require "./component"
require "json"

module Components
  # Base class for stateful components
  # These components maintain internal state and can respond to user interactions
  abstract class StatefulComponent < Component
    # Component state stored as JSON-compatible values
    @state : Hash(String, JSON::Any)
    
    # Track if component has changed
    @changed : Bool = false
    
    def initialize(**attrs)
      super(**attrs)
      @state = {} of String => JSON::Any
      initialize_state
      @changed = false  # Reset after initialization
    end
    
    # Initialize component state (to be overridden by subclasses)
    protected def initialize_state
    end
    
    # Get a state value
    def get_state(key : String) : JSON::Any?
      @state[key]?
    end
    
    # Set a state value
    def set_state(key : String, value : JSON::Any) : Nil
      old_value = @state[key]?
      @state[key] = value
      
      if old_value != value
        @changed = true
        state_changed(key, old_value, value)
      end
    end
    
    # Set state from various types
    def set_state(key : String, value : String)
      set_state(key, JSON::Any.new(value))
    end
    
    def set_state(key : String, value : Int32)
      set_state(key, JSON::Any.new(value.to_i64))
    end
    
    def set_state(key : String, value : Int64)
      set_state(key, JSON::Any.new(value))
    end
    
    def set_state(key : String, value : Float32)
      set_state(key, JSON::Any.new(value.to_f64))
    end
    
    def set_state(key : String, value : Float64)
      set_state(key, JSON::Any.new(value))
    end
    
    def set_state(key : String, value : Bool)
      set_state(key, JSON::Any.new(value))
    end
    
    def set_state(key : String, value : Array(JSON::Any))
      set_state(key, JSON::Any.new(value))
    end
    
    def set_state(key : String, value : Hash(String, JSON::Any))
      set_state(key, JSON::Any.new(value))
    end
    
    # Check if component has changed
    def changed? : Bool
      @changed
    end
    
    # Reset changed flag
    def reset_changed!
      @changed = false
    end
    
    # Alias for consistency
    def reset_changed
      reset_changed!
    end
    
    # Mark component as changed
    def mark_changed!
      @changed = true
    end
    
    # Called when state changes (can be overridden)
    protected def state_changed(key : String, old_value : JSON::Any?, new_value : JSON::Any)
    end
    
    # Get the current state as a hash
    def state : Hash(String, JSON::Any)
      @state
    end
    
    # Stateful components should not be cached by default
    def cacheable? : Bool
      false
    end
    
    # Convert state to JSON
    def state_to_json : JSON::Any
      JSON::Any.new(@state)
    end
  end
end