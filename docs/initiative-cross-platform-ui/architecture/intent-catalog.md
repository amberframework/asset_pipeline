# Apple-Native Intent Catalog

**Source of truth for `asset_pipeline` intent vocabulary.**

This catalog names every user-interaction intent the framework recognizes, using **Apple SwiftUI/UIKit/AppKit vocabulary verbatim** as the canonical identifier. The owner directive (2026-05-25) is binding: where Apple has named a behavior, we adopt that name; we do not invent generic substitutes.

Each entry is classified into exactly one of four classes:

- **Class A** — Widget-routing intents. Framework picks materially different `UI::View` per platform. Gets the four-part contract (capabilities + defaults + override_registry + resolver). See `intent-routing-candidates.md`.
- **Class B** — Framework-contract intents. Cross-cutting invariants every widget honors (accessibility, reduced motion, dynamic type).
- **Class C** — Cross-platform-bridged intents. Single Crystal API surface, different native implementations per platform (share, clipboard, permissions, URL handling, file pickers). Distinct from HIG's "system experiences" surface (App Shortcuts, Controls, Live Activities, Widgets, Notifications, Status Bars) — those would belong to a separate Class E if we expand to cover them; Phase 9 does not.
- **Class D** — Native modifier intents. SwiftUI modifiers that configure existing widgets 1:1 (no routing, no contract — direct Crystal-to-modifier translation).

Lint requires every row to carry all 12 common-schema fields. Class D rows carry 14 fields (the common 12 plus `crystal_api_shape` and `platforms`). Em-dash `"—"` is the sentinel for no-equivalent-on-platform.

**Vocabulary rule:** `intent_identifier_crystal` MUST be the snake_case form of `primary_apple_name`. No exceptions in this catalog — Codex content review forced every identifier into compliance.

---

## Class A — Widget-routing intents

### `:swipe_actions`

- **intent_identifier_crystal:** `:swipe_actions`
- **primary_apple_name:** `swipeActions`
- **class:** A
- **tier:** 2
- **swiftui_api:** `swipeActions(edge:allowsFullSwipe:content:)`
- **uikit_api:** `UISwipeActionsConfiguration`
- **appkit_api:** `NSTableView` row actions via `NSTableViewRowActionStyle`
- **hig_page:** `gestures.md`, `accessibility.md`, `lists-and-tables.md`
- **android_equivalent:** `SwipeToDismissBox` (Material 3); `swipeable` modifier (Compose Foundation)
- **web_equivalent:** No native swipe affordance on desktop; mobile web uses CSS + JS gesture libraries OR inline buttons fallback
- **coverage_today:** partial on iOS/iPadOS/web (`src/ui/views/swipe_action_row.cr:64-65`; iOS swipe-reveal via `src/ui/renderers/uikit_renderer.cr:3823-3870`; web via `src/ui/renderers/web_renderer.cr:2887-2911`); macOS inline-button degradation (`src/ui/renderers/appkit_renderer.cr:3819-3826`); Android renderer is a STUB (`src/ui/renderers/android_renderer.cr:3148-3152` — defers proper integration to Phase 10B.1c) # caveats: trailing-edge only on iOS/macOS/Android; leading-edge honored only on web (`src/ui/renderers/web_renderer.cr:2909-2911`); destructive role honored on iOS + web; AppKit drops it. Capability block trimmed in 10-pre.1 — see intent-routing-candidates.md.
- **description:** Reveal trailing or leading actions on a list row via swipe gesture. HIG requires an alternate non-gesture path (button, custom action, keyboard shortcut) per `gestures.md:23,31` and `accessibility.md:134`. Materially different per platform: iOS swipe-reveal vs macOS inline trailing buttons (AppKit `def visit(view : UI::SwipeActionRow)` at `src/ui/renderers/appkit_renderer.cr:3806` renders content + trailing-action NSButtons inline).

---

## Class B — Framework-contract intents

### `:accessibility_label`

