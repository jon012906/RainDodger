# opencode Command Guide — Rain Dodger

This project ships custom opencode commands in `.opencode/command/`. This guide explains each one — what it does, when to use it, and how to invoke it.

## How commands work

- Type `@` in the opencode prompt and pick a command, or type it directly: `@research`, `@implement`, `@review`.
- Everything after the command name is passed as `$ARGUMENTS` and can steer the command (e.g. `@review TripPlannerView.swift`).
- Commands are instructions the AI executes; the user always reviews the result before it ships.
- After editing any `.opencode/command/*.md` file, **restart opencode** so the change is picked up.
- One golden rule from `AGENTS.md`: nothing is committed or pushed automatically — that only happens on `@push`.

## Command overview

| Command | Purpose | Typically used |
|---|---|---|
| `@research` | Investigate a technical question, report with sources | Before implementing something new |
| `@implement` | Execute the plan/phase, then verify it builds | After `@research` produced a recommendation |
| `@review` | Review the latest code changes, report issues | After `@implement`, before `@push` |
| `@push` | Commit + push pending work (identity checks) | When work is verified |
| `@rebase` | Rebase current branch onto latest of another | Before `@push` when remote moved |
| `@clean-commit-history` | Scrub leaked credentials from git history | Emergency only |

---

## `@research`

**What it does:** Searches the web (Apple docs first) for a technical question, evaluates it against the Rain Dodger stack, and reports: bottom line, findings with sources, tradeoffs, and a recommendation. **Does not write code.**

**When to use:** You're unsure about an API, framework behavior, or tradeoff — e.g. WeatherKit limits, Core ML feasibility, SwiftData migration rules.

**Examples:**

```
@research WeatherKit hourly forecast maximum time horizon and accuracy
@research Core ML on-device rain nowcasting vs WeatherKit minute forecast
@research MapKit route alternatives limit and how to draw custom polyline overlays
```

**Output shape:** Bottom line → Findings + links → Tradeoffs/risks → Recommendation with confidence, plus what to do next.

---

## `@implement`

**What it does:** Executes the plan or phase in progress (from `$ARGUMENTS` or the session's to-do list) following `.opencode/rules/003-project-guideline.md` and `AGENTS.md`. Builds after each phase with `xcodebuild` and runs the review flow at the end.

**When to use:** Everything concrete in the flow — features, milestones, or named plans.

**Examples:**

```
@implement Phase 1 Foundation
@implement Search screen with destination suggestions
```

**What it does not do:** It never commits or pushes — that stays with `@push`.

**Workflow:** Set up the plan in `docs/implementation.md` (or describe it inline) → `@implement <phase>` → it builds → it calls `@review` → fixes approved issues → reports summary.

---

## `@review`

**What it does:** Runs `git status` + `git diff`, checks the changes against project conventions (project guideline, glove-friendly rules, no identity leaks), and reports a list of issues: `file:line`, problem, suggested fix — split into **must fix** and **suggestions**. If issues exist it proposes a fixing plan and asks for approval before touching files.

**When to use:** After `@implement`, before `@push`. Also for reviewing any hand-made diff.

**Examples:**

```
@review
@review Views RouteMapView
```

---

## `@push`

**What it does:** Enforces identity/secret rules (`.gitignore` check, no `DEVELOPMENT_TEAM` in the pbxproj, no API keys), commits pending changes with a Conventional Commits message (subject ≤ 50 chars), and pushes to the remote.

**When to use:** Only when you want the work committed and pushed — and only after verification.

**Example:**

```
@push
```

**Note:** If the remote moved, run `@rebase main` first.

---

## `@rebase`

**What it does:** Rebase the current branch onto the latest of another branch (defaults to `origin/main`). Aborts if there are uncommitted changes (commit them or stash first). Resolves conflicts commit by commit. Never force-pushes without explicit user confirmation.

**When to use:** Remote branch is ahead of your local work, before pushing.

**Examples:**

```
@rebase main
@rebase origin/develop
```

---

## `@clean-commit-history`

**What it does:** Completely removes a file (e.g. a leaked credentials file) from git history using `git filter-repo` (or `filter-branch` fallback).

**When to use:** Emergency only — a credential or identity file was committed at some point in history. It's destructive: all commit hashes change and collaborators must re-clone.

**Example:**

```
@clean-commit-history secrets.json
```

**Important:** After scrubbing, a **force push is required** — and the credential must still be rotated/revoked, because forks and clones may hold it. A history scrub does not un-leak anything.

---

## Example end-to-end session

```
1. @research MapKit route alternatives on iOS 26
   → report: limit info, overlay approach, recommendation
2. User decision → plan in docs/implementation.md (or as a to-do list)
3. @implement Phase 2 Routing MVP
   → builds, then auto-runs @review
4. @review → issues found → approve fixing plan → fixes
5. @rebase main          (if remote moved)
6. @push                 (identity checks, commit, push)
```

## Conventions that apply to every command

- No comments in code unless asked; self-documenting code.
- Every feature: Model + Service (protocol) + `@MainActor @Observable` ViewModel + View.
- New SwiftData models registered in `RainDodgerApp.swift` `Schema`.
- Glove-first UI: ≥ 44 pt hit targets, high contrast, glanceable.
- Verification: `xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger -destination 'platform=iOS Simulator,name=iPhone 16'`.
