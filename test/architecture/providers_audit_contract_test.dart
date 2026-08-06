import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/audit/provider_contract.dart';
import '../../scripts/audit/providers.dart' as providers;

void main() {
  test(
    'provider audit reports the owned defense-in-depth contract',
    () {
      final envelope = providers.buildProviderAuditEnvelope(
        const ProviderContractReport([]),
        generatedAt: DateTime.utc(2026, 8, 6),
      );

      expect(envelope['tool_source'], 'owned_provider_contract');
      expect(envelope['scan_state'], 'ran');
      expect(envelope['findings'], isEmpty);
    },
  );

  group('qualified Riverpod scope bindings', () {
    test('accepts an unshadowed qualified Riverpod alias', () {
      final report = _checkSource('''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void render() => runApp(
  riverpod.ProviderScope(child: const Placeholder()),
);
''');

      expect(report.violations, isEmpty, reason: report.describe());
    });

    test('fails closed when a qualified Riverpod alias is shadowed', () {
      final sources = <String>[
        '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

final riverpod = Object();
void render() => runApp(riverpod.ProviderScope(child: const Placeholder()));
''',
        '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void render() {
  final riverpod = Object();
  runApp(riverpod.ProviderScope(child: const Placeholder()));
}
''',
        '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void render() {
  var riverpod = Object();
  runApp(riverpod.ProviderScope(child: const Placeholder()));
}
''',
        '''
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

void render(dynamic riverpod) {
  runApp(riverpod.ProviderScope(child: const Placeholder()));
}
''',
      ];

      for (final source in sources) {
        final report = _checkSource(source);
        expect(
          report.violations.map((violation) => violation.code),
          contains('missing_provider_scope'),
          reason: report.describe(),
        );
      }
    });
  });
}

ProviderContractReport _checkSource(String source) {
  final root = Directory.systemTemp.createTempSync('provider_contract_test_');
  addTearDown(() => root.deleteSync(recursive: true));
  Directory('${root.path}/lib').createSync();
  File('${root.path}/analysis_options.yaml').writeAsStringSync('''
plugins:
  riverpod_lint: 3.1.4
''');
  File('${root.path}/pubspec.lock').writeAsStringSync('''
packages:
  riverpod_lint:
    dependency: "direct dev"
    description:
      name: riverpod_lint
      url: "https://pub.dev"
    source: hosted
    version: "3.1.4"
''');
  File('${root.path}/lib/fixture.dart').writeAsStringSync(source);
  return checkProviderContract(root.path);
}
