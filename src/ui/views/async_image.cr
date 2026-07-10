# Image view that loads its content asynchronously from a URL.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # AsyncImage — Image view that loads its content asynchronously from a URL.
  class AsyncImage < View
    property url : String = ""
    property placeholder : View? = nil
    property content_mode : ContentMode = ContentMode::Fit
    property is_loading : Bool = false
    property error_message : String? = nil
    property on_load : Proc(Nil)? = nil
    property on_error : Proc(String, Nil)? = nil

    def initialize(@url : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
