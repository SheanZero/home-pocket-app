# Phase 30: i18n + Empty States + Golden Polish — Pattern Map

**Mapped:** 2026-05-31
**Files analyzed:** 11 (6 new golden test files + 5 modified files)
**Analogs found:** 11 / 11

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `test/golden/list_day_group_header_golden_test.dart` | test (golden) | request-response | `test/golden/amount_display_golden_test.dart` | exact — no ProviderScope needed |
| `test/golden/list_empty_state_golden_test.dart` | test (golden) | request-response | `test/golden/per_category_breakdown_card_golden_test.dart` | exact — 3 locale × N variants, ProviderScope |
| `test/golden/list_sort_filter_bar_golden_test.dart` | test (golden) | request-response | `test/golden/soul_vs_survival_card_golden_test.dart` | exact — ProviderScope + multi-provider overrides |
| `test/golden/list_transaction_tile_golden_test.dart` | test (golden) | request-response | `test/golden/soul_vs_survival_card_golden_test.dart` | exact — ProviderScope + fixed-fixture |
| `test/golden/list_calendar_header_golden_test.dart` | test (golden) | request-response | `test/golden/per_category_breakdown_card_golden_test.dart` | exact — ProviderScope overrides; adds determinism fix |
| `test/golden/list_category_filter_sheet_golden_test.dart` | test (golden) | request-response | `test/golden/per_category_breakdown_card_golden_test.dart` | exact — ProviderScope + FakeRepository override |
| `lib/features/list/presentation/widgets/list_empty_state.dart` | component | request-response | `lib/features/family_sync/presentation/widgets/sync_status_badge.dart` | exact — enum-driven switch render, S.of(context), ConsumerWidget |
| `lib/features/list/presentation/screens/list_screen.dart` | screen | request-response | self (lines 111–121) | self-modification — replace bool branching |
| `lib/l10n/app_ja.arb` | config | transform | self (lines 2197–2210) | self-modification — key block extension |
| `lib/l10n/app_zh.arb` | config | transform | self (lines 2197–2210) | self-modification — key block extension |
| `lib/l10n/app_en.arb` | config | transform | self (lines 2197–2210) | self-modification — key block extension |
| `lib/features/list/presentation/widgets/list_calendar_header.dart` | component | request-response | self (lines 220–268) | self-modification — replace 3 hardcoded Semantics labels |
| `test/widget/features/list/list_empty_state_test.dart` | test (widget) | request-response | self (current file) | self-modification — migrate bool to enum API |
| `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | test (unit) | request-response | self (lines 60–68) | self-modification — add day-only-clear case |

---

## Pattern Assignments

### `test/golden/list_day_group_header_golden_test.dart` (test, golden)

**Analog:** `test/golden/amount_display_golden_test.dart`

No ProviderScope needed — `ListDayGroupHeader` is a pure `StatelessWidget` with no provider reads.

**Imports pattern** (from `amount_display_golden_test.dart` lines 1–6):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_day_group_header.dart';
import 'package:home_pocket/generated/app_localizations.dart';
```

**`_wrap` without ProviderScope** (from `amount_display_golden_test.dart` lines 9–24):
```dart
Widget _wrap({required Locale locale, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: Center(child: SizedBox(width: 390, height: 32, child: child)),
    ),
  );
}
```

**3-locale test body pattern** (from `amount_display_golden_test.dart` lines 26–79):
```dart
void main() {
  group('ListDayGroupHeader golden', () {
    testWidgets('locale ja', (tester) async {
      await tester.pumpWidget(
        _wrap(
          locale: const Locale('ja'),
          child: ListDayGroupHeader(
            date: DateTime(2026, 5, 15),
            locale: const Locale('ja'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(ListDayGroupHeader),
        matchesGoldenFile('goldens/list_day_group_header_ja.png'),
      );
    });
    // repeat for 'zh' and 'en'
  });
}
```

**Key difference from `amount_display`:** `ListDayGroupHeader` receives `locale: Locale` as a constructor param (used by `DateFormatter`) — pass the same locale to both `_wrap(locale:)` and the widget constructor.

---

### `test/golden/list_empty_state_golden_test.dart` (test, golden)

**Analog:** `test/golden/per_category_breakdown_card_golden_test.dart`

9 golden cases: 3 variants (`noData`, `dayEmpty`, `filtered`) × 3 locales (ja, zh, en).

