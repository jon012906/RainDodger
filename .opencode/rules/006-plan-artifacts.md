# Plan Artifacts — the Plan ID Store (compaction-safe workflow)

**Load when:** planning, implementing, reviewing — any pipeline hop; and when a session resumes after context compaction or a fresh session continues a branch's work.

Every plan is a durable artifact at `.opencode/tmp/plans/<plan-id>.md` (gitignored via root `.gitignore` — `.opencode/tmp/`, workspace metadata only, like branch goals). The **plan ID** is the cross-session handoff token: the Planner, Executor, and Reviewer run as separate sessions, and the main session may be compacted — nobody relies on chat memory for the plan or its review state.

## Plan IDs

- Format: `<branch>-p<NN>` — `<branch>` is the branch name without its type prefix (`feat/weather-enhance` → `weather-enhance`), `NN` is the per-branch plan sequence (`01`, `02`, ...).
- Fix plans (replans from Reviewer issues): `<plan-id>-f<NN>` — e.g. `weather-enhance-p01-f01`, a child of `weather-enhance-p01`.
- Review reports: `.opencode/tmp/reports/<skill>-<plan-id>-r<NN>.md` — `rNN` is the review round number per plan (`r01`, `r02`, ...).
- The Planner proposes the ID as the **first line of its output** (`PLAN ID: <id>`). The main session validates uniqueness against `.opencode/tmp/plans/` (bump `NN` on collision), persists the file, and passes the ID to the next agent.

## Who writes

| Artifact | Writer |
|---|---|
| Plan file | Main session only (Planner is read-only — `edit: deny`) |
| Plan status + log rows | Main session, after each agent hop |
| Review report file | Reviewer returns the verdict; main session persists it |

The Executor and Reviewer never edit the plan file — the main session owns it, so the file always reflects the state the orchestrator saw.

## Plan file template

```markdown
# Plan <plan-id>

- **Branch:** <branch-name>
- **Branch goal:** `.opencode/branch-goals/<branch>.md` — read it, it is the mission
- **Created:** <YYYY-MM-DD HH:MM>
- **Status:** planned | approved | executing | executed | reviewing | passed | failed | fixing
- **Parent:** <plan-id> — the plan this fix plan fixes (or —)
- **Supersedes:** <plan-id> — the plan this replan replaces (or —)

## Goal

<one sentence>

## Acceptance criteria

- [ ] <checkable item>
- [ ] <checkable item>

## Ordered steps

1. <exact file path> — <types/functions/protocols to create/modify>
2. ...

## Verification

- <command> — <what it proves>

## Risks / tradeoffs

- <risk> — <fallback>

## Review log

| Round | Report | Verdict | Issues | Fix plan |
|-------|--------|---------|--------|----------|
| r01 | .opencode/tmp/reports/<skill>-<plan-id>-r01.md | FAIL | 2 must fix / 1 suggestion | <plan-id>-f01 |

## Execution log

| Step | Result | Evidence |
|------|--------|----------|
| 1 | done | <build result / git diff --stat> |
```

## Status lifecycle

- `planned` — Planner output returned, file written, awaiting user approval
- `approved` — user approved the plan
- `executing` — Executor is implementing
- `executed` — Executor handoff done, awaiting review
- `reviewing` — Reviewer is running
- `passed` — `VERDICT: PASS` and user approved
- `failed` — `VERDICT: FAIL`, issues logged in the Review log
- `fixing` — fix plan created (`<plan-id>-f<NN>`), fix loop in progress

## Compaction rules

- Every pipeline hop starts by **reading the plan file by ID** — never from memory: the Executor reads `.opencode/tmp/plans/<plan-id>.md` before coding; the Reviewer reads it before judging.
- After context compaction or in a fresh session, the main session resumes by reading `.opencode/branch-goals/<branch>.md` (the mission) + `.opencode/tmp/plans/<latest-plan-id>.md` (the state).
- The plan file is the single source of truth for the phase: goal, criteria, steps, and review history. Anything not in the file is not known — re-read, don't guess.
- Status transitions and Review-log rows are appended after each hop — the file always reflects the current state.

## Review linkage (replan / issues / fixing)

- The Reviewer returns `VERDICT: PASS | FAIL` + one-line issues. The main session persists the report at `.opencode/tmp/reports/<skill>-<plan-id>-r<NN>.md` and appends a Review-log row to the plan file.
- On `FAIL`: the main session hands the Planner the report path + plan ID. The Planner returns a fix plan with `PLAN ID: <plan-id>-f<NN>`; the main session persists it (`Parent: <plan-id>`), the Executor implements it, the Reviewer re-verifies as `r<NN+1>` — loop until `PASS` + user approval.
- Every report, Review-log row, and fix plan carries the plan ID — the full replan/issue/fix history is reconstructible from `.opencode/tmp/plans/` + `.opencode/tmp/reports/` alone.