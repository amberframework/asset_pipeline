# Responsive sizing value (`Fluid(min, ideal, max)`) that translates to CSS
# `clamp(...)` on web and to platform-idiomatic size-class behavior on native.

module UI
  # Responsive sizing value. Translates to `clamp(min, ideal, max)` on web,
  # and to the platform's idiomatic size class behavior on Apple/Android
  # (handled by later phases).
  #
  # `min`, `ideal`, and `max` are CSS-compatible size strings (e.g., `"20rem"`,
  # `"60vw"`, `"480px"`). Use the `Fluid.px` / `Fluid.vw` constructors when you
  # have numeric pixel values rather than building strings by hand.
  record Fluid,
    min : String,
    ideal : String,
    max : String do
    # Construct from numeric pixel values. Pixels are emitted as `Npx`.
    def self.px(min : Number, ideal : Number, max : Number) : Fluid
      new(min: "#{min}px", ideal: "#{ideal}px", max: "#{max}px")
    end

    # Construct from a fluid `vw` ideal with px floor/ceiling.
    def self.vw(min_px : Number, ideal_vw : Number, max_px : Number) : Fluid
      new(min: "#{min_px}px", ideal: "#{ideal_vw}vw", max: "#{max_px}px")
    end

    # Render as a CSS `clamp()` expression.
    def to_css : String
      "clamp(#{min}, #{ideal}, #{max})"
    end
  end
end
