---
slug: popovers
ui_view: UI::Popover
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/popovers.md
validation_report: ../validation/reports/popovers.md
---

# UI::Popover

> A transient floating container anchored to a trigger element, rendered with the
> `popover` Liquid Glass material (NSVisualEffectMaterialPopover on macOS,
> UIGlassEffect / UIBlurEffect(systemChromeMaterial) on iOS 26) and ~10pt corner
> radius by default on both platforms.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A popover is the HIG idiom for contextual micro-content that belongs adjacent to
a specific control -- a filter panel, a mini-inspector, an event editor, a quick-
action palette. It is NOT a modal replacement: it disappears when the user taps
outside, it carries no "back" gesture, and it should never cascade (one popover
open at a time). Use a sheet or alert for anything that requires explicit
confirmation before dismissing.

The popover surface conveys "this content is attached to that control" through two
signals: the glass material (visually floating above the host surface) and the
arrow/tail pointing at the anchor. For validation renders the inline path shows
the glass surface without the arrow -- in production, the presented path via
NSPopover or UIPopoverPresentationController provides the arrow automatically.

(HIG: "Use a popover to expose a small amount of information or functionality."
-- Popovers / Best practices.)

## Quickstart

```crystal
# Filter panel popover -- HIG-aligned default configuration.
# Construct content, then wrap in UI::Popover.
# Production: set is_presented = true on a user action to trigger the
# platform's popover lifecycle (NSPopover / UIPopoverPresentationController).
content = UI::VStack.new(spacing: 12.0)

title = UI::Label.new("Filter")
title.font = UI::Font.new(size: 13.0, weight: :semibold)
title.accessibility_label = "Filter panel title"
content << title

toggle1 = UI::Toggle.new("Show Completed", true)
toggle1.accessibility_label = "Show Completed toggle"
content << toggle1

toggle2 = UI::Toggle.new("Show Archived", false)
toggle2.accessibility_label = "Show Archived toggle"
content << toggle2

clear_btn = UI::Button.new("Clear", role: :default)
clear_btn.accessibility_label = "Clear filters"
content << clear_btn

popover = UI::Popover.new(content.as(UI::View), :bottom)
```

Renders: `NSVisualEffectView` (NSVisualEffectMaterialPopover = 6) on macOS,
`UIVisualEffectView` (UIGlassEffect on iOS 26, UIBlurEffect(style: 11) fallback)
on iOS. Both wrap an inner `NSStackView` / `UIStackView` with 16pt
leading/trailing insets and 12pt top/bottom insets. Corner radius ~10pt via
CALayer on both platforms.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `content` | `View?` | `nil` | The child view tree rendered inside the popover glass surface. |
| `is_presented` | `Bool` | `false` | When `false`, the inline validation path renders the glass surface in the host view tree. When `true`, the renderer triggers the platform popover lifecycle (NSPopover / UIPopoverPresentationController), providing the arrow/tail and hit-outside-to-dismiss behavior. |
| `arrow_edge` | `Symbol` | `:bottom` | `:top`, `:bottom`, `:leading`, `:trailing` -- the edge of the popover from which the arrow should emerge, passed to `NSPopover.preferredEdge` / `UIPopoverArrowDirection`. Only used in the presented path. |
| `preferred_width` | `Float64?` | `nil` | Hint for the popover's preferred content width. Passed to `NSPopover.contentSize` / `UIViewController.preferredContentSize` in the presented path. |
| `preferred_height` | `Float64?` | `nil` | Hint for the popover's preferred content height. |
| `on_dismiss` | `Proc(Nil)?` | `nil` | Called when the popover is dismissed (presented path only). |

**Theming**: `UI::Theme.apple_default.corner_radius_medium` (10.0 pt, matches
the NSPopover default corner radius). The glass material is hard-wired to the
platform's popover material and is not overridable via a Theme token on the
current implementation. See `foundations/color-and-theming.md`.

## Light / dark appearance notes

