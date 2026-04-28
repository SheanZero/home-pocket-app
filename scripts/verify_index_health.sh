#!/usr/bin/env bash
# scripts/verify_index_health.sh
# Confirms every link in INDEX files points to a real file,
# and every file in the directory is mentioned in INDEX.
#
# Usage: bash scripts/verify_index_health.sh
# Exit 0 = all INDEX files healthy; exit 1 = broken links or orphan files found.

set -euo pipefail

fail=0

check_dir() {
  local dir=$1
  local index=$2
  echo "Checking $dir against $index..."

  # (A) Broken-link check: for every (./...md) link in INDEX, verify the file exists
  while read -r path; do
    full="$dir/$(basename "$path")"
    if [ ! -f "$full" ]; then
      echo "  BROKEN LINK in $index: $path"
      fail=1
    fi
  done < <(grep -oE '\([^)]+\.md\)' "$index" | tr -d '()' | grep -v '^http' | sort -u)

  # (B) Orphan-file check: for every *.md in the directory, verify it's mentioned by basename in INDEX
  for f in "$dir"/*.md; do
    base=$(basename "$f")
    [ "$base" = "$(basename "$index")" ] && continue
    if ! grep -q "$base" "$index"; then
      echo "  ORPHAN: $base not listed in $index"
      fail=1
    fi
  done
}

check_dir docs/arch/01-core-architecture docs/arch/01-core-architecture/ARCH-000_INDEX.md
check_dir docs/arch/03-adr docs/arch/03-adr/ADR-000_INDEX.md

# 05-UI: ARCH-000 doubles as the master index for UI specs (per D-04 rationale).
# UI-001 must appear in ARCH-000's UI subsection.
check_dir docs/arch/05-UI docs/arch/01-core-architecture/ARCH-000_INDEX.md

# MOD-000 is a stub-with-pointer per D-04 — not a full INDEX, so we skip
# the orphan/link check here. The presence of MOD-000_INDEX.md is the DOCS-03 contract.
test -f docs/arch/02-module-specs/MOD-000_INDEX.md || { echo "  MOD-000_INDEX.md missing"; fail=1; }

exit $fail
