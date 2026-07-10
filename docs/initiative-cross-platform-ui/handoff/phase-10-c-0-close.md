# Phase 10C.0 — Close handoff

**Date:** 2026-05-25 (iter 1) — updated 2026-05-26 (iter 2 Codex remediation).
**Branch:** `phase-10-c-0` cut from `phase-10`; iter 2 merged `phase-10-a-0a`.
**Status:** Deliverables 1–7 complete. Acceptance gate met modulo 4 pre-existing failures verified against `phase-10` base.

See **§Iter 2 — Codex remediation** at bottom for the post-Codex-BLOCK
forward commits.

---

## Deliverables status

| # | Deliverable | Status | Artifact |
|---|---|---|---|
| 1 | Spec inventory + classification (132 specs) | DONE | `docs/initiative-cross-platform-ui/handoff/phase-10-c-0-spec-inventory.md` |
| 2 | Spec directory reorganization | DONE in 2 batches | Two commits (`d446ba9d`, `b0688743`) |
| 3 | Root Makefile (test-web, test-macos, test-ios, test-android, test-all) | DONE | `Makefile` (94 lines) |
| 4 | Native compile matrix discovery | DONE with documented blockers | `docs/initiative-cross-platform-ui/native-compile-matrix.md` |
| 5 | Family 5 directory-convention rule | DONE; iter 2 wired to runner via `ConventionRule` base class | `src/lsp_rules/family_5_partial/spec_platform_directory_rule.cr` |
| 6 | CI workflow update | DONE; iter 2 added `lint` + split `test-web` Linux/macOS | `.github/workflows/initiative-cross-platform-ui.yml` (12 jobs) |
| 7 | This close handoff | DONE | this file |

---

## Spec move counts (before / after)

| Location | Before reorg | After reorg |
|---|---:|---:|
| `spec/asset_pipeline_spec.cr` | 1 file | moved → `spec/web/asset_pipeline_spec.cr` |
| `spec/spec_helper.cr` | 1 | moved → `spec/web/spec_helper.cr` |
| `spec/asset_pipeline/**` | 19 | moved → `spec/web/asset_pipeline/**` |
| `spec/components/**` | 23 | moved → `spec/web/components/**` |
| `spec/fixtures/**` | 4 | moved → `spec/web/fixtures/**` |
| `spec/import_map/**` | 1 | moved → `spec/web/import_map/**` |
| `spec/scripts/**` | 1 | moved → `spec/web/scripts/**` |
| `spec/support/**` | 6 → 5 web + 1 native | `spec/web/support/**` (5) + `spec/native_macos/support/ax_test_patterns.cr` (1) |
| `spec/ui/**` | 74 → 61 web + 13 native | `spec/web/ui/**` (61) + `spec/native_macos/{ax_test,hig_validation,native,menu_bar}/**` (13) |
| `spec/test_js/` | (non-`.cr` fixtures, untouched) | unchanged |
| **Total `.cr` specs** | **132** | **132** (118 web + 14 native_macos) |

Verified via `find spec -name '*.cr' | wc -l` before and after — 132 both times.

### Regression check

`crystal spec spec/web/` after reorg reports (iter 1):
```
1723 examples, 4 failures, 0 errors, 66 pending
```

After iter-2 phase-10-a-0a merge (which adds 11 lint_conventions examples):
```
1734 examples, 4 failures, 0 errors, 66 pending
```

The 4 failures are **pre-existing on `phase-10` base** — NOT regressions
introduced by the 10C.0 spec move. Proof captured in iter 2:

```
$ git worktree add /tmp/p10-base phase-10
$ cd /tmp/p10-base && crystal spec
# (full spec suite)
1723 examples, 4 failures, 0 errors, 66 pending

Failed examples:
  crystal spec spec/ui/views_spec.cr:3279 # UI::Theme web renderer ...
  crystal spec spec/components/phase2_verification_spec.cr:52 # Phase 2 ...
  crystal spec spec/components/phase2_verification_spec.cr:116 # Phase 2 ...
  crystal spec spec/components/phase2_verification_spec.cr:129 # Phase 2 ...
```

Identical example/failure/pending counts AND identical failing spec
locations (modulo the `spec/web/` path prefix added by the 10C.0
reorg). The 4 failures are tracked outside Phase 10C.0's scope and
will be addressed when the components / theme owner triages them.

