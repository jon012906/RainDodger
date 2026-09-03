---
description: Switch git branch via an interactive dropdown. Usage: /switch
---

The user wants to switch git branches. Do NOT guess the branch — always present a dropdown.

1. **List branches:** run `git branch -a`. Build the list of branches:
   - Local branches first (from `git branch`), then remote-only branches (from `git branch -r` that have no local counterpart).
   - Strip the `remotes/origin/` prefix when displaying remote branches; mark remote-only ones, e.g. `feat/foo (remote)`.
   - Skip `HEAD -> origin/main`.
2. **Open the dropdown:** call the `question` tool with:
   - header: `Switch branch`
   - question: `Pick the branch to switch to`
   - options: one per branch. Put the current branch first and label it with `(Recommended)` — picking it is a harmless no-op. Keep the user's branch names verbatim as option labels.
3. **Check git state:** after the user picks, run `git status --short`. If the worktree has uncommitted changes, tell the user and ask whether to proceed anyway or commit/stash first (never stash, discard, or commit automatically).
4. **Switch:** run `git switch <branch>`. For a remote-only branch, run `git switch --create <branch> --track origin/<branch>`.
5. **Confirm:** report the new branch name and, if the switch was refused (dirty worktree), what the user decided.
6. Never commit, push, or delete anything as part of this command.