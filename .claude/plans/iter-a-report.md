# Iter A Report -- Scene Library + 6 Pilot Slug Re-Captures

**Date:** 2026-04-14
**Iteration:** Iter A (scene-library restructure)

## What was built

### 3 scene composer classes

All three exist in `src/ui/validation_scenes/` (required by `src/ui/validation_scenes.cr`):

**`dashboard_scene.cr` -- DashboardScene**
Top bar (Amber wordmark + search stub + avatar), left sidebar (MEMORIES: Inbox 12, Dreamed, Noted, Archived; VAULTS: Morning Pages, Sketches, Rituals, Code Spells), main area (two content cards: "2h 14m of deep work" focus card + Recent memories card with sun.max / hourglass / wand.and.stars rows), focal centered via split-install path (`build_chrome` + `objc_install_content_view_centered`). focal_position: `:center_modal`, `:toolbar_trailing`.

**`document_scene.cr` -- DocumentScene**
Title bar (back chevron + "Morning Pages · April 14"), document body (three journal paragraphs with three highlighted selection lines in Amber gold 45% opacity, cursor-bar divider after selection), focal placed adjacent to selection via HStack push-right. focal_position: `:adjacent_to_selection`.

**`dock_scene.cr` -- DockScene**
5-icon dock bar (calendar, envelope, safari, sparkles [Amber], gearshape) with frosted glass tray, Amber icon highlighted with gold border, focal (dock menu surface) stacked above Amber icon with downward-arrow tail, desktop background via Amber cream fallback (real gradient via HIG_BACKDROP_PATH). focal_position: `:above_dock_icon`.

### Worklist.json -- scene field on 6 pilot slugs

All 6 pilot slugs carry `"scene"` field (verified via `python3 -c` query):
- sheets, alerts, popovers: `"scene": "dashboard"`
- edit-menus, context-menus: `"scene": "document"`
- dock-menus: `"scene": "dock"`

### Capture driver changes

`hig_showcase.cr` carries:
- `SLUG_SCENES` constant mapping the 6 slugs to scene names.
- `scene_for_slug` / `wrap_in_scene` helpers.
- Dashboard split-install path: chrome rendered via `build_chrome`, focal rendered separately, `objc_install_content_view_centered` installs focal with per-slug max_width (540 sheets, 380 alerts, 320 popovers, 400 default).
- Document/dock: single tree full-stretch via `objc_install_content_view`.
- iOS dispatch in `hig_bridge.cr` similarly routes scene-wrapped slugs.

### Nitpick fixes (inline)

**Card/Box default content padding:** `UI::Card#content_padding` defaults to `EdgeInsets.new(top: 21.0, trailing: 21.0, bottom: 21.0, leading: 21.0)` (Fibonacci-golden Lg token). The property and the default are in `src/ui/views/card.cr` line 27. Renderers consume it. Title and body no longer kiss the card corners.

**Alert body NSTextField width:** Body NSTextField capped at 238pt (`objc_constrain_width(msg_field, 238.0)`) in `appkit_renderer.cr` line 1213 -- card_width (270pt) minus edge insets (16pt x 2). Prevents the two-column artifact on "Amber cannot restore them".

**Popover case arm:** Stray toggles replaced with a realistic filter popover (title "Filter" + Sort-by segmented picker [Newest first / Oldest first] + Vault segmented picker [Morning Pages / All vaults] + "Clear filters" button). HIG-canonical contextual panel use case.

**Dock-menu arm:** Menu rendered directly inside DockScene (popped open above Amber icon with tail arrow). No separate closed-state. The menu surface (Sheet grouped_card wrapping custom items, recent docs, system items) is the focal.

**Menu renders (edit-menus, context-menus):** Both render in open-state (glass surface with full item list) adjacent to selected text in DocumentScene. Verified in captures below.

## Visual description of 6 re-captured slugs

**sheets (macOS light/dark, iOS light/dark):** "Conjure Reminder" sheet card centered over the Amber dashboard -- MEMORIES sidebar on the left with Inbox 12 badge visible, "2h 14m of deep work" focus card in the upper right. The sheet card sits over Amber cream (light) / deep ember (dark) gradient backdrop with frosted glass visible. Component is unambiguously IN the Amber app context.

**alerts (macOS light/dark, iOS light/dark):** "Reshape today's timeline?" alert card centered over same dashboard chrome. Cancel (blue, semibold) and Reshape (system red, destructive) buttons visible in both light and dark. iOS dark shows Amber gold gradient bleeding through the glass surface behind the card.

**popovers (macOS light/dark, iOS light/dark):** "Filter" popover with Sort-by and Vault segmented pickers centered over dashboard chrome. iOS dark shows the filter popover sliding up from bottom of the dashboard, Amber gold backdrop visible through glass.

**edit-menus (macOS light/dark, iOS light/dark):** DocumentScene with journal text, three selected lines in Amber gold tint, and the edit-menu glass surface (Cut/Copy/Paste / Select All / Find / Look Up / Translate / Share with keyboard shortcuts) adjacent to the selection. Component reads as a contextual text-editing menu, not a floating tile.

**context-menus (macOS light/dark, iOS light/dark):** Same DocumentScene with Cut/Copy/Paste/Share/Duplicate/Delete (destructive) context-menu surface positioned to the right of the selected text block. Amber gold selection tint is visible above the menu. Clear spatial relationship between selection and menu.

**dock-menus (macOS light/dark):** DockScene: cream/ember gradient desktop, frosted dock bar at bottom with calendar/envelope/safari/sparkles (Amber, gold-bordered)/gearshape icons, "New Window / Open Recent / Recent docs / Options / Quit" menu surface floating above the Amber icon with downward-arrow tail. iOS captures show the dock-menu in a simplified flat layout (DockScene renders on both platforms; dock is macOS-only per HIG -- iOS captures exist for completeness and show the component list without the dock chrome).

## Infrastructure gotchas

**`objc_install_content_view_centered` is load-bearing for dashboard slugs.** Without the split-install path (chrome full-stretch, focal centered independently), Auto Layout cannot correctly position the modal card -- it would be pinned to the stack's first subview position rather than centered over the chrome. The split-install is the reason modal components look properly centered.

**DockScene iOS caveat:** `dock-menus-ios-light/dark.png` are 2.7 MB because the iOS test harness renders the full DockScene including all icon text labels -- the SF Symbol text strings ("calendar", "envelope", "sparkles") render as large rendered text blocks. These are not show-stoppers but a future iteration should use actual SF Symbol rendering via UIImage(systemName:) rather than plain label text.

**`withinWindow` blending + clear root background:** The `window.backgroundColor = .clear` and `NSVisualEffectView` `setBlendingMode: 1` (withinWindow) are load-bearing for glass bleed-through on both platforms. Both are in place from Phase 0.1/0.2.

## Dashboard regenerated

`python3 .claude/skills/apple-platform-guide/validation/build_index.py` ran successfully:
- `validation/index.html` -- current dashboard (39/63 terminal rows)
- `validation/index-39of63-2026-04-14.html` -- snapshot
