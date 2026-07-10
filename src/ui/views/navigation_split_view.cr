# Multi-column navigation container (sidebar + content + detail) for iPad and macOS.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # NavigationSplitView — Multi-column navigation container (sidebar + content + detail) for iPad and macOS.
  class NavigationSplitView < View
    property sidebar : View? = nil
    property content : View? = nil
    property detail : View? = nil
    property sidebar_width : Float64 = 250.0
    property shows_sidebar : Bool = true
    property column_visibility : Symbol = :all # :all, :double_column, :detail_only

    # Phase 5 v2 — Apple semantic material override for the sidebar pane.
    # nil = use the HIG-canonical default (:sidebar). Callers pass the
    # `UI::DesignTokens::AppleSemantic#to_key` Symbol form (e.g.
    # `:sidebar`, `:menu`, `:system_resolved`); the renderer's populator
    # forwards the stringified key to the SwiftKit facade which resolves
    # it to a SwiftUI Material via `MaterialSemanticResolver`.
    property material_semantic : Symbol? = nil

    def initialize(@sidebar : View? = nil, @content : View? = nil, @detail : View? = nil)
      # Default container-query root: the split view's sidebar/content
      # ratio depends on its own width, not the viewport. Naming it
      # `split-view` lets the registered class CSS and inline render
      # output expose the same `@container split-view (...)` contract.
      @container_query_name = "split-view"
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
