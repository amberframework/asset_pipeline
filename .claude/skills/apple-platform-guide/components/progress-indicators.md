---
slug: progress-indicators
ui_view: UI::ActivityIndicator / UI::ProgressView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/progress-indicators.md
validation_report: ../validation/reports/progress-indicators.md
---

# UI::ActivityIndicator / UI::ProgressView

> Progress indicators communicate that work is ongoing; `UI::ActivityIndicator`
> renders the indeterminate circular spinner (NSProgressIndicator spinning style /
> UIActivityIndicatorView) while `UI::ProgressView` renders the determinate or
> indeterminate horizontal bar (NSProgressIndicator bar style / UIProgressView),
> with no Liquid Glass material applied -- both are content-inline components that
> render directly into the host view without a translucent surface.

## Feel of the flow
_What these components "mean" in a UI, and when to reach for each._

Progress indicators are reassurance signals. They tell the user "the app is alive and
working" without asking for any interaction. Use `UI::ActivityIndicator` (spinner) for
background or asynchronous tasks where the duration is unknown and the available space
is small -- next to a button, inside a text field, or in a toolbar. Use `UI::ProgressView`
with a `value:` (0.0..1.0) for operations with a known completion fraction, such as a
file upload, download, or media conversion.

Do not use a progress indicator for tasks that complete in under a second -- the
flash of a spinner is more disorienting than a brief wait. Do not use an indeterminate
bar (`ProgressView(nil, .Linear)`) on iOS via UIProgressView; UIKit has no native
indeterminate bar animation -- use a spinner instead.

