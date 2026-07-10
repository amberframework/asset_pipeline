require "../../../spec_helper"
require "../../../../../src/ui"

# Phase 3a — the production `SwiftKitObjCSender` (in
# `src/ui/native/swiftkit_overrides.cr`) normalises Populator setter
# Symbols into ObjC selector form (`:setStyle` → `"setStyle:"`) at the
# boundary so the populator contract — which the spec recording sender
# asserts against without trailing colons — stays decoupled from the
# ObjC selector convention. This spec pins that normalisation.
#
# The helper is exposed as `Populator.objc_setter_selector` (a module
# method) precisely so it can be exercised without the `-Dmacos` /
# `-Dios` gating that the production sender requires.

describe UI::Native::Populator, ".objc_setter_selector" do
  it "appends a trailing colon to a colon-less setter Symbol" do
    UI::Native::Populator.objc_setter_selector(:setStyle).should eq("setStyle:")
    UI::Native::Populator.objc_setter_selector(:setBackgroundColor).should eq("setBackgroundColor:")
    UI::Native::Populator.objc_setter_selector(:setRole).should eq("setRole:")
  end

  it "leaves a Symbol that already ends in a colon unchanged" do
    UI::Native::Populator.objc_setter_selector(:"setStyle:").should eq("setStyle:")
    UI::Native::Populator.objc_setter_selector(:"setAccessibilityLabel:").should eq("setAccessibilityLabel:")
  end

  it "preserves embedded colons (multi-arg setters) without doubling" do
    # Rare for overrides but possible for future call sites. The helper
    # only touches the trailing position — embedded colons are kept.
    UI::Native::Populator.objc_setter_selector(:"setTitle:forState:").should eq("setTitle:forState:")
  end
end
