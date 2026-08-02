import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/check_group_use_case.dart';
import 'package:home_pocket/application/family_sync/complete_member_activation_use_case.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckGroupUseCase extends Mock implements CheckGroupUseCase {}

class MockPullSyncUseCase extends Mock implements PullSyncUseCase {}

class MockGroupRepository extends Mock implements GroupRepository {}

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  late MockCheckGroupUseCase checkGroup;
  late MockPullSyncUseCase pullSync;
  late MockGroupRepository groupRepository;
  late MockSyncOrchestrator orchestrator;
  late CompleteMemberActivationUseCase useCase;

  GroupInfo activeGroup({String groupKey = 'epoch-2-key'}) => GroupInfo(
    groupId: 'group-1',
    groupName: 'Family',
    status: GroupStatus.active,
    role: 'member',
    groupKey: groupKey,
    keyEpoch: 2,
    members: const [],
    createdAt: DateTime(2026),
  );

  GroupInfo confirmingGroup({String? groupKey}) => GroupInfo(
    groupId: 'group-1',
    groupName: 'Family',
    status: GroupStatus.confirming,
    role: 'member',
    groupKey: groupKey,
    keyEpoch: groupKey == null ? 1 : 2,
    members: const [],
    createdAt: DateTime(2026),
  );

  setUp(() {
    checkGroup = MockCheckGroupUseCase();
    pullSync = MockPullSyncUseCase();
    groupRepository = MockGroupRepository();
    orchestrator = MockSyncOrchestrator();
    useCase = CompleteMemberActivationUseCase(
      checkGroup: checkGroup,
      pullSync: pullSync,
      groupRepository: groupRepository,
      orchestrator: orchestrator,
    );

    when(
      () => orchestrator.execute(any()),
    ).thenAnswer((_) async => const SyncOrchestratorSuccess());
  });

  test(
    'pulls a targeted key, revalidates membership, activates, then reconciles',
    () async {
      var checkCalls = 0;
      when(() => checkGroup.execute()).thenAnswer((_) async {
        checkCalls++;
        return checkCalls == 1
            ? const CheckGroupAwaitingKey(groupId: 'group-1')
            : const CheckGroupInGroup(groupId: 'group-1');
      });
      when(
        () => pullSync.execute(),
      ).thenAnswer((_) async => const PullSyncResult.success(0));
      when(
        () => groupRepository.getGroupById('group-1'),
      ).thenAnswer((_) async => confirmingGroup(groupKey: 'epoch-2-key'));
      final result = await useCase.execute(expectedGroupId: 'group-1');

      expect(result, isA<MemberActivationReady>());
      verifyInOrder([
        () => checkGroup.execute(),
        () => pullSync.execute(),
        () => groupRepository.getGroupById('group-1'),
        () => checkGroup.execute(),
        () => orchestrator.execute(SyncMode.initialSync),
        () => orchestrator.execute(SyncMode.incrementalPull),
      ]);
    },
  );

  test('keeps awaiting key when the key envelope arrives late', () async {
    var checkCalls = 0;
    var pullCalls = 0;
    when(() => checkGroup.execute()).thenAnswer((_) async {
      checkCalls++;
      if (checkCalls < 3) {
        return const CheckGroupAwaitingKey(groupId: 'group-1');
      }
      return const CheckGroupInGroup(groupId: 'group-1');
    });
    when(() => pullSync.execute()).thenAnswer((_) async {
      pullCalls++;
      return pullCalls == 1
          ? const PullSyncResult.noNewData()
          : const PullSyncResult.success(0);
    });
    when(() => groupRepository.getGroupById('group-1')).thenAnswer((_) async {
      return pullCalls == 1
          ? confirmingGroup()
          : confirmingGroup(groupKey: 'epoch-2-key');
    });

    final first = await useCase.execute(expectedGroupId: 'group-1');
    final second = await useCase.execute(expectedGroupId: 'group-1');

    expect(first, isA<MemberActivationAwaitingKey>());
    expect(second, isA<MemberActivationReady>());
    verify(() => pullSync.execute()).called(2);
    verify(() => orchestrator.execute(SyncMode.initialSync)).called(1);
    verify(() => orchestrator.execute(SyncMode.incrementalPull)).called(1);
  });

  test('network or decryption failure remains awaiting key', () async {
    when(
      () => checkGroup.execute(),
    ).thenAnswer((_) async => const CheckGroupAwaitingKey(groupId: 'group-1'));
    when(
      () => pullSync.execute(),
    ).thenAnswer((_) async => const PullSyncResult.error('offline'));

    final result = await useCase.execute(expectedGroupId: 'group-1');

    expect(result, isA<MemberActivationAwaitingKey>());
    expect((result as MemberActivationAwaitingKey).message, 'offline');
    verifyNever(() => groupRepository.getGroupById(any()));
    verifyNever(() => orchestrator.execute(any()));
  });

  test('rejects an event for a different group before syncing', () async {
    when(() => checkGroup.execute()).thenAnswer(
      (_) async => const CheckGroupAwaitingKey(groupId: 'group-other'),
    );

    final result = await useCase.execute(expectedGroupId: 'group-1');

    expect(result, isA<MemberActivationError>());
    verifyNever(() => pullSync.execute());
    verifyNever(() => orchestrator.execute(any()));
  });

  test('rejects a group change during key bootstrap', () async {
    var checkCalls = 0;
    when(() => checkGroup.execute()).thenAnswer((_) async {
      checkCalls++;
      return checkCalls == 1
          ? const CheckGroupAwaitingKey(groupId: 'group-1')
          : const CheckGroupInGroup(groupId: 'group-other');
    });
    when(
      () => pullSync.execute(),
    ).thenAnswer((_) async => const PullSyncResult.success(0));
    when(
      () => groupRepository.getGroupById('group-1'),
    ).thenAnswer((_) async => confirmingGroup(groupKey: 'epoch-2-key'));

    final result = await useCase.execute(expectedGroupId: 'group-1');

    expect(result, isA<MemberActivationError>());
    verifyNever(() => orchestrator.execute(any()));
  });

  test('repeated confirmation after ready is idempotent', () async {
    when(
      () => checkGroup.execute(),
    ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));
    when(
      () => groupRepository.getActiveGroup(),
    ).thenAnswer((_) async => activeGroup());

    final first = await useCase.execute(expectedGroupId: 'group-1');
    final second = await useCase.execute(expectedGroupId: 'group-1');

    expect(first, isA<MemberActivationReady>());
    expect(second, isA<MemberActivationReady>());
    verify(() => checkGroup.execute()).called(1);
    verify(() => orchestrator.execute(SyncMode.initialSync)).called(1);
    verify(() => orchestrator.execute(SyncMode.incrementalPull)).called(1);
  });

  test('does not report ready when initial reconciliation fails', () async {
    when(
      () => checkGroup.execute(),
    ).thenAnswer((_) async => const CheckGroupInGroup(groupId: 'group-1'));
    when(() => orchestrator.execute(SyncMode.initialSync)).thenAnswer(
      (_) async => const SyncOrchestratorError('initial sync failed'),
    );

    final result = await useCase.execute(expectedGroupId: 'group-1');

    expect(result, isA<MemberActivationError>());
    verifyNever(() => orchestrator.execute(SyncMode.incrementalPull));
  });
}
