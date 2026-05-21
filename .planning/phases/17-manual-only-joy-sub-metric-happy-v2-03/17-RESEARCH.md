# Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03) - Research

**Researched:** 2026-05-20
**Domain:** Drift schema migration (v16→v17), Dart enum modeling, Riverpod 3 session-state provider, AnalyticsDao filter plumbing across 10+ methods, sync payload extension, anti-toxicity widget test extension, ARB trilingual i18n.
**Confidence:** HIGH (all integration points read end-to-end; SQLite migration semantics verified against official docs)

## Summary

Phase 17 is mechanical wiring on top of well-established v1.2 precedents — there are no novel architectural problems to solve. Every pattern this phase needs already ships in the codebase: `selectedTimeWindowProvider` is the template for the new toggle provider (`state_time_window.dart` is a 22-line file using `@riverpod` notifier); `TimeWindowChip` is the template for the new chip widget; `migration_v15_to_v16_test.dart` is the template for the new round-trip migration test; `anti_toxicity_phase16_test.dart` is the template for the trilingual forbidden-substring sweep; Phase 16 already added DAO filter parameters (`bookIds: List<String>`) so the optional-filter shape is precedented. The risk surface is execution discipline (every DAO method touched, ARB parity, `build_runner` after `@freezed`/`@riverpod`/Drift changes) — not technical novelty.

The one **non-trivial discovery** is the migration shape: the existing `transactions` table uses Drift table-level `customConstraints` for the `soul_satisfaction` CHECK. Drift's `migrator.addColumn` does NOT rewrite table-level constraints on an existing database — `customConstraints` are only applied at table-creation time. Phase 17's CHECK on `entry_source` must therefore be expressed as a **column-level inline check** via raw `customStatement('ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL DEFAULT \'manual\' CHECK(entry_source IN (\'manual\',\'voice\',\'ocr\'))')` rather than via `migrator.addColumn` + table-level constraint. SQLite ALTER TABLE ADD COLUMN supports DEFAULT 'manual' + column-level CHECK in the same statement (verified against `sqlite.org/lang_altertable.html`).

The second **non-trivial discovery** is that `ocr_scanner_screen.dart` does NOT currently push to `TransactionConfirmScreen` — it is a UI stub whose shutter button just calls `Navigator.pop(context)`. The CONTEXT references to "OCR push site" must be interpreted as either (a) adding a Phase 17 placeholder push site that stamps `'manual'`, or (b) recognizing there is nothing to stamp yet and deferring that wire-up to MOD-005. Recommended: option (b) — Phase 17 does not introduce a synthetic push site that ships dead code; the `EntrySource.manual` default is what MOD-005's first commit will overwrite to `EntrySource.ocr`. This aligns with CONTEXT D-07's intent (no `'ocr'` row in v1.2) and avoids planning for a push site that doesn't exist.

**Primary recommendation:** Plan 7-9 tasks of moderate size, with Plans 01 (ROADMAP correction), 02 (schema migration + Transaction model + Companion update + migration round-trip test) and 09 (AnalyticsScreen integration + _refresh wiring + isolation test extension) as the highest-risk bookends. Most plans are single-DAO-method-or-use-case scope.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** `transactions.entry_source` is `TEXT NOT NULL DEFAULT 'manual'` with CHECK(entry_source IN ('manual','voice','ocr')). Dart enum `EntrySource { manual, voice, ocr }` lives in `lib/features/accounting/domain/models/entry_source.dart` (or appended to existing accounting enum file — planner discretion). The `ocr` enum value is reserved for MOD-005; Phase 17 does NOT produce any live `'ocr'` row.
- **D-02:** `entry_source` does NOT enter the hash chain. `currentHash` continues to be computed from `id + amount + timestamp + prevHash` only.
- **D-03:** Sync payload carries `entry_source`. `TransactionSyncMapper.toCreateOperation` and `fromCreateOperation` serialize and respect the field. Older-schema peers sending payload without the field cause receiving device to fall back to `'manual'`.
- **D-04:** Pre-launch backfill: all existing rows resolve to `'manual'` via the column-level DEFAULT — no separate UPDATE statement.
- **D-05:** No new index by default on `entry_source`. Re-evaluate after profiling on a seeded large book.
- **D-06:** `CreateTransactionParams` gains `required EntrySource entrySource`. No default value — every caller must specify.
- **D-07:** OCR scanner stamps `'manual'` in v1.2; MOD-005 changes it as a separate commit.
- **D-08:** `demo_data_service.dart` `insertTransaction` calls pass `EntrySource.manual`.
- **D-09:** Sync-receive path falls back to `'manual'` for older-schema peers.
- **D-10:** `selectedJoyMetricVariantProvider` is session-scoped Riverpod notifier providing `JoyMetricVariant { all, manualOnly }`. Default = `all`. Cold-start resets to `all`.
- **D-11:** Provider file lives at `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart`.
- **D-12:** Toggle UI = `JoyMetricVariantChip` in `AppBar.actions`, placed directly to the right of `TimeWindowChip`.
- **D-13:** Five ARB additions, ja/zh/en parity: `analyticsJoyMetricVariantChipLabel`, `analyticsJoyMetricVariantSheetTitle`, `analyticsJoyMetricVariantOptionAll`, `analyticsJoyMetricVariantOptionManualOnly`, `analyticsJoyMetricVariantManualOnlyExplain`.
- **D-14:** Forbidden-substring list extension. Trilingual minimums per locale (see CONTEXT for exact strings).
- **D-15:** Manual-only is a WHOLE-AnalyticsScreen audit lens, not a Joy-only filter. ALL surfaces filter under manualOnly mode. NOT filtered: `GetMonthlyJoyTargetRecommendationUseCase`, HomeHero.
- **D-16:** ROADMAP SC-3 wording correction is plan-phase task #1 (pattern mirrors Phase 16 D-15).
- **D-17:** DAO plumbing — each affected `AnalyticsDao` method gains `EntrySource? entrySourceFilter` parameter. `_soulExpenseFilter` / `_survivalExpenseFilter` constants UNCHANGED — `entry_source` added as separate appended clause.
- **D-18:** `_refresh()` invalidation extension — providers consuming the toggle fold `selectedJoyMetricVariantProvider` into their family key. HomeHero / Home tab providers MUST NOT be invalidated by AnalyticsScreen refresh.

### Claude's Discretion

- Exact placement of `EntrySource` enum file (recommended: sibling to `transaction.dart`).
- Bottom sheet vs popup for `JoyMetricVariantChip` (bottom sheet matches TimeWindowChip pattern).
- Exact ARB key wording (D-13 anchors are guidance, not commands).
- DAO method signature ordering for new parameter (recommended: after `startDate`/`endDate`, null-default).
- Group-mode wiring of `entrySourceFilter` (across-books variants get same parameter).
- Migration test fixture strategy (extend existing v15→v16 pattern).
- Per-screen unit tests (extend existing `*_test.dart` files; no new top-level files).
- Provider family key shape: `(bookId, startDate, endDate, joyMetricVariant)`.

### Deferred Ideas (OUT OF SCOPE)

