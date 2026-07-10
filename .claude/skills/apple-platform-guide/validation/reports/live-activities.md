---
slug: live-activities
verdict: SKIPPED
validated_at: 2026-04-17T00:00:00Z
iteration: 1
verdict_per_appearance:
  macos_light: "n/a (extension surface)"
  macos_dark:  "n/a (extension surface)"
  ios_light:   "n/a (extension surface)"
  ios_dark:    "n/a (extension surface)"
---

# Live Activities -- Validation note

## HIG reference
![HIG ref](../../../apple-hig/images/components-live-activities-intro.png)

## Verdict: SKIPPED

`UI::LiveActivities` is now an export-oriented ActivityKit metadata surface, not
a drawable in-app component. The shard can model activity attributes, content
state, and update intents, but the rendered Lock Screen and Dynamic Island
surfaces remain system-owned.

### What is implemented

- live activity catalog metadata
- attribute payload export
- content-state payload export
- optional update-intent metadata
- deterministic ActivityKit scaffold export

### Why validation stays skipped

The HIG row is about a system presentation surface. The useful implementation
work here is in the exported metadata contract, not in faking the Live Activity
card inside an app-owned screenshot.
