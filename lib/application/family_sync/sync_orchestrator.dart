import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'check_group_validity_use_case.dart';
import 'full_sync_use_case.dart';
import 'pull_sync_use_case.dart';
import 'push_sync_use_case.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';
import 'transaction_change_tracker.dart';

/// Result of an orchestrated sync operation.
sealed class SyncOrchestratorResult {
  const SyncOrchestratorResult();
}

class SyncOrchestratorSuccess extends SyncOrchestratorResult {
  const SyncOrchestratorSuccess({this.appliedCount = 0, this.pushedCount = 0});
  final int appliedCount;
  final int pushedCount;
}

class SyncOrchestratorNoGroup extends SyncOrchestratorResult {
  const SyncOrchestratorNoGroup();
}

class SyncOrchestratorError extends SyncOrchestratorResult {
  const SyncOrchestratorError(this.message);
  final String message;
}

/// Orchestration layer: sequences Use Cases into sync modes.
///
/// No timers or scheduling — pure business logic coordination.
class SyncOrchestrator {
  SyncOrchestrator({
    required PullSyncUseCase pullSync,
    required PushSyncUseCase pushSync,
    required FullSyncUseCase fullSync,
    required SyncAvatarUseCase avatarSync,
    required CheckGroupValidityUseCase checkValidity,
    ShadowBookService? shadowBookService,
    required GroupRepository groupRepo,
    required UserProfileRepository profileRepo,
    required SyncQueueManager queueManager,
    required KeyManager keyManager,
    required TransactionChangeTracker changeTracker,
  }) : _pullSync = pullSync,
       _pushSync = pushSync,
       _fullSync = fullSync,
       _avatarSync = avatarSync,
       _checkValidity = checkValidity,
       _groupRepo = groupRepo,
       _profileRepo = profileRepo,
       _queueManager = queueManager,
       _keyManager = keyManager,
       _changeTracker = changeTracker;

  final PullSyncUseCase _pullSync;
  final PushSyncUseCase _pushSync;
  final FullSyncUseCase _fullSync;
  final SyncAvatarUseCase _avatarSync;
  final CheckGroupValidityUseCase _checkValidity;
  final GroupRepository _groupRepo;
  final UserProfileRepository _profileRepo;
  final SyncQueueManager _queueManager;
  final KeyManager _keyManager;
  final TransactionChangeTracker _changeTracker;

  /// Tracks last pushed profile hash to avoid redundant profile operations.
  String? _lastPushedProfileHash;

  /// Execute a sync mode. Returns the result.
  Future<SyncOrchestratorResult> execute(SyncMode mode) async {
    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] Executing $mode...');
    }
    try {
      return switch (mode) {
        SyncMode.initialSync => await _executeInitialSync(),
        SyncMode.incrementalPush => await _executeIncrementalPush(),
        SyncMode.incrementalPull => await _executeIncrementalPull(),
        SyncMode.profileSync => await _executeProfileSync(),
        SyncMode.fullPull => await _executeFullPull(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncOrchestrator: $mode failed: $e');
      }
      return SyncOrchestratorError(e.toString());
    }
  }

  /// Check 24h threshold for full pull.
  Future<bool> needsFullPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return false;
    final lastSync = group.lastSyncAt;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > const Duration(hours: 24);
  }

  /// Get pending queue count for SyncStatus.
  Future<int> getPendingQueueCount() => _queueManager.getPendingCount();

  // --- Private orchestration flows ---

  Future<SyncOrchestratorResult> _executeInitialSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] initialSync started');
    }

    // Always: push all → push avatar → pull
    final pushed = await _fullSync.execute();
    await _avatarSync.pushAvatarToMembers(groupId: group.groupId);
    final pullResult = await _pullSync.execute();
    final applied = pullResult is PullSyncSuccess ? pullResult.appliedCount : 0;

    if (kDebugMode) {
      debugPrint(
        '[SyncOrchestrator] initialSync complete: pushed=$pushed, applied=$applied',
      );
    }

    return SyncOrchestratorSuccess(pushedCount: pushed, appliedCount: applied);
  }

  Future<SyncOrchestratorResult> _executeIncrementalPush() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    // Check group validity (5-min cache)
    final validity = await _checkValidity.execute();
    if (validity is GroupInvalid) {
      return SyncOrchestratorError('Group invalid: ${validity.reason}');
    }
    if (validity is GroupNoGroup) {
      return const SyncOrchestratorNoGroup();
    }

    // Flush pending transaction changes
    final txnOps = _changeTracker.flush();
    if (txnOps.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[SyncOrchestrator] incrementalPush: pushing ${txnOps.length} transaction ops',
        );
      }
      await _pushSync.execute(operations: txnOps, vectorClock: const {});
    }

    // Build profile operation if changed
    final profileOps = await _buildProfileOperationsIfChanged();

    if (profileOps.isNotEmpty) {
      await _pushSync.execute(operations: profileOps, vectorClock: const {});
    }

    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] incrementalPush: draining offline queue');
    }

    // Drain offline queue
    await _queueManager.drainQueue();

    return SyncOrchestratorSuccess(pushedCount: txnOps.length);
  }

  Future<SyncOrchestratorResult> _executeIncrementalPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final pullResult = await _pullSync.execute();
    final applied = pullResult is PullSyncSuccess ? pullResult.appliedCount : 0;

    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] incrementalPull: applied=$applied');
    }

    return SyncOrchestratorSuccess(appliedCount: applied);
  }

  Future<SyncOrchestratorResult> _executeProfileSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final profile = await _profileRepo.find();
    if (profile == null) return const SyncOrchestratorSuccess();

    final deviceId = await _keyManager.getDeviceId() ?? '';

    // Always push profile on explicit profile sync
    final ops = <Map<String, dynamic>>[
      {
        'op': 'update',
        'entityType': 'profile',
        'entityId': deviceId,
        'data': {
          'displayName': profile.displayName,
          'avatarEmoji': profile.avatarEmoji,
        },
        'fromDeviceId': deviceId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ];

    await _pushSync.execute(operations: ops, vectorClock: const {});

    // Push avatar if available
    await _avatarSync.pushAvatarToMembers(groupId: group.groupId);

    // Update last pushed hash
    _lastPushedProfileHash = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );

    return const SyncOrchestratorSuccess(pushedCount: 1);
  }

  Future<SyncOrchestratorResult> _executeFullPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final pullResult = await _pullSync.execute();
    final applied = pullResult is PullSyncSuccess ? pullResult.appliedCount : 0;

    return SyncOrchestratorSuccess(appliedCount: applied);
  }

  // --- Profile change detection ---

  Future<List<Map<String, dynamic>>> _buildProfileOperationsIfChanged() async {
    final profile = await _profileRepo.find();
    if (profile == null) return const [];

    final deviceId = await _keyManager.getDeviceId() ?? '';
    final currentHash = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );

    if (currentHash == _lastPushedProfileHash) return const [];

    _lastPushedProfileHash = currentHash;
    return [
      {
        'op': 'update',
        'entityType': 'profile',
        'entityId': deviceId,
        'data': {
          'displayName': profile.displayName,
          'avatarEmoji': profile.avatarEmoji,
        },
        'fromDeviceId': deviceId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ];
  }

  String _computeProfileHash(String displayName, String avatarEmoji) {
    final input = '$displayName|$avatarEmoji';
    return hash_lib.sha256.convert(utf8.encode(input)).toString();
  }
}
