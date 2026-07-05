import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Layer-dependency rules enforced on REAL import statements.
///
/// The import_guard custom_lint deny rules match import URIs against
/// `package:home_pocket/...` prefixes verbatim, but this repo enforces
/// `prefer_relative_imports` — so every deny-mode guard is inert for
/// intra-project imports (quality report P1-2). This test closes that hole:
/// it scans every hand-written file under lib/, resolves relative imports to
/// lib-rooted paths, and asserts the dependency directions from CLAUDE.md
/// (Presentation → Application → Domain ← Data ← Infrastructure).
///
/// Rules ("outer layers depend on inner, never reverse" — domain is the
/// innermost circle, so ANY layer may import lib/features/*/domain/**):
///   1. lib/infrastructure/** must not import lib/application/** or any
///      non-domain part of lib/features/** (infrastructure provides
///      technology; it must not know about business logic or UI).
///   2. lib/application/** must not import lib/features/*/presentation/**
///      (use cases depend on domain interfaces, never on UI/wiring).
///   3. lib/features/*/domain/** must not import lib/data/**,
///      lib/infrastructure/**, lib/application/**, or any presentation/**
///      (domain is fully independent).
///
/// To grant a deliberate exception, add the lib-rooted file path to
/// [_allowlist] with a justification comment.
const Set<String> _allowlist = {
  // (empty — no sanctioned violations)
};

class _Violation {
  _Violation(this.file, this.import, this.rule);

  final String file;
  final String import;
  final String rule;

  @override
  String toString() => '$file → $import ($rule)';
}

void main() {
  test('layer dependency directions hold on real imports', () {
    final violations = <_Violation>[];

    for (final entry in _libDartFiles()) {
      final filePath = entry.key; // lib-rooted, e.g. lib/data/app_database.dart
      if (_allowlist.contains(filePath)) continue;

      for (final import in entry.value) {
        final target = _resolveToLibPath(filePath, import);
        if (target == null) continue; // dart: or third-party package

        for (final rule in _rules) {
          if (rule.appliesTo(filePath) && rule.forbids(target)) {
            violations.add(_Violation(filePath, target, rule.name));
          }
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Layer violations (import_guard deny rules do not catch relative '
          'imports — this test is the enforcement point):\n'
          '${violations.join('\n')}',
    );
  });
}

class _Rule {
  const _Rule(this.name, this.appliesTo, this.forbids);

  final String name;
  final bool Function(String file) appliesTo;
  final bool Function(String target) forbids;
}

final _presentationDir = RegExp(r'^lib/features/[^/]+/presentation/');
final _domainDir = RegExp(r'^lib/features/[^/]+/domain/');

final List<_Rule> _rules = [
  _Rule(
    'infrastructure must not depend on application or feature presentation',
    (f) => f.startsWith('lib/infrastructure/'),
    (t) =>
        t.startsWith('lib/application/') ||
        (t.startsWith('lib/features/') && !_domainDir.hasMatch(t)),
  ),
  _Rule(
    'application must not depend on presentation',
    (f) => f.startsWith('lib/application/'),
    (t) => _presentationDir.hasMatch(t),
  ),
  _Rule(
    'domain must be independent',
    (f) => _domainDir.hasMatch(f),
    (t) =>
        t.startsWith('lib/data/') ||
        t.startsWith('lib/infrastructure/') ||
        t.startsWith('lib/application/') ||
        _presentationDir.hasMatch(t),
  ),
];

final _importPattern = RegExp(
  '''^import\\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

/// Yields (lib-rooted path, import strings) for every hand-written Dart file.
Iterable<MapEntry<String, List<String>>> _libDartFiles() sync* {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where(
        (f) =>
            f.path.endsWith('.dart') &&
            !f.path.endsWith('.g.dart') &&
            !f.path.endsWith('.freezed.dart') &&
            !f.path.startsWith('lib/generated/'),
      );
  for (final file in files) {
    final imports = _importPattern
        .allMatches(file.readAsStringSync())
        .map((m) => m.group(1)!)
        .toList();
    yield MapEntry(file.path, imports);
  }
}

/// Resolves [import] (as written in [fromFile]) to a lib-rooted path, or null
/// for dart:/third-party imports.
String? _resolveToLibPath(String fromFile, String import) {
  if (import.startsWith('package:home_pocket/')) {
    return 'lib/${import.substring('package:home_pocket/'.length)}';
  }
  if (import.startsWith('package:') || import.startsWith('dart:')) {
    return null;
  }
  // Relative import: resolve against the importing file's directory.
  final baseSegments = fromFile.split('/')..removeLast();
  final segments = [...baseSegments];
  for (final part in import.split('/')) {
    if (part == '..') {
      segments.removeLast();
    } else if (part != '.') {
      segments.add(part);
    }
  }
  return segments.join('/');
}
