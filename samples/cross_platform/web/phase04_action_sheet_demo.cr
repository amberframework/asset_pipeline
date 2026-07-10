# Phase 4 R1 web demo — ActionSheetWithWebFallback CDP test page.
#
# Renders a single page containing one trigger button + one
# ActionSheetWithWebFallback. The action sheet is rendered with
# `is_presented: false` so the fallback JS's MutationObserver sees a
# real closed -> open transition when `__phase4.open()` toggles
# `data-presented`. That transition is required for the focus-trap
# probe (the JS only stashes `previouslyFocused` and runs `show()`
# on the false -> true edge) and for the focus-restoration probes.
#
# Codex Checkpoint 1 (see codex_reviews/checkpoint1-page-design.txt):
#   "Make open() force a real transition" — addressed by setting
#   data-presented=false first, then true on rAF.
#   "Attach the dismiss listener once" — addressed by installing
#   the listener at DOMContentLoaded, not inside open().
#
# Usage:
#   crystal run samples/cross_platform/web/phase04_action_sheet_demo.cr -- \
#     samples/cross_platform/web/dist/phase04_action_sheet_demo.html

require "../../../src/ui"
require "../../../src/ui/design_tokens"
require "../../../src/ui/design_tokens/generators/web_generator"

trigger = UI::Button.new("Open action sheet")
trigger.test_id = "action-sheet-trigger"

sheet = UI::ActionSheetWithWebFallback.new(
  "Action sheet demo",
  "Pick a destructive option.",
)
sheet.add_action("Save", :default)
sheet.add_action("Delete", :destructive)
sheet.add_action("Cancel", :cancel)
sheet.is_presented = false
sheet.test_id = "action-sheet-host"

root = UI::VStack.new(spacing: 12.0)
root << trigger
root << sheet

renderer = UI::Web::Renderer.new
body_html = renderer.render(root)
token_css = UI::DesignTokens::WebGenerator.generate(UI::DesignTokens::Tokens.default)

# Helpers exposed for the CDP harness. Pure JS, no framework.
#  * __phase4.open() forces a closed -> open transition.
#  * The dismiss-log listener is attached once at DOMContentLoaded.
#  * The trigger button starts at a stable, deterministic position so
#    layout / touch-target probes have predictable rects.
helpers_js = <<-JS
window.__phase4 = (function () {
  function trigger() {
    return document.querySelector('[data-testid="action-sheet-trigger"]');
  }
  function sheet() {
    return document.querySelector('.ap-action-sheet[data-component="action-sheet"]');
  }
  function panel() {
    return document.querySelector('.ap-action-sheet__panel');
  }
  function backdrop() {
    return document.querySelector('.ap-action-sheet__backdrop');
  }
  function focusables() {
    var FOCUSABLE =
      'a[href],button:not([disabled]),input:not([disabled]),' +
      'select:not([disabled]),textarea:not([disabled]),' +
      '[tabindex]:not([tabindex="-1"])';
    return Array.from(panel().querySelectorAll(FOCUSABLE));
  }
  function ensureDismissLog() {
    if (window.__phase4DismissLog) return;
    window.__phase4DismissLog = [];
    sheet().addEventListener('ap:action-sheet:dismiss', function (e) {
      window.__phase4DismissLog.push(e.detail);
    });
  }
  function open() {
    ensureDismissLog();
    trigger().focus();
    window.__preOpenFocus = document.activeElement;
    window.__trigger = document.activeElement;
    var s = sheet();
    // Force closed -> open transition so the fallback's MutationObserver
    // sees an edge and runs show().
    s.setAttribute('data-presented', 'false');
    return new Promise(function (resolve) {
      requestAnimationFrame(function () {
        s.setAttribute('data-presented', 'true');
        // Wait for the second rAF so show()'s own rAF has run and
        // focus has landed inside the panel.
        requestAnimationFrame(function () {
          requestAnimationFrame(resolve);
        });
      });
    });
  }
  function close() {
    sheet().setAttribute('data-presented', 'false');
    window.__phase4DismissLog = null;
  }
  function resetTrace() { window.__focusTrace = []; }
  function pushTrace() {
    var el = document.activeElement;
    var p = panel();
    window.__focusTrace.push({
      n: window.__focusTrace.length,
      tag: el ? el.tagName : null,
      testid: el ? el.getAttribute && el.getAttribute('data-testid') : null,
      label: el && el.textContent ? el.textContent.slice(0, 40) : null,
      inside: !!(el && p && p.contains(el)),
    });
  }
  return {
    trigger: trigger, sheet: sheet, panel: panel,
    backdrop: backdrop, focusables: focusables,
    ensureDismissLog: ensureDismissLog,
    open: open, close: close,
    resetTrace: resetTrace, pushTrace: pushTrace,
  };
})();
// Trigger button gets a stable rect for layout probes.
var __style = document.createElement('style');
__style.textContent = [
  'body { padding: 16px; }',
  '[data-testid="action-sheet-trigger"] { position: fixed; top: 16px; left: 16px; z-index: 1; }',
].join('\\n');
document.head.appendChild(__style);
JS

html = String.build do |io|
  io << "<!doctype html>\n"
  io << %(<html lang="en">\n<head>\n)
  io << %(<meta charset="utf-8">\n)
  io << %(<meta name="viewport" content="width=device-width,initial-scale=1">\n)
  io << "<title>Phase 4 — ActionSheetWithWebFallback CDP demo</title>\n"
  io << "<style>\n"
  io << token_css
  io << <<-CSS

  html, body {
    margin: 0;
    font-family: var(--ap-font-sans);
    background: var(--ap-color-surface-canvas);
    color: var(--ap-color-text-primary);
    min-height: 100%;
  }
  body { padding: 16px; }
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
  io << "\n</style>\n</head>\n<body>\n"
  io << %(<header><a href="#main" class="visually-hidden">Skip to main content</a></header>\n)
  io << %(<main id="main" aria-label="Phase 4 action sheet demo">\n)
  io << body_html
  io << "\n</main>\n<script>\n"
  io << helpers_js
  io << "\n</script>\n</body>\n</html>\n"
end

output_path = ARGV[0]? || "samples/cross_platform/web/dist/phase04_action_sheet_demo.html"
File.write(output_path, html)
STDOUT.puts "wrote #{output_path} (#{html.bytesize} bytes)"
