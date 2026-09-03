---
name: spec-decomposer
description: >
  Decompose a big Rain Dodger feature into smaller user-journey-milestone
  slices so each slice gets its own spec, design, and flow doc. Use when the
  Planner is defining spec, design and flow docs for a feature too big for
  one spec — "decompose this spec", "split the feature into smaller specs",
  "break down the feature before writing docs", "this feature needs slices",
  "resume the decomposition plan", "continue from plan.md", "keep going with
  the slices" —
  or when a single docs/specs/<feature>.md would exceed ~10 requirements or
  span multiple user journeys. Do not use for small single-journey features
  (write one spec directly), generating design/flow docs from a finished spec
  (that's prd-to-docs), screenshot-to-PRD (that's screenshot-to-prd),
  reviewing design docs (that's design-review), the GitHub PR gate (that's
  pr-review), or Swift app code (that's swift-review).
---

I am the spec decomposer for this repo. I split oversized features into
smaller, independently implementable slices — each slice is one
user-journey milestone with its own spec doc (its design and flow docs come
later, per slice, via `prd-to-docs`) — so the Planner can phase doc
production and implementation.

## When to use

- A feature intent would produce one spec that is too big to review in one
  pass (roughly > 10 requirements or spanning multiple user journeys).
- User asks "decompose this spec", "split the feature into smaller specs",
  "break down the feature before writing docs", "this feature needs slices".
- As the Planner, when the plan covers a big feature's spec + design + flow
  docs and the feature must be sliced first.
- A new session resumes a sliced feature — "resume the decomposition plan",
  "continue the slices" — read plan.md §7 Progress and continue without
  re-verification.

Not for:

- Small single-journey features — write one spec directly, no decomposition.
- Generating design/flow docs from a finished spec — that's `prd-to-docs`.
- Screenshot → PRD — that's `screenshot-to-prd`.
- Reviewing design docs — that's `design-review`; the PR gate — `pr-review`.
- Swift app code — that's `swift-review`.

## Input contract

- **Input:** a feature intent — the user's request, a draft
  `docs/specs/<feature>.md` that is too big, or a feature scoped in
  `docs/specs/spec-guide.md`.
- **Outputs:** `docs/specs/<feature>/plan.md` (the decomposition plan) plus
  one sliced spec `docs/specs/<feature>/<slice>.md` per journey milestone,
  all inside the feature folder `docs/specs/<feature>/` (create it if
  missing). Design and flow docs are NOT produced here.
- **Ground truth to read before writing:**
  - `docs/specs/spec-guide.md` — the feature list and product scope.
  - `docs/template/spec.md` — the spec skeleton each slice must fill.
  - `docs/template/design.md` and `docs/template/flow.md` — to scope what
    each slice will later cover (referenced in the plan, not written here).
  - `.opencode/branch-goals/<branch>.md` if present — the branch mission
    bounds what the slices may contain.

## Procedure

1. **Extract journey milestones.** Read the feature intent and split it into
   the rider-facing milestones it spans (e.g. plan a trip → choose a route →
   start the ride). Each milestone becomes one slice. If the feature is one
   milestone, stop — this skill does not apply.

2. **Slice.** One journey milestone per slice. Each slice must be:
   - Independently implementable and reviewable (its own spec with its own
     P0/P1/P2 and acceptance criteria).
   - Small enough to review in one pass (≤ ~10 requirements per slice).
   - Self-contained in scope: no requirement split across slices.
   - Ordered by dependency so slice N+1 builds on slice N (e.g. route
     selection before rain overlay on the moving map).

3. **Map requirements.** Every requirement from the source intent maps to
   exactly one slice. Cross-cutting concerns (offline fallback, accessibility)
   are stated once in each affected slice's Constraints, not invented as new
   slices. Orphans and duplicates are flagged, never silently dropped.

4. **Allocate sessions.** Estimate each slice's full doc set (spec + design +
   flow) at ~chars/4 tokens and group slices into batches of 1–2 per session.
   If a batch's cumulative estimate exceeds the session cap (~500k chars /
   ~125k tokens — conservative, model-dependent, includes tool-output and
   review-hop overhead), mark that batch `SESSION OVERLOAD`, split it, and
   never start it in this session.

