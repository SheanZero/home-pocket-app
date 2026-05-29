# Project Research Summary

**Project:** Home Pocket v1.4 — 列表功能 (Transaction List Tab)
**Domain:** Flutter local-first family accounting app — read-biased list/calendar feature on existing 5-layer Clean Architecture
**Researched:** 2026-05-29
**Confidence:** HIGH

## Executive Summary

The v1.4 List tab is a read-biased calendar + filterable list surface bolted onto an already mature 5-layer Clean Architecture. The primary design challenge is not the features themselves — competitor pattern analysis (Zaim, MoneyForward ME, おカネレコ) shows all patterns are well-understood — but rather integrating cleanly with the existing DAO, provider, and family-sync machinery without duplicating or violating the established conventions. The recommended approach is a new `lib/features/list/` module following the Thin Feature rule, one new `findByBookIds` DAO method (query extension, no migration), and reuse of `AnalyticsDao.getDailyTotals`, `DeleteTransactionUseCase`, `shadowBooksProvider`, and `TransactionEditScreen` as-is. The only external package addition is `table_calendar: ^3.2.0`, which is pin-safe and iOS-build-safe.

The two biggest technical risks are both pre-existing architectural constraints, not new complexity: (1) the hash-chain integrity requirement means swipe-delete must exclusively use `DeleteTransactionUseCase` (soft-delete path) — any direct DAO delete breaks the chain and is unrecoverable without backup restore; (2) `IndexedStack` in `MainShellScreen` means provider auto-dispose does not fire on tab switch, requiring an explicit policy decision (keep-alive vs explicit reset) before any provider is written. Both are easily mitigated when addressed in the first phase rather than discovered late.

The feature scope is well-bounded: calendar grid with per-day totals, scrollable month list with date-group dividers, sort/filter/search, swipe-to-delete with confirmation, tap-to-edit, family-aware unified list with member attribution, and i18n/empty states. Four items are explicitly out of scope (month settlement/lock, income tracking, "New" badge, amount-range filter). Post-v1.4 additions to plan for but not build now: sort by amount/edit-time, undo-delete SnackBar, loading skeleton, and pagination.

---

## Cross-File Divergence Resolutions

The following four divergences were identified across research files and are resolved here. The roadmapper must use these resolutions, not the raw per-file statements.

### Resolution 1: Per-Day Calendar Totals Data Source

**Divergence:** FEATURES.md says a new `getDailyTotals` DAO method is required. STACK.md and ARCHITECTURE.md both say the existing `AnalyticsDao.getDailyTotals()` already exists and should be reused.

**Resolution: Reuse the existing `AnalyticsDao.getDailyTotals()`. No new DAO method needed for the calendar.**

Evidence: STACK.md and ARCHITECTURE.md both cite direct codebase inspection of `lib/data/daos/analytics_dao.dart`, confirming `getDailyTotals` performs `DATE(timestamp, 'unixepoch', 'localtime') GROUP BY day SUM(amount)` for a given book + date range. FEATURES.md was written without inspecting the DAO directly. The correct integration path is a new `listCalendarProvider({bookId, month})` that calls `analyticsRepositoryProvider.getDailyTotals(...)` — no new DAO surface required.

**Note for roadmapper:** FEATURES.md also references a `GetMonthlyDailyTotalsUseCase` in `lib/application/accounting/` as a new artifact. This is unnecessary given direct `AnalyticsRepository` reuse. Eliminate from the backlog.

### Resolution 2: Calendar Widget — `table_calendar` Package vs Custom Widget

**Divergence:** STACK.md recommends `table_calendar: ^3.2.0`. ARCHITECTURE.md leans on existing custom widgets and does not mention the package.

**Recommendation: Add `table_calendar: ^3.2.0`. Use `CalendarBuilders` for all visual customization.**

Rationale: A calendar month grid requires ~350 lines of date arithmetic, DST-safe boundary handling, locale-aware day-of-week headers, and hit-test logic. `table_calendar` saves this entirely, is `intl: ^0.20.0` compatible (project pins `0.20.2`), has no win32 dependency, and requires no iOS CocoaPods changes. The `CalendarBuilders.defaultBuilder` API gives full cell rendering control, so the design system (`AppTextStyles`, `AppColors`, `context.wmCard`) is not compromised. The tradeoff is a package dependency vs ~350 lines of custom code with known edge cases — the package wins on risk-adjusted cost.

