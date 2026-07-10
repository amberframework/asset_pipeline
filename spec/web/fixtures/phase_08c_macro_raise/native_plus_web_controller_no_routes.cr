# Fixture: declares a native controller AND a web_controller, but no
# web_path or web_actions. Expected: same {% raise %} as the bare-
# web_controller case — a web_controller with no route description
# emits nothing whether or not a native controller is also present.
# (Codex iter-1 rev-1 MINOR finding tightening.)
require "../../../../src/asset_pipeline/native_app"
require "../../../../src/asset_pipeline/native_controller"

class Phase08CNativePlusWebScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    UI::Label.new("x")
  end
end

class Phase08CNativePlusWebController < UI::Controller
end

class Phase08CNativePlusWebWebController
end

class Phase08CNativePlusWebApp < UI::App
  screen :foo, Phase08CNativePlusWebController,
         web_controller: Phase08CNativePlusWebWebController
end
