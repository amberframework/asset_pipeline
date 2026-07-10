require "../base/stateless_component"
require "./button_component"

module Components
  module Examples
    # Plan card used by pricing/comparison pages.
    #
    # It is deliberately small: price cards compose badges, copy, and a
    # token-backed button while preserving a stable `data-component` contract.
    class PricingCardComponent < StatelessComponent
      component_css <<-CSS
      .am-price-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        display: grid;
        gap: 1rem;
        padding: 1rem;
      }

      .am-price-card[data-featured="true"] {
        border-color: color-mix(in oklch, var(--ap-color-brand-primary) 58%, var(--ap-color-border-subtle));
        box-shadow: var(--ap-elevation-floating);
      }

      .am-price {
        align-items: baseline;
        display: flex;
        gap: 0.35rem;
      }

      .am-price strong {
        font-size: 2rem;
        line-height: 1;
      }
      CSS

      def render_content : String
        name = @attributes["name"]? || "Plan"
        badge = @attributes["badge"]? || name
        badge_tone = @attributes["badge_tone"]? || "brand"
        price = @attributes["price"]? || "$0"
        period = @attributes["period"]? || "/seat"
        copy = @attributes["copy"]? || ""
        featured = @attributes["featured"]? == "true"
        action = @attributes["action"]? || "Choose #{name}"
        action_tone = @attributes["action_tone"]? || (featured ? "brand" : "neutral")
        action_emphasis = @attributes["action_emphasis"]? || (featured ? "solid" : "outline")

        button = ButtonComponent.new(
          label: action,
          tone: action_tone,
          emphasis: action_emphasis,
          size: "md"
        )

        String.build do |io|
          io << %(<article class="am-price-card" data-component="pricing-card")
          io << %( data-featured="true") if featured
          io << ">"
          io << %(<span class="am-badge" data-tone="#{escape_html(badge_tone)}">#{escape_html(badge)}</span>)
          io << %(<div class="am-price"><strong>#{escape_html(price)}</strong><span>#{escape_html(period)}</span></div>)
          io << %(<p class="am-demo-copy">#{escape_html(copy)}</p>)
          io << button.render
          io << %(</article>)
        end
      end
    end
  end
end
