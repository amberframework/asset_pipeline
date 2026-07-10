---
slug: gauges
ui_view: UI::Gauge
priority: P2
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/gauges.md
validation_report: ../validation/reports/gauges.md
---

# UI::Gauge

> A compact circular gauge for bounded values like storage, capacity, or
> readiness. The default taste should feel measured and quiet: one clear arc,
> one readable value, and enough surrounding space that the gauge reads as an
> instrument instead of decoration.

## Feel of the flow

Use `UI::Gauge` when the number matters, but the surrounding context benefits
from a quick visual read. Good gauges feel stable and glanceable. They should
support a quick scan first, then let the number confirm the meaning.

This first-pass primitive is a shared fallback surface built from `UI::Canvas`
plus labels. It is honest about being portable now while leaving room for a
future native gauge bridge later.

## Quickstart

```crystal
gauge = UI::Gauge.new(
  72.0,
  0.0,
  100.0,
  "Disk usage",
  "Live capacity",
  "Keep below 80%",
  "Used across the current workspace"
)
gauge.accessibility_label = "Disk usage gauge"
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `value` | `Float64` | `0.0` | Current value to display. |
| `minimum_value` | `Float64` | `0.0` | Lower bound of the gauge range. |
| `maximum_value` | `Float64` | `100.0` | Upper bound of the gauge range. |
| `units` | `String?` | `"%"` | Units appended to the value label. |
| `value_precision` | `Int32` | `0` | Decimal precision for the visible value. |
| `label` | `String?` | `nil` | Optional title above the gauge. |
| `prompt` | `String?` | `nil` | Optional secondary prompt above the stage. |
| `caption` | `String?` | `nil` | Supporting text below the gauge. |
| `help_text` | `String?` | `nil` | Additional low-emphasis copy below the caption. |
| `show_value` | `Bool` | `true` | Whether to show the centered value text. |
| `diameter` | `Float64` | `180.0` | Overall stage width and height. |
| `ring_thickness` | `Float64` | `12.0` | Stroke width for the track and progress arc. |
| `track_color` | `UI::Color` | neutral gray | Background ring color. |
| `progress_color` | `UI::Color` | blue | Active progress arc color. |

## Light / dark appearance notes

Gauges need both shape clarity and contrast discipline. The track must stay
visible in dark mode, and the progress arc should feel purposeful rather than
glowing for attention. Keep the centered value readable without letting it
compete with the ring.

## Customization / brand override

Brand work should mostly happen through restrained accent color, supporting
copy, and the surrounding layout. When the arc gets too loud or the stage gets
too cramped, the gauge stops reading as an instrument and starts reading as a
badge.

## What happens on each platform

- **macOS 26**: Currently rendered through the shared fallback built from
  `UI::Canvas` and labels.
- **iOS 26 / iPadOS 26**: Rendered through the same fallback surface.

## Related

- `UI::ProgressView` for linear or spinner-style progress.
- `UI::ChartView` for richer trend and distribution data.
