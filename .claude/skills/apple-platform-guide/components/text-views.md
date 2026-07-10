---
slug: text-views
ui_view: UI::RichText
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/text-views.md
validation_report: ../validation/reports/text-views.md
---

# UI::RichText

> A multi-line, scrollable text display backed by NSTextView (macOS) or UITextView (iOS),
> rendering styled spans with no Liquid Glass material -- system background color tracking
> appearance automatically via NSColor.labelColor / UIColor.labelColor.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

`UI::RichText` is the right reach when you need more than a single line: compose screens,
long-form notes, error-message bodies, multi-paragraph explanations, or content with mixed
typographic emphasis (bold highlights within a regular-weight paragraph). It renders as a
scrollable NSTextView (macOS) or UITextView (iOS) and adopts the system label color by
default, so text stays legible in both light and dark appearances with no configuration.

Do not reach for `UI::RichText` for small amounts of non-editable text -- use `UI::Label`
instead. For editable multi-line input (the user types into the area), use `UI::TextArea`
which wires up the delegate callbacks and optional placeholder text.

(HIG: "Use a text view when you need to display text that's long, editable, or in a
special format. Text views differ from Text fields and Labels in that they provide the
most options for displaying specialized text and receiving text input." -- Text views /
Best practices.)

## Quickstart

```crystal
# Read-only paragraph -- three lines of wrapped body text.
tv = UI::RichText.new
tv.add_span("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.")
tv.accessibility_label = "Article body text"

# Attributed text -- bold + italic spans in a single view.
tv2 = UI::RichText.new
tv2.add_span("The quick brown fox ", bold: false, italic: false)
tv2.add_span("jumps over", bold: true, italic: false)
tv2.add_span(" the lazy dog. ", bold: false, italic: false)
tv2.add_span("Styled text", bold: false, italic: true)
tv2.add_span(" mixed with plain content.", bold: false, italic: false)
tv2.accessibility_label = "Attributed body text"
```

Renders: NSTextView inside NSScrollView on macOS 26; UITextView on iOS 26. No Liquid Glass
material -- system background color (white in light, near-black in dark) with NSColor.labelColor
/ UIColor.labelColor text.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `spans` | `Array(UI::RichText::Span)` | `[]` | The sequence of styled text runs. Add via `add_span`. |
| `text_alignment` | `UI::Alignment` | `Alignment::Leading` | Leading / center / trailing text alignment, maps to NSTextAlignment / NSTextAlignment. |
| `Span#text` | `String` | `""` | The text content of this run. |
| `Span#font` | `UI::Font` | `Font.new` (system 17pt regular) | Per-span font. family: "system" maps to system font; "monospace" maps to monospaced system font. |
| `Span#color` | `UI::Color` | `Color{0,0,0,1}` (sentinel) | Per-span foreground color. The zero-RGB sentinel is replaced by NSColor.labelColor / UIColor.labelColor at render time for appearance-tracking. Set an explicit non-zero RGBA to lock a brand color. |
| `Span#bold` | `Bool` | `false` | Applies bold weight to this span's font. |
| `Span#italic` | `Bool` | `false` | Applies italic style to this span's font. |
| `Span#underline` | `Bool` | `false` | Underline decoration on this span. (Planned: rendered via NSAttributedString underlineStyle attribute; not yet wired in the bridge.) |
| `Span#strikethrough` | `Bool` | `false` | Strikethrough decoration on this span. (Planned: rendered via NSAttributedString strikethroughStyle attribute; not yet wired in the bridge.) |
| `Span#link` | `String?` | `nil` | URL string for a tappable link span. (Planned: UITextView.dataDetectorTypes / NSTextView delegate; not yet wired.) |
| `accessibility_label` | `String?` | `nil` | VoiceOver label for the text view container. Required for interactive text views. |

**Theming**: No explicit `UI::Theme` tokens consumed by `UI::RichText`. The text color
defaults to `NSColor.labelColor` / `UIColor.labelColor` (the sentinel swap in the renderer).
To use a theme-derived color, set `Span#color` to a non-zero RGBA corresponding to your
brand token. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::RichText` has no intrinsic surface material -- it renders on the window/view
controller's default background (white in light, near-black in dark on iOS; white in light,
dark gray in dark on macOS). Text color is resolved at render time:

- **Light appearance:** `NSColor.labelColor` resolves to near-black (~0.05 RGB), contrast
  approximately 21:1 against white background. `UIColor.labelColor` resolves identically
  on iOS.
- **Dark appearance:** `NSColor.labelColor` (DarkAqua) resolves to near-white (~0.95 RGB),
  contrast approximately 15:1 against NSTextView dark background (~0.15 RGB) on macOS;
  `UIColor.labelColor` resolves to near-white (~0.95 RGB) on black UITextView background
  (~0.0 RGB) on iOS, contrast approximately 20:1.

The sentinel swap (Color{0,0,0,1} => nscolor_label_primary) fires whenever the span's
color equals the zero-RGB default. If you set a non-zero RGBA on a span, the sentinel
does NOT fire and that span uses your explicit color in both appearances. This means a
brand color override on a span is not appearance-tracked -- see "Customization / brand
override" below for the correct pattern.

SF Symbols are not used by `UI::RichText` itself. If your spans include icon glyphs via
Unicode PUA codepoints, ensure the symbol font variant is specified in `Span#font`.

