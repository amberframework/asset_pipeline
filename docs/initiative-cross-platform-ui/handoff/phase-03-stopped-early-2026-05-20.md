# Phase 3 — Implementer Stopped Early — 2026-05-20

**Status:** Implementer returned early per `implementation_criteria.md` §"When the brief is wrong" and the dispatch brief's explicit guidance ("Given Phase 3's complexity, err toward stopping early on anything ambiguous"). This is a legitimate, well-justified escalation — NOT a Validator failure.

**Commits landed (2):**

- `7756d25` `[Phase 3] Repair crystal-spec link gap by narrowing darwin guards` — Architect scope addition.
- `6996ba7` `[Phase 3] Add AssetPipelineSwiftKit scaffold with Button facade` — Phase 3 vertical-slice foundation.

---

## What landed (real, valuable, validatable)

### Architect scope addition: `crystal spec` link gap repaired

7 native-bridge files (`objc_collections.cr`, `quick_actions.cr`, `status_bar.cr`, `menu_bar.cr`, `windows.cr`, `notifications.cr`, plus the matching spec) had their `flag?(:darwin)` guards narrowed to `flag?(:macos) || flag?(:ios)`. The `:darwin` flag auto-sets on macOS hosts regardless of renderer flag, so the `lib LibObjCBridge`/`LibCollectionBridge` blocks were trying to resolve C trampolines at every spec-runner link step — but those trampolines are only compiled by native sample builds. The narrower gate excludes the declarations from default `crystal spec`. Native sample builds always pass `-Dmacos` / `-Dios` and link bridge `.m` files explicitly, so they continue working unchanged.

