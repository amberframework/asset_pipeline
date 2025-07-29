require "../base/container_element"

module Components
  module Elements
    # Represents the <pre> element - preformatted text
    class Pre < ContainerElement
      def initialize(**attrs)
        super("pre", **attrs)
      end
      
      # Pre elements preserve whitespace, so don't escape spaces/newlines in content
      protected def render_children : String
        @children.map do |child|
          case child
          when HTMLElement
            child.render
          when String
            # Still escape HTML entities but preserve whitespace
            child.gsub('&', "&amp;")
                 .gsub('<', "&lt;")
                 .gsub('>', "&gt;")
                 .gsub('"', "&quot;")
                 .gsub('\'', "&#39;")
          else
            child.to_s
          end
        end.join
      end
    end
  end
end