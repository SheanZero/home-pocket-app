import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Per-card error shell.
///
/// T-Information-1: this widget never accepts or renders raw error objects.
class AnalyticsCardErrorState extends StatelessWidget {
  const AnalyticsCardErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.analyticsCardErrorHeading,
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.analyticsCardErrorBody,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.wmTextSecondary,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(l10n.analyticsCardErrorRetry),
            ),
          ],
        ),
      ),
    );
  }
}
