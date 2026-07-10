---
slug: scroll-views
ui_view: UI::ScrollView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/scroll-views.md
validation_report: ../validation/reports/scroll-views.md
---

# UI::ScrollView

> A transparent content container that clips its child view tree to a visible
> viewport and lets users scroll the hidden content into view; renders as
> NSScrollView on macOS and UIScrollView on iOS, with no surface material of
> its own (no Liquid Glass by default).

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A scroll view exists to reveal content that does not fit in the available
space. It is the right reach when a list, an article, a form, or a canvas
must be taller (or wider) than the window or panel that contains it. The
scroll view itself disappears visually -- it has no background, no border,
and no chrome of its own. What it contributes is the clipping boundary and
the scroll gesture, plus the transient indicator that confirms to the user
that more content is available in that direction.

What a scroll view is NOT for: it is not a page-replacement (use
NavigationStack for that), not a disclosure mechanism (use a collapsible
section or a Popover), and not a substitute for pagination (consider a
PageControl when users move through defined chunks). Nesting a scroll view
inside another scroll view on the same axis creates an unpredictable and
frustrating interface; the HIG explicitly calls this out.

(HIG: "Make it apparent when content is scrollable. Because scroll indicators
aren't always visible, it can be helpful to make it obvious when content
extends beyond the view." -- Scroll views / Best practices.)

## Quickstart

```crystal
# Build the scrollable content -- any view tree, but a VStack is typical
rows = UI::VStack.new(spacing: 0.0)
(1..20).each do |i|
  row = UI::Label.new("Item #{i} -- scrollable content")
  row.font = UI::Font.new(size: 16.0, weight: :regular)
  rows << row
  rows << UI::Divider.new if i < 20
end

# Wrap in a ScrollView.
# frame_height is REQUIRED when embedding in a VStack / HStack:
# without it the parent stack collapses the scroll view to zero height.
scroll = UI::ScrollView.new(rows)
scroll.scroll_vertical = true
scroll.frame_height = 300.0            # viewport height in points
scroll.shows_indicators = true         # show overlay scroller during scroll
scroll.accessibility_label = "Content list, scrollable"
```

Renders: NSScrollView (macOS) or UIScrollView (iOS/iPadOS). No surface
material -- the scroll region is transparent; the window or host view
background shows through. The scroll indicator is a transient overlay knob
that appears during active scrolling.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `content` | `UI::View?` | `nil` | The single child view tree to scroll. Typically a VStack, HStack, or Grid. |
| `scroll_vertical` | `Bool` | `true` | Enables vertical scrolling and the vertical scroll indicator. |
| `scroll_horizontal` | `Bool` | `false` | Enables horizontal scrolling and the horizontal scroll indicator. |
| `shows_indicators` | `Bool` | `true` | Shows the transient overlay scroll indicator during active scrolling. Set false to permanently hide it (not recommended for user-initiated scroll areas per HIG). |
| `frame_height` | `Float64` | `0.0` | Pins the viewport height in points via an Auto Layout constraint. Required when embedding in a vertical NSStackView / UIStackView; 0 = unconstrained (collapses). |
| `frame_width` | `Float64` | `0.0` | Pins the viewport width in points. Usually leave at 0 and let the parent stack supply the width. |

**Theming**: UI::ScrollView has no surface color of its own; it is always
transparent. Content child views inherit the host window background unless
they set their own `background` property. Scroll indicator color tracks the
system appearance automatically (no theme token needed). See
`foundations/color-and-theming.md`.

## Light / dark appearance notes

UI::ScrollView has no visual chrome of its own in either appearance. The
component is transparent by design -- the scroll region shows the host
window background behind the content.

In light appearance, the host window background is system white (~1.0 RGB on
macOS, white on iOS), so content rows with `NSColor.labelColor` /
`UIColor.label` resolve to near-black (~0.0 RGB) for ~21:1 contrast. The
transient scroll indicator resolves to a dark semi-transparent knob
(NSScrollerKnobStyleOverlay dark variant in light) visible against the white
background.

In dark appearance, the host window background is DarkAqua (~0.12 RGB on
macOS) or the near-black system background on iOS (~0.05 RGB). Label colors
resolve to near-white (~1.0 RGB) automatically via `NSColor.labelColor` /
`UIColor.label` semantic colors, maintaining ~17:1 contrast. The scroll
indicator resolves to a lighter semi-transparent knob visible against the dark
background. The transition between appearances is handled entirely by the
platform's semantic color system; no code change is required.

UI::Divider separators inside the scroll content use `NSColor.separatorColor`
/ `UIColor.separator`, which resolve to a medium-gray in light and a slightly
lighter near-dark-gray in dark. They are legible in both appearances as layout
aids between rows.

No SF Symbols are used by UI::ScrollView itself. Content child views may use
SF Symbols, and those resolve their weight/color per the system appearance as
they would in any other container.

A brand override that sets a dark `background` on the scrollable content
VStack will reduce the indicator knob's contrast in dark mode (dark indicator
against dark custom background). If you set a custom background on the content,
test both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Set a brand background on the content, not the scroll view.**
```crystal
# UI::ScrollView is always transparent. Apply background to the content
# VStack so the brand fill stays within the scroll area and the window
# chrome outside the scroll region remains unaffected.
rows = UI::VStack.new(spacing: 0.0)
rows.background = UI::Color.new(r: 0.96, g: 0.97, b: 1.0)  # brand tint
scroll = UI::ScrollView.new(rows)
scroll.frame_height = 300.0
# Keep shows_indicators: true so users know content continues.
```

