# Crystal model for cross-platform widget placement metadata (surface, families,
# timeline intent, refresh policy). Export-only — no in-app rendering implied.

require "json"

module UI
  # Describes how a widget should be placed and refreshed on a specific
  # platform surface.
  #
  # This stays intentionally declarative. It records the widget family's
  # intended placement and timeline behavior so host tooling can export the
  # metadata into WidgetKit or another extension layer without pretending to
  # render the widget in-app.
  class WidgetPlacement
    property surface : String
    property families : Array(String)
    property timeline_intent : String
    property refresh_policy : String?
    property notes : String?

    def initialize(
      @surface : String,
      families : Array(String)? = nil,
      @timeline_intent : String = "snapshot",
      @refresh_policy : String? = nil,
      @notes : String? = nil
    )
      @families = families || [] of String
    end

    def add_family(family : String) : String
      @families << family
      family
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "surface", @surface
        json.field "families" do
          json.array do
            @families.each { |family| json.string family }
          end
        end
        json.field "timeline_intent", @timeline_intent
        json.field "refresh_policy", @refresh_policy if @refresh_policy
        json.field "notes", @notes if @notes
      end
    end

    def widgetkit_families : String
      return "[]" if @families.empty?
      entries = @families.map { |family| ".#{swift_family_case(family)}" }.join(", ")
      "[#{entries}]"
    end

    def export_widgetkit_scaffold(indent : String = "        ") : String
      String.build do |io|
        io << indent << "WidgetPlacementSpec(\n"
        io << indent << "    surface: " << swift_string_literal(@surface) << ",\n"
        io << indent << "    families: " << widgetkit_families << ",\n"
        io << indent << "    timelineIntent: " << swift_string_literal(@timeline_intent) << ",\n"
        io << indent << "    refreshPolicy: "
        if refresh_policy = @refresh_policy
          io << swift_string_literal(refresh_policy)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    notes: "
        if notes = @notes
          io << swift_string_literal(notes)
        else
          io << "nil"
        end
        io << "\n"
        io << indent << ")"
      end
    end

    private def swift_family_case(value : String) : String
      normalized = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .downcase

      case normalized
      when "system_small" then "systemSmall"
      when "system_medium" then "systemMedium"
      when "system_large" then "systemLarge"
      when "system_extra_large" then "systemExtraLarge"
      when "accessory_circular" then "accessoryCircular"
      when "accessory_rectangular" then "accessoryRectangular"
      when "accessory_inline" then "accessoryInline"
      when "accessory_angular" then "accessoryAngular"
      when "accessory_corner" then "accessoryCorner"
      else
        parts = normalized.split('_').reject(&.empty?)
        return "widgetFamily" if parts.empty?
        first = parts.shift
        first + parts.map(&.capitalize).join
      end
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end

  end

  # A single widget declaration.
  #
  # The model is extension-oriented rather than visual. It captures the
  # widget's identity, a short summary, and the surfaces where the widget is
  # expected to appear.
  class Widget
    property identifier : String
    property title : String
    property summary : String?
    property placements : Array(WidgetPlacement)
    property is_enabled : Bool

    def initialize(
      @title : String,
      identifier : String? = nil,
      @summary : String? = nil,
      placements : Array(WidgetPlacement)? = nil,
      @is_enabled : Bool = true
    )
      @identifier = if identifier && !identifier.empty?
                      identifier
                    else
                      slugify(@title)
                    end
      @placements = placements || [] of WidgetPlacement
    end

    def add_placement(
      surface : String,
      families : Array(String)? = nil,
      timeline_intent : String = "snapshot",
      refresh_policy : String? = nil,
      notes : String? = nil,
      &block : WidgetPlacement -> Nil
    ) : WidgetPlacement
      placement = WidgetPlacement.new(
        surface,
        families: families,
        timeline_intent: timeline_intent,
        refresh_policy: refresh_policy,
        notes: notes
      )
      yield placement
      @placements << placement
      placement
    end

    def add_placement(
      surface : String,
      families : Array(String)? = nil,
      timeline_intent : String = "snapshot",
      refresh_policy : String? = nil,
      notes : String? = nil
    ) : WidgetPlacement
      placement = WidgetPlacement.new(
        surface,
        families: families,
        timeline_intent: timeline_intent,
        refresh_policy: refresh_policy,
        notes: notes
      )
      @placements << placement
      placement
    end

    def add_placement(placement : WidgetPlacement) : WidgetPlacement
      @placements << placement
      placement
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "title", @title
        json.field "summary", @summary if @summary
        json.field "placements" do
          json.array do
            @placements.each { |placement| placement.to_payload(json) }
          end
        end
        json.field "is_enabled", @is_enabled
      end
    end

    def widgetkit_struct_name : String
      "#{swift_type_name(@identifier)}Widget"
    end

    def widgetkit_provider_name : String
      "#{swift_type_name(@identifier)}Provider"
    end

    def widgetkit_entry_name : String
      "#{swift_type_name(@identifier)}Entry"
    end

    def widgetkit_view_name : String
      "#{swift_type_name(@identifier)}WidgetView"
    end

    def widgetkit_supported_families : Array(String)
      families = [] of String
      @placements.each do |placement|
        placement.families.each do |family|
          normalized = normalize_widgetkit_family(family)
          families << normalized unless families.includes?(normalized)
        end
      end
      families
    end

    def export_widgetkit_scaffold(indent : String = "    ") : String
      String.build do |io|
        io << indent << "struct " << widgetkit_struct_name << ": Widget {\n"
        io << indent << "    var body: some WidgetConfiguration {\n"
        io << indent << "        StaticConfiguration(kind: " << swift_string_literal(@identifier) << ", provider: " << widgetkit_provider_name << "()) { entry in\n"
        io << indent << "            " << widgetkit_view_name << "(entry: entry)\n"
        io << indent << "        }\n"
        io << indent << "        .configurationDisplayName(" << swift_string_literal(@title) << ")\n"
        if summary = @summary
          io << indent << "        .description(" << swift_string_literal(summary) << ")\n"
        end
        supported_families = widgetkit_supported_families
        unless supported_families.empty?
          io << indent << "        .supportedFamilies([" << supported_families.map { |family| ".#{family}" }.join(", ") << "])\n"
        end
        io << indent << "    }\n"
        io << indent << "}\n\n"

        io << indent << "struct " << widgetkit_entry_name << ": TimelineEntry {\n"
        io << indent << "    let date: Date\n"
        io << indent << "}\n\n"

        io << indent << "struct " << widgetkit_provider_name << ": TimelineProvider {\n"
        io << indent << "    func placeholder(in context: Context) -> " << widgetkit_entry_name << " {\n"
        io << indent << "        " << widgetkit_entry_name << "(date: Date())\n"
        io << indent << "    }\n\n"
        io << indent << "    func getSnapshot(in context: Context, completion: @escaping (" << widgetkit_entry_name << ") -> Void) {\n"
        io << indent << "        completion(" << widgetkit_entry_name << "(date: Date()))\n"
        io << indent << "    }\n\n"
        io << indent << "    func getTimeline(in context: Context, completion: @escaping (Timeline<" << widgetkit_entry_name << ">) -> Void) {\n"
        io << indent << "        completion(Timeline(entries: [" << widgetkit_entry_name << "(date: Date())], policy: .atEnd))\n"
        io << indent << "    }\n"
        io << indent << "}\n\n"

        io << indent << "struct " << widgetkit_view_name << ": View {\n"
        io << indent << "    let entry: " << widgetkit_entry_name << "\n"
        io << indent << "    var body: some View {\n"
        io << indent << "        Text(" << swift_string_literal(@title) << ")\n"
        io << indent << "    }\n"
        io << indent << "}\n"
      end
    end

    private def slugify(value : String) : String
      normalized = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
      normalized.empty? ? "widget" : normalized
    end

    private def swift_type_name(value : String) : String
      parts = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .split('_')
        .reject(&.empty?)
      return "Widget" if parts.empty?
      type_name = parts.map(&.capitalize).join
      type_name = "Widget#{type_name}" unless type_name =~ /^[A-Za-z]/
      type_name
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end

    private def normalize_widgetkit_family(value : String) : String
      normalized = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .downcase

      case normalized
      when "system_small" then "systemSmall"
      when "system_medium" then "systemMedium"
      when "system_large" then "systemLarge"
      when "system_extra_large" then "systemExtraLarge"
      when "accessory_circular" then "accessoryCircular"
      when "accessory_rectangular" then "accessoryRectangular"
      when "accessory_inline" then "accessoryInline"
      when "accessory_angular" then "accessoryAngular"
      when "accessory_corner" then "accessoryCorner"
      else
        parts = normalized.split('_').reject(&.empty?)
        return "widgetFamily" if parts.empty?
        first = parts.shift
        first + parts.map(&.capitalize).join
      end
    end
  end

  # Extension-oriented metadata container for widgets.
  #
  # The container is intentionally export-only. It gives build tooling a place
  # to collect widget declarations and serialize them into a manifest for the
  # eventual WidgetKit or system-extension integration layer.
  class Widgets
    property application_name : String
    property bundle_identifier : String?
    property widgets : Array(Widget)

    def initialize(@application_name : String, @bundle_identifier : String? = nil, widgets : Array(Widget)? = nil)
      @widgets = widgets || [] of Widget
    end

    def add_widget(
      title : String,
      identifier : String? = nil,
      summary : String? = nil,
      placements : Array(WidgetPlacement)? = nil,
      is_enabled : Bool = true,
      &block : Widget -> Nil
    ) : Widget
      widget = Widget.new(
        title,
        identifier: identifier,
        summary: summary,
        placements: placements,
        is_enabled: is_enabled
      )
      yield widget
      @widgets << widget
      widget
    end

    def add_widget(
      title : String,
      identifier : String? = nil,
      summary : String? = nil,
      placements : Array(WidgetPlacement)? = nil,
      is_enabled : Bool = true
    ) : Widget
      widget = Widget.new(
        title,
        identifier: identifier,
        summary: summary,
        placements: placements,
        is_enabled: is_enabled
      )
      @widgets << widget
      widget
    end

    def add_widget(widget : Widget) : Widget
      @widgets << widget
      widget
    end

    def remove_widget(identifier : String) : Bool
      before = @widgets.size
      @widgets.reject! { |entry| entry.identifier == identifier }
      before != @widgets.size
    end

    def find_widget(identifier : String) : Widget?
      @widgets.find { |entry| entry.identifier == identifier }
    end

    def clear : Nil
      @widgets.clear
    end

    def to_payload : String
      JSON.build do |json|
        json.object do
          json.field "application_name", @application_name
          json.field "bundle_identifier", @bundle_identifier if @bundle_identifier
          json.field "widgets" do
            json.array do
              @widgets.each { |widget| widget.to_payload(json) }
            end
          end
        end
      end
    end

    def export_widgetkit_scaffold : String
      String.build do |io|
        io << "// Generated WidgetKit scaffold for " << @application_name << "\n"
        io << "import Foundation\n"
        io << "import WidgetKit\n"
        io << "import SwiftUI\n\n"
        io << "enum " << scaffold_type_name << " {\n"
        io << "    static let applicationName = " << swift_string_literal(@application_name) << "\n"
        io << "    static let bundleIdentifier = "
        if bundle_identifier = @bundle_identifier
          io << swift_string_literal(bundle_identifier)
        else
          io << "nil"
        end
        io << "\n"
        io << "    static let widgets: [WidgetSpec] = [\n"
        @widgets.each do |widget|
          io << "        WidgetSpec(\n"
          io << "            identifier: " << swift_string_literal(widget.identifier) << ",\n"
          io << "            title: " << swift_string_literal(widget.title) << ",\n"
          io << "            summary: "
          if summary = widget.summary
            io << swift_string_literal(summary)
          else
            io << "nil"
          end
          io << ",\n"
          io << "            placements: [\n"
          widget.placements.each do |placement|
            io << placement.export_widgetkit_scaffold("                ")
            io << ",\n"
          end
          io << "            ]\n"
          io << "        ),\n"
        end
        io << "    ]\n"
        io << "}\n\n"
        io << "struct WidgetSpec {\n"
        io << "    let identifier: String\n"
        io << "    let title: String\n"
        io << "    let summary: String?\n"
        io << "    let placements: [WidgetPlacementSpec]\n"
        io << "}\n\n"
        io << "struct WidgetPlacementSpec {\n"
        io << "    let surface: String\n"
        io << "    let families: [WidgetFamily]\n"
        io << "    let timelineIntent: String\n"
        io << "    let refreshPolicy: String?\n"
        io << "    let notes: String?\n"
        io << "}\n\n"
        @widgets.each do |widget|
          io << widget.export_widgetkit_scaffold
          io << "\n"
        end
      end
    end

    private def scaffold_type_name : String
      "#{swift_type_name(@application_name)}WidgetKitScaffold"
    end

    private def swift_type_name(value : String) : String
      parts = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .split('_')
        .reject(&.empty?)
      return "AssetPipeline" if parts.empty?
      type_name = parts.map(&.capitalize).join
      type_name = "Widget#{type_name}" unless type_name =~ /^[A-Za-z]/
      type_name
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end
  end
end