**Design-system fit vs build speed:** Both are achievable with `table_calendar`. The `CalendarBuilders` API replaces the entire cell renderer — no visual chrome from the package leaks into the UI. This is a resolved decision; no further research needed.

### Resolution 3: Calendar Daily Totals in Family Mode — Own-Book Only vs Combined

**Divergence:** Multiple researchers flagged this as unresolved. ARCHITECTURE.md explicitly marks it "own-book only; family calendar aggregation is out-of-scope v1.4."

**Recommended default for v1.4: Own-book only calendar totals.**

Rationale: Combining all family members' daily spending in the calendar requires a new `AnalyticsDao` variant querying across multiple `book_id` values, is not in stated scope, and risks inconsistency with the unified list (which shows all members' transactions). The v1.4 default is own-book calendar totals. If users request combined calendar totals, add in v1.5 as a distinct enhancement.

**Decision to surface in requirements:** Flag as an open product question — "Should the calendar show your own spending or combined family spending in family mode?" — and document the v1.4 default (own-book) explicitly so it is not re-litigated during implementation.

### Resolution 4: Ledger Color Inversion Risk

**Divergence:** MEMORY.md states Soul = `#47B88A` (green), Survival = `#5A9CC8` (blue). CLAUDE.md app overview says "Soul Ledger: Purple theme" and "Survival Ledger: Green theme". PITFALLS.md flags this inconsistency explicitly.

**Resolution: Do not hardcode either description. Verify against `lib/core/theme/app_colors.dart` constants before writing any list tile color logic.**

The ground truth is the constant file. The ledger color tag in `ListTransactionTile` must reference `AppColors.soul` and `AppColors.survival` by name — never by hex literal. Include "verify ledger color constants against `app_colors.dart`" as the first task of the list tile implementation phase.

---

## Key Findings

### Recommended Stack

The locked stack (Riverpod 3.1, Freezed 3, Drift 2.25, SQLCipher, GoRouter, Lucide Icons) covers all v1.4 capabilities without new additions except one package. The `table_calendar: ^3.2.0` package is the single addition: it handles the calendar month grid, month navigation, and day-selection state, saving ~350 lines of date arithmetic. All other capabilities — dynamic Drift query sorting, text search, `Dismissible` swipe-delete, family-aware multi-book queries, provider state composition — are built from the existing stack.

The critical pin constraints to respect: `intl: 0.20.2` exact pin (compatible with `table_calendar ^3.2.0` which requires `^0.20.0`); `file_picker 11 / package_info_plus 9 / share_plus 12` trio must move together; `sqlcipher_flutter_libs ^0.6.7` (not `sqlite3_flutter_libs`). None are affected by the `table_calendar` addition.

**Core technologies for v1.4:**
- `table_calendar: ^3.2.0` — calendar grid with custom cell builder; only new dependency
- `Drift 2.25` — new `findByBookIds` DAO method (query extension, no schema migration); reuse `AnalyticsDao.getDailyTotals` for calendar
- `Riverpod 3.1 + @riverpod codegen` — `ListFilterNotifier`, `listTransactionsProvider`, `listCalendarProvider`; all with explicit keepAlive policy
- `Freezed 3` — `ListFilterState`, `ListSortConfig`, `TaggedTransaction` value types
- `Dismissible` (Flutter built-in) — swipe-to-delete; no external package needed
- `NumberFormatter` + `AppTextStyles.amountSmall` — amount display with tabular figures; mandatory for all monetary values

### Expected Features

