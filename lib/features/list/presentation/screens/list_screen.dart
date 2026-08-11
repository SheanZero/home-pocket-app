import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show categoryByIdProvider;
import '../../../../generated/app_localizations.dart';
import '../../../../features/accounting/presentation/screens/transaction_edit_screen.dart';
import '../../../../features/accounting/presentation/utils/category_display_utils.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/family_sync/presentation/navigation/family_flow_launcher.dart';
import '../../../../features/family_sync/presentation/widgets/family_mode_badge.dart';
import '../../../../features/home/presentation/widgets/month_picker_dialog.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../../../features/profile/domain/models/user_profile.dart';
import '../../../../features/profile/presentation/providers/state_user_profile.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../features/settings/presentation/screens/settings_screen.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../../../shared/constants/sort_config.dart';
import '../../../../shared/utils/invalidate_transaction_dependents.dart';
import '../../../../shared/utils/transaction_display_amounts.dart';
import '../../../../shared/widgets/family_transaction_attribution.dart';
import '../../../../shared/widgets/main_surface_header.dart';
import '../../domain/models/list_filter_state.dart';
import '../../domain/models/tagged_transaction.dart';
import '../providers/state_calendar_totals.dart';
import '../providers/state_list_filter.dart';
import '../providers/state_list_transactions.dart';
import '../widgets/list_calendar_header.dart';
import '../widgets/list_day_group_header.dart';
import '../widgets/list_empty_state.dart';
import '../widgets/list_ledger_segments.dart';
import '../widgets/list_sort_filter_bar.dart';
import '../widgets/list_transaction_tile.dart';

/// List screen for Phase 28 — grouped-by-day transaction list with pinned sort/filter bar.
///
/// Replaces the Phase 27 CircularProgressIndicator placeholder with:
/// - [ListSortFilterBar]: pinned 44dp chip bar
/// - Grouped-by-day [ListView.builder] via [buildFlatList]
class ListScreen extends ConsumerWidget {
  const ListScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod 3: .value is the nullable accessor (not .valueOrNull, which was removed)
    final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
    // Phase 29: resolve currencyCode from bookByIdProvider
    const currencyCode = 'JPY';
    final filter = ref.watch(listFilterProvider);
    final isGroupMode = ref.watch(isGroupModeProvider);

    // Opens the shared month-grid picker (same widget the home header uses) and
    // applies the choice to the list's selected-month state. Future months are
    // disabled by the picker itself (quick 260714-qit — STRICT mockup header:
    // no prev/next chevrons).
    Future<void> openMonthPicker() async {
      final picked = await showMonthPickerDialog(
        context,
        selectedYear: filter.selectedYear,
        selectedMonth: filter.selectedMonth,
      );
      if (picked == null || !context.mounted) return;
      ref
          .read(listFilterProvider.notifier)
          .selectMonth(picked.year, picked.month);
    }

