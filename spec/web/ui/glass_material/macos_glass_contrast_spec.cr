require "../../spec_helper"
require "../../../../src/ui/design_tokens"

# Phase 5 v2 probe placeholder — slug `macos.glass.material.contrast.wcag_aa`.
#
# v2 update: mirror of the iOS contrast probe but for the AppKit renderer.
# Verifies text-on-NSVisualEffectMaterial contrast satisfies WCAG 2.2 AA
# for each AppleSemantic role.
#
# AX identifier convention: `ap.glass.contrast.semantic.<semantic_key>`.
describe "Phase 5 v2 probe: macos.glass.material.contrast.wcag_aa" do
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
    pending "text_primary on AppleSemantic::#{semantic} meets WCAG-AA 4.5:1 contrast on macOS" do
      # Expected shape (Phase 6.5 will implement) — see iOS counterpart.
    end
  end
end
