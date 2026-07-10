require "../base/stateless_component"

module Components
  module DesignSystem
    abstract class PrimitiveComponent < StatelessComponent
      protected def root_classes(base : String, modifiers : Array(String) = [] of String) : String
        classes = [base]
        modifiers.each do |modifier|
          next if modifier.empty?
          classes << "#{base}--#{modifier}"
        end

        if extra = @attributes["class"]?
          classes.concat(extra.split(/\s+/).reject(&.empty?))
        end

        classes.join(" ")
      end

      protected def heading_tag(value : String?, fallback : String = "2") : String
        case value || fallback
        when "1" then "h1"
        when "2" then "h2"
        when "3" then "h3"
        when "4" then "h4"
        when "5" then "h5"
        when "6" then "h6"
        else          "h2"
        end
      end

      protected def bool_attr?(name : String) : Bool
        @attributes[name]? == "true"
      end

      protected def escaped(value : String) : String
        escape_html(value)
      end

      protected def render_data_aria_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class PageShell < PrimitiveComponent
      component_css <<-CSS
      .am-skip-link {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-focus);
        border-radius: var(--ap-radius-control);
        box-shadow: var(--ap-elevation-overlay);
        color: var(--ap-color-text-primary);
        left: 1rem;
        padding: 0.625rem 0.875rem;
        position: fixed;
        top: 1rem;
        transform: translateY(-150%);
        transition: transform var(--ap-motion-duration-fast) var(--ap-motion-ease-standard);
        z-index: 1000;
      }

      .am-skip-link:focus,
      .am-skip-link:focus-visible {
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 3px;
        transform: translateY(0);
      }

      .am-page-shell {
        background: var(--ap-color-surface-canvas);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: clamp(1rem, 2vw, 1.5rem);
        min-height: 100%;
      }

      .am-page-shell__header,
      .am-page-shell__main {
        margin-inline: auto;
        max-width: var(--am-page-shell-max-width, 72rem);
        width: min(100% - 2rem, var(--am-page-shell-max-width, 72rem));
      }

      .am-page-shell__header {
        display: grid;
        gap: 0.5rem;
        padding-block-start: clamp(1.25rem, 3vw, 2rem);
      }

      .am-page-shell__title {
        font-size: clamp(1.75rem, 4vw, 2.75rem);
        font-weight: var(--ap-type-heading-weight);
        letter-spacing: 0;
        line-height: 1.08;
        margin: 0;
      }

      .am-page-shell__subtitle {
        color: var(--ap-color-text-secondary);
        font-size: 1rem;
        line-height: 1.55;
        margin: 0;
        max-width: 64ch;
      }

      .am-page-shell__main {
        display: grid;
        gap: clamp(1rem, 2vw, 1.5rem);
        padding-block-end: clamp(1.5rem, 4vw, 3rem);
      }

      .am-page-shell__main:focus {
        outline: none;
      }

      @media (prefers-reduced-motion: reduce) {
        .am-skip-link {
          transition-duration: 0.01ms;
        }
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || component_id
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        label = @attributes["label"]?
        main_id = @attributes["main_id"]? || "#{id}-main"
        title_id = @attributes["title_id"]? || "#{id}-title"
        skip_label = @attributes["skip_label"]? || "Skip to content"

        String.build do |io|
          io << %(<div class="#{root_classes("am-page-shell")}" id="#{escaped(id)}" data-component="page-shell">)
          io << %(<a class="am-skip-link" href="##{escaped(main_id)}">#{escaped(skip_label)}</a>)

          if title || subtitle
            io << %(<header class="am-page-shell__header">)
            if title
              io << %(<h1 class="am-page-shell__title" id="#{escaped(title_id)}">#{escaped(title)}</h1>)
            end
            if subtitle
              io << %(<p class="am-page-shell__subtitle">#{escaped(subtitle)}</p>)
            end
            io << "</header>"
          end

          io << %(<main class="am-page-shell__main" id="#{escaped(main_id)}" tabindex="-1")
          if title
            io << %( aria-labelledby="#{escaped(title_id)}")
          elsif label
            io << %( aria-label="#{escaped(label)}")
          end
          io << ">"
          io << render_children
          io << "</main></div>"
        end
      end
    end

    class LandingHero < PrimitiveComponent
      struct Action
        getter label : String
        getter href : String?
        getter tone : String
        getter emphasis : String
        getter size : String
        getter type : String
        getter external : Bool
        getter target : String?
        getter rel : String?

        def initialize(@label : String,
                       @href : String? = nil,
                       @tone : String = "brand",
                       @emphasis : String = "solid",
                       @size : String = "md",
                       @type : String = "button",
                       @external : Bool = false,
                       @target : String? = nil,
                       @rel : String? = nil)
        end
      end

      @kicker : String
      @title : String
      @body : String
      @actions : Array(Action)
      @toolbar_html : String
      @toolbar_label : String
      @toolbar_prefix : String
      @aside_html : String

      def initialize(*,
                     kicker : String = "",
                     title : String,
                     body : String? = nil,
                     copy : String? = nil,
                     actions : Array(Action) = [] of Action,
                     toolbar_html : String = "",
                     toolbar_label : String = "Theme preview",
                     toolbar_prefix : String = "Theme",
                     aside_html : String = "",
                     **attrs)
        super(**attrs)
        raise ArgumentError.new("LandingHero requires a non-empty title") if title.strip.empty?

        @kicker = kicker
        @title = title
        @body = body || copy || ""
        @actions = actions
        @toolbar_html = toolbar_html
        @toolbar_label = toolbar_label
        @toolbar_prefix = toolbar_prefix
        @aside_html = aside_html
      end

      def render_content : String
        compatibility = @attributes["compatibility_markup"]? == "demo"

        String.build do |io|
          io << %(<header class="#{root_classes("am-demo-hero")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          io << %( data-component="landing-hero") unless compatibility
          if label = @attributes["label"]? || @attributes["aria_label"]? || @attributes["aria-label"]?
            io << %( aria-label="#{escaped(label)}")
          end
          render_landing_hero_passthrough_attributes(io) unless compatibility
          io << ">"
          render_landing_hero_body(io)
          io << "\n</header>"
        end
      end

      private def render_landing_hero_body(io : IO) : Nil
        io << "\n  <div>"
        io << "\n    <div class=\"am-kicker\">#{escaped(@kicker)}</div>" unless @kicker.empty?
        io << "\n    <h1 class=\"am-demo-title\">#{escaped(@title)}</h1>" unless @title.empty?
        io << "\n    <p class=\"am-demo-copy\">#{escaped(@body)}</p>" unless @body.empty?
        unless @actions.empty?
          io << "\n    <div class=\"am-demo-actions\">"
          @actions.each do |action|
            io << "\n      #{render_landing_hero_action(action)}"
          end
          io << "\n    </div>"
        end
        unless @toolbar_html.empty?
          io << "\n    <div class=\"am-demo-toolbar\" role=\"group\" aria-label=\"#{escaped(@toolbar_label)}\">"
          io << "\n      <span class=\"am-demo-subtle\">#{escaped(@toolbar_prefix)}</span>" unless @toolbar_prefix.empty?
          io << "\n      #{@toolbar_html}"
          io << "\n    </div>"
        end
        io << "\n  </div>"
        io << "\n  #{@aside_html}" unless @aside_html.empty?
      end

      private def render_landing_hero_action(action : Action) : String
        classes = "am-button am-button--#{escaped(action.tone)} am-button--#{escaped(action.emphasis)} am-button--#{escaped(action.size)}"
        if href = action.href
          target = action.target || (action.external ? "_blank" : nil)
          rel = action.rel || (action.external ? "noopener noreferrer" : nil)

          String.build do |io|
            io << %(<a class="#{classes}" href="#{escaped(href)}")
            io << %( target="#{escaped(target)}") if target
            io << %( rel="#{escaped(rel)}") if rel
            io << ">#{escaped(action.label)}</a>"
          end
        else
          %(<button type="#{escaped(action.type)}" class="#{classes}" data-state="default" data-tone="#{escaped(action.tone)}" data-emphasis="#{escaped(action.emphasis)}">#{escaped(action.label)}</button>)
        end
      end

      private def render_landing_hero_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if {"id", "class", "compatibility_markup", "label", "aria_label", "aria-label", "data-component"}.includes?(name)

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class OrderSummary < PrimitiveComponent
      struct AddOn
        getter label : String
        getter value : String
        getter checked : Bool

        def initialize(@label : String, @value : String, @checked : Bool = false)
        end
      end

      @label : String
      @seat_label : String
      @seat_id : String
      @seat_min : String
      @seat_max : String
      @seat_value : String
      @seat_hint_suffix : String
      @add_ons : Array(AddOn)
      @total_label : String
      @total : String
      @note : String
      @seat_price : String?
      @billing : String
      @annual_factor : String?
      @currency : String
      @period : String
      @annual_note : String?
      @monthly_note : String?

      def initialize(*,
                     label : String = "Order summary",
                     seat_label : String = "Seats",
                     seat_id : String = "order-seats",
                     seat_min : String = "1",
                     seat_max : String = "40",
                     seat_value : String = "1",
                     seat_hint_suffix : String = "seats selected",
                     add_ons : Array(AddOn) = [] of AddOn,
                     total_label : String = "Total",
                     total : String = "",
                     note : String = "",
                     seat_price : String? = nil,
                     billing : String = "monthly",
                     annual_factor : String? = nil,
                     currency : String = "$",
                     period : String = "",
                     annual_note : String? = nil,
                     monthly_note : String? = nil,
                     **attrs)
        super(**attrs)
        @label = label
        @seat_label = seat_label
        @seat_id = seat_id
        @seat_min = seat_min
        @seat_max = seat_max
        @seat_value = seat_value
        @seat_hint_suffix = seat_hint_suffix
        @add_ons = add_ons
        @total_label = total_label
        @total = total
        @note = note
        @seat_price = seat_price
        @billing = billing
        @annual_factor = annual_factor
        @currency = currency
        @period = period
        @annual_note = annual_note
        @monthly_note = monthly_note
      end

      def render_content : String
        compatibility = @attributes["compatibility_markup"]? == "demo"

        String.build do |io|
          io << %(<aside class="#{root_classes("am-summary")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          if compatibility
            io << " data-amber-pricing data-ap-pricing"
          else
            io << %( data-component="order-summary")
            if dynamic_pricing?
              io << " data-ap-pricing"
              io << %( data-ap-pricing-seat-price="#{escaped(@seat_price.not_nil!)}")
              io << %( data-ap-pricing-billing="#{escaped(@billing)}")
              io << %( data-ap-pricing-currency="#{escaped(@currency)}")
              io << %( data-ap-pricing-period="#{escaped(@period)}")
              io << %( data-ap-pricing-annual-factor="#{escaped(@annual_factor.not_nil!)}") if @annual_factor
              io << %( data-ap-pricing-annual-note="#{escaped(@annual_note.not_nil!)}") if @annual_note
              io << %( data-ap-pricing-monthly-note="#{escaped(@monthly_note.not_nil!)}") if @monthly_note
            end
            render_order_summary_passthrough_attributes(io)
          end
          io << %( aria-label="#{escaped(@label)}">)
          io << "\n  <strong>#{escaped(@label)}</strong>"
          io << "\n  #{render_order_summary_seat_field(compatibility)}"
          unless @add_ons.empty?
            io << "\n  <div class=\"am-choice-grid\">"
            @add_ons.each do |add_on|
              io << "\n    <label class=\"am-switch\"><input type=\"checkbox\""
              io << " data-amber-pricing-addon" if compatibility
              io << " data-ap-pricing-addon"
              io << %( value="#{escaped(add_on.value)}")
              io << " checked" if add_on.checked
              io << "> #{escaped(add_on.label)}</label>"
            end
            io << "\n  </div>"
          end
          unless @total.empty?
            io << "\n  <div class=\"am-summary-row\"><span>#{escaped(@total_label)}</span><strong"
            io << " data-amber-pricing-total" if compatibility
            io << " data-ap-pricing-total"
            io << " aria-live=\"polite\" aria-atomic=\"true\"" unless compatibility
            io << ">#{escaped(@total)}</strong></div>"
          end
          unless @note.empty?
            io << "\n  <span class=\"am-demo-subtle\""
            io << " data-amber-pricing-note" if compatibility
            io << " data-ap-pricing-note aria-live=\"polite\">#{escaped(@note)}</span>"
          end
          io << "\n</aside>"
        end
      end

      private def dynamic_pricing? : Bool
        !@seat_price.nil?
      end

      private def render_order_summary_seat_field(compatibility : Bool) : String
        data_attrs = {"data-ap-pricing-seats" => ""}
        data_attrs = {"data-amber-pricing-seats" => "", "data-ap-pricing-seats" => ""} if compatibility
        hint_hooks = compatibility ? "data-amber-pricing-seats-label data-ap-pricing-seats-label" : "data-ap-pricing-seats-label"

        FormField.new(
          label: @seat_label,
          id: @seat_id,
          type: "range",
          min: @seat_min,
          max: @seat_max,
          value: @seat_value,
          hint_html: %(<span #{hint_hooks}>#{escaped(@seat_value)}</span> #{escaped(@seat_hint_suffix)}),
          data_attrs: data_attrs
        ).render
      end

      private def render_order_summary_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if {"id", "class", "compatibility_markup", "data-component", "data-ap-pricing", "data-amber-pricing", "data-ap-pricing-seat-price", "data-ap-pricing-billing", "data-ap-pricing-currency", "data-ap-pricing-period", "data-ap-pricing-annual-factor", "data-ap-pricing-annual-note", "data-ap-pricing-monthly-note", "aria-label", "aria_label"}.includes?(name)

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class PageHero < PrimitiveComponent
      def render_content : String
        return render_demo_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        kicker = @attributes["kicker"]?
        title = @attributes["title"]?
        body = @attributes["body"]? || @attributes["copy"]?
        id = @attributes["id"]?
        label = @attributes["label"]? || @attributes["aria_label"]?

        String.build do |io|
          io << %(<header class="#{root_classes("am-page-hero")}")
          io << %( id="#{escaped(id)}") if id
          io << %( aria-label="#{escaped(label)}") if label
          io << "><div>"
          io << %(<div class="am-kicker">#{escaped(kicker)}</div>) if kicker
          io << %(<h1 class="am-page-title">#{escaped(title)}</h1>) if title
          io << %(<p class="am-demo-copy">#{escaped(body)}</p>) if body
          io << "</div>"
          io << render_children unless @children.empty?
          io << "</header>"
        end
      end

      private def render_demo_compatibility_content : String
        kicker = @attributes["kicker"]? || ""
        title = @attributes["title"]? || ""
        body = @attributes["body"]? || @attributes["copy"]? || ""
        aside = render_children

        <<-HTML
    <header class="am-page-hero">
      <div>
        <div class="am-kicker">#{escaped(kicker)}</div>
        <h1 class="am-page-title">#{escaped(title)}</h1>
        <p class="am-demo-copy">#{escaped(body)}</p>
      </div>
      #{aside}
    </header>
    HTML
      end
    end

    class DashboardShell < PrimitiveComponent
      def render_content : String
        return render_demo_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        title_id = @attributes["title_id"]? || "dashboard-title"
        sidebar_label = @attributes["sidebar_label"]? || "Dashboard sections"
        sidebar_html = @attributes["sidebar_html"]? || ""
        main_html = @attributes["body_html"]? || @attributes["main_html"]?

        String.build do |io|
          io << %(<section class="#{root_classes("am-section")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          io << %( aria-labelledby="#{escaped(title_id)}")
          render_dashboard_shell_passthrough_attributes(io)
          io << ">"
          io << %(<div class="am-dashboard-shell"><aside class="am-sidebar" aria-label="#{escaped(sidebar_label)}">)
          io << sidebar_html
          io << %(</aside><div class="am-dashboard-main">)
          if main_html
            io << main_html
          else
            io << render_children
          end
          io << "</div></div></section>"
        end
      end

      private def render_demo_compatibility_content : String
        title_id = @attributes["title_id"]? || "dashboard-title"
        sidebar_label = @attributes["sidebar_label"]? || "Dashboard sections"
        sidebar_html = @attributes["sidebar_html"]? || ""
        main_html = @attributes["body_html"]? || @attributes["main_html"]? || render_children

        <<-HTML
    <section class="am-section" aria-labelledby="#{escaped(title_id)}">
      <div class="am-dashboard-shell">
        <aside class="am-sidebar" aria-label="#{escaped(sidebar_label)}">
          #{sidebar_html}
        </aside>
        <div class="am-dashboard-main">
          #{main_html}
        </div>
      </div>
    </section>
    HTML
      end

      private def render_dashboard_shell_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if name == "id" || name == "class"
          next if {"title_id", "sidebar_label", "sidebar_html", "body_html", "main_html"}.includes?(name)
          next if name == "aria-labelledby" || name == "aria_labelledby"

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class PageLinkCard < PrimitiveComponent
      def render_content : String
        href = @attributes["href"]? || "#"
        title = @attributes["title"]? || ""
        summary = @attributes["summary"]? || @attributes["body"]? || @attributes["copy"]? || ""
        action_label = @attributes["action_label"]? || "Open #{title.downcase}"

        String.build do |io|
          io << %(<a class="#{root_classes("am-page-card")}" href="#{escaped(href)}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          render_data_aria_attributes(io)
          io << ">"
          io << %(<strong>#{escaped(title)}</strong>)
          io << %(<span>#{escaped(summary)}</span>)
          io << %(<small>#{escaped(action_label)}</small>)
          io << "</a>"
        end
      end
    end

    class PageLinkCardGrid < PrimitiveComponent
      def render_content : String
        compatibility = @attributes["compatibility_markup"]? == "demo"

        String.build do |io|
          io << %(<div class="#{root_classes("am-page-card-grid")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          io << %( data-component="page-link-card-grid") unless compatibility
          render_page_link_card_grid_passthrough_attributes(io)
          io << ">"
          io << render_children
          io << "</div>"
        end
      end

      private def render_page_link_card_grid_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if name == "id" || name == "class" || name == "compatibility_markup"

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class Divider < PrimitiveComponent
      def render_content : String
        label = @attributes["label"]? || ""

        String.build do |io|
          io << %(<div class="#{root_classes("am-divider")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          render_data_aria_attributes(io)
          io << ">"
          io << %(<span>#{escaped(label)}</span>)
          io << "</div>"
        end
      end
    end

    class VisualBand < PrimitiveComponent
      def render_content : String
        return render_demo_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        title = @attributes["title"]? || ""
        body = @attributes["body"]? || @attributes["copy"]? || ""

        String.build do |io|
          io << %(<div class="#{root_classes("am-parallax-band")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          render_data_aria_attributes(io)
          io << ">"
          io << %(<strong>#{escaped(title)}</strong>)
          io << %(<p>#{escaped(body)}</p>)
          io << render_children
          io << "</div>"
        end
      end

      private def render_demo_compatibility_content : String
        title = @attributes["title"]? || ""
        body = @attributes["body"]? || @attributes["copy"]? || ""
        child = render_children

        String.build do |io|
          io << %(<div class="am-parallax-band">)
          io << %(\n    <strong>#{escaped(title)}</strong>)
          io << %(\n    <p>#{escaped(body)}</p>)
          io << "\n    "
          io << child
          io << "\n  </div>"
        end
      end
    end

    class Section < PrimitiveComponent
      component_css <<-CSS
      .am-section {
        display: grid;
        gap: 1rem;
        min-width: 0;
      }

      .am-section--compact {
        gap: 0.625rem;
      }

      .am-section--spacious {
        gap: 1.5rem;
      }

      .am-section__header {
        display: grid;
        gap: 0.375rem;
      }

      .am-section__title {
        color: var(--ap-color-text-primary);
        font-size: 1.375rem;
        font-weight: var(--ap-type-heading-weight);
        letter-spacing: 0;
        line-height: 1.2;
        margin: 0;
      }

      .am-section__subtitle,
      .am-section__body {
        color: var(--ap-color-text-secondary);
        line-height: 1.55;
      }

      .am-section__subtitle {
        margin: 0;
      }

      .am-section__body {
        min-width: 0;
      }
      CSS

      def render_content : String
        return render_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        id = @attributes["id"]? || component_id
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        label = @attributes["label"]?
        spacing = @attributes["spacing"]? || "default"
        title_id = @attributes["title_id"]? || "#{id}-title"
        tag = heading_tag(@attributes["heading_level"]?)
        modifiers = spacing == "default" ? [] of String : [spacing]

        String.build do |io|
          io << %(<section class="#{root_classes("am-section", modifiers)}" id="#{escaped(id)}" data-component="section")
          if title
            io << %( aria-labelledby="#{escaped(title_id)}")
          elsif label
            io << %( aria-label="#{escaped(label)}")
          end
          io << ">"

          if title || subtitle
            io << %(<div class="am-section__header">)
            if title
              io << %(<#{tag} class="am-section__title" id="#{escaped(title_id)}">#{escaped(title)}</#{tag}>)
            end
            if subtitle
              io << %(<p class="am-section__subtitle">#{escaped(subtitle)}</p>)
            end
            io << "</div>"
          end

          unless @children.empty?
            io << %(<div class="am-section__body">)
            io << render_children
            io << "</div>"
          end

          io << "</section>"
        end
      end

      private def render_compatibility_content : String
        id = @attributes["id"]?
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        label = @attributes["label"]?
        spacing = @attributes["spacing"]? || "default"
        title_id = @attributes["title_id"]? || id || component_id
        tag = heading_tag(@attributes["heading_level"]?)
        modifiers = spacing == "default" ? [] of String : [spacing]

        String.build do |io|
          io << %(<section class="#{root_classes("am-section", modifiers)}")
          io << %( id="#{escaped(id)}") if id
          if title
            io << %( aria-labelledby="#{escaped(title_id)}")
          elsif label
            io << %( aria-label="#{escaped(label)}")
          end
          io << ">"

          if title || subtitle
            io << %(<div class="am-section-header">)
            if title
              io << %(<#{tag} id="#{escaped(title_id)}">#{escaped(title)}</#{tag}>)
            end
            if subtitle
              io << %(<p>#{escaped(subtitle)}</p>)
            end
            io << "</div>"
          end

          io << render_children
          io << "</section>"
        end
      end
    end

    class Panel < PrimitiveComponent
      component_css <<-CSS
      .am-panel {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: 1rem;
        min-width: 0;
        padding: 1rem;
      }

      .am-panel--raised {
        box-shadow: var(--ap-elevation-raised);
      }

      .am-panel--brand {
        border-color: var(--ap-color-brand-primary);
      }

      .am-panel--success {
        border-color: var(--ap-color-success-border);
      }

      .am-panel--warning {
        border-color: var(--ap-color-warning-border);
      }

      .am-panel--danger {
        border-color: var(--ap-color-danger-border);
      }

      .am-panel--info {
        border-color: var(--ap-color-info-border);
      }

      .am-panel__header {
        display: grid;
        gap: 0.35rem;
      }

      .am-panel__title {
        font-size: 1.125rem;
        font-weight: var(--ap-type-heading-weight);
        letter-spacing: 0;
        line-height: 1.25;
        margin: 0;
      }

      .am-panel__subtitle,
      .am-panel__body {
        color: var(--ap-color-text-secondary);
        line-height: 1.55;
      }

      .am-panel__subtitle {
        margin: 0;
      }
      CSS

      def render_content : String
        return render_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        id = @attributes["id"]? || component_id
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        label = @attributes["label"]?
        tone = @attributes["tone"]? || "neutral"
        title_id = @attributes["title_id"]? || "#{id}-title"
        tag = heading_tag(@attributes["heading_level"]?, "3")
        modifiers = [] of String
        modifiers << tone unless tone == "neutral"
        modifiers << "raised" if bool_attr?("raised")

        String.build do |io|
          io << %(<section class="#{root_classes("am-panel", modifiers)}" id="#{escaped(id)}" data-component="panel" data-tone="#{escaped(tone)}" role="region")
          if title
            io << %( aria-labelledby="#{escaped(title_id)}")
          elsif label
            io << %( aria-label="#{escaped(label)}")
          end
          io << ">"

          if title || subtitle
            io << %(<div class="am-panel__header">)
            if title
              io << %(<#{tag} class="am-panel__title" id="#{escaped(title_id)}">#{escaped(title)}</#{tag}>)
            end
            if subtitle
              io << %(<p class="am-panel__subtitle">#{escaped(subtitle)}</p>)
            end
            io << "</div>"
          end

          unless @children.empty?
            io << %(<div class="am-panel__body">)
            io << render_children
            io << "</div>"
          end

          io << "</section>"
        end
      end

      private def render_compatibility_content : String
        tag = @attributes["tag"]? || "section"
        tone = @attributes["tone"]?
        label = @attributes["label"]?
        labelledby = @attributes["labelledby"]?
        role = @attributes["role"]?
        id = @attributes["id"]?

        String.build do |io|
          io << %(<#{escaped(tag)} class="#{root_classes("am-panel")}")
          io << %( id="#{escaped(id)}") if id
          io << %( data-tone="#{escaped(tone)}") if tone
          io << %( role="#{escaped(role)}") if role
          io << %( aria-label="#{escaped(label)}") if label
          io << %( aria-labelledby="#{escaped(labelledby)}") if labelledby
          io << ">"
          io << render_children
          io << %(</#{escaped(tag)}>)
        end
      end
    end

    class Metric < PrimitiveComponent
      def render_content : String
        label = @attributes["label"]? || ""
        value = @attributes["value"]? || ""
        body = @attributes["body"]? || @attributes["copy"]?

        String.build do |io|
          io << %(<div class="#{root_classes("am-metric")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          render_data_aria_attributes(io)
          io << ">"
          io << %(<span class="am-demo-subtle">#{escaped(label)}</span>)
          io << %(<strong>#{escaped(value)}</strong>)
          io << "<span>"
          if body
            io << escaped(body)
          else
            io << render_children
          end
          io << "</span></div>"
        end
      end
    end

    class LayoutGrid < PrimitiveComponent
      KIND_CLASSES = {
        "grid"   => "am-grid",
        "two"    => "am-two-col",
        "three"  => "am-three-col",
        "four"   => "am-four-col",
        "metric" => "am-metric-grid",
      }

      def render_content : String
        kind = @attributes["kind"]? || "grid"
        css_class = KIND_CLASSES[kind]? || raise ArgumentError.new("Unknown layout grid kind: #{kind}")
        compatibility = @attributes["compatibility_markup"]? == "demo"

        String.build do |io|
          io << %(<div class="#{root_classes(css_class)}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end

          unless compatibility
            io << %( data-component="layout-grid" data-layout-kind="#{escaped(kind)}")
          end
          render_layout_passthrough_attributes(io)
          io << ">"
          io << render_children
          io << "</div>"
        end
      end

      private def render_layout_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if name == "id" || name == "class" || name == "kind" || name == "compatibility_markup"

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class TerminalPreview < PrimitiveComponent
      DEFAULT_LABEL = "Static generation terminal preview"

      @label : String
      @lines : Array(String)

      def initialize(*, label : String = DEFAULT_LABEL, commands : Array(String)? = nil, lines : Array(String)? = nil, **attrs)
        super(**attrs)
        @label = label
        @lines = commands || lines || [] of String
      end

      def render_content : String
        return render_demo_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        label = @attributes["aria-label"]? || @attributes["aria_label"]? || @label

        String.build do |io|
          io << %(<div class="#{root_classes("am-terminal")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end
          io << %( role="region" aria-label="#{escaped(label)}")
          render_terminal_passthrough_attributes(io)
          io << ">"
          @lines.each do |line|
            io << %(<div class="am-terminal-line">#{escaped(line)}</div>)
          end
          io << "</div>"
        end
      end

      private def render_demo_compatibility_content : String
        label = @attributes["aria-label"]? || @attributes["aria_label"]? || @label

        String.build do |io|
          io << %(<div class="#{root_classes("am-terminal")}" role="region" aria-label="#{escaped(label)}">)
          @lines.each do |line|
            io << "\n      "
            io << %(<div class="am-terminal-line">#{escaped(line)}</div>)
          end
          io << "\n    </div>"
        end
      end

      private def render_terminal_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if name == "id" || name == "class" || name == "aria-label" || name == "aria_label"

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class ShowcasePreview < PrimitiveComponent
      DEFAULT_LABEL        = "Interface preview"
      DEFAULT_WINDOW_TITLE = "Preview"
      DEFAULT_RAIL_LABEL   = "Preview sections"
      DEFAULT_EYEBROW      = "Status"
      DEFAULT_HEADLINE     = "Ready"
      DEFAULT_LIST_LABEL   = "Preview workflow"

      struct Step
        getter title : String
        getter body : String
        getter badge_html : String

        def initialize(@title : String, @body : String, @badge_html : String = "")
        end
      end

      @label : String
      @window_title : String
      @rail_label : String
      @rail_items : Array(String)
      @active_rail_item : String
      @eyebrow : String
      @headline : String
      @badge_html : String
      @list_label : String
      @steps : Array(Step)

      def initialize(*,
                     label : String = DEFAULT_LABEL,
                     aria_label : String? = nil,
                     window_title : String = DEFAULT_WINDOW_TITLE,
                     rail_label : String = DEFAULT_RAIL_LABEL,
                     rail_items : Array(String) = [] of String,
                     active_rail_item : String? = nil,
                     eyebrow : String = DEFAULT_EYEBROW,
                     headline : String = DEFAULT_HEADLINE,
                     badge_html : String = "",
                     list_label : String = DEFAULT_LIST_LABEL,
                     steps : Array(Step) = [] of Step,
                     **attrs)
        super(**attrs)
        @label = aria_label || label
        @window_title = window_title
        @rail_label = rail_label
        @rail_items = rail_items
        @active_rail_item = active_rail_item || rail_items.first? || ""
        @eyebrow = eyebrow
        @headline = headline
        @badge_html = badge_html
        @list_label = list_label
        @steps = steps
      end

      def render_content : String
        compatibility = @attributes["compatibility_markup"]? == "demo"
        label = @attributes["aria-label"]? || @attributes["aria_label"]? || @label

        String.build do |io|
          io << %(<aside class="#{root_classes("am-hero-showcase")}")
          if id = @attributes["id"]?
            io << %( id="#{escaped(id)}")
          end

          if compatibility
            io << " data-amber-sticky-hover data-ap-sticky-hover"
          else
            io << %( data-component="showcase-preview")
            io << " data-ap-sticky-hover" if sticky_hover?
            render_showcase_preview_passthrough_attributes(io)
          end
          io << %( aria-label="#{escaped(label)}">)
          render_showcase_preview_body(io, compatibility)
          io << "\n  </aside>"
        end
      end

      private def render_showcase_preview_body(io : IO, compatibility : Bool) : Nil
        io << "\n    <div class=\"am-window-chrome\">"
        io << "\n      <span class=\"am-window-dots\" aria-hidden=\"true\"><span></span><span></span><span></span></span>"
        io << "\n      <strong>#{escaped(@window_title)}</strong>"
        io << "\n    </div>"
        io << "\n    <div class=\"am-showcase-body\">"
        unless @rail_items.empty?
          if compatibility
            io << "\n      <nav class=\"am-showcase-rail\" aria-label=\"#{escaped(@rail_label)}\">"
          else
            io << "\n      <div class=\"am-showcase-rail\" role=\"list\" aria-label=\"#{escaped(@rail_label)}\">"
          end
          @rail_items.each do |item|
            io << "\n        <span class=\"am-showcase-pill\""
            if compatibility
              io << %( data-active="true") if item == @active_rail_item
            else
              io << %( role="listitem")
              io << %( data-active="true" aria-current="true") if item == @active_rail_item
            end
            io << ">#{escaped(item)}</span>"
          end
          if compatibility
            io << "\n      </nav>"
          else
            io << "\n      </div>"
          end
        end
        io << "\n      <div class=\"am-showcase-main\">"
        io << "\n        <div class=\"am-showcase-headline\">"
        io << "\n          <div><span class=\"am-demo-subtle\">#{escaped(@eyebrow)}</span><strong>#{escaped(@headline)}</strong></div>"
        io << "\n          #{@badge_html}" unless @badge_html.empty?
        io << "\n        </div>"
        unless @steps.empty?
          io << "\n        <div class=\"am-journey-map\" role=\"list\" aria-label=\"#{escaped(@list_label)}\">"
          @steps.each_with_index do |step, index|
            io << "\n          <div class=\"am-journey-step\" role=\"listitem\"><span class=\"am-step-index\">#{index + 1}</span><div><strong>#{escaped(step.title)}</strong><div class=\"am-demo-subtle\">#{escaped(step.body)}</div></div>#{step.badge_html}</div>"
          end
          io << "\n        </div>"
        end
        io << "\n      </div>"
        io << "\n    </div>"
      end

      private def sticky_hover? : Bool
        !{"false", "0", "off"}.includes?(@attributes["sticky_hover"]? || @attributes["sticky-hover"]? || "true")
      end

      private def render_showcase_preview_passthrough_attributes(io : IO) : Nil
        @attributes.each do |name, value|
          next if {"id", "class", "compatibility_markup", "sticky_hover", "sticky-hover", "aria-label", "aria_label", "data-component"}.includes?(name)

          attr_name =
            if name.starts_with?("data-") || name.starts_with?("aria-")
              name
            elsif name.starts_with?("data_") || name.starts_with?("aria_")
              name.gsub('_', '-')
            end

          io << %( #{escaped(attr_name)}="#{escaped(value)}") if attr_name
        end
      end
    end

    class Badge < PrimitiveComponent
      component_css <<-CSS
      .am-badge {
        align-items: center;
        background: var(--ap-color-state-selected);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: 999px;
        color: var(--ap-color-text-primary);
        display: inline-flex;
        font-size: 0.75rem;
        font-weight: 720;
        gap: 0.35rem;
        line-height: 1;
        min-height: 1.5rem;
        padding: 0.25rem 0.55rem;
        vertical-align: middle;
        white-space: nowrap;
      }

      .am-badge--brand {
        background: var(--ap-color-state-selected);
        border-color: var(--ap-color-brand-primary);
        color: var(--ap-color-brand-primary-active);
      }

      .am-badge--success {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-badge--warning {
        background: var(--ap-color-warning-bg);
        border-color: var(--ap-color-warning-border);
        color: var(--ap-color-warning-text);
      }

      .am-badge--danger {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-badge--info {
        background: var(--ap-color-info-bg);
        border-color: var(--ap-color-info-border);
        color: var(--ap-color-info-text);
      }
      CSS

      def render_content : String
        tone = @attributes["tone"]? || "neutral"
        label = @attributes["label"]?
        role = @attributes["role"]?
        modifiers = tone == "neutral" ? [] of String : [tone]

        String.build do |io|
          io << %(<span class="#{root_classes("am-badge", modifiers)}" data-component="badge" data-tone="#{escaped(tone)}")
          io << %( role="#{escaped(role)}") if role
          io << ">"
          if label
            io << escaped(label)
          else
            io << render_children
          end
          io << "</span>"
        end
      end
    end

    class Alert < PrimitiveComponent
      component_css <<-CSS
      .am-alert {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: 0.5rem;
        padding: 0.875rem 1rem;
      }

      .am-alert--success {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-alert--warning {
        background: var(--ap-color-warning-bg);
        border-color: var(--ap-color-warning-border);
        color: var(--ap-color-warning-text);
      }

      .am-alert--danger {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-alert--info {
        background: var(--ap-color-info-bg);
        border-color: var(--ap-color-info-border);
        color: var(--ap-color-info-text);
      }

      .am-alert__title {
        font-weight: 760;
        line-height: 1.25;
      }

      .am-alert__body {
        line-height: 1.5;
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || component_id
        tone = @attributes["tone"]? || "info"
        title = @attributes["title"]?
        body = @attributes["body"]?
        title_id = @attributes["title_id"]? || "#{id}-title"
        role = @attributes["role"]? || (tone == "danger" || tone == "warning" ? "alert" : "status")
        live = @attributes["aria_live"]? || (role == "alert" ? "assertive" : "polite")
        modifiers = tone == "neutral" ? [] of String : [tone]

        String.build do |io|
          io << %(<div class="#{root_classes("am-alert", modifiers)}" id="#{escaped(id)}" data-component="alert" data-tone="#{escaped(tone)}" role="#{escaped(role)}" aria-live="#{escaped(live)}" aria-atomic="true")
          io << %( aria-labelledby="#{escaped(title_id)}") if title
          io << " hidden" if bool_attr?("hidden")
          io << ">"
          if title
            io << %(<div class="am-alert__title" id="#{escaped(title_id)}">#{escaped(title)}</div>)
          end
          io << %(<div class="am-alert__body">)
          if body
            io << escaped(body)
          else
            io << render_children
          end
          io << "</div></div>"
        end
      end
    end

    class EmptyState < PrimitiveComponent
      component_css <<-CSS
      .am-empty-state {
        align-items: center;
        border: 1px dashed var(--ap-color-border-default);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-secondary);
        display: grid;
        gap: 0.75rem;
        justify-items: center;
        min-width: 0;
        padding: clamp(1.5rem, 4vw, 2.5rem);
        text-align: center;
      }

      .am-empty-state__title {
        color: var(--ap-color-text-primary);
        font-size: 1.25rem;
        font-weight: var(--ap-type-heading-weight);
        letter-spacing: 0;
        line-height: 1.2;
        margin: 0;
      }

      .am-empty-state__body {
        line-height: 1.55;
        margin: 0;
        max-width: 42rem;
      }

      .am-empty-state__actions {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.625rem;
        justify-content: center;
      }
      CSS

      def render_content : String
        return render_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        id = @attributes["id"]? || component_id
        title = @attributes["title"]? || "No results"
        body = @attributes["body"]?
        title_id = @attributes["title_id"]? || "#{id}-title"
        tag = heading_tag(@attributes["heading_level"]?, "2")

        String.build do |io|
          io << %(<section class="#{root_classes("am-empty-state")}" id="#{escaped(id)}" data-component="empty-state" aria-labelledby="#{escaped(title_id)}">)
          io << %(<#{tag} class="am-empty-state__title" id="#{escaped(title_id)}">#{escaped(title)}</#{tag}>)
          if body
            io << %(<p class="am-empty-state__body">#{escaped(body)}</p>)
          end
          unless @children.empty?
            io << %(<div class="am-empty-state__actions">)
            io << render_children
            io << "</div>"
          end
          io << "</section>"
        end
      end

      private def render_compatibility_content : String
        title = @attributes["title"]? || "No results"
        body = @attributes["body"]?

        String.build do |io|
          io << %(<section class="#{root_classes("am-empty")}")
          if label = @attributes["label"]?
            io << %( aria-label="#{escaped(label)}")
          end
          io << ">"
          io << %(<strong>#{escaped(title)}</strong>)
          if body
            io << %(<span class="am-demo-subtle">#{escaped(body)}</span>)
          end
          io << render_children
          io << "</section>"
        end
      end
    end

    class Skeleton < PrimitiveComponent
      component_css <<-CSS
      .am-visually-hidden {
        border: 0;
        clip: rect(0 0 0 0);
        height: 1px;
        margin: -1px;
        overflow: hidden;
        padding: 0;
        position: absolute;
        white-space: nowrap;
        width: 1px;
      }

      .am-skeleton {
        display: grid;
        gap: 0.625rem;
        width: 100%;
      }

      .am-skeleton__item {
        animation: am-skeleton-pulse 1.2s ease-in-out infinite;
        background: linear-gradient(90deg, var(--ap-color-surface-sunken), var(--ap-color-state-hover), var(--ap-color-surface-sunken));
        background-size: 200% 100%;
        border-radius: var(--ap-radius-control);
        display: block;
        min-height: 0.875rem;
        width: 100%;
      }

      .am-skeleton__item--short {
        width: 62%;
      }

      .am-skeleton__item--block {
        min-height: 5rem;
      }

      @keyframes am-skeleton-pulse {
        to { background-position: -200% 0; }
      }

      @media (prefers-reduced-motion: reduce) {
        .am-skeleton__item {
          animation: none;
        }
      }
      CSS

      def render_content : String
        label = @attributes["label"]? || "Loading"
        count = (@attributes["count"]? || "3").to_i? || 3
        shape = @attributes["shape"]? || "text"
        count = 1 if count < 1

        String.build do |io|
          io << %(<div class="#{root_classes("am-skeleton")}" data-component="skeleton" role="status" aria-label="#{escaped(label)}">)
          io << %(<span class="am-visually-hidden">#{escaped(label)}</span>)
          count.times do |index|
            item_classes = ["am-skeleton__item"]
            item_classes << "am-skeleton__item--short" if shape == "text" && index == count - 1 && count > 1
            item_classes << "am-skeleton__item--block" if shape == "block"
            io << %(<span class="#{item_classes.join(" ")}" aria-hidden="true"></span>)
          end
          io << "</div>"
        end
      end
    end

    class Toast < PrimitiveComponent
      component_css <<-CSS
      .am-toast {
        align-items: start;
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-overlay);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: 0.25rem 0.75rem;
        grid-template-columns: minmax(0, 1fr) auto;
        max-width: min(28rem, calc(100vw - 2rem));
        padding: 0.875rem;
      }

      .am-toast--success {
        border-color: var(--ap-color-success-border);
      }

      .am-toast--warning {
        border-color: var(--ap-color-warning-border);
      }

      .am-toast--danger {
        border-color: var(--ap-color-danger-border);
      }

      .am-toast--info {
        border-color: var(--ap-color-info-border);
      }

      .am-toast__title {
        font-weight: 760;
        line-height: 1.25;
      }

      .am-toast__body {
        color: var(--ap-color-text-secondary);
        grid-column: 1;
        line-height: 1.45;
      }

      .am-toast__dismiss {
        align-items: center;
        appearance: none;
        background: transparent;
        border: 0;
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-secondary);
        cursor: pointer;
        display: inline-flex;
        font: inherit;
        grid-column: 2;
        grid-row: 1 / span 2;
        justify-content: center;
        min-height: 2rem;
        min-width: 2rem;
        padding: 0.25rem;
      }

      .am-toast__dismiss:focus,
      .am-toast__dismiss:focus-visible {
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 2px;
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || component_id
        tone = @attributes["tone"]? || "info"
        title = @attributes["title"]?
        body = @attributes["body"]?
        title_id = @attributes["title_id"]? || "#{id}-title"
        role = @attributes["role"]? || (tone == "danger" || tone == "warning" ? "alert" : "status")
        live = @attributes["aria_live"]? || (role == "alert" ? "assertive" : "polite")
        dismiss_label = @attributes["dismiss_label"]?
        action_label = @attributes["action_label"]?
        modifiers = tone == "neutral" ? [] of String : [tone]

        String.build do |io|
          io << %(<div class="#{root_classes("am-toast", modifiers)}" id="#{escaped(id)}" data-component="toast" data-tone="#{escaped(tone)}" role="#{escaped(role)}" aria-live="#{escaped(live)}" aria-atomic="true")
          io << %( aria-labelledby="#{escaped(title_id)}") if title
          io << ">"
          if title
            io << %(<div class="am-toast__title" id="#{escaped(title_id)}">#{escaped(title)}</div>)
          end
          io << %(<div class="am-toast__body">)
          if body
            io << escaped(body)
          else
            io << render_children
          end
          io << "</div>"
          if dismiss_label
            io << %(<button class="am-toast__dismiss" type="button" aria-label="#{escaped(dismiss_label)}" data-amber-toast-dismiss data-ap-toast-dismiss>&times;</button>)
          end
          if action_label
            io << %(<button class="am-button am-button--neutral am-button--ghost am-button--sm" type="button">#{escaped(action_label)}</button>)
          end
          io << "</div>"
        end
      end
    end

    class Progress < PrimitiveComponent
      component_css <<-CSS
      .am-progress-field {
        display: grid;
        gap: 0.45rem;
      }

      .am-progress-field__row {
        align-items: center;
        display: flex;
        gap: 0.75rem;
        justify-content: space-between;
      }

      .am-progress-field__label {
        color: var(--ap-color-text-primary);
        font-weight: 680;
        line-height: 1.3;
      }

      .am-progress-field__value {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
        line-height: 1.3;
      }

      .am-progress {
        accent-color: var(--ap-color-brand-primary);
        block-size: 0.75rem;
        inline-size: 100%;
      }

      .am-progress--success {
        accent-color: var(--ap-color-success-indicator);
      }

      .am-progress--warning {
        accent-color: var(--ap-color-warning-indicator);
      }

      .am-progress--danger {
        accent-color: var(--ap-color-danger-indicator);
      }

      .am-progress--info {
        accent-color: var(--ap-color-info-indicator);
      }
      CSS

      def render_content : String
        return render_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        id = @attributes["id"]? || component_id
        label = @attributes["label"]? || "Progress"
        value = @attributes["value"]?
        max = @attributes["max"]? || "100"
        tone = @attributes["tone"]? || "brand"
        value_label = @attributes["value_label"]?
        label_id = @attributes["label_id"]? || "#{id}-label"
        value_id = @attributes["value_id"]? || "#{id}-value"
        modifiers = tone == "brand" ? [] of String : [tone]

        String.build do |io|
          io << %(<div class="#{root_classes("am-progress-field")}" id="#{escaped(id)}" data-component="progress">)
          io << %(<div class="am-progress-field__row">)
          io << %(<span class="am-progress-field__label" id="#{escaped(label_id)}">#{escaped(label)}</span>)
          if value_label
            io << %(<span class="am-progress-field__value" id="#{escaped(value_id)}">#{escaped(value_label)}</span>)
          end
          io << "</div>"
          io << %(<progress class="#{root_classes("am-progress", modifiers)}" max="#{escaped(max)}" aria-labelledby="#{escaped(label_id)}")
          io << %( value="#{escaped(value)}") if value
          io << %( aria-describedby="#{escaped(value_id)}") if value_label
          io << "></progress></div>"
        end
      end

      private def render_compatibility_content : String
        label = @attributes["label"]? || "Progress"
        value = @attributes["value"]? || "0"
        min = @attributes["min"]? || "0"
        max = @attributes["max"]? || "100"
        width = @attributes["width"]? || "#{value}%"

        String.build do |io|
          io << %(<div class="#{root_classes("am-progress")}" role="progressbar" aria-label="#{escaped(label)}" aria-valuemin="#{escaped(min)}" aria-valuemax="#{escaped(max)}" aria-valuenow="#{escaped(value)}">)
          io << %(<span style="width: #{escaped(width)};"></span>)
          io << "</div>"
        end
      end
    end

    class ChatPanel < PrimitiveComponent
      def render_content : String
        id = @attributes["id"]?
        title = @attributes["title"]? || "Review chat"
        title_id = @attributes["title_id"]? || "chat-title"
        label = @attributes["label"]?
        messages_html = @attributes["messages_html"]?
        field_html = @attributes["field_html"]?
        action_html = @attributes["action_html"]?

        String.build do |io|
          io << %(<section class="#{root_classes("am-panel")} am-chat-panel")
          io << %( id="#{escaped(id)}") if id
          if label
            io << %( aria-label="#{escaped(label)}")
          else
            io << %( aria-labelledby="#{escaped(title_id)}")
          end
          io << ">"
          io << %(<div class="am-window-chrome"><strong id="#{escaped(title_id)}">#{escaped(title)}</strong>)
          io << render_children
          io << "</div>"
          io << %(<div class="am-chat-log" data-amber-chat-log data-ap-chat-log role="log" aria-live="polite">)
          io << messages_html if messages_html
          io << "</div>"
          io << %(<form class="am-chat-form" data-amber-chat-form data-ap-chat-form>)
          io << field_html if field_html
          io << action_html if action_html
          io << "</form></section>"
        end
      end
    end

    class LiveSearchPanel < PrimitiveComponent
      def render_content : String
        id = @attributes["id"]?
        title = @attributes["title"]? || "Live search"
        title_id = @attributes["title_id"]? || "search-title"
        label = @attributes["label"]?
        field_html = @attributes["field_html"]? || @attributes["search_field_html"]?
        results_html = @attributes["results_html"]?

        String.build do |io|
          io << %(<section class="#{root_classes("am-panel")}")
          io << %( id="#{escaped(id)}") if id
          if label
            io << %( aria-label="#{escaped(label)}")
          else
            io << %( aria-labelledby="#{escaped(title_id)}")
          end
          io << ">"
          io << %(<h2 id="#{escaped(title_id)}" style="margin:0;">#{escaped(title)}</h2>)
          io << field_html if field_html
          io << %(<div class="am-search-results" data-amber-search-results data-ap-search-results role="status" aria-live="polite">)
          io << results_html if results_html
          io << "</div></section>"
        end
      end
    end

    class UploadQueue < PrimitiveComponent
      def render_content : String
        id = @attributes["id"]?
        title = @attributes["title"]? || "Upload queue"
        title_id = @attributes["title_id"]? || "upload-title"
        label = @attributes["label"]?
        item_html = @attributes["item_html"]?
        progress_html = @attributes["progress_html"]?

        String.build do |io|
          io << %(<section class="#{root_classes("am-panel")}")
          io << %( id="#{escaped(id)}") if id
          if label
            io << %( aria-label="#{escaped(label)}")
          else
            io << %( aria-labelledby="#{escaped(title_id)}")
          end
          io << ">"
          io << %(<h2 id="#{escaped(title_id)}" style="margin:0;">#{escaped(title)}</h2>)
          io << %(<div class="am-upload-queue">)
          io << item_html if item_html
          io << progress_html if progress_html
          io << render_children
          io << "</div></section>"
        end
      end
    end

    class Disclosure < PrimitiveComponent
      component_css <<-CSS
      .am-disclosure {
        display: grid;
        gap: 0.75rem;
        min-width: 0;
      }

      .am-disclosure__panel {
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-secondary);
        padding: 0.875rem 1rem;
      }

      .am-disclosure__panel[hidden] {
        display: none;
      }
      CSS

      def render_content : String
        return render_compatibility_content if @attributes["compatibility_markup"]? == "demo"

        id = @attributes["id"]? || component_id
        label = @attributes["label"]? || "Show details"
        panel_id = @attributes["panel_id"]? || "#{id}-panel"
        expanded = bool_attr?("expanded")
        panel_label = @attributes["panel_label"]?

        String.build do |io|
          io << %(<div class="#{root_classes("am-disclosure")}" id="#{escaped(id)}" data-component="disclosure">)
          io << %(<button class="am-button am-button--neutral am-button--outline am-button--md" type="button" data-amber-disclosure data-ap-disclosure aria-expanded="#{expanded}" aria-controls="#{escaped(panel_id)}">#{escaped(label)}</button>)
          io << %(<div class="am-disclosure__panel" id="#{escaped(panel_id)}")
          if panel_label
            io << %( aria-label="#{escaped(panel_label)}")
          end
          io << " hidden" unless expanded
          io << ">"
          io << render_children
          io << "</div></div>"
        end
      end

      private def render_compatibility_content : String
        label = @attributes["label"]? || "Show details"
        panel_id = @attributes["panel_id"]? || "details-panel"
        expanded = bool_attr?("expanded")

        String.build do |io|
          io << %(<button type="button" class="am-button am-button--neutral am-button--outline am-button--md" data-state="default" data-tone="neutral" data-emphasis="outline" data-amber-disclosure="" data-ap-disclosure="" aria-expanded="#{expanded}" aria-controls="#{escaped(panel_id)}">#{escaped(label)}</button>)
          io << render_children
        end
      end
    end

    class ValidatedForm < PrimitiveComponent
      component_css <<-CSS
      .am-form {
        display: grid;
        gap: 1rem;
      }

      .am-form-status {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-secondary);
        line-height: 1.5;
        padding: 0.75rem 0.875rem;
      }

      .am-form-status[data-state="success"] {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-form-status[data-state="error"] {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || component_id
        label = @attributes["label"]? || "Validated form"
        status = @attributes["status"]? || "Complete the required fields."
        status_id = @attributes["status_id"]? || "#{id}-status"
        method = @attributes["method"]? || "post"
        action = @attributes["action"]?

        String.build do |io|
          classes = ["am-form", "am-panel"]
          if extra = @attributes["class"]?
            classes.concat(extra.split(/\s+/).reject(&.empty?))
          end

          io << %(<form class="#{classes.join(" ")}" id="#{escaped(id)}" data-component="validated-form" data-amber-validate data-ap-validate novalidate aria-describedby="#{escaped(status_id)}" aria-label="#{escaped(label)}" method="#{escaped(method)}")
          io << %( action="#{escaped(action)}") if action
          io << ">"
          io << %(<div class="am-form-status" id="#{escaped(status_id)}" role="status" data-amber-form-status data-ap-form-status>#{escaped(status)}</div>)
          io << render_children
          io << "</form>"
        end
      end
    end
  end
end
