# Roadmap: Home Pocket

## Milestones

- ✅ **v1.0 Codebase Cleanup Initiative** — Phases 1-8 (shipped 2026-04-29) — see [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v1.1 Happiness Metric & Display** — Phases 9-12 (shipped 2026-05-05) — see [archive](milestones/v1.1-ROADMAP.md)
- ✅ **v1.2 Happiness Metric Refresh** — Phases 13-17 (shipped 2026-05-21) — see [archive](milestones/v1.2-ROADMAP.md)
- ✅ **v1.3 迭代帐本输入** — Phases 18-23 (shipped 2026-05-26) — see [archive](milestones/v1.3-ROADMAP.md)
- 🚧 **v1.4 列表功能** — Phases 24-30 (in progress)

## Phases

<details>
<summary>✅ v1.0 Codebase Cleanup Initiative (Phases 1-8) — SHIPPED 2026-04-29</summary>

- [x] Phase 1: Audit Pipeline + Tooling Setup (8/8 plans) — completed 2026-04-25
- [x] Phase 2: Coverage Baseline (4/4 plans) — completed 2026-04-26
- [x] Phase 3: CRITICAL Fixes (5/5 plans) — completed 2026-04-26
- [x] Phase 4: HIGH Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 5: MEDIUM Fixes (5/5 plans) — completed 2026-04-27
- [x] Phase 6: LOW Fixes (6/6 plans) — completed 2026-04-27
- [x] Phase 7: Documentation Sweep (6/6 plans) — completed 2026-04-28
- [x] Phase 8: Re-Audit + Exit Verification (8/8 plans) — completed 2026-04-28

**Outcome:** REAUDIT-DIFF.json reports `resolved=50, regression=0, new=0, open_in_baseline=0`. 4 permanent CI guardrails active. Full details: `.planning/milestones/v1.0-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.1 Happiness Metric & Display (Phases 9-12) — SHIPPED 2026-05-05</summary>

- [x] Phase 9: Happiness Domain & Formula Layer (14/14 plans) — completed 2026-05-02
- [x] Phase 10: HomePage SoulFullnessCard Redesign (13/13 plans) — completed 2026-05-03
- [x] Phase 11: AnalyticsScreen Unified Dashboard (8/8 plans) — completed 2026-05-04
- [x] Phase 12: UI Copy Rename Pass (5/5 plans) — completed 2026-05-04

**Outcome:** v1.1 delivered the happiness metric domain, integrated HomeHeroCard, Variant δ AnalyticsScreen, trilingual Joy/Daily ledger copy rename, and accepted ADR-015 lexical hierarchy. One Phase 11 human UAT verification item is acknowledged as deferred at close in `.planning/STATE.md`. Full details: `.planning/milestones/v1.1-ROADMAP.md`.

</details>

<details>
<summary>✅ v1.2 Happiness Metric Refresh (Phases 13-17) — SHIPPED 2026-05-21</summary>

- [x] Phase 13: ADR-016 Backend Foundation (7/7 plans) — completed 2026-05-19
- [x] Phase 14: ADR-016 Frontend + ARB Reconciliation (6/6 plans) — completed 2026-05-19
- [x] Phase 15: Custom Time Windows (6/6 plans) — completed 2026-05-19
- [x] Phase 16: Per-Category Breakdown + Soul-vs-Survival (10/10 plans) — completed 2026-05-20
- [x] Phase 17: Manual-Only Joy Sub-Metric (8/8 plans) — completed 2026-05-21

**Outcome:** v1.2 migrated the Joy metric from density (Joy/¥) to cumulative `Σ joy_contribution` (ADR-016): HomeHero rebuilt with sage-green→gold target ring, Settings exposes user-configurable `monthly_joy_target` with 3-month median recommendation + fallback baseline 50, AnalyticsScreen Variant ε retired density and added Custom Time Windows (week/month/quarter/year/arbitrary), Per-Category breakdown + Soul-vs-Survival comparison with anti-toxicity framing, and Manual-Only Joy sub-metric variant on Drift schema v17 (`entry_source` column). HomeHero isolation invariant (ADR-016 §3) structurally enforced. Audit status `tech_debt` accepted at close — Phase 13/17 lack VERIFICATION.md; 3 Nyquist VALIDATION.md drafts; documentation-grade debt only. Full details: `.planning/milestones/v1.2-ROADMAP.md` + `.planning/milestones/v1.2-MILESTONE-AUDIT.md`.

</details>

<details>
<summary>✅ v1.3 迭代帐本输入 (Phases 18-23) — SHIPPED 2026-05-26</summary>

- [x] Phase 18: Shared Details Form Foundation (8/8 plans) — completed 2026-05-22
- [x] Phase 19: Manual One-Step + Keypad Polish (5/5 plans) — completed 2026-05-23
- [x] Phase 20: Voice Number Parser (zh + ja) (9/9 plans) — completed 2026-05-24
- [x] Phase 21: Voice Category Resolver Level-2 Enforcement (6/6 plans) — completed 2026-05-25
- [x] Phase 22: Voice One-Step Integration + Record Button UX (10/10 plans) — completed 2026-05-25
- [x] Phase 23: v1.3 Cleanup — Scanner Allow-Lists + Voice Flow Polish (9/9 plans) — completed 2026-05-26

**Outcome:** v1.3 transformed ledger entry into single-screen, voice-trustworthy core experience. Single shared `TransactionDetailsForm` widget powers 4 hosts (manual, voice, edit, OCR review). `ManualOneStepScreen` collapses 2-screen entry chain; SmartKeyboard 48dp non-negotiable touch-target floor with 6 golden baselines. Locale-aware zh+ja voice number parsing (state machines + `VoiceChunkMerger` 2.5s continued-listening window) at zh 96% + ja 100% corpus accuracy. `VoiceCategoryResolver` always-L2 contract with merchant DB + extensible synonym dictionary. Hold-to-record gesture with AnimatedContainer shape morph + caption swap (`<100ms` verified). 2 BLOCKER gaps (G-01/G-02) elevated and closed in Phase 22. Phase 23 cleanup absorbed carried tech-debt: scanner allow-lists, 6 voice-flow surgical fixes, 4 mechanical polish items, REQUIREMENTS.md reconciliation, 9/9 device UATs passed, `voice_input_screen.dart` slimmed 838→776 LOC via mixin + helpers extraction. Audit status `tech_debt` accepted at close — documentation-grade Nyquist debt only; all 15 v1.3 requirements satisfied and reconciled. Full details: `.planning/milestones/v1.3-ROADMAP.md` + `.planning/milestones/v1.3-MILESTONE-AUDIT.md`.

</details>

### 🚧 v1.4 列表功能 (Phases 24-30)

- [x] **Phase 24: Data Layer Extension** — Multi-book DAO query + watch stream + DateBoundaries utility (completed 2026-05-29)
- [x] **Phase 25: Domain Models + Use Case** — `ListFilterState`, `ListSortConfig`, `GetListTransactionsUseCase` (completed 2026-05-29)
- [x] **Phase 26: Providers + Shell Wiring** — All 4 Riverpod providers + keepAlive policy + shell placeholder replaced (completed 2026-05-30)
- [x] **Phase 27: Calendar Header + Month Summary** — `table_calendar` integration, per-day totals, month nav, day-tap filter (completed 2026-05-30)
- [x] **Phase 28: Transaction Tile + Sort/Filter Bar** — Row display, swipe-delete, tap-to-edit, sort/filter controls (completed 2026-05-30)
- [x] **Phase 29: List Screen Assembly + Family** — Full screen, pull-to-refresh, shadow books, member attribution + filter (completed 2026-05-30)
- [x] **Phase 30: i18n + Empty States + Golden Polish** — ~20–25 ARB keys × 3 locales, empty states, golden baselines (completed 2026-05-31)

---

## Phase Details

### Phase 24: Data Layer Extension

**Goal**: The data foundation for the list feature is correct, testable, and safe — multi-book queries, reactive watch stream, and month-boundary arithmetic are established as shared utilities before any UI is written.
**Depends on**: Phase 23 (v1.3 shipped)
**Requirements**: LIST-02
**Success Criteria** (what must be TRUE):

  1. `TransactionDao.findByBookIds(bookIds, startDate, endDate, ...)` executes a single SQL query spanning multiple `book_id` values, excludes soft-deleted rows, respects `ledgerType` and `categoryId` filters, and orders results by the requested `SortField`
  2. A Drift `.watch()` stream on `findByBookIds` emits a new event within one Riverpod rebuild cycle after any of: insert, soft-delete, sync-applied write — without requiring `ref.invalidate` from the caller
  3. `DateBoundaries.monthRange(year, month)` and `DateBoundaries.dayRange(day)` return boundaries that include transactions at `00:00:00` and `23:59:59` on the boundary day (unit tests pass)
  4. After soft-deleting a mid-chain transaction via `DeleteTransactionUseCase`, `HashChainService.verifyChain()` on the remaining non-deleted rows returns `ChainVerificationResult.valid` — confirming the soft-delete-only contract for swipe-delete
  5. Shadow-book `note` decryption failures in `TransactionRepositoryImpl._toModel()` are caught and return `note: null` — the remaining transaction fields are intact (explicit test with a fixture that simulates decrypt failure)

**Plans**: 3 plans
Plans:
**Wave 1**

- [x] 24-01-PLAN.md — SortField/SortDirection enums + DateBoundaries utility + SC#3 tests (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 24-02-PLAN.md — TransactionDao.findByBookIds + watchByBookIds + SC#1/SC#2/SC#4 tests (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 24-03-PLAN.md — Repository impl + domain interface + SC#5 decrypt-failure test (Wave 3)

**UI hint**: no

---

### Phase 25: Domain Models + Use Case

**Goal**: The pure-Dart domain layer for the list feature is locked — Freezed value objects describe all filter/sort state, the repository interface is declared, and the use case is unit-tested without Riverpod.
**Depends on**: Phase 24
**Requirements**: SORT-01, SORT-02, SORT-03, SORT-04
**Success Criteria** (what must be TRUE):

  1. `SortField` enum (timestamp, updatedAt, amount) and `SortDirection` enum (asc, desc) exist in `lib/shared/constants/sort_config.dart` — importable by both the domain layer and the DAO without triggering `import_guard` violations
  2. `ListSortConfig` and `ListFilterState` Freezed classes exist, `build_runner` generates `.freezed.dart` and `.g.dart` without errors, and `flutter analyze` reports zero issues on the new files
  3. `GetListTransactionsUseCase.execute(GetListParams)` returns `Result.error` when `bookIds` is empty, and forwards validated params to `TransactionRepository.findByBookIds(...)` — verified with a `MockTransactionRepository` unit test
  4. Changing sort field from `timestamp` to `amount` via `ListSortConfig.copyWith()` produces a new immutable object and does not mutate the original (Freezed `copyWith` contract)

**Plans**: 2 plans
Plans:
**Wave 1**

- [x] 25-01-PLAN.md — ListSortConfig + ListFilterState Freezed VOs + import_guard configs + build_runner (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 25-02-PLAN.md — GetListTransactionsUseCase + GetListParams + Mocktail unit tests (Wave 2)

**UI hint**: no

---

### Phase 26: Providers + Shell Wiring

**Goal**: All Riverpod providers for the list feature are wired together, the `keepAlive` policy under `IndexedStack` is explicitly decided and encoded, and `ListScreen` replaces the shell placeholder — the list tab is reachable but shows a loading state.
**Depends on**: Phase 25
**Requirements**: FILTER-01, FILTER-02, FILTER-03, FILTER-04
**Success Criteria** (what must be TRUE):

  1. `listFilterStateProvider` holds all composed filter state (`selectedMonth`, `activeDayFilter`, `sortConfig`, `ledgerType?`, `categoryId?`, `searchQuery`, `memberBookId?`) in a single Freezed value object, and `clearAll()` resets every filter to its initial value in one call
  2. The `keepAlive` policy is documented in the provider annotation comment: filter state persists across tab switches under `IndexedStack` (keepAlive: true) — the policy is encoded in code, not just a comment
  3. `listTransactionsProvider(bookId)` returns a `List<TaggedTransaction>` where text search queries against `searchQuery` match on category name, merchant, and note fields with AND-composition against the active ledger and category filters — verified with `ProviderContainer.test()` + `waitForFirstValue`
  4. `ListScreen` is reachable via the List tab in `MainShellScreen` (the `Center(child: Text(...))` placeholder at line 111 is replaced); `flutter analyze` is zero issues; `build_runner` diff is clean

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 26-01-PLAN.md — TaggedTransaction + MemberTag Freezed VOs + import_guard + Wave 0 test stubs (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 26-02-PLAN.md — ListFilter Notifier (keepAlive:true) + getListTransactionsUseCaseProvider + filter notifier tests (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 26-03-PLAN.md — listTransactionsProvider + locale-aware text search + transactions provider tests (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 26-04-PLAN.md — ListScreen loading scaffold + main_shell_screen.dart wiring + human verify (Wave 4)

**UI hint**: yes

---

### Phase 27: Calendar Header + Month Summary

**Goal**: The calendar header is a complete, independently testable widget — month navigation, per-day expense totals, day-tap filter, and the month expense summary are all observable in isolation.
**Depends on**: Phase 26
**Requirements**: CAL-01, CAL-02, CAL-03, CAL-04
**Success Criteria** (what must be TRUE):

  1. User can tap the previous/next arrows on the List tab to switch months; the calendar grid re-renders with the correct month and the displayed month label updates (e.g. "2026年5月" in ja locale)
  2. Each day cell in the calendar grid shows the total expense for that day (expense-only basis, own-book only in v1.4); days with no expenses show no amount indicator
  3. User can tap a day cell to filter the list to that day; the tapped day is visually highlighted; tapping the same day again clears the day filter and shows all entries in the month
  4. A month expense summary line below the calendar shows the current month's total expense-only spend formatted via `NumberFormatter` + `AppTextStyles.amountSmall` (tabular figures aligned); the total excludes income transactions
  5. `table_calendar: ^3.2.0` is added to `pubspec.yaml`; `flutter build ios --debug --no-codesign` succeeds; `intl: 0.20.2` pin is not violated

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 27-01-PLAN.md — Dependency setup: `table_calendar` + ARB keys + `initializeDateFormatting` + Wave 0 test stubs (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 27-02-PLAN.md — `calendarDailyTotalsProvider` `@riverpod` family + `_dayKey` normalization + 5 provider unit tests (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 27-03-PLAN.md — `CalendarHeaderWidget` (C-01/C-02/C-03/C-04) + `ListScreen` integration + 3 widget tests (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 27-04-PLAN.md — iOS build gate (SC#5) + full test suite + human verify (Wave 4)

**UI hint**: yes

---

### Phase 28: Transaction Tile + Sort/Filter Bar

**Goal**: Individual list rows and the sort/filter controls are complete, correctly styled, and safe — the transaction tile shows all required fields with correct colors and formatting, swipe-delete routes exclusively through `DeleteTransactionUseCase`, and tap-to-edit opens the v1.3 edit screen.
**Depends on**: Phase 27
**Requirements**: LIST-01, ROW-01, ROW-02, SORT-01, SORT-02, SORT-03, SORT-04, FILTER-01, FILTER-02, FILTER-03, FILTER-04
**Success Criteria** (what must be TRUE):

  1. Each transaction row displays category emoji + name, a ledger-color tag using `AppColors.survival` / `AppColors.soul` constants (verified against `lib/core/theme/app_colors.dart`, never hardcoded hex), transaction date formatted via `DateFormatter`, and amount formatted via `NumberFormatter` + `AppTextStyles.amountSmall` with tabular figures visually aligned across rows with differing digit counts
  2. User can tap a row to open `TransactionEditScreen` with the transaction pre-populated; saving the edit closes the screen and the list reflects the updated values without a manual refresh
  3. User can swipe a row to trigger a delete confirmation dialog; confirming the delete calls `DeleteTransactionUseCase.execute(id)` (soft-delete only — a unit test asserts `isDeleted = true` on the row and `HashChainService.verifyChain()` returns valid after the operation); the row disappears from the list
  4. User can tap the sort control to cycle through date / edit-time / amount sort fields and toggle ascending/descending; the active sort field and direction are visually indicated in the sort bar
  5. User can tap the ledger filter chip to filter to Survival or Soul entries; user can open the category filter to select one or more categories; both filters compose with text search (AND logic) and a single "clear all" control resets all active filters

**Plans**: 7 plans
Plans:
**Wave 1** *(parallel)*

- [x] 28-01-PLAN.md — D-01 Freezed state change (categoryIds Set) + ARB keys + build_runner (Wave 1)
- [x] 28-02-PLAN.md — Wave 0 test stubs: notifier + hash-chain + widget tests (Wave 1)

**Wave 2** *(blocked on Wave 1)*

- [x] 28-03-PLAN.md — ListTransactionTile (C-01) + ListDayGroupHeader (C-02) + tile tests GREEN (Wave 2)
- [x] 28-04-PLAN.md — CategoryFilterSheet (C-05) + ListEmptyState (C-06) (Wave 2)

**Wave 3** *(blocked on Wave 2)*

- [x] 28-05-PLAN.md — ListSortFilterBar (C-03) + bar tests GREEN (Wave 3)

**Wave 4** *(blocked on Wave 3)*

- [x] 28-06-PLAN.md — ListScreen assembly + SC#3 hash-chain test + full suite GREEN (Wave 4)

**Wave 5** *(blocked on Wave 4)*

- [ ] 28-07-PLAN.md — Human verify: all 21 behavioral checks (Wave 5)

**UI hint**: yes

---

### Phase 29: List Screen Assembly + Family

**Goal**: The complete list screen is assembled — all components integrated, pull-to-refresh works, reactive sync updates propagate automatically, and when a family is joined the list merges members' entries with per-row attribution and a "Mine only" shortcut.
**Depends on**: Phase 28
**Requirements**: LIST-04, FAM-01, FAM-02, FAM-03, FAM-04
**Success Criteria** (what must be TRUE):

  1. User can pull down on the transaction list to trigger a refresh; the list reloads and reflects any new entries added on another device since the last sync
  2. When the user has joined a family group, the transaction list includes entries from all family members (shadow books via `shadowBooksProvider`) merged with the user's own entries — the month total and calendar per-day totals reflect all members' combined expenses
  3. Each row belonging to a family member displays a member attribution label (name or emoji indicator) so the user can distinguish whose entry it is; own entries show no attribution label
  4. User can tap a family member chip in the filter bar to show only that member's entries; the member filter composes with the active ledger and category filters
  5. User can tap the "Mine only" shortcut (a prominent toggle in the filter area) to instantly show only their own entries; tapping it again returns to the full family view — the shortcut is visible even when no other member filter is active

**Plans**: 4 plans
Plans:
**Wave 1**

- [x] 29-01-PLAN.md — Wave 0 test stubs: 2 new widget test files + extensions to 3 existing test files (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 29-02-PLAN.md — state_list_transactions.dart group-mode bookIds fan-out + memberTag fill + member filter narrowing + state_calendar_totals.dart per-book sum + ARB listMineOnly key (Wave 2)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 29-03-PLAN.md — list_transaction_tile.dart member attribution chip + list_sort_filter_bar.dart family segment + anyFilterActive fix (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 29-04-PLAN.md — list_screen.dart RefreshIndicator + anyFilterActive fix + full suite GREEN + human verify (Wave 4)

**UI hint**: yes

---

### Phase 30: i18n + Empty States + Golden Polish

**Goal**: Every user-visible string in the list tab is trilingual, the empty-state messages are clear and contextual, golden baselines are locked on stable isolated widgets, and the full CI suite passes at zero issues.
**Depends on**: Phase 29
**Requirements**: LIST-03
**Success Criteria** (what must be TRUE):

  1. All list-tab UI strings are served via `S.of(context)` ARB keys; `flutter gen-l10n` produces no warnings; all three locale files (ja/zh/en) have identical key count (no orphan keys in any locale)
  2. When no transactions exist in the selected month, the user sees a clear empty-state message (e.g. "この月の記録はありません" in ja) — not a blank area
  3. When the user has applied filters that match no transactions, the user sees a distinct filtered-empty-state message (e.g. "条件に合う記録が見つかりません" in ja) with a "clear filters" inline action — distinct from the no-data empty state
  4. `flutter analyze` reports zero issues; `dart run custom_lint --no-fatal-infos` reports zero errors; `build_runner` diff is clean; global test coverage remains ≥70%

**Plans**: 5 plans
Plans:
**Wave 1**

- [x] 30-01-PLAN.md — ARB key edits (6 new keys + 4 updated values) in all 3 locales + flutter gen-l10n (Wave 1)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 30-02-PLAN.md — ListEmptyState 3-state rework + list_screen.dart branching + list_calendar_header.dart Semantics + test updates + D-08 sweep (Wave 2)

**Wave 3** *(blocked on Wave 2, parallel pair)*

- [x] 30-03-PLAN.md — Golden test files: list_transaction_tile, list_day_group_header, list_sort_filter_bar, list_empty_state (9 cases) + baselines (Wave 3)
- [x] 30-04-PLAN.md — Golden test files: list_calendar_header (determinism fix), list_category_filter_sheet + baselines (Wave 3)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 30-05-PLAN.md — CI green gate: analyze 0 + custom_lint 0 + build_runner clean + coverage ≥70% + human verify (Wave 4)

**UI hint**: yes

---

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 24. Data Layer Extension | 3/3 | Complete    | 2026-05-29 |
| 25. Domain Models + Use Case | 2/2 | Complete    | 2026-05-29 |
| 26. Providers + Shell Wiring | 4/4 | Complete    | 2026-05-30 |
| 27. Calendar Header + Month Summary | 4/4 | Complete    | 2026-05-30 |
| 28. Transaction Tile + Sort/Filter Bar | 6/7 | Complete    | 2026-05-30 |
| 29. List Screen Assembly + Family | 4/4 | Complete    | 2026-05-30 |
| 30. i18n + Empty States + Golden Polish | 5/5 | Complete   | 2026-05-31 |

---

## Milestone Progress

| Milestone | Phases | Plans Complete | Status | Shipped |
|-----------|--------|----------------|--------|---------|
| v1.0 Codebase Cleanup Initiative | 1-8 | 48/48 | Complete | 2026-04-29 |
| v1.1 Happiness Metric & Display | 9-12 | 40/40 | Complete | 2026-05-05 |
| v1.2 Happiness Metric Refresh | 13-17 | 37/37 | Complete | 2026-05-21 |
| v1.3 迭代帐本输入 | 18-23 | 47/47 | Complete | 2026-05-26 |
| v1.4 列表功能 | 24-30 | 0/TBD | In Progress | - |
