# Phase 3 BX8 dismiss-path probe. Records which sheet dismiss path (primary,
# cancel, swipe, backdrop, escape) fired so AXTest / XCUITest can assert it.

require "./probe_store"

module UI::Probes
  # DismissProbe — Phase 3 rubric BX8.
  #
  # Backs the `phase-03-sheet-focus-return` slug. Each documented sheet
  # dismiss path (primary, cancel, swipe, backdrop, escape) writes a
  # canonical reason string into `last_reason`. A mirror Label reads it
  # so XCUITest / AXTest harnesses can assert which dismiss path fired.
  #
  # Phase 3 Remediation 10 — explicit-flag guard semantics:
  #   SwiftUI `.sheet(isPresented:)`'s onDismiss closure fires AFTER
  #   every dismissal including the button-driven ones (when the
  #   button's on_tap sets `sheet.is_presented = false`). If the
  #   on_dismiss callback naively wrote "swipe" it would clobber the
  #   "primary" / "cancel" reason the button already recorded.
  #
  #   Pattern: `mark_explicit(reason)` records the reason AND sets the
  #   explicit flag; `handle_dismiss` writes "swipe" ONLY IF the flag is
  #   clear (interactive dismissal) and ALWAYS clears the flag for the
  #   next presentation. Button on_tap calls `mark_explicit` then sets
  #   `sheet.is_presented = false`; sheet.on_dismiss calls
  #   `handle_dismiss`.
  module DismissProbe
    @@last_reason : String = "none"
    @@explicit : Bool = false

    def self.last_reason : String
      @@last_reason
    end

    def self.set(reason : String) : Nil
      @@last_reason = reason
      ProbeStore.instance.set("dismiss-reason", reason)
    end

    def self.reset : Nil
      @@last_reason = "none"
      @@explicit = false
      ProbeStore.instance.set("dismiss-reason", "none")
    end

    def self.current_text : String
      @@last_reason
    end

    # Button-driven dismiss. Records the canonical reason AND marks the
    # explicit flag so the subsequent `handle_dismiss` (fired by
    # SwiftUI's onDismiss closure) does not overwrite with "swipe".
    def self.mark_explicit(reason : String) : Nil
      @@explicit = true
      set(reason)
    end

    # Wired to UI::Sheet#on_dismiss. Records "swipe" ONLY IF this
    # dismissal was not a previously-marked explicit action.
    # Always clears the explicit flag for the next sheet presentation.
    def self.handle_dismiss : Nil
      set("swipe") unless @@explicit
      @@explicit = false
    end
  end
end
