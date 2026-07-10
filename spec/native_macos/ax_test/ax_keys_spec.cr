{% if flag?(:macos) %}

require "spec"
require "../../../src/ui"
require "../../../src/ui/ax_test"

# A6 — Synthetic keyboard events via CGEvent.
#
# These specs verify the API surface and that calls do not raise. Real
# end-to-end verification (key actually delivered to focused app, focus
# advanced, menu dismissed) requires the spec runner to have
# Accessibility permission. CGEventPost without permission is silently
# dropped by the OS — no exception is thrown.
describe UI::AXTest::Keys do
  describe "named key helpers" do
    it "exposes all named keys without raising" do
      # All named helpers should be callable. We don't assert side
      # effects — that requires a focused fixture app. We do assert
      # no exception escapes.
      UI::AXTest::Keys.escape!
      UI::AXTest::Keys.tab!
      UI::AXTest::Keys.shift_tab!
      UI::AXTest::Keys.return!
      UI::AXTest::Keys.arrow_up!
      UI::AXTest::Keys.arrow_down!
      UI::AXTest::Keys.arrow_left!
      UI::AXTest::Keys.arrow_right!
      UI::AXTest::Keys.space!
      UI::AXTest::Keys.delete!
    end

    it "exposes the generic press(keycode, modifiers) API" do
      # Cmd+Tab (app switcher) — posts a key event but we cannot
      # observe it without a fixture. Just verify it runs.
      UI::AXTest::Keys.press(UI::AXTest::Keys::TAB, LibCGEvent::CGEventFlagCommand)
    end
  end

  describe "#type" do
    it "types a multi-character string without raising" do
      UI::AXTest::Keys.type("hello world 123")
    end

    it "handles unicode characters" do
      UI::AXTest::Keys.type("café — résumé — 中文")
    end

    it "handles an empty string" do
      UI::AXTest::Keys.type("")
    end
  end

  describe "permission integration" do
    pending "delivers an Escape key to a focused fixture app and verifies dismiss (requires Accessibility permission)"
  end
end

{% end %}
