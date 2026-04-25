#!/usr/bin/env bash
# scripts/audit_dead_code.sh
# Runs dart_code_linter check-unused-{code,files}, emits .planning/audit/shards/dead_code.json
set -euo pipefail
exec dart run scripts/audit/dead_code.dart "$@"
