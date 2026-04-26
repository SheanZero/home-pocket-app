import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/sync/websocket_service.dart';
import 'package:mocktail/mocktail.dart';

// Inline Mocktail-only mocks (no @GenerateMocks, no package:mockito)
class _MockKeyManager extends Mock implements KeyManager {}

void main() {
  late AppDatabase testDatabase;
  late _MockKeyManager mockKeyManager;
  late ProviderContainer container;

  setUp(() {
    testDatabase = AppDatabase.forTesting();
    mockKeyManager = _MockKeyManager();

    when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
    when(
      () => mockKeyManager.getPublicKey(),
    ).thenAnswer((_) async => 'pub-key');

    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(testDatabase),
        keyManagerProvider.overrideWithValue(mockKeyManager),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group(
    'family_sync/repository_providers characterization tests (pre-refactor: 6 sync-client providers)',
    () {
      test('groupRepositoryProvider constructs GroupRepository', () {
        final repo = container.read(groupRepositoryProvider);
        expect(repo, isA<GroupRepository>());
      });

      test('syncRepositoryProvider constructs SyncRepository', () {
        final repo = container.read(syncRepositoryProvider);
        expect(repo, isA<SyncRepository>());
      });

      test('requestSignerProvider constructs RequestSigner', () {
        final signer = container.read(requestSignerProvider);
        expect(signer, isA<RequestSigner>());
      });

      test('relayApiClientProvider constructs RelayApiClient', () {
        final client = container.read(relayApiClientProvider);
        expect(client, isA<RelayApiClient>());
      });

      test('e2eeServiceProvider constructs E2EEService', () {
        final service = container.read(e2eeServiceProvider);
        expect(service, isA<E2EEService>());
      });

      test('syncQueueManagerProvider constructs SyncQueueManager', () {
        final manager = container.read(syncQueueManagerProvider);
        expect(manager, isA<SyncQueueManager>());
      });

      test(
        'pushNotificationServiceProvider constructs PushNotificationService',
        () {
          // Note: this uses Platform.isIOS which may vary per environment,
          // but the provider should always construct without throwing.
          final service = container.read(pushNotificationServiceProvider);
          expect(service, isA<PushNotificationService>());
        },
      );

      test('webSocketServiceProvider constructs WebSocketService', () {
        final service = container.read(webSocketServiceProvider);
        expect(service, isA<WebSocketService>());
      });

      test('all 6 sync-client providers return non-null instances', () {
        expect(container.read(relayApiClientProvider), isNotNull);
        expect(container.read(e2eeServiceProvider), isNotNull);
        expect(container.read(pushNotificationServiceProvider), isNotNull);
        expect(container.read(syncQueueManagerProvider), isNotNull);
        expect(container.read(webSocketServiceProvider), isNotNull);
        expect(container.read(requestSignerProvider), isNotNull);
      });

      test(
        'groupMemberDaoProvider constructs GroupMemberDao without error',
        () {
          // groupMemberDaoProvider is used for watch queries from sync_providers
          final dao = container.read(groupMemberDaoProvider);
          expect(dao, isNotNull);
        },
      );
    },
  );
}
