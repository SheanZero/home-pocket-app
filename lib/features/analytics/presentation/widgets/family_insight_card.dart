import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../accounting/domain/models/category.dart';
import '../../../accounting/presentation/utils/category_display_utils.dart';
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
    this.sharedJoyCategory,
  });

  final FamilyHappiness? family;
  final bool isGroupMode;
  final List<Object>? shadowBooks;
  final Locale locale;
  final Category? sharedJoyCategory;

  @override
  Widget build(BuildContext context) {
    final showFamily = isGroupMode && (shadowBooks?.isNotEmpty ?? false);
    if (!showFamily) return const SizedBox.shrink();

    final l10n = S.of(context);
    final highlightsText = _highlightsText(l10n);
    return Card(
      color: context.palette.success.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: context.palette.success.withValues(alpha: 0.30),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.analyticsCardTitleFamilyInsight,
              style: AppTextStyles.itemTitle.copyWith(
                color: context.palette.success,
              ),
            ),
            const SizedBox(height: 8),
            if (highlightsText != null) ...[
              Text(
                highlightsText,
                style: AppTextStyles.body.copyWith(
                  color: context.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              _sharedJoyText(l10n),
              style: AppTextStyles.body.copyWith(
                color: context.palette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _highlightsText(S l10n) {
    return switch (family?.familyHighlightsSum) {
      null || Empty<int>() => null,
      Value<int>(:final data) => l10n.analyticsFamilyHighlightsSentence(data),
    };
  }

  String _sharedJoyText(S l10n) {
    return switch (family?.sharedJoyInsight) {
      null || Empty() => l10n.analyticsFamilyEmpty,
      Value(:final data) => l10n.analyticsFamilySharedJoySentence(
        categoryNameForDisplay(
          categoryId: data.categoryId,
          category: sharedJoyCategory,
          locale: locale,
        ),
        data.totalCount,
        data.avgSatisfaction.toStringAsFixed(1),
      ),
    };
  }
}
