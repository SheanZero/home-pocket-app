# Architecture Research — v1.1 Happiness Metric & Display

**Domain:** Local-first Flutter accounting app — happiness metric integration into existing 5-layer Clean Architecture
**Researched:** 2026-05-01
**Confidence:** HIGH (verified directly against the live `lib/` tree; all path/symbol claims grounded in source reads)

> **Scope note.** This file answers the 8 integration questions asked in the milestone prompt. The existing 5-layer architecture is *already* documented in `.planning/codebase/ARCHITECTURE.md` (2026-04-25, v1.0 baseline) — this file builds on top of it rather than re-stating it. Read that file first if you need the layer/data-flow primer.

---

## System Overview — Where v1.1 Components Land

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PRESENTATION LAYER                                  │
│  features/home/presentation/                features/analytics/presentation/ │
│  ┌─────────────────────────────┐            ┌──────────────────────────────┐│
│  │ screens/home_screen.dart    │            │ screens/analytics_screen.dart││
│  │   ├─ MonthOverviewCard      │            │   ├─ Summary / Pie / Daily   ││
│  │   ├─ LedgerComparisonSec.   │            │   ├─ LedgerRatio / Budget    ││
│  │   └─ SoulFullnessCard ★MOD  │            │   └─ ★NEW HappinessSection   ││
│  │       (rebuilt: 4 tiles +   │            │       (4 widgets reading     ││
│  │        story card)          │            │        dormant DAOs)         ││
│  │                             │            │                              ││
│  │ widgets/                    │            │ widgets/                     ││
│  │   soul_fullness_card.dart◐  │            │   ★joy_density_trend.dart    ││
│  │   ★best_joy_moment_card.    │            │   ★satisfaction_histogram.   ││
│  │   ★family_highlights_card.  │            │   ★joy_summary_section.dart  ││
│  │                             │            │                              ││
│  │ providers/                  │            │ providers/                   ││
│  │   state_home.dart◐          │            │   state_analytics.dart◐      ││
│  │   ★state_happiness.dart     │            │   (extend with happiness     ││
│  │   (re-exports from analytics│            │    providers — same family)  ││
│  │    OR direct)               │            │                              ││
│  └─────────────────────────────┘            └──────────────────────────────┘│
└──────────────────┬─────────────────────────────────┬────────────────────────┘
                   │ ref.watch(...Provider)          │
┌──────────────────┴─────────────────────────────────┴────────────────────────┐
│                          APPLICATION LAYER (GLOBAL)                          │
│  lib/application/analytics/                                                  │
│    get_monthly_report_use_case.dart       (existing)                         │
│    get_expense_trend_use_case.dart        (existing)                         │
│    get_budget_progress_use_case.dart      (existing)                         │
│    ★get_happiness_report_use_case.dart    (NEW — primary)                    │
│    ★get_best_joy_moment_use_case.dart     (NEW — story card)                 │
│    ★get_family_happiness_use_case.dart    (NEW — group mode only)            │
│    repository_providers.dart              (extend: add use case providers)   │
└──────────────────┬─────────────────────────────────────────────────────────┘
                   │ uses                                          implements
┌──────────────────┴────────────────────────┐  ┌──────────────────────────────┐
│   DOMAIN LAYER (per feature)              │  │       DATA LAYER             │
│   features/analytics/domain/              │  │  lib/data/                   │
│     models/                               │  │    daos/                     │
│       monthly_report.dart       (existing)│  │      analytics_dao.dart◐     │
│       budget_progress.dart      (existing)│  │      (3 dormant methods —    │
│       expense_trend.dart        (existing)│  │       wire only, no schema)  │
│       analytics_aggregate.dart  (existing)│  │      ★+1 method:             │
│       ★happiness_report.dart    (NEW)     │  │        getBestJoyMoment()    │
│       ★best_joy_moment.dart     (NEW)     │  │    repositories/             │
│       ★family_happiness.dart    (NEW)     │  │      analytics_repository_   │
│     repositories/                         │  │        impl.dart◐ (extend)   │
│       analytics_repository.dart◐ (extend) │  │                              │
└───────────────────────────────────────────┘  └──────────────────────────────┘

