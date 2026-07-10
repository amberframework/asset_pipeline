# Phase 8D.3b — 14-Row Capture Matrix + Deterministic Capture Driver (BRIEF v2 — DISPATCH-READY)

**Date drafted:** 2026-05-25
**Status:** Brief v2 — addresses 16 Codex antagonist findings (4 BLOCKER + 5 HIGH + 4 MEDIUM + 3 LOW). Pending owner approval.
**Branch:** `phase-08d.3b-capture-matrix`.
**Predecessor:** `phase-08d.3a-pass-with-notes-2026-05-25`.
**Planning artifacts:** `scoping-8d.3.md`, `coplan-8d.3-codex-1.md`, `brief-8d.3b.v1.md`, `codex-critique-1-brief-8d.3b.md`.

---

## 1. Mission

Build a deterministic capture driver that walks Voyager into each of the 14 contract states using:
- Crystal-side **scenarios** that mutate `Voyager::State` + `NavigationCoordinator` + `ActionDispatcher` into the target visual state.
- An iOS-side **XCUITest** test method that loops scenarios × appearances, launches the app with `launchEnvironment` carrying `VOYAGER_CAPTURE_SCENARIO` + `VOYAGER_ROOT_SLUG` + `VOYAGER_APPEARANCE`, polls for a known AX element, screenshots, and writes to disk.
- A macOS-side **shell loop** using the existing `VOYAGER_SCREENSHOT_PATH` offscreen capture, with `VOYAGER_CAPTURE_SCENARIO` + `HIG_APPEARANCE` env vars.

Capture matrix: **28 iOS + 28 macOS = 56 captures.** All artifacts under `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/`.

Captures are **visual state proof**, NOT interaction proof. Interaction proof is the deferred Phase 8 collective hand-test gate, per `[[complete-phase-arc-before-review]]`.

## 2. The 14-row visual contract

| # | State to capture | iOS slug needed | iOS capturable? | macOS capturable? |
|---|---|---|---|---|
| 1 | Just-launched Sign-in screen | voyager-sign-in | yes | yes |
| 2 | After Sign-in → Todos (5 seeded rows) | voyager-todos | yes | yes |
| 3 | Editor empty (Add Todo, Save disabled) | voyager-todo-editor | yes | yes |
| 4 | Editor prefilled with "Rem 6.11 test" (Save enabled) | voyager-todo-editor | yes | yes |
| 5 | After Save — Todos with that row visible | voyager-todos | yes | yes |
| 6 | Row completed (strikethrough + chart shifted) | voyager-todos | yes | yes |
| 7 | Swipe revealed (Edit + Delete actions) | voyager-todos | **see HIGH 3** | yes (AppKit native trailing buttons) |
| 8 | Editor prefilled from swipe-Edit | voyager-todo-editor | yes | yes |
| 9 | After Edit Save — row updated | voyager-todos | yes | yes |
| 10 | After Delete — row removed | voyager-todos | yes | yes |
| 11 | Settings default (Hide-completed off) | voyager-settings | yes | yes |
| 12 | Settings toggled (Hide-completed on) | voyager-settings | yes | yes |
| 13 | Todos filtered (back from Settings) | voyager-todos | yes | yes |
| 14 | Todos unfiltered (re-toggle + back) | voyager-todos | yes | yes |

**Row 7 iOS caveat:** the current `UI::SwipeActionRow` UIKit rendering has no static "trailing actions revealed" state. The iOS row-7 capture ships with the row AT REST (closed), and the README documents the gesture-only nature. macOS row-7 captures the natural AppKit inline trailing buttons (already in the renderer per `src/ui/renderers/appkit_renderer.cr:3801`).

**Final counts:** 28 iOS PNGs (14 × light/dark) + 28 macOS PNGs (14 × light/dark) = 56 total.

## 3. Architecture

### 3.1 Scenario architecture (Codex BLOCKER 2 resolution)

**Scenarios walk into existing-state visual representations.** They do NOT simulate user typing. The Editor screen renders `title_field.text = seed_title` where `seed_title = editing ? editing.title : ""` (`todo_editor.cr:38,66`). Calling `FormState.register("title", "...")` populates the form registry but does NOT change rendered text.

