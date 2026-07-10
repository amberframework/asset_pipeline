---
slug: text-views
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T22:56:00Z
iteration: 28
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Text views -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-text-view-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/text-views-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/text-views-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/text-views-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/text-views-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This batch fixed the one thing that would have made the row hard to trust:
macOS once again shows actual text content instead of a near-empty shell, and
iOS keeps the reading surface compact and legible inside the card.

### What improved
- macOS now renders both text surfaces with visible content and calm spacing.
- iOS presents a clean two-state study instead of a tall, half-clipped demo.
- Both platforms read like native editing surfaces rather than debug captures.

### Why this is still notes-only
- The study is intentionally simplified: it validates the default surface,
  spacing, and legibility, not a full editing workflow with selection chrome.
- The iOS sample uses a compact read/edit presentation rather than a richer
  document-style composition.

### Result
Promote this row to `PASS_WITH_NOTES`. The default text-view surface now feels
clean and dependable on both platforms.
