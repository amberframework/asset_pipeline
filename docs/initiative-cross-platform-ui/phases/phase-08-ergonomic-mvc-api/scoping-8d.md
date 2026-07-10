# Phase 8D — Voyager Migration to Unified UI::App Architecture (SCOPING DRAFT)

**Date opened:** 2026-05-24
**Status:** SCOPING — architect + Codex co-planning. Brief authoring follows.
**Branch:** to be cut as `phase-08d-voyager-migration` after planning lands.

---

## The problem being solved

Phase 8A/8B/8C shipped the unified architecture. Phase 8D is the visible payoff: prove the architecture by migrating Voyager — the canonical demo app — to use it across all three real targets (web, macOS, iOS).

Today's Voyager has a working `coord.push(Route.new(:todos))` pattern threaded directly through screen `build` methods. There is no `UI::App`, no `UI::Controller`, no `UI::ActionDispatcher`, no `UI::FormState`. The web target generates static HTML files via `samples/initiative-cross-platform-ui-voyager/web/static_site.cr` and does NOT run on Amber. The native targets (iOS bridge.cr + macOS host.cr) drive navigation via direct coord mutation, not via the new dispatcher.

**Two layered problems:**

1. **Native architecture migration** — refactor Voyager's screens + native hosts to use UI::App + UI::Controller + UI::ActionDispatcher + UI::FormState. This closes the deferred items from Phase 8B (iOS bridge to UI::ActionDispatcher; interactive-typing click-trace; SecureField bridge limitation).

2. **Web target architecture migration** — Voyager web is currently a static-HTML build, NOT an Amber server. Phase 8C's `routes_for(UI::App)` macro only matters when there's an Amber server consuming it. To make the unified-UI::App-declaration architecture meaningful on Voyager web, the web target must be rebuilt as an Amber app, OR the architecture has to accommodate a "static-site-only" web target as a first-class option.

3. **Closing evidence gates** — the 14-row Voyager behavior contract (28 captures: 14 actions × light/dark on iOS, plus macOS equivalents) has been deferred since Phase 6.11. Phase 8D's natural closing gate.

## Why this matters as one phase

Splitting native and web into separate phases means we can't prove the "one declaration drives all targets" architectural claim on a real app. Voyager is the demo where the claim has to land or it doesn't land at all. The native + web migrations are interdependent in a way the spike work was not — `class VoyagerApp < UI::App` declared in `app.cr` should drive ALL three target builds in `macos/`, `ios/`, and `web/`.

That said, the scope is large. Phase 8D should plan for **sub-phasing** (8D-1, 8D-2, 8D-3, ...) the same way Phase 6.12 did. Codex partner: help me figure out the right sub-phase boundaries.

## Scope candidates (open for Codex critique + structuring)

These are candidate scope items. I expect Codex to challenge structure, merge or split items, identify missing items, propose sub-phase boundaries, and flag risks.

### A. Native Voyager — `class VoyagerApp < UI::App`

- Define `VoyagerApp < UI::App` with `initial_route :sign_in` + `screen :sign_in, :todos, :todo_editor, :settings`.
- Define `SignInController, TodosController, TodoEditorController, SettingsController` — each `< UI::Controller` with explicit `dispatch_action` override.
- Existing screens (`screens/sign_in.cr`, etc.) become `UI::Screen` subclasses with `build(context : UI::ScreenContext)`.
- Existing `Voyager::State` global module becomes either part of a controller's instance state (per-mount) or stays as a module singleton for the demo (since Voyager has no persistence).
- The macOS host (`macos/host.cr`) creates a `UI::ActionDispatcher`, wires it to the coordinator, calls `VoyagerApp.bootstrap!`, mounts the initial screen via the dispatcher.
- The iOS bridge (`ios/bridge.cr`) does the same; this closes the deferred Phase 8B iOS-side dispatcher wiring.

**Risk:** Voyager's screen build methods access state via `Voyager::State` singleton + take `coord` as an argument. Refactor must preserve the state-propagation litmus (Settings toggle → Todos rerenders on back). New `UI::ScreenContext` carries flash/session/params but NOT app state. Resolution: probably keep `Voyager::State` as a module-level singleton; controllers reach into it.

