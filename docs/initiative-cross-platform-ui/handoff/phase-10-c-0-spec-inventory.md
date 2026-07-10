# Phase 10C.0 — Spec inventory + classification

**Date:** 2026-05-25 (iter 1) — updated 2026-05-26 (iter 2 remediation).
**Branch:** `phase-10-c-0`
**Source count (iter 1 pre-merge):** 132 spec files (verified via `find spec -name '*.cr' | wc -l`).
**Source count (iter 2 post-merge):** 140 spec files. The phase-10-a-0a merge brought in 8 additional `.cr` files (1 spec + 7 fixtures); see Reconciliation below.
**Files with relative `require`:** 129 of the original 132 (verified via `grep -lr "require_relative\|require \"\\.\\./" spec/`).

---

## Classification rule (per `architecture-decisions.md` Decision 5)

**Deepest platform dependency.** A spec is placed in `spec/native_<X>/`
if it exercises a platform-gated view/renderer code path under
`-D<X>` AND the platform-specific assertions are the substantive
payload of the file. Multi-platform contract specs stay in `spec/web/`
if they pass under plain `crystal spec` without native link flags.

Platform-flag-gated specs (`{% if flag?(:macos) %}`, etc.) that yield
0 examples under web AND only exercise meaningful assertions under the
native flag are placed in the native directory so `make test-macos` /
`make test-ios` / `make test-android` actually run them.

Specs that use `pending` (placeholder bodies that never run) AND ship
under default `crystal spec` are classified as web — they document a
future native probe without requiring native link flags today.

`UI::AXTest` specs are unconditionally `spec/native_macos/` — they
`require` ApplicationServices runtime and only compile / link under
`-Dmacos` with `-framework ApplicationServices`.

**Iter 2 note (Codex Finding 4):** the 117-row category-level
classification for `spec/web/` below is acceptable under Decision 5
where the category is unambiguous. Every spec in `spec/web/` falls
under the same rule: "either runs at least one example under plain
`crystal spec` OR is a `pending`-only forward-compat probe." Per-row
classification was considered and rejected as adding noise without
discriminating signal — every row would say "runs/pendings under
plain `crystal spec`." The 14 macOS rows below DO get per-row
rationale because each row's classification depends on a distinct
runtime dependency (AXTest, NSApp host, `flag?(:macos)` gate, etc.).

---

## Summary

| Target directory | Spec count | Notes |
|---|---:|---|
| `spec/web/` | 117 → 126 post-merge | Default `crystal spec` lane. |
| `spec/native_macos/` | 14 | Requires `-Dmacos` + `objc_bridge.o` + AppKit/ApplicationServices link flags. |
| `spec/native_ios/` | 0 | Allowed directory; placeholder `README.md` + `.gitkeep`. See `spec/native_ios/README.md`. |
| `spec/native_android/` | 0 | Allowed directory; placeholder `README.md` + `.gitkeep`. See `spec/native_android/README.md`. |
| `spec/spec_helper.cr` | 0 | **MOVED in iter 1** to `spec/web/spec_helper.cr`. There is NO file at `spec/spec_helper.cr` today; the Family 5 rule lists it as an allowed root location for forward compatibility if a cross-tree helper is ever needed. (iter 2 fix: this row previously said "stays at root" which contradicted the close handoff.) |
| **Original total** | **132** | All accounted for + moved. |
| **Iter 2 additions (from phase-10-a-0a merge)** | **+8** | 1 spec + 7 fixtures under `spec/web/lint_conventions/`. |
| **Total today** | **140** | 126 web + 14 native_macos. |

---

## spec_helper.cr clarification (iter 2 — Codex Finding 4)

The iter-1 inventory said `spec/spec_helper.cr` "stays at root" but the
iter-1 close handoff said it "moved to `spec/web/`". The handoff is
correct. Verification:

```
$ git ls-files spec/spec_helper.cr spec/web/spec_helper.cr
spec/web/spec_helper.cr
```

