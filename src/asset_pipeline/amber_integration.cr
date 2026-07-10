# Asset Pipeline — Amber framework integration.
#
# This module ships the production wiring for using the asset_pipeline
# cross-platform UI system (`UI::View` tree → `UI::Web::Renderer`) as
# the view layer of an Amber web app.
#
# The integration intentionally stays narrow: it does NOT wrap
# HTTP::Server::Context, it does NOT replace Amber's `render` macro,
# it does NOT introduce a new routing layer. It contributes:
#
#   * `UI::Screen`            — abstract base class. Subclass + implement
#                               `build(context : UI::ScreenContext) : UI::View`.
#   * `UI::ScreenContext`     — narrow per-request value object passed to
#                               `Screen#build`. Carries params, flash,
#                               design tokens, and the request CSRF token.
#   * `UI::ScreenContext::Web` — concrete implementation that wraps an
#                               Amber controller's request context.
#   * `UI::ScreenHelpers`     — controller mixin. Provides
#                               `compute_screen_html(ScreenClass)` which
#                               assigns `@screen_html` so a per-action
#                               shim ECR template can render
#                               `<%= @screen_html %>`.
#   * `UI::AmberConfig`       — global module for app-wide configuration
#                               (e.g. design tokens).
#   * `UI::RenderContext`     — renderer-scoped value (CSRF token + future
#                               request-bound state) threaded through
#                               `UI::Web::Renderer` so widgets like
#                               `UI::Form` can inject CSRF without the
#                               author wiring it on every form.
#
# # Why a shim ECR (and not a macro that writes templates)?
#
# Amber's `render(...)` is a macro that expands to
# `Kilt.render("path/template.ecr")` at compile time. Kilt's path lookup
# happens during Crystal compilation, BEFORE any macro-emitted file
# would land on disk. We cannot reliably emit shim templates from a
# macro and have Kilt find them in the same compilation unit.
#
# Therefore the integration uses **per-controller-action static shim
# templates** checked in by the author at
# `src/views/{controller_name}/{action_name}.ecr` whose only contents
# are `<%= @screen_html %>`. The integration ships `bin/asset_pipeline_amber`
# (a CLI generator) which creates these shim files mechanically so the
# author doesn't have to write them by hand.
#
# # Why no `session_data` Hash?
#
# Amber's session abstract store does not promise a `to_h` iteration
# API across all backends (CookieStore + RedisStore). Rather than
# leaking an inconsistent API surface, ScreenContext deliberately
# excludes session iteration. Controllers that want to thread specific
# session values to a screen should pass them via a per-screen
# constructor or a thin subclass; this keeps the contract narrow and
# avoids creating a backend-dependent API.
#
# # Why no `csrf_token` mutation on `UI::Form` post-build?
#
# Mutating a `UI::Form` instance's `csrf_token` property after the view
# tree is built is acceptable when the tree is fresh-per-request, but
# it leaks across shared trees. The supported CSRF threading path is
# either:
#
#   * explicit constructor arg:
#       `UI::Form.new(action: "/submit", csrf_token: context.csrf_token)`
#   * renderer-scoped `UI::RenderContext`:
#       `UI::Web::Renderer.new.render(view_tree, render_context: ctx)`
#
# The Form's web visit honors the explicit constructor arg first; if
# `nil`, it falls back to the threaded `UI::RenderContext`.
#
# This file requires only `asset_pipeline/ui` — it does NOT require
# `amber`. Apps using this integration require amber separately. The
# mixin methods use duck-typing on `params`/`flash`/`session`/
# `csrf_token` which any `Amber::Controller::Base` already provides.

