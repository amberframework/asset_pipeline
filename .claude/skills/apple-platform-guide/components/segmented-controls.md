---
slug: segmented-controls
ui_view: UI::SegmentedControl
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/segmented-controls.md
validation_report: ../validation/reports/segmented-controls.md
---

# UI::SegmentedControl

> A linear group of two or more mutually-exclusive segments rendered as a
> pill-shaped NSSegmentedControl (macOS) or UISegmentedControl (iOS/iPadOS)
> by default with no Liquid Glass material -- the selected segment is
> distinguished by a filled rounded-rect capsule in the platform accent color
> (macOS) or a white/gray capsule within a secondary-fill pill (iOS 26).

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A segmented control groups a small, fixed set of mutually-exclusive choices
that affect the content displayed directly below or beside it. Reach for it
when you want users to switch between two to five closely-related views or
filter states in a toolbar or inspector -- for example, a calendar
(Day / Week / Month) or a list / grid toggle. Unlike a tab bar, a segmented
control lives inside the content area and is appropriate for view-switching
within a single screen or pane.

Do not use a segmented control to perform actions (use a toolbar button group
instead); do not use it when the option set exceeds five to seven items (use
a picker or pop-up button instead); do not mix text and image segments in a
single control.

(HIG: "Use a segmented control to provide closely related choices that affect
an object, state, or view." -- Segmented controls / Best practices.)

## Quickstart

```crystal
# Text-only: 3 segments, "Week" selected (index 1)
seg = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
seg.accessibility_label = "Time range selector"

# With change handler
seg_handler = UI::SegmentedControl.new(["Day", "Week", "Month"], 1) do |idx|
  puts "Selected index: #{idx}"
end
seg_handler.accessibility_label = "Time range selector with callback"
```

Renders: NSSegmentedControl (macOS) with a system-blue selected-segment capsule
in both light and dark; UISegmentedControl (iOS/iPadOS) with a white-capsule /
gray-capsule selected state inside a secondarySystemFill pill. No Liquid Glass
material -- segmented controls are input controls, not surface overlays.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `segments` | `Array(String)` | `[]` | The ordered list of segment labels. HIG recommends 2-5 items on iPhone, 2-7 on iPad/Mac. |
| `selected_index` | `Int32` | `0` | Zero-based index of the pre-selected segment. |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Called with the new selected index whenever the user taps a different segment. |
| `accessibility_label` | `String` | `""` | VoiceOver label for the entire control. Required for interactive elements (HIG Accessibility). |

**Theming**: `UI::SegmentedControl` inherits the system accent color for the
selected-segment fill on macOS (NSColor.controlAccentColor). On iOS, the
selected-segment color tracks UIColor.label / UIColor.systemBackground per
the platform's segmented-control system appearance. No explicit theme-token
overrides are available in the current implementation; brand color can be
applied via `tintColor` on UISegmentedControl through a post-render UIKit
hook if needed. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSSegmentedControl renders on NSColor.windowBackgroundColor
(~1.0 RGB white). Selected segment: NSColor.controlAccentColor fill (system
blue, ~0.0/0.478/1.0 RGB) with NSColor.alternateSelectedControlTextColor label
(~1.0 RGB white) -- contrast ~6.5:1. Unselected segments: NSColor.labelColor
(~0.0 RGB) against the control's light-gray base -- contrast ~5.5:1. Segment
separators: NSColor.separatorColor 1pt vertical lines. Outer pill: ~6pt corner
radius matching NSSegmentedControl default.

**macOS dark:** DarkAqua appearance. NSColor.controlAccentColor remains system
blue (tracks the system accent in DarkAqua by default). Selected label:
NSColor.alternateSelectedControlTextColor dark (~1.0 RGB) -- contrast ~6.5:1
against blue. Unselected labels: NSColor.labelColor dark (~1.0 RGB) against the
control's dark-material segment base -- contrast ~17:1. Typography weight is
unchanged -- NSSegmentedControl does not auto-thin in dark mode.

**iOS/iPadOS light:** UISegmentedControl pill: UIColor.secondarySystemFill
(~0.95 gray fill). Selected segment: white rounded-rect capsule within the pill.
Selected label: UIColor.label (~0.0 RGB) against white -- contrast ~21:1.
Unselected labels: UIColor.label (~0.0 RGB) against the gray pill -- contrast
~5.5:1. Height: 32pt (UISegmentedControl intrinsic height).

**iOS/iPadOS dark:** Pill: UIColor.secondarySystemFill dark (~0.11 RGB).
Selected segment: UIColor.tertiarySystemFill dark (~0.18 RGB) capsule -- shape
delineation rather than high-contrast color, which is the HIG-correct dark-mode
UISegmentedControl behavior. Selected label: UIColor.label dark (~1.0 RGB)
against ~0.18 RGB -- contrast ~16:1. Unselected labels: UIColor.label dark
(~1.0 RGB) against pill dark background (~0.11 RGB) -- contrast ~14:1. Both
states legible.

SF Symbols: `UI::SegmentedControl` passes `segments` as string titles via
`setLabel:forSegment:` / `insertSegmentWithTitle:atIndex:animated:`. Actual
SF Symbol image segments (via `setImage:forSegment:` / `UIImage.systemImageNamed:`)
are not yet implemented -- planned as `segment_images : Array(String)?`. For
icon-only controls, use SF Symbol name strings as text labels as a fallback
until that property is available.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary (macOS only, via system accent).**
```crystal
# NSSegmentedControl inherits the system accent color. To use a brand color
# for the selected segment, apply tintColor post-render via the native handle.
# The segments, hit targets, and pill shape remain HIG-correct.
seg = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
seg.accessibility_label = "Time range selector"
# Brand-accent override is applied at the AppKit layer outside UI::View:
#   [nsSegmentedControlPtr setSelectedSegmentBezelColor: brandNSColor]
# This keeps HIG spacing (equal-width segments) and typography (system font).
```

**Replace the glass material with a flat brand surface (not applicable here).**
```crystal
# Segmented controls do not use a Liquid Glass material. The "surface" is the
# platform-native pill background (NSColor.controlBackgroundColor on macOS,
# UIColor.secondarySystemFill on iOS). To use a custom flat color instead,
# set the control's layer.backgroundColor via a post-render native hook.
# Warning: overriding the system material removes appearance-adaptive tracking
# (the control will no longer automatically adjust for dark mode unless you
# also set a dark-mode color variant). Prefer keeping the system default.
seg = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
seg.accessibility_label = "Time range selector"
# Custom background is a native-layer concern; the UI::View API does not
# expose a surface_style knob for this component in the current release.
```

**Override typography while keeping HIG spacing.**
```crystal
# UI::SegmentedControl does not expose a font property. NSSegmentedControl
# and UISegmentedControl use the system font at the platform-default size
# (~13pt on macOS, ~13pt on iOS). To use a brand font, apply it via the
# native layer after the view is rendered:
#   [nsSegCtrlPtr setFont: [NSFont fontWithName:@"BrandFont-Regular" size:13]]
# Keep the platform-default point size (13pt) to preserve HIG-recommended
# legibility and segment-width balance. Changing the font size affects
# intrinsic segment width calculations.
seg = UI::SegmentedControl.new(["Day", "Week", "Month"], 1)
seg.accessibility_label = "Time range selector"
# Custom font is applied post-render via the ObjC bridge or SwiftUI overlay.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a compact view/filter toggle (list vs grid) with 2 options."**
```crystal
toggle = UI::SegmentedControl.new(["List", "Grid"], 0) do |idx|
  show_list = idx == 0
end
toggle.accessibility_label = "Layout toggle"
```
HIG: "Keep control types consistent within a single segmented control."

**"I want a time-range picker (Day/Week/Month) with Week pre-selected."**
```crystal
range_picker = UI::SegmentedControl.new(["Day", "Week", "Month"], 1) do |idx|
  reload_chart(range: [:day, :week, :month][idx])
end
range_picker.accessibility_label = "Chart time range"
```
HIG: "Consider a segmented control to switch between closely related subviews."

## What happens on each platform
- **iOS 26**: UISegmentedControl with a pill-shaped container in
  UIColor.secondarySystemFill and a white/gray selected-segment capsule.
  No Liquid Glass material. Height: 32pt intrinsic. `UIControlEventValueChanged`
  triggers the `on_change` callback via `CrystalActionDispatcher`.
- **iPadOS 26**: Same as iOS 26. Segmented control width adapts to the wider
  iPad viewport; the host should constrain it to the desired width or let
  Auto Layout distribute it within a toolbar.
- **macOS 26**: NSSegmentedControl with equal-width segments, a system-blue
  selected-segment fill via NSColor.controlAccentColor, and NSColor.labelColor
  unselected labels. Segment target tracking: `NSSegmentedControl.trackingMode`
  defaults to `.selectOne` (mutually exclusive). Change callbacks use
  `CrystalActionDispatcher` with `NSSegmentedControl.target/action`.

## HIG citations (validated)
- Segmented controls -- Best practices: "Use a segmented control to provide
  closely related choices that affect an object, state, or view."
- Segmented controls -- Best practices: "Limit the number of segments in a
  control. Too many segments can be hard to parse and time-consuming to navigate.
  Aim for no more than about five to seven segments in a wide interface and no
  more than about five segments on iPhone."
- Segmented controls -- Content: "Prefer using either text or images -- not a
  mix of both -- in a single segmented control."
- Segmented controls -- Content: "Use nouns or noun phrases for segment labels.
  Write text that describes each segment and uses title-style capitalization."
- Segmented controls -- Platform considerations -- iOS, iPadOS: "Consider a
  segmented control to switch between closely related subviews. A segmented
  control can be useful as a way to quickly switch between related subviews."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/segmented-controls.md](../validation/reports/segmented-controls.md)

## Related
- `UI::Picker` -- when the option set exceeds 5-7 items or requires a wheel /
  inline-list presentation
- `UI::TabView` -- when switching between completely separate sections of an app
  (HIG: "Use a tab view in the main window area -- instead of a segmented control
  -- for view switching")
- `UI::ToggleButton` -- for a single binary state (not a mutually-exclusive group)
