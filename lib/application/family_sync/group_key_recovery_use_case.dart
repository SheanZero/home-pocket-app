import 'dart:async';

import 'package:uuid/uuid.dart';

import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';

enum GroupKeyRecoveryPhase {
  idle,
  requesting,
  waitingForPeer,
  responding,
  recovered,
  rateLimited,
  unrecoverable,
  error,
}

class GroupKeyRecoveryStatus {
  const GroupKeyRecoveryStatus({
    this.phase = GroupKeyRecoveryPhase.idle,
    this.groupId,
    this.requestId,
    this.keyEpoch,
    this.expiresAt,
    this.nextAutomaticAttemptAt,
    this.message,
  });

  final GroupKeyRecoveryPhase phase;
  final String? groupId;
  final String? requestId;
  final int? keyEpoch;
  final DateTime? expiresAt;
  final DateTime? nextAutomaticAttemptAt;
  final String? message;
}

typedef GroupKeyRecoveryClock = DateTime Function();

/// Coordinates zero-knowledge recovery of a missing group key.
///
/// The relay stores request metadata and an already-sealed response only. It
/// never receives the group key. Every responder re-fetches the authoritative
/// membership snapshot before sealing so notification data is never trusted as
/// authority.
class GroupKeyRecoveryCoordinator {
  GroupKeyRecoveryCoordinator({
    required this._apiClient,
    required this._groupRepository,
    required this._keyManager,
    required this._e2eeService,
    GroupKeyRecoveryClock? clock,
  }) : _clock = clock ?? DateTime.now;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final KeyManager _keyManager;
  final E2EEService _e2eeService;
  final GroupKeyRecoveryClock _clock;