    final l10n = S.of(context);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: MainSurfaceHeader.screenPadding,
              child: MainSurfaceHeader(
                key: const Key('list-v15-header'),
                title: DateFormatter.formatMonthYear(
                  DateTime(filter.selectedYear, filter.selectedMonth),
                  locale,
                ),
                titleKey: const Key('list-month-title'),
                titleColor: context.palette.info,
                onTitleTap: openMonthPicker,
                titleTooltip: l10n.listMonthPickerLabel,
                trailing: FamilyModeBadge(
                  key: const Key('list-mode-badge'),
                  isGroupMode: isGroupMode,
                  onTap: () => openAuthoritativeFamilyFlow(context, ref),
                ),
                actions: [
                  MainSurfaceHeaderAction(
                    key: const Key('list-month-picker-button'),
                    icon: Icons.calendar_month_outlined,
                    tooltip: l10n.listMonthPickerLabel,
                    onPressed: openMonthPicker,
                  ),
                  MainSurfaceHeaderAction(
                    key: const Key('list-settings-button'),
                    icon: Icons.settings_outlined,
                    tooltip: l10n.settings,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => SettingsScreen(bookId: bookId),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: MainSurfaceHeader.contentSpacing),
            // v15 order: ledger segments → calendar → filter bar → list.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: ListLedgerSegments(),
            ),
            CalendarHeaderWidget(
              bookId: bookId,
              currencyCode: currencyCode,
              locale: locale,
            ),
            ListSortFilterBar(bookId: bookId),
            Expanded(child: _buildList(context, ref, filter, locale)),
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    ListFilterState filter,
    Locale locale,
  ) {
    final palette = context.palette;
    final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
    return RefreshIndicator(
      color: palette.accentPrimary,
      onRefresh: () async {
        // Refresh re-fetches data → invalidate the SQL base (P2-1); the search
        // layer [listTransactionsProvider] cascades because it watches the base.
        ref.invalidate(listTransactionsBaseProvider(bookId: bookId));
        ref.invalidate(
          calendarDailyTotalsProvider(
            bookId: bookId,
            year: filter.selectedYear,
            month: filter.selectedMonth,
          ),
        );
        ref.invalidate(
          calendarFamilyLedgerTotalsProvider(
            bookId: bookId,
            year: filter.selectedYear,
            month: filter.selectedMonth,
          ),
        );
        // Await re-settlement so spinner dismisses honestly (Pitfall F)
        await ref
            .read(listTransactionsProvider(bookId: bookId).future)
            .catchError((_) => <TaggedTransaction>[]);
      },
      child: txsAsync.when(
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: CircularProgressIndicator(
              color: palette.accentPrimary,
              strokeWidth: 2,
            ),
          ),
        ),
        error: (err, st) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 40,
                  color: palette.textTertiary,
                ),
                const SizedBox(height: 8),
                Text(
                  S.of(context).listLoadError,
                  style: AppTextStyles.caption.copyWith(
                    color: palette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
        data: (txs) {
          // D-05: "other" filters = non-day filters; anyOtherFilter takes priority over day filter
          final anyOtherFilter =
              filter.ledgerType != null ||
              filter.categoryIds.isNotEmpty ||
              filter.searchQuery.isNotEmpty ||
              filter.memberBookId != null;

          final variant = anyOtherFilter
              ? ListEmptyVariant.filtered
              : (filter.activeDayFilter != null
                    ? ListEmptyVariant.dayEmpty
                    : ListEmptyVariant.noData);

          if (txs.isEmpty) {
            // Wrap in scrollable so pull-to-refresh gesture fires when empty (Pitfall E)
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              // Breathing room below the sort/filter bar when there are no records.
              padding: const EdgeInsets.only(top: 80),
              child: ListEmptyState(variant: variant),
            );
          }

          // D-01 flat mode: amount sort renders a globally-sorted flat list with
          // no day-group headers, inside a single v15 `.list-transactions` card.
          // The transactions are already sorted by the provider; skip
          // buildFlatList entirely.
          if (filter.sortConfig.sortField == SortField.amount) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              children: [
                _transactionCard(
                  context,
                  ref,
                  txs,
                  filter,
                  locale,
                  showDate: true,
                ),
              ],
            );
          }

          // Default: timestamp sort — grouped-by-day; each day is a day-header
          // followed by a `.list-transactions` card (v15 layout).
          final items = buildFlatList(txs, filter.sortConfig.sortDirection);
          final children = <Widget>[];
          var currentRows = <TaggedTransaction>[];
          DateTime? currentDate;

          void flushGroup() {
            if (currentDate != null && currentRows.isNotEmpty) {
              children.add(
                ListDayGroupHeader(date: currentDate, locale: locale),
              );
              children.add(
                _transactionCard(context, ref, currentRows, filter, locale),
              );
              children.add(
                const SizedBox(key: Key('list-day-group-gap'), height: 10),
              );
            }
            currentRows = <TaggedTransaction>[];
          }

