require "spec"
require "../../src/asset_pipeline"
require "../../src/components"
require "../../src/ui"
require "../../src/asset_pipeline/amber_integration"
require "../../src/asset_pipeline/native_controller"
require "../../src/asset_pipeline/native_app"

class APICardProbeVisitor < UI::PlatformVisitor
  {% for view_type in [
                        UI::Label, UI::Button, UI::VStack, UI::HStack, UI::ZStack, UI::Image,
                        UI::TextField, UI::ScrollView, UI::Spacer, UI::Toggle, UI::Checkbox,
                        UI::RadioGroup, UI::Slider, UI::NavigationStack, UI::NavigationLink,
                        UI::TabView, UI::ProgressView, UI::ActivityIndicator, UI::Alert,
                        UI::Picker, UI::IconButton, UI::ListView, UI::OutlineView,
                        UI::SecureField, UI::Stepper, UI::SegmentedControl, UI::DatePicker,
                        UI::TimePicker, UI::SearchField, UI::TextArea, UI::Grid, UI::Form,
                        UI::NavigationSplitView, UI::Toolbar, UI::Sheet, UI::Popover,
                        UI::ConfirmationDialog, UI::Snackbar, UI::Card, UI::Surface,
                        UI::Divider, UI::GlassBackground, UI::AsyncImage, UI::RichText,
                        UI::LinkButton, UI::MenuButton, UI::ToggleButton, UI::TextEditor,
                        UI::Circle, UI::Rectangle, UI::RoundedRectangle, UI::Capsule,
                        UI::Canvas, UI::PathView, UI::MapView, UI::ChartView,
                        UI::WebViewComponent, UI::ColorPicker, UI::VideoPlayer, UI::Tooltip,
                        UI::DisclosureGroup, UI::PageControl, UI::ComboBox,
                        UI::RatingIndicator, UI::ActionSheetWithWebFallback,
                        UI::ContextMenuWithWebFallback, UI::PathControlWithWebFallback,
                        UI::SwipeActionRow,
                      ] %}
    def visit(view : {{view_type}}) : Nil
    end
  {% end %}

  def visit(view : UI::ActivityView) : Nil
    view.title
    nil
  end

  {% if flag?(:macos) || flag?(:ios) %}
    def visit(view : UI::ContextMenu) : Nil
    end
  {% end %}

  {% if flag?(:macos) %}
    def visit(view : UI::PathControl) : Nil
    end
  {% end %}

  {% if flag?(:ios) %}
    def visit(view : UI::ActionSheet) : Nil
    end
  {% end %}
end

{% if flag?(:macos) || flag?(:ios) %}
  class APICardProbeSender < UI::Native::Populator::Sender
    def set_color(target : String, setter : Symbol, color : UI::Color?)
    end

    def set_number(target : String, setter : Symbol, value : Float64?)
    end

    def set_bool(target : String, setter : Symbol, value : Bool?)
    end

    def set_string(target : String, setter : Symbol, value : String?)
    end
  end
{% end %}
