# Tier 2 Translation Contract

**Companion to:** `intent-catalog.md`, `intent-routing-candidates.md`.

This document defines the contract for how the framework translates user intents into concrete `UI::View` instances per platform. It is the architectural authority for Phase 10 implementation work — Phase 10 implements; this doc decides.

---

## Scope

The contract applies ONLY to Class A intents (`:swipe_actions`, currently the only entry). All other classes have their own documentation shapes:

- **Class B** — framework-contract intents (accessibility, reduced motion, dynamic type) — documented as invariants every widget honors. No contract; renderer enforces.
- **Class C** — system-integration intents (share, clipboard, permissions) — documented as bridged-API surfaces. Single Crystal API, different native implementation per platform.
- **Class D** — native modifier intents — documented as direct Crystal-API-to-SwiftUI-modifier translations. No contract overhead.

Most of Phase 8's existing widgets (`UI::Button`, `UI::Slider`, `UI::TextField`, etc.) are Class D. They have stable universal APIs that the renderer translates 1:1 to platform-native widgets. They don't need (and shouldn't pay for) intent routing.

---

## The four-part contract (Class A only)

A Class A intent declares all four parts:

### 1. `intent_id`

A Crystal Symbol naming the intent. MUST be the snake_case form of `primary_apple_name` in the catalog (`swipeActions` → `:swipe_actions`).

### 2. `capabilities`

A block of named predicates that the intent supports + requires. Two purposes:

- **Documents what an override widget must provide.** If a substitute widget doesn't declare `supports_role :destructive` but the intent requires it, registration raises.
- **Documents HIG-derived invariants.** `requires_visible_or_keyboard_alternative` encodes the HIG `gestures.md:23` rule that gestures cannot be sole paths to functions.

Capability predicates are named conventionally:
- `supports_X` / `supports_X(value)` — the intent supports the feature.
- `requires_X` — the intent demands the feature from any widget realization.
- `preserves_X` — the intent must preserve some property across activations.
- `does_not_conflict_with_X` — the intent's gesture/affordance must not collide with X.

### 3. `defaults`

A per-platform-key map of concrete `UI::View` classes. Six keys: `:ios, :ipados, :macos, :android, :web_wide, :web_narrow`.

Each value is a `UI::View` subclass. If the framework has no shipped widget for that platform default, the value is the symbol `:missing` and a backlog entry exists in `intent-backlog.md`.

### 4. `override_registry`

App-scoped + screen-scoped registries with precedence `screen > app > default`.

App-level registration:
```crystal
class VoyagerApp < UI::App
  override_intent :swipe_actions, with: UI::DragHandleRow, on: [:web_wide]
end
```

Screen-level registration:
```crystal
class SettingsScreen < UI::Screen
  override_intent :swipe_actions, with: UI::InlineActionRow, on: [:ios]
end
```

Platform key `:all` matches every platform.

---

## Resolver (deferred to Phase 10+)

A Class A intent is resolved at render time via `UI::Intent.resolve(intent_id, ctx)`:

```crystal
# In a screen's build method:
row_widget_class = UI::Intent.resolve(:swipe_actions, ctx)
row = row_widget_class.new(content: row_content, actions: [edit, delete])
```

The resolver walks the registries in precedence order, returns the resolved widget class, and the screen author constructs the widget normally.

**Why a resolver, not a high-level constructor?** Crystal type erasure makes `UI::ActionableRow.new(...)` returning different concrete classes painful: the return type is `UI::View` (loss of type info), or the constructor is generic (unwieldy at the call site), or every override widget must share an identical public API (over-constraining). The resolver pattern lets each concrete widget keep its specific API; the author asks the framework "which widget" then calls its constructor directly.

Phase 10 implements the resolver. Phase 9 documents the shape.

---

## Override capability validation

Override registration validates the substitute widget against the intent's `capabilities`. The validation runs at app-bootstrap time (or screen-load time for screen-scoped overrides), not at render time — failures are caught before a user sees the UI.

Validation rules:

1. The override widget MUST declare its OWN capabilities block. Widgets without one cannot be used as overrides.
2. For every capability the intent `requires_`, the override widget MUST declare a matching `provides_` or the analogous capability.
3. For every capability the intent `supports_`, the override MAY declare it — but if absent, the override's renderer cannot use that feature.
4. The override widget's class MUST be a subclass of `UI::View`.

Failure raises `UI::Intent::CapabilityMismatchError` with a specific message naming the missing capability and the HIG rationale.

### Example failure

```
UI::Intent::CapabilityMismatchError:
  Override for :swipe_actions with UI::DragHandleRow on platforms [:macos, :web_wide]
  failed capability validation.

  Missing required capability: requires_accessibility_custom_actions

  Source: HIG accessibility.md:134 — "Offer alternatives to gestures.
  Gestures can be less comfortable for people who have limited dexterity,
  so offer onscreen ways to achieve the same outcome."

  Resolution: UI::DragHandleRow must declare `provides_accessibility_custom_actions`
  in its widget capabilities block, OR a different override widget should be chosen.
```

---

## Class D documentation shape (for contrast)

Class D entries do NOT carry a four-part contract. They document the Crystal API that emits the SwiftUI modifier 1:1.

Example for `:refreshable`:

```crystal
# Class D intent: refreshable
#
# Apple API:   .refreshable { await reload() }
# UIKit API:   UIRefreshControl on UIScrollView
# AppKit API:  no native; emit ToolbarItem refresh fallback
# HIG page:    lists-and-tables.md
#
# Crystal API:
#   list.refreshable = -> { state.reload_todos }
#
# Platforms honored: iOS, iPadOS, Android (Material PullRefreshContainer).
# macOS: emit an explicit ToolbarItem refresh fallback (renderer responsibility).
# Web: custom JS implementation OR ToolbarItem fallback.
```

No capabilities block. No defaults table. No override registry. The Crystal API is the contract; renderers translate to the native modifier.

If a Class D entry needs DIFFERENT widgets per platform (not just different modifier emission), that's a signal to reclassify it as Class A.

---

## Implementation pseudocode (for Phase 10)

This is the implementation shape Phase 10 builds against. It's NOT shipped in Phase 9 — Phase 9 is docs-only.

```crystal
module UI
  module Intent
    # Registry singleton keyed by intent_id.
    class Registry
      @@app_overrides = {} of Symbol => Hash(Symbol, UI::View.class)
      @@screen_overrides = {} of {Symbol, UI::Screen.class} => Hash(Symbol, UI::View.class)
      @@defaults = {} of Symbol => Hash(Symbol, UI::View.class)
      @@capabilities = {} of Symbol => CapabilitySet

      def self.register_intent(intent_id : Symbol, capabilities : CapabilitySet, defaults : Hash(Symbol, UI::View.class))
        @@capabilities[intent_id] = capabilities
        @@defaults[intent_id] = defaults
      end

      def self.register_app_override(intent_id : Symbol, widget : UI::View.class, on platforms : Array(Symbol))
        validate_capability_match!(intent_id, widget)
        platforms.each do |platform|
          @@app_overrides[intent_id] ||= {} of Symbol => UI::View.class
          @@app_overrides[intent_id][platform] = widget
        end
      end

      def self.register_screen_override(intent_id : Symbol, screen_class : UI::Screen.class, widget : UI::View.class, on platforms : Array(Symbol))
        validate_capability_match!(intent_id, widget)
        platforms.each do |platform|
          @@screen_overrides[{intent_id, screen_class}] ||= {} of Symbol => UI::View.class
          @@screen_overrides[{intent_id, screen_class}][platform] = widget
        end
      end

      def self.resolve(intent_id : Symbol, ctx : UI::ScreenContext) : UI::View.class
        platform = current_platform_key(ctx)   # :ios / :ipados / etc.

        # 1. screen override
        if ctx.current_screen
          screen_class = ctx.current_screen.class
          if override = @@screen_overrides[{intent_id, screen_class}]?
            if widget = override[platform]?
              return widget
            end
          end
        end

        # 2. app override
        if override = @@app_overrides[intent_id]?
          if widget = override[platform]?
            return widget
          end
        end

        # 3. framework default
        if defaults = @@defaults[intent_id]?
          if widget = defaults[platform]?
            return widget
          end
        end

        raise UI::Intent::UnresolvableError.new(intent_id, platform)
      end

      private def self.validate_capability_match!(intent_id : Symbol, widget : UI::View.class)
        required = @@capabilities[intent_id].required
        provided = widget.capabilities.provided
        missing = required - provided
        unless missing.empty?
          raise UI::Intent::CapabilityMismatchError.new(intent_id, widget, missing)
        end
      end
    end
  end
end
```

This sketch is non-binding; Phase 10 may adjust the API as long as the contract semantics survive.

---

## Acceptance examples (what Phase 10 must support)

### Example 1 — App uses framework defaults

```crystal
class VoyagerApp < UI::App
  # No overrides. Framework default for :swipe_actions
  # → UI::SwipeActionRow on iOS/iPadOS/Android/web_narrow
  # → UI::InlineActionRow on macOS/web_wide (Phase 10 backlog)
end

class TodosScreen < UI::Screen
  def build(ctx)
    list = UI::VStack.new
    state.todos.each do |todo|
      row_class = UI::Intent.resolve(:swipe_actions, ctx)
      row = row_class.new(content: todo_row(todo), actions: [edit_action(todo), delete_action(todo)])
      list << row
    end
    list
  end
end
```

### Example 2 — App-level override

```crystal
class VoyagerApp < UI::App
  override_intent :swipe_actions, with: UI::InlineActionRow, on: [:ios]
end
```

After this registration, every screen in VoyagerApp uses `UI::InlineActionRow` on iOS instead of the default `UI::SwipeActionRow`.

### Example 3 — Screen-level override

```crystal
class SettingsScreen < UI::Screen
  override_intent :swipe_actions, with: UI::InlineActionRow, on: :all
end
```

Only `SettingsScreen` uses `UI::InlineActionRow` on every platform.

### Example 4 — Failed override

```crystal
class VoyagerApp < UI::App
  override_intent :swipe_actions, with: UI::PlainRow, on: [:ios]
end

# Raises at registration time:
# UI::Intent::CapabilityMismatchError:
#   UI::PlainRow does not provide: supports_role :destructive,
#   supports_disabled_actions, supports_voiceover_actions, ...
```

---

## Repo evidence cited

This contract derives from real-world experience in the codebase:

- **`src/ui/views/swipe_action_row.cr`** — Apple vocabulary already used in comments (`swipeActions`, `UISwipeActionsConfiguration`). The widget today does double-duty: iOS swipe-reveal AND macOS inline-buttons in one class. This contract formalizes the split.
- **`src/ui/views/context_menu.cr`** — Class D example. One Crystal API, renderers translate to platform-native gesture (long-press / right-click).
- **`src/ui/views/button.cr`** — Class D counterexample. Stable universal API; no override would change which class is constructed. The contract correctly leaves it alone.
- **`src/ui/design_tokens.cr`** — `UI::DesignTokens::Brand` is the architectural analog. Apps override brand colors by subclassing `Brand`; this contract extends the same pattern from token values to widget choice.

— Architect (Claude Opus 4.7)
