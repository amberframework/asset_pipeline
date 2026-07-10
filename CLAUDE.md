# Asset Pipeline

A front-end library written in pure Crystal that provides type-safe HTML generation, utility-first CSS, JavaScript/Stimulus management, and reactive server-side components. Ships as a single shard with zero runtime dependencies.

## Architecture

```
src/components/
  elements/          94 HTML element classes (Div, Input, Table, etc.)
  base/              Component base classes (Stateless, Stateful, Reactive)
  css/               CSS engine (ClassBuilder, Config, Generator, Parser)
  reactive/          WebSocket-based real-time component updates
  examples/          6 reference components (Button, Card, Counter, Form, Chat, LiveSearch)
  integration.cr     Amber framework helpers and view macros

src/asset_pipeline.cr  FrontLoader — import maps and script rendering
src/asset_pipeline/
  stimulus/          StimulusRenderer — auto-detects controllers from import maps
  import_map/        ESM import map management
```

## Key Entry Points

- `Components::Elements::*` — 94 type-safe HTML element classes matching HTML tags
- `Components::StatelessComponent` — cacheable, pure-render components
- `Components::StatefulComponent` — components with internal JSON state
- `Components::Reactive::ReactiveComponent` — WebSocket-enabled real-time components
- `Components::CSS::ClassBuilder` — fluent DSL for building CSS class strings
- `Components::CSS::Config` — design token configuration (OKLCH colors, spacing, typography)
- `Components::CSS::Engine::Generator` — generates utility CSS with @layer structure
- `AssetPipeline::FrontLoader` — JavaScript import map and Stimulus management
- `UI::App` — declarative app + route registry
- `UI::Screen` — screen authoring with `build(ctx)`
- `UI::Controller` — native action handler
- `UI::ActionDispatcher` — routes action refs to controllers + applies ActionResult
- `UI::ActionResult` — Navigate / Pop / Rerender / ReplaceRoot / RenderInline
- `UI::FormState` — controlled input state across renders
- `UI::ScreenContext` — Native + Web variants passed to `build(ctx)`
- `UI::AmberIntegration.routes_for(App)` — Amber web integration macro

## Naming Conventions

- Element classes match HTML tag names: `Div`, `Article`, `Input`, `Th`, `Dialog`
- Factory methods on `Input`: `.text()`, `.email()`, `.radio()`, `.search()`, `.range()`, `.color()`, etc.
- Factory methods on `Meta`: `.charset()`, `.viewport()`, `.description()`
- Factory methods on `Link`: `.stylesheet()`, `.preload()`, `.preconnect()`
- Component CSS registered via `component_css <<-CSS ... CSS` macro
- Utility classes follow Tailwind naming: `bg-blue-500`, `hover:text-white`, `sm:flex`

## Design Philosophy

- No templates — all HTML generated from Crystal classes with compile-time type safety
- Utility-first CSS with OKLCH color space and `@layer` cascade structure
- WCAG 2.2 AA accessibility built into defaults (focus rings, motion preferences, ARIA states)
- Design-system web helpers are vanilla JavaScript: no Node, npm, bundlers, or
  Stimulus. The legacy FrontLoader path still supports ESM import maps and
  Stimulus for non-design-system assets.
- Components render to strings via `.render()` for server-side rendering

## Cross-Platform UI System

The asset_pipeline extends beyond web with a cross-platform native UI component system. A single Crystal source tree compiles to web (HTML), macOS (AppKit), iOS (UIKit), and Android (JNI/Views) using Crystal's compile-time `flag?()` for zero-overhead platform dispatch.

**Core model:** App code builds a tree of `UI::View` objects. A compile-time-selected `PlatformRenderer` (a `PlatformVisitor` subclass) walks the tree and produces native UI. The web renderer delegates to `Components::Elements`; native renderers call through ObjC or JNI bridges.

### UI::App application architecture

Phase 8 added the app-level architecture for cross-platform screens:

