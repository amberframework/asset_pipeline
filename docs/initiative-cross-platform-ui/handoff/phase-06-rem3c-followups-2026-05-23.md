# Phase 6 Rem 3-completion — follow-ups handoff (2026-05-23)

Dispatched by: Implementer Remediation 3-completion agent.
Branch: `phase-06-side-by-side-demo-app` (HEAD = `4b9c820`).
Prior commit: `cbe7351`. Range added this dispatch: `e64de96` → `4b9c820`
(5 commits).

This dispatch shipped:

  - Fix 1: iOS ScrollView wrapper around CascadeHost (`e64de96`).
  - Fix 2: Sign-in primary button uses `ButtonStyle::Prominent`
    (`dcd4334`).
  - Fix 3: Font (size + weight) propagation Crystal → SwiftKit →
    SwiftUI `Text.font(.system(size:weight:))` (`10551f7`).
  - Fix 4: Re-captured iOS + macOS sign-in baselines (`4b9c820`).

Visual outcomes confirmed:

  - macOS sign-in (light + dark): "Cascade" wordmark renders bold
    34pt display weight — was body 17pt regular before.
  - iOS sign-in (light + dark): same wordmark improvement.
  - macOS sign-in: "Sign in" button visible as gray
    `.borderedProminent` pill.
  - iOS sign-in (dark): "Sign in" label visible centered as white
    text below Password — was invisible before.
  - iOS sign-in (light): "Sign in" label is black text on white
    card. Visibility is technically present but chrome contrast is
    poor.

## Residual gaps for a follow-up dispatch

### 1. SwiftUI `.borderedProminent` tint not reaching the Sign-in button

The Phase 6 brand override sets accent / brand-tint to teal via the
SwiftUI environment. But the `.buttonStyle(.borderedProminent)` on the
hosted Sign-in button renders un-tinted (gray on macOS, default-system
on iOS). HIG defines `.borderedProminent` as the filled accent-color
CTA; without the accent cascade reaching the SwiftUI Button scope we
get a flat pill on macOS and an under-decorated text-only button on
iOS-light.

Likely fixes (one or more):

  - In `ButtonFacade.swift`, when `overrides.style == "prominent"`,
    additionally apply `.tint(<brand-accent-color>)` on the button.
    This requires plumbing the brand accent color through
    `ButtonOverrides` (today only `backgroundColor` /
    `foregroundColor` / `cornerRadius` are available — none of them
    map to the SwiftUI `.tint()` modifier scope which is what
    `.borderedProminent` consults).
  - Alternatively: route the Phase 6 brand override's accent color
    into a top-level `.tint()` cascade at the SwiftUI host root
    (Cascade root view) so every nested borderedProminent button
    inherits it via the environment.

Recommended approach: top-level `.tint()` cascade. Smaller surface,
matches how SwiftUI is meant to be configured. The brand override
ContentView wrapper in `samples/initiative-cross-platform-ui-demo/ios/
Sources/ContentView.swift` would apply `.tint(Color(...))` from the
demo's brand_tokens — and the macOS host's host.cr equivalent would
need the same.

### 2. iOS-light low-contrast Sign-in chrome

On iOS in light appearance, `.borderedProminent` renders as black
label text on the white card with no visible fill. This is
SwiftUI's "no accent in scope" fallback. Fixing residual gap #1
(top-level `.tint()` cascade) should fix this automatically — the
borderedProminent fill resolves against the active tint.

### 3. macOS Sign-in button width not honoring content_width pin

The Crystal source sets `primary.minimum_width = 340.0` and
`primary.maximum_width = 340.0`. The macOS sign-in baseline shows
the rendered Sign-in pill at ~80pt wide, NOT 340pt. This matches the
known Rem 2 "card stretch / button shrink" pattern that's been a
long-running issue: SwiftUI's intrinsic Button content size wins
over the min/max width pin in some hosting-controller layout paths.

Likely fix: in `ButtonFacade.swift`, when `minWidth` is set, apply
`.frame(width:)` (exact) instead of `.frame(minWidth:)`. The
exact-frame approach matches what BX9 did for `minHeight`. Today the
code applies `minWidth` only:

```swift
if let mw = overrides.minWidth {
    let mwCG = CGFloat(mw.doubleValue)
    base = AnyView(base.frame(minWidth: mwCG))
}
```

Should become (when `maxWidth == minWidth`):

```swift
if let mw = overrides.minWidth, let mxw = overrides.maxWidth,
   mw.doubleValue == mxw.doubleValue {
    base = AnyView(base.frame(width: CGFloat(mw.doubleValue)))
} else if let mw = overrides.minWidth {
    base = AnyView(base.frame(minWidth: CGFloat(mw.doubleValue)))
}
```

The same fix probably belongs on the equivalent
TextField / SecureField facade chain, but those are already pinned
via the upstream stack constraints, so only Button is affected here.

### 4. Social buttons styled as bordered, not brand-accented

Lower priority. The Apple / Google / Email social-auth row buttons
in sign_in.cr have `role = :secondary`. The populator emits
`setRole: "secondary"` and the ButtonFacade has no case for
`"secondary"` (only `destructive` and `cancel`). They render as
system-bordered pills. If the Phase 6 brand identity wants social
buttons styled with brand chrome, add an explicit
`style: UI::ButtonStyle::Bordered` (already the default) or
`Tinted`, OR teach ButtonFacade to switch on `"secondary"` to
apply something like `.tint(.secondary)` cascade. Cosmetic, defer.

## Verification

Build closures after this dispatch:

  - `crystal spec`: 1455 / 4 failures / 0 errors. The 4 failures
    pre-date this dispatch (theme web renderer + 3 phase2
    verification). The +1 over the prior 1454 is the new
    `populate_label` font-override spec I added in `10551f7`.
  - `crystal spec spec/ui/design_tokens/material_spec.cr`: 31 / 0 / 0.
  - `swift build -c release` (AssetPipelineSwiftKit): exit 0.
  - `make -C samples/initiative-cross-platform-ui-demo macos`: exit 0,
    binary at samples/initiative-cross-platform-ui-demo/macos/bin/
    cascade.
  - `make -C samples/initiative-cross-platform-ui-demo ios`: exit 0,
    CascadeDemo.app at Xcode DerivedData.
  - Sign-in screen quad capture: `crystal-alpha run
    scripts/capture_demo_quad.cr -- --surfaces macos,ios --slugs
    demo-sign-in` exit 0; 4 PNGs written.

Stay on branch `phase-06-side-by-side-demo-app`; do not merge or push.
