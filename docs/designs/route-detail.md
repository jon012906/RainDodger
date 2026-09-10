# Design — Route Detail

Reference screenshot (Apple Maps route step list, iOS): after selecting a route and tapping its expanded detail, a full-height sheet lists the turn-by-turn steps — each row a turn-arrow icon, the instruction text, and the distance on the right; rainy steps add a rain icon and a percentage. A back chevron at the top returns to the route options. Rain Dodger shows this step list by expanding the **existing** planner sheet (`.medium` → `.large`) when the rider re-taps the already-selected route card — no nested second sheet.

## 1. Screens

- **Route cards (unchanged):** the planner half-sheet with origin/destination/stop, Leave at, Check Route, and the route cards. Re-tapping the **selected** card switches to the step view.
- **Detail loaded with wet steps:** sheet expanded to `.large`; header row (back chevron · "Route details" title · empty trailing), wet-distance summary "Rain on 14 km of 40 km", and the scrollable step list. Wet steps show `cloud.rain.fill` + a percentage; dry steps show only icon + instruction + distance.
- **Checking rain:** while `weatherState == .loading` the header area reads "Checking rain along your route…" (inline `ProgressView` + label); step marks are withheld until the forecast attaches.
- **No forecast (idle):** steps render without marks; a full-width blue "Check route for rain" button sits at the bottom of the step view and calls `checkRoute()`.
- **Weather unavailable:** the header area shows the note "Live rain unavailable" (`icloud.slash` icon + text); steps render without marks; no summary, no button.
- **Empty steps:** a centered "Turn-by-turn directions unavailable for this route" message replaces the list; the back control stays.
- **Back to cards:** tapping the back chevron returns to the route cards and collapses the sheet to `.medium`, with all trip state preserved.

## 2. Layout

- **Sheet:** the existing `TripPlannerSheet` presents with `.presentationDetents([.medium, .large], selection: $detent)`; the step view drives `detent = .large`, the route-card view keeps `.medium`. Same sheet instance — no nested presentation. Drag dismissal and drag-down to `.medium` behave as today.
- **Step view (`RouteDetailSheet`)** — content column from top:
  - **Header row:** leading back button (48 × 44 pt, `chevron.left`, VO "Back to routes"); centered "Route details" title (`.isHeader`); trailing spacer.
  - **Summary row (forecast loaded):** "Rain on 14 km of 40 km" (`Color.primary`), single line, left-aligned under the header.
  - **Checking row:** inline `ProgressView(.small)` + "Checking rain along your route…" (`Color.secondary`).
  - **Unavailable note:** `icloud.slash` icon (`Color.secondary`) + "Live rain unavailable" (`Color.primary`). (`cloud.slash` is not available in SF Symbols; `icloud.slash` is the corrected symbol.)
  - **Step list:** vertical `ScrollView` with one `RouteStepRow` per step inside a rounded card (`Color.searchElement` light / `Color(.secondarySystemBackground)` dark), hairline dividers between rows, same card treatment as the trip rows.
  - **Bottom affordance (idle only):** full-width "Check route for rain" button — `Color.checkRouteBlue` backing, white `cloud.rain` icon + label, ≥ 44 pt — calls `viewModel.checkRoute()`.
- **RouteStepRow** — leading turn icon (24 pt, `Color.secondary`), instruction text (`Color.primary`, `.rdRowName`, wraps to 2 lines max), trailing distance text (`Color.secondary`, `.rdRowStreet`); wet steps add `cloud.rain.fill` (blue) + "60%" (`Color.primary`) after the distance. Row min-height 44 pt; when the instruction is long the distance column stays right-aligned.
- **Map (unchanged):** the selected route's colored rain segments, legend, badges, and camera fit are untouched by the step view.

## 3. Components

- **RouteDetailSheet** — the step view rendered inside `TripPlannerSheet` when the selected card is re-tapped; owns the back control, the header summary/note, the step list, and the "Check route for rain" affordance; renders `TripPlannerViewModel` state (weather idle/loading/loaded/unavailable, empty steps).
- **RouteStepRow** — one step: `RouteTurnType` icon + instruction + distance + optional rain icon/% (wet only). Renders a `RouteStep` plus its representative `rainChance: Double?` (nil = no forecast; < 0.50 = dry, no mark).
- **RouteTurnType icon mapping** (icons are decorative; the instruction text carries the meaning):
  - `depart` → `location.north.fill` · `straight` → `arrow.up` · `turnLeft` → `arrow.turn.up.left` · `turnRight` → `arrow.turn.up.right` · `slightLeft` → `arrow.up.left` · `slightRight` → `arrow.up.right` · `keepLeft` → `arrow.turn.up.left` · `keepRight` → `arrow.turn.up.right` · `merge` → `arrow.merge` · `roundabout` → `arrow.triangle.turn.up.right.circle` · `uTurn` → `arrow.uturn.left` · `arrive` → `flag.checkered` · `other` → `arrow.up`
