#!/usr/bin/env bash
# scripts/build_cleanup_touched_files.sh
# Generates .planning/audit/cleanup-touched-files.txt — the union of all lib/
# file paths from `files_modified:` frontmatter of every Phase 3-6 PLAN.md.
# Per CONTEXT.md D-04: this list is the per-file ≥80% coverage gate input
# in audit.yml; it supersedes phase6-touched-files.txt (kept on disk as
# historical artifact).
#
# Steps:
#   1. Glob .planning/phases/0[3-6]-*/*-PLAN.md
#   2. For each plan: extract `files_modified:` YAML block, take entries
#      starting with `lib/` only (filter test/, scripts/, docs/, etc.)
#   3. Sort + uniq the union, write newline-delimited to output file
#   4. Verify line count > 50

set -euo pipefail

OUT=".planning/audit/cleanup-touched-files.txt"

echo "[cleanup:touched] enumerating Phase 3-6 PLAN.md files..."
PLANS=$(ls .planning/phases/0[3-6]-*/*-PLAN.md 2>/dev/null | sort)
if [ -z "$PLANS" ]; then
  echo "[cleanup:touched] ERROR: no Phase 3-6 PLAN.md files found" >&2
  exit 2
fi

echo "[cleanup:touched] extracting files_modified entries (lib/ only)..."
TMP=$(mktemp)
for plan in $PLANS; do
  # Extract the files_modified: YAML block: read until the next top-level
  # frontmatter key OR the closing ---. awk handles both bare `- path` and
  # quoted `- "path"` forms.
  awk '
    /^files_modified:/ {in_block=1; next}
    in_block && /^[a-zA-Z_]+:/ {in_block=0}
    in_block && /^---$/ {in_block=0}
    in_block && /^[[:space:]]*-[[:space:]]+/ {
      # strip leading "  - " / "- " and quotes
      sub(/^[[:space:]]*-[[:space:]]+/, "")
      gsub(/^"|"$/, "")
      gsub(/^'\''|'\''$/, "")
      print
    }
  ' "$plan" >> "$TMP"
done

echo "[cleanup:touched] filtering to lib/ paths and sorting..."
grep -E '^lib/' "$TMP" | sort -u > "$OUT"
rm -f "$TMP"

COUNT=$(wc -l < "$OUT" | tr -d ' ')
echo "[cleanup:touched] wrote $COUNT entries to $OUT"

if [ "$COUNT" -lt 50 ]; then
  echo "[cleanup:touched] WARNING: only $COUNT entries — Phase 3-6 union expected ≥50" >&2
fi

echo "[cleanup:touched] OK"
