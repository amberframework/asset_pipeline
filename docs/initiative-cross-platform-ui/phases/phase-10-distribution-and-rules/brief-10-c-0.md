# Phase 10C.0 — Spec Directory Split + Runner Matrix + Family 5 Directory Rule (v2)

**Sub-phase:** 10C.0 — establish multi-target spec structure + native compile matrix.
**Branch:** `phase-10-c-0` cut from `phase-10`.
**Status:** v2 — replaces v1 after Codex REVISE (3 HIGH + 4 MEDIUM + 2 LOW); architectural pin-downs in architecture-decisions.md Decision 5.
**Predecessor:** 10-pre.2 closed. Parallel with 10B.0 + 10A.0a.

---

## Critical context

Per **architecture-decisions.md Decision 5** + Codex 10C.0 findings:

- **132 specs in the repo** (not ~20). 129 contain relative `require` paths.
- **Family 5 directory rule ships as a Crystal-side rule** under the runner mechanism 10A.0a establishes (Decision 1), NOT as an AmberLSP plugin.
- **Native compile matrix is best-effort with documented blockers**, not "fix iOS/Android."
- **Root `Makefile` creation in scope** — repo currently has only sample Makefiles.
- **`objc_bridge.o` lifecycle in scope** — `make test-macos` depends on compiling `.m` to `.o`.

## 1. What you are doing