★ = NEW file/symbol     ◐ = MODIFIED existing file     (no mark) = unchanged
```

### Component Responsibilities (v1.1 deltas only)

| Component | Layer | Status | Responsibility |
|-----------|-------|--------|----------------|
| `HappinessReport` Freezed model | analytics/domain/models | NEW | Holds 4 personal metrics (avgSat, joyPerYen, highlightCount, bestJoyMoment ref) + optional 2 family fields |
| `BestJoyMoment` Freezed model | analytics/domain/models | NEW | Story card: single transaction id + amount + satisfaction + categoryId + timestamp + computed joyPerYen |
| `FamilyHappiness` Freezed model | analytics/domain/models | NEW | 2 cooperative metrics (familyHighlightsSum, sharedJoyInsight: List<CategorySatisfaction>) |
| `GetHappinessReportUseCase` | application/analytics | NEW | Wires `getSoulSatisfactionOverview` + `getSatisfactionDistribution` + `getBestJoyMoment` into `HappinessReport`. Mirrors `GetMonthlyReportUseCase` shape. |
| `GetBestJoyMomentUseCase` | application/analytics | NEW | Returns single `BestJoyMoment` for the month. Uses a new DAO query (see Q4). |
| `GetFamilyHappinessUseCase` | application/analytics | NEW | Group-mode only. Aggregates over all books visible in current group. |
| `AnalyticsRepository` interface | analytics/domain/repositories | EXTEND | Add `getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`, `getBestJoyMoment` method signatures. |
| `AnalyticsRepositoryImpl` | data/repositories | EXTEND | Implement the 4 new interface methods by delegating to existing/new DAO methods. |
| `AnalyticsDao` | data/daos | ADD ONE METHOD | Add `getBestJoyMoment` only. The 3 satisfaction methods already exist (verified in `lib/data/daos/analytics_dao.dart` lines 230–327). |
| `state_happiness.dart` | features/analytics/presentation/providers | NEW | New `@riverpod` providers: `happinessReportProvider`, `bestJoyMomentProvider`, `familyHappinessProvider`, `joyPerYenTrendProvider` (derived). |
| `SoulFullnessCard` | features/home/presentation/widgets | REBUILT | Replaces 2-tile (Satisfaction + ROI) layout with 4-tile + story card + conditional family card. Becomes container widget that takes `HappinessReport`. |
| `BestJoyMomentCard` | features/home/presentation/widgets | NEW | Story card extracted from `SoulFullnessCard` for reusability between Home and Analytics screens. |
| `FamilyHighlightsCard` | features/home/presentation/widgets | NEW | Conditional sub-widget for 2 family metrics. Group mode only. |
| `JoyDensityTrendChart` | features/analytics/presentation/widgets | NEW | Joy-per-¥ line chart (mirror `ExpenseTrendChart` shape but uses `getDailySatisfactionTrend`). |
| `SatisfactionHistogram` | features/analytics/presentation/widgets | NEW | Score-frequency bar chart (mirror `DailyExpenseChart` shape). |
| `JoyLedgerStatisticsSection` | features/analytics/presentation/widgets | NEW | Section header + composes the two charts above. Inserted between `LedgerRatioChart` and `BudgetProgressList` in `analytics_screen.dart`. |

### What is NOT changing (per Out-of-Scope locks)

- `lib/data/tables/transactions_table.dart` — no schema mutation
- `lib/data/app_database.dart` — no version bump
- `lib/features/accounting/domain/models/transaction.dart` — no field added
- `LedgerType` enum — values stay `survival` / `soul`
- `lib/core/theme/app_colors.dart` — color tokens stay (`#5A9CC8`, `#47B88A`, `#8AB8DA`)
- `SatisfactionEmojiPicker`, `VoiceSatisfactionEstimator` — input pipeline untouched

---

## Recommended Project Structure (v1.1 file additions)

```
lib/
├── application/analytics/                                # GLOBAL use cases
│   ├── get_monthly_report_use_case.dart                  # existing
│   ├── get_expense_trend_use_case.dart                   # existing
│   ├── get_budget_progress_use_case.dart                 # existing
│   ├── get_happiness_report_use_case.dart                # ★ NEW (primary)
│   ├── get_best_joy_moment_use_case.dart                 # ★ NEW (single-tx argmax)
│   ├── get_family_happiness_use_case.dart                # ★ NEW (group mode)
│   ├── repository_providers.dart                         # ◐ EXTEND (add new use case providers)
│   └── repository_providers.g.dart                       # regenerated
│
├── data/
│   ├── daos/
│   │   └── analytics_dao.dart                            # ◐ EXTEND (+ 1 method: getBestJoyMoment)
│   └── repositories/
│       └── analytics_repository_impl.dart                # ◐ EXTEND (+ 4 method impls)
│
├── features/analytics/
│   ├── domain/
│   │   ├── models/
│   │   │   ├── happiness_report.dart                     # ★ NEW (Freezed)
│   │   │   ├── happiness_report.freezed.dart             # generated
│   │   │   ├── happiness_report.g.dart                   # generated
│   │   │   ├── best_joy_moment.dart                      # ★ NEW (Freezed)
│   │   │   ├── best_joy_moment.freezed.dart              # generated
│   │   │   ├── best_joy_moment.g.dart                    # generated
│   │   │   ├── family_happiness.dart                     # ★ NEW (Freezed)
│   │   │   ├── family_happiness.freezed.dart             # generated
│   │   │   ├── family_happiness.g.dart                   # generated
│   │   │   └── analytics_aggregate.dart                  # ◐ EXTEND (add SatisfactionOverview, SatisfactionDistribution, DailySatisfaction, BestJoyMomentRow domain types)
│   │   └── repositories/
│   │       └── analytics_repository.dart                 # ◐ EXTEND (+ 4 method signatures)
│   └── presentation/
│       ├── providers/
│       │   ├── state_analytics.dart                      # ◐ unchanged or minimal — see Q5
│       │   ├── state_happiness.dart                      # ★ NEW (4 providers)
│       │   └── state_happiness.g.dart                    # generated
│       ├── screens/
│       │   └── analytics_screen.dart                     # ◐ EXTEND (insert JoyLedgerStatisticsSection)
│       └── widgets/
│           ├── joy_density_trend_chart.dart              # ★ NEW
│           ├── satisfaction_histogram.dart               # ★ NEW
│           └── joy_ledger_statistics_section.dart        # ★ NEW
│
├── features/home/presentation/
│   ├── screens/
│   │   └── home_screen.dart                              # ◐ MODIFY (drop _computeSatisfaction / _computeHappinessROI; switch SoulFullnessCard wiring to happinessReportProvider)
│   └── widgets/
│       ├── soul_fullness_card.dart                       # ◐ REBUILT (interface change)
│       ├── best_joy_moment_card.dart                     # ★ NEW
│       └── family_highlights_card.dart                   # ★ NEW
│
└── l10n/
    ├── app_ja.arb                                        # ◐ rename 4 keys + add ~12 new keys
    ├── app_zh.arb                                        # ◐ same
    └── app_en.arb                                        # ◐ same
```

### Structure Rationale

