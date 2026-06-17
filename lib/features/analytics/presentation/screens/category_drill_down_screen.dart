import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../../shared/utils/currency_conversion.dart';
import '../../../accounting/domain/models/transaction.dart';
import '../../../list/domain/models/tagged_transaction.dart';
import '../../../list/presentation/widgets/list_transaction_tile.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/category_drill_down.dart';
import '../../domain/models/time_window.dart';
import '../providers/state_analytics.dart';
import '../providers/state_time_window.dart';

/// DRILL-01 (UI) / D-B1, D-B2, D-B3: pushed READ-ONLY category drill-down.
///
/// Entered by tapping a donut legend ROW ([CategoryDonutCard]); flat-lists all
/// EXPENSE transactions in [l1CategoryId] (including every L2 child) for the
/// active analytics window. The window comes from the keepAlive
/// `selectedTimeWindowProvider` session state (Phase 45 D-C1) — only
/// [l1CategoryId] is threaded through the route, never the window range.
///
/// Header = subtotal + count + 日均 (per-window-day average): three NEUTRAL
/// descriptive values (D-B2, ADR-012-safe). No target/goal/ranking/cross-period
/// copy. The list is READ-ONLY (D-B3): [ListTransactionTile] in `readOnly`
/// mode — no swipe-delete (no [Dismissible]) and no tap-to-edit. Mutations stay
/// on the List/entry tab.
class CategoryDrillDownScreen extends ConsumerWidget {
  const CategoryDrillDownScreen({
    super.key,
    required this.bookId,
    required this.l1CategoryId,
  });

  final String bookId;
  final String l1CategoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final palette = context.palette;
    final locale =
        ref.watch(currentLocaleProvider).value ?? const Locale('ja');

    // Window from keepAlive session state (D-C1) — never threaded via route.
    final window = ref.watch(selectedTimeWindowProvider);
    final range = window.range;

    final drillAsync = ref.watch(
      categoryDrillDownProvider(
        bookId: bookId,
        startDate: range.start,
        endDate: range.end,
        l1CategoryId: l1CategoryId,
      ),
    );

