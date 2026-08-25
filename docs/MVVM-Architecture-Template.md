# MVVM Architecture Template — Rain Dodger

Canonical blueprint for adding features to Rain Dodger. Follow this template for every new feature.

## Folder Structure

```
RainDodger/
├── RainDodgerApp.swift          # App entry, ModelContainer
├── Models/                      # SwiftData + domain models (Trip, RoutePlan, SavedDestination)
├── Services/                    # Protocols + concrete implementations (weather, directions, location)
├── ViewModels/                  # @MainActor @Observable classes (one per screen/feature)
└── Views/                       # SwiftUI views (one per screen, plus reusable components)
```

## Layers

### Models
- Pure Swift value types or SwiftData `@Model` classes
- No UI logic, no service calls

### Services
- Protocol first, concrete impl behind it → mockable in previews/tests
- `async/await` only, throw on failure
- Naming: `WeatherServicing` protocol, `WeatherService` impl, or protocol named `WeatherService` with `LiveWeatherService` impl

```swift
protocol WeatherService {
    func currentCondition(at location: CLLocation) async throws -> WeatherCondition
}

struct LiveWeatherService: WeatherService {
    func currentCondition(at location: CLLocation) async throws -> WeatherCondition { ... }
}
```

### ViewModels
- `@MainActor` + `@Observable`
- Own state, published via properties; expose `enum`-based `state` for loading/error/loaded
- Call services, never import SwiftUI
- Views observe via `@Environment` or `@State` + `@Bindable`

```swift
@MainActor
@Observable
final class TripPlannerViewModel {
    enum State {
        case idle, loading, loaded(TripPlan), failed(String)
    }

    private(set) var state: State = .idle

    private let weather: any WeatherService
    private let directions: any DirectionsService

    init(weather: any WeatherService, directions: any DirectionsService) {
        self.weather = weather
        self.directions = directions
    }

    func planTrip(to destination: Destination) async {
        state = .loading
        do {
            let route = try await directions.route(to: destination)
            let condition = try await weather.currentCondition(at: destination.location)
            state = .loaded(TripPlan(route: route, condition: condition))
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}
```

### Views
- Thin, dumb SwiftUI views; render ViewModel state only
- Big hit targets (min 44pt), high contrast, glanceable — glove-friendly
- Preview with mocked services:

```swift
#Preview {
    TripPlannerView(
        viewModel: TripPlannerViewModel(
            weather: MockWeatherService(),
            directions: MockDirectionsService()
        )
    )
}
```

## Rules

1. ViewModel is `@MainActor @Observable`, never imports SwiftUI
2. Views never call services or touch SwiftData directly — always through the ViewModel
3. Services are protocols; inject mocks in previews/tests
4. Feature = one folder set: `Models/X.swift`, `Services/XService.swift`, `ViewModels/XViewModel.swift`, `Views/XView.swift`
5. New SwiftData models must be registered in the `Schema` in `RainDodgerApp.swift`
