---
slug: activity-views
ui_view: UI::ActivityView
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/activity-views.md
validation_report: ../validation/reports/activity-views.md
---

# UI::ActivityView

> An activity view (share sheet) presents sharing destinations and action
> tiles in a Liquid Glass surface, rendered with `UIGlassEffect` /
> `UIBlurEffect(systemChromeMaterial)` on iOS 26 and an
> `NSVisualEffectView(popover)` approximation on macOS.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

An activity view is the canonical entry point to platform-level sharing
and quick actions. Users reach it from the Share button (square.and.arrow.up)
and expect to find messaging apps, AirDrop, system actions like Print and
Copy, and app-specific actions relevant to the content. The component's four
zones — header, destination row, action grid, cancel — are a well-learned
pattern: do not deviate from the zone order or omit the cancel affordance.

Use `UI::ActivityView` when the user has selected content to share or when
a contextual set of actions applies to the current item. It is NOT the right
component for settings panels, confirmation dialogs, or any flow where the
user has not explicitly chosen to share or act on an item.

(HIG: "Use the Share button to display an activity view. People are accustomed
to accessing system-provided activities when they choose the Share button." —
Activity views / Best practices.)

## Quickstart

```crystal
view = UI::ActivityView.new(
  title: "Nature Walks",
  subtitle: "12 photos · 3.4 MB",
  thumbnail: UI::Image.new("photo"),          # any UI::View, typically UI::Image
  destinations: [
    UI::ActivityDestination.new(icon_symbol: "envelope",  label: "Mail"),
    UI::ActivityDestination.new(icon_symbol: "message",   label: "Messages"),
    UI::ActivityDestination.new(icon_symbol: "wifi",      label: "AirDrop"),
    UI::ActivityDestination.new(icon_symbol: "note.text", label: "Notes"),
  ],
  actions: [
    UI::ActivityAction.new(icon_symbol: "folder",     label: "Save to Files"),
    UI::ActivityAction.new(icon_symbol: "printer",    label: "Print"),
    UI::ActivityAction.new(icon_symbol: "doc.on.doc", label: "Copy"),
    UI::ActivityAction.new(icon_symbol: "book",       label: "Add to Reading List"),
  ],
  on_cancel: -> { dismiss_sheet }
)
```

Renders: on iOS 26, a `UIVisualEffectView` wrapping a `UIGlassEffect` (or
`UIBlurEffect(systemChromeMaterial)` on earlier SDKs) with four arranged
zones. On macOS, a `NSVisualEffectView(NSVisualEffectMaterialPopover)` with
the same four zones inline for validation. When `is_presented = true` and a
share payload is present, native renderers present `UIActivityViewController`
on iOS/iPadOS and `NSSharingServicePicker` on macOS so the same view model can
drive a real share flow.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `title` | `String` | required | Primary header text (15pt semibold, primary label color) |
| `subtitle` | `String?` | `nil` | Secondary header text (13pt regular, secondary label color) |
| `is_presented` | `Bool` | `false` | When true, native renderers present the system share UI if a share payload is available. |
| `share_text` | `String?` | `nil` | Optional share body text passed into `UIActivityViewController` / `NSSharingServicePicker`. |
| `share_url` | `String?` | `nil` | Optional URL or file path included in the native share payload. |
| `share_subject` | `String?` | `nil` | Optional share subject used by the iOS share controller. |
| `thumbnail` | `View?` | `nil` | Optional preview view in the header (typically `UI::Image`) |
| `destinations` | `Array(ActivityDestination)` | `[]` | Horizontal destination row — each item has `icon_symbol : String`, `label : String`, `on_select : Proc?` |
| `actions` | `Array(ActivityAction)` | `[]` | 2-col action tile grid — each item has `icon_symbol : String`, `label : String`, `on_select : Proc?`, `role : Symbol?` |
| `on_cancel` | `Proc(Nil)?` | `nil` | Called when the Cancel button is activated |

**ActivityAction role values:** `:destructive` renders the action label in
`[UIColor systemRedColor]` / `[NSColor systemRedColor]` (platform-tracked
semantic red). `nil` or omitted uses the primary label color.

**Theming**: activity view surfaces use `nscolor_label_primary` /
`nscolor_label_secondary` for text, and `nsfont_system_weight` for the
semibold title and Cancel button. The glass material token is
`NSVisualEffectMaterialPopover` on macOS and `UIBlurEffectStyleSystemChromeMaterial`
on iOS. See `foundations/color-and-theming.md` for semantic color guidance.

## Light / dark appearance notes

The component resolves in each appearance as follows:

**Text colors:** `title` uses `nscolor_label_primary` which dispatches
`[NSColor labelColor]` on macOS and `[UIColor labelColor]` on iOS. Both
track appearance automatically — near-black in light, white in dark. The
`subtitle` uses `nscolor_label_secondary` (`secondaryLabelColor` on both
platforms) which resolves to a gray in light and a lighter gray in dark.
Action tile labels follow the same pattern. If an `ActivityAction` has
`role: :destructive`, the label uses a baked RGBA (1.0, 0.23, 0.19, 1.0)
in light. In dark the system red from `nscolor_rgba` maintains adequate
contrast against the dark glass background.

**Glass material:** On macOS the material is
`NSVisualEffectMaterialPopover` (material index 6), which the system
renders as a warm light gray in light appearance and a darker gray in dark
appearance. On iOS the material is `UIGlassEffect` (iOS 26 runtime check;
falls back to `UIBlurEffectStyleSystemChromeMaterial` on iOS 15-25), which
renders as near-white in light and dark gray in dark. Both materials track
appearance without any developer action.

