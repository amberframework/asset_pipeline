require "../base/stateless_component"

module Components
  module Examples
    # Dialog-style command palette with vanilla JS keyboard behavior.
    class CommandPaletteComponent < StatelessComponent
      record Command, label : String, shortcut : String

      component_css <<-CSS
      .am-command-component {
        display: grid;
        gap: 0.5rem;
      }

      .am-command-panel {
        background:
          linear-gradient(135deg, color-mix(in oklch, var(--ap-color-brand-primary) 12%, transparent), transparent 45%),
          var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-floating);
        color: var(--ap-color-text-primary);
        /* Closed state: hide visually but keep the inner controls laid
           out so AA touch-target audits, focus-visible enumeration, and
           accessibility-tree walkers can inspect the items without
           opening the palette. The owning element carries `inert` while
           closed; see scripts/design-system.js openCommandPanel. */
        inset: 12vh max(1rem, calc((100vw - 760px) / 2)) auto;
        opacity: 0;
        overflow: hidden;
        padding: 0;
        pointer-events: none;
        position: fixed;
        transform: translateY(-6px);
        transition: opacity var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          transform var(--ap-motion-duration-fast) var(--ap-motion-ease-standard);
        visibility: hidden;
        z-index: 50;
      }

      .am-command-panel[data-state="open"] {
        opacity: 1;
        pointer-events: auto;
        transform: none;
        visibility: visible;
      }

      .am-command-list {
        display: grid;
        gap: 0.35rem;
        padding: 0.85rem;
      }

      .am-command-item {
        align-items: center;
        background: transparent;
        border: 0;
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-secondary);
        cursor: pointer;
        display: flex;
        font: inherit;
        gap: 1rem;
        justify-content: space-between;
        padding: 0.7rem 0.8rem;
        text-align: left;
      }

      .am-command-item:hover,
      .am-command-item:focus-visible,
      .am-command-item[data-active="true"] {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
        outline: none;
      }

      kbd {
        background: var(--ap-color-surface-sunken);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: 0.35rem;
        color: var(--ap-color-text-muted);
        font-size: 0.75rem;
        padding: 0.1rem 0.35rem;
      }
      CSS

      @commands : Array(Command)

      def initialize(@commands : Array(Command) = self.class.default_commands, **attrs)
        super(**attrs)
      end

      def self.default_commands : Array(Command)
        [
          Command.new("Toggle theme", "Cmd D"),
          Command.new("Capture screenshots", "Shift S"),
          Command.new("Open accessibility audit", "A"),
        ]
      end

      def render_content : String
        id = @attributes["id"]? || "am-command-#{object_id}"
        title = @attributes["title"]? || "Command palette"
        opener_label = @attributes["opener_label"]? || "Command"

        String.build do |io|
          io << %(<div class="am-command-component" data-component="command-palette">)
          io << %(<button class="am-button am-button--neutral am-button--outline am-button--sm" type="button" id="#{escape_html(id)}-opener" aria-haspopup="dialog" aria-controls="#{escape_html(id)}" data-amber-command-open="#{escape_html(id)}" data-ap-command-open="#{escape_html(id)}">#{escape_html(opener_label)}</button>)
          io << %(<div class="am-command-panel" id="#{escape_html(id)}" data-amber-command-panel data-ap-command-panel data-state="closed" role="dialog" aria-modal="true" aria-labelledby="#{escape_html(id)}-title" tabindex="-1">)
          io << %(<div class="am-window-chrome"><strong id="#{escape_html(id)}-title">#{escape_html(title)}</strong><button class="am-button am-button--neutral am-button--ghost am-button--sm" type="button" data-amber-command-close data-ap-command-close>Close</button></div>)
          io << %(<div class="am-command-list">)
          io << %(<label class="am-field" for="#{escape_html(id)}-search"><span>Search commands</span><input class="am-input" id="#{escape_html(id)}-search" type="search" data-amber-command-search data-ap-command-search placeholder="Type a command"></label>)
          @commands.each do |command|
            io << %(<button class="am-command-item" type="button"><span>#{escape_html(command.label)}</span><kbd>#{escape_html(command.shortcut)}</kbd></button>)
          end
          io << "</div></div></div>"
        end
      end
    end
  end
end
