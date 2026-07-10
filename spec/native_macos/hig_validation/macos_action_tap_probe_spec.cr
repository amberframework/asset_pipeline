{% if flag?(:macos) %}
require "spec"
require "json"
require "../support/ax_test_patterns"

# Phase 3 BX2 — macOS twin of BX1.
#
# Phase 6.5 D3 refactor: this spec now requires `AXTestPatterns` and
# delegates the host launch + action-tap probe to the pattern library.
# See spec/support/ax_test_patterns.cr.
#
# Run:
#   crystal-alpha spec spec/ui/hig_validation/macos_action_tap_probe_spec.cr \
#     -Dmacos --link-flags="-framework ApplicationServices -framework CoreFoundation"

SHARD_ROOT_BX2   = File.expand_path("../../..", __DIR__)
SHOWCASE_BIN_BX2 = File.join(SHARD_ROOT_BX2, "samples/cross_platform/macos_host/bin/hig_showcase")
EVIDENCE_ROOT    = File.join(SHARD_ROOT_BX2, "docs/initiative-cross-platform-ui/handoff/phase-03-evidence-2026-05-21-iter5")

describe "Phase 3 BX2 — action tap probe (macOS)" do
  unless File.exists?(SHOWCASE_BIN_BX2)
    pending "bin/hig_showcase not built (run: make -C samples/cross_platform/macos_host build)"
    next
  end

  it "renders the probe scene and accepts AXPress on tap-probe-button" do
    Dir.mkdir_p(File.join(EVIDENCE_ROOT, "screenshots"))
    Dir.mkdir_p(File.join(EVIDENCE_ROOT, "inspections"))
    Dir.mkdir_p(File.join(EVIDENCE_ROOT, "test_output"))

    transitions = [] of String

    AXTestPatterns::HostLaunch.with_host("phase-03-action-tap-probe") do |app|
      transitions = AXTestPatterns::ActionTapProbe.run(
        app,
        trigger_id: "tap-probe-button",
        counter_id: "tap-probe-counter",
        expected_values: %w[0 1 2 3],
      )

      File.write(
        File.join(EVIDENCE_ROOT, "inspections/BX2-label-transitions.json"),
        transitions.to_json
      )

      app.screenshot(File.join(EVIDENCE_ROOT, "screenshots/BX2-final.png"))
    end

    transitions.size.should be > 0
  end
end

{% end %}