**Must have (table stakes — all P1):**
- Calendar grid with per-day expense totals + month nav (prev/next arrows; no future months)
- Tap-a-day filter + "Show all" / clear-day control
- Month expense-only summary line (reuse `GetMonthlyReportUseCase`)
- Transaction list rows with date-group dividers
- Sort: date asc/desc toggle (default desc is free from existing DAO)
- Text search: merchant + note + category name
- Filter by ledger (Survival / Soul / All) — core dual-ledger differentiator
- Filter by category (bottom sheet; single-select for v1.4)
- **Combined filter state + clear-all** (single `ListFilterState` Freezed object; all filters AND-composed; clear-all is a required escape hatch)
- Tap row to `TransactionEditScreen` (reuse existing; pop(true) triggers invalidate)
- Swipe-to-delete with confirmation dialog (AlertDialog; `DeleteTransactionUseCase` only — never direct DAO)
- Empty states: no-entries-in-month and no-filter-match
- Family-aware unified list with member attribution (shadow books via `shadowBooksProvider`)
- Member filter + **"Mine only" shortcut toggle** ("自分のみ" / "仅我的" / "Mine only")
- Pull-to-refresh + sync-triggered auto-refresh

**Should have (P2 — post-v1.4):**
- Sort by amount (high→low / low→high) — full-month load already done; add sort picker
- Undo-delete SnackBar (5s) — requires `RestoreTransactionUseCase`; defer if scope tight
- Loading skeleton / shimmer rows — polish only

**Defer to v2+:**
- Pagination / virtual scroll (only if family groups >2000 monthly entries cause jank)
- Cross-month date range filter (AnalyticsScreen owns this)
- Combined family calendar totals (v1.5+ enhancement)
- Export filtered list to CSV/PDF

**Explicitly out of scope (owner-stated):**
- Month settlement / month-lock
- Income tracking in list
- "New" badge on recently synced entries
- Amount-range filter

### Architecture Approach

The feature lands in a new `lib/features/list/` module following the Thin Feature rule: `domain/` (models + repository interface) and `presentation/` (screens, widgets, providers). Application logic lives in `lib/application/list/` (new `GetListTransactionsUseCase`). The only data-layer change is adding `findByBookIds` to `TransactionDao` and `TransactionRepositoryImpl` — a query-only extension, no Drift migration. `TransactionRepositoryImpl` implements both `TransactionRepository` and `ListTransactionRepository`; no second implementation class.

The key architectural insight: the family sync model already stores each member's transactions in local shadow books under different `book_id` values. The list feature needs only to pass `[myBookId, ...shadowBookIds]` to `findByBookIds` — no merge service, no in-memory join, no additional sync logic. Calendar data stays own-book-only via `analyticsRepositoryProvider.getDailyTotals()`.

**Major new components:**
1. `lib/features/list/` — new Thin Feature module (domain models + presentation)
2. `lib/application/list/GetListTransactionsUseCase` — wraps `TransactionRepository.findByBookIds`; validates params; returns `Result<List<Transaction>>`
3. `TransactionDao.findByBookIds()` — multi-book, date-range, ledger/category filter, SQL-level ORDER BY; Dart-side post-process for text search + day filter + member filter
4. `listFilterStateProvider (Notifier)` — single coordination point for all filter state
5. `listTransactionsProvider (FutureProvider)` — composes filter, shadow books, use case call, Dart-side post-processing
6. `listCalendarProvider (FutureProvider, family {bookId, month})` — reuses `analyticsRepositoryProvider.getDailyTotals()`

**Modified existing files:**
- `main_shell_screen.dart:111` — replace placeholder with `ListScreen(bookId: bookId)`
- `TransactionRepository` interface — add abstract `findByBookIds`
- `TransactionRepositoryImpl` — add `findByBookIds` implementation

**Reused without modification:**
- `TransactionEditScreen` (push + pop(true) invalidate pattern)
- `DeleteTransactionUseCase` (soft-delete only; never bypass)
- `shadowBooksProvider` (family shadow book IDs + member attribution)
- `AnalyticsDao.getDailyTotals` (calendar per-day rollup)
- `isGroupModeProvider` + `activeGroupProvider`

### Critical Pitfalls

1. **Swipe-delete must use `DeleteTransactionUseCase` exclusively** — any direct DAO delete breaks the hash chain permanently. Wire to the use case in Phase 1 and write a `verifyChain()` test after soft-delete before any UI phase begins.

2. **IndexedStack does not trigger provider auto-dispose** — `MainShellScreen` uses `IndexedStack` (confirmed line 97). Decide the keepAlive vs reset policy for all filter providers before writing a single provider.

