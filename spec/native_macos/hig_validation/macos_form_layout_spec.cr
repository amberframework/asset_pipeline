{% if flag?(:macos) %}
require "spec"
require "json"
require "../support/ax_test_patterns"

# Phase 3 BX7 — macOS twin of BX6.
#
# Phase 6.5 D3 refactor: delegates the host launch + per-row frame +
# non-overlap assertions to the FormLayoutProbe pattern.

SHARD_ROOT_BX7   = File.expand_path("../../..", __DIR__)
SHOWCASE_BIN_BX7 = File.join(SHARD_ROOT_BX7, "samples/cross_platform/macos_host/bin/hig_showcase")
EVIDENCE_ROOT_BX7 = File.join(SHARD_ROOT_BX7, "docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5")

describe "Phase 3 BX7 — form layout (macOS)" do
  unless File.exists?(SHOWCASE_BIN_BX7)
    pending "bin/hig_showcase not built (run: make -C samples/cross_platform/macos_host build)"
    next
  end

  it "renders three form rows at non-zero size without overlap" do
    Dir.mkdir_p(File.join(EVIDENCE_ROOT_BX7, "inspections"))
    Dir.mkdir_p(File.join(EVIDENCE_ROOT_BX7, "screenshots"))

    AXTestPatterns::HostLaunch.with_host("phase-03-form-nested-buttons") do |app|
      frames = AXTestPatterns::FormLayoutProbe.run(
        app,
        row_ids: %w[form-row-1 form-row-2 form-row-3],
      )

      File.write(
        File.join(EVIDENCE_ROOT_BX7, "inspections/BX7-ax-frames.json"),
        frames.map { |f| {identifier: f.identifier, x: f.x, y: f.y, width: f.width, height: f.height} }.to_json
      )

      AXTestPatterns::FormLayoutProbe.assert_stacked_non_overlapping(frames)

      # Drive AXPress on row 2 — row must remain present.
      row2 = AXTestPatterns::Helpers.find_by_identifier(app, "form-row-2")
      row2.should_not be_nil
      if r2 = row2
        r2.click
        sleep(0.2.seconds)
        re_row2 = AXTestPatterns::Helpers.find_by_identifier(app, "form-row-2")
        re_row2.should_not be_nil
        counter = AXTestPatterns::Helpers.find_by_identifier(app, "form-row-2-counter", role: "AXStaticText")
        counter_value = counter.try(&.value) || "(not found)"
        File.write(
          File.join(EVIDENCE_ROOT_BX7, "inspections/BX7-tap-result.json"),
          {row2_present_after_tap: true, counter_value: counter_value}.to_json
        )
      end

      app.screenshot(File.join(EVIDENCE_ROOT_BX7, "screenshots/BX7-form-rendered.png"))
    end
  end
end

{% end %}
