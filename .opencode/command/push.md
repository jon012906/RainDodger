---
description: Commit and push pending changes — first ask the user for commit message ideas (per file or grouped), then help rephrase before committing.
---

The user has invoked `@push`. Commit and push the pending work:

1. Run `git status --short` and `git diff` to inspect all pending changes (staged and unstaged).
2. **Enforce the `.gitignore` rule before anything else.** Verify that no developer-identity files are being committed or pushed:
   - Run `git check-ignore` over every changed/new path; refuse to commit anything matching `.gitignore` identity patterns (`xcuserdata/`, `*.xcuserstate`, `*.pbxuser`, `*.mode1v3`, `*.mode2v3`, `*.perspectivev3`, `*.xccheckout`, `*.mobileprovision`, `*.p12`, `*.cer`, `*.key`, `**/ExportOptions.plist`).
   - Verify `grep -n "DEVELOPMENT_TEAM = [0-9A-Z]" RainDodger.xcodeproj/project.pbxproj` returns nothing before committing; if it does, clear the value first — the `.xcodeproj` must never carry a personal bundle/team identifier.
   - If `.gitignore` is missing or any identity file is staged, fix it before proceeding and report it to the user.
3. Never commit API keys or secrets.
4. **Propose a commit plan (grouping):** group the pending changes into commits before writing anything:
   - One commit per single unrelated file (e.g. fix in one file, docs in another)
   - One commit per group of related files (same feature/change area), e.g. `TripPlannerViewModel.swift` + `TripPlannerView.swift` + `Models/Trip.swift`
   - Present the grouping to the user: each group = list of files + suggested subject, and explain why the group is one coherent change.
5. **Ask for the user's commit message:** for each group, ask the user what message they want (they may provide keywords, a draft, or their preferred message; they can also take the suggested one). This is their message — do not override.
6. **Help rephrase:** after they give it, help refine before committing:
   - Match repo style: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`), subject ≤ 50 chars, imperative mood
   - Keep their intent/words, only sharpen grammar and precision
   - Show the proposed (rewritten) message next to the original and ask to confirm before committing
7. Stage and commit per group in order, respecting `.gitignore`.
8. Run `git log --oneline -5` to review, then `git push` (set upstream if the branch has none). If no remote is configured, report that push could not be completed.
9. Report the commit hash(es), files pushed, and push result to the user.