- **Use cases stay in `lib/application/analytics/`, NOT in `features/happiness/`** — Thin Feature rule (`.claude/rules/arch.md` + `CLAUDE.md` "Placement Decision Rule" line 32) forbids `application/` inside `features/`. Existing analytics use cases live there; happiness is the same business-logic domain (analytics over `transactions` table).
- **Domain models in `features/analytics/domain/models/`, NOT a new feature module** — see Q2. Keeping them in analytics avoids cross-feature import sprawl (Home would otherwise import `features/happiness/domain/...` AND `features/analytics/domain/...` for the same screen).
- **DAO additions stay in `analytics_dao.dart`** — the file already groups soul-satisfaction queries (lines 230–327). One more method preserves cohesion. New DAO file would split a query family arbitrarily.
- **Provider lives in analytics presentation, re-imported by Home** — single source of truth. Home already imports from `features/analytics/presentation/providers/state_analytics.dart` (verified `home_screen.dart` line 12), so the precedent is set.

---

## Architectural Patterns (project-specific, applied to v1.1)

### Pattern 1: Use Case Per Aggregate (existing project convention)

**What:** One use case class per Freezed aggregate model returned to the UI. Constructor-injected repositories. `execute()` is the only public method. Internally calls `Future.wait` for parallel DAO queries.

**Project precedent:** `GetMonthlyReportUseCase` (`lib/application/analytics/get_monthly_report_use_case.dart`) bundles 4 parallel `AnalyticsRepository` calls + 1 `CategoryRepository` call into a single `MonthlyReport`.

**Apply to v1.1:** `GetHappinessReportUseCase` parallelises `getSoulSatisfactionOverview` + `getSatisfactionDistribution` + `getBestJoyMoment` into `HappinessReport`. Same shape.

```dart
// lib/application/analytics/get_happiness_report_use_case.dart
class GetHappinessReportUseCase {
  GetHappinessReportUseCase({required AnalyticsRepository analyticsRepository})
    : _analyticsRepository = analyticsRepository;

  final AnalyticsRepository _analyticsRepository;

  Future<HappinessReport> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    final results = await Future.wait([
      _analyticsRepository.getSoulSatisfactionOverview(bookId: bookId, startDate: start, endDate: end),
      _analyticsRepository.getMonthlyTotals(bookId: bookId, startDate: start, endDate: end),  // for soulTotal
      _analyticsRepository.getSatisfactionDistribution(bookId: bookId, startDate: start, endDate: end),
      _analyticsRepository.getBestJoyMoment(bookId: bookId, startDate: start, endDate: end),
    ]);

    final overview = results[0] as SatisfactionOverview;
    final totals = results[1] as MonthlyTotals;
    final distribution = results[2] as List<SatisfactionDistribution>;
    final best = results[3] as BestJoyMoment?;

    final highlightCount = distribution
        .where((d) => d.score >= 8)
        .fold<int>(0, (s, d) => s + d.count);

    final joyPerYen = totals.soulExpenses > 0
        ? overview.avgSatisfaction * overview.count / totals.soulExpenses
        : 0.0;

    return HappinessReport(
      year: year, month: month,
      avgSatisfaction: overview.avgSatisfaction,
      joyPerYen: joyPerYen,
      highlightCount: highlightCount,
      bestJoyMoment: best,
    );
  }
}
```

**Trade-offs:** Slightly heavier than helper functions, but consistent with the codebase. Testable in isolation. Riverpod-friendly.

### Pattern 2: Dormant DAO Wiring (specific to v1.1)

**What:** Three DAO methods (`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`) already exist on `AnalyticsDao` (verified `lib/data/daos/analytics_dao.dart` lines 230–327) but are **not currently called by any repository, use case, or provider**. They are dormant data-access. v1.1 wires them through the layers without touching the queries themselves.

**Apply:** Each dormant DAO method needs:
1. A domain-model counterpart in `analytics_aggregate.dart` (DAO-side has `SatisfactionOverviewResult`; domain side needs `SatisfactionOverview`).
2. A signature on `AnalyticsRepository` (interface).
3. An implementation on `AnalyticsRepositoryImpl` that translates DAO result → domain model (mirrors `getMonthlyTotals` translation pattern, lines 18–28 of `analytics_repository_impl.dart`).
4. Consumption inside a use case (`GetHappinessReportUseCase`).

**Trade-offs:** Boilerplate-heavy (4 layers × 3 methods = 12 surface points), but enforces import_guard layering. Domain stays decoupled from Drift.

### Pattern 3: Container Widget With Async Provider (existing pattern)

**What:** Widget receives a Freezed model directly (not raw values) and is rendered inside an `AsyncValue.when` from the parent screen. The widget itself is a `StatelessWidget` — it does not consume providers.

**Project precedent:** `SoulFullnessCard` today is a `StatelessWidget` taking 3 primitives (`satisfactionPercent`, `happinessROI`, `recentSoulAmount`). The parent `home_screen.dart` line 132 unwraps `reportAsync.when(data: (report) => SoulFullnessCard(...), ...)`.

**Apply to v1.1:** `SoulFullnessCard` becomes `SoulFullnessCard({required HappinessReport report, required bool isGroupMode, FamilyHappiness? familyReport})`. Stays `StatelessWidget`. Widget tests still build it without ProviderScope.

```dart
// home_screen.dart (rebuilt section)
final happinessAsync = ref.watch(happinessReportProvider(bookId: bookId, year: year, month: month));
final familyAsync = isGroupMode
    ? ref.watch(familyHappinessProvider(year: year, month: month))
    : const AsyncValue.data(null);

happinessAsync.when(
  data: (report) => familyAsync.when(
    data: (family) => SoulFullnessCard(
      report: report,
      isGroupMode: isGroupMode,
      familyReport: family,
    ),
    loading: () => SoulFullnessCard(report: report, isGroupMode: false),
    error: (_, __) => SoulFullnessCard(report: report, isGroupMode: false),
  ),
  loading: ...,
  error: ...,
);
```

**Trade-offs:** Two `AsyncValue.when` reads when group mode is on; acceptable since both providers are cheap.

---

## Data Flow

### v1.1 Read Path: Happiness Report

