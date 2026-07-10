---
slug: buttons
ui_view: UI::Button
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/buttons.md
validation_report: ../validation/reports/buttons.md
---

# UI::Button

> A button initiates an instantaneous action. On macOS the renderer produces a
> native NSButton; on iOS a UIButton backed by UIButton.Configuration (iOS 15+)
> which provides bordered, filled, tinted, and plain bezel variants. No Liquid
> Glass material is applied to the button itself -- Liquid Glass belongs to the
> surface container (Sheet, Popover) that the button sits inside.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

`UI::Button` is the "commit an action" primitive. Reach for it whenever a
user's choice should produce an immediate, one-shot side effect -- submitting a
form, opening a sheet, confirming a destructive step. It is NOT for navigation
between hierarchical pages (use `UI::NavigationLink`), toggling a boolean
state (use `UI::Toggle`), or selecting one of a few options (use
`UI::SegmentedControl` or `UI::Picker`). Keep to one or two prominent buttons
per view so the primary action reads clearly; additional actions should use
quieter styles.

HIG: "When buttons are instantly recognizable and easy to understand, an app
tends to feel intuitive and well designed." -- Buttons / Best practices.

A button's `style` knob sets the visual shape (filled, tinted, bordered, or
borderless); its `role` knob carries the semantic weight (destructive =
red; cancel = semibold). Use one prominent button per view for the most likely
action; use the cancel role, not custom styling, for dismissal actions. Neither
role override should be skipped -- the role system is how HIG communicates
safety signals without any additional UI.

(HIG: "a destructive button uses the system red color." -- Buttons / Role.)

## Quickstart

```crystal
require "asset_pipeline/ui"

# Prominent (primary CTA) -- filled blue on iOS; accent-bordered on macOS
save = UI::Button.new("Save", style: UI::ButtonStyle::Prominent) { save_document }
save.accessibility_label = "Save document"

# Default (secondary action) -- gray bordered on iOS; rounded push button on macOS
continue_btn = UI::Button.new("Continue")

# Destructive role -- system red fill (Prominent) or red label (Default)
delete_btn = UI::Button.new("Delete Account",
  role: :destructive,
  style: UI::ButtonStyle::Prominent)
delete_btn.accessibility_label = "Delete account permanently"

# Cancel role -- semibold label weight on both platforms
cancel_btn = UI::Button.new("Cancel", role: :cancel)

# Tinted (secondary CTA, softer than Prominent)
add_btn = UI::Button.new("Add to List", style: UI::ButtonStyle::Tinted)

# Borderless (text-link, lowest prominence)
learn_btn = UI::Button.new("Learn more", style: UI::ButtonStyle::Borderless)

# With SF Symbol prefix
share_btn = UI::Button.new("Share", symbol: "square.and.arrow.up")
share_btn.accessibility_label = "Share item"

# Disabled state
offline_btn = UI::Button.new("Unavailable")
offline_btn.disabled = true
```

Renders: on iOS 26, UIButton via `+[UIButton buttonWithConfiguration:primaryAction:]`
with UIButtonConfiguration variant selected per style (gray/filled/tinted/plain).
On macOS 26, NSButton with NSBezelStyle and bezelColor/contentTintColor attributes
per style. No Liquid Glass material on the button surface.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | (required) | Button title. Use title-style capitalization per HIG; start with a verb ("Save", "Add to Cart", "Delete"). |
| `style` | `UI::ButtonStyle` | `ButtonStyle::Default` | Visual shape. Default = gray bordered; Prominent = filled blue; Tinted = translucent accent; Bordered = explicit bordered (same as Default); Borderless = no bezel. See ButtonStyle table below. |
| `role` | `Symbol` | `:default` | Semantic role: `:default` (no special styling), `:destructive` (system red), `:cancel` (semibold). Applied on top of style in both renderers. |
| `symbol` | `String?` | `nil` | SF Symbol glyph name prepended to the label. Unknown names silently skipped. Example: `"square.and.arrow.up"`, `"trash"`. |
| `font` | `UI::Font` | `Font.new` (system default) | Title font. The `:cancel` role overrides weight to `:semibold`; other roles use this value verbatim. |
| `foreground_color` | `UI::Color` | `Color(0.0, 0.478, 1.0)` | Label tint for Default/Bordered/Borderless non-destructive roles. Baked RGBA (not adaptive). Overridden by `systemRedColor` when `role == :destructive`. |
| `disabled` | `Bool` | `false` | When `true`, renderers call `setEnabled:NO`; platform handles grayed-out appearance. |
| `on_tap` | `Proc(Nil)?` | `nil` | Tap / click handler. Wired via `CrystalActionDispatcher` on both platforms. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. Set for every button whose visual label does not fully describe the action (icons, abbreviations). |

### ButtonStyle enum