There is **no** `spec/spec_helper.cr` file. The Family 5 directory
rule (`SpecPlatformDirectoryRule.ALLOWED_ROOT_FILES`) keeps
`spec/spec_helper.cr` in its allowed-root list as a forward-compat
slot, but no file is committed at that path today.

---

## spec/native_macos/ — 14 specs (per-row rationale)

All require `UI::AXTest` (which only compiles with `-Dmacos` +
ApplicationServices link flags) OR are HIG validation specs that drive
a live NSApp host.

| Current path | Target path (= final) | Rationale (deepest platform dependency) |
|---|---|---|
| `spec/support/ax_test_patterns.cr` | `spec/native_macos/support/ax_test_patterns.cr` | AXTest helper module loaded by HIG specs; `require "asset_pipeline/ui/ax_test"` is `-Dmacos`-only. |
| `spec/ui/ax_test/ax_app_spec.cr` | `spec/native_macos/ax_test/ax_app_spec.cr` | AXTest app launch coverage; only compiles with ApplicationServices link flag. |
| `spec/ui/ax_test/ax_focus_spec.cr` | `spec/native_macos/ax_test/ax_focus_spec.cr` | AXTest focus coverage; ditto. |
| `spec/ui/ax_test/ax_geometry_spec.cr` | `spec/native_macos/ax_test/ax_geometry_spec.cr` | AXTest geometry coverage; ditto. |
| `spec/ui/ax_test/ax_identifier_spec.cr` | `spec/native_macos/ax_test/ax_identifier_spec.cr` | AXTest identifier coverage; ditto. |
| `spec/ui/ax_test/ax_keys_spec.cr` | `spec/native_macos/ax_test/ax_keys_spec.cr` | AXTest keystroke coverage; ditto. |
| `spec/ui/ax_test/ax_resize_spec.cr` | `spec/native_macos/ax_test/ax_resize_spec.cr` | AXTest window resize coverage; ditto. |
| `spec/ui/ax_test/ax_screenshot_element_spec.cr` | `spec/native_macos/ax_test/ax_screenshot_element_spec.cr` | AXTest screenshot path; ditto. |
| `spec/ui/ax_test/ax_value_writer_spec.cr` | `spec/native_macos/ax_test/ax_value_writer_spec.cr` | AXTest text-field value setter; ditto. |
| `spec/ui/hig_validation/macos_action_tap_probe_spec.cr` | `spec/native_macos/hig_validation/macos_action_tap_probe_spec.cr` | Requires AXTest patterns + drives macOS tap probe; needs `-Dmacos` + AppKit link. |
| `spec/ui/hig_validation/macos_form_layout_spec.cr` | `spec/native_macos/hig_validation/macos_form_layout_spec.cr` | Requires AXTest patterns + drives macOS form layout host; ditto. |
| `spec/ui/hig_validation/macos_visual_spec.cr` | `spec/native_macos/hig_validation/macos_visual_spec.cr` | Requires AXTest patterns + drives macOS visual probe; ditto. |
| `spec/ui/menu_bar_spec.cr` | `spec/native_macos/menu_bar_spec.cr` | 100% `{% if flag?(:macos) %}` gated; yields 0 examples under web. macOS-only `NSMenu`/`NSStatusBar` assertions are the substantive payload. |
| `spec/ui/native/collections_spec.cr` | `spec/native_macos/native/collections_spec.cr` | All examples gated `{% if flag?(:macos) || flag?(:ios) %}` / `{% if flag?(:android) %}`; yields 0 examples under web. macOS is the runnable lane today; iOS/Android remain attempted-blocked per the compile matrix. |

---

## spec/web/ — 117 original specs (category-level rationale)

Per the iter-2 reasoning above, the 117 web specs share a single
unambiguous classification rule: they either run at least one example
under plain `crystal spec` OR are `pending`-only forward-compat probes
that compile under web build. Per-row rationale would not add
discriminating signal — every row would repeat the same predicate.

The web specs decompose by top-level category:

