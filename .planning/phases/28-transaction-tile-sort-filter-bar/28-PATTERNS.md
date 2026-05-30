# Phase 28: Transaction Tile + Sort/Filter Bar — Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 11 (5 new widgets, 3 modified source files, 3 modified providers/models, 5 new test files)
**Analogs found:** 10 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `lib/features/list/domain/models/list_filter_state.dart` | model | CRUD | `lib/features/list/domain/models/list_sort_config.dart` | exact |
| `lib/features/list/presentation/providers/state_list_filter.dart` | provider/notifier | CRUD | `lib/features/list/presentation/providers/state_list_filter.dart` (self-modify) | self |
| `lib/features/list/presentation/providers/state_list_transactions.dart` | provider | CRUD+transform | self-modify (existing Dart-side filter pipeline) | self |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | widget | request-response | `lib/features/home/presentation/widgets/home_transaction_tile.dart` | exact |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | widget | event-driven | `lib/features/list/presentation/widgets/list_calendar_header.dart` (pinned non-scrolling widget pattern) | role-match |
| `lib/features/list/presentation/widgets/list_day_group_header.dart` | widget | transform | `lib/features/list/presentation/widgets/list_calendar_header.dart` | role-match |
| `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` | widget | CRUD | `lib/features/accounting/presentation/screens/category_selection_screen.dart` | exact |
| `lib/features/list/presentation/widgets/list_empty_state.dart` | widget | request-response | `lib/features/list/presentation/widgets/list_calendar_header.dart` error state | partial-match |
| `lib/features/list/presentation/screens/list_screen.dart` | screen | CRUD | `lib/features/list/presentation/screens/list_screen.dart` (self-modify) | self |
| `test/unit/features/list/list_filter_notifier_test.dart` | test | CRUD | `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | exact |
| `test/unit/features/list/delete_hash_chain_integrity_test.dart` | test | CRUD | `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | role-match |
| `test/widget/features/list/list_transaction_tile_test.dart` | test | request-response | `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | role-match |
| `test/widget/features/list/list_sort_filter_bar_test.dart` | test | event-driven | `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` | role-match |

---

## Pattern Assignments

---

### `lib/features/list/domain/models/list_filter_state.dart` (model, CRUD — D-01 field change)

**Analog:** `lib/features/list/domain/models/list_sort_config.dart` (Freezed VO with `@Default`)

**Current live code** (lines 1–45 of `list_filter_state.dart`):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../accounting/domain/models/transaction.dart';
import 'list_sort_config.dart';

part 'list_filter_state.freezed.dart';

@freezed
abstract class ListFilterState with _$ListFilterState {
  const ListFilterState._();

  const factory ListFilterState({
    required int selectedYear,
    required int selectedMonth,
    DateTime? activeDayFilter,
    @Default(ListSortConfig()) ListSortConfig sortConfig,
    LedgerType? ledgerType,
    String? categoryId,           // ← D-01: CHANGE THIS LINE
    @Default('') String searchQuery,
    String? memberBookId,
  }) = _ListFilterState;
  ...
}
```

**D-01 change — exact diff (line 29):**
```dart
// BEFORE (live code at list_filter_state.dart:29):
String? categoryId,

// AFTER (D-01):
@Default(<String>{}) Set<String> categoryIds,
```

**`@Default` annotation pattern** from `lib/features/list/domain/models/list_sort_config.dart` lines 12–16:
```dart
@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    @Default(SortField.updatedAt) SortField sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _ListSortConfig;
```

