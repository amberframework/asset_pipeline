# GATE_REPORT Schema

The validator returns a single JSON document conforming to this schema. The team lead archives it under `handoff/phase-{NN}-{passed|failing-{N}}-{YYYY-MM-DD}.md` (wrapped in a markdown code fence).

---

## Schema

```jsonc
{
  // Phase number, 1-based, matches the folder prefix
  "phase": 1,

  // Phase name, exact match with MASTER_PLAN.md
  "phase_name": "Design Token Foundation",

  // ISO date of the validator run
  "validator_run_date": "2026-05-21",

  // Iteration number (1 for first validation, 2 for first remediation, etc.)
  "iteration": 1,

  // Commit hashes the implementer reported (verify they exist)
  "implementer_commits": ["abc1234", "def5678"],

  // PASS | FAIL — derived from `checks` array
  "verdict": "PASS",

  // Array of every check in validation.md, in the order they appear there
  "checks": [
    {
      // Stable identifier from validation.md, used to correlate across iterations
      "check_id": "tokens.types-defined",

      // From validation.md: is this a required check or optional?
      "required": true,

      // Did the check pass?
      "passed": true,

      // Was the check unable to run? (missing env, tool failure, etc.)
      "blocked": false,

      // Paths (relative to evidence directory) where evidence lives
      "evidence": [
        "test_output/tokens.types-defined.log"
      ],

      // Mandatory free-text. For passes: one line confirming what was seen.
      // For failures: what was expected, what was seen, where the gap is.
      "notes": "All five token categories defined as Crystal types with frozen instances."
    }
    // ... one entry per check in validation.md
  ],

  // 2–4 sentence prose summary
  "summary": "11 of 12 required checks pass. One failure in token cascade to web renderer for Button widget."
}
```

---

## Verdict computation

```
verdict = "PASS"  if  every check where required == true has passed == true
verdict = "FAIL"  otherwise
```

`blocked: true` is treated as `passed: false` for verdict purposes.

Optional checks (`required: false`) never affect the verdict. They are recorded so the team lead can see what's working beyond the minimum bar.

---

## Required fields

Every check object must have:

- `check_id` (string, matches validation.md)
- `required` (boolean)
- `passed` (boolean)
- `blocked` (boolean)
- `evidence` (array of strings, may be empty if the check is purely inspection-based)
- `notes` (string, non-empty)

The top-level object must have:

- `phase`, `phase_name`, `validator_run_date`, `iteration`, `implementer_commits`, `verdict`, `checks`, `summary`

---

## Constraints

- `checks` array length and order must match `validation.md` exactly. A check from `validation.md` that the validator did not run is a protocol violation; in that case mark `blocked: true` with a `notes` explanation.
- Evidence paths are relative to the evidence directory for this run. The team lead's archive process preserves the directory.
- `notes` must be human-readable. JSON in `notes` is allowed if it's the most precise way to express the finding, but plain English is preferred.

---

## Example: a failing report

```json
{
  "phase": 3,
  "phase_name": "SwiftUI Native Bridge",
  "validator_run_date": "2026-06-04",
  "iteration": 1,
  "implementer_commits": ["1a2b3c4", "5d6e7f8", "9012345"],
  "verdict": "FAIL",
  "checks": [
    {
      "check_id": "swiftui.button-default-renders",
      "required": true,
      "passed": true,
      "blocked": false,
      "evidence": ["screenshots/swiftui.button-default-renders-ios-light.png", "screenshots/swiftui.button-default-renders-ios-dark.png"],
      "notes": "Default Button on iOS renders as SwiftUI Button (system blue, system font, default insets). Matches reference screenshot."
    },
    {
      "check_id": "swiftui.button-background-override",
      "required": true,
      "passed": false,
      "blocked": false,
      "evidence": ["screenshots/swiftui.button-background-override-ios-light.png", "test_output/swiftui.button-background-override.log"],
      "notes": "Setting view.background_color = Color.red on a Button still produces system blue background on iOS. Expected: red background, system font/insets retained. Likely cause: the Swift bridge applies modifiers conditionally, but the iOS visitor in uikit_renderer.cr line 1247 passes nil for the override even when it's set."
    },
    {
      "check_id": "swiftui.glass-cascade",
      "required": true,
      "passed": false,
      "blocked": true,
      "evidence": [],
      "notes": "Blocked: the Swift companion library AssetPipelineSwiftKit was not found in the iOS sample build. xcodebuild reports 'no such module AssetPipelineSwiftKit'. Implementer's handoff says it was added; build configuration may be missing."
    }
  ],
  "summary": "1 required check passes, 2 fail (one due to logic gap, one blocked by missing module link). Implementer needs to fix uikit_renderer.cr modifier propagation and verify Swift companion library is linked into the iOS sample target."
}
```
