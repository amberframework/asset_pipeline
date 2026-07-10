# Compile-time stub for `UI::ContextMenu` on non-Apple-family targets.
#
# Lives outside an `{% if flag?(...) %}` macro so the `{% raise %}` inside
# `macro new` only fires at construction sites, not at class-definition
# time. This file must only be required when neither `flag?(:macos)` nor
# `flag?(:ios)` is set — see `src/ui/views/context_menu.cr` for the gate.

module UI
  # Long-press / right-click contextual menu attached to a host view (Apple-family only).
  class ContextMenu
    macro new(*args, **kwargs)
      {% raise <<-MSG
        UI::ContextMenu is Apple-family only (Tier 3). This build does not have -Dmacos or -Dios.

        Pick one:

        1. Build with -Dmacos or -Dios:
             crystal build my_app.cr -Dmacos
             crystal build my_app.cr -Dios

        2. Use the explicit web-fallback class instead:
             UI::ContextMenuWithWebFallback.new
           which renders a native context menu on Apple targets and an
           accessible vanilla-JS positioned dropdown on web.

        3. Guard the usage at the call site:
             {% if flag?(:macos) || flag?(:ios) %}
               menu = UI::ContextMenu.new
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
