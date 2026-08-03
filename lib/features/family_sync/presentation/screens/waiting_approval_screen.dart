import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../../domain/models/sync_status_model.dart';
import '../../../../application/family_sync/complete_member_activation_use_case.dart';
import '../../../../application/family_sync/deactivate_group_use_case.dart';
import '../../../../application/family_sync/group_key_recovery_use_case.dart';
import '../../../../application/family_sync/join_request_lifecycle_use_cases.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/group_operation_error.dart';
import '../providers/repository_providers.dart';
import '../providers/state_sync.dart';
import '../widgets/family_flow_components.dart';
import '../widgets/family_network_unavailable_dialog.dart';
import 'group_choice_screen.dart';
import 'group_management_screen.dart';
import 'join_group_screen.dart';

enum WaitingApprovalInitialMode { pendingApproval, recoveringKey }

/// Centered waiting screen displayed after the joiner has confirmed their
/// join request and is waiting for the group owner to approve.
///
/// Preserves the existing polling + event-listener pattern from the previous
/// implementation but with a redesigned UI matching the Pencil design.
class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.ownerDisplayName,
    this.initialMode = WaitingApprovalInitialMode.pendingApproval,
  });

  final String groupId;
  final String groupName;
  final String ownerDisplayName;
  final WaitingApprovalInitialMode initialMode;

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  bool _hasNavigated = false;
  StreamSubscription<SyncStatus>? _syncSubscription;
  StreamSubscription<Map<String, dynamic>>? _joinRequestSubscription;
  StreamSubscription<GroupKeyRecoveryStatus>? _keyRecoverySubscription;
  Timer? _pollingTimer;
  int _pollCount = 0;
  late JoinRequestStatus _requestStatus;
  bool _isCancelling = false;
  String? _lifecycleError;
  GroupKeyRecoveryStatus _keyRecoveryStatus = const GroupKeyRecoveryStatus();
  bool _isRetryingKey = false;
  bool _isAbandoningRecovery = false;

  @override
  void initState() {
    super.initState();
    _requestStatus =
        widget.initialMode == WaitingApprovalInitialMode.recoveringKey
        ? JoinRequestStatus.approved
        : JoinRequestStatus.pending;
    _listenForSyncStatus();
    _listenForJoinRequestResolution();
    _listenForKeyRecovery();
    _startAdaptivePolling();
    if (widget.initialMode == WaitingApprovalInitialMode.recoveringKey) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_verifyGroupAndNavigate());
      });
    }
  }

  void _listenForKeyRecovery() {
    final coordinator = ref.read(groupKeyRecoveryCoordinatorProvider);
    _keyRecoveryStatus = coordinator.currentStatus;
    _keyRecoverySubscription = coordinator.statusStream.listen((status) {
      if (!mounted || status.groupId != widget.groupId) return;
      setState(() => _keyRecoveryStatus = status);
      if (status.phase == GroupKeyRecoveryPhase.recovered) {
        unawaited(_verifyGroupAndNavigate());
      }
    });
  }

  Future<void> _retryGroupKey() async {
    if (_isRetryingKey) return;
    setState(() => _isRetryingKey = true);
    await ref
        .read(groupKeyRecoveryCoordinatorProvider)
        .requestKey(groupId: widget.groupId, manual: true);
    await _verifyGroupAndNavigate();
    if (mounted) setState(() => _isRetryingKey = false);
  }

  Future<void> _leaveAndChooseAnotherFamily({
    bool skipConfirmation = false,
  }) async {
    if (_isAbandoningRecovery) return;
    final group = await ref
        .read(groupRepositoryProvider)
        .getGroupById(widget.groupId);
    if (!mounted) return;
    if (group == null) {
      setState(() => _lifecycleError = S.of(context).familySyncRestoreFailed);
      return;
    }
    final l10n = S.of(context);
    final isOwner = group.role == 'owner';
    if (!skipConfirmation) {
      final confirmed = await showSoftConfirmDialog(
        context,
        title: isOwner
            ? l10n.familySyncDeactivateGroup
            : l10n.familySyncLeaveGroup,
        body: isOwner
            ? l10n.familySyncDeactivateGroupConfirm
            : l10n.familySyncLeaveGroupConfirm,
        confirmLabel: isOwner
            ? l10n.familySyncDeactivateGroup
            : l10n.familySyncLeaveGroup,
        cancelLabel: l10n.cancel,
      );
      if (!confirmed || !mounted) return;
    }

    setState(() {
      _isAbandoningRecovery = true;
      _lifecycleError = null;
    });
    final result = group.role == 'owner'
        ? await ref.read(deactivateGroupUseCaseProvider).execute(widget.groupId)
        : await ref.read(leaveGroupUseCaseProvider).execute(widget.groupId);
    if (!mounted) return;
    final succeeded =
        result is DeactivateGroupSuccess || result is LeaveGroupSuccess;
    if (!succeeded) {
      setState(() => _isAbandoningRecovery = false);
      final GroupOperationFailure? failure = switch (result) {
        DeactivateGroupError() => result,
        LeaveGroupError() => result,
        _ => null,
      };
      if (failure != null &&
          await handleFamilyNetworkFailure(
            context,
            failure,
            onRetry: () => _leaveAndChooseAnotherFamily(skipConfirmation: true),
          )) {
        return;
      }
      setState(() {
        _lifecycleError = switch (result) {
          DeactivateGroupError(:final message) =>
            l10n.familySyncDeactivateGroupFailed(message),
          LeaveGroupError(:final message) => l10n.familySyncLeaveGroupFailed(
            message,
          ),
          _ => l10n.groupKeyRecoveryUnavailable,
        };
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const GroupChoiceScreen()),
    );
  }

  void _listenForJoinRequestResolution() {
    _joinRequestSubscription = ref
        .read(pushNotificationServiceProvider)
        .joinRequestLifecycleEvents
        .listen((event) {
          if (!mounted || event['groupId'] != widget.groupId) return;
          final status = JoinRequestStatusX.parse(event['status']);
          if (status != null) {
            _applyJoinRequestStatus(status);
          } else {
            unawaited(_refreshJoinRequestStatus());
          }
        });
  }

  void _listenForSyncStatus() {
    final engine = ref.read(syncEngineProvider);
    _syncSubscription = engine.statusStream.listen((status) {
      if (!mounted || _hasNavigated) return;
      if (status.state == SyncState.initialSyncing ||
          status.state == SyncState.awaitingKey ||
          status.state == SyncState.synced) {
        unawaited(_verifyGroupAndNavigate());
      }
    });
  }

  void _startAdaptivePolling() {
    _pollingTimer?.cancel();
    _pollCount = 0;
    _scheduleNextPoll();
  }

  void _scheduleNextPoll() {
    if (_hasNavigated || _requestStatus.isTerminal) return;

    // Adaptive backoff: 5s -> 10s -> 15s -> 30s, then stays at 30s
    const delays = [5, 10, 15, 30];
    final delaySeconds = delays[_pollCount.clamp(0, delays.length - 1)];

    _pollingTimer = Timer(Duration(seconds: delaySeconds), () async {
      if (!mounted || _hasNavigated) return;
      _pollCount++;
      await _pollOnce();
      if (mounted && !_hasNavigated && !_requestStatus.isTerminal) {
        _scheduleNextPoll();
      }
    });
  }

  Future<void> _pollOnce() async {
    final statusLoaded = await _refreshJoinRequestStatus();
    if (!statusLoaded) return;
    if (!mounted || _hasNavigated || _requestStatus.isTerminal) return;
    await _verifyGroupAndNavigate();
  }

  Future<bool> _refreshJoinRequestStatus() async {
    final result = await ref
        .read(getJoinRequestStatusUseCaseProvider)
        .execute(groupId: widget.groupId);
    if (!mounted || _hasNavigated) return false;
    switch (result) {
      case JoinRequestLifecycleSuccess(:final status):
        _applyJoinRequestStatus(status);
        return true;
      case JoinRequestLifecycleError(:final message, :final kind):
        if (kind == GroupOperationErrorKind.notFound) {
          // Local confirming state is only a cache. If the relay no longer
          // has this request, clear the cache and move to a recoverable
          // terminal state rather than polling and displaying a raw 404.
          try {
            await ref
                .read(groupRepositoryProvider)
                .deactivateGroup(widget.groupId);
          } catch (_) {
            // The relay result remains authoritative. Local cache cleanup is
            // best-effort here and will be reconciled on the next app start.
          }
          if (!mounted || _hasNavigated) return false;
          _applyJoinRequestStatus(JoinRequestStatus.expired);
          return true;
        }
        // Polling is background work. Stay on the pending state while offline
        // or throttled instead of exposing transport errors or immediately
        // issuing another family API request.
        if (kind == GroupOperationErrorKind.networkUnavailable ||
            kind == GroupOperationErrorKind.rateLimited) {
          setState(() => _lifecycleError = null);
          return false;
        }
        setState(() => _lifecycleError = message);
        return false;
    }
  }

  void _applyJoinRequestStatus(JoinRequestStatus status) {
    if (!mounted) return;
    if (status.isTerminal) {
      _stopPolling();
    }
    setState(() {
      _requestStatus = status;
      _lifecycleError = null;
    });
  }

  Future<void> _cancelJoinRequest() async {
    if (_isCancelling || _requestStatus.isTerminal) return;
    setState(() {
      _isCancelling = true;
      _lifecycleError = null;
    });
    final result = await ref
        .read(cancelJoinRequestUseCaseProvider)
        .execute(groupId: widget.groupId);
    if (!mounted) return;
    setState(() => _isCancelling = false);
    switch (result) {
      case JoinRequestLifecycleSuccess(:final status):
        _applyJoinRequestStatus(status);
      case JoinRequestLifecycleError(:final message):
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _cancelJoinRequest,
        )) {
          return;
        }
        setState(() => _lifecycleError = message);
    }
  }

  Future<void> _tryAnotherInvite() async {
    await ref.read(groupRepositoryProvider).deactivateGroup(widget.groupId);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const JoinGroupScreen()),
    );
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _verifyGroupAndNavigate() async {
    if (_hasNavigated) return;

    final result = await ref
        .read(completeMemberActivationUseCaseProvider)
        .execute(expectedGroupId: widget.groupId);
    if (!mounted || _hasNavigated) return;

    switch (result) {
      case MemberActivationReady(:final groupId):
        _hasNavigated = true;
        _stopPolling();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case MemberActivationNotInGroup():
        break;
      case MemberActivationPendingApproval():
        break;
      case MemberActivationAwaitingKey():
        break;
      case MemberActivationError():
        break;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    unawaited(_syncSubscription?.cancel());
    unawaited(_joinRequestSubscription?.cancel());
    unawaited(_keyRecoverySubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    final palette = context.palette;
    if (_requestStatus.isTerminal) {
      return _buildTerminalState(context, l10n);
    }
    if (_requestStatus == JoinRequestStatus.approved ||
        _keyRecoveryStatus.groupId == widget.groupId) {
      return _buildKeyRecoveryState(context, l10n);
    }
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: familyFlowHorizontalPadding,
          ),
          child: Column(
            children: [
              const SizedBox(height: 7),
              FamilyFlowHeader(
                title: l10n.familyFlowWaitingHeader,
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 16),
              FamilyFlowProgress(
                labels: [
                  l10n.familyFlowJoinStepCode,
                  l10n.familyFlowJoinStepConfirm,
                  l10n.familyFlowJoinStepWait,
                ],
                currentStep: 2,
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final centeredHeight = constraints.maxHeight > 48
                        ? constraints.maxHeight - 48
                        : 0.0;
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: centeredHeight),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 68,
                                height: 68,
                                child: CircularProgressIndicator(
                                  strokeWidth: 4,
                                  color: palette.accentPrimary,
                                  backgroundColor: palette.borderDefault,
                                ),
                              ),
                              const SizedBox(height: 27),
                              Text(
                                l10n.groupWaitingApproval,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.pageTitle.copyWith(
                                  fontSize: 21,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                l10n.groupWaitingDesc(widget.ownerDisplayName),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                '${l10n.groupWaitingHint1}\n${l10n.groupWaitingHint2}',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: palette.background,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            familyFlowHorizontalPadding,
            10,
            familyFlowHorizontalPadding,
            14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_lifecycleError case final error?) ...[
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.label.copyWith(color: palette.error),
                ),
                const SizedBox(height: 10),
              ],
              FamilySecondaryButton(
                controlKey: const Key('cancel-join-request-button'),
                onPressed: _isCancelling ? null : _cancelJoinRequest,
                label: l10n.groupCancelRequest,
                icon: LucideIcons.undo,
                isLoading: _isCancelling,
                prominent: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyRecoveryState(BuildContext context, S l10n) {
    final palette = context.palette;
    final phase = _keyRecoveryStatus.phase;
    final unavailable = phase == GroupKeyRecoveryPhase.unrecoverable;
    final rateLimited = phase == GroupKeyRecoveryPhase.rateLimited;
    final description = unavailable
        ? l10n.groupKeyRecoveryUnavailable
        : rateLimited
        ? l10n.groupKeyRecoveryRateLimited
        : l10n.groupKeyRecoveryWaiting;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: familyFlowHorizontalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  unavailable ? Icons.key_off_outlined : Icons.key_outlined,
                  size: 64,
                  color: unavailable ? palette.warning : palette.accentPrimary,
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.groupKeyRecoveryTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _isRetryingKey ? null : _retryGroupKey,
                  child: _isRetryingKey
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.groupKeyRecoveryRetry),
                ),
                const SizedBox(height: 12),
                FamilySecondaryButton(
                  controlKey: const Key('choose-another-family-action'),
                  onPressed: _isAbandoningRecovery
                      ? null
                      : _leaveAndChooseAnotherFamily,
                  label: l10n.groupKeyRecoveryRebuild,
                  icon: LucideIcons.logOut,
                  isLoading: _isAbandoningRecovery,
                ),
                if (_lifecycleError case final error?) ...[
                  const SizedBox(height: 12),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.error),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTerminalState(BuildContext context, S l10n) {
    final palette = context.palette;
    final (title, description) = switch (_requestStatus) {
      JoinRequestStatus.rejected => (
        l10n.groupRequestRejectedTitle,
        l10n.groupRequestRejectedDescription,
      ),
      JoinRequestStatus.cancelled => (
        l10n.groupRequestCancelledTitle,
        l10n.groupRequestCancelledDescription,
      ),
      JoinRequestStatus.expired => (
        l10n.groupRequestExpiredTitle,
        l10n.groupRequestExpiredDescription,
      ),
      JoinRequestStatus.pending || JoinRequestStatus.approved => ('', ''),
    };

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: familyFlowHorizontalPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 64,
                  color: palette.textSecondary,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textSecondary),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _tryAnotherInvite,
                  child: Text(l10n.groupTryAnotherInvite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
