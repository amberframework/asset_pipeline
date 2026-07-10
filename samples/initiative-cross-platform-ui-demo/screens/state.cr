module InitiativeDemo
  # Shared demo state — instance, NOT class vars (per Phase 6 brief
  # decision #3 and the I-9 invariant: no new class vars with
  # initializers that the iOS embedding gap would silently break).
  #
  # State for each screen is a plain Crystal struct/class — settings
  # toggles, picker selections, navigation cursor, etc. The brand
  # override pattern (InitiativeDemo.brand_tokens in brand.cr) is the
  # ONLY module-level value; everything that mutates lives here.
  class State
    property current_screen : Symbol = :sign_in
    property selected_tab : Int32 = 0

    # Sign-in form
    property email : String = ""
    property password : String = ""
    property remember_me : Bool = true

    # Settings
    property notifications_enabled : Bool = true
    property dark_mode_preference : Int32 = 0 # 0=auto, 1=light, 2=dark
    property volume : Float64 = 0.5
    property accent_color : UI::DesignTokens::Color = InitiativeDemo::BRAND_PRIMARY_LIGHT

    def initialize
    end
  end
end
