# Phase 9: Happiness Domain & Formula Layer — Pattern Map

**Mapped:** 2026-05-01
**Files analyzed:** 33 (15 CREATE production + 11 Wave-0 tests + 7 MODIFY)
**Analogs found:** 32 / 33 (one novelty: generic plain-sealed `MetricResult<T>`)

---

## File Classification

### Production code (CREATE)

| New File | Role | Data Flow |
|---|---|---|
| `lib/features/analytics/domain/models/metric_result.dart` | domain_model (sealed union) | transform / pure |
| `lib/features/analytics/domain/models/happiness_report.dart` | domain_model (Freezed aggregate) | transform / pure |
| `lib/features/analytics/domain/models/best_joy_moment_row.dart` | domain_model (Freezed) | transform / pure |
| `lib/features/analytics/domain/models/family_happiness.dart` | domain_model (Freezed aggregate) | transform / pure |
| `lib/features/analytics/domain/models/shared_joy_insight.dart` | domain_model (Freezed; tuple-only) | transform / pure |
| `lib/application/analytics/get_happiness_report_use_case.dart` | use_case | request-response (orchestrates 3 repo calls) |
| `lib/application/analytics/get_best_joy_moment_use_case.dart` | use_case | request-response (single repo call) |
| `lib/application/analytics/get_family_happiness_use_case.dart` | use_case | request-response (fan-out per shadow book) |
| `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` | formatter (i18n utility) | transform / pure |
| `lib/features/analytics/presentation/providers/state_happiness.dart` | provider (Riverpod codegen) | event-driven async |
| `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` | adr | doc |
| `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` | adr | doc |
| `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` | adr | doc |

### Production code (MODIFY)

| File | Role | Data Flow | Operation |
|---|---|---|---|
| `lib/data/tables/transactions_table.dart` | table (schema) | — | line 35: `Constant(5)` → `Constant(2)` |
| `lib/data/app_database.dart` | db wiring | — | `schemaVersion 15 → 16`; add `if (from < 16)` block in `onUpgrade` |
| `lib/data/daos/analytics_dao.dart` | dao | request-response | add `static const _soulExpenseFilter`; refactor 3 existing soul queries; add `getSoulRowsForPtvf` + `getBestJoyMoment` + `getSharedJoyCategoryInsight` |
| `lib/data/repositories/analytics_repository_impl.dart` | repository_impl | request-response | implement 4 new methods |
| `lib/features/analytics/domain/repositories/analytics_repository.dart` | repository_interface | request-response | add 4 abstract method signatures |
| `lib/features/analytics/presentation/providers/repository_providers.dart` | provider wiring | event-driven async | add 3 use case providers (THIS is the canonical use case provider file, NOT `lib/application/analytics/repository_providers.dart`) |
| `lib/application/analytics/demo_data_service.dart` | service (test seeder) | batch | line 134: survival branch `5` → `2` |
| `docs/arch/03-adr/ADR-000_INDEX.md` | adr index | doc | append 3 entries |
| `.planning/REQUIREMENTS.md` | spec | doc | HAPPY-02/03/04/08 amendments, HAPPY-09 removal, FAMILY-01 |
| `.planning/ROADMAP.md` | spec | doc | Phase 9 pitfalls, Phase 12 scope |

### Tests (Wave 0 — CREATE empty stubs first)

| Test File | Test Type |
|---|---|
| `test/unit/data/migrations/migration_v15_to_v16_test.dart` | drift migration |
| `test/unit/features/analytics/domain/models/metric_result_test.dart` | unit (sealed pattern) |
| `test/unit/features/analytics/domain/models/happiness_report_test.dart` | unit (Freezed) |
| `test/unit/data/daos/analytics_dao_happiness_test.dart` | drift dao |
| `test/unit/data/repositories/analytics_repository_happiness_test.dart` | unit (impl delegation) |
| `test/unit/application/analytics/get_happiness_report_use_case_test.dart` | unit |
| `test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` | unit |
| `test/unit/application/analytics/get_family_happiness_use_case_test.dart` | unit |
| `test/unit/application/analytics/repository_providers_test.dart` | unit (provider wiring) |
| `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` | unit |

> **Important location correction (vs CONTEXT.md drafting):** the use case provider entries
> (`getMonthlyReportUseCaseProvider`, `getBudgetProgressUseCaseProvider`,
> `getExpenseTrendUseCaseProvider`) currently live in
> **`lib/features/analytics/presentation/providers/repository_providers.dart`** (verified at
> `:32`, `:41`, `:47`). The file `lib/application/analytics/repository_providers.dart` only
> re-exports `appAppDatabaseProvider`. Phase 9's 3 new use case providers MUST be added to
> the **presentation** `repository_providers.dart` to preserve the single-source-of-truth
> rule. The Wave-0 test file path
> `test/unit/application/analytics/repository_providers_test.dart` named in VALIDATION.md
> can therefore exercise both files (re-export + use-case wiring); the planner should
> name the test class accordingly.

---

## Pattern Assignments

### Role: `domain_model` — sealed union (`MetricResult<T>`)

#### `lib/features/analytics/domain/models/metric_result.dart` (NEW)

**Closest analog:** `lib/application/family_sync/check_group_use_case.dart:10-28`
(plain `sealed class` with `extends` variants — no Freezed, no codegen).
**Why this analog over `init_result.dart`:** D-13 specifies a *generic* parameter `T`;
the project has zero precedent for `@freezed sealed class<T>` and Freezed's generic
codegen has known quirks (per RESEARCH.md Q3a). Plain sealed sidesteps the risk while
matching project idiom (14+ plain-sealed classes already in `application/family_sync/`).

**Excerpt to mirror** (`check_group_use_case.dart:10-28`):
```dart
sealed class CheckGroupResult {
  const CheckGroupResult();
}

class CheckGroupInGroup extends CheckGroupResult {
  const CheckGroupInGroup({required this.groupId});

  final String groupId;
}

class CheckGroupNotInGroup extends CheckGroupResult {
  const CheckGroupNotInGroup();
}

class CheckGroupError extends CheckGroupResult {
  const CheckGroupError(this.message);

  final String message;
}
```

**Adapt to `MetricResult<T>`** (D-13 verbatim):
```dart
sealed class MetricResult<T> {
  const MetricResult();
}

final class Empty<T> extends MetricResult<T> {
  const Empty();
}

final class Value<T> extends MetricResult<T> {
  final T data;
  final int sampleSize;
  const Value(this.data, this.sampleSize);
}
```

**Notes:**
- D-13 mandates `final class` for variants (Dart 3 `final` modifier on the leaf classes).
- No `@freezed`, no `part 'metric_result.freezed.dart'`, no JSON.
- Consumption pattern (verified used 14+ times in family_sync use cases):
  `switch (result) { case Empty(): ... case Value(:final data, :final sampleSize): ... }`.
- File <40 lines target (single small file, high cohesion).

---

### Role: `domain_model` — Freezed aggregates

