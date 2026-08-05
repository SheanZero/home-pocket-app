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

        expect(checkProviderContract(providerScopeRoot.path).isPassing, isTrue);
        expect(checkProviderContract(uncontrolledRoot.path).isPassing, isTrue);
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
