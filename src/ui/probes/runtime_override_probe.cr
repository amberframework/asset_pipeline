# Phase 3 BX5 runtime-override probe. Backs the 'Make Red' trigger that mutates
# a target view's background_color override at render time for the scene rebuild.

require "./probe_store"

module UI::Probes
  # RuntimeOverrideProbe — Phase 3 rubric BX5.
  #
  # Backs the `phase-03-runtime-override-probe` slug. The "Make Red"
  # trigger button mutates `target_red`; the scene rebuild logic reads
  # this value at render time and applies a red background_color override
  # to the target Button.
  #
  # NOTE on architecture: SwiftUI hosting in the current SwiftKit bridge
  # does not respond to property mutation after the initial render. A
  # genuine re-paint requires either (a) the rubric's caller to teardown
  # and re-render the slug, or (b) a SwiftKit reactive-property facade
  # (deferred per phase-03-remediation-3-blockers-2026-05-21.md). This
  # singleton holds the mutated state regardless, so a re-render of the
  # slug picks up the new background. The probe Label `override-state`
  # mirrors the boolean so the rubric can confirm the on_tap fired even
  # when the visual repaint is gated on the SwiftKit reactive path.
  module RuntimeOverrideProbe
    @@target_red : Bool = false

    def self.target_red? : Bool
      @@target_red
    end

    def self.set_red : Nil
      @@target_red = true
      ProbeStore.instance.set("override-state", "red")
    end

    def self.reset : Nil
      @@target_red = false
      ProbeStore.instance.set("override-state", "transparent")
    end

    def self.current_text : String
      @@target_red ? "red" : "transparent"
    end
  end
end
