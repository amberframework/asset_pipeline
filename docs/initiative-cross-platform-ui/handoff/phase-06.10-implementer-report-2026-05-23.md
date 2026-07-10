# Phase 6.10 — Implementer Report

**Date:** 2026-05-23
**Branch:** `phase-06.10-navigable-crud-demo`
**Range:** `372b8d9` (architect handoff) → `3c69524` (D4 fix) — 7 commits.

## Summary

Phase 6.10 closes the "Cascade is a screenshot catalog, not a navigable
app" gap raised after Phase 7. Three library primitives shipped + a new
4-screen Voyager Todos demo with the state-propagation litmus passing
at the Crystal contract level.

## Commits

| SHA       | Subject |
|-----------|---------|
| `49db590` | D1 — UI::NavigationCoordinator + spec (15/0) |
| `ac6fdac` | D2 — Web renderer route host (UI::Web.render_route_host + JS shim) |
| `53dfdf6` | D3 — UI::SwipeActionRow + visit impls (web/uikit/appkit/android) |
| `ab75973` | D3 fix — Codex blockers (on_tap_route, JSON safety, breakpoint) |
| `8ea3874` | D4 — Voyager demo: 4 screens + web build + litmus spec (5/0) |
| `3c69524` | D4 fix — Codex blockers (CSS data-attr mismatch, chart write, edit route) |

## Deliverables

### D1 — UI::NavigationCoordinator
- **Path:** `src/ui/navigation_coordinator.cr`, `spec/ui/navigation_coordinator_spec.cr`.
- **API:** `push / pop / replace_root / pop_to_root / on_change / current /
  depth / subscriber_count`. `Route` record holds `id : Symbol` +
  `params : Hash(Symbol, String)`.
- **Instance-level state** — no class vars (I-9 compliant per iOS class-init gap).
- **Notify fires AFTER stack mutation**, so subscribers see the new
  `current`. `pop` at root depth is a no-op (no notify).

### D2 — Web renderer route host
- **Path:** `src/ui/renderers/web_renderer.cr` (`UI::Web.render_route_host`).
- Emits per-route HTML fragment JSON + a JS shim that swaps
  `host.innerHTML` on hashchange / popstate / `UIRouteHost.push()`.
- JSON safety: uses `JSON.build` + post-pass that rewrites `</` to `<\/`
  inside the JSON payload to prevent `</script>` termination.
  `initial_route` HTML-escaped in the data-route attribute.
- aria-live announcer (I-6 a11y).

### D2 (native renderer hooks)
- **NOT shipped as separate renderer changes.** The native hosts (macOS
  NSWindow setContentView swap + iOS SwiftUI @State trampoline) will
  call `Voyager.build_route(state, coord, coord.current)` inside their
  `coord.on_change` handler — the renderer doesn't need internal
  subscription support because the host owns the renderer instance.
  This is the simpler, cleaner pattern. Native host source files are
  deferred (see "Deferred" below).

### D3 — UI::SwipeActionRow
- **Path:** `src/ui/views/swipe_action_row.cr`, `spec/ui/swipe_action_row_spec.cr`.
- `UI::SwipeAction` carries `label / role / icon / on_tap / on_tap_route`.
  `on_tap_route` is the web-only routing hook (Crystal Procs can't run
  client-side in static HTML; `on_tap_route` lets the JS shim push a
  route on tap).
