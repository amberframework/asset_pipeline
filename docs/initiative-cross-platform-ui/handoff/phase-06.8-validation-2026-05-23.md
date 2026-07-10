# Phase 6.8 Validation — Visual Polish Deferrals

**Date:** 2026-05-23
**Validator:** independent half of the Phase 6.8 trust-pair
**Branch:** `phase-06.8-visual-polish-deferrals`
**Commit range checked:** `afb7791..3faab95` (5 commits from architect handoff to current HEAD)

## Verdict

**PASS**

All 3 fixes land cleanly. All regression baselines hold (`crystal spec`
1455/4/0, material spec 31/0, swift build exit 0, all 3 demo builds exit
0, all 3 audit harness I-1 probes PASS). The iOS Sign-in button is
clearly visible and rendered in brand teal — the Phase 6 Rem 4 + Rem 5
regression mode did NOT recur. Diff scope is exactly what the brief
allowed: `ButtonFacade.swift` (+38/-4) and the 4 sign-in baselines (iOS
+ macOS, light + dark). No other code or baseline files were touched.

The brief validator exits non-zero on a single
`repo_derived_facts` drift (ButtonFacade.swift went 283 → 317 lines after
the 3 fixes). Per the Validator brief, this is an expected architect
amendment and not a blocker for PASS.

## Commit range

```
e5ebec3  [Phase 6.8 Fix 1] ButtonFacade: bypass .borderedProminent with explicit Capsule.fill(brandTeal) for prominent style
290ed34  [Phase 6.8] Recapture iOS sign-in baselines after Fix 1
524cdd1  [Phase 6.8 Fix 2] ButtonFacade: exact frame(width:) when min_w==max_w + prominent; macOS button now 340pt brand-teal pill
d5edf4f  [Phase 6.8 Fix 3] ButtonFacade: map :secondary role to .bordered chrome
3faab95  [Phase 6.8] Recapture iOS sign-in baselines after Fix 3
```

## Per-fix verification

### Fix 1 — brand-teal Capsule.fill bypass — PASS

**Source verification:** `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift`
lines 158–174. The `case "prominent":` branch no longer calls
`.buttonStyle(.borderedProminent)`. Instead it applies:

```
let brandTeal = Color(red: 0.012, green: 0.521, blue: 0.521)
content = AnyView(
    content
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(Capsule().fill(brandTeal))
)
```

`Color(red: 0.012, green: 0.521, blue: 0.521)` in sRGB is approximately
RGB (3, 133, 133) which matches the brand-teal target `#038585`.

**Visual citation (iOS light):** `magick identify` sampled the Sign-in
button at multiple points (1206×2622 baseline):

```
btn_left  (100,1660) = srgb(3,133,133)
btn_center(300,1660) = srgb(3,133,133)
btn_mid   (600,1660) = srgb(3,133,133)
btn_right (1100,1660)= srgb(3,133,133)
```

EXACT match to brand-teal `#038585`. NOT system blue.

**Visual citation (iOS dark):**
`docs/initiative-cross-platform-ui/baselines/ios/demo-sign-in-dark.png` —
Sign-in button is a clearly visible brand-teal pill on the black
background, white "Sign in" label still legible.

**Verdict:** Fix 1 lands correctly on both light and dark iOS.

### Fix 2 — macOS exact-width pin when min_w == max_w + prominent — PASS

**Source verification:** `ButtonFacade.swift` lines 125–139. The minWidth
branch now contains the conditional:

```
if let mxw = overrides.maxWidth, mw.doubleValue == mxw.doubleValue,
   overrides.style == "prominent" {
    base = AnyView(base.frame(width: mwCG))      // Fix 2: exact
} else {
    base = AnyView(base.frame(minWidth: mwCG))   // unchanged
}
```

The exact `.frame(width:)` is only applied when min_w == max_w AND style
is "prominent" — matches the brief's contract exactly.

**Visual citation (macOS light):** Sampled the Sign-in button row at
y=820 across 1440px canvas:

```
btn_at_50   = srgba(58,131,132,1)   # teal pill
btn_at_400  = srgba(91,148,149,1)   # teal pill (over Sign-in label)
btn_at_700  = srgba(58,131,132,1)   # teal pill
btn_at_800  = srgba(0,0,0,0)        # transparent (outside button)
```

