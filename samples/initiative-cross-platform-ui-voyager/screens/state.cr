module Voyager
  # A single todo item — id, title, optional note, completed flag.
  class Todo
    property id : Int32
    property title : String
    property note : String
    property completed : Bool

    def initialize(@id : Int32, @title : String, @note : String = "", @completed : Bool = false)
    end
  end

  # Voyager's shared app state. Held by the NavigationCoordinator's
  # owning module-level VoyagerApp instance (NOT a class var with
  # initializer — per I-9 + the iOS class-init gap memory).
  #
  # State mutations (e.g. Settings toggle of `hide_completed`) take
  # effect AFTER the coordinator's on_change fires, so the visible
  # route is rebuilt from the new state. This is the state-propagation
  # litmus path:
  #   Settings toggle → state.hide_completed = true → coord.pop →
  #   coord notifies → host rebuilds Todos route with filtered list +
  #   recalculated chart counts.
  class State
    property current_user : String = ""
    property todos : Array(Todo)
    property hide_completed : Bool = false
    @next_id : Int32 = 1

    def initialize
      @todos = [] of Todo
      # Seed with a few items so the demo has visible content on
      # first launch (and the chart isn't empty).
      add_todo("Buy groceries", "Eggs, milk, bread", false)
      add_todo("Finish quarterly report", "Due Friday", false)
      add_todo("Call dentist", "", true)
      add_todo("Read a book", "Foundation, ch 3-5", false)
      add_todo("Water plants", "", true)
    end

    def add_todo(title : String, note : String = "", completed : Bool = false) : Todo
      todo = Todo.new(@next_id, title, note, completed)
      @next_id += 1
      @todos << todo
      todo
    end

    def find_todo(id : Int32) : Todo?
      @todos.find { |t| t.id == id }
    end

    def delete_todo(id : Int32) : Nil
      @todos.reject! { |t| t.id == id }
    end

    # The currently visible todos, after the Settings filter is
    # applied. This is the field the state-propagation litmus
    # exercises: toggling hide_completed in Settings + popping back
    # to Todos must immediately use the filtered result.
    def visible_todos : Array(Todo)
      return @todos unless @hide_completed
      @todos.reject(&.completed)
    end

    # Open count over the visible todos (so the chart reflects the
    # filtered list when hide_completed is on — matches the brief's
    # state-propagation litmus: "Todos list AND chart reflect"
    # means the chart numbers move when filtering kicks in).
    def open_count : Int32
      visible_todos.count { |t| !t.completed }
    end

    def completed_count : Int32
      visible_todos.count(&.completed)
    end

    # Underlying counts (full list, regardless of filter) — exposed
    # for callers that need the unfiltered totals.
    def open_count_total : Int32
      @todos.count { |t| !t.completed }
    end

    def completed_count_total : Int32
      @todos.count(&.completed)
    end
  end

  # Phase 8D.1 — Voyager.state module singleton.
  #
  # The new `UI::Screen` API hands screens a `ScreenContext::Native` and
  # NO direct `state` reference. So Voyager screens reach into the
  # process-wide `Voyager::State` via this accessor. macOS host sets it
  # once in `VoyagerHost.run!`; the `Voyager.build_route` compat shim
  # sets it on every call (so existing test specs that construct a fresh
  # `state = Voyager::State.new` and pass it through the shim continue to
  # exercise the same state-propagation contract).
  #
  # iOS class-init gap (see `project_crystal_ios_class_init_gap` memory):
  # we deliberately AVOID a default-initialiser class var. The accessor
  # lazy-allocates a default `State.new` on first read so even targets
  # that skip module-load side effects work.
  @@state : State? = nil

  def self.state : State
    @@state ||= State.new
  end

  def self.state=(new_state : State) : State
    @@state = new_state
  end
end
