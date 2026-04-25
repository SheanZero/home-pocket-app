#!/usr/bin/env bash
# scripts/test_idempotency.sh
# Runs the full audit pipeline twice and diffs issues.json — proves stable IDs.
set -euo pipefail

bash scripts/test_audit_pipeline.sh
cp .planning/audit/issues.json /tmp/audit_run1.json

bash scripts/test_audit_pipeline.sh

if ! diff -q /tmp/audit_run1.json .planning/audit/issues.json; then
  echo "[audit:idempotency] FAIL: issues.json differs across runs (stable-ID guarantee broken)" >&2
  diff /tmp/audit_run1.json .planning/audit/issues.json | head -40 >&2
  exit 1
fi

echo "[audit:idempotency] OK — issues.json byte-identical across runs"
