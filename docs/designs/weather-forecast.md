# Design — Weather Forecast (Rain Layer)

Reference screenshot (Apple Maps rain overlay, iOS): the route is drawn over the map as a polyline whose stroke color changes along its length — blue where rain is unlikely, yellow where rain is possible, red where rain is likely — so the road's weather is readable at a glance. A small overlay card sits at the top of the map explaining the colors and summarizing the ride's wet distance; while the forecast is computing, a dim scrim with a spinner and "Checking rain along your route…" covers the map.

## 1. Screens

- **Loading (weather computing):** Check Route dismisses the trip sheet first, then a dim scrim (45% black) covers the map with a centered card: `ProgressView` + "Checking rain along your route…" on a solid `Color(.systemBackground)` backing. Non-dismissable; map gestures blocked; the overlay covers the map and the route-summary pill. Light + dark: same layout; the card auto-adapts.
- **Loaded (forecast):** the selected route redraws as per-segment strokes — route-blue (<30%), yellow (30–60%), red (≥60%) — REPLACING the plain route-blue selected stroke; unselected alternatives stay muted blue as today. A `RainLegend` card floats top-leading over the map: chips "Dry <30%", "Light 30–60%", "Heavy rain ≥60%" plus the wet-distance line "14 km of 40 km with rain ≥ 50%" and the time line "Rain at 2:40 PM · 3:05 PM · 3:30 PM" (or with "+N more" when capped). A small `RainTimeBadge` (`cloud.rain.fill` + short arrival time) sits below the route line at the start of each wet stretch (cap 3). Route cards, existing ETA/fastest badges, pill, camera fit unchanged.
- **Offline / WeatherKit unavailable:** the legend is replaced by a non-blocking banner "Live rain unavailable" (cloud-slash icon + text on a solid backing); the route draws in plain route-blue as today — fully shown, plan not failed. No badges, no time line.
- **Re-selected route:** selecting another route card NEVER auto-fetches — a route with cached segments reuses them instantly (legend + colored segments + time badges stay); a route without segments shows no forecast (plain route-blue, legend hidden) until the rider taps Check Route.
- **Re-plan / Retry:** tapping Check Route again cancels the weather task, re-runs routing, and repeats loading → loaded (or the offline banner).
- **Departure change:** `setDepartureDate` re-plans via `plan()` (routing only) — the weather state resets to idle, so the time badges and legend time line clear until the rider taps Check Route again (no re-scoring without re-fetch).
- **Destination cleared:** clearing the destination (trip-planner R17/R18) resets the weather state to idle — the colored segments, legend, offline banner, and time badges all clear with the destination-only reset; the map returns to the empty search state.

## 2. Layout

- **Loading overlay:** full-map dim scrim (`.ignoresSafeArea()`) covering the map and the route-summary pill, with a centered card (max width ~280 pt): spinner (`ProgressView`, `.controlSize(.large)`) above the label; solid `Color(.systemBackground)` backing, 16 pt corner radius, subtle shadow; ≥ 44 pt effective height.
- **Legend card:** top-leading overlay over the map (12 pt from the top, 16 pt from the leading edge). Content column: a chip row (dot swatch + band label + % range), the wet-distance line underneath, and the time line underneath that. Solid `Color(.systemBackground)` backing, 14 pt corner radius, shadow; `minHeight` 44. `ViewThatFits(in: .horizontal)`: the chips row horizontal, with a vertical stacked fallback for huge Dynamic Type sizes.
- **Legend time line:** up to 3 short times joined by "·" (e.g. "Rain at 2:40 PM · 3:05 PM · 3:30 PM"); "+N more" appended when capped (e.g. "Rain at 2:40 PM · 3:05 PM · 3:30 PM +2 more").
- **Time badges:** one per wet stretch, anchored at the stretch-start coordinate (via `MapProxy.convert`) offset BELOW the route line (`y + 20`) so a badge never collides with the destination ETA badge (`y − 42`) or the fastest badge (`y − 26`); cap 3 — the first 3 wet stretches by route order. Badge content: `cloud.rain.fill` + short time on ONE line, never wraps.
- **Offline banner:** same top-leading position as the legend; icon + "Live rain unavailable" in a solid card, `minHeight` 44.
- **Map:** selected route = per-segment colored strokes (lineWidth 6) when segments exist, else plain route-blue 6 pt; unselected = route-blue at 40% opacity, 2 pt. Camera fit, existing ETA/fastest badges, pill unchanged.

## 3. Components

