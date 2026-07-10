
# Phase 4 — Platform Tier Gating · Validation Rubric

You are the validator agent for phase 4. Your job is to verify, against this rubric, that the phase 4 implementer's work meets the contract. You do **not** modify code; you read, run, and record.

---

## Validator scope reminder

You will:
- **Read** source files, doc files, test output.
- **Run** Crystal builds (`crystal build --no-codegen ...`), spec suites (`crystal spec`), and the browser-MCP harness for accessibility audits on the web fallbacks.
- **Capture** stdout/stderr, screenshots, and axe/IBM Equal Access JSON into the evidence directory.
- **Record** a `GATE_REPORT.json` per the schema in `rubric/gate_report_schema.md`.

You will not:
- Edit code, except for the temporary-edit pattern documented in `rubric/validation_criteria.md` (and revert before exit).
- Skip a check. Each check below appears once in the report, in this order.
- Re-classify the tier matrix yourself. If a widget is missing from the matrix, that is the implementer's gap to fix.

---

## Pre-reading checklist

Before running checks:

1. `rubric/validation_criteria.md` — universal validator standards.
2. `rubric/gate_report_schema.md` — report format.
3. `rubric/behavior-simulation-toolkit.md` — CDP-over-WebSocket focus / Tab / dismiss-path patterns (§3, §4.2, §5.5, §5.6, §5.9). All `focus.*` and `conformance.*-positioning` checks in this phase rely on the patterns documented there.
4. `phases/phase-04-platform-tier-gating/README.md` — orientation.
5. `phases/phase-04-platform-tier-gating/implementation.md` — the contract you are validating against. Read it fully.
6. `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — tier model.
7. The implementer's handoff message (provided by the team lead) — note the commit hashes and any disclosed deviations.

Do **not** read the implementer's commit messages until you have formed expectations from the rubric.

---

## Evidence directory

Create `handoff/phase-04-evidence-{YYYY-MM-DD}/` per the layout in `rubric/validation_criteria.md`. All evidence paths in this report are relative to that directory.

---

## Checks

### tier.matrix-exists

**Required.** `docs/initiative-cross-platform-ui/tier-matrix.md` exists at the expected path.

How: `ls docs/initiative-cross-platform-ui/tier-matrix.md`.

Pass when: file exists, is non-empty, contains the three section headers `## Tier 1`, `## Tier 2`, `## Tier 3`.

### tier.matrix-classifies-every-widget

**Required.** Every `.cr` file in `src/ui/views/` is named at least once in `tier-matrix.md`.

How:
```
ls src/ui/views/*.cr | xargs -n1 basename | sed 's/\.cr$//'
```
For each widget name, grep `tier-matrix.md` for it. Capture the missing list.

Pass when: no widget from `src/ui/views/` is missing from the matrix. Also, no entry in the matrix references a file that doesn't exist (no zombies).

### tier.tier3-set-correct

**Required.** The Tier 3 section of `tier-matrix.md` lists at minimum: `ActionSheet`, `ContextMenu`, `PathControl`. These three are the hard-required Tier 3 set for Phase 4.

**Escape hatch (explicit, do not flag as a deviation):** `Toolbar`, `Popover`, and `MenuButton` are deferred to team-lead adjudication by the implementation brief (see `implementation.md` §"Judgment calls deferred to team-lead adjudication"). If they appear in Tier 3 with a justification, that is acceptable. If they appear in Tier 2 with a justification, that is also acceptable. If they appear in Tier 3 without justification or are missing from the matrix entirely, fail.

Other widgets the README mentioned (`HapticFeedback`, `MenuBarExtra`, native `ColorPicker`/`DatePicker`/`TimePicker` chrome) are either absent (no class exists yet) or classified with a brief justification.

Pass when: (a) `ActionSheet`, `ContextMenu`, and `PathControl` are present in Tier 3, AND (b) `Toolbar`/`Popover`/`MenuButton` are each classified somewhere (Tier 2 or Tier 3) with a one-line justification, AND (c) every other widget in `src/ui/views/` is classified. Otherwise fail with a specific note about which classification is missing.

