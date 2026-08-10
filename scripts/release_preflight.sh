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
PHASE61_SIGNING_EVIDENCE="${PHASE61_SIGNING_EVIDENCE:-}"
RELEASE_DEPENDENCY_SCOPE_ACTIVE=false
RELEASE_DEPENDENCY_SCOPE_DIR=''
RELEASE_PUBSPEC_BACKUP=''
RELEASE_LOCK_BACKUP=''

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

Without --package this script performs credential-free release verification:
Android generates release metadata only; iOS creates an unsigned release app.
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

verify_android_package_jdk17() {
  local jdk_home=''
  local candidate
  local java_binary
  local java_version
  local java_major

  for candidate in "${PHASE61_JAVA_HOME:-}" "${JAVA_HOME:-}"; do
    if [[ -n "$candidate" && -x "$candidate/bin/java" ]]; then
      jdk_home="$candidate"
      break
    fi
  done

  [[ -n "$jdk_home" ]] ||
    fail 'Android package requires PHASE61_JAVA_HOME or JAVA_HOME with executable bin/java'

  java_binary="$jdk_home/bin/java"
  if ! java_version="$("$java_binary" -version 2>&1)"; then
    fail 'Android package Java version check failed'
  fi
  if [[ "$java_version" =~ version[[:space:]]+\"([0-9]+) ]]; then
    java_major="${BASH_REMATCH[1]}"
  else
    fail 'Android package Java version output is not parseable'
  fi
  [[ "$java_major" == "17" ]] ||
    fail "Android package requires JDK 17; configured Java is major $java_major"

  export JAVA_HOME="$jdk_home"
  export PATH="$JAVA_HOME/bin:$PATH"
  log "Android package JDK verified: $JAVA_HOME"
}

remove_generated_registrants() {
  local root="${1:-$PROJECT_ROOT}"
  # These are ignored Flutter-generated files, never hand-maintained source.
  run rm -f \
    "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java" \
    "$root/ios/Runner/GeneratedPluginRegistrant.h" \
    "$root/ios/Runner/GeneratedPluginRegistrant.m"
}

write_ios_release_pubspec() {
  local input="$1"
  local output="$2"

  # Flutter 3.44 intentionally does not filter native dev dependencies for
  # iOS/macOS (flutter/flutter#163874). Keep integration_test available to
  # device-test jobs, but remove it from the temporary manifest used for a
  # shipping iOS build so it cannot enter the generated registrant or app.
  awk '
    /^  integration_test:$/ {
      if (removed != 0) {
        exit 43
      }
      removed = 1
      skipping = 1
      next
    }
    skipping && /^    sdk: flutter$/ {
      skipping = 0
      next
    }
    { print }
    END {
      if (removed != 1 || skipping != 0) {
        exit 42
      }
    }
  ' "$input" > "$output"
}

prepare_ios_release_dependency_scope() {
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    ios|all) ;;
    *) return 0 ;;
  esac

  "$DRY_RUN" && return 0

  RELEASE_DEPENDENCY_SCOPE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/happy-pocket-release-preflight.XXXXXX")"
  RELEASE_PUBSPEC_BACKUP="$RELEASE_DEPENDENCY_SCOPE_DIR/pubspec.yaml"
  RELEASE_LOCK_BACKUP="$RELEASE_DEPENDENCY_SCOPE_DIR/pubspec.lock"
  cp "$PROJECT_ROOT/pubspec.yaml" "$RELEASE_PUBSPEC_BACKUP"
  cp "$PROJECT_ROOT/pubspec.lock" "$RELEASE_LOCK_BACKUP"
  RELEASE_DEPENDENCY_SCOPE_ACTIVE=true

  if ! write_ios_release_pubspec \
    "$RELEASE_PUBSPEC_BACKUP" \
    "$PROJECT_ROOT/pubspec.yaml"; then
    fail 'could not create the temporary iOS release manifest without integration_test'
  fi
}

restore_release_dependency_scope() {
  local exit_status="$1"
  trap - EXIT

  if ! "$RELEASE_DEPENDENCY_SCOPE_ACTIVE"; then
    return "$exit_status"
  fi

  cp "$RELEASE_PUBSPEC_BACKUP" "$PROJECT_ROOT/pubspec.yaml"
  cp "$RELEASE_LOCK_BACKUP" "$PROJECT_ROOT/pubspec.lock"
  RELEASE_DEPENDENCY_SCOPE_ACTIVE=false

  # Restore the normal development package configuration after the release
  # artifact has been checked. This is deliberately after all artifact scans:
  # pub get regenerates development registrants that include integration_test.
  if ! flutter pub get; then
    log 'ERROR: restored pubspec files, but flutter pub get could not restore the development package configuration.' >&2
    exit_status=1
  fi
  rm -rf "$RELEASE_DEPENDENCY_SCOPE_DIR"

  return "$exit_status"
}

