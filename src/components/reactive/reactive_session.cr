require "http/web_socket"
require "../base/component"

module Components
  module Reactive
    # Manages a reactive WebSocket session
    class ReactiveSession
      getter id : String
      getter socket : HTTP::WebSocket
      getter components : Hash(String, Component)
      getter created_at : Time
      
      def initialize(@socket : HTTP::WebSocket)
        @id = ""
        @components = {} of String => Component
        @created_at = Time.utc
        @mutex = Mutex.new
      end
      
      def id=(@id : String)
      end
      
      # Register a component with this session
      def register_component(component_id : String, component : Component? = nil) : Nil
        @mutex.synchronize do
          if component
            @components[component_id] = component
          else
            # Mark that we're tracking this component ID
            # The actual component instance will be set later
            @components[component_id] = DummyComponent.new(component_id)
          end
        end
      end
      
      # Get a component by ID
      def get_component(component_id : String) : Component?
        @mutex.synchronize do
          component = @components[component_id]?
          
          # If it's a dummy, return nil
          component.is_a?(DummyComponent) ? nil : component
        end
      end
      
      # Check if session has a component
      def has_component?(component_id : String) : Bool
        @mutex.synchronize do
          @components.has_key?(component_id)
        end
      end
      
      # Set actual component instance
      def set_component(component_id : String, component : Component) : Nil
        @mutex.synchronize do
          @components[component_id] = component
        end
      end
      
      # Send message to client
      def send_message(message : Hash | NamedTuple) : Nil
        begin
          @socket.send(message.to_json)
        rescue ex
          # Connection closed, cleanup will happen
        end
      end
      
      # Send batch update
      def send_batch_update(updates : Array(NamedTuple)) : Nil
        send_message({
          type: "batch_update",
          updates: updates
        })
      end
      
      # Cleanup session
      def cleanup : Nil
        @mutex.synchronize do
          @components.clear
        end
      end
      
      # Get session info
      def info : NamedTuple
        @mutex.synchronize do
          {
            id: @id,
            created_at: @created_at,
            component_count: @components.size,
            connected: !@socket.closed?
          }
        end
      end
    end
    
    # Placeholder component for tracking IDs before actual component is available
    private class DummyComponent < Component
      def initialize(@component_id : String)
        super()
      end
      
      def render_content : String
        ""
      end
    end
  end
end