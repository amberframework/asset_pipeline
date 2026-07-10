# Phase 6 — Cascade demo app.
#
# A single Crystal source that compiles to web (HTML), macOS (AppKit
# .app), and iOS (UIKit simulator .app). The build targets live under
# samples/initiative-cross-platform-ui-demo/{web,macos,ios}; each picks
# this file up via `require` and feeds the selected screen into its
# platform renderer.
#
# Slug source (in priority order):
#   1. ENV["DEMO_SLUG"]
#   2. ARGV[0]
#   3. default "demo-sign-in"
#
# Five screens are addressable by stable slugs (Phase 6 brief decision #7):
#   demo-sign-in     -> InitiativeDemo::SignInScreen
#   demo-dashboard   -> InitiativeDemo::DashboardScreen
#   demo-detail      -> InitiativeDemo::DetailScreen
#   demo-settings    -> InitiativeDemo::SettingsScreen
#   demo-tier-three  -> InitiativeDemo::TierThreeScreen
#
# Plus a meta-slug `demo-all` that the quad-comparison harness uses to
# iterate the screens in sequence (each surface captures all 5 in turn).

require "../../src/ui"
require "./brand"
require "./screens/state"
require "./screens/sign_in"
require "./screens/dashboard"
require "./screens/detail"
require "./screens/settings"
require "./screens/tier_three"

module InitiativeDemo
  SLUGS = [
    "demo-sign-in",
    "demo-dashboard",
    "demo-detail",
    "demo-settings",
    "demo-tier-three",
  ]

  # Build the requested screen as a UI::View.  Used by the per-platform
  # entry points (web/static_site_generator.cr, macos/host.cr, the iOS
  # bridge) to render any screen by slug.
  def self.build_screen(slug : String, state : InitiativeDemo::State? = nil) : UI::View
    state ||= InitiativeDemo::State.new
    case slug
    when "demo-sign-in"
      SignInScreen.build(state)
    when "demo-dashboard"
      DashboardScreen.build(state)
    when "demo-detail"
      DetailScreen.build(state)
    when "demo-settings"
      SettingsScreen.build(state)
    when "demo-tier-three"
      TierThreeScreen.build(state)
    else
      placeholder = UI::Label.new("Unknown slug: #{slug}")
      placeholder.accessibility_label = "Unknown slug"
      placeholder.as(UI::View)
    end
  end

  # Returns the screen wrapped in a NavigationStack with a title — the
  # canonical surface for native renderers (web ignores the
  # NavigationStack chrome and just renders the root).
  def self.build_navigated(slug : String, state : InitiativeDemo::State? = nil) : UI::View
    inner = build_screen(slug, state)
    title = case slug
            when "demo-sign-in"    then "Welcome"
            when "demo-dashboard"  then "Cascade"
            when "demo-detail"     then "Detail"
            when "demo-settings"   then "Settings"
            when "demo-tier-three" then "Platform widgets"
            else                        "Demo"
            end
    stack = UI::NavigationStack.new(inner, title)
    stack.large_title = (slug == "demo-dashboard")
    stack.accessibility_label = "Navigation: #{title}"
    stack.test_id = "demo-navigation-stack"
    stack.as(UI::View)
  end
end
