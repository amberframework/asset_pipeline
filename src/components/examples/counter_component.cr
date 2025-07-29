require "../base/stateful_component"
require "../elements/grouping/div"
require "../elements/grouping/span"
require "../elements/forms/form_controls"

module Components
  module Examples
    # A stateful counter component
    class CounterComponent < StatefulComponent
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
        container = Elements::Div.new(class: "counter-component").build do |c|
          # Display
          c << Elements::Div.new(class: "counter-display").build do |display|
            label_span = Elements::Span.new(class: "counter-label")
            label_span << "Count: "
            display << label_span
            
            value_span = Elements::Span.new(class: "counter-value")
            value_span << count.to_s
            display << value_span
          end
          
          # Controls
          c << Elements::Div.new(class: "counter-controls").build do |controls|
            # Decrement button
            dec_btn = Elements::Button.new(
              type: "button",
              class: "btn btn-secondary",
              "data-action": "click->decrement"
            )
            dec_btn << "-"
            controls << dec_btn
            
            controls << " "
            
            # Increment button
            inc_btn = Elements::Button.new(
              type: "button",
              class: "btn btn-primary",
              "data-action": "click->increment"
            )
            inc_btn << "+"
            controls << inc_btn
            
            controls << " "
            
            # Reset button
            reset_btn = Elements::Button.new(
              type: "button",
              class: "btn btn-warning",
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