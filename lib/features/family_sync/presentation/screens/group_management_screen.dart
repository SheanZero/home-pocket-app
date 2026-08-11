import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../application/family_sync/manage_group_invite_use_case.dart';
import '../../../../application/family_sync/group_operation_error.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status_model.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/deactivate_group_use_case.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import '../../../../application/family_sync/transfer_owner_use_case.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_active_group.dart';
import '../providers/state_sync.dart';
import '../widgets/group_rename_dialog.dart';
import '../widgets/family_network_unavailable_dialog.dart';
import '../widgets/family_flow_components.dart';
import '../widgets/invite_expiry_countdown.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/sync_status_badge.dart';
import 'member_approval_screen.dart';
import 'join_group_screen.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({
    super.key,
    this.groupId,
    this.approvedMemberDeviceId,
    this.shareInvite,
    this.copyInvite,
  });

  final String? groupId;
  final String? approvedMemberDeviceId;
  final Future<void> Function(String text)? shareInvite;
  final Future<void> Function(String code)? copyInvite;

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  GroupInfo? _activeGroup;
  String? _managedInviteCode;
  DateTime? _managedInviteExpiresAt;
  bool _isLoading = true;
  bool _isInviteLoading = false;
  bool _isTransferLoading = false;

  GroupInfo? get _currentGroup {
    final watched = ref.read(activeGroupProvider).value;
    if (watched != null &&
        (widget.groupId == null || widget.groupId == watched.groupId)) {
      return _withManagedInvite(watched);
    }
    return _withManagedInvite(_activeGroup);
  }

  GroupInfo? _withManagedInvite(GroupInfo? group) {
    final code = _managedInviteCode;
    if (group == null || code == null) return group;
    return group.copyWith(
      inviteCode: code,
      inviteExpiresAt: _managedInviteExpiresAt,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);
    final group = widget.groupId != null
        ? await ref.read(groupRepositoryProvider).getGroupById(widget.groupId!)
        : await ref.read(groupRepositoryProvider).getActiveGroup();
    if (!mounted) return;
    setState(() {
      _activeGroup = group;
      _isLoading = false;
    });
  }

  Future<void> _handleRename() async {
    final group = _currentGroup;
    if (group == null) return;

    final newName = await GroupRenameDialog.show(context, group.groupName);
    if (newName == null || !mounted) return;

    final result = await ref
        .read(renameGroupUseCaseProvider)
        .execute(groupId: group.groupId, groupName: newName);

    if (!mounted) return;

    switch (result) {
      case RenameGroupSuccess(:final groupName):
        setState(() {
          _activeGroup = group.copyWith(groupName: groupName);
        });
      case RenameGroupError():
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _handleRename,
        )) {
          return;
        }
        if (!mounted) return;
        showErrorFeedback(context, l10n.groupRenameFailed);
    }
  }

  Future<void> _handleLeaveOrDeactivate() async {
    final group = _currentGroup;
    if (group == null) return;

    final isOwner = group.role == 'owner';
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

    final result = isOwner
        ? await ref.read(deactivateGroupUseCaseProvider).execute(group.groupId)
        : await ref.read(leaveGroupUseCaseProvider).execute(group.groupId);

    if (!mounted) return;

    if (result is DeactivateGroupSuccess || result is LeaveGroupSuccess) {
      Navigator.of(context).pop();
      return;
    }

    final GroupOperationFailure? failure = switch (result) {
      DeactivateGroupError() => result,
      LeaveGroupError() => result,
      _ => null,
    };
    if (failure != null &&
        await handleFamilyNetworkFailure(
          context,
          failure,
          onRetry: _handleLeaveOrDeactivate,
        )) {
      return;
    }
    if (!mounted) return;

    final message = switch (result) {
      DeactivateGroupError(:final message) =>
        l10n.familySyncDeactivateGroupFailed(message),
      LeaveGroupError(:final message) => l10n.familySyncLeaveGroupFailed(
        message,
      ),
      _ => l10n.familySyncStatusError,
    };
    showErrorFeedback(context, message);
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final group = _currentGroup;
    if (group == null) return;

    final confirmed = await showSoftConfirmDialog(
      context,
      title: l10n.familySyncRemoveMember,
      body: l10n.familySyncRemoveMemberConfirm(member.deviceName),
      confirmLabel: l10n.familySyncRemoveMember,
      cancelLabel: l10n.cancel,
    );

    if (!confirmed || !mounted) return;

    final result = await ref
        .read(removeMemberUseCaseProvider)
        .execute(groupId: group.groupId, deviceId: member.deviceId);
    if (!mounted) return;

    if (result is RemoveMemberSuccess) {
      await _loadGroup();
      return;
    }

    if (result is RemoveMemberError) {
      if (await handleFamilyNetworkFailure(
        context,
        result,
        onRetry: () => _handleRemoveMember(member),
      )) {
        return;
      }
      if (!mounted) return;
      showErrorFeedback(
        context,
        l10n.familySyncRemoveMemberFailed(result.message),
      );
    }
  }

  Future<void> _handleInvite() async {
    final group = _currentGroup;
    if (group == null || group.role != 'owner' || _isInviteLoading) return;

    setState(() => _isInviteLoading = true);
    final result = await ref
        .read(manageGroupInviteUseCaseProvider)
        .execute(groupId: group.groupId);
    if (!mounted) return;
    setState(() => _isInviteLoading = false);

    switch (result) {
      case ManageGroupInviteSuccess():
        _applyInviteToLocalState(result);
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _OwnerInviteSheet(
            groupName: group.groupName,
            initialInvite: result,
            onRefresh: _refreshInvite,
            onCopy: _copyInvite,
            onShare: (inviteCode) => _shareInvite(
              groupName: group.groupName,
              inviteCode: inviteCode,
            ),
          ),
        );
      case ManageGroupInviteForbidden():
        showErrorFeedback(context, l10n.familySyncInviteOwnerOnly);
      case ManageGroupInviteError():
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _handleInvite,
        )) {
          return;
        }
        if (!mounted) return;
        showErrorFeedback(context, l10n.familySyncRegenerateInviteFailed);
    }
  }

  Future<void> _handleTransferOwnership() async {
    final group = _currentGroup;
    if (group == null ||
        group.role != 'owner' ||
        group.groupKey?.isNotEmpty != true ||
        _isTransferLoading) {
      return;
    }
    final candidates = group.members
        .where((member) => member.status == 'active' && member.role == 'member')
        .toList();
    if (candidates.isEmpty) return;

    final target = await showModalBottomSheet<GroupMember>(
      context: context,
      backgroundColor: context.palette.card,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.familySyncTransferOwnerSelect,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final member in candidates)
                ListTile(
                  key: Key('transfer-owner-candidate-${member.deviceId}'),
                  leading: Text(
                    member.avatarEmoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(member.displayName),
                  subtitle: Text(member.deviceName),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () => Navigator.pop(sheetContext, member),
                ),
            ],
          ),
        ),
      ),
    );
    if (target == null || !mounted) return;

    final firstConfirmed = await showSoftConfirmDialog(
      context,
      title: l10n.familySyncTransferOwnerConfirmTitle,
      body: l10n.familySyncTransferOwnerConfirmBody(target.displayName),
      confirmLabel: l10n.next,
      cancelLabel: l10n.cancel,
    );
    if (!firstConfirmed || !mounted) return;
    final finalConfirmed = await showSoftConfirmDialog(
      context,
      title: l10n.familySyncTransferOwnerFinalTitle,
      body: l10n.familySyncTransferOwnerFinalBody(target.displayName),
      confirmLabel: l10n.familySyncTransferOwner,
      cancelLabel: l10n.cancel,
    );
    if (!finalConfirmed || !mounted) return;

    setState(() => _isTransferLoading = true);
    final result = await ref
        .read(ownerTransferUseCaseProvider)
        .execute(groupId: group.groupId, targetDeviceId: target.deviceId);
    if (!mounted) return;
    setState(() => _isTransferLoading = false);
    switch (result) {
      case OwnerTransferSuccess():
        await _loadGroup();
        if (mounted) {
          showSuccessFeedback(context, l10n.familySyncTransferOwnerSuccess);
        }
      case OwnerTransferForbidden():
        showErrorFeedback(context, l10n.familySyncTransferOwnerNotReady);
      case OwnerTransferInvalidTarget():
        showErrorFeedback(context, l10n.familySyncTransferOwnerInvalidTarget);
      case OwnerTransferError(:final message):
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _handleTransferOwnership,
        )) {
          return;
        }
        if (!mounted) return;
        showErrorFeedback(context, l10n.familySyncTransferOwnerFailed(message));
    }
  }

  Future<ManageGroupInviteResult> _refreshInvite() async {
    final group = _currentGroup;
    if (group == null || group.role != 'owner') {
      return const ManageGroupInviteForbidden();
    }

    final result = await ref
        .read(manageGroupInviteUseCaseProvider)
        .execute(groupId: group.groupId, forceRefresh: true);
    if (mounted && result is ManageGroupInviteSuccess) {
      _applyInviteToLocalState(result);
    }
    return result;
  }

  void _applyInviteToLocalState(ManageGroupInviteSuccess invite) {
    final group = _currentGroup;
    if (!mounted || group == null) return;
    setState(() {
      _managedInviteCode = invite.inviteCode;
      _managedInviteExpiresAt = invite.expiresAt;
      _activeGroup = group.copyWith(
        inviteCode: invite.inviteCode,
        inviteExpiresAt: invite.expiresAt,
      );
    });
  }

  Future<void> _handleRegenerateInlineInvite() async {
    if (_isInviteLoading) return;
    setState(() => _isInviteLoading = true);
    final result = await _refreshInvite();
    if (!mounted) return;
    setState(() => _isInviteLoading = false);
    switch (result) {
      case ManageGroupInviteSuccess():
        showSuccessFeedback(context, l10n.familySyncInviteRegenerated);
      case ManageGroupInviteForbidden():
        showErrorFeedback(context, l10n.familySyncInviteOwnerOnly);
      case ManageGroupInviteError():
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _handleRegenerateInlineInvite,
        )) {
          return;
        }
        if (!mounted) return;
        showErrorFeedback(context, l10n.familySyncRegenerateInviteFailed);
    }
  }

  Future<void> _copyInvite(String inviteCode) async {
    final copy = widget.copyInvite;
    if (copy != null) {
      await copy(inviteCode);
    } else {
      await Clipboard.setData(ClipboardData(text: inviteCode));
    }
    if (mounted) {
      showSuccessFeedback(context, l10n.familySyncInviteCopied);
    }
  }

  Future<void> _shareInvite({
    required String groupName,
    required String inviteCode,
  }) async {
    final text = l10n.familySyncInviteShareMessage(groupName, inviteCode);
    final share = widget.shareInvite;
    if (share != null) {
      await share(text);
    } else {
      await SharePlus.instance.share(ShareParams(text: text));
    }
  }

  Future<void> _showSyncSettings(SyncState syncState) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.palette.card,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.familyFlowSyncSettings,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              SyncStatusBadge(state: syncState),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  LucideIcons.refreshCw,
                  color: context.palette.accentPrimary,
                ),
                title: Text(l10n.familySyncManualSync),
                subtitle: Text(l10n.familySyncManualSyncDesc),
                onTap: () {
                  Navigator.pop(sheetContext);
                  ref.read(syncEngineProvider).onManualSync();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  S get l10n => S.of(context);

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final syncState = syncStatusAsync.value?.state ?? SyncState.noGroup;
    final watchedGroup = ref.watch(activeGroupProvider).value;
    final baseGroup =
        watchedGroup != null &&
            (widget.groupId == null || widget.groupId == watchedGroup.groupId)
        ? watchedGroup
        : _activeGroup;
    final group = _withManagedInvite(baseGroup);

    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : group != null
            ? _buildGroupContent(syncState, group)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildGroupContent(SyncState syncState, GroupInfo group) {
    return _GroupManagementContent(
      syncState: syncState,
      group: group,
      approvedMemberDeviceId: widget.approvedMemberDeviceId,
      isInviteLoading: _isInviteLoading,
      isTransferLoading: _isTransferLoading,
      managementSummary: _managementSummary,
      roleLabel: _roleLabel,
      memberLifecycleLabel: _memberLifecycleLabel,
      onRename: _handleRename,
      onRemoveMember: _handleRemoveMember,
      onInvite: _handleInvite,
      onCopyInvite: _copyInvite,
      onShareInvite: _shareInvite,
      onRegenerateInvite: _handleRegenerateInlineInvite,
      onSyncSettings: _showSyncSettings,
      onLeaveOrDeactivate: _handleLeaveOrDeactivate,
      onTransferOwnership: _handleTransferOwnership,
    );
  }

  Widget _buildEmptyState() {
    final palette = context.palette;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users, size: 64, color: palette.textTertiary),
          const SizedBox(height: 16),
          Text(
            l10n.familySyncNoDevicePaired,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familySyncPairPrompt,
            style: TextStyle(fontSize: 14, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }

  String _roleLabel(String role) {
    return switch (role) {
      'owner' => l10n.familySyncRoleOwner,
      _ => l10n.familySyncRoleMember,
    };
  }

  String _managementSummary(GroupInfo group, List<GroupMember> activeMembers) {
    final owners = activeMembers.where((member) => member.role == 'owner');
    final owner = owners.isEmpty ? null : owners.first;
    final lastSyncAt = group.lastSyncAt;
    final syncLabel = lastSyncAt == null
        ? l10n.familySyncSynced
        : l10n.familySyncMinutesAgo(
            DateTime.now()
                .difference(lastSyncAt.toLocal())
                .inMinutes
                .clamp(0, 999),
          );
    return l10n.familyFlowManagementSummary(
      owner?.displayName ?? l10n.familySyncRoleOwner,
      activeMembers.length,
      syncLabel,
    );
  }

  String _memberLifecycleLabel(GroupMember member) {
    final date = member.removedAt ?? member.confirmedAt ?? member.joinedAt;
    final formatted = date == null
        ? null
        : MaterialLocalizations.of(context).formatShortDate(date.toLocal());
    if (member.status != 'active') {
      final reason = switch (member.removalReason ?? member.status) {
        'left' => l10n.familySyncRemovalReasonLeft,
        'removed' => l10n.familySyncRemovalReasonRemoved,
        'group_dissolved' => l10n.familySyncRemovalReasonDissolved,
        'rejected' => l10n.familySyncRemovalReasonRejected,
        'cancelled' => l10n.familySyncRemovalReasonCancelled,
        'expired' => l10n.familySyncRemovalReasonExpired,
        _ => l10n.familySyncRemovalReasonUnknown,
      };
      return formatted == null
          ? reason
          : l10n.familySyncRemovedAtReason(formatted, reason);
    }
    final role = _roleLabel(member.role);
    if (formatted == null) return role;
    return member.confirmedAt != null
        ? l10n.familySyncConfirmedAt(role, formatted)
        : l10n.familySyncJoinedAt(role, formatted);
  }
}

class _GroupManagementContent extends StatelessWidget {
  const _GroupManagementContent({
    required this.syncState,
    required this.group,
    required this.approvedMemberDeviceId,
    required this.isInviteLoading,
    required this.isTransferLoading,
    required this.managementSummary,
    required this.roleLabel,
    required this.memberLifecycleLabel,
    required this.onRename,
    required this.onRemoveMember,
    required this.onInvite,
    required this.onCopyInvite,
    required this.onShareInvite,
    required this.onRegenerateInvite,
    required this.onSyncSettings,
    required this.onLeaveOrDeactivate,
    required this.onTransferOwnership,
  });

  final SyncState syncState;
  final GroupInfo group;
  final String? approvedMemberDeviceId;
  final bool isInviteLoading;
  final bool isTransferLoading;
  final String Function(GroupInfo group, List<GroupMember> activeMembers)
  managementSummary;
  final String Function(String role) roleLabel;
  final String Function(GroupMember member) memberLifecycleLabel;
  final VoidCallback onRename;
  final Future<void> Function(GroupMember member) onRemoveMember;
  final Future<void> Function() onInvite;
  final Future<void> Function(String inviteCode) onCopyInvite;
  final Future<void> Function({
    required String groupName,
    required String inviteCode,
  })
  onShareInvite;
  final Future<void> Function() onRegenerateInvite;
  final Future<void> Function(SyncState syncState) onSyncSettings;
  final Future<void> Function() onLeaveOrDeactivate;
  final Future<void> Function() onTransferOwnership;

  @override
  Widget build(BuildContext context) {
    final data = _GroupManagementViewData.fromGroup(
      group,
      approvedMemberDeviceId: approvedMemberDeviceId,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: familyFlowHorizontalPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GroupManagementHeader(
            group: group,
            activeMembers: data.activeMembers,
            isOwner: data.isOwner,
            managementSummary: managementSummary,
            onRename: onRename,
            syncState: syncState,
          ),
          if (data.approvedMember case final member?)
            _ApprovedMemberJoining(member: member),
          if (data.isOwner && data.pendingMemberCount > 0)
            _PendingMemberRequests(
              groupId: group.groupId,
              pendingMemberCount: data.pendingMemberCount,
            ),
          _ActiveMemberCard(
            group: group,
            activeMembers: data.activeMembers,
            isOwner: data.isOwner,
            canManageInvites: data.canManageInvites,
            isInviteLoading: isInviteLoading,
            roleLabel: roleLabel,
            onRemoveMember: onRemoveMember,
            onInvite: onInvite,
          ),
          if (data.canManageInvites && group.inviteCode?.isNotEmpty == true)
            _ManagedInviteSection(
              group: group,
              isInviteLoading: isInviteLoading,
              onCopyInvite: onCopyInvite,
              onShareInvite: onShareInvite,
              onRegenerateInvite: onRegenerateInvite,
            ),
          if (data.terminalMembers.isNotEmpty)
            _MemberHistorySection(
              members: data.terminalMembers,
              memberLifecycleLabel: memberLifecycleLabel,
            ),
          const SizedBox(height: 8),
          _SyncSettingsAction(syncState: syncState, onTap: onSyncSettings),
          const SizedBox(height: 12),
          _GroupExitActions(
            group: group,
            canJoinAnotherFamily: data.canJoinAnotherFamily,
            canManageInvites: data.canManageInvites,
            hasTransferCandidate: data.hasTransferCandidate,
            isTransferLoading: isTransferLoading,
            onLeaveOrDeactivate: onLeaveOrDeactivate,
            onTransferOwnership: onTransferOwnership,
          ),
        ],
      ),
    );
  }
}

