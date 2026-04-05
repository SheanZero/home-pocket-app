/// Event types for UI navigation routing (non-sync concerns).
enum SyncTriggerEventType {
  joinRequest,
  memberConfirmed,
  memberLeft,
  groupDissolved,
  syncAvailable,
}

/// UI navigation event emitted by push notifications.
///
/// Used by [FamilySyncNotificationRouteListener] to navigate
/// to the appropriate screen when a push event arrives.
class SyncTriggerEvent {
  const SyncTriggerEvent._({required this.type, this.groupId});

  const SyncTriggerEvent.joinRequest({String? groupId})
    : this._(type: SyncTriggerEventType.joinRequest, groupId: groupId);

  const SyncTriggerEvent.memberConfirmed({String? groupId})
    : this._(type: SyncTriggerEventType.memberConfirmed, groupId: groupId);

  const SyncTriggerEvent.memberLeft({String? groupId})
    : this._(type: SyncTriggerEventType.memberLeft, groupId: groupId);

  const SyncTriggerEvent.groupDissolved({String? groupId})
    : this._(type: SyncTriggerEventType.groupDissolved, groupId: groupId);

  const SyncTriggerEvent.syncAvailable({String? groupId})
    : this._(type: SyncTriggerEventType.syncAvailable, groupId: groupId);

  final SyncTriggerEventType type;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is SyncTriggerEvent &&
        other.type == type &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(type, groupId);
}