3. **Date-range boundary errors** — the codebase has a canonical idiom (`DateTime(y, m+1, 0, 23, 59, 59)` for month-end; `DateTime(y, m, d, 23, 59, 59)` for day-end). Extract a `DateBoundaries` utility in `lib/shared/utils/` in Phase 1.

4. **Separate providers for calendar totals and filtered list** — if both derive from one provider, every search keystroke triggers full calendar re-render. Calendar watches only `(bookId, month)`. Use Drift `.watch()` stream for the transaction list so post-delete and post-sync updates propagate automatically. Note: no watch queries exist in `TransactionDao` today — adding one is a Phase 1 deliverable.

5. **Riverpod 3 `ProviderException` wrapping** — all provider error test assertions must use `throwsA(isA<ProviderException>().having(...))`. Use `ProviderContainer.test()` and `waitForFirstValue<T>()` from `test/helpers/test_provider_scope.dart` — never bare `await container.read(provider.future)`.

6. **Shadow book `note` decryption** — shadow notes encrypted with originating device key are undecryptable locally. `_toModel()` must catch and return `note: null`. Text search must gracefully skip note for shadow rows. Verify in Phase 1.

7. **Ledger color constants** — verify `AppColors.soul` and `AppColors.survival` against `lib/core/theme/app_colors.dart` before writing list tile code. Do not reference hex values from CLAUDE.md or MEMORY.md.

---

## Implications for Roadmap

Based on combined research, build order follows: data → application → domain → providers → calendar/list widgets → interactions → family → i18n/polish. 9 phases recommended.

### Phase 1: Data Layer Extension
**Rationale:** All subsequent phases depend on the DAO. No schema migration means zero risk. Hash chain integrity and date boundary correctness must be established before any UI exists.
**Delivers:** `SortField`/`SortDirection` enums in `lib/shared/constants/`; `TransactionDao.findByBookIds()`; `TransactionDao` watch query; `DateBoundaries` utility in `lib/shared/utils/`; repository abstract + impl.
**Addresses:** Hash chain safety (verifyChain test), date boundary correctness, no-migration requirement.
**Avoids:** Hash chain break; date boundary errors; shadow note decryption exceptions (verify here).
**Research flag:** None — well-documented Drift patterns; standard extension.

### Phase 2: Application Use Case
**Rationale:** Thin boundary; separates DAO params from provider concerns; testable without Riverpod.
**Delivers:** `lib/application/list/GetListTransactionsUseCase` + `GetListParams`; unit tests with `MockTransactionRepository`.
**Avoids:** Family bookId assembly inside use case (provider responsibility).
**Research flag:** None — standard Use Case pattern.

### Phase 3: Domain Models
**Rationale:** `ListFilterState` is the coordination point for all filter composition; must exist before any provider.
**Delivers:** `ListFilterState` (Freezed) + `ListSortConfig` (Freezed) + `ListTransactionRepository` interface + `TaggedTransaction` model; `build_runner`.
**Avoids:** Scattered per-filter state; cross-feature domain imports (use `lib/shared/constants/` for `SortField`).
**Research flag:** None — Freezed patterns established.

### Phase 4: Riverpod Providers + Shell Wiring
**Rationale:** Provider topology must be designed as a unit. `keepAlive` policy for IndexedStack decided here. Shell wiring makes the feature reachable for integration testing.
**Delivers:** All 4 providers (`repository_providers`, `state_list_filter`, `state_list_transactions`, `state_list_calendar`); shell wiring replacing placeholder at `main_shell_screen.dart:111`; `build_runner`.
**Avoids:** IndexedStack keepAlive trap; `ProviderException` test errors; bare `container.read(provider.future)`.
**Research flag:** Medium complexity — keepAlive policy requires a product decision (filter state persistence on tab switch). Flag for requirements sign-off before implementation.

### Phase 5: Calendar Header Widget
**Rationale:** Calendar is the visual anchor; must be isolated and testable before list assembly.
**Delivers:** `list_calendar_header.dart` (table_calendar wrapper with `CalendarBuilders`, month nav, day-tap); `list_month_summary.dart`; widget tests + golden baselines (isolated cell only).
**Uses:** `table_calendar: ^3.2.0` (add to pubspec.yaml here); `NumberFormatter`; `AppTextStyles.amountSmall`.
**Avoids:** Calendar totals derived from filtered list provider; calendar including income; visual chrome leaking from package.
**Research flag:** None — `CalendarBuilders` API verified.

