# Modal sheet that slides up from the bottom (iOS) or appears as a dialog (macOS).
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) || flag?(:ios) %}
  require "../native/swiftkit_bridge"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Sheet — Modal sheet that slides up from the bottom (iOS) or appears as a dialog (macOS).
  class Sheet < View
    property content : View? = nil
    getter is_presented : Bool = false

    # Phase 3 Remediation 10 — reactive setter. Mirrors the
    # `UI::Toggle#is_on=` pattern: setting `is_presented` after the
    # renderer has emitted the SwiftKit hosting view dispatches
    # through `apsk_sheet_set_presented`, which flips the
    # `APSKSheetState.isPresented` `@Published` field and triggers a
    # SwiftUI re-render that presents / dismisses the sheet via
    # `.sheet(isPresented:)`. Setters issued before the view has been
    # rendered are simply stored on the property; the next render
    # seeds the reactive state from the new value.
    def is_presented=(new_value : Bool) : Bool
      @is_presented = new_value
      {% if flag?(:macos) || flag?(:ios) %}
        if sh = @swiftkit_state_handle
          LibSwiftKitBridge.apsk_sheet_set_presented(sh, new_value ? 1 : 0)
        end
      {% end %}
      new_value
    end

    property shows_drag_indicator : Bool = true
    property detents : Array(Symbol) = [:medium, :large]  # :small, :medium, :large, :custom
    property selected_detent : Symbol = :medium
    property on_dismiss : Proc(Nil)? = nil

    # HIG surface-chrome style. Controls how renderers paint the sheet's
    # container when rendering inline (i.e., when is_presented is false or
    # the visitor is drawing the content directly into the host view).
    #   :auto         — render with HIG grouped-card chrome by default
    #                   (rounded corners, grouped-background fill, 16pt
    #                   padding). This is the default so inline sheet
    #                   content reads like a real HIG presentation surface.
    #   :grouped_card — explicit grouped-card chrome.
    #   :plain        — no chrome; act as a bare container.
    property surface_style : Symbol = :auto

    # Phase 5 v2 — Apple semantic material override for the sheet's
    # presented background. nil = HIG-canonical :sheet (NSVisualEffectMaterialSheet
    # on macOS; .thickMaterial via .presentationBackground on iOS 16.4+).
    property material_semantic : Symbol? = nil

    def initialize(@content : View? = nil, *, @surface_style : Symbol = :auto)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end

  # Presentation state for a Sheet (is_presenting flag + the underlying view).
  class SheetPresenter
    property sheet : Sheet
    property is_presenting : Bool = false

    def initialize(@sheet : Sheet)
    end

    def present
      @is_presenting = true
      @sheet.is_presented = true
    end

    def dismiss
      @is_presenting = false
      @sheet.is_presented = false
      @sheet.on_dismiss.try(&.call)
    end
  end
end
