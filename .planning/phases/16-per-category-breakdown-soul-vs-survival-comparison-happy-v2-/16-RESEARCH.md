# Phase 16: Per-Category Breakdown + Soul-vs-Survival Comparison (HAPPY-V2-01 + STATSUI-V2-01) - Research

**Researched:** 2026-05-20
**Domain:** Flutter analytics surface extension (Clean Architecture / Variant ε / Riverpod 3 / Drift+SQLCipher)
**Confidence:** HIGH (all major findings codebase-verified)

## Summary

Phase 16 adds two read-only descriptive surfaces to AnalyticsScreen Variant ε: (1) `PerCategoryBreakdownCard` — a soul-ledger per-category satisfaction list with min-N=3 filter, top-5 default, "Other" fold row and "show all" expansion; (2) `SoulVsSurvivalCard` — an **engagement-axis** (count + spend) snapshot of both ledgers, with `avg satisfaction` shown only on the Soul column (asymmetric by design because survival rows have no user-set satisfaction picker). Both surfaces follow Phase 15's `selectedTimeWindowProvider` `(startDate, endDate)` contract, live in the existing Distribution section group, and inherit the Variant ε card chrome from `family_insight_card.dart` / `category_spend_donut_chart.dart`.

The codebase already provides 95% of the infrastructure: `getSharedJoyCategoryInsight` is the structural twin of the new per-category DAO (drop `LIMIT 1`); `getLedgerTotals` + `getSoulSatisfactionOverview` are the existing window-aware DAO methods the Soul-vs-Survival surface needs; `MetricResult<T>` is the agreed Empty/Value envelope; `TimeWindowValidation.assertValid` is the existing guard for `(startDate, endDate)`; `_soulExpenseFilter` is the canonical predicate. The principal load-bearing risk is upholding the engagement-axis re-frame (no `AVG(soul_satisfaction)` over survival rows anywhere) and not invalidating HomeHero in `_refresh()`.

**Primary recommendation:** Add ONE new use case per surface, ONE family-aggregate variant per surface, and 4 corresponding window-keyed `@riverpod` providers in a NEW file `state_ledger_snapshot.dart` (keeps `state_happiness.dart` Joy-focused). Reuse `getSharedJoyCategoryInsight`'s exact tie-break ordering for the new per-category DAO. Use Dart-side `HAVING COUNT >= 3` filtering + parallel low-N rollup count via a single query that returns all categories (cleaner than two queries; v1.2 volumes make the cost negligible).

## User Constraints (from CONTEXT.md)

### Locked Decisions

Phase 16 CONTEXT.md `<decisions>` block — verbatim summary:

**Soul-vs-Survival Comparison Semantics (Area 1)**
- **D-01:** Re-frame Soul-vs-Survival as an **engagement axis**, NOT a satisfaction axis. ROADMAP Phase 16 SC-3 example wording is overridden.
- **D-02:** Shared metrics for the comparison surface are `entry count + total spend`. No `avg/tx`, no spend percentage.
- **D-03:** Soul column carries an additional `avg satisfaction` row (single-sided by design).
- **D-04:** Survival ledger never displays a "satisfaction-derived" number in this surface.
- **D-05:** Empty state — if EITHER ledger has 0 entries within the active window, the entire Soul-vs-Survival card renders Empty.

**Per-Category Breakdown Card (Area 2)**
- **D-06:** Card form is a vertical ranked list (one row per category) — no mini-bars, no donut, no table.
- **D-07:** Sort axis is `avg satisfaction DESC, count DESC, category_id ASC` — identical to `getSharedJoyCategoryInsight`.
- **D-08:** <3 entries categories are grouped into a single "Other" fold row (aggregate count only).
- **D-09:** Default view shows top 5; "expand all" affordance reveals ranked 6+.
- **D-10:** "Other" fold-row aggregate metrics are **entry count only** — NOT an averaged avg satisfaction.

**Soul-vs-Survival Visual Frame (Area 3)**
- **D-11:** Side-by-side two-column mini-card. Left = Soul (sage green `#47B88A`); right = Survival (blue `#5A9CC8`).
- **D-12:** Section header language frame is "Ledger · This window" / "本期账本描述" / "今期の家計簿". ARB key recommendation: `analyticsCardTitleLedgerThisWindow`. No "comparison"/"vs"/"versus" framing.
- **D-13:** Both new cards live in the AnalyticsScreen Distribution section group. Insertion order: `_CategoryDonutCard` → `_SoulVsSurvivalCard` → `_SatisfactionHistogramOrFallback` → `_PerCategoryBreakdownCard`.
- **D-14:** Anti-toxicity forbidden-substring list (en/zh/ja) — minimum coverage locked; planner expands.
- **D-15:** ROADMAP Phase 16 SC-3 wording correction is a plan-task deliverable.

**Group/Family Mode (Area 4)**
- **D-16:** In `isGroupMode = true`, both surfaces show You-vs-Family aggregation. Per-family-member breakdown forbidden (ADR-012 §6). `book_id IN (...)` — never `GROUP BY book_id`.
- **D-17:** Per-Category in group mode renders as **TWO STACKED CARDS** within the Distribution group ("You · Top categories" + "Family · Top categories").
- **D-18:** Soul-vs-Survival in group mode renders as a **2×2 grid** in a single card (rows = You/Family, columns = Soul|Survival).
- **D-19:** The asymmetry between Per-Category (2 stacked cards) and Soul-vs-Survival (1 card with 2×2 grid) is intentional.
- **D-20:** When `isGroupMode = true` but `shadowBooksProvider` returns 0 or 1 book, Family rows/cards fall back to Empty ("Family data not available this window").

### Claude's Discretion

From CONTEXT.md §"Planner / UI-Spec Discretion":
- Exact ARB key names beyond recommendations.
- Card padding/divider/icon details (subject to UI-SPEC.md — already approved).
- Tap behavior on per-category rows and Other fold row (recommended noop).
- Tap behavior on Soul-vs-Survival cells (noop).
- DAO query shape choice for per-category: separate query for low-N "Other" vs Dart-side filter (planner picks).
- Group-aggregate DAO shape: separate method vs `aggregate: bool` flag (recommendation: separate method).
- Use case + provider naming (follow `state_<aggregate>.dart` convention).
- Refresh wiring details (extending `_refresh()`).
- Theme support for goldens (planner verifies per current project support).

### Deferred Ideas (OUT OF SCOPE)

From CONTEXT.md `<deferred>`:
- Per-category drill-in (tap row → transaction list).
- Per-category trend over time / sparklines.
- Survival ledger satisfaction picker (contradicts ADR-014).
- Spend-share % representation in Soul-vs-Survival.
- Per-family-member breakdown of any kind (ADR-012 §6 — permanent).
- Goldens beyond default viewport widths.
- Cross-phase audit for "default-2" leak in other analytics surfaces.
- FAMILY-V2-03 Privacy Consent Gate.

## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HAPPY-V2-01 | User can view a per-category satisfaction breakdown in AnalyticsScreen — which spending categories bring the most joy (e.g., "Coffee shops: 8.2 avg / 12 entries"). | R1 (DAO shape), R3 (use case), R4 (domain model), R5 (widget layout), R10 (test strategy). Realized as `PerCategoryBreakdownCard` with min-N=3 + Other fold + top-5 default. |
| STATSUI-V2-01 | User can view a Soul-vs-Survival happiness comparison surface with anti-toxicity framing (descriptive only, no value-judgment language). | R1 (DAO reuse), R3 (use case), R4 (LedgerSnapshot model), R5 (2-column / 2×2 grid layout), R7 (anti-toxicity test). Realized as `SoulVsSurvivalCard` with **engagement-axis re-frame** per D-01..D-04. |

## Project Constraints (from CLAUDE.md)

**Mandatory directives the planner MUST honor:**

- **Thin Feature rule:** features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`. New use cases live in `lib/application/analytics/`; new widgets in `lib/features/analytics/presentation/widgets/`.
- **Layer dependency:** Domain must NOT import Data. Presentation → Application → Domain ← Data ← Infrastructure.
- **Code-gen required** after modifying `@riverpod`, `@freezed`, Drift tables, or ARB files: `flutter pub run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n`. AUDIT-10 CI guardrail blocks PRs with stale generated files.
- **Riverpod 3 conventions:**
  - `class XNotifier extends _$XNotifier` generates `xProvider` (NOT `xNotifierProvider`). Suffix `Notifier` is stripped.
  - `AsyncValue.value` (nullable) — NOT `.valueOrNull`.
  - Errors wrapped in `ProviderException` — test with `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.
  - Side-effect listeners → `ref.listen`, NOT `ref.watch`.
  - Async tests: use `waitForFirstValue<T>(container, provider)` helper in `test/helpers/test_provider_scope.dart`. NEVER `await container.read(provider.future)` on auto-dispose providers.
  - Use `ProviderContainer.test()` over `ProviderContainer() + addTearDown`.
