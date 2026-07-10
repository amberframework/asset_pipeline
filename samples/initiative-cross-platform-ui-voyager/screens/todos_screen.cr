module Voyager
  # Voyager — Todos screen.
  #
  # Phase 8D.1: migrated from module-level class with
  # `build(state, coord)` to `UI::Screen` subclass with
  # `build(ctx : UI::ScreenContext) : UI::View`. All callbacks route
  # through `Voyager.dispatch(action_ref, action_params)` per the
  # brief's action ref convention.
  class TodosScreen < UI::Screen
    SLUG = "voyager-todos"

    def build(context : UI::ScreenContext) : UI::View
      metrics = UI::DesignTokens::DeviceMetrics.current
      content_width = metrics.compact_horizontal? ? 340.0 : 480.0

      state = Voyager.state

      root = UI::VStack.new(spacing: 16.0)
      root.root_fill = true
      root.alignment = UI::Alignment::Leading
      root.padding = UI::EdgeInsets.new(
        top: 24.0 + metrics.safe_area_top_pt,
        trailing: 20.0 + metrics.safe_area_trailing_pt,
        bottom: 24.0 + metrics.safe_area_bottom_pt,
        leading: 20.0 + metrics.safe_area_leading_pt,
      )
      root.accessibility_label = "Voyager todos screen"
      root.test_id = "voyager-todos-root"

      header = UI::HStack.new(spacing: 8.0)
      header.alignment = UI::Alignment::Center
      header.minimum_width = content_width
      header.maximum_width = content_width

      title = UI::Label.new("Todos")
      title.font = UI::Font.new(size: 28.0, weight: :bold)
      title.text_color_role = UI::LabelRole::Primary

      spacer = UI::Spacer.new

      settings_btn = UI::Button.new("Settings")
      settings_btn.role = :secondary
      settings_btn.accessibility_label = "Settings"
      settings_btn.test_id = "voyager-todos-settings"
      # Phase 8D.1 — :open_settings routes to TodosController#open_settings
      # which returns Navigate(:settings).
      settings_btn.on_tap = -> { Voyager.dispatch(:open_settings) }

      header << title.as(UI::View)
      header << spacer.as(UI::View)
      header << settings_btn.as(UI::View)

      chart_row = UI::HStack.new(spacing: 16.0)
      chart_row.alignment = UI::Alignment::Center
      chart_row.minimum_width = content_width
      chart_row.maximum_width = content_width

      open_card = build_count_card("Open", state.open_count_total.to_s, :primary, dimmed: false)
      completed_card = build_count_card("Done", state.completed_count_total.to_s, :secondary, dimmed: state.hide_completed)
      chart_row << open_card
      chart_row << completed_card

      banner : UI::View? = nil
      if state.hide_completed
        b = UI::Label.new("Completed items hidden (toggle in Settings)")
        b.font = UI::Font.new(size: 13.0, weight: :regular)
        b.text_color_role = UI::LabelRole::Tertiary
        b.test_id = "voyager-todos-filter-banner"
        banner = b.as(UI::View)
      end

      list_stack = UI::VStack.new(spacing: 8.0)
      list_stack.alignment = UI::Alignment::Leading
      list_stack.minimum_width = content_width
      list_stack.maximum_width = content_width
      list_stack.test_id = "voyager-todos-list"

      visible = state.visible_todos
      visible.each do |todo|
        list_stack << build_todo_row(todo, content_width).as(UI::View)
      end

      add_btn = UI::Button.new("Add Todo", style: UI::ButtonStyle::Prominent)
      add_btn.accessibility_label = "Add a new todo"
      add_btn.test_id = "voyager-todos-add"
      add_btn.minimum_width = content_width
      add_btn.maximum_width = content_width
      # Phase 8D.1 — :new_todo routes to TodosController#new_todo which
      # returns Navigate(:todo_editor, params: {todo_id: "0"}).
      add_btn.on_tap = -> { Voyager.dispatch(:new_todo) }

      root << header.as(UI::View)
      root << chart_row.as(UI::View)
      if b = banner
        root << b
      end
      root << list_stack.as(UI::View)
      root << add_btn.as(UI::View)

      root.as(UI::View)
    end

    private def build_count_card(label : String, value : String, tint : Symbol, dimmed : Bool = false) : UI::View
      card = UI::VStack.new(spacing: 4.0)
      card.alignment = UI::Alignment::Leading
      card.padding = UI::EdgeInsets.new(top: 12.0, trailing: 16.0, bottom: 12.0, leading: 16.0)
      card.minimum_width = 120.0

      v = UI::Label.new(value)
      v.font = UI::Font.new(size: 32.0, weight: :bold)
      v.text_color_role = if dimmed
                            UI::LabelRole::Tertiary
                          else
                            tint == :primary ? UI::LabelRole::Primary : UI::LabelRole::Secondary
                          end
      v.test_id = "voyager-count-#{label.downcase}"

      l = UI::Label.new(label)
      l.font = UI::Font.new(size: 13.0, weight: :regular)
      l.text_color_role = UI::LabelRole::Tertiary
      l.opacity = dimmed ? 0.6 : 1.0

      card << v.as(UI::View)
      card << l.as(UI::View)
      card.as(UI::View)
    end

    private def build_todo_row(todo : Todo, content_width : Float64) : UI::View
      content = UI::HStack.new(spacing: 12.0)
      content.alignment = UI::Alignment::Center
      content.padding = UI::EdgeInsets.new(top: 10.0, trailing: 12.0, bottom: 10.0, leading: 12.0)
      content.test_id = "voyager-todo-row-#{todo.id}"

      check = UI::Checkbox.new(label: "", is_checked: todo.completed)
      check.accessibility_label = todo.completed ? "Mark '#{todo.title}' as not done" : "Mark '#{todo.title}' as done"
      check.test_id = "voyager-todo-row-#{todo.id}-check"
      # Phase 8D.1 — :toggle_row dispatched with row identity in
      # action_params. Controller mutates state + returns Rerender so
      # the host rebuilds Todos with the new completed-state styling.
      todo_id_str = todo.id.to_s
      check.on_change = ->(_value : Bool) {
        Voyager.dispatch(:toggle_row, {"todo_id" => todo_id_str})
      }

      title_label = UI::Label.new(todo.title)
      title_label.font = UI::Font.new(size: 16.0, weight: :semibold)
      title_label.text_color_role = todo.completed ? UI::LabelRole::Secondary : UI::LabelRole::Primary
      title_label.strikethrough = todo.completed
      title_label.test_id = "voyager-todo-row-#{todo.id}-title"

      content << check.as(UI::View)
      content << title_label.as(UI::View)

      row = UI::SwipeActionRow.new(content.as(UI::View))
      row.accessibility_label = "Todo: #{todo.title}"
      row.minimum_width = content_width
      row.maximum_width = content_width

      # Phase 8D.1 — swipe actions carry row identity via action_params,
      # which the dispatcher forwards into ctx.action_params on the
      # controller's invocation.
      edit_action = UI::SwipeAction.new(
        "Edit",
        on_tap: -> {
          Voyager.dispatch(:edit_row, {"todo_id" => todo_id_str})
        },
        on_tap_route: "voyager-todo-editor",
      )
      del_action = UI::SwipeAction.new(
        "Delete",
        on_tap: -> {
          Voyager.dispatch(:delete_row, {"todo_id" => todo_id_str})
        },
        role: :destructive,
      )

      row.trailing_actions = [edit_action, del_action]
      row.as(UI::View)
    end
  end
end
