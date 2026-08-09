import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'rotate_group_key_use_case.dart';
import 'shadow_book_service.dart';

/// Handles member_left push notification.
///
/// If this device was removed: cleanup + deactivate group.
/// If another member left: update local member list.
class HandleMemberLeftUseCase {
  HandleMemberLeftUseCase({
    required this._groupRepo,
    required this._queueManager,
    required this._shadowBookService,
    required this._keyManager,
    required RotateGroupKeyUseCase rotateGroupKey,
  });

  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final ShadowBookService _shadowBookService;
  final KeyManager _keyManager;

  Future<void> execute({
    required String groupId,
    required String deviceId,
    String? reason,
    int? keyEpoch,
  }) async {
    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId != null &&
        deviceId == localDeviceId &&
        reason == 'removed') {
      await _queueManager.clearQueue();
      await _shadowBookService.cleanSyncData(groupId);
      await _groupRepo.deactivateGroup(groupId);
      return;
    }

    final group = await _groupRepo.getGroupById(groupId);
    if (group == null) return;

    final updatedMembers = group.members
        .where((m) => m.deviceId != deviceId)
        .toList();
    await _groupRepo.updateMembers(groupId, updatedMembers);

    // The relay now commits a server-backed, per-device rotation envelope in
    // the same transaction as removal.  Generating another local key here can
    // diverge from that durable epoch. SyncEngine refreshes the authoritative
    // snapshot and pulls the targeted envelope instead.
  }
}
