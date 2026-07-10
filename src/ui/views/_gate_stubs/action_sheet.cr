# Compile-time stub for `UI::ActionSheet` on non-iOS targets.
#
# This file is intentionally NOT inside an `{% if flag?(:ios) %}` macro —
# Crystal's macro engine eagerly fires nested `{% raise %}` statements
# while expanding the outer guard, so wrapping the stub in an `if/else`
# fires the raise at definition time. Splitting the stub into a separate
# file that is conditionally required by `action_sheet.cr` defers the
# `{% raise %}` to actual call-site expansion of `UI::ActionSheet.new`.
#
# This file must only be required when `flag?(:ios)` is FALSE — see
# `src/ui/views/action_sheet.cr` for the gate.

module UI
  # Modal sheet of choices presented at the bottom of the screen on iOS (iOS only).
  class ActionSheet
    macro new(*args, **kwargs)
      {% raise <<-MSG
        UI::ActionSheet is iOS-only (Tier 3). This build does not have -Dios.

        Pick one:

        1. Build with -Dios:
             crystal build my_app.cr -Dios

        2. Use the explicit web-fallback class instead:
             UI::ActionSheetWithWebFallback.new(...)
           which renders a native iOS action sheet on -Dios and an
           accessible vanilla-JS bottom sheet on web (and a styled
           ConfirmationDialog on macOS / Android).

        3. Guard the usage at the call site:
             {% if flag?(:ios) %}
               sheet = UI::ActionSheet.new("Title", "Message")
               # ...
             {% else %}
               # alternate UI for this platform
             {% end %}

        See docs/initiative-cross-platform-ui/tier-matrix.md for the full
        tier classification and which widgets require which flags.
        MSG
      %}
    end
  end
end
