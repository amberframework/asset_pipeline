require "../reactive/reactive_component"
require "../elements/forms/form"
require "../elements/forms/input"
require "../elements/forms/form_controls"
require "../elements/grouping/div"
require "../elements/grouping/lists"
require "../elements/text/text_semantics"

module Components
  module Examples
    # Real-time chat component
    class ChatComponent < Reactive::ReactiveComponent
      def initialize(**attrs)
        super
      end
      
      protected def initialize_state
        set_state("messages", [] of JSON::Any)
        set_state("draft", "")
        set_state("username", @attributes["username"]? || "Anonymous")
      end
      
      def render_content : String
        Elements::Div.new(class: "chat-component").build do |container|
          # Messages container
          messages_div = Elements::Div.new(class: "messages", style: "height: 400px; overflow-y: auto; border: 1px solid #ddd; padding: 1rem; margin-bottom: 1rem;")
          
          messages = get_state("messages").try(&.as_a?) || [] of JSON::Any
          messages.each do |msg|
            message_div = Elements::Div.new(class: "message mb-2")
            
            # Username
            username = Elements::Strong.new
            username << (msg["username"]?.try(&.as_s?) || "Unknown")
            username << ": "
            message_div << username
            
            # Message text
            message_div << (msg["text"]?.try(&.as_s?) || "")
            
            messages_div << message_div
          end
          
          container << messages_div
          
          # Message form
          form = Elements::Form.new("data-action": "submit->send_message")
          
          # Input group
          input_group = Elements::Div.new(class: "input-group")
          
          # Message input
          input = Elements::Input.new(
            type: "text",
            name: "message",
            placeholder: "Type a message...",
            class: "form-control",
            value: get_state("draft").try(&.as_s?) || "",
            "data-action": "input->update_draft"
          )
          input_group << input
          
          # Send button
          button_wrapper = Elements::Div.new(class: "input-group-append")
          button = Elements::Button.new(type: "submit", class: "btn btn-primary")
          button << "Send"
          button_wrapper << button
          input_group << button_wrapper
          
          form << input_group
          container << form
        end.render
      end
      
      # Update draft message as user types
      def update_draft(event : JSON::Any)
        draft = event["value"]?.try(&.as_s?) || ""
        set_state("draft", JSON::Any.new(draft))
      end
      
      # Send a message
      def send_message(event : JSON::Any)
        draft = get_state("draft").try(&.as_s?) || ""
        return if draft.empty?
        
        # Add message to list
        messages = get_state("messages").try(&.as_a?) || [] of JSON::Any
        new_message = JSON::Any.new({
          "id" => JSON::Any.new(Time.utc.to_unix_ms),
          "username" => get_state("username") || JSON::Any.new("Anonymous"),
          "text" => JSON::Any.new(draft),
          "timestamp" => JSON::Any.new(Time.utc.to_s)
        } of String => JSON::Any)
        
        messages << new_message
        
        # Update state and clear draft
        update_state do
          set_state("messages", JSON::Any.new(messages))
          set_state("draft", JSON::Any.new(""))
        end
        
        # In a real app, this would also broadcast to other users
        # ReactiveHandler.broadcast_update would handle this
      end
      
      # Receive a message from another user
      def receive_message(message : JSON::Any)
        messages = get_state("messages").try(&.as_a?) || [] of JSON::Any
        messages << message
        set_state("messages", JSON::Any.new(messages))
      end
    end
  end
end