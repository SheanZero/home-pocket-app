import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status_model.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../application/family_sync/deactivate_group_use_case.dart';
import '../../../../application/family_sync/leave_group_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../../shared/widgets/soft_confirm_dialog.dart';
import '../providers/repository_providers.dart';
import '../providers/state_sync.dart';
import '../widgets/group_rename_dialog.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/sync_status_badge.dart';
import 'member_approval_screen.dart';

class GroupManagementScreen extends ConsumerStatefulWidget {
  const GroupManagementScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<GroupManagementScreen> createState() =>
      _GroupManagementScreenState();
}

class _GroupManagementScreenState extends ConsumerState<GroupManagementScreen> {
  GroupInfo? _activeGroup;
  bool _isLoading = true;

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
    final group = _activeGroup;
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
        showErrorFeedback(context, l10n.groupRenameFailed);
    }
  }

  Future<void> _handleLeaveOrDeactivate() async {
    final group = _activeGroup;
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
    final group = _activeGroup;
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
      showErrorFeedback(
        context,
        l10n.familySyncRemoveMemberFailed(result.message),
      );
    }
  }

  S get l10n => S.of(context);

  @override
  Widget build(BuildContext context) {
    final syncStatusAsync = ref.watch(syncStatusStreamProvider);
    final syncState = syncStatusAsync.value?.state ?? SyncState.noGroup;

    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activeGroup != null
            ? _buildGroupContent(syncState)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildGroupContent(SyncState syncState) {
    final palette = context.palette;
    final group = _activeGroup!;
    final isOwner = group.role == 'owner';
    final hasPendingMembers = group.members.any(
      (member) => member.status == 'pending',
    );
    final activeMembers = group.members
        .where((m) => m.status != 'pending')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // Header: back button + sync badge
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.chevronLeft,
                      size: 20,
                      color: palette.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.groupBack,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              _buildSyncStatusRow(syncState),
            ],
          ),
          const SizedBox(height: 28),

          // Group name with edit icon
          GestureDetector(
            onTap: isOwner ? _handleRename : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('\u{1F3E0}', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Text(
                  group.groupName,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: palette.textPrimary,
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  Icon(
                    LucideIcons.pencil,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Pending approval alert
          if (isOwner && hasPendingMembers) ...[
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        MemberApprovalScreen(groupId: group.groupId),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: palette.accentPrimaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.accentPrimaryBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.bellRing,
                      size: 18,
                      color: palette.accentPrimary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.familySyncApprovalTitle,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: palette.accentPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 16,
                      color: palette.accentPrimary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Member section label
          Text(
            l10n.familySyncMembers,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Member card
          Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: palette.surfaceScrimMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                for (var index = 0; index < activeMembers.length; index++) ...[
                  MemberListTile(
                    displayName: activeMembers[index].displayName,
                    avatarEmoji: activeMembers[index].avatarEmoji,
                    avatarImagePath: activeMembers[index].avatarImagePath,
                    roleLabel: _roleLabel(activeMembers[index].role),
                    isOwner: activeMembers[index].role == 'owner',
                    onRemove: isOwner && activeMembers[index].role != 'owner'
                        ? () => _handleRemoveMember(activeMembers[index])
                        : null,
                  ),
                  if (index < activeMembers.length - 1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1, color: palette.borderDivider),
                    ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Action section
          if (isOwner) ...[
            // Invite new member button (outline)
            GestureDetector(
              onTap: () {
                // Navigate back to the create group / invite flow
                // This can be handled by the parent or a new route
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: palette.borderDefault),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.userPlus,
                      size: 16,
                      color: palette.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.groupInviteMembers,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Disband / leave group ghost button
          Center(
            child: GestureDetector(
              onTap: _handleLeaveOrDeactivate,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  group.role == 'owner'
                      ? l10n.groupDisband
                      : l10n.familySyncLeaveGroup,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: palette.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSyncStatusRow(SyncState syncState) {
    final palette = context.palette;
    final isBusy =
        syncState == SyncState.syncing || syncState == SyncState.initialSyncing;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SyncStatusBadge(state: syncState),
        if (!isBusy) ...[
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => ref.read(syncEngineProvider).onManualSync(),
            child: Icon(
              LucideIcons.refreshCw,
              size: 16,
              color: palette.textSecondary,
            ),
          ),
        ],
      ],
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
              fontFamily: 'Outfit',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familySyncPairPrompt,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14,
              color: palette.textSecondary,
            ),
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
}