- **RouteCard (modified)** — its tap handler now distinguishes select (non-selected card) from expand (already-selected card); the sheet's re-tap switches to the step view.
- **TripPlannerSheet (modified)** — gains the cards/steps mode (`@State`), the `.medium`/`.large` detent selection binding, and hosts `RouteDetailSheet` in steps mode.
- **TripPlannerViewModel (modified)** — exposes the selected alternative's steps, computes each step's representative rain chance from `rainSegments`, and exposes the wet-distance summary via `RainMetrics`.
- **RainMetrics (shared)** — the single shared wet-distance helper (`RainMetrics.wetDistance(for:)`) used by `MapScreenView`/`RainLegend` and `RouteDetailSheet` so the map legend and the detail header always agree.

## 4. Light / Dark Mode

- Step view background matches `TripPlannerSheet`: `Color.searchBackground` in light / `Color(.systemBackground)` in dark.
- Step rows sit in one rounded card: `Color.searchElement` in light / `Color(.secondarySystemBackground)` in dark, hairline dividers (`Color(.separator)`) — same treatment as the trip rows.
- Instruction text `Color.primary` (≥ 4.5:1), distance `Color.secondary`; turn icon `Color.secondary` (decorative).
- Rain mark: `cloud.rain.fill` in `Color.blue` + "60%" in `Color.primary` — the % text carries the information (never icon+color alone); blue on the card backing stays ≥ 3:1 in both modes.
- Summary "Rain on 14 km of 40 km": `Color.primary` on the card/sheet background (≥ 4.5:1 in both modes).
- Checking row and unavailable note: `Color.secondary` icon + `Color.primary` text.
- "Check route for rain" button: solid `Color.checkRouteBlue` (~#0054D4) with white text + white icon — white-on-blue ≈ 6.8:1 in both modes; same as the existing Check Route button.
- Back chevron: `Color.primary` glyph on the sheet background (≥ 4.5:1).

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels (exact):
  - Back control: **"Back to routes"**; hint "Double tap to return to route options".
  - Detail title: **"Route details"** (`.isHeader`).
  - Wet-distance summary: **"Rain on 14 kilometers of 40 kilometers, rain 50 percent or more"** (single combined element; the ≥ 50% threshold is spoken, not only visual).
  - Checking row: **"Checking rain along your route"**.
  - Unavailable note: **"Live rain unavailable. Showing route without rain forecast."**
  - Step row (wet): **"Turn left onto Main Street, 800 meters, rain 60 percent"** (instruction text + distance + "rain N percent" only when the step is wet).
  - Step row (dry / no forecast): **"Turn left onto Main Street, 800 meters"**.
  - Distance spoken: < 1000 m → "N meters"; ≥ 1000 m → "X.X kilometers" (one decimal).
  - "Check route for rain" button: **"Check route for rain"**; hint "Double tap to check the route for rain".
  - Empty-steps note: **"Turn-by-turn directions unavailable for this route"**.
  - Turn icons and rain icons: `.accessibilityHidden(true)` — the combined row label carries all information.
- All interactive targets (back chevron, "Check route for rain" button) ≥ 44 × 44 pt; rows are non-interactive but ≥ 44 pt for glanceability.
- Dynamic Type: instruction text wraps (max 2 lines, no vertical clipping); rows and the header grow with text size; the list scrolls; the summary row uses `ViewThatFits` fallback to a stacked layout when the line is too wide.
- Non-color-only: turn meaning comes from the instruction text (icons decorative), rain from the "60%" text (never icon+color alone).
- Reduce Motion: the `.medium` → `.large` detent change is the system detent animation; step rows and rain marks appear instantly (state-driven, no custom animation); back collapse is the system transition.
- Contrast: `Color.primary` text on solid backings ≥ 4.5:1 in both modes; `Color.secondary` labels carry the lower-contrast caveat already accepted in `docs/designs/trip-planner.md:86`.

## 6. Motion / Haptics

- **Expansion / collapse:** system detent animation only (no custom transition); Reduce Motion → system default, no custom movement.
- **Step list:** static rows; appear/disappear instantly with the mode switch.
- **Rain marks:** attach instantly when the forecast finishes (no fade/scale).
- **No haptics this branch** (the step view is a passive preview; ride-start/warning haptics come later).