### Phase 6: Transaction Tile + Sort/Filter Bar
**Rationale:** List row and filter UI are independent of calendar; can run in parallel with Phase 5.
**Delivers:** `ListTransactionTile` (category emoji, ledger tag, date, amount, optional member tag; `Dismissible` delete, `onTap` edit); `list_sort_filter_bar.dart` (sort chip, ledger/category chips, search field with 300ms debounce); `list_empty_state.dart`.
**Avoids:** Reusing `HomeTransactionTile` directly (lacks date column + member tag); `ref.watch` for SnackBar side effects (use `ref.listen`); hardcoded amount formatting.
**Research flag:** None — standard widget patterns.

### Phase 7: List Screen Assembly + Full Integration
**Rationale:** Assembles all components; integration tests cover all interactions.
**Delivers:** `list_screen.dart` with `CustomScrollView`; pull-to-refresh; sync-triggered auto-refresh; post-edit/post-delete invalidation of list + calendar + home providers.
**Avoids:** Missing home-screen invalidation after edit/delete; missing `SafeArea` bottom padding.
**Research flag:** None — integration patterns established.

### Phase 8: Family-Aware List
**Rationale:** Adds shadow-book multi-book queries and member attribution. Deferred until single-user list is stable.
**Delivers:** `isGroupModeProvider` guard in `listTransactionsProvider`; `shadowBooksProvider` integration; `TaggedTransaction` member label resolution; member filter chips + "Mine only" shortcut; graceful unknown-member fallback.
**Avoids:** Per-row DAO calls for member names (use in-memory `bookId → memberLabel` map); shadow note decrypt causing exceptions; member list changes triggering full list rebuild (separate `memberMapProvider`).
**Research flag:** Medium complexity — shadow note decryption contract must be confirmed in Phase 1.

### Phase 9: ARB + i18n + Golden Polish
**Rationale:** ARB keys last avoids repeated `flutter gen-l10n` runs and golden churn during development.
**Delivers:** ~20–25 new ARB keys across all 3 locale files (ja/zh/en); `flutter gen-l10n` clean; golden baselines for isolated widgets only; `flutter analyze` zero warnings.
**Avoids:** Missing ARB key in one locale blocking CI; goldens baselined before layout is stable; >12 new golden PNG files.
**Research flag:** None — ARB workflow established.

### Phase Ordering Rationale

- Phases 1–3 are pure Dart with no UI: fast, fully testable, establish all correctness invariants before any widget exists.
- Phase 4 provider topology is designed as a unit: keepAlive policy, dependency graph, and shell wiring decided together.
- Phases 5 and 6 can run in parallel (calendar header and tile/filter bar share no state).
- Phase 7 integration deferred until widget components are stable.
- Phase 8 family mode deliberately last: adds real complexity without blocking the single-user experience.
- Phase 9 i18n last: prevents repeated gen-l10n runs and baseline churn.

### Research Flags

**Needs product decision before Phase 4:**
- Filter state keepAlive policy: persist on tab switch (natural under IndexedStack) or reset? Document and encode in provider annotations.
- Calendar family aggregation: v1.4 own-book only default confirmed; product team should verify this is acceptable UX.

**Needs implementation verification in Phase 1:**
- Shadow book `note` decryption exception handling in `TransactionRepositoryImpl._toModel()` — MEDIUM confidence. Write an explicit test.

**Needs pre-implementation verification:**
- Ledger color constants: `grep -n "survival\|soul" lib/core/theme/app_colors.dart` before Phase 6.

**Standard patterns (skip research-phase):**
- Phases 1–3: Drift query extension + Freezed domain models — fully established.
- Phases 5–6: `CalendarBuilders` API + `Dismissible` — verified against official docs.
- Phase 9: ARB workflow — established in codebase.

### Open Questions for Requirements

