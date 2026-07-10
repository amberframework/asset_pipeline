# Master Plan — Cross-Platform UI Initiative

**Status:** Planning complete, ready for execution
**Initiative branch:** `feature/utility-first-css-asset-pipeline` (the merge target; each phase merges back here when its validator passes)
**Phase branches:** `phase-{NN}-{slug}` per phase (created by the Architect before each Team Lead dispatch; see "Branching Discipline" below)
**Date initiated:** 2026-05-20
**Roles:** **Architect** (oversees the entire initiative, dispatches per-phase Team Leads) → **Team Lead** (orchestrates one phase, dispatches Implementer + Validator) → **Implementer** + **Validator** (trust pair, never communicate with each other).

> **Read `origin.md` before reading the rest of this document.** It preserves the verbatim prompts from the project owner that shaped every load-bearing decision below. When a phase's formal docs are silent on an ambiguity, the origin is where the spirit of the work lives.

---

## North Star

A single Crystal source defines a demo app. It builds to **desktop web**, **mobile web**, **iOS native**, and **macOS native**. Looking at all four side-by-side, a reasonable observer can:

1. **Identify them as the same brand** — colors, type scale, spacing, radii, motion all read as a unified product.
2. **See the platform speaking its own language** — Apple platforms use SwiftUI defaults (system fonts, glass surfaces, action sheets, haptics); web uses browser-native semantics; behavior fluidly adapts when the macOS window or web viewport is resized between desktop and mobile widths.
3. **Verify accessibility** — every interactive element meets WCAG 2.2 AA on web and the platform equivalent on native (AXUIElement, XCUITest accessibility identifiers).

The Crystal API for the demo author looks the same on every platform. The library does the platform-tailoring underneath, with explicit opt-in for genuinely platform-only widgets.

---

## What This Plan Is

This document is the **team lead's working ledger**. It is the only document the team lead needs to read in full to understand:

- Where the work is in the overall sequence
- What phase is currently active
- Which agent (implementer or validator) should be spawned next
- What "done" means for each phase
- Where to find the detailed brief for each phase

The team lead **does not** execute implementation work directly. The team lead **delegates** to a trust pair (implementer + validator) per phase. See `rubric/trust_pair_protocol.md`.

---

## What This Plan Is Not

- Not a feature backlog. Backlog work lives in GitHub issues.
- Not a detailed implementation document. Each phase has its own `implementation.md` (briefing for the implementer agent) and `validation.md` (rubric for the validator agent).
- Not a Gantt chart. Phases are sequenced by dependency, not by date.

---

## Tier model (foundational concept)

Every widget and visual behavior in the library belongs to one of three tiers. This vocabulary is used throughout the plan and in every phase.

| Tier | Definition | Cascades to | Examples |
|---|---|---|---|
| **Tier 1 — Brand** | Universal design language: colors, spacing, type scale, border radius, motion, breakpoints. | All four platforms identically (within platform unit conventions). | Brand primary color, 4-pt spacing grid, semibold body text, 6 px button radius |
| **Tier 2 — Platform Default** | Visual treatment that comes from the platform's idiomatic UI library when the developer has not customized. | The platform's native styling (SwiftUI on Apple, browser-native on web, Material on Android). Overrides cascade from Tier 1 when developer customizes. | Default button hover (web :hover), default toggle animation (SwiftUI), glass surface (iOS 26+), system font fallback |
| **Tier 3 — Platform-Only Widget** | A widget that only exists on certain platforms and requires explicit opt-in. Using it on an unsupported platform is a compile-time error unless an explicit fallback is wired. | Native implementation on supported platform. Optional documented fallback on others. | `ActionSheet` (iOS), `ContextMenu` (macOS/iOS), `HapticFeedback` (iOS), platform notifications |

**Rule of thumb:** A demo screen written against the public API should compile and look correct on every supported platform **without** the author touching Tier 2 or Tier 3 concerns. The author writes against Tier 1; Tier 2 happens for free; Tier 3 is reached for intentionally.

---

## Branching discipline

Each phase gets its own working branch, cut from the latest commit of `feature/utility-first-css-asset-pipeline`. The Architect creates the phase branch **before** dispatching the Team Lead and merges it back **after** the validator passes. The Implementer and Validator both operate on the phase branch; they do not see or interact with the initiative branch directly.

Phase branch naming: `phase-{NN}-{slug}` where `NN` is the two-digit phase number and `slug` matches the phase folder. Examples:

- `phase-01-design-token-foundation`
- `phase-02-responsive-web-fluid-resize`
- `phase-03-swiftui-native-bridge`

Architect's per-phase git rhythm:

1. **Before dispatch:**
   ```
   git checkout feature/utility-first-css-asset-pipeline
   git pull --ff-only origin feature/utility-first-css-asset-pipeline   # if remote exists
   git checkout -b phase-{NN}-{slug}
   ```
