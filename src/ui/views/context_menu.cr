# Long-press / right-click contextual menu attached to a host view.
# Part of the asset_pipeline cross-platform UI::View catalog.

require "../view"

{% if flag?(:macos) || flag?(:ios) %}
  # Top-level namespace for the asset_pipeline cross-platform UI system.
  module UI
    # Tier 3 — Apple-family only (macOS + iOS). Use UI::ContextMenuWithWebFallback
    # to render an equivalent dropdown menu on web.
    #
    # On every other target, naming this class is a compile-time error
    # (see _gate_stubs/context_menu.cr).
    class ContextMenu < View
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

      def initialize
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false, &block : -> Nil)
        @items << Item.new(
          label: label,
          icon: icon,
          is_destructive: is_destructive,
          is_disabled: is_disabled,
          action: block
        )
      end

      def add_item(label : String, icon : String? = nil, is_destructive : Bool = false, is_disabled : Bool = false)
        @items << Item.new(
          label: label,
          icon: icon,
          is_destructive: is_destructive,
          is_disabled: is_disabled
        )
      end

      def add_separator
        @items << Separator.new
      end

      def accept(visitor : PlatformVisitor)
        visitor.visit(self)
      end
    end
  end
{% else %}
  # Defer the actionable raise to the stub file — see the macro-expansion
  # rationale in src/ui/views/_gate_stubs/context_menu.cr.
  require "./_gate_stubs/context_menu"
{% end %}