```
[HomeScreen / AnalyticsScreen builds]
    ↓ ref.watch(happinessReportProvider(bookId, year, month))
[state_happiness.dart provider]
    ↓ executes
[GetHappinessReportUseCase.execute()]
    ↓ Future.wait([...])
[AnalyticsRepository] (interface)  ← Domain
    ↓ resolves to
[AnalyticsRepositoryImpl] (data layer)
    ↓ delegates to
[AnalyticsDao]
    ├─ getSoulSatisfactionOverview()      ← dormant, exists
    ├─ getMonthlyTotals()                 ← used by report path; reused for soulExpenses
    ├─ getSatisfactionDistribution()      ← dormant, exists
    └─ getBestJoyMoment()                 ← NEW DAO query
    ↓ raw SQL via _db.customSelect(...)
[SQLCipher-encrypted transactions table]
    ↑ rows
[DAO Result classes]                       ← e.g. SatisfactionOverviewResult
    ↑ mapped to domain types in Repository
[Domain types]                             ← e.g. SatisfactionOverview
    ↑ assembled into
[HappinessReport Freezed model]
    ↑ delivered as AsyncValue<HappinessReport>
[StatelessWidget rendering]
```

### State Management Wiring

```
@riverpod  (in state_happiness.dart)
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}

// useCase provider lives in lib/application/analytics/repository_providers.dart
@riverpod
GetHappinessReportUseCase getHappinessReportUseCase(Ref ref) {
  return GetHappinessReportUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

### Key Data Flows (v1.1-specific)

1. **Personal happiness (HomePage + Analytics):** `bookId` (current book) → `happinessReportProvider` → `HappinessReport` (4 metrics + optional `BestJoyMoment`). Cached per `(bookId, year, month)`.
2. **Family happiness (HomePage, group mode only):** `currentGroupId` → `familyHappinessProvider` → `FamilyHappiness` (2 metrics aggregated across all books in the group's shadow). Conditionally subscribed via `isGroupModeProvider` (verified in `lib/features/family_sync/presentation/providers/state_active_group.g.dart` line 40).
3. **Joy density trend (Analytics):** `bookId` → `joyPerYenTrendProvider` → `List<DailyJoyPoint>` from `getDailySatisfactionTrend` + per-day soul amount join. Drives `JoyDensityTrendChart`.
4. **Satisfaction histogram (Analytics):** `bookId` → derived selector on `happinessReportProvider.distribution` → `SatisfactionHistogram` widget. No new provider — selector inside widget.

---

## Answers to Specific Questions

### Q1. Where does the new HappinessReport domain model live?

**Recommendation:** `lib/features/analytics/domain/models/happiness_report.dart`. Same directory as `monthly_report.dart`, `expense_trend.dart`, `budget_progress.dart`.

**Reasoning:**
- Domain models for analytics-style aggregates are already grouped here (verified directory listing). Adding `happiness_report.dart` continues the pattern.
- `HappinessReport` is purely an analytics aggregate — it has no behavior of its own, no repository interface beyond what `AnalyticsRepository` already covers.
- Putting it under a new `features/happiness/` would violate the Thin Feature rule's spirit because it would force `lib/application/analytics/` to import from `features/happiness/domain/` while continuing to import `features/analytics/domain/` — bidirectional coupling.

### Q2. New feature module `features/happiness/` or extend `features/analytics/`?

**Recommendation:** **Extend `features/analytics/`.** Do NOT create `features/happiness/`.

**Reasoning (from existing project pattern):**
- Existing pattern: `features/{accounting, home, analytics, settings, family_sync, profile, dual_ledger}` — modules are scoped by **user-perceived surface area**, not by metric category. There is no `features/transactions/` despite transactions being a major domain — it lives under `accounting`.
- `Happiness` is not a screen-level surface. It surfaces inside `HomePage` (the `home` feature) and inside `AnalyticsScreen` (the `analytics` feature). A new module would be a domain bag without screens.
- The 3 dormant DAO methods are already on `AnalyticsDao`, the repo is `AnalyticsRepository`, the use cases live in `application/analytics/`. Renaming or splitting these to fit a happiness module would be a churn-heavy refactor with no benefit.
- Counter-evidence consulted: there is no `features/voice/` either even though voice has its own `application/voice/` directory (verified `STRUCTURE.md` line 201) — voice surfaces inside `accounting`. Same logic applies: happiness surfaces inside `home` + `analytics`.

**Where the metric *concept* lives in code:**
- Models + repo signature: `features/analytics/domain/`
- Computation: `application/analytics/`
- UI in HomePage: `features/home/presentation/`
- UI in Analytics: `features/analytics/presentation/`

### Q3. One use case (`GetHappinessReportUseCase`) or split per metric / per audience?

**Recommendation:** Three use cases, split by **audience boundary**, not by metric:

| Use Case | Returns | Used By |
|----------|---------|---------|
| `GetHappinessReportUseCase` | `HappinessReport` (4 personal metrics) | HomePage SoulFullnessCard + Analytics summary |
| `GetBestJoyMomentUseCase` | `BestJoyMoment?` (single tx) | Embedded in `HappinessReport` and standalone for re-use |
| `GetFamilyHappinessUseCase` | `FamilyHappiness` (2 cooperative metrics) | HomePage only (group mode), Analytics if extended later |

**Reasoning:**
- **Personal vs Family is a real boundary.** Personal metrics scope to `bookId`. Family metrics scope to `groupId` and aggregate across multiple books (the current book + shadow books from other family members). Different inputs → different use cases.
- **`BestJoyMoment` is a separate use case** because (a) it's the only one that returns a single transaction (others return aggregates), (b) it has a different DAO query shape (argmax not avg/sum), and (c) the story card may be re-used standalone in future screens (e.g., a "this month's joy highlight" notification).
- **Don't split the 4 personal metrics into 4 use cases** — they share the same DAO calls. One round trip, one Freezed model, one provider. Splitting them would force 4 parallel DAO calls per home screen render.

**Counter-pattern (rejected):** "One use case per metric." Would require 4–6 separate Riverpod providers on every home rebuild. Existing `GetMonthlyReportUseCase` has 8+ derived fields in `MonthlyReport` and is shipped as one — same logic applies.

### Q4. Where does Best Joy per ¥ belong — new DAO query or in-memory from existing satisfaction data?

**Recommendation:** **New DAO query.** Add `getBestJoyMoment` to `AnalyticsDao`.

**Reasoning:**
- The existing `getSatisfactionDistribution` and `getDailySatisfactionTrend` aggregate over groups (`GROUP BY soul_satisfaction`, `GROUP BY day`) — they discard transaction-level identity. You **cannot** recover the single best transaction's `id`, `categoryId`, `merchant`, `note` from these aggregates.
- The required argmax query is `SELECT * FROM transactions WHERE ledger_type='soul' AND type='expense' AND is_deleted=0 AND timestamp BETWEEN ? AND ? AND amount > 0 ORDER BY (CAST(soul_satisfaction AS REAL) / amount) DESC LIMIT 1`. Trivial in SQL, expensive in-memory (would require pulling every soul transaction back through the encryption layer).
- DAO-level filter respects the soul-only constraint without leaking the rule to the use case.
- Pulling all transactions into memory would also defeat the v1.0 performance principle in `analytics_dao.dart` line 86: "Uses database-level SUM/GROUP BY for performance (<2s target)."

**Encryption note (HIGH confidence):** The `note` column is field-encrypted (ChaCha20-Poly1305 via `FieldEncryptionService`, applied transparently in `TransactionRepositoryImpl`). The argmax DAO query should NOT return `note` — only return id, amount, categoryId, satisfaction, timestamp, merchant. If the UI needs `note` decrypted (e.g., to show "今天的午餐"), call the existing `TransactionRepository.findById(id)` from the use case after the argmax to get a fully-decrypted `Transaction` model. This avoids decrypt churn for the 99% case where `note` is empty.

**Recommended DAO signature:**
```dart
// lib/data/daos/analytics_dao.dart
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async { ... }

