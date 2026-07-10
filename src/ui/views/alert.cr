# Modal alert dialog used to confirm critical information or destructive actions.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A modal alert dialog with title, message, and action buttons.
  class Alert < View
    # Alert button definition
    record AlertButton,
      label : String,
      style : Symbol = :default,
      action : Proc(Nil)? = nil

    # Alert title
    property title : String

    # Alert message body
    property message : String = ""

    # Action buttons
    property buttons : Array(AlertButton) = [] of AlertButton

    # Whether the alert is currently presented
    property is_presented : Bool = false

    # Phase 5 v2 — Apple semantic material override. nil = HIG-canonical
    # default :system_resolved (SwiftUI `.alert` is system-drawn; Apple
    # explicitly recommends letting the system handle alert chrome).
    # Setting this has no visible effect on the active SwiftUI `.alert`
    # path; preserved for cross-platform symmetry with the other Category
    # B widgets' material override surface.
    property material_semantic : Symbol? = nil

    def initialize(@title : String, @message : String = "")
    end

    # Add a button to the alert with a block action
    def add_button(label : String, style : Symbol = :default, &action : -> Nil)
      @buttons << AlertButton.new(label: label, style: style, action: action)
    end

    # Add a button without action
    def add_button(label : String, style : Symbol = :default)
      @buttons << AlertButton.new(label: label, style: style)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
