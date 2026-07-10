# Phase 8D.3b — 14-Row Capture Matrix + Deterministic Capture Driver (BRIEF v1)

**Date drafted:** 2026-05-25
**Status:** Brief v1 — pending Codex antagonist critique.
**Branch:** `phase-08d.3b-capture-matrix` (to be cut at brief approval).
**Predecessor:** Phase 8D.3a `phase-08d.3a-pass-with-notes-2026-05-25`.
**Planning artifacts:** `scoping-8d.3.md`, `coplan-8d.3-codex-1.md` (covers both 8D.3a + 8D.3b).

---

## 1. Mission

Build a deterministic capture driver that walks Voyager into each of the 14 contract states without depending on XCUITest tap synthesis (blocked by Phase 6.10), then produce **28 iOS captures** (14 × light/dark) and **24 macOS captures** (12 non-swipe rows × light/dark). All artifacts committed to `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/`.

The captures are **visual state proof**, NOT interaction proof. Interaction proof is the deferred Phase 8 collective hand-test gate, per `[[complete-phase-arc-before-review]]`.

## 2. The 14-row visual contract (verbatim from Phase 6.11 brief)

| # | State to capture | iOS artifact | macOS artifact |
|---|---|---|---|
| 1 | Just-launched Sign-in screen | `voyager-row-01-sign-in-{light,dark}.png` | same |
| 2 | After Sign-in tap → Todos with 5 seeded rows | `voyager-row-02-todos-launch-{light,dark}.png` | same |
| 3 | Editor empty (Add Todo) — Save **disabled** | `voyager-row-03-editor-empty-{light,dark}.png` | same |
| 4 | Editor with title typed — Save **enabled** | `voyager-row-04-editor-typed-{light,dark}.png` | same |
| 5 | After Save — new row visible | `voyager-row-05-todos-after-save-{light,dark}.png` | same |
| 6 | Row completed (strikethrough + chart shift) | `voyager-row-06-todos-row-completed-{light,dark}.png` | same |
| 7 | Swipe revealed (Edit + Delete trailing actions) | `voyager-row-07-todos-swipe-revealed-{light,dark}.png` | **iOS-only** |
| 8 | Editor prefilled from swipe-Edit | `voyager-row-08-editor-edit-prefilled-{light,dark}.png` | **iOS-only** |
| 9 | After Edit Save — row updated | `voyager-row-09-todos-after-edit-{light,dark}.png` | same |
| 10 | After Delete — row removed | `voyager-row-10-todos-after-delete-{light,dark}.png` | **iOS-only** (no macOS swipe-delete) |
| 11 | Settings default (Hide-completed off) | `voyager-row-11-settings-default-{light,dark}.png` | same |
| 12 | Settings toggled (Hide-completed on) | `voyager-row-12-settings-toggled-{light,dark}.png` | same |
| 13 | Todos filtered (back from Settings) | `voyager-row-13-todos-filtered-{light,dark}.png` | same |
| 14 | Todos unfiltered (re-toggle + back) | `voyager-row-14-todos-unfiltered-{light,dark}.png` | same |

**Final counts:** 28 iOS (all 14 × light + dark) + 24 macOS (12 non-swipe rows × light + dark, skipping rows 7, 8, 10).

## 3. Capture-driver architecture (Codex co-plan §3 — adopted)

### 3.1 Scenario registry — Voyager sample-local

**New file:** `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr`.

Defines a `Voyager::CaptureScenarios` module with one method per row:

