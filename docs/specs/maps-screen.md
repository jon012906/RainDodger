# Spec — Maps Screen

## 1. Goal

Give the rider a familiar map "home screen" they already know before any route or weather logic exists: a full-screen interactive map showing where they are, a floating search bar for the destination they will type later, and one-thumb controls to recenter and orient. This branch builds the map shell — pan/zoom, user-location dot, recenter, compass, permission handling, and the search entry point — so later branches can drop routes and rain onto a screen that already feels native.

> **Historical note (feat/navigation-icon):** the user-location blue dot (R2) and the custom always-visible compass (R4) described below are **superseded** by `docs/specs/navigation-heading.md` — the head arrow, the custom gyro compass, and the heading-lock button replace them. R2/R4 rows are marked superseded in §3.

## 2. User Problem

- The app currently shows a template list — no map, no location, nothing a rider can use while mounted.
- Riders plan by map first: they expect to see the map and their position (blue dot at the time; head arrow per `docs/specs/navigation-heading.md` NH1) the moment the app opens, with search and navigation reachable in one tap.
- While riding, the map can be panned anywhere; the rider needs a single tap to get back to their position, and a compass to know which way they are facing when the map is not north-up.
- Location permission must be handled like Apple Maps: ask once, explain clearly when denied, and give a working path to fix it.

## 3. Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| R1 | Interactive map: pan/zoom standard gestures, full-screen | P0 | iOS 26 SwiftUI `Map` |
| R2 | User-location blue dot rendered | P0 | `UserAnnotation`; heading cone **deferred** to a later feature — dot only on this branch · **SUPERSEDED** (feat/navigation-icon) — replaced by the custom head arrow; see `docs/specs/navigation-heading.md` NH1/NH2 |
| R3 | Recenter-to-location button | P0 | Returns/centers camera to user location from any pan position |
| R4 | Compass | P0 | Core Location heading (`trueHeading` w/ `magneticHeading` fallback); always visible, dial rotates with heading and shows cardinal letters (N/E/S/W, top letter = facing); tap = north-up + recenter · **SUPERSEDED** (feat/navigation-icon) — replaced by the custom gyro compass (always visible, top of the bottom-trailing control stack, needle = phone heading, decorative, not tappable) + heading-lock button; see `docs/specs/navigation-heading.md` NH4/NH5 |
| R5 | Search bar | P0 | Visual parity + tap opens the destination search page (see `docs/specs/search.md`); real search (`MKLocalSearch`) delivered by the search feature |
| R7 | Permission states | P0 | Unknown → system prompt → authorized/denied; denied = explanatory overlay + Open Settings |
| R8 | Accessibility | P0 | `.opencode/rules/004-accessibility.md`: ≥ 44 pt targets, VoiceOver labels/hints, Dynamic Type, Reduce Motion, contrast |
| R9 | Clearing a destination from the route-summary pill X or the trip planner destination-row X restores the empty/search map | P0 | `DestinationSearchField` ("Your Destination…") visible, no destination pin/route/rain overlays, camera back at the rider's location; see `docs/specs/trip-planner.md` R17/R18 |

## 4. Data Model

No new SwiftData models this branch — `Item` stays untouched. The map screen relies on Core Location value types only:

- `CLLocation`: rider position; drives the recenter target. (Blue-dot rendering is **superseded** — see R2 / `docs/specs/navigation-heading.md`.)
- `CLHeading`: device heading (`trueHeading`, `magneticHeading` fallback) — historically drove the custom compass dial; **superseded** by `docs/specs/navigation-heading.md` (arrow rotation + custom gyro compass needle).

`MapViewModel` holds ephemeral UI state (camera position, heading, permission state, search entry) — nothing is persisted.

## 5. Rules / Logic

