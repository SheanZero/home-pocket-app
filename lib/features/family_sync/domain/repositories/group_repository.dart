import '../models/group_info.dart';
import '../models/group_member.dart';
import '../models/member_content_version.dart';

abstract class GroupRepository {
  Future<void> savePendingGroup({
    required String groupId,
    required String groupName,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,
    int keyEpoch = 1,
  });

  Future<void> saveConfirmingGroup({
    required String groupId,
    required String groupName,
    required List<GroupMember> members,
    String role = 'member',
    int keyEpoch = 1,
  });

  Future<void> restoreActiveGroup({
    required String groupId,
    required String role,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String groupKey,
    required List<GroupMember> members,
    int keyEpoch = 1,
  });

  Future<void> activateMember(String groupId, String deviceId);

  Future<void> confirmLocalGroup(String groupId);

  /// Moves a locally active snapshot back to the non-active state while the
  /// device is waiting for the E2EE group key.
  Future<void> markGroupConfirming(String groupId);

  Future<void> storeGroupKey(String groupId, String groupKeyBase64);

  Future<void> storeGroupKeyForEpoch(
    String groupId, {
    required String groupKeyBase64,
    required int keyEpoch,
  });

  Future<void> clearGroupKeyForEpoch(String groupId, {required int keyEpoch});

  Future<GroupInfo?> getActiveGroup();
  Stream<GroupInfo?> watchActiveGroup();

  Future<GroupInfo?> getPendingGroup();

  /// Returns the only local pending, confirming, or active family.
  /// Implementations must fail closed when corrupt history contains more than
  /// one live row; callers must not choose an arbitrary family.
  Future<GroupInfo?> getCurrentGroup();

  Future<GroupInfo?> getGroupById(String groupId);

  /// Persists a completed reconciliation timestamp.
  ///
  /// When [expectedGroupId] is provided, storage must only update that group
  /// while it is still active. This prevents a late pull from stamping a new
  /// family after membership changes during network work. Returns whether the
  /// active group was still the expected group and the timestamp was written.
  Future<bool> updateLastSyncTime(DateTime syncTime, {String? expectedGroupId});

  Future<void> updateMembers(String groupId, List<GroupMember> members);

  Future<void> updateInviteCode(
    String groupId,
    String inviteCode,
    DateTime expiresAt,
  );

  Future<void> deactivateGroup(String groupId);

  /// Permanently removes a dissolved family and all group-scoped local state.
  Future<void> deleteGroup(String groupId);

  Future<void> updateGroupName(String groupId, String groupName);

  /// Updates a name only while [groupId] is still the locally active group.
  /// Returns false if membership changed before the write reached storage.
  Future<bool> updateActiveGroupName(String groupId, String groupName);

  /// Atomically applies server-authoritative role, epoch and membership.
  /// When the epoch advances, any key from the retired epoch is cleared.
  Future<bool> applyAuthoritativeSnapshot({
    required String groupId,
    required String groupName,
    required String role,
    required int keyEpoch,
    required List<GroupMember> members,
  });

  Future<void> updateMemberProfile({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? avatarImageHash,
  });

  /// Updates identity text without clearing a separately synchronized avatar.
  Future<void> updateMemberIdentity({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
  });
}

/// SQLCipher-backed member-version capability. Kept separate so lightweight
/// tests and non-persistent adapters remain source compatible.
abstract interface class VersionedGroupMemberRepository {
  Future<MemberContentVersion?> prepareLocalProfileVersion({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required String contentDigest,
    required DateTime now,
  });

  Future<MemberContentVersion?> prepareLocalAvatarVersion({
    required String groupId,
    required String deviceId,
    required String? avatarImagePath,
    required String? avatarImageHash,
    required String contentDigest,
    required DateTime now,
  });

  Future<bool> applyMemberIdentityVersioned({
    required String groupId,
    required String deviceId,
    required String displayName,
    required String avatarEmoji,
    required MemberContentVersion version,
  });

  Future<bool> applyMemberAvatarVersioned({
    required String groupId,
    required String deviceId,
    required String? avatarImagePath,
    required String? avatarImageHash,
    required MemberContentVersion version,
  });
}

/// Optional production capability for monotonic server control-plane state.
/// Legacy test doubles and older integrations may keep using [GroupRepository].
abstract class RevisionedGroupRepository {
  Future<bool> hasProcessedControlEvent(String eventId);

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
  });
}

/// Authenticated control-feed metadata settled by an authoritative snapshot.
///
/// These values are audit/invalidation evidence only. Business state always
/// comes from the group status snapshot that covers [revision].
class ControlEventMetadata {
  const ControlEventMetadata({
    required this.eventId,
    required this.groupId,
    required this.revision,
    required this.eventType,
    required this.occurredAt,
  });

  final String eventId;
  final String groupId;
  final int revision;
  final String eventType;
  final DateTime occurredAt;
}

class ControlSnapshotConflictException implements Exception {
  const ControlSnapshotConflictException({
    required this.groupId,
    required this.revision,
  });

  final String groupId;
  final int revision;

  @override
  String toString() =>
      'ControlSnapshotConflictException(groupId: $groupId, revision: $revision)';
}

/// SQLCipher-backed write-ahead record for a membership rotation.  Key
/// material never leaves encrypted local storage except as per-device sealed
/// envelopes sent to the zero-knowledge relay.
class MembershipRotationIntent {
  const MembershipRotationIntent({
    required this.groupId,
    required this.requestId,
    required this.operation,
    required this.targetDeviceId,
    required this.expectedKeyEpoch,
    required this.newKeyEpoch,
    required this.groupKey,
    required this.envelopes,
    required this.createdAt,
  });

  final String groupId;
  final String requestId;
  final String operation;
  final String targetDeviceId;
  final int expectedKeyEpoch;
  final int newKeyEpoch;
  final String? groupKey;
  final List<Map<String, dynamic>> envelopes;
  final DateTime createdAt;
}

/// Optional production capability kept separate from [GroupRepository] so
/// existing test doubles do not silently pretend to offer crash recovery.
abstract class MembershipRotationIntentStore {
  Future<void> saveMembershipRotationIntent(MembershipRotationIntent intent);

  Future<MembershipRotationIntent?> getMembershipRotationIntent(String groupId);

  Future<void> clearMembershipRotationIntent(
    String groupId, {
    required String requestId,
  });

  /// Installs the already-generated key, applies the exact remaining member
  /// set, and clears the intent in one local SQL transaction.
  Future<void> completeMembershipRotationLocally({
    required MembershipRotationIntent intent,
    required List<GroupMember> members,
  });
}
