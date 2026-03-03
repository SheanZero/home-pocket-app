import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_management_screen.dart';
import 'package:home_pocket/features/family_sync/presentation/widgets/family_sync_settings_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

class TestSyncStatusNotifier extends SyncStatusNotifier {
  TestSyncStatusNotifier(this.initialState);

  final SyncStatus initialState;

  @override
  SyncStatus build() => initialState;
}

void main() {
  late MockGroupRepository groupRepository;

  setUp(() {
    groupRepository = MockGroupRepository();
    when(() => groupRepository.getActiveGroup()).thenAnswer(
      (_) async => GroupInfo(
        groupId: 'group-1',
        bookId: 'book-1',
        status: GroupStatus.active,
        role: 'owner',
        members: const [
          GroupMember(
            deviceId: 'owner-1',
            publicKey: 'pk-owner',
            deviceName: 'Owner phone',
            role: 'owner',
            status: 'active',
          ),
        ],
        createdAt: DateTime(2026, 3, 1),
      ),
    );
  });

  testWidgets('navigates to GroupManagementScreen when already paired', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        Scaffold(body: FamilySyncSettingsSection(bookId: 'book-1')),
        overrides: [
          groupRepositoryProvider.overrideWithValue(groupRepository),
          syncStatusNotifierProvider.overrideWith(
            () => TestSyncStatusNotifier(SyncStatus.synced),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();

    expect(find.byType(GroupManagementScreen), findsOneWidget);
  });
}
