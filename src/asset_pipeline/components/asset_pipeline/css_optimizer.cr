require "../css_registry"

module AssetPipeline
  module Components
    module AssetPipeline
      # CSSOptimizer provides CSS tree-shaking and optimization
      # based on component usage tracked by CSSRegistry
      class CSSOptimizer
        property css_registry : CSSRegistry
        property base_css_path : String?
        property output_path : String
        property minify : Bool
        
        def initialize(@output_path : String = "public/assets", 
                       @base_css_path : String? = nil, 
                       @minify : Bool = false)
          @css_registry = CSSRegistry.instance
        end
        
        # Generate optimized CSS containing only used classes
        def generate_optimized_css : String
          used_classes = @css_registry.all_used_classes
          component_classes = @css_registry.component_classes
          
          css_rules = [] of String
          
          # Add base component framework styles
          css_rules << generate_component_framework_css
          
          # Generate CSS for each used class
          used_classes.each do |css_class|
            if rule = generate_css_rule_for_class(css_class)
              css_rules << rule
            end
          end
          
          # Add component-specific styles
          component_classes.each do |component_name, classes|
            css_rules << generate_component_specific_css(component_name, classes.to_a)
          end
          
          # Combine and optionally minify
          combined_css = css_rules.join("\n")
          @minify ? minify_css(combined_css) : combined_css
        end
        
        # Write optimized CSS to file
        def write_optimized_css(filename : String = "components-optimized.css") : String
          css_content = generate_optimized_css
          output_file = File.join(@output_path, filename)
          
          Dir.mkdir_p(File.dirname(output_file))
          File.write(output_file, css_content)
          
          output_file
        end
        
        # Analyze CSS usage and provide optimization report
        def generate_optimization_report : Hash(String, String | Int32 | Array(String))
          used_classes = @css_registry.all_used_classes
          component_classes = @css_registry.component_classes
          usage_count = @css_registry.class_usage_count
          
          # Calculate savings potential
          total_possible_classes = get_all_possible_css_classes
          unused_classes = total_possible_classes - used_classes
          
          {
            "total_components" => component_classes.size,
            "used_css_classes" => used_classes.size,
            "unused_css_classes" => unused_classes.size,
            "optimization_ratio" => calculate_optimization_ratio(used_classes.size, total_possible_classes.size),
            "most_used_classes" => get_most_used_classes(usage_count, 10),
            "unused_classes_sample" => unused_classes.first(20),
            "generated_css_size" => generate_optimized_css.bytesize,
            "components_tracked" => component_classes.keys
          }
        end
        
        # Purge CSS file based on component usage
        def purge_css_file(input_file : String, output_file : String) : String
          return "" unless File.exists?(input_file)
          
          css_content = File.read(input_file)
          used_classes = @css_registry.all_used_classes
          
          # Simple CSS purging - remove unused class rules
          purged_css = purge_unused_css_rules(css_content, used_classes)
          
          Dir.mkdir_p(File.dirname(output_file))
          File.write(output_file, purged_css)
          
          output_file
        end
        
        # Generate critical CSS for above-the-fold content
        def generate_critical_css(priority_components : Array(String) = [] of String) : String
          critical_classes = [] of String
          
          # Get classes from priority components
          priority_components.each do |component_name|
            if classes = @css_registry.component_classes[component_name]?
              critical_classes.concat(classes)
            end
          end
          
          # Add base framework classes
          critical_classes.concat(get_critical_framework_classes)
          
          # Generate CSS only for critical classes
          css_rules = [] of String
          css_rules << generate_component_framework_css(critical_only: true)
          
          critical_classes.uniq.each do |css_class|
            if rule = generate_css_rule_for_class(css_class)
              css_rules << rule
            end
          end
          
          css_rules.join("\n")
        end
        
        # Write critical CSS to file
        def write_critical_css(priority_components : Array(String) = [] of String, 
                              filename : String = "critical.css") : String
          css_content = generate_critical_css(priority_components)
          output_file = File.join(@output_path, filename)
          
          Dir.mkdir_p(File.dirname(output_file))
          File.write(output_file, css_content)
          
          output_file
        end
        
        # Integrate with external CSS processing tools
        def integrate_with_postcss(postcss_config : Hash(String, String)) : String
          optimized_css = generate_optimized_css
          
          # Write temporary file for PostCSS processing
          temp_file = File.join(@output_path, "temp-components.css")
          File.write(temp_file, optimized_css)
          
          # Would integrate with PostCSS here in a real implementation
          # For now, just return the optimized CSS
          File.delete(temp_file)
          optimized_css
        end
        
        private def generate_component_framework_css(critical_only : Bool = false) : String
          if critical_only
            <<-CSS
              /* Critical Component Framework Styles */
              [data-component] { position: relative; }
              .btn { display: inline-block; }
            CSS
          else
            <<-CSS
              /* Component Framework Styles */
              [data-component] {
                position: relative;
              }
              
              [data-component].component-loading {
                opacity: 0.7;
                pointer-events: none;
              }
              
              [data-component].component-error {
                border: 1px solid #ef4444;
                background-color: #fef2f2;
              }
              
              [data-component].component-disabled {
                opacity: 0.5;
                pointer-events: none;
              }
              
              /* Animation utilities */
              .component-fade-in {
                animation: componentFadeIn 0.2s ease-in-out;
              }
              
              @keyframes componentFadeIn {
                from { opacity: 0; }
                to { opacity: 1; }
              }
            CSS
          end
        end
        
        private def generate_css_rule_for_class(css_class : String) : String?
          case css_class
          when .starts_with?("btn")
            generate_button_css_rule(css_class)
          when .starts_with?("counter"), .starts_with?("count")
            generate_counter_css_rule(css_class)
          when .starts_with?("toggle")
            generate_toggle_css_rule(css_class)
          when .starts_with?("dropdown")
            generate_dropdown_css_rule(css_class)
          when .starts_with?("form")
            generate_form_css_rule(css_class)
          when .starts_with?("card")
            generate_card_css_rule(css_class)
          when .starts_with?("alert")
            generate_alert_css_rule(css_class)
          else
            generate_utility_css_rule(css_class)
          end
        end
        
        private def generate_component_specific_css(component_name : String, classes : Array(String)) : String
          <<-CSS
            /* #{component_name} Component Styles */
            [data-component="#{component_name.downcase}"] {
              /* Component-specific base styles */
            }
          CSS
        end
        
        private def generate_button_css_rule(css_class : String) : String
          case css_class
          when "btn"
            ".btn { padding: 0.5rem 1rem; border: 1px solid #d1d5db; border-radius: 0.375rem; background-color: #f9fafb; cursor: pointer; text-decoration: none; display: inline-block; font-weight: 500; text-align: center; transition: all 0.2s; }"
          when "btn-primary"
            ".btn-primary { background-color: #3b82f6; color: white; border-color: #2563eb; } .btn-primary:hover { background-color: #2563eb; }"
          when "btn-secondary"
            ".btn-secondary { background-color: #6b7280; color: white; border-color: #4b5563; } .btn-secondary:hover { background-color: #4b5563; }"
          when "btn-danger"
            ".btn-danger { background-color: #ef4444; color: white; border-color: #dc2626; } .btn-danger:hover { background-color: #dc2626; }"
          when "btn-success"
            ".btn-success { background-color: #10b981; color: white; border-color: #059669; } .btn-success:hover { background-color: #059669; }"
          when "btn-small"
            ".btn-small { padding: 0.25rem 0.5rem; font-size: 0.875rem; }"
          when "btn-large"
            ".btn-large { padding: 0.75rem 1.5rem; font-size: 1.125rem; }"
          when "btn-disabled"
            ".btn-disabled, .btn:disabled { opacity: 0.5; cursor: not-allowed; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_counter_css_rule(css_class : String) : String
          case css_class
          when "counter"
            ".counter { display: inline-flex; align-items: center; gap: 0.5rem; }"
          when "count-display"
            ".count-display { min-width: 2rem; text-align: center; font-weight: bold; padding: 0.25rem 0.5rem; border: 1px solid #d1d5db; border-radius: 0.25rem; }"
          when "counter-controls"
            ".counter-controls { display: flex; gap: 0.25rem; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_toggle_css_rule(css_class : String) : String
          case css_class
          when "toggle"
            ".toggle { display: inline-flex; align-items: center; }"
          when "toggle-button"
            ".toggle-button { width: 3rem; height: 1.5rem; border-radius: 9999px; background-color: #d1d5db; position: relative; cursor: pointer; transition: background-color 0.2s; }"
          when "toggle-on"
            ".toggle-on { background-color: #3b82f6; }"
          when "toggle-thumb"
            ".toggle-thumb { width: 1.25rem; height: 1.25rem; background-color: white; border-radius: 50%; position: absolute; top: 0.125rem; left: 0.125rem; transition: transform 0.2s; } .toggle-on .toggle-thumb { transform: translateX(1.5rem); }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_dropdown_css_rule(css_class : String) : String
          case css_class
          when "dropdown"
            ".dropdown { position: relative; display: inline-block; }"
          when "dropdown-menu"
            ".dropdown-menu { position: absolute; background-color: white; border: 1px solid #d1d5db; border-radius: 0.375rem; box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1); display: none; min-width: 10rem; z-index: 10; }"
          when "dropdown-item"
            ".dropdown-item { padding: 0.5rem 1rem; cursor: pointer; } .dropdown-item:hover { background-color: #f3f4f6; }"
          when "dropdown-open"
            ".dropdown-open .dropdown-menu { display: block; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_form_css_rule(css_class : String) : String
          case css_class
          when "form-field"
            ".form-field { margin-bottom: 1rem; }"
          when "form-label"
            ".form-label { display: block; font-weight: 500; margin-bottom: 0.25rem; }"
          when "form-input"
            ".form-input { width: 100%; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 0.375rem; }"
          when "form-error"
            ".form-error { color: #ef4444; font-size: 0.875rem; margin-top: 0.25rem; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_card_css_rule(css_class : String) : String
          case css_class
          when "card"
            ".card { background-color: white; border: 1px solid #d1d5db; border-radius: 0.5rem; overflow: hidden; }"
          when "card-header"
            ".card-header { padding: 1rem; border-bottom: 1px solid #d1d5db; }"
          when "card-body"
            ".card-body { padding: 1rem; }"
          when "card-footer"
            ".card-footer { padding: 1rem; border-top: 1px solid #d1d5db; background-color: #f9fafb; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_alert_css_rule(css_class : String) : String
          case css_class
          when "alert"
            ".alert { padding: 1rem; border-radius: 0.375rem; margin-bottom: 1rem; }"
          when "alert-success"
            ".alert-success { background-color: #d1fae5; color: #065f46; border: 1px solid #a7f3d0; }"
          when "alert-error"
            ".alert-error { background-color: #fee2e2; color: #991b1b; border: 1px solid #fca5a5; }"
          when "alert-warning"
            ".alert-warning { background-color: #fef3c7; color: #92400e; border: 1px solid #fcd34d; }"
          when "alert-info"
            ".alert-info { background-color: #dbeafe; color: #1e40af; border: 1px solid #93c5fd; }"
          else
            ".#{css_class} { /* Generated rule for #{css_class} */ }"
          end
        end
        
        private def generate_utility_css_rule(css_class : String) : String?
          case css_class
          when .starts_with?("text-")
            generate_text_utility(css_class)
          when .starts_with?("bg-")
            generate_background_utility(css_class)
          when .starts_with?("border-")
            generate_border_utility(css_class)
          when .starts_with?("p-"), .starts_with?("m-")
            generate_spacing_utility(css_class)
          else
            nil
          end
        end
        
        private def generate_text_utility(css_class : String) : String?
          case css_class
          when "text-left"
            ".text-left { text-align: left; }"
          when "text-center"
            ".text-center { text-align: center; }"
          when "text-right"
            ".text-right { text-align: right; }"
          when "text-bold"
            ".text-bold { font-weight: bold; }"
          else
            nil
          end
        end
        
        private def generate_background_utility(css_class : String) : String?
          case css_class
          when "bg-gray"
            ".bg-gray { background-color: #f3f4f6; }"
          when "bg-blue"
            ".bg-blue { background-color: #3b82f6; }"
          when "bg-red"
            ".bg-red { background-color: #ef4444; }"
          else
            nil
          end
        end
        
        private def generate_border_utility(css_class : String) : String?
          case css_class
          when "border"
            ".border { border: 1px solid #d1d5db; }"
          when "border-rounded"
            ".border-rounded { border-radius: 0.375rem; }"
          else
            nil
          end
        end
        
        private def generate_spacing_utility(css_class : String) : String?
          case css_class
          when "p-1"
            ".p-1 { padding: 0.25rem; }"
          when "p-2"
            ".p-2 { padding: 0.5rem; }"
          when "m-1"
            ".m-1 { margin: 0.25rem; }"
          when "m-2"
            ".m-2 { margin: 0.5rem; }"
          else
            nil
          end
        end
        
        private def get_all_possible_css_classes : Array(String)
          # This would normally be read from a master CSS file or configuration
          # For now, return a reasonable set of classes
          %w[
            btn btn-primary btn-secondary btn-danger btn-success btn-small btn-large btn-disabled
            counter count-display counter-controls
            toggle toggle-button toggle-on toggle-thumb
            dropdown dropdown-menu dropdown-item dropdown-open
            form-field form-label form-input form-error
            card card-header card-body card-footer
            alert alert-success alert-error alert-warning alert-info
            text-left text-center text-right text-bold
            bg-gray bg-blue bg-red
            border border-rounded
            p-1 p-2 m-1 m-2
          ]
        end
        
        private def get_critical_framework_classes : Array(String)
          %w[btn counter toggle]
        end
        
        private def calculate_optimization_ratio(used : Int32, total : Int32) : String
          return "0%" if total == 0
          ratio = ((used.to_f / total.to_f) * 100).round(1)
          "#{ratio}%"
        end
        
        private def get_most_used_classes(usage_count : Hash(String, Int32), limit : Int32) : Array(String)
          usage_count.to_a.sort_by(&.[1]).reverse.first(limit).map(&.[0])
        end
        
        private def purge_unused_css_rules(css_content : String, used_classes : Array(String)) : String
          # Simple CSS purging implementation
          # In a real implementation, this would use a proper CSS parser
          lines = css_content.lines
          purged_lines = [] of String
          
          lines.each do |line|
            # Keep line if it contains a used class or is not a class rule
            if used_classes.any? { |cls| line.includes?(".#{cls}") } || !line.includes?(".")
              purged_lines << line
            end
          end
          
          purged_lines.join("\n")
        end
        
        private def minify_css(css : String) : String
          # Simple CSS minification
          css.gsub(/\s+/, " ")
             .gsub(/;\s*}/, "}")
             .gsub(/\s*{\s*/, "{")
             .gsub(/;\s*/, ";")
             .gsub(/,\s*/, ",")
             .strip
        end
      end
    end
  end
end 