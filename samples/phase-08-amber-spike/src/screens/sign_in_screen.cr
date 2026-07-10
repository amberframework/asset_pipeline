# Phase 8 spike — Sign In screen as a UI::Screen subclass.
#
# Phase 8A migration: rewritten to use UI::Form with explicit web POST
# semantics. Previously the screen built a bare VStack-of-fields and
# relied on manual curl form-encoding for the POST test. With Item 2's
# UI::Form extension the screen now renders a real <form action method>
# wrapper, CSRF hidden input, and an auto-promoted submit button —
# meaning a human submitting from a real browser will reach the
# controller's submit action with email/password/_csrf params.
class SignInScreen < UI::Screen
  def build(context : UI::ScreenContext) : UI::View
    email_value = context.params["email"]? || ""

    root = UI::VStack.new(spacing: 16.0)
    root << UI::Label.new("Phase 8 Amber Spike — Sign In")

    if msg = context.flash_data["error"]?
      root << UI::Label.new("\u{26A0} #{msg}")
    elsif msg = context.flash_data["notice"]?
      root << UI::Label.new("\u{2713} #{msg}")
    end

    form = UI::Form.new(
      action: "/sign_in/submit",
      csrf_token: context.csrf_token,
    )
    form << UI::TextField.new(
      placeholder: "you@example.com",
      name: "email",
      text: email_value,
    )
    form << UI::SecureField.new(
      placeholder: "Password",
      name: "password",
    )
    # Single-button form — UI::Form auto-promotes the lone Button child
    # to type="submit". Explicit `type:` would also work and is the
    # required form for any multi-button screen.
    form << UI::Button.new("Sign in")

    root << form
    root
  end
end
