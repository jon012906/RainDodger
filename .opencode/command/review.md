---
description: Review the latest generated code changes, report issues, and propose a fixing plan.
---

The user has invoked `@review`. Review the output of the generated/developed code:

1. Run `git status --short` and `git diff` (plus `git diff --staged` if anything is staged) to see what changed. If `$ARGUMENTS` names specific files or paths, review only those.
2. Review against the Rain Dodger conventions in `AGENTS.md` and the architecture in `docs/MVVM-Architecture-Template.md`:
   - ViewModels are `@MainActor` `@Observable`, never import SwiftUI
   - Services behind protocols, mocked in previews/tests
   - Views are thin, read state only; async/await for all service calls
   - Glove-friendly UI: hit targets ≥ 44pt, high contrast, glanceable
3. Check for correctness: logic bugs, force unwraps, retain cycles, missing error handling, unhandled `async` failures, hardcoded values that should be config.
4. Check for security/identity leaks: no API keys, no `DEVELOPMENT_TEAM`, no `xcuserdata/` staged.
5. Report findings as a concise list of issues, each with: `file:line`, problem, and suggested fix. Separate into **must fix** and **suggestions**. If everything is clean, say so in one line.
6. **If issues were found:** do NOT edit anything yet. Report the issues to the user, then propose a fixing plan (ordered list of edits) and ask the user for approval to execute it. Wait for their confirmation before touching any file.
7. **If the user approves the fixing plan:** execute the fixes one by one, then re-run this review on the updated diff and report that issues are resolved (or repeat the report/ask cycle for any remaining ones).
