# Phase 6.12B — Capture + Audit Closure Brief

**Date opened:** 2026-05-24
**Authored by:** Architect (Codex-critiqued before dispatch — see critique trail)
**Branch:** `phase-06.12-library-identity-macos-polish` (continue from `b2dc0e7`)
**Agent type:** CAPTURE-ONLY. No source code changes. Verify + screenshot + audit + report. If you find a code-level bug, ESCALATE — do not fix.

---

## Why this iteration exists

Phase 6.12A (commit `973d32d`) shipped the library-identity pivot (`Color::SYSTEM_ACCENT` sentinel + 4 renderer integrations + macOS NSWindow sizing + Cascade preservation + no-amber audit) per its brief. Evidence captures were explicitly carved out and deferred to 6.12B per [[mid-stop-pattern-evidence-capture]]:

> "44-artifact capture set + 2 audit markdown files + owner hand-test gate. osascript runtime probes (blocked by Accessibility TCC permission this iteration). Cascade native (macOS / iOS) prominent-button pixel sample."

This iteration closes that gap. After 6.12B's captures land + the owner runs the hand-test, Phase 6.12 closes per architect.

---

## Environment assumptions

1. iPhone 17 Pro simulator exists and boots.
2. Branch HEAD `b2dc0e7` is checked out (includes 6.12A + Phase 8 design docs).
3. `crystal spec` baseline is 1529/4/0 at `b2dc0e7`. Must remain stable through this iteration (you're not modifying code, so this is verification only).
4. The Voyager iOS scene delegate reads `VOYAGER_APPEARANCE` env var. To flip appearance on a captured Voyager screen, use `SIMCTL_CHILD_VOYAGER_APPEARANCE=light/dark` when launching via `xcrun simctl launch`.
5. Voyager builds are already in DerivedData from 6.12A; if needed, rebuild with `make -C samples/initiative-cross-platform-ui-voyager ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'`.
6. macOS Voyager binary at `samples/initiative-cross-platform-ui-voyager/macos/bin/voyager` should exist; rebuild via `make -C samples/initiative-cross-platform-ui-voyager macos` if missing.
7. `codex` CLI at `/opt/homebrew/bin/codex` for the audit-doc Codex review.

---

## Tolerance for partial completion

Per [[mid-stop-pattern-evidence-capture]], capture agents in prior phases routinely stopped mid-action on the long capture loops. To prevent that:

- **The deliverables below are sorted by priority.** Priority 1 (Cascade pixel-proof + macOS resize captures + iOS legibility) MUST land. Priority 2 (the 14-row behavior contract) is best-effort.
- **If you run out of turn budget at the 14-row contract, STOP and write the report with whatever you captured.** Do NOT skip the report.
- **If a capture step requires extending XCUITest with new methods, STOP and ESCALATE** — XCUITest extension is code work, out of scope.

---

## Scope — 6 priority groups (post-Codex revision)

**Codex-critique revision:** prior version had the audit docs at Priority 3 (after the 14-row contract). A mid-stop would have left screenshots without WCAG interpretation. Order now is: 1A-1D capture priority groups → **2A audits + Codex review** → 2B behavior contract (best-effort, last so partial completion leaves a complete report).

### Priority 1A — Cascade preservation pixel-proof

Owner directive on 6.12A: Cascade must continue to render deep teal after the Option C pivot. 6.12A verified this at the SOURCE level + via web CSS grep, but didn't pixel-sample the native Cascade prominent buttons.

**Required artifacts:**

- `docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/cascade-ios-prominent-button.png`
- `docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/cascade-macos-prominent-button.png`

**Pixel-sample verification:** the Cascade brand color is approximately `oklch(0.560 0.130 195.00)` per the Phase 6.12A no-amber-audit doc. In sRGB this lands near `(15, 133, 133)` — the deep teal. Each capture must:

1. Show a prominent button rendered in Cascade's deep teal (NOT the system blue we set for Voyager via SYSTEM_ACCENT).
2. Be sampled via `python3 /tmp/wcag_sample.py <png> <btn_x> <btn_y>` to confirm the pixel falls within `(15, 133, 133) ± 15 per channel`.

If pixel-sample fails on either platform: ESCALATE. This is a real regression.

**Build commands:**

```bash
# Cascade iOS — adapt from Voyager Make pattern
make -C samples/initiative-cross-platform-ui-demo cascade-ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'

# Cascade macOS
make -C samples/initiative-cross-platform-ui-demo cascade-macos
# Launch + screenshot via xcrun simctl io / screencapture
```

(Note: the exact Cascade Make targets may differ from Voyager's — check `samples/initiative-cross-platform-ui-demo/Makefile`. If the target shape is unfamiliar, report what you find and capture what you can.)

### Priority 1B — macOS resize captures (3 widths × 2 appearances = 6 screenshots)

Per 6.12A Item 3 brief, this is the visual proof of the NSWindow sizing fix (880×640 default + resizable + 480×400 floor).

**Required artifacts** under `docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/`:

- `voyager-macos-480x400-light.png` — minimum size, light appearance
- `voyager-macos-880x640-light.png` — default size, light appearance
- `voyager-macos-1280x800-light.png` — wide, light appearance
- `voyager-macos-480x400-dark.png`
- `voyager-macos-880x640-dark.png`
- `voyager-macos-1280x800-dark.png`

**Capture sequence (per appearance):**

```bash
# Launch Voyager macOS bin
samples/initiative-cross-platform-ui-voyager/macos/bin/voyager voyager-todos &
VOYAGER_PID=$!
sleep 2  # wait for window mount

# Resize + capture at each size. Use AppleScript via osascript to set bounds.
for SIZE in "480x400:480 400" "880x640:880 640" "1280x800:1280 800"; do
  LABEL="${SIZE%%:*}"; DIMS="${SIZE##*:}"
  W="${DIMS%% *}"; H="${DIMS##* }"
  osascript -e "tell application \"voyager\" to set bounds of window 1 to {100, 100, $((100+W)), $((100+H))}"
  sleep 1
  screencapture -l$(osascript -e 'tell application "voyager" to get id of window 1') \
    docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/voyager-macos-${LABEL}-light.png
done
kill $VOYAGER_PID
```

(Note: macOS Voyager doesn't have an env-var appearance pin like iOS does — appearance follows system. Toggle dark mode via `defaults write -g AppleInterfaceStyle Dark; killall -KILL "Voyager"` or via System Settings.)

**If osascript fails on TCC Accessibility permission:** document the failure in the audit, capture via window-id `screencapture -l` if possible, otherwise log the gap and proceed.

### Priority 1C — iOS legibility captures (8 screenshots) + WCAG audit

The Phase 6.11 iter-3 audit was flagged NEEDS_WORK by Codex 3 (over-broad "semantic auto-pass" claims). 6.12A's pivot to SYSTEM_ACCENT changes what should be on-screen (system blue buttons instead of amber). Recapture all 8 + rewrite the audit.

**Required artifacts:**

- `voyager-{signin,todos,editor,settings}-{light,dark}.png` (8 PNGs) under `docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/`
- `phase-06.12b-evidence/ios-legibility-audit.md` per the table format below

**Capture loop** (the appearance-flip + relaunch pattern proven in 6.11 capture+audit close):

```bash
DEVICE=$(xcrun simctl list devices booted | awk '/iPhone 17 Pro/ {print $NF; exit}' | tr -d '()')
EVIDENCE=docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence
for APPEAR in light dark; do
  for ROUTE in voyager-sign-in voyager-todos voyager-todo-editor voyager-settings; do
    xcrun simctl ui "$DEVICE" appearance "$APPEAR"
    sleep 0.5
    SIMCTL_CHILD_VOYAGER_APPEARANCE="$APPEAR" \
      xcrun simctl launch --terminate-running-process "$DEVICE" \
        com.assetpipeline.voyager.VoyagerDemo --args -VoyagerRoot "$ROUTE"
    sleep 3
    case "$ROUTE" in
      voyager-sign-in) N=signin;;
      voyager-todos) N=todos;;
      voyager-todo-editor) N=editor;;
      voyager-settings) N=settings;;
    esac
    xcrun simctl io "$DEVICE" screenshot "$EVIDENCE/voyager-${N}-${APPEAR}.png"
  done
done
```

**Audit table format** (per `[[audit-shortcut-trap]]`):

```markdown
| Screen | Appearance | Element | Sampled point | Foreground | Background | Ratio | Pass/Fail | Auto-pass (semantic citation)? |
|--------|------------|---------|---------------|------------|------------|-------|-----------|--------------------------------|
| Sign-in | light | Title "Sign In" | (x, y) | #000 | #FFF | 21:1 | PASS | YES — src/.../sign_in.cr:42 uses UI::Label.new with default Color.label semantic |
| ... | ... | ... | ... | ... | ... | ... | ... | ... |
```

Auto-pass claims require a `file:line` source citation. Non-semantic rows require measured pixel coordinates + WCAG ratio via `/tmp/wcag_sample.py`. Sample at minimum 3 elements per screen-appearance.

**Pay specific attention to:**
- The Sign-in button background (should now be iOS system blue post-SYSTEM_ACCENT, was amber under the pre-6.12A library default).
- The Done card filtered state with `opacity = 0.6` (Codex 2 flag from Phase 6.11).
- Placeholder text in form fields (should be `Color.primary.opacity(0.5)` via `PromptOverlayField` from Phase 6.11 iter-4 — ~4:1 ratio).

### Priority 1D — iOS swipe-revealed screenshots (2 screenshots)

Phase 6.11 iter-3 brief required `voyager-todos-swipe-revealed-{light,dark}.png` and they were never produced.

**Required artifacts:**

- `phase-06.12b-evidence/voyager-todos-swipe-revealed-light.png`
- `phase-06.12b-evidence/voyager-todos-swipe-revealed-dark.png`

**Approach options (pick what works):**

- Run XCUITest's existing harness at `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift` if it has a swipe-then-screenshot test. If it doesn't, do NOT add one — that's code work.
- Drive by-hand via the Simulator UI: open the running app to Todos, swipe left on a row, take a screenshot with `xcrun simctl io booted screenshot`.

**If neither approach succeeds without code extension:** capture whatever swipe-state visual you can (even just the unswipe Todos screen), log the gap in the report, ESCALATE for a code follow-up in a future phase.

### Priority 2A — Audit markdown + Codex review (BEFORE 2B)

Two audit docs land at `phase-06.12b-evidence/`:

- `ios-legibility-audit.md` — populated from Priority 1C captures per the table format in Priority 1C.
- `macos-legibility-audit.md` — same format applied to the 6 macOS resize captures from Priority 1B. Per window-width, a column of measured ratios for chrome that varies (control placement, text wrap, button labels).

After both audits land, run:

```bash
codex exec --skip-git-repo-check "Quick review of the Phase 6.12B audit docs at docs/initiative-cross-platform-ui/handoff/phase-06.12b-evidence/ios-legibility-audit.md and macos-legibility-audit.md. For each row claiming semantic auto-pass: is the file:line citation real (do not read source files; trust the format)? For each row with measured ratio: is the math correct? Flag anything that looks fabricated. Verdict: APPROVE / REVISE. Max 100 words."
```

Save to `phase-06.12b-codex-1.md`.

**Audit + Codex run BEFORE the 14-row contract** so partial completion leaves a complete WCAG interpretive artifact, not orphan screenshots.

### Priority 2B — 14-row functional behavior contract (28 screenshots, best-effort)

Phase 6.11 brief revision 2 Item 3 specified 14 actions × light + dark = 28 captures of the Voyager CRUD flow. This is the largest single deliverable in the phase.

**Per [[mid-stop-pattern-evidence-capture]]:** if turn budget gets tight, STOP at row N + write the report with rows 1..N captured. Do NOT skip the report to capture more.

**Capture cycle (Codex-revision tightened):**

- **Seeded state contract:** App launch must show a deterministic starting point. Voyager has 5 seed todos defined in `samples/.../voyager/screens/state.cr`. Before each behavior-row capture session, terminate any running Voyager + relaunch (`xcrun simctl launch --terminate-running-process`) to reset state to the seed.
- **Light + dark are TWO SEPARATE PASSES.** Do not toggle appearance mid-flow. Capture all 14 light rows on one clean run; reset; capture all 14 dark rows on a second clean run with `SIMCTL_CHILD_VOYAGER_APPEARANCE=dark`.
- **For each behavior row, the per-row driving instructions are:**
  - Row 1 (`behavior-01-launch`): just-launched Sign-in screen. No interaction. Screenshot.
  - Row 2 (`behavior-02-after-signin`): in the email field, type `seth@example.com` (use `xcrun simctl io` to drive text input via `simctl keyboard` if available, OR via XCUITest's EXISTING `signin` test method if `VoyagerVisualTests.swift` already has one). Type `password` in the password field. Tap Sign in. Wait for Todos to render. Screenshot.
  - Row 3 (`behavior-03-editor-empty`): from Todos, tap Add Todo. Wait for Editor mount. Screenshot. (Save button should be visibly disabled.)
  - Row 4 (`behavior-04-editor-typed`): in the Title field, type `Rem 6.12B test`. Screenshot. (Save button should now be enabled.)
  - Row 5 (`behavior-05-after-save`): tap Save. Wait for Todos rerender. Screenshot. (New row "Rem 6.12B test" should be visible.)
  - Row 6 (`behavior-06-row-completed`): on the "Rem 6.12B test" row, tap the leading checkbox/toggle. Screenshot. (Row text should be strikethrough + secondary label color.)
  - Row 7 (`behavior-07-swipe-revealed`): swipe-left on the "Rem 6.12B test" row to reveal Edit + Delete trailing actions. Screenshot. (Same artifact as Priority 1D — link or duplicate.)
  - Row 8 (`behavior-08-editor-prefilled`): tap Edit on the swiped row. Wait for Editor with prefilled `Rem 6.12B test` + Completed toggle on. Screenshot.
  - Row 9 (`behavior-09-after-edit`): change title to `Rem 6.12B test edited`. Tap Save. Wait for Todos. Screenshot. (Row should be updated in place.)
  - Row 10 (`behavior-10-after-delete`): swipe-left, tap Delete. Wait for Todos. Screenshot. (Row should be removed.)
  - Row 11 (`behavior-11-settings-default`): tap Settings link in Todos header. Wait for Settings screen. Screenshot. (Hide-completed toggle off.)
  - Row 12 (`behavior-12-settings-toggled`): tap the Hide-completed toggle. Screenshot. (Toggle flipped on.)
  - Row 13 (`behavior-13-todos-filtered`): tap back navigation. Wait for Todos. Screenshot. (Completed rows omitted.)
  - Row 14 (`behavior-14-todos-unfiltered`): navigate to Settings, toggle off, navigate back. Screenshot.

**If any row's driving requires extending VoyagerVisualTests.swift with a new XCUITest method:** STOP that row, capture whatever state you can, log the gap. Continue to the next row (or, if it's a sequence-dependent failure, STOP the contract and write the report at that point).

**Required artifacts** under `phase-06.12b-evidence/`:

```
behavior-01-launch-{light,dark}.png         (initial sign-in screen)
behavior-02-after-signin-{light,dark}.png   (Todos screen after submit)
behavior-03-editor-empty-{light,dark}.png   (Editor open, blank, Save disabled)
behavior-04-editor-typed-{light,dark}.png   (Title typed, Save enabled)
behavior-05-after-save-{light,dark}.png     (Todos with new row)
behavior-06-row-completed-{light,dark}.png  (Row toggled complete)
behavior-07-swipe-revealed-{light,dark}.png (same as Priority 2A — reuse)
behavior-08-editor-prefilled-{light,dark}.png (Edit a row, title prefilled)
behavior-09-after-edit-{light,dark}.png     (Row updated in place)
behavior-10-after-delete-{light,dark}.png   (Row removed)
behavior-11-settings-default-{light,dark}.png (Settings, toggle off)
behavior-12-settings-toggled-{light,dark}.png (Toggle on)
behavior-13-todos-filtered-{light,dark}.png (Back to Todos, filtered)
behavior-14-todos-unfiltered-{light,dark}.png (Toggle off, back, unfiltered)
```

**This requires driving navigation + state mutation through the running app.** Options:

- Extend `VoyagerVisualTests.swift` with a 14-step XCUITest — CODE WORK, out of scope. Do not.
- Drive by-hand in the Simulator (Cmd+Tab between editor + sim), taking screenshots at each step. Tedious but works.
- Use `xcrun simctl ui booted gesture` if it supports the gestures needed. Verify before relying on.

If by-hand driving is the only path AND would exceed turn budget: capture rows 1-5 (the basic sign-in → save flow) and the report flags the rest as "requires owner hand-test or future XCUITest extension."

---

## Final report

Write `docs/initiative-cross-platform-ui/handoff/phase-06.12b-implementer-report.md` covering:

- Per-priority status (1A / 1B / 1C / 2A / 2B / 3) with PASS / PARTIAL / SKIPPED.
- Artifact paths.
- Codex verdict.
- The 14-row behavior table with COMPLETE / PARTIAL / UNATTAINED per row.
- Hand-test commands for the owner to run his closing-gate check (build commands + launch commands for both iOS and macOS).
- Open uncertainty (especially around the by-hand 14-row contract gaps if any).

Return to architect. Do NOT declare Phase 6.12 passed — that's the owner's hand-test gate after seeing the captures.

## Hard rules

- DO NOT modify source code. Capture + audit + commit + report only.
- DO NOT extend XCUITest with new test methods.
- DO NOT edit `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift` — read-only reference for what tests EXIST today; do not add to it. If the existing test methods cover a behavior row, use them; if not, drive by-hand or log as UNATTAINED.
- DO NOT touch `samples/initiative-cross-platform-ui-voyager/screens/` or any Crystal source.
- DO NOT commit captures that show pre-6.12A state (verify the file timestamps are after 6.12A's HEAD `973d32d`).
- DO NOT proceed if pixel-sample on Cascade prominent button FAILS — escalate immediately.
- Standard Claude co-author footer on commits.
- `grep -rE "voyager-(save-chain|interaction-proof)"` must still return 0 (no diagnostic logging leaked).
- If turn budget gets tight, STOP at a coherent boundary + write the report. Better a complete report on partial captures than incomplete report on full captures.
