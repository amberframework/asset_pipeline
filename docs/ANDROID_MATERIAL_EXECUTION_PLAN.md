# Android Material Execution Plan

Date: April 17, 2026

Audience: the next agent working inside `asset_pipeline` on Android, Material
Design, web-token unification, and cross-platform demo quality.

## Goal

Build a complete Android system with the same rigor already applied to Apple:

1. real Android-native rendering, not placeholder boxes
2. Material Design 3 grade defaults, spacing, motion, and theme behavior
3. screenshot-based validation with a trustworthy ledger
4. a showable cross-platform demo story spanning macOS, iOS, Android, and web
5. a central design-token contract that can funnel brand assets down into each
   platform renderer

This is not a small “theme pass.” It is the next major platform phase.

## What "Done" Means

Android is only considered done for this phase when all of the following are
true:

1. the Android renderer has no major placeholder surfaces for common app UI
2. Material 3 semantics are reflected in defaults, not just available as
   optional styling
3. there is an Android showcase host equivalent to the Apple validation hosts
4. the Android validation ledger has current screenshot evidence and written
   judgment for auditable studies
5. the shared token system can drive Apple, Android, and web from one source
6. there is at least one coherent demo app / showcase flow that reads as the
   same product across desktop, phone, and web

## Current State of the Repo

### Good news

- `asset_pipeline` already has a real `UI::Android::Renderer`.
- `UI::Theme` already includes Material-flavored semantic color roles and a
  baseline Material theme preset.
- the web renderer can already inject theme CSS custom properties.
- the repo already has a brand-kit/token showcase generator.
- Amber CLI already scaffolds native app projects that include Android build
  scripts, Gradle, and tests.

### Important limitations

Android is not yet at Apple’s level of rigor.

The Android renderer still has placeholder or stub-like behavior for several
important surfaces, including:

- `UI::MapView`
- `UI::ChartView`
- `UI::WebViewComponent`
- `UI::ColorPicker`
- `UI::VideoPlayer`
- `UI::ActivityView`

There is also no Android showcase host yet under `samples/cross_platform/`
equivalent to:

- `samples/cross_platform/macos_host/hig_showcase.cr`
- `samples/cross_platform/ios_host/hig_bridge.cr`

That missing validation host is a major reason Android will feel slower unless
we tackle it directly.

## Repo Boundary

Do not blur this line:

- `asset_pipeline` owns renderer behavior, shared UI primitives, platform
  bridges, Android/Material validation, and token consumption.
- `amber` owns domain mapping and runtime patterns.
- `amber_cli` owns project generation, target wiring, and regeneration
  ergonomics.

For this Android phase, work in `asset_pipeline` should focus on the render
layer, token consumption, validation machinery, and demo surfaces.

## Core Deliverables

### 1. Android Material renderer parity

Deliver:

- honest Android-native implementations for the currently-placeholder families
- Material 3 defaults for:
  - typography
  - shape
  - elevation
  - color roles
  - state overlays
  - spacing and component padding
- Android-specific adaptive layout behavior where appropriate

Acceptance bar:

- common app surfaces no longer render as generic `android/view/View` stubs
- component defaults look intentional before product-specific styling
- the renderer is predictable enough to validate visually

### 2. Unified token funnel

Deliver:

- a clearer shared token contract for:
  - colors
  - typography
  - spacing
  - radii
  - elevation
  - icon families
  - textures / images
  - sound references
  - motion timing
- mapping rules from the shared token model to:
  - Apple theme consumption
  - Android Material consumption
  - web CSS custom properties

Acceptance bar:

- one brand definition can materially change all three platform outputs
- the web renderer and brand-kit output stop being a side path and become part
  of the same design system story

### 3. Android validation host and ledger

Deliver:

- a new Android showcase host under `samples/cross_platform/android_host/`
- screenshot capture scripts
- a validation ledger parallel to the Apple workflow
- light / dark screenshot evidence for auditable studies

Acceptance bar:

- Android visual review is no longer “look at a random screen and guess”
- there is a stable HTML dashboard for Android validation results
- evidence freshness can be audited automatically

### 4. Cross-platform demo app

Deliver one coherent demo experience rendered across:

- macOS
- iOS
- Android
- web

The demo should not be another loose collage of components. It should show a
single product story with:

- navigation
- list-detail content
- search / filtering
- forms / editing
- settings / appearance
- media / map / web or system surface where useful

Acceptance bar:

- the product identity is recognizable across all targets
- the design language reads as centrally controlled but natively expressed
- screenshots are something we would be comfortable showing publicly

