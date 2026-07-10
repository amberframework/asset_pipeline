require "../base/stateless_component"
require "../design_system/fieldset"
require "./form_field_component"

module Components
  module Examples
    # Semantic payment form proof with native validation attributes and design-system hooks.
    class PaymentFormComponent < StatelessComponent
      component_css <<-CSS
      .am-payment-form {
        display: grid;
        gap: 1rem;
      }
      CSS

      def render_content : String
        id = @attributes["id"]? || "payment"
        status_id = "#{id}-status"
        name_id = @attributes["id"]? ? "#{id}-name" : "card-name"
        email_id = @attributes["id"]? ? "#{id}-email" : "card-email"
        number_id = @attributes["id"]? ? "#{id}-card-number" : "card-number"
        expiry_id = @attributes["id"]? ? "#{id}-card-expiry" : "card-expiry"
        cvc_id = @attributes["id"]? ? "#{id}-card-cvc" : "card-cvc"
        promo_id = @attributes["id"]? ? "#{id}-promo-code" : "promo-code"

        String.build do |io|
          io << %(<form class="am-form am-panel am-payment-form" data-component="payment-form" data-amber-validate data-ap-validate data-amber-payment-form data-ap-payment-form novalidate aria-describedby="#{escape_html(status_id)}">)
          io << %(<div class="am-form-status" id="#{escape_html(status_id)}" role="status" data-amber-form-status data-ap-form-status>Enter payment details to preview browser validation.</div>)
          io << fieldset("Receipt contact", %(<label class="am-field" for="#{escape_html(email_id)}"><span>Receipt email</span><input class="am-input" id="#{escape_html(email_id)}" name="email" type="email" autocomplete="email" required placeholder="finance@example.com"></label>))
          io << fieldset("Card details", %(<label class="am-field" for="#{escape_html(name_id)}"><span>Name on card</span><input class="am-input" id="#{escape_html(name_id)}" name="ccname" autocomplete="cc-name" required></label><label class="am-field" for="#{escape_html(number_id)}"><span>Card number</span><input class="am-input" id="#{escape_html(number_id)}" name="card_number" inputmode="numeric" autocomplete="cc-number" pattern="[0-9 ]{19}" required data-amber-card-number data-ap-card-number data-pattern-message="Use 16 digits grouped as 0000 0000 0000 0000." placeholder="4242 4242 4242 4242"></label><div class="am-form-grid"><label class="am-field" for="#{escape_html(expiry_id)}"><span>Expiry</span><input class="am-input" id="#{escape_html(expiry_id)}" name="expiry" inputmode="numeric" autocomplete="cc-exp" pattern="[0-9]{2}/[0-9]{2}" required data-amber-card-expiry data-ap-card-expiry data-pattern-message="Use MM/YY." placeholder="09/29"></label><label class="am-field" for="#{escape_html(cvc_id)}"><span>CVC</span><input class="am-input" id="#{escape_html(cvc_id)}" name="cvc" inputmode="numeric" autocomplete="cc-csc" pattern="[0-9]{3,4}" required data-amber-card-cvc data-ap-card-cvc data-pattern-message="Use a 3 or 4 digit security code." placeholder="123"></label></div>))
          io << fieldset("Promotion code", %(<label class="am-field" for="#{escape_html(promo_id)}"><span>Promo code</span><input class="am-input" id="#{escape_html(promo_id)}" name="promo_code" autocomplete="off" data-amber-promo-code data-ap-promo-code placeholder="AP10"><span class="am-field__hint" data-amber-promo-status data-ap-promo-status>Optional. Try AP10.</span></label>))
          io << %(<button class="am-button am-button--brand am-button--solid am-button--md" type="submit">Preview checkout</button>)
          io << "</form>"
        end
      end

      private def fieldset(legend : String, body : String) : String
        component = Components::DesignSystem::Fieldset.new(legend: legend)
        component << Components::Elements::RawHTML.new(body)
        component.render
      end
    end
  end
end
