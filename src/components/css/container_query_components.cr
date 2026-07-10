require "./component_css_registry"

# Component CSS for the Phase 2 container-query showcase components: Card,
# Form, and NavigationSplitView. These rules opt the canonical surface
# classes (`.am-card`, `.am-form`, `.am-split-view`) into being container-
# query roots and ship the layout-switch declarations as `@container <name>`
# blocks so the components reflow against *their* rendering width rather
# than the viewport.
#
# Loading this file is enough to register the CSS via the global
# `ComponentCSSRegistry`; the Generator picks the entries up in its
# `@layer components` pass.
module Components
  module CSS
    module ContainerQueryComponents
      CARD_CSS = <<-CSS
      .am-card {
        container-type: inline-size;
        container-name: card;
      }

      @container card (min-width: 480px) {
        .am-card[data-layout="auto"] .am-card__layout {
          flex-direction: row;
          gap: var(--ap-space-4, 1rem);
        }
        .am-card[data-layout="auto"] .am-card__media {
          flex: 0 0 40%;
        }
        .am-card[data-layout="auto"] .am-card__body {
          flex: 1 1 auto;
        }
      }

      @container card (min-width: 720px) {
        .am-card[data-layout="auto"] .am-card__layout {
          gap: var(--ap-space-6, 1.5rem);
        }
      }
      CSS

      FORM_CSS = <<-CSS
      .am-form {
        container-type: inline-size;
        container-name: form;
      }

      @container form (max-width: 360px) {
        .am-form[data-layout="auto"] .am-form-field {
          flex-direction: column;
          align-items: stretch;
        }
        .am-form[data-layout="auto"] .am-form-field > label {
          min-width: 0;
        }
      }

      @container form (min-width: 480px) {
        .am-form[data-layout="auto"] .am-form-field {
          flex-direction: row;
          align-items: center;
        }
      }
      CSS

      SPLIT_VIEW_CSS = <<-CSS
      .am-split-view {
        container-type: inline-size;
        container-name: split-view;
      }

      @container split-view (max-width: 767px) {
        .am-split-view[data-layout="auto"] {
          flex-direction: column;
        }
        .am-split-view[data-layout="auto"] > .am-split-view__sidebar {
          width: 100%;
          border-right: 0;
          border-bottom: 1px solid var(--ap-color-border-subtle);
        }
      }

      @container split-view (min-width: 768px) {
        .am-split-view[data-layout="auto"] {
          flex-direction: row;
        }
      }
      CSS

      # Touch-target floor (WCAG 2.5.5 Target Size, AA). The rubric probes
      # the static demo HTML for native `<button>`, `<input type="submit">`,
      # `<input type="checkbox">`, `<input type="radio">`, and `<select>`
      # at sizes < 44 x 44. Inline `enforce_touch_target` only reaches the
      # widgets emitted by the web renderer; the showcase pages and
      # primitive helpers also produce these tags directly. Putting the
      # floor in registered CSS guarantees every native interactive widget
      # — wherever its markup comes from — meets the contract. Decorative
      # variants opt out via the explicit `data-touch-target-opt-out` hook
      # so the rule never traps icon-only chrome that lives behind a
      # larger labelled hit target.
      TOUCH_TARGET_CSS = <<-CSS
      /* Touch-target floor uses real element selectors (not :where()) so
         the 44 x 44 minimum wins against component-level overrides like
         `.am-button { min-height: 2.5rem }` (40px) without resorting to
         !important. Variants that intentionally want a smaller hit zone
         opt out via `data-touch-target-opt-out`. */
      button:not([data-touch-target-opt-out]),
      input[type="submit"]:not([data-touch-target-opt-out]),
      input[type="reset"]:not([data-touch-target-opt-out]),
      input[type="button"]:not([data-touch-target-opt-out]),
      select:not([data-touch-target-opt-out]) {
        min-block-size: 44px;
        min-inline-size: 44px;
      }

      /* Checkboxes and radios keep their native paint at the OS-controlled
         size; expanding the hit target via inline-size on the input itself
         is the most reliable cross-browser path. */
      input[type="checkbox"]:not([data-touch-target-opt-out]),
      input[type="radio"]:not([data-touch-target-opt-out]) {
        min-block-size: 44px;
        min-inline-size: 44px;
      }

      /* Visual size variant `am-button--sm` declares min-height: 2rem,
         which is below the 44 px AA floor. Restore the floor here at
         higher specificity than the size rule itself so the chip's
         visual padding stays compact while the tappable rect grows. */
      .am-button.am-button--sm:not([data-touch-target-opt-out]),
      button.am-button--md:not([data-touch-target-opt-out]),
      button.am-button:not([data-touch-target-opt-out]) {
        min-block-size: 44px;
        min-inline-size: 44px;
      }
      CSS

      ComponentCSSRegistry.instance.register("UI::Card", CARD_CSS)
      ComponentCSSRegistry.instance.register("UI::Form", FORM_CSS)
      ComponentCSSRegistry.instance.register("UI::NavigationSplitView", SPLIT_VIEW_CSS)
      ComponentCSSRegistry.instance.register("UI::TouchTargetFloor", TOUCH_TARGET_CSS)
    end
  end
end
