# Fixture: registers a screen with no native side AND no web side.
# Expected: `crystal build` fails with the "must declare at least one
# side" macro {% raise %} from src/asset_pipeline/native_app.cr.
require "../../../../src/asset_pipeline/native_app"

class Phase08CNoSideApp < UI::App
  screen :empty
end