### B. Web Voyager — Amber-server rebuild OR static-site preservation

Two paths; Codex critique should pick:

**B1 — Migrate Voyager web to Amber.**
- Build a minimal Amber app at `samples/initiative-cross-platform-ui-voyager/web/`.
- Controllers: `SignInController`, `TodosController`, `TodoEditorController`, `SettingsController` extend `Amber::Controller::Base`, include `UI::ScreenHelpers`, render each route's screen via `compute_screen_html`.
- `config/routes.cr` uses `UI::AmberIntegration.routes_for(VoyagerApp)`.
- Replaces the static-site build (`static_site.cr`) entirely.
- Closing gate: Selenium browser POST proof against the Amber-served Voyager.

**B2 — Keep web as static-site; document the architecture limit.**
- The Phase 8 architecture is: "unified UI::App declaration drives Amber web + native." Static-site web is OUT OF SCOPE for the unified-declaration claim.
- Voyager web stays static. Doc the architecture as "Amber web + native via UI::App; static-site is a separate path."
- Closing gate: less ambitious. Just verify Voyager native targets work with the new API.

**Architect lean:** B1. The architectural claim "one declaration drives all three targets" is materially weaker if static-site is excluded. But B1 is significantly more work. Codex partner: pressure-test this.

### C. iOS-specific deferred items

- **Interactive-typing click-trace.** Phase 8B spike used `PHASE8B_AUTOFILL_EMAIL` env var to bypass the keyboard. Phase 8D Voyager hand-test must verify real keyboard events flow into FormState → controller action.
- **SecureField bridge limitation.** SwiftKit's `apsk_secure_field_*` bridge emits `""` on change instead of the real value. Either fix this on the SwiftKit side, or document as known limitation with workaround.
- **iOS legibility recapture.** Phase 6.11/6.12 deferred 4-of-8 iOS legibility captures + the macOS resize captures. Phase 8D should close this since Voyager is being touched anyway.

### D. 14-row behavior contract — the closing-gate visible payoff

The 14-row contract (defined in Phase 6.11 brief, deferred through 6.12 + 8B) is the user-visible proof that the system works:

1. Just-launched Sign-in
2. After Sign in (email + password typed + tapped)
3. Editor empty
4. Editor with title typed
5. After Save (new row visible)
6. Row completed (strikethrough)
7. Swipe revealed
8. Editor prefilled (from swipe-Edit)
9. After Edit Save
10. After Delete
11. Settings default
12. Settings hide-completed toggled
13. Todos filtered (back from Settings)
14. Todos unfiltered (re-toggle + back)

Light + dark = 28 captures on iOS. macOS equivalent (where applicable) = additional captures.

### E. Documentation surface (probably Phase 8E, not 8D)

Phase 8E was scoped earlier for docs + skill + tutorial. Codex partner: should ANY docs land in 8D, or all in 8E? Probably defer to 8E.

## Sub-phase candidates (Codex partner: structure this)

Initial guess:

- **8D-1** — Native Voyager refactor (Items A + parts of C). Closing gate: macOS Voyager binary launches + 14-row hand-test rows 1-14 work in iteration mode (not screenshotted yet).
- **8D-2** — Web Voyager Amber rebuild (Item B1). Closing gate: Selenium browser proof against Amber-served Voyager.
- **8D-3** — Evidence captures (Item D + remaining of C). Closing gate: 14-row × 2 appearances captured on iOS + macOS equivalents.

OR:

- **8D-1** — Native macOS (lowest risk, fastest payoff)
- **8D-2** — Native iOS (closes Phase 8B deferred iOS work)
- **8D-3** — Web Amber rebuild
- **8D-4** — 14-row captures

Codex partner: which split better matches the risk profile + visible-payoff cadence?

## Open architectural questions for Codex partner

1. **State management.** Voyager's `Voyager::State` is a module-level singleton with mutable arrays. Should it stay as a singleton (current pattern, works for demos), become part of `UI::App` (new pattern, ergonomic for consumers), or become per-controller (Rails-ergonomic, but Voyager has no persistence layer)? What's the minimal change?

