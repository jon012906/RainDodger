# Design — Maps Screen

Reference screenshot (Google Maps, iOS): a full-screen map. Bottom center: a floating rounded-capsule search bar — magnifier icon on the left, placeholder "Your Destination…", mic icon and avatar button on the right. Top-trailing: two floating circular buttons stacked — a dark circle with a white compass (cardinal letters N/E/S/W, rotates with device heading, always visible), and a white circle with a dark location arrow (recenter) below it. A blue user-location dot sits at the center on the map.

## 1. Screens

The feature is a single main screen with these states:

- **Loading:** map renders immediately (system tiles); no blue dot or controls until the first heading/location arrives.
- **Permission requested (system):** native iOS when-in-use prompt appears over the map; app shows the map beneath it.
- **Denied:** in-app overlay on the map — explanatory text ("Rain Dodger needs your location to recenter the map") + Open Settings button.
- **Loaded:** full-screen map, blue user dot, bottom search capsule, bottom-trailing recenter button drawn above the bottom bar (compass out of scope this branch).
- **Search entry:** tapping the search capsule opens the destination search page (see `docs/designs/search.md`).

Offline/error of map tiles is handled by MapKit's standard behavior — no custom error state this branch.

## 2. Layout

- **Map:** full-screen edge-to-edge, standard gestures (pan/zoom/pinch), standard MapKit style. `Map` (iOS 26 SwiftUI).
- **Search capsule:** floating bottom-center, above the map, inset from safe areas. Content: magnifier · "Your Destination…" placeholder · mic · avatar. Whole capsule is a single 44 pt+ tap target → opens the search page.
- **Control stack:** the recenter button floats bottom-trailing, above the map and drawn ON TOP of / above the bottom bar (the search field when no route is planned, or the route-summary pill when the trip sheet is dismissed) — never behind or underneath it. It sits ~80 pt above the bottom safe-area inset in portrait, and ~76 pt above the inset in landscape (where the bar is full-width), so it clears the bar in both orientations. White circle with a dark location arrow; 44 pt+.
- **Compass:** **out of scope this branch** — `CompassControl` stays commented out in `MapScreenView` and is not rendered. When re-enabled: always visible; dial rotates with device heading so the cardinal letter for the current heading sits at the top marker (N → E → S → W); tap → north-up + recenter.
- **Blue dot:** centered on the user's location via `UserAnnotation` (no cone this branch).
- **Denied overlay:** full-map coverage with dark translucent scrim + solid card: heading, explanation, Open Settings button.

**Landscape (mounted):** the phone sits in landscape on the bike mount — both orientations must work (004 §4.7):

- **Search capsule:** expands to full width across the bottom edge (inside the horizontal safe-area insets) instead of floating bottom-center; content keeps the same order (magnifier · placeholder · mic · avatar).
- **Control stack:** the recenter button stays bottom-trailing inside the safe area — clear of the Dynamic Island/notch (which sits at the left or right edge in landscape) and of the left/right screen edges, and lifted ~76 pt above the bottom inset so it clears the full-width bottom bar; stays 44 pt+.
- **No element cut off:** the search capsule and the recenter control stack remain fully on-screen within the safe areas in landscape; the map fills the remaining space.

## 3. Components

- **MapScreenView** — composes the `Map`, overlays controls, owns the `MapViewModel`.
- **DestinationSearchField** — the bottom capsule (magnifier, "Your Destination…", mic, avatar); tap → opens `SearchPage` (see `docs/designs/search.md`).
- **CompassControl** — dark circle with rotating cardinal letters (N emphasized) + fixed top marker; **out of scope this branch** (commented out in `MapScreenView`, not rendered); when re-enabled: always visible; tap → north-up + recenter.
- **RecenterButton** — white circle, dark location arrow; pans camera to user location. Positioned bottom-trailing and drawn above the bottom bar (search field or route-summary pill), lifted ~80 pt above the bottom safe-area inset in portrait (~76 pt in landscape where the bar is full-width).
- **LocationPermissionOverlay** — denied state: explanation + Open Settings (44 pt).
- **SearchPage** — destination search page as a modal sheet; components in `docs/designs/search.md`.
- **MockLocationService** — for previews: scripted headings 0° → 45° → 90° → 180°, static coordinate, configurable permission state.

## 4. Light / Dark Mode

- Map keeps the standard MapKit style in both modes.
- Floating controls get **solid backings** (no translucency) so they contrast over map content:
  - Capsule: `Color(.systemBackground)` light / `Color(.secondarySystemBackground)` dark.
  - Compass: dark circle `#1C1C1E` in both modes with white cardinal letters (N bold white, E/S/W white at 72%) + white top marker.
  - Recenter: white circle in both modes with near-black (`#1C1C1E`) location arrow.
- Compass letters and marker stay ≥ 3:1 against the dark backing in both modes.
- Text in the capsule: `Color.primary`, placeholder `Color.secondary` — ≥ 4.5:1 on the solid backing.
- Denied overlay scrim: `Color.black.opacity(0.6)` both modes; card solid.

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels (exact):
  - Search capsule: **"Your destination field"** (hint: "Double tap to search", placeholder announces "Your Destination…").
  - Compass: **"Compass"** (value: current cardinal + degrees, e.g. "North, 0 degrees"; hint: "Double tap to reset to north and recenter").
  - Recenter: **"Recenter to my location"**.
- All interactive targets ≥ 44 × 44 pt; capsule component and control stack use system spacing plus generous padding.
- Dynamic Type: "Your Destination…" uses `.title3`-scale system text that scales; capsule height grows with text size.
- Reduce Motion: compass dial static (no rotation animation); map camera recenter still animates only for distance (compass tap uses default camera; see §6).
- Contrast: solid backings per §4 guarantee 4.5:1 text / 3:1 graphics in light and dark; map contents do not carry app-critical info (dot + controls only).
- Mock service in previews lets VoiceOver users exercise every state.

## 6. Motion / Haptics

- **Compass dial:** eased rotation (shortest-arc), ~0.2 s smooth curve on heading change.
- **Reduce Motion:** dial repositions instantly, no animation; the search page uses the system sheet transition.
- **Recenter:** default SwiftUI `Map` camera move (no custom animation); no follow-heading mode.
- **No haptics required this branch** (deferred — no ride start, no warnings yet).