#### `lib/features/analytics/domain/models/happiness_report.dart` (NEW)
#### `lib/features/analytics/domain/models/family_happiness.dart` (NEW)
#### `lib/features/analytics/domain/models/best_joy_moment_row.dart` (NEW)
#### `lib/features/analytics/domain/models/shared_joy_insight.dart` (NEW)

**Closest analog:** `lib/features/analytics/domain/models/monthly_report.dart:1-47`
(same domain folder, same import-guard scope, same Freezed + JSON pattern).

**Excerpt to mirror** (`monthly_report.dart:1-47`):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'daily_expense.dart';
import 'month_comparison.dart';

part 'monthly_report.freezed.dart';
part 'monthly_report.g.dart';

/// Category-level spending breakdown within a monthly report.
@freezed
abstract class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    required String categoryId,
    required String categoryName,
    required String icon,
    required String color,
    required int amount,
    required double percentage,
    required int transactionCount,
    int? budgetAmount,
    double? budgetProgress,
  }) = _CategoryBreakdown;

  factory CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);
}

/// Complete monthly financial report.
@freezed
abstract class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required int year,
    required int month,
    required int totalIncome,
    required int totalExpenses,
    /* ... */
  }) = _MonthlyReport;

  factory MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);
}
```

**Adapt to `HappinessReport`** (shape locked verbatim by D-15):
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

import 'best_joy_moment_row.dart';
import 'metric_result.dart';

part 'happiness_report.freezed.dart';
part 'happiness_report.g.dart';

@freezed
abstract class HappinessReport with _$HappinessReport {
  const factory HappinessReport({
    required int year,
    required int month,
    required String bookId,
    required int totalSoulTx,
    required MetricResult<double> avgSatisfaction,
    required MetricResult<double> joyPerYen,
    required MetricResult<double> medianSatisfaction,
    required MetricResult<int> highlightsCount,
    required MetricResult<BestJoyMomentRow> topJoy,
  }) = _HappinessReport;

  factory HappinessReport.fromJson(Map<String, dynamic> json) =>
      _$HappinessReportFromJson(json);
}
```

**Notes:**
- Use `abstract class ... with _$Foo` pattern (Freezed 3.x; verified at `monthly_report.dart:11`).
- Both `.freezed.dart` and `.g.dart` parts (JSON precedent — keeps the cross-feature import target serializable for Phase 10/11).
- **`MetricResult<T>` is NOT directly JSON-serializable** as a generic plain-sealed class. Two options for the planner:
  1. Annotate the `MetricResult<T>` field with `@JsonKey(includeFromJson: false, includeToJson: false)` and skip JSON for the wrapped fields.
  2. Drop `fromJson` from happiness aggregates entirely (no current downstream consumer needs JSON; Phase 10/11 read live from provider).
  Option 2 is simpler and matches CLAUDE.md's "MANY SMALL FILES" / minimum-surface principle. Planner decides.
- File size target: <100 lines per aggregate.

#### `lib/features/analytics/domain/models/best_joy_moment_row.dart`

```dart
@freezed
abstract class BestJoyMomentRow with _$BestJoyMomentRow {
  const factory BestJoyMomentRow({
    required String transactionId,
    required int amount,
    required int soulSatisfaction,
    required String categoryId,
    required DateTime timestamp,
    // NOTE: deliberately omits `note` — encrypted column; ARCH-002 + RESEARCH Q1a.
  }) = _BestJoyMomentRow;
}
```

#### `lib/features/analytics/domain/models/shared_joy_insight.dart`

Tuple-only return shape per D-08 (anti-leaderboard contract):
```dart
@freezed
abstract class SharedJoyInsight with _$SharedJoyInsight {
  const factory SharedJoyInsight({
    required String categoryId,
    required double avgSatisfaction,
    required int totalCount,
  }) = _SharedJoyInsight;
}
```

**Forbidden additions** (type-system enforced):
- ❌ `Map<MemberId, ...>` of any kind
- ❌ `List<MemberContribution>`
- ❌ Any `deviceId` / `memberDisplayName` / `bookId` fields

---

### Role: `domain_model` — flat plain dataclass (analytics_aggregate.dart pattern)

If the planner wants additional DAO-side row containers (e.g., `SoulRowAmountSat`,
`BestJoyMomentDaoResult`, `SharedJoyCategoryDaoResult`), the precedent is
`lib/data/daos/analytics_dao.dart:6-81` — plain Dart classes with `const` constructors,
defined in the same DAO file (not in domain). Keep DAO row types co-located with the DAO
to avoid inflating `analytics_aggregate.dart`.

**Excerpt** (`analytics_dao.dart:48-57`):
```dart
class SatisfactionOverviewResult {
  final double avgSatisfaction;
  final int count;

  const SatisfactionOverviewResult({
    required this.avgSatisfaction,
    required this.count,
  });
}
```

---

### Role: `dao` — Drift query method

#### Modify `lib/data/daos/analytics_dao.dart`

**Closest analog:** the existing soul-satisfaction query family at `analytics_dao.dart:230-327`
(`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`).

**`_soulOnly()` extraction pattern (D-01, HAPPY-05).** Add a `static const String` and
refactor existing queries to compose via interpolation. Excerpt of one of the existing
queries to refactor (`analytics_dao.dart:230-258`):
```dart
Future<SatisfactionOverviewResult> getSoulSatisfactionOverview({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
        'FROM transactions '
        'WHERE book_id = ? AND ledger_type = \'soul\' AND type = \'expense\' '
        'AND is_deleted = 0 '
        'AND timestamp >= ? AND timestamp <= ?',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();
  /* ... */
}
```

**Refactor target** (CLASS-LEVEL const, mirror project's hand-written-SQL idiom verified
at lines 99, 138, 174, 207, 237, 269, 302):
```dart
class AnalyticsDao {
  AnalyticsDao(this._db);

  final AppDatabase _db;

  // D-01 / HAPPY-05: ledger + lifecycle filter ONLY. NO satisfaction predicate.
  static const String _soulExpenseFilter =
      "ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0";

  // ... existing methods refactored, e.g.:
  // 'WHERE book_id = ? AND $_soulExpenseFilter AND timestamp >= ? ...'
}
```

**`getBestJoyMoment` new method.** Mirror `getSoulSatisfactionOverview:230-259` shape;
add row-typed return.
```dart
/// Returns the single highest-satisfaction soul tx in window (D-06; HAPPY-04).
/// Tie-break: amount DESC, then timestamp DESC.
/// Returns null when no soul tx exists in window.
Future<BestJoyMomentDaoResult?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db.customSelect(
    'SELECT id, amount, soul_satisfaction, category_id, timestamp '
    'FROM transactions '
    'WHERE book_id = ? AND $_soulExpenseFilter '
    'AND timestamp >= ? AND timestamp <= ? '
    'ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC '
    'LIMIT 1',
    variables: [
      Variable.withString(bookId),
      Variable.withDateTime(startDate),
      Variable.withDateTime(endDate),
    ],
  ).get();
  if (results.isEmpty) return null;
  final row = results.first;
  return BestJoyMomentDaoResult(
    transactionId: row.read<String>('id'),
    amount: row.read<int>('amount'),
    soulSatisfaction: row.read<int>('soul_satisfaction'),
    categoryId: row.read<String>('category_id'),
    timestamp: row.read<DateTime>('timestamp'),
  );
}
```

