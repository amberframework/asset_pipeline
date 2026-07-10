require "../base/stateless_component"
require "../elements/base/raw_html"
require "./button_component"

module Components
  module Examples
    # Theme controls for pages using the Amber cascade contract.
    #
    # `mode="toggle"` is a compact global switch. `mode="segmented"` exposes
    # explicit light/dark buttons for demos and settings screens.
    class ThemeSwitcherComponent < StatelessComponent
      component_css <<-CSS
      .am-theme-status {
        align-items: center;
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        display: inline-flex;
        font-size: 0.8125rem;
        font-weight: 680;
        min-height: 2rem;
        padding: 0 0.65rem;
      }

      .am-segmented {
        align-items: center;
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        display: inline-flex;
        gap: 0.2rem;
        padding: 0.2rem;
      }

      .am-segmented button {
        background: transparent;
        border: 0;
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        cursor: pointer;
        font: inherit;
        font-size: 0.875rem;
        font-weight: 680;
        /* Visual height stays 2rem (32 px); use min-block-size to expose
           the AA touch target while leaving the rendered chip compact. */
        min-block-size: 44px;
        min-inline-size: 44px;
        padding: 0 0.75rem;
      }

      .am-segmented button:hover,
      .am-segmented button:focus-visible {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 2px;
      }

      .am-segmented button[aria-pressed="true"] {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
      }
      CSS

      def render_content : String
        case @attributes["mode"]?
        when "segmented"
          segmented
        else
          toggle
        end
      end

      private def toggle : String
        label = @attributes["label"]? || "Switch to dark"
        status = @attributes["status"]? || "Light active"
        button = ButtonComponent.new(label: "", tone: "neutral", emphasis: "ghost", size: "sm")
        button["data-component"] = "theme-switcher"
        button["data-amber-theme-toggle"] = ""
        button["data-ap-theme-toggle"] = ""
        button["aria-pressed"] = "false"
        button << Elements::RawHTML.new(%(<span data-amber-theme-label data-ap-theme-label>#{escape_html(label)}</span>))

        String.build do |io|
          io << button.render
          io << %(<span class="am-theme-status" data-component="theme-status" data-amber-theme-status data-ap-theme-status role="status" aria-live="polite">#{escape_html(status)}</span>)
        end
      end

      private def segmented : String
        label = @attributes["label"]? || "Theme mode"
        <<-HTML
        <span class="am-segmented" role="group" aria-label="#{escape_html(label)}" data-component="theme-switcher" data-theme-switcher-mode="segmented">
          <button type="button" data-amber-theme-set="light" data-ap-theme-set="light" aria-pressed="true">Light</button>
          <button type="button" data-amber-theme-set="dark" data-ap-theme-set="dark" aria-pressed="false">Dark</button>
        </span>
        HTML
      end
    end
  end
end