```crystal
module Voyager
  module CaptureScenarios
    # A scenario walks Voyager::State + the NavigationCoordinator + (if
    # needed) transient UI flags into the target visual state, then
    # returns the route_id the host should mount.
    #
    # Each scenario is keyed by a canonical id matching the artifact
    # filename ("row-04-editor-typed"). The iOS bridge / macOS host
    # reads VOYAGER_CAPTURE_SCENARIO and dispatches to the matching
    # method here.
    record Result, route_id : Symbol, route_params : Hash(Symbol, String) = {} of Symbol => String

    def self.apply(scenario_id : String, state : Voyager::State, coord : UI::NavigationCoordinator, dispatcher : UI::ActionDispatcher) : Result
      case scenario_id
      when "row-01-sign-in"           then row_01_sign_in(state, coord, dispatcher)
      when "row-02-todos-launch"      then row_02_todos_launch(state, coord, dispatcher)
      when "row-03-editor-empty"      then row_03_editor_empty(state, coord, dispatcher)
      when "row-04-editor-typed"      then row_04_editor_typed(state, coord, dispatcher)
      when "row-05-todos-after-save"  then row_05_todos_after_save(state, coord, dispatcher)
      # ... etc, 14 total
      else
        raise "Unknown VOYAGER_CAPTURE_SCENARIO: #{scenario_id}"
      end
    end

    # Each method mutates state + coord as needed, may call
    # dispatcher.mount_screen(...) explicitly to seed a FormState with
    # the right values (e.g. row 4 needs title="Rem 6.11 test" in
    # form_state), and returns the Result with route_id to render.
    private def self.row_04_editor_typed(state, coord, dispatcher)
      # Walk: sign in already implicit (no auth gate at state level);
      # ensure todos are seeded (State.new already does); push editor
      # route; seed form_state with the typed title.
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, {todo_id: "0"} of Symbol => String))
      dispatcher.mount_screen(coord.current)
      dispatcher.current_form_state.register("title", "Rem 6.11 test")
      Result.new(route_id: :todo_editor, route_params: {todo_id: "0"} of Symbol => String)
    end

    # Row 7 swipe-revealed needs the SwipeActionRow to be in its
    # revealed state. If SwipeActionRow has no setter for this, the
    # implementer adds a SAMPLE-ONLY transient flag (e.g.
    # Voyager::State#capture_swipe_revealed_id : Int32?) that the
    # screens consult during build and the row checks. This is a
    # capture-only contract; production code paths ignore the flag.
    private def self.row_07_todos_swipe_revealed(state, coord, dispatcher)
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      state.capture_swipe_revealed_id = state.todos.first.id
      Result.new(route_id: :todos)
    end

    # ... other rows.
  end
end
```

### 3.2 iOS bridge integration

`samples/initiative-cross-platform-ui-voyager/ios/bridge.cr` `initialize_runtime` reads `VOYAGER_CAPTURE_SCENARIO` env var after the existing `Voyager::HostBootstrap.build` returns. If set:
- Calls `Voyager::CaptureScenarios.apply(scenario_id, state, coord, dispatcher)`.
- The returned `Result.route_id` overrides whatever route Swift's `VOYAGER_ROOT_SLUG` would otherwise have selected.
- Render happens normally via `render_slug`.

```crystal
# After result = Voyager::HostBootstrap.build(:sign_in):
if scenario = ENV["VOYAGER_CAPTURE_SCENARIO"]?
  apply_result = Voyager::CaptureScenarios.apply(scenario, result.state, result.coord, result.dispatcher)
  # Forward the scenario's chosen slug — Swift's @State will still
  # request voyager-* via VOYAGER_ROOT_SLUG, but the coord has been
  # walked, so render_slug's lookup will use coord.current.id.
  copy_slug_to_buf(Voyager.slug_for_route_id(apply_result.route_id))
else
  copy_slug_to_buf(Voyager.slug_for_route_id(result.coord.current.id))
end
```

The Swift side does NOT change. It still passes `VOYAGER_ROOT_SLUG` into `voyager_render(slug)`. The Crystal side has already walked the coord into the target state; `render_slug`'s post-resync logic just renders `coord.current`.

### 3.3 macOS host integration

`samples/initiative-cross-platform-ui-voyager/macos/host.cr` `run!` reads `VOYAGER_CAPTURE_SCENARIO` similarly. macOS already supports `VOYAGER_SCREENSHOT_PATH` for offscreen capture; combining the two lets a single `crystal-alpha run` invocation produce a single .png.

### 3.4 Capture script — `bin/capture_voyager.sh`

**New file:** `samples/initiative-cross-platform-ui-voyager/bin/capture_voyager.sh`.

Driver script that produces the full matrix:

```bash
#!/usr/bin/env bash
set -euo pipefail

EVIDENCE_DIR="docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence"
mkdir -p "$EVIDENCE_DIR/ios" "$EVIDENCE_DIR/macos"

IOS_SCENARIOS=(
  "row-01-sign-in" "row-02-todos-launch" "row-03-editor-empty"
  "row-04-editor-typed" "row-05-todos-after-save" "row-06-todos-row-completed"
  "row-07-todos-swipe-revealed" "row-08-editor-edit-prefilled" "row-09-todos-after-edit"
  "row-10-todos-after-delete" "row-11-settings-default" "row-12-settings-toggled"
  "row-13-todos-filtered" "row-14-todos-unfiltered"
)
MACOS_SCENARIOS=(
  # Same list minus swipe-only rows 7, 8, 10.
  "row-01-sign-in" "row-02-todos-launch" "row-03-editor-empty"
  "row-04-editor-typed" "row-05-todos-after-save" "row-06-todos-row-completed"
  "row-09-todos-after-edit" "row-11-settings-default" "row-12-settings-toggled"
  "row-13-todos-filtered" "row-14-todos-unfiltered"
)
# Note: row-14 needs to land at "todos unfiltered" — its scenario is
# the same as row-02 (todos with completed rows visible) so we can
# share the file OR generate twice for the contract.

APPEARANCES=("light" "dark")

# --- iOS ---
DEVICE=$(xcrun simctl list devices booted | awk '/iPhone/ {print $NF; exit}' | tr -d '()')
if [ -z "$DEVICE" ]; then
  DEVICE=$(xcrun simctl list devices available | awk '/iPhone 17 Pro/ {print $NF; exit}' | tr -d '()')
  [ -z "$DEVICE" ] && DEVICE=$(xcrun simctl list devices available | awk '/iPhone/ {print $NF; exit}' | tr -d '()')
  xcrun simctl boot "$DEVICE"
fi

APP_PATH=$(ls -d ~/Library/Developer/Xcode/DerivedData/VoyagerDemo-*/Build/Products/Debug-iphonesimulator/VoyagerDemo.app | head -1)
xcrun simctl install "$DEVICE" "$APP_PATH"

for scenario in "${IOS_SCENARIOS[@]}"; do
  for appearance in "${APPEARANCES[@]}"; do
    xcrun simctl ui "$DEVICE" appearance "$appearance"
    xcrun simctl terminate "$DEVICE" com.assetpipeline.voyager.VoyagerDemo || true
    xcrun simctl launch \
      --terminate-running-process \
      --setenv VOYAGER_CAPTURE_SCENARIO="$scenario" \
      --setenv VOYAGER_APPEARANCE="$appearance" \
      "$DEVICE" com.assetpipeline.voyager.VoyagerDemo
    sleep 1.5  # let SwiftUI settle + Crystal render
    xcrun simctl io "$DEVICE" screenshot "$EVIDENCE_DIR/ios/voyager-$scenario-$appearance.png"
  done
done

# --- macOS ---
make -C samples/initiative-cross-platform-ui-voyager macos
VOYAGER_BIN=samples/initiative-cross-platform-ui-voyager/macos/build/voyager-host
for scenario in "${MACOS_SCENARIOS[@]}"; do
  for appearance in "${APPEARANCES[@]}"; do
    VOYAGER_CAPTURE_SCENARIO="$scenario" \
    VOYAGER_APPEARANCE="$appearance" \
    VOYAGER_SCREENSHOT_PATH="$EVIDENCE_DIR/macos/voyager-$scenario-$appearance.png" \
      "$VOYAGER_BIN"
  done
done

echo "Captures complete:"
ls -1 "$EVIDENCE_DIR/ios" | wc -l
ls -1 "$EVIDENCE_DIR/macos" | wc -l
```

## 4. Item-by-item scope

### Item 1 — `Voyager::CaptureScenarios` module
New file `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr`. 14 scenario methods. Sample-only — not a framework API. Required by `samples/initiative-cross-platform-ui-voyager/app.cr` only when present (gated under existence check).

### Item 2 — `Voyager::State#capture_swipe_revealed_id` (sample-local flag)
Add to `samples/initiative-cross-platform-ui-voyager/screens/state.cr`:
```crystal
# Phase 8D.3b — capture-only: when set, the matching SwipeActionRow
# renders in its "trailing actions revealed" state for screenshot
# purposes. Production code paths leave this nil.
property capture_swipe_revealed_id : Int32? = nil
```

### Item 3 — `Voyager::TodosScreen` SwipeActionRow consults the flag
Update `samples/initiative-cross-platform-ui-voyager/screens/todos.cr` to set the SwipeActionRow's revealed-state when `state.capture_swipe_revealed_id == todo.id`. If `UI::SwipeActionRow` exposes a setter for this (e.g. `force_revealed = true`), use it. If not, add a sample-only renderer hint via test_id suffix that the implementer documents — DON'T modify `UI::SwipeActionRow` API.

### Item 4 — Bridge integration (iOS + macOS)
- iOS: `bridge.cr` `initialize_runtime` reads `VOYAGER_CAPTURE_SCENARIO` after `HostBootstrap.build` returns; calls `CaptureScenarios.apply` if set.
- macOS: `host.cr` `run!` does the same.

### Item 5 — Capture script
`samples/initiative-cross-platform-ui-voyager/bin/capture_voyager.sh` executable. Drives the full matrix per §3.4.

### Item 6 — Run the matrix + commit artifacts
- Run the capture script.
- Verify all 28 iOS + 24 macOS PNGs exist + have non-trivial file sizes (>10kB each).
- Commit to `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/`.

### Item 7 — Artifact mapping table
`docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/README.md` with the table from §2 + actual file paths + brief note explaining "visual state proof, not interaction proof; interaction proof is in Phase 8 collective hand-test."

### Item 8 — Codex per-iteration review
Standard pattern. Output to `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-codex-N.md`.

