# Crystal model for ActivityKit-style Live Activity update intents. Export-only:
# captures the update payload for a host or build step without rendering in-app.

require "json"

module UI
  # Metadata for an ActivityKit-style update intent.
  #
  # This is export-only. It keeps the intent that would be handed off to a host
  # or build step without pretending to render anything in-app.
  class LiveActivityUpdateIntent
    property identifier : String
    property title : String?
    property subtitle : String?
    property system_image : String?
    property user_info : Hash(String, String)
    property is_enabled : Bool

    def initialize(
      @identifier : String,
      @title : String? = nil,
      @subtitle : String? = nil,
      @system_image : String? = nil,
      user_info : Hash(String, String) = {} of String => String,
      @is_enabled : Bool = true
    )
      raise ArgumentError.new("live activity update intent identifier cannot be blank") if @identifier.strip.empty?
      @user_info = user_info.dup
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "title", @title if @title
        json.field "subtitle", @subtitle if @subtitle
        json.field "system_image", @system_image if @system_image
        json.field "user_info", @user_info unless @user_info.empty?
        json.field "is_enabled", @is_enabled
      end
    end
  end

  # Export-only ActivityKit-style state for one live activity.
  #
  # The state is deliberately plain data: an attributes type, the exported
  # attributes payload, the content-state payload, and an optional update
  # intent.
  class LiveActivity
    property identifier : String
    property attributes_type : String
    property attributes : Hash(String, String)
    property content_state : Hash(String, String)
    property update_intent : LiveActivityUpdateIntent?
    property is_active : Bool

    def initialize(
      @attributes_type : String,
      identifier : String? = nil,
      attributes : Hash(String, String) = {} of String => String,
      content_state : Hash(String, String) = {} of String => String,
      @update_intent : LiveActivityUpdateIntent? = nil,
      @is_active : Bool = true
    )
      raise ArgumentError.new("live activity attributes type cannot be blank") if @attributes_type.strip.empty?
      @identifier = if identifier && !identifier.empty?
                      identifier
                    else
                      slugify(@attributes_type)
                    end
      @attributes = attributes.dup
      @content_state = content_state.dup
    end

    def add_attribute(key : String, value : String) : String
      @attributes[key] = value
      value
    end

    def add_content_state_field(key : String, value : String) : String
      @content_state[key] = value
      value
    end

    def attach_update_intent(intent : LiveActivityUpdateIntent) : LiveActivityUpdateIntent
      @update_intent = intent
      intent
    end

    def build_update_intent(
      identifier : String,
      title : String? = nil,
      subtitle : String? = nil,
      system_image : String? = nil,
      user_info : Hash(String, String) = {} of String => String,
      is_enabled : Bool = true
    ) : LiveActivityUpdateIntent
      attach_update_intent(
        LiveActivityUpdateIntent.new(
          identifier,
          title: title,
          subtitle: subtitle,
          system_image: system_image,
          user_info: user_info,
          is_enabled: is_enabled
        )
      )
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "attributes_type", @attributes_type
        json.field "attributes", @attributes
        json.field "content_state", @content_state
        json.field "update_intent" do
          if intent = @update_intent
            intent.to_payload(json)
          else
            json.null
          end
        end
        json.field "is_active", @is_active
      end
    end

    # Export a deterministic Swift/ActivityKit scaffold for this activity.
    #
    # The scaffold stays conservative: it mirrors the exported keys as typed
    # string properties and records the update intent metadata as static
    # constants so a later build step can fill in the real ActivityKit surface.
    def to_activitykit_scaffold(indent : Int32 = 4) : String
      indent_str = " " * indent
      child_indent = indent_str + "    "
      struct_name = swift_type_name(@attributes_type, "LiveActivity")

      String.build do |output|
      output << indent_str << "public struct " << struct_name << ": ActivityAttributes {\n"
        output << child_indent << "public struct ContentState: Codable, Hashable {\n"

        if @content_state.empty?
          output << child_indent << "    // No content-state fields were exported.\n"
        else
          sorted_content_state_keys.each do |key|
            output << child_indent << "    public var " << swift_identifier(key) << ": String\n"
          end
        end

        output << child_indent << "}\n\n"
        output << child_indent << "public static let identifier = " << swift_string_literal(@identifier) << "\n"
        output << child_indent << "public static let attributesType = " << swift_string_literal(@attributes_type) << "\n"
        output << child_indent << "public static let isActive = " << @is_active << "\n"
        output << child_indent << "public static let attributeKeys = [\n"
        sorted_attribute_keys.each do |key|
          output << child_indent << "    " << swift_string_literal(key) << ",\n"
        end
        output << child_indent << "]\n"
        output << child_indent << "public static let contentStateKeys = [\n"
        sorted_content_state_keys.each do |key|
          output << child_indent << "    " << swift_string_literal(key) << ",\n"
        end
        output << child_indent << "]\n"

        if intent = @update_intent
          output << child_indent << "public static let updateIntentIdentifier = " << swift_string_literal(intent.identifier) << "\n"
          if title = intent.title
            output << child_indent << "public static let updateIntentTitle = " << swift_string_literal(title) << "\n"
          else
            output << child_indent << "public static let updateIntentTitle: String? = nil\n"
          end
          if subtitle = intent.subtitle
            output << child_indent << "public static let updateIntentSubtitle = " << swift_string_literal(subtitle) << "\n"
          else
            output << child_indent << "public static let updateIntentSubtitle: String? = nil\n"
          end
          if system_image = intent.system_image
            output << child_indent << "public static let updateIntentSystemImage = " << swift_string_literal(system_image) << "\n"
          else
            output << child_indent << "public static let updateIntentSystemImage: String? = nil\n"
          end
          if intent.user_info.empty?
            output << child_indent << "public static let updateIntentUserInfo: [String: String] = [:]\n"
          else
            output << child_indent << "public static let updateIntentUserInfo: [String: String] = [\n"
            intent.user_info.keys.sort.each do |key|
              value = intent.user_info[key]
              output << child_indent << "    " << swift_string_literal(key) << ": " << swift_string_literal(value) << ",\n"
            end
            output << child_indent << "]\n"
          end
        else
          output << child_indent << "public static let updateIntentIdentifier: String? = nil\n"
          output << child_indent << "public static let updateIntentTitle: String? = nil\n"
          output << child_indent << "public static let updateIntentSubtitle: String? = nil\n"
          output << child_indent << "public static let updateIntentSystemImage: String? = nil\n"
          output << child_indent << "public static let updateIntentUserInfo: [String: String] = [:]\n"
        end

        output << indent_str << "}\n"
      end
    end

    private def slugify(value : String) : String
      normalized = value
        .gsub(/([a-z\d])([A-Z])/, "\\1-\\2")
        .gsub(/([A-Z]+)([A-Z][a-z])/, "\\1-\\2")
        .downcase
        .gsub(/[^a-z0-9]+/, "-")
        .gsub(/^-+|-+$/, "")
      normalized.empty? ? "live-activity" : normalized
    end

    private def sorted_attribute_keys : Array(String)
      @attributes.keys.sort
    end

    private def sorted_content_state_keys : Array(String)
      @content_state.keys.sort
    end

    private def swift_identifier(value : String, fallback : String = "value") : String
      normalized = value
        .strip
        .downcase
        .gsub(/[^a-z0-9]+/, "_")
        .gsub(/^_+|_+$/, "")

      normalized = fallback if normalized.empty?
      normalized = "#{fallback}_#{normalized}" if normalized.match(/^\d/)
      normalized = "_#{normalized}" if swift_keyword?(normalized)
      normalized
    end

    private def swift_type_name(value : String, fallback : String) : String
      trimmed = value.strip
      return fallback if trimmed.empty?
      return trimmed if trimmed.match(/\A[A-Z][A-Za-z0-9]*\z/)

      normalized = trimmed
        .gsub(/([a-z\d])([A-Z])/, "\\1 \\2")
        .gsub(/[^A-Za-z0-9]+/, " ")
        .split(/\s+/)
        .map { |part| part.empty? ? "" : part[0].upcase + part[1..].downcase }
        .join

      normalized = fallback if normalized.empty?
      normalized = "#{fallback}#{normalized}" if normalized.match(/^\d/)
      normalized
    end

    private def swift_string_literal(value : String) : String
      String.build do |output|
        output << '"'
        value.each_char do |char|
          case char
          when '\\'
            output << "\\\\"
          when '"'
            output << "\\\""
          when '\n'
            output << "\\n"
          when '\r'
            output << "\\r"
          when '\t'
            output << "\\t"
          else
            output << char
          end
        end
        output << '"'
      end
    end

    private def swift_keyword?(value : String) : Bool
      %w(
        associatedtype
        class
        deinit
        enum
        extension
        fileprivate
        func
        import
        init
        inout
        internal
        let
        operator
        private
        protocol
        public
        static
        struct
        subscript
        typealias
        var
        break
        case
        continue
        default
        defer
        do
        else
        fallthrough
        for
        guard
        if
        in
        repeat
        return
        switch
        where
        while
        as
        any
        catch
        false
        is
        nil
        rethrows
        super
        self
        Self
        throw
        throws
        true
        try
        await
      ).includes?(value)
    end
  end

  # Container for exported live activity state.
  #
  # This is the app-facing surface for building ActivityKit-style state dumps
  # for a host, build step, or validation pipeline.
  class LiveActivities
    property application_name : String
    property bundle_identifier : String?
    property activities : Array(LiveActivity)

    def initialize(@application_name : String, @bundle_identifier : String? = nil, activities : Array(LiveActivity)? = nil)
      @activities = activities || [] of LiveActivity
    end

    def add_activity(
      attributes_type : String,
      identifier : String? = nil,
      attributes : Hash(String, String) = {} of String => String,
      content_state : Hash(String, String) = {} of String => String,
      update_intent : LiveActivityUpdateIntent? = nil,
      is_active : Bool = true,
      &block : LiveActivity -> Nil
    ) : LiveActivity
      activity = LiveActivity.new(
        attributes_type,
        identifier: identifier,
        attributes: attributes,
        content_state: content_state,
        update_intent: update_intent,
        is_active: is_active
      )
      yield activity
      @activities << activity
      activity
    end

    def add_activity(
      attributes_type : String,
      identifier : String? = nil,
      attributes : Hash(String, String) = {} of String => String,
      content_state : Hash(String, String) = {} of String => String,
      update_intent : LiveActivityUpdateIntent? = nil,
      is_active : Bool = true
    ) : LiveActivity
      activity = LiveActivity.new(
        attributes_type,
        identifier: identifier,
        attributes: attributes,
        content_state: content_state,
        update_intent: update_intent,
        is_active: is_active
      )
      @activities << activity
      activity
    end

    def add_activity(activity : LiveActivity) : LiveActivity
      @activities << activity
      activity
    end

    def remove_activity(identifier : String) : Bool
      before = @activities.size
      @activities.reject! { |entry| entry.identifier == identifier }
      before != @activities.size
    end

    def clear : Nil
      @activities.clear
    end

    def find_activity(identifier : String) : LiveActivity?
      @activities.find { |entry| entry.identifier == identifier }
    end

    def to_payload : String
      JSON.build do |json|
        json.object do
          json.field "application_name", @application_name
          json.field "bundle_identifier", @bundle_identifier if @bundle_identifier
          json.field "activities" do
            json.array do
              @activities.each { |activity| activity.to_payload(json) }
            end
          end
        end
      end
    end

    # Export a conservative Swift/ActivityKit scaffold for the full collection.
    #
    # The scaffold is deterministic and extension-oriented: it uses stable
    # ordering, typed string placeholders, and static metadata constants so a
    # later build step can map the export into ActivityKit or WidgetKit code.
    def export_activitykit_scaffold : String
      String.build do |output|
        output << "import ActivityKit\n"
        output << "import WidgetKit\n\n"
        output << "// Generated by asset_pipeline.\n"
        output << "// Application: " << @application_name << "\n"
        output << "// Bundle Identifier: " << @bundle_identifier << "\n" if @bundle_identifier
        output << "\n"
        output << "public enum " << swift_module_name << " {\n"

        if @activities.empty?
          output << "    // No live activities were exported.\n"
        else
          sorted_activities.each do |activity|
            output << "\n"
            output << activity.to_activitykit_scaffold
          end
        end

        output << "}\n"
      end
    end

    private def sorted_activities : Array(LiveActivity)
      @activities.sort_by(&.identifier)
    end

    private def swift_module_name : String
      base = @application_name.strip
      base = "AssetPipeline" if base.empty?
      normalized = base
        .gsub(/([a-z\d])([A-Z])/, "\\1 \\2")
        .gsub(/[^A-Za-z0-9]+/, " ")
        .split(/\s+/)
        .map { |part| part.empty? ? "" : part[0].upcase + part[1..].downcase }
        .join
      normalized = "AssetPipeline" if normalized.empty?
      normalized = "AssetPipeline#{normalized}" if normalized.match(/^\d/)
      "#{normalized}LiveActivities"
    end
  end
end
