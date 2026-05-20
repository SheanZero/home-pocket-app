# Phase 17: Manual-Only Joy Sub-Metric (HAPPY-V2-03) - Context

**Gathered:** 2026-05-20
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 17 ships a "manual-only" audit-lens view across the entire AnalyticsScreen by introducing a per-transaction `entry_source` column (schema bump v16 → v17), stamping it on every entry path, and adding an AnalyticsScreen-scoped toggle that switches every data card from "all entries" to "manual entries only".

**In scope:**
- Drift schema migration v16 → v17: add `transactions.entry_source` column (`TEXT NOT NULL DEFAULT 'manual'`, table-level `CHECK(entry_source IN ('manual','voice','ocr'))`).
- Dart enum `EntrySource { manual, voice, ocr }` in `lib/features/accounting/domain/models/` (sibling to `LedgerType`).
- Backfill: pre-launch project → all existing rows resolve to `'manual'` via the column-level DEFAULT; no separate UPDATE step.
- Entry-path stamping:
  - `CreateTransactionParams` gains `required EntrySource entrySource` (no default — caller must specify).
  - `TransactionConfirmScreen` gains `EntrySource entrySource` constructor param threaded into `CreateTransactionParams`.
  - `voice_input_screen.dart:352` push site passes `EntrySource.voice`.
  - `transaction_entry_screen.dart:225` push site passes `EntrySource.manual`.
  - `ocr_scanner_screen.dart` push site passes `EntrySource.manual` (MOD-005 not shipped; `ocr` enum value reserved but no live row in v1.2).
  - `demo_data_service.dart` `insertTransaction` calls (lines 103, 137) pass `EntrySource.manual`.
- Sync payload: `TransactionSyncMapper` (create-operation serialize/deserialize) carries `entry_source`; cross-device fidelity preserved. `entry_source` does NOT enter the hash chain (consistent with `soul_satisfaction`, avoids v1.1 hash re-derivation).
- Repository / DAO surface:
  - `TransactionRepository.insert` + `TransactionDao.insertTransaction` extended with `entrySource` parameter.
  - `AnalyticsDao` every Joy / window-keyed read method gains `EntrySource? entrySourceFilter` parameter (null → no extra predicate; non-null → `AND entry_source = ?` appended).
  - `_soulExpenseFilter` / `_survivalExpenseFilter` constants remain unchanged in shape; `entry_source` filter is added as an additional bound parameter, not by mutating the predicate-drift constant.
- Application layer: every AnalyticsScreen-feeding use case (see `<decisions>` D-10 list) accepts `EntrySource? entrySourceFilter` and threads it to the repository / DAO call.
- Presentation layer:
  - New provider `selectedJoyMetricVariantProvider` (`@riverpod` notifier) in `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart`, state = `JoyMetricVariant { all, manualOnly }`, default `all`, session-only.
  - New widget `JoyMetricVariantChip` in `lib/features/analytics/presentation/widgets/`, placed in `AnalyticsScreen` `AppBar.actions` directly to the right of `TimeWindowChip`; opens a bottom sheet (or popup — planner discretion) with 2 options.
  - `AnalyticsScreen._refresh()` extended to invalidate the same provider set when toggle changes; HomeHero / Home tab providers MUST NOT be invalidated (Phase 15 D-12 carry-forward).
- ARB additions (ja/zh/en parity): `analyticsJoyMetricVariantChipLabel`, `analyticsJoyMetricVariantSheetTitle`, `analyticsJoyMetricVariantOptionAll`, `analyticsJoyMetricVariantOptionManualOnly`, `analyticsJoyMetricVariantManualOnlyExplain`; `flutter gen-l10n` succeeds.
- ROADMAP SC-3 wording fix: the literal "Joy metrics (Σ joy_contribution, per-category breakdown, Soul-vs-Survival comparison)" understates the actual decision — the toggle affects all AnalyticsScreen surfaces (D-10). Plan-phase task #1 corrects SC-3 wording (pattern mirrors Phase 16 D-15).
- Tests:
  - Drift migration round-trip test v16 → v17 with deterministic backfill assertion.
  - Use-case unit tests for each affected use case asserting both `entrySourceFilter = null` (unchanged behavior) and `entrySourceFilter = EntrySource.manual` (filtered behavior).
  - Widget test: toggling `JoyMetricVariantChip` flips every observed card to filtered values; HomeHero card unaffected.
  - Forbidden-substring widget test across ja/zh/en (per Phase 16 D-14 pattern, extended with Phase 17 risk substrings — see D-08).
  - Integration test covering: manual entry → `entry_source='manual'`; voice entry → `entry_source='voice'`.

