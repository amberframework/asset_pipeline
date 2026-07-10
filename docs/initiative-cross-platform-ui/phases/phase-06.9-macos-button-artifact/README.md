# Phase 6.9 — macOS Button Inner-Rectangle Artifact

**Inserted:** 2026-05-23, immediately after Phase 6.8 PASS.
**Dependencies:** Phase 6.8 PASS (tag `phase-06.8-pass-2026-05-23`).
**Blocks:** Phase 7 (preferably; cleaner baselines for CI gating).

## Scope

Phase 6.8's Fix 1 (Capsule.fill bypass) ships brand-teal pill chrome
that looks clean on iOS but has a minor cosmetic artifact on macOS:
SwiftUI's default Button label rendering shows a smaller darker
rectangle inside the larger brand-teal Capsule. Documented in commit
`524cdd1` and the Phase 6.8 reflection.

Phase 6.9 closes this single artifact.

## The fix

In `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift`,
the `case "prominent":` block applies:
```swift
content
    .foregroundStyle(.white)
    .padding(.vertical, 10)
    .padding(.horizontal, 20)
    .background(Capsule().fill(brandTeal))
```

But SwiftUI on macOS adds its own default button-style chrome over the
label, which shows through as a smaller darker rectangle inside the
Capsule. Fix: append `.buttonStyle(.plain)` to suppress SwiftUI's
default chrome:
```swift
content
    .foregroundStyle(.white)
    .padding(.vertical, 10)
    .padding(.horizontal, 20)
    .background(Capsule().fill(brandTeal))
    .buttonStyle(.plain)
```

`.buttonStyle(.plain)` tells SwiftUI not to draw any default chrome on
the Button — only the explicit `.background` modifier provides the pill
fill. This is the canonical SwiftUI pattern for fully-custom button
chrome.

## Out of scope

- iOS Sign-in button (Fix 1 already renders cleanly on iOS — no artifact).
- macOS button width pin (Phase 6.8 Fix 2 already landed correctly).
- :secondary chrome (Phase 6.8 Fix 3 already landed correctly).
- Any other ButtonFacade behavior.

## Acceptance

1. macOS sign-in baseline at `docs/initiative-cross-platform-ui/baselines/macos/demo-sign-in-light.png`:
   - Sign-in button renders as a clean brand-teal Capsule fill with
     white "Sign in" label — NO inner darker rectangle visible.
2. macOS sign-in dark baseline: same property.
3. iOS Sign-in button still renders brand-teal pill (Phase 6.8 Fix 1
   not regressed).
4. Sign-in button still respects 340pt width (Phase 6.8 Fix 2 not
   regressed).
5. Social-row buttons still render with bordered chrome (Phase 6.8
   Fix 3 not regressed).
6. Brief validator exits 0.
7. Regression baselines clean (crystal spec 1455/4/0; material spec
   31/0; all 4 build closures exit 0).

## Anticipated work size

~2 commits: ButtonFacade.swift one-line addition + macOS sign-in
baseline re-capture. Codex check after the fix to confirm the artifact
is gone AND iOS isn't regressed.
