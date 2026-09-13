---
description: Execute the current plan or phase, then verify it with @review.
---

The user has invoked `@implement`. Execute the plan or phase that is currently in progress:

1. Identify the active plan or phase: read the user's `$ARGUMENTS` (e.g. a plan ID like `weather-enhance-p01`, a feature, todo, or milestone name like `@implement Trip Planner`); if none given, check `.opencode/tmp/plans/` for the latest plan file on this branch (`git branch --show-current`) and read it; otherwise look at the current todo list / most recent plan described in this session. The plan file at `.opencode/tmp/plans/<plan-id>.md` is the single source of truth — read it fully before implementing (see `.opencode/rules/006-plan-artifacts.md`).
2. Follow the Rain Dodger architecture in `.opencode/rules/003-project-guideline.md`:
   - Feature = one folder set: `Models/`, `Services/`, `ViewModels/`, `Views/`
   - ViewModels are `@MainActor` `@Observable`, never import SwiftUI
   - Services behind protocols, mocked in previews/tests
   - New SwiftData models registered in the `Schema` in `RainDodgerApp.swift`
   - No comments unless asked; self-documenting code
   - Keep the review handoff checklist format from `.opencode/rules/002-workflow.md`
3. Implement the plan phase by phase, in order. After each phase:
   - Verify the change compiles by running `./.opencode/scripts/xcode-tools.sh build` (canonical path; simulator from `simulator-config.json`/`RD_SIM`)
   - Fix any build errors before moving to the next phase
4. When the full plan/phase is implemented, run the review workflow (`@review`) on the generated output:
   - The review identifies issues and reports them to the user with `file:line`, problem, and suggested fix
   - It proposes a fixing plan and asks the user to approve executing it
   - Correct any approved issues until the review reports clean
5. Report a concise summary: what was implemented (files added/changed), build status, and the review result.
6. Never commit or push — the user does that explicitly with `@push`.
