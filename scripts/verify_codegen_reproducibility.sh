#!/usr/bin/env bash

# D-08/D-09: prove that committed generators are deterministic before trusting
# downstream static analysis and architecture checks.
set -euo pipefail

PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
cd "$PROJECT_ROOT"

generation_scope=(
  pubspec.yaml
  pubspec.lock
  lib/generated/
)

while IFS= read -r generated_file; do
  generation_scope+=("$generated_file")
done < <(git ls-files -- 'lib/**/*.g.dart' 'lib/**/*.freezed.dart')

fail() {
  printf 'verify_codegen_reproducibility: %s\n' "$*" >&2
  exit 1
}

assert_clean_generation_scope() {
  local boundary="$1"

  if ! git diff --exit-code HEAD -- "${generation_scope[@]}"; then
    printf 'Generated scope changed at %s:\n' "$boundary" >&2
    git diff --name-only HEAD -- "${generation_scope[@]}" >&2
    fail 'commit the reviewed handwritten input and generated output together, then rerun from a clean scope'
  fi
}

assert_clean_generation_scope 'before generation'

flutter pub get --enforce-lockfile
dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk

printf 'Running generation pass 1.\n'
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
assert_clean_generation_scope 'after generation pass 1'

flutter analyze --no-fatal-infos
dart run custom_lint --no-fatal-infos
flutter test \
  test/architecture/layer_import_rules_test.dart \
  test/architecture/domain_import_rules_test.dart \
  test/architecture/presentation_layer_rules_test.dart
dart run scripts/verify_tooling_guards.dart

git diff --check
