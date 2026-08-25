---
description: Rebase the current branch onto the latest of another branch.
---

The user has invoked `@rebase`. Rebase the current branch from the updated branch:

1. Determine the target branch: use `$ARGUMENTS` if provided (e.g. `@rebase main`), otherwise default to the remote's default branch (`origin/main` or `git symbolic-ref refs/remotes/origin/HEAD`).
2. Run `git status --short` and abort if there are uncommitted changes — tell the user to commit or stash first (never commit automatically unless the user asked).
3. Run `git fetch origin` to get the latest commits from the remote.
4. Run `git rebase <target-branch>` (use `--autostash` only if the user explicitly allows it).
5. If conflicts occur, resolve them file by file, then `git rebase --continue` until the rebase completes.
6. Never force-push without explicit user confirmation; if the branch is already published and rebasing rewrites history, ask the user before pushing.
7. Report the result: old base, new base, and commit count rebased.
