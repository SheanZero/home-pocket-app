# Phase 9: Happiness Domain & Formula Layer - Context

**Gathered:** 2026-05-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 9 is the **linchpin phase** of v1.1. It locks the formulas, contracts, and anti-gamification defenses for the happiness metrics so every downstream UI consumer (Phase 10 HomePage, Phase 11 AnalyticsScreen, Phase 12 ARB rename) builds on stable ground.

**Delivered surface:**
- Domain models (`HappinessReport`, `BestJoyMomentRow`, `FamilyHappiness`, `SharedJoyInsight`, sealed `MetricResult<T>`)
- Centralized `_soulOnly()` SQL fragment + 1 new DAO query (`getBestJoyMoment` argmax) + median computation hook
- 3 use cases scoped by audience boundary (`GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase`)
- Dart-layer PTVF (Prospect Theory Value Function) Joy/¥ density computation with currency-aware base
- Schema migration v15 → v16 (default `soul_satisfaction` 5 → 2)
- ADR ratifying anti-gamification posture + Joy density PTVF scaling rationale + soul satisfaction unipolar positive scale

**Not delivered in Phase 9** (downstream phases): HomePage UI rebuild (Phase 10), Analytics chart wiring (Phase 11), ARB value rename + emoji label rename + picker icon update (Phase 12).

</domain>

<decisions>
## Implementation Decisions

### Formulas

- **D-01 `_soulOnly()` SQL fragment is non-filtering on satisfaction.** The fragment filters only `WHERE ledger_type = 'soul' AND type = 'expense' AND is_deleted = 0`. It does NOT filter `soul_satisfaction != 5` or any other satisfaction value. All default-state rows enter every aggregation. Why: the user explicitly chose "no backdoor — for future UI extension keep data clean."

- **D-02 Schema bump v15 → v16.** `transactions_table.dart:35` `withDefault(const Constant(5))` → `withDefault(const Constant(2))`. CHECK constraint stays `BETWEEN 1 AND 10`. **No data backfill** required — project is pre-launch with no real user data. `demo_data_service.dart` must be reviewed for any seeded `sat=5` rows that need updating to match the new "2 = neutral / unrated baseline" semantic.

- **D-03 HAPPY-01 (Avg Satisfaction):** `AVG(soul_satisfaction)` over month-to-date soul ledger expense transactions scoped by `book_id`. **No PTVF scaling** — Avg Sat is the "金额无关的纯情绪自检" angle, deliberately decoupled from HAPPY-02's money-weighted density.

- **D-04 HAPPY-02 (Joy density / Joy per ¥) uses Prospect Theory Value Function with α=0.88, base currency-aware.** Formula:
  ```
  density = SUM(soul_satisfaction × (amount / base)^0.88) / SUM(amount)
  ```
  - α = 0.88 is Kahneman & Tversky's empirically fitted value (1979 Econometrica paper).
  - **Base by currency:** JPY → 500, CNY → 25, USD → 5, fallback → 500. The use case takes `currencyCode: String` as a parameter; the presentation provider resolves currency from `Book.currency` before invoking the use case.
  - **Scaling computed in Dart layer**, not in SQL. DAO returns row-wise `(amount, soul_satisfaction)` tuples; the use case folds them into the PTVF density. Rationale: SQLite has no `POW`/`EXP` standard functions; Dart-side computation also keeps the constant α and base together as named consts that ADR can reference and that future tuning has a clean home.
  - **Performance trade-off accepted:** This violates the v1.0 "DAO uses SUM/GROUP BY for <2s performance" principle. With monthly soul tx counts typically 10–100 per book, the row-wise return is negligible. Document the trade-off in the PTVF ADR.

- **D-05 HAPPY-03 (Highlights count) threshold = sat ≥ 6** (was ≥ 8 in initial spec). The new threshold matches the post-rename emoji semantic where emoji 3 (writes 6) is "Good" and the count means "Good or better" moments. REQUIREMENTS.md HAPPY-03 must be amended.

