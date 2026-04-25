#!/usr/bin/env bash
# scripts/audit_duplication.sh
# Phase-1 stub: duplication detection is delegated to AI agent (CONTEXT.md D-01.b).
# Emits empty findings array to keep the merger's input-set static.
set -euo pipefail
exec dart run scripts/audit/duplication.dart "$@"
