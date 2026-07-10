# FakeLibObjCBridge — spec helper that records the ObjC / SwiftKit bridge
# calls a renderer makes so the spec can assert default-detection,
# overrides population, and call ordering without linking against
# Foundation, AppKit, UIKit, or AssetPipelineSwiftKit.
#
# Used by: spec/ui/renderers/swiftkit/*_spec.cr
# Gated under spec runs only (default Crystal build, no -Dmacos / -Dios).
#
# Why this exists:
#   `src/ui/renderers/uikit_renderer.cr` and `appkit_renderer.cr` reach
#   for `LibObjCBridge` / `LibSwiftKitBridge` symbols that only resolve
#   inside a native sample build (where Foundation and the AppKit /
#   UIKit frameworks are linked). The renderer visit methods themselves
#   are gated on `flag?(:ios)` / `flag?(:macos)`, so under plain
#   `crystal spec` they never compile. This helper module gives the
#   renderer-overrides specs a way to exercise the SAME populate-
#   the-Overrides logic that the renderer uses by inviting the spec
#   author to call the populator function directly with a fake
#   "overrides pointer" sentinel and a recording shim.
#
# Contract:
#   - `record(:setter_name, args)` appends a Call entry.
#   - `assert_sent(:setter_name, args: [...])` raises if the call is
#     missing.
#   - `refute_sent(:setter_name)` raises if the call IS present
#     (default-detection check).
#   - `next_sentinel_pointer` returns a fresh, unique `Void*` so each
#     overrides allocation is distinguishable.
#   - `reset` clears everything; run from a `Spec.before_each` hook.

module FakeLibObjCBridge
  # An individual call recording. `args` is captured as an Array(String)
  # so the spec can assert against stringified inputs without coupling
  # to Crystal's Object identity.
  record Call,
    name : Symbol,
    args : Array(String),
    returned : String

  @@calls = [] of Call
  @@stub_returns = {} of Symbol => String
  @@next_sentinel : UInt64 = 1_u64

  def self.reset : Nil
    @@calls.clear
    @@stub_returns.clear
    @@next_sentinel = 1_u64
  end

  def self.calls : Array(Call)
    @@calls.dup
  end

  def self.stub_return(selector : Symbol, value : String) : Nil
    @@stub_returns[selector] = value
  end

  def self.record(name : Symbol, args : Array(String), returned : String) : String
    @@calls << Call.new(name, args, returned)
    returned
  end

  # Return a fresh sentinel pointer (UInt64 encoded as a hex String).
  # Each call returns a different sentinel so allocation sites are
  # distinguishable across the spec body.
  def self.next_sentinel_pointer : String
    sentinel = @@next_sentinel
    @@next_sentinel += 1_u64
    "0x" + sentinel.to_s(16).rjust(16, '0')
  end

  # Spec assertion: a selector with the given args was sent N times.
  # `args` is optional; pass nil to assert "any args."
  def self.assert_sent(name : Symbol, times : Int32 = 1, args : Array(String)? = nil) : Nil
    matches = @@calls.select do |c|
      next false unless c.name == name
      args.nil? || c.args == args
    end
    if matches.size != times
      raise "expected #{name} sent #{times} times with args=#{args.inspect}, got #{matches.size} (calls: #{@@calls.inspect})"
    end
  end

  # Spec assertion: a selector was NOT sent. Used to verify
  # default-detection (e.g. setCornerRadius: is not invoked when
  # corner_radius is left at the type default).
  def self.refute_sent(name : Symbol) : Nil
    matches = @@calls.select { |c| c.name == name }
    raise "expected #{name} NOT to be sent, but got #{matches.size} calls" if matches.size > 0
  end
end