So row 4 ("Editor with title typed") is reframed as **"Editor opened on a pre-existing todo with title 'Rem 6.11 test'"**:
- Scenario seeds an extra todo at construction with `title: "Rem 6.11 test"`.
- Scenario pushes `Route.new(:todo_editor, {todo_id: "<that_id>"})`.
- Screen renders with `seed_title == "Rem 6.11 test"` → title field has visible text + Save enabled (from `:120`).

This same reframe covers rows 5, 8, 9.

### 3.2 Slug-and-coord alignment (Codex BLOCKER 1 resolution)

`render_slug`'s depth-1 resync (`bridge.cr:217`) replaces coord.current with the slug Swift requested, UNDOING the scenario's coord walk if they disagree.

**Resolution:** capture driver sets BOTH `VOYAGER_CAPTURE_SCENARIO` AND `VOYAGER_ROOT_SLUG` matching the scenario's expected final route. Scenario walks coord to a state where `coord.current.id` matches the slug Swift will request. Depth-1 resync becomes a no-op (current.id == route.id) → scenario walk is preserved.

For multi-depth scenarios (e.g. row 8 = `[todos, todo_editor]`), scenario uses `coord.replace_root(:todos)` + `coord.push(:todo_editor, params)`. Final depth is 2; depth-1 resync only fires at depth 1.

### 3.3 Scenario registry — sample-local Crystal module

**New file:** `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr`.

**Require:** add `require "./capture_scenarios"` to `samples/initiative-cross-platform-ui-voyager/app.cr` after the existing screens/controllers requires (Codex MEDIUM 2).

```crystal
module Voyager
  module CaptureScenarios
    record Result, route_id : Symbol

    SCENARIO_TO_SLUG = {
      "row-01-sign-in"             => "voyager-sign-in",
      "row-02-todos-launch"        => "voyager-todos",
      "row-03-editor-empty"        => "voyager-todo-editor",
      "row-04-editor-prefilled"    => "voyager-todo-editor",
      "row-05-todos-after-save"    => "voyager-todos",
      "row-06-todos-row-completed" => "voyager-todos",
      "row-07-todos-swipe-row"     => "voyager-todos",
      "row-08-editor-edit-prefilled" => "voyager-todo-editor",
      "row-09-todos-after-edit"    => "voyager-todos",
      "row-10-todos-after-delete"  => "voyager-todos",
      "row-11-settings-default"    => "voyager-settings",
      "row-12-settings-toggled"    => "voyager-settings",
      "row-13-todos-filtered"      => "voyager-todos",
      "row-14-todos-unfiltered"    => "voyager-todos",
    }

    # Apply the scenario named by VOYAGER_CAPTURE_SCENARIO. Mutates
    # state + coord + dispatcher into the visual end state. The
    # scenario's LAST call MUST be dispatcher.mount_screen(coord.current)
    # per Codex HIGH 1 — guarantees current_form_state matches the
    # final route's params.
    def self.apply(scenario_id : String, state : Voyager::State, coord : UI::NavigationCoordinator, dispatcher : UI::ActionDispatcher) : Result
      case scenario_id
      when "row-01-sign-in"             then row_01(state, coord, dispatcher)
      when "row-02-todos-launch"        then row_02(state, coord, dispatcher)
      when "row-03-editor-empty"        then row_03(state, coord, dispatcher)
      when "row-04-editor-prefilled"    then row_04(state, coord, dispatcher)
      when "row-05-todos-after-save"    then row_05(state, coord, dispatcher)
      when "row-06-todos-row-completed" then row_06(state, coord, dispatcher)
      when "row-07-todos-swipe-row"     then row_07(state, coord, dispatcher)
      when "row-08-editor-edit-prefilled" then row_08(state, coord, dispatcher)
      when "row-09-todos-after-edit"    then row_09(state, coord, dispatcher)
      when "row-10-todos-after-delete"  then row_10(state, coord, dispatcher)
      when "row-11-settings-default"    then row_11(state, coord, dispatcher)
      when "row-12-settings-toggled"    then row_12(state, coord, dispatcher)
      when "row-13-todos-filtered"      then row_13(state, coord, dispatcher)
      when "row-14-todos-unfiltered"    then row_14(state, coord, dispatcher)
      else
        raise "Unknown VOYAGER_CAPTURE_SCENARIO: #{scenario_id.inspect}"
      end
    end

    # Implementer authors all 14 method bodies per the contract in §3.4.
    # Examples:

    private def self.row_01(state, coord, dispatcher) : Result
      coord.replace_root(UI::NavigationCoordinator::Route.new(:sign_in))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :sign_in)
    end

    private def self.row_04(state, coord, dispatcher) : Result
      # Reframe: editor opened on pre-existing todo with the contract
      # title. Ensure a todo with that title exists; push editor route
      # with its id.
      todo = state.add_todo("Rem 6.11 test")
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      coord.push(UI::NavigationCoordinator::Route.new(:todo_editor, {todo_id: todo.id.to_s} of Symbol => String))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todo_editor)
    end

    private def self.row_12(state, coord, dispatcher) : Result
      state.hide_completed = true
      coord.replace_root(UI::NavigationCoordinator::Route.new(:settings))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :settings)
    end

    private def self.row_13(state, coord, dispatcher) : Result
      state.hide_completed = true
      coord.replace_root(UI::NavigationCoordinator::Route.new(:todos))
      dispatcher.mount_screen(coord.current)
      Result.new(route_id: :todos)
    end

    # ... etc for all 14.
  end
end
```

