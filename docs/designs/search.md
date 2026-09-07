# Design — Destination Search

The feature is a search page presented as a modal sheet over the maps screen. Top: a search field. Below: a recent-destinations section (when recents exist) or live result rows.

## 1. Screens

- **Idle:** page opens, field auto-focused, no query yet. Shows the Recent section if recents exist; otherwise empty (nothing but the field).
- **Searching:** query typed; ProgressView while the (debounced) MapKit search runs.
- **Loaded:** result rows: circular category icon + bold name + secondary-gray street. Tap to select.
- **Empty:** query present but no results — "No results" message.
- **Error:** MapKit failure (e.g. offline) — error message + Retry.

## 2. Layout

- **Page:** modal sheet with a top search field and a scrollable list below. Presented via `.sheet` (system modal transition).
- **Search field (pinned at sheet top):** row with `magnifyingglass` · `TextField("Your Destination…")` · in-field clear X (only when text present) · `mic.fill` (decorative). Auto-focused on appear — focus is applied after the sheet settles so the keyboard reliably appears. Entire field ≥ 44 pt.
- **Close button:** trailing circular X (≥ 44 pt), always visible; dismisses the sheet — distinct from the in-field clear X.
- **Recent header:** "Recent" text header shown only when the recents list is non-empty; tap a recent row = select it (same action as a search result).
- **Result row:** leading circular icon (systemGray5 fill, SF Symbol) + `VStack` (bold name, secondary street). Row ≥ 44 pt.

**Landscape (mounted):** the field stays pinned to the top inside safe areas; the list scrolls beneath. No element cut off.

## 3. Components

- **SearchPage** — the modal sheet page; owns layout, the Recent section, and the state rendering (idle/searching/loaded/empty/error). Takes a `SearchViewModel` + `onSelect` callback.
- **SearchResultRow** — single result row (icon + name + street), reusable for both search results and recents.
- **SearchViewModel** — `@MainActor @Observable`; debounce, state machine, calls the search service.

## 4. Light / Dark Mode

- Page background: `Color.searchBackground` (#F1F2F6) in light; `Color(.systemBackground)` in dark.
- Search field + close button: `Color.searchElement` (#C6C6C8) in light; `Color(.systemGray5)` in dark — visibly lighter than the dark sheet background (Apple Maps style contrast).
- Result rows: `Color.searchElement` (#C6C6C8) rounded cards (16 pt radius) in light; `Color(.secondarySystemBackground)` in dark — visible in both modes.
- Result row icon: `Color(.systemGray5)` circle in both modes; SF Symbol `Color.secondary`.
- Name: `Color.primary`; street: `Color.secondary` — both ≥ 4.5:1 on the background (light street-on-card is lower contrast — accepted user choice for now).
- "Recent" header: `Color.secondary`, small-caps/uppercase-style header.

## 5. Accessibility

Per `.opencode/rules/004-accessibility.md`:

- VoiceOver labels (exact):
  - Search field: **"Your Destination…"** (placeholder), in-field clear X **"Clear search"**, trailing close **"Close search"**.
  - Result row: **"<name>, <street>"** (hint: "Double tap to select as destination").
  - Decorative `mic.fill` → `.accessibilityHidden(true)`.
- All interactive targets (field, X, rows) ≥ 44 × 44 pt.
- Dynamic Type: name/street scale; rows grow with text size; no `fixedSize` vertical growth.
- Reduce Motion: no custom animations on list/rows; the sheet uses the system transition.
- Contrast: `Color.primary`/`Color.secondary` on solid backgrounds (4.5:1 text / 3:1 graphics).

## 6. Motion / Haptics

- Sheet presents with the system modal transition (no custom animation); drag indicator visible (`.presentationDragIndicator(.visible)`).
- No haptics required this branch (selection is a plain navigation action).
