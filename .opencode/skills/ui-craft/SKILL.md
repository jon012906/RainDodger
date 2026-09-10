---
name: ui-craft
description: >
  Build Rain Dodger SwiftUI views to the Impeccable craft floor: platform-native
  controls, semantic tokens, Dynamic Type, 44pt targets, every state, safe areas,
  and purposeful motion — no web-shaped UI, no glitches. Use when the Executor
  implements or fixes anything under RainDodger/Views/, builds a screen from a
  design doc, or the user asks to build, polish, or fix a SwiftUI screen. Do not
  use for planning/shaping UI (that's ui-shape), code review (that's
  swift-review), design-doc review (that's design-review), or Swift tests (that's
  swift-testing).
---

I am the UI execution operator for this repo. I build SwiftUI screens that pass
the Impeccable craft floor and the iOS slop test, exactly to the approved design
doc and plan — native, glitch-free, glove-friendly.

## When to use

- As the Executor, for any change under `RainDodger/Views/` (and UI state it
  needs in `ViewModels/`).
- Building a screen from `docs/designs/<feature>.md` + the approved plan.
- Fixing a UI bug/glitch: layout, state, animation, overflow, dark mode.
- User asks "build the screen", "match the design", "fix this UI".

Not for:

- Shaping/planning UI — that's `ui-shape`.
- Reviewing — `swift-review` (code), `design-review` (design docs).
- Non-UI Swift (models/services) — follow 003 only.

## Build rules, in order

1. **The design doc wins.** Implement the tokens, components, layout, states,
   and copy exactly as specified in `docs/designs/<feature>.md`. If the doc is
   silent or ambiguous, stop and report the blocker — never invent visual
   decisions.
2. **The incumbent world wins.** Reuse existing components/tokens/patterns in
   `RainDodger/Views/`; match neighboring screens' spacing, type, and color.
   New components only when the plan says so.
3. **Platform-native, always** (Impeccable iOS reference):
   - System navigation (NavigationStack/sheet), large titles on top-level
     screens, edge-swipe back untouched
   - Platform controls (Toggle, Picker, Stepper, .alert, .confirmationDialog)
     and SF Symbols — never web-shaped buttons or emoji icons
   - Layout inside safe areas; nothing under the notch, Dynamic Island, home
     indicator, or keyboard
   - Semantic system colors (`Color.primary`/`.secondary`, `.systemBackground`,
     `.separator`, materials); raw hex only for brand tokens the design doc
     defines with both light and dark values
   - Dynamic Type styles (`.body`, `.headline`, …), no hard-coded point sizes;
     layout must survive `.accessibilityXXL`
   - ≥ 44×44 pt targets with spacing; no precision-only gestures
   - System transitions; one authored motion moment; crossfade under Reduce
     Motion; never fight the navigation model
4. **Every state exists:** loading, empty, loaded, error, permission denied,
   offline, disabled. A happy-path-only screen is unfinished.
5. **Copy is design material:** controls name their action; errors name the
   problem and the recovery; product terminology stays consistent.

## Glitch checklist (verify before handoff)

- **Layout:** truncation at large Dynamic Type; `.fixedSize` blocking growth;
  fixed frame heights clipping; rows under 44 pt; content under the home
  indicator or keyboard; map overlay z-order.
- **State:** view not re-rendering from `@Observable`; `@State` seeded from
  changing input; work re-firing on every render (`.task(id:)` vs `.onAppear`);
  stale data after cancellation; errors swallowed with `try?`.
- **Lists:** `List`/`LazyVStack` for long content; stable `id`s; dividers and
  insets consistent with neighboring screens.
- **Animation:** implicit animations re-triggering on unrelated state writes;
  missing `withAnimation` for visible changes; animation still running under
  Reduce Motion; animating non-animatable values.
- **Appearance:** hard-coded colors breaking dark mode; contrast below
  4.5:1 / 3:1; color-only information; materials with no Reduce Transparency
  fallback.
- **Map:** overlays hidden from VoiceOver; camera/legend updates causing
  render loops.

## Verify before handoff

- Build: `bash .opencode/scripts/xcode-tools.sh build`; on failure only
  `tail -30 .opencode/tmp/xcodebuild.log`.
- Run the smoke flow: `bash .opencode/scripts/xcode-tools.sh run` (or the
  `simulator-testing` skill) — take the screenshot path from the script's own
  output.
- Previews with mocked services for every state the screen renders; dark mode
  and a large Dynamic Type size in previews.
- Walk the design doc against the rendered result state by state.
- Hand off with the standard Executor checklist (path:line per file) + the
  screenshot path.

## Refuse (unless the design doc or plan explicitly chose it)

Nested cards, cards-as-structure, hard offset shadows, gradient text, glass as
decoration, emoji icons, gray text on colored surfaces, untinted black/white,
one identical entrance on every element.

## Guardrails

- Never commit or push; the user runs `@push`.
- No comments in code (003); MVVM: views render ViewModel state only — never
  call services or SwiftData from a view.
- If the design doc and the plan disagree, stop and report — do not pick one.
- This skill never relaxes 003/004; it operationalizes them.

Source: adapted from Impeccable (https://github.com/pbakaus/impeccable,
Apache-2.0) — iOS platform reference + craft floor.
