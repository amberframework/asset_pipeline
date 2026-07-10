require "../../spec_helper"
require "../../../../src/ui/design_tokens"

# Phase 5 probe placeholder — slug `macos.glass.material.env_response`.
#
# Mirror of `ios_glass_env_response_spec.cr` for the AppKit renderer.
# AX identifier convention: `ap.glass.env.<axis>.<step>`.
describe "Phase 5 probe: macos.glass.material.env_response" do
  steps = [:ultra_thin, :thin, :regular, :thick, :chrome]

  describe "reduced_motion cell" do
    steps.each do |step|
      pending "renders `#{step}` without renderer-side animation under reduced_motion on macOS" do
      end
    end
  end

  describe "high_contrast cell" do
    steps.each do |step|
      pending "renders `#{step}` with documented high_contrast response on macOS" do
      end
    end
  end

  describe "dark_mode cell" do
    steps.each do |step|
      pending "renders `#{step}` differently in dark vs light appearance on macOS" do
      end
    end
  end
end