**Verification:** `crystal spec` from repo root now reports `1244 examples, 4 failures, 0 errors` (4 pre-existing failures unrelated to bridge gating — see Known Concerns #2 in the Implementer handoff).

### Phase 3 vertical-slice foundation

- **Swift package scaffold** at `swift/AssetPipelineSwiftKit/` with `Package.swift` (iOS 16+ / macOS 13+, swift-snapshot-testing 1.17.x pinned).
- **`APSKPlatformView`** declared once in `Sources/AssetPipelineSwiftKit/Overrides/ViewOverrides.swift` per §5.5 + line 701 duplicate-prevention rule.
- **`HostingHelpers.swift`** with `host(_:)` applying the §5.6 `.frame(minWidth: 1, minHeight: 1)` Form/List defensive sizing.
- **`CallbackBridge.swift`** with `APSKRuntime.initialize(actionTrampoline:)` and a spec-only `_installTestTrampoline` hook.
- **`CommonModifiers.swift`** — the single conditional cascade every facade calls last.
- **`ViewOverrides.swift`, `ButtonOverrides.swift`** — `nil`-default override fields per §5.5.
- **`ButtonFacade.swift`** — the proof-of-pattern: SwiftUI `Button(role:action:)` with style cascade, common modifiers, hosted controller.
- **`AssetPipelineTokens.swift` symlink** to the Phase 1 dist output.

- **Crystal side:**
  - `src/ui/native/swiftkit_bridge.cr` — typed `LibSwiftKitBridge` Crystal `lib`, gated on `flag?(:macos) || flag?(:ios)`. Phase 5 extends this per §7.4.
  - `src/ui/native/swiftkit_bridge.m` — C trampolines bridging Crystal calls to `APSK*Facade.make...` via `objc_msgSend`.
  - `src/ui/native/swiftkit_overrides.cr` — `UI::Native::Populator.populate_button(target, view, sender)` + abstract `Sender`. Spec-friendly extraction.
  - `src/ui/native/callback_registry.cr` extended with `register_action`, `register_action_with_value`, `invoke_swiftkit`, and the exported `ap_swiftkit_invoke_action` C trampoline.

- **Specs:**
  - `spec/support/fake_lib_objc_bridge.cr` — recording shim per §Step 8a.
  - `spec/support/fake_lib_objc_bridge_spec.cr` — sanity spec.
  - `spec/ui/renderers/swiftkit/button_overrides_spec.cr` — the §11 default-detection invariant for every ButtonOverrides field.
  - `spec/ui/renderers/swiftkit/callback_registry_swiftkit_spec.cr` — token + dispatch behavior.

  **38 new Phase 3 specs all pass.**

### The published Crystal-side `LibSwiftKitBridge` contract (for Phase 5 extension)

```crystal
{% if flag?(:macos) || flag?(:ios) %}
  @[Link(framework: "Foundation")]
  lib LibSwiftKitBridge
    fun apsk_runtime_initialize(action_trampoline : Void*)
    fun apsk_view_overrides_new : Void*
    fun apsk_button_overrides_new : Void*
    fun apsk_make_button(label : UInt8*, overrides : Void*, action_token : UInt64) : Void*
  end
{% end %}
```

Naming convention: `apsk_*_new` for overrides constructors, `apsk_make_<widget>` for facade entry points, `apsk_runtime_*` for runtime init. Phase 5's `material_parameters_new` / `glass_background_facade_make` `fun`s slot directly into this block.

---

## What did NOT land (and why)

- **Renderer visit-method migration.** The existing `visit(UI::Button)` methods in `uikit_renderer.cr` and `appkit_renderer.cr` are ~230 lines each with extensive Phase 1/2 brand customization: amber-gold for `:primary` role, plum for `:destructive`, dark-mode contrast logic, the role × style cross-matrix. Replacing these wholesale with `Populator.populate_button(ovr, view, sender); LibSwiftKitBridge.apsk_make_button(...)` risks silently regressing the brand baseline that Phases 1 and 2 carefully tuned (and that Validator iter-2 of both phases verified).
- **Remaining 34 widgets (Steps 3–7 of §6).** Each follows the same pattern as Button; cannot ship until the pattern's brand-handling question is settled.
- **Sample build script updates (Step 2).** Adds link weight (`-framework SwiftUI -framework Combine`, the static `.a`, `-Wl,-rpath,/usr/lib/swift`) with no code path using it until the renderer migrates.
- **Swift snapshot baselines (Steps 8–9).** Requires an Xcode + simulator environment to produce reproducible PNGs.

---

## The architectural question the Implementer surfaced

The Phase 3 brief's North Star ("SwiftUI defaults must come through on Apple platforms" — Origin Prompt 1) is in tension with Phases 1 and 2's load-bearing brand work. Specifically:

**Option A — Brand fidelity:** The Swift facade reads `AssetPipelineTokens.swift` (the Phase 1 generated companion) and reproduces the amber-gold / plum / dark-mode contrast as SwiftUI `Color` values + view modifiers. Result: SwiftUI structure (focus rings, haptics, animation) with the brand palette intact. The amber-gold `Button` looks like our `Button`, not like the generic SwiftUI tint.

**Option B — SwiftUI default supremacy:** The Swift facade uses raw SwiftUI primitives without applying brand colors unless a `view.background_color` or similar EXPLICIT override is set. Result: every `Button` defaults to system-blue / accent-color. Brand identity only surfaces when developers explicitly customize per widget. This matches the literal text of origin.md Prompt 1 ("We want to use on the native side as much of Apple's SwiftUI library defaults as possible. And then only when the user starts customizing do the effects cascade").

**Option C — Hybrid:** A few load-bearing brand values (brand-primary, surface, text-primary, danger) are baked into the Swift facade's default style; the rest defer to SwiftUI defaults. This is closer to Phase 1's actual implementation pattern (`UI::Theme` adapter reads brand-primary by default; visit-method literals were the brand-secondary layer Phase 2 partially scrubbed).

The Implementer correctly identified this as "above an Implementer's pay grade" and stopped. The question is yours.

---

## Implementer-flagged Known Concerns (verbatim)

1. Two phases of work remain (Dispatch A: Button visit-method migration + the brand decision; Dispatch B: 34 other widgets).
2. **4 pre-existing test failures** surfaced by the link-gap repair: `spec/ui/views_spec.cr:3247` (theme test expects empty string, Phase 1 changed token output), 3× `spec/components/phase2_verification_spec.cr` (legacy `btn btn-primary` class assertions vs current `am-button am-button--brand`). NOT introduced by Phase 3; couldn't even be observed before the link-gap repair landed.
3. `UIHostingController` nested layout pathology not visually validated — requires iOS simulator.
4. `CallbackRegistry.invoke_swiftkit` follows the existing not-thread-safe pattern (no mutex added) to keep the threading contract consistent across all dispatch entry points.
5. `ap_swiftkit_invoke_action` `fun` symbol may not be emitted in `crystal spec` because nothing in the spec tree references it; functionally covered via `UI::CallbackRegistry.invoke_swiftkit`.
6. `swiftkit_bridge.m` is not yet compiled by any build (waits on sample build script update / future dispatch).
7. `swift/AssetPipelineSwiftKit/Sources/AssetPipelineTokens/AssetPipelineTokens.swift` is a Unix symlink (asset_pipeline has no Windows target so this is fine).

---

## SourceKit diagnostics

A separate observation: SourceKit (Xcode) currently reports cross-module reference errors in the Swift files (`Cannot find type 'APSKPlatformView' in scope`, `Cannot find type 'ViewOverrides' in scope`, etc.). These are likely SourceKit parser warnings, not actual build errors — `swift build` against the same files should resolve them because they share a target in `Package.swift`. The first Implementer dispatch that runs `swift build` (probably during Dispatch A's sample-build wiring) will confirm whether these are spurious SourceKit complaints or real compilation errors. Flagging here for the record.

---

## Recommended Architect path

1. **Answer the brand-vs-default question.** Probably ask Seth.
2. **Dispatch A (small, surgical):** Migrate `visit(UI::Button)` in both renderers per the chosen brand-handling approach. Update sample build scripts. Verify with the existing Phase 1/2 cascade demos (web cascade #18 + macOS cascade #19) that brand-primary still flows correctly through the new bridge. Add the `apsk_runtime_initialize` call site. This dispatch sets the canonical pattern.
3. **Dispatch B (large, mechanical):** Roll out the remaining 34 widgets following Dispatch A's pattern. Add Swift snapshot baselines.
4. **Validator:** Single dispatch after Dispatch B; the Phase 3 rubric in `validation.md` validates the complete migration, not the partial state.

Alternatively, treat the current state as Phase 3a (foundation) — a separate phase tag — and rename the remaining widget migration as Phase 3b. This is purely a bookkeeping question; the work is the same.