## Recommended Workstreams

Use parallel lanes, but keep ownership clean.

### Lane A: Android renderer and bridge

Owner responsibilities:

- `src/ui/renderers/android_renderer.cr`
- any Android JNI bridge additions
- Android-specific native wrappers or support scripts

Primary tasks:

1. replace placeholders for map, chart, web view, color picker, video, and
   activity/share flows
2. bring button, text input, cards, dialogs, snackbars, app bars, list items,
   chips, menus, and segmented controls into Material 3 shape
3. tighten defaults until screenshots are believable without custom styling

### Lane B: Theme + token unification

Owner responsibilities:

- `src/ui/theme.cr`
- `src/ui/renderers/web_renderer.cr`
- `src/generators/brand_kit.cr`
- any shared design-token docs or support code

Primary tasks:

1. expand the token contract beyond the current color/typography/shape basics
2. ensure web output and Android consumption read from the same semantic system
3. define how fonts, textures, and sounds are referenced without forcing the
   UI layer to own business content

### Lane C: Android showcase host + validation

Owner responsibilities:

- `samples/cross_platform/android_host/**`
- Android screenshot capture scripts
- Android validation reports, manifests, and dashboard files

Primary tasks:

1. create the Android equivalent of the Apple showcase hosts
2. build repeatable screenshot capture for light / dark
3. create the Android review rubric and evidence audit flow
4. keep the ledger honest as studies are promoted

### Lane D: Integrator / demo steward

One owner only.

Responsibilities:

- choose acceptance thresholds
- review screenshots
- keep the Android worklist honest
- maintain the cross-platform demo compositions
- own commits that touch shared validation truth or cross-platform demo files

Do not let multiple workers write the same validation ledger files in parallel.

## Concrete Phase Plan

### Phase 0: Environment stabilization

Before big implementation work:

1. fix the broken local API 34 AVD by installing the missing system image
2. keep the two existing Android 15 / API 35 Pixel 6 AVDs
3. add one tablet-class AVD for adaptive layout validation
4. document emulator boot / capture conventions

Current local machine status:

- installed emulator: `36.4.9`
- installed platform-tools: `36.0.2`
- installed build-tools: `34.0.0`, `35.0.0`
- installed platforms: `android-34`, `android-35`
- installed system image: `system-images;android-35;google_apis;arm64-v8a`
- usable AVDs:
  - `crystal_test`
  - `test_api35`
- broken AVD:
  - `Pixel_3a_API_34_extension_level_7_arm64-v8a`
  - missing `android-34` Google APIs arm64 system image

Recommended local setup commands:

```bash
sdkmanager "system-images;android-34;google_apis;arm64-v8a"

avdmanager create avd \
  -n pixel_8_api34 \
  -k "system-images;android-34;google_apis;arm64-v8a" \
  -d pixel_8

avdmanager create avd \
  -n pixel_tablet_api35 \
  -k "system-images;android-35;google_apis;arm64-v8a" \
  -d pixel_tablet
```

### Phase 1: Token and Material contract

Implement first:

1. a sharper semantic token model in `UI::Theme`
2. explicit mapping of shared tokens to Material 3 semantics
3. matching web CSS custom property output
4. brand-kit updates so the generated token showcase reflects the unified model

Do this before a huge component pass, otherwise Android defaults will drift.

### Phase 2: Material component parity

Priority order:

1. surfaces visible in every app:
   - buttons
   - text fields
   - cards
   - dialogs
   - menus
   - list items
   - app bars / toolbars
   - navigation
2. content/media surfaces:
   - web view
   - map
   - video
   - chart
3. supporting Material patterns:
   - snackbar
   - chips
   - segmented controls
   - pickers
   - disclosure / expansion patterns

Each family should exit this phase with:

- real Android-native rendering
- Material 3 defaults
- screenshotable behavior in the Android host

### Phase 3: Android validation system

Create:

- `samples/cross_platform/android_host/`
- `scripts/run_android_material_tests.sh`
- `docs/android-material-validation/index.html`
- Android evidence manifests and reports

Use the Apple workflow as inspiration, not as an excuse to clone it blindly.
Android should have a Material-specific rubric:

- component hierarchy
- density and spacing
- typography scale
- elevation and surfaces
- state treatment
- large-screen adaptation
- light / dark theme fidelity

### Phase 4: Cross-platform demo app

Once renderer and validation are credible, create one demo with the same
information architecture across:

