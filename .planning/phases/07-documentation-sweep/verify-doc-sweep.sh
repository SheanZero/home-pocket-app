#!/usr/bin/env bash
# .planning/phases/07-documentation-sweep/verify-doc-sweep.sh
# Verifies that documentation drift is fully remediated.
# Exits 0 only when ALL drift gates pass.

set -euo pipefail
fail=0

echo "[1/6] Checking layer-centralization drift..."
hits=$(grep -rn --exclude-dir=03-adr "features/[a-z_]*/use_cases\|features/[a-z_]*/data/repositories" docs/arch/ | wc -l || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits stale layer paths in docs/arch/"; fail=1; } || echo "  OK"

echo "[2/6] Checking mockito drift..."
hits=$(grep -rn --exclude-dir=03-adr "package:mockito\|@GenerateMocks\|\.mocks\.dart" docs/arch/ | wc -l || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits mockito references"; fail=1; } || echo "  OK"

echo "[3/6] Checking sqlite3_flutter_libs drift in non-historical contexts..."
hits=$(grep -rn --exclude-dir=03-adr "sqlite3_flutter_libs" docs/arch/ | wc -l || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits sqlite3_flutter_libs in non-ADR docs"; fail=1; } || echo "  OK"

echo "[4/6] Checking doc/arch path drift in CLAUDE.md and rules..."
hits=$({ grep -hcE 'doc/arch[^/]' CLAUDE.md .claude/rules/arch.md 2>/dev/null || true; } | awk '{s+=$1} END {print s+0}')
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits 'doc/arch' references"; fail=1; } || echo "  OK"

echo "[5/6] Checking MOD-014 phantom references..."
hits=$(grep -rn "MOD-014_i18n\.md\|MOD-014 i18n" docs/arch/ CLAUDE.md | wc -l || true)
[ "$hits" -gt 0 ] && { echo "  FAIL: $hits phantom MOD-014 file references"; fail=1; } || echo "  OK"

echo "[6/6] Checking ADR-011 presence..."
test -f docs/arch/03-adr/ADR-011_*.md || { echo "  FAIL: ADR-011 missing"; fail=1; }
grep -q "ADR-011" docs/arch/03-adr/ADR-000_INDEX.md || { echo "  FAIL: ADR-011 not indexed"; fail=1; }
[ "$fail" -eq 0 ] && echo "  OK"

exit $fail
