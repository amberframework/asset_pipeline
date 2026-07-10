---
slug: edit-menus
verdict: PASS_WITH_NOTES
validated_at: 2026-04-17T15:09:56Z
iteration: 29
verdict_per_appearance:
  macos_light: PASS_WITH_NOTES
  macos_dark:  PASS_WITH_NOTES
  ios_light:   PASS_WITH_NOTES
  ios_dark:    PASS_WITH_NOTES
---

# Edit menus -- Visual validation

## HIG reference
![HIG ref](../../../apple-hig/images/components-edit-menu-intro.png)

## Rendered -- macOS (light)
![macOS light](../screenshots/edit-menus-macos-light.png)

## Rendered -- macOS (dark)
![macOS dark](../screenshots/edit-menus-macos-dark.png)

## Rendered -- iOS (light)
![iOS light](../screenshots/edit-menus-ios-light.png)

## Rendered -- iOS (dark)
![iOS dark](../screenshots/edit-menus-ios-dark.png)

## Verdict: PASS_WITH_NOTES

This refresh puts the edit-menu study on calmer centered plates across both
hosts. The structure now reads in one glance, leaves visible amber gutters, and
keeps the menu anatomy focused on clipboard, selection, and lookup actions
instead of incidental scene clutter.

### What improved
- macOS now uses an ambient composition with a short "Edit" header and tighter
  grouping, which makes the menu read like a deliberate study instead of a
  document screenshot.
- iOS now renders as a centered card against the warm backdrop instead of being
  trapped inside the document scene, so the menu plate is visible and stable in
  both appearances.

### Remaining notes
1. The rows still render as pill buttons rather than native `NSMenuItem` /
   `UIEditMenuInteraction` rows.
2. Labels still follow the systemic orange-blue action tint path rather than a
   true label-color menu treatment.
3. Runtime-presented menus remain richer than the inline capture path.

These are real notes, but they no longer undermine the default taste or legibility.
