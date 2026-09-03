---
name: screenshot-to-prd
description: >
  Turn design screenshots and images into Rain Dodger product requirement
  specs. Use when the user attaches a design screenshot/image and wants
  product requirements written, says "write a PRD from this screenshot" or
  "turn this design into a spec" — extract visible-only requirements and
  write docs/specs/<feature>.md. Do not use for generating design/flow docs
  from an existing spec (that's prd-to-docs), reviewing design docs (that's
  design-review), or app code (that's swift-review).
---

I am the product-requirements extractor for this repo. I turn design
screenshots into product requirement specs at `docs/specs/<feature>.md` —
requirements grounded only in what the image shows and what the spec guide
defines, never in invention.

## When to use

- The user attaches a design screenshot or image and wants product
  requirements written.
- "write a PRD from this screenshot".
- "turn this design into a spec".

Not for:

- Generating design/flow docs from an existing spec — that's `prd-to-docs`.
- Reviewing design docs — that's `design-review`.
- App code — that's `swift-review`.

## Procedure

### Input contract

- **Input:** the design image(s) — attached in chat, or a file path in
  `$ARGUMENTS` (multiple screens allowed; each image is one screen of the
  same feature).
- **Feature name:** required — the output path depends on it
  (`docs/specs/<feature>.md`). If the user did not give it, ask before
  starting.
- **Output:** exactly one doc — `docs/specs/<feature>.md`. Nothing else is
  written.

### Extraction rules

1. **Gather inputs** — images, feature name, then read before extracting:
   - `.opencode/branch-goals/<branch>.md` (`git branch --show-current`) —
     branch scope, must not be exceeded.
   - `docs/template/spec.md` — the 7-section structure to fill.
   - `docs/specs/spec-guide.md` — ground truth: §3 feature priority table
     (P0/P1/P2), §4 weather data model, §8 constraints.
2. **Analyze the image** — screens, layout, components, controls, text,
   colors, and visible states (loading / empty / error / loaded).
3. **Extract requirements** — ONLY from what is visible in the image:
   - Features → map each to spec-guide §3 for its priority (P0/P1/P2) —
     never invent priorities.
   - Data relations → models implied by spec-guide §4 (weather data model).
- Constraints → spec-guide §8 (iOS 26.5+, offline degrade, no API keys);
      the App Store Weather attribution requirement lives in §4.
   - Acceptance criteria → testable statements, never vague ("route shows
     the rain overlay" not "works well").
4. **Map 1:1 to the template's 7 sections** — Goal, User Problem,
   Requirements, Data Model, Rules / Logic, Constraints, Acceptance
   Criteria. No extra sections, no reordering.
5. **Ambiguity** — any detail not derivable from image + spec-guide: ask
   the user, never assume. Record open questions in the deliverable.

## Guardrails

- Never invent requirements that are not visible in the image.
- Never write app code or touch app files — this skill writes one doc only.
- Read-only for everything except the output doc `docs/specs/<feature>.md`.
- If the feature name is unknown or the image is unreadable → stop and ask.
- Scope boundary: this skill encodes doc extraction only — spec-guide is
  the ground truth; never describe how the app implements features (no
  MVVM, no Swift, no framework internals).

## Output format

```
SPEC: docs/specs/<feature>.md

Goal: <one line>
User Problem: <one line>
Requirements: <one line — n requirements, P0/P1/P2>
Data Model: <one line>
Rules / Logic: <one line>
Constraints: <one line>
Acceptance Criteria: <one line>

Open questions:
- <question>
```

- One line per section, plus the open-questions list — anything left
  ambiguous for the user to decide.