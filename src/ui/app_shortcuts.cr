# Crystal model for Apple App Shortcuts (AppIntents) metadata. Export-only:
# captures the shortcut intent so host tooling can register it with the OS,
# without pretending to render the shortcut UI in-app.

require "json"

module UI
  # Metadata for one App Shortcut declaration.
  #
  # The visible presentation of App Shortcuts belongs to Apple's system
  # surfaces. This model keeps the intent in Crystal so host code can export a
  # practical metadata payload for AppIntents / shortcut registration without
  # pretending the capability is a drawable UI::View.
  class AppShortcutParameter
    property name : String
    property prompt : String?
    property type : String?
    property default_value : String?
    property is_required : Bool

    def initialize(
      @name : String,
      @prompt : String? = nil,
      @type : String? = nil,
      @default_value : String? = nil,
      @is_required : Bool = true
    )
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "name", @name
        json.field "prompt", @prompt if @prompt
        json.field "type", @type if @type
        json.field "default_value", @default_value if @default_value
        json.field "is_required", @is_required
      end
    end

    def app_intents_parameter_name : String
      camelize(@name, lowercase_first: true)
    end

    def app_intents_value_type : String
      normalized = @type.try(&.downcase) || "string"
      case normalized
      when "bool", "boolean" then "Bool"
      when "int", "integer" then "Int"
      when "double", "decimal", "number" then "Double"
      when "date", "datetime" then "Date"
      else
        "String"
      end
    end

    def export_app_intents_scaffold(indent : String = "        ") : String
      String.build do |io|
        io << indent << "AppShortcutParameterSpec(\n"
        io << indent << "    name: " << swift_string_literal(@name) << ",\n"
        io << indent << "    parameterName: " << swift_string_literal(app_intents_parameter_name) << ",\n"
        io << indent << "    prompt: "
        if prompt = @prompt
          io << swift_string_literal(prompt)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    valueType: " << swift_string_literal(app_intents_value_type) << ",\n"
        io << indent << "    defaultValue: "
        if default_value = @default_value
          io << swift_string_literal(default_value)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    isRequired: " << @is_required << "\n"
        io << indent << ")"
      end
    end

    private def camelize(value : String, lowercase_first : Bool = false) : String
      parts = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .split('_')
        .reject(&.empty?)
      return lowercase_first ? "parameter" : "Parameter" if parts.empty?

      first = parts.shift.downcase
      body = parts.map(&.capitalize).join
      lowercase_first ? "#{first}#{body}" : "#{first.capitalize}#{body}"
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end
  end

  # A single shortcut declaration.
  #
  # This is intentionally a metadata object, not a rendered view. It packages
  # the user-facing title, phrases, and parameters that a host app can later
  # export into AppIntents or a similar integration layer.
  class AppShortcut
    property identifier : String
    property title : String
    property subtitle : String?
    property summary : String?
    property icon : String?
    property phrases : Array(String)
    property parameters : Array(AppShortcutParameter)
    property is_enabled : Bool
    property is_discoverable : Bool

    def initialize(
      @title : String,
      identifier : String? = nil,
      @subtitle : String? = nil,
      @summary : String? = nil,
      @icon : String? = nil,
      phrases : Array(String)? = nil,
      parameters : Array(AppShortcutParameter)? = nil,
      @is_enabled : Bool = true,
      @is_discoverable : Bool = true
    )
      @identifier = if identifier && !identifier.empty?
                      identifier
                    else
                      slugify(@title)
                    end
      @phrases = phrases || [] of String
      @parameters = parameters || [] of AppShortcutParameter
    end

    def add_phrase(phrase : String) : String
      @phrases << phrase
      phrase
    end

    def add_parameter(
      name : String,
      prompt : String? = nil,
      type : String? = nil,
      default_value : String? = nil,
      is_required : Bool = true
    ) : AppShortcutParameter
      parameter = AppShortcutParameter.new(
        name,
        prompt: prompt,
        type: type,
        default_value: default_value,
        is_required: is_required
      )
      @parameters << parameter
      parameter
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "title", @title
        json.field "subtitle", @subtitle if @subtitle
        json.field "summary", @summary if @summary
        json.field "icon", @icon if @icon
        json.field "phrases" do
          json.array do
            @phrases.each { |phrase| json.string phrase }
          end
        end
        json.field "parameters" do
          json.array do
            @parameters.each { |parameter| parameter.to_payload(json) }
          end
        end
        json.field "is_enabled", @is_enabled
        json.field "is_discoverable", @is_discoverable
      end
    end

    def app_intent_struct_name : String
      "#{swift_type_name(@identifier)}Intent"
    end

    def app_shortcut_spec_name : String
      "#{swift_type_name(@identifier)}ShortcutSpec"
    end

    def app_intent_display_name : String
      @title
    end

    def app_intent_description : String?
      @summary
    end

    def export_app_intents_scaffold(indent : String = "    ") : String
      String.build do |io|
        io << indent << "struct " << app_intent_struct_name << ": AppIntent {\n"
        io << indent << "    static var title: LocalizedStringResource { "
        io << swift_string_literal(app_intent_display_name)
        io << " }\n"
        if description = app_intent_description
          io << indent << "    static var description = IntentDescription(" << swift_string_literal(description) << ")\n"
        end
        io << indent << "    static var parameterSummary: some ParameterSummary {\n"
        io << indent << "        Summary(" << swift_string_literal(@title) << ")\n"
        io << indent << "    }\n"
        io << indent << "    func perform() async throws -> some IntentResult {\n"
        io << indent << "        .result()\n"
        io << indent << "    }\n"
        io << indent << "}\n"
      end
    end

    def export_app_shortcut_spec(indent : String = "        ") : String
      String.build do |io|
        io << indent << "AppShortcutSpec(\n"
        io << indent << "    identifier: " << swift_string_literal(@identifier) << ",\n"
        io << indent << "    title: " << swift_string_literal(@title) << ",\n"
        io << indent << "    subtitle: "
        if subtitle = @subtitle
          io << swift_string_literal(subtitle)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    summary: "
        if summary = @summary
          io << swift_string_literal(summary)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    icon: "
        if icon = @icon
          io << swift_string_literal(icon)
        else
          io << "nil"
        end
        io << ",\n"
        io << indent << "    phrases: [" << @phrases.map { |phrase| swift_string_literal(phrase) }.join(", ") << "],\n"
        io << indent << "    parameters: [\n"
        @parameters.each do |parameter|
          io << parameter.export_app_intents_scaffold("        ")
          io << ",\n"
        end
        io << indent << "    ],\n"
        io << indent << "    isEnabled: " << @is_enabled << ",\n"
        io << indent << "    isDiscoverable: " << @is_discoverable << ",\n"
        io << indent << "    specTypeName: " << swift_string_literal(app_shortcut_spec_name) << ",\n"
        io << indent << "    intentTypeName: " << swift_string_literal(app_intent_struct_name) << "\n"
        io << indent << ")"
      end
    end

    private def slugify(value : String) : String
      normalized = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
      normalized.empty? ? "shortcut" : normalized
    end

    private def swift_type_name(value : String) : String
      parts = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .split('_')
        .reject(&.empty?)
      return "Shortcut" if parts.empty?
      type_name = parts.map(&.capitalize).join
      type_name = "Shortcut#{type_name}" unless type_name =~ /^[A-Za-z]/
      type_name
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end
  end

  # App-shell metadata container for App Shortcuts.
  #
  # The model is intentionally export-oriented. Host code can collect one or
  # more shortcuts here and serialize the declaration payload into a build
  # step, Intents bundle, or other platform integration layer.
  class AppShortcuts
    property application_name : String
    property bundle_identifier : String?
    property shortcuts : Array(AppShortcut)

    def initialize(@application_name : String, @bundle_identifier : String? = nil, shortcuts : Array(AppShortcut)? = nil)
      @shortcuts = shortcuts || [] of AppShortcut
    end

    def add_shortcut(
      title : String,
      identifier : String? = nil,
      subtitle : String? = nil,
      summary : String? = nil,
      icon : String? = nil,
      phrases : Array(String)? = nil,
      parameters : Array(AppShortcutParameter)? = nil,
      is_enabled : Bool = true,
      is_discoverable : Bool = true,
      &block : AppShortcut -> Nil
    ) : AppShortcut
      shortcut = AppShortcut.new(
        title,
        identifier: identifier,
        subtitle: subtitle,
        summary: summary,
        icon: icon,
        phrases: phrases,
        parameters: parameters,
        is_enabled: is_enabled,
        is_discoverable: is_discoverable
      )
      yield shortcut
      @shortcuts << shortcut
      shortcut
    end

    def add_shortcut(
      title : String,
      identifier : String? = nil,
      subtitle : String? = nil,
      summary : String? = nil,
      icon : String? = nil,
      phrases : Array(String)? = nil,
      parameters : Array(AppShortcutParameter)? = nil,
      is_enabled : Bool = true,
      is_discoverable : Bool = true
    ) : AppShortcut
      shortcut = AppShortcut.new(
        title,
        identifier: identifier,
        subtitle: subtitle,
        summary: summary,
        icon: icon,
        phrases: phrases,
        parameters: parameters,
        is_enabled: is_enabled,
        is_discoverable: is_discoverable
      )
      @shortcuts << shortcut
      shortcut
    end

    def add_shortcut(shortcut : AppShortcut) : AppShortcut
      @shortcuts << shortcut
      shortcut
    end

    def remove_shortcut(identifier : String) : Bool
      before = @shortcuts.size
      @shortcuts.reject! { |entry| entry.identifier == identifier }
      before != @shortcuts.size
    end

    def clear : Nil
      @shortcuts.clear
    end

    def find_shortcut(identifier : String) : AppShortcut?
      @shortcuts.find { |entry| entry.identifier == identifier }
    end

    def to_payload : String
      JSON.build do |json|
        json.object do
          json.field "application_name", @application_name
          json.field "bundle_identifier", @bundle_identifier if @bundle_identifier
          json.field "shortcuts" do
            json.array do
              @shortcuts.each { |shortcut| shortcut.to_payload(json) }
            end
          end
        end
      end
    end

    def export_app_intents_scaffold : String
      String.build do |io|
        io << "// Generated AppIntents scaffold for " << @application_name << "\n"
        io << "import AppIntents\n"
        io << "import Foundation\n\n"
        io << "enum " << scaffold_type_name << " {\n"
        io << "    static let applicationName = " << swift_string_literal(@application_name) << "\n"
        io << "    static let bundleIdentifier = "
        if bundle_identifier = @bundle_identifier
          io << swift_string_literal(bundle_identifier)
        else
          io << "nil"
        end
        io << "\n"
        io << "    static let shortcuts: [AppShortcutSpec] = [\n"
        @shortcuts.each do |shortcut|
          io << shortcut.export_app_shortcut_spec("        ")
          io << ",\n"
        end
        io << "    ]\n"
        io << "}\n\n"
        io << "struct AppShortcutSpec {\n"
        io << "    let identifier: String\n"
        io << "    let title: String\n"
        io << "    let subtitle: String?\n"
        io << "    let summary: String?\n"
        io << "    let icon: String?\n"
        io << "    let phrases: [String]\n"
        io << "    let parameters: [AppShortcutParameterSpec]\n"
        io << "    let isEnabled: Bool\n"
        io << "    let isDiscoverable: Bool\n"
        io << "    let specTypeName: String\n"
        io << "    let intentTypeName: String\n"
        io << "}\n\n"
        io << "struct AppShortcutParameterSpec {\n"
        io << "    let name: String\n"
        io << "    let parameterName: String\n"
        io << "    let prompt: String?\n"
        io << "    let valueType: String\n"
        io << "    let defaultValue: String?\n"
        io << "    let isRequired: Bool\n"
        io << "}\n\n"
        @shortcuts.each do |shortcut|
          io << shortcut.export_app_intents_scaffold
          io << "\n"
        end
      end
    end

    private def scaffold_type_name : String
      "#{swift_type_name(@application_name)}AppIntentsScaffold"
    end

    private def swift_type_name(value : String) : String
      parts = value
        .gsub(/([a-z\d])([A-Z])/, "\\1_\\2")
        .gsub(/[^A-Za-z0-9]+/, "_")
        .split('_')
        .reject(&.empty?)
      return "AssetPipeline" if parts.empty?
      type_name = parts.map(&.capitalize).join
      type_name = "AppShortcuts#{type_name}" unless type_name =~ /^[A-Za-z]/
      type_name
    end

    private def swift_string_literal(value : String) : String
      escaped = value.gsub("\\", "\\\\").gsub("\"", "\\\"").gsub("\n", "\\n")
      %("#{escaped}")
    end
  end
end
