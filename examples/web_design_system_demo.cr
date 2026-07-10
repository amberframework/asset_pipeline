require "file_utils"
require "../src/components"

module WebDesignSystemDemo
  PAGE_DIR      = "output"
  OUTPUT        = File.join(PAGE_DIR, "web-design-system-demo.html")
  PAGE_MANIFEST = [
    {key: "overview", title: "Home", file: "web-design-system-demo.html", legacy_file: "amber-design-system-demo.html"},
    {key: "pricing", title: "Pricing", file: "web-design-system-pricing.html", legacy_file: "amber-design-system-pricing.html"},
    {key: "forms", title: "Forms", file: "web-design-system-forms.html", legacy_file: "amber-design-system-forms.html"},
    {key: "dashboard", title: "Dashboard", file: "web-design-system-dashboard.html", legacy_file: "amber-design-system-dashboard.html"},
    {key: "timeline", title: "Timeline", file: "web-design-system-timeline.html", legacy_file: "amber-design-system-timeline.html"},
    {key: "collaboration", title: "Collaboration", file: "web-design-system-collaboration.html", legacy_file: "amber-design-system-collaboration.html"},
    {key: "patterns", title: "Patterns", file: "web-design-system-patterns.html", legacy_file: "amber-design-system-patterns.html"},
  ]

  def self.run
    Components::CSS::ClassRegistry.instance.clear
    register_page_css

    css = Components::CSS::Engine::Generator.new(Components::CSS::Config.new).generate
    fonts = Components::Assets::FontManifest.new
    fonts << Components::Assets::FontAsset.cdn(
      "Inter + Newsreader",
      "https://fonts.googleapis.com/css2?family=Inter:wght@400;520;680;760&family=Newsreader:opsz,wght@6..72,620..720&display=swap"
    )

    write_pages(css, fonts)
    puts "Generated #{OUTPUT} and #{PAGE_MANIFEST.size - 1} web design-system companion pages"
  end

  def self.register_page_css
    Components::CSS::ComponentCSSRegistry.instance.register(
      "WebDesignSystemDemo::FrontloaderStudio",
      <<-CSS
      /* Demo-local token aliases. Phase 1 removed the `--amber-*` cascade
         and Phase 2 migrated the demo heredoc to `--ap-*`. The dist token
         file ships canonical scalars (--ap-color-danger, --ap-color-info,
         etc.) but does NOT ship the surface/border/text triples or the
         radius-control / elevation-* family that the demo composes. We
         derive them here so the static demo stays self-contained without
         polluting the source-of-truth token dist. */
      :where(:root) {
        --ap-radius-control: 0.5rem;
        --ap-color-state-hover: color-mix(in oklch, var(--ap-color-brand-primary) 12%, transparent);
        --ap-color-success-bg: color-mix(in oklch, var(--ap-color-success) 14%, var(--ap-color-surface-canvas));
        --ap-color-success-border: color-mix(in oklch, var(--ap-color-success) 42%, var(--ap-color-border-default));
        --ap-color-success-text: var(--ap-color-success);
        --ap-color-warning-bg: color-mix(in oklch, var(--ap-color-warning) 16%, var(--ap-color-surface-canvas));
        --ap-color-warning-border: color-mix(in oklch, var(--ap-color-warning) 44%, var(--ap-color-border-default));
        --ap-color-warning-text: var(--ap-color-warning);
        --ap-color-danger-bg: color-mix(in oklch, var(--ap-color-danger) 14%, var(--ap-color-surface-canvas));
        --ap-color-danger-border: color-mix(in oklch, var(--ap-color-danger) 44%, var(--ap-color-border-default));
        --ap-color-danger-text: var(--ap-color-danger);
        --ap-color-danger-focus-ring: color-mix(in oklch, var(--ap-color-danger) 38%, transparent);
        --ap-color-info-bg: color-mix(in oklch, var(--ap-color-info) 14%, var(--ap-color-surface-canvas));
        --ap-color-info-border: color-mix(in oklch, var(--ap-color-info) 44%, var(--ap-color-border-default));
        --ap-color-info-text: var(--ap-color-info);
        --ap-elevation-raised: var(--ap-shadow-raised);
        --ap-elevation-floating: var(--ap-shadow-floating);
        --ap-elevation-overlay: var(--ap-shadow-overlay);
      }

      .am-skip-link {
        background: var(--ap-color-surface-inverse);
        border-radius: 0 0 var(--ap-radius-control) 0;
        color: var(--ap-color-text-inverse);
        left: 0;
        padding: 0.75rem 1rem;
        position: fixed;
        top: 0;
        transform: translateY(-110%);
        z-index: 100;
      }

      .am-skip-link:focus {
        transform: translateY(0);
      }

      .am-demo-shell {
        /* Explicit flat background-color so axe-core's contrast walker
           can compute foreground-vs-background pairs without falling back
           to its `#ffffff` sentinel. The gradient stack on top supplies
           the textured surface; the flat color underneath supplies the
           contrast baseline that AA serializes against. */
        background-color: var(--ap-color-surface-canvas);
        background-image:
          linear-gradient(135deg, color-mix(in oklch, var(--ap-color-brand-primary) 13%, transparent), transparent 24rem),
          linear-gradient(170deg, transparent 56%, color-mix(in oklch, var(--ap-color-brand-accent) 9%, transparent) 56%, transparent 74%),
          linear-gradient(90deg, color-mix(in oklch, var(--ap-color-border-subtle) 45%, transparent) 1px, transparent 1px),
          linear-gradient(180deg, color-mix(in oklch, var(--ap-color-border-subtle) 34%, transparent) 1px, transparent 1px),
          linear-gradient(180deg, var(--ap-color-surface-canvas), var(--ap-color-surface-sunken));
        background-size: auto, auto, 5.5rem 5.5rem, 5.5rem 5.5rem, auto;
        color: var(--ap-color-text-primary);
        min-height: 100vh;
        overflow-x: clip;
      }

      .am-demo-container {
        margin: 0 auto;
        /* Page shell scales smoothly between phones and a 1220px ceiling
           rather than clipping at fixed gutters on narrow viewports. */
        max-width: clamp(20rem, 92vw, 1220px);
        padding: clamp(0.75rem, 2.5vw, 1.5rem);
      }

      .am-demo-nav {
        align-items: center;
        display: flex;
        gap: clamp(0.5rem, 1.6vw, 1.25rem);
        justify-content: space-between;
        padding: clamp(0.5rem, 1.4vw, 0.9rem) 0 clamp(0.75rem, 2vw, 1.25rem);
        position: sticky;
        top: 0;
        z-index: 20;
      }

      .am-demo-nav::before {
        background: color-mix(in oklch, var(--ap-color-surface-canvas) 88%, transparent);
        backdrop-filter: blur(18px);
        border-bottom: 1px solid color-mix(in oklch, var(--ap-color-border-subtle) 72%, transparent);
        content: "";
        inset: -1rem -1rem 0;
        position: absolute;
        z-index: -1;
      }

      .am-demo-brand {
        align-items: center;
        color: var(--ap-color-text-primary);
        display: inline-flex;
        font-weight: 760;
        gap: 0.6rem;
        min-width: max-content;
        text-decoration: none;
      }

      .am-demo-mark {
        background:
          linear-gradient(135deg, var(--ap-color-brand-primary), var(--ap-color-brand-accent)),
          var(--ap-color-brand-primary);
        border-radius: clamp(0.4rem, 0.6vw, 0.65rem);
        box-shadow:
          inset 0 0 0 1px oklch(1 0 0 / 0.38),
          0 8px 24px color-mix(in oklch, var(--ap-color-brand-primary) 28%, transparent);
        display: inline-block;
        height: clamp(1.75rem, 2.4vw, 2.5rem);
        width: clamp(1.75rem, 2.4vw, 2.5rem);
      }

      .am-demo-nav-links {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: clamp(0.25rem, 0.6vw, 0.5rem);
        justify-content: flex-end;
        min-width: 0;
      }

      .am-demo-nav-links a {
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        font-size: clamp(0.8rem, 1vw, 0.9375rem);
        font-weight: 680;
        padding: clamp(0.4rem, 0.7vw, 0.55rem) clamp(0.55rem, 1vw, 0.85rem);
        text-decoration: none;
      }

      .am-demo-nav-links a:hover,
      .am-demo-nav-links a:focus-visible {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
      }

      .am-demo-nav-links a[aria-current="page"] {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
      }

      .am-theme-status {
        align-items: center;
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        display: inline-flex;
        font-size: 0.8125rem;
        font-weight: 680;
        min-height: 2rem;
        padding: 0 0.65rem;
      }

      .am-demo-hero,
      .am-page-hero {
        align-items: end;
        display: grid;
        gap: 1.75rem;
        grid-template-columns: minmax(0, 1.08fr) minmax(19rem, 0.92fr);
        padding: 2.75rem 0 2rem;
      }

      .am-page-hero {
        align-items: center;
        padding-bottom: 1.25rem;
      }

      .am-kicker,
      .am-demo-subtle {
        color: var(--ap-color-text-muted);
        font-size: 0.8125rem;
        font-weight: 760;
      }

      .am-kicker {
        color: var(--ap-color-brand-primary-active);
        text-transform: uppercase;
      }

      .am-demo-title,
      .am-page-title {
        font-family: var(--ap-font-display);
        font-size: clamp(2.55rem, 7vw, 5.6rem);
        font-weight: 720;
        letter-spacing: 0;
        line-height: 0.95;
        margin: 0.45rem 0 1rem;
        max-width: 11ch;
      }

      .am-page-title {
        font-size: clamp(2.1rem, 5.4vw, 4.5rem);
        max-width: 13ch;
      }

      .am-demo-copy {
        color: var(--ap-color-text-primary);
        font-size: 1.03125rem;
        line-height: 1.7;
        margin: 0;
        max-width: 64ch;
      }

      .am-demo-actions,
      .am-demo-toolbar,
      .am-inline-actions {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: clamp(0.5rem, 1.2vw, 1rem);
        margin-top: clamp(0.85rem, 2vw, 1.5rem);
      }

      .am-panel,
      .am-demo-panel {
        /* Opaque background-color first, decorative tint layered on top.
           Axe's contrast walker needs a flat opaque ancestor to compute
           4.5:1; a `color-mix(..., transparent)` makes the panel itself
           transparent and the walker keeps climbing until it hits the
           browser default. */
        background-color: var(--ap-color-surface-panel);
        background-image: linear-gradient(0deg, color-mix(in oklch, var(--ap-color-surface-panel) 92%, transparent), color-mix(in oklch, var(--ap-color-surface-panel) 92%, transparent));
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        display: grid;
        gap: clamp(0.75rem, 1.6vw, 1.25rem);
        min-width: 0;
        padding: clamp(0.85rem, 1.8vw, 1.4rem);
      }

      .am-panel[data-tone="accent"] {
        background:
          linear-gradient(135deg, color-mix(in oklch, var(--ap-color-brand-accent) 12%, transparent), transparent 58%),
          var(--ap-color-surface-panel);
      }

      .am-section {
        display: grid;
        gap: clamp(0.9rem, 2vw, 1.6rem);
        padding: clamp(1.5rem, 4vw, 3.25rem) 0;
      }

      .am-section + .am-section {
        border-top: 1px solid color-mix(in oklch, var(--ap-color-border-subtle) 72%, transparent);
      }

      .am-section-header {
        align-items: end;
        display: grid;
        gap: clamp(0.5rem, 1.4vw, 1rem);
        grid-template-columns: minmax(0, 0.9fr) minmax(18rem, 0.7fr);
      }

      .am-section-header h2 {
        font-family: var(--ap-font-display);
        font-size: clamp(1.8rem, 3.4vw, 3.1rem);
        letter-spacing: 0;
        line-height: 1;
        margin: 0;
      }

      .am-section-header p {
        color: var(--ap-color-text-secondary);
        margin: 0;
      }

      .am-grid,
      .am-two-col,
      .am-three-col,
      .am-four-col {
        display: grid;
        gap: clamp(0.6rem, 1.5vw, 1.25rem);
      }

      .am-two-col {
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .am-three-col {
        grid-template-columns: repeat(3, minmax(0, 1fr));
      }

      .am-four-col {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }

      .am-page-card-grid {
        container-type: inline-size;
        container-name: card-grid;
        display: grid;
        gap: clamp(0.75rem, 1.5vw, 1.25rem);
        /* Container-driven auto-fit: cards reflow naturally from one column
           on narrow viewports to as many as fit at min(100%, 320px) without
           a media query breakpoint. */
        grid-template-columns: repeat(auto-fit, minmax(min(100%, 18rem), 1fr));
      }

      .am-page-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        color: var(--ap-color-text-primary);
        display: grid;
        gap: clamp(0.4rem, 0.9vw, 0.7rem);
        min-height: clamp(8rem, 14vw, 13rem);
        padding: clamp(0.75rem, 1.6vw, 1.25rem);
        text-decoration: none;
        transition: transform var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          border-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard),
          background-color var(--ap-motion-duration-fast) var(--ap-motion-ease-standard);
      }

      .am-page-card:hover,
      .am-page-card:focus-visible {
        background: var(--ap-color-state-hover);
        border-color: var(--ap-color-border-strong);
        transform: translateY(-2px);
      }

      .am-page-card span {
        color: var(--ap-color-text-secondary);
      }

      .am-page-card small {
        align-self: end;
        color: var(--ap-color-brand-primary-active);
        font-weight: 760;
      }

      .am-hero-showcase,
      .am-app-window,
      .am-terminal,
      .am-command-panel {
        background:
          linear-gradient(135deg, color-mix(in oklch, var(--ap-color-brand-primary) 12%, transparent), transparent 45%),
          var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-floating);
        overflow: hidden;
      }

      .am-hero-showcase {
        min-height: 29rem;
        transform: translate3d(0, 0, 0);
      }

      .am-window-chrome {
        align-items: center;
        border-bottom: 1px solid var(--ap-color-border-subtle);
        display: flex;
        gap: 0.45rem;
        justify-content: space-between;
        padding: 0.75rem 0.85rem;
      }

      .am-window-dots {
        display: inline-flex;
        gap: 0.35rem;
      }

      .am-window-dots span {
        background: var(--ap-color-border-default);
        border-radius: 999px;
        height: 0.55rem;
        width: 0.55rem;
      }

      .am-showcase-body {
        display: grid;
        gap: 0;
        grid-template-columns: 7rem minmax(0, 1fr);
        min-height: 24rem;
      }

      .am-showcase-rail {
        background: color-mix(in oklch, var(--ap-color-surface-sunken) 65%, transparent);
        border-right: 1px solid var(--ap-color-border-subtle);
        display: grid;
        gap: 0.45rem;
        align-content: start;
        padding: 1rem 0.7rem;
      }

      .am-showcase-pill,
      .am-segmented button {
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        font-size: 0.8125rem;
        font-weight: 680;
        padding: 0.48rem 0.65rem;
      }

      .am-showcase-pill[data-active="true"],
      .am-segmented button[aria-pressed="true"],
      .am-segmented button[data-state="selected"] {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
      }

      .am-showcase-main {
        display: grid;
        gap: 1rem;
        padding: 1rem;
      }

      .am-showcase-headline {
        align-items: end;
        display: flex;
        justify-content: space-between;
        gap: 1rem;
      }

      .am-showcase-headline strong {
        display: block;
        font-size: 1.55rem;
        line-height: 1;
      }

      .am-journey-map {
        display: grid;
        gap: 0.8rem;
      }

      .am-journey-step {
        align-items: center;
        background: color-mix(in oklch, var(--ap-color-surface-elevated) 88%, transparent);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.75rem;
        grid-template-columns: auto minmax(0, 1fr) auto;
        padding: 0.8rem;
      }

      .am-step-index {
        align-items: center;
        background: var(--ap-color-brand-primary);
        border-radius: 0.45rem;
        color: var(--ap-color-text-inverse);
        display: inline-grid;
        font-weight: 760;
        height: 2rem;
        justify-items: center;
        width: 2rem;
      }

      .am-badge {
        align-items: center;
        background: var(--ap-color-info-bg);
        border: 1px solid var(--ap-color-info-border);
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-info-text);
        display: inline-flex;
        font-size: 0.8125rem;
        font-weight: 760;
        min-height: 1.75rem;
        padding: 0 0.65rem;
        width: fit-content;
      }

      .am-badge[data-tone="success"] {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-badge[data-tone="warning"] {
        background: var(--ap-color-warning-bg);
        border-color: var(--ap-color-warning-border);
        color: var(--ap-color-warning-text);
      }

      .am-badge[data-tone="danger"] {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-badge[data-tone="brand"] {
        background: color-mix(in oklch, var(--ap-color-brand-primary) 16%, transparent);
        border-color: color-mix(in oklch, var(--ap-color-brand-primary) 38%, var(--ap-color-border-subtle));
        color: var(--ap-color-text-primary);
      }

      .am-alert {
        border: 1px solid var(--ap-color-info-border);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-info-text);
        display: grid;
        gap: 0.25rem;
        padding: 0.85rem 1rem;
      }

      .am-alert[data-tone="success"] {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-alert[data-tone="warning"] {
        background: var(--ap-color-warning-bg);
        border-color: var(--ap-color-warning-border);
        color: var(--ap-color-warning-text);
      }

      .am-alert[data-tone="danger"] {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-segmented {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        display: inline-flex;
        gap: 0.2rem;
        padding: 0.2rem;
      }

      .am-segmented button {
        background: transparent;
        border: 0;
        cursor: pointer;
        min-block-size: 44px;
        min-inline-size: 44px;
      }

      .am-metric-grid,
      .am-heatmap {
        display: grid;
        gap: 0.65rem;
      }

      .am-metric-grid {
        grid-template-columns: repeat(4, minmax(0, 1fr));
      }

      .am-metric {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.25rem;
        padding: 0.85rem;
      }

      .am-metric strong {
        font-size: 1.45rem;
        line-height: 1;
      }

      .am-terminal {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
        font-family: var(--ap-font-mono);
        overflow-wrap: anywhere;
        padding: 1rem;
      }

      .am-terminal-line {
        color: color-mix(in oklch, var(--ap-color-text-inverse) 82%, var(--ap-color-brand-accent));
        margin: 0.35rem 0;
      }

      .am-terminal-line::before {
        color: var(--ap-color-brand-primary);
        content: "$ ";
      }

      .am-field,
      .am-control-example {
        display: grid;
        gap: 0.42rem;
      }

      .am-field label,
      .am-field > span:first-child,
      .am-control-example > span:first-child {
        color: var(--ap-color-text-secondary);
        font-size: 0.875rem;
        font-weight: 680;
      }

      .am-field__hint {
        color: var(--ap-color-text-muted);
        font-size: 0.8125rem;
      }

      .am-field__error {
        color: var(--ap-color-danger-text);
        font-size: 0.8125rem;
        font-weight: 680;
      }

      .am-input,
      .am-select,
      .am-textarea {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-default);
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-primary);
        font: inherit;
        min-height: 2.55rem;
        padding: 0.65rem 0.75rem;
        width: 100%;
      }

      .am-textarea {
        min-height: 7rem;
        resize: vertical;
      }

      .am-input:focus,
      .am-select:focus,
      .am-textarea:focus {
        border-color: var(--ap-color-border-focus);
        box-shadow: 0 0 0 3px var(--ap-color-border-focus);
        outline: none;
      }

      .am-input[aria-invalid="true"],
      .am-select[aria-invalid="true"],
      .am-textarea[aria-invalid="true"] {
        border-color: var(--ap-color-danger-border);
        box-shadow: 0 0 0 3px var(--ap-color-danger-focus-ring);
      }

      .am-form {
        container-type: inline-size;
        container-name: form;
        display: grid;
        gap: 1rem;
      }

      .am-form-grid {
        display: grid;
        gap: 1rem;
        grid-template-columns: repeat(2, minmax(0, 1fr));
      }

      .am-field--wide,
      .am-form-grid .am-alert,
      .am-form-grid .am-form-status {
        grid-column: 1 / -1;
      }

      .am-form-status {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-secondary);
        padding: 0.8rem 0.9rem;
      }

      .am-form-status[data-state="error"] {
        background: var(--ap-color-danger-bg);
        border-color: var(--ap-color-danger-border);
        color: var(--ap-color-danger-text);
      }

      .am-form-status[data-state="success"] {
        background: var(--ap-color-success-bg);
        border-color: var(--ap-color-success-border);
        color: var(--ap-color-success-text);
      }

      .am-choice-grid {
        display: grid;
        gap: 0.65rem;
      }

      .am-choice,
      .am-switch {
        align-items: center;
        color: var(--ap-color-text-secondary);
        display: flex;
        gap: 0.6rem;
      }

      .am-choice input,
      .am-switch input,
      .am-range {
        accent-color: var(--ap-color-brand-primary);
      }

      .am-range {
        min-height: 1.5rem;
      }

      .am-price-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        display: grid;
        gap: 1rem;
        padding: 1rem;
      }

      .am-price-card[data-featured="true"] {
        border-color: color-mix(in oklch, var(--ap-color-brand-primary) 58%, var(--ap-color-border-subtle));
        box-shadow: var(--ap-elevation-floating);
      }

      .am-price {
        align-items: baseline;
        display: flex;
        gap: 0.35rem;
      }

      .am-price strong {
        font-size: 2rem;
        line-height: 1;
      }

      .am-summary {
        background: var(--ap-color-surface-sunken);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.65rem;
        padding: 1rem;
      }

      .am-summary-row,
      .am-state-row {
        align-items: center;
        display: flex;
        gap: 0.75rem;
        justify-content: space-between;
        min-width: 0;
      }

      .am-summary-row strong {
        font-size: 1.35rem;
      }

      .am-dashboard-shell {
        container-type: inline-size;
        container-name: dashboard;
        display: grid;
        gap: 1rem;
        grid-template-columns: 13rem minmax(0, 1fr);
      }

      .am-sidebar {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.55rem;
        align-content: start;
        padding: 1rem;
      }

      .am-sidebar a {
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-secondary);
        font-weight: 680;
        padding: 0.55rem 0.65rem;
        text-decoration: none;
      }

      .am-sidebar a[aria-current="page"],
      .am-sidebar a:hover {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
      }

      .am-dashboard-main {
        display: grid;
        gap: 1rem;
        min-width: 0;
      }

      .am-dashboard-main > .am-two-col {
        grid-template-columns: minmax(34rem, 1.15fr) minmax(22rem, 0.85fr);
      }

      .am-dashboard-toolbar {
        align-items: center;
        display: flex;
        flex-wrap: wrap;
        gap: 0.75rem;
        justify-content: space-between;
      }

      .am-heatmap {
        grid-template-columns: repeat(12, minmax(0, 1fr));
      }

      .am-heat-pill {
        background: color-mix(in oklch, var(--ap-color-brand-accent) calc(var(--heat, 10) * 1%), var(--ap-color-surface-elevated));
        border: 1px solid color-mix(in oklch, var(--ap-color-brand-accent) 24%, var(--ap-color-border-subtle));
        border-radius: var(--ap-radius-pill);
        min-height: 0.8rem;
      }

      /* Note: closed-state styling for `.am-command-panel` is handled by
         the CommandPaletteComponent's registered CSS so the layout-but-
         hidden semantics propagate everywhere the palette is used. */

      .am-command-list {
        display: grid;
        gap: 0.35rem;
        padding: 0.85rem;
      }

      .am-command-item {
        align-items: center;
        border-radius: var(--ap-radius-control);
        color: var(--ap-color-text-secondary);
        display: flex;
        justify-content: space-between;
        gap: 1rem;
        padding: 0.7rem 0.8rem;
      }

      .am-command-item:hover,
      .am-command-item:focus-visible {
        background: var(--ap-color-state-hover);
        color: var(--ap-color-text-primary);
        outline: none;
      }

      kbd {
        background: var(--ap-color-surface-sunken);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: 0.35rem;
        color: var(--ap-color-text-muted);
        font-size: 0.75rem;
        padding: 0.1rem 0.35rem;
      }

      .am-timeline {
        position: relative;
      }

      .am-timeline::before {
        background: linear-gradient(180deg, var(--ap-color-brand-primary), var(--ap-color-brand-accent));
        border-radius: var(--ap-radius-pill);
        content: "";
        inset: 0 auto 0 50%;
        position: absolute;
        transform: translateX(-50%);
        width: 0.25rem;
      }

      .am-timeline-item {
        display: grid;
        gap: 1rem;
        grid-template-columns: minmax(0, 1fr) 3rem minmax(0, 1fr);
        margin: 1.75rem 0;
        opacity: 1;
        transform: none;
      }

      .am-timeline-item[data-visible="true"] {
        opacity: 1;
        transform: translateY(0);
        transition: opacity var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized),
          transform var(--ap-motion-duration-slow) var(--ap-motion-ease-emphasized);
      }

      .am-timeline-dot {
        align-self: center;
        background: var(--ap-color-brand-primary);
        border: 4px solid var(--ap-color-surface-canvas);
        border-radius: 999px;
        box-shadow: 0 0 0 1px var(--ap-color-border-subtle);
        height: 1.25rem;
        justify-self: center;
        width: 1.25rem;
        z-index: 1;
      }

      .am-timeline-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-raised);
        display: grid;
        gap: 0.45rem;
        padding: 1rem;
      }

      .am-timeline-item:nth-child(even) .am-timeline-card {
        grid-column: 3;
      }

      .am-timeline-item:nth-child(even) .am-timeline-dot {
        grid-column: 2;
      }

      .am-timeline-item:nth-child(odd) .am-timeline-card {
        grid-column: 1;
      }

      .am-timeline-item:nth-child(odd) .am-timeline-dot {
        grid-column: 2;
      }

      .am-time-field {
        background:
          radial-gradient(circle at 20% 25%, color-mix(in oklch, var(--ap-color-brand-primary) 26%, transparent), transparent 14rem),
          radial-gradient(circle at 80% 68%, color-mix(in oklch, var(--ap-color-brand-accent) 22%, transparent), transparent 16rem),
          var(--ap-color-surface-sunken);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        min-height: 18rem;
        overflow: hidden;
        position: relative;
      }

      .am-time-field svg {
        height: 100%;
        inset: 0;
        opacity: 0.58;
        position: absolute;
        width: 100%;
      }

      .am-chat-panel {
        display: grid;
        gap: 0;
        min-height: 34rem;
      }

      .am-chat-log {
        display: grid;
        gap: 0.75rem;
        max-height: 24rem;
        overflow: auto;
        padding: 1rem;
      }

      .am-message {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.25rem;
        padding: 0.75rem;
      }

      .am-message[data-own="true"] {
        background: color-mix(in oklch, var(--ap-color-brand-primary) 13%, var(--ap-color-surface-panel));
        border-color: color-mix(in oklch, var(--ap-color-brand-primary) 38%, var(--ap-color-border-subtle));
        margin-left: 2rem;
      }

      .am-message strong {
        font-size: 0.875rem;
      }

      .am-chat-form {
        border-top: 1px solid var(--ap-color-border-subtle);
        display: grid;
        gap: 0.75rem;
        grid-template-columns: minmax(0, 1fr) auto;
        padding: 1rem;
      }

      .am-live-search__results,
      .am-search-results {
        display: grid;
        gap: 0.45rem;
      }

      .am-search-result {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.2rem;
        padding: 0.75rem;
      }

      .am-upload-queue {
        display: grid;
        gap: 0.75rem;
      }

      .am-progress {
        background: var(--ap-color-surface-sunken);
        border-radius: var(--ap-radius-pill);
        height: 0.55rem;
        overflow: hidden;
      }

      .am-progress span {
        background: linear-gradient(90deg, var(--ap-color-brand-primary), var(--ap-color-brand-accent));
        display: block;
        height: 100%;
      }

      .am-divider {
        align-items: center;
        color: var(--ap-color-text-muted);
        display: grid;
        font-size: 0.8125rem;
        font-weight: 760;
        gap: 0.75rem;
        grid-template-columns: 1fr auto 1fr;
      }

      .am-divider::before,
      .am-divider::after {
        background: var(--ap-color-border-subtle);
        content: "";
        height: 1px;
      }

      .am-parallax-band {
        background:
          linear-gradient(120deg, color-mix(in oklch, var(--ap-color-brand-primary) 20%, transparent), transparent 34%),
          linear-gradient(300deg, color-mix(in oklch, var(--ap-color-brand-accent) 20%, transparent), transparent 36%),
          var(--ap-color-surface-inverse);
        border-radius: var(--ap-radius-card);
        color: var(--ap-color-text-inverse);
        min-height: 17rem;
        overflow: hidden;
        padding: 1.25rem;
        position: relative;
      }

      .am-parallax-band svg {
        inset: auto 0 0 auto;
        opacity: 0.46;
        position: absolute;
      }

      .am-tabs [role="tablist"] {
        display: flex;
        flex-wrap: wrap;
        gap: 0.4rem;
      }

      .am-tabs [role="tab"] {
        background: var(--ap-color-surface-elevated);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-pill);
        color: var(--ap-color-text-secondary);
        cursor: pointer;
        font-weight: 680;
        padding: 0.55rem 0.8rem;
      }

      .am-tabs [role="tab"][aria-selected="true"] {
        background: var(--ap-color-surface-inverse);
        color: var(--ap-color-text-inverse);
      }

      .am-tab-panel[hidden] {
        display: none;
      }

      .am-carousel {
        display: grid;
        gap: 0.8rem;
      }

      .am-carousel-track {
        display: grid;
        grid-template-columns: 1fr;
      }

      .am-carousel-slide {
        display: none;
      }

      .am-carousel-slide[data-active="true"] {
        display: grid;
      }

      .am-empty,
      .am-skeleton-card {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        display: grid;
        gap: 0.75rem;
        justify-items: start;
        padding: 1rem;
      }

      .am-skeleton {
        animation: amber-shimmer 1.2s linear infinite;
        background: linear-gradient(90deg, var(--ap-color-surface-sunken), var(--ap-color-surface-elevated), var(--ap-color-surface-sunken));
        background-size: 200% 100%;
        border-radius: var(--ap-radius-pill);
        display: block;
        min-height: 0.85rem;
        width: 100%;
      }

      .am-skeleton[data-block="true"] {
        border-radius: var(--ap-radius-card);
        min-height: 5rem;
      }

      .am-toast {
        align-items: center;
        background: var(--ap-color-surface-inverse);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-floating);
        color: var(--ap-color-text-inverse);
        display: flex;
        gap: 0.75rem;
        justify-content: space-between;
        padding: 0.75rem 0.9rem;
      }

      .am-toast .am-button {
        color: var(--ap-color-text-inverse);
      }

      .am-toast .am-toast__body {
        color: inherit;
      }

      .am-dialog {
        background: var(--ap-color-surface-panel);
        border: 1px solid var(--ap-color-border-subtle);
        border-radius: var(--ap-radius-card);
        box-shadow: var(--ap-elevation-overlay);
        color: var(--ap-color-text-primary);
        max-width: min(34rem, calc(100vw - 2rem));
        padding: 1rem;
      }

      .am-dialog::backdrop {
        background: oklch(0 0 0 / 0.42);
      }

      @keyframes amber-shimmer {
        from { background-position: 200% 0; }
        to { background-position: -200% 0; }
      }

      @media (prefers-reduced-motion: reduce) {
        *,
        *::before,
        *::after {
          animation-duration: 1ms !important;
          animation-iteration-count: 1 !important;
          scroll-behavior: auto !important;
          transition-duration: 1ms !important;
        }

        .am-page-card:hover,
        .am-page-card:focus-visible {
          transform: none;
        }
      }

      @media (max-width: 900px) {
        .am-demo-hero,
        .am-page-hero,
        .am-section-header,
        .am-two-col,
        .am-three-col,
        .am-four-col,
        .am-page-card-grid,
        .am-dashboard-shell,
        .am-form-grid {
          grid-template-columns: 1fr;
        }

        .am-metric-grid {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .am-demo-nav {
          align-items: start;
          display: grid;
        }

        .am-demo-nav-links {
          justify-content: start;
        }

        .am-showcase-body {
          grid-template-columns: 1fr;
        }

        .am-showcase-rail {
          border-right: 0;
          border-bottom: 1px solid var(--ap-color-border-subtle);
          grid-template-columns: repeat(3, minmax(0, 1fr));
        }
      }

      @media (max-width: 640px) {
        .am-demo-container {
          padding: 0.75rem;
        }

        .am-demo-title,
        .am-page-title {
          font-size: clamp(2.2rem, 14vw, 3.6rem);
        }

        .am-demo-nav-links > * {
          flex: 1 1 auto;
        }

        .am-demo-nav-links a,
        .am-demo-nav-links button {
          justify-content: center;
          text-align: center;
        }

        .am-metric-grid,
        .am-heatmap {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }

        .am-chat-form {
          grid-template-columns: 1fr;
        }

        .am-timeline::before {
          left: 0.75rem;
          transform: none;
        }

        .am-timeline-item {
          grid-template-columns: 1.75rem minmax(0, 1fr);
        }

        .am-timeline-item:nth-child(n) .am-timeline-card {
          grid-column: 2;
        }

        .am-timeline-item:nth-child(n) .am-timeline-dot {
          grid-column: 1;
        }
      }

      /* === Phase 2 container queries =====================================
         These rules adapt components to *their* container width rather than
         the viewport, so a card inside a narrow sidebar reflows the same
         way the same card inside a wide hero would. */

      @container form (max-width: 360px) {
        .am-form-grid {
          grid-template-columns: 1fr;
        }
      }

      @container form (min-width: 480px) {
        .am-form-grid {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
      }

      @container card-grid (max-width: 480px) {
        .am-page-card {
          min-height: 9rem;
        }
      }

      @container dashboard (max-width: 960px) {
        .am-dashboard-shell {
          grid-template-columns: 1fr;
        }
        .am-sidebar {
          grid-template-columns: repeat(auto-fit, minmax(8rem, 1fr));
          display: grid;
        }
        /* Inner two-col (table + chart panel) demands 34rem + 22rem and
           was the root cause of the dashboard's horizontal overflow at
           768 / 375 / 320. Collapse to a single column whenever the
           dashboard container itself is below 960. */
        .am-dashboard-main > .am-two-col {
          grid-template-columns: 1fr;
        }
        .am-dashboard-main .am-metric-grid {
          grid-template-columns: repeat(auto-fit, minmax(min(100%, 9rem), 1fr));
        }
        .am-dashboard-toolbar {
          align-items: stretch;
        }
        .am-dashboard-toolbar > * {
          min-width: 0;
        }
      }

      @container dashboard (max-width: 520px) {
        .am-dashboard-main .am-metric-grid {
          grid-template-columns: repeat(2, minmax(0, 1fr));
        }
        .am-dashboard-main .am-heatmap {
          grid-template-columns: repeat(6, minmax(0, 1fr));
        }
      }
      CSS
    )
  end

  def self.write_pages(css : String, fonts : Components::Assets::FontManifest)
    FileUtils.mkdir_p(PAGE_DIR)
    pages = {
      "overview"      => document("Frontloader Studio", "overview", css, fonts, overview_page),
      "pricing"       => document("Frontloader Studio Pricing", "pricing", css, fonts, pricing_page),
      "forms"         => document("Frontloader Studio Forms", "forms", css, fonts, forms_page),
      "dashboard"     => document("Frontloader Studio Dashboard", "dashboard", css, fonts, dashboard_page),
      "timeline"      => document("Crystal Timeline", "timeline", css, fonts, timeline_page),
      "collaboration" => document("Frontloader Studio Collaboration", "collaboration", css, fonts, collaboration_page),
      "patterns"      => document("Frontloader Studio Patterns", "patterns", css, fonts, patterns_page),
    }

    PAGE_MANIFEST.each do |page|
      html = pages[page[:key]]
      File.write(File.join(PAGE_DIR, page[:file]), html)
      File.write(File.join(PAGE_DIR, page[:legacy_file]), html)
    end
  end

  def self.document(title : String, current : String, css : String, fonts : Components::Assets::FontManifest, content : String) : String
    <<-HTML
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <title>#{title}</title>
      #{fonts.link_tags}
      <style>
      #{fonts.font_face_css}
      #{css}
      </style>
    </head>
    <body class="am-demo-shell" data-demo-page="#{current}">
      <nav aria-label="Skip link">
        <a class="am-skip-link" href="#main">Skip to content</a>
      </nav>
      <div class="am-demo-container">
        #{nav(current)}
        <main id="main" tabindex="-1">
          #{content}
        </main>
      </div>
      <script>
      #{File.read("public/js/design-system.js")}
      </script>
    </body>
    </html>
    HTML
  end

  def self.nav(current : String) : String
    links = PAGE_MANIFEST.map do |page|
      aria = page[:key] == current ? %( aria-current="page") : ""
      %(<a href="#{page[:file]}"#{aria}>#{page[:title]}</a>)
    end.join("\n")

    <<-HTML
    <nav class="am-demo-nav" aria-label="Demo pages">
      <a class="am-demo-brand" href="web-design-system-demo.html"><span class="am-demo-mark" aria-hidden="true"></span>Frontloader Studio</a>
      <div class="am-demo-nav-links">
        #{links}
        #{Components::DesignSystem::ThemeSwitcher.new.render}
      </div>
    </nav>
    HTML
  end

  def self.button(label : String, tone = "brand", emphasis = "solid", size = "md", attrs = {} of String => String) : String
    component = Components::DesignSystem::Button.new(label: label, tone: tone, emphasis: emphasis, size: size)
    attrs.each { |name, value| component[name] = value }
    component.render
  end

  def self.badge(label : String, tone = "info") : String
    Components::DesignSystem::Badge.new(label: label, tone: tone).render
  end

  def self.metric(label : String, value : String, copy : String) : String
    Components::DesignSystem::Metric.new(label: label, value: value, body: copy).render
  end

  def self.layout_grid(kind : String, body : String) : String
    component = Components::DesignSystem::LayoutGrid.new(kind: kind, compatibility_markup: "demo")
    component << Components::Elements::RawHTML.new(body)
    component.render
  end

  def self.layout_grid(kind : String, items : Array(String)) : String
    layout_grid(kind, "\n        #{items.join("\n        ")}\n      ")
  end

  def self.validated_form(id : String, label : String, status : String, status_id : String, body : String) : String
    form = Components::DesignSystem::ValidatedForm.new(
      id: id,
      label: label,
      status: status,
      status_id: status_id
    )
    form << Components::Elements::RawHTML.new(body)
    form.render
  end

  def self.field(label : String, id : String, type = "text", attrs = {} of String => String, data_attrs = {} of String => String, aria_attrs = {} of String => String, options = [] of Components::DesignSystem::FormField::Option) : String
    component = Components::DesignSystem::FormField.new(
      options: options,
      data_attrs: data_attrs,
      aria_attrs: aria_attrs,
      label: label,
      id: id,
      type: type
    )
    attrs.each { |name, value| component[name] = value }
    component.render
  end

  def self.page_hero(kicker : String, title : String, copy : String, aside : String = "") : String
    component = Components::DesignSystem::PageHero.new(
      kicker: kicker,
      title: title,
      body: copy,
      compatibility_markup: "demo"
    )
    component << Components::Elements::RawHTML.new(aside) unless aside.empty?
    component.render
  end

  def self.section_block(title_id : String, title : String, copy : String, body : String, id : String? = nil) : String
    component = Components::DesignSystem::Section.new(
      title_id: title_id,
      title: title,
      subtitle: copy,
      compatibility_markup: "demo"
    )
    component["id"] = id if id
    component << Components::Elements::RawHTML.new(body)
    component.render
  end

  def self.panel_block(body : String, tag = "section", extra_class = "", attrs = {} of String => String) : String
    component = Components::DesignSystem::Panel.new(
      tag: tag,
      compatibility_markup: "demo"
    )
    component["class"] = extra_class unless extra_class.empty?
    attrs.each { |name, value| component[name] = value }
    component << Components::Elements::RawHTML.new(body)
    component.render
  end

  def self.overview_page : String
    contract_panel_body = %(<strong>Public component contract</strong><p class="am-demo-copy">Buttons, cards, form fields, tables, charts, page sections, motion helpers, and feedback states use generic component APIs with token-backed compatibility selectors instead of Bootstrap-shaped naming.</p>)
    contract_panel = panel_block(contract_panel_body, "div", "", {"tone" => "accent"})
    pages_body = "  #{Components::DesignSystem::PageLinkCardGrid.new(compatibility_markup: "demo").build { |grid| grid << Components::Elements::RawHTML.new("\n    #{PAGE_MANIFEST.reject { |page| page[:key] == "overview" }.map { |page| Components::DesignSystem::PageLinkCard.new(href: page[:file], title: page[:title], summary: page_summary(page[:key])).render }.join("\n")}\n  ") }.render}"

    proof_metrics = [metric("Theme modes", "2", "Light and dark via generated CSS variables."), metric("Runtime", "0", "No build tooling, no framework glue."), metric("Controls", "HTML5", "Native semantics first, JS only for quality of life."), metric("Charts", "SVG", "First-party visuals with adapter boundary.")]
    terminal_preview = Components::DesignSystem::TerminalPreview.new(commands: ["crystal run examples/web_design_system_demo.cr", "crystal run scripts/validate_web_demo.cr", "crystal run scripts/capture_web_demo_screenshots.cr"], compatibility_markup: "demo").render
    showcase_preview = Components::DesignSystem::ShowcasePreview.new(
      label: "Frontloader product interface preview",
      window_title: "Launch command",
      rail_label: "Preview sections",
      rail_items: ["Plan", "Ship", "Learn"],
      active_rail_item: "Plan",
      eyebrow: "Launch health",
      headline: "Ready in 18h",
      badge_html: badge("AA checked", "success"),
      list_label: "Launch readiness workflow",
      steps: [
        Components::DesignSystem::ShowcasePreview::Step.new("Assets compiled", "CSS variables, SVG charts, and font strategies ready.", badge("Done", "success")),
        Components::DesignSystem::ShowcasePreview::Step.new("Pricing validated", "Seat totals, add-ons, and payment fields respond in browser.", badge("Review", "warning")),
        Components::DesignSystem::ShowcasePreview::Step.new("Demo evidence", "Screenshots and CDP audits capture the current surface.", badge("Queued", "brand")),
      ],
      compatibility_markup: "demo"
    ).render
    landing_hero = Components::DesignSystem::LandingHero.new(
      kicker: "No-build JavaScript. Opinionated design-system UI.",
      title: "Beautiful launch ops by default.",
      body: "Frontloader Studio is a fictional AI launch-operations product that shows Asset Pipeline behaving like a taste-bearing web design system: semantic, accessible, themeable, motion-aware, and interactive without a build step.",
      actions: [
        Components::DesignSystem::LandingHero::Action.new("Open pricing"),
        Components::DesignSystem::LandingHero::Action.new("View dashboard", tone: "neutral", emphasis: "outline"),
        Components::DesignSystem::LandingHero::Action.new("External project link", href: "https://crystal-lang.org", tone: "neutral", emphasis: "ghost", external: true),
      ],
      toolbar_html: Components::DesignSystem::ThemeSwitcher.new(mode: "segmented", label: "Theme mode").render,
      aside_html: showcase_preview,
      compatibility_markup: "demo"
    ).render
    proof_body = <<-HTML
      #{layout_grid("four", proof_metrics)}
      #{layout_grid("two", [terminal_preview, contract_panel])}
    HTML

    <<-HTML
    #{landing_hero}

    #{section_block("home-pages-title", "A product tour, not a component dump.", "Every page demonstrates components in realistic context: pricing, authentication, operations, a timeline, collaboration, and reusable page patterns.", pages_body)}

    #{section_block("home-proof-title", "The design system carries the interface.", "Warm action color carries primary intent. Ink surfaces keep dense workflows calm. Teal highlights operational intelligence without turning the app into an orange-black theme.", proof_body)}
    HTML
  end

  def self.page_summary(key : String) : String
    {
      "pricing"       => "Plans, billing toggles, seat sliders, add-ons, promo codes, payment validation, and success states.",
      "forms"         => "Sign-in, sign-up, password confirmation, reset flows, semantic field wiring, and native browser validation.",
      "dashboard"     => "Operational metrics, row states, filters, command palette, first-party chart, and schedule heatmap.",
      "timeline"      => "Crystal language milestones with alternating scroll-reveal cards and subtle motion.",
      "collaboration" => "Large chat surface, live search, mentions, uploads, activity, empty and loading states.",
      "patterns"      => "Dividers, parallax-style bands, carousel, tabs, disclosure, dialog, toasts, and link treatments.",
    }[key]
  end

  def self.pricing_page : String
    payment_form = Components::DesignSystem::PaymentForm.new.render
    order_addons = [
      Components::DesignSystem::OrderSummary::AddOn.new("Accessibility audit add-on", "180", true),
      Components::DesignSystem::OrderSummary::AddOn.new("Launch-room transcript pack", "90"),
    ]
    aside = Components::DesignSystem::OrderSummary.new(label: "Interactive order summary", seat_id: "pricing-seats", seat_min: "3", seat_max: "40", seat_value: "12", add_ons: order_addons, total_label: "Billing", total: "$1,188/mo", note: "Annual billing saves 18%.", compatibility_markup: "demo").render
    plan_cards = [
      Components::DesignSystem::PricingCard.new(name: "Starter", badge: "Starter", badge_tone: "brand", price: "$39", copy: "For small teams proving a launch workflow.", action: "Choose Starter", action_tone: "neutral", action_emphasis: "outline").render,
      Components::DesignSystem::PricingCard.new(name: "Studio", badge: "Recommended", badge_tone: "success", price: "$99", copy: "Full launch operations with accessibility, dashboards, and collaboration.", action: "Choose Studio", featured: "true").render,
      Components::DesignSystem::PricingCard.new(name: "Scale", badge: "Scale", badge_tone: "info", price: "$179", copy: "Governance, reviews, and rollout support for larger teams.", action: "Talk to sales", action_tone: "neutral", action_emphasis: "outline").render,
    ]
    plans_body = <<-HTML
      <div class="am-demo-toolbar">
        <span class="am-segmented" role="group" aria-label="Billing cycle" data-amber-billing-toggle data-ap-billing-toggle>
          <button type="button" data-billing="monthly" aria-pressed="false">Monthly</button>
          <button type="button" data-billing="annual" aria-pressed="true">Annual</button>
        </span>
      </div>
      #{layout_grid("three", plan_cards)}
    HTML
    payment_state_panel_body = %(<strong>Payment states demonstrated</strong><div class="am-choice-grid">#{badge("Valid card path", "success")}#{badge("Promo review", "warning")}#{badge("Inline invalid fields", "danger")}#{badge("Live summary updates", "info")}</div><p class="am-demo-copy">The implementation uses HTML5 attributes first, then vanilla JS for formatting, matching, and live region text.</p>)
    payment_state_panel = panel_block(payment_state_panel_body, "aside", "", {"tone" => "accent", "label" => "Payment states demonstrated"})
    payment_body = layout_grid("two", [payment_form, payment_state_panel])

    <<-HTML
    #{page_hero("Pricing and payment", "Plans that prove form states.", "The pricing page uses realistic inputs so theme, validation, field semantics, and state management are visible in context.", aside)}

    #{section_block("plans-title", "Plan comparison", "Billing controls are native buttons and inputs. The total updates in a live region without requiring a framework.", plans_body)}

    #{section_block("payment-title", "Payment form", "The form does not submit anywhere. It demonstrates browser-native validation, formatted fields, invalid states, and success feedback.", payment_body)}
    HTML
  end

  def self.forms_page : String
    signup_form = Components::DesignSystem::AuthForm.new(mode: "signup").render
    signin_form = Components::DesignSystem::AuthForm.new(mode: "signin").render
    reset_form = validated_form("reset-form", "Password reset", "Enter an email to preview reset validation.", "reset-status", %(#{field("Account email", "reset-email", "email", {"name" => "email", "autocomplete" => "email", "required" => "true"})}#{button("Send reset link", "neutral", "outline", "md", {"type" => "submit"})}))
    team_sizes = [Components::DesignSystem::FormField::Option.new("Choose one", ""), Components::DesignSystem::FormField::Option.new("3-10", "3-10"), Components::DesignSystem::FormField::Option.new("11-50", "11-50"), Components::DesignSystem::FormField::Option.new("51+", "51+")]
    preference_fields = %(<div class="am-form-grid">#{field("Team size", "team-size", "select", {"name" => "team_size", "required" => "true"}, options: team_sizes)}#{field("Launch date", "launch-date", "date", {"name" => "launch_date", "required" => "true"})}#{field("Launch note", "notes", "textarea", {"name" => "notes", "minlength" => "12", "required" => "true", "placeholder" => "Describe what the team is shipping.", "wide" => "true"})}</div>#{button("Save preferences", "brand", "solid", "md", {"type" => "submit"})})
    preferences_form = validated_form("preferences-form", "Launch preferences", "Preference updates stay local in this demo.", "preferences-status", preference_fields)
    auth_body = layout_grid("two", [signup_form, signin_form])
    reset_body = layout_grid("two", [reset_form, preferences_form])

    <<-HTML
    #{page_hero("Semantic forms", "Auth flows with native validation.", "Email fields, password rules, confirmation matching, reset flows, labels, hints, and error messages are all wired as browser-readable controls.")}

    #{section_block("auth-title", "Sign-up and sign-in", "These are separate flows because a real product needs different defaults, autocomplete hints, and validation behavior for each.", auth_body)}

    #{section_block("reset-title", "Reset and preference forms", "The same field contract scales from single-field flows to dense settings screens.", reset_body, "reset-flow")}
    HTML
  end

  def self.dashboard_page : String
    rows = [
      Components::DesignSystem::DataTable::Row.new("LCH-204", "Pricing page validation", "Mina Park", "Passing", "success", "98%"),
      Components::DesignSystem::DataTable::Row.new("LCH-205", "Payment error copy", "Theo Grant", "Needs review", "warning", "73%"),
      Components::DesignSystem::DataTable::Row.new("LCH-206", "Dark contrast sweep", "Ana Ruiz", "Blocked", "danger", "41%"),
      Components::DesignSystem::DataTable::Row.new("LCH-207", "Timeline motion", "Seth Tucker", "Selected", "selected", "86%"),
    ]
    table = Components::DesignSystem::DataTable.new(rows, id: "launch-table", caption: "Launch work with accessible row state semantics").render
    chart = Components::DesignSystem::SimpleChart.new(id: "launch-confidence-chart", title: "Launch confidence").render
    heatmap = Components::DesignSystem::ScheduleHeatmap.new(id: "launch-schedule-heatmap").render
    command_palette = Components::DesignSystem::CommandPalette.new(id: "launch-command", opener_label: "Command").render
    visual_panel_body = %(#{chart}#{heatmap})
    visual_panel = panel_block(visual_panel_body, "aside", "", {"label" => "Launch visual evidence"})
    sidebar_html = <<-HTML
    <strong>Frontloader</strong>
          <a href="#" aria-current="page">Launches</a>
          <a href="#">Assets</a>
          <a href="#">Audits</a>
          <a href="#">Billing</a>
          #{command_palette}
    HTML
    dashboard_body = <<-HTML
    <div class="am-dashboard-toolbar" data-testid="dashboard-toolbar">
            <div data-testid="dashboard-heading"><h2 id="dashboard-title" style="margin:0;">Launch readiness</h2><p class="am-demo-copy">Every row state has a visible indicator, subtle background, richer hover, and semantic label.</p></div>
            #{field("Filter work", "launch-filter", "search", {"placeholder" => "Try blocked, selected, pricing", "hint_html" => %(<span id="launch-filter-status" role="status" aria-live="polite">4 matching rows</span>)}, {"data-amber-filter" => "#launch-table", "data-ap-filter" => "#launch-table", "data-amber-filter-status" => "#launch-filter-status", "data-ap-filter-status" => "#launch-filter-status", "data-testid" => "dashboard-filter-field"})}
          </div>
          <div data-testid="dashboard-metric-grid">#{layout_grid("metric", [metric("Ready", "82%", "Up 12% after form audit."), metric("Open risks", "3", "One color issue is blocking."), metric("Evidence", "27", "Screenshots and audits stored."), metric("Runtime deps", "0", "All interactions are vanilla JS.")])}</div>
          <div data-testid="dashboard-two-col">#{layout_grid("two", [%(<div data-testid="dashboard-table-panel">#{table}</div>), visual_panel])}</div>
    HTML
    dashboard_shell = Components::DesignSystem::DashboardShell.new(sidebar_html: sidebar_html, body_html: dashboard_body, compatibility_markup: "demo").render

    <<-HTML
    #{page_hero("Operations dashboard", "A dense product surface that stays calm.", "The dashboard puts tables, filters, charts, command palette, schedule heatmaps, and row states into one realistic SaaS workflow.")}

    #{dashboard_shell}
    HTML
  end

  def self.timeline_page : String
    timeline = Components::DesignSystem::Timeline.new(id: "crystal-history-timeline").render

    <<-HTML
    #{page_hero("Crystal timeline", "Motion should help the story breathe.", "The centered timeline alternates facts on desktop, collapses cleanly on mobile, and keeps subtle ambient movement separate from required comprehension.", %(<aside class="am-time-field" aria-hidden="true">#{time_svg}</aside>))}

    #{timeline}
    HTML
  end

  def self.time_svg : String
    <<-SVG
    <svg viewBox="0 0 520 260" role="img" aria-label="Abstract timeline field">
      <path data-svg-part d="M40 190 C130 80, 220 245, 330 92 S470 120, 500 38" fill="none" stroke="currentColor" stroke-width="2"/>
      <circle data-svg-part cx="92" cy="144" r="24" fill="currentColor" opacity="0.08"/>
      <circle data-svg-part cx="256" cy="160" r="34" fill="currentColor" opacity="0.08"/>
      <circle data-svg-part cx="410" cy="88" r="28" fill="currentColor" opacity="0.08"/>
      <path data-svg-part d="M68 58 H188 M250 58 H454 M110 218 H342" stroke="currentColor" stroke-width="1" opacity="0.32"/>
    </svg>
    SVG
  end

  def self.collaboration_page : String
    upload_progress = Components::DesignSystem::Progress.new(label: "Timeline SVG upload progress", value: "72", compatibility_markup: "demo").render
    empty_state = Components::DesignSystem::EmptyState.new(title: "No unresolved blockers in this room", body: "The empty state is specific, calm, and paired with the next action.", compatibility_markup: "demo").build { |state| state << Components::Elements::RawHTML.new(button("Start review", "brand", "soft", "sm")) }.render
    chat_messages = %(<article class="am-message"><strong>Mina</strong><span>The pricing calculator now mirrors the order summary.</span></article><article class="am-message"><strong>Theo</strong><span>@design please review the dark-mode table warning row.</span></article><article class="am-message" data-own="true"><strong>You</strong><span>I am checking keyboard focus and dialog return behavior.</span></article>)
    chat_panel = Components::DesignSystem::ChatPanel.new(title: "Review chat", title_id: "chat-title", messages_html: chat_messages, field_html: field("Message", "chat-message", "text", {"name" => "message", "required" => "true", "placeholder" => "Write a launch note"}), action_html: button("Send", "brand", "solid", "md", {"type" => "submit"})).build { |panel| panel << Components::Elements::RawHTML.new(badge("Live", "success")) }.render
    search_panel = Components::DesignSystem::LiveSearchPanel.new(title: "Live search", title_id: "search-title", field_html: field("Search records", "collab-search", "search", {"placeholder" => "Try timeline, payment, command"}, {"data-amber-live-search" => "", "data-ap-live-search" => ""})).render
    upload_panel = Components::DesignSystem::UploadQueue.new(title: "Upload queue", title_id: "upload-title", item_html: %(<div class="am-state-row"><span>pricing-dark.png</span>#{badge("Uploaded", "success")}</div>), progress_html: upload_progress).build { |queue| queue << Components::Elements::RawHTML.new(%(<div class="am-state-row"><span>timeline.svg</span>#{badge("72%", "warning")}</div>)) }.render
    collaboration_tools = <<-HTML
        <div class="am-grid">
          #{search_panel}

          #{upload_panel}

          #{empty_state}
        </div>
    HTML
    room_body = layout_grid("two", [chat_panel, collaboration_tools])

    <<-HTML
    #{page_hero("Collaboration", "Chat, search, uploads, and activity in context.", "Communication components are larger here so state changes, live regions, scrolling, and empty/loading behavior can be experienced like a real app.")}

    #{section_block("collab-title", "Launch room", "Messages, search results, upload progress, and review activity all share the same state vocabulary.", room_body)}
    HTML
  end

  def self.patterns_page : String
    tabs = Components::DesignSystem::Tabs.new(id: "evidence", title: "Tabbed evidence", label: "Evidence views").render
    carousel = Components::DesignSystem::Carousel.new(id: "patterns-carousel", title: "Carousel").render
    dialog = Components::DesignSystem::Dialog.new(
      id: "pattern-dialog",
      title: "Native dialog wrapper",
      body: "The browser dialog element supplies modal behavior while design-system tokens control surface, shadow, radius, and action styling."
    ).render
    visual_band = Components::DesignSystem::VisualBand.new(title: "CSS/SVG first parallax-style band", body: "Deterministic visual assets keep the demo self-contained while still giving large page sections a strong identity.", compatibility_markup: "demo").build { |band| band << Components::Elements::RawHTML.new(time_svg) }.render
    composition_body = <<-HTML
      #{Components::DesignSystem::Divider.new(label: "Launch composition").render}
      #{visual_band}
    HTML
    interactive_body = <<-HTML
      #{layout_grid("two", [tabs, carousel])}

      #{layout_grid("two", %(
        <section class="am-panel" aria-labelledby="disclosure-title">
          <h2 id="disclosure-title" style="margin:0;">Disclosure</h2>
          #{Components::DesignSystem::Disclosure.new(label: "Show advanced settings", panel_id: "advanced-panel", compatibility_markup: "demo").build { |disclosure| disclosure << Components::Elements::RawHTML.new(Components::DesignSystem::Alert.new(id: "advanced-panel", body: "Advanced settings are hidden until requested, and the button owns `aria-expanded`.", tone: "warning", role: "status", hidden: "true").render) }.render}
        </section>

        <section class="am-panel" aria-labelledby="dialog-title">
          <h2 id="dialog-title" style="margin:0;">Dialog and toast</h2>
          #{dialog}
          #{Components::DesignSystem::Toast.new(id: "screenshot-validation-toast", body: "Screenshot validation finished", tone: "neutral", action_label: "View").render}
        </section>
      ))}
    HTML

    <<-HTML
    #{page_hero("Page patterns", "Reusable sections with interaction affordances.", "Dividers, bands, tabs, carousel, disclosure, dialog, toasts, and links round out the page-level design contract.")}

    #{section_block("patterns-title", "Composition primitives", "These are not decorative leftovers. They are the page tools that make a system feel complete.", composition_body)}

    #{section_block("interactive-patterns-title", "Tabs, carousel, disclosure, and dialog", "All behaviors are vanilla JavaScript and keep ARIA/focus state in sync.", interactive_body)}
    HTML
  end
end

WebDesignSystemDemo.run
