---
slug: page-controls
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T22:22:00Z
iteration: 27
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Page controls -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-page-dots-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/page-controls-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/page-controls-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/page-controls-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/page-controls-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This is now a much better component study. The dots sit inside a compact,
centered composition with enough surrounding gutter that the page-control rhythm
is the thing being judged instead of a lot of empty backdrop.

### What improved
- The indicator rows are now framed as a disciplined study rather than floating
  labels in open space.
- The default and amber-tinted variants keep the same shape language and read at
  a glance in both appearances.
- iOS and macOS both present the control as a restrained indicator, not a fake
  navigation strip.

### Why this is still notes-only
- macOS still uses the synthetic page-control fallback, because AppKit has no
  native `NSPageControl`.
- The study is intentionally isolated and compact; it proves the default taste
  of the indicator, not its behavior inside a full paging flow.

### Result
Promote this row to `PASS_WITH_NOTES`. It is now clean, legible, and focused
enough to count as the default baseline.