2. **Team Lead dispatched.** Implementer commits incrementally on this branch; Validator runs against the same branch.
3. **On a passing GATE_REPORT:**
   ```
   git checkout feature/utility-first-css-asset-pipeline
   git merge --ff-only phase-{NN}-{slug}
   git tag phase-{NN}-passed-{YYYY-MM-DD}
   git branch -d phase-{NN}-{slug}    # optional
   ```
4. Update the progress ledger to `Passed`. Archive the gate report under `handoff/`. Write a reflection note (`handoff/phase-{NN}-reflection-{date}.md`).
5. **Checkpoint with the project owner before creating the next phase's branch.** Phase transitions are deliberate, not autopilot.

**Forbidden:** force-push, `rebase --interactive` rewriting already-handed-off history, deleting the initiative branch, deleting passed-phase tags, branching off anything other than the latest passed state of the initiative branch. If a passed phase needs correction, the correction is a forward commit on the current phase's branch — never a rewrite of history before the passed tag.

---

## Phase sequence

Phases are listed in dependency order. The team lead must complete validation gates in order; do not parallelize unless explicitly noted in the phase's README.

| # | Phase | Purpose | Folder |
|---|---|---|---|
| 1 | **Design Token Foundation** | Single source of truth for Tier 1: colors, spacing, type, radius, motion, breakpoints. Generators for web CSS, Apple Swift, Android resources. Brand override API. | `phases/phase-01-design-token-foundation/` |
| 2 | **Responsive Web Fluid Resize** | Replace pixel constraints with `clamp()`. Implement container queries. Mobile-first layout. Viewport meta. Touch-target minimums. | `phases/phase-02-responsive-web-fluid-resize/` |
| 3 | **SwiftUI Native Bridge** | Swift companion library exposing SwiftUI components via `@objc`. Crystal renderers use SwiftUI defaults; modifiers only when Crystal view declares overrides. | `phases/phase-03-swiftui-native-bridge/` |
| 4 | **Platform Tier Gating** | Formalize Tier 1/2/3. Add compile-time guards on Tier 3 widgets. Document and (where reasonable) provide web fallbacks for Tier 3. | `phases/phase-04-platform-tier-gating/` |
| 5 | **Glass Material Tokenization** | Promote glass material strength to design tokens. Wire all renderers (incl. RenderEffect on Android API 31+). Brand override of glass intensity. | `phases/phase-05-glass-material-tokenization/` |
| 6 | **Side-by-Side Demo App** | Single Crystal source. Builds web + iOS + macOS. Five representative screens. Screenshot harness for the four-up comparison page. | `phases/phase-06-side-by-side-demo-app/` |
| 6.5 | **Audit-Infrastructure-First** | NEW (added 2026-05-22 per planning retrospective). Ships the reusable audit harness — visual diff baseline tooling, CDP harness extensions, AXTest/XCUITest patterns, accessibility audit drivers — that Phase 6 uses *during development* and Phase 7 wraps into CI. Resolves the Phase-7-depends-on-Phase-6 audit-first conflict surfaced by Codex round 2 critique. | `phases/phase-06.5-audit-infrastructure-first/` |
| 7 | **CI Integration for Accessibility & Visual Verification** | Wraps Phase 6.5's harness into GitHub Actions / equivalent. Visual regression baselines per screen × platform × viewport × scheme run on every PR. Accessibility audits per platform run on every PR. Re-scoped from "build audit infrastructure" (now in 6.5) to "integrate audit infrastructure into CI." | `phases/phase-07-accessibility-visual-verification/` |

### Why this order

- **Phase 1 is the foundation.** Every later phase reads from the token system.
- **Phase 2 can technically run in parallel with phase 3**, but the team lead should serialize them to keep validation evidence clean. If schedule pressure demands parallelization, document the decision in `handoff/` and run two separate validators.
- **Phase 3 (SwiftUI bridge) is the highest-risk phase.** A failed validation here means the entire native experience is wrong. Budget for at least one remediation loop.
- **Phase 4 depends on phase 3** because Tier 2 defaults can only be verified once SwiftUI is in place.
- **Phase 5 depends on phases 1 + 3** (tokens + SwiftUI surface).
- **Phase 6.5 depends on phases 1-5** structurally but ships BEFORE Phase 6 begins. Reason: per `handoff/planning-retrospective-2026-05-22.md` Principle 6, audit infrastructure must exist during the work it audits, not afterwards. The original master plan had Phase 7 depending on Phase 6; that conflicts with the audit-first lesson Phase 3 paid dearly to learn.
- **Phase 6 depends on phases 1–5 + 6.5.** Earlier dry runs of the demo are fine but don't satisfy phase 6's validation criteria, AND phase 6's empirical verification uses the harness shipped in 6.5.
- **Phase 7 depends on phase 6** (CI baselines need a working app to baseline). Phase 7's scope is narrowed: integrate Phase 6.5's harness into CI; don't author new infrastructure.

