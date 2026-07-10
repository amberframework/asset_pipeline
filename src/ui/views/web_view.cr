# Embedded web content view backed by WKWebView / WebView2.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # WebViewComponent — Embedded web content view backed by WKWebView / WebView2.
  class WebViewComponent < View
    property url : String = ""
    property html : String? = nil
    property base_url : String? = nil
    property allows_navigation : Bool = true
    property allows_scripts : Bool = true
    property title : String? = nil
    property on_navigation_request : Proc(String, Bool)? = nil
    property on_navigation_start : Proc(String, Nil)? = nil
    property on_navigation_finish : Proc(String, Nil)? = nil

    def initialize(@url : String = "")
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
