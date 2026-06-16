# Phase 44: 数据与用例补全 (Data / Use-Case Additions — reuse-first) - Pattern Map

**Mapped:** 2026-06-16
**Files analyzed:** 6 (2 NEW use-case/model, 2 MODIFY, 1 NEW shared pure helper, 1 MODIFY provider wiring + new family)
**Analogs found:** 6 / 6 (all exact or strong role-matches in-repo)

This is a **data/use-case-layer-only, reuse-first, Drift v21 (NO migration)** phase. Every new file has a strong in-repo analog. The only genuinely-new code is: 2 Freezed field additions, 1 new thin use case + its TDD test, 1 NEW Freezed model, and 1 shared pure L1-rollup helper. Everything else is reuse.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/application/analytics/get_category_drill_down_use_case.dart` **(NEW)** | use-case (Application) | request-response / read-aggregate | `lib/application/analytics/get_monthly_report_use_case.dart` (repo+category injection, categoryMap build) + `get_list_transactions_use_case.dart` (Dart-side filter) | role-match (compose two analogs) |
| `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` **(NEW, TDD-FIRST D-04)** | test | unit (in-memory Drift) | `test/unit/application/analytics/get_expense_trend_use_case_test.dart` | exact |
| `lib/features/analytics/domain/models/category_drill_down.dart` **(NEW)** | model (Domain, Freezed) | transform | `lib/features/analytics/domain/models/expense_trend.dart` (`ExpenseTrendData` list-carrying Freezed) | exact |
| `lib/features/analytics/domain/models/expense_trend.dart` **(MODIFY — D-08 +dailyTotal +joyTotal on `MonthlyTrend`)** | model (Domain, Freezed) | transform | self (existing `MonthlyTrend` fields) | exact |
| `lib/application/analytics/get_expense_trend_use_case.dart` **(MODIFY — D-08 per-ledger fetch)** | use-case (Application) | request-response / read-aggregate | self + `get_monthly_report_use_case.dart` lines 56-105 (getLedgerTotals + zero-default loop) | exact |
| L1-rollup pure helper **(NEW, D-11 — placement = planner's discretion; recommend `lib/features/analytics/domain/`)** | utility (pure transform) | transform | `_buildCategoryBreakdowns` in `get_monthly_report_use_case.dart` (L2-grain map+sum precedent) — but L1-parent rollup itself is net-new | partial (no exact rollup analog exists) |
| `lib/features/analytics/presentation/providers/repository_providers.dart` **(MODIFY — add drill use-case provider)** + new drill family in `state_analytics.dart` | provider (Presentation) | request-response | `repository_providers.dart` `getExpenseTrendUseCase` (line 56-61) + `state_analytics.dart` `monthlyReport`/`expenseTrend` families (auto-dispose) | exact |

## Pattern Assignments

### `lib/application/analytics/get_category_drill_down_use_case.dart` (NEW — use-case, read-aggregate)

**Primary analog:** `lib/application/analytics/get_monthly_report_use_case.dart` (constructor injection + categoryMap build)
**Secondary analog:** `lib/application/list/get_list_transactions_use_case.dart` (Dart-side category filter precedent, D-05)

**Constructor + injection pattern** — inject `TransactionRepository` (NOT `AnalyticsRepository`) + `CategoryRepository` (for parentId map). Mirror `GetMonthlyReportUseCase` lines 16-23:
```dart
class GetCategoryDrillDownUseCase {
  GetCategoryDrillDownUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
  }) : _txRepo = transactionRepository,
       _categoryRepo = categoryRepository;
  final TransactionRepository _txRepo;
  final CategoryRepository _categoryRepo;