**Out of scope:**
- HomeHero behavior changes. HomeHero providers do NOT read `selectedJoyMetricVariantProvider`. Ring color, monthly reset, target recommendation, KPI tile — all unchanged (SC-4, Phase 13 D-09, Phase 14, Phase 15 D-12 carry-forward).
- `GetMonthlyJoyTargetRecommendationUseCase` filter participation. Recommendation stays universal (past 3 months median, all entries). Settings UI is not affected by AnalyticsScreen toggle.
- MOD-005 OCR scanner functional implementation. `ocr_scanner_screen.dart` exists as a shell and routes through `TransactionConfirmScreen`; Phase 17 only ensures the route is stamped as `'manual'` (`ocr` enum value is reserved at the type-system level but no production row receives it). When MOD-005 ships, an independent commit changes the OCR scanner push site to `EntrySource.ocr`.
- Per-family-member breakdown of voice vs manual entries — forbidden (ADR-012 §6).
- Persisting toggle across app restart — out of scope per Phase 15 D-12 session-only pattern; toggle resets to `all` on every cold start.
- Survival-ledger satisfaction picker — explicitly out of scope (ADR-014 D-10 / Phase 16 D-04).
- Any cross-period delta UI (e.g., "manual entries this month vs last month") — forbidden by ADR-012 §4.
- Per-book toggle state — toggle is global to AnalyticsScreen across active books.
- Schema bump beyond `entry_source` column; no other table changes.

</domain>

<decisions>
## Implementation Decisions

### Column Shape, Migration, and Backfill (Area 1)

- **D-01: `transactions.entry_source` is `TEXT NOT NULL DEFAULT 'manual'` with table-level `CHECK(entry_source IN ('manual','voice','ocr'))`.** Dart enum `EntrySource { manual, voice, ocr }` lives in `lib/features/accounting/domain/models/entry_source.dart` (or appended to an existing accounting domain enum file — planner discretion). The `ocr` enum value is reserved for MOD-005; Phase 17 does NOT produce any live `'ocr'` row.
  - **Why:** Two-value enum (`manual`/`voice`) would force an extra schema migration when MOD-005 ships; pre-reserving `ocr` keeps Phase 17 + MOD-005 ship paths independent. Symbolic asset cost (one un-stamped enum value) is small; schema-migration cost saved is meaningful.
  - **Migration semantics:** add the column via `migrator.addColumn(transactions, transactions.entrySource)` in the v16 → v17 block; declare the column in Drift table file with `text().withDefault(const Constant('manual'))()`; append `'CHECK(entry_source IN (\'manual\', \'voice\', \'ocr\'))'` to `customConstraints`. Planner verifies SQLite's ALTER TABLE ADD COLUMN expresses both DEFAULT and column-level CHECK natively; if not, a two-step migration (add column with DEFAULT, then table-rebuild for CHECK) is the fallback.

- **D-02: `entry_source` does NOT enter the hash chain.** `currentHash` continues to be computed from `id + amount + timestamp + prevHash` only (per `_hashChainService.calculateTransactionHash` in `create_transaction_use_case.dart:136-141`). This preserves v1.1's hash chain reverse-compatibility — no row's `currentHash` changes after the migration.
  - **Why:** Consistent with `soul_satisfaction` (Phase 9 / Phase 13 implicitly accepted that satisfaction is not hash-protected). Re-deriving v1.1 hashes would be invasive and would require an ADR amendment. The `entry_source` field is observational / audit-only — tamper resistance is a nice-to-have, not load-bearing.

- **D-03: Sync payload carries `entry_source`.** `TransactionSyncMapper.toCreateOperation` and the corresponding `fromCreateOperation` (deserialize path on the receiving device) serialize and respect the field. A voice transaction created on device A appears as `entry_source='voice'` on device B after sync; older-schema peers sending a payload without the field cause the receiving device to fall back to `'manual'` (the DEFAULT).
  - **Why:** SC-2 says voice path stamps `'voice'` and manual path stamps `'manual'` — this contract must hold across the family-sync surface or the manual-only filter becomes meaningless in group mode.

- **D-04: Pre-launch backfill semantics.** All existing rows resolve to `'manual'` via the column-level DEFAULT — no separate UPDATE statement, no heuristic backfill based on transaction metadata (none of which carries an "is from voice" signal today). Voice-keyword data lives only in `category_keyword_preferences` for learning, not on the transaction row itself.
  - **Why:** Pre-launch project per PROJECT.md / Phase 9 D-02 / Phase 13 D-01 — no production data to be honest about; demo/dev rows being labeled `'manual'` is a benign default that the next test pass can re-seed.

- **D-05: No new index by default on `entry_source`.** Existing `idx_tx_book_id`, `idx_tx_book_timestamp`, and `idx_tx_book_deleted` already prune the row set to typical 10–100 monthly soul tx per book; `entry_source` is a low-cardinality 1-of-3 secondary filter, so a dedicated index has negligible plan-cost benefit at v1.2 volumes. Planner re-evaluates after profiling on a seeded large book if real benchmarks suggest a `(book_id, entry_source)` composite would help.

### Voice-Stamping Touchpoint (Area 2)

- **D-06: `CreateTransactionParams` gains `required EntrySource entrySource`.** No default value — every caller must specify. This forces every entry-path screen to make an explicit decision and prevents silent regressions when new entry paths are added.
  - **Caller updates:**
    - `transaction_confirm_screen.dart:300` — receive `widget.entrySource` and thread it into `CreateTransactionParams`.
    - `voice_input_screen.dart:352` `MaterialPageRoute<void>(builder: (_) => TransactionConfirmScreen(... entrySource: EntrySource.voice ...))`.
    - `transaction_entry_screen.dart:225` `... entrySource: EntrySource.manual ...`.
    - `ocr_scanner_screen.dart:58` (or wherever the OCR scanner pushes to confirm) `... entrySource: EntrySource.manual ...` (v1.2 — see D-07).
  - **Why:** Threading the `voiceKeyword` sentinel (the current heuristic on line 252-259 of `transaction_confirm_screen.dart`) conflates input-channel awareness with category-learning — `voiceKeyword != null` happens to imply voice today but is not a future-proof contract. An explicit enum on the params is type-safe and self-documenting at every push site.