Reorganize 132 specs into platform-aware directories. Build per-platform test runners (root Makefile). Discover the actual state of the native compile matrix. Ship the Family 5 directory-convention rule (loaded by 10A.0a's runner). After 10C.0 closes:

- `spec/web/` (default; runs with `crystal spec`).
- `spec/native_macos/` (runs with `crystal-alpha`/`acrystal` + `-Dmacos` + ObjC bridge link flags).
- `spec/native_ios/` (best-effort; documented if broken).
- `spec/native_android/` (best-effort; documented if broken).
- Root `Makefile` with `test-web`, `test-macos`, `test-ios`, `test-android`, `test-all` targets.
- `docs/initiative-cross-platform-ui/native-compile-matrix.md` — per-platform status doc.
- `src/lsp_rules/family_5_partial/spec_platform_directory_convention.cr` — Crystal rule class loaded by 10A.0a's runner.
- CI workflow updated.

## 2. Read first

1. `docs/initiative-cross-platform-ui/phases/phase-10-distribution-and-rules/architecture-decisions.md` — **authoritative**.
2. Current spec inventory: `find spec -name '*.cr' | wc -l` (expected: 132).
3. Sample Makefiles under `samples/` for the existing ObjC bridge compile pattern.
4. CLAUDE.md Build & Test + Native App Development Workflow sections for link flag references.
5. `[[project_platform_minimums]]` memory — macOS 14+, iOS 16+, Phase 4 deployment targets.
6. `[[reference_agent_crystal]]` memory — `acrystal` from `crimson-knight/homebrew-agent-crystal` (formerly `crystal-alpha`).
7. `.github/workflows/initiative-cross-platform-ui.yml` — current CI.

## 3. Constraints (Hard Rules)

- Forward commits only on `phase-10-c-0`.
- **129 specs with relative `require` paths** must be grep'd + updated atomically after each `git mv` batch. Verify with `crystal spec spec/web/` (default tree first).
- **No spec deletions** — only moves. Every existing spec ends up in the new tree OR architect-documented as orphan.
- **Don't break existing tests.** `crystal spec` must pass after moves on the default web subset.
- Native iOS/Android: **document, don't repair.** If broken, record `attempted-blocked` status with exact command + first error.
- Family 5 directory rule extends 10A.0a's `ConventionRule` base class (NOT `AmberLSP::Rules::BaseRule`).
- `[[codex-as-architect-antagonist]]` + `[[audit-scope-discipline]]` apply.

## 4. Deliverables

### Deliverable 1 — Spec inventory + classification

Write `docs/initiative-cross-platform-ui/handoff/phase-10-c-0-spec-inventory.md`:

For all 132 specs:
- Current path.
- Target path (`spec/web/`, `spec/native_macos/`, `spec/native_ios/`, `spec/native_android/`).
- Classification rationale per the rule in architecture-decisions.md Decision 5:
  - Classify by **deepest platform dependency**, not just flags in the spec file.
  - If spec exercises a platform-gated view/renderer path, place in platform dir UNLESS it uses fakes/stubs.
  - Multi-platform contract specs stay in `spec/web/` only if they pass under plain `crystal spec` without native link flags.

Architect reviews the inventory before bulk moves.

### Deliverable 2 — Spec directory reorganization

For each of the 132 specs:
1. `git mv` to target directory.
2. `grep -l "require_relative\|require \".\\./\"" <new_path>` to find relative requires.
3. Update relative paths to new locations.
4. `crystal spec <new_path>` to verify the spec still parses/runs.

Batches: 10-15 specs at a time per commit. After each batch, run `crystal spec spec/web/` to verify no regression.

### Deliverable 3 — Root `Makefile`

Create `Makefile` at repo root:

```makefile
AP_BRIDGE_OBJ = lib/asset_pipeline/src/ui/native/objc_bridge.o
AP_BRIDGE_SRC = src/ui/native/objc_bridge.m

$(AP_BRIDGE_OBJ): $(AP_BRIDGE_SRC)
	clang -c $(AP_BRIDGE_SRC) -o $(AP_BRIDGE_OBJ) -fno-objc-arc

test-web:
	crystal spec spec/web/

test-macos: $(AP_BRIDGE_OBJ)
	acrystal spec spec/native_macos/ -Dmacos --link-flags="$(AP_BRIDGE_OBJ) -framework AppKit -framework Foundation -lobjc"

test-ios:
	@echo "iOS: see docs/initiative-cross-platform-ui/native-compile-matrix.md"
	# Implementation depends on Deliverable 4 findings.

test-android:
	@echo "Android: see docs/initiative-cross-platform-ui/native-compile-matrix.md"
	# Implementation depends on Deliverable 4 findings.

test-all: test-web test-macos
	@echo "iOS/Android: see native-compile-matrix.md"
```

Adjust details based on Deliverable 4 outcomes.

### Deliverable 4 — Native compile matrix discovery

Write `docs/initiative-cross-platform-ui/native-compile-matrix.md`:

For each platform (macOS, iOS, Android), one of three statuses:
- `verified` — command runs end-to-end; document the canonical command.
- `attempted-blocked` — first actionable error + next remediation owner.
- `deferred-not-attempted` — explicit "not run; deferred to <phase>" rationale.

Required per-platform fields:
- Exact build/spec command (canonical).
- Required link flags + framework dependencies.
- Crystal compiler version + path (`acrystal` per `[[reference_agent_crystal]]`; alias to `crystal-alpha` if local install uses old name).
- SDK assumptions (Xcode version, Android NDK version).
- Whether builds work TODAY (run the command; report).
- CI feasibility: runner type + cost concern.

**Best-effort:** actually run the commands. Document what happens. If iOS breaks at link step due to missing Xcode SDK, that's `attempted-blocked` with that error. NOT a 10C.0 blocker.

### Deliverable 5 — Family 5 directory-convention rule

`src/lsp_rules/family_5_partial/spec_platform_directory_convention.cr`:

Extends 10A.0a's `ConventionRule` base class. Rule: every spec file under `spec/` must live in `spec/web/`, `spec/native_<X>/`, OR be the helper file (`spec/spec_helper.cr`). Diagnostic format matches 10A.0a's runner expectations.

**Coordination with 10A.0a:** if 10A.0a hasn't merged when 10C.0 runs, the rule file exists but isn't loaded yet. Close handoff documents the dependency.

### Deliverable 6 — CI workflow update

`.github/workflows/initiative-cross-platform-ui.yml`:
- macOS job runs `make test-macos` (existing macos-14 runner).
- Linux/web job runs `make test-web` (existing setup).
- iOS job: `continue-on-error: true` initially; expand per Deliverable 4 findings.
- Android job: `continue-on-error: true` initially; uses `ubuntu-latest` + Android SDK setup OR skipped per findings.
- Lint job: `crystal run scripts/lint_conventions.cr` (10A.0a's runner; coordinate timing).

### Deliverable 7 — Close handoff

`docs/initiative-cross-platform-ui/handoff/phase-10-c-0-close.md`:
- Spec inventory: 132 specs classified; before/after path table.
- Per-platform compile matrix status (table per Deliverable 4).
- New Family 5 rule file shipped (coordination with 10A.0a noted).
- CI workflow changes.
- Anything blocking 10B.0 / 10A.0 dispatch (coordination notes).
- Codex content review verdict.

## 5. Workflow

1. `git checkout -b phase-10-c-0 phase-10`.
2. Inventory + classification (Deliverable 1). Commit.
3. Native compile matrix discovery (Deliverable 4) — RUN the commands; document. Commit.
4. Apply spec moves in batches (Deliverable 2). After each batch: `crystal spec spec/web/` passes. Commit per batch.
5. Root Makefile (Deliverable 3). Commit.
6. Family 5 rule file (Deliverable 5). Commit.
7. CI workflow update (Deliverable 6). Commit.
8. Close handoff (Deliverable 7).
9. Standard footer.

## 6. Acceptance gate

- ✅ All 132 specs accounted for + moved.
- ✅ `crystal spec spec/web/` passes (same test count as before reorg).
- ✅ `make test-macos` passes OR has documented blocker.
- ✅ Native compile matrix doc has 3 status entries (macOS, iOS, Android) with command + outcome.
- ✅ Root Makefile exists with all 5 targets.
- ✅ `objc_bridge.o` build dependency wired.
- ✅ Family 5 rule file exists + compiles + integrates with 10A.0a's runner (or coord note if 10A.0a not merged).
- ✅ CI workflow runs available platforms.
- ✅ Codex content review APPROVE.

## 7. Out of scope

- Fixing broken iOS/Android compile (best-effort report only).
- Family 5 deep rules (10A.final).
- AmberLSP integration (out of scope per Decision 1).
- Widget implementation.
- Catalog edits.
- Owner involvement.

— Architect (Claude Opus 4.7), 10C.0 brief v2 (post-Codex + architecture-decisions.md)
