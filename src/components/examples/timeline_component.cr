require "../base/stateless_component"

module Components
  module Examples
    # Alternating milestone timeline with scroll-reveal hooks.
    class TimelineComponent < StatelessComponent
      record Milestone, date : String, title : String, body : String

      component_css <<-CSS
      .am-timeline {
        position: relative;
      }

      .am-timeline::before {
        background: linear-gradient(180deg, var(--ap-color-brand-primary), var(--ap-color-brand-accent));
        border-radius: var(--ap-radius-pill);
        content: "";
        inset: 0 auto 0 50%;
        position: absolute;
        transform: translateX(-50%);
        width: 0.25rem;
      }

      .am-timeline-item {
        display: grid;
        gap: 1rem;
        grid-template-columns: minmax(0, 1fr) 3rem minmax(0, 1fr);
        margin: 1.75rem 0;
        opacity: 1;
        transform: none;
      }

      .am-timeline-item[data-visible="true"] {
        opacity: 1;
        transform: translateY(0);
        transition: opacity var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized),
          transform var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized);
      }

      .am-timeline-dot {
        align-self: center;
        background: var(--ap-color-brand-primary);
        border: 4px solid var(--ap-color-surface-canvas);
        border-radius: 999px;
        box-shadow: 0 0 0 1px var(--ap-color-border-subtle);
        height: 1.25rem;
        justify-self: center;
        width: 1.25rem;
        z-index: 1;
      }

      .am-timeline-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        display: grid;
        gap: 0.45rem;
        padding: 1rem;
      }

      .am-timeline-item:nth-child(even) .am-timeline-card {
        grid-column: 3;
      }

      .am-timeline-item:nth-child(even) .am-timeline-dot {
        grid-column: 2;
      }

      .am-timeline-item:nth-child(odd) .am-timeline-card {
        grid-column: 1;
      }

      .am-timeline-item:nth-child(odd) .am-timeline-dot {
        grid-column: 2;
      }

      @media (max-width: 640px) {
        .am-timeline::before {
          left: 0.75rem;
          transform: none;
        }

        .am-timeline-item {
          grid-template-columns: 1.75rem minmax(0, 1fr);
        }

        .am-timeline-item:nth-child(n) .am-timeline-card {
          grid-column: 2;
        }

        .am-timeline-item:nth-child(n) .am-timeline-dot {
          grid-column: 1;
        }
      }
      CSS

      @milestones : Array(Milestone)

      def initialize(@milestones : Array(Milestone) = self.class.default_milestones, **attrs)
        super(**attrs)
      end

      def self.default_milestones : Array(Milestone)
        [
          Milestone.new("2011", "First Crystal work begins", "Crystal starts as a Ruby-inspired compiled language experiment."),
          Milestone.new("2014", "Public momentum builds", "Early adopters explore expressive syntax with native-code performance."),
          Milestone.new("2017", "Web frameworks mature", "Amber and other Crystal web tools make full-stack applications easier to imagine."),
          Milestone.new("2021", "Crystal 1.0", "The language reaches a stable milestone with a clearer compatibility promise."),
          Milestone.new("2024", "Ecosystem hardening", "Developer tooling, docs, and production practices become more practical."),
          Milestone.new("2026", "Design-system proof", "Asset Pipeline demonstrates token-backed UI, no-build JS, and browser validation."),
        ]
      end

      def render_content : String
        id = @attributes["id"]? || "am-timeline-#{object_id}"
        title = @attributes["title"]? || "Selected milestones"

        String.build do |io|
          io << %(<section class="am-section am-timeline" data-component="timeline" aria-labelledby="#{escape_html(id)}-title">)
          io << %(<h2 id="#{escape_html(id)}-title" class="am-demo-subtle">#{escape_html(title)}</h2>)
          @milestones.each do |item|
            io << %(<article class="am-timeline-item" data-amber-reveal data-ap-reveal><span class="am-timeline-dot" aria-hidden="true"></span><div class="am-timeline-card"><span class="am-badge" data-tone="brand">#{escape_html(item.date)}</span><strong>#{escape_html(item.title)}</strong><p class="am-demo-copy">#{escape_html(item.body)}</p></div></article>)
          end
          io << "</section>"
        end
      end
    end
  end
end
