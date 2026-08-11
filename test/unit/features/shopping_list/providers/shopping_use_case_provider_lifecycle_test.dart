import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/repository_providers.dart'
    as app_accounting;
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/shopping_list/domain/models/shopping_item.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:home_pocket/features/shopping_list/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:mocktail/mocktail.dart';

class _MockDurableShoppingItemRepository extends Mock
    implements DurableFamilySyncShoppingItemRepository {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockSyncEngine extends Mock implements SyncEngine {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      ShoppingItem(
        id: 'fallback',
        deviceId: 'fallback-device',
        listType: 'private',
        name: 'Fallback',
        createdAt: DateTime.utc(2026),
      ),
    );
  });

  test(
    'completion can resolve device identity after its auto-dispose provider is released',
    () async {
      final repository = _MockDurableShoppingItemRepository();
      final keyManager = _MockKeyManager();
      final syncEngine = _MockSyncEngine();
      final readGate = Completer<ShoppingItem?>();
      final item = ShoppingItem(
        id: 'item-1',
        deviceId: 'original-device',
        listType: 'public',
        name: 'Milk',
        createdAt: DateTime.utc(2026, 8, 11),
      );

      when(
        () => repository.findById(item.id),
      ).thenAnswer((_) => readGate.future);
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => repository.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as ShoppingItem,
      );

      final container = ProviderContainer.test(
        overrides: [
          shoppingItemRepositoryProvider.overrideWithValue(repository),
          app_accounting.appKeyManagerProvider.overrideWithValue(keyManager),
          syncEngineProvider.overrideWithValue(syncEngine),
        ],
      );

      final useCase = container.read(toggleItemCompletedUseCaseProvider);
      final resultFuture = useCase.execute(item.id);

      // A bare read does not retain an auto-dispose provider. Let Riverpod
      // release it while the use case is waiting for its local database read.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      readGate.complete(item);

      final result = await resultFuture;

      expect(result.isSuccess, isTrue);
      verify(() => keyManager.getDeviceId()).called(1);
      verify(
        () => repository.updateWithFamilySyncOutbox(
          any(),
          originDeviceId: 'device-1',
        ),
      ).called(1);
    },
  );
}
