import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/family_sync/domain/models/sync_status_model.dart';
import 'check_group_use_case.dart';
import 'pull_sync_use_case.dart';
import 'sync_orchestrator.dart';
import 'group_key_recovery_use_case.dart';

sealed class MemberActivationResult {
  const MemberActivationResult();
}

class MemberActivationReady extends MemberActivationResult {
  const MemberActivationReady({required this.groupId});

  final String groupId;
}

class MemberActivationPendingApproval extends MemberActivationResult {
  const MemberActivationPendingApproval({required this.groupId});

  final String groupId;
}

class MemberActivationAwaitingKey extends MemberActivationResult {
  const MemberActivationAwaitingKey({required this.groupId, this.message});

  final String groupId;
  final String? message;
}

class MemberActivationNotInGroup extends MemberActivationResult {
  const MemberActivationNotInGroup();
}

class MemberActivationError extends MemberActivationResult {
  const MemberActivationError(this.message);

  final String message;
}

/// Completes the joiner's confirmation handshake without relying on a pending
/// WebSocket connection.
///
/// A member is ready only after the server snapshot says the local device is
/// active, the targeted owner envelope has installed the current group key,
/// the local group has been activated, and both initial reconciliation and an
/// incremental pull have succeeded.
class CompleteMemberActivationUseCase {
  CompleteMemberActivationUseCase({
    required CheckGroupUseCase checkGroup,
    required PullSyncUseCase pullSync,
    required GroupRepository groupRepository,
    required SyncOrchestrator orchestrator,
    GroupKeyRecoveryCoordinator? keyRecovery,
  }) : _checkGroup = checkGroup,
       _pullSync = pullSync,
       _groupRepository = groupRepository,
       _orchestrator = orchestrator,
       _keyRecovery = keyRecovery;

  final CheckGroupUseCase _checkGroup;
  final PullSyncUseCase _pullSync;
  final GroupRepository _groupRepository;
  final SyncOrchestrator _orchestrator;
  final GroupKeyRecoveryCoordinator? _keyRecovery;

  final _readyGroupIds = <String>{};
  final _inFlight = <String, Future<MemberActivationResult>>{};

  Future<MemberActivationResult> execute({String? expectedGroupId}) {
    final flightKey = expectedGroupId ?? '_authoritative_group';
    final existing = _inFlight[flightKey];
    if (existing != null) return existing;

    late final Future<MemberActivationResult> future;
    future = _execute(expectedGroupId: expectedGroupId).whenComplete(() {
      if (identical(_inFlight[flightKey], future)) {
        _inFlight.remove(flightKey);
      }
    });
    _inFlight[flightKey] = future;
    return future;
  }

  Future<MemberActivationResult> _execute({String? expectedGroupId}) async {
    if (expectedGroupId != null && _readyGroupIds.contains(expectedGroupId)) {
      final activeGroup = await _groupRepository.getActiveGroup();
      if (activeGroup?.groupId == expectedGroupId &&
          activeGroup?.groupKey?.isNotEmpty == true) {
        return MemberActivationReady(groupId: expectedGroupId);
      }
      _readyGroupIds.remove(expectedGroupId);
    }

    final initialCheck = await _checkGroup.execute();
    switch (initialCheck) {
      case CheckGroupNotInGroup():
        return const MemberActivationNotInGroup();
      case CheckGroupPendingApproval(:final groupId):
        return _matchesExpected(groupId, expectedGroupId)
            ? MemberActivationPendingApproval(groupId: groupId)
            : _unexpectedGroup(groupId, expectedGroupId);
      case CheckGroupAwaitingKey(:final groupId):
        if (!_matchesExpected(groupId, expectedGroupId)) {
          return _unexpectedGroup(groupId, expectedGroupId);
        }
        return _bootstrapKeyAndActivate(groupId);
      case CheckGroupInGroup(:final groupId):
        if (!_matchesExpected(groupId, expectedGroupId)) {
          return _unexpectedGroup(groupId, expectedGroupId);
        }
        return _reconcileAndMarkReady(groupId);
      case CheckGroupError(:final message):
        return MemberActivationError(message);
    }
  }

  Future<MemberActivationResult> _bootstrapKeyAndActivate(
    String groupId,
  ) async {
    final pullResult = await _pullSync.execute();
    if (pullResult case PullSyncError(:final message)) {
      return MemberActivationAwaitingKey(groupId: groupId, message: message);
    }
    if (pullResult is PullSyncNoPair) {
      return MemberActivationAwaitingKey(groupId: groupId);
    }

    final group = await _groupRepository.getGroupById(groupId);
    if (group?.groupKey?.isNotEmpty != true) {
      final recovery = await _keyRecovery?.requestKey(groupId: groupId);
      return MemberActivationAwaitingKey(
        groupId: groupId,
        message: recovery?.message,
      );
    }

    // Pulling a key is not authority to activate. Fetch the server snapshot a
    // second time so confirmLocalGroup is reached only for this active device.
    final authoritativeCheck = await _checkGroup.execute();
    switch (authoritativeCheck) {
      case CheckGroupInGroup(groupId: final authoritativeGroupId):
        if (authoritativeGroupId != groupId) {
          return _unexpectedGroup(authoritativeGroupId, groupId);
        }
        return _reconcileAndMarkReady(authoritativeGroupId);
      case CheckGroupAwaitingKey(groupId: final authoritativeGroupId):
        return authoritativeGroupId == groupId
            ? MemberActivationAwaitingKey(groupId: authoritativeGroupId)
            : _unexpectedGroup(authoritativeGroupId, groupId);
      case CheckGroupPendingApproval(groupId: final authoritativeGroupId):
        return authoritativeGroupId == groupId
            ? MemberActivationPendingApproval(groupId: authoritativeGroupId)
            : _unexpectedGroup(authoritativeGroupId, groupId);
      case CheckGroupNotInGroup():
        return const MemberActivationNotInGroup();
      case CheckGroupError(:final message):
        return MemberActivationError(message);
    }
  }

  Future<MemberActivationResult> _reconcileAndMarkReady(String groupId) async {
    final initial = await _orchestrator.execute(SyncMode.initialSync);
    final initialError = _syncFailure(initial, 'Initial reconciliation');
    if (initialError != null) return initialError;

    // Drain anything that arrived while the initial full snapshot was being
    // pushed. Readiness is intentionally gated on this second pull.
    final incremental = await _orchestrator.execute(SyncMode.incrementalPull);
    final incrementalError = _syncFailure(incremental, 'Incremental pull');
    if (incrementalError != null) return incrementalError;

    _readyGroupIds.add(groupId);
    return MemberActivationReady(groupId: groupId);
  }

  MemberActivationError? _syncFailure(
    SyncOrchestratorResult result,
    String operation,
  ) {
    return switch (result) {
      SyncOrchestratorSuccess() => null,
      SyncOrchestratorNoGroup() => MemberActivationError(
        '$operation could not find the activated group',
      ),
      SyncOrchestratorError(:final message) => MemberActivationError(message),
    };
  }

  bool _matchesExpected(String actual, String? expected) {
    return expected == null || actual == expected;
  }

  MemberActivationError _unexpectedGroup(String actual, String? expected) {
    return MemberActivationError(
      'Confirmation group mismatch: expected $expected, received $actual',
    );
  }
}
