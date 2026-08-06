#!/usr/bin/env bash
# scripts/audit_layer.sh
# Runs import_lint and emits .planning/audit/shards/layer.json
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