require "../ui"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Per-request value object passed to `UI::Screen#build`. Concrete
  # `ScreenContext::Web` lives below.
  abstract class ScreenContext
    abstract def params : Hash(String, String)
    abstract def params_multi : Hash(String, Array(String))
    abstract def flash_data : Hash(String, String)
    abstract def design_tokens : UI::DesignTokens::Tokens
    abstract def csrf_token : String?

    # Web-target concrete ScreenContext. Wraps the scalar/multi params,
    # the flash messages, the design-token bundle, and the CSRF token
    # extracted from the request via Amber's CSRF helper.
    class Web < ScreenContext
      getter params : Hash(String, String)
      getter params_multi : Hash(String, Array(String))
      getter flash_data : Hash(String, String)
      getter design_tokens : UI::DesignTokens::Tokens
      getter csrf_token : String?

      def initialize(
        @params : Hash(String, String),
        @params_multi : Hash(String, Array(String)),
        @flash_data : Hash(String, String),
        @design_tokens : UI::DesignTokens::Tokens,
        @csrf_token : String?
      )
      end
    end
  end

  # App-wide configuration for the Amber integration. Apps set this
  # once at boot (typically in `config/initializers/asset_pipeline.cr`):
  #
  #     UI::AmberConfig.design_tokens = UI::DesignTokens::Tokens
  #       .default.with_brand(AcmeBrand.new)
  #
  # The configured tokens are passed into every `UI::ScreenContext`
  # built by `UI::ScreenHelpers#compute_screen_html`.
  module AmberConfig
    @@design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

    def self.design_tokens : UI::DesignTokens::Tokens
      @@design_tokens
    end

    def self.design_tokens=(tokens : UI::DesignTokens::Tokens) : UI::DesignTokens::Tokens
      @@design_tokens = tokens
    end
  end

  # Abstract base class for screens. Authors subclass `UI::Screen` and
  # implement `build(context)` to return a `UI::View` tree.
  #
  # Screens are stateless — the per-request data lives on
  # `ScreenContext`. A screen instance is constructed fresh per render.
  #
  #     class SignInScreen < UI::Screen
  #       def build(context : UI::ScreenContext) : UI::View
  #         form = UI::Form.new(
  #           action: "/sign_in/submit",
  #           csrf_token: context.csrf_token,
  #         )
  #         form << UI::TextField.new(placeholder: "Email", name: "email",
  #                                   text: context.params["email"]? || "")
  #         form << UI::SecureField.new(placeholder: "Password", name: "password")
  #         form << UI::Button.new("Sign in", type: UI::Button::Type::Submit)
  #         form
  #       end
  #     end
  abstract class Screen
    abstract def build(context : ScreenContext) : UI::View
  end

  # Phase 8C — Amber-router contribution from `UI::App`.
  #
  # `UI::AmberIntegration.routes_for(SpikeApp)` expands inside an
  # Amber `routes :web do ... end` block to a sequence of `get` / `post` /
  # `put` / `patch` / `delete` calls — one per `web_actions` entry on
  # every screen registered by `SpikeApp` that declared web metadata.
  #
  # # How it works
  #
  # Each `screen :id, ..., web_controller: X, web_path: "/x", web_actions: [...]`
  # macro call emits TWO things on `UI::App` subclass:
  #
  #   1. A marker class method `def self._web_route_emit_<id> : Nil; nil; end`
  #      — its only purpose is to be enumerable via `@type.class.methods`
  #      at compile time.
  #   2. A same-named class macro `macro _web_route_emit_<id>` whose body
  #      is the unrolled `get`/`post` calls for the registration's
  #      `web_actions` array.
  #
  # `routes_for(SpikeApp)` iterates the subclass's class methods at
  # compile time, finds every `_web_route_emit_*` marker, and emits
  # `SpikeApp._web_route_emit_<id>` for each one. Crystal's macro
  # engine resolves those calls to the same-named macros (not the
  # marker methods), and the macro bodies expand inline inside the
  # `routes :web do ... end` block — where Amber's `router.draw ...
  # do |with router yield|` makes `get` / `post` / etc resolve to the
  # router DSL's `Amber::DSL::Router` macros.
  #
  # The mechanism is empirically verified in
  # `docs/initiative-cross-platform-ui/phases/phase-08-ergonomic-mvc-api/codex-critique-1-brief-8c.md`
  # (Codex session 019e5c01-6ddf-75e3-8940-e2f61bfd2cb5, "The proven
  # mechanism" section).
  #
  # # When no screen has web metadata
  #
  # `routes_for(MyApp)` expands to nothing — no error, no warning. This
  # supports native-first apps that gradually opt into web routes. The
  # caller's `routes :web do ... end` block can still hold manual
  # `get`/`post` lines alongside the `routes_for` call.
  #
  # # Example
  #
  #     class SpikeApp < UI::App
  #       screen :sign_in,
  #              web_controller: SignInController,
  #              web_path: "/",
  #              web_actions: [
  #                {verb: :get,  action: :index},
  #                {verb: :post, action: :submit, path: "/sign_in/submit"},
  #              ]
  #     end
  #
  #     # config/routes.cr
  #     Amber::Server.configure do
  #       routes :web do
  #         UI::AmberIntegration.routes_for(SpikeApp)
  #         # Plus any other manual Amber routes the app needs.
  #       end
  #     end
  module AmberIntegration
    macro routes_for(app_class)
      {% for method in app_class.resolve.class.methods %}
        {% if method.name.starts_with?("_web_route_emit_") %}
          {{app_class}}.{{method.name.id}}
        {% end %}
      {% end %}
    end
  end

  # Controller mixin. Include in `ApplicationController` so every
  # controller in the app can call `compute_screen_html(ScreenClass)`
  # before `render("action.ecr")`.
  #
  #     class ApplicationController < Amber::Controller::Base
  #       include UI::ScreenHelpers
  #       LAYOUT = "application.ecr"
  #     end
  #
  #     class SignInController < ApplicationController
  #       def index
  #         compute_screen_html(SignInScreen)
  #         render("index.ecr")
  #       end
  #     end
  #
  # The shim template at `src/views/sign_in/index.ecr` is one line:
  #
  #     <%= @screen_html %>
  #
  # Use `bin/asset_pipeline_amber generate <controller> <action>` to
  # create the shim file mechanically.
  module ScreenHelpers
    # Build a `UI::ScreenContext::Web` from the current controller's
    # request, instantiate `screen_class`, build the view tree, render
    # to HTML via `UI::Web::Renderer`, and assign to `@screen_html`.
    # Returns the rendered HTML string as a convenience.
    #
    # The renderer's `design_tokens` are seeded from
    # `UI::AmberConfig.design_tokens` so apps that configured a brand
    # override at boot pick it up automatically.
    def compute_screen_html(screen_class : UI::Screen.class) : String
      ctx = build_screen_context
      screen = screen_class.new
      view_tree = screen.build(ctx)
      renderer = UI::Web::Renderer.new
      renderer.design_tokens = ctx.design_tokens
      render_context = UI::RenderContext.new(csrf_token: ctx.csrf_token)
      html = renderer.render(view_tree, render_context: render_context)
      @screen_html = html
      html
    end

    # Build a `UI::ScreenContext::Web` from the current Amber
    # controller's request. Override in a subclass if a non-default
    # context shape is required.
    private def build_screen_context : UI::ScreenContext::Web
      UI::ScreenContext::Web.new(
        params: params_scalar_hash,
        params_multi: params_multi_hash,
        flash_data: flash_hash,
        design_tokens: UI::AmberConfig.design_tokens,
        csrf_token: amber_csrf_token,
      )
    end

    # Flattened scalar form of params. Multi-value params (checkbox
    # groups, multi-select) collapse to their first value. Screens
    # needing the full array should read `context.params_multi[key]`.
    private def params_scalar_hash : Hash(String, String)
      h = {} of String => String
      params.to_h.each do |key, value|
        case value
        when String
          h[key.to_s] = value
        when Array(String)
          first = value.first?
          h[key.to_s] = first if first
        else
          h[key.to_s] = value.to_s
        end
      end
      h
    end

    # Full multi-value form of params. Preserves the array-shape that
    # Amber's `params.to_h` exposes.
    private def params_multi_hash : Hash(String, Array(String))
      h = {} of String => Array(String)
      params.to_h.each do |key, value|
        case value
        when Array(String)
          h[key.to_s] = value
        when String
          h[key.to_s] = [value]
        else
          h[key.to_s] = [value.to_s]
        end
      end
      h
    end

    private def flash_hash : Hash(String, String)
      h = {} of String => String
      if f = flash
        f.each { |level, message| h[level.to_s] = message.to_s }
      end
      h
    end

    # Read the CSRF token via Amber's controller helper (which the
    # `Amber::Controller::Base` includes through
    # `Amber::Controller::Helpers::CSRF`). Falls back to nil if the
    # helper is not available (controller without CSRF pipe). This is
    # the SUPPORTED CSRF threading path — do NOT read the raw session
    # key directly, Amber's CSRF pipe uses a masked-token strategy and
    # the raw session value is not what the form should submit.
    private def amber_csrf_token : String?
      if responds_to?(:csrf_token)
        token = csrf_token
        token.is_a?(String) ? token : nil
      end
    rescue
      nil
    end
  end
end
