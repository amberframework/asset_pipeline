# Cascade — Phase 6 cross-platform demo app

A single Crystal source tree that compiles to web (static HTML), macOS
(AppKit `.app`), and iOS (UIKit simulator `.app`). Built to be the
litmus test for the cross-platform UI initiative: open the
`quad-comparison.html` page next to the iOS simulator and the macOS
window, and the same brand should be immediately recognizable across
all four surfaces.

The brand override in `brand.cr` deliberately picks a deep teal
(OKLCH(0.56, 0.13, 195)) — distinct from the default amber hue family —
so the "brand override works" claim is visually demonstrable.

## Screens

| Slug | What it shows |
|------|---------------|
| `demo-sign-in` | Brand wordmark, email + password fields, primary button, social-auth row |
| `demo-dashboard` | 3-tab TabView (cards / list / profile) |
| `demo-detail` | Hero placeholder, title, body, action buttons |
| `demo-settings` | Toggles, picker, segmented control, slider, color picker, button row |
| `demo-tier-three` | `ActionSheetWithWebFallback`, `ContextMenuWithWebFallback`, `PathControlWithWebFallback` |

## Build targets

```
make web      # writes output/initiative-demo/*.html (one per screen + quad-comparison.html)
make macos    # builds samples/initiative-cross-platform-ui-demo/macos/bin/cascade
make ios      # generates and builds the iOS simulator app
make all      # all three
```

The Makefile mirrors the build patterns from `samples/cross_platform/`:
- macOS: `objc_bridge.o` + `swiftkit_bridge.o` + Swift release link + `crystal-alpha build -Dmacos`.
- iOS: `build_crystal_lib.sh simulator` → libhighost.a → `xcodebuild`.

## Layout

```
samples/initiative-cross-platform-ui-demo/
  app.cr                # build_screen(slug) entry point used by every target
  brand.cr              # InitiativeDemo::DemoBrand + .brand_tokens
  screens/              # one file per demo screen
    state.cr            # instance-scoped demo state (NO class vars)
    sign_in.cr
    dashboard.cr
    detail.cr
    settings.cr
    tier_three.cr
  web/
    static_site.cr      # crystal run target -> writes output/initiative-demo/*.html
  macos/
    host.cr             # crystal-alpha build -Dmacos
    Makefile.include    # included by top-level Makefile
  ios/
    bridge.cr           # crystal-alpha cross-compile -Dios -> libhighost.a
    project.yml         # xcodegen input
    Sources/            # Swift host app
    UITests/            # XCUITest visual specs
  Makefile              # entrypoint
  README.md
```

## Audit harness integration

The five screen slugs (`demo-sign-in`, `demo-dashboard`, `demo-detail`,
`demo-settings`, `demo-tier-three`) plus the meta-slug `demo-all` are
registered in `scripts/audit_harness.cr` and exercise every probe cell.

```
bash scripts/audit_harness_smoke.sh I-1 web demo-sign-in
bash scripts/audit_harness_smoke.sh I-1 macos demo-dashboard
bash scripts/audit_harness_smoke.sh I-1 ios demo-detail
bash scripts/audit_harness_smoke.sh I-1 web demo-all     # iterates all 5
```

Baselines live at `docs/initiative-cross-platform-ui/baselines/{web-desktop, web-mobile, ios, macos}/demo-{screen}-{appearance}.png`.

## Quad-comparison page

`scripts/capture_demo_quad.cr` iterates the 5 screens across all 4
user-facing surfaces (web-desktop, web-mobile, iOS sim, macOS host) in
light + dark mode and writes `output/initiative-demo/quad-comparison.html`
— 5 rows × 4 columns × 2 appearance variants per cell.

The reviewer's job is simple: "Can I see this is the same brand?"
