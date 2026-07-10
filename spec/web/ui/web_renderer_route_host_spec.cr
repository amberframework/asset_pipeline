require "../../../src/ui"
require "spec"

# Phase 6.10 D2 — UI::Web.render_route_host
#
# The web target is a single-page HTML document with hash-route
# navigation. This helper emits the JS shim + per-route fragment
# data so the browser can swap routes on hashchange / popstate /
# UIRouteHost.push() without a full page reload.
describe UI::Web do
  describe ".render_route_host" do
    it "emits the host div seeded with the initial route's fragment" do
      routes = {"sign-in" => "<p>Hello</p>", "todos" => "<p>Todos</p>"}
      out = UI::Web.render_route_host(routes, "sign-in")
      out.should contain "<div id=\"ui-route-host\""
      out.should contain "data-route=\"sign-in\""
      out.should contain "<p>Hello</p>"
    end

    it "embeds every route fragment in the JSON data block" do
      routes = {"a" => "<span>A</span>", "b" => "<span>B</span>"}
      out = UI::Web.render_route_host(routes, "a")
      out.should contain %(<script type="application/json" id="ui-route-data">)
      # JSON encodes routes as a JSON object; `</` is escaped to
      # `<\/` to prevent premature </script> termination, but the
      # browser's JSON.parse decodes it back to `</span>` on the
      # client. The encoded form is what the static HTML emits.
      out.should contain "\"a\":\"<span>A<\\/span>\""
      out.should contain "\"b\":\"<span>B<\\/span>\""
    end

    it "emits the JS shim with push/pop/replace/setFragment + hashchange + popstate" do
      out = UI::Web.render_route_host({"a" => "<p>A</p>"}, "a")
      out.should contain "UIRouteHost"
      out.should contain "window.addEventListener('hashchange'"
      out.should contain "window.addEventListener('popstate'"
      out.should contain "history.pushState"
      out.should contain "setFragment"
    end

    it "emits an aria-live announcer for I-6 a11y" do
      out = UI::Web.render_route_host({"a" => "<p>A</p>"}, "a")
      out.should contain %(id="ui-route-announcer")
      out.should contain "aria-live=\"polite\""
    end

    it "escapes embedded quotes and newlines safely in the JSON block" do
      routes = {"a" => %(<p class="x">line1\nline2</p>)}
      out = UI::Web.render_route_host(routes, "a")
      out.should contain %(class=\\"x\\")
      out.should contain "line1\\nline2"
    end

    it "neutralises </script> sequences inside the JSON data block" do
      # If raw `</script>` reaches the JSON script body it would
      # prematurely terminate it. The implementation rewrites `</`
      # to `<\/` inside the JSON payload (still valid JSON; the
      # browser's JSON.parse decodes it). Outside the script (in
      # the host div's HTML body) `</script>` is harmless text and
      # is left alone.
      routes = {"a" => "<p>before</script>after</p>"}
      out = UI::Web.render_route_host(routes, "a")
      # Pluck the JSON data block body (between the opening
      # <script ...> and the first </script>).
      match = out.match(/<script type="application\/json"[^>]*>([\s\S]*?)<\/script>/)
      match.should_not be_nil
      body = match.not_nil![1]
      body.should_not contain "</script>"
      body.should contain "<\\/script>"
    end

    it "respects a custom aria-live announce template" do
      out = UI::Web.render_route_host(
        {"a" => "<p>A</p>"}, "a",
        route_change_announce_label: "Opened {route}",
      )
      out.should contain "Opened {route}"
    end
  end
end
