import 'dart:async';
import 'dart:convert';
import 'dart:io';

typedef ToolingGuardCommand =
    Future<ToolingGuardCommandResult> Function(
      ToolingGuardCase guardCase,
      String workingDirectory,
    );

Future<void> _toolingGuardFixtureQueue = Future<void>.value();

/// Serializes complete fixture transactions in-process and across processes.
/// The persistent lock coordinate is intentionally kept under ignored
/// `.dart_tool`; ownership of scanned `lib/` sentinels never escapes this
/// callback.
Future<T> withToolingGuardFixtureLock<T>(
  Future<T> Function() action, {
  String workingDirectory = '.',
}) async {
  final previous = _toolingGuardFixtureQueue;
  final releaseQueue = Completer<void>();
  _toolingGuardFixtureQueue = releaseQueue.future;
  await previous;

  final root = Directory(workingDirectory).absolute;
  final lock = File('${root.path}/.dart_tool/phase58_tooling_guard.lock');
  final handle = await lock.open(mode: FileMode.append);
  try {
    await handle.lock(FileLock.blockingExclusive);
    return await action();
  } finally {
    try {
      await handle.unlock();
    } finally {
      await handle.close();
      releaseQueue.complete();
    }
  }
}

class ToolingGuardCase {
  const ToolingGuardCase({
    required this.name,
    required this.fixturePath,
    required this.source,
    required this.command,
    required this.arguments,
    this.diagnosticCode,
    this.expectFailure = true,
    this.expectsFixturePath = true,
    this.detectPluginFailure = false,
  });

  const ToolingGuardCase.importGuardPackage()
    : this(
        name: 'import_lint package import',
        fixturePath:
            'lib/features/accounting/domain/models/phase58_package_import_fixture.dart',
        source:
            "import 'package:home_pocket/data/app_database.dart';\n\n"
            'void phase58ForbiddenPackageImport(AppDatabase database) {}\n',
        command: 'dart',
        arguments: const ['run', 'import_lint'],
        diagnosticCode: 'domain_to_data',
      );

  const ToolingGuardCase.layerScannerPackage()
    : this(
        name: 'layer scanner package import',
        fixturePath:
            'lib/features/accounting/domain/phase58_scanner_package_import_fixture.dart',
        source:
            "import 'package:home_pocket/data/app_database.dart';\n\n"
            'void phase58ForbiddenScannerPackageImport(AppDatabase database) {}\n',
        command: 'flutter',
        arguments: const [
          'test',
          'test/architecture/layer_import_rules_test.dart',
        ],
        diagnosticCode: 'domain must be independent',
      );

  const ToolingGuardCase.layerScannerRelative()
    : this(
        name: 'layer scanner relative import',
        fixturePath:
            'lib/features/accounting/domain/phase58_scanner_relative_import_fixture.dart',
        source:
            "import '../../../data/app_database.dart';\n\n"
            'void phase58ForbiddenScannerRelativeImport(AppDatabase database) {}\n',
        command: 'flutter',
        arguments: const [
          'test',
          'test/architecture/layer_import_rules_test.dart',
        ],
        diagnosticCode: 'domain must be independent',
      );

