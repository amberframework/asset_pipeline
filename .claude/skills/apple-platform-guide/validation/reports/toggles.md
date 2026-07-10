---
slug: toggles
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T17:18:24Z
iteration: review-2026-04-16c
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS_WITH_NOTES
  ios_dark:    PASS_WITH_NOTES
---

# Toggles — Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-toggles-intro.png)

## Rendered — macOS (light)
![macOS light](../screenshots/toggles-macos-light.png)

## Rendered — macOS (dark)
![macOS dark](../screenshots/toggles-macos-dark.png)

## Rendered — iOS (light)
![iOS light](../screenshots/toggles-ios-light.png)

## Rendered — iOS (dark)
![iOS dark](../screenshots/toggles-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The toggle row now reads as a stable component study instead of a full-bleed
dump. The role states are clear on both platforms, the study card framing is
calm, and the warm Amber palette stays out of the way of the switch anatomy.
It remains PASS_WITH_NOTES because this is still a compact family plate rather
than a more contextual settings-flow example.

### Evidence manifest
- **Manifest:** `../evidence/toggles.json`
- **Required captures:** PASS — all four files present and > 10 KB.
- **Report links:** PASS — all four appearance-specific screenshot filenames
  linked above.

### Light appearance observations
- macOS: the centered study card gives the switch family enough breathing room
  to compare states quickly.
- iOS: the toggle labels and on/off states are fully visible within the card,
  with no edge pressure from the phone frame.

### Dark appearance observations
- macOS: the dark study preserves contrast and keeps the toggle states easy to
  scan.
- iOS: the darker card maintains clean switch silhouettes and readable label
  hierarchy.

### Deviations / notes
- The control work itself is solid; the remaining gap is contextual richness,
  not anatomy.
- This is a trustworthy PASS_WITH_NOTES row and no longer needs to be treated
  as stale evidence.

### Source citations
- Apple HIG — "Toggles" (see `apple-hig/pages/toggles.md` in the skill corpus).

### Remediation (if NEEDS_WORK)
N/A — notes only.
