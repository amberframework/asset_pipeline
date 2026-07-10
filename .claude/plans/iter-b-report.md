# Iter B Report -- Scene Library Expansion (5 New Scene Composers)

**Date:** 2026-04-14
**Iteration:** Iter B (scene-library restructure)

## What was built

### 5 new scene composer classes

All five exist in `src/ui/validation_scenes/` and are required by `src/ui/validation_scenes.cr`:

**`inbox_scene.cr` -- InboxScene**
Left sidebar (~200pt): MEMORIES (Inbox 12 via tray icon + badge in label / Dreamed / Noted / Archived) + VAULTS (Morning Pages / Sketches / Rituals / Code Spells), each row using `UI::Image.new(symbol)` for the SF glyph. Right content: 5 Amber-voice messages with sender / subject / preview and unread indicator dots. Three focal positions: `:left_pane` (focal replaces sidebar), `:right_pane` (focal replaces message list), `:full_2pane` (focal wraps entire body, chrome only added above).

**`settings_scene.cr` -- SettingsScene**
Title bar: gear `UI::Image` + "Amber · Preferences" wordmark. Left nav sidebar (~160pt): General (selected, Amber gold tint) / Appearance / Rituals / Vaults / Sounds with `UI::Image` SF glyphs. Right panel: HIG form rows with ~120pt right-aligned label column and flexible control column, 34pt minimum row height, 8pt row gap. Two focal positions: `:single_row` (focal embedded in one labeled form row between context stubs) and `:multi_row` (focal placed as a full-width block between stub rows).

**`gallery_scene.cr` -- GalleryScene**
Title bar: "Amber · Memories" + segmented grid/list toggle (SegmentedControl). Three focal positions: `:grid_full` (focal IS the gallery content, wrapped with 21pt padding), `:inline_rows` (five memory rows each carrying the focal on the trailing edge -- rating-indicators use case), `:carousel` (three Amber memory cards in an HStack with 21pt tile gap + focal page-control dots below centered). Tile icons use `UI::Image.new(symbol)` with Amber gold tint. `GalleryScene.memory_tile` is a public class method for external tile construction.

**`chart_scene.cr` -- ChartScene**
Title bar: "Amber · Focus" + "This week" label. Two-column body: narrow left stat column (~140pt) with three plum-accented stat blocks (2h 14m / Today / hourglass, 7 / Streak / flame, 12 / Distortions / wand.and.stars via `UI::Image`), wide right chart card. Chart card: title row + "Mon-Sun" subtitle + 21pt content_padding (mandatory Iter B nitpick -- chart does not touch card edges). Two focal positions: `:card_focal` (focal inside card), `:inline_rows` (focal beside each stat block -- progress bars, activity indicators).

**`ambient_scene.cr` -- AmbientScene**
Minimal chrome: amber sparkles `UI::Image` + "Amber" wordmark, single hairline divider. Content: focal centered both horizontally and vertically with 55pt padding from window edges (xxl Fibonacci-golden token). Optional `context_label` string shown in small secondary gray above the focal. Used for labels, boxes, text-fields, search-fields, text-views.

### `src/ui/validation_scenes.cr` updated

Now requires all 8 scene files (3 from Iter A + 5 new).

### `hig_showcase.cr` SLUG_SCENES + wrap_in_scene updated

`SLUG_SCENES` constant extended to 41 entries covering all slugs in the Iter B mapping table. `wrap_in_scene` extended with `when "inbox"`, `when "gallery"`, `when "chart"`, `when "settings"`, `when "ambient"` arms. Each arm selects the correct `focal_position` per slug. Dashboard/document/dock arms augmented with slug-aware position selection.

### worklist.json scene fields added

`"scene"` and `"focal_position"` fields added to all 29 slugs in the Iter B mapping table:
- inbox: sidebars (left_pane), split-views (full_2pane), lists-and-tables (right_pane)
- gallery: collections, image-views (grid_full), rating-indicators (inline_rows), page-controls (carousel)
- chart: charts (card_focal), progress-indicators (inline_rows)
- settings: buttons, toggles, sliders, disclosure-controls, color-wells (multi_row); steppers, pickers, segmented-controls, pop-up-buttons, pull-down-buttons, combo-boxes (single_row)
- document: menus (adjacent_to_selection)
- dashboard: toolbars, tab-bars, tab-views (toolbar_trailing); activity-views (center_modal)
- ambient: text-fields, text-views, search-fields, labels, boxes (centered)

### Crystal build

`crystal-alpha build --no-codegen -Dmacos samples/cross_platform/macos_host/hig_showcase.cr` passed clean (zero errors, zero warnings).
`crystal-alpha tool format` applied to all 5 new scene files.

## Re-captures: status

The 10 slug / 40 PNG re-captures called for in the Iter B spec are a separate runtime step (requires macOS host binary + iOS simulator + screenshot harness). This report covers the source deliverables (scene classes, worklist wiring, SLUG_SCENES dispatch). Iter B re-captures run via the standard capture commands after the host binary is built:

```bash
make -C samples/cross_platform/macos_host showcase SLUG=sidebars
crystal-alpha spec spec/ui/hig_validation/macos_visual_spec.cr -Dmacos \
  --link-flags="-framework ApplicationServices -framework CoreFoundation" \
  -- --only sidebars
```

Repeat for: sidebars, split-views, buttons, toggles, sliders, image-views, rating-indicators, charts, labels, boxes.

## Dashboard

`python3 .claude/skills/apple-platform-guide/validation/build_index.py` regenerated:
- `validation/index.html` -- current dashboard (39/63 terminal rows, unchanged row states)
- `validation/index-39of63-2026-04-14.html` -- snapshot

## Infrastructure notes

- All SF Symbol positions in the 5 new scenes use `UI::Image.new(symbol_name)`, never `UI::Label` with symbol text.
- SettingsScene form rows: labels are vertically centered with controls via HStack + `minimum_height: 34.0` on each row.
- GalleryScene tiles have consistent 21pt inter-tile gap (Fibonacci-golden Lg token).
- ChartScene chart card has explicit `content_padding: EdgeInsets.new(top: 21.0, ...)` on the `UI::Card` so the chart focal does not touch card edges.
