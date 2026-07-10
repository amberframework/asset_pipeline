require "../spec_helper"
require "../../../src/asset_pipeline/native_app"

# Spec-only reopening of UI::App. Provides a helper that strands the
# private `@@screens` class-var back to nil so we can simulate the iOS
# class-init gap failure mode and prove `bootstrap!` recovers from it.
# Kept out of production code so the supported `UI::App` API surface
# does not include a destructive registry-wipe method.
abstract class UI::App
  def self._strand_screens_registry_for_specs! : Nil
    @@screens = nil
    nil
  end
end

# Stub screens + controllers used by the registration specs. The real
# `UI::Controller` base class lands in `native_controller.cr` (iter 2);
# the forward declaration in `native_app.cr` is enough for screen
# registration to compile here.
private class NativeAppSpecScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("stub")
  end
end

private class NativeAppSpecOtherScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("other")
  end
end

# This pair tests the implicit FooController -> FooScreen derivation:
# `screen :detail, NativeAppSpecDetailController` (with no explicit
# screen_class) must resolve to NativeAppSpecDetailScreen.
private class NativeAppSpecDetailScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("detail")
  end
end

private class NativeAppSpecController < UI::Controller
end

private class NativeAppSpecOtherController < UI::Controller
end

private class NativeAppSpecDetailController < UI::Controller
end

# Mock app: two explicit screen_class registrations + one implicit
# derivation (NativeAppSpecDetailController -> NativeAppSpecDetailScreen).
private class NativeAppSpecApp < UI::App
  initial_route :primary

  screen :primary, NativeAppSpecController, screen_class: NativeAppSpecScreen
  screen :secondary, NativeAppSpecOtherController, screen_class: NativeAppSpecOtherScreen
  screen :detail, NativeAppSpecDetailController
end

# Mock app that exercises the design_tokens macro override.
private class NativeAppSpecBrandedApp < UI::App
  initial_route :primary
  screen :primary, NativeAppSpecController, screen_class: NativeAppSpecScreen

  design_tokens do |tokens|
    # Override a single observable field with a sentinel value (51.0)
    # so the spec can prove the block body actually ran and its result
    # was wired into the class-getter.
    tokens.copy_with(touch_target_minimum_px: 51.0)
  end
end

describe UI::App do
  it "captures the declared initial_route_id" do
    NativeAppSpecApp.initial_route_id.should eq(:primary)
  end

  it "registers every screen declared by the `screen` macro" do
    NativeAppSpecApp.screens.keys.should contain(:primary)
    NativeAppSpecApp.screens.keys.should contain(:secondary)
  end

  it "looks up a registered screen via registration_for" do
    reg = NativeAppSpecApp.registration_for(:primary)
    reg.route_id.should eq(:primary)
    reg.controller_class.should eq(NativeAppSpecController)
    reg.screen_class.should eq(NativeAppSpecScreen)
  end

  it "raises UnknownRouteError with the available routes for an unknown id" do
    expect_raises(UI::App::UnknownRouteError, /not_a_route/) do
      NativeAppSpecApp.registration_for(:not_a_route)
    end
  end

  it "derives FooController -> FooScreen by default when screen_class omitted" do
    reg = NativeAppSpecApp.registration_for(:detail)
    reg.controller_class.should eq(NativeAppSpecDetailController)
    reg.screen_class.should eq(NativeAppSpecDetailScreen)
  end

  it "defaults app_design_tokens to a Tokens instance" do
    NativeAppSpecApp.app_design_tokens.should be_a(UI::DesignTokens::Tokens)
  end

  it "leaves initial_route_id unset for apps that don't declare one" do
    UI::App.initial_route_id.should eq(:_unset)
  end

  it "runs the design_tokens macro block and exposes the override via app_design_tokens" do
    # The sentinel 51.0 in NativeAppSpecBrandedApp's design_tokens block
    # is observable on app_design_tokens; the default (44.0) is what an
    # un-overridden subclass returns.
    NativeAppSpecBrandedApp.app_design_tokens.touch_target_minimum_px.should eq(51.0)
    NativeAppSpecApp.app_design_tokens.touch_target_minimum_px.should eq(44.0)
  end

  it "bootstrap! is idempotent and re-registers every screen" do
    # Force-clear the registry, then bootstrap, and verify both explicit
    # and derived registrations land back in. Two passes prove idempotence.
    original_keys = NativeAppSpecApp.screens.keys.dup
    NativeAppSpecApp.screens.clear
    NativeAppSpecApp.screens.size.should eq(0)
    NativeAppSpecApp.bootstrap!
    NativeAppSpecApp.screens.size.should eq(original_keys.size)
    original_keys.each { |k| NativeAppSpecApp.screens.has_key?(k).should be_true }
    # Second call — must not duplicate or fail.
    NativeAppSpecApp.bootstrap!
    NativeAppSpecApp.screens.size.should eq(original_keys.size)
  end

  it "bootstrap! recovers when @@screens is stranded as nil (iOS class-init gap simulation)" do
    # Simulate the iOS class-init gap failure mode: the `@@screens`
    # class-var default initialiser never ran, so the underlying var
    # is nil. `bootstrap!` must allocate a fresh registry hash AND
    # populate it from the compile-time-emitted `_bootstrap_screen_*`
    # methods — both halves survive the gap because methods exist at
    # compile time, not module-load time.
    original_keys = NativeAppSpecApp.screens.keys.dup
    NativeAppSpecApp._strand_screens_registry_for_specs!
    NativeAppSpecApp.bootstrap!
    NativeAppSpecApp.screens.size.should eq(original_keys.size)
    original_keys.each { |k| NativeAppSpecApp.screens.has_key?(k).should be_true }
  end

  it "initial_route_id is method-emitted (compile-time code), not class-var default" do
    # Phase 8B item 1 hardening: the iOS class-init gap can skip class-
    # var default initialisers, but method definitions are compile-time
    # emitted code. Confirm both the default and the override resolve
    # via method dispatch rather than a class-var read — exercised by
    # the override returning the symbol declared in the `initial_route`
    # macro (which itself emits a method override).
    NativeAppSpecApp.initial_route_id.should eq(:primary)
    UI::App.initial_route_id.should eq(:_unset)
  end

  it "app_design_tokens is method-emitted and caches the override result" do
    # Calling twice must return the SAME Tokens instance (cached via
    # the @@app_design_tokens class-var) — proves the block doesn't
    # re-run per call. The cache var itself starts nil; the lazy
    # accessor populates it. iOS gap can strand the cache var as nil
    # but the accessor's method body recomputes on demand.
    a = NativeAppSpecBrandedApp.app_design_tokens
    b = NativeAppSpecBrandedApp.app_design_tokens
    a.should be(b)
    a.touch_target_minimum_px.should eq(51.0)
  end
end
