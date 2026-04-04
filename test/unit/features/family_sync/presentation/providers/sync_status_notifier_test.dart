import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/active_group_provider.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repo;

  setUp(() {
    repo = MockGroupRepository();
  });

  group('SyncStatusNotifier', () {
    test('defaults to unpaired when no active group exists', () async {
      when(() => repo.watchActiveGroup()).thenAnswer((_) => Stream.value(null));

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(activeGroupProvider.future);

      expect(container.read(syncStatusNotifierProvider), SyncStatus.unpaired);
    });

    test('defaults to synced when an active group exists', () async {
      when(
        () => repo.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(_buildActiveGroup()));

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(activeGroupProvider.future);

      expect(container.read(syncStatusNotifierProvider), SyncStatus.synced);
    });

    test(
      'keeps transient status when active group details update without membership transition',
      () async {
        final controller = StreamController<GroupInfo?>.broadcast();
        when(
          () => repo.watchActiveGroup(),
        ).thenAnswer((_) => controller.stream);

        final container = ProviderContainer(
          overrides: [groupRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(() async {
          await controller.close();
          container.dispose();
        });

        final sub = container.listen(activeGroupProvider, (previous, next) {});
        addTearDown(sub.close);
        final statusSub = container.listen(
          syncStatusNotifierProvider,
          (previous, next) {},
        );
        addTearDown(statusSub.close);

        controller.add(_buildActiveGroup());
        await container.read(activeGroupProvider.future);
        expect(container.read(syncStatusNotifierProvider), SyncStatus.synced);

        container
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.syncing);

        controller.add(
          _buildActiveGroup().copyWith(lastSyncAt: DateTime(2026, 3, 14, 9)),
        );
        await Future<void>.delayed(Duration.zero);

        expect(container.read(syncStatusNotifierProvider), SyncStatus.syncing);
      },
    );
  });
}

GroupInfo _buildActiveGroup() {
  return GroupInfo(
    groupId: 'group-1',
    groupName: 'Test Family',
    status: GroupStatus.active,
    role: 'owner',
    members: const [],
    createdAt: DateTime(2026, 3, 14),
  );
}
