import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/verify_codegen_reproducibility.sh';

String _executableSource(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .join('\n');

int _onlyIndexOf(String source, String value) {
  expect(
    RegExp(RegExp.escape(value)).allMatches(source),
    hasLength(1),
    reason: '$value must appear exactly once as an executable contract step',
  );
  return source.indexOf(value);
}

int _countOf(String source, String value) =>
    RegExp(RegExp.escape(value)).allMatches(source).length;

List<String> _twoPassContractViolations(String source) {
  final executable = _executableSource(source);
  final violations = <String>[];

  void expectCount(String value, int expected) {
    if (_countOf(executable, value) != expected) {
      violations.add('$value must appear $expected time(s)');
    }
  }

  expectCount('Running generation pass 1.', 1);
  expectCount('Running generation pass 2.', 1);
  expectCount('flutter gen-l10n', 2);
  expectCount('flutter pub run build_runner build --delete-conflicting-outputs', 2);
  expectCount("assert_clean_generation_scope 'after generation pass 1'", 1);
  expectCount("assert_clean_generation_scope 'after generation pass 2'", 1);
  expectCount('flutter analyze --no-fatal-infos', 1);
  expectCount('dart run custom_lint --no-fatal-infos', 1);
  expectCount('test/architecture/layer_import_rules_test.dart', 1);
  expectCount('test/architecture/domain_import_rules_test.dart', 1);
  expectCount('test/architecture/presentation_layer_rules_test.dart', 1);
  expectCount('dart run scripts/verify_tooling_guards.dart', 1);
  expectCount('git diff --check', 1);

  final pass1Diff = executable.indexOf(
    "assert_clean_generation_scope 'after generation pass 1'",
  );
  final pass2 = executable.indexOf('Running generation pass 2.');
  final pass2Diff = executable.indexOf(
    "assert_clean_generation_scope 'after generation pass 2'",
  );
  final analyzer = executable.indexOf('flutter analyze --no-fatal-infos');
  final customLint = executable.indexOf('dart run custom_lint --no-fatal-infos');
  final layer = executable.indexOf(
    'test/architecture/layer_import_rules_test.dart',
  );
  final domain = executable.indexOf(
    'test/architecture/domain_import_rules_test.dart',
  );
  final presentation = executable.indexOf(
    'test/architecture/presentation_layer_rules_test.dart',
  );
  final toolingGuards = executable.indexOf(
    'dart run scripts/verify_tooling_guards.dart',
  );
  final whitespace = executable.indexOf('git diff --check');

  if (pass1Diff < 0 || pass2 < pass1Diff || pass2Diff < pass2) {
    violations.add('both clean generation boundaries must precede pass 2');
  }
  if (analyzer < pass2Diff ||
      customLint < analyzer ||
      layer < customLint ||
      domain < layer ||
      presentation < domain ||
      toolingGuards < presentation ||
      whitespace < toolingGuards) {
    violations.add('quality gates must run once after the second clean pass');
  }
  if (executable.contains('|| true')) {
    violations.add('no command may swallow a failing exit status');
  }
  return violations;
}

void main() {
  test('first pass is locked and diff-scoped', () {
    final rawSource = File(_scriptPath).readAsStringSync();
    final source = _executableSource(rawSource);

    expect(rawSource, contains('#!/usr/bin/env bash'));
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
    final l10n = source.indexOf('flutter gen-l10n');
    final buildRunner = source.indexOf(
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

  test('two clean generation passes precede every lint and architecture gate', () {
    final source = File(_scriptPath).readAsStringSync();

    expect(_twoPassContractViolations(source), isEmpty);

    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          "assert_clean_generation_scope 'after generation pass 2'\n\n"
          'flutter analyze --no-fatal-infos',
          'flutter analyze --no-fatal-infos\n\n'
          "assert_clean_generation_scope 'after generation pass 2'",
        ),
      ),
      isNotEmpty,
      reason: 'analyzer cannot move before the second clean diff gate',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          'test/architecture/domain_import_rules_test.dart',
          'test/architecture/missing_architecture_test.dart',
        ),
      ),
      isNotEmpty,
      reason: 'all three architecture tests are mandatory',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          'dart run custom_lint --no-fatal-infos',
          'dart run custom_lint --no-fatal-infos\n'
          'dart run custom_lint --no-fatal-infos',
        ),
      ),
      isNotEmpty,
      reason: 'no fallback or duplicate quality command is allowed',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst('flutter gen-l10n', 'flutter gen-l10n || true'),
      ),
      isNotEmpty,
      reason: 'generator failures cannot be swallowed',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          'dart run scripts/verify_tooling_guards.dart',
          '# dart run scripts/verify_tooling_guards.dart',
        ),
      ),
      isNotEmpty,
      reason: 'comment-only quality commands do not count',
    );
  });
}
