# Phase 10 Scoping v2 — Codex Co-Plan Antagonist Findings

**Date:** 2026-05-25
**Codex:** medium reasoning, default model (gpt-5.5), arg-form prompt.
**Source log:** `/tmp/codex-coplan-10.log` (3058 lines; key verdict at line 2806).
**Verdict:** REVISE.

---

## Bottom line

> Do not commit v2 as-is. The 5-part shape is usable, but the hard serialization and B-family decomposition are load-bearing wrong. v3 should keep 10-pre, but split it into "truth correction" and "API decision protocol," move the spec directory split earlier, carve out bridge/reactivity work explicitly, and stop pretending 10B can be one linear widget bucket.

## HIGH findings (all adopted)

**HIGH-1 — Hard serialization is false.** v2's "no interleaving" rule between 10-pre → 10A → 10B → 10C → 10D is too rigid. Docs will go stale while APIs change; spec directory arriving after 10B means widgets are first written into the wrong structure. **Adopt:** dependency lanes, not strict serial.

**HIGH-2 — 10-pre is over-gated and under-scoped.** Catalog correction blocks coding only for accurate Class A defaults + false Class B claims. Class D prose cleanup does not block bridge skeletons, spec split, or LSP substrate. Also: 10-pre does not settle the rename protocol that will affect every downstream phase. **Adopt:** split 10-pre into 10-pre.1 (factual correction) and 10-pre.2 (API decision protocol + freeze).

**HIGH-3 — B.2 is not one family.** "Class B accessibility surface" mixes static metadata, custom actions, focus management, environment queries, motion, dynamic type, contrast, keyboard access. **Adopt:** split into B.2a (static AX metadata: label, hint, value, traits/grouping), B.2b (action/focus/keyboard: custom actions, focus, full keyboard access), B.2c (environment-driven: reduce motion, dynamic type, contrast, differentiate without color, captions, flashing).

**HIGH-4 — Class C needs bridge substrate before features.** v2 lists bridge skeleton only as R3 mitigation. Six bridges (share, clipboard, URL, files, permissions, print) cannot each invent their own Swift/ObjC/Java shape. **Adopt:** B.3.0 SystemBridge substrate before any Class C feature: Crystal facade namespace, platform capability detection, ObjC/Swift/Java/JNI call conventions, async/error result model, no-op/unsupported behavior, first golden bridge (clipboard or open URL).

**HIGH-5 — Class D rename is too late at B.5.** 10B widget implementation + 10C rules + spec names target unstable names if renames happen at the end. **Adopt:** move catalog ↔ Crystal API rename reconciliation to 10-pre.2 as the explicit API freeze. Renames complete before docs, LSP rule wording, spec names, or Voyager migration.

**HIGH-6 — Reactivity is missing as an invariant.** v2 does not require new widgets or `UI::Intent.resolve` to preserve state-mutation → re-render. **Adopt:** explicit reactivity acceptance gate per `[[reactivity-is-table-stakes]]` memory. `resolve` runs at screen build time, not once at app boot. Rerender after state mutation preserves current platform override. Specs cover override-change-then-rerender.

## MEDIUM findings (all adopted)

**MEDIUM-1 — Docs-first is counterproductive.** Full public docs before widget/API implementation = writing docs for unstable surfaces. **Adopt:** minimal doc scaffolding (e.g. file headers + module summaries) early in 10A.0; final API docs after API freeze (10-pre.2) + after B.2/B.3 shapes land. Split 10A into 10A.0 (early — LSP families 1-3 + skill substrate + minimal docs) and 10A.final (after API freeze — full docs + LSP families 4-5).

**MEDIUM-2 — Voyager 4 screens cannot prove 67 intents.** **Adopt:** companion "intent exerciser" sample app at 10D — generated spec-gallery exercising the remaining 50+ intents Voyager flagship flows don't cover. Voyager exercises ~15 flagship flows; intent exerciser covers the rest.