Contrast caveats: a brand color override on `Span#color` that targets a specific mid-tone
(e.g. a brand teal at 0.0/0.55/0.55) will be legible on a white light background (~3.5:1)
but potentially difficult on a dark background (~2:1 at the same RGBA without adjustment).
Use `UI::Color` values with at least 4.5:1 contrast in both appearances, or constrain
overrides to accents rather than primary body text.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's
legibility, hit targets, or appearance-tracking._

**Swap the accent span to your brand primary.**
```crystal
# HIG default: all spans use the sentinel Color{0,0,0,1} => NSColor.labelColor.
# Brand override: a single highlighted span in brand amber, keeping all other
# spans on the appearance-tracking sentinel.
tv = UI::RichText.new
tv.add_span("Background context ", bold: false, italic: false)
# Brand amber: 1.0/0.6/0.0 -- legible on white (4.5:1+) but check dark separately.
tv.add_span("key term", bold: true, italic: false,
            color: UI::Color.new(r: 1.0, g: 0.6, b: 0.0, a: 1.0))
tv.add_span(" with remaining context.", bold: false, italic: false)
# Remaining spans use default Color{0,0,0,1} sentinel => nscolor_label_primary.
```

**Replace body text with a brand typeface while keeping HIG spacing.**
```crystal
# UI::Font.new with a named family falls back to system font if the name
# is not registered in the app bundle. Register your brand font in Info.plist
# (UIAppFonts / ATSApplicationFontsPath) before referencing it here.
brand_font = UI::Font.new(family: "BrandSans-Regular", size: 17.0, weight: :regular)
tv = UI::RichText.new
tv.add_span("Body text in brand typeface.", font: brand_font)
# 17pt matches HIG body text size. Do not reduce below 13pt for legibility.
```

**Disable appearance-tracking for a fully branded text block.**
```crystal
# Explicit RGBA bypasses the sentinel swap -- both light and dark get this color.
# Use only for decorative or brand-primary scenarios where you have verified
# contrast in both appearances (minimum 4.5:1 for body text).
brand_dark = UI::Color.new(r: 0.1, g: 0.15, b: 0.3, a: 1.0)  # navy ~18:1 on white, ~1:1 on dark -- DO NOT USE for dark mode
# Correct pattern: provide separate appearances via the host's theme.
# See foundations/color-and-theming.md for appearance-conditional color tokens.
tv = UI::RichText.new
tv.add_span("Branded text block.", color: brand_dark)
```

## Feel recipes
Short examples that map design intent to code.

**"I want a compose screen body area where the user types a long note."**
-> Use `UI::TextArea` instead of `UI::RichText`. `UI::TextArea` has `is_editable: true`,
   `placeholder: "Start typing..."`, and optional `on_change` callback. `UI::RichText` is
   read-only by design.

**"I want an error detail area showing a formatted stack trace in monospaced font."**
-> Set `Span#font` to `UI::Font.new(family: "monospace", size: 13.0, weight: :regular)`.
   This maps to `monospacedSystemFontOfSize:weight:` on iOS/macOS, which tracks the system
   monospaced font preference (SF Mono on Apple platforms). Keep `Span#color` at the zero-RGB
   sentinel so the text color appearance-tracks (near-black light / near-white dark).

## What happens on each platform
- **iOS 26**: `UITextView` with `setEditable: NO`, `setScrollEnabled: NO` (intrinsic height
  in UIStackView), `setFont: UIFont.systemFontOfSize:17`, `setTextColor: UIColor.labelColor`
  via sentinel swap.
- **iPadOS 26**: Same as iOS 26. UITextView on iPadOS has no additional layout differences
  in this renderer.
- **macOS 26**: `NSTextView` inside `NSScrollView` with `hasVerticalScroller: YES`,
  `autohidesScrollers: YES`, `setEditable: NO`, `setFont: NSFont.systemFontOfSize:17`,
  `setTextColor: NSColor.labelColor` via sentinel swap.

## HIG citations (validated)
- Text views -> Abstract: "A text view displays multiline, styled text content, which can
  optionally be editable."
- Text views -> Best practices: "Use a text view when you need to display text that's long,
  editable, or in a special format."
- Text views -> Best practices: "Keep text legible. Although you can use multiple fonts,
  colors, and alignments in creative ways, it's essential to maintain the readability of
  your content. It's a good idea to adopt Dynamic Type so your text still looks good if
  people change text size on their device."
- Text views -> Best practices: "Make useful text selectable. If a text view contains
  useful information such as an error message, a serial number, or an IP address, consider
  letting people select and copy it for pasting elsewhere."
- Text views -> "Text views can be any height and allow scrolling when the content extends
  outside of the view. By default, content within a text view is aligned to the leading edge
  and uses the system label color."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/text-views.md](../validation/reports/text-views.md)

## Related
- `UI::Label` -- use for short non-editable text (one or two lines); does not scroll.
- `UI::TextArea` -- use when the user needs to type multi-line input; has `on_change` callback
  and `placeholder`.
- `UI::TextEditor` -- use for code / structured text editing with optional syntax
  highlighting and line numbers.
- `recipes/compose-screen.md` -- multi-component pattern combining `UI::TextArea`,
  `UI::Toolbar`, and `UI::Button` for a message composition screen.