- **D-07: OCR scanner stamps `'manual'` in v1.2; MOD-005 changes it as a separate commit.** `ocr_scanner_screen.dart` is a UI shell that routes through `TransactionConfirmScreen`. Phase 17 ensures the route is stamped `'manual'`. When MOD-005 ships real OCR recognition, that phase's first commit updates the push site to `EntrySource.ocr`. Phase 17 does NOT pre-color `'ocr'` rows because no real OCR-derived data exists yet.

- **D-08: `demo_data_service.dart` `insertTransaction` calls (lines 103, 137) pass `EntrySource.manual`.** Demo / dev seed data is keyboard-style; `'manual'` is the honest label. If a future demo scenario simulates voice entries, the seed code changes locally without affecting production data semantics.

- **D-09: Sync-receive path falls back to `'manual'` for older-schema peers.** `TransactionSyncMapper.fromCreateOperation` reads the `entry_source` field if present; absent → DEFAULT `'manual'`. This makes Phase 17 backward-compatible with v1.1 devices in a family group; the audit filter just under-counts voice on the receiving side, which is acceptable (and the older peer would have logged voice itself).

### Toggle State + UI + ARB Copy (Area 3)

- **D-10 (split below for clarity — see "Filter Scope" section for D-10 narrative; here we record toggle semantics).** `selectedJoyMetricVariantProvider` is a session-scoped Riverpod notifier providing `JoyMetricVariant { all, manualOnly }`. Default is `all`. Session-only, not persisted — consistent with Phase 15 D-12 (`selectedTimeWindowProvider`). Cold-start resets to `all`.

- **D-11: Provider file lives at `lib/features/analytics/presentation/providers/state_joy_metric_variant.dart`.** Naming follows the `state_<aggregate>.dart` Riverpod convention used by `state_time_window.dart`, `state_analytics.dart`, `state_happiness.dart`, `state_ledger_snapshot.dart` in the same directory.

- **D-12: Toggle UI = `JoyMetricVariantChip` in `AppBar.actions`.** Placed directly to the right of `TimeWindowChip` (`analytics_screen.dart:70-73`). Tapping opens a bottom sheet or popup with two options (planner discretion); selection applies immediately and closes the sheet. The chip label reflects the current selection (localized "All" / "Manual only" via the new ARB keys).
  - **Why placement here:** the AppBar "scope chip" pattern is already established (TimeWindowChip); a sibling chip for "what counts" extends the same mental model. Distribution-section placement would surface the toggle deeper into the screen and bury its effect on KPI mini-hero / Stories.
  - **Concern:** AppBar may be crowded on narrow viewports. Planner verifies with the project's golden test viewport sizes; if it overflows, an overflow menu fallback is acceptable (still in `AppBar.actions`).

- **D-13: ARB additions.** Five new keys, all with ja/zh/en parity:
  - `analyticsJoyMetricVariantChipLabel` — chip text (likely shows current selection).
  - `analyticsJoyMetricVariantSheetTitle` — bottom sheet / popup title.
  - `analyticsJoyMetricVariantOptionAll` — "All entries" label.
  - `analyticsJoyMetricVariantOptionManualOnly` — "Manual entries only" label.
  - `analyticsJoyMetricVariantManualOnlyExplain` — one-line explanation copy attached to the option in the sheet (e.g., "Excludes voice-estimated entries").
  - **Anchor wording (planner refines but stays within this register):**
    - en: `Manual entries only · excludes voice-estimated entries`
    - ja: `手動入力のみ · 音声推定を除外`
    - zh: `仅手动输入 · 不含语音估算条目`
  - **Reuse:** existing `manualInput` / `voiceInput` keys are NOT reused for the toggle, because their semantic is "input method label" — using them for "metric variant" creates lexical drift.

- **D-14: Forbidden-substring list extension (anti-toxicity).** Phase 16 D-14 minimum list applies; Phase 17 adds risk substrings specific to "voice is less valid" framing:
  - en: `less accurate`, `invalid`, `unreliable`, `less valid`, `estimated` (in a value-judgment context), `inaccurate`, `wrong`
  - ja: `不正確`, `信頼できない`, `不完全`, `精度が低い`, `誤り`
  - zh: `不准`, `不可靠`, `不完整`, `质量差`, `估算不准`, `错误`
  - The widget test asserts that, across ja/zh/en, none of the Phase 17 rendered surfaces (chip label, sheet, explanation copy) contains any forbidden substring. Phase 16's existing widget test infrastructure is the precedent.

### Filter Scope + DAO Plumbing (Area 4)

