---
slug: context-menus
verdict: PASS_WITH_NOTES
validated_at: 2026-04-16T20:45:00Z
iteration: 25
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark: PASS_WITH_NOTES
  ios_light: PASS_WITH_NOTES
  ios_dark: PASS_WITH_NOTES
---

# Context menus -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-context-menu-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/context-menus-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/context-menus-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/context-menus-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/context-menus-ios-dark.png)

## Verdict: PASS_WITH_NOTES

The new captures finally read like a menu study instead of a broken mockup. The menu
surface is centered, the action hierarchy is legible, and the destructive action now
lands with the right visual weight.

### What improved
- The menu width is restrained enough to feel intentional on both platforms.
- The amber-themed environment is present but no longer overwhelms the menu itself.
- Destructive treatment, separators, and action spacing are clear and readable.

### Why this is still notes-only
- The study still shows a staged menu surface rather than a true invoked context-menu
  interaction anchored to content.
- The macOS preview keeps a little more supporting chrome than the HIG example needs,
  so it still reads slightly like a demo scene.

### Result
This is strong enough to count as `PASS_WITH_NOTES`. The remaining gap is more about
interaction realism than basic layout taste.
