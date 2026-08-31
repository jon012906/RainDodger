# Rain Dodger — Accessibility Guidelines

Accessibility is not optional. Reference: `specs.md §7`. All new UI code is a11y-ready from the start.
Targets: **WCAG 2.1 AA** and **MAS-C** (Apple Accessibility Standards).

## 1. Why It Matters

Riders are a diverse group: vision loss, color blindness, low muscle control, hearing impairment,
temporary disabilities (gloves, rain, vibration, one-hand riding), and attention limits while moving.
A rider with a disability must get the same answer — "this route is driest" — as everyone else.

## 2. User Groups & What They Need

| Group | Typical need | Rain Dodger impact |
|---|---|---|
| Low vision / blind | VoiceOver reading of every piece of information on screen | Route cards must be fully read by VoiceOver: ETA, distance, rain %, "Driest"/"Fastest" |
| Color blind | Don't rely on color alone | Rain segments need labels/values, not just blue/yellow/red overlay color |
| Motor / dexterity limits | Large targets, no precision gestures | ≥ 44 pt targets; no pinch-only interaction; gloves already force this |
| Cognitive (attention, memory) | Glanceable, predictable, consistent | Consistent layout; info at a glance while riding; warnings before rain, not during |
| Hearing impaired | Visual warnings, not audio-only | Rain warnings visible, not spoken-only — add haptics |
| All riders with gloves / mounted + vibrating | Touch may land wrong; glance only | Touch targets tolerant to offset; one-hand operation; high contrast |

## 3. Requirements (apply to EVERY new feature/utility)

### VoiceOver (Screen Reader)

- Every custom view combination is accessible: `accessibilityElement(children: .combine)` or `.ignoreChildren`
- Labels describe meaning, not looks: "Fastest route, 25 minutes, 14 km, rain on 40%" — never "blue line"
- Decorative map overlays use `.accessibilityHidden(true)`; route info lives in accessible cards or map
  annotations with `.accessibilityLabel`
- Dynamic changes announced: when a route becomes "Driest" or rain warning triggers, use
  `AccessibilityNotification.Announcement`
- Interactions: custom controls use `.accessibilityAddTraits` (`.isButton`, `.isHeader`), actions
  via `.accessibilityAction`; never trap VoiceOver (accessibility first responder / navigation disabled)

### Dynamic Type

- Test at every text size from `.extraSmall` to `.accessibilityXXL` (and `.accessibilityXXXL` where reasonable)
- Never `fixedSize` vertical growth; use `LayoutPriority`, `ViewThatFits`, `ScrollView` where content grows
- Legend/overlay labels must scale; rain risk "%" numbers stay readable at 200% size

### Color & Contrast

- WCAG 2.1 AA: 4.5:1 for normal text, 3:1 for large text (18 pt / 14 pt bold) and graphical objects
- Rain overlay segments: 3:1 against route/map background; color PLUS label or pattern — never color only
- Respect dark mode; `Color.primary`/`Color.secondary` system colors, avoid hard-coded hexes
- Avoid red/green status pairs for color blind riders ("Dry"/"Wet" text labels, not icons+color only)

### Touch & Hit Targets

- Minimum **44 × 44 pt** (Apple HIG); glove target default: 44 pt with generous spacing
- No precision-only gestures (pinch-only, tiny sliders); alternatives provided (buttons, steppers, `.accessibilityAdjustableAction`)
- Buttons the most important action (Start Ride) is the biggest

### Motion & Effects

- Respect `Reduce Motion`: no flashing overlays, no unnecessary parallax, use `.accessibilityReduceMotion` for animations
- Respect `Reduce Transparency`: don't rely on translucency for legibility; overlays get solid backing
- Respect `Reduce Contrast`: don't rely on subtle differences; use labels

### Audio & Haptics

- Every spoken warning paired with a visual one (and haptic where safe while riding)
- Never the only channel: rider may be deaf, or environment noise > audio

## 4. Integration Checklist (per feature/utility)

1. VoiceOver: label, value, hint, traits on every custom element
2. Dynamic Type: layout survives scale-up; no clipped text
3. Contrast: 4.5:1 / 3:1 verified in light AND dark
4. Size: all interactive targets ≥ 44 pt
5. No color-only information; add text/patterns
6. Reduce Motion / Reduce Transparency respected
7. Orientation: both portrait and landscape (mounted)
8. Keyboard input where relevant (search destination field)

## 5. Testing (required before review)

- **Accessibility Inspector (Xcode):** run on simulator/device; fix every warning
- **VoiceOver:** rotor settings read (characters/words), full screen-reading pass; stop/start, re-read
- **Dynamic Type:** `.extraSmall` → `.accessibilityXXL` screenshots per screen
- **Color blindness:** Simulator → Features → Color Filters / Increase Contrast; route overlay still understandable
- **Reduce Motion + Reduce Transparency:** features still usable
- Real device with gloves or one thumb: all critical actions reachable layout and hit box
- Map-specific: route polyline and rain overlays remain distinguishable at 3:1 contrast, and map
  inaccessible elements don't leak nonsense VoiceOver reads

## 6. Definition of Done (added to acceptance criteria)

A feature is NOT done if any §3 requirement fails. A11y failures are **P0** — routed like any P0 bug
(Planner → fix plan → Executor → Reviewer passes).

## 7. Sources

- Apple Human Interface Guidelines: Accessibility (https://developer.apple.com/design/human-interface-guidelines/accessibility)
- Apple Accessibility for developers (https://developer.apple.com/accessibility/)
- Web Content Accessibility Guidelines 2.1 (https://www.w3.org/TR/WCAG21/)
