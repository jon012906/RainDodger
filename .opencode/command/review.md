---
description: Review the latest changes (skill-dispatched), report issues read-only, and propose a fixing plan.
---

The user has invoked `@review`. Review the latest generated code/design changes:

0. **Skill dispatch:** determine the topic, then invoke the skill tool to load the matching review skill and follow its procedure + output format:
   - Swift/app files → `swift-review`
   - Design docs (`docs/designs/*.md`) or design changes → `design-review`
   - Pushed branch / `gh pr` context → `pr-review`
   - Nothing matches (config/docs-only, meta-workflow) → use the built-in steps below
1. Run `git status --short` and `git diff` (plus `git diff --staged` if anything is staged) to see what changed. If `$ARGUMENTS` names specific files or paths, review only those.
2. Review against the Rain Dodger conventions in `.opencode/rules/003-project-guideline.md` and `.opencode/rules/005-commit-push-guidelines.md`:
   - ViewModels are `@MainActor` `@Observable`, never import SwiftUI
   - Services behind protocols, mocked in previews/tests
   - Views are thin, read state only; async/await for all service calls
   - Glove-friendly UI: hit targets ≥ 44pt, high contrast, glanceable
3. Check for correctness: logic bugs, force unwraps, retain cycles, missing error handling, unhandled `async` failures, hardcoded values that should be config.
4. Check for security/identity leaks: no API keys, no `DEVELOPMENT_TEAM`, no `xcuserdata/` staged.
5. Report findings as a concise list of issues, each with: `file:line`, problem, and suggested fix. Separate into **must fix** and **suggestions**. If everything is clean, say so in one line.
6. **If issues were found:** do NOT edit anything — this review is read-only. Report each issue as `file:line`, problem, severity (**must fix** / **suggestion**), and fix direction, then propose an ordered fixing plan and ask the user for approval. Wait for their confirmation before any file is touched.
7. **If the user approves the fixing plan:** the Executor executes it (Planner fix loop: Reviewer issues → Planner fix plan → Executor implements → Reviewer re-verifies). Then re-run this review on the updated diff and report that issues are resolved (or repeat the report/ask cycle for any remaining ones).
