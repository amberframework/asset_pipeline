# Abstract visitor interface that every platform renderer (Web / AppKit / UIKit /
# Android) implements to walk a UI::View tree and produce native output.

require "./views/*"

module UI
  # Abstract visitor for platform-specific rendering of UI views.
  #
  # Each concrete platform renderer (macOS/AppKit, iOS/UIKit, Android,
  # Web/HTML) implements this interface. The visitor pattern decouples
  # the view tree structure from rendering logic, allowing the same
  # view hierarchy to be rendered natively on any target platform.
  #
  # Example:
  #   class WebRenderer < UI::PlatformVisitor
  #     def visit(view : UI::Label)
  #       # emit <span> element
  #     end
  #     # ... implement all visit methods
  #   end
  abstract class PlatformVisitor
    abstract def visit(view : Label)
    abstract def visit(view : Button)
    abstract def visit(view : VStack)
    abstract def visit(view : HStack)
    abstract def visit(view : ZStack)
    abstract def visit(view : Image)
    abstract def visit(view : TextField)
    abstract def visit(view : ScrollView)
    abstract def visit(view : Spacer)
    abstract def visit(view : Toggle)
    abstract def visit(view : Checkbox)
    abstract def visit(view : RadioGroup)
    abstract def visit(view : Slider)
    abstract def visit(view : NavigationStack)
    abstract def visit(view : NavigationLink)
    abstract def visit(view : TabView)
    abstract def visit(view : ProgressView)
    abstract def visit(view : ActivityIndicator)
    abstract def visit(view : Alert)
    abstract def visit(view : Picker)
    abstract def visit(view : IconButton)
    abstract def visit(view : ListView)
    abstract def visit(view : OutlineView)
    def visit(view : ColumnView)
      view.fallback_view.accept(self)
    end
    def visit(view : TokenField)
      view.fallback_view.accept(self)
    end
    def visit(view : ImageWell)
      view.fallback_view.accept(self)
    end
    def visit(view : Panel)
      view.fallback_view.accept(self)
    end
    def visit(view : Gauge)
      view.fallback_view.accept(self)
    end
    def visit(view : ActivityRing)
      view.fallback_view.accept(self)
    end
    def visit(view : ActivityRings)
      view.fallback_view.accept(self)
    end
    abstract def visit(view : SecureField)
    abstract def visit(view : Stepper)
    abstract def visit(view : SegmentedControl)
    abstract def visit(view : DatePicker)
    abstract def visit(view : TimePicker)
    abstract def visit(view : SearchField)
    abstract def visit(view : TextArea)
    abstract def visit(view : Grid)
    abstract def visit(view : Form)
    abstract def visit(view : NavigationSplitView)
    abstract def visit(view : Toolbar)
    abstract def visit(view : Sheet)
    abstract def visit(view : Popover)
    abstract def visit(view : ConfirmationDialog)
    abstract def visit(view : Snackbar)
    abstract def visit(view : Card)
    abstract def visit(view : Surface)
    abstract def visit(view : Divider)
    abstract def visit(view : GlassBackground)
    # P2 Wave 3
    abstract def visit(view : AsyncImage)
    abstract def visit(view : RichText)
    abstract def visit(view : LinkButton)
    abstract def visit(view : MenuButton)
    {% if flag?(:macos) || flag?(:ios) %}
      abstract def visit(view : ContextMenu)
    {% end %}
    abstract def visit(view : ToggleButton)
    abstract def visit(view : TextEditor)
    # P3 Stubs
    abstract def visit(view : Circle)
    abstract def visit(view : Rectangle)
    abstract def visit(view : RoundedRectangle)
    abstract def visit(view : Capsule)
    abstract def visit(view : Canvas)
    abstract def visit(view : PathView)
    {% if flag?(:macos) %}
      abstract def visit(view : PathControl)
    {% end %}
    abstract def visit(view : MapView)
    abstract def visit(view : ChartView)
    abstract def visit(view : WebViewComponent)
    abstract def visit(view : ColorPicker)
    abstract def visit(view : VideoPlayer)
    abstract def visit(view : Tooltip)
    abstract def visit(view : ActivityView)
    abstract def visit(view : DisclosureGroup)
    abstract def visit(view : PageControl)
    abstract def visit(view : ComboBox)
    abstract def visit(view : RatingIndicator)

    # Phase 4 — Tier 3 widgets and their cross-platform fallback siblings.
    # ActionSheet is iOS-only after the Phase 4 gate ships; the abstract
    # visit declaration is itself gated so non-iOS renderers do not have
    # to implement a method that references an undefined class. The
    # WithWebFallback companion compiles everywhere.
    {% if flag?(:ios) %}
      abstract def visit(view : ActionSheet)
    {% end %}
    abstract def visit(view : ActionSheetWithWebFallback)
    abstract def visit(view : ContextMenuWithWebFallback)
    abstract def visit(view : PathControlWithWebFallback)

    # Phase 6.10 — SwipeActionRow. iOS renders SwiftUI .swipeActions;
    # macOS + desktop-web render visible trailing buttons; mobile-web
    # renders touch-swipe-to-reveal panel.
    abstract def visit(view : SwipeActionRow)
  end
end
