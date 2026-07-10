# Phase 6.11 — Implementer Brief (revision 2, post-Codex critique)

**Date opened:** 2026-05-23
**Authored by:** Architect; revised after Codex antagonist critique flagged REVISE-THESE-ITEMS on revision 1
**Branch:** `phase-06.11-ios-polish-defaults` (cut from feature branch at `183e59d`, after 6.10 merge)
**Codex protocol:** Per-iteration critique on EVERY iteration (Implementer-side). Architect-side Codex critique on this brief already complete; the critique is reflected in the tightened acceptance criteria below.
**Closing gate:** Owner hands-on verification on iPhone 17 Pro Sim. macOS is OUT OF SCOPE.

---

## Why this phase exists

See `README.md`. Short version: Phase 6.10 hit its brief but owner hand-test surfaced (a) illegible iOS Todos text under the Voyager brand override, (b) functional CRUD gaps. Phase 6.11 drops the brand override (per owner directive) and polishes the Todos CRUD to feel like a real app.

---

## Codex-antagonist findings applied

Brief revision 1 was critiqued by Codex with the verdict REVISE-THESE-ITEMS, citing: (1) item 1 under-bounded (three valid outcomes), (2) item 2 subjective legibility, (3) item 3 ambiguous semantics, (4) hidden assumptions, (5) item 3 not externally testable. Each is addressed below.

---

## Environment assumptions (Codex finding #4)

The Implementer MUST verify these BEFORE writing code:

1. **iPhone 17 Pro simulator exists.** Check:
   ```bash
   xcrun simctl list devices | grep -E "iPhone 17 Pro"
   ```
   If absent, create one:
   ```bash
   xcrun simctl create 'iPhone 17 Pro' com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro com.apple.CoreSimulator.SimRuntime.iOS-26-0
   ```
   (Use whatever iOS-26-x runtime is installed.)
2. **Commit `bb1c825` exists on this branch** (the Save-propagation chain from 6.10 Rem 4). Verify:
   ```bash
   git log --oneline | grep bb1c825
   ```
3. **Sign-in accepts any input that passes regex.** Voyager's Sign-in does NOT auth a backend — any email matching the basic regex + any non-empty password advances. Document in the implementer report; don't add real auth.
4. **State is in-memory only.** `samples/.../voyager/screens/state.cr` is a Crystal struct; no disk persistence. Don't add it.
5. **The diagnostic NSLog grep-token pattern** is documented in `docs/initiative-cross-platform-ui/handoff/phase-06.10-remediation-2-codex-blocker.md` (in this repo). Re-use the pattern as needed; remove all `voyager-*` grep-tokens before final commit.

---

## Scope — 3 items, all must close with concrete acceptance

### 1. Remove Voyager brand override completely

**Codex finding #1:** brief revision 1 allowed delete OR strip OR no-op as valid outcomes. Pick ONE.

**Required final state:**

- **DELETE** `samples/initiative-cross-platform-ui-voyager/brand.cr` entirely (file removed from the working tree, recorded in git as a delete).
- **REMOVE** every reference to `VoyagerBrand` and `with_brand` in `samples/initiative-cross-platform-ui-voyager/`. Verify with:
  ```bash
  grep -rE "VoyagerBrand|with_brand|brand\.cr" samples/initiative-cross-platform-ui-voyager/
  ```
  Must return 0 hits in tracked source.
- **REMOVE** any inline brand color literals (hex `#xxxxxx`, `OKLCH(`, `Color.hex(`) from `samples/.../voyager/screens/*.cr` and `samples/.../voyager/app.cr`. Verify:
  ```bash
  grep -rE "Color\.hex|OKLCH\(0\.42|#[0-9a-fA-F]{6}" samples/initiative-cross-platform-ui-voyager/screens/ samples/initiative-cross-platform-ui-voyager/app.cr
  ```
  Returns 0 hits.
- **DO NOT** add a replacement brand. Voyager runs on `UI::DesignTokens::Tokens.default` only.

**Acceptance evidence:** all three grep commands above return 0 hits, recorded in the implementer report.

### 2. iOS text legibility — WCAG 2.2 AA objective threshold

