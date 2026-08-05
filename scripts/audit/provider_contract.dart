import 'dart:io';

/// Repository-owned Riverpod checks for the analyzer-8 production graph.
///
/// `riverpod_lint` 3.1.0 remains locked as a compatibility hold, but is not an
/// active analysis-server plugin on Flutter 3.44.8. This contract protects the
/// app-root invariant without treating an unloaded upstream plugin as green.
class ProviderContractViolation {
  const ProviderContractViolation({
    required this.code,
    required this.path,
    required this.line,
    required this.message,
  });

  final String code;
  final String path;
  final int line;
  final String message;

  @override
  String toString() => '$path:$line $code: $message';
}

class ProviderContractReport {
  const ProviderContractReport(this.violations);

  final List<ProviderContractViolation> violations;

  bool get isPassing => violations.isEmpty;

  String describe() => violations.join('\n');
}

ProviderContractReport checkProviderContract(String rootPath) {
  final root = Directory(rootPath).absolute;
  final violations = <ProviderContractViolation>[];
  _checkAppRoots(root, violations);
  _checkRiverpodLintHold(root, violations);
  return ProviderContractReport(violations);
}

void _checkAppRoots(
  Directory root,
  List<ProviderContractViolation> violations,
) {
  final lib = Directory('${root.path}/lib');
  if (!lib.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'provider_contract_lib_missing',
        path: 'lib',
        line: 1,
        message: 'Cannot inspect app roots because lib/ is missing.',
      ),
    );
    return;
  }

  for (final file in lib.listSync(recursive: true).whereType<File>()) {
    if (!file.path.endsWith('.dart') ||
        file.path.endsWith('.g.dart') ||
        file.path.endsWith('.freezed.dart') ||
        file.path.contains(
          '${Platform.pathSeparator}generated${Platform.pathSeparator}',
        )) {
      continue;
    }
    final source = file.readAsStringSync();
    final path = _relativePath(root, file);
    for (final call in _findCalls(source, 'runApp')) {
      if (_isScopedRoot(call.argument)) continue;
      violations.add(
        ProviderContractViolation(
          code: 'missing_provider_scope',
          path: path,
          line: _lineAt(source, call.offset),
          message:
              'runApp root must be wrapped by ProviderScope or UncontrolledProviderScope.',
        ),
      );
    }

    // Happy Pocket initializes a prebuilt ProviderContainer before rendering;
    // its app-root seam is the AppRunner callback rather than a direct runApp.
    if (path == 'lib/main.dart' &&
        source.contains('typedef AppRunner') &&
        !_hasScopedAppRunner(source)) {
      violations.add(
        const ProviderContractViolation(
          code: 'missing_provider_scope',
          path: 'lib/main.dart',
          line: 1,
          message:
              'AppRunner success root must use UncontrolledProviderScope with the initialized container.',
        ),
      );
    }
  }
}

void _checkRiverpodLintHold(
  Directory root,
  List<ProviderContractViolation> violations,
) {
  final options = File('${root.path}/analysis_options.yaml');
  if (!options.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_hold_unverifiable',
        path: 'analysis_options.yaml',
        line: 1,
        message:
            'Missing analysis options; cannot verify the riverpod_lint hold.',
      ),
    );
  } else {
    final source = options.readAsStringSync();
    final activePlugin = RegExp(
      r'^\s*(?:-\s*riverpod_lint|riverpod_lint\s*:)\s*(?:#.*)?$',
      multiLine: true,
    ).firstMatch(source);
    if (activePlugin != null) {
      violations.add(
        ProviderContractViolation(
          code: 'riverpod_lint_active',
          path: 'analysis_options.yaml',
          line: _lineAt(source, activePlugin.start),
          message:
              'riverpod_lint is held on Flutter 3.44.8/analyzer 8 and must not be configured as an active plugin without a passing bad/control probe.',
        ),
      );
    }
  }

  final lockfile = File('${root.path}/pubspec.lock');
  if (!lockfile.existsSync()) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_version_unparseable',
        path: 'pubspec.lock',
        line: 1,
        message:
            'Missing lockfile; cannot verify the held riverpod_lint version.',
      ),
    );
    return;
  }

  final lockSource = lockfile.readAsStringSync();
  final package = RegExp(
    r'^  riverpod_lint:\s*$',
    multiLine: true,
  ).firstMatch(lockSource);
  final afterPackage = package == null ? '' : lockSource.substring(package.end);
  final nextPackage = RegExp(r'\n  \S').firstMatch(afterPackage);
  final packageSection = nextPackage == null
      ? afterPackage
      : afterPackage.substring(0, nextPackage.start);
  final version = package == null
      ? null
      : RegExp(
          r'''^    version:\s*["']([^"']+)["']\s*$''',
          multiLine: true,
        ).firstMatch(packageSection)?.group(1);
  if (version == null ||
      !RegExp(r'^\d+\.\d+\.\d+(?:\+\d+)?$').hasMatch(version)) {
    violations.add(
      const ProviderContractViolation(
        code: 'riverpod_lint_version_unparseable',
        path: 'pubspec.lock',
        line: 1,
        message: 'Held riverpod_lint version is missing or not parseable.',
      ),
    );
  } else if (version != '3.1.0') {
    violations.add(
      ProviderContractViolation(
        code: 'riverpod_lint_version_mismatch',
        path: 'pubspec.lock',
        line: _lineAt(lockSource, package!.start),
        message:
            'Expected held riverpod_lint 3.1.0 for the analyzer-8 graph, found $version.',
      ),
    );
  }
}

bool _hasScopedAppRunner(String source) {
  for (final call in _findCalls(source, 'appRunner')) {
    if (call.argument.contains('UncontrolledProviderScope(')) return true;
  }
  return false;
}

bool _isScopedRoot(String argument) =>
    argument.contains('ProviderScope(') ||
    argument.contains('UncontrolledProviderScope(');

List<_Call> _findCalls(String source, String name) {
  final calls = <_Call>[];
  final matcher = RegExp('\\b$name\\s*\\(');
  for (final match in matcher.allMatches(source)) {
    final open = source.indexOf('(', match.start);
    final close = _matchingParen(source, open);
    if (close == null) continue;
    calls.add(_Call(match.start, source.substring(open + 1, close)));
  }
  return calls;
}

int? _matchingParen(String source, int open) {
  var depth = 0;
  for (var index = open; index < source.length; index++) {
    final char = source[index];
    if (char == '(') depth++;
    if (char == ')') {
      depth--;
      if (depth == 0) return index;
    }
  }
  return null;
}

int _lineAt(String source, int offset) =>
    1 + '\n'.allMatches(source.substring(0, offset)).length;

String _relativePath(Directory root, File file) {
  final prefix = '${root.path}${Platform.pathSeparator}';
  return file.path.startsWith(prefix)
      ? file.path.substring(prefix.length).replaceAll('\\', '/')
      : file.path.replaceAll('\\', '/');
}

class _Call {
  const _Call(this.offset, this.argument);

  final int offset;
  final String argument;
}

void main() {
  final report = checkProviderContract('.');
  if (report.isPassing) {
    stdout.writeln('[provider-contract] PASS owned provider contract');
    return;
  }
  for (final violation in report.violations) {
    stderr.writeln('[provider-contract] $violation');
  }
  exitCode = 1;
}
