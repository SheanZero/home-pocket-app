# Requirements — Milestone v1.4 列表功能 (Transaction List)

**Defined:** 2026-05-29
**Goal:** Build out the placeholder List tab into a full transaction overview — month calendar (per-day expense totals + tap-to-filter), sortable/searchable/filterable transaction list, basic month summary — reusing the v1.3 edit path and surfacing family members' entries when a family is joined.

**Reference:** Japanese-kakeibo-style design (calendar header + sortable transaction list under the bottom-nav List tab). Research: `.planning/research/SUMMARY.md`.

---

## v1.4 Requirements

### Calendar & Month (CAL)

- [x] **CAL-01**: User can switch the displayed month (previous / next + month picker) on the List tab.
- [x] **CAL-02**: User sees a month calendar grid showing each day's total expense; in family mode the per-day total combines the user's own + members' expenses (consistent with the list).
- [x] **CAL-03**: User can tap a day in the calendar to filter the list to that day; tapping the selected day again clears the day filter.
- [x] **CAL-04**: User sees a current-month summary (total expense, expense-only basis) on the List tab.

### List Display (LIST)

- [x] **LIST-01**: User sees the selected month's transactions as a scrollable list; each row shows category emoji + name, ledger-color tag (Survival `AppColors.survival` / Soul `AppColors.soul`), date, and amount (tabular figures via `AppTextStyles.amount*`, formatted by `NumberFormatter` + locale).
- [x] **LIST-02**: The list updates reactively after add / edit / delete / family-sync — no manual refresh required (new `TransactionDao.watchByBookId(s)` stream).
- [ ] **LIST-03**: User sees a clear empty state when no transactions match the current month + active filters.
- [ ] **LIST-04**: User can pull-to-refresh the list.

### Sort (SORT)

- [x] **SORT-01**: User can sort the list by transaction date.
- [x] **SORT-02**: User can sort the list by edit / created time (reference default).
- [x] **SORT-03**: User can sort the list by amount.
- [x] **SORT-04**: User can toggle ascending / descending for the active sort.

### Search & Filter (FILTER)

- [x] **FILTER-01**: User can text-search the list by category name, merchant, and note.
- [x] **FILTER-02**: User can filter the list by ledger (Survival / Soul).
- [x] **FILTER-03**: User can filter the list by one or more categories.
- [x] **FILTER-04**: Active search + filters compose together (AND logic) and the user can clear all filters in one action.

### Row Interactions (ROW)

- [ ] **ROW-01**: User can tap a row to open it for editing (reuses `TransactionEditScreen` + shared `TransactionDetailsForm`; preserves `entry_source`).
- [ ] **ROW-02**: User can swipe a row to delete it with a confirmation dialog; deletion routes exclusively through `DeleteTransactionUseCase` (soft-delete, hash-chain integrity preserved).

### Family-Aware (FAM)

- [ ] **FAM-01**: When a family is joined, the list includes family members' transactions (shadow books) merged with the user's own.
- [ ] **FAM-02**: Each row attributes its owner (member name / emoji indicator) when in family mode.
- [ ] **FAM-03**: User can filter the list by family member.
- [ ] **FAM-04**: User can quickly switch to a "Mine only" view in family mode.

---

## Future Requirements (deferred)

- **Month settlement / month-lock (结账锁月)** — the reference's 结账 button; complex (close month, carry balance, lock edits). Deferred to a later milestone.
- **Income tracking + net/income calendar basis** — v1.4 is expense-only; income type would need data-model support.
- **Undo-on-delete** — SnackBar "undo" via a `RestoreTransactionUseCase` (set `isDeleted=false` + re-enqueue sync). Deferred.
- **Amount-range filter** — min/max amount filter; not in v1.4 filter set.
- **"New" badge** — recently-added marker on rows (reference shows it); cut from v1.4.

---

## Out of Scope (explicit exclusions, v1.4)

- **Month settlement / lock** — see Future; v1.4 is read/browse + edit/delete only, no month-close logic.
- **Income / net totals** — calendar and summary are expense-only; no income type introduced.
- **Combined-currency calendar math beyond existing `NumberFormatter.compact()`** — if a family has mixed-currency books, rely on existing formatter behavior; no new multi-currency aggregation.
- **New navigation/tabs** — Todo tab (待办事项) stays a placeholder; only the List tab is built.

---

## Implementation Notes (cross-cutting, from research)

- **Placement:** new `lib/features/list/` module (read-biased, mirrors `features/analytics/`); replace placeholder at `main_shell_screen.dart:111`. Data-layer queries stay in `lib/data/daos/` per the Thin Feature rule.
- **Reuse:** `AnalyticsDao/Repository.getDailyTotals()` for calendar rollups; `shadowBooksProvider` for family books; `TransactionEditScreen` + `DeleteTransactionUseCase` as-is.
- **New DAO:** `findByBookIds(...)` (multi-book) + a `watch*` stream (no `watch()` queries exist today).
- **Hash-chain:** swipe-delete soft-deletes only; add a chain-integrity-after-delete test.
- **IndexedStack:** filter/search/sort state survives tab switches — keepAlive: true decided in Phase 26 (natural under IndexedStack; filter state persists across tab switches).
- **Shared month-boundary util:** consolidate the `DateTime(y, m+1, 0, 23,59,59)` idiom (6 existing call sites) rather than adding a 7th. Extract `DateBoundaries` utility to `lib/shared/utils/`.
- **i18n:** all strings via `S.of(context)` (ja default, + zh/en); dates via `DateFormatter`; amounts via `NumberFormatter`. ~20–25 new ARB keys.
- **Stack:** add `table_calendar: ^3.2.0` (pin-safe; intl 0.20.2 compatible; no win32/native). Verify `flutter build ios` stays green.

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LIST-02 | Phase 24 — Data Layer Extension | Complete |
| SORT-01 | Phase 25 — Domain Models + Use Case | Complete |
| SORT-02 | Phase 25 — Domain Models + Use Case | Complete |
| SORT-03 | Phase 25 — Domain Models + Use Case | Complete |
| SORT-04 | Phase 25 — Domain Models + Use Case | Complete |
| FILTER-01 | Phase 26 — Providers + Shell Wiring | Complete |
| FILTER-02 | Phase 26 — Providers + Shell Wiring | Complete |
| FILTER-03 | Phase 26 — Providers + Shell Wiring | Complete |
| FILTER-04 | Phase 26 — Providers + Shell Wiring | Complete |
| CAL-01 | Phase 27 — Calendar Header + Month Summary | Complete |
| CAL-02 | Phase 27 — Calendar Header + Month Summary | Complete |
| CAL-03 | Phase 27 — Calendar Header + Month Summary | Complete |
| CAL-04 | Phase 27 — Calendar Header + Month Summary | Complete |
| LIST-01 | Phase 28 — Transaction Tile + Sort/Filter Bar | Complete |
| ROW-01 | Phase 28 — Transaction Tile + Sort/Filter Bar | Pending |
| ROW-02 | Phase 28 — Transaction Tile + Sort/Filter Bar | Pending |
| LIST-04 | Phase 29 — List Screen Assembly + Family | Pending |
| FAM-01 | Phase 29 — List Screen Assembly + Family | Pending |
| FAM-02 | Phase 29 — List Screen Assembly + Family | Pending |
| FAM-03 | Phase 29 — List Screen Assembly + Family | Pending |
| FAM-04 | Phase 29 — List Screen Assembly + Family | Pending |
| LIST-03 | Phase 30 — i18n + Empty States + Golden Polish | Pending |
