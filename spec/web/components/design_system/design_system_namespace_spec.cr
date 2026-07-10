require "../../spec_helper"
require "../../../../src/asset_pipeline/design_system"

describe Components::DesignSystem do
  it "exposes promoted example components through generic names" do
    Components::DesignSystem::AuthForm.name.should eq(Components::Examples::AuthFormComponent.name)
    Components::DesignSystem::Button.name.should eq(Components::Examples::ButtonComponent.name)
    Components::DesignSystem::Card.name.should eq(Components::Examples::CardComponent.name)
    Components::DesignSystem::Carousel.name.should eq(Components::Examples::CarouselComponent.name)
    Components::DesignSystem::CommandPalette.name.should eq(Components::Examples::CommandPaletteComponent.name)
    Components::DesignSystem::DataTable.name.should eq(Components::Examples::DataTableComponent.name)
    Components::DesignSystem::Dialog.name.should eq(Components::Examples::DialogComponent.name)
    Components::DesignSystem::FormField.name.should eq(Components::Examples::FormFieldComponent.name)
    Components::DesignSystem::PaymentForm.name.should eq(Components::Examples::PaymentFormComponent.name)
    Components::DesignSystem::PricingCard.name.should eq(Components::Examples::PricingCardComponent.name)
    Components::DesignSystem::ScheduleHeatmap.name.should eq(Components::Examples::ScheduleHeatmapComponent.name)
    Components::DesignSystem::SimpleChart.name.should eq(Components::Examples::SimpleChartComponent.name)
    Components::DesignSystem::Tabs.name.should eq(Components::Examples::TabsComponent.name)
    Components::DesignSystem::ThemeSwitcher.name.should eq(Components::Examples::ThemeSwitcherComponent.name)
    Components::DesignSystem::Timeline.name.should eq(Components::Examples::TimelineComponent.name)
  end

  it "renders Button with the same canonical classes and state markers" do
    generic = Components::DesignSystem::Button.new(
      label: "Save",
      tone: "success",
      emphasis: "outline",
      size: "lg",
      loading: "true"
    ).render

    example = Components::Examples::ButtonComponent.new(
      label: "Save",
      tone: "success",
      emphasis: "outline",
      size: "lg",
      loading: "true"
    ).render

    generic.should eq(example)
    generic.should contain("am-button am-button--success am-button--outline am-button--lg")
    generic.should contain(%(data-state="loading"))
    generic.should contain(%(aria-busy="true"))
  end

  it "renders FormField with the same form contract and nested option type" do
    generic_options = [
      Components::DesignSystem::FormField::Option.new("Choose one", ""),
      Components::DesignSystem::FormField::Option.new("3-10", "3-10"),
    ]

    example_options = [
      Components::Examples::FormFieldComponent::Option.new("Choose one", ""),
      Components::Examples::FormFieldComponent::Option.new("3-10", "3-10"),
    ]

    generic = Components::DesignSystem::FormField.new(
      label: "Team size",
      id: "team-size",
      type: "select",
      required: "true",
      options: generic_options,
      data_attrs: {"data-amber-filter" => "#team-table"},
      aria_attrs: {"aria-describedby" => "team-size-hint"}
    ).render

    example = Components::Examples::FormFieldComponent.new(
      label: "Team size",
      id: "team-size",
      type: "select",
      required: "true",
      options: example_options,
      data_attrs: {"data-amber-filter" => "#team-table"},
      aria_attrs: {"aria-describedby" => "team-size-hint"}
    ).render

    generic.should eq(example)
    generic.should contain(%(<label for="team-size" class="am-field" data-component="field">))
    generic.should contain(%(<select id="team-size" name="team_size" class="am-select"))
    generic.should contain(%(data-amber-filter="#team-table"))
    generic.should contain(%(aria-describedby="team-size-hint"))
  end

  it "renders additional promoted proof components with stable data-component hooks" do
    card = Components::DesignSystem::Card.new(
      title: "Pipeline health",
      subtitle: "All asset checks passed",
      selected: "true",
      interactive: "true"
    ).render

    pricing_card = Components::DesignSystem::PricingCard.new(
      name: "Team",
      badge: "Recommended",
      price: "$24",
      featured: "true"
    ).render

    table = Components::DesignSystem::DataTable.new(
      caption: "Namespace smoke table"
    ).render

    chart = Components::DesignSystem::SimpleChart.new(
      [3, 7],
      ["Queued", "Built"],
      title: "Builds"
    ).render

    card.should contain(%(data-component="card"))
    card.should contain(%(data-state="selected"))
    pricing_card.should contain(%(data-component="pricing-card"))
    pricing_card.should contain(%(data-featured="true"))
    table.should contain(%(class="am-table-wrap" data-component="table"))
    table.should contain(%(<caption>Namespace smoke table</caption>))
    chart.should contain(%(data-component="chart"))
    chart.should contain(%(data-chart-adapter="first-party-svg"))
  end

  it "exposes Fieldset as a generic form grouping primitive" do
    html = Components::DesignSystem::Fieldset.new(
      legend: "Preferences",
      described_by: "preferences-status"
    ).build do |fieldset|
      fieldset << Components::Elements::RawHTML.new(%(<label class="am-field">Team size<input class="am-input"></label>))
    end.render

    html.should contain(%(<fieldset class="am-form-fieldset" aria-describedby="preferences-status">))
    html.should contain(%(<legend class="am-visually-hidden">Preferences</legend>))
  end

  it "renders ThemeSwitcher with the same theme hooks" do
    generic = Components::DesignSystem::ThemeSwitcher.new(
      label: "Theme mode",
      mode: "segmented"
    ).render

    example = Components::Examples::ThemeSwitcherComponent.new(
      label: "Theme mode",
      mode: "segmented"
    ).render

    generic.should eq(example)
    generic.should contain(%(data-component="theme-switcher"))
    generic.should contain(%(data-amber-theme-set="light"))
    generic.should contain(%(data-ap-theme-set="light"))
    generic.should contain(%(data-amber-theme-set="dark"))
    generic.should contain(%(data-ap-theme-set="dark"))
    generic.should contain(%(aria-pressed="true"))
  end

  it "renders Dialog with the same runtime hooks and classes" do
    generic = Components::DesignSystem::Dialog.new(
      id: "settings-dialog",
      title: "Settings",
      body: "Review workspace settings.",
      opener_label: "Open settings"
    ).render

    example = Components::Examples::DialogComponent.new(
      id: "settings-dialog",
      title: "Settings",
      body: "Review workspace settings.",
      opener_label: "Open settings"
    ).render

    generic.should eq(example)
    generic.should contain(%(class="am-dialog-component" data-component="dialog"))
    generic.should contain(%(data-amber-dialog-open="settings-dialog"))
    generic.should contain(%(data-ap-dialog-open="settings-dialog"))
    generic.should contain(%(<dialog class="am-dialog" id="settings-dialog"))
    generic.should contain(%(data-amber-dialog-close))
    generic.should contain(%(data-ap-dialog-close))
  end

  it "renders Tabs with the same roving-tab contract" do
    generic_tabs = [
      Components::DesignSystem::Tabs::Tab.new("overview", "Overview", "Summary panel"),
      Components::DesignSystem::Tabs::Tab.new("audit", "Audit", "Audit panel"),
    ]

    example_tabs = [
      Components::Examples::TabsComponent::Tab.new("overview", "Overview", "Summary panel"),
      Components::Examples::TabsComponent::Tab.new("audit", "Audit", "Audit panel"),
    ]

    generic = Components::DesignSystem::Tabs.new(
      tabs: generic_tabs,
      id: "workspace-tabs",
      title: "Workspace",
      label: "Workspace sections"
    ).render

    example = Components::Examples::TabsComponent.new(
      tabs: example_tabs,
      id: "workspace-tabs",
      title: "Workspace",
      label: "Workspace sections"
    ).render

    generic.should eq(example)
    generic.should contain(%(data-amber-tabs data-ap-tabs data-component="tabs"))
    generic.should contain(%(role="tablist"))
    generic.should contain(%(aria-selected="true"))
    generic.should contain(%(class="am-tab-panel"))
  end
end
