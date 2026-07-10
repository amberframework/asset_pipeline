---
slug: disclosure-controls
ui_view: UI::DisclosureGroup
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/disclosure-controls.md
validation_report: ../validation/reports/disclosure-controls.md
---

# UI::DisclosureGroup

> A disclosure control reveals and hides information or functionality by
> toggling a rotating triangle or chevron; on macOS it renders as a native
> NSButton with bezelStyle=disclosure (an AppKit widget), and on iOS it renders
> as a chevron SF Symbol row (chevron.right collapsed, chevron.down expanded)
> matching the SwiftUI DisclosureGroup affordance -- no Liquid Glass material
> is applied, as disclosure controls are content affordances, not surfaces.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A `UI::DisclosureGroup` is a progressive-disclosure affordance: it places
infrequently-needed options behind a triangular indicator so the default view
stays clean. Use it when some settings, options, or child rows are secondary to
the primary content and can safely be hidden until the person needs them. The
HIG describes two shapes: the disclosure triangle (used inline in lists and
outlines, like Finder's folder hierarchy or Keynote's export dialog), and the
disclosure button (used next to a control in a dialog to reveal advanced
options, like the macOS Save sheet's "Show More" affordance). Both shapes share
the same collapse/expand semantic.

Do NOT use `UI::DisclosureGroup` as a replacement for tabs or navigation.
It is for revealing a flat list of sibling options, not for navigating between
destinations. Do NOT use it for primary controls -- HIG requires: "Place
controls that people are most likely to use at the top of the disclosure
hierarchy so they're always visible, with more advanced functionality hidden by
default."

(HIG: "Use a disclosure control to hide details until they're relevant. Place
controls that people are most likely to use at the top of the disclosure
hierarchy so they're always visible, with more advanced functionality hidden by
default." -- Disclosure controls / Best practices.)

## Quickstart

```crystal
# Expanded group: shows child content below the header row.
# On macOS: NSButton.bezelStyle.disclosure pointing down + indented child NSTextFields.
# On iOS: chevron.down UIButton + UILabel header + child UILabels.
expanded = UI::DisclosureGroup.new("General", expanded: true)
expanded.content << UI::Label.new("Appearance: Auto")
expanded.content << UI::Label.new("Language & Region: English (US)")
expanded.content << UI::Label.new("Date & Time: Automatic")

# Collapsed group: shows only the header row; content is hidden.
# On macOS: NSButton.bezelStyle.disclosure pointing inward (right).
# On iOS: chevron.right UIButton + UILabel header; no child rows rendered.
collapsed = UI::DisclosureGroup.new("Privacy & Security", expanded: false)
collapsed.content << UI::Label.new("Location Services: On")

# Compose multiple groups in a VStack for a list-style outline.
outline = UI::VStack.new(spacing: 8.0)
outline << expanded.as(UI::View)
outline << collapsed.as(UI::View)
```

Renders: on macOS, an NSStackView (vertical) containing an NSButton with
bezelStyle=disclosure (NSButton.BezelStyle.disclosure = 5) as the triangle
indicator and an NSTextField label; when expanded, a second indented NSStackView
of child views. On iOS, a UIStackView (vertical) containing a UIButton
(UIButtonTypeSystem) with a chevron SF Symbol image and a UILabel title; when
expanded, a second UIStackView of child views.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `title` | `String` | (required) | Text displayed beside the disclosure triangle/chevron in the header row. HIG: "Provide a descriptive label when using a disclosure triangle. Make sure your labels indicate what is disclosed or hidden, like 'Advanced Options.'" |
| `expanded` | `Bool` | `false` | Controls the triangle/chevron direction (right = collapsed, down = expanded) and whether the content block is rendered. Set to `true` for initial-open state (e.g. when the HIG recommends showing primary options at the top of the hierarchy). |
| `content` | `Array(View)` | `[] of View` | Child views revealed when expanded = true. Any UI::View subclass is accepted; UI::Label, UI::HStack, and UI::Divider are most common. |
| `accessibility_label` | `String?` | `"#{title}, expanded/collapsed"` | Accessibility label on the header button, announced by VoiceOver. Defaults to "General, expanded" / "General, collapsed" automatically. Override when the auto-generated label is ambiguous. |

**Theming**: The header label resolves via `NSColor.labelColor` / `UIColor.labelColor`
(system semantic color, tracks appearance automatically). The triangle/chevron
color inherits from `NSColor.labelColor` / `UIColor.systemBlue` (iOS system
tint). No explicit `UI::Theme` tokens are read by the DisclosureGroup renderer;
font size defaults to 13pt (macOS, matching NSTextField label convention) and
17pt (iOS, matching HIG body text). See `foundations/color-and-theming.md`.

## Light / dark appearance notes

**macOS light:** NSButton.bezelStyle.disclosure renders a small (~13x13pt) gray
triangle glyph on a white window background. The triangle is drawn by AppKit
using the current label color (`NSColor.labelColor` light = near-black). The
NSTextField title resolves to `NSColor.labelColor` light (approximately 0.0/0.0/0.0
RGBA, ~16:1 on white). Content children also resolve to `NSColor.labelColor`.
The horizontal separator between sections uses `NSColor.separatorColor` (light gray).

**macOS dark:** The disclosure triangle widget tracks the appearance -- AppKit
renders the triangle in `NSColor.labelColor` dark variant (near-white on dark gray
background, approximately 0.85/0.85/0.85, ~14:1 on ~20% gray). NSTextField title
and content labels also resolve to `NSColor.labelColor` dark (near-white). The
separator resolves to `NSColor.separatorColor` dark (medium gray). All elements
track the system appearance automatically without any extra code.

**iOS light:** The chevron SF Symbol (chevron.right or chevron.down) renders in
`UIColor.systemBlue` (approximately 0.0/0.478/1.0, ~4.5:1 on white -- acceptable
for a large glyph element). The UILabel title renders in `UIColor.labelColor`
light (near-black on white, ~15:1). Content UILabel children also use
`UIColor.labelColor`. The separator uses `UIColor.separator` (light gray).

**iOS dark:** The chevron renders in `UIColor.systemBlue` dark variant
(approximately 0.06/0.52/1.0, ~5:1 on near-black -- legible). UILabel title and
content resolve to `UIColor.labelColor` dark (near-white on near-black, ~14:1).
All semantic colors track the appearance automatically.

SF Symbol variants: chevron.right and chevron.down are both monochrome template
images; they inherit the UIButton tint color (`UIColor.systemBlue`) in both
appearances. No filled vs outline switching is needed.

Contrast caution: if you override the chevron color to a custom brand color,
verify the contrast remains at least 3:1 against both light and dark backgrounds.
A mid-gray brand color that passes in light mode may drop below 3:1 on iOS dark
near-black backgrounds.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary (iOS chevron tint).**
```crystal
# The chevron UIButton inherits UIView.tintColor from the parent window.
# To change the chevron color on iOS, set the accent on the parent VStack
# or the root view. The title UILabel uses UIColor.labelColor and should
# NOT be overridden -- it guarantees legibility in both appearances.
#
# On macOS the disclosure triangle color is drawn by AppKit and cannot be
# tinted via a property knob on UI::DisclosureGroup. macOS triangle rendering
# always uses NSColor.labelColor (system-adaptive). Do not attempt to tint it.
group = UI::DisclosureGroup.new("Advanced Settings", expanded: false)
group.content << UI::Label.new("Option A")
# To apply a brand tint on iOS: set it on the enclosing VStack's background
# or via the window's tintColor -- not on the DisclosureGroup directly.
# (UI::Theme.primary controls system-wide accent if the renderer reads it.)
```

**Override the title font size while keeping HIG spacing.**
```crystal
# There is no `font` knob directly on UI::DisclosureGroup today.
# The title NSTextField (macOS) and UILabel (iOS) use the renderer's
# hardcoded 13pt / 17pt defaults. To change font size, add child label
# content with a custom UI::Font and set expanded = true with an empty title,
# or extend the view with a custom subclass. The preferred path is to keep
# the HIG-mandated 13pt (macOS) / 17pt (iOS) sizes for the header row and
# apply custom fonts only to child content labels.
child_label = UI::Label.new("Custom styled option")
child_label.font = UI::Font.new(family: "system", size: 15.0, weight: :regular)
group = UI::DisclosureGroup.new("Options", expanded: true)
group.content << child_label
```

**Use a flat background instead of the system window background.**
```crystal
# DisclosureGroup itself has no surface -- it renders content directly on
# whatever parent background it is placed on. To add a branded card
# background, wrap the group in a UI::Card or UI::Surface with a flat fill.
# This preserves all HIG hit targets and legibility while adding a brand
# container.
card = UI::Card.new
card.corner_radius = 10.0
card.background = UI::Color.new(r: 0.95, g: 0.95, b: 0.97, a: 1.0)  # light brand surface
group = UI::DisclosureGroup.new("Section", expanded: false)
group.content << UI::Label.new("Item A")
card.content = group.as(UI::View)
```

## Feel recipes
Short examples that map design intent to code.

**"I want an outline where the top-level category is open by default."**
-> Set `expanded: true` on the first group. Set `expanded: false` on all
   others. HIG: "Place controls that people are most likely to use at the top
   of the disclosure hierarchy so they're always visible."

**"I want a 'Show More' button that reveals advanced save options."**
-> Use `UI::DisclosureGroup.new("Show More", expanded: false)` placed near
   the primary save control. Add advanced option rows to `group.content`.
   Use only one per view: HIG "Use no more than one disclosure button in a
   single view. Multiple disclosure buttons add complexity and can be
   confusing."

## What happens on each platform
- **iOS 26**: `UIButton` (UIButtonTypeSystem) + chevron.right / chevron.down SF
  Symbol + `UILabel` in a horizontal `UIStackView`; content in a child vertical
  `UIStackView`. Matches SwiftUI DisclosureGroup internal layout. No Liquid
  Glass material (disclosure controls are content affordances, not surfaces).
- **iPadOS 26**: Same as iOS 26. HIG does not note iPadOS-specific deviations
  for disclosure controls.
- **macOS 26**: `NSButton` with `bezelStyle = .disclosure` (value 5) + empty
  title + `NSTextField` label in a horizontal `NSStackView`; content in a child
  `NSStackView` with 20pt leading inset. For the push-disclosure variant (dialog
  "Show More"), the current renderer uses bezelStyle=5 for both shapes; a future
  `style: :push_disclosure` knob will map to bezelStyle=23.

## HIG citations (validated)
- Disclosure controls -> Best practices: "Use a disclosure control to hide
  details until they're relevant. Place controls that people are most likely to
  use at the top of the disclosure hierarchy so they're always visible, with more
  advanced functionality hidden by default."
- Disclosure controls -> Disclosure triangles: "Provide a descriptive label when
  using a disclosure triangle. Make sure your labels indicate what is disclosed or
  hidden, like 'Advanced Options.'"
- Disclosure controls -> Disclosure buttons: "Place a disclosure button near the
  content that it shows and hides. Establish a clear relationship between the
  control and the expanded choices that appear when a person clicks or taps a
  button."
- Disclosure controls -> Disclosure buttons: "Use no more than one disclosure
  button in a single view. Multiple disclosure buttons add complexity and can be
  confusing."
- Disclosure controls -> Platform considerations -> iOS, iPadOS, visionOS:
  "Disclosure controls are available in iOS, iPadOS, and visionOS with the
  SwiftUI DisclosureGroup view."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/disclosure-controls.md](../validation/reports/disclosure-controls.md)

## Related
- `UI::Toggle` -- on/off boolean switch (UISwitch / NSButton.buttonType=switch);
  NOT a disclosure control despite the worklist's original mapping. Use Toggle for
  settings that are enabled or disabled, DisclosureGroup for revealing hidden content.
- `UI::ListView` -- when disclosure triangles should appear inline in a multi-level
  list/outline (Finder list view style), pair DisclosureGroup rows inside a ListView.
- `recipes/settings-panel.md` -- multi-section settings panel using DisclosureGroup
  for progressive disclosure of advanced options.
