# Iter B Captures Report

**Date:** 2026-04-14
**Binary:** samples/cross_platform/macos_host/bin/hig_showcase (rebuilt 20:24, 3335536 bytes)

## Captures completed

All 40 PNGs produced fresh. macOS at 20:24-20:25, iOS at 19:58-20:10.

| Slug | macOS light | macOS dark | iOS light | iOS dark |
|------|------------|-----------|----------|---------|
| sidebars | 216KB | 224KB | 210KB | 210KB |
| split-views | 210KB | 211KB | 154KB | 154KB |
| buttons | 968KB | 1281KB | 667KB | 918KB |
| toggles | 968KB | 1259KB | 574KB | 826KB |
| sliders | 957KB | 1223KB | 624KB | 893KB |
| image-views | 856KB | 1022KB | 582KB | 786KB |
| rating-indicators | 392KB | 386KB | 650KB | 910KB |
| charts | 735KB | 820KB | 491KB | 754KB |
| labels | 224KB | 216KB | 477KB | 746KB |
| boxes | 150KB | 142KB | 494KB | 671KB |

## Infrastructure issue: GC regression

The macOS binary rebuilt at 20:12 produced blank white PNGs (75928 bytes) for ALL
slugs. Root cause: Crystal's escape analysis treated the `native`/`native_chrome`/
`native_focal` NativeView variables as dead after their last explicit reference
(objc_install_content_view at line 2642), allowing a GC collection during the
subsequent objc_run_loop_for(0.6) call to release the NativeView objects' ObjC
retains. With retains released, NSView arranged subviews removed themselves from
their NSStackView parents before CGWindowListCreateImage captured the compositor
frame. The resulting capture was all-white (window background only).

Fix: added a gc_guard tuple `gc_guard = {native, native_chrome, native_focal}`
followed by `GC.collect` (to flush any pending collection while guards are in
scope) and `_ = gc_guard` after the capture to ensure the compiler keeps the
references live through the entire critical section. Filed in hig_showcase.cr
at the objc_run_loop_for call site.

The 19:35 binary was not affected because it compiled from an older version of
hig_showcase.cr (pre-19:50) which happened to reference `native` later in the
file (in the interactive path setup code that preceded the screenshot path in
the older layout), keeping the variable live through the run loop incidentally.

## Key capture spot-checks

**sidebars-macos-dark** (224KB): Amber inbox scene on dark brown sidebar
backdrop. MEMORIES section (Inbox 12, Dreamed, Noted, Archived) with SF Symbol
glyphs and Amber gold tint on active row. VAULTS section (Morning Pages,
Sketches, Rituals, Code Spells). Right pane shows 5 message rows with
sender/subject/preview. Title bar "Amber / Inbox / Compose" visible.

**buttons-macos-light** (968KB): Amber Preferences window on orange-peach
gradient. Left nav sidebar (General/Appearance/Rituals/Vaults/Sounds). Right
form panel with Button Style/Role Gallery: Default/Continue, Prominent (pill),
Tinted/Add to List, Bordered/Options, Borderless/Learn more, Destructive/Delete
(system red), Cancel (semibold), Disabled/Unavailable (gray), SF Symbol/Share,
Dest+Symbol/Remove. Destrucive and cancel role wiring visible.

**charts-macos-light** (735KB): Amber Focus dashboard on orange-peach gradient.
Left stat column: 2h 14m/Today, 7/Streak, 12/Distortions with Amber plum SF
Symbol icons. Right chart card: "Focus minutes this week" title + Mon-Sun bar
chart with Amber plum (#5B3A94) bars, Thu tallest (138min), Sat second (157min).
21pt card padding enforced -- bars do not touch card edges.

**image-views-ios-dark** (786KB): Gallery scene on Amber gold gradient, dark
appearance. Shows SF Symbol star.fill (60pt, system blue tint), square
thumbnail placeholder (gray bordered 120x120), circular avatar (tan fill 64pt
diameter), rounded card (12pt radius). All 4 image-view variant rows visible.

## Dashboard

Regenerated at 20:25. Output: validation/index.html + snapshot
validation/index-39of63-2026-04-15.html. Worklist state unchanged (row states
not updated in this pass -- captures only).
