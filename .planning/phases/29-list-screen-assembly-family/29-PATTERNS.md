# Phase 29: List Screen Assembly + Family — Pattern Map

**Mapped:** 2026-05-30
**Files analyzed:** 7 (5 edited + 2 new tests)
**Analogs found:** 7 / 7

> This is a seam-completion phase. All 5 production edits are in-file targeted changes.
> The pattern for each edit is the existing code in the same file, plus one codebase
> precedent for each new technique (shadow-book fan-out, RefreshIndicator).
> The 2 new test files copy the established list test scaffold verbatim.

---

## File Classification

| File | Change Kind | Role | Data Flow | Closest Analog | Match Quality |
|------|-------------|------|-----------|----------------|---------------|
| `lib/features/list/presentation/providers/state_list_transactions.dart` | EDIT seams ~L44-45, ~L103-106 | provider | request-response / CRUD | `lib/features/home/presentation/providers/state_shadow_books.dart` (`shadowAggregate`) — fan-out loop over shadow books | role-match |
| `lib/features/list/presentation/providers/state_calendar_totals.dart` | EDIT seam ~L30 | provider | CRUD / batch | same file (existing single-book pattern) + `state_shadow_books.dart` per-book loop | in-file + role-match |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | EDIT — add second trailing chip | widget | request-response | same file lines 134–145 (ledger tag `Container`) | in-file exact |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | EDIT — add family segment + fix `anyFilterActive` | widget | request-response / event-driven | same file lines 201–293 (ledger chips + `anyFilterActive` L128) | in-file exact |
| `lib/features/list/presentation/screens/list_screen.dart` | EDIT — `RefreshIndicator` + `anyFilterActive` fix + group gating | screen | request-response | `lib/features/analytics/presentation/screens/analytics_screen.dart` lines 80–90 (`RefreshIndicator` + `_refresh`) | role-match |
| `test/widget/features/list/list_screen_refresh_test.dart` | NEW test | widget test | — | `test/widget/features/list/list_sort_filter_bar_test.dart` (`_pumpBar` + `ProviderScope`) | role-match |
| `test/widget/features/list/list_sort_filter_bar_member_test.dart` | NEW test | widget test | — | `test/widget/features/list/list_sort_filter_bar_test.dart` (full file) | exact |

---

## Pattern Assignments

### `state_list_transactions.dart` — seam expansion (lines 44–45 + 103–106)

**In-file base pattern** — the existing provider body already establishes the
`ref.watch` chain, step-numbered comments, and `txs.map(...)` terminal expression.
Expand Step 3 and Step 7 by inserting shadow-book fan-out inline.

**Step 3 — current code (lines 44–45):**
```dart
// Step 3: own-book only (Phase 29: merge shadow books → bookIds + memberTag)
final bookIds = [bookId];
```

**Step 7 — current code (lines 102–106):**
```dart
// Step 7: wrap as TaggedTransaction
// Phase 29: fill memberTag from shadowBooks lookup
return txs
    .map((tx) => TaggedTransaction(transaction: tx, memberTag: null))
    .toList();
```

**Analog for shadow-book fan-out pattern** — `lib/features/home/presentation/providers/state_shadow_books.dart` lines 71–95 (`shadowAggregate` provider):
```dart
// Pattern: await ref.watch(shadowBooksProvider.future) then iterate
final shadowBookList = await ref.watch(shadowBooksProvider.future);
if (shadowBookList.isEmpty) return const ShadowAggregate.empty();
// ...
for (final shadow in shadowBookList) {
  final report = await reportUseCase.execute(bookId: shadow.book.id, ...);
  totalExpenses += report.totalExpenses;
  perBookReports[shadow.book.id] = report;
}
```

**Analog for isGroupMode gating** — `lib/features/analytics/presentation/screens/analytics_screen.dart` lines 62–67:
```dart
final isGroupMode = ref.watch(isGroupModeProvider);
final shadowBooksAsync = isGroupMode
    ? ref.watch(shadowBooksProvider).whenData<List<ShadowBookInfo>?>((v) => v)
    : const AsyncData<List<ShadowBookInfo>?>(null);
```

**What to copy into Step 3 (replaces `final bookIds = [bookId];`):**
```dart
// Step 3: own-book + shadow books in group mode (FAM-01)
final isGroup = ref.watch(isGroupModeProvider);
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future))
    : const <ShadowBookInfo>[];

final bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];
// Build lookup table once: shadowBookId → ShadowBookInfo (for memberTag fill, D-01)
final bookIdToShadow = {for (final s in shadowBookList) s.book.id: s};

// Member filter narrowing — SQL-level (D-02 preference)
// Reduces bookIds to one book when a member chip is selected.
final memberBookId = filter.memberBookId;
final effectiveBookIds = memberBookId != null
    ? (bookIds.contains(memberBookId) ? [memberBookId] : const <String>[])
    : bookIds;
```