- `UI::App` declares routes via the `screen` macro.
- `UI::Screen` builds views from a `ScreenContext` (shared across web + native).
- `UI::Controller` handles native actions and returns `UI::ActionResult`.
- `UI::ActionDispatcher` routes native action refs and applies navigation/render results.
- `UI::FormState` carries controlled input values across renders.
- `UI::AmberIntegration.routes_for` wires a `UI::App` to a full-server Amber target.

**Target split:**

| Target | Path |
|---|---|
| macOS / iOS native | `UI::ActionDispatcher` |
| Amber full-server web | `UI::AmberIntegration.routes_for` |
| Voyager static-site web | `Voyager.build_route` (sample-local, deliberate; see `docs/initiative-cross-platform-ui/architecture/web-target-position.md`) |

Voyager's static-site web target is intentionally NOT dispatcher-backed. See the web target position note for the rationale.

Phase 8 closed the ergonomic MVC-style app API in May 2026 across 8A, 8B, 8C, 8D.1, 8D.2, 8D.3a, and 8D.3b.

Full guide: `ui-app` skill + `docs/initiative-cross-platform-ui/tutorial-ui-app.md`.

### Design philosophy: beauty-by-default, overridable for brand

A `UI::View` must produce the most beautiful Apple-native render possible with zero configuration on iOS / iPadOS / macOS — Liquid Glass materials, system typography, semantic colors, correct hit targets, destructive/cancel role wiring, SF Symbols, and section chrome. This is the library's North Star: a developer who writes `UI::Sheet.new([...])` gets a HIG-authentic Apple sheet by default, in both light and dark appearance. When they want to impose their brand voice, they override explicit knobs on the view or theme — and every component usage doc must document both the default and the override paths.

Validation work enforces this standard: see `.claude/agents/apple-platform-designer/agent.md` for the per-iteration playbook. Every surface component is validated in four captures (macOS light + dark, iOS light + dark) against the HIG reference illustration, and every component usage doc must include both a "Light / dark appearance notes" section and a "Customization / brand override" section before it counts as shipped. Preview scenes must follow `.claude/skills/apple-platform-guide/foundations/preview-composition.md` and `.claude/skills/apple-platform-guide/foundations/preview-screen-recipes.md`: default to a component study, choose the prescribed screen recipe, add relationship/app context only when the HIG behavior requires it, keep brand/app chrome subordinate to the component, and declare the component state, palette role map, alignment rails, and required anatomy. Before any row can pass, run `.claude/skills/apple-platform-guide/validation/audit_evidence.py`; for P0 rows and pass candidates also run `scripts/codex_hig_review.sh <slug>` and preserve the resulting `validation/codex-reviews/<slug>.json`. Stale report/screenshot pairs, missing light/dark captures, debug labels, clipped primary content, confusing preview stages, off-palette raw system colors, unowned alignment rails, skipped target-platform components, unaddressed Codex findings, and unproven Liquid Glass must stay pending for rework.

**Checkpoint commit on every passing slug.** When the design-critic agent (`.claude/agents/design-critic/agent.md` — June, the staff-designer persona) returns `PASS` or `PASS_WITH_NOTES` for a slug, the orchestrator (or the apple-platform-designer agent itself per its checkpoint playbook) MUST commit the slug's work as a checkpoint. Format: `feat(<slug>): pass design-critic at iteration N — <verdict>` with per-appearance verdicts in the body. Never commit on a self-graded pass or NEEDS_WORK. The checkpoint is the safety net that allows bisecting progress and reverting regressions.

### Key Architecture Decisions

- Native components only — no custom drawing engine (unlike Flutter)
- Layout delegated to platform engines (NSStackView, UIStackView, LinearLayout, CSS flexbox)
- Visitor pattern for platform dispatch — adding a view type = one method per renderer
- `NativeHandle` with explicit `ReleaseStrategy` for memory management
- `CallbackRegistry` prevents Crystal Proc GC while native code holds function pointers

### Current View Types (59)

**Core (9):** `Label`, `Button`, `VStack`, `HStack`, `ZStack`, `Image`, `TextField`, `ScrollView`, `Spacer`

**Controls / Selection (P1):** `Toggle`, `Checkbox`, `RadioGroup`, `Slider`, `Stepper`, `SegmentedControl`, `Picker`, `DatePicker`, `TimePicker`, `ColorPicker`, `SecureField`, `SearchField`, `TextArea`, `TextEditor`