| Category (count) | Why web | Notes |
|---|---|---|
| `spec/asset_pipeline/**` (24) | Pure Ruby/Crystal asset-pipeline contract assertions (front loader, script renderer, action dispatcher, action result, amber integration, controllers, voyager specs). No native flags; no native link. | Includes `native_app_spec.cr` / `native_context_spec.cr` / `native_controller_spec.cr` — these test the **abstract** native-controller API (callable from any platform), not platform-specific runtime; they pass under plain `crystal spec`. |
| `spec/asset_pipeline_spec.cr` (1) | Top-level shard smoke spec. | |
| `spec/components/**` (24) | Pure component-system / CSS engine / cache / design-system assertions. No native dependencies. | Includes 5 `phaseN_verification_spec.cr` files — pre-existing failures in 3 of them, see iter-1 close handoff regression section + iter-2 reconfirmation against `phase-10` base. |
| `spec/fixtures/**` (4) | Test fixtures for macro-raise phase_08c specs. Pure compile/render assertions. | Loaded as fixtures by web specs. |
| `spec/import_map/**` (1) | Import-map shard assertions. | |
| `spec/scripts/**` (1) | Design-system manifest validator script tests. | |
| `spec/support/**` (5) | Web-runnable test helpers: `accessibility_matchers`, `fake_lib_objc_bridge` (a fake of the macOS bridge for web-only spec compilation), `phase04_compile_check`. | The `fake_lib_objc_bridge.cr` is the web-side stub that mirrors the native bridge's API surface for compile-time substitution. |
| `spec/ui/**` (61) | UI contract assertions runnable under plain `crystal spec`: design tokens (8), renderer outputs (12), form state, fluid, native handle / callback / reactive state (4), navigation, notifications, quick actions, status bar, view adapter, `views_spec.cr` (3300 lines — the dominant majority is web-runnable contract assertions; `{% if flag?(:macos) %}` islands skip under web), widgets, windows, web renderer route host, voyager state propagation, action_sheet/context_menu/path_control web-fallback + compile-error specs (6), glass material `pending`-only probes (6). | The 6 `glass_material/*.cr` specs are 100% `pending` today (placeholder native probes — they compile under web build with 0 active examples). |

**Full path listing (117 original web specs, sorted, with target paths
that are all `spec/web/<original>`):**

<details>
<summary>Click to expand 117-row listing</summary>