  const ToolingGuardCase.providerScopeMissing()
    : this(
        name: 'provider app root without scope',
        fixturePath: 'lib/phase58_provider_scope_bad_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n\n"
            'void phase58BadProviderRoot() => runApp(const Placeholder());\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeQualifiedRunAppMissing()
    : this(
        name: 'qualified Flutter provider app root without scope',
        fixturePath:
            'lib/phase58_provider_scope_qualified_run_app_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart' as widgets;\n\n"
            'void phase58QualifiedBadProviderRoot() =>\n'
            '    widgets.runApp(const widgets.Placeholder());\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeControl()
    : this(
        name: 'provider app root scope control',
        fixturePath: 'lib/phase58_provider_scope_control_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
            'void phase58ProviderRootControl() =>\n'
            '    runApp(const ProviderScope(child: Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        expectFailure: false,
        expectsFixturePath: false,
      );

  const ToolingGuardCase.providerScopeLocalCollision()
    : this(
        name: 'provider app root local ProviderScope collision',
        fixturePath: 'lib/phase58_provider_scope_local_collision_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n\n"
            'class ProviderScope extends Widget {\n'
            '  const ProviderScope({required this.child});\n'
            '  final Widget child;\n'
            '  @override\n'
            '  Element createElement() => throw UnimplementedError();\n'
            '}\n\n'
            'void phase58LocalCollision() =>\n'
            '    runApp(const ProviderScope(child: Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeImportedShadow()
    : this(
        name: 'provider app root imported ProviderScope shadow',
        fixturePath: 'lib/phase58_provider_scope_imported_shadow_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
            'final ProviderScope = ({required Widget child}) => child;\n\n'
            'void phase58ImportedShadow() =>\n'
            '    runApp(ProviderScope(child: const Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeCommentLookalike()
    : this(
        name: 'provider app root comment lookalike',
        fixturePath: 'lib/phase58_provider_scope_comment_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n\n"
            'void phase58CommentLookalike() =>\n'
            '    runApp(/* ProviderScope(child: Placeholder()) */ const Placeholder());\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeStringLookalike()
    : this(
        name: 'provider app root string lookalike',
        fixturePath: 'lib/phase58_provider_scope_string_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n\n"
            'void phase58StringLookalike() =>\n'
            "    runApp(const Placeholder(key: ValueKey('ProviderScope(')));\n",
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeUnrelatedAlias()
    : this(
        name: 'provider app root unrelated import alias',
        fixturePath: 'lib/phase58_provider_scope_unrelated_alias_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:unrelated/scopes.dart' as riverpod;\n\n"
            'void phase58UnrelatedAlias() =>\n'
            '    runApp(riverpod.ProviderScope(child: const Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeQualifiedAliasShadow()
    : this(
        name: 'provider app root qualified alias shadow',
        fixturePath:
            'lib/phase58_provider_scope_qualified_alias_shadow_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;\n\n"
            'void phase58QualifiedAliasShadow(dynamic riverpod) {\n'
            '  runApp(riverpod.ProviderScope(child: const Placeholder()));\n'
            '}\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeRecordPatternAliasShadow()
    : this(
        name: 'provider app root record-pattern alias shadow',
        fixturePath:
            'lib/phase58_provider_scope_record_pattern_alias_shadow_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;\n\n"
            'final Type importedProviderScopeType = riverpod.ProviderScope;\n\n'
            'class FakeNamespace {\n'
            '  Widget ProviderScope({required Widget child}) => child;\n'
            '}\n\n'
            'void phase58RecordPatternAliasShadow() {\n'
            '  final (riverpod, _) = (FakeNamespace(), 0);\n'
            '  runApp(riverpod.ProviderScope(child: const Placeholder()));\n'
            '}\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeExtensionTypeShadow()
    : this(
        name: 'provider app root extension-type constructor shadow',
        fixturePath:
            'lib/phase58_provider_scope_extension_type_shadow_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart';\n\n"
            'final ProviderContainer importedContainer = ProviderContainer();\n\n'
            'extension type ProviderScope._(Widget _widget) implements Widget {}\n\n'
            'void phase58ExtensionTypeShadow() =>\n'
            '    runApp(ProviderScope._(const Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        diagnosticCode: 'missing_provider_scope',
      );

  const ToolingGuardCase.providerScopeExtensionTypeAliasControl()
    : this(
        // A top-level `extension type riverpod` cannot coexist with an
        // `as riverpod` import prefix in valid Dart. Keep this companion
        // fixture compilable while proving an extension-type declaration does
        // not incorrectly shadow a real qualified Riverpod import.
        name: 'provider app root extension-type alias control',
        fixturePath:
            'lib/phase58_provider_scope_extension_type_alias_shadow_fixture.dart',
        source:
            "import 'package:flutter/widgets.dart';\n"
            "import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;\n\n"
            'extension type ProviderScope._(Widget _widget) implements Widget {}\n\n'
            'void phase58ExtensionTypeAliasShadow() =>\n'
            '    runApp(riverpod.ProviderScope(child: const Placeholder()));\n',
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        expectFailure: false,
        expectsFixturePath: false,
      );

  const ToolingGuardCase.validProductionAnalyzer()
    : this(
        name: 'valid production flutter analyze',
        fixturePath: '',
        source: null,
        command: 'flutter',
        arguments: const ['analyze', '--no-fatal-infos'],
        expectFailure: false,
        expectsFixturePath: false,
        detectPluginFailure: true,
      );

  const ToolingGuardCase.validProductionImportLint()
    : this(
        name: 'valid production import_lint',
        fixturePath: '',
        source: null,
        command: 'dart',
        arguments: const ['run', 'import_lint'],
        expectFailure: false,
        expectsFixturePath: false,
        detectPluginFailure: true,
      );

  const ToolingGuardCase.validProductionLayerScanner()
    : this(
        name: 'valid production layer scanner',
        fixturePath: '',
        source: null,
        command: 'flutter',
        arguments: const [
          'test',
          'test/architecture/layer_import_rules_test.dart',
        ],
        expectFailure: false,
        expectsFixturePath: false,
      );

  const ToolingGuardCase.validProductionProviderContract()
    : this(
        name: 'valid production provider contract',
        fixturePath: '',
        source: null,
        command: 'dart',
        arguments: const ['run', 'scripts/audit/provider_contract.dart'],
        expectFailure: false,
        expectsFixturePath: false,
        detectPluginFailure: true,
      );

  final String name;
  final String fixturePath;
  final String? source;
  final String command;
  final List<String> arguments;
  final String? diagnosticCode;
  final bool expectFailure;
  final bool expectsFixturePath;
  final bool detectPluginFailure;
}

class ToolingGuardCommandResult {
  const ToolingGuardCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;

  String get combinedOutput => '$stdout\n$stderr';
}

class ToolingGuardCaseResult {
  const ToolingGuardCaseResult({
    required this.guardCase,
    required this.messages,
    required this.output,
  });

  final ToolingGuardCase guardCase;
  final List<String> messages;
  final String output;

  bool get isPassing => messages.isEmpty;
}

class ToolingGuardResult {
  const ToolingGuardResult(this.cases);

  final List<ToolingGuardCaseResult> cases;

  bool get isPassing => cases.every((result) => result.isPassing);

  String describe() => cases.expand((result) => result.messages).join('\n');
}

Future<ToolingGuardCommandResult> runToolingGuardCommand(
  ToolingGuardCase guardCase,
  String workingDirectory,
) async {
  final result = await Process.run(
    guardCase.command,
    guardCase.arguments,
    workingDirectory: workingDirectory,
  );
  return ToolingGuardCommandResult(
    exitCode: result.exitCode,
    stdout: result.stdout.toString(),
    stderr: result.stderr.toString(),
  );
}

Future<ToolingGuardResult> verifyToolingGuards({
  List<ToolingGuardCase> cases = const [
    ToolingGuardCase.importGuardPackage(),
    ToolingGuardCase.layerScannerPackage(),
    ToolingGuardCase.layerScannerRelative(),
    ToolingGuardCase.providerScopeMissing(),
    ToolingGuardCase.providerScopeQualifiedRunAppMissing(),
    ToolingGuardCase.providerScopeControl(),
    ToolingGuardCase.providerScopeLocalCollision(),
    ToolingGuardCase.providerScopeImportedShadow(),
    ToolingGuardCase.providerScopeCommentLookalike(),
    ToolingGuardCase.providerScopeStringLookalike(),
    ToolingGuardCase.providerScopeUnrelatedAlias(),
    ToolingGuardCase.providerScopeQualifiedAliasShadow(),
    ToolingGuardCase.providerScopeRecordPatternAliasShadow(),
    ToolingGuardCase.providerScopeExtensionTypeShadow(),
    ToolingGuardCase.providerScopeExtensionTypeAliasControl(),
  ],
  ToolingGuardCommand runCommand = runToolingGuardCommand,
  bool runValidTreeChecks = true,
  String workingDirectory = '.',
}) async {
  return withToolingGuardFixtureLock(() async {
    final root = Directory(workingDirectory).absolute;
    final stale = <ToolingGuardCaseResult>[];
    for (final guardCase in cases) {
      if (guardCase.source != null &&
          File('${root.path}/${guardCase.fixturePath}').existsSync()) {
        stale.add(
          ToolingGuardCaseResult(
            guardCase: guardCase,
            messages: ['pre-existing fixture: ${guardCase.fixturePath}'],
            output: '',
          ),
        );
      }
    }
    if (stale.isNotEmpty) return ToolingGuardResult(stale);

    final results = <ToolingGuardCaseResult>[];
    for (final guardCase in cases) {
      results.add(await _verifyCase(guardCase, root.path, runCommand));
    }
    if (runValidTreeChecks) {
      for (final guardCase in _validProductionCases) {
        results.add(await _verifyCase(guardCase, root.path, runCommand));
      }
    }
    return ToolingGuardResult(results);
  }, workingDirectory: workingDirectory);
}

const _validProductionCases = [
  ToolingGuardCase.validProductionAnalyzer(),
  ToolingGuardCase.validProductionImportLint(),
  ToolingGuardCase.validProductionLayerScanner(),
  ToolingGuardCase.validProductionProviderContract(),
];

Future<ToolingGuardCaseResult> _verifyCase(
  ToolingGuardCase guardCase,
  String workingDirectory,
  ToolingGuardCommand runCommand,
) async {
  final fixture = guardCase.source == null
      ? null
      : File('$workingDirectory/${guardCase.fixturePath}');
  final messages = <String>[];
  var output = '';
  try {
    if (fixture != null) {
      await fixture.writeAsString(guardCase.source!, flush: true);
    }
    final commandResult = await runCommand(guardCase, workingDirectory);
    output = commandResult.combinedOutput;
    if (guardCase.expectFailure && commandResult.exitCode == 0) {
      messages.add('${guardCase.name}: expected a nonzero exit');
    }
    if (!guardCase.expectFailure && commandResult.exitCode != 0) {
      messages.add(
        '${guardCase.name}: expected a zero exit, got ${commandResult.exitCode}',
      );
    }
    if (guardCase.diagnosticCode != null &&
        !_hasDiagnostic(output, guardCase.diagnosticCode!)) {
      messages.add(
        '${guardCase.name}: missing diagnostic ${guardCase.diagnosticCode}',
      );
    }
    if (guardCase.expectsFixturePath &&
        !_hasFixturePath(output, guardCase.fixturePath)) {
      messages.add(
        '${guardCase.name}: missing fixture ${guardCase.fixturePath}',
      );
    }
    if (guardCase.detectPluginFailure && _hasPluginFailure(output)) {
      messages.add('${guardCase.name}: analyzer plugin failure detected');
    }
  } on ProcessException catch (error) {
    messages.add('${guardCase.name}: command spawn failed: ${error.message}');
  } on FileSystemException catch (error) {
    messages.add('${guardCase.name}: fixture write failed: ${error.message}');
  } finally {
    try {
      if (fixture?.existsSync() ?? false) await fixture!.delete();
    } on FileSystemException catch (error) {
      messages.add('${guardCase.name}: cleanup failed: ${error.message}');
    }
  }
  return ToolingGuardCaseResult(
    guardCase: guardCase,
    messages: messages,
    output: output,
  );
}

bool _hasDiagnostic(String output, String diagnosticCode) {
  try {
    final decoded = jsonDecode(output);
    final diagnostics = decoded is Map<String, dynamic>
        ? decoded['diagnostics']
        : null;
    if (diagnostics is List) {
      return diagnostics.any(
        (diagnostic) =>
            diagnostic is Map && diagnostic['code'] == diagnosticCode,
      );
    }
  } on FormatException {
    // import_lint, the repository-owned scanner, and Flutter tests use text
    // output. Their stable rule/diagnostic code is still required below.
  }
  return output.contains(diagnosticCode);
}

bool _hasFixturePath(String output, String fixturePath) {
  final normalizedPath = fixturePath.replaceAll('\\', '/');
  return output.replaceAll('\\', '/').contains(normalizedPath);
}

bool _hasPluginFailure(String output) => RegExp(
  r'PluginException|PluginEx|UNKNOWN_REQUEST|(?:unable|failed)\s+to\s+parse[^\n]*version',
  caseSensitive: false,
).hasMatch(output);

Future<void> main() async {
  final result = await verifyToolingGuards();
  for (final caseResult in result.cases) {
    final status = caseResult.isPassing ? 'PASS' : 'FAIL';
    stdout.writeln('[tooling-guards] $status ${caseResult.guardCase.name}');
    if (!caseResult.isPassing) stderr.writeln(caseResult.messages.join('\n'));
  }
  if (!result.isPassing) exitCode = 1;
}
