# Phase 3 BX3 toggle-value probe. Mirrors the most recent Toggle on_change Bool
# into a store entry that an adjacent Label reads at render time.

require "./probe_store"

module UI::Probes
  # ToggleProbe — Phase 3 rubric BX3.
  #
  # Backs the `phase-03-toggle-value-probe` slug. The probe Toggle's
  # `on_change` updates `last_value`; the adjacent Label mirrors it.
  module ToggleProbe
    @@last_value : Bool = false

    def self.last_value : Bool
      @@last_value
    end

    def self.set(value : Bool) : Nil
      @@last_value = value
      ProbeStore.instance.set("toggle-probe-value", value.to_s)
    end

    def self.reset : Nil
      @@last_value = false
      ProbeStore.instance.set("toggle-probe-value", "false")
    end

    def self.current_text : String
      @@last_value.to_s
    end
  end
end
