# Fixture: declares web_controller but no web_path or web_actions.
# Expected: `crystal build` fails with the "web_controller but
# neither web_path nor web_actions" macro {% raise %} (Phase 8C
# iter-1 codex-revision tightening).
require "../../../../src/asset_pipeline/native_app"

class Phase08CWebCtrlOnlyController
end

class Phase08CWebCtrlOnlyApp < UI::App
  screen :foo, web_controller: Phase08CWebCtrlOnlyController
end
