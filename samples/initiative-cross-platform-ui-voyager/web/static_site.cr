# Phase 6.10 — Voyager web build.
#
# Emits a single-page HTML doc with hash-route navigation. The four
# routes are pre-rendered as fragments at build time + served via
# UI::Web.render_route_host's JS shim, which swaps the visible
# fragment on hashchange / popstate / UIRouteHost.push().
#
# State-propagation litmus is implemented via a client-side state
# layer (vanilla JS), since static HTML can't invoke Crystal Procs.
# The Settings "Hide completed" toggle sets a class on the host
# document that hides .voyager-todo-row[data-completed="true"] in
# the Todos route. The chart counts are tagged with
# data-count-open / data-count-done and updated by the same JS on
# toggle change. This is the equivalent of the
# coordinator-on-change → host-rebuild flow that the native targets
# use, scoped to the constraints of the static-site target.

require "../app"
require "../../../src/ui/renderers/web_renderer"

OUTPUT_DIR = ARGV[0]? || File.expand_path("../../../output/voyager-demo", __DIR__)
Dir.mkdir_p(OUTPUT_DIR)

def render_route(slug : String, state : Voyager::State, coord : UI::NavigationCoordinator) : String
  # Phase 6.11 Item 1 — brand override removed. Renderer carries
  # `UI::DesignTokens::Tokens.default` already; no per-host override.
  route = Voyager.route_for_slug(slug)
  view = Voyager.build_route(state, coord, route)
  renderer = UI::Web::Renderer.new
  renderer.render(view)
end

# Build all 4 routes from a fresh state. The coordinator's on_change
# callbacks aren't fired at static-site build time — we directly
# render each slug to get its initial HTML fragment.
state = Voyager::State.new
coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))

routes = {} of String => String
Voyager::SLUGS.each do |slug|
  routes[slug] = render_route(slug, state, coord)
end

# Pre-render the theme CSS once. Default tokens (no brand override).
theme_renderer = UI::Web::Renderer.new
theme_css = theme_renderer.inject_theme_css

# Build the page. Body holds the route host (initial route =
# voyager-sign-in) + the client-side state script (Voyager-specific,
# layered atop the generic UIRouteHost shim).
APPEARANCES = ["light", "dark"]

APPEARANCES.each do |appearance|
  page = String.build do |io|
    io << "<!doctype html>\n"
    io << %(<html lang="en" data-appearance="#{appearance}">) << '\n'
    io << "<head>\n"
    io << %(<meta charset="utf-8">) << '\n'
    io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
    io << "<title>Voyager — Navigable Todos Demo (#{appearance})</title>\n"
    io << theme_css
    io << "<style>\n"
    io << "body { margin: 0; min-height: 100vh; "
    io << "background: var(--ap-color-surface-canvas); "
    io << "color: var(--ap-color-text-primary); "
    io << "font-family: var(--ap-font-sans); }\n"
    io << "[data-appearance=\"dark\"] { color-scheme: dark; }\n"
    io << "[data-appearance=\"light\"] { color-scheme: light; }\n"
    # The completed-row hide rule: when the doc has the
    # `voyager-hide-completed` class, any swipe-row marked with
    # data-todo-completed="true" is hidden. The JS layer annotates
    # each row based on the rendered checkmark icon ([x] vs [ ]).
    io << ".voyager-hide-completed [data-todo-completed=\"true\"] { display: none !important; }\n"
    io << "</style>\n"
    io << "</head>\n"
    io << %(<body data-appearance="#{appearance}">) << '\n'

    # Brand banner so the user knows which demo + appearance.
    io << %(<div style="padding: 8px 16px; background: var(--ap-color-brand-primary); color: white; font-family: var(--ap-font-sans); font-size: 13px;">)
    io << "Voyager Demo (#{appearance}) — navigable: try Sign in → Todos → Settings → toggle Hide completed → Back to Todos"
    io << "</div>\n"

    # The route host.
    io << UI::Web.render_route_host(routes, "voyager-sign-in")

    # Voyager-specific state JS.
    io << <<-JS
