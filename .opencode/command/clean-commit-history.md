---
description: Scrub leaked credentials from git history by removing a file from all commits.
---

The user has invoked `@clean-commit-history`. Remove credential/identity files from git history (and report the need to force-push).

1. Parse `$ARGUMENTS`: one or more file paths to scrub (e.g. `@clean-commit-history secrets.json credentials/`). If none given, ask the user which file(s) leaked.
2. Inspect the current state:
   - Run `git log --oneline --all -- <path>` to confirm the file is actually in history and identify the leaking commits.
   - Run `git status --short` — abort if there are uncommitted changes to the file being scrubbed; tell the user to commit or stash first.
   - Verify the file genuinely contains credentials (API keys, secrets, tokens, signing/entitlement files, datasets, `.mlmodel` sources, identity files) before rewriting. If it's not a leak, confirm with the user.
3. Warn the user that history rewrite is destructive and irreversible (all commit hashes change, collaborators must re-clone), then get explicit confirmation before proceeding.
4. Rewrite history. Prefer `git filter-repo` (`git filter-repo --path <path> --path <path2> --invert-paths --force`); if it's not installed, fall back to `git filter-branch` (`git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch <path>' --prune-empty -- --all`) and note that filter-repo is the safer option.
5. After the rewrite: add the scrubbed path(s) to `.gitignore` if missing, then run `git reflog expire --expire=now --all && git gc --prune=now --aggressive` to purge the blobs locally.
6. Do NOT push automatically. Report the new history (`git log --oneline -10`) and tell the user:
   - Force push is required: `git push --force-with-lease origin main` (or current branch).
   - The leaked credential must be rotated/revoked — removing it from history does not un-leak it (GitHub commit search, forks, and clones may still hold it).
7. Report which commits contained the file, the rewrite result, and the remaining push/rotation steps.