{% if flag?(:macos) %}
  require "spec"

  describe "UI::Label selectable text behavior on macOS" do
    pending "copy proof pending: SwiftUI's selectable NSTextView was not discoverable in 3/3 AppKit subview walks; prior AX and Quartz attempts varied between focus 8/15 and 15/15, selection lengths 0 and 39, and sentinel versus exact-path pasteboard contents"
  end
{% end %}
