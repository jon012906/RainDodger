# Implementation Log — Rain Dodger

Living document that tracks the app from Xcode template to a working app, and records the **user's changes in each phase**. Each phase is executed with `@implement <Phase>` and verified with `@review`; every change made in a phase is documented here (see **Change Log**). A phase is **done** only when everything in its checklist is complete, the project builds (`xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger`), and `@review` reports clean.

## How to work this file

- Each phase is executed with `@implement <Phase>` (or ran as its own plan), then checked with `@review`.
- Tick checkboxes as work completes; move a phase to `Done` only when verified.
- Feature work always follows `.opencode/rules/003-project-guideline.md`; visual work follows the feature's design doc in `docs/designs/`; scope follows `docs/template/spec-guide.md`.
- Never commit or push here — the user does it explicitly with `@push`.

## Phase 0 — Baseline (current state)

- [x] Xcode project `RainDodger.xcodeproj` builds on iPhone 16 simulator
- [x] SwiftData `ModelContainer` wired in `RainDodgerApp.swift`
- [x] Docs in place: `docs/template/spec-guide.md`, `docs/template/design.md`, `.opencode/rules/003-project-guideline.md`
- [ ] Template `Item` model replaced by domain models (see Phase 2)

## Phase 1 — Foundation

Goal: repo-level skeleton every feature builds on. No visible features yet.

- [x] Feature folders created: `Models/`, `Services/`, `ViewModels/`, `Views/`
- [x] Service protocols with `async/await`: `LocationService`, `DestinationSearchService` (`WeatherService`/`DirectionsService` deferred to Phase 2)
- [x] Mock implementations for previews/tests: `MockLocationService`, `MockDestinationSearchService`
- [x] `Info.plist`: `NSLocationWhenInUseUsageDescription` added
- [ ] WeatherKit entitlement enabled and configured in the project (deferred — comes with the Phase 3 rain layer)
- [ ] `AGENTS.md` conventions verify: no comments, modern SwiftUI (`@Observable`), max 4-line rule for VMs
- [ ] Build passes, `@review` clean

## Phase 2 — Foundation Models & Routing MVP

Goal: user can search a destination and see route alternatives on a map (like Apple Maps).

- [ ] `Trip`, `RoutePlan`, `SavedDestination` models replace `Item`; registered in `Schema`
- [ ] Destination search (map-based + `MKLocalSearchCompleter` suggestions)
- [ ] `MKDirections` returns 2–3 route alternatives in `RoutePlan`
- [ ] Map with route polylines, start/destination pins, best-fit camera
- [ ] Route cards: ETA + distance (glanceable, ≥ 44 pt targets)
- [ ] `@MainActor @Observable` `TripPlannerViewModel` with `idle/loading/loaded/failed` state
- [ ] Build passes, `@review` clean

## Phase 3 — Rain Layer (P0, the core feature)

Goal: per-segment rain probability over every route, ranked driest-first.

- [ ] Route polyline sampled every ~1 km (start → arrival)
- [ ] `WeatherKit`: current conditions + minute forecast (60 min) + hourly at each sample coordinate
- [ ] Per-segment rain chance blended from WeatherKit at arrival time per segment
- [ ] Rain overlay drawn on map segments (color-coded per the rain-layer design doc in `docs/designs/`: <30% / 30–60% / >60%)
- [ ] Dry route scoring: `score = w1 × ETA + w2 × rain exposure`; weights in config
- [ ] Route cards show: "Driest" badge, "Fastest" badge with wet distance ("14 km of 40 km with rain ≥ 50%")
- [ ] Offline degrade: route still shows, banner "live rain unavailable"
- [ ] Build passes, `@review` clean

## Phase 4 — Departure Optimization & Saved Destinations (P1)

Goal: "leave in 20 min, rain passes in 40 min."

- [ ] `SavedDestination` flows: save, list, reuse (home/work)
- [ ] Departure-time sweep over hourly forecast → driest departure window suggestion
- [ ] Route cards update when departure time changes (re-score)
- [ ] Build passes, `@review` clean

## Phase 5 — Working App Polish (P2/P3)

Goal: rider-ready app, not a demo.

- [ ] Turn-by-turn with rain warnings ahead ("rain in 5 km")
- [ ] Core ML short-term rain predictor blended with WeatherKit per segment
- [ ] Design tokens from the feature design docs in `docs/designs/` applied (light + dark, typography, colors, monospaced rain %)
- [ ] Haptics on ride start + rain warning
- [ ] Glove-friendly audit: all targets ≥ 44 pt, high contrast, glanceable while mounted
- [ ] Landscape (mounted) layout supported
- [ ] Build passes, `@review` clean

