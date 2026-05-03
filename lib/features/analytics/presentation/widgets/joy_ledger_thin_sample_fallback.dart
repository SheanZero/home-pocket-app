import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';

/// HAPPY-06 / D-07 joint replacement for Joy trend and histogram cards.
class JoyLedgerThinSampleFallback extends StatelessWidget {
  const JoyLedgerThinSampleFallback({super.key, required this.onAddEntryTap});

  final VoidCallback onAddEntryTap;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Card(
      color: AppColors.soul.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.soul.withValues(alpha: 0.20)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsThinSampleFallbackHeading,
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.soul),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.analyticsThinSampleFallbackBody,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.wmTextSecondary,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onAddEntryTap,
              child: Text(l10n.analyticsThinSampleFallbackCta),
            ),
          ],
        ),
      ),
    );
  }
}