The popover glass material automatically tracks the system appearance on both
platforms without any application code.

**macOS light:** NSVisualEffectMaterialPopover (= 6) with BlendingModeBehindWindow
resolves to a frosted gray fill (~0.82 RGB) with a subtle glass-edge highlight
rim (~0.75 RGB border). Primary text (NSColor.labelColor) resolves to near-black
(~0.0 RGB, contrast against 0.82 glass ~12:1). Secondary labels use
NSColor.secondaryLabelColor (~0.56 RGB). The NSButton checkbox controls draw their
titles at near-black (~13pt regular) against the gray glass -- contrast well above
the 4.5:1 threshold. System-blue links/buttons remain distinguishable from any
destructive-red elements.

**macOS dark:** The same NSVisualEffectMaterialPopover in DarkAqua resolves to
~0.22 RGB dark frosted fill. NSColor.labelColor DarkAqua resolves to near-white
(~1.0 RGB, contrast against 0.22 glass ~7:1, above threshold). The glass-edge
rim lightens slightly (~0.30 RGB) to maintain separation from the card fill.
Typography weights stay identical to light appearance -- NSButton does not auto-
thin in DarkAqua. No legibility failures in dark.

**iOS light:** UIVisualEffectView (UIGlassEffect iOS 26 or UIBlurEffect style 11)
resolves to a near-white frosted panel (~0.97 RGB) with a soft drop shadow
providing elevation depth. UIColor.label in light resolves to near-black (~0.0
RGB). Contrast for primary text against the glass ~21:1. UISwitch controls show
systemGreen for the on track, system gray for off -- both distinguishable from
any system-blue accent or system-red destructive elements.

**iOS dark:** UIVisualEffectView dark material resolves to an elevated dark surface
(~0.15 RGB) against the near-black host. UIColor.label in dark resolves to near-
white (~1.0 RGB, contrast against 0.15 fill ~7:1). The glass edge rim provides a
~0.22 RGB border visible against both the card fill and the host. UISwitch green
on track remains distinguishable from near-white label text in dark.

**SF Symbols:** UI::Popover itself does not emit SF Symbols. Content views placed
inside the popover (e.g. icon buttons, toggles with symbols) inherit the host
appearance via the parent UIVisualEffectView / NSVisualEffectView's effective
appearance. Hierarchical SF Symbol rendering tracks appearance automatically when
rendered inside a visual effect view.

