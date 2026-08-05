#!/usr/bin/env bash
# scripts/audit_duplication.sh
# Runs the repository-owned exact structural duplication detector.
set -euo pipefail
exec dart run scripts/audit/duplication.dart "$@"