**Imports pattern** (from `per_category_breakdown_card_golden_test.dart` lines 1–10):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/list/presentation/widgets/list_empty_state.dart';
import 'package:home_pocket/generated/app_localizations.dart';
```

**`_wrap` with ProviderScope** (from `per_category_breakdown_card_golden_test.dart` lines 51–89):
```dart
Widget _wrap({required Locale locale, required ListEmptyVariant variant}) {
  return ProviderScope(
    // listFilterProvider needed for button callbacks (ref.read in onPressed)
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 390,
            height: 300,
            child: ListEmptyState(variant: variant),
          ),
        ),
      ),
    ),
  );
}
```

**3-variant × 3-locale test body** (pattern from `per_category_breakdown_card_golden_test.dart` lines 92–113):
```dart
void main() {
  group('ListEmptyState golden', () {
    for (final locale in [const Locale('ja'), const Locale('zh'), const Locale('en')]) {
      for (final variant in ListEmptyVariant.values) {
        testWidgets('${variant.name} — ${locale.languageCode}', (tester) async {
          await tester.pumpWidget(_wrap(locale: locale, variant: variant));
          await tester.pumpAndSettle();
          await expectLater(
            find.byType(ListEmptyState),
            matchesGoldenFile(
              'goldens/list_empty_state_${variant.name}_${locale.languageCode}.png',
            ),
          );
        });
      }
    }
  });
}
```

---

### `test/golden/list_sort_filter_bar_golden_test.dart` (test, golden)

**Analog:** `test/golden/soul_vs_survival_card_golden_test.dart` (ProviderScope + multi-override pattern) combined with `test/widget/features/list/list_sort_filter_bar_test.dart` (exact provider override set for this widget).

**Provider overrides needed** (from `list_sort_filter_bar_test.dart` lines 24–48):
```dart
ProviderScope(
  overrides: [
    locale_providers.currentLocaleProvider
        .overrideWith((_) async => locale),
    // isGroupModeProvider: keep default (false) unless testing Mine-only chip
    // shadowBooksProvider: only needed when isGroupMode=true; override to [] as safety
  ],
  child: MaterialApp(
    locale: locale,
    localizationsDelegates: S.localizationsDelegates,
    supportedLocales: S.supportedLocales,
    theme: ThemeData.light(),
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 56,
        child: ListSortFilterBar(bookId: 'book_golden'),
      ),
    ),
  ),
)
```

**3-locale loop pattern** (from `soul_vs_survival_card_golden_test.dart` lines 98–108):
```dart
testWidgets('locale ja', (tester) async {
  await tester.pumpWidget(_wrap(locale: const Locale('ja')));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(ListSortFilterBar),
    matchesGoldenFile('goldens/list_sort_filter_bar_ja.png'),
  );
});
```

---

### `test/golden/list_transaction_tile_golden_test.dart` (test, golden)

**Analog:** `test/golden/soul_vs_survival_card_golden_test.dart` (ProviderScope + fixed fixture).

**Fixture pattern** (from `list_transaction_tile_test.dart` lines 26–43):
```dart
TaggedTransaction _makeTx() {
  final now = DateTime(2026, 5, 1, 10, 30);
  return TaggedTransaction(
    transaction: Transaction(
      id: 'tx-golden',
      bookId: 'book_golden',
      deviceId: 'device1',
      amount: 1234,
      type: TransactionType.expense,
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
      timestamp: now,
      currentHash: 'stub_hash',
      createdAt: now,
      entrySource: EntrySource.manual,
    ),
  );
}
```

**ProviderScope wrap** (from `list_transaction_tile_test.dart` lines 45–76 + `per_category_breakdown_card_golden_test.dart` lines 51–89):
```dart
Widget _wrap({required Locale locale}) {
  return ProviderScope(
    // deleteTransactionUseCaseProvider only called in onDismissed, not build()
    // no provider override needed for rendering
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 80,
          child: ListTransactionTile(
            taggedTx: _makeTx(),
            bookId: 'book_golden',
            onTap: () {},
            onDeleted: () {},
            tagText: /* locale-specific via S, or pass pre-resolved string */
            tagBgColor: AppColors.survivalLight,
            tagTextColor: AppColors.survival,
            category: 'category_food',
            categoryColor: AppColors.survival,
            formattedAmount: '¥1,234',
            formattedTime: '10:30',
            satisfactionIcon: null,
          ),
        ),
      ),
    ),
  );
}
```

**Note:** `tagText` (ledger label like '生存') comes from `S.of(context)` in the screen, not the tile. For the golden, pass pre-resolved strings for each locale directly.

---

### `test/golden/list_calendar_header_golden_test.dart` (test, golden — highest complexity)

**Analog:** `test/golden/per_category_breakdown_card_golden_test.dart` (ProviderScope overrides) with determinism fix specific to this widget.

**Critical determinism override** (from RESEARCH.md §D-03 — verified from `list_calendar_header.dart:142`):
```dart
// Pin to January 2025 so DateTime.now() (2026-05+) never matches any cell
const _fixedYear = 2025;
const _fixedMonth = 1;

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      // REQUIRED: prevents DateTime.now() flake in _buildDayCell (line 142)
      listFilterProvider.overrideWith(
        (ref) => ListFilterState(
          selectedYear: _fixedYear,
          selectedMonth: _fixedMonth,
        ),
      ),
      calendarDailyTotalsProvider(
        bookId: 'test_book',
        year: _fixedYear,
        month: _fixedMonth,
      ).overrideWith((_) async => <DateTime, int>{}),
      isGroupModeProvider.overrideWith((_) => false),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 520,
          child: CalendarHeaderWidget(
            bookId: 'test_book',
            currencyCode: 'JPY',
            locale: locale,
          ),
        ),
      ),
    ),
  );
}
```

**pumpAndSettle drains AnimatedSize** (from RESEARCH.md — `_SummaryRow` contains `AnimatedSize`):
```dart
await tester.pumpWidget(_wrap(locale: const Locale('ja')));
await tester.pumpAndSettle(); // drains AnimatedSize in _SummaryRow
await expectLater(
  find.byType(CalendarHeaderWidget),
  matchesGoldenFile('goldens/list_calendar_header_ja.png'),
);
```

---

### `test/golden/list_category_filter_sheet_golden_test.dart` (test, golden)

**Analog:** `test/golden/per_category_breakdown_card_golden_test.dart` combined with `test/widget/features/list/list_category_filter_sheet_test.dart` (FakeRepository pattern).

**FakeRepository override** (from `list_category_filter_sheet_test.dart` lines 27–75, 117–148):
```dart
// Reuse _FakeCategoryRepository from list_category_filter_sheet_test.dart
// (or inline in golden test if cross-file import is awkward)

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      categoryRepositoryProvider
          .overrideWithValue(_FakeCategoryRepository(_testCategories)),
      locale_providers.currentLocaleProvider
          .overrideWith((_) async => locale),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 500,
          child: CategoryFilterSheet(initialSelected: const {}),
        ),
      ),
    ),
  );
}
```

---

### `lib/features/list/presentation/widgets/list_empty_state.dart` (component, 3-state rework)

**Analog:** `lib/features/family_sync/presentation/widgets/sync_status_badge.dart`

This is the closest existing analog — an enum-driven `switch` dispatch that routes to icon + label + optional action, using `S.of(context)` for all copy. The `sync_status_badge.dart` pattern matches the 3-state design exactly.

**Enum definition pattern** (from `category_reorder_row.dart` line 7 — simplest enum-at-top-of-file pattern):
```dart
/// Three render variants for [ListEmptyState] (Phase 30, D-04/D-05).
enum ListEmptyVariant {
  /// No transactions in the selected month, no filters active.
  noData,
  /// Only a calendar day-filter active and no results on that day.
  dayEmpty,
  /// Any ledger/category/search/member filter active (regardless of day).
  filtered,
}
```

**Constructor change** (replaces existing `lib/features/list/presentation/widgets/list_empty_state.dart` line 15–16):
```dart
// BEFORE (binary):
const ListEmptyState({super.key, required this.isFilterActive});
final bool isFilterActive;

