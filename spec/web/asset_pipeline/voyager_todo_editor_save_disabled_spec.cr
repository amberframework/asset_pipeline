require "../spec_helper"
require "../../../samples/initiative-cross-platform-ui-voyager/app"

# Phase 8D.3a — Save-enabled-on-type wiring proof.
#
# TWO sections:
#   2a — screen-authored closure spec. Locates title_field + save by
#        test_id; invokes `title_field.on_change.not_nil!.call(value)`
#        directly. Proves the screen assigned a closure that mutates
#        `save.disabled` correctly for empty/whitespace/non-blank/cleared
#        values + the editing-prefilled-then-cleared scenario.
#
#   2b — renderer-hook composition spec. Mirrors what the UIKit / AppKit
#        renderer's `visit(UI::TextField)` does: sets
#        `UI::FormState.current` + `current_mount_token`, calls
#        `UI::FormStateRendererHook.wrap_text_handler(title_field)` to
#        obtain the WRAPPED proc, then invokes that wrapped proc with
#        sample values. Asserts BOTH:
#          - `fs["title"]` is updated (FormState write composed in first),
#          - `save.disabled` matches the closure's mirror logic (user
#            closure ran second in the composition).
#        This is the unit proof that the screen's closure + the renderer's
#        wrap compose correctly. Without 2b, only the screen author's
#        intent is verified; the LIVE iOS integration (renderer-time
#        wrap + native text event) is proved by Item 4 step 8 hand-test.

# Walks a built view tree depth-first, returning the first view whose
# `test_id` matches the requested id (or nil if no match). Recurses
# into VStack / HStack / ZStack children.
private def find_view_by_test_id(view : UI::View, id : String) : UI::View?
  return view if view.test_id == id

  children : Array(UI::View)? = nil
  case view
  when UI::VStack then children = view.children
  when UI::HStack then children = view.children
  when UI::ZStack then children = view.children
  end

  if children
    children.each do |child|
      if hit = find_view_by_test_id(child, id)
        return hit
      end
    end
  end
  nil
end

# Build a fresh ScreenContext::Native pre-seeded with the given
# `todo_id` so the editor's `ctx.params["todo_id"]` resolves.
# Optionally accepts a dispatcher so the editor's call to
# `Voyager.dispatcher.try(&.current_form_state)` returns a usable
# FormState (matches the pattern in voyager_dispatcher_integration_spec).
private def make_editor_ctx(todo_id : String = "0", mount_token : Int64 = 1_i64) : UI::ScreenContext::Native
  fs = UI::FormState.new(mount_token: mount_token)
  fs.register("todo_id", todo_id)
  coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:todo_editor))
  UI::ScreenContext::Native.new(
    form_state: fs,
    session: UI::Session::InProcess.new,
    flash: UI::Flash::InProcess.new,
    design_tokens: UI::DesignTokens::Tokens.default,
    navigation: coord,
    action_params: {} of String => String,
  )
end

