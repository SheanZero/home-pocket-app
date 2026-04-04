import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';

const _purpleGradient = [
  Color(0xFFE8D5F5),
  Color(0xFFF3EAF9),
  Color(0xFFFAF5FD),
];

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    required this.roleLabel,
    this.isOwner = false,
    this.isCurrentUser = false,
    this.youSuffix = '',
    this.onRemove,
  });

  final String displayName;
  final String avatarEmoji;
  final String? avatarImagePath;
  final String roleLabel;
  final bool isOwner;
  final bool isCurrentUser;
  final String youSuffix;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = isCurrentUser ? '$displayName$youSuffix' : displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AvatarDisplay(
            emoji: avatarEmoji,
            imagePath: avatarImagePath,
            size: 44,
            gradientColors: isOwner ? null : _purpleGradient,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: isOwner ? FontWeight.w500 : FontWeight.w400,
                    color: isOwner
                        ? AppColors.accentPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
