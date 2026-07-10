module InitiativeDemo
  # demo-sign-in — brand wordmark, two text fields, primary button,
  # secondary text link, social-auth row.
  #
  # Anatomy:
  #   VStack(spacing: 24)
  #     Label("Demo")           # brand wordmark
  #     Label("Sign in...")     # subtitle
  #     VStack(spacing: 12)
  #       TextField(email)
  #       SecureField(password)
  #     Button("Sign in", primary)
  #     LinkButton("Forgot?")
  #     Divider
  #     HStack(spacing: 12)
  #       Button("Apple")  Button("Google")  Button("Email")  # social
  module SignInScreen
    extend self

    SLUG = "demo-sign-in"

    def build(state : InitiativeDemo::State) : UI::View
      # Use an explicit content width that sits below the iPhone 17 portrait
      # logical width (~402pt) so the column doesn't clip / right-shift on
      # iOS. macOS / web renderers honour the same pin and centre the
      # content within their wider viewports via the parent VStack's
      # `Center` alignment.
      content_width = 340.0

      root = UI::VStack.new(spacing: 24.0)
      root.alignment = UI::Alignment::Center
      root.padding = UI::EdgeInsets.new(top: 48.0, trailing: 32.0, bottom: 48.0, leading: 32.0)
      root.minimum_width = content_width
      root.maximum_width = content_width
      root.accessibility_label = "Sign in screen"
      root.test_id = "demo-sign-in-root"

      wordmark = UI::Label.new("Cascade")
      wordmark.font = UI::Font.new(size: 34.0, weight: :bold)
      wordmark.text_color_role = UI::LabelRole::Primary
      wordmark.text_alignment = UI::Alignment::Center
      wordmark.accessibility_label = "Cascade brand wordmark"

      subtitle = UI::Label.new("Sign in to continue")
      subtitle.font = UI::Font.new(size: 15.0, weight: :regular)
      subtitle.text_color_role = UI::LabelRole::Secondary
      subtitle.text_alignment = UI::Alignment::Center

      # Form fields. Pin to the content width so SwiftUI's TextField /
      # SecureField don't collapse to their intrinsic placeholder width
      # (which is what produced the "tiny empty oval" Password baseline).
      fields = UI::VStack.new(spacing: 12.0)
      fields.alignment = UI::Alignment::Leading
      fields.minimum_width = content_width
      fields.maximum_width = content_width

      email_field = UI::TextField.new(placeholder: "Email")
      email_field.text = state.email
      email_field.accessibility_label = "Email address"
      email_field.test_id = "demo-sign-in-email"
      email_field.keyboard_type = UI::KeyboardType::EmailAddress
      email_field.minimum_width = content_width
      email_field.maximum_width = content_width
      email_field.on_change = ->(value : String) { state.email = value }

      password_field = UI::SecureField.new(placeholder: "Password")
      password_field.text = state.password
      password_field.accessibility_label = "Password"
      password_field.test_id = "demo-sign-in-password"
      password_field.minimum_width = content_width
      password_field.maximum_width = content_width
      password_field.on_change = ->(value : String) { state.password = value }

      fields << email_field.as(UI::View)
      fields << password_field.as(UI::View)

      # Primary button. Use ButtonStyle::Prominent so SwiftUI applies
      # `.buttonStyle(.borderedProminent)` on iOS / macOS — this is the
      # filled brand-tint pill chrome HIG calls for on a primary CTA.
      # Without it the SwiftUI default body-Button renders as bare text
      # (Rem 3 baseline showed the Sign-in button as invisible on the
      # white card). `role` stays `:default` because the action is
      # non-destructive; the role enum doesn't accept `:primary` and the
      # populator was previously emitting `setRole:` with the string
      # "primary" which the Swift facade had no case for (no-op).
      primary = UI::Button.new("Sign in", style: UI::ButtonStyle::Prominent)
      primary.accessibility_label = "Sign in to your account"
      primary.test_id = "demo-sign-in-submit"
      primary.minimum_width = content_width
      primary.maximum_width = content_width

      # Secondary "forgot password" link.
      # Pass a non-empty URL so the SwiftUI LinkButtonFacade emits a
      # SwiftUI `Link` (which inherits the accent / brand-tint cascade
      # as link colour) rather than falling back to a styled `Button`
      # whose default chrome on macOS is an opaque gray pill that
      # hides the brand teal entirely. The on-tap is wired through
      # `opens_in_browser=false` so the demo doesn't actually navigate.
      forgot = UI::LinkButton.new("Forgot password?", "https://example.com/forgot")
      forgot.opens_in_browser = false
      forgot.accessibility_label = "Reset your password"
      forgot.test_id = "demo-sign-in-forgot"

      # Social auth divider + row.
      divider = UI::Divider.new(:horizontal)
      or_label = UI::Label.new("or continue with")
      or_label.font = UI::Font.new(size: 13.0, weight: :regular)
      or_label.text_color_role = UI::LabelRole::Tertiary
      or_label.text_alignment = UI::Alignment::Center

      social_row = UI::HStack.new(spacing: 12.0)
      social_row.alignment = UI::Alignment::Center
      social_row.minimum_width = content_width
      social_row.maximum_width = content_width
      ["Apple", "Google", "Email"].each_with_index do |name, idx|
        b = UI::Button.new(name)
        b.role = :secondary
        b.accessibility_label = "Continue with #{name}"
        b.test_id = "demo-sign-in-social-#{idx}"
        social_row << b.as(UI::View)
      end

      root << wordmark.as(UI::View)
      root << subtitle.as(UI::View)
      root << fields.as(UI::View)
      root << primary.as(UI::View)
      root << forgot.as(UI::View)
      root << divider.as(UI::View)
      root << or_label.as(UI::View)
      root << social_row.as(UI::View)

      root.as(UI::View)
    end
  end
end
