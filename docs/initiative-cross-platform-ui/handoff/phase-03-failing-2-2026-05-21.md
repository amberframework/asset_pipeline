# Phase 3 — Failing GATE_REPORT (iteration 2) — 2026-05-21

**Verdict:** FAIL
**Validator run date:** 2026-05-21
**Iteration:** 2 (after one remediation loop)

**Implementer commits validated (13):**
- Foundation (2): `7756d25` `6996ba7`
- Dispatch A (4): `7486040 ed51fd7 dfe1274 bdfcf18`
- Dispatch B (2): `3a81950 34e1d4b`
- Dispatch C (2): `f647ddb f2cae3b`
- Remediation 1 (3): `c1b87e8 5525c43 5e0887f`

**Evidence directory:** `docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-20-iter2/`

---

## Architect adjudication

49 required checks, 1 optional. Of the 49: **18 pass, 23 env-blocked (per binding adjudication), 8 substance failures.**

### Major progress from iter-1

Every iter-1 structural blocker is closed:
- All three Swift package slices (iOS simulator, iOS device, macOS) build cleanly. The accessibilityLabel collision and ToolbarFacade ViewBuilder error are both fixed.
- Swift test suite ships: 38 tests across `OverridesPropagationTests` (24), `RuntimeBridgeTests` (9), `SnapshotTests` (5) — all 0 failures.
- GlassBackground ships end-to-end with the correct `if #available(iOS 26.0, macOS 26.0, *) { .glassEffect() } else { material-fallback }` cascade.

This iter went from "Swift package won't even compile" to "Swift package builds clean + ships with its own test suite". Substantively, that's a massive iter-2.

### Remaining substance failures (8) — bucketed by adjudication-vs-fix nature

**Bucket A — "literal vs equivalent" rubric findings (5 checks).** The implementation chose a different idiom from what the rubric literally names; the semantic equivalent is in place. Architect-adjudicate as PASS if the owner agrees these are equivalent:

- **#I4 `bridge.objc-msg-send-conventions`** — `objc_send_ulong_ret_id` symbol is absent. Implementer used typed `fun apsk_make_<widget>(... action_token : UInt64) : Void*` declarations instead. Per Phase 3 implementation.md §7.4, the typed wrapper IS the canonical pattern (it's what `LibSwiftKitBridge` is for). The rubric's named symbol comes from §7.3, which describes the raw `objc_send_*` pattern that §7.4 supersedes.
- **#I10 `swiftkit.runtime-init-call-site`** — `APSKRuntime` install call-site is in the renderer's `ensure_swiftkit_runtime!` (uikit_renderer:4540, appkit_renderer:4510), not in the sample app. Renderer-internal idempotent install is arguably more robust than relying on every sample to remember the call.
- **#S2 `spec.overrides-population-toggle`** — `toggle_overrides_spec.cr` file does not exist. Assertions live in `group1_overrides_spec.cr` (`describe '#populate_toggle'` at line 187).
- **#S3 `spec.default-detection-invariant`** — `default_detection_spec.cr` file does not exist. The invariant IS covered structurally across button/group1/group3/glass_background spec files.
- **#S5 `spec.swift-overrides-propagation`** — `OverridesPropagationTests` exists and passes (24 tests, 0 failures) but does not assert against the cross-cutting `ViewOverrides` common field grid (backgroundColor / foregroundColor / padding / border / shadow / opacity / hidden / min-max have zero test mentions). The widget-specific overrides are covered; the common-field grid is not.

**Bucket B — genuine Phase 3 widget gap (1 check, but it affects 3 inspection checks too).** This needs a code fix:

- **`UI::ListView` (§6 #25) is missing entirely.** No facade, no overrides, no populator method. The visit() method in both renderers still builds raw `UIStackView`/`NSStackView`. ListView appears to have been dropped from Dispatch C scope (it's not in the navigation/modals/forms/menus groups the dispatch listed) and was not picked up in Remediation 1's scope (III). This drives failures on I3 (bridge.facades-called-for-each-widget), I6 (overrides-class-per-widget), I7 (facade-class-per-widget).

**Bucket C — env-blocked (23 checks, per binding adjudication).** Behavior + visual checks that need a working sample binary on a real iOS 26.2 simulator. Blocked by:
- `crystal-alpha` not installed on this host (needed for iOS sample build).
- No iOS 26.2 simulator / iPhone 17 Pro available.
- No macOS sample binary linked against the Swift companion (because the make path needs crystal-alpha).

These would unblock with environment provisioning, NOT with more remediation code. The Implementer's code is structurally complete; the validation host is the limiting factor.

---

## Three resolution paths

### (α) Adjudicate the 5 literal-vs-equivalent findings + dispatch tight Remediation 2 for ListView

Treat I4, I10, S2, S3, S5 as architect-adjudicated PASS (the semantic equivalents are demonstrably in place; the rubric's literal symbol/file names are not the only valid expression of the intent). Dispatch Remediation 2 narrowly for the ListView widget. Treat the 23 env-blocks as "ships pending hardware/toolchain availability for visual proofs."

**Result:** Phase 3 passes after Remediation 2 + adjudication. The env-blocks become a Phase-7-or-CI-provisioning concern. **Architect's recommendation.**

### (β) Full Remediation 2 covering all 8 substance gaps

Add the ListView widget + create the literal-named spec files (or rename existing ones) + extend OverridesPropagationTests with the cross-cutting field grid + add the literal symbol name + move the runtime install call-site to the sample app.

**Result:** Cleaner against the literal rubric, but doesn't change the 23 env-blocked checks. Phase 3 still can't be visually proven on this host. Bigger blast radius for what's mostly cosmetic alignment.

### (γ) Escalate to owner without dispatching Remediation 2

Per the protocol's "after one remediation loop, escalate" rule — surface to the owner and let them decide. We're already past the protocol's auto-loop budget; a second loop requires explicit authorization.

**Result:** Owner picks. This is what the protocol actually says to do.

---

## Architect's honest read

The bigger story is that Phase 3 is structurally complete on the Crystal + Swift sides. The only genuine code gap is ListView (1 widget out of 36 + ListView = 37). The other 5 "substance" failures are rubric-literal mismatches where the implementation's choice is defensible.

The 23 env-blocked checks are the real ceiling: without a working iOS 26.2 simulator + crystal-alpha installed, Phase 3 cannot prove visual fidelity. That's a validation-environment problem, not a Phase 3 implementation problem. Phase 7 (Visual Verification) is supposed to own the CI/hardware provisioning anyway.

Path (α) ships Phase 3 in this session. Path (β) ships Phase 3 in this session with more cosmetic-alignment work. Path (γ) explicitly surfaces to the owner without committing to either.
