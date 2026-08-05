#!/usr/bin/env bash
# scripts/install_audit_tools.sh
# Bootstrap audit tools separately from the application's analyzer-8 resolver.
# Global activation keeps coverde's dependency graph out of the checked-in app
# lockfile; the blocking dependency compatibility contract validates that lock.
set -euo pipefail

echo "[audit:install] Activating coverde globally (pinned to 0.3.0+1)..."
dart pub global activate coverde 0.3.0+1

echo "[audit:install] Verifying coverde is on PATH..."
if ! command -v coverde >/dev/null 2>&1; then
  echo "[audit:install] WARNING: coverde not on PATH — add ~/.pub-cache/bin to PATH" >&2
fi

echo "[audit:install] Done."
