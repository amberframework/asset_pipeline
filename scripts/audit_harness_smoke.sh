#!/usr/bin/env bash
# Phase 6.5 audit harness smoke shim.
#
# Thin wrapper around `scripts/audit_harness.cr` that maps positional
# arguments to the Crystal CLI's `--invariant`/`--platform`/`--slug` flags.
#
# Usage:
#   bash scripts/audit_harness_smoke.sh <I-N> <platform> [slug] [--format json]
#
# Examples:
#   bash scripts/audit_harness_smoke.sh I-3 ios demo_button
#   bash scripts/audit_harness_smoke.sh I-1 web action_sheet --format json
#   bash scripts/audit_harness_smoke.sh I-11 macos
#
# Exit codes (passthrough from audit_harness.cr):
#   0  -> probe PASS or documented SKIP
#   1  -> probe FAIL
#   2  -> unimplemented routing
#   3  -> internal error / bad args
#
# The brief.yml probe cells reference this script as the entry point. The
# probe-cell semantics in brief.yml §5 are: the brief validator only
# path-checks; the Phase 6.5 Validator at end of phase executes every
# cell command and expects exit 0 (or a documented skip recorded in the
# matrix).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HARNESS_SRC="$ROOT/scripts/audit_harness.cr"

if [ ! -f "$HARNESS_SRC" ]; then
  echo "audit_harness_smoke: missing $HARNESS_SRC" >&2
  exit 3
fi

if [ "$#" -lt 2 ]; then
  echo "Usage: bash scripts/audit_harness_smoke.sh <I-N> <platform> [slug] [--format json]" >&2
  exit 3
fi

INVARIANT="$1"
PLATFORM="$2"
shift 2

EXTRA_ARGS=()
if [ "$#" -ge 1 ]; then
  case "$1" in
    --format|--*)
      EXTRA_ARGS+=("$@")
      ;;
    *)
      EXTRA_ARGS+=(--slug "$1")
      shift
      EXTRA_ARGS+=("$@")
      ;;
  esac
fi

# Pick the Crystal binary: prefer crystal-alpha (native renderer flags)
# but fall back to crystal for environments without the alpha toolchain.
CRYSTAL_BIN="${CRYSTAL_BIN:-}"
if [ -z "$CRYSTAL_BIN" ]; then
  if command -v crystal-alpha >/dev/null 2>&1; then
    CRYSTAL_BIN="crystal-alpha"
  elif command -v crystal >/dev/null 2>&1; then
    CRYSTAL_BIN="crystal"
  else
    echo "audit_harness_smoke: neither crystal-alpha nor crystal in PATH" >&2
    exit 3
  fi
fi

if [ "${#EXTRA_ARGS[@]}" -eq 0 ]; then
  exec "$CRYSTAL_BIN" run "$HARNESS_SRC" -- \
    --invariant "$INVARIANT" \
    --platform "$PLATFORM"
else
  exec "$CRYSTAL_BIN" run "$HARNESS_SRC" -- \
    --invariant "$INVARIANT" \
    --platform "$PLATFORM" \
    "${EXTRA_ARGS[@]}"
fi
