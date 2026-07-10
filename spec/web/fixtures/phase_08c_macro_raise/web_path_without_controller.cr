# Fixture: declares web_path without web_controller.
# Expected: `crystal build` fails with the "declares web_path or
# web_actions but no web_controller" macro {% raise %}.
require "../../../../src/asset_pipeline/native_app"

class Phase08CMissingCtrlApp < UI::App
  screen :foo, web_path: "/foo"
end