- macOS
- iOS
- Android
- web

Recommended demo shape:

1. home / dashboard
2. list-detail workspace
3. composer / editor
4. search + filters
5. settings / theme controls
6. media / map / system surfaces page

The goal is not “same screenshot everywhere.” The goal is:

- same brand
- same product identity
- native navigation and surface choices per platform

### Phase 5: Android shell and extension surfaces

After in-app UI is real, close the Android system-owned surface story:

- notifications
- app shortcuts
- widgets
- share intents
- other export-oriented Android shell surfaces as appropriate

These should follow the same honest rule used on Apple:

- model and export truthfully
- do not fake screenshots for system-owned UI

## Parallel Emulator Strategy

The machine can move faster if emulator use is disciplined.

### What to run in parallel

Safe:

- one phone emulator
- one second phone or tablet emulator
- one build lane

Avoid:

- more than two active emulator UI capture lanes unless the machine proves it
  can sustain it
- rebuilding the Crystal shared library separately for every shard of the test
  matrix

### Recommended strategy

1. build the Android shared library once
2. boot two emulators up front
3. shard screenshot work by component family, not by random file edits
4. run capture/test batches against fixed `ANDROID_SERIAL` targets
5. keep one emulator phone-focused and one tablet-focused

Recommended boot commands:

```bash
/Users/crimsonknight/Library/Android/sdk/emulator/emulator \
  @crystal_test -port 5554 -no-snapshot-save

/Users/crimsonknight/Library/Android/sdk/emulator/emulator \
  @pixel_tablet_api35 -port 5556 -no-snapshot-save
```

Recommended targeting pattern:

```bash
ANDROID_SERIAL=emulator-5554 ./scripts/run_android_material_tests.sh --only buttons,dialogs
ANDROID_SERIAL=emulator-5556 ./scripts/run_android_material_tests.sh --only sidebars,split-views
```

Notes:

- build once, reuse many times
- serialize Gradle assemble if it fights itself
- parallelize emulator test/capture, not core compilation
- keep ports fixed so CI or local scripts are deterministic

## Concrete Gaps to Close First

The first agent should not wander. Start here:

1. install the missing API 34 system image and create the tablet AVD
2. write down the Android validation folder structure before screenshot files
   start proliferating
3. create the Android showcase host skeleton
4. replace the highest-visibility Android placeholders:
   - `UI::WebViewComponent`
   - `UI::MapView`
   - `UI::VideoPlayer`
   - `UI::ChartView`
5. tighten Material defaults for:
   - buttons
   - text fields
   - cards
   - app bars
   - dialogs
6. only then start broad screenshot generation

## Suggested File Ownership

To reduce merge tax:

- Worker A:
  - `src/ui/renderers/android_renderer.cr`
  - Android bridge / Android support scripts
- Worker B:
  - `src/ui/theme.cr`
  - `src/ui/renderers/web_renderer.cr`
  - `src/generators/brand_kit.cr`
- Worker C:
  - `samples/cross_platform/android_host/**`
  - Android validation reports / manifests / dashboard
- Integrator:
  - cross-platform demo files
  - final validation truth
  - commits that touch shared ledgers or dashboards

## Noise to Ignore in the Current Worktree

As of this handoff, the following are pre-existing noise or unrelated Apple
worktree leftovers. Do not “clean them up” as part of Android work unless you
are explicitly taking ownership of them:

- `.DS_Store`
- modified files under:
  - `.claude/skills/apple-platform-guide/validation/evidence/*.json`
- modified:
  - `.claude/skills/apple-platform-guide/validation/index-43of65-2026-04-17.html`
- untracked:
  - `.claude/skills/apple-platform-guide/validation/evidence/complications.json`
  - `samples/cross_platform/macos_app.cr`
  - `samples/cross_platform/showcase.html`
  - `samples/cross_platform/macos_host/.claude/`

Ignore that noise unless the Android work explicitly depends on it.

## Progress Reporting Expectations

The next agent should report progress in units that matter:

1. placeholder families eliminated
2. Material-grade families accepted
3. Android studies with current screenshot evidence
4. demo screens completed across all targets
5. token categories unified across Android / Apple / web

Avoid vague status like “did some Android work.”

## Bottom Line

This Android phase is feasible, and the repo already has real leverage:

- Android renderer foundation exists
- Material token concepts exist
- native app scaffolding already exists in Amber CLI
- Apple has shown the validation pattern works

But it will only move quickly if we treat Android as a full platform program,
not as a loose series of renderer patches.