The Sign-in button spans roughly x=50..~700 — same horizontal range as
the email field which spans roughly x=0..~680 (sampled at y=330). The
button width pin is honored — button matches the email/password field
width.

**Visual citation (macOS dark):** baseline shows the Sign-in button
extending across the same horizontal range as the email/password fields
above it. The width pin is visually confirmed.

**Verdict:** Fix 2 lands correctly.

### Fix 3 — :secondary role → .bordered chrome — PASS

**Source verification:** `ButtonFacade.swift` lines 190–200. The fix is
implemented as a post-switch role check, NOT a new case in the style
switch — exactly as the Implementer's report noted:

```
if overrides.role == "secondary" && overrides.style == nil {
    content = AnyView(content.buttonStyle(.bordered))
}
```

The `&& overrides.style == nil` guard ensures app code that sets an
explicit style alongside `:secondary` still wins, which is appropriate
defensive coding.

**Visual citation (macOS light):** the Apple / Google / Email social-row
buttons at the bottom of the macOS sign-in baseline render with the
canonical `.bordered` chrome — rounded grey outlined buttons with dark
labels. NOT default flat text.

**iOS social row:** the iOS sign-in baselines crop above the social row
on the visible portion of the captured screen — the social row is below
the visible region of the 2622px-tall capture. This is consistent with
the Implementer's report (pre-existing layout issue, not a Fix 3
regression). The Fix 3 mapping itself is verified in source and on
macOS.

**Verdict:** Fix 3 lands correctly on macOS. iOS social-row visibility
is pre-existing-layout, not a Fix 3 concern.

## iOS Sign-in button NOT regressed (CRITICAL)

The Phase 6 Rem 4 + Rem 5 nightmare was the iOS Sign-in button going
invisible. This regression mode did NOT recur.

- `docs/initiative-cross-platform-ui/baselines/ios/demo-sign-in-light.png`
  shows a fully visible Sign-in button rendered in brand teal (sampled
  pixel RGB exactly `3, 133, 133`).
- `docs/initiative-cross-platform-ui/baselines/ios/demo-sign-in-dark.png`
  shows the Sign-in button as a brand-teal pill on the black dark-mode
  surface with the white "Sign in" label clearly legible.
- The audit harness `I-1 ios demo-sign-in` probe (which runs the real
  XCUITest visual snapshot via xcodebuild) returns **PASS** in 22892ms.

The button-visibility invariant holds.

## Regression baseline results

| Check | Result | Notes |
|-------|--------|-------|
| `crystal spec` | 1455 examples / 4 failures / 0 errors / 66 pending | Matches Phase 6 close-out baseline. 4 failures are the same pre-existing failures (3 phase-2 verification + 1 theme css). |
| `crystal spec spec/ui/design_tokens/material_spec.cr` | 31/0/0 | Matches expected. |
| `swift build -c release --package-path swift/AssetPipelineSwiftKit` | exit 0 | Build complete in 1.25s. |
| `make -C samples/initiative-cross-platform-ui-demo web` | exit 0 | 11 files written. |
| `make -C samples/initiative-cross-platform-ui-demo macos` | exit 0 | No work needed (up to date). |
| `make -C samples/initiative-cross-platform-ui-demo ios` | exit 0 | BUILD SUCCEEDED. |
| `audit_harness_smoke.sh I-1 ios demo-sign-in` | PASS (22892ms) | XCUITest visual snapshot pass. |
| `audit_harness_smoke.sh I-1 macos demo-sign-in` | PASS (1582ms) | macOS visual diff pass. |
| `audit_harness_smoke.sh I-1 web demo-sign-in` | PASS (5143ms) | Web visual diff pass. |

## Brief validator

```
crystal run scripts/validate_phase_brief.cr -- docs/initiative-cross-platform-ui/phases/phase-06.8-visual-polish-deferrals/brief.yml
```

Exits **2** on the single fact drift:

> FAIL[2]: Fact 'ButtonFacade.swift line count (pre-impl baseline;
> sanity check Phase 6.8 doesn't bloat)' DRIFTED. Expected: "283".
> Actual: "317".

