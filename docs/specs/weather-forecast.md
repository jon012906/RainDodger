# Spec — Weather Forecast (Rain Layer)

## 1. Goal

After the rider taps "Check Route", Rain Dodger computes a rainfall forecast along the **selected** route over time: the route path is sampled every 5 km, each sample gets the precipitation probability at the rider's estimated arrival time, and the route is redrawn on the map as color-coded segments (<30% route-blue, 30–60% yellow, ≥60% red) with a legend and a wet-distance summary — so the rider can see at a glance where the road will be rained on.

## 2. User Problem

- A rider planning a trip has no idea which parts of the route will be raining when they arrive — today they only get ETA and distance.
- Weather apps report the destination's weather, not the weather along the path at the time the rider passes each point.
- The rider needs a glanceable, glove-friendly answer: "is this stretch of road wet when I get there, and how much of the ride is wet?"

## 3. Requirements

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| R1 | WeatherKit entitlement `com.apple.developer.weatherkit` present; protocol-first `WeatherService` (Live + Mock) | P0 | Mock = deterministic scripted probabilities for previews/tests |
| R2 | Selected route's polyline sampled every 5,000 m (cap ~60 samples); each sample's arrival time = `departureDate ?? now` + proportional fraction of travel time; `rainChance` fetched per sample in a bounded TaskGroup (chunked ≤ 8 concurrent) | P0 | Arrival-time forecast per point |
| R3 | Blocking full-map loading overlay "Checking rain along your route…" while weather computes | P0 | Non-dismissable; present over the map only |
| R4 | Selected route drawn as per-segment colored strokes REPLACING the route-blue stroke: <30% route-blue, 30–60% yellow, ≥60% red; unselected alternatives stay muted blue as today | P0 | Band mapping shared with the legend |
| R5 | `RainLegend` over the map: "Dry / Light / Heavy rain" chips with % ranges + wet-distance line ("14 km of 40 km with rain ≥ 50%") | P0 | Text not color-only |
| R6 | Weather failure/offline degrades to a non-blocking "live rain unavailable" banner in place of the legend; route fully shown, no crash, plan NOT failed | P0 | |
| R7 | Weather computed for the selected route only; re-selecting another route re-samples/re-fetches (prior in-flight fetch cancelled); re-selecting a route that already has segments reuses them | P0 | No weather on unselected alternatives |
| R8 | MVVM: `@MainActor @Observable` `TripPlannerViewModel` injects `WeatherService`; no comments; accessibility per `.opencode/rules/004-accessibility.md`; mocks in all previews | P0 | |
| R9 | Docs: spec/design/flow per templates; `docs/template/spec-guide.md` §9 + `docs/implementation.md` updated | P0 | |

## 4. Data Model

In-memory value types only — **no SwiftData on this branch**:

- **`RainSegment`** — one forecast sample along the route:
  - `id: UUID`, `index: Int` (sample ordinal), `coordinate: CLLocationCoordinate2D`, `distanceFromStart: CLLocationDistance`, `rainChance: Double` (0–1).
- **`RouteAlternative`** gains `rainSegments: [RainSegment]` (default `[]` so existing inits stay source-compatible).

```mermaid
erDiagram
  ROUTE_ALTERNATIVE ||--o{ RAIN_SEGMENT : "sampled every 5 km"
  ROUTE_ALTERNATIVE {
    uuid id
    double distance
    timeInterval travelTime
    polyline polyline
    array coordinatePoints
    array rainSegments
  }
  RAIN_SEGMENT {
    uuid id
    int index
    coordinate coordinate
    double distanceFromStart
    double rainChance
  }
```

## 5. Rules / Logic

- **Sampling:** walk the selected route's `coordinatePoints` accumulating haversine distance; emit a sample every 5,000 m (the first point is always included; capped at 60 samples).
- **Arrival time per sample:** `departure = departureDate ?? Date()`; `arrival = departure + (distanceFromStart / max(totalDistance, lastSampleDistance)) × travelTime`.
- **Concurrency:** samples fetched in chunks of ≤ 8 via `withThrowingTaskGroup` (bounded); results sorted by `index` before attaching.
- **Bands:** < 0.30 = Dry (route-blue), 0.30–0.60 = Light (yellow), ≥ 0.60 = Heavy rain (red).
- **Wet distance:** sum of segment lengths whose `rainChance ≥ 0.5`; segment length = next sample's `distanceFromStart − this sample's`, and the last segment extends to the route's total distance.
- **Weather failure:** catch the error, keep the route and plan, set `weatherState = .unavailable` → banner. Never fail the plan.
- **Re-selection:** selecting a route without segments cancels the prior weather task and fetches; selecting one with segments reuses them.
- **Re-plan:** an automatic re-route (destination/origin/stop/departure change) cancels the in-flight weather task, resets the weather state to idle, and re-runs routing only — no forecast until the rider taps Check Route again.
- **Trigger:** weather is fetched only by `checkRoute()` (the Check Route tap) or by `selectRoute(_:)` for a route without cached segments.

## 6. Constraints

- iOS 26.5+, iPhone-first; Apple frameworks only (WeatherKit + existing MapKit/CoreLocation/SwiftUI).
- WeatherKit entitlement required; API budget ≈ 500k calls/month → 5 km sampling + ~60-sample cap bounds per-route cost; no caching/persistence this branch.
- Selected-route-only; no dry-route ranking / departure-time sweep (Phase 4).
- Live WeatherKit may return no data on the simulator → device-only manual validation; mock-verifiable path now.
- Offline/WeatherKit failure must degrade gracefully (banner, route still shown).
- No SwiftData/persistence; no changes to the trip-planner routing shell beyond wiring weather in.

## 7. Acceptance Criteria

- [ ] `com.apple.developer.weatherkit` present in `RainDodger/RainDodger.entitlements`; build passes via `.opencode/scripts/xcode-tools.sh build`
- [ ] `WeatherService` protocol + `LiveWeatherService` (WeatherKit) + `MockWeatherService` (deterministic scripted probabilities); no comments
- [ ] Check Route → routing succeeds → blocking "Checking rain along your route…" overlay → selected route sampled every 5 km (cap 60) → per-segment colors + legend + wet distance on the selected route only
- [ ] Picking a destination / changing origin/stop/departure auto-plans routing with NO weather and no overlay; only tapping Check Route starts the forecast.
- [ ] Legend chips "Dry / Light / Heavy rain" + % ranges + "X km of Y km with rain ≥ 50%"; not color-only
- [ ] WeatherKit failure/offline → non-blocking "live rain unavailable" banner in place of the legend; route fully shown; plan not failed
- [ ] Re-selecting a route re-samples/re-fetches (prior fetch cancelled); re-selecting a route with segments reuses them
- [ ] A11y per `.opencode/rules/004-accessibility.md`: VO labels, non-color-only, ≥44 pt, Dynamic Type, Reduce Motion
- [ ] `TripPlannerViewModel` injects `weatherService`; `ContentView` injects `LiveWeatherService`; all `#Preview`s use `MockWeatherService`
- [ ] Docs: `docs/specs/weather-forecast.md`, `docs/designs/weather-forecast.md`, `docs/flows/weather-forecast.md` per templates; `docs/template/spec-guide.md` §9 + `docs/implementation.md` updated