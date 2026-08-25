# AGENTS.md

## Profile

I am an iOS developer working on **Rain Dodger** — a native iOS app for motorcyclists that combines Apple Maps routing with live weather data so riders can plan routes that avoid rain and stay dry.

## Project Overview

- **App:** Rain Dodger (iPhone-first, SwiftUI)
- **Deployment target:** iOS 26.5 (modern SwiftUI / SwiftData stack, no legacy UIKit)
- **Core idea:** Take a rider's destination, overlay current + forecast rain on Apple Maps routes, and suggest the driest departure time and route.

## Tech Stack

- **Language:** Swift 5.0, modern SwiftUI (`@Observable`, `@Environment`, `NavigationSplitView`/`NavigationStack`)
- **Persistence:** SwiftData (a `ModelContainer` is already wired up in `RainDodgerApp.swift`; template `Item` model still present — will be replaced by domain models like `Trip`, `RoutePlan`, `SavedDestination`)
- **Maps:** Apple Maps — `MapKit` (`MKMapView` via `Map`, `MKRoute`/`MKDirections` for routing)
- **Weather:** `WeatherKit` (`WeatherService`) for current conditions, precipitation, and hourly forecast
- **ML:** `Core ML` for on-device short-term rain prediction (blended with WeatherKit into per-route-segment rain chance)
- **Location:** `CoreLocation` for the rider's current position

## Architecture & Conventions

- Single-view SwiftUI app today (`RainDodger/`); grows into feature folders: `Models/`, `Services/`, `Views/`, `ViewModels/`
- Services (WeatherKit, Directions, Location) behind protocols so they can be mocked in previews and tests
- Async/await for all service calls; `@MainActor` on ViewModels and observable models
- All map/weather features require Info.plist usage descriptions: `NSLocationWhenInUseUsageDescription`, and WeatherKit entitlements
- Keep the motorcyclist use case front and center: one-hand glanceable UI, gloves-friendly big hit targets, high contrast, works with gloves while riding (support iPhone while mounted)

## Key Rules

- Do NOT add comments unless asked; write self-documenting, readable code
- Build and verify with the Xcode project (`RainDodger.xcodeproj`) — target `RainDodger`
- Prefer Apple frameworks (MapKit, WeatherKit, CoreLocation) over third-party SDKs
- Never commit API keys or secrets; WeatherKit uses entitlements, not keys
- Never commit or push automatically — only commit and push when the user explicitly runs the command `@push`
- Never commit developer identity: signing profiles, certificates, `*.mobileprovision`, `DEVELOPMENT_TEAM` (personal Apple ID / team ID), or Xcode user data (`xcuserdata/`) — `.gitignore` already excludes them
- When asked to verify, run `xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger -destination 'platform=iOS Simulator,name=iPhone 16'` (adjust simulator name as available)