**`getSoulRowsForPtvf` new method.** Returns row-wise tuples for Dart-layer PTVF fold
(D-04). Mirror `getSatisfactionDistribution:262-292` shape (List<row-class>):
```dart
Future<List<SoulRowAmountSat>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db.customSelect(
    'SELECT amount, soul_satisfaction '
    'FROM transactions '
    'WHERE book_id = ? AND $_soulExpenseFilter '
    'AND timestamp >= ? AND timestamp <= ?',
    variables: [
      Variable.withString(bookId),
      Variable.withDateTime(startDate),
      Variable.withDateTime(endDate),
    ],
  ).get();
  return results
      .map((r) => SoulRowAmountSat(
            amount: r.read<int>('amount'),
            soulSatisfaction: r.read<int>('soul_satisfaction'),
          ))
      .toList();
}

class SoulRowAmountSat {
  final int amount;
  final int soulSatisfaction;
  const SoulRowAmountSat({required this.amount, required this.soulSatisfaction});
}
```

**`getSharedJoyCategoryInsight` new method.** Mirror the GROUP BY pattern from
`getSatisfactionDistribution:262-292`, with HAVING + tie-break:
```dart
/// FAMILY-02 (D-08): category argmax over an arbitrary set of book_ids.
/// min-N=3 guard at SQL level; tie-break via ORDER BY count DESC, category_id ASC.
/// Returns null when no category meets min-N (use case maps to MetricResult.empty).
Future<SharedJoyCategoryDaoResult?> getSharedJoyCategoryInsight({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (bookIds.isEmpty) return null;
  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final results = await _db.customSelect(
    'SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
    'FROM transactions '
    'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
    'AND timestamp >= ? AND timestamp <= ? '
    'GROUP BY category_id '
    'HAVING COUNT(*) >= 3 '
    'ORDER BY avg_sat DESC, cnt DESC, category_id ASC '
    'LIMIT 1',
    variables: [
      ...bookIds.map(Variable.withString),
      Variable.withDateTime(startDate),
      Variable.withDateTime(endDate),
    ],
  ).get();
  if (results.isEmpty) return null;
  final row = results.first;
  return SharedJoyCategoryDaoResult(
    categoryId: row.read<String>('category_id'),
    avgSatisfaction: row.read<double>('avg_sat'),
    totalCount: row.read<int>('cnt'),
  );
}
```

**Notes:**
- Encryption discipline: queries deliberately omit `note` (encrypted by `FieldEncryptionService`).
- All new queries reuse `$_soulExpenseFilter`; refactoring the 3 existing queries to do the
  same is SQL-equivalent (string concat) and pays the centralization dividend.
- `IN (?,?,?...)` placeholder pattern is required by drift's `customSelect`; build dynamically.

---

### Role: `repository_interface` (abstract)

#### Modify `lib/features/analytics/domain/repositories/analytics_repository.dart`

**Closest analog:** the file itself (`analytics_repository.dart:4-30`).

**Excerpt** (`analytics_repository.dart:1-30`):
```dart
import '../models/analytics_aggregate.dart';

abstract class AnalyticsRepository {
  Future<MonthlyTotals> getMonthlyTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<CategoryTotal>> getCategoryTotals({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
    String type = 'expense',
  });
  /* ... */
}
```

**Adapt** — add 4 method signatures (return DAO-result types or domain types). Recommendation:
return DAO-result types directly (the use case is in `application/`, can import DAO row types
because DAO row types live in `data/daos/analytics_dao.dart` and the *interface* lives in
`features/analytics/domain/`). **CRITICAL — domain layer purity:** the domain layer's
`import_guard.yaml:7-12` denies imports from `data/`. Therefore the interface MUST return
**domain-layer types** only. Two options:

1. Promote the 3 new DAO row classes (`SoulRowAmountSat`, `BestJoyMomentDaoResult`,
   `SharedJoyCategoryDaoResult`) to plain Dart classes in
   `lib/features/analytics/domain/models/analytics_aggregate.dart` (matches the existing
   `MonthlyTotals` / `CategoryTotal` pattern at `analytics_aggregate.dart:1-33`).
2. Define mirror domain types and have the repository impl translate (matches the
   existing `getMonthlyTotals` flow at `analytics_repository_impl.dart:11-27`).

**Recommended**: Option 2. Mirror the existing established pattern verbatim. New domain
types in `analytics_aggregate.dart`:

```dart
// extend analytics_aggregate.dart with:
class SoulSatisfactionOverview {
  final double avgSatisfaction;
  final int count;
  const SoulSatisfactionOverview({required this.avgSatisfaction, required this.count});
}

class SoulRowSample {
  final int amount;
  final int soulSatisfaction;
  const SoulRowSample({required this.amount, required this.soulSatisfaction});
}

class SatisfactionScoreBucket {
  final int score;
  final int count;
  const SatisfactionScoreBucket({required this.score, required this.count});
}

class SharedJoyCategoryAggregate {
  final String categoryId;
  final double avgSatisfaction;
  final int totalCount;
  const SharedJoyCategoryAggregate({
    required this.categoryId,
    required this.avgSatisfaction,
    required this.totalCount,
  });
}
```

Note the planner may also choose to use `BestJoyMomentRow` (Freezed, in domain) directly as
the repository return type — that is also clean since the row already lives in domain.

**Adapted interface additions:**
```dart
// in analytics_repository.dart
Future<SoulSatisfactionOverview> getSoulSatisfactionOverview({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
});

Future<List<SatisfactionScoreBucket>> getSatisfactionDistribution({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
});

Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
});

Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
});

Future<SharedJoyCategoryAggregate?> getSharedJoyCategoryInsight({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
});
```

---

### Role: `repository_impl` — DAO → domain mapping

#### Modify `lib/data/repositories/analytics_repository_impl.dart`

**Closest analog:** `analytics_repository_impl.dart:11-93` — the existing 4 method impls.

**Excerpt** (`analytics_repository_impl.dart:30-52`):
```dart
@override
Future<List<CategoryTotal>> getCategoryTotals({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  String type = 'expense',
}) async {
  final results = await _dao.getCategoryTotals(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
    type: type,
  );

  return results
      .map(
        (row) => CategoryTotal(
          categoryId: row.categoryId,
          totalAmount: row.totalAmount,
          transactionCount: row.transactionCount,
        ),
      )
      .toList();
}
```

**Adapt** — one impl per new method, plain DAO-row → domain-class mapping:
```dart
@override
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final result = await _dao.getBestJoyMoment(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
  if (result == null) return null;
  return BestJoyMomentRow(
    transactionId: result.transactionId,
    amount: result.amount,
    soulSatisfaction: result.soulSatisfaction,
    categoryId: result.categoryId,
    timestamp: result.timestamp,
  );
}
```

