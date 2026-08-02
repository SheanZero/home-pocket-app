import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/family_sync/confirm_member_use_case.dart';
import '../../../../application/family_sync/join_request_lifecycle_use_cases.dart';
import '../../../../application/family_sync/notify_member_approval_use_case.dart';
import '../../../../application/family_sync/repository_providers.dart'
    show WebSocketEventType, notifyMemberApprovalUseCaseProvider;
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../../domain/models/group_info.dart';
import '../../domain/models/group_member.dart';
import '../providers/repository_providers.dart'
    show
        confirmMemberUseCaseProvider,
        groupRepositoryProvider,
        rejectJoinRequestUseCaseProvider;
import '../widgets/family_flow_components.dart';
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
    unawaited(_loadGroup());
    unawaited(_connectWebSocket());
  }

  Future<void> _connectWebSocket() async {
    final useCase = ref.read(notifyMemberApprovalUseCaseProvider);
    _notifyUseCase = useCase;

    _wsEventSubscription = useCase.listenForJoinRequests().listen((event) {
      if (!mounted) return;
      if (event.type == WebSocketEventType.joinRequest ||
          event.type == WebSocketEventType.joinRequestResolved) {
        unawaited(_loadGroup());
      }
    });

    var wsGroupId = widget.groupId;
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
        .read(rejectJoinRequestUseCaseProvider)
        .execute(groupId: group.groupId, deviceId: member.deviceId);
    if (!mounted) return;
    setState(() => _rejectingMemberId = null);

    if (result is JoinRequestLifecycleSuccess) {
      await _loadGroup();
      return;
    }
    if (result is JoinRequestLifecycleError) {
      showErrorFeedback(
        context,
        S.of(context).groupRejectRequestFailed(result.message),
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
        group?.members.where((member) => member.status == 'pending').toList() ??
        const <GroupMember>[];
    final applicant = pendingMembers.isEmpty ? null : pendingMembers.first;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: familyFlowHorizontalPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 7),
              FamilyFlowHeader(
                title: l10n.familySyncApprovalTitle,
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 16),
              FamilyFlowProgress(
                labels: [
                  l10n.familyFlowCreateStepCreate,
                  l10n.familyFlowCreateStepInvite,
                  l10n.familyFlowCreateStepApprove,
                ],
                currentStep: 2,
              ),
              const SizedBox(height: 27),
              if (applicant != null && group != null)
                _buildApplicantView(l10n, applicant)
              else
                _buildEmptyView(l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicantView(S l10n, GroupMember applicant) {
    final palette = context.palette;
    final isBusy = _approvingMemberId != null || _rejectingMemberId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FamilyFlowIntro(
          title: l10n.familyFlowApprovalTitle,
          subtitle: l10n.familyFlowApprovalSubtitle,
        ),
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.borderDefault),
          ),
          child: Column(
            children: [
              AvatarDisplay(
                emoji: applicant.avatarEmoji,
                imagePath: applicant.avatarImagePath,
                size: 80,
                gradientColors: [
                  palette.memberGradientA,
                  palette.memberGradientB,
                  palette.memberGradientC,
                ],
              ),
              const SizedBox(height: 12),
              Text(
                applicant.displayName,
                style: AppTextStyles.pageTitle.copyWith(
                  fontSize: 21,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.familyFlowApprovalDevice(applicant.deviceName),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              if (applicant.joinedAt != null) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.familySyncRequestedAt(
                    MaterialLocalizations.of(
                      context,
                    ).formatShortDate(applicant.joinedAt!.toLocal()),
                  ),
                  style: AppTextStyles.supporting.copyWith(
                    color: palette.textTertiary,
                  ),
                ),
              ],
              const SizedBox(height: 11),
              FamilyVerifiedBadge(label: l10n.familyFlowDeviceKeyVerified),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              flex: 100,
              child: FamilySecondaryButton(
                onPressed: isBusy ? null : () => _reject(applicant),
                label: l10n.groupReject,
                isLoading: _rejectingMemberId == applicant.deviceId,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 135,
              child: FamilyPrimaryButton(
                onPressed: isBusy ? null : () => _approve(applicant),
                label: l10n.groupApprove,
                isLoading: _approvingMemberId == applicant.deviceId,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        FamilyHelperNote(
          icon: LucideIcons.lockKeyhole,
          text: l10n.familyFlowApprovalHelper,
        ),
      ],
    );
  }

  Widget _buildEmptyView(S l10n) {
    final palette = context.palette;
    return Column(
      children: [
        const SizedBox(height: 100),
        Icon(LucideIcons.circleCheck, size: 52, color: palette.accentPrimary),
        const SizedBox(height: 18),
        Text(
          l10n.familyFlowApprovalEmptyTitle,
          textAlign: TextAlign.center,
          style: AppTextStyles.pageTitle.copyWith(color: palette.textPrimary),
        ),
        const SizedBox(height: 7),
        Text(
          l10n.familySyncApprovalTip,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(color: palette.textSecondary),
        ),
      ],
    );
  }
}
