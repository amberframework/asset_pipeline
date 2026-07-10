---
slug: segmented-controls
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T23:33:10Z
iteration: 2
verdict_per_appearance:
  macos_light: PASS
  macos_dark: PASS
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Segmented controls -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-segmented-control-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/segmented-controls-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/segmented-controls-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/segmented-controls-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/segmented-controls-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The study is materially better now: both platforms present the control in a
centered, believable card instead of letting it drift or clip at the edge of
the frame. macOS now lives on the same calm ambient plate as the better recent
batches, while iOS still keeps a small notes-only caveat because the icon-style
row is text-backed rather than true SF Symbol imagery.

### Light appearance observations

- macOS light feels balanced and native, with enough surrounding space to make
  the selected segment read immediately.
- iOS light now stays inside the capture frame cleanly and no longer feels like
  the control is being shoved offscreen.

### Dark appearance observations

- macOS dark keeps the selection state clear without overemphasizing the blue
  accent.
- iOS dark preserves legibility and spacing, with the same remaining note about
  text-based icon labels.

### Deviations

1. The icon-oriented variant still uses symbol names as text labels instead of
   real SF Symbol image segments.

### Remediation (if NEEDS_WORK)

N/A -- notes only.
