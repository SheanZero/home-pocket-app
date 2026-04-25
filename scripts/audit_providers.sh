#!/usr/bin/env bash
# scripts/audit_providers.sh
# Runs custom_lint, filters to riverpod_lint codes, emits .planning/audit/shards/providers.json
set -euo pipefail
exec dart run scripts/audit/providers.dart "$@"