317 - 283 = +34 lines. This is the expected delta from the 3 fixes
(Capsule.fill prominent block + width-pin conditional + secondary-role
check). Per the Validator brief: this is an architect amendment, NOT a
Validator concern. The "no bloat" fact was a pre-impl sanity check that
the implementation phase is expected to invalidate when the architect
amends the brief at close-out.

All other facts verified clean: invariant_matrix structure valid (11
rows, all platform cells present, no placeholders), top-level keys
recognized, phase section structure valid.

## Diff scope check

```
git diff --stat afb7791..3faab95
 .../baselines/ios/demo-sign-in-dark.png            | Bin 117248 -> 114143 bytes
 .../baselines/ios/demo-sign-in-light.png           | Bin 121646 -> 118638 bytes
 .../baselines/macos/demo-sign-in-dark.png          | Bin 70800 -> 73239 bytes
 .../baselines/macos/demo-sign-in-light.png         | Bin 68246 -> 70779 bytes
 .../Facades/ButtonFacade.swift                     |  42 +++++++++++++++++++--
 5 files changed, 38 insertions(+), 4 deletions(-)
```

EXACTLY the brief-allowed scope:
- `ButtonFacade.swift` (+38/-4)
- 4 sign-in baselines (iOS light + dark, macOS light + dark)

No changes to `src/ui/`, `src/ui/design_tokens/`, other Swift files,
Crystal renderers, demo source code, or any other baseline.

Non-sign-in baselines untouched: ran
`git diff --name-only afb7791..3faab95 | grep -E 'baselines/(ios|macos|web-desktop|web-mobile)/demo-(dashboard|detail|settings|tier-three)'`
which returned empty (grep exit 1). The dashboard, detail, settings, and
tier-three baselines on all 4 surfaces remain frozen at their
pre-Phase-6.8 state.

## Findings

1. **All 3 fixes are present, scoped correctly, and visually verified.**
   Fix 1's brand-teal Capsule.fill applied. Fix 2's exact-width pin
   conditional applied. Fix 3's post-switch role check applied (NOT a
   new switch case — matches the Implementer's analysis that
   `:secondary` arrives as a role, not a style).
2. **iOS pixel-sampling proves exact brand-teal `#038585` rendering.**
   Sampling at multiple x-coordinates across the iOS-light Sign-in
   button returned `srgb(3,133,133)` consistently — the brand-teal
   target from `UI::DesignTokens` brand_primary.
3. **macOS width pin is correctly honored.** The Sign-in button on
   macOS spans roughly the same horizontal range as the email/password
   fields above it (sampled at the button row vs the field row).
4. **macOS social-row `.bordered` chrome confirmed.** Apple / Google /
   Email buttons render with the canonical SwiftUI bordered chrome.
5. **iOS Sign-in button visibility preserved.** The regression mode
   from Phase 6 Rem 4 + Rem 5 (invisible Sign-in button) did NOT recur.
6. **Diff scope is minimal and on-contract.** Only ButtonFacade.swift
   and 4 sign-in baselines touched. No Crystal-side changes were
   required.
7. **Brief validator drift is expected** (ButtonFacade.swift +34
   lines for 3 fixes) and explicitly anticipated by the Validator
   brief.
8. **Crystal spec stable** at 1455/4/0 (same 4 pre-existing failures
   from Phase 6 close-out).
9. **All 3 audit-harness I-1 probes PASS** including the real
   xcodebuild iOS test.
10. **Codex co-pilot revert-and-continue protocol was honored.** The
    commit log shows Fix 1 → recapture iOS → Fix 2 → Fix 3 → recapture
    iOS, with no reverts needed (all 3 fixes passed Codex per-fix
    checks). No fix had to be reverted — clean run.

## Recommendation

**PASS Phase 6.8.** Tag as `phase-06.8-pass-2026-05-23` and proceed to
Phase 7 baselining against the post-6.8 state.

One small follow-up to capture in a future iteration (not a Phase 6.8
blocker):

- The iOS sign-in social row (Apple / Google / Email) is not visible
  within the 1206×2622 capture region. This is a pre-existing layout
  scrim, not a Fix 3 regression — Fix 3 itself is verified visible on
  macOS where the row is rendered above the fold. A future scoped pass
  could investigate iOS bottom-content visibility (likely a sheet/scroll
  inset issue independent of ButtonFacade).