- HomeHero behavior changes (untouched, ADR-016 §3).
- `GetMonthlyJoyTargetRecommendationUseCase` filter participation (universal, untouched).
- MOD-005 OCR functional implementation (Phase 17 only reserves enum value).
- Per-family-member voice-vs-manual breakdown (permanently forbidden, ADR-012 §6).
- Persisting toggle across app restart (session-only by design).
- Per-book toggle state (toggle is global to AnalyticsScreen).
- Cross-period delta UI (ADR-012 §4).
- Hash-chain inclusion of `entry_source` (rejected, D-02).
- `entry_source` index (D-05 — re-evaluate post-launch).
- OCR-only Joy variant (binary toggle in v1.2; 3-way reconsidered when MOD-005 ships).
- `entry_source` audit log meta-statistic surface.
- TOOL-V2-01 fl_chart 1.x upgrade (out of v1.2).
- FAMILY-V2-01/02/03 family privacy hardening (out of v1.2).

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HAPPY-V2-03 | User can opt to view a manual-entry-only Joy sub-metric variant (excludes voice-estimated entries). Requires schema migration to add `entry_source` column. | Schema migration v16→v17 plumbed via SQLite `ALTER TABLE ADD COLUMN ... CHECK(...)` (column-level inline, NOT table-level customConstraints — see Common Pitfall #1). Enum modeled at domain layer; threaded through `CreateTransactionParams` (required, no default — D-06); stamped at 3 entry sites (voice/manual push + demo). DAO methods (12+) gain `EntrySource? entrySourceFilter`. Use cases re-emit the parameter on their `execute` signatures. AnalyticsScreen toggle = `JoyMetricVariantChip` + `selectedJoyMetricVariantProvider`. HomeHero / Settings recommendation isolation enforced by family-key omission (NOT invalidation suppression). ARB additions in trilingual lockstep. Anti-toxicity widget test extended with Phase 17 forbidden substrings. Round-trip migration test + integration test for voice/manual stamp. |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| `entry_source` column + CHECK | Data (`lib/data/tables/`, `lib/data/app_database.dart`) | — | Schema is a data-tier concern; migration block in app_database.dart |
| `EntrySource` enum | Domain (`lib/features/accounting/domain/models/`) | — | Domain enum sibling to `LedgerType`; consumed by both data layer (via `.name`) and presentation layer |
| Stamping on entry paths | Presentation (push sites) → Application (`CreateTransactionParams`) | Data (Companion insert) | Push sites declare intent; use case threads param; DAO persists |
| Sync payload extension | Domain (`TransactionSyncMapper`) | Application (`apply_sync_operations_use_case.dart` consumes via mapper) | Mapper owns wire-format; use cases call it but do not know the field |
| Manual-only toggle state | Presentation (`state_joy_metric_variant.dart`) | — | Session-only UI state; never reaches application/data |
| AnalyticsDao filter SQL | Data | Application (use case threads param to repo) | DAO owns SQL composition; `EntrySource?` is null-default to preserve no-filter behavior |
| Toggle UI affordance | Presentation (`JoyMetricVariantChip`) | — | Pure widget; reads provider, opens sheet, updates provider |
| Family-key invalidation | Presentation (Riverpod auto-invalidation via key change) | — | No code-level invalidation needed when key changes; D-18 |
| HomeHero / Settings isolation | Presentation (negative requirement: NO read of `selectedJoyMetricVariantProvider`) | — | Verified by `home_screen_isolation_test.dart` extension |
| Anti-toxicity assertion | Test (widget) | Presentation (ARB) | Widget test asserts; ARB owns the strings |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Drift (drift, drift_dev) | per current pubspec | Schema migration via `MigrationStrategy.onUpgrade`, custom statements for ALTER TABLE | [VERIFIED: codebase] Already in use for v3-v16 migrations; precedent: `if (from < 4) await migrator.addColumn(transactions, transactions.soulSatisfaction);` |
| Freezed (freezed_annotation, build_runner) | per current pubspec | `Transaction` model regen with `entrySource` field + JSON serialization | [VERIFIED: codebase] Already used for `Transaction` (line 11 of `transaction.dart`) — adding a field is a pure regen |
| Riverpod 3 (riverpod_annotation, riverpod_generator) | 3.1+ per CLAUDE.md | `@riverpod` notifier for `selectedJoyMetricVariantProvider`; family key on consuming providers | [VERIFIED: codebase] Direct template `state_time_window.dart` |
| flutter_localizations + ARB | intl 0.20.2 pinned | Trilingual key additions ja/zh/en lockstep | [VERIFIED: codebase] Active pattern; pubspec pin must not change |
| sqlcipher_flutter_libs | ^0.6.x per CLAUDE.md | SQLCipher AES-256 for the migration | [VERIFIED: codebase] Not touched by Phase 17; mentioned here to confirm no native changes needed |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_test | bundled | Widget tests for anti-toxicity sweep, JoyMetricVariantChip tap-flow, HomeHero isolation extension | All test plans |
| mocktail | per current pubspec | Mock use cases in widget tests (pattern: `home_screen_isolation_test.dart`) | Widget tests for variant-aware flows |
| sqlite3 / drift native | bundled | In-memory DB for migration round-trip test | Migration test |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `EntrySource` enum at domain layer | String literals threaded through use case | Rejected — D-06's "required, no default" depends on type safety; strings allow silent typos |
| Adding `entry_source` to hash chain | Including in `calculateTransactionHash` input | Rejected — D-02 preserves v1.1 hash continuity (also matches `soul_satisfaction` precedent) |
| New `entry_source` index | `idx_tx_book_entry_source` composite | Deferred — D-05 says no (low cardinality, monthly soul tx count 10-100 per book) |
| Mutating `_soulExpenseFilter` / `_survivalExpenseFilter` constants to embed entry_source filter | Single constant carrying full predicate | Rejected — D-17 explicitly preserves the predicate-drift defense from Phase 16 |
| Persisting toggle state | SharedPreferences via SettingsRepository | Rejected — D-10 session-only matches Phase 15 D-12 (`selectedTimeWindowProvider`) precedent |

**Installation:** No new package installs needed. All required libraries are present in pubspec.yaml.

**Version verification:** Skipped — Phase 17 introduces ZERO new packages. The existing Drift / Freezed / Riverpod 3 / sqlcipher_flutter_libs versions are pinned by Phase 16 and previous phases. CLAUDE.md explicitly forbids touching dependency pins (file_picker 11.x, package_info_plus 9.0.1, share_plus 12.0.2 trio).

## Package Legitimacy Audit

> **Not applicable.** Phase 17 installs ZERO new packages. All implementation reuses existing dependencies (Drift, Freezed, Riverpod 3, flutter_localizations, mocktail, flutter_test). Slopcheck gate intentionally skipped.

## Architecture Patterns

### System Architecture Diagram

```
Entry-paths                       Domain                    Data                Sync
-----------                       ------                    ----                ----
voice_input_screen.dart:352 ─┐
transaction_entry_screen      │
  .dart:225                  ─┤                                                  
demo_data_service.dart:103,  ─┤
  137                          ▼
                          TransactionConfirmScreen
                          (+ EntrySource ctor param, D-06)
                                    │
                                    ▼
                          CreateTransactionParams
                          (required EntrySource entrySource)
                                    │
                                    ▼
                          CreateTransactionUseCase
                          ─── hash chain calc (unchanged, D-02)
                                    │                                              
                                    ▼                                              
                          Transaction (Freezed) ──────► TransactionRepositoryImpl
                                    │                       ▼                       
                                    │                   TransactionDao.insertTransaction
                                    │                   (+ entrySource string param)
                                    │                       ▼                       
                                    │                   Drift TransactionsCompanion
                                    │                   (entry_source: Value(...))
                                    │
                                    └─► TransactionSyncMapper.toCreateOperation
                                        (+ entry_source key in payload, D-03)


Read path (AnalyticsScreen)

AppBar.actions: [TimeWindowChip, JoyMetricVariantChip]
                                     │
                                     ▼ (tap → sheet → setVariant)
              selectedJoyMetricVariantProvider (JoyMetricVariant { all, manualOnly })
                                     │ (read by every state_*.dart provider that
                                     ▼  feeds an AnalyticsScreen card per D-15)
              state_happiness.dart / state_analytics.dart / state_ledger_snapshot.dart
              (family-key gains joyMetricVariant; provider resolves to
               EntrySource? = manualOnly ? EntrySource.manual : null)
                                     │
                                     ▼
              Application use cases (all 10+ AnalyticsScreen-feeding use cases gain
              EntrySource? entrySourceFilter on execute())
                                     │
                                     ▼
              AnalyticsRepository → AnalyticsDao methods
              (each appends "AND entry_source = ?" when filter non-null)


Negative space (D-15 exclusions):
  HomeHero providers (state_home/*.dart) — DO NOT read selectedJoyMetricVariantProvider
  monthlyJoyTargetRecommendationProvider — DO NOT take entrySourceFilter parameter
  Settings recommendation UI — unaffected by toggle
```

### Recommended Project Structure

```
lib/
├── data/
│   ├── tables/
│   │   └── transactions_table.dart        # ADD: entrySource TextColumn
│   ├── daos/
│   │   ├── analytics_dao.dart             # MODIFY: 10+ methods gain entrySourceFilter param
│   │   └── transaction_dao.dart           # MODIFY: insertTransaction adds entrySource param
│   ├── repositories/
│   │   ├── transaction_repository_impl.dart  # MODIFY: passes transaction.entrySource.name
│   │   └── analytics_repository_impl.dart    # MODIFY: re-emits entrySourceFilter (if exists; verify)
│   └── app_database.dart                  # MODIFY: schemaVersion 16→17, migration block
├── features/accounting/domain/models/
│   ├── entry_source.dart                  # NEW: enum EntrySource { manual, voice, ocr }
│   └── transaction.dart                   # MODIFY: + required EntrySource entrySource field
├── features/accounting/domain/models/
│   └── transaction_sync_mapper.dart       # MODIFY: toSyncMap + fromSyncMap handle entry_source
├── application/
│   ├── accounting/create_transaction_use_case.dart  # MODIFY: CreateTransactionParams + required entrySource
│   └── analytics/
│       ├── get_happiness_report_use_case.dart      # MODIFY: + EntrySource? entrySourceFilter
│       ├── get_monthly_report_use_case.dart        # MODIFY: same
│       ├── get_per_category_soul_breakdown_use_case.dart  # MODIFY: same
│       ├── get_per_category_soul_breakdown_across_books_use_case.dart  # same
│       ├── get_soul_vs_survival_snapshot_use_case.dart  # same
│       ├── get_soul_vs_survival_snapshot_across_books_use_case.dart  # same
│       ├── get_best_joy_moment_use_case.dart       # MODIFY: same
│       ├── get_satisfaction_distribution_use_case.dart  # same
│       ├── get_largest_monthly_expense_use_case.dart   # same
│       ├── get_expense_trend_use_case.dart         # MODIFY: same (for 6-month under D-15)
│       ├── get_family_happiness_use_case.dart      # MODIFY: same
│       ├── get_monthly_joy_target_recommendation_use_case.dart  # DO NOT MODIFY (D-15 exclusion)
│       └── demo_data_service.dart                  # MODIFY: insertTransaction calls pass 'manual'
├── features/analytics/
│   ├── domain/models/                              # NO CHANGE
│   └── presentation/
│       ├── providers/
│       │   ├── state_joy_metric_variant.dart       # NEW: JoyMetricVariant + selectedJoyMetricVariantProvider
│       │   ├── state_analytics.dart                # MODIFY: family key + read variant + thread filter
│       │   ├── state_happiness.dart                # MODIFY: same
│       │   └── state_ledger_snapshot.dart          # MODIFY: same
│       ├── screens/
│       │   └── analytics_screen.dart               # MODIFY: AppBar.actions adds JoyMetricVariantChip
│       └── widgets/
│           └── joy_metric_variant_chip.dart        # NEW: chip + bottom sheet (TimeWindowChip clone)
└── features/accounting/presentation/screens/
    ├── transaction_confirm_screen.dart             # MODIFY: + required EntrySource entrySource ctor param
    ├── voice_input_screen.dart:352                 # MODIFY: pass EntrySource.voice
    └── transaction_entry_screen.dart:225           # MODIFY: pass EntrySource.manual

lib/l10n/
├── app_en.arb                                      # ADD: 5 keys
├── app_ja.arb                                      # ADD: 5 keys
└── app_zh.arb                                      # ADD: 5 keys

test/
├── unit/data/migrations/
│   └── migration_v16_to_v17_test.dart              # NEW: round-trip + DEFAULT + CHECK assertions
├── unit/features/accounting/domain/models/
│   └── transaction_sync_mapper_test.dart           # MODIFY: + entry_source round-trip + fallback to manual
├── unit/application/analytics/
│   └── *_test.dart                                 # MODIFY: each affected use case test adds two cases
│                                                   # (entrySourceFilter=null vs EntrySource.manual)
├── integration/sync/
│   └── bill_sync_round_trip_test.dart              # MODIFY: assert entry_source survives round-trip
├── integration/
│   └── entry_path_stamping_test.dart               # NEW (or extend existing): manual+voice stamp
└── widget/features/
    ├── analytics/presentation/widgets/
    │   ├── anti_toxicity_phase16_test.dart         # EXTEND: Phase 17 forbidden list + new card states
    │   │                                           # OR rename to anti_toxicity_phase17_test.dart
    │   └── joy_metric_variant_chip_test.dart       # NEW: tap → sheet → setVariant flow
    └── home/presentation/screens/
        └── home_screen_isolation_test.dart         # EXTEND: assert HomeHero unaffected by toggle
```

### Pattern 1: Drift schema migration with column-level inline CHECK

**What:** Add a new column to an existing table with both a DEFAULT and a CHECK constraint applied to existing rows + future inserts.

**When to use:** Whenever a schema bump adds a constrained column AND the project uses Drift table-level `customConstraints` (NOT inline column `.check()`).

**Why custom statement, not `migrator.addColumn`:** Drift's `migrator.addColumn(transactions, transactions.entrySource)` writes ONLY the column itself with its inline column constraints (`.text().withDefault(...)()`). It does NOT update the table's `customConstraints` list on the existing SQLite schema — `customConstraints` are only baked into the SQL when Drift creates a table from scratch. For an existing v16 database upgrading to v17, the only way to apply a CHECK to existing rows + new rows is column-level inline via raw SQL.

**Example:**
```dart
// In lib/data/app_database.dart migration block, between if (from < 16) and the closing brace:
if (from < 17) {
  // D-01: column-level inline CHECK and DEFAULT. SQLite ALTER TABLE ADD COLUMN
  // permits both constraints in the same statement; the DEFAULT applies to all
  // pre-existing rows in one operation (D-04: no separate UPDATE needed).
  // Source: https://sqlite.org/lang_altertable.html
  await customStatement(
    "ALTER TABLE transactions ADD COLUMN entry_source TEXT NOT NULL "
    "DEFAULT 'manual' CHECK(entry_source IN ('manual', 'voice', 'ocr'))",
  );
}
```

The table file declares the same shape so a FRESH install (no migration) produces an equivalent column:

```dart
// In lib/data/tables/transactions_table.dart, alongside soulSatisfaction:
TextColumn get entrySource =>
    text().withDefault(const Constant('manual'))();

// Note: NO entry to customConstraints list. Drift's column-creation SQL when
// it creates the table from scratch will emit `entry_source TEXT NOT NULL
// DEFAULT 'manual'` — but the CHECK applied at v16→v17 migration time is NOT
// emitted on fresh install. To make fresh-install match, either:
//   (a) Add `'CHECK(entry_source IN (\'manual\', \'voice\', \'ocr\'))'` to
//       the customConstraints list (table-level), OR
//   (b) Use `.check(...)` inline if Drift's API permits enum checks
// Recommended: (a) — append to the existing customConstraints list. The
// table-level CHECK applies to both fresh-install and migrated-from-v17
// paths, while the migration step's column-level CHECK handles the
// pre-existing-row case.
```

### Pattern 2: Riverpod 3 session-state notifier (template)

**What:** AppBar-scoped UI state that resets on cold-start; consumed by family-keyed downstream providers.

**When to use:** AnalyticsScreen affordances that scope what data displays without persisting (Phase 15 D-12 + Phase 17 D-10 pattern).

**Example:**
```dart
// File: lib/features/analytics/presentation/providers/state_joy_metric_variant.dart
// Source: clone of state_time_window.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_joy_metric_variant.g.dart';

enum JoyMetricVariant { all, manualOnly }

/// D-10/D-11: Session-scoped AnalyticsScreen joy-metric-variant selection.
/// HomeHero is NOT a consumer (D-15 negative requirement); Settings
/// recommendation UI is NOT a consumer.
@riverpod
class SelectedJoyMetricVariant extends _$SelectedJoyMetricVariant {
  @override
  JoyMetricVariant build() => JoyMetricVariant.all;

  void setVariant(JoyMetricVariant variant) {
    state = variant;
  }
}
```

**Generated provider name:** `selectedJoyMetricVariantProvider` (Riverpod 3 strips `Notifier`-style suffix — verified against `SelectedTimeWindow` → `selectedTimeWindowProvider` precedent).

### Pattern 3: DAO method gains optional filter parameter

**What:** Append `AND entry_source = ?` to the existing WHERE clause when the filter is non-null; leave query unchanged when null.

**When to use:** Every `AnalyticsDao` method consumed by an AnalyticsScreen card (D-17).

**Example:**
```dart
// Before (analytics_dao.dart:373-404):
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async { ... }

// After:
Future<BestJoyMomentRow?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
  EntrySource? entrySourceFilter,  // NEW
}) async {
  final entrySourceClause = entrySourceFilter != null
      ? ' AND entry_source = ?'
      : '';
  final results = await _db
      .customSelect(
        'SELECT id, amount, soul_satisfaction, category_id, timestamp '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ?'
        '$entrySourceClause '
        'ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC '
        'LIMIT 1',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
          if (entrySourceFilter != null)
            Variable.withString(entrySourceFilter.name),
        ],
      )
      .get();
  // ... unchanged from here
}
```

Note: `EntrySource.name` is the Dart enum name (e.g., `'manual'`, `'voice'`) — directly compatible with the SQL column's stored values.

### Anti-Patterns to Avoid

- **Mutating `_soulExpenseFilter` / `_survivalExpenseFilter` constants:** D-17 explicitly forbids — append entry_source as a separate clause. Embedding it inside the constant breaks the Phase 16 predicate-drift defense.
- **Adding `entrySourceFilter` to `GetMonthlyJoyTargetRecommendationUseCase`:** D-15 explicitly excludes. Phase 13 D-09's note that anticipates this addition is OVERRIDDEN by Phase 17.
- **Reading `selectedJoyMetricVariantProvider` from any HomeHero / Home-tab provider:** D-15 / D-18 / ADR-016 §3. HomeHero ring stays current-month-anchored and reflects ALL entries.
- **`CreateTransactionParams.entrySource` with a default value:** D-06 forbids defaults — silently stamps `'manual'` when a new push site forgets to pass.
- **Using `migrator.addColumn` and expecting customConstraints to apply to existing rows:** Drift does not rewrite table constraints in-place; use raw `customStatement` for the column-level inline CHECK (see Pattern 1).
- **Inventing an OCR `TransactionConfirmScreen` push site to "satisfy" the entry-path coverage requirement:** the OCR screen is a UI stub with no push site; Phase 17 does NOT add one. MOD-005's first commit owns that wire-up. D-07 confirms.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Schema migration scaffolding | Custom DDL runner | Drift `MigrationStrategy.onUpgrade` block | Already in `app_database.dart`; transactional, version-keyed |
| Migration round-trip test harness | Custom test helper | Extend `migration_v15_to_v16_test.dart` pattern | Uses `AppDatabase.forTesting()` in-memory native; precedent is `index_v15_migration_test.dart` |
| ARB pluralization / placeholders | Custom string templater | flutter `gen_l10n` + ARB | Existing `S.of(context)` pattern; trilingual lockstep enforced by gen_l10n warnings |
| Forbidden-substring widget sweep | Custom widget walker | Extend `anti_toxicity_phase16_test.dart` | Already pumps card × locale × state matrix; just append phase17 list |
| Session-only state | SharedPreferences with manual reset hooks | `@riverpod` notifier with no persistence | `state_time_window.dart` precedent; cold-start reset is automatic |
| Family-key invalidation on toggle change | `ref.invalidate` in `setVariant` | Family-key change auto-invalidates (D-18) | Riverpod 3 invalidates a family entry when its key tuple changes |
| Sync payload framing | Custom JSON envelope | `TransactionSyncMapper.toCreateOperation` extension | Existing wire format; just add `entry_source` key |

**Key insight:** Phase 17 is plumbing on top of Phase 13-16 architecture. Every "library" needed is already wired and proven. The only NEW logic this phase writes is (a) the migration statement, (b) the toggle UI widget, (c) the variant enum, and (d) ARB strings.

## Runtime State Inventory

> Phase 17 is a schema migration + code edit. Existing DB rows are migrated in place by the column-level DEFAULT (D-04). No external runtime state to migrate.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | SQLCipher database `transactions` table: existing rows in dev/test/demo DBs gain `entry_source='manual'` via column DEFAULT. Pre-launch project — no production data. | None — data migration is automatic via ALTER TABLE ADD COLUMN DEFAULT |
| Live service config | None — no external service registers an entry-source identifier | None |
| OS-registered state | None — no Task Scheduler / launchd / pm2 entries reference entry sources | None |
| Secrets / env vars | None — no .env or SOPS key references entry-source semantics | None |
| Build artifacts / installed packages | `*.freezed.dart` and `*.g.dart` for `Transaction` model and Riverpod providers must regenerate. `app_database.g.dart` regenerates with bumped schemaVersion. `app_localizations*.dart` regenerates after ARB additions. | `flutter pub run build_runner build --delete-conflicting-outputs` + `flutter gen-l10n` (CLAUDE.md Pitfall #3 enforced by AUDIT-10 CI) |

**Cross-device migration semantics (D-03/D-09):** A v17 device receiving a payload from a v16 (older-schema) peer sees no `entry_source` key in the payload; the receiving device's `TransactionSyncMapper.fromSyncMap` defaults to `EntrySource.manual` (D-09). This means voice-entered txs created on a v16 device and pushed to v17 are mislabeled as 'manual' on receive — accepted as known semantics per CONTEXT D-09 ("the audit filter just under-counts voice on the receiving side").

## Common Pitfalls

### Pitfall 1: Drift `migrator.addColumn` does NOT apply table-level `customConstraints` to existing rows

**What goes wrong:** A planner reads the existing migration block (`if (from < 4) await migrator.addColumn(transactions, transactions.soulSatisfaction);`) and assumes the analogous `migrator.addColumn(transactions, transactions.entrySource)` will respect the table-level CHECK in `customConstraints`. It will not — Drift emits ONLY the column definition with inline column constraints (`.withDefault(...)`). The table-level CHECK is baked in only at table-creation time on fresh installs.

**Why it happens:** The Drift docs do not state this constraint clearly; the precedent in the codebase (`soul_satisfaction`'s CHECK) was added when the table was first created, then the column itself was added in v4 BEFORE the CHECK was added to `customConstraints`. The historical migration's CHECK was applied to existing rows via the table-level constraint being already on the table when the migrator ran — but only because of incidental ordering, not by guarantee.

**How to avoid:**
1. For the migration step, use `customStatement` with a column-level inline CHECK in the same ALTER TABLE ADD COLUMN statement (Pattern 1 above).
2. ALSO add the entry to the table's `customConstraints` list, so fresh installs of v17+ have the equivalent table-level CHECK.
3. Verify both paths in the migration test: (a) row inserted before migration retains DEFAULT 'manual', (b) attempting to insert `entry_source='invalid'` post-migration raises a SQLite CHECK violation.

**Warning signs:** Migration round-trip test passes the DEFAULT assertion but fails (or silently passes) the CHECK violation assertion. Or: a test asserts on the v17 fresh-install path and a different test asserts on the migrated-from-v16 path, but only one runs.

### Pitfall 2: `ocr_scanner_screen.dart` has NO `TransactionConfirmScreen.push()` site to stamp

**What goes wrong:** A planner reads CONTEXT's "Phase 17 ensures the OCR scanner push site stamps 'manual'" and creates a plan task to modify `ocr_scanner_screen.dart` line 58. Line 58 is the `EntryModeSwitcher(selectedMode: InputMode.ocr, bookId: bookId)` — an input mode tab, NOT a push site. The shutter button (line 129) calls `Navigator.pop(context)`, not a Navigator.push.

**Why it happens:** CONTEXT D-07 anticipates this by saying "MOD-005 changes it as a separate commit" — but the wording in D-06 ("the push site at line 58") is misleading. The OCR scanner is a UI stub.

**How to avoid:** Phase 17's `EntrySource` enum is shipped with `ocr` as a reserved value, but no code path stamps it. The plan must NOT include a task to "wire up OCR scanner push site" because (a) there is no push site, (b) creating a synthetic one ships dead code, (c) MOD-005 owns the real wire-up. The Phase 17 plan's entry-stamping task list is **3 sites only**: `voice_input_screen.dart:352`, `transaction_entry_screen.dart:225`, and `demo_data_service.dart:103+137`.

**Warning signs:** A plan-phase task that says "modify ocr_scanner_screen.dart to pass EntrySource.manual" without specifying a Navigator.push site to modify. Or: a task that creates a fresh push site in the OCR screen "for completeness".

### Pitfall 3: Riverpod 3 family key invalidation on toggle change

**What goes wrong:** A planner assumes `_refresh()` must explicitly `ref.invalidate(perCategorySoulBreakdownProvider(bookId: ..., variant: manualOnly))` when the toggle changes. This is wrong — Riverpod 3 family-keyed providers are automatically invalidated when their key tuple changes. Adding manual invalidation in `setVariant` causes double-rebuild and may break HomeHero isolation (if the manual invalidation accidentally hits a HomeHero family that shares a base provider).

**Why it happens:** Phase 15 D-12 established `_refresh()` for pull-to-refresh; planners may carry the "invalidate on state change" mental model from setState patterns.

**How to avoid:** `setVariant(JoyMetricVariant)` is a pure state mutation. The family-keyed providers (e.g., `perCategorySoulBreakdownProvider(bookId, startDate, endDate, joyMetricVariant)`) auto-resolve on next `ref.watch`. The `_refresh()` method needs NO modification for toggle-change semantics — only for pull-to-refresh. Plans should verify this by widget test: `tap toggle → no manual invalidation called → cards re-render with new data`.

**Warning signs:** Plan adds `ref.invalidate(...)` calls inside `SelectedJoyMetricVariant.setVariant`. Or: HomeHero isolation test fails because the toggle inadvertently invalidates a home provider.

### Pitfall 4: ARB key ordering and `flutter gen-l10n` lock-step failure

**What goes wrong:** A planner adds the 5 new keys to `app_en.arb` but forgets one or more in `app_ja.arb` / `app_zh.arb`. `flutter gen-l10n` will fail with `Missing translation for key 'X' in app_ja.arb`. CI gate per REQUIREMENTS.md §6 (i18n parity).

**Why it happens:** 1110+ keys per ARB file; eyeball-checking lockstep is unreliable.

**How to avoid:** Per-key add procedure: (1) add to `app_en.arb` with `@key` metadata block, (2) add to `app_ja.arb`, (3) add to `app_zh.arb`, (4) run `flutter gen-l10n` immediately, (5) verify build succeeds before moving to next key. Plans must batch all 5 keys into ONE commit so the lockstep is verifiable. The existing pattern (search `analyticsTimeWindowChipLabelCustom` across all 3 ARB files — they all sit between the same neighbors) is the model.

**Warning signs:** `flutter gen-l10n` emits warnings or fails. Lint step `flutter analyze` fails with `S.of(context).analyticsJoyMetricVariantX` undefined.

### Pitfall 5: Build_runner regen forgetting after Transaction model field addition

**What goes wrong:** Adding `required EntrySource entrySource` to `Transaction` Freezed model invalidates `transaction.freezed.dart` and `transaction.g.dart`. Failing to regen produces compile errors that look unrelated ("The named parameter 'entrySource' isn't defined for the constructor 'Transaction'"). CLAUDE.md Pitfall #3.

**Why it happens:** Codegen drift between Dart-source `Transaction` and generated `_Transaction` factory.

**How to avoid:** Every plan that modifies `@freezed` / `@riverpod` / Drift tables MUST end with `flutter pub run build_runner build --delete-conflicting-outputs`. CI gate AUDIT-10 catches stale generated files committed to git but does NOT catch in-progress dev shells. Plans should include this command as an explicit acceptance step, not assume it.

**Warning signs:** Plan-acceptance fails with `'entrySource' isn't defined` errors in code that depends on `Transaction`.

