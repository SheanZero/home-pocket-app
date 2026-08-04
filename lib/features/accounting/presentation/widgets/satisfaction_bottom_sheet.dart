import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import 'satisfaction_emoji_picker.dart';

enum SatisfactionPromptReason { manualSelection, categoryInference, revisit }

@immutable
class SatisfactionPromptRequest {
  const SatisfactionPromptRequest({
    required this.currentValue,
    required this.reason,
    this.categoryName,
  });

  final int currentValue;
  final SatisfactionPromptReason reason;
  final String? categoryName;
}

typedef SatisfactionPromptCallback =
    Future<int?> Function(SatisfactionPromptRequest request);

List<String> satisfactionSheetLevelLabels(S l10n) => <String>[
  l10n.satisfactionBad,
  l10n.satisfactionSheetChoiceTwo,
  l10n.satisfactionNormal,
  l10n.satisfactionSheetChoiceFour,
  l10n.satisfactionVeryGood,
];

String satisfactionSheetLabelFor(S l10n, int value) {
  final labels = satisfactionSheetLevelLabels(l10n);
  if (value <= 2) return labels[0];
  if (value <= 4) return labels[1];
  if (value <= 6) return labels[2];
  if (value <= 8) return labels[3];
  return labels[4];
}

class SatisfactionBottomSheet extends StatelessWidget {
  const SatisfactionBottomSheet({
    super.key,
    required this.request,
    required this.onSelected,
  });

  final SatisfactionPromptRequest request;
  final ValueChanged<int> onSelected;

  static Future<int?> show(
    BuildContext context, {
    required SatisfactionPromptRequest request,
  }) {
    final palette = context.palette;
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: palette.textPrimary.withValues(alpha: 0.18),
      builder: (sheetContext) => SatisfactionBottomSheet(
        request: request,
        onSelected: (value) => Navigator.of(sheetContext).pop(value),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final palette = context.palette;
    final levelLabels = satisfactionSheetLevelLabels(l10n);
    final currentLabel = satisfactionSheetLabelFor(l10n, request.currentValue);
    final categoryName = request.categoryName;
    final reason =
        request.reason == SatisfactionPromptReason.categoryInference &&
            categoryName != null &&
            categoryName.isNotEmpty
        ? l10n.satisfactionSheetCategoryReason(categoryName)
        : l10n.satisfactionSheetManualReason;

    return Material(
      key: const ValueKey('satisfaction-bottom-sheet'),
      color: palette.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: palette.borderList,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.joyLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  child: Text(
                    reason,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.supporting.copyWith(
                      color: palette.joyText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                l10n.satisfactionSheetTitle,
                textAlign: TextAlign.center,
                style: AppTextStyles.pageTitle.copyWith(
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.satisfactionSheetCurrent(currentLabel),
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              SatisfactionEmojiPicker(
                value: request.currentValue,
                onChanged: onSelected,
                title: l10n.satisfactionLevel,
                levelLabels: levelLabels,
                bottomLabels: [
                  levelLabels.first,
                  levelLabels[2],
                  levelLabels.last,
                ],
                showHeader: false,
                choiceLabels: levelLabels,
                chipSize: 64,
              ),
              const SizedBox(height: 35),
              Text(
                l10n.satisfactionSheetAutoReturn,
                textAlign: TextAlign.center,
                style: AppTextStyles.supporting.copyWith(
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                key: const ValueKey('satisfaction-keep-current'),
                onPressed: () => onSelected(request.currentValue),
                style: TextButton.styleFrom(
                  foregroundColor: palette.textSecondary,
                  minimumSize: const Size(48, 48),
                  textStyle: AppTextStyles.button,
                ),
                child: Text(l10n.satisfactionSheetKeepCurrent(currentLabel)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
