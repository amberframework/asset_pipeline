# Web platform renderer. Walks a UI::View tree and produces HTML by delegating
# to the Components::Elements system; accepts a per-request RenderContext.

require "../platform_visitor"
require "../../components"
require "../design_tokens"
require "../design_tokens/generators/web_generator"
require "json"
require "html"

module UI
  module Web
    # Renders a UI view tree to HTML using the Components::Elements system.
    #
    # The renderer walks the view tree via the visitor pattern and produces
    # an equivalent DOM tree built from `Components::Elements` classes.
    # Call `render` on a view to get the final HTML string.
    #
    # Example:
    #   label = UI::Label.new("Hello")
    #   renderer = UI::Web::Renderer.new
    #   label.accept(renderer)
    #   renderer.output # => "<span style=\"font-size: 17.0px; color: rgba(0, 0, 0, 1.0); text-align: left\">Hello</span>"
    class Renderer < UI::PlatformVisitor
      # Stack of elements being built. The top of the stack is the current
      # parent container that child elements will be added to.
      @element_stack : Array(Components::Elements::HTMLElement)

      # The root element produced by the most recent `visit` call at the
      # top level.
      @root : Components::Elements::HTMLElement?

      property theme : UI::Theme? = nil

      # Renderer-scoped context for the current `render` call. Set by
      # `render(view, render_context:)` and reset to the empty value
      # when no context is supplied. Read by `visit(UI::Form)` so the
      # form's web visit can inject the request CSRF token without the
      # author threading it through every Form construction.
      getter render_context : UI::RenderContext = UI::RenderContext.empty

      # The button instance to render as `type="submit"` regardless of
      # its declared `view.type`. Set ONLY by `visit(UI::Form)` when a
      # form's lone Button child is eligible for auto-promotion.
      # Reset to nil after the form visit completes so subsequent
      # standalone button renders are unaffected. Identity comparison
      # via `same?` ensures we promote only the specific instance, not
      # buttons that happen to share `type == Type::Button`.
      @auto_submit_button : UI::Button? = nil

      def initialize
        @element_stack = [] of Components::Elements::HTMLElement
        @root = nil
      end

      # The unified UI::DesignTokens model. Defaults to Tokens.default; can be
      # swapped (with a brand override applied) by the host app before render.
      property design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

      # Inject CSS custom properties from the active design tokens model as a
      # <style> element at the beginning of the output.
      #
      # Phase 1 of the cross-platform UI initiative: this delegates entirely
      # to UI::DesignTokens::WebGenerator so the renderer and the committed
      # dist file share a single source of truth. The legacy UI::Theme
      # custom-property block is emitted too for backward compatibility with
      # callers that depend on `--md-sys-color-*` aliases.
      def inject_theme_css : String
        t = @theme || UI::Theme.design_system_default

        String.build do |io|
          io << "<style>\n"
          io << t.to_css_custom_properties
          io << UI::DesignTokens::WebGenerator.generate(@design_tokens)
          io << "</style>\n"
        end
      end

      # Returns the rendered HTML string for the view tree.
      def output : String
        @root.try(&.render) || ""
      end

      # Convenience method: accept a view and return the HTML string.
      #
      # `render_context:` carries request-bound values that the visit
      # methods need but that don't belong on the view tree itself
      # (currently just the CSRF token; see `UI::RenderContext`). The
      # context is reset to `RenderContext.empty` after rendering so
      # subsequent calls don't leak the previous request's state.
      def render(view : UI::View, *, render_context : UI::RenderContext = UI::RenderContext.empty) : String
        @render_context = render_context
        view.accept(self)
        output
      ensure
        @render_context = UI::RenderContext.empty
      end

      # Render `view` wrapped in a full HTML5 document. Always emits the
      # responsive viewport meta tag, the charset, the supplied title, and
      # the active design-token `<style>` block (via `inject_theme_css`)
      # before the rendered view in `<body>`. Callers therefore never need
      # to hand-roll a `<head>` or remember the viewport meta — the
      # renderer owns that responsibility for any consumer.
      #
      # `lang` defaults to `"en"` and can be overridden for localized output.
      def render_document(view : UI::View, title : String, lang : String = "en") : String
        body_html = render(view)
        String.build do |str|
          str << "<!doctype html>\n"
          str << %(<html lang="#{lang}">) << '\n'
          str << "<head>\n"
          str << %(<meta charset="utf-8">) << '\n'
          str << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
          str << "<title>" << title << "</title>\n"
          str << inject_theme_css
          str << "</head>\n"
          str << "<body>\n"
          str << body_html
          str << "\n</body>\n"
          str << "</html>\n"
        end
      end

      # ---------------------------------------------------------------
      # Visit methods
      # ---------------------------------------------------------------

      def visit(view : UI::Label)
        el = Components::Elements::Span.new
        el << view.text

        # Font styles
        apply_font_styles(el, view.font)

        # Text color
        if role = view.text_color_role
          el.add_style("color: #{label_role_css(role)}")
        else
          el.add_style("color: #{color_css(view.text_color, default_token: "var(--ap-color-text-primary)")}")
        end

        # Text alignment
        el.add_style("text-align: #{alignment_to_css(view.text_alignment)}")

        # Line clamping
        if view.number_of_lines > 0
          el.add_style("display: -webkit-box; -webkit-line-clamp: #{view.number_of_lines}; -webkit-box-orient: vertical; overflow: hidden")
        end

        # Phase 6.11 — strikethrough toggle. Equivalent to SwiftUI's
        # `.strikethrough(true)` on UIKit / AppKit; on web we emit the
        # standard CSS `text-decoration: line-through`.
        if view.strikethrough
          el.add_style("text-decoration: line-through")
        end

        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Button)
        # Phase 8A Item 5 — honor view.type so submit/reset buttons can
        # drive a `<form>` submission. Single-button-form auto-promotion
        # is recorded as `@auto_submit_button` by `visit(UI::Form)` and
        # checked via identity here, so a shared view tree rendered
        # across requests is never mutated.
        effective_type = view.type
        if (auto = @auto_submit_button) && auto.same?(view)
          effective_type = UI::Button::Type::Submit
        end
        type_attr = case effective_type
                    in UI::Button::Type::Submit then "submit"
                    in UI::Button::Type::Reset  then "reset"
                    in UI::Button::Type::Button then "button"
                    end
        el = Components::Elements::Button.new(type: type_attr)
        el << view.label
        el.add_class(button_classes(view))
        el.set_attribute("data-component", "button")
        el.set_attribute("data-state", view.disabled ? "disabled" : "default")
        el.set_attribute("data-tone", button_tone(view))
        el.set_attribute("data-emphasis", button_emphasis(view))

        # Font styles
        apply_font_styles(el, view.font, emit_defaults: false)

        # Foreground color
        c = view.foreground_color
        default_button_color = UI::Color.new(r: 0.0, g: 0.478, b: 1.0)
        unless c == default_button_color
          el.add_style("color: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a})")
        end

        # Disabled state
        if view.disabled
          el.set_attribute("disabled", "disabled")
        end

        # Action identifier (data attribute for JS binding)
        if view.on_tap
          el.set_attribute("data-action", "click")
        end

        # Accessibility
        if label = view.accessibility_label
          el.set_attribute("aria-label", label)
        end

        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::VStack)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; gap: #{view.spacing}px")

        # Alignment maps to align-items for the cross axis
        el.add_style("align-items: #{stack_align_items(view.alignment)}")

        apply_common_styles(el, view)

        # Push as current parent, visit children, pop
        push_container(el) do
          view.children.each { |child| child.accept(self) }
        end
      end

      def visit(view : UI::HStack)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: row; gap: #{view.spacing}px")

        # Alignment maps to align-items for the cross axis
        el.add_style("align-items: #{stack_align_items(view.alignment)}")

        apply_common_styles(el, view)

        push_container(el) do
          view.children.each { |child| child.accept(self) }
        end
      end

      def visit(view : UI::ZStack)
        el = Components::Elements::Div.new
        el.add_style("position: relative")

        apply_common_styles(el, view)

        # ZStack children need position: absolute (except the first which
        # establishes the size). We track the index during iteration.
        @element_stack.push(el)
        view.children.each_with_index do |child, index|
          child.accept(self)
          # After visiting the child, the last child added to el needs
          # position: absolute if it's not the first child.
          if index > 0
            last_child = el.children.last?
            if last_child.is_a?(Components::Elements::HTMLElement)
              last_child.add_style("position: absolute; top: 0; left: 0")
            end
          end
        end
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Image)
        el = Components::Elements::Img.new
        el.set_attribute("src", view.source)
        el.set_attribute("alt", view.accessibility_label || view.source)

        # Content mode -> object-fit
        case view.content_mode
        when ContentMode::Fit
          el.add_style("object-fit: contain")
        when ContentMode::Fill
          el.add_style("object-fit: cover")
        when ContentMode::Stretch
          el.add_style("object-fit: fill")
        end

        # Tint color (CSS filter approach)
        if tint = view.tint_color
          el.add_style("filter: drop-shadow(0 0 0 rgba(#{to_rgb_int(tint.r)}, #{to_rgb_int(tint.g)}, #{to_rgb_int(tint.b)}, #{tint.a}))")
        end

        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::TextField)
        el = Components::Elements::Input.new

        # Input type based on secure_entry
        if view.secure_entry
          el.set_attribute("type", "password")
        else
          el.set_attribute("type", "text")
        end

        # Name attribute — required for browser form POST submission
        # when this field is inside a `<form>`. Emitted whenever the
        # author set a name; never auto-derived from placeholder.
        if (n = view.name) && !n.empty?
          el.set_attribute("name", n)
        end

        # Placeholder
        unless view.placeholder.empty?
          el.set_attribute("placeholder", view.placeholder)
        end

        # Current value
        unless view.text.empty?
          el.set_attribute("value", view.text)
        end

        # Keyboard type -> inputmode attribute
        case view.keyboard_type
        when KeyboardType::EmailAddress
          el.set_attribute("inputmode", "email")
        when KeyboardType::NumberPad
          el.set_attribute("inputmode", "numeric")
        when KeyboardType::PhonePad
          el.set_attribute("inputmode", "tel")
        when KeyboardType::URL
          el.set_attribute("inputmode", "url")
        end

        # Font and text color
        apply_font_styles(el, view.font)
        el.add_style("color: #{color_css(view.text_color, default_token: "var(--ap-color-text-primary)")}")

        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::ScrollView)
        el = Components::Elements::Div.new

        # Overflow based on scroll axes
        case {view.scroll_horizontal, view.scroll_vertical}
        when {true, true}
          el.add_style("overflow: auto")
        when {true, false}
          el.add_style("overflow-x: auto; overflow-y: hidden")
        when {false, true}
          el.add_style("overflow-x: hidden; overflow-y: auto")
        else
          el.add_style("overflow: hidden")
        end

        apply_common_styles(el, view)

        # Visit the content child if present
        if content = view.content
          push_container(el) do
            content.accept(self)
          end
        else
          push_element(el)
        end
      end

      def visit(view : UI::Spacer)
        el = Components::Elements::Div.new
        el.add_style("flex: 1 1 0%")

        if view.min_length > 0
          el.add_style("min-height: #{view.min_length}px; min-width: #{view.min_length}px")
        end

        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Toggle)
        # Render as a label with a checkbox input styled as a switch
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        # The actual toggle input
        input = Components::Elements::Input.new
        input.set_attribute("type", "checkbox")
        if view.is_on
          input.set_attribute("checked", "checked")
        end
        if view.style == UI::ToggleStyle::Switch
          input.add_style("appearance: none; width: 42px; height: 24px; border-radius: 12px; background: var(--ap-color-border-default); position: relative; cursor: pointer; transition: background var(--ap-motion-duration-fast) var(--ap-motion-ease-standard)")
        end
        if tint = view.tint_color
          input.add_style("accent-color: rgba(#{to_rgb_int(tint.r)}, #{to_rgb_int(tint.g)}, #{to_rgb_int(tint.b)}, #{tint.a})")
        end

        # The native checkbox input is the tappable target; the wrapping
        # <div> is decorative. Enforce on the input.
        enforce_touch_target(input)

        apply_common_styles(el, view)

        @element_stack.push(el)
        push_element(input)
        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          push_element(label_el)
        end
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Checkbox)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        input = Components::Elements::Input.new
        input.set_attribute("type", "checkbox")
        if view.is_checked
          input.set_attribute("checked", "checked")
        end

        enforce_touch_target(input)

        apply_common_styles(el, view)

        @element_stack.push(el)
        push_element(input)
        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          push_element(label_el)
        end
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::RadioGroup)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; gap: 4px")

        apply_common_styles(el, view)

        group_name = view.id || "radio_#{view.object_id}"

        @element_stack.push(el)
        view.options.each_with_index do |option, index|
          row = Components::Elements::Div.new
          row.add_style("display: flex; align-items: center; gap: 8px")

          input = Components::Elements::Input.new
          input.set_attribute("type", "radio")
          input.set_attribute("name", group_name)
          input.set_attribute("value", index.to_s)
          if index == view.selected_index
            input.set_attribute("checked", "checked")
          end

          label_el = Components::Elements::Span.new
          label_el << option

          # Build row manually
          @element_stack.push(row)
          push_element(input)
          push_element(label_el)
          @element_stack.pop
          push_element(row)
        end
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Slider)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          @element_stack.push(el)
          push_element(label_el)
          @element_stack.pop
        end

        input = Components::Elements::Input.new
        input.set_attribute("type", "range")
        input.set_attribute("min", view.minimum.to_s)
        input.set_attribute("max", view.maximum.to_s)
        input.set_attribute("value", view.value.to_s)
        if view.step > 0
          input.set_attribute("step", view.step.to_s)
        end
        if tint = view.tint_color
          input.add_style("accent-color: rgba(#{to_rgb_int(tint.r)}, #{to_rgb_int(tint.g)}, #{to_rgb_int(tint.b)}, #{tint.a})")
        end

        enforce_touch_target(input)

        apply_common_styles(el, view)

        @element_stack.push(el)
        push_element(input)
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::NavigationStack)
        # Render as a container with a nav bar and content area
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; height: 100%")

        if view.shows_navigation_bar
          nav_bar = Components::Elements::Div.new
          nav_bar.add_style("display: flex; align-items: center; padding: 12px 16px; border-bottom: 1px solid var(--ap-color-border-subtle)")

          if title = view.title
            title_el = Components::Elements::Span.new
            title_el << title
            if view.large_title
              title_el.add_style("font-size: 34px; font-weight: bold")
            else
              title_el.add_style("font-size: 17px; font-weight: 600")
            end
            nav_bar.add_child(title_el)
          end

          el.add_child(nav_bar)
        end

        content_area = Components::Elements::Div.new
        content_area.add_style("flex: 1; overflow: auto")

        apply_common_styles(el, view)

        # Render the current view (top of stack or root) into content area
        @element_stack.push(content_area)
        view.current_view.accept(self)
        @element_stack.pop

        el.add_child(content_area)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::NavigationLink)
        # Render as a clickable row with label and optional disclosure chevron
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px; padding: 12px 16px; cursor: pointer")
        el.set_attribute("role", "link")
        el.set_attribute("tabindex", "0")

        # Label text
        label_el = Components::Elements::Span.new
        label_el << view.label
        label_el.add_style("flex: 1")
        el.add_child(label_el)

        # Disclosure indicator
        if view.shows_disclosure
          chevron = Components::Elements::Span.new
          chevron << "›"
          chevron.add_style("color: var(--ap-color-text-muted); font-size: 20px")
          el.add_child(chevron)
        end

        apply_common_styles(el, view)
        enforce_touch_target(el)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::TabView)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; height: 100%")

        # Content area
        content_area = Components::Elements::Div.new
        content_area.add_style("flex: 1; overflow: auto")

        if content = view.current_content
          @element_stack.push(content_area)
          content.accept(self)
          @element_stack.pop
        end
        el.add_child(content_area)

        # Tab bar at bottom
        tab_bar = Components::Elements::Div.new
        tab_bar.add_style("display: flex; border-top: 1px solid var(--ap-color-border-subtle); padding: 8px 0")
        tab_bar.set_attribute("role", "tablist")

        view.tabs.each_with_index do |tab, index|
          tab_el = Components::Elements::Div.new
          tab_el.add_style("flex: 1; text-align: center; padding: 4px; cursor: pointer")
          tab_el.set_attribute("role", "tab")
          if index == view.selected_index
            tab_el.set_attribute("aria-selected", "true")
            tab_el.add_style("color: var(--ap-color-brand-primary); font-weight: 600")
          else
            tab_el.add_style("color: var(--ap-color-text-muted)")
          end

          label_span = Components::Elements::Span.new
          label_span << tab.label
          tab_el.add_child(label_span)
          tab_bar.add_child(tab_el)
        end

        el.add_child(tab_bar)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::ProgressView)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        progress_el = Components::Elements::Div.new
        progress_el.set_attribute("role", "progressbar")

        case view.style
        when UI::ProgressStyle::Linear
          progress_el.add_style("width: 100%; height: 4px; background: var(--ap-color-border-subtle); border-radius: var(--ap-radius-pill); overflow: hidden")
          if val = view.value
            inner = Components::Elements::Div.new
            inner.add_style("height: 100%; width: #{(val * 100).round}%; background: var(--ap-color-brand-primary)")
            progress_el.add_child(inner)
            progress_el.set_attribute("aria-valuenow", (val * 100).round.to_s)
            progress_el.set_attribute("aria-valuemin", "0")
            progress_el.set_attribute("aria-valuemax", "100")
          else
            progress_el.add_style("animation: progress-indeterminate 1.5s linear infinite")
          end
        when UI::ProgressStyle::Circular
          size = 24
          progress_el.add_style("width: #{size}px; height: #{size}px; border-radius: 50%; border: 3px solid var(--ap-color-border-subtle); border-top-color: var(--ap-color-brand-primary)")
          if view.value.nil?
            progress_el.add_style("animation: spin 1s linear infinite")
          end
        end

        el.add_child(progress_el)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::ActivityIndicator)
        el = Components::Elements::Div.new
        el.set_attribute("role", "status")
        el.add_style("display: inline-flex; align-items: center; justify-content: center")

        size_px = case view.size
                  when :small then 16
                  when :large then 48
                  else             24
                  end

        spinner = Components::Elements::Div.new
        spinner.add_style("width: #{size_px}px; height: #{size_px}px; border-radius: 50%; border: 2px solid var(--ap-color-border-subtle); border-top-color: var(--ap-color-brand-primary)")

        if view.is_animating
          spinner.add_style("animation: spin 1s linear infinite")
        else
          spinner.add_style("opacity: 0.3")
        end

        el.add_child(spinner)
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Alert)
        # Render as a modal overlay with title, message, and buttons
        el = Components::Elements::Div.new
        el.set_attribute("role", "alertdialog")
        el.set_attribute("aria-modal", "true")
        el.add_style("position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: oklch(0.18 0.02 248 / 0.42); display: flex; align-items: center; justify-content: center; z-index: 1000")

        dialog = Components::Elements::Div.new
        # Dialog reflows from a 260px floor through 80vw up to 270px on phones,
        # and from 280px through 90vw up to 400px on tablets/desktop. Padding
        # also scales from 16px (small viewports) through 4vw up to 24px.
        dialog.add_style("background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); border-radius: var(--ap-radius-panel); padding: #{fluid_px(16, 4, 24)}; min-width: #{fluid_px(260, 80, 270)}; max-width: #{fluid_px(280, 90, 400)}; box-shadow: var(--ap-elevation-overlay)")

        title_el = Components::Elements::Span.new
        title_el << view.title
        title_el.add_style("display: block; font-size: 17px; font-weight: 600; text-align: center; margin-bottom: 8px")
        dialog.add_child(title_el)

        unless view.message.empty?
          msg_el = Components::Elements::Span.new
          msg_el << view.message
          msg_el.add_style("display: block; font-size: 13px; text-align: center; color: var(--ap-color-text-secondary); margin-bottom: 16px")
          dialog.add_child(msg_el)
        end

        el.add_child(dialog)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Picker)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; gap: 4px")

        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          el.add_child(label_el)
        end

        select_el = Components::Elements::Div.new
        select_el.set_attribute("role", "combobox")
        select_el.add_style("border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); padding: 8px 12px; cursor: pointer; background: var(--ap-color-surface-panel)")

        view.options.each_with_index do |option, index|
          opt_el = Components::Elements::Div.new
          opt_el.set_attribute("role", "option")
          opt_el.add_style("padding: 4px 8px")
          if index == view.selected_index
            opt_el.set_attribute("aria-selected", "true")
            opt_el.add_style("font-weight: 600")
          end
          opt_span = Components::Elements::Span.new
          opt_span << option
          opt_el.add_child(opt_span)
          select_el.add_child(opt_el)
        end

        el.add_child(select_el)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::IconButton)
        el = Components::Elements::Button.new(type: "button")
        el.set_attribute("aria-label", view.label || view.icon)
        el.add_style("display: inline-flex; align-items: center; justify-content: center; cursor: pointer; border: none; background: transparent; padding: 4px")

        if view.disabled
          el.set_attribute("disabled", "disabled")
        end

        icon_el = Components::Elements::Span.new
        icon_el << view.icon
        icon_el.add_style("font-size: #{view.icon_size}px")
        el.add_child(icon_el)

        if lbl = view.label
          lbl_el = Components::Elements::Span.new
          lbl_el << lbl
          el.add_child(lbl_el)
        end

        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::ListView)
        el = Components::Elements::Div.new
        el.set_attribute("role", "list")
        el.add_style("display: flex; flex-direction: column")

        apply_common_styles(el, view)

        push_container(el) do
          view.sections.each do |section|
            if header = section.header
              header_el = Components::Elements::Span.new
              header_el << header
              header_el.add_style("font-size: 13px; font-weight: 600; color: var(--ap-color-text-muted); padding: 8px 16px")
              push_element(header_el)
            end

            section.items.each do |item|
              row = Components::Elements::Div.new
              row.set_attribute("role", "listitem")
              row.add_style("padding: 12px 16px")
              @element_stack.push(row)
              item.accept(self)
              @element_stack.pop
              push_element(row)
            end

            if footer = section.footer
              footer_el = Components::Elements::Span.new
              footer_el << footer
              footer_el.add_style("font-size: 12px; color: var(--ap-color-text-muted); padding: 4px 16px")
              push_element(footer_el)
            end
          end
        end
      end

      def visit(view : UI::OutlineView)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::ColumnView)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::TokenField)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::ImageWell)
        view.fallback_view.accept(self)
      end

      def visit(view : UI::SecureField)
        el = Components::Elements::Input.new
        el.set_attribute("type", "password")

        if (n = view.name) && !n.empty?
          el.set_attribute("name", n)
        end

        unless view.placeholder.empty?
          el.set_attribute("placeholder", view.placeholder)
        end

        unless view.text.empty?
          el.set_attribute("value", view.text)
        end

        apply_font_styles(el, view.font)
        el.add_style("color: #{color_css(view.text_color, default_token: "var(--ap-color-text-primary)")}")

        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::Stepper)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          el.add_child(label_el)
        end

        minus_btn = Components::Elements::Button.new(type: "button")
        minus_btn << "-"
        minus_btn.add_style("width: 32px; height: 32px; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); cursor: pointer")
        enforce_touch_target(minus_btn)
        el.add_child(minus_btn)

        value_el = Components::Elements::Span.new
        value_el << view.value.to_s
        # The numeric value display is not a touch target; it just needs a
        # readable width that scales with the surrounding viewport.
        value_el.add_style("min-width: #{fluid_px(40, 12, 56)}; text-align: center")
        el.add_child(value_el)

        plus_btn = Components::Elements::Button.new(type: "button")
        plus_btn << "+"
        plus_btn.add_style("width: 32px; height: 32px; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); cursor: pointer")
        enforce_touch_target(plus_btn)
        el.add_child(plus_btn)

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::SegmentedControl)
        el = Components::Elements::Div.new
        el.add_style("display: inline-flex; border: 1px solid var(--ap-color-brand-primary); border-radius: var(--ap-radius-control); overflow: hidden")

        view.segments.each_with_index do |segment, index|
          seg_el = Components::Elements::Div.new
          seg_el.set_attribute("role", "button")
          seg_el.add_style("padding: 6px 16px; cursor: pointer; font-size: 14px")
          if index == view.selected_index
            seg_el.add_style("background: var(--ap-color-brand-primary); color: var(--ap-color-text-inverse)")
          else
            seg_el.add_style("background: transparent; color: var(--ap-color-brand-primary)")
          end
          if index > 0
            seg_el.add_style("border-left: 1px solid var(--ap-color-brand-primary)")
          end
          # Each segment is independently tappable; enforce touch target on
          # the segment itself, not the parent strip.
          enforce_touch_target(seg_el)
          seg_span = Components::Elements::Span.new
          seg_span << segment
          seg_el.add_child(seg_span)
          el.add_child(seg_el)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::DatePicker)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          el.add_child(label_el)
        end

        input = Components::Elements::Input.new
        case view.mode
        when UI::DatePickerMode::Date
          input.set_attribute("type", "date")
        when UI::DatePickerMode::Time
          input.set_attribute("type", "time")
        when UI::DatePickerMode::DateAndTime
          input.set_attribute("type", "datetime-local")
        end
        input.add_style("border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); padding: 6px 12px; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary)")
        enforce_touch_target(input)
        el.add_child(input)

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::TimePicker)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          el.add_child(label_el)
        end

        input = Components::Elements::Input.new
        input.set_attribute("type", "time")
        if view.minute_interval > 1
          input.set_attribute("step", (view.minute_interval * 60).to_s)
        end
        input.add_style("border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); padding: 6px 12px; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary)")
        enforce_touch_target(input)
        el.add_child(input)

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::SearchField)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")

        input = Components::Elements::Input.new
        input.set_attribute("type", "search")
        unless view.placeholder.empty?
          input.set_attribute("placeholder", view.placeholder)
        end
        unless view.text.empty?
          input.set_attribute("value", view.text)
        end
        input.add_style("flex: 1; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-pill); padding: 8px 16px; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary)")
        enforce_touch_target(input)
        el.add_child(input)

        if view.shows_cancel_button && view.is_searching
          cancel = Components::Elements::Button.new(type: "button")
          cancel << "Cancel"
          cancel.add_style("border: none; background: transparent; color: var(--ap-color-brand-primary); cursor: pointer")
          el.add_child(cancel)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::TextArea)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column")

        # Use a div styled as textarea (since we don't have a textarea element class)
        textarea = Components::Elements::Div.new
        textarea.set_attribute("contenteditable", view.is_editable ? "true" : "false")
        textarea.set_attribute("role", "textbox")
        textarea.set_attribute("aria-multiline", "true")
        textarea.add_style("border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); padding: 8px; min-height: 80px; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary)")
        enforce_touch_target(textarea)

        if view.text.empty? && !view.placeholder.empty?
          textarea << view.placeholder
          textarea.add_style("color: var(--ap-color-text-muted)")
        else
          textarea << view.text
        end

        if !view.is_scrollable
          textarea.add_style("overflow: hidden")
        end

        apply_font_styles(textarea, view.font)
        c = view.text_color
        unless view.text.empty?
          textarea.add_style("color: #{color_css(c, default_token: "var(--ap-color-text-primary)")}")
        end

        el.add_child(textarea)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Grid)
        el = Components::Elements::Div.new
        col_count = view.column_count
        if col_count > 0
          el.add_style("display: grid; grid-template-columns: repeat(#{col_count}, 1fr); gap: #{view.row_spacing}px #{view.column_spacing}px")
        else
          el.add_style("display: grid; gap: #{view.row_spacing}px #{view.column_spacing}px")
        end

        apply_common_styles(el, view)

        push_container(el) do
          view.children.each do |row|
            row.each do |cell|
              cell_wrapper = Components::Elements::Div.new
              @element_stack.push(cell_wrapper)
              cell.accept(self)
              @element_stack.pop
              push_element(cell_wrapper)
            end
          end
        end
      end

      def visit(view : UI::Form)
        # Phase 8A Item 2 — when `view.action` is non-nil, wrap the
        # existing section/flat-children rendering in an HTML <form>
        # element with method + action + injected CSRF hidden input.
        # When action is nil the original (pre-Phase-8A) rendering is
        # preserved exactly so native + non-form web usage are unchanged.
        if view.action
          render_web_form_wrapper(view)
        else
          render_web_form_unwrapped(view)
        end
      end

      private def render_web_form_wrapper(view : UI::Form)
        action = view.action.not_nil!
        # Form element wraps the chrome div so the browser submits.
        form_el = Components::Elements::Form.new
        form_el.set_attribute("action", action)
        form_el.set_attribute("method", view.method.upcase)
        form_el.add_class("am-form")
        form_el.set_attribute("data-component", "form")
        form_el.set_attribute("data-layout", "auto")
        form_el.add_style("display: flex; flex-direction: column; gap: 16px")
        apply_common_styles(form_el, view)

        # Inject the CSRF hidden input. Constructor-supplied wins over
        # renderer-context-threaded.
        csrf = view.csrf_token || @render_context.csrf_token
        if csrf && !csrf.empty?
          csrf_input = Components::Elements::Input.new
          csrf_input.set_attribute("type", "hidden")
          csrf_input.set_attribute("name", "_csrf")
          csrf_input.set_attribute("value", csrf)
          form_el.add_child(csrf_input)
        end

        # Compute single-button auto-promotion: a form with exactly one
        # Button child whose type is the default Type::Button is
        # rendered as `type="submit"` so a browser submits the form.
        # Identity-tagged on the renderer; never mutates view.type.
        @auto_submit_button = single_default_button_for_autopromote(view)

        push_container(form_el) do
          emit_form_sections(view)
          # Flat children render inline AFTER section chrome so authors
          # can mix grouped + flat content if needed.
          view.children.each { |child| child.accept(self) }
        end
      ensure
        @auto_submit_button = nil
      end

      private def render_web_form_unwrapped(view : UI::Form)
        el = Components::Elements::Div.new
        el.set_attribute("role", "form")
        el.add_class("am-form")
        el.set_attribute("data-component", "form")
        el.set_attribute("data-layout", "auto")
        el.add_style("display: flex; flex-direction: column; gap: 16px")
        apply_common_styles(el, view)

        push_container(el) do
          emit_form_sections(view)
          view.children.each { |child| child.accept(self) }
        end
      end

      private def emit_form_sections(view : UI::Form) : Nil
        view.sections.each do |section|
          section_el = Components::Elements::Div.new
          section_el.add_style("display: flex; flex-direction: column; gap: 8px")

          if header = section.header
            header_el = Components::Elements::Span.new
            header_el << header
            header_el.add_style("font-size: 13px; font-weight: 600; color: var(--ap-color-text-muted); text-transform: uppercase; padding: 0 16px")
            section_el.add_child(header_el)
          end

          section.fields.each do |field|
            field_el = Components::Elements::Div.new
            field_el.add_class("am-form-field")
            field_el.add_style("display: flex; align-items: center; gap: 8px; padding: 12px 16px; background: var(--ap-color-surface-panel); border-bottom: 1px solid var(--ap-color-border-subtle)")

            unless field.label.empty?
              label_el = Components::Elements::Span.new
              label_el << field.label
              label_el.add_style("min-width: #{fluid_px(80, 22, 120)}; color: var(--ap-color-text-secondary)")
              field_el.add_child(label_el)
            end

            if content = field.content
              @element_stack.push(field_el)
              content.accept(self)
              @element_stack.pop
            end

            section_el.add_child(field_el)
          end

          if footer = section.footer
            footer_el = Components::Elements::Span.new
            footer_el << footer
            footer_el.add_style("font-size: 12px; color: var(--ap-color-text-muted); padding: 4px 16px")
            section_el.add_child(footer_el)
          end

          push_element(section_el)
        end
      end

      # Returns the lone Button eligible for auto-promotion to
      # `Type::Submit`, or nil. A button is eligible iff:
      #   1. It is the only `UI::Button` in the ENTIRE form tree —
      #      flat children, section field contents, AND any nested
      #      container's recursive descendants. Per Phase 8A brief
      #      Item 5: "Auto-promotion only happens when EXACTLY ONE
      #      button child exists in the entire form tree."
      #   2. Its `type` is still the default `Type::Button` (author did
      #      not explicitly opt to Submit or Reset).
      # Author behavior: multi-button forms (cancel + save, etc.) must
      # set `type: UI::Button::Type::Submit` explicitly on the intended
      # submitter — no surprising "last button wins" convention.
      private def single_default_button_for_autopromote(view : UI::Form) : UI::Button?
        buttons = [] of UI::Button
        collect_form_buttons(view, buttons)
        return nil unless buttons.size == 1
        candidate = buttons.first
        return nil unless candidate.type == UI::Button::Type::Button
        candidate
      end

      private def collect_form_buttons(form : UI::Form, buttons : Array(UI::Button)) : Nil
        form.sections.each do |section|
          section.fields.each do |field|
            if content = field.content
              collect_buttons_in_subtree(content, buttons)
            end
          end
        end
        form.children.each do |child|
          collect_buttons_in_subtree(child, buttons)
        end
      end

      private def collect_buttons_in_subtree(view : UI::View, buttons : Array(UI::Button)) : Nil
        case view
        when UI::Button
          buttons << view
        when UI::Form
          # A nested form has its own auto-promotion lifecycle and
          # MUST be excluded from the outer form's button budget.
        when UI::VStack
          view.children.each { |c| collect_buttons_in_subtree(c, buttons) }
        when UI::HStack
          view.children.each { |c| collect_buttons_in_subtree(c, buttons) }
        when UI::ZStack
          view.children.each { |c| collect_buttons_in_subtree(c, buttons) }
        when UI::ScrollView
          if content = view.content
            collect_buttons_in_subtree(content, buttons)
          end
        end
      end

      def visit(view : UI::NavigationSplitView)
        el = Components::Elements::Div.new
        el.add_class("am-split-view")
        el.set_attribute("data-component", "split-view")
        # Opt into container-query layout switching (sidebar overlays content
        # below 768 px container, sidebar inline at 768 px+).
        el.set_attribute("data-layout", "auto")
        el.add_style("display: flex; height: 100%")

        if view.shows_sidebar
          if sidebar = view.sidebar
            sidebar_el = Components::Elements::Div.new
            sidebar_el.add_class("am-split-view__sidebar")
            # Sidebar reflows from 220px floor through a 30vw curve up to
            # the caller-specified ceiling so it adapts to wider monitors
            # without overrunning on phones.
            sidebar_el.add_style("width: #{fluid_with_floor(220, "30vw", view.sidebar_width)}; border-right: 1px solid var(--ap-color-border-subtle); overflow-y: auto")
            @element_stack.push(sidebar_el)
            sidebar.accept(self)
            @element_stack.pop
            el.add_child(sidebar_el)
          end
        end

        if content = view.content
          content_el = Components::Elements::Div.new
          content_el.add_style("flex: 1; overflow-y: auto")
          @element_stack.push(content_el)
          content.accept(self)
          @element_stack.pop
          el.add_child(content_el)
        end

        if detail = view.detail
          detail_el = Components::Elements::Div.new
          detail_el.add_style("flex: 1; overflow-y: auto")
          @element_stack.push(detail_el)
          detail.accept(self)
          @element_stack.pop
          el.add_child(detail_el)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Toolbar)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px; padding: 8px 16px; border-bottom: 1px solid var(--ap-color-border-subtle); background: var(--ap-color-surface-sunken)")
        el.set_attribute("role", "toolbar")

        if view.shows_title
          if title = view.title
            title_el = Components::Elements::Span.new
            title_el << title
            title_el.add_style("font-weight: 600; margin-right: auto")
            el.add_child(title_el)
          end
        end

        view.items.each do |item|
          btn = Components::Elements::Button.new(type: "button")
          btn.add_style("border: none; background: transparent; cursor: pointer; padding: 4px 8px")
          btn.set_attribute("aria-label", item.label)
          btn << item.label
          el.add_child(btn)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Sheet)
        el = Components::Elements::Div.new
        if view.is_presented
          el.add_style("position: fixed; bottom: 0; left: 0; right: 0; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); border-radius: var(--ap-radius-panel) var(--ap-radius-panel) 0 0; box-shadow: var(--ap-elevation-overlay); z-index: 900; transition: transform var(--ap-motion-duration-base) var(--ap-motion-ease-standard)")
          case view.selected_detent
          when :small  then el.add_style("max-height: 25vh")
          when :medium then el.add_style("max-height: 50vh")
          when :large  then el.add_style("max-height: 90vh")
          end
        else
          el.add_style("display: none")
        end

        if view.shows_drag_indicator
          indicator = Components::Elements::Div.new
          indicator.add_style("width: 36px; height: 5px; background: var(--ap-color-border-default); border-radius: var(--ap-radius-pill); margin: 8px auto")
          el.add_child(indicator)
        end

        if content = view.content
          content_el = Components::Elements::Div.new
          content_el.add_style("padding: 16px; overflow-y: auto")
          @element_stack.push(content_el)
          content.accept(self)
          @element_stack.pop
          el.add_child(content_el)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Popover)
        el = Components::Elements::Div.new
        if view.is_presented
          el.add_style("position: absolute; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-card); box-shadow: var(--ap-elevation-floating); z-index: 800; padding: 12px")
          if w = view.preferred_width
            el.add_style("width: #{w}px")
          end
          if h = view.preferred_height
            el.add_style("height: #{h}px")
          end
        else
          el.add_style("display: none")
        end

        if content = view.content
          @element_stack.push(el)
          content.accept(self)
          @element_stack.pop
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::ConfirmationDialog)
        el = Components::Elements::Div.new
        el.set_attribute("role", "alertdialog")
        el.set_attribute("aria-modal", "true")
        if view.is_presented
          el.add_style("position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: oklch(0.18 0.02 248 / 0.42); display: flex; align-items: center; justify-content: center; z-index: 1000")
        else
          el.add_style("display: none")
        end

        dialog = Components::Elements::Div.new
        dialog.add_style("background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); border-radius: var(--ap-radius-panel); padding: #{fluid_px(16, 4, 24)}; min-width: #{fluid_px(260, 80, 270)}; max-width: #{fluid_px(280, 90, 400)}; box-shadow: var(--ap-elevation-overlay)")

        title_el = Components::Elements::Span.new
        title_el << view.title
        title_el.add_style("display: block; font-size: 17px; font-weight: 600; text-align: center; margin-bottom: 8px")
        dialog.add_child(title_el)

        unless view.message.empty?
          msg_el = Components::Elements::Span.new
          msg_el << view.message
          msg_el.add_style("display: block; font-size: 13px; text-align: center; color: var(--ap-color-text-secondary); margin-bottom: 16px")
          dialog.add_child(msg_el)
        end

        buttons_el = Components::Elements::Div.new
        buttons_el.add_style("display: flex; gap: 8px; justify-content: center")

        cancel_btn = Components::Elements::Button.new(type: "button")
        cancel_btn << view.cancel_label
        cancel_btn.add_style("padding: 8px 24px; border-radius: var(--ap-radius-control); border: 1px solid var(--ap-color-border-default); background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); cursor: pointer")
        enforce_touch_target(cancel_btn)
        buttons_el.add_child(cancel_btn)

        confirm_btn = Components::Elements::Button.new(type: "button")
        confirm_btn << view.confirm_label
        if view.confirm_style == :destructive
          confirm_btn.add_style("padding: 8px 24px; border-radius: var(--ap-radius-control); border: none; background: var(--ap-color-danger-indicator); color: var(--ap-color-text-inverse); cursor: pointer")
        else
          confirm_btn.add_style("padding: 8px 24px; border-radius: var(--ap-radius-control); border: none; background: var(--ap-color-brand-primary); color: var(--ap-color-text-inverse); cursor: pointer")
        end
        enforce_touch_target(confirm_btn)
        buttons_el.add_child(confirm_btn)

        dialog.add_child(buttons_el)
        el.add_child(dialog)

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Snackbar)
        el = Components::Elements::Div.new
        if view.is_presented
          el.add_style("position: fixed; bottom: 16px; left: 50%; transform: translateX(-50%); background: var(--ap-color-surface-inverse); color: var(--ap-color-text-inverse); padding: 12px 24px; border-radius: var(--ap-radius-card); display: flex; align-items: center; gap: 16px; z-index: 950; box-shadow: var(--ap-elevation-floating)")
        else
          el.add_style("display: none")
        end

        msg = Components::Elements::Span.new
        msg << view.message
        el.add_child(msg)

        if action = view.action_label
          btn = Components::Elements::Button.new(type: "button")
          btn << action
          btn.add_style("border: none; background: transparent; color: var(--ap-color-brand-accent); font-weight: 600; cursor: pointer; text-transform: uppercase")
          el.add_child(btn)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Card)
        el = Components::Elements::Div.new
        el.add_class("am-card")
        el.add_class(view.is_outlined ? "am-card--outline" : "am-card--elevated")
        el.set_attribute("data-component", "card")
        el.set_attribute("data-elevation", view.elevation.to_s)
        # Opt into container-query layout switching (vertical stack below
        # 480px container, horizontal split above).
        el.set_attribute("data-layout", "auto")
        el.add_style("overflow: hidden")

        if content = view.content
          @element_stack.push(el)
          content.accept(self)
          @element_stack.pop
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Surface)
        el = Components::Elements::Div.new
        case view.shape
        when :rounded then el.add_style("border-radius: 12px")
        when :circle  then el.add_style("border-radius: 50%")
        end

        if view.elevation > 0
          shadow_y = (view.elevation * 2).round
          shadow_blur = (view.elevation * 4).round
          el.add_style("box-shadow: 0 #{shadow_y}px #{shadow_blur}px oklch(0.18 0.02 248 / 0.1)")
        end

        if content = view.content
          @element_stack.push(el)
          content.accept(self)
          @element_stack.pop
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::Divider)
        el = Components::Elements::Div.new
        c = view.color
        color_css = "rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a})"
        if view.orientation == :horizontal
          el.add_style("height: #{view.thickness}px; background: #{color_css}; width: 100%")
        else
          el.add_style("width: #{view.thickness}px; background: #{color_css}; height: 100%")
        end
        el.set_attribute("role", "separator")

        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::GlassBackground)
        el = Components::Elements::Div.new

        # Phase 5 v2: glass material follows the quantizer model. Brand
        # intensity selects the EFFECTIVE ThicknessStep via
        # `material.resolve(declared).name`; the inline style + class
        # suffix key off the effective step (NOT the declared step). The
        # WebGenerator emits per-step `--ap-material-*` constants without
        # intensity scaling — the renderer's effective-step selection is
        # the entire mechanism by which brand intensity reaches the
        # rendered CSS. See brief.yml adapter_cardinality row 2.
        resolved = @design_tokens.material.resolve(view.material)
        step_key = material_css_step_key(resolved.name)
        el.add_class("ap-glass")
        el.add_class("ap-glass--#{step_key}")
        el.add_style(
          "backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
          "-webkit-backdrop-filter: blur(var(--ap-material-blur-#{step_key})) saturate(var(--ap-material-saturation-#{step_key})); " \
          "background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{step_key}) * 100%), transparent); " \
          "border-radius: inherit"
        )

        if content = view.content
          @element_stack.push(el)
          content.accept(self)
          @element_stack.pop
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # Map a `GlassBackground#material` Symbol to the CSS class suffix /
      # custom-property segment. Unknown symbols fall back to `regular`.
      private def material_css_step_key(name : Symbol) : String
        case name
        when :ultra_thin then "ultra-thin"
        when :thin       then "thin"
        when :regular    then "regular"
        when :thick      then "thick"
        when :chrome     then "chrome"
        else                  "regular"
        end
      end

      # ---------------------------------------------------------------
      # P2 Wave 3 Visit methods
      # ---------------------------------------------------------------

      def visit(view : UI::AsyncImage)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative")
        if view.is_loading
          spinner = Components::Elements::Div.new
          spinner.add_style("width: 24px; height: 24px; border-radius: 50%; border: 2px solid var(--ap-color-border-subtle); border-top-color: var(--ap-color-brand-primary); animation: spin 1s linear infinite")
          el.add_child(spinner)
        elsif !view.url.empty?
          img = Components::Elements::Img.new
          img.set_attribute("src", view.url)
          img.set_attribute("loading", "lazy")
          case view.content_mode
          when UI::ContentMode::Fit     then img.add_style("object-fit: contain")
          when UI::ContentMode::Fill    then img.add_style("object-fit: cover")
          when UI::ContentMode::Stretch then img.add_style("object-fit: fill")
          end
          el.add_child(img)
        end
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::RichText)
        el = Components::Elements::Div.new
        el.add_style("text-align: #{alignment_to_css(view.text_alignment)}")
        view.spans.each do |span|
          span_el = Components::Elements::Span.new
          span_el << span.text
          styles = [] of String
          c = span.color
          styles << "color: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a})"
          styles << "font-weight: bold" if span.bold
          styles << "font-style: italic" if span.italic
          styles << "text-decoration: underline" if span.underline
          styles << "text-decoration: line-through" if span.strikethrough
          styles.each { |s| span_el.add_style(s) }
          if link = span.link
            span_el.add_style("cursor: pointer; color: var(--ap-color-brand-primary)")
            span_el.set_attribute("data-href", link)
          end
          el.add_child(span_el)
        end
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::LinkButton)
        el = Components::Elements::Div.new
        el.set_attribute("role", "link")
        el.set_attribute("tabindex", "0")
        el.add_style("color: var(--ap-color-brand-primary); cursor: pointer; display: inline")
        unless view.url.empty?
          el.set_attribute("data-href", view.url)
        end
        el << view.label
        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::MenuButton)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative")
        btn = Components::Elements::Button.new(type: "button")
        btn << view.label
        btn.add_style("display: flex; align-items: center; gap: 4px; padding: 6px 12px; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); cursor: pointer")
        enforce_touch_target(btn)
        el.add_child(btn)

        if !view.items.empty?
          menu = Components::Elements::Div.new
          menu.add_style("position: absolute; top: 100%; left: 0; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-card); box-shadow: var(--ap-elevation-floating); min-width: #{fluid_px(150, 40, 240)}; z-index: 100")
          menu.set_attribute("role", "menu")
          view.items.each do |item|
            item_el = Components::Elements::Div.new
            item_el.set_attribute("role", "menuitem")
            item_el.add_style("padding: 8px 16px; cursor: pointer")
            if item.is_destructive
              item_el.add_style("color: var(--ap-color-danger-text)")
            end
            item_el << item.label
            menu.add_child(item_el)
          end
          el.add_child(menu)
        end

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # Phase 4 — Tier 3. UI::ContextMenu is Apple-family only (flag?(:macos)
      # || flag?(:ios)); on those builds the web renderer must still
      # satisfy the abstract visit method (web renderer compiles on every
      # target). The visitor is a no-op — the cross-platform web rendering
      # path is UI::ContextMenuWithWebFallback (below).
      {% if flag?(:macos) || flag?(:ios) %}
        def visit(view : UI::ContextMenu)
          el = Components::Elements::Div.new
          el.set_attribute("role", "menu")
          el.set_attribute("data-component", "context-menu-noop")
          el.add_style("display: none")
          apply_common_styles(el, view)
          if parent = @element_stack.last?
            parent.as(Components::Elements::ContainerElement).add_child(el)
          else
            @root = el
          end
        end
      {% end %}

      # Web rendering of the cross-platform ContextMenu companion. Produces
      # a host element with the trigger as a child and a hidden role=menu
      # ul ready to be positioned by the vanilla-JS fallback.
      def visit(view : UI::ContextMenuWithWebFallback)
        host = Components::Elements::Div.new
        host.set_attribute("data-ap-ctx-host", "true")
        host.add_class("ap-ctx-menu-host")

        # Render the trigger first so the fallback JS finds it as the
        # first non-menu, non-style/script child of the host. When the
        # developer didn't pass a trigger, we render no trigger and the
        # JS attaches nothing automatically (the developer remains
        # responsible for toggling data-presented on the menu element).
        if trigger = view.trigger
          @element_stack.push(host)
          trigger.accept(self)
          @element_stack.pop
        end

        menu = Components::Elements::Ul.new
        menu.add_class("ap-ctx-menu")
        menu.set_attribute("role", "menu")
        menu.set_attribute("data-presented", "false")

        view.items.each_with_index do |entry, index|
          case entry
          when UI::ContextMenuWithWebFallback::Separator
            sep = Components::Elements::Li.new
            sep.set_attribute("role", "separator")
            sep.add_class("ap-ctx-menu__separator")
            menu.add_child(sep)
          when UI::ContextMenuWithWebFallback::Item
            li = Components::Elements::Li.new
            li.set_attribute("role", "none")
            btn = Components::Elements::Button.new(type: "button")
            btn.set_attribute("role", "menuitem")
            btn.add_class("ap-ctx-menu__item")
            btn.add_class("ap-ctx-menu__item--destructive") if entry.is_destructive
            if entry.is_disabled
              btn.set_attribute("aria-disabled", "true")
              btn.set_attribute("disabled", "disabled")
            end
            btn.set_attribute("data-ap-ctx-action", index.to_s)
            if icon = entry.icon
              icon_el = Components::Elements::Span.new
              icon_el.set_attribute("aria-hidden", "true")
              icon_el << icon
              btn.add_child(icon_el)
            end
            label_el = Components::Elements::Span.new
            label_el << entry.label
            btn.add_child(label_el)
            li.add_child(btn)
            menu.add_child(li)
          end
        end

        host.add_child(menu)

        unless @context_menu_css_emitted
          @context_menu_css_emitted = true
          style_block = Components::Elements::Style.new
          style_block << CONTEXT_MENU_FALLBACK_CSS
          host.add_child(style_block)

          script_block = Components::Elements::Script.new
          script_block << CONTEXT_MENU_FALLBACK_JS
          host.add_child(script_block)
        end

        apply_common_styles(host, view)
        push_element(host)
      end

      @context_menu_css_emitted : Bool = false

      CONTEXT_MENU_FALLBACK_CSS = <<-CSS
      .ap-ctx-menu-host { position: relative; display: contents; }
      .ap-ctx-menu {
        position: fixed;
        list-style: none; margin: 0; padding: 4px;
        min-width: 200px;
        background: var(--ap-color-surface-panel);
        color: var(--ap-color-text-primary);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-floating);
        z-index: 900;
        display: none;
      }
      .ap-ctx-menu[data-presented="true"] { display: block; }
      .ap-ctx-menu__item {
        display: flex; align-items: center; gap: 8px;
        width: 100%;
        min-height: 32px; padding: 0 12px;
        background: transparent; border: none;
        color: inherit; font: inherit;
        text-align: left; cursor: pointer;
        border-radius: 6px;
      }
      .ap-ctx-menu__item:hover,
      .ap-ctx-menu__item:focus-visible {
        background: var(--ap-color-surface-hover);
        outline: none;
      }
      .ap-ctx-menu__item--destructive { color: var(--ap-color-danger-text); }
      .ap-ctx-menu__item[aria-disabled="true"] {
        color: var(--ap-color-text-muted);
        cursor: not-allowed;
      }
      .ap-ctx-menu__separator {
        height: 1px;
        margin: 4px 0;
        background: var(--ap-color-border-subtle);
      }
      CSS

      CONTEXT_MENU_FALLBACK_JS = {{ read_file("#{__DIR__}/../web/context_menu_fallback.js") }}

      def visit(view : UI::ToggleButton)
        el = Components::Elements::Button.new(type: "button")
        el.set_attribute("role", "switch")
        el.set_attribute("aria-checked", view.is_selected.to_s)
        if view.is_selected
          el.add_style("background: var(--ap-color-brand-primary); color: var(--ap-color-text-inverse); border: none; padding: 8px 16px; border-radius: var(--ap-radius-control); cursor: pointer")
        else
          el.add_style("background: transparent; color: var(--ap-color-text-secondary); border: 1px solid var(--ap-color-border-default); padding: 8px 16px; border-radius: var(--ap-radius-control); cursor: pointer")
        end
        el << view.label
        apply_common_styles(el, view)
        enforce_touch_target(el)
        push_element(el)
      end

      def visit(view : UI::TextEditor)
        el = Components::Elements::Div.new
        el.add_style("display: flex; flex-direction: column; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); overflow: hidden")

        if view.shows_line_numbers
          el.add_style("font-family: monospace")
        end

        editor = Components::Elements::Div.new
        editor.set_attribute("contenteditable", view.is_editable ? "true" : "false")
        editor.set_attribute("role", "textbox")
        editor.set_attribute("aria-multiline", "true")
        editor.add_style("padding: 12px; min-height: 200px; outline: none; white-space: pre-wrap")
        apply_font_styles(editor, view.font)
        c = view.text_color
        editor.add_style("color: #{color_css(c, default_token: "var(--ap-color-text-primary)")}")

        if view.text.empty? && !view.placeholder.empty?
          editor << view.placeholder
          editor.add_style("color: var(--ap-color-text-muted)")
        else
          editor << view.text
        end

        el.add_child(editor)
        apply_common_styles(el, view)

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # ---------------------------------------------------------------
      # P3 Stub Visit methods
      # ---------------------------------------------------------------

      def visit(view : UI::Circle)
        el = Components::Elements::Div.new
        c = view.fill_color
        el.add_style("width: #{view.size}px; height: #{view.size}px; border-radius: 50%; background: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a}); display: inline-block")
        if sc = view.stroke_color
          el.add_style("border: #{view.stroke_width}px solid rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})")
        end
        el.set_attribute("data-component", "circle")
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Rectangle)
        el = Components::Elements::Div.new
        c = view.fill_color
        el.add_style("width: #{view.width}px; height: #{view.height}px; background: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a}); display: inline-block")
        if sc = view.stroke_color
          el.add_style("border: #{view.stroke_width}px solid rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})")
        end
        el.set_attribute("data-component", "rectangle")
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::RoundedRectangle)
        el = Components::Elements::Div.new
        c = view.fill_color
        el.add_style("width: #{view.width}px; height: #{view.height}px; border-radius: #{view.corner_radius}px; background: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a}); display: inline-block")
        if sc = view.stroke_color
          el.add_style("border: #{view.stroke_width}px solid rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})")
        end
        el.set_attribute("data-component", "rounded-rectangle")
        el.set_attribute("data-corner-style", view.corner_style.to_s)
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Capsule)
        el = Components::Elements::Div.new
        c = view.fill_color
        el.add_style("width: #{view.width}px; height: #{view.height}px; border-radius: 9999px; background: rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a}); display: inline-block")
        if sc = view.stroke_color
          el.add_style("border: #{view.stroke_width}px solid rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})")
        end
        el.set_attribute("data-component", "capsule")
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Canvas)
        el = Components::Elements::Div.new
        el.add_style("width: #{view.width}px; height: #{view.height}px; position: relative; overflow: hidden; display: inline-block")
        el.set_attribute("role", "img")
        el.set_attribute("data-component", "canvas")
        el.set_attribute("data-width", view.width.to_s)
        el.set_attribute("data-height", view.height.to_s)
        el.set_attribute("data-operations", view.operations.size.to_s)
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::PathView)
        el = Components::Elements::Div.new
        el.add_style("width: #{view.width}px; height: #{view.height}px; display: inline-block")
        sc = view.stroke_color
        stroke_css = "rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})"
        fill_css = if fc = view.fill_color
                     c = fc
                     "rgba(#{to_rgb_int(c.r)}, #{to_rgb_int(c.g)}, #{to_rgb_int(c.b)}, #{c.a})"
                   else
                     "none"
                   end
        el.set_attribute("data-component", "path")
        el.set_attribute("data-path", view.to_svg_path)
        el.set_attribute("data-stroke", stroke_css)
        el.set_attribute("data-fill", fill_css)
        el.set_attribute("data-stroke-width", view.stroke_width.to_s)
        apply_common_styles(el, view)
        push_element(el)
      end

      # Phase 4 — Tier 3. UI::PathControl is macOS-only (flag?(:macos)); on
      # -Dmacos builds the web renderer still compiles and must satisfy
      # the abstract method, so a no-op visitor lives here. The
      # cross-platform web rendering path is UI::PathControlWithWebFallback.
      {% if flag?(:macos) %}
        def visit(view : UI::PathControl)
          el = Components::Elements::Div.new
          el.set_attribute("data-component", "path-control-noop")
          el.add_style("display: none")
          apply_common_styles(el, view)
          push_element(el)
        end
      {% end %}

      # Cross-platform breadcrumb rendering. Emits a semantic
      # `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` with the current
      # leaf marked aria-current="page" — a notable improvement on the
      # `>`-separated string the previous visitor produced.
      def visit(view : UI::PathControlWithWebFallback)
        nav = Components::Elements::Nav.new
        nav.set_attribute("aria-label", "Breadcrumb")
        nav.add_style("display: inline-flex; align-items: center; padding: 6px 10px; border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-card); background: var(--ap-color-surface-panel)")

        ol = Components::Elements::Ol.new
        ol.add_style("list-style: none; margin: 0; padding: 0; display: inline-flex; align-items: center; gap: 6px")

        view.components.each_with_index do |component, index|
          li = Components::Elements::Li.new
          li.add_style("display: inline-flex; align-items: center; gap: 4px")

          last = index == view.components.size - 1
          inner_wrapper : Components::Elements::HTMLElement
          if url = component.url
            anchor = Components::Elements::A.new
            anchor.set_attribute("href", url)
            anchor.add_style("color: var(--ap-color-text-link); text-decoration: none")
            anchor.set_attribute("aria-current", "page") if last
            inner_wrapper = anchor
          else
            span = Components::Elements::Span.new
            span.add_style("color: var(--ap-color-text-primary)")
            span.set_attribute("aria-current", "page") if last
            inner_wrapper = span
          end

          if icon = component.icon
            icon_el = Components::Elements::Span.new
            icon_el.set_attribute("aria-hidden", "true")
            icon_el << icon
            inner_wrapper.as(Components::Elements::ContainerElement).add_child(icon_el)
          end
          name_el = Components::Elements::Span.new
          name_el << component.name
          inner_wrapper.as(Components::Elements::ContainerElement).add_child(name_el)
          li.add_child(inner_wrapper)
          ol.add_child(li)

          unless last
            sep = Components::Elements::Li.new
            sep.set_attribute("aria-hidden", "true")
            sep.add_style("color: var(--ap-color-text-muted)")
            sep << "/"
            ol.add_child(sep)
          end
        end

        if view.style == UI::PathControlStyle::PopUp
          popup = Components::Elements::Span.new
          popup.set_attribute("aria-hidden", "true")
          popup.add_style("margin-left: 6px; color: var(--ap-color-text-muted)")
          popup << "v"
          nav.add_child(ol)
          nav.add_child(popup)
        else
          nav.add_child(ol)
        end

        apply_common_styles(nav, view)
        push_element(nav)
      end

      def visit(view : UI::MapView)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative; overflow: hidden; background: var(--ap-color-surface-sunken)")
        el.set_attribute("data-component", "map")
        el.set_attribute("data-latitude", view.latitude.to_s)
        el.set_attribute("data-longitude", view.longitude.to_s)
        el.set_attribute("data-zoom", view.zoom_level.to_s)
        el.set_attribute("data-map-type", view.map_type.to_s)
        el.set_attribute("data-shows-user-location", view.shows_user_location.to_s)
        el.set_attribute("data-annotation-count", view.annotations.size.to_s)
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::ChartView)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative")
        el.set_attribute("data-component", "chart")
        el.set_attribute("data-chart-type", view.chart_type.to_s)
        el.set_attribute("data-title", view.title)
        el.set_attribute("data-point-count", view.data_points.size.to_s)
        el.set_attribute("data-show-legend", view.show_legend.to_s)
        el.set_attribute("data-show-grid", view.show_grid.to_s)
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::WebViewComponent)
        el = Components::Elements::Iframe.new
        el.add_style("display: block; width: 100%; min-height: 280px; border: 0; border-radius: var(--ap-radius-panel); overflow: hidden; background: var(--ap-color-surface-panel)")
        el.set_attribute("loading", "lazy")
        el.set_attribute("src", view.url) unless view.url.empty?
        if html = view.html
          el.set_attribute("srcdoc", html)
        end
        if t = view.title
          el.set_attribute("title", t)
        end
        unless view.allows_navigation && view.allows_scripts
          sandbox = [] of String
          sandbox << "allow-forms" if view.allows_navigation
          sandbox << "allow-same-origin"
          sandbox << "allow-scripts" if view.allows_scripts
          el.set_attribute("sandbox", sandbox.join(' '))
        end
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::ColorPicker)
        el = Components::Elements::Div.new
        el.add_style("display: flex; align-items: center; gap: 8px")
        unless view.label.empty?
          label_el = Components::Elements::Span.new
          label_el << view.label
          el.add_child(label_el)
        end
        input = Components::Elements::Input.new
        input.set_attribute("type", "color")
        c = view.selected_color
        hex = "#%02x%02x%02x" % {to_rgb_int(c.r), to_rgb_int(c.g), to_rgb_int(c.b)}
        input.set_attribute("value", hex)
        if view.supports_alpha
          input.set_attribute("data-supports-alpha", "true")
        end
        enforce_touch_target(input)
        el.add_child(input)
        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      def visit(view : UI::VideoPlayer)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative; background: #000")
        el.set_attribute("data-component", "video")
        el.set_attribute("data-src", view.url)
        el.set_attribute("data-autoplay", view.auto_play.to_s)
        el.set_attribute("data-muted", view.muted.to_s)
        el.set_attribute("data-loop", view.loop.to_s)
        el.set_attribute("data-controls", view.shows_controls.to_s)
        if poster = view.poster_url
          el.set_attribute("data-poster", poster)
        end
        apply_common_styles(el, view)
        push_element(el)
      end

      def visit(view : UI::Tooltip)
        el = Components::Elements::Div.new
        el.add_style("display: inline-block; position: relative")
        el.set_attribute("data-component", "tooltip")
        el.set_attribute("data-tooltip", view.text)
        el.set_attribute("data-position", view.position.to_s)
        el.set_attribute("data-delay", view.delay.to_s)
        if view.is_visible
          el.set_attribute("data-visible", "true")
        end
        if content = view.content
          @element_stack.push(el)
          content.accept(self)
          @element_stack.pop
        end
        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # ActivityView -> semantic HTML share-sheet approximation.
      # Web rendering: popover-style card with all four zones.
      def visit(view : UI::ActivityView)
        el = Components::Elements::Div.new
        # Phase 5 v2: ActivityView's translucent surface picks the EFFECTIVE
        # thickness step via the v2 quantizer. HIG-canonical declared step
        # is `:thick` (matches the iOS/macOS Apple semantic `Sheet` and the
        # SwiftUI `.thickMaterial` analogue). Inline style references the
        # `--ap-material-*` constants for the effective step so both the
        # backdrop-filter live path and the @supports color-mix fallback
        # cascade. See brief.yml adapter_cardinality row 2.
        activity_resolved = @design_tokens.material.resolve(:thick)
        activity_key = material_css_step_key(activity_resolved.name)
        el.add_class("ap-glass")
        el.add_class("ap-glass--#{activity_key}")
        el.add_style("background: color-mix(in oklch, var(--ap-color-surface-panel) calc(var(--ap-material-opacity-#{activity_key}) * 100%), transparent); backdrop-filter: blur(var(--ap-material-blur-#{activity_key})) saturate(var(--ap-material-saturation-#{activity_key})); -webkit-backdrop-filter: blur(var(--ap-material-blur-#{activity_key})) saturate(var(--ap-material-saturation-#{activity_key})); border: 1px solid var(--ap-color-border-subtle); border-radius: var(--ap-radius-panel); box-shadow: var(--ap-elevation-overlay); color: var(--ap-color-text-primary); padding: #{fluid_px(12, 3, 16)}; max-width: #{fluid_px(280, 92, 480)}; display: flex; flex-direction: column; gap: 12px")
        el.set_attribute("role", "dialog")
        el.set_attribute("aria-label", view.title)

        # Zone 1: Header
        header = Components::Elements::Div.new
        header.add_style("display: flex; flex-direction: row; align-items: center; gap: 12px")
        title_el = Components::Elements::Div.new
        title_el.add_style("font-size: 15px; font-weight: 600")
        title_el << view.title
        if sub = view.subtitle
          sub_el = Components::Elements::Div.new
          sub_el.add_style("font-size: 13px; color: var(--ap-color-text-muted)")
          sub_el << sub
          title_el.add_child(sub_el)
        end
        header.add_child(title_el)
        el.add_child(header)

        # Zone 2: Destination row
        dest_row = Components::Elements::Div.new
        dest_row.add_style("display: flex; flex-direction: row; gap: 16px; overflow-x: auto; padding-bottom: 4px")
        view.destinations.each do |dest|
          dest_item = Components::Elements::Div.new
          dest_item.add_style("display: flex; flex-direction: column; align-items: center; gap: 4px; min-width: 60px")
          icon_el = Components::Elements::Div.new
          icon_el.add_style("width: 60px; height: 60px; border-radius: 30px; background: var(--ap-color-surface-elevated); display: flex; align-items: center; justify-content: center; font-size: 24px")
          icon_el.set_attribute("aria-label", dest.icon_symbol)
          lbl_el = Components::Elements::Div.new
          lbl_el.add_style("font-size: 11px; color: var(--ap-color-text-secondary); text-align: center")
          lbl_el << dest.label
          dest_item.add_child(icon_el)
          dest_item.add_child(lbl_el)
          dest_row.add_child(dest_item)
        end
        el.add_child(dest_row)

        # Zone 3: Action grid (2-col)
        grid = Components::Elements::Div.new
        grid.add_style("display: grid; grid-template-columns: 1fr 1fr; gap: 8px")
        view.actions.each do |act|
          tile = Components::Elements::Div.new
          tile.add_style("display: flex; flex-direction: row; align-items: center; gap: 8px; background: var(--ap-color-surface-elevated); border-radius: var(--ap-radius-card); padding: 10px 12px")
          icon_span = Components::Elements::Div.new
          icon_span.set_attribute("aria-label", act.icon_symbol)
          icon_span.add_style("width: 28px; height: 28px; border-radius: var(--ap-radius-control); background: var(--ap-color-surface-elevated); display: flex; align-items: center; justify-content: center")
          lbl_span = Components::Elements::Div.new
          lbl_span << act.label
          color = act.role == :destructive ? "var(--ap-color-danger-text)" : "inherit"
          lbl_span.add_style("font-size: 13px; color: #{color}")
          tile.add_child(icon_span)
          tile.add_child(lbl_span)
          grid.add_child(tile)
        end
        el.add_child(grid)

        # Zone 4: Cancel button
        cancel_el = Components::Elements::Div.new
        cancel_el.add_style("font-size: 17px; font-weight: 600; color: var(--ap-color-brand-primary); text-align: center; padding: 12px; cursor: pointer; border-radius: var(--ap-radius-card); background: var(--ap-color-surface-elevated)")
        cancel_el << "Cancel"
        el.add_child(cancel_el)

        apply_common_styles(el, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # DisclosureGroup -> <details>/<summary> HTML element.
      # Uses the native HTML disclosure widget: <details> (collapsed by
      # default) and <summary> (the clickable header row). When
      # expanded = true, the details element is given the open attribute.
      def visit(view : UI::DisclosureGroup)
        details = Components::Elements::Div.new
        open_attr = view.expanded ? " open" : ""
        details.add_style("display: block")
        details.set_attribute("role", "group")
        details.set_attribute("aria-expanded", view.expanded ? "true" : "false")

        # Header row: chevron indicator + title
        header_div = Components::Elements::Div.new
        header_div.add_style("display: flex; flex-direction: row; align-items: center; gap: 6px; cursor: pointer; user-select: none; font-size: 17px; padding: 4px 0")
        acc_text = view.accessibility_label || "#{view.title}, #{view.expanded ? "expanded" : "collapsed"}"
        header_div.set_attribute("aria-label", acc_text)
        chevron = Components::Elements::Div.new
        chevron.add_style("font-size: 12px; color: var(--ap-color-text-muted); transition: transform var(--ap-motion-duration-fast) var(--ap-motion-ease-standard)")
        # Right-pointing = collapsed (U+276F ❯); down-pointing = expanded (U+276F rotated)
        chevron_char = view.expanded ? "\u25BC" : "\u25B6"
        chevron << chevron_char
        header_div.add_child(chevron)
        title_span = Components::Elements::Div.new
        title_span.add_style("font-size: 17px; font-weight: 400")
        title_span << view.title
        header_div.add_child(title_span)
        details.add_child(header_div)

        # Content block: shown when expanded = true
        if view.expanded && !view.content.empty?
          content_div = Components::Elements::Div.new
          content_div.add_style("display: flex; flex-direction: column; gap: 4px; padding-left: 20px; padding-top: 4px")
          push_container(content_div) do
            view.content.each do |child|
              child.accept(self)
            end
          end
          details.add_child(content_div)
        end

        apply_common_styles(details, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(details)
        else
          @root = details
        end
      end

      # ---------------------------------------------------------------
      # PageControl -> a flex row of dot <span> elements.
      # ---------------------------------------------------------------
      def visit(view : UI::PageControl)
        total = [view.total, 1].max
        current = view.current.clamp(0, total - 1)

        container = Components::Elements::Div.new
        container.add_style("display: flex; flex-direction: row; align-items: center; gap: 6px; justify-content: center")
        acc_label = view.accessibility_label || "Page #{current + 1} of #{total}"
        container.set_attribute("role", "tablist")
        container.set_attribute("aria-label", acc_label)

        total.times do |i|
          dot = Components::Elements::Div.new
          is_current = (i == current)
          size = is_current ? "8px" : "7px"
          if is_current
            fill_color = if tc = view.tint_color
                           "rgba(#{(tc.r * 255).to_i}, #{(tc.g * 255).to_i}, #{(tc.b * 255).to_i}, #{tc.a})"
                         else
                           "var(--ap-color-brand-primary)"
                         end
            dot.add_style("width: #{size}; height: #{size}; border-radius: 50%; background-color: #{fill_color}; flex-shrink: 0")
          else
            stroke_color = if tc = view.tint_color
                             "rgba(#{(tc.r * 255).to_i}, #{(tc.g * 255).to_i}, #{(tc.b * 255).to_i}, 0.4)"
                           else
                             "color-mix(in oklch, var(--ap-color-brand-primary) 40%, transparent)"
                           end
            dot.add_style("width: #{size}; height: #{size}; border-radius: 50%; border: 1px solid #{stroke_color}; background-color: transparent; flex-shrink: 0")
          end
          dot.set_attribute("role", "tab")
          dot.set_attribute("aria-selected", is_current ? "true" : "false")
          container.add_child(dot)
        end

        apply_common_styles(container, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(container)
        else
          @root = container
        end
      end

      # ---------------------------------------------------------------
      # ComboBox -> <input list="..."> + <datalist> (HTML5 native combo)
      # ---------------------------------------------------------------
      def visit(view : UI::ComboBox)
        # <datalist> holds the preset options; <input list="..."> links to it.
        list_id = "combo-#{view.object_id}"

        # Outer <div> wrapper so width constraints work cleanly.
        outer = Components::Elements::Div.new
        outer.add_style("display: flex; align-items: center; position: relative")

        # <datalist> element
        datalist = Components::Elements::Div.new
        datalist.set_attribute("id", list_id)
        # We emit datalist as a generic Div (no native datalist class in
        # Components::Elements) — callers who need true HTML5 behaviour
        # should use the raw HTML emit path. This web renderer is a stub
        # for doc/test purposes only.
        datalist.set_attribute("data-role", "datalist")
        view.options.each do |opt|
          option_el = Components::Elements::Div.new
          option_el.set_attribute("data-value", opt)
          datalist.add_child(option_el)
        end
        outer.add_child(datalist)

        # <input> element styled as a combo box field
        input_el = Components::Elements::Div.new
        input_el.set_attribute("data-role", "combobox-input")
        input_el.set_attribute("list", list_id)
        unless view.value.empty?
          input_el.set_attribute("value", view.value)
        end
        unless view.placeholder.empty?
          input_el.set_attribute("placeholder", view.placeholder)
        end
        if acc = view.accessibility_label
          input_el.set_attribute("aria-label", acc)
        end
        input_el.set_attribute("role", "combobox")
        input_el.set_attribute("aria-expanded", "false")
        input_el.set_attribute("aria-haspopup", "listbox")
        input_el.add_style("display: flex; border: 1px solid var(--ap-color-border-default); border-radius: var(--ap-radius-control); padding: 8px 32px 8px 8px; font-size: 13px; width: 100%; box-sizing: border-box; background: var(--ap-color-surface-panel); color: var(--ap-color-text-primary)")

        outer.add_child(input_el)

        apply_common_styles(outer, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(outer)
        else
          @root = outer
        end
      end

      # ---------------------------------------------------------------
      # RatingIndicator -> a row of star span elements (CSS flexbox)
      # ---------------------------------------------------------------
      def visit(view : UI::RatingIndicator)
        outer = Components::Elements::Div.new
        outer.add_style("display: flex; align-items: center; gap: 4px")

        clamped = view.value.clamp(0.0, view.max.to_f64)
        filled_count = clamped.round.to_i

        # Resolve tint color string (CSS rgb). Default: system yellow.
        tint_css = if tc = view.tint_color
                     "rgb(#{(tc.r * 255).round}, #{(tc.g * 255).round}, #{(tc.b * 255).round})"
                   else
                     "rgb(255, 204, 0)"
                   end

        view.max.times do |i|
          star = Components::Elements::Div.new
          star.set_attribute("aria-hidden", "true")
          # Use Unicode star characters: filled = U+2605, outlined = U+2606
          star.set_attribute("data-star", i < filled_count ? "filled" : "empty")
          star.add_style("font-size: 20px; color: #{tint_css}; user-select: none")
          outer.add_child(star)
        end

        if acc = view.accessibility_label
          outer.set_attribute("aria-label", acc)
        else
          outer.set_attribute("aria-label", "#{filled_count} out of #{view.max} stars")
        end
        outer.set_attribute("role", "img")

        apply_common_styles(outer, view)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(outer)
        else
          @root = outer
        end
      end

      # ---------------------------------------------------------------
      # Private helpers
      # ---------------------------------------------------------------

      private def label_role_css(role : UI::LabelRole) : String
        case role
        when UI::LabelRole::Primary
          "var(--ap-color-text-primary)"
        when UI::LabelRole::Secondary
          "var(--ap-color-text-secondary)"
        when UI::LabelRole::Tertiary, UI::LabelRole::Quaternary
          "var(--ap-color-text-muted)"
        else
          "var(--ap-color-text-primary)"
        end
      end

      private def color_css(color : UI::Color, default_token : String? = nil) : String
        if default_token && color == UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
          default_token
        else
          "rgba(#{to_rgb_int(color.r)}, #{to_rgb_int(color.g)}, #{to_rgb_int(color.b)}, #{color.a})"
        end
      end

      # Apply common View base-class styles to any element.
      private def apply_common_styles(el : Components::Elements::HTMLElement, view : UI::View)
        # Padding
        p = view.padding
        if p.top != 0.0 || p.trailing != 0.0 || p.bottom != 0.0 || p.leading != 0.0
          el.add_style("padding: #{p.top}px #{p.trailing}px #{p.bottom}px #{p.leading}px")
        end

        # Background color
        if bg = view.background
          el.add_style("background-color: rgba(#{to_rgb_int(bg.r)}, #{to_rgb_int(bg.g)}, #{to_rgb_int(bg.b)}, #{bg.a})")
        end

        # Hidden
        if view.hidden
          el.add_style("display: none")
        end

        # Opacity
        if view.opacity < 1.0
          el.add_style("opacity: #{view.opacity}")
        end

        # Corner radius
        if view.corner_radius > 0
          el.add_style("border-radius: #{view.corner_radius}px")
        end

        # Clip to bounds
        if view.clip_to_bounds
          el.add_style("overflow: hidden")
        end

        # Shadow
        if view.shadow_radius > 0
          sc = view.shadow_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0, a: 0.3)
          el.add_style("box-shadow: #{view.shadow_offset_x}px #{view.shadow_offset_y}px #{view.shadow_radius}px rgba(#{to_rgb_int(sc.r)}, #{to_rgb_int(sc.g)}, #{to_rgb_int(sc.b)}, #{sc.a})")
        end

        # Border
        if view.border_width > 0
          bc = view.border_color || UI::Color.new(r: 0.0, g: 0.0, b: 0.0)
          el.add_style("border: #{view.border_width}px solid rgba(#{to_rgb_int(bc.r)}, #{to_rgb_int(bc.g)}, #{to_rgb_int(bc.b)}, #{bc.a})")
        end

        # Blur
        if view.blur_radius > 0
          el.add_style("filter: blur(#{view.blur_radius}px)")
        end

        # Size constraints. `fluid_width` / `fluid_height` take precedence
        # over the legacy `minimum_*` / `maximum_*` pair because clamp()
        # already encodes the floor + ceiling. When only one channel is
        # fluid, the other still falls back to the legacy min/max pair.
        if fw = view.fluid_width
          el.add_style("width: #{fw.to_css}")
        else
          if min_w = view.minimum_width
            el.add_style("min-width: #{min_w}px")
          end
          if max_w = view.maximum_width
            el.add_style("max-width: #{max_w}px")
          end
        end

        if fh = view.fluid_height
          el.add_style("height: #{fh.to_css}")
        else
          if min_h = view.minimum_height
            el.add_style("min-height: #{min_h}px")
          end
          if max_h = view.maximum_height
            el.add_style("max-height: #{max_h}px")
          end
        end

        # Phase 6.10 Rem 4 (Item 2D) — root_fill on web maps to
        # `width: 100%; min-height: 100dvh`. `dvh` (dynamic viewport
        # height) respects mobile browser address-bar resizing — newer
        # iOS Safari / Chrome shrinks the visible viewport when the URL
        # bar is visible and 100vh would overflow there.
        #
        # `box-sizing: border-box` is required so any padding the screen
        # applies (Voyager screens all set `content_padding`) is included
        # inside the 100% width rather than added to it. Without this,
        # `width: 100% + padding-left + padding-right` overflows the
        # viewport by exactly the padding pair under the browser's
        # default content-box sizing.
        if view.root_fill
          unless view.fluid_width || view.minimum_width || view.maximum_width
            el.add_style("width: 100%")
            el.add_style("box-sizing: border-box")
          end
          unless view.fluid_height || view.minimum_height || view.maximum_height
            el.add_style("min-height: 100dvh")
          end
        end

        # Container query root: emit containment context so descendant rules
        # of the form `@container <name> (...)` resolve against this box.
        if cq_name = view.container_query_name
          el.add_style("container-type: inline-size")
          el.add_style("container-name: #{cq_name}")
        end

        # View ID -> HTML id
        if id = view.id
          el.set_attribute("id", id)
        end

        # Accessibility label -> aria-label (only if not already set)
        if label = view.accessibility_label
          unless el["aria-label"]
            el.set_attribute("aria-label", label)
          end
        end

        # Test identifier -> data-testid attribute for automated UI testing
        if tid = view.test_id
          el.set_attribute("data-testid", tid)
        end
      end

      # Apply font properties as inline CSS.
      private def apply_font_styles(el : Components::Elements::HTMLElement, font : UI::Font, emit_defaults : Bool = true)
        if emit_defaults || font.size != 17.0
          el.add_style("font-size: #{font.size}px")
        end

        unless font.family == "system"
          el.add_style("font-family: #{font.family}")
        end

        case font.weight
        when :bold
          el.add_style("font-weight: bold")
        when :semibold
          el.add_style("font-weight: 600")
        when :medium
          el.add_style("font-weight: 500")
        when :light
          el.add_style("font-weight: 300")
        when :thin
          el.add_style("font-weight: 100")
        end
        # :regular is the default, no need to emit

        if font.italic
          el.add_style("font-style: italic")
        end
      end

      private def button_classes(view : UI::Button) : String
        [
          "am-button",
          "am-button--#{button_tone(view)}",
          "am-button--#{button_emphasis(view)}",
          "am-button--md",
        ].join(" ")
      end

      private def button_tone(view : UI::Button) : String
        case view.role
        when :destructive then "danger"
        when :cancel      then "neutral"
        else                   "brand"
        end
      end

      private def button_emphasis(view : UI::Button) : String
        case view.style
        when UI::ButtonStyle::Prominent  then "solid"
        when UI::ButtonStyle::Tinted     then "soft"
        when UI::ButtonStyle::Bordered   then "outline"
        when UI::ButtonStyle::Borderless then "ghost"
        else                                  "outline"
        end
      end

      # Convert a UI::Alignment to a CSS text-align value.
      private def alignment_to_css(alignment : UI::Alignment) : String
        case alignment
        when Alignment::Leading  then "left"
        when Alignment::Center   then "center"
        when Alignment::Trailing then "right"
        else                          "left"
        end
      end

      # Convert a UI::Alignment to a CSS align-items value for stacks.
      private def stack_align_items(alignment : UI::Alignment) : String
        case alignment
        when Alignment::Leading  then "flex-start"
        when Alignment::Center   then "center"
        when Alignment::Trailing then "flex-end"
        when Alignment::Top      then "flex-start"
        when Alignment::Bottom   then "flex-end"
        when Alignment::Fill     then "stretch"
        else                          "center"
        end
      end

      # Convert a 0.0-1.0 color component to a 0-255 integer.
      private def to_rgb_int(value : Float64) : Int32
        (value * 255).round.to_i.clamp(0, 255)
      end

      # Push an element as either a child of the current parent or as root.
      private def push_element(el : Components::Elements::HTMLElement)
        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # Push a container element onto the stack, execute the block (which
      # visits children and adds them to this container), then pop and
      # register the container with its own parent or as root.
      private def push_container(el : Components::Elements::ContainerElement, &)
        @element_stack.push(el)
        yield
        @element_stack.pop

        if parent = @element_stack.last?
          parent.as(Components::Elements::ContainerElement).add_child(el)
        else
          @root = el
        end
      end

      # Build a `clamp(min_px, ideal_vw, max_px)` literal from numeric pixel
      # floor/ceiling and a vw curve. Used by widget visit methods to migrate
      # away from hard-coded pixel sizing without surfacing UI::Fluid records
      # on every internal style construction.
      private def fluid_px(min : Number, ideal : Number, max : Number) : String
        "clamp(#{min}px, #{ideal}vw, #{max}px)"
      end

      # Build a `clamp(floor_px, ideal_expr, ceiling_px)` literal where the
      # ideal is a raw CSS expression (e.g., `"3vw"`, `"min(100%, 480px)"`)
      # bracketed by pixel anchors.
      private def fluid_with_floor(floor : Number, ideal : String, ceiling : Number) : String
        "clamp(#{floor}px, #{ideal}, #{ceiling}px)"
      end

      # Emit a 44 x 44 CSS-pixel touch-target floor on the supplied element.
      # The value is read from the active design tokens (Phase 1) so brand
      # overrides cascade through. Call from the visit method of every
      # interactive widget, on the *tappable* element (button / input /
      # styled label / thumb), not a decorative wrapper.
      private def enforce_touch_target(el : Components::Elements::HTMLElement)
        min = @design_tokens.touch_target_minimum_px
        el.add_style("min-width: #{min}px")
        el.add_style("min-height: #{min}px")
      end

      # Phase 4 — Tier 3 stub on -Dios builds only. The web renderer is
      # compiled even when -Dios is set (host apps may want both renderers
      # in scope), so PlatformVisitor's abstract visit(view : ActionSheet)
      # must be satisfied here. In practice the web renderer is never
      # invoked with a UI::ActionSheet on iOS (the iOS app uses UIKit
      # renderer); this method exists purely for abstract-method coverage.
      {% if flag?(:ios) %}
        def visit(view : UI::ActionSheet)
          el = Components::Elements::Div.new
          el.set_attribute("role", "dialog")
          el.set_attribute("aria-modal", "true")
          el.set_attribute("data-component", "action-sheet-noop")
          el.add_style("display: none")
          apply_common_styles(el, view)
          push_element(el)
        end
      {% end %}

      # Phase 4 — Tier 3 cross-platform companion. Renders a bottom-sheet
      # styled to read as the native iOS action sheet, with backdrop,
      # backdrop-tap-dismiss, swipe-handle affordance, optional cancel
      # button, and full ARIA chrome (role=dialog, aria-modal=true,
      # aria-labelledby, aria-describedby). The vanilla-JS focus trap,
      # Escape-to-dismiss, and action dispatch land in Commit 3.
      def visit(view : UI::ActionSheetWithWebFallback)
        id = next_action_sheet_id
        title_id = "ap-as-title-#{id}"
        msg_id = "ap-as-msg-#{id}"

        root = Components::Elements::Div.new
        root.add_class("ap-action-sheet")
        root.set_attribute("role", "dialog")
        root.set_attribute("aria-modal", "true")
        root.set_attribute("aria-labelledby", title_id)
        root.set_attribute("aria-describedby", msg_id) unless view.message.empty?
        root.set_attribute("data-presented", view.is_presented.to_s)
        root.set_attribute("data-component", "action-sheet")
        root.set_attribute("data-testid", "ap-action-sheet-#{id}")

        backdrop = Components::Elements::Div.new
        backdrop.add_class("ap-action-sheet__backdrop")
        backdrop.set_attribute("data-ap-as-dismiss", "backdrop")
        root.add_child(backdrop)

        panel = Components::Elements::Div.new
        panel.add_class("ap-action-sheet__panel")
        panel.set_attribute("role", "document")
        panel.set_attribute("tabindex", "-1")

        handle_el = Components::Elements::Div.new
        handle_el.add_class("ap-action-sheet__handle")
        handle_el.set_attribute("aria-hidden", "true")
        panel.add_child(handle_el)

        h2 = Components::Elements::H2.new
        h2.set_attribute("id", title_id)
        h2.add_class("ap-action-sheet__title")
        if view.title.empty?
          # Hidden anchor for aria-labelledby when no visible title.
          h2.set_attribute("hidden", "hidden")
        else
          h2 << view.title
        end
        panel.add_child(h2)

        unless view.message.empty?
          msg_el = Components::Elements::P.new
          msg_el.set_attribute("id", msg_id)
          msg_el.add_class("ap-action-sheet__message")
          msg_el << view.message
          panel.add_child(msg_el)
        end

        actions_list = Components::Elements::Ul.new
        actions_list.add_class("ap-action-sheet__actions")
        # Phase 4 R2: do NOT set role="group" on the <ul>. Doing so strips
        # the element's implicit role="list", which orphans the <li>
        # children and triggers axe-core's `listitem` rule. The outer
        # action-sheet container already exposes role="dialog" +
        # aria-modal="true"; the <ul>'s implicit list semantics are
        # sufficient and correct for the action list.

        cancel_pair : Tuple(Int32, UI::ActionSheetWithWebFallback::Action)? = nil
        view.actions.each_with_index do |action, index|
          if action.style == :cancel
            cancel_pair ||= {index, action}
            next
          end

          li = Components::Elements::Li.new
          btn = Components::Elements::Button.new(type: "button")
          btn.add_class("ap-action-sheet__action")
          btn.add_class(action.style == :destructive ? "ap-action-sheet__action--destructive" : "ap-action-sheet__action--default")
          btn.set_attribute("data-ap-as-action", index.to_s)
          enforce_touch_target(btn)
          btn << action.label
          li.add_child(btn)
          actions_list.add_child(li)
        end
        panel.add_child(actions_list)

        if pair = cancel_pair
          idx, action = pair
          cancel_btn = Components::Elements::Button.new(type: "button")
          cancel_btn.add_class("ap-action-sheet__action")
          cancel_btn.add_class("ap-action-sheet__action--cancel")
          cancel_btn.set_attribute("data-ap-as-action", idx.to_s)
          cancel_btn.set_attribute("data-ap-as-dismiss", "cancel")
          enforce_touch_target(cancel_btn)
          cancel_btn << action.label
          panel.add_child(cancel_btn)
        end

        root.add_child(panel)

        # Inline CSS + JS once per renderer instance. The static script
        # itself is idempotent (window.__apActionSheetInitialized) so even
        # if multiple renderer instances coexist on a page, the behavior
        # registers exactly once at runtime.
        unless @action_sheet_css_emitted
          @action_sheet_css_emitted = true
          style_block = Components::Elements::Style.new
          style_block << ACTION_SHEET_FALLBACK_CSS
          root.add_child(style_block)

          script_block = Components::Elements::Script.new
          script_block << ACTION_SHEET_FALLBACK_JS
          root.add_child(script_block)
        end

        apply_common_styles(root, view)
        push_element(root)
      end

      # Phase 6.10 — SwipeActionRow.
      #
      # Desktop-web: render the content + a visible trailing-actions
      # HStack with one button per action. Same chrome the user expects
      # in a desktop list row.
      #
      # Mobile-web (viewport < mobile_breakpoint_px): emit the same
      # content + a hidden trailing-actions panel, plus inline JS
      # touch-event handlers that translate the row on touchmove and
      # reveal the panel when the user swipes left far enough.
      #
      # Both surfaces are emitted unconditionally; the JS shim hides
      # the always-visible buttons on mobile and shows the
      # swipe-revealable panel instead, and the converse on desktop.
      # That keeps the HTML accessible to screen readers regardless
      # of viewport.
      def visit(view : UI::SwipeActionRow)
        row_id = next_swipe_action_id
        wrap = Components::Elements::Div.new
        wrap.add_class("ap-swipe-row")
        wrap.set_attribute("data-component", "swipe-action-row")
        wrap.set_attribute("data-row-id", row_id.to_s)
        wrap.set_attribute("data-mobile-breakpoint", view.mobile_breakpoint_px.to_s)

        # Content cell — the primary row content. Rendered via the
        # standard visit path so any UI::View is supported.
        content_html = render_subview(view.content)
        content_el = Components::Elements::Div.new
        content_el.add_class("ap-swipe-row__content")
        content_el.add_raw_html(content_html)
        wrap.add_child(content_el)

        # Trailing actions — visible HStack on desktop, revealed on
        # mobile swipe.
        if !view.trailing_actions.empty?
          wrap.add_child(swipe_action_panel(view.trailing_actions, "trailing"))
        end

        if !view.leading_actions.empty?
          wrap.add_child(swipe_action_panel(view.leading_actions, "leading"))
        end

        # Emit CSS + JS once per renderer instance, attached to this
        # row wrap so it's part of the rendered output regardless of
        # nesting.
        register_swipe_action_chrome(wrap) unless @swipe_action_chrome_emitted

        apply_common_styles(wrap, view)
        push_element(wrap)
      end

      @swipe_action_counter : Int32 = 0
      @swipe_action_chrome_emitted : Bool = false

      private def next_swipe_action_id : Int32
        @swipe_action_counter += 1
      end

      # Build a leading/trailing action panel (HStack of buttons) for
      # a SwipeActionRow. Buttons emit `data-on-tap-route` when the
      # action carries a routing destination so the client-side
      # UIRouteHost shim can dispatch (see register_swipe_action_chrome's
      # JS — it listens for clicks on .ap-swipe-row__action and calls
      # UIRouteHost.push when present).
      private def swipe_action_panel(actions : Array(UI::SwipeAction), edge : String) : Components::Elements::Div
        panel = Components::Elements::Div.new
        panel.add_class("ap-swipe-row__#{edge}")
        actions.each_with_index do |action, idx|
          btn = Components::Elements::Button.new(type: "button")
          btn << action.label
          btn.add_class("ap-swipe-row__action")
          btn.add_class("ap-swipe-row__action--destructive") if action.role == :destructive
          btn.set_attribute("data-action-index", idx.to_s)
          btn.set_attribute("data-action-role", action.role.to_s)
          btn.set_attribute("data-action-edge", edge)
          btn.set_attribute("aria-label", action.label)
          if route = action.on_tap_route
            btn.set_attribute("data-on-tap-route", route)
          end
          if action.on_tap
            # Crystal Procs can't run client-side from static HTML,
            # but mark the button so a downstream JS-bound demo can
            # dispatch by index.
            btn.set_attribute("data-has-callback", "1")
          end
          panel.add_child(btn)
        end
        panel
      end

      # CSS + vanilla-JS for the swipe-action chrome. Emits a <style>
      # block + a <script> with touch-event handlers that translate
      # the row on swipe-left and reveal the trailing panel. The
      # chrome <div> is appended into the current row wrapper so it
      # travels with the rendered output regardless of nesting (a
      # single SwipeActionRow at the root vs nested inside a VStack
      # both emit the chrome exactly once per renderer instance).
      private def register_swipe_action_chrome(wrap : Components::Elements::HTMLElement)
        @swipe_action_chrome_emitted = true
        chrome_div = Components::Elements::Div.new
        chrome_div.set_attribute("data-component", "swipe-action-chrome")
        chrome_div.set_attribute("hidden", "hidden")
        chrome_div.add_raw_html(swipe_action_chrome_html)
        wrap.as(Components::Elements::ContainerElement).add_child(chrome_div)
      end

      private def swipe_action_chrome_html : String
        <<-HTML
        <style>
        .ap-swipe-row {
          position: relative;
          display: flex;
          align-items: stretch;
          overflow: hidden;
          touch-action: pan-y;
        }
        .ap-swipe-row__content {
          flex: 1;
          min-width: 0;
        }
        .ap-swipe-row__trailing,
        .ap-swipe-row__leading {
          display: flex;
          gap: 8px;
          padding: 0 8px;
          align-items: center;
        }
        .ap-swipe-row__action {
          padding: 8px 14px;
          border-radius: 8px;
          border: 1px solid var(--ap-color-border-default);
          background: var(--ap-color-surface-panel);
          color: var(--ap-color-text-primary);
          font: inherit;
          cursor: pointer;
          min-height: 44px;
        }
        .ap-swipe-row__action--destructive {
          color: var(--ap-color-danger-text);
          border-color: var(--ap-color-danger-text);
        }
        /* mobile mode is toggled via class `ap-swipe-row--mobile`
           which the JS shim adds when viewport width is below the
           row's `data-mobile-breakpoint` value. CSS @media queries
           can't take a variable, so we use a class-driven approach
           and let JS resolve the breakpoint per-row. */
        .ap-swipe-row--mobile .ap-swipe-row__trailing,
        .ap-swipe-row--mobile .ap-swipe-row__leading {
          position: absolute;
          top: 0;
          bottom: 0;
          opacity: 0;
          transform: translateX(0);
          transition: opacity 120ms ease, transform 120ms ease;
          pointer-events: none;
        }
        .ap-swipe-row--mobile .ap-swipe-row__trailing { right: 0; }
        .ap-swipe-row--mobile .ap-swipe-row__leading { left: 0; }
        .ap-swipe-row--mobile[data-revealed="trailing"] .ap-swipe-row__trailing {
          opacity: 1; transform: translateX(0); pointer-events: auto;
        }
        .ap-swipe-row--mobile[data-revealed="leading"] .ap-swipe-row__leading {
          opacity: 1; transform: translateX(0); pointer-events: auto;
        }
        .ap-swipe-row--mobile[data-revealed="trailing"] .ap-swipe-row__content {
          transform: translateX(-120px);
          transition: transform 120ms ease;
        }
        </style>
        <script>
        (function() {
          var REVEAL_THRESHOLD = 40; // px
          function applyMobileClass(row) {
            var bp = parseInt(row.getAttribute('data-mobile-breakpoint') || '768', 10);
            if (window.innerWidth < bp) {
              row.classList.add('ap-swipe-row--mobile');
            } else {
              row.classList.remove('ap-swipe-row--mobile');
              row.removeAttribute('data-revealed');
            }
          }
          function bind(row) {
            if (row.dataset.swipeBound === '1') return;
            row.dataset.swipeBound = '1';
            applyMobileClass(row);
            var startX = null;
            row.addEventListener('touchstart', function(e) {
              if (!row.classList.contains('ap-swipe-row--mobile')) return;
              startX = e.touches[0].clientX;
            }, {passive: true});
            row.addEventListener('touchmove', function(e) {
              if (startX === null) return;
              var dx = e.touches[0].clientX - startX;
              if (dx < -REVEAL_THRESHOLD) row.setAttribute('data-revealed', 'trailing');
              else if (dx > REVEAL_THRESHOLD) row.setAttribute('data-revealed', 'leading');
            }, {passive: true});
            row.addEventListener('touchend', function() { startX = null; });
            // Wire on_tap_route routing for any action button inside.
            row.querySelectorAll('.ap-swipe-row__action').forEach(function(btn) {
              btn.addEventListener('click', function(e) {
                var route = btn.getAttribute('data-on-tap-route');
                if (route && window.UIRouteHost && typeof window.UIRouteHost.push === 'function') {
                  e.preventDefault();
                  window.UIRouteHost.push(route);
                }
              });
            });
          }
          function bindAll() {
            document.querySelectorAll('.ap-swipe-row').forEach(bind);
          }
          // Tap outside any row resets reveal state.
          document.addEventListener('click', function(e) {
            document.querySelectorAll('.ap-swipe-row[data-revealed]').forEach(function(row) {
              if (!row.contains(e.target)) row.removeAttribute('data-revealed');
            });
          });
          window.addEventListener('resize', function() {
            document.querySelectorAll('.ap-swipe-row').forEach(applyMobileClass);
          });
          if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', bindAll);
          } else {
            bindAll();
          }
        })();
        </script>
        HTML
      end

      # Render `view` to HTML in a sub-renderer (preserves parent
      # context). Used by SwipeActionRow to embed arbitrary content.
      private def render_subview(view : UI::View) : String
        sub = Renderer.new
        sub.design_tokens = @design_tokens
        sub.render(view)
      end

      # Monotonic per-renderer counter for action-sheet element IDs.
      private def next_action_sheet_id : Int32
        @action_sheet_counter ||= 0
        (@action_sheet_counter = @action_sheet_counter.not_nil! + 1)
      end

      @action_sheet_css_emitted : Bool = false

      # Vanilla-JS bottom-sheet behavior. Source lives at
      # src/ui/web/action_sheet_fallback.js and is inlined into the renderer
      # binary at compile time so the rendered HTML is self-sufficient (no
      # external <script src=...> required).
      ACTION_SHEET_FALLBACK_JS = {{ read_file("#{__DIR__}/../web/action_sheet_fallback.js") }}

      ACTION_SHEET_FALLBACK_CSS = <<-CSS
      .ap-action-sheet { position: fixed; inset: 0; z-index: 1000; display: none; }
      .ap-action-sheet[data-presented="true"] { display: block; }
      .ap-action-sheet__backdrop {
        position: absolute; inset: 0;
        background: oklch(0.18 0.02 248 / 0.42);
      }
      .ap-action-sheet__panel {
        position: absolute; left: 0; right: 0; bottom: 0;
        background: var(--ap-color-surface-panel);
        color: var(--ap-color-text-primary);
        border-radius: var(--ap-radius-panel) var(--ap-radius-panel) 0 0;
        padding: 12px 16px env(safe-area-inset-bottom);
        box-shadow: var(--ap-elevation-overlay);
        transform: translateY(0);
        transition: transform var(--ap-motion-duration-base) var(--ap-motion-ease-standard);
        outline: none;
        max-height: 80vh;
        overflow-y: auto;
      }
      .ap-action-sheet[data-presented="false"] .ap-action-sheet__panel {
        transform: translateY(100%);
      }
      .ap-action-sheet__handle {
        width: 36px; height: 5px;
        background: var(--ap-color-border-default);
        border-radius: var(--ap-radius-pill);
        margin: 0 auto 12px;
      }
      @media (min-width: 768px) {
        .ap-action-sheet__panel {
          left: 50%; right: auto; bottom: 50%;
          transform: translate(-50%, 50%);
          max-width: 420px; width: 90vw;
          border-radius: var(--ap-radius-panel);
        }
        .ap-action-sheet[data-presented="false"] .ap-action-sheet__panel {
          transform: translate(-50%, 50%) scale(0.96);
          opacity: 0;
        }
        .ap-action-sheet__handle { display: none; }
      }
      .ap-action-sheet__title   { font-size: 17px; font-weight: 600; text-align: center; margin: 0 0 4px; }
      .ap-action-sheet__message { font-size: 13px; color: var(--ap-color-text-secondary); text-align: center; margin: 0 0 16px; }
      .ap-action-sheet__actions { list-style: none; padding: 0; margin: 0 0 8px; display: flex; flex-direction: column; gap: 8px; }
      .ap-action-sheet__action {
        width: 100%;
        padding: 12px 16px;
        border: none; border-radius: var(--ap-radius-control);
        background: var(--ap-color-surface-sunken);
        /* Phase 4 R2: brand-accent on surface-sunken measured 1.92:1 in
         * light mode (WCAG-AA fails 4.5:1 for 17px normal text). The
         * cancel action inherits this color over surface-panel (#fff),
         * measured 2.27:1. Swapping to brand-primary lifts both surfaces
         * to >= 5.05:1 (sunken) and >= 5.78:1 (panel) in light mode and
         * >= 8.72:1 in dark mode, while preserving the "interactive CTA"
         * semantic affordance. */
        color: var(--ap-color-brand-primary);
        font-size: 17px;
        cursor: pointer;
        min-height: 44px;
      }
      .ap-action-sheet__action:focus-visible {
        outline: 2px solid var(--ap-color-focus-ring);
        outline-offset: 2px;
      }
      .ap-action-sheet__action--destructive { color: var(--ap-color-danger-text); }
      .ap-action-sheet__action--cancel {
        background: var(--ap-color-surface-panel);
        font-weight: 600;
        margin-top: 4px;
        border: 1px solid var(--ap-color-border-default);
      }
      CSS
    end

    # ---------------------------------------------------------------
    # Phase 6.10 D2 — coordinator-driven route host
    # ---------------------------------------------------------------
    #
    # The web target is a single-page HTML doc with hash-route
    # navigation. Each route's view tree is rendered once at build
    # time + once per push/pop at runtime, in the browser, via a
    # tiny vanilla-JS shim. The shim listens to hashchange + popstate
    # and swaps the host element's innerHTML to the new route's
    # pre-rendered HTML fragment.
    #
    # `render_route_host(routes)` emits:
    #   1. The host `<div id="ui-route-host">…</div>` containing the
    #      INITIAL route's fragment.
    #   2. A `<script type="application/json" id="ui-route-data">…`
    #      block carrying every route's pre-rendered HTML keyed by
    #      route id.
    #   3. A `<script>` that wires hashchange → DOM swap.
    #
    # `routes` is `Hash(String, String)` of route_id_str => prerendered_html.
    # `initial_route` is the route shown before any hash navigation.
    # `route_change_announce_label` is the aria-live announcement template
    # (default "Navigated to {route}") used for I-6 a11y compliance.
    def self.render_route_host(
      routes : Hash(String, String),
      initial_route : String,
      route_change_announce_label : String = "Navigated to {route}",
    ) : String
      # Build a fully JSON-encoded payload. JSON.build handles all
      # the standard escapes (\, ", \n, \t, \r, control chars). We
      # additionally post-process the encoded payload to neutralise
      # `</script>` sequences — which the JSON spec doesn't escape
      # but which would prematurely close the surrounding
      # <script type="application/json"> block. Replacing `<` with
      # `<` inside JSON string values is the standard mitigation
      # (still valid JSON, won't terminate the script tag).
      payload = JSON.build do |json|
        json.object do
          routes.each do |route_id, html|
            json.field(route_id, html)
          end
        end
      end
      payload = payload.gsub("</", "<\\/").gsub("<!--", "<\\!--")

      initial_route_attr = HTML.escape(initial_route)
      initial_route_js = initial_route.inspect

      String.build do |io|
        # Route fragment data — embedded as JSON so the JS shim can
        # look up any fragment by id.
        io << %(<script type="application/json" id="ui-route-data">) << '\n'
        io << payload << '\n'
        io << "</script>\n"

        # The host element holding the visible route. innerHTML is the
        # rendered fragment for the initial route.
        io << %(<div id="ui-route-host" role="main" aria-live="polite" data-route=") << initial_route_attr << "\">\n"
        io << (routes[initial_route]? || "")
        io << "\n</div>\n"

        # The aria-live announcer (separate element so it doesn't
        # collide with the host content's a11y tree).
        io << %(<div id="ui-route-announcer" aria-live="polite" aria-atomic="true" )
        io << %(style="position:absolute; left:-10000px; top:auto; width:1px; height:1px; overflow:hidden;"></div>) << '\n'

        # JS shim. Vanilla DOM API + hashchange + popstate. The
        # NavigationCoordinator on the server side renders all routes
        # at build time; the browser just swaps fragments. State
        # mutations (e.g. Settings toggle) trigger a re-emit of the
        # affected fragments via additional patches (Phase 6.10 D4
        # uses inline JS to re-call the static fragment for the
        # toggled route).
        io << <<-JS
<script>
(function() {
  var routes = JSON.parse(document.getElementById('ui-route-data').textContent);
  var host = document.getElementById('ui-route-host');
  var announcer = document.getElementById('ui-route-announcer');

  function routeFromHash() {
    var h = window.location.hash || '';
    if (h.startsWith('#')) h = h.substring(1);
    return h && routes[h] ? h : host.getAttribute('data-route');
  }

  function render(routeId, opts) {
    opts = opts || {};
    var html = routes[routeId];
    if (typeof html !== 'string') return;
    host.innerHTML = html;
    host.setAttribute('data-route', routeId);
    if (!opts.silent) {
      announcer.textContent = #{route_change_announce_label.inspect}.replace('{route}', routeId);
    }
    if (opts.pushState) {
      try { window.history.pushState({route: routeId}, '', '#' + routeId); } catch (e) {}
    }
  }

  window.UIRouteHost = {
    push: function(routeId) { render(routeId, {pushState: true}); },
    pop: function(rootRoute) {
      try { window.history.back(); } catch (e) {
        if (rootRoute) render(rootRoute, {silent: false});
      }
    },
    replace: function(routeId) {
      render(routeId, {silent: false});
      try { window.history.replaceState({route: routeId}, '', '#' + routeId); } catch (e) {}
    },
    setFragment: function(routeId, html) {
      routes[routeId] = html;
      if (host.getAttribute('data-route') === routeId) {
        host.innerHTML = html;
      }
    },
  };

  window.addEventListener('hashchange', function() { render(routeFromHash(), {silent: false}); });
  window.addEventListener('popstate', function() { render(routeFromHash(), {silent: false}); });

  // If the initial hash names a route different from the data-route
  // attribute, swap to it on load (so direct deep-links work).
  var initial = routeFromHash();
  if (initial !== host.getAttribute('data-route')) render(initial, {silent: true});
})();
</script>
JS
      end
    end
  end
end
