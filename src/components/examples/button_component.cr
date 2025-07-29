require "../base/stateless_component"
require "../elements/forms/form_controls"

module Components
  module Examples
    # A reusable button component
    class ButtonComponent < StatelessComponent
      def render_content : String
        # Extract component props
        label = @attributes["label"]? || "Button"
        type = @attributes["type"]? || "button"
        variant = @attributes["variant"]? || "primary"
        size = @attributes["size"]? || "medium"
        disabled = @attributes["disabled"]? == "true"
        
        # Build button with appropriate classes
        button_classes = ["btn", "btn-#{variant}", "btn-#{size}"]
        button_classes << "disabled" if disabled
        
        # Create button element
        button = Elements::Button.new(
          type: type,
          class: button_classes.join(" "),
          disabled: disabled ? "true" : nil
        )
        
        # Add icon if specified
        if icon = @attributes["icon"]?
          span = Elements::Span.new(class: "btn-icon")
          span << icon
          button << span
          button << " "
        end
        
        # Add label
        button << label
        
        # Add children if any
        unless @children.empty?
          button << " "
          @children.each do |child|
            case child
            when Component
              button << child.render
            when Elements::HTMLElement
              button << child
            when String
              button << child
            end
          end
        end
        
        button.render
      end
    end
  end
end