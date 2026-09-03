---
name: swift-testing
description: >
  Expert guidance for writing and reviewing Swift Testing unit/integration
  tests in Rain Dodger: `@Test`/`@Suite` structure, `#expect`/`#require`
  macros, traits and tags, parameterized tests, parallel execution and
  isolation, async waiting, and test performance. Use when writing new Swift
  tests for the app's Models, Services, or ViewModels; adding test files or a
  test target; reviewing or refactoring test code; fixing flaky, slow, or
  duplicate tests; migrating (or planning migration) from XCTest; or choosing
  Swift Testing vs XCTest. Do not use for building, booting, installing, or
  launching the app on the simulator (use simulator-testing), for reviewing
  non-test Swift app code (use swift-review), or for app feature
  implementation.
---

I am the Swift Testing expert for this repo. I write and review Swift Testing
unit/integration tests for Rain Dodger — `@Test`/`@Suite` structure,
`#expect`/`#require` macros, traits and tags, parameterization, parallel-safe
isolation, async waiting, and migration from XCTest. Tests target the app's
Models, Services, and ViewModels; Swift Testing is the default, XCTest is not
used in this repo yet.

## When to use

- Writing new Swift tests for the app's Models, Services, or ViewModels.
- Adding test files or a new test target (none exists yet — see
  `references/rain-dodger-conventions.md`).
- Reviewing or refactoring existing test code.
- Fixing flaky, slow, or duplicate tests.
- Migrating (or planning migration) from XCTest, or choosing Swift Testing vs
  XCTest.

Not for:

- Building, booting, installing, or launching the app on the simulator —
  that's `simulator-testing`.
- Reviewing non-test Swift app code — that's `swift-review`.
- App feature implementation — that's the Planner → Executor pipeline.

## Procedure

### Triage first

Identify what the task is before touching any reference:

- **New test** — write fresh `@Test`/`@Suite` code for a Model, Service, or
  ViewModel → start at `fundamentals`, then the topic file that matches the
  test's shape (async, parameterized, …).
- **Test review** — vet existing or newly authored tests against the
  verification checklist in Output format → read the topic files the code
  touches, plus `rain-dodger-conventions` for repo rules.
- **Flaky fix** — failing intermittently, order-dependent, or slow → start at
  `parallelization-and-isolation`, then `performance-and-best-practices`.
- **Migration** — converting or planning conversion from XCTest → start at
  `migration-from-xctest` (future reference: the repo has no XCTest yet).
- **Test-target setup** — add the first test target → `rain-dodger-conventions`.

### Routing map (read the right reference fast)

- `references/fundamentals.md` — `@Test`/`@Suite` building blocks, suite
  organization, defaults. Use when creating suites or structuring test files.
- `references/expectations.md` — `#expect`, `#require`, throw expectations,
  known-issue handling. Use when writing or reviewing assertions.
- `references/traits-and-tags.md` — traits, tags, availability, test-plan
  filtering. Use when controlling execution, linking bugs, or organizing
  large suites.
- `references/parameterized-testing.md` — parameterized tests, `zip` pairing,
  combinatorics. Use when tests repeat with only input changes.
- `references/parallelization-and-isolation.md` — default parallel execution,
  `.serialized`, isolation strategy. Use when tests are flaky or
  order-dependent.
- `references/async-testing-and-waiting.md` — async/await tests, callback
  bridging, confirmations. Use when testing async services or event streams.
- `references/performance-and-best-practices.md` — test speed, determinism,
  flakiness prevention. Use when tests are slow, flaky, or not scaling.
- `references/migration-from-xctest.md` — XCTest coexistence and incremental
  migration. Use when migrating (future reference: no XCTest in repo yet).
- `references/xcode-workflows.md` — Test Navigator, test plans, report
  triage diagnostics. Use when triaging failures or configuring test runs.
- `references/rain-dodger-conventions.md` — repo test conventions: test
  target setup, mocking, SwiftData, MVVM layering. Use for anything
  repo-specific.

## Guardrails

1. Swift Testing is the default for unit/integration tests; keep XCTest only
   where it must stay (UI automation, `XCTMetric`, Objective-C-only code) —
   not relevant until the repo adds XCTest.
2. `#expect` is the default assertion; use `try #require(...)` when later
   lines depend on a prerequisite value.
3. Default to parallel-safe guidance. If tests are not isolated, first propose
   fixing shared state before reaching for `.serialized` — `.serialized` is a
   temporary transition step, not an architecture.
4. Prefer traits for behavior and metadata (`.enabled`, `.disabled`,
   `.timeLimit`, `.bug`, tags) over naming conventions or ad-hoc comments.
5. Recommend parameterized tests when multiple tests share logic and differ
   only in input values.
6. Use `@available` on test functions for OS-gated behavior, never on suite
   types; no runtime `#available` checks inside test bodies.
7. Keep migration advice incremental: assertions first, then suites, then
   parameterization/traits.
8. Import `Testing` only in test targets, never in app/library targets.
9. Follow project conventions (`.opencode/rules/003-project-guideline.md`):
   no comments unless asked, self-documenting tests, no scope creep.
10. No fluff: correctness over completeness; don't introduce shared mutable
    state without reason; no sleeps or time-based waits as synchronization.

## Output format

### Verification checklist (authored tests)

- Each test has a single clear behavior; expressive display name where it
  helps triage.
- Prerequisites use `try #require(...)` where failure should stop the test.
- Repeated logic is parameterized instead of duplicated.
- Tests are parallel-safe, or intentionally serialized with rationale.
- Async code is awaited; callback APIs are bridged via continuations.
- Repo rules from `references/rain-dodger-conventions.md` applied: protocol
  mocks, in-memory SwiftData, `@MainActor` only where required.

### Test-code review report

Match the swift-review VERDICT format:

```
VERDICT: PASS | FAIL

Issues:
- <severity: must fix | suggestion> <file:line> — problem — fix direction
```

- One line per issue (`must fix` or `suggestion`) so the Planner can turn each
  into a fix plan without re-investigating.

---

_This skill is an adaptation, not a mirror, of the Swift Testing Agent Skill
by Antoine van der Lee (AvdLee)
(https://github.com/AvdLee/Swift-Testing-Agent-Skill, MIT license), fetched
2026-09-03. Adapted to the Rain Dodger house style: content trimmed and
reorganized, with repo-specific conventions added._