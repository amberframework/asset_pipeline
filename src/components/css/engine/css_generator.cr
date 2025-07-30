require "./css_rule"
require "./css_parser"
require "../class_registry"
require "../config/css_config"

module Components
  module CSS
    module Engine
      # Generates CSS from utility classes
      class Generator
        @config : Config
        @rules : Array(Rule)
        @registry : ClassRegistry
        
        def initialize(@config : Config)
          @rules = [] of Rule
          @registry = ClassRegistry.instance
        end
        
        # Generate CSS for all used classes
        def generate : String
          # Clear existing rules
          @rules.clear
          
          # Generate rules for each used class
          @registry.used_classes.each do |class_name|
            if rule = generate_rule_for_class(class_name)
              @rules << rule
            end
          end
          
          # Sort rules by priority and render
          render_rules
        end
        
        # Generate CSS for specific classes
        def generate_for_classes(classes : Array(String)) : String
          @rules.clear
          
          classes.each do |class_name|
            if rule = generate_rule_for_class(class_name)
              @rules << rule
            end
          end
          
          render_rules
        end
        
        # Generate a rule for a single class
        private def generate_rule_for_class(class_name : String) : Rule?
          # Extract modifiers (hover:, sm:, etc.)
          result = Parser.extract_modifiers(class_name)
          modifiers = result[:modifiers]
          base_class = result[:base]
          
          # Parse the base utility
          declarations = Parser.parse_utility(base_class, @config)
          return nil unless declarations
          
          # Create the rule
          rule = Rule.new(".#{CSS.escape(base_class)}")
          declarations.each do |property, value|
            rule.add_declaration(property, value)
          end
          
          # Apply modifiers
          modifiers.each do |modifier|
            case modifier
            # Pseudo classes
            when "hover", "focus", "active", "disabled", "visited"
              rule.with_pseudo(modifier)
              
            # Dark mode
            when "dark"
              rule.with_media("(prefers-color-scheme: dark)")
              
            # Responsive breakpoints
            when "sm", "md", "lg", "xl", "2xl"
              if breakpoint = @config.screens[modifier]?
                rule.with_media("(min-width: #{breakpoint})")
              end
              
            # Print
            when "print"
              rule.with_media("print")
            end
          end
          
          rule
        end
        
        # Render all rules to CSS
        private def render_rules : String
          # Group rules by media query
          grouped = @rules.group_by(&.media_query)
          
          String.build do |str|
            # Reset and base styles
            str << generate_reset
            str << "\n\n"
            
            # Regular rules (no media query)
            if regular_rules = grouped[nil]?
              regular_rules.sort_by(&.priority).each do |rule|
                str << rule.render
                str << "\n"
              end
            end
            
            # Media query rules
            grouped.each do |media_query, rules|
              next if media_query.nil?
              
              str << "\n"
              str << "@media #{media_query} {\n"
              
              rules.sort_by(&.priority).each do |rule|
                # Create a new rule without media query for rendering
                inner_rule = Rule.new(rule.selector, rule.priority)
                rule.declarations.each do |prop, val|
                  inner_rule.add_declaration(prop, val)
                end
                if pseudo = rule.pseudo_class
                  inner_rule.with_pseudo(pseudo)
                end
                
                str << "  " << inner_rule.render.gsub("\n", "\n  ")
                str << "\n"
              end
              
              str << "}\n"
            end
          end
        end
        
        # Generate CSS reset
        private def generate_reset : String
          <<-CSS
          /* CSS Reset */
          *, ::before, ::after {
            box-sizing: border-box;
            border-width: 0;
            border-style: solid;
            border-color: currentColor;
          }
          
          html {
            line-height: 1.5;
            -webkit-text-size-adjust: 100%;
            -moz-tab-size: 4;
            tab-size: 4;
            font-family: #{@config.fonts["sans"]};
          }
          
          body {
            margin: 0;
            line-height: inherit;
          }
          
          hr {
            height: 0;
            color: inherit;
            border-top-width: 1px;
          }
          
          abbr:where([title]) {
            text-decoration: underline dotted;
          }
          
          h1, h2, h3, h4, h5, h6 {
            font-size: inherit;
            font-weight: inherit;
          }
          
          a {
            color: inherit;
            text-decoration: inherit;
          }
          
          b, strong {
            font-weight: bolder;
          }
          
          code, kbd, samp, pre {
            font-family: #{@config.fonts["mono"]};
            font-size: 1em;
          }
          
          small {
            font-size: 80%;
          }
          
          sub, sup {
            font-size: 75%;
            line-height: 0;
            position: relative;
            vertical-align: baseline;
          }
          
          sub {
            bottom: -0.25em;
          }
          
          sup {
            top: -0.5em;
          }
          
          table {
            text-indent: 0;
            border-color: inherit;
            border-collapse: collapse;
          }
          
          button, input, optgroup, select, textarea {
            font-family: inherit;
            font-size: 100%;
            font-weight: inherit;
            line-height: inherit;
            color: inherit;
            margin: 0;
            padding: 0;
          }
          
          button, select {
            text-transform: none;
          }
          
          button, [type='button'], [type='reset'], [type='submit'] {
            -webkit-appearance: button;
            background-color: transparent;
            background-image: none;
          }
          
          :-moz-focusring {
            outline: auto;
          }
          
          :-moz-ui-invalid {
            box-shadow: none;
          }
          
          progress {
            vertical-align: baseline;
          }
          
          ::-webkit-inner-spin-button, ::-webkit-outer-spin-button {
            height: auto;
          }
          
          [type='search'] {
            -webkit-appearance: textfield;
            outline-offset: -2px;
          }
          
          ::-webkit-search-decoration {
            -webkit-appearance: none;
          }
          
          ::-webkit-file-upload-button {
            -webkit-appearance: button;
            font: inherit;
          }
          
          summary {
            display: list-item;
          }
          
          blockquote, dl, dd, h1, h2, h3, h4, h5, h6, hr, figure, p, pre {
            margin: 0;
          }
          
          fieldset {
            margin: 0;
            padding: 0;
          }
          
          legend {
            padding: 0;
          }
          
          ol, ul, menu {
            list-style: none;
            margin: 0;
            padding: 0;
          }
          
          textarea {
            resize: vertical;
          }
          
          input::placeholder, textarea::placeholder {
            opacity: 1;
            color: #9ca3af;
          }
          
          button, [role="button"] {
            cursor: pointer;
          }
          
          :disabled {
            cursor: default;
          }
          
          img, svg, video, canvas, audio, iframe, embed, object {
            display: block;
            vertical-align: middle;
          }
          
          img, video {
            max-width: 100%;
            height: auto;
          }
          
          [hidden] {
            display: none;
          }
          CSS
        end
      end
      
      module CSS
        # Escape CSS identifiers
        def self.escape(str : String) : String
          str.gsub(/[^\w-]/) do |char|
            "\\#{char}"
          end
        end
      end
    end
  end
end