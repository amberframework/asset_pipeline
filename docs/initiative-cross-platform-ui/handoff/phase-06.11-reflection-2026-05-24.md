# Phase 6.11 — Architect Reflection

**Phase:** 6.11 — iOS Polish + SwiftUI Defaults
**Date closed:** 2026-05-24 (PASS_WITH_NOTES)
**Branch:** `phase-06.11-ios-polish-defaults` (to be merged to feature branch)
**Final HEAD:** `f53487f`
**Tag:** `phase-06.11-pass-with-notes-2026-05-24`

## Verdict

PASS_WITH_NOTES. The phase shipped real framework work but the owner directive "stick with SwiftUI defaults" is only partially met. Library-identity decision (Option C from `phase-06.11-iter-5-architectural-finding.md`) carries into Phase 6.12.

## What shipped

### Iter 1 — Voyager brand override deletion
- `samples/.../voyager/brand.cr` deleted.
- All `VoyagerBrand` / `with_brand` references removed from Voyager screens + app.cr.
- Inline brand color literals removed.
- Codex 1 PASS at commit `496d6ec`.

### Iter 2 — Framework reactivity
- Reactive Button/Label runtime state mutators (Swift + Crystal bridges).
- `NavigationCoordinator#republish` for in-place re-renders (no slug change).
- Renderer wiring for the reactive entry points.
- Voyager screen authoring updates: blank-title Save disabling, swipe-delete republish, toggle-complete republish.
- Codex 2 verdict NEEDS_WORK (no regressions, evidence + audit pending).

### Iter 3 — Swipe row + silent fallback
- `objc_bridge.m` swipe-row height constraint (UIScrollView in stack-arranged context).
- `UI::RenderError` introduced; `visit(UI::SwipeActionRow)` raises loudly on render failure (no more silent empty UIView).
- Codex 3 verdict NEEDS_WORK on the iter-3 close (the audit relied on over-broad "semantic auto-pass" — placeholder text was actually failing WCAG AA at 1.67:1 / 2.23:1).

### Iter 4 — ButtonFacade + placeholder contrast
- Phase 6.8 brand-teal hardcode in `ButtonFacade.swift case "prominent":` removed; prominent buttons now use `.controlSize(.large).buttonStyle(.borderedProminent)` (Path A from Phase 6.10 made the workaround obsolete).
- Stretched-prominent recipe (`.frame(maxWidth: .infinity)` on label + outer width pin) preserves form-column width pinning that was the actual reason for the original workaround.
- `PromptOverlayField` wrapper introduced in TextField + SecureField facades; placeholder rendered at `Color.primary.opacity(0.5)` (~4:1 contrast, comfortably above WCAG AA 3:1 floor).
- Codex 4 PASS for the Swift facade slice at commit `ef4b039`.

### Iter 5 — Investigation: dark-mode propagation + Cancel button brand bleed
- Recaptured 8 legibility screenshots with `SIMCTL_CHILD_VOYAGER_APPEARANCE` env var; backgrounds now correctly flip light/dark on iPhone 17 Pro.
- Identified the iOS host's `VoyagerSceneDelegate` reads `VOYAGER_APPEARANCE` env var as source of truth (not system trait collection) — by design for deterministic offscreen capture, but undocumented for hand-test users.
- **Architectural finding:** UIKit renderer (`uikit_renderer.cr:4109-4112`) unconditionally calls `apsk_runtime_set_brand_tint(...)` with `design_tokens.colors_light.brand_primary` on every render. Voyager carries `Tokens.default`, whose `brand_primary` is the library's amber. `HostingHelpers.host` applies `.tint(amber)` to every SwiftUI root → Cancel buttons render amber even with Voyager's consumer-side brand removal.
- Full finding doc at `phase-06.11-iter-5-architectural-finding.md` with 4 options (A: nilable brand_primary, B: per-consumer opt-out, C: system-accent default — owner-selected, D: defer). Owner selected **Option C: `Tokens.default` tracks platform accent.** Carries to Phase 6.12.

## What didn't ship (carrying to Phase 6.12)