- **i18n parity:** every UI string change goes through ARB ja/zh/en in lockstep. `flutter gen-l10n` must succeed without warnings.
- **All UI text via `S.of(context)`** — never hardcode strings.
- **All amounts via `AppTextStyles.amountLarge/Medium/Small`** (tabular figures mandatory).
- **All currency via `NumberFormatter.formatCurrency`** with locale from `currentLocaleProvider`.
- **All dates via `DateFormatter`**.
- **Repository providers:** ONE `repository_providers.dart` per feature (single source of truth). NEVER duplicate definitions.
- **Riverpod provider rules:** NEVER throw `UnimplementedError` in providers.
- **App pins to leave alone:** `intl: 0.20.2` (exact pin), `sqlcipher_flutter_libs ^0.6.x` (NEVER `sqlite3_flutter_libs`), `file_picker ^11.0.2`, `package_info_plus ^9.0.1`, `share_plus ^12.0.2` — Phase 16 does not need new deps.
- **Zero analyzer warnings before commit.** `flutter analyze` MUST be 0 issues. Don't suppress with `// ignore:`.
- **Don't modify generated files** (`.g.dart`, `.freezed.dart`, `lib/generated/app_localizations*.dart`).
- **Drift TableIndex syntax** (Pitfall #11): Phase 16 has **no schema changes**, so this is informational only.
- **Per-file test coverage ≥70%** on changed files (per REQUIREMENTS.md Cross-Phase Constraints §5).
- **Cross-phase constraints** (REQUIREMENTS.md): ADR-012 (no gamification, no cross-period delta, no per-member leaderboards), ADR-014 (soul_satisfaction default=2, scale 1..10, unipolar positive), ADR-016 §2 (single Joy expression), CI guardrails (analyze 0, custom_lint 0, import_guard 0, riverpod_lint 0, build_runner clean-diff).

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Per-category soul aggregate query (`GROUP BY category_id HAVING COUNT >= 3`) | Database / Drift DAO (`lib/data/daos/analytics_dao.dart`) | — | SQL aggregation is the right tier for set-based operations at scale; mirrors `getSharedJoyCategoryInsight` precedent. |
| Group-mode family aggregate query (`book_id IN (...)`) | Database / Drift DAO | — | Identical SQL pattern to `getSharedJoyCategoryInsight`. ADR-012 §6 compliance is structural (no `GROUP BY book_id`). |
| Ledger snapshot aggregate (`getLedgerTotals` + `getSoulSatisfactionOverview` reuse + count) | Database / Drift DAO | — | Existing DAO methods cover ~90% of the surface; only the per-ledger entry-count tally is potentially new. |
| `MetricResult<T>` Empty/Value envelope construction | Application (Use Case) | — | Use case is the layer that decides Empty semantics (D-05: either-ledger-zero → entire card Empty). |
| `TimeWindowValidation.assertValid` guard | Application (Use Case) | — | Defense-in-depth check at entry per Phase 15 contract. Repository/DAO trusts validated input. |
| Min-N=3 + "Other" fold-row aggregation | Application (Use Case) | Database (HAVING) | SQL HAVING filters main list; Dart-side rollup counts low-N entries for the Other row. (Decision in R1.) |
| Localized category name resolution | Infrastructure (`CategoryLocaleService.resolveFromId`) | — | Existing static-map service handles `cat_*` → locale-aware display name. |
| Time-window state (`selectedTimeWindowProvider`) | Presentation (Riverpod) | — | Owned by Phase 15; Phase 16 consumes via `(bookId, startDate, endDate)` family parameter. |
| `_refresh()` invalidation set | Presentation (`analytics_screen.dart`) | — | Two new providers added; HomeHero/Home tab providers MUST NOT appear (Phase 15 D-12 binding). |
| Group-mode `shadowBooksProvider` resolution | Presentation | Application | Presentation resolves shadow books to `groupBookIds: List<String>` before invoking the use case (FamilyHappiness precedent). |
| Anti-toxicity copy enforcement | Presentation (widget tests) | i18n (ARB review) | Trilingual `find.textContaining` assertions in widget tests; ARB review is a planning-time deliverable. |
| Card chrome / two-column / 2×2 grid layout | Presentation (widget) | Theme (`AppColors`, `AppTextStyles`) | Pure Flutter Material composition; reuses existing tokens per UI-SPEC.md. |

## Standard Stack

### Core (all already in `pubspec.yaml` — Phase 16 introduces ZERO new dependencies)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_riverpod` | ^3.1.0 | State management | Project standard (Riverpod 3 conventions per CLAUDE.md) [VERIFIED: pubspec.yaml line 20] |
| `riverpod_annotation` | ^4.0.0 | `@riverpod` code generation | Project standard [VERIFIED: pubspec.yaml line 21] |
| `riverpod_generator` | ^4.0.0+1 | Generator dev dep | Project standard [VERIFIED: pubspec.yaml line 83] |
| `freezed_annotation` | ^3.0.0 | Immutable data classes | Project standard [VERIFIED: pubspec.yaml line 24] |
| `drift` | ^2.25.0 | Type-safe SQL DAO | Project standard [VERIFIED: pubspec.yaml line 61] |
| `sqlcipher_flutter_libs` | ^0.6.7 | Encrypted SQLite | Project standard — never `sqlite3_flutter_libs` [VERIFIED: pubspec.yaml line 62] |
| `intl` | 0.20.2 (exact pin) | i18n formatting | Hard pin by `flutter_localizations` [VERIFIED: pubspec.yaml line 17] |
| `fl_chart` | ^1.2.0 | Chart primitives | Project standard (NOT used by Phase 16 — list/grid only) [VERIFIED: pubspec.yaml line 44] |

### Supporting (test-only, already in `pubspec.yaml`)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `mocktail` | (in dev_dependencies) | Use-case + repository mocks in unit tests | Mirrors `get_family_happiness_use_case_test.dart` pattern |
| `flutter_test` | (Flutter SDK) | Widget tests + golden tests | All Phase 16 widget tests |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Riverpod `Future` provider (auto-dispose) | `Notifier` family with manual cache | Auto-dispose suits AnalyticsScreen — IndexedStack keeps tabs alive (Phase 15 STATE.md decision); cache invalidation via `_refresh()` is the established pattern. |
| `@freezed` for the new aggregate models | Plain sealed classes (like `MetricResult`) | `@freezed` provides `copyWith` + value equality + JSON support (not needed here). The existing `SharedJoyInsight` precedent uses `@freezed` → follow precedent. |
| Two separate DAO queries (one for top-N, one for low-N count) | Single query returning all categories with min-N filter applied in Dart | Single query is one round trip and a list traversal in Dart — cleaner at v1.2 volumes (10–100 rows/window). Two queries would be `O(2 round trips)` for no benefit. Recommendation: single query with Dart-side bisection (see R1). |
| Inline two-column `Row` + `IntrinsicHeight` for Soul-vs-Survival | Side-by-side `Expanded`-wrapped columns inside a `Card` | `Expanded` doesn't equalize heights when content differs (Soul has 3 rows, Survival has 2); `IntrinsicHeight + Row` gives equal-height columns. Use `IntrinsicHeight` per Flutter idiom (see R5). |

**Installation:** none — Phase 16 uses only existing project dependencies.

**Version verification (codebase-grounded):**
- `flutter_riverpod ^3.1.0` confirmed at `pubspec.yaml:20` [VERIFIED: pubspec.yaml]
- `riverpod_annotation ^4.0.0` confirmed at `pubspec.yaml:21` [VERIFIED: pubspec.yaml]
- `freezed_annotation ^3.0.0` confirmed at `pubspec.yaml:24` [VERIFIED: pubspec.yaml]
- `intl: 0.20.2` exact pin confirmed at `pubspec.yaml:17` [VERIFIED: pubspec.yaml]
- `drift ^2.25.0` + `sqlcipher_flutter_libs ^0.6.7` confirmed [VERIFIED: pubspec.yaml lines 61-62]

## Package Legitimacy Audit

**Not applicable — Phase 16 introduces zero new external packages.** All recommended libraries are existing project dependencies already vetted at v1.0/v1.1 and present in `pubspec.yaml`. CONTEXT.md §"Registry Safety" in UI-SPEC.md also confirms this (no shadcn, no third-party registries, no remote block fetches).

## Architecture Patterns

### System Architecture Diagram

```
                  ┌────────────────────────────────────────┐
                  │ User selects time window               │
                  │ (TimeWindowChip → TimeWindowPickerSheet)│
                  └─────────────────┬──────────────────────┘
                                    │
                              setWindow(TimeWindow)
                                    │
                                    ▼
              ┌───────────────────────────────────────────┐
              │  selectedTimeWindowProvider (Phase 15)    │
              │  → derives (startDate, endDate)           │
              └─────────────────┬─────────────────────────┘
                                │ ref.watch
                                ▼
        ┌─────────────────────────────────────────────────────┐
        │ AnalyticsScreen.build()                             │
        │                                                     │
        │  Distribution section group:                        │
        │   1. CategorySpendDonutChart (existing)             │
        │   2. SoulVsSurvivalCard ← NEW                       │
        │   3. SatisfactionDistributionHistogram (existing)   │
        │   4. PerCategoryBreakdownCard ← NEW                 │
        │      (× 2 stacked instances in group mode)          │
        └────┬───────────────────────────────────┬────────────┘
             │ ref.watch                         │ ref.watch
             ▼                                   ▼
   ┌──────────────────────────┐    ┌─────────────────────────────────┐
   │ soulVsSurvivalSnapshot   │    │ perCategorySoulBreakdown        │
   │ Provider (window-keyed)  │    │ Provider (window-keyed)         │
   │                          │    │                                 │
   │ + group-aggregate variant│    │ + group-aggregate variant       │
   │   (consumes shadowBooks) │    │   (consumes shadowBooks)        │
   └──────────┬───────────────┘    └────────────┬────────────────────┘
              │ ref.watch                       │ ref.watch
              ▼                                  ▼
   ┌─────────────────────────────────────────────────────────┐
   │ Application layer (lib/application/analytics/)          │
   │                                                         │
   │  GetSoulVsSurvivalSnapshotUseCase                       │
   │  GetSoulVsSurvivalSnapshotAcrossBooksUseCase            │
   │  GetPerCategorySoulBreakdownUseCase                     │
   │  GetPerCategorySoulBreakdownAcrossBooksUseCase          │
   │                                                         │
   │  - TimeWindowValidation.assertValid(start, end)         │
   │  - Empty semantics (D-05, D-20)                         │
   │  - Min-N=3 + Other rollup (per-category use case)       │
   └─────────────────────┬───────────────────────────────────┘
                         │
                         ▼
   ┌─────────────────────────────────────────────────────────┐
   │ AnalyticsRepository (interface) + Impl                  │
   │                                                         │
   │  Extended methods:                                      │
   │    getPerCategorySoulBreakdown(bookId, start, end)      │
   │    getPerCategorySoulBreakdownAcrossBooks(bookIds, ..)  │
   │    (existing) getSoulSatisfactionOverview               │
   │    (existing) getLedgerTotals                           │
   │    (new)      getLedgerEntryCounts(bookId, start, end)  │
   │    (new)      getLedgerEntryCountsAcrossBooks(...)      │
   └─────────────────────┬───────────────────────────────────┘
                         │
                         ▼
   ┌─────────────────────────────────────────────────────────┐
   │ AnalyticsDao (lib/data/daos/analytics_dao.dart)         │
   │                                                         │
   │  - _soulExpenseFilter (existing constant)               │
   │  - _survivalExpenseFilter (NEW constant)                │
   │  - GROUP BY category_id HAVING COUNT(*) >= 3            │
   │    ORDER BY AVG(soul_satisfaction) DESC, COUNT DESC,    │
   │             category_id ASC                             │
   │  - GROUP BY ledger_type for counts + spend              │
   └─────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
lib/
├── application/
│   └── analytics/
│       ├── _time_window_validation.dart         (existing — reused)
│       ├── get_per_category_soul_breakdown_use_case.dart       (NEW)
│       ├── get_per_category_soul_breakdown_across_books_use_case.dart  (NEW)
│       ├── get_soul_vs_survival_snapshot_use_case.dart         (NEW)
│       ├── get_soul_vs_survival_snapshot_across_books_use_case.dart    (NEW)
│       ├── repository_providers.dart            (existing — app-layer DB re-export only)
│       └── ...
├── features/
│   └── analytics/
│       ├── domain/
│       │   ├── models/
│       │   │   ├── per_category_soul_breakdown.dart     (NEW @freezed)
│       │   │   ├── per_category_soul_breakdown.freezed.dart  (generated)
│       │   │   ├── ledger_snapshot.dart                  (NEW @freezed)
│       │   │   ├── ledger_snapshot.freezed.dart          (generated)
│       │   │   ├── shared_joy_insight.dart               (existing precedent)
│       │   │   └── ...
│       │   └── repositories/
│       │       └── analytics_repository.dart    (extended with new methods)
│       └── presentation/
│           ├── providers/
│           │   ├── state_happiness.dart         (existing — UNTOUCHED for Phase 16)
│           │   ├── state_ledger_snapshot.dart   (NEW — owns 4 new providers)
│           │   ├── state_ledger_snapshot.g.dart (generated)
│           │   ├── repository_providers.dart    (extended with 4 new use case providers)
│           │   └── ...
│           ├── screens/
│           │   └── analytics_screen.dart        (extended: 2 new card slots + _refresh wiring)
│           └── widgets/
│               ├── per_category_breakdown_card.dart   (NEW)
│               ├── soul_vs_survival_card.dart          (NEW)
│               └── ...
├── data/
│   ├── daos/
│   │   └── analytics_dao.dart                   (extended with new DAO methods + _survivalExpenseFilter)
│   └── repositories/
│       └── analytics_repository_impl.dart       (extended with new method wiring)
└── l10n/
    ├── app_en.arb                                (extended with ~15 new keys)
    ├── app_ja.arb                                (extended with ~15 new keys)
    └── app_zh.arb                                (extended with ~15 new keys)

test/
├── unit/
│   ├── data/daos/
│   │   └── analytics_dao_per_category_test.dart           (NEW)
│   ├── application/analytics/
│   │   ├── get_per_category_soul_breakdown_use_case_test.dart           (NEW)
│   │   ├── get_per_category_soul_breakdown_across_books_use_case_test.dart  (NEW)
│   │   ├── get_soul_vs_survival_snapshot_use_case_test.dart             (NEW)
│   │   └── get_soul_vs_survival_snapshot_across_books_use_case_test.dart    (NEW)
│   └── features/analytics/domain/models/
│       ├── per_category_soul_breakdown_test.dart  (NEW)
│       └── ledger_snapshot_test.dart              (NEW)
├── widget/
│   └── features/analytics/presentation/
│       ├── widgets/
│       │   ├── per_category_breakdown_card_test.dart      (NEW)
│       │   ├── soul_vs_survival_card_test.dart            (NEW)
│       │   └── anti_toxicity_copy_test.dart               (NEW — trilingual forbidden-substring)
│       └── screens/
│           └── analytics_screen_phase16_integration_test.dart  (NEW — refresh wiring + HomeHero isolation extension)
└── golden/
    ├── per_category_breakdown_card_golden_test.dart       (NEW)
    ├── soul_vs_survival_card_golden_test.dart             (NEW)
    └── goldens/
        ├── per_category_breakdown_card_light_ja.png       (NEW)
        ├── per_category_breakdown_card_dark_ja.png        (NEW)
        ├── per_category_breakdown_card_group_light_ja.png (NEW)
        ├── soul_vs_survival_card_light_ja.png             (NEW)
        ├── soul_vs_survival_card_dark_ja.png              (NEW)
        ├── soul_vs_survival_card_group_light_ja.png       (NEW)
        └── soul_vs_survival_card_group_dark_ja.png        (NEW)
```

### Pattern 1: window-keyed `@riverpod` Future provider (Riverpod 3)

**What:** Async family provider parameterized by `(bookId, startDate, endDate)` (and optionally currency for group-aggregate variants); reads upstream use-case provider; calls `execute()`.

**When to use:** ALL Phase 16 data providers. Mirrors `happinessReportProvider` / `satisfactionDistributionProvider` shape exactly.

**Example:**
```dart
// Source: lib/features/analytics/presentation/providers/state_happiness.dart:15-30 (verified pattern)

@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final useCase = ref.watch(getPerCategorySoulBreakdownUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
}
```

### Pattern 2: Group-mode provider with `shadowBooksProvider` resolution

**What:** Family-aggregate provider gates on `isGroupModeProvider`, then awaits `shadowBooksProvider` to resolve book IDs, then invokes the across-books use case. Falls back to `Empty()` when 0 or 1 books returned (D-20).

**When to use:** `perCategorySoulBreakdownFamilyProvider`, `soulVsSurvivalSnapshotFamilyProvider`.

**Example:**
```dart
// Source: lib/features/analytics/presentation/providers/state_happiness.dart:86-109 (verified pattern — familyHappinessProvider)

@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdownFamily(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) return const Empty();

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((s) => s.book.id).toList();
  if (groupBookIds.length < 2) return const Empty();  // D-20

  final useCase = ref.watch(getPerCategorySoulBreakdownAcrossBooksUseCaseProvider);
  return useCase.execute(
    groupBookIds: groupBookIds,
    startDate: startDate,
    endDate: endDate,
  );
}
```

### Pattern 3: Use Case at `lib/application/analytics/` with `TimeWindowValidation`

**What:** Single `execute()` method, repository-injected, calls `TimeWindowValidation.assertValid(startDate, endDate)` at entry, returns `MetricResult<T>`.

**When to use:** All four new Phase 16 use cases.

**Example:**
```dart
// Source: lib/application/analytics/get_satisfaction_distribution_use_case.dart (verified — entire file)

class GetPerCategorySoulBreakdownUseCase {
  GetPerCategorySoulBreakdownUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  static const int _minN = 3;
  static const int _defaultTopCount = 5;  // for documentation; widget controls display

  Future<MetricResult<PerCategorySoulBreakdown>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);

    final rows = await _repo.getPerCategorySoulBreakdown(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    if (rows.isEmpty) return const Empty();

    // Split: items meeting min-N vs Other fold (D-08, D-10)
    final qualifying = rows.where((r) => r.totalCount >= _minN).toList();
    final lowN = rows.where((r) => r.totalCount < _minN).toList();

    // D-07: sort by AVG DESC, COUNT DESC, categoryId ASC
    qualifying.sort((a, b) {
      final byAvg = b.avgSatisfaction.compareTo(a.avgSatisfaction);
      if (byAvg != 0) return byAvg;
      final byCount = b.totalCount.compareTo(a.totalCount);
      if (byCount != 0) return byCount;
      return a.categoryId.compareTo(b.categoryId);
    });

    final otherCount = lowN.fold<int>(0, (s, r) => s + r.totalCount);
    final otherCategoryCount = lowN.length;
    final totalCount = qualifying.fold<int>(0, (s, r) => s + r.totalCount) + otherCount;

    if (qualifying.isEmpty && otherCount == 0) return const Empty();

    final aggregate = PerCategorySoulBreakdown(
      items: qualifying,
      totalCount: totalCount,
      otherCount: otherCount,
      otherCategoryCount: otherCategoryCount,
    );
    return Value(aggregate, totalCount);
  }
}
```

### Pattern 4: DAO method — `customSelect` with parameterized `_soulExpenseFilter`

**What:** `_db.customSelect(...)` with positional placeholders, `Variable.withString/withDateTime` mapping. Composes the canonical `_soulExpenseFilter` constant via string interpolation.

**When to use:** Both new DAO methods (single-book + multi-book).

**Example:**
```dart
// Source: lib/data/daos/analytics_dao.dart:410-444 (getSharedJoyCategoryInsight — verified pattern)

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
        // NOTE: NO HAVING here — use case applies min-N filter in Dart (R1 decision)
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

### Pattern 5: Card chrome — `Card + Padding(14) + Column(start) + AppTextStyles.titleLarge title`

**What:** Inherit Variant ε card chrome from `family_insight_card.dart` (verified at lines 32-65): `Card` with `BorderRadius.circular(14)`, `EdgeInsets.all(14)`, `Column(crossAxisAlignment: start)`, `AppTextStyles.titleLarge` for title.

**When to use:** Both new cards (`PerCategoryBreakdownCard`, `SoulVsSurvivalCard`).

**Example:** see UI-SPEC.md lines 33-43 (Spacing token table — values locked) and lines 51-58 (Typography table).

### Anti-Patterns to Avoid

- **`AVG(soul_satisfaction)` over survival rows** (anywhere — DAO, use case, or UI): would default-2-dominate and read as "survival is always neutral/unhappy". D-04 forbids; planner must enforce via code review.
- **`GROUP BY book_id` in family-aggregate queries**: ADR-012 §6 forbids per-member breakdown. Use `book_id IN (?, ?, ...)` for aggregation, NEVER GROUP BY. (Mirrors `getSharedJoyCategoryInsight` precedent.)
- **`HAVING COUNT >= 3` in the per-category DAO query**: would hide low-N categories that the "Other" fold row needs to count. Apply min-N in the use case (Dart), not the DAO (R1 decision).
- **Invalidating HomeHero providers in `_refresh()`**: Phase 15 D-12 binding. HomeHero stays month-anchored; never appears in the analytics refresh set.
- **`AsyncValue.valueOrNull`**: removed in Riverpod 3. Use `.value` (nullable).
- **`class XNotifierProvider`**: generator strips `Notifier` suffix. Provider name is `xProvider`, not `xNotifierProvider`.
- **Throwing `UnimplementedError` in providers**: forbidden per project rule. Always wire to a real implementation or return Empty.
- **Hardcoded UI strings**: every label, header, empty-state copy MUST go through `S.of(context)`. ARB ja/zh/en MUST be in lockstep.
- **Mutation of objects**: use `copyWith` (project rule). `@freezed` enforces this on annotated classes.
- **Modifying `.g.dart` / `.freezed.dart` / `lib/generated/app_localizations*.dart` files by hand**: re-run code-gen / `flutter gen-l10n` instead.
- **Average-of-averages on the Other fold row**: D-10 forbids. Other shows entry count only.
- **Half-populated Soul-vs-Survival card**: D-05 forbids. If either ledger has 0 entries, render Empty (no "Survival: 0 entries" cell).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Time-window validation | Custom `start <= end` guards in each use case | `TimeWindowValidation.assertValid(start, end)` from `lib/application/analytics/_time_window_validation.dart` | Calendar-month math, leap-year handling, current-window allowlist; reused across Phase 15 use cases. |
| Empty/Value envelope | Nullable returns or `bool isEmpty` flags | `MetricResult<T>` sealed type (`Empty<T>()` / `Value<T>(data, sampleSize)`) from `lib/features/analytics/domain/models/metric_result.dart` | Pattern-match enforces exhaustive handling at every call site. Project standard for happiness metrics. |
| Localized category names | Direct ARB lookups from category IDs | `CategoryLocaleService.resolveFromId(categoryId, locale)` from `lib/infrastructure/category/category_locale_service.dart` | Handles `cat_*` → `category_*` ARB key transformation; falls back to ID for user-created categories. |
| Currency formatting | `'¥${amount.toString()}'` or `NumberFormat` direct | `NumberFormatter.formatCurrency` from `lib/infrastructure/i18n/formatters/number_formatter.dart` (with locale from `currentLocaleProvider`) | Locale-aware decimal places (JPY 0, USD/CNY/EUR 2), thousand separators, tabular-figure compatibility. |
| Date formatting | Manual `'$year/$month/$day'` interpolation | `DateFormatter` from `lib/infrastructure/i18n/formatters/date_formatter.dart` | ja `2026/02/04`, en `02/04/2026`, zh `2026年02月04日` per CLAUDE.md. |
| Anti-leaderboard tuple shape | New ad-hoc record / Map | Mirror `SharedJoyInsight` `(categoryId, avgSatisfaction, totalCount)` tuple from `lib/features/analytics/domain/models/shared_joy_insight.dart` | Established precedent + no-per-member contract enforced by type. |
| Soul vs survival ledger filter constants | Inline string predicates per query | Define `_survivalExpenseFilter` constant in `analytics_dao.dart` (parallel to existing `_soulExpenseFilter` at line 82) | Single source of truth, prevents predicate drift. |
| Card chrome | Custom containers + manual padding/radius | Wrap content in `Card` with `BorderRadius.circular(14)` + `EdgeInsets.all(14)` + `Column(crossAxisAlignment: start)` — verified from `family_insight_card.dart:34-40` | Matches Variant ε convention; goldens already aligned at 14px. |
| Two-column equal-height layout | Stacked `Expanded` with manual height matching | `IntrinsicHeight + Row(children: [Expanded(child: ...), const VerticalDivider(width: 1), Expanded(child: ...)])` | Flutter idiom; auto-equalizes column heights regardless of content count. |
| 2×2 grid for cells | `GridView.count(crossAxisCount: 2)` (overkill, intrinsic-size issues) | `Column<Row>` with `Expanded` cells | Cleaner for fixed 2×2; aligns with snap-to-content sizing. |

**Key insight:** Phase 16 is almost entirely "compose existing primitives". The 5-layer Clean Architecture infrastructure, `MetricResult`, `TimeWindowValidation`, `CategoryLocaleService`, `_soulExpenseFilter`, `getSharedJoyCategoryInsight` precedent, and Variant ε card chrome give the planner pre-built components for >90% of the work. New code is concentrated in: 2 DAO methods (mirroring 1 existing), 4 use cases (mirroring 1 existing each), 4 providers (mirroring 2 existing patterns), 2 domain models (1 new shape), 2 widgets (new layouts), ~15 ARB keys × 3 locales, and corresponding tests.

## Runtime State Inventory

**Phase 16 is greenfield extension — NO rename/refactor. This section is informational only.**

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — Phase 16 adds query surfaces only. No new tables, no new columns. Schema version stays at 16. [VERIFIED: D-discretion bullet states no schema changes] | None |
| Live service config | None — no external services touched | None |
| OS-registered state | None — pure Flutter / Drift app, no OS-level changes | None |
| Secrets/env vars | None — uses existing SQLCipher KeyManager + AppSettings via SharedPreferences | None |
| Build artifacts | After Phase 16 plan execution: `flutter gen-l10n` regenerates `lib/generated/app_localizations*.dart`; `build_runner` regenerates `.g.dart` + `.freezed.dart` for new models/providers. AUDIT-10 CI guardrail enforces clean diff. | Run `flutter pub run build_runner build --delete-conflicting-outputs` and `flutter gen-l10n` after every annotation/ARB change |

**Nothing else found.** Verified by:
- Drift schema check: `lib/data/app_database.dart` `schemaVersion` is 16 (locked since Phase 13 D-01 — no v1.2 phase bumps it).
- Migration runner check: no Drift migration referenced by Phase 16.
- AppSettings check: no new SharedPreferences keys needed for Phase 16 (everything is query-derived from existing tables).

## Common Pitfalls

### Pitfall 1: Forgetting `TimeWindowValidation.assertValid(start, end)` at use-case entry

**What goes wrong:** Use case accepts malformed `(start, end)` (e.g., start > end, span > 12 months, future end date), forwards to repository, generates an incorrect result or empty list.

**Why it happens:** UI defenses (Phase 15 TimeWindowPickerSheet validation) are layered, but use cases are the contract boundary for `(startDate, endDate)`. The Phase 15 pattern is **every** window-aware use case calls `TimeWindowValidation.assertValid` at entry as defense in depth.

**How to avoid:** First line inside `execute()` of all four new use cases:
```dart
TimeWindowValidation.assertValid(startDate, endDate);
```
[VERIFIED pattern: `lib/application/analytics/get_satisfaction_distribution_use_case.dart:18`, `lib/application/analytics/get_family_happiness_use_case.dart:28`, `lib/application/analytics/get_happiness_report_use_case.dart:35`]

**Warning signs:** A new use case test that doesn't include a "throws ArgumentError for invalid window" case.

### Pitfall 2: Accidentally invalidating HomeHero providers in `_refresh()`

**What goes wrong:** Pull-to-refresh on AnalyticsScreen triggers HomeHero to reload from a non-current-month window, breaking ADR-016 §3 ring semantics.

**Why it happens:** It's tempting to invalidate "everything happiness-related" in `_refresh()`. But `happinessReportProvider` is also consumed by HomeHero — invalidating it from AnalyticsScreen would re-trigger HomeHero's read. The current code (`analytics_screen.dart:168-213`) carefully scopes invalidation by passing the `(startDate, endDate)` window — HomeHero uses different parameters (month-anchored), so its provider instance is different.

**How to avoid:**
1. New providers added to `_refresh()` MUST be invalidated with the SAME `(startDate, endDate)` keys used by the AnalyticsScreen build context (NOT by month-anchored keys).
2. Add the existing test `home_screen_isolation_test.dart` (or extend it) to cover the new Phase 16 providers — verify that AnalyticsScreen `_refresh()` does NOT cause HomeHero rebuild.
3. The comment `// D-12: _refresh MUST NOT invalidate any home/* provider` at `analytics_screen.dart:168` is the load-bearing constraint.

**Warning signs:** Any `ref.invalidate(...)` in `_refresh()` whose family parameters don't match the AnalyticsScreen window context (i.e., looks like month-anchored rather than `(startDate, endDate)`).

### Pitfall 3: Riverpod 3 provider name resolution after `class XNotifier extends _$XNotifier`

**What goes wrong:** Tests / consumers reference `xNotifierProvider` and get a "symbol not found" or runtime "ProviderException: Bad state". The 2 → 3 migration stripped the `Notifier` suffix.

**Why it happens:** Per CLAUDE.md "Riverpod 3 conventions": `class LocaleNotifier` annotated with `@riverpod` generates `localeProvider` (NOT `localeNotifierProvider`).

**How to avoid:** Phase 16's NEW providers should NOT use `Notifier` suffix unless they need explicit state-class generation. For 4 read-only Future providers, plain `@riverpod Future<X> name(Ref ref, {...})` is correct (yields `nameProvider`). [VERIFIED: existing pattern at `state_happiness.dart:15-30, 51-63, 86-109`]

**Warning signs:** A new generated `*.g.dart` file with `*NotifierProvider` symbols when no `Notifier` class was actually needed.

### Pitfall 4: `AsyncValue.valueOrNull` no longer exists

**What goes wrong:** Compile error / test referencing `.valueOrNull` on `AsyncValue<T>` fails after Riverpod 3 migration.

**Why it happens:** Renamed to `.value` (nullable) in Riverpod 3. Old throwing `value` is gone.

**How to avoid:** Use `.value` (nullable) for "give me the loaded value or null" pattern. Existing examples: `analytics_screen.dart:51, 69` use `.value` correctly. New widgets/providers must follow same.

**Warning signs:** `find.text(state.valueOrNull?.foo ?? '')` or similar in tests/widgets.

### Pitfall 5: ProviderException wrapping inner exceptions in tests

**What goes wrong:** Test asserts `throwsA(isA<ArgumentError>())` but the actual thrown exception is `ProviderException(exception: ArgumentError(...))`. Test fails with "Expected ArgumentError but got ProviderException".

**Why it happens:** Riverpod 3 wraps provider errors. Inner exception accessible via `.exception`.

**How to avoid:** Test pattern:
```dart
expect(
  () => container.read(provider(...).future),
  throwsA(isA<ProviderException>().having(
    (e) => e.exception, 'exception', isA<ArgumentError>())),
);
```

**Warning signs:** Tests expecting bare exception types from providers without ProviderException wrapping.

### Pitfall 6: `await container.read(provider.future)` on auto-dispose providers

**What goes wrong:** Test gets `Bad state: disposed during loading` instead of the expected value/error.

**Why it happens:** Riverpod 3 disposes the orphan read before the build settles. Phase 16's new providers are all auto-dispose by default.

**How to avoid:** Use `waitForFirstValue<T>(container, provider)` helper in `test/helpers/test_provider_scope.dart` which holds a subscription via `container.listen(..., fireImmediately: true)` and Completer. [VERIFIED: CLAUDE.md Riverpod 3 conventions table]

**Warning signs:** Tests with bare `await container.read(...future)` calls failing with disposed-during-loading.

### Pitfall 7: Soul-vs-Survival "AVG over survival rows" trap

**What goes wrong:** A developer adds `AVG(soul_satisfaction)` for survival rows (because Soul has it and Survival "should match for symmetry"). Survival shows 2.0 in every cell — the default value — and the surface reads as "survival is always neutral/unhappy". Anti-toxicity reverse pattern.

**Why it happens:** `transactions.soul_satisfaction` defaults to 2 ([VERIFIED: lib/data/tables/transactions_table.dart:35]: `IntColumn get soulSatisfaction => integer().withDefault(const Constant(2))();`). The picker only renders for soul-ledger entries (ADR-014 D-10). Survival rows uniformly carry `soul_satisfaction = 2`. AVG over them = 2.0.

**How to avoid:**
- The DAO method `getSoulVsSurvivalSnapshot` MUST NOT compute `AVG(soul_satisfaction)` for survival rows.
- Use existing `getSoulSatisfactionOverview` (already `_soulExpenseFilter`-scoped) for Soul column's avg sat.
- For Survival counts/spend, use `getLedgerTotals` + a new per-ledger entry-count helper that filters `ledger_type = 'survival' AND type = 'expense' AND is_deleted = 0`.
- Soul-vs-Survival use case asserts: Survival LedgerSnapshot has no `avgSatisfaction` field (type-system gate, see R4).
- Widget asserts: `SoulVsSurvivalCard` never reads a Survival satisfaction value (type system prevents this if model is shaped per R4).

**Warning signs:** Any new SQL with `AVG(soul_satisfaction)` outside the `_soulExpenseFilter` predicate. A LedgerSnapshot with a non-null `avgSatisfaction` on the Survival side.

### Pitfall 8: ARB ja/zh/en parity drift

**What goes wrong:** Adding a new key to `app_en.arb` but forgetting `app_zh.arb` and/or `app_ja.arb`. `flutter gen-l10n` warns or fails; runtime fallback shows raw key strings.

**Why it happens:** Three files, easy to miss one. ARB files are 1973 lines each (verified) — manual diff hard to spot.

**How to avoid:**
- Add keys in groups (e.g., all per-category card keys in one block) across all three files in the same commit.
- Run `flutter gen-l10n` and verify it succeeds without warnings.
- Run `grep -c '<key>' lib/l10n/app_*.arb` to verify count = 3 for each key (or 6 if there's a `@key` metadata block).

**Warning signs:** `flutter gen-l10n` warns about missing keys; a UI surface shows the raw ARB key string at runtime.

### Pitfall 9: Anti-toxicity forbidden substring leaking into ARB

**What goes wrong:** A translator (or any well-meaning copy revision) introduces a substring like "比較" (zh/ja "compare") into a card subtitle. The widget renders it. Anti-toxicity contract silently broken.

**Why it happens:** ARB review is manual; reviewers may not match against the forbidden-substring list. There's no compile-time check.

**How to avoid:**
- The trilingual widget test in `anti_toxicity_copy_test.dart` (R7) is the structural gate.
- Test pumps each Phase 16 card in all three locales × both modes (single + group) × all states (empty + value), with synthetic data.
- For each forbidden substring (D-14 minimum list), asserts `find.textContaining(substring)` returns `findsNothing` on the rendered widget tree.

**Warning signs:** A new ARB key not covered by the anti-toxicity test fixture (e.g., test only covers card titles, not row text). Solution: test pumps the **whole card** for each state, not a curated string.

### Pitfall 10: Build runner stale generated files in CI

**What goes wrong:** AUDIT-10 CI guardrail blocks PR with "stale generated files" because `.g.dart` or `.freezed.dart` for new providers/models wasn't regenerated.

**Why it happens:** Forgot `flutter pub run build_runner build --delete-conflicting-outputs` after adding `@riverpod` or `@freezed` annotations.

**How to avoid:**
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding/modifying new `@freezed` models or `@riverpod` providers.
- Run `flutter gen-l10n` after editing ARB files.
- Commit generated files alongside source changes.
- AUDIT-10 enforces clean-diff in CI.

**Warning signs:** Generated file has older mtime than source after a build. CI failure "stale generated files".

### Pitfall 11: `riverpod_lint` violations from non-`Notifier` side effects

**What goes wrong:** `riverpod_lint` flags `ref.watch(...)` used for side-effect (e.g., showing snackbar on state change) inside a build method.

**Why it happens:** Phase 16 is read-only — should not have side effects in providers. But if a widget consumes a provider AND triggers navigation/snackbar based on state change, that belongs in `ref.listen`, NOT `ref.watch` (CLAUDE.md Riverpod 3 conventions).

**How to avoid:** Phase 16's two new cards are read-only displays. No `ref.listen` should be needed. If a future tap behavior is added (drill-in deferred), use `ref.listen`.

**Warning signs:** `riverpod_lint` error in CI; provider read used to trigger UI side effect.

## Code Examples

### Per-Category Soul Breakdown — single book

```dart
// Source: pattern verified against lib/data/daos/analytics_dao.dart:410-444 (getSharedJoyCategoryInsight)
// New method to add (no LIMIT 1, no HAVING — see R1 decision):

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

### Per-Category Soul Breakdown — across books (group mode)

```dart
// Source: pattern verified against lib/data/daos/analytics_dao.dart:410-444
// Group-mode variant — book_id IN (...) per D-16 (NEVER GROUP BY book_id):

Future<List<PerCategorySoulRow>> getPerCategorySoulBreakdownAcrossBooks({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (bookIds.isEmpty) return const [];

  final placeholders = List.filled(bookIds.length, '?').join(', ');
  final results = await _db
      .customSelect(
        'SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt '
        'FROM transactions '
        'WHERE book_id IN ($placeholders) AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ? '
        'GROUP BY category_id '
        'ORDER BY avg_sat DESC, cnt DESC, category_id ASC',
        variables: [
          ...bookIds.map(Variable.withString),
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

### Soul-vs-Survival — per-ledger entry counts (new helper) — single book

```dart
// New DAO method. Mirror getLedgerTotals (lib/data/daos/analytics_dao.dart:214-241)
// but include COUNT(*) per ledger.

Future<List<LedgerSnapshotRow>> getLedgerSnapshot({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT ledger_type, SUM(amount) as total, COUNT(*) as cnt '
        "FROM transactions "
        "WHERE book_id = ? AND is_deleted = 0 AND type = 'expense' "
        'AND timestamp >= ? AND timestamp <= ? '
        'GROUP BY ledger_type',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();

  return results.map((row) => LedgerSnapshotRow(
    ledgerType: row.read<String>('ledger_type'),
    totalAmount: row.read<int>('total'),
    entryCount: row.read<int>('cnt'),
  )).toList();
}

Future<List<LedgerSnapshotRow>> getLedgerSnapshotAcrossBooks({
  required List<String> bookIds,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  if (bookIds.isEmpty) return const [];
  final placeholders = List.filled(bookIds.length, '?').join(', ');
  // identical query shape with WHERE book_id IN (...)
  // ...
}
```

### Domain models (NEW)

```dart
// Source: pattern verified against lib/features/analytics/domain/models/shared_joy_insight.dart

// lib/features/analytics/domain/models/per_category_soul_breakdown.dart
import 'package:freezed_annotation/freezed_annotation.dart';
part 'per_category_soul_breakdown.freezed.dart';

@freezed
abstract class PerCategorySoulRow with _$PerCategorySoulRow {
  const factory PerCategorySoulRow({
    required String categoryId,
    required double avgSatisfaction,
    required int totalCount,
  }) = _PerCategorySoulRow;
}

@freezed
abstract class PerCategorySoulBreakdown with _$PerCategorySoulBreakdown {
  const factory PerCategorySoulBreakdown({
    required List<PerCategorySoulRow> items,         // qualifying ≥ min-N, sorted
    required int totalCount,                          // sum of all entry counts (incl. Other)
    required int otherCount,                          // total entries in <min-N categories
    required int otherCategoryCount,                  // number of <min-N categories folded
  }) = _PerCategorySoulBreakdown;
}

// lib/features/analytics/domain/models/ledger_snapshot.dart
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

// SURVIVAL ledger sub-record (NO satisfaction field by design — D-04)
@freezed
abstract class SurvivalLedgerSnapshot with _$SurvivalLedgerSnapshot {
  const factory SurvivalLedgerSnapshot({
    required int entryCount,
    required int totalSpend,
  }) = _SurvivalLedgerSnapshot;
}

// Type-system gate: Survival has NO avgSatisfaction field. Any attempt to add
// AVG(soul_satisfaction) on Survival side is a compile error. This is the
// structural enforcement of D-04.

@freezed
abstract class SoulVsSurvivalSnapshot with _$SoulVsSurvivalSnapshot {
  const factory SoulVsSurvivalSnapshot({
    required SoulLedgerSnapshot soul,
    required SurvivalLedgerSnapshot survival,
    // Group-mode fields — null in solo mode
    SoulLedgerSnapshot? familySoul,
    SurvivalLedgerSnapshot? familySurvival,
  }) = _SoulVsSurvivalSnapshot;
}
```

### Use Case — Soul-vs-Survival (single book)

```dart
// lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart
import '../../features/analytics/domain/models/ledger_snapshot.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '_time_window_validation.dart';

class GetSoulVsSurvivalSnapshotUseCase {
  GetSoulVsSurvivalSnapshotUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  Future<MetricResult<SoulVsSurvivalSnapshot>> execute({
    required String bookId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    TimeWindowValidation.assertValid(startDate, endDate);  // Pitfall #1

    // Parallel fetch — same pattern as get_happiness_report_use_case.dart:37-58
    final results = await Future.wait([
      _repo.getLedgerSnapshot(bookId: bookId, startDate: startDate, endDate: endDate),
      _repo.getSoulSatisfactionOverview(bookId: bookId, startDate: startDate, endDate: endDate),
    ]);

    final ledgerRows = results[0] as List<LedgerSnapshotRow>;
    final soulSatOverview = results[1] as SoulSatisfactionOverview;

    final soulRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'soul');
    final survivalRow = ledgerRows.firstWhereOrNull((r) => r.ledgerType == 'survival');

    // D-05: if EITHER ledger has 0 entries, render Empty
    if (soulRow == null || soulRow.entryCount == 0 ||
        survivalRow == null || survivalRow.entryCount == 0) {
      return const Empty();
    }

    final snapshot = SoulVsSurvivalSnapshot(
      soul: SoulLedgerSnapshot(
        entryCount: soulRow.entryCount,
        totalSpend: soulRow.totalAmount,
        avgSatisfaction: soulSatOverview.avgSatisfaction,  // ONLY from _soulExpenseFilter — never survival
      ),
      survival: SurvivalLedgerSnapshot(
        entryCount: survivalRow.entryCount,
        totalSpend: survivalRow.totalAmount,
        // NO avgSatisfaction — D-04 type-system gate
      ),
    );

    return Value(snapshot, soulRow.entryCount + survivalRow.entryCount);
  }
}
```

### Widget — `SoulVsSurvivalCard` two-column layout (single mode)

```dart
// Sketch — full implementation per UI-SPEC.md typography/color tokens

class SoulVsSurvivalCard extends ConsumerWidget {
  const SoulVsSurvivalCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;
  final bool isGroupMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(soulVsSurvivalSnapshotProvider(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    ));
    final familyAsync = isGroupMode
      ? ref.watch(soulVsSurvivalSnapshotFamilyProvider(
          startDate: startDate,
          endDate: endDate,
        ))
      : const AsyncValue.data(Empty<SoulVsSurvivalSnapshot>());

    return snapshotAsync.when(
      loading: () => const SizedBox(height: 200),
      error: (_, _) => AnalyticsCardErrorState(onRetry: () => ref.invalidate(
        soulVsSurvivalSnapshotProvider(bookId: bookId, startDate: startDate, endDate: endDate),
      )),
      data: (result) => Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                S.of(context).analyticsCardTitleLedgerThisWindow,
                style: AppTextStyles.titleLarge.copyWith(color: context.wmTextPrimary),
              ),
              const SizedBox(height: 12),
              if (result is Empty<SoulVsSurvivalSnapshot>)
                Text(S.of(context).analyticsLedgerEmpty,
                  style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary))
              else if (result is Value<SoulVsSurvivalSnapshot>)
                isGroupMode
                  ? _Grid2x2(snapshot: result.data, familyAsync: familyAsync, ...)
                  : _TwoColumn(snapshot: result.data, ...),
            ],
          ),
        ),
      ),
    );
  }
}

// _TwoColumn uses IntrinsicHeight + Row + Expanded for equal-height columns:
//
// IntrinsicHeight(
//   child: Row(
//     children: [
//       Expanded(child: _SoulCell(soul: snapshot.soul, ...)),
//       const VerticalDivider(width: 1),  // context.wmBorderDivider tint
//       Expanded(child: _SurvivalCell(survival: snapshot.survival, ...)),
//     ],
//   ),
// )
//
// _Grid2x2 is Column<Row>:
//
// Column(children: [
//   Row(children: [
//     Expanded(child: _SoulCell(label: l10n.analyticsLedgerRowYou, soul: snapshot.soul)),
//     const VerticalDivider(width: 1),
//     Expanded(child: _SurvivalCell(label: l10n.analyticsLedgerRowYou, survival: snapshot.survival)),
//   ]),
//   const Divider(height: 1),  // horizontal between You and Family rows
//   Row(children: [
//     Expanded(child: _SoulCell(label: l10n.analyticsLedgerRowFamily, soul: familySnapshot?.soul, fallback: l10n.analyticsLedgerFamilyEmpty)),
//     const VerticalDivider(width: 1),
//     Expanded(child: _SurvivalCell(label: l10n.analyticsLedgerRowFamily, survival: familySnapshot?.survival, fallback: ...)),
//   ]),
// ])
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Density (Joy/¥) as primary Joy metric | `Σ joy_contribution` (sum of `soul_satisfaction × (amount / base)^0.88`) | Phase 13 (ADR-016 ratify, 2026-05-19) | Phase 16's per-category surface NEVER uses density. It uses raw `AVG(soul_satisfaction)` per category — the underlying soul satisfaction picker value, not a density derivative. |
| Month-bound use case parameters `(year, month)` | `(startDate, endDate)` window parameters | Phase 15 | All Phase 16 use cases use `(startDate, endDate)`; `TimeWindowValidation.assertValid` is the entry guard. |
| `MonthChipPicker` in AppBar | `TimeWindowChip` + `TimeWindowPickerSheet` | Phase 15 | Phase 16 consumes `selectedTimeWindowProvider` directly — does NOT add new picker UI. |
| Riverpod 2.x `.valueOrNull` | Riverpod 3 `.value` (nullable) | Project Riverpod 3 migration (pre-v1.2) | Phase 16 must use `.value` everywhere. |
| Riverpod 2.x exceptions thrown directly | Riverpod 3 `ProviderException` wrapping | Project Riverpod 3 migration | Phase 16 tests must use `throwsA(isA<ProviderException>().having((e) => e.exception, ...))`. |
| AVG(soul_satisfaction) seen as universally meaningful | Soul-only filter (`_soulExpenseFilter`) gating all satisfaction aggregates | ADR-014 ratify + Phase 13 | Phase 16's load-bearing constraint — D-04. |

**Deprecated/outdated:**
- `joy_density_formatter.dart` — replaced by `joy_cumulative_formatter.dart` (Phase 13). Phase 16 does not use density anywhere.
- `selectedMonthProvider` — replaced by `selectedTimeWindowProvider` (Phase 15). Phase 16 uses the new provider.
- `MonthChipPicker` — replaced by `TimeWindowChip` (Phase 15).
- `valueOrNull` on `AsyncValue<T>` — replaced by `.value` (Riverpod 3).

## Validation Architecture

Per `.planning/config.json`: `workflow.nyquist_validation: true` — this section is REQUIRED.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter SDK) + `mocktail` (dev dep) [VERIFIED: pubspec.yaml + existing test structure] |
| Config file | `analysis_options.yaml` (lint rules); no separate test config — Flutter SDK conventions |
| Quick run command | `flutter test test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart -r expanded` (per-file) |
| Full suite command | `flutter test` (entire project — typical Phase 15 plans ran < 90 seconds) |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HAPPY-V2-01 | DAO returns categories with AVG/COUNT, sorted, including <min-N | unit | `flutter test test/unit/data/daos/analytics_dao_per_category_test.dart` | Wave 0 — NEW |
| HAPPY-V2-01 | Use case filters min-N=3, folds Other, sorts per D-07 | unit | `flutter test test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart` | Wave 0 — NEW |
| HAPPY-V2-01 | Use case wraps Empty when no soul entries | unit | (above test, additional test case) | Wave 0 — NEW |
| HAPPY-V2-01 | TimeWindowValidation.assertValid called at entry | unit | (above test, additional test case asserting throws) | Wave 0 — NEW |
| HAPPY-V2-01 | Across-books variant uses `book_id IN (...)` not GROUP BY book_id | unit | `flutter test test/unit/data/daos/analytics_dao_per_category_test.dart` (group-aggregate variant test) | Wave 0 — NEW |
| HAPPY-V2-01 | Widget renders top-5 by default with sort order matching D-07 | widget | `flutter test test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` | Wave 0 — NEW |
| HAPPY-V2-01 | Widget shows "Other" fold row when low-N categories present | widget | (above test, additional case) | Wave 0 — NEW |
| HAPPY-V2-01 | Widget "show all" affordance expands beyond top-5 | widget | (above test, additional case) | Wave 0 — NEW |
| HAPPY-V2-01 | Widget renders Empty state when use case returns Empty | widget | (above test, additional case) | Wave 0 — NEW |
| HAPPY-V2-01 | Group mode renders two stacked cards (You + Family) per D-17 | widget | `flutter test test/widget/features/analytics/presentation/screens/analytics_screen_phase16_integration_test.dart` | Wave 0 — NEW |
| HAPPY-V2-01 | Golden — light + dark themes, solo + group modes | golden | `flutter test test/golden/per_category_breakdown_card_golden_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | DAO returns per-ledger (count, spend) without GROUP BY book_id | unit | `flutter test test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | Use case Empty when EITHER ledger has 0 entries (D-05) | unit | `flutter test test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | Use case populates Soul.avgSatisfaction from `_soulExpenseFilter` only | unit | (above test) | Wave 0 — NEW |
| STATSUI-V2-01 | Use case Survival snapshot has NO avgSatisfaction field (compile-time gate) | unit (type) | Verified by `SurvivalLedgerSnapshot` model definition; tested by `ledger_snapshot_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | Across-books variant uses `book_id IN (...)` | unit | (per ledger test, group-aggregate case) | Wave 0 — NEW |
| STATSUI-V2-01 | Widget renders two-column layout in solo mode, 2×2 grid in group mode | widget | `flutter test test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | Widget shows Empty state for half-populated data per D-05 | widget | (above test) | Wave 0 — NEW |
| STATSUI-V2-01 | Widget shows family-empty row when `shadowBooks.length < 2` (D-20) | widget | (above test, group-mode case) | Wave 0 — NEW |
| STATSUI-V2-01 | Anti-toxicity — no forbidden substrings in any locale × any state | widget | `flutter test test/widget/features/analytics/presentation/widgets/anti_toxicity_copy_test.dart` | Wave 0 — NEW |
| STATSUI-V2-01 | Golden — light + dark themes, solo + group modes | golden | `flutter test test/golden/soul_vs_survival_card_golden_test.dart` | Wave 0 — NEW |
| CROSS | `_refresh()` invalidates new providers without touching HomeHero | widget/integration | extend existing `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` | Wave 0 — EXTEND |
| CROSS | ROADMAP SC-3 wording reflects engagement-axis re-frame | doc-task | Manual review at plan close (D-15) | Wave 0 — manual |

### Sampling Rate

- **Per task commit:** `flutter test <changed-file-test>` (use case test, DAO test, widget test for the changed widget)
- **Per wave merge:** `flutter test test/unit/application/analytics/ test/unit/data/daos/ test/widget/features/analytics/` (analytics-scoped fast subset, < 30s)
- **Phase gate:** Full `flutter test` + `flutter analyze` (0 issues) + `flutter test --coverage` (≥70% per-file on changed files per REQUIREMENTS.md §5)

### Wave 0 Gaps

- [ ] `test/unit/data/daos/analytics_dao_per_category_test.dart` — covers HAPPY-V2-01 DAO surface (single book + across books)
- [ ] `test/unit/data/daos/analytics_dao_ledger_snapshot_test.dart` — covers STATSUI-V2-01 DAO surface (single book + across books)
- [ ] `test/unit/application/analytics/get_per_category_soul_breakdown_use_case_test.dart` — covers min-N filter, Other rollup, sort order, Empty semantics, TimeWindowValidation
- [ ] `test/unit/application/analytics/get_per_category_soul_breakdown_across_books_use_case_test.dart` — group-mode variant
- [ ] `test/unit/application/analytics/get_soul_vs_survival_snapshot_use_case_test.dart` — D-05 Empty semantics, Soul.avgSatisfaction soul-only
- [ ] `test/unit/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case_test.dart` — group-mode + D-20 fallback
- [ ] `test/unit/features/analytics/domain/models/per_category_soul_breakdown_test.dart` — Freezed equality + copyWith
- [ ] `test/unit/features/analytics/domain/models/ledger_snapshot_test.dart` — SoulLedgerSnapshot + SurvivalLedgerSnapshot Freezed equality + structural compile-time gate
- [ ] `test/widget/features/analytics/presentation/widgets/per_category_breakdown_card_test.dart` — top-5 default, show-all expansion, Other fold, Empty state
- [ ] `test/widget/features/analytics/presentation/widgets/soul_vs_survival_card_test.dart` — two-column solo, 2×2 group, D-05 Empty, D-20 family-empty
- [ ] `test/widget/features/analytics/presentation/widgets/anti_toxicity_copy_test.dart` — trilingual forbidden-substring assertions across all states for both cards
- [ ] `test/golden/per_category_breakdown_card_golden_test.dart` — light + dark + group goldens
- [ ] `test/golden/soul_vs_survival_card_golden_test.dart` — light + dark + group goldens
- [ ] **Extend** `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — add Phase 16 providers to the "AnalyticsScreen `_refresh()` does NOT cause HomeHero rebuild" assertion set
- [ ] **Optional:** `test/widget/features/analytics/presentation/screens/analytics_screen_phase16_integration_test.dart` — full screen-level integration covering insertion order per D-13

*All Phase 16 tests are new — no existing test infrastructure covers these surfaces. Test helpers `createLocalizedWidget`, `happiness_test_fixtures.dart`, and `test_provider_scope.dart` (esp. `waitForFirstValue`) are reused per Phase 15 patterns.*

## Security Domain

**Phase 16 security_enforcement: enabled** (per `.planning/config.json` defaults — no explicit `false`). However, Phase 16 is a **read-only analytics surface** with no new persistence, no new external inputs, no new authentication / authorization surface, no destructive actions. Most ASVS categories are N/A.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | Phase 16 inherits app-level biometric/secure-storage (MOD-006); no new auth surface introduced |
| V3 Session Management | no | No sessions involved; analytics is local read-only |
| V4 Access Control | yes — implicit | Per ADR-012 §6 + D-16: Phase 16 surfaces NEVER expose per-family-member data even in group mode. Type-system gate (`SharedJoyInsight` precedent + new `PerCategorySoulBreakdown` + `SoulVsSurvivalSnapshot` models carry no `bookId` or member projection) is the structural enforcement. |
| V5 Input Validation | yes | `TimeWindowValidation.assertValid(startDate, endDate)` at every use-case entry; Drift parameterized queries (`Variable.withString/withDateTime`) prevent SQL injection. |
| V6 Cryptography | no | All persistence inherits MOD-006 4-layer encryption (SQLCipher etc.); Phase 16 adds no new persistence surface |
| V8 Data Protection | yes — implicit | Phase 16 reads from already-encrypted SQLCipher tables (transactions); no new logging, no new data exfiltration vector |
| V14 Configuration | no | No config changes |

### Known Threat Patterns for {Flutter + Drift analytics surface}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection through user-controlled book IDs or category IDs | Tampering | All Phase 16 queries use Drift parameterized variables (`Variable.withString/withDateTime`). `book_id IN (?, ?, ...)` uses `List.filled` placeholders, NEVER string concatenation. [VERIFIED pattern: `lib/data/daos/analytics_dao.dart:417-419`] |
| Default-2 satisfaction leak (information disclosure) | Information Disclosure (mild) | D-04 anti-toxicity contract: NEVER AVG soul_satisfaction over survival rows. Mitigations: (a) `_soulExpenseFilter` predicate scopes every soul-aggregate query; (b) `SurvivalLedgerSnapshot` model has no `avgSatisfaction` field (type-system gate); (c) widget tests assert absence of satisfaction-derived numbers on Survival surfaces. |
| Per-family-member data exposure via UI | Information Disclosure | D-16 + ADR-012 §6: Phase 16 queries NEVER `GROUP BY book_id`. Aggregate models (`PerCategorySoulBreakdown`, `SoulVsSurvivalSnapshot`) carry no per-member projection. Type-system gate via no-bookId field on aggregate models. |
| Time-window injection / range explosion (DoS) | Denial of Service | `TimeWindowValidation.assertValid` rejects spans > 12 months and future end dates. Defense in depth (UI + use case). |
| Locale-injection breakage in ARB | Tampering (mild) | All UI text via `S.of(context)` — locale parameter is a controlled enum, not user-controlled string. |

### Threat-mitigation summary for Phase 16

The principal "security" risk for Phase 16 is **product integrity** (anti-toxicity / anti-leaderboard) rather than classic security. The architecture deliberately leverages the type system as the structural enforcement:
- `SurvivalLedgerSnapshot` has NO `avgSatisfaction` field → cannot accidentally render or compute one.
- `PerCategorySoulBreakdown` is a top-level aggregate with no per-member projection → cannot accidentally surface family-member data.
- ADR-012 §6 + D-16 + existing `SharedJoyInsight` precedent are the contract; Phase 16 inherits.

## Open Questions

1. **Should the per-category use case return a sorted list, or leave sorting to the widget?**
   - What we know: D-07 mandates `AVG DESC, COUNT DESC, categoryId ASC`. The DAO returns rows in this order (via `ORDER BY`). Dart-side min-N split also needs to preserve order.
   - What's unclear: Whether the use case re-sorts after the split (defensive, but redundant) or trusts DAO ordering.
   - Recommendation: Use case re-sorts the `qualifying` list explicitly (matches `get_family_happiness_use_case.dart` defensive style). Cost is O(n log n) for n ≤ ~30 categories — negligible.

2. **Should `_PerCategoryBreakdownCard` use a stateful `_isExpanded: bool` toggle, or a separate `expandedProvider` family?**
   - What we know: D-09 says "expand all" affordance. Tap state could be local (StatefulWidget) or shared via Riverpod.
   - What's unclear: Whether expansion state should persist across navigation (Phase 15 STATE.md says IndexedStack keeps tabs alive, so a local widget state works).
   - Recommendation: Local `StatefulWidget` with `_isExpanded` field. Per-card local state. Simpler. No new provider. (Group-mode "show all" is independent per card.)

3. **Should the Soul-vs-Survival snapshot use case compute total spend separately, or reuse `getLedgerTotals`?**
   - What we know: `getLedgerTotals` already exists (`lib/data/daos/analytics_dao.dart:214-241`); returns `List<LedgerTotalResult>(ledgerType, totalAmount)` — but lacks COUNT.
   - What's unclear: Whether to add a `getLedgerSnapshot` that returns both COUNT+SUM (single query, recommended) or compose `getLedgerTotals` + a separate count helper.
   - Recommendation: Add new `getLedgerSnapshot(bookId, start, end) → List<LedgerSnapshotRow(ledgerType, totalAmount, entryCount)>` (one query, three columns). Mirrors `getLedgerTotals` pattern, adds COUNT. Keeps the use case parallel-fetch simple (1 DAO call for both ledgers + 1 DAO call for Soul avg sat = 2 parallel calls total).

4. **Group-aggregate variant: separate use case file, or `aggregate: bool` flag on existing use case?**
   - What we know: CONTEXT.md §"Planner Discretion" notes both options acceptable, recommends separate methods. `SharedJoyInsight` is fetched in `GetFamilyHappinessUseCase` alongside personal aggregates — but that's a multi-aggregate use case.
   - Recommendation: Separate `GetPerCategorySoulBreakdownAcrossBooksUseCase` + `GetSoulVsSurvivalSnapshotAcrossBooksUseCase`. (a) Mirrors `GetFamilyHappinessUseCase` for group-mode separation; (b) keeps single-book use cases simple; (c) easier to test independently; (d) wired via `state_ledger_snapshot.dart` `*FamilyProvider` providers that consume `shadowBooksProvider`.

5. **Should `PerCategoryBreakdownCard` solo-mode title differ from group-mode title?**
   - What we know: UI-SPEC.md lines 97-99 define three titles: `analyticsCardTitlePerCategorySoul` (solo), `analyticsCardTitlePerCategorySoulYou` (group/You card), `analyticsCardTitlePerCategorySoulFamily` (group/Family card).
   - What's unclear: Should solo mode share the "You" key, or use a generic "Joy · Categories"?
   - Recommendation: Use the three distinct keys per UI-SPEC. The "You / Family" framing only makes sense when both are present; solo mode uses the generic key.

## Environment Availability

Phase 16 is **code/config-only** with no external dependencies beyond the existing project toolchain. This section is therefore largely informational.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All code | ✓ (assumed — project is active) | Project standard | — |
| Dart SDK | All code | ✓ | Project standard | — |
| `flutter pub run build_runner` | `@riverpod` + `@freezed` code-gen | ✓ | Pinned via `pubspec.yaml` dev_deps | — |
| `flutter gen-l10n` | ARB-to-Dart i18n generation | ✓ (built into Flutter SDK) | Flutter standard | — |
| `flutter test` | unit + widget + golden tests | ✓ | Flutter standard | — |
| `flutter analyze` | CI guardrail | ✓ | Flutter standard | — |

**No missing dependencies, no fallbacks needed.** Phase 16 introduces zero new external tools.

## Sources

### Primary (HIGH confidence)

- **Phase 16 CONTEXT.md** (`.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/16-CONTEXT.md`) — D-01..D-20 source of truth.
- **Phase 16 UI-SPEC.md** (`.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/16-UI-SPEC.md`) — verified by gsd-ui-researcher; visual contract.
- **Phase 15 CONTEXT.md** (`.planning/phases/15-custom-time-windows-happy-v2-02/15-CONTEXT.md`) — `selectedTimeWindowProvider`, `(startDate, endDate)` contract, HomeHero D-12 binding.
- **Phase 13 CONTEXT.md** (`.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md`) — `Σ joy_contribution` backend, `MetricResult`, `getSoulRowsForJoyContribution`.
- **Phase 14 CONTEXT.md** (`.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-CONTEXT.md`) — Variant ε frame, Joy Index vocabulary.
- **REQUIREMENTS.md** — HAPPY-V2-01, STATSUI-V2-01, Cross-Phase Constraints §1-6.
- **ROADMAP.md** Phase 16 — Goal + 5 Success Criteria (SC-3 wording to be corrected per D-15).
- **STATE.md** — Project status, Phase 15 close decisions.
- **CLAUDE.md** — Thin Feature rule, Riverpod 3 conventions, intl 0.20.2 pin, common pitfalls table.

### Codebase verifications (HIGH confidence)

- `lib/data/daos/analytics_dao.dart` (445 lines) — `_soulExpenseFilter` line 82, `getLedgerTotals` line 214, `getSoulSatisfactionOverview` line 244, `getSharedJoyCategoryInsight` lines 410-444.
- `lib/features/analytics/presentation/screens/analytics_screen.dart` (587 lines) — Distribution section lines 106-121, `_refresh()` lines 160-213 with D-12 comment line 168.
- `lib/features/analytics/presentation/providers/state_happiness.dart` (121 lines) — provider patterns verified.
- `lib/features/analytics/presentation/providers/state_time_window.dart` (22 lines) — `SelectedTimeWindow` notifier.
- `lib/features/analytics/presentation/providers/repository_providers.dart` (107 lines) — use case provider wiring entry point.
- `lib/application/analytics/_time_window_validation.dart` — `TimeWindowValidation.assertValid` guard.
- `lib/application/analytics/get_family_happiness_use_case.dart` — `book_id IN (...)` group-aggregate precedent.
- `lib/application/analytics/get_satisfaction_distribution_use_case.dart` — minimal window-aware use case shape.
- `lib/features/analytics/domain/models/metric_result.dart` — `Empty<T>()` / `Value<T>(data, sampleSize)` sealed type.
- `lib/features/analytics/domain/models/shared_joy_insight.dart` — anti-leaderboard tuple precedent (Freezed).
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — abstract interface to extend.
- `lib/data/repositories/analytics_repository_impl.dart` — implementation pattern.
- `lib/features/analytics/presentation/widgets/family_insight_card.dart` — group-mode card precedent (84 lines).
- `lib/features/analytics/presentation/widgets/category_spend_donut_chart.dart` — Distribution-card neighbor (148 lines).
- `lib/features/analytics/presentation/widgets/analytics_screen_section_header.dart` — section header style.
- `lib/data/tables/transactions_table.dart` line 35 — soul_satisfaction default = 2 (THE load-bearing trap).
- `lib/core/theme/app_colors.dart` lines 36-47 — Soul `#47B88A`, Survival `#5A9CC8`, soulLight/survivalLight/olive.
- `lib/core/theme/app_theme_colors.dart` — `wmSoulTagBg`, `wmSurvivalTagBg`, `wmBorderDivider` extensions.
- `lib/core/theme/app_text_styles.dart` — `amountLarge/Medium/Small` with `FontFeature.tabularFigures()`.
- `lib/infrastructure/category/category_locale_service.dart` — `resolveFromId(categoryId, locale)`.
- `pubspec.yaml` — dependency versions.
- `lib/l10n/app_en.arb` (1973 lines) — verified no Phase 16 key collisions (no `analyticsCardTitleLedgerThisWindow`, no `analyticsPerCategory*`, no `analyticsLedger*` outside soulLedger/survivalLedger labels).
- `test/helpers/test_localizations.dart` + `test/helpers/happiness_test_fixtures.dart` + `test/helpers/test_provider_scope.dart` — fixture/helper precedents.
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero isolation test to extend.
- `test/golden/home_hero_card_golden_test.dart` — golden test pattern precedent (light/dark themes, single locale ja).

### Secondary (MEDIUM confidence)

- **ADR-012 No Gamification v1.1** — §6 per-family-member breakdown forbidden (already ratified).
- **ADR-014 Soul Satisfaction Unipolar Positive Scale** — D-10 picker-only-on-soul (already ratified; cited by CONTEXT.md).
- **ADR-016 Joy Metric Visualization Redesign** — §3 HomeHero monthly anchor, §5 100% no-event contract (already ratified).

### Tertiary (LOW confidence)

None — every finding is verified against the codebase or canonical project documents.

## Assumptions Log

> Every claim in this RESEARCH.md was either VERIFIED against the codebase or CITED from a canonical project document. The assumptions table below lists the small number of recommendations that depend on best-effort code-archaeology where the planner / discuss-phase may want to revisit.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Single-query DAO with Dart-side min-N split is cleaner than two queries at v1.2 transaction volumes (10–100 rows / window). | R1, Pattern 4 | Low — if data volume grows substantially, a HAVING-filtered query + separate low-N count query becomes the right approach. Refactor cost is small. |
| A2 | Adding new providers to a NEW file `state_ledger_snapshot.dart` (vs extending `state_happiness.dart`) is the cleaner placement. | R2 | Low — extending `state_happiness.dart` is also acceptable; choice is stylistic. Phase 13 added `monthlyJoyTargetRecommendationProvider` to `state_happiness.dart` because it was Joy-targeted. Phase 16's surfaces are ledger-snapshot / per-category — semantically distinct. |
| A3 | Local `_isExpanded: bool` widget state for "show all" expansion is sufficient (no shared Riverpod state). | Open Q #2 | Very low — IndexedStack keeps tabs alive (per Phase 15 STATE.md), so widget state survives tab switches. If the requirement changes to "persistent across app restart", a Riverpod provider would be needed. |
| A4 | `IntrinsicHeight + Row + Expanded + VerticalDivider` is the cleanest idiom for the two-column equal-height card layout. | R5, Pattern 5 | Low — Flutter idiom standard; alternatives (CustomMultiChildLayout, ConstraintsLayout) are more complex with no benefit at this scale. |
| A5 | The new `getLedgerSnapshot` DAO method (with COUNT + SUM in one query) is preferable to composing `getLedgerTotals` + a separate count helper. | Open Q #3 | Very low — single round trip is strictly faster; same query shape as existing `getLedgerTotals`. |
| A6 | Separate group-aggregate use cases (vs `aggregate: bool` flag) is preferable for testability and parallelism with `GetFamilyHappinessUseCase`. | Open Q #4 | Very low — mirrors existing architecture; the `aggregate: bool` flag pattern doesn't exist in the codebase. |
| A7 | Goldens are required for light + dark themes per ROADMAP SC-4. UI-SPEC.md §Theme Mode Coverage confirms theme support. | R8 | Very low — `home_hero_card_family_dark_ja.png` in `test/golden/goldens/` confirms project does have dark golden support. |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

(Table is intentionally non-empty because some recommendations rest on best-effort defaults that the planner may want to challenge.)

## R1. DAO Query Shape — Per-Category Breakdown

**Single-book method (`getPerCategorySoulBreakdown`):**

Query shape (mirrors `getSharedJoyCategoryInsight` at `analytics_dao.dart:410-444`, but returns all rows — no LIMIT, no HAVING):

```sql
SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt
FROM transactions
WHERE book_id = ? AND ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0
  AND timestamp >= ? AND timestamp <= ?
GROUP BY category_id
ORDER BY avg_sat DESC, cnt DESC, category_id ASC
```

Decisions:
- **WHERE clause:** reuses `_soulExpenseFilter` constant (`analytics_dao.dart:82`) via string interpolation in customSelect.
- **GROUP BY:** `category_id` — exactly mirrors `getSharedJoyCategoryInsight`.
- **HAVING:** **REMOVED** (vs `getSharedJoyCategoryInsight HAVING COUNT(*) >= 3`). Reason: the new DAO must return ALL categories — including <3 entries — so the use case can compute the Other row's `totalCount + categoryCount`. Filtering happens in Dart (R1 single-query strategy).
- **ORDER BY:** identical tie-break `avg_sat DESC, cnt DESC, category_id ASC` per D-07.
- **Returns:** `List<PerCategorySoulRow>` where `PerCategorySoulRow = (categoryId, avgSatisfaction, totalCount)`. Same shape as `SharedJoyCategoryAggregate` but in a list.

**"Other" fold-row strategy comparison:**

| Option | Round trips | Code complexity | Decision |
|--------|-------------|-----------------|----------|
| (a) Single query returns all categories + Dart filters into qualifying / low-N | 1 | use case applies `where r.totalCount >= 3` and `where r.totalCount < 3` partitions | ✅ **Recommended** — cleaner; at 10–100 categories/window, partition is O(n); use case is simpler. |
| (b) Two queries: query A `HAVING COUNT >= 3` for the main list; query B `SELECT COUNT(DISTINCT category_id), SUM(cnt) WHERE COUNT < 3` for the Other row | 2 | needs special-case query B; SQL is awkward (HAVING is per-row, can't be used for separate AVG of low-N) | Reject — no benefit at v1.2 scale; SQL gymnastics for marginal saving. |

**Group-aggregate method (`getPerCategorySoulBreakdownAcrossBooks`):**

Same query shape with `WHERE book_id IN (?, ?, ...)` placeholder expansion (mirrors `getSharedJoyCategoryInsight` lines 415-419). Constraint: NEVER `GROUP BY book_id` (ADR-012 §6 + D-16). The aggregate is across all member books treated as a single set.

```sql
SELECT category_id, AVG(soul_satisfaction) as avg_sat, COUNT(*) as cnt
FROM transactions
WHERE book_id IN (?, ?, ?) AND ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0
  AND timestamp >= ? AND timestamp <= ?
GROUP BY category_id
ORDER BY avg_sat DESC, cnt DESC, category_id ASC
```

## R2. State Layer — Provider Naming + Invalidation

**Placement decision: NEW file `state_ledger_snapshot.dart`** (vs extending `state_happiness.dart`).

Rationale:
- `state_happiness.dart` currently owns: `happinessReportProvider`, `bestJoyMomentProvider`, `monthlyJoyTargetRecommendationProvider`, `largestMonthlyExpenseProvider`, `familyHappinessProvider` (5 providers, 121 lines). Adding 4 more providers (per-category + soul-vs-survival × solo + family) would push it past 250 lines and conflate different "aggregate kinds".
- Existing `state_<aggregate>.dart` naming convention (ARCH-004 + Phase 13 D-04) supports adding a new file per aggregate.
- A new `state_ledger_snapshot.dart` aligns with the new `LedgerSnapshot` domain model and per-category breakdown semantics. Clean separation.

**Provider definitions (sketches):**

```dart
// lib/features/analytics/presentation/providers/state_ledger_snapshot.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/ledger_snapshot.dart';
import '../../domain/models/metric_result.dart';
import '../../domain/models/per_category_soul_breakdown.dart';
import '../../../family_sync/presentation/providers/state_active_group.dart';
import '../../../home/presentation/providers/state_shadow_books.dart';
import 'repository_providers.dart';

part 'state_ledger_snapshot.g.dart';

/// HAPPY-V2-01 single-book per-category soul satisfaction breakdown.
@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdown(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final useCase = ref.watch(getPerCategorySoulBreakdownUseCaseProvider);
  return useCase.execute(bookId: bookId, startDate: startDate, endDate: endDate);
}

/// HAPPY-V2-01 D-17 family-aggregate variant for group-mode "Family · Top categories" card.
@riverpod
Future<MetricResult<PerCategorySoulBreakdown>> perCategorySoulBreakdownFamily(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) return const Empty();

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((s) => s.book.id).toList();
  if (groupBookIds.length < 2) return const Empty();  // D-20 fallback

  final useCase = ref.watch(getPerCategorySoulBreakdownAcrossBooksUseCaseProvider);
  return useCase.execute(
    groupBookIds: groupBookIds,
    startDate: startDate,
    endDate: endDate,
  );
}

/// STATSUI-V2-01 single-book Soul-vs-Survival engagement snapshot.
@riverpod
Future<MetricResult<SoulVsSurvivalSnapshot>> soulVsSurvivalSnapshot(
  Ref ref, {
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final useCase = ref.watch(getSoulVsSurvivalSnapshotUseCaseProvider);
  return useCase.execute(bookId: bookId, startDate: startDate, endDate: endDate);
}

/// STATSUI-V2-01 D-18 family-aggregate variant for group-mode 2×2 grid row 2.
@riverpod
Future<MetricResult<SoulVsSurvivalSnapshot>> soulVsSurvivalSnapshotFamily(
  Ref ref, {
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final activeGroup = await ref.watch(activeGroupProvider.future);
  if (activeGroup == null) return const Empty();

  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((s) => s.book.id).toList();
  if (groupBookIds.length < 2) return const Empty();  // D-20 fallback

  final useCase = ref.watch(getSoulVsSurvivalSnapshotAcrossBooksUseCaseProvider);
  return useCase.execute(
    groupBookIds: groupBookIds,
    startDate: startDate,
    endDate: endDate,
  );
}
```

**Keying:** All four providers are families on `(bookId, startDate, endDate)` (the family-aggregate variants drop `bookId`, deriving from `shadowBooksProvider`). Mirror Phase 15 `(bookId, startDate, endDate)` shape exactly.

**`_refresh()` extension in `analytics_screen.dart`:**

```dart
// In _refresh() — ADD (insert before the if (isGroupMode) {...} block):

ref.invalidate(
  perCategorySoulBreakdownProvider(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  ),
);
ref.invalidate(
  soulVsSurvivalSnapshotProvider(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  ),
);

if (isGroupMode) {
  ref.invalidate(familyHappinessProvider(startDate: startDate, endDate: endDate));
  ref.invalidate(shadowBooksProvider);
  // ADD:
  ref.invalidate(perCategorySoulBreakdownFamilyProvider(startDate: startDate, endDate: endDate));
  ref.invalidate(soulVsSurvivalSnapshotFamilyProvider(startDate: startDate, endDate: endDate));
}
```

The D-12 binding (`// _refresh MUST NOT invalidate any home/* provider`) at line 168 stays intact. The new invalidations all consume `(startDate, endDate)` from the AnalyticsScreen window — HomeHero's `happinessReportProvider` is keyed by a different `(startDate, endDate)` pair (month-anchored), so its instance is different and is NOT invalidated.

## R3. Use Case Shape — `lib/application/analytics/`

Four new use cases:

```dart
// lib/application/analytics/get_per_category_soul_breakdown_use_case.dart
class GetPerCategorySoulBreakdownUseCase {
  // single-book; constructor-injected AnalyticsRepository
  // execute({bookId, startDate, endDate}) → Future<MetricResult<PerCategorySoulBreakdown>>
  // - TimeWindowValidation.assertValid(start, end)
  // - calls _repo.getPerCategorySoulBreakdown(bookId, start, end)
  // - partitions by COUNT >= 3 vs COUNT < 3 (D-08, D-10)
  // - sorts qualifying by D-07 order
  // - returns Empty if no rows; Value(aggregate, totalCount) otherwise
}

// lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart
class GetPerCategorySoulBreakdownAcrossBooksUseCase {
  // group-mode (D-17, D-16); same shape but takes List<String> groupBookIds instead of bookId
  // execute({groupBookIds, startDate, endDate}) → Future<MetricResult<PerCategorySoulBreakdown>>
  // - if groupBookIds.isEmpty: return Empty()
  // - TimeWindowValidation.assertValid(start, end)
  // - calls _repo.getPerCategorySoulBreakdownAcrossBooks(groupBookIds, start, end)
  // - same partition + sort + Empty/Value logic as single-book variant
}

// lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart
class GetSoulVsSurvivalSnapshotUseCase {
  // single-book engagement snapshot
  // execute({bookId, startDate, endDate}) → Future<MetricResult<SoulVsSurvivalSnapshot>>
  // - TimeWindowValidation.assertValid(start, end)
  // - parallel Future.wait:
  //   - _repo.getLedgerSnapshot(bookId, start, end)        // count + spend per ledger
  //   - _repo.getSoulSatisfactionOverview(bookId, start, end)  // avg sat (soul-only)
  // - D-05: if either ledger has 0 entries, return Empty()
  // - constructs SoulLedgerSnapshot(entryCount, totalSpend, avgSatisfaction) — avg from overview
  //   and SurvivalLedgerSnapshot(entryCount, totalSpend) — NO avg field
  // - returns Value(SoulVsSurvivalSnapshot(soul, survival), totalEntries)
}

// lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart
class GetSoulVsSurvivalSnapshotAcrossBooksUseCase {
  // group-mode (D-18, D-16)
  // execute({groupBookIds, startDate, endDate}) → Future<MetricResult<SoulVsSurvivalSnapshot>>
  // - if groupBookIds.isEmpty: return Empty()
  // - TimeWindowValidation.assertValid
  // - parallel Future.wait calling Across-Books DAO methods:
  //   - _repo.getLedgerSnapshotAcrossBooks(groupBookIds, start, end)
  //   - for avg sat: aggregate getSoulSatisfactionOverview across books (compute weighted average from per-book overviews) OR add new DAO method getSoulSatisfactionOverviewAcrossBooks
  // - same D-05 Empty fallback
}
```

**Provider wiring in `repository_providers.dart`** (extend the existing file at `lib/features/analytics/presentation/providers/repository_providers.dart`):

```dart
// ADD to repository_providers.dart (after the existing GetFamilyHappinessUseCase provider):

@riverpod
GetPerCategorySoulBreakdownUseCase getPerCategorySoulBreakdownUseCase(Ref ref) {
  return GetPerCategorySoulBreakdownUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

@riverpod
GetPerCategorySoulBreakdownAcrossBooksUseCase getPerCategorySoulBreakdownAcrossBooksUseCase(Ref ref) {
  return GetPerCategorySoulBreakdownAcrossBooksUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

@riverpod
GetSoulVsSurvivalSnapshotUseCase getSoulVsSurvivalSnapshotUseCase(Ref ref) {
  return GetSoulVsSurvivalSnapshotUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}

@riverpod
GetSoulVsSurvivalSnapshotAcrossBooksUseCase getSoulVsSurvivalSnapshotAcrossBooksUseCase(Ref ref) {
  return GetSoulVsSurvivalSnapshotAcrossBooksUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

## R4. Domain Models

See "Code Examples" section above for full Freezed definitions. Summary:

**`PerCategorySoulRow`** (`@freezed`, in `lib/features/analytics/domain/models/per_category_soul_breakdown.dart`):
- `categoryId: String`
- `avgSatisfaction: double`
- `totalCount: int`
- Same shape as `SharedJoyInsight` / `SharedJoyCategoryAggregate` (validated precedent).

**`PerCategorySoulBreakdown`** (`@freezed`, top-level aggregate, in the same file):
- `items: List<PerCategorySoulRow>` (qualifying ≥min-N, sorted per D-07)
- `totalCount: int` (sum of all entry counts incl. Other)
- `otherCount: int` (entries in <min-N categories)
- `otherCategoryCount: int` (number of <min-N categories folded)
- Wrapped in `MetricResult<PerCategorySoulBreakdown>` at use-case output.

**`SoulLedgerSnapshot`** (`@freezed`, in `lib/features/analytics/domain/models/ledger_snapshot.dart`):
- `entryCount: int`
- `totalSpend: int`
- `avgSatisfaction: double`

**`SurvivalLedgerSnapshot`** (`@freezed`, same file):
- `entryCount: int`
- `totalSpend: int`
- **NO `avgSatisfaction` field — type-system gate enforcing D-04** (Pitfall #7).

**`SoulVsSurvivalSnapshot`** (`@freezed`, top-level aggregate, same file):
- `soul: SoulLedgerSnapshot` (You scope)
- `survival: SurvivalLedgerSnapshot` (You scope)
- `familySoul: SoulLedgerSnapshot?` (group mode only)
- `familySurvival: SurvivalLedgerSnapshot?` (group mode only)
- Wrapped in `MetricResult<SoulVsSurvivalSnapshot>` at use-case output.

**Alternative shape considered:** `youFamily: { you: ..., family: ... }` Map-style nesting. Rejected because (a) `@freezed` doesn't model nested records cleanly without separate classes; (b) nullable `familySoul`/`familySurvival` is more idiomatic for "group mode optional" semantics. Adopted shape mirrors `FamilyHappiness` which carries multiple optional `MetricResult<T>` fields directly on the top model.

Code-gen impact: `build_runner build --delete-conflicting-outputs` produces `.freezed.dart` for both files. No `.g.dart` (no JSON support needed; these are transient query results).

## R5. Widget Layout — `_PerCategoryBreakdownCard` + `_SoulVsSurvivalCard`

**Card chrome match:** All Phase 16 cards use Variant ε chrome verified from `family_insight_card.dart:32-65`:
- `Card` wrapper with `shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`
- `Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [...]))`
- Title: `AppTextStyles.titleLarge`
- Body content: `AppTextStyles.bodyMedium`
- Captions / Empty: `AppTextStyles.caption` with `context.wmTextSecondary`

**`PerCategoryBreakdownCard` — default-5 + show-all affordance pattern:**

No existing Variant ε widget has this exact pattern. Recommended Flutter idiom: **`StatefulWidget` with `_isExpanded: bool`** local state.

```dart
class PerCategoryBreakdownCard extends ConsumerStatefulWidget {
  // constructor takes bookId, startDate, endDate, locale, (optional) scopeLabel for group mode
}

class _PerCategoryBreakdownCardState extends ConsumerState<PerCategoryBreakdownCard> {
  bool _isExpanded = false;
  static const int _defaultTop = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBreakdown = ref.watch(...);
    return asyncBreakdown.when(
      data: (result) => switch (result) {
        Empty() => _empty(),
        Value(:final data, sampleSize: _) => _renderValue(data),
      },
      // ...
    );
  }

  Widget _renderValue(PerCategorySoulBreakdown data) {
    final visibleCount = _isExpanded ? data.items.length : math.min(_defaultTop, data.items.length);
    final visible = data.items.take(visibleCount).toList();
    final showAllAffordance = data.items.length > _defaultTop;
    final hasOther = data.otherCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_title(), style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        for (final row in visible) ...[
          _CategoryRow(row: row, locale: locale),
          const SizedBox(height: 8),
        ],
        if (hasOther) ...[
          const Divider(height: 1),
          const SizedBox(height: 8),
          _OtherFoldRow(otherCount: data.otherCount, categoryCount: data.otherCategoryCount),
          const SizedBox(height: 8),
        ],
        if (showAllAffordance)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
              child: Text(_isExpanded
                ? S.of(context).analyticsPerCategoryShowLess
                : S.of(context).analyticsPerCategoryShowAll),
            ),
          ),
      ],
    );
  }
}
```

**`SoulVsSurvivalCard` — two-column (solo) / 2×2 grid (group):**

Layout idioms:
- Solo: `IntrinsicHeight + Row(children: [Expanded(SoulCell), VerticalDivider(width: 1), Expanded(SurvivalCell)])` — auto-equalizes column heights.
- Group: `Column(children: [Row(YouSoul, V, YouSurvival), Divider, Row(FamilySoul, V, FamilySurvival)])` — 2×2 grid via Column<Row>.
- `VerticalDivider` color: `context.wmBorderDivider`.
- Cells inherit `wmSoulTagBg` / `wmSurvivalTagBg` subtle backgrounds per UI-SPEC table.

**Scaffold change in `analytics_screen.dart`** (extending the Distribution group at lines 106-121):

```dart
// EXISTING (lines 106-121):
AnalyticsScreenSectionHeader(label: l10n.analyticsGroupHeaderDistribution),
const SizedBox(height: 8),
_CategoryDonutCard(bookId: bookId, startDate: startDate, endDate: endDate),
const SizedBox(height: 8),
_SatisfactionHistogramOrFallback(bookId: bookId, startDate: startDate, endDate: endDate, currencyCode: currencyCode),