```
spec/asset_pipeline_spec.cr                       → spec/web/asset_pipeline_spec.cr
spec/asset_pipeline/action_dispatcher_spec.cr     → spec/web/asset_pipeline/action_dispatcher_spec.cr
spec/asset_pipeline/action_result_spec.cr         → spec/web/asset_pipeline/action_result_spec.cr
spec/asset_pipeline/amber_integration_spec.cr     → spec/web/asset_pipeline/amber_integration_spec.cr
spec/asset_pipeline/cli/amber_generator_spec.cr   → spec/web/asset_pipeline/cli/amber_generator_spec.cr
spec/asset_pipeline/components/asset_pipeline_integration_test.cr → spec/web/asset_pipeline/components/asset_pipeline_integration_test.cr
spec/asset_pipeline/components/caching_test.cr    → spec/web/asset_pipeline/components/caching_test.cr
spec/asset_pipeline/components/components_test.cr → spec/web/asset_pipeline/components/components_test.cr
spec/asset_pipeline/components/javascript_integration_test.cr → spec/web/asset_pipeline/components/javascript_integration_test.cr
spec/asset_pipeline/dependency_analyzer_spec.cr   → spec/web/asset_pipeline/dependency_analyzer_spec.cr
spec/asset_pipeline/enhanced_front_loader_spec.cr → spec/web/asset_pipeline/enhanced_front_loader_spec.cr
spec/asset_pipeline/enhanced_script_renderer_spec.cr → spec/web/asset_pipeline/enhanced_script_renderer_spec.cr
spec/asset_pipeline/front_loader_script_integration_spec.cr → spec/web/asset_pipeline/front_loader_script_integration_spec.cr
spec/asset_pipeline/native_app_spec.cr            → spec/web/asset_pipeline/native_app_spec.cr
spec/asset_pipeline/native_context_spec.cr        → spec/web/asset_pipeline/native_context_spec.cr
spec/asset_pipeline/native_controller_spec.cr     → spec/web/asset_pipeline/native_controller_spec.cr
spec/asset_pipeline/phase_08c_routes_for_spec.cr  → spec/web/asset_pipeline/phase_08c_routes_for_spec.cr
spec/asset_pipeline/platform_spec.cr              → spec/web/asset_pipeline/platform_spec.cr
spec/asset_pipeline/script_renderer_spec.cr       → spec/web/asset_pipeline/script_renderer_spec.cr
spec/asset_pipeline/stimulus/stimulus_renderer_spec.cr → spec/web/asset_pipeline/stimulus/stimulus_renderer_spec.cr
spec/asset_pipeline/voyager_app_spec.cr           → spec/web/asset_pipeline/voyager_app_spec.cr
spec/asset_pipeline/voyager_controllers_spec.cr   → spec/web/asset_pipeline/voyager_controllers_spec.cr
spec/asset_pipeline/voyager_dispatcher_integration_spec.cr → spec/web/asset_pipeline/voyager_dispatcher_integration_spec.cr
spec/asset_pipeline/voyager_host_bootstrap_spec.cr → spec/web/asset_pipeline/voyager_host_bootstrap_spec.cr
spec/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr → spec/web/asset_pipeline/voyager_todo_editor_save_disabled_spec.cr
spec/components/assets/font_asset_spec.cr         → spec/web/components/assets/font_asset_spec.cr
spec/components/base/component_spec.cr            → spec/web/components/base/component_spec.cr
spec/components/cache/cache_warmer_spec.cr        → spec/web/components/cache/cache_warmer_spec.cr
spec/components/cache/cacheable_spec.cr           → spec/web/components/cache/cacheable_spec.cr
spec/components/cache/memory_cache_store_spec.cr  → spec/web/components/cache/memory_cache_store_spec.cr
spec/components/css/amber_design_system_spec.cr   → spec/web/components/css/amber_design_system_spec.cr
spec/components/css/css_layer_structure_spec.cr   → spec/web/components/css/css_layer_structure_spec.cr
spec/components/css/css_phase2_wcag_spec.cr       → spec/web/components/css/css_phase2_wcag_spec.cr
spec/components/css/css_phase3_capabilities_spec.cr → spec/web/components/css/css_phase3_capabilities_spec.cr
spec/components/css/css_phase4_component_layer_spec.cr → spec/web/components/css/css_phase4_component_layer_spec.cr
spec/components/design_system/design_system_namespace_spec.cr → spec/web/components/design_system/design_system_namespace_spec.cr
spec/components/design_system/primitives_spec.cr  → spec/web/components/design_system/primitives_spec.cr
spec/components/design_system/runtime_alias_spec.cr → spec/web/components/design_system/runtime_alias_spec.cr
spec/components/elements/base/html_element_spec.cr → spec/web/components/elements/base/html_element_spec.cr
spec/components/elements/document/document_elements_spec.cr → spec/web/components/elements/document/document_elements_spec.cr
spec/components/elements/integration_spec.cr      → spec/web/components/elements/integration_spec.cr
spec/components/elements/simple_test_spec.cr      → spec/web/components/elements/simple_test_spec.cr
spec/components/examples/example_components_spec.cr → spec/web/components/examples/example_components_spec.cr
spec/components/phase1_verification_spec.cr       → spec/web/components/phase1_verification_spec.cr
spec/components/phase2_verification_spec.cr       → spec/web/components/phase2_verification_spec.cr
spec/components/phase3_verification_spec.cr       → spec/web/components/phase3_verification_spec.cr
spec/components/phase4_verification_spec.cr       → spec/web/components/phase4_verification_spec.cr
spec/components/phase6_final_verification_spec.cr → spec/web/components/phase6_final_verification_spec.cr
spec/components/reactive/reactive_handler_spec.cr → spec/web/components/reactive/reactive_handler_spec.cr
spec/components/view_generation_spec.cr           → spec/web/components/view_generation_spec.cr
spec/fixtures/phase_08c_macro_raise/native_plus_web_controller_no_routes.cr → spec/web/fixtures/phase_08c_macro_raise/native_plus_web_controller_no_routes.cr
spec/fixtures/phase_08c_macro_raise/no_side.cr    → spec/web/fixtures/phase_08c_macro_raise/no_side.cr
spec/fixtures/phase_08c_macro_raise/web_controller_no_routes.cr → spec/web/fixtures/phase_08c_macro_raise/web_controller_no_routes.cr
spec/fixtures/phase_08c_macro_raise/web_path_without_controller.cr → spec/web/fixtures/phase_08c_macro_raise/web_path_without_controller.cr
spec/import_map/import_map_spec.cr                → spec/web/import_map/import_map_spec.cr
spec/scripts/validate_design_system_manifest_spec.cr → spec/web/scripts/validate_design_system_manifest_spec.cr
spec/support/accessibility_matchers_spec.cr       → spec/web/support/accessibility_matchers_spec.cr
spec/support/accessibility_matchers.cr            → spec/web/support/accessibility_matchers.cr
spec/support/fake_lib_objc_bridge_spec.cr         → spec/web/support/fake_lib_objc_bridge_spec.cr
spec/support/fake_lib_objc_bridge.cr              → spec/web/support/fake_lib_objc_bridge.cr
spec/support/phase04_compile_check.cr             → spec/web/support/phase04_compile_check.cr
spec/ui/app_shortcuts_spec.cr                     → spec/web/ui/app_shortcuts_spec.cr
spec/ui/design_tokens_brand_spec.cr               → spec/web/ui/design_tokens_brand_spec.cr
spec/ui/design_tokens_cascade_spec.cr             → spec/web/ui/design_tokens_cascade_spec.cr
spec/ui/design_tokens_conversion_spec.cr          → spec/web/ui/design_tokens_conversion_spec.cr
spec/ui/design_tokens_default_accent_spec.cr      → spec/web/ui/design_tokens_default_accent_spec.cr
spec/ui/design_tokens_spec.cr                     → spec/web/ui/design_tokens_spec.cr
spec/ui/design_tokens/generators/apple_generator_spec.cr → spec/web/ui/design_tokens/generators/apple_generator_spec.cr
spec/ui/design_tokens/generators/web_generator_spec.cr → spec/web/ui/design_tokens/generators/web_generator_spec.cr
spec/ui/design_tokens/material_spec.cr            → spec/web/ui/design_tokens/material_spec.cr
spec/ui/device_metrics_spec.cr                    → spec/web/ui/device_metrics_spec.cr
spec/ui/fluid_spec.cr                             → spec/web/ui/fluid_spec.cr
spec/ui/form_state_spec.cr                        → spec/web/ui/form_state_spec.cr
spec/ui/glass_material/ios_glass_contrast_spec.cr → spec/web/ui/glass_material/ios_glass_contrast_spec.cr
spec/ui/glass_material/ios_glass_default_spec.cr  → spec/web/ui/glass_material/ios_glass_default_spec.cr
spec/ui/glass_material/ios_glass_env_response_spec.cr → spec/web/ui/glass_material/ios_glass_env_response_spec.cr
spec/ui/glass_material/macos_glass_contrast_spec.cr → spec/web/ui/glass_material/macos_glass_contrast_spec.cr
spec/ui/glass_material/macos_glass_default_spec.cr → spec/web/ui/glass_material/macos_glass_default_spec.cr
spec/ui/glass_material/macos_glass_env_response_spec.cr → spec/web/ui/glass_material/macos_glass_env_response_spec.cr
spec/ui/live_activities_spec.cr                   → spec/web/ui/live_activities_spec.cr
spec/ui/native/callback_registry_spec.cr          → spec/web/ui/native/callback_registry_spec.cr
spec/ui/native/native_handle_spec.cr              → spec/web/ui/native/native_handle_spec.cr
spec/ui/native/native_view_spec.cr                → spec/web/ui/native/native_view_spec.cr
spec/ui/native/reactive_state_spec.cr             → spec/web/ui/native/reactive_state_spec.cr
spec/ui/navigation_coordinator_spec.cr            → spec/web/ui/navigation_coordinator_spec.cr
spec/ui/notifications_spec.cr                     → spec/web/ui/notifications_spec.cr
spec/ui/quick_actions_spec.cr                     → spec/web/ui/quick_actions_spec.cr
spec/ui/renderers/container_query_spec.cr         → spec/web/ui/renderers/container_query_spec.cr
spec/ui/renderers/document_mode_spec.cr           → spec/web/ui/renderers/document_mode_spec.cr
spec/ui/renderers/fluid_emission_spec.cr          → spec/web/ui/renderers/fluid_emission_spec.cr
spec/ui/renderers/swiftkit/button_overrides_spec.cr → spec/web/ui/renderers/swiftkit/button_overrides_spec.cr
spec/ui/renderers/swiftkit/callback_registry_swiftkit_spec.cr → spec/web/ui/renderers/swiftkit/callback_registry_swiftkit_spec.cr
spec/ui/renderers/swiftkit/glass_background_overrides_spec.cr → spec/web/ui/renderers/swiftkit/glass_background_overrides_spec.cr
spec/ui/renderers/swiftkit/group1_overrides_spec.cr → spec/web/ui/renderers/swiftkit/group1_overrides_spec.cr
spec/ui/renderers/swiftkit/group3_overrides_spec.cr → spec/web/ui/renderers/swiftkit/group3_overrides_spec.cr
spec/ui/renderers/swiftkit/list_view_overrides_spec.cr → spec/web/ui/renderers/swiftkit/list_view_overrides_spec.cr
spec/ui/renderers/swiftkit/objc_setter_selector_spec.cr → spec/web/ui/renderers/swiftkit/objc_setter_selector_spec.cr
spec/ui/renderers/system_accent_integration_spec.cr → spec/web/ui/renderers/system_accent_integration_spec.cr
spec/ui/renderers/touch_target_spec.cr            → spec/web/ui/renderers/touch_target_spec.cr
spec/ui/renderers/web_glass_spec.cr               → spec/web/ui/renderers/web_glass_spec.cr
spec/ui/renderers/web_renderer_spec.cr            → spec/web/ui/renderers/web_renderer_spec.cr
spec/ui/state_spec.cr                             → spec/web/ui/state_spec.cr
spec/ui/status_bar_spec.cr                        → spec/web/ui/status_bar_spec.cr
spec/ui/swipe_action_row_spec.cr                  → spec/web/ui/swipe_action_row_spec.cr
spec/ui/view_adapter_spec.cr                      → spec/web/ui/view_adapter_spec.cr
spec/ui/views_spec.cr                             → spec/web/ui/views_spec.cr
spec/ui/views/action_sheet_compile_error_spec.cr  → spec/web/ui/views/action_sheet_compile_error_spec.cr
spec/ui/views/action_sheet_spec.cr                → spec/web/ui/views/action_sheet_spec.cr
spec/ui/views/action_sheet_with_web_fallback_spec.cr → spec/web/ui/views/action_sheet_with_web_fallback_spec.cr
spec/ui/views/context_menu_compile_error_spec.cr  → spec/web/ui/views/context_menu_compile_error_spec.cr
spec/ui/views/context_menu_with_web_fallback_spec.cr → spec/web/ui/views/context_menu_with_web_fallback_spec.cr
spec/ui/views/path_control_compile_error_spec.cr  → spec/web/ui/views/path_control_compile_error_spec.cr
spec/ui/views/path_control_with_web_fallback_spec.cr → spec/web/ui/views/path_control_with_web_fallback_spec.cr
spec/ui/voyager_state_propagation_spec.cr         → spec/web/ui/voyager_state_propagation_spec.cr
spec/ui/web_renderer_route_host_spec.cr           → spec/web/ui/web_renderer_route_host_spec.cr
spec/ui/widgets_spec.cr                           → spec/web/ui/widgets_spec.cr
spec/ui/windows_spec.cr                           → spec/web/ui/windows_spec.cr
spec/spec_helper.cr                               → spec/web/spec_helper.cr
```

