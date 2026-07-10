# Phase 5 v2 — Architect's Reflection — 2026-05-22

Phase 5 (Glass Material Tokenization) closed PASS at HEAD `87d388d` on
`phase-05-glass-material-tokenization`, 13 commits past the architect handoff
at `4ccdb29`. This note captures what worked, what didn't, and what the next
phase should carry forward.

## What worked

**The brief-as-contract pattern delivered.** The `phase_brief.schema.json`
+ `scripts/validate_phase_brief.cr` forcing function caught real authoring
defects (placeholder text, null-op probes, fact drift) at draft time, and
the 3 pre-dispatch Codex antagonist rounds resolved 8+ substantive blockers
before any code was written. The brief's `lower_layer_assumptions` ran as
shell commands; the `repo_derived_facts` ran as grep queries; nothing was
prose-only.

**Trust-pair held.** Implementer landed 11 commits + Rem1 commit; Validator
independently re-verified every invariant, every assumption, every fact, and
4 build closures. Their report cited file:line for every claim. They even
caught their own self-inflicted error (a `git checkout 4ccdb29 -- src/` that
overwrote sources) and recovered cleanly. The trust-pair pattern is doing
exactly what it's supposed to do.

**Pre-Validator Codex review caught one real blocker.** The Implementer
shipped the per-widget pre-26 SwiftUI modifier for 5 Category B facades but
skipped the `if #available(iOS 26.0, macOS 26.0, *)` gate that swaps to
`.glassEffect()`. Codex caught it; Remediation 1 fixed it in a single commit
(`87d388d`). Without the gate, Liquid Glass-capable platforms would have
ignored the cross-platform `.glassEffect()` contract.

## What didn't work the first time

**The original Phase 5 brief had a model error.** Iter 1 + iter 2 dispatched
against a single-axis (thickness-only) Material that conflicted with Apple's
semantic NSVisualEffectMaterial vocabulary. Two FAILs surfaced the model
gap. The cure was the v2 architecture doc + capability matrix + Codex
adversarial review of three architecture options. Owner picked Hybrid
two-axis. The v2 brief and dispatch worked first try (modulo Rem1).

**Lesson:** when a brief's `adapter_cardinality` claims an API↔adapter
mapping that contradicts the platform's design vocabulary, the brief is
wrong, not the implementation. The v2 brief now has 3 explicit
`adapter_cardinality` rows (Apple semantic / web thickness / Android
thickness) and the v2 architecture doc's per-widget defaults table is
binding.

**The Implementer's report was substantially correct but overclaimed in two
places.** They claimed `make -C samples/cross_platform/macos_host build`
exited 0 — true at the time they ran it, but the iOS Crystal-lib build they
ran AFTER clobbered `.build/release` symlink to point at the iOS Simulator
variant. When I verified, the macOS host build failed until I rebuilt the
swift package for macOS. Procedural, not contract-violating, but worth
documenting.

**Lesson for the build harness:** `make` macOS host build and iOS
Crystal-lib build are mutually exclusive on the `.build/release` symlink.
Phase 5.5 or Phase 6 should harden the Makefile / build script to detect
the wrong-target symlink and rebuild as needed.

## What to carry forward

1. **Use the same brief-authoring loop for Phase 6+.** Schema validator
   gates dispatch. Codex review at draft time + at impl-diff time.
   Validator runs independently after Implementer + Codex remediation.
2. **The two-axis Material model is now precedent** for similar
   cross-platform vocabulary mismatches: when Apple's role-based identity
   doesn't fit a thickness ranking (or vice versa), surface both axes
   explicitly and document the cross-platform translation in
   `adapter_cardinality` rows.
3. **Phase 5.5 carry-forward items:**
   - Delete the 6 `_legacy_*` AppKit methods (architect-acknowledged dead
     code: `_legacy_tab_view`, `_legacy_alert`, `_legacy_navigation_split_view`,
     `_legacy_toolbar`, `_legacy_sheet`, `_legacy_popover`).
   - Phase 6.5 ships the audit harness that runs the probe placeholders
     for Apple platforms (per-AppleSemantic visual baselines, per-step
     contrast, env-response).
4. **SourceKit stale-index warning ≠ swiftc failure.** Saved to
   feedback memory: `feedback_sourcekit_stale_index.md`.

## Next phase

Phase 6 (Side-by-Side Demo App). Per MASTER_PLAN, Phase 6 depends on
Phase 5's tokenized Material API. With v2 PASS, Phase 6 unblocks.
Phase 6.5 (audit infrastructure) was inserted between 6 and 7 during
the planning retrospective; ordering is 5 → 6 → 6.5 → 7.

**Checkpoint 3 surface to owner:**
- Sign off on Phase 5 v2 PASS
- Tag the passing state (`phase-05-v2-pass`)
- Authorize Phase 6 brief authoring + dispatch
- Confirm Phase 6 brief should be authored against the same schema +
  validator + Codex forcing function used here
