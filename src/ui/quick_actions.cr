# Crystal model for iOS / iPadOS Quick Actions (Home Screen long-press shortcuts).
# Export-only: captures the action metadata for the host to register with the OS.

require "json"

module UI
  class QuickAction
    property type : String
    property title : String
    property subtitle : String?
    property system_image : String?
    property user_info : Hash(String, String) = {} of String => String

    def initialize(@type : String,
                   @title : String,
                   @subtitle : String? = nil,
                   @system_image : String? = nil,
                   @user_info : Hash(String, String) = {} of String => String)
      raise ArgumentError.new("home-screen quick action type cannot be blank") if @type.strip.empty?
      raise ArgumentError.new("home-screen quick action title cannot be blank") if @title.strip.empty?
      @user_info = @user_info.dup
    end

    def to_json(json : JSON::Builder) : Nil
      json.object do
        json.field "type", @type
        json.field "title", @title
        json.field "subtitle", @subtitle if @subtitle
        json.field "system_image", @system_image if @system_image
        unless @user_info.empty?
          json.field "user_info", @user_info
        end
      end
    end
  end

  class QuickActionsCatalog
    property actions : Array(QuickAction) = [] of QuickAction
    property is_applied : Bool = false

    def initialize(@actions : Array(QuickAction) = [] of QuickAction)
    end

    def add(action : QuickAction) : self
      @actions << action
      self
    end

    def add_action(type : String,
                   title : String,
                   subtitle : String? = nil,
                   system_image : String? = nil,
                   user_info : Hash(String, String) = {} of String => String) : QuickAction
      action = QuickAction.new(
        type: type,
        title: title,
        subtitle: subtitle,
        system_image: system_image,
        user_info: user_info
      )
      add(action)
      action
    end

    def to_json : String
      JSON.build do |json|
        json.object do
          json.field "actions" do
            json.array do
              @actions.each { |action| action.to_json(json) }
            end
          end
        end
      end
    end

    def apply : Bool
      @is_applied = HomeScreenQuickActions.apply(self)
    end

    def install : Bool
      apply
    end

    def clear : Nil
      @actions.clear
      HomeScreenQuickActions.clear
      @is_applied = false
    end
  end

  module HomeScreenQuickActions
    extend self

    {% if flag?(:macos) || flag?(:ios) %}
      lib LibObjCBridge
        fun ap_home_screen_quick_actions_apply(payload : UInt8*) : Int32
        fun ap_home_screen_quick_actions_clear : Void
      end
    {% end %}

    def export_manifest(catalog : QuickActionsCatalog) : String
      catalog.to_json
    end

    def export_plist_fragment(catalog : QuickActionsCatalog) : String
      lines = [] of String
      lines << "<array>"
      catalog.actions.each do |action|
        lines << "  <dict>"
        lines << "    <key>UIApplicationShortcutItemType</key>"
        lines << "    <string>#{xml_escape(action.type)}</string>"
        lines << "    <key>UIApplicationShortcutItemTitle</key>"
        lines << "    <string>#{xml_escape(action.title)}</string>"
        if subtitle = action.subtitle
          lines << "    <key>UIApplicationShortcutItemSubtitle</key>"
          lines << "    <string>#{xml_escape(subtitle)}</string>"
        end
        if symbol = action.system_image
          lines << "    <key>UIApplicationShortcutItemIconSymbolName</key>"
          lines << "    <string>#{xml_escape(symbol)}</string>"
        end
        unless action.user_info.empty?
          lines << "    <key>UIApplicationShortcutItemUserInfo</key>"
          lines << "    <dict>"
          action.user_info.each do |key, value|
            lines << "      <key>#{xml_escape(key)}</key>"
            lines << "      <string>#{xml_escape(value)}</string>"
          end
          lines << "    </dict>"
        end
        lines << "  </dict>"
      end
      lines << "</array>"
      lines.join('\n')
    end

    def apply(catalog : QuickActionsCatalog) : Bool
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_home_screen_quick_actions_apply(catalog.to_json.to_unsafe) == 1
      {% else %}
        false
      {% end %}
    end

    def clear : Nil
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_home_screen_quick_actions_clear
      {% end %}
    end

    private def xml_escape(value : String) : String
      value
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub("\"", "&quot;")
        .gsub("'", "&apos;")
    end
  end
end
