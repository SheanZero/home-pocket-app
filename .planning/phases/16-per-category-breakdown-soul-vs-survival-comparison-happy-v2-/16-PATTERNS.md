# Phase 16 — Pattern Map

> Closest existing analog in the codebase for each new/modified file. Excerpts are paste-ready guidance for plan `<read_first>` + `<action>` fields. All line citations were verified by reading the cited file at the cited range.

**Mapped:** 2026-05-20
**Files analyzed:** 27 (24 NEW + 3 MODIFIED)
**Analogs found:** 26 / 27 (one novel — see Files Without Close Analogs)

---

## File Inventory

| # | Path | Role | Layer | Analog (file:lines) | Match |
|---|------|------|-------|---------------------|-------|
| 1 | `lib/data/daos/analytics_dao.dart` (extend) | dao | data | self (existing methods 82, 214-241, 244-272, 410-444) | exact |
| 2 | `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` | domain-model | domain | `lib/features/analytics/domain/models/shared_joy_insight.dart:1-14` | exact |
| 3 | `lib/features/analytics/domain/models/ledger_snapshot.dart` | domain-model | domain | `lib/features/analytics/domain/models/shared_joy_insight.dart` + `lib/features/analytics/domain/models/analytics_aggregate.dart:28-44` | role-match |
| 4 | `lib/features/analytics/domain/repositories/analytics_repository.dart` (extend) | repository | domain | self (interface methods at 28-67) | exact |
| 5 | `lib/data/repositories/analytics_repository_impl.dart` (extend) | repository | data | self (existing impls at 80-99, 102-117, 178-188) | exact |
| 6 | `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart` | use-case | application | `lib/application/analytics/get_satisfaction_distribution_use_case.dart:1-25` | role-match |
| 7 | `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` | use-case | application | `lib/application/analytics/get_family_happiness_use_case.dart:14-106` | role-match |
| 8 | `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart` | use-case | application | `lib/application/analytics/get_satisfaction_distribution_use_case.dart` + `get_family_happiness_use_case.dart:42-65` (parallel Future.wait) | role-match |
| 9 | `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart` | use-case | application | `lib/application/analytics/get_family_happiness_use_case.dart:23-106` | role-match |
| 10 | `lib/features/analytics/presentation/providers/repository_providers.dart` (extend) | provider | presentation | self (lines 36-106, four use-case providers) | exact |
| 11 | `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` (NEW) | provider | presentation | `lib/features/analytics/presentation/providers/state_happiness.dart:14-30` (window-keyed) + `:86-109` (group-mode) | exact |
| 12 | `lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` | widget | presentation | `lib/features/analytics/presentation/widgets/family_insight_card.dart:12-84` (chrome) + `category_spend_donut_chart.dart:71-103` (top-N + Other) | role-match |
| 13 | `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` | widget | presentation | `lib/features/analytics/presentation/widgets/family_insight_card.dart:12-84` (chrome) | role-match |
| 14 | `lib/l10n/app_en.arb` (extend) | arb | i18n | self (lines 1860-1949 analytics keys) | exact |
| 15 | `lib/l10n/app_ja.arb` (extend) | arb | i18n | self (parity with app_en.arb) | exact |
| 16 | `lib/l10n/app_zh.arb` (extend) | arb | i18n | self (parity with app_en.arb) | exact |
| 17 | `test/unit/data/daos/analytics_dao_per_category_test.dart` | test-unit | data | `test/unit/data/daos/analytics_dao_happiness_test.dart:1-86` | exact |
| 18 | `test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart` | test-unit | data | `test/unit/data/daos/analytics_dao_happiness_test.dart:1-86` | exact |
| 19 | `test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart` | test-unit | application | `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart` (full) | exact |
| 20 | `test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart` | test-unit | application | `test/unit/application/analytics/get_family_happiness_use_case_test.dart:1-100` | exact |
| 21 | `test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart` | test-unit | application | `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart` | exact |
| 22 | `test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart` | test-unit | application | `test/unit/application/analytics/get_family_happiness_use_case_test.dart` | exact |
| 23 | `test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` | test-widget | presentation | `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:1-120` | exact |
| 24 | `test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` | test-widget | presentation | `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:1-120` | exact |
| 25 | `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` | test-widget | presentation | `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` (locale loop) — **no exact analog for substring-absence sweep** | partial / novel |
| 26 | `test/golden/per_category_breakdown_card_golden_test.dart` + `test/golden/soul_vs_survival_card_golden_test.dart` | test-golden | presentation | `test/golden/amount_display_golden_test.dart:1-79` | exact |
| 27 | `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (extend) | test-widget | presentation | self (lines 122-250 — entire scaffolding pattern) | exact |
| 28 | `lib/features/analytics/presentation/screens/analytics_screen.dart` (extend) | screen-integration | presentation | self (lines 105-121 Distribution composition + 160-213 `_refresh()`) | exact |
| 29 | `.planning/ROADMAP.md` SC-3 wording (modify) | doc-update | docs | self (other Phase SCs in same file) | exact |

---

## Detailed Mappings

### 1. `lib/data/daos/analytics_dao.dart` — extend with 4 new methods

**Role:** dao (data layer)
**Analog (in-file):**
- `getSharedJoyCategoryInsight` — `lib/data/daos/analytics_dao.dart:410-444` (multi-book GROUP BY category_id + tie-break)
- `getSoulSatisfactionOverview` — `lib/data/daos/analytics_dao.dart:244-272` (window-aware soul-only AVG)
- `getLedgerTotals` — `lib/data/daos/analytics_dao.dart:214-241` (GROUP BY ledger_type)
- `_soulExpenseFilter` constant — `lib/data/daos/analytics_dao.dart:82-83`

**Methods to add:**
1. `getPerCategorySoulBreakdown({bookId, startDate, endDate}) → Future<List<PerCategorySoulRow>>`
2. `getPerCategorySoulBreakdownAcrossBooks({bookIds, startDate, endDate}) → Future<List<PerCategorySoulRow>>`
3. `getLedgerSnapshot({bookId, startDate, endDate}) → Future<List<LedgerSnapshotRow>>` (SUM + COUNT per ledger_type)
4. `getLedgerSnapshotAcrossBooks({bookIds, startDate, endDate}) → Future<List<LedgerSnapshotRow>>`
5. NEW constant: `_survivalExpenseFilter` for symmetry / single-source-of-truth (parallel to `_soulExpenseFilter` at line 82-83 — see RESEARCH `code_context` §"Established Patterns")

**Pattern excerpt — single-book sort (mirrors line 410-444 minus LIMIT 1, no HAVING — Dart applies min-N):**
```dart
// Source: lib/data/daos/analytics_dao.dart:410-444 (getSharedJoyCategoryInsight)
Future<List<PerCategorySoulRow>> getPerCategorySoulBreakdown({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ? '
        'GROUP BY category_id '
        'ORDER BY avg_sat DESC, cnt DESC, category_id ASC',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();
  return results.map((row) => PerCategorySoulRow(
    categoryId: row.read<String>('category_id'),
    avgSatisfaction: row.read<double>('avg_sat'),
    totalCount: row.read<int>('cnt'),
  )).toList();
}
```

**Pattern excerpt — across-books (mirrors line 415-433 placeholders pattern):**
```dart
// Source: lib/data/daos/analytics_dao.dart:415-433
if (bookIds.isEmpty) return const [];
final placeholders = List.filled(bookIds.length, '?').join(', ');
// ...
'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
// ...
variables: [
  ...bookIds.map(Variable.withString),
  Variable.withDateTime(startDate),
  Variable.withDateTime(endDate),
],
```

**Pattern excerpt — ledger snapshot (mirrors line 214-241 + adds COUNT):**
```dart
// Source: lib/data/daos/analytics_dao.dart:214-241 (getLedgerTotals)
// Phase 16 adds COUNT(*) — single query, three columns.
final results = await _db.customSelect(
  'SELECT ledger_type, SUM(amount) as total, COUNT(*) as cnt FROM transactions '
  "WHERE book_id = ? AND is_deleted = 0 AND type = 'expense' "
  'AND timestamp >= ? AND timestamp <= ? '
  'GROUP BY ledger_type',
  variables: [
    Variable.withString(bookId),
    Variable.withDateTime(startDate),
    Variable.withDateTime(endDate),
  ],
).get();
```

**Adaptation notes for Phase 16:**
- Define `_survivalExpenseFilter` mirroring `_soulExpenseFilter` at line 82-83 — RESEARCH calls this out as anti-predicate-drift hygiene.
- Do NOT add `HAVING COUNT(*) >= 3` to the DAO — use case applies min-N in Dart per RESEARCH R1 (pitfall: HAVING hides low-N rows the "Other" fold needs).
- Add new row types `PerCategorySoulRow` and `LedgerSnapshotRow` at the top of the file alongside existing `LedgerTotalResult` (lines 40-48) and `SatisfactionOverviewResult` (lines 50-59) declarations.
- All queries use `Variable.withString` / `Variable.withDateTime` — never string concatenation (V5 input validation contract).

---

### 2. `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` (NEW)

**Role:** domain-model (domain layer)
**Analog:** `lib/features/analytics/domain/models/shared_joy_insight.dart:1-14` — exact

**Pattern excerpt:**
```dart
// Source: lib/features/analytics/domain/models/shared_joy_insight.dart:1-14
import 'package:freezed_annotation/freezed_annotation.dart';

part 'shared_joy_insight.freezed.dart';

/// FAMILY-02 / D-08 anti-leaderboard tuple.
/// Per-person breakdowns are forbidden by contract.
@freezed
abstract class SharedJoyInsight with _$SharedJoyInsight {
  const factory SharedJoyInsight({
    required String categoryId,
    required double avgSatisfaction,
    required int totalCount,
  }) = _SharedJoyInsight;
}
```

**Adaptation notes for Phase 16:**
- Define BOTH `PerCategorySoulRow` (item shape, identical fields to `SharedJoyInsight`) AND the wrapper aggregate `PerCategorySoulBreakdown { items, totalCount, otherCount, otherCategoryCount }` in the same file.
- Use `abstract class X with _$X` (the v3 Freezed pattern) — matches the analog exactly.
- Header doc-comment must reference D-07 (sort) + D-08 (Other fold) + ADR-012 §6 (no per-member).

---

### 3. `lib/features/analytics/domain/models/ledger_snapshot.dart` (NEW)

**Role:** domain-model (domain layer)
**Analog:** `lib/features/analytics/domain/models/shared_joy_insight.dart` (Freezed shape) + RESEARCH R4 (type-system gate design)

**Pattern excerpt (composite from RESEARCH lines 838-874):**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'ledger_snapshot.freezed.dart';

// SOUL ledger sub-record (has avg satisfaction)
@freezed
abstract class SoulLedgerSnapshot with _$SoulLedgerSnapshot {
  const factory SoulLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
    required double avgSatisfaction,
  }) = _SoulLedgerSnapshot;
}

// SURVIVAL ledger sub-record (NO satisfaction field — D-04 type-system gate)
@freezed
abstract class SurvivalLedgerSnapshot with _$SurvivalLedgerSnapshot {
  const factory SurvivalLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
  }) = _SurvivalLedgerSnapshot;
}

@freezed
abstract class SoulVsSurvivalSnapshot with _$SoulVsSurvivalSnapshot {
  const factory SoulVsSurvivalSnapshot({
    required SoulLedgerSnapshot soul,
    required SurvivalLedgerSnapshot survival,
    SoulLedgerSnapshot? familySoul,         // null in solo mode
    SurvivalLedgerSnapshot? familySurvival, // null in solo mode
  }) = _SoulVsSurvivalSnapshot;
}
```

**Adaptation notes for Phase 16:**
- **CRITICAL D-04 gate:** `SurvivalLedgerSnapshot` MUST NOT carry `avgSatisfaction`. Any attempt to add it later is a compile error — this IS the structural enforcement of D-04 (RESEARCH §Pitfall 7).
- Group-mode (`familySoul`/`familySurvival`) fields default to null in solo mode and are populated only when both `isGroupMode && shadowBooks.length >= 2` (D-20).
- Doc-comment must explicitly reference D-04 above `SurvivalLedgerSnapshot` so future readers know why the asymmetry exists.
- After creating the file, run `flutter pub run build_runner build --delete-conflicting-outputs` (AUDIT-10 CI guardrail).

---

### 4. `lib/features/analytics/domain/repositories/analytics_repository.dart` — extend interface

**Role:** repository interface (domain layer)
**Analog:** self — existing method signatures at lines 28-67

**Pattern excerpt (mirrors line 63-67):**
```dart
// Source: lib/features/analytics/domain/repositories/analytics_repository.dart:63-67
/// FAMILY-02 / D-08 — category argmax across books with min-N=3 guard.
Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
});
```

**Methods to add (signatures only — no impl in this file):**
1. `Future<List<PerCategorySoulRow>> getPerCategorySoulBreakdown({required String bookId, required DateTime startDate, required DateTime endDate});`
2. `Future<List<PerCategorySoulRow>> getPerCategorySoulBreakdownAcrossBooks({required List<String> bookIds, required DateTime startDate, required DateTime endDate});`
3. `Future<List<LedgerSnapshotRow>> getLedgerSnapshot({required String bookId, required DateTime startDate, required DateTime endDate});`
4. `Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({required List<String> bookIds, required DateTime startDate, required DateTime endDate});`

**Adaptation notes for Phase 16:**
- Each new method gets a doc-comment in the same style as line 62 ("FAMILY-02 / D-08 — ...") — reference HAPPY-V2-01 / STATSUI-V2-01 + D-07 / D-04 as applicable.
- Add imports at top for new row types from `../models/per_category_soul_breakdown.dart` and `../models/ledger_snapshot.dart` (or surface the rows from `analytics_aggregate.dart` if planner prefers to keep raw row tuples there — pattern at lines 1-100 of `analytics_aggregate.dart` is `class XResult { ... }` plain classes).

---

### 5. `lib/data/repositories/analytics_repository_impl.dart` — extend with concrete delegations

**Role:** repository impl (data layer)
**Analog:** self — existing delegations at lines 80-99 (`getLedgerTotals`), 102-117 (`getSoulSatisfactionOverview`), 178-188 (`getSharedJoyCategoryInsight`)

**Pattern excerpt (mirrors line 80-99):**
```dart
// Source: lib/data/repositories/analytics_repository_impl.dart:80-99
@override
Future<List<LedgerTotal>> getLedgerTotals({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _dao.getLedgerTotals(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
  return results
      .map((row) => LedgerTotal(ledgerType: row.ledgerType, totalAmount: row.totalAmount))
      .toList();
}
```

**Adaptation notes for Phase 16:**
- One `@override` impl method per new interface method. Each delegates to the matching new DAO method (1-to-1).
- Convert DAO row types (e.g., `LedgerSnapshotRow` from DAO) to domain row types if the planner decides to keep them separate (see ARCH-001 layering: DAO returns raw rows; repository converts to domain types). Existing `getLedgerTotals` does this conversion at line 91-98.

---

### 6. `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart` (NEW)

**Role:** use case (application layer)
**Analog:** `lib/application/analytics/get_satisfaction_distribution_use_case.dart` (entire file, 1-25) — exact

**Pattern excerpt (full file):**
```dart
// Source: lib/application/analytics/get_satisfaction_distribution_use_case.dart:1-25
import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

/// STATSUI-02 / D-05 — satisfaction score buckets for the selected month.
class GetSatisfactionDistributionUseCase {
  GetSatisfactionDistributionUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<List<SatisfactionScoreBucket>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    TimeWindowValidation.assertValid(startDate, endDate);
    return _repo.getSatisfactionDistribution(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
```

**Adaptation notes for Phase 16:**
- Return type is `Future<MetricResult<PerCategorySoulBreakdown>>` (not a bare list) — wraps Empty/Value per `MetricResult<T>` sealed type at `lib/features/analytics/domain/models/metric_result.dart:16-29`.
- After fetching raw rows from `_repo.getPerCategorySoulBreakdown(...)`, apply Dart-side min-N split + sort per RESEARCH lines 422-447 (qualifying.sort by `b.avgSatisfaction.compareTo(a.avgSatisfaction)` → `b.totalCount.compareTo(a.totalCount)` → `a.categoryId.compareTo(b.categoryId)`).
- Build `PerCategorySoulBreakdown(items, totalCount, otherCount, otherCategoryCount)` and wrap in `Value(...)` when non-empty; return `const Empty()` when `qualifying.isEmpty && otherCount == 0`.
- First statement inside `execute()` MUST be `TimeWindowValidation.assertValid(startDate, endDate);` (Pitfall 1 — verified at `get_satisfaction_distribution_use_case.dart:18`, `get_family_happiness_use_case.dart:28`).
- Define private constants `static const int _minN = 3;` at top of class (RESEARCH line 404-405).

---

### 7. `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` (NEW)

**Role:** use case (application layer)
**Analog:** `lib/application/analytics/get_family_happiness_use_case.dart:14-106` (whole class — group-mode pattern with `groupBookIds` resolution upstream)

**Pattern excerpt (mirrors line 23-40 entry):**
```dart
// Source: lib/application/analytics/get_family_happiness_use_case.dart:23-40
Future<FamilyHappiness> execute({
  required List<String> groupBookIds,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  TimeWindowValidation.assertValid(startDate, endDate);

  // D-09 + D-16: empty short-circuit with no repository calls.
  if (groupBookIds.isEmpty) {
    return FamilyHappiness(
      year: endDate.year,
      month: endDate.month,
      totalGroupSoulTx: 0,
      familyHighlightsSum: const Empty(),
      sharedJoyInsight: const Empty(),
      medianSatisfaction: const Empty(),
    );
  }
  // ... call _repo.getSharedJoyCategoryInsight(bookIds: groupBookIds, ...)
}
```

**Adaptation notes for Phase 16:**
- Accepts `List<String> groupBookIds` (NOT `bookId`); presentation layer resolves `shadowBooksProvider` BEFORE invoking (verified pattern at `state_happiness.dart:97-98`).
- Returns `Future<MetricResult<PerCategorySoulBreakdown>>`.
- `if (groupBookIds.isEmpty)` → `return const Empty();` (matches D-16 + D-20 contract).
- Calls `_repo.getPerCategorySoulBreakdownAcrossBooks(bookIds: groupBookIds, ...)` then applies SAME Dart-side min-N split + sort as the single-book use case (extract a private helper for DRY).
- ADR-012 §6 / D-16 contract: no per-member fields are EVER constructed — type-system enforces this because `PerCategorySoulBreakdown` carries no `bookId` field.

---

### 8. `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart` (NEW)

**Role:** use case (application layer)
**Analog:** `lib/application/analytics/get_satisfaction_distribution_use_case.dart` (structure) + `lib/application/analytics/get_family_happiness_use_case.dart:42-65` (`Future.wait` parallel fetch)

**Pattern excerpt (mirrors family_happiness line 42-65 + research lines 892-933):**
```dart
// Source: lib/application/analytics/get_family_happiness_use_case.dart:42-65 (Future.wait pattern)
final overviews = await Future.wait(
  groupBookIds.map(
    (id) => _repo.getSoulSatisfactionOverview(
      bookId: id,
      startDate: startDate,
      endDate: endDate,
    ),
  ),
);
final distributions = await Future.wait(
  groupBookIds.map(
    (id) => _repo.getSatisfactionDistribution(...),
  ),
);
```

**Phase 16 shape:**
```dart
Future<MetricResult<SoulVsSurvivalSnapshot>> execute({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  TimeWindowValidation.assertValid(startDate, endDate);

  final results = await Future.wait([
    _repo.getLedgerSnapshot(bookId: bookId, startDate: startDate, endDate: endDate),
    _repo.getSoulSatisfactionOverview(bookId: bookId, startDate: startDate, endDate: endDate),
  ]);
  final ledgerRows = results[0] as List<LedgerSnapshotRow>;
  final soulSatOverview = results[1] as SoulSatisfactionOverview;

  final soulRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'soul');
  final survivalRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'survival');

  // D-05: EITHER ledger 0 entries → entire card Empty
  if (soulRow == null || soulRow.entryCount == 0 ||
      survivalRow == null || survivalRow.entryCount == 0) {
    return const Empty();
  }

  return Value(
    SoulVsSurvivalSnapshot(
      soul: SoulLedgerSnapshot(
        entryCount: soulRow.entryCount,
        totalSpend: soulRow.totalAmount,
        avgSatisfaction: soulSatOverview.avgSatisfaction,  // ONLY from _soulExpenseFilter — Pitfall 7
      ),
      survival: SurvivalLedgerSnapshot(
        entryCount: survivalRow.entryCount,
        totalSpend: survivalRow.totalAmount,
        // NO avgSatisfaction field — D-04 compile-time gate
      ),
    ),
    soulRow.entryCount + survivalRow.entryCount,
  );
}
```

**Adaptation notes for Phase 16:**
- D-05 gate is the FIRST conditional after fetch; do not partial-populate (matches `SharedJoyInsight` Empty semantics).
- The Soul `avgSatisfaction` value comes ONLY from `getSoulSatisfactionOverview` (which uses `_soulExpenseFilter` at `analytics_dao.dart:82`). **NEVER** call AVG over a Survival-scoped query — Pitfall 7 / RESEARCH line 626-638.
- `firstWhereOrNull` from `package:collection` — verify if already imported in `lib/application/analytics/` or fall back to `try/catch` or `.where(...).firstOrNull` (Dart 3 extension).

---

### 9. `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart` (NEW)

**Role:** use case (application layer)
**Analog:** `lib/application/analytics/get_family_happiness_use_case.dart:14-106` + use case #8 above

**Adaptation notes for Phase 16:**
- Accepts `List<String> groupBookIds`.
- Calls `_repo.getLedgerSnapshotAcrossBooks(bookIds: groupBookIds, ...)` plus a per-book soul avg satisfaction fetch (or extend the across-books DAO to compute it directly — planner discretion; pattern at family_happiness line 42-50 shows the per-book `Future.wait` loop).
- D-20 gate: caller (presentation) checks `groupBookIds.length < 2 → Empty`. Use case still guards `if (groupBookIds.isEmpty) return const Empty();` defensively.

---

### 10. `lib/features/analytics/presentation/providers/repository_providers.dart` — extend with 4 new use-case providers

**Role:** provider (presentation layer)
**Analog:** self — existing 4-line use-case provider declarations at lines 76-82 (Distribution), 84-90 (BestJoy), 92-98 (LargestExpense), 100-106 (FamilyHappiness)

**Pattern excerpt:**
```dart
// Source: lib/features/analytics/presentation/providers/repository_providers.dart:76-82
/// STATSUI-02 / D-05: GetSatisfactionDistributionUseCase provider.
@riverpod
GetSatisfactionDistributionUseCase getSatisfactionDistributionUseCase(Ref ref) {
  return GetSatisfactionDistributionUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Adaptation notes for Phase 16:**
- Add 4 new providers using IDENTICAL shape: `getPerCategorySoulBreakdownUseCase`, `getPerCategorySoulBreakdownAcrossBooksUseCase`, `getSoulVsSurvivalSnapshotUseCase`, `getSoulVsSurvivalSnapshotAcrossBooksUseCase`.
- Doc-comment `/// HAPPY-V2-01 / D-07: ...` and `/// STATSUI-V2-01 / D-01..D-05: ...` headers.
- Imports at top of file: add 4 new `import '../../../../application/analytics/get_*_use_case.dart';` lines (mirrors lines 4-12).
- After save: run `flutter pub run build_runner build --delete-conflicting-outputs` — the `.g.dart` will regenerate alongside.

---

### 11. `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` (NEW)

**Role:** provider (presentation layer — Riverpod 3 `@riverpod` Future providers)
**Analog (window-keyed):** `lib/features/analytics/presentation/providers/state_happiness.dart:14-30` (`happinessReportProvider`)
**Analog (group-mode):** `lib/features/analytics/presentation/providers/state_happiness.dart:86-109` (`familyHappinessProvider`)

**Pattern excerpt — window-keyed provider:**
```dart
// Source: lib/features/analytics/presentation/providers/state_happiness.dart:14-30
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/best_joy_moment_row.dart';
import '../../domain/models/analytics_aggregate.dart';
// ...
import 'repository_providers.dart';

part 'state_happiness.g.dart';

/// HAPPY-01..04 personal happiness report.
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    currencyCode: currencyCode,
  );
}
```

**Pattern excerpt — group-mode provider with `shadowBooksProvider`:**
```dart
// Source: lib/features/analytics/presentation/providers/state_happiness.dart:86-109
@riverpod
Future<FamilyHappiness> familyHappiness(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) {
    return _emptyFamilyHappiness(endDate: endDate);
  }

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((shadow) => shadow.book.id).toList();
  if (groupBookIds.isEmpty) {
    return _emptyFamilyHappiness(endDate: endDate);
  }

  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  return useCase.execute(
    groupBookIds: groupBookIds,
    startDate: startDate,
    endDate: endDate,
  );
}
```

**Adaptation notes for Phase 16:**
- File header:
  ```dart
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import '../../domain/models/per_category_soul_breakdown.dart';
  import '../../domain/models/ledger_snapshot.dart';
  import '../../domain/models/metric_result.dart';
  import '../../../family_sync/presentation/providers/state_active_group.dart';
  import '../../../home/presentation/providers/state_shadow_books.dart';
  import 'repository_providers.dart';

  part 'state_ledger_snapshot.g.dart';
  ```
- 4 providers to declare:
  1. `perCategorySoulBreakdown({bookId, startDate, endDate}) → Future<MetricResult<PerCategorySoulBreakdown>>`
  2. `perCategorySoulBreakdownFamily({startDate, endDate}) → Future<MetricResult<PerCategorySoulBreakdown>>`
  3. `soulVsSurvivalSnapshot({bookId, startDate, endDate}) → Future<MetricResult<SoulVsSurvivalSnapshot>>`
  4. `soulVsSurvivalSnapshotFamily({startDate, endDate}) → Future<MetricResult<SoulVsSurvivalSnapshot>>`
- D-20 gate in family providers: `if (groupBookIds.length < 2) return const Empty();` (RESEARCH lines 376-377; differs from `familyHappiness` which uses `.isEmpty`).
- Provider names follow Riverpod 3 convention: `class XNotifier` → `xProvider` (suffix stripped). For these read-only Future providers, no `Notifier` class is needed — top-level `@riverpod Future<...> name(Ref ref, {...})` yields `nameProvider`.

---

### 12. `lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` (NEW)

**Role:** widget (presentation layer)
**Analog (chrome):** `lib/features/analytics/presentation/widgets/family_insight_card.dart:32-65`
**Analog (top-N + Other):** `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart:71-103` (slice + overflow → Other)

**Pattern excerpt — card chrome (line 32-46):**
```dart
// Source: lib/features/analytics/presentation/widgets/family_insight_card.dart:32-46
return Card(
  color: AppColors.olive.withValues(alpha: 0.10),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
    side: BorderSide(color: AppColors.olive.withValues(alpha: 0.30)),
  ),
  child: Padding(
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.analyticsCardTitleFamilyInsight,
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.olive),
        ),
        const SizedBox(height: 8),
        // ... rows
      ],
    ),
  ),
);
```

**Pattern excerpt — top-N + Other fold (donut analog at line 71-103):**
```dart
// Source: lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart:88-100
if (overflow.isNotEmpty && total > 0) {
  final otherAmount = overflow.fold<int>(0, (sum, item) => sum + item.amount);
  slices.add(_DonutSlice(
    categoryName: l10n.analyticsCategoryDonutOther,
    amount: otherAmount,
    percentage: otherAmount / total * 100,
  ));
}
```

**Adaptation notes for Phase 16:**
- This is a `ConsumerWidget` (NOT `StatelessWidget` like `FamilyInsightCard`) because it consumes `perCategorySoulBreakdownProvider`. Use the `_SatisfactionHistogramOrFallback` shape at `analytics_screen.dart:363-430` as the `ConsumerWidget + ref.watch + AsyncValue.when` template.
- Replace `AppColors.olive` with `context.wmCard` for the surface (per UI-SPEC.md Color table — secondary tier `AppColors.card`).
- Title: `S.of(context).analyticsCardTitlePerCategorySoul` (UI-SPEC line 97-99) — three variants for solo / group-You / group-Family.
- Expansion: local `StatefulWidget` with `_isExpanded: bool` per RESEARCH Open Question #2 — DO NOT introduce a new Riverpod provider for UI-local state.
- Sort + min-N + Other fold occur in the use case (file #6 above); the widget renders trusted, pre-sorted data + `Other` aggregate.
- Number formatting: `AppTextStyles.amountMedium` (UI-SPEC Typography table) — never raw `Text('${x}')` for numbers (CLAUDE.md Amount Display Style rule).
- Locale must thread through `CategoryLocalizationService.resolveFromId(categoryId, locale)` — verified analog at `family_insight_card.dart:78`.
- `AsyncValue.when`: loading → `SizedBox(height: ~280)` placeholder; error → `AnalyticsCardErrorState(onRetry: ...)` (existing widget; see `analytics_screen.dart:350-358`); data → switch on `MetricResult<PerCategorySoulBreakdown>` Empty vs Value.
- `Empty` case shows `S.of(context).analyticsPerCategoryEmpty`; `Value` case renders Top-5 ranked rows + `Other` fold row (if `otherCount > 0`) + "Show all" affordance (if `items.length > 5`).

---

### 13. `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` (NEW)

**Role:** widget (presentation layer)
**Analog (chrome):** `lib/features/analytics/presentation/widgets/family_insight_card.dart:32-65` (Card + Padding + Column)
**Analog (`AsyncValue.when`):** `lib/features/analytics/presentation/screens/analytics_screen.dart:343-359` (`_CategoryDonutCard`)
**Analog (two-column equal-height + 2×2 grid):** none in codebase — composed from Flutter idioms per UI-SPEC.md + RESEARCH lines 1004-1030

**Pattern excerpt — two-column layout (RESEARCH lines 1006-1014, Flutter idiom):**
```dart
IntrinsicHeight(
  child: Row(
    children: [
      Expanded(child: _SoulCell(soul: snapshot.soul, ...)),
      const VerticalDivider(width: 1),  // context.wmBorderDivider tint
      Expanded(child: _SurvivalCell(survival: snapshot.survival, ...)),
    ],
  ),
)
```

**Pattern excerpt — 2×2 grid (RESEARCH lines 1017-1030):**
```dart
Column(children: [
  Row(children: [
    Expanded(child: _SoulCell(label: l10n.analyticsLedgerRowYou, soul: snapshot.soul)),
    const VerticalDivider(width: 1),
    Expanded(child: _SurvivalCell(label: l10n.analyticsLedgerRowYou, survival: snapshot.survival)),
  ]),
  const Divider(height: 1),
  Row(children: [
    Expanded(child: _SoulCell(label: l10n.analyticsLedgerRowFamily, soul: familySnapshot?.soul, fallback: l10n.analyticsLedgerFamilyEmpty)),
    const VerticalDivider(width: 1),
    Expanded(child: _SurvivalCell(label: l10n.analyticsLedgerRowFamily, survival: familySnapshot?.survival, fallback: ...)),
  ]),
])
```

**Adaptation notes for Phase 16:**
- `ConsumerWidget`. Watches `soulVsSurvivalSnapshotProvider(...)` and (only if `isGroupMode`) `soulVsSurvivalSnapshotFamilyProvider(...)`.
- Card surface uses `context.wmCard` (NOT the olive tint from `FamilyInsightCard`).
- Title: `S.of(context).analyticsCardTitleLedgerThisWindow` (D-12 framing — NEVER "vs"/"comparison").
- Soul column accent: `AppColors.soul` (`#47B88A`); Survival column accent: `AppColors.survival` (`#5A9CC8`) — UI-SPEC §Color §Accent reserved-for.
- Cell internal layout: `_SoulCell` shows count → spend → avg sat (3 lines); `_SurvivalCell` shows count → spend (2 lines, NO avg sat). The class structure ENFORCES D-04 — `_SurvivalCell` literally cannot read an `avgSatisfaction` field because `SurvivalLedgerSnapshot` has none.
- D-05 Empty: when `MetricResult<SoulVsSurvivalSnapshot>` is `Empty<...>`, render `S.of(context).analyticsLedgerEmpty` body, no cells.
- D-20 group-fallback: when `familyAsync.value` is `Empty<...>` due to <2 books, the bottom row's cells render `S.of(context).analyticsLedgerFamilyEmpty` placeholder.

---

### 14-16. `lib/l10n/app_{en,ja,zh}.arb` — extend with ~15 new keys (ja/zh/en parity)

**Role:** arb (i18n)
**Analog:** existing analytics keys at `lib/l10n/app_en.arb:1864-1949` (verified parity at `app_ja.arb` and `app_zh.arb` same line range)

**Pattern excerpt — simple key:**
```json
// Source: lib/l10n/app_en.arb:1865-1871
"analyticsGroupHeaderDistribution": "━ Distribution ━",
"analyticsCardTitleTotalSixMonth": "Total · 6-month trend",
"analyticsCardCaptionTotalSixMonth": "BarChart · current month highlighted",
"analyticsCardTitleCategoryDonut": "Total · Category breakdown",
"analyticsCardCaptionCategoryDonut": "Donut/PieChart · top-N + Other",
"analyticsCategoryDonutOther": "Other",
```

**Pattern excerpt — placeholdered key with `@key` metadata:**
```json
// Source: lib/l10n/app_en.arb:1880-1894
"analyticsCardLargestExpenseBody": "{categoryName} · {amount} · {date}",
"@analyticsCardLargestExpenseBody": {
  "description": "Largest monthly expense story card body",
  "placeholders": {
    "categoryName": {"type": "String"},
    "amount": {"type": "String"},
    "date": {"type": "String"}
  }
},
```

**Keys to add (UI-SPEC.md §Copywriting Contract — final names planner-discretion but recommended):**
1. `analyticsCardTitlePerCategorySoul` (solo) / `analyticsCardTitlePerCategorySoulYou` (group/You) / `analyticsCardTitlePerCategorySoulFamily` (group/Family)
2. `analyticsPerCategoryRow` (placeholders: categoryName, avgSat, count) — placeholdered form
3. `analyticsPerCategoryOtherFold` (placeholders: totalCount, categoryCount)
4. `analyticsPerCategoryShowAll`, `analyticsPerCategoryShowLess`
5. `analyticsCardTitleLedgerThisWindow` — D-12 framing
6. `analyticsLedgerColumnSoul`, `analyticsLedgerColumnSurvival`
7. `analyticsLedgerRowYou`, `analyticsLedgerRowFamily`
8. `analyticsLedgerCellEntries` (placeholder: count), `analyticsLedgerCellAvgSat` (placeholder: avgSat)
9. `analyticsPerCategoryEmpty`, `analyticsLedgerEmpty`, `analyticsLedgerFamilyEmpty`

**Adaptation notes for Phase 16:**
- ALL keys added to all three ARB files in the SAME commit (Pitfall 8 — `grep -c 'key' lib/l10n/app_*.arb` should equal 3 per key, or 6 if `@key` metadata block exists).
- After save: run `flutter gen-l10n` and verify zero warnings.
- Translations must comply with D-14 forbidden-substring list — NO `比較`/`対決`/`vs`/`compare`/`versus`/`勝ち`/`負け`/`更好`/`更差` etc.

---

### 17. `test/unit/data/daos/analytics_dao_per_category_test.dart` (NEW)

**Role:** test-unit (data layer)
**Analog:** `test/unit/data/daos/analytics_dao_happiness_test.dart:1-86` — exact structural fit

**Pattern excerpt (setup + seedTx helper):**
```dart
// Source: test/unit/data/daos/analytics_dao_happiness_test.dart:1-52
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/analytics_dao.dart';

void main() {
  late AppDatabase db;
  late AnalyticsDao dao;

  final windowStart = DateTime(2026, 5);
  final windowEnd = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    db = AppDatabase.forTesting();
    dao = AnalyticsDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedTx({
    required String id,
    String bookId = 'book_joy',
    int amount = 1000,
    String type = 'expense',
    String categoryId = 'cat_joy',
    String ledgerType = 'soul',
    DateTime? timestamp,
    bool isDeleted = false,
    int soulSatisfaction = 6,
  }) {
    // ... insert into db.transactions
  }
  // ... tests
}
```

**Adaptation notes for Phase 16:**
- Reuse `AppDatabase.forTesting()` + `seedTx` helper verbatim (paste, do not import — each DAO test file is self-contained per project precedent).
- Test cases required:
  1. Soul filter — survival rows excluded from per-category result (mirror analog test at line 54-86).
  2. Sort order — `AVG DESC, COUNT DESC, categoryId ASC` (seed 3 categories with controlled `(avg, count, id)` tuples; assert order).
  3. NO `HAVING` filter applied at DAO — low-N rows ARE returned by DAO (use case filters them in Dart per RESEARCH R1).
  4. Across-books variant — `book_id IN (...)` returns rows from multiple books pooled.
  5. Empty window → empty list.
- Verify zero soul satisfaction values from survival rows ever appear (Pitfall 7 — assert `survival_with_satisfaction=10` does NOT bleed into result).

---

### 18. `test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart` (NEW)

**Role:** test-unit (data layer)
**Analog:** `test/unit/data/daos/analytics_dao_happiness_test.dart:1-86` — same scaffold

**Adaptation notes for Phase 16:**
- Test cases:
  1. Per-ledger COUNT + SUM correctness — seed 3 soul + 2 survival rows of varied amounts; assert `(ledger_type='soul', cnt=3, total=∑)` + `(ledger_type='survival', cnt=2, total=∑)`.
  2. `is_deleted = 0` filter respected on both sides.
  3. `type = 'expense'` filter respected (seed an `income` row, verify excluded).
  4. Window filter (timestamp boundary inclusive/exclusive — match `getLedgerTotals` semantics at `analytics_dao.dart:222-223`).
  5. Across-books variant — `book_id IN (...)` correctly pools.
  6. Empty window → empty list, NOT null.

---

### 19-22. Use-case unit tests (NEW × 4)

**Role:** test-unit (application layer)
**Analog (single-book):** `test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart:1-99` — exact
**Analog (group-mode):** `test/unit/application/analytics/get_family_happiness_use_case_test.dart:1-100`

**Pattern excerpt (full file — single-book):**
```dart
// Source: test/unit/application/analytics/get_satisfaction_distribution_use_case_test.dart:1-99
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/analytics/get_satisfaction_distribution_use_case.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetSatisfactionDistributionUseCase useCase;

  final startDate = DateTime(2026, 4);
  final endDate = DateTime(2026, 4, 30, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetSatisfactionDistributionUseCase(analyticsRepository: repository);
  });
  // ... stub helpers + tests

  test('throws ArgumentError when start > end', () async {
    expect(
      () => useCase.execute(
        bookId: 'book-1',
        startDate: DateTime(2026, 5, 31),
        endDate: DateTime(2026, 5),
      ),
      throwsArgumentError,
    );
  });

  test('throws ArgumentError when range exceeds 12 months', () async {...});
  test('throws ArgumentError when endDate is in the future', () async {...});
}
```

**Adaptation notes for Phase 16:**
- 3 mandatory `TimeWindowValidation` cases (start > end, range > 12 months, endDate in future) — copy verbatim from analog lines 67-98.
- Per-category use-case test additional cases:
  1. Min-N filter: rows with `count < 3` end up in Other, NOT items list.
  2. Sort order: `AVG DESC, COUNT DESC, categoryId ASC` — assert exact order with crafted tuples.
  3. Empty return: `repo.getPerCategorySoulBreakdown(...)` returns `[]` → use case returns `const Empty<PerCategorySoulBreakdown>()`.
  4. Sub-min-N only: ALL rows have count<3 → items=[] but otherCount>0; return `Value` (sub-min-N is NOT Empty — RESEARCH §"Empty + sub-min-N flow").
- Soul-vs-Survival use-case test additional cases:
  1. D-05 — soul has 0 entries → Empty.
  2. D-05 — survival has 0 entries → Empty.
  3. Value path: both ledgers non-zero → `Value` with `Soul.avgSatisfaction` populated from `getSoulSatisfactionOverview` mock (verifies ONLY soul-scoped query is used).
- Across-books variants: stub `getPerCategorySoulBreakdownAcrossBooks` / `getLedgerSnapshotAcrossBooks` instead; empty `groupBookIds` → Empty short-circuit (no repo calls — `verifyNever`).
- Mock pattern: `class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}` — verbatim from analog.

---

### 23-24. Widget tests for the two new cards (NEW × 2)

**Role:** test-widget (presentation layer)
**Analog:** `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:1-120` — exact

**Pattern excerpt (testWidgets + createLocalizedWidget):**
```dart
// Source: test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:13-30
const locale = Locale('ja');

testWidgets('does not render when group mode is false', (tester) async {
  await tester.pumpWidget(
    createLocalizedWidget(
      const FamilyInsightCard(
        family: _familyWithSharedJoy,
        isGroupMode: false,
        shadowBooks: [_shadowBook],
        locale: locale,
      ),
      locale: locale,
    ),
  );

  expect(_shrinkFinder(), findsOneWidget);
  expect(find.text('家族 · ハイライトサマリー'), findsNothing);
});
```

**Test helper to reuse:** `test/helpers/test_localizations.dart:15` — `createLocalizedWidget(widget, locale: locale)` wraps in `ProviderScope` + `MaterialApp` with `S.delegate` chain.

**Adaptation notes for Phase 16:**
- Since both new widgets are `ConsumerWidget` that consume async providers, pass `overrides: [...]` to `createLocalizedWidget` (the helper accepts overrides per its v1.2 signature — verified at `test_localizations.dart:15-20`) and override the new providers with `.overrideWith((_) async => fixtureValue())`.
- Test cases for `PerCategoryBreakdownCard`:
  1. Loading state (`AsyncValue.loading` override) → placeholder, no row text.
  2. Empty state (override returns `Empty<PerCategorySoulBreakdown>`) → empty body text rendered, no rows.
  3. Sub-min-N only (qualifying empty, otherCount>0) → "Other" fold row visible, no ranked rows.
  4. Value with 3 qualifying categories → 3 rows rendered, sort order verified by `find.byType` order.
  5. Value with 7 qualifying categories → 5 rows + "Show all" affordance; tap → 7 rows + "Show less".
  6. Group mode — stub two providers and render both stacked cards (D-17) — assert both titles found.
- Test cases for `SoulVsSurvivalCard`:
  1. Solo Value → two-column layout, both Soul + Survival numbers rendered, Survival has NO satisfaction line.
  2. Solo Empty (D-05) → empty body text, no columns rendered.
  3. Group Value (4 cells) → 2×2 layout, all four cells rendered with correct labels.
  4. Group D-20 fallback (`shadowBooks.length < 2`) → bottom row shows `analyticsLedgerFamilyEmpty` text.
- Use `find.text(localizedString)` + `findsOneWidget`/`findsNothing` matchers (verbatim from analog).

---

### 25. `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` (NEW)

**Role:** test-widget (presentation layer) — **trilingual forbidden-substring sweep**
**Analog:** `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` (locale parameterization) — **partial; no codebase analog does a forbidden-substring sweep across rendered widget trees**

**Skeleton pattern (composed from analog + RESEARCH §Pitfall 9):**
```dart
// Locale parameterization mirrors family_insight_card_test.dart:13
const locales = [Locale('en'), Locale('ja'), Locale('zh')];

const forbiddenEn = [
  'better', 'worse', 'winner', 'loser', 'vs', 'versus',
  'compare', 'comparison', 'higher is good', 'lower is bad',
  'score', 'rank', 'ranking', 'wins', 'loses',
];
const forbiddenZh = [
  '更好', '更差', '赢', '输', '胜', '败', 'vs',
  '对比', '比较', '排名', '分数', '胜出', '落败',
];
const forbiddenJa = [
  '勝ち', '負け', 'より良い', 'より悪い', '比較',
  '対決', 'スコア', 'ランキング', '勝つ', '負ける',
];

for (final locale in locales) {
  for (final state in ['empty', 'sub_min_n', 'value', 'group_value']) {
    testWidgets('PerCategoryBreakdownCard / $locale / $state — no forbidden substrings', (tester) async {
      await tester.pumpWidget(createLocalizedWidget(
        _buildPerCategoryCard(state: state),
        locale: locale,
        overrides: [/* provider overrides for the state */],
      ));
      await tester.pumpAndSettle();

      final forbidden = locale.languageCode == 'en' ? forbiddenEn
        : locale.languageCode == 'ja' ? forbiddenJa
        : forbiddenZh;

      for (final substring in forbidden) {
        expect(find.textContaining(substring, findRichText: true),
          findsNothing,
          reason: 'D-14: forbidden substring "$substring" leaked into $locale / $state');
      }
    });
  }
}
```

**Adaptation notes for Phase 16:**
- Test pumps the WHOLE card for each state (RESEARCH line 664: "test pumps the whole card for each state, not a curated string") — `find.textContaining` walks the rendered Text widget tree.
- Both `PerCategoryBreakdownCard` AND `SoulVsSurvivalCard` covered.
- For each card × 3 locales × 4 states (empty / sub-min-N or sole-soul-empty / value / group-value) = 24 assertions per forbidden-substring set.
- Add this test to the analytics widget directory; CI runs it as part of `flutter test`.
- Forbidden substring lists are LOCKED in CONTEXT D-14 + UI-SPEC §"Forbidden substrings"; this test file embeds them as `const`. Any future ARB addition will be vetted by this test.

---

### 26. `test/golden/per_category_breakdown_card_golden_test.dart` + `test/golden/soul_vs_survival_card_golden_test.dart` (NEW)

**Role:** test-golden (presentation layer)
**Analog:** `test/golden/amount_display_golden_test.dart:1-79` — exact

**Pattern excerpt (golden harness):**
```dart
// Source: test/golden/amount_display_golden_test.dart:1-79
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
      body: Center(child: SizedBox(width: 360, height: 80, child: child)),
    ),
  );
}

testWidgets('JPY ¥1,235 — locale ja', (tester) async {
  await tester.pumpWidget(_wrap(locale: const Locale('ja'), child: const AmountDisplay(...)));
  await expectLater(
    find.byType(AmountDisplay),
    matchesGoldenFile('goldens/amount_display_jpy.png'),
  );
});
```

**Adaptation notes for Phase 16:**
- Wrap each card in `ProviderScope(overrides: [...])` BEFORE `MaterialApp` (the analog doesn't because `AmountDisplay` has no provider deps; Phase 16 cards do).
- Golden file naming convention: `goldens/per_category_breakdown_card_light_ja.png`, `_dark_ja.png`, `_group_light_ja.png` (per RESEARCH lines 321-327).
- For theme coverage: wrap in `Theme(data: ThemeData.light()/...dark())` — verify project's existing dark-theme golden pattern in `home_hero_card_golden_test.dart` (file exists, planner inspects).
- Use `SizedBox(width: 360, height: ~280)` (card density per UI-SPEC) to keep golden bytes stable across screen sizes.
- After first run: commit the generated PNG bytes; subsequent test runs assert equality.

---

### 27. `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — EXTEND

**Role:** test-widget (presentation layer)
**Analog:** self — lines 122-250 (entire test scaffolding)

**Pattern excerpt (verify HomeHero NOT rebuilt with analytics window):**
```dart
// Source: test/widget/features/home/presentation/screens/home_screen_isolation_test.dart:170-235
testWidgets(
  'HomeHero remains current-month keyed when Analytics window is year 2020',
  (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    verify(
      () => monthlyReportUseCase.execute(
        bookId: _bookId,
        startDate: currentMonthStart,
        endDate: currentMonthEnd,
      ),
    ).called(greaterThanOrEqualTo(1));
    // ... other current-month verifies

    verifyNever(
      () => monthlyReportUseCase.execute(
        bookId: any(named: 'bookId'),
        startDate: DateTime(2020),
        endDate: any(named: 'endDate'),
      ),
    );
    // ... other "never with year-2020 window" verifyNever assertions
  },
);
```

**Adaptation notes for Phase 16:**
- Phase 15 D-12 binding: AnalyticsScreen `_refresh()` MUST NOT invalidate HomeHero providers. Phase 16 adds 4 new providers to the analytics `_refresh()` set — this test MUST be extended to:
  1. Add mocks for the 4 new use cases (`GetPerCategorySoulBreakdownUseCase`, `GetPerCategorySoulBreakdownAcrossBooksUseCase`, `GetSoulVsSurvivalSnapshotUseCase`, `GetSoulVsSurvivalSnapshotAcrossBooksUseCase`).
  2. Add overrides for the 4 new providers in `buildSubject()` (mirror line 128-156).
  3. Add `verifyNever(...)` blocks for the 4 new use cases with the year-2020 window (matches existing pattern at line 206-234).
  4. The Phase 16 providers are NOT consumed by HomeHero, so they should NEVER be called with Home tab's current-month keys — that constraint is the assertion.
- Source-import check at line 238-250 (HomeScreen does not import `state_time_window`) should also verify HomeScreen does NOT import `state_ledger_snapshot` — add this assertion.

---

### 28. `lib/features/analytics/presentation/screens/analytics_screen.dart` — MODIFY

**Role:** screen-integration (presentation layer)
**Analog (in-file):**
- Distribution composition — `analytics_screen.dart:105-121`
- `_refresh()` invalidation list — `analytics_screen.dart:160-213`
- Existing card consumer — `_CategoryDonutCard` at `analytics_screen.dart:343-359`, `_SatisfactionHistogramOrFallback` at line 363-430

**Pattern excerpt — Distribution section composition (line 105-121):**
```dart
// Source: lib/features/analytics/presentation/screens/analytics_screen.dart:105-121
const SizedBox(height: 32),
AnalyticsScreenSectionHeader(
  label: l10n.analyticsGroupHeaderDistribution,
),
const SizedBox(height: 8),
_CategoryDonutCard(
  bookId: bookId,
  startDate: startDate,
  endDate: endDate,
),
const SizedBox(height: 8),
_SatisfactionHistogramOrFallback(
  bookId: bookId,
  startDate: startDate,
  endDate: endDate,
  currencyCode: currencyCode,
),
const SizedBox(height: 32),
```

**Pattern excerpt — `_refresh()` invalidation (line 167-212):**
```dart
// Source: lib/features/analytics/presentation/screens/analytics_screen.dart:167-212
void _refresh(WidgetRef ref, {...}) {
  // D-12: _refresh MUST NOT invalidate any home/* provider
  ref.invalidate(monthlyReportProvider(bookId: bookId, startDate: startDate, endDate: endDate));
  ref.invalidate(expenseTrendProvider(bookId: bookId, anchor: trendAnchor));
  ref.invalidate(earliestTransactionMonthProvider(bookId: bookId));
  ref.invalidate(happinessReportProvider(...));
  ref.invalidate(satisfactionDistributionProvider(...));
  ref.invalidate(bestJoyMomentProvider(...));
  ref.invalidate(largestMonthlyExpenseProvider(...));
  if (isGroupMode) {
    ref.invalidate(familyHappinessProvider(startDate: startDate, endDate: endDate));
    ref.invalidate(shadowBooksProvider);
  }
}
```

**Adaptation notes for Phase 16:**
- **Insertion (D-13):** between line 113 (end of `_CategoryDonutCard`) and line 115 (`const SizedBox(height: 8)`), insert:
  ```dart
  const SizedBox(height: 8),
  _SoulVsSurvivalCard(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    currencyCode: currencyCode,
    locale: locale,
    isGroupMode: isGroupMode,
  ),
  ```
- After line 121 (`_SatisfactionHistogramOrFallback`), insert:
  ```dart
  const SizedBox(height: 8),
  _PerCategoryBreakdownCard(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    locale: locale,
    scope: PerCategoryScope.you, // or solo
  ),
  if (isGroupMode) ...[
    const SizedBox(height: 8),
    _PerCategoryBreakdownCard(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
      locale: locale,
      scope: PerCategoryScope.family, // D-17 two stacked cards
    ),
  ],
  ```
- **Extend `_refresh()`** (line 167-212) with 4 new `ref.invalidate(...)` calls — using SAME `(bookId, startDate, endDate)` keys as the build context (RESEARCH §Pitfall 2: "MUST be invalidated with the SAME `(startDate, endDate)` keys"). Two of them only when `isGroupMode` (within the existing `if (isGroupMode) {...}` block at line 207-212).
- **DO NOT** invalidate any Home/HomeHero provider — preserve the `// D-12` comment at line 168.
- Add imports at top (lines 1-25): `'../widgets/per_category_breakdown_card.dart';` + `'../widgets/soul_vs_survival_card.dart';`.

---

### 29. `.planning/ROADMAP.md` — SC-3 wording correction (D-15)

**Role:** doc-update (docs)
**Analog:** other Phase Success Criteria in the same ROADMAP.md file (cited as planner-discretion analog).

**Adaptation notes for Phase 16:**
- Locate Phase 16 §"Success Criteria" SC-3. The example wording ("Soul ledger averages 7.4 satisfaction; survival ledger 5.1") is the load-bearing error to fix.
- Replacement suggested in CONTEXT D-15: *"...displaying both ledgers' engagement metrics (entry count + total spend; Soul column additionally shows average satisfaction). Copy is descriptive only — no value-judgment terms (better/worse/winner/loser/vs framing) — verified by ARB review + widget assertion of forbidden-substring absence in all three locales."*
- This is the FIRST task in the Phase 16 plan (D-15: "Phase 16 plan's first task list item"). It is doc-only — no test impact, no code impact.

---

## Shared Patterns

### S1. `TimeWindowValidation.assertValid` — defense-in-depth window guard

**Source:** `lib/application/analytics/_time_window_validation.dart`
**Verified call sites:** `get_satisfaction_distribution_use_case.dart:18`, `get_family_happiness_use_case.dart:28`, `get_happiness_report_use_case.dart:35`

**Apply to:** ALL 4 new use cases (#6, #7, #8, #9) — first statement inside `execute()`.

```dart
Future<MetricResult<...>> execute({...}) async {
  TimeWindowValidation.assertValid(startDate, endDate);
  // ... fetch + transform
}
```

**Rejected inputs:** start > end (throws `ArgumentError`); span > 12 months; endDate in the future. Tests must cover all three (analog: `get_satisfaction_distribution_use_case_test.dart:67-98`).

---

### S2. `MetricResult<T>` Empty/Value envelope

**Source:** `lib/features/analytics/domain/models/metric_result.dart:16-29`

**Apply to:** All Phase 16 use case return types: `Future<MetricResult<PerCategorySoulBreakdown>>`, `Future<MetricResult<SoulVsSurvivalSnapshot>>`.

```dart
// Source: lib/features/analytics/domain/models/metric_result.dart:16-29
sealed class MetricResult<T> {
  const MetricResult();
}
final class Empty<T> extends MetricResult<T> { const Empty(); }
final class Value<T> extends MetricResult<T> {
  const Value(this.data, this.sampleSize);
  final T data;
  final int sampleSize;
}
```

**Pattern-match in widget (Dart 3 switch):**
```dart
switch (result) {
  Empty() => renderEmptyCopy(),
  Value(:final data, :final sampleSize) => renderRows(data),
}
```

---

### S3. `_soulExpenseFilter` canonical SQL predicate

**Source:** `lib/data/daos/analytics_dao.dart:82-83`

```dart
static const String _soulExpenseFilter =
    "ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0";
```

**Apply to:** ALL new soul-scoped DAO queries (#1: `getPerCategorySoulBreakdown`, `getPerCategorySoulBreakdownAcrossBooks`). Compose via string interpolation in the SQL: `'WHERE book_id = ? AND $_soulExpenseFilter AND timestamp >= ? AND timestamp <= ?'` (matches `getSoulSatisfactionOverview` at line 251-254 and `getSharedJoyCategoryInsight` at line 421-423).

**NEW companion constant:** Define `_survivalExpenseFilter` in the same DAO file using identical structure with `'survival'` — single-source-of-truth for symmetry (RESEARCH §"Established Patterns").

---

### S4. `customSelect` with `Variable.withString` / `Variable.withDateTime` — input-validation gate

**Source:** `lib/data/daos/analytics_dao.dart:418-433` (across-books pattern)

```dart
final placeholders = List.filled(bookIds.length, '?').join(', ');
final results = await _db.customSelect(
  'SELECT ... WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
  'AND timestamp >= ? AND timestamp <= ? ...',
  variables: [
    ...bookIds.map(Variable.withString),
    Variable.withDateTime(startDate),
    Variable.withDateTime(endDate),
  ],
).get();
```

**Apply to:** ALL new DAO queries (#1 single-book + across-books). Never use string interpolation for user-controlled values (V5 ASVS / RESEARCH §"Security Domain"). The `_soulExpenseFilter` constant interpolation IS safe because the constant is a literal — but bookIds/dates always go through `Variable`.

---

### S5. `AsyncValue.when` per-card fault isolation

**Source:** `lib/features/analytics/presentation/screens/analytics_screen.dart:343-359` (`_CategoryDonutCard`)

```dart
return monthlyAsync.when(
  data: (monthly) => _AnalyticsDataCard(...),
  loading: () => const SizedBox(height: 280),
  error: (_, _) => AnalyticsCardErrorState(
    onRetry: () => ref.invalidate(monthlyReportProvider(...)),
  ),
);
```

**Apply to:** Both new widgets (#12, #13). Each card's `AsyncValue` is consumed in its own `.when()` so one failing provider does not blank the screen (file comment at `analytics_screen.dart:27-30`). Use `AnalyticsCardErrorState` (existing widget) with locale-specific pull-to-refresh hint per UI-SPEC §"Error state".

---

### S6. `CategoryLocalizationService.resolveFromId` — localized category names

**Source:** `lib/features/analytics/presentation/widgets/family_insight_card.dart:78`

```dart
CategoryLocalizationService.resolveFromId(data.categoryId, locale)
```

(Imported from `lib/application/accounting/category_localization_service.dart`.)

**Apply to:** `PerCategoryBreakdownCard` (#12) leading-cell category name lookup per row. Handles `cat_*` → ARB key transformation with user-created-category fallback (RESEARCH §"Don't Hand-Roll").

---

### S7. ProviderScope override + `createLocalizedWidget` test scaffold

**Source:** `test/helpers/test_localizations.dart:15-20` + `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart:1-30`

```dart
await tester.pumpWidget(
  createLocalizedWidget(
    const WidgetUnderTest(...),
    locale: const Locale('ja'),
    overrides: [/* provider overrides */],
  ),
);
```

**Apply to:** All Phase 16 widget tests (#23, #24, #25). For `ConsumerWidget`s, pass `overrides: [providerX.overrideWith((_) async => fixtureValue())]` — see `home_screen_isolation_test.dart:128-166` for a comprehensive override list.

---

## Files Without Close Analogs

### `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`

**Why novel:** No existing test in the codebase performs a forbidden-substring sweep across rendered widget trees per locale. The closest precedent is `family_insight_card_test.dart` which uses `find.text(localizedString)` for positive assertion of expected text — but NOT `find.textContaining(forbidden)` with `findsNothing` for negative assertion.

**Mitigation:**
- Test structure is composed from `family_insight_card_test.dart` (locale iteration pattern) + `Finder` API documentation (`find.textContaining(pattern, findRichText: true)`).
- The forbidden lists themselves are locked in CONTEXT D-14 + UI-SPEC §"Forbidden substrings", so the test logic is mechanical — not creative.
- This is the only file in Phase 16 lacking an exact codebase analog. All other tests trace cleanly to an existing test file.

---

## Verification Summary

| Concern | Status |
|---------|--------|
| All NEW files have a cited analog (file:lines) | yes — 26 of 27 exact/role-match; 1 partial-novel (anti_toxicity_phase16_test.dart) |
| All MODIFIED files cite the specific lines to extend | yes — analytics_screen.dart:105-121 + 167-212; analytics_dao.dart additions follow lines 82, 214-241, 244-272, 410-444; ARB files extend lines 1860-1949 region |
| Code excerpts include path + line range | yes — every excerpt cites `file:line-range` |
| Shared cross-cutting patterns extracted | yes — S1 (TimeWindowValidation), S2 (MetricResult), S3 (_soulExpenseFilter + new _survivalExpenseFilter), S4 (Drift Variable), S5 (AsyncValue.when), S6 (CategoryLocalizationService), S7 (test scaffolding) |
| D-04 type-system gate captured in pattern | yes — `SurvivalLedgerSnapshot` has no `avgSatisfaction` field (file #3); `_SurvivalCell` widget cannot read what model doesn't expose (file #13) |
| D-12 framing captured (no vs/comparison wording) | yes — file #13 + #14-16 + #25 (anti_toxicity_phase16_test.dart) |
| D-17 stacked cards in group mode | yes — file #28 (two `_PerCategoryBreakdownCard` insertions with `scope: solo|you|family`) |
| D-18 2×2 grid in group mode | yes — file #13 (Column<Row> layout per RESEARCH lines 1017-1030) |
| D-20 family-empty fallback | yes — file #11 (`if (groupBookIds.length < 2) return const Empty();`) |
| Phase 15 D-12 HomeHero non-invalidation preserved | yes — file #27 (extend home_screen_isolation_test) + file #28 `_refresh()` notes |
| Pitfall 7 ("AVG over survival rows" trap) gated | yes — S3 (`_soulExpenseFilter` reuse), file #3 (type-system gate), file #8 (use case uses `getSoulSatisfactionOverview` only) |
| ARB ja/zh/en parity gate | yes — file #14-16 cites Pitfall 8 grep verification + parallel structural pattern from `app_en.arb:1864-1949` |
| Tests for ProviderException wrapping (Riverpod 3) | implicit — TimeWindowValidation throws ArgumentError synchronously, NOT via provider; tests use `throwsArgumentError` per analog at `get_satisfaction_distribution_use_case_test.dart:67-98` |

---

## PATTERN MAPPING COMPLETE

**Phase:** 16 — Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01)
**Files classified:** 29 (24 NEW + 4 MODIFIED + 1 doc-only)
**Analogs found:** 28 / 29 (one partial — anti_toxicity_phase16_test.dart is novel in structure but uses existing locale-iteration scaffold)

### Coverage

- Files with exact analog: 22
- Files with role-match analog (different role/data-flow, similar pattern): 6
- Files with partial/novel: 1 (`anti_toxicity_phase16_test.dart`)

### Key Patterns Identified

- **Riverpod 3 `@riverpod Future<...>` family providers** keyed on `(bookId, startDate, endDate)` — `state_happiness.dart:14-30` is the canonical analog; new file #11 (`state_ledger_snapshot.dart`) replicates this verbatim for 4 providers.
- **`Future.wait` parallel DAO fetch + Empty/Value wrap** — `get_family_happiness_use_case.dart:42-65` is the canonical analog; new file #8 (`get_soul_vs_survival_snapshot_use_case.dart`) replicates with 2 parallel fetches (ledger snapshot + soul satisfaction).
- **`_soulExpenseFilter` constant interpolation + `Variable.with*` parameterization** in all DAO custom selects — `analytics_dao.dart:82` + `:418-433` is the canonical analog; new file #1 extends with a `_survivalExpenseFilter` companion.
- **Card chrome = `Card + Padding(14) + Column(start)` with `AppTextStyles.titleLarge`** — `family_insight_card.dart:32-46` is the canonical analog for both new widgets.
- **Type-system gate for D-04** — `SurvivalLedgerSnapshot` carries no `avgSatisfaction` field; this is the structural enforcement that prevents the "default-2 over survival" anti-toxicity reverse-pattern at compile time.
- **ARB ja/zh/en parity in lockstep** with `@key` metadata for placeholdered strings — `app_en.arb:1880-1894` is the canonical analog.
- **Test scaffold: `createLocalizedWidget(widget, locale, overrides: [...])` + `find.text(localizedString)`** — `family_insight_card_test.dart:1-30` is the canonical analog; new files #23, #24 replicate. File #25 inverts the pattern using `find.textContaining(forbidden) → findsNothing`.

### File Created

`/Users/xinz/Development/home-pocket-app/.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/16-PATTERNS.md`

### Ready for Planning

Pattern mapping complete. `gsd-planner` can now reference these analogs directly in PLAN action sections — every NEW file points to a specific `file:lines` source plus a paste-ready code excerpt; every MODIFIED file points to the specific lines being extended plus the contextual pattern.
