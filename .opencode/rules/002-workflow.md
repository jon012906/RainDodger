# Working Agreement & Agent Workflow

**Load when:** defining a task, planning a phase, implementing, or reviewing — anything that runs through the pipeline.

## Working Agreement

| Responsibility     | User                            | AI                     |
| ------------------ | ------------------------------- | ---------------------- |
| Define the problem | **Lead**                        | Assist                 |
| Product direction  | **Lead**                        | Challenge              |
| User flow          | **Lead**                        | Review                 |
| Architecture       | **Understand & decide**         | Propose/review         |
| Technical research | Participate                     | **Lead/assist**        |
| Coding             | Review/understand               | **Execute**            |
| Boilerplate        | —                               | **Execute**            |
| Testing            | **Verify**                      | Generate/assist        |
| Debugging          | **Reason first**                | Assist                 |
| Final decision     | **User**                        | —                      |

Workflow loop: Think → Specify → Ask AI → Execute → Inspect → Test → Explain → Debug → Reflect

- User keeps ownership of technical reasoning: direction, design, and verification stay with the user
- AI automates implementation-heavy work (git, code, boilerplate) and explains what/why in reviewable increments
- When a spec is ambiguous, AI asks instead of assuming; AI challenges product decisions with tradeoffs, user decides
- User reviews and verifies AI output before it ships

## Agent Workflow (Planner → Executor → Reviewer)

Work is built through three specialized agents, defined in `.opencode/agent/`. Each has ONE job, runs as its own session, and is verified by the user at every hop.

| Agent | Job | Interaction |
|---|---|---|
| Planner | Turn intent into a concrete phase plan + acceptance criteria, aligned with `specs.md`, `design.md`, `implementation.md` | Reviews: nothing (plans), and replans fixes from Reviewer issues |
| Executor | Implement exactly the planned phase (or fix plan), verify the build, hand off | Receives: plan. Reviews: own build errors only |
| Reviewer | Verify Executor output against plan + criteria in an isolated session | Verdict: PASS/FAIL + issue lines. Never edits code |

```
User intent ──► Planner ──plan + criteria──► User verify
                                                 │
                                                 ▼
                              Reviewer ──diff/checks──► Executor ──code + build──► User verify
                                  ▲                       ▲
                                  └── issues (FAIL) ──────┘
                                         │
                                         ▼
                                  Planner replans fix ────► Executor ... (loop until PASS)
```

Rules:
- **Roles never merge:** Executor never reviews its own work; Reviewer never fixes issues; Planner never writes code.
- **Separate sessions on purpose:** Executor and Reviewer must never be the same agent — independence (no self-approval/hallucination) is the point.
- **User gates every hop:** the user verifies the plan, the execution result, and the verdict before the pipeline continues; final decision is the user's.
- If the Reviewer fails a phase, the fix loop is: Reviewer issues → Planner fix plan → Executor implements → Reviewer re-verifies → repeat until PASS.
- The user contributes more strongly on the plan activity: Planner drafts and challenges, user decides.
- Never commit or push automatically — user does it explicitly with `@push`.

## Review Handoff — User + Reviewer Confirm Before Continuing

Every time a phase (or fix) finishes executing, the AI must stop and ask the user for confirmation before anything continues (next phase, push). The result is checked by **two reviewers: the user and the Reviewer agent**, and both must pass.

1. **User check (checklist):** the AI stops with a short report + an openable review checklist:

```
Phase <N> done

List to review (click to open):
- [ ] <what to check> | <path/file>[:line]
- [ ] <what to check> | <path/file>[:line]

Review and confirm, or say what to change.
```

2. **Reviewer check (verdict):** after the user's confirmation, the Reviewer agent verifies the same phase in a separate session and returns VERDICT: PASS/FAIL + issue lines.

3. Only when **both** pass does the phase move on. If either fails, the user decides: fix now (Planner fix plan → Executor → re-check) or adjust the plan first.

- Every created/modified file is listed with the specific thing to verify (function, feature, view, logic), so the user knows why it matters — not just "file changed".
- Paths are formatted as clickable references (`path/file.swift:line`), so the user can open them quickly.
- The checkboxes cover the acceptance criteria of that phase — the user's tick marks are the approval gate.
- The AI does NOT auto-continue to `@review` / next phase / `@push` until the user confirms (or explicitly says to proceed).
- If a fix loop is running (Reviewer issues → Executor), the same checklist applies to the fixed phase before re-verification continues.
