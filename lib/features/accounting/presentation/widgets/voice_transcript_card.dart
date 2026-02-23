import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/category.dart';
import '../../domain/models/voice_parse_result.dart';
import '../utils/category_display_utils.dart';

/// Card that displays the voice transcript and parsed result chips.
///
/// Shows a "認識結果" label at the top, the recognized text below it,
/// and—when [parseResult] is available—a divider followed by a row of
/// chips for amount, category, and merchant name.
class VoiceTranscriptCard extends ConsumerWidget {
  /// Whether recording is currently in progress.
  final bool isRecording;

  /// Partial (in-progress) recognized text — shown in muted color.
  final String partialText;

  /// Final recognized text — shown in primary color.
  final String finalText;

  /// Parsed result to show as chips below the transcript.
  /// Chips are only rendered when this is non-null.
  final VoiceParseResult? parseResult;

  /// Resolved category object for display (looked up from categoryId).
  final Category? category;

  /// Parent category for L2 categories (used for "Parent > Child" display).
  final Category? parentCategory;

  const VoiceTranscriptCard({
    super.key,
    required this.isRecording,
    required this.partialText,
    required this.finalText,
    this.parseResult,
    this.category,
    this.parentCategory,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final locale = ref.watch(currentLocaleProvider);
    final displayText = finalText.isNotEmpty ? finalText : partialText;
    final isFinal = finalText.isNotEmpty;

    final result = parseResult;
    final hasChips = result != null &&
        (result.amount != null ||
            result.parsedDate != null ||
            result.merchantName != null ||
            result.categoryMatch != null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            l10n.voiceRecognitionResult,
            style: AppTextStyles.labelMedium,
          ),
          const SizedBox(height: 12),
          Text(
            displayText,
            style: AppTextStyles.headlineMedium.copyWith(
              color:
                  isFinal ? AppColors.textPrimary : AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (hasChips) ...[
            const SizedBox(height: 12),
            const Divider(
              color: AppColors.divider,
              thickness: 1,
              height: 1,
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                if (result.parsedDate != null)
                  _ParseChip(
                    icon: Icons.calendar_today_outlined,
                    label: DateFormatter.formatRelative(
                      result.parsedDate!,
                      locale,
                    ),
                    isPrimary: true,
                  ),
                if (result.amount != null)
                  _ParseChip(
                    icon: Icons.payments_outlined,
                    label: NumberFormatter.formatCurrency(
                      result.amount!.toDouble(),
                      'JPY',
                      locale,
                    ),
                    isPrimary: true,
                  ),
                if (result.categoryMatch != null)
                  _ParseChip(
                    icon: category != null
                        ? resolveCategoryIcon(
                            (parentCategory ?? category)!.icon)
                        : Icons.folder_outlined,
                    label: category != null
                        ? formatCategoryPath(
                            category: category!,
                            parentCategory: parentCategory,
                            locale: locale,
                          )
                        : result.categoryMatch!.categoryId,
                    isPrimary: true,
                  ),
                if (result.merchantName != null)
                  _ParseChip(
                    icon: Icons.store_outlined,
                    label: result.merchantName!,
                    isPrimary: false,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParseChip extends StatelessWidget {
  final IconData icon;
  final String label;

  /// Primary chips (amount, category) use the survival blue palette.
  /// Secondary chips (merchant) use a neutral muted palette.
  final bool isPrimary;

  const _ParseChip({
    required this.icon,
    required this.label,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final color = isPrimary ? AppColors.survival : AppColors.textSecondary;
    final bgColor =
        isPrimary ? AppColors.survivalLight : AppColors.tabBarBackground;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
