# Compile-time stub for `UI::PathControl` on non-macOS targets.
#
# Lives outside an `{% if flag?(...) %}` macro so the `{% raise %}` inside
# `macro new` only fires at construction sites, not at class-definition
# time. This file must only be required when `flag?(:macos)` is FALSE —
# see `src/ui/views/path_control.cr` for the gate.

module UI
  # macOS path control showing a filesystem-style breadcrumb (macOS only).
  class PathControl
    macro new(*args, **kwargs)
      {% raise <<-MSG
        UI::PathControl is macOS-only (Tier 3). NSPathControl has no honest
        cross-platform analog. This build does not have -Dmacos.

        Pick one:

        1. Build with -Dmacos:
             crystal build my_app.cr -Dmacos

        2. Use the explicit web-fallback class instead:
             UI::PathControlWithWebFallback.new(...)
           which renders a native NSPathControl on -Dmacos and a
           `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` on every
           other target.

        3. Guard the usage at the call site:
             {% if flag?(:macos) %}
               path = UI::PathControl.new(...)
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