- **D-06 HAPPY-04 (Top Joy / 本月最值) uses Pure satisfaction sort, NO ¥500 floor.** SQL:
  ```sql
  ORDER BY soul_satisfaction DESC, amount DESC, timestamp DESC LIMIT 1
  ```
  Why: the user pushed back on the original `sat / amount` density argmax — under that formula, `¥500 sat=6` beats `¥3,000 sat=10`, which violates the intuitive constraint "10 is the ceiling so sat=10 must trump sat=8". Pure sat sort with `amount DESC` tiebreak preserves the ceiling AND rewards intentional bigger spending when satisfaction is tied. The ¥500 floor is removed because amount-DESC tiebreak handles the "small amount over-rewarded" concern. REQUIREMENTS.md HAPPY-04 must be amended.

- **D-07 FAMILY-01 (Family Highlights Sum) threshold = sat ≥ 6**, aligned with HAPPY-03. Returns `int` (single aggregate count). **Per-member breakdown is forbidden by contract** — the use case signature must not expose `Map<MemberId, int>` or any data shape that enables a leaderboard. REQUIREMENTS.md FAMILY-01 must be amended.

- **D-08 FAMILY-02 (Shared Joy Insight) uses category argmax with min-N=3 guard.** SQL:
  ```sql
  GROUP BY category_id
  HAVING COUNT(*) >= 3
  ORDER BY AVG(soul_satisfaction) DESC, COUNT(*) DESC, category_id ASC
  LIMIT 1
  ```
  Returns `(categoryId, avgSatisfaction, totalCount)` only — no per-member fields, type-system enforced. Tie-break: same avg → higher count wins; same avg + count → category_id ascending (deterministic). When no category meets min-N=3, returns null → `MetricResult.empty` at use case layer.

- **D-09 Group books enumeration: Family use cases reuse `shadowBooksProvider`.** `GetFamilyHappinessUseCase.execute()` accepts `groupBookIds: List<String>` as a parameter. The presentation provider (in `state_happiness.dart`) resolves the list via `ref.watch(shadowBooksProvider.future)` before invoking the use case. Phase 11 reuses the same path. Use case stays free of presentation-layer / shadow-book-registry knowledge.

### Soul Satisfaction Scale (Path B unipolar positive shift)

- **D-10 Schema default 5 → 2** (already captured in D-02). Encodes the new "every soul transaction is happy at least at neutral level" semantic. Default-2 collides with `picker emoji 1 (Neutral)` value — the project explicitly accepts this collision because it does not need to distinguish "user tapped Neutral" from "user submitted without tapping". The product framing: every soul transaction is **at least neutral**.

- **D-11 Phase 12 ARB rename pass scope expands to include 5 satisfaction-level emoji labels** (and corresponding picker icon updates):
  - `satisfactionBad` → "中性 / Neutral / 中性"
  - `satisfactionSlightlyBad` → "OK / OK / OK"
  - `satisfactionNormal` → "不错 / Good / 不錯"
  - `satisfactionGood` → "满足 / Great / 満足"
  - `satisfactionVeryGood` → "最爱 / Amazing / 最愛"
  - Picker icon for emoji 1: `sentiment_very_dissatisfied_outlined` → `sentiment_neutral_outlined` (or equivalent neutral icon). Other 4 icons may need symmetric adjustment — Phase 12 / planner decides icon set.

- **D-12 Voice estimator output range realignment is post-launch / v1.2.** Current voice output ∈ [3, 10] (`voice_satisfaction_estimator.dart:185-188`) does not align cleanly with the new picker semantic. Voice values 3, 5, 7, 9 fall between picker emojis, but the picker's `_selectedIndex` getter rounds to nearest bucket and renders deterministically. Acceptable compromise: ship Phase 9 + 12 changes, fix voice realignment in v1.2 if the cross-modal inconsistency causes user friction.

### MetricResult Contract

- **D-13 Sealed binary type with Empty / Value variants:**
  ```dart
  sealed class MetricResult<T> {
    const MetricResult();
  }
  final class Empty<T> extends MetricResult<T> {
    const Empty();
  }
  final class Value<T> extends MetricResult<T> {
    final T data;
    final int sampleSize;  // count of soul tx that contributed
    const Value(this.data, this.sampleSize);
  }
  ```
  No `thinSample` variant. UI signals sample-size context via separate caption logic, not via type-level differentiation.

- **D-14 Single Empty (no subtypes / no `reason` enum).** UI distinguishes "no soul tx" vs "min-N not met" (FAMILY-02 only) by reading the aux field `totalSoulTx` / `totalGroupSoulTx` from the parent report. Trade-off: simpler types vs UI must combine signals. Accepted because the type complexity savings outweigh UI's modest extra logic.