assert_release_registrants_clean() {
  local root="${1:-$PROJECT_ROOT}"
  local registrant
  local -a registrants=()

  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      registrants+=(
        "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
      )
      ;;
    ios)
      registrants+=(
        "$root/ios/Runner/GeneratedPluginRegistrant.h"
        "$root/ios/Runner/GeneratedPluginRegistrant.m"
      )
      ;;
    all)
      registrants+=(
        "$root/android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java"
        "$root/ios/Runner/GeneratedPluginRegistrant.h"
        "$root/ios/Runner/GeneratedPluginRegistrant.m"
      )
      ;;
  esac

  for registrant in "${registrants[@]}"; do
    [[ -f "$registrant" ]] || continue
    if grep -nF 'integration_test' "$registrant" >&2; then
      fail "dev-only integration_test reference found in generated release registrant: ${registrant#$root/}"
    fi
  done
}

assert_ios_release_artifact_clean() {
  local root="${1:-$PROJECT_ROOT}"
  local binary="$root/build/ios/iphoneos/Runner.app/Runner"

  [[ -f "$binary" ]] || fail 'iOS release smoke build did not produce Runner.app/Runner'
  if strings "$binary" | grep -n -i -E 'integration[_-]?test|IntegrationTestPlugin' >&2; then
    fail 'dev-only integration_test reference found in the iOS release Runner.app binary'
  fi
}

assert_android_release_artifacts_clean() {
  local root="${1:-$PROJECT_ROOT}"
  local aab="$root/build/app/outputs/bundle/release/app-release.aab"
  local apk="$root/build/app/outputs/flutter-apk/app-release.apk"
  local artifact
  local test_pattern='integration_test|IntegrationTestPlugin|dev[.]flutter[.]integration_test'

  if [[ ! -f "$apk" ]]; then
    apk="$root/build/app/outputs/apk/release/app-release.apk"
  fi
  [[ -f "$aab" ]] || fail 'Android release packaging did not produce app-release.aab'
  [[ -f "$apk" ]] || fail 'Android release packaging did not produce app-release.apk'

  for artifact in "$aab" "$apk"; do
    if unzip -Z1 "$artifact" | grep -n -i -E "$test_pattern" >&2; then
      fail "dev-only test entry found in Android release artifact: ${artifact#$root/}"
    fi
    if strings "$artifact" | grep -n -i -E "$test_pattern" >&2; then
      fail "dev-only test content found in Android release artifact: ${artifact#$root/}"
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
    run_flutter pub run build_runner build
  else
    log 'Skipping Dart code generation (pass --regenerate only when generator inputs changed).'
  fi
}

run_smoke_compile() {
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      # Generates release-mode Android metadata without constructing an APK or
      # reaching the CR-04 signing gate. A signed artifact is only attempted by
      # --package and remains fail-closed.
      run_flutter build apk --release --config-only
      ;;
    ios)
      # This is a real unsigned release build, not a profile build. Profile
      # mode includes dev plugins in its registrant and cannot prove release
      # artifact hygiene.
      run_flutter build ios --release --no-codesign
      ;;
    all)
      run_flutter build apk --release --config-only
      run_flutter build ios --release --no-codesign
      ;;
  esac
}

package_signed_release() {
  case "$RELEASE_PREFLIGHT_PLATFORM" in
    android)
      # This invokes verifyReleaseSigning; no debug-key fallback is permitted.
      if [[ "$PHASE61_SIGNING_EVIDENCE" == "true" ]]; then
        run "$PROJECT_ROOT/android/gradlew" -p "$PROJECT_ROOT/android" \
          --no-daemon \
          -Pphase61SigningEvidence=true bundleRelease
        run "$PROJECT_ROOT/android/gradlew" -p "$PROJECT_ROOT/android" \
          --no-daemon \
          -Pphase61SigningEvidence=true assembleRelease
      else
        run_flutter build appbundle --release
        run_flutter build apk --release
      fi
      ;;
    ios)
      run_flutter build ipa --release
      ;;
    all)
      run_flutter build appbundle --release
      run_flutter build apk --release
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
  trap 'restore_release_dependency_scope "$?"' EXIT
  prepare_ios_release_dependency_scope
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
    case "$RELEASE_PREFLIGHT_PLATFORM" in
      ios|all) assert_ios_release_artifact_clean ;;
    esac
  fi

  if "$PACKAGE_RELEASE"; then
    case "$RELEASE_PREFLIGHT_PLATFORM" in
      android|all) verify_android_package_jdk17 ;;
    esac
    log 'Preflight passed; starting signed production packaging.'
    package_signed_release
    if "$DRY_RUN"; then
      log 'DRY RUN: would scan both Android release artifacts.'
    else
      case "$RELEASE_PREFLIGHT_PLATFORM" in
        android|all) assert_android_release_artifacts_clean ;;
      esac
    fi
  else
    log 'Preflight passed; signed production packaging was not requested.'
  fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
