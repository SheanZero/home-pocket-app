import 'dart:convert';

import 'package:drift/drift.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/models/member_content_version.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../app_database.dart';
import '../daos/group_dao.dart';
import '../daos/group_member_dao.dart';

class GroupRepositoryImpl
    implements
        GroupRepository,
        RevisionedGroupRepository,
        MembershipRotationIntentStore,
        VersionedGroupMemberRepository {
  GroupRepositoryImpl({required this._groupDao, required this._memberDao});

  final GroupDao _groupDao;
  final GroupMemberDao _memberDao;

  @override
  Future<void> saveMembershipRotationIntent(
    MembershipRotationIntent intent,
  ) async {
    final inserted = await _groupDao.attachedDatabase.customUpdate(
      '''
        INSERT INTO membership_rotation_intents (
          group_id, request_id, operation, target_device_id,
          expected_key_epoch, new_key_epoch, group_key,
          envelopes_json, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(group_id) DO NOTHING
      ''',
      variables: [
        Variable<String>(intent.groupId),
        Variable<String>(intent.requestId),
        Variable<String>(intent.operation),
        Variable<String>(intent.targetDeviceId),
        Variable<int>(intent.expectedKeyEpoch),
        Variable<int>(intent.newKeyEpoch),
        Variable<String>(intent.groupKey),
        Variable<String>(jsonEncode(intent.envelopes)),
        Variable<int>(intent.createdAt.millisecondsSinceEpoch),
      ],
    );
    if (inserted == 1) return;
    final existing = await getMembershipRotationIntent(intent.groupId);
    if (existing == null ||
        existing.requestId != intent.requestId ||
        existing.operation != intent.operation ||
        existing.targetDeviceId != intent.targetDeviceId ||
        existing.expectedKeyEpoch != intent.expectedKeyEpoch ||
        existing.newKeyEpoch != intent.newKeyEpoch ||
        existing.groupKey != intent.groupKey ||
        jsonEncode(existing.envelopes) != jsonEncode(intent.envelopes)) {
      throw StateError('Conflicting membership rotation intent');
    }
  }

  @override
  Future<MembershipRotationIntent?> getMembershipRotationIntent(
    String groupId,
  ) async {
    final row = await _groupDao.attachedDatabase
        .customSelect(
          '''
            SELECT group_id, request_id, operation, target_device_id,
                   expected_key_epoch, new_key_epoch, group_key,
                   envelopes_json, created_at
            FROM membership_rotation_intents WHERE group_id = ?
          ''',
          variables: [Variable<String>(groupId)],
        )
        .getSingleOrNull();
    if (row == null) return null;
    final decoded = jsonDecode(row.read<String>('envelopes_json'));
    if (decoded is! List) {
      throw const FormatException('Invalid membership rotation envelopes');
    }
    return MembershipRotationIntent(
      groupId: row.read<String>('group_id'),
      requestId: row.read<String>('request_id'),
      operation: row.read<String>('operation'),
      targetDeviceId: row.read<String>('target_device_id'),
      expectedKeyEpoch: row.read<int>('expected_key_epoch'),
      newKeyEpoch: row.read<int>('new_key_epoch'),
      groupKey: row.readNullable<String>('group_key'),
      envelopes: decoded
          .whereType<Map>()
          .map(
            (entry) =>
                entry.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList(growable: false),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at'),
      ),
    );
  }

  @override
  Future<void> clearMembershipRotationIntent(
    String groupId, {
    required String requestId,
  }) async {
    await _groupDao.attachedDatabase.customStatement(
      'DELETE FROM membership_rotation_intents '
      'WHERE group_id = ? AND request_id = ?',
      [groupId, requestId],
    );
  }

  @override
  Future<void> completeMembershipRotationLocally({
    required MembershipRotationIntent intent,
    required List<GroupMember> members,
  }) async {
    final key = intent.groupKey;
    if (key == null || key.isEmpty) {
      throw StateError('Membership rotation intent has no group key');
    }
    await _groupDao.attachedDatabase.transaction(() async {
      final updated = await _groupDao.attachedDatabase.customUpdate(
        'UPDATE groups SET group_key = ?, key_epoch = ? '
        'WHERE group_id = ? AND status = ?',
        variables: [
          Variable<String>(key),
          Variable<int>(intent.newKeyEpoch),
          Variable<String>(intent.groupId),
          const Variable<String>('active'),
        ],
      );
      if (updated != 1) {
        throw StateError('Active family changed during membership rotation');
      }
      await _replaceMembersPreservingE2ee(intent.groupId, members);
      await clearMembershipRotationIntent(
        intent.groupId,
        requestId: intent.requestId,
      );
    });
  }

  @override
  Future<bool> hasProcessedControlEvent(String eventId) async {
    if (eventId.isEmpty) return false;
    final row = await _groupDao.attachedDatabase
        .customSelect(
          'SELECT 1 FROM control_events WHERE event_id = ? LIMIT 1',
          variables: [Variable<String>(eventId)],
        )
        .getSingleOrNull();
    return row != null;
  }

  @override
  Future<void> savePendingGroup({
    required String groupId,
    required String groupName,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,
    int keyEpoch = 1,
  }) async {
    await _groupDao.attachedDatabase.transaction(() async {
      await _groupDao.deletePendingGroups();
      await _groupDao.insert(
        GroupsCompanion.insert(
          groupId: groupId,
          status: 'pending',
          role: 'owner',
          groupName: Value(groupName),
          inviteCode: Value(inviteCode),
          inviteExpiresAt: Value(inviteExpiresAt.millisecondsSinceEpoch),
          groupKey: Value(groupKey),
          keyEpoch: Value(keyEpoch),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
    });
  }

  @override
  Future<void> saveConfirmingGroup({
    required String groupId,
    required String groupName,
    required List<GroupMember> members,
    String role = 'member',
    int keyEpoch = 1,
  }) async {
    await _groupDao.insert(
      GroupsCompanion.insert(
        groupId: groupId,
        status: 'confirming',
        role: role,
        groupName: Value(groupName),
        keyEpoch: Value(keyEpoch),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _memberDao.insertAll(_toCompanions(groupId, members));
  }

  @override
  Future<void> restoreActiveGroup({
    required String groupId,
    required String role,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String groupKey,
    required List<GroupMember> members,
    int keyEpoch = 1,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    await _groupDao.attachedDatabase.transaction(() async {
      await _groupDao.insert(
        GroupsCompanion.insert(
          groupId: groupId,
          status: 'active',
          role: role,
          inviteCode: Value(inviteCode),
          inviteExpiresAt: Value(inviteExpiresAt?.millisecondsSinceEpoch),
          groupKey: Value(groupKey),
          keyEpoch: Value(keyEpoch),
          createdAt: now,
          confirmedAt: Value(now),
        ),
      );
      await _memberDao.replaceAll(groupId, _toCompanions(groupId, members));
    });
  }

  @override
  Future<void> activateMember(String groupId, String deviceId) =>
      _memberDao.updateStatus(groupId, deviceId, 'active');

  @override
  Future<void> confirmLocalGroup(String groupId) async {
    final group = await _groupDao.findByGroupId(groupId);
    if (group == null || group.groupKey == null || group.groupKey!.isEmpty) {
      throw StateError('Cannot activate a group without its E2EE group key');
    }

    await _groupDao.updateConfirmedAt(
      groupId,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> markGroupConfirming(String groupId) =>
      _groupDao.updateStatus(groupId, 'confirming');

  @override
  Future<void> storeGroupKey(String groupId, String groupKeyBase64) =>
      _groupDao.updateGroupKey(groupId, groupKeyBase64);

  @override
  Future<void> storeGroupKeyForEpoch(
    String groupId, {
    required String groupKeyBase64,
    required int keyEpoch,
  }) => _groupDao.updateGroupKeyForEpoch(
    groupId,
    groupKey: groupKeyBase64,
    keyEpoch: keyEpoch,
  );

  @override
  Future<void> clearGroupKeyForEpoch(String groupId, {required int keyEpoch}) =>
      _groupDao.clearGroupKeyForEpoch(groupId, keyEpoch: keyEpoch);

  @override
  Future<GroupInfo?> getActiveGroup() async {
    final group = await _groupDao.findActive();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Stream<GroupInfo?> watchActiveGroup() {
    return _groupDao.watchActiveGroup().asyncMap((group) async {
      if (group == null) {
        return null;
      }
      return _toGroupInfo(group);
    });
  }

  @override
  Future<GroupInfo?> getPendingGroup() async {
    final group = await _groupDao.findPending();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getCurrentGroup() async {
    final group = await _groupDao.findCurrent();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getGroupById(String groupId) async {
    final group = await _groupDao.findByGroupId(groupId);
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<bool> updateLastSyncTime(
    DateTime syncTime, {
    String? expectedGroupId,
  }) async {
    if (expectedGroupId != null) {
      return await _groupDao.updateActiveLastSyncAt(
            expectedGroupId,
            syncTime.millisecondsSinceEpoch,
          ) >
          0;
    }

    final group = await _groupDao.findActive();
    if (group == null) return false;
    return await _groupDao.updateActiveLastSyncAt(
          group.groupId,
          syncTime.millisecondsSinceEpoch,
        ) >
        0;
  }

  @override
  Future<void> updateMembers(String groupId, List<GroupMember> members) =>
      _groupDao.attachedDatabase.transaction(
        () => _replaceMembersPreservingE2ee(groupId, members),
      );

  @override
  Future<void> updateInviteCode(
    String groupId,
    String inviteCode,
    DateTime expiresAt,
  ) => _groupDao.updateInvite(
    groupId,
    inviteCode,
    expiresAt.millisecondsSinceEpoch,
  );

  @override
  Future<void> deactivateGroup(String groupId) async {
    await _groupDao.attachedDatabase.transaction(() async {
      await _deleteGroupScopedData(groupId);
      await _groupDao.deactivateAndClearSecrets(groupId);
    });
  }

  @override
  Future<void> deleteGroup(String groupId) async {
    await _groupDao.attachedDatabase.transaction(() async {
      await _deleteGroupScopedData(groupId);
      await _groupDao.deleteByGroupId(groupId);
    });
  }

  Future<void> _deleteGroupScopedData(String groupId) async {
    await _groupDao.attachedDatabase.customStatement(
      'DELETE FROM family_sync_outbox WHERE group_id = ?',
      [groupId],
    );
    await _groupDao.attachedDatabase.customStatement(
      'DELETE FROM inbound_sync_operations WHERE group_id = ?',
      [groupId],
    );
    await _memberDao.deleteByGroupId(groupId);
  }

  @override
  Future<void> updateGroupName(String groupId, String groupName) =>
      _groupDao.updateGroupName(groupId, groupName);

  @override
  Future<bool> updateActiveGroupName(String groupId, String groupName) async {
    final rows = await _groupDao.updateActiveGroupName(groupId, groupName);
    return rows == 1;
  }

  @override
  Future<bool> applyAuthoritativeSnapshot({
    required String groupId,
    required String groupName,
    required String role,
    required int keyEpoch,
    required List<GroupMember> members,
  }) async {
    return _groupDao.attachedDatabase.transaction(() async {
      final current = await _groupDao.findByGroupId(groupId);
      if (current == null || current.status != 'active') return false;
      final updated = await _groupDao.updateActiveControlPlane(
        groupId: groupId,
        groupName: groupName,
        role: role,
        keyEpoch: keyEpoch,
        clearRetiredKey: current.keyEpoch != keyEpoch,
      );
      if (updated != 1) return false;
      await _replaceMembersPreservingE2ee(groupId, members);
      return true;
    });
  }

  @override
  Future<bool> applyRevisionedAuthoritativeSnapshot({
    required String groupId,
    required String groupName,
    required String role,
    required int keyEpoch,
    required List<GroupMember> members,
    required int revision,
    required DateTime updatedAt,
    required String snapshotDigest,
    String? eventId,
    int? eventRevision,
    String? eventType,
    DateTime? eventOccurredAt,
    List<ControlEventMetadata> controlEvents = const [],
  }) async {
    if (revision < 0 || snapshotDigest.isEmpty) {
      throw ArgumentError('Invalid control-plane snapshot metadata');
    }
    if (controlEvents.any(
      (event) =>
          event.groupId != groupId ||
          event.eventId.isEmpty ||
          event.revision <= 0 ||
          event.revision > revision,
    )) {
      throw ArgumentError('Control events are not covered by the snapshot');
    }
    return _groupDao.attachedDatabase.transaction(() async {
      final current = await _groupDao.findByGroupId(groupId);
      if (current == null || current.status != 'active') return false;
      if (revision < current.controlRevision) return false;
      if (revision == current.controlRevision &&
          current.controlSnapshotDigest.isNotEmpty &&
          current.controlSnapshotDigest != snapshotDigest) {
        throw ControlSnapshotConflictException(
          groupId: groupId,
          revision: revision,
        );
      }
      if (revision == current.controlRevision &&
          current.controlSnapshotDigest == snapshotDigest) {
        await _recordControlEvent(
          eventId: eventId,
          groupId: groupId,
          revision: eventRevision ?? revision,
          eventType: eventType,
          occurredAt: eventOccurredAt,
        );
        await _recordControlEvents(controlEvents);
        return false;
      }

      final updated = await _groupDao.updateActiveControlPlane(
        groupId: groupId,
        groupName: groupName,
        role: role,
        keyEpoch: keyEpoch,
        clearRetiredKey: current.keyEpoch != keyEpoch,
        controlRevision: revision,
        controlUpdatedAt: updatedAt.millisecondsSinceEpoch,
        controlSnapshotDigest: snapshotDigest,
      );
      if (updated != 1) return false;
      await _replaceMembersPreservingE2ee(groupId, members);
      await _recordControlEvent(
        eventId: eventId,
        groupId: groupId,
        revision: eventRevision ?? revision,
        eventType: eventType,
        occurredAt: eventOccurredAt,
      );
      await _recordControlEvents(controlEvents);
      return true;
    });
  }

  Future<void> _recordControlEvents(List<ControlEventMetadata> events) async {
    for (final event in events) {
      await _recordControlEvent(
        eventId: event.eventId,
        groupId: event.groupId,
        revision: event.revision,
        eventType: event.eventType,
        occurredAt: event.occurredAt,
      );
    }
  }

  Future<void> _recordControlEvent({
    required String? eventId,
    required String groupId,
    required int revision,
    required String? eventType,
    required DateTime? occurredAt,
  }) async {
    if (eventId == null || eventId.isEmpty || revision <= 0) return;
    await _groupDao.attachedDatabase.customStatement(
      '''INSERT OR IGNORE INTO control_events
         (event_id, group_id, revision, event_type, occurred_at, processed_at)
         VALUES (?, ?, ?, ?, ?, ?)''',
      [
        eventId,
        groupId,
        revision,
        eventType ?? 'snapshot_invalidated',
        (occurredAt ?? DateTime.now()).millisecondsSinceEpoch,
        DateTime.now().millisecondsSinceEpoch,
      ],
    );
  }

  @override
  Future<MemberContentVersion?> prepareLocalProfileVersion({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required String contentDigest,
    required DateTime now,
  }) {
    return _groupDao.attachedDatabase.transaction(() async {
      final row = await _memberDao.findByGroupAndDevice(groupId, deviceId);
      if (row == null || row.status != 'active') return null;
      final current = _profileVersion(row);
      if (current.contentDigest == contentDigest &&
          row.displayName == displayName &&
          row.avatarEmoji == avatarEmoji) {
        return current;
      }
      final next = MemberContentVersion(
        revision: MemberContentVersion.nextRevision(
          current: current.revision,
          now: now,
        ),
        originDeviceId: deviceId,
        contentDigest: contentDigest,
      );
      final updated = await _memberDao.updateMemberIdentityVersioned(
        groupId: groupId,
        deviceId: deviceId,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        revision: next.revision,
        originDeviceId: next.originDeviceId,
        digest: next.contentDigest,
      );
      return updated == 1 ? next : null;
    });
  }

  @override
  Future<MemberContentVersion?> prepareLocalAvatarVersion({
    required String groupId,
    required String deviceId,
    required String? avatarImagePath,
    required String? avatarImageHash,
    required String contentDigest,
    required DateTime now,
  }) {
    return _groupDao.attachedDatabase.transaction(() async {
      final row = await _memberDao.findByGroupAndDevice(groupId, deviceId);
      if (row == null || row.status != 'active') return null;
      final current = _avatarVersion(row);
      if (current.contentDigest == contentDigest) {
        if (row.avatarImagePath != avatarImagePath ||
            row.avatarImageHash != avatarImageHash) {
          await _memberDao.updateMemberAvatarVersioned(
            groupId: groupId,
            deviceId: deviceId,
            avatarImagePath: avatarImagePath,
            avatarImageHash: avatarImageHash,
            revision: current.revision,
            originDeviceId: current.originDeviceId,
            contentHash: current.contentDigest,
          );
        }
        return current;
      }
      final next = MemberContentVersion(
        revision: MemberContentVersion.nextRevision(
          current: current.revision,
          now: now,
        ),
        originDeviceId: deviceId,
        contentDigest: contentDigest,
      );
      final updated = await _memberDao.updateMemberAvatarVersioned(
        groupId: groupId,
        deviceId: deviceId,
        avatarImagePath: avatarImagePath,
        avatarImageHash: avatarImageHash,
        revision: next.revision,
        originDeviceId: next.originDeviceId,
        contentHash: next.contentDigest,
      );
      return updated == 1 ? next : null;
    });
  }

  @override
  Future<bool> applyMemberIdentityVersioned({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required MemberContentVersion version,
  }) {
    return _groupDao.attachedDatabase.transaction(() async {
      final row = await _memberDao.findByGroupAndDevice(groupId, deviceId);
      if (row == null || row.status != 'active') return false;
      if (!version.isStrictlyNewerThan(_profileVersion(row))) return false;
      return await _memberDao.updateMemberIdentityVersioned(
            groupId: groupId,
            deviceId: deviceId,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            revision: version.revision,
            originDeviceId: version.originDeviceId,
            digest: version.contentDigest,
          ) ==
          1;
    });
  }

  @override
  Future<bool> applyMemberAvatarVersioned({
    required String groupId,
    required String deviceId,
    required String? avatarImagePath,
    required String? avatarImageHash,
    required MemberContentVersion version,
  }) {
    return _groupDao.attachedDatabase.transaction(() async {
      final row = await _memberDao.findByGroupAndDevice(groupId, deviceId);
      if (row == null || row.status != 'active') return false;
      if (!version.isStrictlyNewerThan(_avatarVersion(row))) return false;
      return await _memberDao.updateMemberAvatarVersioned(
            groupId: groupId,
            deviceId: deviceId,
            avatarImagePath: avatarImagePath,
            avatarImageHash: avatarImageHash,
            revision: version.revision,
            originDeviceId: version.originDeviceId,
            contentHash: version.contentDigest,
          ) ==
          1;
    });
  }

  @override
  Future<void> updateMemberProfile({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  }) => _memberDao.updateMemberProfile(
    groupId: groupId,
    deviceId: deviceId,
    displayName: displayName,
    avatarEmoji: avatarEmoji,
    avatarImagePath: avatarImagePath,
    avatarImageHash: avatarImageHash,
  );

  @override
  Future<void> updateMemberIdentity({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
  }) => _memberDao.updateMemberIdentity(
    groupId: groupId,
    deviceId: deviceId,
    displayName: displayName,
    avatarEmoji: avatarEmoji,
  );

  Future<void> _replaceMembersPreservingE2ee(
    String groupId,
    List<GroupMember> incoming,
  ) async {
    final existing = {
      for (final row in await _memberDao.findByGroupId(groupId))
        row.deviceId: row,
    };
    final merged = incoming
        .map((member) {
          final old = existing[member.deviceId];
          if (old == null) return member;

          final incomingProfile = MemberContentVersion(
            revision: member.profileRevision,
            originDeviceId: member.profileOriginDeviceId,
            contentDigest: member.profileDigest,
          );
          final oldProfile = _profileVersion(old);
          final preserveProfile =
              oldProfile.compareTo(incomingProfile) > 0 ||
              (oldProfile.compareTo(incomingProfile) == 0 &&
                  oldProfile.contentDigest.isNotEmpty);

          final incomingAvatar = MemberContentVersion(
            revision: member.avatarRevision,
            originDeviceId: member.avatarOriginDeviceId,
            contentDigest: member.avatarContentHash,
          );
          final oldAvatar = _avatarVersion(old);
          final preserveAvatar =
              oldAvatar.compareTo(incomingAvatar) > 0 ||
              (oldAvatar.compareTo(incomingAvatar) == 0 &&
                  (old.avatarImagePath != null ||
                      oldAvatar.contentDigest.isNotEmpty));

          return member.copyWith(
            displayName: preserveProfile ? old.displayName : member.displayName,
            avatarEmoji: preserveProfile ? old.avatarEmoji : member.avatarEmoji,
            profileRevision: preserveProfile
                ? old.profileRevision
                : member.profileRevision,
            profileOriginDeviceId: preserveProfile
                ? old.profileOriginDeviceId
                : member.profileOriginDeviceId,
            profileDigest: preserveProfile
                ? old.profileDigest
                : member.profileDigest,
            avatarImagePath: preserveAvatar
                ? old.avatarImagePath
                : member.avatarImagePath,
            avatarImageHash: preserveAvatar
                ? old.avatarImageHash
                : member.avatarImageHash,
            avatarRevision: preserveAvatar
                ? old.avatarRevision
                : member.avatarRevision,
            avatarOriginDeviceId: preserveAvatar
                ? old.avatarOriginDeviceId
                : member.avatarOriginDeviceId,
            avatarContentHash: preserveAvatar
                ? old.avatarContentHash
                : member.avatarContentHash,
          );
        })
        .toList(growable: false);
    await _memberDao.deleteByGroupId(groupId);
    await _memberDao.insertAll(_toCompanions(groupId, merged));
  }

  MemberContentVersion _profileVersion(GroupMemberData row) =>
      MemberContentVersion(
        revision: row.profileRevision,
        originDeviceId: row.profileOriginDeviceId,
        contentDigest: row.profileDigest,
      );

  MemberContentVersion _avatarVersion(GroupMemberData row) =>
      MemberContentVersion(
        revision: row.avatarRevision,
        originDeviceId: row.avatarOriginDeviceId,
        contentDigest: row.avatarContentHash,
      );

  List<GroupMembersCompanion> _toCompanions(
    String groupId,
    List<GroupMember> members,
  ) {
    return members
        .map(
          (member) => GroupMembersCompanion.insert(
            groupId: groupId,
            deviceId: member.deviceId,
            publicKey: member.publicKey,
            deviceName: member.deviceName,
            role: member.role,
            status: member.status,
            displayName: Value(member.displayName),
            avatarEmoji: Value(member.avatarEmoji),
            avatarImagePath: Value(member.avatarImagePath),
            avatarImageHash: Value(member.avatarImageHash),
            profileRevision: Value(member.profileRevision),
            profileOriginDeviceId: Value(member.profileOriginDeviceId),
            profileDigest: Value(member.profileDigest),
            avatarRevision: Value(member.avatarRevision),
            avatarOriginDeviceId: Value(member.avatarOriginDeviceId),
            avatarContentHash: Value(member.avatarContentHash),
            joinedAt: Value(member.joinedAt?.millisecondsSinceEpoch),
            confirmedAt: Value(member.confirmedAt?.millisecondsSinceEpoch),
            removedAt: Value(member.removedAt?.millisecondsSinceEpoch),
            removalReason: Value(member.removalReason),
          ),
        )
        .toList();
  }

  Future<GroupInfo> _toGroupInfo(GroupData group) async {
    final members = await _memberDao.findByGroupId(group.groupId);
    return GroupInfo(
      groupId: group.groupId,
      status: GroupStatus.values.byName(group.status),
      groupName: group.groupName,
      role: group.role,
      inviteCode: group.inviteCode,
      inviteExpiresAt: group.inviteExpiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.inviteExpiresAt!)
          : null,
      groupKey: group.groupKey,
      keyEpoch: group.keyEpoch,
      members: members
          .map(
            (member) => GroupMember(
              deviceId: member.deviceId,
              publicKey: member.publicKey,
              deviceName: member.deviceName,
              role: member.role,
              status: member.status,
              displayName: member.displayName,
              avatarEmoji: member.avatarEmoji,
              avatarImagePath: member.avatarImagePath,
              avatarImageHash: member.avatarImageHash,
              profileRevision: member.profileRevision,
              profileOriginDeviceId: member.profileOriginDeviceId,
              profileDigest: member.profileDigest,
              avatarRevision: member.avatarRevision,
              avatarOriginDeviceId: member.avatarOriginDeviceId,
              avatarContentHash: member.avatarContentHash,
              joinedAt: member.joinedAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(member.joinedAt!),
              confirmedAt: member.confirmedAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(member.confirmedAt!),
              removedAt: member.removedAt == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(member.removedAt!),
              removalReason: member.removalReason,
            ),
          )
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(group.createdAt),
      confirmedAt: group.confirmedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.confirmedAt!)
          : null,
      lastSyncAt: group.lastSyncAt != null
          ? DateTime.fromMillisecondsSinceEpoch(group.lastSyncAt!)
          : null,
      controlRevision: group.controlRevision,
      controlUpdatedAt: group.controlUpdatedAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(group.controlUpdatedAt!),
      controlSnapshotDigest: group.controlSnapshotDigest,
    );
  }
}
