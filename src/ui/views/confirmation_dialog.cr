# Action-confirmation prompt with platform-idiomatic destructive/cancel buttons.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # ConfirmationDialog — Action-confirmation prompt with platform-idiomatic destructive/cancel buttons.
  class ConfirmationDialog < View
    property title : String
    property message : String = ""
    property is_presented : Bool = false
    property confirm_label : String = "Confirm"
    property cancel_label : String = "Cancel"
    property confirm_style : Symbol = :default  # :default, :destructive
    property on_confirm : Proc(Nil)? = nil
    property on_cancel : Proc(Nil)? = nil

    def initialize(@title : String, @message : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
