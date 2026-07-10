---
slug: toggles
ui_view: UI::Toggle
priority: P0
platforms: [iOS, iPadOS, macOS]
hig_page: ../../../apple-hig/pages/toggles.md
validation_report: ../validation/reports/toggles.md
---

# UI::Toggle

> A binary switch that lets people choose between on and off states; on iOS/iPadOS it renders as a UISwitch (pill-shaped track, white thumb, green-on-tintable), and on macOS as an NSButton(buttonType: Switch) checkbox style — no Liquid Glass material required for either platform.

## Feel of the flow
_What this component "means" in a UI, and when to reach for it._

A toggle expresses a single binary setting that takes effect immediately. Reach for it when the user controls something whose value flips between two opposing states — notifications on/off, a feature enabled/disabled, a mode active/inactive — and where the current state must be visible at a glance without any confirmation step.

Do NOT use a toggle to choose among three or more options (use a `UI::Picker` or `UI::SegmentedControl`), to trigger a one-shot action (use a `UI::Button`), or to select items from a list (use a `UI::Checkbox` or `UI::ListView` with multi-select).

(HIG: "Use a toggle to help people choose between two opposing values that affect the state of content or a view." -- Toggles / Best practices.)

## Quickstart

```crystal
# Row: label to the left, UISwitch to the right -- the canonical HIG pattern.
row = UI::HStack.new(spacing: 12.0)

label = UI::Label.new("Notifications")
label.accessibility_label = "Notifications setting label"
row << label.as(UI::View)

toggle = UI::Toggle.new("", true)   # label="" so the label is on the HStack, not the control
toggle.accessibility_label = "Notifications toggle, on"
row << toggle.as(UI::View)
```

Renders: UISwitch (iOS/iPadOS) with a green pill-shaped track and a white thumb at the trailing edge when `is_on: true`; gray track with thumb at leading edge when `is_on: false`. On macOS, renders as NSButton(buttonType: Switch) -- a checkbox-style control with a blue filled square and white checkmark when on, an empty rounded square when off.

## Customization

| Knob | Type | Default | Effect |
|------|------|---------|--------|
| `label` | `String` | `""` | Title text rendered inside the control on macOS NSButton; leave empty and place the label in an HStack to the left per HIG iOS pattern. |
| `is_on` | `Bool` | `false` | Initial on/off state. `true` = ON (green track on iOS, blue filled checkbox on macOS). |
| `disabled` | `Bool` | `false` | When `true`, calls `setEnabled:NO` on UISwitch (iOS) / NSButton (macOS), dimming the control and making it non-interactive. |
| `tint_color` | `Color?` | `nil` | On iOS, calls `setOnTintColor:` to override the default green track. On macOS NSButton the tint is not applied (planned: NSSwitch migration). |
| `style` | `ToggleStyle` | `Switch` | `Switch` (pill UISwitch / NSButton switch) or `Checkbox` (maps to NSButton checkbox on macOS; falls back to UIButton toggle on iOS). |
| `on_change` | `Proc(Bool, Nil)?` | `nil` | Callback invoked with the new Bool state when the user toggles. |
| `accessibility_label` | `String?` | `nil` | VoiceOver label. Required for interactive elements per HIG. |
| `opacity` | `Float64` | `1.0` | View-level alpha. Prefer `disabled = true` for non-interactive dimming; use `opacity` only for cosmetic layering. |

**Theming**: `UI::Toggle` uses system-level colors (`UIColor.systemGreen` for ON track, `UIColor.systemGray4` for OFF track on iOS) and does not route through `UI::Theme` color tokens. To change the ON color, use `tint_color`. See `foundations/color-and-theming.md` for the sentinel-swap pattern used by other views.

## Light / dark appearance notes

**iOS light:** UISwitch ON track resolves to `UIColor.systemGreen` in light mode -- approximately RGB 0.20/0.78/0.35. OFF track resolves to `UIColor.systemGray4` -- approximately RGB 0.82/0.82/0.84. White thumb (~1.0 RGB) is legible against both. Contrast (thumb vs ON track) ~4.8:1; (thumb vs OFF track) ~1.8:1 -- UISwitch thumb contrast is a known platform trade-off at small sizes, but the filled-color track provides the state cue rather than thumb legibility alone.

**iOS dark:** `UIColor.systemGreen` darkens to approximately RGB 0.19/0.82/0.35 in dark mode -- slightly brighter, maintaining contrast against the dark UIViewController background (~0.0 RGB). OFF track resolves to `UIColor.systemGray4` dark variant -- approximately RGB 0.30/0.30/0.30. White thumb remains ~1.0 RGB. All legible. The sentinel-swap pattern used by Label / TextField / RichText does not apply here because UISwitch colors are system-managed, not baked from a Crystal color literal.

**macOS light:** NSButton(buttonType: Switch) ON state renders with system accent blue fill (~0.0/0.478/1.0) and a white checkmark. OFF state is an empty rounded square with a light-gray border (~0.75 RGB) on white background. Both states have good contrast against the white window background.

**macOS dark:** Same NSButton renders with system accent blue (auto-adapted to DarkAqua) for ON. OFF state is an empty rounded square with a slightly lighter border on the dark window background (~0.12 RGB). The OFF vs disabled distinction on dark macOS is subtle: both show an empty square, with the disabled one having marginally lighter border rendering. This is a known NSButton limitation; NSSwitch provides a clearer disabled appearance.

**SF Symbol variants:** `UI::Toggle` does not render SF Symbols directly. On macOS NSButton checkbox, the checkmark glyph is system-rendered, not a user-supplied SF Symbol.

**Custom tint contrast caution:** When overriding `tint_color` for iOS, ensure the custom color provides sufficient contrast with the white thumb (~4.5:1 recommended for body-size elements). Very light or very bright hues (e.g. yellow, light cyan) may fail contrast at small UISwitch track sizes. Test in both light and dark appearances.

