import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'refresh_group_snapshot_use_case.dart';

sealed class OwnerTransferResult {
  const OwnerTransferResult();
}

class OwnerTransferSuccess extends OwnerTransferResult {
  const OwnerTransferSuccess({
    required this.newOwnerDeviceId,
    required this.keyEpoch,
    required this.requestId,
  });

  final String newOwnerDeviceId;
  final int keyEpoch;
  final String requestId;
}

class OwnerTransferForbidden extends OwnerTransferResult {
  const OwnerTransferForbidden();
}

class OwnerTransferInvalidTarget extends OwnerTransferResult {
  const OwnerTransferInvalidTarget();
}

class OwnerTransferError extends OwnerTransferResult {
  const OwnerTransferError(this.message);

  final String message;
}

typedef OwnerTransferRequestIdFactory = String Function();
typedef OwnerTransferEpochCommittedCallback =
    Future<void> Function(String groupId, int keyEpoch);

/// Prepares a new key once, then submits the exact same signed request on a
/// timeout retry. The relay atomically persists all targeted envelopes before
/// changing roles, so a successful response can never expose a keyless epoch.
class OwnerTransferUseCase {
  OwnerTransferUseCase({
    required GroupRepository groupRepository,
    required RelayApiClient apiClient,
    required E2EEService e2eeService,
    required RefreshGroupSnapshotUseCase refreshGroupSnapshot,
    OwnerTransferRequestIdFactory? requestIdFactory,
    OwnerTransferEpochCommittedCallback? onEpochCommitted,
  }) : _groupRepository = groupRepository,
       _apiClient = apiClient,
       _e2eeService = e2eeService,
       _refreshGroupSnapshot = refreshGroupSnapshot,
       _requestIdFactory = requestIdFactory ?? const Uuid().v4,
       _onEpochCommitted = onEpochCommitted;

  static const envelopePurpose = 'owner_transfer';

  final GroupRepository _groupRepository;
  final RelayApiClient _apiClient;
  final E2EEService _e2eeService;
  final RefreshGroupSnapshotUseCase _refreshGroupSnapshot;
  final OwnerTransferRequestIdFactory _requestIdFactory;
  final OwnerTransferEpochCommittedCallback? _onEpochCommitted;

  Future<OwnerTransferResult> execute({
    required String groupId,
    required String targetDeviceId,
  }) async {
    final group = await _groupRepository.getGroupById(groupId);
    if (group == null ||
        group.status != GroupStatus.active ||
        group.role != 'owner' ||
        group.groupKey == null ||
        group.groupKey!.isEmpty) {
      return const OwnerTransferForbidden();
    }

    final target = _activeMember(group.members, targetDeviceId);
    final owner = group.members
        .where((member) => member.role == 'owner' && member.status == 'active')
        .firstOrNull;
    if (target == null ||
        target.role != 'member' ||
        owner == null ||
        owner.deviceId == targetDeviceId) {
      return const OwnerTransferInvalidTarget();
    }

    final activeMembers =
        group.members.where((member) => member.status == 'active').toList()
          ..sort((left, right) => left.deviceId.compareTo(right.deviceId));
    if (activeMembers.length < 2) {
      return const OwnerTransferInvalidTarget();
    }

    final requestId = _requestIdFactory();
    final newEpoch = group.keyEpoch + 1;
    final newKey = _e2eeService.generateGroupKey();
    final envelopes = <Map<String, dynamic>>[];
    for (final member in activeMembers) {
      final payload = await _e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: newKey,
        memberDeviceId: member.deviceId,
        memberPublicKey: member.publicKey,
        keyEpoch: newEpoch,
        requestId: requestId,
        purpose: envelopePurpose,
      );
      envelopes.add({
        'deviceId': member.deviceId,
        'payload': payload,
        'payloadHash': sha256.convert(utf8.encode(payload)).toString(),
      });
    }

    try {
      final response = await _submitWithOneTimeoutRetry(
        groupId: groupId,
        requestId: requestId,
        targetDeviceId: targetDeviceId,
        expectedKeyEpoch: group.keyEpoch,
        newKeyEpoch: newEpoch,
        envelopes: envelopes,
      );
      final responseEpoch = (response['keyEpoch'] as num?)?.toInt();
      final responseOwner = response['newOwnerDeviceId'] as String?;
      if (responseEpoch != newEpoch || responseOwner != targetDeviceId) {
        return const OwnerTransferError('Invalid owner transfer response');
      }

      // Install our already-generated key before applying the role snapshot.
      // Snapshot reconciliation preserves a key whose epoch already matches.
      await _groupRepository.storeGroupKeyForEpoch(
        groupId,
        groupKeyBase64: newKey,
        keyEpoch: newEpoch,
      );
      final refreshed = await _refreshGroupSnapshot.execute(groupId: groupId);
      if (refreshed is RefreshGroupSnapshotFailed) {
        return OwnerTransferError(refreshed.message);
      }
      await _onEpochCommitted?.call(groupId, newEpoch);
      return OwnerTransferSuccess(
        newOwnerDeviceId: targetDeviceId,
        keyEpoch: newEpoch,
        requestId: requestId,
      );
    } on RelayApiException catch (error) {
      if (error.isForbidden) return const OwnerTransferForbidden();
      if (error.statusCode == 400) return const OwnerTransferInvalidTarget();
      return OwnerTransferError(error.message);
    } catch (error) {
      return OwnerTransferError(error.toString());
    }
  }

  Future<Map<String, dynamic>> _submitWithOneTimeoutRetry({
    required String groupId,
    required String requestId,
    required String targetDeviceId,
    required int expectedKeyEpoch,
    required int newKeyEpoch,
    required List<Map<String, dynamic>> envelopes,
  }) async {
    try {
      return await _apiClient.transferOwner(
        groupId: groupId,
        requestId: requestId,
        targetDeviceId: targetDeviceId,
        expectedKeyEpoch: expectedKeyEpoch,
        newKeyEpoch: newKeyEpoch,
        envelopes: envelopes,
      );
    } on TimeoutException {
      return _apiClient.transferOwner(
        groupId: groupId,
        requestId: requestId,
        targetDeviceId: targetDeviceId,
        expectedKeyEpoch: expectedKeyEpoch,
        newKeyEpoch: newKeyEpoch,
        envelopes: envelopes,
      );
    }
  }

  GroupMember? _activeMember(List<GroupMember> members, String deviceId) {
    for (final member in members) {
      if (member.deviceId == deviceId && member.status == 'active') {
        return member;
      }
    }
    return null;
  }
}
