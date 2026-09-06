# Spec — Maps Screen

## 1. Goal

Give the rider a familiar map "home screen" they already know before any route or weather logic exists: a full-screen interactive map showing where they are, a floating search bar for the destination they will type later, and one-thumb controls to recenter and orient. This branch builds the map shell — pan/zoom, user-location dot, recenter, compass, permission handling, and tap-stub search — so later branches can drop routes and rain onto a screen that already feels native.

## 2. User Problem

- The app currently shows a template list — no map, no location, nothing a rider can use while mounted.
- Riders plan by map first: they expect to see the map and their blue dot the moment the app opens, with search and navigation reachable in one tap.
- While riding, the map can be panned anywhere; the rider needs a single tap to get back to their position, and a compass to know which way they are facing when the map is not north-up.
- Location permission must be handled like Apple Maps: ask once, explain clearly when denied, and give a working path to fix it.

## 3. Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| R1 | Interactive map: pan/zoom standard gestures, full-screen | P0 | iOS 26 SwiftUI `Map` |
| R2 | User-location blue dot rendered | P0 | `UserAnnotation`; heading cone **deferred** to a later feature — dot only on this branch |
| R3 | Recenter-to-location button | P0 | Returns/centers camera to user location from any pan position |
| R4 | Compass | P0 | Core Location heading (`trueHeading` w/ `magneticHeading` fallback); always visible, dial rotates with heading and shows cardinal letters (N/E/S/W, top letter = facing); tap = north-up + recenter |
| R5 | Search bar | P0 | Visual parity + tap stub ("coming soon" placeholder); real search (`MKLocalSearch`) **deferred** |
| R7 | Permission states | P0 | Unknown → system prompt → authorized/denied; denied = explanatory overlay + Open Settings |
| R8 | Accessibility | P0 | `.opencode/rules/004-accessibility.md`: ≥ 44 pt targets, VoiceOver labels/hints, Dynamic Type, Reduce Motion, contrast |

## 4. Data Model

No new SwiftData models this branch — `Item` stays untouched. The map screen relies on Core Location value types only:

- `CLLocation`: rider position; drives the blue dot and the recenter target.
- `CLHeading`: device heading; drives the compass dial (`trueHeading`, `magneticHeading` fallback).

`MapViewModel` holds ephemeral UI state (camera position, heading, permission state, stub visibility) — nothing is persisted.

## 5. Rules / Logic

- **Heading selection:** prefer `CLHeading.trueHeading`; fall back to `magneticHeading` when true heading is unavailable.
- **Dial smoothing:** drop heading samples whose jump from the previous accepted value is ≥ 180° (outlier/crossing artifact), then rotate the dial the short way around.
- **Compass:** always visible; the dial rotates so the cardinal letter for the current heading sits at the top marker (N → E → S → W).
- **Compass tap:** reset map to north-up and recenter to user location.
- **Heading updates:** only while permission is authorized and the screen is visible (stop on disappear).
- **Recenter:** camera returns to the user's last known location, any pan position.
- **Permission flow:** unknown → request when-in-use → authorized (dot + heading) or denied (overlay + Open Settings).
- **Search:** shows the coming-soon stub; no `MKLocalSearch`, no directions.

## 6. Constraints

- iOS 26.5+, iPhone-first (landscape supported while mounted).
- Apple frameworks only: SwiftUI, MapKit, Core Location. No third-party packages, no WebKit.
- Privacy: `NSLocationWhenInUseUsageDescription` in `Info.plist`; location never leaves the device; no background location.
- No routes, no weather, no map rotation/follow-heading mode on this branch.
- Location services may be interrupted (Settings) — the screen must recover to the correct state on resume.

## 7. Acceptance Criteria

- [ ] `docs/specs/maps-screen.md`, `docs/designs/maps-screen.md`, `docs/flows/maps-screen.md` exist per templates and pass design-review
- [ ] `docs/template/spec-guide.md` §9 shows `feat/maps-screen`; stale `docs/specs/spec-guide.md` refs fixed in `docs/implementation.md` + `.opencode/rules/004-accessibility.md`
- [ ] Blue user dot rendered (`UserAnnotation`); no heading cone (explicitly deferred — spec/design/flow/docs must not promise one)
- [ ] Compass: dial driven by Core Location heading (true w/ magnetic fallback), always visible, cardinal letters rotate (top letter = facing), tap = north-up + recenter, 44 pt target, VoiceOver label/value/hint, Reduce Motion respected
- [ ] Recenter: button pans camera to user location from anywhere
- [ ] Search: tap shows the coming-soon stub with an accessible announcement
- [ ] Denied permission: explanatory overlay + Open Settings (44 pt)
- [ ] Accessibility per `.opencode/rules/004-accessibility.md` (hit targets, VoiceOver, Dynamic Type)
- [ ] `docs/implementation.md` logs a correction for the stale Phase-1 entries + this branch's docs/code phases
- [ ] No out-of-scope framework introduced (no `MKDirections`, no WeatherKit, no third-party, no `MKLocalSearch`)
