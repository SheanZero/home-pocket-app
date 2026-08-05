#!/usr/bin/env bash
# scripts/audit_providers.sh
# Runs the repository-owned provider contract and emits provider-hygiene findings.
set -euo pipefail
exec dart run scripts/audit/providers.dart "$@"