class _GroupManagementViewData {
  const _GroupManagementViewData({
    required this.isOwner,
    required this.canManageInvites,
    required this.pendingMemberCount,
    required this.approvedMember,
    required this.activeMembers,
    required this.terminalMembers,
    required this.canJoinAnotherFamily,
  });

  factory _GroupManagementViewData.fromGroup(
    GroupInfo group, {
    String? approvedMemberDeviceId,
  }) {
    final isOwner = group.role == 'owner';
    final activeMembers = group.members
        .where((member) => member.status == 'active')
        .toList();
    final pendingMembers = group.members
        .where((member) => member.status == 'pending')
        .toList();
    GroupMember? approvedMember;
    if (isOwner && approvedMemberDeviceId != null) {
      for (final member in pendingMembers) {
        if (member.deviceId == approvedMemberDeviceId) {
          approvedMember = member;
          break;
        }
      }
    }
    return _GroupManagementViewData(
      isOwner: isOwner,
      canManageInvites:
          isOwner &&
          group.groupKey?.isNotEmpty == true &&
          group.status == GroupStatus.active,
      pendingMemberCount:
          pendingMembers.length - (approvedMember == null ? 0 : 1),
      approvedMember: approvedMember,
      activeMembers: activeMembers,
      terminalMembers: isOwner
          ? group.members
                .where(
                  (member) =>
                      member.status != 'active' && member.status != 'pending',
                )
                .toList()
          : const <GroupMember>[],
      canJoinAnotherFamily:
          isOwner &&
          group.status == GroupStatus.active &&
          group.members.length <= 1 &&
          group.members.every(
            (member) => member.role == 'owner' && member.status == 'active',
          ),
    );
  }

