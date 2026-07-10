# Phase 3 BX6/BX7 form-row probe. Counts taps on a nested form-row button and
# exposes the count via a mirror label that test harnesses can read.

require "./probe_store"

module UI::Probes
  # FormRowProbe — Phase 3 rubric BX6 / BX7.
  #
  # Backs the `phase-03-form-nested-buttons` slug. Form row 2's
  # `on_tap` increments `row2_count`. A mirror Label with identifier
  # `form-row-2-counter` reflects the current count.
  module FormRowProbe
    @@row2_count : Int32 = 0

    def self.row2_count : Int32
      @@row2_count
    end

    def self.increment_row2 : Int32
      @@row2_count += 1
      ProbeStore.instance.set("form-row-2-counter", @@row2_count.to_s)
      @@row2_count
    end

    def self.reset : Nil
      @@row2_count = 0
      ProbeStore.instance.set("form-row-2-counter", "0")
    end

    def self.current_text : String
      @@row2_count.to_s
    end
  end
end
