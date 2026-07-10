# Phase 3 BX4 slider-value probe. Writes the latest Slider on_change Float64 into
# a store entry that an adjacent mirror Label reads at render time.

require "./probe_store"

module UI::Probes
  # SliderProbe — Phase 3 rubric BX4.
  #
  # Backs the `phase-03-slider-value-probe` slug. The Slider's
  # `on_change` writes the latest Float64 into `last_value`; the
  # adjacent Label reads `formatted` so the rendered text matches what
  # XCUITest reads via `staticTexts[...]`.
  module SliderProbe
    # Use Float64? so callers can distinguish "no value yet" from "0.0".
    # Crystal Float64 default-initialisation is technically 0.0 but the
    # cross-platform load order has produced cases where the singleton's
    # class storage is read before any setter has run; on iOS this took
    # the Float printer (`Float::Printer::RyuPrintf`) down with a
    # KERN_INVALID_ADDRESS while formatting an uninitialised slot.
    # Treating the value as optional and supplying a safe formatter
    # closes the window without touching the BX4 hot path semantics.
    @@last_value : Float64? = 0.0

    def self.last_value : Float64
      @@last_value || 0.0
    end

    def self.set(value : Float64) : Nil
      @@last_value = value
      ProbeStore.instance.set("slider-probe-value", formatted)
    end

    def self.reset : Nil
      @@last_value = 0.0
      ProbeStore.instance.set("slider-probe-value", "0.00")
    end

    def self.formatted : String
      v = @@last_value
      return "0.00" if v.nil?
      # Defensive: NaN / Infinity cannot be formatted reliably on every
      # platform. Treat them as the safe default.
      return "0.00" unless v.finite?
      # Avoid `sprintf("%.2f", v)` — Crystal's `RyuPrintf::d2fixed_buffered_n`
      # crashed inside the formatter on iOS arm64 simulator builds even
      # when handed a finite Float64 (iter 6 BX4 crash trace shows
      # KERN_INVALID_ADDRESS at +152 in `Array(UInt8)#[]`). Build the
      # string from the integer/fraction split instead — pure integer
      # arithmetic that does not call into the Float printer at all.
      format_two_decimals(v)
    end

    # Renders a Float64 as a fixed-2-decimal string without going through
    # `sprintf` / `Float::Printer::RyuPrintf`. Sign-aware, rounds half-up.
    private def self.format_two_decimals(v : Float64) : String
      negative = v < 0.0
      abs_v = negative ? -v : v
      # Multiply, round, then split back into integer + 2-digit fraction.
      scaled = (abs_v * 100.0 + 0.5).to_i64
      whole = scaled // 100_i64
      frac = scaled % 100_i64
      sign = negative ? "-" : ""
      frac_str = frac < 10_i64 ? "0#{frac}" : frac.to_s
      "#{sign}#{whole}.#{frac_str}"
    end

    def self.current_text : String
      formatted
    end
  end
end
