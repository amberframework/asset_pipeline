# Phase 8D.3b Brief Critique — Codex Antagonist (Architect-Side, Iter 1)

**Date:** 2026-05-25
**Brief reviewed:** `phase-08-ergonomic-mvc-api/brief-8d.3b.md` (v1)
**Source log:** `/tmp/codex-critique-brief-8d3b.log`.

## Verdict: REVISE — NOT DISPATCH-READY

16 findings: **4 BLOCKER**, 5 HIGH, 4 MEDIUM, 3 LOW. All addressed in v2.

## Findings

### BLOCKER 1 — iOS scenario route override is not actually wired

Swift's `@State` always initializes from `VOYAGER_ROOT_SLUG` (`VoyagerApp.swift:17`). The Crystal-side scenario walks `coord` into a target route, but Swift then calls `voyager_render(swift_slug)` with the slug it was launched with. `render_slug`'s depth-1 resync (`bridge.cr:217`) treats this as first-launch and calls `coord.replace_root(swift_route)` — undoing the scenario's coord walk.

**Resolution (v2):** Two complementary fixes:
1. Capture script sets BOTH `VOYAGER_CAPTURE_SCENARIO` and `VOYAGER_ROOT_SLUG` per scenario. A `scenario → expected_slug` mapping in the script: row-04 → "voyager-todo-editor", row-02 → "voyager-todos", etc.
2. Scenario walks the coord to the target route depth-1 (using `coord.replace_root`, not `push`). Then Swift's slug request matches coord.current.id → resync is a no-op → render walks the right screen.

For multi-depth scenarios (e.g. row-08 "editor prefilled from swipe-Edit" needs `[todos, todo_editor]` stack), the scenario uses `replace_root(:todos)` then `push(:todo_editor)`, ending at depth 2. The depth-1 resync only fires at depth 1, so multi-depth scenarios are unaffected.

### BLOCKER 2 — Row 4 "typed title" cannot render as typed via FormState.register

`TodoEditorScreen` renders `title_field.text = seed_title` where `seed_title = editing ? editing.title : ""` (`todo_editor.cr:38,66`). `save.disabled` also reads `seed_title` at render time. Calling `dispatcher.current_form_state.register("title", "Rem 6.11 test")` populates the form registry but does NOT change the rendered title or save state.