### 3.4 Per-row scenario walk contracts (REFERENCE — implementer follows)

| Row | State setup | Coord walk | Notes |
|---|---|---|---|
| 01 | default seeded | replace_root(:sign_in) | trivial |
| 02 | default seeded | replace_root(:todos) | 5 seed rows visible |
| 03 | default seeded | replace_root(:todos) → push(:todo_editor, {todo_id: "0"}) | depth 2; new-todo path; seed_title="" |
| 04 | add "Rem 6.11 test" todo | replace_root(:todos) → push(:todo_editor, {todo_id: <id>}) | depth 2; editor prefilled |
| 05 | add "Rem 6.11 test" todo | replace_root(:todos) | depth 1; that row visible in list |
| 06 | mark seeded row #0 completed | replace_root(:todos) | strikethrough + chart shift |
| 07 | default seeded | replace_root(:todos) | iOS captures at-rest (gesture limitation); macOS captures inline trailing buttons |
| 08 | default seeded | replace_root(:todos) → push(:todo_editor, {todo_id: "<seed_id>"}) | depth 2; editor prefilled with existing seed |
| 09 | mutate seed todo #0 title to "Walk the dog updated" | replace_root(:todos) | depth 1; that row's title is updated |
| 10 | delete_todo(seed #0) | replace_root(:todos) | depth 1; 4 rows visible (not 5) |
| 11 | default seeded | replace_root(:settings) | hide_completed=false |
| 12 | hide_completed=true | replace_root(:settings) | toggle ON |
| 13 | hide_completed=true | replace_root(:todos) | filtered list |
| 14 | default seeded (hide_completed=false) | replace_root(:todos) | unfiltered (visually identical to row 02; ship as distinct artifact per MEDIUM 3) |

### 3.5 iOS bridge integration

`bridge.cr` `initialize_runtime` after `HostBootstrap.build` returns:

```crystal
# After: result = Voyager::HostBootstrap.build(:sign_in)
if scenario = ENV["VOYAGER_CAPTURE_SCENARIO"]?
  Voyager::CaptureScenarios.apply(scenario, result.state, result.coord, result.dispatcher)
end

# Seed slug buf from the (possibly walked) coord.current.
copy_slug_to_buf(Voyager.slug_for_route_id(result.coord.current.id))
```

### 3.6 macOS host integration

`host.cr` `run!` after `dispatcher = UI::ActionDispatcher.new(...)` + `dispatcher.mount_screen(coord.current)`:

```crystal
if scenario = ENV["VOYAGER_CAPTURE_SCENARIO"]?
  Voyager::CaptureScenarios.apply(scenario, Voyager.state, coord, dispatcher)
end
```

The host then proceeds with the existing offscreen capture path (`VOYAGER_SCREENSHOT_PATH` branch). Set `HIG_APPEARANCE` per Codex MEDIUM 1 so token-resolved colors honor dark mode.

### 3.7 Capture driver — XCUITest method (Codex HIGH 5 resolution)

**New test method** in `samples/initiative-cross-platform-ui-voyager/ios/UITests/VoyagerVisualTests.swift`:

```swift
/// Phase 8D.3b — 14-row capture matrix. Loops scenarios × appearances,
/// launches the app with VOYAGER_CAPTURE_SCENARIO + matching
/// VOYAGER_ROOT_SLUG + VOYAGER_APPEARANCE via app.launchEnvironment
/// (the proven-working pattern from earlier iter tests), polls for a
/// scenario-specific AX element, captures via XCUIScreen, writes to
/// disk under the evidence directory.
///
/// Each scenario's expected AX element comes from a switch keyed on
/// the scenario id — see scenarioAXIdentifier(_:) below. The poll
/// uses waitForExistence(timeout: 12) to handle SwiftUI / Crystal
/// startup variance.
func testCaptureMatrix() throws {
    let evidenceDir = ProcessInfo.processInfo.environment["VOYAGER_CAPTURE_EVIDENCE_DIR"]
        ?? FileManager.default.currentDirectoryPath + "/voyager-captures"
    do {
        try FileManager.default.createDirectory(atPath: evidenceDir,
                                                withIntermediateDirectories: true)
    } catch {
        XCTFail("Failed to create evidence dir \(evidenceDir): \(error)")
        return
    }

    let scenarios: [(id: String, slug: String, axHint: String)] = [
        ("row-01-sign-in",             "voyager-sign-in",     "Sign in"),
        ("row-02-todos-launch",        "voyager-todos",       "voyager-todos-add"),
        ("row-03-editor-empty",        "voyager-todo-editor", "voyager-todo-editor-save"),
        ("row-04-editor-prefilled",    "voyager-todo-editor", "voyager-todo-editor-save"),
        ("row-05-todos-after-save",    "voyager-todos",       "voyager-todos-add"),
        ("row-06-todos-row-completed", "voyager-todos",       "voyager-todos-add"),
        ("row-07-todos-swipe-row",     "voyager-todos",       "voyager-todos-add"),
        ("row-08-editor-edit-prefilled","voyager-todo-editor","voyager-todo-editor-save"),
        ("row-09-todos-after-edit",    "voyager-todos",       "voyager-todos-add"),
        ("row-10-todos-after-delete",  "voyager-todos",       "voyager-todos-add"),
        ("row-11-settings-default",    "voyager-settings",    "voyager-settings-hide-completed"),
        ("row-12-settings-toggled",    "voyager-settings",    "voyager-settings-hide-completed"),
        ("row-13-todos-filtered",      "voyager-todos",       "voyager-todos-add"),
        ("row-14-todos-unfiltered",    "voyager-todos",       "voyager-todos-add"),
    ]

    for scenario in scenarios {
        for appearance in ["light", "dark"] {
            let app = XCUIApplication()
            app.launchEnvironment = [
                "VOYAGER_CAPTURE_SCENARIO": scenario.id,
                "VOYAGER_ROOT_SLUG":        scenario.slug,
                "VOYAGER_APPEARANCE":       appearance,
            ]
            app.launch()

            // Poll for either an element with the AX identifier
            // matching axHint OR a button with that label.
            let identifierMatch = app.descendants(matching: .any)[scenario.axHint]
            let buttonMatch     = app.buttons[scenario.axHint]
            let found = identifierMatch.waitForExistence(timeout: 12)
                     || buttonMatch.waitForExistence(timeout: 2)
            XCTAssertTrue(found,
                "Scenario \(scenario.id) (\(appearance)) failed to reach \(scenario.axHint)")

            // Brief settle then capture.
            Thread.sleep(forTimeInterval: 0.6)
            let snapshot = XCUIScreen.main.screenshot()
            let pngData = snapshot.pngRepresentation
            let outPath = "\(evidenceDir)/voyager-\(scenario.id)-\(appearance).png"
            let outUrl = URL(fileURLWithPath: outPath)
            do {
                try pngData.write(to: outUrl, options: .atomic)
            } catch {
                XCTFail("Failed to write \(outPath): \(error)")
            }
            // Sanity-check: assert non-trivial file size so we catch
            // empty/zero-byte writes that would silently pass.
            let attrs = (try? FileManager.default.attributesOfItem(atPath: outPath)) ?? [:]
            let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
            XCTAssertGreaterThan(size, 10_000,
                "PNG for scenario \(scenario.id) (\(appearance)) is \(size) bytes; expected > 10KB.")

            app.terminate()
        }
    }
}
```

### 3.8 macOS capture loop — shell driver

**New file:** `samples/initiative-cross-platform-ui-voyager/bin/capture_voyager_macos.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

EVIDENCE_DIR="docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/macos"
mkdir -p "$EVIDENCE_DIR"

# Build the macOS binary if not already.
make -C samples/initiative-cross-platform-ui-voyager macos
VOYAGER_BIN="samples/initiative-cross-platform-ui-voyager/macos/bin/voyager"

SCENARIOS=(
  "row-01-sign-in" "row-02-todos-launch" "row-03-editor-empty"
  "row-04-editor-prefilled" "row-05-todos-after-save" "row-06-todos-row-completed"
  "row-07-todos-swipe-row" "row-08-editor-edit-prefilled" "row-09-todos-after-edit"
  "row-10-todos-after-delete" "row-11-settings-default" "row-12-settings-toggled"
  "row-13-todos-filtered" "row-14-todos-unfiltered"
)

for scenario in "${SCENARIOS[@]}"; do
  for appearance in light dark; do
    VOYAGER_CAPTURE_SCENARIO="$scenario" \
    VOYAGER_APPEARANCE="$appearance" \
    HIG_APPEARANCE="$appearance" \
    VOYAGER_SCREENSHOT_PATH="$EVIDENCE_DIR/voyager-$scenario-$appearance.png" \
      "$VOYAGER_BIN"
  done
done

echo "macOS captures: $(ls -1 $EVIDENCE_DIR/*.png | wc -l) (expected: 28)"
```

### 3.9 iOS capture invocation

```bash
# Build VoyagerDemo first (from prior phases).
cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator
xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run the capture-matrix test method. Specify the evidence dir via env.
VOYAGER_CAPTURE_EVIDENCE_DIR="$(pwd)/../../../docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/ios" \
  xcodebuild -project VoyagerDemo.xcodeproj -scheme VoyagerDemo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testCaptureMatrix
```

Note: `VOYAGER_CAPTURE_EVIDENCE_DIR` is read by the test method via `ProcessInfo.processInfo.environment` — that env var IS visible to the test runner (in test target context). Files are written via FileManager.

## 4. Item-by-item scope

### Item 1 — `Voyager::CaptureScenarios` module
New file. 14 scenario methods per §3.4. Required in `app.cr`.

### Item 2 — iOS bridge integration
`bridge.cr` reads `VOYAGER_CAPTURE_SCENARIO` after `HostBootstrap.build`; calls `CaptureScenarios.apply`. Slug buf seeded from coord.current.id (which the scenario may have walked).

### Item 3 — macOS host integration
`host.cr` reads `VOYAGER_CAPTURE_SCENARIO` after dispatcher construction; calls `CaptureScenarios.apply`. Sets `HIG_APPEARANCE` flow.

### Item 4 — `testCaptureMatrix` XCUITest method
New test in `VoyagerVisualTests.swift`. Loops scenarios × appearances. Writes PNGs to `VOYAGER_CAPTURE_EVIDENCE_DIR`.

### Item 5 — macOS capture shell loop
New file `bin/capture_voyager_macos.sh`.

### Item 6 — Run the full matrix; commit artifacts
- Run iOS capture test → 28 PNGs.
- Run macOS shell loop → 28 PNGs.
- Verify all 56 files exist + > 10KB each.
- Commit under `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/{ios,macos}/`.

### Item 7 — Artifact README + 14-row mapping
`docs/initiative-cross-platform-ui/handoff/phase-08d.3b-evidence/README.md`:
- 14-row contract table with iOS + macOS paths.
- Note: visual state proof; interaction proof = Phase 8 collective hand-test.
- Row 7 iOS caveat (gesture-only state; ships at-rest).
- Row 14 distinct-artifact-but-visually-identical-to-row-02 note.

### Item 8 — Codex per-iteration review
Standard pattern. Output to `docs/initiative-cross-platform-ui/handoff/phase-08d.3b-codex-N.md`.

## 5. Acceptance criteria

- [ ] `samples/initiative-cross-platform-ui-voyager/capture_scenarios.cr` exists with 14 scenarios + SCENARIO_TO_SLUG map.
- [ ] `samples/initiative-cross-platform-ui-voyager/app.cr` requires `./capture_scenarios`.
- [ ] iOS `bridge.cr` reads `VOYAGER_CAPTURE_SCENARIO` + applies after HostBootstrap.
- [ ] macOS `host.cr` reads `VOYAGER_CAPTURE_SCENARIO` + applies after dispatcher construction.
- [ ] `testCaptureMatrix` in `VoyagerVisualTests.swift` exists + writes 28 PNGs to VOYAGER_CAPTURE_EVIDENCE_DIR.
- [ ] `bin/capture_voyager_macos.sh` executable; produces 28 macOS PNGs in one invocation.
- [ ] **56 PNGs total** committed under `phase-08d.3b-evidence/{ios,macos}/`, all > 10KB.
- [ ] README mapping table committed.
- [ ] `crystal spec` baseline unchanged.
- [ ] iOS + macOS builds succeed.
- [ ] Codex review APPROVE or APPROVE_WITH_NOTES.

## 6. Risk register

- **R1** — `UI::SwipeActionRow` has no force-revealed setter; iOS row-7 ships at-rest with README caveat. *Resolved as documented limitation per Codex HIGH 3.*
- **R2** — Scenario walking sequence — `mount_screen` MUST be the last call after all coord mutations. *Resolved by §3.3 + scenario API contract.*
- **R3** — `app.launchEnvironment` from XCUITest is the proven pattern (replaces v1's unverified `simctl --setenv`). *Codex HIGH 5 resolved.*
- **R4** — macOS renderer reads `HIG_APPEARANCE` not `VOYAGER_APPEARANCE` — script sets both. *Codex MEDIUM 1 resolved.*
- **R5** — `crystal spec` must still pass; the scenarios module is sample-local, no framework changes. *No regression risk.*
- **R6** — iOS first-launch class-init: each XCUITest scenario launch is a fresh process; `voyager_init` runs every time. *Should be fine; implementer verifies no SIGSEGV by running row-01 first.*
- **R7** — Row 14 distinct from row 02 (visually identical, separate file). *Codex MEDIUM 3 resolved.*
- **R8** — `Voyager.state` lazy-allocates if scenario runs BEFORE host assigns it (macOS host assigns inside HostBootstrap or directly). *Both hosts assign via HostBootstrap.build → no race.*

## 7. Implementation order

1. Item 1: `capture_scenarios.cr` with rows 01, 02, 03 (representative shapes — depth-1 sign-in, depth-1 todos, depth-2 editor-new).
2. Item 2: iOS bridge integration. Run a single scenario (row-01) via the XCUITest method (just one scenario; comment out the rest of the loop). Verify the screenshot looks right.
3. Item 3: macOS host integration. Run row-01 via the shell loop. Verify the PNG.
4. Items 1 + 2 + 3 expanded: author the remaining 11 scenarios.
5. Item 4: complete `testCaptureMatrix` with full scenario loop.
6. Item 5: complete macOS shell script.
7. Item 6: run the full matrix.
8. Item 7: README.
9. Item 8: Codex review.

## 8. Validation invocations

- `crystal spec` — baseline; no failures introduced.
- iOS build: `cd samples/initiative-cross-platform-ui-voyager/ios && ./build_crystal_lib.sh simulator && xcodebuild ... build`.
- macOS build: `make -C samples/initiative-cross-platform-ui-voyager macos`.
- Single-scenario iOS smoke: comment out all but row-01 in `testCaptureMatrix`, run via `xcodebuild test -only-testing:.../testCaptureMatrix`; verify the PNG.
- Single-scenario macOS smoke: `VOYAGER_CAPTURE_SCENARIO=row-01-sign-in VOYAGER_APPEARANCE=light HIG_APPEARANCE=light VOYAGER_SCREENSHOT_PATH=/tmp/test.png samples/initiative-cross-platform-ui-voyager/macos/bin/voyager`.
- Full iOS matrix: `xcodebuild test -only-testing:VoyagerDemoUITests/VoyagerVisualTests/testCaptureMatrix` with `VOYAGER_CAPTURE_EVIDENCE_DIR` set.
- Full macOS matrix: `samples/initiative-cross-platform-ui-voyager/bin/capture_voyager_macos.sh`.

## 9. Hard rules

- Forward commits only on `phase-08d.3b-capture-matrix`.
- NO framework API changes. `UI::SwipeActionRow`, `UI::Button`, `UI::FormState`, `UI::TextField`, etc. all unchanged.
- NO C ABI changes to `bridge.cr`.
- NO Swift PRODUCTION code changes (`VoyagerBridge.swift`, `ContentView.swift`, `VoyagerApp.swift`). Test Swift (`VoyagerVisualTests.swift`) is free.
- Capture scenarios are SAMPLE-LOCAL — not part of any framework module.
- Codex review per iteration.
- Standard Claude co-author footer.

— Architect (Claude Opus 4.7)