**MEDIUM-3 — Native compilation matrix is aspirational.** "All 4 platform compile targets pass" assumes iOS/Android compile is already established when neither is verified. **Adopt:** early 10C.0 matrix discovery — exact commands, link flags, expected unsupported cases, CI feasibility, whether iOS/Android are compile-only or simulator-run.

**MEDIUM-4 — Family 5 should not wait entirely until after widgets.** Spec directory conventions affect all widget work. **Adopt:** split Family 5 — `spec_platform_directory_convention` + runner structure land in 10C.0 before 10B; deep rules (`flag_gated_block_requires_platform_spec`, XCUITest/AXTest matching) land in 10A.final after widget examples exist.

## LOW findings (all adopted)

**LOW-1 — Backlog count mismatch.** v2 says 35; `intent-backlog.md` totals 34 (with B-035 present). **Adopt:** reconcile in 10-pre.1.

**LOW-2 — "Class A defaults" wording is muddy.** B.1 mixes `InlineActionRow` creation, capability corrections, Android proper integration. **Adopt:** split B.1 → B.1a (named widget creation), B.1b (capability honesty corrections per the freshness audit), B.1c (Android Material 3 integration).

**LOW-3 — Owner checkpoint only at 10D is risky for UI semantics.** No checkpoint OK but drift invisible. **Adopt:** require internal "golden evidence packets" per sub-phase — capture screenshots, code snippets, before/after, mapped to acceptance gates. Architect reviews each packet at sub-phase close.

## Answers to the 6 v2 open questions

1. **Sub-phase ordering parallelizability:** Partially parallelize per dependency lanes. 10-pre.1 gates catalog-driven widget work. 10C.0 spec split + LSP substrate + bridge investigation can overlap. Do not serialize full docs before APIs stabilize.

2. **Catalog ↔ Crystal API rename protocol:** **Code wins** by default for already-shipped public Crystal APIs unless name is actively misleading or blocks Apple-vocabulary intent mapping. Catalog preserves Apple intent identifiers; `crystal_api_shape` may document Crystal-idiomatic names. Renames require migration notes + Voyager updates in the same slice.

3. **Class B threading strategy:** `UI::View` base carries universal semantic fields (label, hint, value, actions, focus metadata, grouping). Do not dump environment flags as mutable per-view properties. Motion, dynamic type, contrast, captions, flashing, VoiceOver/Switch state live in `UI::Environment` + renderer contracts.

4. **Class C bridge layer:** Yes — unified `UI::System` bridge substrate first. Class C does not start with 9 feature-specific bridges.

5. **Voyager scope at 10D:** 4 screens insufficient. Add companion intent-exerciser sample app. Voyager flagship + intent exerciser together prove the catalog.

6. **Anything else:** Add reactivity contract gate. `UI::Intent.resolve` must be render-time + rerender-safe.

## Sub-phases Codex would add

- `10C.0` early: spec directory split, runner matrix discovery, minimal CI command proof.
- `10-pre.2`: API rename protocol + backlog freeze.
- `10B.3.0`: unified native bridge substrate.
- `10B-reactivity` slice: rerender + state-mutation preservation tests.
- `10D-harness`: Voyager expansion OR generated intent exerciser.

## v3 shape Codex would APPROVE

```
10-pre.1   factual catalog correction
10-pre.2   API rename protocol + backlog/count freeze
10C.0      spec directory split + platform runner discovery
10A.0      LSP Families 1–3 + skill substrate + minimal doc scaffolding
10B.0      Tier 2 resolver, render-time/rerender contract
10B.1a/b/c Class A widget creation + capability honesty + Android integration
10B.2a/b/c accessibility split by semantic risk
10B.3.0    native bridge substrate
10B.3.x    Class C features riding the substrate
10B.4      missing widgets (Menu, FullScreenCover, Inspector, etc.)
10B.5      remaining Class D implementations
10A.final  public docs + LSP Families 4–5 after APIs stabilize
10D        Voyager + intent exerciser + owner hands-on
```

— Architect (Claude Opus 4.7) reconciling Codex co-plan iteration 1
