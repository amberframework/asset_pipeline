# Codex external review protocol

## Purpose

Use Codex as an independent outside reviewer in the HIG validation loop. This is
not a replacement for the builder or design-critic. It is a second opinion that
checks evidence freshness, screen-recipe fit, default taste, implementation
legitimacy, and whether the current screenshots support the claimed verdict.

This protocol is intended for build-in-public work: every review writes a
structured JSON artifact that can be summarized in progress logs or PR notes.

## When to call Codex

Call Codex after the builder has:

1. Implemented or changed the slug.
2. Regenerated all required screenshots.
3. Regenerated the validation report.
4. Run `audit_evidence.py --slug <slug> --write-manifest`.

For P0 slugs and any slug the builder wants to mark `pass` or
`pass_with_notes`, Codex review is blocking. If Codex returns
`NEEDS_WORK` or `INSUFFICIENT_EVIDENCE`, the row stays pending until the
builder fixes or explicitly rebuts the finding with current screenshot
evidence.

## Command

From the repo root:

```bash
scripts/codex_hig_review.sh <slug>
```

The script writes:

```text
.claude/skills/apple-platform-guide/validation/codex-reviews/<slug>.json
```

The output matches:

```text
.claude/skills/apple-platform-guide/validation/codex-review.schema.json
```

Set a model explicitly if needed:

```bash
CODEX_MODEL=gpt-5.4 scripts/codex_hig_review.sh <slug>
```

Set a Codex binary explicitly if the other agent does not have `codex` on PATH:

```bash
CODEX_BIN=/Applications/Codex.app/Contents/Resources/codex scripts/codex_hig_review.sh <slug>
```

## What Codex checks

Codex reads the worklist row, report, evidence manifest, HIG page, attached
screenshots, preview composition rules, preview screen recipes, Amber brand
contract, and design-critic rules.

Codex must fail or block when:

- Required screenshots are missing, stale, unreadable, all-black, or newer than
  the report.
- The report describes pixels that are not visible in the current captures.
- The chosen preview uses the wrong screen recipe.
- Raw system blue/red appears as primary/destructive action color without a
  named native-control exception.
- Palette roles, alignment rails, component anatomy, or HIG state are unclear.
- A glass-required surface does not show visible backdrop bleed-through.
- A target-platform native component is skipped instead of implemented or left
  pending as an implementation gap.
- A platform N/A card is treated as a visual pass.

## How the builder should respond

If Codex returns `PASS` or `PASS_WITH_NOTES`, continue to design-critic review.

If Codex returns `INSUFFICIENT_EVIDENCE`, regenerate screenshots, report, and
manifest before asking any taste reviewer to grade the slug.

If Codex returns `NEEDS_WORK`, fix the listed findings and re-run the slug. Do
not bury the finding in notes or move the worklist row to a terminal state.

If Codex returns `PLATFORM_N_A`, record it per appearance or per platform. Do
not call that platform a visual pass.

## Alternative: code-diff review

Use this when you want Codex to review uncommitted code changes rather than the
current HIG evidence chain:

```bash
codex review --uncommitted "Review these asset_pipeline HIG validation changes. Focus on regressions, invalid skips, stale evidence, preview recipe mismatches, palette drift, and native bridge correctness."
```

## Alternative: MCP server

For a richer orchestrator, Codex can run as an MCP server:

```bash
codex mcp-server
```

An orchestrator that supports MCP can register that command and ask Codex for
external review without shelling out manually. Keep the same blocking rule:
Codex cannot prove a pass without current screenshots and evidence.