class BestJoyMomentRow {
  final String transactionId;
  final int amount;
  final int satisfaction;
  final String categoryId;
  final DateTime timestamp;
  // Note: no 'note' field — fetch via TransactionRepository if needed.
}
```

### Q5. Provider organization — extend `state_analytics.dart` or new `state_happiness.dart`?

**Recommendation:** **New `state_happiness.dart` in `features/analytics/presentation/providers/`.** Do not extend `state_analytics.dart`.

**Reasoning:**
- `state_analytics.dart` is currently 60 lines (verified) with 4 providers. Adding 4 more would push it over the cohesion line and toward the 200–400-line target ceiling in the project's coding-style rule.
- File-per-aggregate matches the rest of the analytics feature: `monthly_report.dart` model + `expense_trend.dart` model + `budget_progress.dart` model are all separate files, so providers per aggregate is natural.
- Home + Analytics both import from this single file (Home already imports `state_analytics.dart` per `home_screen.dart` line 12). Single source of truth.
- Naming convention is already `state_<aggregate>.dart` (verified `STRUCTURE.md` line 161; existing files: `state_home.dart`, `state_shadow_books.dart`, `state_today_transactions.dart`, `state_analytics.dart`, `state_active_group.dart`).

**File contents (proposed):**
```dart
// lib/features/analytics/presentation/providers/state_happiness.dart
@riverpod
Future<HappinessReport> happinessReport(Ref, {bookId, year, month}) => ...;

@riverpod
Future<BestJoyMoment?> bestJoyMoment(Ref, {bookId, year, month}) => ...;

@riverpod
Future<FamilyHappiness?> familyHappiness(Ref, {year, month}) => ...;

@riverpod
Future<List<DailyJoyPoint>> joyDensityTrend(Ref, {bookId, year, month}) => ...;
```

**Use case providers** stay in `lib/application/analytics/repository_providers.dart` (existing pattern: use case providers co-locate with the use case definition; verified `lib/application/analytics/repository_providers.dart`).

### Q6. ARB rename pass blast radius

**Verified consumer map (from `grep -rn` over `lib/`):**

| ARB key | Used in `lib/` | Used in `test/` |
|---------|----------------|-----------------|
| `survivalLedger` | `home_screen.dart:270`, `ledger_ratio_chart.dart:94` | `home_screen_test.dart:389,426` |
| `soulLedger` | `home_screen.dart:285`, `ledger_ratio_chart.dart:100` | `home_screen_test.dart:390,427` |
| `homeSoulFullness` | `soul_fullness_card.dart:60` | `soul_fullness_card_test.dart:48,56,58` |
| `homeHappinessROI` | `soul_fullness_card.dart:133` | (none) |
| `homeRecentSoulExpense` | `soul_fullness_card.dart:156` | (none) |
| `satisfactionLevel` | `soul_fullness_card.dart:98`, `transaction_confirm_screen.dart:662` | (none) |

**Total source touch: 7 production files + 2 test files.**

**Files needing edit (concrete list):**
1. `lib/l10n/app_ja.arb` — rename 4 keys' values
2. `lib/l10n/app_zh.arb` — rename 4 keys' values
3. `lib/l10n/app_en.arb` — rename 4 keys' values
4. `lib/features/home/presentation/screens/home_screen.dart` — 2 ARB call sites
5. `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart` — 2 ARB call sites
6. `lib/features/home/presentation/widgets/soul_fullness_card.dart` — 3 ARB call sites (will be substantially rebuilt regardless)
7. `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — 1 site (`satisfactionLevel`; **note: the project description says to rename only 4 specific keys; `satisfactionLevel` is not in that list — leave it alone**)
8. `test/features/home/presentation/screens/home_screen_test.dart` — 4 ARB references (re-verify after rename)
9. `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` — 3 ARB references