// PHASE 16 EXTENSION (per D-13 insertion order):
AnalyticsScreenSectionHeader(label: l10n.analyticsGroupHeaderDistribution),
const SizedBox(height: 8),
_CategoryDonutCard(bookId: bookId, startDate: startDate, endDate: endDate),
const SizedBox(height: 8),
SoulVsSurvivalCard(  // NEW
  bookId: bookId,
  startDate: startDate,
  endDate: endDate,
  currencyCode: currencyCode,
  locale: locale,
  isGroupMode: isGroupMode,
),
const SizedBox(height: 8),
_SatisfactionHistogramOrFallback(bookId: bookId, startDate: startDate, endDate: endDate, currencyCode: currencyCode),
const SizedBox(height: 8),
PerCategoryBreakdownCard(  // NEW — solo or group "You" instance
  bookId: bookId,
  startDate: startDate,
  endDate: endDate,
  locale: locale,
  scope: PerCategoryScope.you,  // enum: solo, you, family
),
if (isGroupMode) ...[
  const SizedBox(height: 8),
  PerCategoryBreakdownCard(  // NEW — group "Family" instance (D-17)
    bookId: bookId,        // unused for family scope but required by widget signature
    startDate: startDate,
    endDate: endDate,
    locale: locale,
    scope: PerCategoryScope.family,
  ),
],
```

`AsyncValue.when` fault isolation preserved per card (existing pattern at lines 249-282, 302-320, 343-360, 394-429, 456-473, 500-518, 540-554).

## R6. i18n + ARB Parity

**Inventory of existing keys (verified in `lib/l10n/app_en.arb`):**

| Key | Where used | Status |
|-----|-----------|--------|
| `analyticsGroupHeaderTime`, `analyticsGroupHeaderDistribution`, `analyticsGroupHeaderStories` | Section headers | Existing — reused |
| `analyticsCardTitleCategoryDonut`, `analyticsCardCaptionCategoryDonut`, `analyticsCategoryDonutOther` | Donut card | Existing — sibling pattern reference |
| `analyticsCardTitleFamilyInsight`, `analyticsFamilyEmpty` | Family card | Existing — group-mode precedent |
| `analyticsCardErrorHeading`, `analyticsCardErrorBody`, `analyticsCardErrorRetry` | Card error state | Existing — REUSED for Phase 16 error states |
| `analyticsCardTitleSatisfactionHistogram`, `analyticsCardCaptionHistogram` | Histogram card | Existing — sibling pattern reference |

**No collision detected** for Phase 16 proposed keys (verified by grep: no existing `analyticsCardTitleLedgerThisWindow`, no `analyticsPerCategory*`, no `analyticsLedgerColumn*`).

**Note:** `homeMonthComparison: "vs Last Month"` exists at `app_en.arb:578` — this is a HomeScreen string (NOT AnalyticsScreen). It contains the substring "vs" which is on Phase 16's forbidden list — but it's not on a Phase 16 surface. **The anti-toxicity widget test must scope assertions to the Phase 16 widgets only, not the whole app.** (Standard widget-test practice.)

**Proposed new keys (~15-17 keys × 3 locales = ~45-51 ARB additions):**

Per UI-SPEC.md §Copywriting Contract (verified accurate):

| ARB key | en | zh | ja |
|---------|----|----|----|
| `analyticsCardTitlePerCategorySoul` | Joy · Categories | 悦己 · 类别 | ときめき · カテゴリ |
| `analyticsCardTitlePerCategorySoulYou` | Joy · Your categories | 悦己 · 你的类别 | ときめき · あなたのカテゴリ |
| `analyticsCardTitlePerCategorySoulFamily` | Joy · Family categories | 悦己 · 家庭类别 | ときめき · 家族のカテゴリ |
| `analyticsPerCategoryRow` (placeholders {categoryName, avgSat, count}) | "{categoryName} · {avgSat} avg / {count} entries" | "{categoryName} · 平均 {avgSat} / {count} 条" | "{categoryName} · 平均 {avgSat} / {count} 件" |
| `analyticsPerCategoryOtherFold` (placeholders {totalCount, categoryCount}) | "Other: {totalCount} entries across {categoryCount} categories" | "其他：{totalCount} 条，跨 {categoryCount} 个类别" | "その他：{totalCount} 件、{categoryCount} カテゴリ" |
| `analyticsPerCategoryShowAll` | Show all | 展开全部 | すべて表示 |
| `analyticsPerCategoryShowLess` | Show less | 收起 | 折りたたむ |
| `analyticsPerCategoryEmpty` | No category data this window | 本期暂无类别数据 | 今期はカテゴリデータがありません |
| `analyticsCardTitleLedgerThisWindow` | Ledger · This window | 本期账本描述 | 今期の家計簿 |
| `analyticsLedgerColumnSoul` | Soul | 灵魂 | ときめき |
| `analyticsLedgerColumnSurvival` | Survival | 生存 | 生活 |
| `analyticsLedgerRowYou` | You | 你 | あなた |
| `analyticsLedgerRowFamily` | Family | 家庭 | 家族 |
| `analyticsLedgerCellEntries` (placeholder {count}) | "{count} entries" | "{count} 条" | "{count} 件" |
| `analyticsLedgerCellAvgSat` (placeholder {avgSat}) | "{avgSat} avg satisfaction" | "平均满意 {avgSat}" | "平均満足 {avgSat}" |
| `analyticsLedgerEmpty` | No data this window | 本期暂无数据 | 今期はデータがありません |
| `analyticsLedgerFamilyEmpty` | Family data not available this window | 本期暂无家庭数据 | 今期は家族データがありません |

All UI text via `S.of(context)`. All currency cell values delegated to `NumberFormatter.formatCurrency(amount, currencyCode, locale)`. All `avgSat` displays formatted via `.toStringAsFixed(1)` for one-decimal display (no project-wide satisfaction formatter exists per file scan; one-decimal is consistent with `family_insight_card.dart:80` precedent).

**`CategoryLocaleService.resolveFromId(categoryId, locale)` verification** (`lib/infrastructure/category/category_locale_service.dart:16-22`):
- Returns localized display name for `cat_*` category IDs.
- Falls back to raw ID for user-created (non-`cat_*`) categories.
- Already supports list-of-categories iteration (the call site iterates row-by-row).
- **No changes needed** for the new list surface.

## R7. Anti-Toxicity Widget Test Design

**Test file location:** `test/widget/features/analytics/presentation/widgets/anti_toxicity_copy_test.dart` (per project test convention).

**Test design:**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ... project imports

void main() {
  const forbiddenEn = ['better', 'worse', 'winner', 'loser', 'vs', 'versus',
    'compare', 'comparison', 'higher is good', 'lower is bad', 'score',
    'rank', 'ranking', 'wins', 'loses'];
  const forbiddenZh = ['更好', '更差', '赢', '输', '胜', '败', 'vs',
    '对比', '比较', '排名', '分数', '胜出', '落败'];
  const forbiddenJa = ['勝ち', '負け', 'より良い', 'より悪い', '比較',
    '対決', 'スコア', 'ランキング', '勝つ', '負ける'];

  // Synthetic data fixtures
  final richPerCategoryData = PerCategorySoulBreakdown(/* top-5 + Other rows */);
  final richSnapshotData = SoulVsSurvivalSnapshot(/* solo + family */);

  group('anti-toxicity — PerCategoryBreakdownCard', () {
    for (final locale in [const Locale('en'), const Locale('zh'), const Locale('ja')]) {
      for (final scope in PerCategoryScope.values) {
        testWidgets('locale=$locale scope=$scope value-state has no forbidden substrings', (tester) async {
          await tester.pumpWidget(
            createLocalizedWidget(
              ProviderScope(
                overrides: [
                  // override provider to return richPerCategoryData
                ],
                child: PerCategoryBreakdownCard(
                  bookId: 'b1', startDate: DateTime(2026, 5), endDate: DateTime(2026, 5, 31),
                  locale: locale, scope: scope,
                ),
              ),
              locale: locale,
            ),
          );
          await tester.pumpAndSettle();

          final forbidden = locale.languageCode == 'zh' ? forbiddenZh
            : locale.languageCode == 'ja' ? forbiddenJa : forbiddenEn;
          for (final sub in forbidden) {
            expect(find.textContaining(sub, findRichText: true), findsNothing,
              reason: 'Locale=$locale scope=$scope: rendered text contains forbidden substring "$sub"');
          }
        });

        // Repeat for Empty state, sub-min-N-only state, expanded state
      }
    }
  });

  group('anti-toxicity — SoulVsSurvivalCard', () {
    // Same pattern, both solo and group modes, both value and empty states.
  });
}
```

