module Components
  module Reactive
    # Registry for component actions to enable dynamic dispatch
    module ActionRegistry
      @@actions = {} of String => Proc(Component, JSON::Any?, Nil)
      
      # Register an action handler
      def self.register(action_name : String, &block : Component, JSON::Any? -> Nil)
        @@actions[action_name] = block
      end
      
      # Execute an action if registered
      def self.execute(component : Component, action_name : String, data : JSON::Any?) : Bool
        if handler = @@actions[action_name]?
          handler.call(component, data)
          true
        else
          false
        end
      end
      
      # Check if an action is registered
      def self.has_action?(action_name : String) : Bool
        @@actions.has_key?(action_name)
      end
      
      # Macro to define reactive actions in components
      macro reactive_action(name)
        # Register the action when the class is loaded
        Components::Reactive::ActionRegistry.register({{name.stringify}}) do |component, data|
          if component.responds_to?({{name}})
            component.{{name.id}}(data)
          end
        end
        
        # Define the actual method
        def {{name.id}}(data : JSON::Any?)
          {{yield}}
        end
      end
    end
  end
end