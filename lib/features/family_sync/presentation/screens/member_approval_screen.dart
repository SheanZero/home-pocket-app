import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/family_sync/confirm_member_use_case.dart';
import '../../../../application/family_sync/notify_member_approval_use_case.dart';
import '../../../../application/family_sync/remove_member_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    show WebSocketEventType, notifyMemberApprovalUseCaseProvider;
import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/repository_providers.dart'
    show
        groupRepositoryProvider,
        confirmMemberUseCaseProvider,
        removeMemberUseCaseProvider;
import 'group_management_screen.dart';

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
  String? _rejectingMemberId;
  StreamSubscription<dynamic>? _wsEventSubscription;
  NotifyMemberApprovalUseCase? _notifyUseCase;

  @override
  void initState() {
    super.initState();
    _loadGroup();
    _connectWebSocket();
  }

  Future<void> _connectWebSocket() async {
    final useCase = ref.read(notifyMemberApprovalUseCaseProvider);
    _notifyUseCase = useCase;

    // Listen for join_request events to refresh the pending list
    _wsEventSubscription = useCase.listenForJoinRequests().listen((event) {
      if (!mounted) return;
      if (event.type == WebSocketEventType.joinRequest) {
        _loadGroup(); // Reload to pick up new pending member
      }
    });

    // Determine groupId for WebSocket connection
    String? wsGroupId = widget.groupId;
    if (wsGroupId == null) {
      final group = await ref.read(groupRepositoryProvider).getActiveGroup();
      wsGroupId = group?.groupId;
    }
    if (!mounted || wsGroupId == null) return;

    await useCase.connectWebSocket(groupId: wsGroupId);
  }

  @override
  void dispose() {
    unawaited(_wsEventSubscription?.cancel());
    _notifyUseCase?.disconnectWebSocket();
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
        .execute(groupId: group.groupId, deviceId: member.deviceId);

    if (!mounted) return;

    setState(() => _approvingMemberId = null);

    if (result is ConfirmMemberSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupManagementScreen(groupId: group.groupId),
        ),
      );
      return;
    }

    if (result is ConfirmMemberError) {
      showErrorFeedback(context, result.message);
    }
  }

  Future<void> _reject(GroupMember member) async {
    final group = _group;
    if (group == null) return;

    setState(() => _rejectingMemberId = member.deviceId);
    final result = await ref
        .read(removeMemberUseCaseProvider)
        .execute(groupId: group.groupId, deviceId: member.deviceId);

    if (!mounted) return;

    setState(() => _rejectingMemberId = null);

    if (result is RemoveMemberSuccess) {
      Navigator.of(context).pop();
      return;
    }

    if (result is RemoveMemberError) {
      showErrorFeedback(
        context,
        S.of(context).familySyncRemoveMemberFailed(result.message),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: palette.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final group = _group;
    final pendingMembers =
        group?.members.where((m) => m.status == 'pending').toList() ??
        const <GroupMember>[];

    // Show the first pending member in the new centered design
    final applicant = pendingMembers.isNotEmpty ? pendingMembers.first : null;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: applicant != null
                ? _buildApplicantView(l10n, applicant, group!)
                : _buildEmptyView(l10n),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicantView(S l10n, GroupMember applicant, GroupInfo group) {
    final palette = context.palette;
    final isBusy = _approvingMemberId != null || _rejectingMemberId != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bell icon
        Icon(LucideIcons.bellRing, size: 32, color: palette.accentPrimary),
        const SizedBox(height: 16),

        // Title
        Text(
          l10n.groupJoinRequest,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: palette.textPrimary,
          ),
        ),
        const SizedBox(height: 24),

        // Applicant card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: palette.surfaceScrimLight,
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              AvatarDisplay(
                emoji: applicant.avatarEmoji,
                size: 80,
                gradientColors: [
                  palette.memberGradientA,
                  palette.memberGradientB,
                  palette.memberGradientC,
                ],
              ),
              const SizedBox(height: 14),
              Text(
                applicant.displayName,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.groupJoinRequestDesc(applicant.displayName),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              // Group name tag
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('\u{1F3E0}', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                    Text(
                      group.groupName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: palette.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Button row: Reject + Approve
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isBusy ? null : () => _reject(applicant),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.borderDefault),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_rejectingMemberId == applicant.deviceId)
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: palette.textSecondary,
                          ),
                        )
                      else ...[
                        Icon(
                          LucideIcons.x,
                          size: 16,
                          color: palette.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.groupReject,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: isBusy ? null : () => _approve(applicant),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        palette.fabGradientEnd,
                        palette.fabGradientStart,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.actionShadow,
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_approvingMemberId == applicant.deviceId)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        const Icon(
                          LucideIcons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.groupApprove,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyView(S l10n) {
    final palette = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.bellRing, size: 32, color: palette.textTertiary),
        const SizedBox(height: 16),
        Text(
          l10n.familySyncApprovalTip,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: palette.textSecondary),
        ),
      ],
    );
  }
}
