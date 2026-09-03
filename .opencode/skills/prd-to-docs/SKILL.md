---
name: prd-to-docs
description: >
  Generate Rain Dodger design docs, flow docs, and data-flow diagrams from a
  finished feature spec. Use when a completed docs/specs/<feature>.md exists
  and the user wants its design doc, flow doc, and data-flow diagram
  generated — "generate design/flow docs from this spec", "make the
  data-flow diagram" — or as the Executor when the plan calls for producing
  the design/flow docs for a spec — flat for a single spec
  (docs/designs/<feature>.md + docs/flows/<feature>.md), mirrored in a
  feature folder for a sliced spec (docs/designs/<feature>/<slice>.md +
  docs/flows/<feature>/<slice>.md) — with the data-flow diagram embedded in
  the input spec. Do not use for screenshot-to-PRD conversion
  (that's screenshot-to-prd), reviewing design docs (that's design-review),
  the GitHub PR gate (that's pr-review), or Swift app code (that's
  swift-review).
---

I am the spec-to-docs generator for this repo. I turn a finished feature
spec into the two docs that follow it — `docs/designs/<feature>.md` and
`docs/flows/<feature>.md` — plus the data-flow diagram embedded in the spec
itself — matching the project templates and the rules the docs must pass.

## When to use

- A finished spec exists — `docs/specs/<feature>.md` (single-spec) or a
  slice at `docs/specs/<feature>/<slice>.md` (decomposed by
  `spec-decomposer`) — and the user wants its design doc, flow doc, and
  data-flow diagram generated.
- User asks "generate design/flow docs from this spec" or "make the
  data-flow diagram".
- As the Executor, when the plan says to produce the design/flow docs for a
  spec — flat `docs/designs/<feature>.md` + `docs/flows/<feature>.md`, or
  mirrored `docs/designs/<feature>/<slice>.md` +
  `docs/flows/<feature>/<slice>.md` for a sliced spec.

Not for:

- Screenshot → PRD conversion — that's `screenshot-to-prd`.
- Reviewing design docs — that's `design-review`.
- The GitHub PR gate — that's `pr-review`.
- Swift app code — that's `swift-review`.

## Procedure

**Input contract**

- **Input:** a finished spec — `docs/specs/<feature>.md` (single-spec) or
  `docs/specs/<feature>/<slice>.md` (sliced). "Finished" = the user confirms
  it — no `TBD` left in the spec. If the spec still has `TBD`s, stop and
  ask the user.
- **Outputs:** design and flow docs that MIRROR the input spec's location —
  `docs/specs/<feature>.md` → `docs/designs/<feature>.md` +
  `docs/flows/<feature>.md`; `docs/specs/<feature>/<slice>.md` →
  `docs/designs/<feature>/<slice>.md` + `docs/flows/<feature>/<slice>.md`
  (create the directories if missing) — and the data-flow diagram embedded
  in the input spec's §4 Data Model (added only if absent).
- **Ground truth to read before writing:**
  - `docs/template/design.md` — the design-doc skeleton (6 sections).
  - `docs/template/flow.md` — the flow-doc skeleton (6 sections).
  - `.opencode/rules/004-accessibility.md` — the a11y checklist (its §4) the
    design doc must map.
  - `docs/specs/spec-guide.md` — §4 data flow + §5 scoring for the diagram.