- **Heading selection:** prefer `CLHeading.trueHeading`; fall back to `magneticHeading` when true heading is unavailable (now feeds the head arrow — `docs/specs/navigation-heading.md` NH3).
- **Dial smoothing:** drop heading samples whose jump from the previous accepted value is ≥ 180° (outlier/crossing artifact), then rotate the dial the short way around. **Superseded** — the smoothing survives, the dial does not; see `docs/specs/navigation-heading.md` NH3.
- **Compass:** always visible; the dial rotates so the cardinal letter for the current heading sits at the top marker (N → E → S → W). **Superseded** (feat/navigation-icon) — custom gyro compass in the bottom-trailing control stack (always visible, needle = phone heading, decorative, not tappable) + heading-lock button; see `docs/specs/navigation-heading.md` NH4/NH5.
- **Compass tap:** reset map to north-up and recenter to user location. **Superseded** — the custom gyro compass is not tappable; north-up/recenter happens via `RecenterButton` / unlocking; see `docs/specs/navigation-heading.md` NH4/NH5.
- **Heading updates:** only while permission is authorized and the screen is visible (stop on disappear).
- **Recenter:** camera returns to the user's last known location, any pan position.
- **Permission flow:** unknown → request when-in-use → authorized (dot + heading) or denied (overlay + Open Settings).
- **Search:** opens the destination search page (see `docs/specs/search.md`); the coming-soon stub is removed on the search branch.
- **Clear destination:** when a destination is cleared from the route-summary pill's X (trip-planner R17) or the trip planner destination-row X (trip-planner R18), the map returns to the empty/search state — `DestinationSearchField` ("Your Destination…") visible, no destination pin, no route polyline, no rain overlays/legend/badges, and the camera returns to the rider's location. The reset scope and the retained trip values (origin/stop/departure) are defined by `docs/specs/trip-planner.md` §5 "Clear destination".

## 6. Constraints

- iOS 26.5+, iPhone-first (landscape supported while mounted).
- Apple frameworks only: SwiftUI, MapKit, Core Location. No third-party packages, no WebKit.
- Privacy: `NSLocationWhenInUseUsageDescription` in `Info.plist`; location never leaves the device; no background location.
- No routes, no weather, no map rotation/follow-heading mode on this branch. Follow-heading is **superseded** (feat/navigation-icon): it now lives in `docs/specs/navigation-heading.md` — custom gyro compass + heading-lock button (R4 superseded).
- Location services may be interrupted (Settings) — the screen must recover to the correct state on resume.

## 7. Acceptance Criteria

- [ ] `docs/specs/maps-screen.md`, `docs/designs/maps-screen.md`, `docs/flows/maps-screen.md` exist per templates and pass design-review
- [ ] `docs/template/spec-guide.md` §9 shows `fix/clear-destination`; stale `docs/specs/spec-guide.md` refs fixed in `docs/implementation.md` + `.opencode/rules/004-accessibility.md`
- [ ] Blue user dot rendered (`UserAnnotation`); no heading cone (explicitly deferred) — **superseded** (feat/navigation-icon) by the head arrow; see `docs/specs/navigation-heading.md` NH1/NH2
- [ ] Compass: dial driven by Core Location heading (true w/ magnetic fallback), always visible, cardinal letters rotate (top letter = facing), tap = north-up + recenter, 44 pt target, VoiceOver label/value/hint, Reduce Motion respected — **superseded** (feat/navigation-icon) by the custom gyro compass (always visible, needle = phone heading, decorative, not tappable) + heading-lock button; see `docs/specs/navigation-heading.md` NH4/NH5
- [ ] Recenter: button pans camera to user location from anywhere
- [ ] Search: tap opens the destination search page (see `docs/specs/search.md`)
- [ ] Clearing a destination from the route-summary pill X or the destination-row X restores the empty/search map: `DestinationSearchField` visible, no destination pin/route/rain overlays, camera back at the rider's location (`docs/specs/trip-planner.md` R17/R18)
- [ ] Denied permission: explanatory overlay + Open Settings (44 pt)
- [ ] Accessibility per `.opencode/rules/004-accessibility.md` (hit targets, VoiceOver, Dynamic Type)
- [ ] `docs/implementation.md` logs a correction for the stale Phase-1 entries + this branch's docs/code phases
- [ ] No out-of-scope framework introduced (no `MKDirections`, no WeatherKit, no third-party)
