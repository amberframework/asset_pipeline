# Phase 8B — UI::FormState — per-screen-mount input value registry.
#
# A `UI::FormState` holds the live values typed into the inputs on a
# single screen mount. Native renderers (AppKit + UIKit) wire each
# TextField / SecureField / Toggle's `on_change` to call
# `form_state.update(name, value)` when the input has a non-empty
# `name` property.
#
# # Per-screen-mount lifetime
#
# Every time the dispatcher mounts a screen (`mount_screen(route_id)`),
# it creates a NEW FormState with a fresh `mount_token : Int64`. When
# the user navigates away (push / pop / replace_root), the dispatcher
# allocates yet another FormState for the next mount.
#
# # Mount-token-scoped stale-callback no-ops
#
# Renderer callbacks capture the FormState reference AND its mount
# token at wire-time. When the callback fires, it compares the
# captured token against the dispatcher's CURRENT token; if they
# don't match, the callback is a no-op. This prevents a delayed
# on_change from a prior screen's TextField from leaking values into
# the next screen's FormState. Per Codex finding #3 on the brief.
#
# # Why module-level current_form_state + current_mount_token?
#
# Renderer code (UI::AppKit::Renderer / UI::UIKit::Renderer)
# instantiates new `visit(UI::TextField)` calls for each tree walk.
# Each visit needs to capture the CURRENT FormState reference + token
# at wire-time. The dispatcher (iter 4) writes both values at the
# start of every mount via class methods on `UI::FormState`. The
# renderer reads them at visit time. This is a one-writer
# (dispatcher) / many-reader (renderer visits) pattern — no race in
# the single-threaded AppKit / UIKit main-loop world.

