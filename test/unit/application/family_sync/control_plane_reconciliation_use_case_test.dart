import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/control_plane_reconciliation_use_case.dart';
import 'package:home_pocket/application/family_sync/membership_rotation_coordinator.dart';
import 'package:home_pocket/application/family_sync/refresh_group_snapshot_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:mocktail/mocktail.dart';

class _MockRelayApiClient extends Mock implements RelayApiClient {}

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockRefreshGroupSnapshotUseCase extends Mock
    implements RefreshGroupSnapshotUseCase {}

class _MockCheckGroupValidityUseCase extends Mock
    implements CheckGroupValidityUseCase {}

class _MockKeyManager extends Mock implements KeyManager {}

class _MockMembershipRotationCoordinator extends Mock
    implements MembershipRotationCoordinator {}

void main() {
  late _MockRelayApiClient apiClient;
  late _MockGroupRepository groupRepository;
  late _MockRefreshGroupSnapshotUseCase refreshSnapshot;
  late _MockCheckGroupValidityUseCase checkValidity;

  const localMember = GroupMember(
    deviceId: 'device-1',
    publicKey: 'pk-1',
    deviceName: 'Phone',
    role: 'owner',
    status: 'active',
    displayName: 'Owner',
    avatarEmoji: '🏠',
  );
  final activeGroup = GroupInfo(
    groupId: 'group-1',
    status: GroupStatus.active,
    groupName: 'Family',
    role: 'owner',
    groupKey: 'key-2',
    keyEpoch: 2,
    members: const [localMember],
    createdAt: DateTime.utc(2026, 8, 1),
    controlRevision: 2,
  );

  Map<String, dynamic> event(String id, int revision) => {
    'eventId': id,
    'groupId': 'group-1',
    'revision': revision,
    'eventType': 'group_renamed',
    'occurredAt': '2026-08-02T00:00:00Z',
  };

  setUp(() {
    apiClient = _MockRelayApiClient();
    groupRepository = _MockGroupRepository();
    refreshSnapshot = _MockRefreshGroupSnapshotUseCase();
    checkValidity = _MockCheckGroupValidityUseCase();

    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => activeGroup);
    when(
      () => refreshSnapshot.execute(
        groupId: any(named: 'groupId'),
        controlEvent: any(named: 'controlEvent'),
        controlEvents: any(named: 'controlEvents'),
      ),
    ).thenAnswer(
      (_) async => const RefreshGroupSnapshotApplied(groupName: 'Family'),
    );
    when(
      () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
        groupId: any(named: 'groupId'),
        statusCode: any(named: 'statusCode'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => const GroupValidityResult.invalid('removed'));
  });

  ControlPlaneReconciliationUseCase makeUseCase({
    int maxPages = 20,
    Duration requestTimeout = const Duration(seconds: 10),
  }) {
    return ControlPlaneReconciliationUseCase(
      apiClient: apiClient,
      groupRepository: groupRepository,
      refreshSnapshot: refreshSnapshot,
      checkValidity: checkValidity,
      maxPagesPerExecution: maxPages,
      requestTimeout: requestTimeout,
    );
  }

  test(
    'paginates missed events then applies one authoritative snapshot',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenAnswer(
        (_) async => {
          'events': [event('event-4', 4), event('event-3', 3)],
          'hasMore': true,
          'nextRevision': 4,
        },
      );
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 4,
          limit: 100,
        ),
      ).thenAnswer(
        (_) async => {
          'events': [event('event-4', 4), event('event-5', 5)],
          'hasMore': false,
          'nextRevision': 5,
        },
      );

      final result = await makeUseCase().execute();

      expect(
        result,
        const ControlPlaneReconciliationResult.reconciled(
          pageCount: 2,
          eventCount: 3,
        ),
      );
      final captured =
          verify(
                () => refreshSnapshot.execute(
                  groupId: 'group-1',
                  controlEvents: captureAny(named: 'controlEvents'),
                ),
              ).captured.single
              as List<Map<String, dynamic>>;
      expect(captured.map((item) => item['eventId']), [
        'event-3',
        'event-4',
        'event-5',
      ]);
    },
  );

  test(
    'requests initial bill sync after a missed member confirmation',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenAnswer(
        (_) async => {
          'events': [
            {...event('event-3', 3), 'eventType': 'member_confirmed'},
          ],
          'hasMore': false,
          'nextRevision': 3,
        },
      );

      final result = await makeUseCase().execute();

      expect(
        result,
        const ControlPlaneReconciliationResult.reconciled(
          pageCount: 1,
          eventCount: 1,
          requiresInitialSync: true,
        ),
      );
    },
  );

  test(
    'stops without applying a snapshot when pagination makes no progress',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenAnswer(
        (_) async => {
          'events': <Map<String, dynamic>>[],
          'hasMore': true,
          'nextRevision': 2,
        },
      );

      final result = await makeUseCase().execute();

      expect(
        result,
        isA<ControlPlaneReconciliationDeferred>().having(
          (value) => value.reason,
          'reason',
          ControlPlaneReconciliationDeferredReason.noProgress,
        ),
      );
      verifyNever(
        () => refreshSnapshot.execute(
          groupId: any(named: 'groupId'),
          controlEvents: any(named: 'controlEvents'),
        ),
      );
    },
  );

  test(
    'stops at the configured page limit without advancing snapshot',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: any(named: 'afterRevision'),
          limit: 100,
        ),
      ).thenAnswer((invocation) async {
        final after = invocation.namedArguments[#afterRevision] as int;
        return {
          'events': [event('event-${after + 1}', after + 1)],
          'hasMore': true,
          'nextRevision': after + 1,
        };
      });

      final result = await makeUseCase(maxPages: 2).execute();

      expect(
        result,
        isA<ControlPlaneReconciliationDeferred>().having(
          (value) => value.reason,
          'reason',
          ControlPlaneReconciliationDeferredReason.pageLimitReached,
        ),
      );
      verifyNever(
        () => refreshSnapshot.execute(
          groupId: any(named: 'groupId'),
          controlEvents: any(named: 'controlEvents'),
        ),
      );
    },
  );

  test('network and 5xx failures preserve local membership', () async {
    when(
      () => apiClient.getGroupControlEvents(
        groupId: 'group-1',
        afterRevision: 2,
        limit: 100,
      ),
    ).thenThrow(Exception('offline'));

    final result = await makeUseCase().execute();

    expect(result, isA<ControlPlaneReconciliationUnavailable>());
    verifyNever(
      () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
        groupId: any(named: 'groupId'),
        statusCode: any(named: 'statusCode'),
        reason: any(named: 'reason'),
      ),
    );
    verifyNever(
      () => refreshSnapshot.execute(
        groupId: any(named: 'groupId'),
        controlEvents: any(named: 'controlEvents'),
      ),
    );
  });

  test(
    'timeout preserves local membership and blocks the data plane',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenAnswer((_) => Completer<Map<String, dynamic>>().future);

      final result = await makeUseCase(
        requestTimeout: const Duration(milliseconds: 1),
      ).execute();

      expect(result, isA<ControlPlaneReconciliationUnavailable>());
      verifyNever(
        () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
          groupId: any(named: 'groupId'),
          statusCode: any(named: 'statusCode'),
          reason: any(named: 'reason'),
        ),
      );
      verifyNever(
        () => refreshSnapshot.execute(
          groupId: any(named: 'groupId'),
          controlEvents: any(named: 'controlEvents'),
        ),
      );
    },
  );

  test('events 403 is authoritative removal and invokes cleanup', () async {
    when(
      () => apiClient.getGroupControlEvents(
        groupId: 'group-1',
        afterRevision: 2,
        limit: 100,
      ),
    ).thenThrow(const RelayApiException(statusCode: 403, message: 'forbidden'));

    final result = await makeUseCase().execute();

    expect(result, isA<ControlPlaneReconciliationNoGroup>());
    verify(
      () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
        groupId: 'group-1',
        statusCode: 403,
        reason: any(named: 'reason'),
      ),
    ).called(1);
  });

  test('pull 404 cleanup does not depend on another network request', () async {
    final result = await makeUseCase()
        .executeAfterAuthenticatedMembershipFailure(
          statusCode: 404,
          reason: 'group gone',
        );

    expect(result, isA<ControlPlaneReconciliationNoGroup>());
    verify(
      () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
        groupId: 'group-1',
        statusCode: 404,
        reason: 'group gone',
      ),
    ).called(1);
    verifyNever(
      () => apiClient.getGroupControlEvents(
        groupId: any(named: 'groupId'),
        afterRevision: any(named: 'afterRevision'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test(
    'events 404 means old endpoint and still validates by snapshot',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenThrow(
        const RelayApiException(statusCode: 404, message: 'not found'),
      );

      final result = await makeUseCase().execute();

      expect(
        result,
        const ControlPlaneReconciliationResult.reconciled(
          pageCount: 0,
          eventCount: 0,
          eventsEndpointUnsupported: true,
        ),
      );
      verify(
        () => refreshSnapshot.execute(
          groupId: 'group-1',
          controlEvents: const [],
        ),
      ).called(1);
      verifyNever(
        () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
          groupId: any(named: 'groupId'),
          statusCode: any(named: 'statusCode'),
          reason: any(named: 'reason'),
        ),
      );
    },
  );

  test(
    'status 404 or inactive snapshot performs authoritative cleanup',
    () async {
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenAnswer(
        (_) async => {
          'events': <Map<String, dynamic>>[],
          'hasMore': false,
          'nextRevision': 2,
        },
      );
      when(
        () => refreshSnapshot.execute(
          groupId: 'group-1',
          controlEvents: const [],
        ),
      ).thenAnswer(
        (_) async => const RefreshGroupSnapshotMembershipInvalid(
          'Group is inactive',
          statusCode: 404,
        ),
      );

      final result = await makeUseCase().execute();

      expect(result, isA<ControlPlaneReconciliationNoGroup>());
      verify(
        () => checkValidity.invalidateAfterAuthenticatedMembershipFailure(
          groupId: 'group-1',
          statusCode: 404,
          reason: 'Group is inactive',
        ),
      ).called(1);
    },
  );

  test('concurrent requests share one authenticated reconciliation', () async {
    final page = Completer<Map<String, dynamic>>();
    when(
      () => apiClient.getGroupControlEvents(
        groupId: 'group-1',
        afterRevision: 2,
        limit: 100,
      ),
    ).thenAnswer((_) => page.future);
    final useCase = makeUseCase();

    final first = useCase.execute();
    final second = useCase.execute();
    await Future<void>.delayed(Duration.zero);
    verify(
      () => apiClient.getGroupControlEvents(
        groupId: 'group-1',
        afterRevision: 2,
        limit: 100,
      ),
    ).called(1);

    page.complete({
      'events': <Map<String, dynamic>>[],
      'hasMore': false,
      'nextRevision': 2,
    });
    expect(await first, isA<ControlPlaneReconciliationReconciled>());
    expect(await second, isA<ControlPlaneReconciliationReconciled>());
  });

  test(
    'old server fallback snapshot still recovers C1 pending rotation',
    () async {
      final keyManager = _MockKeyManager();
      final rotation = _MockMembershipRotationCoordinator();
      final realRefresh = RefreshGroupSnapshotUseCase(
        apiClient: apiClient,
        groupRepository: groupRepository,
        keyManager: keyManager,
        membershipRotation: rotation,
      );
      final useCase = ControlPlaneReconciliationUseCase(
        apiClient: apiClient,
        groupRepository: groupRepository,
        refreshSnapshot: realRefresh,
        checkValidity: checkValidity,
      );
      final pendingSnapshot = {
        'groupId': 'group-1',
        'status': 'active',
        'groupName': 'Family',
        'keyEpoch': 2,
        'rotationRequired': true,
        'members': [localMember.toJson()],
      };
      final recoveredSnapshot = {
        ...pendingSnapshot,
        'keyEpoch': 3,
        'rotationRequired': false,
      };
      when(() => keyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(
        () => apiClient.getGroupControlEvents(
          groupId: 'group-1',
          afterRevision: 2,
          limit: 100,
        ),
      ).thenThrow(
        const RelayApiException(statusCode: 404, message: 'old server'),
      );
      var statusCalls = 0;
      when(() => apiClient.getGroupStatus('group-1')).thenAnswer((_) async {
        statusCalls++;
        return statusCalls == 1 ? pendingSnapshot : recoveredSnapshot;
      });
      when(
        () => rotation.recoverFromSnapshot(pendingSnapshot),
      ).thenAnswer((_) async => true);
      when(
        () => groupRepository.applyAuthoritativeSnapshot(
          groupId: 'group-1',
          groupName: 'Family',
          role: 'owner',
          keyEpoch: 3,
          members: const [localMember],
        ),
      ).thenAnswer((_) async => true);

      expect(
        await useCase.execute(),
        isA<ControlPlaneReconciliationReconciled>(),
      );
      verify(() => rotation.recoverFromSnapshot(pendingSnapshot)).called(1);
      verify(() => apiClient.getGroupStatus('group-1')).called(2);
    },
  );
}
