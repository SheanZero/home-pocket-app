#!/usr/bin/env bash
# .planning/phases/07-documentation-sweep/verify-doc-sweep-smoke.sh
# Hermetic smoke test: confirms verify-doc-sweep.sh gate 4 detects `doc/arch/`
# singular-path drift. Injects a deliberate violation into a TEMP COPY of
# CLAUDE.md (NOT the real file), runs the gate against the temp copy, and
# asserts the gate fails. Cleans up unconditionally.
#
# Exit 0 = gate 4 correctly detected drift (smoke PASS).
# Exit non-zero = gate 4 still cannot detect drift (smoke FAIL — regression).

set -euo pipefail

WORKDIR=$(mktemp -d)
trap 'rm -rf "$WORKDIR"' EXIT

# Copy CLAUDE.md and .claude/rules/arch.md into the workdir
cp CLAUDE.md "$WORKDIR/CLAUDE.md"
mkdir -p "$WORKDIR/.claude/rules"
cp .claude/rules/arch.md "$WORKDIR/.claude/rules/arch.md"

# Inject deliberate drift into the temp CLAUDE.md
echo "see doc/arch/foo for details" >> "$WORKDIR/CLAUDE.md"

# Build a temp copy of the gate script that reads from $WORKDIR
TEMP_SCRIPT="$WORKDIR/verify-doc-sweep.sh"
sed -e "s|CLAUDE\.md|$WORKDIR/CLAUDE.md|g" \
    -e "s|\.claude/rules/arch\.md|$WORKDIR/.claude/rules/arch.md|g" \
    .planning/phases/07-documentation-sweep/verify-doc-sweep.sh > "$TEMP_SCRIPT"
chmod +x "$TEMP_SCRIPT"

# Run the gate; expect non-zero exit (drift was injected)
if bash "$TEMP_SCRIPT" >/dev/null 2>&1; then
  echo "SMOKE FAIL: gate 4 did NOT detect injected doc/arch/foo drift"
  exit 1
fi

echo "SMOKE PASS: gate 4 correctly fails on doc/arch/ drift"
exit 0
