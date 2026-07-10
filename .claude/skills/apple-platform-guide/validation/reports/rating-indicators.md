---
slug: rating-indicators
verdict: PASS_WITH_NOTES
validated_at: 2026-04-17T15:09:56Z
iteration: 2
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS
  ios_dark:    PASS
---

# Rating indicators -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-rating-indicators-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/rating-indicators-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/rating-indicators-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/rating-indicators-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/rating-indicators-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The refreshed study is calmer and more deliberate on both hosts: a compact
centered plate, short row labels, and enough amber breathing room that the star
states read immediately. The anatomy is now clear without feeling like a raw
control dump.

### What improved
- macOS now uses a quieter ambient card with short labels (`Full`, `Partial`,
  `Low`, `Tinted`) and stable row spacing.
- iOS now mirrors that same compact study framing, keeping the synthetic star
  rows visually disciplined instead of loose in the viewport.

### Remaining notes
1. macOS still uses the `NSImageView`/SF Symbol fallback rather than live
   `NSLevelIndicator(style=rating)` in the capture path.
2. iOS remains an idiomatic approximation because HIG does not define a native
   rating-indicator component there.

These are acceptable notes rather than blockers, so the row stays promoted.
