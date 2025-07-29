require "../base/stateful_component"
require "./reactive_handler"

module Components
  module Reactive
    # Base class for components that support real-time updates via WebSocket
    abstract class ReactiveComponent < StatefulComponent
      # Whether this component should auto-update on state changes
      property auto_update : Bool = true
      
      # Override render to include reactive data attributes
      def render : String
        wrapped = Elements::Div.new(
          "data-component-id": component_id,
          "data-component-type": self.class.name
        )
        
        # Add the component content
        wrapped << render_content
        
        wrapped.render
      end
      
      # Register this component with the reactive handler
      def register : Nil
        ReactiveHandler.register_component(self)
      end
      
      # Unregister this component
      def unregister : Nil
        ReactiveHandler.unregister_component(component_id)
      end
      
      # Send update to all connected clients
      def push_update : Nil
        return unless changed?
        
        ReactiveHandler.broadcast_update(
          component_id,
          render,
          state_to_json
        )
        
        reset_changed
      end
      
      # Override state setters to trigger updates
      def set_state(key : String, value : JSON::Any) : Nil
        super
        push_update if @auto_update
      end
      
      # Batch state updates
      def update_state(&block : -> Nil) : Nil
        # Temporarily disable auto-update
        old_auto_update = @auto_update
        @auto_update = false
        
        # Execute state changes
        yield
        
        # Re-enable and push update
        @auto_update = old_auto_update
        push_update if @auto_update
      end
      
      # Handle incoming actions from client
      def handle_action(action : String, data : JSON::Any) : Nil
        # Override in subclasses to handle specific actions
      end
      
      # Broadcast update to all sessions with this component
      def broadcast_update : Nil
        ReactiveSocket.update_component(
          component_id,
          render,
          state_to_json
        )
        
        reset_changed
      end
      
      # Subscribe to server-side events
      macro on_event(event_name, &block)
        def handle_{{event_name.id}}_event(data : JSON::Any)
          {{block.body}}
        end
      end
      
      # Define client-side action handler
      macro on_action(action_name, &block)
        def {{action_name.id}}(data : JSON::Any)
          {{block.body}}
          push_update if changed?
        end
      end
    end
  end
end