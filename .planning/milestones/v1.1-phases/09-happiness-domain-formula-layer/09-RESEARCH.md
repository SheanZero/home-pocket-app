# Phase 9: Happiness Domain & Formula Layer — Research

**Researched:** 2026-05-01
**Domain:** Happiness/wellbeing metric domain layer over an existing Drift+SQLCipher Flutter analytics module
**Confidence:** HIGH (every architectural claim grounded in source reads at verified line numbers; CONTEXT.md decisions D-01..D-23 are LOCKED and quoted verbatim from the user)

---

## User Constraints (from CONTEXT.md)

> Source of truth: `.planning/phases/09-happiness-domain-formula-layer/09-CONTEXT.md`
> All 23 decisions D-01..D-23 are LOCKED. Research operates inside them, not around them.

### Locked Decisions (excerpt — full text in CONTEXT.md)

- **D-01**: `_soulOnly()` SQL fragment is non-filtering on satisfaction. Filters only `WHERE ledger_type='soul' AND type='expense' AND is_deleted=0`. No backdoor.
- **D-02**: Schema bump v15 → v16. `transactions_table.dart:35` `Constant(5)` → `Constant(2)`. CHECK `BETWEEN 1 AND 10` stays. No backfill (pre-launch).
- **D-03**: HAPPY-01 = `AVG(soul_satisfaction)` over month-to-date. No PTVF scaling.
- **D-04**: HAPPY-02 PTVF α=0.88, base by currency (JPY=500 / CNY=25 / USD=5 / fallback=500), Dart-layer fold. DAO returns row-wise `(amount, soul_satisfaction)`. Performance trade-off accepted; document in ADR.
- **D-05**: HAPPY-03 threshold sat ≥ 6 (was ≥8). Spec amendment.
- **D-06**: HAPPY-04 = pure sat sort, NO ¥500 floor. `ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1`. Spec amendment.
- **D-07**: FAMILY-01 threshold sat ≥ 6. Returns `int` only — `Map<MemberId,int>` is forbidden by contract. Spec amendment.
- **D-08**: FAMILY-02 = category argmax with min-N=3 guard. Returns `(categoryId, avgSatisfaction, totalCount)` only — no per-member fields.
- **D-09**: Family use cases reuse `shadowBooksProvider`. Use case takes `groupBookIds: List<String>` parameter.
- **D-10**: Default 5 → 2 schema migration encodes "every soul tx is happy at least at neutral level."
- **D-11**: Phase 12 expands scope to rename 5 emoji ARB labels + picker icons (NOT Phase 9 work).
- **D-12**: Voice estimator output range realignment deferred to v1.2.
- **D-13**: Sealed `MetricResult<T>` with two variants `Empty<T>` (`const Empty()`) and `Value<T>` (`data, sampleSize`). No `thinSample` variant.
- **D-14**: Single Empty (no subtypes / no reason enum). UI distinguishes "no soul tx" vs "min-N not met" by reading aux fields `totalSoulTx` / `totalGroupSoulTx`.
- **D-15**: Mixed packaging: main metrics MetricResult-wrapped, aux metadata flat. `HappinessReport` and `FamilyHappiness` Freezed shapes locked verbatim in CONTEXT.md lines 99–129.
- **D-16**: Empty-trigger alignment table locked: all personal metrics co-empty under `totalSoulTx=0`; FAMILY-02 has additional "no category meets min-N" trigger.
- **D-17**: HAPPY-04 contract is simple — no extra Phase 9 logic for "all neutral" case. Phase 10 UI inspects `topJoy.data.soulSatisfaction <= 2` and renders CTA.
- **D-18**: HAPPY-09 REMOVED from v1.1 → folded into HAPPY-V2-03. v1.1 REQ count 26 → 25.
- **D-19**: Joy/¥ stored as raw double; no display normalization in the model.
- **D-20**: New helper `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` co-locates PTVF base AND display unit maps.
- **D-21**: Headline-tile selection deferred to Phase 10. Phase 9 ships 4 personal tiles equally.
- **D-22**: Three new ADRs in Phase 9 (No Gamification v1.1; Joy Density PTVF Scaling; Soul Satisfaction Unipolar Positive Scale). Planner picks numbers — current max ADR-011 → expect 012, 013, 014.
- **D-23**: Phase 12 drafts a fourth ADR — Lexical Hierarchy v1.1 (out of Phase 9 scope; will be ADR-015).

### Claude's Discretion (planner decides)

- DAO method naming, file split strategy, build_runner ordering — follow `get_monthly_report_use_case.dart` template precisely.
- ADR numbering — read `docs/arch/03-adr/ADR-*.md`, pick next sequential (012, 013, 014; Phase 12 → 015).
- Test fixture strategy (hand-built / demo_data_service-derived / new test_doubles).
- Median computation strategy — recommend reusing `getSatisfactionDistribution` data and computing in Dart (see Q2 below for full analysis).

### Deferred Ideas (OUT OF SCOPE for Phase 9)

- Phase 10 work: HomePage `SoulFullnessCard` rebuild, CTA pattern detection, `_compute*` helper deletion.
- Phase 11 work: AnalyticsScreen `JoyLedgerStatisticsSection`, Joy/¥ trend line, satisfaction histogram, median tooltip.
- Phase 12 work: 5 emoji ARB rename + picker Material icon update + ADR-XXX_Lexical_Hierarchy.
- v2/post-launch: HAPPY-V2-03 (manual-only sub-metric + entry_source column), voice estimator output realignment, voice-bias regression test, HAPPY-V2-01/-02, STATSUI-V2-01, FAMILY-V2-01/-02, TOOL-V2-01/-02, EUR/GBP/KRW PTVF base extension, PTVF α tuning, unrated/Neutral distinction mechanism, median DAO-side optimization.
- **Forbidden anti-features (permanent):** Per-member breakdown surfaces (leaderboards), streaks/badges/daily targets, cross-period delta on home tile, public sharing of happiness metrics.

---

## Project Constraints (from CLAUDE.md)

These are **CI-enforced** or project-policy directives that the planner MUST honor:

- **Thin Feature rule** — Features NEVER contain `application/`, `infrastructure/`, `data/tables/`, or `data/daos/`. Enforced by `import_guard` (`lib/features/import_guard.yaml`). [VERIFIED: `lib/features/import_guard.yaml:4-8`]
- **Domain layer purity** — `features/analytics/domain/` denies imports from `data/`, `infrastructure/`, `application/`, other features' `presentation/`, and `package:flutter/**`. [VERIFIED: `lib/features/analytics/domain/import_guard.yaml:7-12`]
- **One `repository_providers.dart` per feature/domain** — single source of truth; never duplicate provider definitions. Use case providers go in `lib/application/analytics/repository_providers.dart`.
- **Drift `TableIndex` syntax** — use `TableIndex(name:..., columns: {#col})` with Symbol syntax; no `Index()` constructor, no `@override`. Already correct in `transactions_table.dart:45-52`.
- **Riverpod conventions** — `@riverpod` codegen; provider naming `state_<aggregate>.dart`; no `UnimplementedError` providers; no duplicate definitions (CI-enforced via `arch test provider_graph_hygiene_test.dart` + `riverpod_lint`).
- **Crypto rules** — All crypto ops via `lib/infrastructure/crypto/`. **NOT TRIGGERED in Phase 9** — DAO query reads only non-encrypted columns; argmax does NOT return `note`.
- **i18n rules** — All UI text via `S.of(context)`; ARB key parity locked across ja/zh/en. **NOT TRIGGERED in Phase 9** — no ARB file edits in this phase (Phase 12 owns rename pass).
- **Code quality gates** — `flutter analyze` 0 issues; `dart run custom_lint --no-fatal-infos` 0 errors; per-file coverage ≥70% with `--deferred` mechanism; `build_runner` clean-diff; `sqlite3_flutter_libs` rejection.
- **`intl` is pinned at 0.20.2** — do NOT bump. Locked by flutter_localizations.

---

## Phase Summary

Phase 9 is the **linchpin** of milestone v1.1 — it locks formulas, contracts, and anti-gamification defenses for happiness metrics so Phases 10/11/12 build on stable ground. The work decomposes into seven concurrent slices: (1) schema migration v15→v16 (single-line default change + empty `onUpgrade` body); (2) sealed `MetricResult<T>` plus three new Freezed aggregates (`HappinessReport`, `FamilyHappiness`, `BestJoyMomentRow`, `SharedJoyInsight`); (3) one new DAO method `getBestJoyMoment` + a row-wise `(amount, soul_satisfaction)` query for PTVF Dart-layer fold + a centralized `_soulOnly()` SQL fragment exposed as a `static const String`; (4) repository surface extension (4 new method signatures on `AnalyticsRepository`); (5) three use cases that mirror `GetMonthlyReportUseCase` precisely (`GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase`); (6) a new `joy_density_formatter.dart` helper co-locating PTVF base + display unit maps; (7) three new ADRs ratifying the no-gamification posture, PTVF scaling rationale, and unipolar positive scale philosophy. Eleven REQs are addressed (HAPPY-01..08, FAMILY-01..02, plus HAPPY-09 satisfied via formal removal-as-spec-amendment per D-18).

