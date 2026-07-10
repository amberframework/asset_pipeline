
# Phase 6 — Side-by-Side Demo App — Implementation Brief

**You are the implementer agent for this phase.** Read this document in full before writing any code. The validator will check your output against `validation.md` — make their job easy by satisfying every check listed there.

---

## Goal

> **Naming note (read first).** Throughout this brief, the product is called **DemoApp** (Crystal module `DemoApp`, brand class `DemoBrand`, prose name "Demo"). This is a deliberately neutral placeholder. If the team lead has a preferred product name, run a single global find-replace across this folder before the implementer starts work (`DemoApp` → `<Name>App`, `DemoBrand` → `<Name>Brand`, prose "Demo" → "<Name>"). The brand override's technical content (saturated coral primary, deep violet accent, distinct radius scale, faster motion curve, the visually-distinct intent) is the load-bearing part and is unchanged by any rename.

Build a single Crystal source that declares a small but representative demo app, configure it to build for three targets (web, macOS, iOS), and produce a quad-comparison HTML harness that captures every screen on every platform at every relevant viewport into one reviewable page.

The deliverable is **not** "a feature." It is **the integration test for the entire initiative.** Phases 1–5 each shipped a contract; phase 6 is the screen on which all five contracts must read as one product.

The user's litmus test for "done": open `output/initiative-demo/quad-comparison.html`, look at the five screens rendered across web (three viewports), macOS (wide + narrow), and iOS simulator, and tell at a glance that:

1. It is the same brand on every platform.
2. The platform is speaking its own language (Liquid Glass on Apple, browser-native focus rings on web, system fonts everywhere they belong).
3. Resizing the web viewport or macOS window between desktop and mobile widths reflows fluidly.
4. The Tier 3 screen visibly uses platform-only widgets on Apple and the documented `*WithWebFallback` variants on web.

If you cannot stand behind those four claims when you hand off, you are not done.

---

## Pre-reading checklist

Before writing any code, read in this order:

