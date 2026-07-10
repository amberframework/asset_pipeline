require "../base/stateless_component"
require "../elements/forms/form_controls"
require "../variants/component_variant"

module Components
  module Examples
    # Opinionated design-system button example.
    #
    # Current compatibility selectors are `am-button*`; legacy
    # Bootstrap-shaped `.btn` examples are intentionally not emitted.
    class ButtonComponent < StatelessComponent
      component_css <<-CSS
      .am-button {
        --am-button-bg: var(--ap-color-brand-primary);
        --am-button-bg-hover: var(--ap-color-brand-primary-hover);
        --am-button-border: transparent;
        --am-button-text: var(--ap-color-text-inverse);
        align-items: center;
        appearance: none;
        background: var(--am-button-bg);
        border: 1px solid var(--am-button-border);
        border-radius: var(--ap-radius-control);
        box-shadow: 0 1px 0 oklch(1 0 0 / 0.22) inset;
        color: var(--am-button-text);
        cursor: pointer;
        display: inline-flex;
        font-family: var(--ap-font-sans);
        font-weight: 680;
        gap: 0.5rem;
        justify-content: center;
        line-height: 1;
        min-height: 2.5rem;
        padding: 0.625rem 1rem;
        position: relative;
        text-decoration: none;
        transition: background var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          border-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          box-shadow var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          transform var(--ap-motion-duration-fast) var(--ap-motion-ease-emphasized);
        user-select: none;
      }

      .am-button:hover:not(:disabled):not([aria-disabled="true"]) {
        background: var(--am-button-bg-hover);
        box-shadow: var(--ap-elevation-raised);
        transform: translateY(-1px);
      }

      .am-button:active:not(:disabled):not([aria-disabled="true"]),
      .am-button[data-state="active"] {
        background: var(--ap-color-brand-primary-active);
        box-shadow: none;
        transform: translateY(0);
      }

      .am-button:focus {
        box-shadow: 0 0 0 3px var(--ap-color-focus-ring-solid);
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 3px;
      }

      .am-button:focus-visible {
        box-shadow: 0 0 0 3px var(--ap-color-focus-ring-solid);
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 3px;
      }

      .am-button:disabled,
      .am-button[aria-disabled="true"],
      .am-button[data-state="disabled"] {
        cursor: not-allowed;
        opacity: 0.56;
        transform: none;
      }

      .am-button[data-state="loading"] {
        cursor: progress;
      }

      .am-button[data-state="loading"]::before {
        animation: amber-button-spin 800ms linear infinite;
        border: 2px solid currentColor;
        border-right-color: transparent;
        border-radius: 50%;
        content: "";
        height: 0.875rem;
        width: 0.875rem;
      }

      .am-button--neutral {
        --am-button-bg: var(--ap-color-surface-elevated);
        --am-button-bg-hover: var(--ap-color-state-hover);
        --am-button-border: var(--ap-color-border-default);
        --am-button-text: var(--ap-color-text-primary);
      }

      .am-button--success {
        --am-button-bg: var(--ap-color-success-indicator);
        --am-button-bg-hover: var(--ap-color-success-border);
      }

      .am-button--warning {
        --am-button-bg: var(--ap-color-warning-indicator);
        --am-button-bg-hover: var(--ap-color-warning-border);
        --am-button-text: var(--ap-color-text-primary);
      }

      .am-button--danger {
        --am-button-bg: var(--ap-color-danger-indicator);
        --am-button-bg-hover: var(--ap-color-danger-border);
      }

      .am-button--info {
        --am-button-bg: var(--ap-color-info-indicator);
        --am-button-bg-hover: var(--ap-color-info-border);
      }

      .am-button--soft {
        background: var(--ap-color-state-selected);
        border-color: var(--ap-color-border-subtle);
        color: var(--ap-color-brand-primary-active);
      }

      .am-button--success.am-button--soft {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-button--warning.am-button--soft {
        background: var(--ap-color-warning-bg);
        border-color: var(--ap-color-warning-border);
        color: var(--ap-color-warning-text);
      }

      .am-button--danger.am-button--soft {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-button--info.am-button--soft {
        background: var(--ap-color-info-bg);
        border-color: var(--ap-color-info-border);
        color: var(--ap-color-info-text);
      }

      .am-button--outline {
        background: transparent;
        border-color: var(--am-button-bg);
        color: var(--am-button-bg);
      }

      .am-button--ghost {
        background: transparent;
        border-color: transparent;
        color: var(--am-button-bg);
        box-shadow: none;
      }

      .am-button--neutral.am-button--outline,
      .am-button--neutral.am-button--ghost {
        color: var(--ap-color-text-secondary);
      }

      .am-button--neutral.am-button--outline {
        border-color: var(--ap-color-border-default);
      }

      .am-button--sm {
        font-size: 0.875rem;
        min-height: 2rem;
        padding: 0.45rem 0.75rem;
      }

      .am-button--lg {
        font-size: 1.0625rem;
        min-height: 3rem;
        padding: 0.8rem 1.2rem;
      }

      .am-button__icon {
        align-items: center;
        display: inline-flex;
        font-size: 1em;
        justify-content: center;
      }

      .am-button:focus {
        box-shadow: 0 0 0 3px var(--ap-color-focus-ring-solid);
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 3px;
      }

      .am-button:focus-visible {
        box-shadow: 0 0 0 3px var(--ap-color-focus-ring-solid);
        outline: 2px solid var(--ap-color-focus-ring-solid);
        outline-offset: 3px;
      }

      @keyframes amber-button-spin {
        to { transform: rotate(360deg); }
      }

      @media (prefers-reduced-motion: reduce) {
        .am-button,
        .am-button:hover {
          transition-duration: 0.01ms;
          transform: none;
        }

        .am-button[data-state="loading"]::before {
          animation: none;
        }
      }
      CSS

      def render_content : String
        label = @attributes["label"]? || "Button"
        type = @attributes["type"]? || "button"
        tone = @attributes["tone"]? || @attributes["variant"]? || "brand"
        emphasis = @attributes["emphasis"]? || "solid"
        size = normalize_size(@attributes["size"]? || "md")
        state = @attributes["state"]? || "default"
        disabled = @attributes["disabled"]? == "true"
        loading = @attributes["loading"]? == "true" || state == "loading"
        selected = @attributes["selected"]? == "true" || state == "selected"

        variant = Components::Variants::ComponentVariant.new(
          family: "am-button",
          tone: normalize_tone(tone),
          emphasis: emphasis,
          size: size,
          state: disabled ? "disabled" : (loading ? "loading" : state),
        )

        button = Elements::Button.new(
          type: type,
          class: variant.classes
        )

        button.set_attribute("disabled", "disabled") if disabled
        button.set_attribute("data-state", disabled ? "disabled" : (loading ? "loading" : state))
        button.set_attribute("data-tone", normalize_tone(tone))
        button.set_attribute("data-emphasis", emphasis)
        button.set_attribute("aria-busy", "true") if loading
        button.set_attribute("aria-pressed", selected ? "true" : "false") if selected
        button.set_attribute("aria-disabled", "true") if disabled
        apply_passthrough_attributes(button)

        if icon = @attributes["icon"]?
          span = Elements::Span.new(class: "am-button__icon")
          span.set_attribute("aria-hidden", "true")
          span << icon
          button << span
          button << " "
        end

        button << label

        unless @children.empty?
          button << " "
          @children.each do |child|
            case child
            when Component
              button << child.render
            when Elements::HTMLElement
              button << child
            when Elements::RawHTML
              button << child
            when String
              button << child
            end
          end
        end

        button.render
      end

      private def normalize_size(value : String) : String
        case value
        when "small"  then "sm"
        when "medium" then "md"
        when "large"  then "lg"
        else               value
        end
      end

      private def normalize_tone(value : String) : String
        case value
        when "primary"     then "brand"
        when "secondary"   then "neutral"
        when "destructive" then "danger"
        else                    value
        end
      end

      private def apply_passthrough_attributes(button : Elements::Button) : Nil
        reserved = %w[label tone variant emphasis size state disabled loading selected icon]

        @attributes.each do |name, value|
          next if reserved.includes?(name)
          next unless passthrough_attribute?(name)

          button.set_attribute(name, value)
        end
      end

      private def passthrough_attribute?(name : String) : Bool
        name.starts_with?("data-") ||
          name.starts_with?("aria-") ||
          %w[id name value form title].includes?(name)
      end
    end
  end
end
