import 'dart:convert';
import 'dart:io';

typedef ToolingGuardCommand =
    Future<ToolingGuardCommandResult> Function(
      ToolingGuardCase guardCase,
      String workingDirectory,
    );

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
        name: 'import_guard package import',
        fixturePath:
            'lib/features/accounting/domain/phase58_package_import_fixture.dart',
        source:
            "import 'package:home_pocket/data/app_database.dart';\n\n"
            'void phase58ForbiddenPackageImport(AppDatabase database) {}\n',
        command: 'dart',
        arguments: const [
          'run',
          'custom_lint',
          '--format=json',
          '--no-fatal-infos',
        ],
        diagnosticCode: 'import_guard',
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

  const ToolingGuardCase.validProductionCustomLint()
    : this(
        name: 'valid production custom_lint',
        fixturePath: '',
        source: null,
        command: 'dart',
        arguments: const ['run', 'custom_lint', '--no-fatal-infos'],
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
    ToolingGuardCase.providerScopeControl(),
    ToolingGuardCase.providerScopeLocalCollision(),
    ToolingGuardCase.providerScopeImportedShadow(),
    ToolingGuardCase.providerScopeCommentLookalike(),
    ToolingGuardCase.providerScopeStringLookalike(),
    ToolingGuardCase.providerScopeUnrelatedAlias(),
  ],
  ToolingGuardCommand runCommand = runToolingGuardCommand,
  bool runValidTreeChecks = true,
  String workingDirectory = '.',
}) async {
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
}

const _validProductionCases = [
  ToolingGuardCase.validProductionAnalyzer(),
  ToolingGuardCase.validProductionCustomLint(),
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
    // The repository-owned scanner and Flutter test use text output instead
    // of custom_lint's JSON reporter. Their stable diagnostic code is still
    // required, so fall through to the text check below.
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
