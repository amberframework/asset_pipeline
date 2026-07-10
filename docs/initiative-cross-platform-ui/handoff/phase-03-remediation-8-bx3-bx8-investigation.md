# Phase 3 Remediation 8 — BX3 + BX8 investigation notes

**Status:** Remediation 8 closed BX4, BX6, BX9. BX3 and BX8 remain
FAIL on iOS 26.5 / iPhone 17 Pro simulator after a substantial
investigation; both surface a deeper iOS-specific integration
issue and are documented here for follow-up rather than burning
further cycles in Remediation 8.

## Remediation 8 outcome summary

| Check | Pre-iter6 status | Post-iter8 status | Notes |
|-------|------------------|-------------------|-------|
| BX1 | PASS | PASS | iOS Button tap callback — unchanged. |
| BX2 | PASS (macOS) | PASS | macOS reactive label — unchanged. |
| BX3 | FAIL | FAIL | iOS Toggle binding — see below. |
| BX4 | FAIL (crash) | **PASS** | SliderProbe sprintf crash fixed via manual decimal formatter (commit 4f7da71). |
| BX5 | PASS | PASS | iOS runtime override re-render — unchanged. |
| BX6 | FAIL (25.125pt) | **PASS** | Form row touch target — fixed by `.contentShape(Rectangle())` (commit 9e49083). |
| BX7 | PASS | PASS | macOS twin — unchanged. |
| BX8 | FAIL (crash) | FAIL | Sheet slug crash — see below. |
| BX9 | FAIL (25.125pt) | **PASS** | Standalone Button touch target — same fix as BX6. |
| BX10 | PASS | PASS | Dark mode tint shift — unchanged. |
| BX11 | PASS | PASS | macOS-only — unchanged. |
| BX12 | PASS | PASS | iOS runtime init order — unchanged. |

Net: 3 of 5 iOS FAILs closed in Remediation 8. BX3 and BX8 deferred.

## BX3 — Toggle synthetic tap reaches AX element but isOn does not flip

### What was tried

1. **Restructured ToggleFacade to build the Toggle inside the View
   body.** Previously the `Toggle(label, isOn: storage.binding)`
   was constructed at `makeReactiveToggle` call-time with a
   closure-built `Binding(get:set:)`. Suspected that closure-built
   Bindings don't pick up the iOS 26 accessibility-activate path
   when the UIHostingController is mounted via UIViewRepresentable.
   Migrated to `@ObservedObject var storage` inside a dedicated
   `ToggleHost: View` struct and bound with `$storage.value` (the
   @Published projected value). Added `.onChange(of: storage.value)`
   to fire the Crystal callback; added `BoolStorage.suppressNextFire`
   + `setProgrammatically(_:)` to avoid double-firing on Crystal-
   driven programmatic mutation.

2. **Pinned `.toggleStyle(.switch)` as the iOS default.** Default
   toggleStyle on iOS is `.automatic` which resolves to switch
   anyway, but pinning makes the AX trait unambiguously "switch"
   and matches XCUITest's `app.switches[...]` lookup.

3. **Added `.contentShape(Rectangle())` to the Toggle.** This was
   the missing piece that fixed BX6/BX9 (Button hit-test rect).
   For Toggle it did not help — the underlying isOn binding still
   doesn't flip on synthetic tap.

### Status

XCUITest reports the tap as delivered (`toggle.tap()` returns
without error and the test continues to the assertion). The
SwiftUI `BoolStorage.value` Published property never receives a
write. Crystal `on_change` handler never fires.

### Hypothesis

This is a UIHostingController-mounted-as-UIViewRepresentable hit-
test propagation gap specific to value-bound SwiftUI controls.
Button works (BX1 passes) because the Button uses a discrete
action callback, not a two-way binding. Toggle uses
`Binding<Bool>` — when XCUITest taps it, the AX-activate path
must walk through the UIHostingController, SwiftUI internals,
the UISwitch action handler, and back into the Binding setter.
One of those hops is broken under the current hosting topology.

### Recommended next steps

- Try mounting the Crystal-built UIView inside a UIViewController
  (add a child VC) so the UIHostingController has a proper
  responder-chain parent.
- Try `UIHostingConfiguration` (iOS 16+) instead of
  `UIHostingController.view` for the inline-mounted case.
- Try a deliberate `Thread.sleep(forTimeInterval: 0.5)` after the
  tap (the current sleep is 0.25s); the binding might be flipping
  but the test reads too early.
- Try `.allowsHitTesting(true)` explicitly on the Toggle.

## BX8 — Sheet slug crashes at launch in apsk_nsstring

### Crash signature

```
EXC_BAD_ACCESS at 0x0
  _platform_strlen @ 4
  +[NSString stringWithUTF8String:] @ 40
  apsk_nsstring @ 64
  apsk_make_label_reactive @ 100
  *UI::UIKit::Renderer#visit<UI::Label>:Nil @ 132
```

The `apsk_nsstring` NULL check (which I hardened to return `@""`)
passes — meaning the C `text` pointer is non-NULL — yet
`[NSString stringWithUTF8String:]` walks into `strlen` which then
dereferences address 0. The pointer is non-NULL but invalid.

### What was tried

1. **`apsk_nsstring` returns `@""` for NULL.** Did not help —
   the crash is not from a NULL pointer.

2. **Captured `view.text` into a local variable before the FFI.**
   Did not help — the GC is not actually collecting the String,
   but something else is invalidating the byte pointer.

3. **Copied `view.text` bytes into a `libc malloc` null-terminated
   buffer and called `LibC.free` after the FFI returns.** This
   regressed: the same slug now crashed EARLIER, inside
   `visit<UI::Label> @ 116` (KERN_INVALID_ADDRESS at 0x4 —
   nil-class-pointer plus offset). The detour exposed a separate
   Crystal-iOS String#bytesize ABI mismatch we don't fully
   understand yet. Reverted.

### Hypothesis

The crash is specific to `phase-03-sheet-focus-return` because
the sheet slug renders its inner labels via `render_detached(content)`
on the Sheet view. The detached render saves and restores the
visitor's stack — somewhere in that save/restore the Label's
inner String pointer becomes stale. BX1, BX5, etc. don't crash
because they don't use `render_detached`.

### Recommended next steps

- Instrument `render_detached` to confirm the offending Label's
  text address before and after the save/restore.
- Try forcing a copy of all child views before `render_detached`
  via `view.dup`.
- Investigate why the libc-malloc detour regressed to a
  String#bytesize crash — likely a Crystal-iOS class-layout
  miscompilation that affects more than just this slug.