---

### Role: `use_case`

#### `lib/application/analytics/get_happiness_report_use_case.dart` (NEW)
#### `lib/application/analytics/get_best_joy_moment_use_case.dart` (NEW)
#### `lib/application/analytics/get_family_happiness_use_case.dart` (NEW)

**Closest analog:** `lib/application/analytics/get_monthly_report_use_case.dart:1-122`
(same folder, same project convention, same shape).

**Excerpt** (`get_monthly_report_use_case.dart:13-54`):
```dart
class GetMonthlyReportUseCase {
  GetMonthlyReportUseCase({
    required AnalyticsRepository analyticsRepository,
    required CategoryRepository categoryRepository,
  }) : _analyticsRepository = analyticsRepository,
       _categoryRepo = categoryRepository;

  final AnalyticsRepository _analyticsRepository;
  final CategoryRepository _categoryRepo;

  Future<MonthlyReport> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // Run independent queries in parallel
    final results = await Future.wait([
      _analyticsRepository.getMonthlyTotals(
        bookId: bookId, startDate: startDate, endDate: endDate,
      ),
      _analyticsRepository.getCategoryTotals(
        bookId: bookId, startDate: startDate, endDate: endDate,
      ),
      /* ... */
    ]);

    final totals = results[0] as MonthlyTotals;
    /* ... */

    return MonthlyReport(/* ... */);
  }
}
```

**Adapt to `GetHappinessReportUseCase`** — mirror precisely:
```dart
class GetHappinessReportUseCase {
  GetHappinessReportUseCase({
    required AnalyticsRepository analyticsRepository,
  }) : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  // D-04 PTVF constants (centralized; ADR-013 references this).
  static const double _ptvfAlpha = 0.88;

  Future<HappinessReport> execute({
    required String bookId,
    required int year,
    required int month,
    required String currencyCode, // D-04: drives PTVF base lookup
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final results = await Future.wait([
      _repo.getSoulSatisfactionOverview(
        bookId: bookId, startDate: startDate, endDate: endDate),     // 0
      _repo.getSatisfactionDistribution(
        bookId: bookId, startDate: startDate, endDate: endDate),     // 1
      _repo.getSoulRowsForPtvf(
        bookId: bookId, startDate: startDate, endDate: endDate),     // 2
      _repo.getBestJoyMoment(
        bookId: bookId, startDate: startDate, endDate: endDate),     // 3
    ]);

    final overview = results[0] as SoulSatisfactionOverview;
    final distribution = results[1] as List<SatisfactionScoreBucket>;
    final ptvfRows = results[2] as List<SoulRowSample>;
    final topJoy = results[3] as BestJoyMomentRow?;

    final totalSoulTx = overview.count;

    if (totalSoulTx == 0) {
      return HappinessReport(
        year: year, month: month, bookId: bookId,
        totalSoulTx: 0,
        avgSatisfaction: const Empty(),
        joyPerYen: const Empty(),
        medianSatisfaction: const Empty(),
        highlightsCount: const Empty(),
        topJoy: const Empty(),
      );
    }

    final base = ptvfBaseFor(currencyCode); // from joy_density_formatter.dart
    final density = _computePtvfDensity(ptvfRows, base);
    final median = _computeMedianFromDistribution(distribution);
    final highlights = _countHighlights(distribution); // sat >= 6 (D-05)

    return HappinessReport(
      year: year, month: month, bookId: bookId,
      totalSoulTx: totalSoulTx,
      avgSatisfaction: Value(overview.avgSatisfaction, totalSoulTx),
      joyPerYen: Value(density, totalSoulTx),
      medianSatisfaction: Value(median, totalSoulTx),
      highlightsCount: Value(highlights, totalSoulTx),
      topJoy: topJoy == null ? const Empty() : Value(topJoy, totalSoulTx),
    );
  }

  // D-04 verbatim: density = Σ(sat × (amount/base)^0.88) / Σ(amount).
  double _computePtvfDensity(List<SoulRowSample> rows, double base) {
    if (rows.isEmpty) return 0;
    var num = 0.0;
    var den = 0;
    for (final r in rows) {
      final scaled = math.pow(r.amount / base, _ptvfAlpha).toDouble();
      num += r.soulSatisfaction * scaled;
      den += r.amount;
    }
    if (den == 0) return 0;
    return num / den;
  }

  // RESEARCH Q2 Option A — count-keyed walk over distribution.
  double _computeMedianFromDistribution(List<SatisfactionScoreBucket> dist) {
    final total = dist.fold<int>(0, (s, d) => s + d.count);
    if (total == 0) return 0;
    final isEven = total % 2 == 0;
    final midIndex = total ~/ 2;
    var cumulative = 0;
    int? lower;
    for (final d in dist) {
      cumulative += d.count;
      if (lower == null && cumulative > (isEven ? midIndex - 1 : midIndex)) {
        lower = d.score;
      }
      if (cumulative > midIndex) {
        return isEven ? (lower! + d.score) / 2.0 : d.score.toDouble();
      }
    }
    return 0; // unreachable when total > 0
  }

  int _countHighlights(List<SatisfactionScoreBucket> dist) {
    var c = 0;
    for (final d in dist) {
      if (d.score >= 6) c += d.count; // D-05 threshold
    }
    return c;
  }
}
```

**Adapt to `GetBestJoyMomentUseCase`** — single repo call, single MetricResult return:
```dart
class GetBestJoyMomentUseCase {
  GetBestJoyMomentUseCase({required AnalyticsRepository analyticsRepository})
      : _repo = analyticsRepository;
  final AnalyticsRepository _repo;

  Future<MetricResult<BestJoyMomentRow>> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final overview = await _repo.getSoulSatisfactionOverview(
      bookId: bookId, startDate: startDate, endDate: endDate);
    if (overview.count == 0) return const Empty();

    final row = await _repo.getBestJoyMoment(
      bookId: bookId, startDate: startDate, endDate: endDate);
    if (row == null) return const Empty();
    return Value(row, overview.count);
  }
}
```

