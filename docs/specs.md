# Rain Dodger — Product & Technical Specs

## 1. Goal

Rain Dodger helps motorcyclists get where they're going **without getting wet**. It replicates the familiar interaction patterns of Google Maps / Apple Maps — destination search, route selection, turn-by-turn — but adds a weather-aware layer riders don't have today:

- Find the **driest route** (primary feature)
- Or take the **fastest route** with a clear warning of **which segments are likely to be raining** when you reach them

## 2. Target User & Riding Behavior

Motor riders are familiar with Google Maps / Apple Maps. Their behavior:

1. Type/search destination (or pick a saved one)
2. See 1–3 route alternatives with ETA and distance
3. Pick fastest / preferred route, hit "Start"
4. Follow turn-by-turn, glance at phone while mounted

Rain Dodger keeps all of that — same mental model — and adds a decision layer before step 3.

### Decision Flow (what the rider experiences)

1. Enter destination → routes are requested
2. Each route card shows: ETA, distance, **+ rain risk**
   - **Dry route:** marked "Driest" with sun/umbrella badge, maybe slightly slower
   - **Fastest route:** marked "Fastest" with rain overlays on rain-threatened segments
3. Rider picks a route. Rainy segments are drawn in blue on the map with a chance % (e.g. 78%)
4. Optionally: **best departure time** suggestion (e.g. "leave in 20 min, rain passes in 40 min")
5. Ride starts; map warns when approaching a rain segment

## 3. Key Features (MVP → Later)

| Priority | Feature | Description |
|---|---|---|
| P0 | Route rain overlay | Draw rain probability over route polyline segments |
| P0 | Dry route ranking | Rank alternatives by weighted score: dryness + time |
| P0 | Fastest route warning | Fastest route shown, but rain segments flagged with % chance |
| P1 | Departure time optimizer | Suggest driest time window to leave |
| P1 | Saved destinations | Reuse frequent trips (home/work) |
| P2 | Turn-by-turn with rain warnings | Alert "rain in 5 km" while riding |
| P2 | ML-based rain prediction | Core ML model predicting short-term precipitation along route |
| P3 | Community rain reports | Rider-reported wet/dry segments |

## 4. Frameworks (Tech Stack)

| Concern | Framework | Role |
|---|---|---|
| UI | SwiftUI | All screens; modern `@Observable` state |
| Maps | MapKit | Map display, `MKRoute`/`MKDirections` routing, route alternatives |
| Weather | WeatherKit | Current conditions, precipitation, hourly/daily forecast, precipitation chance |
| Location | CoreLocation | Rider position, authorization (`NSLocationWhenInUseUsageDescription`) |
| ML | **Core ML** | On-device rain prediction: short-term precipitation forecasting along route segments |
| Persistence | SwiftData | Trips, saved destinations, route plans |
| Async | Swift concurrency | `async/await`, `@MainActor` ViewModels |

### Core ML Strategy

- Train (offline / via Create ML or Python + `coremltools`) a model on historical weather + radar data to predict precipitation probability at a (latitude, longitude, time) point
- Inputs: coordinates, time-of-day, historical precip, temperature, humidity, pressure trends
- Output: precipitation chance 0–1 for the segment at the estimated arrival time
- Model is bundled in the app (`.mlmodel`), runs fully on-device — no API keys
- Used as a **confidence layer on top of WeatherKit**: WeatherKit gives hourly forecast for waypoints; Core ML fills gaps between waypoints and blends both into a per-segment rain probability

### Data Flow

```
Destination ──► MKDirections ──► 2-3 route alternatives
                        │
                        ▼
         For each route: sample waypoints every ~1 km
                        │
                        ▼
      WeatherKit hourly precip ─┐
      Core ML short-term model ─┼──► per-segment rain chance + ETA at segment
      route distance/time ─────┘
                        │
                        ▼
   Route cards: Driest / Fastest + rain overlay + departure time
```

## 5. Route Scoring Model

Score each route alternative:

```
Score = w1 × (ETA in minutes) + w2 × (total rain exposure)
rain exposure = Σ over segments (segment length × chance of rain at segment arrival time)
```

- **Driest route:** pick min rain exposure; show ETA penalty honestly
- **Fastest route:** min ETA; show rain overlay + total wet distance ("14 km of 40 km with rain ≥ 50%")

Tunable weights (`w1`, `w2`) live in config so product can tune "how much rain-aversion" without code changes.

## 6. UI Principles (rider-first)

- One-hand glanceable: route cards readable at a glance while mounted
- Glove-friendly: hit targets ≥ 44 pt, minimal precision gestures
- High contrast: dark mode friendly, blue rain overlays distinct from route color
- Rain shown as color-coded segments: e.g. <30% clear, 30–60% yellow, >60% blue/red
- Big "Start ride" button; warnings spoken + visual before rain segments

## 7. Constraints

- iOS 26.5+, iPhone-first, landscape-supported while mounted
- On-device privacy: location + route stay local; no analytics of riding behavior unless user opts in
- No API keys in repo; WeatherKit via entitlements, Core ML bundled
- Weather-dependent feature must degrade gracefully offline (show route without rain overlay, note "live rain unavailable")