**After edit:** run `flutter pub run build_runner build --delete-conflicting-outputs` then `flutter analyze` (0 issues required before writing any widget code — CLAUDE.md Pitfall #3/#13).

---

### `lib/features/list/presentation/providers/state_list_filter.dart` (provider/notifier, CRUD — D-01 mutator replacement)

**Analog:** self-modify. Existing Notifier shape is the pattern; replace one mutator, add one.

**Imports pattern** (lines 1–7 of existing file):
```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/list_filter_state.dart';
import '../../domain/models/list_sort_config.dart';
import '../../../accounting/domain/models/transaction.dart';

part 'state_list_filter.g.dart';
```

**Notifier class declaration pattern** (lines 16–19):
```dart
@Riverpod(keepAlive: true)
class ListFilter extends _$ListFilter {
  @override
  ListFilterState build() => ListFilterState.initial();
```

**Existing mutator pattern to copy** (lines 40–47 — setSort/setLedgerFilter, use same `copyWith` shape):
```dart
void setSort(ListSortConfig sort) {
  state = state.copyWith(sortConfig: sort);
}

void setLedgerFilter(LedgerType? type) {
  state = state.copyWith(ledgerType: type);
}
```

**D-01 replacement: remove `setCategoryFilter(String? id)` (lines 49–51), add:**
```dart
/// Replaces category filter with a new Set of leaf category IDs.
/// Empty set = no category filter (pass-all).
void setCategories(Set<String> ids) {
  state = state.copyWith(categoryIds: ids);
}

/// Toggles a single leaf category ID in/out of the active filter set.
void toggleCategory(String id) {
  final current = Set<String>.from(state.categoryIds);
  if (current.contains(id)) {
    current.remove(id);
  } else {
    current.add(id);
  }
  state = state.copyWith(categoryIds: current);
}
```

**`clearAll` method stays unchanged** (lines 64–66) — `ListFilterState.initial()` will return `categoryIds: {}` after the Freezed regeneration because `@Default(<String>{})` is set.

---

### `lib/features/list/presentation/providers/state_list_transactions.dart` (provider, CRUD+transform — D-01 filter update)

**Analog:** self-modify. Add one Dart-side filter step after the existing day-filter step.

**Existing imports pattern** (lines 1–12):
```dart
import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/accounting/category_localization_service.dart';
import '../../../../application/list/get_list_transactions_use_case.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../../domain/models/tagged_transaction.dart';
import 'repository_providers.dart';
import 'state_list_filter.dart';

part 'state_list_transactions.g.dart';
```

**Existing pipeline shape** (lines 47–51 — use case call):
```dart
final result = await useCase.execute(
  GetListParams(bookIds: bookIds, filter: filter),
);
```

**Add after step 6a day-filter (after line ~72), before step 6b text search:**
```dart
// Step 6a-bis: Dart-side category filter (D-01 — Set<String> multi-select)
// Pass null to SQL-layer categoryId; filter Dart-side for multi-value.
if (filter.categoryIds.isNotEmpty) {
  txs = txs
      .where((tx) => filter.categoryIds.contains(tx.categoryId))
      .toList();
}
```

**Note on `GetListParams`:** The existing `GetListParams` receives `filter` which still contains the old `categoryId` field until D-01 regeneration. After D-01 the field becomes `categoryIds`; the SQL-layer use case only reads `filter.ledgerType` and `filter.sortConfig` for its SQL query — category filtering is already Dart-side only in the existing code path (research A3 confirmed). No `GetListParams` signature change needed.

---

### `lib/features/list/presentation/widgets/list_transaction_tile.dart` (widget, request-response — NEW)

**Analog:** `lib/features/home/presentation/widgets/home_transaction_tile.dart` (lines 1–120, entire file)

**Imports pattern** (copy from `home_transaction_tile.dart` lines 1–5, extend):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../providers/state_list_transactions.dart';  // for listTransactionsProvider
import '../../domain/models/tagged_transaction.dart';
```

**Core tile widget — extends `HomeTransactionTile` layout verbatim** (lines 57–119 of analog):
```dart
/// List tile wrapping [HomeTransactionTile] in a [Dismissible] for swipe-to-delete
/// and adding [onTap] for tap-to-edit navigation (ROW-01 / ROW-02).
///
/// Pure data-driven: all display values computed from [TaggedTransaction] by caller.
class ListTransactionTile extends ConsumerWidget {
  const ListTransactionTile({
    super.key,
    required this.taggedTx,
    required this.bookId,
    required this.onTap,
    // Pre-formatted values injected by parent (pure-UI contract matches HomeTransactionTile)
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.category,
    required this.categoryColor,
    required this.formattedAmount,
    required this.formattedTime,   // D-09: time only, not full date
    this.satisfactionIcon,
  });
  ...
}
```

**`Dismissible` wrapping pattern** (RESEARCH.md Pattern 2, no existing analog):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  return Dismissible(
    key: ValueKey(taggedTx.transaction.id),   // MUST be ValueKey
    direction: DismissDirection.endToStart,   // left-swipe only; right-swipe = no-op
    background: Container(
      color: Colors.red,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      child: const Icon(Icons.delete, color: AppColors.card, size: 20),
    ),
    confirmDismiss: (_) => showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('削除しますか？',   // Phase 30: S.of(context).listDeleteConfirmTitle
          style: AppTextStyles.titleSmall),
        content: Text('この記録を削除します。元に戻せません。',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('キャンセル',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textSecondary)),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('削除',
              style: AppTextStyles.titleSmall.copyWith(color: Colors.red)),
          ),
        ],
      ),
    ),
    onDismissed: (_) {
      // CRITICAL order: ScaffoldMessenger BEFORE provider calls (context still valid here)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('削除しました')),  // Phase 30: ARB key
      );
      ref.read(deleteTransactionUseCaseProvider).execute(taggedTx.transaction.id);
      ref.invalidate(listTransactionsProvider(bookId: bookId));
      // Also invalidate calendarDailyTotalsProvider — read year/month from listFilterProvider
    },
    child: HomeTransactionTile(
      tagText: tagText,
      tagBgColor: tagBgColor,
      tagTextColor: tagTextColor,
      merchant: taggedTx.transaction.merchant ?? taggedTx.transaction.note ?? '—',
      category: category,
      categoryColor: categoryColor,
      formattedAmount: formattedAmount,
      amountColor: AppColors.textPrimary,
      satisfactionIcon: satisfactionIcon,
      onTap: onTap,
    ),
  );
}
```

**`AlertDialog` shape** — copy from `lib/features/accounting/presentation/screens/category_selection_screen.dart` lines 168–189 (`_showDiscardDialog`):
```dart
// analog: category_selection_screen.dart lines 168-189
final discard = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(l10n.discardUnsavedChanges),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(ctx, false),
        child: Text(l10n.keepEditing),
      ),
      TextButton(
        onPressed: () => Navigator.pop(ctx, true),
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        child: Text(l10n.discard),
      ),
    ],
  ),
);
```

**tap-to-edit navigation pattern** (from `TransactionEditScreen` pop contract):
```dart
// ROW-01: tap handler — pass into Tile as onTap callback from parent
Future<void> _onTileTap(BuildContext context, WidgetRef ref,
    TaggedTransaction tx, String bookId, ListFilterState filter) async {
  final result = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => TransactionEditScreen(transaction: tx.transaction),
    ),
  );
  if (result == true) {
    ref.invalidate(listTransactionsProvider(bookId: bookId));
    // Invalidate calendar totals:
    // ref.invalidate(calendarDailyTotalsProvider(bookId: bookId,
    //   year: filter.selectedYear, month: filter.selectedMonth));
  }
}
```

**Tile time display** — add below the existing `HomeTransactionTile` category row (UI-SPEC C-01):
```dart
// Time only — D-09 (date is in day-group header, tile shows HH:mm)
// Use intl directly for time-only; DateFormatter.formatDateTime includes date.
import 'package:intl/intl.dart';
final timeStr = DateFormat('HH:mm', locale.toString())
    .format(taggedTx.transaction.timestamp);
```

---

### `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` (widget, event-driven — NEW)

**Analog:** `lib/features/list/presentation/widgets/list_calendar_header.dart` (pinned non-scrolling widget, `ConsumerWidget` with `ref.watch(listFilterProvider)`)

**Imports pattern** (from `list_calendar_header.dart` lines 1–11, adapt):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../../domain/models/list_sort_config.dart';
import '../../domain/models/list_filter_state.dart';
import '../providers/state_list_filter.dart';
import '../providers/state_list_transactions.dart';  // listTransactionsProvider (for invalidate)
import 'list_category_filter_sheet.dart';
```

**Widget declaration — MUST be `ConsumerStatefulWidget`** (needs `_searchExpanded` local state):
```dart
class ListSortFilterBar extends ConsumerStatefulWidget {
  const ListSortFilterBar({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<ListSortFilterBar> createState() => _ListSortFilterBarState();
}

class _ListSortFilterBarState extends ConsumerState<ListSortFilterBar> {
  bool _searchExpanded = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
```

**`ref.watch(listFilterProvider)` pattern** (same as `list_calendar_header.dart` line 43):
```dart
@override
Widget build(BuildContext context) {
  final filter = ref.watch(listFilterProvider);
  final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
  ...
}
```

**Pinned bar container** (UI-SPEC C-03 — 44dp fixed height):
```dart
Container(
  height: 44,
  decoration: const BoxDecoration(
    color: AppColors.background,
    border: Border(
      bottom: BorderSide(color: AppColors.borderDivider, width: 1),
    ),
  ),
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [/* chips */],
    ),
  ),
)
```

**Sort chip with active field label** (D-05 — must NOT be generic "Sort"):
```dart
// SC#4 hard requirement: chip label = current field name
ActionChip(
  avatar: Icon(Icons.sort, size: 14, color: AppColors.textSecondary),
  label: Text(
    _sortFieldLabel(filter.sortConfig.sortField, locale),
    style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
  ),
  onPressed: () => _showSortMenu(context, filter),
  side: const BorderSide(color: AppColors.accentPrimary, width: 1),
  backgroundColor: AppColors.card,
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
)

String _sortFieldLabel(SortField field, Locale locale) {
  final lang = locale.languageCode;
  switch (field) {
    case SortField.timestamp:
      return lang == 'ja' ? '日付' : (lang == 'zh' ? '日期' : 'Date');
    case SortField.updatedAt:
      return lang == 'ja' ? '更新日時' : (lang == 'zh' ? '更新时间' : 'Edit time');
    case SortField.amount:
      return lang == 'ja' ? '金額' : (lang == 'zh' ? '金额' : 'Amount');
  }
}
```

**Direction arrow** (D-04 / SORT-04):
```dart
IconButton(
  icon: Icon(
    filter.sortConfig.sortDirection == SortDirection.desc
        ? Icons.arrow_downward
        : Icons.arrow_upward,
    size: 18,
    color: AppColors.textPrimary,
  ),
  onPressed: () => ref.read(listFilterProvider.notifier).setSort(
    filter.sortConfig.copyWith(
      sortDirection: filter.sortConfig.sortDirection == SortDirection.desc
          ? SortDirection.asc
          : SortDirection.desc,
    ),
  ),
  padding: EdgeInsets.zero,
  constraints: const BoxConstraints(minWidth: 32, minHeight: 44),
)
```

**Ledger chips pattern** (FILTER-02 — three mutually-exclusive chips, mirroring the `FilterChip` active-state convention used in `category_selection_screen.dart`):
```dart
// "All" chip: active = ledgerType == null
ActionChip(
  label: Text('すべて',   // Phase 30: S.of(context).listLedgerAll
    style: AppTextStyles.caption.copyWith(
      color: filter.ledgerType == null
          ? AppColors.textPrimary : AppColors.textSecondary)),
  backgroundColor: filter.ledgerType == null
      ? AppColors.backgroundMuted : AppColors.card,
  side: BorderSide(
    color: filter.ledgerType == null
        ? AppColors.borderDefault : AppColors.borderDefault, width: 1),
  onPressed: () =>
      ref.read(listFilterProvider.notifier).setLedgerFilter(null),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
// "生存" chip: active = ledgerType == LedgerType.survival
ActionChip(
  label: Text('生存',  // Phase 30: S.of(context).listLedgerSurvival
    style: AppTextStyles.caption.copyWith(
      color: filter.ledgerType == LedgerType.survival
          ? AppColors.survival : AppColors.textSecondary)),
  backgroundColor: filter.ledgerType == LedgerType.survival
      ? AppColors.survivalLight : AppColors.card,
  side: BorderSide(
    color: filter.ledgerType == LedgerType.survival
        ? AppColors.survival : AppColors.borderDefault, width: 1),
  onPressed: () => ref.read(listFilterProvider.notifier).setLedgerFilter(
    filter.ledgerType == LedgerType.survival ? null : LedgerType.survival),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
```

**AnimatedContainer search expand** (D-06, RESEARCH.md Pattern 6):
```dart
_searchExpanded
  ? AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: 160,
      height: 32,
      child: TextField(
        autofocus: true,
        controller: _searchController,
        onChanged: (v) =>
            ref.read(listFilterProvider.notifier).setSearch(v),
        onSubmitted: (_) {
          if (_searchController.text.isEmpty) {
            setState(() => _searchExpanded = false);
          }
        },
        style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: '検索...',  // Phase 30: ARB key
          hintStyle:
              AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.borderDefault, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: AppColors.accentPrimary, width: 1),
          ),
        ),
      ),
    )
  : IconButton(
      icon: const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
      onPressed: () => setState(() => _searchExpanded = true),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
    ),
