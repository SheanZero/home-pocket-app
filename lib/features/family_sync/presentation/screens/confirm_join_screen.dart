import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../shared/widgets/feedback_toast.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/repository_providers.dart';
import '../widgets/family_flow_components.dart';
import '../widgets/family_network_unavailable_dialog.dart';
import 'waiting_approval_screen.dart';

class ConfirmJoinScreen extends ConsumerStatefulWidget {
  const ConfirmJoinScreen({super.key, required this.result});

  final JoinGroupVerified result;

  @override
  ConsumerState<ConfirmJoinScreen> createState() => _ConfirmJoinScreenState();
}

class _ConfirmJoinScreenState extends ConsumerState<ConfirmJoinScreen> {
  bool _isConfirming = false;

  Future<void> _handleConfirm() async {
    setState(() => _isConfirming = true);

    final profile = await ref.read(userProfileProvider.future);
    if (!mounted) return;

    final result = await ref
        .read(confirmJoinUseCaseProvider)
        .execute(
          groupId: widget.result.groupId,
          groupName: widget.result.groupName,
          displayName: profile?.displayName ?? '',
          avatarEmoji: profile?.avatarEmoji ?? '',
        );

    if (!mounted) return;

    switch (result) {
      case ConfirmJoinSuccess():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => WaitingApprovalScreen(
              groupId: widget.result.groupId,
              groupName: widget.result.groupName,
              ownerDisplayName: widget.result.ownerDisplayName,
            ),
          ),
        );
      case ConfirmJoinError(:final message):
        setState(() => _isConfirming = false);
        if (await handleFamilyNetworkFailure(
          context,
          result,
          onRetry: _handleConfirm,
        )) {
          return;
        }
        if (!mounted) return;
        showErrorFeedback(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final result = widget.result;

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
                title: l10n.familyFlowJoinConfirmHeader,
                onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(height: 16),
              FamilyFlowProgress(
                labels: [
                  l10n.familyFlowJoinStepCode,
                  l10n.familyFlowJoinStepConfirm,
                  l10n.familyFlowJoinStepWait,
                ],
                currentStep: 1,
              ),
              const SizedBox(height: 27),
              FamilyFlowIntro(
                title: l10n.familyFlowJoinConfirmTitle,
                subtitle: l10n.familyFlowJoinConfirmSubtitle,
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: palette.borderDefault),
                ),
                child: Column(
                  children: [
                    AvatarDisplay(emoji: result.ownerAvatarEmoji, size: 72),
                    const SizedBox(height: 10),
                    Text(
                      result.groupName,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageTitle.copyWith(
                        fontSize: 21,
                        color: palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.familyFlowOwnerSummary(result.ownerDisplayName),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 11),
                    FamilyVerifiedBadge(
                      label: l10n.familyFlowPublicKeyVerified,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              FamilyPrimaryButton(
                onPressed: _isConfirming ? null : _handleConfirm,
                label: l10n.groupConfirmJoin,
                isLoading: _isConfirming,
              ),
              const SizedBox(height: 20),
              FamilyHelperNote(
                icon: LucideIcons.lockKeyhole,
                text: l10n.familyFlowPrivateLedgerHelper,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