</details>

---

## Iter 2 reconciliation — phase-10-a-0a merge additions (+8 files)

The iter-2 merge of `phase-10-a-0a` brought in 8 additional `.cr`
files that did not exist on `phase-10` at iter-1 inventory time:

| File | Target | Rationale |
|---|---|---|
| `spec/lint_conventions/family_1_naming_spec.cr` | **moved iter 2 to** `spec/web/lint_conventions/family_1_naming_spec.cr` | Phase 10A.0a's regression spec for the convention rule runner. Runs under plain `crystal spec` (11 examples, 0 failures). Belongs in `spec/web/` per the Family 5 rule. Move commit: see iter-2 commit "Move spec/lint_conventions/ into spec/web/". |
| `spec/lint_conventions/fixtures/controller_bad_suffix_fail.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/controller_bad_suffix_fail.cr` | Rule fixture. Excluded from rule walks by the runner's `/fixtures/` filter. |
| `spec/lint_conventions/fixtures/controller_pass.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/controller_pass.cr` | Rule fixture. Ditto. |
| `spec/lint_conventions/fixtures/lib_vendored_pass.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/lib_vendored_pass.cr` | Rule fixture. Ditto. |
| `spec/lint_conventions/fixtures/samples_view_pass.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/samples_view_pass.cr` | Rule fixture. Ditto. |
| `spec/lint_conventions/fixtures/screen_bad_name_fail.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/screen_bad_name_fail.cr` | Rule fixture. Ditto. |
| `spec/lint_conventions/fixtures/screen_pass.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/screen_pass.cr` | Rule fixture. Ditto. |
| `spec/lint_conventions/fixtures/ui_root_view_fail.cr` | **moved iter 2 to** `spec/web/lint_conventions/fixtures/ui_root_view_fail.cr` | Rule fixture. Ditto. |

