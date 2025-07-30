require "./asset"

module Components
  module Assets
    # JavaScript asset with processing capabilities
    class JSAsset < Asset
      # JS-specific options
      property minify : Bool = true
      property source_map : Bool = false
      property target : String = "es2020"
      
      def content_type : String
        "application/javascript"
      end
      
      # Process JavaScript content
      def process : String
        processed = @content
        
        # Basic minification in production
        if minify
          processed = minify_js(processed)
        end
        
        processed
      end
      
      # Basic JavaScript minification
      private def minify_js(js : String) : String
        js
          .gsub(/\/\/.*$/, "")        # Remove single-line comments
          .gsub(/\/\*[\s\S]*?\*\//, "") # Remove multi-line comments
          .gsub(/\s+/, " ")           # Collapse whitespace
          .gsub(/\s*([{}();,:])\s*/, "\\1") # Remove spaces around operators
          .strip
      end
      
      # Wrap in IIFE (Immediately Invoked Function Expression)
      def wrap_iife : String
        "(function(){#{processed_content}})();"
      end
      
      # Add to global scope
      def add_to_global(name : String) : String
        "window.#{name} = #{processed_content};"
      end
    end
  end
end