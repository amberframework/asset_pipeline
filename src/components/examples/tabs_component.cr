require "../base/stateless_component"

module Components
  module Examples
    # Accessible tab set with roving tabindex, neutral behavior hooks, and
    # compatibility aliases.
    class TabsComponent < StatelessComponent
      record Tab, id : String, label : String, panel : String

      component_css <<-CSS
      .am-tabs {
        display: grid;
        gap: 0.8rem;
      }

      .am-tabs [role="tablist"] {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
      }

      .am-tabs [role="tab"] {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        cursor: pointer;
        font: inherit;
        font-weight: 680;
        min-height: 2.4rem;
        padding: 0.55rem 0.8rem;
      }

      .am-tabs [role="tab"][aria-selected="true"] {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
      }

      .am-tabs [role="tab"]:focus-visible {
        outline: 2px solid var(--ap-color-border-focus);
        outline-offset: 3px;
      }

      .am-tab-panel {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-secondary);
        padding: 0.85rem;
      }

      .am-tab-panel[hidden] {
        display: none;
      }

      .am-component-title {
        margin: 0;
      }
      CSS

      @tabs : Array(Tab)

      def initialize(@tabs : Array(Tab) = self.class.default_tabs, **attrs)
        super(**attrs)
      end

      def self.default_tabs : Array(Tab)
        [
          Tab.new("spec", "Spec", "Semantic forms, token-backed states, and no-build helpers define the contract."),
          Tab.new("audit", "Audit", "Crystal and Chrome inspect validity, focus, contrast, and interaction behavior."),
          Tab.new("shots", "Screens", "Desktop and mobile screenshots capture visual evidence for review."),
        ]
      end

      def render_content : String
        id = @attributes["id"]? || "am-tabs-#{object_id}"
        title = @attributes["title"]? || "Tabbed evidence"
        label = @attributes["label"]? || "#{title} views"

        String.build do |io|
          io << %(<section class="am-panel am-tabs" data-amber-tabs data-ap-tabs data-component="tabs" aria-labelledby="#{escape_html(id)}-title">)
          io << %(<h2 id="#{escape_html(id)}-title" class="am-component-title">#{escape_html(title)}</h2>)
          io << %(<div role="tablist" aria-label="#{escape_html(label)}">)
          @tabs.each_with_index do |tab, index|
            selected = index == 0
            tab_id = "#{id}-tab-#{tab.id}"
            panel_id = "#{id}-panel-#{tab.id}"
            io << %(<button id="#{escape_html(tab_id)}" role="tab" type="button" aria-selected="#{selected}" aria-controls="#{escape_html(panel_id)}" tabindex="#{selected ? 0 : -1}">#{escape_html(tab.label)}</button>)
          end
          io << "</div>"
          @tabs.each_with_index do |tab, index|
            tab_id = "#{id}-tab-#{tab.id}"
            panel_id = "#{id}-panel-#{tab.id}"
            hidden = index == 0 ? "" : " hidden"
            io << %(<div class="am-tab-panel" id="#{escape_html(panel_id)}" role="tabpanel" aria-labelledby="#{escape_html(tab_id)}"#{hidden}>#{escape_html(tab.panel)}</div>)
          end
          io << "</section>"
        end
      end
    end
  end
end
