---
slug: image-wells
ui_view: UI::ImageWell
priority: P2
platforms: [macOS, iOS, iPadOS]
hig_page: ../../../apple-hig/pages/image-wells.md
validation_report: ../validation/reports/image-wells.md
---

# UI::ImageWell

> A framed image drop target for avatars, artwork, or document thumbnails. The
> default taste should feel orderly and dependable: one clear well, one clear
> preview, and obvious room for replacement.

## Feel of the flow

Use `UI::ImageWell` when the job is to set or replace one image, not browse a
gallery. Good image wells feel more like a field than a canvas. The boundary is
part of the meaning: this is where the chosen image lives, and this is where a
new one can be dropped in.

Apple’s HIG roots this in macOS `NSImageWell`. Our shared primitive starts as a
portable fallback surface so the shard can model that workflow before the
native drag-and-drop bridge lands.

## Quickstart

```crystal
well = UI::ImageWell.new(
  "profile-preview",
  "Profile image",
  "Drop a new image here",
  "Square crop recommended",
  "PNG, JPEG, or HEIC"
)
well.accessibility_label = "Profile image well"
```

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `image_source` | `String?` | `nil` | Named preview image shown inside the well. |
| `placeholder_icon` | `String` | `"photo"` | Symbol-like placeholder shown when no image is present. |
| `label` | `String?` | `nil` | Optional title above the well. |
| `prompt` | `String?` | `nil` | Optional secondary instruction above the well. |
| `caption` | `String?` | `nil` | Supporting text below the well. |
| `help_text` | `String?` | `nil` | Secondary help copy below the caption. |
| `well_width` | `Float64` | `240.0` | Width of the preview well. |
| `well_height` | `Float64` | `180.0` | Height of the preview well. |
| `preview_padding` | `UI::EdgeInsets` | `18/18/18/18` | Interior space between the well edge and preview content. |

## Light / dark appearance notes

The well boundary must stay visible in both appearances or the control stops
feeling like a field. Empty-state icons should read as guidance, not decoration,
and a filled preview should still leave enough frame around the image to imply
replaceability. Dark mode especially should preserve the border and field shape
instead of turning the preview into a floating loose image.

## Customization / brand override

Brand work should usually happen through the surrounding copy, image choice, and
subtle neutral tinting of the well. Keep the field shape clear. When the border
gets too faint or the preview image fills the entire area with no inset, the
component loses its “drop target” feeling and starts reading like a plain image
view.

## What happens on each platform

- **macOS 26**: Currently rendered through the shared fallback well while a
  future native `NSImageWell` bridge remains open.
- **iOS 26 / iPadOS 26**: Rendered through the same fallback surface. Apple
  does not offer a direct iOS `NSImageWell` peer, so the field metaphor remains
  a portable approximation for now.

## HIG citations (validated)

- Image wells are used to display and replace a single image.
- The well should preserve a strong field boundary and make replacement feel
  straightforward.

Validation report:
[validation/reports/image-wells.md](../validation/reports/image-wells.md)

## Related

- `UI::Image` and `UI::AsyncImage` for plain image presentation.
- `UI::Button` or `UI::IconButton` for explicit choose/change actions paired
  with the well.