**Coverage:**
- ✅ All three locales × both cards × all major states (value, empty, sub-min-N, expanded, group-mode).
- ✅ Uses `find.textContaining(substring, findRichText: true)` for robust substring detection.
- ✅ Synthetic data fixtures live in `test/helpers/` alongside `happiness_test_fixtures.dart` (recommend `phase16_fixtures.dart`).
- ✅ ARB-driven — if ARB ja/zh/en accidentally introduces a forbidden substring, the test catches it.

**Plan task suggestion:** This test is mandatory per D-14. Add as a Plan task with explicit "anti-toxicity assertion: D-14 minimum coverage + locale review surfaces" deliverable.

## R8. Goldens + Theme Support

**Existing golden suite inventory** (`test/golden/goldens/`):
- `amount_display_{cny,jpy,usd}.png` — 3 currency variants (single locale)
- `home_hero_card_*_ja.png` — 10 goldens, all `ja` locale (1 dark, 9 light)
- `summary_cards_{en,ja}.png` — 2 goldens

**Conclusion:** Project's golden suite **does** cover dark theme (`home_hero_card_family_dark_ja.png`). Phase 16 should match this with light + dark variants for each new card.

**Naming convention** (matching `home_hero_card_*` precedent):
- `goldens/per_category_breakdown_card_solo_light_ja.png`
- `goldens/per_category_breakdown_card_solo_dark_ja.png`
- `goldens/per_category_breakdown_card_group_you_light_ja.png` (or just one combined screenshot showing both stacked cards)
- `goldens/per_category_breakdown_card_group_family_light_ja.png`
- `goldens/soul_vs_survival_card_solo_light_ja.png`
- `goldens/soul_vs_survival_card_solo_dark_ja.png`
- `goldens/soul_vs_survival_card_group_light_ja.png`
- `goldens/soul_vs_survival_card_group_dark_ja.png`

