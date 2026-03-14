import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/deactivate_group_use_case.dart';
import '../../use_cases/leave_group_use_case.dart';
import '../../use_cases/remove_member_use_case.dart';
import '../../use_cases/regenerate_invite_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import 'member_approval_screen.dart';
import '../widgets/partner_device_tile.dart';
import '../widgets/sync_status_badge.dart';

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

  Future<void> _handleLeaveOrDeactivate() async {
    final group = _activeGroup;
    if (group == null) return;

    final l10n = S.of(context);
    final isOwner = group.role == 'owner';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isOwner ? l10n.familySyncDeactivateGroup : l10n.familySyncLeaveGroup,
        ),
        content: Text(
          isOwner
              ? l10n.familySyncDeactivateGroupConfirm
              : l10n.familySyncLeaveGroupConfirm,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(
              isOwner
                  ? l10n.familySyncDeactivateGroup
                  : l10n.familySyncLeaveGroup,
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = isOwner
        ? await ref.read(deactivateGroupUseCaseProvider).execute(group.groupId)
        : await ref.read(leaveGroupUseCaseProvider).execute(group.groupId);

    if (!mounted) return;

    if (result is DeactivateGroupSuccess || result is LeaveGroupSuccess) {
      ref
          .read(syncStatusNotifierProvider.notifier)
          .updateStatus(SyncStatus.unpaired);
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleRegenerateInvite() async {
    final group = _activeGroup;
    if (group == null) return;

    final result = await ref
        .read(regenerateInviteUseCaseProvider)
        .execute(group.groupId);
    if (!mounted) return;

    if (result is RegenerateInviteSuccess) {
      await _loadGroup();
      return;
    }

    if (result is RegenerateInviteError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).familySyncRegenerateInviteFailed(result.message),
          ),
        ),
      );
    }
  }

  Future<void> _handleRemoveMember(GroupMember member) async {
    final group = _activeGroup;
    if (group == null) return;
    final l10n = S.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.familySyncRemoveMember),
        content: Text(l10n.familySyncRemoveMemberConfirm(member.deviceName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.familySyncRemoveMember),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final result = await ref
        .read(removeMemberUseCaseProvider)
        .execute(groupId: group.groupId, deviceId: member.deviceId);
    if (!mounted) return;

    if (result is RemoveMemberSuccess) {
      await _loadGroup();
      return;
    }

    if (result is RemoveMemberError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            S.of(context).familySyncRemoveMemberFailed(result.message),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncStatusNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).familySyncGroupManagement),
        actions: [
          SyncStatusBadge(status: syncStatus),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _activeGroup != null
          ? _buildGroupContent()
          : _buildEmptyState(),
    );
  }

  Widget _buildGroupContent() {
    final group = _activeGroup!;
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);
    final isOwner = group.role == 'owner';
    final hasPendingMembers = group.members.any(
      (member) => member.status == 'pending',
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familySyncPairedDevice,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.familySyncMemberCount(group.members.length),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isOwner && hasPendingMembers) ...[
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              MemberApprovalScreen(groupId: group.groupId),
                        ),
                      );
                    },
                    icon: const Icon(Icons.verified_user_outlined),
                    label: Text(l10n.familySyncApprovalTitle),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familySyncPairInfo,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  l10n.familySyncPairId,
                  group.groupId.length > 8
                      ? group.groupId.substring(0, 8)
                      : group.groupId,
                ),
                _buildInfoRow(
                  l10n.familySyncPairedSince,
                  group.confirmedAt != null
                      ? DateFormatter.formatDate(group.confirmedAt!, locale)
                      : '-',
                ),
                _buildInfoRow(
                  l10n.familySyncMembers,
                  group.members.length.toString(),
                ),
              ],
            ),
          ),
        ),
        if (isOwner && group.inviteCode != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.familySyncPairCode,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.inviteCode!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _handleRegenerateInvite,
                    icon: const Icon(Icons.refresh),
                    label: Text(l10n.familySyncRegenerateInvite),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.familySyncMembers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...group.members.map(
                  (member) => PartnerDeviceTile(
                    device: member,
                    trailing: isOwner && member.role != 'owner'
                        ? TextButton(
                            onPressed: () => _handleRemoveMember(member),
                            child: Text(l10n.familySyncRemoveMember),
                          )
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: _handleLeaveOrDeactivate,
          icon: Icon(isOwner ? Icons.group_off : Icons.logout),
          label: Text(
            isOwner
                ? l10n.familySyncDeactivateGroup
                : l10n.familySyncLeaveGroup,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final l10n = S.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_2_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.familySyncNoDevicePaired,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.familySyncPairPrompt,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
