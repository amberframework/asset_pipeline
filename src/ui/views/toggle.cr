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
    # Whether the control is in the on / checked state.
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

    # Caption / accessibility label rendered alongside the control.
    property label : String = ""
    # Visual style variant applied to the control.
    property style : ToggleStyle = ToggleStyle::Switch
    # Explicit appearance override. Native keeps the platform switch default.
    property appearance : ToggleAppearance = ToggleAppearance::Native
    # Colors used by the opt-in machined toggle appearances.
    property track_color : SurfaceColor? = nil
    property knob_color : SurfaceColor? = nil
    property on_color : SurfaceColor? = nil
    property lamp_color : SurfaceColor? = nil
    # Tint applied to platform-native chrome (button highlight, selection, etc).
    property tint_color : Color? = nil
    # Invoked when the user changes the control's value.
    property on_change : Proc(Bool, Nil)? = nil
    # Whether the toggle is non-interactive (grayed out).
    # Maps to NSButton setEnabled:NO (AppKit) and UISwitch setEnabled:NO (UIKit).
    property disabled : Bool = false

    def initialize(@label : String = "", @is_on : Bool = false)
    end

    # JSON-encode the explicit custom appearance settings for the SwiftUI facade.
    def surface_craft_toggle_json : String?
      return nil if appearance == ToggleAppearance::Native && track_color.nil? && knob_color.nil? && on_color.nil? && lamp_color.nil?

      JSON.build do |json|
        json.object do
          json.field "appearance", appearance.to_s.underscore
          if color = track_color
            json.field "track", SurfaceCraftEncoding.color_value(color)
          end
          if color = knob_color
            json.field "knob", SurfaceCraftEncoding.color_value(color)
          end
          if color = on_color
            json.field "on", SurfaceCraftEncoding.color_value(color)
          end
          if color = lamp_color
            json.field "lamp", SurfaceCraftEncoding.color_value(color)
          end
        end
      end
    end

    def initialize(@label : String = "", @is_on : Bool = false, &block : Bool -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end

    # Phase 10B.2a — default AX role: `:switch`.
    def default_accessibility_role : Symbol?
      :switch
    end

    # Phase 10B.2b — interactive widgets default to focusable.
    def default_focusable : Bool
      true
    end
  end
end