Minimum: 6 new goldens (3 surfaces × 2 themes). Maximum: 8-10 if you split solo / group / sub-min-N states.

**Golden test pattern** mirrors `test/golden/home_hero_card_golden_test.dart` (verified, lines 1-179):
- `MaterialApp` wrapper with `localizationsDelegates`, `theme: ThemeData.light(), darkTheme: ThemeData.dark(), themeMode: themeMode`.
- Fixed `SizedBox(width: 600, height: ???)` wrap.
- `tester.pumpAndSettle()` before `expectLater(matchesGoldenFile(...))`.
- Single locale (`ja`) per existing precedent — anti-toxicity test covers en/zh separately.

**Group-mode goldens add 1 additional file per surface** — UI-SPEC.md confirms (Card+grid for Soul-vs-Survival is single golden; Per-Category stacked-cards is 2 widgets stacked but a single test screenshot of the whole AnalyticsScreen Distribution group would capture both).

## R9. Refresh + Invalidation Wiring

**`_refresh()` in `analytics_screen.dart` (lines 160-213):**

Current invalidation set (`(startDate, endDate)`-keyed providers):
- `monthlyReportProvider`
- `expenseTrendProvider` (anchor-keyed, not window-keyed)
- `earliestTransactionMonthProvider` (bookId-keyed)
- `happinessReportProvider`
- `satisfactionDistributionProvider`
- `bestJoyMomentProvider`
- `largestMonthlyExpenseProvider`
- (if isGroupMode) `familyHappinessProvider`, `shadowBooksProvider`

