require "http/server"
require "http/web_socket"
require "json"
require "./reactive_session"
require "./action_registry"
require "../base/component"

module Components
  module Reactive
    # HTTP Handler for reactive components
    # This handler can be added to any Crystal web framework's middleware pipeline
    # 
    # Example usage in Amber:
    #   pipeline :web do
    #     plug Components::Reactive::ReactiveHandler.new
    #   end
    #
    # The handler manages:
    # 1. WebSocket connections for real-time updates
    # 2. HTTP POST requests for component actions (non-WebSocket fallback)
    # 3. Component lifecycle and state management
    class ReactiveHandler
      include HTTP::Handler
      
      # Configuration
      property websocket_path : String
      property action_path_prefix : String
      property enable_http_fallback : Bool
      
      # Class-level session management
      @@sessions = {} of String => ReactiveSession
      @@sessions_mutex = Mutex.new
      
      # Component instances by ID
      @@components = {} of String => Component
      @@components_mutex = Mutex.new
      
      def initialize(
        @websocket_path : String = "/components/ws",
        @action_path_prefix : String = "/components/action",
        @enable_http_fallback : Bool = true
      )
      end
      
      def call(context) : Nil
        request = context.request
        
        case
        when websocket_upgrade?(request)
          handle_websocket(context)
        when component_action?(request)
          handle_http_action(context)
        else
          call_next(context)
        end
      end
      
      private def websocket_upgrade?(request : HTTP::Request) : Bool
        request.path == @websocket_path && 
        request.headers["Upgrade"]? == "websocket"
      end
      
      private def component_action?(request : HTTP::Request) : Bool
        @enable_http_fallback && 
        request.method == "POST" && 
        request.path.starts_with?(@action_path_prefix)
      end
      
      private def handle_websocket(context : HTTP::Server::Context) : Nil
        ws_handler = HTTP::WebSocketHandler.new do |ws, ctx|
          session = ReactiveSession.new(ws)
          
          ws.on_message do |message|
            handle_websocket_message(session, message)
          end
          
          ws.on_close do
            cleanup_session(session)
          end
          
          ws.on_ping do
            ws.pong
          end
        end
        
        ws_handler.call(context)
      end
      
      private def handle_websocket_message(session : ReactiveSession, message : String) : Nil
        begin
          data = JSON.parse(message)
          message_type = data["type"].as_s
          
          case message_type
          when "register"
            handle_register(session, data)
          when "action"
            handle_action(session, data)
          when "ping"
            session.send_message({type: "pong"})
          else
            session.send_message({
              type: "error",
              message: "Unknown message type: #{message_type}"
            })
          end
        rescue ex
          session.send_message({
            type: "error",
            message: "Failed to process message: #{ex.message}"
          })
        end
      end
      
      private def handle_register(session : ReactiveSession, data : JSON::Any) : Nil
        session_id = data["sessionId"].as_s
        component_ids = data["components"].as_a.map(&.as_s)
        
        @@sessions_mutex.synchronize do
          session.id = session_id
          @@sessions[session_id] = session
        end
        
        # Associate components with session
        component_ids.each do |component_id|
          if component = get_component(component_id)
            session.register_component(component_id, component)
          end
        end
        
        session.send_message({
          type: "registered",
          sessionId: session_id,
          components: component_ids
        })
      end
      
      private def handle_action(session : ReactiveSession, data : JSON::Any) : Nil
        component_id = data["componentId"].as_s
        method = data["method"].as_s
        event_data = data["event"]
        
        if component = get_component(component_id)
          execute_component_action(component, method, event_data, session)
        else
          session.send_message({
            type: "error",
            message: "Component not found: #{component_id}"
          })
        end
      end
      
      # HTTP fallback for non-WebSocket environments
      private def handle_http_action(context : HTTP::Server::Context) : Nil
        begin
          body = context.request.body.try(&.gets_to_end) || ""
          data = JSON.parse(body)
          
          component_id = data["componentId"].as_s
          method = data["method"].as_s
          event_data = data["event"]?
          
          if component = get_component(component_id)
            # Execute action
            result = execute_component_action_http(component, method, event_data)
            
            # Return updated component HTML
            context.response.content_type = "application/json"
            context.response.print({
              success: true,
              componentId: component_id,
              html: result[:html],
              state: result[:state]
            }.to_json)
          else
            context.response.status = HTTP::Status::NOT_FOUND
            context.response.print({
              success: false,
              error: "Component not found"
            }.to_json)
          end
        rescue ex
          context.response.status = HTTP::Status::BAD_REQUEST
          context.response.print({
            success: false,
            error: ex.message
          }.to_json)
        end
      end
      
      private def execute_component_action(
        component : Component, 
        method : String, 
        event_data : JSON::Any, 
        session : ReactiveSession
      ) : Nil
        begin
          # Try to execute via action registry first
          success = ActionRegistry.execute(component, method, event_data)
          
          if !success
            # Fallback to known methods
            case method
            when "increment"
              component.increment(event_data) if component.responds_to?(:increment)
            when "search"
              component.search(event_data) if component.responds_to?(:search)
            when "send_message"
              component.send_message(event_data) if component.responds_to?(:send_message)
            when "update_draft"
              component.update_draft(event_data) if component.responds_to?(:update_draft)
            else
              session.send_message({
                type: "error",
                message: "Method not found: #{method}"
              })
              return
            end
          end
            
            # Send update if component changed
            if component.is_a?(StatefulComponent) && component.changed?
              session.send_message({
                type: "update",
                componentId: component.component_id,
                html: component.render,
                state: component.state_to_json
              })
              
              component.reset_changed
            end
        rescue ex
          session.send_message({
            type: "error",
            message: "Action failed: #{ex.message}"
          })
        end
      end
      
      private def execute_component_action_http(
        component : Component,
        method : String,
        event_data : JSON::Any?
      ) : NamedTuple(html: String, state: JSON::Any?)
        # Try action registry first
        success = ActionRegistry.execute(component, method, event_data)
        
        if !success
          # Fallback to known methods
          if event_data
            case method
            when "increment"
              component.increment(event_data) if component.responds_to?(:increment)
            when "search"
              component.search(event_data) if component.responds_to?(:search)
            when "send_message"
              component.send_message(event_data) if component.responds_to?(:send_message)
            when "update_draft"
              component.update_draft(event_data) if component.responds_to?(:update_draft)
            when "receive_message"
              component.receive_message(event_data) if component.responds_to?(:receive_message)
            end
          end
        end
        
        state = nil
        if component.is_a?(StatefulComponent)
          state = component.state_to_json
          component.reset_changed
        end
        
        {html: component.render, state: state}
      end
      
      private def cleanup_session(session : ReactiveSession) : Nil
        @@sessions_mutex.synchronize do
          @@sessions.delete(session.id)
        end
        session.cleanup
      end
      
      # Component management
      
      private def get_component(component_id : String) : Component?
        @@components_mutex.synchronize do
          @@components[component_id]?
        end
      end
      
      # Public API for managing components
      
      def self.register_component(component : Component) : Nil
        @@components_mutex.synchronize do
          @@components[component.component_id] = component
        end
      end
      
      def self.unregister_component(component_id : String) : Nil
        @@components_mutex.synchronize do
          @@components.delete(component_id)
        end
      end
      
      def self.broadcast_update(component_id : String, html : String, state : JSON::Any? = nil) : Nil
        @@sessions_mutex.synchronize do
          @@sessions.each_value do |session|
            if session.has_component?(component_id)
              session.send_message({
                type: "update",
                componentId: component_id,
                html: html,
                state: state
              })
            end
          end
        end
      end
      
      def self.send_to_session(session_id : String, message : Hash | NamedTuple) : Nil
        @@sessions_mutex.synchronize do
          if session = @@sessions[session_id]?
            session.send_message(message)
          end
        end
      end
      
      def self.active_sessions : Int32
        @@sessions_mutex.synchronize do
          @@sessions.size
        end
      end
      
      def self.registered_components : Int32
        @@components_mutex.synchronize do
          @@components.size
        end
      end
    end
  end
end