The project already has direct precedent for every pattern this phase needs: `GetMonthlyReportUseCase` is the use case template; `analytics_dao.dart` lines 230–327 hold three dormant DAO methods of the right shape; sealed-class + Freezed coexist (`auth_result.dart:11`, `init_result.dart:9`); `closeTo` matcher is the project's idiom for floating-point assertions (`get_monthly_report_use_case_test.dart:128`); `shadowBooksProvider` is wired and ready for D-09 reuse. The principal novelty is `MetricResult<T>` as a generic sealed type — the project has no prior generic sealed class, but D-13 specifies it as a **plain** sealed class (NOT `@freezed`), which sidesteps Freezed's known generic-type limitations.

**Primary recommendation:** Sequence the build as Wave 0 (test infra) → Wave 1 (schema migration + domain models, parallelizable) → Wave 2 (DAO + repository extension) → Wave 3 (use cases + provider wiring) → Wave 4 (formatter helper + tests) → Wave 5 (3 ADRs) → Wave 6 (spec amendments to REQUIREMENTS.md / ROADMAP.md). Run `build_runner` between every wave that touches `@freezed`/`@riverpod` annotations.

---

## Phase Requirements

| ID | Description (post-amendment) | Research Support |
|----|------------------------------|------------------|
| HAPPY-01 | Avg Satisfaction = `AVG(soul_satisfaction)` over MTD soul-expense rows, scoped by `bookId`. No PTVF scaling. | Q1 (DAO method `getSoulSatisfactionOverview` already exists at `analytics_dao.dart:230-259`, returns `SatisfactionOverviewResult{avgSatisfaction, count}`). |
| HAPPY-02 | Joy/¥ density = `Σ (sat × (amount/base)^0.88) / Σ amount`, base by currency (JPY=500 / CNY=25 / USD=5 / fallback=500), computed in Dart layer. | Q1 (new row-wise DAO method needed); Q5 (test fixtures). |
| HAPPY-03 | Highlights count = count of soul tx with `sat ≥ 6` MTD. (was ≥8 — D-05 spec amendment.) | Q1 (derive from `getSatisfactionDistribution` already at `analytics_dao.dart:262-292`). |
| HAPPY-04 | Top Joy = pure sat-sort argmax (`ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1`). | Q1 (NEW DAO method `getBestJoyMoment` — only genuinely new query). |
| HAPPY-05 | Centralized `_soulOnly()` SQL fragment composed by every soul aggregator. Filters `ledger_type='soul' AND type='expense' AND is_deleted=0` only — no satisfaction filter (D-01). | Q1 (recommend `static const String` on `AnalyticsDao`). |
| HAPPY-06 | Sealed `MetricResult<T>` with `Empty<T>` / `Value<T>` variants. UI never sees NaN/infinity/0%. | Q3 (sealed-class precedent verified; non-Freezed sealed type sidesteps generic Freezed limitations). |
| HAPPY-07 | ADR `No Gamification v1.1` ratifies "no streaks / badges / daily targets / cross-period comparisons / public sharing". Goodhart's Law defense. Binding through milestone close. | Q8 (ADR-012 expected). |
| HAPPY-08 | 5-emoji ↔ 1-10 mapping pinned by unit tests under new unipolar positive semantic (REQUIREMENTS.md amendment includes the mapping table). | Q9 (REQUIREMENTS.md amendment task). Note: emoji ARB *labels* renamed in Phase 12 (D-11), but the *mapping numbers* are pinned in Phase 9 tests. |
| HAPPY-09 | **REMOVED from v1.1 (D-18).** Coverage = the spec amendment task itself. Folded into HAPPY-V2-03. | Q9 (REQUIREMENTS.md amendment removes HAPPY-09; updates HAPPY-V2-03 dependency note). |
| FAMILY-01 | Family Highlights Sum = aggregate count of `sat ≥ 6` across all family shadow books MTD. Returns `int` only (NEVER `Map<MemberId,int>`). | Q1 (Dart-layer fold over `getSoulSatisfactionOverview` results from each shadow book); Q12 (forbidden patterns audit). |
| FAMILY-02 | Shared Joy Insight = category argmax with min-N=3 guard. Returns `(categoryId, avgSatisfaction, totalCount)` only — type-system enforced anti-leaderboard. | Q1 (new DAO method needed — `getSharedJoyCategoryInsight`); Q12. |

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Soul-satisfaction column default | Database / Storage | — | Schema-level; one-line change in `transactions_table.dart`. |
| `_soulOnly()` SQL fragment | Database / Storage (DAO) | — | Centralizes filter at the lowest layer that owns SQL composition. |
| Argmax query (HAPPY-04) | Database / Storage (DAO) | — | SQL `ORDER BY ... LIMIT 1` is the only non-decoder path that doesn't pull every row through the encryption layer. |
| Row-wise PTVF-input query | Database / Storage (DAO) | Application (use case) | DAO returns rows; application folds via `(amount/base)^0.88`. SQLite has no `POW`/`EXP` standard functions (D-04). |
| PTVF α=0.88 constant | Application (use case) | Infrastructure (formatter) | Use case owns math; formatter co-locates display constants and base-by-currency map. |
| Median computation | Application (use case) | Database / Storage | Reuses `getSatisfactionDistribution` data; Dart-layer fold (D-claude-discretion recommendation). |
| `MetricResult<T>` envelope | Domain | Application | Domain owns the contract; application emits the variants. |
| Empty/Value alignment table (D-16) | Application (use case) | Domain | Use cases enforce trigger consistency; domain types provide the sealed scaffold. |
| `HappinessReport` / `FamilyHappiness` Freezed | Domain | — | Pure data containers; cross-feature import target for HomePage (Phase 10) and AnalyticsScreen (Phase 11). |
| Use case provider wiring | Application | Presentation (consumer) | Single `repository_providers.dart` per CLAUDE.md rule; `state_happiness.dart` consumes via `ref.watch`. |
| `shadowBooksProvider` resolution (D-09) | Presentation | Application (use case) | Presentation resolves the list, passes to use case; use case stays free of provider knowledge. |
| Joy/¥ display formatting (D-20) | Infrastructure (i18n formatters) | Presentation | Joins `NumberFormatter` / `DateFormatter` precedent at `lib/infrastructure/i18n/formatters/`. |
| 3 ADRs | Documentation (`docs/arch/03-adr/`) | — | ADR-012/013/014; numbering verified — `ls /Users/xinz/Development/home-pocket-app/docs/arch/03-adr/` confirms ADR-011 is current max. |
| Spec amendments (REQUIREMENTS.md / ROADMAP.md) | Documentation (`.planning/`) | — | In-phase deliverables per D-22. |

**Why this matters:** Phase 9 is pure backend / contract work — there is no Browser tier, no Frontend Server tier, no API/HTTP boundary. The relevant tiers map to Clean Architecture layers: DB schema → DAO → repository → domain → use case → provider. Misassignment risks: putting PTVF math in DAO (impossible without `POW`/`EXP`); putting `_soulOnly()` in use cases (defeats centralization); putting ADRs in `.planning/` instead of `docs/arch/03-adr/` (project convention violation).

---

## Research Findings

### Q1. DAO method placement & shape

**Q1a. `getBestJoyMoment` placement.** [VERIFIED]

Place in `lib/data/daos/analytics_dao.dart` as a new method following the convention at lines 230–327 (the existing soul-satisfaction query family). Do NOT split into a new DAO — three of four soul-satisfaction queries already live here (`getSoulSatisfactionOverview:230-259`, `getSatisfactionDistribution:262-292`, `getDailySatisfactionTrend:295-327`); cohesion principle dictates the fourth member of the family lives alongside.

**Recommended signature** (mirrors the project pattern at `analytics_dao.dart:230-259`):