**Phase 16 ADDITIONS:**
- `perCategorySoulBreakdownProvider(bookId: bookId, startDate: startDate, endDate: endDate)`
- `soulVsSurvivalSnapshotProvider(bookId: bookId, startDate: startDate, endDate: endDate)`
- (if isGroupMode) `perCategorySoulBreakdownFamilyProvider(startDate: startDate, endDate: endDate)`
- (if isGroupMode) `soulVsSurvivalSnapshotFamilyProvider(startDate: startDate, endDate: endDate)`

**Explicit confirmation: HomeHero/Home tab providers are NOT in the set.** The new providers all key off `(startDate, endDate)` from the AnalyticsScreen window — distinct from HomeHero's month-anchored `(startDate, endDate)`. Even if HomeHero internally consumes `happinessReportProvider`, AnalyticsScreen's invalidation uses different `(startDate, endDate)` keys, so HomeHero's provider instance is NOT invalidated.

**The comment at line 168 (`// D-12: _refresh MUST NOT invalidate any home/* provider`)** stays as a binding constraint and reviewer signal.

**Test extension required:** Add the four new Phase 16 providers to the `home_screen_isolation_test.dart` assertion that `AnalyticsScreen._refresh()` does NOT cause HomeHero rebuild.

## R10. Test Strategy + Per-File Coverage

