# Single-line search input with platform-idiomatic clear and scope affordances.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # SearchField — Single-line search input with platform-idiomatic clear and scope affordances.
  class SearchField < View
    property text : String = ""
    property placeholder : String = "Search"
    property is_searching : Bool = false
    property shows_cancel_button : Bool = true
    property on_change : Proc(String, Nil)? = nil
    property on_submit : Proc(String, Nil)? = nil
    property on_cancel : Proc(Nil)? = nil

    def initialize(@placeholder : String = "Search")
    end

    def initialize(@placeholder : String = "Search", &block : String -> Nil)
      @on_change = block
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