**Important nuance — ARB key names vs values:**
The milestone description says "ARB-only renaming." Read carefully:
- The **values** (Chinese / Japanese / English text) change in all 3 ARB files.
- The **keys** (`soulLedger`, `survivalLedger`, `homeHappinessROI`, `homeSoulFullness`) — should they also rename?

**Recommendation:** **Keep ARB keys unchanged; only change values.** Reasons:
- Keys are referenced from 7 source files. Renaming keys forces broader code edits without semantic benefit.
- ARB key parity is locked across `ja/zh/en` (per CLAUDE.md "i18n Rules"). Renaming keys requires updating all 3 files atomically anyway.
- Future translation-platform exports use keys as identifiers. Stability matters.
- `homeHappinessROI` will display "幸福密度 / ハピネス密度 / Joy / ¥" — the key name becomes slightly misleading (says "ROI", value says "density"), but this is technical debt outside v1.1's scope. v1.2+ can do a deliberate key-rename pass with proper grep-and-replace.

**If you DO decide to rename keys** (not recommended for v1.1): use the global codebase-rename tool, NOT manual edits — `home_screen.dart` line 270 is hand-editable, but the 3 generated `app_localizations_*.dart` files (~3500 lines each, lib/generated/) are regenerated from ARB by `flutter gen-l10n` and any drift will cause runtime crashes.

### Q7. Inline-helper migration — `_computeSatisfaction` and `_computeHappinessROI`

**Verified current state:** Both helpers live in `home_screen.dart` lines 345–367. Both are short (15 and 6 lines respectively). Neither is shared.

**Recommendation:** **Move both into `GetHappinessReportUseCase`.** Delete from `home_screen.dart`.

