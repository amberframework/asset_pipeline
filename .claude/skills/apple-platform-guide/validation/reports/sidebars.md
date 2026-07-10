---
slug: sidebars
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T22:23:00Z
iteration: 27
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Sidebars -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-sidebar-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/sidebars-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/sidebars-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/sidebars-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/sidebars-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The row is in a healthier place now. The macOS captures make the leading
sidebar anatomy readable, and the iPhone study no longer tries to fake a huge
desktop pane inside a narrow frame. Instead it presents a compact navigation
adaptation that is actually reviewable.

### What improved
- The iPhone study now has calm gutter, shorter copy, and a believable selected
  destination instead of a crowded oversized list.
- The selected row, icon rhythm, and trailing count are readable across both
  appearances.
- The macOS composition is tighter, so the sidebar itself reads first instead of
  feeling swallowed by the larger scene.

### Why this is still notes-only
- On iPhone, the HIG discourages literal sidebars, so the iOS study is an
  adaptation of sidebar intent rather than a direct platform match.
- The macOS capture still carries more surrounding product chrome than a fully
  isolated component study.

### Result
Promote this row to `PASS_WITH_NOTES`. The structure is now strong enough to
represent the default taste honestly, with the platform-adaptation caveat
recorded.
