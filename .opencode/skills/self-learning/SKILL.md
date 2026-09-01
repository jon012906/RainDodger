---
name: self-learning
description: >
  Create and maintain a new agent skill in this repo when a procedure repeats or a
  hard-won lesson deserves encoding. Use when the same non-trivial multi-step procedure
  is being done for the second time; when a procedure was discovered through errors or
  trial-and-error; when a project-specific convention (Rain Dodger repo, workflow, or
  tooling) is worth encoding as reusable machine-readable instructions; when a recurring
  named task in the Rain Dodger workflow shows up; or when authoring or editing any
  SKILL.md — to check name uniqueness, validate frontmatter, and announce the skill in
  chat. Do not use for one-off or trivial requests, for app feature code (that is
  implementation work, not meta-workflow), or when an existing skill already covers the
  task.
---

I am the skill author for this repo. I create and maintain project skills at
`.opencode/skills/<name>/SKILL.md` — **without waiting for user approval** (branch
decision) — and I announce every new, edited, or retired skill in chat immediately.

## When to use

Create a new skill when ANY signal is present:

- The same non-trivial multi-step procedure is being done for the **2nd repetition**.
- A procedure was **hard-won through errors** — you fixed it by trial-and-error and it
  should not have to be relearned.
- A **project-specific convention** (repo layout, workflow rules, tooling quirks) is
  worth encoding once, machine-readably.
- A **recurring named task** exists in the Rain Dodger workflow (e.g. phases, reviews,
  push gates) and no skill covers it.
- A **task-specific procedure** is worth encoding for this task — fine, as long as its
  scope says so: the skill must only load for tasks in its domain, never for unrelated
  ones (see Domain scoping below).

Domain scoping — always:

- The `description` triggers define WHEN the skill loads. Scope them tightly to the
  skill's domain (e.g. "use when reviewing a GitHub PR", "use when running gh") so it
  never activates on unrelated work.
- If the skill is task-specific, say so in the description ("use for the X workflow") —
  the skill's domain is its trigger set; a skill out of its domain never gets loaded.

Do NOT create one when:

- The request is **one-off or trivial** (single step, obvious, no risk of relearning).
- It is **app feature code** — implementing Rain Dodger features is app work, not
  meta-workflow; skills encode how the agent works, not what the app does.
- **A skill already covers it** — check the session's `available_skills` list FIRST,
  including `github-cli` and `pr-review`; extend or reuse instead of duplicating.

## SKILL.md anatomy

- Location: `.opencode/skills/<name>/SKILL.md` (one folder per skill, `SKILL.md` at its
  root). New skills live in the repo only, never in user-level skill directories.
- Frontmatter `name`: lowercase-hyphen, must match the directory name exactly, and must
  match `^[a-z0-9]+(-[a-z0-9]+)*$`.
- Frontmatter `description`: 1–1024 characters, trigger-rich — start it with what it is,
  then "Use when …" with concrete triggers.
- Body sections in project style (see `github-cli` and `pr-review`): an intro line ("I am
  the …"), then `When to use`, `Procedure`, `Guardrails`, `Output format`. Keep it sharp
  and machine-usable — no fluff, exact commands and formats.

## Do-not-touch

- User-level skills: `caveman-*`, `research`, `find-skills`, `customize-opencode` —
  **never copy, edit, re-host, or duplicate their scope.** They live in
  `~/.agents/skills/`, `~/.config/opencode/skills/`, and `~/.claude/skills/` and are
  out of this repo's control.
- The existing project skills `github-cli` and `pr-review` — modify them only when the
  user explicitly asks; never rewrite their style or scope silently.

## Procedure

1. **Check name uniqueness.** The proposed `<name>` must not exist in:
   - project skills: `.opencode/skills/<name>/`
   - user skills: `~/.agents/skills/<name>/`, `~/.config/opencode/skills/<name>/`,
     `~/.claude/skills/<name>/`
   Also reject names already present in the session's `available_skills`. If it exists
   anywhere, do not create — suggest extending the existing skill instead.
2. **Write** `.opencode/skills/<name>/SKILL.md` — frontmatter + body per anatomy above.
3. **Validate** immediately:
   - `name` equals directory name and matches the regex.
   - `description` length in 1–1024 characters.
   - Every "When to use" trigger from the skill's content is keyword-searchable in the
     `description` (that is what makes it auto-loadable).
   - **Domain-scoped**: the description's triggers are bound to the skill's domain (both
     "use when" AND "do not use for" edges), so the skill loads for its task and never
     for unrelated requests. Task-specific skills are allowed — but a task-specific
     description that may fire outside its task is not.
4. **Announce in chat** immediately (no approval needed; see Output format).

## Announcement format

Every created, edited, or retired skill gets a chat announcement — no waiting for user
approval to create (branch decision), but committing is still gated by the user's
`@push`:

```
NEW SKILL: <name> — <one-line purpose> — <path to SKILL.md> — <trigger words>
```

For edits/retirement, `NEW SKILL:` becomes `UPDATED SKILL:` / `RETIRED SKILL:`.
Announcement wording must include the **discovery caveat**: the skill list is a
per-session snapshot — a newly created skill becomes loadable in the **NEXT** session,
not the current one.

## Maintenance

- Editing or retiring a skill is announced too, with the same format and caveat.
- A skill that no longer serves any branch goal (`git branch --show-current` →
  `.opencode/branch-goals/<branch>.md`) is a candidate for removal; propose it to the
  user, and only remove on confirmation.
- Before every code task, re-check `available_skills`: skills describe the current best
  way to work — stale skills should be updated or retired, not followed blindly.

## Guardrails

- Creation is automatic, but the **announcement is mandatory** — never create silently.
- Never touch, edit, or copy user-level skills (see Do-not-touch).
- Never use a skill to bypass AGENTS.md constraints (no auto-commit/push, no secrets,
  identity rules) — the skill explains the rule, it does not override it.
- Skills encode meta-workflow (how the agent works). If a skill starts describing app
  feature code, it is scope creep — move that content into the app docs instead.