1. `docs/initiative-cross-platform-ui/MASTER_PLAN.md` — the whole document. You are the last implementation phase; everything before you must be in place. If anything reads as not-actually-done, **stop and return early** to the team lead per the "When the brief is wrong" section of `rubric/implementation_criteria.md`.
2. `docs/initiative-cross-platform-ui/phases/phase-06-side-by-side-demo-app/README.md` — phase orientation. You've already opened this folder if you're reading this.
3. `docs/initiative-cross-platform-ui/rubric/implementation_criteria.md` — universal implementer rules. These apply.
4. `docs/initiative-cross-platform-ui/rubric/validation_criteria.md` — read so you know what's coming. Do not try to game it; do read it.
5. Phases 1–5 READMEs in the `phases/` folder. You compose everything they built. Each phase's `validation.md` is also worth skimming so you understand what "the platform default" is supposed to look like by the time you compose it.
6. Source files for orientation (read, don't modify):
   - `samples/cross_platform/macos_host/hig_showcase.cr` — existing macOS sample. Mirrors the build pattern you will use.
   - `samples/cross_platform/macos_host/Makefile` — build pattern for macOS `.app`.
   - `samples/cross_platform/ios_host/hig_bridge.cr` — existing iOS sample, especially the `{% if flag?(:ios) %}` guard pattern and the `crystal_render_slug` C-ABI export shape.
   - `samples/cross_platform/ios_host/build_crystal_lib.sh` — the iOS Crystal static-lib build script.
   - `samples/cross_platform/ios_host/CrystalHIGHost.xcodeproj` / `project.yml` — the XcodeGen project file pattern you'll model.
   - `examples/web_design_system_demo.cr` — existing static-site generator for web. Your web build will follow the same `generate_static_site` shape.
   - `CLAUDE.md` (repo root) — the "Native App Development Workflow" section, especially the platform flag table and the ObjC bridge compilation step.
7. Skim the existing `src/ui/views/` tree so you know what widgets are available and what their APIs look like. Do not try to invent new widget APIs in this phase — the phase scope is composition.

Do not skip any of the above. The demo app is the integration test; you cannot compose what you have not read.

---

## Existing infrastructure to use (vs. rebuild)

Phase 6 has the most "wrap existing infrastructure with a new app" work in the initiative. Almost every build script, capture pattern, and sample-app pattern you need already exists. The new artifacts are the demo source itself (`samples/initiative-cross-platform-ui-demo/`), the brand override, the screens, and the quad-comparison capture script. Everything else is **borrowed and adapted**.

### Sample apps you mirror (template pattern, do not delete)

- `samples/cross_platform/macos_host/` — the canonical macOS sample. Mirror its layout exactly:
  - `Makefile` — code-signing block with `CODESIGN_IDENTITY ?= Developer ID Application: AgentC Consulting LLC (PXDF92M2T4)` (preserve this; TCC grants for screen recording depend on stable signing identity).
  - `hig_showcase.cr` — entry-point shape and `HIG_SCREENSHOT_PATH` env-driven capture pattern.
  - `window_helper.m` — AppKit `NSApplication` + `NSWindow` bootstrap. Copy verbatim; this code does not need rewriting.
  - `bin/hig_showcase` output convention — your `bin/demo_app` mirrors it.
- `samples/cross_platform/ios_host/` — the canonical iOS sample. Mirror:
  - `build_crystal_lib.sh` — the cross-compile script. Your `build_ios_lib.sh` is a near-copy with the bridge file path swapped.
  - `project.yml` — XcodeGen input. Preserve `EXCLUDED_ARCHS[sdk=iphonesimulator*]: x86_64` (Crystal arm64-only constraint) and `deploymentTarget.iOS: "26.0"` (Liquid Glass requirement).
  - `Sources/CrystalHIGHostApp.swift`, `Sources/ContentView.swift`, `Sources/CrystalBridge.swift` — Swift app entry pattern. Your `Sources/DemoApp.swift` + `Sources/CrystalDemoHost.swift` follow this shape.
  - `UITests/HIGVisualTests.swift` — XCUITest pattern that drives a slug-based capture via `app.launchEnvironment`. Your `ScreenSmokeTests.swift` follows this — same `XCUIApplication` + `launchEnvironment["DEMO_SCREEN"]` pattern.
  - `hig_bridge.cr` — `crystal_render_slug` C-ABI export shape. Your `crystal_render_demo_screen` mirrors it.
- `samples/cross_platform/android_host/` — Android is out of scope for the quad comparison (see Master Plan), but read this once to confirm the Crystal-Android bridge pattern in case Phase 6 needs to verify an Android sample build still passes the cross-target invariant.

### Existing scripts to extend (do not duplicate)

- `scripts/capture_web_demo_screenshots.cr` — **the template for `scripts/capture_demo_quad.cr`.** It re-exports the canonical CDP harness at `scripts/capture_amber_demo_screenshots.cr` (headless Chrome launched directly with `--remote-debugging-port`, JSON-RPC over `HTTP::WebSocket`, `Emulation.setDeviceMetricsOverride` for viewport, `Page.captureScreenshot` for PNGs into `test-results/web-design-system/`). See `../../rubric/behavior-simulation-toolkit.md` §3. Your new script is structurally identical but writes to `output/initiative-demo/quad-evidence/` and adds the macOS + iOS capture stages. Do not write a new screenshot capture mechanism — extend the existing one.
- `scripts/validate_web_demo.cr` — runs structural validation against the web demo's generated HTML. Your `build_web.cr` output should pass the same validation by following the same `UI::Web::Renderer.new.render_document(view, title:)` pattern that `examples/web_design_system_demo.cr` uses.
- `scripts/axe_web_demo_audit.cr` — axe-core audit runner. Validator runs it against your output; the implementer ensures the generated HTML is auditable (semantic landmarks, `<main>`, `aria-*` attributes where appropriate).
- `scripts/ibm_web_demo_audit.cr` — IBM Equal Access audit runner. Same.
- `scripts/codex_hig_review.sh` — HIG screenshot review runner for the macOS sample (uses `osascript` + `screencapture`). Reuse this pattern for `capture_macos` in your quad-capture script; the macOS window-id resolution dance is non-trivial.
- `scripts/run_ios_hig_tests.sh` — wraps `xcodebuild test -only-testing`. Model `make ios` capture on this.

### Existing static-site demo to mirror

- `examples/web_design_system_demo.cr` — the canonical static-site demo. Read top to bottom. The output convention (one HTML file per "screen", a shared `theme.css`, an `assets/` folder, an `index.html` landing page) is the template for your `web/build_web.cr`. Your demo's web output must follow the same convention so `scripts/validate_web_demo.cr` and friends Just Work against it.
- `examples/amber_design_system_demo.cr` — alternative example showing the Amber brand variant. Read once for comparison; the `UI::Brand.use(...)` invocation pattern is here.

### Test infrastructure you reuse

- `src/ui/ax_test/` and `src/ui/ax_test.cr` — Crystal-native macOS Accessibility framework. Use this for any macOS behavior verification (window resize, focus check, etc.) in the cross-target spec. Do not roll new AXUIElement bindings.
- `spec/ui/hig_validation/macos_visual_spec.cr` — existing pattern for the AX-driven macOS visual harness. Mirror it for any new macOS behavior spec your Phase 6 work adds.
- `spec/spec_helper.cr` — auto-requires support files. The new `spec/samples/initiative_cross_platform_ui_demo_spec.cr` does not need extra `require` registration.

### Pinned versions and environment

These are the only versions your build scripts may target. Hardcode them; do not float. Validator will confirm.

| Tool | Version / Identity | Where it is referenced |
|---|---|---|
| Crystal compiler | `crystal-alpha` (`/opt/homebrew/bin/crystal-alpha`) | All `make` / `build_*.sh` invocations. |
| Xcode | 16+ with iOS SDK 26 | iOS sample build; do not lower deployment target. |
| iOS simulator runtime | `com.apple.CoreSimulator.SimRuntime.iOS-26-2` | Pin in `make ios`; verify via `xcrun simctl list runtimes`. |
| iOS simulator device | `iPhone 17 Pro` (Xcode human-readable name) → tag `iphone17pro` (filesystem-safe) | Standard target. Phase 7 alignment: `iphone17pro` is the canonical lowercase no-spaces form (per the Viewport tag vocabulary section below). |
| XcodeGen | `>= 2.41` | Bootstrap stanza enforces. Do not float. |
| Homebrew | required | XcodeGen bootstrap depends on `brew install xcodegen`. |
| macOS Developer ID | `Developer ID Application: AgentC Consulting LLC (PXDF92M2T4)` | Reuse from `samples/cross_platform/macos_host/Makefile`. Required for stable TCC permissions across rebuilds. |
| swift-snapshot-testing | `1.17.x` | Inherited from Phase 3. Phase 6 does not introduce snapshot tests directly, but the iOS XCUITest target may use it for behavior assertions. |
| axe-core | (whatever `scripts/axe_web_demo_audit.cr` pins) | Do not bump. |

### Conventions enforced project-wide

- **Output directory:** `output/initiative-demo/` is the canonical location for generated web artifacts. The validator looks here; do not write to a different location.
- **Evidence subdirectory:** `output/initiative-demo/quad-evidence/` holds the PNGs assembled into `quad-comparison.html`. Distinct from Phase 7's baseline directory `test-results/initiative-demo-baselines/` — those are different artifacts serving different purposes (Phase 6 = current state, Phase 7 = regression baseline). **Do not merge them.**
- **Viewport tag vocabulary:** the lowercase no-spaces form (`iphone17pro`, `desktop`, `tablet`, `mobile`, `mobile-min`) is the only accepted form in filenames, viewport identifiers, and evidence paths. The human-readable form (`iPhone 17 Pro`) appears only in `xcodebuild -destination 'name=iPhone 17 Pro'` strings and in prose. This convention is shared with Phase 7.
- **Brand override is the source of truth for the demo's chrome.** Do not hardcode colors anywhere in screen Crystal source. Every color comes from `DemoApp::Tokens.color.brand_primary` (etc.) via the brand override path. If you find yourself typing a hex string in a screen file, stop — that's a bug.
- **`test_id` on every interactive widget.** Use a stable convention like `data-testid="screen-{screen}-{widget-role}"` (e.g., `screen-sign-in-primary-cta`, `screen-tier3-show-action-sheet`). The validator and the brand-override check rely on these identifiers to locate elements. Document the identifier convention in the screen files' doc-comments.
- **Slug → screen dispatch.** Both macOS and iOS use `ENV["DEMO_SCREEN"]` (macOS) and `app.launchEnvironment["DEMO_SCREEN"]` (iOS XCUITest). Web uses one file per screen. The screen-id strings are the same vocabulary across all three platforms — define them once in `src/nav.cr` constants (`SCREEN_SIGN_IN = "sign-in"`, etc.) and reference everywhere.
- **CSS prefix:** `--ap-*` is the canonical prefix for all generated CSS variables. The web demo's `theme.css` must use this prefix; the validator's brand-override check samples by RGB, not by CSS variable, but the variable prefix audit is enforced by Phase 1's generator.

### What is genuinely new vs. extended

| New | Extended / mirrored |
|---|---|
| `samples/initiative-cross-platform-ui-demo/` (entire tree) | `samples/cross_platform/macos_host/` (pattern source) |
| `scripts/capture_demo_quad.cr` | `scripts/capture_web_demo_screenshots.cr` (pattern source) |
| `output/initiative-demo/` (the generated artifacts) | `scripts/axe_web_demo_audit.cr`, `scripts/ibm_web_demo_audit.cr` |
| `spec/samples/initiative_cross_platform_ui_demo_spec.cr` | `examples/web_design_system_demo.cr` (pattern source) |
| `samples/initiative-cross-platform-ui-demo/inspections/sign-in-primary-button.bbox.json` | `samples/cross_platform/ios_host/` (pattern source for `ios/`) |
| `samples/initiative-cross-platform-ui-demo/inspections/amber-default-primary-button.rgb.json` | Repo `Makefile` (if present) — add `make demo-quad` target |

If you find yourself creating a file outside `samples/initiative-cross-platform-ui-demo/` or `scripts/capture_demo_quad.cr` or the two inspection JSON fixtures, stop and confirm.

---

## Folder layout

Create exactly this tree under `samples/initiative-cross-platform-ui-demo/`. Do not add extra files unless absolutely necessary; if you do, justify it in the handoff `Deviations` section.

```
samples/initiative-cross-platform-ui-demo/
├── README.md                          # How to build + view; written last
├── src/
│   ├── demo_app.cr                    # Top-level entry: chooses target, dispatches
│   ├── brand.cr                       # Brand declaration (Tier 1 override)
│   ├── nav.cr                         # NavigationStack wiring, screen IDs
│   ├── screens/
│   │   ├── sign_in.cr                 # Screen 1
│   │   ├── dashboard.cr               # Screen 2 (3-tab container)
│   │   ├── dashboard_activity.cr      # Tab 1: card grid
│   │   ├── dashboard_friends.cr       # Tab 2: list with section headers
│   │   ├── dashboard_settings.cr      # Tab 3: settings form (links to detail screens)
│   │   ├── detail.cr                  # Screen 3: transaction detail
│   │   ├── settings.cr                # Screen 4: full settings/preferences
│   │   └── tier3_demo.cr              # Screen 5: ActionSheet + ContextMenu (Tier 3)
│   └── content/
│       ├── copy.cr                    # All strings (themed: "Demo" expense tracker)
│       ├── friends.cr                 # Mock friend data
│       └── transactions.cr            # Mock transaction data
├── assets/
│   └── placeholders/
│       ├── avatar-{1..6}.svg          # 6 local SVG avatars (geometric, license-clean)
│       ├── hero-transaction.svg       # Detail screen hero
│       └── wordmark.svg               # "Demo" wordmark (Inter or system fallback)
├── web/
│   ├── build_web.cr                   # Static-site generator (one HTML per screen)
│   └── shell.html.ecr                 # HTML shell template (head, viewport meta, theme CSS link)
├── macos/
│   ├── build_macos.cr                 # macOS .app entry; thin wrapper, similar to hig_showcase.cr
│   ├── window_helper.m                # NSApplication + NSWindow init (copied from hig_showcase)
│   ├── Info.plist.template
│   └── Makefile                       # macOS build, signing, bundling
├── ios/
│   ├── build_ios_lib.sh               # Cross-compile Crystal to libdemo.a for iOS
│   ├── bridge.cr                      # C-ABI export, mirrors hig_bridge.cr pattern
│   ├── project.yml                    # XcodeGen project spec
│   ├── Sources/
│   │   ├── DemoApp.swift              # SwiftUI app entry; embeds Crystal-rendered NavigationStack
│   │   ├── CrystalDemoHost.swift      # UIViewRepresentable wrapping the C-ABI render call
│   │   └── Info.plist
│   └── UITests/
│       └── ScreenSmokeTests.swift     # Launch app, navigate each screen, capture screenshot
└── handoff/                           # (Optional) Your own working notes; not committed unless useful
```

Top-level scripts (not in the demo folder; live in repo `scripts/`):

```
scripts/
├── capture_demo_quad.cr               # Quad-comparison harness (NEW — written by you)
├── capture_demo_web.cr                # Web-only capture (NEW; or extend existing capture_web_demo_screenshots.cr)
└── (existing scripts unchanged)
```

Build outputs:

```
output/initiative-demo/
├── index.html                         # Landing page linking each screen
├── sign-in.html
├── dashboard-activity.html
├── dashboard-friends.html
├── dashboard-settings.html
├── detail.html
├── settings.html
├── tier3.html
├── theme.css                          # Generated from brand.cr by phase 1's WebGenerator
├── assets/                            # Copied SVGs
└── quad-comparison.html               # Generated by capture_demo_quad.cr
```

---

## Themed content (not lorem ipsum)

The demo is a fictitious expense-tracking product called **Demo**. Themed content reads more honestly across platforms than lorem ipsum and makes the brand override more legible. All copy lives in `src/content/copy.cr` as constants so a future remix is one-file.

Examples:

- Wordmark: `Demo`
- Sign-in tagline: `Track shared expenses with the people who matter.`
- Sign-in button: `Sign in`
- Tab labels: `Activity`, `Friends`, `Settings`
- Sample transaction: `Coffee with Riley — $4.80 — 2h ago`
- Detail-screen hero caption: `Shared expense · Settled`
- Tier-3 screen prompt: `Share this transaction…` (the action sheet target)

Don't agonize over the copy — keep it short, neutral, and consistent. The point is **legible structure**, not microcopy.

---

## Per-screen view specs

For each of the five screens, the spec lists: a structural sketch, the widgets used, and which tier each widget exercises. Compose using **existing** widgets from `src/ui/views/`. If a widget is missing for what you want to express, simplify the screen rather than adding new widget types — phase 6 is composition, not new widget work.

### Screen 1 — Sign-in

**Purpose:** Show the brand chrome (wordmark, type scale, primary button, link affordance, social-auth row). Single column on every platform.

**Sketch:**

```
┌─────────────────────────────────────┐
│                                     │
│           ◯◯◯◯◯◯ Demo           │  ← wordmark SVG, Tier 1 (brand asset)
│                                     │
│       Track shared expenses         │  ← tagline, Tier 1 type scale (display)
│       with the people who matter.   │
│                                     │
│   ┌───────────────────────────────┐ │
│   │  Email                        │ │  ← TextField (Tier 2 default)
│   └───────────────────────────────┘ │
│                                     │
│   ┌───────────────────────────────┐ │
│   │  Password                ◉    │ │  ← SecureField (Tier 2 default)
│   └───────────────────────────────┘ │
│                                     │
│   ┌───────────────────────────────┐ │
│   │           Sign in             │ │  ← Button.primary (Tier 1 brand color)
│   └───────────────────────────────┘ │
│                                     │
│         Forgot your password?       │  ← LinkButton (Tier 2 default — :hover on web)
│                                     │
│   ─────────── or sign in with ──── │  ← Divider with inline Label
│                                     │
│   [  ] [  ] [  ]                    │  ← 3 IconButtons (Apple, Google, GitHub)
│                                     │
└─────────────────────────────────────┘
```

**Widgets:**

- `UI::VStack` (outer container, spacing: tokens.space.lg)
- `UI::Image` (wordmark SVG; placeholder if rendering text-only)
- `UI::Label` (tagline, type style: `:display_md`)
- `UI::TextField` (email; Tier 2 — SwiftUI default treatment on Apple, browser-native `<input>` on web)
- `UI::SecureField` (password; Tier 2)
- `UI::Button` with `role: :primary` (Tier 1 background = brand.primary)
- `UI::LinkButton` ("Forgot your password?"; Tier 2 — browser `:hover` underline on web, NSButton link style on macOS, system blue on iOS)
- `UI::Divider` with optional inline `UI::Label`
- `UI::HStack` of 3 `UI::IconButton` (Tier 2 social-auth row)

**Tier coverage:** Tier 1 (brand color, type scale, radius); Tier 2 (TextField, SecureField, Button hover/press states, LinkButton). No Tier 3 on this screen — keep it pure.

**Layout rules:**
- Max width 420 px (Tier 1 — `tokens.layout.form_max_width`). Center horizontally.
- Vertical centering on tall viewports (desktop); top-aligned with safe-area padding on mobile.
- On macOS narrow window: same layout — the form is already mobile-first.

### Screen 2 — Dashboard (3-tab)

**Purpose:** Show navigation idioms, glass surface (Tier 1 + Tier 5 tokenization), and layout responsiveness (3-column grid on desktop, 2-col on tablet, 1-col on mobile).

This screen is a `TabView` container that switches between three children. Each child is its own file but composes onto the same TabView shell.

**Sketch (outer shell, all tabs share this):**

```
┌─────────────────────────────────────────────────┐
│ ╔═══════════════════════════════════════════╗  │
│ ║  Demo                       👤 Riley  ║  │  ← TopBar (glass surface, Tier 5 material)
│ ╚═══════════════════════════════════════════╝  │
│                                                 │
│   ( Tab content here — varies per tab )         │
│                                                 │
│ ╔═══════════════════════════════════════════╗  │
│ ║  ⌂ Activity   👥 Friends   ⚙ Settings    ║  │  ← TabBar (iOS-bottom, macOS-top, web-bottom on mobile)
│ ╚═══════════════════════════════════════════╝  │
└─────────────────────────────────────────────────┘
```

**Outer-shell widgets:**

- `UI::NavigationStack` (root navigation host)
- `UI::TabView` with three tab items
- Top chrome: `UI::HStack` inside a `UI::GlassBackground` (Tier 1 brand glass; phase 5 wires intensity)
- `UI::Label` (wordmark text), `UI::Spacer`, `UI::IconButton` (avatar)

#### Tab 1 — Activity (card grid)

**Sketch (desktop 3-col, tablet 2-col, mobile 1-col):**

```
Activity
┌────────────┐ ┌────────────┐ ┌────────────┐
│ 🥤         │ │ 🍕         │ │ ⛽         │
│ Coffee     │ │ Pizza      │ │ Gas        │
│ $4.80      │ │ $24.00     │ │ $42.10     │
│ 2h ago     │ │ Yesterday  │ │ 3 days ago │
└────────────┘ └────────────┘ └────────────┘
┌────────────┐ ┌────────────┐ ┌────────────┐
│ ...        │ │ ...        │ │ ...        │
└────────────┘ └────────────┘ └────────────┘
```

**Widgets:**
- `UI::Label` (`:title_lg` style: "Activity")
- `UI::Grid` with adaptive columns: `min: 240`, `ideal: 280`, `max: 1fr` (Tier 1 — via `tokens.layout.card_min` etc.)
- 6 × `UI::Card` (each card is `VStack(Label, Label, Label)`); cards are tappable, routing to detail screen via `UI::NavigationLink`
- Each card uses `UI::Surface` with token-driven radius and elevation

**Tier coverage:** Tier 1 (card radius, spacing, type); Tier 2 (Card hover/press on web, tap highlight on iOS, focus ring on macOS).

#### Tab 2 — Friends (list with section headers)

**Sketch:**

```
Friends

— Close friends ——————————————————
  ◉ Riley         Owes you $12.40   ›
  ◉ Sam           Owes you  $3.00   ›
  ◉ Jordan        Settled           ›

— Recent ————————————————————————
  ◉ Casey         You owe   $8.20   ›
  ◉ Drew          You owe  $14.50   ›
```

**Widgets:**
- `UI::List` (Tier 2 — UITableView-grouped on iOS, NSTableView with header rows on macOS, semantic `<ul>` with `<h3>` section headers on web)
- Section header: `UI::Label` (`:label_md`, uppercase, dimmed)
- Each row: `UI::HStack(Image(avatar), VStack(Label(name), Label(balance, dimmed)), Spacer, IconButton(:chevron))`

**Tier coverage:** Tier 2 (list row tap highlight, section header default styling).

#### Tab 3 — Settings (form preview)

**Sketch:**

```
Settings

  Profile
    ◯ Avatar (tap to change)
    Name        [ Riley                 ]
    Email       [ riley@example.com ]

  Preferences
    Notifications   ◉─── On
    Dark mode       ───◉ Auto
    Haptics         ◉─── On

  About
    Version 1.0 (build 100)         ›
    Open settings (full screen)     ›
```

**Widgets:**
- `UI::Form` (Tier 2 — semantic `<form>` on web, NSGridView-like layout on macOS, grouped UITableView on iOS)
- `UI::Image` (avatar), `UI::TextField` × 2
- `UI::Toggle` × 3 (Tier 2 — UISwitch on iOS, NSSwitch on macOS, styled checkbox on web)
- `UI::NavigationLink` (label: "Open settings (full screen)", destination: settings screen — Screen 4)

### Screen 3 — Detail view

**Purpose:** Show navigation push/pop, image scaling, multi-column layout on wide viewports.

**Sketch (wide viewport — two-column):**

```
┌─────────────────────────────────────────────────────────┐
│ ‹ Back                                                  │
│ ┌──────────────┐  ┌──────────────────────────────────┐ │
│ │              │  │ Coffee with Riley                │ │
│ │  🥤 (hero)   │  │ $4.80 · Shared · Settled         │ │
│ │              │  │                                  │ │
│ │              │  │ Paid by: Riley                   │ │
│ │              │  │ Split: 50 / 50                   │ │
│ │              │  │ Date: May 18, 2026               │ │
│ │              │  │                                  │ │
│ │              │  │ [ Edit ]  [ Share ]  [ Delete ]  │ │
│ └──────────────┘  └──────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

**Sketch (narrow viewport — single-column, stacked):**

```
‹ Back
┌──────────────────────────────────┐
│         🥤 (hero, 16:9)          │
└──────────────────────────────────┘
Coffee with Riley
$4.80 · Shared · Settled

Paid by: Riley
Split: 50 / 50
Date: May 18, 2026

[ Edit ]
[ Share ]
[ Delete ]
```

**Widgets:**
- `UI::NavigationLink` (back arrow — automatic on iOS via NavigationStack; explicit on web/macOS via toolbar slot)
- Outer: `UI::AdaptiveStack` if available, otherwise `UI::HStack` on wide + `UI::VStack` on narrow gated by a viewport check. Prefer the responsive primitive from phase 2 (`fluid()`) where applicable.
- `UI::Image` (hero, 16:9 aspect; Tier 1 — radius from `tokens.radius.lg`)
- `UI::Label` × multiple (title, subtitle, metadata rows)
- `UI::HStack` of `UI::Button` (Edit secondary, Share secondary, Delete destructive — `role: :destructive`)

**Tier coverage:** Tier 1 (radii, type, destructive color); Tier 2 (button role styling — system red on iOS, NSAlertSecondButton style on macOS, browser-native red on web).

### Screen 4 — Settings (full)

**Purpose:** Exercise the form widget set densely. This is the screen that proves the form widgets all reflow correctly across viewports.

**Sketch:**

```
‹ Back   Settings

Account
  Name              [ Riley                    ]
  Email             [ riley@example.com    ]
  Phone             [ +1 555 0123              ]

Preferences
  Theme             [ Auto ▾ ]   ← Picker
  Accent            ●●●●●●●  ← ColorPicker
  Default split     [—|—————]   ← Slider (0% to 100%)
  Notifications     ◉── On       ← Toggle
  Haptics           ◉── On       ← Toggle
  Reminder time     [ 09:00  ]   ← TimePicker
  Frequency         (Daily) (Weekly) (Off)  ← SegmentedControl

Currency
  Default           [ USD ▾ ]    ← Picker
  Rounding          [ – | + ]    ← Stepper

[ Save changes ]   [ Cancel ]
```

**Widgets:**
- `UI::Form`
- `UI::TextField` × 3
- `UI::Picker` × 2 (Theme, Currency) — Tier 2: UIPickerView on iOS, NSPopUpButton on macOS, `<select>` on web
- `UI::ColorPicker` — Tier 3 *boundary*: native chrome on iOS/macOS, HTML `<input type="color">` on web (this is a Tier-3-with-explicit-web-fallback case from phase 4)
- `UI::Slider` — Tier 2
- `UI::Toggle` × 2 — Tier 2
- `UI::TimePicker` — Tier 3 boundary (native chrome on iOS/macOS, HTML `<input type="time">` on web)
- `UI::SegmentedControl` — Tier 2
- `UI::Stepper` — Tier 2
- `UI::Button` × 2 (Save = primary, Cancel = secondary)

**Tier coverage:** Tier 1 (form spacing, label type); Tier 2 (every form control's default treatment); Tier 3 boundary on ColorPicker / TimePicker.

### Screen 5 — Tier 3 demo

**Purpose:** Show platform-only widgets and the explicit `*WithWebFallback` pattern from phase 4 in one screen.

**Sketch:**

```
‹ Back   Platform-only widgets

This screen uses widgets that only exist on certain platforms.
On the web, the documented fallback variant is used.

┌──────────────────────────────────────────┐
│  Share this transaction                  │  ← Label
│  [ Show action sheet ]                   │  ← Button → ActionSheet (iOS) / ActionSheetWithWebFallback (web)
└──────────────────────────────────────────┘

┌──────────────────────────────────────────┐
│  Right-click a row to see context menu   │  ← Label
│  ┌────────────────────────────────────┐  │
│  │ Coffee with Riley     $4.80        │  │  ← Row with ContextMenu (macOS/iOS) / ContextMenuWithWebFallback (web)
│  │ Pizza with Sam        $24.00       │  │
│  │ Gas with Jordan       $42.10       │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘

```

**Widgets:**
- `UI::Button` toggling a `UI::ActionSheet` (iOS) / `UI::ActionSheetWithWebFallback` (web) via its `is_presented` property — see compile-time pattern below. On macOS, fall back to a `UI::ConfirmationDialog` (also driven by `is_presented`).
- `UI::List` of rows, each with `UI::ContextMenu` (macOS/iOS) — on web use `UI::ContextMenuWithWebFallback`.

(Note: an earlier draft of this screen included a HapticFeedback demo button. That widget is out of scope for the entire initiative until a future phase adds it — Phase 4 explicitly defers it. Do not stub the widget in Phase 6; if you find yourself wanting a third Tier-3 example, surface to the team lead.)

**Tier coverage:** Tier 3 explicitly. This screen is the proof that phase 4's gating works in a real composition.

**Compile-time pattern (uses Phase 4's actual instance-method API, NOT invented class-level convenience methods):**

Phase 4 ships ActionSheet as a `UI::View` subclass with a mutable `is_presented : Bool = false` property and an `add_action(...)` instance method (see Phase 4 `implementation.md` §"Before / after — `ActionSheet`"). You construct an instance, configure it, and toggle `is_presented` from the tap handler. There is **no** `UI::ActionSheet.show(...)` class-level convenience.

```crystal
# At screen-build time: construct the sheet once and own its state.
share_sheet =
  {% if flag?(:ios) %}
    UI::ActionSheet.new(title: "Share", message: "Send this link to a friend").tap do |s|
      s.add_action(UI::ActionSheet::Action.new("Copy link"))
      s.add_action(UI::ActionSheet::Action.new("Open in Messages"))
      s.add_action(UI::ActionSheet::Action.cancel("Cancel"))
    end
  {% elsif flag?(:macos) %}
    UI::ConfirmationDialog.new(title: "Share", message: "Send this link to a friend").tap do |d|
      d.add_action(UI::ConfirmationDialog::Action.new("Copy link"))
      d.add_action(UI::ConfirmationDialog::Action.new("Open in Messages"))
      d.add_action(UI::ConfirmationDialog::Action.cancel("Cancel"))
    end
  {% else %}
    UI::ActionSheetWithWebFallback.new(title: "Share", message: "Send this link to a friend").tap do |s|
      s.add_action(UI::ActionSheetWithWebFallback::Action.new("Copy link"))
      s.add_action(UI::ActionSheetWithWebFallback::Action.new("Open in Messages"))
      s.add_action(UI::ActionSheetWithWebFallback::Action.cancel("Cancel"))
    end
  {% end %}

# The trigger button flips `is_presented` on the sheet instance.
share_button = UI::Button.new("Show action sheet") do
  share_sheet.is_presented = true
end
```

**Trust Phase 4's source over this brief.** If Phase 4's actual `ActionSheet` API differs from the above (different keyword names, different `Action` constructor, `is_open` instead of `is_presented`, etc.), match the source. The point is to use the **instance-method** API Phase 4 actually shipped, not to invent `.show(...)` class methods.

Either way, the source must read as **one Crystal file with platform branches**, not three forks of the screen.

---

## Brand declaration

The brand override is a concrete demonstration that phase 1's token system works. It must be **visibly distinct** from the default amber brand. The user's instruction in the README: "A subtle palette tweak isn't enough; pick a notably different primary color."

**Chosen palette:**

- Primary: **saturated coral** — `oklch(0.68 0.22 25)` (warm, high chroma)
- Accent: **deep violet** — `oklch(0.42 0.18 295)` (cool, high chroma — pulls hard against the coral)
- Destructive: **system red** (kept) — uses `tokens.role.destructive` default
- Background: warm off-white in light, deep charcoal with violet undertone in dark
- Surface: glass-friendly translucent panels

**Concrete Crystal (drop into `samples/initiative-cross-platform-ui-demo/src/brand.cr`):**

The brand is a **subclass of `UI::Brand` (the immutable abstract class from Phase 1)** that overrides the relevant `override_*` methods to return modified records. Phase 1 made `Tokens` immutable; there is **no** `Brand.declare do |b| b.color.brand_primary = ... end` builder DSL. Each `override_*` method receives the base record and returns a new record via `copy_with` (or hand-rolled construction if `copy_with` is not available on the Crystal version in use).

```crystal
require "asset_pipeline/ui"

# Demo brand override — phase 6 demo.
#
# Deliberately chromatic + warm-vs-cool tension so a side-by-side comparison
# against the default amber brand is unmistakable. If you find yourself
# nudging these values "to be tasteful", stop — the point is contrast.

module DemoApp
  class DemoBrand < UI::Brand
    # ----- Color (light) -----
    protected def override_color_light(p : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      p.copy_with(
        brand_primary:       UI::DesignTokens::Color.oklch(0.68, 0.22,  25),   # coral
        brand_primary_hover: UI::DesignTokens::Color.oklch(0.62, 0.22,  25),
        brand_accent:        UI::DesignTokens::Color.oklch(0.42, 0.18, 295),   # deep violet
        text_inverse:        UI::DesignTokens::Color.oklch(0.98, 0.01,  90),   # warm white on primary
        surface_canvas:      UI::DesignTokens::Color.oklch(0.985, 0.02,  65),  # warm off-white
        surface_panel:       UI::DesignTokens::Color.oklch(0.97,  0.02,  65),
        text_primary:        UI::DesignTokens::Color.oklch(0.18,  0.03, 295),
        text_secondary:      UI::DesignTokens::Color.oklch(0.42,  0.03, 295),
        border_subtle:       UI::DesignTokens::Color.oklch(0.88,  0.02,  65),
      )
    end

    # ----- Color (dark) — same hue family, inverted lightness. -----
    protected def override_color_dark(p : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      p.copy_with(
        surface_canvas: UI::DesignTokens::Color.oklch(0.16, 0.04, 295),   # violet-tinted charcoal
        surface_panel:  UI::DesignTokens::Color.oklch(0.22, 0.04, 295),
        text_primary:   UI::DesignTokens::Color.oklch(0.96, 0.02,  65),
        brand_primary:  UI::DesignTokens::Color.oklch(0.74, 0.20,  25),   # slightly brighter coral
      )
    end

    # ----- Type scale -----
    # Coral product wants slightly tighter, slightly heavier type than amber's default.
    protected def override_type(scale : UI::DesignTokens::TypeScale) : UI::DesignTokens::TypeScale
      scale.copy_with(
        family_sans:    "Inter, ui-sans-serif, system-ui, sans-serif",
        family_display: "Newsreader, Inter, ui-serif, serif",
        display:        UI::DesignTokens::TypeStep.new(size: 2.75, line_height: 1.05, weight: 720, tracking: -0.02),
        headline:       UI::DesignTokens::TypeStep.new(size: 2.00, line_height: 1.10, weight: 700, tracking: -0.01),
        title:          UI::DesignTokens::TypeStep.new(size: 1.375, line_height: 1.20, weight: 680, tracking: 0.00),
        body:           UI::DesignTokens::TypeStep.new(size: 1.00, line_height: 1.45, weight: 440, tracking: 0.00),
        caption:        UI::DesignTokens::TypeStep.new(size: 0.8125, line_height: 1.30, weight: 600, tracking: 0.04),
      )
    end

    # ----- Radius — chunkier than amber; coral wants soft, almost pillowy corners. -----
    protected def override_radius(r : UI::DesignTokens::RadiusScale) : UI::DesignTokens::RadiusScale
      r.copy_with(
        sm:   0.625,   # 10 px
        md:   0.875,   # 14 px
        lg:   1.375,   # 22 px
        xl:   2.000,   # 32 px
        pill: 9999.0,
      )
    end

    # ----- Motion — quicker than amber's defaults. Coral wants energetic. -----
    protected def override_motion(m : UI::DesignTokens::MotionScale) : UI::DesignTokens::MotionScale
      m.copy_with(
        duration_fast_ms:  120,
        duration_base_ms:  200,
        duration_slow_ms:  320,
        ease_standard:     "cubic-bezier(0.2, 0.0, 0.0, 1.0)",
        ease_emphasized:   "cubic-bezier(0.25, 0.0, 0.0, 1.2)",  # subtle overshoot
      )
    end

    # NOTE: Phase 5 promotes glass material to a token branch. If `Tokens` has
    # a `material` aggregate by the time Phase 6 lands, add the matching
    # `override_material(m) -> m.copy_with(intensity: 1.15)` here. If Phase 5
    # has not landed by the time you start Phase 6, leave this override out
    # rather than inventing the API surface.

    # Spacing kept default (4-pt grid) — no override.
  end

  # The Tokens instance the demo app uses everywhere. Constructed once at app
  # boot and threaded through the renderers.
  Tokens = UI::DesignTokens::Tokens.default.with_brand(DemoBrand.new)
end
```

**Important:** if any of the token accessor names above differ from what Phase 1 actually shipped, update to match — do not invent. The validator will fail you if you reference `text_inverse` and the actual field name is `on_primary`. **Trust the source, not this brief.** In particular, `copy_with` may or may not be auto-provided by Crystal's `record` macro for the version pinned in this repo; if not, hand-roll the merge using named-argument construction. The Phase 1 implementer's handoff documents the chosen approach in the `design_tokens.cr` file header.

---

## Navigation flow

Five screens; one navigation stack. Routing is declarative.

```crystal
# samples/initiative-cross-platform-ui-demo/src/nav.cr

module DemoApp::Nav
  # Stable screen identifiers — also used by the capture harness.
  SCREEN_SIGN_IN  = "sign-in"
  SCREEN_DASH_ACT = "dashboard-activity"
  SCREEN_DASH_FRD = "dashboard-friends"
  SCREEN_DASH_SET = "dashboard-settings"
  SCREEN_DETAIL   = "detail"
  SCREEN_SETTINGS = "settings"
  SCREEN_TIER3    = "tier3"

  def self.root_view : UI::View
    UI::NavigationStack.new do |stack|
      stack.root = DemoApp::Screens::SignIn.build(on_submit: ->{
        stack.push(DemoApp::Screens::Dashboard.build(stack))
      })
    end
  end

  # Dashboard pushes detail / settings / tier3 from its tabs / cards.
  # See dashboard.cr for the wiring.
end
```

**Flow:**

```
SignIn ──[Sign in]──▶ Dashboard
                       │
                       ├── Tab: Activity ──[tap card]──▶ Detail
                       ├── Tab: Friends  ──[tap row]───▶ Detail
                       └── Tab: Settings ──[Open settings (full screen)]──▶ Settings
                                          ──[Platform-only demos »]───────▶ Tier3
```

**Per-platform navigation defaults:**

- **iOS:** NavigationStack with system back button (chevron + previous title). TabView uses bottom UITabBar.
- **macOS:** NavigationStack with toolbar-mounted back button. TabView uses NSSegmentedControl in toolbar (idiomatic macOS).
- **Web:** Each screen is its own static HTML page in single-page-per-screen mode; navigation is `<a href>` links. NavigationStack renders semantic `<nav>` chrome with a back link generated based on referrer. TabView renders as a sticky bottom bar on mobile widths and as inline tabs on desktop widths.

This is enforced by phase 3's SwiftUI bridge and phase 2's responsive web work — you compose against the unified API, the renderers do the right thing.

---

## Build configuration

### Web build

**Pattern:** Mirror `examples/web_design_system_demo.cr`. Generate one HTML file per screen plus an `index.html` landing page. All screens share a single generated `theme.css`.

**Multi-page rationale:** Each screen needs to be capturable independently by the screenshot harness. A single-page app would require driving navigation programmatically; multi-page lets the capture script just load a URL and shoot. Trade-off: no client-side routing transitions. That's fine — we're capturing static states.

**Entry point:** `samples/initiative-cross-platform-ui-demo/web/build_web.cr`

```crystal
require "file_utils"
require "../../../src/asset_pipeline"
require "../../../src/ui"
require "../src/brand"
require "../src/screens/sign_in"
require "../src/screens/dashboard_activity"
require "../src/screens/dashboard_friends"
require "../src/screens/dashboard_settings"
require "../src/screens/detail"
require "../src/screens/settings"
require "../src/screens/tier3_demo"

module DemoApp::WebBuild
  OUTPUT_DIR = "output/initiative-demo"

  def self.run
    FileUtils.mkdir_p(OUTPUT_DIR)
    FileUtils.cp_r("samples/initiative-cross-platform-ui-demo/assets", OUTPUT_DIR)

    # Apply brand override BEFORE rendering — token cascade flows from here.
    UI::Brand.use(DemoApp::Brand)

    # Generate theme CSS from the active brand.
    File.write(
      File.join(OUTPUT_DIR, "theme.css"),
      UI::DesignTokens::WebGenerator.new(DemoApp::Brand).generate
    )

    # Generate one HTML file per screen.
    write_screen("sign-in.html",              DemoApp::Screens::SignIn.build)
    write_screen("dashboard-activity.html",   DemoApp::Screens::DashboardActivity.build)
    write_screen("dashboard-friends.html",    DemoApp::Screens::DashboardFriends.build)
    write_screen("dashboard-settings.html",   DemoApp::Screens::DashboardSettings.build)
    write_screen("detail.html",               DemoApp::Screens::Detail.build)
    write_screen("settings.html",             DemoApp::Screens::Settings.build)
    write_screen("tier3.html",                DemoApp::Screens::Tier3Demo.build)
    write_index

    puts "Generated #{OUTPUT_DIR}/ (#{Dir.children(OUTPUT_DIR).size} files)"
  end

  private def self.write_screen(name : String, view : UI::View)
    html = UI::Web::Renderer.new.render_document(view, title: "Demo — #{name.gsub(/\.html$/, "")}")
    File.write(File.join(OUTPUT_DIR, name), html)
  end

  private def self.write_index
    # Tiny landing page linking each screen by id. Useful for human review.
    # Implementation left to the implementer.
  end
end

DemoApp::WebBuild.run
```

**Command:**

```bash
crystal run samples/initiative-cross-platform-ui-demo/web/build_web.cr
# → produces output/initiative-demo/*.html
```

The `make web` target (added to repo `Makefile` if one exists, else added to the demo's own `Makefile`) wraps this command.

### macOS build

**Pattern:** Mirror `samples/cross_platform/macos_host/Makefile`. The output is a runnable binary (and optionally a `.app` bundle). The binary is a NSApplication that creates one NSWindow and renders the demo's root view; the screen displayed is selected by `ENV["DEMO_SCREEN"]` or defaults to the sign-in screen.

**Entry point:** `samples/initiative-cross-platform-ui-demo/macos/build_macos.cr`

```crystal
require "../../../src/ui"
require "../src/brand"
require "../src/nav"
# (require all screens)

{% if flag?(:macos) %}
  UI::Brand.use(DemoApp::Brand)
  screen_id = ENV["DEMO_SCREEN"]? || "sign-in"

  root = case screen_id
         when "sign-in"            then DemoApp::Screens::SignIn.build
         when "dashboard-activity" then DemoApp::Screens::DashboardActivity.build
         # ...etc
         else
           DemoApp::Nav.root_view
         end

  app = UI::AppKit::Application.new(title: "Demo — #{screen_id}", root_view: root)
  app.run
{% end %}
```

The choice between "show full nav flow" vs "show one screen" is driven by env var so the capture harness can target individual screens.

**Build (`samples/initiative-cross-platform-ui-demo/macos/Makefile`):**

Mirror `samples/cross_platform/macos_host/Makefile` exactly — including:
- ObjC bridge compilation (`objc_bridge.o`)
- Window helper compilation (`window_helper.o`)
- `-Dmacos` flag
- Framework list (AppKit, Foundation, etc.) — include `WebKit, MapKit, AVKit, AVFoundation` if the demo uses any of those; if not, drop them for a cleaner link.
- Code-signing block (keep the Developer ID identity wiring; allow override via env)

```makefile
SLUG ?= sign-in

showcase: build
	DEMO_SCREEN=$(SLUG) ./bin/demo_app

build: ext-ap ext-win bin/demo_app

bin/demo_app: build_macos.cr ext-ap ext-win
	@mkdir -p bin
	$(CRYSTAL) build build_macos.cr -o bin/demo_app -Dmacos \
		--link-flags="$(MACOS_LINK_FLAGS)"
	@$(MAKE) --no-print-directory sign

# ... ext-ap, ext-win, sign, clean targets identical pattern to hig_showcase
```

**App bundling:** Build a `.app` directory tree with the binary, `Info.plist`, and an icon. The validator may require a real `.app`; produce one. `samples/cross_platform/macos_host/` may already have a `bundle` target — copy that pattern.

### iOS build

**Pattern:** Mirror `samples/cross_platform/ios_host/`. Crystal source compiles to a static library (`libdemo.a`); Swift host app links against it and embeds the rendered view in a `UIViewRepresentable`. Build for **iPhone 17 Pro simulator** per the README.

**Files to create:**

1. `samples/initiative-cross-platform-ui-demo/ios/bridge.cr` — mirror `samples/cross_platform/ios_host/hig_bridge.cr`. Replace its slug→scene dispatch with screen-id→view dispatch. C-ABI export shape:

```crystal
{% if flag?(:ios) %}
  fun crystal_render_demo_screen(screen_id : LibC::Char*) : Void*
    # initialize Crystal runtime if needed (see hig_bridge.cr)
    # apply brand
    # build view for screen_id
    # convert to native pointer, retain, return
  end
{% end %}
```

2. `samples/initiative-cross-platform-ui-demo/ios/build_ios_lib.sh` — mirror `samples/cross_platform/ios_host/build_crystal_lib.sh`. Cross-compile to `libdemo.a` for `arm64-apple-ios-simulator`.

3. `samples/initiative-cross-platform-ui-demo/ios/project.yml` — XcodeGen spec. Mirror the existing `ios_host/project.yml`. The Swift app target links `libdemo.a` and the Swift companion library from phase 3 (`AssetPipelineSwiftKit`).

4. `samples/initiative-cross-platform-ui-demo/ios/Sources/DemoApp.swift`:

```swift
import SwiftUI

@main
struct DemoApp: App {
    init() {
        // Crystal runtime is initialized lazily by the bridge on first call.
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        NavigationStack {
            // Embed Crystal-rendered root view via UIViewRepresentable.
            CrystalDemoHost(screenId: "sign-in")
                .navigationTitle("Demo")
        }
    }
}
```

5. `samples/initiative-cross-platform-ui-demo/ios/Sources/CrystalDemoHost.swift`:

```swift
import SwiftUI
import UIKit

struct CrystalDemoHost: UIViewRepresentable {
    let screenId: String

    func makeUIView(context: Context) -> UIView {
        let ptr = crystal_render_demo_screen(screenId.cString(using: .utf8))
        return Unmanaged<UIView>.fromOpaque(ptr!).takeUnretainedValue()
    }

    func updateUIView(_ uiView: UIView, context: Context) {}
}
```

6. `samples/initiative-cross-platform-ui-demo/ios/UITests/ScreenSmokeTests.swift` — XCUITest target that launches the app and verifies the demo root view renders without crashing, then captures a screenshot. This is what the capture harness drives.

**XcodeGen pin and bootstrap.** The iOS build depends on [XcodeGen](https://github.com/yonaskolb/XcodeGen) (a Homebrew tool that generates `.xcodeproj` from `project.yml`). XcodeGen is **required**; the script must ensure it is installed at a known-good version before invoking it, and must fail with a clear, actionable error message if installation cannot proceed (rather than silently letting `xcodegen generate` fail with a cryptic "command not found").

**Known-good version: XcodeGen >= 2.41.** This is the minimum version verified against the Xcode toolchain pinned in `CLAUDE.md`. Earlier versions miss `package:` and Swift-Package-Manager-integration fields used by the generated project.

Place the following install/version-check stanza at the **top** of `build_ios_lib.sh` (and any `make ios` recipe that calls into iOS tooling), **before** any other command:

```bash
#!/usr/bin/env bash
set -euo pipefail

# --- XcodeGen bootstrap ------------------------------------------------------
# Required tool. Pinned minimum version 2.41. Install via Homebrew (Brewfile
# preferred if the repo ships one; raw `brew install` otherwise).

ensure_xcodegen() {
  if command -v xcodegen >/dev/null 2>&1; then
    local v
    v="$(xcodegen --version 2>/dev/null || echo 0.0)"
    # crude lexical compare is fine for "2.41" vs "2.41.x"; tighten if needed.
    if [ "$(printf '%s\n2.41\n' "$v" | sort -V | head -n1)" != "2.41" ]; then
      echo "error: xcodegen ${v} found, but >= 2.41 is required." >&2
      echo "       Upgrade with: brew upgrade xcodegen   (or 'brew bundle' if the repo has a Brewfile)." >&2
      exit 1
    fi
    return 0
  fi

  if [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/Brewfile" ]; then
    echo "xcodegen not found — installing via 'brew bundle' (Brewfile present)."
    (cd "$(git rev-parse --show-toplevel)" && brew bundle)
  elif command -v brew >/dev/null 2>&1; then
    echo "xcodegen not found — installing via 'brew install xcodegen'."
    brew install xcodegen
  else
    cat >&2 <<'EOF'
error: xcodegen is not installed and Homebrew is not available on this machine.

The Phase 6 iOS build requires XcodeGen >= 2.41. Install it one of two ways:
  1) Install Homebrew (https://brew.sh) and re-run this script (it will auto-install).
  2) Install XcodeGen manually (https://github.com/yonaskolb/XcodeGen#installing)
     and ensure `xcodegen` is on PATH, then re-run this script.
EOF
    exit 1
  fi
}

ensure_xcodegen
# --- end XcodeGen bootstrap --------------------------------------------------

# (rest of the build script: build_ios_lib.sh body)
```

**Build command (in the `ios/` folder, AFTER the bootstrap stanza above runs):**

```bash
./build_ios_lib.sh                                # produces libdemo.a
xcodegen generate                                 # from project.yml — XcodeGen is now guaranteed installed
xcodebuild -project DemoApp.xcodeproj \
  -scheme DemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro,OS=latest' \
  build
```

A `make ios` target wraps this. The `make ios` recipe must call the bootstrap stanza too (factor it into a shell helper if duplicating between Makefile and shell script becomes painful).

**Simulator pinning:** the README pins iPhone 17 Pro (viewport tag `iphone17pro` — see "Viewport tag vocabulary" below). Verify the implementer's Xcode install has that simulator available. If iOS 26 / Xcode 26 is the supported environment per the repo's CLAUDE.md, this should work; if not, document the closest available simulator in the handoff and flag for the team lead.

**Viewport tag vocabulary (D10 — canonical across Phases 6 and 7).** The lowercase, no-spaces form `iphone17pro` is the only accepted tag in filenames, evidence paths, viewport identifiers, and `SCREENSHOTS` arrays. Forms like `iPhone 17 Pro` (human-readable) appear only in user-facing prose, code comments, and `xcodebuild -destination 'name=iPhone 17 Pro'` strings (where Xcode requires the human-readable name). Tags like `iphone_17_pro`, `iPhone17Pro`, or `iphone-17-pro` are NOT permitted anywhere.

---

## Quad-comparison harness

The deliverable: `output/initiative-demo/quad-comparison.html`. One static page. CSS grid. For each of the 5 screens, one row showing all viewport captures side by side, labeled, in light + dark.

### Script: `scripts/capture_demo_quad.cr`

Single Crystal script that orchestrates everything. Shape:

```crystal
require "file_utils"

module CaptureDemoQuad
  EVIDENCE_DIR = "output/initiative-demo/quad-evidence"
  OUTPUT_HTML  = "output/initiative-demo/quad-comparison.html"

  SCREENS = %w[sign-in dashboard-activity dashboard-friends dashboard-settings detail settings tier3]

  WEB_VIEWPORTS = [
    {name: "desktop",  width: 1280, height: 800},
    {name: "tablet",   width:  768, height: 1024},
    {name: "mobile",   width:  375, height: 667},
  ]

  SCHEMES = %w[light dark]

  def self.run
    FileUtils.mkdir_p(EVIDENCE_DIR)
    build_outputs
    capture_web
    capture_macos
    capture_ios
    write_html_grid
    puts "Wrote #{OUTPUT_HTML}"
  end

  private def self.build_outputs
    # 1. crystal run samples/.../web/build_web.cr
    # 2. make -C samples/.../macos build
    # 3. make -C samples/.../ios build  (skip if XCUITest harness will rebuild)
  end

  private def self.capture_web
    # For each screen × viewport × scheme:
    #   - launch headless Chrome via CDP per ../../rubric/behavior-simulation-toolkit.md §3.2
    #     (extend scripts/capture_amber_demo_screenshots.cr; do NOT introduce Puppeteer/Playwright/npm)
    #   - navigate file://.../output/initiative-demo/{screen}.html
    #   - set viewport + prefers-color-scheme
    #   - wait for fonts + images
    #   - capture {evidence_dir}/web-{screen}-{viewport}-{scheme}.png
  end

  private def self.capture_macos
    # For each screen × {wide, narrow} × scheme:
    #   - DEMO_SCREEN={screen} ./bin/demo_app &
    #   - wait for window to appear (poll for window title via osascript/AXTest)
    #   - resize window: osascript -e 'tell app "System Events" to set size of window 1 to {1280, 800}'
    #     and {640, 800} for narrow
    #   - set appearance: osascript -e 'tell app "System Events" to tell appearance preferences to set dark mode to true/false'
    #   - screencapture -l <window_id> -t png -o {evidence_dir}/macos-{screen}-{extent}-{scheme}.png
    #   - kill the binary
  end

  private def self.capture_ios
    # Boot iPhone 17 Pro simulator (xcrun simctl boot ...).
    # For each screen × scheme:
    #   - set simulator appearance: xcrun simctl ui booted appearance light|dark
    #   - launch the demo app with DEMO_SCREEN env var
    #     xcrun simctl launch booted com.assetpipeline.democross --DEMO_SCREEN={screen}
    #   - wait for view to render (XCUITest accessibility-id probe or just sleep 2)
    #   - xcrun simctl io booted screenshot {evidence_dir}/ios-{screen}-{scheme}.png
    #   - terminate the app: xcrun simctl terminate booted com.assetpipeline.democross
  end

  private def self.write_html_grid
    # Emit a static HTML file with CSS grid. For each screen, one section,
    # in light then dark, with all captures from that screen as children.
  end
end

CaptureDemoQuad.run
```

### Quad-comparison HTML layout

The page is purely static — no JS. CSS Grid. Each screen gets one section. Each section contains two sub-rows: light, then dark. Each sub-row is a 6-column grid of captures (web desktop, web tablet, web mobile, macOS wide, macOS narrow, iOS).

Visual sketch of the output page:

```
═══════════════════════════════════════════════════════════════════
  Demo Demo — Quad Comparison
  Generated YYYY-MM-DD  •  Brand: coral/violet (override of amber)
═══════════════════════════════════════════════════════════════════

▾ Sign in
  Light
  ┌─Web 1280─┐ ┌─Web 768─┐ ┌Web 375┐ ┌macOS wide─┐ ┌mac narrow┐ ┌iOS 17 Pro┐
  │   .png   │ │  .png   │ │ .png  │ │   .png    │ │   .png   │ │   .png   │
  └──────────┘ └─────────┘ └───────┘ └───────────┘ └──────────┘ └──────────┘
  Dark
  ┌──────────┐ ┌─────────┐ ┌───────┐ ┌───────────┐ ┌──────────┐ ┌──────────┐
  │   .png   │ │  .png   │ │ .png  │ │   .png    │ │   .png   │ │   .png   │
  └──────────┘ └─────────┘ └───────┘ └───────────┘ └──────────┘ └──────────┘

▾ Dashboard — Activity
  ...
```

Implementation: use CSS grid with `grid-template-columns: repeat(6, 1fr)`, captures rendered with `<img>` at natural width, captioned via `<figcaption>`. Pure CSS, no JavaScript. Total file should be a few hundred lines including the embedded captures.

### Headless web capture choice

You have three options for the headless web capture; pick the one already established in the repo:

1. **Chrome DevTools Protocol (CDP) over WebSocket from Crystal** — the canonical pattern. `scripts/capture_amber_demo_screenshots.cr` (and its thin re-export `scripts/capture_web_demo_screenshots.cr`) launches headless Chrome with `--remote-debugging-port`, opens an `HTTP::WebSocket` to a new target's `webSocketDebuggerUrl`, and exchanges JSON-RPC (`Page.navigate`, `Emulation.setDeviceMetricsOverride`, `Emulation.setEmulatedMedia`, `Page.captureScreenshot`, `Input.dispatchKeyEvent`, `Runtime.evaluate`). See `../../rubric/behavior-simulation-toolkit.md` §3 for the full surface. **Required.**
2. **Standalone Puppeteer/Playwright script** — would require Node, which conflicts with the repo's "no npm" rule. **Forbidden.**
3. **`chromedp` via shell** — possible but adds a Go dependency. **Forbidden.**

Use option 1 — extend the existing `scripts/capture_*_demo_screenshots.cr` (reuse its `DevTools` class verbatim) or copy the wrapper into a new sibling script. Do not introduce a new browser-automation dependency.

---

## Step-by-step commit plan

Each bullet is one commit (or a small group of commits if the diff is large). Commit subjects follow `[Phase 6] {imperative summary}` per the universal criteria.

**(a) Foundation — brand + folder skeleton**

1. `[Phase 6] Scaffold initiative-demo folder structure`
   - Create the folder tree under `samples/initiative-cross-platform-ui-demo/` with empty placeholder files where needed (just enough to anchor subsequent commits).
   - Add the `assets/placeholders/*.svg` files (avatar 1–6, hero, wordmark). Keep them geometric — circles, gradients — license-clean.

2. `[Phase 6] Declare Demo brand override (coral/violet)`
   - Write `src/brand.cr` exactly as specified above. Verify it compiles by running `crystal build --no-codegen samples/initiative-cross-platform-ui-demo/src/brand.cr` against the phase-1 token API. Adjust accessor names if phase 1 used different names.

3. `[Phase 6] Add themed copy + mock data modules`
   - Write `src/content/copy.cr`, `src/content/friends.cr`, `src/content/transactions.cr`. Constants only. No logic.

**(b) Sign-in screen**

4. `[Phase 6] Add sign-in screen view`
   - Write `src/screens/sign_in.cr` per the per-screen spec. Compile-check it against web target via `crystal build --no-codegen`.

**(c) Dashboard + tabs**

5. `[Phase 6] Add dashboard shell with 3-tab TabView`
   - `src/screens/dashboard.cr` — shell, NavigationStack root, TopBar, TabView wiring.

6. `[Phase 6] Add dashboard Activity tab (card grid)`
   - `src/screens/dashboard_activity.cr`. Tap routing to detail via NavigationLink.

7. `[Phase 6] Add dashboard Friends tab (sectioned list)`
   - `src/screens/dashboard_friends.cr`.

8. `[Phase 6] Add dashboard Settings tab (form preview)`
   - `src/screens/dashboard_settings.cr`.

**(d) Detail screen**

9. `[Phase 6] Add transaction detail screen with adaptive layout`
   - `src/screens/detail.cr`. Wide vs narrow layouts via responsive primitives from phase 2.

**(e) Settings screen**

10. `[Phase 6] Add full settings screen exercising form widgets`
    - `src/screens/settings.cr`. All form widgets — Picker, Slider, Toggle, ColorPicker, TimePicker, SegmentedControl, Stepper, TextField, Button.

**(f) Tier 3 screen**

11. `[Phase 6] Add Tier 3 demo screen with platform branches`
    - `src/screens/tier3_demo.cr`. ActionSheet (iOS) / ConfirmationDialog (macOS) / ActionSheetWithWebFallback (web). ContextMenu (Apple) / ContextMenuWithWebFallback (web). No HapticFeedback in this initiative — out of scope.

**(g) Build wiring**

12. `[Phase 6] Wire web build for initiative demo`
    - `web/build_web.cr`, `web/shell.html.ecr`. Run, verify `output/initiative-demo/*.html` exist and load in a browser.

13. `[Phase 6] Wire macOS build for initiative demo`
    - `macos/build_macos.cr`, `macos/Makefile`, `macos/window_helper.m`, `macos/Info.plist.template`. Run `make build`, verify binary exists, launch it, verify the sign-in screen renders in a window.

14. `[Phase 6] Wire iOS build for initiative demo`
    - `ios/bridge.cr`, `ios/build_ios_lib.sh`, `ios/project.yml`, `ios/Sources/*.swift`. Run `make ios`, verify the app installs and launches in iPhone 17 Pro simulator and shows the sign-in screen.

**(h) Quad-comparison harness**

15. `[Phase 6] Add capture_demo_quad.cr screenshot harness`
    - `scripts/capture_demo_quad.cr`. Implement web capture first (model on existing `capture_web_demo_screenshots.cr`), then macOS, then iOS. Verify it produces all captures in the evidence subfolder.

16. `[Phase 6] Render quad-comparison HTML grid`
    - Extend the harness to assemble the captures into `quad-comparison.html` via CSS grid. Verify the page opens correctly in a browser.

**(i) Documentation**

17. `[Phase 6] Document initiative demo build + viewing`
    - Write `samples/initiative-cross-platform-ui-demo/README.md`. Sections: What this demo is, How to build (per platform), How to view the quad comparison, How the brand override works, Per-screen reference.

**(j) Top-level Make targets (if a repo-root Makefile exists)**

18. `[Phase 6] Add make web / make macos / make ios / make demo-quad targets`
    - If the repo root has a Makefile, extend it. If not, add a thin `samples/initiative-cross-platform-ui-demo/Makefile` that wraps the three platform builds. Either way the validator should be able to run `make demo-quad` and get the quad-comparison page.

**(k) Tests**

19. `[Phase 6] Add cross-target spec for screen rendering`
    - Spec file at `spec/samples/initiative_cross_platform_ui_demo_spec.cr`. For each screen ID, instantiate the view and assert it builds without raising. Run under all three target flags (`-Dmacos`, `-Dios`, no flag for web). At minimum, the spec verifies the constructors compile and return a non-nil `UI::View`.

Typical commit count: 18–22 commits. Bias toward smaller commits; the validator's failure modes are easier to localize that way.

---

## Testing requirements

The minimum bar:

1. **Cross-target spec passes** (`crystal spec spec/samples/initiative_cross_platform_ui_demo_spec.cr`). The spec must run under default web target and under `-Dmacos`. Under `-Dios` it should at minimum verify the C-ABI export function compiles (the actual rendering happens inside the simulator and is verified by XCUITest).

2. **Three builds succeed:**
   - Web: `crystal run samples/initiative-cross-platform-ui-demo/web/build_web.cr` produces all 8 HTML files plus `theme.css`.
   - macOS: `make -C samples/initiative-cross-platform-ui-demo/macos build` produces a working binary that launches and renders the sign-in screen.
   - iOS: `make -C samples/initiative-cross-platform-ui-demo/ios build` produces an iOS app that installs and launches on iPhone 17 Pro simulator without crash.

3. **Quad-capture harness runs end-to-end** and produces:
   - All evidence PNGs in `output/initiative-demo/quad-evidence/`
   - The final `output/initiative-demo/quad-comparison.html`
   - The HTML opens in a browser without broken image references

4. **Existing test suite stays green** (`crystal spec` from repo root).

5. **All four platforms still build** per the phase 1 cross-platform invariant — verify `crystal build --no-codegen src/asset_pipeline.cr` and the existing HIG sample builds in `samples/cross_platform/` still work.

You are not required to run the validator's full checklist yourself; you are required to make those checks possible.

### Required handoff artifacts for the validator's brand-override check

The validator's `brand.override-visible` check (validation.md) uses a CIE Lab ΔE measurement against a fixture, not a comment-out/revert dance. To make that check runnable, your handoff must include two fixture files committed alongside the demo:

1. **`samples/initiative-cross-platform-ui-demo/inspections/sign-in-primary-button.bbox.json`** — the bounding box (x, y, width, height in pixel coords on the web-desktop-light sign-in capture) of the primary call-to-action button. Produced by your quad-capture harness during the sign-in capture. Schema:
   ```json
   { "screen": "sign-in", "viewport": "web-desktop-light", "primary_cta_bbox": { "x": 540, "y": 384, "width": 200, "height": 48 } }
   ```
2. **`samples/initiative-cross-platform-ui-demo/inspections/amber-default-primary-button.rgb.json`** — the canonical sRGB triple for the amber-default theme's primary button background (the value `--ap-color-brand-primary` resolves to after OKLCH→sRGB conversion in Phase 1's web generator). Compute once during your harness setup; commit. Schema:
   ```json
   { "amber_default_brand_primary_srgb": [62, 119, 109], "source": "DesignTokens::WebGenerator(AmberBrand).resolve_srgb(:brand_primary)" }
   ```

If either fixture is missing, the validator marks `brand.override-visible` as `blocked: true` and the team lead either supplies the fixture or sends the phase back. Pre-empt this by committing both during your quad-capture step.

---

## Definition of done

You are done when **all** of the following are true:

1. Every step in the commit plan above is committed on the phase branch `phase-06-side-by-side-demo-app`.
2. `make web`, `make macos`, `make ios` (or the equivalent commands documented in the demo README) all complete successfully on a clean checkout.
3. `crystal run scripts/capture_demo_quad.cr` completes without error and produces `output/initiative-demo/quad-comparison.html`. You have opened that page in a browser and visually confirmed:
   - All 5 screens are present.
   - Every cell shows a non-blank image.
   - Light and dark variants are visibly different.
   - The brand reads as coral/violet, not amber.
4. The cross-target spec passes under all three target flags.
5. The existing test suite is green.
6. `samples/initiative-cross-platform-ui-demo/README.md` exists and documents the build commands a fresh contributor would need.
7. Your handoff message to the team lead names every commit hash, lists any deviations from this brief (with reasoning), and explicitly confirms the four claims from the Goal section above.

You are **not** done when:

- Any of the three platform builds is "almost working" or "compiles but needs manual fixup."
- The quad-comparison page exists but some cells are blank or broken.
- The brand override is "in the right ballpark" but visually identical to amber at a glance.
- Tests are passing because you skipped writing them.

If you discover any of these gaps in your final review, fix them before handoff. Reading "done" honestly is a load-bearing skill — see the universal criteria.

---

## Known concerns to surface in your handoff

In your handoff `Known concerns` section, address each of these explicitly:

1. **Did any phase 1–5 deliverable look incomplete during integration?** If yes, name the phase and what felt off. The team lead will decide whether to remediate that phase before the validator runs phase 6.
2. **Did you have to add or modify any widget in `src/ui/views/` to make a screen renderable?** This is out of scope per the phase brief — if you did it, justify it.
3. **iPhone 17 Pro simulator availability** — confirm the simulator was installed and runtime present (`xcrun simctl list runtimes`). If you had to substitute, name the substitute and explain.
4. **Any flakiness in the capture harness** — if a screenshot intermittently fails, document the workaround and whether you addressed the root cause.
5. **Brand override visibility** — embed two thumbnail screenshots in the handoff (one default amber demo from phase 1, one Demo coral demo from phase 6) so the team lead can adjudicate "is the override visibly different" without rebuilding.

---

End of phase 6 implementation brief.
