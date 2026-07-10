require "../base/stateless_component"

module Components
  module Examples
    # First-party SVG chart proof for milestone 1.
    #
    # This intentionally avoids a hard Chart.js dependency. Larger charting
    # libraries can be added later behind an adapter that preserves this
    # semantic wrapper and token contract.
    class SimpleChartComponent < StatelessComponent
      component_css <<-CSS
      .am-chart {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: 0.75rem;
        min-width: 0;
        padding: 1rem;
      }

      .am-chart__title {
        color: var(--ap-color-text-primary);
        font-weight: var(--ap-type-heading-weight);
      }

      .am-chart__summary {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
      }

      .am-chart svg {
        height: auto;
        max-width: 100%;
        overflow: visible;
        width: 100%;
      }

      .am-chart__bar {
        fill: var(--ap-color-brand-primary);
        rx: 6;
        transform-origin: bottom;
      }

      .am-chart__bar:nth-of-type(2n) {
        fill: var(--ap-color-brand-accent);
      }

      .am-chart__axis {
        stroke: var(--ap-color-border-default);
        stroke-width: 1;
      }

      .am-chart__label {
        fill: var(--ap-color-text-muted);
        font: 600 10px var(--ap-font-sans);
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

      @media (prefers-reduced-motion: no-preference) {
        .am-chart__bar {
          animation: amber-chart-grow var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized) both;
          transform: scaleY(0.08);
        }

        .am-chart__bar:nth-of-type(2) { animation-delay: 60ms; }
        .am-chart__bar:nth-of-type(3) { animation-delay: 120ms; }
        .am-chart__bar:nth-of-type(4) { animation-delay: 180ms; }
      }

      @keyframes amber-chart-grow {
        to { transform: scaleY(1); }
      }
      CSS

      @values : Array(Int32)
      @labels : Array(String)
      VALID_ADAPTERS = %w[first-party-svg external]

      def initialize(@values : Array(Int32) = [18, 31, 26, 44], @labels : Array(String) = ["Mon", "Tue", "Wed", "Thu"], **attrs)
        super(**attrs)
      end

      def render_content : String
        adapter = @attributes["adapter"]? || "first-party-svg"
        raise ArgumentError.new("Invalid chart adapter '#{adapter}'. Expected one of: #{VALID_ADAPTERS.join(", ")}") unless VALID_ADAPTERS.includes?(adapter)

        title = @attributes["title"]? || "Weekly activity"
        return render_external_adapter(title) if adapter == "external"

        max = @values.empty? ? 1 : @values.max
        width = 320
        height = 160
        gap = 16
        count = @values.empty? ? 1 : @values.size
        bar_width = ((width - 40 - gap * (count - 1)) / count).to_i
        chart_id = @attributes["id"]? || "am-chart-#{object_id}"
        description = @values.each_with_index.map do |value, index|
          label = @labels[index]? || (index + 1).to_s
          "#{label}: #{value}"
        end.join(", ")

        String.build do |io|
          io << %(<figure class="am-chart" data-component="chart" data-chart-adapter="first-party-svg" aria-describedby="#{chart_id}-data-caption">)
          io << %(<figcaption><div class="am-chart__title">#{escape_html(title)}</div>)
          io << %(<div class="am-chart__summary">A fast built-in chart preview for simple product metrics.</div></figcaption>)
          io << %(<svg viewBox="0 0 #{width} #{height}" aria-hidden="true" focusable="false">)
          io << %(<title id="#{chart_id}-title">#{escape_html(title)} chart</title>)
          io << %(<desc id="#{chart_id}-desc">#{escape_html(description)}</desc>)
          io << %(<line class="am-chart__axis" x1="24" y1="132" x2="#{width - 8}" y2="132"></line>)

          @values.each_with_index do |value, index|
            bar_height = ((value.to_f / max.to_f) * 104).round.to_i
            x = 32 + index * (bar_width + gap)
            y = 132 - bar_height
            io << %(<rect class="am-chart__bar" data-chart-part="bar" x="#{x}" y="#{y}" width="#{bar_width}" height="#{bar_height}"></rect>)
            label = @labels[index]? || (index + 1).to_s
            io << %(<text class="am-chart__label" x="#{x + bar_width / 2}" y="150" text-anchor="middle">#{escape_html(label)}</text>)
          end

          io << "</svg>"
          io << %(<table class="am-sr-only"><caption id="#{chart_id}-data-caption">#{escape_html(title)} source data</caption><thead><tr><th scope="col">Label</th><th scope="col">Value</th></tr></thead><tbody>)
          @values.each_with_index do |value, index|
            label = @labels[index]? || (index + 1).to_s
            io << %(<tr><th scope="row">#{escape_html(label)}</th><td>#{value}</td></tr>)
          end
          io << "</tbody></table></figure>"
        end
      end

      private def render_external_adapter(title : String) : String
        chart_id = @attributes["id"]? || "am-chart-#{object_id}"
        String.build do |io|
          io << %(<figure class="am-chart" data-component="chart" data-chart-adapter="external" aria-describedby="#{chart_id}-data-caption">)
          io << %(<figcaption><div class="am-chart__title">#{escape_html(title)}</div>)
          io << %(<div class="am-chart__summary">External chart adapters mount inside the isolated root while Amber keeps captions, tokens, and source data.</div></figcaption>)
          io << %(<div data-chart-external-root data-chart-values="#{escape_html(@values.join(","))}" data-chart-labels="#{escape_html(@labels.join(","))}"></div>)
          io << %(<table class="am-sr-only"><caption id="#{chart_id}-data-caption">#{escape_html(title)} source data</caption><thead><tr><th scope="col">Label</th><th scope="col">Value</th></tr></thead><tbody>)
          @values.each_with_index do |value, index|
            label = @labels[index]? || (index + 1).to_s
            io << %(<tr><th scope="row">#{escape_html(label)}</th><td>#{value}</td></tr>)
          end
          io << "</tbody></table></figure>"
        end
      end
    end
  end
end
