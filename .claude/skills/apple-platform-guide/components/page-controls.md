---
slug: page-controls
ui_view: UI::PageControl
priority: P2
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/page-controls.md
validation_report: ../validation/reports/page-controls.md
---

# UI::PageControl

> A horizontal row of dot indicators that shows the user's current position
> in a flat, ordered list of pages; on iOS and iPadOS it maps to UIPageControl
> (no Liquid Glass material -- dots render as opaque filled and outlined circles
> over whatever background they are placed on), and on macOS it is synthesized
> as an NSStackView of CALayer circles because HIG declares page controls
> "not supported in macOS."

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Page controls signal position in a flat, linearly ordered set of pages -- the
kind of content where each page is a peer (onboarding screens, a photo carousel,
a news swipe gallery). The filled dot marks "you are here" and the ring of
outlined dots says "there are N pages total."

This is NOT the component for hierarchical navigation (use `UI::NavigationStack`),
tabbed interfaces (use `UI::TabView`), or long content lists (use `UI::ListView`
or `UI::ScrollView`). Page controls are also not intended for more than about
ten pages -- beyond ten, individual dots become too small to count at a glance.

(HIG: "Although page controls can handle any number of pages, don't display too
many. More than about 10 dots are hard to count at a glance." -- Page controls /
Best practices.)

## Quickstart

```crystal
# Five pages, user is on the third (index 2).
# Default: UIColor.label (filled dot) + UIColor.secondaryLabel (outline dots).
pc = UI::PageControl.new(total: 5, current: 2)
pc.accessibility_label = "Page 3 of 5"

# Embed at the bottom of a VStack below the paged content.
stack = UI::VStack.new(spacing: 0.0)
stack << content_view
stack << pc
```

Renders: UIPageControl on iOS 26 and iPadOS 26, using UIColor.label for the
filled current-page dot and UIColor.secondaryLabel for the outlined non-current
dots; on macOS 26, synthesized as a horizontal NSStackView of CALayer-backed
NSView circles (filled vs. outlined) using NSColor.controlAccentColor.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `total` | `Int32` | (required) | Total number of page dots displayed. HIG recommends no more than 10. |
| `current` | `Int32` | `0` | Zero-based index of the filled (current) dot; clamped to `0...total`. |
| `tint_color` | `Color?` | `nil` | Overrides both the current-page fill and the non-current stroke/fill hue. When nil, uses UIColor.label / NSColor.controlAccentColor. |
| `page_indicator_tint_color` | `Color?` | `nil` | Independently overrides the non-current dot color. Useful for split tinting (filled = brand primary, others = brand secondary). When nil, derives from `tint_color` at 40% alpha or UIColor.secondaryLabel. |
| `background_style` | `Symbol` | `:automatic` | iOS 14+ background pill appearance. `:automatic` shows pill only during interaction; `:prominent` always shows; `:minimal` never shows. Ignored on macOS. |
| `accessibility_label` | `String?` | `nil` | Screen reader announcement. When nil, UIPageControl provides its own "Page X of Y" announcement; set explicitly to add context. |

**Theming**: no `UI::Theme` tokens drive this component directly.
`tint_color` and `page_indicator_tint_color` are explicit `UI::Color` overrides.
See `foundations/color-and-theming.md` for the `UI::Color` record fields.

## Light / dark appearance notes

The component resolves its color entirely through semantic UIKit/AppKit colors
when no `tint_color` is set:

**iOS / iPadOS:**

- Current-page dot: `UIColor.labelColor`. In light mode this resolves to
  near-black (~RGB 0.0/0.0/0.0), giving approximately 21:1 contrast on a
  white background. In dark mode it resolves to near-white (~RGB 1.0/1.0/1.0),
  giving approximately 21:1 contrast on a black background. Both resolve
  automatically to the correct high-contrast value.
- Non-current dots: `UIColor.secondaryLabel`. In light mode approximately
  RGB 0.57/0.57/0.57 (~3.8:1 on white). In dark mode approximately
  RGB 0.55/0.55/0.55 (~3.5:1 on black). Subordinate but legible in both
  appearances, matching the HIG intent that non-current dots are visually
  quieter than the current indicator.

Note: UIPageControl's factory defaults assume the control is overlaid on a
colored or photographic surface (the HIG reference illustration shows it on
a coral background). The semantic-color defaults above are a deliberate
library choice to ensure legibility on any host background. If your app
places the page control over a colored surface, let `tint_color` nil and rely
on the system defaults, or set `tint_color` to white for a light-on-dark usage.

**macOS:**

- Current-page dot: `NSColor.controlAccentColor` (system accent). In
  Aqua (light) mode this resolves to system blue (~RGB 0.0/0.478/1.0, ~3.1:1
  on white). In DarkAqua mode it resolves to a slightly lighter blue
  (~RGB 0.039/0.518/1.0, ~5.4:1 on the dark host). The accent color tracks
  the user's System Settings accent choice (blue, purple, orange, etc.).
