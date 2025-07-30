require "../base/asset"

module Components
  module Assets
    # CSS asset with processing capabilities
    class CSSAsset < Asset
      # CSS-specific options
      property minify : Bool = true
      property source_map : Bool = false
      property autoprefixer : Bool = true
      
      def content_type : String
        "text/css"
      end
      
      # Process CSS content
      def process : String
        processed = @content
        
        # Remove comments in production
        if minify
          processed = remove_comments(processed)
          processed = minify_css(processed)
        end
        
        # Add vendor prefixes if enabled
        if autoprefixer
          processed = add_vendor_prefixes(processed)
        end
        
        processed
      end
      
      # Remove CSS comments
      private def remove_comments(css : String) : String
        # Remove /* */ comments
        css.gsub(/\/\*[\s\S]*?\*\//, "")
      end
      
      # Basic CSS minification
      private def minify_css(css : String) : String
        css
          .gsub(/\s+/, " ")           # Collapse whitespace
          .gsub(/\s*:\s*/, ":")       # Remove spaces around colons
          .gsub(/\s*;\s*/, ";")       # Remove spaces around semicolons
          .gsub(/\s*\{\s*/, "{")      # Remove spaces around opening braces
          .gsub(/\s*\}\s*/, "}")      # Remove spaces around closing braces
          .gsub(/\s*,\s*/, ",")       # Remove spaces around commas
          .gsub(/;\}/, "}")           # Remove last semicolon before closing brace
          .strip                      # Remove leading/trailing whitespace
      end
      
      # Add vendor prefixes for common properties
      private def add_vendor_prefixes(css : String) : String
        prefixes = {
          "transform" => ["-webkit-transform", "-ms-transform"],
          "transition" => ["-webkit-transition"],
          "animation" => ["-webkit-animation"],
          "flex" => ["-webkit-flex", "-ms-flex"],
          "user-select" => ["-webkit-user-select", "-moz-user-select", "-ms-user-select"],
          "appearance" => ["-webkit-appearance", "-moz-appearance"],
          "backdrop-filter" => ["-webkit-backdrop-filter"],
        }
        
        result = css
        
        prefixes.each do |property, vendor_props|
          # Match property declarations
          result = result.gsub(/([^-\w])#{property}\s*:/) do |match|
            prefix_match = $1
            value_match = match.split(":")[1]? || ""
            
            # Build prefixed versions
            prefixed = vendor_props.map { |vp| "#{prefix_match}#{vp}:#{value_match}" }.join(";")
            "#{prefixed};#{match}"
          end
        end
        
        result
      end
      
      # Merge multiple CSS assets
      def self.merge(assets : Array(CSSAsset)) : CSSAsset
        merged_content = assets.map(&.processed_content).join("\n")
        
        merged = new(content: merged_content)
        
        # Combine all dependencies
        assets.each do |asset|
          asset.dependencies.each { |dep| merged.add_dependency(dep) }
        end
        
        merged
      end
      
      # Extract critical CSS for above-the-fold content
      def extract_critical(selectors : Array(String)) : String
        rules = [] of String
        
        # Simple critical CSS extraction
        # In production, this would use a proper CSS parser
        processed_content.scan(/([^{}]+)\{([^}]+)\}/) do |match|
          selector = match[1].strip
          declarations = match[2]
          
          # Check if selector matches any critical selectors
          if selectors.any? { |cs| selector.includes?(cs) }
            rules << "#{selector}{#{declarations}}"
          end
        end
        
        rules.join
      end
      
      # Generate source map
      def generate_source_map : String?
        return nil unless source_map && source_path
        
        # Simplified source map generation
        # In production, use a proper source map library
        {
          "version" => 3,
          "sources" => [source_path],
          "names" => [] of String,
          "mappings" => "",
          "file" => output_filename
        }.to_json
      end
    end
  end
end