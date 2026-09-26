# Image view that loads its content asynchronously from a URL.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # AsyncImage — Image view that loads its content asynchronously from a URL.
  class AsyncImage < View
    # URL the view points at.
    property url : String = ""
    # Pre-fetched image bytes. Native renderers without an async URL loader
    # (UIKit) display these synchronously when present; web renderers keep
    # using `url`. Populated by callers that fetch ahead of render time.
    property preloaded_data : Bytes? = nil
    # Placeholder text shown when the field is empty.
    property placeholder : View? = nil
    # How the content is scaled / aligned within its frame (e.g. `:fit`, `:fill`, `:center`).
    property content_mode : ContentMode = ContentMode::Fit
    # Boolean toggle.
    property is_loading : Bool = false
    # Text value.
    property error_message : String? = nil
    # Invoked when the underlying resource finishes loading.
    property on_load : Proc(Nil)? = nil
    # Invoked with the error when the underlying resource fails to load.
    property on_error : Proc(String, Nil)? = nil

    def initialize(@url : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
