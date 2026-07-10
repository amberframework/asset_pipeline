# Phase 8 — Collective Review Handoff

**Date:** 2026-05-25
**Arc:** 8A → 8B → 8C → 8D.1 → 8D.2 → 8D.3a → 8D.3b → 8E
**Status:** All sub-phases CLOSED; final feature set ready for owner review.
**Branch:** `feature/utility-first-css-asset-pipeline`
**Final HEAD:** `ff130ab3`
**Tags:** `phase-08a-pass-2026-05-24` → `phase-08e-pass-2026-05-25`

---

## What this is

Per owner directive `[[complete-phase-arc-before-review]]`: instead of stopping at each sub-phase for hand-tests, we ran the full Phase 8 arc on automated proof (Crystal specs + cross-platform builds + XCUITest cold-launch smokes + Codex per-iteration reviews) and surface the consolidated feature set here for one collective review.

This document is the entry point for that review. Each section names what shipped, where to look, and what's worth touching.

## The feature set in one paragraph

Phase 8 shipped an ergonomic MVC-style API for cross-platform Apple-native + Amber-web apps. A `UI::App` subclass declares routes via `screen` macros; `UI::Screen` subclasses author `build(ctx)` view trees; `UI::Controller` subclasses handle native actions and return `UI::ActionResult` (Navigate / Pop / Rerender / ReplaceRoot / RenderInline); `UI::ActionDispatcher` translates results into coordinator + FormState mutations with mount-before-publish discipline; `UI::FormState` carries controlled input values across renders with mount-token-keyed stale-fire guards; `UI::AmberIntegration.routes_for(YourApp)` wires the same `UI::App` declaration into an Amber server. The canonical demo (Voyager) ships on macOS native + iOS native; an Amber spike proves the web full-server path; a static-site web target remains (the `Voyager.build_route` helper) as the deliberate non-dispatcher path.

## Things to touch in the review

### 1. The canonical demo — Voyager on the simulator

The 8-step hand-test recipe (deferred from 8D.1, 8D.2, 8D.3a) is the highest-value interactive check. App is pre-built; recipe + commands are in **`docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/brief-8d.3a.md` §4 + §4.1**.

`.app` artifact: `~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app` (build clean across 8D.2 + 8D.3a; if stale, rebuild via `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild ... build`).

The 8 steps in summary:
1. Sign-in renders. 2. Sign-in → Todos. 3. Add Todo → Cancel returns. 4. Swipe row → Edit → modify title → Save returns with update. 5. Checkbox toggles strikethrough. 6. Swipe → Delete removes row. 7. Settings → Hide-completed → back filters Todos. 8. **Editor with empty title: typing enables Save; backspace disables it** (the 8D.3a Save-on-type fix).

### 2. The visual capture matrix — 56 PNGs

**`docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/`** has 28 iOS captures + 28 macOS captures (14 contract rows × light + dark on each platform). README maps each PNG to its scenario.

Worth browsing for visual consistency, dark-mode legibility, AppKit-vs-UIKit rendering parity, and where iOS row-07 falls short (gesture-only state is captured at-rest — known limitation, documented).

### 3. The Amber spike — full-server web

**`samples/phase-08-amber-spike/`** is a minimal Amber app proving `UI::AmberIntegration.routes_for`. It's not a Voyager port; it's a sign-in demo that exercises form POST → controller dispatch → flash → rerender.

Verify by reading `samples/phase-08-amber-spike/config/routes.cr` (one line: `routes :web do UI::AmberIntegration.routes_for(SpikeApp) end`) and `samples/phase-08-amber-spike/src/spike_app.cr`.

### 4. The new public APIs

In `src/asset_pipeline/`:
- `native_app.cr` — `UI::App` + `ScreenRegistration` + the `screen` macro.
- `native_controller.cr` — `UI::Controller` + `dispatch_action`.
- `action_dispatcher.cr` — `UI::ActionDispatcher` (the mount-before-publish heart).
- `action_result.cr` — `UI::ActionResult` sealed subtypes.
- `native_context.cr` — `UI::ScreenContext::Native` + `::Web`.
- `amber_integration.cr` — `UI::AmberIntegration.routes_for` + `UI::ScreenHelpers`.

In `src/ui/`:
- `form_state.cr` — `UI::FormState` + `UI::FormStateRendererHook.wrap_text_handler`.
- `views/screen.cr` — `UI::Screen` base class with `build(ctx)`.

### 5. The docs

- **Skill:** `.claude/skills/ui-app/SKILL.md` — operational reference. 12 sections; should be the first thing a new agent reads when building on this API.
- **Tutorial:** `docs/initiative-cross-platform-ui/tutorial-ui-app.md` — 13-chapter narrative with the canonical TasksApp + Voyager lifts.
- **Position note:** `docs/initiative-cross-platform-ui/architecture/web-target-position.md` — the "Voyager web is static-site by design; Amber is a separate proof path" stance.
- **CLAUDE.md:** new "UI::App application architecture" subsection + 8 Key Entry Points additions + Quick Reference row.

### 6. The five canonical architectural rules

Stated identically in skill + tutorial (per 8E Codex iter 2 finding):

