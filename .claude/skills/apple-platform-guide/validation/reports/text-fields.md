---
slug: text-fields
verdict: PASS_WITH_NOTES
validated_at: 2026-04-17T15:26:53Z
iteration: 25
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Text fields -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-text-field-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/text-fields-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/text-fields-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/text-fields-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/text-fields-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The form study is clean and current. It now has the right amount of surrounding gutter,
the fields line up well, and the layout reads like a deliberate default rather than a
rushed demo.

### What improved
- Both platforms keep enough gutter for the form to breathe.
- Labels and field widths are aligned in a way that feels intentional.
- Light and dark appearances are both easy to scan.

### Why this is still notes-only
- The iOS secure field still reads as empty in the static screenshot, which is a
  capture limitation rather than a layout problem.
- The study is good, but it still sits a touch closer to a curated sample than a full
  production form surface.

### Result
This is a solid baseline and should remain `PASS_WITH_NOTES` until the host can present
secure-field state and surrounding form chrome more naturally in capture.