```

**Window-fetch primitive (D-04)** — `TransactionRepository.findByBookIds`, VERIFIED signature (`transaction_repository.dart` lines 32-40). `bookIds` positional, rest named, `startDate`/`endDate` `required`, NO `categoryId` (L1 filter is Dart-side):
```dart
Future<List<Transaction>> findByBookIds(
  List<String> bookIds, {
  LedgerType? ledgerType,
  String? categoryId,            // pass null — D-05 filters Dart-side
  required DateTime startDate,
  required DateTime endDate,
  SortField sortField,
  SortDirection sortDirection,
});
```

**categoryMap build (copy from `get_monthly_report_use_case.dart` lines 71-74):**
```dart
final categories = await _categoryRepo.findAll();
final categoryMap = <String, Category>{};
for (final cat in categories) { categoryMap[cat.id] = cat; }
```

**Dart-side L1 filter (D-05 precedent — `get_list_transactions_use_case.dart` lines 54-56 comment).** Pitfall 2 (RESEARCH): a tx may be filed directly on the L1 OR on an L2 child. Compute "L1 ancestor of tx.categoryId":
```dart
// Category has parentId (nullable) + level (L1: level==1/parentId==null; L2: level==2)
// l1AncestorOf(catId): if level==1 → catId; if level==2 → parentId
final filtered = txns.where((tx) {
  final cat = categoryMap[tx.categoryId];
  final l1 = (cat?.level == 1) ? cat!.id : cat?.parentId;
  return l1 == l1CategoryId;
}).toList();
```

**Subtotal/count (D-11 / Pitfall 3):** do NOT re-sum `findByBookIds` rows for the summary number — consume the SAME shared L1-rollup helper the donut uses (single source-of-truth). The drill list shows individual txns; its summary `subtotal`/`count` come from the rollup entry for `l1CategoryId`.

---

### `test/unit/application/analytics/get_category_drill_down_use_case_test.dart` (NEW — TDD-FIRST, D-04)

**Analog:** `test/unit/application/analytics/get_expense_trend_use_case_test.dart` (exact — mirror its harness)

**Seed harness (lines 17-49):** in-memory `AppDatabase.forTesting()` + real DAOs (`AnalyticsDao`, `CategoryDao`, `TransactionDao`) + `AnalyticsRepositoryImpl`. For drill, also need `TransactionRepositoryImpl` + `CategoryRepositoryImpl`.
```dart
database = AppDatabase.forTesting();
categoryDao = CategoryDao(database);
transactionDao = TransactionDao(database);
// seed L1 + L2 categories via categoryDao.insertCategory(level: 1 / level: 2, parentId: ...)
// seed transactions via transactionDao.insertTransaction(...)
```
**Category seed (lines 27-44):** `categoryDao.insertCategory(id, name, icon, color, level, isSystem, createdAt, [parentId])`. Seed BOTH an L1 and an L2-child-of-L1 to cover Pitfall 2.
**Transaction seed (lines 129-159):** `transactionDao.insertTransaction(id, bookId, deviceId, amount, type:'expense', categoryId, ledgerType:'daily'|'joy', timestamp, currentHash, createdAt, entrySource:'manual')`.
**Required RED cases (RESEARCH test map):** window+L1-filtered txns returned; correct subtotal/count; L1-direct AND L2-child both included; empty-window → empty. Write BEFORE the use-case code (D-04 locked).

---

### `lib/features/analytics/domain/models/category_drill_down.dart` (NEW — Freezed model)

**Analog:** `lib/features/analytics/domain/models/expense_trend.dart` (`ExpenseTrendData` — list-carrying Freezed)

**Recommended shape (RESEARCH; `avgPerDay` + sort = Claude's discretion):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'category_drill_down.freezed.dart';
// JSON optional — transient (auto-dispose provider). Omit fromJson unless a consumer needs it.

@freezed
abstract class CategoryDrillDown with _$CategoryDrillDown {
  const factory CategoryDrillDown({
    required List<Transaction> transactions,  // window+L1-filtered, sorted (planner: time-desc recommended)
    required int subtotal,                     // from shared L1-rollup helper (D-11 — same source as donut)
    required int count,
    int? avgPerDay,                            // optional (D-03; descriptive avg is ADR-012-safe)
  }) = _CategoryDrillDown;
}
```
`Transaction` domain model is import-safe in domain layer. Run `build_runner` after creating.

---

### `lib/features/analytics/domain/models/expense_trend.dart` (MODIFY — D-08)

**Analog:** self — existing `MonthlyTrend` factory (lines 8-18). Add two `required int` fields:
```dart
const factory MonthlyTrend({
  required int year,
  required int month,
  required int totalExpenses,
  required int totalIncome,
  required int dailyTotal,   // D-08 ADD
  required int joyTotal,     // D-08 ADD
}) = _MonthlyTrend;
```
**Pitfall (RESEARCH A1):** `MonthlyTrend` has `fromJson`/`toJson` — adding `required` fields breaks any persisted instance. Grep confirms transient (only built in-memory). Re-run `build_runner` (regenerates `.freezed.dart` + `.g.dart`). Update `expense_trend_test.dart` (86 LOC) for the new fields.