Per REQUIREMENTS.md Cross-Phase Constraints §5 — "per-file coverage ≥70% on changed files".

**Per-file expected coverage targets:**

| File | Expected coverage | Test source |
|------|-------------------|-------------|
| `lib/data/daos/analytics_dao.dart` (added methods only) | ≥80% | DAO tests with in-memory Drift (existing pattern in `test/unit/data/daos/`) |
| `lib/data/repositories/analytics_repository_impl.dart` (added bridge methods) | ≥70% | Existing repository test pattern (`analytics_repository_happiness_test.dart`) |
| `lib/application/analytics/get_per_category_soul_breakdown_use_case.dart` | ≥90% | Direct mocktail-based use case test |
| `lib/application/analytics/get_per_category_soul_breakdown_across_books_use_case.dart` | ≥90% | Same |
| `lib/application/analytics/get_soul_vs_survival_snapshot_use_case.dart` | ≥90% | Same |
| `lib/application/analytics/get_soul_vs_survival_snapshot_across_books_use_case.dart` | ≥90% | Same |
| `lib/features/analytics/domain/models/per_category_soul_breakdown.dart` | ≥80% | Freezed model test (equality + copyWith) |
| `lib/features/analytics/domain/models/ledger_snapshot.dart` | ≥80% | Freezed model test |
| `lib/features/analytics/presentation/providers/state_ledger_snapshot.dart` | ≥70% | Widget integration tests cover providers indirectly + dedicated `state_ledger_snapshot_test.dart` if needed |
| `lib/features/analytics/presentation/providers/repository_providers.dart` (added providers) | ≥70% | Indirect via use case tests (provider definitions are thin) |
| `lib/features/analytics/presentation/widgets/per_category_breakdown_card.dart` | ≥80% | Widget tests covering loading, empty, sub-min-N, value, expanded, error |
| `lib/features/analytics/presentation/widgets/soul_vs_survival_card.dart` | ≥80% | Widget tests covering loading, empty, value (solo + group), error, family-empty |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` (modified _refresh) | maintain ≥70% | Extend `home_screen_isolation_test.dart` + dedicated refresh assertion |

**Test helpers / fixtures available:**
- `test/helpers/test_localizations.dart` — `createLocalizedWidget(child, locale, overrides)` for all widget tests.
- `test/helpers/happiness_test_fixtures.dart` — joy/satisfaction fixture builders; extend with Phase 16 fixtures (or new `phase16_fixtures.dart`).
- `test/helpers/test_provider_scope.dart` — `waitForFirstValue<T>(container, provider)` helper for async provider reads.
- `family_insight_card_test.dart` — group-mode card test precedent (D-16/D-17 family rendering).
- `category_spend_donut_chart_test.dart` — Distribution-group widget test precedent.

## R11. Validation Architecture

(See above section `## Validation Architecture` — fully populated per Step 4.)

