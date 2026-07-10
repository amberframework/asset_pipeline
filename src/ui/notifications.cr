# Crystal models for UserNotifications authorization status and request payloads.
# Export-only: a host adapter performs the actual UNUserNotificationCenter calls.

require "json"

module UI
  enum NotificationAuthorizationStatus
    NotDetermined
    Denied
    Authorized
    Provisional
    Ephemeral
    Unsupported
  end

  class NotificationRequest
    property identifier : String
    property title : String
    property subtitle : String?
    property body : String
    property delay_seconds : Float64
    property repeats : Bool
    property sound : Bool
    property badge : Int32?
    property thread_id : String?

    def initialize(@title : String,
                   @body : String,
                   identifier : String? = nil,
                   @subtitle : String? = nil,
                   @delay_seconds : Float64 = 0.25,
                   @repeats : Bool = false,
                   @sound : Bool = true,
                   @badge : Int32? = nil,
                   @thread_id : String? = nil)
      @identifier = if identifier && !identifier.empty?
                      identifier
                    else
                      "ui-notification-#{Time.utc.to_unix_ms}"
                    end
    end

    def effective_delay_seconds : Float64
      base = @delay_seconds > 0.0 ? @delay_seconds : 0.25
      @repeats && base < 60.0 ? 60.0 : base
    end
  end

  class NotificationAction
    property identifier : String
    property title : String
    property kind : String
    property options : Array(String)
    property text_input_button_title : String?
    property text_input_placeholder : String?
    property is_enabled : Bool

    def initialize(
      @identifier : String,
      @title : String,
      @kind : String = "default",
      options : Array(String) = [] of String,
      @text_input_button_title : String? = nil,
      @text_input_placeholder : String? = nil,
      @is_enabled : Bool = true
    )
      raise ArgumentError.new("notification action identifier cannot be blank") if @identifier.strip.empty?
      raise ArgumentError.new("notification action title cannot be blank") if @title.strip.empty?
      @kind = normalize_kind(@kind)
      @options = options.map(&.strip).reject(&.empty?).uniq.sort
    end

    def add_option(option : String) : String
      normalized = option.strip
      return normalized if normalized.empty?

      @options = (@options + [normalized]).uniq.sort
      normalized
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "title", @title
        json.field "kind", @kind
        json.field "options" do
          json.array do
            @options.each { |option| json.string option }
          end
        end
        json.field "text_input_button_title", @text_input_button_title if @text_input_button_title
        json.field "text_input_placeholder", @text_input_placeholder if @text_input_placeholder
        json.field "is_enabled", @is_enabled
      end
    end

    def to_swift_scaffold(indent : Int32 = 12) : String
      indent_str = " " * indent
      String.build do |output|
        if text_input?
          output << indent_str << "UNTextInputNotificationAction(\n"
          output << indent_str << "    identifier: " << swift_string_literal(@identifier) << ",\n"
          output << indent_str << "    title: " << swift_string_literal(@title) << ",\n"
          output << indent_str << "    options: " << swift_options_literal << ",\n"
          output << indent_str << "    textInputButtonTitle: " << swift_string_literal(@text_input_button_title || "Send") << ",\n"
          output << indent_str << "    textInputPlaceholder: " << swift_string_literal(@text_input_placeholder || "") << "\n"
          output << indent_str << ")"
        else
          output << indent_str << "UNNotificationAction(\n"
          output << indent_str << "    identifier: " << swift_string_literal(@identifier) << ",\n"
          output << indent_str << "    title: " << swift_string_literal(@title) << ",\n"
          output << indent_str << "    options: " << swift_options_literal << "\n"
          output << indent_str << ")"
        end
      end
    end

    private def normalize_kind(value : String) : String
      normalized = value.strip.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/^_+|_+$/, "")
      normalized.empty? ? "default" : normalized
    end

    private def text_input? : Bool
      @kind == "text_input"
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

    private def swift_options_literal : String
      mapped = @options.map do |option|
        case option.downcase
        when "foreground" then ".foreground"
        when "destructive" then ".destructive"
        when "authenticationrequired" then ".authenticationRequired"
        when "authentication_required" then ".authenticationRequired"
        else
          nil
        end
      end.compact

      mapped.empty? ? "[]" : "[#{mapped.join(", ")}]"
    end
  end

  class NotificationCategory
    property identifier : String
    property actions : Array(NotificationAction)
    property intent_identifiers : Array(String)
    property options : Array(String)
    property is_enabled : Bool

    def initialize(
      @identifier : String,
      actions : Array(NotificationAction) = [] of NotificationAction,
      intent_identifiers : Array(String) = [] of String,
      options : Array(String) = [] of String,
      @is_enabled : Bool = true
    )
      raise ArgumentError.new("notification category identifier cannot be blank") if @identifier.strip.empty?
      @actions = actions.dup
      @intent_identifiers = intent_identifiers.map(&.strip).reject(&.empty?).uniq.sort
      @options = options.map(&.strip).reject(&.empty?).uniq.sort
    end

    def add_action(action : NotificationAction) : NotificationAction
      @actions << action
      action
    end

    def add_action(
      identifier : String,
      title : String,
      kind : String = "default",
      options : Array(String) = [] of String,
      text_input_button_title : String? = nil,
      text_input_placeholder : String? = nil,
      is_enabled : Bool = true
    ) : NotificationAction
      action = NotificationAction.new(
        identifier,
        title,
        kind: kind,
        options: options,
        text_input_button_title: text_input_button_title,
        text_input_placeholder: text_input_placeholder,
        is_enabled: is_enabled
      )
      add_action(action)
      action
    end

    def add_intent_identifier(identifier : String) : String
      normalized = identifier.strip
      return normalized if normalized.empty?

      @intent_identifiers = (@intent_identifiers + [normalized]).uniq.sort
      normalized
    end

    def add_option(option : String) : String
      normalized = option.strip
      return normalized if normalized.empty?

      @options = (@options + [normalized]).uniq.sort
      normalized
    end

    def to_payload(json : JSON::Builder) : Nil
      json.object do
        json.field "identifier", @identifier
        json.field "actions" do
          json.array do
            sorted_actions.each { |action| action.to_payload(json) }
          end
        end
        json.field "intent_identifiers" do
          json.array do
            @intent_identifiers.each { |identifier| json.string identifier }
          end
        end
        json.field "options" do
          json.array do
            @options.each { |option| json.string option }
          end
        end
        json.field "is_enabled", @is_enabled
      end
    end

    def to_swift_scaffold(indent : Int32 = 8) : String
      indent_str = " " * indent
      action_indent = indent_str + "    "
      String.build do |output|
        output << indent_str << "UNNotificationCategory(\n"
        output << action_indent << "identifier: " << swift_string_literal(@identifier) << ",\n"
        output << action_indent << "actions: [\n"
        sorted_actions.each do |action|
          output << action.to_swift_scaffold(indent + 8) << ",\n"
        end
        output << action_indent << "],\n"
        output << action_indent << "intentIdentifiers: ["
        output << @intent_identifiers.map { |identifier| swift_string_literal(identifier) }.join(", ")
        output << "],\n"
        output << action_indent << "options: " << swift_category_options_literal << "\n"
        output << indent_str << ")"
      end
    end

    private def sorted_actions : Array(NotificationAction)
      @actions.sort_by(&.identifier)
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

    private def swift_category_options_literal : String
      mapped = @options.map do |option|
        case option.downcase
        when "custom_dismiss_action" then ".customDismissAction"
        when "allow_in_car_play" then ".allowInCarPlay"
        when "hidden_previews_show_title" then ".hiddenPreviewsShowTitle"
        when "hidden_previews_show_subtitle" then ".hiddenPreviewsShowSubtitle"
        else
          nil
        end
      end.compact

      mapped.empty? ? "[]" : "[#{mapped.join(", ")}]"
    end
  end

  class NotificationsCatalog
    property application_name : String
    property bundle_identifier : String?
    property categories : Array(NotificationCategory)

    def initialize(@application_name : String, @bundle_identifier : String? = nil, categories : Array(NotificationCategory)? = nil)
      @categories = categories || [] of NotificationCategory
    end

    def add_category(category : NotificationCategory) : NotificationCategory
      @categories << category
      category
    end

    def add_category(
      identifier : String,
      actions : Array(NotificationAction) = [] of NotificationAction,
      intent_identifiers : Array(String) = [] of String,
      options : Array(String) = [] of String,
      is_enabled : Bool = true,
      &block : NotificationCategory -> Nil
    ) : NotificationCategory
      category = NotificationCategory.new(
        identifier,
        actions: actions,
        intent_identifiers: intent_identifiers,
        options: options,
        is_enabled: is_enabled
      )
      yield category
      @categories << category
      category
    end

    def add_category(
      identifier : String,
      actions : Array(NotificationAction) = [] of NotificationAction,
      intent_identifiers : Array(String) = [] of String,
      options : Array(String) = [] of String,
      is_enabled : Bool = true
    ) : NotificationCategory
      category = NotificationCategory.new(
        identifier,
        actions: actions,
        intent_identifiers: intent_identifiers,
        options: options,
        is_enabled: is_enabled
      )
      @categories << category
      category
    end

    def remove_category(identifier : String) : Bool
      before = @categories.size
      @categories.reject! { |entry| entry.identifier == identifier }
      before != @categories.size
    end

    def find_category(identifier : String) : NotificationCategory?
      @categories.find { |entry| entry.identifier == identifier }
    end

    def clear : Nil
      @categories.clear
    end

    def export_manifest : String
      JSON.build do |json|
        json.object do
          json.field "application_name", @application_name
          json.field "bundle_identifier", @bundle_identifier if @bundle_identifier
          json.field "categories" do
            json.array do
              sorted_categories.each { |category| category.to_payload(json) }
            end
          end
        end
      end
    end

    def export_swift_scaffold : String
      String.build do |output|
        output << "import UserNotifications\n\n"
        output << "// Generated by asset_pipeline.\n"
        output << "// Application: " << @application_name << "\n"
        output << "// Bundle Identifier: " << @bundle_identifier << "\n" if @bundle_identifier
        output << "\n"
        output << "public enum " << swift_module_name << " {\n"
        if @categories.empty?
          output << "    // No notification categories were exported.\n"
        else
          output << "    public static var categories: Set<UNNotificationCategory> {\n"
          output << "        Set([\n"
          sorted_categories.each do |category|
            output << category.to_swift_scaffold(12) << ",\n"
          end
          output << "        ])\n"
          output << "    }\n\n"
          output << "    public static func register() {\n"
          output << "        UNUserNotificationCenter.current().setNotificationCategories(categories)\n"
          output << "    }\n"
        end
        output << "}\n"
      end
    end

    private def sorted_categories : Array(NotificationCategory)
      @categories.sort_by(&.identifier)
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
      "#{normalized}Notifications"
    end
  end

  module Notifications
    extend self

    {% if flag?(:macos) || flag?(:ios) %}
      lib LibObjCBridge
        fun ap_notifications_authorization_status : Int64
        fun ap_notifications_request_authorization(alert : Int32, sound : Int32, badge : Int32) : Int32
        fun ap_notifications_schedule_local(identifier : UInt8*, title : UInt8*, subtitle : UInt8*, body : UInt8*, delay_seconds : Float64, badge : Int32, play_sound : Int32, repeats : Int32, thread_id : UInt8*) : Int32
        fun ap_notifications_remove_pending(identifier : UInt8*) : Void
        fun ap_notifications_remove_all_pending : Void
      end
    {% end %}

    def authorization_status : NotificationAuthorizationStatus
      {% if flag?(:macos) || flag?(:ios) %}
        status_from_native(LibObjCBridge.ap_notifications_authorization_status)
      {% else %}
        NotificationAuthorizationStatus::Unsupported
      {% end %}
    end

    def request_authorization(alert : Bool = true, sound : Bool = true, badge : Bool = true) : Bool
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_notifications_request_authorization(alert ? 1 : 0, sound ? 1 : 0, badge ? 1 : 0) == 1
      {% else %}
        false
      {% end %}
    end

    def schedule(request : NotificationRequest) : Bool
      {% if flag?(:macos) || flag?(:ios) %}
        subtitle_ptr = request.subtitle ? request.subtitle.not_nil!.to_unsafe : Pointer(UInt8).null
        thread_ptr = request.thread_id ? request.thread_id.not_nil!.to_unsafe : Pointer(UInt8).null
        badge_value = request.badge || -1

        LibObjCBridge.ap_notifications_schedule_local(
          request.identifier.to_unsafe,
          request.title.to_unsafe,
          subtitle_ptr,
          request.body.to_unsafe,
          request.effective_delay_seconds,
          badge_value,
          request.sound ? 1 : 0,
          request.repeats ? 1 : 0,
          thread_ptr
        ) == 1
      {% else %}
        false
      {% end %}
    end

    def remove_pending(identifier : String) : Nil
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_notifications_remove_pending(identifier.to_unsafe)
      {% end %}
    end

    def remove_all_pending : Nil
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_notifications_remove_all_pending
      {% end %}
    end

    def export_manifest(catalog : NotificationsCatalog) : String
      catalog.export_manifest
    end

    def export_swift_scaffold(catalog : NotificationsCatalog) : String
      catalog.export_swift_scaffold
    end

    private def status_from_native(status : Int64) : NotificationAuthorizationStatus
      case status
      when 0 then NotificationAuthorizationStatus::NotDetermined
      when 1 then NotificationAuthorizationStatus::Denied
      when 2 then NotificationAuthorizationStatus::Authorized
      when 3 then NotificationAuthorizationStatus::Provisional
      when 4 then NotificationAuthorizationStatus::Ephemeral
      else        NotificationAuthorizationStatus::Unsupported
      end
    end
  end
end
