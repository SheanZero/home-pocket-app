import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';

import '../../helpers/test_provider_scope.dart';

void main() {
  group('appDatabaseProvider', () {
    test('throws StateError when read without override', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        () => container.read(appDatabaseProvider),
        throwsA(isA<StateError>()),
      );
    });

    test('StateError message references AppInitializer and test helper', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      try {
        container.read(appDatabaseProvider);
        fail('Expected StateError');
      } on StateError catch (e) {
        expect(e.message, contains('AppInitializer'));
        expect(e.message, contains('test_provider_scope.dart'));
      }
    });

    test('returns override value when overrideWithValue is used', () {
      final db = AppDatabase.forTesting();
      final container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      addTearDown(() {
        container.dispose();
        db.close();
      });

      expect(container.read(appDatabaseProvider), same(db));
    });

    test('does NOT throw when accessed via createTestProviderScope', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      expect(() => container.read(appDatabaseProvider), returnsNormally);
    });

    test('createTestProviderScope uses in-memory database by default', () {
      final container = createTestProviderScope();
      addTearDown(container.dispose);

      final db = container.read(appDatabaseProvider);
      expect(db, isA<AppDatabase>());
    });

    test('createTestProviderScope accepts custom database', () {
      final customDb = AppDatabase.forTesting();
      final container = createTestProviderScope(database: customDb);
      addTearDown(() {
        container.dispose();
        customDb.close();
      });

      expect(container.read(appDatabaseProvider), same(customDb));
    });

    test('createTestProviderScope forwards additionalOverrides', () {
      final testProvider = Provider<String>((_) => 'default');
      final container = createTestProviderScope(
        additionalOverrides: [testProvider.overrideWithValue('overridden')],
      );
      addTearDown(container.dispose);

      expect(container.read(testProvider), equals('overridden'));
    });
  });
}
