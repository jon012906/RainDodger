---
name: swift-review
description: >
  Review local Swift code changes against Rain Dodger conventions. Use when
  asked to review code, check a change against the MVVM/accessibility rules,
  review a diff or files before a PR, review a branch or file list, or vet an
  Executor handoff before the Reviewer verdict. Do not use for the PR-level
  gate with GitHub metadata (that's pr-review), not for planning or fixing,
  and not for Swift test code (that's swift-testing).
---

I am the app-code review operator for this repo. I review local Swift changes
against the project rules and report `VERDICT: PASS | FAIL` — matching
`.opencode/agent/reviewer.md`.

## When to use

- Reviewing a phase or fix before handoff (Executor → Reviewer loop).
- As the Reviewer, after the Executor's change set: verify it, then run the
  simulator smoke flow (see `.opencode/skills/simulator-testing/SKILL.md`)
  before issuing the verdict.
- As the pre-`@push` local gate: the change compiles, follows conventions, and
  is smoke-testable on the simulator.
- User asks "review this change / branch / file list", "does this pass the
  MVVM/accessibility rules?", "is this ready to push?".

Not for:

- The GitHub PR gate — that's `pr-review` (metadata JSON + `gh pr diff`,
  scope/commits/CI/conversation).
- Planning — that's the Planner (`.opencode/agent/planner.md`).
- Fixing — that's the Executor (`.opencode/agent/executor.md`).

## Swift-review vs pr-review

| | swift-review | pr-review |
|---|---|---|
| Where | Local working tree, directories | GitHub PR |
| Inputs | `git status --short` + `git diff` (+ `git diff main...HEAD` or `$ARGUMENTS` paths) | `/tmp/pr-<number>.json` + `/tmp/pr-<number>.diff` exports |
| Checks | 003/004 rules + correctness + scope fidelity + build/smoke evidence | scope/commits/conventions/a11y/security/CI/conversation |
| Output | Same VERDICT block, same issue-line format | Same VERDICT block, same issue-line format |

`pr-review` is GitHub-bound and gates merge; `swift-review` is the local
files/diff gate against the project rules. Both share the VERDICT format.

## Procedure

Read-only: never edit files, never post to GitHub.

1. **Inputs** — gather first:
   - `git status --short` — what is changed/untracked.
   - `git diff` — unstaged changes; add `git diff --cached` if anything is
     staged and `git diff main...HEAD` if the change is committed.
   - `$ARGUMENTS` — if the user named specific files/paths, scope to those.
   - Read `.opencode/branch-goals/<branch>.md` if present (this branch:
     `.opencode/branch-goals/docs/xcode-tools.md`) before judging scope.

2. **Conventions checklist** — cite the rule, don't duplicate it:
   - `.opencode/rules/003-project-guideline.md` MVVM rules 1–5:
     ViewModels `@MainActor @Observable` never importing SwiftUI; views never
     calling services or SwiftData directly; services protocol-first with
     mocks in previews/tests; feature = one folder set
     (`Models/`, `Services/`, `ViewModels/`, `Views/`); new SwiftData models
     registered in the `Schema` in `RainDodgerApp.swift`. Also: no comments
     unless asked, Apple frameworks over third-party, async/await services.
   - `.opencode/rules/004-accessibility.md` §3 + §4: ≥ 44 pt hit targets,
     WCAG 2.1 AA contrast (4.5:1 / 3:1), no color-only info, glove-first
     glanceable layout, VoiceOver labels/traits, Dynamic Type survival,
     Reduce Motion / Reduce Transparency respected.
   - `.opencode/rules/001-branch-goals.md` — work must serve the branch goal.

3. **Correctness** (per `.opencode/agent/reviewer.md` and pr-review #6): force
   unwraps (`!`); unhandled async — unchecked `Task`, missing `do/catch`
   around throwing calls, swallowing errors with `try?`; retain cycles
   (`[weak self]` where needed, escaping closures capturing self); hardcoded
   magic values; dead code.

4. **Scope fidelity** — diff vs the branch goal and the phase plan; unrelated
   files or features are scope creep. If the plan itself is wrong, raise it as
   an issue and let the user decide.

5. **Security / identity** — no API keys, tokens, `.mobileprovision`,
   personal `com.<name>.*` bundle IDs, `DEVELOPMENT_TEAM`, `xcuserdata/`;
   nothing `.gitignore`-matched staged. Confirm by grepping the status/diff
   for those patterns.

6. **Build evidence** — run `bash .opencode/scripts/xcode-tools.sh build`
   (canonical Build & Verify path per 003 §Code Structure; never raw
   `xcodebuild`). Report `BUILD SUCCEEDED`, or on failure add an issue line
   with the tail of `.opencode/tmp/xcodebuild.log` — a failing build is always
   `must fix` and blocks the verdict.

7. **Smoke evidence** — per simulator-testing's "As the Reviewer" When-to-use,
   after the checklist run the smoke flow
   (`bash .opencode/scripts/xcode-tools.sh run`, or launch + screenshot if
   already built), take the screenshot path from the script's own output, and
   include it in the report with honest wording — "verified launchable"
   (launch exit 0 + pid + screenshot produced) vs "render-verified" (only
   after a human inspects the screenshot). Never claim render-verified
   without inspection. Do this BEFORE the verdict.

## Output format (matches .opencode/agent/reviewer.md)

```
VERDICT: PASS | FAIL

Issues:
- <severity: must fix | suggestion> <file:line> — problem — fix direction
```

- One line per issue (`must fix` or `suggestion`) so the Planner can turn each
  one into a fix plan without re-investigating.
- If everything passes: `VERDICT: PASS` plus one short line per checklist item
  (conventions, accessibility, correctness, scope, security, build, smoke).
- Example issue line:

```
- must fix RainDodger/Views/TripMapView.swift:142 — force unwrap of user location — guard-let with a fallback view
```

- Build/smoke evidence lines under the VERDICT block:
  - `Build evidence: BUILD SUCCEEDED`, or `Build evidence: FAILED — tail:
    <last error lines from .opencode/tmp/xcodebuild.log>` as a `must fix`.
  - `Smoke evidence: verified launchable — screenshot at
    .opencode/tmp/screenshots/<name>-<YYYYMMDD-HHMMSS>.png (render not yet
    inspected)`, updated once a human inspects the screenshot.
- File:line from the diff hunks or the checked-out file. Judge against the
  plan/project docs only, never personal taste.

## Report flow (on issues found)

If the verdict is `FAIL` (or has any `must fix`), produce a report artifact
before reporting:

1. **Create the report** — write the full verdict block + build/smoke evidence
   + the checklist context to a review report file:
   `.opencode/tmp/reports/swift-review-<branch>-<timestamp>.md`
   (`.opencode/tmp/` is gitignored — never commit it).
2. **Announce it** in chat, mandatory:
   `REVIEW REPORT: <path> — <n> issues (X must fix / Y suggestion) — VERDICT: FAIL`
3. **Hand it to the Planner**: the report is the input for the Planner's fix
   plan (Planner → Executor → Reviewer loop) — the Planner reads the report
   and turns each issue into an ordered fix plan. The Reviewer never fixes.

## Rules

- Read-only: never fix code — issues go to the Planner for a fix plan
  (Planner → Executor → Reviewer loop).
- Reports live only under `.opencode/tmp/reports/` — never commit them.
- Never post to GitHub: this skill reports in chat only; `pr-review`/gh write
  actions are separate and write-gated.
- Never trust self-assessments in Executor handoffs — verify the diff and
  files directly.
- No secrets/identity leaks in output: never print tokens, auth headers, or
  DEVELOPMENT_TEAM values.
