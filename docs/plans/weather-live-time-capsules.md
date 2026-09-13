# Plan: Real-Time Weather & Capsule Icons

## Problem

1. **Static weather times**: Weather forecasts are fetched once based on `departureTime + (fraction × travelTime)` and never update. A user who selects "Leave at 2:00 PM" sees 2:30 PM weather at the midpoint even at 2:45 PM.

2. **Inconsistent capsule icons**: `RainAnnotationBadge` hardcodes `cloud.rain.fill` + "raining" regardless of intensity. The 4-level `RainRisk` icons don't match the desired 3-state visual system.

## Solution

### Part A — Real-Time Weather Refresh

Add a timer-based refresh that recalculates weather forecast points using current time, plus on-demand refresh when the Weather Timeline is opened.

**Files to modify:**

| File | Change |
|------|--------|
| `RainDodger/ViewModels/TripPlannerViewModel.swift` | Add `weatherRefreshTimer`, `startWeatherRefresh()`, `stopWeatherRefresh()`, `refreshWeather()` methods; call `refreshWeather()` from `loadWeather()` completion; add a `refreshIfNeeded()` method for on-demand use |
| `RainDodger/Views/WeatherTimelineView.swift` | Call `viewModel.refreshIfNeeded()` in `.onAppear` |

**Logic:**

```
startWeatherRefresh():
  - Create a Timer.publish(every: 300, on: .main, in: .common) (5 min)
  - On tick: call refreshWeather()

refreshWeather():
  - Guard weatherState == .loaded, let selected alternative
  - Re-run sampleForecast() with departure: Date() (current time)
  - Update routePlan.rainSegments and weatherAnalysis
  - No state transition flash (keep .loaded)

refreshIfNeeded():
  - If weatherState == .loaded and >60s since last refresh, call refreshWeather()

onAppear in WeatherTimelineView:
  - Call viewModel.refreshIfNeeded()
```

**Edge cases:**
- Timer pauses when app enters background (`.common` RunLoop mode handles this)
- Timer stops when route is cleared or new route is planned (`cancelPlan()` already cancels `weatherTask`)
- No visual flash — weather data updates in place

### Part B — 3-State Capsule Icons

Map the 4-level `RainRisk` to 3 visual states:

| RainRisk | Icon | Label |
|----------|------|-------|
| `.low` | `cloud.sun` | Sunny |
| `.moderate` | `cloud.drizzle` | Light |
| `.high` + `.veryHigh` | `cloud.heavyrain` | Raining |

**Files to modify:**

| File | Change |
|------|--------|
| `RainDodger/Models/WeatherModels.swift` | Update `RainRisk.icon` and `RainRisk.label` computed properties |
| `RainDodger/Views/RainAnnotationBadge.swift` | Use `RainRisk`-based icon/label instead of hardcoded `cloud.rain.fill` / "raining"; derive risk from `rainChance` |
| `RainDodger/Views/WeatherTimelineView.swift` | Update `overallRiskSummary` to match new labels |
| `RainDodger/Views/RouteCard.swift` | Update `routeRainRisk` text to match new labels |

**`WeatherModels.swift` changes:**

```swift
var icon: String {
    switch self {
    case .low: "cloud.sun"
    case .moderate: "cloud.drizzle"
    case .high, .veryHigh: "cloud.heavyrain"
    }
}

var label: String {
    switch self {
    case .low: "Sunny"
    case .moderate: "Light"
    case .high, .veryHigh: "Raining"
    }
}
```

**`RainAnnotationBadge.swift` changes:**

Add a `rainRisk` property derived from `rainChance`:
```swift
private var rainRisk: RainRisk {
    if rainChance < 0.25 { return .low }
    if rainChance < 0.50 { return .moderate }
    if rainChance < 0.75 { return .high }
    return .veryHigh
}
```

Update body to use `rainRisk.icon` and `rainRisk.label`.

## Verification

1. Build the project — no errors
2. Launch on simulator — verify weather timeline shows correct icons:
   - Dry segments: cloud.sun + "Sunny"
   - Light rain segments: cloud.drizzle + "Light"
   - Heavy rain segments: cloud.heavyrain + "Raining"
3. Verify RainAnnotationBadge on map uses same icon logic
4. Verify periodic refresh works (set timer to 10s for testing, confirm weather updates)
5. Verify on-demand refresh triggers when opening WeatherTimelineView
6. Run linter/typechecker