```dart
// Returns null when no soul tx exists in the window.
Future<BestJoyMomentDaoResult?> getBestJoyMoment({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db.customSelect(
    'SELECT id, amount, soul_satisfaction, category_id, timestamp '
    'FROM transactions '
    'WHERE book_id = ? AND ledger_type = \'soul\' AND type = \'expense\' '
    'AND is_deleted = 0 '
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

**Encryption note** [VERIFIED via ARCHITECTURE.md and CONTEXT.md canonical_refs]: `note` column is field-encrypted via `FieldEncryptionService`, applied transparently in `TransactionRepositoryImpl`. The DAO query deliberately omits `note` to avoid decrypt churn (Phase 10 UI doesn't need note text in the story card). If a future need surfaces, call `TransactionRepository.findById(rowId)` from a downstream use case as a second step — the project's existing pattern.

**Q1b. `_soulOnly()` SQL fragment shape.** [VERIFIED]

Recommend a `static const String` on `AnalyticsDao`:

```dart
class AnalyticsDao {
  // D-01: Filters ledger and lifecycle ONLY. NO satisfaction filter.
  static const String _soulExpenseFilter =
      "ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0";
  // ... existing queries refactored to compose via:
  // 'WHERE book_id = ? AND $_soulExpenseFilter AND timestamp >= ? ...'
}
```

**Why a const string, not a Drift `Trigger` or SQL `VIEW`:**
- The project's existing DAO uses raw `customSelect` with hand-written SQL strings (verified at lines 99, 138, 174, 207, 237, 269, 302). Composing via Dart string interpolation is the established idiom.
- Drift VIEWs require a schema migration entry and bind to schema version; would require a v17 bump if added later. Sidesteppable.
- Drift Triggers are for write-side cascading, irrelevant for read filters.
- A const string is grep-able (`rg "_soulExpenseFilter"` finds all consumers); a VIEW is opaque to grep.

**Reuse sites (4+):** `getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`, `getBestJoyMoment`, the new row-wise PTVF query, the new `getSharedJoyCategoryInsight`. Refactoring the three existing queries to compose from the const is a no-op for query plans (string equivalence) but pays the centralization dividend — single edit point if ledger semantics ever extend.

**Q1c. PTVF row-wise query.** [VERIFIED]

The current DAO does NOT have a row-wise `(amount, soul_satisfaction)` returning method — every existing query aggregates with `AVG` / `SUM` / `COUNT` / `GROUP BY`. A new method is required. Recommended signature:

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
    variables: [/* ... */],
  ).get();
  return results.map((r) => SoulRowAmountSat(
    amount: r.read<int>('amount'),
    soulSatisfaction: r.read<int>('soul_satisfaction'),
  )).toList();
}

class SoulRowAmountSat {
  final int amount;
  final int soulSatisfaction;
  const SoulRowAmountSat({required this.amount, required this.soulSatisfaction});
}
```

**Performance note** [CITED: D-04]: This violates the v1.0 "<2s SUM/GROUP BY performance" principle (`analytics_dao.dart:85`). With monthly soul tx counts of 10–100 per book (per CONTEXT.md `<specifics>`), the row count is negligible. Document the trade-off in ADR-013 (Joy Density PTVF Scaling) per D-22.2.

---

### Q2. Median computation strategy

[VERIFIED via reading `analytics_dao.dart:262-292`]

Three options:

| Option | Approach | Cost | Recommendation |
|--------|----------|------|----------------|
| A | Reuse `getSatisfactionDistribution` (count-keyed map of score→count); compute median in Dart by walking the cumulative distribution. | Zero new DAO method. ~10 lines of Dart. | ✅ **Recommended.** |
| B | New SQL median (SQLite has no built-in `MEDIAN`; would require `WITH cte AS (... ROW_NUMBER() ...) SELECT ... LIMIT/OFFSET`). | New DAO method, complex SQL, untested in project. | ❌ Reject. |
| C | Dart-layer median over the row-wise PTVF query (`getSoulRowsForPtvf`). | Reuses an already-needed query, but pulls more rows than needed if HAPPY-02 is empty (e.g., if shape becomes lazy). | ⚠️ Acceptable fallback. |

**Why Option A:** `getSatisfactionDistribution` is already dormant-and-ready (returns `[(score, count), ...]` ordered ASC by score per `analytics_dao.dart:275`). Median over a count-keyed distribution is a textbook walk:

```dart
double computeMedianFromDistribution(List<SatisfactionDistribution> dist) {
  final total = dist.fold<int>(0, (s, d) => s + d.count);
  if (total == 0) return 0;
  final midIndex = total ~/ 2;
  final isEven = total % 2 == 0;
  int cumulative = 0;
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
```

The implementation belongs in `GetHappinessReportUseCase` (private helper) and `GetFamilyHappinessUseCase` (group-level). Test coverage piggybacks on the use case tests.

---

### Q3. Sealed `MetricResult<T>` ergonomics

**Q3a. Sealed-class precedent in project.** [VERIFIED]

Sealed classes are well-established:
- `lib/core/initialization/init_result.dart:9` — `@freezed sealed class InitResult with _$InitResult` (with `InitSuccess` / `InitFailure` factory variants).
- `lib/infrastructure/security/models/auth_result.dart:11` — same pattern, 6 variants.
- `lib/infrastructure/security/models/audit_log_entry.dart:48` — `@freezed sealed class AuditLogEntry with _$AuditLogEntry`.
- `lib/application/family_sync/*_use_case.dart` — at least 14 plain `sealed class` declarations (e.g., `check_group_use_case.dart:10` `sealed class CheckGroupResult`).

**Two coexisting patterns:**
1. **`@freezed sealed class`** — for value types with `copyWith` / json serialization. Used in `init_result.dart`, `auth_result.dart`, `audit_log_entry.dart`. Requires Freezed 3.x (verified in `pubspec.yaml:81` `freezed: ^3.0.0`).
2. **Plain `sealed class` with `extends`** — for simple union types. Used throughout `application/family_sync/`. NO codegen needed; pattern-matched via `switch` exhaustiveness.

**Recommendation for `MetricResult<T>`:** Use **plain sealed class** (Pattern 2). [VERIFIED]

```dart
// lib/features/analytics/domain/models/metric_result.dart
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

**Why plain over `@freezed sealed`:**
- D-13 specifies the exact shape — Freezed's machinery (json serialization, deep `copyWith`) is unused.
- **Generic types + Freezed have known limitations** — Freezed 3.x supports generics on union types but the codegen quirks for unconstrained type parameters add risk and the project has zero precedent for `@freezed` on a generic type.
- Plain sealed is sufficient: `switch (result) { case Empty(): ... case Value(:final data, :final sampleSize): ... }` is the consumption pattern (already used heavily in `lib/application/family_sync/`).

**Q3b. Freezed model with `MetricResult<double>` field.** [VERIFIED]

`HappinessReport` per D-15 holds `MetricResult<double> avgSatisfaction` etc. Freezed 3.x's `copyWith` handles non-Freezed field types as opaque values (doesn't deep-copy them) — this is correct behavior because `MetricResult` instances are themselves immutable. The generated `==` on `_$HappinessReport` will compare `MetricResult` references with the default `==` on `Object`. **This is acceptable** because each use-case execution constructs a fresh `MetricResult`, and Riverpod's `AsyncValue<HappinessReport>` cache is keyed by use-case input parameters, not by structural equality. If structural comparison becomes needed (e.g., for widget memoization), override `==` and `hashCode` on `Empty` and `Value` — straightforward.

**json_serializable concern:** D-15 model definitions show `@freezed class HappinessReport with _$HappinessReport` — without a `fromJson` factory there is no json_serializable wiring needed. Recommend NOT generating `fromJson` for these aggregates (they're transient query results, not persisted). Compare to `MonthlyReport` which DOES have `fromJson` (`monthly_report.dart:45`) — this is unused dead-weight that the planner can choose to omit for the new aggregates. **Decision flagged for planner.**

---

### Q4. Schema migration v15 → v16

**Q4a. Project migration idiom.** [VERIFIED via `lib/data/app_database.dart:48-264`]

`MigrationStrategy.onUpgrade` is a single `(migrator, from, to) async { ... }` block with `if (from < N)` chains. Each version step does its work and falls through. No `onCreate` is overridden (inherited from `_$AppDatabase`).

**Schema version constant** lives at exactly **one place**: `app_database.dart:45` `int get schemaVersion => 15;`. Bump to `16`.

**Q4b. Migration body.** [VERIFIED]

Per D-02: "**No data backfill** required — project is pre-launch with no real user data." For a column-default change with no ALTER, the migration body is essentially empty:

```dart
if (from < 16) {
  // v16: transactions.soul_satisfaction default 5 → 2 (D-02 / D-10).
  // Schema-level default change — no DDL needed because Drift expresses the
  // default in companion class, not as a SQL DEFAULT constraint.
  // No backfill: pre-launch state, no real user data exists.
  // CHECK(soul_satisfaction BETWEEN 1 AND 10) survives unchanged.
}
```

**Important nuance** [VERIFIED via `transactions_table.dart:35`]: Drift's `withDefault(const Constant(5))` is enforced at the **Companion class** layer (Dart side), not as a SQL `DEFAULT` constraint. Existing rows are not affected by changing the value in the table definition; only NEW inserts that omit `soulSatisfaction` will see the new default. This makes the migration genuinely empty.

**Verification check for the migration:** A regression test should confirm post-migration `INSERT INTO transactions (..., /* omit soul_satisfaction */)` writes value `2`, not `5`. The test must use a fresh `AppDatabase.forTesting()` (which is in-memory and exercises `onCreate` → schema v16 directly, not `onUpgrade`).

**Q4c. CHECK constraint survival.** [VERIFIED via `transactions_table.dart:41-43`]

The CHECK constraint `customConstraints: ['CHECK(soul_satisfaction BETWEEN 1 AND 10)']` survives the default change. New default `2` is in the valid range. ✓

**Q4d. `demo_data_service.dart` audit.** [VERIFIED via `lib/application/analytics/demo_data_service.dart:130-135`]

Two `sat=5` rows exist:

```dart
// demo_data_service.dart:131-134
final satisfaction = ledgerType == 'soul'
    ? 1 + _random.nextInt(10) // 1..10
    : 5;
