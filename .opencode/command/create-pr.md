---
description: Create a pull request from the repo PR template. Usage: /create-pr
---

The user wants to open a PR for the current branch, filled from `.github/pull_request_template.md`.

1. **Verify branch:** run `git branch --show-current`. Refuse if on `main` — a PR needs a feature branch.
2. **Verify push state:** run `git status -sb`. If the branch has no upstream or is ahead of origin, tell the user to run `@push` first — never push implicitly (github-cli rule). Only proceed once the branch is fully pushed.
3. **Gather context:**
   - Read `.opencode/branch-goals/<branch>.md` (if present) for the one-line goal recap.
   - Commits: `git log origin/main..HEAD --oneline --no-merges`.
   - Files: `git diff origin/main...HEAD --stat`.
   - Phase plan: if the branch's plan doc exists under `docs/specs/`, summarize its phases for the Phases table; otherwise omit that table with a note.
   - Verification evidence: check for a recent screenshot in `.opencode/tmp/screenshots/` and any reviewer verdict file; if evidence is missing or unclear, ask the user what to put in Verification.
4. **Draft the PR body:** fill every section of `.github/pull_request_template.md` (Summary, Phases, Changes, Verification, Related, Notes) with the gathered context. Leave no template placeholder unreplaced. Write the draft to `.opencode/tmp/pr-body.md`.
5. **Propose title:** Conventional Commits style (e.g. `feat:`, `docs:`, `fix:`), subject ≤ 72 chars, matching the branch type.
6. **Show and confirm:** present the title and the full body, then show the exact command:
   `gh pr create -R jon012906/RainDodger --head <branch> --base main --title "<title>" --body-file .opencode/tmp/pr-body.md`
   Wait for explicit user confirmation before running it. If the user wants edits to the title or body, revise and re-confirm.
7. **Report:** on success, return the PR URL and a one-line summary. Never merge, comment on, or modify the PR after creation.