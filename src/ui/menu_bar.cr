# Declarative top-level menu structure for the macOS / iPad app-shell menu bar.
# Not a UI::View — the visible menu bar belongs to AppKit; this model is
# installed into the host application's main menu.

require "json"

module UI
  # Declarative top-level menu structure for app-shell command chrome.
  #
  # UI::MenuBar is intentionally not a UI::View: the visible menu bar
  # belongs to AppKit. This object keeps the menu intent in Crystal and can
  # install it into the host application's main menu on macOS / iPad.
  #
  # Phase 4: gated to Apple-family targets only. The class references
  # UI::ContextMenu (now a Tier 3 widget) which only exists on -Dmacos /
  # -Dios. Non-Apple builds get a no-op MenuBars module so existing
  # call sites remain source-compatible.
  {% if flag?(:macos) || flag?(:ios) %}
    class MenuBar
      record Menu,
        title : String,
        menu : ContextMenu

      property menus : Array(Menu) = [] of Menu
      property is_installed : Bool = false

      def initialize
      end

      def add_menu(title : String, menu : ContextMenu = ContextMenu.new, &block : ContextMenu -> Nil) : ContextMenu
        yield menu
        @menus << Menu.new(title: title, menu: menu)
        menu
      end

      def add_menu(title : String, menu : ContextMenu = ContextMenu.new) : ContextMenu
        @menus << Menu.new(title: title, menu: menu)
        menu
      end

      def remove_menu(title : String) : Bool
        before = @menus.size
        @menus.reject! { |entry| entry.title == title }
        before != @menus.size
      end

      def clear : Nil
        @menus.clear
        MenuBars.clear if @is_installed
        @is_installed = false
      end

      def install : Bool
        @is_installed = MenuBars.install(self)
      end

      def uninstall : Nil
        MenuBars.clear
        @is_installed = false
      end

      def to_payload : String
        JSON.build do |json|
          json.object do
            json.field "menus" do
              json.array do
                @menus.each do |entry|
                  json.object do
                    json.field "title", entry.title
                    json.field "items" do
                      serialize_context_menu(json, entry.menu, entry.title)
                    end
                  end
                end
              end
            end
          end
        end
      end

      private def serialize_context_menu(json : JSON::Builder, menu : ContextMenu, menu_title : String) : Nil
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
                json.field "identifier", menu_identifier(menu_title, entry.label)
                json.field "icon", entry.icon
                json.field "is_destructive", entry.is_destructive
                json.field "is_disabled", entry.is_disabled
              end
            end
          end
        end
      end

      private def menu_identifier(menu_title : String, label : String) : String
        "#{slugify(menu_title)}.#{slugify(label)}"
      end

      private def slugify(value : String) : String
        normalized = value.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-+|-+$/, "")
        normalized.empty? ? "item" : normalized
      end
    end
  {% end %}

  module MenuBars
    extend self

    {% if flag?(:macos) || flag?(:ios) %}
      lib LibObjCBridge
        fun ap_menu_bar_install(payload : UInt8*) : Int32
        fun ap_menu_bar_clear : Void
        fun ap_menu_bar_take_triggered_identifier : UInt8*
        fun ap_free_c_string(payload : UInt8*) : Void
      end

      def install(menu_bar : UI::MenuBar) : Bool
        LibObjCBridge.ap_menu_bar_install(menu_bar.to_payload.to_unsafe) == 1
      end
    {% else %}
      # Non-Apple builds expose a no-op install so call sites compile
      # without referencing UI::MenuBar (which does not exist on these
      # targets). Pass `nil` or any object; the call returns false.
      def install(menu_bar) : Bool
        false
      end
    {% end %}

    def clear : Nil
      {% if flag?(:macos) || flag?(:ios) %}
        LibObjCBridge.ap_menu_bar_clear
      {% end %}
    end

    def take_triggered_identifier : String?
      {% if flag?(:macos) || flag?(:ios) %}
        ptr = LibObjCBridge.ap_menu_bar_take_triggered_identifier
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