**Adapt to `GetFamilyHappinessUseCase`** — fan-out across `groupBookIds: List<String>` (D-09):
```dart
class GetFamilyHappinessUseCase {
  GetFamilyHappinessUseCase({required AnalyticsRepository analyticsRepository})
      : _repo = analyticsRepository;
  final AnalyticsRepository _repo;

  Future<FamilyHappiness> execute({
    required List<String> groupBookIds, // D-09: presentation resolves via shadowBooksProvider
    required int year,
    required int month,
  }) async {
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    if (groupBookIds.isEmpty) {
      return FamilyHappiness(
        year: year, month: month,
        totalGroupSoulTx: 0,
        familyHighlightsSum: const Empty(),
        sharedJoyInsight: const Empty(),
        medianSatisfaction: const Empty(),
      );
    }

    // Fan out per shadow book + one cross-book category argmax in parallel.
    final overviews = await Future.wait(groupBookIds.map((id) =>
        _repo.getSoulSatisfactionOverview(
          bookId: id, startDate: startDate, endDate: endDate)));
    final distributions = await Future.wait(groupBookIds.map((id) =>
        _repo.getSatisfactionDistribution(
          bookId: id, startDate: startDate, endDate: endDate)));
    final sharedJoy = await _repo.getSharedJoyCategoryInsight(
      bookIds: groupBookIds, startDate: startDate, endDate: endDate);

    final totalGroupSoulTx = overviews.fold<int>(0, (s, o) => s + o.count);
    if (totalGroupSoulTx == 0) {
      return FamilyHappiness(/* all-empty as above with totalGroupSoulTx=0 */);
    }

    // FAMILY-01 (D-07): aggregate-only int — no Map<MemberId, int>.
    final highlights = _aggregateHighlights(distributions); // sat >= 6
    final groupMedian = _computeGroupMedian(distributions);

    return FamilyHappiness(
      year: year, month: month,
      totalGroupSoulTx: totalGroupSoulTx,
      familyHighlightsSum: Value(highlights, totalGroupSoulTx),
      sharedJoyInsight: sharedJoy == null
          ? const Empty()
          : Value(SharedJoyInsight(
              categoryId: sharedJoy.categoryId,
              avgSatisfaction: sharedJoy.avgSatisfaction,
              totalCount: sharedJoy.totalCount,
            ), totalGroupSoulTx),
      medianSatisfaction: Value(groupMedian, totalGroupSoulTx),
    );
  }
}
```

**Notes:**
- `import 'dart:math' as math;` for `math.pow` (Dart core; no new dep).
- Constructor injection — single `AnalyticsRepository` for happiness use cases (no
  `CategoryRepository` since FAMILY-02 returns `categoryId` not `categoryName` per D-08).
- `_computeMedian*` and `_countHighlights` are private helpers; share via private
  extension or duplicate (project precedent: `get_monthly_report_use_case.dart` duplicates
  `_buildCategoryBreakdowns` style helpers — fine to duplicate; planner decides DRY-ness).

---

### Role: `formatter` (i18n)

#### `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` (NEW)

**Closest analog:** `lib/infrastructure/i18n/formatters/number_formatter.dart:1-78`
(same directory, same `Locale` parameter convention, same `intl` 0.20.2 usage).

**Excerpt** (`number_formatter.dart:1-23`):
```dart
import 'dart:ui';

import 'package:intl/intl.dart';

class NumberFormatter {
  NumberFormatter._();

  static String formatNumber(num number, Locale locale, {int decimals = 2}) {
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: decimals,
    );
    return formatter.format(number);
  }

  static String formatCurrency(num amount, String currencyCode, Locale locale) {
    final formatter = NumberFormat.currency(
      locale: locale.toString(),
      symbol: _getCurrencySymbol(currencyCode),
      decimalDigits: _getCurrencyDecimals(currencyCode),
    );
    return formatter.format(amount);
  }
  /* ... private _getCurrencySymbol, _getCurrencyDecimals ... */
}
```

**Adapt to `JoyDensityFormatter`** (D-20):
```dart
import 'dart:ui';
import 'package:intl/intl.dart';

// D-04: PTVF base by currency. Co-located with display unit map.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};

const Map<String, ({double multiplier, String label})> _displayUnitByCurrency = {
  'JPY': (multiplier: 1000.0, label: '/ ¥1k'),
  'CNY': (multiplier: 100.0,  label: '/ ¥100'),
  'USD': (multiplier: 1.0,    label: r'/ $1'),
};

/// PTVF base for the given ISO 4217 currency code; falls back to JPY base 500.
double ptvfBaseFor(String currencyCode) =>
    _ptvfBaseByCurrency[currencyCode.toUpperCase()] ?? 500.0;

class JoyDensityFormatter {
  JoyDensityFormatter._();

  static String format(double rawDensity, String currencyCode, Locale locale) {
    final code = currencyCode.toUpperCase();
    final unit = _displayUnitByCurrency[code]
        ?? (multiplier: 1000.0, label: '/ ¥1k'); // JPY fallback
    final scaled = rawDensity * unit.multiplier;
    final formatter = NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: 1,
    );
    return '${formatter.format(scaled)} ${unit.label}';
  }
}
```

**Notes:**
- `ptvfBaseFor` is a top-level function so the use case can `import` and call it
  without a static class qualifier (matches the use case PTVF math co-location intent
  documented in D-20).
- Both maps are top-level `const` (private with `_` prefix) → grep-able, single edit
  point for future EUR/GBP additions per `<deferred>` ideas.
- Locale-aware decimal formatting via `intl 0.20.2` — pinned, no version bump.
- File <60 lines target.

---

### Role: `provider` (Riverpod codegen)

#### `lib/features/analytics/presentation/providers/state_happiness.dart` (NEW)

**Closest analog:** `lib/features/analytics/presentation/providers/state_analytics.dart:1-60`
(same directory, same `state_<aggregate>.dart` convention, same `@riverpod` codegen).
Plus `lib/features/home/presentation/providers/state_shadow_books.dart:66-97`
for the `shadowBooksProvider` consumption pattern (D-09).

**Excerpt** (`state_analytics.dart:30-40`):
```dart
@riverpod
Future<MonthlyReport> monthlyReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}
```

**Excerpt of shadowBooks consumption** (`state_shadow_books.dart:66-97`):
```dart
@riverpod
Future<ShadowAggregate> shadowAggregate(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final shadowBookList = await ref.watch(shadowBooksProvider.future);
  if (shadowBookList.isEmpty) return const ShadowAggregate.empty();

  final reportUseCase = ref.watch(getMonthlyReportUseCaseProvider);
  /* ... fan out per shadow book ... */
}
```

**Adapt to `state_happiness.dart`:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/accounting/presentation/providers/repository_providers.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/home/presentation/providers/state_shadow_books.dart';
import '../../domain/models/family_happiness.dart';
import '../../domain/models/happiness_report.dart';
import '../../domain/models/metric_result.dart';
import 'repository_providers.dart';

part 'state_happiness.g.dart';

/// Personal happiness report for the active book (HAPPY-01..04).
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  // Resolve currency from Book (drives D-04 PTVF base).
  final book = await ref.watch(bookByIdProvider(bookId).future);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: book.currency,
  );
}

/// Best Joy moment story-card data (HAPPY-04).
@riverpod
Future<MetricResult<BestJoyMomentRow>> bestJoyMoment(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getBestJoyMomentUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}

