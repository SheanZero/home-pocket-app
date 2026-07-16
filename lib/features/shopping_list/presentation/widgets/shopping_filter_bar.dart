import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/state_shopping_filter.dart';
import 'shopping_category_filter_sheet.dart';
import 'shopping_segmented_control.dart';

/// v15 warm-Japanese shopping filter card (D-02 visual port, ADR-019).
///
/// Personal mode renders the ledger segmented control above the secondary
/// private/category filters. Family mode adds the list-scope segment first.
///
/// Data wiring is unchanged — the Material `SegmentedButton`/chip bar was
/// swapped for the `.segmented-control` pill visual, but every control still
/// reads/writes the SAME providers:
/// - scope segment  → [listTypeProvider] ('all' | 'private'), family only
///   (labelled 全部 / 個人).
/// - ledger segment → [shoppingFilterProvider].ledgerType (null | daily | joy).
/// - 私有 chip       → [shoppingFilterProvider].showPrivateOnly.
/// - カテゴリ chip    → [ShoppingCategoryFilterSheet] → setCategoryIds.
/// The reorder (並べ替え) toggle now lives in the screen's 買うもの section
/// header, matching the mockup — it is intentionally NOT rendered here.
class ShoppingFilterBar extends ConsumerWidget {
  const ShoppingFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(shoppingFilterProvider);
    final listType = ref.watch(listTypeProvider);
    final isGroupMode = ref.watch(isGroupModeProvider);
    final palette = context.palette;
    final l10n = S.of(context);

    // Ledger segment: null → 'all', otherwise 'daily' / 'joy'.
    final ledgerValue = switch (filter.ledgerType) {
      LedgerType.daily => 'daily',
      LedgerType.joy => 'joy',
      null => 'all',
    };

    final ledgerSegment = ShoppingSegmentedControl<String>(
      selected: ledgerValue,
      segments: [
        ShoppingSegment(value: 'all', label: l10n.shoppingFilterLedgerAll),
        ShoppingSegment(
          value: 'daily',
          label: l10n.listLedgerDaily,
          tone: SegmentTone.daily,
        ),
        ShoppingSegment(
          value: 'joy',
          label: l10n.listLedgerJoy,
          tone: SegmentTone.joy,
        ),
      ],
      onChanged: (value) {
        final next = switch (value) {
          'daily' => LedgerType.daily,
          'joy' => LedgerType.joy,
          _ => null,
        };
        ref.read(shoppingFilterProvider.notifier).setLedgerFilter(next);
      },
    );

    // Scope segment (family only): 全部 / 個人. The screenshot labels the
    // second option 個人 (personal) — the 私有 wording is reserved for the
    // separate row-2 私有 chip below, resolving the old double-私有 label.
    final scopeSegment = ShoppingSegmentedControl<String>(
      selected: listType,
      segments: [
        ShoppingSegment(value: 'all', label: l10n.shoppingScopeAll),
        ShoppingSegment(value: 'private', label: l10n.shoppingScopePersonal),
      ],
      onChanged: (value) =>
          ref.read(listTypeProvider.notifier).setListType(value),
    );

    return Container(
      key: const Key('shopping_filter_surface'),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.borderDefault, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isGroupMode) ...[
            SizedBox(width: double.infinity, child: scopeSegment),
            const SizedBox(height: 8),
          ],
          SizedBox(width: double.infinity, child: ledgerSegment),
          const SizedBox(height: 10),
          Row(
            children: [
              _FilterChip(
                key: const Key('shopping_filter_private_chip'),
                label: l10n.shoppingFilterPrivate,
                icon: Icons.lock_outline,
                active: filter.showPrivateOnly,
                activeBackground: palette.sharedLight,
                activeForeground: palette.sharedText,
                activeBorder: palette.shared,
                onTap: () => ref
                    .read(shoppingFilterProvider.notifier)
                    .setPrivateFilter(!filter.showPrivateOnly),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                key: const Key('shopping_filter_category_chip'),
                label: l10n.shoppingFilterCategory,
                icon: Icons.tune,
                active: filter.categoryIds.isNotEmpty,
                activeBackground: palette.dailyLight,
                activeForeground: palette.borderInputActive,
                activeBorder: palette.borderInputActive,
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => ShoppingCategoryFilterSheet(
                      initialSelected: filter.categoryIds,
                      onApply: (ids) => ref
                          .read(shoppingFilterProvider.notifier)
                          .setCategoryIds(ids),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Pill chip used for the secondary private/category filters.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.activeBackground,
    required this.activeForeground,
    required this.activeBorder,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final Color activeBackground;
  final Color activeForeground;
  final Color activeBorder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final foreground = active ? activeForeground : palette.textSecondary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? activeBackground : palette.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? activeBorder : palette.borderDefault,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: foreground,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
