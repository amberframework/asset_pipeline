---
title: Accessibility defaults
topic: accessibility
hig_pages:
  - accessibility.md
---

# Accessibility defaults

## What it means

Accessibility on Apple platforms is a floor, not a feature. Every control must
be reachable by VoiceOver, the minimum hit target must be satisfied for pointer
and touch users, and the system's Dynamic Type / Reduce Motion / Increase
Contrast settings must be respected.

Five defaults that are non-negotiable:

1. **44x44pt minimum hit target on iOS**, 60x60pt on visionOS. Touch targets
   smaller than this are a hard fail — not a style choice.
2. **Every interactive control needs an accessibility label.** VoiceOver reads
   this. An unlabeled button is invisible to a screen-reader user.
3. **Honor Dynamic Type.** When the user scales text, your UI must scale with
   it. Cropping or truncating text at the user's preferred size is a fail.
4. **Contrast minimums.** Per WCAG Level AA (which Apple's Accessibility
   Inspector measures against): 4.5:1 for text up to 17pt, 3:1 for text ≥18pt
   or bold text.
5. **Reduce Motion.** If your UI uses animation, provide a reduced-motion
   variant or opt out of the animation entirely when the setting is on.

The HIG frames these as the minimum to be "intuitive, perceivable, and
adaptable" — not as optional adornments.

## How it's expressed in asset_pipeline

### Accessibility labels

Every `UI::View` has an `accessibility_label` property (source: `src/ui/view.cr`):

```crystal
abstract class View
  property accessibility_label : String? = nil
  property id : String? = nil
  property test_id : String? = nil
  # ...
end
```

The asset_pipeline CLAUDE.md states the rule plainly:

> Every interactive element MUST have `accessibility_label` set.

Do this on construction:

```crystal
btn = UI::Button.new("Save")
btn.accessibility_label = "Save changes"

img = UI::Image.new("logo.png")
img.accessibility_label = "Amber Pipeline logo"
```

The `id` property is for programmatic lookup (e.g. from AXTest). The `test_id`
property maps to a platform-native test identifier (NSAccessibilityIdentifier /
accessibilityIdentifier) for XCUITest-style automation. See `ax-test` skill for
the test-harness API.

### Hit targets

**Automatic hit-target enforcement is planned.** Today views render at their
intrinsic native size — for `UIButton`, that's typically ≥44pt tall already,
but a `UIButton` with a single-character label might render at ~28pt. To
guarantee 44x44pt, set `minimum_width` and `minimum_height`:

```crystal
close_btn = UI::Button.new("×")
close_btn.minimum_width = 44.0
close_btn.minimum_height = 44.0
close_btn.accessibility_label = "Close"
```

On macOS the HIG's equivalent guidance is 28pt tall for standard controls with
mouse pointers, but Accessibility Keyboard users still benefit from 44pt. When
in doubt, go 44.

### Dynamic Type

See `typography.md` — full Dynamic Type support is planned. Today size values
are static. Until the `Font.preferred(:body)` API lands, test your UI at the
"accessibility" Dynamic Type sizes manually and verify no text is clipped.

### Focus rings

On macOS, keyboard-focus rings are drawn by AppKit automatically on controls
(`NSButton`, `NSTextField`). On iOS 26, external-keyboard focus follows the
same system behavior on `UIControl` subclasses. The asset_pipeline renderers
pass through; you generally don't need to manage focus rings yourself. If you
disable them (via `focusRingType = .none`), the HIG says you must supply a
visible replacement.

### Reduce Motion

**Reduce Motion honoring is planned.** When animation APIs land in
asset_pipeline, they'll check `UIAccessibility.isReduceMotionEnabled` and scale
durations / swap transitions accordingly. For now, avoid elaborate custom
animations and prefer the system's default transitions (which respect the
setting).

## Cross-references

- `accessibility` skill — WCAG 2.2 AA details (focus management, ARIA, motion
  preferences).
- `ax-test` skill — macOS accessibility-tree verification. The AXTest library
  queries the real AX tree of a running app; an unlabeled interactive view
  will fail an AXTest assertion.

## HIG citations

- **Accessibility → Vision**: the WCAG contrast minimums and font-weight
  interaction. (`pages/accessibility.md`)
- **Accessibility → Vision**: the platform default/minimum text-size table.
  (`pages/accessibility.md`)
- **Buttons → Best practices**: "a button needs a hit region of at least 44x44
  pt — in visionOS, 60x60 pt." (`pages/buttons.md`)
- **Accessibility** (article intro): an accessible interface is "intuitive,
  perceivable, and adaptable." (`pages/accessibility.md`)
