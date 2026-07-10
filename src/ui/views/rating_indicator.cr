# Horizontal star-row rating control. AppKit maps to NSLevelIndicator's rating
# style; UIKit synthesises a UIStackView of SF Symbol "star.fill" / "star"
# UIImageViews tinted with the resolved color.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A horizontal row of star symbols communicating a ranking level.
  #
  # On macOS the renderer uses NSLevelIndicator with
  # NSLevelIndicatorStyleRating (style constant 4), which produces the
  # native star-row control identical to the one shown in the HIG
  # illustration.  On iOS there is no NSLevelIndicator equivalent; the
  # UIKit renderer synthesises a UIStackView of UIImageView instances
  # carrying SF Symbol names "star.fill" (for filled positions) and "star"
  # (for empty positions), tinted with the resolved tint color.
  #
  # HIG: "A rating indicator uses a series of horizontally arranged
  # graphical symbols — by default, stars — to communicate a ranking
  # level." — Rating indicators, abstract.
  #
  # HIG: "A rating indicator doesn't display partial symbols; it rounds
  # the value to display complete symbols only." — Rating indicators,
  # abstract.
  class RatingIndicator < View
    # Current rating value.  Clamped to 0..max at render time.
    # Fractional values are rounded to the nearest integer star.
    property value : Float64

    # Maximum number of stars (and the upper bound of the rating scale).
    # Defaults to 5, matching the App Store and Music rating convention.
    property max : Int32

    # Tint color for star symbols.  When nil the renderer uses the
    # system yellow/orange (NSColor.systemYellowColor on macOS,
    # UIColor.systemYellowColor on iOS) which is the HIG default for
    # rating stars.
    property tint_color : Color?

    def initialize(
      @value : Float64 = 0.0,
      @max : Int32 = 5,
      @tint_color : Color? = nil
    )
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
