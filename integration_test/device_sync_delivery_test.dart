import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/sync_queue_dao.dart';
import 'package:home_pocket/data/repositories/sync_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/sync_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/push_notification_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider/path_provider.dart';

import 'helpers/device_test_crypto.dart';

// E2E-SYNC-PUSH / E2E-SYNC-PULL / E2E-SYNC-ACK / E2E-OFFLINE-QUEUE

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockE2EEService extends Mock implements E2EEService {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockSyncQueueManager extends Mock implements SyncQueueManager {}

class _MockKeyManager extends Mock implements KeyManager {}

class _DeviceMessagingClient implements PushMessagingClient {
  final tokenRefresh = StreamController<String>.broadcast();
  final foreground = StreamController<Map<String, dynamic>>.broadcast();
  final opened = StreamController<Map<String, dynamic>>.broadcast();
  final List<String> events;

  _DeviceMessagingClient(this.events);

  @override
  Future<void> requestPermission() async => events.add('permission');

  @override
  Future<String?> getToken() async => 'device-e2e-token';

  @override
  Stream<String> get onTokenRefresh => tokenRefresh.stream;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => foreground.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => opened.stream;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;

  Future<void> close() async {
    await tokenRefresh.close();
    await foreground.close();
    await opened.close();
  }
}

class _DeviceLocalNotificationClient implements LocalNotificationClient {
  final List<String> events;

  _DeviceLocalNotificationClient(this.events);

  @override
  Future<void> initialize(
    Future<void> Function(Map<String, dynamic> data) onTap,
  ) async => events.add('local-notifications');

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required Map<String, dynamic> payload,
  }) async => events.add('local-show');
}

class _AllowDevicePushPolicy implements PushAcceptancePolicy {
  @override
  Future<String?> resolveIdentityGeneration() async => 'device-e2e';

  @override
  Future<bool> accepts(
    Map<String, dynamic> data, {
    required String? boundIdentityGeneration,
  }) async => boundIdentityGeneration == 'device-e2e';
}

