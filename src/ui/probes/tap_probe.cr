# Phase 3 BX1/BX2 button-tap probe. Increments a counter on each on_tap and
# exposes it via a mirror Label so XCUITest / AXTest can assert the transitions.

require "./probe_store"

module UI::Probes
  # TapProbe — Phase 3 rubric BX1 / BX2.
  #
  # Backs the `phase-03-action-tap-probe` slug. The probe Button's
  # `on_tap` increments `counter`; the adjacent probe Label reads the
  # current count at render time. AXTest / XCUITest harnesses assert
  # the counter transitions across taps.
  module TapProbe
    @@counter : Int32 = 0

    def self.counter : Int32
      @@counter
    end

    def self.increment : Int32
      @@counter += 1
      ProbeStore.instance.set("tap-probe-counter", @@counter.to_s)
      @@counter
    end

    def self.reset : Nil
      @@counter = 0
      ProbeStore.instance.set("tap-probe-counter", "0")
    end

    def self.current_text : String
      @@counter.to_s
    end
  end
end