**Contrast caveat:** If a brand override replaces the glass material with a very
light custom fill (near-white) in dark mode, UIColor.label near-white text will
fall below the 3:1 threshold. Always verify dark-mode contrast when overriding
the surface background.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up
HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# The Clear button and any system-blue tinted elements inside the popover
# content use the accent color. Override the accent on the content views.
# The glass material itself stays HIG-default -- do not override material here.
clear_btn = UI::Button.new("Clear", role: :default)
clear_btn.tint_color = UI::Color.new(r: 0.36, g: 0.0, b: 0.87) # brand violet
# HIG spacing (16pt insets, 8pt spacing) and the glass material stay unchanged.
```

**Replace the glass material with a flat brand surface.**
```crystal
# UI::Popover does not expose a surface_style knob directly. To use a flat
# brand background instead of Liquid Glass, wrap your content in a UI::Surface
# (which supports surface_style: :plain) and skip UI::Popover. Use
# UI::PopoverPresenter to manage lifecycle if needed, or present the surface
# as a custom view inside the popover content tree.
#
# WARNING: removing the glass material loses the Liquid Glass translucency that
# communicates floating elevation on iOS 26 / macOS 26. The surface will no
# longer read as a popover -- it will look like a card. Consider whether a
# UI::Card or UI::Sheet better matches your intent if you remove the glass.
surface = UI::Surface.new(surface_style: :plain)
surface.background_color = UI::Color.new(r: 0.10, g: 0.08, b: 0.20) # brand dark
# Then set surface as the popover content.
```

**Override typography while keeping HIG spacing.**
```crystal
# Set font on individual Label views inside the popover content.
# HIG mandates 13pt on macOS, 15pt on iOS for popover body text.
# The spacing (8pt between stack items, 16pt insets) is owned by the renderer
# and should not be changed via the content tree.
title = UI::Label.new("Filter")
title.font = UI::Font.new(size: 13.0, weight: :semibold, family: "YourBrandFont")
# Keeping size at 13pt (macOS) / 15pt (iOS) preserves HIG legibility.
# Switching to a lighter weight (thin, ultralight) risks legibility in dark mode.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a contextual date-change panel that attaches to a calendar event chip"**
-> Set `arrow_edge: :bottom` so the arrow points up to the chip above the popover.
-> Set `preferred_width: 280.0` to constrain the panel to a comfortable reading width.
-> Set `is_presented = true` on the UI::PopoverPresenter when the chip is tapped.
-> Keep content to date/time pickers + a Done button (HIG: "limit the amount of
   functionality to a few related tasks").

**"I want a mini-inspector that stays open while the user browses other content"**
-> On macOS, set `popover.detachable = true` (planned; see gaps.md) or use
   NSPanel directly via the ObjC bridge. HIG: "You can make a popover detachable
   in macOS, which becomes a separate panel when people drag it."
-> On iOS, a non-detachable popover cannot stay open -- use a sidebar or sheet for
   persistent inspectors on iPhone-size layouts.

## What happens on each platform
- **iOS 26**: `UIVisualEffectView` initialized with `UIGlassEffect` (preferred) or
  `UIBlurEffect(style: .systemChromeMaterial)` fallback. Inner `UIStackView` with
  16pt margins. `UIPopoverPresentationController` provides the arrow and
  hit-outside-dismiss in the presented path.
- **iPadOS 26**: Identical to iOS 26. HIG recommends popovers over sheets on iPad
  wide layouts; the same `UI::Popover` view adapts correctly -- the
  UIPopoverPresentationController renders natively on iPad without full-screen
  modal fallback.
- **macOS 26**: `NSVisualEffectView` (NSVisualEffectMaterialPopover = 6). Inner
  `NSStackView` with 16pt insets. `NSPopover` provides the arrow, animation, and
  detachable panel behavior in the presented path. Detachable panel behavior is
  HIG-recommended for inspector-style popovers.

## HIG citations (validated)
- Popovers -> Best practices: "Use a popover to expose a small amount of information
  or functionality. Because a popover disappears after people interact with it, limit
  the amount of functionality in the popover to a few related tasks."
- Popovers -> Best practices: "Position popovers appropriately. Make sure a popover's
  arrow points as directly as possible to the element that revealed it. Ideally, a
  popover doesn't cover the element that revealed it or any essential content people
  may need to see while using it."
- Popovers -> Best practices: "Show one popover at a time. Displaying multiple
  popovers clutters the interface and causes confusion. Never show a cascade or
  hierarchy of popovers, in which one emerges from another."
- Popovers -> Best practices: "Always save work when automatically closing a
  nonmodal popover. People can unintentionally dismiss a nonmodal popover by clicking
  or tapping outside its bounds."
- Popovers -> Platform considerations -> iOS, iPadOS: "Avoid displaying popovers in
  compact views. Reserve popovers for wide views; for compact views, use all available
  screen space by presenting information in a full-screen modal view like a sheet
  instead."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/popovers.md](../validation/reports/popovers.md)

## Related
- `UI::Sheet` -- use for full-height modal content that requires explicit dismiss
  (Done / Cancel), rather than incidental contextual editing.
- `UI::Alert` -- use for warnings or destructive confirmations that require the
  user's explicit attention before continuing.
- `UI::GlassBackground` -- the raw Liquid Glass material primitive; use when you
  need glass without popover lifecycle semantics.
- `recipes/contextual-editor.md` -- popover + form field pattern for inline
  attribute editing.
