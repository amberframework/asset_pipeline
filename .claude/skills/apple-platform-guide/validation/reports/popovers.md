---
slug: popovers
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T17:18:24Z
iteration: review-2026-04-16c
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS_WITH_NOTES
  ios_dark:    PASS_WITH_NOTES
---

# Popovers — Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-popovers-intro.png)

## Rendered — macOS (light)
![macOS light](../screenshots/popovers-macos-light.png)

## Rendered — macOS (dark)
![macOS dark](../screenshots/popovers-macos-dark.png)

## Rendered — iOS (light)
![iOS light](../screenshots/popovers-ios-light.png)

## Rendered — iOS (dark)
![iOS dark](../screenshots/popovers-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This row is back in a usable state. The iOS host now captures a centered,
fully in-frame popover instead of losing the surface off the leading edge, and
the simplified option rows read much more cleanly than the earlier segmented
control experiment. It remains PASS_WITH_NOTES because both platforms are
still showing a study-card interpretation of a popover rather than a more
anchored, truly transient presentation.

### Evidence manifest
- **Manifest:** `../evidence/popovers.json`
- **Required captures:** PASS — all four files present and > 10 KB.
- **Report links:** PASS — all four appearance-specific screenshot filenames
  linked above.

### Light appearance observations
- macOS: the popover remains readable and on-brand inside the Amber scene.
- iOS: the popover now sits cleanly within the frame with stable hierarchy and
  enough gutter to judge the content.

### Dark appearance observations
- macOS: the dark popover keeps the warm palette and readable contrast.
- iOS: the dark study is now centered and calm, with the selected rows and
  clear-filters action reading cleanly against the darker glass surface.

### Deviations / notes
- The iOS preview uses simplified static option rows to avoid segmented-control
  layout artifacts in compact width; this is visually better, but still more of
  a study composition than a fully anchored system popover.
- The row is trustworthy again for backlog purposes, but there is still room
  for a richer anchored-presentation pass later.

### Source citations
- Apple HIG — "Popovers" (see `apple-hig/pages/popovers.md` in the skill corpus).

### Remediation (if NEEDS_WORK)
N/A — notes only.