**What to copy into Step 7 (replaces `.map((tx) => TaggedTransaction(...)`):**
```dart
// Step 7: wrap as TaggedTransaction; own-book rows → memberTag null (D-01/SC#3)
return txs.map((tx) {
  final shadow = bookIdToShadow[tx.transaction.bookId];
  return TaggedTransaction(
    transaction: tx,
    memberTag: shadow == null
        ? null
        : MemberTag(
            emoji: shadow.memberAvatarEmoji,
            name: shadow.memberDisplayName,
          ),
  );
}).toList();
```

**New imports to add** (to the existing import block at lines 1–12):
```dart
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import '../../domain/models/tagged_transaction.dart'; // already present — MemberTag is in this file
```

Pass `effectiveBookIds` (not `bookIds`) to `GetListParams.bookIds` in Step 4.

---

### `state_calendar_totals.dart` — multi-book sum (seam at line 30)

**In-file base pattern** — current provider body (lines 31–39):
```dart
final repo = ref.watch(analyticsRepositoryProvider);
final range = DateBoundaries.monthRange(year, month);
final totals = await repo.getDailyTotals(
  bookId: bookId,
  startDate: range.start,
  endDate: range.end,
  // type defaults to 'expense' — expense-only basis (D-09, Pitfall 6)
);
return {for (final t in totals) _dayKey(t.date): t.totalAmount};
```

**Analog for per-book loop + map merge** — `lib/features/home/presentation/providers/state_shadow_books.dart` lines 71–95 (`shadowAggregate` per-book loop):
```dart
for (final shadow in shadowBookList) {
  final report = await reportUseCase.execute(bookId: shadow.book.id, ...);
  totalExpenses += report.totalExpenses;      // integer accumulation
  perBookReports[shadow.book.id] = report;
}
```

**What to replace the seam block with (the entire body after the `// Phase 29: combine shadow books` comment):**
```dart
// CRITICAL: watch only (bookIds, year, month) — NEVER watch memberBookId/ledger/search
// Pitfall 3 / D-06: calendar always full-family combined, isolated from filter state
final isGroup = ref.watch(isGroupModeProvider);
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future))
    : const <ShadowBookInfo>[];

final allBookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];

final repo = ref.watch(analyticsRepositoryProvider);
final range = DateBoundaries.monthRange(year, month);

// Per-book calls (N = 1 solo; 2–5 family; ≤31 rows per book — fast enough, D-06)
final merged = <DateTime, int>{};
for (final bid in allBookIds) {
  final totals = await repo.getDailyTotals(
    bookId: bid,
    startDate: range.start,
    endDate: range.end,
    // type defaults to 'expense' (Pitfall 6)
  );
  for (final t in totals) {
    final k = _dayKey(t.date);
    merged[k] = (merged[k] ?? 0) + t.totalAmount;
  }
}
return merged;
```

**New imports to add:**
```dart
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
```

**Pitfall 3 compliance rule:** The provider's public signature `(bookId, year, month)` must NOT change. `isGroupModeProvider` and `shadowBooksProvider` are watched internally. `listFilterProvider` must NEVER appear here.

---

### `list_transaction_tile.dart` — member attribution chip (new second trailing element)

**In-file analog** — the existing ledger tag `Container` block (lines 133–145):
```dart
// Tag badge
Container(
  decoration: BoxDecoration(
    color: tagBgColor,
    borderRadius: BorderRadius.circular(3),
  ),
  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
  child: Text(
    tagText,
    style: AppTextStyles.micro.copyWith(color: tagTextColor),
  ),
),
const SizedBox(width: 8),
```

**What to insert between the `Expanded` info column and the amount** (after the existing `const SizedBox(width: 8)` at line 193, before the amount `Text` at line 195):
```dart
// Member attribution chip — second trailing element, only for shadow-book rows (D-01/SC#3)
// taggedTx.memberTag is null for own-book rows; no isOwn branch needed
if (taggedTx.memberTag case final tag?) ...[
  ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 72),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.sharedLight,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        '${tag.emoji} ${tag.name}',
        style: AppTextStyles.micro.copyWith(color: AppColors.shared),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
  const SizedBox(width: 8),
],
```

