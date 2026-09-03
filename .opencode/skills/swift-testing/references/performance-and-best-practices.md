# Performance and Best Practices

Fast, deterministic, parallel-safe Swift Testing suites: principles and practical patterns. Use when test runs are slow, flaky, or not scaling in CI.

> Rain Dodger: mock dependencies via protocol-first services (`.opencode/rules/003-project-guideline.md` rule 3) and use in-memory SwiftData `ModelContainer`s for persistence tests — never real network, filesystem, or on-disk stores in unit tests. See `rain-dodger-conventions.md`.

## Core principles

- Prefer deterministic tests over timing-sensitive tests.
- Prefer synchronous verification when asynchronous waiting is not required.
- Keep tests independent so parallel execution remains safe and effective.
- Treat `.serialized` as a temporary compromise, not a default architecture.

## 1) Keep tests synchronous where possible

Synchronous tests generally run faster and are easier to reason about.

```swift
struct PriceCalculator {
    static func total(_ subtotal: Int, discount: Int) -> Int { subtotal - discount }
}

@Test func totalCalculation() {
    #expect(PriceCalculator.total(100, discount: 20) == 80)
}
```

Avoid introducing `async` or sleeps for purely synchronous logic.

```swift
// Avoid:
// @Test func totalCalculation() async {
//     try await Task.sleep(nanoseconds: 100_000_000)
//     #expect(...)
// }
```

## 2) Avoid unnecessary main-actor isolation

`@MainActor` can reduce useful parallelization and should be used only when code truly needs main-thread isolation.

```swift
// Good: non-UI logic stays non-main-actor.
@Test func parserIsStable() {
    #expect("A,B,C".split(separator: ",").count == 3)
}

// Use @MainActor only for UI/main-thread sensitive code.
@MainActor
@Test func viewModelMutation() {
    #expect(true)
}
```

## 3) Remove shared mutable state

Shared mutable state is a major source of flakiness and parallel failures.

```swift
enum Globals {
    static var token: String?
}

// Flaky pattern:
@Test func writeToken() {
    Globals.token = "abc"
    #expect(Globals.token == "abc")
}

@Test func expectsNoToken() {
    #expect(Globals.token == nil)
}
```

Better: create isolated state per test.

```swift
struct SessionState {
    var token: String?
}

@Test func isolatedTokenState() {
    var state = SessionState()
    state.token = "abc"
    #expect(state.token == "abc")
}
```

## 4) Prefer in-memory dependencies for the fast path

Use fakes/in-memory repositories for high-volume test runs; reserve real integration dependencies for dedicated plans.

```swift
protocol CacheStore {
    func put(key: String, value: String)
    func get(key: String) -> String?
}

final class InMemoryCacheStore: CacheStore {
    private var values: [String: String] = [:]
    func put(key: String, value: String) { values[key] = value }
    func get(key: String) -> String? { values[key] }
}

@Test func cacheRoundTrip() {
    let cache = InMemoryCacheStore()
    cache.put(key: "user", value: "42")
    #expect(cache.get(key: "user") == "42")
}
```

## 5) Use parameterized tests to reduce overhead and improve diagnostics

```swift
func isValidPort(_ value: Int) -> Bool { (1...65535).contains(value) }

@Test(arguments: [1, 80, 443, 65535])
func validPorts(_ port: Int) {
    #expect(isValidPort(port))
}
```

This reduces duplicated setup code and gives argument-level failure visibility.

## 6) Keep setup cheap and scoped

- Build expensive fixtures only when needed.
- Prefer per-suite immutable setup for shared readonly data.
- Avoid network/file-system setup in unit tests unless behavior depends on it.

```swift
struct CurrencyTests {
    let rates: [String: Double]

    init() {
        rates = ["USD": 1.0, "EUR": 0.92]
    }

    @Test func hasEURRate() {
        #expect(rates["EUR"] != nil)
    }
}
```

## 7) Use `.serialized` narrowly

```swift
@Suite(.serialized)
struct TemporarySerialDBTests {
    @Test func migrationA() async throws { #expect(true) }
    @Test func migrationB() async throws { #expect(true) }
}
```

Add TODO context and remove once dependencies are isolated.

## 8) Flakiness reduction checklist

- No reliance on execution order.
- No shared mutable globals/singletons without reset.
- No arbitrary sleeps as synchronization.
- No hidden external dependencies in unit tests.
- Deterministic fixtures and stable clocks/random sources.
- Explicit known-issue wrappers for temporary failures.

## Quick do / don't

- Do optimize for determinism first, then speed.
- Do keep most tests parallel-safe and dependency-light.
- Don't treat test slowness as only a hardware problem.
- Don't move everything to `@MainActor` or `.serialized` to silence flakiness.