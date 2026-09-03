# Xcode Workflows

Xcode diagnostics workflows: Test Navigator, test plans, and report triage for debugging failures fast. Use when triaging failing tests or configuring focused test runs.

## Test Navigator usage

- Run tests at function, suite, tag, and argument level.
- In parameterized tests, rerun only the failing arguments for fast iteration.

### Example flow

1. Run the suite.
2. Open the failing parameterized argument.
3. Rerun only that argument to iterate quickly.

## Filtering and grouping

- Use tag filters in the navigator for focused development loops.
- Keep tag naming stable so filters and plans stay reusable.
- Prefer tag-based include/exclude over fragile test-name patterns.

## Test plans

- Configure include/exclude tags per target in test plans.
- Use "any tags" vs "all tags" intentionally when combining filters.
- Maintain separate plans for fast core checks vs integration/slower scenarios.

## Report triage

- Review distribution insights for failure clustering by tags, bugs, or destinations.
- Investigate grouped failures first — they often indicate systemic regressions.
- Ensure disabled/known-issue reasons are visible and actionable in reports.

### Triage sequence

1. Check if failures cluster by a shared tag.
2. Open one representative failure.
3. Confirm whether the root cause is common (dependency/outage/config) or test-local.
4. Fix the root cause, then remove temporary known-issue annotations.

## Diagnostic quality

- Keep expectations expressive and narrow — `#expect` captures sub-expressions for focused failure messages.
- Improve argument/type descriptions (`CustomTestStringConvertible`) for faster root-cause identification.
- Ensure bug traits link to trackable issues.

## Checklist

- Tag naming is consistent across suites.
- Test plans reflect the team workflow (local dev, CI, release).
- Parameterized failures are rerun at argument level before broad reruns.