**Navigation / Surfaces (P1):** `NavigationStack`, `NavigationLink`, `NavigationSplitView`, `TabView`, `Toolbar`, `Sheet`, `Popover`, `Alert`, `ConfirmationDialog`, `Snackbar`, `Card`, `Surface`, `Divider`, `Form`, `Grid`

**Feedback (P1):** `ProgressView`, `ActivityIndicator`

**Buttons (P1):** `IconButton`, `LinkButton`, `MenuButton`, `ToggleButton`

**Rich / Media (P2):** `RichText`, `AsyncImage`, `VideoPlayer`, `MapView`, `WebViewComponent`, `ChartView`, `Tooltip`

**Shapes / Drawing (P2):** `Circle`, `Rectangle`, `RoundedRectangle`, `Capsule`, `Canvas`, `PathView`

**Apple glass (P1):** `GlassBackground` — maps to `NSVisualEffectView` / `UIVisualEffectView + UIBlurEffect`.

Source files in `src/ui/views/`. Canonical core mapping:

| UI::View | Web | macOS (AppKit) | iOS (UIKit) | Android |
|----------|-----|----------------|-------------|---------|
| `Label` | `<span>` | NSTextField | UILabel | TextView |
| `Button` | `<button>` | NSButton | UIButton | MaterialButton |
| `VStack` | flex column | NSStackView | UIStackView | LinearLayout |
| `HStack` | flex row | NSStackView | UIStackView | LinearLayout |
| `ZStack` | position:relative | NSView | UIView | FrameLayout |
| `Image` | `<img>` | NSImageView | UIImageView | ImageView |
| `TextField` | `<input>` | NSTextField | UITextField | EditText |
| `ScrollView` | overflow:auto | NSScrollView | UIScrollView | ScrollView |
| `Spacer` | flex:1 | gravity space | UILayoutGuide | Space weight=1 |
| `GlassBackground` | (backdrop-filter) | NSVisualEffectView | UIVisualEffectView | elevation fallback |

For the full cross-platform mapping (SwiftUI / UIKit / AppKit / Compose / Android View / HTML) see the `component-mapping-matrix` skill.

## Tier model for cross-platform widgets

Every widget in `src/ui/views/` falls into one of three tiers, documented
canonically at
[`docs/initiative-cross-platform-ui/tier-matrix.md`](docs/initiative-cross-platform-ui/tier-matrix.md):

* **Tier 1 (Brand-universal)** — visual primitives and layout helpers
  (`VStack`, `HStack`, `Card`, `Circle`, etc.). No platform-idiomatic
  chrome; renders identically modulo platform unit conventions. No
  gating required.
* **Tier 2 (Platform default)** — universal API surface that platform
  renderers map to the idiomatic native widget (`Button`, `Slider`,
  `Sheet`, `Picker`, etc.). The Phase 3 SwiftUI facade gives them
  Apple polish; the web renderer emits matching HTML. No gating.
* **Tier 3 (Platform-only)** — widgets with no honest cross-platform
  analog (`ActionSheet`, `ContextMenu`, `PathControl`). Each is wrapped
  in a `{% if flag?(...) %}` macro guard so naming the class without
  the right `-D` flag produces a compile-time error naming the missing
  flag, the explicit `*WithWebFallback` companion class, and an example
  guard. Every Tier 3 widget ships a `*WithWebFallback` sibling that
  renders the native chrome on the supported platform and an accessible
  fallback on every other target.

When adding a Tier 3 widget, follow `src/ui/views/action_sheet.cr` as the
template: gate the class definition with `{% if flag?(:ios) %}`, route the
non-matching branch through a stub file in `src/ui/views/_gate_stubs/`
(this prevents Crystal's macro engine from firing `{% raise %}` eagerly
during outer-guard expansion), and ship a `*WithWebFallback` sibling for
the cross-platform path. Document the new row in
`docs/initiative-cross-platform-ui/tier-matrix.md` in the same commit.

