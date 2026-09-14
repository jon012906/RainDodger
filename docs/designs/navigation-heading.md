# Design — Navigation Heading

Reference screenshot (Apple Maps turn-by-turn, iOS): a full-screen map with a blue arrow "puck" at the rider's position showing the direction of travel; a small floating compass (a circle with an N marker) appears at the top-trailing corner whenever the map is not north-up, and tapping it resets north. Rain Dodger replaces the system puck with a custom **head arrow**, uses a **custom gyro compass** (always visible — the built-in MapKit compass hides at north-up and cannot show the phone heading), and adds a **bottom-trailing lock button** that rotates the map and compass to follow the phone's heading.

**Job and rider:** a motorcyclist, gloves on, phone mounted (portrait or landscape), riding. In one glance they see: which way they face (head arrow at their position), whether the map is locked to their heading (custom gyro compass + lock button), and how to unlock/recenter.

## 1. Screens

The feature is the map screen with these states:

- **Loading (no fix yet):** map renders immediately (system tiles); no arrow and no lock state until the first location/heading arrives; the control stack is present.
- **Authorized + fix:** head arrow at the live coordinate; north-up map; custom gyro compass always visible (needle shows the phone heading); control stack present.
- **Locked:** map rotates with the phone's heading; arrow points up; compass needle keeps pointing at the phone heading (visually coherent with the rotated map); lock button shows the filled state.
- **Unlocked + manually rotated:** arrow still shows true facing (`heading − cameraHeading`); custom gyro compass always visible at the top of the bottom-trailing control stack, needle keeps showing the phone heading regardless of map rotation; lock button shows the hollow state.
- **Heading unavailable:** arrow upright (rotation 0), no cardinal value read.
- **Denied:** existing `LocationPermissionOverlay` over the map; no arrow.

## 2. Layout

- **Map:** full-screen edge-to-edge, standard gestures (pan/zoom/pinch), standard MapKit style. `Map` (iOS 26 SwiftUI).
- **Head arrow:** centered at the live coordinate via `Annotation("", coordinate:)` + `HeadingArrowView`, `.annotationTitles(.hidden)`.
- **Compass:** custom gyro compass (`MapCompassOverlay`) at the top of the bottom-trailing control stack (above `RecenterButton`), **always visible** in both orientations — 56 pt white circle + gray ring + red needle following the phone heading, fixed N, decorative (not interactive).
- **Control stack (bottom-trailing):** existing insets kept — the stack floats ~80 pt above the bottom safe-area inset in portrait and ~76 pt in landscape (where the bar is full-width), drawn ON TOP of the bottom bar (search capsule / route-summary pill). `MapCompassOverlay` on top, `RecenterButton` below it, `HeadingLockButton` below, 12 pt spacing.
- **Denied overlay:** unchanged — full-map dark translucent scrim + solid card: heading, explanation, Open Settings button.

**Landscape (mounted):** the phone sits in landscape on the bike mount — both orientations must work (004 §4.7):

- **Control stack:** stays bottom-trailing inside the safe area — clear of the Dynamic Island/notch (left or right edge in landscape) and of the screen edges, lifted ~76 pt above the bottom inset so it clears the full-width bottom bar; stays 44 pt+.
- **Compass:** the custom gyro compass sits at the top of the bottom-trailing control stack in landscape, sharing the stack's landscape insets (bottom 76); always visible.
- **No element cut off:** the arrow, compass, and control stack remain fully on-screen within the safe areas; the map fills the remaining space.

## 3. Components

