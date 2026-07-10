#!/usr/bin/env bash
# Phase 6.5 D5 — Vendor refresh script.
# Refetches vendor/audit/axe.min.js + vendor/audit/ace.js at the pinned
# versions documented in vendor/audit/README.md.
#
# Run only when audit rules need an update. Commit the refreshed files
# in a follow-up commit with the version bump in the README.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
DEST="$ROOT/vendor/audit"
mkdir -p "$DEST"

AXE_VERSION="4.10.2"
ACE_VERSION="4.0.17"

curl -fsSL "https://cdnjs.cloudflare.com/ajax/libs/axe-core/${AXE_VERSION}/axe.min.js" \
  -o "$DEST/axe.min.js"
echo "vendor_install: refreshed axe-core $AXE_VERSION -> $DEST/axe.min.js ($(wc -c < "$DEST/axe.min.js") bytes)"

curl -fsSL "https://unpkg.com/accessibility-checker-engine@${ACE_VERSION}/ace.js" \
  -o "$DEST/ace.js"
echo "vendor_install: refreshed ACE $ACE_VERSION -> $DEST/ace.js ($(wc -c < "$DEST/ace.js") bytes)"
