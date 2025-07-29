module Components
  module Elements
    # Wrapper for raw HTML content that should not be escaped
    class RawHTML
      getter html : String
      
      def initialize(@html : String)
      end
      
      def to_s
        @html
      end
      
      def render
        @html
      end
    end
  end
end