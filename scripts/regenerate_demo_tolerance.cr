# Phase 6 helper — overwrite the tolerance JSON sidecars for the 5
# demo screens × 4 surfaces × 2 appearances with the canonical
# `pixel_diff_max` / `channel_diff_max` schema that scripts/visual_diff.cr
# actually reads. The capture_demo_quad.cr writer originally used a
# documentary schema (max_pixel_diff_pct + max_delta_e) that visual_diff.cr
# does not understand — those fields fell back to the default-strict 0,
# so any environment-driven byte drift surfaced as FAIL even with a
# sidecar present.
#
# Run after baseline capture:
#   crystal run scripts/regenerate_demo_tolerance.cr

require "json"
require "file_utils"

REPO_ROOT     = File.expand_path("..", __DIR__)
BASELINE_ROOT = File.join(REPO_ROOT, "docs/initiative-cross-platform-ui/baselines")

SLUGS = %w[demo-sign-in demo-dashboard demo-detail demo-settings demo-tier-three]
APPEARANCES = %w[light dark]
SURFACES = %w[web-desktop web-mobile macos ios]

# Per-surface tolerance budgets. Native renderers + font hinting + glass
# blur radius drift by ~0.1% across cache states; web rasterizer drift
# is similar magnitude but shows up in font subpixel position.
TOLERANCE_BY_SURFACE = {
  "web-desktop" => {pixel_diff_max: 5_000_i64, channel_diff_max: 12},
  "web-mobile"  => {pixel_diff_max: 5_000_i64, channel_diff_max: 12},
  "macos"       => {pixel_diff_max: 5_000_i64, channel_diff_max: 12},
  "ios"         => {pixel_diff_max: 5_000_i64, channel_diff_max: 12},
}

SLUGS.each do |slug|
  APPEARANCES.each do |appearance|
    SURFACES.each do |surface|
      png_path  = File.join(BASELINE_ROOT, surface, "#{slug}-#{appearance}.png")
      side_path = File.join(BASELINE_ROOT, surface, "#{slug}-#{appearance}.tolerance.json")
      next unless File.exists?(png_path)
      tol = TOLERANCE_BY_SURFACE[surface]
      json = {
        "pixel_diff_max"   => tol[:pixel_diff_max],
        "channel_diff_max" => tol[:channel_diff_max],
        "surface"          => surface,
        "slug"             => slug,
        "appearance"       => appearance,
        "created_phase"    => "phase-06",
        "notes"            => "Phase 6 quad-comparison baseline. Tolerance budget covers font-hinting / rasterizer drift across cache states.",
      }
      File.write(side_path, json.to_pretty_json + "\n")
      puts "wrote #{side_path}"
    end
  end
end
