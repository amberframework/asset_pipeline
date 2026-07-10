# Phase 4 R1 web demo — ContextMenuWithWebFallback CDP test page.
#
# Renders three independent menus with three triggers positioned in
# the top-left, center, and bottom-right of the viewport. That layout
# satisfies the `conformance.context-menu-positioning` rubric, which
# requires "three real trigger positions" and the menu to fit within
# the viewport after each open.
#
# Codex Checkpoint 1 confirmed:
#   * Trigger is rendered as the host's first child (visitor walks
#     `view.trigger` before the menu list), so the fallback JS's
#     findTrigger() picks it up.
#   * The renderer's @context_menu_css_emitted guard emits the
#     CSS/JS exactly once (in the first host); subsequent hosts
#     are bound by the JS's document-wide init() on DOMContentLoaded.
#   * View-level styling hook does not exist for Button, so the
#     trigger quadrants are positioned via page-level CSS keyed
#     off `[data-testid="ctx-trigger-*"]`.
#
# Usage:
#   crystal run samples/cross_platform/web/phase04_context_menu_demo.cr -- \
#     samples/cross_platform/web/dist/phase04_context_menu_demo.html

require "../../../src/ui"
require "../../../src/ui/design_tokens"
require "../../../src/ui/design_tokens/generators/web_generator"

def build_menu(testid : String, label : String) : UI::ContextMenuWithWebFallback
  trigger = UI::Button.new(label)
  trigger.test_id = testid
  menu = UI::ContextMenuWithWebFallback.new(trigger: trigger)
  menu.add_item("Open")
  menu.add_item("Rename")
  menu.add_item("Duplicate", is_disabled: true)
  menu.add_separator
  menu.add_item("Delete", is_destructive: true)
  menu.test_id = "ctx-menu-#{testid.sub("ctx-trigger-", "")}"
  menu
end

root = UI::VStack.new(spacing: 16.0)
root << build_menu("ctx-trigger-tl", "Top-left trigger")
root << build_menu("ctx-trigger-center", "Center trigger")
root << build_menu("ctx-trigger-br", "Bottom-right trigger")

renderer = UI::Web::Renderer.new
body_html = renderer.render(root)
token_css = UI::DesignTokens::WebGenerator.generate(UI::DesignTokens::Tokens.default)

helpers_js = <<-JS
window.__phase4 = (function () {
  function triggerFor(slug) {
    return document.querySelector('[data-testid="ctx-trigger-' + slug + '"]');
  }
  function hostFor(slug) {
    var t = triggerFor(slug);
    return t ? t.closest('[data-ap-ctx-host]') : null;
  }
  function menuFor(slug) {
    var h = hostFor(slug);
    return h ? h.querySelector('.ap-ctx-menu') : null;
  }
  function ensureDismissLog() {
    if (window.__phase4DismissLog) return;
    window.__phase4DismissLog = [];
    document.querySelectorAll('[data-ap-ctx-host]').forEach(function (host) {
      host.addEventListener('ap:ctx-menu:dismiss', function (e) {
        window.__phase4DismissLog.push({
          reason: e.detail && e.detail.reason,
          host_testid: host.querySelector('[data-testid^="ctx-trigger-"]')
            && host.querySelector('[data-testid^="ctx-trigger-"]').getAttribute('data-testid'),
        });
      });
    });
  }
  return {
    triggerFor: triggerFor,
    hostFor: hostFor,
    menuFor: menuFor,
    ensureDismissLog: ensureDismissLog,
  };
})();
window.__phase4.ensureDismissLog();
JS

# Page-level styling: positions triggers in the documented quadrants
# (within 16 px of the documented corner per the rubric); resets default
# margins so getBoundingClientRect math is deterministic.
positioning_css = <<-CSS
html, body {
  margin: 0;
  font-family: var(--ap-font-sans);
  background: var(--ap-color-surface-canvas);
  color: var(--ap-color-text-primary);
  min-height: 100%;
}
[data-testid="ctx-trigger-tl"] {
  position: fixed; top: 0; left: 0;
}
[data-testid="ctx-trigger-center"] {
  position: fixed; top: 50%; left: 50%;
  transform: translate(-50%, -50%);
}
[data-testid="ctx-trigger-br"] {
  position: fixed; bottom: 0; right: 0;
}
.visually-hidden {
  position: absolute; width: 1px; height: 1px;
  padding: 0; margin: -1px; overflow: hidden;
  clip: rect(0 0 0 0); white-space: nowrap; border: 0;
}
.visually-hidden:focus, .visually-hidden:focus-visible {
  position: static; width: auto; height: auto;
  margin: 0; clip: auto; white-space: normal;
}
CSS

html = String.build do |io|
  io << "<!doctype html>\n"
  io << %(<html lang="en">\n<head>\n)
  io << %(<meta charset="utf-8">\n)
  io << %(<meta name="viewport" content="width=device-width,initial-scale=1">\n)
  io << "<title>Phase 4 — ContextMenuWithWebFallback CDP demo</title>\n"
  io << "<style>\n" << token_css << "\n" << positioning_css << "\n</style>\n</head>\n<body>\n"
  io << %(<header><a href="#main" class="visually-hidden">Skip to main content</a></header>\n)
  io << %(<main id="main" aria-label="Phase 4 context menu demo">\n)
  io << body_html
  io << "\n</main>\n<script>\n" << helpers_js << "\n</script>\n</body>\n</html>\n"
end

output_path = ARGV[0]? || "samples/cross_platform/web/dist/phase04_context_menu_demo.html"
File.write(output_path, html)
STDOUT.puts "wrote #{output_path} (#{html.bytesize} bytes)"