```

The `ledgerType == 'survival' ? 5 : <random>` branch should update to `2` for consistency with the new default semantic ("every soul tx is happy at neutral level; survival baseline is also neutral-by-default"). **Action item for planner:** include a one-line edit in the schema-migration plan unit to change `: 5;` → `: 2;` at `demo_data_service.dart:134`.

**Other `sat=5` references** [VERIFIED via grep]: `lib/data/daos/transaction_dao.dart:29` `int soulSatisfaction = 5,` and `:133` (same pattern in `updateTransaction` overload). These are Dart-layer parameter defaults that mirror the table default. **Should also update to `2`** for semantic consistency. Three lines total: `transactions_table.dart:35`, `transaction_dao.dart:29`, `transaction_dao.dart:133`. Plus `transaction.dart:42` `@Default(5) int soulSatisfaction,` (the Freezed model). Four total.

**Action item:** the schema migration plan unit must edit all four sites in lockstep, or downstream insert paths will silently default to `5` even after the migration.

---

### Q5. PTVF Joy/¥ test fixture coverage

**Q5a. Required test cases** [DERIVED from D-04, D-13, D-16]:

| # | Case | Expected output |
|---|------|----------------|
| 1 | `n=0` (empty soul ledger MTD) | `joyPerYen = MetricResult.empty()` |
| 2 | `n=1`, single soul tx ¥3000, sat=8 | `Value(density, sampleSize=1)` where density = `8 × (3000/500)^0.88 / 3000` ≈ `8 × 5.014 / 3000` ≈ `0.01337` |
| 3 | `n=2`, mixed sat / mixed amount | Numerically computed, asserted via `closeTo` |
| 4 | All default `sat=2` (post-migration) | Density computes; not zero; not NaN |
| 5 | All `sat=10` mixed amount | Density highest, dominated by high-amount rows due to PTVF |
| 6 | Multi-currency (JPY base 500, CNY 25, USD 5) | Same `(amount, sat)` shape with different `Book.currency` values produces different densities matching the base lookup |
| 7 | Currency fallback (e.g., EUR not in map) | Falls back to base=500 (JPY); test asserts no exception |
| 8 | Survival contamination guard | Fixture with 2 survival rows + 2 soul rows; assert survival rows don't enter `Σ`. |
| 9 | `is_deleted=1` exclusion | Fixture with 1 deleted soul row; assert excluded. |
| 10 | Multi-book isolation | Two `book_id`s; assert `bookId` filter works. |

**Q5b. Multi-currency fixture mechanics.** [VERIFIED via `books_table.dart:8`]

`Book.currency` is a 3-char ISO column. Multi-currency tests need:
1. Insert a book with `currency = 'CNY'` (existing book test fixtures already do this — see `test/unit/application/analytics/get_monthly_report_use_case_test.dart` for book-fixture patterns).
2. Insert soul tx into that book.
3. Pass `currencyCode: 'CNY'` to `GetHappinessReportUseCase.execute()` (per D-04 the use case takes `currencyCode: String`).

**Multi-currency tests are easy** because `AppDatabase.forTesting()` (in-memory) plus existing book/transaction insertion DAOs cover all the seeding. No extra fixtures needed.

**Q5c. Floating-point assertions.** [VERIFIED via `test/unit/application/analytics/get_monthly_report_use_case_test.dart:128,251`]

The project idiom is `expect(value, closeTo(expected, tolerance))`:
- Already used at `get_monthly_report_use_case_test.dart:128` `expect(report.savingsRate, closeTo(73.3, 0.1));`
- Used in `voice/levenshtein_test.dart:65,70` for similarity scores.

**Recommended tolerance for PTVF tests:** `0.0001` (4 significant figures) — tighter than `0.1` because PTVF density values are typically `10^-3` to `10^-2` magnitude, so `0.1` would be useless.

---

### Q6. `shadowBooksProvider` integration (D-09)

**Q6a. Provider shape.** [VERIFIED via `lib/features/home/presentation/providers/state_shadow_books.dart:25-43`]

```dart
@riverpod
Future<List<ShadowBookInfo>> shadowBooks(Ref ref) async { ... }
```

Returns `Future<List<ShadowBookInfo>>` where `ShadowBookInfo` carries `(book, memberDisplayName, memberAvatarEmoji)`. **NOT just book IDs** — it's a richer struct.

**Adapter pattern in `state_happiness.dart`** (the new presentation provider):

```dart
@riverpod
Future<FamilyHappiness> familyHappiness(Ref ref, {required int year, required int month}) async {
  final groupId = ref.watch(activeGroupProvider).valueOrNull?.groupId;
  if (groupId == null) {
    // Short-circuit: no active group → empty FamilyHappiness with totalGroupSoulTx=0.
    return FamilyHappiness(year: year, month: month, totalGroupSoulTx: 0,
      familyHighlightsSum: const Empty(), sharedJoyInsight: const Empty(),
      medianSatisfaction: const Empty());
  }
  final shadowBooks = await ref.watch(shadowBooksProvider.future);
  final groupBookIds = shadowBooks.map((s) => s.book.id).toList();
  final useCase = ref.watch(getFamilyHappinessUseCaseProvider);
  return useCase.execute(groupBookIds: groupBookIds, year: year, month: month);
}
```

**Q6b. Empty-list short-circuit.** [VERIFIED]

`shadowBooks` returns `const []` when no group is active (`state_shadow_books.dart:28`). The presentation provider should short-circuit BEFORE calling the use case (above) — but the use case itself MUST also handle `groupBookIds: []` gracefully. Recommended use case behavior:

```dart
Future<FamilyHappiness> execute({required List<String> groupBookIds, required int year, required int month}) async {
  if (groupBookIds.isEmpty) {
    return FamilyHappiness(year: year, month: month, totalGroupSoulTx: 0,
      familyHighlightsSum: const Empty(), sharedJoyInsight: const Empty(),
      medianSatisfaction: const Empty());
  }
  // ... real work
}
```

This belt-and-braces pattern matches the project's "fail safe at every layer" idiom (see CLAUDE.md "Code Quality Checklist").

**Q6c. Including current device's own book.** [FLAGGED — minor open question]

`shadowBooks` returns *other members'* books (`book_repo.findShadowBooksByGroupId(groupId)` per `state_shadow_books.dart:31`). For Family Happiness, we want **all family books = current device's book + every shadow book**. The presentation provider should append the current `bookId` to `groupBookIds`. Confirm by reading `book_repository.dart` for `findShadowBooksByGroupId` semantics during planning. **(Open question O-1.)**

---

### Q7. Provider wiring location

[VERIFIED via `lib/application/analytics/repository_providers.dart` and `lib/features/analytics/presentation/providers/state_analytics.dart`]

**The single-source-of-truth split is locked by project precedent:**

| File | Owns | Pattern source |
|------|------|----------------|
| `lib/application/analytics/repository_providers.dart` | Use case providers (`@riverpod GetHappinessReportUseCase getHappinessReportUseCase(Ref ref) => ...`) | Mirrors existing `getMonthlyReportUseCaseProvider` pattern (the file currently exists at `repository_providers.dart` with `appDatabaseProvider` re-export — extend it). |
| `lib/features/analytics/presentation/providers/state_happiness.dart` (NEW) | Async data providers consumed by widgets (`@riverpod Future<HappinessReport> happinessReport(Ref ref, {bookId, year, month}) => ...`) | Mirrors `state_analytics.dart` pattern at `state_analytics.dart:32-40`. |

**NEVER duplicate provider definitions.** This is structurally enforced by `arch test provider_graph_hygiene_test.dart` + `riverpod_lint` per CLAUDE.md "Common Pitfalls" #10 (structurally enforced).

**Confirm the existing repository_providers.dart shape** [VERIFIED at `lib/application/analytics/repository_providers.dart:1-19`]: currently has 1 provider (`appAppDatabase`). Need to **add** providers for `analyticsRepository` (probably already lives in feature presentation — verify) plus the 3 new use case providers. **Action item for planner:** read `repository_providers.dart` in full and locate where `getMonthlyReportUseCaseProvider` is currently defined; the 3 new use case providers go in the same file.

---

### Q8. ADR drafting (D-22)

**Q8a. Numbering** [VERIFIED via `ls docs/arch/03-adr/`]:

Current files: `ADR-000_INDEX.md`, `ADR-001` through `ADR-011`. Max number = **011**. Next sequential: **ADR-012, ADR-013, ADR-014**. (Phase 12 will draft ADR-015 per D-23 — not Phase 9 work.)

**ADR Map per D-22:**

| Phase 9 ADR | Topic | Anchor (REQ / decision) |
|-------------|-------|-------------------------|
| ADR-012 | No Gamification v1.1 | Ratifies HAPPY-07. Goodhart's Law defense. Binding through milestone close. |
| ADR-013 | Joy Density PTVF Scaling | α=0.88 (K-T 1979), base-by-currency, Dart-layer rationale, performance trade-off vs SUM/GROUP BY principle. Anchors D-04. |
| ADR-014 | Soul Satisfaction Unipolar Positive Scale | Default 5→2 schema migration, picker emoji semantic remap, default-vs-Neutral collision acceptance, post-launch voice realignment plan. Anchors D-10..D-12. |

Numbers are sequential and the planner picks them — do NOT skip numbers.

**Q8b. Required ADR sections** [VERIFIED via `.claude/rules/arch.md` lines 1-180+ and ADR-011 file structure]:

Per `.claude/rules/arch.md` ADR template:

1. 文档头部信息 (header: 编号, 版本, 创建日期, 状态, 决策者, 影响范围, 相关 ADR)
2. 标题和编号
3. 状态 (Status — `✅ 已接受` once accepted)
4. 背景 (Context)
5. 考虑的方案 (Considered Options)
6. 决策 (Decision)
7. 决策理由 (Rationale)
8. 后果 (Consequences)
9. 实施计划 (Implementation Plan)

**Append-only rule:** Once status is `✅ 已接受`, subsequent context appends as `## Update YYYY-MM-DD: <topic>` at file end. Do NOT modify accepted decision text.