## 5. Acceptance criteria

- [ ] `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr` exists with 14 scenario methods.
- [ ] `Voyager::State#capture_swipe_revealed_id` property added; production paths unaffected.
- [ ] `Voyager::TodosScreen` consults the flag for swipe-revealed rendering.
- [ ] iOS `bridge.cr` + macOS `host.cr` read `VOYAGER_CAPTURE_SCENARIO` + dispatch.
- [ ] `bin/capture_voyager.sh` executable + produces the full matrix in one invocation.
- [ ] **28 iOS PNGs** committed under `phase-08d.3b-evidence/ios/`.
- [ ] **24 macOS PNGs** committed under `phase-08d.3b-evidence/macos/`.
- [ ] README.md with the artifact mapping table committed.
- [ ] `crystal spec` baseline unchanged (no new failures; scenario module is sample-only, no framework impact).
- [ ] iOS + macOS builds succeed.
- [ ] Codex review APPROVE or APPROVE_WITH_NOTES.

## 6. Risk register

- **R1** — `UI::SwipeActionRow` has no force-revealed setter. *Mitigation:* Item 3 documents the sample-only workaround. If no clean path exists, mark row 7 as "iOS-not-currently-capturable" + write a one-line README note. NO API change to `UI::SwipeActionRow`.
- **R2** — Scenario walking modifies dispatcher state in ways that break the on_change subscriber. *Mitigation:* the scenario runs BEFORE the on_change subscriber is registered? No — looking at bridge.cr, on_change is registered inside HostBootstrap.build's mount_screen call OR after the result returns. Implementer verifies and adjusts order if needed.
- **R3** — `xcrun simctl launch --setenv` doesn't actually forward env vars to the running app. *Mitigation:* verify with a single scenario before running the full matrix. If broken, use `xcrun simctl spawn ... env VAR=val` or write env vars to a known file the app reads.
- **R4** — Light/dark switch takes time on the simulator. *Mitigation:* the script's 1.5s sleep covers most cases; implementer extends if captures show wrong appearance.
- **R5** — macOS scenarios + offscreen capture path don't compose. *Mitigation:* macOS already supports `VOYAGER_SCREENSHOT_PATH`; the scenario apply happens before render. Should compose. Implementer verifies on row-01 first.
- **R6** — Row 14 is identical to row 02 (Todos unfiltered). *Mitigation:* still generate the capture for contract completeness; README notes the equivalence.
- **R7** — Mid-stop pattern at capture work. *Mitigation:* the script is fully scripted — no manual interaction needed. Implementer ships the script + runs it end-to-end. If it stalls, the script's exit code reveals where.

## 7. Implementation order

1. Item 1: `capture_scenarios.cr` skeleton + first 3 scenarios (sign-in, todos-launch, editor-empty).
2. Item 4: iOS bridge integration — wire `VOYAGER_CAPTURE_SCENARIO`. macOS host integration.
3. Test loop: build iOS + macOS, run a single iOS capture (e.g. `xcrun simctl launch --setenv VOYAGER_CAPTURE_SCENARIO=row-01-sign-in ...`) → screenshot → verify content.
4. Items 1 + 2 + 3: complete the remaining 11 scenarios; add the swipe-revealed flag; wire TodosScreen.
5. Item 5: capture script.
6. Item 6: run the full matrix.
7. Item 7: README.
8. Item 8: Codex review.

## 8. Validation invocations

- `crystal spec` — baseline; no failures introduced.
- iOS build: `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild ... build`.
- macOS build: `make -C samples/initiative-cross-platform-ui-voyager macos`.
- Single-scenario smoke (iOS): `xcrun simctl launch --setenv VOYAGER_CAPTURE_SCENARIO=row-04-editor-typed --setenv VOYAGER_APPEARANCE=light "$DEVICE" com.assetpipeline.voyager.VoyagerDemo`.
- Single-scenario smoke (macOS): `VOYAGER_CAPTURE_SCENARIO=row-04-editor-typed VOYAGER_APPEARANCE=light VOYAGER_SCREENSHOT_PATH=/tmp/test.png ./voyager-host`.
- Full matrix: `samples/initiative-cross-platform-ui-voyager/bin/capture_voyager.sh`.

## 9. Hard rules

- Forward commits only on `phase-08d.3b-capture-matrix`.
- NO framework API changes. `UI::SwipeActionRow`, `UI::Button`, `UI::FormState`, `UI::TextField`, etc. all unchanged.
- NO C ABI changes to `bridge.cr`.
- NO Swift production code edits.
- Capture scenarios are SAMPLE-LOCAL — not part of any framework module.
- Codex review per iteration.
- Standard Claude co-author footer.

— Architect (Claude Opus 4.7)