### Pitfall 6: Riverpod 3 `flutter_riverpod/legacy.dart` import drift

**What goes wrong:** A planner copies a snippet from Phase 13/14 docs that still references `StateNotifierProvider` or `StateProvider` and adds an `import 'package:flutter_riverpod/flutter_riverpod.dart';` for them. Riverpod 3 split these into `flutter_riverpod/legacy.dart` (see CLAUDE.md table).

**Why it happens:** Riverpod 3 migration was done across Phases 13-16, but inline examples may still use 2.x patterns.

**How to avoid:** Phase 17's new provider uses `@riverpod` annotation + Notifier subclass — does NOT need legacy imports. The new chip widget uses `ConsumerWidget` from `flutter_riverpod/flutter_riverpod.dart` — also no legacy. Verify by checking that any new file imports ONLY `flutter_riverpod/flutter_riverpod.dart` (and `riverpod_annotation/riverpod_annotation.dart` for the notifier file).

**Warning signs:** `custom_lint` or `riverpod_lint` violations on new files.

### Pitfall 7: ROADMAP wording correction must precede plumbing tasks

**What goes wrong:** A planner sequences the ROADMAP SC-3 wording fix (D-16) as a late plan, then verifier discovers that the wording-vs-implementation gap is masking a real D-15 scope under-implementation.

