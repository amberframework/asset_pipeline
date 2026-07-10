# Type-safe reactive state container (`UI::State(T)`). Notifies registered
# listeners on value change (equality-checked) and underpins controlled inputs.

module UI
  # Type-safe reactive state container.
  #
  # When the value changes, all registered listeners are notified with
  # the old and new values. Listeners are NOT called when the same
  # value is assigned (equality check via `!=`).
  #
  # Example:
  #   counter = UI::State(Int32).new(0)
  #   counter.on_change { |old_val, new_val| puts "#{old_val} -> #{new_val}" }
  #   counter.value = 1  # prints "0 -> 1"
  #   counter.value = 1  # no output (same value)
  class State(T)
    getter value : T
    @listeners : Array(Proc(T, T, Nil))

    def initialize(@value : T)
      @listeners = [] of Proc(T, T, Nil)
    end

    def value=(new_value : T) : T
      old = @value
      @value = new_value
      if old != new_value
        @listeners.each { |listener| listener.call(old, new_value) }
      end
      new_value
    end

    def on_change(&block : T, T -> Nil) : Nil
      @listeners << block
    end

    def remove_listeners : Nil
      @listeners.clear
    end
  end
end
