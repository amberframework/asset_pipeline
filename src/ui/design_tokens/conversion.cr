# OKLCH <-> sRGB color-space conversion routines used by the design-token
# engine. Deterministic and round-trip stable within documented tolerances.

module UI
  module DesignTokens
    # OKLCH ↔ sRGB conversion based on Björn Ottosson's OKLab/OKLCH algorithm.
    #
    # Reference: https://bottosson.github.io/posts/oklab/
    #
    # All routines are deterministic and round-trip stable within the tolerances
    # documented on each method. Out-of-gamut OKLCH triples are mapped into the
    # sRGB gamut by reducing chroma in fixed steps (0.001 chroma units) until
    # the result lies within [0, 1] on every linear-RGB channel. This is
    # perceptually preferable to naive RGB clamping (which warps hue).
    #
    # Internal convention: L is on [0, 1] (NOT [0, 100]); chroma is unbounded
    # in principle but in practice ≤ ~0.4 for displayable sRGB colors; hue is
    # in degrees on [0, 360).
    module Conversion
      extend self

      # Convert OKLCH to sRGB (each channel on [0, 1]).
      #
      # If the OKLCH triple is out of gamut, chroma is iteratively reduced
      # (by 0.001 per step) until the resulting sRGB lies within [0, 1] on
      # all channels. The hue is preserved exactly; only chroma is squeezed.
      def oklch_to_srgb(l : Float64, c : Float64, h : Float64) : Tuple(Float64, Float64, Float64)
        chroma = c
        # Cap iterations so we always terminate even with pathological input.
        500.times do
          r, g, b = oklch_to_srgb_unchecked(l, chroma, h)
          if in_unit_range?(r) && in_unit_range?(g) && in_unit_range?(b)
            return {clamp_unit(r), clamp_unit(g), clamp_unit(b)}
          end
          chroma -= 0.001
          break if chroma <= 0.0
        end
        # Fully desaturated fallback (chroma == 0): pure lightness.
        r, g, b = oklch_to_srgb_unchecked(l, 0.0, h)
        {clamp_unit(r), clamp_unit(g), clamp_unit(b)}
      end

      # Convert sRGB (each channel on [0, 1]) to OKLCH.
      def srgb_to_oklch(r : Float64, g : Float64, b : Float64) : Tuple(Float64, Float64, Float64)
        lin_r = srgb_to_linear(r)
        lin_g = srgb_to_linear(g)
        lin_b = srgb_to_linear(b)

        l_lms = 0.4122214708_f64 * lin_r + 0.5363325363_f64 * lin_g + 0.0514459929_f64 * lin_b
        m_lms = 0.2119034982_f64 * lin_r + 0.6806995451_f64 * lin_g + 0.1073969566_f64 * lin_b
        s_lms = 0.0883024619_f64 * lin_r + 0.2817188376_f64 * lin_g + 0.6299787005_f64 * lin_b

        l_ = cbrt(l_lms)
        m_ = cbrt(m_lms)
        s_ = cbrt(s_lms)

        l_lab = 0.2104542553_f64 * l_ + 0.7936177850_f64 * m_ - 0.0040720468_f64 * s_
        a_lab = 1.9779984951_f64 * l_ - 2.4285922050_f64 * m_ + 0.4505937099_f64 * s_
        b_lab = 0.0259040371_f64 * l_ + 0.7827717662_f64 * m_ - 0.8086757660_f64 * s_

        c = Math.sqrt(a_lab * a_lab + b_lab * b_lab)
        h_rad = Math.atan2(b_lab, a_lab)
        h_deg = h_rad * 180.0 / Math::PI
        h_deg += 360.0 if h_deg < 0.0

        {l_lab, c, h_deg}
      end

      # Raw OKLCH → sRGB conversion that may return out-of-gamut channel values.
      # Used internally by `oklch_to_srgb` (which adds gamut mapping).
      def oklch_to_srgb_unchecked(l : Float64, c : Float64, h : Float64) : Tuple(Float64, Float64, Float64)
        h_rad = h * Math::PI / 180.0
        a_lab = c * Math.cos(h_rad)
        b_lab = c * Math.sin(h_rad)

        l_ = l + 0.3963377774_f64 * a_lab + 0.2158037573_f64 * b_lab
        m_ = l - 0.1055613458_f64 * a_lab - 0.0638541728_f64 * b_lab
        s_ = l - 0.0894841775_f64 * a_lab - 1.2914855480_f64 * b_lab

        l_lms = l_ * l_ * l_
        m_lms = m_ * m_ * m_
        s_lms = s_ * s_ * s_

        lin_r = 4.0767416621_f64 * l_lms - 3.3077115913_f64 * m_lms + 0.2309699292_f64 * s_lms
        lin_g = -1.2684380046_f64 * l_lms + 2.6097574011_f64 * m_lms - 0.3413193965_f64 * s_lms
        lin_b = -0.0041960863_f64 * l_lms - 0.7034186147_f64 * m_lms + 1.7076147010_f64 * s_lms

        {linear_to_srgb(lin_r), linear_to_srgb(lin_g), linear_to_srgb(lin_b)}
      end

      # Gamma-encode a linear sRGB channel into companded sRGB.
      def linear_to_srgb(x : Float64) : Float64
        return -linear_to_srgb(-x) if x < 0.0
        return 0.0 if x == 0.0
        if x >= 0.0031308
          1.055 * (x ** (1.0 / 2.4)) - 0.055
        else
          12.92 * x
        end
      end

      # Decode a companded sRGB channel into linear sRGB.
      def srgb_to_linear(x : Float64) : Float64
        return -srgb_to_linear(-x) if x < 0.0
        if x >= 0.04045
          ((x + 0.055) / 1.055) ** 2.4
        else
          x / 12.92
        end
      end

      # Cube root that preserves sign (handles negative LMS values cleanly).
      def cbrt(x : Float64) : Float64
        if x < 0.0
          -((-x) ** (1.0 / 3.0))
        else
          x ** (1.0 / 3.0)
        end
      end

      # ΔE2000 color difference between two OKLCH (or sRGB-derived OKLCH)
      # triples. Used by validation specs; not on the hot path.
      #
      # The reference algorithm is in CIE Lab, so we convert OKLCH → linear sRGB
      # → CIE XYZ → CIE Lab and compare in that space. This matches the
      # perceptual-difference bar the Architect tightened to ΔE2000 ≤ 1.0 at
      # the five canonical palette comparison points.
      def delta_e_2000(
        l1 : Float64, c1 : Float64, h1 : Float64,
        l2 : Float64, c2 : Float64, h2 : Float64,
      ) : Float64
        lab1 = oklch_to_ciexyz_lab(l1, c1, h1)
        lab2 = oklch_to_ciexyz_lab(l2, c2, h2)
        ciede2000(lab1, lab2)
      end

      private def in_unit_range?(x : Float64) : Bool
        x >= -0.0005 && x <= 1.0005
      end

      private def clamp_unit(x : Float64) : Float64
        return 0.0 if x < 0.0
        return 1.0 if x > 1.0
        x
      end

      # OKLCH → sRGB → linear sRGB → CIE XYZ (D65) → CIE Lab.
      private def oklch_to_ciexyz_lab(l : Float64, c : Float64, h : Float64) : Tuple(Float64, Float64, Float64)
        r, g, b = oklch_to_srgb(l, c, h)
        lin_r = srgb_to_linear(r)
        lin_g = srgb_to_linear(g)
        lin_b = srgb_to_linear(b)
        # sRGB D65 to XYZ
        x = 0.4124564_f64 * lin_r + 0.3575761_f64 * lin_g + 0.1804375_f64 * lin_b
        y = 0.2126729_f64 * lin_r + 0.7151522_f64 * lin_g + 0.0721750_f64 * lin_b
        z = 0.0193339_f64 * lin_r + 0.1191920_f64 * lin_g + 0.9503041_f64 * lin_b
        # D65 reference white
        xn = 0.95047_f64
        yn = 1.00000_f64
        zn = 1.08883_f64
        fx = lab_f(x / xn)
        fy = lab_f(y / yn)
        fz = lab_f(z / zn)
        l_lab = 116.0 * fy - 16.0
        a_lab = 500.0 * (fx - fy)
        b_lab = 200.0 * (fy - fz)
        {l_lab, a_lab, b_lab}
      end

      private def lab_f(t : Float64) : Float64
        delta = 6.0 / 29.0
        if t > delta * delta * delta
          t ** (1.0 / 3.0)
        else
          t / (3.0 * delta * delta) + 4.0 / 29.0
        end
      end

      # Sharma 2005 implementation of CIEDE2000.
      private def ciede2000(lab1 : Tuple(Float64, Float64, Float64), lab2 : Tuple(Float64, Float64, Float64)) : Float64
        l1, a1, b1 = lab1
        l2, a2, b2 = lab2

        c1 = Math.sqrt(a1 * a1 + b1 * b1)
        c2 = Math.sqrt(a2 * a2 + b2 * b2)
        c_bar = (c1 + c2) / 2.0
        c_bar7 = c_bar ** 7
        g = 0.5 * (1.0 - Math.sqrt(c_bar7 / (c_bar7 + 25.0 ** 7)))

        a1p = (1.0 + g) * a1
        a2p = (1.0 + g) * a2

        c1p = Math.sqrt(a1p * a1p + b1 * b1)
        c2p = Math.sqrt(a2p * a2p + b2 * b2)

        h1p = (b1 == 0.0 && a1p == 0.0) ? 0.0 : (Math.atan2(b1, a1p) * 180.0 / Math::PI)
        h1p += 360.0 if h1p < 0.0
        h2p = (b2 == 0.0 && a2p == 0.0) ? 0.0 : (Math.atan2(b2, a2p) * 180.0 / Math::PI)
        h2p += 360.0 if h2p < 0.0

        dlp = l2 - l1
        dcp = c2p - c1p

        dhp = if c1p * c2p == 0.0
                0.0
              elsif (h2p - h1p).abs <= 180.0
                h2p - h1p
              elsif (h2p - h1p) > 180.0
                (h2p - h1p) - 360.0
              else
                (h2p - h1p) + 360.0
              end

        dhp_term = 2.0 * Math.sqrt(c1p * c2p) * Math.sin((dhp * Math::PI / 180.0) / 2.0)

        l_bar = (l1 + l2) / 2.0
        cp_bar = (c1p + c2p) / 2.0

        hp_bar = if c1p * c2p == 0.0
                   h1p + h2p
                 elsif (h1p - h2p).abs <= 180.0
                   (h1p + h2p) / 2.0
                 elsif (h1p + h2p) < 360.0
                   (h1p + h2p + 360.0) / 2.0
                 else
                   (h1p + h2p - 360.0) / 2.0
                 end

        t = 1.0 -
            0.17 * Math.cos((hp_bar - 30.0) * Math::PI / 180.0) +
            0.24 * Math.cos((2.0 * hp_bar) * Math::PI / 180.0) +
            0.32 * Math.cos((3.0 * hp_bar + 6.0) * Math::PI / 180.0) -
            0.20 * Math.cos((4.0 * hp_bar - 63.0) * Math::PI / 180.0)

        delta_theta = 30.0 * Math.exp(-(((hp_bar - 275.0) / 25.0) ** 2))
        cp_bar7 = cp_bar ** 7
        rc = 2.0 * Math.sqrt(cp_bar7 / (cp_bar7 + 25.0 ** 7))
        sl = 1.0 + (0.015 * ((l_bar - 50.0) ** 2)) / Math.sqrt(20.0 + (l_bar - 50.0) ** 2)
        sc = 1.0 + 0.045 * cp_bar
        sh = 1.0 + 0.015 * cp_bar * t
        rt = -Math.sin(2.0 * delta_theta * Math::PI / 180.0) * rc

        Math.sqrt(
          (dlp / sl) ** 2 +
            (dcp / sc) ** 2 +
            (dhp_term / sh) ** 2 +
            rt * (dcp / sc) * (dhp_term / sh)
        )
      end
    end
  end
end
