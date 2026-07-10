---
slug: labels
ui_view: UI::Label
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/labels.md
validation_report: ../validation/reports/labels.md
---

# UI::Label

> A label is a static piece of text that people can read and often copy,
> but not edit. `UI::Label` is the atomic text-display primitive in
> asset_pipeline -- it emits `NSTextField` (non-editable) on macOS and
> `UILabel` on iOS/iPadOS with no Liquid Glass backing (labels are text
> glyphs, not surfaces), using `LabelRole` semantic color tokens that
> track light and dark appearance automatically.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A `UI::Label` is the component you reach for whenever you need to place
non-editable text on screen. It is the title of a screen, the caption
under an image, the value in a "name: value" row, the error message next
to a failing control, the secondary annotation under a headline. It is
NOT a text input (use `UI::TextField` for a short editable string or
`UI::TextEditor` for long-form text), and it is NOT a button label (the
text inside a `UI::Button` is authored as the button's `title` argument).

The semantic-color system is the key design principle: HIG defines four
label colors that vary in appearance (Primary, Secondary, Tertiary,
Quaternary) to communicate relative visual importance. `UI::Label`
implements this through `text_color_role : LabelRole?` which resolves at
render time to the platform's dynamic system color -- tracking light,
dark, and Increase Contrast automatically with zero per-call work.

(HIG: *"Use system-provided label colors to communicate relative
importance. The system defines four label colors that vary in appearance
to help you give text different levels of visual importance."* -- Labels /
Best practices.)

## Quickstart

```crystal
require "asset_pipeline/ui"

# 8-row gallery demonstrating all four LabelRole semantic color tokens
# and the HIG text-size ladder approximated via UI::Font size + weight.

ladder = UI::VStack.new(spacing: 10.0)

# Row 1: Large Title -- Primary, 34pt Bold
title = UI::Label.new("The quick brown fox")
title.font = UI::Font.new(size: 34.0, weight: :bold)
title.text_color_role = UI::LabelRole::Primary   # default; shown explicitly
ladder << title

# Row 2: Headline -- Primary, 17pt Semibold
headline = UI::Label.new("The quick brown fox")
headline.font = UI::Font.new(size: 17.0, weight: :semibold)
headline.text_color_role = UI::LabelRole::Primary
ladder << headline

# Row 5: Subheadline -- Secondary, 15pt Semibold
subhead = UI::Label.new("The quick brown fox")
subhead.font = UI::Font.new(size: 15.0, weight: :semibold)
subhead.text_color_role = UI::LabelRole::Secondary
ladder << subhead

# Row 6: Footnote -- Tertiary, 13pt Regular
footnote = UI::Label.new("The quick brown fox")
footnote.font = UI::Font.new(size: 13.0, weight: :regular)
footnote.text_color_role = UI::LabelRole::Tertiary
ladder << footnote

# Row 7: Caption / Watermark -- Quaternary, 12pt Regular
caption = UI::Label.new("THE QUICK BROWN FOX")
caption.font = UI::Font.new(size: 12.0, weight: :regular)
caption.text_color_role = UI::LabelRole::Quaternary
ladder << caption

# Row 8: Multi-line Body -- Primary, 17pt Regular, unlimited lines
body = UI::Label.new("The quick brown fox jumps over the lazy dog. Pack my box with five dozen liquor jugs.")
body.font = UI::Font.new(size: 17.0, weight: :regular)
body.text_color_role = UI::LabelRole::Primary
body.number_of_lines = 0
ladder << body
```

Renders: `UILabel` on iOS/iPadOS; `NSTextField` (isEditable: NO,
setBordered: NO, setDrawsBackground: NO) on macOS. No Liquid Glass
material -- labels are text glyphs, not surfaces. `LabelRole` tokens
route to `NSColor.labelColor` / `UIColor.labelColor` and their four
tiered counterparts, tracking appearance automatically.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `text` | `String` | (constructor) | The displayed string. Pass via `UI::Label.new(text)`. |
| `text_color_role` | `UI::LabelRole?` | `LabelRole::Primary` | Semantic Apple label-color role. When set, the renderer resolves to `NSColor.labelColor` / `UIColor.labelColor` and siblings at render time, tracking appearance (light/dark/Increase Contrast) automatically. Set to `nil` to opt into the explicit `text_color` RGBA instead. |
| `text_color` | `UI::Color` | `Color(0,0,0)` | Brand/explicit RGBA override. Only consulted when `text_color_role` is nil. Setting this without clearing `text_color_role` has no effect -- the role takes priority. |
| `font` | `UI::Font` | `Font.new(family: "system", size: 17.0, weight: :regular)` | System font, 17pt Regular (HIG Body). HIG ladder sizes: Large Title 34 Bold / Headline 17 Semibold / Body 17 / Callout 16 / Subheadline 15 Semibold / Footnote 13 / Caption 12. See "Light / dark appearance notes" for Dynamic Type gap. |
| `text_alignment` | `UI::Alignment` | `Alignment::Leading` | Leading / Center / Trailing. HIG expects leading for prose; center for titles over cards. |
| `number_of_lines` | `Int32` | `0` | Maximum line count. `0` means unlimited (maps to `UILabel.numberOfLines = 0` and NSTextField cell `usesSingleLineMode = NO`). Required for any label whose text may wrap. |
| `accessibility_label` | `String?` | `nil` (inherits `text`) | VoiceOver label override. Inherited from `UI::View`. Set when the visible text is a glyph, abbreviation, or visual-only decoration. |

**Theming**: `UI::Theme.apple_default` provides `font_family`,
`font_size_body` (17.0), `font_size_title` (22.0), `font_size_headline`
(28.0), `font_size_caption` (12.0). The four semantic label-color roles
(`label_primary`, `label_secondary`, `label_tertiary`, `label_quaternary`)
are stored on `UI::Theme` as symbolic `LabelRole` values; the renderers
own the lookup to platform system colors. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::Label` is not a glass-backed surface -- it carries no NSVisualEffectView
/ UIVisualEffectView. Appearance-tracking comes entirely from the
`text_color_role` color-token system. Here is how each role resolves:

**macOS (AppKit):**
- `LabelRole::Primary` -> `NSColor.labelColor`. Light: near-black (~0.0
  RGBA). Dark: near-white (~0.92 RGBA). System Increase Contrast: increases
  opacity (color becomes fully opaque). Estimated contrast ~15:1 (light),
  ~18:1 (dark).
- `LabelRole::Secondary` -> `NSColor.secondaryLabelColor`. Light: medium
  gray (~0.55 RGBA). Dark: off-white (~0.60 RGBA). Contrast ~4:1 (light),
  ~5:1 (dark). Correct for subheadings and supplemental text.
- `LabelRole::Tertiary` -> `NSColor.tertiaryLabelColor`. Light: light gray
  (~0.70 RGBA). Dark: medium gray (~0.40 RGBA). Contrast ~3:1 (light),
  ~3.5:1 (dark). Suitable for supplemental detail (Footnote role).
- `LabelRole::Quaternary` -> `NSColor.quaternaryLabelColor`. Light: very
  light gray (~0.82 RGBA). Dark: dim gray (~0.25 RGBA). Intentionally
  low-contrast -- HIG designates this for watermark and metadata text.
  Contrast ~1.5:1 (light), ~2:1 (dark). Not for body copy.

**iOS/iPadOS (UIKit):**
- `LabelRole::Primary` -> `UIColor.labelColor`. Light: near-black. Dark:
  near-white. Same semantic as macOS.
- `LabelRole::Secondary` -> `UIColor.secondaryLabelColor`. Light: medium
  gray. Dark: off-white gray.
- `LabelRole::Tertiary` -> `UIColor.tertiaryLabelColor`. Light/Dark:
  corresponding dim grays.
- `LabelRole::Quaternary` -> `UIColor.quaternaryLabelColor`. Watermark.

**Font weight in dark mode:** `NSTextField` and `UILabel` do not
auto-thin typography in dark mode on current Apple SDKs. The validation
captures (macOS dark, iteration 19) confirm Bold at 34pt and Semibold at
17pt retain their weight correctly in DarkAqua appearance.

**Brand override legibility caution:** If a developer sets
`text_color_role = nil` and supplies a baked RGBA brand color, that color
will NOT adapt to dark mode. A brand color chosen for a light background
(e.g. dark slate `Color(0.1, 0.1, 0.2)`) will become nearly invisible on
a dark UIColor.systemBackground or DarkAqua NSColor.windowBackgroundColor.
Always test any baked `text_color` override in both appearances before
shipping.

**Dynamic Type:** `UI::Label` does not yet support Dynamic Type. `font.size`
routes to `systemFontOfSize:` (a fixed-point call), not
`preferredFont(forTextStyle:)`. Users with accessibility Text Size
preferences will not see the label resize. This is the open gap from
gaps.md iteration 12; a `font_style : Symbol?` knob is planned to close it.
See gaps.md for the proposal.

**SF Symbol variants:** Labels do not render SF Symbols -- use `UI::Image`
with `symbol_name` for icon glyphs. The row-header labels in the gallery
use 12pt Secondary for contrast demonstration only.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Use a brand primary color for accent text while keeping system labels.**
```crystal
# HIG body copy and navigation labels use LabelRole (appearance-tracked).
# Reserve explicit text_color for brand-colored accent labels only.
body = UI::Label.new("Shipped on April 14")
body.font = UI::Font.new(size: 17.0, weight: :regular)
body.text_color_role = UI::LabelRole::Primary   # tracks dark mode

accent = UI::Label.new("View details")
accent.font = UI::Font.new(size: 17.0, weight: :semibold)
accent.text_color_role = nil                    # opt out of system role
accent.text_color = UI::Color.new(r: 0.12, g: 0.47, b: 0.71)  # brand blue
# WARNING: baked text_color does NOT track dark mode -- verify contrast
# against both UIColor.systemBackground light (~1.0) and dark (~0.0).
```

**Replace system hierarchy with a flat brand voice.**
```crystal
# Use text_color_role = nil and a single brand color throughout.
# Trade-off: loses automatic dark-mode adaptation; you own both modes.
label = UI::Label.new("Order confirmed")
label.font = UI::Font.new(family: "YourBrand-Display", size: 28.0, weight: :bold)
label.text_color_role = nil
label.text_color = UI::Color.new(r: 0.08, g: 0.08, b: 0.10)  # brand near-black
# Pair with a light-mode container. Test dark appearance explicitly --
# this baked near-black will be invisible on UIColor.systemBackground dark.
```

**Override typography while keeping HIG-role colors.**
```crystal
# Substitute a brand font via UI::Font.new(family:) while preserving
# the semantic LabelRole color system for automatic appearance tracking.
theme = UI::Theme.apple_default
theme.font_family = "YourBrand-Sans"
# Keep HIG ladder sizes -- these are the accessibility floor:
theme.font_size_body     = 17.0   # HIG Body
theme.font_size_title    = 22.0   # HIG Title 2
theme.font_size_headline = 28.0   # HIG Title 1
theme.font_size_caption  = 12.0   # HIG Caption 1

# Per-label: keep size+role, swap family:
subhead = UI::Label.new("Section header")
subhead.font = UI::Font.new(family: "YourBrand-Sans", size: 15.0, weight: :semibold)
subhead.text_color_role = UI::LabelRole::Secondary  # still appearance-tracked
# This gives brand typography with automatic dark-mode color adaptation.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a screen title with a supporting subtitle"**
-> Build a `UI::VStack.new(spacing: 4.0)`. Push a Large Title label
(`size: 34.0, weight: :bold, text_color_role: Primary`). Push a
Subheadline label (`size: 15.0, weight: :regular,
text_color_role: Secondary`). The Secondary role automatically dims the
subtitle relative to the title in both light and dark.
HIG: *"Use system-provided label colors to communicate relative importance."*

**"I want a metadata watermark under a card"**
-> Set `text_color_role = UI::LabelRole::Quaternary` on a 12pt Regular
label. The quaternary color is intentionally very faint -- correct for
metadata like "3 items" or a version stamp. Do not use quaternary for
body copy that users must read. HIG: *"quaternaryLabel -- Watermark text."*

## What happens on each platform
- **iOS 26**: `UILabel` via `alloc` + `initWithFrame:`. `font` routes
  to `UIFont.systemFontOfSize:weight:` (fixed-point; not Dynamic Type).
  `LabelRole::Primary` -> `UIColor.labelColor` (dynamic); `::Secondary`
  -> `UIColor.secondaryLabelColor`; `::Tertiary` ->
  `UIColor.tertiaryLabelColor`; `::Quaternary` ->
  `UIColor.quaternaryLabelColor`. `number_of_lines` -> `setNumberOfLines:`.
  No Liquid Glass.
- **iPadOS 26**: same as iOS 26. Larger viewport means the gallery does
  not clip (the iOS host scrolling gap only appears at iPhone width).
- **macOS 26**: `NSTextField` via `alloc` + `init`, then `setEditable: NO`,
  `setBordered: NO`, `setDrawsBackground: NO`, `setSelectable: NO`
  (HIG macOS: *"use the isEditable property of NSTextField"*). `font`
  routes to `NSFont.systemFontOfSize:weight:`. `LabelRole` tokens route
  to `NSColor.labelColor` / `NSColor.secondaryLabelColor` /
  `NSColor.tertiaryLabelColor` / `NSColor.quaternaryLabelColor`.
  Multi-line behavior via `NSTextField.cell.wraps = YES` when
  `number_of_lines = 0`.

## HIG citations (validated)
- Labels -> Abstract: *"A label is a static piece of text that people can
  read and often copy, but not edit."*
- Labels -> Best practices: *"Use a label to display a small amount of
  text that people don't need to edit. If you need to let people edit a
  small amount of text, use a text field. If you need to display a large
  amount of text, and optionally let people edit it, use a text view."*
- Labels -> Best practices: *"Prefer system fonts. A label can display
  plain or styled text, and it supports Dynamic Type (where available) by
  default. If you adjust the style of a label or use custom fonts, make
  sure the text remains legible."*
- Labels -> Best practices: *"Use system-provided label colors to
  communicate relative importance. The system defines four label colors
  that vary in appearance to help you give text different levels of visual
  importance."*
- Labels -> Best practices: *"Make useful label text selectable. If a
  label contains useful information -- like an error message, a location,
  or an IP address -- consider letting people select and copy it for
  pasting elsewhere."*
- Labels -> Platform considerations -> macOS: *"To display uneditable
  text in a label, use the isEditable property of NSTextField."*

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/labels.md](../validation/reports/labels.md)

## Related
- `UI::TextField` -- when the text must be editable (short form field).
- `UI::TextEditor` -- when the text must be editable (long-form multiline).
- `UI::Button` -- when the text must be tappable (use `title:` arg, not a
  separate label).
- `recipes/typography-hierarchy.md` -- multi-level title/subhead/body/
  footnote composition pattern.
