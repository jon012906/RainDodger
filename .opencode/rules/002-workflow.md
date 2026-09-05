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

Work is built through three specialized agents, defined in `.opencode/agent/`. Each has ONE job, runs as its own session; the user verifies the plan and the verdict.

| Agent | Job | Interaction |
|---|---|---|
| Planner | Turn intent into a concrete phase plan + acceptance criteria, aligned with `docs/template/spec-guide.md`, `docs/designs/`, `docs/implementation.md` | Reviews: nothing (plans), and replans fixes from Reviewer issues |
| Executor | Implement exactly the planned phase (or fix plan), verify the build, hand off | Receives: plan. Reviews: own build errors only |
| Reviewer | Verify Executor output against plan + criteria in an isolated session; dispatch the review skill matching the change set (swift-review / design-review / pr-review), built-in fallback otherwise | Verdict: PASS/FAIL + issue lines. Never edits code. Runs immediately after the Executor (no user gate in between) |

```
User intent ──► Planner ──plan + criteria──► User verify plan
                                                  │
                                                  ▼
                     Reviewer ──diff/checks──► Executor ──code + build──► Reviewer ──verdict──► User verify
                                ▲                       ▲
                                └── issues (FAIL) ──────┘
                                       │
                                       ▼
                                Planner replans fix ────► Executor ... (loop until PASS)
```

Legend: the Reviewer runs immediately after the Executor — no user gate between them.

Rules:
- **Roles never merge:** Executor never reviews its own work; Reviewer never fixes issues; Planner never writes code.
- **Separate sessions on purpose:** Executor and Reviewer must never be the same agent — independence (no self-approval/hallucination) is the point.
- **User gates plan and verdict:** the user verifies the plan; the Reviewer runs automatically right after the Executor; the user verifies the verdict + checklist before the pipeline continues (next phase / fix loop / `@push`). Final decision stays with the user.
- If the Reviewer fails a phase, the fix loop is: Reviewer issues → Planner fix plan → Executor implements → Reviewer re-verifies → repeat until PASS.
- The user contributes more strongly on the plan activity: Planner drafts and challenges, user decides.
- Never commit or push automatically — user does it explicitly with `@push`.

## Review Handoff — Executor → Reviewer (immediate) → User

Every time a phase (or fix) finishes executing, the AI hands off to the Reviewer immediately, then the user checks the result. The result is checked by **two reviewers: the Reviewer agent and the user**.

1. **Executor stops with build result + checklist:** the Executor's final message is the build result, blockers (if any), what to hand to the Reviewer, and an openable review checklist:

```
Phase <N> done

List to review (click to open):
- [ ] <what to check> | <path/file>[:line]
- [ ] <what to check> | <path/file>[:line]
```

2. **Reviewer check (immediately):** the Reviewer agent verifies the same phase right after the Executor finishes, in a separate session, with no user confirmation in between. Returns VERDICT: PASS/FAIL + one-line issues.

3. **User check (verdict + checklist):** the user verifies the checklist and the verdict. The phase moves on only when the Reviewer PASSes AND the user approves. If either fails or the user objects, the user decides: fix now (Planner fix plan → Executor → re-review) or adjust the plan first.

- Every created/modified file is listed with the specific thing to verify (function, feature, view, logic), so the user knows why it matters — not just "file changed".
- Paths are formatted as clickable references (`path/file.swift:line`), so the user can open them quickly.
- The checkboxes cover the acceptance criteria of that phase — the user's tick marks are the approval gate.
- The Reviewer itself runs without a user gate; the AI does NOT auto-continue to the next phase / fix loop / `@push` until the Reviewer PASSes AND the user confirms (or explicitly says to proceed).
- If a fix loop is running (Reviewer issues → Executor), the same checklist applies to the fixed phase before re-verification continues.
