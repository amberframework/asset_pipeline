module Voyager
  # Voyager — Sign In screen.
  #
  # Phase 8D.1: migrated from a module-level class with
  # `build(state, coord)` to a `UI::Screen` subclass with
  # `build(ctx : UI::ScreenContext) : UI::View`. User-intent callbacks
  # route through `Voyager.dispatch(:action_name, action_params)` per
  # the brief's action-ref convention; the controller layer
  # (`SignInController`) interprets the actions and returns
  # `UI::ActionResult` subtypes that the dispatcher translates into
  # coordinator operations.
  class SignInScreen < UI::Screen
    SLUG = "voyager-sign-in"

    def build(context : UI::ScreenContext) : UI::View
      # Phase 6.10 Rem 4 (Item 2D/2E + Item 3) — device-aware sizing.
      # See screens/sign_in.cr pre-8D.1 history for the layout rationale
      # (root_fill + content_width cap + safe-area aware padding).
      metrics = UI::DesignTokens::DeviceMetrics.current
      content_width = metrics.compact_horizontal? ? 340.0 : 400.0

      state = Voyager.state

      root = UI::VStack.new(spacing: 24.0)
      root.root_fill = true
      root.alignment = UI::Alignment::Center
      root.padding = UI::EdgeInsets.new(
        top: 48.0 + metrics.safe_area_top_pt,
        trailing: 32.0 + metrics.safe_area_trailing_pt,
        bottom: 48.0 + metrics.safe_area_bottom_pt,
        leading: 32.0 + metrics.safe_area_leading_pt,
      )
      root.accessibility_label = "Voyager sign in screen"
      root.test_id = "voyager-sign-in-root"

      wordmark = UI::Label.new("Voyager")
      wordmark.font = UI::Font.new(size: 34.0, weight: :bold)
      wordmark.text_color_role = UI::LabelRole::Primary
      wordmark.text_alignment = UI::Alignment::Center
      wordmark.accessibility_label = "Voyager brand wordmark"

      subtitle = UI::Label.new("Sign in to manage your todos")
      subtitle.font = UI::Font.new(size: 15.0, weight: :regular)
      subtitle.text_color_role = UI::LabelRole::Secondary
      subtitle.text_alignment = UI::Alignment::Center

      fields = UI::VStack.new(spacing: 12.0)
      fields.alignment = UI::Alignment::Leading
      fields.minimum_width = content_width
      fields.maximum_width = content_width

      # Phase 8D.1 — the renderer's wire-time TextField hook
      # (UI::FormStateRendererHook.wrap_text_handler) reads
      # UI::FormState.current and writes typed values into the
      # dispatcher's per-mount FormState under the `name` key. Brief
      # contract: SignInController#submit reads `ctx.form_state["email"]`
      # and `ctx.form_state["password"]`.
      email = UI::TextField.new(placeholder: "Email", name: "email")
      email.text = state.current_user
      email.accessibility_label = "Email address"
      email.test_id = "voyager-sign-in-email"
      email.keyboard_type = UI::KeyboardType::EmailAddress
      email.minimum_width = content_width
      email.maximum_width = content_width
      # NOTE on `state.current_user`: this is a UX-courtesy mirror so the
      # pre-populated email survives a re-render. The authoritative store
      # for the dispatched submit is FormState (renderer-wired). We keep
      # the side-write into state for the same UX as pre-8D.1.
      email.on_change = ->(value : String) { state.current_user = value }

      password = UI::SecureField.new(placeholder: "Password", name: "password")
      password.accessibility_label = "Password"
      password.test_id = "voyager-sign-in-password"
      password.minimum_width = content_width
      password.maximum_width = content_width

      fields << email.as(UI::View)
      fields << password.as(UI::View)

      submit = UI::Button.new("Sign in", style: UI::ButtonStyle::Prominent)
      submit.accessibility_label = "Sign in"
      submit.test_id = "voyager-sign-in-submit"
      submit.minimum_width = content_width
      submit.maximum_width = content_width
      # Phase 8D.1 — Symbol action ref `:submit` routes to
      # SignInController#submit per the brief's action-ref convention.
      submit.on_tap = -> { Voyager.dispatch(:submit) }

      root << wordmark.as(UI::View)
      root << subtitle.as(UI::View)
      root << fields.as(UI::View)
      root << submit.as(UI::View)

      root.as(UI::View)
    end
  end
end