<script>
(function() {
  // Voyager client-side state mirror. Initialised to match the
  // server-rendered initial state; mutated by Settings toggle +
  // surfaced into the Todos route via DOM toggles.
  window.VoyagerState = {
    hideCompleted: false,
    setHideCompleted: function(value) {
      this.hideCompleted = !!value;
      document.documentElement.classList.toggle('voyager-hide-completed', this.hideCompleted);
      this.refreshTodosChrome();
    },
    // Recount visible rows + write the open/done counts back into
    // the chart cells AND show/hide the filter banner. This is the
    // direct DOM equivalent of the Crystal-side route rebuild.
    refreshTodosChrome: function() {
      var rows = document.querySelectorAll('[data-component="swipe-action-row"][data-todo-completed]');
      if (rows.length === 0) return; // not on the Todos route
      var open = 0, done = 0;
      rows.forEach(function(r) {
        // visible_todos semantics: when hideCompleted is on,
        // completed rows are display:none — count only what would
        // be rendered.
        var isCompleted = r.getAttribute('data-todo-completed') === 'true';
        if (window.VoyagerState.hideCompleted && isCompleted) return;
        if (isCompleted) done++; else open++;
      });
      var openEl = document.querySelector('span[data-testid="voyager-count-open"]');
      var doneEl = document.querySelector('span[data-testid="voyager-count-done"]');
      if (openEl) openEl.textContent = open;
      if (doneEl) doneEl.textContent = done;

      var banner = document.querySelector('[data-testid="voyager-todos-filter-banner"]');
      if (window.VoyagerState.hideCompleted) {
        if (!banner) {
          var todoRoot = document.querySelector('[data-testid="voyager-todos-root"]');
          if (todoRoot && todoRoot.children.length >= 2) {
            banner = document.createElement('div');
            banner.setAttribute('data-testid', 'voyager-todos-filter-banner');
            banner.textContent = 'Completed items hidden (toggle in Settings)';
            banner.style.fontSize = '13px';
            banner.style.color = 'var(--ap-color-text-tertiary)';
            banner.style.padding = '0 4px';
            // Insert after the chart row (index 1).
            todoRoot.insertBefore(banner, todoRoot.children[2] || null);
          }
        }
      } else if (banner && banner.parentNode) {
        banner.parentNode.removeChild(banner);
      }
    }
  };

  // Wire the Settings toggle on first render (and after each
  // navigation, since the host re-binds the route's fragment).
  function bindSettings() {
    var toggle = document.querySelector('[data-testid="voyager-settings-hide-completed"] input[type="checkbox"], [data-testid="voyager-settings-hide-completed"]');
    if (!toggle) return;
    // The toggle was rendered with a default state; reflect any
    // existing client-side state.
    if (toggle.type === 'checkbox') {
      toggle.checked = window.VoyagerState.hideCompleted;
      toggle.addEventListener('change', function() {
        window.VoyagerState.setHideCompleted(toggle.checked);
      });
    }
    // Wire the back button to UIRouteHost.pop -> render todos.
    var back = document.querySelector('[data-testid="voyager-settings-back"]');
    if (back) {
      back.addEventListener('click', function(e) {
        e.preventDefault();
        if (window.UIRouteHost) window.UIRouteHost.push('voyager-todos');
      });
    }
  }
  function bindSignIn() {
    var submit = document.querySelector('[data-testid="voyager-sign-in-submit"]');
    if (submit) {
      submit.addEventListener('click', function(e) {
        e.preventDefault();
        if (window.UIRouteHost) window.UIRouteHost.push('voyager-todos');
      });
    }
  }
  function bindTodos() {
    var settings = document.querySelector('[data-testid="voyager-todos-settings"]');
    if (settings) {
      settings.addEventListener('click', function(e) {
        e.preventDefault();
        if (window.UIRouteHost) window.UIRouteHost.push('voyager-settings');
      });
    }
    // Annotate each row with its completion state from the
    // rendered icon text so the hide rule + chart can resolve.
    document.querySelectorAll('[data-component="swipe-action-row"]').forEach(function(row) {
      if (row.hasAttribute('data-todo-completed')) return;
      var icon = row.querySelector('.ap-swipe-row__content span');
      if (icon && icon.textContent.trim() === '[x]') {
        row.setAttribute('data-todo-completed', 'true');
      } else if (icon) {
        row.setAttribute('data-todo-completed', 'false');
      }
    });
    // Re-apply the hide rule + chart sync. State survives across
    // route changes — this is the litmus.
    window.VoyagerState.refreshTodosChrome();
  }
  function bindAll() {
    bindSignIn();
    bindTodos();
    bindSettings();
  }
  // Observe route changes so we re-bind after fragment swap.
  var host = document.getElementById('ui-route-host');
  if (host) {
    var mo = new MutationObserver(function() { bindAll(); });
    mo.observe(host, {childList: true, subtree: true});
  }
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', bindAll);
  } else {
    bindAll();
  }
})();
</script>
JS
    io << "\n</body>\n</html>\n"
  end

  out_path = File.join(OUTPUT_DIR, "voyager-#{appearance}.html")
  File.write(out_path, page)
  puts "wrote #{out_path}"