- **D-15: Manual-only is a WHOLE-AnalyticsScreen audit lens, not a Joy-only filter.** When `selectedJoyMetricVariantProvider = manualOnly`, the following surfaces ALL re-query with `entry_source='manual'`:
  - KPI mini-hero (`KpiMiniHeroStrip`) — total / soul / Joy cells.
  - 6-month trend (`MonthlySpendTrendBarChart` / `_TotalSixMonthCard`) — even though Phase 15 D-10 keeps this rolling-6-month and out of TimeWindow's authority, it DOES respect the joy-metric-variant filter under D-15. The two-axis behavior (window-immune, variant-aware) is intentional and matches the "manual-only mode = audit mode for the whole AnalyticsScreen" framing.
  - Category donut (`_CategoryDonutCard`).
  - Soul-vs-Survival card (`SoulVsSurvivalCard`) — BOTH Soul and Survival columns filter on `entry_source='manual'` (count, spend, and where applicable avg sat).
  - Satisfaction histogram (`_SatisfactionHistogramOrFallback`).
  - Per-category breakdown card (`PerCategoryBreakdownCard`) + group-mode "Family" stacked card.
  - Best Joy story strip (`BestJoyStoryStrip`).
  - Largest expense story (`LargestExpenseStoryCard`).
  - Family insight card (`FamilyInsightCard`).
- **NOT filtered (explicit exclusions):**
  - `GetMonthlyJoyTargetRecommendationUseCase` — Settings UI consumes this; not under AnalyticsScreen toggle authority. Target recommendation stays universal (past 3 months median over all entries).
  - HomeHero — every HomeHero provider ignores `selectedJoyMetricVariantProvider`. The provider hierarchy stays as it is today; Phase 17 does not introduce any read of the toggle in HomeHero code paths.

- **D-16: ROADMAP SC-3 wording correction is plan-phase task #1.** SC-3 currently reads "...all Joy metrics (Σ joy_contribution, per-category breakdown, Soul-vs-Survival comparison) re-query with `entry_source = 'manual'` filter." Per D-15, this understates the actual scope. Suggested replacement: *"When manual-only is selected, every data card on AnalyticsScreen re-queries with `entry_source = 'manual'` filter (including total spend / category distribution / 6-month trend / largest expense / Soul-vs-Survival both columns). HomeHero and Settings recommendation remain unaffected (SC-4)."* Plan-phase rewrites SC-3 in `.planning/ROADMAP.md` as its first task (pattern mirrors Phase 16 D-15).

- **D-17: DAO plumbing — each affected `AnalyticsDao` method gains `EntrySource? entrySourceFilter` parameter.** When null → no extra predicate. When non-null → append `AND entry_source = ?` with the enum's `.name` as a bound parameter (safe SQL injection-wise; parameter-bound). The `_soulExpenseFilter` / `_survivalExpenseFilter` constants remain unchanged in their string content — `entry_source` enters as a separate appended clause, not by mutating the predicate constant. This preserves the "single source of truth" defense for the soul/survival predicate.
  - **Affected DAO methods (planner verifies and adds parameter):**
    - `getMonthlyTotals`, `getCategorySpend` (and the trend equivalent for 6-month) — non-Joy but D-15 covers them.
    - `getSoulSatisfactionOverview`, `getSatisfactionDistribution`, `getBestJoyMoment`, `getLargestMonthlyExpense`, `getSoulRowsForJoyContribution`, `getSoulRowsForJoyContributionAcrossBooks`, `getPerCategorySoulBreakdown`, `getPerCategorySoulBreakdownAcrossBooks`, `getSharedJoyCategoryInsight`, family-side aggregates.
    - The exact list of touched DAO methods is planner discretion; the rule is: any AnalyticsDao method consumed by an AnalyticsScreen card gains the parameter.
  - **Repository / Use Case propagation:** every use case that ends up reading from those DAO methods exposes the same `EntrySource? entrySourceFilter` parameter on its `execute(...)` signature; providers in `state_*.dart` resolve the current `selectedJoyMetricVariantProvider` to `EntrySource? = manualOnly ? EntrySource.manual : null` and pass it through.

- **D-18: `_refresh()` invalidation extension.** `analytics_screen.dart` `_refresh(...)` invalidates the same provider set as today (window-keyed Joy + non-Joy providers); it does NOT additionally invalidate on toggle change because Riverpod automatically invalidates window-keyed family providers when their key (which now includes the variant) changes. Provider families that consume the toggle should fold `selectedJoyMetricVariantProvider` into their family key (e.g., `(bookId, startDate, endDate, joyMetricVariant)`).
  - **HomeHero / Home tab providers MUST NOT be invalidated by AnalyticsScreen refresh** — Phase 15 D-12 carry-forward.

### Claude's Discretion (planner picks within these boundaries)

