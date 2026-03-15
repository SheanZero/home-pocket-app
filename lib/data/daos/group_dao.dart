import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/groups_table.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [Groups])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<void> insert(GroupsCompanion entry) => into(groups).insert(entry);

  Future<void> deletePendingGroups() => (delete(groups)
        ..where(
          (table) =>
              table.status.equals('pending') |
              table.status.equals('confirming'),
        ))
      .go();

  Future<GroupData?> findByGroupId(String groupId) => (select(
    groups,
  )..where((table) => table.groupId.equals(groupId))).getSingleOrNull();

  Future<GroupData?> findActive() => (select(
    groups,
  )..where((table) => table.status.equals('active'))).getSingleOrNull();

  Stream<GroupData?> watchActiveGroup() => (select(
    groups,
  )..where((table) => table.status.equals('active'))).watchSingleOrNull();

  Future<GroupData?> findPending() =>
      (select(groups)..where(
            (table) =>
                table.status.equals('pending') |
                table.status.equals('confirming'),
          ))
          .getSingleOrNull();

  Future<void> updateStatus(String groupId, String status) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(status: Value(status)),
      );

  Future<void> updateGroupKey(String groupId, String groupKey) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(groupKey: Value(groupKey)),
      );

  Future<void> updateConfirmedAt(String groupId, int confirmedAt) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(
          status: const Value('active'),
          confirmedAt: Value(confirmedAt),
        ),
      );

  Future<void> updateLastSyncAt(String groupId, int lastSyncAt) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(lastSyncAt: Value(lastSyncAt)),
      );

  Future<void> updateInvite(String groupId, String code, int expiresAt) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(
          inviteCode: Value(code),
          inviteExpiresAt: Value(expiresAt),
        ),
      );
}