- **D-15 HappinessReport / FamilyHappiness use mixed packaging — main metrics wrapped in MetricResult, aux metadata flat:**
  ```dart
  @freezed
  class HappinessReport with _$HappinessReport {
    const factory HappinessReport({
      // aux (flat)
      required int year,
      required int month,
      required String bookId,
      required int totalSoulTx,                                  // window-scoped soul tx count
      // main metrics (MetricResult-wrapped)
      required MetricResult<double> avgSatisfaction,             // HAPPY-01
      required MetricResult<double> joyPerYen,                   // HAPPY-02 (raw, pre-display)
      required MetricResult<double> medianSatisfaction,          // HAPPY-01b for AnalyticsScreen tooltip
      required MetricResult<int> highlightsCount,                // HAPPY-03
      required MetricResult<BestJoyMomentRow> topJoy,            // HAPPY-04
    }) = _HappinessReport;
  }

  @freezed
  class FamilyHappiness with _$FamilyHappiness {
    const factory FamilyHappiness({
      // aux (flat)
      required int year,
      required int month,
      required int totalGroupSoulTx,
      // main metrics
      required MetricResult<int> familyHighlightsSum,            // FAMILY-01
      required MetricResult<SharedJoyInsight> sharedJoyInsight,  // FAMILY-02
      required MetricResult<double> medianSatisfaction,          // group-level median for tooltip
    }) = _FamilyHappiness;
  }
  ```

- **D-16 Empty trigger alignment table:**
  | Metric | Empty trigger | Value content |
  |---|---|---|
  | HAPPY-01 Avg Sat | totalSoulTx = 0 | data=mean, sampleSize=totalSoulTx |
  | HAPPY-02 Joy/¥ | totalSoulTx = 0 (sum_amt = 0 only possible in degenerate "all zero amount" case which expense type forbids) | data=density, sampleSize=totalSoulTx |
  | HAPPY-03 Highlights | totalSoulTx = 0 | data=count (may be 0), sampleSize=totalSoulTx |
  | HAPPY-04 Top Joy | totalSoulTx = 0 | data=BestJoyMomentRow, sampleSize=totalSoulTx |
  | FAMILY-01 Family Highlights | totalGroupSoulTx = 0 | data=count (may be 0), sampleSize=totalGroupSoulTx |
  | FAMILY-02 Shared Joy Insight | totalGroupSoulTx = 0 OR no category meets min-N=3 | data=SharedJoyInsight, sampleSize=totalGroupSoulTx |

  All personal metrics are co-empty under the same `totalSoulTx = 0` trigger, simplifying UI conditional rendering.

### Best Joy Fallback (HAPPY-04 specific UX)

- **D-17 HAPPY-04 contract is simple — no extra Phase 9 logic for "all neutral" case.** As long as `totalSoulTx > 0`, return `Value(BestJoyMomentRow, sampleSize=totalSoulTx)`. Phase 10 UI inspects `topJoy.data.soulSatisfaction <= 2` and renders a CTA variant ("回去给最大那笔评个分让它变成你的本月最爱") instead of the standard story card. HappinessReport already carries enough info (`avgSatisfaction.data`, `totalSoulTx`, `topJoy.data.soulSatisfaction`) for UI to make this judgment with no Phase 9 contract surface change.

### HAPPY-09 Voice-Bias Path

- **D-18 HAPPY-09 is REMOVED from v1.1 scope.** REQUIREMENTS.md must be amended:
  - Remove HAPPY-09 from v1.1 active requirements list.
  - Move into v2 deferred items by extending `HAPPY-V2-03` (existing entry "Manual-only sub-metric variant if voice-bias proves problematic").
  - Update `HAPPY-V2-03` dependency note: "depends on `entry_source` column being added in a future schema migration"; Phase 9.0 verification step is no longer needed because the column has been confirmed absent.
  - v1.1 active REQ count: **26 → 25** (HAPPY: 9→8 items).
- ROADMAP.md Phase 9 critical pitfalls list must be updated to delete the "Voice-estimator +0.3 upward bias quantified by regression test; verify `transactions.entry_source` column exists in substep 9.0" item.
- Voice estimator output range realignment is also deferred (already noted in D-12).

### Joy Density Display