  final bool isOwner;
  final bool canManageInvites;
  final int pendingMemberCount;
  final GroupMember? approvedMember;
  final List<GroupMember> activeMembers;
  final List<GroupMember> terminalMembers;
  final bool canJoinAnotherFamily;

  bool get hasTransferCandidate =>
      activeMembers.any((member) => member.role == 'member');
}

class _ApprovedMemberJoining extends StatelessWidget {
  const _ApprovedMemberJoining({required this.member});

  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Container(
        key: const Key('approved-member-joining'),
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: palette.successLight,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: palette.accentPrimaryBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Icon(
                LucideIcons.circleCheck,
                size: 20,
                color: palette.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.familyFlowApprovedJoiningTitle(member.displayName),
                    style: AppTextStyles.label.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    l10n.familyFlowApprovedJoiningDescription,
                    style: AppTextStyles.supporting.copyWith(
                      color: palette.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupManagementHeader extends StatelessWidget {
  const _GroupManagementHeader({
    required this.group,
    required this.activeMembers,
    required this.isOwner,
    required this.managementSummary,
    required this.onRename,
    required this.syncState,
  });

  final GroupInfo group;
  final List<GroupMember> activeMembers;
  final bool isOwner;
  final String Function(GroupInfo group, List<GroupMember> activeMembers)
  managementSummary;
  final VoidCallback onRename;
  final SyncState syncState;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 7),
        FamilyFlowHeader(
          title: l10n.familySyncGroupManagement,
          onBack: () => Navigator.maybePop(context),
          trailing: SyncStatusBadge(state: syncState),
        ),
        const SizedBox(height: 18),
        FamilyHouseIdentity(
          name: group.groupName,
          subtitle: managementSummary(group, activeMembers),
          compact: true,
          onEdit: isOwner ? onRename : null,
          editLabel: l10n.edit,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _PendingMemberRequests extends StatelessWidget {
  const _PendingMemberRequests({
    required this.groupId,
    required this.pendingMemberCount,
  });

  final String groupId;
  final int pendingMemberCount;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MemberApprovalScreen(groupId: groupId),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.satisfactionPillBg,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: palette.joyFullnessBorder),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.userPlus, size: 19, color: palette.joyText),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.familyFlowPendingRequests(pendingMemberCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.label.copyWith(
                      color: palette.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  l10n.familyFlowViewRequests,
                  maxLines: 1,
                  style: AppTextStyles.supporting.copyWith(
                    color: palette.joyText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: palette.joyText,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ActiveMemberCard extends StatelessWidget {
  const _ActiveMemberCard({
    required this.group,
    required this.activeMembers,
    required this.isOwner,
    required this.canManageInvites,
    required this.isInviteLoading,
    required this.roleLabel,
    required this.onRemoveMember,
    required this.onInvite,
  });

  final GroupInfo group;
  final List<GroupMember> activeMembers;
  final bool isOwner;
  final bool canManageInvites;
  final bool isInviteLoading;
  final String Function(String role) roleLabel;
  final Future<void> Function(GroupMember member) onRemoveMember;
  final Future<void> Function() onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var index = 0; index < activeMembers.length; index++) ...[
            _ActiveMemberTile(
              member: activeMembers[index],
              isOwner: isOwner,
              isCurrentUser:
                  group.role == 'owner' && activeMembers[index].role == 'owner',
              roleLabel: roleLabel,
              onRemoveMember: onRemoveMember,
            ),
            if (index < activeMembers.length - 1)
              Divider(height: 1, color: palette.borderDivider),
          ],
          if (canManageInvites) ...[
            Divider(height: 1, color: palette.borderDivider),
            _OwnerInviteAction(
              isLoading: isInviteLoading,
              label: l10n.groupInviteMembers,
              onInvite: onInvite,
            ),
          ],
        ],
      ),
    );
  }
}

class _ActiveMemberTile extends StatelessWidget {
  const _ActiveMemberTile({
    required this.member,
    required this.isOwner,
    required this.isCurrentUser,
    required this.roleLabel,
    required this.onRemoveMember,
  });

  final GroupMember member;
  final bool isOwner;
  final bool isCurrentUser;
  final String Function(String role) roleLabel;
  final Future<void> Function(GroupMember member) onRemoveMember;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return MemberListTile(
      displayName: member.displayName,
      avatarEmoji: member.avatarEmoji,
      avatarImagePath: member.avatarImagePath,
      roleLabel: roleLabel(member.role),
      isOwner: member.role == 'owner',
      isCurrentUser: isCurrentUser,
      youSuffix: l10n.familySyncYouSuffix,
      onRemove: isOwner && member.role != 'owner'
          ? () => onRemoveMember(member)
          : null,
    );
  }
}

class _OwnerInviteAction extends StatelessWidget {
  const _OwnerInviteAction({
    required this.isLoading,
    required this.label,
    required this.onInvite,
  });

