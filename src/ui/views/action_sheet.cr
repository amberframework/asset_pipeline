# Modal sheet of choices presented at the bottom of the screen on iOS.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

{% if flag?(:ios) %}
  # Top-level namespace for the asset_pipeline cross-platform UI system.
  module UI
    # Tier 3 — iOS-only. Use UI::ActionSheetWithWebFallback to render on
    # web (or anywhere a cross-platform fallback is acceptable).
    #
    # Builds with -Dios. On every other target, constructing this class
    # (`UI::ActionSheet.new(...)`) is a compile-time error; pure type
    # references and `.allocate` still compile (the constructor macro
    # is the gate). See _gate_stubs/action_sheet.cr.
    #
    # iOS rendering currently routes through SwiftKit's ConfirmationDialogFacade
    # which exposes a binary confirm/cancel surface; ActionSheet with more
    # than one non-cancel action degrades to {first non-cancel action,
    # cancel action} pending a Phase 5 multi-action SwiftUI facade.
    class ActionSheet < View
      record Action,
        label : String,
        style : Symbol = :default, # :default | :destructive | :cancel
        action : Proc(Nil)? = nil

      property title : String = ""
      property message : String = ""
      property actions : Array(Action) = [] of Action
      property is_presented : Bool = false

      def initialize(@title : String = "", @message : String = "")
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
      end

      def add_action(label : String, style : Symbol = :default)
        @actions << Action.new(label: label, style: style)
      end

      def primary_action : Action?
        @actions.find { |a| a.style != :cancel }
      end

      def cancel_action : Action?
        @actions.find { |a| a.style == :cancel }
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    end
  end
{% else %}
  # On non-iOS targets, hand off to the gate stub file. Its compile-time
  # raise only fires at construction sites because the stub is NOT nested
  # inside this outer macro guard — see the comment header on the stub
  # file itself for the macro-expansion rationale. The stub lives in a
  # subdirectory so the require glob in src/ui.cr does not pull it in
  # on -Dios builds.
  require "./_gate_stubs/action_sheet"
{% end %}