Map<String, dynamic> _dataMessage(String messageId) => {
  'messageId': messageId,
  'fromDeviceId': 'sender-e2e',
  'keyEpoch': 1,
  'payload': jsonEncode({
    'v': 2,
    't': 'D',
    'e': 1,
    'p': 'ciphertext-$messageId',
  }),
};

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'offline ciphertext survives SQLCipher reopen and settles only on relay ACK',
    (tester) async {
      final masterKey = DeviceTestMasterKeyRepository();
      final root = Directory(
        '${(await getTemporaryDirectory()).path}/home-pocket-sync-e2e-'
        '${DateTime.now().microsecondsSinceEpoch}',
      );
      final databaseFile = File('${root.path}/sync-delivery.db');
      final initialNow = DateTime.utc(2026, 8, 5, 12);
      AppDatabase? database;
      try {
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(masterKey, databaseFile),
        );
        var repository = SyncRepositoryImpl(dao: SyncQueueDao(database));
        final failedRelay = _MockRelayApiClient();
        final initialManager = SyncQueueManager(
          syncRepository: repository,
          apiClient: failedRelay,
          now: () => initialNow,
        );

        await initialManager.enqueue(
          id: 'device-queue-1',
          groupId: 'group-e2e',
          encryptedPayload: 'opaque-device-ciphertext',
          vectorClock: const {'device-e2e': 4},
          operationCount: 1,
          keyEpoch: 3,
          withdrawalReceipts: const [
            SyncWithdrawalReceipt(entityId: 'bill-e2e', revision: 4),
          ],
          initialFailure: const RelayApiException(
            statusCode: 503,
            message: 'offline',
          ),
        );
        final queued = await repository.getEntry('device-queue-1');
        expect(queued, isNotNull);
        expect(queued!.state, SyncQueueEntryState.retrying);
        expect(queued.withdrawalReceipts, hasLength(1));
        final retryAt = queued.nextRetryAt!;

        await database.close();
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(masterKey, databaseFile),
        );
        repository = SyncRepositoryImpl(dao: SyncQueueDao(database));
        final relay = _MockRelayApiClient();
        when(
          () => relay.pushSync(
            groupId: any(named: 'groupId'),
            syncId: any(named: 'syncId'),
            payload: any(named: 'payload'),
            vectorClock: any(named: 'vectorClock'),
            operationCount: any(named: 'operationCount'),
            keyEpoch: any(named: 'keyEpoch'),
          ),
        ).thenAnswer((_) async => {'recipientCount': 1});
        final acknowledged = <SyncWithdrawalReceipt>[];
        final restartedManager = SyncQueueManager(
          syncRepository: repository,
          apiClient: relay,
          now: () => retryAt,
          onWithdrawalsDelivered: (receipts) async {
            acknowledged.addAll(receipts);
          },
        );

        expect(await restartedManager.drainQueue(), 1);
        expect(acknowledged.single.entityId, 'bill-e2e');
        expect(await repository.getEntry('device-queue-1'), isNull);
      } finally {
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'pull applies durably before ACK and then drains queued push',
    (tester) async {
      final masterKey = DeviceTestMasterKeyRepository();
      final root = Directory(
        '${(await getTemporaryDirectory()).path}/home-pocket-pull-e2e-'
        '${DateTime.now().microsecondsSinceEpoch}',
      );
      final databaseFile = File('${root.path}/pull-ack.db');
      AppDatabase? database;
      try {
        database = AppDatabase(
          await createDeviceTestEncryptedExecutor(masterKey, databaseFile),
        );
        await database.customStatement(
          'CREATE TABLE device_e2e_pull_apply ('
          'entity_id TEXT PRIMARY KEY NOT NULL)',
        );

        final apiClient = _MockRelayApiClient();
        final e2ee = _MockE2EEService();
        final groups = _MockGroupRepository();
        final queue = _MockSyncQueueManager();
        final keyManager = _MockKeyManager();
        final order = <String>[];

        when(() => groups.getActiveGroup()).thenAnswer(
          (_) async => GroupInfo(
            groupId: 'group-e2e',
            status: GroupStatus.active,
            groupName: 'Device Family',
            role: 'owner',
            groupKey: 'group-key-e2e',
            members: const [],
            createdAt: DateTime.utc(2026, 8, 5),
          ),
        );
        when(
          () => keyManager.getDeviceId(),
        ).thenAnswer((_) async => 'device-e2e');
        when(
          () => e2ee.decryptFromGroup(
            encryptedPayload: any(named: 'encryptedPayload'),
            groupKeyBase64: any(named: 'groupKeyBase64'),
          ),
        ).thenReturn(
          jsonEncode({
            'operations': [
              {
                'op': 'update',
                'entityType': 'bill',
                'entityId': 'bill-from-device-pull',
                'data': {'id': 'bill-from-device-pull'},
              },
            ],
          }),
        );
        when(() => apiClient.pullSync()).thenAnswer(
          (_) async => {
            'messages': [_dataMessage('device-pull-message')],
            'hasMore': false,
          },
        );
        when(
          () => apiClient.ackSync(messageIds: any(named: 'messageIds')),
        ).thenAnswer((_) async {
          final rows = await database!
              .customSelect('SELECT entity_id FROM device_e2e_pull_apply')
              .get();
          expect(
            rows.single.read<String>('entity_id'),
            'bill-from-device-pull',
          );
          order.add('ack');
          return {'acked': 1};
        });
        when(() => queue.drainQueue()).thenAnswer((_) async {
          order.add('queue-drain');
          return 1;
        });

        final pull = PullSyncUseCase(
          apiClient: apiClient,
          e2eeService: e2ee,
          groupRepo: groups,
          queueManager: queue,
          keyManager: keyManager,
          applyOperations: (operations, {groupId}) async {
            final entityId = operations.single['entityId'] as String;
            await database!.customStatement(
              'INSERT INTO device_e2e_pull_apply (entity_id) VALUES (?)',
              [entityId],
            );
            order.add('apply');
          },
        );

        final result = await pull.execute();
        expect(result, isA<PullSyncSuccess>());
        final success = result as PullSyncSuccess;
        expect(success.appliedCount, 1);
        expect(success.ackedCount, 1);
        expect(order, ['apply', 'ack', 'queue-drain']);
      } finally {
        await database?.close();
        if (await root.exists()) await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets('push provider pipeline registers and routes foreground sync', (
    tester,
  ) async {
    final events = <String>[];
    final apiClient = _MockRelayApiClient();
    final messaging = _DeviceMessagingClient(events);
    final localNotifications = _DeviceLocalNotificationClient(events);
    final delivered = Completer<void>();
    when(
      () => apiClient.updatePushToken(
        pushToken: any(named: 'pushToken'),
        pushPlatform: any(named: 'pushPlatform'),
      ),
    ).thenAnswer((_) async => events.add('token-registered'));

    final service = PushNotificationService(
      apiClient: apiClient,
      messagingClient: messaging,
      localNotificationClient: localNotifications,
      firebaseInitializer: () async => events.add('provider-init'),
      pushPlatform: 'device-e2e',
      acceptancePolicy: _AllowDevicePushPolicy(),
    );
    try {
      service.registerHandlers(
        onSyncAvailable: (_) async {
          events.add('sync-routed');
          if (!delivered.isCompleted) delivered.complete();
        },
      );

      expect(await service.initialize(), 'device-e2e-token');
      messaging.foreground.add({'type': 'sync_available'});
      await delivered.future.timeout(const Duration(seconds: 5));

      expect(
        events,
        containsAllInOrder([
          'provider-init',
          'local-notifications',
          'permission',
          'token-registered',
          'sync-routed',
        ]),
      );
    } finally {
      await service.dispose();
      await messaging.close();
    }
  });
}
