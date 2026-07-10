# Continuous-value slider control with configurable range and step.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) || flag?(:ios) %}
  require "../native/swiftkit_bridge"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Slider — Continuous-value slider control with configurable range and step.
  class Slider < View
    getter value : Float64 = 0.0

    # Reactive setter — programmatically drag a rendered SwiftUI Slider
    # without firing the `on_change` callback (Crystal-initiated mutation
    # would otherwise loop). See `apsk_slider_set_value` for the
    # SwiftKit-side implementation.
    def value=(new_value : Float64) : Float64
      @value = new_value
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_slider_set_value(sh, new_value)
        end
      {% end %}
      new_value
    end
    property minimum : Float64 = 0.0
    property maximum : Float64 = 1.0
    property step : Float64 = 0.0  # 0 = continuous
    property label : String = ""
    property tint_color : Color? = nil
    property on_change : Proc(Float64, Nil)? = nil

    def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 1.0, @value : Float64 = 0.0)
    end

    def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 1.0, @value : Float64 = 0.0, &block : Float64 -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
