import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/config/release_features.dart';
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

enum _UnableToJoinActionTarget { reenterInvite, chooseAnother }

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
  _UnableToJoinActionTarget? _pendingUnableToJoinAction;

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

  Future<void> _leaveCurrentFamilyAndContinue({
    required _UnableToJoinActionTarget target,
    bool skipConfirmation = false,
  }) async {
    if (_pendingUnableToJoinAction != null) return;
    final group = await ref
        .read(groupRepositoryProvider)
        .getGroupById(widget.groupId);
    if (!mounted) return;
    if (group == null) {
      setState(
        () => _lifecycleError = S.of(context).groupUnableToJoinActionFailed,
      );
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
      _pendingUnableToJoinAction = target;
      _lifecycleError = null;
    });
    final result = group.role == 'owner'
        ? await ref.read(deactivateGroupUseCaseProvider).execute(widget.groupId)
        : await ref.read(leaveGroupUseCaseProvider).execute(widget.groupId);
    if (!mounted) return;
    final succeeded =
        result is DeactivateGroupSuccess || result is LeaveGroupSuccess;
    if (!succeeded) {
      setState(() => _pendingUnableToJoinAction = null);
      final GroupOperationFailure? failure = switch (result) {
        DeactivateGroupError() => result,
        LeaveGroupError() => result,
        _ => null,
      };
      if (failure != null &&
          await handleFamilyNetworkFailure(
            context,
            failure,
            onRetry: () => _leaveCurrentFamilyAndContinue(
              target: target,
              skipConfirmation: true,
            ),
          )) {
        return;
      }
      setState(() {
        _lifecycleError = l10n.groupUnableToJoinActionFailed;
      });
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => target == _UnableToJoinActionTarget.reenterInvite
            ? const JoinGroupScreen()
            : const GroupChoiceScreen(),
      ),
    );
  }

  Future<void> _clearTerminalStateAndContinue(
    _UnableToJoinActionTarget target,
  ) async {
    if (_pendingUnableToJoinAction != null) return;
    setState(() {
      _pendingUnableToJoinAction = target;
      _lifecycleError = null;
    });
    try {
      await ref.read(groupRepositoryProvider).deactivateGroup(widget.groupId);
    } catch (_) {
      // The relay's terminal membership state is authoritative. Local cleanup
      // is best-effort and reconciliation will remove stale cache later.
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => target == _UnableToJoinActionTarget.reenterInvite
            ? const JoinGroupScreen()
            : const GroupChoiceScreen(),
      ),
    );
  }

  void _listenForJoinRequestResolution() {
    if (!ReleaseFeatures.pushNotifications) return;
    _joinRequestSubscription = ref
        .read(pushNotificationServiceProvider)
        .joinRequestLifecycleEvents
        .listen((event) {
          if (!mounted || event['groupId'] != widget.groupId) return;
          final status = JoinRequestStatusX.parse(event['status']);
          if (status != null) {
            _applyJoinRequestStatus(status);
            if (status == JoinRequestStatus.approved) {
              unawaited(_verifyGroupAndNavigate());
            }
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
        if (_requestStatus != JoinRequestStatus.approved) {
          setState(() => _requestStatus = JoinRequestStatus.approved);
        }
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
    final keyRecoveryUnrecoverable =
        _keyRecoveryStatus.groupId == widget.groupId &&
        _keyRecoveryStatus.phase == GroupKeyRecoveryPhase.unrecoverable;
    if (_requestStatus.isTerminal || keyRecoveryUnrecoverable) {
      return _buildUnableToJoinState(
        context,
        l10n,
        requiresMembershipExit:
            !_requestStatus.isTerminal && keyRecoveryUnrecoverable,
      );
    }
    final isRecoveringKey =
        _requestStatus == JoinRequestStatus.approved ||
        _keyRecoveryStatus.groupId == widget.groupId;
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
                                isRecoveringKey
                                    ? l10n.groupKeyRecoveryTitle
                                    : l10n.groupWaitingApproval,
                                textAlign: TextAlign.center,
                                style: AppTextStyles.pageTitle.copyWith(
                                  fontSize: 21,
                                  color: palette.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                isRecoveringKey
                                    ? l10n.groupKeyRecoveryWaiting
                                    : l10n.groupWaitingDesc(
                                        widget.ownerDisplayName,
                                      ),
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body.copyWith(
                                  color: palette.textSecondary,
                                ),
                              ),
                              if (!isRecoveringKey) ...[
                                const SizedBox(height: 24),
                                Text(
                                  '${l10n.groupWaitingHint1}\n${l10n.groupWaitingHint2}',
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.body.copyWith(
                                    color: palette.textSecondary,
                                  ),
                                ),
                              ],
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
      bottomNavigationBar: isRecoveringKey
          ? null
          : ColoredBox(
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
                        style: AppTextStyles.label.copyWith(
                          color: palette.error,
                        ),
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

  Widget _buildUnableToJoinState(
    BuildContext context,
    S l10n, {
    required bool requiresMembershipExit,
  }) {
    final palette = context.palette;
    final reenterLoading =
        _pendingUnableToJoinAction == _UnableToJoinActionTarget.reenterInvite;
    final chooseLoading =
        _pendingUnableToJoinAction == _UnableToJoinActionTarget.chooseAnother;

    Future<void> continueWith(_UnableToJoinActionTarget target) =>
        requiresMembershipExit
        ? _leaveCurrentFamilyAndContinue(target: target)
        : _clearTerminalStateAndContinue(target);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 52).clamp(
                        0,
                        double.infinity,
                      ),
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 340),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _UnableToJoinIllustration(),
                            const SizedBox(height: 34),
                            Text(
                              l10n.groupUnableToJoinTitle,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.pageTitle.copyWith(
                                fontSize: 24,
                                height: 32 / 24,
                                color: palette.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l10n.groupUnableToJoinDescription,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.body.copyWith(
                                height: 22 / 14,
                                color: palette.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: palette.borderDivider),
          ],
        ),
      ),
      bottomNavigationBar: ColoredBox(
        color: palette.background,
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(
            familyFlowHorizontalPadding,
            24,
            familyFlowHorizontalPadding,
            22,
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
                const SizedBox(height: 12),
              ],
              _UnableToJoinAction(
                controlKey: const Key('reenter-family-invite-action'),
                label: l10n.groupReenterInvite,
                icon: LucideIcons.logIn,
                color: palette.accentPrimary,
                isLoading: reenterLoading,
                onPressed: _pendingUnableToJoinAction == null
                    ? () =>
                          continueWith(_UnableToJoinActionTarget.reenterInvite)
                    : null,
              ),
              const SizedBox(height: 12),
              _UnableToJoinAction(
                controlKey: const Key('choose-another-family-action'),
                label: l10n.groupExitAndChooseAnother,
                icon: LucideIcons.logOut,
                color: palette.joyText,
                isLoading: chooseLoading,
                onPressed: _pendingUnableToJoinAction == null
                    ? () =>
                          continueWith(_UnableToJoinActionTarget.chooseAnother)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnableToJoinIllustration extends StatelessWidget {
  const _UnableToJoinIllustration();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 164,
      height: 168,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(LucideIcons.house, size: 120, color: palette.textSecondary),
          Positioned(
            right: 4,
            bottom: 12,
            child: Icon(LucideIcons.circleX, size: 42, color: palette.joyText),
          ),
        ],
      ),
    );
  }
}

class _UnableToJoinAction extends StatelessWidget {
  const _UnableToJoinAction({
    required this.controlKey,
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.isLoading,
  });

  final Key controlKey;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return OutlinedButton(
      key: controlKey,
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(62),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        foregroundColor: color,
        backgroundColor: Colors.transparent,
        disabledForegroundColor: color.withValues(alpha: 0.62),
        disabledBackgroundColor: Colors.transparent,
        side: BorderSide(color: palette.borderDefault),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: SizedBox(
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: isLoading
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, size: 22),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 34),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: AppTextStyles.button.copyWith(
                  color: color,
                  fontSize: 15,
                ),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Icon(LucideIcons.chevronRight, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