(HIG: "When possible, use a determinate progress indicator. An indeterminate progress
indicator shows that a process is occurring, but it doesn't help people estimate how
long a task will take." -- Progress indicators / Best practices.)

## Quickstart

```crystal
# Spinner -- indeterminate, medium size (HIG default for background tasks)
spinner = UI::ActivityIndicator.new(true, :medium)
spinner.accessibility_label = "Loading"

# Linear determinate bar at 60% with label and cancel affordance
progress_row = UI::VStack.new(spacing: 6.0)
bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
bar.accessibility_label = "Upload progress 60 percent"
lbl = UI::Label.new("Uploading... 60%")
lbl.font = UI::Font.new(size: 13.0, weight: :regular)
cancel_btn = UI::Button.new("Cancel")
cancel_btn.role = :cancel
cancel_btn.accessibility_label = "Cancel upload"
progress_row << lbl
progress_row << bar
progress_row << cancel_btn
```

Renders: `NSProgressIndicator` (spinning style) on macOS;
`UIActivityIndicatorView` on iOS. The determinate bar renders as
`NSProgressIndicator` (bar style, setDoubleValue: 0.6) on macOS and
`UIProgressView` (setProgress: 0.6) on iOS. No Liquid Glass material.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `is_animating` | `Bool` | `true` | Calls `startAnimation:` / `startAnimating` when true; `stopAnimation:` / `stopAnimating` when false. A stopped spinner is hidden on iOS (UIActivityIndicatorView default hidesWhenStopped). |
| `size` | `Symbol` | `:medium` | On iOS: medium = UIActivityIndicatorViewStyle.medium (~20pt), large = UIActivityIndicatorViewStyle.large (~37pt). On macOS: no effect -- NSProgressIndicator spinning style is fixed size. |
| `color` | `Color?` | `nil` | Overrides the spinner tint. On iOS: calls `setColor:` on UIActivityIndicatorView. On macOS: no effect (NSProgressIndicator uses system-controlled color). Nil uses the platform default (gray on light, white/gray on dark). |
| `value` | `Float64?` | `nil` | For `UI::ProgressView`. Nil = indeterminate. 0.0..1.0 = determinate. On macOS: `setIndeterminate:` / `setDoubleValue:`. On iOS: `UIProgressView.setProgress:animated:`. |
| `style` | `ProgressStyle` | `ProgressStyle::Linear` | For `UI::ProgressView`. `Linear` = bar; `Circular` = UIActivityIndicatorView on iOS / NSProgressIndicator spinning on macOS. |
| `tint_color` | `Color?` | `nil` | For `UI::ProgressView`. Overrides the fill color via `setProgressTintColor:` on iOS. On macOS: no effect (bar color tracks system accent). |
| `label` | `String` | `""` | For `UI::ProgressView`. Descriptive text stored on the view; not automatically rendered as a sibling label -- append a `UI::Label` to the parent stack manually. |

**Theming**: `UI::Theme.primary` (0.0/0.478/1.0 by default) is the source of the
blue tint used for the determinate bar fill on both platforms. Override it to change
the fill color without touching `tint_color` directly. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::ActivityIndicator` and `UI::ProgressView` rely entirely on system semantic colors
and do not reference any `UI::Theme` tokens directly in their renderer implementations.
This means they track the system appearance automatically without any extra code.

**macOS -- light appearance:**
`NSProgressIndicator` spinning style renders gray spokes (NSColor.secondaryLabelColor
values, approximately 0.0/0.0/0.0/0.5 alpha) against a white or window-chrome
background. The bar style fill tracks `NSColor.controlAccentColor` (system blue by
default, approximately 0.0/0.478/1.0). Track background is `NSColor.quaternaryLabelColor`
(light gray). No contrast failures at default system sizes.

**macOS -- dark appearance:**
`NSProgressIndicator` spinning style auto-inverts spoke color to near-white
(approximately 1.0/1.0/1.0/0.5 alpha) against a dark window background. This is
automatic and requires no renderer code. The bar fill tracks `NSColor.controlAccentColor`
dark-mode resolved value (approximately 0.039/0.518/1.0, slightly lighter for dark
background contrast). Track background is `NSColor.quaternaryLabelColor` dark
(approximately 0.25 RGB).

**iOS -- light appearance:**
`UIActivityIndicatorView` default color is `UIColor.systemGray` in light mode
(approximately 0.56/0.56/0.58). On a white background this gives ~3:1 contrast
-- acceptable for an animated indicator per WCAG large-element 3:1 threshold.
When a `color:` override is applied, ensure it meets 3:1 against the background.
`UIProgressView` fill color is `UIColor.tintColor` (system blue by default,
approximately 0.0/0.478/1.0). Track is `UIColor.systemFill` (~0.47/0.47/0.50 at
0.18 alpha, light gray).

**iOS -- dark appearance:**
`UIActivityIndicatorView` default color resolves to `UIColor.systemGray` dark
(approximately 0.56/0.56/0.58 -- system gray is context-adaptive; on dark background
it remains mid-gray, giving ~3.5:1 contrast). `UIProgressView` fill resolves to
system blue dark-mode adjusted (approximately 0.039/0.518/1.0). Track resolves to
`UIColor.systemFill` dark (approximately 0.47/0.47/0.50 at 0.36 alpha, darker fill).
All visible.

**SF Symbol usage:** Neither `UI::ActivityIndicator` nor `UI::ProgressView` uses
SF Symbols -- the indicator chrome is drawn by the native control without symbols.
If you want to annotate a spinner row with an icon (e.g., iCloud sync), use a
`UI::HStack` with an `UI::Image` (SF Symbol) followed by the spinner.

**Contrast caveat for brand overrides:** If you override `color:` on
`UI::ActivityIndicator` to a brand color, verify 3:1 contrast against the background
in BOTH appearances. A light-brand pastel that is legible in light may fall below
3:1 in dark mode if the background darkens more than the brand color.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the spinner tint to your brand primary (iOS only).**
```crystal
# On iOS, UIActivityIndicatorView.setColor: accepts any UIColor.
# Hit targets and animation behavior are unchanged.
# On macOS, NSProgressIndicator ignores the color override -- color tracks
# NSColor.controlAccentColor, which the user controls in System Preferences.
brand_spinner = UI::ActivityIndicator.new(true, :medium)
brand_spinner.color = UI::Color.new(r: 0.8, g: 0.2, b: 0.4, a: 1.0)
brand_spinner.accessibility_label = "Loading"
# Verify 3:1 contrast against host background in both light and dark.
```

**Swap the progress bar fill to your brand primary (iOS only).**
```crystal
# On iOS, UIProgressView.setProgressTintColor: overrides the blue fill.
# On macOS, the bar fill tracks NSColor.controlAccentColor -- override that
# system preference or accept the system default.
brand_bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
brand_bar.tint_color = UI::Color.new(r: 0.8, g: 0.2, b: 0.4, a: 1.0)
brand_bar.accessibility_label = "Upload progress 60 percent"
# The track color (UIProgressView.trackTintColor) remains system gray
# unless you also set it via a post-render view tweak.
```

**Pair a progress bar with a brand-font label (keeping HIG spacing).**
```crystal
# HIG: "If it's helpful, display a description that provides additional
# context for the task." -- Progress indicators / Best practices.
# Use a VStack with the system-default bar (unchanged) and a labeled row.
# Override only the font; preserve the 6pt spacing between label and bar.
upload_col = UI::VStack.new(spacing: 6.0)
bar = UI::ProgressView.new(0.6, UI::ProgressStyle::Linear)
bar.accessibility_label = "Upload progress 60 percent"
status_lbl = UI::Label.new("Uploading... 60%")
status_lbl.font = UI::Font.new(family: "YourBrandFont-Regular", size: 13.0, weight: :regular)
upload_col << status_lbl
upload_col << bar
# Keep size at 13pt (HIG caption/body scale) -- do not reduce below 11pt.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a spinner next to a button while an async request is in flight"**
-> Use `UI::HStack` with `UI::ActivityIndicator.new(true, :medium)` and the button.
-> Show the spinner by setting `is_animating = true`; hide by setting `is_animating = false`.
-> Keep `accessibility_label` on the spinner so VoiceOver announces "Loading".

**"I want a full-width determinate bar with a cancel affordance"**
-> Use `UI::VStack` with a `UI::Label` for the status string, a `UI::ProgressView`
   (full-width in a VStack takes the parent's width automatically), then a `UI::Button`
   with `role: :cancel` below.
-> Do NOT put the bar inside a `UI::HStack` with the label and button -- NSProgressIndicator
   collapses to circular style when its HStack width falls below ~60pt.

## What happens on each platform
- **iOS 26**: `UIActivityIndicatorView` (medium = 100, large = 101). `UIProgressView`
  for linear determinate. No Liquid Glass material. `startAnimating` / `stopAnimating`
  called per `is_animating`. Tint color applied via `setColor:` / `setProgressTintColor:`.
- **iPadOS 26**: Same as iOS 26. On larger screens, consider placing the progress row
  in a constrained-width container (~320pt) to avoid a bar stretching full tablet width.
- **macOS 26**: `NSProgressIndicator` for both spinner (style=spinning) and bar (style=bar).
  `startAnimation:` / `stopAnimation:` called per `is_animating`. Tint color override is
  ignored by macOS -- bar fill tracks `NSColor.controlAccentColor`. Spinner size knob
  has no effect -- NSProgressIndicator spinning is fixed-size (~20pt). Indeterminate bar
  uses `setIndeterminate: YES` + `startAnimation:` for the barber-pole animation.

## HIG citations (validated)
- Progress indicators -> Best practices: "When possible, use a determinate progress
  indicator. An indeterminate progress indicator shows that a process is occurring, but
  it doesn't help people estimate how long a task will take."
- Progress indicators -> Best practices: "Keep progress indicators moving so people know
  something is continuing to happen. People tend to associate a stationary indicator with
  a stalled process or a frozen app."
- Progress indicators -> Best practices: "If it's helpful, display a description that
  provides additional context for the task. Be accurate and succinct. Avoid vague terms
  like loading or authenticating because they seldom add value."
- Progress indicators -> Best practices: "When it's feasible, let people halt processing.
  If people can interrupt a process without causing negative side effects, include a
  Cancel button."
- Progress indicators -> macOS: "Prefer an activity indicator (spinner) to communicate
  the status of a background operation or when space is constrained. Spinners are small
  and unobtrusive, so they're useful for asynchronous background tasks, like retrieving
  messages from a server."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/progress-indicators.md](../validation/reports/progress-indicators.md)

## Related
- `UI::Button` -- pair a Cancel button (role: :cancel) alongside a ProgressView for
  the HIG-recommended halt affordance.
- `UI::GlassBackground` -- if you need to show a progress indicator on a glass surface
  (e.g., inside a sheet), embed `UI::ActivityIndicator` inside `UI::GlassBackground`
  with transparent background so the material shows through.
- `recipes/async-loading-row.md` -- multi-component pattern combining ActivityIndicator,
  Label, and Button for a typical async-fetch row.
