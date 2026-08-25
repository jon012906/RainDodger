---
description: Commit and push all pending changes to the remote.
---

The user has invoked `@push`. Commit and push the pending work now:

1. Run `git status --short` and `git diff` to inspect all pending changes (staged and unstaged).
2. Never stage or commit developer identity: `xcuserdata/`, `*.mobileprovision`, `*.p12`, `*.cer`, certificates, or any `DEVELOPMENT_TEAM` value in `project.pbxproj`. Verify `grep -n "DEVELOPMENT_TEAM = [0-9A-Z]" RainDodger.xcodeproj/project.pbxproj` returns nothing before committing; if it does, clear the value first.
3. Never commit API keys or secrets.
4. Stage only intended files and commit with a concise Conventional Commits message matching the repo style (e.g. `feat:`, `fix:`, `docs:`, `chore:`), subject ≤ 50 chars.
5. Run `git log --oneline -5` to review, then `git push` (set upstream if the branch has none). If no remote is configured, report that push could not be completed.
6. Report the commit hash and push result to the user.
