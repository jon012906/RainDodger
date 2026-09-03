# Rain Dodger Test Conventions

Repo-specific conventions for Swift Testing in Rain Dodger: test-target setup, MVVM layering, mocking, and SwiftData. Use for anything repo-specific; generic Swift Testing guidance lives in the other references.

## Current test state

- **No test target exists yet.** `RainDodger.xcodeproj` has a single application target; `ENABLE_TESTABILITY = YES` is set in the project build settings, so the app module can be `@testable`-imported once a test target is added.
- No XCTest code anywhere; no UI tests.
- Consequence: when the first tests arrive, write Swift Testing directly — there is no legacy XCTest burden to migrate.

## Adding the first test target

- Add a unit-test bundle to `RainDodger.xcodeproj` (host: the Rain Dodger app). `ENABLE_TESTABILITY = YES` is already set, so `@testable import RainDodger` works.
- Import `Testing` in the test target only; the app target must never import `Testing`.
- Mirror the app layout with a `RainDodgerTests/` folder set: `Models/`, `Services/`, `ViewModels/` — one test file per source file under test.

## MVVM layering (per `.opencode/rules/003-project-guideline.md`)

- A feature is one folder set: `Models/`, `Services/`, `ViewModels/`, `Views/`. Unit tests cover the first three; `Views/` are SwiftUI and are verified on the simulator, not unit-tested.
- **Models**: pure Swift value types or SwiftData `@Model` classes — testable without services or UI.
- **Services**: protocol first, concrete implementation behind it — tests inject mocks conforming to the protocol (naming per 003: protocol + `Live` implementation).
- **ViewModels**: `@MainActor @Observable`, never import SwiftUI — their tests annotate `@MainActor`; they call services through the protocol and expose `enum`-based state, which is what tests assert on.
- **Views**: thin SwiftUI views that never call services or SwiftData directly — no unit tests today.

## Mocking services

- Services are protocols, so tests inject conforming mocks/fakes — no real network, WeatherKit, MapKit, or CoreLocation calls in unit tests.
- Prefer small hand-written fakes over third-party mocking frameworks (Apple frameworks over third-party SDKs, per 003).
- The same protocol mocks feed SwiftUI previews; keep shared fakes where both test target and previews can use them.

## SwiftData in tests

- Use an in-memory container — `ModelConfiguration(isStoredInMemoryOnly: true)` — never the on-disk store.
- Register the models under test in the `Schema`, mirroring `RainDodgerApp.swift` (003 rule 5: every new SwiftData model must be registered in the `Schema`).
- Create one fresh container per suite (or per test) — never share one across tests; in-memory containers are cheap and isolate state.

## Async services

- All service calls are `async/await` and throw on failure — tests `await` directly and verify failures with `#expect(throws:)` / `try #require(...)`. Callback bridging is the exception, not the norm (see `async-testing-and-waiting.md`).

## Out of scope

- Accessibility rules (`.opencode/rules/004-accessibility.md`) target UI code — out of scope for unit tests.
- UI automation — none exists; if added later it belongs in a separate UI test target (`XCUIApplication`), not Swift Testing.