// AFTER (3-state):
const ListEmptyState({super.key, required this.variant});
final ListEmptyVariant variant;
```

**Switch dispatch pattern** (from `sync_status_badge.dart` lines 44–70):
```dart
@override
Widget build(BuildContext context, WidgetRef ref) {
  final (icon, message, actionLabel, onAction) = switch (variant) {
    ListEmptyVariant.noData => (
        Icons.receipt_long_outlined,
        S.of(context).listEmptyMonth,
        null,
        null,
      ),
    ListEmptyVariant.dayEmpty => (
        Icons.event_busy_outlined,
        S.of(context).listEmptyDay,
        S.of(context).listEmptyDayClear,
        () => ref.read(listFilterProvider.notifier).selectDay(null), // D-05 CRITICAL
      ),
    ListEmptyVariant.filtered => (
        Icons.search_off_outlined,
        S.of(context).listEmptyFiltered,
        S.of(context).listEmptyFilteredClear,
        () => ref.read(listFilterProvider.notifier).clearAll(),
      ),
  };
  // ... Column with icon, Text(message), optional TextButton(onAction)
}
```

**Render structure** (from existing `list_empty_state.dart` lines 21–62 — preserve layout, update dispatch):
```dart
return Center(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: AppColors.textTertiary),
        const SizedBox(height: 16),
        Text(
          message,
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.accentPrimary,
              ),
            ),
          ),
        ],
      ],
    ),
  ),
);
```

---

### `lib/features/list/presentation/screens/list_screen.dart` (screen, branching update)

**Analog:** Self-modification of lines 111–121.

**Current branching** (lines 111–121):
```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;

