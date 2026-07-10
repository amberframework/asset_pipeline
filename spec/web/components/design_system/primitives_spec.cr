require "../../spec_helper"
require "../../../../src/asset_pipeline/design_system"

describe "Components::DesignSystem generic primitives" do
  it "renders PageShell with a skip link, labelled main landmark, and child content" do
    html = Components::DesignSystem::PageShell.new(
      id: "workspace",
      title: "Workspace",
      subtitle: "Operational overview",
      main_id: "workspace-main"
    ).build do |page|
      page << Components::DesignSystem::Section.new(
        id: "activity",
        title: "Activity",
        heading_level: "2"
      ).build { |section| section << "Recent work" }
    end.render

    html.should contain(%(<div class="am-page-shell" id="workspace" data-component="page-shell">))
    html.should contain(%(<a class="am-skip-link" href="#workspace-main">Skip to content</a>))
    html.should contain(%(<main class="am-page-shell__main" id="workspace-main" tabindex="-1" aria-labelledby="workspace-title">))
    html.should contain(%(<section class="am-section" id="activity" data-component="section" aria-labelledby="activity-title">))
    html.should contain(%(<h2 class="am-section__title" id="activity-title">Activity</h2>))
    html.should contain(%(<div class="am-section__body">Recent work</div>))
    expect_no_duplicate_ids(html)
    expect_no_positive_tabindex(html)
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LandingHero with generic metadata, escaped text, actions, toolbar, and aside" do
    hero = Components::DesignSystem::LandingHero.new(
      id: "launch-hero",
      label: "Launch landing",
      kicker: "No-build <JavaScript>",
      title: "Ship & learn",
      copy: "A proof <page> for teams.",
      actions: [
        Components::DesignSystem::LandingHero::Action.new("Open <pricing>", type: "submit"),
        Components::DesignSystem::LandingHero::Action.new("Docs & API", href: "/docs?mode=fast&theme=dark", tone: "neutral", emphasis: "ghost"),
      ],
      toolbar_html: %(<span class="am-segmented">Theme</span>),
      aside_html: %(<aside class="am-panel" aria-label="Preview">Preview</aside>),
      data_view: "overview"
    )
    hero["class"] = "is-featured"
    html = hero.render

    html.should eq(%(<header class="am-demo-hero is-featured" id="launch-hero" data-component="landing-hero" aria-label="Launch landing" data-view="overview">
  <div>
    <div class="am-kicker">No-build &lt;JavaScript&gt;</div>
    <h1 class="am-demo-title">Ship &amp; learn</h1>
    <p class="am-demo-copy">A proof &lt;page&gt; for teams.</p>
    <div class="am-demo-actions">
      <button type="submit" class="am-button am-button--brand am-button--solid am-button--md" data-state="default" data-tone="brand" data-emphasis="solid">Open &lt;pricing&gt;</button>
      <a class="am-button am-button--neutral am-button--ghost am-button--md" href="/docs?mode=fast&amp;theme=dark">Docs &amp; API</a>
    </div>
    <div class="am-demo-toolbar" role="group" aria-label="Theme preview">
      <span class="am-demo-subtle">Theme</span>
      <span class="am-segmented">Theme</span>
    </div>
  </div>
  <aside class="am-panel" aria-label="Preview">Preview</aside>
</header>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LandingHero external links with safe target and rel defaults" do
    html = Components::DesignSystem::LandingHero.new(
      title: "External proof",
      actions: [
        Components::DesignSystem::LandingHero::Action.new("External project", href: "https://crystal-lang.org", tone: "neutral", emphasis: "ghost", external: true),
      ]
    ).render

    html.should contain(%(<a class="am-button am-button--neutral am-button--ghost am-button--md" href="https://crystal-lang.org" target="_blank" rel="noopener noreferrer">External project</a>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "requires LandingHero to render a non-empty h1 title" do
    expect_raises(ArgumentError, "LandingHero requires a non-empty title") do
      Components::DesignSystem::LandingHero.new(title: "   ").render
    end
  end

  it "omits LandingHero action and toolbar wrappers when no content is supplied" do
    html = Components::DesignSystem::LandingHero.new(
      kicker: "Product",
      title: "Quiet hero",
      body: "No actions yet."
    ).render

    html.should eq(%(<header class="am-demo-hero" data-component="landing-hero">
  <div>
    <div class="am-kicker">Product</div>
    <h1 class="am-demo-title">Quiet hero</h1>
    <p class="am-demo-copy">No actions yet.</p>
  </div>
</header>))
    html.should_not contain("am-demo-actions")
    html.should_not contain("am-demo-toolbar")
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LandingHero in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::LandingHero.new(
      kicker: "No-build JavaScript. Opinionated design-system UI.",
      title: "Beautiful launch ops by default.",
      body: "Frontloader Studio is a fictional AI launch-operations product.",
      actions: [
        Components::DesignSystem::LandingHero::Action.new("Open pricing"),
        Components::DesignSystem::LandingHero::Action.new("View dashboard", tone: "neutral", emphasis: "outline"),
        Components::DesignSystem::LandingHero::Action.new("External project link", href: "https://crystal-lang.org", tone: "neutral", emphasis: "ghost", external: true),
      ],
      toolbar_html: %(<span class="am-segmented" role="group" aria-label="Theme mode">Theme controls</span>),
      aside_html: %(<aside class="am-hero-showcase" aria-label="Preview">Preview</aside>),
      compatibility_markup: "demo"
    ).render

    html.should eq(%(<header class="am-demo-hero">
  <div>
    <div class="am-kicker">No-build JavaScript. Opinionated design-system UI.</div>
    <h1 class="am-demo-title">Beautiful launch ops by default.</h1>
    <p class="am-demo-copy">Frontloader Studio is a fictional AI launch-operations product.</p>
    <div class="am-demo-actions">
      <button type="button" class="am-button am-button--brand am-button--solid am-button--md" data-state="default" data-tone="brand" data-emphasis="solid">Open pricing</button>
      <button type="button" class="am-button am-button--neutral am-button--outline am-button--md" data-state="default" data-tone="neutral" data-emphasis="outline">View dashboard</button>
      <a class="am-button am-button--neutral am-button--ghost am-button--md" href="https://crystal-lang.org" target="_blank" rel="noopener noreferrer">External project link</a>
    </div>
    <div class="am-demo-toolbar" role="group" aria-label="Theme preview">
      <span class="am-demo-subtle">Theme</span>
      <span class="am-segmented" role="group" aria-label="Theme mode">Theme controls</span>
    </div>
  </div>
  <aside class="am-hero-showcase" aria-label="Preview">Preview</aside>
</header>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders OrderSummary with generic metadata, neutral hooks, escaped text, and live total semantics" do
    html = Components::DesignSystem::OrderSummary.new(
      id: "checkout-summary",
      label: "Checkout <summary>",
      seat_id: "team-seats",
      seat_min: "2",
      seat_max: "8",
      seat_value: "4",
      seat_hint_suffix: "licenses",
      seat_price: "45",
      period: "/mo",
      add_ons: [
        Components::DesignSystem::OrderSummary::AddOn.new("Audit <pack>", "180", true),
      ],
      total_label: "Due monthly",
      total: "$360/mo",
      note: "Updates live.",
      data_view: "checkout"
    ).render

    html.should eq(%(<aside class="am-summary" id="checkout-summary" data-component="order-summary" data-ap-pricing data-ap-pricing-seat-price="45" data-ap-pricing-billing="monthly" data-ap-pricing-currency="$" data-ap-pricing-period="/mo" data-view="checkout" aria-label="Checkout &lt;summary&gt;">
  <strong>Checkout &lt;summary&gt;</strong>
  <label for="team-seats" class="am-field" data-component="field"><span>Seats</span><input type="range" id="team-seats" name="team_seats" class="am-range" min="2" max="8" value="4" data-ap-pricing-seats=""><span class="am-field__hint"><span data-ap-pricing-seats-label>4</span> licenses</span></label>
  <div class="am-choice-grid">
    <label class="am-switch"><input type="checkbox" data-ap-pricing-addon value="180" checked> Audit &lt;pack&gt;</label>
  </div>
  <div class="am-summary-row"><span>Due monthly</span><strong data-ap-pricing-total aria-live="polite" aria-atomic="true">$360/mo</strong></div>
  <span class="am-demo-subtle" data-ap-pricing-note aria-live="polite">Updates live.</span>
</aside>))
    html.should_not contain("data-amber-pricing")
    expect_no_bootstrap_shaped_classes(html)
  end

  it "omits OrderSummary optional add-on, total, and note groups when empty" do
    html = Components::DesignSystem::OrderSummary.new(
      label: "Quiet summary",
      seat_id: "quiet-seats"
    ).render

    html.should eq(%(<aside class="am-summary" data-component="order-summary" aria-label="Quiet summary">
  <strong>Quiet summary</strong>
  <label for="quiet-seats" class="am-field" data-component="field"><span>Seats</span><input type="range" id="quiet-seats" name="quiet_seats" class="am-range" min="1" max="40" value="1" data-ap-pricing-seats=""><span class="am-field__hint"><span data-ap-pricing-seats-label>1</span> seats selected</span></label>
</aside>))
    html.should_not contain("am-choice-grid")
    html.should_not contain("am-summary-row")
    html.should_not contain("aria-live")
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders OrderSummary in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::OrderSummary.new(
      label: "Interactive order summary",
      seat_id: "pricing-seats",
      seat_min: "3",
      seat_max: "40",
      seat_value: "12",
      add_ons: [
        Components::DesignSystem::OrderSummary::AddOn.new("Accessibility audit add-on", "180", true),
        Components::DesignSystem::OrderSummary::AddOn.new("Launch-room transcript pack", "90"),
      ],
      total_label: "Billing",
      total: "$1,188/mo",
      note: "Annual billing saves 18%.",
      compatibility_markup: "demo"
    ).render

    html.should eq(%(<aside class="am-summary" data-amber-pricing data-ap-pricing aria-label="Interactive order summary">
  <strong>Interactive order summary</strong>
  <label for="pricing-seats" class="am-field" data-component="field"><span>Seats</span><input type="range" id="pricing-seats" name="pricing_seats" class="am-range" min="3" max="40" value="12" data-amber-pricing-seats="" data-ap-pricing-seats=""><span class="am-field__hint"><span data-amber-pricing-seats-label data-ap-pricing-seats-label>12</span> seats selected</span></label>
  <div class="am-choice-grid">
    <label class="am-switch"><input type="checkbox" data-amber-pricing-addon data-ap-pricing-addon value="180" checked> Accessibility audit add-on</label>
    <label class="am-switch"><input type="checkbox" data-amber-pricing-addon data-ap-pricing-addon value="90"> Launch-room transcript pack</label>
  </div>
  <div class="am-summary-row"><span>Billing</span><strong data-amber-pricing-total data-ap-pricing-total>$1,188/mo</strong></div>
  <span class="am-demo-subtle" data-amber-pricing-note data-ap-pricing-note aria-live="polite">Annual billing saves 18%.</span>
</aside>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageHero with the current demo-compatible anatomy" do
    html = Components::DesignSystem::PageHero.new(
      kicker: "Frontloader Studio",
      title: "Ship clearer work",
      body: "A calm command center for launch teams."
    ).build do |hero|
      hero << Components::Elements::RawHTML.new(%(<aside class="am-panel" data-tone="accent"><strong>Live proof</strong></aside>))
    end.render

    html.should eq(%(<header class="am-page-hero"><div><div class="am-kicker">Frontloader Studio</div><h1 class="am-page-title">Ship clearer work</h1><p class="am-demo-copy">A calm command center for launch teams.</p></div><aside class="am-panel" data-tone="accent"><strong>Live proof</strong></aside></header>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageHero with optional passthrough attributes and copy alias" do
    hero = Components::DesignSystem::PageHero.new(
      id: "overview-hero",
      label: "Overview",
      kicker: "Dashboard",
      title: "Launch overview",
      copy: "Teams can scan the state of work."
    )
    hero["class"] = "is-featured"
    html = hero.render

    html.should eq(%(<header class="am-page-hero is-featured" id="overview-hero" aria-label="Overview"><div><div class="am-kicker">Dashboard</div><h1 class="am-page-title">Launch overview</h1><p class="am-demo-copy">Teams can scan the state of work.</p></div></header>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageHero in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::PageHero.new(
      kicker: "Pricing and payment",
      title: "Plans that prove form states.",
      body: "The pricing page uses realistic inputs.",
      compatibility_markup: "demo"
    ).build do |hero|
      hero << Components::Elements::RawHTML.new(%(<aside class="am-summary">Summary</aside>))
    end.render

    html.should eq(<<-HTML
    <header class="am-page-hero">
      <div>
        <div class="am-kicker">Pricing and payment</div>
        <h1 class="am-page-title">Plans that prove form states.</h1>
        <p class="am-demo-copy">The pricing page uses realistic inputs.</p>
      </div>
      <aside class="am-summary">Summary</aside>
    </header>
    HTML
    )
  end

  it "renders DashboardShell with the current dashboard shell anatomy" do
    nav_html = %(<nav><a href="#overview">Overview</a></nav>)
    main_html = %(<h1 id="dashboard-title">Dashboard</h1><p>Launch health</p>)

    html = Components::DesignSystem::DashboardShell.new(
      sidebar_html: nav_html,
      body_html: main_html
    ).render

    html.should eq(%(<section class="am-section" aria-labelledby="dashboard-title"><div class="am-dashboard-shell"><aside class="am-sidebar" aria-label="Dashboard sections">#{nav_html}</aside><div class="am-dashboard-main">#{main_html}</div></div></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders DashboardShell with generic labels, main_html alias, and safe passthrough attributes" do
    shell = Components::DesignSystem::DashboardShell.new(
      id: "operations-dashboard",
      title_id: "ops-title",
      sidebar_label: "Operations sections",
      sidebar_html: %(<nav aria-label="Operations"><a href="#queue">Queue</a></nav>),
      main_html: %(<h1 id="ops-title">Operations</h1>)
    )
    shell["class"] = "is-condensed"
    shell["data-view"] = "dashboard"
    shell["aria_describedby"] = "ops-summary"

    html = shell.render

    html.should eq(%(<section class="am-section is-condensed" id="operations-dashboard" aria-labelledby="ops-title" data-view="dashboard" aria-describedby="ops-summary"><div class="am-dashboard-shell"><aside class="am-sidebar" aria-label="Operations sections"><nav aria-label="Operations"><a href="#queue">Queue</a></nav></aside><div class="am-dashboard-main"><h1 id="ops-title">Operations</h1></div></div></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders DashboardShell in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::DashboardShell.new(
      sidebar_html: %(<strong>Frontloader</strong>),
      body_html: %(<div class="am-dashboard-toolbar">Toolbar</div>),
      compatibility_markup: "demo"
    ).render

    html.should eq(<<-HTML
    <section class="am-section" aria-labelledby="dashboard-title">
      <div class="am-dashboard-shell">
        <aside class="am-sidebar" aria-label="Dashboard sections">
          <strong>Frontloader</strong>
        </aside>
        <div class="am-dashboard-main">
          <div class="am-dashboard-toolbar">Toolbar</div>
        </div>
      </div>
    </section>
    HTML
    )
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageLinkCard with the current overview page-card anatomy" do
    html = Components::DesignSystem::PageLinkCard.new(
      href: "dashboard.html",
      title: "Dashboard",
      summary: "Metrics, filters, tables, charts, and command palette."
    ).render

    html.should eq(%(<a class="am-page-card" href="dashboard.html"><strong>Dashboard</strong><span>Metrics, filters, tables, charts, and command palette.</span><small>Open dashboard</small></a>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageLinkCard with body/copy aliases, custom action label, and passthrough hooks" do
    body_html = Components::DesignSystem::PageLinkCard.new(
      href: "patterns.html",
      title: "Patterns",
      body: "Tabs, carousel, disclosure, dialog, and toast.",
      action_label: "Open patterns proof"
    ).render

    copy_card = Components::DesignSystem::PageLinkCard.new(
      href: "timeline.html",
      title: "Timeline",
      copy: "Milestones and delivery rhythm.",
      aria_label: "Open timeline page"
    )
    copy_card["id"] = "timeline-card"
    copy_card["class"] = "is-featured"
    copy_card["data-page"] = "timeline"
    copy_html = copy_card.render

    body_html.should eq(%(<a class="am-page-card" href="patterns.html"><strong>Patterns</strong><span>Tabs, carousel, disclosure, dialog, and toast.</span><small>Open patterns proof</small></a>))
    copy_html.should eq(%(<a class="am-page-card is-featured" href="timeline.html" id="timeline-card" aria-label="Open timeline page" data-page="timeline"><strong>Timeline</strong><span>Milestones and delivery rhythm.</span><small>Open timeline</small></a>))
    expect_no_bootstrap_shaped_classes(body_html + copy_html)
  end

  it "renders PageLinkCardGrid with generic component metadata" do
    grid = Components::DesignSystem::PageLinkCardGrid.new(
      id: "overview-pages",
      aria_label: "Generated proof pages"
    )
    grid["class"] = "is-featured"
    grid["data-view"] = "overview"
    html = grid.build do |layout|
      layout << Components::Elements::RawHTML.new(
        Components::DesignSystem::PageLinkCard.new(
          href: "dashboard.html",
          title: "Dashboard",
          summary: "Metrics and controls."
        ).render
      )
    end.render

    html.should eq(%(<div class="am-page-card-grid is-featured" id="overview-pages" data-component="page-link-card-grid" aria-label="Generated proof pages" data-view="overview"><a class="am-page-card" href="dashboard.html"><strong>Dashboard</strong><span>Metrics and controls.</span><small>Open dashboard</small></a></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders PageLinkCardGrid in demo compatibility mode without extra metadata" do
    html = Components::DesignSystem::PageLinkCardGrid.new(
      compatibility_markup: "demo"
    ).build do |layout|
      layout << Components::Elements::RawHTML.new(
        Components::DesignSystem::PageLinkCard.new(
          href: "forms.html",
          title: "Forms",
          summary: "Auth and payment flows."
        ).render
      )
    end.render

    html.should eq(%(<div class="am-page-card-grid"><a class="am-page-card" href="forms.html"><strong>Forms</strong><span>Auth and payment flows.</span><small>Open forms</small></a></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Divider with the current divider anatomy" do
    html = Components::DesignSystem::Divider.new(
      label: "Interactions"
    ).render

    html.should eq(%(<div class="am-divider"><span>Interactions</span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Divider with optional passthrough attributes" do
    divider = Components::DesignSystem::Divider.new(
      id: "patterns-divider",
      label: "Patterns <proof>",
      aria_label: "Pattern groups"
    )
    divider["class"] = "is-compact"
    divider["data-section"] = "patterns"
    html = divider.render

    html.should eq(%(<div class="am-divider is-compact" id="patterns-divider" aria-label="Pattern groups" data-section="patterns"><span>Patterns &lt;proof&gt;</span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders VisualBand with the current parallax-style band anatomy and raw child slot" do
    child = %(<svg viewBox="0 0 120 40" aria-hidden="true"><path d="M0 20h120"></path></svg>)

    html = Components::DesignSystem::VisualBand.new(
      title: "Motion without runtime",
      body: "SVG and token-backed CSS carry the composition."
    ).build do |band|
      band << Components::Elements::RawHTML.new(child)
    end.render

    html.should eq(%(<div class="am-parallax-band"><strong>Motion without runtime</strong><p>SVG and token-backed CSS carry the composition.</p>#{child}</div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders VisualBand with copy alias and optional passthrough attributes" do
    band = Components::DesignSystem::VisualBand.new(
      id: "visual-proof",
      title: "Static <band>",
      copy: "Escaped body & text.",
      aria_describedby: "visual-proof-note"
    )
    band["class"] = "is-featured"
    band["data-proof"] = "visual-band"
    html = band.render

    html.should eq(%(<div class="am-parallax-band is-featured" id="visual-proof" aria-describedby="visual-proof-note" data-proof="visual-band"><strong>Static &lt;band&gt;</strong><p>Escaped body &amp; text.</p></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders VisualBand in demo compatibility mode with stable existing whitespace" do
    svg = %(<svg viewBox="0 0 120 40" aria-hidden="true"><path d="M0 20h120"></path></svg>)
    html = Components::DesignSystem::VisualBand.new(
      title: "CSS/SVG first parallax-style band",
      body: "Deterministic visual assets keep the demo self-contained.",
      compatibility_markup: "demo"
    ).build do |band|
      band << Components::Elements::RawHTML.new(svg)
    end.render

    html.should eq(<<-HTML
    <div class="am-parallax-band">
        <strong>CSS/SVG first parallax-style band</strong>
        <p>Deterministic visual assets keep the demo self-contained.</p>
        #{svg}
      </div>
    HTML
    )
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Section and Panel with explicit accessible names" do
    section = Components::DesignSystem::Section.new(
      id: "reports",
      label: "Reports without heading",
      spacing: "compact"
    ).render

    panel = Components::DesignSystem::Panel.new(
      id: "billing-panel",
      title: "Billing",
      subtitle: "Invoice status",
      tone: "info",
      raised: "true"
    ).build { |p| p << "Paid" }.render

    section.should contain(%(<section class="am-section am-section--compact" id="reports" data-component="section" aria-label="Reports without heading">))
    panel.should contain(%(<section class="am-panel am-panel--info am-panel--raised" id="billing-panel" data-component="panel" data-tone="info" role="region" aria-labelledby="billing-panel-title">))
    panel.should contain(%(<h3 class="am-panel__title" id="billing-panel-title">Billing</h3>))
    panel.should contain(%(<p class="am-panel__subtitle">Invoice status</p>))
    panel.should contain(%(<div class="am-panel__body">Paid</div>))
    expect_no_bootstrap_shaped_classes(section + panel)
  end

  it "renders Section in demo compatibility mode without changing existing anatomy" do
    html = Components::DesignSystem::Section.new(
      title_id: "plans-title",
      title: "Plan comparison",
      subtitle: "Billing controls are native buttons and inputs.",
      compatibility_markup: "demo"
    ).build do |section|
      section << Components::Elements::RawHTML.new(%(<div class="am-three-col">Plans</div>))
    end.render

    html.should eq(%(<section class="am-section" aria-labelledby="plans-title"><div class="am-section-header"><h2 id="plans-title">Plan comparison</h2><p>Billing controls are native buttons and inputs.</p></div><div class="am-three-col">Plans</div></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Panel in demo compatibility mode without adding wrapper anatomy" do
    html = Components::DesignSystem::Panel.new(
      tag: "aside",
      tone: "accent",
      label: "Payment states demonstrated",
      compatibility_markup: "demo"
    ).build do |panel|
      panel << Components::Elements::RawHTML.new(%(<strong>Payment states demonstrated</strong>))
    end.render

    html.should eq(%(<aside class="am-panel" data-tone="accent" aria-label="Payment states demonstrated"><strong>Payment states demonstrated</strong></aside>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Metric with the current repeated metric anatomy" do
    html = Components::DesignSystem::Metric.new(
      label: "Ready",
      value: "82%",
      body: "Up 12% after form audit."
    ).render

    html.should eq(%(<div class="am-metric"><span class="am-demo-subtle">Ready</span><strong>82%</strong><span>Up 12% after form audit.</span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Metric with copy alias and optional passthrough attributes" do
    metric = Components::DesignSystem::Metric.new(
      id: "runtime-metric",
      label: "Runtime",
      value: "0",
      copy: "No build tooling.",
      aria_label: "Runtime dependency count"
    )
    metric["class"] = "is-highlighted"
    metric["data-state"] = "selected"
    metric["aria-current"] = "true"
    html = metric.render

    html.should eq(%(<div class="am-metric is-highlighted" id="runtime-metric" aria-label="Runtime dependency count" data-state="selected" aria-current="true"><span class="am-demo-subtle">Runtime</span><strong>0</strong><span>No build tooling.</span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LayoutGrid with generic component metadata" do
    grid = Components::DesignSystem::LayoutGrid.new(
      id: "proof-grid",
      kind: "three",
      aria_label: "Proof cards"
    )
    grid["class"] = "is-dense"
    grid["data-view"] = "proof"
    html = grid.build { |layout| layout << "<article>One</article>" }.render

    html.should eq(%(<div class="am-three-col is-dense" id="proof-grid" data-component="layout-grid" data-layout-kind="three" aria-label="Proof cards" data-view="proof">&lt;article&gt;One&lt;/article&gt;</div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LayoutGrid in demo compatibility mode without extra metadata" do
    html = Components::DesignSystem::LayoutGrid.new(
      kind: "metric",
      compatibility_markup: "demo"
    ).build do |layout|
      layout << Components::Elements::RawHTML.new(%(<div class="am-metric">Ready</div>))
    end.render

    html.should eq(%(<div class="am-metric-grid"><div class="am-metric">Ready</div></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "rejects unknown LayoutGrid kinds" do
    expect_raises(ArgumentError, "Unknown layout grid kind: carousel") do
      Components::DesignSystem::LayoutGrid.new(kind: "carousel").render
    end
  end

  it "renders TerminalPreview with the current overview terminal anatomy" do
    html = Components::DesignSystem::TerminalPreview.new(
      commands: [
        "$ crystal run examples/web_design_system_demo.cr",
        "Generated output/web-design-system-demo.html",
        "Validated light, dark, reduced motion, keyboard, and accessibility states.",
      ]
    ).render

    html.should eq(%(<div class="am-terminal" role="region" aria-label="Static generation terminal preview"><div class="am-terminal-line">$ crystal run examples/web_design_system_demo.cr</div><div class="am-terminal-line">Generated output/web-design-system-demo.html</div><div class="am-terminal-line">Validated light, dark, reduced motion, keyboard, and accessibility states.</div></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders TerminalPreview with lines alias and optional passthrough attributes" do
    preview = Components::DesignSystem::TerminalPreview.new(
      id: "build-terminal",
      label: "Build output",
      lines: [
        "$ crystal spec spec/components/design_system/primitives_spec.cr",
        "Escaped <status> & \"quotes\"",
      ],
      aria_describedby: "build-terminal-note"
    )
    preview["class"] = "is-compact"
    preview["data-state"] = "complete"
    html = preview.render

    html.should eq(%(<div class="am-terminal is-compact" id="build-terminal" role="region" aria-label="Build output" aria-describedby="build-terminal-note" data-state="complete"><div class="am-terminal-line">$ crystal spec spec/components/design_system/primitives_spec.cr</div><div class="am-terminal-line">Escaped &lt;status&gt; &amp; &quot;quotes&quot;</div></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders TerminalPreview in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::TerminalPreview.new(
      commands: [
        "crystal run examples/web_design_system_demo.cr",
        "crystal run scripts/validate_web_demo.cr",
      ],
      compatibility_markup: "demo"
    ).render

    html.should eq(%(<div class="am-terminal" role="region" aria-label="Static generation terminal preview">
      <div class="am-terminal-line">crystal run examples/web_design_system_demo.cr</div>
      <div class="am-terminal-line">crystal run scripts/validate_web_demo.cr</div>
    </div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders ShowcasePreview with generic component metadata and escaped text" do
    preview = Components::DesignSystem::ShowcasePreview.new(
      id: "launch-preview",
      label: "Launch preview",
      window_title: "Launch <command>",
      rail_items: ["Plan", "Ship"],
      active_rail_item: "Ship",
      eyebrow: "Launch <health>",
      headline: "Ready & steady",
      badge_html: %(<span class="am-badge" data-component="badge">AA checked</span>),
      list_label: "Workflow <steps>",
      steps: [
        Components::DesignSystem::ShowcasePreview::Step.new("Assets <compiled>", "CSS variables & charts.", %(<span class="am-badge">Done</span>)),
      ],
      sticky_hover: "false",
      data_view: "overview"
    )
    preview["class"] = "is-raised"
    html = preview.render

    html.should eq(%(<aside class="am-hero-showcase is-raised" id="launch-preview" data-component="showcase-preview" data-view="overview" aria-label="Launch preview">
    <div class="am-window-chrome">
      <span class="am-window-dots" aria-hidden="true"><span></span><span></span><span></span></span>
      <strong>Launch &lt;command&gt;</strong>
    </div>
    <div class="am-showcase-body">
      <div class="am-showcase-rail" role="list" aria-label="Preview sections">
        <span class="am-showcase-pill" role="listitem">Plan</span>
        <span class="am-showcase-pill" role="listitem" data-active="true" aria-current="true">Ship</span>
      </div>
      <div class="am-showcase-main">
        <div class="am-showcase-headline">
          <div><span class="am-demo-subtle">Launch &lt;health&gt;</span><strong>Ready &amp; steady</strong></div>
          <span class="am-badge" data-component="badge">AA checked</span>
        </div>
        <div class="am-journey-map" role="list" aria-label="Workflow &lt;steps&gt;">
          <div class="am-journey-step" role="listitem"><span class="am-step-index">1</span><div><strong>Assets &lt;compiled&gt;</strong><div class="am-demo-subtle">CSS variables &amp; charts.</div></div><span class="am-badge">Done</span></div>
        </div>
      </div>
    </div>
  </aside>))
    html.should_not contain("data-ap-sticky-hover")
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders ShowcasePreview default output without empty static rail or step lists" do
    html = Components::DesignSystem::ShowcasePreview.new(
      label: "Empty preview",
      window_title: "Preview shell",
      eyebrow: "Status",
      headline: "Waiting",
      sticky_hover: "false"
    ).render

    html.should eq(%(<aside class="am-hero-showcase" data-component="showcase-preview" aria-label="Empty preview">
    <div class="am-window-chrome">
      <span class="am-window-dots" aria-hidden="true"><span></span><span></span><span></span></span>
      <strong>Preview shell</strong>
    </div>
    <div class="am-showcase-body">
      <div class="am-showcase-main">
        <div class="am-showcase-headline">
          <div><span class="am-demo-subtle">Status</span><strong>Waiting</strong></div>
        </div>
      </div>
    </div>
  </aside>))
    html.should_not contain(%(class="am-showcase-rail"))
    html.should_not contain(%(class="am-journey-map"))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders ShowcasePreview in demo compatibility mode with stable existing whitespace" do
    html = Components::DesignSystem::ShowcasePreview.new(
      label: "Frontloader product interface preview",
      window_title: "Launch command",
      rail_label: "Preview sections",
      rail_items: ["Plan", "Ship", "Learn"],
      active_rail_item: "Plan",
      eyebrow: "Launch health",
      headline: "Ready in 18h",
      badge_html: %(<span class="am-badge am-badge--success" data-component="badge" data-tone="success">AA checked</span>),
      list_label: "Launch readiness workflow",
      steps: [
        Components::DesignSystem::ShowcasePreview::Step.new("Assets compiled", "CSS variables, SVG charts, and font strategies ready.", %(<span class="am-badge am-badge--success" data-component="badge" data-tone="success">Done</span>)),
        Components::DesignSystem::ShowcasePreview::Step.new("Pricing validated", "Seat totals, add-ons, and payment fields respond in browser.", %(<span class="am-badge am-badge--warning" data-component="badge" data-tone="warning">Review</span>)),
        Components::DesignSystem::ShowcasePreview::Step.new("Demo evidence", "Screenshots and CDP audits capture the current surface.", %(<span class="am-badge am-badge--brand" data-component="badge" data-tone="brand">Queued</span>)),
      ],
      compatibility_markup: "demo"
    ).render

    html.should eq(%(<aside class="am-hero-showcase" data-amber-sticky-hover data-ap-sticky-hover aria-label="Frontloader product interface preview">
    <div class="am-window-chrome">
      <span class="am-window-dots" aria-hidden="true"><span></span><span></span><span></span></span>
      <strong>Launch command</strong>
    </div>
    <div class="am-showcase-body">
      <nav class="am-showcase-rail" aria-label="Preview sections">
        <span class="am-showcase-pill" data-active="true">Plan</span>
        <span class="am-showcase-pill">Ship</span>
        <span class="am-showcase-pill">Learn</span>
      </nav>
      <div class="am-showcase-main">
        <div class="am-showcase-headline">
          <div><span class="am-demo-subtle">Launch health</span><strong>Ready in 18h</strong></div>
          <span class="am-badge am-badge--success" data-component="badge" data-tone="success">AA checked</span>
        </div>
        <div class="am-journey-map" role="list" aria-label="Launch readiness workflow">
          <div class="am-journey-step" role="listitem"><span class="am-step-index">1</span><div><strong>Assets compiled</strong><div class="am-demo-subtle">CSS variables, SVG charts, and font strategies ready.</div></div><span class="am-badge am-badge--success" data-component="badge" data-tone="success">Done</span></div>
          <div class="am-journey-step" role="listitem"><span class="am-step-index">2</span><div><strong>Pricing validated</strong><div class="am-demo-subtle">Seat totals, add-ons, and payment fields respond in browser.</div></div><span class="am-badge am-badge--warning" data-component="badge" data-tone="warning">Review</span></div>
          <div class="am-journey-step" role="listitem"><span class="am-step-index">3</span><div><strong>Demo evidence</strong><div class="am-demo-subtle">Screenshots and CDP audits capture the current surface.</div></div><span class="am-badge am-badge--brand" data-component="badge" data-tone="brand">Queued</span></div>
        </div>
      </div>
    </div>
  </aside>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Badge with a generic component marker and semantic tone" do
    html = Components::DesignSystem::Badge.new(
      label: "Active",
      tone: "success",
      role: "status"
    ).render

    html.should eq(%(<span class="am-badge am-badge--success" data-component="badge" data-tone="success" role="status">Active</span>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Alert with live-region semantics" do
    html = Components::DesignSystem::Alert.new(
      id: "sync-alert",
      title: "Sync failed",
      body: "Try again.",
      tone: "danger",
      hidden: "true"
    ).render

    html.should contain(%(<div class="am-alert am-alert--danger" id="sync-alert" data-component="alert" data-tone="danger" role="alert" aria-live="assertive" aria-atomic="true" aria-labelledby="sync-alert-title" hidden>))
    html.should contain(%(<div class="am-alert__title" id="sync-alert-title">Sync failed</div>))
    html.should contain(%(<div class="am-alert__body">Try again.</div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders EmptyState as a labelled section with optional actions" do
    html = Components::DesignSystem::EmptyState.new(
      id: "empty-search",
      title: "No matching records",
      body: "Change filters and retry."
    ).build do |state|
      state << Components::DesignSystem::Badge.new(label: "Filtered", tone: "info")
    end.render

    html.should contain(%(<section class="am-empty-state" id="empty-search" data-component="empty-state" aria-labelledby="empty-search-title">))
    html.should contain(%(<h2 class="am-empty-state__title" id="empty-search-title">No matching records</h2>))
    html.should contain(%(<p class="am-empty-state__body">Change filters and retry.</p>))
    html.should contain(%(<div class="am-empty-state__actions"><span class="am-badge am-badge--info" data-component="badge" data-tone="info">Filtered</span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders EmptyState in demo compatibility mode without changing existing anatomy" do
    html = Components::DesignSystem::EmptyState.new(
      title: "No unresolved blockers in this room",
      body: "The empty state is specific, calm, and paired with the next action.",
      compatibility_markup: "demo"
    ).build do |state|
      state << Components::Elements::RawHTML.new(%(<button class="am-button" type="button">Start review</button>))
    end.render

    html.should eq(%(<section class="am-empty"><strong>No unresolved blockers in this room</strong><span class="am-demo-subtle">The empty state is specific, calm, and paired with the next action.</span><button class="am-button" type="button">Start review</button></section>))
  end

  it "renders Skeleton as a named status region with hidden decorative items" do
    html = Components::DesignSystem::Skeleton.new(
      label: "Loading reports",
      count: "2"
    ).render

    html.should contain(%(<div class="am-skeleton" data-component="skeleton" role="status" aria-label="Loading reports">))
    html.should contain(%(<span class="am-visually-hidden">Loading reports</span>))
    html.should contain(%(<span class="am-skeleton__item" aria-hidden="true"></span>))
    html.should contain(%(<span class="am-skeleton__item am-skeleton__item--short" aria-hidden="true"></span>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Toast with notification semantics and neutral behavior hooks" do
    html = Components::DesignSystem::Toast.new(
      id: "saved-toast",
      title: "Saved",
      body: "Changes are available.",
      tone: "success",
      dismiss_label: "Dismiss notification",
      action_label: "View"
    ).render

    html.should contain(%(<div class="am-toast am-toast--success" id="saved-toast" data-component="toast" data-tone="success" role="status" aria-live="polite" aria-atomic="true" aria-labelledby="saved-toast-title">))
    html.should contain(%(<div class="am-toast__title" id="saved-toast-title">Saved</div>))
    html.should contain(%(<div class="am-toast__body">Changes are available.</div>))
    html.should contain(%(<button class="am-toast__dismiss" type="button" aria-label="Dismiss notification" data-amber-toast-dismiss data-ap-toast-dismiss>&times;</button>))
    html.should contain(%(<button class="am-button am-button--neutral am-button--ghost am-button--sm" type="button">View</button>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders deterministic Toast markup when an id is supplied" do
    first = Components::DesignSystem::Toast.new(
      id: "stable-toast",
      body: "Saved.",
      tone: "neutral",
      action_label: "View"
    ).render
    second = Components::DesignSystem::Toast.new(
      id: "stable-toast",
      body: "Saved.",
      tone: "neutral",
      action_label: "View"
    ).render

    first.should eq(second)
  end

  it "renders Progress with native progress semantics" do
    html = Components::DesignSystem::Progress.new(
      id: "upload-progress",
      label: "Upload",
      value: "40",
      max: "100",
      value_label: "40%",
      tone: "info"
    ).render

    html.should contain(%(<div class="am-progress-field" id="upload-progress" data-component="progress">))
    html.should contain(%(<span class="am-progress-field__label" id="upload-progress-label">Upload</span>))
    html.should contain(%(<span class="am-progress-field__value" id="upload-progress-value">40%</span>))
    html.should contain(%(<progress class="am-progress am-progress--info" max="100" aria-labelledby="upload-progress-label" value="40" aria-describedby="upload-progress-value"></progress>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Progress in demo compatibility mode without changing existing anatomy" do
    html = Components::DesignSystem::Progress.new(
      label: "Timeline SVG upload progress",
      value: "72",
      compatibility_markup: "demo"
    ).render

    html.should eq(%(<div class="am-progress" role="progressbar" aria-label="Timeline SVG upload progress" aria-valuemin="0" aria-valuemax="100" aria-valuenow="72"><span style="width: 72%;"></span></div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders ChatPanel with byte-stable collaboration anatomy and vanilla hooks" do
    messages = %(<article class="am-message"><strong>Mina</strong><span>The pricing calculator now mirrors the order summary.</span></article><article class="am-message"><strong>Theo</strong><span>@design please review the dark-mode table warning row.</span></article><article class="am-message" data-own="true"><strong>You</strong><span>I am checking keyboard focus and dialog return behavior.</span></article>)
    field = %(<label class="am-field" for="chat-message">Message<input class="am-input" id="chat-message" type="text" name="message" required placeholder="Write a launch note"></label>)
    action = %(<button class="am-button am-button--brand am-button--solid am-button--md" type="submit">Send</button>)
    html = Components::DesignSystem::ChatPanel.new(
      title: "Review chat",
      title_id: "chat-title",
      messages_html: messages,
      field_html: field,
      action_html: action
    ).build do |panel|
      panel << Components::DesignSystem::Badge.new(label: "Live", tone: "success")
    end.render

    html.should eq(%(<section class="am-panel am-chat-panel" aria-labelledby="chat-title"><div class="am-window-chrome"><strong id="chat-title">Review chat</strong><span class="am-badge am-badge--success" data-component="badge" data-tone="success">Live</span></div><div class="am-chat-log" data-amber-chat-log data-ap-chat-log role="log" aria-live="polite">#{messages}</div><form class="am-chat-form" data-amber-chat-form data-ap-chat-form>#{field}#{action}</form></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders LiveSearchPanel with current live search field and status hooks" do
    field = %(<label class="am-field" for="collab-search">Search records<input class="am-input" id="collab-search" type="search" placeholder="Try timeline, payment, command" data-amber-live-search data-ap-live-search></label>)
    html = Components::DesignSystem::LiveSearchPanel.new(
      title: "Live search",
      title_id: "search-title",
      field_html: field
    ).render

    html.should eq(%(<section class="am-panel" aria-labelledby="search-title"><h2 id="search-title" style="margin:0;">Live search</h2>#{field}<div class="am-search-results" data-amber-search-results data-ap-search-results role="status" aria-live="polite"></div></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders UploadQueue with byte-stable queue shell and supplied item/progress HTML" do
    uploaded = %(<div class="am-state-row"><span>pricing-dark.png</span><span class="am-badge am-badge--success" data-component="badge" data-tone="success">Uploaded</span></div>)
    progress = %(<div class="am-progress" role="progressbar" aria-label="Timeline SVG upload progress" aria-valuemin="0" aria-valuemax="100" aria-valuenow="72"><span style="width: 72%;"></span></div>)
    pending = %(<div class="am-state-row"><span>timeline.svg</span><span class="am-badge am-badge--warning" data-component="badge" data-tone="warning">72%</span></div>)
    html = Components::DesignSystem::UploadQueue.new(
      title: "Upload queue",
      title_id: "upload-title",
      item_html: uploaded,
      progress_html: progress
    ).build do |queue|
      queue << Components::Elements::RawHTML.new(pending)
    end.render

    html.should eq(%(<section class="am-panel" aria-labelledby="upload-title"><h2 id="upload-title" style="margin:0;">Upload queue</h2><div class="am-upload-queue">#{uploaded}#{progress}#{pending}</div></section>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Disclosure with owned panel semantics and neutral behavior hooks" do
    html = Components::DesignSystem::Disclosure.new(
      id: "details",
      label: "Show advanced settings",
      panel_label: "Advanced settings"
    ).build { |disclosure| disclosure << "Advanced settings stay hidden until requested." }.render

    html.should contain(%(<div class="am-disclosure" id="details" data-component="disclosure">))
    html.should contain(%(<button class="am-button am-button--neutral am-button--outline am-button--md" type="button" data-amber-disclosure data-ap-disclosure aria-expanded="false" aria-controls="details-panel">Show advanced settings</button>))
    html.should contain(%(<div class="am-disclosure__panel" id="details-panel" aria-label="Advanced settings" hidden>Advanced settings stay hidden until requested.</div>))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Disclosure in demo compatibility mode without changing current button anatomy" do
    panel = Components::DesignSystem::Alert.new(
      id: "advanced-panel",
      body: "Advanced settings are hidden until requested.",
      tone: "warning",
      role: "status",
      hidden: "true"
    ).render
    html = Components::DesignSystem::Disclosure.new(
      label: "Show advanced settings",
      panel_id: "advanced-panel",
      compatibility_markup: "demo"
    ).build do |disclosure|
      disclosure << Components::Elements::RawHTML.new(panel)
    end.render

    html.should start_with(%(<button type="button" class="am-button am-button--neutral am-button--outline am-button--md" data-state="default" data-tone="neutral" data-emphasis="outline" data-amber-disclosure="" data-ap-disclosure="" aria-expanded="false" aria-controls="advanced-panel">Show advanced settings</button>))
    html.should contain(%(<div class="am-alert am-alert--warning" id="advanced-panel" data-component="alert" data-tone="warning" role="status" aria-live="polite" aria-atomic="true" hidden>))
    expect_live_region(html, "advanced-panel")
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders Fieldset with hidden legend and optional description wiring" do
    html = Components::DesignSystem::Fieldset.new(
      legend: "Card details",
      described_by: "payment-status"
    ).build do |fieldset|
      fieldset << Components::Elements::RawHTML.new(%(<label class="am-field">Card number<input class="am-input" required></label>))
    end.render

    html.should contain(%(<fieldset class="am-form-fieldset" aria-describedby="payment-status">))
    html.should contain(%(<legend class="am-visually-hidden">Card details</legend>))
    html.should contain(%(<label class="am-field">Card number<input class="am-input" required></label>))
    expect_describedby_targets_exist(%(<div id="payment-status">Ready.</div>#{html}))
    expect_no_bootstrap_shaped_classes(html)
  end

  it "renders ValidatedForm with native validation hooks and live status" do
    html = Components::DesignSystem::ValidatedForm.new(
      id: "reset-form",
      label: "Password reset",
      status: "Enter your account email."
    ).build do |form|
      form << Components::Elements::RawHTML.new(%(<label>Email <input type="email" required></label>))
    end.render

    html.should contain(%(<form class="am-form am-panel" id="reset-form" data-component="validated-form" data-amber-validate data-ap-validate novalidate aria-describedby="reset-form-status" aria-label="Password reset" method="post">))
    html.should contain(%(<div class="am-form-status" id="reset-form-status" role="status" data-amber-form-status data-ap-form-status>Enter your account email.</div>))
    html.should contain(%(<label>Email <input type="email" required></label>))
    expect_live_region(html, "reset-form-status")
    expect_describedby_targets_exist(html)
    expect_no_bootstrap_shaped_classes(html)
  end
end
