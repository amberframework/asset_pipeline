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
      component_css <<-CSS
      .am-chat {
        display: grid;
        gap: 1rem;
      }

      .am-chat__messages {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.625rem;
        max-height: 25rem;
        min-height: 16rem;
        overflow-y: auto;
        padding: 1rem;
      }

      .am-chat__message {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-primary);
        padding: 0.625rem 0.75rem;
      }

      .am-chat__author {
        color: var(--ap-color-brand-primary-active);
      }

      .am-chat__input-row {
        align-items: center;
        display: grid;
        gap: 0.5rem;
        grid-template-columns: minmax(0, 1fr) auto;
      }

      @media (max-width: 36rem) {
        .am-chat__input-row {
          grid-template-columns: 1fr;
        }

        .am-chat__send .am-button {
          width: 100%;
        }
      }
      CSS

      def initialize(**attrs)
        super
      end

      protected def initialize_state
        set_state("messages", [] of JSON::Any)
        set_state("draft", "")
        set_state("username", @attributes["username"]? || "Anonymous")
      end

      def render_content : String
        Elements::Div.new(class: "am-chat").build do |container|
          # Messages container
          messages_div = Elements::Div.new(class: "am-chat__messages", role: "log", "aria-live": "polite")

          messages = get_state("messages").try(&.as_a?) || [] of JSON::Any
          messages.each do |msg|
            message_div = Elements::Div.new(class: "am-chat__message")

            # Username
            username = Elements::Strong.new(class: "am-chat__author")
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
          input_group = Elements::Div.new(class: "am-chat__input-row")

          # Message input
          input = Elements::Input.new(
            type: "text",
            name: "message",
            placeholder: "Type a message...",
            class: "am-input",
            value: get_state("draft").try(&.as_s?) || "",
            "aria-label": "Message",
            "data-action": "input->update_draft"
          )
          input_group << input

          # Send button
          button_wrapper = Elements::Div.new(class: "am-chat__send")
          button = Elements::Button.new(type: "submit", class: "am-button am-button--brand am-button--solid am-button--md")
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
          "id"        => JSON::Any.new(Time.utc.to_unix_ms),
          "username"  => get_state("username") || JSON::Any.new("Anonymous"),
          "text"      => JSON::Any.new(draft),
          "timestamp" => JSON::Any.new(Time.utc.to_s),
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
