---
name: prd-to-docs
description: >
  Generate Rain Dodger design docs, flow docs, and data-flow diagrams from a
  finished feature spec. Use when a completed docs/specs/<feature>.md exists
  and the user wants its design doc, flow doc, and data-flow diagram
  generated — "generate design/flow docs from this spec", "make the
  data-flow diagram" — or as the Executor when the plan calls for producing
  docs/designs/<feature>.md and docs/flows/<feature>.md (with the data-flow
  diagram embedded in docs/specs/<feature>.md) from the spec. Do not use for
  screenshot-to-PRD conversion (that's screenshot-to-prd), reviewing design
  docs (that's design-review), the GitHub PR gate (that's pr-review),
  or Swift app code (that's swift-review).
---

I am the spec-to-docs generator for this repo. I turn a finished feature
spec into the two docs that follow it — `docs/designs/<feature>.md` and
`docs/flows/<feature>.md` — plus the data-flow diagram embedded in the spec
itself — matching the project templates and the rules the docs must pass.

## When to use

- A finished `docs/specs/<feature>.md` exists and the user wants its design
  doc, flow doc, and data-flow diagram generated.
- User asks "generate design/flow docs from this spec" or "make the
  data-flow diagram".
- As the Executor, when the plan says to produce
  `docs/designs/<feature>.md` and `docs/flows/<feature>.md` from the spec.

Not for:

- Screenshot → PRD conversion — that's `screenshot-to-prd`.
- Reviewing design docs — that's `design-review`.
- The GitHub PR gate — that's `pr-review`.
- Swift app code — that's `swift-review`.

## Procedure

**Input contract**

- **Input:** a finished `docs/specs/<feature>.md`. "Finished" = the user
  confirms it — no `TBD` left in the spec. If the spec still has `TBD`s,
  stop and ask the user.
- **Outputs:** `docs/designs/<feature>.md`, `docs/flows/<feature>.md`
  (create the directories if missing), and the data-flow diagram embedded
  in `docs/specs/<feature>.md` §3 Data Relations (added only if absent).
- **Ground truth to read before writing:**
  - `docs/template/design.md` — the design-doc skeleton (5 sections).
  - `docs/template/flow.md` — the flow-doc skeleton (4 sections).
  - `.opencode/rules/004-accessibility.md` — the a11y checklist (its §4) the
    design doc must map.
  - `docs/specs/spec-guide.md` — §4 data flow + §5 scoring for the diagram.

1. **Design doc** — write `docs/designs/<feature>.md` with all five template
   sections, mirroring design-review's §2 conformance so the doc passes
   review. Nothing left `TBD` on submit:
   - §1 Design source: sources / asset locations / references filled in from
     the spec.
   - §2 Screens: one section per screen — layout, components, and states
     (loading / empty / error / loaded); dark-mode notes per screen;
     weather/rain colors (`rainClear` / `rainLight` / `rainHeavy`,
     `routePrimary` / `routeAlternative`) and functional colors (`success` /
     `warning` / `danger` / `accent`) defined with **both light and dark
     values**; rain percentages in **monospaced digits**.
   - §3 UI/UX principles: glanceable, glove-friendly hit targets (≥ 44 pt),
     high contrast.
   - §4 Accessibility: maps the `.opencode/rules/004-accessibility.md`
     checklist — VoiceOver, Dynamic Type, contrast 4.5:1 / 3:1 in light AND
     dark, ≥ 44 pt targets, Reduce Motion / Reduce Transparency, portrait +
     landscape (mounted).
   - §5 Motion & interaction: transitions, rain overlay animation, haptics,
     sheet presentation.

2. **Data-flow diagram** — embed one **mermaid** diagram directly into
   `docs/specs/<feature>.md` §3 Data Relations (NO separate `.mmd` source
   file — GitHub renders the fence inline). Add it only if the spec does not
   already carry it. Drawn from the spec's §3 Data Relations + spec-guide §4
   Data Flow: Destination → MKDirections → 2–3 route alternatives → sample
   waypoints every ~1 km → WeatherKit (current / minute / hourly) + Core ML
   → per-segment rain chance + ETA → route cards Driest / Fastest + rain
   overlay + departure time.

3. **Flow doc** — write `docs/flows/<feature>.md` with all four template
   sections:
   - §1 User journey: start → end steps derived from the spec's Goal.
   - §2 Flow diagram: reference the data-flow diagram embedded in
     `docs/specs/<feature>.md` §3 — do NOT duplicate it here.
   - §3 Events & state changes: doc-level states (idle / loading / loaded /
     failed), described as app behavior, not code.
   - §4 Edge cases: from the spec's constraints + spec-guide — offline
     (route without rain overlay, "live rain unavailable"), permission
     denied, empty states, rapid navigation.

4. **Traceability check** — every flow event and state change must trace
   back to a spec requirement; every design element to the spec's feature
   description. Anything absent from the spec is flagged, never invented.

## Guardrails

- Never invent design or flow details absent from the spec — flag them as
  `TBD` or ask the user.
- Never write app code — this skill generates docs only.
- Read-only everywhere except the three outputs
  (`docs/designs/<feature>.md`, `docs/flows/<feature>.md`, and the data-flow
  diagram embedded in `docs/specs/<feature>.md`).
- Use the correct output path `docs/designs/<feature>.md`.
- Colors must stay consistent with spec-guide's tokens — no new palette.
- Flow events must trace back to spec requirements.
- Scope: doc generation rules only — no app implementation content (no
  MVVM / Swift / framework internals).

## Output format

Hand back to the user:

```
Generated:
- docs/designs/<feature>.md — <sections filled>
- docs/flows/<feature>.md — <sections filled>
- docs/specs/<feature>.md — embedded data-flow diagram (added if absent)

Open questions / TBDs:
- <anything flagged during generation, or "none">
```