---

### `lib/application/analytics/get_expense_trend_use_case.dart` (MODIFY — D-08)

**Analog:** self (existing 6-month loop, lines 20-43) + `get_monthly_report_use_case.dart` lines 56-105 (getLedgerTotals call + zero-default extraction)

**Extension point** — inside the existing per-month loop (lines 20-43), add a `getLedgerTotals` call alongside `getMonthlyTotals`, using the SAME `(startDate, endDate, entrySourceFilter)` (RESEARCH Flag C correctness pitfall — don't derive across query boundaries). Repo method VERIFIED (`analytics_repository.dart` lines 34-39):
```dart
Future<List<LedgerTotal>> getLedgerTotals({
  required String bookId, required DateTime startDate,
  required DateTime endDate, EntrySource? entrySourceFilter,
});
```

**Zero-default extraction (COPY `get_monthly_report_use_case.dart` lines 97-105 — Pitfall 1):** `getLedgerTotals` omits zero-spend ledgers; pre-initialize to 0:
```dart
int dailyTotal = 0;
int joyTotal = 0;
for (final lt in ledgerTotals) {
  if (lt.ledgerType == 'daily') dailyTotal = lt.totalAmount;
  else if (lt.ledgerType == 'joy') joyTotal = lt.totalAmount;
}
```
Then add `dailyTotal`/`joyTotal` to the `MonthlyTrend(...)` ctor (lines 36-42). Note `ledgerType` stored values are `'daily'`/`'joy'` (NOT 生存/灵魂 — ADR-017). **D-09:** compute NO joy cross-period delta. Update `get_expense_trend_use_case_test.dart` (171 LOC) — add a joy-empty-month assertion.
**Discretion (D-08 / RESEARCH Flag C):** in-use-case loop (2 queries × 6 months) vs new repo `getMonthlyLedgerTotals` — both migration-free; planner picks.

---

### L1-rollup pure helper (NEW — D-11; placement = planner's discretion)

**Analog:** `_buildCategoryBreakdowns` in `get_monthly_report_use_case.dart` (lines 133-154) shows the L2-grain map+sum pattern — but **L1-parent rollup itself is genuinely new** (RESEARCH: grep for `rollup`/`parentId`/`level1` found only the per-category-joy "Other rollup", a different concept).

- **Input:** `List<CategoryBreakdown>` (L2-grain, from `MonthlyReport.categoryBreakdowns`) + `{categoryId → Category}` map for `parentId` lookup.
- **L1 ancestor rule (Category model VERIFIED — `category.dart` lines 20-21):** `level==1` → `id`; `level==2` → `parentId`.
- **Output:** L1-grain list, summed by L1 ancestor, sorted amount-desc, top-10 for donut.
- **Consumed by BOTH** the donut display transform (OVW-01) AND the drill summary subtotal/count (D-11) — one source-of-truth (Pitfall 3).
- **Recommended location (RESEARCH Open Q 3):** pure top-level function or extension in `lib/features/analytics/domain/` (no Flutter import; `CategoryBreakdown`/`Category` are domain types — domain placement avoids a layer violation). Add a dedicated unit test (covers OVW-01 + DRILL summary).

---

### Provider wiring (MODIFY `repository_providers.dart` + new family in `state_analytics.dart`)

**Use-case provider analog** — `repository_providers.dart` `getExpenseTrendUseCase` (lines 56-61). For drill, inject `transactionRepositoryProvider` + `categoryRepositoryProvider` (both in `lib/features/accounting/presentation/providers/repository_providers.dart`, already imported here line 21):
```dart
@riverpod
GetCategoryDrillDownUseCase getCategoryDrillDownUseCase(Ref ref) {
  return GetCategoryDrillDownUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}
```

**Drill family provider analog** — `state_analytics.dart` `monthlyReport`/`expenseTrend` families (lines 13-52). All `@riverpod` analytics providers are **auto-dispose by default** (D-14) and read NO `home/*` provider. New drill family key `(bookId/bookIds, startDate, endDate, l1CategoryId)`:
```dart
@riverpod
Future<CategoryDrillDown> categoryDrillDown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String l1CategoryId,
}) async {
  final useCase = ref.watch(getCategoryDrillDownUseCaseProvider);
  return useCase.execute(/* ... */);
}
```
**D-12 (Pitfall 4):** normalize `startDate`/`endDate` via `DateBoundaries` (e.g. `DateBoundaries.monthRange(year, month)` → `(start, end)`, VERIFIED `date_boundaries.dart` line 30) BEFORE they enter the family key tuple — the analytics shell already holds a normalized `TimeWindow`; pass its normalized bounds, never raw `DateTime.now()` microseconds.
**Riverpod 3 naming (CLAUDE.md):** `getCategoryDrillDownUseCase` fn → `getCategoryDrillDownUseCaseProvider`; `categoryDrillDown` fn → `categoryDrillDownProvider`. Run `build_runner` after edits (regenerates `.g.dart`).

## Shared Patterns

### Zero-default ledger extraction (Pitfall 1)
**Source:** `lib/application/analytics/get_monthly_report_use_case.dart` lines 97-105
**Apply to:** `GetExpenseTrendUseCase` (D-08). Pre-init `dailyTotal=0`/`joyTotal=0`; `getLedgerTotals` omits zero-spend ledger rows.

### Dart-side category filter (D-05)
**Source:** `lib/application/list/get_list_transactions_use_case.dart` lines 54-61 (`categoryId: null` + comment "multi-category filtering is Dart-side")
**Apply to:** `GetCategoryDrillDownUseCase` — fetch window via `findByBookIds(categoryId: null)`, then `.where` on L1 ancestor. NO new DAO/SQL, NO `(book_id, category_id, timestamp)` index (D-06).

### categoryMap build for parentId/name lookup
**Source:** `lib/application/analytics/get_monthly_report_use_case.dart` lines 71-74
**Apply to:** drill use case + L1-rollup helper (both need `{id → Category}` for parentId/level).

### Provider family key normalization (D-12)
**Source:** `lib/shared/utils/date_boundaries.dart` (`DateBoundaries.monthRange`/`dayRange`, lines 30/48) + `state_analytics.dart` families
**Apply to:** the new drill family — normalize window bounds before the key tuple to avoid rebuild storm.

### Auto-dispose + Home isolation (D-14 / GUARD-01)
**Source:** `lib/features/analytics/presentation/providers/state_analytics.dart` (all `@riverpod` = auto-dispose; none read `home/*`)
**Apply to:** drill family + drill use-case provider. Structural lock asserted by `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart`.

### Anti-toxicity wording (D-03, surfaced Phase 46/47 — note only)
**Source:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` + `..._phase17_test.dart`
**Note for planner:** drill summary copy must be ADR-012-safe (no target/cross-period/ranking/judgmental wording). Data layer carries no copy; this is a Phase 46/47 concern but the full `flutter test` per-wave gate must include these scans.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| L1-rollup pure helper (partial) | utility | transform | No existing L1-parent rollup in codebase (only a per-category-joy "Other" fold, a different concept). The map+sum *mechanics* mirror `_buildCategoryBreakdowns`, but the L1-parent aggregation is net-new pure code. Closest mechanical precedent cited above. |

## Metadata

**Analog search scope:** `lib/application/analytics/`, `lib/application/list/`, `lib/features/analytics/{domain,presentation}/`, `lib/features/accounting/domain/`, `lib/shared/utils/`, `test/unit/application/analytics/`
**Files scanned:** ~14 source/test files read or grepped (all VERIFIED against committed source via RESEARCH.md this session)
**Pattern extraction date:** 2026-06-16

**Cross-cutting gotchas for planner (from RESEARCH + CLAUDE.md):**
- Riverpod 3 provider-name generation strips `UseCase`/`Notifier` suffix.
- `flutter pub run build_runner build --delete-conflicting-outputs` required after every Freezed/Riverpod edit.
- ADR-017 生存/灵魂 grep-ban on new identifiers — use `daily`/`joy` (stored `ledger_type` is `'daily'`/`'joy'`; `LedgerType.survival/soul` enum values intentionally retained).
- D-13: Drift schema stays v21 — NO migration, NO new DAO/index. Decorative `idx_tx_book_timestamp` (never emitted) is a non-blocking tech-debt note ONLY, NOT a Phase 44 task.
- Per-day-joy heatmap data is deferred to Phase 46 (RESEARCH Flag A) — note in PLAN so it is not silently dropped.
