import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/notify_member_approval_use_case.dart';
import 'package:home_pocket/application/family_sync/repository_providers.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart' as crypto;
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

class _MockKeyManager extends Mock implements KeyManager {}

class _MockSyncRepository extends Mock implements SyncRepository {}

void main() {
  late _MockKeyManager mockKeyManager;
  late _MockSyncRepository mockSyncRepository;

  setUp(() {
    mockKeyManager = _MockKeyManager();
    mockSyncRepository = _MockSyncRepository();
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        crypto.keyManagerProvider.overrideWithValue(mockKeyManager),
        appSyncRepositoryProvider.overrideWithValue(mockSyncRepository),
      ],
    );
  }

  group('lib/application/family_sync/repository_providers.dart', () {
    test('appRelayApiClientProvider returns a non-null RelayApiClient', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appRelayApiClientProvider);
      expect(result, isA<RelayApiClient>());
    });

    test('appE2eeServiceProvider returns a non-null E2EEService', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appE2eeServiceProvider);
      expect(result, isA<E2EEService>());
    });

    test('appSyncQueueManagerProvider returns a SyncQueueManager', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appSyncQueueManagerProvider);
      expect(result, isA<SyncQueueManager>());
    });

    test('appWebSocketServiceProvider returns a WebSocketService', () {
      final container = makeContainer();
      addTearDown(container.dispose);
      final result = container.read(appWebSocketServiceProvider);
      expect(result, isA<WebSocketService>());
    });

    test(
      'appKeyManagerProvider (re-export) returns the same as overridden underlying provider',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);
        final result = container.read(appKeyManagerProvider);
        expect(result, same(mockKeyManager));
      },
    );

    test(
      'notifyMemberApprovalUseCaseProvider returns a NotifyMemberApprovalUseCase',
      () {
        final container = makeContainer();
        addTearDown(container.dispose);
        final result = container.read(notifyMemberApprovalUseCaseProvider);
        expect(result, isA<NotifyMemberApprovalUseCase>());
      },
    );
  });
}
