---
slug: boxes
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T20:45:00Z
iteration: 25
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Boxes -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-box-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/boxes-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/boxes-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/boxes-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/boxes-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The refreshed captures are finally using honest gutters and readable padding on both
platforms. The component now reads like a small grouped container instead of content
stuck to the rounded edges.

### What improved
- Both platforms now keep clear ambient space around the box, so the amber backdrop
  remains visible and the component no longer feels edge-hugging.
- The content padding reads correctly in the rounded container. Labels and values no
  longer crowd the corners.
- Dark mode is legible on both platforms, with the card surface clearly separated
  from the background.

### Why this is still notes-only
- The study is still a staged validation card rather than a more literal macOS/iOS
  settings-style composition.
- The iOS framing is cleaner than before, but the box still rides a little high in
  the capture instead of feeling perfectly centered in the viewport.

### Result
This is a good default taste baseline now. Keep it as `PASS_WITH_NOTES` until the
host framing becomes a little calmer and more platform-native.
