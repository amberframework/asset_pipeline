---
title: Materials
topic: materials
hig_pages:
  - materials.md
---

# Materials

## What it means

A *material* is a visual effect that creates depth and hierarchy between
foreground and background elements by letting color pass through from behind. On
Apple platforms there are two classes of material:

- **Liquid Glass** — dynamic, floats above content. See `liquid-glass.md` for
  when to reach for this specifically. iOS 26 / macOS 26 only.
- **Standard materials** — `ultra-thin`, `thin`, `regular`, `thick`. Used
  *within* the content layer to create visual distinction between groupings. All
  Apple platforms.

The two are not interchangeable. Liquid Glass signals "this sits above content";
standard materials signal "this is content, separated from other content." If
you pick the wrong layer, the hierarchy reads wrong.

## The standard material symbol palette

asset_pipeline's `UI::GlassBackground` accepts these symbols (source:
`src/ui/views/glass_background.cr`):

| Symbol | Use when | Maps to (iOS) | Maps to (macOS) |
|--------|----------|---------------|-----------------|
| `:ultra_thin` | Over rich media where content must remain dominant | `UIBlurEffect.Style.systemUltraThinMaterial` | `NSVisualEffectMaterial.hudWindow` (closest) |
| `:thin` | Quiet inspector / tooltip surface | `UIBlurEffect.Style.systemThinMaterial` | `NSVisualEffectMaterial.sidebar` |
| `:regular` | Default floating control surface (toolbars, popovers with text) | `UIBlurEffect.Style.systemMaterial` | `NSVisualEffectMaterial.menu` |
| `:thick` | Sheets and alerts where foreground legibility dominates | `UIBlurEffect.Style.systemThickMaterial` | `NSVisualEffectMaterial.windowBackground` |
| `:chrome` | Heavy, opaque chrome (window title bar on macOS) | `UIBlurEffect.Style.systemChromeMaterial` | `NSVisualEffectMaterial.titlebar` |

The exact mapping lives in the renderer; see `glass-effects` skill for the
ObjC-level selector table, and `platform-renderers` for where the visitor methods
live.

### iOS 26 Liquid Glass automatic material selection

On iOS 26, when you place a standard `UIViewController`-based component
(toolbar, tab bar, popover presentation controller), the system picks the
correct Liquid Glass variant for you. If you wrap a custom view in
`UI::GlassBackground`, the renderer:

1. If the SDK supports `UIGlassEffectView`, uses the regular variant for
   `:regular`/`:thick`/`:chrome` and the system-thin variant for
   `:thin`/`:ultra_thin`.
2. Otherwise falls back to `UIVisualEffectView + UIBlurEffect` with the mapping
   above.

You don't need to feature-detect in Crystal — the renderer does it.

## How it's expressed in asset_pipeline

```crystal
# Wrap content in a thin material for a quiet inspector feel
content = UI::Label.new("Tap and hold for options")
wrapped = UI::GlassBackground.new(content: content, material: :thin)
wrapped.corner_radius = 10.0
wrapped.padding = UI::EdgeInsets.new(top: 8.0, trailing: 12.0, bottom: 8.0, leading: 12.0)
```

`is_vibrant` on `GlassBackground` (default `true`) controls whether the renderer
applies a vibrancy effect (`UIVibrancyEffect` / `NSVisualEffectView` with
vibrancy) on labels inside the material. The HIG says: "use vibrant colors on
top of materials" to ensure legibility; keep `is_vibrant: true` unless you have
a specific reason to opt out.

There is no per-material theme token today — the palette is fixed by the five
symbols above. A theme-level "material preset" (e.g. `theme.popover_material =
:thin`) is planned.

## Choosing a material

Two variables to weigh, per the HIG:

- **Thicker materials (`:thick`, `:chrome`) → better contrast.** Good for text
  and fine features that must remain crisp.
- **Thinner materials (`:thin`, `:ultra_thin`) → better context retention.**
  The user keeps a sense of what's behind the material.

Default to `:regular`. Move thinner when content behind matters
(photo-browsing, map views). Move thicker when the foreground is information-
dense (alerts, forms inside a sheet).

## HIG citations

- **Materials → Standard materials**: "Choose materials and effects based on
  semantic meaning and recommended usage." (`pages/materials.md`)
- **Materials → Standard materials**: "Help ensure legibility by using vibrant
  colors on top of materials." (`pages/materials.md`)
- **Materials → Platform considerations → iOS, iPadOS**: the four-level standard
  material palette (ultraThin / thin / regular / thick). (`pages/materials.md`)
- **Materials → Liquid Glass**: regular variant "blurs and adjusts the luminosity
  of background content to maintain legibility"; clear variant "ideal for
  prioritizing the visibility of the underlying content." (`pages/materials.md`)