**Gate language correction:** the iter-1 close called this "passed"; the
honest framing is "**passed modulo 4 pre-existing failures verified
against phase-10 base.**" The Phase 10C.0 reorg itself introduced zero
new failures.

---

## Per-platform compile matrix status

Full detail in `docs/initiative-cross-platform-ui/native-compile-matrix.md`.

| Platform | Status | Blocker / next owner |
|---|---|---|
| web (`crystal`) | `verified` | None — `make test-web` runs the 118-spec lane. |
| macOS (`acrystal -Dmacos`) | `attempted-blocked` | TWO distinct blockers: (a) spec entries needing `require "../../src/ui"` ahead of `require "../../src/ui/ax_test"` — applied to the 14 native_macos specs during migration; (b) `src/ui/native/objc_collections.cr` declares `lib LibCollectionBridge` `fun`s whose C implementation (`collection_bridge.c`/`.m`) is NOT in the repo, so `make test-macos` link fails with ~40 undefined symbols. Sample apps under `samples/cross_platform/macos_host/` link OK today, suggesting the bridge lives in downstream sample sources. Deferred to a follow-up native-runner phase. |
| iOS (`acrystal -Dios`) | `attempted-blocked` | `acrystal build --target=arm64-apple-ios18.0 -Dios` link step pulls macOS-built `libgc.dylib`. Repo's iOS path uses `--cross-compile` + `libcascade.a` + Xcode (`samples/initiative-cross-platform-ui-demo/ios/build_crystal_lib.sh`), not standalone `acrystal spec`. Deferred to 10D. |
| Android (`acrystal -Dandroid`) | `attempted-blocked` | `acrystal build -Dandroid` fails on `require "c/sys/epoll"` — `agent-crystal` Homebrew tap installs macOS-targeted stdlib only. Needs Linux Crystal + NDK. Deferred to 10D. |

---

## Family 5 rule status (post iter-2)