**Token notes:**
- `AppColors.sharedLight` — bg (warm peach, line 55 of `app_colors.dart`)
- `AppColors.shared` — text (terracotta, line 54)
- `AppTextStyles.micro` — 10px w700, same as ledger tag (no new style)
- `maxWidth: 72` — per UI-SPEC CC-1 truncation contract
- No constructor parameter changes — `taggedTx` already on the widget

---

### `list_sort_filter_bar.dart` — family segment + `anyFilterActive` fix

**In-file analog A — chip construction** (lines 201–260, ledger chip pattern):
```dart
Semantics(
  label: 'Survival ledger',
  selected: filter.ledgerType == LedgerType.survival,
  child: ActionChip(
    label: Text(
      l10n.listLedgerSurvival,
      style: AppTextStyles.caption.copyWith(
        color: filter.ledgerType == LedgerType.survival
            ? AppColors.survival
            : AppColors.textSecondary,
      ),
    ),
    backgroundColor: filter.ledgerType == LedgerType.survival
        ? AppColors.survivalLight
        : AppColors.card,
    side: BorderSide(
      color: filter.ledgerType == LedgerType.survival
          ? AppColors.survival
          : AppColors.borderDefault,
      width: 1,
    ),
    onPressed: () => ref
        .read(listFilterProvider.notifier)
        .setLedgerFilter(
          filter.ledgerType == LedgerType.survival ? null : LedgerType.survival,
        ),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
),
```

**In-file analog B — `anyFilterActive` declaration** (lines 128–131):
```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty;
```

**In-file analog C — conditional Clear chip guard** (lines 420–448):
```dart
if (anyFilterActive) ...[
  const SizedBox(width: 8),
  Semantics(
    label: 'Clear all filters',
    child: ActionChip(
      avatar: const Icon(Icons.clear_all, size: 14, color: AppColors.textSecondary),
      label: Text(l10n.listClearAll, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      backgroundColor: AppColors.backgroundMuted,
      side: const BorderSide(color: AppColors.borderDefault, width: 1),
      onPressed: () {
        ref.read(listFilterProvider.notifier).clearAll();
        setState(() { _searchExpanded = false; _searchController.clear(); });
      },
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  ),
],
```

**Fix 1 — `anyFilterActive` (line 128):** add 5th condition:
```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;       // FAM-03 fix (Pitfall B)
```

**Fix 2 — new `isGroupMode` watch in `build()`** (insert after `final sortConfig = filter.sortConfig;` at line 126):
```dart
final isGroupMode = ref.watch(isGroupModeProvider);
final shadowBooksAsync = isGroupMode
    ? ref.watch(shadowBooksProvider)
    : const AsyncData<List<ShadowBookInfo>>([]);
```

**New content to insert** — family segment between the search widget and the existing `if (anyFilterActive)` Clear chip block. Per UI-SPEC CC-2 the family segment is the last named group before Clear:
```dart
// ── Family segment (FAM-03/FAM-04) — group mode only (D-04 / CC-4) ──────
if (isGroupMode) ...[
  const SizedBox(width: 8),
  // Mine-only chip: always visible in group mode (SC#5); prominent unselected look
  ActionChip(
    avatar: Icon(
      Icons.person_outline,
      size: 14,
      color: filter.memberBookId == widget.bookId
          ? AppColors.textPrimary
          : AppColors.textSecondary,
    ),
    label: Text(
      S.of(context).listMineOnly,       // new ARB key (placeholder: "Mine only")
      style: AppTextStyles.caption.copyWith(color: AppColors.textPrimary),
    ),
    backgroundColor: AppColors.backgroundMuted,
    side: const BorderSide(color: AppColors.borderDefault, width: 1),
    onPressed: () => ref
        .read(listFilterProvider.notifier)
        .setMemberFilter(
          filter.memberBookId == widget.bookId ? null : widget.bookId,
        ),
    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
  ),
  const SizedBox(width: 4),
  // Per-member chips: one per shadow book
  ...shadowBooksAsync.when(
    data: (shadows) => shadows.map((info) {
      final isSelected = filter.memberBookId == info.book.id;
      return Padding(
        padding: const EdgeInsets.only(right: 4),
        child: ActionChip(
          label: Text(
            '${info.memberAvatarEmoji} ${info.memberDisplayName}',
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? AppColors.shared : AppColors.textSecondary,
            ),
          ),
          backgroundColor: isSelected ? AppColors.sharedLight : AppColors.card,
          side: BorderSide(
            color: isSelected ? AppColors.sharedBorder : AppColors.borderDefault,
            width: 1,
          ),
          onPressed: () => ref
              .read(listFilterProvider.notifier)
              .setMemberFilter(isSelected ? null : info.book.id),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      );
    }).toList(),
    loading: () => const [],
    error: (_, __) => const [],
  ),
],
```

