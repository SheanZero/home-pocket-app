import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'member_avatar.dart';

/// Bar displaying a family/group name, overlapping member avatars,
/// and a navigation chevron. Only visible in group/family mode.
class GroupBar extends StatelessWidget {
  const GroupBar({
    super.key,
    required this.familyName,
    required this.members,
    this.onTap,
  });

  /// Display name of the family group (e.g. "田中家").
  final String familyName;

  /// List of member records, each with an [initial] character and [color].
  final List<({String initial, Color color})> members;

  /// Called when the bar is tapped. Typically navigates to group settings.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildLeft(),
            _buildAvatarStack(),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeft() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.people,
          size: 18,
          color: AppColors.accentPrimary,
        ),
        const SizedBox(width: 10),
        Text(familyName, style: AppTextStyles.titleSmall),
      ],
    );
  }

  Widget _buildAvatarStack() {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }

    // Each MemberAvatar is 28px (24 inner + 2px stroke each side).
    // Avatars overlap by 6px, so each subsequent avatar is offset by 22px.
    const double avatarSize = 28;
    const double overlap = 6;
    const double stride = avatarSize - overlap; // 22

    final stackWidth = members.length * stride + overlap;

    return SizedBox(
      width: stackWidth,
      height: avatarSize,
      child: Stack(
        children: [
          for (final (i, m) in members.indexed)
            Positioned(
              left: i * stride,
              child: MemberAvatar(initial: m.initial, color: m.color),
            ),
        ],
      ),
    );
  }
}
