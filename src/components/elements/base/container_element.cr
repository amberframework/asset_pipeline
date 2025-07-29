require "./html_element"

module Components
  module Elements
    # Base class for container HTML elements that can have children
    abstract class ContainerElement < HTMLElement
      def initialize(tag_name : String, **attrs)
        super(tag_name, **attrs)
      end
      
      # Add a child element or text content
      def <<(child : HTMLElement | String) : self
        @children << child
        self
      end
      
      # Add a child element or text content (alias for <<)
      def add_child(child : HTMLElement | String) : self
        self << child
      end
      
      # Add multiple children at once
      def add_children(*children : HTMLElement | String) : self
        children.each { |child| self << child }
        self
      end
      
      # Clear all children
      def clear : self
        @children.clear
        self
      end
      
      # Check if element has children
      def empty? : Bool
        @children.empty?
      end
      
      # Get the number of children
      def children_count : Int32
        @children.size
      end
      
      # Build content using a block
      def build(&block : self -> Nil) : self
        yield self
        self
      end
      
      # Render children as HTML
      protected def render_children : String
        @children.map do |child|
          case child
          when HTMLElement
            child.render
          when String
            escape_html(child)
          else
            child.to_s
          end
        end.join
      end
      
      # Render the complete element with opening tag, children, and closing tag
      def render : String
        if @children.empty?
          # Self-closing syntax for empty container elements
          "<#{@tag_name}#{render_attributes}></#{@tag_name}>"
        else
          "<#{@tag_name}#{render_attributes}>#{render_children}</#{@tag_name}>"
        end
      end
      
    end
  end
end