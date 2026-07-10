# Translation Matrix

**Companion to:** `intent-catalog.md`, `intent-routing-candidates.md`, `tier-2-translation-contract.md`.

For each Class A intent, the per-platform default translation: which existing `UI::View` class implements the default, or `MISSING` (backlog entry).

This matrix is small because Class A has 1 entry. As more Class A intents are identified in future phases (`:reorder_list_items` is a candidate per the co-plan), the matrix grows.

---

## Class A intent: `:swipe_actions`

| Platform | Default widget | Status | Notes |
|---|---|---|---|
| iOS | `UI::SwipeActionRow` | ✅ shipped (trailing edge) | `src/ui/views/swipe_action_row.cr:19,64-65`; UIKit renderer emits swipe gesture via `make_swipe_reveal_row` (`src/ui/renderers/uikit_renderer.cr:3823-3870`). Trailing edge only; leading edge is a Phase 10B.1b target. |
| iPadOS | `UI::SwipeActionRow` | ✅ shipped (trailing edge) | Same as iOS. |
| macOS | `UI::InlineActionRow` | ❌ **MISSING — see backlog B-001 (P0)** | The named default class does not exist anywhere in `src/`. `UI::SwipeActionRow` is currently rendered as inline buttons on AppKit (`src/ui/renderers/appkit_renderer.cr:3801-3826`), but the named widget should match the visual representation. Phase 10B.1a delivers the class. |
| Android | `UI::SwipeActionRow` (stub) | ⚠️ partial | Android renderer is explicitly a stub at `src/ui/renderers/android_renderer.cr:3148-3152` — renders only the content view, defers proper `SwipeToDismissBox` integration to Phase 10B.1c. **Backlog item B-035 (P1).** |
| web_wide | `UI::InlineActionRow` | ❌ **MISSING — see backlog B-002 (P0)** | The named default class does not exist anywhere in `src/`. Desktop web has no native swipe gesture; inline trailing buttons (with hover affordance) are idiomatic. Phase 10B.1a delivers the class. |
| web_narrow | `UI::SwipeActionRow` | ✅ shipped (web renderer) | Mobile web JS-driven swipe-reveal via `src/ui/renderers/web_renderer.cr:2887-2911`. Honors leading edge today (`web_renderer.cr:2909-2911`); native paths are trailing-only — see capability block trim in `intent-routing-candidates.md`. |

**2/6 default translations shipped; 1/6 partial (Android stub); 2/6 MISSING (the Class A intent's named default class does not exist for macOS or web_wide); 1/6 shipped via SwipeActionRow as default.** See `intent-backlog.md` for B-001 (P0), B-002 (P0), B-035, B-036 (P0).

---

## Freshness reconciliation

Running `ls src/ui/views/*.cr | wc -l` against the repo on 2026-05-25 returns **79** top-level files, and `find src/ui/views -name '*.cr' | wc -l` returns **82** once the `_gate_stubs/` subdirectory is included. Those 82 source files break down into **four mutually-exclusive buckets**: **73 ordinary top-level `UI::View` subclasses** (`button.cr`, `text_field.cr`, `vstack.cr`, etc.); **3 Tier 3 gated widgets** (`action_sheet.cr`, `context_menu.cr`, `path_control.cr`) whose class definitions live behind `{% if flag?(...) %}` macros per CLAUDE.md:148-160; **3 `*_with_web_fallback.cr` companion classes** (`action_sheet_with_web_fallback.cr`, `context_menu_with_web_fallback.cr`, `path_control_with_web_fallback.cr`) that ship the cross-platform path for each Tier 3 widget; and **3 gate-stub siblings** under `src/ui/views/_gate_stubs/` (`action_sheet.cr`, `context_menu.cr`, `path_control.cr`) whose only job is to emit a `{% raise %}` compile-time error on non-matching builds. 73 + 3 + 3 = 79 top-level files; 79 + 3 gate stubs = 82. A handful of view files also define *presenter* helper classes inside the same file (e.g., `UI::ActivityViewPresenter` in `activity_view.cr`, `UI::PopoverPresenter` in `popover.cr`, `UI::SheetPresenter` in `sheet.cr`, `UI::SnackbarPresenter` in `snackbar.cr`); these do not change the file count, but `widget-intent-mapping.md` calls them out in the Reason column where they exist. The **canonical view-type count is 79** (the top-level `*.cr` files in `src/ui/views/`). The **scoping-9 reference to "80 view types" is approximate** (it predates the latest commit). The **`component-mapping-matrix` skill's count of 59** captures only the *cross-platform-mapped* widgets and intentionally omits the renderer-internal presenters, the gate stubs, and the WithWebFallback companions. **`tier-matrix.md` lists only 78 widget rows** (17 Tier 1 + 55 Tier 2 + 3 Tier 3 gated + 3 WithWebFallback companions); spot-checking the source tree against the matrix shows it currently omits `swipe_action_row.cr`, which is a staleness in `tier-matrix.md` rather than a discrepancy in the source tree. `widget-intent-mapping.md` (Item 6) audits all 82 files (the 79 top-level + the 3 gate stubs) so every row in the source tree is accounted for.

---

## Future Class A candidates (not yet promoted)

These are mentioned in the co-plan but did not meet the Class A bar in Phase 9:

- `:reorder_list_items` (`onMove`) — currently Class D. If drag-handle (iOS) vs up-down-buttons (web-wide) proves to be different widgets rather than the same widget with platform-different rendering, this gets promoted to Class A.
- `:navigation_split_view` — currently Class D. If `NavigationStack` on compact vs `NavigationSplitView` on regular size-class proves to require different widget classes (not just different renderer behavior), it could become Class A. The current `UI::NavigationStack` + `UI::NavigationSplitView` setup treats them as separate widgets the author picks; that may already be correct.

Future phases evaluate these candidates against the materially-different-widget bar. The default expectation is "stay Class D unless proven otherwise."

— Architect (Claude Opus 4.7)