- **intent_identifier_crystal:** `:accessibility_label`
- **primary_apple_name:** `accessibilityLabel`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityLabel(_:)`
- **uikit_api:** `UIView.accessibilityLabel`
- **appkit_api:** `NSView.accessibilityLabel`
- **hig_page:** `accessibility.md`
- **android_equivalent:** `contentDescription` (Compose) / `android:contentDescription` (Views)
- **web_equivalent:** `aria-label` attribute
- **coverage_today:** shipped (`src/ui/view.cr:132` — every `UI::View` exposes `property accessibility_label : String? = nil`)
- **description:** Human-readable label exposed to assistive technologies (VoiceOver, TalkBack, screen readers). Required on every interactive widget per HIG accessibility guidance. Framework invariant: no interactive widget ships without a non-empty accessibility_label.

### `:accessibility_hint`

- **intent_identifier_crystal:** `:accessibility_hint`
- **primary_apple_name:** `accessibilityHint`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityHint(_:)`
- **uikit_api:** `UIView.accessibilityHint`
- **appkit_api:** `NSView.accessibilityHelp`
- **hig_page:** `accessibility.md`
- **android_equivalent:** Compose `Modifier.semantics { contentDescription = ... }` extended via `tooltip`
- **web_equivalent:** `aria-describedby` referencing a description element
- **coverage_today:** missing # was: partial (some views; not universally exposed). Phase 10-pre.1 audit: zero views expose any `accessibility_hint` property; scan of `src/ui/views/`, `src/ui/view.cr`, `src/ui/renderers/` returned no matches. Tracked by B-037 (10B.2a).
- **description:** Brief description of what activating an element does. Distinct from label (which is the element's identity). HIG cautions against duplicating the label.

### `:accessibility_value`

- **intent_identifier_crystal:** `:accessibility_value`
- **primary_apple_name:** `accessibilityValue`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityValue(_:)`
- **uikit_api:** `UIView.accessibilityValue`
- **appkit_api:** `NSView.accessibilityValue`
- **hig_page:** `accessibility.md`
- **android_equivalent:** Compose `Modifier.semantics { stateDescription = ... }`
- **web_equivalent:** `aria-valuenow` / `aria-valuetext`
- **coverage_today:** missing # was: partial. Phase 10-pre.1 audit: zero views expose any `accessibility_value` property; not present on `UI::View` base (`src/ui/view.cr`) and no per-view override. Tracked by B-037 (10B.2a).
- **description:** Current value of a stateful control (slider position, toggle state, picker selection) for assistive tech.

### `:accessibility_action`

- **intent_identifier_crystal:** `:accessibility_action`
- **primary_apple_name:** `accessibilityAction`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityAction(_:_:)`
- **uikit_api:** `UIAccessibilityCustomAction`
- **appkit_api:** `NSAccessibilityCustomAction`
- **hig_page:** `accessibility.md`, `gestures.md`
- **android_equivalent:** Compose `Modifier.semantics { customActions = listOf(...) }`
- **web_equivalent:** Visible buttons with `role="button"` (no direct ARIA custom-action equivalent)
- **coverage_today:** missing (not surfaced on `UI::View`)
- **description:** Custom actions exposed to assistive tech as an alternative to gestures. **Critical for swipe-action rows** per `accessibility.md:134` — gestures cannot be the sole path to a function.

### `:accessibility_rotor`

- **intent_identifier_crystal:** `:accessibility_rotor`
- **primary_apple_name:** `AccessibilityRotor`
- **class:** B
- **tier:** 2
- **swiftui_api:** `AccessibilityRotor`
- **uikit_api:** `UIAccessibilityCustomRotor`
- **appkit_api:** —
- **hig_page:** `accessibility.md`
- **android_equivalent:** —
- **web_equivalent:** ARIA landmarks + `role` attributes
- **coverage_today:** missing
- **description:** Custom VoiceOver navigation entry point grouping related elements. Used for skimming long content.

### `:accessibility_focused`

- **intent_identifier_crystal:** `:accessibility_focused`
- **primary_apple_name:** `accessibilityFocused`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityFocused(_:)`
- **uikit_api:** `UIView.accessibilityElementsHidden`, `UIAccessibility.post(notification:argument:)`
- **appkit_api:** `NSAccessibility.Notification.focusedUIElementChanged`
- **hig_page:** `accessibility.md`
- **android_equivalent:** Compose `Modifier.focusRequester`
- **web_equivalent:** Programmatic focus via `.focus()` JS API
- **coverage_today:** missing
- **description:** Programmatically move assistive-tech focus to a specific element (e.g., when an error appears, route focus to the error message).

### `:accessibility_reduce_motion`

- **intent_identifier_crystal:** `:accessibility_reduce_motion`
- **primary_apple_name:** `accessibilityReduceMotion`
- **class:** B
- **tier:** 2
- **swiftui_api:** `@Environment(\.accessibilityReduceMotion)`
- **uikit_api:** `UIAccessibility.isReduceMotionEnabled`
- **appkit_api:** `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion`
- **hig_page:** `accessibility.md`, `motion.md`
- **android_equivalent:** `Settings.Global.TRANSITION_ANIMATION_SCALE`
- **web_equivalent:** CSS `@media (prefers-reduced-motion: reduce)`
- **coverage_today:** missing (no framework-level helper)
- **description:** Respect user's Reduce Motion setting. Animations should fade rather than translate; large motion should be muted.

### `:dynamic_type_size`

- **intent_identifier_crystal:** `:dynamic_type_size`
- **primary_apple_name:** `dynamicTypeSize`
- **class:** B
- **tier:** 2
- **swiftui_api:** `@Environment(\.dynamicTypeSize)`, `.font(.body)` (scaled fonts)
- **uikit_api:** `UIFontMetrics`, `UIFont.preferredFont(forTextStyle:)`
- **appkit_api:** `NSFont` semantic styles
- **hig_page:** `typography.md`, `accessibility.md`
- **android_equivalent:** `sp` units; Material `Text` typography scaling
- **web_equivalent:** `em` / `rem` units + browser zoom
- **coverage_today:** partial (`src/ui/design_tokens.cr:537,643,1048` — `TypeScale` and `Tokens#type_scale` carry semantic font sizes; runtime scaling on `UI::View` not wired)
- **description:** Scale text and layout in response to user's text-size preference. HIG: support at least the standard accessibility sizes.

### `:accessibility_increase_contrast`

- **intent_identifier_crystal:** `:accessibility_increase_contrast`
- **primary_apple_name:** `accessibilityIncreaseContrast`
- **class:** B
- **tier:** 2
- **swiftui_api:** `@Environment(\.accessibilityIncreaseContrast)`
- **uikit_api:** `UIAccessibility.isDarkerSystemColorsEnabled`
- **appkit_api:** `NSWorkspace.shared.accessibilityDisplayShouldIncreaseContrast`
- **hig_page:** `accessibility.md`
- **android_equivalent:** Material `high contrast text` setting
- **web_equivalent:** CSS `@media (prefers-contrast: more)`
- **coverage_today:** missing
- **description:** Increase color contrast for users with vision needs. Per HIG `accessibility.md:49`: ensure interface remains usable with elevated contrast.

### `:accessibility_differentiate_without_color`

- **intent_identifier_crystal:** `:accessibility_differentiate_without_color`
- **primary_apple_name:** `accessibilityDifferentiateWithoutColor`
- **class:** B
- **tier:** 2
- **swiftui_api:** `@Environment(\.accessibilityDifferentiateWithoutColor)`
- **uikit_api:** `UIAccessibility.shouldDifferentiateWithoutColor`
- **appkit_api:** —
- **hig_page:** `accessibility.md`, `color.md`
- **android_equivalent:** —
- **web_equivalent:** WCAG 1.4.1 — provide redundant non-color cues
- **coverage_today:** missing
- **description:** Provide non-color cues (icons, text labels, patterns) for state. HIG: never use color as the sole means of conveying information.

### `:accessibility_voice_over_enabled`

- **intent_identifier_crystal:** `:accessibility_voice_over_enabled`
- **primary_apple_name:** `accessibilityVoiceOverEnabled`
- **class:** B
- **tier:** 2
- **swiftui_api:** `@Environment(\.accessibilityVoiceOverEnabled)` + label/hint/value/action modifiers
- **uikit_api:** `UIAccessibility.isVoiceOverRunning`
- **appkit_api:** `NSWorkspace.shared.isVoiceOverEnabled`
- **hig_page:** `voiceover.md`, `accessibility.md`
- **android_equivalent:** TalkBack
- **web_equivalent:** Screen reader compatibility via ARIA
- **coverage_today:** partial (`src/ui/view.cr:132` — `accessibility_label` carries through to VoiceOver; full traits/value/hint not exposed)
- **description:** Full VoiceOver compatibility. Required: every interactive element discoverable, labeled, value-reported, action-equivalent for gestures.

### `:accessibility_switch_control`

- **intent_identifier_crystal:** `:accessibility_switch_control`
- **primary_apple_name:** Switch Control
- **apple_canonical_name_exists:** false
- **exception_justification:** "Switch Control" is a HIG-named system feature (accessibility.md:154) with no single SwiftUI modifier. Apps honor it via focusable + accessibility actions; the intent is the contract, not an API. Identifier follows the `:accessibility_<feature_name>` convention used by other system-feature contracts in Class B.
- **class:** B
- **tier:** 2
- **swiftui_api:** Honored via focusable + accessibility actions
- **uikit_api:** `UIAccessibility.isSwitchControlRunning`
- **appkit_api:** —
- **hig_page:** `accessibility.md:154`
- **android_equivalent:** Switch Access
- **web_equivalent:** Keyboard-only navigation
- **coverage_today:** missing
- **description:** Switch Control assistive technology — single/dual-switch navigation through the UI. Requires every interactive element to be focusable + activatable without precise pointing.

### `:accessibility_voice_control`

- **intent_identifier_crystal:** `:accessibility_voice_control`
- **primary_apple_name:** Voice Control
- **apple_canonical_name_exists:** false
- **exception_justification:** "Voice Control" is a HIG-named system feature (accessibility.md:140) with no single SwiftUI modifier. Apps honor it by ensuring accessibility labels match visible text. Identifier follows the `:accessibility_<feature_name>` convention.
- **class:** B
- **tier:** 2
- **swiftui_api:** Honored via accessibility labels (Voice Control matches on visible labels)
- **uikit_api:** `UIAccessibility.isVoiceControlRunning`
- **appkit_api:** —
- **hig_page:** `accessibility.md:140`
- **android_equivalent:** Voice Access
- **web_equivalent:** —
- **coverage_today:** missing
- **description:** Voice Control allows users to operate the device entirely by voice. Requires accessibility labels match what's visible (so users can say "tap Sign In" and it works).

### `:accessibility_full_keyboard_access`

- **intent_identifier_crystal:** `:accessibility_full_keyboard_access`
- **primary_apple_name:** Full Keyboard Access
- **apple_canonical_name_exists:** false
- **exception_justification:** "Full Keyboard Access" is a HIG-named system feature (accessibility.md:152) with no single SwiftUI modifier. Apps honor it via `focusable`, `focusEffect`, `defaultFocus`, and `UIKeyCommand` collectively. Identifier follows the `:accessibility_<feature_name>` convention.
- **class:** B
- **tier:** 2
- **swiftui_api:** `.focusable(_:)`, `.focusEffect(_:)`, `.defaultFocus(_:_:)`
- **uikit_api:** `UIResponder.canBecomeFirstResponder`, `UIKeyCommand`
- **appkit_api:** `NSResponder` key view loop, `keyDown(with:)`
- **hig_page:** `accessibility.md:152`, `keyboards.md`
- **android_equivalent:** `View.isFocusable`, `KeyEvent` handling
- **web_equivalent:** `tabindex` attribute, native focus management
- **coverage_today:** partial (web `<button>` / `<input>` emitted by `src/ui/renderers/web_renderer.cr:159,294` are focusable by default; no Crystal-side helper on `UI::View` (`src/ui/view.cr:132` is the only AX-related property). Tracked by B-037 (10B.2a).)
- **description:** Every interactive element reachable + activatable via keyboard alone. HIG calls this out explicitly: "Let people use the keyboard alone to navigate."

### `:accessibility_element`

- **intent_identifier_crystal:** `:accessibility_element`
- **primary_apple_name:** `accessibilityElement`
- **class:** B
- **tier:** 2
- **swiftui_api:** `.accessibilityElement(children:)`, `.accessibilityAddTraits(_:)`
- **uikit_api:** `UIAccessibility` container traits
- **appkit_api:** `NSAccessibility.Role` for grouping
- **hig_page:** `accessibility.md`
- **android_equivalent:** Compose `Modifier.semantics(mergeDescendants: true)`
- **web_equivalent:** ARIA landmarks (`role="navigation"`, etc.)
- **coverage_today:** missing
- **description:** Group related views for assistive-tech navigation. Without this, VoiceOver users hear every leaf element individually.

### `:accessibility_captions`

- **intent_identifier_crystal:** `:accessibility_captions`
- **primary_apple_name:** Captions / Subtitles / Transcripts
- **apple_canonical_name_exists:** false
- **exception_justification:** "Captions / Subtitles / Transcripts" is a HIG-named media-accessibility category (accessibility.md:168) with no single SwiftUI modifier. Apps honor it via AVKit caption tracks + media selection options. Identifier follows the `:accessibility_<feature_name>` convention.
- **class:** B
- **tier:** 2
- **swiftui_api:** `AVPlayer` caption tracks via `AVMediaSelectionOption`
- **uikit_api:** Same as SwiftUI
- **appkit_api:** Same as SwiftUI
- **hig_page:** `accessibility.md:168`
- **android_equivalent:** `MediaPlayer.setCaptioningEnabled`
- **web_equivalent:** `<track kind="captions">` element
- **coverage_today:** missing
- **description:** Captions, subtitles, transcripts for video/audio media. HIG: any media with speech should include captions.

### `:accessibility_assistive_access`

- **intent_identifier_crystal:** `:accessibility_assistive_access`
- **primary_apple_name:** Assistive Access
- **apple_canonical_name_exists:** false
- **exception_justification:** "Assistive Access" is a HIG-named iOS 17+ system mode (assistive-access.md) with no SwiftUI modifier. Apps honor it by providing simplified flows. Identifier follows the `:accessibility_<feature_name>` convention.
- **class:** B
- **tier:** 2
- **swiftui_api:** App design honors Assistive Access via simplified flows
- **uikit_api:** —
- **appkit_api:** —
- **hig_page:** `accessibility.md`, `assistive-access.md`
- **android_equivalent:** —
- **web_equivalent:** —
- **coverage_today:** missing
- **description:** Apple's reduced-cognitive-load mode (iOS 17+). Apps that support Assistive Access provide simplified, focused, low-distraction flows.

### `:accessibility_dim_flashing_lights`

- **intent_identifier_crystal:** `:accessibility_dim_flashing_lights`
- **primary_apple_name:** Dim Flashing Lights
- **apple_canonical_name_exists:** false
- **exception_justification:** "Dim Flashing Lights" is a HIG-named accessibility feature with no single SwiftUI modifier (system handles it inside AVKit playback). Custom video implementations need explicit handling. Identifier follows the `:accessibility_<feature_name>` convention.
- **class:** B
- **tier:** 2
- **swiftui_api:** Honored automatically by AVKit playback
- **uikit_api:** Same
- **appkit_api:** Same
- **hig_page:** `accessibility.md`
- **android_equivalent:** —
- **web_equivalent:** CSS-controlled dimming of video; manual implementation
- **coverage_today:** missing
- **description:** Detect + dim sequences of flashing lights in videos for users with photo-sensitivity. iOS handles this in system video playback; custom video players need explicit handling.

---

## Class C — Cross-platform-bridged intents

Single Crystal API surface, different native implementation per platform. **NOT the same as HIG's "system experiences" surface** (App Shortcuts, Controls, Live Activities, Widgets, Notifications, Status Bars per `system-experiences.md:31`). Those would be a separate class if introduced in a future phase.

### `:share_link`

- **intent_identifier_crystal:** `:share_link`
- **primary_apple_name:** `ShareLink`
- **class:** C
- **tier:** 2
- **swiftui_api:** `ShareLink(item:subject:message:label:)`
- **uikit_api:** `UIActivityViewController`
- **appkit_api:** `NSSharingService`, `NSSharingServicePicker`
- **hig_page:** `system-experiences.md` (sharing) — not the same as the broader "system experiences" collection
- **android_equivalent:** `Intent.ACTION_SEND` + `Intent.createChooser`
- **web_equivalent:** `navigator.share()` (Web Share API)
- **coverage_today:** shipped (`UI::ActivityView` wires native sharing through the renderers: iOS `src/ui/renderers/uikit_renderer.cr:3408` → `src/ui/native/objc_bridge.m:2216-2245` presenting `UIActivityViewController`; macOS `src/ui/renderers/appkit_renderer.cr:3417` → `src/ui/native/objc_bridge.m:2148-2214` presenting `NSSharingServicePicker`; Android `src/ui/renderers/android_renderer.cr:2871` → `src/ui/native/android_bridge.c:1045` invoking `Intent.ACTION_SEND` via `android_context_start_share_chooser`; web visitor renders inline share affordances at `src/ui/renderers/web_renderer.cr:2184-2265` — an inline HTML approximation of the share-sheet, NOT `navigator.share()`) # 2026-05-25 correction: original audit false-negative (`phase-10-pre-catalog-freshness-2026-05-25.md` correction block); re-audit confirmed in `phase-10-pre-1-class-c-reaudit-2026-05-25.md`. B-026 closed by 10-pre.1.
- **description:** Open the system share UI to send content to other apps/services. SwiftUI canonical name is `ShareLink`; Crystal identifier is the snake_case form.

### `:copyable`

- **intent_identifier_crystal:** `:copyable`
- **primary_apple_name:** `copyable`
- **class:** C
- **tier:** 2
- **swiftui_api:** `.copyable(_:)`
- **uikit_api:** `UIPasteboard.general.string = ...`
- **appkit_api:** `NSPasteboard.general.setString(_:forType:)`
- **hig_page:** `system-experiences.md`
- **android_equivalent:** `ClipboardManager.setPrimaryClip(...)`
- **web_equivalent:** `navigator.clipboard.writeText(...)`
- **coverage_today:** missing
- **description:** Write a string (or richer payload) to the system clipboard.

### `:paste_button`

- **intent_identifier_crystal:** `:paste_button`
- **primary_apple_name:** `PasteButton`
- **class:** C
- **tier:** 2
- **swiftui_api:** `PasteButton(payloadType:onPaste:)`, `.pasteboard(...)`
- **uikit_api:** `UIPasteboard.general.string`
- **appkit_api:** `NSPasteboard.general.string(forType:)`
- **hig_page:** `system-experiences.md`
- **android_equivalent:** `ClipboardManager.getPrimaryClip()`
- **web_equivalent:** `navigator.clipboard.readText()` (requires permission)
- **coverage_today:** missing
- **description:** Read a string (or richer payload) from the system clipboard.

### `:authorization_request`

- **intent_identifier_crystal:** `:authorization_request`
- **primary_apple_name:** Authorization request (resource-specific Apple APIs)
- **class:** C
- **tier:** 2
- **swiftui_api:** Resource-specific (e.g. `requestAuthorization` on `AVCaptureDevice`, `CLLocationManager`, `UNUserNotificationCenter`)
- **uikit_api:** Same as SwiftUI (resource-specific)
- **appkit_api:** Same as iOS for shared resources
- **hig_page:** `privacy.md`, `requesting-permission.md`
- **android_equivalent:** `ActivityResultContracts.RequestPermission`
- **web_equivalent:** `navigator.permissions.query` + resource-specific prompts
- **coverage_today:** partial (notifications-auth shipped at `src/ui/notifications.cr:456` → `src/ui/native/objc_bridge.m:2297`; camera / microphone / photos / location / contacts / calendar not yet wired) # 2026-05-25 re-audit: notifications-auth is the only realized resource; HIG-mandated rationale presentation is the app's responsibility today, not framework-enforced. Tracked under B-029.
- **description:** Request user permission for camera, microphone, photo library, location, contacts, calendar, notifications. HIG requires explicit user-facing rationale.

### `:open_url`

- **intent_identifier_crystal:** `:open_url`
- **primary_apple_name:** `openURL`
- **class:** C
- **tier:** 2
- **swiftui_api:** `@Environment(\.openURL)`, `Link(destination:)`
- **uikit_api:** `UIApplication.shared.open(_:options:completionHandler:)`
- **appkit_api:** `NSWorkspace.shared.open(_:)`
- **hig_page:** `system-experiences.md`
- **android_equivalent:** `Intent.ACTION_VIEW` with URI
- **web_equivalent:** `window.open(url)` or `location.href = url`
- **coverage_today:** missing
- **description:** Open a URL in the system default handler (browser for web, mail client for mailto:, etc.).

### `:on_open_url`

- **intent_identifier_crystal:** `:on_open_url`
- **primary_apple_name:** `onOpenURL`
- **class:** C
- **tier:** 2
- **swiftui_api:** `.onOpenURL(perform:)`
- **uikit_api:** `application(_:continue:restorationHandler:)`, `scene(_:openURLContexts:)`
- **appkit_api:** Same as iOS via `NSApplicationDelegate`
- **hig_page:** `system-experiences.md`
- **android_equivalent:** App Links / `Intent` filters
- **web_equivalent:** URL routing handled by the framework's router
- **coverage_today:** missing
- **description:** Handle incoming URL/deep-link to navigate to a specific app state.

### `:ui_print_interaction_controller`

- **intent_identifier_crystal:** `:ui_print_interaction_controller`
- **primary_apple_name:** `UIPrintInteractionController`
- **class:** C
- **tier:** 2
- **swiftui_api:** —
- **uikit_api:** `UIPrintInteractionController`
- **appkit_api:** `NSPrintOperation`
- **hig_page:** `system-experiences.md`
- **android_equivalent:** `PrintManager`, `PrintHelper`
- **web_equivalent:** `window.print()`
- **coverage_today:** missing
- **description:** Initiate the system print flow.

### `:file_importer`

- **intent_identifier_crystal:** `:file_importer`
- **primary_apple_name:** `fileImporter`
- **class:** C
- **tier:** 2
- **swiftui_api:** `.fileImporter(isPresented:allowedContentTypes:onCompletion:)`
- **uikit_api:** `UIDocumentPickerViewController`
- **appkit_api:** `NSOpenPanel`
- **hig_page:** `file-management.md`
- **android_equivalent:** `Intent.ACTION_OPEN_DOCUMENT`
- **web_equivalent:** `<input type="file">` element
- **coverage_today:** missing
- **description:** Open a system file picker, return the user's selected file URL(s).

### `:file_exporter`

- **intent_identifier_crystal:** `:file_exporter`
- **primary_apple_name:** `fileExporter`
- **class:** C
- **tier:** 2
- **swiftui_api:** `.fileExporter(isPresented:document:contentType:onCompletion:)`
- **uikit_api:** `UIDocumentPickerViewController(forExporting:)`
- **appkit_api:** `NSSavePanel`
- **hig_page:** `file-management.md`
- **android_equivalent:** `Intent.ACTION_CREATE_DOCUMENT`
- **web_equivalent:** `<a download="..." href="...">` or `Blob` download
- **coverage_today:** missing
- **description:** Open a system save panel, write the user-confirmed file.

---

## Class D — Native modifier intents

Class D entries carry the 12 common-schema fields PLUS `crystal_api_shape` and `platforms`.

### `:list`

- **intent_identifier_crystal:** `:list`
- **primary_apple_name:** `List`
- **class:** D
- **tier:** 2
- **swiftui_api:** `List { ForEach(items) { ... } }`
- **uikit_api:** `UITableView`, `UICollectionView`
- **appkit_api:** `NSTableView`, `NSCollectionView`
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** `LazyColumn` (Compose), `RecyclerView` (Views)
- **web_equivalent:** `<ul>` / `<ol>` / `<table>` HTML
- **coverage_today:** partial (`src/ui/views/list_view.cr:5,13,37` — actual class is `UI::ListView` with `sections : Array(Section)`; renderers visit at `src/ui/renderers/uikit_renderer.cr:1064`, `src/ui/renderers/appkit_renderer.cr:1067`, `src/ui/renderers/web_renderer.cr:811`, `src/ui/renderers/android_renderer.cr:1243`) Caveat: composition is "real native List visitor," not VStack fallback as previously stated.
- **crystal_api_shape:** `list = UI::ListView.flat(items: rows)` OR `UI::ListView.new(sections: [UI::ListView::Section.new(items: rows)])`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Vertically-scrolling collection of rows with native row management (separators, selection, swipe actions, reorder support).

### `:list_row_separator`

- **intent_identifier_crystal:** `:list_row_separator`
- **primary_apple_name:** `listRowSeparator`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.listRowSeparator(_:edges:)`
- **uikit_api:** `UITableView.separatorStyle`, `UITableView.separatorInset`
- **appkit_api:** `NSTableView` cell separator handling
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** Compose `HorizontalDivider`
- **web_equivalent:** CSS `border-bottom` on list items
- **coverage_today:** partial (`src/ui/views/list_view.cr:32` — `ListView#shows_separators : Bool` is list-level, not per-row; honored by `src/ui/renderers/uikit_renderer.cr:1235`, `src/ui/renderers/appkit_renderer.cr:1216-1229`) Per-row override missing — see close handoff "new gaps" for backlog candidate.
- **crystal_api_shape:** `list.shows_separators = false`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Show or hide the separator line between list rows.

### `:list_section_spacing`

- **intent_identifier_crystal:** `:list_section_spacing`
- **primary_apple_name:** `listSectionSpacing`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.listSectionSpacing(_:)`
- **uikit_api:** `UITableView.sectionHeaderHeight` / `sectionFooterHeight`
- **appkit_api:** —
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** Custom spacing via padding modifier
- **web_equivalent:** CSS margin between sections
- **coverage_today:** missing
- **crystal_api_shape:** `list.list_section_spacing = 24.0`
- **platforms:** ios, ipados, android, web_wide, web_narrow; macOS uses default
- **description:** Vertical space between list sections.

### `:list_section_index_visibility`

- **intent_identifier_crystal:** `:list_section_index_visibility`
- **primary_apple_name:** `listSectionIndexVisibility`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.listSectionIndexVisibility(_:)` (iOS 18+)
- **uikit_api:** `UITableViewDataSource.sectionIndexTitles`
- **appkit_api:** —
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** `FastScroller`
- **web_equivalent:** Custom anchor links + scroll handlers
- **coverage_today:** missing
- **crystal_api_shape:** `list.list_section_index_visibility = :automatic | :visible | :hidden`
- **platforms:** ios, ipados
- **description:** Toggle the section-index sidebar (the A-Z scrubber on iOS Contacts-style lists).

### `:refreshable`

- **intent_identifier_crystal:** `:refreshable`
- **primary_apple_name:** `refreshable`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.refreshable { await reload() }`
- **uikit_api:** `UIRefreshControl`
- **appkit_api:** — (no native pull-to-refresh; emit as toolbar refresh item)
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** `PullRefreshContainer` (Material)
- **web_equivalent:** No native pull-to-refresh; mobile-web custom JS or toolbar button
- **coverage_today:** missing (no `UI::ListView.refreshable=` property)
- **crystal_api_shape:** `list.refreshable = -> { state.reload_todos }`
- **platforms:** ios, ipados, android; macOS uses toolbar refresh fallback; web uses button fallback
- **description:** Trigger a refresh of list content via pull-down gesture (or platform-equivalent affordance).

### `:searchable`

- **intent_identifier_crystal:** `:searchable`
- **primary_apple_name:** `searchable`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.searchable(text:placement:prompt:)`
- **uikit_api:** `UISearchController`
- **appkit_api:** `NSSearchToolbarItem`, `NSSearchField`
- **hig_page:** `search-fields.md`
- **android_equivalent:** Material `SearchBar`
- **web_equivalent:** `<input type="search">`
- **coverage_today:** missing (no `UI::ListView.searchable=` integration)
- **crystal_api_shape:** `list.searchable = "Search todos..."`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Surface a search field for filtering list content.

### `:search_suggestions`

- **intent_identifier_crystal:** `:search_suggestions`
- **primary_apple_name:** `searchSuggestions`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.searchSuggestions { ... }`
- **uikit_api:** `UISearchController.searchResultsUpdater`
- **appkit_api:** `NSSearchField` autocomplete via `NSTextFieldDelegate`
- **hig_page:** `search-fields.md`
- **android_equivalent:** Material `SearchBar` suggestions slot
- **web_equivalent:** `<datalist>` element
- **coverage_today:** missing
- **crystal_api_shape:** `list.search_suggestions = ->(query : String) { ["Egg", "Eggplant"] }`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Show suggested completions/matches inside the search UI as the user types.

### `:search_scopes`

- **intent_identifier_crystal:** `:search_scopes`
- **primary_apple_name:** `searchScopes`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.searchScopes(_:scopes:)`
- **uikit_api:** `UISearchController.searchBar.scopeButtonTitles`
- **appkit_api:** —
- **hig_page:** `search-fields.md`
- **android_equivalent:** Material chip filter group adjacent to SearchBar
- **web_equivalent:** Custom radio/segment UI
- **coverage_today:** missing
- **crystal_api_shape:** `list.search_scopes = ["All", "Open", "Done"]`
- **platforms:** ios, ipados, android, web_wide, web_narrow; macOS uses adjacent segmented control
- **description:** Constrain searches to a chosen scope via segmented control above/within the search field.

### `:on_move`

- **intent_identifier_crystal:** `:on_move`
- **primary_apple_name:** `onMove`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.onMove(perform:)`
- **uikit_api:** `UITableViewDataSource.tableView(_:moveRowAt:to:)`, `UITableView.isEditing`
- **appkit_api:** `NSTableView` drag-source / drop-destination protocols
- **hig_page:** `lists-and-tables.md`, `drag-and-drop.md`
- **android_equivalent:** Compose `reorderable` (third-party lib) or `ItemTouchHelper` (Views)
- **web_equivalent:** HTML5 `draggable` attribute + drag events; OR up/down arrow buttons
- **coverage_today:** missing
- **crystal_api_shape:** `list.on_move = ->(from : Range(Int32, Int32), to : Int32) { state.reorder_todos(from, to) }`
- **platforms:** ios, ipados, macos, android; web_wide uses drag-handle buttons; web_narrow uses up/down buttons
- **description:** Reorder list items. **Why not Class A:** the renderer-side translation differs (drag-handle on mobile, arrow buttons on web) but the conceptual widget is still `UI::List` with an `on_move` handler. Authors don't pick a different widget per platform; they pass the same handler and the renderer handles the affordance. If a future phase determines authors need to actively choose between drag-handle and arrow-button widgets, the intent gets promoted to Class A.

### `:on_delete`

- **intent_identifier_crystal:** `:on_delete`
- **primary_apple_name:** `onDelete`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.onDelete(perform:)`
- **uikit_api:** `UITableViewDataSource.tableView(_:commit:forRowAt:)` with `editingStyle: .delete`
- **appkit_api:** Custom delete button or menu action
- **hig_page:** `lists-and-tables.md`
- **android_equivalent:** `SwipeToDismiss` callback
- **web_equivalent:** Delete button per row
- **coverage_today:** partial (via `UI::SwipeActionRow` trailing actions; `src/ui/views/swipe_action_row.cr:65` — `trailing_actions : Array(SwipeAction)`; standalone `on_delete` on `UI::ListView` not exposed)
- **crystal_api_shape:** `list.on_delete = ->(indices : IndexSet) { state.delete_todos(indices) }`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Handler for row deletion. Independent of `:swipe_actions` — `:on_delete` is the deletion callback; the framework decides how to expose deletion (swipe-action on mobile, Delete key on macOS, button on web). Apps that want explicit affordance control use `:swipe_actions` with custom destructive actions instead.

### `:sheet`

- **intent_identifier_crystal:** `:sheet`
- **primary_apple_name:** `sheet`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.sheet(isPresented:onDismiss:content:)`
- **uikit_api:** `UISheetPresentationController`
- **appkit_api:** `NSViewController.presentAsSheet(_:)`
- **hig_page:** `sheets.md`
- **android_equivalent:** Material `ModalBottomSheet`
- **web_equivalent:** Modal dialog overlay (CSS + JS)
- **coverage_today:** shipped (`src/ui/views/sheet.cr:7` — `class Sheet < View`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:1659`, `src/ui/renderers/appkit_renderer.cr:1638`, `src/ui/renderers/web_renderer.cr:1354`, `src/ui/renderers/android_renderer.cr:1840`)
- **crystal_api_shape:** `sheet = UI::Sheet.new(content); presenter = UI::SheetPresenter.new(sheet); presenter.present`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Present content as a modal sheet anchored to bottom (iOS) or floating (macOS).

