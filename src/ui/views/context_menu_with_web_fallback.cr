# Tier-3 context menu with a web-compatible fallback rendering on non-native targets.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"
{% if flag?(:macos) || flag?(:ios) %}
  require "./context_menu"
{% end %}

# Top-level namespace for the asset_pipeline cross-platform UI system.
module UI
  # Cross-platform companion to the Apple-family-only UI::ContextMenu.
  #
  # On -Dmacos / -Dios: delegates to a held UI::ContextMenu instance, so
  # the native renderer produces the standard NSMenu / UIMenu chrome.
  #
  # On every other target: renders directly. The web visitor produces a
  # role=menu positioned dropdown with arrow-key navigation, escape-to-
  # dismiss, and focus restoration (see context_menu_fallback.js).
  class ContextMenuWithWebFallback < View
    record Item,
      label : String,
      icon : String? = nil,
      is_destructive : Bool = false,
      is_disabled : Bool = false,
      action : Proc(Nil)? = nil

    struct Separator
    end

    alias Entry = Item | Separator

    property items : Array(Entry) = [] of Entry

    # Optional trigger view rendered as a child of the menu host so the
    # web fallback's vanilla-JS contextmenu / Shift+F10 handlers have an
    # element to bind to. When nil, the menu is still rendered (and can
    # be toggled programmatically by setting data-presented), but no
    # trigger is wired automatically.
    property trigger : View? = nil

    {% if flag?(:macos) || flag?(:ios) %}
      @inner : UI::ContextMenu

      def initialize(@trigger : View? = nil)
        @inner = UI::ContextMenu.new
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false, &block : -> Nil)
        @items << Item.new(
          label: label, icon: icon,
          is_destructive: is_destructive, is_disabled: is_disabled,
          action: block,
        )
        @inner.add_item(label, icon, is_destructive, is_disabled, &block)
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false)
        @items << Item.new(
          label: label, icon: icon,
          is_destructive: is_destructive, is_disabled: is_disabled,
        )
        @inner.add_item(label, icon, is_destructive, is_disabled)
      end

      def add_separator
        @items << Separator.new
        @inner.add_separator
      end

      def accept(visitor : PlatformVisitor)
        @inner.accept(visitor)
      end
    {% else %}
      def initialize(@trigger : View? = nil)
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false, &block : -> Nil)
        @items << Item.new(
          label: label, icon: icon,
          is_destructive: is_destructive, is_disabled: is_disabled,
          action: block,
        )
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false)
        @items << Item.new(
          label: label, icon: icon,
          is_destructive: is_destructive, is_disabled: is_disabled,
        )
      end

      def add_separator
        @items << Separator.new
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    {% end %}
  end
end
