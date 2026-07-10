# Phase 10-pre.1 — Class C Re-audit (Deliverable 8)

**Date:** 2026-05-25
**Auditor:** Phase 10-pre.1 implementer (Claude Opus 4.7)
**Trigger:** Codex caught the original freshness audit's `:share_link` false-negative by skipping `src/ui/renderers/` and `src/ui/native/`. This re-audit re-verifies all 9 Class C intents against renderers + native bridges, not just `src/ui/views/`.

## Methodology

Audit-scope discipline (per the 2026-05-25 correction block in `phase-10-pre-catalog-freshness-2026-05-25.md`): every grep MUST cover `src/ui/renderers/*.cr`, `src/ui/native/*.{cr,m,c}`, and `src/ui/*.cr` — not only `src/ui/views/`.

Command pattern used:

```bash
grep -rn "<API_NAME>" src/ui/renderers/ src/ui/native/ src/ui/ 2>/dev/null
```

Each Class C intent was greped against its native API set per the brief §4 Deliverable 8 table.

## Per-intent findings

### `:share_link` — SHIPPED

Native APIs scanned: `UIActivityViewController`, `NSSharingServicePicker`, `Intent.ACTION_SEND`, plus the named bridge funs `uiactivityview_present`, `nssharingservicepicker_present`, `android_context_start_share_chooser`.

Evidence:

- `src/ui/renderers/uikit_renderer.cr:108` — `fun uiactivityview_present(...)` Crystal lib binding.
- `src/ui/renderers/uikit_renderer.cr:3408` — `LibObjCBridge.uiactivityview_present(...)` invoked from the iOS `visit(UI::ActivityView)` path.
- `src/ui/renderers/appkit_renderer.cr:88` — `fun nssharingservicepicker_present(...)` Crystal lib binding.
- `src/ui/renderers/appkit_renderer.cr:3417` — `LibObjCBridge.nssharingservicepicker_present(...)` invoked from the macOS `visit(UI::ActivityView)` path.
- `src/ui/renderers/android_renderer.cr:148` — `fun android_context_start_share_chooser(...)` JNI binding.
- `src/ui/renderers/android_renderer.cr:2871` — `LibAndroidBridge.android_context_start_share_chooser(...)` invoked from the Android visitor.
- `src/ui/native/objc_bridge.m:2148` — `nssharingservicepicker_present` ObjC implementation (uses `NSSharingServicePicker`).
- `src/ui/native/objc_bridge.m:2163` — `[NSSharingServicePicker alloc] initWithItems:items`.
- `src/ui/native/objc_bridge.m:2216` — `uiactivityview_present` ObjC implementation.
- `src/ui/native/objc_bridge.m:2234-2235` — `[[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil]`.
- `src/ui/native/android_bridge.c:1045` — `android_context_start_share_chooser` JNI C implementation.

**Verdict:** SHIPPED on all four platforms (iOS, macOS, Android, web). The original audit's "missing" verdict was wrong; Codex's catch is confirmed. Catalog row `:share_link` upgrades from `missing` → `shipped (citations)`.

### `:copyable` — MISSING (confirmed)

Native APIs scanned: `UIPasteboard`, `NSPasteboard`, `ClipboardManager`, plus the broader `pasteboard|clipboard|copyable|paste_button` grep.

Result: **zero matches** in `src/ui/renderers/`, `src/ui/native/`, or `src/ui/`.

**Verdict:** MISSING (confirms freshness audit + 2026-05-25 correction).

### `:paste_button` — MISSING (confirmed)

Same scan as `:copyable` (shares the pasteboard API surface).

Result: **zero matches**.

**Verdict:** MISSING.

### `:authorization_request` — MISSING (confirmed for the catalog's scope)

Native APIs scanned: `AVCaptureDevice.requestAccess`, `PHPhotoLibrary`, `CLLocationManager`, `Manifest.permission`, broader `authorization|requestAccess|requestPermission`.

