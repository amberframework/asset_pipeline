require "../base/stateless_component"

module Components
  module Examples
    # Accessible heatmap proof for compact schedule/activity summaries.
    class ScheduleHeatmapComponent < StatelessComponent
      record Hour, hour : Int32, level : Int32, label : String

      component_css <<-CSS
      .am-heatmap-card {
        display: grid;
        gap: 0.65rem;
        margin: 0;
      }

      .am-heatmap {
        display: grid;
        gap: 0.65rem;
        grid-template-columns: repeat(12, minmax(0, 1fr));
      }

      .am-heat-pill {
        background: color-mix(in oklch, var(--ap-color-brand-accent) calc(var(--heat, 10) * 1%), var(--ap-color-surface-elevated));
        border: 1px solid color-mix(in oklch, var(--ap-color-brand-accent) 24%, var(--ap-color-border-subtle));
        border-radius: var(--ap-radius-pill);
        min-height: 0.8rem;
      }

      .am-heatmap-summary {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
      }

      .am-sr-only {
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

      @media (max-width: 640px) {
        .am-heatmap {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }
      CSS

      @hours : Array(Hour)

      def initialize(@hours : Array(Hour) = self.class.default_hours, **attrs)
        super(**attrs)
      end

      def self.default_hours : Array(Hour)
        (0...24).map do |hour|
          level = ((hour * 7) % 70) + 18
          descriptor = level > 70 ? "high" : level > 45 ? "moderate" : "low"
          Hour.new(hour, level, "#{hour.to_s.rjust(2, '0')}:00 #{descriptor} activity")
        end
      end

      def render_content : String
        id = @attributes["id"]? || "am-heatmap-#{object_id}"
        title = @attributes["title"]? || "Schedule heatmap"
        summary = @attributes["summary"]? || "Hourly launch activity from midnight through 23:00."

        String.build do |io|
          io << %(<figure class="am-heatmap-card" data-component="schedule-heatmap" aria-describedby="#{escape_html(id)}-summary #{escape_html(id)}-table-caption">)
          io << %(<figcaption><strong>#{escape_html(title)}</strong><span class="am-heatmap-summary" id="#{escape_html(id)}-summary">#{escape_html(summary)}</span></figcaption>)
          io << %(<div class="am-heatmap" role="list" aria-label="#{escape_html(title)}" aria-describedby="#{escape_html(id)}-summary">)
          @hours.each do |hour|
            io << %(<span class="am-heat-pill" role="listitem" style="--heat: #{hour.level};" title="#{escape_html(hour.label)}" aria-label="#{escape_html(hour.label)}"></span>)
          end
          io << "</div>"
          io << %(<table class="am-sr-only"><caption id="#{escape_html(id)}-table-caption">#{escape_html(title)} table fallback</caption><thead><tr><th scope="col">Hour</th><th scope="col">Activity</th></tr></thead><tbody>)
          @hours.each do |hour|
            io << %(<tr><th scope="row">#{hour.hour.to_s.rjust(2, '0')}:00</th><td>#{hour.level}% - #{escape_html(hour.label)}</td></tr>)
          end
          io << "</tbody></table>"
          io << "</figure>"
        end
      end
    end
  end
end
