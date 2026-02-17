import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';

/// Invite family card with a tap callback.
///
/// Pure UI component -- no providers, no navigation.
class FamilyInviteBanner extends StatelessWidget {
  const FamilyInviteBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.familyInviteBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.survivalBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.people_outline,
                  size: 20,
                  color: AppColors.survival,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.homeFamilyInviteTitle, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 2),
                  Text(l10n.homeFamilyInviteDesc, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.survival,
            ),
          ],
        ),
      ),
    );
  }
}