Use `AssetPipeline::Platform.requires(:ios) do ... end` in application
code to gate platform-only logic; reserve raw `{% if flag?(:ios) %}` for
library code under `src/ui/`. The `Platform.requires` macro produces the
same actionable compile-time error format as the widget gates when the
build is missing the required flag.

## Design tokens

The canonical Tier 1 brand contract lives in `src/ui/design_tokens.cr`
(`UI::DesignTokens::Tokens`). It carries 23 semantic color roles in both light
and dark palettes, a 35-step spacing scale, type / radius / shadow / motion
scales, breakpoints, and `touch_target_minimum_px`. Colors are stored as both
OKLCH (the source of truth) and a baked sRGB triple.

Per-platform generators emit committed dist files from this single source:

| Generator | Output | Consumer |
|-----------|--------|----------|
| `UI::DesignTokens::WebGenerator` | `src/ui/design_tokens/dist/web_tokens.css` | Web renderer's `inject_theme_css` |
| `UI::DesignTokens::AppleGenerator` | `src/ui/design_tokens/dist/AssetPipelineTokens.swift` | Phase 3 SwiftUI bridge |

Regenerate after editing the model:
```bash
crystal run scripts/regenerate_design_tokens.cr
```

The web CSS variable prefix is `--ap-*` (canonical). The legacy `--amber-*`
alias was removed wholesale in Phase 1 of the cross-platform UI initiative;
downstream code must reference `var(--ap-color-brand-primary)` etc.

Consumer apps override the brand by subclassing `UI::DesignTokens::Brand`:
```crystal
class AcmeBrand < UI::DesignTokens::Brand
  protected def override_color_light(palette)
    palette.copy_with(brand_primary: UI::DesignTokens::Color.hex("#1d4ed8"))
  end
end

tokens = UI::DesignTokens::Tokens.default.with_brand(AcmeBrand.new)
```

`Tokens.default.with_brand(brand)` returns a NEW `Tokens` — never mutates the
default. Pass the result into a renderer's `design_tokens` property.

The Android XML generator is deferred to a follow-up phase; see
`docs/initiative-cross-platform-ui/handoff/phase-01-architect-scope-deferral-2026-05-20.md`.
The `UI::DesignTokens::Color#to_android_argb` helper already ships so the
deferred generator has a stable conversion API.

## Quick Reference

| Topic | Skill |
|-------|-------|
| Building UIs with elements and components | `build-ui` |
| Building apps — UI::App + Controller + Dispatcher + FormState + Amber integration | `ui-app` |
| CSS styling, ClassBuilder, design tokens | `css-styling` |
| JavaScript, Stimulus, reactive components (legacy FrontLoader path only) | `javascript` |
| WCAG 2.2 AA accessibility | `accessibility` |
| Cross-platform UI overview (59 UI::View types) | `cross-platform-components` |
| Full API reference for UI::View types | `component-api` |
| Platform renderer implementations | `platform-renderers` |
| Apple glass/translucency effects | `glass-effects` |
| iOS 26 / macOS 26 native component catalog | `ios26-native-components` |
| Android Compose / Material 3 component catalog | `android-compose-components` |
| Cross-platform component mapping matrix | `component-mapping-matrix` |
| Flutter architecture lessons and patterns | `flutter-architecture-lessons` |
| Graphics/3D rendering API survey (stub) | `graphics-rendering` |
| Native UI testing with AXUIElement | `ax-test` |
| Apple HIG corpus (166 pages, offline, searchable) | `apple-hig` |
| **Apple platform developer guide (HIG-backed usage docs)** | **`apple-platform-guide`** |

> **Native compiler:** Use `crystal-alpha` (not `crystal`) for native macOS,
> iOS, and Android builds. Web design-system proof commands use plain `crystal`;
> see `docs/web-design-system/compiler-command-matrix.md`.

## Native App Development Workflow

When building or modifying a native macOS/iOS app with Asset Pipeline UI, follow this cycle:

### 1. Build Views
Use the `build-ui` and `component-api` skills to create views with `UI::VStack`, `UI::Button`, etc.
**Every interactive element MUST have `accessibility_label` set.**

### 2. Compile & Bundle
Build with `-Dmacos` flag. For distribution: `make bundle` → sign → install.

