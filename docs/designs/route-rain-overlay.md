# Design — Route Rain Overlay (Apple Maps UI/UX)

## 1. Design Source

- Feature spec: `docs/specs/route-rain-overlay.md` (requirements R1–R9)
- Product guide: `docs/specs/spec-guide.md` §2 (decision flow), §6 (UI principles), §4 (data flow)
- Interaction reference: Apple Maps routing UX — search field, route cards, selectable polylines, turn-by-turn guidance (no external assets; native SwiftUI/MapKit components)
- Color token source: Apple system palette (systemBlue/systemGray family + weather-derived tints); thresholds from spec-guide §6

## 2. Screens

### Color Tokens (used across all screens)

| Token | Meaning | Light | Dark |
|---|---|---|---|
| `rainClear` | Segment rain chance < 30% | `#2E7D32` (green) | `#66BB6A` |
| `rainLight` | 30–60% chance | `#F9A825` (yellow) | `#FFD54F` |
| `rainHeavy` | > 60% chance | `#1565C0` (blue) | `#64B5F6` |
| `routePrimary` | Selected route polyline | `#007AFF` | `#0A84FF` |
| `routeAlternative` | Non-selected route polyline | `#8E8E93` | `#636366` |
| `success` | "Driest" badge, dry summary | `#34C759` | `#30D158` |
| `warning` | Rain warning banner | `#FF9500` | `#FF9F0A` |
| `danger` | Heavy rain alert, wet-distance summary | `#FF3B30` | `#FF453A` |
| `accent` | Primary action ("Start ride") | `#0A84FF` | `#0A84FF` |

Rules: rain overlay colors sit at 3:1 contrast against route/map background in both modes (verified per `.opencode/rules/004-accessibility.md` §3). Rain percentage labels use `.monospacedDigit()` so digits don't jump at a glance. `rainClear` never appears as a filled overlay on dry routes — dry segments keep the plain route color.

### Screen 1 — Route Planning (P0, R1–R5, R7–R9)

Apple Maps-style layout:

- **Search field** (top, 44 pt height): destination input; keyboard input supported (a11y §4.8). Focused state shows recent destinations.
- **Map** (fills screen, `MapKit` `Map`): route polylines drawn after direction results. Selected route = `routePrimary`; alternatives = `routeAlternative` (3 pt stroke, `MKRoute.polyline`). Rain overlay = `MKPolylineRenderer` overlay segments colored by `rainClear`/`rainLight`/`rainHeavy` with a **chance % label** (monospaced) at heavy-segment midpoints — never color-only.
- **Route cards** (bottom sheet, collapsible): 1–3 cards, each showing:
  - ETA (bold, large), distance
  - Rain badge: `success` "Driest" (R3) or `warning` "Rain ahead" with wet-distance summary in `danger` for the fastest route ("14 km of 40 km with rain ≥ 50%", R4)
  - Departure-time suggestion line (P1, R7): "Leave in 20 min — rain passes in 40 min"
- **"Start ride" button** (bottom, biggest on screen, ≥ 44 pt, `accent`): enabled only when a route is selected.

States:

| State | Behavior |
|---|---|
| Idle | Map only; search field placeholder "Where to?"; no cards |
| Loading routes | Cards area shows 3 skeleton cards (Reduce Motion: static placeholders, no shimmer) |
| Loading weather | Selected/visible route overlays fade in when per-segment data arrives; label "Checking rain…" |
| Loaded | Cards + rain overlay + badges; selection highlights polyline |
| Error | Route error: inline card "Routes unavailable — retry"; weather error: routes still drawn, banner "live rain unavailable" (R8) |
| Empty | No destination match: "No places found" below search field |

Dark mode: same token set (dark values); map follows system; cards use solid backing (no translucency dependence, a11y Reduce Transparency).

### Screen 2 — Riding / Turn-by-turn (P1, R6)

Apple Maps turn-by-turn look, top guidance banner + map below:

- **Guidance banner**: next instruction + distance, `success` background while dry.
- **Rain warning**: approaching a `rainHeavy` segment flips banner to `warning`/`danger` — "Rain in 5 km — chance 70%" — spoken (AVSpeechSynthesizer) + haptic + visual, **before** the segment (a11y §2 hearing impaired).
- Bottom status: ETA to destination; remaining wet distance when on a rainy route.

States: navigating / approaching-rain (warning shown) / arrived ("You've arrived", haptic).

## 3. UI/UX Principles

- Glanceable: ETA + rain risk readable at a glance while mounted; no more than 3 route cards; single badge per card
- Glove-friendly: every hit target ≥ 44 pt with generous spacing; no pinch-only gestures; card tap = selection, big "Start ride"
- High contrast: rain colors distinct from route color (blue on gray/blue route is avoided — `rainHeavy` uses blue only on dry `routePrimary` segments with % labels), light + dark verified
- Consistent: Apple Maps mental model throughout; rain layer is the only addition

## 4. Accessibility

Maps `.opencode/rules/004-accessibility.md` checklist:

1. **VoiceOver**: route cards combined into one element reading "Fastest route, 25 minutes, 14 km, rain on 40% of segments" — never "blue line". Decorative map polylines `.accessibilityHidden(true)`; rain segment % lives in the cards + map annotation labels. "Driest" change announced via `AccessibilityNotification.Announcement`; "Start ride" `.isButton` trait.
2. **Dynamic Type**: `.extraSmall` → `.accessibilityXXL`; card text flows, no `fixedSize`; search field and banner grow via `ViewThatFits`; rain % monospaced stays legible at 200%.
3. **Contrast**: 4.5:1 text, 3:1 rain segments vs. map in light AND dark (token pairs above); dry/wet communicated by text labels ("Driest", "Rain ahead"), not color alone.
4. **Hit targets**: search field, cards, Start ride ≥ 44 pt; no precision gestures.
5. **No color-only info**: every colored segment has a % label or card text.
6. **Reduce Motion**: rain overlay fades (no flashing); skeleton cards static; respect `.accessibilityReduceMotion`.
7. **Reduce Transparency**: cards/banners solid-backed.
8. **Orientation**: portrait + landscape (mounted) both supported; cards stack in portrait, side rail in landscape.
9. **Keyboard**: destination search field full keyboard access.

## 5. Motion & Interaction

- Route selection: selected polyline animates to `routePrimary` with a 0.2 s crossfade; card lifts 2 pt
- Rain overlay: segments fade in per route (staggered 0.15 s) when weather loads — respects Reduce Motion
- Route cards: sheet slides up on results; collapse/expand spring
- Rain warning: banner flips to `warning` with a single non-repeating pulse; `UINotificationFeedbackGenerator.warning` haptic
- Ride start: haptic confirm + transition to guidance banner slide-in
- All animations gated on `.accessibilityReduceMotion`