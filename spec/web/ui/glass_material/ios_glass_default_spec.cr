require "../../spec_helper"
require "../../../../src/ui/design_tokens"

# Phase 5 v2 probe placeholder — slug `ios.glass.material.default`.
#
# v2 update: this probe verifies per-AppleSemantic mapping on iOS via the
# UIBlurEffectStyle approximation table. UIKit has no first-class semantic
# materials, so each AppleSemantic role maps to a thickness-style
# UIBlurEffect raw value documented in
# `uikit_blur_effect_style_for_semantic`. SDK-verified raw values:
#
#   systemUltraThinMaterial = 6  (Menu)
#   systemThinMaterial      = 7  (Sidebar)
#   systemMaterial          = 8  (Popover, WindowBackground, Titlebar)
#   systemThickMaterial     = 9  (Sheet)
#   systemChromeMaterial    = 10 (HeaderView, HUDWindow)
#
# SystemResolved is the no-call sentinel — UIVisualEffectView built with
# a nil UIBlurEffect renders without explicit blur.
#
# Pending bodies; Phase 6.5 harness work runs the assertions. AX
# identifier convention: `ap.glass.semantic.<semantic_key>`.
describe "Phase 5 v2 probe: ios.glass.material.default" do
  [
    UI::DesignTokens::AppleSemantic::Menu,
    UI::DesignTokens::AppleSemantic::Popover,
    UI::DesignTokens::AppleSemantic::Sidebar,
    UI::DesignTokens::AppleSemantic::Sheet,
    UI::DesignTokens::AppleSemantic::HeaderView,
    UI::DesignTokens::AppleSemantic::WindowBackground,
    UI::DesignTokens::AppleSemantic::HUDWindow,
    UI::DesignTokens::AppleSemantic::Titlebar,
    UI::DesignTokens::AppleSemantic::SystemResolved,
  ].each do |semantic|
    pending "renders the UIBlurEffectStyle approximation for AppleSemantic::#{semantic} on iOS" do
      # Expected shape (Phase 6.5 will implement):
      #   app = UI::AXTest::App.launch(IOS_GLASS_FIXTURE_APP)
      #   screen = app.window("Glass Material Default — #{semantic.to_key}")
      #   elem = screen.find(identifier: "ap.glass.semantic.#{semantic.to_key}")
      #   elem.should_not be_nil
      #   captured = capture_render(elem)
      #   if semantic.system_resolved?
      #     # SystemResolved sentinel — UIVisualEffectView's underlying
      #     # UIBlurEffect should be nil; Apple defaults apply.
      #     captured.blur_effect_present.should be_false
      #   else
      #     captured.blur_effect_style.should eq(<SDK-verified raw integer>)
      #   end
      #   app.screenshot("/tmp/p5v2-ios-#{semantic.to_key}.png")
    end
  end
end