describe "Phase 8D.3a — Voyager TodoEditor Save-enabled-on-type wiring" do
  describe "Section 2a — screen-authored closure" do
    it "Save is disabled when initial title is empty (new-todo flow)" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "0"))

      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)
      save.disabled.should be_true
    end

    it "Save is enabled when initial title is non-blank (edit-existing flow)" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      # todo_id "1" — the seeded "Buy groceries" todo.
      root = screen.build(make_editor_ctx(todo_id: "1"))

      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)
      save.disabled.should be_false
    end

    it "closure: empty string disables Save" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      # Open in edit mode so initial disabled is false; then prove the
      # closure flips it to true when the title is cleared.
      root = screen.build(make_editor_ctx(todo_id: "1"))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      save.disabled.should be_false
      title_field.on_change.not_nil!.call("")
      save.disabled.should be_true
    end

    it "closure: whitespace-only string disables Save" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "1"))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      title_field.on_change.not_nil!.call("   ")
      save.disabled.should be_true

      title_field.on_change.not_nil!.call("\t\n")
      save.disabled.should be_true
    end

    it "closure: non-blank string enables Save" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "0"))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      save.disabled.should be_true
      title_field.on_change.not_nil!.call("anything")
      save.disabled.should be_false
    end

    it "closure: title cleared after typing flips Save back to disabled" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "0"))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      title_field.on_change.not_nil!.call("Buy milk")
      save.disabled.should be_false

      title_field.on_change.not_nil!.call("")
      save.disabled.should be_true
    end

    it "editing-prefilled then cleared: closure flips Save to disabled" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil
      UI::FormState.reset_renderer_hooks!

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "1"))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      # Edit-prefilled flow: initial state has Save enabled.
      save.disabled.should be_false

      # User clears the field.
      title_field.on_change.not_nil!.call("")
      save.disabled.should be_true

      # User types again.
      title_field.on_change.not_nil!.call("Buy milk again")
      save.disabled.should be_false
    end
  end

  describe "Section 2b — renderer-hook composition (FormStateRendererHook.wrap_text_handler)" do
    it "wrapped handler updates fs[\"title\"] AND mutates save.disabled on every keystroke" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil

      # Simulate the dispatcher's wire-time renderer-hook setup: a
      # FormState is mounted as current with a matching token.
      UI::FormState.reset_renderer_hooks!
      fs = UI::FormState.new(mount_token: 42_i64)
      UI::FormState.current = fs
      UI::FormState.current_mount_token = 42_i64

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "0", mount_token: 42_i64))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      # Sanity: initial new-todo state is empty title + disabled Save.
      save.disabled.should be_true

      # Renderer-time composition: wrap the screen-authored on_change
      # through the same hook the UIKit/AppKit renderer uses.
      wrapped = UI::FormStateRendererHook.wrap_text_handler(title_field).not_nil!

      # Keystroke: user types "x".
      wrapped.call("x")
      fs["title"].should eq("x")        # FormState write composed in
      save.disabled.should be_false     # screen closure ran after

      # Keystroke: user clears the field.
      wrapped.call("")
      fs["title"].should eq("")
      save.disabled.should be_true

      # Keystroke: user types whitespace.
      wrapped.call("   ")
      fs["title"].should eq("   ")      # FormState records raw value
      save.disabled.should be_true      # closure uses .strip.empty?

      # Keystroke: user types a real title.
      wrapped.call("Buy milk")
      fs["title"].should eq("Buy milk")
      save.disabled.should be_false

      UI::FormState.reset_renderer_hooks!
    end

    it "wrapped handler is a full no-op when mount tokens mismatch (stale fire)" do
      Voyager.state = Voyager::State.new
      Voyager.dispatcher = nil

      UI::FormState.reset_renderer_hooks!
      fs_a = UI::FormState.new(mount_token: 1_i64)
      UI::FormState.current = fs_a
      UI::FormState.current_mount_token = 1_i64

      screen = Voyager::TodoEditorScreen.new
      root = screen.build(make_editor_ctx(todo_id: "1", mount_token: 1_i64))
      title_field = find_view_by_test_id(root, "voyager-todo-editor-title").as(UI::TextField)
      save = find_view_by_test_id(root, "voyager-todo-editor-save").as(UI::Button)

      # Editor opened in edit-existing mode: Save is enabled.
      save.disabled.should be_false

      wrapped = UI::FormStateRendererHook.wrap_text_handler(title_field).not_nil!

      # Navigate away — dispatcher swaps in a new FormState/token.
      fs_b = UI::FormState.new(mount_token: 2_i64)
      UI::FormState.current = fs_b
      UI::FormState.current_mount_token = 2_i64

      # Stale fire. Neither FormState write NOR user closure runs.
      wrapped.call("")
      fs_a["title"].should eq("Buy groceries") # wire-time register seeded title
      save.disabled.should be_false             # closure did NOT run (still enabled)

      UI::FormState.reset_renderer_hooks!
    end
  end
end
