# Compiler Command Matrix

This matrix separates the current web design-system proof from native platform
builds.

- Use `crystal` for the Phase 1 web/design-system proof commands that generate
  static HTML, run focused component specs, and capture browser evidence.
- Use `crystal-alpha` for native macOS, iOS, and Android platform builds and
  native UI tests, matching the native guidance in `CLAUDE.md`.

Do not switch the web proof to Node tooling. Do not build native platform
renderers with plain `crystal`.
Plain `crystal` is correct for the web proof because it does not link native
frameworks. `crystal-alpha` is required for native targets because it owns the
AppKit/UIKit/JNI link path and the `-Dmacos`, `-Dios`, and `-Dandroid` flag set.

## Current Command Matrix

| Work surface | Compiler | Commands |
| --- | --- | --- |
| Web design-system focused specs | `crystal` | `crystal spec spec/components/css spec/components/assets/font_asset_spec.cr spec/components/examples/example_components_spec.cr spec/ui/renderers/web_renderer_spec.cr` |
| Web design-system demo generation | `crystal` | `crystal run examples/web_design_system_demo.cr` |
| Web static and canonical-surface audit | `crystal` | `crystal run scripts/validate_web_demo.cr` |
| Web browser, screenshot, contrast, keyboard, touch-target, AX tree, and reduced-motion evidence | `crystal` | `crystal run scripts/capture_web_demo_screenshots.cr` |
| Web axe audit | `crystal` | `crystal run scripts/axe_web_demo_audit.cr` |
| Web IBM Equal Access audit | `crystal` | `crystal run scripts/ibm_web_demo_audit.cr` |
| General diff hygiene | none | `git diff --check` |
| Native macOS app build | `crystal-alpha` | `crystal-alpha build src/app.cr -o bin/app -Dmacos --link-flags="lib/asset_pipeline/src/ui/native/objc_bridge.o -framework AppKit -framework Foundation -lobjc"` |
| Native macOS UI specs | `crystal-alpha` | `crystal-alpha spec spec/ui/ -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"` |
| Native iOS build | `crystal-alpha` | Use `-Dios` and the project iOS bridge/linker wrapper. |
| Native Android build | `crystal-alpha` | Use `-Dandroid` and the project Android/JNI wrapper. |

`CLAUDE.md` states that `crystal-alpha` does not auto-detect native renderers.
Native builds must pass the appropriate compile flag:

- macOS: `-Dmacos`
- iOS: `-Dios`
- Android: `-Dandroid`
- Web renderer: no native flag

For macOS and iOS native renderer builds, compile the Objective-C bridge before
linking:

```bash
clang -c lib/asset_pipeline/src/ui/native/objc_bridge.m \
  -o lib/asset_pipeline/src/ui/native/objc_bridge.o -fno-objc-arc
```

## Fast Web Validation Ladder

Use this when changing generated design-system views, docs that describe
contracts, or small component behavior.

```bash
crystal spec spec/components/examples/example_components_spec.cr
crystal run scripts/validate_web_demo.cr
git diff --check
```

When the change touches CSS tokens, font assets, renderer output, or promoted
components, widen the spec pass:

```bash
crystal spec spec/components/css spec/components/assets/font_asset_spec.cr \
  spec/components/examples/example_components_spec.cr \
  spec/ui/renderers/web_renderer_spec.cr
crystal run scripts/validate_web_demo.cr
git diff --check
```

The fast ladder should fail on missing labels, duplicate IDs, inline handlers,
Bootstrap-shaped canonical classes, missing semantic form attributes, and
generated-page drift caught by the static audit.

## Full Web Validation Ladder

Use this before handing off meaningful design-system web changes.

```bash
crystal spec spec/components/css spec/components/assets/font_asset_spec.cr \
  spec/components/examples/example_components_spec.cr \
  spec/ui/renderers/web_renderer_spec.cr
crystal run examples/web_design_system_demo.cr
crystal run scripts/validate_web_demo.cr
crystal run scripts/validate_design_system_manifest.cr
crystal run scripts/capture_web_demo_screenshots.cr
crystal run scripts/axe_web_demo_audit.cr
crystal run scripts/ibm_web_demo_audit.cr
git diff --check
```

The full ladder produces the current canonical evidence set under
`test-results/web-design-system/`: static audit, canonical-surface audit,
browser audit, screenshots, contrast samples, reduced-motion report, keyboard
traversal, touch targets, accessibility tree snapshots, axe results, and IBM
Equal Access results. Compatibility copies are mirrored to
`test-results/amber-design-system/` during the alpha migration.

## Native Validation Ladder

Use this only when changing native platform renderers, `UI::View` behavior, or
native sample apps.

```bash
clang -c lib/asset_pipeline/src/ui/native/objc_bridge.m \
  -o lib/asset_pipeline/src/ui/native/objc_bridge.o -fno-objc-arc
crystal-alpha build src/app.cr -o bin/app -Dmacos \
  --link-flags="lib/asset_pipeline/src/ui/native/objc_bridge.o \
    -framework AppKit -framework Foundation -lobjc"
crystal-alpha spec spec/ui/ -Dmacos \
  --link-flags="-framework ApplicationServices -framework CoreFoundation"
```

Native UI tests require macOS Accessibility permission for the terminal running
the specs.

## Future Reusable CLI Targets

These commands are the intended stable CLI, not the current Phase 1
implementation:

| Future command | Current equivalent |
| --- | --- |
| `asset_pipeline validate --fast` | Focused `crystal spec`, `crystal run scripts/validate_web_demo.cr`, `git diff --check` |
| `asset_pipeline validate --static` | `crystal run scripts/validate_web_demo.cr` and `crystal run scripts/validate_design_system_manifest.cr` |
| `asset_pipeline validate --browser` | `crystal run scripts/capture_web_demo_screenshots.cr` |
| `asset_pipeline validate --a11y` | `crystal run scripts/axe_web_demo_audit.cr` and `crystal run scripts/ibm_web_demo_audit.cr` |
| `asset_pipeline validate --full` | Full web validation ladder |
| `asset_pipeline capture` | Browser screenshot and state capture path currently inside `scripts/capture_web_demo_screenshots.cr` |

The future CLI should read a consuming app's route or component manifest instead
of hard-coding the seven Frontloader Studio demo pages.
The first static manifest path exists now:

```bash
crystal run scripts/validate_design_system_manifest.cr
crystal run scripts/validate_design_system_manifest.cr path/to/design-system.routes.yml
```