---

## Progress ledger

The team lead updates this table as work proceeds. Each row's `Status` is one of:

- `Not Started` — nothing dispatched
- `Implementer Active` — implementer agent currently working
- `Implementer Returned` — implementer reported done, validator not yet spawned
- `Validator Active` — validator running checklist
- `Failing` — validator returned failures; implementer needs to be re-spawned with the gate report
- `Passed` — all required checks pass; phase complete

| # | Phase | Status | Implementer commit(s) | Validator report | Notes |
|---|---|---|---|---|---|
| 1 | Design Token Foundation | **Passed (2026-05-20)** — tag `phase-01-passed-2026-05-20` | `5b6483b 40e396d 0e3b943 575613a 8ecd37d 006dc70 3874a4e 8b68717` + remediation `a84c6c3 4cefe9f 0988646` | `handoff/phase-01-passed-2026-05-20.md` (iter 2 PASS); `handoff/phase-01-failing-1-2026-05-20.md` (iter 1 FAIL → remediated); `handoff/phase-01-reflection-2026-05-20.md` (architect reflection) | Iter 2 verdict PASS: 19/20 required checks pass; 3 deferred per architect handoff; #20 iOS cascade blocked but Architect-adjudicated satisfied by #19 macOS pivot proof. Merged ff into `feature/utility-first-css-asset-pipeline`. Awaiting Seth checkpoint #3 before Phase 2 dispatch |
| 2 | Responsive Web Fluid Resize | **Passed (2026-05-20)** — tag `phase-02-passed-2026-05-20` | `e17f7b6 b8709ac a82ad02 a710f6b a6ebee4 93205f4 c185f01 44d003f 5a5b52c 36f74f9` + remediation `c735c47 12cf77f 5b996c3 a5beccc` | `handoff/phase-02-passed-2026-05-20.md` (iter 2 PASS); `handoff/phase-02-failing-1-2026-05-20.md` (iter 1 FAIL → remediated); `handoff/phase-02-reflection-2026-05-20.md` | Iter 2 verdict PASS: 25/25 required checks pass. Iter-1's 12 failures all closed by 4 remediation commits. Merged ff into `feature/utility-first-css-asset-pipeline`. Awaiting Seth checkpoint before Phase 3 dispatch |
| 3 | SwiftUI Native Bridge | **Passed (2026-05-21)** — tag `phase-03-passed-2026-05-21` | R1-2 (already listed); R3: `e754104 61e8663 1a77437 8007e8c 9a0bcfd 119004d`; R4: `bc2b246 133da34 92cf0ad 2105cc0 bb9b5d2 1701668 2a431e5`; R5: `a818e7d a1049ea`; R6: `21b1ddd`; R7: `7d0b0d5 90a2d54`; R8: `5fc9dbd 6955460 e351f62 0faf0f0 4f7da71 d352561 9e49083 9a7d78f f469fd0`; R9: `427c50b a2e56bb`; R10: `e3a26c1 376343a 8349809 bfd129d` | `handoff/phase-03-passed-2026-05-21.md` (iter 7 PASS); `handoff/phase-03-reflection-2026-05-21.md` (architect reflection); `handoff/phase-03-iter4-2026-05-21.md` + `phase-03-iter3-2026-05-21.md` + R3/R5 blockers + R8 investigation (failing iters); `handoff/phase-03-state-2026-05-21-codex-context.md` (Codex review framing) | Iter 7 verdict PASS: 49/49 required checks. All 3 load-bearing reactive invariants (BX1 button-tap, BX2 macOS, BX5 override-rerender) empirically proven on both macOS 26.5 + iPhone 17 Pro iOS 26.5. R3 authored 12 probe slugs + XCUITest + AXTest specs; R4 shipped reactive forward bridge; R5+R6 fixed iOS link + require leaks; R7 fixed AX-tree discoverability; R8 fixed 3 of 5 iOS bugs (sprintf, contentShape, frame); R9 fixed BX8 launch crash via class-init workaround + falsified R8 hypotheses with diagnostic-first protocol; R10 shipped UISwitch UIViewRepresentable for BX3 + full reactive Sheet bridge for BX8 (with Codex CLI brief-review + 4-checkpoint critique cycle). Merged ff into `feature/utility-first-css-asset-pipeline`. Phase 5+ inheritances: class-init systematic fix, Groups 4-5 widgets. Awaiting Seth checkpoint before Phase 4 dispatch |
| 4 | Platform Tier Gating | **Passed (2026-05-22)** — tag `phase-04-passed-2026-05-22` | Initial (10 atomic + 2 Codex follow-ups): `bfcb103 958b004 724ca7f 8df0242 cdee220 6da452f 5e27a12 49e48b1 a8db5d9 56dc514 2ce5da6 022dc11`; R1 (6 — test pages + CDP harness): `049da91 259a8d6 ae20a1b f97a57e 5895189 6c20a52`; R2 (2 — renderer accessibility fixes): `8192575 6180a14` | `handoff/phase-04-passed-2026-05-22.md` (iter 2 PASS); `handoff/phase-04-reflection-2026-05-22.md` (architect reflection); `handoff/phase-04-evidence-2026-05-21-iter1/` + `phase-04-evidence-2026-05-22-iter2/` (validator iterations); `handoff/phase-04-implementer-deviations.md`; `handoff/phase-04-r2-evidence-2026-05-22/` | Iter 2 verdict PASS: 31/31 required checks. All 3 Tier-3 gates produce exact compile-error format on wrong platform; all 3 *WithWebFallback siblings cross-compile everywhere. 12/12 CDP behavior probes empirically PASS (focus trap + escape + backdrop + positioning + touch targets + axe-core + IBM Equal Access for ActionSheet and ContextMenu; semantic structure for PathControl). Tier matrix complete (78 widgets: 17 Tier 1 / 55 Tier 2 / 3 Tier 3 gated + 3 fallback companions). Phase 3 regression check clean (iOS XCUITest 10/10, macOS AXTest 2/2, swift test 53/53, crystal spec baseline + 4 pre-existing failures). Codex CLI brief-review + 4-checkpoint critique cadence used throughout; R1 found 12 blocked behavior probes were latent test-coverage gaps; R2 fixed 2 real WCAG-AA renderer-source bugs the CDP harness exposed (color contrast --ap-color-brand-accent→--ap-color-brand-primary at web_renderer.cr:2721 + remove role="group" from action-sheet \<ul\> at web_renderer.cr:2589). Merged ff into `feature/utility-first-css-asset-pipeline`. Phase 5 inheritances: Crystal-iOS class-init systematic fix (carried from Phase 3), HapticFeedback widget (Phase 4 deferred). Awaiting Seth checkpoint before Phase 5 dispatch |
| 5 | Glass Material Tokenization | **Passed (2026-05-22)** — tag `phase-05-v2-pass-2026-05-22` | Architect handoff: `4ccdb29`. Implementer iter 1 (11 atomic): `800076c 7b2a458 13c45b2 a9fc062 64198d3 d4bdd7b a901cb2 c871e31 e2a4dab 404695b 587e7a7`. Remediation 1 (1 — .glassEffect() gate on 5 Cat-B facades): `87d388d` | `handoff/phase-05-v2-validation-2026-05-22.md` (Validator PASS); `handoff/phase-05-v2-architecture-2026-05-22.md` (owner-signed-off architecture); `handoff/phase-05-v2-reflection-2026-05-22.md` (architect reflection); `handoff/phase-05-material-capability-matrix-2026-05-22.md` (pre-decision matrix that drove the Hybrid choice); `handoff/phase-05-appkit-legacy-material-debt-2026-05-22.md` (Phase 5.5 carry-forward); iter-1 evidence under `handoff/phase-05-evidence-2026-05-22-iter1/` + iter-2 FAIL under `handoff/phase-05-evidence-2026-05-22-iter2/` | Iter 1 + 2 FAIL on the single-axis-thickness model; v2 architecture introduced the two-axis (AppleSemantic + ThicknessStep + intensity) model per owner-chosen Hybrid path. Validator PASS at HEAD `87d388d`: all 11 invariants, all 9 lower_layer_assumptions, all 9 repo_derived_facts, 4 build closures (swift release, macOS host, iOS Crystal-lib simulator, web semantic), material spec 31/31, crystal spec baseline (only 4 pre-existing failures). Pre-Validator Codex review caught 1 blocker (Cat-B facades missing iOS 26+/macOS 26+ `.glassEffect()` gate); Rem1 fixed in `87d388d`. Phase 5.5 carry-forward: delete 6 `_legacy_*` AppKit methods; Phase 6.5 ships audit harness for Apple-platform probe placeholders. Awaiting Seth checkpoint before Phase 6 dispatch |
| **5.5** | **AppKit + UIKit Legacy Material Cleanup** (added 2026-05-22 post-Phase-5 v2 PASS) | **Passed (2026-05-22)** — tag `phase-05.5-pass-2026-05-22` | Architect handoff: `10ae763`. Implementer (1 atomic): `b6875b9`. Architect brief amendment (post-impl state): `be04dae` | `handoff/phase-05.5-validation-2026-05-22.md` (Validator PASS); `handoff/phase-05.5-reflection-2026-05-22.md` (architect reflection) | Tiny phase: deleted 12 `_legacy_*` dead-code Category B methods (6 AppKit + 6 UIKit), 1465 lines net deletion, 0 insertions. All 9 README acceptance items PASS: AppKit + UIKit `_legacy_*` counts 0; facade counts unchanged at 6/6; macOS host + iOS Crystal-lib + web semantic builds exit 0; crystal spec baseline 1454/4/0 (4 allowlisted pre-existing failures); material spec 31/0. Brief authored against the schema, Codex caught 3 blockers pre-dispatch (target count, iOS probe misnaming, README acceptance vagueness), all fixed. Phase 5 v2 surfaces (swift/, design_tokens/, views/) untouched. Awaiting Seth checkpoint before Phase 6.5 dispatch |
| 6 | Side-by-Side Demo App | **Passed (2026-05-23) PASS_WITH_NOTES** — tag `phase-06-pass-2026-05-23` | Architect handoff: `b26b688`. Implementer iter 1 (8): `aa25c6e..8186359`. Rem 1 (iOS class-init crash fix + 10 iOS baselines): `01e4aba..b04bc86`. Rem 2 (macOS sign-in + brand-tint Link): `a3d3a96..cbe7351`. Rem 3 + 3-completion (Sign-in button visible + Font knob): `e64de96..2008cb5` + architect in-flight `fddcc71`. Rem 4 (regressed): `071d91b..3dcd6e1`. Rem 5 (rollback + Codex co-pilot fix attempt + revert): `45a4486..0d19dc0` | `handoff/phase-06-validation-2026-05-23.md` (Validator PASS_WITH_NOTES); `handoff/phase-06-reflection-2026-05-23.md` (architect reflection); `handoff/phase-06-rem3c-followups-2026-05-23.md` + `handoff/phase-06-rem5-fix1-blocked-2026-05-23.md` (deferral docs) | 5 demo screens shipped × 4 user-facing surfaces (web-desktop, web-mobile, iOS sim, macOS host) × 2 appearances = 40 baseline PNGs committed. Quad-comparison.html assembles brand-litmus grid. CascadeDemo.app launches without crashing post-Rem-1 (Codex diagnosed iOS class-init gap on BRAND_TOKENS module constant; fix replaced with brand_tokens method). audit_harness_smoke.sh I-1 web/macos/ios demo-all all PASS with real probes (iOS via xcodebuild test ~20s/slug). Production code surface: scripts/cdp_probes/devtools.cr Chrome wait-loop bump (benign infra); src/ui/views/label.cr font_size/font_weight knobs; src/ui/native/swiftkit_overrides.cr label populator extension. **3 deferrals to Phase 7 / Phase 6.8:** brand-teal tint propagation through SwiftUI .borderedProminent (4 Rem cycles couldn't converge; iOS 26's chrome resolves .accentColor sentinel but not concrete Color values — Rem 5 handoff doc proposes bypassing .borderedProminent with explicit Capsule fill); macOS Sign-in button width pin (340pt content_width not respected on Prominent style); social-row :secondary role → .bordered chrome mapping. Regression baselines clean (crystal spec 1454/4/0 → +1 unrelated test = 1455/4/0; material spec 31/0/0; all 4 build closures exit 0; Phase 5 v2 + 5.5 + 6.5 invariants preserved). Phase consumed 5 remediation cycles — reflection doc documents the convergence failure on brand-teal as a SwiftUI per-platform tint-resolution lesson. Awaiting Seth checkpoint before Phase 7 dispatch |
| **6.5** | **Audit-Infrastructure-First** (added 2026-05-22 per retrospective) | **Passed (2026-05-23)** — tag `phase-06.5-pass-2026-05-23` | Architect handoff: `d9b40b1`. Implementer iter 1 (9): `f42fbb2 9827aac 8b1adbe 91072b2 1863093 f6487f7 4a728c6 f852259 ace85c1`. Rem 1 (iOS probe real-ization): `cd0e7b4 0a090b5`. Rem 2 (I-9 iOS missed cell): `51ec515` | `handoff/phase-06.5-validation-2026-05-23.md` (Validator PASS_WITH_NOTES); `handoff/phase-06.5-reflection-2026-05-23.md` (architect reflection) | All 6 deliverables shipped: unified `scripts/audit_harness.cr` + `audit_harness_smoke.sh` (44 probe cells routed: 32 working + 12 documented-skip); visual-diff tooling (`scripts/visual_diff.cr` + `regenerate_baselines.sh` + canonical `baselines/` tree with migrated Phase 3 baselines); AXTest pattern library at `spec/support/ax_test_patterns.cr` (8 modules); XCUITest pattern library at `samples/cross_platform/ios_host/UITests/Patterns/` (7 files); generalized CDP probes at `scripts/cdp_probes/` (8 files) + vendored axe-core 4.10.2 + ACE 4.0.17 under `vendor/audit/`. Rem 1 + Rem 2 closed two iterations of the vacuous-probe pattern (iOS I-1..I-7 + I-11 + I-9 all converted from artifact-presence proxies to real `xcodebuild test` invocations via `IOSXcodeProbe` helper). 7 real-probe failures deferred to Phase 6 (demo-content gaps, not wiring gaps). Production code (src/ui/, swift/) untouched; regression baselines unchanged (crystal spec 1454/4/0, material spec 31/0, all 4 build closures exit 0). Awaiting Seth checkpoint before Phase 6 dispatch |
| **6.8** | **Visual Polish Deferrals from Phase 6** (added 2026-05-23 post-Phase-6 PASS_WITH_NOTES) | **Passed (2026-05-23)** — tag `phase-06.8-pass-2026-05-23` | Architect handoff: `afb7791`. Implementer iter 1 + continuation (5): `e5ebec3 290ed34 524cdd1 d5edf4f 3faab95` | `handoff/phase-06.8-validation-2026-05-23.md` (Validator PASS); `handoff/phase-06.8-reflection-2026-05-23.md` (architect reflection) | 3 visual fixes shipped in ButtonFacade.swift (+34 lines): (1) brand-teal Capsule.fill bypass of .borderedProminent — iOS Sign-in samples to exactly srgb(3,133,133)=#038585 confirming Phase 6 brand override; (2) macOS exact frame(width:) pin when min_w==max_w + prominent — button now 340pt matching email/password fields; (3) :secondary role → .bordered chrome via post-switch role check (Implementer discovered :secondary arrives as a ROLE not a STYLE through swiftkit_overrides.cr). Per-fix Codex check protocol (Phase 6 Rem 5 lesson) prevented regression. Diff scope tight: only ButtonFacade.swift + 4 sign-in baselines touched. iOS Sign-in button visibility preserved across all 3 fixes. Minor macOS cosmetic artifact (inner rectangle from SwiftUI Button's default label rendering overlaying Capsule.fill) documented as Phase 7 follow-up. Regression baselines clean (crystal spec 1455/4/0, material spec 31/0, all 4 build closures exit 0, audit harness I-1 web/macos/ios demo-sign-in all PASS with real probes). Awaiting Seth checkpoint before Phase 7 dispatch |
| **6.9** | **macOS Button Inner-Rectangle Artifact** (added 2026-05-23 post-Phase-6.8 PASS) | **Passed (2026-05-23)** — tag `phase-06.9-pass-2026-05-23` | Architect handoff: `c68d36f`. Implementer (2): `848c90a b4ba884` | `handoff/phase-06.9-reflection-2026-05-23.md` (architect reflection) | Single-line ButtonFacade.swift fix: appended `.buttonStyle(.plain)` to the prominent case's modifier chain to suppress SwiftUI's default macOS Button chrome that was overlaying the Capsule.fill brand-teal pill. macOS sign-in baseline now shows clean brand-teal Capsule with white "Sign in" label (no inner darker rectangle artifact). iOS sign-in preserved (no regression). All 8 regression gates pass (crystal spec 1455/4/0, material spec 31/0, swift build + 3 demo builds + 3 I-1 audit probes). Cleanest dispatch in the Phase 6.x series — 1 fix, 1 dispatch, 0 remediations, single Codex check verdict PROGRESS. Awaiting Seth checkpoint before Phase 7 dispatch |
| 7 | CI Integration for Accessibility & Visual Verification | **Passed (2026-05-23) PASS_WITH_NOTES** — tag `phase-07-pass-2026-05-23` | Architect handoff: `4e93064`. Implementer (5): `400068c 052caf3 a63c99b 83bfa7d 687e814` | `handoff/phase-07-validation-2026-05-23.md` (Validator PASS_WITH_NOTES); `handoff/phase-07-reflection-2026-05-23.md` (architect reflection — initiative close-out) | 3 deliverables shipped: (1) GitHub Actions workflow at `.github/workflows/initiative-cross-platform-ui.yml` (436 lines); (2) verification runbook (251 lines); (3) CLAUDE.md pointer. Codex caught 4 brief + 3 implementation blockers; all closed. Regression clean. ~~INITIATIVE COMPLETE.~~ **REOPENED** — owner Cascade hand-test surfaced gaps that drove Phase 6.10/6.11/6.12/8. |
| **6.10** | **Navigable CRUD Demo + Navigation Coordinator** (added 2026-05-23 post-Phase-7 owner review) | **Passed (2026-05-23) PASS_WITH_NOTES** — tag `phase-06.10-pass-with-notes-2026-05-23` | Multi-remediation arc (initial + 4 Rem). HEAD `15bc2bd` then merged via `45d2d58`. | `handoff/phase-06.10-reflection-2026-05-23.md` | Owner identified Cascade as "screenshot catalog, not a navigable app." 6.10 shipped: `UI::NavigationCoordinator` (reactive push/pop/on_change), `UI::SwipeActionRow`, route-host re-render, Path A UIHostingController VC parenting (architectural fix to SwiftUI Button tap chain), AX tree traversal across SwiftUI/UIKit boundary, device-aware utilities (DeviceMetrics, root_fill, safe-area tokens, size-class breakpoints), string-callback bridge for Save propagation, iOS class-init gap workaround. 4 feedback memories saved. 4 remediations consumed. Voyager Todos demo navigable end-to-end on web; native hosts shipped but interaction-untested at close. |
| **6.11** | **iOS Polish + SwiftUI Defaults** (added 2026-05-23 post-6.10 owner hand-test) | **Passed (2026-05-24) PASS_WITH_NOTES** — tag `phase-06.11-pass-with-notes-2026-05-24` | Multi-iteration arc (initial + iter 2/3/4/5). HEAD `f53487f` then merged via `45d2d58`. | `handoff/phase-06.11-reflection-2026-05-24.md` | Owner directive: "stick with SwiftUI defaults." 6.11 shipped: Voyager `brand.cr` deletion; ButtonFacade prominent teal hardcode REMOVED → restored to `.borderedProminent`; `PromptOverlayField` wrapper for placeholder contrast (~4:1 WCAG AA); reactive Button/Label runtime state mutators; `NavigationCoordinator#republish`; swipe-row UIScrollView height fix; `UI::RenderError` loud failure path. 3 new feedback memories. Iter-5 architectural finding surfaced: `Tokens.default.brand_primary` still amber post-deletion — library default itself needs the pivot (Phase 6.12 Option C). |
| **6.12** | **Library-Identity Pivot (Option C) + macOS Cascade Fix** (added 2026-05-24 post-6.11 architectural finding) | **Passed (2026-05-24) PASS_WITH_NOTES** — tag `phase-06.12-pass-with-notes-2026-05-24` | 3 sub-phases (6.12A code + 6.12B captures + 6.12C Cascade regression fix). HEAD `8b8cd9fe` on feature. | `handoff/phase-06.12-reflection-2026-05-24.md` | 6.12A shipped `Color::SYSTEM_ACCENT` sentinel — `Tokens.default.brand_primary` family resolves to platform system accent (iOS systemBlue, macOS controlAccentColor, web `AccentColor` keyword, Android raises NotImplemented). 4 renderer integrations + macOS NSWindow sizing (880×640 default, both-axes resizable, 480×400 floor) + Cascade preservation + no-amber audit across generated outputs. 6.12B capture agent surfaced the Cascade macOS prominent-button regression (`.borderedProminent` ignores `.tint()` on macOS). 6.12C closed it via Path A-prime: new `APSKBrandProminentButtonStyle.swift` (macOS-only custom ButtonStyle from primitives), gated `#if os(macOS) && brandTint != nil`. iOS branch byte-identical to 6.11. Spec 1497 → 1529 (+32). Open notes: pixel-gamma caveat on Cascade R-channel; 14-row behavior contract deferred to 8D. 1 new feedback memory. |
| **8** | **Ergonomic Top-Level API + Amber Integration** (added 2026-05-24 per owner directive: ergonomic top-level API for drop-in Amber view layer) | **8A Passed (2026-05-24) PASS — clean** — tag `phase-08a-pass-2026-05-24`. Sub-phases 8B in-flight, 8C drafted, 8D/8E TBD. | 8A HEAD `721768e1` on feature. 8B in-flight on `phase-08b-native-app-controller`. | `phase-08-ergonomic-mvc-api/{design.md,brief-8a.md,brief-8b.md,brief-8c.md,codex-critique-*.md}`; `handoff/phase-08a-reflection-2026-05-24.md` | Architecture: parallel-controllers per Codex v1 REJECT salvage. Web uses `Amber::Controller::Base` directly with `UI::ScreenHelpers` mixin providing `compute_screen_html(ScreenClass)`. Native uses parallel `UI::App` + `UI::Controller` + `UI::ActionDispatcher` + `UI::FormState` (Phase 8B). Shared `UI::Screen` + `UI::View` authoring. Design v2 went through 3 Codex passes; spike at `samples/phase-08-amber-spike/` proved Amber integration end-to-end before production code. 8A shipped `src/asset_pipeline/amber_integration.cr` + extended `UI::Form` with web POST semantics (action/method/csrf_token, `UI::RenderContext` threading for CSRF) + name/text kwargs on TextField/SecureField + `UI::Button::Type` enum + per-controller static shim ECR + CLI generator. **Closing gate: real headless Chrome 149 via Selenium driving a real form submit — HTTP 200 + flash notice in post-submit page.** Spec 1529 → 1576 (+47). First clean PASS this session (not PASS_WITH_NOTES). 5/5 per-iteration Codex APPROVE; 0 REJECT; 4-pass brief critique cycle. |

