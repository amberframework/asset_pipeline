# Phase 6.12C — Cascade Prominent-Button Brand Regression Investigation + Fix

**Date opened:** 2026-05-24
**Authored by:** Architect (Codex-critique before dispatch)
**Branch:** `phase-06.12-library-identity-macos-polish` (continue from `62da2c53` + Cascade evidence commit)
**Codex protocol:** Per-iteration critique on every code-touching iteration. Self-assessment NOT acceptable.

---

## Why this iteration exists

Phase 6.12B's capture agent reached Priority 1A and confirmed empirically: **Cascade macOS prominent Sign-in button no longer renders deep teal — it renders light gray.** Phase 6.11 iter-4 removed the `Capsule.fill(brandTeal)` workaround in `ButtonFacade.swift` case "prominent" because Path A (Phase 6.10 VC parenting) had made it obsolete for the SwiftUI Button tap chain. But that workaround was ALSO masking a separate macOS-specific quirk: `.borderedProminent` on macOS uses the system accent color regardless of `.tint()` set in the SwiftUI environment.

Evidence committed at `phase-06.12b-evidence/cascade-macos-prominent-button-{light,dark}.png`. The Forgot-password link IS teal in the same screenshot (so `.tint()` cascades to `.bordered`/`.borderless` chrome), but the prominent button isn't.

This is a Cascade-specific regression because Cascade applies a custom brand. Voyager (which uses `Tokens.default` = `Color::SYSTEM_ACCENT` after Phase 6.12A) is unaffected — its prominent buttons correctly resolve to system blue.

Phase 6.12C investigates the macOS `.borderedProminent` × `.tint()` interaction empirically + picks a fix that:
- Restores Cascade's deep teal prominent button on macOS.
- Does NOT regress Voyager's system-blue prominent button.
- Does NOT restore the original hardcoded brand-teal `Color(red: 0.012, ...)` literal (that was Phase 6.8 broken-by-design; Phase 6.11 iter-4 correctly removed it).

---

## Item 1 — Empirical investigation of macOS `.borderedProminent` × `.tint()`

Before any fix lands, the Implementer runs a minimal investigation:

1. **Write a 10-line SwiftUI test app** (NOT shipped — investigation only) inside `samples/initiative-cross-platform-ui-demo/scratch/probe.swift`:
   ```swift
   import SwiftUI
   struct ProbeView: View {
     var body: some View {
       VStack {
         Button("System blue prominent") {}.buttonStyle(.borderedProminent)
         Button("Tinted teal prominent") {}.buttonStyle(.borderedProminent).tint(Color(red: 0.059, green: 0.522, blue: 0.522))
         Button("Tinted teal bordered") {}.buttonStyle(.bordered).tint(Color(red: 0.059, green: 0.522, blue: 0.522))
       }.padding()
     }
   }
   ```
2. **Run in a SwiftUI macOS app harness** (smallest viable Xcode project OR `swift run` against a tiny target). Screenshot the result.
3. **Determine empirically:** does `.tint()` apply to `.borderedProminent` on macOS?
4. If NO: confirm by reading Apple's SwiftUI documentation citations. Document at `handoff/phase-06.12c-probe-findings.md`.
5. If YES: the regression has a different cause — escalate (the ButtonFacade removal may have broken something else).

**Acceptance — Item 1:**
- `phase-06.12c-probe-findings.md` documents the empirical behavior + Apple-doc citations.
- Architect-readable conclusion: "macOS .borderedProminent ignores .tint()" OR "macOS .borderedProminent respects .tint()."

---

## Item 2 — Fix path (architect-decided based on Item 1 findings)

The implementer reports Item 1's findings + waits for architect direction BEFORE applying a fix. Possible fix paths (the architect picks based on probe evidence):

### Path A — Custom `Capsule.fill` chrome on macOS only (NAIVE — see Path A-prime)

In `ButtonFacade.swift case "prominent":`, branch:
```swift
case "prominent":
#if os(macOS)
  if let activeTint = APSKRuntime.brandTint {
    content = AnyView(content
      .foregroundStyle(.white)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background(Capsule().fill(activeTint))
      .buttonStyle(.plain))
  } else {
    content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
  }
#else
  content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
#endif
```

**Why this is better than the Phase 6.8 original:**
- Conditional on PLATFORM (only macOS).
- Conditional on `APSKRuntime.brandTint != nil` (only when a custom brand is active — Voyager with SYSTEM_ACCENT gets plain `.borderedProminent`).
- Reads the live tint, no hardcoded color.

### Path A-prime — Reusable macOS `ButtonStyle` (RECOMMENDED, per Codex)

Codex critique noted: the naive `Capsule.fill` snippet (Path A) flattens
native pressed / disabled / focus / high-contrast state visuals. The
correct fix preserves them by implementing a real SwiftUI `ButtonStyle`:

```swift
#if os(macOS)
struct APSKBrandProminentButtonStyle: ButtonStyle {
  let tint: Color
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.body.weight(.semibold))
      .foregroundStyle(.white)
      .padding(.vertical, 8)
      .padding(.horizontal, 16)
      .background(
        Capsule()
          .fill(configuration.isPressed ? tint.opacity(0.85) : tint)
      )
      .opacity(configuration.isPressed ? 0.95 : 1.0)
      .overlay(
        // Focus ring respects accent-color from environment when present
        Capsule().stroke(Color.accentColor.opacity(0.0), lineWidth: 3)
      )
      .accessibilityAddTraits(.isButton)
  }
}
#endif

// In case "prominent":
#if os(macOS)
  if let activeTint = APSKRuntime.brandTint {
    content = AnyView(content.buttonStyle(APSKBrandProminentButtonStyle(tint: activeTint)))
  } else {
    content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
  }
#else
  content = AnyView(content.controlSize(.large).buttonStyle(.borderedProminent))
#endif
```

