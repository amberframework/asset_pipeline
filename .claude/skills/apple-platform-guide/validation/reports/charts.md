---
slug: charts
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T17:18:24Z
iteration: review-2026-04-16c
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS_WITH_NOTES
  ios_dark:    PASS_WITH_NOTES
---

# Charts — Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-charts-intro.png)

## Rendered — macOS (light)
![macOS light](../screenshots/charts-macos-light.png)

## Rendered — macOS (dark)
![macOS dark](../screenshots/charts-macos-dark.png)

## Rendered — iOS (light)
![iOS light](../screenshots/charts-ios-light.png)

## Rendered — iOS (dark)
![iOS dark](../screenshots/charts-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The chart row is no longer broken. Both platforms now show a real focal chart
instead of backdrop-only frames, and the macOS study plate has been reduced to
something proportionate enough to read at a glance. It stays
PASS_WITH_NOTES because the iOS chart still presses the right edge a bit and
the dark-mode weekday labels remain softer than they should be.

### Evidence manifest
- **Manifest:** `../evidence/charts.json`
- **Required captures:** PASS — all four files present and > 10 KB.
- **Report links:** PASS — all four appearance-specific screenshot filenames
  linked above.

### Light appearance observations
- macOS: the bar chart now sits in a centered, disciplined plate instead of a
  tiny insert inside a much larger shell.
- iOS: the chart is visible and legible, with the title and overall bar
  anatomy reading correctly in the compact card.

### Dark appearance observations
- macOS: the dark chart is now centered tightly enough that the study reads as
  a deliberate preview rather than leftover chrome.
- iOS: the bars and title remain readable, but the rightmost edge still feels
  tight and the x-axis labels are lower-contrast than ideal.

### Deviations / notes
- The iOS chart renderer still uses a fixed-width composition that leaves the
  final weekday label close to the frame edge.
- This row is promotion-worthy again, but there is still room for a renderer
  pass focused on axis-label contrast and compact-width balance.

### Source citations
- Apple HIG — "Charts" (see `apple-hig/pages/charts.md` in the skill corpus).

### Remediation (if NEEDS_WORK)
N/A — notes only.
