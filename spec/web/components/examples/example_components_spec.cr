require "../../spec_helper"
require "../../../../src/components/examples/button_component"
require "../../../../src/components/examples/card_component"
require "../../../../src/components/examples/auth_form_component"
require "../../../../src/components/examples/carousel_component"
require "../../../../src/components/examples/command_palette_component"
require "../../../../src/components/examples/data_table_component"
require "../../../../src/components/examples/dialog_component"
require "../../../../src/components/examples/form_field_component"
require "../../../../src/components/examples/payment_form_component"
require "../../../../src/components/examples/pricing_card_component"
require "../../../../src/components/examples/simple_chart_component"
require "../../../../src/components/examples/schedule_heatmap_component"
require "../../../../src/components/examples/tabs_component"
require "../../../../src/components/examples/theme_switcher_component"
require "../../../../src/components/examples/timeline_component"
require "../../../../src/components/examples/counter_component"
require "../../../../src/components/examples/form_component"
require "../../../../src/components/examples/chat_component"
require "../../../../src/components/examples/live_search_component"

describe "Example Components" do
  describe Components::Examples::ButtonComponent do
    it "renders a basic button" do
      button = Components::Examples::ButtonComponent.new(label: "Click Me")
      rendered = button.render

      rendered.should contain("<button")
      rendered.should contain("Click Me")
      rendered.should contain("am-button am-button--brand am-button--solid am-button--md")
      rendered.should contain("data-state=\"default\"")
    end

    it "supports different variants and sizes" do
      button = Components::Examples::ButtonComponent.new(
        label: "Danger",
        tone: "danger",
        emphasis: "outline",
        size: "lg"
      )

      rendered = button.render
      rendered.should contain("am-button--danger")
      rendered.should contain("am-button--outline")
      rendered.should contain("am-button--lg")
    end

    it "can be disabled" do
      button = Components::Examples::ButtonComponent.new(
        label: "Disabled",
        disabled: "true"
      )

      rendered = button.render
      rendered.should contain("disabled=\"disabled\"")
      rendered.should contain("aria-disabled=\"true\"")
      rendered.should contain("data-state=\"disabled\"")
    end

    it "can render loading state semantics" do
      button = Components::Examples::ButtonComponent.new(
        label: "Saving",
        loading: "true"
      )

      rendered = button.render
      rendered.should contain("data-state=\"loading\"")
      rendered.should contain("aria-busy=\"true\"")
    end

    it "supports icons" do
      button = Components::Examples::ButtonComponent.new(
        label: "Save",
        icon: "+"
      )

      rendered = button.render
      rendered.should contain("<span class=\"am-button__icon\" aria-hidden=\"true\">+</span>")
      rendered.should contain("Save")
    end

    it "passes safe aria and data attributes through" do
      button = Components::Examples::ButtonComponent.new(
        label: "Open",
        "aria-controls": "panel",
        "data-amber-disclosure": ""
      )

      rendered = button.render
      rendered.should contain(%(aria-controls="panel"))
      rendered.should contain(%(data-amber-disclosure=""))
      rendered.should_not contain(%(label="Open"))
    end
  end

  describe Components::Examples::ThemeSwitcherComponent do
    it "renders a theme toggle using the canonical button contract" do
      rendered = Components::Examples::ThemeSwitcherComponent.new.render

      rendered.should contain(%(data-component="theme-switcher"))
      rendered.should contain(%(data-amber-theme-toggle=""))
      rendered.should contain(%(data-ap-theme-toggle=""))
      rendered.should contain(%(data-amber-theme-label))
      rendered.should contain(%(data-ap-theme-label))
      rendered.should contain(%(data-amber-theme-status))
      rendered.should contain(%(data-ap-theme-status))
      rendered.should contain(%(am-button am-button--neutral am-button--ghost am-button--sm))
      expect_behavior_hook_pair(rendered, "data-ap-theme-toggle", "data-amber-theme-toggle")
      expect_live_region(rendered)
    end

    it "renders explicit segmented light and dark controls" do
      rendered = Components::Examples::ThemeSwitcherComponent.new(mode: "segmented").render

      rendered.should contain(%(role="group"))
      rendered.should contain(%(data-amber-theme-set="light"))
      rendered.should contain(%(data-ap-theme-set="light"))
      rendered.should contain(%(data-amber-theme-set="dark"))
      rendered.should contain(%(data-ap-theme-set="dark"))
      rendered.should contain(%(aria-pressed="true"))
    end

    it "is reusable with caller supplied toggle copy and status" do
      rendered = Components::Examples::ThemeSwitcherComponent.new(
        label: "Use dark theme",
        status: "System theme active"
      ).render

      rendered.should contain("Use dark theme")
      rendered.should contain("System theme active")
      rendered.should contain(%(data-component="theme-switcher"))
    end
  end

  describe Components::Examples::FormFieldComponent do
    it "renders native email validation attributes" do
      rendered = Components::Examples::FormFieldComponent.new(
        label: "Email",
        id: "email",
        type: "email",
        autocomplete: "email",
        required: "true"
      ).render

      rendered.should contain(%(<label for="email" class="am-field" data-component="field">))
      rendered.should contain(%(<input type="email" id="email" name="email" class="am-input"))
      rendered.should contain(%(autocomplete="email"))
      rendered.should contain(%(required="required"))
      expect_accessible_control(rendered, "email")
      expect_no_duplicate_ids(rendered)
    end

    it "renders search hooks and live-region hint markup" do
      rendered = Components::Examples::FormFieldComponent.new(
        label: "Filter",
        id: "filter",
        type: "search",
        hint_html: %(<span id="filter-status" role="status">4 matching rows</span>),
        data_attrs: {"data-amber-filter" => "#table"}
      ).render

      rendered.should contain(%(data-amber-filter="#table"))
      rendered.should contain(%(<span id="filter-status" role="status">4 matching rows</span>))
      expect_accessible_control(rendered, "filter")
      expect_live_region(rendered, "filter-status")
    end

    it "renders select options" do
      rendered = Components::Examples::FormFieldComponent.new(
        label: "Team size",
        id: "team-size",
        type: "select",
        options: [
          Components::Examples::FormFieldComponent::Option.new("Choose one", ""),
          Components::Examples::FormFieldComponent::Option.new("3-10", "3-10"),
        ]
      ).render

      rendered.should contain(%(<select id="team-size" name="team_size" class="am-select">))
      rendered.should contain(%(<option value="">Choose one</option>))
      rendered.should contain(%(<option value="3-10">3-10</option>))
    end

    it "passes reusable validation, data, and aria attributes without demo-specific leakage" do
      rendered = Components::Examples::FormFieldComponent.new(
        label: "Launch URL",
        id: "launch-url",
        type: "url",
        required: "true",
        placeholder: "https://example.com",
        data_attrs: {"data-amber-preview" => "#preview"},
        aria_attrs: {"aria-describedby" => "launch-url-hint"}
      ).render

      rendered.should contain(%(type="url"))
      rendered.should contain(%(placeholder="https://example.com"))
      rendered.should contain(%(data-amber-preview="#preview"))
      rendered.should contain(%(aria-describedby="launch-url-hint"))
      rendered.should_not contain("Frontloader")
      rendered.should_not contain("pricing")
    end
  end

  describe Components::Examples::PricingCardComponent do
    it "renders a plan card composed from tokens and ButtonComponent" do
      rendered = Components::Examples::PricingCardComponent.new(
        name: "Studio",
        badge: "Recommended",
        badge_tone: "success",
        price: "$99",
        copy: "Launch operations.",
        featured: "true"
      ).render

      rendered.should contain(%(data-component="pricing-card"))
      rendered.should contain(%(data-featured="true"))
      rendered.should contain(%(data-tone="success"))
      rendered.should contain(%(<strong>$99</strong>))
      rendered.should contain(%(am-button am-button--brand am-button--solid am-button--md))
    end

    it "honors caller supplied plan copy and action variants" do
      rendered = Components::Examples::PricingCardComponent.new(
        name: "Team",
        badge: "Team",
        badge_tone: "info",
        price: "$25",
        period: "/month",
        copy: "Reusable pricing plan.",
        action: "Start Team",
        action_tone: "neutral",
        action_emphasis: "ghost"
      ).render

      rendered.should contain(%(data-component="pricing-card"))
      rendered.should contain(%(<strong>$25</strong>))
      rendered.should contain(%(<span>/month</span>))
      rendered.should contain("Reusable pricing plan.")
      rendered.should contain("Start Team")
      rendered.should contain("am-button--ghost")
      rendered.should_not contain("Choose Studio")
    end
  end

  describe Components::Examples::CardComponent do
    it "renders a basic card" do
      card = Components::Examples::CardComponent.new(
        title: "Card Title",
        subtitle: "Card Subtitle"
      )
      card << "Card content goes here"

      rendered = card.render
      rendered.should contain("<div class=\"am-card\"")
      rendered.should contain("<h3 class=\"am-card__title\">Card Title</h3>")
      rendered.should contain("<p class=\"am-card__subtitle\">Card Subtitle</p>")
      rendered.should contain("Card content goes here")
    end

    it "renders with an image" do
      card = Components::Examples::CardComponent.new(
        title: "Image Card",
        image_url: "/image.jpg",
        image_alt: "Test Image"
      )

      rendered = card.render
      rendered.should contain("<img src=\"/image.jpg\" alt=\"Test Image\" class=\"am-card__media\">")
    end

    it "renders without optional fields" do
      card = Components::Examples::CardComponent.new
      card << "Just content"

      rendered = card.render
      rendered.should contain("<div class=\"am-card\"")
      rendered.should contain("Just content")
      rendered.should_not contain("am-card__title")
      rendered.should_not contain("am-card__subtitle")
    end

    it "adds interaction semantics when marked interactive" do
      card = Components::Examples::CardComponent.new(title: "Selectable", interactive: "true", selected: "true")
      rendered = card.render

      rendered.should contain("role=\"button\"")
      rendered.should contain("tabindex=\"0\"")
      rendered.should contain("aria-pressed=\"true\"")
    end
  end

  describe Components::Examples::DataTableComponent do
    it "renders semantic row states with accessible labels" do
      table = Components::Examples::DataTableComponent.new
      rendered = table.render

      rendered.should contain("class=\"am-table\"")
      rendered.should contain(%(class="am-table-wrap" data-component="table"))
      rendered.should contain("data-state=\"danger\"")
      rendered.should contain("data-motion=\"row\"")
      rendered.should contain("aria-invalid=\"true\"")
      rendered.should contain("aria-selected=\"true\"")
      rendered.should contain("aria-label=\"Failed card update: Payment error\"")
      rendered.should contain("am-table__status")
    end

    it "renders empty state when no rows exist" do
      table = Components::Examples::DataTableComponent.new([] of Components::Examples::DataTableComponent::Row)
      rendered = table.render

      rendered.should contain("data-state=\"empty\"")
      rendered.should contain("No matching records")
    end
  end

  describe Components::Examples::CommandPaletteComponent do
    it "renders dialog semantics and command hooks" do
      palette = Components::Examples::CommandPaletteComponent.new(id: "test-command")
      rendered = palette.render

      rendered.should contain(%(data-component="command-palette"))
      rendered.should contain(%(data-amber-command-open="test-command"))
      rendered.should contain(%(data-ap-command-open="test-command"))
      rendered.should contain(%(data-amber-command-panel))
      rendered.should contain(%(data-ap-command-panel))
      rendered.should contain(%(role="dialog"))
      rendered.should contain(%(aria-modal="true"))
      rendered.should contain(%(aria-controls="test-command"))
      rendered.should contain(%(data-amber-command-search))
      rendered.should contain(%(data-ap-command-search))
      rendered.should contain(%(class="am-command-item"))
      rendered.should_not contain("btn btn-")
      expect_behavior_hook_pair(rendered, "data-ap-command-open", "data-amber-command-open", "test-command")
      expect_behavior_hook_pair(rendered, "data-ap-command-panel", "data-amber-command-panel")
      expect_relationship_targets_exist(rendered)
    end
  end

  describe Components::Examples::ScheduleHeatmapComponent do
    it "renders accessible hourly activity cells" do
      heatmap = Components::Examples::ScheduleHeatmapComponent.new(id: "launch-heatmap")
      rendered = heatmap.render

      rendered.should contain(%(data-component="schedule-heatmap"))
      rendered.should contain(%(aria-describedby="launch-heatmap-summary launch-heatmap-table-caption"))
      rendered.should contain(%(id="launch-heatmap-summary"))
      rendered.should contain(%(<caption id="launch-heatmap-table-caption">Schedule heatmap table fallback</caption>))
      rendered.should contain(%(role="list"))
      rendered.should contain(%(role="listitem"))
      rendered.should contain(%(aria-describedby=))
      rendered.should contain(%(aria-label="00:00))
      rendered.scan(/class="am-heat-pill"/).size.should eq(24)
      rendered.should contain(%(am-sr-only))
      rendered.should contain(%(<table class="am-sr-only">))
      rendered.should contain(%(<th scope="col">Hour</th>))
      expect_source_data_table(rendered, "launch-heatmap-table-caption", ["Hour", "Activity"])
      expect_relationship_targets_exist(rendered)
    end

    it "renders deterministic markup when an id is supplied" do
      first = Components::Examples::ScheduleHeatmapComponent.new(id: "stable-heatmap").render
      second = Components::Examples::ScheduleHeatmapComponent.new(id: "stable-heatmap").render

      first.should eq(second)
    end
  end

  describe Components::Examples::PaymentFormComponent do
    it "renders semantic payment validation fields" do
      form = Components::Examples::PaymentFormComponent.new
      rendered = form.render

      rendered.should contain(%(data-component="payment-form"))
      rendered.should contain(%(data-amber-payment-form))
      rendered.should contain(%(data-ap-payment-form))
      rendered.should contain(%(<legend class="am-visually-hidden">Receipt contact</legend>))
      rendered.should contain(%(<legend class="am-visually-hidden">Card details</legend>))
      rendered.should contain(%(<legend class="am-visually-hidden">Promotion code</legend>))
      rendered.scan(/<fieldset class="am-form-fieldset"/).size.should eq(3)
      rendered.should contain(%(type="email"))
      rendered.should contain(%(autocomplete="cc-number"))
      rendered.should contain(%(inputmode="numeric"))
      rendered.should contain(%(data-amber-card-number))
      rendered.should contain(%(data-ap-card-number))
      rendered.should contain(%(data-amber-card-expiry))
      rendered.should contain(%(data-ap-card-expiry))
      rendered.should contain(%(data-amber-card-cvc))
      rendered.should contain(%(data-ap-card-cvc))
      rendered.should contain(%(data-amber-promo-code))
      rendered.should contain(%(data-ap-promo-code))
    end

    it "documents browser and helper validation hooks separately" do
      rendered = Components::Examples::PaymentFormComponent.new(id: "checkout").render

      rendered.should contain(%(aria-describedby="checkout-status"))
      rendered.should contain(%(for="checkout-name"))
      rendered.should contain(%(id="checkout-name"))
      rendered.should contain(%(for="checkout-card-number"))
      rendered.should contain(%(id="checkout-card-number"))
      rendered.should contain(%(for="checkout-card-expiry"))
      rendered.should contain(%(id="checkout-card-expiry"))
      rendered.should contain(%(for="checkout-card-cvc"))
      rendered.should contain(%(id="checkout-card-cvc"))
      rendered.should contain(%(for="checkout-promo-code"))
      rendered.should contain(%(id="checkout-promo-code"))
      rendered.should contain(%(pattern="[0-9 ]{19}"))
      rendered.should contain(%(data-pattern-message="Use 16 digits grouped as 0000 0000 0000 0000."))
      rendered.should contain(%(pattern="[0-9]{2}/[0-9]{2}"))
      rendered.should contain(%(data-pattern-message="Use MM/YY."))
      rendered.should contain(%(pattern="[0-9]{3,4}"))
      rendered.should contain(%(data-pattern-message="Use a 3 or 4 digit security code."))
      expect_no_duplicate_ids(rendered)
      expect_accessible_control(rendered, "checkout-email")
      expect_accessible_control(rendered, "checkout-card-number")
      expect_accessible_control(rendered, "checkout-card-expiry")
      expect_accessible_control(rendered, "checkout-card-cvc")
      expect_live_region(rendered, "checkout-status")
      expect_describedby_targets_exist(rendered)
    end
  end

  describe Components::Examples::AuthFormComponent do
    it "renders sign-up password semantics" do
      form = Components::Examples::AuthFormComponent.new(mode: "signup")
      rendered = form.render

      rendered.should contain(%(data-component="auth-form"))
      rendered.should contain(%(data-amber-auth-form))
      rendered.should contain(%(data-ap-auth-form))
      rendered.should contain(%(<fieldset class="am-form-fieldset" aria-describedby="signup-status">))
      rendered.should contain(%(<legend class="am-visually-hidden">Create workspace account details</legend>))
      rendered.should contain(%(type="email"))
      rendered.should contain(%(autocomplete="new-password"))
      rendered.should contain(%(minlength="10"))
      rendered.should contain(%(data-amber-password))
      rendered.should contain(%(data-ap-password))
      rendered.should contain(%(data-amber-password-confirm="signup-password"))
      rendered.should contain(%(data-ap-password-confirm="signup-password"))
    end

    it "renders sign-in autocomplete semantics" do
      form = Components::Examples::AuthFormComponent.new(mode: "signin")
      rendered = form.render

      rendered.should contain(%(aria-label="Sign in"))
      rendered.should contain(%(<fieldset class="am-form-fieldset" aria-describedby="signin-status">))
      rendered.should contain(%(<legend class="am-visually-hidden">Workspace sign-in details</legend>))
      rendered.should contain(%(autocomplete="email"))
      rendered.should contain(%(autocomplete="current-password"))
      rendered.should contain(%(data-component="auth-form"))
      rendered.should contain(%(data-amber-auth-form))
      rendered.should contain(%(data-ap-auth-form))
    end

    it "prefixes reusable sign-up ids when an id is supplied" do
      rendered = Components::Examples::AuthFormComponent.new(id: "workspace-auth", mode: "signup").render

      rendered.should contain(%(aria-describedby="workspace-auth-status"))
      rendered.should contain(%(for="workspace-auth-name"))
      rendered.should contain(%(id="workspace-auth-email"))
      rendered.should contain(%(id="workspace-auth-password"))
      rendered.should contain(%(id="workspace-auth-password-rules"))
      rendered.should contain(%(id="workspace-auth-confirm"))
      rendered.should contain(%(data-amber-password-confirm="workspace-auth-password"))
      rendered.should contain(%(data-ap-password-confirm="workspace-auth-password"))
      expect_no_duplicate_ids(rendered)
      expect_accessible_control(rendered, "workspace-auth-email")
      expect_accessible_control(rendered, "workspace-auth-password")
      expect_accessible_control(rendered, "workspace-auth-confirm")
      expect_live_region(rendered, "workspace-auth-status")
      expect_describedby_targets_exist(rendered)
    end

    it "prefixes reusable sign-in ids when an id is supplied" do
      rendered = Components::Examples::AuthFormComponent.new(id: "team-signin", mode: "signin").render

      rendered.should contain(%(aria-describedby="team-signin-status"))
      rendered.should contain(%(for="team-signin-email"))
      rendered.should contain(%(id="team-signin-email"))
      rendered.should contain(%(for="team-signin-password"))
      rendered.should contain(%(id="team-signin-password"))
      expect_no_duplicate_ids(rendered)
      expect_accessible_control(rendered, "team-signin-email")
      expect_accessible_control(rendered, "team-signin-password")
      expect_live_region(rendered, "team-signin-status")
      expect_describedby_targets_exist(rendered)
    end
  end

  describe Components::Examples::TimelineComponent do
    it "renders milestone cards with reveal hooks" do
      timeline = Components::Examples::TimelineComponent.new(id: "crystal-timeline")
      rendered = timeline.render

      rendered.should contain(%(data-component="timeline"))
      rendered.should contain(%(aria-labelledby="crystal-timeline-title"))
      rendered.should contain(%(<h2 id="crystal-timeline-title"))
      rendered.should contain(%(data-amber-reveal))
      rendered.should contain(%(data-ap-reveal))
      rendered.should contain("Crystal 1.0")
      rendered.should contain(%(am-timeline-dot" aria-hidden="true"))
    end

    it "renders deterministic markup when an id is supplied" do
      first = Components::Examples::TimelineComponent.new(id: "stable-timeline").render
      second = Components::Examples::TimelineComponent.new(id: "stable-timeline").render

      first.should eq(second)
    end
  end

  describe Components::Examples::TabsComponent do
    it "renders a roving-tabindex tab contract" do
      tabs = Components::Examples::TabsComponent.new(id: "evidence")
      rendered = tabs.render

      rendered.should contain(%(data-component="tabs"))
      rendered.should contain(%(data-amber-tabs))
      rendered.should contain(%(data-ap-tabs))
      rendered.should contain(%(role="tablist"))
      rendered.should contain(%(role="tab"))
      rendered.should contain(%(aria-selected="true"))
      rendered.should contain(%(tabindex="-1"))
      rendered.should contain(%(role="tabpanel"))
      rendered.should contain(%(hidden))
    end
  end

  describe Components::Examples::CarouselComponent do
    it "renders slide state and controls" do
      carousel = Components::Examples::CarouselComponent.new(id: "state-carousel")
      rendered = carousel.render

      rendered.should contain(%(data-component="carousel"))
      rendered.should contain(%(data-amber-carousel))
      rendered.should contain(%(data-ap-carousel))
      rendered.should contain(%(aria-roledescription="carousel"))
      rendered.should contain(%(aria-roledescription="slide"))
      rendered.should contain(%(aria-hidden="true"))
      rendered.should contain(%(data-amber-carousel-prev))
      rendered.should contain(%(data-ap-carousel-prev))
      rendered.should contain(%(data-amber-carousel-next))
      rendered.should contain(%(data-ap-carousel-next))
      rendered.should contain(%(role="status"))
      expect_behavior_hook_pair(rendered, "data-ap-carousel", "data-amber-carousel")
      expect_behavior_hook_pair(rendered, "data-ap-carousel-prev", "data-amber-carousel-prev")
      expect_behavior_hook_pair(rendered, "data-ap-carousel-next", "data-amber-carousel-next")
      expect_live_region(rendered)
    end
  end

  describe Components::Examples::DialogComponent do
    it "renders a native dialog with labelled opener and close hook" do
      dialog = Components::Examples::DialogComponent.new(id: "pattern-dialog")
      rendered = dialog.render

      rendered.should contain(%(data-component="dialog"))
      rendered.should contain(%(aria-haspopup="dialog"))
      rendered.should contain(%(data-amber-dialog-open="pattern-dialog"))
      rendered.should contain(%(data-ap-dialog-open="pattern-dialog"))
      rendered.should contain(%(<dialog class="am-dialog" id="pattern-dialog"))
      rendered.should contain(%(aria-labelledby="pattern-dialog-title"))
      rendered.should contain(%(aria-describedby="pattern-dialog-desc"))
      rendered.should contain(%(data-amber-dialog-close))
      rendered.should contain(%(data-ap-dialog-close))
      expect_no_duplicate_ids(rendered)
      expect_behavior_hook_pair(rendered, "data-ap-dialog-open", "data-amber-dialog-open", "pattern-dialog")
      expect_behavior_hook_pair(rendered, "data-ap-dialog-close", "data-amber-dialog-close")
      expect_describedby_targets_exist(rendered)
    end
  end

  describe Components::Examples::SimpleChartComponent do
    it "renders first-party SVG chart markup" do
      chart = Components::Examples::SimpleChartComponent.new([10, 20], ["A", "B"], id: "revenue-chart", title: "Revenue")
      rendered = chart.render

      rendered.should contain("data-chart-adapter=\"first-party-svg\"")
      rendered.should contain(%(aria-describedby="revenue-chart-data-caption"))
      rendered.should contain(%(<title id="revenue-chart-title">Revenue chart</title>))
      rendered.should contain(%(<caption id="revenue-chart-data-caption">Revenue source data</caption>))
      rendered.should contain("<svg")
      rendered.should contain("<desc")
      rendered.should contain("A: 10, B: 20")
      rendered.should contain("data-chart-part=\"bar\"")
      rendered.should contain(%(<table class="am-sr-only">))
      rendered.should contain(%(<th scope="col">Label</th>))
      rendered.should_not contain("Chart.js")
      expect_no_duplicate_ids(rendered)
      expect_describedby_targets_exist(rendered)
      expect_source_data_table(rendered, "revenue-chart-data-caption", ["Label", "Value"])
    end

    it "isolates external chart adapters behind a stable root and table fallback" do
      chart = Components::Examples::SimpleChartComponent.new([3, 5], ["Low", "High"], id: "adapter-chart", title: "Adapter", adapter: "external")
      rendered = chart.render

      rendered.should contain(%(data-chart-adapter="external"))
      rendered.should contain(%(aria-describedby="adapter-chart-data-caption"))
      rendered.should contain(%(data-chart-external-root))
      rendered.should contain(%(data-chart-values="3,5"))
      rendered.should contain(%(data-chart-labels="Low,High"))
      rendered.should contain(%(<caption id="adapter-chart-data-caption">Adapter source data</caption>))
      rendered.should contain(%(<table class="am-sr-only">))
      rendered.should_not contain("<svg")
      rendered.should_not contain("Chart.js")
    end

    it "renders deterministic markup when an id is supplied" do
      first = Components::Examples::SimpleChartComponent.new([10, 20], ["A", "B"], id: "stable-chart", title: "Revenue").render
      second = Components::Examples::SimpleChartComponent.new([10, 20], ["A", "B"], id: "stable-chart", title: "Revenue").render

      first.should eq(second)
    end

    it "rejects unknown chart adapters instead of silently loading dependencies" do
      expect_raises(ArgumentError, /Invalid chart adapter/) do
        Components::Examples::SimpleChartComponent.new(adapter: "chartjs").render
      end
    end
  end

  describe Components::Examples::CounterComponent do
    it "renders with initial count" do
      counter = Components::Examples::CounterComponent.new
      rendered = counter.render

      rendered.should contain("counter-value")
      rendered.should contain(">0</span>")
      rendered.should contain("<button")
      rendered.should contain("data-action=\"click-&gt;increment\"")
      rendered.should contain("data-action=\"click-&gt;decrement\"")
      rendered.should contain("data-action=\"click-&gt;reset\"")
      rendered.should contain("am-button")
      rendered.should_not contain("btn btn-")
    end

    it "increments count" do
      counter = Components::Examples::CounterComponent.new
      counter.increment

      counter.get_state("count").try(&.as_i?).should eq(1)
      counter.render.should contain(">1</span>")
    end

    it "decrements count" do
      counter = Components::Examples::CounterComponent.new
      counter.set_state("count", 5)
      counter.decrement

      counter.get_state("count").try(&.as_i?).should eq(4)
      counter.render.should contain(">4</span>")
    end

    it "resets count" do
      counter = Components::Examples::CounterComponent.new
      counter.set_state("count", 10)
      counter.reset

      counter.get_state("count").try(&.as_i?).should eq(0)
      counter.render.should contain(">0</span>")
    end
  end

  describe Components::Examples::FormComponent do
    it "renders a form with fields" do
      form = Components::Examples::FormComponent.new
      rendered = form.render

      rendered.should contain("<form")
      rendered.should contain("data-action=\"submit-&gt;submit\"")
      rendered.should contain("<label for=\"name\">Name")
      rendered.should contain("<input type=\"text\" name=\"name\"")
      rendered.should contain("<label for=\"email\">Email")
      rendered.should contain("<input type=\"email\" name=\"email\"")
      rendered.should contain("<label for=\"message\">Message")
      rendered.should contain("<textarea name=\"message\"")
      rendered.should contain("<button type=\"submit\"")
      rendered.should contain("class=\"am-form\"")
      rendered.should contain("class=\"am-input\"")
      rendered.should contain("am-button")
      rendered.should_not contain("form-control")
      rendered.should_not contain("btn btn-")
    end

    it "validates required fields" do
      form = Components::Examples::FormComponent.new
      form.submit

      errors = form.get_state("errors").try(&.as_h?)
      errors.should_not be_nil
      errors.not_nil!["name"]?.should_not be_nil
      errors.not_nil!["email"]?.should_not be_nil
      errors.not_nil!["message"]?.should_not be_nil
    end

    it "validates email format" do
      form = Components::Examples::FormComponent.new

      # Set invalid email
      form.field_changed(JSON.parse(%{{"field": "email", "value": "invalid"}}))

      errors = form.get_state("errors").try(&.as_h?)
      errors.not_nil!["email"]?.try(&.as_s?).should eq("Please enter a valid email address")

      # Set valid email
      form.field_changed(JSON.parse(%{{"field": "email", "value": "test@example.com"}}))

      errors = form.get_state("errors").try(&.as_h?)
      errors.not_nil!["email"]?.should be_nil
    end

    it "shows success message on valid submission" do
      form = Components::Examples::FormComponent.new

      # Fill out form
      form.field_changed(JSON.parse(%{{"field": "name", "value": "John Doe"}}))
      form.field_changed(JSON.parse(%{{"field": "email", "value": "john@example.com"}}))
      form.field_changed(JSON.parse(%{{"field": "message", "value": "Hello"}}))

      # Submit
      form.submit

      form.get_state("submitted").try(&.as_bool?).should be_true
      form.render.should contain("Form submitted successfully!")
    end
  end

  describe Components::Examples::ChatComponent do
    it "renders design-system chat classes without Bootstrap button or form classes" do
      chat = Components::Examples::ChatComponent.new(username: "Amber")
      chat.receive_message(JSON.parse(%{{"username": "Amber", "text": "Hello"}}))

      rendered = chat.render
      rendered.should contain("class=\"am-chat\"")
      rendered.should contain("class=\"am-chat__messages\"")
      rendered.should contain("role=\"log\"")
      rendered.should contain("class=\"am-input\"")
      rendered.should contain("am-button am-button--brand am-button--solid am-button--md")
      rendered.should_not contain("form-control")
      rendered.should_not contain("btn btn-")
    end
  end

  describe Components::Examples::LiveSearchComponent do
    it "renders design-system live-search classes without Bootstrap list or form classes" do
      search = Components::Examples::LiveSearchComponent.new
      search.set_state("query", "invoice")
      search.set_state("results", [
        JSON::Any.new({
          "id"    => JSON::Any.new(1_i64),
          "title" => JSON::Any.new("Invoice match"),
        } of String => JSON::Any),
      ])

      rendered = search.render
      rendered.should contain("class=\"am-live-search\"")
      rendered.should contain("class=\"am-input\"")
      rendered.should contain("class=\"am-live-search__list\"")
      rendered.should contain("class=\"am-live-search__item\"")
      rendered.should_not contain("form-control")
      rendered.should_not contain("list-group")
      rendered.should_not contain("text-muted")
      rendered.should_not contain("mt-3")
    end
  end
end
