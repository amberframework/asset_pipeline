# Phase 8D.2 — flag-agnostic host bootstrap helper.
#
# Encapsulates the canonical dispatcher construction sequence so the
# iOS bridge AND any future host can call ONE primitive instead of
# duplicating the order. The macOS host predates this helper and may
# be migrated to it in a follow-up cleanup; it is NOT in 8D.2 scope.
#
# Returns a `Bootstrap::Result` struct carrying all the constructed
# collaborators. Caller is responsible for pinning them per its own
# GC discipline (iOS class-vars; macOS local vars).
#
# Per Codex HIGH 4 + R11 elevation in brief-8d.2.md: extracting this
# sequence makes the runtime invariants ("bootstrap before construct",
# "mount_screen before any render", "assign Voyager.state and
# Voyager.dispatcher exactly once") testable under default `crystal
# spec` — no `-Dios` required because the helper does not depend on
# the UIKit renderer.

require "./app"

module Voyager
  module HostBootstrap
    record Result,
      state : Voyager::State,
      coord : UI::NavigationCoordinator,
      session : UI::Session::InProcess,
      flash : UI::Flash::InProcess,
      dispatcher : UI::ActionDispatcher

    # Build the full host substrate. Calls `VoyagerApp.bootstrap!`,
    # constructs state + coord + session + flash + dispatcher, calls
    # `dispatcher.mount_screen` for the initial route, assigns
    # `Voyager.state` and `Voyager.dispatcher`. Returns the constructed
    # collaborators for host-level pinning.
    def self.build(initial_route_id : Symbol = :sign_in) : Result
      VoyagerApp.bootstrap!

      state = Voyager::State.new
      Voyager.state = state

      coord = UI::NavigationCoordinator.new(
        UI::NavigationCoordinator::Route.new(initial_route_id)
      )
      session = UI::Session::InProcess.new
      flash = UI::Flash::InProcess.new
      dispatcher = UI::ActionDispatcher.new(
        app: VoyagerApp,
        navigation: coord,
        session: session,
        flash: flash,
        design_tokens: UI::DesignTokens::Tokens.default,
      )
      dispatcher.mount_screen(coord.current)
      Voyager.dispatcher = dispatcher

      Result.new(
        state: state,
        coord: coord,
        session: session,
        flash: flash,
        dispatcher: dispatcher,
      )
    end
  end
end