/// Family happiness report — short-circuits to "all-empty" when no group is active.
@riverpod
Future<FamilyHappiness> familyHappiness(
  Ref ref, {
  required int year,
  required int month,
}) async {
  final inGroup = ref.watch(isGroupModeProvider);
  if (!inGroup) {
    return FamilyHappiness(
      year: year, month: month,
      totalGroupSoulTx: 0,
      familyHighlightsSum: const Empty(),
      sharedJoyInsight: const Empty(),
      medianSatisfaction: const Empty(),
    );
  }
  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((s) => s.book.id).toList();
  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  return useCase.execute(
    groupBookIds: groupBookIds,
    year: year,
    month: month,
  );
}
```

**Notes:**
- Riverpod codegen requires `part 'state_happiness.g.dart';` — run `build_runner` after.
- `bookByIdProvider` import path may need verification by the executor; if absent, use
  `bookRepositoryProvider.findById(bookId)` and inline.
- Single-source-of-truth: no provider definitions duplicated; use case providers come
  from the existing `repository_providers.dart` (modified in this same phase).
- Short-circuit logic for family is INSIDE the provider (per CONTEXT.md "Known forbidden
  patterns": "Conditionally subscribing family provider inside widget build()").

---

### Role: `provider wiring` — modify `repository_providers.dart`

#### Modify `lib/features/analytics/presentation/providers/repository_providers.dart`

**Closest analog:** the file itself (`repository_providers.dart:30-51`) — already wires 3 use
case providers in the same idiom.

**Excerpt** (`repository_providers.dart:30-51`):
```dart
/// GetMonthlyReportUseCase provider.
@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(Ref ref) {
  return GetMonthlyReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
  );
}

/// GetBudgetProgressUseCase provider.
@riverpod
GetBudgetProgressUseCase getBudgetProgressUseCase(Ref ref) {
  return GetBudgetProgressUseCase();
}

/// GetExpenseTrendUseCase provider.
@riverpod
GetExpenseTrendUseCase getExpenseTrendUseCase(Ref ref) {
  return GetExpenseTrendUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Adapt — append 3 new providers:**
```dart
/// GetHappinessReportUseCase provider (Phase 9 / HAPPY-01..04).
@riverpod
GetHappinessReportUseCase getHappinessReportUseCase(Ref ref) {
  return GetHappinessReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// GetBestJoyMomentUseCase provider (Phase 9 / HAPPY-04).
@riverpod
GetBestJoyMomentUseCase getBestJoyMomentUseCase(Ref ref) {
  return GetBestJoyMomentUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

/// GetFamilyHappinessUseCase provider (Phase 9 / FAMILY-01..02).
@riverpod
GetFamilyHappinessUseCase getFamilyHappinessUseCase(Ref ref) {
  return GetFamilyHappinessUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Run `build_runner` after edit** to regenerate `repository_providers.g.dart`.

---

### Role: `table` (Drift schema modify)

#### Modify `lib/data/tables/transactions_table.dart`

**Closest analog:** `transactions_table.dart:35` itself — single-line `withDefault(const Constant(5))`.

**Excerpt** (`transactions_table.dart:34-43`):
```dart
// Soul ledger satisfaction (1-10, default 5)
IntColumn get soulSatisfaction => integer().withDefault(const Constant(5))();

@override
Set<Column> get primaryKey => {id};

@override
List<String> get customConstraints => [
  'CHECK(soul_satisfaction BETWEEN 1 AND 10)',
];
```

**Adapt** (D-02 / D-10):
```dart
// Soul ledger satisfaction (1-10, default 2 — unipolar positive scale per ADR-014)
IntColumn get soulSatisfaction => integer().withDefault(const Constant(2))();
```

**Notes:**
- Comment update is part of the change to record semantic shift (every soul tx is happy
  at least at neutral level).
- CHECK constraint `BETWEEN 1 AND 10` UNCHANGED.

---

### Role: `db wiring` (schema version + migration)

#### Modify `lib/data/app_database.dart`

**Closest analog:** the existing `if (from < 4)` and `if (from < 15)` blocks
(`app_database.dart:58-59`, `:243-262`).

**Excerpt** (`app_database.dart:43-50` and the `from < 4` / `from < 15` examples):
```dart
@override
int get schemaVersion => 15;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      /* ... */
      if (from < 4) {
        await migrator.addColumn(transactions, transactions.soulSatisfaction);
      }
      /* ... */
      if (from < 15) {
        await customStatement(
          'CREATE INDEX IF NOT EXISTS idx_audit_logs_event ON audit_logs (event)',
        );
        /* ... */
      }
    },
  );
}
```

**Adapt** (D-02):
```dart
@override
int get schemaVersion => 16;

@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      /* ... existing v3..v15 blocks unchanged ... */
      if (from < 16) {
        // v16: change `transactions.soul_satisfaction` default 5 → 2.
        // Default applies to NEW inserts only; existing rows (none — pre-launch)
        // are not rewritten. SQLite ALTER TABLE supports column default change
        // via the table-recreation pattern, but Drift transparently handles
        // schema-default-only changes via the regenerated table DDL on cold open.
        // No ALTER COLUMN statement needed for default-change-only when no
        // existing rows depend on the old default.
      }
    },
  );
}
```

**Notes:**
- D-02 explicitly says "No data backfill required — pre-launch" → the `from < 16` block
  may be empty (`/* no-op */`) but MUST exist to consume the version bump cleanly.
- Drift's `customStatement` is the project's escape hatch for raw SQL when migrator
  helpers don't fit. SQLite does NOT support `ALTER COLUMN` for default values prior
  to 3.35 reliably, but since the change is "default for future inserts" and Drift
  regenerates the table DDL via `validateDatabaseSchema` on open, the empty block is
  acceptable. Planner verifies via the Wave-0 migration test
  (`test/unit/data/migrations/migration_v15_to_v16_test.dart`).
- If the executor finds Drift complains on schema validation, add an explicit
  `customStatement('PRAGMA writable_schema = 1; UPDATE sqlite_master SET sql = ... ')`
  pattern, but this is a fallback only. Default-cluster contamination (`T-9-01`) is
  data-side, not schema-side: `demo_data_service.dart:134` is the real concern.

---

### Role: `service` modify (demo_data_service.dart)

#### Modify `lib/application/analytics/demo_data_service.dart`

**Closest analog:** the file itself, line 134.

**Excerpt** (`demo_data_service.dart:130-135`):
```dart
// Soul transactions get random satisfaction (1-10), survival gets default 5
final satisfaction = ledgerType == 'soul'
    ? 1 +
          _random.nextInt(10) // 1..10
    : 5;
```

**Adapt** (D-02 alignment):
```dart
// Soul transactions get random satisfaction (1-10), survival gets default 2
// (unipolar positive scale per ADR-014).
final satisfaction = ledgerType == 'soul'
    ? 1 +
          _random.nextInt(10) // 1..10
    : 2;
```

**Notes:**
- Only the `else` branch changes (`5` → `2`); the soul branch's `1..10` random range
  is unchanged.
- Comment update reflects new semantic.

---

### Role: `adr` (markdown architectural decision records)

#### NEW `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md`
#### NEW `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md`
#### NEW `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md`

**Closest analog:** `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md:1-80`
(most recent ADR, project's current header convention).

**Excerpt** (`ADR-011_Codebase_Cleanup_Initiative_Outcome.md:1-37`):
```markdown
# ADR-011: Codebase Cleanup Initiative Outcome

