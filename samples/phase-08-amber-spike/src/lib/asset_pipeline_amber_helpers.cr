# Phase 8 spike: prototype `asset_pipeline` Amber integration helpers.
#
# These live inside the spike directory until the design is validated.
# If the spike passes Codex review, Phase 8A's brief lifts them into
# `src/asset_pipeline/amber_integration.cr` for real.
#
# Goal: prove that an Amber controller can render a `UI::Screen` view
# tree via a single `render_screen` helper without wrapping
# HTTP::Server::Context.

require "asset_pipeline/ui"

module UI
  # Narrow ScreenContext for the web target. Carries only what the
  # screen author needs to read — params, session, flash,
  # design_tokens. No request/response/cookies/csrf accessor at this
  # layer — those belong on the Amber controller, not in the screen.
  class ScreenContext
    getter params : Hash(String, String)
    getter session_data : Hash(String, String)
    getter flash_data : Hash(String, String)
    getter design_tokens : UI::DesignTokens::Tokens
    getter csrf_token : String?

    def initialize(@params, @session_data, @flash_data, @design_tokens, @csrf_token = nil)
    end
  end

  module ScreenHelpers
    # Compute a UI::Screen's HTML and stash it in @screen_html so the
    # caller can `render("index.ecr")` (or any shim template that
    # echoes <%= @screen_html %>) — Amber's render() macro requires a
    # template path and does NOT have an html: overload.
    #
    # Spike finding #3: render(html:) does not exist. The integration
    # has to either (a) ship a shim ECR template per controller, or
    # (b) generate the shim template at compile time, or (c) bypass
    # render() entirely and write to response directly (losing layout
    # wrapping).
    #
    # The spike uses path (a) with one shim template per controller.
    # Phase 8A's brief should pick the long-term answer.
    #
    # Usage:
    #   class SignInController < ApplicationController
    #     include UI::ScreenHelpers
    #     def index
    #       compute_screen_html SignInScreen
    #       render("index.ecr")
    #     end
    #   end
    def compute_screen_html(screen_class : UI::Screen.class) : String
      ctx = build_screen_context
      screen = screen_class.new
      view_tree = screen.build(ctx)
      html = UI::Web::Renderer.new.render(view_tree)
      @screen_html = html
      html
    end

    # Build a UI::ScreenContext from the current Amber controller's
    # context. Pulls params (flattened to Hash(String, String)),
    # session (current keys), flash (current messages), and the
    # current CSRF token if available.
    private def build_screen_context : UI::ScreenContext
      UI::ScreenContext.new(
        params: params_hash,
        session_data: session_hash,
        flash_data: flash_hash,
        design_tokens: ::UI::AmberConfig.design_tokens,
        csrf_token: csrf_token_value,
      )
    end

    private def params_hash : Hash(String, String)
      h = {} of String => String
      # Amber's params is iterable; values may be String | Array(String).
      params.to_h.each do |key, value|
        case value
        when String
          h[key.to_s] = value
        when Array(String)
          h[key.to_s] = value.first
        else
          h[key.to_s] = value.to_s
        end
      end
      h
    end

    private def session_hash : Hash(String, String)
      h = {} of String => String
      # Amber's session is roughly Hash-like; iterate keys when possible.
      # If iteration isn't supported, return an empty hash + log.
      if session.responds_to?(:to_h)
        session.to_h.each { |k, v| h[k.to_s] = v.to_s }
      end
      h
    end

    private def flash_hash : Hash(String, String)
      h = {} of String => String
      flash.each { |level, message| h[level.to_s] = message.to_s } if flash
      h
    end

    private def csrf_token_value : String?
      # Amber's CSRF pipe exposes a class method or session key. Try
      # the session key first (this is where the spike will surface
      # the real answer).
      session["csrf.token"]?
    rescue
      nil
    end
  end

  # App-wide configuration for the Amber view layer. Apps set this
  # once at boot in config/initializers.
  module AmberConfig
    @@design_tokens : UI::DesignTokens::Tokens = UI::DesignTokens::Tokens.default

    def self.design_tokens : UI::DesignTokens::Tokens
      @@design_tokens
    end

    def self.design_tokens=(tokens : UI::DesignTokens::Tokens) : Nil
      @@design_tokens = tokens
    end
  end

  # Base Screen class. Author subclasses + implements build(context).
  abstract class Screen
    abstract def build(context : ScreenContext) : UI::View
  end
end
