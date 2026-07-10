module Voyager
  # Phase 8D.1 — SignInController.
  #
  # Owns the `:submit` action for SignInScreen. Reads typed email +
  # password out of FormState; on non-empty inputs stashes the email
  # into session and returns `ReplaceRoot.new(:todos)` so the sign-in
  # screen does NOT remain in the back stack (per brief stack-policy
  # contract: post-sign-in stack is `[todos]`, not `[sign_in, todos]`).
  # On empty inputs sets a flash error and returns `Rerender` so the
  # current screen rebuilds with the error visible (Phase 8D.1 does not
  # yet render the flash visually — that's a follow-up; the contract is
  # what the brief locks in).
  class SignInController < UI::Controller
    def dispatch_action(name : Symbol, context : UI::ScreenContext::Native) : UI::ActionResult
      case name
      when :submit
        submit(context)
      else
        raise UI::Controller::UnknownActionError.new(
          "SignInController has no action :#{name}"
        )
      end
    end

    def submit(context : UI::ScreenContext::Native) : UI::ActionResult
      email = (context.form_state.values["email"]? || "").strip
      password = (context.form_state.values["password"]? || "").strip
      if email.empty? || password.empty?
        context.flash["error"] = "Please provide both email and password."
        UI::ActionResult::Rerender.new
      else
        context.session["user_email"] = email
        # CRITICAL: ReplaceRoot, not Navigate. Sign-in must not be in
        # the back stack.
        UI::ActionResult::ReplaceRoot.new(:todos)
      end
    end
  end
end