- **D-19 Joy/¥ stored as raw double (`MetricResult<double> joyPerYen`).** No display-unit normalization in the model — keeps the Freezed model decoupled from currency-specific presentation conventions.
- **D-20 New helper `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` provides locale-aware formatting:**
  ```dart
  const Map<String, double> _PTVF_BASE_BY_CURRENCY = {'JPY': 500.0, 'CNY': 25.0, 'USD': 5.0};
  const Map<String, ({double multiplier, String label})> _DISPLAY_UNIT_BY_CURRENCY = {
    'JPY': (multiplier: 1000.0, label: '/ ¥1k'),
    'CNY': (multiplier: 100.0,  label: '/ ¥100'),
    'USD': (multiplier: 1.0,    label: r'/ $1'),
  };
  double ptvfBaseFor(String currencyCode) => _PTVF_BASE_BY_CURRENCY[currencyCode] ?? 500.0;
  String formatJoyDensity(double rawDensity, String currencyCode) { /* ... */ }
  ```
  Both PTVF base and display unit are co-located in this helper; centralized maintenance for future currency additions (EUR, GBP, etc).
- **D-21 Headline metric tile selection is deferred to Phase 10 UI design.** Phase 9 contract provides 4 personal metric tiles equally; UI hierarchy and which tile is the "head" is a presentation concern.

### Architectural Decisions Records (ADRs)

- **D-22 Three new ADRs to be drafted in Phase 9** (planner assigns numbers, current max is ADR-011):
  1. **No Gamification v1.1** — ratifies HAPPY-07 spec ("no streaks / no badges / no daily targets / no cross-period comparisons / no public sharing of happiness metrics"). Goodhart's-Law defense binding through milestone close.
  2. **Joy Density PTVF Scaling** — documents α=0.88 (K-T 1979 empirical), base-by-currency table, Dart-layer rationale, performance trade-off vs SUM/GROUP BY principle.
  3. **Soul Satisfaction Unipolar Positive Scale** — documents the philosophy shift (every soul tx is happy at least at neutral level), default 5 → 2 schema migration, picker emoji semantic remap, default-vs-Neutral collision acceptance, post-launch voice estimator realignment plan.
- **D-23 Phase 12 drafts a fourth ADR** (planner assigns number): **Lexical Hierarchy v1.1** — documents 幸福 / happiness reserved for documentation; ときめき / 悦己 / Joy used in-product; 5 emoji labels under new mapping; CN family-mode 「家族的小确幸」 vs 「家族悦己」 disambiguation.

### Spec Amendments (Phase 9 plan tasks)

The following REQUIREMENTS.md and ROADMAP.md edits are part of Phase 9's deliverables (planner allocates them as plan units):
- **REQUIREMENTS.md**:
  - HAPPY-02 formula update (PTVF α=0.88 with currency-aware base, Dart-layer fold)
  - HAPPY-03 threshold ≥8 → ≥6
  - HAPPY-04 formula update (Pure sat sort, ¥500 floor removed)
  - HAPPY-08 emoji ↔ value mapping table (new unipolar positive semantic)
  - HAPPY-09 removed → folded into HAPPY-V2-03
  - FAMILY-01 threshold ≥8 → ≥6
- **ROADMAP.md** Phase 9 critical pitfalls list:
  - Remove ¥500 floor item (D-06)
  - Remove voice-bias regression test item (D-18)
  - Add "schema bump v15 → v16 for default 5 → 2" item
  - Add "PTVF α=0.88 with currency-aware base; Dart-layer fold; SUM/GROUP BY trade-off accepted" item
- **ROADMAP.md** Phase 12 scope expansion:
  - Add 5 emoji ARB labels rename to existing 4-key rename pass
  - Add picker Material icon update (emoji 1: very_dissatisfied → neutral)

### Claude's Discretion

