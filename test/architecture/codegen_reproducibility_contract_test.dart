import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _scriptPath = 'scripts/verify_codegen_reproducibility.sh';

List<String> _executableLines(String source) => source
    .split('\n')
    .where((line) => !line.trimLeft().startsWith('#'))
    .map((line) => line.trim())
    .where((line) => line.isNotEmpty)
    .toList();

String _executableSource(String source) => _executableLines(source).join('\n');

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

List<String> _generatedOutputGuardViolations(String source) {
  final violations = <String>[];

  if (!source.contains('untracked_generation_outputs()')) {
    violations.add('the generated-output guard must enumerate untracked files');
  }
  if (_countOf(source, 'git ls-files --others --exclude-standard --') != 1) {
    violations.add('the generated-output guard must include non-ignored files');
  }
  if (_countOf(source, 'git ls-files --others --ignored --exclude-standard --') !=
      1) {
    violations.add('the generated-output guard must include ignored files');
  }
  if (!source.contains("':(glob)lib/**/*.g.dart'")) {
    violations.add('the generated-output guard must include all .g.dart files');
  }
  if (!source.contains("':(glob)lib/**/*.freezed.dart'")) {
    violations.add(
      'the generated-output guard must include all .freezed.dart files',
    );
  }
  if (source.contains('done < <(git ls-files')) {
    violations.add('the generated scope must not be fixed before generation');
  }
  return violations;
}

