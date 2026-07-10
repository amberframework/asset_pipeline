---
slug: charts
ui_view: UI::ChartView
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/charts.md
validation_report: ../validation/reports/charts.md
---

# UI::ChartView

> A data visualization view that renders bar, line, or placeholder pie marks with
> category labels and a baseline axis reference, using system blue CALayer fills on
> macOS and iOS. On macOS 26, the plot area uses a flat NSStackView-based layout with
> rounded-rect ~8pt corner styling; on iOS 26, the same UIStackView structure tracks
> the system appearance via UIColor.labelColor semantic fills for labels.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A chart is the right tool when your UI needs to communicate relative quantities,
trends, or proportions in a dataset at a glance. The HIG describes bar marks as
working "especially well when each value can represent a sum, like the total number of
steps taken in a day." Reach for UI::ChartView when you have a small, fixed set of
category values (5-10 data points) that people need to compare side-by-side. It is NOT
a general-purpose plotting engine: it has no pan/zoom, no interactive tooltip, and no
real-time data binding. For those use cases, embed a native Swift Charts view via
UIViewRepresentable rather than using UI::ChartView.

(HIG: "An effective chart highlights a few key pieces of information in a dataset,
helping people gain insights and make decisions." -- Charts / Introduction.)

## Quickstart

```crystal
chart = UI::ChartView.new
chart.chart_type = :bar
chart.title = "Steps This Week"
chart.data_points = [
  UI::ChartDataPoint.new(label: "Mon", value: 6200.0),
  UI::ChartDataPoint.new(label: "Tue", value: 8400.0),
  UI::ChartDataPoint.new(label: "Wed", value: 5100.0),
  UI::ChartDataPoint.new(label: "Thu", value: 9800.0),
  UI::ChartDataPoint.new(label: "Fri", value: 7300.0),
  UI::ChartDataPoint.new(label: "Sat", value: 11200.0),
  UI::ChartDataPoint.new(label: "Sun", value: 4600.0),
]
chart.show_grid = true
chart.accessibility_label = "Steps this week bar chart, Mon through Sun"
```

Renders: on macOS 26, an NSStackView-based bar chart (~360x220pt) with system blue
NSView CALayer bars scaled to data values, NSTextField category labels, and a
NSView hairline baseline. On iOS 26, the equivalent UIStackView layout with
UIColor.labelColor semantic titles, UIColor.secondaryLabelColor category labels, and
CALayer blue fills. No Liquid Glass material -- chart is a content surface, not a
presentation surface.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `chart_type` | `Symbol` | `:bar` | Selects the mark type: `:bar` renders vertical bars, `:line` renders dot+stem columns suggesting a trend, `:pie` renders a placeholder filled circle |
| `title` | `String` | `""` | Chart title rendered above the plot area; empty string skips the title label |
| `data_points` | `Array(UI::ChartDataPoint)` | `[]` | Array of `{label, value, color?}` records; bars/dots are scaled to the max value in the array |
| `show_legend` | `Bool` | `true` | (Planned) when true, a legend row will be rendered; currently has no visual effect |
| `show_grid` | `Bool` | `true` | (Planned) when true, horizontal grid lines at 25/50/75% will be rendered; currently has no visual effect |
| `accessibility_label` | `String?` | `nil` | Accessibility label on the outer container; defaults to "Chart: <title>" if nil |

Each `UI::ChartDataPoint` record accepts:

| Field | Type | Default | Effect |
|-------|------|---------|--------|
| `label` | `String` | `""` | Category label rendered below the bar or dot |
| `value` | `Float64` | `0.0` | Data value; bars are scaled relative to the max value in the array |
| `color` | `UI::Color?` | `nil` | Per-bar fill color override; nil uses system blue |

**Theming**: UI::ChartView does not directly reference UI::Theme tokens. Label colors
use NSColor.labelColor / UIColor.labelColor (macOS/iOS) and
NSColor.secondaryLabelColor / UIColor.secondaryLabelColor for category labels.
Bar fills use system blue RGBA (0.0/0.478/1.0) by default via CALayer.backgroundColor.
See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS:** The AppKit renderer reads `ENV["HIG_APPEARANCE"]` at render time to bake
the appropriate background colors. In light mode, the plot area fill is ~0.97 RGB
(subtle off-white). In dark mode, the plot area fill is ~0.16 RGB (dark charcoal).
Window background is baked to ~0.12 RGB in dark, 1.0 in light, matching the DarkAqua
NSVisualEffectView window. Title and category labels use baked RGBA values keyed off
`HIG_APPEARANCE`: ~0.92 RGB (near-white) in dark, ~0.08 RGB (near-black) in light.
Bar fills use dark-adjusted blue (0.039/0.518/1.0) in dark mode, standard blue
(0.0/0.478/1.0) in light -- both are clearly distinguishable from the respective
plot area backgrounds. Baseline separator uses ~0.3 RGB in dark (visible on dark plot),
~0.85 RGB in light.

**iOS:** The UIKit renderer avoids `ENV[]` access entirely (calling `ENV[]?` from inside
a UIStackView layout callback crashes Crystal's thread initializer when called from
SwiftUI's layout pass). Instead, title and category labels use UIColor.labelColor and
UIColor.secondaryLabelColor respectively -- these are appearance-tracking semantic
colors that automatically render near-black in light mode and near-white in dark mode
without any explicit dark-mode branching. Bar fills use a baked RGBA (0.0/0.478/1.0) for
both appearances because CALayer.backgroundColor requires a CGColorRef from a static
color; in dark mode the light-mode blue still reads as blue and is legible against the
~0.94 plot area. Plot area background uses a baked ~0.94 RGB fill for both appearances.

**SF Symbols:** UI::ChartView does not use SF Symbols. Data encoding is position and
height only.

**Contrast caveats:** Brand overrides that darken bar fill below the luminance of the
plot area background risk making bars invisible in dark mode. Always verify overridden
fill colors against both plot area backgrounds (~0.97 light, ~0.94 or transparent dark).

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap bar fill to your brand primary.**
```crystal
# Per-bar brand color via ChartDataPoint.color.
chart.data_points = [
  UI::ChartDataPoint.new(label: "Mon", value: 6200.0,
    color: UI::Color.new(r: 0.6, g: 0.0, b: 0.8, a: 1.0)),  # brand purple
  UI::ChartDataPoint.new(label: "Tue", value: 8400.0,
    color: UI::Color.new(r: 0.6, g: 0.0, b: 0.8, a: 1.0)),
  # ... remaining days
]
# Keep: HIG-default proportional heights, rounded tops, baseline separator,
# category labels, accessibility label. Only bar fill changes.
```

**Remove the title to maximize plot area density.**
```crystal
chart.title = ""  # omit title label
# HIG: "In a compact environment, maximize the width of the plot area."
# Dropping the title gives the bars more vertical space in a compact widget.
# Ensure accessibility_label still describes the chart purpose.
chart.accessibility_label = "Steps this week, Mon through Sun"
```

**Override typography while keeping HIG spacing.**
```crystal
# UI::ChartView does not expose a font knob directly. To substitute a brand
# font for chart labels, subclass UI::ChartView and override the NSTextField
# font call in a custom AppKit renderer subclass:
#
#   class BrandChartRenderer < UI::AppKit::Renderer
#     def visit(view : UI::ChartView)
#       # call super, then patch fonts on label subviews
#       super
#     end
#   end
#
# HIG: "Customize a slider's appearance if it adds value." The same principle
# applies -- only override typography when your brand font is meaningful to
# the chart context, never just for decorative reasons.
# The HIG-mandated spacing (8pt bar gap, 10pt labels) should not change.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a weekly step-count bar chart with a custom accent color"**
-> Set `chart_type = :bar`, supply 7 `ChartDataPoint` records with Mon-Sun labels
   and step counts as values. Set each data point's `color` to your brand accent
   `UI::Color`. Set `accessibility_label` describing the chart period and metric.

**"I want a trend line for a stock price over 6 months"**
-> Set `chart_type = :line`, supply 6 `ChartDataPoint` records with month
   abbreviations as labels and closing prices as values. The line renderer draws
   dots at each value position with stems to the baseline, suggesting trend direction.
   For production, replace with a native Swift Charts `LineMark` via UIViewRepresentable.

## What happens on each platform
- **iOS 26**: UIStackView-based bar chart (UIStackView horizontal with column UIStackViews).
  UIColor.labelColor / UIColor.secondaryLabelColor for labels (appearance-tracking).
  CALayer.backgroundColor for bar fills (baked RGBA; use `color` per-data-point for
  brand overrides). Chart is a flat surface -- no UIBlurEffect or UIGlassEffect.
- **iPadOS 26**: Same UIKit renderer as iOS. The chart_w = 340pt fits comfortably on
  iPad's wider viewport without clipping. Category labels and baseline visible.
- **macOS 26**: NSStackView-based bar chart. NSTextField labels with baked RGBA colors
  keyed off HIG_APPEARANCE env var. NSView CALayer bars in system blue. Flat surface --
  no NSVisualEffectView. Plot area ~344x188pt with 8pt rounded corners.

## HIG citations (validated)
- Charts -> Marks: "Bar marks work well in charts that help people compare values in
  different categories or view the relative proportions of various parts in a whole.
  When used to help people understand data that changes over time, bar charts work
  especially well when each value can represent a sum."
- Charts -> Best practices: "Establish a consistent visual hierarchy that helps
  communicate the relative importance of various chart elements. Typically, you want
  the data itself to be most prominent, while letting the descriptions and axes provide
  additional context without competing with the data."
- Charts -> Best practices: "Make every chart in your app accessible. Charts -- like
  all infographics -- need to be fully accessible to everyone, regardless of how they
  perceive content."
- Charts -> Descriptive content: "Write descriptions that help people understand what
  a chart does before they view it."
- Charts -> Best practices: "In a compact environment, maximize the width of the plot
  area to give people enough space to comfortably examine a chart."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/charts.md](../validation/reports/charts.md)

## Related
- `UI::GlassBackground` -- when you need a glass-surfaced container around a chart in
  a presentation context (e.g., a chart inside a popover or sheet)
- `UI::Card` -- when you need a grouped box container for the chart with standard
  card chrome (border, shadow, corner radius)
- `recipes/data-overview.md` -- multi-component pattern composing a chart with a
  summary label and navigation link to a detail view
