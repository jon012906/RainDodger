---
description: Execute the current plan or phase, then verify it with @review.
---

The user has invoked `@implement`. Execute the plan or phase that is currently in progress:

1. Identify the active plan or phase: read the user's `$ARGUMENTS` (e.g. a feature, todo, or milestone name like `@implement Trip Planner`); if none given, look at the current todo list / most recent plan described in this session.
2. Follow the Rain Dodger architecture in `docs/MVVM-Architecture-Template.md` and conventions in `AGENTS.md`:
   - Feature = one folder set: `Models/`, `Services/`, `ViewModels/`, `Views/`
   - ViewModels are `@MainActor` `@Observable`, never import SwiftUI
   - Services behind protocols, mocked in previews/tests
   - New SwiftData models registered in the `Schema` in `RainDodgerApp.swift`
   - No comments unless asked; self-documenting code
3. Implement the plan phase by phase, in order. After each phase:
   - Verify the change compiles by running `xcodebuild build -project RainDodger.xcodeproj -scheme RainDodger -destination 'platform=iOS Simulator,name=iPhone 16'` (adjust simulator name as available)
   - Fix any build errors before moving to the next phase
4. When the full plan/phase is implemented, run the review workflow (`@review`) on the generated output:
   - The review identifies issues and reports them to the user with `file:line`, problem, and suggested fix
   - It proposes a fixing plan and asks the user to approve executing it
   - Correct any approved issues until the review reports clean
5. Report a concise summary: what was implemented (files added/changed), build status, and the review result.
6. Never commit or push — the user does that explicitly with `@push`.
