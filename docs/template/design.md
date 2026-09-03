# Design — <Feature Name>

_Usage: copy to `docs/designs/<feature>.md`, rename, and fill in._

Guiding questions: What screen/state does the rider see? How does loading/error/success look? Are controls glove-friendly? Is it accessible?

## 1. Screens

List each screen/state:

- Empty
- Loading
- Loaded
- Error
- Permission denied
- Offline

## 2. Layout

What appears where? Map, cards, buttons, search field, overlays.

## 3. Components

Reusable UI pieces:

- DestinationSearchField
- RouteCard
- RainRiskBadge
- StartRideButton

## 4. Light / Dark Mode

Colors, contrast, map overlay behavior.

## 5. Accessibility

VoiceOver labels, Dynamic Type, 44pt touch targets, high contrast.

Must satisfy `.opencode/rules/004-accessibility.md`.

## 6. Motion / Haptics

Transitions, loading states, ride-start haptic, warning haptic.