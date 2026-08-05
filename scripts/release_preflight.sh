#!/usr/bin/env bash
#
# Rebuilds the native plugin registrants from a clean state before a release
# candidate. Device integration tests can generate registrants containing the
# dev-only integration_test plugin; those files are ignored by git but can make
# the next Android release compilation fail. This script makes the transition
# deterministic and deliberately separates credential-free smoke compilation
# from signed production packaging.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RELEASE_PREFLIGHT_PLATFORM="all"
DRY_RUN=false
REGENERATE=false
PACKAGE_RELEASE=false

usage() {
  cat <<'USAGE'
Usage: bash scripts/release_preflight.sh [options]

Options:
  --platform android|ios|all  Targets to clean and smoke-compile (default: all).
  --regenerate                Run gen-l10n and build_runner after pub get.
                              Use only when the release includes ARB, Riverpod,
                              Freezed, or Drift generator inputs.
  --package                   After preflight passes, create signed production
                              artifacts. Android still requires the fail-closed
                              Gradle production-signing credentials; iOS still
                              requires its normal signing setup.
  --dry-run                   Print the ordered commands without changing files.
  -h, --help                  Show this help.

Without --package this script only creates unsigned/profile smoke artifacts.
USAGE
}

log() {
  printf '[release-preflight] %s\n' "$*"
}

fail() {
  printf '[release-preflight] ERROR: %s\n' "$*" >&2
  exit 1
}

run() {
  if "$DRY_RUN"; then
    log "DRY RUN: $*"
    return 0
  fi
  log "$*"
  "$@"
}

run_flutter() {
  run flutter "$@"
}

remove_generated_registrants() {
  local root="${1:-$PROJECT_ROOT}"
  # These are ignored Flutter-generated files, never hand-maintained source.
  run rm -f \
    "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java" \
    "$root/ios/Runner/GeneratedPluginRegistrant.h" \
    "$root/ios/Runner/GeneratedPluginRegistrant.m"
}

assert_release_registrants_clean() {
  local root="${1:-$PROJECT_ROOT}"
  local registrant
  local -a registrants=(
    "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
    "$root/ios/Runner/GeneratedPluginRegistrant.h"
    "$root/ios/Runner/GeneratedPluginRegistrant.m"
  )

  for registrant in "${registrants[@]}"; do
    [[ -f "$registrant" ]] || continue
    if grep -nF 'integration_test' "$registrant" >&2; then
      fail "dev-only integration_test reference found in generated release registrant: ${registrant#$root/}"
    fi
  done
}

assert_expected_registrants_exist() {
  local root="${1:-$PROJECT_ROOT}"
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      [[ -f "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java" ]] ||
        fail 'Android smoke compilation did not regenerate GeneratedPluginRegistrant.java'
      ;;
    ios)
      [[ -f "$root/ios/Runner/GeneratedPluginRegistrant.m" ]] ||
        fail 'iOS smoke compilation did not regenerate GeneratedPluginRegistrant.m'
      ;;
    all)
      [[ -f "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java" ]] ||
        fail 'Android smoke compilation did not regenerate GeneratedPluginRegistrant.java'
      [[ -f "$root/ios/Runner/GeneratedPluginRegistrant.m" ]] ||
        fail 'iOS smoke compilation did not regenerate GeneratedPluginRegistrant.m'
      ;;
  esac
}

regenerate_if_required() {
  if "$REGENERATE"; then
    run_flutter gen-l10n
    run_flutter pub run build_runner build --delete-conflicting-outputs
  else
    log 'Skipping Dart code generation (pass --regenerate only when generator inputs changed).'
  fi
}

run_smoke_compile() {
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      run_flutter build apk --profile
      ;;
    ios)
      run_flutter build ios --profile --no-codesign
      ;;
    all)
      run_flutter build apk --profile
      run_flutter build ios --profile --no-codesign
      ;;
  esac
}

package_signed_release() {
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      # This invokes verifyReleaseSigning; no debug-key fallback is permitted.
      run_flutter build appbundle --release
      ;;
    ios)
      run_flutter build ipa --release
      ;;
    all)
      run_flutter build appbundle --release
      run_flutter build ipa --release
      ;;
  esac
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --platform)
        [[ $# -ge 2 ]] || fail '--platform requires android, ios, or all'
        RELEASE_PREFLIGHT_PLATFORM="$2"
        shift 2
        ;;
      --regenerate)
        REGENERATE=true
        shift
        ;;
      --package)
        PACKAGE_RELEASE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h|--help)
        usage
        return 0
        ;;
      *)
        fail "unknown option: $1"
        ;;
    esac
  done

  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android|ios|all) ;;
    *) fail "unsupported platform: $RELEASE_PREFLIGHT_PLATFORM" ;;
  esac

  cd "$PROJECT_ROOT"
  log "Starting clean $RELEASE_PREFLIGHT_PLATFORM release preflight."
  run_flutter clean
  remove_generated_registrants
  run_flutter pub get
  regenerate_if_required
  run_smoke_compile

  if "$DRY_RUN"; then
    log 'DRY RUN: would verify generated registrants contain no integration_test reference.'
  else
    assert_expected_registrants_exist
    assert_release_registrants_clean
  fi

  if "$PACKAGE_RELEASE"; then
    log 'Preflight passed; starting signed production packaging.'
    package_signed_release
  else
    log 'Preflight passed; signed production packaging was not requested.'
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