### `:full_screen_cover`

- **intent_identifier_crystal:** `:full_screen_cover`
- **primary_apple_name:** `fullScreenCover`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.fullScreenCover(isPresented:onDismiss:content:)`
- **uikit_api:** `UIViewController.modalPresentationStyle = .fullScreen`
- **appkit_api:** Full-window modal via `NSWindow`
- **hig_page:** `modality.md`
- **android_equivalent:** Full-screen `Dialog` or full-screen activity
- **web_equivalent:** Full-viewport modal overlay
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::FullScreenCover class exists in src/ui/views/. Tracked under B-010 full-screen cover.`
- **platforms:** ios, ipados, android; macos+web use sheets at appropriate size
- **description:** Modal that takes the entire screen (no peek of the parent).

### `:popover`

- **intent_identifier_crystal:** `:popover`
- **primary_apple_name:** `popover`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.popover(isPresented:attachmentAnchor:arrowEdge:content:)`
- **uikit_api:** `UIPopoverPresentationController`
- **appkit_api:** `NSPopover`
- **hig_page:** `popovers.md`
- **android_equivalent:** Material `DropdownMenu` (functional analog)
- **web_equivalent:** CSS-positioned floating element OR HTML `<dialog popover>`
- **coverage_today:** shipped (`src/ui/views/popover.cr:4` — `class Popover < View`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:1723`, `src/ui/renderers/appkit_renderer.cr:1697`, `src/ui/renderers/web_renderer.cr:1390`, `src/ui/renderers/android_renderer.cr:1907`)
- **crystal_api_shape:** `popover = UI::Popover.new(content, :bottom); presenter = UI::PopoverPresenter.new(popover, anchor_view); presenter.present`
- **platforms:** ipados, macos, web_wide; iOS+web_narrow fall back to sheet
- **description:** Transient floating panel anchored to a source view. iPad/macOS only — on iPhone falls back to sheet.

