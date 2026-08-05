import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/verify_codegen_reproducibility.sh';

int _onlyIndexOf(String source, String value) {
  expect(
    RegExp(RegExp.escape(value)).allMatches(source),
    hasLength(1),
    reason: '$value must appear exactly once as an executable contract step',
  );
  return source.indexOf(value);
}

void main() {
  test('first pass is locked and diff-scoped', () {
    final source = File(_scriptPath).readAsStringSync();

    expect(source, contains('#!/usr/bin/env bash'));
    expect(source, contains('set -euo pipefail'));
    expect(source, contains('BASH_SOURCE[0]'));
    expect(source, contains('pwd -P'));
    expect(source, contains('git ls-files'));
    expect(source, contains('git diff --exit-code HEAD --'));
    expect(source, contains('pubspec.yaml'));
    expect(source, contains('pubspec.lock'));
    expect(source, contains('lib/generated/'));
    expect(source, contains("'lib/**/*.g.dart' 'lib/**/*.freezed.dart'"));

    final dirtyPreflight = source.indexOf(
      "assert_clean_generation_scope 'before generation'",
    );
    final pubGet = _onlyIndexOf(source, 'flutter pub get --enforce-lockfile');
    final baseline = _onlyIndexOf(
      source,
      'dart run scripts/dependency_compatibility.dart '
      '--mode=baseline --verify-running-flutter-sdk',
    );
    final l10n = _onlyIndexOf(source, 'flutter gen-l10n');
    final buildRunner = _onlyIndexOf(
      source,
      'flutter pub run build_runner build --delete-conflicting-outputs',
    );
    final firstPassDiff = source.indexOf(
      "assert_clean_generation_scope 'after generation pass 1'",
    );
    final analyzer = _onlyIndexOf(source, 'flutter analyze --no-fatal-infos');
    final customLint = _onlyIndexOf(
      source,
      'dart run custom_lint --no-fatal-infos',
    );
    final layer = _onlyIndexOf(
      source,
      'test/architecture/layer_import_rules_test.dart',
    );
    final domain = _onlyIndexOf(
      source,
      'test/architecture/domain_import_rules_test.dart',
    );
    final presentation = _onlyIndexOf(
      source,
      'test/architecture/presentation_layer_rules_test.dart',
    );
    final toolingGuards = _onlyIndexOf(
      source,
      'dart run scripts/verify_tooling_guards.dart',
    );

    expect(dirtyPreflight, greaterThanOrEqualTo(0));
    expect(pubGet, greaterThan(dirtyPreflight));
    expect(baseline, greaterThan(pubGet));
    expect(l10n, greaterThan(baseline));
    expect(buildRunner, greaterThan(l10n));
    expect(firstPassDiff, greaterThan(buildRunner));
    expect(analyzer, greaterThan(firstPassDiff));
    expect(customLint, greaterThan(analyzer));
    expect(layer, greaterThan(customLint));
    expect(domain, greaterThan(layer));
    expect(presentation, greaterThan(domain));
    expect(toolingGuards, greaterThan(presentation));

    expect(source, isNot(contains('build_runner watch')));
    expect(
      RegExp(r'git (?:reset|checkout|clean)|(?:dart|flutter) format').hasMatch(
        source,
      ),
      isFalse,
    );
  });
}
