require "../base/stateless_component"

module Components
  module Examples
    # Compact carousel for status cards. Keyboard and state behavior is handled
    # by the vanilla `initCarousel` helper.
    class CarouselComponent < StatelessComponent
      record Slide, tone : String, title : String, body : String

      component_css <<-CSS
      .am-carousel {
        display: grid;
        gap: 0.8rem;
      }

      .am-carousel-track {
        display: grid;
        grid-template-columns: 1fr;
      }

      .am-carousel-slide {
        display: none;
      }

      .am-carousel-slide[data-active="true"] {
        display: grid;
      }

      .am-carousel:focus-visible {
        outline: 2px solid var(--ap-color-border-focus);
        outline-offset: 4px;
      }
      CSS

      @slides : Array(Slide)

      def initialize(@slides : Array(Slide) = self.class.default_slides, **attrs)
        super(**attrs)
      end

      def self.default_slides : Array(Slide)
        [
          Slide.new("success", "Light mode", "Native controls and surfaces stay readable."),
          Slide.new("warning", "Dark mode", "Ink surfaces use contrast instead of pure black."),
          Slide.new("danger", "Invalid state", "Error text, border, and focus ring coordinate."),
        ]
      end

      def render_content : String
        id = @attributes["id"]? || "am-carousel-#{object_id}"
        title = @attributes["title"]? || "Carousel"

        String.build do |io|
          io << %(<section class="am-panel am-carousel" id="#{escape_html(id)}" data-amber-carousel data-ap-carousel data-component="carousel" aria-labelledby="#{escape_html(id)}-title" aria-roledescription="carousel">)
          io << %(<h2 id="#{escape_html(id)}-title" class="am-component-title">#{escape_html(title)}</h2>)
          io << %(<div class="am-carousel-track">)
          @slides.each_with_index do |slide, index|
            active = index == 0
            io << %(<div class="am-carousel-slide am-alert" data-active="#{active}" data-tone="#{escape_html(slide.tone)}" role="group" aria-roledescription="slide" aria-label="#{index + 1} of #{@slides.size}" aria-hidden="#{!active}"><strong>#{escape_html(slide.title)}</strong><span>#{escape_html(slide.body)}</span></div>)
          end
          io << "</div>"
          io << %(<div class="am-inline-actions">)
          io << %(<button class="am-button am-button--neutral am-button--outline am-button--sm" type="button" data-amber-carousel-prev data-ap-carousel-prev aria-label="Previous slide">Previous</button>)
          io << %(<button class="am-button am-button--brand am-button--solid am-button--sm" type="button" data-amber-carousel-next data-ap-carousel-next aria-label="Next slide">Next</button>)
          io << %(<span class="am-demo-subtle" data-amber-carousel-status data-ap-carousel-status role="status" aria-live="polite">Slide 1 of #{@slides.size}</span>)
          io << "</div></section>"
        end
      end
    end
  end
end
