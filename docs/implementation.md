# Implementation Log — Rain Dodger

Living document that tracks the app from Xcode template to a working app, and records the **user's changes in each phase**. Each phase is executed with `@implement <Phase>` and verified with `@review`; every change made in a phase is documented here (see **Change Log**). A phase is **done** only when everything in its checklist is complete, the project builds (`xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger`), and `@review` reports clean.

## How to work this file

- Each phase is executed with `@implement <Phase>` (or ran as its own plan), then checked with `@review`.
- Tick checkboxes as work completes; move a phase to `Done` only when verified.
- Feature work always follows `.opencode/rules/003-project-guideline.md`; visual work follows the feature's design doc in `docs/designs/`; scope follows `docs/specs/spec-guide.md`.
- Never commit or push here — the user does it explicitly with `@push`.

## Phase 0 — Baseline (current state)

- [x] Xcode project `RainDodger.xcodeproj` builds on iPhone 16 simulator
- [x] SwiftData `ModelContainer` wired in `RainDodgerApp.swift`
- [x] Docs in place: `docs/specs/spec-guide.md`, `docs/template/design.md`, `.opencode/rules/003-project-guideline.md`
- [ ] Template `Item` model replaced by domain models (see Phase 2)

## Phase 1 — Foundation

Goal: repo-level skeleton every feature builds on. No visible features yet.

- [ ] Feature folders created: `Models/`, `Services/`, `ViewModels/`, `Views/`
- [ ] Service protocols with `async/await`: `WeatherService`, `DirectionsService`, `LocationService`
- [ ] Mock live implementations for previews/tests
- [ ] `Info.plist`: `NSLocationWhenInUseUsageDescription` added
- [ ] WeatherKit entitlement enabled and configured in the project
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
| | | |
