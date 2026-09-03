---
name: github-cli
description: >
  Use the GitHub CLI (gh) for all GitHub operations. Use when asked to create, view, or
  inspect a pull request or issue, check CI or workflow status, merge, close, comment,
  review, search PRs/issues, create or view a release, or run any other gh command.
  Also use when reading GitHub state (open PRs, pending reviews, failing checks) before
  pushing, publishing, or reporting on repo status.
---

I am the GitHub CLI (gh) operator for this repo. I run read-only `gh` commands freely;
write commands (create/merge/close/comment/review/release, issue mutations) only after
showing the exact command and getting explicit user confirmation.

## When to use

- User asks for a PR/issue action: create, view, list, comment, review, approve, close, merge.
- User asks about CI: check runs, failing checks, workflow status, re-run.
- User asks to publish or update a release, or to view releases.
- User asks for repo status: open PRs, open issues, recent commits, branch state.
- Before reporting "ready to ship": confirm the branch is pushed, PR exists, checks pass.

## Procedure

### Auth & scoping

- On any gh error regarding auth/permission, run `gh auth status` first and report the account.
- Repo is `jon012906/RainDodger`. In-repo operations work without `-R`; use
  `-R OWNER/REPO` for any cross-repo operation.
- Do not assume a remote name; check `gh repo view --json nameWithOwner` if uncertain.

### Read commands (safe, run freely)

- `gh pr view --json number,title,url,state,headRefName,mergeable,reviewDecision,statusCheckRollup`
- `gh pr list --state open --json number,title,url,author --jq '.[] | "\(.number) \(.title)"'`
- `gh pr diff`, `gh pr checks`
- `gh issue list --state open --json number,title,url --jq '.[] | "\(.number) \(.title)"'`,
  `gh issue view <n> --json title,url,labels,assignees,milestone,state`
- `gh repo view --json nameWithOwner,defaultBranchRef,url`
- `gh search prs "repo:jon012906/RainDodger is:open"`, `gh search issues "<term>" --limit 10` —
  if search errors on a new repo ("resources do not exist or you do not have
  permission"), fall back to `gh pr list --state open` / `gh issue list` (search index
  lags on new repos)
- `gh api` GET requests (no writes)

Keep outputs small: prefer `--json` with `--jq` projections. If raw output would be
large, pipe to `/var/folders/jm/h_3jzgjj66s3kdg3_qzl_smw0000gn/T/opencode` temp files and
summarize instead of pasting.

### Write commands (REQUIRE explicit user confirmation)

Show the full exact command (with resolved args) and wait for the user to confirm before
running it. Preserve the user's choices verbatim.

- `gh pr create`: implies `git push`. Prefer the user's own `@push` first, then create with
  `gh pr create -R jon012906/RainDodger --head <branch>`. Never push the branch implicitly.
- `gh pr merge`: squash/merge/rebase is the user's choice. It changes the remote
  (push-equivalent) — never merge to `main` without explicit confirmation.
- `gh pr close`, `gh pr comment`, `gh pr review --approve|--comment|--request-changes`
- `gh release create`

### Issues, assignees & labels

- `gh issue create` — gather title, body, assignee, labels, milestone from the user first.
  Use `--title "<t>" --body-file <file> --assignee <login> --label <label> --milestone <m>`
  (repeat `--assignee`/`--label` for multiples). Prefer an existing issue template from
  `.github/ISSUE_TEMPLATE/` when one matches; write long bodies to a temp file.
- `gh issue edit <n>` — `--title`, `--body-file`, `--milestone`, `--add-label/--remove-label`,
  `--add-assignee/--remove-assignee`.
- Assigning via edit (there is no `gh issue assign` / `gh pr assign` subcommand):
  `gh issue edit <n> --add-assignee <login>` / `--remove-assignee <login>`,
  `gh pr edit <n> --add-assignee <login>` / `--remove-assignee <login>`; assign at
  creation with `gh issue create --assignee` / `gh pr create --assignee`.
  Read assignees back with `gh issue/pr view --json assignees`.

### Rebase

- Sync an open PR with `main` (local): `git fetch origin`, `git rebase origin/main` on the
  branch, resolve conflicts, then ask the user to run `@push` (`--force-with-lease`) —
  never force-push implicitly.
- Native GitHub rebase at merge: `gh pr merge --rebase` — replays the original commits
  on `main` (no squash). Merge/squash/rebase mode is always the user's choice.
- After any rebase or merge: re-check `gh pr checks` before reporting ready.

## Guardrails

- Never commit or push automatically. AGENTS.md: the user runs `@push`. Flag any gh
  command that pushes (create/merge) and confirm first.
- Never expose tokens or keys. Never run `gh auth token`, never print auth headers,
  never paste credentials into a command or output.
- Identity rules (no DEVELOPMENT_TEAM, personal bundle IDs, `xcuserdata/` in configs)
  are enforced by @push checks, not bypassed by gh. Never use gh to work around them.
- Directly targeted at this repo by default; add `-R` explicitly for any other repo.

## Output format

- Return PR/issue URLs (clickable), plus a one-line summary per item.
- Use machine-readable `--json` output as review input; no raw pastes.
