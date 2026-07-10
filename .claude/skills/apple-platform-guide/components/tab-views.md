---
slug: tab-views
ui_view: UI::TabView
priority: P0
platforms: [macOS]
hig_page: ../../../apple-hig/pages/tab-views.md
validation_report: ../validation/reports/tab-views.md
---

# UI::TabView (tab-views pattern)

> A tab view presents multiple mutually exclusive content panes in the same window area,
> switched by a text-label tab strip at the top edge of the pane; on macOS it maps to
> NSTabView wrapped in NSVisualEffectMaterialMenu (10) glass for appearance-tracking;
> iOS and iPadOS do not support this pattern -- use UI::SegmentedControl there instead.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Use a tab view to partition closely related settings, options, or data into named sections
within a single window area. The top-mounted tab strip signals enclosure: users understand
that each tab reveals content that is conceptually parallel to the others. A tab view is
not for navigation between unrelated screens -- that is UI::TabView with `bar_position: :bottom`
on iOS (the tab-bars pattern). Tab views are macOS-primary: the HIG explicitly excludes them
from iOS, iPadOS, tvOS, and visionOS.

Keep each pane fully self-contained. Controls inside a pane should affect only that pane's
content; cross-pane side effects confuse users and violate the mutual-exclusivity contract.

(HIG: "Make sure the controls within a pane affect content only in the same pane. Panes are
mutually exclusive, so ensure they're fully self-contained." -- Tab views / Best practices.)

## Quickstart

```crystal
general_content = UI::VStack.new(spacing: 12.0)
general_heading = UI::Label.new("General")
general_heading.font = UI::Font.new(size: 15.0, weight: :semibold)
general_heading.accessibility_label = "General settings heading"
general_row = UI::Label.new("Language & Region: English (US)")
general_row.font = UI::Font.new(size: 13.0, weight: :regular)
general_row.text_color_role = UI::LabelRole::Secondary
general_content << general_heading
general_content << general_row

tabs = [
  UI::TabView::Tab.new(label: "General",       content: general_content.as(UI::View)),
  UI::TabView::Tab.new(label: "Advanced",      content: UI::Label.new("Advanced settings").as(UI::View)),
  UI::TabView::Tab.new(label: "Accessibility", content: UI::Label.new("Accessibility options").as(UI::View)),
  UI::TabView::Tab.new(label: "Updates",       content: UI::Label.new("Software updates").as(UI::View)),
]

tab_view = UI::TabView.new(tabs, 0)   # index 0 = "General" selected
tab_view.bar_position = :top          # macOS tab-views HIG pattern
tab_view.glass_bar = true             # NSVisualEffectMaterialMenu wraps the component
tab_view.accessibility_label = "Tab view navigation"
```

Renders: on macOS, a NSVisualEffectMaterialMenu (10) glass root containing a top-mounted
horizontal NSStackView of text-label tab cells, an NSBox separator, and a content pane
NSStackView below; the selected tab is tinted system blue via NSColor.controlAccentColor
and unselected tabs use NSColor.secondaryLabelColor. On iOS (where NSTabView is not
supported) the renderer falls back to the UIGlassEffect-backed UITabBar-style layout used
by the tab-bars pattern.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `tabs` | `Array(Tab)` | `[]` | The ordered list of tabs; each `Tab` carries `label`, optional `icon`, and `content`. |
| `selected_index` | `Int32` | `0` | Zero-based index of the active tab; the corresponding `content` is displayed. |
| `bar_position` | `Symbol` | `:bottom` | `:top` for macOS tab-views (tab strip above content); `:bottom` for iOS tab-bars style. |
| `glass_bar` | `Bool` | `true` | When true, wraps the component in NSVisualEffectMaterialMenu (macOS) or UIGlassEffect (iOS) glass. Set false for a plain opaque bar (brand override). |
| `selected_tint_color` | `Color?` | `nil` | Tint applied to the selected tab label and icon. Nil resolves to system accent (NSColor.controlAccentColor on macOS, UIColor.systemBlueColor on iOS). |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Callback invoked with the new index when the user selects a different tab. |

**Theming**: selected tab tint reads `UI::Theme.apple_default.primary` (default 0.0/0.478/1.0
= system blue). Unselected tabs use NSColor.secondaryLabelColor / UIColor.secondaryLabelColor,
which tracks the system appearance automatically. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light (Aqua):** NSVisualEffectMaterialMenu (10) resolves to a frosted translucent
light-gray surface ~0.91 RGB over white. The glass surface is clearly distinguishable from
the window background (~1.0 RGB). The selected tab uses NSColor.controlAccentColor in Aqua
appearance, which defaults to system blue 0.0/0.478/1.0. Unselected tabs use
NSColor.secondaryLabelColor Aqua ~0.50 RGB (mid-gray). Tab labels are 13pt NSTextField
(Regular weight). Content pane is rendered at ~1.0 RGB (white), providing high contrast for
any content placed inside.

**macOS dark (DarkAqua):** NSVisualEffectMaterialMenu (10) in DarkAqua resolves to a frosted
dark surface ~0.22 RGB, distinguishable from the near-black window background (~0.09 RGB).
NSColor.controlAccentColor in DarkAqua retains the blue hue (~0.0/0.478/1.0 base, may shift
to ~0.039/0.518/1.0 for dark-background contrast). Unselected tabs use
NSColor.secondaryLabelColor DarkAqua ~0.60 RGB -- light gray on dark glass, legible. Tab
label font weight is preserved in dark mode (Regular 13pt, no auto-thin). Content pane in
DarkAqua resolves to a dark surface ~0.18 RGB; embed content with NSColor.labelColor or
NSColor.secondaryLabelColor for automatic contrast tracking.

**iOS (fallback -- not HIG-supported):** On iOS the UIKit renderer uses UIGlassEffect (iOS 26)
or UIBlurEffectStyleSystemChromeMaterial (= 11) as a fallback. Light appearance: frosted
~0.96 RGB on white. Dark appearance: dark glass ~0.18 RGB on black. Selected tab uses
UIColor.systemBlueColor (light: 0.0/0.478/1.0; dark: ~0.25/0.56/1.0 adjusted for dark-bg
contrast). Tab labels are 10pt UILabel at bottom position. iOS developers should use
UI::SegmentedControl instead of UI::TabView for top-switch patterns on iPhone and iPad.

**SF Symbol usage:** The `tab-views` HIG pattern is text-only (no icons) per NSTabView
convention. Icons are optional via the `icon` field on `Tab`; if provided they are rendered
above the label using NSImageView/UIImageView with SF Symbol outline glyphs. When using icons
on macOS consider appending ".fill" to the symbol name for filled glyphs, which are more
legible at the smaller tab strip size.

**Contrast caveats:** If you override `selected_tint_color` to a low-contrast color (e.g.
a mid-gray brand accent), the selected tab label may not be distinguishable from unselected
tabs in either appearance. Keep selected tint at >= 3:1 contrast against the glass surface
in both Aqua and DarkAqua. The default system blue passes this threshold in both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override the selected-tab tint to a brand color while keeping HIG structure intact.
# Hit targets, spacing (16pt edge insets, 13pt labels), and separator remain HIG-default.
tab_view.selected_tint_color = UI::Color.new(r: 0.82, g: 0.12, b: 0.28)  # brand crimson
# Ensure your brand color has >= 3:1 contrast against the glass surface in both
# Aqua (~0.91 RGB) and DarkAqua (~0.22 RGB). System red passes; very dark/light accents may not.
```

**Replace the glass material with a flat brand surface.**
```crystal
# Disable the NSVisualEffectMaterialMenu glass wrap. The component renders with a plain
# NSView root (no translucency). You lose appearance-tracking through the glass layer;
# you must supply a background color that works in both light and dark.
tab_view.glass_bar = false
# Without glass, the tab strip background is the window background color. If you want
# a distinct brand-colored tab strip background, set it via the enclosing container's
# background -- the renderer does not expose a standalone tab-strip background knob.
# Warn: removing glass reduces visual richness and breaks the HIG frosted-surface promise.
```

**Override typography while keeping HIG spacing.**
```crystal
# There is no per-tab font knob on UI::TabView today -- the renderer hard-codes 13pt system
# font for bar_position: :top and 10pt for :bottom. To use a brand font, override the
# renderer directly (planned: UI::Theme font_family token will propagate here in a future
# iteration). In the interim, set UI::Theme.apple_default.font_family to your brand font
# name; the NSFont.systemFont calls in the renderer will continue to use the system font
# until the knob is wired. (planned)
```

## Feel recipes
Short examples that map design intent to code.

**"I want a System Preferences style settings panel with four tabs."**
Setting `bar_position: :top` produces the exact macOS tab-views shape: text-only tab strip
at top, separator, content pane below with 16pt edge insets.

**"I want to programmatically switch tabs without user input."**
Set `tab_view.selected_index = new_index` before passing the view to the renderer. There is
no animated transition in the static-render model; the renderer always shows the pane at
`selected_index`. For reactive tab switching, wire `on_change` to a server-side update
that re-renders the view tree with the new index.

## What happens on each platform
- **macOS 26**: NSVisualEffectView (NSVisualEffectMaterialMenu = 10) glass root, top
  horizontal NSStackView of NSTextField tab cells (13pt, Regular), NSBox separator,
  NSStackView content pane below. Selected tab NSColor.controlAccentColor; unselected
  NSColor.secondaryLabelColor. Both track Aqua/DarkAqua automatically.
- **iPadOS 26**: Not natively supported per HIG. Renderer falls back to UITabBar-style
  layout (same as iOS). Use UI::SegmentedControl for a top-switch pattern on iPad.
- **iOS 26**: Not natively supported per HIG ("Not supported in iOS, iPadOS, tvOS, or
  visionOS"). Renderer falls back to UIVisualEffectView + UIGlassEffect (or
  UIBlurEffectStyleSystemChromeMaterial = 11) bottom tab bar layout (tab-bars style).
  Use UI::SegmentedControl for inline section-switch patterns on iPhone.

## HIG citations (validated)
- Tab views -- Abstract: "A tab view presents multiple mutually exclusive panes of content
  in the same area, which people can switch between using a tabbed control."
- Tab views -- Anatomy: "The tabbed control appears on the top edge of the content area."
- Tab views -- Best practices: "Provide a label for each tab that describes the contents
  of its pane. A good label helps people predict the contents of a pane before clicking or
  tapping its tab. In general, use nouns or short noun phrases for tab labels."
- Tab views -- Best practices: "Avoid providing more than six tabs in a tab view. Having
  more than six tabs can be overwhelming and create layout issues."
- Tab views -- Platform considerations -- iOS, iPadOS: "Not supported in iOS, iPadOS, tvOS,
  or visionOS. For similar functionality, consider using a segmented control instead."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/tab-views.md](../validation/reports/tab-views.md)

## Related
- `UI::TabView` (tab-bars pattern) -- same class with `bar_position: :bottom`; the iOS-primary
  bottom navigation bar pattern with Liquid Glass surface and SF Symbol icons.
- `UI::SegmentedControl` -- the HIG-recommended iOS/iPadOS replacement for tab-views; renders
  as UISegmentedControl, appropriate for inline content-switching within a screen.
- `recipes/settings-panel.md` -- multi-pane settings window using tab-views + form rows.
