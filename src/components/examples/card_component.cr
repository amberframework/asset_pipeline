require "../base/stateless_component"
require "../elements/grouping/div"
require "../elements/sections/headings"
require "../elements/grouping/p"
require "../elements/embedded/img"

module Components
  module Examples
    # Opinionated design-system card example. Emits token-backed compatibility
    # anatomy classes instead of Bootstrap-shaped `.card-body` / `.card-title`.
    class CardComponent < StatelessComponent
      component_css <<-CSS
      .am-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        color: var(--ap-color-text-primary);
        display: flex;
        flex-direction: column;
        min-width: 0;
        overflow: hidden;
        transition: border-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          box-shadow var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          transform var(--ap-motion-duration-fast) var(--ap-motion-ease-emphasized);
      }

      .am-card:hover {
        border-color: var(--ap-color-border-default);
        box-shadow: var(--ap-elevation-floating);
        transform: translateY(-2px);
      }

      .am-card--flat {
        box-shadow: var(--ap-elevation-flat);
      }

      .am-card--outline {
        box-shadow: none;
      }

      .am-card--interactive {
        cursor: pointer;
      }

      .am-card--selected {
        border-color: var(--ap-color-brand-primary);
        box-shadow: 0 0 0 3px var(--ap-color-border-focus), var(--ap-elevation-raised);
      }

      .am-card--danger {
        border-color: var(--ap-color-danger-border);
      }

      .am-card__media {
        aspect-ratio: 16 / 9;
        background: var(--ap-color-surface-sunken);
        object-fit: cover;
        width: 100%;
      }

      .am-card__body {
        display: grid;
        gap: 0.75rem;
        padding: 1rem;
      }

      .am-card__eyebrow {
        color: var(--ap-color-brand-primary-active);
        font-size: 0.75rem;
        font-weight: 760;
        letter-spacing: 0;
        text-transform: uppercase;
      }

      .am-card__title {
        color: var(--ap-color-text-primary);
        font-size: 1.125rem;
        font-weight: var(--ap-type-heading-weight);
        line-height: 1.2;
      }

      .am-card__subtitle,
      .am-card__content {
        color: var(--ap-color-text-secondary);
        line-height: 1.55;
      }

      .am-card__content {
        font-size: 0.9375rem;
      }

      @media (prefers-reduced-motion: reduce) {
        .am-card,
        .am-card:hover {
          transition-duration: 0.01ms;
          transform: none;
        }
      }
      CSS

      def render_content : String
        title = @attributes["title"]?
        subtitle = @attributes["subtitle"]?
        eyebrow = @attributes["eyebrow"]?
        image_url = @attributes["image_url"]?
        image_alt = @attributes["image_alt"]? || ""
        tone = @attributes["tone"]? || "neutral"
        selected = @attributes["selected"]? == "true"
        interactive = @attributes["interactive"]? == "true"
        outlined = @attributes["outlined"]? == "true"

        card_classes = ["am-card"]
        card_classes << "am-card--#{tone}" unless tone == "neutral"
        card_classes << "am-card--selected" if selected
        card_classes << "am-card--interactive" if interactive
        card_classes << "am-card--outline" if outlined

        card = Elements::Div.new(class: card_classes.join(" ")).build do |c|
          c.set_attribute("data-component", "card")
          c.set_attribute("data-state", selected ? "selected" : "default")
          if interactive
            c.set_attribute("role", "button")
            c.set_attribute("tabindex", "0")
            c.set_attribute("aria-pressed", selected ? "true" : "false")
          end

          if image_url
            c << Elements::Img.new(
              src: image_url,
              alt: image_alt,
              class: "am-card__media"
            )
          end

          c << Elements::Div.new(class: "am-card__body").build do |body|
            if eyebrow
              el = Elements::Div.new(class: "am-card__eyebrow")
              el << eyebrow
              body << el
            end

            if title
              heading = Elements::H3.new(class: "am-card__title")
              heading << title
              body << heading
            end

            if subtitle
              el = Elements::P.new(class: "am-card__subtitle")
              el << subtitle
              body << el
            end

            unless @children.empty?
              content_div = Elements::Div.new(class: "am-card__content")
              @children.each do |child|
                case child
                when Component
                  content_div << child.render
                when Elements::HTMLElement
                  content_div << child
                when String
                  content_div << child
                end
              end
              body << content_div
            end
          end
        end

        card.render
      end
    end
  end
end