end

# Also emit per-route static HTML files for baseline-capture parity
# with the Cascade build.
APPEARANCES.each do |appearance|
  Voyager::SLUGS.each do |slug|
    fresh_state = Voyager::State.new
    fresh_coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:sign_in))
    body_html = render_route(slug, fresh_state, fresh_coord)

    html = String.build do |io|
      io << "<!doctype html>\n"
      io << %(<html lang="en" data-appearance="#{appearance}">) << '\n'
      io << "<head>\n"
      io << %(<meta charset="utf-8">) << '\n'
      io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
      io << "<title>Voyager · #{slug} (#{appearance})</title>\n"
      io << theme_css
      io << "<style>\n"
      io << "body { margin: 0; min-height: 100vh; "
      io << "background: var(--ap-color-surface-canvas); "
      io << "color: var(--ap-color-text-primary); "
      io << "font-family: var(--ap-font-sans); }\n"
      io << "[data-appearance=\"dark\"] { color-scheme: dark; }\n"
      io << "[data-appearance=\"light\"] { color-scheme: light; }\n"
      io << "</style>\n"
      io << "</head>\n"
      io << %(<body data-appearance="#{appearance}" data-slug="#{slug}">) << '\n'
      io << body_html
      io << "\n</body>\n</html>\n"
    end

    out_path = File.join(OUTPUT_DIR, "#{slug}-#{appearance}.html")
    File.write(out_path, html)
    puts "wrote #{out_path}"
  end
end

# Index page.
index = String.build do |io|
  io << "<!doctype html>\n<html lang=\"en\">\n<head>\n"
  io << %(<meta charset="utf-8">) << '\n'
  io << %(<meta name="viewport" content="width=device-width, initial-scale=1">) << '\n'
  io << "<title>Voyager — index</title>\n"
  io << "<style>\n"
  io << "body { font-family: -apple-system, system-ui, sans-serif; max-width: 720px; margin: 40px auto; padding: 24px; line-height: 1.5; }\n"
  io << "table { width: 100%; border-collapse: collapse; }\n"
  io << "th, td { text-align: left; padding: 8px 12px; border-bottom: 1px solid #ccc; }\n"
  io << "a { color: #4338ca; text-decoration: none; }\n"
  io << "a:hover { text-decoration: underline; }\n"
  io << "</style>\n</head>\n<body>\n"
  io << "<h1>Voyager — Navigable Todos demo</h1>\n"
  io << "<p>Phase 6.10. Click the single-page navigable app, or open any individual screen.</p>\n"
  io << "<h2>Navigable app (single-page, hash-routed)</h2>\n"
  io << %(<p><a href="voyager-light.html">▶ Open Voyager (light)</a> &nbsp; )
  io << %(<a href="voyager-dark.html">▶ Open Voyager (dark)</a></p>) << '\n'
  io << "<h2>Per-screen baselines</h2>\n"
  io << "<table>\n<thead><tr><th>Slug</th><th>Light</th><th>Dark</th></tr></thead>\n<tbody>\n"
  Voyager::SLUGS.each do |slug|
    io << "<tr><td>#{slug}</td>"
    io << %Q(<td><a href="#{slug}-light.html">light</a></td>)
    io << %Q(<td><a href="#{slug}-dark.html">dark</a></td>)
    io << "</tr>\n"
  end
  io << "</tbody>\n</table>\n</body>\n</html>\n"
end

File.write(File.join(OUTPUT_DIR, "index.html"), index)
puts "wrote #{File.join(OUTPUT_DIR, "index.html")}"
puts "Voyager web build done — #{Voyager::SLUGS.size * APPEARANCES.size + APPEARANCES.size + 1} files."
