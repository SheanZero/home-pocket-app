import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/inbound_sync_operation_repository.dart';
import 'package:home_pocket/features/shopping_list/domain/repositories/shopping_item_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockTransactionRepository extends Mock
    implements TransactionRepository {}

class _MockShoppingItemRepository extends Mock
    implements ShoppingItemRepository {}

class _MockShadowBookService extends Mock implements ShadowBookService {}

void main() {
  late AppDatabase database;
  late GroupRepositoryImpl groupRepository;
  late ApplySyncOperationsUseCase useCase;

  const members = [
    GroupMember(
      deviceId: 'device-a',
      publicKey: 'pk-a',
      deviceName: 'Phone A',
      role: 'owner',
      status: 'active',
      displayName: 'Server A',
      avatarEmoji: '🏠',
    ),
    GroupMember(
      deviceId: 'device-b',
      publicKey: 'pk-b',
      deviceName: 'Phone B',
      role: 'member',
      status: 'active',
      displayName: 'Server B',
      avatarEmoji: '🏠',
    ),
  ];

  setUp(() async {
    database = AppDatabase.forTesting();
    groupRepository = GroupRepositoryImpl(
      groupDao: GroupDao(database),
      memberDao: GroupMemberDao(database),
    );
    await groupRepository.restoreActiveGroup(
      groupId: 'group-1',
      role: 'owner',
      groupKey: 'group-key',
      members: members,
    );
    useCase = ApplySyncOperationsUseCase(
      transactionRepository: _MockTransactionRepository(),
      shoppingItemRepository: _MockShoppingItemRepository(),
      shadowBookService: _MockShadowBookService(),
      groupRepository: groupRepository,
      inboundRepository: MemoryInboundSyncOperationRepository(),
    );
  });

  tearDown(() => database.close());

  Map<String, dynamic> profileOperation({
    required String operationId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    int? revision,
    bool includeDigest = true,
  }) {
    final digest = sha256
        .convert(utf8.encode(jsonEncode([displayName, avatarEmoji])))
        .toString();
    return {
      'op': 'update',
      'entityType': 'profile',
      'entityId': deviceId,
      'operationId': operationId,
      'fromDeviceId': deviceId,
      'revision': ?revision,
      if (revision != null) 'originDeviceId': deviceId,
      'data': {
        'schemaVersion': 1,
        'ownerDeviceId': deviceId,
        'revision': ?revision,
        if (includeDigest) 'profileDigest': digest,
        'displayName': displayName,
        'avatarEmoji': avatarEmoji,
      },
    };
  }

  test(
    'newer then older and duplicate deliveries never roll profile back',
    () async {
      final newer = profileOperation(
        operationId: 'profile-new',
        deviceId: 'device-a',
        displayName: 'New A',
        avatarEmoji: '🌱',
        revision: 20,
      );
      final older = profileOperation(
        operationId: 'profile-old',
        deviceId: 'device-a',
        displayName: 'Old A',
        avatarEmoji: '🐛',
        revision: 19,
      );

      final result = await useCase.execute([
        newer,
        older,
        newer,
      ], groupId: 'group-1');

      expect(result.operations.map((entry) => entry.status), [
        SyncOperationApplyStatus.applied,
        SyncOperationApplyStatus.applied,
        SyncOperationApplyStatus.alreadyApplied,
      ]);
      final member = (await groupRepository.getActiveGroup())!.members.first;
      expect(member.displayName, 'New A');
      expect(member.profileRevision, 20);
    },
  );

  test(
    'legacy revision-zero payload applies once then loses to versioned state',
    () async {
      final legacy = profileOperation(
        operationId: 'legacy-first',
        deviceId: 'device-a',
        displayName: 'Legacy A',
        avatarEmoji: '🌿',
        includeDigest: false,
      );
      await useCase.execute([legacy], groupId: 'group-1');
      expect(
        (await groupRepository.getActiveGroup())!.members.first.displayName,
        'Legacy A',
      );

      await useCase.execute([
        profileOperation(
          operationId: 'versioned',
          deviceId: 'device-a',
          displayName: 'Versioned A',
          avatarEmoji: '🌱',
          revision: 5,
        ),
        {...legacy, 'operationId': 'legacy-late'},
      ], groupId: 'group-1');

      final member = (await groupRepository.getActiveGroup())!.members.first;
      expect(member.displayName, 'Versioned A');
      expect(member.profileRevision, 5);
    },
  );

  test(
    'same revision digest tie converges regardless of arrival order',
    () async {
      List<Map<String, dynamic>> operations(String deviceId) => [
        profileOperation(
          operationId: '$deviceId-low',
          deviceId: deviceId,
          displayName: 'Alpha',
          avatarEmoji: '🌱',
          revision: 30,
        ),
        profileOperation(
          operationId: '$deviceId-high',
          deviceId: deviceId,
          displayName: 'Zulu',
          avatarEmoji: '🌳',
          revision: 30,
        ),
      ];

      await useCase.execute(operations('device-a'), groupId: 'group-1');
      await useCase.execute(
        operations('device-b').reversed.toList(),
        groupId: 'group-1',
      );

      final current = (await groupRepository.getActiveGroup())!.members;
      final a = current.singleWhere((member) => member.deviceId == 'device-a');
      final b = current.singleWhere((member) => member.deviceId == 'device-b');
      expect(a.profileDigest, b.profileDigest);
      expect(a.displayName, b.displayName);
      expect(a.avatarEmoji, b.avatarEmoji);
    },
  );
}
