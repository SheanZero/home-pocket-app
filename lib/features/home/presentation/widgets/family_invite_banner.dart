import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// Vertical invite card with overlapping avatar circles and coral CTA button.
///
/// Shown in solo mode when the user hasn't joined a family group yet.
/// Pure UI component -- no providers, no navigation.
class FamilyInviteBanner extends StatelessWidget {
  const FamilyInviteBanner({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
                  child: _avatarCircle(
                    context,
                    AppColors.olive,
                    Icons.face_2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Title
          Text(
            '\u5BB6\u65CF\u3068\u4E00\u7DD2\u306B\u7BA1\u7406\u3057\u3088\u3046',
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
            '\u30D1\u30FC\u30C8\u30CA\u30FC\u3092\u62DB\u5F85\u3057\u3066\n\u5BB6\u8A08\u7C3F\u3092\u30EA\u30A2\u30EB\u30BF\u30A4\u30E0\u3067\u5171\u6709',
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
                    '\u5BB6\u65CF\u3092\u62DB\u5F85\u3059\u308B',
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
