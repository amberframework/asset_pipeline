---
slug: rating-indicators
ui_view: UI::RatingIndicator
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/rating-indicators.md
validation_report: ../validation/reports/rating-indicators.md
---

# UI::RatingIndicator

> A horizontal row of star SF Symbols communicating a ranking level: on
> macOS 26 the renderer uses NSImageView + SF Symbol "star.fill" / "star"
> glyphs in NSStackView (composites correctly in the validation snapshot
> path; live apps should use NSLevelIndicator with
> NSLevelIndicatorStyleRating for click-to-rate interactivity); on iOS 26
> the renderer synthesises a UIStackView of UIImageViews carrying the
> same SF Symbol names, tinted with the resolved tint color.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A rating indicator lets a user read or set a ranking at a glance. It
sits at the intersection of data display and micro-interaction: the row
of stars encodes a value on a fixed scale (usually 1-5) without
requiring a number to be read. Use it in list rows for App Store-style
review scores, Music album ratings, or any discrete ranking that fits
on a 1-N scale.

A rating indicator is NOT a progress indicator, a slider, or a level
meter. It communicates a categorical ranking, not a continuous
percentage, and it rounds fractional values to whole stars per HIG.
When you need continuous feedback, use `UI::Slider`.

(HIG: "Make it easy to change rankings. When presenting a list of
ranked items, let people adjust the rank of individual items inline
without navigating to a separate editing screen." -- Rating indicators /
Best practices.)

## Quickstart

```crystal
# Default: 3 of 5 yellow stars, accessibility label auto-generated.
rating = UI::RatingIndicator.new(value: 3.0, max: 5)
rating.accessibility_label = "3 out of 5 stars"

# Full 5-star rating
full = UI::RatingIndicator.new(value: 5.0, max: 5)
full.accessibility_label = "5 out of 5 stars"

# Custom tint (blue)
blue_rating = UI::RatingIndicator.new(
  value: 3.0,
  max: 5,
  tint_color: UI::Color.new(r: 0.0, g: 0.48, b: 1.0)
)
blue_rating.accessibility_label = "3 out of 5 stars"
```

Renders: on macOS, a horizontal NSStackView of NSImageView instances
carrying SF Symbol "star.fill" (filled positions) and "star" (empty
positions), tinted with `contentTintColor`. On iOS, a horizontal
UIStackView of UIImageView instances carrying the same SF Symbol names,
tinted with `setTintColor:`. The rendered shape matches
NSLevelIndicator(style=rating) exactly: equally-spaced stars, same
size, same tint, same filled/outlined distinction.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `value` | `Float64` | `0.0` | Current rating. Clamped to 0..max and rounded to nearest integer at render time per HIG. |
| `max` | `Int32` | `5` | Total number of stars. Drives both the scale upper bound and the number of glyph positions rendered. |
| `tint_color` | `Color?` | `nil` | Tint for all star glyphs. `nil` resolves to system yellow (R:1.0 G:0.8 B:0.0) matching App Store / Music conventions. |
| `accessibility_label` | `String?` | auto | Override the VoiceOver announcement. When nil the renderer produces "X out of Y stars" automatically. |

**Theming**: No `UI::Theme` tokens are consumed by this component. The
tint color is set directly via `tint_color`. See
`foundations/color-and-theming.md` for token conventions.

## Light / dark appearance notes

The star glyphs are SF Symbols ("star.fill" and "star") drawn via
NSImageView.contentTintColor (macOS) and UIImageView.tintColor (iOS).
Both APIs produce appearance-tracked tinting when the color is a
semantic system color. When `tint_color` is nil, the renderer provides
a fixed RGBA yellow (R:1.0 G:0.8 B:0.0 alpha:1.0). This color reads
as gold on white (light) and gold-on-black (dark) with approximately
5:1 contrast in dark mode -- above the 4.5:1 WCAG body-text threshold.

The outlined "star" glyph in dark mode shows a yellow stroke on a
near-black background (~4:1 contrast) -- the outline is legible and
clearly distinct from the filled glyph. No contrast degradation occurs
between light and dark appearances.

The label text above each row (rendered by the host as UI::Label) uses
NSColor.labelColor / UIColor.label, which tracks the system appearance
automatically: near-black (~21:1) on light, near-white (~21:1) on dark.

SF Symbol variants used:
- Filled positions: "star.fill" (monochrome, hierarchical rendering
  with the tint color as the primary layer).
- Empty positions: "star" (outline variant, tinted with the same color
  -- the outline tracks the tint while the interior remains transparent,
  revealing the host background).

