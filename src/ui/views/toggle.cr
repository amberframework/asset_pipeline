# On / off toggle switch with optional label.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) || flag?(:ios) %}
  require "../native/swiftkit_bridge"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Toggle — On / off toggle switch with optional label.
  class Toggle < View
    getter is_on : Bool = false

    # Reactive setter — programmatically flips a rendered SwiftUI Toggle
    # without firing the `on_change` callback (Crystal initiated the
    # mutation; firing the proc back at Crystal would loop). See
    # `apsk_toggle_set_value` (Swift `@_cdecl`) for the SwiftKit-side
    # implementation.
    def is_on=(new_value : Bool) : Bool
      @is_on = new_value
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_toggle_set_value(sh, new_value ? 1 : 0)
        end
      {% end %}
      new_value
    end
    property label : String = ""
    property style : ToggleStyle = ToggleStyle::Switch
    property tint_color : Color? = nil
    property on_change : Proc(Bool, Nil)? = nil
    # Whether the toggle is non-interactive (grayed out).
    # Maps to NSButton setEnabled:NO (AppKit) and UISwitch setEnabled:NO (UIKit).
    property disabled : Bool = false

    def initialize(@label : String = "", @is_on : Bool = false)
    end

    def initialize(@label : String = "", @is_on : Bool = false, &block : Bool -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
