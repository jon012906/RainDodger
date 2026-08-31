---
description: Create a new git branch (docs/, feat/, fix/) and store its goal so every agent session follows it. Usage: /branch <branch-name> "<goal>".
---

The user invoked `@branch`. Usage: `/branch <branch-name> "<goal>"` (e.g. `/branch feat/rain-radius "Add rain radius filtering"`; goal can also be given after the command, or by the user in chat).

1. **Parse the goal:** `$1` = branch name, `$2...` = free-text goal. If no goal was provided, ask the user for it first — never create a branch without knowing its goal.
2. **Validate the branch name:**
   - Must start with one of: `docs/` (agent design / app design planning), `feat/` (implement feature from docs), `fix/` (solve issue or bug). Warn and ask if it doesn't match, rather than silently creating it.
   - No spaces; suggest a kebab-case slug if there are any.
3. **Check git state:** run `git status --short`. If the worktree has uncommitted changes, tell the user and ask whether to proceed anyway or commit/stash first (never stash or discard automatically).
4. **Create the branch:** run `git checkout -b <branch-name>`.
5. **Store the goal:** create the directory `.opencode/branch-goals/` (gitignored, never committed) and write `.opencode/branch-goals/<branch-name>.md` with exactly this structure:

```markdown
# Branch Goal: <branch-name>

- **Type:** <docs | feat | fix>
- **Branch:** <branch-name>
- **Created:** <YYYY-MM-DD>

## Goal

<the user's goal, stated as a mission sentence>

## Scope

- In: (what this branch must deliver — fill with the user during planning)
- Out: (what it must NOT touch)

## Done

- (how we know it's finished — acceptance criteria; refine during planning)
```

6. **Confirm:** report the branch name, the goal, and the goal file path back to the user. State that this goal will be loaded by the agent in this and future sessions on this branch.
7. Never commit or push the goal file — it is workspace metadata, ignored by git.
