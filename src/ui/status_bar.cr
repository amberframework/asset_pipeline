# Crystal model for iOS status-bar appearance (content style + hidden flag).
# Export-only: a host adapter applies the appearance to the active UIViewController.

require "json"

module UI
  enum StatusBarContentStyle
    Default
    LightContent
    DarkContent
  end

  # iOS status-bar appearance policy.
  #
  # The visible top bar remains system-owned; this configuration only expresses
  # whether the app wants light/dark content and whether the bar should be
  # hidden.
  class StatusBarAppearance
    property style : StatusBarContentStyle = StatusBarContentStyle::Default
    property hidden : Bool = false
    property animated : Bool = true

    def initialize(
      @style : StatusBarContentStyle = StatusBarContentStyle::Default,
      @hidden : Bool = false,
      @animated : Bool = true
    )
    end
  end

  # A small app-shell model for a macOS status item and its attached menu.
  #
  # Phase 4: gated to Apple-family targets only. The class references
  # UI::ContextMenu (Tier 3) which only exists on -Dmacos / -Dios.
  {% if flag?(:macos) || flag?(:ios) %}
    class StatusBar
      property identifier : String
      property title : String?
      property icon : String?
      property tooltip : String?
      property menu : ContextMenu?
      property is_template_icon : Bool = true
      property is_visible : Bool = true
      property is_installed : Bool = false

      def initialize(@identifier : String = "status-item",
                     @title : String? = nil,
                     @icon : String? = nil,
                     @tooltip : String? = nil,
                     @menu : ContextMenu? = nil)
      end

      def with_menu(menu : ContextMenu = ContextMenu.new, &block : ContextMenu -> Nil) : ContextMenu
        yield menu
        @menu = menu
        menu
      end

      def attach(menu : ContextMenu) : ContextMenu
        @menu = menu
        menu
      end

      def install : Bool
        @is_installed = StatusBars.install_item(self)
      end

      def uninstall : Nil
        StatusBars.uninstall_item(@identifier)
        @is_installed = false
      end

      def to_payload : String?
        menu = @menu
        return nil unless menu

        JSON.build do |json|
          json.object do
            json.field "items" do
              json.array do
                menu.items.each do |entry|
                  case entry
                  when UI::ContextMenu::Separator
                    json.object do
                      json.field "type", "separator"
                    end
                  when UI::ContextMenu::Item
                    json.object do
                      json.field "type", "item"
                      json.field "label", entry.label
                      json.field "identifier", menu_identifier(entry.label)
                      json.field "icon", entry.icon
                      json.field "is_destructive", entry.is_destructive
                      json.field "is_disabled", entry.is_disabled
                    end
                  end
                end
              end
            end
          end
        end
      end

      private def menu_identifier(label : String) : String
        "#{slugify(@identifier)}.#{slugify(label)}"
      end

      private def slugify(value : String) : String
        normalized = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
        normalized.empty? ? "item" : normalized
      end
    end
  {% end %}

  module StatusBars
    extend self

    {% if flag?(:macos) || flag?(:ios) %}
      lib LibObjCBridge
        fun ap_status_bar_apply(style : Int64, hidden : Int32, animated : Int32) : Int32
        fun ap_status_item_install(identifier : UInt8*, title : UInt8*, icon : UInt8*, tooltip : UInt8*, template_icon : Int32, visible : Int32, menu_payload : UInt8*) : Int32
        fun ap_status_item_uninstall(identifier : UInt8*) : Void
        fun ap_status_item_take_triggered_identifier : UInt8*
        fun ap_free_c_string(payload : UInt8*) : Void
      end
    {% end %}

    def apply(appearance : StatusBarAppearance) : Bool
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_status_bar_apply(
          appearance.style.value,
          appearance.hidden ? 1 : 0,
          appearance.animated ? 1 : 0
        ) == 1
      {% else %}
        false
      {% end %}
    end

    {% if flag?(:macos) || flag?(:ios) %}
      def install_item(item : UI::StatusBar) : Bool
        title_ptr = item.title ? item.title.not_nil!.to_unsafe : Pointer(UInt8).null
        icon_ptr = item.icon ? item.icon.not_nil!.to_unsafe : Pointer(UInt8).null
        tooltip_ptr = item.tooltip ? item.tooltip.not_nil!.to_unsafe : Pointer(UInt8).null
        payload = item.to_payload
        payload_ptr = payload ? payload.not_nil!.to_unsafe : Pointer(UInt8).null

        LibObjCBridge.ap_status_item_install(
          item.identifier.to_unsafe,
          title_ptr,
          icon_ptr,
          tooltip_ptr,
          item.is_template_icon ? 1 : 0,
          item.is_visible ? 1 : 0,
          payload_ptr
        ) == 1
      end
    {% else %}
      def install_item(item) : Bool
        false
      end
    {% end %}

    def uninstall_item(identifier : String) : Nil
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_status_item_uninstall(identifier.to_unsafe)
      {% end %}
    end

    def take_triggered_identifier : String?
      {% if flag?(:macos) || flag?(:ios) %}
        ptr = LibObjCBridge.ap_status_item_take_triggered_identifier
        return nil if ptr.null?

        begin
          String.new(ptr)
        ensure
          LibObjCBridge.ap_free_c_string(ptr)
        end
      {% else %}
        nil
      {% end %}
    end
  end
end
