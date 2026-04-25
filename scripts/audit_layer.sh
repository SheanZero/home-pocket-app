#!/usr/bin/env bash
# scripts/audit_layer.sh
# Runs custom_lint, filters to import_guard codes, emits .planning/audit/shards/layer.json
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