  static const _uuid = Uuid();
  static const _automaticBackoff = <Duration>[
    Duration(seconds: 5),
    Duration(seconds: 15),
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 2),
  ];

  final _controller = StreamController<GroupKeyRecoveryStatus>.broadcast();
  final _automaticAttempts = <String, int>{};
  final _inFlightRequests = <String, Future<GroupKeyRecoveryStatus>>{};
  final _inFlightResponders = <String, Future<int>>{};
  GroupKeyRecoveryStatus _status = const GroupKeyRecoveryStatus();

  GroupKeyRecoveryStatus get currentStatus => _status;
  Stream<GroupKeyRecoveryStatus> get statusStream => _controller.stream;

  Future<GroupKeyRecoveryStatus> requestKey({
    required String groupId,
    bool manual = false,
  }) {
    final existing = _inFlightRequests[groupId];
    if (existing != null) return existing;
    late final Future<GroupKeyRecoveryStatus> future;
    future = _requestKey(groupId: groupId, manual: manual).whenComplete(() {
      if (identical(_inFlightRequests[groupId], future)) {
        _inFlightRequests.remove(groupId);
      }
    });
    _inFlightRequests[groupId] = future;
    return future;
  }

  Future<GroupKeyRecoveryStatus> _requestKey({
    required String groupId,
    required bool manual,
  }) async {
    final now = _clock().toUtc();
    if (!manual && _status.groupId == groupId) {
      final expiresAt = _status.expiresAt;
      if (expiresAt != null && !expiresAt.isAfter(now)) {
        return _emit(
          GroupKeyRecoveryStatus(
            phase: GroupKeyRecoveryPhase.unrecoverable,
            groupId: groupId,
            requestId: _status.requestId,
            keyEpoch: _status.keyEpoch,
            expiresAt: expiresAt,
            message: 'No active peer supplied the current group key',
          ),
        );
      }
      final nextAttempt = _status.nextAutomaticAttemptAt;
      if (nextAttempt != null && nextAttempt.isAfter(now)) {
        return _status;
      }
    }

    final group = await _groupRepository.getGroupById(groupId);
    if (group == null) {
      return _emit(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.error,
          groupId: groupId,
          message: 'Local group snapshot is unavailable',
        ),
      );
    }
    if (group.groupKey?.isNotEmpty == true) {
      _automaticAttempts.remove(groupId);
      return _emit(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.recovered,
          groupId: groupId,
          keyEpoch: group.keyEpoch,
        ),
      );
    }

    final deviceId = await _keyManager.getDeviceId();
    final localMember = _member(group.members, deviceId);
    if (deviceId == null || localMember?.status != 'active') {
      return _emit(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.error,
          groupId: groupId,
          keyEpoch: group.keyEpoch,
          message: 'Only an active member may request a group key',
        ),
      );
    }

    _emit(
      GroupKeyRecoveryStatus(
        phase: GroupKeyRecoveryPhase.requesting,
        groupId: groupId,
        keyEpoch: group.keyEpoch,
      ),
    );
    try {
      final response = await _apiClient.requestGroupKey(
        groupId: groupId,
        // A restored device cannot trust the epoch stored beside a missing
        // key. Epoch 0 asks the relay to return the authoritative epoch.
        keyEpoch: 0,
        forceNotify: manual,
      );
      final requestId = _requiredString(response['requestId']);
      final responseEpoch = _positiveInt(response['keyEpoch']);
      final expiresAt = DateTime.tryParse(
        _requiredString(response['expiresAt']),
      )?.toUtc();
      if (responseEpoch == null || expiresAt == null) {
        throw const FormatException('Invalid group key request response');
      }
      if (responseEpoch != group.keyEpoch) {
        await _groupRepository.clearGroupKeyForEpoch(
          groupId,
          keyEpoch: responseEpoch,
        );
      }
      final attempt = (_automaticAttempts[groupId] ?? 0) + 1;
      _automaticAttempts[groupId] = attempt;
      final delay =
          _automaticBackoff[(attempt - 1).clamp(
            0,
            _automaticBackoff.length - 1,
          )];
      return _emit(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.waitingForPeer,
          groupId: groupId,
          requestId: requestId,
          keyEpoch: responseEpoch,
          expiresAt: expiresAt,
          nextAutomaticAttemptAt: now.add(delay),
        ),
      );
    } on RelayApiException catch (error) {
      return _emit(
        GroupKeyRecoveryStatus(
          phase: error.statusCode == 429
              ? GroupKeyRecoveryPhase.rateLimited
              : GroupKeyRecoveryPhase.error,
          groupId: groupId,
          keyEpoch: group.keyEpoch,
          nextAutomaticAttemptAt: error.statusCode == 429
              ? now.add(const Duration(seconds: 30))
              : null,
          message: error.message,
        ),
      );
    } catch (_) {
      return _emit(
        GroupKeyRecoveryStatus(
          phase: GroupKeyRecoveryPhase.error,
          groupId: groupId,
          keyEpoch: group.keyEpoch,
          message: 'Unable to request the group key',
        ),
      );
    }
  }

  Future<int> respondToPending({required String groupId}) {
    final existing = _inFlightResponders[groupId];
    if (existing != null) return existing;
    late final Future<int> future;
    future = _respondToPending(groupId).whenComplete(() {
      if (identical(_inFlightResponders[groupId], future)) {
        _inFlightResponders.remove(groupId);
      }
    });
    _inFlightResponders[groupId] = future;
    return future;
  }

  Future<int> respondForCurrentGroup() async {
    final group = await _groupRepository.getActiveGroup();
    if (group == null) return 0;
    return respondToPending(groupId: group.groupId);
  }

  Future<int> _respondToPending(String groupId) async {
    final group = await _groupRepository.getGroupById(groupId);
    final groupKey = group?.groupKey;
    if (group == null ||
        group.status != GroupStatus.active ||
        groupKey == null ||
        groupKey.isEmpty) {
      return 0;
    }

    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId == null) return 0;
    final snapshot = await _apiClient.getGroupStatus(groupId);
    if (snapshot['groupId'] != groupId || snapshot['status'] != 'active') {
      return 0;
    }
    final epoch = _positiveInt(snapshot['keyEpoch']) ?? group.keyEpoch;
    if (epoch != group.keyEpoch) return 0;
    final members = _members(snapshot['members']);
    if (_member(members, localDeviceId)?.status != 'active') return 0;

    final response = await _apiClient.getPendingGroupKeyRequests(groupId);
    final rawRequests = response['requests'];
    if (rawRequests is! List) {
      throw const FormatException('Invalid pending key request response');
    }

    var stored = 0;
    _emit(
      GroupKeyRecoveryStatus(
        phase: GroupKeyRecoveryPhase.responding,
        groupId: groupId,
        keyEpoch: epoch,
      ),
    );
    for (final raw in rawRequests.whereType<Map>()) {
      final request = raw.map((key, value) => MapEntry(key.toString(), value));
      final requestId = _nullableString(request['requestId']);
      final requesterId = _nullableString(request['requesterDeviceId']);
      final requesterPublicKey = _nullableString(request['requesterPublicKey']);
      final requestEpoch = _positiveInt(request['keyEpoch']);
      final expiresAt = DateTime.tryParse(
        _nullableString(request['expiresAt']) ?? '',
      )?.toUtc();
      final requester = _member(members, requesterId);
      if (requestId == null ||
          requesterId == null ||
          requesterId == localDeviceId ||
          requesterPublicKey == null ||
          requestEpoch != epoch ||
          expiresAt == null ||
          !expiresAt.isAfter(_clock().toUtc()) ||
          requester?.status != 'active' ||
          requester!.publicKey != requesterPublicKey) {
        continue;
      }

      final sealed = await _e2eeService.encryptGroupKeyForMember(
        groupKeyBase64: groupKey,
        memberDeviceId: requesterId,
        memberPublicKey: requesterPublicKey,
        keyEpoch: epoch,
        requestId: requestId,
      );
      final pushResult = await _apiClient.pushGroupKeyResponse(
        groupId: groupId,
        requestId: requestId,
        targetDeviceId: requesterId,
        payload: sealed,
        keyEpoch: epoch,
        syncId: _uuid.v4(),
      );
      if (_positiveInt(pushResult['recipientCount']) == 1) stored++;
    }
    _emit(const GroupKeyRecoveryStatus());
    return stored;
  }

  GroupKeyRecoveryStatus _emit(GroupKeyRecoveryStatus status) {
    _status = status;
    if (!_controller.isClosed) _controller.add(status);
    return status;
  }

  GroupMember? _member(List<GroupMember> members, String? deviceId) {
    if (deviceId == null) return null;
    for (final member in members) {
      if (member.deviceId == deviceId) return member;
    }
    return null;
  }

  List<GroupMember> _members(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((raw) {
      return GroupMember.fromJson(
        raw.map((key, value) => MapEntry(key.toString(), value)),
      );
    }).toList();
  }

  String _requiredString(Object? value) {
    final parsed = _nullableString(value);
    if (parsed == null) throw const FormatException('Expected string');
    return parsed;
  }

  String? _nullableString(Object? value) =>
      value is String && value.isNotEmpty ? value : null;

  int? _positiveInt(Object? value) {
    final parsed = switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
    return parsed != null && parsed > 0 ? parsed : null;
  }

  Future<void> dispose() => _controller.close();
}