- Non-current dots: `NSColor.controlAccentColor` at 40% alpha, synthesized
  as a stroke on an outlined circle. Visible in both light and dark against
  standard window background colors.

HIG states page controls are "Not supported in macOS." The macOS render is a
best-effort approximation using CALayer circles. There are no SF Symbol variants
used by this component (dots are pure CALayer geometry on macOS; UIPageControl
uses its built-in dot imagery on iOS).

Brand override contrast caveat: setting `tint_color` to a very light color
(e.g. white or yellow) on a light background will reduce the filled dot contrast
below 3:1 and impair legibility. Prefer `tint_color` values with at least 3:1
contrast against your surface background.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override the filled dot to your brand color while keeping
# semantic secondary color for the outlined dots.
pc = UI::PageControl.new(total: 5, current: 2)
pc.tint_color = UI::Color.new(r: 0.92, g: 0.24, b: 0.47)  # brand magenta
# Non-current dots automatically derive as magenta at 40% alpha.
# Hit targets: UIPageControl provides 44pt touch target per HIG.
# Spacing and sizing stay HIG-default.
```

**Split tinting: different colors for current vs. non-current dots.**
```crystal
# Current dot in brand primary, non-current dots in a brand secondary hue.
pc = UI::PageControl.new(total: 5, current: 2)
pc.tint_color = UI::Color.new(r: 0.92, g: 0.24, b: 0.47)           # brand magenta (filled)
pc.page_indicator_tint_color = UI::Color.new(r: 0.92, g: 0.24, b: 0.47, a: 0.3)  # softer magenta (outlined)
# Warning: verify contrast of both colors against your surface background.
# Setting page_indicator_tint_color below ~0.3 alpha on white or very light
# backgrounds risks invisible dots. HIG: "Avoid coloring indicator images.
# Custom colors can reduce the contrast."
```

**Force prominent background pill on iOS.**
```crystal
# :prominent keeps the translucent pill background always visible.
# Use when the page control is the primary navigation element.
pc = UI::PageControl.new(total: 5, current: 2)
pc.background_style = :prominent
# HIG: "Use this style only when the control is the primary navigational
# control in the screen."
```

## Feel recipes
Short examples that map design intent to code.

**"I want a minimal position-only indicator, no interaction feedback."**
- Set `background_style: :minimal` (suppresses the iOS background pill).
- Keep default colors for legibility.
- HIG: "Use the minimal background style when you just want to show the
  position of the current page in the list and you don't need to provide
  visual feedback during scrubbing."

**"I want to mark one special page (like Weather's current-location page)."**
- Use UIPageControl's `setIndicatorImage:forPage:` via a platform-specific
  extension rather than `UI::PageControl` directly.
- Or: wrap `UI::PageControl` beside a `UI::Label` with an SF Symbol icon
  at the leading position to mark the special page conceptually.
- HIG: "Avoid using more than two different indicator images in a page control."

## What happens on each platform
- **iOS 26**: Native UIPageControl. `currentPageIndicatorTintColor` =
  UIColor.labelColor (default) or `tint_color`. `pageIndicatorTintColor` =
  UIColor.secondaryLabel (default) or `page_indicator_tint_color`. Background
  pill driven by `background_style`. Touch target: UIPageControl's intrinsic
  height of 44pt satisfies HIG's interactive element minimum.
- **iPadOS 26**: Same as iOS 26. iPadOS additionally supports pointer hover
  to target specific indicators; this is handled by UIPageControl internally.
- **macOS 26**: HIG "Not supported." Synthesized as a horizontal NSStackView
  of CALayer-backed NSView circles: 8pt filled circle (current) and 7pt
  outlined circles (others), 6pt spacing, NSColor.controlAccentColor fill /
  stroke. Accessibility label set on the containing NSStackView.

## HIG citations (validated)
- Page controls -> abstract: "A page control displays a row of indicator
  images, each of which represents a page in a flat list."
- Page controls -> Best practices: "Center a page control at the bottom of
  the view or window. To ensure people always know where to find a page
  control, center it horizontally and position it near the bottom of the view."
- Page controls -> Best practices: "Although page controls can handle any
  number of pages, don't display too many. More than about 10 dots are hard
  to count at a glance."
- Page controls -> Customizing indicators: "Avoid coloring indicator images.
  Custom colors can reduce the contrast that differentiates the current-page
  indicator and makes the page control visible on the screen."
- Page controls -> Platform considerations: "Not supported in macOS."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/page-controls.md](../validation/reports/page-controls.md)

## Related
- `UI::ScrollView` -- the paged content area that the page control indicates
  position within; HIG: "Related: Scroll views."
- `UI::TabView` -- use instead when content areas are named tabs, not flat
  ordinal pages.
- `UI::NavigationStack` -- use instead for hierarchical navigation flows.