**Why it happens:** D-16 is paperwork; it feels low-value compared to the schema migration.

**How to avoid:** Phase 16 D-15 established the pattern: ROADMAP SC fixup is plan-phase Plan 01. Phase 17 follows the same sequencing (D-16). Plan 01 must update `.planning/ROADMAP.md` SC-3 to the wording in D-16 BEFORE any other plan is drafted. This single-file commit serves as a sanity-anchor for the rest of the phase.

**Warning signs:** Plan 01 is anything other than the ROADMAP wording fix. Or: verifier ships and reports "implementation matches ROADMAP SC-3 narrowly but misses the audit-lens framing".

## Code Examples

Verified patterns from official sources or codebase.

### Migration round-trip test fixture (extend existing pattern)

```dart
// File: test/unit/data/migrations/migration_v16_to_v17_test.dart
// Source: clone of migration_v15_to_v16_test.dart
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

const _targetSchemaVersion = 17;

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase.forTesting());
  tearDown(() async => await db.close());

  group('v17 entry_source column migration', () {
    test('AppDatabase schemaVersion is 17', () {
      expect(db.schemaVersion, _targetSchemaVersion);
    });

    test('omitted entry_source stores DEFAULT manual', () async {
      await _insertTransaction(db, id: 'tx_default');
      final row = await _findTransaction(db, 'tx_default');
      expect(row.entrySource, equals('manual'));
    });

    test('accepts voice', () async {
      await _insertTransaction(
        db,
        id: 'tx_voice',
        entrySource: const Value('voice'),
      );
      final row = await _findTransaction(db, 'tx_voice');
      expect(row.entrySource, equals('voice'));
    });

    test('accepts ocr (reserved, no live use in v1.2)', () async {
      await _insertTransaction(
        db,
        id: 'tx_ocr',
        entrySource: const Value('ocr'),
      );
      final row = await _findTransaction(db, 'tx_ocr');
      expect(row.entrySource, equals('ocr'));
    });

    test('rejects invalid entry_source via CHECK constraint', () async {
      expect(
        () => _insertTransaction(
          db,
          id: 'tx_invalid',
          entrySource: const Value('keyboard'),
        ),
        throwsA(isA<Object>()),
        reason: 'CHECK(entry_source IN (\'manual\',\'voice\',\'ocr\')) '
            'must reject other values',
      );
    });
  });
}
// _insertTransaction + _findTransaction helpers similar to v16 test
```

