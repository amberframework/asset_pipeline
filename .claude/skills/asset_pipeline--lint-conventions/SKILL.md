---
name: asset_pipeline--lint-conventions
description: Run the asset_pipeline convention linter (`scripts/lint_conventions.cr`) — Crystal-side runner that enforces Phase 10 Family 1 naming rules across src/, samples/, and spec/. Use before commit, in CI, or when reviewing a PR.
---

# asset_pipeline — Convention Linter

Convention enforcement for asset_pipeline ships as a Crystal-side
runner, not as an AmberLSP extension. The runner walks the repo,
applies every registered rule, and exits non-zero on violations so
CI and pre-commit hooks can gate.

## When to use
- Before committing on a feature branch.
- In CI as a fast pre-build gate.
- During PR review when you suspect naming drift.
- When you add a new screen, controller, or view subclass.

## Invocation

```bash
crystal run scripts/lint_conventions.cr
```

Exit codes:
- `0` — no diagnostics.
- `1` — one or more diagnostics emitted (printed to stdout).
- `2` — bad CLI arguments.

Output line format:
```
<file>:<line>: [<rule_name>] <message> (suggested: <fix>)
```

## Useful options

```bash
# Limit to one rule family
crystal run scripts/lint_conventions.cr -- --rules=family_1

# Scan only a subset of paths
crystal run scripts/lint_conventions.cr -- --no-default-paths --paths=src/ui/views

# Machine-friendly mode (currently identical to human; reserved for future structured output)
crystal run scripts/lint_conventions.cr -- --format=machine
```

Default scan roots: `src/`, `samples/`, `spec/`. Always-excluded:
`lib/`, `.crystal-cache/`, and `spec/fixtures/` (test fixtures
intentionally exercise malformed shapes).

## Suppression

Add `# lint:disable=<rule_name>` on its own line near the top of a
file to suppress that rule across the whole file. Multiple rules can
be listed comma-separated. `# lint:disable=all` disables every rule
for the file. Use sparingly; prefer fixing the violation.

## Rule families

### Family 1 — naming (this sub-phase)
Five regex-based rules covering screen/controller/view naming:

| Rule name | What it checks |
|---|---|
| `family_1/screen_class_naming` | Every `< UI::Screen` subclass name ends in `Screen`. |
| `family_1/screen_file_suffix` | Files declaring a `< UI::Screen` subclass use the matching `foo_screen.cr` basename. |
| `family_1/controller_class_naming` | Every `< UI::Controller` subclass name ends in `Controller`. |
| `family_1/controller_file_suffix` | Files declaring a `< UI::Controller` subclass use the matching `foo_controller.cr` basename. |
| `family_1/view_subclass_under_views_dir` | `UI::View` subclasses live under `src/ui/views/` or `samples/`. |

### Family 2 — view-spec pair (deferred to 10A.0b)
### Family 3 — architectural (deferred to 10A.0c)
### Family 4 — test_id hygiene (deferred to 10A.final)
### Family 5 — directory + multi-target (10C.0 + 10A.final)

## Adding a new rule

Rules are **auto-discovered**. Drop a file and ship — no runner edit
required.

1. Create the rule file under `src/lsp_rules/family_<N>_<topic>/<name>_rule.cr`.
2. Subclass `ConventionRule` and implement `rule_name : String` +
   `check(file_path, content) : Array(Diagnostic)`. (Optional:
   override `configure(config : ConventionConfig)` to receive runtime
   config.)
3. The class auto-registers via `ConventionRule.inherited`, and the
   runner auto-requires every `*_rule.cr` under `src/lsp_rules/` via a
   compile-time `find` macro expansion.
4. Run `crystal run scripts/lint_conventions.cr` and confirm the rule
   count went up by one and the run is green on `src/` + `samples/`.
5. Manually break a file; confirm red on injection.
6. Add a SKILL.md row in the appropriate Family table.

To verify auto-discovery, drop a stub rule file in any
`src/lsp_rules/family_N_*/` directory, re-run the linter, observe the
rule count increment, then delete the file.

## Configurable allowlists

Some rules read a config file at the repo root:

- `.lint_conventions.yml` — flat YAML with sectioned keys.

Currently supported keys:

```yaml
view_subclass:
  approved_roots:
    - "src/ui/views/"
    - "samples/"
```

If the config file is missing, defaults apply. Pass `--config=<path>`
to override the location.

## Regression fixtures

Known false-positive cases are pinned as fixtures under
`spec/lint_conventions/fixtures/`. A fixture file is a single `.cr`
file with a comment header naming the expected outcome (pass or fail
with which rule). The optional spec at
`spec/lint_conventions/family_1_naming_spec.cr` exercises each rule
against the fixtures to lock in current behavior.

## CI integration

```yaml
- name: Convention lint
  run: crystal run scripts/lint_conventions.cr
```

## Pre-commit hook

```bash
#!/usr/bin/env bash
set -e
crystal run scripts/lint_conventions.cr --quiet
```

## Distribution

The skill ships in `asset_pipeline`'s `.claude/skills/`. Per the
shards AI-docs auto-detection rule, consumers receive the skill
installed under their `.claude/skills/asset_pipeline--<skill_name>/`
namespace. Because this skill's source dir is already prefixed with
`asset_pipeline--` (matching the brief), shards installs it under a
doubly-prefixed path. See the `phase-10-a-0a-close.md` handoff.

## Why a Crystal runner instead of AmberLSP?

AmberLSP's `CustomRule` is YAML-regex-only and has no Crystal
compiled rule loader. Per the Phase 10 architecture decision
(2026-05-25), convention rules ship as a Crystal program. Rule
classes live under `src/lsp_rules/` so they port directly if AmberLSP
later grows the loader.
