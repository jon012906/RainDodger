# Project Guideline — Rain Dodger

**Load when:** starting any session, or any task that touches the app's scope/stack/architecture/feature implementation, or when building/verifying Swift code and choosing frameworks. One-line identity: native iOS app for motorcyclists — Apple Maps routing + live weather so riders plan rain-free routes.

## Project Profile

- iOS developer building **Rain Dodger** — a native iOS app for motorcyclists that combines Apple Maps routing with live weather data so riders can plan routes that avoid rain and stay dry.

## Project Overview

- **App:** Rain Dodger (iPhone-first, SwiftUI)
- **Deployment target:** iPhone 13 and newer (iOS 26.x); target the latest tech available on iPhone 17 (modern SwiftUI / SwiftData stack, no legacy UIKit)
- **Core idea:** Take a rider's destination, overlay current + forecast rain on Apple Maps routes, and suggest the driest departure time and route.

## Tech Stack

- **Language:** Swift 5.0, modern SwiftUI (`@Observable`, `@Environment`, `NavigationSplitView`/`NavigationStack`)
- **Persistence:** SwiftData (a `ModelContainer` is already wired up in `RainDodgerApp.swift`; template `Item` model still present — will be replaced by domain models like `Trip`, `RoutePlan`, `SavedDestination`)
- **Maps:** Apple Maps — `MapKit` (`MKMapView` via `Map`, `MKRoute`/`MKDirections` for routing)
- **Weather:** `WeatherKit` (`WeatherService`) for current conditions, precipitation, and hourly forecast
- **ML:** `Core ML` for on-device short-term rain prediction (blended with WeatherKit into per-route-segment rain chance)
- **Location:** `CoreLocation` for the rider's current position

## Docs & Definitions

Per-feature docs follow this layout; each file starts from its template in `docs/template/`:

| Doc | Location | Definition |
|---|---|---|
| **Spec** | `docs/specs/<feature>.md` | **What the feature must do** — product requirements (P0/P1/P2), data relations (models, relationships), constraints, acceptance criteria |
| **Design** | `docs/designs/<feature>.md` | **How it must look/feel** — UI/UX per screen (light + dark), components, states; relies on `.opencode/rules/004-accessibility.md` |
| **Flow** | `docs/flows/<feature>.md` | **How the user uses it** — diagrams of the user journey and the events addressed by the feature's spec + design |
| **Implementation** | `docs/implementation.md` | _(TBA — definition to be confirmed)_ |

Rule: every feature contributes one spec, one design, and one flow doc — implementation follows `.opencode/rules/003-project-guideline.md` (MVVM) and `docs/implementation.md`.

## MVVM Architecture (mandatory for every feature)
Canonical blueprint for adding features to Rain Dodger. Follow it for every new feature.

### Folder Structure

```
RainDodger/
├── RainDodgerApp.swift          # App entry, ModelContainer
├── Models/                      # SwiftData + domain models (Trip, RoutePlan, SavedDestination)
├── Services/                    # Protocols + concrete implementations (weather, directions, location)
├── ViewModels/                  # @MainActor @Observable classes (one per screen/feature)
└── Views/                       # SwiftUI views (one per screen, plus reusable components)
```

### Layers

#### Models
- Pure Swift value types or SwiftData `@Model` classes
- No UI logic, no service calls

#### Services
- Protocol first, concrete impl behind it → mockable in previews/tests
- `async/await` only, throw on failure
- Naming: protocol + `Live` impl (e.g. `WeatherService` → `LiveWeatherService`)

#### ViewModels
- `@MainActor` + `@Observable`
- Own state, published via properties; expose `enum`-based `state` for loading/error/loaded
- Call services, never import SwiftUI
- Views observe via `@Environment` or `@State` + `@Bindable`

#### Views
- Thin, dumb SwiftUI views; render ViewModel state only
- Big hit targets (min 44pt), high contrast, glanceable — glove-friendly
- Previews with mocked services

### Rules

1. ViewModel is `@MainActor @Observable`, never imports SwiftUI
2. Views never call services or touch SwiftData directly — always through the ViewModel
3. Services are protocols; inject mocks in previews/tests
4. Feature = one folder set: `Models/X.swift`, `Services/XService.swift`, `ViewModels/XViewModel.swift`, `Views/XView.swift`
5. New SwiftData models must be registered in the `Schema` in `RainDodgerApp.swift`

## Architecture & Conventions

- Single-view SwiftUI app today (`RainDodger/`); grows into feature folders: `Models/`, `Services/`, `Views/`, `ViewModels/`
- Services (WeatherKit, Directions, Location) behind protocols so they can be mocked in previews and tests
- Async/await for all service calls; `@MainActor` on ViewModels and observable models
- All map/weather features require Info.plist usage descriptions: `NSLocationWhenInUseUsageDescription`, and WeatherKit entitlements
- Keep the motorcyclist use case front and center: one-hand glanceable UI, gloves-friendly big hit targets, high contrast, works with gloves while riding (support iPhone while mounted)

## Code Structure

### Build & Verify

- Build and verify with the Xcode project (`RainDodger.xcodeproj`) — target `RainDodger`
- When asked to verify, run `xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger -destination 'platform=iOS Simulator,name=iPhone 16'` (adjust simulator name as available)

### Code Style

- Do NOT add comments unless asked; write self-documenting, readable code

### Frameworks

- Prefer Apple frameworks (MapKit, WeatherKit, CoreLocation) over third-party SDKs