          for (final item in items) {
            switch (item) {
              case DayHeaderItem():
                flushGroup();
                currentDate = item.date;
              case TransactionRowItem():
                currentRows.add(item.tx);
            }
          }
          flushGroup();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            // Clear the floating bottom navigation bar so the last row is not
            // obscured.
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: children,
          );
        },
      ),
    );
  }

  /// Builds a single v15 `.list-transactions` card wrapping [rows] with
  /// interior 1dp dividers between consecutive rows (no divider after the last).
  Widget _transactionCard(
    BuildContext context,
    WidgetRef ref,
    List<TaggedTransaction> rows,
    ListFilterState filter,
    Locale locale, {
    bool showDate = false,
  }) {
    final palette = context.palette;
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      children.add(
        _buildTile(context, ref, rows[i], filter, locale, showDate: showDate),
      );
      if (i < rows.length - 1) {
        children.add(
          Divider(height: 1, thickness: 1, color: palette.borderList),
        );
      }
    }
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.borderDefault, width: 1),
        // v15 `.list-transactions`: very-light warm card shadow (0 4px 14px).
        boxShadow: [
          BoxShadow(
            color: palette.navShadow,
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }

  Widget _buildTile(
    BuildContext context,
    WidgetRef ref,
    TaggedTransaction tx,
    ListFilterState filter,
    Locale locale, {
    bool showDate = false,
  }) {
    final palette = context.palette;
    final transaction = tx.transaction;
    final ledgerType = transaction.ledgerType;

    // Ledger tag colors resolved via palette (COLOR-02 / D-07 dark-mode support).
    // v15 `.list-transaction-tag`/`-icon` use the darker *Text variants for AA
    // contrast on the soft tag background.
    final tagText = ledgerType == LedgerType.daily
        ? S.of(context).listLedgerDaily
        : S.of(context).listLedgerJoy;
    final tagBgColor = ledgerType == LedgerType.daily
        ? palette.dailyLight
        : palette.joyLight;
    final tagTextColor = ledgerType == LedgerType.daily
        ? palette.dailyText
        : palette.joyText;
    // Leading category icon uses the same ledger-text colour as the tag (v15).
    final categoryColor = tagTextColor;

    final defaultCategory = defaultCategoryFromId(transaction.categoryId);
    final customCategoryAsync = defaultCategory == null
        ? ref.watch(categoryByIdProvider(transaction.categoryId))
        : null;
    final displayCategory = defaultCategory ?? customCategoryAsync?.value;

    // Locale-resolved category name. Custom categories come from encrypted
    // local storage; an ellipsis is shown during the short lookup rather than
    // leaking the opaque storage ID into the row.
    final category = categoryNameForDisplay(
      categoryId: transaction.categoryId,
      category: displayCategory,
      locale: locale,
      isLoading: customCategoryAsync?.isLoading ?? false,
    );

    final displayAmounts = formatTransactionDisplayAmounts(
      amountMinorUnits: transaction.amount,
      amountCurrencyCode: 'JPY',
      originalCurrencyCode: transaction.originalCurrency,
      originalAmountMinorUnits: transaction.originalAmount,
      locale: locale,
    );

    final l1Icon = displayCategory == null
        ? Icons.category
        : parentCategoryIconForCategory(displayCategory);

    // Satisfaction face: joy transactions only (ADR-014 mapping)
    final satisfactionValue = transaction.ledgerType == LedgerType.joy
        ? transaction.joyFullness
        : null;

    final isGroupMode = ref.watch(isGroupModeProvider);
    final familyPayer = isGroupMode
        ? _resolveFamilyPayer(
            tx,
            profile: ref.watch(userProfileProvider).value,
            shadows: ref.watch(shadowBooksProvider).value ?? const [],
            selfLabel: S.of(context).familyTransactionPayerSelf,
            memberFallbackLabel: S.of(context).analyticsDonutMemberFilterLabel,
          )
        : null;

    // 260603-nr1 #5: refresh every transaction-dependent provider after an
    // edit-save or swipe-delete — list + calendar (keyed) AND the Home today
    // summary + Analytics reports (whole families). Previously only list +
    // calendar were invalidated, leaving Home/Analytics stale in solo mode.
    void invalidateAfterMutation() {
      invalidateTransactionDependents(
        ref,
        bookId: bookId,
        year: filter.selectedYear,
        month: filter.selectedMonth,
      );
    }

    // Tap handler: push TransactionEditScreen; on save (result == true), refresh.
    Future<void> onTap() async {
      try {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (ctx) => TransactionEditScreen(transaction: transaction),
          ),
        );
        if (result == true) {
          invalidateAfterMutation();
        }
      } catch (e, st) {
        // Surface rather than silently dropping the unhandled Future (WR-03).
        FlutterError.reportError(
          FlutterErrorDetails(exception: e, stack: st, library: 'list_screen'),
        );
      }
    }

    final tile = ListTransactionTile(
      taggedTx: tx,
      bookId: bookId,
      onTap: onTap,
      onDeleted: invalidateAfterMutation,
      tagText: tagText,
      tagBgColor: tagBgColor,
      tagTextColor: tagTextColor,
      category: category,
      categoryColor: categoryColor,
      formattedAmount: displayAmounts.primaryAmount,
      l1Icon: l1Icon,
      locale: locale,
      merchant: transaction.merchant,
      satisfactionValue: satisfactionValue,
      showDate: showDate,
      foreignAnnotation: displayAmounts.foreignAnnotation,
      familyPayerLabel: familyPayer?.label,
      familyPayerTone: familyPayer?.tone ?? FamilyPayerTone.self,
      familyPayerAvatarEmoji: familyPayer?.avatarEmoji,
      familyPayerAvatarImagePath: familyPayer?.avatarImagePath,
    );

    // Dividers between rows are owned by [_transactionCard]; the tile renders
    // bare.
    return tile;
  }

  _ListFamilyPayer _resolveFamilyPayer(
    TaggedTransaction tagged, {
    required UserProfile? profile,
    required List<ShadowBookInfo> shadows,
    required String selfLabel,
    required String memberFallbackLabel,
  }) {
    if (tagged.transaction.bookId == bookId) {
      return _ListFamilyPayer(
        label: selfLabel,
        tone: FamilyPayerTone.self,
        avatarEmoji: profile?.avatarEmoji ?? '',
        avatarImagePath: profile?.avatarImagePath,
      );
    }

    final shadowIndex = shadows.indexWhere(
      (shadow) => shadow.book.id == tagged.transaction.bookId,
    );
    if (shadowIndex >= 0) {
      final shadow = shadows[shadowIndex];
      return _ListFamilyPayer(
        label: shadow.memberDisplayName.isEmpty
            ? memberFallbackLabel
            : shadow.memberDisplayName,
        tone: familyPayerToneForShadowIndex(shadowIndex),
        avatarEmoji: shadow.memberAvatarEmoji,
        avatarImagePath: shadow.memberAvatarImagePath,
      );
    }

    final fallback = tagged.memberTag;
    return _ListFamilyPayer(
      label: fallback?.name.isNotEmpty == true
          ? fallback!.name
          : memberFallbackLabel,
      tone: FamilyPayerTone.memberA,
      avatarEmoji: fallback?.emoji ?? '',
      avatarImagePath: null,
    );
  }
}

class _ListFamilyPayer {
  const _ListFamilyPayer({
    required this.label,
    required this.tone,
    required this.avatarEmoji,
    required this.avatarImagePath,
  });

  final String label;
  final FamilyPayerTone tone;
  final String avatarEmoji;
  final String? avatarImagePath;
}