if (txs.isEmpty) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: ListEmptyState(isFilterActive: anyFilterActive),
  );
}
```

**New branching** (D-05 logic from RESEARCH.md lines 255–273 — `anyOtherFilter` takes priority):
```dart
// D-05: "other" filters = non-day filters
final anyOtherFilter = filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;

final variant = anyOtherFilter
    ? ListEmptyVariant.filtered
    : (filter.activeDayFilter != null
        ? ListEmptyVariant.dayEmpty
        : ListEmptyVariant.noData);

if (txs.isEmpty) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: ListEmptyState(variant: variant),
  );
}
```

**Also fix at line 101** — replace `'[data load error]'` with `S.of(context).listLoadError` (D-12):
```dart
// BEFORE:
Text('[data load error]', ...)

// AFTER:
Text(S.of(context).listLoadError, ...)
```

---

### `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` (config, ARB key block)

**Analog:** Self-modification after line 2205 in each file (`listEmptyFilteredClear` block).

**Insertion position** (verified: line 2206–2210 of each ARB file is the `@listEmptyFilteredClear` block followed by `"@@locale"`):
```json
  "listEmptyFilteredClear": "フィルターをクリア",
  "@listEmptyFilteredClear": {
    "description": "Clear filters action in filtered-empty state (Phase 28)"
  },
  // ← INSERT NEW KEYS HERE, before "@@locale"
  "@@locale": "ja"
}
```

**New keys — app_ja.arb** (D-06 + D-07 + D-12 + D-13, following `@`-metadata pattern from lines 2197–2208):
```json
  "listEmptyDay": "この日の記録はありません",
  "@listEmptyDay": {
    "description": "Empty state when day filter active and no transactions on that day (Phase 30)"
  },
  "listEmptyDayClear": "月全体を表示",
  "@listEmptyDayClear": {
    "description": "Clear day filter action in day-empty state (Phase 30)"
  },
  "listLoadError": "データを読み込めません",
  "@listLoadError": {
    "description": "Error state when list data fails to load (Phase 30)"
  },
  "listCalNavPrev": "前の月",
  "@listCalNavPrev": {
    "description": "Semantics label for previous month button in calendar header (Phase 30)"
  },
  "listCalNavNext": "次の月",
  "@listCalNavNext": {
    "description": "Semantics label for next month button in calendar header (Phase 30)"
  },
  "listCalNavCurrentMonth": "今月に戻る",
  "@listCalNavCurrentMonth": {
    "description": "Semantics label for return to current month gesture in calendar header (Phase 30)"
  }
```

**New keys — app_zh.arb:**
```json
  "listEmptyDay": "这一天没有记录",
  "listEmptyDayClear": "显示整月",
  "listLoadError": "无法加载数据",
  "listCalNavPrev": "上个月",
  "listCalNavNext": "下个月",
  "listCalNavCurrentMonth": "返回本月"
```
(with identical `@`-metadata format)

**New keys — app_en.arb:**
```json
  "listEmptyDay": "No records on this day",
  "listEmptyDayClear": "Show full month",
  "listLoadError": "Unable to load data",
  "listCalNavPrev": "Previous month",
  "listCalNavNext": "Next month",
  "listCalNavCurrentMonth": "Return to current month"