1. **App/domain state mutations go through the target's controller layer** — `UI::Controller` + `UI::ActionDispatcher` on native; the Amber controller's request cycle on Amber full-server web; build-time only for static-site. Never in screen `build` methods.
2. **View-local affordances may use closures.** (e.g. `save.disabled = title.empty?` on `title_field.on_change` — not a dispatcher Rerender, which would allocate fresh FormState.)
3. **Mount before publish/render.** Dispatcher's `mount_screen` ALWAYS precedes the coord op (`push` / `pop` / `replace_root` / `republish`) that fires the on_change subscriber.
4. **Renderer/provider install before screen build.** `UI::UIKit::Renderer.new` installs `DesignTokens::Device.install_provider`; screens query `DeviceMetrics.current` during `build`. Construct-after-build SIGSEGVs on iOS fresh-renderer paths.
5. **Capture evidence ≠ interaction evidence.** Screenshots prove visual state at known scenarios; dispatcher specs + hand-tests prove action behavior. Asking screenshots to prove "the tap worked" runs into Phase 6.10's XCUITest tap-synthesis wall.

These rules emerged from real iteration loops (cited in each sub-phase's reflection); they're the most concentrated lessons from the arc.

## Numbers across the arc

- Spec growth: 1529 (pre-Phase 8) → **1723** (+194 examples across 8A + 8B + 8C + 8D.1 + 8D.2 + 8D.3a). Same 4 pre-existing failures untouched.
- Captures: 56 PNGs (14 rows × 2 appearances × 2 platforms).
- Codex passes: ~30 per-iteration reviews (architect-antagonist + implementer-side) across the arc.
- Brief revisions: 8A through 8E each had 1-3 Codex critique rounds before dispatch.
- Sub-phase tags: 8 total (8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, 8D.3b, 8E).

## Per-sub-phase reflections (cross-reference)

- `phase-08a-reflection-2026-05-24.md` — Amber integration substrate, parallel-controllers architecture, browser POST closing-gate.
- 8B (in master plan) — `UI::ActionDispatcher` + `UI::FormState` substrate; mount-before-publish invariant; Phase 8B spike at `samples/phase-08b-native-spike/`.
- 8C (in master plan) — `routes_for(UI::App)` macro + twin-emission pattern proven via Codex empirical work.
- `phase-08d.1-reflection-2026-05-25.md` — Voyager macOS migration; byte-identical-screenshot closing gate.
- `phase-08d.2-reflection-2026-05-25.md` — iOS bridge migration; `HostBootstrap.build` helper; renderer-provider install ordering memory.
- `phase-08d.3a-reflection-2026-05-25.md` — Save-on-type fix; view-local-affordance-vs-app/domain-state reframing; web-target-position note.
- (8D.3b + 8E close with the commits themselves; no separate reflection — captures + docs land cleanly.)

## What was hard

- **Mount-before-publish was load-bearing and counter-intuitive.** Renderer wire-time reads FormState.current during the on_change subscriber that fires synchronously inside the coord op; you have to mount first OR the renderer sees the stale FormState. Phase 8B Codex iter 4 caught this; the invariant survived every subsequent phase.
- **Web is three things.** Amber full-server (dispatcher-equivalent), Voyager static-site (no dispatcher, build-time HTML), and the framework's `UI::Web::Renderer` (used by both). Confusing these costs hours; the position note + the explicit rule rewording in 8E exists because Codex caught the conflation.
- **iOS class-init gap is real.** Class-var initializers don't fire when `_main` is hidden behind Swift `@main`. Every iOS-side class-var with side effects must be allocated explicitly in `initialize_runtime`. `Thread.init` / `Fiber.init` / `Crystal::Once.init` must precede any `Crystal::once`-guarded constant access. Verified by SIGSEGV traces preserved in `~/Library/Logs/DiagnosticReports/`.
- **XCUITest tap synthesis doesn't reach Crystal-rendered button on_tap closures.** Phase 6.10 limitation; survived all of Phase 8. Hand-test is the real interaction proof.
- **Codex CLI flakiness.** Three patterns worked reliably: medium reasoning, arg-form prompt, tee + tail. `gpt-5-codex` model unavailable on this account; default works. Codex iter 3 of 8E stalled on stdin (the implementer invoked `codex exec` without piping the prompt); architect resolved the iter 2 REVISE finding directly.

## Open follow-ups (not blocking review)

- `Voyager.build_route` — permanent static-site entry point per D1 disposition; could be renamed for clarity in a future polish phase (not 8E scope).
- macOS host could migrate to `Voyager::HostBootstrap.build` for parity with iOS; pure cleanup.
- `UI::FormState.register` has a comment claiming it updates existing keys; code says seed-only. Doc trap; cleanup ticket.
- Row 7 iOS swipe-revealed visual: no static representation in `UI::SwipeActionRow`; would require a sample-only renderer hint or framework API extension. Out of scope.
- `apple-platform-guide` skill predates Phase 8; could link to `ui-app` from its overview. Optional.

## How to review

Suggested order, for maximum signal in minimum time:

1. **Skim `tutorial-ui-app.md`** (15 min) — gets the architecture in your head.
2. **Open the iOS simulator + run the 8-step hand-test** (20 min) — finds integration bugs no audit catches.
3. **Browse the 56 PNGs** in `phase-08d.3b-evidence/` (5 min) — visual coherence + dark-mode polish.
4. **Spot-check the new APIs** (10 min) — `action_dispatcher.cr` translate_result is the spine; `native_app.cr` screen macro is the surface.
5. **Read this file's "What was hard" section** (3 min) — calibrates what to push back on.

Feedback to me as architect; I'll dispatch remediation per finding.

— Architect (Claude Opus 4.7)
