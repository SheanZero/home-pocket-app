import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/repository_providers.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart' as crypto;
import 'package:home_pocket/infrastructure/security/providers.dart' as security;
import 'package:mocktail/mocktail.dart';

class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late _MockKeyManager mockKeyManager;
  late AppDatabase mockDatabase;

  setUp(() {
    mockKeyManager = _MockKeyManager();
    mockDatabase = AppDatabase.forTesting();
  });

  tearDown(() async {
    await mockDatabase.close();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        crypto.keyManagerProvider.overrideWithValue(mockKeyManager),
        security.appDatabaseProvider.overrideWithValue(mockDatabase),
      ],
    );
  }

  group('lib/application/accounting/repository_providers.dart', () {
    test('appAppDatabaseProvider (re-export) returns the overridden database', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appAppDatabaseProvider);
      expect(result, same(mockDatabase));
    });

    test('appKeyManagerProvider (re-export) returns the overridden key manager', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appKeyManagerProvider);
      expect(result, same(mockKeyManager));
    });
  });
}
