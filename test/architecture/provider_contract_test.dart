import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/provider_contract.dart';

void main() {
  group('owned Riverpod provider contract', () {
    test('missing ProviderScope at an app root is rejected', () async {
      final root = await _createFixtureRoot(
        appSource: '''
import 'package:flutter/widgets.dart';

void main() => runApp(const Placeholder());
''',
      );
      addTearDown(() => root.delete(recursive: true));

      final report = checkProviderContract(root.path);

      expect(report.isPassing, isFalse);
      expect(report.describe(), contains('missing_provider_scope'));
      expect(report.describe(), contains('lib/main.dart:3'));
    });

    test(
      'ProviderScope and UncontrolledProviderScope app roots pass',
      () async {
        final providerScopeRoot = await _createFixtureRoot(
          appSource: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: Placeholder()));
''',
        );
        addTearDown(() => providerScopeRoot.delete(recursive: true));
        final uncontrolledRoot = await _createFixtureRoot(
          appSource: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(UncontrolledProviderScope(
  container: ProviderContainer(),
  child: const Placeholder(),
));
''',
        );
        addTearDown(() => uncontrolledRoot.delete(recursive: true));

        final providerScopeReport = checkProviderContract(
          providerScopeRoot.path,
        );
        final uncontrolledReport = checkProviderContract(uncontrolledRoot.path);
        expect(
          providerScopeReport.isPassing,
          isTrue,
          reason: providerScopeReport.describe(),
        );
        expect(
          uncontrolledReport.isPassing,
          isTrue,
          reason: uncontrolledReport.describe(),
        );
      },
    );

    test('only Riverpod-resolved root scope constructors pass', () async {
      final cases = <({String name, String source, bool passes})>[
        (
          name: 'local ProviderScope name collision',
          source: '''
import 'package:flutter/widgets.dart';

class ProviderScope extends Widget {
  const ProviderScope({required this.child});
  final Widget child;

  @override
  Element createElement() => throw UnimplementedError();
}

void main() => runApp(const ProviderScope(child: Placeholder()));
''',
          passes: false,
        ),
        (
          name: 'comment lookalike',
          source: '''
import 'package:flutter/widgets.dart';

void main() => runApp(/* ProviderScope(child: Placeholder()) */ const Placeholder());
''',
          passes: false,
        ),
        (
          name: 'string lookalike',
          source: '''
import 'package:flutter/widgets.dart';

void main() => runApp(const Placeholder(key: ValueKey('ProviderScope(')));
''',
          passes: false,
        ),
        (
          name: 'unrelated import alias',
          source: '''
import 'package:flutter/widgets.dart';
import 'package:unrelated/scopes.dart' as riverpod;

void main() => runApp(riverpod.ProviderScope(child: const Placeholder()));
''',
          passes: false,
        ),
        (
          name: 'Riverpod import alias',
          source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void main() => runApp(riverpod.ProviderScope(child: const Placeholder()));
''',
          passes: true,
        ),
        (
          name: 'Riverpod show import',
          source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;

void main() => runApp(const ProviderScope(child: Placeholder()));
''',
          passes: true,
        ),
      ];

      for (final fixture in cases) {
        final root = await _createFixtureRoot(appSource: fixture.source);
        addTearDown(() => root.delete(recursive: true));

        final report = checkProviderContract(root.path);

        expect(
          report.isPassing,
          fixture.passes,
          reason: '${fixture.name}: ${report.describe()}',
        );
      }
    });

    test(
      'unqualified Riverpod scopes fail closed when locally shadowed',
      () async {
        final cases = <({String name, String source})>[
          (
            name: 'top-level final variable',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ProviderScope = ({required Widget child}) => child;

void main() => runApp(ProviderScope(child: const Placeholder()));
''',
          ),
          (
            name: 'typed local variable',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  dynamic ProviderScope = ({required Widget child}) => child;
  runApp(ProviderScope(child: const Placeholder()));
}
''',
          ),
          (
            name: 'top-level function',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Widget ProviderScope({required Widget child}) => child;

void main() => runApp(ProviderScope(child: const Placeholder()));
''',
          ),
          (
            name: 'local class',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProviderScope extends Widget {
  const ProviderScope({required this.child});
  final Widget child;

  @override
  Element createElement() => throw UnimplementedError();
}

void main() => runApp(const ProviderScope(child: Placeholder()));
''',
          ),
          (
            name: 'typedef',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef ProviderScope = Widget Function({required Widget child});

void main() => runApp(ProviderScope(child: const Placeholder()));
''',
          ),
          (
            name: 'lexical parameter',
            source: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  root(ProviderScope) {
    runApp(ProviderScope(child: const Placeholder()));
  }
}
''',
          ),
        ];

        for (final fixture in cases) {
          final root = await _createFixtureRoot(appSource: fixture.source);
          addTearDown(() => root.delete(recursive: true));

          final report = checkProviderContract(root.path);

          expect(
            report.isPassing,
            isFalse,
            reason: '${fixture.name}: ${report.describe()}',
          );
        }
      },
    );

    test(
      'qualified Riverpod scopes ignore unqualified local shadows',
      () async {
        final root = await _createFixtureRoot(
          appSource: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

final ProviderScope = ({required Widget child}) => child;

void main() =>
    runApp(riverpod.ProviderScope(child: const Placeholder()));
''',
        );
        addTearDown(() => root.delete(recursive: true));

        final report = checkProviderContract(root.path);

        expect(report.isPassing, isTrue, reason: report.describe());
      },
    );

    test('the production lib tree satisfies the owned provider contract', () {
      final report = checkProviderContract('.');

      expect(report.isPassing, isTrue, reason: report.describe());
    });

    test('active or unparseable riverpod_lint state fails closed', () async {
      final root = await _createFixtureRoot(
        appSource: '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() => runApp(const ProviderScope(child: Placeholder()));
''',
        analysisOptions: '''
analyzer:
  plugins:
    - custom_lint
    - riverpod_lint
''',
        lockfile: 'packages:\n  riverpod_lint:\n    version: "bad"\n',
      );
      addTearDown(() => root.delete(recursive: true));

      final report = checkProviderContract(root.path);

      expect(report.isPassing, isFalse);
      expect(report.describe(), contains('riverpod_lint_active'));
      expect(report.describe(), contains('riverpod_lint_version_unparseable'));
    });
  });
}

Future<Directory> _createFixtureRoot({
  required String appSource,
  String analysisOptions = '''
analyzer:
  plugins:
    - custom_lint
''',
  String lockfile = '''
packages:
  riverpod_lint:
    version: "3.1.0"
''',
}) async {
  final root = await Directory.systemTemp.createTemp('provider_contract_test_');
  final lib = Directory('${root.path}/lib')..createSync();
  await File('${lib.path}/main.dart').writeAsString(appSource);
  await File(
    '${root.path}/analysis_options.yaml',
  ).writeAsString(analysisOptions);
  await File('${root.path}/pubspec.lock').writeAsString(lockfile);
  return root;
}