```
(with identical `@`-metadata format)

**Keys to update in-place (value change only, key unchanged):**

`listMineOnly` (line 2152 of all 3 files — D-07):
- ja: `"Mine only"` → `"自分のみ"`
- zh: `"Mine only"` → `"仅自己"`
- en: `"Mine only"` → `"Mine only"` (no change)

`listEmptyMonth` (line 2197 of all 3 files — D-06):
- ja: `"この月の記録はありません"` → `"この月にはまだ記録がありません"`
- zh: `"本月暂无记录"` → `"本月还没有记录"`
- en: `"No entries this month"` → `"No records yet this month"`

`listEmptyFiltered` (line 2201 of en only — D-06):
- en: `"No entries match your filters"` → `"No records match your filters"`
- ja/zh: already match D-04 table; no change needed

---

### `lib/features/list/presentation/widgets/list_calendar_header.dart` (component, Semantics labels)

**Analog:** Self-modification at lines 220–253.

**Current hardcoded labels** (lines 220–253):
```dart
Semantics(label: 'Previous month', ...)     // line 221
Semantics(label: 'Return to current month', ...) // line 236
Semantics(label: 'Next month', ...)         // line 253
```

**Replacement pattern** (add `final l10n = S.of(context);` if not already in scope; from `list_calendar_header.dart` line 42 where `l10n` is already declared):
```dart
// l10n = S.of(context) is already declared at line 42 of CalendarHeaderWidget.build
// The _MonthNavRow subwidget at line ~205+ does NOT have context access to S.of(context)
// — either pass the l10n or the resolved strings as constructor params

// Option A: pass resolved strings from CalendarHeaderWidget.build (recommended)
_MonthNavRow(
  filter: filter,
  locale: locale,
  onPrevMonth: ...,
  onNextMonth: ...,
  onLabelTap: ...,
  prevLabel: S.of(context).listCalNavPrev,       // new param
  nextLabel: S.of(context).listCalNavNext,       // new param
  currentMonthLabel: S.of(context).listCalNavCurrentMonth, // new param
)

// Option B: add BuildContext to _MonthNavRow.build (makes it use S.of(context) directly)
// — either approach is consistent with existing codebase patterns
```

**Semantics replacement in `_MonthNavRow.build`** (lines 220–253):
```dart
// BEFORE:
Semantics(label: 'Previous month', child: ...)
Semantics(label: 'Return to current month', child: ...)
Semantics(label: 'Next month', child: ...)