| Style | iOS (UIButtonConfiguration) | macOS (NSButton) |
|-------|---------------------------|-----------------|
| `Default` | `grayButtonConfiguration` -- gray bordered pill | NSBezelStyleRounded, isBordered = true |
| `Prominent` | `filledButtonConfiguration` -- solid blue (or red) filled pill | NSBezelStyleRounded + bezelColor = controlAccentColor + contentTintColor = white |
| `Tinted` | `tintedButtonConfiguration` -- translucent tint fill | NSBezelStyleFlexiblePush + bezelColor = controlAccentColor @ 0.18 alpha |
| `Bordered` | `grayButtonConfiguration` (same as Default) | NSBezelStyleRounded, isBordered = true |
| `Borderless` | `plainButtonConfiguration` -- no bezel | isBordered = false |

**Role x Style matrix (color outcome):**

| role / style | Default | Prominent | Tinted | Borderless |
|---|---|---|---|---|
| `:default` | blue label | blue fill + white text | blue-tint fill + blue text | blue link text |
| `:destructive` | red label | red fill + white text | red background + white text | red link text |
| `:cancel` | semibold blue label | semibold white text on blue fill | semibold blue on tint | semibold blue link text |

**Theming**: relevant tokens are `UI::Theme.apple_default.primary` (default
label tint, currently baked RGBA) and `UI::Theme.apple_default.error` (system
red for destructive role, resolved via `NSColor.systemRedColor` /
`UIColor.systemRedColor` -- adaptive). See `foundations/color-and-theming.md`.

## Light / dark appearance notes

`UI::Button` renders as a native platform control. The bezel and disabled
appearance track the system appearance automatically (NSButton / UIButton manage
their own material). The appearance-tracking concerns for buttons are:

**Default role label color (light):** `foreground_color` defaults to
`Color(0.0, 0.478, 1.0)`. Both renderers apply this as a baked RGBA attribute,
not the adaptive `NSColor.systemBlueColor` / `UIColor.systemBlueColor`. In light
mode, contrast is approximately 4.8:1 against white (PASS). Open gap from
iteration 12.

**Default role label color (dark):** The same baked `(0.0, 0.478, 1.0)` against
a near-black background yields approximately 3.5:1 (above the 3:1 large-text
threshold). The adaptive dark-mode system blue `(0.039, 0.518, 1.0)` would give
slightly better contrast. On iOS, UIButton.Configuration.grayButtonConfiguration
internally uses the system blue adaptive color for its label, so the baked value
only affects Borderless and Default-style buttons where `foreground_color` is
directly applied.

**Prominent style label color:** The renderer sets `contentTintColor = whiteColor`
on macOS (NSButton) and `baseForegroundColor = whiteColor` on iOS destructive-
Prominent path. The Prominent background uses `controlAccentColor` on macOS (tracks
dark mode) and UIButton.Configuration's built-in filled background on iOS (also
adaptive). White text on blue fill is high contrast in both appearances.

**Destructive role (both appearances):** `NSColor.systemRedColor` /
`UIColor.systemRedColor` are dynamic system tokens that track dark mode.
Light resolves to approximately `(1.0, 0.23, 0.19)`; dark resolves to approximately
`(1.0, 0.27, 0.23)`. Clearly distinct from system blue in both appearances.
Destructive-Prominent path overrides `baseBackgroundColor = systemRedColor`
and `baseForegroundColor = whiteColor` on iOS; overrides `bezelColor = systemRedColor`
on macOS.

**Cancel role (both appearances):** Font weight is overridden to `:semibold`
automatically. The semibold weight is visible in both light and dark; the system
font at semibold renders distinctly heavier than the regular-weight default button.

**SF Symbol glyphs (both appearances):** Symbol glyphs are monochrome template
images. On macOS, NSButton renders templates in the system control color (black
in light, near-white in dark) rather than the attributed-title foreground color.
On iOS, symbol renders in `tintColor` (system blue by default), not in the
custom `baseForegroundColor`. For destructive+symbol combinations this creates a
color mismatch (symbol in system color, label in red). Both parts remain legible;
the red label communicates the role. Open deviation in the validation report.

**Contrast caveat for brand overrides:** If a brand color is used for
`foreground_color`, verify contrast in BOTH appearances before shipping. A brand
color that passes in light may be indistinguishable from the dark background in
dark mode. Use a semantic color token rather than a baked RGBA whenever possible.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving
up HIG's legibility, hit targets, or appearance-tracking._

**Swap the accent to your brand primary.**
```crystal
# Override foreground_color for Default/Bordered/Borderless styles.
# Keep role == :destructive unchanged -- systemRedColor is a HIG safety signal.
btn = UI::Button.new("Confirm")
btn.foreground_color = UI::Color.new(r: 0.20, g: 0.70, b: 0.45)  # brand green

# For Prominent style, foreground_color does not affect the fill background.
# The fill comes from UIButton.Configuration.filled / NSButton bezelColor.
# Use foreground_color only for label tint on Default/Bordered/Borderless.
```