- **WeatherLoadingOverlay** — blocking scrim + spinner + "Checking rain along your route…"; VO "Checking rain along your route"; non-dismissable (no affordance); swallows map gestures.
- **RainLegend** — chips "Dry"/"Light"/"Heavy rain" with % ranges + the wet-distance line + the time line (up to 3 short times + "+N more"); a single combined VO element; information carried by text, never color alone. Gains a time-line input derived from the wet stretches.
- **RainTimeBadge** (private, inside `MapScreenView`) — `cloud.rain.fill` + short arrival time; recipe identical to `destinationETABadge`: Capsule `Color(.systemBackground)` backing, `Color.primary` text, shadow `black 0.25 / r4 / y2`, `.headline` (Dynamic Type scales), `.accessibilityHidden(true)`.
- **RainUnavailableBanner** — non-blocking "Live rain unavailable" notice rendered in place of the legend; VO "Live rain unavailable. Showing route without rain forecast."
- **RainSegment** (model) + `rainSegments` on `RouteAlternative` — see `docs/specs/weather-forecast.md §4`; `RainSegment` gains `arrivalDate: Date`.
- **WetStretch** (model, value type) + `RainMetrics.wetStretches(for:)` — contiguous wet runs (`rainChance ≥ wetThreshold`) derived from `rainSegments`; supplies each badge's start coordinate, arrival date, representative chance, and distance from start — see `docs/specs/weather-forecast.md §4–5`.
- **WeatherService (Live + Mock)** — protocol-first service behind the ViewModel.

## 4. Light / Dark Mode

- Legend/banner/overlay cards: `Color(.systemBackground)` backing in both modes; `Color.primary` text (≥ 4.5:1) — dark-adapts automatically.
- Scrim: `Color.black.opacity(0.45)` in both modes; the label sits on the solid card, so Reduce Transparency users keep fully legible content.
- Band colors: route-blue `Color.blue` (<30%), `Color.yellow` (30–60%), `Color.red` (≥60%) — identical in both modes. Yellow on a light map is lower-contrast; mitigated by the always-present text labels (chip labels + % ranges) and the wet-distance line — never color alone.
- Shadow on legend/banner cards: `Color.black.opacity(0.2)`, radius 6, y 2 — reads as floating above the map in both modes.
- Time badges: `Color(.systemBackground)` backing + `Color.primary` text (≥ 4.5:1 both modes) + shadow `black 0.25 / r4 / y2` — identical to the destination ETA badge; dark-adapts automatically.
- Legend time line: `.rdRowStreet` text in `Color.primary`; "·" separators and "+N more" in `Color.secondary` (≥ 4.5:1 both modes). No raw hex colors anywhere in the badge or time line.

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels (exact):
  - Loading overlay: **"Checking rain along your route"** (scrim `.accessibilityHidden(true)`; card combined into one element).
  - Legend (with time badges, cap 3, 2 more wet stretches): **"Rain legend. Dry, under 30 percent. Light, 30 to 60 percent. Heavy rain, 60 percent or more. 14 kilometers of 40 kilometers with rain 50 percent or more. Rain likely at 2:40 PM, 3:05 PM, and 3:30 PM. 2 more wet stretches."** (single combined element; swatch dots `.accessibilityHidden(true)`). With no wet stretches the time sentence is omitted.
  - Offline banner: **"Live rain unavailable. Showing route without rain forecast."**
  - Rain-time badges are decorative: `.accessibilityHidden(true)` — the same information is always carried by the legend's extended VO label.
  - Rain polylines are pure graphics (`.accessibilityHidden` is unavailable on `MapPolyline`) — the same information is always exposed as text by the legend, the wet-distance line, and the time line.
- **Non-color-only:** every band has a text label + % range; the wet-distance line carries the quantitative summary; the time line carries the "when" answer in text; color-blind riders get the full answer from text.
- **Touch targets:** the legend/banner cards are NOT interactive (no accidental activation while mounted) but keep `minHeight` 44 for glanceability; time badges are NOT interactive; the loading overlay swallows map gestures so no pan/zoom races the computation.
- Dynamic Type: legend/banner text scales; time badges use `.headline` so they scale; `ViewThatFits` falls back to a stacked chip column at large sizes so nothing clips.
- Reduce Motion: overlay, legend, banner, time badges, and the legend time line appear/disappear instantly (no fade/scale custom animation); colored segments swap instantly.
- Contrast: `Color.primary` text on `Color(.systemBackground)` ≥ 4.5:1 in both modes; the scrim dimming never carries information.

## 6. Motion / Haptics

- **Loading overlay:** appears/disappears instantly (state-driven, no custom animation); `ProgressView` is the system indeterminate spinner.
- **Legend/banner:** static; no entry/exit animation (Reduce Motion friendly).
- **Time badges + legend time line:** appear/disappear instantly when the forecast attaches or clears (state-driven, no custom animation); never move across the map.
- **Colored segments:** swap instantly when the forecast attaches; no stroke transition.
- **No haptics this branch** (weather computation and route selection are passive; warning haptics come in Phase 5).