# Phase 6.10 — Navigable CRUD Demo + Navigation Coordinator

**Inserted:** 2026-05-23, after Phase 7 PASS_WITH_NOTES.
**Dependencies:** Phase 7 PASS (tag `phase-07-pass-2026-05-23`); reuses widgets shipped in Phases 1-6.9.
**Blocks:** Initiative final sign-off (this phase closes the "actually navigable" gap the owner surfaced post-Phase-7).

## Why this phase exists

Phase 7 closed the initiative's CI gate, but a post-Phase-7 architect-owner review surfaced a substantive gap: **the Cascade demo passed the brand-litmus visual capture test but is a 5-screen catalog, not a navigable app.** The owner explicitly named this:

> "page navigation is something that we've had to reincorporate into an application every single time. It's just for whatever reason the navigation doesn't seem to be considered a part of screen building."

Codex analysis traced this to a real architectural gap: `UI::NavigationStack#push` / `#pop` mutate a Crystal `Array(View)` but do NOT trigger any reactive re-render, native controller call, or browser history update. The library has the *vocabulary* of navigation but not the *runtime*.

Phase 6.10 closes the gap by:

1. Shipping a **second demo app (Voyager)** that's a working navigable Todos CRUD — not a screenshot catalog. The owner can launch it on iOS Sim + macOS + web and actually navigate it.
2. Shipping the **3 minimum library primitives** that working navigation needs: `UI::NavigationCoordinator` (reactive nav state), a route-host re-render hook in renderers, and `UI::SwipeActionRow` (iOS Mail-style swipe-to-reveal-actions widget).

## Scope

In scope:

- **Voyager demo app** at `samples/initiative-cross-platform-ui-voyager/` with 4 screens:
  1. **Sign In** — email TextField with basic regex format validation, SecureField for password, Sign in button advances to Todos.
  2. **Todos** — list of items (ListView + SwipeActionRow), Add button, ChartView showing open vs completed counts, Settings link.
  3. **Todo Editor** — title TextField, note TextField, completed Toggle. Save mutates shared state + pops back. Back without save = no change.
  4. **Settings** — single "Hide completed" Toggle. State-propagation litmus: toggle → back → Todos + chart immediately reflect.

- **`UI::NavigationCoordinator`** (new): reactive app-level navigation state. Owns `routes : Array(Route)`. Methods: `push(route)`, `pop`, `replace_root(route)`, `pop_to_root`, `on_change(&block)`. When `push` / `pop` mutate the routes, registered `on_change` callbacks fire — renderers subscribe to swap the visible root.

- **Route host re-render hook**: renderers wire `NavigationCoordinator#on_change` to a callback that rebuilds the root view from the new route and replaces the platform's content view. iOS/macOS: replace the SwiftUI hosting controller's content. Web: full-page DOM swap + `history.pushState` / `popstate` listener.

- **`UI::SwipeActionRow`** (new widget): a list row with `leading_actions : Array(SwipeAction)` and `trailing_actions : Array(SwipeAction)`. On iOS/UIKit: native SwiftUI `.swipeActions(edge: .trailing)` modifier. On macOS/AppKit: visible trailing buttons (HIG-conformant — macOS doesn't have swipe gesture in the same way). On web: CSS-only swipe interaction OR visible trailing buttons for desktop + touch-swipe for mobile viewports.

- **Voyager build configs**: `make web` (static HTML with hash-route navigation), `make macos` (.app with NavigationCoordinator-driven re-render), `make ios` (iOS sim .app with the same coordinator wiring).

- **Voyager baselines + harness routing**: per-screen baselines committed at `docs/initiative-cross-platform-ui/baselines/{platform}/voyager-{screen}-{appearance}.png`. The audit harness recognizes Voyager slugs (`voyager-sign-in`, `voyager-todos`, `voyager-todo-editor`, `voyager-settings`).

Out of scope:

- **URL routing / deep links** — coordinator uses route IDs, not URL paths. URL routing is a future phase if needed.
- **Edge-swipe back sync on iOS** — native iOS edge swipe to pop is nice-to-have; if SwiftUI's `NavigationStack(path:)` binding gives it for free we keep it, but we don't ship `APSKNavigationState` SwiftKit bridge in this phase. Approach (a) full root re-render on coordinator change (per Codex recommendation) is the choice.
- **Multi-action native action sheets** — current iOS action sheet maps only first non-cancel + cancel ([uikit_renderer.cr:3682](../../../src/ui/renderers/uikit_renderer.cr)). Voyager puts Edit/Delete on the swipe action row, NOT inside a sheet. Multi-action sheet facade is a separate future phase.
- **Cascade demo modifications** — Cascade stays as it is (screenshot catalog). Voyager is its own demo.

## Acceptance

The owner can:

1. Launch the iOS app in the simulator (`make -C samples/initiative-cross-platform-ui-voyager ios run`), see the Sign In screen, type an invalid email and see validation feedback, type a valid email + any password, tap "Sign in", and advance to the Todos screen.
2. On the Todos screen: see a list of 5+ items with checkmarks for completed ones, see a chart showing the count of open vs completed, swipe a row left (on iPhone touch) to reveal Edit/Delete, tap Edit to open the Todo Editor screen.
3. In the Todo Editor: change the title, toggle Completed, tap Save, see the Todo list update + chart update, and the back button + state both correct.
4. Navigate Todos → Settings, toggle "Hide completed", tap back, see the Todos list filtered (completed items hidden) and the chart updated.
5. Repeat the experience on macOS (`make -C samples/initiative-cross-platform-ui-voyager macos run`) — same screens, same flow, native macOS chrome (no swipe gesture, visible trailing buttons instead).
6. Repeat the experience on web (`make -C samples/initiative-cross-platform-ui-voyager web && open output/voyager-demo/index.html`) — same screens, same flow, fluid resize between 1280px desktop layout and 375px mobile layout in a single browser window (single-page hash-routed navigation, NOT separate static pages).

Plus:

- `crystal spec` still matches 1455/4/0 baseline.
- `swift build -c release` + 4 build closures (web semantic, macOS host, iOS Crystal-lib, macOS bin/cascade preserved) all exit 0.
- Voyager-specific audit harness probes pass: `bash scripts/audit_harness_smoke.sh I-1 web voyager-todos`, same for iOS + macOS.

## Risk notes

- **State propagation across pops is the litmus test.** If Settings toggle → back → Todos doesn't immediately reflect, the NavigationCoordinator's re-render hook is broken. This is the make-or-break verification — don't ship Phase 6.10 if it fails.
- **Swipe gesture on web** — CSS-only swipe is fiddly; the mobile-web fallback may need touchstart/touchmove/touchend JS. Acceptable to ship desktop-web with visible trailing buttons + mobile-web with touch handler.
- **iOS NavigationStack(path:) compatibility** — the chosen approach (a) full root re-render on coordinator change means we DON'T use SwiftUI's stateful NavigationStack(path:). We hand SwiftUI a new root each time. Acceptable for the demo; durable APSKNavigationState binding is a future phase.

## Briefing documents

- Implementer brief: `brief.yml` (validator-PASS contract)
- Architect reflection: `../../handoff/phase-06.10-reflection-2026-05-23.md` (to be authored on close-out)
- Universal: `../../rubric/implementation_criteria.md`, `../../rubric/validation_criteria.md`
- Schema: `../../schemas/phase_brief.schema.json`
