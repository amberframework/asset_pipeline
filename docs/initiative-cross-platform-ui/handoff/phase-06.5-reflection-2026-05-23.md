# Phase 6.5 — Architect's Reflection — 2026-05-23

Phase 6.5 (Audit-Infrastructure-First) closed PASS at HEAD `51ec515`
on `phase-06.5-audit-infrastructure-first`, 12 commits past the
architect handoff at `d9b40b1` (9 Implementer + 2 Rem1 + 1 Rem2).
The phase shipped 6 distinct deliverables — unified audit harness,
visual-diff baseline tooling, AXTest pattern library, XCUITest
pattern library, generalized CDP probe library + vendored a11y
drivers, and a per-platform invariant probe coverage matrix routing
all 44 cells (32 working + 12 documented-skip).

## What worked

**The forcing-function-plus-trust-pair pattern caught two contract
gaps that would otherwise have shipped silently.** The Validator's
PASS_WITH_NOTES surfaced (a) iOS I-9 still using an artifact-presence
proxy at a wrong path, and (b) 7 real-probe failures that the
Implementer initially classified as artifact-presence passes. Both
gaps were the exact vacuous-probe pattern Codex flagged in brief
review Round 1. The remediation cycle (Rem1 → Validator → Rem2)
closed the violations cleanly.

**The Implementer's discovery-driven Xcode bootstrap saved hours.**
The remediation hit a project-name surprise (`CrystalHIGHost.xcodeproj`,
not the `HIGHost` the brief stubbed) and an iPhone destination
surprise (iPhone 17 paired with iOS 26 deployment target, NOT iPhone 15
which pairs with iOS 17.x). The Implementer added an
`AUDIT_HARNESS_IOS_DESTINATION` env override and auto-bootstrap via
xcodegen — both surfaced via the runtime probe, not the brief
authoring. Lesson: brief authoring can stub plausibly-named test
targets, but the Implementer's empirical discovery wins.

**The vendored-JS pattern for axe-core + IBM Equal Access shipped
clean.** No live npm install at runtime; both committed under
`vendor/audit/` with pinned versions and a vendor_install.sh that
documents the install steps. This is the right precedent for any
future JS-driver work.

## What didn't work the first time

**iOS probes shipped as artifact-presence proxies on iter 1.** The
Implementer (reasonably, per a misread of the <60s brief budget)
shipped fast file-existence checks instead of real xcodebuild test
invocations for all 9 iOS cells. The architect caught this at
pre-Validator review (spot-checking `bash audit_harness_smoke.sh
I-3 ios demo_button` exited 0 in 0ms — diagnostic of a proxy). Owner
authorized accepting the >60s budget overrun; Rem1 fixed 8 of 9 iOS
cells. The Validator caught the missed 9th cell (I-9 iOS still proxied
at a wrong path); Rem2 fixed it.

**Lesson:** "fast probe" shortcuts are a tell. When a cell reports
PASS in <100ms for what should be a real cross-process invocation,
the architect should challenge the contract. Future briefs should
specify minimum probe wall-clock time as part of the contract
("real probe MUST take >1s of wall clock"), making the proxy pattern
self-falsifying.

**Demo-content gaps are not the same as wiring gaps.** The 7
real-probe failures the Validator categorized as "demo-content gaps"
(probes are wired correctly but the underlying demo screens / baseline
images aren't ready) are correctly deferred to Phase 6, where the
Side-by-Side Demo App ships the demos these probes target. Phase 7's
CI integration will then expect them to pass.

## What to carry forward

1. **Minimum probe wall-clock contract.** Future brief invariant
   rationales should specify "real probe MUST take >N ms of wall
   clock" where N is a defensible lower bound (e.g., 100ms for any
   cross-process invocation). Makes proxy patterns auto-fail at
   Validator time.
2. **Xcode project bootstrap is part of the harness.** Phase 6.5's
   `IOSXcodeProbe.ensure_xcodeproj_fresh` is the right precedent —
   the harness regenerates the project from `project.yml` via
   xcodegen when stale. Phase 6 + Phase 7 inherit this.
3. **Phase 6 follow-up:** wire the 7 demo-content gaps to actual
   demos. The Validator's Findings #2 enumerates them.
4. **Phase 7 follow-up:** integrate the smoke shim into GitHub
   Actions CI. The audit_harness CLI is already CI-friendly
   (structured JSON output via `--format json`).

## Next phase

Phase 6 (Side-by-Side Demo App) — depends on Phase 6.5's harness
during development per the planning retrospective's audit-first
principle. With Phase 6.5 PASS, Phase 6 unblocks.

**Checkpoint 3 surface to owner:**
- Sign off on Phase 6.5 PASS_WITH_NOTES (with Rem 2 closing the
  contract violation; the 7 demo-content gaps deferred to Phase 6
  per Validator recommendation)
- Tag the passing state (`phase-06.5-pass-2026-05-23`)
- Authorize Phase 6 brief authoring + dispatch