**文档编号:** ADR-011
**文档版本:** 1.1
**创建日期:** 2026-04-27
**最后更新:** 2026-04-28 (append-only Update 章节; 见文末)
**状态:** ✅ 已接受
**决策者:** Architecture Team
**影响范围:** 全局重构（Phases 3–6）, CI 守门, 测试基础设施
**相关 ADR:** ADR-002 (Database Solution), ADR-007 (Layer Responsibilities), ...

---

## 📋 状态

**当前状态:** ✅ 已接受
**决策日期:** 2026-04-27
**实施状态:** 已完成 (Phases 3–6 已落地)

---

## 🎯 背景 (Context)

[narrative ...]

---

## 🔍 考虑的方案 (Considered Options)

### 清理方案

**采用方案（已实施）：** ...

**拒绝的备选方案：**
- ...

---

## ✅ 决策 (Decision)

[decision body ...]
```

**Adapt — required sections** (per `.claude/rules/arch.md`):
1. 📋 状态 (Status)
2. 🎯 背景 (Context)
3. 🔍 考虑的方案 (Considered Options)
4. ✅ 决策 (Decision)
5. 💡 决策理由 (Rationale)
6. ⚖️ 后果 (Consequences)
7. 📅 实施计划 (Implementation Plan)

**ADR-012 framing seeds** (D-22.1):
- Cite Goodhart's Law (Goodhart, 1975).
- Reference HAPPY-07 in REQUIREMENTS.md.
- Forbidden anti-features: streaks, badges, daily targets, cross-period delta on home,
  public sharing.
- Binding through milestone v1.1 close.

**ADR-013 framing seeds** (D-22.2):
- Cite Kahneman & Tversky (1979). "Prospect Theory: An Analysis of Decision under Risk."
  *Econometrica*, 47(2), 263–292.
- α=0.88 empirical fit.
- Currency-aware base table: JPY=500, CNY=25, USD=5, fallback=500.
- Dart-layer fold rationale: SQLite has no `POW`/`EXP`.
- Performance trade-off vs `analytics_dao.dart:85` "<2s SUM/GROUP BY" principle —
  with monthly soul tx counts of 10–100, row-wise fetch is negligible.
- Reference `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` for centralized
  base map.

**ADR-014 framing seeds** (D-22.3):
- Default 5 → 2 schema migration; reference D-02 / D-10.
- Picker emoji semantic remap (Phase 12 ARB rename pass listed in D-11).
- Default-vs-Neutral collision (`SatisfactionEmojiPicker` writes 2/4/6/8/10) explicitly
  accepted.
- Voice estimator output range realignment deferred to v1.2 (D-12).
- Product framing: "every soul transaction is happy at least at neutral level."

---

### Role: `adr index` modify

#### Modify `docs/arch/03-adr/ADR-000_INDEX.md`

**Closest analog:** the existing entries (`ADR-000_INDEX.md:14-60` shows the per-entry shape).

**Excerpt** (`ADR-000_INDEX.md:16-37`):
```markdown
### [ADR-001: 选择Riverpod作为状态管理方案](./ADR-001_State_Management.md)

**状态:** ✅ 已接受
**日期:** 2026-02-03
**影响范围:** 整个应用的状态管理层

**核心决策:**
选择 **flutter_riverpod 2.x** 作为状态管理方案

**关键理由:**
- 编译时类型安全
- ...

**备选方案:**
- ...
```

**Adapt — append 3 entries** (ADR-012, ADR-013, ADR-014) using identical structure.
Update `**最后更新:**` field at file top.

---

### Role: `spec` modify (`.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`)

#### Modify `.planning/REQUIREMENTS.md`

No close code analog — these are project planning markdown documents. Apply the
amendments from D-22 spec amendments block in CONTEXT.md verbatim:
- HAPPY-02 PTVF α=0.88 with currency-aware base, Dart-layer fold
- HAPPY-03 threshold ≥8 → ≥6
- HAPPY-04 pure sat sort, ¥500 floor removed
- HAPPY-08 emoji ↔ value mapping table (new unipolar positive semantic)
- HAPPY-09 removed → HAPPY-V2-03 absorbs
- FAMILY-01 threshold ≥8 → ≥6, returns `int` only

#### Modify `.planning/ROADMAP.md`

- Phase 9 critical pitfalls: remove ¥500 floor item (D-06); remove voice-bias regression
  test item (D-18); add schema bump v15 → v16 item; add PTVF α=0.88 + Dart-fold trade-off
  item.
- Phase 12 scope expansion: 5 emoji ARB labels rename + picker icon update.

---

## Test Patterns

### Test analog — Drift migration

#### `test/unit/data/migrations/migration_v15_to_v16_test.dart` (NEW Wave 0)

**Closest analog:** `test/unit/data/migrations/index_v15_migration_test.dart:1-120`.

**Excerpt** (`index_v15_migration_test.dart:1-30`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:sqlite3/sqlite3.dart';

const _targetSchemaVersion = 15;

void main() {
  test('AppDatabase schemaVersion is 15', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    expect(db.schemaVersion, _targetSchemaVersion);
  });

  group('v15 index migration', () {
    late Database rawDb;

    setUp(() {
      rawDb = sqlite3.openInMemory();
      _createV14Tables(rawDb);
    });
    /* ... */
  });
}
```

**Adapt for v15→v16:**
```dart
const _targetSchemaVersion = 16;

void main() {
  test('AppDatabase schemaVersion is 16', () {
    final db = AppDatabase.forTesting();
    addTearDown(db.close);
    expect(db.schemaVersion, _targetSchemaVersion);
  });

  group('v15 → v16 default change', () {
    test('soul_satisfaction default is 2 on fresh schema', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // Insert a transaction without specifying soul_satisfaction.
      // (Use TransactionDao.insertTransaction with the param omitted.)
      // Verify the row reads back with soul_satisfaction == 2.
    });

    test('CHECK(soul_satisfaction BETWEEN 1 AND 10) survives', () async {
      final db = AppDatabase.forTesting();
      addTearDown(db.close);
      // Attempt insert with soul_satisfaction = 11; expect SQLite constraint failure.
    });
  });
}
```

### Test analog — DAO

#### `test/unit/data/daos/analytics_dao_happiness_test.dart` (NEW Wave 0)

**Closest analog:** `test/unit/data/daos/transaction_dao_test.dart` and the
`get_monthly_report_use_case_test.dart` setup pattern at `:1-55`. Same `AppDatabase.forTesting()`,
seed-then-query idiom.

### Test analog — use case

#### `test/unit/application/analytics/get_happiness_report_use_case_test.dart` (NEW Wave 0)

**Closest analog:** `test/unit/application/analytics/get_monthly_report_use_case_test.dart:1-130`.

