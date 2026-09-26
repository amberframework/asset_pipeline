require "./ui/fluid"
# Phase 10B.2c iter 2 — `UI::Environment` is referenced from
# `UI::RenderContext` (in `view.cr`), so it must load BEFORE `view.cr`.
require "./ui/environment"
require "./ui/view"
require "./ui/form_state"
require "./ui/navigation_coordinator"
require "./ui/app_shortcuts"
require "./ui/live_activities"
require "./ui/widgets"
require "./ui/windows"
require "./ui/quick_actions"
# Phase 10B.0 — Tier 2 intent resolver + registry. Must load BEFORE
# `views/*` because `UI::SwipeActionRow` (and future Tier 2 widgets)
# call `declares_capabilities` at class-load, which writes into
# `UI::WidgetRoute::Registry`.
require "./ui/widget_route/registry"
require "./ui/system_action/result"
require "./ui/system_action/platform_binding"
require "./ui/system_action/registry"
# Phase 10B.3.0 — UI::Environment is the process-level platform +
# capability surface read by Class C dispatch. Load before
# `./ui/widget_route` so `SystemAction.perform` can reference it.
require "./ui/environment"
require "./ui/widget_route"
require "./ui/system_action"
require "./ui/views/*"
# `widget_route/bootstrap` installs the framework-default capability
# declarations + platform defaults. It loads AFTER `views/*` so that
# `UI::SwipeActionRow` (and future widget classes) are defined before
# the bootstrap references them.
require "./ui/widget_route/bootstrap"
# Phase 10B.3.0 — install Class C bindings (currently the
# :hello_world_alert proof; 10B.3.x grows this).
require "./ui/system_action/bootstrap"
require "./ui/menu_bar"
require "./ui/status_bar"
require "./ui/platform_visitor"
require "./ui/theme"
require "./ui/notifications"
require "./ui/speech"
require "./ui/preferences"
require "./ui/renderers/web_renderer"

# Reactive state and component bridge
require "./ui/state"
require "./ui/view_adapter"

# Native platform infrastructure (memory management, FFI handles, callbacks)
require "./ui/native/release_strategy"
require "./ui/native/lib_objc_runtime"
require "./ui/native/handle_tracker"
require "./ui/native/native_handle"
require "./ui/native/objc_handle"
require "./ui/native/jni_handle"
require "./ui/native/callback_registry"
require "./ui/native/native_view"

# Collection bridge wrappers (platform-gated: ObjC on Darwin, JNI on Android)
require "./ui/native/objc_collections"
require "./ui/native/jni_collections"

# SwiftKit bridge (Phase 3: AppKit/UIKit renderers reach SwiftUI defaults
# through this typed wrapper). Platform-gated to macos/ios; the populator
# module is unconditional so specs can exercise the default-detection
# rule without -Dmacos / -Dios.
require "./ui/native/swiftkit_bridge"
require "./ui/native/swiftkit_overrides"
require "./ui/font_registry"

# Phase 12.A — Interaction-contracts marker emitter. See
# docs/initiative-cross-platform-ui/architecture/interaction-contracts-harness.md.
# No-op when ENV["APIC_ENABLED"] is unset.
require "./ui/native/interaction_contracts"

# Pure renderer policy helpers (always compiled — unit-testable headless).
require "./ui/renderers/stack_bake"

# Platform-specific renderers (compile-time gated)
require "./ui/renderers/appkit_renderer"
require "./ui/renderers/uikit_renderer"
require "./ui/renderers/android_renderer"
require "./ui/renderers/watchkit_renderer"
