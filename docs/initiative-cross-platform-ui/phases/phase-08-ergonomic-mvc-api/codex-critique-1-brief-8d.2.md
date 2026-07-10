# Phase 8D.2 Brief Critique — Codex Antagonist (Architect-Side, Iter 1)

**Date:** 2026-05-25
**Brief reviewed:** `phase-08-ergonomic-mvc-api/brief-8d.2.md` (v1)
**Per directive:** `[[codex-as-architect-antagonist]]`
**Codex CLI invocation:** arg-form prompt, medium reasoning, tee'd to `/tmp/codex-critique-brief-8d2.log`.

## Verdict: REVISE

16 findings: 2 BLOCKER, 5 HIGH, 6 MEDIUM, 3 LOW. All addressed in brief v2.

## Findings

### BLOCKER 1 — `initialize_runtime` omits initial slug-buffer seeding

Existing `bridge.cr:160` calls `copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))` before marking `@@initialized = true`. Brief v1 step 13 omits this. Without it, the first `voyager_current_slug()` call before any navigation returns an empty zeroed buffer.

**Resolution (v2):** Add explicit step 13: `copy_slug_to_buf(Voyager.slug_for_route_id(coord.current.id))`. Move `@@initialized = true` to step 14.

### BLOCKER 2 — Owner hand-test Step 3 (Add Todo → Save) is blocked by pre-existing Save-disabled-while-blank logic

`samples/initiative-cross-platform-ui-voyager/screens/todo_editor.cr:120`:
```crystal
save.disabled = seed_title.strip.empty?
```

For "Add new todo" with `todo_id == 0`, `seed_title == ""` so `save.disabled = true` at render time. There is no reactive re-enable when the user types (a documented Phase 8B follow-up). Step 3 of the hand-test ("type title, tap Save") cannot dispatch — the button remains disabled.

**Resolution (v2):** Restructure hand-test recipe to exercise Save through the **Edit** path (where `seed_title` is non-empty):
- Step 3: Tap "Add Todo" → confirm Editor renders → tap "Cancel" → confirm Pop to Todos with no new row.
- Step 4 (new): Swipe a seeded todo → tap "Edit" → confirm Editor renders with title prefilled → edit the title → tap "Save" → confirm Pop with updated title.

This proves Save dispatch AND the params-propagation contract (`ctx.action_params["todo_id"]` → `Navigate(:todo_editor, params: {todo_id})` → editor reads `ctx.params["todo_id"]`).

### HIGH 1 — Item 2 sample code labels with stale slug

Brief v1's `render_slug` sample sets:
```crystal
view.accessibility_label = "voyager-root-#{slug}"
view.test_id = "voyager-root-#{slug}"
```

But the rendered screen is `coord.current.id`'s registration. If Swift passes a slug disagreeing with `coord.current` (and resync doesn't fire), AX identity diverges from rendered content.

**Resolution (v2):** Use `current_slug = Voyager.slug_for_route_id(coord.current.id)` and label with `current_slug`.

### HIGH 2 — `testColdLaunchDispatcherWired` is too weak for the migration's main risk

Sign-in cold-launch proves render + AX discovery only — does NOT exercise initial slug resync, dispatcher-backed `ScreenContext`, or route-specific FormState seeding.

**Resolution (v2):** Add a second XCUITest `testColdLaunchTodosDispatcherWired` that launches with `VOYAGER_ROOT_SLUG=voyager-todos` and asserts `voyager-todos-add` (or equivalent Todos-specific element) is AX-discoverable within 10s. Two cold-launch smokes total.

### HIGH 3 — `testRenderInitialSlug` does not actually assert root existence

Existing test computes `foundRoot` but only records an XCTContext activity if false — never `XCTAssert(foundRoot, ...)`. Marked green even when roots are missing.

**Resolution (v2):** Implementer adds `XCTAssertTrue(foundRoot, "...")`. This is a test fix, not a Swift production change — covered under "test Swift is free."

### HIGH 4 — Option 7A leaves no automated Crystal-side proof of iOS host wiring

Skipping all Crystal-side host-wiring smoke is too thin. A small flag-agnostic helper would catch the exact sequence risks: `Voyager.state` assignment, dispatcher creation, initial `mount_screen`, `Voyager.dispatcher`, current FormState seed.