---

## Team lead / Architect playbook (how to use this document)

**Updated 2026-05-22 per `handoff/planning-retrospective-2026-05-22.md` to require the phase-brief forcing function before any dispatch.**

1. **Read this MASTER_PLAN.md fully.** Then read `rubric/trust_pair_protocol.md`, `rubric/implementation_criteria.md`, `rubric/validation_criteria.md`, AND `handoff/planning-retrospective-2026-05-22.md` (the 11-invariant grid + 8 forward principles). Together these are about a 25-minute read; they are the entire surface area of how to do the job.
2. **Identify the next `Not Started` phase** in the progress ledger.
3. **Open that phase's folder** and read its `README.md`. The README orients you to the phase's scope, dependencies, and acceptance criteria.
4. **AUTHOR the phase brief as YAML** at `phases/phase-NN-<slug>/brief.yml` against `schemas/phase_brief.schema.json`. The brief MUST contain: the `phase` metadata, exactly 11 invariant rows in `invariant_matrix` (one per I-1..I-11), `lower_layer_assumptions` for every layer the phase touches, `repo_derived_facts` for every numeric/symbolic claim, `adapter_cardinality` for any public API bound to a native component, and a `pre_dispatch_validation` section pointing at a runnable script.
5. **RUN the validator BEFORE dispatching the implementer:** `crystal run scripts/validate_phase_brief.cr -- phases/phase-NN-<slug>/brief.yml`. **Exit 0 is mandatory before dispatch.** Any non-zero exit (1=schema, 2=fact-drift, 3=assumption-falsified, 4=cardinality-mismatch, 5=path-nonexistent, 6=pre-dispatch-validation) means the brief is not dispatchable; fix the gap before proceeding.
6. **Spawn the implementer agent** following the trust pair protocol. Pass `implementation.md` PLUS the validated `brief.yml` as the briefing.
7. **When the implementer returns**, update the ledger to `Implementer Returned`. Spawn the validator agent. Pass `validation.md` as the rubric.
8. **When the validator returns a passing GATE_REPORT**, update the ledger to `Passed`, archive the report under `handoff/phase-XX-passed-YYYY-MM-DD.md`, and move to the next phase.
9. **When the validator returns failures**, update the ledger to `Failing`, archive the report under `handoff/phase-XX-failing-N-YYYY-MM-DD.md`, and re-spawn the implementer with the gate report attached so they can remediate.

