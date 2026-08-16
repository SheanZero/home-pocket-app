#!/usr/bin/env bash
# Validates the migrated cleanup coverage manifest.
#
# The original generator derived this list from milestone PLAN.md files. Those
# historical planning files were intentionally retired after the first public
# release, so tool/audit/cleanup-touched-files.txt is now the durable manifest.
# This command keeps the old entry point for CI and local tooling while
# fail-closing on missing, malformed, unsorted, duplicated, or undersized data.

set -euo pipefail

MANIFEST="${OUT:-tool/audit/cleanup-touched-files.txt}"

if [ ! -f "$MANIFEST" ]; then
  echo "[cleanup:touched] ERROR: manifest not found: $MANIFEST" >&2
  exit 2
fi

if grep -Ev '^lib/.+' "$MANIFEST" >/dev/null; then
  echo "[cleanup:touched] ERROR: every entry must be a lib/ path" >&2
  exit 2
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT
LC_ALL=C sort -u "$MANIFEST" > "$TMP"
if ! cmp -s "$TMP" "$MANIFEST"; then
  echo "[cleanup:touched] ERROR: manifest must be sorted and deduplicated" >&2
  exit 2
fi

COUNT="$(wc -l < "$MANIFEST" | tr -d ' ')"
if [ "$COUNT" -lt 50 ]; then
  echo "[cleanup:touched] ERROR: only $COUNT entries; expected at least 50" >&2
  exit 2
fi

echo "[cleanup:touched] validated $COUNT entries in $MANIFEST"
