
# Phase 4 — Platform Tier Gating · Implementation Brief

You are the implementer agent for phase 4 of the cross-platform UI initiative. Read this brief fully before making any code changes. The validator will check against `validation.md` in the same folder; do not read that document until you have completed your work.

---

## Goal

Formalize the Tier 1 / Tier 2 / Tier 3 contract for every UI widget in the library, gate Tier 3 widgets at compile time so they cannot accidentally compile into the wrong platform, and provide explicit `*WithWebFallback` sibling classes for the two Tier 3 widgets where a sensible web equivalent exists (`ActionSheet` and `ContextMenu`). Document the result in a new `tier-matrix.md` and update `CLAUDE.md` so future agents understand the convention.

When you are done, a Crystal program that names `UI::ActionSheet.new(...)` in a build without `-Dios` must fail with a clear, actionable compile-time error that names the iOS flag, the explicit web-fallback class, and shows an example `{% if flag?(:ios) %}` guard. A Crystal program that names `UI::ActionSheetWithWebFallback.new(...)` must build on every platform and render correctly on web via a self-contained vanilla-JS bottom sheet.

---

## Pre-reading checklist

Before touching code, read in order:

1. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/MASTER_PLAN.md` — full document; pay attention to the Tier model section.
2. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-04-platform-tier-gating/README.md` — orientation.
3. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/rubric/implementation_criteria.md` — universal implementer standards.
4. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/docs/initiative-cross-platform-ui/phases/phase-03-swiftui-native-bridge/README.md` — to understand what is already routed through SwiftUI on iOS. Tier 3 widgets in scope here render via SwiftUI on iOS (action sheets and confirmation dialogs use SwiftUI's `.confirmationDialog` modifier under the hood); your gating must not break that path.
5. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/views/` — survey every `.cr` file. There are 75 widget source files. The tier matrix below classifies them; verify the file list matches your `ls` output.
6. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/menu_bar.cr` — read the existing `{% if flag?(:darwin) %}` pattern. This is the convention you will extend.
7. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/src/ui/renderers/web_renderer.cr` lines 1097, 1163, 1191, 1424, 1457, 1630 — the existing web visitor methods for Toolbar, Popover, ConfirmationDialog, MenuButton, ContextMenu, PathControl. You will be removing or relocating the ContextMenu and PathControl visitors as part of this phase; verify what's there before you touch it.
8. `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/CLAUDE.md` — the conventions file you will update.

---

## Existing infrastructure to use (vs. rebuild)

Phase 4 is mostly a refactor + new-file phase, not a new-tool phase. The existing repo already has most of the pieces; what is genuinely new here are the three Tier 3 gate macros, the three `*WithWebFallback` companions, two vanilla-JS fallback files, the `Platform.requires` macro, and the tier matrix document.

### Crystal source you extend (do not replace)

- `src/ui/views/` — 70+ widget files already present. Confirm with `ls src/ui/views/*.cr | wc -l` before editing. Every widget you touch (`context_menu.cr`, `path_control.cr`, etc.) already has a class definition; you wrap it in `{% if flag?(...) %}`, you do not rewrite it.
- `src/ui/views/context_menu.cr` — exists. Gate it.
- `src/ui/views/path_control.cr` — exists. Gate it.
- `src/ui/views/popover.cr`, `src/ui/views/confirmation_dialog.cr`, `src/ui/views/sheet.cr`, `src/ui/views/toolbar.cr`, `src/ui/views/menu_button.cr` — exist. Leave classification to the matrix; do not gate without team-lead sign-off.
- `src/ui/views/action_sheet.cr` — **does NOT exist.** Phase 4 creates it (per the "Important finding" section). This is the only new view-class file; everything else is already on disk.
- `src/ui/menu_bar.cr` — already gates with `{% if flag?(:darwin) %}`. The pattern you mirror is here; read it before writing your own.
- `src/ui/renderers/web_renderer.cr` — large file (~1700 lines). Existing visit methods for `ContextMenu` (line 1457) and `PathControl` (line 1630) are removed/relocated by this phase. Do not delete the surrounding visitor infrastructure; keep all other visit methods unchanged.
- `src/ui/renderers/uikit_renderer.cr` — your `visit(view : UI::ActionSheet)` must route through the SwiftKit `.confirmationDialog` facade landed in Phase 3. If `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/` does not contain a `ConfirmationDialogFacade.swift` or equivalent, **stop and return early** — Phase 3 has not landed the prerequisite.
- `src/ui/renderers/appkit_renderer.cr` and `src/ui/renderers/android_renderer.cr` — extend with `visit(view : UI::ActionSheetWithWebFallback)` (and friends). The existing visit methods for `ContextMenu` and `PathControl` on these renderers must be removed because the gated classes no longer exist outside their target platforms.
- `src/components/css/tokens/` — token files. The CSS in the web fallback uses `var(--ap-color-surface-panel)`, `var(--ap-radius-panel)`, etc. Every CSS variable referenced must already be defined by Phase 1's token output. Verify with `grep "^  --ap-color-surface-panel" output/*.html` or in the generated CSS file; if a variable is missing, the Phase 1 work is incomplete.
- `src/asset_pipeline.cr` — top-level require index. Add the new `src/asset_pipeline/platform.cr` require here.

### Crystal source you create

- `src/ui/views/action_sheet.cr` — new (the un-gated shell in Commit 1, gated in Commit 4).
- `src/ui/views/action_sheet_with_web_fallback.cr` — new.
- `src/ui/views/context_menu_with_web_fallback.cr` — new.
- `src/ui/views/path_control_with_web_fallback.cr` — new.
- `src/asset_pipeline/platform.cr` — new (the `Platform.requires` macro).
- `src/ui/web/action_sheet_fallback.js` — new vanilla-JS file.
- `src/ui/web/context_menu_fallback.js` — new vanilla-JS file.
- Five spec files: `spec/ui/views/action_sheet_spec.cr`, `spec/ui/views/action_sheet_with_web_fallback_spec.cr`, `spec/ui/views/action_sheet_compile_error_spec.cr`, `spec/ui/views/context_menu_compile_error_spec.cr`, `spec/ui/views/path_control_compile_error_spec.cr`.
- `docs/initiative-cross-platform-ui/tier-matrix.md` — new document.

### Existing scripts to run (do not duplicate)

- Build verification: `crystal build --no-codegen src/asset_pipeline.cr` (default web), then with `-Dios`, `-Dmacos`, `-Dandroid`. These four invocations are the cross-target gate already documented at `rubric/implementation_criteria.md` §Testing.
- Macros sample build: `cd samples/cross_platform/macos_host && make build`; `./samples/cross_platform/ios_host/build_crystal_lib.sh simulator`.
- Spec suite: `crystal spec` from repo root. Existing test suite must remain green.
- Accessibility audits: `crystal run scripts/axe_web_demo_audit.cr` and `crystal run scripts/ibm_web_demo_audit.cr` already exist. Phase 4's web fallback validation reuses these — do not write a new axe runner.
- Screenshot capture: `crystal run scripts/capture_web_demo_screenshots.cr` (already exists). The validator runs this against the web demo with an action-sheet/context-menu test scene patched in via temporary edit. The implementer does not need to add a new capture script; the implementer only needs to ensure the existing demo (`examples/web_design_system_demo.cr`) can render the new fallbacks when authored to do so.

### Test infrastructure you reuse

- `spec/spec_helper.cr` — auto-requires support files; the compile-error spec helper template in Commit 10 is a private helper inside each compile-error spec file, not a shared support module (preserves the "no shared global counter across unrelated specs" property).
- `spec/ui/renderers/web_renderer_spec.cr` — existing file for rendered-HTML assertions. The HTML-structure specs (`fallback.web-html-action-sheet-structure`, `fallback.web-html-context-menu-structure`) extend this file. Do not create a new renderer spec file.
- The `Atomic(Int32)` counter pattern shown in Commit 10 is the canonical concurrency-safe approach for tempfile naming in this codebase; use it as-is.

### Pinned versions and environment

| Tool | Version | Notes |
|---|---|---|
| Crystal compiler | `crystal-alpha` (`/opt/homebrew/bin/crystal-alpha`) | The compile-error spec invocation must be `crystal build --no-codegen <tempfile>`, not `crystal-alpha`, so that the spec runs against whatever Crystal compiler the spec runner uses. Confirm `which crystal` resolves to `crystal-alpha` (or symlink) before running the compile-error specs. |
| Browser MCP | already loaded via `ToolSearch` | Used by validator for focus-trap and axe runs. |
| axe-core | whatever `scripts/axe_web_demo_audit.cr` pins | Do not bump versions in this phase. |

### Conventions enforced project-wide

- **`{% if flag?(:darwin) %}`** is the existing project convention for "Apple-family." Use it for `ContextMenu` because the widget works on both iOS and macOS. Use `{% if flag?(:ios) %}` or `{% if flag?(:macos) %}` for the strictly single-OS widgets.
- **`{% raise %}`** inside the `{% else %}` branch is **compile-time** raising. The string argument may be a HEREDOC; multi-line is supported.
- **CSS prefix:** `--ap-*` is the canonical prefix for new emissions in this initiative. `--amber-*` aliases may exist as deprecated re-exports from Phase 1 but **must not be referenced** in new Phase 4 CSS or fallback JS. The validator enforces this with a grep (`fallback.css-uses-ap-prefix`).
- **JS budget:** each vanilla-JS fallback ≤ 200 lines. No `import`, no `require`, no CDN. Self-contained IIFE that registers once per page (idempotent — observe `__apActionSheetInitialized` and `__apContextMenuInitialized` flags). Honor the existing `register_once` pattern in `web_renderer.cr`.
- **`MutationObserver` scoping:** the brief (and the prior audit) flags `observe(document.documentElement, { subtree: true })` as a real perf concern on large pages. Scope the observer to the specific `.ap-action-sheet` / `.ap-ctx-menu` roots, not to the document root, **unless** the renderer's re-render pattern forces document-wide observation. If document-wide is required, narrow `attributeFilter` to the smallest possible set and document the choice in a code comment.

### What is genuinely new vs. extended

| New | Extended |
|---|---|
| `src/ui/views/action_sheet.cr` | `src/ui/renderers/web_renderer.cr` (remove old ContextMenu / PathControl visitors; add fallback visitors) |
| `src/ui/views/*_with_web_fallback.cr` × 3 | `src/ui/renderers/uikit_renderer.cr` (add ActionSheet visitor) |
| `src/ui/web/*_fallback.js` × 2 | `src/ui/renderers/appkit_renderer.cr` / `android_renderer.cr` (add fallback visitors; remove gated class visitors) |
| `src/asset_pipeline/platform.cr` | `src/ui/menu_bar.cr` (wrap ContextMenu reference) |
| `docs/initiative-cross-platform-ui/tier-matrix.md` | `src/asset_pipeline.cr`, `CLAUDE.md`, `README.md` |
| `spec/ui/views/*_compile_error_spec.cr` × 3 | `spec/ui/renderers/web_renderer_spec.cr` |
| `spec/asset_pipeline/platform_spec.cr` | `src/ui/views/context_menu.cr`, `src/ui/views/path_control.cr` (add gate macros) |

If you find yourself about to create a file not on the "New" list, stop and confirm with the team lead.

---

## Important finding from pre-implementation audit

**`ActionSheet` does not exist as a source file.** `src/ui/views/action_sheet.cr` is absent. The Phase 4 README treats it as the canonical Tier 3 widget, but on web today its job is being approximated by `ConfirmationDialog` + `Sheet`. Before you can gate `ActionSheet`, you must create it.

This is **in scope** for phase 4. Do not return early citing the missing class. The implementer is expected to:

1. Create `src/ui/views/action_sheet.cr` with the class shape sketched in step 1 below.
2. Wire it through `src/ui/views.cr` and the four renderers (`web_renderer.cr`, `uikit_renderer.cr`, `appkit_renderer.cr`, `android_renderer.cr`). On iOS the implementation must route through the SwiftUI bridge from phase 3; on macOS, web, and Android the un-gated default class must produce a compile error (those platforms have no native action sheet), with the explicit `ActionSheetWithWebFallback` available for web.
3. Then apply the Tier 3 gate per step 2 below.

Similarly, **`HapticFeedback`** is referenced by the README as a Tier 3 widget but no file currently exists. It is not in scope for phase 4 — leave it for a future phase. Note it in your handoff "Known concerns" section.

**`MenuBarExtra`** likewise does not exist as a separate widget; the existing `src/ui/menu_bar.cr` covers macOS menu-bar installation and is already gated. No new class is required.

---

## Tier classification deliverable

You will produce a new file `docs/initiative-cross-platform-ui/tier-matrix.md` containing the table below. Every widget in `src/ui/views/` must appear in this matrix with an assigned tier. The table that follows is the proposed classification; reconcile it against the actual filesystem state before publishing.

### Proposed classification

The 75 widgets currently in `src/ui/views/`, organized by tier. **Italicized** entries are the ones I am least confident about; resolve uncertainty by raising the question with the team lead before committing the matrix.

#### Tier 1 — Brand-universal (renders identically modulo platform unit conventions)

These have no platform-idiomatic chrome — they are visual primitives or layout. They live in `src/ui/views/` and require no gating.

- `capsule.cr`
- `card.cr`
- `circle.cr`
- `column_view.cr`
- `confirmation_dialog.cr` *(generic modal; ActionSheetWithWebFallback delegates here on web)*
- `divider.cr`
- `grid.cr`
- `hstack.cr`
- `icon_button.cr`
- `image.cr`
- `label.cr`
- `link_button.cr`
- `panel.cr`
- `path_view.cr` *(SVG path data; universal)*
- `rectangle.cr`
- `rounded_rectangle.cr`
- `snackbar.cr`
- `spacer.cr`
- `surface.cr`
- `vstack.cr`
- `zstack.cr`

#### Tier 2 — Platform default (universal API; platform renderer picks idiomatic widget)

These have a meaningful semantic on every platform; their visual treatment shifts based on the renderer. No gating; phase 3's SwiftUI bridge gives them their Apple polish.

- `activity_indicator.cr`
- `activity_ring.cr`
- `activity_rings.cr`
- `activity_view.cr` *(shares; Apple uses UIActivityViewController, web uses share API or copy-link; reasonable everywhere)*
- `alert.cr`
- `async_image.cr`
- `button.cr`
- `canvas.cr`
- `chart_view.cr`
- `checkbox.cr`
- `color_picker.cr` *(uses `<input type="color">` on web — the native picker is Tier 2 polish, not a Tier 3 gate)*
- `combo_box.cr`
- `date_picker.cr` *(uses `<input type="date">` on web; SwiftUI `DatePicker` on Apple)*
- `disclosure_group.cr`
- `form.cr`
- `gauge.cr`
- `glass_background.cr` *(degrades to standard backdrop on platforms without glass material)*
- `image_well.cr`
- `list_view.cr`
- `map_view.cr` *(MapKit on Apple, Leaflet/Google embed on web; not Tier 3 because every platform has a map)*
- `menu_button.cr` *(pop-up / pull-down; renders on every platform)*
- `navigation_link.cr`
- `navigation_split_view.cr`
- `navigation_stack.cr`
- `outline_view.cr`
- `page_control.cr`
- `picker.cr`
- `popover.cr` *(positioned floating panel; arrow chrome is Apple polish, structure is universal)*
- `progress_view.cr`
- `radio_group.cr`
- `rating_indicator.cr`
- `rich_text.cr`
- `scroll_view.cr`
- `search_field.cr`
- `secure_field.cr`
- `segmented_control.cr`
- `sheet.cr` *(bottom sheet / modal sheet)*
- `slider.cr`
- `stepper.cr`
- `tab_view.cr`
- `text_area.cr`
- `text_editor.cr`
- `text_field.cr`
- `time_picker.cr` *(uses `<input type="time">` on web)*
- `toggle.cr`
- `toggle_button.cr`
- `token_field.cr`
- `tooltip.cr`
- `toolbar.cr` *(see "Open questions" below)*
- `video_player.cr`
- `web_view.cr`

#### Tier 3 — Platform-only (compile-time gated)

These have **no honest cross-platform analog**. Building them without the right `-D` flag is a compile error. An explicit `*WithWebFallback` sibling class is provided when a credible web equivalent exists.

| Widget | Required flag | Has WithWebFallback? | Notes |
|---|---|---|---|
| `action_sheet.cr` *(to be created)* | `:ios` | **Yes** — `ActionSheetWithWebFallback` | iOS-only; SwiftUI `.confirmationDialog` (sheet style) on iOS, vanilla-JS bottom sheet on web. macOS users should use `ConfirmationDialog` directly. |
| `context_menu.cr` | `:darwin` (covers iOS + macOS) | **Yes** — `ContextMenuWithWebFallback` | Right-click / long-press menu; vanilla-JS positioned dropdown on web. |
| `path_control.cr` | `:macos` | **Yes** *(optional, recommended)* — `PathControlWithWebFallback` | NSPathControl is macOS-only. Web fallback renders a `<nav aria-label="Breadcrumb">` with an ordered list. The existing breadcrumb-style web visitor moves into the fallback class. |

#### Open questions to resolve with the team lead before publishing the matrix

- **`Toolbar`** — the phase 4 README classifies Apple-style NSToolbar/UIBarButtonItem-style toolbars as Tier 3 distinct from "the web Toolbar concept" as Tier 1. The existing `src/ui/views/toolbar.cr` is one class with one visitor that renders adequately on every platform. I have placed it in Tier 2 above. Two paths forward:
  - **(a)** Leave as Tier 2. The existing class is the cross-platform toolbar. If a future feature needs NSToolbar's pill-shaped customization UI, introduce a new Tier 3 `PlatformToolbar` class then.
  - **(b)** Rename the existing class to `PlatformToolbar`, gate Tier 3, and introduce a new Tier 1 `Toolbar` that's just a flex row. This is a breaking API change.
  - **Recommended: (a).** Ask the team lead to confirm before publishing.
- **`Popover`** — the existing class renders on web with a positioned div; arrow chrome is an Apple polish item. Currently classified Tier 2. If the team lead wants Apple-only popover semantics (NSPopover detach behavior, etc.) gated, this would move to Tier 3 with a fallback. Recommended: keep Tier 2; revisit if Phase 6 demo screens hit a behavioral mismatch.
- **`MenuButton`** — pop-up vs. pull-down semantics work on web. Classified Tier 2. Could be argued Tier 3 (the Apple chevron convention is idiomatic) — but the web rendering is adequate and the existing visitor honors `is_pull_down`. Recommended: keep Tier 2.

If you encounter any widget in `src/ui/views/` that is not classified above, do not guess. List it under "Unclassified" in your handoff message and let the team lead adjudicate.

---

## Compile-time guard mechanism

Tier 3 widget files use Crystal's `{% if flag?(...) %}` macro at module-load time to either define the class (on supported platforms) or raise a `{% raise %}` compile error (on unsupported platforms).

The `{% raise %}` message is the developer-facing contract for the gate. It must contain:

1. The widget name.
2. The required platform flag (e.g., `-Dios`).
3. The name of the explicit `*WithWebFallback` class if one exists, or "no fallback available" if not.
4. A minimal `{% if flag?(:ios) %}` example showing how to guard usage in application code.

### Before / after — `ActionSheet`

**Before** (after step 1 below creates the class):

```crystal
# src/ui/views/action_sheet.cr
require "../view"

module UI
  class ActionSheet < View
    record Action,
      label : String,
      style : Symbol = :default, # :default | :destructive | :cancel
      action : Proc(Nil)? = nil

    property title : String = ""
    property message : String = ""
    property actions : Array(Action) = [] of Action
    property is_presented : Bool = false

    def initialize(@title : String = "", @message : String = "")
    end

    def add_action(label : String, style : Symbol = :default, &block : -> Nil)
      @actions << Action.new(label: label, style: style, action: block)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
```

**After** — gated:

```crystal
# src/ui/views/action_sheet.cr
require "../view"

{% if flag?(:ios) %}
  module UI
    # Tier 3 — iOS-only. Use ActionSheetWithWebFallback to render on web.
    #
    # Builds with `-Dios`. On every other platform, naming this class is a
    # compile-time error (see the macro below).
    class ActionSheet < View
      record Action,
        label : String,
        style : Symbol = :default, # :default | :destructive | :cancel
        action : Proc(Nil)? = nil

      property title : String = ""
      property message : String = ""
      property actions : Array(Action) = [] of Action
      property is_presented : Bool = false

      def initialize(@title : String = "", @message : String = "")
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    end
  end
{% else %}
  module UI
    # Compile-time stub for `ActionSheet` on non-iOS targets.
    #
    # Naming this class at all (e.g., `UI::ActionSheet.new`) triggers the
    # `{% raise %}` below at compile time with an actionable message.
    class ActionSheet
      {% raise <<-MSG
        UI::ActionSheet is iOS-only (Tier 3). This build does not have `-Dios`.

        Pick one:

        1. Build with -Dios:
             crystal build my_app.cr -Dios

        2. Use the explicit web-fallback class instead:
             UI::ActionSheetWithWebFallback.new(...)
           which renders a native iOS action sheet on -Dios and an
           accessible vanilla-JS bottom sheet on web.

        3. Guard the usage at the call site:
             {% if flag?(:ios) %}
               sheet = UI::ActionSheet.new("Title", "Message")
               # ...
             {% else %}
               # alternate UI for this platform
             {% end %}

        See docs/initiative-cross-platform-ui/tier-matrix.md for the full
        tier classification and which widgets require which flags.
        MSG
      %}
    end
  end
{% end %}
```

The same pattern applies to `context_menu.cr` (flag `:darwin`) and `path_control.cr` (flag `:macos`). The `{% raise %}` message is widget-specific; the structure is identical.

### Notes on the macro

- **HEREDOC for the message** keeps the multi-line `MSG` readable. Crystal's `{% raise %}` accepts any string expression at compile time.
- **The stub class body contains only the raise.** No properties, no methods. This is intentional — any other code in the stub class would itself compile in non-ios builds and produce confusing secondary errors.
- **The `require` at the top is unconditional.** The `View` superclass is universal. Only the `ActionSheet` class definition is conditional.
- **Do not guard the visitor methods** the same way. The `web_renderer.cr` and `appkit_renderer.cr` `visit(view : UI::ActionSheet)` methods should simply not exist after this phase. The `uikit_renderer.cr` `visit(view : UI::ActionSheet)` method is the only one that compiles, because the class itself is only defined when `flag?(:ios)`.

---

## `*WithWebFallback` pattern

Crystal cannot define two classes with the same name in different files, and the macro above means `UI::ActionSheet` is undefined on non-iOS builds. The `WithWebFallback` sibling is therefore a **separate class** that:

- On supported platforms: holds a `UI::ActionSheet` instance and delegates `accept(visitor)` to it. The visitor still gets the real Tier 3 widget.
- On unsupported platforms: holds its own state (title, message, actions) and renders the web fallback directly.

Both branches expose the same public API surface (`add_action`, `title=`, `is_presented=`, etc.) so application code that uses the fallback class is portable.

### Contract

```crystal
# src/ui/views/action_sheet_with_web_fallback.cr
require "../view"
{% if flag?(:ios) %}
  require "./action_sheet"
{% end %}

module UI
  # Cross-platform companion to the iOS-only `ActionSheet`. Use this class
  # whenever you want an action-sheet UX that works on web too.
  #
  # On `-Dios`: delegates to UI::ActionSheet (native iOS action sheet via
  # the SwiftUI bridge).
  # On any other platform: renders a vanilla-JS bottom-sheet on web,
  # falls back to ConfirmationDialog semantics on macOS/Android.
  class ActionSheetWithWebFallback < View
    record Action,
      label : String,
      style : Symbol = :default,
      action : Proc(Nil)? = nil

    property title : String = ""
    property message : String = ""
    property actions : Array(Action) = [] of Action
    property is_presented : Bool = false

    {% if flag?(:ios) %}
      @inner : UI::ActionSheet

      def initialize(@title : String = "", @message : String = "")
        @inner = UI::ActionSheet.new(@title, @message)
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
        @inner.add_action(label, style, &block)
      end

      def accept(visitor : PlatformVisitor)
        @inner.title = @title
        @inner.message = @message
        @inner.is_presented = @is_presented
        @inner.accept(visitor)
      end
    {% else %}
      def initialize(@title : String = "", @message : String = "")
      end

      def add_action(label : String, style : Symbol = :default, &block : -> Nil)
        @actions << Action.new(label: label, style: style, action: block)
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    {% end %}
  end
end
```

The visitor methods then split cleanly:

- `uikit_renderer.cr` only ever sees `UI::ActionSheet` (because the fallback delegates).
- `web_renderer.cr` only ever sees `UI::ActionSheetWithWebFallback` (its `visit` method generates the bottom-sheet HTML+JS).
- `appkit_renderer.cr` and `android_renderer.cr` see `UI::ActionSheetWithWebFallback` only; they render it as a styled modal (delegating to whatever `ConfirmationDialog`'s visitor produces).

`ContextMenuWithWebFallback` follows the same pattern, gated on `flag?(:darwin)` (since both iOS and macOS have a native ContextMenu).

`PathControlWithWebFallback` follows the same pattern, gated on `flag?(:macos)`.

---

## Web fallback implementations

The library is no-npm, no-bundler. JS is vanilla, self-contained, and inlined into the rendered HTML as a `<script>` block (or registered once per page). Keep each fallback's JS under 200 lines.

### `ActionSheet` web fallback — bottom sheet

The web visitor for `UI::ActionSheetWithWebFallback` renders a structure equivalent to:

```html
<div class="ap-action-sheet"
     role="dialog"
     aria-modal="true"
     aria-labelledby="ap-as-title-{id}"
     aria-describedby="ap-as-msg-{id}"
     data-presented="{true|false}"
     data-testid="...">
  <div class="ap-action-sheet__backdrop" data-ap-as-dismiss="backdrop"></div>
  <div class="ap-action-sheet__panel" role="document" tabindex="-1">
    <div class="ap-action-sheet__handle" aria-hidden="true"></div>
    <h2 id="ap-as-title-{id}" class="ap-action-sheet__title">{title}</h2>
    <p  id="ap-as-msg-{id}"   class="ap-action-sheet__message">{message}</p>
    <ul class="ap-action-sheet__actions" role="group">
      <li>
        <button type="button"
                class="ap-action-sheet__action ap-action-sheet__action--default"
                data-ap-as-action="0">{label}</button>
      </li>
      <!-- destructive style adds class ap-action-sheet__action--destructive -->
      <!-- cancel style is rendered separately, styled distinct, last in DOM -->
    </ul>
    <button type="button"
            class="ap-action-sheet__action ap-action-sheet__action--cancel"
            data-ap-as-dismiss="cancel">Cancel</button>
  </div>
</div>
```

CSS (inline into the visitor output via `add_style` calls; this is the existing convention in `web_renderer.cr`):

```css
/* Backdrop */
.ap-action-sheet { position: fixed; inset: 0; z-index: 1000; display: none; }
.ap-action-sheet[data-presented="true"] { display: block; }
.ap-action-sheet__backdrop {
  position: absolute; inset: 0;
  background: oklch(0.18 0.02 248 / 0.42);
}

/* Panel — slides up from the bottom on mobile, centers on desktop */
.ap-action-sheet__panel {
  position: absolute; left: 0; right: 0; bottom: 0;
  background: var(--ap-color-surface-panel);
  color: var(--ap-color-text-primary);
  border-radius: var(--ap-radius-panel) var(--ap-radius-panel) 0 0;
  padding: 12px 16px env(safe-area-inset-bottom);
  box-shadow: var(--ap-elevation-overlay);
  transform: translateY(0);
  transition: transform var(--ap-motion-duration-base) var(--ap-motion-ease-standard);
  outline: none;
  max-height: 80vh;
  overflow-y: auto;
}
.ap-action-sheet[data-presented="false"] .ap-action-sheet__panel {
  transform: translateY(100%);
}

/* Handle — visual affordance for "this is a sheet, you can swipe it" */
.ap-action-sheet__handle {
  width: 36px; height: 5px;
  background: var(--ap-color-border-default);
  border-radius: var(--ap-radius-pill);
  margin: 0 auto 12px;
}

/* Desktop: center the panel rather than dock to bottom */
@media (min-width: 768px) {
  .ap-action-sheet__panel {
    left: 50%; right: auto; bottom: 50%;
    transform: translate(-50%, 50%);
    max-width: 420px; width: 90vw;
    border-radius: var(--ap-radius-panel);
  }
  .ap-action-sheet[data-presented="false"] .ap-action-sheet__panel {
    transform: translate(-50%, 50%) scale(0.96);
    opacity: 0;
  }
  .ap-action-sheet__handle { display: none; }
}

.ap-action-sheet__title   { font-size: 17px; font-weight: 600; text-align: center; margin: 0 0 4px; }
.ap-action-sheet__message { font-size: 13px; color: var(--ap-color-text-secondary); text-align: center; margin: 0 0 16px; }
.ap-action-sheet__actions { list-style: none; padding: 0; margin: 0 0 8px; display: flex; flex-direction: column; gap: 8px; }
.ap-action-sheet__action {
  width: 100%;
  padding: 12px 16px;
  border: none; border-radius: var(--ap-radius-control);
  background: var(--ap-color-surface-sunken);
  color: var(--ap-color-brand-accent);
  font-size: 17px;
  cursor: pointer;
  min-height: 44px; /* touch target */
}
.ap-action-sheet__action:focus-visible {
  outline: 2px solid var(--ap-color-focus-ring);
  outline-offset: 2px;
}
.ap-action-sheet__action--destructive { color: var(--ap-color-danger-text); }
.ap-action-sheet__action--cancel {
  background: var(--ap-color-surface-panel);
  font-weight: 600;
  margin-top: 4px;
  border: 1px solid var(--ap-color-border-default);
}
```

JS (`src/ui/web/action_sheet_fallback.js`, registered once per page via the existing asset pipeline; under 200 lines):

```js
// Vanilla-JS bottom-sheet behavior for UI::ActionSheetWithWebFallback.
// Pure DOM; no framework. Idempotent — safe to call init() multiple times.
//
// Behaviors:
//   * Backdrop click dismisses (treated as Cancel)
//   * Escape key dismisses (treated as Cancel)
//   * Focus trap inside the panel while presented
//   * On show: previously focused element saved; first action button focused
//   * On dismiss: focus returned to the previously focused element
//   * Optional swipe-down to dismiss on touch devices
//
// Contract with Crystal:
//   * Crystal renders <div class="ap-action-sheet" data-presented="true|false">
//   * Application code toggles data-presented to show/hide
//   * Action clicks dispatch a CustomEvent("ap:action-sheet:action",
//     { detail: { index, label } }) on the root div; Crystal-side listeners
//     wire to the recorded Proc.
//   * Dismiss dispatches CustomEvent("ap:action-sheet:dismiss").

(function () {
  if (window.__apActionSheetInitialized) return;
  window.__apActionSheetInitialized = true;

  const FOCUSABLE =
    'a[href],button:not([disabled]),input:not([disabled]),' +
    'select:not([disabled]),textarea:not([disabled]),[tabindex]:not([tabindex="-1"])';

  const state = new WeakMap();

  function focusables(panel) {
    return Array.from(panel.querySelectorAll(FOCUSABLE)).filter(el =>
      el.offsetParent !== null || el === document.activeElement
    );
  }

  function trapFocus(e, root) {
    if (e.key !== 'Tab') return;
    const panel = root.querySelector('.ap-action-sheet__panel');
    const els = focusables(panel);
    if (els.length === 0) { e.preventDefault(); panel.focus(); return; }
    const first = els[0], last = els[els.length - 1];
    if (e.shiftKey && document.activeElement === first) {
      e.preventDefault(); last.focus();
    } else if (!e.shiftKey && document.activeElement === last) {
      e.preventDefault(); first.focus();
    }
  }

  function show(root) {
    const s = state.get(root) || {};
    s.previouslyFocused = document.activeElement;
    state.set(root, s);
    const panel = root.querySelector('.ap-action-sheet__panel');
    const first = focusables(panel)[0] || panel;
    requestAnimationFrame(() => first.focus());
  }

  function hide(root, reason) {
    const s = state.get(root);
    root.setAttribute('data-presented', 'false');
    root.dispatchEvent(new CustomEvent('ap:action-sheet:dismiss', { detail: { reason } }));
    if (s && s.previouslyFocused && s.previouslyFocused.focus) {
      s.previouslyFocused.focus();
    }
  }

  function attach(root) {
    if (root.__apBound) return;
    root.__apBound = true;

    root.addEventListener('click', e => {
      const dismiss = e.target.closest('[data-ap-as-dismiss]');
      if (dismiss) { e.preventDefault(); hide(root, dismiss.dataset.apAsDismiss); return; }
      const action = e.target.closest('[data-ap-as-action]');
      if (action) {
        e.preventDefault();
        const index = parseInt(action.dataset.apAsAction, 10);
        root.dispatchEvent(new CustomEvent('ap:action-sheet:action', {
          detail: { index, label: action.textContent.trim() }
        }));
        hide(root, 'action');
      }
    });

    root.addEventListener('keydown', e => {
      if (e.key === 'Escape') { e.preventDefault(); hide(root, 'escape'); return; }
      trapFocus(e, root);
    });

    // Optional: swipe-down on the panel handle to dismiss
    const handle = root.querySelector('.ap-action-sheet__handle');
    if (handle && 'ontouchstart' in window) {
      let startY = null;
      handle.addEventListener('touchstart', e => { startY = e.touches[0].clientY; }, { passive: true });
      handle.addEventListener('touchmove', e => {
        if (startY === null) return;
        const dy = e.touches[0].clientY - startY;
        if (dy > 48) { hide(root, 'swipe'); startY = null; }
      }, { passive: true });
    }

    // Observe presentation toggles so we run the show() bookkeeping.
    new MutationObserver(records => {
      for (const r of records) {
        if (r.attributeName === 'data-presented' &&
            root.getAttribute('data-presented') === 'true') {
          show(root);
        }
      }
    }).observe(root, { attributes: true, attributeFilter: ['data-presented'] });

    if (root.getAttribute('data-presented') === 'true') show(root);
  }

  function init() {
    document.querySelectorAll('.ap-action-sheet').forEach(attach);
  }

  if (document.readyState !== 'loading') init();
  else document.addEventListener('DOMContentLoaded', init);

  // Re-bind when new sheets are inserted (Crystal re-renders).
  new MutationObserver(init).observe(document.documentElement, { childList: true, subtree: true });
})();
```

### `ContextMenu` web fallback — positioned dropdown

The web visitor for `UI::ContextMenuWithWebFallback` renders:

```html
<div class="ap-ctx-menu-host" data-ap-ctx-host>
  <!-- Trigger (the element the developer wired contextmenu/long-press to)
       lives as the child of the host. Crystal does NOT inject the trigger;
       the developer wires it via the parent view. The host attribute is
       what the JS hooks. -->
  <ul class="ap-ctx-menu"
      role="menu"
      aria-labelledby="..."
      data-presented="false"
      data-testid="...">
    <li role="none">
      <button type="button"
              role="menuitem"
              class="ap-ctx-menu__item"
              data-ap-ctx-action="0">{label}</button>
    </li>
    <li role="separator" class="ap-ctx-menu__separator"></li>
    <li role="none">
      <button type="button"
              role="menuitem"
              class="ap-ctx-menu__item ap-ctx-menu__item--destructive"
              data-ap-ctx-action="2">{label}</button>
    </li>
  </ul>
</div>
```

CSS:

```css
.ap-ctx-menu-host { position: relative; display: contents; }
.ap-ctx-menu {
  position: fixed; /* positioned imperatively by JS */
  list-style: none; margin: 0; padding: 4px;
  min-width: 200px;
  background: var(--ap-color-surface-panel);
  color: var(--ap-color-text-primary);
  border: 1px solid var(--ap-color-border-subtle);
  border-radius: var(--ap-radius-card);
  box-shadow: var(--ap-elevation-floating);
  z-index: 900;
  display: none;
}
.ap-ctx-menu[data-presented="true"] { display: block; }
.ap-ctx-menu__item {
  display: flex; align-items: center; gap: 8px;
  width: 100%;
  min-height: 32px; padding: 0 12px;
  background: transparent; border: none;
  color: inherit; font: inherit;
  text-align: left; cursor: pointer;
  border-radius: 6px;
}
.ap-ctx-menu__item:hover,
.ap-ctx-menu__item:focus-visible {
  background: var(--ap-color-surface-hover);
  outline: none;
}
.ap-ctx-menu__item--destructive { color: var(--ap-color-danger-text); }
.ap-ctx-menu__item[aria-disabled="true"] {
  color: var(--ap-color-text-muted);
  cursor: not-allowed;
}
.ap-ctx-menu__separator {
  height: 1px;
  margin: 4px 0;
  background: var(--ap-color-border-subtle);
}
```

JS (`src/ui/web/context_menu_fallback.js`; under 200 lines):

```js
// Vanilla-JS context-menu behavior for UI::ContextMenuWithWebFallback.
// Pure DOM; no framework.
//
// Behaviors:
//   * Trigger element opens menu on contextmenu (right-click) and long-press
//   * Menu positions itself near the trigger, flips when near viewport edge
//   * Arrow keys move focus between menuitems
//   * Home/End jump to first/last
//   * Escape closes; focus returns to trigger
//   * Click outside dismisses
//   * Enter/Space activates the focused item
//   * Disabled items are skipped by keyboard nav and not clickable

(function () {
  if (window.__apContextMenuInitialized) return;
  window.__apContextMenuInitialized = true;

  function itemsOf(menu) {
    return Array.from(menu.querySelectorAll('.ap-ctx-menu__item:not([aria-disabled="true"])'));
  }

  function position(menu, x, y) {
    menu.setAttribute('data-presented', 'true');
    const r = menu.getBoundingClientRect();
    const vw = window.innerWidth, vh = window.innerHeight;
    const left = (x + r.width  > vw) ? Math.max(0, vw - r.width  - 8) : x;
    const top  = (y + r.height > vh) ? Math.max(0, vh - r.height - 8) : y;
    menu.style.left = left + 'px';
    menu.style.top  = top  + 'px';
  }

  function open(host, x, y) {
    const menu = host.querySelector('.ap-ctx-menu');
    if (!menu) return;
    host.__previouslyFocused = document.activeElement;
    position(menu, x, y);
    const first = itemsOf(menu)[0];
    if (first) first.focus();
  }

  function close(host, reason) {
    const menu = host.querySelector('.ap-ctx-menu');
    if (!menu) return;
    menu.setAttribute('data-presented', 'false');
    host.dispatchEvent(new CustomEvent('ap:ctx-menu:dismiss', { detail: { reason } }));
    if (host.__previouslyFocused && host.__previouslyFocused.focus) {
      host.__previouslyFocused.focus();
    }
  }

  function moveFocus(menu, dir) {
    const items = itemsOf(menu);
    if (items.length === 0) return;
    const i = items.indexOf(document.activeElement);
    let next;
    if (dir === 'first') next = 0;
    else if (dir === 'last') next = items.length - 1;
    else if (dir === 'next') next = i < 0 ? 0 : (i + 1) % items.length;
    else if (dir === 'prev') next = i < 0 ? items.length - 1 : (i - 1 + items.length) % items.length;
    items[next].focus();
  }

  function attach(host) {
    if (host.__apBound) return;
    host.__apBound = true;

    // The trigger is the host's first non-menu child element.
    const trigger = Array.from(host.children).find(el => !el.classList.contains('ap-ctx-menu'));
    if (!trigger) return;

    trigger.addEventListener('contextmenu', e => {
      e.preventDefault();
      open(host, e.clientX, e.clientY);
    });

    // Long-press on touch
    let pressTimer = null;
    trigger.addEventListener('touchstart', e => {
      if (e.touches.length !== 1) return;
      const t = e.touches[0];
      pressTimer = setTimeout(() => open(host, t.clientX, t.clientY), 500);
    }, { passive: true });
    ['touchend', 'touchmove', 'touchcancel'].forEach(ev =>
      trigger.addEventListener(ev, () => clearTimeout(pressTimer), { passive: true }));

    const menu = host.querySelector('.ap-ctx-menu');
    if (!menu) return;

    menu.addEventListener('click', e => {
      const item = e.target.closest('.ap-ctx-menu__item');
      if (!item || item.getAttribute('aria-disabled') === 'true') return;
      const index = parseInt(item.dataset.apCtxAction, 10);
      host.dispatchEvent(new CustomEvent('ap:ctx-menu:action', {
        detail: { index, label: item.textContent.trim() }
      }));
      close(host, 'action');
    });

    menu.addEventListener('keydown', e => {
      switch (e.key) {
        case 'Escape':    e.preventDefault(); close(host, 'escape'); break;
        case 'ArrowDown': e.preventDefault(); moveFocus(menu, 'next'); break;
        case 'ArrowUp':   e.preventDefault(); moveFocus(menu, 'prev'); break;
        case 'Home':      e.preventDefault(); moveFocus(menu, 'first'); break;
        case 'End':       e.preventDefault(); moveFocus(menu, 'last');  break;
        case 'Enter':
        case ' ':         e.preventDefault(); document.activeElement.click(); break;
      }
    });

    document.addEventListener('click', e => {
      if (menu.getAttribute('data-presented') !== 'true') return;
      if (host.contains(e.target)) return;
      close(host, 'outside');
    });
  }

  function init() { document.querySelectorAll('[data-ap-ctx-host]').forEach(attach); }
  if (document.readyState !== 'loading') init(); else document.addEventListener('DOMContentLoaded', init);
  new MutationObserver(init).observe(document.documentElement, { childList: true, subtree: true });
})();
```

These two JS files together total well under the 200-line budget per fallback and have no external dependencies.

---

## `Platform.requires(:ios)` helper

App authors who write platform-only logic (not platform-only widgets) need a way to express "this block only compiles on iOS" without learning Crystal macro syntax themselves. Provide a one-liner helper:

```crystal
# src/asset_pipeline/platform.cr  (new file)
module AssetPipeline
  module Platform
    # Compile-time platform gate. Use this in application code to assert
    # that a block is only entered on a specific platform target. If the
    # build does not have the matching `-D` flag, the macro raises a
    # compile error naming the missing flag.
    #
    # Example:
    #   AssetPipeline::Platform.requires(:ios) do
    #     trigger_haptic
    #   end
    #
    # On non-iOS builds, this raises:
    #   "AssetPipeline::Platform.requires(:ios) — this code path needs -Dios."
    macro requires(platform_flag)
      {% if flag?(platform_flag.id) %}
        {{ yield }}
      {% else %}
        {% raise "AssetPipeline::Platform.requires(:#{platform_flag.id}) — this code path needs -D#{platform_flag.id}. Either build with that flag, or guard with `{% if flag?(:#{platform_flag.id}) %}` and provide an else-branch." %}
      {% end %}
    end

    # Compile-time platform predicate. Use in `{% if Platform.has?(:ios) %}`
    # contexts when the macro form above is more verbose than needed.
    macro has?(platform_flag)
      {% if flag?(platform_flag.id) %} true {% else %} false {% end %}
    end
  end
end
```

This is **for app code only**. Library code (anything under `src/ui/views/`, `src/ui/renderers/`) continues to use raw `{% if flag?(:ios) %}` blocks.

---

## `tier-matrix.md` template

Location: `docs/initiative-cross-platform-ui/tier-matrix.md` (sibling to `MASTER_PLAN.md`).

Outline:

```markdown
# Tier Matrix — Cross-Platform UI

This document classifies every widget in `src/ui/views/` into Tier 1
(Brand), Tier 2 (Platform Default), or Tier 3 (Platform-Only). It is the
canonical source for the tier classification; the Phase 4 implementer
populated it from the proposal in `phases/phase-04-platform-tier-gating/
implementation.md`.

See the Tier model section of `MASTER_PLAN.md` for the definitions.

## How to use this matrix

* New widget? Pick a tier and add it here in the same commit that adds
  the source file. Unclassified widgets are a build-time TODO.
* Tier 3 widget needs a fallback? Add a `*WithWebFallback` row.
* Found a widget here that isn't in `src/ui/views/`? File a bug — the
  matrix is stale.

## Tier 1 — Brand-universal

| Widget | Source file | Notes |
|---|---|---|
| Capsule | `src/ui/views/capsule.cr` | |
| Card | `src/ui/views/card.cr` | |
| ... | ... | |

## Tier 2 — Platform default

| Widget | Source file | Required SwiftUI facade (phase 3) | Notes |
|---|---|---|---|
| Button | `src/ui/views/button.cr` | Yes | |
| ColorPicker | `src/ui/views/color_picker.cr` | Yes | Uses `<input type="color">` on web. |
| ... | ... | ... | ... |

## Tier 3 — Platform-only

| Widget | Source file | Required flag | With-web-fallback class | Notes |
|---|---|---|---|---|
| ActionSheet | `src/ui/views/action_sheet.cr` | `:ios` | `ActionSheetWithWebFallback` | New in phase 4. SwiftUI `.confirmationDialog` on iOS. |
| ContextMenu | `src/ui/views/context_menu.cr` | `:darwin` | `ContextMenuWithWebFallback` | |
| PathControl | `src/ui/views/path_control.cr` | `:macos` | `PathControlWithWebFallback` | |

## Open questions

(empty when phase 4 closes; populated during implementation if the team
lead has not yet resolved a classification)

## Change log

* 2026-MM-DD — Phase 4 created initial classification.
```

When you publish this, the **Tier 1** and **Tier 2** sections must enumerate every file from your `ls src/ui/views/` output. No widget left unclassified.

---

## Step-by-step implementation plan

Each step is a commit. Subjects use the convention from `implementation_criteria.md`.

### Commit 1 — `[Phase 4] Create ActionSheet widget shell`

Files:
- New: `src/ui/views/action_sheet.cr` (un-gated yet — just the class shape).
- Edit: `src/ui/views.cr` (or equivalent require-all index, if one exists) to include the new file.
- New: `src/ui/views/action_sheet_with_web_fallback.cr` (un-gated yet).
- New: `spec/ui/views/action_sheet_spec.cr` (basic construction + add_action test).
- New: `spec/ui/views/action_sheet_with_web_fallback_spec.cr`.

Why first: the gate macro needs the class to exist. Verifying the class works as a plain View on web is the prerequisite to gating it.

### Commit 2 — `[Phase 4] Route ActionSheet to UIKit visitor`

Files:
- Edit: `src/ui/renderers/uikit_renderer.cr` — add `visit(view : UI::ActionSheet)`. Implement via SwiftKit's `.confirmationDialog` (the SwiftUI bridge from phase 3 must already expose this; if not, return early and flag to team lead).
- Edit: `src/ui/renderers/appkit_renderer.cr` — explicitly **do not** add a visitor. macOS has no native action sheet; the fallback path is `ActionSheetWithWebFallback`.
- Edit: `src/ui/renderers/web_renderer.cr` — add `visit(view : UI::ActionSheetWithWebFallback)` rendering the bottom-sheet structure.
- Edit: `src/ui/renderers/android_renderer.cr` — add `visit(view : UI::ActionSheetWithWebFallback)` rendering as a styled BottomSheetDialog.

### Commit 3 — `[Phase 4] Inline ActionSheet fallback JS+CSS into web renderer`

Files:
- New: `src/ui/web/action_sheet_fallback.js` (the JS shown above).
- Edit: `src/ui/renderers/web_renderer.cr` — register the JS once per page (existing pattern; see how the renderer currently injects scripts).

### Commit 4 — `[Phase 4] Gate ActionSheet at compile time on non-iOS`

Files:
- Edit: `src/ui/views/action_sheet.cr` — wrap the class in `{% if flag?(:ios) %}` / `{% else %}` with the actionable `{% raise %}` shown above.
- Edit: `src/ui/views/action_sheet_with_web_fallback.cr` — finalize the conditional delegate pattern shown above.
- New: `spec/ui/views/action_sheet_compile_error_spec.cr` — uses `Crystal::Macros` / subprocess `crystal build --no-codegen` to assert a snippet using `UI::ActionSheet` without `-Dios` fails with the expected message text.

### Commit 5 — `[Phase 4] Apply Tier 3 gate to ContextMenu`

Files:
- Edit: `src/ui/views/context_menu.cr` — wrap in `{% if flag?(:darwin) %}` / `{% else %}` with raise.
- New: `src/ui/views/context_menu_with_web_fallback.cr`.
- Edit: `src/ui/renderers/web_renderer.cr` — **remove** the existing `visit(view : UI::ContextMenu)` (line 1457). The class no longer exists on web. **Add** `visit(view : UI::ContextMenuWithWebFallback)`.
- New: `src/ui/web/context_menu_fallback.js`.
- New: `spec/ui/views/context_menu_compile_error_spec.cr`.
- New: `spec/ui/views/context_menu_with_web_fallback_spec.cr`.

**Watch out:** `src/ui/menu_bar.cr` uses `ContextMenu` inside its `Menu` record. On a `-Dios` build (which is also `:darwin`), this continues to work. On a non-darwin web build, `MenuBar` is a macOS construct anyway, so the menu_bar.cr file should not require context_menu.cr unconditionally; it should follow the same pattern. **Edit `src/ui/menu_bar.cr`** to wrap the `ContextMenu` usage in `{% if flag?(:darwin) %}`.

### Commit 6 — `[Phase 4] Apply Tier 3 gate to PathControl`

Files:
- Edit: `src/ui/views/path_control.cr` — wrap in `{% if flag?(:macos) %}` / `{% else %}` with raise.
- New: `src/ui/views/path_control_with_web_fallback.cr`.
- Edit: `src/ui/renderers/web_renderer.cr` — remove the existing `visit(view : UI::PathControl)` (line 1630). Add `visit(view : UI::PathControlWithWebFallback)` that renders `<nav aria-label="Breadcrumb"><ol>...</ol></nav>` with proper landmark semantics (an improvement over the existing `>`-separated string).

### Commit 7 — `[Phase 4] Add AssetPipeline::Platform.requires macro`

Files:
- New: `src/asset_pipeline/platform.cr` (the macro shown above).
- Edit: `src/asset_pipeline.cr` — require the new file.
- New: `spec/asset_pipeline/platform_spec.cr` — covers `Platform.requires` and `Platform.has?` against the current build flags.

### Commit 8 — `[Phase 4] Publish tier-matrix.md`

Files:
- New: `docs/initiative-cross-platform-ui/tier-matrix.md` (every widget classified).

### Commit 9 — `[Phase 4] Update CLAUDE.md tier conventions`

Files:
- Edit: `/Users/crimsonknight/open_source_coding_projects/asset_pipeline/CLAUDE.md`
  - Add a new section: "Tier model for cross-platform widgets" (3 paragraphs summarizing Tier 1/2/3 and pointing to `docs/initiative-cross-platform-ui/tier-matrix.md`).
  - Add: "When adding a Tier 3 widget, follow `src/ui/views/action_sheet.cr` as the template: gate with `{% if flag?(:ios) %}`, provide an actionable `{% raise %}` else-branch, and ship a `*WithWebFallback` sibling if a credible web fallback exists."
  - Add: "Use `AssetPipeline::Platform.requires(:ios)` in application code to gate platform-only logic; reserve raw `{% if flag?(:ios) %}` for library code."

### Commit 10 — `[Phase 4] Compile-error specs and CI gate`

Files:
- Refine the three `*_compile_error_spec.cr` specs from commits 4–6. Pattern:

**Compile-check subprocess pattern: tempfile, not stdin.** The `crystal build --no-codegen -` (read source from stdin) invocation is not portable across Crystal versions used in this repo, and `Process.run`'s combined stdout/stderr capture is more reliable than juggling two `IO::Memory` sinks. Write the snippet to a uniquely-numbered tempfile under `/tmp/`, invoke `crystal build --no-codegen <path>`, and assert against the combined output. Number the tempfile per spec example to avoid races when specs run in parallel.

```crystal
# spec/ui/views/action_sheet_compile_error_spec.cr
require "../../spec_helper"

# Counter for unique tempfile names across spec examples in this process.
@@_compile_check_counter = Atomic(Int32).new(0)

private def write_compile_check_source(snippet : String) : String
  n = @@_compile_check_counter.add(1)
  path = "/tmp/asset-pipeline-compile-check-#{Process.pid}-#{n}.cr"
  File.write(path, snippet)
  path
end

private def run_compile_check(snippet : String, flags : Array(String) = [] of String) : {Process::Status, String}
  path = write_compile_check_source(snippet)
  combined = IO::Memory.new
  status = Process.run(
    "crystal",
    ["build", "--no-codegen", *flags, path],
    output: combined,
    error: combined,
  )
  File.delete(path) if File.exists?(path)
  {status, combined.to_s}
end

describe "UI::ActionSheet (compile-time gate)" do
  it "raises a useful compile error when used without -Dios" do
    snippet = <<-CR
      require "asset_pipeline/ui"
      sheet = UI::ActionSheet.new("Title", "Message")
    CR
    status, output = run_compile_check(snippet)
    status.success?.should be_false
    output.should contain("UI::ActionSheet is iOS-only")
    output.should contain("-Dios")
    output.should contain("UI::ActionSheetWithWebFallback")
    output.should contain("{% if flag?(:ios) %}")
  end

  it "compiles cleanly when built with -Dios" do
    snippet = <<-CR
      require "asset_pipeline/ui"
      sheet = UI::ActionSheet.new("Title", "Message")
    CR
    status, _output = run_compile_check(snippet, flags: ["-Dios"])
    status.success?.should be_true
  end
end
```

Conventions for this pattern across all three compile-error specs (ActionSheet, ContextMenu, PathControl):

- Tempfile path is `/tmp/asset-pipeline-compile-check-{pid}-{n}.cr` where `{n}` is a per-process monotonic counter (so parallel spec runners cannot collide).
- Always pass a single combined `IO::Memory` to both `output:` and `error:` so the error-text assertion can match either Crystal stdout (`info` lines) or stderr (typical compiler diagnostics).
- Always delete the tempfile in an `ensure`-equivalent path so failed examples do not leave litter under `/tmp/`.
- Assertions match the error message text against the combined output (not against stderr alone).

---

## Documentation updates

In addition to the new `tier-matrix.md` and the `CLAUDE.md` additions called out in commit 9, update:

- `README.md` (repo root) — **only if** the public API changes from a user's perspective. The `*WithWebFallback` classes are new public types, so add a paragraph under whatever section currently lists cross-platform views: "Tier 3 widgets like `UI::ActionSheet`, `UI::ContextMenu`, and `UI::PathControl` are gated to specific platforms at compile time. For an action sheet that also works on web, use `UI::ActionSheetWithWebFallback`. See `docs/initiative-cross-platform-ui/tier-matrix.md` for the full classification."
- Inline doc-comments on each new public type.

---

## Testing requirements

Beyond the compile-error specs above:

- **Crystal-side**:
  - `ActionSheet.new` + `add_action` + property assignment all work on `-Dios`.
  - `ActionSheetWithWebFallback.new` + `add_action` works on every flag combination (`-Dios`, `-Dmacos`, default web, `-Dandroid`).
  - `ContextMenu` compile-error on default (web) build; compiles on `-Dios` and `-Dmacos`.
  - `ContextMenuWithWebFallback` compiles everywhere.
  - `PathControl` compile-error on every build except `-Dmacos`.
  - `PathControlWithWebFallback` compiles everywhere.
  - `AssetPipeline::Platform.requires(:ios) { ... }` raises a compile error without `-Dios`; passes through on `-Dios`.

- **Web fallback behavior**:
  - HTML structure assertions: the `web_renderer.cr` visit method produces a `role="dialog"`, `aria-modal="true"`, `data-presented` attribute, and the expected child structure for `ActionSheetWithWebFallback`. Use the existing renderer spec pattern (compare rendered HTML to expected fragments).
  - Same for `ContextMenuWithWebFallback` (asserts `role="menu"`, items have `role="menuitem"`).
  - These specs live in `spec/ui/renderers/web_renderer_spec.cr` (extend the existing file) and are about rendered HTML only — JS-level focus-trap behavior is validated by the validator's browser-MCP runs, not by Crystal specs.

- **Existing spec suite must remain green.** `crystal spec` from repo root.

- **Cross-target builds:**
  - `crystal build --no-codegen src/asset_pipeline.cr` (default web) succeeds.
  - `crystal build --no-codegen src/asset_pipeline.cr -Dios` succeeds.
  - `crystal build --no-codegen src/asset_pipeline.cr -Dmacos` succeeds.
  - `crystal build --no-codegen src/asset_pipeline.cr -Dandroid` succeeds.
  - The macOS sample under `samples/cross_platform/macos_host/` builds clean.
  - The iOS sample under `samples/cross_platform/ios_host/` builds clean.

---

## Definition of done

1. `src/ui/views/action_sheet.cr` exists, is Tier-3-gated, and produces the actionable compile error on non-iOS builds.
2. `src/ui/views/action_sheet_with_web_fallback.cr` exists and renders correctly on web, macOS, and Android; on iOS it delegates to the gated `ActionSheet`.
3. `context_menu.cr` and `path_control.cr` are similarly gated, with their `*WithWebFallback` siblings present.
4. `src/ui/menu_bar.cr` is updated to wrap its `ContextMenu` usage in `{% if flag?(:darwin) %}`.
5. The vanilla-JS fallbacks for action sheet and context menu are inlined into the web renderer output and pass accessibility audits at the validator level (focus trap, ARIA roles, keyboard nav, escape-to-dismiss, focus restoration).
6. `AssetPipeline::Platform.requires(:ios)` macro is implemented and spec-covered.
7. `docs/initiative-cross-platform-ui/tier-matrix.md` exists, classifies every widget in `src/ui/views/`, and lists no unclassified widgets.
8. `CLAUDE.md` documents the tier convention and points new contributors at `tier-matrix.md`.
9. Compile-error specs for `ActionSheet`, `ContextMenu`, and `PathControl` exist and pass.
10. Existing spec suite stays green. All four target builds compile.
11. Commits follow `[Phase 4] ...` subject convention. Handoff message includes the commit hashes and an honest "Deviations" section.

Done does **not** mean validator has reviewed. Hand off to the team lead and wait.
