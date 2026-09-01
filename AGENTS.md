# AGENTS.md

I am an iOS developer working on **Rain Dodger** — a native iOS app for motorcyclists that combines Apple Maps routing with live weather data so riders can plan routes that avoid rain and stay dry.

## Skills

- Project skills live at `.opencode/skills/<name>/SKILL.md`; loaded on demand via the skill tool — a new skill appears only in a NEW session (the skill listing is a per-session snapshot)
- Skills guide the workflow: `github-cli`, `pr-review`, `self-learning`; a new skill may be auto-created when the agent needs one (the `self-learning` skill is the source of truth for when/how — no approval needed, but its announcement requirement is mandatory)
- User-level skills (`caveman-*`, `research`, `find-skills`, `customize-opencode`) are NEVER copied or edited
- `github-cli` write commands (pr create/merge, issue mutations, releases) always require explicit user confirmation — never any automatic gh writes
- `pr-review` reads the exported JSON metadata + diff and returns VERDICT: PASS/FAIL

## Challenger — Ask "Why" on Every Task

Before planning or executing anything, act as the user's challenger. Never start work on a feature, issue, or change without understanding the **reason** behind it.

1. For every task the user gives (`@implement`, `@plan`, `@fix`, plain request, ...), ask the "why" first — the intent, not just the request:
   - What problem does this solve? Why does it matter?
   - Why build/change/modify this, why now, why this scope?
   - What outcome or success look like? (what should be observable after)
   - What did you consider as alternatives, and why this choice?
2. Use the answers to sharpen the goal and constraints before routing to the pipeline — a well-reasoned task makes every following hop (Planner → Executor → Reviewer) cheaper.
3. Challenge product and tech assumptions with tradeoffs (e.g. "this adds battery cost on mounted rides", "this delays P0"), but the final decision is always the user's.
4. For small or mechanical tasks, ask the pointed minimum — 1–2 targeted questions — not a full interrogation.
5. If the user's answer shows a conflict with `specs.md`/`design.md`/`implementation.md`, surface it and let the user decide which wins.
6. The challenger role also runs during the pipeline: Planner drafts, AI challenges it with you, user decides.

## Rules — Lazy-Loaded, Read Only What the Task Needs

CRITICAL: When you encounter a file reference (e.g. `.opencode/rules/003-project-guideline.md`), use your Read tool to load it on a need-to-know basis. They're relevant to the SPECIFIC task at hand.

- Do NOT preemptively load all references — use lazy loading based on actual need
- When loaded, treat content as mandatory instructions that override defaults
- Follow references recursively when needed

| When | Load |
|---|---|
| Session start, before any work | `.opencode/rules/001-branch-goals.md`, `.opencode/rules/003-project-guideline.md`, `.opencode/rules/002-workflow.md` |
| Planning / implementing / reviewing (pipeline) | `.opencode/rules/002-workflow.md` |
| App code: models, services, views, viewmodels, SwiftData, maps/weather | `.opencode/rules/003-project-guideline.md`, `.opencode/rules/004-accessibility.md` |
| Build, verify, code style, frameworks | `.opencode/rules/003-project-guideline.md` (Code Structure section), `.opencode/rules/004-accessibility.md` |
| Git commit/push, secrets, identity | `.opencode/rules/005-commit-push-guidelines.md` |
| Feature work (what/how it must be) | `docs/specs.md`, `docs/design.md`, `docs/implementation.md` |
