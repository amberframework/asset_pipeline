---
title: Spacing and layout
topic: layout
hig_pages:
  - layout.md
  - spatial-layout.md
---

# Spacing and layout

## What it means

Apple's layout language is built on a handful of conventions that compound into
the look of a native app:

- **The 8pt grid.** Paddings, margins, and stack spacings default to multiples
  of 8: commonly 4, 8, 12, 16, 20, 24. Stray pixel values (13, 17, 22) read as
  off and undermine the sense of alignment.
- **Safe areas are sacred.** The top/bottom inset for notches, home indicators,
  and tab bars is managed by the system. Don't paint controls into these
  regions; instead, anchor content to safe-area edges and let the system
  resolve the actual pixel offset.
- **Backgrounds extend to edges; controls sit above them.** Artwork fills the
  screen all the way to the bezel. Tab bars, sidebars, toolbars — these now
  sit on top of content via Liquid Glass rather than partitioning a separate
  strip.
- **Alignment scans faster than contrast.** If two groups of content line up on
  the leading edge, the eye reads them as related. Use alignment rather than
  decorative dividers wherever possible.

Platform-specific margin defaults (from HIG layout pages):

| Platform | Default horizontal margin |
|----------|---------------------------|
| iOS (phone) | 16–20 pt |
| iPadOS (regular width) | 24 pt |
| macOS | 20 pt |

## How it's expressed in asset_pipeline

`UI::EdgeInsets` is the primitive for padding and margins (source:
`src/ui/view.cr`):

```crystal
record EdgeInsets,
  top : Float64 = 0.0,
  trailing : Float64 = 0.0,
  bottom : Float64 = 0.0,
  leading : Float64 = 0.0
```

Use it to express the 8pt grid explicitly:

```crystal
insets = UI::EdgeInsets.new(top: 16.0, trailing: 20.0, bottom: 16.0, leading: 20.0)
my_view.padding = insets
```

Note: `EdgeInsets` uses `leading`/`trailing` rather than `left`/`right` — this
is correct for right-to-left layout support; the renderer flips them for RTL
languages automatically. Never introduce `left`/`right` in your own API.

Stacks carry their own inter-child spacing:

```crystal
# source: src/ui/views/vstack.cr
class VStack < View
  property spacing : Float64 = 8.0
  property alignment : Alignment = Alignment::Center
  getter children : Array(View)
end
```

Default stack spacing is 8.0 — one unit of the grid. For denser groupings drop
to 4.0; for looser sectioning jump to 16.0 or 20.0.

Example — a settings-section layout on the 8pt grid:

```crystal
section = UI::VStack.new(spacing: 12.0, alignment: UI::Alignment::Leading)
section.padding = UI::EdgeInsets.new(top: 16.0, trailing: 20.0, bottom: 16.0, leading: 20.0)

section << UI::Label.new("Notifications")
section << UI::Toggle.new("Push alerts", true)
section << UI::Toggle.new("Email digest", false)
```

### Safe areas

**Explicit safe-area modifiers are planned.** Today the renderer applies the
system safe-area guide automatically to the root view; you don't need to opt
in. You also can't currently opt out (no `ignores_safe_area(edges: .top)`
modifier yet). If you need a full-bleed background, achieve it today by
setting the root view's `background` color and letting child content take the
safe-area padding naturally.

### Maximum widths

For readability, long-form content on iPad and macOS shouldn't stretch edge to
edge. Set `maximum_width` on content containers:

```crystal
article = UI::VStack.new(spacing: 16.0)
article.maximum_width = 680.0  # typical readable line length
article << UI::Label.new("...")
```

`maximum_width` / `minimum_width` / `maximum_height` / `minimum_height` are
standard properties on every `UI::View`.

## HIG citations

- **Layout → Best practices**: "Group related items to help people find the
  information they want. … use negative space, background shapes, colors,
  materials, or separator lines to show when elements are related."
  (`pages/layout.md`)
- **Layout → Best practices**: "Extend content to fill the screen or window."
  (`pages/layout.md`)
- **Layout → Visual hierarchy**: "Align components with one another to make
  them easier to scan and to communicate organization and hierarchy."
  (`pages/layout.md`)
- **Layout → Adaptability**: "respecting system-defined safe areas, margins,
  and guides." (`pages/layout.md`)
- **Spatial layout**: complementary guidance for visionOS. (`pages/spatial-layout.md`)
