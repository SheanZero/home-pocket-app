import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';


class GroupChoiceScreen extends ConsumerWidget {
  const GroupChoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _Header(title: l10n.familySync),
              const SizedBox(height: 40),
              const _HeroAvatars(),
              const SizedBox(height: 24),
              Text(
                l10n.groupChoiceTitle,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.groupChoiceSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              _ActionCard(
                icon: LucideIcons.plusCircle,
                iconBackgroundColor: palette.accentPrimaryLight,
                iconColor: palette.accentPrimary,
                title: l10n.groupCreate,
                description: l10n.groupCreateDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _ActionCard(
                icon: LucideIcons.logIn,
                iconBackgroundColor: palette.dailyLight,
                iconColor: palette.daily,
                title: l10n.familySyncEnterPartnerCode,
                description: l10n.groupJoinDesc,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const JoinGroupScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _E2eeHint(text: l10n.groupE2eeHint),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Row(
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
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: palette.textPrimary,
          ),
        ),
        const Spacer(),
        // Invisible spacer to balance the back button
        const SizedBox(width: 60),
      ],
    );
  }
}

class _HeroAvatars extends StatelessWidget {
  const _HeroAvatars();

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 140,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            left: 0,
            child: _BorderedAvatar(emoji: '\u{1F431}', size: 56),
          ),
          Positioned(
            child: _BorderedAvatar(
              emoji: '\u{1F338}',
              size: 56,
              gradientColors: [
                palette.memberGradientA,
                palette.memberGradientB,
                palette.memberGradientC,
              ],
            ),
          ),
          Positioned(
            right: 0,
            child: _BorderedAvatar(
              emoji: '\u{1F43B}',
              size: 56,
              gradientColors: [palette.successLight, palette.card],
            ),
          ),
        ],
      ),
    );
  }
}

class _BorderedAvatar extends StatelessWidget {
  const _BorderedAvatar({
    required this.emoji,
    required this.size,
    this.gradientColors,
  });

  final String emoji;
  final double size;
  final List<Color>? gradientColors;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2.5),
      ),
      child: AvatarDisplay(
        emoji: emoji,
        size: size,
        gradientColors: gradientColors,
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.iconBackgroundColor,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBackgroundColor;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.borderDefault),
          boxShadow: [
            BoxShadow(
              color: palette.surfaceScrimMedium,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: palette.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _E2eeHint extends StatelessWidget {
  const _E2eeHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          LucideIcons.shield,
          size: 14,
          color: palette.textSecondary.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: palette.textSecondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