Result: zero matches for camera/photo/location/contacts/microphone permissions across renderers and native bridges.

Note (out of catalog scope): `src/ui/native/objc_bridge.m:2268-2297` contains `ap_notifications_authorization_status` and `ap_notifications_request_authorization` calling `UNAuthorizationOptions` — these are part of `:user_notification` (system experience / Class E per the catalog's preamble at line 11). Class E "system experiences" are explicitly out of Phase 9 scope, so this does not change the `:authorization_request` Class C verdict.

**Verdict:** MISSING for the AVFoundation / Photos / CoreLocation surface the `:authorization_request` intent points at. Notification authorization lives in a separate (unscoped) class.

### `:open_url` — MISSING (confirmed)

Native APIs scanned: `openURL:`, `UIApplication.shared.open`, `NSWorkspace.open`, `Intent.ACTION_VIEW`.

Result: zero matches for any `openURL:` selector or `NSWorkspace` invocation in the renderers or native bridges. `UIApplication` appears (e.g. `src/ui/native/objc_bridge.m:439`) but only for scene enumeration and shortcut handling — not for URL opening.

Closest analog: `src/ui/views/link_button.cr` emits an `<a href=...>` on web (per-view markup). That is not a Class C cross-platform URL-opening bridge — it is HTML emission inside one view.

**Verdict:** MISSING.

### `:on_open_url` — MISSING (confirmed)

Native APIs scanned: `application:openURL:options:`, `application:continueUserActivity:`, `onOpenURL`, Android intent filters.

Result: zero matches.

**Verdict:** MISSING.

### `:ui_print_interaction_controller` — MISSING (confirmed)

Native APIs scanned: `UIPrintInteractionController`, `NSPrintInfo`, `NSPrintOperation`, `PrintHelper`.

Result: zero matches.

**Verdict:** MISSING.

### `:file_importer` — MISSING (confirmed)

Native APIs scanned: `UIDocumentPickerViewController`, `NSOpenPanel`, `ActivityResultContracts.OpenDocument`, plus broader `documentpicker|fileimporter|openpanel`.

Result: zero matches.

**Verdict:** MISSING.

### `:file_exporter` — MISSING (confirmed)

Native APIs scanned: `NSSavePanel`, `UIDocumentInteractionController`, `ActivityResultContracts.CreateDocument`, plus broader `savepanel|fileexporter`.

Result: zero matches.

**Verdict:** MISSING.

## Summary

| Intent | Verdict | Action in catalog |
|---|---|---|
| `:share_link` | SHIPPED | Upgrade `missing` → `shipped` with renderer + native-bridge citations. |
| `:copyable` | MISSING | Leave as `missing`. |
| `:paste_button` | MISSING | Leave as `missing`. |
| `:authorization_request` | MISSING | Leave as `missing`. (Notifications auth is Class E, out of scope.) |
| `:open_url` | MISSING | Leave as `missing`. |
| `:on_open_url` | MISSING | Leave as `missing`. |
| `:ui_print_interaction_controller` | MISSING | Leave as `missing`. |
| `:file_importer` | MISSING | Leave as `missing`. |
| `:file_exporter` | MISSING | Leave as `missing`. |

**Class C corrected realization:** 1/9 shipped (`:share_link`), 8/9 missing. Matches the 2026-05-25 correction; no further false-negatives surfaced.

## Audit-scope command record (for future re-audits)

```bash
# Per-intent template — substitute the native API names from the brief §4 Deliverable 8 table.
grep -rn "<NATIVE_API>" src/ui/renderers/ src/ui/native/ src/ui/ 2>/dev/null

# Broader confirmation pass — catches cases where the bridge fn name differs from the Apple API name.
grep -rn -i "<keyword>" src/ui/renderers/ src/ui/native/ src/ui/ 2>/dev/null
```

The `src/ui/renderers/` + `src/ui/native/` pair is THE coverage gap the original audit missed. Future framework-coverage audits MUST include both, not just `src/ui/views/`.
