import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/family_payer_palette.dart';
import '../../features/profile/presentation/widgets/avatar_display.dart';

export '../../core/theme/family_payer_palette.dart' show FamilyPayerTone;

/// Maps shadow books across the eight identity colors.
///
/// The same shadow-book order is shared by Home and List, keeping a member's
/// label stable across both surfaces. The device owner plus the first seven
/// shadow books use all eight colors once; later members cycle the same set.
FamilyPayerTone familyPayerToneForShadowIndex(int index) =>
    FamilyPayerTone.values[(index + 1) % FamilyPayerTone.values.length];

/// Compact identity-first payer label used in family transaction rows.
class FamilyPayerChip extends StatelessWidget {
  const FamilyPayerChip({super.key, required this.label, required this.tone});

  final String label;
  final FamilyPayerTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = FamilyPayerPalette.resolve(
      Theme.of(context).brightness,
      tone,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 72),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          child: Text(
            label,
            style: AppTextStyles.compact.copyWith(
              color: colors.foreground,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

/// Family transaction avatar with the category icon retained as a corner
/// badge. Shared by Home recent spending and List detail rows.
class FamilyTransactionAvatar extends StatelessWidget {
  const FamilyTransactionAvatar({
    super.key,
    required this.avatarEmoji,
    required this.avatarImagePath,
    required this.categoryIcon,
    required this.badgeColor,
    this.badgeKey,
  });

  final String avatarEmoji;
  final String? avatarImagePath;
  final IconData categoryIcon;
  final Color badgeColor;
  final Key? badgeKey;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return SizedBox(
      width: 42,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AvatarDisplay(
            emoji: avatarEmoji,
            imagePath: avatarImagePath,
            size: 40,
          ),
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              key: badgeKey,
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
                border: Border.all(color: palette.card, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Icon(categoryIcon, size: 11, color: palette.card),
            ),
          ),
        ],
      ),
    );
  }
}
