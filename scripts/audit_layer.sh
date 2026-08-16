#!/usr/bin/env bash
# scripts/audit_layer.sh
# Runs import_lint and emits tool/audit/shards/layer.json
set -euo pipefail
exec dart run scripts/audit/layer.dart "$@"
