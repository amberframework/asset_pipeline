# Container that groups input controls into sections with HIG-conformant spacing.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # A form view. Two usage modes co-exist:
  #
  # 1. **Sectioned form (existing iOS-style grouped semantics)** — built via
  #    `add_section` + adding `Field`s. Renders as grouped `<fieldset>`s on
  #    web; native renderers wrap each section in NSBox / iOS Form-section
  #    chrome.
  #
  # 2. **Flat form (Phase 8A)** — built with `form << child` for simple
  #    sign-in / contact forms. Renders as inline flex-column children
  #    on web. Native renderers fall through to the section-rendering
  #    path unchanged; flat-children mode is web-only in Phase 8A.
  #
  # # Web POST semantics (Phase 8A)
  #
  # When `action` is non-nil, the web renderer wraps the form's children
  # in `<form action="..." method="POST">` and injects a hidden
  # `<input type="hidden" name="_csrf" value="...">` field. The CSRF
  # token resolves in this order:
  #
  # 1. `Form#csrf_token` explicit constructor arg (set once at build time).
  # 2. `UI::RenderContext.csrf_token` threaded into
  #    `UI::Web::Renderer#render(view, render_context:)`.
  # 3. nil — the form still renders, but no hidden CSRF input is emitted.
  #
  # # Submit-button auto-promotion
  #
  # On web, if `action` is non-nil and the form contains exactly ONE
  # `UI::Button` child whose `type` is the default `Type::Button`, the
  # renderer promotes that single button to `Type::Submit` so a browser
  # can submit the form. Multi-button forms do NOT auto-promote — set
  # `type: UI::Button::Type::Submit` explicitly on the intended submitter.
  #
  # Property mutation note: `csrf_token` is read once by the web visit
  # method on the live `Form` instance. Threading via the renderer's
  # `RenderContext` is the supported API for shared trees. Direct
  # post-build mutation of `csrf_token` on a tree that may be re-rendered
  # across requests is unsupported.
  class Form < View
    record Field,
      label : String = "",
      content : View? = nil

    record FormSection,
      header : String? = nil,
      fields : Array(Field) = [] of Field,
      footer : String? = nil

    property sections : Array(FormSection) = [] of FormSection

    # Flat (non-sectioned) children appended via `<<`. Web visit renders
    # these inline after the section chrome. Native visit (Phase 8A
    # scope) ignores `children` — only sections render natively.
    property children : Array(View) = [] of View

    # Web POST target. When nil (default) the web visit does NOT wrap
    # children in a `<form>` element and the form renders identically
    # to its previous sectioned-only behavior. When non-nil the wrapper
    # `<form action="..." method="...">` emits and CSRF + submit-button
    # plumbing engages.
    property action : String? = nil

    # HTTP method for the form wrapper. Defaults to POST. The web
    # renderer normalizes to uppercase.
    property method : String = "POST"

    # CSRF token written to the hidden `<input name="_csrf">` field.
    # Set via the constructor at screen-build time. If left nil the
    # renderer falls back to `UI::RenderContext.csrf_token` threaded
    # through `UI::Web::Renderer#render(view, render_context:)`. If both
    # are nil no hidden CSRF input is emitted.
    property csrf_token : String? = nil

    def initialize(
      *,
      @action : String? = nil,
      @method : String = "POST",
      @csrf_token : String? = nil
    )
      # Default container-query root so `@container form (...)` rules and
      # the per-element render output both pick up `container-type:
      # inline-size; container-name: form;` without needing the registered
      # class CSS to be loaded.
      @container_query_name = "form"
    end

    def add_section(header : String? = nil, footer : String? = nil) : FormSection
      section = FormSection.new(header: header, footer: footer)
      @sections << section
      section
    end

    # Append a flat (non-sectioned) child. Used by the screen author
    # for simple sign-in / contact forms where iOS-style section
    # grouping isn't needed. Returns the form for chaining.
    def <<(child : View) : self
      @children << child
      self
    end

    def field_count : Int32
      sections.sum(&.fields.size)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