```

**Conditional clear chip** (D-07):
```dart
bool get _anyFilterActive =>
    filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty;

if (_anyFilterActive)
  ActionChip(
    avatar: const Icon(Icons.clear_all, size: 14,
        color: AppColors.textSecondary),
    label: Text('クリア',  // Phase 30: ARB key
        style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary)),
    backgroundColor: AppColors.backgroundMuted,
    side: const BorderSide(color: AppColors.borderDefault, width: 1),
    onPressed: () {
      ref.read(listFilterProvider.notifier).clearAll();
      setState(() {
        _searchExpanded = false;
        _searchController.clear();
      });
    },
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
```

---

### `lib/features/list/presentation/widgets/list_day_group_header.dart` (widget, transform — NEW)

**Analog:** `lib/features/list/presentation/widgets/list_calendar_header.dart` (Container/Text pattern with `AppColors.backgroundMuted` + `AppTextStyles.caption`)

**Imports pattern:**
```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/date_formatter.dart';
```

**Core widget — stateless, pure UI** (UI-SPEC C-02, 32dp height):
```dart
class ListDayGroupHeader extends StatelessWidget {
  const ListDayGroupHeader({
    super.key,
    required this.date,
    required this.locale,
  });

  final DateTime date;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.backgroundMuted,
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          DateFormatter.formatDate(date, locale),
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
```

**Grouped-by-day assembly helper** (place as private functions in `list_screen.dart` or an adjacent `_list_grouping.dart`):
```dart
// Sealed item type — avoids index arithmetic bugs in ListView.builder
sealed class _ListItem {}
class _HeaderItem extends _ListItem {
  final DateTime date;
  _HeaderItem(this.date);
}
class _RowItem extends _ListItem {
  final TaggedTransaction tx;
  _RowItem(this.tx);
}

List<_ListItem> _buildFlatList(
  List<TaggedTransaction> txs,
  SortDirection direction,
) {
  final map = <DateTime, List<TaggedTransaction>>{};
  for (final t in txs) {
    final key = DateTime(
      t.transaction.timestamp.year,
      t.transaction.timestamp.month,
      t.transaction.timestamp.day,
    );
    map.putIfAbsent(key, () => []).add(t);
  }
  final sortedKeys = map.keys.toList()
    ..sort((a, b) => direction == SortDirection.desc
        ? b.compareTo(a)
        : a.compareTo(b));
  return [
    for (final k in sortedKeys) ...[
      _HeaderItem(k),
      for (final tx in map[k]!) _RowItem(tx),
    ],
  ];
}
```

---

### `lib/features/list/presentation/widgets/list_category_filter_sheet.dart` (widget, CRUD — NEW)

**Analog:** `lib/features/accounting/presentation/screens/category_selection_screen.dart` (lines 20–450, entire file)

**Imports pattern** (from `category_selection_screen.dart` lines 1–14, adapt for filter sheet):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../application/accounting/category_localization_service.dart';
import '../../../../features/accounting/domain/models/category.dart';
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show categoryRepositoryProvider;
import '../../../../features/settings/presentation/providers/state_locale.dart';
import '../providers/state_list_filter.dart';
```

**Widget declaration — `ConsumerStatefulWidget` with local selection state:**
```dart
/// Multi-select category filter bottom sheet (D-02: L1→L2 cascade + tristate).
///
/// Pre-populated from [listFilterProvider]'s current [categoryIds].
/// Writes via [listFilterProvider.notifier.setCategories()] only on "Apply".
class CategoryFilterSheet extends ConsumerStatefulWidget {
  const CategoryFilterSheet({super.key, required this.initialSelected});
  final Set<String> initialSelected;

  @override
  ConsumerState<CategoryFilterSheet> createState() =>
      _CategoryFilterSheetState();
}
```

**L1/L2 load pattern** — copy verbatim from `category_selection_screen.dart` lines 47–89:
```dart
Future<void> _loadCategories() async {
  final repo = ref.read(categoryRepositoryProvider);
  final all = await repo.findActive();
  final l1 = <Category>[];
  final l2Map = <String, List<Category>>{};
  for (final cat in all) {
    if (cat.level == 1) {
      l1.add(cat);
    } else if (cat.level == 2 && cat.parentId != null) {
      l2Map.putIfAbsent(cat.parentId!, () => []).add(cat);
    }
  }
  l1.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  for (final children in l2Map.values) {
    children.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
  if (mounted) {
    setState(() {
      _l1Categories = l1;
      _l2ByParent = l2Map;
      _isLoading = false;
    });
  }
}
```

**Tristate L1 logic** (RESEARCH.md Pattern 5):
```dart
enum _L1SelectState { none, partial, all }

_L1SelectState _l1State(String l1Id) {
  final children = _l2ByParent[l1Id] ?? [];
  if (children.isEmpty) return _L1SelectState.none;
  final count = children.where((c) => _localSelected.contains(c.id)).length;
  if (count == 0) return _L1SelectState.none;
  if (count == children.length) return _L1SelectState.all;
  return _L1SelectState.partial;
}

void _toggleL1(String l1Id) {
  final children = _l2ByParent[l1Id] ?? [];
  final s = _l1State(l1Id);
  setState(() {
    if (s == _L1SelectState.all) {
      for (final c in children) _localSelected.remove(c.id);
    } else {
      for (final c in children) _localSelected.add(c.id);
    }
  });
}
```

**Tristate Checkbox rendering** (Flutter SDK built-in):
```dart
// none  → Checkbox(value: false, tristate: false, ...)
// partial → Checkbox(value: null, tristate: true, ...)
// all   → Checkbox(value: true, tristate: false, ...)
Checkbox(
  tristate: s == _L1SelectState.partial,
  value: s == _L1SelectState.partial ? null : (s == _L1SelectState.all),
  onChanged: (_) => _toggleL1(l1.id),
)
```

**Apply pattern** (writes to `listFilterProvider`, mirrors `CategorySelectionScreen.onChildSelected` → `Navigator.pop`):
```dart
// Apply button onPressed:
ref.read(listFilterProvider.notifier).setCategories(
  Set<String>.unmodifiable(_localSelected));
Navigator.pop(context);
```

**Sheet container** (UI-SPEC C-05 — `showModalBottomSheet` caller in bar):
```dart
// In ListSortFilterBar._openCategorySheet:
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => CategoryFilterSheet(
    initialSelected: ref.read(listFilterProvider).categoryIds,
  ),
);
```

---

### `lib/features/list/presentation/widgets/list_empty_state.dart` (widget, request-response — NEW)

**Analog:** no exact analog; closest is the error state inline in `list_calendar_header.dart`. Pattern is a simple `Center(child: Column(...))`.

**Core pattern** (UI-SPEC C-06):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/state_list_filter.dart';

class ListEmptyState extends ConsumerWidget {
  const ListEmptyState({super.key, required this.isFilterActive});
  final bool isFilterActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFilterActive
                  ? Icons.search_off_outlined
                  : Icons.receipt_long_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 16),
            Text(
              isFilterActive
                  ? '[filtered empty placeholder]'   // Phase 30: ARB listEmptyFiltered
                  : '[month empty placeholder]',     // Phase 30: ARB listEmptyMonth
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isFilterActive) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () =>
                    ref.read(listFilterProvider.notifier).clearAll(),
                child: Text(
                  '[clear filters placeholder]',  // Phase 30: ARB listEmptyFilteredClear
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.accentPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

---

### `lib/features/list/presentation/screens/list_screen.dart` (screen, CRUD — MODIFY)

**Analog:** self-modify. Existing structure is the pattern; replace `Expanded(spinner)` with bar + list.

**Current structure** (lines 23–35, entire build method):
```dart
return Column(
  children: [
    CalendarHeaderWidget(
      bookId: bookId,
      currencyCode: currencyCode,
      locale: locale,
    ),
    // Phase 28: replace with transaction list
    const Expanded(child: Center(child: CircularProgressIndicator())),
  ],
);
```

**Target structure after Phase 28** (UI-SPEC C-02/C-03 layout):
```dart
return Column(
  children: [
    CalendarHeaderWidget(
      bookId: bookId,
      currencyCode: currencyCode,
      locale: locale,
    ),
    ListSortFilterBar(bookId: bookId),          // C-03: pinned, 44dp, no-scroll
    Expanded(
      child: _buildList(context, ref, filter, locale),
    ),
  ],
);

Widget _buildList(BuildContext context, WidgetRef ref,
    ListFilterState filter, Locale locale) {
  final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
  return txsAsync.when(
    loading: () => const Center(
      child: CircularProgressIndicator(
          color: AppColors.accentPrimary, strokeWidth: 2)),
    error: (_, __) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, size: 40, color: AppColors.textTertiary),
        const SizedBox(height: 8),
        Text('[data load error]',
            style: AppTextStyles.caption.copyWith(
                color: AppColors.textSecondary)),
      ]),
    ),
    data: (txs) {
      if (txs.isEmpty) {
        final anyActive = filter.activeDayFilter != null ||
            filter.ledgerType != null ||
            filter.categoryIds.isNotEmpty ||
            filter.searchQuery.isNotEmpty;
        return ListEmptyState(isFilterActive: anyActive);
      }
      final items = _buildFlatList(txs, filter.sortConfig.sortDirection);
      return ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, i) {
          final item = items[i];
          return switch (item) {
            _HeaderItem() => ListDayGroupHeader(
                date: item.date, locale: locale),
            _RowItem() => ListTransactionTile(/* ... */),
          };
        },
      );
    },
  );
}
```

**`AsyncValue.when` pattern** — copy from `list_calendar_header.dart` calendarAsync.when usage (the existing provider consumption shape in this feature).

---

## Test File Pattern Assignments

---

### `test/unit/features/list/list_filter_notifier_test.dart` (unit test — covers D-01 mutators)

**Analog:** `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` (lines 1–253, entire file)

**Imports pattern** (lines 1–8 of analog):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/list/domain/models/list_filter_state.dart';
import 'package:home_pocket/features/list/domain/models/list_sort_config.dart';
import 'package:home_pocket/features/list/presentation/providers/state_list_filter.dart';
import 'package:home_pocket/shared/constants/sort_config.dart';
```

**`ProviderContainer.test()` pattern** (lines 11–13 of analog):
```dart
test('...', () {
  final container = ProviderContainer.test();
  final notifier = container.read(listFilterProvider.notifier);
  ...
});
```

**New tests to add for D-01** (following exact structure of analog's `setCategoryFilter` tests):
```dart
test('setCategories stores the provided Set', () {
  final container = ProviderContainer.test();
  container.read(listFilterProvider.notifier)
      .setCategories({'cat_food', 'cat_transport'});
  expect(container.read(listFilterProvider).categoryIds,
      equals({'cat_food', 'cat_transport'}));
});

test('toggleCategory adds id when not present', () {
  final container = ProviderContainer.test();
  container.read(listFilterProvider.notifier).toggleCategory('cat_food');
  expect(container.read(listFilterProvider).categoryIds,
      contains('cat_food'));
});

test('toggleCategory removes id when already present', () {
  final container = ProviderContainer.test();
  container.read(listFilterProvider.notifier)
    ..setCategories({'cat_food'})
    ..toggleCategory('cat_food');
  expect(container.read(listFilterProvider).categoryIds, isEmpty);
});

test('clearAll resets categoryIds to empty Set', () {
  final container = ProviderContainer.test();
  container.read(listFilterProvider.notifier)
    ..setCategories({'cat_food'})
    ..clearAll();
  expect(container.read(listFilterProvider).categoryIds, isEmpty);
});

test('setCategories produces new state via copyWith (immutability)', () {
  final container = ProviderContainer.test();
  final before = container.read(listFilterProvider);
  container.read(listFilterProvider.notifier)
      .setCategories({'cat_food'});
  final after = container.read(listFilterProvider);
  expect(identical(before, after), isFalse);
  expect(before.categoryIds, isEmpty);
});
```

---

### `test/unit/features/list/delete_hash_chain_integrity_test.dart` (unit test — SC#3)

**Analog:** `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` (imports and `ProviderContainer.test()` + `waitForFirstValue<T>` pattern)

**Imports pattern** (from `list_transactions_provider_test.dart` lines 1–17):
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
import 'package:home_pocket/infrastructure/crypto/services/hash_chain_service.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/test_provider_scope.dart';
```

**`waitForFirstValue<T>` usage** (from `test_provider_scope.dart` line 34):
```dart
final result = await waitForFirstValue(container,
    listTransactionsProvider(bookId: 'book1'));
expect(result.hasValue, isTrue);
```

**SC#3 test structure** (from RESEARCH.md Pitfall 6):
```dart
test('soft-delete sets isDeleted=true and hash chain remains valid', () async {
  final db = AppDatabase.forTesting();
  final container = ProviderContainer.test(overrides: [
    appDatabaseProvider.overrideWithValue(db),
  ]);

  // 1. Insert 3 transactions via repository
  // 2. Soft-delete middle one via DeleteTransactionUseCase
  final useCase = container.read(deleteTransactionUseCaseProvider);
  await useCase.execute(middleId);

  // 3. Assert isDeleted = true on that row
  // (via transactionRepositoryProvider.findById or DAO)

  // 4. Verify hash chain on remaining non-deleted rows
  // hashChainService.verifyChain takes List<Map<String,dynamic>>
  final hashChain = HashChainService();
  // fetch raw maps from DAO...
  final result = hashChain.verifyChain(remainingMaps);
  expect(result.isValid, isTrue);
});
```

---

### `test/widget/features/list/list_transaction_tile_test.dart` (widget test — ROW-01/ROW-02)

**Analog:** `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` (lines 1–37 — `_pumpCalendarHeader` pattern + `UncontrolledProviderScope`)

**Widget pump helper pattern** (from `list_calendar_header_test.dart` lines 16–37):
```dart
Future<void> _pumpTile(
  WidgetTester tester,
  ProviderContainer container,
  TaggedTransaction tx,
) async {
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        home: Scaffold(
          body: ListTransactionTile(
            taggedTx: tx,
            bookId: 'book1',
            onTap: () {},
            // ... pre-formatted display values ...
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
```

**Mock pattern** (from `list_calendar_header_test.dart` line 13 and `list_transactions_provider_test.dart` line 19):
```dart
class _MockDeleteTransactionUseCase extends Mock
    implements DeleteTransactionUseCase {}
```

**ROW-01 tap test shape:**
```dart
testWidgets('ROW-01: tapping tile navigates to TransactionEditScreen',
    (tester) async {
  // Pump tile, tap, verify Navigator push
});
```

**ROW-02 swipe test shape:**
```dart
testWidgets('ROW-02: left swipe shows confirm dialog', (tester) async {
  await tester.drag(find.byType(ListTransactionTile),
      const Offset(-500, 0));
  await tester.pumpAndSettle();
  expect(find.byType(AlertDialog), findsOneWidget);
});
```

---

### `test/widget/features/list/list_sort_filter_bar_test.dart` (widget test — SORT/FILTER)

**Analog:** `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart`

**Same `UncontrolledProviderScope` + `ProviderContainer.test(overrides: [...])` shape.**

**Key interactions to test:**
```dart
testWidgets('SC#4: sort chip label reflects current field name', (tester) async {
  // Initial state: SortField.updatedAt → label should NOT be "Sort"
  // Assert: find.text('更新日時') or find.text('Edit time')
});

testWidgets('FILTER-02: tapping ledger chip sets ledgerFilter', (tester) async {
  // Tap '生存' chip → assert listFilterProvider.state.ledgerType == LedgerType.survival
});

testWidgets('FILTER-04: clear chip appears only when filter active', (tester) async {
  // Initially: no clear chip
  // setLedgerFilter(LedgerType.soul) → clear chip appears
});
```

---

## Shared Patterns

### Freezed model + `@Default` annotation
**Source:** `lib/features/list/domain/models/list_sort_config.dart` lines 12–16
**Apply to:** `list_filter_state.dart` D-01 field change (`@Default(<String>{}) Set<String> categoryIds`)
```dart
@freezed
abstract class ListSortConfig with _$ListSortConfig {
  const factory ListSortConfig({
    @Default(SortField.updatedAt) SortField sortField,
    @Default(SortDirection.desc) SortDirection sortDirection,
  }) = _ListSortConfig;
```

### `@Riverpod(keepAlive: true)` Notifier with `copyWith` mutations
**Source:** `lib/features/list/presentation/providers/state_list_filter.dart` lines 16–68
**Apply to:** `state_list_filter.dart` D-01 mutator changes (new `setCategories`/`toggleCategory` follow same `state = state.copyWith(...)` pattern)

### `ConsumerWidget` with `ref.watch(listFilterProvider)` state read
**Source:** `lib/features/list/presentation/widgets/list_calendar_header.dart` lines 28–53
**Apply to:** `list_sort_filter_bar.dart`, `list_empty_state.dart`, and `list_screen.dart`
```dart
class CalendarHeaderWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(listFilterProvider);
    final calendarAsync = ref.watch(calendarDailyTotalsProvider(...));
    ...
  }
}
```

### `AsyncValue.when` loading/error/data pattern
**Source:** `lib/features/list/presentation/widgets/list_calendar_header.dart` (calendarAsync.when usage)
**Apply to:** `list_screen.dart` `listTransactionsProvider` consumption
```dart
// Pattern: pass ?? {} so UI renders during loading state
final dailyMap = calendarAsync.value ?? {};
// For async provider consuming in list_screen.dart, use full .when:
txsAsync.when(
  loading: () => ...,
  error: (e, st) => ...,
  data: (data) => ...,
)
```

### `showDialog<bool>` AlertDialog confirmation
**Source:** `lib/features/accounting/presentation/screens/category_selection_screen.dart` lines 168–189
**Apply to:** `list_transaction_tile.dart` `confirmDismiss` callback
```dart
final discard = await showDialog<bool>(
  context: context,
  builder: (ctx) => AlertDialog(
    title: Text(...),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx, false), child: ...),
      TextButton(
        style: TextButton.styleFrom(foregroundColor: Colors.red),
        onPressed: () => Navigator.pop(ctx, true),
        child: ...,
      ),
    ],
  ),
);
```

### `ref.read(useCase).execute()` fire-and-forget pattern
**Source:** `lib/features/settings/presentation/widgets/data_management_section.dart` (lines 68–71)
**Apply to:** `list_transaction_tile.dart` `onDismissed` — use `ref.read` (not watch) for one-shot side-effects
```dart
final result = await ref
    .read(exportBackupUseCaseProvider)
    .execute(bookId: bookId, password: password);
```

### `show` import guard for cross-feature provider
**Source:** `lib/features/list/presentation/providers/repository_providers.dart` lines 4–5
**Apply to:** Any new list widget importing `deleteTransactionUseCaseProvider` from accounting feature
```dart
import '../../../accounting/presentation/providers/repository_providers.dart'
    show transactionRepositoryProvider;
// Same pattern for delete:
import '../../../../features/accounting/presentation/providers/repository_providers.dart'
    show deleteTransactionUseCaseProvider;
```

### `ProviderContainer.test()` + `waitForFirstValue<T>` in unit tests
**Source:** `test/helpers/test_provider_scope.dart` lines 13–45
**Apply to:** All new test files (`list_filter_notifier_test.dart`, `delete_hash_chain_integrity_test.dart`)
```dart
final container = ProviderContainer.test(overrides: [...]);
// For async providers:
final value = await waitForFirstValue(container, someProvider);
```

### `UncontrolledProviderScope` in widget tests
**Source:** `test/widget/features/list/presentation/widgets/list_calendar_header_test.dart` lines 16–37
**Apply to:** All new widget test files (`list_transaction_tile_test.dart`, `list_sort_filter_bar_test.dart`)
```dart
await tester.pumpWidget(
  UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      home: Scaffold(body: WidgetUnderTest()),
    ),
  ),
);
```

### `AppTextStyles.amountSmall` for all monetary amounts
**Source:** `lib/core/theme/app_text_styles.dart` line 162
**Apply to:** `list_transaction_tile.dart` amount display — passed into `HomeTransactionTile.formattedAmount` (tile uses `amountSmall` internally)
```dart
static const amountSmall = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 15,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  fontFeatures: _tabularFigures,  // SC#1 cross-row alignment
);
```

### Nullable `bookId` parameter + provider fallback
**Source:** CLAUDE.md §"Widget Parameter Pattern"
**Apply to:** `list_screen.dart`, `list_transaction_tile.dart`, `list_sort_filter_bar.dart` — all pass `bookId` through; if `bookId` may come from parent, use:
```dart
final effectiveBookId = bookId ?? ref.watch(currentBookIdProvider).value;
```

---

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `lib/features/list/presentation/widgets/list_empty_state.dart` | widget | request-response | No prior empty-state widget in the list feature; closest is inline error handling in `list_calendar_header.dart`. Planner should use standard `Center(Column(...))` pattern. |

---

## Metadata

**Analog search scope:** `lib/features/list/`, `lib/features/home/presentation/widgets/`, `lib/features/accounting/presentation/screens/`, `lib/core/theme/`, `lib/features/settings/presentation/widgets/`, `test/unit/features/list/`, `test/widget/features/list/`
**Files scanned:** 15 source files + 5 existing test files
**Pattern extraction date:** 2026-05-30

### Critical Anti-Patterns (from RESEARCH.md — must note for planner)

1. **Do NOT create a new `repository_providers.dart` in the list feature.** Import `deleteTransactionUseCaseProvider` from accounting with a `show` guard (see Shared Patterns above). `provider_graph_hygiene_test` enforces this.
2. **Do NOT call `ref.watch` or `await` inside `onDismissed`.** Call `ScaffoldMessenger.of(context)` synchronously first, then `ref.read(deleteUseCase).execute()` fire-and-forget, then `ref.invalidate(...)`.
3. **Do NOT hardcode hex colors for ledger tags.** Only `AppColors.survival` / `AppColors.soul` / `AppColors.survivalLight` / `AppColors.soulLight`.
4. **Sort chip label MUST show active field name** (D-05 / SC#4). "Sort" generic label fails the acceptance criterion.
5. **Run `build_runner build --delete-conflicting-outputs` immediately after D-01 Freezed change** — before writing any widget code.
6. **`Dismissible` key MUST be `ValueKey(tx.transaction.id)`** — plain `Key(...)` causes assertion failures on list rebuild.
