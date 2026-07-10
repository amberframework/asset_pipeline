# Phase 6.11 — Codex Review 1 (Iteration 1)

**Date:** 2026-05-23
**Iteration scope:** Item 1 — Drop Voyager brand override.

## Diff scope

- Delete `samples/initiative-cross-platform-ui-voyager/brand.cr`.
- Remove `require "./brand"` from `samples/.../app.cr` and the inline
  `PHASE 6.10 REM 2 TEMP` interaction-proof helper (LibVoyagerInteractionLog
  / `Voyager.log_interaction`).
- Strip `Voyager.brand_tokens` assignments from `macos/host.cr`,
  `ios/bridge.cr`, and `web/static_site.cr` — replace with comments noting
  that the renderer carries `UI::DesignTokens::Tokens.default` already.
- Remove every `Voyager.log_interaction("…")` call from `screens/*.cr`.
- Replace `renderer.design_tokens = Voyager.brand_tokens` in
  `spec/ui/voyager_state_propagation_spec.cr` with an explanatory comment.

## Acceptance evidence

1. `samples/.../brand.cr` removed — git records `D`.
2. `grep -rE "VoyagerBrand|with_brand|brand\.cr" samples/initiative-cross-platform-ui-voyager/` → 0 hits (exit 1).
3. `grep -rE "Color\.hex|OKLCH\(0\.42|#[0-9a-fA-F]{6}" samples/initiative-cross-platform-ui-voyager/screens/ samples/initiative-cross-platform-ui-voyager/app.cr` → 0 hits (exit 1).
4. `grep -rE "voyager-(save-chain|interaction-proof)" samples/ src/` → 0 hits (exit 1).
5. `crystal spec` → 1497/4/0 baseline preserved.
6. `make ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'` → `** BUILD SUCCEEDED **`.

## Codex verdict

**Initial verdict:** NEEDS_WORK — Codex's `grep` against the working tree
caught two stale untracked artifacts (`macos/bin/voyager` and
`macos/bin/voyager.dwarf`) that still contained the literal `VoyagerBrand`
string from a prior 6.10 build. The brief's acceptance is "grep returns 0
hits in **tracked source**", and the stale binaries were not under git
control, but they tripped the literal command. Implementer cleared
`samples/.../macos/bin/` before commit so the working tree itself is now
clean.

**Post-cleanup verdict:** PASS for Item 1.

- Source-level Item 1 work complete: `brand.cr` deleted, every
  `VoyagerBrand` / `with_brand` / `brand_tokens` reference removed, no
  inline color literals introduced as replacements.
- `crystal spec` regression check passes (1497/4/0 unchanged).
- iOS build unaffected — `make ios` exits 0.

## Codex invocation

```bash
codex exec --skip-git-repo-check "Review this iteration against ...phase-06.11.../brief.md Item 1 ..."
```

Approx 71k tokens consumed; ~30s. Full Codex output preserved by Implementer
in the iteration commit message.
