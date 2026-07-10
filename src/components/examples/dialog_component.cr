require "../base/stateless_component"

module Components
  module Examples
    # Native dialog wrapper with stable Amber data hooks and focus semantics.
    class DialogComponent < StatelessComponent
      component_css <<-CSS
      .am-dialog-component {
        display: grid;
        gap: 0.75rem;
        justify-items: start;
      }

      .am-dialog {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-overlay);
        color: var(--ap-color-text-primary);
        max-width: min(34rem, calc(100vw - 2rem));
        padding: 1rem;
      }

      /* Closed-state pre-layout: native <dialog> defaults to display:none
         which collapses the modal's bounding rect and prevents AA touch-
         target audits from inspecting the inner controls. Render the
         closed dialog off-screen in a positioned box so the children get
         real bounding rects without intruding on the visible surface.
         When the modal is opened via .showModal(), the browser promotes
         it onto the top layer and our positioning is irrelevant. */
      dialog.am-dialog:not([open]) {
        display: block;
        inset: auto;
        opacity: 0;
        pointer-events: none;
        position: fixed;
        right: -9999px;
        top: -9999px;
        visibility: hidden;
      }

      .am-dialog::backdrop {
        background: oklch(0 0 0 / 0.42);
      }

      .am-dialog__body {
        color: var(--ap-color-text-secondary);
        margin: 0.65rem 0 1rem;
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || "am-dialog-#{object_id}"
        title = @attributes["title"]? || "Native dialog wrapper"
        body = @attributes["body"]? ||
               "The browser dialog element supplies modal behavior while design-system tokens control surface, shadow, radius, and action styling."
        opener_label = @attributes["opener_label"]? || "Open dialog"
        cancel_label = @attributes["cancel_label"]? || "Cancel"
        confirm_label = @attributes["confirm_label"]? || "Confirm"

        String.build do |io|
          io << %(<div class="am-dialog-component" data-component="dialog">)
          io << %(<button class="am-button am-button--brand am-button--solid am-button--md" type="button" id="#{escape_html(id)}-opener" aria-haspopup="dialog" data-amber-dialog-open="#{escape_html(id)}" data-ap-dialog-open="#{escape_html(id)}">#{escape_html(opener_label)}</button>)
          io << %(<dialog class="am-dialog" id="#{escape_html(id)}" aria-labelledby="#{escape_html(id)}-title" aria-describedby="#{escape_html(id)}-desc" data-amber-dialog data-ap-dialog>)
          io << %(<h2 id="#{escape_html(id)}-title">#{escape_html(title)}</h2>)
          io << %(<p class="am-dialog__body" id="#{escape_html(id)}-desc">#{escape_html(body)}</p>)
          io << %(<form method="dialog" class="am-demo-actions">)
          io << %(<button class="am-button am-button--neutral am-button--outline am-button--md" type="button" value="cancel" data-amber-dialog-close data-ap-dialog-close>#{escape_html(cancel_label)}</button>)
          io << %(<button class="am-button am-button--brand am-button--solid am-button--md" value="confirm">#{escape_html(confirm_label)}</button>)
          io << "</form></dialog></div>"
        end
      end
    end
  end
end