**Resolution (v2):** Reframe row 4 scenarios to walk into the **editor-with-prefilled-existing-todo** state. Add a seeded todo at construction (or reuse one of the 5 seed rows) with title "Rem 6.11 test", then `coord.push(:todo_editor, {todo_id: "<that_id>"})`. The editor opens prefilled → `seed_title == "Rem 6.11 test"` → title field renders with text + Save is enabled (after 8D.3a's closure runs ONCE post-render? No — 8D.3a's closure runs on title-field's on_change; at initial render, `save.disabled = seed_title.strip.empty?` from `:120` covers it: non-empty seed = enabled).

This reframe also covers rows 5 (after-save) + 9 (after-edit-save) — both end at "Todos with that row visible."

Row 4 caption in README updated: "Editor opened on a pre-existing todo with title 'Rem 6.11 test'; Save enabled." This is the visible state the contract calls for.

### BLOCKER 3 — macOS count/math wrong

Brief said "skip rows 7, 8, 10 → 12 rows × 2 = 24 macOS." That's 11 rows (14 − 3), not 12 — 22 captures, not 24. Codex HIGH 4 also flagged that AppKit renders SwipeActionRow as visible trailing buttons natively, so rows 7, 8, 10 ARE capturable on macOS.

**Resolution (v2):** macOS captures ALL 14 rows × 2 appearances = **28 macOS captures**. AppKit's natural inline-actions rendering covers what iOS shows as swipe-revealed; the macOS row-07 capture shows the row with its trailing Edit + Delete buttons visible.

Total matrix: 28 iOS + 28 macOS = 56 captures (down from "52" the v1 brief miscalculated, up from "the iOS-only treatment" v1 implied).

### BLOCKER 4 — Capture script points at the wrong macOS binary

Makefile builds `macos/bin/voyager` (`Makefile:37`), brief said `macos/build/voyager-host`.

**Resolution (v2):** Fix the path. `VOYAGER_BIN="samples/initiative-cross-platform-ui-voyager/macos/bin/voyager"`.

### HIGH 1 — Scenario apply timing requires precise mount discipline

Dispatcher token timeline: `HostBootstrap.build` calls `mount_screen` → token 1 with Sign-in FormState. Scenario then mutates `coord` and (must) call `dispatcher.mount_screen(coord.current)` → token 2 with the final route's FormState.

**Resolution (v2):** Brief explicitly requires the scenario's LAST call to be `dispatcher.mount_screen(coord.current)`. ALL coord mutations happen BEFORE the final mount_screen. This guarantees `dispatcher.current_form_state` is seeded from the scenario's final route params.

### HIGH 2 — FormState.register is seed-only, not write-through

`@values[name] = initial unless @values.has_key?(name)` (`form_state.cr:66`). Calling `register` on a new key only seeds; on an existing key it's a no-op.

**Resolution (v2):** Brief no longer claims register simulates typing. The route-params + seeded-todo approach in BLOCKER 2's resolution drives visible state through `seed_title`, not through FormState.register.

### HIGH 3 — SwipeActionRow has no force-revealed setter

`swipe_action_row.cr:62` exposes only content, leading/trailing actions, mobile_breakpoint_px. No revealed-state setter. UIKit renderer doesn't have a force-reveal hook.

**Resolution (v2):** Row-07 iOS capture is **honest evidence boundary** — ship the captured PNG with the row at REST (closed, like row-02), and document in README: "Row 07 iOS capture shows the row at rest; swipe-revealed state is gesture-driven and has no static representation in the current UIKit::SwipeActionRow rendering. Hand-test gate verifies the live swipe gesture."

NO API change to `UI::SwipeActionRow` in 8D.3b. Documenting the limitation is more honest than faking it.

macOS row 07 capture shows the AppKit-native trailing buttons (already in the renderer) — that IS the macOS visual of "actions revealed."

### HIGH 4 — macOS already has the inline-actions equivalent

`appkit_renderer.cr:3801` already renders SwipeActionRow as visible trailing buttons. This is the macOS natural state — there's no separate "revealed" state to construct.

**Resolution (v2):** All 14 macOS captures use the existing AppKit rendering. Rows 7, 8, 10 macOS captures show the buttons inline. No special handling needed.

### HIGH 5 — `simctl launch --setenv` not verified

The local precedent in `VoyagerVisualTests.swift:25` uses XCUITest `launchEnvironment`, not `simctl --setenv`. Codex couldn't verify Apple docs (file-read constraint).

**Resolution (v2):** Use the proven-working XCUITest `launchEnvironment` pattern. The capture driver becomes an XCUITest test method that runs all scenarios via `xcodebuild test`. Each scenario's app launch carries `VOYAGER_CAPTURE_SCENARIO` + `VOYAGER_ROOT_SLUG` + `VOYAGER_APPEARANCE` via `app.launchEnvironment`. The test captures `XCUIScreen.main.screenshot()` and writes via `XCTAttachment` — OR writes directly to disk via `FileManager` if attachment retrieval is awkward.

Verified working pattern: `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift:30-32` already uses `app.launchEnvironment = ["VOYAGER_ROOT_SLUG": slug, "VOYAGER_APPEARANCE": appearance]`.

### MEDIUM 1 — macOS renderer reads HIG_APPEARANCE, not VOYAGER_APPEARANCE

`appkit_renderer.cr:3986` checks `HIG_APPEARANCE`. The host passes `VOYAGER_APPEARANCE` to the capture window, but token-resolved colors stay light unless `HIG_APPEARANCE` is also set.

**Resolution (v2):** Capture script sets BOTH `VOYAGER_APPEARANCE="$appearance" HIG_APPEARANCE="$appearance"`.

### MEDIUM 2 — Scenario file not required anywhere

`app.cr:37` requires screens/controllers only. Crystal doesn't auto-load sibling files.

**Resolution (v2):** Implementer adds `require "./capture_scenarios"` to `samples/initiative-cross-platform-ui-voyager/app.cr` after the existing requires. The require is unconditional — the scenarios module is a no-op if `VOYAGER_CAPTURE_SCENARIO` isn't set.

### MEDIUM 3 — Row 14 needs distinct artifact

V1 said "share the file" with row 02. Codex correctly flags: artifact mapping table needs distinct entries even if images are visually identical.

**Resolution (v2):** Row 14 generates its own PNG file. README documents the equivalence.

### MEDIUM 4 — Full simctl launch command not validated

Replaced entirely by the XCUITest pattern (HIGH 5 resolution). The `xcrun simctl ui appearance` part stays — it's the simulator-level appearance switch.

### LOW 1 — FormState.register comment vs code contradiction

Documentation trap. NOT in 8D.3b scope; flagged for a future cleanup phase.

### LOW 2 — Time-based screenshot wait

XCUITest pattern uses `waitForExistence(timeout:)` against expected AX-tree elements per scenario. Brief Item 6 should specify the wait pattern (poll for a known scenario-specific AX element, then capture).

### LOW 3 — Scenario API route_params unused

V1 returned `route_params` in the Result, but the iOS snippet ignored them. Either thread params through to `coord.replace_root` / `push` calls or drop the field.

**Resolution (v2):** Scenario calls `coord.replace_root/push` directly with params. `Result` carries only the route_id for slug-mapping purposes. `route_params` field dropped.

## Architectural impact summary

V1's premise was: write Crystal scenarios that walk state; capture via `simctl launch --setenv` + shell script. Both halves of that premise broke:
- Crystal scenarios can walk state, BUT Swift's @State + `render_slug`'s depth-1 resync fight the walk unless the script also matches `VOYAGER_ROOT_SLUG` (BLOCKER 1).
- `simctl --setenv` is unverified; XCUITest `launchEnvironment` is the proven pattern (HIGH 5).

V2 rebases on the proven XCUITest pattern AND the scenario-aware slug matching. The capture driver becomes an XCUITest test method that loops scenarios + appearances, launches with the matched env vars, polls for a scenario-specific AX element, screenshots, and writes to disk.

— Codex (medium reasoning, arg-form prompt)