- File: `src/lsp_rules/family_5_partial/spec_platform_directory_rule.cr` (renamed iter 2 to match runner's `*_rule.cr` auto-discovery glob).
- Compiles: yes (`crystal build --no-codegen` exit 0).
- **Extends `ConventionRule`** (iter 2). Auto-registered via the `inherited` macro hook.
- Auto-discovered + loaded by `scripts/lint_conventions.cr` (the runner shipped with 10A.0a, merged in iter 2).
- Functional probe: `crystal run scripts/lint_conventions.cr` runs all 6 rules (5 Family 1 + 1 Family 5) over 435 files → 0 diagnostics. Probe captured during implementation.
- Diagnostic format: uses the shared `Diagnostic` struct from `src/lsp_rules/convention_rule.cr` (the iter-1 local `ConventionDiagnostic` shim was dropped in iter 2).
- Tests: a Family 5 regression fixture-spec is deferred to 10A.final (alongside Family 2/3 rule expansions). 10A.0a's `spec/web/lint_conventions/family_1_naming_spec.cr` is the template the Family 5 fixture-spec will follow.

---

## CI workflow changes

`.github/workflows/initiative-cross-platform-ui.yml` gains four new jobs ahead of the existing demo/audit jobs:

| Job | Runner | continue-on-error | Notes |
|---|---|---|---|
| `test-web` (iter 1) | macos-14 | false | `make test-web`. Iter-2 split into `test-web-linux` + `test-web-macos` per brief §4 line 141. |
| `test-macos` | macos-14 | **true** | `make test-macos`. Matrix says `attempted-blocked` — non-fatal until C bridge ships. |
| `test-ios` | macos-14 | **true** | `make test-ios` (placeholder echo). |
| `test-android` | ubuntu-latest | **true** | `make test-android` (placeholder echo). |

**Iter 2 update:** workflow now has 12 jobs (added `lint` + split `test-web` Linux/macOS); see §Iter 2 → Finding 3 for the post-iter-2 table.

The existing demo + visual-audit jobs (build-web, build-macos, build-ios, audit-web, audit-macos, audit-ios) are unchanged.

---

## Anything blocking 10A.0a / 10B.0 / 10A.0b

- **10A.0a (Crystal-side runner + Family 1):** ✅ MERGED INTO `phase-10-c-0` in iter 2. The runner + base class + 5 Family 1 rules now ship together with the Family 5 rule.
- **10A.0b (Family 2 view-spec pair):** unblocked by this close. `spec/web/` and `spec/native_macos/` directories exist; the spec-pair rule can be authored against them.
- **10A.0c (Family 3 architectural):** unblocked. Runs after 10A.0a (now merged).
- **10B.0 (Tier 2 intent resolver):** specs land in `spec/ui/intent_spec.cr` (its own branch's current tree) per Decision 4. 10C.0 will need a follow-up migration commit on whichever branch lands second — trivial `git mv` + path-edit task tracked here. When 10B.0 merges, the Family 5 rule will flag any spec it adds outside `spec/web/` / `spec/native_X/`.

---

## Branch HEAD SHA

After Deliverable 7 close commit lands. Commits on `phase-10-c-0` from `phase-10`:

```
<sha-of-close-commit>  [Phase 10C.0 close] Implementer handoff
<sha-of-ci-commit>     [Phase 10C.0] CI workflow update + Family 5 rule + Makefile
b0688743               [Phase 10C.0] Move 118 web specs (Deliverable 2 batch 2/N)
d446ba9d               [Phase 10C.0] Move 14 native_macos specs (Deliverable 2 batch 1/N)
12e59cc3               [Phase 10C.0] Native compile matrix (Deliverable 4)
9f6ce521               [Phase 10C.0] Spec inventory + classification (132 specs)
f40f247e               [Phase 10] Parallel-trio briefs v2 + architecture-decisions.md  ← phase-10 base
```

---

## Acceptance gate check

- ✅ All 132 specs accounted for + moved (verified via `find spec -name '*.cr' | wc -l`).
- ✅ `crystal spec spec/web/` passes modulo 4 pre-existing failures verified against `phase-10` base (iter 2 — see Regression check section).
- ⚠️ `make test-macos` documented blocker (collection_bridge.c missing) — matrix doc captures.
- ✅ Native compile matrix doc has 3 status entries (macOS / iOS / Android) with command + outcome.
- ✅ Root Makefile exists with all 5 targets (test-web, test-macos, test-ios, test-android, test-all) + new `lint` target (iter 2).
- ✅ `objc_bridge.o` build dependency wired (Makefile target `$(AP_BRIDGE_OBJ)` — renamed in iter 2 per brief §4 line 84).
- ✅ Family 5 rule file exists + compiles. **Iter 2:** rule now extends `ConventionRule` per brief §4 line 133; auto-discovered by `scripts/lint_conventions.cr` (6 rules loaded, 0 diagnostics on full repo).
- ✅ CI workflow runs available platforms. **Iter 2:** 12 jobs total (added `lint` + split `test-web` into Linux + macOS lanes per brief §4 lines 141-144).

---

## Iter 2 — Codex remediation (2026-05-26)

Codex content review on the iter-1 close handoff returned **BLOCK**
with 4 findings + 2 notes. Iter 2 remediates as forward commits.

### Iter 2 commits (chronological)

| SHA | Subject | Addresses |
|---|---|---|
| `e280d659` | Merge phase-10-a-0a — convention runner + ConventionRule base + Family 1 rules | Finding 2 prerequisite (Option A — recommended path) |
| `ddd69692` | Move spec/lint_conventions/ into spec/web/ per Family 5 | merge-import classification (Family 5 compliance) |
| `8dacdfce` | Finding 2: SpecPlatformDirectoryRule extends ConventionRule | Finding 2 |
| `1ea28a57` | Findings 3 + note: CI Linux + lint jobs; AP_BRIDGE_OBJ rename | Finding 3 + small fix |
| `0a784515` | Finding 4 + notes: inventory fidelity + empty native dirs | Finding 4 + small fix |
| (this commit) | iter-2 close update | handoff narrative |

### Finding 1 — `crystal spec spec/web/` failures

**Status:** resolved as documented pre-existing.

Investigation: ran `crystal spec spec/web/` on `phase-10-c-0` → 1734
examples, 4 failures (1723 + 11 from the 10A.0a merge). Ran `crystal spec`
on a clean `phase-10` worktree → 1723 examples, 4 failures, identical
spec locations + identical failure modes (modulo the `spec/web/`
prefix added by the 10C.0 reorg).

**Failing specs (all pre-existing on phase-10 base):**

| Failing spec | Pre-existing on phase-10? |
|---|---|
| `spec/web/ui/views_spec.cr:3279` — `UI::Theme web renderer inject_theme_css returns empty string with no theme` | YES (was at `spec/ui/views_spec.cr:3279`) |
| `spec/web/components/phase2_verification_spec.cr:52` — `demonstrates component composition` | YES (was at `spec/components/phase2_verification_spec.cr:52`) |
| `spec/web/components/phase2_verification_spec.cr:116` — `components can be nested within components` | YES (was at `spec/components/phase2_verification_spec.cr:116`) |
| `spec/web/components/phase2_verification_spec.cr:129` — `achieves the component system goals` | YES (was at `spec/components/phase2_verification_spec.cr:129`) |

Repro on phase-10 (run in iter 2 to gather proof):

```
$ git worktree add /tmp/p10-base phase-10
$ cd /tmp/p10-base && crystal spec
...
1723 examples, 4 failures, 0 errors, 66 pending

Failed examples:
crystal spec spec/ui/views_spec.cr:3279 # UI::Theme web renderer ...
crystal spec spec/components/phase2_verification_spec.cr:52 # ...
crystal spec spec/components/phase2_verification_spec.cr:116 # ...
crystal spec spec/components/phase2_verification_spec.cr:129 # ...
```

Phase 10C.0 introduced ZERO new failures. The reorg is regression-clean.
The 4 baseline failures are owner-triage items belonging to the
component-system / theme owners — not part of 10C.0's scope.

### Finding 2 — Family 5 rule must extend `ConventionRule`

**Status:** resolved (Option A — merge `phase-10-a-0a`).

Chose Option A from the iter-2 prompt: merged `phase-10-a-0a` (tag
`phase-10-a-0a-pass-2026-05-26`, HEAD `f88f500d`) into `phase-10-c-0`
via `git merge phase-10-a-0a --no-ff`. The merge had no conflicts and
brought in:

* `src/lsp_rules/convention_rule.cr` (ConventionRule base, Diagnostic,
  ConventionConfig).
* `scripts/lint_conventions.cr` (runner with auto-discovery via
  `find . -type f -name "*_rule.cr"`).
* `src/lsp_rules/family_1_naming/*_rule.cr` (5 Family 1 rules).
* `.lint_conventions.yml` (runner config).
* `.claude/skills/asset_pipeline--lint-conventions/SKILL.md`.

Then in commit `8dacdfce` the Family 5 rule:

* Renamed: `spec_platform_directory_convention.cr` →
  `spec_platform_directory_rule.cr` (matches the runner's
  `*_rule.cr` auto-discovery glob).
* Rewrote: `class SpecPlatformDirectoryConvention` →
  `class SpecPlatformDirectoryRule < ConventionRule`.
* Dropped: the local `ConventionDiagnostic` shim — now uses the shared
  `Diagnostic` struct from `src/lsp_rules/convention_rule.cr`.
* Implements `rule_name : String` + `check(file_path, content)` per
  the abstract base contract.
* Auto-registered via `ConventionRule.inherited`.

Verification:

```
$ crystal run scripts/lint_conventions.cr
lint_conventions: OK (435 files, 6 rules, 0 diagnostics)
```

(6 rules = 5 Family 1 + 1 Family 5; up from 5 before the merge.)

### Finding 3 — CI workflow incomplete

**Status:** resolved.

Workflow at `.github/workflows/initiative-cross-platform-ui.yml` now has
12 jobs (up from 10):

| Job | Runner | continue-on-error | What it does |
|---|---|---|---|
| **`lint`** (NEW) | ubuntu-latest | false | `make lint` → `crystal run scripts/lint_conventions.cr` |
| **`test-web-linux`** (NEW) | ubuntu-latest | false | `make test-web` (brief's intent of "Linux/web job") |
| **`test-web-macos`** (renamed) | macos-14 | false | `make test-web` (Makefile / BSD-make compat check on macOS) |
| `test-macos` | macos-14 | true | `make test-macos` — still `attempted-blocked` per matrix |
| `test-ios` | macos-14 | true | `make test-ios` (placeholder echo) |
| `test-android` | ubuntu-latest | true | `make test-android` (placeholder echo) |
| `build-web` | macos-14 | false | unchanged |
| `build-macos` | macos-14 | false | unchanged |
| `build-ios` | macos-14 | false | unchanged |
| `audit-web` | macos-14 | false | unchanged |
| `audit-macos` | macos-14 | false | unchanged |
| `audit-ios` | macos-14 | false | unchanged |

The lint job is enabled now (not commented as future-work) because
`phase-10-a-0a` is merged in.

### Finding 4 — D1 inventory fidelity gap

**Status:** resolved (category-level honesty + spec_helper clarification).

Inventory rewrite at `docs/initiative-cross-platform-ui/handoff/phase-10-c-0-spec-inventory.md`:

* **117 web specs** classified at category level (Decision 5 allows
  this where the category is unambiguous). Added an explicit
  category-breakdown table (24 asset_pipeline + 24 components +
  4 fixtures + 1 import_map + 1 scripts + 5 support + 61 ui +
  1 top-level smoke = 117). Per-row was rejected as noise — every
  row would say the same predicate. The doc is honest about the
  choice.
* **14 macOS specs** kept per-row rationale; expanded prose to
  state each row's distinct runtime dependency.
* **`spec/spec_helper.cr` contradiction** resolved. iter-1 inventory
  was wrong ("stays at root"); iter-1 close handoff was right ("moved
  to spec/web/"). Verified via `git ls-files spec/spec_helper.cr
  spec/web/spec_helper.cr` → only `spec/web/spec_helper.cr` exists.
  Updated inventory + added explicit clarification section that the
  Family 5 rule keeps `spec/spec_helper.cr` in its allowed-root list
  as a forward-compat slot even though no file is committed at that
  path today.
* Added a Reconciliation section documenting the +8 files from the
  phase-10-a-0a merge (1 lint_conventions spec + 7 fixtures, all moved
  into `spec/web/lint_conventions/`).

### Notes (small fixes)

* `spec/native_ios/` and `spec/native_android/` directories created with
  `.gitkeep` + `README.md` each. READMEs document status (`attempted-blocked`
  per matrix), classification rule, Family 5 allowed status, expected
  next landings.
* `Makefile` variable `AP_BRIDGE` → `AP_BRIDGE_OBJ` and `SK_BRIDGE` →
  `SK_BRIDGE_OBJ` per brief §4 line 84-85. `clean-bridges` target
  output adjusted.

### Iter-2 final verification

```
$ crystal spec spec/web/
1734 examples, 4 failures, 0 errors, 66 pending
# 4 failures = same 4 pre-existing on phase-10. Reorg is regression-clean.

$ make test-web
# same — exit 1 due to the 4 pre-existing.

$ make test-macos
# attempted-blocked at link step: ~40 undefined collection_bridge
# symbols (documented in native-compile-matrix.md). Exit 1.

$ make lint
lint_conventions: OK (435 files, 6 rules, 0 diagnostics)

$ crystal run scripts/lint_conventions.cr
lint_conventions: OK (435 files, 6 rules, 0 diagnostics)
```

### Iter-2 branch HEAD SHA

Final commit on `phase-10-c-0`:

```
ef03ea76              [Phase 10C.0 iter 2 close] Codex remediation: 4 findings + 2 notes
0a784515              [Phase 10C.0 iter 2] Finding 4 + notes: inventory fidelity + empty native dirs
1ea28a57              [Phase 10C.0 iter 2] Findings 3 + note: CI Linux + lint jobs; AP_BRIDGE_OBJ rename
8dacdfce              [Phase 10C.0 iter 2] Finding 2: SpecPlatformDirectoryRule extends ConventionRule
ddd69692              [Phase 10C.0 iter 2] Move spec/lint_conventions/ into spec/web/ per Family 5
e280d659              [Phase 10C.0 iter 2] Merge phase-10-a-0a — convention runner + ConventionRule base + Family 1 rules
b3576bb7              [Phase 10C.0 close] Makefile + Family 5 rule + CI + handoff (Deliverables 3, 5, 6, 7)  ← iter-1 close
b0688743              [Phase 10C.0] Move 118 web specs (Deliverable 2 batch 2/N)
d446ba9d              [Phase 10C.0] Move 14 native_macos specs (Deliverable 2 batch 1/N)
12e59cc3              [Phase 10C.0] Native compile matrix (Deliverable 4)
9f6ce521              [Phase 10C.0] Spec inventory + classification (132 specs)
f40f247e              [Phase 10] Parallel-trio briefs v2 + architecture-decisions.md  ← phase-10 base
```

---

## Codex content review

iter-1: BLOCK (4 findings + 2 notes). iter-2 remediation above.
iter-2: pending architect re-trigger of `codex_hig_review.sh`
equivalent for content review.

— Implementer (Phase 10C.0), 2026-05-25 (iter 1), 2026-05-26 (iter 2)