**Replace the HIG-default bordered style with a flat brand surface.**
```crystal
# Use Borderless to remove all bezel chrome. This is the only way to
# produce a truly flat button surface -- no UIVisualEffectView involved.
# Trade-off: removes the visual affordance that the element is interactive.
# HIG: "Plain buttons are useful when you want to show just a label."
flat_btn = UI::Button.new("Skip", style: UI::ButtonStyle::Borderless)
flat_btn.foreground_color = UI::Color.new(r: 0.45, g: 0.45, b: 0.45)  # brand gray
# Warn: Borderless buttons must rely on position / context to signal
# interactivity. Pair with a visible tap state if possible.
```

**Override typography while keeping HIG spacing.**
```crystal
btn = UI::Button.new("Confirm", style: UI::ButtonStyle::Prominent)
btn.font = UI::Font.new(
  family: "YourBrand-Sans",
  size: 17.0,              # keep HIG 17pt body size; do not go below 15pt
  weight: :semibold        # optional; Default renderer uses regular for non-cancel
)
# Do NOT set an overly small size. UIButton's intrinsic content size enforces
# the HIG 44x44pt iOS hit target via its configuration's contentInsets.
# A tiny font pushes the visible tap target below 44pt.
```

## Feel recipes
Short examples that map design intent to code.

**"I want a clear primary call-to-action in a form"**
Use Prominent style at the bottom of the form VStack, role `:default`, verb-first label.
```crystal
submit = UI::Button.new("Book Now", style: UI::ButtonStyle::Prominent) { submit_form }
submit.accessibility_label = "Book reservation"
```
HIG: "use a button that has a prominent visual style for the most likely action
in a view." -- Buttons / Style.

**"I want a destructive confirmation that is unmistakably dangerous"**
Use Prominent style + `:destructive` role to produce a solid red filled button.
```crystal
del = UI::Button.new("Delete Account",
  role: :destructive,
  style: UI::ButtonStyle::Prominent)
del.accessibility_label = "Delete account permanently"
```
HIG: "Don't assign the primary role to a button that performs a destructive
action, even if that action is the most likely choice." -- Buttons / Role.
(Use Prominent only when the user has already been warned via an Alert or
ConfirmationDialog -- do not use Prominent+Destructive as the first point of contact.)

## What happens on each platform
- **iOS 26**: UIButton via `+[UIButton buttonWithConfiguration:primaryAction:]`.
  UIButtonConfiguration variant: `grayButtonConfiguration` (Default/Bordered),
  `filledButtonConfiguration` (Prominent), `tintedButtonConfiguration` (Tinted),
  `plainButtonConfiguration` (Borderless). Role colors applied via
  `setBaseBackgroundColor:` / `setBaseForegroundColor:` on the configuration
  before button creation. Tap handlers route via `CrystalActionDispatcher` on
  `UIControlEventTouchUpInside = 64`. Falls back to `UIButtonTypeSystem` on
  pre-iOS-15 where `UIButtonConfiguration` is unavailable.
- **iPadOS 26**: Same as iOS 26.
- **macOS 26**: NSButton with `NSBezelStyleRounded = 1` (Default/Bordered/Prominent)
  or `NSBezelStyleFlexiblePush = 12` (Tinted) or `isBordered = false` (Borderless).
  Prominent applies `setBezelColor: NSColor.controlAccentColor` + `setContentTintColor:
  NSColor.whiteColor`. Destructive-Prominent overrides `bezelColor = systemRedColor`.
  Label applied via `nsbutton_set_colored_title` (NSAttributedString with foreground
  color + font). SF Symbol via `setImage:` + `setImagePosition: NSImageLeading (7)`.
  Tap handlers route via `CrystalActionDispatcher` with `setTarget:action:`.

## HIG citations (validated)
- Buttons -> Best practices: "a button needs a hit region of at least 44x44 pt
  -- in visionOS, 60x60 pt -- to ensure that people can select it easily, whether
  they use a fingertip, a pointer, their eyes, or a remote."
- Buttons -> Style: "use a button that has a prominent visual style for the most
  likely action in a view. To draw people's attention to a specific button, use a
  prominent button style so the system can apply an accent color to the button's
  background."
- Buttons -> Role: "a primary button uses an app's accent color, whereas a
  destructive button uses the system red color."
- Buttons -> Role: "a cancel button can be one of two types: one that cancels an
  action and one that closes a view."
- Buttons -> Platform considerations -> macOS: "The standard button type in macOS
  is known as a push button. You can configure a push button to display text, a
  symbol, an icon, or an image, or a combination of text and image content."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/buttons.md](../validation/reports/buttons.md)

## Related
- `UI::IconButton` -- when the action is best communicated by an SF Symbol with
  no label (icon-only; no text).
- `UI::LinkButton` -- when the action navigates to a URL or external destination
  rather than committing a side effect.
- `UI::ToggleButton` -- when the button represents a binary state that persists
  (use `UI::Toggle` for switch-style presentation instead).
- `UI::MenuButton` -- when a single tap should present a menu of further options
  (HIG pull-down button pattern).