2. **NavigationCoordinator + ActionDispatcher relationship.** Voyager uses `coord.push(Route.new(...))` directly in screen build methods. Phase 8B's ActionDispatcher wraps coord + dispatches actions; controllers return `UI::ActionResult::Navigate(:route_id)` instead of calling coord directly. How does Voyager's current pattern translate cleanly? Do screen-internal callbacks (e.g. `Toggle on_change`) need to go through ActionDispatcher, or can they stay as direct callbacks?

3. **Web target — when is Amber overkill?** The Voyager web target is a 4-page demo. Amber adds substantial dependency weight (sessions, CSRF, pipelines, etc.) for relatively little UI complexity. Is there a middle path — e.g. a "minimal Amber app" template that strips unnecessary pipes — or does the Phase 8C-proven routes_for path only make sense in full-Amber form?

4. **Voyager web's existing client-side state JS.** Voyager web today uses client-side JS to handle the Settings "Hide completed" toggle (so the static-site build can be reactive without Amber). If migrating to Amber, the toggle becomes a POST → session update → page rerender. Is that the right trade-off, or should the JS-driven reactive flow stay?

5. **Test+CI coverage.** Phase 8D ships a new Voyager. Should there be unit specs for the controller dispatch chain (like Phase 8B's `action_dispatcher_spec.cr`) PLUS the integration captures, or are the integration captures sufficient?

6. **iOS class-init gap discipline.** Voyager's iOS bridge.cr was carefully crafted to avoid the gap (per `[[project_crystal_ios_class_init_gap]]`). The migration to `UI::App.bootstrap!` needs to preserve this. Phase 8B's `_bootstrap_screen_*` macro pattern handles UI::App's own state, but `UI::ActionDispatcher`'s class-vars (if any) also need to survive the gap. Codex: check whether `UI::ActionDispatcher`'s current implementation has any class-var defaults that could strand.

## Risk register (initial; Codex partner expands)

- **R1 — Voyager macOS spike already exists** as `samples/phase-08b-native-spike/` (Phase 8B). Phase 8D Voyager is NOT a parallel spike; it's the production demo. Don't conflate.
- **R2 — Existing Voyager hand-tested behavior.** The current Voyager native + web targets work. Migrating must not break observable behavior — same 5 seed todos, same Sign-in flow, same Settings filter, same swipe actions. Codex partner: should there be a "before-migration snapshot" of expected behavior committed first?
- **R3 — Codex CLI flakiness.** Codex's exec output has been intermittent this session. Phase 8D needs strict per-iteration Codex review. Mitigate by: shorter prompts, explicit response-format demands, dispatch with output-last-message file flag, fall back to log-grep if file is empty.
- **R4 — Mid-stop pattern.** Every prior Implementer agent has stopped at evidence-capture time. Phase 8D's 14-row contract is the highest-risk evidence-capture in the initiative. Split dispatch (code-work agent + separate capture agent) is the right pattern per `[[mid-stop-pattern-evidence-capture]]`.

## What Codex should bring back

1. **Sub-phase structure** — 2-4 sub-phases with clear boundaries.
2. **Item B resolution** — B1 (Amber rebuild) or B2 (static-site stays)?
3. **Closing-gate proposal per sub-phase.**
4. **Risk additions** — what's missing from R1-R4?
5. **Spec strategy** — unit specs for the new Voyager controllers, yes/no?
6. **State-management answer** to question 1.
7. **Anything I'm not seeing.**

## Hard rules (in advance — preserved into the brief)

- Forward commits only on phase-08d-* branches.
- NO Phase 8A/8B/8C API changes. Phase 8D is APPLYING the API to Voyager; if a gap surfaces (e.g. ActionResult doesn't support something Voyager needs), STOP and escalate to architect for a Phase 8C+ patch — do NOT improvise.
- NO regression in existing Voyager behavior. Pre-migration captures or behavior recordings should be baseline.
- Codex per-iteration review. No self-assessment.
- Standard Claude co-author footer.

---

**Next steps:**

1. Send this to Codex as a co-planning partner.
2. Iterate.
3. Convert refined plan → brief-8d.md (or per-sub-phase briefs).
4. Codex critique on the brief(s) before dispatch.
5. Dispatch Implementer.

— Architect (Claude Opus 4.7)
