import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockSyncOrchestrator extends Mock implements SyncOrchestrator {}

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(SyncMode.initialSync);
  });

  group('SyncEngine deduplication', () {
    late SyncEngine engine;
    late MockSyncOrchestrator orchestrator;
    late MockGroupRepository groupRepo;

    final activeGroup = GroupInfo(
      groupId: 'group-1',
      groupName: 'Test Family',
      status: GroupStatus.active,
      role: 'member',
      members: const [
        GroupMember(
          deviceId: 'owner-1',
          publicKey: 'pk',
          deviceName: 'Phone',
          displayName: 'Owner',
          avatarEmoji: '🏠',
          role: 'owner',
          status: 'active',
        ),
      ],
      createdAt: DateTime(2026, 4, 1),
    );

    setUp(() {
      orchestrator = MockSyncOrchestrator();
      groupRepo = MockGroupRepository();
      when(() => orchestrator.needsFullPull()).thenAnswer((_) async => false);
      when(() => orchestrator.getPendingQueueCount())
          .thenAnswer((_) async => 0);
      when(() => orchestrator.execute(any()))
          .thenAnswer((_) async => const SyncOrchestratorSuccess());
      when(() => groupRepo.getActiveGroup())
          .thenAnswer((_) async => activeGroup);

      engine = SyncEngine(
        orchestrator: orchestrator,
        groupRepo: groupRepo,
      );
    });

    tearDown(() {
      engine.dispose();
    });

    test('duplicate onMemberConfirmed within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      engine.onMemberConfirmed(); // duplicate — should be suppressed

      // Allow async sync request to process
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Only one initialSyncing emission (not two)
      final syncingCount =
          statuses.where((s) => s.state == SyncState.initialSyncing).length;
      expect(syncingCount, 1);
    });

    test('duplicate onSyncAvailable within 10s is suppressed', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onSyncAvailable();
      engine.onSyncAvailable(); // duplicate

      await Future<void>.delayed(const Duration(milliseconds: 100));

      final syncingCount =
          statuses.where((s) => s.state == SyncState.syncing).length;
      expect(syncingCount, 1);
    });

    test('different event types are not deduplicated', () async {
      final statuses = <SyncStatus>[];
      engine.statusStream.listen(statuses.add);

      engine.onMemberConfirmed();
      // Wait for first to start processing before sending second
      await Future<void>.delayed(const Duration(milliseconds: 50));
      engine.onSyncAvailable(); // different type — should go through

      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Both should trigger sync status changes
      final allSyncing = statuses
          .where((s) =>
              s.state == SyncState.syncing ||
              s.state == SyncState.initialSyncing)
          .length;
      expect(allSyncing, greaterThanOrEqualTo(2));
    });
  });
}