- **MapScreenView** — composes the `Map`, owns the camera position and the read-only `cameraHeading` tracking, renders the arrow annotation and the control stack.
- **HeadingArrowView** (new) — 36 pt `Color(.systemBackground)` circle + 20 pt `location.north.fill` glyph in `Color.blue`, shadow `black 0.25 / r5 / y2` (matches the control stack); rotation `heading − cameraHeading`, eased 0.2 s shortest-arc; static under Reduce Motion. Map annotation, not a control.
- **HeadingLockButton** (new) — 56 pt white circle (matches `RecenterButton`), glyph `location.north.line` (hollow = unlocked) / `location.north.line.fill` (filled = locked) in near-black `#1C1C1E`; ≥ 44 pt target. Tap toggles the heading lock.
- **MapCompassOverlay** + **NeedleView** (private structs in `MapScreenView.swift`) — the custom gyro compass: 56 pt white circle + gray ring + red needle rotating with `viewModel.heading` (0 when nil → upright in sim), fixed near-black N; always visible at the top of the bottom-trailing control stack; decorative a11y-hidden; not tappable.
- **CompassControl** (deleted) — the custom always-visible dial is removed and its file reference is removed from the project.
- **RecenterButton** (unchanged) — white circle, dark location arrow; pans the camera to the user's location and clears the heading lock.
- **LocationPermissionOverlay** (unchanged) — denied state: explanation + Open Settings (44 pt).
- **MockLocationService** (modified) — for previews: scripted headings plus a deterministic location script (base coordinate, then +0.0004 latitude every 1 s for 4 steps, then hold).
- **Never `MapUserLocationButton`** — its double-tap heading behavior would fight the lock button.

**Anti-goals:** no native `MapCompass` (auto-hide north-up cannot meet the always-visible expectation); no compass tap behavior; no new Info.plist keys; no `UserAnnotation` heading cone; no camera pitch; no accuracy circle/pulse (lost with the system dot — accepted).

## 4. Light / Dark Mode

- Arrow glyph `Color.blue` on a `Color(.systemBackground)` circle; shadow `black 0.25 / r5 / y2` in both modes; the blue glyph stays ≥ 3:1 against the backing in both modes.
- Lock button: white circle in both modes with a near-black (`#1C1C1E`) glyph — matches `RecenterButton`; both glyph states (filled/hollow) ≥ 3:1 on the white backing.
- Custom gyro compass: white circle (`Color.white`) in both modes + gray ring (`Color(.systemGray3)`) + red needle (≥ 3:1 on white in both modes) + near-black (`#1C1C1E`) N; shadow `black 0.25 / r5 / y2` (matches the control stack).
- Map keeps the standard MapKit style; no new tokens.

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels/values/hints (exact):
  - Head arrow: label **"Your location"**; value **"heading north east, 45 degrees"** (cardinal + degrees, e.g. 45° → "north east"); when heading is nil the value is omitted and the element reads **"Your location"**.
  - Lock button: label **"Lock to heading"**; value **"Locked"** / **"Unlocked"**; hint **"Map and compass follow your heading while locked"**.
  - Compass: decorative — a11y-hidden; heading is read from the head arrow's cardinal value, not the compass.
- All interactive targets (lock button, recenter) ≥ 44 × 44 pt; the head arrow is a map annotation (non-interactive) and the compass is decorative (no target required).
- State is conveyed by **shape change** (filled vs hollow glyph) **and** the VO value — never color-only.
- No on-screen text; Dynamic Type has no text to scale (arrow/lock glyphs are fixed-size icons).
- Reduce Motion: arrow rotation static (instant), lock/unlock camera instant, no animation.
- Contrast: 3:1 arrow glyph on its backing and lock glyphs on white in both modes; map content does not carry app-critical info.

## 6. Motion / Haptics

- **Arrow rotation:** eased 0.2 s shortest-arc on heading/camera change; **Reduce Motion** → instant (static, no rotation animation).
- **Lock/unlock camera:** the existing animated camera move pattern (`.userLocation(followsHeading:)` / north-up recenter); **Reduce Motion** → instant, no animation.
- **Compass needle:** eased ~0.2 s on heading change (heading is VM-smoothed, so steps are short); **Reduce Motion** → instant, no animation.
- **No haptics** this feature (existing pattern — ride-start/warning haptics come later).