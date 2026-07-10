# Phase 6 iOS bridge — exposed via build_crystal_lib.sh as libcascade.a.
#
# C ABI:
#   void cascade_init(void)          — must be called once before any
#                                       render call. Seeds Crystal class-var
#                                       state that the iOS embedding skips
#                                       (per Phase 3 R9 BX/class-init gap).
#   void* cascade_render(const char*) — builds a UI::View from the slug,
#                                       renders it via the UIKit renderer,
#                                       returns the raw UIView* with +1
#                                       retain (Swift takes ownership).
#
# This file is the iOS-only twin of samples/cross_platform/ios_host/hig_bridge.cr;
# both share the same cross-compile pattern documented in
# samples/cross_platform/ios_host/build_crystal_lib.sh.

{% if flag?(:ios) %}

require "../app"
require "../../../src/ui/renderers/uikit_renderer"
require "../../../src/ui/probes"

module CascadeBridge
  @@initialized = false
  @@last_native : UI::NativeView? = nil

  def self.initialize_runtime
    return if @@initialized
    GC.init
    # The iOS embedding hides _main (see ios/build_crystal_lib.sh's
    # `ld -r -unexported_symbol _main` step), so Crystal's class-var
    # initializers never run automatically. Phase 6 specifically
    # SHIPS NO new class vars with initializers (per the brief's
    # I-9 preserves clause), but we still match the existing pattern
    # of explicit-reset of any probe singletons that downstream
    # renderers might already depend on.
    UI::Probes::DismissProbe.reset
    UI::Probes::ToggleProbe.reset
    UI::Probes::SliderProbe.reset
    UI::Probes::TapProbe.reset
    UI::Probes::FormRowProbe.reset
    UI::Probes::RuntimeOverrideProbe.reset
    @@initialized = true
  end

  def self.last_native=(nv : UI::NativeView)
    @@last_native = nv
  end

  def self.build_view(slug : String) : UI::View
    state = InitiativeDemo::State.new
    view = InitiativeDemo.build_screen(slug, state)
    # Tag the root for XCUITest discovery (mirrors hig-component-root
    # in the older iOS host).
    view.accessibility_label = "cascade-root-#{slug}" if view.accessibility_label.to_s.empty?
    view.test_id = "cascade-root-#{slug}" if view.test_id.to_s.empty?
    view
  end
end

# ---------------------------------------------------------------------------
# C ABI exports
# ---------------------------------------------------------------------------

fun cascade_init : Void
  CascadeBridge.initialize_runtime
end

fun cascade_render(slug_ptr : LibC::Char*) : Void*
  CascadeBridge.initialize_runtime
  slug = String.new(slug_ptr)
  view = CascadeBridge.build_view(slug)
  renderer = UI::UIKit::Renderer.new
  renderer.design_tokens = InitiativeDemo.brand_tokens
  native = renderer.render(view)
  CascadeBridge.last_native = native
  native.handle.ptr!
end

{% end %}