Hard rules for the team lead / Architect:

- **NEVER dispatch without an exit-0 `validate_phase_brief.cr` run** on the phase's `brief.yml`. The validator is the forcing function that converts the planning lessons into mechanical enforcement. Bypassing it defeats the retrospective.
- **Never edit the phase folders' `implementation.md` or `validation.md`** without first capturing why in a handoff note. Those documents are contracts.
- **Never skip a validation gate** to "save time." A missed gate means the next phase is building on unverified ground.
- **Always update the progress ledger before context-switching.** The ledger is the only thing that survives a team-lead agent restart with full fidelity.
- **Use Codex CLI as antagonist when authoring phase briefs.** The retrospective documents 5+ rounds where Codex caught real defects; treat it as a productive antagonist, not a rubber stamp.

---

## Out of scope (explicit non-goals)

- Renaming the library or any of its public APIs.
- Migrating Android to Compose. Android remains View-based with Material 3.
- Building a SwiftUI-equivalent for Android or Web. SwiftUI is an Apple-only bridge.
- Replacing the existing `samples/cross_platform/` HIG validation studies. Those continue to serve as fine-grained per-component reference; the new demo app in phase 6 is a different artifact serving a different purpose (side-by-side brand verification, not per-component HIG conformance).
- Performance work. The plan assumes the rendering performance of the existing renderers is acceptable; performance regressions are bugs, not phase work.

