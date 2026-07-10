---
slug: progress-indicators
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T20:45:00Z
iteration: 25
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Progress indicators -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-progress-indicators-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/progress-indicators-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/progress-indicators-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/progress-indicators-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/progress-indicators-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This family looks a lot more disciplined now. The centered study card gives the
spinner and progress rows enough room to breathe, and the amber backdrop stays in a
supporting role.

### What improved
- Both platforms now frame the study as a single component plate instead of letting
  the progress controls drift in a wide empty scene.
- The determinate bar, spinner pair, and cancel affordance all stay readable at a
  glance.
- Dark-mode contrast is solid; the progress fill and cancel action still read clearly.

### Why this is still notes-only
- Static screenshots can only prove structure, not motion, so the indeterminate cases
  are still a validation approximation.
- The cancel/upload row is serviceable, but it still feels more like a showcase stack
  than a polished shipping workflow.

### Result
Keep this at `PASS_WITH_NOTES`. The taste is close; the remaining gap is mostly in the
behavior story and a little last-mile composition polish.
