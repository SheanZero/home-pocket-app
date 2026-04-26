import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/repository_providers.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final r = widget.result;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Back button only (no title)
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.chevronLeft,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.groupBack,
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Group info label
              Text(
                l10n.groupJoinTarget,
                style: const TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),

              // Group name row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('\u{1F3E0}', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    r.groupName,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Owner card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A000000),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Owner badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.crown,
                            size: 14,
                            color: AppColors.accentPrimary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.groupOwner,
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accentPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Owner avatar
                    AvatarDisplay(emoji: r.ownerAvatarEmoji, size: 80),
                    const SizedBox(height: 12),

                    // Owner name
                    Text(
                      r.ownerDisplayName,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Confirm button (CTA)
              GestureDetector(
                onTap: _isConfirming ? null : _handleConfirm,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE85A4F), Color(0xFFF08070)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x28E85A4F),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isConfirming)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      else ...[
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.groupConfirmJoin,
                          style: const TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel text link
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Text(
                  l10n.groupCancel,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
