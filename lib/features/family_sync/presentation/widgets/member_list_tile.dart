import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'member_avatar.dart';
import 'status_badge.dart';

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.name,
    required this.roleLabel,
    this.isOwner = false,
    this.isCurrentUser = false,
    this.youSuffix = '',
    this.ownerBadgeLabel,
    this.removeLabel,
    this.onRemove,
  });

  final String name;
  final String roleLabel;
  final bool isOwner;
  final bool isCurrentUser;
  final String youSuffix;
  final String? ownerBadgeLabel;
  final String? removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final displayName = isCurrentUser ? '$name$youSuffix' : name;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          MemberAvatar(name: name, isOwner: isOwner),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    fontFamily: 'IBM Plex Sans',
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isOwner && isCurrentUser && ownerBadgeLabel != null)
            StatusBadge.owner(label: ownerBadgeLabel!)
          else if (onRemove != null && removeLabel != null)
            GestureDetector(
              onTap: onRemove,
              child: Text(
                removeLabel!,
                style: const TextStyle(
                  fontFamily: 'IBM Plex Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFE08870),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