- **DAO method naming, file split strategy, build_runner ordering** — planner decides per existing project convention (`get_monthly_report_use_case.dart` template pattern).
- **ADR numbering** — planner reads `docs/arch/03-adr/ADR-*.md`, picks next sequential numbers (ADR-012, 013, 014; Phase 12's draft = ADR-015 likely).
- **Test fixture strategy** — planner decides between hand-built fixtures, demo_data_service-derived fixtures, or new test_doubles for the 3 use cases. Should cover: n=0 (empty), n=1 (single tx), n=N mixed sat values, all-default sat=2, all sat=10, multi-currency PTVF base, FAMILY-02 min-N edge cases (no category meets, multiple tied).
- **Median computation strategy** (DAO returns raw distribution vs distinct method) — planner decides; recommend reusing `getSatisfactionDistribution` data and computing median in Dart use case layer.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project planning (always)
- `.planning/PROJECT.md` — Milestone v1.1 vision, locked constraints (no theme color changes, no enum rename, schema lock now partially relaxed for D-02), milestone insight ("10 元小確幸 vs 1000 元购物")
- `.planning/REQUIREMENTS.md` — Active REQ list (HAPPY-01..09 → 01..08 after D-18, FAMILY-01..03); v2 deferred items including HAPPY-V2-03
- `.planning/ROADMAP.md` — Phase 9 goal, dependencies, critical pitfalls (subject to amendments per D-22 spec amendments)
- `.planning/STATE.md` — Pending todos for Phase 9 (entry_source verification = closed by D-18; mean-vs-median = closed by D-21; Result<T> vs throw = matches existing analytics module convention per research)

### Phase 9 research (all four are HIGH or MEDIUM-HIGH confidence)
- `.planning/research/SUMMARY.md` — Cross-cutting findings (zero new deps, 9 micro-phases collapse to 4, dominant risks are semantic/cultural not technical)
- `.planning/research/ARCHITECTURE.md` — Layer placement (extend `features/analytics/`, NOT new `features/happiness/`), 3 use case structure, DAO additions, ARB blast radius, build order
- `.planning/research/PITFALLS.md` — Top items: survival-row contamination, ¥10 candy domination (now mooted by D-06), aggregate-only family contract, default-cluster annotation strategy
- `.planning/research/STACK.md` — Confirmation: zero new dependencies (`fl_chart 0.69`, `intl 0.20.2`, `package:collection 1.19.1` cover everything)
- `.planning/research/FEATURES.md` — Industry validation (JP competitors, CN UX patterns), anti-feature reasoning

### Architecture / spec docs
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Overall 5-layer architecture
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` — Drift schema patterns, encryption (note: BestJoyMomentRow deliberately omits `note` to skip field decryption)
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod conventions
- `docs/arch/02-module-specs/MOD-007_Analytics.md` (if present) — Analytics module conventions
- `docs/arch/03-adr/ADR-011_Codebase_Cleanup_Initiative_Outcome.md` — v1.0 cleanup outcomes that frame v1.1's starting state

### Key source files (must read for layer placement decisions)
- `lib/data/tables/transactions_table.dart` — Schema definition for `soul_satisfaction` (default change target)
- `lib/data/tables/books_table.dart` — `currency` column source (drives D-04 currency-aware base)
- `lib/data/daos/analytics_dao.dart` lines 230–327 — 3 dormant DAO methods (`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`); lines 1–86 — performance principle reference
- `lib/data/repositories/analytics_repository_impl.dart` — DAO→domain mapping pattern
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — Repository interface to extend
- `lib/features/analytics/domain/models/analytics_aggregate.dart` — Domain types pattern (extend with happiness aggregates)
- `lib/application/analytics/get_monthly_report_use_case.dart` — Use case template (the 3 new happiness use cases mirror this)
- `lib/application/analytics/repository_providers.dart` — Use case provider wiring (extend with 3 new use case providers)
- `lib/features/analytics/presentation/providers/state_analytics.dart` — Provider naming convention (`state_<aggregate>.dart`); new `state_happiness.dart` follows pattern
- `lib/features/home/presentation/providers/state_shadow_books.dart` — `shadowBooksProvider` to be reused for D-09 group books enumeration
- `lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart` — Picker writes ONLY {2, 4, 6, 8, 10}, basis for default-vs-picker collision analysis (D-10)
- `lib/application/voice/voice_satisfaction_estimator.dart` lines 185–188 — Voice output range [3, 10], deferred realignment in D-12
- `lib/features/home/presentation/screens/home_screen.dart` lines 345–367 — `_computeSatisfaction` and `_computeHappinessROI` helpers to be deleted in Phase 10 (NOT Phase 9)

### Project rules (CLAUDE.md and .claude/rules/)
- `CLAUDE.md` — Thin Feature rule, Placement Decision Rule, Drift TableIndex syntax, Riverpod provider rules, Common Pitfalls list
- `.claude/rules/arch.md` — ADR numbering protocol (ADR-XXX_Name.md, append-only after status `✅ 已接受`)
- `.claude/rules/coding-style.md` — Immutability, file size targets, error handling, input validation
- `.claude/rules/testing.md` — TDD workflow, ≥70% per-file coverage with `--deferred` mechanism
- `.claude/rules/security.md` — No hardcoded secrets, error message hygiene

### External / academic sources (for ADR citations)
- Kahneman & Tversky (1979). "Prospect Theory: An Analysis of Decision under Risk." *Econometrica*, 47(2), 263–292. — α=0.88 PTVF empirical fit (D-04, D-22.2)
- Stevens, S. S. (1957). "On the psychophysical law." *Psychological Review*, 64(3), 153–181. — Power law in psychophysics (referenced as "alternative to PTVF" in ADR-XXX_Joy_Density_PTVF_Scaling)
- Goodhart's Law (Goodhart, 1975) — "When a measure becomes a target, it ceases to be a good measure." Cited in No Gamification ADR.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`GetMonthlyReportUseCase`** (`lib/application/analytics/get_monthly_report_use_case.dart`) — exact template for the 3 new happiness use cases. Same shape: constructor-inject `AnalyticsRepository`, single `execute()` method, `Future.wait` parallelizes DAO calls, returns Freezed aggregate. Mirror precisely.
- **`AnalyticsRepository`** + **`AnalyticsRepositoryImpl`** — extend with 4 new method signatures (`getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getDailySatisfactionTrend`, `getBestJoyMoment`). Three of these have existing DAO methods to delegate to; only `getBestJoyMoment` is new.
- **`AnalyticsDao`** — already groups soul-satisfaction queries (lines 230–327). Add `getBestJoyMoment` as a new method in the same file; do NOT split into a new DAO.
- **`shadowBooksProvider`** (`lib/features/home/presentation/providers/state_shadow_books.dart:13`) — single source of truth for "books visible to the current user across the family group". `state_happiness.dart` reads via `ref.watch(shadowBooksProvider.future)` and passes the resolved `List<String>` to `GetFamilyHappinessUseCase`.
- **`isGroupModeProvider`** / **`activeGroupIdProvider`** (`lib/features/family_sync/presentation/providers/state_active_group.dart`) — gate the `familyHappinessProvider` short-circuit logic.
- **`SatisfactionEmojiPicker`** + **`VoiceSatisfactionEstimator`** — input pipeline untouched in Phase 9 (Phase 12 changes labels/icons; v1.2 may realign voice).
- **`AppTextStyles.amountLarge/Medium/Small`** (`lib/core/theme/app_text_styles.dart`) — `FontFeature.tabularFigures()` for monetary display; reuse for Joy/¥ density once formatted by helper.
- **`NumberFormatter`** / **`DateFormatter`** (`lib/infrastructure/i18n/formatters/`) — locale-aware formatting precedent. New `joy_density_formatter.dart` joins this directory.

### Established Patterns

- **Use Case Per Aggregate** — one use case class per Freezed aggregate, constructor-injected repos, single `execute()` method, `Future.wait` for parallel DAO queries. Applied 3 times: `GetHappinessReportUseCase`, `GetBestJoyMomentUseCase`, `GetFamilyHappinessUseCase`.
- **Container Widget With Async Provider** — widget receives the Freezed aggregate directly (not raw values), wrapped in `AsyncValue.when` from the parent screen. `SoulFullnessCard` will be rebuilt to take `HappinessReport report` (Phase 10 work, not Phase 9).
- **Dormant DAO Wiring** — three of the four required DAO methods already exist (verified at `analytics_dao.dart` lines 230–327). The "wiring" pattern: domain model counterpart → repository interface signature → repo impl translation → use case consumption.
- **Riverpod provider naming `state_<aggregate>.dart`** — convention verified (`state_home.dart`, `state_shadow_books.dart`, `state_today_transactions.dart`, `state_analytics.dart`, `state_active_group.dart`). New file: `state_happiness.dart`.
- **One repository_providers.dart per feature/domain** — single source of truth (CLAUDE.md rule). New use case providers in `lib/application/analytics/repository_providers.dart`. Do NOT duplicate provider definitions in `state_happiness.dart`.
- **Dart 3 sealed-class pattern matching** — `MetricResult<T>` consumed via `switch (result) { case Empty(): ... case Value(:final data, :final sampleSize): ... }`.

### Integration Points

- **Phase 9 → Phase 10 (HomePage)**: HomePage `home_screen.dart` will import `state_happiness.dart` from `features/analytics/presentation/providers/`. Same precedent already exists for `state_analytics.dart` (verified at `home_screen.dart:12`). Not a layer violation — both are presentation.
- **Phase 9 → Phase 11 (AnalyticsScreen)**: AnalyticsScreen extends to consume `joyDensityTrendProvider` and `satisfactionHistogramProvider` (Phase 11 implementation). Phase 9 lays the use cases that feed those providers.
- **Phase 9 → Phase 12 (ARB rename)**: Phase 12 expands scope to also rename 5 emoji ARB labels and update picker icon (D-11). Phase 9 does NOT touch ARB files.
- **`features/home` ↔ `features/family_sync`**: New family use case reads `activeGroupIdProvider` to short-circuit when no group is active. No new coupling created — same pattern as existing `MonthOverviewCard`.
- **Database schema**: One bump (v15 → v16) for default change. Drift's migration framework handles it; empty migration body is acceptable since no real data exists.

### Known forbidden patterns (CI-enforced or project policy)

- ❌ Adding `application/` or `data/` inside `features/happiness/` (would violate Thin Feature rule; `import_guard` rejects it).
- ❌ Reading `Transaction` model directly in HomePage to compute metrics (caused the `_computeSatisfaction` bug; metrics live in `application/analytics/`).
- ❌ Bypassing `AnalyticsRepository` and putting `getBestJoyMoment` directly on `TransactionRepository` (couples analytics to transaction encryption pipeline).
- ❌ Renaming ARB keys mid-milestone (forces broader edits + ARB-key-parity CI churn; Phase 12 only renames values, not keys).
- ❌ Conditionally subscribing family provider inside widget `build()` (fragile rebuild graphs; subscribe at screen level, provider short-circuits internally).
- ❌ `Map<MemberId, int>` or any per-member field in `FamilyHappiness` / `SharedJoyInsight` / `FamilyHighlightsSum` return shapes (anti-leaderboard contract; type-system enforced).

</code_context>

<specifics>
## Specific Ideas

These are particular references and product-philosophy moments from the discussion that anchor downstream judgment calls:

- **"虽然小东西会让人开心，但也要鼓励为了自己的开心花更多的钱"** — drove the HAPPY-04 Pure sat sort decision (D-06). Big intentional spending with high satisfaction must not be invisibly outranked by mid-rated small purchases. The amount-DESC tiebreak rewards "spending more for one's own happiness" without breaking the "10 is ceiling" constraint.

- **"现在没有用户使用"** — explicit signal that the v1.1 "no schema changes" lock is a prudent default rather than a hard constraint. Used to greenlight the schema bump v15 → v16 in D-02 / D-10. Pre-launch, schema migrations are cheap.

- **"让用户的每一笔灵魂支出都是幸福的"** — the product philosophy driving Path B (unipolar positive scale) decisions D-10, D-11, D-12. Soul spending is by definition something the user chose for joy; the scale should celebrate degrees of joy, not let users grade themselves negatively.

- **"现在没有后门"** — early discussion principle: do NOT bake user-friendly compensations (like "exclude default-5 rows") into the SQL fragment. Keep DAO data clean; compensate at the UI layer if needed. This is why `_soulOnly()` in D-01 does no satisfaction filtering despite the cluster-at-default issue.

- **PTVF α=0.88 (Kahneman & Tversky 1979)** — the user's "10000 的 10 是 50" intuition pointed toward power-law scaling. Comparison table with sqrt (α=0.5), log Weber-Fechner, and PTVF α=0.88 showed PTVF is the only formula in the candidate set that satisfies the user's stated outcome ("10-point ¥10000 should beat 6-point ¥500"). Critical α threshold ≈ 0.83; PTVF α=0.88 just clears it. This α=0.88 is the empirically-fitted constant from K-T's Nobel-recognized 1979 paper.

- **Currency-aware PTVF base** — user pointed out that the formula's base must scale with currency. Implementation reads `Book.currency` (verified in `books_table.dart:8`) to drive the lookup. Formula is "JPY-flavored" in spirit (base=¥500 represents "a typical small joyful purchase in JP"); CNY ¥25 and USD $5 are purchasing-power equivalents.

- **"先不要推进讨论"** moments — when the user asked to pause family formula discussion to revisit personal formulas (twice), and to dig into HAPPY-01 vs HAPPY-02 distinction. The 4 personal metrics' philosophy was the pivot that made all subsequent decisions cohere.

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-9 — comes back in Phase 10/11/12 (still v1.1)

- **HomePage `SoulFullnessCard` rebuild** → Phase 10. Including the CTA pattern detection (D-17) for "all neutral" Top Joy state.
- **AnalyticsScreen `JoyLedgerStatisticsSection`** → Phase 11. Joy/¥ trend line + satisfaction histogram + median tooltip on headline row. Median data is already provided by Phase 9 `medianSatisfaction` field (D-15).
- **5 emoji ARB labels rename + picker Material icon update** → Phase 12 (D-11).
- **ADR-XXX Lexical Hierarchy** drafted in Phase 12 (D-23).

### Out-of-v1.1 — v2 / future milestones

- **HAPPY-V2-03 (extended) Manual-only sub-metric variant for voice-bias** — depends on adding `entry_source` column in a future schema migration. Original HAPPY-09 spec absorbed here per D-18.
- **Voice estimator output range realignment** — voice currently outputs [3, 10]; under new picker mapping {2, 4, 6, 8, 10}, voice's odd values (3, 5, 7, 9) fall between picker buckets. Defer to v1.2 per D-12.
- **Voice +0.3 upward bias regression test** — also moved to post-launch concerns per D-18. Still a real concern but not blocking v1.1.
- **HAPPY-V2-01** (per-category satisfaction breakdown view) and **HAPPY-V2-02** (custom time windows) — already captured in REQUIREMENTS.md.
- **STATSUI-V2-01** (Soul-vs-Survival happiness comparison) — captured in REQUIREMENTS.md.
- **FAMILY-V2-01** (Top-3 SharedJoyInsight categories vs LIMIT 1) — captured in REQUIREMENTS.md.
- **FAMILY-V2-02** (Family conversation-prompt cards) — captured in REQUIREMENTS.md.
- **TOOL-V2-01** (`fl_chart 1.x` upgrade) and **TOOL-V2-02** (ARB key rename) — captured in REQUIREMENTS.md.
- **Multi-currency PTVF base extensions** (EUR, GBP, KRW, etc.) — not v1.1 scope; the helper map is structured for trivial extension when needed.
- **`_PTVF_BASE_BY_CURRENCY` map versioning / tuning** — if α=0.88 turns out empirically wrong for the JP market, the constant is centralized for easy future adjustment. Not v1.1 work.
- **Distinguishing "user tapped Neutral" from "user submitted without tapping"** — would require either an `is_rated` boolean column OR re-using DB sentinel value 1 for unrated (since picker writes 2/4/6/8/10 and voice outputs ≥3). Both are schema-level decisions; deferred to future milestones once a real product need surfaces.
- **`SatisfactionDistribution` median-as-DAO-method** (vs Dart-layer derivation) — performance optimization if monthly soul tx counts grow large. Not needed at expected v1.1 volumes.

### Forbidden anti-features (never to be added — captured for boundary-defense)

- ❌ **Per-member breakdown surfaces** (leaderboards, contribution charts) — produces toxic family dynamics; type-system enforced via `int`-only and `(catId, avg, count)`-only return shapes.
- ❌ **Streaks / badges / daily satisfaction targets** — Goodhart's Law, ratified by HAPPY-07 → ADR-XXX_No_Gamification_v1_1.
- ❌ **Cross-period delta on home tile** ("vs last month: +3.2 Joy points") — comparison anti-pattern; surfaces self-judgment dynamics.
- ❌ **Public sharing of happiness metrics** — privacy + comparison risks.

### Reviewed but not folded — none

`cross_reference_todos` step found 0 matching todos. STATE.md "Pending Todos" entries for Phase 9 are addressed by D-18 (entry_source check), D-21 (mean vs median), and matching the existing analytics module convention (`throw` not `Result<T>`, per research `get_monthly_report_use_case.dart` reading).

</deferred>

---

*Phase: 9-Happiness Domain & Formula Layer*
*Context gathered: 2026-05-01*