**SF Symbols:** Destination icons use `imageWithSystemSymbolName:` (macOS)
and `UIImage systemImageNamed:` (iOS). On macOS, SF Symbols render in the
button's inherited label color (near-black in light, white in dark). On iOS,
UIButton inherits the window's tint color (system blue by default), so
destination icons and action icons appear in system blue in both appearances.
The blue maintains adequate contrast against both the near-white (light) and
dark-gray (dark) glass backgrounds.

**Legibility caveat for brand override:** If you replace the default glass
material with a custom opaque fill that is close to system blue, the default
SF Symbol rendering on iOS (which uses the window tint color) may produce
low-contrast icons. Either change the window tint to a brand color that
contrasts with your fill, or explicitly set the image rendering mode to
`.alwaysTemplate` and supply a contrasting tint. Avoid relying on the
default blue tint against a blue fill.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# The destination and action icon tint on iOS inherits from the window.
# To use a brand primary instead of system blue, set the tint on the
# root window before presenting the view. Keep HIG hit targets (44pt)
# and the zone layout intact — only the tint changes.
#
# In your Swift/UIKit layer:
#   window.tintColor = UIColor(named: "BrandPrimary")
#
# The Crystal layer requires no change; the tint is a UIKit window
# property that cascades to all views automatically.
```

**Replace the glass material with a flat brand surface.**
```crystal
# The inline layout for the capture path uses UIVisualEffectView.
# For a flat brand surface, subclass or wrap UI::ActivityView and
# override the renderer's visit method to substitute a UIView with
# a solid background color instead of the UIVisualEffectView.
# WARNING: removing the glass material means appearance-tracking is
# lost unless you manually handle traitCollectionDidChange or use
# UIColor.dynamicProvider. Also disables the Liquid Glass rim highlight
# that gives the surface depth. Only do this if your brand requires
# opaque surfaces throughout.
#
# Example renderer override (macOS, for reference):
#   effect = alloc_init("NSView")
#   brand_color = LibObjCBridge.nscolor_rgba(0.12, 0.09, 0.24, 1.0)
#   LibObjCBridge.objc_send_id(effect, sel("setBackgroundColor:"), brand_color)
#   # NOTE: this disables NSVisualEffectView tracking. You lose
#   # automatic dark-mode adaptation unless you use a dynamic NSColor.
```

**Override typography while keeping HIG spacing.**
```crystal
# The title and Cancel button use nsfont_system_weight(size, weight).
# To substitute a brand font, update the visit method to use
# nsfont_named(name_ptr, size) with your brand font's PostScript name.
# Keep the sizes (title: 15pt, cancel: 17pt) and semibold weight (0.4)
# to maintain HIG-mandated visual hierarchy. The spacing (12pt between
# zones, 16pt insets) should not change — those values are HIG-specified.
#
# Example: in appkit_renderer.cr visit(UI::ActivityView),
# replace the title_font line:
#   title_font = LibObjCBridge.nsfont_system_weight(15.0, 0.4)
# with:
#   brand_name = LibObjCBridge.nsstring_from_cstr("BrandSans-Semibold".to_unsafe)
#   title_font = LibObjCBridge.nsfont_named(brand_name, 15.0)
```

## Feel recipes
Short examples that map design intent to code.

**"I want a share sheet that appears after the user taps the Share button."**
-> Create a `UI::ActivityView` with `destinations` populated from your app's
   supported share targets and `actions` listing your app-specific actions.
   Set `share_text` and / or `share_url`, then flip `is_presented = true`.
   Native renderers present the system share controller while the inline
   activity-view layout remains available for previews and validation.

**"I want a destructive action (e.g., Delete from Album) in the action grid."**
-> Add `UI::ActivityAction.new(icon_symbol: "trash", label: "Delete from Album",
   role: :destructive)` to the `actions` array. The renderer applies
   `systemRedColor` to the label in both light and dark appearance automatically.

## What happens on each platform
- **iOS 26**: `UIVisualEffectView` with `UIGlassEffect` (runtime check) or
  `UIBlurEffect(systemChromeMaterial=11)` fallback. When `is_presented = true`
  and a share payload is present, the renderer presents
  `UIActivityViewController` for the real system share sheet. The inline layout
  remains the validation capture path.
- **iPadOS 26**: Same as iOS. On iPad the system share sheet typically
  presents as a popover rather than a sheet.
- **macOS 26**: `NSVisualEffectView(NSVisualEffectMaterialPopover)`. HIG
  explicitly marks activity views as "Not supported in macOS." For real app
  flows the renderer presents `NSSharingServicePicker`, while the four-zone
  inline layout remains the HIG-honest capture path for cross-platform review.

## HIG citations (validated)
- Activity views -> Best practices: "Avoid creating duplicate versions of
  common actions that are already available in the activity view."
- Activity views -> Best practices: "Consider using a symbol to represent
  your custom activity. SF Symbols provides a comprehensive set of
  configurable symbols you can use to communicate items and concepts in
  an activity view."
- Activity views -> Best practices: "Use the Share button to display an
  activity view. People are accustomed to accessing system-provided
  activities when they choose the Share button."
- Activity views -> Platform considerations: "Not supported in macOS,
  tvOS, or watchOS."
- Activity views -> abstract: "Activity views present sharing activities
  like messaging and actions like Copy and Print, in addition to quick
  access to frequently used apps."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/activity-views.md](../validation/reports/activity-views.md)

## Related
- `UI::Sheet` — use when presenting a bottom-anchored modal surface that is
  not a share sheet.
- `UI::Popover` — use when presenting a contextual panel from a specific
  anchor point.
- `recipes/sharing.md` — multi-component pattern for wiring a Share button
  to a UI::ActivityView with platform-appropriate dispatch.
