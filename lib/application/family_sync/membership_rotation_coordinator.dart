import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'shadow_book_service.dart';

typedef MembershipRotationRequestIdFactory = String Function();
typedef MembershipEpochCommittedCallback =
    Future<void> Function(String groupId, int keyEpoch);

/// Crash-safe membership key-rotation protocol.
///
/// A generated key is written to SQLCipher together with the exact sealed
/// recipient set before the relay is mutated.  Ambiguous HTTP outcomes are
/// reconciled from that same intent plus the authoritative group snapshot.
class MembershipRotationCoordinator {
  MembershipRotationCoordinator({
    required GroupRepository groupRepository,
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required KeyManager keyManager,
    MembershipRotationIntentStore? intentStore,
    SyncQueueManager? queueManager,
    ShadowBookService? shadowBookService,
    MembershipRotationRequestIdFactory? requestIdFactory,
    MembershipEpochCommittedCallback? onEpochCommitted,
  }) : _groupRepository = groupRepository,
       _apiClient = apiClient,
       _e2eeService = e2eeService,
       _keyManager = keyManager,
       _intentStore =
           intentStore ??
           (groupRepository is MembershipRotationIntentStore
               ? groupRepository as MembershipRotationIntentStore
               : null),
       _queueManager = queueManager,
       _shadowBookService = shadowBookService,
       _requestIdFactory = requestIdFactory ?? const Uuid().v4,
       _onEpochCommitted = onEpochCommitted;

  static const removeOperation = 'remove';
  static const leaveOperation = 'leave';
  static const completeLeaveOperation = 'complete_leave';
  static const removePurpose = 'member_remove';
  static const completeLeavePurpose = 'member_leave_rotation';

  final GroupRepository _groupRepository;
  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final KeyManager _keyManager;
  final MembershipRotationIntentStore? _intentStore;
  final SyncQueueManager? _queueManager;
  final ShadowBookService? _shadowBookService;
  final MembershipRotationRequestIdFactory _requestIdFactory;
  final MembershipEpochCommittedCallback? _onEpochCommitted;

  Future<Map<String, dynamic>> removeMember({
    required String groupId,
    required String targetDeviceId,
  }) async {
    final store = _requiredStore;
    final group = await _groupRepository.getGroupById(groupId);
    if (group == null ||
        group.status != GroupStatus.active ||
        group.role != 'owner') {
      throw StateError('Only an active owner can remove a member');
    }

    var intent = await store.getMembershipRotationIntent(groupId);
    if (intent != null &&
        (intent.operation != removeOperation ||
            intent.targetDeviceId != targetDeviceId)) {
      throw StateError('Another membership rotation is already pending');
    }
    final localMembers = group.members
        .where((member) => member.deviceId != targetDeviceId)
        .toList(growable: false);
    final remainingMembers = localMembers
        .where(
          (member) =>
              member.status == 'active' && member.deviceId != targetDeviceId,
        )
        .toList(growable: false);
    final targetIsActive = group.members.any(
      (member) =>
          member.deviceId == targetDeviceId && member.status == 'active',
    );
    final ownerIncluded = remainingMembers.any(
      (member) => member.role == 'owner' && member.status == 'active',
    );
    if (!targetIsActive || !ownerIncluded || remainingMembers.isEmpty) {
      throw StateError('Invalid active member removal target');
    }

    intent ??= await _prepareIntent(
      groupId: groupId,
      operation: removeOperation,
      targetDeviceId: targetDeviceId,
      expectedEpoch: group.keyEpoch,
      purpose: removePurpose,
      recipients: remainingMembers,
    );
    final response = await _apiClient.removeMemberWithPreparedRotation(
      groupId: groupId,
      deviceId: targetDeviceId,
      requestId: intent.requestId,
      expectedKeyEpoch: intent.expectedKeyEpoch,
      newKeyEpoch: intent.newKeyEpoch,
      envelopes: intent.envelopes,
    );
    _validateCommittedResponse(response, intent);
    await store.completeMembershipRotationLocally(
      intent: intent,
      members: localMembers,
    );
    await _onEpochCommitted?.call(groupId, intent.newKeyEpoch);
    return response;
  }

