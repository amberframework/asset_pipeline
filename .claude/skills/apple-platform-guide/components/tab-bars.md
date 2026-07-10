---
slug: tab-bars
ui_view: UI::TabView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/tab-bars.md
validation_report: ../validation/reports/tab-bars.md
---

# UI::TabView

> A bottom navigation bar that lets people switch between the top-level sections of your
> app; on iOS 26 the bar surface renders with UIGlassEffect (Liquid Glass), and on macOS
> approximates the material with NSVisualEffectMaterialMenu.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A tab bar represents the permanent, top-level structure of an app. Tapping a tab is never
destructive -- it merely shifts which section is visible. Each tab is independent: returning
to a tab resumes where the user left off, preserving navigation state within that section.
Reach for a tab bar when your app has two to five distinct, peer sections that users navigate
between frequently. Do NOT use a tab bar to provide actions on the current view (use a Toolbar
instead), and do not hide or disable a tab when its content is temporarily unavailable --
show an empty-state explanation instead.

(HIG: "Use a tab bar to support navigation, not to provide actions." -- Tab bars / Best
practices.)

## Quickstart

```crystal
# 5-tab bar: house/Home, magnifyingglass/Search (selected), heart/Favorites,
# bell/Activity, person/Profile.
# HIG: "Use the appropriate number of tabs" -- 2-5 is the recommended range.
# HIG: "Consider using SF Symbols" -- all icons use SF Symbol names.

tabs = [
  UI::TabView::Tab.new(label: "Home",      icon: "house",           content: home_view),
  UI::TabView::Tab.new(label: "Search",    icon: "magnifyingglass", content: search_view),
  UI::TabView::Tab.new(label: "Favorites", icon: "heart",           content: favs_view),
  UI::TabView::Tab.new(label: "Activity",  icon: "bell",            content: activity_view),
  UI::TabView::Tab.new(label: "Profile",   icon: "person",          content: profile_view),
]

tab_view = UI::TabView.new(tabs, 1)   # selected_index: 1 = Search
tab_view.glass_bar = true             # default true -- Liquid Glass surface
tab_view.accessibility_label = "Tab bar navigation"
```

Renders: on iOS 26, UIVisualEffectView wrapping UIGlassEffect (Liquid Glass) as the surface,
with a horizontal UIStackView of UIImageView (SF Symbol) + UILabel cells; on macOS,
NSVisualEffectView (NSVisualEffectMaterialMenu, tracks appearance) as the surface; on
both platforms, the selected tab item is tinted UIColor.systemBlueColor /
NSColor.controlAccentColor (system blue default).

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `tabs` | `Array(Tab)` | `[]` | The ordered list of tab entries; each Tab has a `label`, optional `icon` (SF Symbol name), and `content` (UI::View for the selected state). HIG recommends 2-5 tabs. |
| `selected_index` | `Int32` | `0` | Zero-based index of the currently selected tab; that tab's icon and label are tinted with `selected_tint_color`. |
| `glass_bar` | `Bool` | `true` | Whether to apply the Liquid Glass material (UIGlassEffect / NSVisualEffectMaterialMenu) to the tab bar surface. Set `false` for a plain opaque bar (brand override; removes appearance-tracking glass). |
| `selected_tint_color` | `Color?` | `nil` | Accent color for the selected tab's icon and label. `nil` resolves to UIColor.systemBlueColor (iOS) or system blue RGBA 0.0/0.478/1.0 (macOS). Override to your brand primary. |
| `bar_position` | `Symbol` | `:bottom` | `:bottom` (iOS HIG default) or `:top` (macOS toolbar-style). Drives which end of the outer vertical stack the tab row appears on. |
| `on_change` | `Proc(Int32, Nil)?` | `nil` | Callback invoked with the new selected index when a tab is tapped. |

**Theming**: `UI::Theme.apple_default.primary` (system blue 0.0/0.478/1.0) drives the default
selected tint. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

Both iOS and macOS renderers resolve all colors from appearance-tracking system color sources,
so the tab bar adapts correctly when the user switches between light and dark appearances.

**Glass surface:**
- iOS 26 light: UIGlassEffect resolves to a light frosted surface (~0.96 RGB) that allows
  content beneath to peek through. The effect tracks the trait collection automatically.
