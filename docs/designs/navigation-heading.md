# Design — Navigation Heading

Reference screenshot (Apple Maps turn-by-turn, iOS): a full-screen map with a blue arrow "puck" at the rider's position showing the direction of travel; a small floating compass (a circle with an N marker) appears at the top-trailing corner whenever the map is not north-up, and tapping it resets north. Rain Dodger replaces the system puck with a custom **head arrow**, keeps the **built-in MapKit compass**, and adds a **bottom-trailing lock button** that rotates the map and compass to follow the phone's heading.

**Job and rider:** a motorcyclist, gloves on, phone mounted (portrait or landscape), riding. In one glance they see: which way they face (head arrow at their position), whether the map is locked to their heading (built-in compass + lock button), and how to unlock/recenter.

## 1. Screens

The feature is the map screen with these states:

- **Loading (no fix yet):** map renders immediately (system tiles); no arrow and no lock state until the first location/heading arrives; the control stack is present.
- **Authorized + fix:** head arrow at the live coordinate; north-up map; built-in compass hidden (map is north-up); control stack present.
- **Locked:** map rotates with the phone's heading; arrow points up; built-in compass visible; lock button shows the filled state.
- **Unlocked + manually rotated:** arrow still shows true facing (`heading − cameraHeading`); built-in compass visible at top-trailing; lock button shows the hollow state.
- **Heading unavailable:** arrow upright (rotation 0), no cardinal value read.
- **Denied:** existing `LocationPermissionOverlay` over the map; no arrow.

## 2. Layout

- **Map:** full-screen edge-to-edge, standard gestures (pan/zoom/pinch), standard MapKit style. `Map` (iOS 26 SwiftUI).
- **Head arrow:** centered at the live coordinate via `Annotation("", coordinate:)` + `HeadingArrowView`, `.annotationTitles(.hidden)`.
- **Built-in compass:** `.mapControls { MapCompass() }` at the native top-trailing position. **Visibility is native behavior: the compass auto-hides when the map is north-up** — it is never forced always-visible.
- **Control stack (bottom-trailing):** existing insets kept — the stack floats ~80 pt above the bottom safe-area inset in portrait and ~76 pt in landscape (where the bar is full-width), drawn ON TOP of the bottom bar (search capsule / route-summary pill). `RecenterButton` on top, `HeadingLockButton` below, 12 pt spacing.
- **Denied overlay:** unchanged — full-map dark translucent scrim + solid card: heading, explanation, Open Settings button.

**Landscape (mounted):** the phone sits in landscape on the bike mount — both orientations must work (004 §4.7):

- **Control stack:** stays bottom-trailing inside the safe area — clear of the Dynamic Island/notch (left or right edge in landscape) and of the screen edges, lifted ~76 pt above the bottom inset so it clears the full-width bottom bar; stays 44 pt+.
- **Compass:** the built-in `.mapControls` compass positions itself natively in landscape.
- **No element cut off:** the arrow, compass, and control stack remain fully on-screen within the safe areas; the map fills the remaining space.

## 3. Components

- **MapScreenView** — composes the `Map`, owns the camera position and the read-only `cameraHeading` tracking, renders the arrow annotation and the control stack.
- **HeadingArrowView** (new) — 36 pt `Color(.systemBackground)` circle + 20 pt `location.north.fill` glyph in `Color.blue`, shadow `black 0.25 / r5 / y2` (matches the control stack); rotation `heading − cameraHeading`, eased 0.2 s shortest-arc; static under Reduce Motion. Map annotation, not a control.
- **HeadingLockButton** (new) — 56 pt white circle (matches `RecenterButton`), glyph `location.north.line` (hollow = unlocked) / `location.north.line.fill` (filled = locked) in near-black `#1C1C1E`; ≥ 44 pt target. Tap toggles the heading lock.
- **MapCompass** (system, built-in) — MapKit's compass via `.mapControls`; native top-trailing; auto-hides north-up; system-rendered in both modes; tap = north-up + recenter (system).
- **CompassControl** (deleted) — the custom always-visible dial is removed and its file reference is removed from the project.
- **RecenterButton** (unchanged) — white circle, dark location arrow; pans the camera to the user's location and clears the heading lock.
- **LocationPermissionOverlay** (unchanged) — denied state: explanation + Open Settings (44 pt).
- **MockLocationService** (modified) — for previews: scripted headings plus a deterministic location script (base coordinate, then +0.0004 latitude every 1 s for 4 steps, then hold).
- **Never `MapUserLocationButton`** — its double-tap heading behavior would fight the lock button.

**Anti-goals:** no custom compass dial; no forced-always-visible compass; no new Info.plist keys; no `UserAnnotation` heading cone; no camera pitch; no accuracy circle/pulse (lost with the system dot — accepted).

## 4. Light / Dark Mode

- Arrow glyph `Color.blue` on a `Color(.systemBackground)` circle; shadow `black 0.25 / r5 / y2` in both modes; the blue glyph stays ≥ 3:1 against the backing in both modes.
- Lock button: white circle in both modes with a near-black (`#1C1C1E`) glyph — matches `RecenterButton`; both glyph states (filled/hollow) ≥ 3:1 on the white backing.
- Built-in compass: system-rendered in both modes.
- Map keeps the standard MapKit style; no new tokens.

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels/values/hints (exact):
  - Head arrow: label **"Your location"**; value **"heading north east, 45 degrees"** (cardinal + degrees, e.g. 45° → "north east"); when heading is nil the value is omitted and the element reads **"Your location"**.
  - Lock button: label **"Lock to heading"**; value **"Locked"** / **"Unlocked"**; hint **"Map and compass follow your heading while locked"**.
  - Built-in compass: system label/value — not overridden.
- All interactive targets (lock button, recenter, built-in compass) ≥ 44 × 44 pt; the head arrow is a map annotation (non-interactive).
- State is conveyed by **shape change** (filled vs hollow glyph) **and** the VO value — never color-only.
- No on-screen text; Dynamic Type has no text to scale (arrow/lock glyphs are fixed-size icons).
- Reduce Motion: arrow rotation static (instant), lock/unlock camera instant, no animation.
- Contrast: 3:1 arrow glyph on its backing and lock glyphs on white in both modes; map content does not carry app-critical info.

## 6. Motion / Haptics

- **Arrow rotation:** eased 0.2 s shortest-arc on heading/camera change; **Reduce Motion** → instant (static, no rotation animation).
- **Lock/unlock camera:** the existing animated camera move pattern (`.userLocation(followsHeading:)` / north-up recenter); **Reduce Motion** → instant, no animation.
- **Built-in compass:** system animation only (appears when the map leaves north-up, tap reset).
- **No haptics** this feature (existing pattern — ride-start/warning haptics come later).