**Q8c. Extra rigor for the No Gamification ADR (ADR-012):**

Goodhart's Law ADRs need a **forbidden-features inventory** explicitly listing what's banned (streaks, badges, daily targets, cross-period comparisons, public sharing) so future PRs can be rejected with a one-line citation. Recommend a `## Forbidden Features (Permanent)` section after Decision. Cite Goodhart, 1975 in the Rationale.

**Q8d. Citation format** [VERIFIED via sampling ADR-011]:

ADR-011 cites with file paths in code blocks (e.g., `pubspec.yaml: mocktail: ^1.0.4`) and references project plans/SUMMARY paths. For ADR-012/013/014:
- Cite K-T 1979 paper formally in ADR-013 (per CONTEXT.md `<canonical_refs>` section).
- Cite Goodhart 1975, 2010 Cabinet Office wellbeing research, Keio SDM 2014 thesis in ADR-012/014 as appropriate.
- Cite source file line numbers (e.g., `lib/data/tables/transactions_table.dart:35`) for schema-migration anchors.

---

### Q9. Spec amendments as planner work-items

[DERIVED from D-22 + D-18]

**REQUIREMENTS.md edits (canonical list):**
1. HAPPY-02 — replace "Σ satisfaction / Σ amount" with PTVF formula (α=0.88, base by currency, Dart-layer fold).
2. HAPPY-03 — change threshold `≥ 8` → `≥ 6`.
3. HAPPY-04 — replace "argmax(satisfaction / amount) WHERE amount >= 500" with "Pure sat sort, ¥500 floor REMOVED".
4. HAPPY-08 — append the new emoji ↔ value mapping table under unipolar positive semantic (the *numbers* — emoji 1 → 2, emoji 2 → 4, etc.; *labels* are Phase 12 work).
5. HAPPY-09 — REMOVE entirely from v1.1 active list. Add to v2 by extending HAPPY-V2-03 with note about deferred `entry_source` column.
6. FAMILY-01 — change threshold `≥ 8` → `≥ 6`.
7. Update REQ count: `26 → 25`. Verify Traceability table reflects HAPPY-09 removal.

**ROADMAP.md edits:**
- Phase 9 critical pitfalls list:
  - REMOVE: "¥500 floor on Best Joy per ¥" (D-06).
  - REMOVE: "Voice-estimator +0.3 upward bias quantified by regression test; verify `transactions.entry_source` column exists in substep 9.0" (D-18).
  - ADD: "Schema bump v15 → v16 for default 5 → 2".
  - ADD: "PTVF α=0.88 with currency-aware base; Dart-layer fold; SUM/GROUP BY trade-off accepted".
- Phase 12 scope:
  - ADD: "5 emoji ARB labels rename" to existing 4-key rename pass (D-11).
  - ADD: "Picker Material icon update (emoji 1: very_dissatisfied → neutral)" (D-11).

**Planner allocation:**

**Recommendation: split into 2 plan units, not 1 consolidated.**
- **Plan 09-XX-spec-amendments-requirements.md** — REQUIREMENTS.md edits + Traceability table refresh.
- **Plan 09-XX-spec-amendments-roadmap.md** — ROADMAP.md Phase 9 + Phase 12 edits.

**Why split:** REQUIREMENTS.md owns REQ-IDs (downstream traceability); ROADMAP.md owns phase scopes (downstream phase planning). Splitting keeps the diffs reviewable, isolates failures, and respects the project's pattern of "one plan = one focused responsibility" (verified across v1.0 phase plans).

**Project precedent for spec changes inside a phase:** v1.0 had `08-08-roadmap-amendment.md` and similar — spec edits were tracked as plan units. Reuse that convention.

---

### Q10. Validation Architecture (Nyquist Dimension 8)

> `workflow.nyquist_validation: true` per `.planning/config.json:19` — section is required.

See dedicated `## Validation Architecture` section below.

---

### Q11. Build sequencing & dependencies

[DERIVED — see `## Recommended Build Sequence` below for full table.]

**Dependencies the planner must declare in PLAN.md frontmatter `depends_on`:**

- Schema migration plan unit must be **first** (no `depends_on`); domain models with `@Default(2)` semantic depend on it conceptually but compilation is independent.
- DAO/repository extension plans depend on (a) schema migration done, (b) `MetricResult<T>` and aggregates compiled.
- Use case plans depend on DAO/repository extension.
- Provider wiring plans depend on use case plans.
- Test plans for each layer depend on the corresponding implementation plan being mergeable (TDD: tests authored first, but blocking gate is "tests pass green" which requires implementation merged).
- ADRs depend on nothing structurally — can be drafted in parallel — but their **content** depends on the corresponding implementation decisions being final. Recommend ADR plans depend on the implementation plans whose decisions they ratify.
- Spec amendment plans depend on nothing structurally.

---

### Q12. Forbidden patterns audit

[VERIFIED]

**Q12a. `import_guard` enforces Thin Feature** [VERIFIED via `lib/features/import_guard.yaml:4-8`]:

```yaml
deny:
  - package:home_pocket/features/*/use_cases/**
  - package:home_pocket/features/*/application/**
  - package:home_pocket/features/*/infrastructure/**
  - package:home_pocket/features/*/data/**
```

Adding `lib/features/happiness/application/...` would be CI-rejected. There is no `features/happiness/` per the architecture decision Q2 — the planner MUST NOT create one.

**Q12b. AnalyticsRepository ownership of `getBestJoyMoment`** [VERIFIED via `lib/features/analytics/domain/repositories/analytics_repository.dart`]:

The interface lives at `lib/features/analytics/domain/repositories/analytics_repository.dart`. Adding `getBestJoyMoment` directly to `TransactionRepository` (in `lib/features/accounting/domain/repositories/`) is FORBIDDEN — `TransactionRepository` is for individual-transaction CRUD; argmax is an analytics aggregate. Couples analytics to transaction encryption pipeline. (Reaffirmed in CONTEXT.md `<known_forbidden_patterns>`.)

**Q12c. Anti-leaderboard contracts** [DERIVED from D-07, D-08]:

Type-system enforcement:
- `FamilyHighlightsSum` → wrapped in `MetricResult<int>` per D-15. The type literally cannot carry per-member info.
- `SharedJoyInsight` → tuple `(categoryId: String, avgSatisfaction: double, totalCount: int)`. No `memberId` field, no `Map<String, int>` field. Type-checked at compile time.

**Action item for plan-checker / Phase 9 verifier:** grep for `Map<String, int>` and `MemberId` symbols in new code; if any appear in `lib/features/analytics/domain/models/family_happiness.dart` or `lib/application/analytics/get_family_happiness_use_case.dart`, reject.

---

### Q13. Cross-currency test coverage for `joy_density_formatter.dart`

[VERIFIED via existing formatter precedent]

**Existing formatter tests** at `test/unit/infrastructure/i18n/formatters/{number_formatter,date_formatter}_test.dart` follow the pattern: per-locale fixtures, edge cases (large/small numbers, decimal handling, locale-specific separators).

**Recommended test cases for `joy_density_formatter.dart`:**