- iOS 26 dark: UIGlassEffect resolves to a dark frosted surface (~0.18 RGB) against black
  backgrounds, clearly distinguishable.
- macOS light (Aqua): NSVisualEffectMaterialMenu (10) resolves to a light frosted gray
  (~0.91 RGB). The menu material is the closest HIG-honest approximation for an iOS-primary
  tab bar component on macOS. BlendingMode BehindWindow samples the window backdrop.
- macOS dark (DarkAqua): NSVisualEffectMaterialMenu (10) resolves to a dark frosted surface
  (~0.22 RGB), distinguishable from near-black window backgrounds.

**Icon tints:**
- Selected tab: UIColor.systemBlueColor (iOS) / RGBA 0.0/0.478/1.0 (macOS). In dark mode
  UIKit adjusts the blue to ~0.039/0.518/1.0 for dark-background contrast; this is automatic
  through the systemBlueColor dynamic color.
- Unselected tabs: UIColor.secondaryLabelColor (iOS) / NSColor.secondaryLabelColor (macOS).
  In light mode ~0.50-0.55 RGB (medium gray). In dark mode ~0.55-0.60 RGB (lighter gray on
  dark background). Both appearances give adequate contrast against the respective glass surface.

**Typography:**
- Tab labels: 10pt Regular system font (UIFont.systemFont(ofSize:10) / NSFont.systemFont(ofSize:10)).
  The 10pt weight is NOT auto-thinned in dark mode on either platform -- the system font
  maintains its Regular weight in both appearances.
