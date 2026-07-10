---
slug: split-views
ui_view: UI::NavigationSplitView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/split-views.md
validation_report: ../validation/reports/split-views.md
---

# UI::NavigationSplitView

> A split view that divides the window into two or three adjacent panes separated by
> 1pt thin dividers, with the sidebar column rendered in the Liquid Glass sidebar
> material (NSVisualEffectMaterialSidebar on macOS, UIGlassContainerEffect on iOS 26)
> and the content and detail panes in the window's native background material.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A split view is the primary multi-level navigation container for iPad and Mac apps.
It sits at the root of the view hierarchy and manages the persistent co-presence of
two or three information levels: the navigation column (sidebar), an optional list
pane, and a detail pane. Unlike a modal sheet or a popover, a split view never
obscures its parent -- all panes are simultaneously visible in a regular-width
environment, letting people stay oriented while navigating hierarchy.

Reach for `UI::NavigationSplitView` when your app has at least two levels of
persistent hierarchy (e.g. mailbox list and message detail, or settings category and
settings page). Do not use it for supplemental panels like an inspector; use a
floating panel or Popover instead. On iPhone compact width, the component collapses
to a NavigationStack sequence -- design the pane content to work independently at
full width.

(HIG: "Typically, you use a split view to show multiple levels of your app's hierarchy
at once and support navigation between them." -- Split views / Abstract.)

## Quickstart

```crystal
# 3-pane Mail-style split view.
# Left sidebar: navigation mailbox list.
# Middle list: message rows.
# Right detail: selected message body.

# Sidebar navigation content
sidebar = UI::VStack.new(spacing: 0.0)
inbox_row = UI::HStack.new(spacing: 6.0)
inbox_row << UI::Image.new("envelope")
inbox_row << UI::Label.new("Inbox")
inbox_row << UI::Spacer.new
inbox_row << UI::Label.new("12")
sidebar << inbox_row

# Message list pane content
message_list = UI::VStack.new(spacing: 0.0)
message_list << UI::Label.new("Quarterly report")
message_list << UI::Divider.new
message_list << UI::Label.new("Re: Meeting notes")

# Detail pane content
detail = UI::VStack.new(spacing: 8.0)
from_label = UI::Label.new("From: Alice Martin <alice@example.com>")
subject_label = UI::Label.new("Subject: Quarterly report")
subject_label.font = UI::Font.new(size: 13.0, weight: :semibold)
detail << from_label
detail << subject_label
detail << UI::Divider.new
detail << UI::Label.new("Hi, please find the Q1 numbers attached...")

# Assemble split view
nsv = UI::NavigationSplitView.new(
  sidebar: sidebar,
  content: message_list,
  detail: detail
)
nsv.sidebar_width = 200.0
nsv.shows_sidebar = true
nsv.accessibility_label = "Mail navigation"
```

Renders: on macOS the sidebar column wraps in an `NSVisualEffectView` with
`NSVisualEffectMaterialSidebar` (material 7, tracks system appearance automatically);
on iOS 26 the sidebar column wraps in a `UIVisualEffectView` with
`UIGlassContainerEffect` (or `UIBlurEffect(style: .systemChromeMaterial)` on older
SDKs). On iPhone compact width, `UISplitViewController` collapses to a
`UINavigationController` sequence.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `sidebar` | `View?` | `nil` | View tree for the leading navigation column. Rendered inside the sidebar Liquid Glass surface. |
| `content` | `View?` | `nil` | View tree for the optional middle list pane. No glass applied; uses window background. |
| `detail` | `View?` | `nil` | View tree for the trailing detail pane. No glass applied; uses window background. |
| `sidebar_width` | `Float64` | `250.0` | Width in points of the sidebar column. HIG recommends a sidebar width that keeps content readable; typical macOS Mail uses ~200pt. |
| `shows_sidebar` | `Bool` | `true` | When false, hides the sidebar column entirely. Maps to `NSSplitViewController` column visibility. |
| `column_visibility` | `Symbol` | `:all` | `:all` shows all columns; `:double_column` hides the sidebar; `:detail_only` shows only the detail pane. |

**Theming**: sidebar glass material is `NSVisualEffectMaterialSidebar` (macOS) /
`UIGlassContainerEffect` (iOS 26) -- both track the system appearance automatically
and are not driven by `UI::Theme` color tokens. Row text colors follow
`Theme.apple_default.primary` (NSColor.labelColor / UIColor.label). Divider lines
use `Theme.apple_default.outline_variant` in the renderer default. See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** The sidebar `NSVisualEffectView` with `NSVisualEffectMaterialSidebar`
(material 7) resolves to a light-gray frosted fill (~0.91 RGB). This is the system-
managed material; it tracks `NSAppearanceNameAqua` automatically. The column divider
line between panes is a 1pt rule in `NSColor.separatorColor` (light resolves to
~0.78 RGB). Primary labels (`NSColor.labelColor`) are near-black (~0.0 RGB),
contrast ~21:1 against the white window background. Section headers are rendered at
~11pt Semibold with a gray text color (~0.6 RGB), contrast ~4.5:1 -- at the WCAG 3:1
large-text threshold. Selected item labels use Semibold weight to communicate
selection state per HIG guidance.

**macOS dark:** The sidebar `NSVisualEffectView` resolves to a dark-gray frosted fill
(~0.21 RGB) tracking `NSAppearanceNameDarkAqua`. Primary labels near-white (~1.0 RGB),
contrast ~12:1. Section headers gray (~0.6 RGB), contrast ~4.0:1. SF Symbol icons
(system blue 0.0/0.478/1.0, orange 1.0/0.584/0.0) remain distinguishable against the
dark sidebar fill. No auto-thinning of semibold weight in dark mode --
`NSTextField` inside `NSVisualEffectView` preserves declared font weight.

**iOS light:** The sidebar column uses `UIGlassContainerEffect` on iOS 26 (or
`UIBlurEffect(style: .systemChromeMaterial)` on older SDKs) resolving to a near-white
frosted card (~0.97 RGB). On compact-width iPhone, `UISplitViewController` collapses
to a `UINavigationController`; the sidebar list fills the full screen width. Labels
use `UIColor.label` (light: ~0.0 RGB) against the white background, contrast ~21:1.

**iOS dark:** `UIGlassContainerEffect` / `UIBlurEffect` resolves to a near-black
frosted surface (~0.05 RGB). Labels use `UIColor.label` (dark: ~1.0 RGB), contrast
~20:1. The dark-mode sidebar material boundary may not be visible as a distinct edge
in static XCUITest screenshots (rasterization harness limitation, noted in
gaps.md iter-41); material object and blending mode are correct. SF Symbol tints
(system blue, orange) remain distinguishable against the near-black surface.

**Brand caution:** If you override `text_color` on section headers to a custom brand
color, verify contrast against both the light-frosted (~0.91 RGB) and dark-frosted
(~0.21 RGB) sidebar fills. A mid-range brand hue (e.g. 0.5/0.5/0.5) at 11pt may
fall below 4.5:1 in one or both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the sidebar icon accent to your brand primary.**
```crystal
# Replace system blue SF Symbol tint with a brand accent.
# Keep font sizes, weights, and spacing at HIG defaults -- only the color changes.
icon = UI::Image.new("envelope")
icon.tint_color = UI::Color.new(r: 0.2, g: 0.6, b: 0.4)  # brand green
row << icon

# Verify the brand color at >= 3:1 contrast against both:
#   light sidebar fill (~0.91 RGB) and dark sidebar fill (~0.21 RGB).
# System blue (0.0/0.478/1.0) passes both; saturated brand greens usually pass
# light but may need a lighter variant for dark.
```

**Replace the sidebar glass with a flat brand surface.**
```crystal
# Setting shows_sidebar = false removes the sidebar column entirely.
# To render a non-glass sidebar, build the sidebar view as a plain VStack
# and wrap it in a UI::Surface or UI::Card with a flat background:
brand_sidebar_bg = UI::Card.new
brand_sidebar_bg.background_color = UI::Color.new(r: 0.12, g: 0.16, b: 0.22)
brand_sidebar_bg.corner_radius = 0.0  # flush edge for sidebar column
inner = UI::VStack.new(spacing: 0.0)
# ... add rows ...
brand_sidebar_bg << inner

nsv = UI::NavigationSplitView.new(
  sidebar: brand_sidebar_bg,
  content: list_pane,
  detail: detail_pane
)
# Note: this removes the NSVisualEffectView / UIGlassContainerEffect glass.
# The sidebar will render as a flat solid fill instead of a Liquid Glass
# translucent surface. HIG Best practices recommend the glass material for
# sidebar surfaces; only deviate if your brand requires a fully opaque sidebar.
```

**Override sidebar section header typography while keeping HIG spacing.**
```crystal
section_hdr = UI::Label.new("MAILBOXES")
# Brand font at the HIG-recommended size and weight for section headers.
section_hdr.font = UI::Font.custom("YourBrandFont-SemiBold", size: 11.0)
# Keep the HIG-recommended secondary text color for section headers.
section_hdr.text_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.6)
section_hdr.accessibility_label = "Mailboxes section header"
# Spacing between header and first row is controlled by the VStack spacing
# in the sidebar content -- keep spacing at 0.0 and let section separators
# (UI::Divider) provide visual grouping rather than large gaps.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a 2-column sidebar + detail layout (no middle list pane)"**
-> Set `content: nil` in the `NavigationSplitView` constructor.
-> Use `sidebar_width: 240.0` (standard macOS sidebar width for most apps).
-> Populate `detail:` with the full content view.

**"I want to hide the sidebar in immersive editing mode"**
-> Set `nsv.shows_sidebar = false` when the user enters the editing context.
-> HIG macOS: "Consider letting people hide a pane when it makes sense. If your
   app includes an editing area, for example, consider letting people hide other
   panes to reduce distractions."
-> Provide a toolbar button or keyboard shortcut to restore the sidebar per HIG:
   "Provide multiple ways to reveal hidden panes."

## What happens on each platform
- **iOS 26**: `UISplitViewController` (triple-column style) with the sidebar column
  wrapped in a `UIVisualEffectView + UIGlassContainerEffect`. On iPhone compact width,
  collapses to `UINavigationController` stack navigation.
- **iPadOS 26**: Full 2 or 3-column split view with resizable panes. The sidebar
  column may be hidden with a toolbar button; the middle list pane and detail pane
  remain visible. Account for fluid resizing across narrow, intermediate, and full
  widths.
- **macOS 26**: `NSSplitViewController` with `NSSplitViewItem` for each column. The
  sidebar item uses `NSSplitViewItem.behavior = .sidebar`. Panes are separated by
  `NSSplitView` dividers (1pt thin style by default per HIG). The sidebar column
  wraps in `NSVisualEffectView(material: .sidebar)` which tracks `NSAppearance`
  automatically.

## HIG citations (validated)
- Split views -- Abstract: "A split view manages the presentation of multiple adjacent
  panes of content, each of which can contain a variety of components, including
  tables, collections, images, and custom views."
- Split views -- Best practices: "To support navigation, persistently highlight the
  current selection in each pane that leads to the detail view. The selected appearance
  clarifies the relationship between the content in various panes and helps people
  stay oriented."
- Split views -- Platform considerations -- iOS: "Prefer using a split view in a
  regular -- not a compact -- environment. A split view needs horizontal space in
  which to display multiple panes. In a compact environment, such as iPhone in portrait
  orientation, it's difficult to display multiple panes without wrapping or truncating
  the content."
- Split views -- Platform considerations -- macOS: "Prefer the thin divider style.
  The thin divider measures one point in width, giving you maximum space for content
  while remaining easy for people to use."
- Split views -- Platform considerations -- macOS: "Consider letting people hide a
  pane when it makes sense. If your app includes an editing area, for example, consider
  letting people hide other panes to reduce distractions or allow more room for
  editing."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/split-views.md](../validation/reports/split-views.md)

## Related
- `UI::NavigationStack` -- single-column push/pop navigation; use instead of split
  view on iPhone compact width
- `UI::GlassBackground` -- standalone Liquid Glass surface without the
  multi-column layout constraint
- `recipes/mail-style-nav.md` -- full 3-pane navigation pattern with sidebar +
  list + detail