    final title = CategoryLocalizationService.resolveFromId(
      l1CategoryId,
      locale,
    );

    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: Text(title)),
      body: drillAsync.when(
        data: (drill) => _DrillBody(
          drill: drill,
          bookId: bookId,
          locale: locale,
          palette: palette,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Text(
            l10n.analyticsDrillLoadError,
            style: AppTextStyles.bodyMedium.copyWith(
              color: palette.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrillBody extends StatelessWidget {
  const _DrillBody({
    required this.drill,
    required this.bookId,
    required this.locale,
    required this.palette,
  });

  final CategoryDrillDown drill;
  final String bookId;
  final Locale locale;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DrillHeader(drill: drill, locale: locale, palette: palette),
        Expanded(
          child: drill.transactions.isEmpty
              ? Center(
                  child: Text(
                    l10n.analyticsDrillEmpty,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: palette.textSecondary,
                    ),
                  ),
                )
              : ListView.separated(
                  itemCount: drill.transactions.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, thickness: 1, color: palette.borderList),
                  itemBuilder: (context, index) => _readOnlyTile(
                    context,
                    drill.transactions[index],
                  ),
                ),
        ),
      ],
    );
  }

  /// Builds a READ-ONLY [ListTransactionTile] (D-B3): the pre-formatting mirrors
  /// `list_screen.dart`'s tile contract, but `readOnly: true` suppresses the
  /// Dismissible + tap-to-edit entirely (no-op callbacks satisfy the required
  /// params but are never wired).
  Widget _readOnlyTile(BuildContext context, Transaction transaction) {
    final ledgerType = transaction.ledgerType;

    final tagText = ledgerType == LedgerType.daily
        ? S.of(context).listLedgerDaily
        : S.of(context).listLedgerJoy;
    final tagBgColor = ledgerType == LedgerType.daily
        ? palette.dailyLight
        : palette.joyLight;
    final tagTextColor = ledgerType == LedgerType.daily
        ? palette.daily
        : palette.joy;
    final categoryColor = tagTextColor;

    final category = CategoryLocalizationService.resolveFromId(
      transaction.categoryId,
      locale,
    );

    final formattedAmount = NumberFormatter.formatCurrency(
      transaction.amount,
      'JPY',
      locale,
    );

    final originalCurrency = transaction.originalCurrency;
    final originalAmount = transaction.originalAmount;
    final String? foreignAnnotation =
        (originalCurrency != null &&
            originalCurrency.toUpperCase() != 'JPY' &&
            originalAmount != null)
        ? NumberFormatter.formatCurrency(
            originalAmount / subunitToUnitFor(originalCurrency),
            originalCurrency,
            locale,
            trimWholeFraction: true,
          )
        : null;

    final l1Icon = _resolveL1IconForCategory(transaction.categoryId);

    final satisfactionValue = transaction.ledgerType == LedgerType.joy
        ? transaction.joyFullness
        : null;

    return ListTransactionTile(
      taggedTx: TaggedTransaction(transaction: transaction),
      bookId: bookId,
      onTap: _noop,
      onDeleted: _noop,
      tagText: tagText,
      tagBgColor: tagBgColor,
      tagTextColor: tagTextColor,
      category: category,
      categoryColor: categoryColor,
      formattedAmount: formattedAmount,
      l1Icon: l1Icon,
      locale: locale,
      merchant: transaction.merchant,
      satisfactionValue: satisfactionValue,
      showDate: true,
      foreignAnnotation: foreignAnnotation,
      readOnly: true,
    );
  }

  static void _noop() {}

  /// Mirrors `list_screen.dart`'s static icon map (L1 icon from category id).
  static IconData _resolveL1IconForCategory(String categoryId) {
    const iconMap = <String, IconData>{
      'cat_food': Icons.restaurant,
      'cat_daily': Icons.local_mall,
      'cat_transport': Icons.directions_bus,
      'cat_hobbies': Icons.sports_esports,
      'cat_clothing': Icons.checkroom,
      'cat_social': Icons.people,
      'cat_health': Icons.local_hospital,
      'cat_education': Icons.school,
      'cat_utilities': Icons.flash_on,
      'cat_communication': Icons.phone_iphone,
      'cat_housing': Icons.home,
      'cat_car': Icons.directions_car,
      'cat_tax': Icons.account_balance,
      'cat_insurance': Icons.security,
      'cat_special': Icons.star,
      'cat_savings': Icons.savings,
      'cat_other': Icons.more_horiz,
    };

    if (!categoryId.startsWith('cat_')) return Icons.category;
    final withoutPrefix = categoryId.substring(4);
    final parts = withoutPrefix.split('_');
    final l1Key = 'cat_${parts.first}';
    return iconMap[l1Key] ?? Icons.category;
  }
}

/// Neutral subtotal + count + 日均 strip (D-B2). All three are plain descriptive
/// values; none is a target,達成率, ranking or cross-period delta (ADR-012-safe).
class _DrillHeader extends StatelessWidget {
  const _DrillHeader({
    required this.drill,
    required this.locale,
    required this.palette,
  });

  final CategoryDrillDown drill;
  final Locale locale;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    final subtotal = NumberFormatter.formatCurrency(
      drill.subtotal,
      'JPY',
      locale,
    );
    final avgPerDay = drill.avgPerDay;

    return Container(
      width: double.infinity,
      color: palette.card,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          _HeaderCell(
            label: l10n.analyticsDrillSubtotalLabel,
            value: subtotal,
            palette: palette,
            emphasize: true,
          ),
          _HeaderCell(
            label: l10n.analyticsDrillCountLabel,
            value: '${drill.count}',
            palette: palette,
          ),
          if (avgPerDay != null)
            _HeaderCell(
              label: l10n.analyticsDrillAvgPerDayLabel,
              value: NumberFormatter.formatCurrency(avgPerDay, 'JPY', locale),
              palette: palette,
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.value,
    required this.palette,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final AppPalette palette;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: palette.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style:
                (emphasize
                        ? AppTextStyles.amountMedium
                        : AppTextStyles.amountSmall)
                    .copyWith(color: palette.textPrimary),
          ),
        ],
      ),
    );
  }
}