**Hide scroll indicators for a clean reading experience.**
```crystal
# The HIG warns against hiding indicators in user-scrolled areas, but a
# purely presentational scroll region (e.g., a marketing hero banner that
# auto-scrolls) may hide them. Keep accessibility_label so VoiceOver still
# describes the region.
scroll = UI::ScrollView.new(content)
scroll.shows_indicators = false
scroll.accessibility_label = "Product highlights, auto-scrolling"
scroll.frame_height = 200.0
```

**Enable horizontal scrolling for a row of cards.**
```crystal
# HIG: "It's alright to place a horizontal scroll view inside a vertical
# scroll view (or vice versa)."  For a horizontally-scrolling card row,
# disable vertical scroll and set frame_height to the card height.
cards = UI::HStack.new(spacing: 12.0)
(1..8).each { |i| cards << UI::Card.new("Card #{i}") }

card_scroller = UI::ScrollView.new(cards)
card_scroller.scroll_horizontal = true
card_scroller.scroll_vertical = false
card_scroller.frame_height = 160.0   # match card height + padding
card_scroller.accessibility_label = "Horizontal card scroller"
```

## Feel recipes
Short examples that map design intent to code.

**"I want a vertically-scrolling settings form that doesn't crush its items"**
-> Set `scroll_vertical = true`, `frame_height` to the available panel height
   (e.g. `400.0`), place a `UI::Form` or `UI::VStack` as content. The form
   items keep their HIG-mandated spacing; the scroll view adds the overflow
   viewport. Do not nest a scroll view inside the form's own scroll behavior.

**"I want to reveal a clue that more content exists below the fold"**
-> HIG: "Displaying partial content at the edge of a view indicates that
   there's more content in that direction." Set `frame_height` slightly less
   than the content height so the last visible row is cut off at exactly one-
   half its height (e.g., 14 full rows + half a 15th row visible). This is the
   canonical HIG-recommended scroll affordance.

## What happens on each platform
- **iOS 26**: UIScrollView. Content wired via `uiscrollview_pin_content`
  (edges to contentLayoutGuide, width to frameLayoutGuide). Scroll indicator:
  UIScrollView overlay knob in UIScrollIndicatorStyle.default, appears during
  scroll and fades out.
- **iPadOS 26**: Same as iOS. On split-view layouts, each pane's scroll view
  can have its own scroll edge effect; keep scroll edge effect heights
  consistent across panes (HIG: "in split view layouts on iPad and Mac, each
  pane can have its own scroll edge effect; in this case, keep them consistent
  in height to maintain alignment").
- **macOS 26**: NSScrollView. Content wired via `nsscrollview_set_document_view`
  (documentView + leading/trailing/top pinned to NSClipView). Scroll indicator:
  NSScroller overlay knob in NSScrollerKnobStyleOverlay (default since macOS 10.7);
  appears during trackpad scroll and fades out.

## HIG citations (validated)
- Scroll views -- Abstract: "A scroll view lets people view content that's
  larger than the view's boundaries by moving the content vertically or
  horizontally."
- Scroll views -- Abstract: "The scroll view itself has no appearance, but it
  can display a translucent scroll indicator that typically appears after people
  begin scrolling the view's content."
- Scroll views -- Best practices: "Make it apparent when content is scrollable.
  Because scroll indicators aren't always visible, it can be helpful to make it
  obvious when content extends beyond the view. For example, displaying partial
  content at the edge of a view indicates that there's more content in that
  direction."
- Scroll views -- Best practices: "Avoid putting a scroll view inside another
  scroll view with the same orientation. Nesting scroll views that have the same
  orientation can create an unpredictable interface that's difficult to control."
- Scroll views -- Best practices: "Support default scrolling gestures and
  keyboard shortcuts. People are accustomed to the systemwide scrolling behavior
  and expect it to work everywhere."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/scroll-views.md](../validation/reports/scroll-views.md)

## Related
- `UI::ListView` -- use instead when content is a homogeneous list of data
  rows that benefit from platform-native row selection, reordering, and
  swipe-to-delete behaviors
- `UI::NavigationStack` -- use instead when the user moves between pages
  (not scrolls within a single page)
- `recipes/settings-form.md` -- multi-section settings form embedded in a
  scroll view with section chrome