## Customization / brand override
_How to go from the HIG-default look to your brand voice, without giving up HIG's legibility, hit targets, or appearance-tracking._

**Swap the ON track color to your brand primary.**
```crystal
# Replace the default green with your brand accent.
# On iOS, setOnTintColor: accepts any UIColor; ensure contrast >= 4.5:1 with white thumb.
toggle = UI::Toggle.new("", true)
toggle.tint_color = UI::Color.new(r: 0.522, g: 0.176, b: 0.996)  # brand purple
toggle.accessibility_label = "Feature toggle, on, brand color"
```
Keep the `is_on`, `disabled`, and `accessibility_label` knobs unchanged. The spacing, hit target (UISwitch is fixed ~51x31pt on iOS, meeting the 44pt minimum), and label placement in the HStack should remain HIG-default.

**Replace the glass material with a flat brand surface.**
```crystal
# UI::Toggle is a control, not a surface component, so there is no glass material
# to replace. If the toggle is embedded in a container that has a glass surface
# (e.g. UI::Sheet or UI::Popover), override the container's surface, not the toggle.
# Example: toggle inside a flat brand card instead of the default glass popover.
card = UI::Card.new
card.background = UI::Color.new(r: 0.96, g: 0.96, b: 0.97)  # brand gray background
card.corner_radius = 12.0
# Add the toggle row inside the card's VStack.
```
Note: Removing glass from `UI::Sheet` or `UI::Popover` that hosts a toggle reduces
the Liquid Glass effect on the container. The toggle itself is unaffected. Cite
`validation/gaps.md` if the enclosing surface loses HIG-required glass.

**Override typography while keeping HIG spacing.**
```crystal
# The "label" placed beside the toggle in the HStack uses UI::Label.
# Override its font while preserving the 12pt HStack spacing and the
# UISwitch's own non-configurable typography.
label = UI::Label.new("Notifications")
label.font = UI::Font.new(family: "YourBrandFont", size: 17.0, weight: :regular)
label.accessibility_label = "Notifications setting label"
```
The UISwitch's own label property (passed as the first `UI::Toggle` argument)
is rarely used on iOS per HIG recommendation ("Use the switch toggle style only
in a list row" -- the row content provides context). Keep the HIG pattern of an
HStack with the label as a separate `UI::Label` and the toggle's `label` as `""`.

## Feel recipes
Short examples that map design intent to code.

**"I want a settings row that dims the toggle when a prerequisite is unmet."**
```crystal
toggle = UI::Toggle.new("", user_is_signed_in && feature_enabled)
toggle.disabled = !user_is_signed_in
toggle.accessibility_label = "Premium feature toggle#{toggle.disabled ? ", requires sign-in" : ""}"
```

**"I want a toggle with a custom on-color that matches both light and dark."**
```crystal
# UIColor system colors adapt automatically. For a custom tint, use a color
# that is legible in both appearances -- a mid-saturation hue works better
# than a near-white or near-black custom color.
toggle = UI::Toggle.new("", true)
toggle.tint_color = UI::Color.new(r: 0.2, g: 0.5, b: 0.9)  # brand blue, mid-sat
```

## What happens on each platform
- **iOS 26**: UISwitch -- `setOn:animated:` for state, `setOnTintColor:` for custom ON track color, `setEnabled:` for disabled dimming. Default ON track: `UIColor.systemGreen`. Pill-shaped, ~51x31pt, exceeds 44pt HIG minimum.
- **iPadOS 26**: Same as iOS -- UISwitch adapts to iPad screen density with identical behavior.
- **macOS 26**: NSButton(buttonType: 3 / NSButtonTypeSwitch) -- checkbox-style control. `setState:` for on/off, `setEnabled:` for disabled. NOTE: the HIG recommends `NSSwitch` for macOS 10.15+ for pill-shape parity; the current renderer uses NSButton which renders a checkbox. Future iteration will migrate to NSSwitch. `tint_color` is not applied on macOS.

## HIG citations (validated)
- Toggles / Best practices: "Use a toggle to help people choose between two opposing values that affect the state of content or a view."
- Toggles / Best practices: "Make sure the visual differences in a toggle's state are obvious. For example, you might add or remove a color fill, show or hide the background shape, or change the inner details you display -- like a checkmark or dot -- to show that a toggle is on or off. Avoid relying solely on different colors to communicate state, because not everyone can perceive the differences."
- Toggles / Platform considerations / iOS, iPadOS: "Change the default color of a switch only if necessary. The default green color tends to work well in most cases, but you might want to use your app's accent color instead. Be sure to use a color that provides enough contrast with the uncolored appearance to be perceptible."
- Toggles / Platform considerations / iOS, iPadOS: "Use the switch toggle style only in a list row. You don't need to supply a label in this situation because the content in the row provides the context for the state the switch controls."
- Toggles / Platform considerations / macOS / Switches: "Prefer a switch for settings that you want to emphasize. A switch has more visual weight than a checkbox, so it looks better when it controls more functionality than a checkbox typically does."

Validation report with side-by-side HIG ref / live screenshots:
[validation/reports/toggles.md](../validation/reports/toggles.md)

## Related
- `UI::Checkbox` -- use for hierarchical grouped settings on macOS where checkbox visual alignment is preferred over switch visual weight.
- `UI::SegmentedControl` -- use when the user must choose from three or more mutually exclusive options.
- `UI::RadioGroup` -- use for 2-5 mutually exclusive options where each needs a distinct label.
- `recipes/settings-form.md` -- multi-row settings form combining UI::Toggle, UI::Slider, and UI::Picker in a HIG-compliant layout.
