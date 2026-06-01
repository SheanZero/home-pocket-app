import 'package:flutter/material.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/models/family_happiness.dart';
import '../../domain/models/metric_result.dart';

/// STATSUI-02 family aggregate card for the stories group.
class FamilyInsightCard extends StatelessWidget {
  const FamilyInsightCard({
    super.key,
    required this.family,
    required this.isGroupMode,
    required this.shadowBooks,
    required this.locale,
  });

  final FamilyHappiness? family;
  final bool isGroupMode;
  final List<Object>? shadowBooks;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final showFamily = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
    if (!showFamily) return const SizedBox.shrink();

    final l10n = S.of(context);
    return Card(
      color: context.palette.success.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: context.palette.success.withValues(alpha: 0.30)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsCardTitleFamilyInsight,
              style: AppTextStyles.titleLarge.copyWith(color: context.palette.success),
            ),
            const SizedBox(height: 8),
            Text(
              _highlightsText(l10n),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _sharedJoyText(l10n),
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _highlightsText(S l10n) {
    return switch (family?.familyHighlightsSum) {
      null || Empty<int>() => l10n.analyticsFamilyEmpty,
      Value<int>(:final data) => l10n.analyticsFamilyHighlightsSentence(data),
    };
  }

  String _sharedJoyText(S l10n) {
    return switch (family?.sharedJoyInsight) {
      null || Empty() => l10n.analyticsFamilyEmpty,
      Value(:final data) => l10n.analyticsFamilySharedJoySentence(
        CategoryLocalizationService.resolveFromId(data.categoryId, locale),
        data.totalCount,
        data.avgSatisfaction.toStringAsFixed(1),
      ),
    };
  }
}