### `:inspector`

- **intent_identifier_crystal:** `:inspector`
- **primary_apple_name:** `inspector`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.inspector(isPresented:content:)`
- **uikit_api:** `UISplitViewController` with inspector column (iPadOS 17+)
- **appkit_api:** `NSSplitViewController` inspector pane
- **hig_page:** `inspectors.md`
- **android_equivalent:** —
- **web_equivalent:** Side panel via CSS grid/flex
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::Inspector class exists in src/ui/views/, and no screen.inspector= setter on UI::Screen. Tracked under B-009 inspector view.`
- **platforms:** ipados, macos, web_wide; ios+android+web_narrow use sheet fallback
- **description:** Side-panel detail view that complements primary content. Detail-on-side, never modal.

### `:alert`

- **intent_identifier_crystal:** `:alert`
- **primary_apple_name:** `alert`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.alert(_:isPresented:actions:message:)`
- **uikit_api:** `UIAlertController(preferredStyle: .alert)`
- **appkit_api:** `NSAlert`
- **hig_page:** `alerts.md`
- **android_equivalent:** Material `AlertDialog`
- **web_equivalent:** HTML `<dialog>` or framework modal
- **coverage_today:** shipped (`src/ui/views/alert.cr:5` — `class Alert < View`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:951`, `src/ui/renderers/appkit_renderer.cr:970`, `src/ui/renderers/web_renderer.cr:713`, `src/ui/renderers/android_renderer.cr:1046`)
- **crystal_api_shape:** `alert = UI::Alert.new("Delete?", "This cannot be undone."); alert.add_button("Delete", :destructive) { state.delete }; alert.add_button("Cancel"); alert.is_presented = true`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Critical attention modal requiring user decision. Sparing use per HIG.

### `:confirmation_dialog`

- **intent_identifier_crystal:** `:confirmation_dialog`
- **primary_apple_name:** `confirmationDialog`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.confirmationDialog(_:isPresented:titleVisibility:actions:message:)`
- **uikit_api:** `UIAlertController(preferredStyle: .actionSheet)`
- **appkit_api:** `NSAlert` with `AlertStyle.critical`
- **hig_page:** `action-sheets.md`
- **android_equivalent:** Material `AlertDialog` with destructive style OR `ModalBottomSheet`
- **web_equivalent:** Modal with action buttons
- **coverage_today:** shipped (`src/ui/views/confirmation_dialog.cr:4` — `class ConfirmationDialog < View`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:1758`, `src/ui/renderers/appkit_renderer.cr:1733`, `src/ui/renderers/web_renderer.cr:1418`, `src/ui/renderers/android_renderer.cr:1984`)
- **crystal_api_shape:** `dialog = UI::ConfirmationDialog.new("Delete?", "This cannot be undone."); dialog.confirm_style = :destructive; dialog.on_confirm = -> { state.delete }; dialog.is_presented = true`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Sheet-style confirmation for destructive or significant actions. Distinct from alert: confirmation dialogs let the user choose among multiple paths; alerts inform.

### `:presentation_detents`