- **Exact placement of `EntrySource` enum file.** Recommended: `lib/features/accounting/domain/models/entry_source.dart` as a sibling to `transaction.dart`'s `LedgerType` enum. If the project pattern is to co-locate enums in `transaction.dart`, append it there. Either is acceptable.
- **Bottom sheet vs popup for `JoyMetricVariantChip`.** Bottom sheet is consistent with `MonthChipPicker` / `TimeWindowPickerSheet` (`time_window_chip.dart`); a lightweight `PopupMenuButton` is acceptable if it fits AppBar density better. Planner picks per project UX pattern.
- **Exact ARB key wording.** D-13 anchors are guidance, not commands. Planner produces final wording reviewed against D-14 forbidden-substring list.
- **DAO method signature ordering for the new parameter.** Recommended: place `entrySourceFilter` after the time-range parameters (`startDate`, `endDate`) and before any "limit / sort" parameters; null-default to make most existing call sites compile without changes if any are not yet wired to the toggle.
- **Group-mode wiring of `entrySourceFilter`.** Use cases that take `bookIds: List<String>` (across-books variants) accept the same `EntrySource?` parameter; the across-books DAO methods (`getSoulRowsForJoyContributionAcrossBooks`, `getPerCategorySoulBreakdownAcrossBooks`, family aggregates) get the parameter the same way as single-book methods.
- **Migration test fixture strategy.** Recommend extending the existing Drift migration test pattern (locate the v15 / v16 test if one exists in `test/data/`) with a v16 → v17 round-trip; assert pre-migration row gains `entry_source='manual'` and new inserts respect the CHECK constraint.
- **Per-screen unit tests.** Each affected use case gets a unit test asserting unchanged behavior with `entrySourceFilter = null` and filtered behavior with `entrySourceFilter = EntrySource.manual`. Existing test files (`test/unit/application/analytics/*_test.dart`) are extended; no new top-level test files unless a new use case is added.
- **Provider family key.** Recommended: providers consuming the toggle declare `family` with key `(bookId, startDate, endDate, joyMetricVariant)`. Planner verifies Riverpod 3 family-key invalidation semantics for this combined key.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Planning
- `.planning/PROJECT.md` — v1.2 milestone goal, HAPPY-V2-03 listed as one of the v1.2 targets, MOD-005 OCR explicitly deferred out of v1.2 (relevant because Phase 17 reserves `ocr` enum value but does NOT ship MOD-005).
- `.planning/REQUIREMENTS.md` — HAPPY-V2-03 requirement (manual-entry-only Joy sub-metric variant), cross-phase constraints (ADR-012, ADR-014, ADR-016 §3 HomeHero immutability, ADR-013 append-only, CI guardrails, i18n parity).
- `.planning/ROADMAP.md` — Phase 17 Goal + 5 Success Criteria. **Plan-phase task #1 corrects SC-3 wording** per D-16 above.
- `.planning/STATE.md` — Current milestone position; Phase 16 close decisions including FamilyInsightCard precedent, the no-invalidation-of-HomeHero rule, and the Distribution section group layout.

### Prior Phase Hand-Off
- `.planning/phases/13-adr-016-backend-foundation/13-CONTEXT.md` — `Σ joy_contribution` backend, MetricResult contract, `getSoulRowsForJoyContribution` DAO pattern, soul-only ledger filter. **Phase 13 D-09 closing note** explicitly anticipates Phase 17's `entry_source` filter parameter being added to the recommendation use case — Phase 17 OVERRIDES that note (D-15 keeps the recommendation universal).
- `.planning/phases/14-adr-016-frontend-arb-reconciliation-tool-v2-02/14-CONTEXT.md` — Variant ε layout, KPI mini-hero, "Joy Index / 悦己指数 / ときめき指数" product vocabulary, HomeHero ring immutability that Phase 17 inherits.
- `.planning/phases/15-custom-time-windows-happy-v2-02/15-CONTEXT.md` — `selectedTimeWindowProvider` session-scoped pattern (Phase 17 mirrors with `selectedJoyMetricVariantProvider`), `(startDate, endDate)` use-case migration, HomeHero / Home tab invalidation isolation rule, `_refresh()` invalidation pattern, `MonthChipPicker` → `TimeWindowChip` evolution that Phase 17 extends with a second chip.
- `.planning/phases/16-per-category-breakdown-soul-vs-survival-comparison-happy-v2-/16-CONTEXT.md` — Soul-vs-Survival re-framed as engagement axis (D-01..D-04 carry forward — Phase 17 D-15 filters BOTH columns under manual-only mode, preserving that engagement-axis framing); per-category breakdown card structure (D-06..D-10 carry forward); ROADMAP wording correction pattern (D-15) — Phase 17 D-16 follows the same pattern; forbidden-substring widget test infrastructure (D-14) — Phase 17 D-14 extends it.