- Content area labels (the selected tab's content): driven by the content view's own fonts,
  which use NSColor.labelColor / UIColor.labelColor -- both track appearance automatically.

**SF Symbol variants:**
- Current renderer: outline (unfilled) SF Symbol variants via `systemImageNamed:` /
  `imageWithSystemSymbolName:accessibilityDescription:`. The outline variant is legible
  in both appearances at the 16-22pt icon size used in tab bars.
- HIG preference: "Prefer filled symbols or icons for consistency with the platform." A
  future iteration will add `use_filled_symbols : Bool` to append ".fill" to icon names
  automatically. For now, pass "house.fill" etc. in the `icon` field if you need filled.
- If you override `selected_tint_color` to a light color (e.g. white or yellow), verify
  that the selected icon remains distinguishable from unselected icons in BOTH appearances.
  A white tint on a light glass surface will collapse contrast -- use a mid-tone or darker
  brand color in light appearance and a brighter variant in dark.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's legibility,
hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override the selected tab tint to a brand color.
# HIG spacing (16pt content insets), hit targets (65pt cell width), and glass surface
# are preserved. Only the icon and label color of the selected tab changes.
tab_view = UI::TabView.new(tabs, selected_index: 1)
tab_view.selected_tint_color = UI::Color.new(r: 0.55, g: 0.24, b: 0.80)  # brand purple

# Caution: verify contrast in BOTH appearances.
# Purple ~0.55/0.24/0.80 reads well against the glass surface in light mode (~5:1).
# In dark mode the glass is darker (~0.18 RGB); purple at this tone may drop below 3:1.
# Consider a lighter dark-mode variant via a two-tab-view conditional or theme override.
```

**Replace the glass material with a flat brand surface.**
```crystal
# Disable Liquid Glass entirely. Produces a plain non-translucent tab bar.
# WARNING: removes the HIG Liquid Glass requirement for tab bars (iOS 26).
# Use only when brand guidelines explicitly require a solid-color tab bar.
tab_view = UI::TabView.new(tabs, selected_index: 1)
tab_view.glass_bar = false
# The bar container will fall back to the system background color.
# Set a background on the view if you need a specific brand color:
tab_view.background = UI::Color.new(r: 0.10, g: 0.10, b: 0.14)  # near-black brand bar

# Legibility trade-offs: without glass, there is no appearance-tracking translucency.
# You are responsible for ensuring the chosen background has sufficient contrast with
# both icon tints (selected and unselected) in BOTH light and dark appearances.
```

**Override typography while keeping HIG spacing.**
```crystal
# Tab labels use the renderer's hard-coded 10pt system font. To substitute a brand font,
# set the content labels in each tab's content view, not in the tab bar itself (the tab
# label font is currently renderer-fixed). The content area IS customizable:

# Inside your tab's content view, use UI::Font.new(size:, weight:) for headings:
content = UI::VStack.new(spacing: 8.0)
title = UI::Label.new("Search")
title.font = UI::Font.new(size: 17.0, weight: :semibold)   # brand heading style
content << title

# Tab cell label font override is planned for a future iteration via a `label_font`
# property on UI::TabView::Tab. For now, brand typography is confined to content views.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a 3-tab app with a brand red selected state."**
```crystal
tab_view = UI::TabView.new([
  UI::TabView::Tab.new(label: "Feed",    icon: "house",       content: feed_view),
  UI::TabView::Tab.new(label: "Explore", icon: "safari",      content: explore_view),
  UI::TabView::Tab.new(label: "Profile", icon: "person",      content: profile_view),
], 0)
tab_view.selected_tint_color = UI::Color.new(r: 0.88, g: 0.14, b: 0.14)
```
HIG: "Use the appropriate number of tabs" -- 3 tabs is within the 2-5 range.

**"I want an activity badge on the Activity tab."**
Badges are planned. For now, embed badge metadata in the label string:
```crystal
UI::TabView::Tab.new(label: "Activity (3)", icon: "bell", content: activity_view)
```
Track the `validation/gaps.md` entry for `UI::TabView` badge support.

## What happens on each platform
- **iOS 26**: UIVisualEffectView with UIGlassEffect as the root surface. Inner vertical
  UIStackView holds the content area (UIStackView, 16pt margins) above a UIColor.separatorColor
  hairline above the horizontal tab row UIStackView (UIStackViewDistributionFillEqually, 5 cells
  each UIImageView + UILabel). Hit targets ~65pt wide x 50pt tall per cell. Selected tab tinted
  UIColor.systemBlueColor or `selected_tint_color`.
- **iPadOS 26**: Same UITabBarController / UIVisualEffectView rendering as iOS. On iPad, the
  system may adapt the tab bar to a sidebar (sidebarAdaptable style) at larger trait collections.
  The current renderer does not implement the sidebar-adaptive behavior; this is logged as a
  gap. The fixed tab bar rendering is correct for tabBarOnly style.
- **macOS 26**: NSVisualEffectView (NSVisualEffectMaterialMenu = 10) as the root surface, inner
  vertical NSStackView, NSBox separator, horizontal tab row NSStackView. NSImageView SF Symbols
  tinted via setContentTintColor:. Tab labels are NSTextField (non-editable, 10pt). macOS is not
  the HIG-primary platform for tab bars ("No additional considerations for macOS" -- HIG); this
  is an iOS-shape approximation for validation parity.

## HIG citations (validated)
- Tab bars -> Abstract: "A tab bar lets people navigate between top-level sections of your app."
- Tab bars -> Best practices: "Use a tab bar to support navigation, not to provide actions. A tab
  bar lets people navigate among different sections of an app... If you need to provide controls
  that act on elements in the current view, use a Toolbars instead."
- Tab bars -> Best practices: "Use the appropriate number of tabs required to help people navigate
  your app. As a representation of your app's hierarchy, it's important to weigh the complexity
  of additional tabs against the need for people to frequently access each section."
- Tab bars -> Best practices: "Consider using SF Symbols to provide familiar, scalable tab bar
  icons. Prefer filled symbols or icons for consistency with the platform."
- Tab bars -> Platform considerations -> iOS: "A tab bar floats above content at the bottom of
  the screen. Its items rest on a Liquid Glass background that allows content beneath to peek
  through."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/tab-bars.md](../validation/reports/tab-bars.md)

## Related
- `UI::Toolbar` -- use Toolbar for actions that act on the current view's content, not for
  top-level section navigation.
- `UI::NavigationSplitView` -- for complex information structures on iPad/macOS where a
  sidebar is preferable to a tab bar.
- `recipes/tab-and-navigation.md` -- multi-component pattern combining UI::TabView with
  UI::NavigationStack for each tab's content hierarchy.
