require "../../spec_helper"
require "../../../../src/ui/design_tokens"

# Phase 5 v2 probe placeholder — slug `macos.glass.material.default`.
#
# v2 update: this probe verifies per-AppleSemantic mapping (NOT per-step
# thickness). Each role maps 1:1 to an NSVisualEffectMaterial integer via
# `appkit_visual_effect_material_for_semantic`; SystemResolved is the
# no-call sentinel.
#
# Pending bodies; Phase 6.5 harness work runs the assertions. AX
# identifier convention: `ap.glass.semantic.<semantic_key>`.
describe "Phase 5 v2 probe: macos.glass.material.default" do
  # All 9 AppleSemantic roles in the v2 enum. The 8 non-SystemResolved
  # values each map to a unique NSVisualEffectMaterial integer; the 9th
  # (SystemResolved) is the no-call sentinel — when it's the declared
  # semantic, the renderer emits NO setMaterial: call and lets Apple
  # defaults apply. The probe must verify both.
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
    pending "renders the NSVisualEffectMaterial for AppleSemantic::#{semantic} on macOS" do
      # Expected shape (Phase 6.5 will implement):
      #   app = UI::AXTest::App.launch(MACOS_GLASS_FIXTURE_APP)
      #   screen = app.window("Glass Material Default — #{semantic.to_key}")
      #   elem = screen.find(identifier: "ap.glass.semantic.#{semantic.to_key}")
      #   elem.should_not be_nil
      #   visual = app.capture_glass_material(elem)
      #   if semantic.system_resolved?
      #     # SystemResolved sentinel — no explicit setMaterial: should be
      #     # emitted. Apple defaults visible.
      #     visual.has_explicit_material.should be_false
      #   else
      #     visual.material_integer.should eq(<expected NSVisualEffectMaterial>)
      #   end
      #   app.screenshot("/tmp/p5v2-macos-#{semantic.to_key}.png")
    end
  end
end
