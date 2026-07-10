# Phase 1 — Architect Reflection — 2026-05-20

## What landed

Phase 1 delivered the unified `UI::DesignTokens` source of truth (colors / spacing / type / radius / shadow / motion / breakpoints / touch-target / Android-equivalent data), two deterministic generators (web `--ap-*` CSS custom properties, Apple `AssetPipelineTokens.swift`), the immutable `Brand` interface that Phases 3/5/6 will inherit verbatim, full Ottosson OKLCH↔sRGB conversion with CIEDE2000 for the visual-grade canonical-palette bar, and complete migration of the web, AppKit, and UIKit renderers' visit-method literals through the token shim (or `# Tier 2` annotation). The Android generator and Android renderer literal-scrub are deferred to a follow-up phase per the scope decision; the model still carries Android-equivalent data so the deferral is cost-free.

Done in 11 Implementer commits (8 original + 3 remediation), one Validator iteration that returned FAIL on the partial renderer scrub the Implementer self-disclosed, and one remediation loop that returned PASS at iteration 2.

## What surprised me

1. **The Implementer self-flagged the partial renderer scrub.** The original Implementer disclosed in their handoff that AppKit + UIKit visit-method literals remained unscrubbed — exactly the failure mode the rubric exists to catch. The remediation loop produced a clean fix in one iteration. This is the trust-pair protocol working as designed: honest disclosure → independent verification → targeted fix.

2. **macOS `NSButton.bezelColor` composites the brand color over the system bezel.** The remediation Validator's #19 disclosure — that the rendered pixel is ~67 sRGB units from the raw sentinel because AppKit's native button compositing softens the brand color — is a meaningful piece of intelligence for Phase 3 (SwiftUI bridge). When SwiftUI `Button` is used in place of raw `NSButton`, the bezel composition may differ. The Phase 3 Implementer should expect to validate brand-primary visibility against rendered output, not against literal RGB values. The Validator's pivot-proof (magenta→green at the same pixel coordinate) is the right shape of test for any future Apple cascade check.

3. **`crystal-alpha` is not actually installed on this validation host.** Both the Implementer and Validator silently fell back to stock `crystal` 1.20.0. The `--no-codegen` checks and `crystal spec` invocations all worked, so no functional gap, but this is worth a project-level decision: the project conventionally uses `crystal-alpha` per CLAUDE.md, but the validation host doesn't have it. Either install it on the host going forward, or formalize that stock `crystal` is the validation-host fallback. Surface to Seth.

4. **The pre-existing `crystal spec` link gap (undefined `nsmutablearray_*` from `src/ui/native/objc_collections.cr`) is now blocking every future Validator from running the full suite cleanly.** The Validator works around it by invoking the 4–5 Phase 1 spec files directly, but this fallback has limits — when later phases add their own spec files, the same workaround will be needed each time, and at some point the link gap should be repaired (probably in a Phase 2 or Phase 3 commit). Not Phase 1's responsibility, but worth tracking.

## Whether downstream phases are still aligned

I re-read Phase 2's `README.md` and `implementation.md` start sections. Phase 2 reads `tokens.touch_target_minimum_px` and `tokens.breakpoints` — both ship on `Tokens.default` as documented. Phase 2 reads `--ap-*` CSS custom properties — all required variables are emitted in `dist/web_tokens.css`. Phase 2 calls existing `scripts/capture_web_demo_screenshots.cr` and the axe/IBM audit scripts — those are committed on the basis state. Phase 2's existing-infrastructure-to-use checklist still applies cleanly.

One downstream consideration to track: Phase 6 will inherit the `UI::Brand` interface shape the Implementer documented in their handoff. The handoff shape matches what Phase 6's implementation.md §573 expects (`UI::Brand` subclass + `override_*` methods returning new records via `copy_with`, no DSL). ✓

Phase 3 will inherit the `LibSwiftKitBridge` typed wrapper that Phase 3 itself ships in `src/ui/native/lib_swiftkit_bridge.cr`. Phase 5 references that surface. Both still match the original Phase 3 brief.

Phase 4's compile-error specs use the tempfile pattern, not stdin — confirmed in Phase 4 implementation.md §1080. ✓

No downstream phase needs amendment based on what Phase 1 delivered.

## Changes to the spirit Seth should know about

- **Phase 1's canonical-palette tolerance was tightened from implementation-grade to visual-grade (ΔE2000 ≤ 1.0)** per the architect-tolerance call at checkpoint 1. The Validator measured ΔE2000 = 0.000 on all five comparison points, so the bar was easy to meet — but it's now formally tighter for any future palette refresh.
- **`UI::Brand` is now the canon for brand overrides** across the initiative. The shape is documented in the Implementer's handoff and frozen.
- **5 new `RadiusScale` role-based steps shipped during remediation** (`xs`, `card`, `sheet`, `avatar`, `avatar_lg`). These were not in the original Phase 1 brief — the Implementer added them to absorb the UIKit setCornerRadius literals semantically rather than t-shirt-sizing them. Brand override path works against these new steps; existing specs still pass. A documentation update in the apple-platform-guide skill might be worth a Phase 6 nice-to-have.
- **`amber_brand_gold` survives as a thin shim** routing through `token_nscolor(:brand_primary)` rather than being deleted, per the Implementer's Deviation #3 in iter-1 (kept because dozens of call sites depend on the name and the behavior — not the symbol — is what matters). Architect accepted this in the failing-1 adjudication.
- **iOS cascade harness was deliberately not shipped this phase.** macOS cascade satisfies the DoD's one-Apple-target requirement. If the cross-platform proof ever needs both Apple targets validated, the iOS harness is a follow-up to schedule.
- **The Validator's pass-with-disclosure on #19 is recorded** — future Phase 3/4/5 cascade checks against AppKit/UIKit rendered widgets should use the pivot-proof shape (color flip at fixed coordinate) rather than expecting raw-RGB ΔE distance.

## Next move

Checkpoint with Seth before creating the Phase 2 branch. Phase 2 dispatch materials are already pre-staged at `handoff/phase-02-dispatch-templates-draft.md` with two substitution points:

1. `{phase-01-implementer-commit-hashes}` — fill with: `5b6483b 40e396d 0e3b943 575613a 8ecd37d 006dc70 3874a4e 8b68717 a84c6c3 4cefe9f 0988646` (all 11)
2. `{phase-01-brand-interface-shape}` — fill with the `UI::Brand` shape from the Implementer's iter-1 handoff: abstract class with `override_color_light/dark` / `override_spacing` / `override_type` / `override_radius` / `override_shadow` / `override_motion` / `override_breakpoints` / `override_touch_target_minimum_px`; consumer-side `Tokens.default.with_brand(BrandSubclass.new)`; left-to-right composition.

After Seth's go-ahead, I'll cut `phase-02-responsive-web-fluid-resize` off the merged head and dispatch the Implementer.