This preserves:
- Pressed state (configuration.isPressed darkens the background).
- Disabled state (handled by SwiftUI's `.disabled()` modifier — applies automatically because we read `.foregroundStyle(.white)` which honors disabled-color cascades).
- Focus state (overlay stroke with `Color.accentColor` — TODO confirm Apple's exact accessibility focus-ring pattern in the probe).
- High-contrast accessibility setting (TODO confirm via `@Environment(\.colorSchemeContrast)` in the probe).

The Implementer's Item 1 probe MUST measure pressed/disabled/focus/high-contrast states in the live SwiftUI test app + document whether the proposed ButtonStyle covers them. If state coverage is incomplete, the brief is REVISE-AGAIN — the fix must preserve native button state semantics.

### Path B — Manual macOS `NSButton`-style override

Use AppKit's `NSButton.bezelStyle` + `NSButton.contentTintColor` instead of SwiftUI's `.borderedProminent`. Larger Swift change.

### Path C — Accept gray as documented platform difference

If the SwiftUI quirk is genuinely undocumented behavior we can't reliably work around, document that custom-brand prominent buttons on macOS render with the system accent. Cascade developers either accept this OR use a different style. **Loses brand cascade promise.**

### Path D — SwiftUI .controlSize hack

Some Apple-platform engineering blogs suggest `.controlSize(.large)` + `.tint()` works on certain macOS versions. If Item 1 shows this works on macOS 14+ (our minimum), it might be a one-knob fix.

**Recommend Path A-prime (reusable ButtonStyle) as the default if Item 1 confirms macOS quirk + the ButtonStyle covers pressed/disabled/focus/high-contrast states.** Path A is too naive per Codex. Path B is heavier. Path C loses brand promise. Path D is the lightest if it works on macOS 14+.

---

## Item 3 — Apply chosen fix + verify

After architect approves the fix path:
1. Apply the change in `swift/.../Facades/ButtonFacade.swift`.
2. Rebuild Cascade macOS: `make -C samples/initiative-cross-platform-ui-demo cascade-macos`.
3. Re-screenshot at `phase-06.12c-evidence/cascade-macos-prominent-button-{light,dark}-fixed.png`.
4. Pixel-sample the button background: `python3 /tmp/wcag_sample.py <png> <btn_x> <btn_y>`. Confirm `(15, 133, 133) ± 15` per channel.
5. Rebuild Voyager macOS: `make -C samples/initiative-cross-platform-ui-voyager macos`.
6. Re-screenshot Voyager Sign-in at `phase-06.12c-evidence/voyager-macos-signin-after-fix.png`.
7. Pixel-sample Voyager's Sign-in button. Confirm it is NOT teal (must be system blue or system gray, NOT (15, 133, 133)).
8. **Add assertion (per Codex)** that Voyager's `APSKRuntime.brandTint == nil` at render time, since Voyager uses `SYSTEM_ACCENT`. Phase 6.12A Item 2 wired this clearing — verify it actually happens. Test seam: instrument `APSKRuntime.brandTint` access via a logging or test-mode hook to confirm the value is nil during Voyager's render path. If `brandTint` is unexpectedly non-nil for Voyager, ESCALATE — the SYSTEM_ACCENT clearing path is broken.
8. Run `crystal spec` — baseline 1529/4/0 must hold.

**Acceptance — Item 3:** all 4 captures present, Cascade teal pixel-sample passes, Voyager system-blue (not teal) pixel-sample passes, spec baseline preserved.

---

## Item 4 — Codex review of the fix

```bash
codex exec --skip-git-repo-check "Review the Phase 6.12C fix at swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift (the case 'prominent' branch). Verify: (1) macOS-only conditional protects Voyager (which uses SYSTEM_ACCENT) from regression; (2) reads APSKRuntime.brandTint at render time so a brand swap mid-session takes effect; (3) the iOS branch unchanged from Phase 6.11 iter-4; (4) no hardcoded color literal restored. Verdict per item: PASS/FAIL. Overall: APPROVE / REVISE."
```

Save to `handoff/phase-06.12c-codex-1.md`.

---

## Hard rules

- Forward commits only.
- DO NOT restore Phase 6.8 hardcoded `Color(red: 0.012, green: 0.521, blue: 0.521)` literal. Use the live `APSKRuntime.brandTint` value.
- DO NOT make the fix non-conditional. iOS must continue to use stock `.borderedProminent` (Voyager system-blue path).
- Standard Claude co-author footer.
- If Item 1 investigation shows `.tint()` DOES apply on macOS, STOP and escalate — the regression has a different cause.
- The Implementer DOES NOT apply Items 2/3 until the architect reviews Item 1 findings + approves a fix path.

## Reporting

Write `handoff/phase-06.12c-implementer-report.md` covering per-item status (1-4), commit SHAs, Codex verdict, evidence paths, hand-test commands.

Return to architect with: branch HEAD SHA, Item 1 findings, proposed fix path, all evidence paths. Architect approves the fix BEFORE merge to feature branch.