  /// Writes a stable leave request before the first network boundary.
  Future<MembershipRotationIntent> submitSelfLeave(String groupId) async {
    final store = _requiredStore;
    final group = await _groupRepository.getGroupById(groupId);
    if (group == null || group.status != GroupStatus.active) {
      throw StateError('Active family not found');
    }
    if (group.role == 'owner') {
      throw StateError('Owner must deactivate or transfer ownership');
    }
    var intent = await store.getMembershipRotationIntent(groupId);
    if (intent != null && intent.operation != leaveOperation) {
      throw StateError('Another membership rotation is already pending');
    }
    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId == null ||
        !group.members.any(
          (member) =>
              member.deviceId == localDeviceId && member.status == 'active',
        )) {
      throw StateError('Local family member identity is missing');
    }
    intent ??= MembershipRotationIntent(
      groupId: groupId,
      requestId: _requestIdFactory(),
      operation: leaveOperation,
      targetDeviceId: localDeviceId,
      expectedKeyEpoch: group.keyEpoch,
      newKeyEpoch: group.keyEpoch + 1,
      groupKey: null,
      envelopes: const [],
      createdAt: DateTime.now(),
    );
    await store.saveMembershipRotationIntent(intent);
    final response = await _apiClient.leaveGroupWithRotation(
      groupId,
      requestId: intent.requestId,
      expectedKeyEpoch: intent.expectedKeyEpoch,
    );
    final pendingEpoch = (response['pendingKeyEpoch'] as num?)?.toInt();
    if (response['requestId'] != intent.requestId ||
        response['rotationRequired'] != true ||
        pendingEpoch != intent.newKeyEpoch) {
      throw StateError('Invalid self-leave rotation response');
    }
    return intent;
  }

  Future<void> finalizeSelfLeave(MembershipRotationIntent intent) async {
    await _queueManager?.clearQueue();
    await _shadowBookService?.cleanSyncData(intent.groupId);
    await _groupRepository.deactivateGroup(intent.groupId);
    await _requiredStore.clearMembershipRotationIntent(
      intent.groupId,
      requestId: intent.requestId,
    );
  }

  /// Cold-start repair for an HTTP response lost after the relay committed a
  /// self-leave.  The ledger makes the second submission an exact replay.
  Future<bool> resumeSelfLeaveIfPending() async {
    final group = await _groupRepository.getCurrentGroup();
    if (group == null) return false;
    final intent = await _requiredStore.getMembershipRotationIntent(
      group.groupId,
    );
    if (intent == null || intent.operation != leaveOperation) return false;
    final response = await _apiClient.leaveGroupWithRotation(
      group.groupId,
      requestId: intent.requestId,
      expectedKeyEpoch: intent.expectedKeyEpoch,
    );
    if (response['requestId'] != intent.requestId) {
      throw StateError('Mismatched self-leave replay response');
    }
    await finalizeSelfLeave(intent);
    return true;
  }

  /// Reconciles owner-side intents before a snapshot can clear a retired key.
  /// Returns true when the relay changed and the caller must fetch a fresh
  /// snapshot before applying it.
  Future<bool> recoverFromSnapshot(Map<String, dynamic> snapshot) async {
    final groupId = snapshot['groupId'] as String?;
    if (groupId == null || snapshot['status'] != 'active') return false;
    final store = _requiredStore;
    final members = _parseMembers(snapshot['members']);
    final snapshotEpoch = (snapshot['keyEpoch'] as num?)?.toInt();
    if (snapshotEpoch == null || snapshotEpoch < 1) return false;

    var intent = await store.getMembershipRotationIntent(groupId);
    if (intent?.operation == leaveOperation) return false;
    final targetIsNoLongerActive =
        intent == null ||
        !members.any(
          (member) =>
              member.deviceId == intent!.targetDeviceId &&
              member.status == 'active',
        );
    if (intent != null &&
        snapshotEpoch == intent.newKeyEpoch &&
        targetIsNoLongerActive) {
      await store.completeMembershipRotationLocally(
        intent: intent,
        members: members,
      );
      await _onEpochCommitted?.call(groupId, intent.newKeyEpoch);
      return false;
    }
    if (intent != null && snapshotEpoch >= intent.newKeyEpoch) {
      throw StateError('Membership rotation intent conflicts with snapshot');
    }
    if (intent?.operation == removeOperation) {
      final response = await _apiClient.removeMemberWithPreparedRotation(
        groupId: groupId,
        deviceId: intent!.targetDeviceId,
        requestId: intent.requestId,
        expectedKeyEpoch: intent.expectedKeyEpoch,
        newKeyEpoch: intent.newKeyEpoch,
        envelopes: intent.envelopes,
      );
      _validateCommittedResponse(response, intent);
      final remaining = members
          .where((member) => member.deviceId != intent!.targetDeviceId)
          .toList(growable: false);
      await store.completeMembershipRotationLocally(
        intent: intent,
        members: remaining,
      );
      await _onEpochCommitted?.call(groupId, intent.newKeyEpoch);
      return true;
    }
    if (intent?.operation == completeLeaveOperation) {
      final response = await _apiClient.completeMembershipRotation(
        groupId: groupId,
        requestId: intent!.requestId,
        expectedKeyEpoch: intent.expectedKeyEpoch,
        newKeyEpoch: intent.newKeyEpoch,
        envelopes: intent.envelopes,
      );
      _validateCommittedResponse(response, intent);
      await store.completeMembershipRotationLocally(
        intent: intent,
        members: members,
      );
      await _onEpochCommitted?.call(groupId, intent.newKeyEpoch);
      return true;
    }

    final rotationRequired = snapshot['rotationRequired'] == true;
    if (!rotationRequired) return false;
    final localOwner = members.where(
      (member) => member.role == 'owner' && member.status == 'active',
    );
    if (localOwner.isEmpty) return false;
    final requestId = snapshot['rotationRequestId'] as String?;
    final pendingEpoch = (snapshot['pendingKeyEpoch'] as num?)?.toInt();
    final removedDeviceId = snapshot['rotationRemovedDeviceId'] as String?;
    if (requestId == null ||
        pendingEpoch != snapshotEpoch + 1 ||
        removedDeviceId == null) {
      throw StateError('Invalid pending membership rotation snapshot');
    }
    final recipients = members
        .where((member) => member.status == 'active')
        .toList(growable: false);
    intent = await _prepareIntent(
      groupId: groupId,
      operation: completeLeaveOperation,
      targetDeviceId: removedDeviceId,
      expectedEpoch: snapshotEpoch,
      purpose: completeLeavePurpose,
      recipients: recipients,
      requestId: requestId,
    );
    final response = await _apiClient.completeMembershipRotation(
      groupId: groupId,
      requestId: intent.requestId,
      expectedKeyEpoch: intent.expectedKeyEpoch,
      newKeyEpoch: intent.newKeyEpoch,
      envelopes: intent.envelopes,
    );
    _validateCommittedResponse(response, intent);
    await store.completeMembershipRotationLocally(
      intent: intent,
      members: members,
    );
    await _onEpochCommitted?.call(groupId, intent.newKeyEpoch);
    return true;
  }

  MembershipRotationIntentStore get _requiredStore =>
      _intentStore ??
      (throw StateError('Durable membership rotation storage unavailable'));

  Future<MembershipRotationIntent> _prepareIntent({
    required String groupId,
    required String operation,
    required String targetDeviceId,
    required int expectedEpoch,
    required String purpose,
    required List<GroupMember> recipients,
    String? requestId,
  }) async {
    final nextKey = _e2eeService.generateGroupKey();
    final stableRequestId = requestId ?? _requestIdFactory();
    final sortedRecipients = [...recipients]
      ..sort((left, right) => left.deviceId.compareTo(right.deviceId));
    final envelopes = <Map<String, dynamic>>[];
    for (final member in sortedRecipients) {
      final payload = await _e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: nextKey,
        memberDeviceId: member.deviceId,
        memberPublicKey: member.publicKey,
        keyEpoch: expectedEpoch + 1,
        requestId: stableRequestId,
        purpose: purpose,
      );
      envelopes.add({
        'deviceId': member.deviceId,
        'payload': payload,
        'payloadHash': sha256.convert(utf8.encode(payload)).toString(),
      });
    }
    final intent = MembershipRotationIntent(
      groupId: groupId,
      requestId: stableRequestId,
      operation: operation,
      targetDeviceId: targetDeviceId,
      expectedKeyEpoch: expectedEpoch,
      newKeyEpoch: expectedEpoch + 1,
      groupKey: nextKey,
      envelopes: List.unmodifiable(envelopes),
      createdAt: DateTime.now(),
    );
    await _requiredStore.saveMembershipRotationIntent(intent);
    return intent;
  }

  void _validateCommittedResponse(
    Map<String, dynamic> response,
    MembershipRotationIntent intent,
  ) {
    if (response['requestId'] != intent.requestId ||
        (response['keyEpoch'] as num?)?.toInt() != intent.newKeyEpoch) {
      throw StateError('Invalid committed membership rotation response');
    }
  }

  List<GroupMember> _parseMembers(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map(
          (member) => GroupMember.fromJson(
            member.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList(growable: false);
  }
}
