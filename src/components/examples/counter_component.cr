require "../base/stateful_component"
require "../elements/grouping/div"
require "../elements/grouping/span"
require "../elements/forms/form_controls"

module Components
  module Examples
    # A stateful counter component
    class CounterComponent < StatefulComponent
      component_css <<-CSS
      .am-counter {
        display: grid;
        gap: 0.75rem;
      }

      .am-counter__display {
        color: var(--ap-color-text-secondary);
      }

      .am-counter__value {
        color: var(--ap-color-text-primary);
        font-weight: 760;
      }

      .am-counter__controls {
        display: flex;
        flex-wrap: wrap;
        gap: 0.5rem;
      }
      CSS

      # Initialize the component state
      protected def initialize_state
        set_state("count", 0)
      end

      # Action methods
      def increment(data : JSON::Any? = nil)
        current = get_state("count").try(&.as_i?) || 0
        set_state("count", current + 1)
      end

      def decrement(data : JSON::Any? = nil)
        current = get_state("count").try(&.as_i?) || 0
        set_state("count", current - 1)
      end

      def reset(data : JSON::Any? = nil)
        set_state("count", 0)
      end

      def render_content : String
        count = get_state("count").try(&.as_i?) || 0

        # Build counter UI
        container = Elements::Div.new(class: "am-counter").build do |c|
          # Display
          c << Elements::Div.new(class: "am-counter__display").build do |display|
            label_span = Elements::Span.new(class: "am-counter__label")
            label_span << "Count: "
            display << label_span

            value_span = Elements::Span.new(class: "counter-value am-counter__value")
            value_span << count.to_s
            display << value_span
          end

          # Controls
          c << Elements::Div.new(class: "am-counter__controls").build do |controls|
            # Decrement button
            dec_btn = Elements::Button.new(
              type: "button",
              class: "am-button am-button--neutral am-button--outline am-button--sm",
              "data-action": "click->decrement"
            )
            dec_btn << "-"
            controls << dec_btn

            controls << " "

            # Increment button
            inc_btn = Elements::Button.new(
              type: "button",
              class: "am-button am-button--brand am-button--solid am-button--sm",
              "data-action": "click->increment"
            )
            inc_btn << "+"
            controls << inc_btn

            controls << " "

            # Reset button
            reset_btn = Elements::Button.new(
              type: "button",
              class: "am-button am-button--warning am-button--soft am-button--sm",
              "data-action": "click->reset"
            )
            reset_btn << "Reset"
            controls << reset_btn
          end
        end

        container.render
      end
    end
  end
end
