# Transient toast / snackbar notification anchored to the bottom of the screen.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Snackbar — Transient toast / snackbar notification anchored to the bottom of the screen.
  class Snackbar < View
    property message : String
    property action_label : String? = nil
    property duration : Float64 = 4.0  # seconds
    property is_presented : Bool = false
    property on_action : Proc(Nil)? = nil
    property on_dismiss : Proc(Nil)? = nil

    def initialize(@message : String, @action_label : String? = nil)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  # Presentation state for a Snackbar (is_presenting flag + the underlying view).
  class SnackbarPresenter
    property snackbar : Snackbar
    property is_presenting : Bool = false

    def initialize(@snackbar : Snackbar)
    end

    def show
      @is_presenting = true
      @snackbar.is_presented = true
    end

    def dismiss
      @is_presenting = false
      @snackbar.is_presented = false
      @snackbar.on_dismiss.try(&.call)
    end
  end
end