---

## Related docs

- **`system-prompt.md`** — The concise identity / role / non-negotiables the project owner pastes as the Architect agent's system prompt. Persistent across every turn.
- **`start-architect.md`** — The operational first-turn protocol the Architect reads after the system prompt. Required reading order, per-phase git rhythm, bookkeeping rhythm, checkpoint moments, first actions.
- **`origin.md`** — **Read this FIRST.** Verbatim prompts from the project owner that shaped this plan; preserves the spirit when the formal docs go silent on an ambiguity.
- `rubric/trust_pair_protocol.md` — how the implementer + validator dance works
- `rubric/implementation_criteria.md` — universal implementer standards
- `rubric/validation_criteria.md` — universal validator standards (incl. presence/behavior/conformance taxonomy)
- `rubric/behavior-simulation-toolkit.md` — concrete recipes for driving real input on macOS / iOS / web; documents the shipped AXTest extensions A1–A7
- `rubric/gate_report_schema.md` — schema for validator reports
- `phases/phase-XX-*/README.md` — per-phase orientation
- `phases/phase-XX-*/implementation.md` — per-phase implementer briefing
- `phases/phase-XX-*/validation.md` — per-phase validator rubric
- `handoff/` — append-only log of all phase transitions and gate reports (incl. `plan-quality-audit-2026-05-20.md`, the audit that drove the first round of revisions)