| # | Case | Expected |
|---|------|----------|
| 1 | `ptvfBaseFor('JPY')` | `500.0` |
| 2 | `ptvfBaseFor('CNY')` | `25.0` |
| 3 | `ptvfBaseFor('USD')` | `5.0` |
| 4 | `ptvfBaseFor('EUR')` (not in map) | `500.0` (fallback) |
| 5 | `ptvfBaseFor('jpy')` (lowercase) | `500.0` (case-insensitive) — ⚠️ **D-20 spec literal does NOT specify case-insensitivity. Open question O-2: confirm whether `Book.currency` is normalized.** |
| 6 | `formatJoyDensity(0.005, 'JPY')` | per Phase 9 contract D-19/D-20: `'5.0 / ¥1k'` (raw 0.005 × multiplier 1000 = 5.0) |
| 7 | `formatJoyDensity(0.5, 'CNY')` | `'50.0 / ¥100'` (0.5 × 100) |
| 8 | `formatJoyDensity(0.1, 'USD')` | `'0.1 / $1'` (0.1 × 1) |
| 9 | `formatJoyDensity(0.0, 'JPY')` | `'0.0 / ¥1k'` or empty-state sentinel? — **flag for planner.** |
| 10 | NaN / infinity guard | Should the formatter accept NaN gracefully or assert? — **flag for planner.** |

**Test pattern:** Follow `number_formatter_test.dart` for grouping per-locale assertions. No new test infrastructure needed.

---

## Validation Architecture

> Required: `workflow.nyquist_validation: true`. Per-task acceptance criteria for plan-checker flow from this section.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (built-in) + `mocktail ^1.0.4` (project standard since v1.0 Phase 4-04 per ADR-011 §A) |
| Config file | None (Flutter convention; runner reads `test/` recursively) |
| In-memory DB | `AppDatabase.forTesting()` at `lib/data/app_database.dart:42` (uses `NativeDatabase.memory()`) |
| Quick run command | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -r expanded` |
| Full suite command | `flutter test --coverage` |
| Coverage gate | Per-file ≥70% with `--deferred` mechanism (CLAUDE.md "Active CI guardrails"); use `coverde --deferred` |

### Phase Requirements → Test Map

| REQ | Behavior | Test Type | Automated Command | File Exists? |
|-----|----------|-----------|-------------------|-------------|
| HAPPY-01 | Avg satisfaction over MTD soul ledger; survival rows excluded | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -r expanded -P "avg satisfaction"` | ❌ Wave 0 |
| HAPPY-02 | PTVF density (α=0.88, base by currency); n=0/1/N + multi-currency cases | unit | `flutter test test/unit/application/analytics/get_happiness_report_use_case_test.dart -r expanded -P "joy per yen"` | ❌ Wave 0 |
| HAPPY-03 | Highlights count `sat ≥ 6` from distribution | unit | same file, `-P "highlights count"` | ❌ Wave 0 |
| HAPPY-04 | Argmax via `ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1` | unit | `flutter test test/unit/application/analytics/get_best_joy_moment_use_case_test.dart` | ❌ Wave 0 |
| HAPPY-04 | DAO query directly returns `null` on empty; correct argmax on populated | unit | `flutter test test/unit/data/daos/analytics_dao_test.dart -P "best joy moment"` | ⚠️ partial — file exists, new tests added |
| HAPPY-05 | `_soulOnly()` const string composes correctly; survival rows demonstrably excluded by all 4 query sites | unit | `flutter test test/unit/data/daos/analytics_dao_test.dart -P "soul only filter"` | ⚠️ partial |
| HAPPY-06 | `MetricResult<T>` sealed switch exhaustiveness; Empty<T>(), Value<T>(data, sampleSize) constructors | unit | `flutter test test/unit/features/analytics/domain/models/metric_result_test.dart` | ❌ Wave 0 |
| HAPPY-06 | UI never sees NaN/inf/0% — assert `MetricResult.empty` returned in n=0 case | unit | included in HAPPY-01..04 tests | ❌ Wave 0 |
| HAPPY-07 | ADR-012 file exists at expected path with required sections | static check | `test -f docs/arch/03-adr/ADR-012_*.md && grep -q "Forbidden Features" docs/arch/03-adr/ADR-012_*.md` | ❌ Wave 5 |
| HAPPY-08 | 5-emoji ↔ {2,4,6,8,10} mapping pinned by unit test | unit | `flutter test test/unit/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart -P "value mapping"` | ⚠️ verify existing test covers post-migration values |
| HAPPY-09 | REMOVED — coverage = REQUIREMENTS.md amendment | static check | `grep -q "HAPPY-V2-03" .planning/REQUIREMENTS.md && ! grep -q "HAPPY-09\b.*Voice satisfaction estimator" .planning/REQUIREMENTS.md` | N/A |
| FAMILY-01 | `FamilyHighlightsSum` returns `int` only; `Map<MemberId, int>` rejected at compile time | unit + grep | `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart -P "highlights sum int"` + `! grep -rn 'Map<.*MemberId.*int>\|Map<String, int>' lib/features/analytics/domain/models/family_happiness.dart lib/application/analytics/get_family_happiness_use_case.dart` | ❌ Wave 0 |
| FAMILY-02 | Category argmax with min-N=3 guard; tuple `(categoryId, avgSatisfaction, totalCount)` only | unit | `flutter test test/unit/application/analytics/get_family_happiness_use_case_test.dart -P "shared joy insight"` | ❌ Wave 0 |
| Schema migration | v15→v16; default 5→2; CHECK constraint survives; new inserts default to 2 | integration | `flutter test test/integration/data/app_database_v16_migration_test.dart` | ❌ Wave 0 |
| `joy_density_formatter` | PTVF base + display unit per currency; fallback to JPY=500 | unit | `flutter test test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/application/analytics/ test/unit/data/daos/analytics_dao_test.dart -r expanded` (~30s estimated based on existing analytics test runtime)
- **Per wave merge:** `flutter test --coverage` + `flutter analyze` + `dart run custom_lint --no-fatal-infos`
- **Phase gate:** Full suite green + per-file coverage ≥70% + 0 analyzer issues + `build_runner` clean-diff before `/gsd-verify-work`

### Wave 0 Gaps (test files to create / extend)

- [ ] `test/unit/features/analytics/domain/models/metric_result_test.dart` — covers HAPPY-06 sealed-class behavior
- [ ] `test/unit/features/analytics/domain/models/happiness_report_test.dart` — Freezed shape + copyWith
- [ ] `test/unit/features/analytics/domain/models/family_happiness_test.dart` — Freezed shape + anti-leaderboard contract grep
- [ ] `test/unit/features/analytics/domain/models/best_joy_moment_test.dart`
- [ ] `test/unit/data/daos/analytics_dao_test.dart` — extend with `getBestJoyMoment`, `getSoulRowsForPtvf`, `_soulExpenseFilter` reuse tests (verify file exists; if not, also a Wave 0 gap)
- [ ] `test/unit/data/repositories/analytics_repository_impl_test.dart` — extend with 4 new method delegations
- [ ] `test/unit/application/analytics/get_happiness_report_use_case_test.dart` — covers HAPPY-01..04 (mirror existing `get_monthly_report_use_case_test.dart` shape)
- [ ] `test/unit/application/analytics/get_best_joy_moment_use_case_test.dart`
- [ ] `test/unit/application/analytics/get_family_happiness_use_case_test.dart`
- [ ] `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart`
- [ ] `test/integration/data/app_database_v16_migration_test.dart` — schema migration verification
- [ ] Possibly `test/unit/features/accounting/presentation/widgets/satisfaction_emoji_picker_test.dart` extension to pin {2,4,6,8,10} mapping (HAPPY-08)

**Framework install:** None — `flutter_test` and `mocktail` already in `pubspec.yaml` (mocktail at `^1.0.4` per `pubspec.yaml`).

---

## Recommended Build Sequence

> Each wave is buildable + testable independently. `build_runner` runs after every wave touching `@freezed` / `@riverpod`.

### Wave 0 — Test scaffolding (parallel; no `depends_on`)

- W0-A: Create test files (Wave 0 Gaps list above) with `test('placeholder', () { /* TODO Wave N */ });` skeletons. Allows TDD authoring in subsequent waves.

### Wave 1 — Schema migration + Domain models (parallel)

- W1-A: **Schema migration v15 → v16** (`depends_on: []`)
  - Edit `lib/data/tables/transactions_table.dart:35` `Constant(5)` → `Constant(2)`.
  - Edit `lib/data/daos/transaction_dao.dart:29` and `:133` parameter defaults `5` → `2`.
  - Edit `lib/features/accounting/domain/models/transaction.dart:42` `@Default(5)` → `@Default(2)`.
  - Edit `lib/application/analytics/demo_data_service.dart:134` `: 5;` → `: 2;`.
  - Bump `lib/data/app_database.dart:45` `schemaVersion` 15 → 16. Add empty `if (from < 16) {}` block in `onUpgrade`.
  - Run `build_runner build --delete-conflicting-outputs`.
  - Migration test in `test/integration/data/app_database_v16_migration_test.dart`.
