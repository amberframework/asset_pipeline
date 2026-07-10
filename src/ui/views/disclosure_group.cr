# Collapsible disclosure section grouping related content under a toggle header.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # DisclosureGroup renders a HIG-compliant disclosure control: a header row
  # with a rotating chevron/triangle that reveals or hides a block of content.
  #
  # HIG defines two disclosure control shapes:
  #   - Disclosure triangle (NSButton.BezelStyle.disclosure): used inline in
  #     lists and outlines. Points right (leading edge) when collapsed, down
  #     when expanded.
  #   - Disclosure button (NSButton.BezelStyle.pushDisclosure): used in dialogs
  #     (e.g. the macOS Save sheet "Show More" button). Points down when
  #     content is hidden, up when visible.
  #
  # On macOS the header row emits a real NSButton with bezelStyle=disclosure (5)
  # followed by an optional visible content block when expanded = true.
  # On iOS DisclosureGroup maps to SwiftUI DisclosureGroup or a UIButton row
  # with a chevron SF Symbol ("chevron.right" when collapsed, "chevron.down"
  # when expanded). Both are rendered inline for validation captures (static;
  # no interactivity needed for visual validation).
  #
  # Usage:
  #   group = UI::DisclosureGroup.new("Advanced Options", expanded: false)
  #   group.content << UI::Label.new("Item A")
  #   group.content << UI::Label.new("Item B")
  class DisclosureGroup < View
    # Header label shown beside the disclosure triangle/chevron.
    property title : String

    # Whether the content block is revealed. Controls triangle/chevron
    # direction and child content visibility.
    property expanded : Bool

    # Child views shown when expanded = true.
    property content : Array(View)

    # Accessibility label for the header row (required for HIG compliance).
    # Defaults to title + state if not set explicitly.
    property accessibility_label : String?

    def initialize(@title : String, @expanded : Bool = false, @content : Array(View) = [] of View)
    end

    def accept(visitor : PlatformVisitor)
      visitor.visit(self)
    end
  end
end
