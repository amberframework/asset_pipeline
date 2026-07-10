# Phase 8 Amber Spike — minimal Amber bootstrap.
#
# Purpose: prove that asset_pipeline can drop into Amber as a view layer
# via `render_screen` helper without wrapping HTTP::Server::Context.

require "amber"

# Phase 8A: lifted helpers now live in the asset_pipeline shard at
# `src/asset_pipeline/amber_integration.cr`. The spike requires the
# production path directly; the old prototype helper at
# `src/lib/asset_pipeline_amber_helpers.cr` is retained for diff
# reference but no longer required.
require "asset_pipeline/amber_integration"

# Phase 8C: `UI::App` ships the unified screen / route registry.
# `config/routes.cr` consumes `SpikeApp` via
# `UI::AmberIntegration.routes_for(SpikeApp)`, so `SpikeApp` must be
# defined BEFORE the routes file is required.
require "asset_pipeline/native_app"

# Load the application code.
require "../src/controllers/application_controller"
require "../src/controllers/sign_in_controller"
require "../src/screens/sign_in_screen"

# Phase 8C — unified UI::App declaration. A single SpikeApp class drives
# BOTH native screen-registry navigation (when the native side lands in
# a follow-up phase) AND Amber web route registration (consumed by
# config/routes.cr via UI::AmberIntegration.routes_for(SpikeApp)).
#
# Today the spike only exercises the web side, so the :sign_in screen
# is registered as web-only — no positional UI::Controller, just the
# Amber controller via web_controller:. Phase 8C's nilable
# controller_class makes this legal.
class SpikeApp < UI::App
  screen :sign_in,
         web_controller: SignInController,
         web_path: "/",
         web_actions: [
           {verb: :get, action: :index},
           {verb: :post, action: :submit, path: "/sign_in/submit"},
         ]
end

# Then routes (must come after controllers AND SpikeApp are defined).
require "./routes"
