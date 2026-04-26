import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository repo;

  setUp(() {
    repo = MockGroupRepository();
  });

  group('activeGroupProvider', () {
    test('isGroupMode is false when no active group exists', () async {
      when(() => repo.watchActiveGroup()).thenAnswer((_) => Stream.value(null));

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(activeGroupProvider.future);

      expect(container.read(isGroupModeProvider), isFalse);
    });

    test('isGroupMode is true when an active group exists', () async {
      when(
        () => repo.watchActiveGroup(),
      ).thenAnswer((_) => Stream.value(_buildActiveGroup()));

      final container = ProviderContainer(
        overrides: [groupRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await container.read(activeGroupProvider.future);

      expect(container.read(isGroupModeProvider), isTrue);
    });
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
