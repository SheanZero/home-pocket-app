import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/family_sync/domain/repositories/sync_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'check_group_validity_use_case.dart';
import 'drain_family_sync_outbox_use_case.dart';
import 'full_sync_use_case.dart';
import 'pull_sync_use_case.dart';
import 'push_sync_use_case.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';
import 'sync_vector_clock.dart';
import 'shopping_item_change_tracker.dart';
import 'transaction_change_tracker.dart';

/// Result of an orchestrated sync operation.
sealed class SyncOrchestratorResult {
  const SyncOrchestratorResult();
}

class SyncOrchestratorSuccess extends SyncOrchestratorResult {
  const SyncOrchestratorSuccess({
    this.appliedCount = 0,
    this.ackedCount = 0,
    this.pageCount = 0,
    this.pushedCount = 0,
  });
  final int appliedCount;
  final int ackedCount;
  final int pageCount;
  final int pushedCount;
}

class SyncOrchestratorNoGroup extends SyncOrchestratorResult {
  const SyncOrchestratorNoGroup();
}

class SyncOrchestratorError extends SyncOrchestratorResult {
  const SyncOrchestratorError(
    this.message, {
    this.statusCode,
    this.isDeferred = false,
    this.appliedCount = 0,
    this.ackedCount = 0,
    this.pageCount = 0,
  });
  final String message;
  final int? statusCode;
  final bool isDeferred;
  final int appliedCount;
  final int ackedCount;
  final int pageCount;
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
    required ShoppingItemChangeTracker shoppingChangeTracker,
    DrainFamilySyncOutboxUseCase? outboxDrainer,
  }) : _pullSync = pullSync,
       _pushSync = pushSync,
       _fullSync = fullSync,
       _avatarSync = avatarSync,
       _checkValidity = checkValidity,
       _groupRepo = groupRepo,
       _profileRepo = profileRepo,
       _queueManager = queueManager,
       _keyManager = keyManager,
       _changeTracker = changeTracker,
       _shoppingChangeTracker = shoppingChangeTracker,
       _outboxDrainer = outboxDrainer;

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
  final ShoppingItemChangeTracker _shoppingChangeTracker;
  final DrainFamilySyncOutboxUseCase? _outboxDrainer;

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

  Future<SyncQueueSummary> getQueueSummary() => _queueManager.getSummary();

  /// Startup/resume recovery hook. Safe to call repeatedly because accepted
  /// rows are deleted by exact stable operation id and revision.
  Future<int> recoverDurableOutbox() async {
    return await _outboxDrainer?.execute() ?? 0;
  }

  // --- Private orchestration flows ---

  Future<SyncOrchestratorResult> _executeInitialSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] initialSync started');
    }

    // Persisted mutations must leave the outbox before any pull/full snapshot.
    final recovered = await recoverDurableOutbox();

    // Always: push all → push avatar → pull
    final pushed = await _fullSync.execute();
    Map<String, dynamic>? profileOperation;
    if (_profileRepo is! DurableFamilySyncUserProfileRepository) {
      profileOperation = await _buildCurrentProfileOperation(group.groupId);
      if (profileOperation != null) {
        await _pushSync.execute(
          operations: [profileOperation],
          vectorClock: const {},
          expectedGroupId: group.groupId,
        );
        _lastPushedProfileHash = profileOperation['profileDigest'] as String?;
      }
      await _avatarSync.pushAvatarToMembers(groupId: group.groupId);
    }
    final pullResult = await _pullSync.execute();
    final pullOutcome = await _completePull(
      groupId: group.groupId,
      result: pullResult,
      pushedCount: pushed + recovered + (profileOperation == null ? 0 : 1),
    );
    if (pullOutcome is! SyncOrchestratorSuccess) {
      return pullOutcome;
    }

    if (kDebugMode) {
      debugPrint(
        '[SyncOrchestrator] initialSync complete: pushed=$pushed, applied=${pullOutcome.appliedCount}',
      );
    }

    return pullOutcome;
  }

  Future<SyncOrchestratorResult> _executeIncrementalPush() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    // Check group validity (5-min cache)
    final validity = await _checkValidity.execute();
    if (validity is GroupInvalid) {
      return const SyncOrchestratorNoGroup();
    }
    if (validity is GroupNoGroup) {
      return const SyncOrchestratorNoGroup();
    }

    final recovered = await recoverDurableOutbox();

    // Flush pending transaction changes
    final txnOps = _changeTracker.flush();
    if (txnOps.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[SyncOrchestrator] incrementalPush: pushing ${txnOps.length} transaction ops',
        );
      }
      await _pushSync.execute(
        operations: txnOps,
        vectorClock: buildSyncVectorClock(txnOps),
      );
    }

    // Flush pending shopping item changes (SC-3, SYNC-01)
    final shoppingOps = _shoppingChangeTracker.flush();
    if (shoppingOps.isNotEmpty) {
      if (kDebugMode) {
        debugPrint(
          '[SyncOrchestrator] incrementalPush: pushing ${shoppingOps.length} shopping ops',
        );
      }
      await _pushSync.execute(operations: shoppingOps, vectorClock: const {});
    }

    // Build profile operation if changed
    final profileOps = _profileRepo is DurableFamilySyncUserProfileRepository
        ? const <Map<String, dynamic>>[]
        : await _buildProfileOperationsIfChanged(group.groupId);

    if (profileOps.isNotEmpty) {
      await _pushSync.execute(operations: profileOps, vectorClock: const {});
    }

    if (kDebugMode) {
      debugPrint('[SyncOrchestrator] incrementalPush: draining offline queue');
    }

    // Drain offline queue
    await _queueManager.drainQueue();

    // WR-03: include shopping + profile ops so pushedCount reflects all work
    // pushed this round, not just transactions (a shopping/profile-only round
    // previously reported 0).
    return SyncOrchestratorSuccess(
      pushedCount:
          recovered + txnOps.length + shoppingOps.length + profileOps.length,
    );
  }

  Future<SyncOrchestratorResult> _executeIncrementalPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    await recoverDurableOutbox();
    final pullResult = await _pullSync.execute();
    if (pullResult is PullSyncSuccess || pullResult is PullSyncNoNewData) {
      // A control/key envelope in this pull may have installed the current
      // epoch. Retry the durable semantic source immediately with that key.
      await recoverDurableOutbox();
    }
    final outcome = await _completePull(
      groupId: group.groupId,
      result: pullResult,
    );

    if (kDebugMode) {
      final applied = outcome is SyncOrchestratorSuccess
          ? outcome.appliedCount
          : 0;
      debugPrint('[SyncOrchestrator] incrementalPull: applied=$applied');
    }

    return outcome;
  }

  Future<SyncOrchestratorResult> _executeProfileSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    if (_profileRepo is DurableFamilySyncUserProfileRepository) {
      final recovered = await recoverDurableOutbox();
      return SyncOrchestratorSuccess(pushedCount: recovered);
    }

    final operation = await _buildCurrentProfileOperation(group.groupId);
    if (operation == null) {
      return const SyncOrchestratorSuccess();
    }

    await _pushSync.execute(
      operations: [operation],
      vectorClock: const {},
      expectedGroupId: group.groupId,
    );

    // Push avatar if available
    await _avatarSync.pushAvatarToMembers(groupId: group.groupId);

    // Update last pushed hash
    _lastPushedProfileHash = operation['profileDigest'] as String?;

    return const SyncOrchestratorSuccess(pushedCount: 1);
  }

  Future<SyncOrchestratorResult> _executeFullPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    await recoverDurableOutbox();
    final pullResult = await _pullSync.execute();
    if (pullResult is PullSyncSuccess || pullResult is PullSyncNoNewData) {
      await recoverDurableOutbox();
    }
    return _completePull(groupId: group.groupId, result: pullResult);
  }

  Future<SyncOrchestratorResult> _completePull({
    required String groupId,
    required PullSyncResult result,
    int pushedCount = 0,
  }) async {
    final outcome = _mapPullResult(result, pushedCount: pushedCount);
    if (result is PullSyncSuccess || result is PullSyncNoNewData) {
      final recorded = await _groupRepo.updateLastSyncTime(
        DateTime.now().toUtc(),
        expectedGroupId: groupId,
      );
      if (!recorded) return const SyncOrchestratorNoGroup();
    }
    return outcome;
  }

  SyncOrchestratorResult _mapPullResult(
    PullSyncResult result, {
    int pushedCount = 0,
  }) {
    return switch (result) {
      PullSyncSuccess(
        :final appliedCount,
        :final ackedCount,
        :final pageCount,
      ) =>
        SyncOrchestratorSuccess(
          appliedCount: appliedCount,
          ackedCount: ackedCount,
          pageCount: pageCount,
          pushedCount: pushedCount,
        ),
      PullSyncNoNewData() => SyncOrchestratorSuccess(pushedCount: pushedCount),
      PullSyncNoPair() => const SyncOrchestratorNoGroup(),
      PullSyncDeferred(
        :final message,
        :final appliedCount,
        :final ackedCount,
        :final pageCount,
      ) =>
        SyncOrchestratorError(
          message,
          isDeferred: true,
          appliedCount: appliedCount,
          ackedCount: ackedCount,
          pageCount: pageCount,
        ),
      PullSyncError(
        :final message,
        :final statusCode,
        :final appliedCount,
        :final ackedCount,
        :final pageCount,
      ) =>
        SyncOrchestratorError(
          message,
          statusCode: statusCode,
          appliedCount: appliedCount,
          ackedCount: ackedCount,
          pageCount: pageCount,
        ),
    };
  }

  // --- Profile change detection ---

  Future<List<Map<String, dynamic>>> _buildProfileOperationsIfChanged(
    String groupId,
  ) async {
    final profile = await _profileRepo.find();
    if (profile == null) return const [];

    final deviceId = await _keyManager.getDeviceId() ?? '';
    if (deviceId.isEmpty) return const [];
    final currentHash = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );

    if (currentHash == _lastPushedProfileHash) return const [];

    final operation = await _buildCurrentProfileOperation(groupId);
    if (operation == null) return const [];
    _lastPushedProfileHash = currentHash;
    return [operation];
  }

  Future<Map<String, dynamic>?> _buildCurrentProfileOperation(
    String groupId,
  ) async {
    final profile = await _profileRepo.find();
    if (profile == null) return null;
    final deviceId = await _keyManager.getDeviceId() ?? '';
    if (deviceId.isEmpty) return null;
    final digest = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );
    final versionedRepository = _groupRepo is VersionedGroupMemberRepository
        ? _groupRepo as VersionedGroupMemberRepository
        : null;
    final prepared = versionedRepository != null
        ? await versionedRepository.prepareLocalProfileVersion(
            groupId: groupId,
            deviceId: deviceId,
            displayName: profile.displayName,
            avatarEmoji: profile.avatarEmoji,
            contentDigest: digest,
            now: DateTime.now(),
          )
        : null;
    if (versionedRepository != null && prepared == null) {
      return null;
    }
    final revision =
        prepared?.revision ?? profile.updatedAt.toUtc().microsecondsSinceEpoch;
    final originDeviceId = prepared?.originDeviceId ?? deviceId;
    return {
      'op': 'update',
      'entityType': 'profile',
      'entityId': deviceId,
      'operationId': 'profile:$deviceId:$revision:$digest',
      'profileDigest': digest,
      'revision': revision,
      'originDeviceId': originDeviceId,
      'data': {
        'schemaVersion': 1,
        'ownerDeviceId': deviceId,
        'revision': revision,
        'profileDigest': digest,
        'displayName': profile.displayName,
        'avatarEmoji': profile.avatarEmoji,
      },
      'fromDeviceId': deviceId,
      'timestamp': profile.updatedAt.toUtc().toIso8601String(),
    };
  }

  String _computeProfileHash(String displayName, String avatarEmoji) {
    return hash_lib.sha256
        .convert(utf8.encode(jsonEncode([displayName, avatarEmoji])))
        .toString();
  }
}