**Excerpt** (use case test setup, `:19-55`):
```dart
late AppDatabase database;
late AnalyticsDao analyticsDao;
late AnalyticsRepositoryImpl analyticsRepository;
late CategoryDao categoryDao;
late TransactionDao transactionDao;
late CategoryRepositoryImpl categoryRepo;
late GetMonthlyReportUseCase useCase;

setUp(() async {
  database = AppDatabase.forTesting();
  analyticsDao = AnalyticsDao(database);
  analyticsRepository = AnalyticsRepositoryImpl(dao: analyticsDao);
  /* ... */
  useCase = GetMonthlyReportUseCase(
    analyticsRepository: analyticsRepository,
    categoryRepository: categoryRepo,
  );

  await categoryDao.insertCategory(
    id: 'cat_food', name: 'Food', icon: '🍕', color: '#FF0000',
    level: 1, isSystem: true, createdAt: DateTime(2026, 1, 1),
  );
});

tearDown(() async {
  await database.close();
});
```

**Excerpt of `closeTo` matcher use** (`:128`):
```dart
// savingsRate = 220000/300000 * 100 ≈ 73.3
expect(report.savingsRate, closeTo(73.3, 0.1));
```

**Adapt for PTVF math** (VALIDATION map task 09-05-02):
```dart
test('PTVF α=0.88 fold matches reference for JPY base 500', () async {
  // Seed soul tx: amount=500, sat=10  → contributes 10 × (500/500)^0.88 = 10
  //               amount=5000, sat=6 → contributes 6 × (5000/500)^0.88 = 6 × 10^0.88
  // expected density = (10 + 6×10^0.88) / 5500
  await transactionDao.insertTransaction(/* 500 / sat=10 / soul / expense */);
  await transactionDao.insertTransaction(/* 5000 / sat=6 / soul / expense */);

  final report = await useCase.execute(
    bookId: 'book1', year: 2026, month: 2, currencyCode: 'JPY');

  final expected = (10 + 6 * math.pow(10, 0.88)) / 5500;
  expect(
    (report.joyPerYen as Value<double>).data,
    closeTo(expected, 1e-9),
  );
});
```

### Test analog — provider wiring

#### `test/unit/application/analytics/repository_providers_test.dart` (NEW Wave 0)

**Closest analog:** `test/unit/application/family_sync/repository_providers_test.dart`
(verified to exist — listed in `ls` output for `application/family_sync/`).

---

## Shared Patterns

### Constructor injection (use cases)

**Source:** `lib/application/analytics/get_monthly_report_use_case.dart:13-21`
**Apply to:** All 3 happiness use cases.

```dart
class FooUseCase {
  FooUseCase({required AnalyticsRepository analyticsRepository})
      : _repo = analyticsRepository;
  final AnalyticsRepository _repo;
  /* single execute() method */
}
```

### Future.wait parallelism

**Source:** `lib/application/analytics/get_monthly_report_use_case.dart:32-54`
**Apply to:** `GetHappinessReportUseCase` (4 parallel repo calls);
`GetFamilyHappinessUseCase` (per-book fan-out + cross-book argmax).

```dart
final results = await Future.wait([
  _repo.callA(...), _repo.callB(...), _repo.callC(...),
]);
final a = results[0] as TypeA;
final b = results[1] as TypeB;
```

### `AppDatabase.forTesting()` test harness

**Source:** `lib/data/app_database.dart:42`,
`test/unit/application/analytics/get_monthly_report_use_case_test.dart:20-30`
**Apply to:** All Wave-0 unit tests touching the DB (DAO + repository + use case + migration).

```dart
late AppDatabase database;
setUp(() async {
  database = AppDatabase.forTesting();
  /* wire DAO + repos + use case via constructors; no Riverpod container */
});
tearDown(() async {
  await database.close();
});
```

### `closeTo` floating-point matcher

**Source:** `test/unit/application/analytics/get_monthly_report_use_case_test.dart:128`
**Apply to:** PTVF math tests (task 09-05-02), median tests (09-05-04), all
`Value<double>` extraction tests.

```dart
expect(actualDouble, closeTo(expectedDouble, 1e-9 /* or 0.1 */));
```

### Hand-written SQL via `customSelect`

**Source:** `lib/data/daos/analytics_dao.dart` lines 99, 138, 174, 207, 237, 269, 302
(7 verified call sites).
**Apply to:** All 3 new DAO methods. NO Drift query DSL — match the established raw-SQL
idiom for grep-ability and consistency.

```dart
final results = await _db.customSelect(
  'SELECT col1, col2 FROM transactions WHERE book_id = ? AND $_soulExpenseFilter '
  'AND timestamp >= ? AND timestamp <= ?',
  variables: [Variable.withString(bookId), Variable.withDateTime(start), ...],
).get();
```

### Riverpod codegen + `Ref` import

**Source:** `lib/features/analytics/presentation/providers/state_analytics.dart:1-10`,
`repository_providers.dart:1-14`
**Apply to:** `state_happiness.dart`, `repository_providers.dart` extensions.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
/* feature-relative imports */
part 'state_happiness.g.dart';

@riverpod
Future<Foo> someFooProvider(Ref ref, {required String arg}) async {
  /* ... */
}
```

After every edit: run `flutter pub run build_runner build --delete-conflicting-outputs`.

### ADR header + section structure

**Source:** `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md:1-37`
**Apply to:** ADR-012, ADR-013, ADR-014.
Required header: 文档编号 / 版本 / 创建日期 / 最后更新 / 状态 / 决策者 / 影响范围 / 相关 ADR.
Required sections: 状态 / 背景 / 考虑的方案 / 决策 / 决策理由 / 后果 / 实施计划.
After status reaches `✅ 已接受`, the file is **append-only** (per `.claude/rules/arch.md`).

---

## No Analog Found

| File | Role | Reason |
|---|---|---|
| `lib/features/analytics/domain/models/metric_result.dart` (generic plain-sealed) | domain_model | Project has zero precedent for **generic** sealed classes. Plain-sealed precedent (`check_group_use_case.dart:10`) is non-generic. The novelty is intentional and locked by D-13. Planner uses the non-generic plain-sealed pattern as the closest template; the only new shape is the type parameter `<T>`. |

---

## Metadata

**Analog search scope:**
- `lib/application/analytics/`
- `lib/application/family_sync/` (sealed classes precedent)
- `lib/data/daos/`, `lib/data/repositories/`, `lib/data/tables/`, `lib/data/app_database.dart`
- `lib/features/analytics/{domain,presentation}/`
- `lib/features/home/presentation/providers/state_shadow_books.dart`
- `lib/features/family_sync/presentation/providers/state_active_group.dart`
- `lib/infrastructure/i18n/formatters/`
- `lib/core/initialization/init_result.dart` (sealed Freezed precedent)
- `test/unit/application/analytics/`, `test/unit/data/{daos,migrations}/`
- `docs/arch/03-adr/ADR-011_*.md`

**Files scanned:** 22 (8 production, 4 test, 2 ADR/spec, 8 supporting reads).

**Pattern extraction date:** 2026-05-01

## PATTERN MAPPING COMPLETE
