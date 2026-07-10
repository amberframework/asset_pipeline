# Phase 4 iter 2 — R1 + R2 deviation verification

## R1 deviations (carried forward from iter 1)

1. **Macro stub-file split**: macros for `Platform.requires`, `ActionSheet`, `ContextMenu`, `PathControl` raise via `{% raise %}`. Source-inspected; specs in `spec/ui/views/{action_sheet,context_menu,path_control}_compile_error_spec.cr` exercise the gates and all PASS. Acceptable.

2. **ContextMenu `trigger : View?` property**: the `*WithWebFallback` carries an optional trigger so the renderer can wire the host's first child to contextmenu / Shift+F10 listeners. Verified in tier-matrix companion table; spec coverage in `context_menu_with_web_fallback_spec.cr` (6 examples PASS). Acceptable.

3. **MenuBar / StatusBar Apple-gating cascade**: `src/ui/menu_bar.cr` references ContextMenu inside `{% if flag?(:macos) || flag?(:ios) %}` blocks, preserving non-darwin compilability. Cross-target build matrix: web/iOS/macOS PASS. Android fails on host stdlib epoll (precedent B9), not Phase 4 code. Acceptable.

## R2 fixes (introduced this iteration)

1. **Color contrast at `web_renderer.cr:2721`**: `color: var(--ap-color-brand-accent)` → `color: var(--ap-color-brand-primary)`.
   - Pre-R2 axe contrast measurement: 1.92:1 (sunken/light) — FAIL of WCAG-AA 4.5:1.
   - Post-R2 measurement (re-run this iteration): 0 serious/critical contrast violations across all 4 viewport×scheme combos (1280-light, 1280-dark, 375-light, 375-dark).
   - Source comment cites computed contrast ≥ 5.05:1 (sunken/light), ≥ 5.78:1 (panel/light), ≥ 8.72:1 (dark). Matches expected.

2. **Listitem markup at `web_renderer.cr:2589`**: removed `actions_list.set_attribute("role", "group")`.
   - Pre-R2 axe baseline: serious "listitem" violation (2 nodes per viewport).
   - Post-R2: zero listitem violations.
   - Verified by source inspection (R2 commit `8192575`) and by post-fix axe re-run.

## Tier matrix reconciliation (iter 2)

- `ls src/ui/views/*.cr | wc -l` → 78 widgets
- Tier 1 heading: "17 widgets" — matches
- Tier 2 heading: "55 widgets" — matches (56 table rows minus 1 header row)
- Tier 3 heading: "3 gated + 3 cross-platform companions" — matches
- Every widget in src/ui/views/ is referenced in the matrix (0 missing)
- No zombie references (no matrix-cited paths that don't exist)
- Tier 3 set: ActionSheet, ContextMenu, PathControl — present
- Toolbar, Popover, MenuButton — all classified in Tier 2 with justifications