**New imports to add:**
```dart
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
```

**Note on `widget.bookId`:** the bar is a `ConsumerStatefulWidget`; `widget.bookId` is already accessible in `_ListSortFilterBarState`. Use it as the own-book ID for Mine-only.

---

### `list_screen.dart` — `RefreshIndicator` + `anyFilterActive` fix + group gating

**External analog** — `lib/features/analytics/presentation/screens/analytics_screen.dart`:

`RefreshIndicator` host (lines 80–90):
```dart
body: RefreshIndicator(
  onRefresh: () async => _refresh(ref, ...),
  child: SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    child: Column(...),
  ),
),
```

`_refresh` void helper pattern (lines 214–220):
```dart
void _refresh(WidgetRef ref, { required ..., }) {
  ref.invalidate(monthlyReportProvider(...));
  ref.invalidate(expenseTrendProvider(...));
  // ...
}
```

**In-file analog — existing `invalidateAfterMutation()` local function** (lines 174–183):
```dart
void invalidateAfterMutation() {
  ref.invalidate(listTransactionsProvider(bookId: bookId));
  ref.invalidate(
    calendarDailyTotalsProvider(
      bookId: bookId,
      year: filter.selectedYear,
      month: filter.selectedMonth,
    ),
  );
}
```

**Fix 1 — `anyFilterActive` in `_buildList`** (line 91–94): add 5th condition (same fix as bar):
```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;       // FAM-03 fix (Pitfall B)
```

**Fix 2 — `RefreshIndicator` wrapping `_buildList`'s return**: wrap the entire `txsAsync.when(...)` block. `loading` and `error` branches need `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics())` wrappers so the pull gesture fires when content is short (Pitfall E).

```dart
Widget _buildList(
  BuildContext context,
  WidgetRef ref,
  ListFilterState filter,
  Locale locale,
) {
  final txsAsync = ref.watch(listTransactionsProvider(bookId: bookId));
  return RefreshIndicator(
    color: AppColors.accentPrimary,
    onRefresh: () async {
      ref.invalidate(listTransactionsProvider(bookId: bookId));
      ref.invalidate(calendarDailyTotalsProvider(
        bookId: bookId,
        year: filter.selectedYear,
        month: filter.selectedMonth,
      ));
      // Await re-settlement so spinner dismisses honestly (Pitfall F)
      await ref
          .read(listTransactionsProvider(bookId: bookId).future)
          .catchError((_) => <TaggedTransaction>[]);
    },
    child: txsAsync.when(
      loading: () => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: const Center(child: CircularProgressIndicator(
          color: AppColors.accentPrimary, strokeWidth: 2)),
      ),
      error: (err, st) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Center(child: /* existing error widget */),
      ),
      data: (txs) {
        // ... existing data branch with anyFilterActive fix ...
        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),   // ADD THIS
          itemCount: items.length,
          itemBuilder: ...,
        );
      },
    ),
  );
}
```

---

## Shared Patterns

### Provider watch for shadow books + group mode
**Source:** `lib/features/home/presentation/providers/state_shadow_books.dart` lines 24–41 (provider definition) and lines 71–95 (`shadowAggregate` usage)
**Apply to:** `state_list_transactions.dart` Step 3, `state_calendar_totals.dart` body

```dart
// Pattern: conditional await on shadowBooksProvider.future
final isGroup = ref.watch(isGroupModeProvider);     // keepAlive, always sync
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future)) // auto-dispose, reactive
    : const <ShadowBookInfo>[];
```

Key point: use `ref.watch` (not `ref.read`) so provider rebuilds when shadow list changes (new member joins).

### ActionChip toggle pattern (selected/unselected states)
**Source:** `list_sort_filter_bar.dart` lines 230–260 (survival ledger chip)
**Apply to:** Mine-only chip + member chips in `list_sort_filter_bar.dart`

Toggle on-press idiom:
```dart
onPressed: () => ref.read(listFilterProvider.notifier).setXxx(
  currentValue == targetValue ? null : targetValue,  // tap selected = deselect
),
```

### `anyFilterActive` 5-condition form
**Source:** `list_screen.dart` line 91 + `list_sort_filter_bar.dart` line 128 (both need the same fix)
**Apply to:** both files in the same commit

```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;    // Phase 29 addition
```

