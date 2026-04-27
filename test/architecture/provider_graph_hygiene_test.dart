import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: Provider graph hygiene invariants.
///
/// Closes HIGH-04, HIGH-05, HIGH-06 (Phase 4 close gate).
/// See CONTEXT.md D-07 and Plan 04-05 for the full decision log.
///
/// This test is Phase 4's "alarm against future regression" for the provider
/// graph — mirrors Phase 3 D-17's import_guard blocking flip for layer rules.
///
/// Run: flutter test test/architecture/provider_graph_hygiene_test.dart

const _features = [
  'accounting',
  'analytics',
  'dual_ledger',
  'family_sync',
  'home',
  'profile',
  'settings',
];

/// HIGH-05 keepAlive hard list (post-Phase-4 names).
///
/// All 5 providers below MUST have @Riverpod(keepAlive: true) in lib/.
/// Reconciliations per D-07.4 and Plan 04-05:
///   - activeGroupMembersProvider: renamed from groupMembers (Task 1)
///   - appMerchantDatabaseProvider: app-prefixed per Plan 04-01 Task 2 Warning 7
const _expectedKeepAliveProviders = [
  'syncEngineProvider',
  'transactionChangeTrackerProvider',
  'appMerchantDatabaseProvider', // `app` prefix per Plan 04-01 Task 2 (Warning 7)
  'activeGroupProvider',
  'activeGroupMembersProvider', // renamed from groupMembers (Task 1 reconciliation)
];

void main() {
  group('Provider graph hygiene', () {
    test(
      'HIGH-04 structure: each feature has exactly one repository_providers.dart and only state_*.dart siblings',
      () {
        for (final feature in _features) {
          final dir = Directory('lib/features/$feature/presentation/providers');
          if (!dir.existsSync()) {
            continue; // some features may not have providers/
          }
          final files = dir
              .listSync()
              .whereType<File>()
              .map((f) => f.uri.pathSegments.last)
              .where((n) => !n.endsWith('.g.dart'))
              .toList();
          final repos = files.where((n) => n == 'repository_providers.dart');
          expect(
            repos.length,
            lessThanOrEqualTo(1),
            reason:
                'feature $feature: expected at most 1 repository_providers.dart, found ${repos.length}',
          );
          for (final n in files.where(
            (n) => n != 'repository_providers.dart',
          )) {
            expect(
              n.startsWith('state_'),
              isTrue,
              reason:
                  'feature $feature: $n is not a state_*.dart (HIGH-04 violation)',
            );
          }
        }
      },
    );

    test(
      'HIGH-04 DI consolidation: Repository/UseCase/Service-suffix providers live only in repository_providers.dart',
      () {
        final violations = <String>[];
        for (final feature in _features) {
          final dir = Directory('lib/features/$feature/presentation/providers');
          if (!dir.existsSync()) continue;
          for (final f in dir.listSync().whereType<File>()) {
            final name = f.uri.pathSegments.last;
            if (name == 'repository_providers.dart' ||
                name.endsWith('.g.dart')) {
              continue;
            }
            final src = f.readAsStringSync();
            final diMatches = RegExp(
              r'@riverpod[\s\S]{0,200}\b(\w+)(Repository|UseCase|Service)\b\s+\w+\(',
            ).allMatches(src);
            for (final m in diMatches) {
              violations.add('${f.path}: ${m.group(0)}');
            }
          }
        }
        expect(
          violations,
          isEmpty,
          reason:
              'DI providers found outside repository_providers.dart:\n${violations.join("\n")}',
        );
      },
    );

    test(
      'HIGH-04 global uniqueness: no duplicate @riverpod function names within lib/features/',
      () {
        // Scope: lib/features/ only. The lib/application/ layer deliberately
        // uses per-feature re-export providers (e.g., appAppDatabaseProvider)
        // that share a function name across sub-modules. This is intentional
        // (Plan 04-01 pattern) — each is a separate Provider object imported
        // via as-prefix aliases. Feature-side uniqueness is what we enforce
        // because two features cannot safely define the same provider name
        // when both are imported into a single presentation file.
        final names = <String, List<String>>{};
        for (final entity in Directory(
          'lib/features',
        ).listSync(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.endsWith('.g.dart')) {
            final src = entity.readAsStringSync();
            // Match: @riverpod\n[type] funcName(Ref ref) — captures funcName
            final matches = RegExp(
              r'@(?:R|r)iverpod(?:\([^)]*\))?\s*(?://[^\n]*\n)*\s*\w[\w<>?, ]*\s+(\w+)\s*\(\s*Ref\b',
            ).allMatches(src);
            for (final m in matches) {
              final name = m.group(1)!;
              names.putIfAbsent(name, () => []).add(entity.path);
            }
          }
        }
        final dupes = Map.fromEntries(
          names.entries.where((e) => e.value.length > 1),
        );
        expect(
          dupes,
          isEmpty,
          reason:
              'Duplicate @riverpod provider names found in lib/features/:\n${dupes.entries.map((e) => "${e.key}: ${e.value}").join("\n")}',
        );
      },
    );

    test(
      'HIGH-05 keepAlive hard list: all named providers retain @Riverpod(keepAlive: true)',
      () {
        final found = <String, String>{}; // providerName → file path
        for (final entity in Directory('lib').listSync(recursive: true)) {
          if (entity is File &&
              entity.path.endsWith('.dart') &&
              !entity.path.endsWith('.g.dart')) {
            final src = entity.readAsStringSync();
            // Match function-style: @Riverpod(keepAlive: true)\n[type] funcName(Ref ref)
            final fnMatches = RegExp(
              r'@Riverpod\(keepAlive:\s*true\)\s*(?://[^\n]*\n)*\s*\w[\w<>?, ]*\s+(\w+)\s*\(\s*Ref\b',
            ).allMatches(src);
            for (final m in fnMatches) {
              found['${m.group(1)!}Provider'] = entity.path;
            }
            // Match class-style: @Riverpod(keepAlive: true)\nclass ClassName extends _$ClassName
            final classMatches = RegExp(
              r'@Riverpod\(keepAlive:\s*true\)\s*(?://[^\n]*\n)*\s*class\s+(\w+)\s+extends\s+_\$\1',
            ).allMatches(src);
            for (final m in classMatches) {
              // ClassName → classNameProvider
              final cn = m.group(1)!;
              final providerName =
                  '${cn[0].toLowerCase()}${cn.substring(1)}Provider';
              found[providerName] = entity.path;
            }
          }
        }
        final missing = _expectedKeepAliveProviders
            .where((p) => !found.containsKey(p))
            .toList();
        expect(
          missing,
          isEmpty,
          reason:
              'HIGH-05 keepAlive providers missing @Riverpod(keepAlive: true): $missing\nFound: ${found.keys.toList()}',
        );
      },
    );

    test('HIGH-06 no UnimplementedError in production providers', () {
      final hits = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is File &&
            entity.path.endsWith('.dart') &&
            !entity.path.endsWith('.g.dart')) {
          final src = entity.readAsStringSync();
          if (RegExp(
                r'@(?:R|r)iverpod[\s\S]{0,500}throw\s+UnimplementedError',
              ).hasMatch(src) ||
              RegExp(
                r'Provider<\w+>\(\([^)]*\)\s*=>\s*throw\s+UnimplementedError',
              ).hasMatch(src)) {
            hits.add(entity.path);
          }
        }
      }
      expect(
        hits,
        isEmpty,
        reason: 'UnimplementedError providers found in production code: $hits',
      );
    });
  });
}
