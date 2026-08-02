import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

typedef KeyRotatedCallback =
    Future<void> Function(String groupId, int keyEpoch);

/// Applies the server-authoritative key generation after an active member
/// leaves. The relay knows only the epoch; the owner generates the actual key
/// and seals it independently to every remaining active member.
class RotateGroupKeyUseCase {
  RotateGroupKeyUseCase({
    required GroupRepository groupRepository,
    required SyncQueueManager queueManager,
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    KeyRotatedCallback? onKeyRotated,
  }) : _groupRepository = groupRepository,
       _queueManager = queueManager,
       _apiClient = apiClient,
       _e2eeService = e2eeService,
       _onKeyRotated = onKeyRotated;

  final GroupRepository _groupRepository;
  final SyncQueueManager _queueManager;
  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final KeyRotatedCallback? _onKeyRotated;
  final Map<String, Future<void>> _inFlightRotations = {};

  static const _uuid = Uuid();

  Future<void> execute({
    required String groupId,
    required int authoritativeEpoch,
    required String removedDeviceId,
  }) {
    final rotationId = '$groupId:$authoritativeEpoch';
    final existing = _inFlightRotations[rotationId];
    if (existing != null) return existing;

    final rotation = _rotate(
      groupId: groupId,
      authoritativeEpoch: authoritativeEpoch,
      removedDeviceId: removedDeviceId,
    );
    _inFlightRotations[rotationId] = rotation;
    return rotation.whenComplete(() {
      if (identical(_inFlightRotations[rotationId], rotation)) {
        _inFlightRotations.remove(rotationId);
      }
    });
  }

  Future<void> _rotate({
    required String groupId,
    required int authoritativeEpoch,
    required String removedDeviceId,
  }) async {
    final group = await _groupRepository.getGroupById(groupId);
    if (group == null ||
        group.status != GroupStatus.active ||
        authoritativeEpoch <= group.keyEpoch) {
      return;
    }

    // Every older data payload was encrypted with a retired key. Current-epoch
    // key envelopes remain queued, and semantic mutations remain in outbox.
    await _queueManager.discardRetiredEpochCiphertext(
      groupId: groupId,
      currentKeyEpoch: authoritativeEpoch,
    );

    if (group.role != 'owner') {
      // Remaining members must not create data with the retired key while
      // waiting for the owner's sealed v2_key envelope.
      await _groupRepository.clearGroupKeyForEpoch(
        groupId,
        keyEpoch: authoritativeEpoch,
      );
      return;
    }

    final nextKey = _e2eeService.generateGroupKey();
    await _groupRepository.storeGroupKeyForEpoch(
      groupId,
      groupKeyBase64: nextKey,
      keyEpoch: authoritativeEpoch,
    );

    for (final member in group.members) {
      if (member.status != 'active' ||
          member.role == 'owner' ||
          member.deviceId == removedDeviceId) {
        continue;
      }

      final sealedKey = await _e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: nextKey,
        memberDeviceId: member.deviceId,
        memberPublicKey: member.publicKey,
        keyEpoch: authoritativeEpoch,
      );
      final syncId = _uuid.v4();
      try {
        await _apiClient.pushSync(
          groupId: groupId,
          syncId: syncId,
          payload: sealedKey,
          vectorClock: const {},
          operationCount: 0,
          keyEpoch: authoritativeEpoch,
        );
      } catch (_) {
        // Key envelopes are already sealed to a single recipient and can use
        // the durable relay queue. They are enqueued before the post-rotation
        // full sync, preserving key-before-data order when connectivity returns.
        await _queueManager.enqueue(
          id: syncId,
          groupId: groupId,
          encryptedPayload: sealedKey,
          vectorClock: const {},
          operationCount: 0,
          keyEpoch: authoritativeEpoch,
        );
      }
    }

    await _onKeyRotated?.call(groupId, authoritativeEpoch);
  }
}
