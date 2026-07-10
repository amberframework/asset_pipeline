require "../spec_helper"

describe SpecSupport::AccessibilityMatchers do
  it "accepts labelled controls with valid described-by targets and live regions" do
    html = <<-HTML
    <form aria-describedby="profile-status">
      <div id="profile-status" role="status">Ready.</div>
      <label for="email">Email</label>
      <input id="email" type="email" aria-describedby="email-error" aria-invalid="true">
      <p id="email-error">Enter a valid email.</p>
    </form>
    HTML

    expect_no_duplicate_ids(html)
    expect_accessible_control(html, "email")
    expect_error_wiring(html, "email", "email-error")
    expect_live_region(html, "profile-status")
    expect_describedby_targets_exist(html)
    expect_no_inline_event_handlers(html)
    expect_no_positive_tabindex(html)
    expect_no_bootstrap_shaped_classes(html)
  end

  it "accepts wrapping labels and aria-labelled controls" do
    html = <<-HTML
    <label>Search <input id="search" type="search"></label>
    <button id="save">Save changes</button>
    <button id="close" aria-label="Close dialog"></button>
    HTML

    expect_accessible_control(html, "search")
    expect_accessible_control(html, "save")
    expect_accessible_control(html, "close")
  end

  it "verifies relationship targets, behavior hook pairs, legends, and source tables" do
    html = <<-HTML
    <button id="open" data-ap-dialog-open="confirm" data-amber-dialog-open="confirm" aria-controls="confirm">Open</button>
    <dialog id="confirm" aria-labelledby="confirm-title" aria-describedby="confirm-desc">
      <h2 id="confirm-title">Confirm</h2>
      <p id="confirm-desc">Review the action.</p>
    </dialog>
    <fieldset><legend class="am-visually-hidden">Card details</legend></fieldset>
    <figure aria-describedby="chart-caption">
      <table class="am-sr-only"><caption id="chart-caption">Revenue source data</caption><thead><tr><th scope="col">Label</th><th scope="col">Value</th></tr></thead></table>
    </figure>
    HTML

    expect_relationship_targets_exist(html)
    expect_behavior_hook_pair(html, "data-ap-dialog-open", "data-amber-dialog-open", "confirm")
    expect_fieldset_legend(html, "Card details")
    expect_source_data_table(html, "chart-caption", ["Label", "Value"])
  end

  it "rejects common accessibility regressions" do
    expect_raises(Spec::AssertionFailed) { expect_no_duplicate_ids(%(<div id="x"></div><p id="x"></p>)) }
    expect_raises(Spec::AssertionFailed) { expect_accessible_control(%(<input id="email">), "email") }
    expect_raises(Spec::AssertionFailed) { expect_relationship_targets_exist(%(<input id="email" aria-describedby="missing">)) }
    expect_raises(Spec::AssertionFailed) { expect_relationship_targets_exist(%(<input id="email" aria-labelledby="empty"><span id="empty"></span>)) }
    expect_raises(Spec::AssertionFailed) { expect_live_region(%(<div id="status" aria-live="off">Ignored</div>), "status") }
    expect_raises(Spec::AssertionFailed) { expect_no_positive_tabindex(%(<button tabindex="3">Bad</button>)) }
    expect_raises(Spec::AssertionFailed) { expect_no_positive_tabindex(%(<button tabindex="next">Bad</button>)) }
    expect_raises(Spec::AssertionFailed) { expect_no_inline_event_handlers(%(<button onclick="save()">Save</button>)) }
    expect_raises(Spec::AssertionFailed) { expect_no_bootstrap_shaped_classes(%(<button class="btn btn-primary">Save</button>)) }
  end
end