- **intent_identifier_crystal:** `:presentation_detents`
- **primary_apple_name:** `presentationDetents`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.presentationDetents(_:)`
- **uikit_api:** `UISheetPresentationController.detents`
- **appkit_api:** —
- **hig_page:** `sheets.md:73-83`
- **android_equivalent:** Material `ModalBottomSheet` `sheetState.expand()` / `partialExpand()`
- **web_equivalent:** Custom CSS heights
- **coverage_today:** partial (`src/ui/views/sheet.cr:31` — `Sheet#detents : Array(Symbol) = [:medium, :large]`; iOS/macOS forwarded via SwiftKit `setDetents` at `src/ui/native/swiftkit_overrides.cr:464-466`; web stub at `src/ui/renderers/web_renderer.cr` and android stub at `src/ui/renderers/android_renderer.cr:1865` echo the values but do not provide a real detented surface) # was: missing — Phase 10-pre.2 audit found shipped Crystal property + SwiftKit wiring; iOS native binding lives in SwiftKit facade.
- **crystal_api_shape:** `sheet.detents = [:medium, :large]`
- **platforms:** ios, ipados, android
- **description:** Resizable sheet stops. `medium` ≈ half-height; `large` ≈ full-height; custom values allowed. macOS and web do not have native detent equivalents — sheets on those platforms render at their content-determined size, which is NOT an Apple detent.

### `:presentation_drag_indicator`

- **intent_identifier_crystal:** `:presentation_drag_indicator`
- **primary_apple_name:** `presentationDragIndicator`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.presentationDragIndicator(_:)`
- **uikit_api:** `UISheetPresentationController.prefersGrabberVisible`
- **appkit_api:** —
- **hig_page:** `sheets.md:83`
- **android_equivalent:** Material `ModalBottomSheet` drag handle
- **web_equivalent:** Custom CSS handle
- **coverage_today:** partial (`src/ui/views/sheet.cr:30` — `Sheet#shows_drag_indicator : Bool = true`; web honored at `src/ui/renderers/web_renderer.cr:1367`; android honored at `src/ui/renderers/android_renderer.cr:1857`; SwiftKit overrides STORES the bool via `setShowsDragIndicator` at `src/ui/native/swiftkit_overrides.cr:468-469` but the value is NOT yet applied to SwiftUI — no `.presentationDragIndicator(_:)` call in `swift/AssetPipelineSwiftKit/Sources/AssetPipelineSwiftKit/Facades/SheetFacade.swift`. iOS/macOS drag indicator is therefore stored-not-applied. Three-valued `:automatic` state is NOT modeled — see close handoff.) # was: missing — Phase 10-pre.2 iter 1 incorrectly claimed full SwiftKit wiring; iter 2 audit (Codex MED-2) corrected to stored-not-applied for iOS/macOS.
- **crystal_api_shape:** `sheet.shows_drag_indicator = true`
- **platforms:** ios, ipados, android; macos+web omit
- **description:** Visual + VoiceOver-accessible grabber indicating the sheet is resizable.

### `:interactive_dismiss_disabled`

- **intent_identifier_crystal:** `:interactive_dismiss_disabled`
- **primary_apple_name:** `interactiveDismissDisabled`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.interactiveDismissDisabled(_:)`
- **uikit_api:** `UIViewController.isModalInPresentation`
- **appkit_api:** —
- **hig_page:** `sheets.md:85`
- **android_equivalent:** `ModalBottomSheet` `shouldDismissOnBackPress = false`
- **web_equivalent:** Disable backdrop-click + ESC handling
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no interactive_dismiss_disabled property on UI::Sheet (src/ui/views/sheet.cr:1-50). Tracked in phase-10-pre-2-close.md "new gaps surfaced".`
- **platforms:** ios, ipados, android, web_wide, web_narrow; macos uses modal-only mode
- **description:** Prevent the user from dismissing a sheet via swipe-down or background tap (typically because unsaved changes need confirmation).

### `:toolbar`

- **intent_identifier_crystal:** `:toolbar`
- **primary_apple_name:** `toolbar`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.toolbar { ToolbarItem(...) }`
- **uikit_api:** `UINavigationItem.rightBarButtonItems` / `leftBarButtonItems`, `UIToolbar`
- **appkit_api:** `NSToolbar`, `NSToolbarItem`
- **hig_page:** `toolbars.md`
- **android_equivalent:** Material `TopAppBar`
- **web_equivalent:** Header HTML + buttons
- **coverage_today:** shipped (`src/ui/views/toolbar.cr:4` — `class Toolbar < View`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:1628`, `src/ui/renderers/appkit_renderer.cr:1603`, `src/ui/renderers/web_renderer.cr:1324`, `src/ui/renderers/android_renderer.cr:1818`)
- **crystal_api_shape:** `toolbar = UI::Toolbar.new("Title"); toolbar.add_item(id: "save", label: "Save", icon: "checkmark") { ... }`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Persistent action surface bound to a screen.

### `:toolbar_item`

- **intent_identifier_crystal:** `:toolbar_item`
- **primary_apple_name:** `ToolbarItem`
- **class:** D
- **tier:** 2
- **swiftui_api:** `ToolbarItem(placement:content:)`
- **uikit_api:** `UIBarButtonItem`
- **appkit_api:** `NSToolbarItem`
- **hig_page:** `toolbars.md`
- **android_equivalent:** Material `TopAppBar` action slot
- **web_equivalent:** Button in header
- **coverage_today:** shipped (`src/ui/views/toolbar.cr:5` — `record ToolbarItem` nested in `Toolbar`; populated via `Toolbar#add_item` at `src/ui/views/toolbar.cr:23,27`; rendered inside `visit(Toolbar)` paths cited above)
- **crystal_api_shape:** `toolbar.add_item(id: "save", label: "Save", icon: "checkmark") { ... }`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Individual action within a toolbar.

### `:toolbar_item_group`

- **intent_identifier_crystal:** `:toolbar_item_group`
- **primary_apple_name:** `ToolbarItemGroup`
- **class:** D
- **tier:** 2
- **swiftui_api:** `ToolbarItemGroup(placement:content:)`
- **uikit_api:** `UIBarButtonItemGroup`
- **appkit_api:** `NSToolbarItemGroup`
- **hig_page:** `toolbars.md`
- **android_equivalent:** Multiple action slots
- **web_equivalent:** Button group HTML
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — UI::Toolbar (src/ui/views/toolbar.cr) only ships flat add_item(id:, label:, icon:) and has no group concept. Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 3.`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Grouped toolbar items that visually belong together.

### `:toolbar_item_placement`

- **intent_identifier_crystal:** `:toolbar_item_placement`
- **primary_apple_name:** `ToolbarItemPlacement`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.principal`, `.navigationBarLeading`, `.navigationBarTrailing`, `.bottomBar`, `.confirmationAction`, `.cancellationAction`, `.destructiveAction`, `.automatic`, `.status`
- **uikit_api:** Manual choice of `leftBarButtonItems` vs `rightBarButtonItems` vs toolbar
- **appkit_api:** `NSToolbarItem` identifier-driven placement
- **hig_page:** `toolbars.md`
- **android_equivalent:** —
- **web_equivalent:** Layout via CSS
- **coverage_today:** missing # was: partial (Phase 10-pre.1 audit: `record ToolbarItem` in `src/ui/views/toolbar.cr:5-9` has no `placement` field; renderers do not honor semantic placement — only a single linear `items` array is emitted in `visit(UI::Toolbar)`).
- **crystal_api_shape:** `item.placement = :navigation_bar_leading`
- **platforms:** ios, ipados, macos
- **description:** Semantic placement of a toolbar item. Renderers honor placement to map to the platform's idiomatic location.

### `:toolbar_background`

- **intent_identifier_crystal:** `:toolbar_background`
- **primary_apple_name:** `toolbarBackground`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.toolbarBackground(_:for:)`
- **uikit_api:** `UINavigationBarAppearance.backgroundColor`
- **appkit_api:** `NSToolbar` appearance via window
- **hig_page:** `toolbars.md`
- **android_equivalent:** Material `TopAppBar` `colors` parameter
- **web_equivalent:** CSS `background` on header
- **coverage_today:** missing
- **crystal_api_shape:** `toolbar.toolbar_background = UI::Color.brand_primary`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Tint/material override for the toolbar background.

### `:toolbar_spacer`

- **intent_identifier_crystal:** `:toolbar_spacer`
- **primary_apple_name:** `ToolbarSpacer`
- **class:** D
- **tier:** 2
- **swiftui_api:** `ToolbarSpacer` (iOS 17+)
- **uikit_api:** `UIBarButtonItem.fixedSpace` / `flexibleSpace`
- **appkit_api:** `NSToolbarItem.Identifier.flexibleSpace`
- **hig_page:** `toolbars.md`
- **android_equivalent:** `Spacer` between actions
- **web_equivalent:** Flex spacer
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — UI::Toolbar (src/ui/views/toolbar.cr) only ships flat add_item(id:, label:, icon:) and has no spacer concept. Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 3.`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Spacer between toolbar items, fixed or flexible.

### `:form_style`

- **intent_identifier_crystal:** `:form_style`
- **primary_apple_name:** `formStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.formStyle(_:)`
- **uikit_api:** Manual styling via `UITableView` `style:` / spacing
- **appkit_api:** Form-specific layout via `NSGridView`
- **hig_page:** `forms.md`
- **android_equivalent:** Material form components composed manually
- **web_equivalent:** CSS styling of `<form>`
- **coverage_today:** missing
- **crystal_api_shape:** `form.form_style = :grouped | :columns | :automatic`
- **platforms:** ios, ipados, macos, web_wide
- **description:** Visual style of a form: grouped, columns, automatic.

### `:grouped_form_style`

- **intent_identifier_crystal:** `:grouped_form_style`
- **primary_apple_name:** `GroupedFormStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.formStyle(.grouped)`
- **uikit_api:** `UITableView(style: .insetGrouped)`
- **appkit_api:** —
- **hig_page:** `forms.md`
- **android_equivalent:** Material list with section headers
- **web_equivalent:** Fieldset/legend HTML
- **coverage_today:** missing
- **crystal_api_shape:** `form.form_style = :grouped`
- **platforms:** ios, ipados
- **description:** Sections rendered as rounded grouped cards (iOS default for Settings-style screens).

### `:columns_form_style`

- **intent_identifier_crystal:** `:columns_form_style`
- **primary_apple_name:** `ColumnsFormStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.formStyle(.columns)`
- **uikit_api:** —
- **appkit_api:** `NSGridView` two-column layout
- **hig_page:** `forms.md`
- **android_equivalent:** —
- **web_equivalent:** CSS grid two-column
- **coverage_today:** missing
- **crystal_api_shape:** `form.form_style = :columns`
- **platforms:** macos, web_wide
- **description:** Labels in a left column, controls in a right column. Desktop-form aesthetic.

### `:navigation_stack`