- **Renderer impls (4):**
  - **Web:** content + visible leading/trailing HStack of buttons + a
    `@media`-replacement JS layer (the chrome JS reads
    `data-mobile-breakpoint` per row and adds `.ap-swipe-row--mobile`
    when `window.innerWidth < bp`; CSS targets the class). Touch handlers
    on touchstart/move/end reveal the trailing panel on swipe-left.
    Action button clicks dispatch via `UIRouteHost.push(route)` when
    `data-on-tap-route` is set.
  - **UIKit:** UIStackView (horizontal) with content + inline UIButtons.
    SwiftUI `.swipeActions(edge:)` SwiftKit facade deferred to follow-up.
  - **AppKit:** NSStackView (horizontal) with content + NSButtons inline
    (HIG — macOS has no swipe-to-reveal).
  - **Android:** delegates to content view (Android cross-build remains
    architect-precedent PASS per Phase 1 #17).
- Abstract method added to `UI::PlatformVisitor`; `TestVisitor` updated;
  the 3 compile-gate specs (action_sheet / context_menu / path_control)
  stay green.

### D4 — Voyager demo
- **Path:** `samples/initiative-cross-platform-ui-voyager/`.
- **8 files:** `app.cr`, `brand.cr`, `Makefile`, `screens/{state,sign_in,todos,todo_editor,settings}.cr`, `web/static_site.cr`.
- **Brand:** deep indigo OKLCH(0.42, 0.20, h=280) — visibly distinct
  from Cascade's deep teal (h=195).
- **Web build:** `make -C samples/initiative-cross-platform-ui-voyager web`
  produces `output/voyager-demo/voyager-{light,dark}.html` (single-page
  hash-routed app) + per-screen baselines.
- **Macos + iOS Makefile targets:** stub-defined but the actual host
  source files are deferred — see "Deferred" below.

## State-propagation litmus — PASS (Crystal + web)

`spec/ui/voyager_state_propagation_spec.cr` — 5 examples, 0 failures.

The litmus contract: push :settings → mutate `state.hide_completed=true`
→ pop back to :todos → rebuilt view tree (a) omits the 2 completed
todos, (b) keeps all 3 open todos, (c) shows the filter banner,
(d) chart counts move from 3/2 to 3/0 (reflecting filtered list).

Web demo: `output/voyager-demo/voyager-light.html` carries a
`VoyagerState.refreshTodosChrome()` JS layer that mirrors the same
behavior in the browser (CSS hides `[data-todo-completed=true]` rows
under the `voyager-hide-completed` doc class; JS writes new chart
counts into the `voyager-count-open/done` spans on Settings toggle).
Codex's review of the final state confirmed the JS dispatches via
`UIRouteHost.push()` from Sign in submit, Todos→Settings link, and
Settings back button — wiring is intact.

## Codex checkpoint trail

| # | Phase | Verdict | Notes |
|---|-------|---------|-------|
| 1 | D1 | PASS | API matches brief; notify fires after mutation; no class vars |
| 3 | D3 | BLOCKERS → fixed in ab75973 | on_tap wiring + JSON safety + breakpoint variable |
| 4 | D4 | BLOCKERS → fixed in 3c69524 | data-attr mismatch + chart JS write + edit route |
| 5 | Litmus | **PROGRESS** | Litmus implementation honest; static gen passes |

(Checkpoint 2 was rolled into 3 since D2's native renderer changes
deferred to the host pattern.)

## Regression status

- `crystal spec`: **1490 examples / 4 failures / 0 errors / 66 pending**.
  Baseline 1455/4/0; added 35 new (15 D1 + 7 D2 + 8 D3 + 5 D4 litmus).
  All 4 failures pre-existing (theme inject_theme_css empty-string +
  3 phase2_verification edge cases).
- `crystal run scripts/regenerate_design_tokens.cr` — unchanged.
- `bin/cascade` macOS build closure — unchanged (Cascade demo untouched
  per brief).
- Web semantic build closure — unchanged.

## Deferred (with explicit handoff)

These were scoped in the brief but didn't land in this PR. The
state-propagation contract is proven, so the deferred items are
mechanical, not architectural:

1. **macOS host (`samples/initiative-cross-platform-ui-voyager/macos/host.cr`).**
   Pattern: mirror `samples/initiative-cross-platform-ui-demo/macos/host.cr`
   but instead of building one slug, build the initial route, subscribe
   to `coord.on_change` with a callback that rebuilds the view, renders
   it, and calls `setContentView:` on the NSWindow. Requires the same
   objc_bridge.o + swiftkit_bridge.o + window_helper.o link chain Cascade
   uses. Estimated 1-2 hour effort.

2. **iOS host (`samples/initiative-cross-platform-ui-voyager/ios/`).**
   Pattern: mirror `samples/initiative-cross-platform-ui-demo/ios/`
   (bridge.cr + project.yml + build_crystal_lib.sh + Xcode project).
   New C export `voyager_route_changed(slug : LibC::Char*)` that the
   Swift host's @State binding reads via a Combine subject. When
   `coord.on_change` fires Crystal-side, the bridge calls a Swift
   trampoline to update the @State, which causes SwiftUI to call
   `VoyagerBridge.render(slug:)` again. Estimated 4-6 hour effort
   (Xcode project work + SwiftUI binding).

3. **SwiftUI `.swipeActions(edge:)` SwiftKit facade.** Current UIKit
   impl uses visible HStack buttons (same as macOS). The brief allows
   this as an interim pattern. Full SwiftKit facade for the native
   swipe gesture is a Phase 6.11+ item.

4. **Codex audit harness routing for `voyager-*` slugs.** Mechanical
   slug-list extension to `scripts/audit_harness.cr` + tests.

5. **Voyager baselines.** The web build emits per-screen HTML
   (`voyager-{sign-in,todos,todo-editor,settings}-{light,dark}.html`)
   ready for screenshot capture by the existing baseline pipeline.
   Capture + commit to `docs/initiative-cross-platform-ui/baselines/web/`
   is mechanical.

## Verification

```bash
# Spec — full suite
crystal spec
# 1490 examples / 4 failures / 0 errors

# Spec — Voyager litmus
crystal spec spec/ui/voyager_state_propagation_spec.cr
# 5 examples / 0 failures

# Web build
crystal run samples/initiative-cross-platform-ui-voyager/web/static_site.cr
# wrote 11 files under output/voyager-demo/

# Open the navigable app
open output/voyager-demo/voyager-light.html
# Click Sign in → Settings → toggle Hide completed → back to Todos
# Confirm the 2 completed todos disappear + chart counts move from 3/2 to 3/0
```

## Files added/changed

```
src/ui/navigation_coordinator.cr           (new, 100 lines)
src/ui/views/swipe_action_row.cr           (new, 80 lines)
src/ui/platform_visitor.cr                 (+5 lines for SwipeActionRow visit)
src/ui/renderers/web_renderer.cr           (+250 lines: render_route_host + visit SwipeActionRow + chrome)
src/ui/renderers/uikit_renderer.cr         (+40 lines: visit SwipeActionRow)
src/ui/renderers/appkit_renderer.cr        (+30 lines: visit SwipeActionRow)
src/ui/renderers/android_renderer.cr       (+5 lines: visit SwipeActionRow stub)
src/ui.cr                                  (+1 require)
spec/ui/navigation_coordinator_spec.cr     (new, 130 lines, 15 examples)
spec/ui/web_renderer_route_host_spec.cr    (new, 70 lines, 7 examples)
spec/ui/swipe_action_row_spec.cr           (new, 100 lines, 8 examples)
spec/ui/voyager_state_propagation_spec.cr  (new, 100 lines, 5 examples)
spec/ui/views_spec.cr                      (+5 lines: TestVisitor SwipeActionRow stub)
samples/initiative-cross-platform-ui-voyager/
  app.cr / brand.cr / Makefile / screens/*.cr / web/static_site.cr  (new, ~700 lines total)
```

## Risk + carry-over

- Native targets shipping the same litmus requires the deferred macOS +
  iOS host files. The contract they need is already proven (coord.on_change
  fires → host calls build_route → fresh tree with new state).
- The Codex final verdict was PROGRESS, not PASS. The brief calls for
  "verify on EACH platform before reporting done"; we've verified web +
  Crystal contract, but iOS Sim + macOS bin verification require the
  deferred host files.
- No regressions introduced. All 4 prior-failing baseline tests still
  fail in exactly the same way; the new 35 tests all pass.

— Implementer
