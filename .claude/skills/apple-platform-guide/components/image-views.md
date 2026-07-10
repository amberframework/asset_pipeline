---
slug: image-views
ui_view: UI::AsyncImage
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/image-views.md
validation_report: ../validation/reports/image-views.md
---

# UI::AsyncImage

> An image view displays a single image on a transparent or opaque background;
> on iOS 26 and macOS 26 the view renders as NSImageView (AppKit) or
> UIImageView (UIKit) with no glass material -- image views are content
> components, not surface components, so Liquid Glass is not applied.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

Image views are the primary vehicle for displaying photographic content,
illustrations, and template icons inside a layout. They sit inside other
containers (HStack, VStack, List rows, Card surfaces) and present a single
image scaled to fit, fill, or stretch the allocated space. Image views are
typically not interactive -- HIG is explicit: "In rare cases where you might
want an image to be interactive, configure a system-provided button to display
the image instead of adding button behaviors to an image view."

Reach for `UI::AsyncImage` when the image source is a URL fetched at runtime
(async, with loading and error states). Reach for `UI::Image` when the source
is a named asset from the app bundle (synchronous, no loading state). For
icons and glyphs, use `UI::Image.new("symbol.name")` with `tint_color` set;
for interactive icon buttons, use `UI::IconButton` instead.

