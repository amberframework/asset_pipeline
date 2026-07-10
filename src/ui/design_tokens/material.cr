# Two-axis material model (semantic role + thickness) for design-token-driven
# glass/translucency surfaces. Replaces the pre-v2 thickness-only model.

module UI
  module DesignTokens
    # Phase 5 v2 — TWO-AXIS Material model.
    #
    # The pre-v2 single-axis model treated glass material as a thickness step
    # (`:ultra_thin`/`:thin`/`:regular`/`:thick`/`:chrome`) with proportional
    # intensity scaling applied uniformly on every renderer. Codex round 1+2
    # critique pointed out that Apple's `NSVisualEffectMaterial` is SEMANTIC
    # (Menu / Popover / Sidebar / Sheet / etc.), not thickness-based.
    #
    # Phase 5 v2 splits the model into two axes:
    #
    #   * `AppleSemantic`   — role-based identity used by Apple chrome
    #                          (NSVisualEffectMaterial integer on macOS;
    #                          UIBlurEffectStyle approximation on iOS).
    #                          Intensity does NOT modify this axis — Apple
    #                          materials are role-based, not intensity-scaled.
    #
    #   * `ThicknessStep`   — discrete thickness used by web + Android.
    #                          The `thickness_for_brand` quantizer
    #                          (`intensity * step_baseline -> effective step`)
    #                          selects which step's predefined `blur_radius`
    #                          / `opacity` apply. This REPLACES iter1's
    #                          proportional-scaling model where every
    #                          intensity value linearly scaled the declared
    #                          step's blur radius — quantizer model gives
    #                          fewer discrete output states but matches the
    #                          architecture's "intensity selects step, step
    #                          determines visual" contract.
    #
    # See:
    #   * `docs/initiative-cross-platform-ui/handoff/phase-05-v2-architecture-2026-05-22.md`
    #   * `docs/initiative-cross-platform-ui/phases/phase-05-glass-material-tokenization/brief.yml`
    #     adapter_cardinality rows 1-3 for the cross-platform consumer-visible
    #     contract.

    # Apple semantic material role. Maps 1:1 to `NSVisualEffectMaterial`
    # integers on macOS; iOS uses an approximation table (UIKit does not
    # expose semantic materials — UIBlurEffectStyle is thickness-like).
    #
    # `SystemResolved` is the sentinel value — when a widget declares it,
    # the renderer emits NO `setMaterial:` / `setEffect:` call and lets
    # Apple defaults apply. This is the HIG-canonical choice for widgets
    # whose chrome is system-drawn (Alert, TabView's bar background,
    # Toolbar's bar background).
    enum AppleSemantic
      Menu             # NSVisualEffectMaterialMenu = 5
      Popover          # NSVisualEffectMaterialPopover = 6
      Sidebar          # NSVisualEffectMaterialSidebar = 7
      Sheet            # NSVisualEffectMaterialSheet = 11
      HeaderView       # NSVisualEffectMaterialHeaderView = 10
      WindowBackground # NSVisualEffectMaterialWindowBackground = 12
      HUDWindow        # NSVisualEffectMaterialHUDWindow = 13
      Titlebar         # NSVisualEffectMaterialTitlebar = 3
      SystemResolved   # special: emit no setMaterial:; let Apple defaults apply

      # Parse a stringified form (e.g. `"menu"`, `"popover"`, `"system_resolved"`,
      # also accepts the Crystal `to_s` variants like `"Menu"`). Returns
      # `SystemResolved` for nil / unknown values rather than raising — the
      # populator path uses this in production code where an invalid string
      # is a soft-failure (just use system defaults).
      def self.from_key(key : String?) : AppleSemantic
        return SystemResolved if key.nil?
        case key.downcase
        when "menu"              then Menu
        when "popover"           then Popover
        when "sidebar"           then Sidebar
        when "sheet"             then Sheet
        when "header_view", "headerview" then HeaderView
        when "window_background", "windowbackground" then WindowBackground
        when "hud_window", "hudwindow" then HUDWindow
        when "titlebar"          then Titlebar
        when "system_resolved", "systemresolved" then SystemResolved
        else                          SystemResolved
        end
      end

      # Canonical lowercase snake_case key (round-trips through `from_key`).
      def to_key : String
        case self
        in .menu?              then "menu"
        in .popover?           then "popover"
        in .sidebar?           then "sidebar"
        in .sheet?             then "sheet"
        in .header_view?       then "header_view"
        in .window_background? then "window_background"
        in .hud_window?        then "hud_window"
        in .titlebar?          then "titlebar"
        in .system_resolved?   then "system_resolved"
        end
      end
    end

    # Discrete thickness step. Drives web `backdrop-filter: blur(...)` radius
    # and Android `RenderEffect.createBlurEffect` radius via the per-step
    # `blur_radius` and `opacity` constants on `MaterialStep`.
    enum ThicknessStep
      UltraThin
      Thin
      Regular
      Thick
      Chrome

      # Canonical lowercase snake_case key (matches the legacy Symbol
      # convention `:ultra_thin` / `:thin` / `:regular` / `:thick` / `:chrome`).
      def to_key : String
        case self
        in .ultra_thin? then "ultra_thin"
        in .thin?       then "thin"
        in .regular?    then "regular"
        in .thick?      then "thick"
        in .chrome?     then "chrome"
        end
      end

      # The legacy Symbol form, used by backwards-compat shims that still
      # accept `Symbol` parameters.
      def to_symbol : Symbol
        case self
        in .ultra_thin? then :ultra_thin
        in .thin?       then :thin
        in .regular?    then :regular
        in .thick?      then :thick
        in .chrome?     then :chrome
        end
      end

      # Convert from the legacy Symbol form. Falls back to `Regular` for
      # unknown symbols — matches the prior `step(:foo)` fallback semantics.
      def self.from_symbol(sym : Symbol) : ThicknessStep
        case sym
        when :ultra_thin then UltraThin
        when :thin       then Thin
        when :regular    then Regular
        when :thick      then Thick
        when :chrome     then Chrome
        else                  Regular
        end
      end
    end

    # One material strength step. `blur_radius` is the CSS-px / Android-dp
    # value used when the step is selected by the quantizer; `opacity` is
    # the per-step fill opacity used by the web `@supports not (backdrop-
    # filter)` fallback and the Android API < 31 alpha fallback.
    record MaterialStep,
      blur_radius : Float64,
      opacity : Float64,
      saturation : Float64,
      luminance : Float64

    # Glass material token branch (two-axis).
    #
    # `step` is the declared `ThicknessStep`; `semantic` is the declared
    # `AppleSemantic`; `intensity` is the brand-declaration-time scalar
    # used by the `thickness_for_brand` quantizer on web + Android.
    #
    # Per-step records (`ultra_thin` / `thin` / `regular` / `thick` /
    # `chrome`) carry the predefined blur_radius / opacity constants the
    # quantizer's effective step lookup returns.
    #
    # Render-time only. Material changes require a re-render — there is
    # no runtime mutator on intensity / step / semantic. Consumers
    # observe brand-overridden values by rebuilding the view tree.
    record Material,
      ultra_thin : MaterialStep,
      thin : MaterialStep,
      regular : MaterialStep,
      thick : MaterialStep,
      chrome : MaterialStep,
      intensity : Float64,
      step : ThicknessStep = ThicknessStep::Regular,
      semantic : AppleSemantic = AppleSemantic::SystemResolved do

      # ---------------------------------------------------------------
      # Apple axis: the declared semantic, unchanged. Intensity does
      # NOT modify this — Apple materials are role-based.
      # ---------------------------------------------------------------
      def apple_semantic : AppleSemantic
        semantic
      end

      # ---------------------------------------------------------------
      # Web / Android axis: quantizer model.
      #
      # Per the v2 architecture doc lines 65-77:
      #   baseline = step_baseline(step)
      #   i = baseline * intensity
      #   <= 0.3 -> UltraThin
      #   <= 0.7 -> Thin
      #   <= 1.3 -> Regular
      #   >= 1.8 -> Chrome
      #   else    -> Thick
      # ---------------------------------------------------------------
      def thickness_for_brand : ThicknessStep
        baseline = self.class.step_baseline(step)
        i = baseline * intensity
        return ThicknessStep::UltraThin if i <= 0.3
        return ThicknessStep::Thin if i <= 0.7
        return ThicknessStep::Regular if i <= 1.3
        return ThicknessStep::Chrome if i >= 1.8
        ThicknessStep::Thick
      end

      # Per-step baseline multiplier for the quantizer. Step baselines
      # are deliberately spaced so that at `intensity = 1.0` each declared
      # step quantizes back to itself (UltraThin->UltraThin, etc.),
      # except `Chrome` (baseline 1.9) which collapses to Chrome (>= 1.8
      # bucket) — that's the documented "Chrome is the ceiling" behavior.
      def self.step_baseline(step : ThicknessStep) : Float64
        case step
        in .ultra_thin? then 0.2
        in .thin?       then 0.5
        in .regular?    then 1.0
        in .thick?      then 1.5
        in .chrome?     then 1.9
        end
      end

      # Lookup the `MaterialStep` for a `ThicknessStep`.
      def material_step_for(s : ThicknessStep) : MaterialStep
        case s
        in .ultra_thin? then ultra_thin
        in .thin?       then thin
        in .regular?    then regular
        in .thick?      then thick
        in .chrome?     then chrome
        end
      end

      # ---------------------------------------------------------------
      # Backwards-compat: pre-v2 callers used `step(:menu)` / `step(:thin)`
      # with a single-axis Symbol vocabulary. The v2 model splits the
      # vocabulary (semantics on Apple, thickness on web/Android), so
      # these shims convert Symbol -> appropriate axis output:
      #
      #   * `step(name)` — accepts the legacy ThicknessStep symbol shape;
      #     unknown symbols fall back to the declared `step`.
      #   * `apple_step(declared)` — legacy quantizer call. v2 maps the
      #     declared Symbol through `ThicknessStep.from_symbol`,
      #     overrides this Material's step temporarily via copy, then
      #     applies `thickness_for_brand` and returns the result as a
      #     Symbol. Callers (GlassBackground visit, web_renderer,
      #     android_renderer) get the same Symbol-in/Symbol-out shape
      #     they had pre-v2; the QUANTIZER semantics are now correct.
      #   * `resolve(name)` — preserved; uses the quantizer's effective
      #     step to choose blur_radius (not proportional scaling).
      # ---------------------------------------------------------------
      def step(name : Symbol) : MaterialStep
        material_step_for(ThicknessStep.from_symbol(name))
      end

      def apple_step(declared : Symbol) : Symbol
        declared_step = ThicknessStep.from_symbol(declared)
        # Apply the quantizer using the declared step as the baseline source.
        # Yields the same Symbol-in/Symbol-out contract the old single-axis
        # callers expect, but routes through `thickness_for_brand` so the
        # semantics are uniform with v2's web + Android quantizer model.
        Material.new(
          ultra_thin: ultra_thin,
          thin: thin,
          regular: regular,
          thick: thick,
          chrome: chrome,
          intensity: intensity,
          step: declared_step,
          semantic: semantic,
        ).thickness_for_brand.to_symbol
      end

      # Render-time resolution for web / Android. Returns a `ResolvedStep`
      # carrying the EFFECTIVE step's predefined blur_radius + opacity (not
      # proportionally scaled). The `name` field in the resolved record is
      # the effective step's Symbol so renderers that key CSS classes /
      # custom-property suffixes on the step name still find the right
      # bucket.
      def resolve(name : Symbol) : ResolvedStep
        effective = Material.new(
          ultra_thin: ultra_thin,
          thin: thin,
          regular: regular,
          thick: thick,
          chrome: chrome,
          intensity: intensity,
          step: ThicknessStep.from_symbol(name),
          semantic: semantic,
        ).thickness_for_brand
        s = material_step_for(effective)
        ResolvedStep.new(
          name: effective.to_symbol,
          blur_radius: s.blur_radius,
          opacity: s.opacity,
          saturation: s.saturation,
          luminance: s.luminance,
        )
      end
    end

    # Output of `Material#resolve` — what web + Android renderers consume.
    # Under the v2 quantizer model, `name` is the EFFECTIVE step (the
    # quantizer's output), not the originally declared step.
    record ResolvedStep,
      name : Symbol,
      blur_radius : Float64,
      opacity : Float64,
      saturation : Float64,
      luminance : Float64
  end
end