**Reasoning:**
1. **They are wrong as currently implemented.** `_computeHappinessROI` returns `report.soulTotal / report.totalExpenses` (line 364–366), which is **soul's share of total expenses**, NOT a joy-per-yen ratio. The PROJECT.md flags this explicitly: *"replace `Happiness ROI` (misleading: was budget-share, not joy density)"*. Keeping it in the screen makes the bug invisible to use case tests.
2. **They use the wrong data window.** `_computeSatisfaction` reads `todayTransactionsProvider` (today's tx), not month-to-date. v1.1 specifies "本月累计" (month-to-date) per PROJECT.md "时间窗：本月累计". The screen-level helper has no business owning a time-window decision.
3. **Test coverage is the real benefit, not LOC.** The current `_compute*` methods are private — they cannot be unit-tested. Moving them into a use case puts them under the existing 70%+ coverage requirement (`coverde --deferred` mechanism per CLAUDE.md "Active CI guardrails").
4. **Riverpod-friendly.** Once inside the use case, the result becomes part of `HappinessReport` and is trivially memoized via `happinessReportProvider`.

**Migration steps:**
1. Delete `_computeSatisfaction` (line 345) — replaced by `HappinessReport.avgSatisfaction` from `getSoulSatisfactionOverview`.
2. Delete `_computeHappinessROI` (line 362) — replaced by `HappinessReport.joyPerYen` (correct formula: Σ satisfaction × count / Σ amount). The misleading `soulTotal/totalExpenses` ratio is removed entirely.
3. Update `home_screen.dart` line 134–135 to read from `HappinessReport` directly:
   ```dart
   reportAsync.when(
     data: (report) => SoulFullnessCard(report: report, ...),
     ...
   )
   ```

### Q8. Build order & dependency chain

**Recommended phase order** (each step buildable + testable independently; respects layer dependencies in `Presentation → Application → Domain ← Data ← Infrastructure`):

```
Phase A (Domain — establish models & contracts)
  A1. lib/features/analytics/domain/models/analytics_aggregate.dart
        + add SatisfactionOverview, SatisfactionDistribution, DailySatisfaction, BestJoyMomentRow domain types
  A2. lib/features/analytics/domain/models/happiness_report.dart  (Freezed)
  A3. lib/features/analytics/domain/models/best_joy_moment.dart   (Freezed)
  A4. lib/features/analytics/domain/models/family_happiness.dart  (Freezed)
  A5. lib/features/analytics/domain/repositories/analytics_repository.dart
        + 4 new method signatures
  --- run build_runner; verify import_guard (Domain has zero outer deps) ---

Phase B (Data — DAO + Repository)
  B1. lib/data/daos/analytics_dao.dart
        + getBestJoyMoment() method only (3 others already exist)
  B2. lib/data/repositories/analytics_repository_impl.dart
        + 4 method impls (DAO result → domain mapping)
  --- write DAO tests + repo tests; run flutter test ---

Phase C (Application — Use Cases)
  C1. lib/application/analytics/get_happiness_report_use_case.dart
  C2. lib/application/analytics/get_best_joy_moment_use_case.dart
  C3. lib/application/analytics/get_family_happiness_use_case.dart
  C4. lib/application/analytics/repository_providers.dart
        + 3 new @riverpod use case providers
  --- run build_runner; write use-case tests; verify joyPerYen formula ---

Phase D (Presentation Providers)
  D1. lib/features/analytics/presentation/providers/state_happiness.dart
        + 4 @riverpod async providers
  --- run build_runner ---

Phase E (Widgets — Home)
  E1. lib/features/home/presentation/widgets/best_joy_moment_card.dart        (NEW — pure widget)
  E2. lib/features/home/presentation/widgets/family_highlights_card.dart      (NEW — pure widget)
  E3. lib/features/home/presentation/widgets/soul_fullness_card.dart           (REBUILT — interface change)
  --- write widget tests for each in isolation ---

Phase F (Widgets — Analytics)
  F1. lib/features/analytics/presentation/widgets/satisfaction_histogram.dart  (NEW)
  F2. lib/features/analytics/presentation/widgets/joy_density_trend_chart.dart (NEW)
  F3. lib/features/analytics/presentation/widgets/joy_ledger_statistics_section.dart (NEW)
  --- write widget tests ---

Phase G (Screens — Wire Up)
  G1. lib/features/home/presentation/screens/home_screen.dart
        - Delete _computeSatisfaction, _computeHappinessROI
        - Wire happinessReportProvider + familyHappinessProvider (group mode)
        - Pass HappinessReport to rebuilt SoulFullnessCard
  G2. lib/features/analytics/presentation/screens/analytics_screen.dart
        - Insert JoyLedgerStatisticsSection between LedgerRatioChart and BudgetProgressList
  --- update home_screen_test.dart, soul_fullness_card_test.dart ---

Phase H (i18n — ARB Rename Pass)
  H1. lib/l10n/app_ja.arb     (4 value renames + ~12 new keys for new tiles)
  H2. lib/l10n/app_zh.arb     (same)
  H3. lib/l10n/app_en.arb     (same)
  H4. flutter gen-l10n        (regenerates lib/generated/app_localizations*.dart)
  --- ARB key parity test (existing CI guardrail) must pass ---

Phase I (Verification & QA)
  I1. flutter analyze (must be 0 issues)
  I2. dart run custom_lint (must be 0 errors — import_guard, riverpod_lint)
  I3. flutter test --coverage (per-file ≥70% on touched files)
  I4. build_runner clean-diff CI guardrail
  I5. Manual smoke test: HomePage solo mode, HomePage group mode, AnalyticsScreen
```

**Why this order:**
- **A → B → C** is the canonical Clean Architecture build direction (Domain → Data → Application). Reversing produces compile errors because outer layers depend on inner. Verified in `STRUCTURE.md` "Where to Put New Code" line 203.
- **D before E/F** because widgets read from providers — providers must compile first.
- **E/F before G** because screens compose widgets — widgets must compile first.
- **H last** because ARB rename is value-only and decoupled from logic. Doing it earlier risks merge churn if widget text changes during dev. Doing it last lets all visible text get its final form in one pass.
- **I after H** because the ARB-key-parity test in CI gates merges (per CLAUDE.md / v1.0 guardrails).

**Critical dependency that drives the order:**
`build_runner` regenerates `*.g.dart` for Freezed models AND for `@riverpod` providers. Skipping it between phases produces stale compilation. Run after each of A, B, C, D before moving on.

---

## Anti-Patterns (specific to v1.1)

### Anti-Pattern 1: Adding `application/` or `data/daos/` Inside `features/happiness/`

**What people do:** Create `features/happiness/application/get_happiness_report_use_case.dart` because "happiness is its own concern."
**Why it's wrong:** Violates the Thin Feature rule (CLAUDE.md "Thin Feature Rule" line 32; structurally enforced by `import_guard` per `.planning/PROJECT.md` line 75). CI will reject the PR.
**Do this instead:** Use cases go in `lib/application/analytics/`. Period.

### Anti-Pattern 2: Reading `Transaction` Model Directly in HomePage to Compute Metrics

**What people do:** Subscribe to `todayTransactionsProvider` (or equivalent) in `home_screen.dart` and compute averages inline (this is exactly what `_computeSatisfaction` does today, lines 345–358).
**Why it's wrong:** (a) Pulls every transaction through the field-decryption layer for `note` even though metrics don't need notes — wasted CPU; (b) Cannot be unit-tested (private method on widget); (c) Duplicates logic if Analytics screen also wants the metric; (d) Wrong time-window (today vs. month).
**Do this instead:** All metric computation lives in `application/analytics/`. UI consumes `HappinessReport` Freezed model only.

### Anti-Pattern 3: Bypassing the Repository for the Argmax Query

**What people do:** Add `getBestJoyMoment` directly to `TransactionRepository` because "it returns a Transaction."
**Why it's wrong:** `TransactionRepository` is for individual-transaction CRUD. The argmax is an analytics aggregate (even though it returns a single record). Mixing them couples analytics to the transactions encryption pipeline (`note` decryption on every read — see `lib/data/repositories/transaction_repository_impl.dart`).
**Do this instead:** DAO returns `BestJoyMomentRow` (no `note`). If UI needs the full transaction (with decrypted `note`), call `TransactionRepository.findById(rowId)` in the use case as a second step. Best-case: zero extra decryption (no `note`); worst-case: one decryption.

### Anti-Pattern 4: Renaming ARB Keys Mid-Milestone

**What people do:** "Let's rename `homeHappinessROI` to `homeJoyDensity` while we're at it."
**Why it's wrong:** Forces simultaneous edit to 3 ARB files + 1 source file + at minimum the `lib/generated/app_localizations*.dart` regeneration + ARB-key-parity CI gate. Any drift breaks the build. Out-of-scope drift risk.
**Do this instead:** Change ARB **values** in v1.1; defer **key** renames to v1.2+ as a focused commit.

### Anti-Pattern 5: Conditionally Subscribing Family Provider Inside Widget

**What people do:** `if (isGroupMode) ref.watch(familyHappinessProvider)` inside a widget's `build()`.
**Why it's wrong:** Riverpod tracks subscription identity per build. Conditional `ref.watch` works but produces fragile rebuild graphs and breaks `keepAlive` reasoning.
**Do this instead:** Always subscribe at the screen level; the provider itself short-circuits when there's no active group:
```dart
@riverpod
Future<FamilyHappiness?> familyHappiness(Ref ref, {required int year, required int month}) async {
  final groupId = ref.watch(activeGroupIdProvider);
  if (groupId == null) return null;
  return ref.watch(getFamilyHappinessUseCaseProvider).execute(groupId: groupId, year: year, month: month);
}
```

---

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| SQLCipher (existing) | Drift `customSelect` in DAO | New `getBestJoyMoment` query — parameterized, soul-only, expense-only, not-deleted. Verify against schema v15 (current). |
| Field encryption (existing) | Transparent in `TransactionRepositoryImpl.findById` | `BestJoyMomentRow` deliberately omits `note` to avoid unnecessary decryption. |
| flutter_localizations (existing) | ARB files + `flutter gen-l10n` | Re-run after ARB value edits. Parity gate exists in CI. |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Home ↔ Analytics presentation | Direct provider import (Home imports `state_happiness.dart` from `analytics/presentation/providers/`) | Already-established pattern (Home imports `state_analytics.dart`). NOT a layer violation — both are presentation. |
| Application → Data | Through `AnalyticsRepository` interface | New methods land on the interface; impl adapts DAO. |
| Application → Infrastructure | None added | No crypto/sync touches in v1.1. |
| HomeScreen ↔ family_sync | Existing `isGroupModeProvider` from `state_active_group` | Reused — no new coupling. v1.1 adds `activeGroupIdProvider` reads inside `familyHappinessProvider`. |
| Family happiness ↔ shadow books | Inside `GetFamilyHappinessUseCase`, query across all books in group | **Open question for roadmap:** how to enumerate group's book list — likely via existing `shadowBooksProvider` or a new use case. Flag for Phase A design. |

### Cross-Cutting Concerns (v1.1 deltas)

- **Logging:** Use `dev.log(..., name: 'Analytics')` — existing channel.
- **Error handling:** Use cases return `Result<HappinessReport>` per `lib/shared/utils/result.dart` envelope (existing convention).
  - ⚠️ **Discrepancy noted:** Existing `analytics/` use cases throw via Drift exceptions → caught at `AsyncValue.when(error: ...)` in widgets. They don't use `Result<T>` despite the project-wide convention (verified by reading `get_monthly_report_use_case.dart` — no `Result` import). v1.1 should match the analytics module's local convention (throw + AsyncValue) rather than introducing `Result` mid-module. Document this in a Phase A note for roadmapper.
- **i18n:** All metric labels via `S.of(context)`. New ARB keys needed (~12 estimated): `bestJoyMomentTitle`, `bestJoyMomentEmptyState`, `joyPerYenLabel`, `joyHighlightsLabel` ("小確幸"), `familyHighlightsTitle`, `familyFavoriteCategoryTitle`, `joyDensityTrendTitle`, `satisfactionHistogramTitle`, etc. Final list emerges during widget design (Phase E/F).
- **Encryption:** Argmax query reads only non-encrypted columns. Acceptable. Story card UI displays category icon + amount + satisfaction emoji — none of which require `note` decryption.

---

## Confidence Assessment

| Area | Confidence | Basis |
|------|------------|-------|
| Layer placement of new components | HIGH | Directly grounded in CLAUDE.md "Placement Decision Rule" + STRUCTURE.md "Where to Put New Code" + verified existing analogues (`analytics/`, `accounting/`). |
| Use case structure | HIGH | Mirrors `GetMonthlyReportUseCase` exactly (read in full). |
| DAO additions | HIGH | Verified `analytics_dao.dart` — 3 of 4 needed methods already exist; only `getBestJoyMoment` is genuinely new. |
| ARB blast radius | HIGH | `grep -rn` over `lib/` and `test/` produced complete consumer map. |
| Inline-helper migration | HIGH | Read both helpers; verified bug claim from PROJECT.md ("misleading: was budget-share"). |
| Build order | HIGH | Standard Clean Architecture order; matches existing CI gates. |
| Family-mode book enumeration | MEDIUM | `shadowBooksProvider` exists (verified in `home_screen.dart` line 18) but the exact wiring for cross-book aggregation needs roadmapper-level design. |
| Result<T> vs throw decision | MEDIUM | Discrepancy between project-wide convention and existing analytics module convention surfaced during research. Roadmapper must pick one for v1.1. |

---

## Sources

- `.planning/PROJECT.md` (read in full — milestone scope, locks, out-of-scope list)
- `.planning/codebase/ARCHITECTURE.md` (read in full — v1.0 baseline architecture)
- `.planning/codebase/STRUCTURE.md` (read in full — file-tree conventions, naming, decision tree)
- `CLAUDE.md` (project rules — Thin Feature, Placement Decision Rule, common pitfalls)
- `lib/data/daos/analytics_dao.dart` (read in full — 3 dormant methods verified at lines 230–327)
- `lib/features/home/presentation/widgets/soul_fullness_card.dart` (read in full — current 2-tile layout)
- `lib/features/home/presentation/screens/home_screen.dart` (lines 1–160 + 320–367 — `_computeSatisfaction` and `_computeHappinessROI` helpers)
- `lib/application/analytics/get_monthly_report_use_case.dart` (read in full — use case template)
- `lib/features/analytics/presentation/providers/state_analytics.dart` (read in full — provider template)
- `lib/features/analytics/presentation/screens/analytics_screen.dart` (read in full — section composition pattern)
- `lib/features/analytics/domain/repositories/analytics_repository.dart` (read in full — interface to extend)
- `lib/features/analytics/domain/models/analytics_aggregate.dart` (read in full — domain types pattern)
- `lib/data/repositories/analytics_repository_impl.dart` (lines 1–80 — DAO→domain mapping pattern)
- `lib/application/analytics/repository_providers.dart` (read in full — use case provider wiring)
- `lib/l10n/app_{en,ja,zh}.arb` (greppable inventory of 6 ARB keys)
- Live `grep -rn` over `lib/` and `test/` for ARB consumers, helper methods, group-mode wiring, soulSatisfaction usage

---

*Architecture research for: v1.1 Happiness Metric & Display milestone*
*Researched: 2026-05-01*
