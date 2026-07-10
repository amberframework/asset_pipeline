# Button styled as a hyperlink that opens or dispatches a navigation action.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # LinkButton — Button styled as a hyperlink that opens or dispatches a navigation action.
  class LinkButton < View
    property label : String
    property url : String = ""
    property opens_in_browser : Bool = true
    property on_tap : Proc(Nil)? = nil

    def initialize(@label : String, @url : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
