import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onRemove,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                AvatarDisplay(
                  emoji: avatarEmoji,
                  imagePath: avatarImagePath,
                  size: 42,
                  gradientColors: isOwner
                      ? null
                      : [
                          palette.memberGradientA,
                          palette.memberGradientB,
                          palette.memberGradientC,
                        ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.itemTitle.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      if (isCurrentUser)
                        Text(
                          youSuffix,
                          style: AppTextStyles.itemTitle.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (isOwner)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: palette.accentPrimaryLight,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      roleLabel,
                      style: AppTextStyles.compact.copyWith(
                        color: palette.accentPrimary,
                      ),
                    ),
                  )
                else
                  Text(
                    roleLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.supporting.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                if (onRemove != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 19,
                    color: palette.textSecondary,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
