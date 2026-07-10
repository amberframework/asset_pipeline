---
slug: split-views
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T22:24:00Z
iteration: 27
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Split views -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-split-view-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/split-views-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/split-views-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/split-views-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/split-views-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This now reads as a real split-view study instead of a broken compact-width
capture. The macOS side shows the pane relationship clearly, and the iPhone
study now explains compact collapse with intentional stacked surfaces instead of
letting content drift off-screen.

### What improved
- The iOS compact-flow study now fits fully inside the frame and keeps sidebar,
  list, and detail roles legible.
- macOS keeps the pane structure and divider story visible without as much noisy
  copy fighting the layout.
- Both platforms now communicate hierarchy of panes at a glance instead of
  relying on the reviewer to infer it from broken positioning.

### Why this is still notes-only
- The iPhone study is a compact adaptation, not a literal live regular-width
  split-view presentation.
- The macOS scene still leans product-like rather than fully isolated, so there
  is room to make the structural anatomy even cleaner later.

### Result
Promote this row to `PASS_WITH_NOTES`. The default composition is now stable and
honest enough to count as part of the library’s baseline taste.