### Architecture / ADRs
- `docs/arch/03-adr/ADR-016_Joy_Metric_Visualization_Redesign.md` §3 — HomeHero remains current-month-anchored, MUST NOT respond to AnalyticsScreen filters. §5 — 100% behavior contract (no discrete events) extends to Phase 17 (e.g., the toggle MUST NOT trigger a celebration when manual-only Joy crosses target). §7 — Phase 13 must-haves checklist gives the use-case structure Phase 17 extends.
- `docs/arch/03-adr/ADR-012_No_Gamification_v1_1.md` §4 — no cross-period delta UI (Phase 17 does NOT surface "manual-only this month vs last month" comparisons); §6 — per-family-member breakdown forbidden (Phase 17 does NOT introduce per-member voice-vs-manual surfaces); §2/§5/§7 also load-bearing for any AnalyticsScreen copy near the toggle.
- `docs/arch/03-adr/ADR-014_Soul_Satisfaction_Unipolar_Positive_Scale.md` — `soul_satisfaction` default = 2, soul-only picker semantics; Phase 17 does NOT introduce a survival picker; the manual-only filter respects ADR-014's soul-only-picker rule (survival rows still have default `2` regardless of manual / voice — the toggle filters which rows participate, not their satisfaction semantics).
- `docs/arch/03-adr/ADR-013_Joy_Density_PTVF_Scaling.md` — PTVF α=0.88 per-tx formula still active (cited by ADR-016 §2); Phase 17 does NOT change the formula; manual-only just filters which rows feed into the Σ.
- `docs/arch/01-core-architecture/ARCH-001_Complete_Guide.md` — Clean Architecture / Thin Feature rules; new providers live in `lib/features/analytics/presentation/providers/`; new domain enum lives in `lib/features/accounting/domain/models/`; use cases extend in `lib/application/analytics/`; DAO + repository changes in `lib/data/`.
- `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md` — Drift schema patterns; specifically, schema bump procedure (precedent: v15 → v16 in Phase 13 D-01..D-10) and migration testing.
- `docs/arch/01-core-architecture/ARCH-003_Security_Architecture.md` — Hash chain semantics; Phase 17 does NOT modify the hash input set (D-02 explicitly excludes `entry_source` from hash, consistent with `soul_satisfaction`).
- `docs/arch/01-core-architecture/ARCH-004_State_Management.md` — Riverpod 3 conventions; `state_<aggregate>.dart` naming (Phase 17 adds `state_joy_metric_variant.dart`).

