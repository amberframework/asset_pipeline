---
slug: sidebars
iteration: 20
diagnosed_at: 2026-04-15
---

# sidebars fix diagnosis — root cause report

## macOS — wireframe bars (Hypothesis confirmed)

Root cause: **Hypothesis 3 (closest) — but the actual mechanism was that
`visit(NavigationSplitView)` used a plain `NSView` as `outer`, not an
`NSStackView`, so content and detail children received `addSubview:` at
origin {0,0} with zero AutoLayout constraints.**

Specific code site: `src/ui/renderers/appkit_renderer.cr`, the
`visit(view : UI::NavigationSplitView)` method (now at ~line 1940).
The original outer container was:

```crystal
outer = alloc_init("NSView")
```

Content and detail panes were rendered into `outer` via:

```crystal
push_stack(outer_native, is_nsstack: false)
content.accept(self)
pop_stack
```

`push_native` with `is_nsstack: false` calls `addSubview:` (not
`addArrangedSubview:`), which places child views at their last-set frame
— which for newly-alloc-inited views is `{0, 0, 0, 0}`. No constraints
existed to give them a real size. The result: the content VStack's
NSTextField labels rendered at zero height, appearing as the grey
horizontal bars seen in the June captures.

The VStack and Label construction in `hig_showcase.cr` (lines 1872–1927)
was correct Crystal code — the text content was there. The bug was
entirely in the renderer's layout container.

Fix applied: replaced `NSView` with a horizontal `NSStackView` (Fill
distribution) as `outer`. The sidebar glass column is now added directly
as an arranged subview of `outer` (not via `push_native` which would
target the parent). Content and detail panes each get their own vertical
`NSStackView` column added as arranged subviews of `outer`, with
AutoLayout giving them real frames.

## macOS — orphaned floating inset

Root cause: the original `visit(NavigationSplitView)` called
`push_native(sidebar_effect_native)` to attach the glass sidebar column.
`push_native` checks `@stack.last?` — at that point, the parent in the
stack is the InboxScene's page `VStack` (an NSStackView), not `outer`.
So the glass sidebar was inserted as an arranged subview of the page's
NSStackView ABOVE `outer`, appearing as an orphaned floating panel in the
bottom-left corner of the capture alongside the "INBOX / Amber / Rituals
/ Vault / Deep Work" list (which was the msg_list VStack also being
misrouted).

Fix applied: the sidebar glass column is now added directly to `outer`'s
arranged subviews array without going through `push_native`.

## iOS — TabView floating at 35% width

Root cause: `build_focal` in `hig_bridge.cr` (lines 2107–2114) branches
on `scene_for_slug(slug)`. For "sidebars", `scene_for_slug` returns `nil`,
so the TabView gets placed inside the outer `vstack = UI::VStack.new(spacing: 16.0)`
at line 2110. This VStack has no `minimum_width`/`minimum_height` set,
so UIKit sizes it to its intrinsic content width — the UIVisualEffectView
holding the tab bar derives its intrinsic width from the tab cells' label
text widths, which resolves to approximately 35% of the iPhone viewport.

Fix applied: added `minimum_width = 375.0`, `minimum_height = 812.0`,
`maximum_width = 375.0`, `maximum_height = 812.0` on the `ios_tabview`
in the "sidebars" case arm of `build_focal`. This forces the UIStackView
wrapper in `build_focal` to size to 375x812pt — full iPhone viewport —
which anchors the bottom tab bar to the bottom of the view frame.

The Memories tab content was also updated from a single `"Memories"` label
to 5 Amber message rows (same content as macOS: sender / subject / preview /
timestamp, amber gold avatars, 68pt row height) per the spec.

## Captures (iteration 20)

- sidebars-macos-light.png: 250,070 bytes
- sidebars-macos-dark.png: 254,056 bytes
- sidebars-ios-light.png: 423,012 bytes
- sidebars-ios-dark.png: 375,687 bytes

All four captured Apr 15 2026. macOS: real message rows visible, orphan
inset gone, sidebar glass material visible. iOS: full-width layout,
message list above tab bar, tab bar at bottom of viewport.