### Anti-toxicity test extension

```dart
// File: test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart
// OR: extend anti_toxicity_phase16_test.dart inline (planner discretion)

const forbiddenEnPhase17 = <String>[
  ...forbiddenEn,  // Phase 16 list
  'less accurate', 'invalid', 'unreliable', 'less valid',
  'inaccurate', 'wrong',
  // 'estimated' only when standalone in value-judgment context — exclude
  // bare 'estimated' from substring sweep because the ARB
  // 'analyticsJoyMetricVariantManualOnlyExplain' may say "Excludes
  // voice-estimated entries" which is descriptive, not judgmental.
  // Risk: substring sweep would false-positive. Plan must define an
  // allowlist OR a more specific phrase.
];

const forbiddenJaPhase17 = <String>[
  ...forbiddenJa,
  '不正確', '信頼できない', '不完全', '精度が低い', '誤り',
];

const forbiddenZhPhase17 = <String>[
  ...forbiddenZh,
  '不准', '不可靠', '不完整', '质量差', '估算不准', '错误',
];

// Test surfaces: JoyMetricVariantChip + bottom sheet + explanation copy
// across ja/zh/en × { all-selected, manualOnly-selected }
```

### Sync mapper extension (round-trip + fallback)

```dart
// Modifications to transaction_sync_mapper.dart:

static Map<String, dynamic> toSyncMap(...) {
  return {
    // ... existing keys ...
    'entrySource': transaction.entrySource.name,  // ADD
    // ... existing keys ...
  };
}

static Transaction fromSyncMap(...) {
  return Transaction(
    // ... existing fields ...
    entrySource: EntrySource.values.byName(
      (data['entrySource'] as String?) ?? 'manual',  // D-09 fallback
    ),
    // ... existing fields ...
  );
}

// Test extension (transaction_sync_mapper_test.dart):
test('toSyncMap encodes entry_source', () {
  final map = TransactionSyncMapper.toSyncMap(
    sampleTransaction.copyWith(entrySource: EntrySource.voice),
    sourceBookId: 'book-1', sourceBookName: 'Main', sourceBookType: 'remote_book:book-1',
  );
  expect(map['entrySource'], 'voice');
});

test('fromSyncMap defaults missing entry_source to manual (D-09)', () {
  final map = TransactionSyncMapper.toSyncMap(sampleTransaction, ...);
  map.remove('entrySource');
  final restored = TransactionSyncMapper.fromSyncMap(map, ...);
  expect(restored.entrySource, EntrySource.manual);
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Heuristic-based "voice or manual?" via `voiceKeyword != null` proxy in `transaction_confirm_screen.dart:252-259` | Explicit `EntrySource` enum threaded via `CreateTransactionParams` | Phase 17 | Type-safe; new entry paths fail to compile until they declare their source |
| `soul_satisfaction` not in hash chain | `entry_source` also not in hash chain (D-02) | Phase 17 (extends Phase 9 precedent) | Hash chain remains v1.1 reverse-compatible; audit fields are observational only |
| Phase 13 D-09 note: "anticipate Phase 17 adds `entrySourceFilter` to recommendation use case" | OVERRIDDEN by Phase 17 D-15 | Phase 17 | Recommendation stays universal; toggle is AnalyticsScreen-only audit lens |

**Deprecated/outdated:**
- The `voiceKeyword != null` heuristic for voice detection in `transaction_confirm_screen.dart:252-262` is NOT deprecated by Phase 17 — that block records category-learning corrections from voice entries, which is independent of `entry_source` stamping. Both signals coexist.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `EntrySource.name` Dart enum string matches the SQL column's string values exactly (`'manual'`, `'voice'`, `'ocr'`) | Pattern 3 | LOW — Dart enum `.name` is a stable language feature; mismatch would be caught by the CHECK constraint at first insert |
| A2 | `customConstraints` table-level CHECK is NOT applied to existing rows by `migrator.addColumn` | Pitfall #1 | MEDIUM — verified by reading Drift source-of-truth docs (no explicit statement either way); the recommended workaround (column-level inline CHECK via `customStatement`) is robust regardless |
| A3 | `selectedJoyMetricVariantProvider` family-key invalidation works as auto-invalidation under Riverpod 3 | Pattern 2 / Pitfall #3 | LOW — Phase 15 D-12 `selectedTimeWindowProvider` ships with the same shape and works in production |
| A4 | The forbidden-substring widget test can be extended without locale-conditional allowlists | Pitfall: anti-toxicity test | MEDIUM — 'estimated' in `analyticsJoyMetricVariantManualOnlyExplain` may need an allowlist or a more specific forbidden phrase. Plan-phase must decide |
| A5 | No new entry path is added during Phase 17 itself (e.g., shortcut widget, sharing extension) | Push-site list | LOW — verified by grepping `MaterialPageRoute.*TransactionConfirmScreen` in lib/ (3 sites found) |
| A6 | `bill_sync_round_trip_test.dart` exists and can be extended to assert entry_source round-trip survival | Pattern: test infrastructure | LOW — file located at `test/integration/sync/bill_sync_round_trip_test.dart` (verified) |

## Open Questions (RESOLVED)

1. **ARB substring sweep handling of `estimated` (and Chinese `估算`)**
   - What we know: D-14 includes `estimated` in the en forbidden list when it's a value-judgment context, but the explanation ARB key may contain "voice-estimated entries" descriptively.
   - What's unclear: Whether the widget test should use phrase-level matching (e.g., forbid `less accurate` but allow `voice-estimated`) or accept the false-positive risk of substring matching.
   - Recommendation: Plan-phase produces final ARB wording FIRST, then the widget test team chooses test strategy. If `estimated` / `估算` appears in any final ARB string, replace it with a more specific forbidden phrase (e.g., `estimated · less` or skip `estimated` entirely and rely on the other 6 en substrings).
   - **RESOLVED:** Plan 07 Task 1 anchors the ARB wording (`Manual entries only · excludes voice-estimated entries`, `仅手动输入 · 不含语音估算条目`) — the bare `estimated` token is descriptive in the compound `voice-estimated` / `语音估算` and is intentionally omitted from the en forbidden list per Q1 recommendation. Plan 07 Task 5 (`anti_toxicity_phase17_test.dart`) encodes the resulting forbidden lists: en excludes bare `'estimated'`; zh forbids the compound `估算不准` but allows standalone `估算`.

2. **`analyticsRepositoryProvider` plumbing for new use-case parameter**
   - What we know: The repository interface `AnalyticsRepository` likely already mirrors DAO signatures. Adding `EntrySource? entrySourceFilter` cascades through interface → impl → use case → state provider.
   - What's unclear: Whether the repository interface should be re-emitted in this phase OR Phase 17 should add the parameter to ONLY the impl + use case (and the interface accepts the param via overload).
   - Recommendation: Add the parameter to the abstract `AnalyticsRepository` interface AND impl. Phase 16 added 4 new repo methods (per-category + soul-vs-survival × single + across-books) and this is the established pattern.
   - **RESOLVED:** Plan 05 Task 2 updates the abstract `AnalyticsRepository` interface AND the concrete `AnalyticsRepositoryImpl` in lockstep (both gain `EntrySource? entrySourceFilter` on every method mirroring a Plan 05 Task 1-modified DAO method). Acceptance criteria require ≥12 occurrences of `EntrySource? entrySourceFilter,` in the abstract interface and ≥12 occurrences of `entrySourceFilter: entrySourceFilter,` in the impl.

3. **Which AnalyticsScreen card-feeding state provider needs a family-key change?**
   - What we know: `monthlyReportProvider`, `happinessReportProvider`, `satisfactionDistributionProvider`, `bestJoyMomentProvider`, `largestMonthlyExpenseProvider`, `expenseTrendProvider`, `perCategorySoulBreakdownProvider`, `perCategorySoulBreakdownFamilyProvider`, `soulVsSurvivalSnapshotProvider`, `soulVsSurvivalSnapshotFamilyProvider`, `familyHappinessProvider` are all candidates per D-15.
   - What's unclear: `expenseTrendProvider` family key is currently `(bookId, anchor)` — adding `joyMetricVariant` makes 3-tuple, but D-15 says 6-month trend respects the variant filter.
   - Recommendation: Plan-phase verifies each provider's current family key, adds `joyMetricVariant` to it, and threads the value into the use case execute call. The exact list is 10-11 providers.
   - **RESOLVED:** Plan 07 Task 3 enumerates the family-key extensions across `state_happiness.dart`, `state_analytics.dart`, `state_ledger_snapshot.dart` (every AnalyticsScreen-feeding provider gains `required JoyMetricVariant joyMetricVariant`, including `expenseTrendProvider`). Plan 08 Task 1 wires the screen-level consumer-site invocations and `_refresh()` invalidations to pass the current variant. `monthlyJoyTargetRecommendationProvider` is the explicit negative exclusion (D-15) — Plan 07 Task 3 acceptance criteria verify the recommendation provider declaration is byte-identical pre/post.

## Environment Availability

> Phase 17 has no new external dependencies. All required tools are present from prior phases (Flutter SDK, Drift codegen, build_runner, gen_l10n). Skipped.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (bundled with Flutter SDK) + mocktail (mocking) |
| Config file | none — Flutter project convention |
| Quick run command | `flutter test test/unit/data/migrations/migration_v16_to_v17_test.dart -x` (single test file) |
| Full suite command | `flutter test --coverage` then `flutter test integration_test/` for integration tests |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HAPPY-V2-03 (SC-1 migration) | Schema v17 ALTER TABLE adds entry_source TEXT NOT NULL DEFAULT 'manual' CHECK(...) | unit (migration round-trip) | `flutter test test/unit/data/migrations/migration_v16_to_v17_test.dart` | ❌ Wave 0 — clone of migration_v15_to_v16_test.dart |
| HAPPY-V2-03 (SC-1 CHECK enforcement) | Inserting `entry_source='keyboard'` raises CHECK violation post-migration | unit (migration test) | same file | ❌ Wave 0 |
| HAPPY-V2-03 (SC-1 backfill) | Pre-existing row gets DEFAULT 'manual' after migration | unit (migration test, simulated via fresh row) | same file | ❌ Wave 0 — `AppDatabase.forTesting()` is fresh-schema; full simulated migration requires sqlite3 raw DB pattern from index_v15_migration_test.dart |
| HAPPY-V2-03 (SC-2 voice stamp) | Voice entry creates row with `entry_source='voice'` | unit (use case test) + integration | `flutter test test/unit/application/accounting/create_transaction_use_case_test.dart` (extend) + new integration | ❌ Wave 0 |
| HAPPY-V2-03 (SC-2 manual stamp) | Manual entry creates row with `entry_source='manual'` | unit + integration | same | ❌ Wave 0 |
| HAPPY-V2-03 (SC-3 toggle re-queries all cards) | When `selectedJoyMetricVariant = manualOnly`, every AnalyticsScreen card provider passes `entrySourceFilter = EntrySource.manual` to its use case | unit (per-use-case) + widget (chip flow) | `flutter test test/unit/application/analytics/` + widget tests | ❌ Wave 0 — extend each existing `*_test.dart` with 2 new test cases; new chip widget test |
| HAPPY-V2-03 (SC-4 HomeHero isolation) | HomeHero providers do NOT read `selectedJoyMetricVariantProvider`; HomeHero ring unaffected by toggle | widget (isolation) | `flutter test test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` (extend) | ✅ exists — extend |
| HAPPY-V2-03 (SC-5 ARB parity + no judgment copy) | All 5 keys exist in ja/zh/en; `flutter gen-l10n` clean; forbidden substrings absent in 3 locales | widget (anti-toxicity sweep) + CI gen-l10n | extend `anti_toxicity_phase16_test.dart` + run `flutter gen-l10n` | ✅ extend existing phase16 test file |
| HAPPY-V2-03 (D-03 sync round-trip) | `TransactionSyncMapper` round-trip preserves entry_source; absent field → 'manual' | unit | extend `transaction_sync_mapper_test.dart` | ✅ extend |
| HAPPY-V2-03 (D-03 cross-device) | `bill_sync_round_trip_test.dart` end-to-end carries entry_source | integration | extend `test/integration/sync/bill_sync_round_trip_test.dart` | ✅ extend |
| HAPPY-V2-03 (D-17 DAO filter clause) | Each AnalyticsDao method composes `AND entry_source = ?` when filter non-null | unit (DAO direct) | `flutter test test/unit/data/daos/analytics_dao_test.dart` (verify exists; if not, extend or fold into use-case tests) | ⚠️ verify presence — may need creation |
| HAPPY-V2-03 (D-15 negative scope) | `GetMonthlyJoyTargetRecommendationUseCase` does NOT accept `entrySourceFilter` | unit (assertive: parameter absent) + lint/grep gate | confirm no signature change; pin via constraint or test | ⚠️ negative-test pattern needed |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/<area>/` for the modified area (e.g., migration test for schema task, use-case test for use-case task)
- **Per wave merge:** `flutter test --coverage` (full unit + widget; coverage check ≥70% per file per REQUIREMENTS.md §5)
- **Phase gate:** `flutter test --coverage && flutter test integration_test/ && flutter analyze && flutter gen-l10n` all green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `test/unit/data/migrations/migration_v16_to_v17_test.dart` — covers HAPPY-V2-03 SC-1 (schema migration round-trip + CHECK enforcement + default backfill)
- [ ] Extension of `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` (rename to `anti_toxicity_phase17_test.dart` OR add parallel test cases) — covers HAPPY-V2-03 SC-5
- [ ] `test/widget/features/analytics/presentation/widgets/joy_metric_variant_chip_test.dart` — covers chip render + bottom sheet + setVariant flow
- [ ] Extension of `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — covers SC-4 HomeHero immunity to toggle
- [ ] Extension of each existing `test/unit/application/analytics/*_test.dart` — add 2 cases per file: `entrySourceFilter = null` (unchanged) and `entrySourceFilter = EntrySource.manual` (filtered)
- [ ] Extension of `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` — covers D-03 round-trip + D-09 fallback
- [ ] Extension of `test/integration/sync/bill_sync_round_trip_test.dart` — covers D-03 cross-device payload integrity
- [ ] (Optional) `test/integration/entry_path_stamping_test.dart` — covers SC-2 end-to-end voice/manual stamping (if not folded into use-case unit tests)
- [ ] No framework install needed — flutter_test + mocktail already in pubspec

## Security Domain

> `security_enforcement` is not explicitly disabled in `.planning/config.json`. Treating as enabled. Phase 17 surface is low-risk (read filter + audit field) but the migration touches user data and the sync payload touches cross-device contracts.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | No new auth surface |
| V3 Session Management | no | No new session surface |
| V4 Access Control | no | `entry_source` is per-row, no cross-user authorization |
| V5 Input Validation | yes | CHECK(entry_source IN (...)) at DB level + `EntrySource` enum at type-system level |
| V6 Cryptography | partial | Migration touches SQLCipher-encrypted DB. `entry_source` is NOT field-encrypted (consistent with `ledger_type`, `soul_satisfaction` — audit metadata is plaintext within the encrypted DB envelope). Hash chain unchanged (D-02). |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SQL injection via `entrySourceFilter` | Tampering | `Variable.withString(entrySourceFilter.name)` — parameter-bound, never string-interpolated. Pattern 3 above |
| Schema migration data loss (CHECK violation rejects DEFAULT row) | Denial of Service | CHECK constraint includes 'manual' which IS the DEFAULT value — no rejection possible. Verified by Pattern 1 |
| Sync payload tampering (peer sends `entry_source='admin'`) | Tampering | `EntrySource.values.byName(...)` throws on unknown values — rejected at deserialization. Receive side falls back to 'manual' only for ABSENT field (D-09), not invalid values |
| Forbidden judgment copy leaks ("voice is less accurate") | Repudiation / brand harm | Anti-toxicity widget test extension (D-14) blocks at CI |
| Hash chain forgery via `entry_source` mutation | Tampering | Out of scope — `entry_source` is NOT hash-protected (D-02, audit-only). Accepted tradeoff |
| HomeHero contract violation (toggle bleeds into ring) | Integrity | `home_screen_isolation_test.dart` extension asserts ring unchanged across toggle states |

## Sources

### Primary (HIGH confidence)

- `lib/data/tables/transactions_table.dart` — Drift table shape, current `customConstraints` pattern
- `lib/data/app_database.dart` — migration block pattern, schemaVersion lifecycle, precedent for `migrator.addColumn`
- `lib/data/daos/analytics_dao.dart` — all 12+ methods that need the new filter parameter; `_soulExpenseFilter` / `_survivalExpenseFilter` constants
- `lib/data/daos/transaction_dao.dart` — `insertTransaction` parameter shape
- `lib/features/accounting/domain/models/transaction.dart` — Freezed `Transaction` model
- `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — sync payload encode/decode pattern + fallback semantics (`soulSatisfaction` precedent)
- `lib/application/accounting/create_transaction_use_case.dart` — `CreateTransactionParams` shape; hash chain calculation
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — push-site receiving end; lines 29-44 constructor, line 300 use-case call
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:340-365` — voice push site
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:215-234` — manual push site
- `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` — VERIFIED STUB (no push site; shutter is Navigator.pop)
- `lib/application/analytics/demo_data_service.dart` — `insertTransaction` calls on lines 103, 137
- `lib/features/analytics/presentation/providers/state_time_window.dart` — Riverpod 3 `@riverpod` notifier template
- `lib/features/analytics/presentation/widgets/time_window_chip.dart` — chip + bottom sheet template
- `lib/features/analytics/presentation/screens/analytics_screen.dart` — AppBar.actions placement (line 69-74), `_refresh()` invalidation pattern (line 200-284)
- `lib/features/analytics/presentation/providers/state_happiness.dart` / `state_analytics.dart` / `state_ledger_snapshot.dart` — provider family-key patterns
- `lib/application/analytics/get_happiness_report_use_case.dart` / `get_per_category_soul_breakdown_use_case.dart` — use-case execute signature shape
- `lib/l10n/app_en.arb` (lines 1697-1786) — `analyticsTimeWindow*` keys = direct precedent for `analyticsJoyMetricVariant*` keys
- `test/unit/data/migrations/migration_v15_to_v16_test.dart` — migration round-trip test template
- `test/unit/data/migrations/index_v15_migration_test.dart` — raw sqlite3 migration pattern for backfill-on-existing-row simulation
- `test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart` — forbidden-substring sweep template
- `test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` — HomeHero isolation test template
- `test/unit/features/accounting/domain/models/transaction_sync_mapper_test.dart` — sync mapper round-trip test pattern (already covers `soulSatisfaction` fallback at line 81-96 — direct precedent for `entry_source` fallback)
- `test/integration/sync/bill_sync_round_trip_test.dart` (line 197) — integration test where TransactionSyncMapper.toCreateOperation is exercised end-to-end
- `.planning/config.json` — verified `workflow.nyquist_validation = true` (Validation Architecture section required)

### Secondary (MEDIUM confidence)

- `sqlite.org/lang_altertable.html` (verified via WebFetch) — ALTER TABLE ADD COLUMN can include both DEFAULT and column-level CHECK in same statement
- Drift docs `drift.simonbinder.eu/migrations/api/` (verified via WebFetch) — migrator API; ambiguous on customConstraints behavior in addColumn — drove the recommendation to use `customStatement` instead of `migrator.addColumn`
- CLAUDE.md project rules — Riverpod 3 import boundary table; intl 0.20.2 pin; sqlcipher_flutter_libs ^0.6.x pin; common pitfalls #1-13

### Tertiary (LOW confidence)

- General Drift + Flutter community search results on `addColumn` + `customConstraints` — no authoritative source contradicts the recommendation to use `customStatement` for inline CHECK on existing rows. Flagged for validation: a Drift maintainer could clarify the actual behavior in a future version, but the chosen approach is robust regardless.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — zero new packages, all libraries in active use, versions pinned by Phase 16
- Architecture: HIGH — direct templates exist for every new artifact (notifier, chip, migration test, anti-toxicity test, sync mapper extension)
- Pitfalls: HIGH — migration semantics verified against SQLite docs; OCR stub confirmed by reading the source; Riverpod 3 family-key invalidation behavior verified by Phase 15 D-12 precedent

**Research date:** 2026-05-20
**Valid until:** 2026-06-20 (30 days; underlying stack is stable through v1.2)
