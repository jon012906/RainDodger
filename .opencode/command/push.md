---
description: Commit and push all pending changes to the remote.
---

The user has invoked `@push`. Commit and push the pending work now:

1. Run `git status --short` and `git diff` to inspect all pending changes (staged and unstaged).
2. **Enforce the `.gitignore` rule before anything else.** Verify that no developer-identity files are being committed or pushed:
   - Run `git check-ignore` over every changed/new path; refuse to commit anything matching `.gitignore` identity patterns (`xcuserdata/`, `*.xcuserstate`, `*.pbxuser`, `*.mode1v3`, `*.mode2v3`, `*.perspectivev3`, `*.xccheckout`, `*.mobileprovision`, `*.p12`, `*.cer`, `*.key`, `**/ExportOptions.plist`).
   - Verify `grep -n "DEVELOPMENT_TEAM = [0-9A-Z]" RainDodger.xcodeproj/project.pbxproj` returns nothing before committing; if it does, clear the value first — the `.xcodeproj` must never carry a personal bundle/team identifier.
   - If `.gitignore` is missing or any identity file is staged, fix it before proceeding and report it to the user.
3. Never commit API keys or secrets.
4. Stage only intended files (respecting `.gitignore`) and commit with a concise Conventional Commits message matching the repo style (e.g. `feat:`, `fix:`, `docs:`, `chore:`), subject ≤ 50 chars.
5. Run `git log --oneline -5` to review, then `git push` (set upstream if the branch has none). If no remote is configured, report that push could not be completed.
6. Report the commit hash, files pushed, and push result to the user.