**Resolution (v2):** Implementer extracts the construction sequence into a flag-agnostic `VoyagerBridge::HostBootstrap` module method (or equivalent) that returns a `{state, coord, session, flash, dispatcher}` tuple/record. The iOS `initialize_runtime` calls it. A new spec at `spec/asset_pipeline/voyager_ios_bootstrap_spec.cr` exercises this helper and verifies:
- `Voyager.state` is set + identical to the returned state.
- Dispatcher's `current_form_state.mount_token != 0` (mount_screen was called).
- `Voyager.dispatcher` is non-nil after the helper returns.
- The dispatcher's coord points at `:sign_in` initially.

### HIGH 5 — R11 understated; elevate

R11 was framed as "awkward spec coverage" but is actually the main vector for shipping with the bridge compiling only under simulator + no unit assertion of the runtime sequence.

**Resolution (v2):** Elevate R11 mitigation to be the HIGH 4 helper extraction (mandatory, not optional). The brief no longer offers "skip Crystal spec entirely" as a valid path.

### MEDIUM 1 — `mount_screen` is not idempotent; don't imply otherwise

Calling `mount_screen` again always increments `current_mount_token` and replaces FormState. Repeated mounts are intentional remounts.

**Resolution (v2):** Brief language clarified: "the first `mount_screen` seeds the initial mount; subsequent calls via `translate_result` are intentional remounts that bump the token."

### MEDIUM 2 — Placeholder branch is mostly defensive, not robust unknown-slug handling

`Voyager.route_for_slug` maps unknown slugs to `:sign_in`, so the placeholder fires only if a registered route has nil `screen_class` (impossible by construction in VoyagerApp).

**Resolution (v2):** Brief language clarified: "defensive guard for future registration shapes; not robust unknown-slug handling — that's `route_for_slug`'s job."

### MEDIUM 3 — Don't overclaim "no crash log"

XCUITest fails on missing button if the app crashes, but does not prove "no crash log" without active diagnostic inspection.

**Resolution (v2):** Brief removes the "no crash log" language. XCUITest acceptance is "test passes within timeout" (which implies no crash before the assertion is reached, but does not actively check diagnostic reports).

### MEDIUM 4 — Hands-on recipe misses destructive + same-route rerender paths

Brief v1 covers push/pop/replace_root + text FormState. Misses delete (destructive) + checkbox toggle (Rerender on same route).

**Resolution (v2):** Recipe extended:
- Step 5 (new): Tap a row's checkbox → confirm strikethrough applies on the SAME route (Rerender).
- Step 6 (new): Swipe a row → tap "Delete" → confirm row disappears (Rerender, destructive action).
- Step 7 (was step 5): Settings flow.

Final 7-step recipe in v2.

### MEDIUM 5 — Mode A / Mode B needs failure loop

If Mode B finds XCUITest or simulator failure, the protocol must send the same implementer back to Mode A with the failure artifacts attached.

**Resolution (v2):** Brief Section 7 specifies: "If Mode B fails, architect dispatches Mode A (remediation) via SendMessage to the same implementer agent with the Mode B failure log + simulator screenshots attached. Same implementer for context coherence."

### MEDIUM 6 — Test Swift scope clarification

"Test Swift is free" should mean existing UITest source code can change. Adding package dependencies, new target dependencies, scheme changes, or production target linkage requires approval.

**Resolution (v2):** Brief Section 2 ("Architectural contracts — frozen") amended: "Test Swift source code is free to change. Test target dependencies, scheme changes, or new target linkage require architect approval before edit."

### LOW 1-3 — Wording precision

LOW 1: Step 9 reasoning re-worded — `mount_screen` doesn't notify, not "no subscriber exists."
LOW 2: Brief explicitly lists removing the `renderer = UI::UIKit::Renderer.new` local in `initialize_runtime` alongside the class-var pin.
LOW 3: Suppression window confirmed safe — no change needed but referenced.

## What's strong about the brief

The architectural shape, the order discipline in `initialize_runtime`, the mount-before-publish reasoning in §3, the iOS class-init gap discipline, the compat-shim disposition, and the hard rules are all correct. The mid-stop dispatch split is the right pattern for this work.

The risk register is well-formed for what it covers — Codex's adds (R7-R11) from co-plan §3 are integrated. The main weakness was over-specifying without test-discovery rigor (HIGH 2-4) and one stale-code reference (BLOCKER 2).

— Codex (medium reasoning, arg-form prompt)
