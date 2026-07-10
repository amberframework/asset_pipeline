require "./ui/fluid"
require "./ui/view"
require "./ui/form_state"
require "./ui/navigation_coordinator"
require "./ui/app_shortcuts"
require "./ui/live_activities"
require "./ui/widgets"
require "./ui/windows"
require "./ui/quick_actions"
require "./ui/views/*"
require "./ui/menu_bar"
require "./ui/status_bar"
require "./ui/platform_visitor"
require "./ui/theme"
require "./ui/notifications"
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

# Platform-specific renderers (compile-time gated)
require "./ui/renderers/appkit_renderer"
require "./ui/renderers/uikit_renderer"
require "./ui/renderers/android_renderer"