### 3. Test with AXTest (REQUIRED before shipping)
Use the `ax-test` skill. Write specs in `spec/ui/` that:
- Launch the installed .app
- Open each window (settings, wizard, about)
- Verify all accessibility-labeled elements exist
- Take screenshots for visual review
- Run with: `crystal-alpha spec spec/ui/ -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"`

**Do NOT ship a build without running UI tests.** The AXTest library queries the real accessibility tree of the running app — if elements are missing or windows don't render, the tests fail.

### 4. Verify Accessibility
Use the `accessibility` skill for WCAG 2.2 AA compliance. Use `ax-test` to verify VoiceOver can discover all interactive elements.

### 5. Platform Polish
Use `glass-effects` for macOS Liquid Glass, `platform-renderers` for renderer-specific behavior.

## Using in a Project (Shard Dependency)

**Require statement:**
```crystal
require "asset_pipeline/ui"  # Cross-platform UI views (NOT "ui")
```

**Platform flags (REQUIRED for native renderers):**

crystal-alpha does NOT auto-detect platform renderers. You MUST pass the appropriate `-D` flag:
- **macOS:** `-Dmacos` → activates `UI::AppKit::Renderer`
- **iOS:** `-Dios` → activates `UI::UIKit::Renderer`
- **Android:** `-Dandroid` → activates `UI::Android::Renderer`
- **Web (default):** No flag needed → uses `UI::Web::Renderer`

Without the flag, the build will silently use the Web renderer even on macOS.

**ObjC bridge compilation (required for macOS/iOS):**

The AppKit and UIKit renderers use typed C wrappers for ARM64-safe `objc_msgSend` calls. You must compile the bridge before linking:
```bash
clang -c lib/asset_pipeline/src/ui/native/objc_bridge.m \
  -o lib/asset_pipeline/src/ui/native/objc_bridge.o -fno-objc-arc
```

Then include the `.o` in your link flags:
```bash
crystal-alpha build src/app.cr -o bin/app -Dmacos \
  --link-flags="lib/asset_pipeline/src/ui/native/objc_bridge.o \
    -framework AppKit -framework Foundation -lobjc"
```

**Example (minimal macOS native app):**
```crystal
require "asset_pipeline/ui"

main_view = UI::VStack.new(spacing: 12.0)
main_view << UI::Label.new("Hello from Asset Pipeline")
main_view << UI::Button.new("Click Me") { puts "Button pressed!" }

renderer = UI::AppKit::Renderer.new
native_view = renderer.render(main_view)
# native_view is a UI::NativeView wrapping an NSStackView
```

## UI Testing (AXTest)

For native macOS apps, use the built-in AXTest library to verify UI rendering:

```crystal
require "asset_pipeline/ui/ax_test"

app = UI::AXTest::App.launch("/Applications/MyApp.app")
prefs = app.window("Preferences")
prefs.not_nil!.find(label: "Save").should_not be_nil
app.screenshot("/tmp/test.png")
app.terminate
```

**Link flags:** `-framework ApplicationServices -framework CoreFoundation`
**Prerequisite:** Terminal needs Accessibility permission in System Settings.
**Convention:** UI tests go in `spec/ui/`, run with `make test-ui`.

See the `ax-test` skill for the full API reference.

## Build & Test

```bash
crystal spec                    # Run unit tests
crystal run examples/web_design_system_demo.cr
                                # Build the static web design-system proof
crystal run scripts/validate_web_demo.cr
                                # Audit the static web design-system proof
crystal-alpha spec spec/ui/ -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"
                                # Run native UI tests (requires Accessibility permission)
crystal tool format --check     # Check formatting
crystal run src/generators/brand_kit.cr  # Generate style guide
```

## Cross-platform UI initiative CI

PRs to `feature/utility-first-css-asset-pipeline` are gated by the
audit workflow at `.github/workflows/initiative-cross-platform-ui.yml`.
The gate runs Phase 6.5's audit harness against Phase 6/6.8/6.9's
committed baselines. See
`docs/initiative-cross-platform-ui/verification-runbook.md` for the
refresh + debug runbook.
