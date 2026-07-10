---
slug: column-views
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T23:33:10Z
iteration: 1
verdict_per_appearance:
  macos_light: PASS
  macos_dark: PASS
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Column views -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-column-view-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/column-views-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/column-views-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/column-views-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/column-views-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The current study now reads as a real column browser instead of a placeholder:
measured column widths, a visible selected path, and enough amber-backed
breathing room to keep the hierarchy legible. It stays notes-only because the
component is fundamentally macOS-shaped and the iOS presentation is an honest
fallback study rather than a native platform control.

### Light appearance observations

- macOS light presents the strongest read: the browser feels Finder-like,
  centered, and properly framed, with labels no longer collapsing into narrow
  wrapped columns.
- iOS light stays clear and useful, with a compact drill-down card instead of a
  full-window faux file manager.

### Dark appearance observations

- macOS dark keeps the hierarchy readable and preserves depth without turning
  into one flat slab.
- iOS dark remains legible, with selection and column boundaries still visible
  against the darker plate.

### Deviations

1. iOS is a portability fallback, not a native Apple column-browser control.
2. The study isolates the browser rather than embedding it in a richer Finder-
   style document context.

### Remediation (if NEEDS_WORK)

N/A -- notes only.
