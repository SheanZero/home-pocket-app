import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/sync/sync_trigger_service.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import 'group_management_screen.dart';
import '../widgets/member_list_tile.dart';
import '../widgets/status_badge.dart';

class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen> {
  GroupInfo? _group;
  bool _isLoading = true;
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
      if (event.type != SyncTriggerEventType.memberConfirmed) return;
      if (event.groupId != null && event.groupId != widget.groupId) return;
      unawaited(_verifyGroupAndNavigate());
    });
  }

  Future<void> _verifyGroupAndNavigate() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final result = await ref.read(checkGroupUseCaseProvider).execute();
    if (!mounted) return;

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              S
                  .of(context)
                  .familySyncCheckFailed(
                    S.of(context).familySyncStatusUnpaired,
                  ),
            ),
          ),
        );
      case CheckGroupError(:final message):
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).familySyncCheckFailed(message))),
        );
    }
  }

  Future<void> _loadGroup() async {
    final group = await ref
        .read(groupRepositoryProvider)
        .getGroupById(widget.groupId);
    if (!mounted) return;

    setState(() {
      _group = group;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    unawaited(_eventSubscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.familySyncWaitingTitle),
        actions: [
          IconButton(
            onPressed: () async {
              await _loadGroup();
              if (!mounted) return;
              await _verifyGroupAndNavigate();
            },
            icon: const Icon(Icons.refresh),
            tooltip: l10n.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHero(context),
                  const SizedBox(height: 24),
                  _buildStatusCard(context),
                  if ((_group?.members.isNotEmpty ?? false)) ...[
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
                    _buildMembersCard(context),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildHero(BuildContext context) {
    final l10n = S.of(context);

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x145A9CC8),
                blurRadius: 24,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.pending_actions_outlined,
            size: 40,
            color: AppColors.survival,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          l10n.familySyncWaitingTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.familySyncWaitingDescription,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'IBM Plex Sans',
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
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
        children: [
          _InfoRow(
            label: l10n.familySyncGroupLabel,
            value: _group?.groupId ?? widget.groupId,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.familySyncStatusLabel,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              StatusBadge.pending(label: l10n.familySyncMemberStatusPending),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersCard(BuildContext context) {
    final members = _group?.members ?? const [];

    return Container(
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
          for (var index = 0; index < members.length; index++) ...[
            MemberListTile(
              name: members[index].deviceName,
              roleLabel: _roleLabel(context, members[index].role),
              isOwner: members[index].role == 'owner',
              ownerBadgeLabel: S.of(context).familySyncRoleOwner,
            ),
            if (index < members.length - 1)
              const Divider(height: 1, color: AppColors.divider),
          ],
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
