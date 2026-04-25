#!/usr/bin/env bash
# scripts/install_audit_tools.sh
# Bootstrap audit tools that cannot live in pubspec.yaml due to analyzer-7 lock.
# See .planning/phases/01-audit-pipeline-tooling-setup/01-RESEARCH.md Pitfall P1-3:
# all coverde versions require analyzer >=8.0.0, which would break the project's
# analyzer-7 pin (json_serializable + riverpod_lint). Global-activate sidesteps it.
set -euo pipefail

echo "[audit:install] Activating coverde globally (pinned to 0.3.0+1)..."
dart pub global activate coverde 0.3.0+1

echo "[audit:install] Verifying coverde is on PATH..."
if ! command -v coverde >/dev/null 2>&1; then
  echo "[audit:install] WARNING: coverde not on PATH — add ~/.pub-cache/bin to PATH" >&2
fi

echo "[audit:install] Done."