If a brand override sets `tint_color` to a low-saturation light gray
on a white background, legibility will degrade on macOS light
appearance. Prefer colors with at least 3:1 contrast against the host
background in both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Replace the system-yellow default with a brand coral color.
# Hit targets (star size 20-28pt), spacing (4pt gap), and
# accessibility label are all preserved; only the fill hue changes.
ri = UI::RatingIndicator.new(value: 4.0, max: 5)
ri.tint_color = UI::Color.new(r: 1.0, g: 0.35, b: 0.27)  # brand coral
ri.accessibility_label = "4 out of 5 stars"
```
Keep: HIG-mandated rounded star shape (SF Symbol), equal spacing,
integer-only rendering. Change: hue only. Ensure the chosen color
has at least 3:1 contrast against the host background in both light
and dark appearances.

**Replace the glass material with a flat brand surface.**
```crystal
# Rating indicators are not surface components and carry no glass
# material to replace. If you embed a RatingIndicator inside a
# UI::Card or UI::Sheet with a custom background, ensure the star
# tint color contrasts against the card/sheet surface, not just
# the host window background.
card = UI::Card.new
card.background = UI::Color.new(r: 0.1, g: 0.1, b: 0.15)  # dark brand card
ri = UI::RatingIndicator.new(value: 3.0, max: 5)
# Default yellow (R:1.0 G:0.8 B:0.0) on dark brand card: ~5:1. OK.
card << ri
```

**Override typography while keeping HIG spacing.**
```crystal
# Rating indicators carry no typography of their own. Override the
# companion label (the human-readable context string) via UI::Label
# while keeping HIG spacing between label and star row.
outer = UI::VStack.new(spacing: 8.0)   # 8pt gap between label and stars
lbl = UI::Label.new("Overall quality:")
lbl.font = UI::Font.new(family: "BrandSans", size: 13.0, weight: :medium)
ri = UI::RatingIndicator.new(value: 4.0, max: 5)
ri.accessibility_label = "4 out of 5 stars, overall quality"
outer << lbl
outer << ri
```

## Feel recipes
Short examples that map design intent to code.

**"I want an inline editable star rating in a list row"**
-- Set `value` from the model, provide an `on_change` callback (not
yet a first-class knob; wrap in UI::HStack with tap gesture on each
star position), set `accessibility_label` to describe the row context.
Reference HIG: "let people adjust the rank of individual items inline."

**"I want a 10-star scale instead of 5"**
```crystal
ri = UI::RatingIndicator.new(value: 7.0, max: 10)
ri.accessibility_label = "7 out of 10 stars"
```
Increasing `max` beyond 5 widens the star row. On narrow layouts
(iPhone portrait) consider `max: 5` with a 0.0-5.0 scale.

## What happens on each platform
- **iOS 26**: UIStackView of UIImageViews, SF Symbol "star.fill" /
  "star", tinted via UIImageView.tintColor. 28pt per star, 4pt
  spacing. No NSLevelIndicator equivalent on iOS (HIG: "Not
  supported in iOS, iPadOS, tvOS, visionOS, or watchOS.").
- **iPadOS 26**: Same as iOS 26. NSLevelIndicator is macOS-only.
- **macOS 26**: NSStackView of NSImageViews, SF Symbol "star.fill" /
  "star", tinted via NSImageView.contentTintColor. 20pt per star,
  4pt spacing. Live apps should use NSLevelIndicator with
  NSLevelIndicatorStyleRating (constant 4) for click-to-rate
  interactivity; the validation renderer uses NSImageView for
  correct static snapshot compositing.

## HIG citations (validated)
- Rating indicators -- abstract: "A rating indicator uses a series
  of horizontally arranged graphical symbols -- by default, stars --
  to communicate a ranking level."
- Rating indicators -- abstract: "A rating indicator doesn't display
  partial symbols; it rounds the value to display complete symbols
  only. Within a rating indicator, symbols are always the same
  distance apart and don't expand or shrink to fit the component's
  width."
- Rating indicators -- Best practices: "Make it easy to change
  rankings. When presenting a list of ranked items, let people adjust
  the rank of individual items inline without navigating to a separate
  editing screen."
- Rating indicators -- Best practices: "If you replace the star with
  a custom symbol, make sure that its purpose is clear. The star is a
  very recognizable ranking symbol, and people may not associate other
  symbols with a rating scale."
- Rating indicators -- Platform considerations: "Not supported in
  iOS, iPadOS, tvOS, visionOS, or watchOS."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/rating-indicators.md](../validation/reports/rating-indicators.md)

## Related
- `UI::Slider` -- use when you need continuous input on a bounded
  range rather than a discrete star scale.
- `UI::ProgressView` -- use when communicating task completion
  percentage, not a user-assigned ranking.
- `recipes/review-list.md` -- multi-row pattern combining
  UI::RatingIndicator with UI::Label and UI::ListView for App
  Store-style review displays.