### Source Integration Points
- `lib/data/tables/transactions_table.dart:5-52` — `Transactions` table; add `TextColumn get entrySource => text().withDefault(const Constant('manual'))();` and append `'CHECK(entry_source IN (\'manual\', \'voice\', \'ocr\'))'` to `customConstraints`. No new index by default (D-05).
- `lib/data/app_database.dart:45` — `schemaVersion = 16` → bump to `17`. Add `if (from < 17) { await migrator.addColumn(transactions, transactions.entrySource); }` in the migration block (between the existing `if (from < 16)` block and the closing brace).
- `lib/data/daos/transaction_dao.dart:11-55` — `insertTransaction` gains `required String entrySource` parameter (or `required EntrySource entrySource` if the DAO accepts the enum directly — planner picks per Drift convention); the `Companion` insert includes the new field.
- `lib/data/daos/analytics_dao.dart` — every method consumed by an AnalyticsScreen card gains an `EntrySource? entrySourceFilter` parameter (D-17 list).
- `lib/data/repositories/transaction_repository_impl.dart:29` — `insert(...)` calls `_dao.insertTransaction(... entrySource: transaction.entrySource.name ...)` (Drift DAO stores string; domain layer holds enum).
- `lib/features/accounting/domain/models/transaction.dart:11-46` — `Transaction` Freezed model gains `required EntrySource entrySource` field; `EntrySource` enum is added either in the same file (sibling to `LedgerType`) or in a new `entry_source.dart` (planner discretion).
- `lib/features/accounting/domain/repositories/transaction_repository.dart` — abstract `insert` signature updates implicitly via the Transaction model; no signature change at the repository interface level.
- `lib/application/accounting/create_transaction_use_case.dart:14-37` (`CreateTransactionParams`) — add `required EntrySource entrySource` field. Lines 144-159 (Transaction construction) thread it into the new `Transaction(... entrySource: params.entrySource ...)` field. Hash chain calculation lines 132-141 unchanged (D-02).
- `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — class constructor adds `required EntrySource entrySource` param (around line 29-44); line 300 `CreateTransactionParams(... entrySource: widget.entrySource ...)` threads it.
- `lib/features/accounting/presentation/screens/voice_input_screen.dart:352` — push `MaterialPageRoute<void>(builder: (_) => TransactionConfirmScreen(... entrySource: EntrySource.voice ...))`.
- `lib/features/accounting/presentation/screens/transaction_entry_screen.dart:225` — push with `entrySource: EntrySource.manual`.
- `lib/features/accounting/presentation/screens/ocr_scanner_screen.dart` — push site (locate via grep — currently `EntryModeSwitcher` on line 58 references `InputMode.ocr` but the actual transaction confirm push is downstream); confirms with `entrySource: EntrySource.manual` (v1.2 — see D-07).
- `lib/application/analytics/demo_data_service.dart:103,137` — `transactionDao.insertTransaction(... entrySource: 'manual' ...)` (or enum if the DAO accepts the enum directly).
- `lib/features/analytics/presentation/screens/analytics_screen.dart:66-180` — extend `AppBar.actions` to include `JoyMetricVariantChip` right of `TimeWindowChip` (around line 70-73); extend the cards' provider calls to also key on `joyMetricVariant`; `_refresh()` invalidates the variant-aware provider set.
- `lib/features/analytics/presentation/providers/state_*.dart` — every state file that consumes a DAO method affected by D-17 reads `selectedJoyMetricVariantProvider` and threads `EntrySource? entrySourceFilter` into its use case calls. Provider family keys updated accordingly.
- `lib/features/analytics/presentation/providers/state_time_window.dart:7-21` — precedent for the new `selectedJoyMetricVariantProvider`; same `@riverpod` notifier pattern, session-only state.
- `lib/features/analytics/presentation/widgets/time_window_chip.dart` — precedent for `JoyMetricVariantChip` shape (chip + bottom sheet).
- `lib/application/family_sync/sync_engine.dart` and `lib/features/accounting/domain/models/transaction_sync_mapper.dart` — `entry_source` enters the sync payload encoding (D-03). Locate `TransactionSyncMapper.toCreateOperation` and the receiving deserialize path; both extended.
- `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb` — add the five new keys (D-13) in trilingual lockstep.
- `lib/generated/app_localizations*.dart` — regenerated via `flutter gen-l10n`; do not hand-edit.

### Project Rules (CLAUDE.md and .claude/rules/)
- `CLAUDE.md` — Thin Feature rule; Riverpod 3 conventions including `flutter_riverpod/legacy.dart` boundary; Drift TableIndex syntax (no new index per D-05); the iOS Podfile `-lsqlite3` strip is unchanged (Phase 17 does not touch native libs). Common pitfall #3 — code-gen REQUIRED after `@freezed` / `@riverpod` / Drift table changes (Phase 17 touches all three).
- `.claude/rules/arch.md` — no new ADR in Phase 17 (Phase 17 implements existing ADR boundaries: ADR-014 picker semantics, ADR-016 §3 HomeHero immutability, ADR-012 §4 no cross-period delta).
- `.claude/rules/coding-style.md` — immutability, `copyWith`, file size targets; the new `EntrySource` enum and the use-case parameter additions follow immutable / explicit-parameter patterns.
- `.claude/rules/testing.md` — TDD workflow; per-file coverage ≥70% (CI gate per REQUIREMENTS.md Cross-Phase Constraints); migration round-trip test is a new test type for Phase 17 vs prior phases.
- `.claude/rules/worklog.md` — Phase 17 close requires a `doc/worklog/YYYYMMDD_HHMM_*.md` entry.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- **`selectedTimeWindowProvider`** (`lib/features/analytics/presentation/providers/state_time_window.dart`) — direct template for `selectedJoyMetricVariantProvider`. Same `@riverpod` notifier pattern, session-only state, no persistence wiring.
- **`TimeWindowChip`** (`lib/features/analytics/presentation/widgets/time_window_chip.dart`) — direct template for `JoyMetricVariantChip`. Same AppBar.actions placement, same chip + bottom sheet (or popup) pattern.
- **`_soulExpenseFilter` / `_survivalExpenseFilter` constants** (`analytics_dao.dart:104,113`) — predicate-drift defense from Phase 16; Phase 17 preserves them unchanged and appends `entry_source` filter as a separate clause (D-17).
- **`MetricResult<T>` sealed type** — usable for any new use case return that wraps `(soul tx count, joy_contribution)` in the manual-only variant; existing use cases keep their return shapes.
- **Drift migration block** (`app_database.dart:48-272`) — well-established `if (from < N)` chain. Phase 13's v15 → v16 was a no-op DDL (default value change at companion layer); Phase 17's v16 → v17 is a real `addColumn` migration with a CHECK constraint — closer in shape to v10 → v11 (`books.isShadow`, `books.groupId`, etc.).
- **`TransactionSyncMapper.toCreateOperation`** — extension point for sync payload field addition (D-03).
- **Forbidden-substring widget test infrastructure** (Phase 16 D-14) — directly reusable for D-14 trilingual assertion; just extend the substring list per locale.

### Established Patterns

- **`@riverpod` notifier session-only state pattern** for AnalyticsScreen-scoped selectors (Phase 15 D-12, Phase 17 D-10/D-11). No `prefs` involved; cold-start reset is the contract.
- **AppBar chip + bottom sheet** for "scope" affordances (`TimeWindowChip` precedent). Phase 17 `JoyMetricVariantChip` follows.
- **`(bookId, startDate, endDate)` family key** for window-keyed analytics providers; Phase 17 extends to `(bookId, startDate, endDate, joyMetricVariant)`.
- **DAO method gains an optional filter parameter** (Phase 16 added `bookIds: List<String>` for across-books variants). Phase 17's `EntrySource? entrySourceFilter` follows the same shape — null = "no extra filter".
- **Trilingual ARB parity + `S.of(context)` + `DateFormatter`/`NumberFormatter`** rules unchanged.
- **HomeHero / Home tab provider isolation from AnalyticsScreen state changes** (Phase 15 D-12); Phase 17 inherits the rule.
- **ROADMAP wording correction as plan-task #1** (Phase 16 D-15 pattern) — Phase 17 D-16 follows.

### Integration Points

- **Drift migration:** schema 16 → 17 adds `transactions.entry_source` column with DEFAULT 'manual' and CHECK constraint; round-trip test verifies pre-migration row count + post-migration `entry_source` default.
- **Transaction model layer:** `Transaction` Freezed model gains `EntrySource entrySource` field; `copyWith` and `toJson`/`fromJson` regenerate via `build_runner`.
- **Create-transaction use case:** `CreateTransactionParams` gains `required EntrySource entrySource`; the use case threads it through unchanged hash chain logic.
- **Entry path screens:** 4 push sites (voice, manual, OCR, demo) explicitly pass the enum.
- **Sync layer:** `TransactionSyncMapper` extended (D-03); cross-device payload carries `entry_source`.
- **AnalyticsScreen:** new chip widget; new provider; existing providers' family keys extended; `_refresh()` invalidation logic touched (HomeHero / Home tab providers explicitly NOT invalidated by toggle change).
- **AnalyticsDao:** each method consumed by an AnalyticsScreen card gains `EntrySource? entrySourceFilter`; SQL composition appends `AND entry_source = ?` when non-null.
- **HomeHero / Settings recommendation:** explicitly DO NOT read `selectedJoyMetricVariantProvider`. The "no invalidation" rule from Phase 15 D-12 is now also a "no read" rule for the toggle.

</code_context>

<specifics>
## Specific Ideas

- **The toggle is a WHOLE-AnalyticsScreen audit lens, not a "Joy KPI footnote".** This is the load-bearing decision of Phase 17 (D-15). Downstream agents that read SC-3's literal "Joy metrics" wording will under-implement the filter scope; D-15 + D-16 (ROADMAP rewrite) prevent that.
- **`entry_source` is a Dart enum `EntrySource { manual, voice, ocr }`, with `ocr` reserved but unused in v1.2.** Pre-emptively shaping the enum avoids a schema-migration churn when MOD-005 ships. The `ocr` value MUST NOT be stamped on any production row in Phase 17 (D-07).
- **`CreateTransactionParams.entrySource` is required, no default.** Every push site explicitly declares its source. The implicit-default option ("manual unless specified") was rejected because it makes silent regressions easy — adding a new entry path that forgets to specify would silently stamp `'manual'`.
- **HomeHero is sacred — neither reads the toggle nor is invalidated by it.** Phase 13 D-09 + Phase 14 + Phase 15 D-12 + ADR-016 §3 are all upstream forces. Phase 17 explicitly recommits to this rule for the toggle interaction.
- **`GetMonthlyJoyTargetRecommendationUseCase` does NOT participate in the filter.** Settings UI is a separate consumer with universal recommendation semantics. Phase 13 D-09 closing note suggested adding `entrySourceFilter` to the recommendation — Phase 17 explicitly OVERRIDES that note. Plan-phase must NOT add the parameter to the recommendation use case.
- **The toggle persistence is session-only.** Cold start resets to `all`. This is intentional — the toggle is an audit-mode side-trip, not the default state of the app.
- **Forbidden substrings are not optional.** D-14 names trilingual minimums per locale; the widget test will catch a slipped-in "less accurate" or "不正確" or "不可靠" before merge. Failure modes are otherwise silent.
- **MOD-005 ship lane is explicitly preserved.** Phase 17 does NOT pre-write OCR-stamping code; MOD-005's first commit changes `ocr_scanner_screen.dart`'s push site to `EntrySource.ocr`. Phase 17 ships with the OCR scanner pushing `'manual'`.

</specifics>

<deferred>
## Deferred Ideas

### Out-of-Phase-17 — future v1.2 / v1.3+ candidates

- **Per-family-member voice-vs-manual breakdown** — permanently forbidden (ADR-012 §6).
- **Toggle persistence across app restart** — out of scope per session-only design (D-10). v1.3+ may reconsider if user research shows people consistently re-enable the toggle on every cold start.
- **OCR-only Joy variant** (third toggle state when MOD-005 ships) — out of scope; Phase 17 designs the enum to accept three values but the toggle is binary (`all` / `manualOnly`). When MOD-005 ships, the toggle UI may expand to 3 segments (`all` / `manualOnly` / `excludeOcr` etc.) — that is a new design discussion, not a Phase 17 deliverable.
- **`entry_source` filter for Settings recommendation** — explicitly REJECTED in Phase 17 (D-15). Future phases could reopen if user research shows the universal recommendation feels biased by voice-heavy past months — but that would warrant a fresh ADR exploration.
- **Per-book toggle state** — toggle is global to AnalyticsScreen in Phase 17. Multi-book scenarios with different audit profiles per book are deferred.
- **`entry_source` audit log surface** (e.g., "your manual / voice ratio over the past quarter") — out of scope. Phase 17 is a filter, not a meta-statistic.
- **Hash-chain inclusion of `entry_source`** — explicitly REJECTED in Phase 17 D-02 to preserve v1.1 hash continuity. Reopening this would warrant an ADR addressing migration of the entire hash chain.
- **`entry_source` index** — D-05 says no. Phase 17 may add after profile-driven evidence; otherwise wait for v1.3+.

### Out-of-v1.2

- **MOD-005 OCR functional implementation** — Phase 17 reserves the `ocr` enum value but ships no live `'ocr'` row. MOD-005 changes `ocr_scanner_screen.dart` push site as its own first commit.
- **TOOL-V2-01 fl_chart 1.x upgrade** — explicitly out of v1.2 per `.planning/REQUIREMENTS.md` v2-deferred row; Phase 17 does NOT touch chart stack.
- **FAMILY-V2-01/02/03 family privacy hardening** — explicitly out of v1.2 per PROJECT.md; Phase 17 does NOT introduce family-axis features beyond the existing aggregate-only model.

### Reviewed Todos (not folded)

`cross_reference_todos` returned 0 matches for Phase 17. The remaining v1.1 verification debt (Phase 11 device/simulator UAT) is unrelated to Phase 17 scope.

</deferred>

---

*Phase: 17 — Manual-Only Joy Sub-Metric (HAPPY-V2-03)*
*Context gathered: 2026-05-20*
