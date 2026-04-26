#!/usr/bin/env bash
# scripts/build_coverage_baseline.sh
# Local end-to-end run of the Phase 2 coverage baseline pipeline
# (mirrors the audit.yml `coverage` job). Produces the four
# .planning/audit/coverage-* artifacts.
#
# Steps:
#   1. flutter test --coverage              → coverage/lcov.info
#   2. coverde filter (strip generated)     → coverage/lcov_clean.info
#   3. dart run scripts/coverage_baseline   → 4 .planning/audit/ artifacts
#   4. Verify all four artifact files exist

set -euo pipefail

echo "[coverage:baseline] running flutter test --coverage..."
flutter test --coverage

echo "[coverage:baseline] stripping generated files via coverde filter..."
# Patterns mirror .github/workflows/audit.yml very_good_coverage.exclude
# (the source of truth). Verify exact `coverde filter` flag syntax against
# `coverde filter --help` if syntax differs across coverde versions.
coverde filter \
  --input coverage/lcov.info \
  --output coverage/lcov_clean.info \
  --filters '\.g\.dart$,\.freezed\.dart$,\.mocks\.dart$,^lib/generated/'

echo "[coverage:baseline] computing per-file coverage..."
dart run scripts/coverage_baseline.dart

echo "[coverage:baseline] verifying outputs..."
test -f .planning/audit/coverage-baseline.txt
test -f .planning/audit/coverage-baseline.json
test -f .planning/audit/files-needing-tests.txt
test -f .planning/audit/files-needing-tests.json

echo "[coverage:baseline] OK"
