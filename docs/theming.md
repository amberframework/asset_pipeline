# Theming an Asset Pipeline UI app

## 1. The short answer

- A skin is a separate consumer shard; this commit has no `UI::Skin` registry or global style singleton.
- The shard subclasses `UI::DesignTokens::Brand` and overrides the light and dark palettes, plus token scales the app will use.
- It vendors font files with a pinned source commit, a SHA-256 manifest, and a checksum spec; `FontRegistry` registers TTF/OTF files on macOS.
- It exposes screen-builder helpers that apply per-view `SurfaceStyle`, `TabShape`, `ToggleAppearance`, `KeycapStyle`, `ColorSwatchPickerStyle`, and `InteractionFeedback` settings.
- The host activates tokens on each renderer with `renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(YourSkin::Brand.new)`.
- `UI::App.design_tokens` stores an app token value, but this commit does not wire it into renderer instances automatically.
- A full skin therefore combines app tokens with screen helpers; native window chrome and several iOS/Android styles remain system-owned or unsupported.

## 2. Layer map

Use tokens for shared app identity and a skin helper for each view that needs a specific treatment. The `Brand` hooks return a new `Tokens`; omitted fields keep their defaults. This guide covers `UI::DesignTokens::Tokens` and the generic `UI` view layer. The web renderer also emits compatibility CSS from `UI::Theme`; that adapter and `Components::CSS::Tokens::Theme` do not automatically follow a renderer's custom tokens. Source paths below are relative to this repository at commit `0e5a33bc26d23805a531f3e2c0a42b69271c76a4`.

### App-wide tokens

