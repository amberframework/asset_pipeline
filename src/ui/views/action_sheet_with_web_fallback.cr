# Tier-3 action sheet with a web-compatible fallback rendering on non-iOS targets.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:ios) %}
  require "./action_sheet"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Cross-platform companion to the iOS-only UI::ActionSheet.
  #
  # On -Dios: delegates to a held UI::ActionSheet instance, so the iOS
  # visitor renders the native action sheet (currently via the
  # ConfirmationDialogFacade; see ActionSheet docs for the N->2 caveat).
  #
  # On every other platform: renders directly. The web visitor produces a
  # role=dialog bottom-sheet with backdrop, focus trap, escape-to-dismiss,
  # and a vanilla-JS event contract (see action_sheet_fallback.js). The
  # macOS and Android visitors synthesize a UI::ConfirmationDialog and
  # delegate to the existing visitor for those platforms.
  #
  # Both branches share the same public API so application code that uses
  # this class is fully portable.
  class ActionSheetWithWebFallback < View
    record Action,
      label : String,
      style : Symbol = :default, # :default | :destructive | :cancel
      action : Proc(Nil)? = nil

    property title : String = ""
    property message : String = ""
    property actions : Array(Action) = [] of Action
    property is_presented : Bool = false

    {% if flag?(:ios) %}
      @inner : UI::ActionSheet

      def initialize(@title : String = "", @message : String = "")
        @inner = UI::ActionSheet.new(@title, @message)
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
        @inner.add_action(label, style, &block)
      end

      def add_action(label : String, style : Symbol = :default)
        @actions << Action.new(label: label, style: style)
        @inner.add_action(label, style)
      end

      def accept(visitor : PlatformVisitor)
        @inner.title = @title
        @inner.message = @message
        @inner.is_presented = @is_presented
        @inner.accept(visitor)
      end
    {% else %}
      def initialize(@title : String = "", @message : String = "")
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
      end

      def add_action(label : String, style : Symbol = :default)
        @actions << Action.new(label: label, style: style)
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    {% end %}
  end
end
