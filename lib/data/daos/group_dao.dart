import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/groups_table.dart';

part 'group_dao.g.dart';

class ActiveGroupSnapshot {
  const ActiveGroupSnapshot({required this.group, required this.members});

  final GroupData group;
  final List<GroupMemberData> members;
}

@DriftAccessor(tables: [Groups])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<void> insert(GroupsCompanion entry) => into(groups).insert(entry);

  Future<void> deletePendingGroups() =>
      (delete(groups)..where(
            (table) =>
                table.status.equals('pending') |
                table.status.equals('confirming'),
          ))
          .go();

  Future<GroupData?> findByGroupId(String groupId) => (select(
    groups,
  )..where((table) => table.groupId.equals(groupId))).getSingleOrNull();

  Future<GroupData?> findActive() => _findOnly(
    (select(groups)..where((table) => table.status.equals('active'))),
    context: 'active',
  );

  Stream<GroupData?> watchActiveGroup() => _watchOnly(
    (select(groups)..where((table) => table.status.equals('active'))),
    context: 'active',
  );

  /// Watches the complete active-group projection, including membership rows.
  ///
  /// A group-only query does not invalidate when a member changes from
  /// pending to active, which left the family-management screen displaying
  /// the approval banner indefinitely. The join makes Drift observe both
  /// tables while preserving the single-live-group invariant.
  Stream<ActiveGroupSnapshot?> watchActiveGroupSnapshot() {
    final membersTable = attachedDatabase.groupMembers;
    final query = select(groups).join([
      leftOuterJoin(
        membersTable,
        membersTable.groupId.equalsExp(groups.groupId),
      ),
    ])..where(groups.status.equals('active'));

    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final groupRows = <String, GroupData>{};
      final members = <GroupMemberData>[];
      for (final row in rows) {
        final group = row.readTable(groups);
        groupRows[group.groupId] = group;
        final member = row.readTableOrNull(membersTable);
        if (member != null) members.add(member);
      }
      if (groupRows.length > 1) {
        throw StateError('Multiple active family groups found');
      }
      return ActiveGroupSnapshot(
        group: groupRows.values.single,
        members: members,
      );
    });
  }

  Future<GroupData?> findPending() => _findOnly(
    (select(groups)..where(
      (table) =>
          table.status.equals('pending') | table.status.equals('confirming'),
    )),
    context: 'pending or confirming',
  );

  Future<GroupData?> findCurrent() => _findOnly(
    (select(groups)..where(
      (table) =>
          table.status.equals('pending') |
          table.status.equals('confirming') |
          table.status.equals('active'),
    )),
    context: 'pending, confirming, or active',
  );

  Future<GroupData?> _findOnly(
    SimpleSelectStatement<$GroupsTable, GroupData> query, {
    required String context,
  }) async {
    query
      ..orderBy([(table) => OrderingTerm.asc(table.groupId)])
      ..limit(2);
    final rows = await query.get();
    if (rows.length > 1) {
      throw StateError('Multiple $context family groups found');
    }
    return rows.firstOrNull;
  }

  Stream<GroupData?> _watchOnly(
    SimpleSelectStatement<$GroupsTable, GroupData> query, {
    required String context,
  }) {
    query
      ..orderBy([(table) => OrderingTerm.asc(table.groupId)])
      ..limit(2);
    return query.watch().map((rows) {
      if (rows.length > 1) {
        throw StateError('Multiple $context family groups found');
      }
      return rows.firstOrNull;
    });
  }

  Future<void> updateStatus(String groupId, String status) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(status: Value(status)),
      );

  Future<void> deactivateAndClearSecrets(String groupId) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        const GroupsCompanion(
          status: Value('inactive'),
          inviteCode: Value(null),
          inviteExpiresAt: Value(null),
          groupKey: Value(null),
          confirmedAt: Value(null),
          lastSyncAt: Value(null),
        ),
      );

  Future<void> deleteByGroupId(String groupId) =>
      (delete(groups)..where((table) => table.groupId.equals(groupId))).go();

  Future<void> updateGroupKey(String groupId, String groupKey) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(groupKey: Value(groupKey)),
      );

  Future<void> updateGroupKeyForEpoch(
    String groupId, {
    required String groupKey,
    required int keyEpoch,
  }) => (update(groups)..where((table) => table.groupId.equals(groupId))).write(
    GroupsCompanion(groupKey: Value(groupKey), keyEpoch: Value(keyEpoch)),
  );

  Future<void> clearGroupKeyForEpoch(String groupId, {required int keyEpoch}) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(groupKey: const Value(null), keyEpoch: Value(keyEpoch)),
      );

  Future<void> updateConfirmedAt(String groupId, int confirmedAt) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(
          status: const Value('active'),
          confirmedAt: Value(confirmedAt),
        ),
      );

  Future<int> updateActiveLastSyncAt(String groupId, int lastSyncAt) =>
      (update(groups)..where(
            (table) =>
                table.groupId.equals(groupId) & table.status.equals('active'),
          ))
          .write(GroupsCompanion(lastSyncAt: Value(lastSyncAt)));

  Future<void> updateInvite(String groupId, String code, int expiresAt) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(
          inviteCode: Value(code),
          inviteExpiresAt: Value(expiresAt),
        ),
      );

  Future<void> updateGroupName(String groupId, String groupName) =>
      (update(groups)..where((table) => table.groupId.equals(groupId))).write(
        GroupsCompanion(groupName: Value(groupName)),
      );

  Future<int> updateActiveGroupName(String groupId, String groupName) =>
      (update(groups)..where(
            (table) =>
                table.groupId.equals(groupId) & table.status.equals('active'),
          ))
          .write(GroupsCompanion(groupName: Value(groupName)));

  Future<int> updateActiveControlPlane({
    required String groupId,
    required String groupName,
    required String role,
    required int keyEpoch,
    required bool clearRetiredKey,
    int? controlRevision,
    int? controlUpdatedAt,
    String? controlSnapshotDigest,
  }) =>
      (update(groups)..where(
            (table) =>
                table.groupId.equals(groupId) & table.status.equals('active'),
          ))
          .write(
            GroupsCompanion(
              groupName: Value(groupName),
              role: Value(role),
              keyEpoch: Value(keyEpoch),
              groupKey: clearRetiredKey
                  ? const Value(null)
                  : const Value.absent(),
              controlRevision: controlRevision == null
                  ? const Value.absent()
                  : Value(controlRevision),
              controlUpdatedAt: controlUpdatedAt == null
                  ? const Value.absent()
                  : Value(controlUpdatedAt),
              controlSnapshotDigest: controlSnapshotDigest == null
                  ? const Value.absent()
                  : Value(controlSnapshotDigest),
            ),
          );
}
