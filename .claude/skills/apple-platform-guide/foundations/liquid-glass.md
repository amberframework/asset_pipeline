---
title: Liquid Glass
topic: materials
hig_pages:
  - materials.md
  - dark-mode.md
  - color.md
---

# Liquid Glass

## What it means

Liquid Glass is the material introduced at WWDC 2025 for iOS 26, iPadOS 26, and
macOS Tahoe 26. It is a dynamic, physically-based translucency that forms a
**distinct functional layer for controls and navigation** — tab bars, toolbars,
sidebars, popovers — that floats above the content layer. Content scrolls and
peeks through from beneath, giving the interface a sense of dynamism and depth
while remaining legible.

Two things that distinguish Liquid Glass from the older frosted-blur materials:

- **It's a layer promise, not a look.** The HIG is explicit: "Don't use Liquid
  Glass in the content layer." Liquid Glass signals "this floats above the
  content" — if you put it on content, you break the hierarchy.
- **It adapts automatically.** The *regular* variant adjusts luminosity against
  the background behind it; the *clear* variant is highly translucent for use
  over media. System components pick up the right variant automatically. If you
  apply it to a custom view, do so sparingly — overuse distracts from the
  content that Liquid Glass was designed to let through.

### When to use

- System chrome that sits above content: toolbars, tab bars, sidebars, popovers.
- A custom floating control that genuinely sits above the content layer.
- A transient interactive element (slider thumb, toggle track) that benefits from
  visual emphasis during activation.

### When NOT to use

- Content backgrounds (app backgrounds, cards in a list, form sections). Use the
  standard materials (`:ultra_thin | :thin | :regular | :thick`) instead — see
  `materials.md`.
- Plain solid-background controls that don't need to let content peek through.
  Liquid Glass has a performance and visual cost; a flat background is often
  clearer.
- Multiple overlapping custom controls in the same view. The HIG says "Limit
  these effects to the most important functional elements."

## How it's expressed in asset_pipeline

The `UI::GlassBackground` view is the dedicated wrapper for glass materials.
Source: `src/ui/views/glass_background.cr`.

```crystal
class GlassBackground < View
  property content : View? = nil
  property material : Symbol = :regular  # :thin, :ultra_thin, :regular, :thick, :chrome
  property is_vibrant : Bool = true
end
```

Constructor: `UI::GlassBackground.new(content: my_view, material: :thin)`.

The iOS renderer maps `GlassBackground` to a `UIVisualEffectView` backed by a
`UIBlurEffect` of the matching style; on iOS 26 with the Liquid Glass SDK, the
regular-variant `UIGlassEffectView` is preferred where available. On macOS the
renderer maps to `NSVisualEffectView` — see `glass-effects` skill for the
selector-level detail.

Minimum viable usage:

```crystal
content = UI::VStack.new(spacing: 12.0)
content << UI::Label.new("Filter")
content << UI::SegmentedControl.new(["All", "Unread"], 0)

glass = UI::GlassBackground.new(content: content, material: :regular)
glass.corner_radius = 12.0
```

**Clear-variant support is planned.** The HIG defines two variants — *regular*
and *clear* — but `GlassBackground` today only exposes the four standard-material
symbols plus `:chrome`. Mapping `:clear` to `UIGlassEffectView.clear` is on the
roadmap; for now, use `:ultra_thin` as the closest approximation over rich media
backgrounds.

### Choosing a material symbol

- `:ultra_thin` — maximum content bleed-through. Use over images/video where the
  content must remain dominant.
- `:thin` — quiet surface for inspectors, tooltips, non-primary popovers.
- `:regular` (default) — the standard "floating above content" feel. Toolbars,
  popovers with text content.
- `:thick` — higher opacity. Sheets, alerts, places where foreground legibility
  trumps content visibility.
- `:chrome` — the heaviest, most opaque. Window chrome on macOS, full-coverage
  overlays.

See `materials.md` for the full decision tree.

### Dark mode and Increase Contrast

Liquid Glass adapts automatically to the system appearance (light/dark) and to
the Increase Contrast setting. `UI::Theme.apple_default` provides color tokens
that work in both appearances. You do not need to manually swap materials when
the user toggles dark mode — the `UIVisualEffectView` / `NSVisualEffectView`
underpinning handles it.

## HIG citations

- **Materials → Liquid Glass**: "Liquid Glass forms a distinct functional layer
  for controls and navigation elements — like tab bars and sidebars — that floats
  above the content layer." (`pages/materials.md`)
- **Materials → Liquid Glass**: "Don't use Liquid Glass in the content layer."
  (`pages/materials.md`)
- **Materials → Liquid Glass**: "Use Liquid Glass effects sparingly. … Limit
  these effects to the most important functional elements in your app."
  (`pages/materials.md`)
- **Color → Best practices**: "provide both light and dark colors to support
  Liquid Glass adaptivity." (`pages/color.md`)