  final bool isLoading;
  final String label;
  final Future<void> Function() onInvite;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      key: const Key('owner-invite-action'),
      onTap: isLoading ? null : onInvite,
      child: SizedBox(
        height: 54,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (isLoading)
                SizedBox(
                  width: 17,
                  height: 17,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.accentPrimary,
                  ),
                )
              else
                Icon(LucideIcons.plus, size: 18, color: palette.accentPrimary),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: palette.accentPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ManagedInviteSection extends StatelessWidget {
  const _ManagedInviteSection({
    required this.group,
    required this.isInviteLoading,
    required this.onCopyInvite,
    required this.onShareInvite,
    required this.onRegenerateInvite,
  });

  final GroupInfo group;
  final bool isInviteLoading;
  final Future<void> Function(String inviteCode) onCopyInvite;
  final Future<void> Function({
    required String groupName,
    required String inviteCode,
  })
  onShareInvite;
  final Future<void> Function() onRegenerateInvite;

  @override
  Widget build(BuildContext context) {
    final inviteCode = group.inviteCode!;
    return Column(
      children: [
        const SizedBox(height: 10),
        _InlineInviteCard(
          inviteCode: inviteCode,
          expiresAt: group.inviteExpiresAt,
          onCopy: () => onCopyInvite(inviteCode),
          onShare: () =>
              onShareInvite(groupName: group.groupName, inviteCode: inviteCode),
          onRegenerate: isInviteLoading ? null : onRegenerateInvite,
        ),
      ],
    );
  }
}

class _MemberHistorySection extends StatelessWidget {
  const _MemberHistorySection({
    required this.members,
    required this.memberLifecycleLabel,
  });

