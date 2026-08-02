import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import 'home_joy_prompt.dart';

/// The selected C2 "journal notes" invitation shown before the current month
/// has any Joy-ledger transactions.
class HomeJoyEmptyState extends StatelessWidget {
  const HomeJoyEmptyState({
    required this.isGroupMode,
    required this.onPromptTap,
    super.key,
  });

  final bool isGroupMode;
  final ValueChanged<HomeJoyPrompt> onPromptTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;

    return Container(
      key: const Key('home-joy-empty-state'),
      constraints: const BoxConstraints(minHeight: 166),
      padding: const EdgeInsets.fromLTRB(15, 16, 15, 17),
      decoration: BoxDecoration(
        color: Color.lerp(palette.card, palette.joyLight, 0.18),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(21)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Transform.rotate(
                angle: -4 * math.pi / 180,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: palette.joyLight,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(14),
                      bottomLeft: Radius.circular(11),
                      bottomRight: Radius.circular(13),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: 4 * math.pi / 180,
                    child: Icon(
                      Icons.favorite_border,
                      size: 18,
                      color: palette.joyText,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isGroupMode
                          ? l10n.homeJoyEmptyTitleGroup
                          : l10n.homeJoyEmptyTitleSingle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.sectionTitle.copyWith(
                        color: palette.textPrimary,
                      ),
                    ),
                    Text(
                      l10n.homeJoyEmptySubtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.supporting.copyWith(
                        color: palette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Semantics(
                button: true,
                child: InkWell(
                  key: const Key('home-joy-empty-free'),
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onPromptTap(HomeJoyPrompt.custom),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 36),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          l10n.homeJoyEmptyFree,
                          maxLines: 1,
                          style: AppTextStyles.compact.copyWith(
                            color: palette.joyText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _JournalPrompt(
                  key: const Key('home-joy-empty-coffee'),
                  angleDegrees: -2,
                  verticalOffset: 2,
                  icon: Icons.local_cafe_outlined,
                  label: l10n.homeJoyEmptyCoffee,
                  ink: palette.joyText,
                  soft: palette.joyLight,
                  onTap: () => onPromptTap(HomeJoyPrompt.coffee),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _JournalPrompt(
                  key: const Key('home-joy-empty-book'),
                  angleDegrees: 1.5,
                  verticalOffset: -2,
                  icon: Icons.menu_book_outlined,
                  label: l10n.homeJoyEmptyBook,
                  ink: palette.accentPrimary,
                  soft: palette.accentPrimaryLight,
                  onTap: () => onPromptTap(HomeJoyPrompt.book),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _JournalPrompt(
                  key: const Key('home-joy-empty-rest'),
                  angleDegrees: -1,
                  verticalOffset: 1,
                  icon: Icons.spa_outlined,
                  label: l10n.homeJoyEmptyRest,
                  ink: palette.dailyText,
                  soft: palette.dailyLight,
                  onTap: () => onPromptTap(HomeJoyPrompt.rest),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _JournalPrompt extends StatelessWidget {
  const _JournalPrompt({
    required this.angleDegrees,
    required this.verticalOffset,
    required this.icon,
    required this.label,
    required this.ink,
    required this.soft,
    required this.onTap,
    super.key,
  });

  final double angleDegrees;
  final double verticalOffset;
  final IconData icon;
  final String label;
  final Color ink;
  final Color soft;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Transform.translate(
      offset: Offset(0, verticalOffset),
      child: Transform.rotate(
        angle: angleDegrees * math.pi / 180,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: onTap,
            child: Container(
              constraints: const BoxConstraints(minHeight: 55),
              decoration: BoxDecoration(
                color: Color.lerp(palette.card, soft, 0.09),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: Color.lerp(palette.borderDefault, ink, 0.16)!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: palette.textPrimary.withValues(alpha: 0.08),
                    blurRadius: 13,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: 5,
                    child: Transform.rotate(
                      angle: -2 * math.pi / 180,
                      child: Container(
                        width: 23,
                        height: 5,
                        decoration: BoxDecoration(
                          color: ink.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 12, 4, 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 16, color: ink),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.compact.copyWith(
                              color: ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
