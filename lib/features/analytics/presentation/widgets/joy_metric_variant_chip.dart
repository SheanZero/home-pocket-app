import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_joy_metric_variant.dart';

/// AppBar action chip for the AnalyticsScreen Joy metric variant.
class JoyMetricVariantChip extends ConsumerWidget {
  const JoyMetricVariantChip({super.key, required this.locale});

  final Locale locale;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final variant = ref.watch(selectedJoyMetricVariantProvider);
    final label = _labelFor(variant, l10n);

    return Tooltip(
      message: l10n.analyticsJoyMetricVariantSheetTitle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => _showSheet(context, ref, l10n),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.wmCard,
                border: Border.all(color: context.wmBorderDefault),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.wmTextPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '▼',
                      style: AppTextStyles.caption.copyWith(
                        color: context.wmTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _labelFor(JoyMetricVariant variant, S l10n) {
    return switch (variant) {
      JoyMetricVariant.all => l10n.analyticsJoyMetricVariantOptionAll,
      JoyMetricVariant.manualOnly =>
        l10n.analyticsJoyMetricVariantOptionManualOnly,
    };
  }

  static Future<void> _showSheet(BuildContext context, WidgetRef ref, S l10n) {
    final selected = ref.read(selectedJoyMetricVariantProvider);

    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.analyticsJoyMetricVariantSheetTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.wmTextPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _VariantOptionTile(
                  selected: selected == JoyMetricVariant.all,
                  title: l10n.analyticsJoyMetricVariantOptionAll,
                  onTap: () {
                    // dart format off
                    ref.read(selectedJoyMetricVariantProvider.notifier).setVariant(JoyMetricVariant.all);
                    // dart format on
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _VariantOptionTile(
                  selected: selected == JoyMetricVariant.manualOnly,
                  title: l10n.analyticsJoyMetricVariantOptionManualOnly,
                  subtitle: l10n.analyticsJoyMetricVariantManualOnlyExplain,
                  onTap: () {
                    // dart format off
                    ref.read(selectedJoyMetricVariantProvider.notifier).setVariant(JoyMetricVariant.manualOnly);
                    // dart format on
                    Navigator.of(sheetContext).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VariantOptionTile extends StatelessWidget {
  const _VariantOptionTile({
    required this.selected,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final bool selected;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selected: selected,
      selectedColor: AppColors.accentPrimary,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: selected ? AppColors.accentPrimary : context.wmTextPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: AppTextStyles.caption.copyWith(
                color: context.wmTextSecondary,
              ),
            ),
      onTap: onTap,
    );
  }
}