1. **Design doc** — write the design doc at the mirrored output path (e.g.
   `docs/designs/<feature>.md` or `docs/designs/<feature>/<slice>.md`) with
   all six template
   sections, mirroring design-review's §2 conformance so the doc passes
   review. Nothing left `TBD` on submit:
   - §1 Screens: one entry per state — empty / loading / loaded / error /
     permission denied / offline.
   - §2 Layout: what appears where — map, cards, buttons, search field,
     overlays.
   - §3 Components: reusable UI pieces (DestinationSearchField, RouteCard,
     RainRiskBadge, StartRideButton).
   - §4 Light / Dark Mode: weather/rain colors (`rainClear` / `rainLight` /
     `rainHeavy`, `routePrimary` / `routeAlternative`) and functional colors
     (`success` / `warning` / `danger` / `accent`) defined with **both light
     and dark values**; rain percentages in **monospaced digits**; map
     overlay behavior.
   - §5 Accessibility: maps the `.opencode/rules/004-accessibility.md`
     checklist — VoiceOver, Dynamic Type, contrast 4.5:1 / 3:1 in light AND
     dark, ≥ 44 pt targets, Reduce Motion / Reduce Transparency, portrait +
     landscape (mounted).
   - §6 Motion & Haptics: transitions, loading states, ride-start haptic,
     warning haptic.

2. **Data-flow diagram** — embed one **mermaid** diagram directly into
   `docs/specs/<feature>.md` §4 Data Model (NO separate `.mmd` source
   file — GitHub renders the fence inline). Add it only if the spec does not
   already carry it. Drawn from the spec's §4 Data Model + spec-guide §4
   Data Flow: Destination → MKDirections → 2–3 route alternatives → sample
   waypoints every ~1 km → WeatherKit (current / minute / hourly) + Core ML
   → per-segment rain chance + ETA → route cards Driest / Fastest + rain
   overlay + departure time.

3. **Flow doc** — write the flow doc at the mirrored output path (e.g.
   `docs/flows/<feature>.md` or `docs/flows/<feature>/<slice>.md`) with all
   six template
   sections:
   - §1 Related Docs: the spec and design paths for the feature, filled in.
   - §2 Flow goal: user goal, start/end state, success outcome — derived
     from the spec's Goal.
   - §3 Spec coverage: map each flow step to the spec's requirement IDs
     (R1…Rn); every requirement must be covered by a step or an edge case.
   - §4 Design coverage: map each step/edge case to the design doc's
     screens and states (loading / empty / error / loaded), using the
     design section numbers.
   - §5 Main journey: start → end steps derived from the spec's Goal.
   - §6 Flow diagram: embed a **mermaid** user-flow diagram (user flow, not
     implementation detail), derived from the Main Journey steps, including
     the error branch.
   - Edge cases (offline route without rain overlay, "live rain
     unavailable", permission denied, empty states, rapid navigation) are
     recorded as rows in the §4 Design Coverage table (states like
     loading/failed) and as branches in the §6 diagram.

4. **Traceability check** — every flow event and state change must trace
   back to a spec requirement; every design element to the spec's feature
   description. Anything absent from the spec is flagged, never invented.

## Guardrails

- Never invent design or flow details absent from the spec — flag them as
  `TBD` or ask the user.
- Never write app code — this skill generates docs only.
- Read-only everywhere except the outputs — the design and flow docs at
  their mirrored paths (flat `docs/designs/<feature>.md` +
  `docs/flows/<feature>.md` for single specs; folder
  `docs/designs/<feature>/<slice>.md` + `docs/flows/<feature>/<slice>.md`
  for sliced specs) and the data-flow diagram embedded in the input spec's
  §4 Data Model.
- Use the correct output paths — mirror the input spec's location (folder
  `docs/<type>/<feature>/` for sliced specs, flat `docs/<type>/<feature>.md`
  for single specs).
- Colors must stay consistent with spec-guide's tokens — no new palette.
- Flow events must trace back to spec requirements.
- Scope: doc generation rules only — no app implementation content (no
  MVVM / Swift / framework internals).

## Output format

Hand back to the user:

```
Generated (paths mirror the input spec's location):
- docs/designs/<feature>.md or docs/designs/<feature>/<slice>.md — <sections filled>
- docs/flows/<feature>.md or docs/flows/<feature>/<slice>.md — <sections filled>
- <input spec path> — embedded data-flow diagram (added if absent)

Open questions / TBDs:
- <anything flagged during generation, or "none">
```