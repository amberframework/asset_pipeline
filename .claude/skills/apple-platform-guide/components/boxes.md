---
slug: boxes
ui_view: UI::Card
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/boxes.md
validation_report: ../validation/reports/boxes.md
---

# UI::Card

> A box creates a visually distinct group of logically related information
> and components. On macOS the renderer produces an NSStackView backed by
> a CALayer (rounded rect, explicit fill, hairline border); on iOS it
> produces a UIStackView with secondarySystemBackgroundColor fill and
> ~10pt corner radius. Liquid Glass is not applied to boxes on iOS 26 or
> macOS 26 -- they are opaque grouped containers, not surface overlays.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

`UI::Card` is the "grouped surface" primitive. Reach for it when a handful
of logically related labels, rows, or controls should read as one unit --
a shipping-details summary, a settings subsection, a stats tile. The box
draws a bordered or filled rectangle around its children so users perceive
them as a single conceptual group rather than independent items.

It is NOT a navigation surface (use `UI::NavigationLink`), a modal
(use `UI::Sheet`), or a general-purpose rounded rectangle for decoration
(use `UI::RoundedRectangle`). Prefer boxes that are noticeably smaller
than the containing view so the grouping reads; nesting boxes inside
boxes is explicitly discouraged by HIG.

(HIG: "Prefer keeping a box relatively small in comparison with its
containing view. As a box's size gets close to the size of the containing
window or screen, it becomes less effective at communicating the
separation of grouped content." -- Boxes / Best practices.)

## Quickstart

```crystal
require "asset_pipeline/ui"

body = UI::VStack.new(spacing: 8.0)
body << UI::Label.new("Your order ships in a reusable padded mailer.")

row1 = UI::HStack.new(spacing: 12.0)
row1 << UI::Label.new("Carrier")
row1 << UI::Label.new("USPS Ground")
body << row1

row2 = UI::HStack.new(spacing: 12.0)
row2 << UI::Label.new("Estimated arrival")
row2 << UI::Label.new("Apr 17 - Apr 19")
body << row2

card = UI::Card.new(body)
card.title = "Shipping details"
```

Renders: NSStackView (vertical, CALayer, ~10pt corner radius, light-gray
fill in light mode / dark-charcoal fill in dark mode, 0.5pt hairline
border) on macOS; UIStackView (secondarySystemBackgroundColor, ~10pt
corner radius, semibold-17pt title UILabel prepended) on iOS.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `content` | `UI::View?` | `nil` | The single child view hosted inside the box. Wrap multiple children in a `UI::VStack` or `UI::HStack`. |
| `elevation` | `Float64` | `1.0` | Logical shadow depth (0.0 = flush, higher = more prominent). Currently mapped to a faint shadow on macOS; iOS renderer does not yet forward this. |
| `is_outlined` | `Bool` | `false` | When `true`, the card signals an outlined visual style. The CALayer border is always present (0.5pt) in the current macOS renderer; this knob is a placeholder for future border-width variation. HIG: "a box uses a visible border or background color" -- one of these should always be active. |
| `title` | `String?` | `nil` | HIG Content: "Provide a succinct introductory title if it helps clarify the box's contents." On macOS, rendered as an 11pt bold NSTextField at the top of the NSStackView; on iOS, rendered as a 17pt semibold UILabel prepended above the content rows. |
| `material` | `Symbol` | `:secondary` | Selects the iOS grouped-background fill: `:secondary` -> `+[UIColor secondarySystemBackgroundColor]` (HIG default); `:tertiary` -> `+[UIColor tertiarySystemBackgroundColor]`. Ignored on macOS (fill is baked from controlBackgroundColor RGBA at render time). |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. HIG content guidance: "a title can help VoiceOver users predict the content they encounter within the box." Inherited from `UI::View`. |
| `padding` | `UI::EdgeInsets` | `EdgeInsets.new` | Interior padding around the content. HIG Best practices: "Consider using padding and alignment to communicate additional grouping within a box." Inherited from `UI::View`. |

**Theming**: relevant `UI::Theme` tokens are `surface` (card fill reference),
`outline` (border color reference), and `on_surface` (default label color
inside the card). See `foundations/color-and-theming.md`.

## Light / dark appearance notes

Boxes are a grouped-surface primitive -- they are NOT glass-backed. They
use opaque fills drawn into a CALayer (macOS) or a UIStackView layer (iOS),
both of which must use baked or appearance-tracking colors to render
correctly.

**macOS:**
The renderer reads `ENV["HIG_APPEARANCE"]` at render time and bakes an
appropriate RGBA into `layer.backgroundColor`: light ~0.970 RGB (matching
NSColor.controlBackgroundColor light value); dark ~0.145 RGB (matching
NSColor.controlBackgroundColor dark value). The title and content labels
use `nscolor_label_primary` (`[NSColor labelColor]`), which tracks the
system appearance dynamically and resolves to near-black in light and
near-white in dark. The border uses an explicit RGBA baked from the
appearance: 0.78 gray in light, 0.35 gray in dark.

The layer fill is baked at renderer startup -- if system appearance changes
at runtime after the view is created, the layer fill will not update. For
production apps that need live tracking, subclass NSStackView and override
`updateLayer` to read `NSColor.controlBackgroundColor.CGColor` inside the
`performAsCurrentDrawingAppearance:` block.

**iOS:**
`UIColor.secondarySystemBackgroundColor` is a true dynamic system color.
It resolves light-gray (~0.95 RGB) in light mode and dark-gray (~0.11 RGB)
in dark mode. The UIStackView layer picks this up automatically because
UIKit's `layoutSubviews` runs within the correct appearance context.
Title and content label text use `UIColor.labelColor` which also
tracks automatically. No explicit appearance-mode baking is needed on iOS.

**SF Symbols:** `UI::Card` does not currently use SF Symbols. If content
views inside the card include SF Symbols, they use the monochrome
rendering by default and track the system tint color.

**Contrast caveats:** If you override `material` to `:tertiary` on iOS in
dark mode, `tertiarySystemBackgroundColor` is lighter than secondary. This
can reduce contrast between card fill and the system background if the
background is already dark. Prefer `:secondary` unless the design
explicitly calls for the lighter tertiary surface.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
theme = UI::Theme.apple_default
theme.primary = UI::ThemeColor.new(r: 0.85, g: 0.14, b: 0.32)  # brand red
# Affects any UI::Button or tinted element placed inside the card.
# The card fill itself remains the HIG-default neutral system gray --
# that is intentional; the box chrome should recede so content reads.
```

**Replace the card background with a flat brand color (loses appearance tracking).**
```crystal
# Boxes are not a glass surface -- this replaces the system-gray fill:
theme.surface = UI::ThemeColor.new(r: 0.12, g: 0.12, b: 0.14)  # brand dark
# Trade-off: baked RGBA does not resolve differently in light vs dark.
# Either supply separate light/dark variants keyed on the app's current
# appearance, or accept a fixed appearance and set `is_outlined = true`
# so the grouping reads in both modes via the border rather than fill.
```

**Override typography while keeping HIG spacing.**
```crystal
theme.font_family = "YourBrand-Serif"
theme.font_size_body = 17.0   # keep HIG body size (17pt iOS, 13pt macOS)
# Do NOT reduce corner_radius_medium below ~8pt on iOS -- the HIG
# inset-grouped style expects ~10pt rounded corners (Theme.apple_default
# corner_radius_medium = 10pt). Reducing to 0pt removes the
# "grouped container" semantic and makes the card read as a flat stripe.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a summary card with a header line and two label/value rows"**
Compose a `VStack` as `content`; put the header as the first label,
then `HStack` for each row. Keep the card narrower than the parent view:
```crystal
body = UI::VStack.new(spacing: 8.0)
body << UI::Label.new("Order summary")
row = UI::HStack.new(spacing: 12.0)
row << UI::Label.new("Total")
row << UI::Label.new("$42.00")
body << row
card = UI::Card.new(body)
```
(HIG: "The appearance of a box helps people understand that its contents
are related." -- Boxes / Content.)

**"I want a settings-pane subsection with a colon-suffixed title"**
Pass a title phrase with a trailing colon per HIG settings-pane convention.
Use the first-class `title` knob (no need to fake it with a leading label):
```crystal
body = UI::VStack.new(spacing: 8.0)
body << UI::Toggle.new("Allow sounds", true)
body << UI::Toggle.new("Show previews", false)
card = UI::Card.new(body)
card.title = "Notifications:"
```
(HIG: "Avoid ending punctuation unless you use a box in a settings pane,
where you append a colon to the title." -- Boxes / Content.)

## What happens on each platform
- **iOS 26**: `UIStackView` (vertical axis, 8pt spacing, fill alignment,
  `isLayoutMarginsRelativeArrangement = YES`,
  `backgroundColor = secondarySystemBackgroundColor` or
  `tertiarySystemBackgroundColor` when `material: :tertiary`,
  `layer.cornerRadius = 10`, `clipsToBounds = YES`). When `title` is
  set, a semibold 17pt `UILabel` with `UIColor.labelColor` is prepended
  as the first arranged subview.
  Source: `src/ui/renderers/uikit_renderer.cr`, `visit(UI::Card)`.
- **iPadOS 26**: Same as iOS.
- **macOS 26**: `NSStackView` (vertical, `wantsLayer = YES`, 8pt spacing,
  leading alignment). Layer has `cornerRadius = 10`, explicit
  appearance-baked `backgroundColor` (light: ~0.970 RGB, dark: ~0.145 RGB),
  and a 0.5pt `borderWidth` with appearance-baked `borderColor`
  (light: 0.78 gray, dark: 0.35 gray). When `title` is set, an 11pt bold
  `NSTextField` with `NSColor.labelColor` is prepended as the first
  arranged subview.
  Source: `src/ui/renderers/appkit_renderer.cr`, `visit(UI::Card)`.

## HIG citations (validated)
- Boxes -> Abstract: "A box creates a visually distinct group of logically
  related information and components."
- Boxes -> Best practices: "By default, a box uses a visible border or
  background color to separate its contents from the rest of the
  interface. A box can also include a title."
- Boxes -> Best practices: "Prefer keeping a box relatively small in
  comparison with its containing view. As a box's size gets close to the
  size of the containing window or screen, it becomes less effective at
  communicating the separation of grouped content, and it can crowd other
  content."
- Boxes -> Content: "Provide a succinct introductory title if it helps
  clarify the box's contents. The appearance of a box helps people
  understand that its contents are related, but it might make sense to
  provide more detail about the relationship. Also, a title can help
  VoiceOver users predict the content they encounter within the box."
- Boxes -> Platform considerations -> iOS, iPadOS: "By default, iOS and
  iPadOS use the secondary and tertiary background colors in boxes."
- Boxes -> Platform considerations -> macOS: "By default, macOS displays
  a box's title above it."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/boxes.md](../validation/reports/boxes.md)

## Related
- `UI::Surface` -- when you want an elevated rectangular area without the
  "box" semantic grouping (no border, no title).
- `UI::GlassBackground` -- when the group should adopt Liquid Glass
  material rather than the standard secondary-background fill.
- `UI::Divider` -- when content within a box needs a hairline separator
  rather than a nested box; HIG explicitly warns against nested boxes.
- `UI::VStack` / `UI::HStack` -- standard composition primitives for the
  `content` child.