- W1-B: **Domain models** (`depends_on: []` — schema is conceptual, not compile-blocking)
  - Create `lib/features/analytics/domain/models/metric_result.dart` (plain sealed class — NO codegen).
  - Create `lib/features/analytics/domain/models/happiness_report.dart` (Freezed; shape per D-15).
  - Create `lib/features/analytics/domain/models/family_happiness.dart` (Freezed; shape per D-15).
  - Create `lib/features/analytics/domain/models/best_joy_moment.dart` (Freezed; carries `BestJoyMomentRow` per D-15).
  - Create `lib/features/analytics/domain/models/shared_joy_insight.dart` (Freezed; tuple `(categoryId, avgSatisfaction, totalCount)`).
  - Extend `lib/features/analytics/domain/models/analytics_aggregate.dart` with new domain types `SatisfactionOverview`, `SatisfactionDistribution`, `BestJoyMomentRow`, `SoulRowAmountSat` (mirror existing `MonthlyTotals` plain-class pattern at line 2).
  - Run `build_runner` for Freezed.
  - Domain tests for `MetricResult` and aggregate types.

### Wave 2 — DAO + Repository extension (`depends_on: [W1-A, W1-B]`)

- W2-A: **DAO additions** (`depends_on: [W1-A]`)
  - Add `static const String _soulExpenseFilter` to `AnalyticsDao`.
  - Refactor `getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend` to compose from `_soulExpenseFilter` (no semantic change — verify via existing tests pass).
  - Add `getBestJoyMoment`, `getSoulRowsForPtvf`, `getSharedJoyCategoryInsight`.
  - DAO tests for the 3 new methods + survival-row exclusion regression test.
- W2-B: **Repository extension** (`depends_on: [W1-B, W2-A]`)
  - Extend `lib/features/analytics/domain/repositories/analytics_repository.dart` with 5 new method signatures (`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`, `getBestJoyMoment`, `getSoulRowsForPtvf`, `getSharedJoyCategoryInsight` — note 3 of these were already in the DAO but not the repo interface).
  - Extend `lib/data/repositories/analytics_repository_impl.dart` with implementations (mirror existing translation pattern at lines 12–28).
  - Repository unit tests with mocktail for delegation.

### Wave 3 — Use cases + provider wiring (`depends_on: [W2-B]`)

- W3-A: **`GetHappinessReportUseCase`** (`depends_on: [W2-B]`)
  - Mirror `get_monthly_report_use_case.dart` template precisely.
  - PTVF computation, median computation, highlights count from distribution.
  - Tests covering all PTVF fixture cases (Q5).
- W3-B: **`GetBestJoyMomentUseCase`** (`depends_on: [W2-B]`)
  - Single argmax delegation to repo.
  - Empty trigger: `totalSoulTx == 0` (need to also fetch `getSoulSatisfactionOverview.count` to enforce per D-16).
- W3-C: **`GetFamilyHappinessUseCase`** (`depends_on: [W2-B]`)
  - Accepts `groupBookIds: List<String>` per D-09.
  - Empty short-circuit on empty list.
  - Aggregates highlights across all books in Dart.
  - Calls `getSharedJoyCategoryInsight` for FAMILY-02.
- W3-D: **Provider wiring** (`depends_on: [W3-A, W3-B, W3-C]`)
  - Extend `lib/application/analytics/repository_providers.dart` with 3 new use case providers.
  - Create `lib/features/analytics/presentation/providers/state_happiness.dart` with 3 async data providers.
  - Run `build_runner` for `@riverpod`.

### Wave 4 — Formatter helper (parallel with Wave 3) (`depends_on: []`)

- W4-A: Create `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` per D-20 spec verbatim.
- W4-B: Tests covering currency cases per Q13.

### Wave 5 — ADRs (parallel; `depends_on: [W2-A, W3-A]` for content correctness)

- W5-A: Draft ADR-012 No Gamification v1.1 (HAPPY-07 ratification).
- W5-B: Draft ADR-013 Joy Density PTVF Scaling (anchors W2-A row-wise query design + W3-A PTVF fold rationale).
- W5-C: Draft ADR-014 Soul Satisfaction Unipolar Positive Scale (anchors W1-A schema migration philosophy).
- W5-D: Update `docs/arch/03-adr/ADR-000_INDEX.md` with 3 new entries.

### Wave 6 — Spec amendments (parallel; `depends_on: []`)

- W6-A: Amend `.planning/REQUIREMENTS.md` per Q9 list (HAPPY-02 / -03 / -04 / -08 / -09; FAMILY-01).
- W6-B: Amend `.planning/ROADMAP.md` Phase 9 critical pitfalls + Phase 12 scope per Q9.

---

## Open Questions for Planner (RESOLVED)

> Short list — Claude's Discretion items where a concrete choice was needed.
> Each question carries a `**RESOLVED:**` line referencing the plan that pinned the decision.