### `ref.invalidate` after mutation
**Source:** `list_screen.dart` lines 174–183 (`invalidateAfterMutation`)
**Apply to:** `RefreshIndicator.onRefresh` in `list_screen.dart`

Identical pair of invalidations: `listTransactionsProvider(bookId: bookId)` + `calendarDailyTotalsProvider(bookId, year, month)`.

### Chip container (ledger tag style)
**Source:** `list_transaction_tile.dart` lines 133–145
**Apply to:** member attribution chip in the same file

Exact construction: `Container` + `BoxDecoration(color: ..., borderRadius: BorderRadius.circular(3))` + `EdgeInsets.symmetric(horizontal: 6, vertical: 1)` + `Text(style: AppTextStyles.micro.copyWith(color: ...))`.

---

## New Test Files — Pattern Assignments

### `test/widget/features/list/list_screen_refresh_test.dart` (NEW)

**Analog:** `test/widget/features/list/list_sort_filter_bar_test.dart` (full file)

**Pump helper pattern** (from `list_sort_filter_bar_test.dart` lines 24–49):
```dart
Future<ProviderContainer> _pumpBar(WidgetTester tester) async {
  late ProviderContainer container;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        locale_providers.currentLocaleProvider
            .overrideWith((_) async => const Locale('ja')),
      ],
      child: Builder(
        builder: (ctx) {
          container = ProviderScope.containerOf(ctx);
          return MaterialApp(
            localizationsDelegates: S.localizationsDelegates,
            supportedLocales: S.supportedLocales,
            locale: const Locale('ja'),
            home: const Scaffold(body: /* widget under test */),
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
```

**Additional mocks needed for `list_screen_refresh_test`:**
- Mock `getListTransactionsUseCaseProvider` (as in `list_transactions_provider_test.dart`)
- Mock `isGroupModeProvider` — `isGroupModeProvider.overrideWithValue(false)` for solo tests; `overrideWithValue(true)` + mock `shadowBooksProvider` for group tests
- Mock `analyticsRepositoryProvider` for `calendarDailyTotalsProvider`

**Key assertions to write:**
1. `find.byType(RefreshIndicator)` — widget present
2. `tester.fling(find.byType(ListView), Offset(0, 300), 1000)` + `pumpAndSettle` → verify `ref.invalidate` calls fire (via `verify(() => mockUseCase.execute(any())).called(greaterThan(1))`)

### `test/widget/features/list/list_sort_filter_bar_member_test.dart` (NEW)

**Analog:** `test/widget/features/list/list_sort_filter_bar_test.dart` (exact scaffold)

**Pump helper** — copy `_pumpBar` from `list_sort_filter_bar_test.dart` and add two extra overrides:
```dart
isGroupModeProvider.overrideWithValue(true),
shadowBooksProvider.overrideWith(
  (ref) async => [
    ShadowBookInfo(
      book: _stubBook('shadow-1'),
      memberDisplayName: '太郎',
      memberAvatarEmoji: '🐻',
    ),
  ],
),
```

**Key assertions to write:**
1. `find.text('Mine only')` — Mine-only chip always visible in group mode (SC#5)
2. `tester.tap(find.text('🐻 太郎'))` → `container.read(listFilterProvider).memberBookId == 'shadow-1'`
3. `tester.tap(find.text('Mine only'))` → `memberBookId == 'book1'` (own bookId)
4. Set `memberBookId != null` in `listFilterProvider` override → `find.text(l10n.listClearAll)` visible (Pitfall B coverage)
5. Solo mode (`isGroupMode = false`) → `find.text('Mine only')` absent, `find.text('🐻 太郎')` absent

**Provider override pattern** for `_FixedListFilter` (from `list_transactions_provider_test.dart` lines 67–73):
```dart
class _FixedListFilter extends ListFilter {
  _FixedListFilter(this._fixed);
  final ListFilterState _fixed;
  @override
  ListFilterState build() => _fixed;
}
// Usage in overrides:
listFilterProvider.overrideWith(() => _FixedListFilter(ListFilterState(
  selectedYear: 2026,
  selectedMonth: 5,
  memberBookId: 'shadow-1',
))),
```

---

## No Analog Found

None. All 7 files have strong analogs either in-file or from a sibling file in the same feature.

---

## Metadata

**Analog search scope:** `lib/features/list/`, `lib/features/analytics/`, `lib/features/home/providers/`, `lib/features/family_sync/`, `test/widget/features/list/`, `test/unit/features/list/`
**Files read:** 13 source files + 4 test files
**Pattern extraction date:** 2026-05-30