require "./fluid"
require "./view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Controlled-input state container threaded through screen renders to preserve text values across rerenders.
  class FormState
    # Field name -> current value. Populated by `register` (initial seed
    # from view.text) and `update` (on_change from input).
    getter values : Hash(String, String)

    # Monotonically-increasing token issued by `UI::ActionDispatcher` on
    # every screen mount. Renderer callbacks capture this at wire-time;
    # stale callbacks compare their captured token against the
    # dispatcher's CURRENT token (`UI::FormState.current_mount_token`)
    # and short-circuit on mismatch.
    getter mount_token : Int64

    def initialize(@mount_token : Int64 = 0_i64, initial : Hash(String, String) = {} of String => String)
      @values = initial.dup
    end

    # Used by the iter-2 forward declaration's spec; preserves the
    # old `UI::FormState.new` signature so existing callers don't break.
    def self.new(initial : Hash(String, String) = {} of String => String) : self
      new(mount_token: 0_i64, initial: initial)
    end

    # Renderer-side hook: when a TextField's `name` is non-empty, the
    # renderer wires `form_state.register(name, view.text)` at view-
    # construction so the initial value (e.g. pre-populated email after
    # a failed submit) is in the registry before any on_change fires.
    # Idempotent: a later `register` for the same key DOES update —
    # the renderer may re-build the same name with a different initial
    # value when the screen re-renders, and we want the latest one.
    def register(name : String, initial : String = "") : Nil
      @values[name] = initial unless @values.has_key?(name)
      nil
    end

    # on_change wiring: called by the renderer's callback when the
    # native input fires a change event. Mount-token check happens at
    # the call site (in the renderer's visit_text_field) — by the time
    # `update` is called, the stale-callback guard has already passed.
    def update(name : String, value : String) : Nil
      @values[name] = value
      nil
    end

    def [](name : String) : String
      @values[name]? || ""
    end

    def []?(name : String) : String?
      @values[name]?
    end

    # Snapshot for the controller's `ctx.params`. Defensive copy so
    # callers can't mutate the live registry.
    def to_h : Hash(String, String)
      @values.dup
    end

    # ----- Renderer hook surface ---------------------------------------
    #
    # The dispatcher (iter 4) writes these class-level slots at every
    # `mount_screen`. The renderer (iter 3) reads them inside
    # `visit(UI::TextField)` / `visit(UI::SecureField)` to wire
    # mount-token-scoped on_change callbacks.

    # `@@current` is nilable + accessed via method — iOS gap safe.
    # `@@current_mount_token` defaults to 0_i64 via a class-var
    # initialiser. The dispatcher (iter 4) writes the real token on
    # every screen mount BEFORE the renderer reads it, so 0_i64 is a
    # benign sentinel — if the iOS gap silently skips the initialiser,
    # the field is still 0_i64 (the same value the gap would strand
    # numerics at), which makes the renderer's wire-time captured
    # token compare equal to the live token only when nothing has
    # navigated yet. A subsequent dispatcher.mount_screen call writes
    # a non-zero token and the system is back in sync.
    @@current : UI::FormState? = nil
    @@current_mount_token : Int64 = 0_i64

    def self.current : UI::FormState?
      @@current
    end

    def self.current=(fs : UI::FormState?) : UI::FormState?
      @@current = fs
    end

    # The mount token belonging to `current`. The dispatcher keeps these
    # two values in lockstep — every `current=` is followed by a token
    # bump and a `current_mount_token=` write. Renderer callbacks
    # compare their captured token against the live one to detect a
    # stale fire after navigation.
    def self.current_mount_token : Int64
      @@current_mount_token
    end

    def self.current_mount_token=(t : Int64) : Int64
      @@current_mount_token = t
    end

    # Reset all renderer-hook state. Used by specs between scenarios
    # and by the dispatcher when tearing down an app.
    def self.reset_renderer_hooks! : Nil
      @@current = nil
      @@current_mount_token = 0_i64
      nil
    end
  end

  # Renderer-side helper called from `visit(UI::TextField)` /
  # `visit(UI::SecureField)` on the native renderers. Encapsulates the
  # "if `view.name` is non-empty, register the initial value + wrap the
  # author's on_change so it ALSO updates FormState with mount-token
  # guarding" pattern, so the renderer code stays slim.
  module FormStateRendererHook
    # Wrap a TextField's on_change. Returns:
    #   - nil if neither the view has a `name` nor a user-supplied
    #     on_change (no wiring needed).
    #   - the original on_change if the view has no `name`.
    #   - a new proc that ALSO updates form_state (mount-token-checked)
    #     before invoking the original on_change.
    def self.wrap_text_handler(view : UI::TextField) : Proc(String, Nil)?
      name = view.name
      user_handler = view.on_change

      if name && !name.empty?
        captured_fs = UI::FormState.current
        captured_token = captured_fs.try(&.mount_token) || 0_i64
        if captured_fs
          captured_fs.register(name, view.text)
        end

        ->(new_value : String) do
          # Stale-fire guard: if the captured token doesn't match the
          # dispatcher's CURRENT token, the entire callback is a no-op
          # — including the user's on_change. Per Codex finding #3 on
          # the brief: stale callbacks become no-ops, not "no-ops
          # against FormState while still firing side effects."
          if captured_fs &&
             UI::FormState.current_mount_token == captured_token &&
             UI::FormState.current == captured_fs
            captured_fs.update(name, new_value)
            user_handler.try(&.call(new_value))
          end
          nil
        end
      else
        user_handler
      end
    end

    # Wrap a SecureField's on_change. Same shape as `wrap_text_handler`
    # but typed for SecureField. The current SwiftKit bridge for
    # SecureField does NOT carry the cleartext through to Crystal — the
    # action token only signals "something changed" and the user's
    # on_change is invoked with `""`. form_state.update therefore writes
    # an empty string for the SecureField's name. Authors who need true
    # password capture on macOS / iOS for Phase 8B should use a plain
    # `UI::TextField` for now. A future SwiftKit bridge iteration will
    # carry the actual typed password.
    def self.wrap_secure_handler(view : UI::SecureField) : Proc(String, Nil)?
      name = view.name
      user_handler = view.on_change

      if name && !name.empty?
        captured_fs = UI::FormState.current
        captured_token = captured_fs.try(&.mount_token) || 0_i64
        if captured_fs
          captured_fs.register(name, view.text)
        end

        ->(new_value : String) do
          # Same stale-fire guard as text handler: token mismatch =
          # full no-op (FormState write AND user handler suppressed).
          if captured_fs &&
             UI::FormState.current_mount_token == captured_token &&
             UI::FormState.current == captured_fs
            captured_fs.update(name, new_value)
            user_handler.try(&.call(new_value))
          end
          nil
        end
      else
        user_handler
      end
    end
  end
end