// AFTER:
Semantics(label: prevLabel, child: ...)         // or S.of(context).listCalNavPrev
Semantics(label: currentMonthLabel, child: ...) // or S.of(context).listCalNavCurrentMonth
Semantics(label: nextLabel, child: ...)         // or S.of(context).listCalNavNext
```

---

### `test/widget/features/list/list_empty_state_test.dart` (test, widget — API migration)

**Analog:** Self-modification — replace `isFilterActive: bool` API with `variant: ListEmptyVariant` API.

**`_pumpEmptyState` signature change** (current lines 21–41):
```dart
// BEFORE:
Future<void> _pumpEmptyState(
  WidgetTester tester,
  ProviderContainer container, {
  required bool isFilterActive,
}) async {
  // ...
  child: ListEmptyState(isFilterActive: isFilterActive),

// AFTER:
Future<void> _pumpEmptyState(
  WidgetTester tester,
  ProviderContainer container, {
  required ListEmptyVariant variant,
}) async {
  // ...
  child: ListEmptyState(variant: variant),
```

**3-variant test cases** (replacing current 2-case group at lines 43–69):
```dart
testWidgets('noData — receipt_long_outlined icon, no action button', (tester) async {
  final container = ProviderContainer.test();
  await _pumpEmptyState(tester, container, variant: ListEmptyVariant.noData);
  expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
  expect(find.byType(TextButton), findsNothing);
});

testWidgets('dayEmpty — event_busy_outlined icon + "show full month" TextButton', (tester) async {
  final container = ProviderContainer.test();
  await _pumpEmptyState(tester, container, variant: ListEmptyVariant.dayEmpty);
  expect(find.byIcon(Icons.event_busy_outlined), findsOneWidget);
  expect(find.byType(TextButton), findsOneWidget);
});

testWidgets('filtered — search_off_outlined icon + "clear filters" TextButton', (tester) async {
  final container = ProviderContainer.test();
  await _pumpEmptyState(tester, container, variant: ListEmptyVariant.filtered);
  expect(find.byIcon(Icons.search_off_outlined), findsOneWidget);
  expect(find.byType(TextButton), findsOneWidget);
});
```

---

### `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` (test, unit — day-only-clear case)

**Analog:** Self-modification — add one test after existing `selectDay with null clears activeDayFilter` test at line 60 (which already passes).

**New test case** (to add in the `listFilterProvider` group, after line 68):
```dart
test(
  'selectDay(null) clears day filter but preserves all other filter fields (D-05)',
  () {
    final container = ProviderContainer.test();
    final notifier = container.read(listFilterProvider.notifier);

    // Set all non-day filters to non-default values
    notifier.setLedgerFilter(LedgerType.soul);
    notifier.setCategories({'cat_food'});
    notifier.setSearch('ランチ');
    notifier.setMemberFilter('book_member_01');
    notifier.selectDay(DateTime(2025, 6, 10));

    // Clear ONLY the day filter
    notifier.selectDay(null);
    final state = container.read(listFilterProvider);

    // Day filter cleared
    expect(state.activeDayFilter, isNull);
    // All other filters preserved (D-05 requirement)
    expect(state.ledgerType, equals(LedgerType.soul));
    expect(state.categoryIds, equals({'cat_food'}));
    expect(state.searchQuery, equals('ランチ'));
    expect(state.memberBookId, equals('book_member_01'));
  },
);
```

---

## Shared Patterns

### Golden `_wrap` + localization delegates
**Source:** `test/golden/amount_display_golden_test.dart` lines 13–19 and `test/golden/per_category_breakdown_card_golden_test.dart` lines 63–71
**Apply to:** All 6 new golden test files

```dart
localizationsDelegates: const [
  S.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: S.supportedLocales,
theme: ThemeData.light(), // D-02: light theme only this phase
```

### Golden naming convention
**Source:** `test/golden/amount_display_golden_test.dart` lines 40, 56, 73
**Apply to:** All 6 new golden test files

```
goldens/list_<widget_name>_<locale>.png
goldens/list_empty_state_<variant>_<locale>.png  // 9 files: noData/dayEmpty/filtered × ja/zh/en
```

### `ProviderContainer.test()` in widget tests
**Source:** `test/widget/features/list/list_empty_state_test.dart` lines 48–49
**Apply to:** All widget test pump helpers

```dart
final container = ProviderContainer.test(); // auto-disposes on test teardown
```

### ARB `@`-metadata format
**Source:** `lib/l10n/app_ja.arb` lines 2197–2208
**Apply to:** All 6 new ARB keys in all 3 locale files

```json
"keyName": "value",
"@keyName": {
  "description": "Human-readable description (Phase 30)"
},
```

### `S.of(context)` usage
**Source:** `lib/features/list/presentation/widgets/list_empty_state.dart` lines 37–38
**Apply to:** All widget-level string references

```dart
S.of(context).listEmptyFiltered    // correct pattern
// Never: S(context).xxx or hardcoded strings
```

---

## No Analog Found

All files have direct analogs. No file in this phase requires building from scratch without a codebase pattern.

---

## Critical Pitfall Notes for Planner

1. **Day-empty uses `selectDay(null)`, not `clearAll()`** — `clearAll()` resets the month anchor. See `state_list_filter.dart:35`. The two actions are different and must not be conflated.

2. **Calendar golden MUST override `listFilterProvider` to past month** — `list_calendar_header.dart:142` calls `DateTime.now()` for `isToday` detection. Pin to `selectedYear: 2025, selectedMonth: 1`.

3. **`listEmptyState.dart` rework is a constructor-breaking change** — update both the widget AND `list_screen.dart` call site AND `list_empty_state_test.dart` in the same commit or the codebase won't compile.

4. **All 3 ARB files must be edited together** — `test/architecture/arb_key_parity_test.dart` enforces sorted key parity across all 3 locales. Partial edits will fail CI.

5. **Run `flutter gen-l10n` after ARB edits** before any widget code references new `S.of(context).listEmptyDay` etc. keys.

---

## Metadata

**Analog search scope:** `test/golden/`, `test/widget/features/list/`, `test/unit/features/list/`, `lib/features/list/`, `lib/features/family_sync/presentation/widgets/`, `lib/features/accounting/presentation/widgets/`, `lib/l10n/`
**Files scanned:** 14 source files read directly
**Pattern extraction date:** 2026-05-31
