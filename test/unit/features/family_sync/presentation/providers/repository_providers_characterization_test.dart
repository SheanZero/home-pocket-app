import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/repository_providers.dart'
    as app_accounting;
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
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
        app_accounting.appAppDatabaseProvider.overrideWithValue(testDatabase),
        keyManagerProvider.overrideWithValue(mockKeyManager),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  group(
    'family_sync/repository_providers characterization tests (post-refactor: delegating providers)',
    () {
      test('groupRepositoryProvider constructs GroupRepository', () {
        final repo = container.read(groupRepositoryProvider);
        expect(repo, isA<GroupRepository>());
      });

      test('syncRepositoryProvider constructs SyncRepository', () {
        final repo = container.read(syncRepositoryProvider);
        expect(repo, isA<SyncRepository>());
      });

      test('relayApiClientProvider delegates to application layer', () {
        // After Plan 04-02 refactor: relayApiClientProvider is a delegating
        // provider that routes through application/family_sync/repository_providers.
        // RelayApiClient is constructed in application layer; feature side delegates.
        final client = container.read(relayApiClientProvider);
        expect(client, isA<RelayApiClient>());
      });

      test('e2eeServiceProvider delegates to application layer', () {
        final service = container.read(e2eeServiceProvider);
        expect(service, isA<E2EEService>());
      });

      test('syncQueueManagerProvider constructs SyncQueueManager', () {
        final manager = container.read(syncQueueManagerProvider);
        expect(manager, isA<SyncQueueManager>());
      });

      test(
        'pushNotificationServiceProvider delegates to application layer',
        () {
          final service = container.read(pushNotificationServiceProvider);
          expect(service, isA<PushNotificationService>());
        },
      );

      test('webSocketServiceProvider delegates to application layer', () {
        final service = container.read(webSocketServiceProvider);
        expect(service, isA<WebSocketService>());
      });

      test('all delegating sync-client providers return non-null instances', () {
        expect(container.read(relayApiClientProvider), isNotNull);
        expect(container.read(e2eeServiceProvider), isNotNull);
        expect(container.read(pushNotificationServiceProvider), isNotNull);
        expect(container.read(syncQueueManagerProvider), isNotNull);
        expect(container.read(webSocketServiceProvider), isNotNull);
      });

      test(
        'groupMemberDaoProvider constructs GroupMemberDao without error',
        () {
          final dao = container.read(groupMemberDaoProvider);
          expect(dao, isNotNull);
        },
      );
    },
  );
}
