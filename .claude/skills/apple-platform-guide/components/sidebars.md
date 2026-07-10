---
slug: sidebars
ui_view: UI::NavigationSplitView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/sidebars.md
validation_report: ../validation/reports/sidebars.md
---

# UI::NavigationSplitView

> A sidebar is a leading-edge navigation column that floats above content in the
> Liquid Glass layer, giving people simultaneous access to multiple peer sections
> of an app's hierarchy; on macOS and iPadOS it renders as an NSVisualEffectView
> (NSVisualEffectMaterialSidebar) or UIVisualEffectView + UIGlassContainerEffect,
> while on iPhone it collapses to a NavigationStack root list.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A sidebar provides a persistent, flat-browsable map of your app's top-level
sections. It is the right choice when users need to switch frequently between
peer areas (like Mail's Inbox, Flagged, and Folders) without drilling deeper into
a hierarchy each time. It is NOT a replacement for a tab bar when your app has
four or fewer top-level areas and each area is relatively isolated. Prefer a tab
bar for simpler navigation; reach for `NavigationSplitView` when the section list
is long, customizable, or benefits from persistent visibility at the side of the
screen.

On iPhone, the sidebar collapses: the sidebar column becomes the root of a
NavigationStack, and tapping a row pushes the detail. On iPad, both the sidebar
and detail columns are visible simultaneously, which is the canonical use case.

(HIG: "A sidebar provides a broad, flat view of an app's information hierarchy,
giving people access to several peer content areas or modes at the same time." --
Sidebars / Abstract.)

## Quickstart

```crystal
# Sidebar column: Mail-style nav rows with SF Symbol icons.
sidebar = UI::VStack.new(spacing: 0.0)

mailboxes_hdr = UI::Label.new("MAILBOXES")
mailboxes_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
mailboxes_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
mailboxes_hdr.accessibility_label = "Mailboxes section header"
sidebar << mailboxes_hdr

inbox_row = UI::HStack.new(spacing: 8.0)
inbox_icon = UI::Image.new("envelope")           # SF Symbol
inbox_icon.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
inbox_icon.accessibility_label = "Envelope icon"
inbox_label = UI::Label.new("Inbox")
inbox_label.font = UI::Font.new(size: 14.0, weight: :regular)
inbox_label.accessibility_label = "Inbox"
inbox_badge = UI::Label.new("12")
inbox_badge.font = UI::Font.new(size: 12.0, weight: :semibold)
inbox_badge.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
inbox_badge.accessibility_label = "12 unread messages"
inbox_row << inbox_icon
inbox_row << inbox_label
inbox_row << UI::Spacer.new
inbox_row << inbox_badge
inbox_row.accessibility_label = "Inbox navigation row"
sidebar << inbox_row

sep = UI::Divider.new
sep.accessibility_label = "Section separator"
sidebar << sep

folders_hdr = UI::Label.new("FOLDERS")
folders_hdr.font = UI::Font.new(size: 11.0, weight: :semibold)
folders_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
folders_hdr.accessibility_label = "Folders section header"
sidebar << folders_hdr

work_row = UI::HStack.new(spacing: 8.0)
work_icon = UI::Image.new("folder")
work_icon.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
work_icon.accessibility_label = "Folder icon"
work_label = UI::Label.new("Work")
work_label.font = UI::Font.new(size: 14.0, weight: :regular)
work_label.accessibility_label = "Work folder"
work_row << work_icon
work_row << work_label
work_row.accessibility_label = "Work folder navigation row"
sidebar << work_row

# Detail area (rendered to the right of the sidebar on iPad / macOS).
detail = UI::Label.new("Inbox selected")
detail.font = UI::Font.new(size: 15.0, weight: :regular)
detail.text_color = UI::Color.new(r: 0.55, g: 0.55, b: 0.55)
detail.accessibility_label = "Detail area placeholder"

nsv = UI::NavigationSplitView.new(
  sidebar: sidebar,
  content: nil,
  detail: detail
)
nsv.sidebar_width = 200.0
nsv.shows_sidebar = true
nsv.accessibility_label = "Mail-style sidebar navigation"
```

Renders: on macOS as an NSView split container with an NSVisualEffectView sidebar
column (NSVisualEffectMaterialSidebar = 7, blendingMode = BehindWindow, tracks
appearance); on iOS 26 as a UIVisualEffectView + UIGlassContainerEffect sidebar
column (UIBlurEffect style=11 fallback on older SDKs); on iPhone the sidebar
column is the sole visible column (split collapses to NavigationStack root).

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `sidebar` | `UI::View?` | `nil` | The view tree rendered inside the Liquid Glass sidebar column. Typically a `UI::VStack` containing section headers, `UI::HStack` nav rows, and `UI::Divider` separators. |
| `content` | `UI::View?` | `nil` | Optional middle column in a 3-column split (e.g. a message list between the sidebar and the detail pane). Nil produces a 2-column layout. |
| `detail` | `UI::View?` | `nil` | The main content area to the right of the sidebar. On iPhone this renders below the sidebar list. |
| `sidebar_width` | `Float64` | `250.0` | Width of the sidebar column in points. HIG Mail-style is ~200pt; Finder uses ~220pt. Constrained via `objc_constrain_width` on macOS and iOS. |
| `shows_sidebar` | `Bool` | `true` | When false, the sidebar column is hidden and only the content/detail columns render. Use this for the "collapsed" state on narrow windows. |
| `column_visibility` | `Symbol` | `:all` | Controls which columns are visible: `:all`, `:double_column` (sidebar + detail), `:detail_only`. Maps to `NSSplitViewItem.isCollapsed` on macOS and `UISplitViewController.preferredDisplayMode` on iOS. |

**Theming**: The sidebar glass surface uses `NSVisualEffectMaterialSidebar` (macOS)
and `UIGlassContainerEffect` / `UIBlurEffect(style=11)` (iOS), which track the
system appearance automatically without any theme token. Section header text color
and row label color can be set directly on child `UI::Label` instances. Accent
color for SF Symbol icons is set via `tint_color` on `UI::Image`. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

On macOS, `NSVisualEffectMaterialSidebar` (material = 7) has two tracked fill
states: light (~0.91 RGB, frosted light gray) and dark (~0.21 RGB, frosted dark
gray). The transition is automatic and driven by `NSVisualEffectBlendingMode
BehindWindow` sampling the window backdrop. In the static validation capture the
fill color is the material's adaptive tracked color, not a live translucent sample
(known harness limitation, gaps.md iter-41). At runtime the true backdrop-blurred
translucency is visible.

On iOS, `UIGlassContainerEffect` (iOS 26) and `UIBlurEffect(style: systemChromeM
aterial = 11)` adapt the same way: light appearance gives a frosted near-white
panel; dark appearance gives a frosted near-black panel. The static capture shows
the fill color; live usage shows translucency.

Section header labels use `UI::Label.text_color = UI::Color(0.6, 0.6, 0.6)`. In
light mode this achieves ~4.5:1 contrast against the sidebar fill; in dark mode
~4.0:1 -- both above the WCAG 2.2 AA threshold for secondary text. If you override
the text color to a lighter gray (e.g. 0.7/0.7/0.7) in dark mode it may fall
below 3:1 -- use the secondary label role (`UI::Label.text_color_role = :secondary`)
to let the platform choose the correct adaptive color instead.

SF Symbol icons declared as `UI::Image.new("symbol-name")` now prefer
`systemImageNamed:` (iOS) and `imageWithSystemSymbolName:accessibilityDescription:`
(macOS) over bundle `imageNamed:`. On macOS, sidebar icons inherit the system
accent color via `NSImageView.contentTintColor`; setting `tint_color` explicitly
overrides it. HIG: "By default, sidebar icons use the current accent color and
people expect to see their chosen accent color throughout all the apps they use."
Overriding `tint_color` to a fixed brand color breaks this expectation on macOS
-- document this trade-off when doing a brand override.

The flag SF Symbol icon is set to orange (1.0/0.584/0.0) in the showcase as a
semantic override (Flagged = orange in Mail). This is distinguishable from system
blue in both light and dark appearances and does not cause contrast failure.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override tint_color on each SF Symbol UIImage to your brand primary.
# Do NOT change font sizes, row heights, or spacing -- HIG row height
# (~44pt on iOS, ~28pt macOS) and 8pt leading symbol spacing are mandatory.
inbox_icon.tint_color = UI::Color.new(r: 0.4, g: 0.2, b: 0.8)  # brand purple
# The sidebar glass material, typography, and spacing remain HIG-default.
# On macOS: HIG warns against specifying a fixed color for all icons, since
# users expect their chosen accent color to apply. Consider only overriding
# icons where semantic meaning (not accent) drives the color (e.g., flag=orange).
```

**Replace the glass material with a flat brand surface.**
```crystal
# There is no surface_style: :plain knob on NavigationSplitView today.
# To use a flat sidebar background instead of Liquid Glass, supply a plain
# UI::VStack or UI::ZStack as the sidebar: and set its background color:
flat_sidebar = UI::VStack.new(spacing: 0.0)
flat_sidebar.background = UI::Color.new(r: 0.12, g: 0.08, b: 0.22)  # brand dark
flat_sidebar << sidebar_rows  # your row views
nsv = UI::NavigationSplitView.new(sidebar: flat_sidebar, detail: detail_view)
# WARNING: this removes the NSVisualEffectMaterialSidebar Liquid Glass.
# The sidebar will no longer track the system appearance automatically.
# Ensure your flat background provides adequate contrast against label text
# in BOTH light (uncommon for a dark brand) and dark appearances.
```

**Override typography while keeping HIG spacing.**
```crystal
# Substitute a brand font for section headers and row labels while preserving
# the HIG row structure (8pt icon-to-label gap, 8pt insets, ~14pt body size).
# Use UI::Font.new(name: "BrandFont-Regular", size: 14.0) when a custom font
# is registered in the app bundle. HIG recommends no smaller than 11pt for
# section headers and no smaller than 14pt for row labels.
mailboxes_hdr.font = UI::Font.new(name: "BrandFont-Semibold", size: 11.0)
inbox_label.font = UI::Font.new(name: "BrandFont-Regular", size: 14.0)
# Row height is driven by UILabel / NSTextField intrinsicContentSize + the
# UIStackView / NSStackView spacing -- do not add explicit height constraints
# that would reduce tap targets below 44pt on iOS.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a Notes-style sidebar with pinned-to-top Folders and a Smart Folders
section."**
-> Add two `UI::VStack` groups, each preceded by a `UI::Label` section header
   (11pt semibold, `text_color_role = :secondary`) and separated by a
   `UI::Divider`. Set `sidebar_width = 220.0` for a slightly wider column.
   Use `shows_sidebar = true` and set `column_visibility = :all`.

**"I want to hide the sidebar when the window is narrow (Finder-style collapse)."**
-> Bind `shows_sidebar` to a `Bool` that you toggle when the window width drops
   below a threshold. Wire a toolbar button (`UI::Button` with SF Symbol
   "sidebar.left") to toggle `shows_sidebar` and call `renderer.render(split_view)`
   again. Set `column_visibility = :detail_only` when collapsed.

## What happens on each platform
- **iOS 26**: `UIView` split container with `UIVisualEffectView +
  UIGlassContainerEffect` sidebar column (UIBlurEffect style=11 fallback). On
  iPhone the split collapses and the sidebar column IS the visible view (root of
  the NavigationStack). The sidebar glass surface uses `setClipsToBounds: true`
  for clean edge rendering.
- **iPadOS 26**: Same UIKit path as iOS. Both columns visible in landscape.
  `sidebarAdaptable` tab view style can also provide a sidebar; use
  `NavigationSplitView` when you want sidebar-only (no tab bar conversion).
- **macOS 26**: `NSView` horizontal container with `NSVisualEffectView` sidebar
  column (NSVisualEffectMaterialSidebar = 7, blendingMode = BehindWindow,
  state = Active). Sidebar width constrained via `objc_constrain_width`. Sidebar
  content hosted in an inner `NSStackView` with 8pt edge insets.

## HIG citations (validated)
- Sidebars / Abstract: "A sidebar appears on the leading side of a view and lets
  people navigate between sections in your app or game."
- Sidebars / Best practices: "In iOS, iPadOS, and macOS, as with other controls
  such as toolbars and tab bars, sidebars float above content in the Liquid Glass
  layer."
- Sidebars / Best practices: "Consider using familiar symbols to represent items
  in the sidebar. SF Symbols provides a wide range of customizable symbols you can
  use to represent items in your app."
- Sidebars / Best practices: "In general, show no more than two levels of hierarchy
  in a sidebar. When a data hierarchy is deeper than two levels, consider using a
  split view interface that includes a content list between the sidebar items and
  detail view."
- Sidebars / Platform considerations / macOS: "Avoid stylizing your app by
  specifying a fixed color for all sidebar icons. By default, sidebar icons use the
  current accent color and people expect to see their chosen accent color throughout
  all the apps they use."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/sidebars.md](../validation/reports/sidebars.md)

## Related
- `UI::TabView` -- prefer over `NavigationSplitView` when you have four or fewer
  top-level areas that do not require a persistent sidebar list.
- `UI::NavigationStack` -- the collapsed iPhone version of a sidebar; use directly
  when you only target iPhone and never need the split layout.
- `recipes/master-detail.md` -- canonical 2-column split pattern combining
  `UI::NavigationSplitView` with `UI::ListView` for the detail column.