**Codex finding #2:** "legible" is subjective. Apply WCAG 2.2 AA.

**Pass criteria:**

- Every text element in all 4 screens (Sign-in / Todos / Editor / Settings), in BOTH light + dark appearance, meets WCAG 2.2 AA contrast against its background:
  - Body text (>= 16pt regular): 4.5:1 minimum contrast ratio.
  - Large text (>= 18pt bold or >= 24pt regular): 3:1 minimum.
  - UI components (button labels, icons in controls): 3:1 minimum against their container background.
- **Sampling method:** for each (screen × appearance) capture, identify the 3 text elements most likely to fail (typically: secondary labels on accent-colored surfaces, small label text on tinted rows, placeholder text). Measure contrast via Apple's `Accessibility Inspector → Color Contrast` tool (or a pixel-color-pick + WCAG formula calculation). Record actual ratios in the legibility audit file.
- **System-color shortcut:** if a text element uses `UI::Color.label` / `secondaryLabel` / `tertiaryLabel` on a `UI::Color.systemBackground` / `secondarySystemBackground` etc., it AUTO-PASSES (Apple's semantic colors are pre-validated for WCAG AA in both appearances). Note in audit which elements rely on the shortcut.
- **Custom colors:** any text element using a non-semantic color must be measured + recorded.

**Required evidence artifacts:**

- `docs/initiative-cross-platform-ui/handoff/phase-06.11-evidence/voyager-{signin,todos,editor,settings}-{light,dark}.png` — 8 screenshots, iPhone 17 Pro.
- `docs/initiative-cross-platform-ui/handoff/phase-06.11-evidence/legibility-audit.md` — table with columns: Screen | Appearance | Element | Sampled point | Foreground | Background | Ratio | Pass/Fail | Auto-pass (semantic)?

### 3. Functional Todos polish — concrete behaviors per action

**Codex finding #3:** "feels like a real app" was undefined. Below is the concrete behavior contract.

**Seeded state contract:**

- App launch shows 5 seeded todos (existing state.cr seed): "Buy groceries", "Walk the dog", "Submit timesheet", "Schedule dentist appointment", "Read 30 minutes" (or whatever state.cr currently seeds). At least 2 are completed=true at seed.
- Chart at top of Todos shows: Open count + Completed count from the seed.

**Behavior contract — each row is a testable acceptance + required screenshot:**

| # | Action | Concrete expected behavior | Required screenshots (light + dark) |
|---|---|---|---|
| 1 | Launch app | Sign-in screen renders, 5 seeded todos exist in state | not yet visible — defer to row 4 |
| 2 | Type valid email + any password → tap Sign in | Screen advances to Todos | `voyager-todos-launch-{light,dark}.png` |
| 3 | Tap "Add Todo" | Editor screen opens; title field empty; completed toggle off; Save button is **disabled** (Codex-flagged: blank-title behavior) | `voyager-editor-empty-{light,dark}.png` |
| 4 | Type "Rem 6.11 test" into title field | Save button enables | `voyager-editor-typed-{light,dark}.png` |
| 5 | Tap Save | Editor pops; row "Rem 6.11 test" appears at the top of the list (or in canonical sort order); chart Open count increments by 1; chart Completed count unchanged | `voyager-todos-after-save-{light,dark}.png` |
| 6 | Tap the checkbox / leading toggle on the new "Rem 6.11 test" row | Row's text takes on `.strikethrough` style; row's text color shifts from `.label` to `.secondaryLabel`; chart Open decrements, Completed increments | `voyager-todos-row-completed-{light,dark}.png` |
| 7 | Swipe the same row left | Edit + Delete trailing actions revealed | `voyager-todos-swipe-revealed-{light,dark}.png` |
| 8 | Tap Edit (on the revealed action) | Editor opens prefilled: title = "Rem 6.11 test", completed = on | `voyager-editor-edit-prefilled-{light,dark}.png` |
| 9 | Change title to "Rem 6.11 edited" → Save | Editor pops; row updates IN-PLACE to "Rem 6.11 edited"; chart counts unchanged | `voyager-todos-after-edit-{light,dark}.png` |
| 10 | Swipe the row left → Tap Delete | Row removes from list; chart Completed count decrements by 1 | `voyager-todos-after-delete-{light,dark}.png` |
| 11 | Tap Settings link | Settings screen opens with "Hide completed" toggle off | `voyager-settings-default-{light,dark}.png` |
| 12 | Tap "Hide completed" toggle ON | Toggle visually flips to on | `voyager-settings-toggled-{light,dark}.png` |
| 13 | Tap back | Todos screen: rows with completed=true are visually omitted; chart Open count unchanged; chart Completed count shown but visually dimmed (or marked filtered) | `voyager-todos-filtered-{light,dark}.png` |
| 14 | Navigate Settings → toggle off → back | Completed rows re-appear; chart returns to undimmed state | `voyager-todos-unfiltered-{light,dark}.png` |

**Edge-case contract (Codex-flagged):**

- **Blank title:** Save button disabled while title is empty. (Row 3 confirms.)
- **Whitespace-only title:** treated as blank — Save disabled.
- **No-op save (open editor, change nothing, tap Save):** if Save was reached (means title is non-empty), it's accepted as-is — no error. List shows the row unchanged.
- **Discard / Cancel:** if the Editor has a Cancel / Back button, tapping it returns to Todos without saving. State unchanged. (If no Cancel exists, this behavior isn't required.)

**Each screenshot pair (light + dark) goes under `phase-06.11-evidence/`. The implementer report must include a table mapping the 14 rows to their captured artifacts.**

---

## Codex protocol (Layer 2 — Implementer side)

Every code-touching iteration gets a real Codex review at `handoff/phase-06.11-codex-N.md`. Self-assessment is NOT acceptable.

If Codex times out: retry. If twice on same iteration: STOP, write `handoff/phase-06.11-codex-blocker.md`, escalate to architect.

---

## Build + verification commands

```bash
crystal spec

# Voyager iOS build (iPhone 17 Pro)
make -C samples/initiative-cross-platform-ui-voyager ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'

# Boot + install + launch
DEVICE=$(xcrun simctl list devices booted | awk '/iPhone 17 Pro/ {print $NF; exit}' | tr -d '()')
APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app | head -1)
xcrun simctl install "$DEVICE" "$APP_PATH"
xcrun simctl launch "$DEVICE" com.assetpipeline.voyager.VoyagerDemo

# Appearance toggle
xcrun simctl ui "$DEVICE" appearance light
xcrun simctl ui "$DEVICE" appearance dark

# Screenshot
xcrun simctl io "$DEVICE" screenshot /tmp/voyager.png

# Log capture (for diagnostic NSLog patterns; remove tokens before final commit)
xcrun simctl spawn "$DEVICE" log stream --predicate 'process == "VoyagerDemo"' --level=debug
```

---

## Acceptance you must meet before reporting done

- `crystal spec` baseline 1497/4/0 preserved (or improved).
- `make -C samples/.../voyager ios IOS_DEST='platform=iOS Simulator,name=iPhone 17 Pro'` exits 0.
- The 3 grep checks in Item 1 each return 0 hits in tracked source.
- 28 screenshots captured (14 behavior rows × light + dark) under `phase-06.11-evidence/`.
- `legibility-audit.md` table populated per Item 2 specification.
- Implementer report at `handoff/phase-06.11-implementer-report.md` includes the behavior-to-artifact mapping table.
- Every code-touching iteration has a real Codex review committed.
- `grep -rE "voyager-(save-chain|interaction-proof)"` in tracked source returns 0 hits.

## Reporting

Return to architect with: branch HEAD SHA, commit count, per-item status with grep-check outputs, evidence paths, hand-test commands, any open uncertainty. Do NOT declare the phase passed — architect's call after owner hand-test.

## Hard rules

- Forward commits only on `phase-06.11-ios-polish-defaults`.
- No scope expansion or unilateral narrowing — STOP and escalate.
- No declaring item PASS without proof artifacts.
- Standard Claude co-author footer on every commit.
- macOS work is OUT OF SCOPE — don't touch `appkit_renderer.cr` or `samples/.../voyager/macos/`.
- Path B (raw UIButton) still forbidden.
- If any of the 14 behaviors can't be made to work with the current library, STOP and escalate (don't paper over with mock data or static views).