- **intent_identifier_crystal:** `:navigation_stack`
- **primary_apple_name:** `NavigationStack`
- **class:** D
- **tier:** 2
- **swiftui_api:** `NavigationStack(path:root:)`
- **uikit_api:** `UINavigationController`
- **appkit_api:** —
- **hig_page:** `navigation-bars.md`
- **android_equivalent:** Compose `Navigation` host
- **web_equivalent:** Browser URL stack + framework router
- **coverage_today:** shipped (`src/ui/views/navigation_stack.cr:10` — `class NavigationStack < View`; coordinator at `src/ui/navigation_coordinator.cr:30,38-39,59-67`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:779`, `src/ui/renderers/appkit_renderer.cr:800`, `src/ui/renderers/web_renderer.cr:530`, `src/ui/renderers/android_renderer.cr:946`)
- **crystal_api_shape:** `coord = UI::NavigationCoordinator.new(UI::NavigationCoordinator::Route.new(:home)); coord.push(UI::NavigationCoordinator::Route.new(:settings))`
- **platforms:** ios, ipados, android, web_wide, web_narrow
- **description:** Stack-based forward/back navigation (push/pop semantics).

### `:navigation_split_view`

- **intent_identifier_crystal:** `:navigation_split_view`
- **primary_apple_name:** `NavigationSplitView`
- **class:** D
- **tier:** 2
- **swiftui_api:** `NavigationSplitView(sidebar:detail:)`
- **uikit_api:** `UISplitViewController`
- **appkit_api:** `NSSplitViewController`
- **hig_page:** `split-views.md`
- **android_equivalent:** Custom two-pane layout (foldable)
- **web_equivalent:** CSS grid sidebar + main
- **coverage_today:** partial (`src/ui/views/navigation_split_view.cr:4-10` — `class NavigationSplitView < View` with `sidebar`, `content`, `detail`, `sidebar_width`, `column_visibility`; visitor entry points at `src/ui/renderers/uikit_renderer.cr:1576`, `src/ui/renderers/appkit_renderer.cr:1547`, `src/ui/renderers/web_renderer.cr:1274`, `src/ui/renderers/android_renderer.cr:1782`. Compact-collapse to stack not yet implemented at the renderer level.)
- **crystal_api_shape:** `view = UI::NavigationSplitView.new(sidebar: sidebar_view, content: list_view, detail: detail_view)`
- **platforms:** ipados, macos, web_wide
- **description:** Two- or three-pane navigation (sidebar + content + optional inspector). On compact platforms, collapses to a stack. **Why not Class A:** the framework already exposes `UI::NavigationStack` and `UI::NavigationSplitView` as separate widgets; authors pick which one based on their layout intent, and the compact-collapse is renderer-internal (the split-view widget itself doesn't change classes on iPhone — it collapses its panes). If a future phase determines authors need the framework to AUTO-PICK between Stack and SplitView per platform without naming the widget, that's a Class A candidate.

### `:navigation_link`

- **intent_identifier_crystal:** `:navigation_link`
- **primary_apple_name:** `NavigationLink`
- **class:** D
- **tier:** 2
- **swiftui_api:** `NavigationLink(value:label:)`
- **uikit_api:** `UINavigationController.pushViewController`
- **appkit_api:** —
- **hig_page:** `navigation-bars.md`
- **android_equivalent:** `NavController.navigate`
- **web_equivalent:** `<a href="...">` link triggering router
- **coverage_today:** partial (`src/ui/views/navigation_link.cr:10-21` — `class NavigationLink < View` with `label`, `destination : View`, `icon`, `shows_disclosure`; route-driven `Voyager.dispatch(:open_X)` integration is implemented per-app, not on the link type itself)
- **crystal_api_shape:** `link = UI::NavigationLink.new("Settings", settings_screen_view)`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Tappable element that pushes onto the navigation stack.

### `:navigation_destination`

- **intent_identifier_crystal:** `:navigation_destination`
- **primary_apple_name:** `navigationDestination`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.navigationDestination(for:destination:)`
- **uikit_api:** Manual `pushViewController` per value type
- **appkit_api:** —
- **hig_page:** `navigation-bars.md`
- **android_equivalent:** `composable("route") { ... }` in Compose Navigation
- **web_equivalent:** Router route definition
- **coverage_today:** shipped (`src/asset_pipeline/native_app.cr:227` — `macro screen(route_id, controller = nil, screen_class = nil, web_controller = nil, web_path = nil, web_actions = nil)` registers route→destination on `UI::App` subclasses)
- **crystal_api_shape:** `screen :foo, FooController`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Declarative mapping of a route value to a destination view. Powers value-driven navigation.

### `:navigation_path`

- **intent_identifier_crystal:** `:navigation_path`
- **primary_apple_name:** `NavigationPath`
- **class:** D
- **tier:** 2
- **swiftui_api:** `NavigationPath` (type-erased stack)
- **uikit_api:** Array of `UIViewController`
- **appkit_api:** —
- **hig_page:** `navigation-bars.md`
- **android_equivalent:** Compose `NavController.currentBackStack`
- **web_equivalent:** Browser history API
- **coverage_today:** shipped (`src/ui/navigation_coordinator.cr:38-39` — `getter routes : Array(Route)` on `UI::NavigationCoordinator`; mutators at `src/ui/navigation_coordinator.cr:59-67`)
- **crystal_api_shape:** `coord.routes  # Array(Route)`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Programmatic representation of the navigation stack — read or rewrite to deep-link.

### `:menu_picker_style`

- **intent_identifier_crystal:** `:menu_picker_style`
- **primary_apple_name:** `MenuPickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.pickerStyle(.menu)`
- **uikit_api:** `UIMenu` attached to a `UIButton`
- **appkit_api:** `NSPopUpButton`
- **hig_page:** `pickers.md`
- **android_equivalent:** Material `ExposedDropdownMenuBox`
- **web_equivalent:** `<select>` element
- **coverage_today:** partial (`src/ui/views/picker.cr:16` — `property style : PickerStyle = PickerStyle::Menu`; enum `PickerStyle` defined at `src/ui/view.cr:66`; visitors at `src/ui/renderers/uikit_renderer.cr:1000`, `src/ui/renderers/appkit_renderer.cr:1003`, `src/ui/renderers/web_renderer.cr:748`, `src/ui/renderers/android_renderer.cr:1106-1108`)
- **crystal_api_shape:** `picker.style = UI::PickerStyle::Menu`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Picker as a dropdown menu. Compact; suitable for 3-10 options.

### `:segmented_picker_style`

- **intent_identifier_crystal:** `:segmented_picker_style`
- **primary_apple_name:** `SegmentedPickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.pickerStyle(.segmented)`
- **uikit_api:** `UISegmentedControl`
- **appkit_api:** `NSSegmentedControl`
- **hig_page:** `segmented-controls.md`
- **android_equivalent:** Material `SegmentedButton`
- **web_equivalent:** Radio group styled as segments
- **coverage_today:** shipped (`src/ui/views/segmented_control.cr:4-7` — `class SegmentedControl < View` with `segments`, `selected_index`, `on_change`; visitors at `src/ui/renderers/uikit_renderer.cr:1381`, `src/ui/renderers/appkit_renderer.cr:1323`, `src/ui/renderers/web_renderer.cr:924`, `src/ui/renderers/android_renderer.cr:1408`)
- **crystal_api_shape:** `picker.style = UI::PickerStyle::Segmented` (or use the standalone `UI::SegmentedControl.new(segments)`)
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Picker as a horizontal segmented control. 2-5 options; mutually exclusive.

### `:wheel_picker_style`

- **intent_identifier_crystal:** `:wheel_picker_style`
- **primary_apple_name:** `WheelPickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.pickerStyle(.wheel)`
- **uikit_api:** `UIPickerView`
- **appkit_api:** —
- **hig_page:** `pickers.md`
- **android_equivalent:** `NumberPicker` (legacy Views)
- **web_equivalent:** Custom drum/wheel widget
- **coverage_today:** missing
- **crystal_api_shape:** `picker.style = UI::PickerStyle::Wheel` (enum value exists at `src/ui/view.cr:67`; renderer wiring not yet shipped — tracked under B-012)
- **platforms:** ios, ipados
- **description:** Picker as a rotating wheel (iOS-classic). Discoverable for long-numeric lists.

### `:palette_picker_style`

- **intent_identifier_crystal:** `:palette_picker_style`
- **primary_apple_name:** `PalettePickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.pickerStyle(.palette)`
- **uikit_api:** —
- **appkit_api:** —
- **hig_page:** `pickers.md`
- **android_equivalent:** Custom grid layout
- **web_equivalent:** Custom grid of radio inputs
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — UI::PickerStyle enum (src/ui/view.cr:66-71) does not define Palette. Adding the value is tracked under B-012 picker styles.`
- **platforms:** ios, ipados, macos (iOS 17+ / macOS 14+)
- **description:** Picker as a horizontal palette of icon swatches (emoji, color, symbol).

### `:inline_picker_style`

- **intent_identifier_crystal:** `:inline_picker_style`
- **primary_apple_name:** `InlinePickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.pickerStyle(.inline)`
- **uikit_api:** `UITableView` static cells with checkmarks
- **appkit_api:** `NSPopUpButton` with `NSMenu` displayed inline
- **hig_page:** `pickers.md`
- **android_equivalent:** Radio button list
- **web_equivalent:** Radio button list
- **coverage_today:** missing
- **crystal_api_shape:** `picker.style = UI::PickerStyle::Inline` (enum value exists at `src/ui/view.cr:70`; renderer wiring not yet shipped — tracked under B-012)
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Picker rendered as an expanded list of options (no popup). Good for 3-7 options when space allows.

### `:compact_date_picker_style`

- **intent_identifier_crystal:** `:compact_date_picker_style`
- **primary_apple_name:** `CompactDatePickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.datePickerStyle(.compact)`
- **uikit_api:** `UIDatePicker(preferredDatePickerStyle: .compact)`
- **appkit_api:** `NSDatePicker(style: .textFieldDateTime)` with popover calendar
- **hig_page:** `date-pickers.md`
- **android_equivalent:** Material `DatePicker` modal
- **web_equivalent:** `<input type="date">`
- **coverage_today:** partial (`src/ui/views/date_picker.cr:4-10` — `class DatePicker < View` with `selected_date`, `mode`, `minimum_date`, `maximum_date`, `on_change`; visitors at `src/ui/renderers/uikit_renderer.cr:1408`, `src/ui/renderers/appkit_renderer.cr:1353`, `src/ui/renderers/web_renderer.cr:957`, `src/ui/renderers/android_renderer.cr:1456`. No `date_picker_style` switch — only one rendering mode per platform today.)
- **crystal_api_shape:** `# Not yet implemented — UI::DatePicker (src/ui/views/date_picker.cr:4-22) has no date_picker_style property; only `mode` (a DatePickerMode enum) ships today. Tracked in phase-10-pre-2-close.md "new gaps surfaced".`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Compact field showing the value; tap/click to open calendar popover.

### `:graphical_date_picker_style`

- **intent_identifier_crystal:** `:graphical_date_picker_style`
- **primary_apple_name:** `GraphicalDatePickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.datePickerStyle(.graphical)`
- **uikit_api:** `UIDatePicker(preferredDatePickerStyle: .inline)`
- **appkit_api:** `NSDatePicker(style: .clockAndCalendar)`
- **hig_page:** `date-pickers.md`
- **android_equivalent:** Material `DatePicker` inline mode
- **web_equivalent:** Calendar grid widget
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — UI::DatePicker has no date_picker_style property (same gap as :compact_date_picker_style).`
- **platforms:** ios, ipados, macos, android, web_wide
- **description:** Expanded calendar view inline. Suitable for date-pickers in forms with space.

### `:wheel_date_picker_style`

- **intent_identifier_crystal:** `:wheel_date_picker_style`
- **primary_apple_name:** `WheelDatePickerStyle`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.datePickerStyle(.wheels)`
- **uikit_api:** `UIDatePicker(preferredDatePickerStyle: .wheels)`
- **appkit_api:** —
- **hig_page:** `date-pickers.md`
- **android_equivalent:** —
- **web_equivalent:** Custom wheel/drum
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — UI::DatePicker has no date_picker_style property (same gap as :compact_date_picker_style).`
- **platforms:** ios, ipados
- **description:** iOS-classic wheel picker. Use sparingly per HIG; compact is preferred.

### `:menu`

- **intent_identifier_crystal:** `:menu`
- **primary_apple_name:** `Menu`
- **class:** D
- **tier:** 2
- **swiftui_api:** `Menu("Label") { actions }`
- **uikit_api:** `UIMenu` attached to `UIButton` or `UIBarButtonItem`
- **appkit_api:** `NSMenu` attached to `NSPopUpButton` or `NSMenuItem`
- **hig_page:** `pull-down-buttons.md`, `menus.md`
- **android_equivalent:** Material `DropdownMenu`
- **web_equivalent:** Custom dropdown OR HTML `<menu>` element
- **coverage_today:** shipped (`src/ui/views/menu_button.cr:22-53` — `class MenuButton < View` with `label`, `icon`, `items : Array(MenuItem)`, `is_pull_down`, `button_style`; `add_item(label:, icon:, is_destructive:, &block)` API; visitors at `src/ui/renderers/uikit_renderer.cr:2122`, `src/ui/renderers/appkit_renderer.cr:2133`, `src/ui/renderers/web_renderer.cr:1680`, `src/ui/renderers/android_renderer.cr:2250`)
- **crystal_api_shape:** `menu = UI::MenuButton.new("More"); menu.add_item(label: "Duplicate") { ... }`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Anchored dropdown menu of actions, usually triggered by a button.

### `:ui_menu`

- **intent_identifier_crystal:** `:ui_menu`
- **primary_apple_name:** `UIMenu`
- **class:** D
- **tier:** 2
- **swiftui_api:** —
- **uikit_api:** `UIMenu(title:image:children:)`
- **appkit_api:** `NSMenu` (analogous concept)
- **hig_page:** `menus.md`
- **android_equivalent:** Compose `DropdownMenu`
- **web_equivalent:** Custom dropdown menu
- **coverage_today:** partial (`src/ui/views/menu_button.cr:23-35` — `record MenuItem` nested in `UI::MenuButton`; consumed inside the `MenuButton` visitors cited above. No top-level `UI::UIMenu` class — items live on the button.)
- **crystal_api_shape:** `# Not yet implemented — no standalone UI::UIMenu class. Today's analog is the nested UI::MenuButton::MenuItem record (src/ui/views/menu_button.cr:23-35). Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 5.`
- **platforms:** ios, ipados
- **description:** UIKit's first-class menu type. Composed of `UIAction`s. Often constructed for context menus and button-attached menus.

### `:ui_action`

- **intent_identifier_crystal:** `:ui_action`
- **primary_apple_name:** `UIAction`
- **class:** D
- **tier:** 2
- **swiftui_api:** —
- **uikit_api:** `UIAction(title:image:identifier:handler:)`
- **appkit_api:** `NSMenuItem` (analogous concept)
- **hig_page:** `menus.md`
- **android_equivalent:** Compose `DropdownMenuItem`
- **web_equivalent:** `<button>` inside menu
- **coverage_today:** partial (`src/ui/views/menu_button.cr:23-35` — `MenuItem` carries `label`, `icon`, `is_destructive`, `action : Proc(Nil)?`; analogous to UIAction but scoped to MenuButton. No standalone `UI::UIAction` class.)
- **crystal_api_shape:** `# Not yet implemented — no standalone UI::UIAction class. Today's analog is the nested UI::MenuButton::MenuItem record (src/ui/views/menu_button.cr:23-35). Tracked in phase-10-pre-2-close.md "new gaps surfaced" item 5.`
- **platforms:** ios, ipados
- **description:** UIKit's first-class menu item. Encodes title, image, attributes (destructive, hidden, disabled), and handler.

### `:context_menu`

- **intent_identifier_crystal:** `:context_menu`
- **primary_apple_name:** `contextMenu`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.contextMenu { actions }`
- **uikit_api:** `UIContextMenuConfiguration`, `UIContextMenuInteraction`
- **appkit_api:** `NSMenu` via `menu(for:)` on `NSView`
- **hig_page:** `menus.md`
- **android_equivalent:** Compose `combinedClickable(onLongClick:)` opening `DropdownMenu`
- **web_equivalent:** `contextmenu` event + custom menu
- **coverage_today:** shipped (`src/ui/views/context_menu.cr:10` — `class ContextMenu < View` (iOS-gated); `src/ui/views/context_menu_with_web_fallback.cr:15` — cross-platform wrapper; visitors at `src/ui/renderers/appkit_renderer.cr:2164,3782`, `src/ui/renderers/web_renderer.cr:1720,1737`, `src/ui/renderers/android_renderer.cr:2263`)
- **crystal_api_shape:** `menu = UI::ContextMenu.new; menu.add_item(label: "Delete", is_destructive: true) { ... }`
- **platforms:** ios (long-press), ipados (long-press + pointer right-click), macos (right-click), android (long-press), web_wide (right-click), web_narrow (long-press)
- **description:** Long-press / right-click action palette on an element. Triggered by the platform's idiomatic gesture.

### `:primary_action`

- **intent_identifier_crystal:** `:primary_action`
- **primary_apple_name:** `primaryAction`
- **class:** D
- **tier:** 2
- **swiftui_api:** `Menu("Label", primaryAction: { ... }) { ... }`
- **uikit_api:** `UIMenu` `primaryAction` property
- **appkit_api:** —
- **hig_page:** `pull-down-buttons.md`
- **android_equivalent:** Split-button (custom composition)
- **web_equivalent:** Split button (button + dropdown caret)
- **coverage_today:** missing
- **crystal_api_shape:** `menu.primary_action = -> { state.do_default }`
- **platforms:** ios, ipados, macos
- **description:** Tap-default of a pull-down/menu button. Tap = primary action; long-press/click-arrow = menu.

### `:draggable`

- **intent_identifier_crystal:** `:draggable`
- **primary_apple_name:** `draggable`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.draggable(_:)`
- **uikit_api:** `UIDragInteraction`, `UIDragItem`
- **appkit_api:** `NSDraggingSource`
- **hig_page:** `drag-and-drop.md`
- **android_equivalent:** `View.startDragAndDrop`
- **web_equivalent:** HTML5 `draggable="true"` + drag events
- **coverage_today:** missing
- **crystal_api_shape:** `view.draggable = { transferable_payload }`
- **platforms:** ios, ipados, macos, android, web_wide
- **description:** Mark a view as the source of a drag operation.

### `:drop_destination`

- **intent_identifier_crystal:** `:drop_destination`
- **primary_apple_name:** `dropDestination`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.dropDestination(for:action:)`
- **uikit_api:** `UIDropInteraction`, `UIDropInteractionDelegate`
- **appkit_api:** `NSDraggingDestination`
- **hig_page:** `drag-and-drop.md`
- **android_equivalent:** `View.setOnDragListener`
- **web_equivalent:** HTML5 drop events
- **coverage_today:** missing
- **crystal_api_shape:** `view.drop_destination = ->(payload, location) { ... }`
- **platforms:** ios, ipados, macos, android, web_wide
- **description:** Mark a view as accepting a drop.

### `:transferable`

- **intent_identifier_crystal:** `:transferable`
- **primary_apple_name:** `Transferable`
- **class:** D
- **tier:** 2
- **swiftui_api:** `Transferable` protocol
- **uikit_api:** `NSItemProvider`
- **appkit_api:** `NSPasteboardWriting` / `NSPasteboardReading`
- **hig_page:** `drag-and-drop.md`
- **android_equivalent:** `ClipData`
- **web_equivalent:** `DataTransfer` API
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::Transferable module in src/ui/. Drag-and-drop is unimplemented on UI::View base.`
- **platforms:** ios, ipados, macos, android, web_wide
- **description:** Protocol for declaring how a Crystal type encodes/decodes for drag-drop and clipboard.

### `:transition`

- **intent_identifier_crystal:** `:transition`
- **primary_apple_name:** `transition`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.transition(_:)`
- **uikit_api:** `UIView.transition(with:duration:options:animations:completion:)`
- **appkit_api:** `NSAnimationContext`
- **hig_page:** `motion.md`
- **android_equivalent:** Compose `AnimatedVisibility` with `enter`/`exit`
- **web_equivalent:** CSS `transition` property
- **coverage_today:** missing
- **crystal_api_shape:** `view.transition = :fade | :slide | :scale`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Animation applied when a view enters or leaves the hierarchy.

### `:matched_geometry_effect`

- **intent_identifier_crystal:** `:matched_geometry_effect`
- **primary_apple_name:** `matchedGeometryEffect`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.matchedGeometryEffect(id:in:)`
- **uikit_api:** Manual animatable layout
- **appkit_api:** —
- **hig_page:** `motion.md`
- **android_equivalent:** Compose `SharedTransitionLayout`
- **web_equivalent:** FLIP technique (custom JS)
- **coverage_today:** missing
- **crystal_api_shape:** `view.matched_geometry_id = :hero_image`
- **platforms:** ios, ipados, macos, android
- **description:** Hero-style animation that morphs a view between two parents with shared identity.

### `:animation`

- **intent_identifier_crystal:** `:animation`
- **primary_apple_name:** `animation` (modifier form)
- **class:** D
- **tier:** 2
- **swiftui_api:** `.animation(_:value:)`
- **uikit_api:** `UIView.animate(withDuration:animations:)`
- **appkit_api:** `NSAnimationContext.runAnimationGroup`
- **hig_page:** `motion.md`
- **android_equivalent:** Compose `animateAsState`
- **web_equivalent:** CSS animations + transitions
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::Animation class and no view.animation= setter on UI::View base. Animation system unimplemented across renderers.`
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Apply an animation curve to property changes on a view.

### `:phase_animator`

- **intent_identifier_crystal:** `:phase_animator`
- **primary_apple_name:** `PhaseAnimator`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.phaseAnimator(_:content:animation:)` (iOS 17+)
- **uikit_api:** Manual chained animations
- **appkit_api:** —
- **hig_page:** `motion.md`
- **android_equivalent:** Compose `updateTransition` sequenced
- **web_equivalent:** CSS `@keyframes` with multiple stops
- **coverage_today:** missing
- **crystal_api_shape:** `view.phase_animator = [:a, :b, :c]`
- **platforms:** ios, ipados, macos (17+ / 14+)
- **description:** Multi-phase sequential animation. View cycles through phases automatically.

### `:keyframe_animator`

- **intent_identifier_crystal:** `:keyframe_animator`
- **primary_apple_name:** `KeyframeAnimator`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.keyframeAnimator(initialValue:trigger:content:keyframes:)` (iOS 17+)
- **uikit_api:** `CAKeyframeAnimation`
- **appkit_api:** `CAKeyframeAnimation`
- **hig_page:** `motion.md`
- **android_equivalent:** Compose `keyframes { }`
- **web_equivalent:** CSS `@keyframes`
- **coverage_today:** missing
- **crystal_api_shape:** `view.keyframe_animator = { ... }`
- **platforms:** ios, ipados, macos (17+ / 14+), android, web_wide, web_narrow
- **description:** Keyframe-based animation with per-frame values.

### `:sensory_feedback`

- **intent_identifier_crystal:** `:sensory_feedback`
- **primary_apple_name:** `sensoryFeedback`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.sensoryFeedback(_:trigger:)` (iOS 17+)
- **uikit_api:** Composite of feedback generators (see :ui_impact_feedback_generator, :ui_notification_feedback_generator, :ui_selection_feedback_generator)
- **appkit_api:** `NSHapticFeedbackManager`
- **hig_page:** `playing-haptics.md`
- **android_equivalent:** `View.performHapticFeedback`
- **web_equivalent:** `navigator.vibrate()` (limited support)
- **coverage_today:** missing
- **crystal_api_shape:** `view.sensory_feedback = :success | :warning | :error | :impact | :selection`
- **platforms:** ios, ipados, android
- **description:** SwiftUI's high-level haptic feedback modifier (iOS 17+). Trigger on a state change or user action.

### `:ui_impact_feedback_generator`

- **intent_identifier_crystal:** `:ui_impact_feedback_generator`
- **primary_apple_name:** `UIImpactFeedbackGenerator`
- **class:** D
- **tier:** 2
- **swiftui_api:** Use `.sensoryFeedback(.impact(weight:intensity:))` instead
- **uikit_api:** `UIImpactFeedbackGenerator(style: .light/.medium/.heavy/.rigid/.soft)`
- **appkit_api:** —
- **hig_page:** `playing-haptics.md`
- **android_equivalent:** `View.performHapticFeedback(HapticFeedbackConstants.CONTEXT_CLICK)`
- **web_equivalent:** —
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::UIImpactFeedbackGenerator class. Haptic system unimplemented in src/ui/.`
- **platforms:** ios, ipados
- **description:** UIKit's impact-style haptic generator. Distinct styles for collision-feel feedback.

### `:ui_notification_feedback_generator`

- **intent_identifier_crystal:** `:ui_notification_feedback_generator`
- **primary_apple_name:** `UINotificationFeedbackGenerator`
- **class:** D
- **tier:** 2
- **swiftui_api:** Use `.sensoryFeedback(.success | .warning | .error)` instead
- **uikit_api:** `UINotificationFeedbackGenerator`
- **appkit_api:** —
- **hig_page:** `playing-haptics.md`
- **android_equivalent:** `View.performHapticFeedback(HapticFeedbackConstants.CONFIRM)`
- **web_equivalent:** —
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::UINotificationFeedbackGenerator class. Haptic system unimplemented in src/ui/.`
- **platforms:** ios, ipados
- **description:** UIKit's success/warning/error haptic generator. Semantic notification-level feedback.

### `:ui_selection_feedback_generator`

- **intent_identifier_crystal:** `:ui_selection_feedback_generator`
- **primary_apple_name:** `UISelectionFeedbackGenerator`
- **class:** D
- **tier:** 2
- **swiftui_api:** Use `.sensoryFeedback(.selection)` instead
- **uikit_api:** `UISelectionFeedbackGenerator`
- **appkit_api:** —
- **hig_page:** `playing-haptics.md`
- **android_equivalent:** —
- **web_equivalent:** —
- **coverage_today:** missing
- **crystal_api_shape:** `# Not yet implemented — no UI::UISelectionFeedbackGenerator class. Haptic system unimplemented in src/ui/.`
- **platforms:** ios, ipados
- **description:** UIKit's selection-change haptic generator. Subtle tick for picker scrolls, segmented control changes.

### `:tap_gesture`

- **intent_identifier_crystal:** `:tap_gesture`
- **primary_apple_name:** `TapGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.onTapGesture(count:perform:)`
- **uikit_api:** `UITapGestureRecognizer`
- **appkit_api:** `NSClickGestureRecognizer`
- **hig_page:** `gestures.md`
- **android_equivalent:** `Modifier.clickable`
- **web_equivalent:** `click` event
- **coverage_today:** partial (`on_tap` exists on `src/ui/views/button.cr:93`, `src/ui/views/icon_button.cr:22`, `src/ui/views/link_button.cr:8`, and on `SwipeAction` at `src/ui/views/swipe_action_row.cr:23`; **NOT** on base `UI::View` (no `on_tap` property exists on the base class — verified by grep)) # caveats: framework-wide tap-gesture surface is missing — clicks must be wired to a button-family widget today. Tracked by B-037-adjacent work; full surface deferred to 10B.
- **crystal_api_shape:** `button.on_tap = -> { ... }` (available on `Button`, `IconButton`, `LinkButton`, `SwipeAction` only; NOT on base `UI::View`)
- **platforms:** ios, ipados, macos, android, web_wide, web_narrow
- **description:** Tap or click handler.

### `:long_press_gesture`

- **intent_identifier_crystal:** `:long_press_gesture`
- **primary_apple_name:** `LongPressGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `.onLongPressGesture(minimumDuration:perform:)`
- **uikit_api:** `UILongPressGestureRecognizer`
- **appkit_api:** `NSPressGestureRecognizer`
- **hig_page:** `gestures.md`
- **android_equivalent:** `Modifier.combinedClickable(onLongClick:)`
- **web_equivalent:** Manual timer on `pointerdown`/`pointerup`
- **coverage_today:** missing as a standalone modifier (used internally by ContextMenu)
- **crystal_api_shape:** `view.on_long_press = -> { ... }`
- **platforms:** ios, ipados, android, web_narrow
- **description:** Long-press handler. Most commonly used internally by `:context_menu`.

### `:drag_gesture`

- **intent_identifier_crystal:** `:drag_gesture`
- **primary_apple_name:** `DragGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `DragGesture` (composed via `.gesture`)
- **uikit_api:** `UIPanGestureRecognizer`
- **appkit_api:** `NSPanGestureRecognizer`
- **hig_page:** `gestures.md`
- **android_equivalent:** `Modifier.draggable`
- **web_equivalent:** `pointerdown`/`pointermove`/`pointerup` event sequence
- **coverage_today:** missing
- **crystal_api_shape:** `view.on_drag = ->(translation : Point) { ... }`
- **platforms:** ios, ipados, macos, android, web_wide
- **description:** Pan/drag gesture handler for custom interactions.

### `:magnify_gesture`

- **intent_identifier_crystal:** `:magnify_gesture`
- **primary_apple_name:** `MagnifyGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `MagnifyGesture` (composed via `.gesture`)
- **uikit_api:** `UIPinchGestureRecognizer`
- **appkit_api:** `NSMagnificationGestureRecognizer`
- **hig_page:** `gestures.md`
- **android_equivalent:** `Modifier.transformable` (scale parameter)
- **web_equivalent:** Manual pointer-event multi-touch handling
- **coverage_today:** missing
- **crystal_api_shape:** `view.on_magnify = ->(scale : Float64) { ... }`
- **platforms:** ios, ipados, macos (trackpad), android, web_wide (trackpad)
- **description:** Pinch-to-zoom gesture handler.

### `:rotate_gesture`

- **intent_identifier_crystal:** `:rotate_gesture`
- **primary_apple_name:** `RotateGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `RotateGesture` (composed via `.gesture`)
- **uikit_api:** `UIRotationGestureRecognizer`
- **appkit_api:** `NSRotationGestureRecognizer`
- **hig_page:** `gestures.md`
- **android_equivalent:** `Modifier.transformable` (rotate parameter)
- **web_equivalent:** Manual pointer multi-touch handling
- **coverage_today:** missing
- **crystal_api_shape:** `view.on_rotate = ->(angle : Float64) { ... }`
- **platforms:** ios, ipados, macos (trackpad), android
- **description:** Rotation gesture handler.

### `:spatial_tap_gesture`

- **intent_identifier_crystal:** `:spatial_tap_gesture`
- **primary_apple_name:** `SpatialTapGesture`
- **class:** D
- **tier:** 2
- **swiftui_api:** `SpatialTapGesture`
- **uikit_api:** —
- **appkit_api:** —
- **hig_page:** `gestures.md`
- **android_equivalent:** —
- **web_equivalent:** —
- **coverage_today:** missing (visionOS-specific; not in current scope)
- **crystal_api_shape:** `view.on_spatial_tap = ->(location : Point3D) { ... }`
- **platforms:** visionOS only (out of current cross-platform scope)
- **description:** Tap gesture in 3D space (visionOS / spatial computing).

---

**Catalog totals (corrected by Phase 10-pre.1, verified 2026-05-25):**

- **92 schema entries** total (Class A: 1, Class B: 18, Class C: 9, Class D: 64).
- **67 top-level intent concepts** — the schema-entry count is higher because composed intents (e.g. picker styles, presentation modifiers) ship multiple catalog rows under one top-level concept.
- Every identifier is the snake_case form of `primary_apple_name`. Every row carries the full schema. Class D entries additionally carry `crystal_api_shape` and `platforms`.

This catalog is the source of truth. Phase 9 deliverables 2-7 cross-reference these identifiers.

— Architect (Claude Opus 4.7)