## Release Gate (working app)

- [ ] All P0–P1 features verified on simulator + device
- [ ] Graceful offline behavior verified
- [ ] Backwards-compatible state migration (SwiftData schema changes safe)
- [ ] No API keys / `DEVELOPMENT_TEAM` / `xcuserdata/` in commits — checked at `@push`

## Change Log

Document every change made in each phase here — files added/modified, decisions, and anything that deviated from the plan.

| Date | Phase | Change |
|---|---|---|
| 2026-09-02 | Phase 1 — feat/map-search | Added `RainDodger/Models/SearchResult.swift`; `RainDodger/Services/DestinationSearchService.swift` (protocol + `LiveDestinationSearchService` + `MockDestinationSearchService`), `RainDodger/Services/LocationService.swift` (protocol + `LiveLocationService` + `MockLocationService`); `RainDodger/ViewModels/MapSearchViewModel.swift`; `RainDodger/Views/MapSearchView.swift`, `RainDodger/Views/DestinationSearchField.swift`. Modified `RainDodger/ContentView.swift` (now hosts `MapSearchView` with Live services; template SwiftData list removed), `RainDodger/Info.plist` (`NSLocationWhenInUseUsageDescription` added), `docs/template/spec-guide.md` (§9 workspace table filled for the branch). Decisions: protocol-first services with Live + mock impls per MVVM; 350 ms debounce via `Task.sleep` + cancellation in the VM; custom floating search field over `.searchable` (full control of states, a11y, layout); map accessories via `.mapControls` (verified against the iOS 26.5 SDK — `mapAccessoryVisibility` does not exist); user-location dot via `UserAnnotation()` (position-based `Map` init has no `showsUserLocation` in iOS 26); pin-drop camera animation gated on Reduce Motion. Deferred: WeatherKit entitlement, routing (`MKDirections`), SwiftData `Item` replacement. |
| 2026-09-04 | Phase A — feat/maps-screen (docs) | **The 2026-09-02 "Phase 1 — feat/map-search" entry above is STALE on this branch.** None of its code exists here: `LocationService`/`DestinationSearchService`/`MapSearch*`/`SearchResult.swift` files and the `NSLocationWhenInUseUsageDescription` addition are absent (git history only; `RainDodger/` still contains the template), and the app is not reachable from a search field. `feat/maps-screen` **re-delivers** `LocationService` (protocol + Live + Mock) and the Info.plist key, renames the screen to `MapScreenView` + `MapViewModel`, and keeps `DestinationSearchService` **deferred** (search = tap stub, no `MKLocalSearch`). Docs created: `docs/specs/maps-screen.md` (Goal, User Problem, Requirements R1–R8, Data Model, Rules/Logic, Constraints, Acceptance), `docs/designs/maps-screen.md` (Docs-screenshot-first: screens/states, layout, components, light/dark, a11y with exact VoiceOver labels, motion/haptics; heading cone explicitly deferred), `docs/flows/maps-screen.md` (mermaid user flow + edge cases A–D). Updated `docs/template/spec-guide.md` §9 to `feat/maps-screen`; fixed stale `docs/specs/spec-guide.md` refs to `docs/template/spec-guide.md` in this file + `.opencode/rules/004-accessibility.md` (spec-guide moved in `a10dc33`, so the old path was a dangling pointer). Decisions: docs-only phase — no app code; user-location heading cone deferred; no routes/weather/follow-heading; no third-party packages; iOS 26 SwiftUI `Map` + `UserAnnotation`; Core Location heading with `trueHeading`/`magneticHeading` fallback; mock service scripts headings 0°→45°→90°→180° for previews. |
| 2026-09-04 | Phase B — feat/maps-screen (code) | Added `RainDodger/Services/LocationService.swift` (`LocationService` protocol; `LiveLocationService` `CLLocationManagerDelegate`, `.whenInUse`, `kCLLocationAccuracyBestForNavigation`, `headingFilter` 2°, `.portrait`, 10 s location timeout, `LocationError: LocalizedError`, heading stream `trueHeading ≥ 0` else `magneticHeading`; `MockLocationService` — configurable permission, Warsaw Żoliborz 52.2592/20.9916, scripted 0°→45°→90°→180° @1 s), `RainDodger/ViewModels/MapViewModel.swift` (`@MainActor @Observable`; `AuthorizationState` unknown/requesting/authorized/denied; `CameraIntent` recenter/resetNorthAndRecenter; 10 s timeout, heading outlier-drop ≥180° + exponential smoothing factor 0.2; `isCompassVisible` = |heading| > 5°; search/navigate stub messages), views `MapScreenView` (`Map(position:)` + `UserAnnotation()`, `.mapStyle(.standard)`, `.onChange` applies `CameraIntent`, `#Preview` mock), `DestinationSearchField` (56 pt capsule, magnifier + "Your Destination…" + mic decorative + avatar, VO "Your destination field"/"Double tap to search"), `CompassControl` (solid-backing needle, red north tip, rotation -heading eased; Reduce Motion static + read; VO "Compass"/"Double tap to reset to north and recenter"; hidden |heading| ≤ 5°), `MapControlButtonsView` (56 pt dark recenter `location.fill` + white navigate diamonds; VO "Recenter to my location", navigate "Start navigation"/"Double tap to begin"), `LocationPermissionOverlay` (denied: "Location Access Needed" + Open Settings 44 pt), `ComingSoonStub` (hammer glyph, VO "Dismiss"). Modified `RainDodger/ContentView.swift` (template SwiftData list → `MapScreenView` with Live services; import removed), `RainDodger/Info.plist` (`NSLocationWhenInUseUsageDescription` "Rain Dodger uses your location to center the map and show your position."). Decisions: **the iOS 26.5 SDK exposes `MapCameraPosition`/`UserAnnotation`/SwiftUI `Map` only via the cross-import overlay `@_MapKit_SwiftUI` (needs `import MapKit` + `import SwiftUI` in the same file; `import MapKit` alone fails — verified with `swiftc -typecheck`)** so the VM (never imports SwiftUI per rule 003) cannot hold a camera — VM publishes `CameraIntent`, the view owns `@State MapCameraPosition` and applies intents via `.onChange`; `nonisolated` delegate callbacks + `MainActor.assumeIsolated` due to `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`/`SWIFT_APPROACHABLE_CONCURRENCY = YES`; PBXFileSystemSynchronizedRootGroup auto-picks up new files (no pbxproj edit); design §5 VO strings win over plan phrasings (search hint "Double tap to search", navigate "Double tap to begin"); Extra view files Overlay/Stub split per design §3 one-file-per-component. Verified: build clean (`xcode-tools.sh build`), sim screenshots loaded state (Żoliborz map + dot + capsule + button stack + compass hidden) and denied state (overlay + Open Settings). Sim gaps: compass needle motion/heading update is device-only (sim emits no heading); stub taps not UI-automated. Deferred: heading cone (user decision), `DestinationSearchService`/real search, routes/weather, `Item` removal. |
| 2026-09-05 | Phase C — maps-screen controls rework | User request (Google Maps–style reference): top-trailing stacked pair — compass on top, recenter below; navigate button dropped. `CompassControl` rebuilt: always-visible dark `#1C1C1E` circle (56 pt) with rotating cardinal letters N/E/S/W (N bold white, others 72% white) + fixed white top marker; dial rotates -heading (shortest-arc, 0.2 s eased; Reduce Motion static); VO "Compass" + value (cardinal + degrees) + hint reset-north. Removed `isCompassVisible`/hide-near-north from `MapViewModel` (always visible) and `navigateTapped` stub; deleted `MapControlButtonsView.swift` → `RecenterButton.swift` (white circle, dark `location.fill` arrow, VO "Recenter to my location"). `MapScreenView`: controls stacked `.topTrailing` (compass above recenter, 12 pt spacing, 16 pt insets), bottom-right overlay removed; error card no longer needs the button clearance inset. Docs synced: `docs/specs/maps-screen.md` (R6 navigate removed, R4 always-visible + cardinal letters), `docs/designs/maps-screen.md` (screenshot/layout/colors/a11y/motion), `docs/flows/maps-screen.md` (journey + mermaid, edge cases B/D), `docs/template/spec-guide.md` §9 Views list. Verified: `xcode-tools.sh build` + `run` on iPhone 17 sim — screenshot shows compass + recenter stack with system permission prompt; heading rotation is device-only (sim emits no heading). Deferred: no follow-heading mode, no navigate button this branch. |
