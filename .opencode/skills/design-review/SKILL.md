---
name: design-review
description: >
  Review Rain Dodger design docs against the project design rules. Use when
  asked to review a design doc (docs/designs/*.md), check a design change
  against docs/template/design.md or the accessibility rules (004), vet a
  feature design before implementation, or as the Reviewer when the change
  set is design files. Do not use for Swift code review (that's swift-review),
  the GitHub PR gate (that's pr-review), planning, or fixing.
---

I am the design review operator for this repo. I review design docs against
the project design and accessibility rules and report `VERDICT: PASS | FAIL` —
matching `.opencode/agent/reviewer.md`.

## When to use

- Reviewing a design doc or design change before implementation.
- As the Reviewer, when the change set is `docs/designs/*.md`.
- User asks "review this design", "does this design pass the project rules?",
  "is this design ready to implement?".

Not for:

- Swift app code — that's `swift-review` (local app-code review).
- The GitHub PR gate — that's `pr-review` (metadata JSON + `gh pr diff`,
  scope/commits/CI/conversation).
- Planning — that's the Planner (`.opencode/agent/planner.md`).
- Fixing — that's the Executor (`.opencode/agent/executor.md`).

## Input contract

- **Scope target:** design docs under `docs/designs/`; the judging rules are
  `docs/template/design.md` (design baseline) and `.opencode/rules/004-accessibility.md`
  (a11y requirements).
- Feature spec `docs/specs/*.md` if applicable — feature-scoped specs that
  constrain the design.
- `.opencode/branch-goals/<branch>.md` if present — read it before judging
  scope.
- Scope by `$ARGUMENTS` if the user named specific files/paths; otherwise
  `git status --short` + `git diff` (plus `--cached` if staged, and
  `main...HEAD` if committed) filtered to design files.

## Procedure

Read-only: never edit design docs.

1. **Inputs** — gather first:
   - `git status --short` — what is changed/untracked.
   - `git diff` — unstaged changes; add `git diff --cached` if anything is
     staged and `git diff main...HEAD` if the change is committed.
   - `$ARGUMENTS` — if the user named specific files/paths, scope to those.
   - Read `.opencode/branch-goals/<branch>.md` if present before judging scope.

2. **Design conformance** — against `docs/template/design.md`; cite the
   section, don't duplicate it. Nothing left `TBD` in a doc submitted for
   review:
   - §1 Design source: sources/asset locations/references filled in.
   - §2 Screens: per-screen layout, components, states (loading / empty /
     error / loaded), dark mode notes, landscape (mounted) notes. Weather/rain
     colors (`rainClear` / `rainLight` / `rainHeavy`, `routePrimary`,
     `routeAlternative`) and functional colors (`success` / `warning` /
     `danger` / `accent`) must be defined with both **light and dark** values;
     rain percentages use **monospaced digits**.
   - §3 UI/UX principles: glanceable, glove-friendly hit targets (≥ 44 pt),
     high contrast.
   - §4 Accessibility: the design addresses `.opencode/rules/004-accessibility.md`
     requirements (VoiceOver, Dynamic Type, color contrast, ≥ 44 pt targets).
   - §5 Motion & interaction: transitions, rain overlay animation, haptics,
     sheet presentation.

3. **Accessibility** per `.opencode/rules/004-accessibility.md` §3 + §4:
   - Contrast: WCAG 2.1 AA 4.5:1 normal text / 3:1 large text and graphics,
     verified in light AND dark mode.
   - No color-only information: rain segments carry a label or pattern.
   - Dynamic Type: layout survives scaling, no clipped text.
   - VoiceOver: every piece of information readable, decorative map overlays
     hidden.
   - Reduce Motion / Reduce Transparency respected.
   - §4 checklist: hit targets ≥ 44 pt; orientation (portrait + landscape
     mounted).

4. **Scope fidelity** — diff vs the branch goal and the design's stated scope;
   unrelated screens or changes are scope creep. If the plan or scope itself is
   wrong, raise it as an issue and let the user decide.

5. **Template coverage** — vs `docs/template/design.md`: all five sections
   present (design source, screens, UI/UX principles, accessibility, motion);
   covered by step 2, re-verified at a glance here.

## Output format (matches .opencode/agent/reviewer.md)

```
VERDICT: PASS | FAIL

Issues:
- <severity: must fix | suggestion> <file:line> — problem — fix direction
```

- One line per issue (`must fix` or `suggestion`) so the Planner can turn each
  one into a fix plan without re-investigating.
- If everything passes: `VERDICT: PASS` plus one short line per checklist item
  (design conformance, accessibility, scope, template compliance).
- Example issue line:

```
- must fix docs/designs/route-overview.md:42 — rain segment colors have no dark-mode values — add the dark column to the palette table
```

- File:line from the design doc. Judge against the design rules and project
  docs only, never personal taste.

## Report flow (on issues found)

If the verdict is `FAIL` (or has any `must fix`), produce a report artifact
before reporting:

1. **Create the report** — write the full verdict block + checklist context to
   `.opencode/tmp/reports/design-review-<branch>-<timestamp>.md`
   (`.opencode/tmp/` is gitignored — never commit it).
2. **Announce it** in chat, mandatory:
   `REVIEW REPORT: <path> — <n> issues — VERDICT: FAIL`
3. **Hand it to the Planner**: the report is the input for the Planner's fix
   plan (Planner → Executor → Reviewer loop) — the Planner reads the report
   and turns each issue into an ordered fix plan. The Reviewer never fixes.

## Rules

- Read-only: never fix design docs — issues go to the Planner for a fix plan
  (Planner → Executor → Reviewer loop).
- Reports live only under `.opencode/tmp/reports/` — never commit them.
- Never trust self-assessments in Executor handoffs — verify the docs
  directly.
- Judge against the design rules and project docs only, never personal taste.
