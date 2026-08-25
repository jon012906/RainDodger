# Design Spec — Rain Dodger

Template for capturing the app's visual design from high-fidelity design screenshots (Figma/Sketch exports). Fill each section in when design assets are provided. Light & Dark mode are mandatory for every value.

## 1. Design Source

| Field | Value |
|---|---|
| Screenshots source | _e.g. Figma file / exported PNGs_ |
| Screenshot date / version | |
| Asset files location | |
| Designer notes | |

## 2. Color Palette

### Semantic Colors

| Token | Light | Dark | Usage |
|---|---|---|---|
| `background` | | | App background |
| `surface` | | | Cards, sheets |
| `surfaceSecondary` | | | Secondary surfaces |
| `textPrimary` | | | Body text |
| `textSecondary` | | | Secondary text |
| `separator` | | | Dividers |

### Weather / Rain Colors (key feature)

| Token | Light | Dark | Usage |
|---|---|---|---|
| `rainClear` (<30%) | | | Dry route segment |
| `rainLight` (30–60%) | | | Light rain segment |
| `rainHeavy` (>60%) | | | Heavy rain segment |
| `routePrimary` | | | Main route line |
| `routeAlternative` | | | Other route lines |

### Functional Colors

| Token | Light | Dark | Usage |
|---|---|---|---|
| `success` | | | "Driest route" badge |
| `warning` | | | "Fastest but wet" badge |
| `danger` | | | Errors, heavy rain alerts |
| `accent` | | | Primary buttons, selection |

## 3. Typography

| Style | Size | Weight | Usage |
|---|---|---|---|
| Large Title | | | Screen titles |
| Title / Heading | | | Route card title |
| Body | | | Body text |
| Caption | | | Rain % labels |
| Route ETA | | | Big ETA on route cards (glanceable) |

- Rain percentage always uses **monospaced digits** to prevent layout shift.

## 4. Spacing & Radii

| Token | Value | Usage |
|---|---|---|
| `spacing.xs` | | 4 pt base |
| `spacing.s` | | |
| `spacing.m` | | |
| `spacing.l` | | |
| `cornerRadius.s` | | Route cards |
| `cornerRadius.m` | | Sheets, buttons |
| Card padding | | |
| Min hit target | ≥ 44 pt | All tappable elements (gloves) |

## 5. Iconography

| Icon | Style | Notes |
|---|---|---|
| Rain drops / umbrella (dry route) | | SF Symbol or custom |
| Fastest route badge | | |
| Rain warning | | |
| Map pins (start / destination) | | |
| Departure time | | |
| Route line stroke style | | _e.g. 8 pt, round cap, casing_ |

## 6. Screens (one per high-fidelity screenshot)

For each screen, paste the screenshot and fill in:

### Screen: `_screen name_`
- **Screenshot:** `_link/path_`
- **Layout:** brief description (list, map top/bottom split, safe areas, landscape behavior)
- **Components on screen:**
  - _Component → style per token above_
- **States:** loading / empty / error / loaded
- **Dark mode notes:** differences from light
- **Landscape (mounted) notes:** how glanceable elements re-arrange

## 7. Component Inventory

List every reusable component with a small spec each:

| Component | Spec |
|---|---|
| Route card | |
| Destination search bar | |
| Departure time picker | |
| Start ride button | |
| Rain legend | |
| Weather banner | |

## 8. Motion & Interaction

| Item | Spec |
|---|---|
| Route selection transition | |
| Rain overlay animation | |
| Haptic feedback points | _ride start, rain warning_ |
| Sheet presentation | _destination search, route details_ |

## 9. Accessibility & Glove Usability Checklist

- [ ] All interactive targets ≥ 44 pt
- [ ] Rain color coded + not color-only (add % text, patterns)
- [ ] Contrast ≥ 4.5:1 for text in both modes
- [ ] Dynamic Type supported
- [ ] Both light & dark mode checked per screen
