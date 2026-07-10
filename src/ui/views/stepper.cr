# Increment / decrement stepper for adjusting a discrete numeric value.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Stepper — Increment / decrement stepper for adjusting a discrete numeric value.
  class Stepper < View
    property value : Float64 = 0.0
    property minimum : Float64 = 0.0
    property maximum : Float64 = 100.0
    property step_value : Float64 = 1.0
    property label : String = ""
    property wraps : Bool = false
    property on_change : Proc(Float64, Nil)? = nil

    def initialize(@minimum : Float64 = 0.0, @maximum : Float64 = 100.0, @value : Float64 = 0.0)
    end

    def initialize(@minimum : Float64, @maximum : Float64, @value : Float64 = 0.0, &block : Float64 -> Nil)
      @on_change = block
    end

    def increment
      new_val = @value + @step_value
      if new_val > @maximum
        @value = @wraps ? @minimum : @maximum
      else
        @value = new_val
      end
    end

    def decrement
      new_val = @value - @step_value
      if new_val < @minimum
        @value = @wraps ? @maximum : @minimum
      else
        @value = new_val
      end
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
