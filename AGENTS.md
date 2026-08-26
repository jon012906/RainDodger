# AGENTS.md

## Profile

I am an iOS developer working on **Rain Dodger** — a native iOS app for motorcyclists that combines Apple Maps routing with live weather data so riders can plan routes that avoid rain and stay dry.

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

## Architecture & Conventions

- Single-view SwiftUI app today (`RainDodger/`); grows into feature folders: `Models/`, `Services/`, `Views/`, `ViewModels/`
- Services (WeatherKit, Directions, Location) behind protocols so they can be mocked in previews and tests
- Async/await for all service calls; `@MainActor` on ViewModels and observable models
- All map/weather features require Info.plist usage descriptions: `NSLocationWhenInUseUsageDescription`, and WeatherKit entitlements
- Keep the motorcyclist use case front and center: one-hand glanceable UI, gloves-friendly big hit targets, high contrast, works with gloves while riding (support iPhone while mounted)

## Working Agreement

| Responsibility     | User                            | AI                     |
| ------------------ | ------------------------------- | ---------------------- |
| Define the problem | **Lead**                        | Assist                 |
| Product direction  | **Lead**                        | Challenge              |
| User flow          | **Lead**                        | Review                 |
| Architecture       | **Understand & decide**         | Propose/review         |
| Technical research | Participate                     | **Lead/assist**        |
| Coding             | Review/understand               | **Execute**            |
| Boilerplate        | —                               | **Execute**            |
| Testing            | **Verify**                      | Generate/assist        |
| Debugging          | **Reason first**                | Assist                 |
| Final decision     | **User**                        | —                      |

Workflow loop: Think → Specify → Ask AI → Execute → Inspect → Test → Explain → Debug → Reflect

- User keeps ownership of technical reasoning: direction, design, and verification stay with the user
- AI automates implementation-heavy work (git, code, boilerplate) and explains what/why in reviewable increments
- When a spec is ambiguous, AI asks instead of assuming; AI challenges product decisions with tradeoffs, user decides
- User reviews and verifies AI output before it ships

## Agent Workflow (Planner → Executor → Reviewer)

Work is built through three specialized agents, defined in `.opencode/agent/`. Each has ONE job, runs as its own session, and is verified by the user at every hop.

| Agent | Job | Interaction |
|---|---|---|
| Planner | Turn intent into a concrete phase plan + acceptance criteria, aligned with `specs.md`, `design.md`, `flow.md` | Reviews: nothing (plans), and replans fixes from Reviewer issues |
| Executor | Implement exactly the planned phase (or fix plan), verify the build, hand off | Receives: plan. Reviews: own build errors only |
| Reviewer | Verify Executor output against plan + criteria in an isolated session | Verdict: PASS/FAIL + issue lines. Never edits code |

```
User intent ──► Planner ──plan + criteria──► User verify
                                                 │
                                                 ▼
                              Reviewer ──diff/checks──► Executor ──code + build──► User verify
                                  ▲                       ▲
                                  └── issues (FAIL) ──────┘
                                         │
                                         ▼
                                  Planner replans fix ────► Executor ... (loop until PASS)
```

Rules:
- **Roles never merge:** Executor never reviews its own work; Reviewer never fixes issues; Planner never writes code.
- **Separate sessions on purpose:** Executor and Reviewer must never be the same agent — independence (no self-approval/hallucination) is the point.
- **User gates every hop:** the user verifies the plan, the execution result, and the verdict before the pipeline continues; final decision is the user's.
- If the Reviewer fails a phase, the fix loop is: Reviewer issues → Planner fix plan → Executor implements → Reviewer re-verifies → repeat until PASS.
- The user contributes more strongly on the plan activity: Planner drafts and challenges, user decides.
- Never commit or push automatically — user does it explicitly with `@push`.

## Key Rules

- Do NOT add comments unless asked; write self-documenting, readable code
- Build and verify with the Xcode project (`RainDodger.xcodeproj`) — target `RainDodger`
- Prefer Apple frameworks (MapKit, WeatherKit, CoreLocation) over third-party SDKs
- Never commit or push credentials or sensitive assets: API keys, secret keys, tokens, certificates, signing profiles, permission/entitlement files, datasets, ML model pipelines (training data, weights, `.mlmodel` sources), or `.gitignore`-matched identity files — WeatherKit uses entitlements, not keys
- Never commit or push automatically — only commit and push when the user explicitly runs the command `@push`
- Never commit developer identity: signing profiles, certificates, `*.mobileprovision`, `DEVELOPMENT_TEAM` (personal Apple ID / team ID), bundle identifiers (personal `com.<name>.*` IDs), or Xcode user data (`xcuserdata/`) — `.gitignore` already excludes them
- When asked to verify, run `xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger -destination 'platform=iOS Simulator,name=iPhone 16'` (adjust simulator name as available)