(HIG: "Use an image view when the primary purpose of the view is simply to
display an image." -- Image views / Best practices.)

## Quickstart

```crystal
# Named asset from the bundle (synchronous):
logo = UI::Image.new("AppLogo")
logo.content_mode = ContentMode::Fit

# SF Symbol tinted (symbol_name branch planned; imageNamed: works for
# NSImage named constants but not for SF Symbol system names):
star = UI::Image.new("star.fill")
star.tint_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)

# URL-backed image with loading and error states (async):
avatar = UI::AsyncImage.new("https://example.com/avatar.jpg")
avatar.is_loading = false  # set true to show placeholder spinner

# Rounded thumbnail with clip:
thumb = UI::AsyncImage.new("https://cdn.example.com/photo.jpg")
thumb.corner_radius = 12.0
thumb.clip_to_bounds = true
thumb.border_width = 1.0
thumb.border_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.62)
```

Renders: `NSImageView` on macOS (AppKit) and `UIImageView` on iOS (UIKit).
No Liquid Glass material -- image views are content, not surface components.
The `content_mode` property maps to `NSImageScaling` on macOS and
`UIViewContentMode` on iOS.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `url` | `String` | `""` | Remote URL for async image loading. URLSession bridge not yet wired; URL is stored but not fetched in current renderer. |
| `content_mode` | `ContentMode` | `ContentMode::Fit` | Scale mode. `Fit` = proportional fit (NSImageScaleProportionallyDown / UIViewContentModeScaleAspectFit). `Fill` = aspect fill with clipping. `Stretch` = axes-independent fill. |
| `is_loading` | `Bool` | `false` | Marks the view as loading; showcase arm renders ActivityIndicator + label when true. |
| `error_message` | `String?` | `nil` | When set marks the view as failed; showcase arm renders gray placeholder. |
| `placeholder` | `View?` | `nil` | View to display while loading or on error (bridge not yet wired). |
| `tint_color` | `Color?` | `nil` | On `UI::Image`: template image tint. Maps to `contentTintColor` (NSImageView, macOS 10.14+) and `tintColor` (UIImageView). Explicit RGBA -- does not track appearance. |
| `corner_radius` | `Float64` | `0.0` | Base `UI::View` property. Applied to `CALayer.cornerRadius` by `apply_common_properties` in both renderers. Use with `clip_to_bounds = true` for rounded or circular clips. |
| `clip_to_bounds` | `Bool` | `false` | Base `UI::View` property. Sets `clipsToBounds` (UIKit) / `wantsLayer` + `masksToBounds` (AppKit) on the image view's layer. |
| `border_width` | `Float64` | `0.0` | Base `UI::View` property. Applied to `CALayer.borderWidth`. |
| `border_color` | `Color?` | `nil` | Base `UI::View` property. Applied to `CALayer.borderColor`. |

**Theming**: no image-view-specific `UI::Theme` tokens. Use
`Theme.apple_default.corner_radius_small` (6pt), `.corner_radius_medium`
(10pt), or `.corner_radius_large` (20pt) for consistent rounding across the
theme. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

Image views are content views. Their appearance adapts through the image
asset's own appearance variants (dark-mode asset catalog variants) rather than
through glass material or color token resolution. Key per-appearance behaviors:

**Tint color.** The `tint_color` property on `UI::Image` is an explicit RGBA
value. It does NOT track appearance automatically. In light mode system blue is
approximately 0.0/0.478/1.0 RGBA; in dark mode the system-resolved blue is
approximately 0.039/0.518/1.0 RGBA (slightly lighter for contrast on dark
backgrounds). If you set a fixed `tint_color`, that RGBA appears identically
in both light and dark appearances. For appearance-tracking tint, leave
`tint_color = nil` on a template image inside UIImageView -- UIKit then
inherits the parent's `tintColor` (UIColor.systemBlue by default), which IS
appearance-tracking. The planned `symbol_name` property will use
`UIImage(systemName:)` which inherits tintColor automatically.

**Background.** The base `view.background` property (via `apply_common_properties`)
sets a literal RGBA on `CALayer.backgroundColor`. This is a fixed color that
does not track appearance. Setting `background = Color.new(r:0.82, g:0.82, b:0.84)`
produces light gray in BOTH light and dark mode. For appearance-tracking placeholder
backgrounds, use the `UI::GlassBackground` view as a wrapper, or wait for
semantic background tokens (planned).

**Corner radius and clipping.** `corner_radius` and `clip_to_bounds` apply via
CALayer in both renderers, independent of appearance. Circular avatar pattern:
`corner_radius = diameter / 2.0` + `clip_to_bounds = true`. The tan-filled
avatar rendered in validation has 0.69/0.56/0.49 fill -- ~4.5:1 contrast on
dark window (macOS dark), ~3:1 on light window (adequate for a fill-shape
not carrying informational text).

**SF Symbol variants (planned).** Once `symbol_name` is wired, SF Symbols will
render in the variant appropriate for the appearance: filled vs outline,
monochrome vs hierarchical, as configured by the symbol's weight/scale/variant.
The `tint_color` override should supply the monochrome tint; leave it nil to
inherit `tintColor` from the UIView hierarchy for automatic appearance tracking.

**Contrast caution.** Image views are transparent by default (no `background`).
A low-contrast image placed directly on white `UIColor.systemBackground` (light)
or near-black (dark) without a border or shadow loses its boundary in the
appearance where the image background is closest to the system background color.
Add `border_width = 0.5` + `border_color` (a 0.6 gray) or a subtle shadow to
define the image boundary in both appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Tint an SF Symbol to your brand primary.**
```crystal
# tint_color is an explicit RGBA -- set it to your brand color.
# What to keep HIG-default: the symbol shape, intrinsic size, padding.
# What can safely change: the RGBA tint.
icon = UI::Image.new("star.fill")
icon.tint_color = UI::Color.new(r: 0.88, g: 0.22, b: 0.41)  # brand rose

# Caution: if brand rose is near-black on dark background, verify contrast
# in dark mode separately. System blue auto-adjusts for dark; a fixed rose
# RGBA does not.
```

**Apply a rounded-thumbnail clip shape for a card image.**
```crystal
# corner_radius + clip_to_bounds on the base UI::View are the knobs.
# No separate clip_shape property exists on UI::AsyncImage (see gaps.md iter 29).
thumb = UI::AsyncImage.new("https://cdn.example.com/photo.jpg")
thumb.corner_radius = 12.0      # matches Theme.apple_default.corner_radius_medium
thumb.clip_to_bounds = true
thumb.border_width = 0.5
thumb.border_color = UI::Color.new(r: 0.6, g: 0.6, b: 0.62)

# The 0.5pt border and corner_radius apply in both light and dark.
# border_color is a fixed RGBA -- choose a value that reads on both
# light and dark backgrounds (a mid-gray 0.6 works in both).
```

**Override the placeholder surface with a flat brand color.**
```crystal
# While is_loading = true, show a brand-colored skeleton surface.
# background is the only knob for this (Liquid Glass not used on image views).
skeleton = UI::AsyncImage.new("")
skeleton.is_loading = true
skeleton.background = UI::Color.new(r: 0.93, g: 0.88, b: 0.97)  # brand lavender
skeleton.corner_radius = 12.0

# Warning: background is a fixed RGBA. In dark mode this lavender may
# appear over-saturated against near-black UIColor.systemBackground.
# Verify contrast in dark mode: 0.93 lavender on 0.11 dark background
# = approximately 6:1 -- legible but test with your specific brand colors.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a circular user avatar with a white border"**
-> Set `corner_radius = diameter / 2.0` and `clip_to_bounds = true` on the
   image view. Set `border_width = 2.0` and `border_color = Color.new(r:1.0,
   g:1.0, b:1.0)` for a white ring. Wrap in a container sized to the
   intended diameter so the image view has explicit bounds.

**"I want a photo grid thumbnail with rounded corners matching the HIG card pattern"**
-> Set `corner_radius = 12.0` (or `Theme.apple_default.corner_radius_medium`),
   `clip_to_bounds = true`, `content_mode = ContentMode::Fill`,
   `border_width = 0.5`, `border_color = Color.new(r:0.6, g:0.6, b:0.62)`.
   This matches the iOS Photos and Music album thumbnail pattern.

## What happens on each platform
- **iOS 26**: `UIImageView`. `setImage:` loads from the bundle via `UIImage
  imageNamed:`. `setContentMode:` maps ContentMode to UIViewContentMode. `setTintColor:`
  applies for template images. `setClipsToBounds:1` is set automatically when
  `content_mode = ContentMode::Fill`. No Liquid Glass material.
- **iPadOS 26**: Same as iOS 26. Image wells (drag-drop editable image views)
  require a separate `UI::ImageWell` view (not yet implemented, P2).
- **macOS 26**: `NSImageView`. `setImage:` loads from bundle via `NSImage
  imageNamed:` (named assets only; SF Symbol loading requires
  `NSImage(systemSymbolName:accessibilityDescription:)`, planned). `setImageScaling:`
  maps ContentMode. `setContentTintColor:` maps tint (macOS 10.14+). Editable
  image views (image well pattern, HIG macOS) not yet wired. No Liquid Glass material.

## HIG citations (validated)
- Image views -- Best practices: "Use an image view when the primary purpose
  of the view is simply to display an image."
- Image views -- Best practices: "If you want to display an icon in your
  interface, consider using a symbol or interface icon instead of an image
  view. SF Symbols provides a large library of streamlined, vector-based images
  that you can render with various colors and opacities. An icon (also called a
  glyph or template image) is typically a bitmap image in which the
  nontransparent pixels can receive color. Both symbols and interface icons can
  use the accent colors people choose."
- Image views -- Content: "Take care when overlaying text on images.
  Compositing text on top of images can decrease both the clarity of the image
  and the legibility of the text. To help improve the results, ensure the text
  contrasts well with the image, and consider ways to make the text object
  stand out, like adding a text shadow or background layer."
- Image views -- Content: "Aim to use a consistent size for all images in an
  animated sequence. When you prescale images to fit the view, the system
  doesn't have to perform any scaling."
- Image views -- Platform considerations -- macOS: "If your app needs an
  editable image view, use an image well. An image well is an image view that
  supports copying, pasting, dragging, and using the Delete key to clear its
  content."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/image-views.md](../validation/reports/image-views.md)

## Related
- `UI::Image` -- synchronous named-asset variant; use for bundle resources and
  SF Symbols (symbol_name wiring planned, see gaps.md iter 29).
- `UI::IconButton` -- when the image should be interactive (tappable).
- `UI::GlassBackground` -- maps to NSVisualEffectView / UIVisualEffectView;
  use when an image appears behind a translucent Liquid Glass surface.
- `recipes/photo-grid.md` -- multi-column photo grid pattern combining
  AsyncImage tiles with a grid layout container.