Post-merge total: 140 `.cr` files under `spec/`, all of which sit
under `spec/web/` or `spec/native_macos/` and satisfy the Family 5
rule (verified by `crystal run scripts/lint_conventions.cr` → 0
diagnostics).

---

## Acceptance gate (pre-move)

- Baseline: `crystal spec` reports 1723 examples, 4 failures, 0 errors,
  66 pending (pre-existing).
- All 4 baseline failures are tracked outside Phase 10C.0's scope.
  Verified pre-existing on `phase-10` base in iter 2; see close
  handoff §Regression check.
- Reorg preserves example count.

## Plan (as executed)

1. Created `spec/web/`, `spec/native_macos/` directory trees (iter 1).
2. Moved 14 native_macos specs (iter 1, commit `d446ba9d`).
3. Moved 118 web specs (iter 1, commit `b0688743`) — actual count was
   117 specs + the `spec_helper.cr` helper file = 118 file moves total.
4. `spec/spec_helper.cr` MOVED to `spec/web/spec_helper.cr` (iter 1,
   in batch 2). Relative-require paths inside specs updated for the
   new depth.
5. After each batch: `crystal spec spec/web/` passes with the same
   1723-example / 4-failure / 66-pending signature.
6. **Iter 2 only:** `phase-10-a-0a` merged in → moved 8 additional
   `lint_conventions` files into `spec/web/`.
7. **Iter 2 only:** created empty `spec/native_ios/` + `spec/native_android/`
   directories with `.gitkeep` + `README.md` files so the post-close
   directory listing is honest (per Codex notes).

## Coordination

- 10A.0a's runner + base class are now merged in (iter 2). Family 5
  rule (`SpecPlatformDirectoryRule`) extends `ConventionRule` and is
  loaded by `scripts/lint_conventions.cr`.
- 10A.0b (Family 2 view-spec pair rule) depends on this reorg landing.
- 10B.0 specs (if any) landing in `spec/ui/intent_spec.cr` on `phase-10-b-0`
  will migrate into `spec/web/` when that branch merges.

— Implementer (Phase 10C.0), 2026-05-25 (iter 1), 2026-05-26 (iter 2)
