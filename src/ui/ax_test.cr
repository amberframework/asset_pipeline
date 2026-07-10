{% if flag?(:macos) %}

# UI::AXTest — Crystal-native UI testing via the macOS Accessibility API.
#
# Uses AXUIElement to query any running app's accessibility tree, verify
# elements exist, read their properties, simulate interactions, and
# capture screenshots. Runs with `crystal spec` — no Xcode required.
#
# ## Quick Start
#
#   require "asset_pipeline/ui/ax_test"
#
#   describe "My App Settings" do
#     app = UI::AXTest::App.launch("/Applications/MyApp.app")
#
#     it "opens preferences" do
#       prefs = app.window("Preferences")
#       prefs.should_not be_nil
#     end
#
#     it "has a save button" do
#       btn = app.find(role: "AXButton", label: "Save")
#       btn.should_not be_nil
#     end
#
#     after_all { app.terminate }
#   end
#
# ## Prerequisites
#
# - App must be code-signed
# - Terminal needs Accessibility permission (System Settings → Privacy → Accessibility)
# - Link flags: -framework ApplicationServices -framework CoreFoundation
#
# ## Require
#
#   require "asset_pipeline/ui/ax_test"

require "./ax_test/ax_ffi"
require "./ax_test/ax_element"
require "./ax_test/ax_app"
require "./ax_test/ax_screenshot"
require "./ax_test/ax_keys"

{% end %}
