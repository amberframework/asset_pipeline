module Components
  module Variants
    VALID_TONES    = %w[brand neutral success warning danger info]
    VALID_EMPHASIS = %w[solid soft outline ghost]
    VALID_SIZES    = %w[sm md lg]
    VALID_STATES   = %w[default hover active selected disabled loading invalid empty]

    # Small value object that keeps component class construction predictable.
    # It is intentionally string-backed so alpha examples can accept params
    # from attrs without exposing raw class soup as the public API.
    record ComponentVariant,
      family : String,
      tone : String = "brand",
      emphasis : String = "solid",
      size : String = "md",
      state : String = "default" do
      def initialize(@family : String, @tone : String = "brand", @emphasis : String = "solid", @size : String = "md", @state : String = "default")
        validate("tone", @tone, VALID_TONES)
        validate("emphasis", @emphasis, VALID_EMPHASIS)
        validate("size", @size, VALID_SIZES)
        validate("state", @state, VALID_STATES)
      end

      def classes : String
        [
          family,
          "#{family}--#{tone}",
          "#{family}--#{emphasis}",
          "#{family}--#{size}",
          state == "default" ? nil : "#{family}--#{state}",
        ].compact.join(" ")
      end

      private def validate(name : String, value : String, allowed : Array(String))
        return if allowed.includes?(value)

        raise ArgumentError.new("Invalid #{name} '#{value}'. Expected one of: #{allowed.join(", ")}")
      end
    end
  end
end
