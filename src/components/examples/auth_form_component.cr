require "../base/stateless_component"
require "../design_system/fieldset"
require "./form_field_component"

module Components
  module Examples
    # Sign-up/sign-in form proof with native browser semantics and password hooks.
    class AuthFormComponent < StatelessComponent
      def render_content : String
        mode = @attributes["mode"]? || "signup"
        mode == "signin" ? render_signin : render_signup
      end

      private def render_signup : String
        id = @attributes["id"]? || "signup"
        status_id = "#{id}-status"
        name_id = "#{id}-name"
        email_id = "#{id}-email"
        password_id = "#{id}-password"
        rules_id = "#{password_id}-rules"
        confirm_id = "#{id}-confirm"

        String.build do |io|
          io << %(<form class="am-form am-panel" data-component="auth-form" data-amber-validate data-ap-validate data-amber-auth-form data-ap-auth-form novalidate aria-describedby="#{escape_html(status_id)}" aria-label="Create workspace">)
          io << %(<div class="am-form-status" id="#{escape_html(status_id)}" role="status" data-amber-form-status data-ap-form-status>Create an account to preview password guidance.</div>)
          io << fieldset("Create workspace account details", %(<label class="am-field" for="#{escape_html(name_id)}"><span>Full name</span><input class="am-input" id="#{escape_html(name_id)}" name="name" autocomplete="name" required></label><label class="am-field" for="#{escape_html(email_id)}"><span>Work email</span><input class="am-input" id="#{escape_html(email_id)}" name="email" type="email" autocomplete="email" required placeholder="designer@example.com"></label><label class="am-field" for="#{escape_html(password_id)}"><span>Password</span><input class="am-input" id="#{escape_html(password_id)}" name="password" type="password" autocomplete="new-password" minlength="10" required data-amber-password data-ap-password aria-describedby="#{escape_html(rules_id)}"><span class="am-field__hint" id="#{escape_html(rules_id)}" data-amber-password-rules data-ap-password-rules>Use 10+ characters with uppercase, lowercase, number, and symbol.</span></label><label class="am-field" for="#{escape_html(confirm_id)}"><span>Confirm password</span><input class="am-input" id="#{escape_html(confirm_id)}" name="password_confirmation" type="password" autocomplete="new-password" required data-amber-password-confirm="#{escape_html(password_id)}" data-ap-password-confirm="#{escape_html(password_id)}"></label><label class="am-choice"><input type="checkbox" required name="terms"> I agree to the accessible launch checklist.</label>), status_id)
          io << %(<button class="am-button am-button--brand am-button--solid am-button--md" type="submit">Create workspace</button>)
          io << "</form>"
        end
      end

      private def render_signin : String
        id = @attributes["id"]? || "signin"
        status_id = "#{id}-status"
        email_id = "#{id}-email"
        password_id = "#{id}-password"

        String.build do |io|
          io << %(<form class="am-form am-panel" data-component="auth-form" data-amber-validate data-ap-validate data-amber-auth-form data-ap-auth-form novalidate aria-describedby="#{escape_html(status_id)}" aria-label="Sign in">)
          io << %(<div class="am-form-status" id="#{escape_html(status_id)}" role="status" data-amber-form-status data-ap-form-status>Sign in with an existing workspace account.</div>)
          io << fieldset("Workspace sign-in details", %(<label class="am-field" for="#{escape_html(email_id)}"><span>Email</span><input class="am-input" id="#{escape_html(email_id)}" name="email" type="email" autocomplete="email" required></label><label class="am-field" for="#{escape_html(password_id)}"><span>Password</span><input class="am-input" id="#{escape_html(password_id)}" name="password" type="password" autocomplete="current-password" required minlength="8"></label><label class="am-switch"><input type="checkbox" name="remember"> Keep me signed in</label>), status_id)
          io << %(<button class="am-button am-button--brand am-button--solid am-button--md" type="submit">Sign in</button>)
          io << %(<a href="#reset-flow">Forgot password?</a>)
          io << "</form>"
        end
      end

      private def fieldset(legend : String, body : String, described_by : String? = nil) : String
        component = Components::DesignSystem::Fieldset.new(legend: legend)
        component["described_by"] = described_by if described_by
        component << Components::Elements::RawHTML.new(body)
        component.render
      end
    end
  end
end