### gate.action-sheet-compile-error

**Required.** **Bar:** behavior — the build actually fails, not just that the macro is present in the source. Building a snippet that names `UI::ActionSheet` without `-Dios` produces a compile error with the expected message.

How: write the snippet to a tempfile (NOT via stdin — the `crystal build --no-codegen -` stdin form was rejected by the prior plan audit and is not reliable on the project's Crystal version):
```
TMP="/tmp/ap_phase4_action_sheet_$$.cr"
cat > "$TMP" <<'CR'
require "asset_pipeline/ui"
sheet = UI::ActionSheet.new("Title", "Message")
CR
crystal build --no-codegen "$TMP" 2>&1 | tee \
  handoff/phase-04-evidence-DATE/test_output/gate.action-sheet-compile-error.log
echo "exit: $?" >> handoff/phase-04-evidence-DATE/test_output/gate.action-sheet-compile-error.log
rm -f "$TMP"
```

Pass when:
1. The recorded `exit:` line is non-zero (the build actually failed; do not accept a passing build with the error text written by some other code path).
2. The captured output contains all four strings:
   - `UI::ActionSheet is iOS-only`
   - `-Dios`
   - `UI::ActionSheetWithWebFallback`
   - `{% if flag?(:ios) %}`
3. The captured output does NOT contain any unrelated compile errors (e.g., a transitive require failing for a different reason) — read the full output; if the gate's `{% raise %}` is masking a different real failure, mark `passed: false` with a note.

Revert: delete the tempfile. `git status --short` must be clean.

Evidence: `test_output/gate.action-sheet-compile-error.log` containing the full captured combined stdout/stderr + the `exit:` line.

### gate.action-sheet-compiles-with-flag

**Required.** The same snippet builds cleanly with `-Dios`.

How: as above with `-Dios` added.

Pass when: build exits zero. No warnings involving phase-4 code.

### gate.context-menu-compile-error

**Required.** Building a snippet that names `UI::ContextMenu` without `-Ddarwin`/`-Dios`/`-Dmacos` produces the expected error.

How: equivalent to gate.action-sheet-compile-error, substituting `ContextMenu` and the expected fallback class name.

Pass when: build fails AND output contains `UI::ContextMenu is`, `-Dios or -Dmacos` (or `darwin`), `UI::ContextMenuWithWebFallback`, and a `{% if flag?(:darwin) %}` example.

### gate.context-menu-compiles-with-flag

**Required.** Same snippet compiles with `-Dios` and again with `-Dmacos`.

Pass when: both builds exit zero.

### gate.path-control-compile-error

**Required.** Building a snippet that names `UI::PathControl` without `-Dmacos` produces the expected error.

Pass when: build fails AND output contains `UI::PathControl is macOS-only`, `-Dmacos`, `UI::PathControlWithWebFallback`, and a `{% if flag?(:macos) %}` example.

### gate.menu-bar-still-compiles-everywhere

**Required.** `src/ui/menu_bar.cr` references `ContextMenu` but is no longer broken on non-darwin builds (the implementer should have guarded the reference).

How: `crystal build --no-codegen src/asset_pipeline.cr` (default web) must succeed. `crystal build --no-codegen src/asset_pipeline.cr -Dios` must succeed. `crystal build --no-codegen src/asset_pipeline.cr -Dmacos` must succeed. `crystal build --no-codegen src/asset_pipeline.cr -Dandroid` must succeed.

Pass when: all four exit zero.

### fallback.with-web-fallback-classes-cross-compile

**Required.** `UI::ActionSheetWithWebFallback`, `UI::ContextMenuWithWebFallback`, `UI::PathControlWithWebFallback` all compile against every flag.

How: for each class and each of `{default, -Dios, -Dmacos, -Dandroid}`, build a snippet that constructs and calls `accept` on a no-op visitor.

Pass when: 12 successful builds.

### fallback.web-html-action-sheet-structure

**Required.** Web visitor for `ActionSheetWithWebFallback` produces the expected HTML structure.

How: a Crystal spec that constructs the view with title, message, and two actions (one destructive), feeds it through `Web::Renderer`, and asserts the output contains: `role="dialog"`, `aria-modal="true"`, `aria-labelledby`, `aria-describedby`, `data-presented`, two `data-ap-as-action` buttons, one with the destructive style class, and a Cancel button with `data-ap-as-dismiss="cancel"`.

Pass when: the spec passes.

### fallback.web-html-context-menu-structure

**Required.** Web visitor for `ContextMenuWithWebFallback` produces the expected HTML.

How: spec asserts `role="menu"`, `role="menuitem"` per item, `role="separator"` for separators, `aria-disabled="true"` for disabled items, `data-ap-ctx-host` attribute on the host wrapper.

Pass when: spec passes.

### fallback.js-is-self-contained

**Required.** The two JS fallback files (`src/ui/web/action_sheet_fallback.js`, `src/ui/web/context_menu_fallback.js`) have no `import`, `require`, or external CDN references. Each is under 200 lines.

How: grep each file for `import|require|<script src=|//npm|cdnjs|unpkg`. `wc -l` each.

Pass when: zero external references; each file ≤ 200 lines.

### fallback.css-uses-ap-prefix

**Required.** All CSS in the fallback stylesheets and any new CSS emitted by Phase 4 web visitors references custom properties using the canonical `--ap-*` prefix. The legacy `--amber-*` aliases are no longer accepted in new emissions.

How:
```
grep -rnE 'var\(--amber-' src/ui/web/ src/ui/views/action_sheet.cr src/ui/views/context_menu.cr src/ui/views/path_control.cr src/ui/renderers/web_renderer.cr
```
Then confirm `--ap-*` is in use:
```
grep -rnE 'var\(--ap-' src/ui/web/ | head -20
```

Pass when: the first grep returns zero matches (no `--amber-*` in any Phase 4 file). The second grep returns matches confirming `--ap-*` is the prefix in use.

### fallback.action-sheet-axe-clean

**Required.** A headless-Chrome CDP run (see `../../rubric/behavior-simulation-toolkit.md` §3, §3.10) against a test page that renders an `ActionSheetWithWebFallback` (presented) shows zero axe-core violations at severity `serious` or `critical`.

How: drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3 (extend `scripts/capture_amber_demo_screenshots.cr` or model on `scripts/axe_web_demo_audit.cr`). Navigate to a test page via `Page.navigate` (create via temporary edit if no demo page exists yet — revert before exiting). Run axe via the established `scripts/axe_web_demo_audit.cr` or the in-browser axe injection used in prior phases (read `axe.min.js` from disk, evaluate it via `Runtime.evaluate` to install `window.axe`, then `Runtime.evaluate` `axe.run().then(r => JSON.stringify(r))` — `DevTools#evaluate` already passes `awaitPromise: true`; see toolkit §3.10).

Pass when: serious/critical violations = 0. Moderate/minor violations are reported in notes but don't fail the check.

Capture: full axe JSON to `audits/fallback.action-sheet-axe-clean.json`. Screenshot of the presented sheet to `screenshots/fallback.action-sheet-axe-clean-{viewport}-{scheme}.png` for 1280×800 desktop light/dark and 375×667 mobile light/dark.

### fallback.action-sheet-ibm-equal-access-clean

**Required.** Same page, IBM Equal Access audit, zero violations at `violation` level.

How: `crystal run scripts/ibm_web_demo_audit.cr` or the equivalent. Capture JSON.

Pass when: violations at `violation` level = 0.

### fallback.context-menu-axe-clean

**Required.** A headless-Chrome CDP run (see `../../rubric/behavior-simulation-toolkit.md` §3, §3.10) against a test page that opens a `ContextMenuWithWebFallback` shows zero axe-core violations at severity `serious` or `critical`.

Pass when: as above.

### fallback.context-menu-ibm-equal-access-clean

**Required.** IBM Equal Access on the context-menu test page returns zero `violation`-level findings.

Pass when: as above.

### focus.action-sheet-focus-trap

**Required.** **Bar:** behavior. On the action-sheet test page, with the sheet presented:

1. Identify focusable elements inside the panel: action buttons + Cancel. There must be at least three (two actions + Cancel) in the test scene.
2. Pressing Tab from the first focusable advances through every action button in DOM order and lands on Cancel last.
3. Pressing Tab from Cancel wraps to the first action button.
4. Pressing Shift-Tab from the first action wraps to Cancel.
5. At every step, `document.activeElement` is inside the `.ap-action-sheet__panel`. Focus never escapes the panel via Tab or Shift-Tab.
6. When the sheet is dismissed (any path), `document.activeElement` returns to the element that was focused before the sheet was opened — captured in `focus.action-sheet-escape-closes`, `focus.action-sheet-backdrop-click-closes`, and the primary/cancel dismiss checks below.

**This check does NOT pass on source inspection.** A `tabindex` audit or a grep for a focus-trap library is insufficient. The check passes only when the validator drives real Tab presses against the running page and records `document.activeElement` after each press.

How: drive Chrome via CDP per `../../rubric/behavior-simulation-toolkit.md` §3.5. Use `Input.dispatchKeyEvent` for the Tab keystrokes — CDP-dispatched input is trusted (`isTrusted === true`) by default, which is the entire reason this protocol is used here; focus-trap libraries that gate on event trust will not respond to JS-side `dispatchEvent(new KeyboardEvent(...))`. Combine with `Runtime.evaluate` for polling `document.activeElement`. The full procedure:

```
1. Launch headless Chrome + open a CDP session (toolkit §3.2).
2. Page.navigate to the action-sheet test page; poll readyState === "complete".
3. Runtime.evaluate: stash the pre-open focused element on window:
     window.__preOpenFocus = document.activeElement;
     window.__focusTrace = [];
4. Click the trigger button via Runtime.evaluate (trigger.click()).
5. Runtime.evaluate: poll for [data-presented="true"] (50 ms interval, 2 s timeout).
6. Send a Tab key via Input.dispatchKeyEvent
   ({"type":"keyDown","key":"Tab","code":"Tab","windowsVirtualKeyCode":9,"nativeVirtualKeyCode":9,"modifiers":0})
   followed by the matching keyUp (real OS-level trusted key). After each
   send, via Runtime.evaluate push to the window-side array:
     window.__focusTrace.push({
       n: window.__focusTrace.length,
       tag: document.activeElement?.tagName,
       testid: document.activeElement?.getAttribute('data-testid'),
       text: document.activeElement?.textContent?.slice(0, 40),
       inside: !!document.activeElement?.closest('.ap-action-sheet__panel')
     });
7. Send Tab a total of (focusable_count + 2) times to guarantee at least one cycle wrap.
8. Send Shift-Tab (focusable_count + 2) times (same Input.dispatchKeyEvent with modifiers: 8).
9. Read window.__focusTrace via Runtime.evaluate (JSON.stringify(window.__focusTrace)).
```

Pass when:
- Every entry in `__focusTrace` has `inside === true` (focus never escaped the panel).
- The set of distinct `testid`s in the trace equals the set of focusable descendants of the panel exactly (every focusable visited at least once; no extras).
- The trace exhibits cycling behavior: entry `[n+focusable_count]` equals entry `[n]` in the Tab phase, and equivalently for Shift-Tab. (Verify by comparing the (focusable_count + 1)-th entry to the 1st.)

If `__focusTrace` is empty after the Tab sends, the page is rejecting untrusted events — confirm the recipe is using `Input.dispatchKeyEvent` and not JS-side `dispatchEvent`. CDP input is trusted by default; if a previous validator used `dispatchEvent(new KeyboardEvent(...))` and got an empty trace, that is a false-negative caused by the wrong synthesis path, not a real focus-trap failure.

Evidence: `inspections/focus.action-sheet-focus-trap.json` — the full `__focusTrace` array, plus a derived `{focusable_count, distinct_testids_visited, cycle_detected_at_index}` summary.

### focus.action-sheet-escape-closes

**Required.** **Bar:** behavior. Pressing Escape while the sheet is presented:
- Hides the sheet (`data-presented="false"`).
- Removes the panel from the document's accessibility tree.
- Fires the `ap:action-sheet:dismiss` CustomEvent with `detail.reason === 'escape'`.
- Returns focus to the trigger element that opened the sheet.

How: open the sheet from a trigger button. Before opening, stash `window.__trigger = document.activeElement` via `Runtime.evaluate`. Install an event listener: `root.addEventListener('ap:action-sheet:dismiss', e => window.__phase4DismissLog.push(e.detail))`. Press Escape via `Input.dispatchKeyEvent` (real trusted key — see `../../rubric/behavior-simulation-toolkit.md` §3.6; CDP input is trusted, JS-side `dispatchEvent` is not). Then read four things via `Runtime.evaluate`:
```js
({
  dismiss_log: window.__phase4DismissLog,
  data_presented: document.querySelector('.ap-action-sheet')?.getAttribute('data-presented'),
  panel_ax_visible: (() => {
    const p = document.querySelector('.ap-action-sheet__panel');
    if (!p) return false;
    // AX-tree visibility requires the element to not be aria-hidden AND not display:none
    if (p.getAttribute('aria-hidden') === 'true') return false;
    if (getComputedStyle(p).display === 'none') return false;
    return true;
  })(),
  focus_restored: document.activeElement === window.__trigger,
  active_testid: document.activeElement?.getAttribute('data-testid'),
  trigger_testid: window.__trigger?.getAttribute('data-testid')
})
```

Pass when **all four** booleans hold:
- `dismiss_log` contains exactly one entry with `{ reason: 'escape' }` (no leaked dismiss events from earlier paths).
- `data_presented === 'false'`.
- `panel_ax_visible === false` (panel is gone from the AX tree — not merely visually hidden behind another layer).
- `focus_restored === true` (the trigger is again `document.activeElement`).

Evidence: `inspections/focus.action-sheet-escape-closes.json` — the evaluated object above.

### focus.action-sheet-backdrop-click-closes

**Required.** **Bar:** behavior. Clicking outside the panel (on the backdrop) dismisses the sheet, identical to the Escape behavior, with `detail.reason === 'backdrop'` in the CustomEvent. The click is a real synthetic mouse event at coordinates measured from `getBoundingClientRect()` on the backdrop element — **not** a JS-side `backdrop.click()`, which a well-behaved implementation may guard against.

How: open the sheet from a known trigger, stash `window.__trigger`, install the dismiss-log listener. Read the backdrop's bounding rect via `Runtime.evaluate` (`JSON.stringify(...getBoundingClientRect())`); then dispatch a real synthetic click at the rect's center via `Input.dispatchMouseEvent` mousePressed + mouseReleased at `{x, y, button: "left", clickCount: 1}` (see toolkit §3.6). The click coordinate must be outside the panel's rect to genuinely test backdrop behavior — verify by reading both rects first. Then evaluate the same four-boolean assertion object from `focus.action-sheet-escape-closes` via `Runtime.evaluate`.

Pass when **all four** hold: dismiss log contains one entry with `{ reason: 'backdrop' }`; `data_presented === 'false'`; panel absent from AX tree; trigger is the active element.

If the synthetic click misses (the rect was wrong, the page intercepted at a higher z-index), the dismiss log will be empty AND `data_presented` will still be `'true'`. Distinguish "dismiss did not fire" from "wrong reason fired" — the former is a test-rig bug; the latter is a real implementation bug. Re-measure the rect, retry once, mark `blocked: true` with the captured rects if the issue persists.

Evidence: `inspections/focus.action-sheet-backdrop-click-closes.json` — the assertion object plus the captured rects (`panel_rect`, `backdrop_rect`, `click_point`) for forensics.

### conformance.action-sheet-positioning

**Required.** **Bar:** conformance. The action-sheet panel is positioned at the bottom of the viewport on mobile (≤ 767 px) and centered on desktop (≥ 768 px). The bottom-position must honor `env(safe-area-inset-bottom)` (this matters on mobile Safari with the home indicator).

How: load the action-sheet test page in headless Chrome via CDP (`Page.navigate` per `../../rubric/behavior-simulation-toolkit.md` §3.2) at three viewports (each set via `Emulation.setDeviceMetricsOverride`):
1. 1280×800 (desktop): expect the panel centered. Measure `getBoundingClientRect()` for `.ap-action-sheet__panel`. Assert: `rect.left + rect.width/2` within ±2 px of viewport center; `rect.top + rect.height/2` within ±2 px of viewport center vertically.
2. 375×667 (mobile): expect the panel docked to bottom. Assert: `rect.bottom` equals `window.innerHeight` exactly (the `safe-area-inset-bottom` defaults to 0 in headless Chrome); `rect.left === 0`; `rect.right === window.innerWidth`.
3. 320×568 (mobile-min): same as 375×667 but at the smallest supported viewport. Assert the panel does not overflow horizontally and the title text does not wrap to more than three lines.

Pass when: all positioning assertions hold at each viewport.

Evidence: `inspections/conformance.action-sheet-positioning-{1280,375,320}.json` — each with the measured rect plus the asserted predicates.

### conformance.action-sheet-touch-targets

**Required.** **Bar:** conformance. Every action button and the Cancel button in the rendered action sheet measures ≥ 44 px in both width and height at the 375×667 viewport.

How: with the sheet presented, evaluate `Array.from(document.querySelectorAll('[data-ap-as-action], [data-ap-as-dismiss="cancel"]')).map(el => el.getBoundingClientRect())` and assert each `width >= 44 && height >= 44`.

Pass when: every button satisfies the predicate.

Evidence: `inspections/conformance.action-sheet-touch-targets.json` — the rect array plus pass/fail per element.

### focus.context-menu-keyboard-nav

**Required.** **Bar:** behavior. With a context-menu open at the test scene's trigger (which has at least four items, one of them `aria-disabled="true"`): ArrowDown moves focus to the next enabled item, ArrowUp to the previous enabled item, Home to first enabled, End to last enabled, Escape closes and returns focus to the trigger. Disabled items are skipped both ways.

How: open the menu via the JS-side `dispatchEvent(new MouseEvent('contextmenu', ...))` (or whatever the test scene exposes). Capture `document.activeElement` after each key press. The test scene must label disabled items with `data-test-disabled="true"` so the validator can confirm they were skipped.

Pass when: every transition lands on an enabled menuitem; no transition lands on a disabled menuitem; Escape returns focus to the original trigger; after Escape the menu's `data-presented === 'false'`.

Evidence: `inspections/focus.context-menu-keyboard-nav.json` — the activeElement transcript for each of the six key presses (ArrowDown, ArrowDown, ArrowUp, Home, End, Escape).

### conformance.context-menu-positioning

**Required.** **Bar:** conformance. The context menu opens at the trigger's location (not at the center of the viewport); when the trigger is near a viewport edge, the menu repositions to remain fully visible. The validator opens the menu against **three real trigger positions** and measures the rendered menu's bounding rect via `getBoundingClientRect()` after each — source inspection of the positioning math is not sufficient.

How: load the context-menu test page in headless Chrome via CDP (`Page.navigate` per `../../rubric/behavior-simulation-toolkit.md` §3.2). The test scene exposes three triggers (`data-testid="ctx-trigger-tl"`, `"ctx-trigger-center"`, `"ctx-trigger-br"`) positioned at top-left (within 16 px of `(0, 0)`), center (within 16 px of viewport center), and bottom-right (within 16 px of `(innerWidth, innerHeight)`). For each trigger, follow the recipe in `../../rubric/behavior-simulation-toolkit.md` §5.9:
1. Read the trigger's `getBoundingClientRect()`; assert it actually lives in the expected viewport quadrant (sanity check that the test fixture is correctly positioned).
2. Dispatch the documented open gesture against the trigger. Prefer `Input.dispatchMouseEvent` with `{"type":"mousePressed","button":"right","clickCount":1}` (immediately followed by `mouseReleased`) at the trigger's center coordinate for a real trusted right-click — see `../../rubric/behavior-simulation-toolkit.md` §3.3 / §3.6. Fall back to `Runtime.evaluate` dispatching `new MouseEvent('contextmenu', {clientX, clientY, bubbles: true})` only if the implementation explicitly handles `contextmenu` events from the JS surface.
3. Poll for `[role="menu"][data-presented="true"]` to mount (50 ms interval, 1 s timeout).
4. Read the menu's `getBoundingClientRect()`. Read the viewport (`innerWidth`, `innerHeight`).
5. Assert the menu's rect is fully inside `[0, innerWidth] × [0, innerHeight]` — `rect.left >= 0 && rect.top >= 0 && rect.right <= innerWidth && rect.bottom <= innerHeight`.
6. Assert the menu's anchored edge is within ±8 px of the trigger's nearest edge. For `ctx-trigger-tl`, the menu's top-left corner should be near the trigger's bottom-left or top-right (depending on the implementation's anchor convention; the test fixture documents which). For `ctx-trigger-br`, the menu must have shifted up and/or left to stay on-screen — its anchored edge no longer hugs the trigger's bottom-right, but its furthest edge from the trigger does not exceed `innerWidth`/`innerHeight`.
7. Dismiss the menu (click body or send Escape) before opening the next position, so each measurement is independent.

Pass when, for each of the three positions, every assertion in step 5 holds (no overflow) and the anchoring relationship in step 6 holds within the documented tolerance.

Evidence: `inspections/conformance.context-menu-positioning-{top-left,center,bottom-right}.json` — each containing `{trigger_rect, menu_rect, viewport, on_screen, anchored_within_tolerance}`.

### focus.context-menu-outside-click-closes

**Required.** **Bar:** behavior. Clicking outside the open menu dismisses it AND returns focus to the trigger.

How: open the menu, click on the document body (specifically `document.body` or an element with `data-testid="empty-outside"`), observe `data-presented` and `document.activeElement`.

Pass when: `data-presented === 'false'` after the click; `document.activeElement` equals the trigger that originally opened the menu.

Evidence: `inspections/focus.context-menu-outside-click-closes.json`.

### spec.suite-green

**Required.** `crystal spec` from repo root completes with `0 errors, 0 failures, 0 pending`.

How:
```
cd /Users/crimsonknight/open_source_coding_projects/asset_pipeline
crystal spec 2>&1 | tee handoff/phase-04-evidence-DATE/test_output/spec.suite-green.log
```

Pass when: the trailer line shows `0 errors, 0 failures`. `0 pending` is required; if non-zero pending, mark passed with a note listing each pending test.

### spec.compile-error-tests

**Required.** The three compile-error specs (`spec/ui/views/action_sheet_compile_error_spec.cr`, `context_menu_compile_error_spec.cr`, `path_control_compile_error_spec.cr`) exist and pass when run individually.

How: run each spec file individually with `crystal spec spec/ui/views/{file}.cr`.

Pass when: each exits zero with passing assertions.

### docs.claude-md-updated

**Required.** `CLAUDE.md` (repo root) contains:
- A section header referring to the Tier model (e.g., "Tier model for cross-platform widgets" or similar).
- A pointer to `docs/initiative-cross-platform-ui/tier-matrix.md`.
- A mention of `AssetPipeline::Platform.requires(:ios)` for app-side gating.

How: `grep -i "tier" CLAUDE.md` and `grep "Platform.requires" CLAUDE.md`.

Pass when: all three present.

### docs.tier-matrix-complete

**Required.** `tier-matrix.md` has no "TBD" or "?" or "Unclassified" entries.

How: `grep -E "TBD|^[?]| Unclassified" docs/initiative-cross-platform-ui/tier-matrix.md`.

Pass when: no matches.

### macro.platform-requires-works

**Required.** `AssetPipeline::Platform.requires(:ios) { ... }` raises a compile error on the default build and is a no-op pass-through on `-Dios`.

How: two minimal snippets, each built with `crystal build --no-codegen`.

Pass when: default build fails with a message containing `Platform.requires(:ios)` and `-Dios`; `-Dios` build exits zero.

---

## Verdict

`PASS` if every required check above has `passed: true`. `FAIL` otherwise. Optional checks (none in this rubric) do not affect verdict.

Return the GATE_REPORT.json + summary per `rubric/validation_criteria.md`.
