#!/usr/bin/env crystal
# Asset Pipeline — Amber integration CLI.
#
# Run from a consuming app's project root:
#   crystal run lib/asset_pipeline/scripts/asset_pipeline_amber.cr -- generate <controller> <action>
#
# Or compile once and use the binary:
#   crystal build lib/asset_pipeline/scripts/asset_pipeline_amber.cr -o bin/asset_pipeline_amber
#   bin/asset_pipeline_amber generate sign_in index
#
# Writes `src/views/<controller>/<action>.ecr` containing the one-line
# shim `<%= @screen_html %>`. See `src/asset_pipeline/amber_integration.cr`
# for the rationale (Amber's `render` macro expands to a compile-time
# Kilt template lookup; the shim has to exist on disk before
# compilation, so macros cannot emit it during the same compilation).

require "../src/asset_pipeline/cli/amber_generator"

exit AssetPipeline::CLI::AmberGenerator.run(ARGV)
