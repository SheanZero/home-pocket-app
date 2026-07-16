import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';

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
    final palette = context.palette;
    final name = isCurrentUser ? '$displayName$youSuffix' : displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AvatarDisplay(
            emoji: avatarEmoji,
            imagePath: avatarImagePath,
            size: 44,
            gradientColors: isOwner
                ? null
                : [
                    palette.memberGradientA,
                    palette.memberGradientB,
                    palette.memberGradientC,
                  ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isOwner ? FontWeight.w500 : FontWeight.w400,
                    color: isOwner
                        ? palette.accentPrimary
                        : palette.textSecondary,
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
