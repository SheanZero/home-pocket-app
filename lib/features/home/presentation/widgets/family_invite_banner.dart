import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Vertical invite card with overlapping avatar circles and coral CTA button.
///
/// Shown in solo mode when the user hasn't joined a family group yet.
/// Pure UI component -- no providers, no navigation.
class FamilyInviteBanner extends StatelessWidget {
  const FamilyInviteBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.wmCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.wmBorderDefault),
      ),
      child: Column(
        children: [
          // Overlapping avatar circles (2 circles, -10px overlap)
          SizedBox(
            width: 82, // 46 + 46 - 10
            height: 46,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: _avatarCircle(
                    context,
                    AppColors.accentPrimary,
                    Icons.face,
                  ),
                ),
                Positioned(
                  left: 36, // 46 - 10
                  child: _avatarCircle(context, AppColors.olive, Icons.face_2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            l10n.homeFamilyBannerTitle,
            style: AppTextStyles.titleMedium.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.wmTextPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          // Subtitle
          Text(
            l10n.homeFamilyBannerSubtitle,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.wmTextSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          // CTA button with heart icon
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    l10n.homeFamilyInviteTitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCircle(BuildContext context, Color bgColor, IconData icon) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(color: context.wmCard, width: 2.5),
      ),
      child: Icon(icon, size: 24, color: Colors.white),
    );
  }
}