## R12. Risk Surfaces / Landmines

Concrete failure modes the planner should pre-empt:

| Risk | Mitigation |
|------|-----------|
| Forgetting `TimeWindowValidation.assertValid` at use-case entry | Pitfall #1. Plan-task explicit deliverable: "every new use case execute() starts with TimeWindowValidation.assertValid(start, end)". Reviewer verifies. |
| Accidentally invalidating HomeHero in `_refresh()` | Pitfall #2. Plan-task: "extend home_screen_isolation_test.dart to cover Phase 16 providers". |
| ARB key collision | Verified — no Phase 16 proposed keys collide with existing keys (grep clean). |
| `intl 0.20.2` pin breakage from new dependency | Phase 16 introduces ZERO new dependencies. Risk: 0. |
| `riverpod_generator 4.x` codegen drift | Mitigated by running `build_runner build --delete-conflicting-outputs` after every annotation change + AUDIT-10 CI guardrail. |
| Drift TableIndex syntax mistakes (Pitfall #11 in CLAUDE.md) | NOT APPLICABLE — Phase 16 introduces no schema changes (no new tables, no new indices). |
| Default-2 leak in other DAO surfaces | OUT OF PHASE 16 SCOPE per CONTEXT.md §"Deferred Ideas" ("Cross-phase audit for 'default-2' leak in other analytics surfaces"). Planner can note for future hygiene pass but should NOT address in Phase 16. |
| Anti-toxicity copy regression in a single locale | Pitfall #9. Anti-toxicity widget test (R7) is mandatory and is the structural gate. |
| Sub-min-N-only state rendering broken | Plan-task: explicit test case in `per_category_breakdown_card_test.dart` for "0 qualifying categories, only Other fold row visible". |
| D-05 either-ledger-zero half-render bug | Plan-task: explicit test case in `get_soul_vs_survival_snapshot_use_case_test.dart` for "soul has 5 entries, survival has 0 → Empty". |
| D-20 family-empty rendering when shadowBooks.length < 2 | Plan-task: explicit test case + provider gate. |
| Group-mode "TWO STACKED CARDS" misimplemented as one merged card | Plan-task: D-17 explicit deliverable; integration test covers card count. |
| Group-mode "2×2 grid" misimplemented as 4 separate cards | Plan-task: D-18 explicit deliverable; widget test asserts single Card container for grid. |
| ROADMAP SC-3 wording correction missed at plan close | Plan-task #1 per D-15 — wording correction is the FIRST plan task. |
| `riverpod_lint` violations on new providers | Run `flutter pub run custom_lint` locally before commit; CI catches in `analyze` step. |
| Build runner stale generated files in CI | Pitfall #10. Plan task: regenerate before every commit; AUDIT-10 catches. |
| `flutter gen-l10n` warnings on ARB updates | Run after every ARB change; verify clean. |

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries verified at `pubspec.yaml`; no new dependencies introduced.
- Architecture (use case shapes, provider patterns, DAO patterns, widget chrome): HIGH — every pattern verified against a working precedent in the codebase (`get_family_happiness_use_case.dart`, `state_happiness.dart`, `analytics_dao.dart`, `family_insight_card.dart`).
- Pitfalls: HIGH — derived from Phase 13/14/15 CONTEXT decisions + CLAUDE.md Riverpod 3 conventions + ADR-014 default-2 trap (codebase-verified at transactions_table.dart:35).
- Domain model shapes (R4): HIGH — `SharedJoyInsight`/`SharedJoyCategoryAggregate` precedent verified; sealed type-system gate for `SurvivalLedgerSnapshot` is a novel but small extension.
- ARB key inventory (R6): HIGH — grep-verified no collisions across all 3 ARB files (1973 lines each).
- Validation architecture: HIGH — `nyquist_validation: true` in config; all test files mapped to requirements; existing test patterns reusable.

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (30 days — stable; codebase changed: 0 Phase 16 prep commits between research and planning)

---

## RESEARCH COMPLETE

### Key Findings

1. **Engagement-axis re-frame (D-01..D-04) is type-system-enforceable.** The `SurvivalLedgerSnapshot` Freezed model deliberately omits an `avgSatisfaction` field. Any code that attempts to compute or render Survival satisfaction is a compile error. This is the strongest structural gate against the default-2 trap.
2. **DAO work is small.** The new per-category DAO method is `getSharedJoyCategoryInsight` with `LIMIT 1` and `HAVING COUNT >= 3` removed (sort and filter move to Dart). The new ledger-snapshot DAO method is `getLedgerTotals` with `COUNT(*)` added. Two new helpers, both single-query and one parameterized for group mode (`book_id IN (...)`).
3. **Providers belong in a NEW `state_ledger_snapshot.dart` file.** Keeps `state_happiness.dart` Joy-focused; matches `state_<aggregate>.dart` ARCH-004 convention; gives 4 new providers a clean home (single + family-aggregate for each surface).
4. **`_refresh()` extension is mechanical.** Add 2 new provider invalidations to the main set, add 2 family-aggregate invalidations inside the `if (isGroupMode)` block. The D-12 binding (no HomeHero invalidation) is preserved because new providers are keyed by AnalyticsScreen `(startDate, endDate)`, distinct from HomeHero's month-anchored keys.
5. **Anti-toxicity widget test (D-14) is non-optional and structurally enforceable.** Trilingual `find.textContaining` assertions per forbidden substring × all states × both cards. Plan-task explicit deliverable. Plus the type-system gate (Survival has no `avgSatisfaction`) means the surface CANNOT accidentally compute a value-judgment number.
6. **Zero new dependencies, zero schema changes.** Phase 16 is pure code/config extension. Risk surface is product-integrity (anti-toxicity), not classic engineering risk.
7. **Goldens: project supports dark theme** (verified via `home_hero_card_family_dark_ja.png`). Phase 16 adds 6+ new goldens covering light + dark for both new surfaces + group-mode variants.
8. **ROADMAP SC-3 wording correction (D-15) is plan-task #1** — engagement-axis re-frame must replace the misleading "Soul ledger averages 7.4 satisfaction; survival ledger 5.1" example.

### File Created

`/Users/xinz/Development/home-pocket-app/.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/16-RESEARCH.md`

### Confidence Assessment

| Area | Level | Reason |
|------|-------|--------|
| Standard Stack | HIGH | Zero new dependencies; every library version verified against `pubspec.yaml`. |
| Architecture | HIGH | All 4 use cases / 4 providers / 2 DAO methods / 2 widgets follow verified codebase precedents. |
| Pitfalls | HIGH | Drawn from Phase 13/14/15 close decisions + CLAUDE.md Riverpod 3 conventions + verified soul_satisfaction default = 2 at `transactions_table.dart:35`. |
| ARB inventory | HIGH | Grep-verified no Phase 16 key collisions; ARB ja/zh/en all 1973 lines (parity intact). |
| Test strategy | HIGH | All existing analytics test patterns + helpers reusable; 14 new test files mapped. |
| Validation architecture | HIGH | `nyquist_validation: true` in config; full Req→Test map populated. |

### Open Questions

1. Should the per-category use case re-sort `qualifying` items defensively, or trust DAO `ORDER BY`? — Recommend defensive sort.
2. `_PerCategoryBreakdownCard` "show all" — `_isExpanded: bool` widget state vs Riverpod state? — Recommend local widget state.
3. `getLedgerSnapshot` (new DAO method with COUNT) vs composing `getLedgerTotals` + separate count helper? — Recommend new method.
4. Group-aggregate variants: separate use case files vs `aggregate: bool` flag? — Recommend separate files.
5. Solo-mode title — share "You" key or use generic `analyticsCardTitlePerCategorySoul`? — Recommend three distinct keys per UI-SPEC.

### Ready for Planning

Research complete. Planner can now create PLAN.md files. Recommended task structure: 7-10 plans covering (1) ROADMAP SC-3 wording correction, (2) ARB + i18n keys (~17 keys × 3 locales), (3) domain models (PerCategorySoulBreakdown + LedgerSnapshot, Freezed), (4) repository + DAO surfaces (2 single-book methods + 2 group-aggregate methods), (5) use cases (4 new), (6) providers + state_ledger_snapshot.dart + repository_providers extensions, (7) PerCategoryBreakdownCard widget, (8) SoulVsSurvivalCard widget, (9) AnalyticsScreen scaffold + _refresh() extension, (10) anti-toxicity + goldens + integration tests.