1. **Undo-delete scope:** Is the undo SnackBar in or out of v1.4 scope? Requires `RestoreTransactionUseCase`. If in scope, add to Phase 7.
2. **Calendar family aggregation:** Own-book only (recommended) or combined family? Product decision.
3. **Mixed-currency compact formatting:** v1.4 assumes single currency — flag if family sync enables multi-currency books before list tab ships.
4. **Filter state persistence on tab switch:** Keep-alive (most natural under IndexedStack) or reset (requires `ref.listen` on tab index)?

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All findings based on direct `pubspec.yaml`, `pubspec.lock`, and source file inspection. `table_calendar` compatibility verified via pub.dev + Context7 docs. |
| Features | HIGH (codebase) / MEDIUM (competitor) | Table stakes from direct codebase analysis. Competitor landscape from web research. |
| Architecture | HIGH | All claims verified against live `lib/` tree. Provider dependency graph traced from source. Shadow book pattern confirmed from `ShadowBookService` + `shadowBooksProvider` source. |
| Pitfalls | HIGH | All pitfalls from actual codebase inspection + CLAUDE.md. Hash chain behavior read from `HashChainService` source. IndexedStack confirmed at line 97. |

**Overall confidence:** HIGH

### Gaps to Address

- **Shadow note decryption contract (MEDIUM):** `TransactionRepositoryImpl._toModel()` exception handling for undecryptable shadow notes not explicitly verified. Phase 1 test requirement.
- **ARB key exact count (MEDIUM):** Estimated ~20–25 new keys. Exact count emerges during Phase 9 widget design.
- **Multi-currency handling:** Assumed out of scope for v1.4. Flag if family sync enables multi-currency books before list tab ships.
- **`RestoreTransactionUseCase` existence:** Does not currently exist. Required only if undo-delete is in v1.4 scope.

---

## Sources

### Primary (HIGH confidence — direct codebase inspection)
- `lib/data/daos/analytics_dao.dart` — confirmed `getDailyTotals` with GROUP BY day pattern
- `lib/data/daos/transaction_dao.dart` — confirmed `findByBookId` signature; no watch queries exist today
- `lib/data/repositories/transaction_repository_impl.dart` — `_toModel` field decryption pattern
- `lib/features/home/presentation/screens/main_shell_screen.dart` — IndexedStack at line 97; placeholder at line 111
- `lib/features/home/presentation/providers/state_shadow_books.dart` — family shadow book + member attribution pattern
- `lib/features/family_sync/presentation/providers/state_active_group.dart` — `activeGroupProvider` keepAlive confirmed
- `lib/features/accounting/presentation/screens/transaction_edit_screen.dart` — pop(true) pattern confirmed
- `lib/application/accounting/delete_transaction_use_case.dart` — soft-delete path confirmed
- `lib/infrastructure/crypto/services/hash_chain_service.dart` — soft-delete safe; hard-delete breaks chain
- `lib/features/analytics/domain/repositories/analytics_repository.dart` — `getDailyTotals` interface
- `lib/core/theme/app_text_styles.dart` — `amountSmall/Medium/Large` with `FontFeature.tabularFigures()`
- `lib/features/analytics/domain/models/time_window.dart` — canonical month-end boundary idiom
- `lib/features/home/presentation/providers/state_today_transactions.dart` — canonical day-end boundary idiom
- `pubspec.yaml` / `pubspec.lock` — all locked dependencies and win32 version verified

### Primary (HIGH confidence — official docs)
- Context7 `/aleksanderwozniak/table_calendar` — `CalendarBuilders` API, `onDaySelected`, `focusedDay`, locale parameter
- pub.dev/packages/table_calendar — version 3.2.0; deps `intl ^0.20.0`, `simple_gesture_detector ^0.2.0`; no win32
- Context7 `/websites/drift_simonbinder_eu` — `OrderingTerm`, `customSelect`/`readsFrom`, `.watch()` stream pattern

### Secondary (MEDIUM confidence — competitor / web research)
- Zaim Google Play listing — calendar per-day totals, tap-day filter patterns
- MoneyForward ME UX (IGNITE blog) — calendar + month total display patterns
- おカネレコ feature page — calendar/list duality, family version features
- Money Manager (Okanemochi) App Store — swipe-to-delete, sort/filter options

---
*Research completed: 2026-05-29*
*Ready for roadmap: yes*