1. **O-1: Family books enumeration.** `shadowBooksProvider` returns *other members'* books. Confirm whether the current device's own book should be included in `groupBookIds` for `GetFamilyHappinessUseCase`. Read `book_repository.dart` `findShadowBooksByGroupId` semantics during planning to verify. (Q6c.)
   **RESOLVED:** Phase 9 passes the unmodified `shadowBooks` list (other members' books only) to the use case. Whether to also include the current device's own book is a presentation-layer concern deferred to Phase 10's HomePage rebuild — not a Phase 9 contract surface change. Documented as a known caveat in Plan 08's must_haves.
2. **O-2: `Book.currency` normalization.** Is currency code stored uppercase in `books_table.currency`? `joy_density_formatter`'s map uses `'JPY'`/`'CNY'`/`'USD'` uppercase keys. If DB stores mixed-case, formatter needs `.toUpperCase()` normalization. Verify by sampling existing book inserts. (Q13 case 5.)
   **RESOLVED:** Plan 09 ships the formatter with case-sensitive lookup against the existing uppercase ISO codes. Plan 09 Test 10 (`'jpy'` → fallback 500.0) pins the contract; if DB ever stores mixed-case the test will trip and the planner will reopen the question.
3. **O-3: `fromJson` / `toJson` on new Freezed aggregates.** `MonthlyReport` has `fromJson` (`monthly_report.dart:45`) but it's likely unused dead-weight (these are transient query results). Recommend NOT generating `fromJson`/`toJson` on the new happiness aggregates. (Q3b — minor.)
   **RESOLVED:** Plan 02 omits `fromJson`/`toJson` on the new Freezed aggregates per the recommendation — they are transient query results, not persisted entities.
4. **O-4: Empty-state sentinel for `formatJoyDensity(0.0, ...)`.** Should the formatter return `'—'` or `'0.0 / ¥1k'` for raw 0.0? UI semantics drive this — likely Phase 10 work but the helper API should be defined here. (Q13 case 9.)
   **RESOLVED:** Plan 09 returns `'0.0 / <unit-label>'` for raw 0.0 so the formatter is total over its domain; the UI layer (Phase 10) substitutes `'—'` or a CTA when `MetricResult` is `Empty`. Formatter stays pure; sentinel handling lives where it belongs.
5. **O-5: Test fixture strategy** (deferred per Claude's Discretion in CONTEXT.md). Recommend hand-built fixtures for unit tests (control over edge cases) + minor extension of `demo_data_service.dart` for integration smoke tests.
   **RESOLVED:** 09-VALIDATION.md adopts the recommendation — hand-built fixtures inside each `*_use_case_test.dart` for unit edge cases; `demo_data_service.dart` extension is touched only by Plan 01 (sat=5 → sat=2 audit) and is not used as a test fixture.

---

## Risk Register

> Ranked by impact (highest first). Each risk has a Phase 9 mitigation hook.

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| R-1 | **Survival-row contamination** — any new aggregator forgets `_soulOnly()` filter and pulls survival rows with `soul_satisfaction=2` (post-migration) into PTVF / median / highlights. | CRITICAL — all 6 metrics silently wrong. | MEDIUM (D-01 forbids satisfaction filter; the *ledger* filter is the residual risk). | (a) `_soulExpenseFilter` const string makes filter centralized + greppable; (b) DAO test fixture mandatorily includes 2 survival rows + assert excluded; (c) refactor 3 existing dormant DAO queries to compose from the same const so any drift breaks all queries together. |
| R-2 | **Formula correctness on PTVF** — α=0.88 typo, base lookup typo, off-by-one in median, miscount of highlights at boundary `sat=6` (off-by-one between `>` and `>=`). | HIGH — wrong numbers ship to UI; user trust impact. | MEDIUM (numerical code in untested territory). | (a) Hand-computed test fixtures with `closeTo(expected, 0.0001)` matchers; (b) HAPPY-03/FAMILY-01 test pin `sat=5` excluded, `sat=6` included exactly; (c) PTVF α=0.88 declared as a single named const (e.g., `_ptvfAlpha = 0.88`) with literal value cross-referenced in ADR-013. |
| R-3 | **Anti-leaderboard contract slip** — future PR adds `Map<MemberId, int>` field to `FamilyHappiness` because "the data is right there in shadowBooks loop". | HIGH (privacy / family dynamics harm; permanent forbidden). | LOW initially; rises over milestone duration. | (a) Type-system enforcement: `MetricResult<int>` for sum, `(catId, avg, count)` tuple for insight; (b) add CI grep step rejecting `Map<.*MemberId.*int>` in `lib/features/analytics/`; (c) document as **explicit forbidden feature** in ADR-012 with grep-able pattern. |
| R-4 | **`demo_data_service.dart` stale rows** — schema migration plan only edits `transactions_table.dart` but forgets `transaction_dao.dart:29`, `:133`, `transaction.dart:42`, `demo_data_service.dart:134`. New inserts via these paths still default to `5`, undermining D-10 philosophy. | MEDIUM — visible in dev / demo only (no real users yet) but pollutes metrics in development. | HIGH if migration plan scope is too narrow. | Schema migration plan unit MUST list **all four** edit sites explicitly (Q4d list). Verifier greps for residual `Constant(5)\|@Default(5).*soulSatisfaction\|soulSatisfaction = 5` in `lib/`. |
| R-5 | **Type-system enforcement of MetricResult** — sealed switch missing exhaustiveness check at consumer site. Phase 10 widget code that uses `if (result is Empty)` instead of `switch` could miss Value sub-cases or silently fall through. | MEDIUM — bugs surface at consumer time, but Phase 9 owns the contract. | LOW initially (Phase 9 doesn't have consumers) — risk escalates in Phase 10. | (a) Document `switch` exhaustiveness as the consumption pattern in ADR-014 or in the model file's dartdoc; (b) Phase 10 plan-checker grep for `if (.* is Empty\|is Value)` patterns and reject in favor of `switch`. |
| R-6 | **Migration body emptiness misunderstood as missing migration** — code review questions empty `if (from < 16) {}` block; reviewer requests "real" DDL, planner adds a no-op `ALTER TABLE` that breaks Drift's schema introspection. | MEDIUM — could break post-migration testing. | MEDIUM (well-intentioned reviewer pressure). | (a) Inline comment explaining D-02 rationale and pre-launch backfill-skip; (b) cite ADR-014 in the comment; (c) migration test that asserts new defaults take effect. |
| R-7 | **MetricResult<T> in widget memoization** — `==` on `Value(0.5, 10)` instances is reference-equality (default), so widget rebuilds on every report-fetch even if numbers identical. Subtle UI flicker / wasted render. | LOW (widgets aren't this phase's deliverable, but the contract enables the issue). | LOW. | Either override `==`/`hashCode` on Empty/Value (5 lines of code), OR document that consumers must rely on `AsyncValue` caching at the provider level. Recommend the override for cleanliness. |
| R-8 | **Generic Freezed quirks if planner mistakenly chooses `@freezed sealed class MetricResult<T>`** — Freezed 3.x supports generics but project has zero precedent; could surface obscure codegen edge cases. | LOW (research's Q3 explicitly recommends plain sealed). | LOW (only if planner deviates from research recommendation). | Lock plain-sealed approach in `metric_result.dart` plan unit; reject any `@freezed` annotation in plan-checker review for that file. |
| R-9 | **ADR-012/013/014 numbering collision** — parallel work elsewhere bumps ADR-012 first. | LOW. | LOW. | Planner reads `docs/arch/03-adr/` immediately before drafting; allocates next-available numbers in lockstep across the 3 ADRs; updates `ADR-000_INDEX.md` atomically with all 3. |
| R-10 | **Spec amendment drift** — REQUIREMENTS.md is amended but the Traceability table at line 102 isn't updated to reflect HAPPY-09 removal, leaving REQ count `26` while body lists `25`. | LOW (cosmetic / document hygiene). | MEDIUM. | Plan unit explicitly includes Traceability table edits. Verifier greps `26 total` and `25 total` consistency. |

---

## Sources

### Primary (HIGH confidence)

- `.planning/phases/09-happiness-domain-formula-layer/09-CONTEXT.md` — D-01..D-23 user decisions (read in full)
- `.planning/phases/09-happiness-domain-formula-layer/09-DISCUSSION-LOG.md` — alternatives considered (read in full)
- `.planning/REQUIREMENTS.md` — REQ list pre-amendment
- `.planning/ROADMAP.md` — Phase 9 + 10 + 11 + 12 sections
- `.planning/STATE.md` — pending todos closure tracking
- `.planning/PROJECT.md` — milestone v1.1 vision
- `.planning/research/SUMMARY.md`, `ARCHITECTURE.md`, `PITFALLS.md`, `STACK.md` — cross-cutting v1.1 research (HIGH/MEDIUM-HIGH confidence)
- `lib/data/tables/transactions_table.dart` (read in full) — schema target
- `lib/data/tables/books_table.dart` (read in full) — currency column
- `lib/data/daos/analytics_dao.dart` (read in full) — 3 dormant methods at lines 230–327; performance principle line 85; soul-only filter recipe lines 239, 271, 305
- `lib/data/repositories/analytics_repository_impl.dart` (read in full) — DAO→domain mapping pattern
- `lib/features/analytics/domain/repositories/analytics_repository.dart` (read in full)
- `lib/features/analytics/domain/models/analytics_aggregate.dart` (read in full)
- `lib/features/analytics/domain/models/monthly_report.dart` (read in full) — Freezed precedent
- `lib/application/analytics/get_monthly_report_use_case.dart` (read in full) — use case template
- `lib/application/analytics/repository_providers.dart` (read in full) — provider wiring location
- `lib/application/analytics/demo_data_service.dart` (read in full) — `sat=5` audit
- `lib/features/analytics/presentation/providers/state_analytics.dart` (read in full) — provider naming pattern
- `lib/features/home/presentation/providers/state_shadow_books.dart` (read in full) — D-09 provider shape
- `lib/features/family_sync/presentation/providers/state_active_group.dart` (read in full)
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` (read in full) — picker writes `{2,4,6,8,10}` confirmed
- `lib/application/voice/voice_satisfaction_estimator.dart:170-190` — voice output range `[3,10]`
- `lib/features/home/presentation/screens/home_screen.dart:340-368` — `_compute*` helpers (Phase 10 scope, NOT 9)
- `lib/data/app_database.dart` (read in full) — schema version + migration pattern
- `lib/data/daos/transaction_dao.dart:20-55,130-160` — `sat=5` defaults that need updating
- `lib/features/accounting/domain/models/transaction.dart:30-47` — Freezed model `@Default(5)`
- `lib/core/initialization/init_result.dart` (read in full) — `@freezed sealed class` precedent
- `lib/infrastructure/security/models/auth_result.dart` (read in full) — same precedent
- `lib/application/family_sync/check_group_use_case.dart:1-50` — plain `sealed class` precedent
- `lib/infrastructure/i18n/formatters/number_formatter.dart` (read in full) — formatter pattern for D-20
- `test/unit/application/analytics/get_monthly_report_use_case_test.dart:1-128` — `closeTo` matcher idiom; `AppDatabase.forTesting()` + DAO seeding pattern
- `lib/features/import_guard.yaml` (read in full) — Thin Feature CI enforcement
- `lib/features/analytics/domain/import_guard.yaml` (read in full) — domain layer purity
- `docs/arch/03-adr/` listing — ADR-011 is current max (verified by `ls`)
- `.claude/rules/arch.md` (read sufficient) — ADR template + numbering protocol
- `.planning/config.json` — `nyquist_validation: true` + workflow flags
- `pubspec.yaml:24,81-82` — Freezed 3.x + json_serializable 6.9.4

### Secondary (MEDIUM confidence)

- Existing v1.1 cross-cutting research files (SUMMARY/ARCHITECTURE/PITFALLS/STACK/FEATURES) — already validated at v1.1 milestone-start.

### External / academic (for ADR citations)

- Kahneman & Tversky (1979) — α=0.88 PTVF empirical fit (cited from CONTEXT.md `<canonical_refs>`).
- Goodhart (1975) — measure-becomes-target law (No Gamification ADR).
- Stevens (1957) — psychophysical power law (alternative noted in PTVF ADR).

---

## Metadata

**Confidence breakdown:**
- DAO method placement & shape: HIGH — every claim grounded in `analytics_dao.dart` line numbers.
- Sealed class for `MetricResult<T>`: HIGH — multiple precedents found in `lib/`; D-13 specifies plain sealed (no Freezed) which sidesteps the only theoretical risk.
- Schema migration mechanics: HIGH — `app_database.dart:48-264` is fully readable; Drift idiom is well-established; D-02 acceptance of empty migration body is explicit.
- Test fixture coverage: HIGH — existing `closeTo` + `AppDatabase.forTesting()` patterns confirmed.
- Provider wiring: HIGH — single-source-of-truth rule is structurally enforced.
- ADR drafting: HIGH — `.claude/rules/arch.md` template is complete; ADR numbering verified by directory listing.
- `joy_density_formatter` design: MEDIUM-HIGH — D-20 spec is precise; tests follow existing formatter precedent.
- `shadowBooksProvider` integration: MEDIUM — provider shape verified; one open question (O-1) on whether current device's book should be included in `groupBookIds`.

**Research date:** 2026-05-01
**Valid until:** 2026-06-01 (30 days — stable contract domain; no fast-moving external dependencies)

---

## RESEARCH COMPLETE