List<String> _twoPassContractViolations(String source) {
  const buildRunner =
      'flutter pub run build_runner build --delete-conflicting-outputs';
  final executableLines = _executableLines(source);
  final executable = executableLines.join('\n');
  final violations = <String>[];

  void expectCount(String value, int expected) {
    if (_countOf(executable, value) != expected) {
      violations.add('$value must appear $expected time(s)');
    }
  }

  void expectExecutableLineCount(String value, int expected) {
    if (executableLines.where((line) => line == value).length != expected) {
      violations.add('$value must appear $expected time(s)');
    }
  }

  expectCount('Running generation pass 1.', 1);
  expectCount('Running generation pass 2.', 1);
  expectCount('flutter gen-l10n', 2);
  expectExecutableLineCount(buildRunner, 2);
  expectCount("assert_clean_generation_scope 'after generation pass 1'", 1);
  expectCount("assert_clean_generation_scope 'after generation pass 2'", 1);
  expectCount('flutter analyze --no-fatal-infos', 1);
  expectCount('dart run import_lint', 1);
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
  final importLint = executable.indexOf('dart run import_lint');
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
  final l10nMatches = RegExp(
    RegExp.escape('flutter gen-l10n'),
  ).allMatches(executable).toList();
  final buildRunnerMatches = executableLines
      .asMap()
      .entries
      .where((entry) => entry.value == buildRunner)
      .map((entry) => entry.key)
      .toList();

  if (pass1Diff < 0 ||
      pass2 < pass1Diff ||
      pass2Diff < pass2 ||
      l10nMatches.length != 2 ||
      buildRunnerMatches.length != 2 ||
      l10nMatches[0].start > executable.indexOf(buildRunner) ||
      executable.indexOf(buildRunner) > pass1Diff ||
      l10nMatches[1].start < pass2 ||
      l10nMatches[1].start > executable.lastIndexOf(buildRunner) ||
      executable.lastIndexOf(buildRunner) > pass2Diff) {
    violations.add('each clean generation boundary must follow l10n then build_runner');
  }
  if (analyzer < pass2Diff ||
      importLint < analyzer ||
      layer < importLint ||
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
    expect(source, contains('git diff --exit-code HEAD --'));
    expect(source, contains('pubspec.yaml'));
    expect(source, contains('pubspec.lock'));
    expect(source, contains('lib/generated/'));
    expect(source, contains("':(glob)lib/**/*.g.dart'"));
    expect(source, contains("':(glob)lib/**/*.freezed.dart'"));

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
    final importLint = _onlyIndexOf(source, 'dart run import_lint');
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
    expect(importLint, greaterThan(analyzer));
    expect(layer, greaterThan(importLint));
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

  test('build_runner command is exact on both D-08 passes', () {
    final source = File(_scriptPath).readAsStringSync();
    const buildRunner =
        'flutter pub run build_runner build --delete-conflicting-outputs';
    const shortenedBuildRunner = 'flutter pub run build_runner build';

    expect(_twoPassContractViolations(source), isEmpty);
    expect(
      source,
      contains('Generator nondeterminism occurred on the second pass.'),
    );

    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          "  assert_clean_generation_scope 'after generation pass 2'\n\n"
          '  flutter analyze --no-fatal-infos',
          '  flutter analyze --no-fatal-infos\n\n'
          "  assert_clean_generation_scope 'after generation pass 2'",
        ),
      ),
      isNotEmpty,
      reason: 'analyzer cannot move before the second clean diff gate',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(buildRunner, shortenedBuildRunner),
      ),
      isNotEmpty,
      reason: 'pass 1 must use the complete conflict-deleting command',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          buildRunner,
          shortenedBuildRunner,
          source.indexOf(buildRunner) + buildRunner.length,
        ),
      ),
      isNotEmpty,
      reason: 'pass 2 must use the complete conflict-deleting command',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          '--delete-conflicting-outputs',
          '--delete-conflicting-output',
        ),
      ),
      isNotEmpty,
      reason: 'the conflict-deletion flag must remain exactly spelled',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          '  flutter gen-l10n\n  $buildRunner',
          '  $buildRunner\n  flutter gen-l10n',
        ),
      ),
      isNotEmpty,
      reason: 'a build cannot move before its pass l10n command',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          "  $buildRunner\n  assert_clean_generation_scope 'after generation pass 1'",
          "  assert_clean_generation_scope 'after generation pass 1'\n  $buildRunner",
        ),
      ),
      isNotEmpty,
      reason: 'each build must precede its own clean-scope assertion',
    );
    expect(
      _twoPassContractViolations(
        source.replaceFirst(
          "  assert_clean_generation_scope 'after generation pass 2'",
          "  $buildRunner\n  assert_clean_generation_scope 'after generation pass 2'",
        ),
      ),
      isNotEmpty,
      reason: 'a third complete build command is forbidden',
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
          'dart run import_lint',
          'dart run import_lint\n'
          'dart run import_lint',
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

  test('each generation boundary rejects untracked generated output', () {
    final source = File(_scriptPath).readAsStringSync();

    expect(_generatedOutputGuardViolations(source), isEmpty);
    expect(
      _generatedOutputGuardViolations(
        source.replaceFirst(
          'git ls-files --others --ignored --exclude-standard --',
          'git ls-files --others --exclude-standard --',
        ),
      ),
      isNotEmpty,
      reason: 'ignored generated output must not bypass the reproducibility gate',
    );
    expect(
      _generatedOutputGuardViolations(
        source.replaceFirst(
          "':(glob)lib/**/*.freezed.dart'",
          "':(glob)lib/**/*.not-generated.dart'",
        ),
      ),
      isNotEmpty,
      reason: 'new Freezed outputs must be rejected even when untracked',
    );
    expect(
      _generatedOutputGuardViolations(
        source.replaceFirst(
          'untracked_generation_outputs() {',
          r'''while IFS= read -r generated_file; do
  generation_scope+=("$generated_file")
done < <(git ls-files -- 'lib/**/*.g.dart')

untracked_generation_outputs() {''',
        ),
      ),
      isNotEmpty,
      reason: 'the generation scope cannot be captured before either pass runs',
    );
  });

  test('untracked-output probe catches ignored and non-ignored artifacts', () async {
    final fixture = await Directory.systemTemp.createTemp('codegen-output-');
    addTearDown(() => fixture.delete(recursive: true));

    await File('${fixture.path}/.gitignore').writeAsString('lib/generated/\n');
    for (final path in [
      'lib/generated/new_localization.dart',
      'lib/feature/new_provider.g.dart',
      'lib/feature/new_model.freezed.dart',
    ]) {
      final file = File('${fixture.path}/$path');
      await file.parent.create(recursive: true);
      await file.writeAsString('// fixture\n');
    }
    final init = await Process.run('git', ['init', '-q'], workingDirectory: fixture.path);
    expect(init.exitCode, 0, reason: init.stderr);
    final email = await Process.run(
      'git',
      ['config', 'user.email', 'codegen-fixture@example.invalid'],
      workingDirectory: fixture.path,
    );
    final name = await Process.run(
      'git',
      ['config', 'user.name', 'Codegen Fixture'],
      workingDirectory: fixture.path,
    );
    final add = await Process.run(
      'git',
      ['add', '.gitignore'],
      workingDirectory: fixture.path,
    );
    final commit = await Process.run(
      'git',
      ['commit', '-qm', 'fixture baseline'],
      workingDirectory: fixture.path,
    );
    expect(email.exitCode, 0, reason: email.stderr);
    expect(name.exitCode, 0, reason: name.stderr);
    expect(add.exitCode, 0, reason: add.stderr);
    expect(commit.exitCode, 0, reason: commit.stderr);

    final result = await Process.run('bash', [
      '-c',
      r'source "$1"; cd "$2"; untracked_generation_outputs',
      'codegen-output-probe',
      File(_scriptPath).absolute.path,
      fixture.path,
    ]);

    expect(result.exitCode, 0, reason: result.stderr);
    expect(
      result.stdout,
      contains('lib/generated/new_localization.dart'),
      reason: 'ignored localization output must still be reported',
    );
    expect(result.stdout, contains('lib/feature/new_provider.g.dart'));
    expect(result.stdout, contains('lib/feature/new_model.freezed.dart'));

    final gateResult = await Process.run('bash', [
      '-c',
      r'source "$1"; cd "$2"; assert_clean_generation_scope "after generation pass 2"',
      'codegen-gate-fixture',
      File(_scriptPath).absolute.path,
      fixture.path,
    ]);

    expect(gateResult.exitCode, 1);
    expect(gateResult.stderr, contains('Untracked generated output'));
    expect(
      gateResult.stderr,
      contains('Generator nondeterminism occurred on the second pass.'),
    );
  });
}