5. **Write the decomposition plan** `docs/specs/<feature>/plan.md`:

   ```
   # Decomposition Plan — <Feature>

   ## 1. Why This Feature Needs Slices
   <what makes one spec unworkable: size, journey span, review risk>

   ## 2. Slices
   All slice docs live under the feature folder: `docs/specs/<feature>/`.
   | Slice | Journey milestone | Spec file | Design file (later) | Flow file (later) | Depends on |
   |---|---|---|---|---|---|
   | S1 | <milestone> | docs/specs/<feature>/s1-<name>.md | docs/designs/<feature>/s1-<name>.md | docs/flows/<feature>/s1-<name>.md | — |
   | S2 | <milestone> | docs/specs/<feature>/s2-<name>.md | docs/designs/<feature>/s2-<name>.md | docs/flows/<feature>/s2-<name>.md | S1 |

   ## 3. Requirement Mapping
   | Source requirement | Slice |
   |---|---|
   | <each requirement from the intent> | S1 |

   ## 4. Suggested Order
   1. S1 — <why first>
   2. S2 — <depends on S1, why>

   ## 5. Deferred Work
   Design + flow docs per slice (`docs/designs/<feature>/<slice>.md`,
   `docs/flows/<feature>/<slice>.md`), generated after each sliced spec is
   finished (prd-to-docs).

   ## 6. Session Allocation
   Estimate: est. tokens ≈ chars/4 per slice doc set. Session cap:
   ~500k chars (~125k tokens) — conservative, model-dependent.
   | Session | Slices | Est. chars | Est. tokens | Alert |
   |---|---|---|---|---|
   | Batch 1 | S1 | ~60k | ~15k | — |
   | Batch 2 | S2 | ~80k | ~20k | — |
   `SESSION OVERLOAD`: cumulative batch estimate over the cap — split the
   batch, never start it in this session.

   ## 7. Progress — Resume Contract (updated at every stop point)
   - Done: —
   - In flight: —
   - Next: <first pending slice's next doc, per §4 order>
   - Resume: `@implement <feature> — resume from plan` (no re-verification)
   ```

6. **Write one spec per slice in the current session's batch** (per §6
   Session Allocation) at the planned `docs/specs/<feature>/<slice>.md`
   path, from `docs/template/spec.md` — with per-slice Goal, Requirements
   (IDs S1-R1…), Data Model, Rules/Logic, Constraints, and Acceptance
   Criteria. Nothing left `TBD` on submit. Slices outside the current batch
   stay pending in §7 Progress.

7. **Traceability check.** Every requirement in the source intent appears in
   exactly one slice's spec; every slice spec traces back to the intent.
   Anything absent from the source is flagged, never invented.

8. **Resume contract.** At every stop point — batch finished, `SESSION
   OVERLOAD` alert, or interrupted work — update plan.md §7 Progress
   (Done / In flight / Next) and then stop. Stopping needs NO user
   verification: the next session auto-resumes by reading §7 and continuing
   with the Next item. Never stop without updating §7.

## Guardrails

- Never write app code — this skill produces docs only.
- Never write design or flow docs — that is `prd-to-docs` after each sliced
  spec is finished.
- Never decompose a single-milestone feature — one spec, no plan doc.
- Never invent requirements absent from the source — flag them or ask.
- Slice IDs and file names must stay consistent between the plan and the
  specs (naming: `s<n>-<name>.md` inside the feature folder).
- Never plan a session batch over the cap (~500k chars / ~125k tokens) —
  apply the `SESSION OVERLOAD` split.
- Update plan.md §7 Progress before every stop point — never stop without
  it; stopping needs no user verification, the next session auto-resumes
  from §7.
- Read-only everywhere except the plan and the sliced specs.
- Scope: decomposition rules only — no app implementation content (no MVVM /
  Swift / framework internals).

## Output format

Hand back to the user:

```
Decomposed:
- docs/specs/<feature>/plan.md — <n> slices (<S1 scope>, <S2 scope>, ...)
- docs/specs/<feature>/s1-<name>.md — <slice scope>
- docs/specs/<feature>/s2-<name>.md — <slice scope>

Next (per slice, via prd-to-docs): design + flow docs
Resume (any time, no verification): `@implement <feature> — resume from plan`
Open questions / TBDs:
- <anything flagged during decomposition, or "none">
```