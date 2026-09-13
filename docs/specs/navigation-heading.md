# Spec — Navigation Heading

## 1. Goal

Give the rider a glanceable sense of which way they face and direct control over map orientation while mounted: a gyro-driven **head arrow** at their position on the map (replacing the system `UserAnnotation` blue dot), the **built-in MapKit `MapCompass`** (replacing the custom always-visible `CompassControl`), and a **heading-lock button** that rotates the map and compass to follow the phone's heading. One glance answers "which way am I facing" and "is the map locked to my heading"; one tap locks/unlocks the map to the heading or recenters.

> **Supersedes maps-screen R2/R4:** this spec replaces `docs/specs/maps-screen.md` **R2** (user-location blue dot via `UserAnnotation` — NH1/NH2 below) and **R4** (custom always-visible compass dial — NH4/NH5 below). maps-screen R2/R4 are marked superseded there.

## 2. User Problem

- The `UserAnnotation` blue dot shows *where* the rider is but not *which way they face*; the maps-screen branch's custom compass promised orientation but was never rendered (out of scope there).
- Riders glance at a mounted phone mid-ride: they need to know at a glance whether the map is north-up or follows the bike's heading, and how to switch — with gloves, without hunting for a control.
- Apple Maps riders expect the platform-native compass behavior: visible only when the map is not north-up, tap to reset. A custom always-visible dial fights that expectation and duplicates MapKit.
- MapKit already ships the `MapCompass` and a `.userLocation(followsHeading:)` camera mode; the app currently reimplements both with custom UI and custom camera intents.

## 3. Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| NH1 | Custom head arrow at the user's live location replacing the system `UserAnnotation` blue dot | P0 | `Annotation("", coordinate:)` + `HeadingArrowView` at `viewModel.currentCoordinate` with `.annotationTitles(.hidden)` |
| NH2 | Arrow follows continuous location while the map is visible | P0 | `LocationService.locationUpdates() -> AsyncStream<CLLocation>` on the protocol (Live + Mock); the stream runs only while authorized and the screen is visible; stops on disappear |
| NH3 | Arrow rotation = gyro heading − camera heading | P0 | True facing at any map rotation; points up in locked mode; rotation 0 (upright) until the first heading sample; eased 0.2 s shortest-arc; static under Reduce Motion |
| NH4 | Built-in MapKit `MapCompass` via `.mapControls` | P0 | Native top-trailing position; **auto-hides when north-up** (native behavior — supersedes maps-screen R4's "always visible"); tap = north-up + recenter (system) |
| NH5 | Heading-lock button toggles `.userLocation(followsHeading:)`; RecenterButton while locked = unlock + north-up | P0 | Lock sets `cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)`; `recenter()` clears the lock |
| NH6 | No new Info.plist keys | P0 | Heading is covered by the existing `NSLocationWhenInUseUsageDescription` location permission |
| NH7 | Lock-state sync from the real camera | P0 | `.onChange(of: cameraPosition)` → `syncFollowHeading(newPosition.followsUserHeading)`; compass tap, user pan, and destination focus keep the button in sync — no camera echo |
| NH8 | Accessibility per 004 | P0 | `.opencode/rules/004-accessibility.md`: ≥ 44 pt targets, exact VO label/value/hint, state via shape change + VO value (never color-only), Reduce Motion, contrast |

## 4. Data Model

No SwiftData — Core Location value types only:

- `CLLocation`: rider position, delivered as a continuous stream (`locationUpdates()`) that keeps `currentCoordinate` fresh and drives the arrow's position.
- `CLHeading`: device heading (`trueHeading` with `magneticHeading` fallback, existing smoothing/outlier-drop in `MapViewModel`); drives the arrow's rotation.
- The camera's `followsUserHeading` state is ephemeral SwiftUI/MapKit state, synced into `MapViewModel.isHeadingLocked` — nothing is persisted.

## 5. Rules / Logic

- **Streams:** location + heading streams run only while permission is authorized and the screen is visible; both stop on disappear.
- **Heading selection:** prefer `CLHeading.trueHeading`; fall back to `magneticHeading` when true heading is unavailable (existing behavior, now feeding the arrow).
- **Arrow rotation:** `rotation = (heading − cameraHeading + 360) mod 360`; heading nil → 0. In locked mode `heading ≈ cameraHeading`, so the arrow points up.
- **Lock/unlock:** lock sets `cameraPosition = .userLocation(followsHeading: true, fallback: .automatic)`; unlock returns the camera north-up at the user's location; `recenter()` always clears the lock (recenter while locked = unlock + north-up).
- **Lock-state sync (no camera echo):** the button never writes the camera; `.onChange(of: cameraPosition)` mirrors the real camera's `followsUserHeading` into `isHeadingLocked`, so compass taps, user pans, and destination focus stay honest.
- **Reduce Motion:** camera moves and arrow rotation apply instantly, no animation.
- **Battery:** continuous `BestForNavigation` location while the map is visible (mounted ride); streams stop on disappear — accepted tradeoff.

## 6. Constraints

- iOS 26.5+, iPhone-first (landscape supported while mounted).
- Apple frameworks only: SwiftUI, MapKit, Core Location. No third-party packages.
- No new Info.plist keys (heading shares the existing location permission).
- No custom compass dial, no forced-always-visible compass (built-in `MapCompass` auto-hides north-up), no `MapUserLocationButton` (its double-tap heading behavior would fight the lock button).
- No camera pitch; no accuracy circle/pulse (lost with the system dot — accepted, flagged in branch risks).
- Supersedes `docs/specs/maps-screen.md` R2 (blue dot) and R4 (custom always-visible compass) — those rows are marked superseded there.

## 7. Acceptance Criteria

- [ ] `docs/specs/navigation-heading.md`, `docs/designs/navigation-heading.md`, `docs/flows/navigation-heading.md` exist per templates and pass design-review
- [ ] NH1: custom head arrow at the live coordinate replaces the `UserAnnotation` blue dot (`Annotation("", coordinate:)` + `HeadingArrowView`, `.annotationTitles(.hidden)`)
- [ ] NH2: arrow follows continuous location (`locationUpdates()` stream) while authorized + visible; streams stop on disappear
- [ ] NH3: rotation = heading − cameraHeading (true facing at any rotation; points up when locked; 0 until the first heading sample); eased 0.2 s shortest-arc; static under Reduce Motion
- [ ] NH4: built-in `MapCompass` via `.mapControls` — native top-trailing, auto-hides north-up (never forced always-visible); tap = north-up + recenter (system)
- [ ] NH5: heading-lock button toggles `.userLocation(followsHeading: true)`; RecenterButton while locked = unlock + north-up
- [ ] NH6: no new Info.plist keys
- [ ] NH7: lock-state synced from the real camera (`followsUserHeading`) — compass tap, pan, destination focus keep the button honest; no camera echo
- [ ] NH8: accessibility per 004 — exact VO labels/values/hints, ≥ 44 pt, state via shape change + VO value, Reduce Motion, contrast
- [ ] `docs/specs/maps-screen.md` R2/R4 + §6 constraint marked superseded with cross-refs; maps-screen design/flow amended — no stale blue-dot/custom-compass promises remain anywhere
- [ ] `docs/template/spec-guide.md` §9 → `feat/navigation-icon`; `docs/implementation.md` Phase N1 entry + Change Log row
- [ ] No code changes this phase (verified via `git status --short` / `git diff --stat`)