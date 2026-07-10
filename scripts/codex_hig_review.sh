#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "usage: $0 <slug>" >&2
  exit 64
fi

SLUG="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
VALIDATION_DIR="${REPO_ROOT}/.claude/skills/apple-platform-guide/validation"
SCREENSHOT_DIR="${VALIDATION_DIR}/screenshots"
OUT_DIR="${VALIDATION_DIR}/codex-reviews"
SCHEMA="${VALIDATION_DIR}/codex-review.schema.json"
OUT_FILE="${OUT_DIR}/${SLUG}.json"

mkdir -p "${OUT_DIR}"

CODEX_BIN="${CODEX_BIN:-codex}"
MODEL_ARGS=()
if [[ -n "${CODEX_MODEL:-}" ]]; then
  MODEL_ARGS=(-m "${CODEX_MODEL}")
fi

IMAGE_ARGS=()
for image in \
  "${SCREENSHOT_DIR}/${SLUG}-macos-light.png" \
  "${SCREENSHOT_DIR}/${SLUG}-macos-dark.png" \
  "${SCREENSHOT_DIR}/${SLUG}-ios-light.png" \
  "${SCREENSHOT_DIR}/${SLUG}-ios-dark.png"; do
  if [[ -f "${image}" ]]; then
    IMAGE_ARGS+=(--image "${image}")
  fi
done

"${CODEX_BIN}" exec \
  -C "${REPO_ROOT}" \
  --sandbox read-only \
  --output-schema "${SCHEMA}" \
  -o "${OUT_FILE}" \
  "${MODEL_ARGS[@]}" \
  "${IMAGE_ARGS[@]}" \
  - <<PROMPT
You are the external Codex reviewer for asset_pipeline's Apple HIG validation loop.

Review slug: ${SLUG}

You are independent from the builder and from the design-critic persona. Do not edit files.
Return only JSON matching ${SCHEMA}.

Read and apply these local sources:
- .claude/skills/apple-platform-guide/validation/worklist.json
- .claude/skills/apple-platform-guide/validation/reports/${SLUG}.md, if present
- .claude/skills/apple-platform-guide/validation/evidence/${SLUG}.json, if present
- .claude/skills/apple-platform-guide/foundations/preview-composition.md
- .claude/skills/apple-platform-guide/foundations/preview-screen-recipes.md
- .claude/skills/apple-platform-guide/brand/amber.md
- .claude/agents/design-critic/agent.md
- .claude/skills/apple-hig/pages/${SLUG}.md, if present

Use the attached screenshots when present. If a required screenshot is missing,
stale, unreadable, all-black, not linked by the report, or newer than the report,
the row verdict is INSUFFICIENT_EVIDENCE.

Review rules:
- Current pixels beat prose. If report text and screenshots disagree, trust screenshots.
- A platform-inapplicable card is PLATFORM_N_A for that platform, not a visual pass.
- A target-platform native component must be implemented or left pending as an
  implementation gap; do not accept a skip because the bridge is hard.
- Apply the prescribed screen recipe. Wrong recipe is NEEDS_WORK.
- Apply default taste gates: palette role map, alignment rails, component anatomy,
  stage discipline, HIG state, and Amber role colors.
- Raw system blue/red visible as primary/destructive action color is NEEDS_WORK
  unless the report names a native-control exception and removes competing hues.
- For glass-required surfaces, visible backdrop bleed-through must be demonstrated
  in the screenshot. A material object in code is not enough.

Produce:
- row_verdict as the worst applicable gate.
- per-appearance verdicts.
- concise findings with concrete evidence and fixes.
- builder_next_steps that the implementation agent can execute.
- public_summary suitable for a build-in-public progress note.
PROMPT

echo "${OUT_FILE}"
