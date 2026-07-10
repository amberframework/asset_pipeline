require "./css_rule"
require "./css_parser"
require "../class_registry"
require "../config/css_config"
require "../component_css_registry"

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

          # Create the rule with full class name (Tailwind-style selector)
          rule = Rule.new(".#{CSS.escape(class_name)}")
          declarations.each do |property, value|
            rule.add_declaration(property, value)
          end

          # Apply modifiers
          modifiers.each do |modifier|
            case modifier
            # Pseudo classes
            when "hover", "focus", "active", "disabled", "visited"
              rule.with_pseudo(modifier)
              # Focus pseudo variants (WCAG 2.4.7)
            when "focus-visible"
              rule.with_pseudo("focus-visible")
            when "focus-within"
              rule.with_pseudo("focus-within")
              # Form validation pseudo classes (WCAG 1.3.1, 3.3.1)
            when "invalid"
              rule.with_pseudo("invalid")
            when "valid"
              rule.with_pseudo("valid")
            when "user-invalid"
              rule.with_pseudo("user-invalid")
            when "user-valid"
              rule.with_pseudo("user-valid")
              # Dark mode
            when "dark"
              rule.with_media("(prefers-color-scheme: dark)")
              # Motion preferences (WCAG 2.2.2, 2.3.1)
            when "motion-safe"
              rule.with_media("(prefers-reduced-motion: no-preference)")
            when "motion-reduce"
              rule.with_media("(prefers-reduced-motion: reduce)")
              # Responsive breakpoints
            when "sm", "md", "lg", "xl", "2xl"
              if breakpoint = @config.screens[modifier]?
                rule.with_media("(min-width: #{breakpoint})")
              end
              # Print
            when "print"
              rule.with_media("print")
              # Contrast preference (WCAG 1.4.3)
            when "contrast-more"
              rule.with_media("(prefers-contrast: more)")
              # Forced colors (WCAG 1.4.1)
            when "forced-colors"
              rule.with_media("(forced-colors: active)")
              # Pointer type (WCAG 2.5.8)
            when "pointer-coarse"
              rule.with_media("(pointer: coarse)")
            when "pointer-fine"
              rule.with_media("(pointer: fine)")
              # Container query modifiers.
              #
              # Supported syntaxes:
              #   @<bp>           -> anonymous container query at named bp
              #                      (e.g. `@md:flex` -> `@container (min-width: 768px)`)
              #   @<name>:<bp>    -> named container query at named bp
              #                      (e.g. `@card:md:flex-row` would arrive as
              #                      modifier "@card:md" producing
              #                      `@container card (min-width: 768px)`)
              #
              # The size lookup uses the `containers` map; if the bp segment
              # is not a known key the modifier is silently dropped so we
              # don't emit a broken @container header.
            when .starts_with?("@")
              raw = modifier.lchop("@")
              if raw.includes?(":")
                name, bp = raw.split(":", 2)
                if size = @config.containers[bp]?
                  rule.with_container("#{name} (min-width: #{size})")
                end
              elsif bp_size = @config.containers[raw]?
                rule.with_container("(min-width: #{bp_size})")
              end

              # Form state pseudo classes
            when "required"
              rule.with_pseudo("required")
            when "checked"
              rule.with_pseudo("checked")
            when "indeterminate"
              rule.with_pseudo("indeterminate")
            when "read-only"
              rule.with_pseudo("read-only")
            when "placeholder-shown"
              rule.with_pseudo("placeholder-shown")
              # Details/dialog open state
            when "open"
              rule.with_pseudo("open")
              # ARIA state variants (WCAG 1.3.1)
            when "aria-expanded"
              rule.with_attribute("aria-expanded", "true")
            when "aria-selected"
              rule.with_attribute("aria-selected", "true")
            when "aria-checked"
              rule.with_attribute("aria-checked", "true")
            when "aria-disabled"
              rule.with_attribute("aria-disabled", "true")
            when "aria-hidden"
              rule.with_attribute("aria-hidden", "true")
            when "aria-pressed"
              rule.with_attribute("aria-pressed", "true")
            when "aria-busy"
              rule.with_attribute("aria-busy", "true")
              # Inert (WCAG 2.1.2)
            when "inert"
              rule.with_complex_pseudo(":is([inert], [inert] *)")
            end
          end

          rule
        end

        # Render all rules to CSS with @layer structure
        private def render_rules : String
          # Group utility rules by media query, then by container query
          grouped_by_media = @rules.group_by(&.media_query)

          String.build do |str|
            # === Layer order declaration ===
            str << "@layer reset, tokens, base, components, utilities;\n\n"

            # === @layer reset ===
            str << "@layer reset {\n"
            str << generate_reset
            str << "\n}\n\n"

            # === @layer tokens ===
            str << "@layer tokens {\n"
            str << "  :root {\n"
            str << "    color-scheme: light dark;\n"
            @config.to_custom_properties.each_line do |line|
              str << "    " << line << "\n" unless line.empty?
            end
            str << "  }\n"
            dark_tokens = @config.to_dark_custom_properties
            unless dark_tokens.empty?
              light_tokens = @config.to_custom_properties
              str << "\n"
              str << "  @media (prefers-color-scheme: dark) {\n"
              str << "    :root {\n"
              dark_tokens.each_line do |line|
                str << "      " << line << "\n" unless line.empty?
              end
              str << "    }\n"
              str << "  }\n"
              str << "\n"
              str << "  [data-ap-theme=\"light\"] {\n"
              light_tokens.each_line do |line|
                str << "    " << line << "\n" unless line.empty?
              end
              str << "  }\n"
              str << "\n"
              str << "  [data-ap-theme=\"dark\"] {\n"
              dark_tokens.each_line do |line|
                str << "    " << line << "\n" unless line.empty?
              end
              str << "  }\n"
              # `[data-amber-theme=...]` aliases were removed in Phase 1 of the
              # cross-platform UI initiative; the canonical attribute selector
              # is `[data-ap-theme]` exclusively.
            end
            str << "}\n\n"

            # === @layer base ===
            str << "@layer base {\n"
            str << generate_accessibility_base
            str << "\n}\n\n"

            # === @layer components ===
            str << "@layer components {\n"
            component_css = collect_component_css
            unless component_css.empty?
              str << component_css
              str << "\n"
            end
            str << "}\n\n"

            # === @layer utilities ===
            str << "@layer utilities {\n"

            # --- Regular rules (no media query, no container query) ---
            if regular_rules = grouped_by_media[nil]?
              # Sub-group by container query
              grouped_by_container = regular_rules.group_by(&.container_query)

              # Rules with no container query
              if plain_rules = grouped_by_container[nil]?
                plain_rules.sort_by(&.priority).each do |rule|
                  inner = build_inner_rule(rule)
                  str << "  " << inner.render.gsub("\n", "\n  ")
                  str << "\n"
                end
              end

              # Rules grouped by container query
              grouped_by_container.each do |container_query, rules|
                next if container_query.nil?

                str << "\n"
                str << "  @container #{container_query} {\n"
                rules.sort_by(&.priority).each do |rule|
                  inner = build_inner_rule(rule, strip_container: true)
                  str << "    " << inner.render.gsub("\n", "\n    ")
                  str << "\n"
                end
                str << "  }\n"
              end
            end

            # --- Media query grouped rules ---
            grouped_by_media.each do |media_query, rules|
              next if media_query.nil?

              # Sub-group by container query
              grouped_by_container = rules.group_by(&.container_query)

              str << "\n"
              str << "  @media #{media_query} {\n"

              # Rules with no container query inside this media query
              if plain_rules = grouped_by_container[nil]?
                plain_rules.sort_by(&.priority).each do |rule|
                  inner = build_inner_rule(rule)
                  str << "    " << inner.render.gsub("\n", "\n    ")
                  str << "\n"
                end
              end

              # Rules with container queries inside this media query
              grouped_by_container.each do |container_query, cq_rules|
                next if container_query.nil?

                str << "\n"
                str << "    @container #{container_query} {\n"
                cq_rules.sort_by(&.priority).each do |rule|
                  inner = build_inner_rule(rule, strip_container: true)
                  str << "      " << inner.render.gsub("\n", "\n      ")
                  str << "\n"
                end
                str << "    }\n"
              end

              str << "  }\n"
            end

            str << "}\n"
          end
        end

        # Build an inner rule that copies ALL fields from the original rule,
        # excluding media_query (handled by outer grouping) and optionally
        # excluding container_query (when already inside a @container block).
        private def build_inner_rule(rule : Rule, strip_container : Bool = false) : Rule
          inner_rule = Rule.new(rule.selector, rule.priority)

          # Copy declarations
          rule.declarations.each do |prop, val|
            inner_rule.add_declaration(prop, val)
          end

          # Copy pseudo-class (simple or complex)
          if pseudo = rule.pseudo_class
            if pseudo.starts_with?(":")
              inner_rule.with_complex_pseudo(pseudo)
            else
              inner_rule.with_pseudo(pseudo)
            end
          end

          # Copy attribute selector
          if attr = rule.attribute_selector
            inner_rule.set_attribute_selector(attr)
          end

          # Copy container query only if not stripping it
          if !strip_container
            if cq = rule.container_query
              inner_rule.with_container(cq)
            end
          end

          # Do NOT copy media_query -- the outer block handles it

          inner_rule
        end

        # Generate base accessibility CSS (WCAG defaults)
        private def generate_accessibility_base : String
          <<-CSS
            /* WCAG 2.4.7: Focus Visible -- baseline keyboard focus ring */
            :focus-visible {
              outline: 2px solid var(--focus-ring-color, var(--ap-color-border-focus, oklch(0.488 0.243 264.376)));
              outline-offset: 2px;
            }

            body {
              background: var(--ap-color-surface-canvas);
              color: var(--ap-color-text-primary);
              font-family: var(--ap-font-sans);
              font-size: var(--ap-type-body-size);
              font-weight: var(--ap-type-body-weight);
              line-height: var(--ap-type-body-line-height);
              text-rendering: optimizeLegibility;
            }

            p {
              font-size: var(--ap-type-paragraph-size);
              line-height: var(--ap-type-paragraph-line-height);
            }

            a {
              color: var(--ap-color-text-link);
            }

            @keyframes ap-row-enter {
              from {
                opacity: 0;
                transform: translateY(var(--ap-motion-distance-subtle));
              }
              to {
                opacity: 1;
                transform: translateY(0);
              }
            }

            @keyframes ap-row-exit {
              from {
                opacity: 1;
                transform: translateY(0);
              }
              to {
                opacity: 0;
                transform: translateY(calc(var(--ap-motion-distance-subtle) * -1));
              }
            }

            @keyframes ap-section-reveal {
              from {
                opacity: 0;
                transform: translateY(0.75rem);
              }
              to {
                opacity: 1;
                transform: translateY(0);
              }
            }

            /* WCAG 2.2.2 / 2.3.1: Reduced Motion -- global animation kill switch */
            @media (prefers-reduced-motion: reduce) {
              *,
              ::before,
              ::after {
                animation-duration: 0.01ms !important;
                animation-iteration-count: 1 !important;
                transition-duration: 0.01ms !important;
                scroll-behavior: auto !important;
              }
            }

            /* WCAG 1.4.1 / 1.4.11: Forced Colors -- system focus ring */
            @media (forced-colors: active) {
              :focus-visible {
                outline: 2px solid Highlight;
                outline-offset: 2px;
              }
            }

            /* Safari list semantics restoration */
            [role="list"] {
              list-style: none;
            }
          CSS
        end

        # Collect component CSS from all registered components.
        # Returns the raw CSS string to be placed inside @layer components.
        private def collect_component_css : String
          Components::CSS::ComponentCSSRegistry.instance.all_css
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
