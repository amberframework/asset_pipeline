---
slug: activity-rings
ui_view: UI::ActivityRings
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/activity-rings.md
validation_report: ../validation/reports/activity-rings.md
---

# UI::ActivityRings

> A fixed-semantics activity summary for Move, Exercise, and Stand progress.
> The default taste should feel like a real health surface: black field,
> stable ring spacing, and enough margin that the rings never look crowded or
> decorative.

## Feel of the flow

Use `UI::ActivityRings` only when the surrounding product is genuinely about
personal activity progress. The rings should read as a compact progress summary
for one person, not as generic circular charts or a colorful accent.

This primitive is intentionally narrow. It preserves the HIG's canonical ring
colors and black circular field, while exposing only the geometry knobs needed
to place the element well inside a broader layout.

## Quickstart

```crystal
rings = UI::ActivityRings.new(0.75, 0.63, 0.50)
rings.size = 176.0
rings.thickness = 16.0
rings.gap = 8.0
rings.accessibility_label = "Today's activity rings"
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `move` | `Float64` | `0.0` | Move progress fraction, clamped to `0.0..1.0`. |
| `exercise` | `Float64` | `0.0` | Exercise progress fraction, clamped to `0.0..1.0`. |
| `stand` | `Float64` | `0.0` | Stand progress fraction, clamped to `0.0..1.0`. |
| `size` | `Float64` | `176.0` | Overall diameter of the circular field. |
| `thickness` | `Float64` | `16.0` | Stroke width for all three rings. |
| `gap` | `Float64` | `8.0` | Distance between rings and between the outer ring and the enclosing black margin. |

## Light / dark appearance notes

The rings themselves should not drift with system appearance. The black field,
ring colors, and ring spacing stay visually fixed; only the surrounding host
chrome changes with light and dark mode. That means the outer black margin is
part of the component, not dead space to squeeze away.

## Customization / brand override

Do not recolor the rings. Brand expression should happen in nearby copy,
layout, or surrounding surfaces instead of inside the ring element itself. The
safe overrides are geometry-only: `size`, `thickness`, and `gap`.

## What happens on each platform

- **iOS 26 / iPadOS 26**: Rendered through the shared composed fallback instead
  of `HKActivityRingView`, so it remains deterministic in validation and does
  not require HealthKit authorization.
- **macOS 26**: Rendered through the same fallback composition as an honest
  cross-platform study, even though Apple's HIG does not define a native macOS
  activity-rings surface.

## HIG citations (validated)

- Activity rings should only represent Move, Exercise, and Stand progress.
- Activity rings should always appear on a black background.
- The black background should remain visible around the outermost ring.
- The ring colors should not be changed.

Validation report:
[validation/reports/activity-rings.md](../validation/reports/activity-rings.md)

## Related

- `UI::ActivityRing` for a single-ring progress surface.
- `UI::Gauge` for non-Activity circular values.