- **Library-identity pivot (Option C):** make `Tokens.default.brand_primary` resolve to platform system accent (iOS systemBlue, macOS controlAccentColor, etc.) rather than the library's amber. Cascade demo gets explicit `.with_brand(CascadeBrand)` to preserve its branded look.
- **Audit rewrite with citations + real measurements:** the Phase 6.11 iter-3 `legibility-audit.md` was flagged NEEDS_WORK by Codex 3 for over-broad "semantic auto-pass" claims that fell apart on pixel sampling. A rewrite with code citations + measured ratios was scoped into iter-4 but never completed.
- **Swipe-revealed screenshots:** `voyager-todos-swipe-revealed-{light,dark}.png` were required in iter-3 brief but never captured.
- **28-row functional behavior screenshots:** the brief revision 2 Item 3 contract specified 28 behavior screenshots (14 actions × light + dark). Out of scope for every iteration. Carried to Phase 6.12.
- **macOS polish:** window sizing (width-resizable, sensible default), min height, dark mode behavior, brand cascade implications for macOS. Carried to Phase 6.12.

## Lessons (worth remembering)

### 1. Codex-as-architect-antagonist caught real architect drift

Repeatedly in this phase, Codex critique caught issues my own audits glossed over:
- The Phase 6.11 brief revision 1 was REVISE-THESE-ITEMS (5 findings, all valid).
- Iter-3's `legibility-audit.md` claimed auto-pass on placeholder text that was actually 1.67:1.
- Iter-3's silent-fallback fix was a weak renderer-path test.
- Iter-5's investigation brief was REVISE for grep-set under-breadth — AND while reviewing, Codex discovered the `VoyagerSceneDelegate` env-var path that explained dark-mode non-propagation. That 5-minute critique replaced a multi-hour investigation.

This is exactly the `[[codex-as-architect-antagonist]]` directive paying off. Continuing into Phase 6.12.

### 2. Audit shortcuts are traps without source-code citations

`[[audit-shortcut-trap]]` — the "semantic auto-pass" rule I introduced into the Phase 6.11 brief became a verification gap. Auto-pass was claimed for placeholder text + button labels without verifying the render path. Codex measured the pixels and proved the audit wrong. Going forward, every auto-pass row needs a `file:line` citation that the render path uses the claimed semantic color.

### 3. Brand cascades have multiple layers — strip them with a grep

`[[plan-what-to-understand-not-just-what-to-build]]` — Phase 6.11's Item 1 acceptance was "delete Voyager's brand.cr." That was correct as far as it went but didn't grep the framework for OTHER brand cascade paths. The architectural finding in iter-5 surfaced ones in `ButtonFacade.swift` (now closed), `CallbackBridge.swift` brandTint registry (still live), the UIKit renderer's `ensure_swiftkit_runtime!` brand-tint propagation (still live), and `Tokens.default.brand_primary` itself (the root cause Option C addresses).

A pre-Phase brief authoring step: grep the whole framework for `brand`, `tint`, `accent`, `Color(` literals. Surface all the layers, not just the consumer-side one.

### 4. Mid-stop pattern is structural, not coincidental

`[[mid-stop-pattern-evidence-capture]]` — 4 different agent dispatches in Phase 6.11 alone stopped mid-action at evidence-capture time. The pattern is real: interactive screenshot capture consumes turn budget faster than expected. Going forward, split dispatches: code-work agent + separate capture+audit agent. Already applied in iter-3 close; should apply systemically in Phase 6.12.

### 5. Capture loop bugs masquerade as library bugs

The "dark mode never propagates" finding from iter-4 looked like a deep framework gap. It was a CAPTURE LOOP bug — I was sending `xcrun simctl ui appearance dark` without the env var Voyager's SceneDelegate reads. Investigation-first (per [[plan-what-to-understand-not-just-what-to-build]]) caught it via Codex's code reading. Future audits: when something "isn't propagating," check the diagnostic harness before declaring it a library bug.

## Bookkeeping

- 9 commits on `phase-06.11-ios-polish-defaults`:
  - `496d6ec` Iter 1 — Drop Voyager brand override
  - `e2c002a` Iter 3 — Swipe-row height + UI::RenderError fallback
  - `ef4b039` Iter 4 — Remove brand-teal + fix placeholder contrast
  - `366b3d7` Iter 4 — Recapture screenshots (initial, broken — same #F2F2F7 both modes)
  - `f53487f` Iter 5 — Architectural finding + corrected screenshots
  - Plus 4 commits from iter-2 (reactive Button/Label, NavigationCoordinator#republish, Voyager screen authoring, Codex 2 review)
- 1 tag: `phase-06.11-pass-with-notes-2026-05-24` at `f53487f`.
- Codex review trail: 4 Codex reviews committed + 1 architect-side critique trail.
- Memory updates this phase: `feedback_codex_as_architect_antagonist`, `feedback_mid_stop_pattern`, `feedback_audit_shortcut_trap`.

— Architect (Claude Opus 4.7)
