# Thread-unsafe key/value store keyed by string identifiers, backing all
# Phase 3 behavior probes. Probe singletons write into it; mirror labels read.

module UI::Probes
  # ProbeStore — a thread-unsafe key/value store keyed by string identifiers.
  #
  # Each probe singleton (TapProbe, ToggleProbe, SliderProbe, etc.) backs
  # its mirror-label state by writing string values into this store. The
  # rendered probe scene reads the values at build_component time so the
  # initial label text reflects the singleton's current state.
  #
  # For end-to-end behavior probes (rubric BX1-BX5), the runtime mutation
  # path is constrained by the SwiftKit hosting model: SwiftUI views are
  # immutable values and do not re-render in response to Crystal mutation
  # without an ObservableObject bridge. The probe singletons therefore
  # focus on (a) holding the state Crystal-side so the next render of the
  # scene reflects the new value, and (b) exposing a counter / last_value
  # accessor that test code can read directly when the AXTest harness is
  # driving the host as an in-process spec.
  #
  # See handoff/phase-03-remediation-3-blockers-2026-05-21.md for the
  # SwiftKit reactive-label gap that limits the probe-mirror tracking path.
  class ProbeStore
    @@instance : ProbeStore?

    def self.instance : ProbeStore
      @@instance ||= ProbeStore.new
    end

    def initialize
      @values = {} of String => String
    end

    def set(key : String, value : String) : Nil
      @values[key] = value
    end

    def get(key : String) : String?
      @values[key]?
    end

    def get_or(key : String, default : String) : String
      @values[key]? || default
    end

    def reset : Nil
      @values.clear
    end

    def reset(key : String) : Nil
      @values.delete(key)
    end
  end
end