| Layer | What it controls and exact API | Scope and current reach |
| --- | --- | --- |
| Color palettes | `UI::DesignTokens::ColorPalette`; the light/dark values are `Tokens#colors_light` and `#colors_dark`. Override with `Brand#override_color_light` and `#override_color_dark`. `ColorPalette#to_h` exposes all 23 roles to generators. [src/ui/design_tokens.cr:350](../src/ui/design_tokens.cr#L350), [src/ui/design_tokens.cr:876](../src/ui/design_tokens.cr#L876), [src/ui/design_tokens/generators/web_generator.cr:139](../src/ui/design_tokens/generators/web_generator.cr#L139) | Per app. Web emits every role as `--ap-color-*`. On Apple, the renderer installs the primary accent cascade; native surface-role resolution is narrower and described under Known gaps. |
| Semantic color roles | The palette roles are listed below. `UI::ColorRole` is a separate, smaller set accepted by `SurfaceColor` styles. [src/ui/view.cr:163](../src/ui/view.cr#L163) | Per app in `Tokens`; per view when a style uses `ColorRole`. Web resolves those roles to token CSS variables. macOS maps most style roles to system colors. |
| Typography | `TypeScale` has `family_sans`, `family_display`, `family_mono`, and `caption`, `body`, `body_emph`, `title`, `headline`, `display` steps. `TypeStep` has `size`, `line_height`, `weight`, `tracking`; override with `Brand#override_type`. [src/ui/design_tokens.cr:535](../src/ui/design_tokens.cr#L535), [src/ui/design_tokens.cr:541](../src/ui/design_tokens.cr#L541), [src/ui/design_tokens.cr:888](../src/ui/design_tokens.cr#L888) | Per app token data. Web emits type CSS variables, but labels still take an explicit `UI::Font`; native labels also use per-view `Font`. There is no automatic app-wide font assignment. |
| Font registration | `UI::FontRegistry.register_bundled_font_file(path : String) : Bool`; `UI::Font` carries a family, size, weight, and italic flag. [src/ui/font_registry.cr:11](../src/ui/font_registry.cr#L11), [src/ui/view.cr:457](../src/ui/view.cr#L457) | Per process on macOS only. It accepts `.ttf`/`.otf` files and returns `false` for invalid files or non-macOS builds. |
| Spacing and radius | `SpacingScale` has `px`, `x0`, `x0_5`, `x1`, `x1_5`, `x2`, `x2_5`, `x3`, `x3_5`, `x4`, `x5`–`x12`, `x14`, `x16`, `x20`, `x24`, `x28`, `x32`, `x36`, `x40`, `x44`, `x48`, `x52`, `x56`, `x60`, `x64`, `x72`, `x80`, `x96`. `RadiusScale` has `none`, `xs`, `sm`, `md`, `lg`, `xl`, `x2l`, `card`, `sheet`, `avatar`, `avatar_lg`, `pill`. Override with `Brand#override_spacing` / `#override_radius`. [src/ui/design_tokens.cr:439](../src/ui/design_tokens.cr#L439), [src/ui/design_tokens.cr:570](../src/ui/design_tokens.cr#L570), [src/ui/design_tokens.cr:884](../src/ui/design_tokens.cr#L884), [src/ui/design_tokens.cr:892](../src/ui/design_tokens.cr#L892) | Per app token data. Web emits CSS variables. Native layout still uses per-view insets and corner radii; a scale override alone does not restyle every view. |
| Shadows, motion, material, breakpoints, targets | `ShadowScale` contains `flat`, `raised`, `floating`, `overlay` `ShadowLevel` arrays; a level has offsets, blur, spread, and color. `MotionScale` holds duration/easing values; `Breakpoints` holds `sm` through `x2l`; `Tokens` also has `material` and `touch_target_minimum_px`. Override with `Brand#override_shadow`, `#override_motion`, `#override_breakpoints`, `#override_material`, and `#override_touch_target_minimum_px`. [src/ui/design_tokens.cr:602](../src/ui/design_tokens.cr#L602), [src/ui/design_tokens.cr:609](../src/ui/design_tokens.cr#L609), [src/ui/design_tokens.cr:625](../src/ui/design_tokens.cr#L625), [src/ui/design_tokens.cr:634](../src/ui/design_tokens.cr#L634), [src/ui/design_tokens.cr:896](../src/ui/design_tokens.cr#L896), [src/ui/design_tokens.cr:900](../src/ui/design_tokens.cr#L900), [src/ui/design_tokens.cr:904](../src/ui/design_tokens.cr#L904), [src/ui/design_tokens.cr:912](../src/ui/design_tokens.cr#L912), [src/ui/design_tokens.cr:916](../src/ui/design_tokens.cr#L916) | Per app token data. Web emits these values; GlassBackground and some renderer paths consume material/target values. SurfaceCraft shadows are separate per-view values. |
| Token activation | `Tokens.default.with_brand(brand)` returns the resolved token object. `UI::App` also offers `design_tokens do |tokens| ... end` and `app_design_tokens`. [src/ui/design_tokens.cr:710](../src/ui/design_tokens.cr#L710), [src/asset_pipeline/native_app.cr:383](../src/asset_pipeline/native_app.cr#L383) | Per app/renderer. Assign the result to each renderer; `UI::App` does not do that assignment in this revision. |

### The 23 palette roles

Every role is a `ColorPalette` field at [src/ui/design_tokens.cr:350](../src/ui/design_tokens.cr#L350). These names describe intended use. `WebGenerator` emits all of them; a native view only receives a role where its renderer or skin helper asks for it.

| Role | Intended use |
| --- | --- |
| `brand_primary` | Primary action and tint/accent. The AppKit and UIKit renderers pass this value into the SwiftUI tint cascade. |
| `brand_primary_hover` | Hover state for primary actions. |
| `brand_primary_active` | Pressed/active state for primary actions. |
| `brand_secondary` | Secondary brand signal or action. |
| `brand_accent` | Tertiary highlight or secondary accent. |
| `surface_canvas` | Main page or app-content ground. |
| `surface_panel` | Grouped panel, card, or form surface. |
| `surface_elevated` | Raised surface, tab, or control face. |
| `surface_sunken` | Inset well, track, or recessed field. |
| `surface_inverse` | Inverse surface used behind inverse text. |
| `text_primary` | Primary reading text. |
| `text_secondary` | Supporting or secondary text. |
| `text_muted` | Quiet metadata, placeholders, or helper text. |
| `text_inverse` | Text on an inverse or filled surface. |
| `text_link` | Link text. |
| `border_subtle` | Quiet separators and edges. |
| `border_default` | Standard field and control outlines. |
| `border_strong` | Emphasized outline. |
| `border_focus` | Keyboard focus indicator. |
| `success` | Success state. |
| `warning` | Warning state. |
| `danger` | Destructive or error state. |
| `info` | Informational state. |

`UI::ColorRole` currently exposes only `BrandPrimary`, `BrandAccent`, `SurfaceCanvas`, `SurfaceElevated`, `SurfacePanel`, `SurfaceSunken`, `SurfaceInverse`, `TextPrimary`, `TextInverse`, and `Warning` for `SurfaceColor` values. Apple `LabelRole` (`Primary`, `Secondary`, `Tertiary`, `Quaternary`) is another API: it asks the OS for dynamic label colors and is not a `ColorPalette` role. [src/ui/view.cr:163](../src/ui/view.cr#L163), [src/ui/theme.cr:29](../src/ui/theme.cr#L29)

### Per-view styles and controls

| Layer | What it controls and exact API | Scope and current reach |
| --- | --- | --- |
| Surfaces | `SurfaceStyle` holds `background_fill_color`, `linear_gradient`, `list_of_inner_shadows`, `list_of_drop_shadows`, and `texture_overlay`. Other views expose those surface properties individually on `UI::View`; there is no `view.surface_style = ...` property. [src/ui/view.cr:185](../src/ui/view.cr#L185), [src/ui/view.cr:205](../src/ui/view.cr#L205), [src/ui/view.cr:212](../src/ui/view.cr#L212), [src/ui/view.cr:225](../src/ui/view.cr#L225), [src/ui/view.cr:237](../src/ui/view.cr#L237), [src/ui/view.cr:778](../src/ui/view.cr#L778) | Per view. SurfaceStyle is accepted by Form sections; set equivalent view properties on other controls. macOS SwiftUI/AppKit and web render these primitives. |
| Form sections | `UI::Form#add_section(header, footer, tab_shape:, tab_icon:, panel_style:, tab_style:)` returns a `FormSection`. [src/ui/views/form.cr:50](../src/ui/views/form.cr#L50), [src/ui/views/form.cr:99](../src/ui/views/form.cr#L99) | Per section. `TabShape` is `Angled`, `Rounded`, `Notched`, or `Flush`; `tab_icon` is an SF Symbol name on macOS. iOS and Android keep the plain grouped Form. |
| Toggles | `UI::Toggle#appearance`, `track_color`, `knob_color`, `on_color`, and `lamp_color`; `ToggleAppearance` is `Native`, `Pill`, `Rocker`, `Slide`, or `LampPill`. [src/ui/views/toggle.cr:36](../src/ui/views/toggle.cr#L36), [src/ui/view.cr:261](../src/ui/view.cr#L261) | Per view. Web and macOS implement the custom appearances; iOS keeps its native switch. |
| Keycaps | `UI::Keycap#style`; `KeycapStyle` is `Outlined`, `Sculpted`, `Inset`, or `Text`. [src/ui/views/keycap.cr:8](../src/ui/views/keycap.cr#L8), [src/ui/view.cr:270](../src/ui/view.cr#L270) | Per view. macOS and web render the SurfaceCraft treatment; other platforms retain a label. |
| Color pickers | `UI::ColorSwatchPicker#appearance` and `#selection_ring_color`; `ColorSwatchPickerStyle` is `SwatchButton`, `SwatchRow`, `NamedPopup`, or `BezelLamp`. Each swatch has a name and `SurfaceColor`. [src/ui/views/color_swatch_picker.cr:37](../src/ui/views/color_swatch_picker.cr#L37), [src/ui/view.cr:278](../src/ui/view.cr#L278) | Per view. Web and macOS render the named swatch styles; iOS/Android retain their plain picker behavior. |
| Buttons, menus, and popups | `UI::Button` exposes `style`, `role`, `font`, `foreground_color`, and base `View` modifiers; not all SurfaceCraft modifiers reach its macOS facade. `UI::MenuButton` exposes `button_style`, `is_pull_down`, and `selected_index`. [src/ui/views/button.cr:45](../src/ui/views/button.cr#L45), [src/ui/views/button.cr:68](../src/ui/views/button.cr#L68), [src/ui/views/menu_button.cr:26](../src/ui/views/menu_button.cr#L26), [src/ui/views/menu_button.cr:50](../src/ui/views/menu_button.cr#L50) | Per view. Use a skin helper to select styles and colors. System menu/popover chrome remains OS-controlled; there is no global skin default for every button or popup. |
| Hover and press | `UI::View#interaction_feedback` accepts `None`, `Sink`, `Lift`, or `Edge`. [src/ui/view.cr:245](../src/ui/view.cr#L245), [src/ui/view.cr:793](../src/ui/view.cr#L793) | Per view. Web emits `data-ap-feedback` and honors reduced motion. macOS applies it to supported facades, with the Button exception in Known gaps. |
| Labels | `UI::Label#font`, `#text_color`, and `#text_color_role`; native labels default to Apple dynamic label colors. [src/ui/views/label.cr:16](../src/ui/views/label.cr#L16), [src/ui/views/label.cr:39](../src/ui/views/label.cr#L39), [src/ui/views/label.cr:70](../src/ui/views/label.cr#L70) | Per view. Set `UI::Font` from your skin helper. On Apple, set `text_color_role = nil` before assigning a literal brand `text_color`; web and Android ignore `LabelRole`. |

### Window chrome and renderers

| Layer | What it controls and exact API | Scope and current reach |
| --- | --- | --- |
| Title bar and window | `UI::Windows.configure` / `WindowConfiguration` set title, subtitle, size limits, `WindowTitlebarStyle`, visibility, toolbar visibility, full-screen support, and resize behavior. [src/ui/windows.cr:13](../src/ui/windows.cr#L13), [src/ui/windows.cr:62](../src/ui/windows.cr#L62), [src/ui/windows.cr:166](../src/ui/windows.cr#L166) | Per window. The API does not set title-bar color, title font, traffic-light color, or the native window background. A root content view can have a per-view background; that is not the NSWindow chrome. |
| Toolbar | `UI::Toolbar#material_semantic` can choose a platform material; `nil` keeps the system default. [src/ui/views/toolbar.cr:9](../src/ui/views/toolbar.cr#L9), [src/ui/views/toolbar.cr:26](../src/ui/views/toolbar.cr#L26) | Per toolbar, material only. It does not set arbitrary toolbar or title-bar colors. |
| Footer | `FormSection#footer` is a `String?`; `UI::Panel#footer` is a `UI::View?`. [src/ui/views/form.cr:50](../src/ui/views/form.cr#L50), [src/ui/views/panel.cr:31](../src/ui/views/panel.cr#L31) | There is no window-level footer-bar skin API. A Panel footer is ordinary content and can use the same per-view helpers as other content. |
| Web renderer | `UI::Web::Renderer#design_tokens` feeds `inject_theme_css`, which calls `WebGenerator.generate`. Output includes `:root`, a dark preference block, and explicit `[data-ap-theme]` palettes. `inject_theme_css` also emits `theme.to_css_custom_properties` for legacy `--md-sys-*` variables; `theme` defaults to `UI::Theme.design_system_default`. [src/ui/renderers/web_renderer.cr:35](../src/ui/renderers/web_renderer.cr#L35), [src/ui/renderers/web_renderer.cr:60](../src/ui/renderers/web_renderer.cr#L60), [src/ui/renderers/web_renderer.cr:70](../src/ui/renderers/web_renderer.cr#L70), [src/ui/design_tokens/generators/web_generator.cr:26](../src/ui/design_tokens/generators/web_generator.cr#L26) | Per renderer. `SurfaceColor` roles become `var(--ap-color-...)`. The legacy theme is independent: assign `renderer.theme` from the skin tokens if its `--md-sys-*` consumers must match. The default body font is system UI; app typography is set per view. |
| macOS renderer | `UI::AppKit::Renderer#design_tokens`; the renderer applies `colors_light.brand_primary` to the SwiftUI tint cascade. [src/ui/renderers/appkit_renderer.cr:4530](../src/ui/renderers/appkit_renderer.cr#L4530), [src/ui/renderers/appkit_renderer.cr:4587](../src/ui/renderers/appkit_renderer.cr#L4587) | Per renderer. SwiftKit provides custom tabs, toggles, keycaps, swatches, and view surfaces, with the listed gaps. |
| iOS renderer | `UI::UIKit::Renderer#design_tokens` exists and applies the primary tint. [src/ui/renderers/uikit_renderer.cr:5087](../src/ui/renderers/uikit_renderer.cr#L5087), [src/ui/renderers/uikit_renderer.cr:5137](../src/ui/renderers/uikit_renderer.cr#L5137) | Partial. It keeps native Form, switch, and picker rendering; custom SurfaceCraft styles are not a complete iOS implementation. `FontRegistry` returns `false` outside macOS. |
| Android renderer | `UI::Android::Renderer#design_tokens` exists and currently resolves material for `GlassBackground`. [src/ui/renderers/android_renderer.cr:277](../src/ui/renderers/android_renderer.cr#L277), [src/ui/renderers/android_renderer.cr:2194](../src/ui/renderers/android_renderer.cr#L2194) | Partial. There is no Android token generator, custom surface styling and font registration are gaps, and code paths that need a fixed system accent can raise `AndroidRendererNotImplemented` ([src/ui/design_tokens.cr:42](../src/ui/design_tokens.cr#L42)). The macOS-hosted Android compile is blocked by the Crystal stdlib's missing `c/sys/epoll`; this lane needs Linux-targeted Crystal and the Android NDK. |

The surface implementation matrix is also summarized in [Surface craft primitives](components/surface-craft.md#platform-coverage).

## 3. Step-by-step checklist

1. **Create a skin shard.** Keep package code under `src/<skin_name>/`, export it from `src/<skin_name>.cr`, keep fonts under `fonts/`, and add consumer-owned specs under `spec/`. `shard.yml` is only package metadata and dependency declarations; do not put palette, appearance, font, or app config keys there.

2. **Pin Asset Pipeline and generate the lock from a clean install.** For the surface API in this guide, use the reviewed commit. Start with a fresh consumer checkout whose `lib/` is empty:

   ```yaml
   dependencies:
     asset_pipeline:
       github: crimson-knight/asset_pipeline
       commit: 0e5a33bc26d23805a531f3e2c0a42b69271c76a4
   ```

   Then run `shards-alpha install` to create `shard.lock` and the checksum from that empty `lib/`, commit the generated lock, and verify it with `shards-alpha install --frozen`. Do not hand-edit the lock or skip checksum verification. The read-only `agentc_mac_ui` reference currently records checksum `sha256:3e35f6710763898312d82ed52e24e2480891ef21e69a5ee460266a0bdbe9b00d` for this Asset Pipeline commit.

3. **Implement a Brand subclass.** Override `override_color_light` and `override_color_dark` using `palette.copy_with(...)`. Override `override_type`, `override_spacing`, or other scale hooks only for values the app will consume. Keep light and dark decisions in their own palettes.

4. **Vendor fonts with provenance.** Copy exact font files and their license files from a pinned upstream source commit. Record the source commit in the skin shard, create `fonts/CHECKSUMS.sha256` with SHA-256 entries, and add a spec that checks every listed file and rejects unexpected files. Verify with `shasum -a 256 -c fonts/CHECKSUMS.sha256`. Register the bundled TTF/OTF files before building views that name their PostScript family:

   ```crystal
   unless UI::FontRegistry.register_bundled_font_file("fonts/Michroma-Regular.otf")
     raise "Could not register Michroma"
   end
   ```

   This registrar is macOS-only. A non-macOS result is `false`.

5. **Add view helpers.** Have section helpers pass `tab_shape`, `tab_icon`, `panel_style`, and `tab_style` to `Form#add_section`. Have toggle, keycap, picker, and button helpers set their exact view properties. Put literal light/dark colors in the skin helper layer and choose them from the active appearance when a native role cannot resolve the palette.

6. **Activate tokens in the app.** With a renderer instance, assign the brand result before its first render:

   ```crystal
   renderer.design_tokens = UI::DesignTokens::Tokens.default.with_brand(ExampleSkin::Brand.new)
   ```

   If the app subclasses `UI::App`, it can define the token value in the class body and feed the getter to the renderer:

   ```crystal
   design_tokens do |tokens|
     tokens.with_brand(ExampleSkin::Brand.new)
   end

   renderer.design_tokens = MyApp.app_design_tokens
   ```

   The macro belongs on the app class, not in `shard.yml`. The explicit renderer assignment is still required at this commit. In an Amber V2 app, require the skin and declare the `UI::App` subclass in `config/application.cr`, following [the repository's Amber V2 bootstrap sample](../samples/phase-08-amber-spike/config/application.cr). Register fonts in app startup before screen/view construction, and put the macro on the UI app subclass where it is declared. For a web renderer whose app still uses legacy `--md-sys-*` CSS, also assign `renderer.theme` using `UI::Theme.from_design_tokens(tokens, font_family:, body_size:, title_size:, headline_size:, caption_size:, corner_small:, corner_medium:, corner_large:)`; this is a separate adapter step.

7. **Convert each screen.** Replace local font/color literals with skin helpers. Use palette-backed roles where the renderer follows tokens; use the skin's appearance-aware helper for native literal-color surfaces. Add helpers for recurring control treatments so each screen uses the same choices.

8. **Verify the result.** Run the skin shard's specs and checksum spec, capture light and dark appearances, exercise controls through accessibility behavior specs, and calculate contrast for every rendered text/background pair. The checklist in section 8 has the repository commands.

## 4. Minimal complete skin example

The snippet is the body of [samples/theming/example_skin.cr](../samples/theming/example_skin.cr); that file has one repository-local `require "../../src/ui"` line before this module. [spec/web/docs/theming_example_spec.cr](../spec/web/docs/theming_example_spec.cr) requires the same file and asserts that both palettes resolve and each helper returns the chosen primitives.

```crystal
module ExampleSkin
  LIGHT_PRIMARY = UI::DesignTokens::Color.hex("#316C73")
  DARK_PRIMARY  = UI::DesignTokens::Color.hex("#A5D4CF")

  # Supplies the skin's light and dark accent colors while retaining the
  # default values for palette roles the example does not override.
  class Brand < UI::DesignTokens::Brand
    protected def override_color_light(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: LIGHT_PRIMARY,
        brand_primary_hover: UI::DesignTokens::Color.hex("#285B63"),
        brand_primary_active: UI::DesignTokens::Color.hex("#214E56"),
      )
    end

    protected def override_color_dark(palette : UI::DesignTokens::ColorPalette) : UI::DesignTokens::ColorPalette
      palette.copy_with(
        brand_primary: DARK_PRIMARY,
        brand_primary_hover: UI::DesignTokens::Color.hex("#B5E1DC"),
        brand_primary_active: UI::DesignTokens::Color.hex("#C3EAE5"),
      )
    end
  end

  # Appends a rounded settings section with semantic panel and tab fills.
  def self.add_settings_section(form : UI::Form, header : String) : UI::Form::FormSection
    form.add_section(
      header,
      tab_shape: UI::TabShape::Rounded,
      tab_icon: "slider.horizontal.3",
      panel_style: UI::SurfaceStyle.new(
        background_fill_color: UI::ColorRole::SurfacePanel,
      ),
      tab_style: UI::SurfaceStyle.new(
        background_fill_color: UI::ColorRole::SurfaceElevated,
      ),
    )
  end

  # Builds a Slide switch with semantic track, knob, and on colors.
  def self.build_switch(label : String, is_on : Bool = false) : UI::Toggle
    toggle = UI::Toggle.new(label, is_on)
    toggle.appearance = UI::ToggleAppearance::Slide
    toggle.track_color = UI::ColorRole::SurfaceSunken
    toggle.knob_color = UI::ColorRole::SurfaceElevated
    toggle.on_color = UI::ColorRole::BrandPrimary
    toggle
  end
end
```

Activate it on a renderer with `Tokens.default.with_brand(ExampleSkin::Brand.new)`. The sample overrides the primary family in both palettes; all other roles keep Asset Pipeline defaults.

## 5. Worked reference: `agentc_mac_ui`

The read-only local consumer at `~/agentc_coding_projects/agentc_mac_ui` is the fuller example. Its Brand uses navy `#23293A`, warm taupe surfaces/text, and brass `#DAB56E`; helper colors also distinguish light and dark appearances. Titles use Michroma; body and helper text use Fira Sans; shortcut keycaps use Fira Mono. Its fonts come from `google/fonts` commit `23e54b51ddffbc7713c583748e3bd86f62b1fa4a`; `fonts/CHECKSUMS.sha256` covers the font and OFL license files, and its checksum spec rejects missing or extra files.

Its `README.md` shows `Brand`, `register_fonts`, `add_folder_section`, `apply_screen_surface`, `build_slide_switch`, `build_keycaps`, `build_recording_color_picker`, and its button/menu helpers working together. Surface helpers take an explicit appearance because several pinned macOS controls need literal colors. The current consumer checkout is unpublished and has no Git remote; its README uses a local path dependency for the skin itself and pins Asset Pipeline to the commit above.

The reference verifies three macOS limits that are also visible in this source:

- Tab labels use a hardcoded 12-point system semibold font and have no tracking field. `FormFacade` accepts shape/style/icon arrays only; see `FormOverrides.swift:22` and `FormFacade.swift:164`.
- Tab icons use a monochrome `Image(systemName:)`; there are no separate fill/stroke color fields. See `FormFacade.swift:164`.
- The Button facade does not apply `apskSurfaceCraftSpec`, so macOS Button `InteractionFeedback::Sink` is dropped. Other supported button properties still allow a raised face, edge, and shadow. See `ButtonFacade.swift` and the `UI::View` payload at `src/ui/view.cr:793`.

A skin for the default Amber V2 app path is planned on the same separate-shard pattern. This guide does not design that skin.

## 6. Rules for a good skin

- Keep Apple controls native by default. Add brand character through explicit override knobs and reusable helpers.
- Use one accent signal per screen. Keep brass or another high-attention color for the single most important action or state.
- Keep text contrast at or above 4.5:1 against its actual background. Do not place light accent text on a light ground.
- Supply and review both light and dark palettes every time.
- Keep color decisions in tokens or skin styles/helpers. Do not hardcode colors in screen/view builders.
- Use platform dynamic label roles for ordinary Apple text unless the skin helper deliberately opts into a brand color.

## 7. Known gaps

| Gap | Verified in source | Where support belongs |
| --- | --- | --- |
| App tokens are not automatically attached to renderers. `UI::App.design_tokens` creates `app_design_tokens`; renderer instances have a separate `design_tokens` property. | `src/asset_pipeline/native_app.cr:383`, `src/ui/renderers/appkit_renderer.cr:4530`, `src/ui/renderers/web_renderer.cr:60`, `src/ui/renderers/uikit_renderer.cr:5087` | Wire `UI::App.app_design_tokens` into each host renderer during bootstrap. Until then, assign it explicitly. |
| Web compatibility `UI::Theme` CSS does not automatically follow `UI::Web::Renderer#design_tokens`. `inject_theme_css` emits the separately held `theme` (or `UI::Theme.design_system_default`); `UI::Theme.from_design_tokens` is an explicit adapter and currently derives from the light palette. | `src/ui/renderers/web_renderer.cr:35`, `src/ui/renderers/web_renderer.cr:70`, `src/ui/theme.cr:168` | Sync the legacy adapter from the active tokens and appearance, or remove its CSS block after its consumers migrate to `--ap-*`. Until then, assign `renderer.theme` explicitly for legacy CSS consumers. |
| Native surface roles do not follow the full custom palette. `SurfaceCraftModifiers.color(from:)` maps `brand-primary` to `Color.accentColor`, `brand-accent` to system teal, `warning` to system orange, and surface/text roles to AppKit system colors. `SurfaceColor` also cannot name the other 13 palette roles. | `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Modifiers/SurfaceCraftModifiers.swift:111`, `src/ui/view.cr:163` | Pass the active token colors into the native role resolver and/or expand `SurfaceColor` roles. Current skin helpers use literal `UI::Color` values selected by appearance when they need exact brand surfaces. |
| App-wide TypeScale does not automatically set each native label font. `UI::Font` is per view and has no tracking or line-height field; `token_font` is defined in the native renderers but has no call sites. Web emits type variables while its body fallback remains system UI. | `src/ui/design_tokens.cr:535`, `src/ui/view.cr:457`, `src/ui/renderers/appkit_renderer.cr:4571`, `src/ui/renderers/uikit_renderer.cr:5127`, `src/ui/renderers/web_renderer.cr:80` | Apply type steps to view defaults or add a token-aware label/font bridge; extend `Font` for tracking/line-height if those should be per-view. |
| Form tab labels cannot set font family, size, or letter spacing. The Swift facade hardcodes 12-point system semibold text; the bridge carries tab shape, icon, and styles only. | `src/ui/views/form.cr:50`, `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Overrides/FormOverrides.swift:22`, `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/FormFacade.swift:164` | Add tab typography fields to `FormSection`/`FormOverrides`, then apply them in `FormFacade`. |
| Form tab icons are monochrome SF Symbols. | `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/FormFacade.swift:164` | Add separate icon fill/stroke color inputs and a duotone rendering path to the Form tab API/facade. |
| macOS Button does not receive SurfaceCraft interaction feedback. The Crystal view serializes feedback, but `ButtonFacade` does not apply `SurfaceCraftModifiers`. | `src/ui/view.cr:793`, `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ButtonFacade.swift:81` | Preserve the surface payload and apply its feedback modifier in `ButtonFacade`. |
| Window chrome cannot take brand colors or fonts. `WindowConfiguration` controls window behavior and titlebar presentation, but not their colors or typography; toolbar material selection is not a custom color. There is no window footer-bar type. | `src/ui/windows.cr:62`, `src/ui/windows.cr:166`, `src/ui/views/toolbar.cr:26`, `src/ui/views/panel.cr:31` | Add host-level appearance properties/bridge support for window background, title bar, and toolbar; keep in-content footers as ordinary views until a window-footer contract exists. |
| Bundled font registration is macOS-only; iOS/Android return `false`. | `src/ui/font_registry.cr:11` | Add per-platform bundle registration and packaging support in the UIKit/Android host layers. |
| iOS/Android do not implement the macOS/web SurfaceCraft set; Android has no token generator and can reject a system-accent sentinel when a fixed color is required. | `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/FormFacade.swift:28`, `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/ToggleFacade.swift:111`, `src/ui/design_tokens.cr:42`, `src/ui/renderers/android_renderer.cr:3464` | Add equivalent UIKit/Android view renderers and token serialization before claiming full-skin parity on those platforms. |
| There is no generic native skin contrast checker. | `src/ui/design_tokens.cr:67` defines color values but no contrast-ratio API. The web design-system browser audit targets its own demo pages. | Keep contrast assertions in the consumer skin spec until a general token contrast tool is added under `src/ui/design_tokens/`. |

## 8. How to verify a skin

1. Run the consumer checksum spec and skin behavior specs, then run this guide's example spec:

   ```bash
   export CRYSTAL_CACHE_DIR=$PWD/.crystal-cache
   crystal-alpha spec spec/web/docs/theming_example_spec.cr
   ```

   Expected result: `3 examples, 0 failures, 0 errors, 0 pending`.

2. Build and run the native app in light and dark appearances. Capture the actual app window in each appearance:

   ```bash
   screencapture -x -o -l <window-id> skin-light.png
   screencapture -x -o -l <window-id> skin-dark.png
   ```

   Review palette, surface, control, text, focus, selection, and overflow on both captures.

3. Run behavioral accessibility checks, not only screenshots. The repo's `spec/native_macos/surface_craft_ax_spec.cr` checks tab labels/layout, ordered rows, Slide-toggle callbacks, and BezelLamp selection through AX. Its sample host must be built first; the spec reports the exact command when it is missing. The repo's Definition of Done requires existing tests and tests for new behavior to pass: `docs/initiative-cross-platform-ui/rubric/implementation_criteria.md:84`.

4. Check each real foreground/background pair in both appearances against 4.5:1. Include secondary/helper text, tab labels, selected swatches, focus indicators, and text on accent fills. The generic native skin has no built-in contrast checker at this commit, so keep the calculation in the consumer spec or a recorded review artifact.

5. For repository regression coverage, run `make test-macos ACRYSTAL=crystal-alpha` and `make test-web CRYSTAL=crystal-alpha` with the cache variable set. Report failures and pending tests separately; a screenshot or a compile alone does not establish behavior.
