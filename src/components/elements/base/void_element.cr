require "./html_element"

module Components
  module Elements
    # Base class for void (self-closing) HTML elements
    # These elements cannot have children and don't have closing tags
    abstract class VoidElement < HTMLElement
      def initialize(tag_name : String, **attrs)
        super(tag_name, **attrs)
      end
      
      # Void elements cannot have children
      def <<(child : HTMLElement | String) : self
        raise ArgumentError.new("Void element <#{@tag_name}> cannot have children")
      end
      
      # Void elements cannot have children
      def add_child(child : HTMLElement | String) : self
        raise ArgumentError.new("Void element <#{@tag_name}> cannot have children")
      end
      
      # Override to indicate this is a void element
      def void_element? : Bool
        true
      end
      
      # Override to indicate void elements cannot have children
      def can_have_children? : Bool
        false
      end
      
      # Render the void element as a self-closing tag
      def render : String
        "<#{@tag_name}#{render_attributes}>"
      end
    end
  end
end