  final List<GroupMember> members;
  final String Function(GroupMember member) memberLifecycleLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          l10n.familySyncMemberHistory,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: palette.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var index = 0; index < members.length; index++) ...[
                MemberListTile(
                  displayName: members[index].displayName,
                  avatarEmoji: members[index].avatarEmoji,
                  avatarImagePath: members[index].avatarImagePath,
                  roleLabel: memberLifecycleLabel(members[index]),
                ),
                if (index < members.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Divider(height: 1, color: palette.borderDivider),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SyncSettingsAction extends StatelessWidget {
  const _SyncSettingsAction({required this.syncState, required this.onTap});

  final SyncState syncState;
  final Future<void> Function(SyncState syncState) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return Material(
      color: palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(color: palette.borderDefault),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => onTap(syncState),
        child: SizedBox(
          height: 50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  LucideIcons.refreshCw,
                  size: 19,
                  color: palette.accentPrimary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.familyFlowSyncSettings,
                    style: AppTextStyles.label.copyWith(
                      color: palette.textPrimary,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 19,
                  color: palette.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupExitActions extends StatelessWidget {
  const _GroupExitActions({
    required this.group,
    required this.canJoinAnotherFamily,
    required this.canManageInvites,
    required this.hasTransferCandidate,
    required this.isTransferLoading,
    required this.onLeaveOrDeactivate,
    required this.onTransferOwnership,
  });

  final GroupInfo group;
  final bool canJoinAnotherFamily;
  final bool canManageInvites;
  final bool hasTransferCandidate;
  final bool isTransferLoading;
  final Future<void> Function() onLeaveOrDeactivate;
  final Future<void> Function() onTransferOwnership;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final isOwner = group.role == 'owner';
    final isOwnerReady = isOwner && group.groupKey?.isNotEmpty == true;
    return Column(
      children: [
        if (canJoinAnotherFamily) ...[
          FamilySecondaryButton(
            key: const Key('join-another-family-action'),
            label: l10n.familySyncJoinAnotherFamily,
            icon: LucideIcons.logIn,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const JoinGroupScreen()),
            ),
          ),
          const SizedBox(height: 12),
        ],
        Center(
          child: TextButton(
            onPressed: isOwner && !isOwnerReady ? null : onLeaveOrDeactivate,
            style: TextButton.styleFrom(
              foregroundColor: palette.error,
              minimumSize: const Size(44, 44),
              textStyle: AppTextStyles.label,
            ),
            child: Text(
              isOwner ? l10n.groupDisband : l10n.familySyncLeaveGroup,
            ),
          ),
        ),
        if (canManageInvites && hasTransferCandidate) ...[
          const SizedBox(height: 240),
          _TransferOwnershipAction(
            isLoading: isTransferLoading,
            onTap: onTransferOwnership,
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _TransferOwnershipAction extends StatelessWidget {
  const _TransferOwnershipAction({
    required this.isLoading,
    required this.onTap,
  });

  final bool isLoading;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    return GestureDetector(
      key: const Key('transfer-owner-action'),
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: palette.borderDefault),
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: palette.textPrimary,
                  ),
                )
              : Text(
                  l10n.familySyncTransferOwner,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
        ),
      ),
    );
  }
}

class _InlineInviteCard extends StatelessWidget {
  const _InlineInviteCard({
    required this.inviteCode,
    required this.expiresAt,
    required this.onCopy,
    required this.onShare,
    required this.onRegenerate,
  });

  final String inviteCode;
  final DateTime? expiresAt;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback? onRegenerate;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final code = inviteCode.length == 6
        ? '${inviteCode.substring(0, 3)} ${inviteCode.substring(3)}'
        : inviteCode;

    return Container(
      constraints: const BoxConstraints(minHeight: 62),
      padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: palette.borderDefault),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    code,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.numerals(
                      AppTextStyles.itemTitle.copyWith(
                        letterSpacing: 1.4,
                        color: palette.textPrimary,
                      ),
                    ),
                  ),
                ),
                if (expiresAt != null) ...[
                  const SizedBox(width: 8),
                  FamilyInviteExpiryCountdown(expiresAt: expiresAt!),
                ],
              ],
            ),
          ),
          IconButton(
            key: const Key('owner-invite-inline-copy'),
            onPressed: onCopy,
            tooltip: l10n.familySyncInviteCopy,
            icon: Icon(
              LucideIcons.copy,
              size: 19,
              color: palette.textSecondary,
            ),
          ),
          IconButton(
            key: const Key('owner-invite-inline-share'),
            onPressed: onShare,
            tooltip: l10n.familySyncShare,
            icon: Icon(
              LucideIcons.share2,
              size: 19,
              color: palette.textSecondary,
            ),
          ),
          IconButton(
            key: const Key('owner-invite-inline-refresh'),
            onPressed: onRegenerate,
            tooltip: l10n.familyFlowRegenerateInvite,
            icon: Icon(
              LucideIcons.refreshCw,
              size: 19,
              color: palette.accentPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerInviteSheet extends StatefulWidget {
  const _OwnerInviteSheet({
    required this.groupName,
    required this.initialInvite,
    required this.onRefresh,
    required this.onCopy,
    required this.onShare,
  });

  final String groupName;
  final ManageGroupInviteSuccess initialInvite;
  final Future<ManageGroupInviteResult> Function() onRefresh;
  final Future<void> Function(String inviteCode) onCopy;
  final Future<void> Function(String inviteCode) onShare;

  @override
  State<_OwnerInviteSheet> createState() => _OwnerInviteSheetState();
}

class _OwnerInviteSheetState extends State<_OwnerInviteSheet> {
  late ManageGroupInviteSuccess _invite;
  Timer? _expiryTimer;
  bool _isRefreshing = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _invite = widget.initialInvite;
    _scheduleExpiryRebuild();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }

  void _scheduleExpiryRebuild() {
    _expiryTimer?.cancel();
    final remaining = _invite.expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return;
    _expiryTimer = Timer(remaining + const Duration(milliseconds: 50), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
      _refreshError = null;
    });

    final result = await widget.onRefresh();
    if (!mounted) return;

    switch (result) {
      case ManageGroupInviteSuccess():
        setState(() {
          _invite = result;
          _isRefreshing = false;
        });
        _scheduleExpiryRebuild();
      case ManageGroupInviteForbidden():
        setState(() {
          _isRefreshing = false;
          _refreshError = S.of(context).familySyncInviteOwnerOnly;
        });
      case ManageGroupInviteError():
        setState(() {
          _isRefreshing = false;
          _refreshError = null;
        });
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _refresh,
        )) {
          return;
        }
        if (mounted) {
          setState(() {
            _refreshError = S.of(context).familySyncRegenerateInviteFailed;
          });
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final expired = !_invite.expiresAt.isAfter(DateTime.now());

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          12,
          24,
          24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.borderDefault,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.familySyncInviteTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.familySyncInviteDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: palette.textSecondary),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.borderDefault),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.groupName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SelectableText(
                      _invite.inviteCode,
                      key: const Key('owner-invite-code'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 5,
                        color: expired
                            ? palette.textTertiary
                            : palette.accentPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    FamilyInviteExpiryCountdown(
                      expiresAt: _invite.expiresAt,
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('owner-invite-copy'),
                      onPressed: expired || _isRefreshing
                          ? null
                          : () => widget.onCopy(_invite.inviteCode),
                      icon: const Icon(LucideIcons.copy, size: 16),
                      label: Text(l10n.familySyncInviteCopy),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      key: const Key('owner-invite-share'),
                      onPressed: expired || _isRefreshing
                          ? null
                          : () => widget.onShare(_invite.inviteCode),
                      icon: const Icon(LucideIcons.share2, size: 16),
                      label: Text(l10n.groupShareCode),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.familySyncInviteApprovalWindowHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: palette.textSecondary),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                key: const Key('owner-invite-refresh'),
                onPressed: _isRefreshing ? null : _refresh,
                icon: _isRefreshing
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.refreshCw, size: 15),
                label: Text(l10n.familySyncRegenerateInvite),
              ),
              Text(
                l10n.familySyncInviteRefreshHint,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: palette.textTertiary),
              ),
              if (_refreshError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _refreshError!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: palette.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
