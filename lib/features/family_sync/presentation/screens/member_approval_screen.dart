import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/sync/sync_trigger_service.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../use_cases/confirm_member_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import '../widgets/info_hint_box.dart';
import '../widgets/member_list_tile.dart';

class MemberApprovalScreen extends ConsumerStatefulWidget {
  const MemberApprovalScreen({super.key, this.groupId});

  final String? groupId;

  @override
  ConsumerState<MemberApprovalScreen> createState() =>
      _MemberApprovalScreenState();
}

class _MemberApprovalScreenState extends ConsumerState<MemberApprovalScreen> {
  GroupInfo? _group;
  bool _isLoading = true;
  String? _approvingMemberId;
  StreamSubscription<SyncTriggerEvent>? _eventSubscription;

  @override
  void initState() {
    super.initState();
    _loadGroup();
    _listenForSyncEvents();
  }

  void _listenForSyncEvents() {
    final syncTrigger = ref.read(syncTriggerServiceProvider);
    _eventSubscription = syncTrigger.events.listen((event) {
      if (!mounted) return;
      if (event.type != SyncTriggerEventType.joinRequest) return;
      if (event.groupId != null &&
          widget.groupId != null &&
          event.groupId != widget.groupId) {
        return;
      }
      _loadGroup();
    });
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }

  Future<void> _loadGroup() async {
    final group = widget.groupId != null
        ? await ref.read(groupRepositoryProvider).getGroupById(widget.groupId!)
        : await ref.read(groupRepositoryProvider).getActiveGroup();
    if (!mounted) return;

    setState(() {
      _group = group;
      _isLoading = false;
    });
  }

  Future<void> _approve(GroupMember member) async {
    final group = _group;
    if (group == null) return;

    setState(() => _approvingMemberId = member.deviceId);
    final result = await ref
        .read(confirmMemberUseCaseProvider)
        .execute(
          groupId: group.groupId,
          deviceId: member.deviceId,
          bookId: group.bookId,
        );

    if (!mounted) return;

    setState(() => _approvingMemberId = null);

    if (result is ConfirmMemberSuccess) {
      await _loadGroup();
      return;
    }

    if (result is ConfirmMemberError) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final group = _group;
    final pendingMembers =
        group?.members.where((member) => member.status == 'pending').toList() ??
        const <GroupMember>[];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.familySyncApprovalTitle)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (pendingMembers.isNotEmpty)
                  ...pendingMembers.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _PendingApprovalCard(
                        member: member,
                        isApproving: _approvingMemberId == member.deviceId,
                        onApprove: () => _approve(member),
                      ),
                    ),
                  )
                else
                  Text(
                    l10n.familySyncApprovalTip,
                    style: const TextStyle(
                      fontFamily: 'IBM Plex Sans',
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                const SizedBox(height: 8),
                InfoHintBox(message: l10n.familySyncApprovalTip),
                const SizedBox(height: 24),
                Text(
                  l10n.familySyncCurrentMembers,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x145A9CC8),
                        blurRadius: 24,
                        offset: Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (
                        var index = 0;
                        index < (group?.members.length ?? 0);
                        index++
                      ) ...[
                        MemberListTile(
                          name: group!.members[index].deviceName,
                          roleLabel: _roleLabel(
                            context,
                            group.members[index].role,
                          ),
                          isOwner: group.members[index].role == 'owner',
                          ownerBadgeLabel: l10n.familySyncRoleOwner,
                        ),
                        if (index < group.members.length - 1)
                          const Divider(height: 1, color: AppColors.divider),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _roleLabel(BuildContext context, String role) {
    final l10n = S.of(context);
    return switch (role) {
      'owner' => l10n.familySyncRoleOwner,
      _ => l10n.familySyncRoleMember,
    };
  }
}

class _PendingApprovalCard extends StatelessWidget {
  const _PendingApprovalCard({
    required this.member,
    required this.isApproving,
    required this.onApprove,
  });

  final GroupMember member;
  final bool isApproving;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x145A9CC8),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.familySyncNewRequest,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          MemberListTile(
            name: member.deviceName,
            roleLabel: l10n.familySyncRoleMember,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.familySyncSecurityVerified,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isApproving ? null : onApprove,
              child: isApproving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.familySyncApprove),
            ),
          ),
        ],
      ),
    );
  }
}
