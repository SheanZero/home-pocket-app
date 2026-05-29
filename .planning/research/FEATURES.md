# Feature Research — Transaction List / Calendar Overview (v1.4)

**Domain:** Transaction List / Calendar Overview — kakeibo-style personal finance app (v1.4 List tab)
**Researched:** 2026-05-29
**Confidence:** HIGH (codebase analysis) / MEDIUM (competitor patterns via web search)

---

## Scope Note

This document covers ONLY the new List tab (v1.4 列表功能). The following already exist and are out of research scope: manual/voice/OCR entry via `TransactionDetailsForm`, dual-ledger categorization, AnalyticsScreen, HomeScreen recent-tx card, P2P family sync, happiness/Joy metric.

Explicit v1.4 out-of-scope (owner-stated): month settlement / month-lock, income tracking, "New" badge, amount-range filter.

---

## Feature Landscape

### Category A: Calendar Header

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Monthly grid calendar with per-day expense total | Standard in Zaim, MoneyForward ME, おカネレコ; users mentally model spending on a monthly grid — it's the defining pattern of kakeibo apps | M | New DAO method: `getDailyTotals(bookId, year, month)` → `Map<int, int>`; `NumberFormatter` compact format | Day cells: show compact total (e.g. ¥1.2万 ja/zh; ¥12k en) if >0 spending, blank otherwise. Never show zero. Use `AppTextStyles.amountSmall`. |
| Month navigation (prev/next arrows) | Every kakeibo app has this; without it the calendar is a dead-end | S | None new | Pure UI state: `selectedMonth` as `DateTime` in a `@riverpod` Notifier. Disallow future months (greyed arrows). |
| Current month as default | Standard — open List tab → land on current month | S | None | Notifier `build()` returns `DateTime.now()`. |
| Tap-a-day to filter list to that day | MoneyForward ME and おカネレコ both do this; the calendar is decorative without interactivity | S | Calendar state drives list `startDate`/`endDate` filter | Tap same day again to deselect (toggle). Selected day has filled cell / accent ring. |
| "Show all" / clear-day-filter control | Users need to return to full-month view after tapping a day | S | Day-filter state | Appears only when a day is selected. Localized: "× 全て表示" / "查看全部" / "Show all". |
| Month expense-only summary line | MoneyForward ME and Zaim both show month total; gives instant context below the calendar | S | Reuse existing `monthlyReportProvider` / `GetMonthlyReportUseCase` | "5月 合計 ¥42,300" style. Expense-only (income out of scope). Placed between calendar and list. |

### Category B: List Display

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Transaction rows: category emoji + name, ledger-color tag, date, amount | All kakeibo apps show this; the home recent-tx card already does it — users expect consistency | S | `HomeTransactionTile` (reuse/extend); `CategoryDisplayUtils` | Ledger tag: Survival (`AppColors.survival` #5A9CC8) or Soul (`AppColors.soul` #47B88A). Amount: `AppTextStyles.amountSmall`. Date shown per-row within day group. |
| Date-group dividers (per-day sections) | Zaim and おカネレコ group rows by date; enables day-by-day scanning | S | None new | Non-sticky dividers between day groups. When a single day is selected (day-filter active) suppress the group header (redundant). |
| Scrollable full-month list | Without scroll, deep month lists are inaccessible | S | `CustomScrollView` with `SliverList` or `ListView.builder` | Bottom nav bar overlaps content; add `SafeArea` bottom padding inside the list. |
| Pull-to-refresh | Standard mobile pattern to re-fetch after background sync | S | `ref.invalidate(listTransactionsProvider(...))` | Wrap in `RefreshIndicator`. Also wire `syncStatusStreamProvider` listener (same pattern as `MainShellScreen`) to auto-refresh on `syncing → synced` transition. |
| Empty state — no transactions in month | Without this, blank screen is confusing and looks broken | S | None | Illustration + localized: "この月に記録がありません" / "本月暂无记录" / "No entries this month". Include CTA hint: tap + to add. |
| Empty state — no match for active filter/search | Blank list with filters active looks like a bug | S | None | Separate copy: "条件に合う記録はありません" / "未找到匹配记录" / "No matching entries". Show "フィルターを解除" / "Clear filters" button. |

### Category C: Sorting

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Sort by transaction date (desc default) | Default in every kakeibo app; most recent first is universally expected | S | `TransactionDao.findByBookId` already sorts by `timestamp DESC` | No UI needed for default. This is the shipped DAO default. |
| Sort direction toggle (asc/desc) | Users scanning a full month chronologically want oldest-first | S | Sort state in Riverpod Notifier; flip `OrderingTerm` in query | Small sort icon button or dropdown chip. |
| Sort by amount (high → low / low → high) | Money Manager and おカネレコ both offer this; useful for spotting big spend | M | Current DAO only orders by timestamp; need in-memory sort on full-month load or new DAO `ORDER BY amount` | In-memory sort is simplest for single-month load (≤500 rows). |
| Sort by edit time (`updatedAt`) | Niche — "what did I enter most recently?" | M | `updatedAt` column exists on `TransactionRow` | Low priority; only add if a sort picker is already being built for amount sort. |

### Category D: Search and Filter

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Text search: merchant + note | All mature finance apps offer text search; expected once a user has >20 monthly entries | M | In-memory `String.contains` (case-insensitive) on full-month load; no new DAO query needed | Search operates on `transaction.merchant` and `transaction.note`. Fast enough for single-month data. |
| Text search: category name | Users say "カフェ" and expect to match coffee-category entries | M | Category names from `CategoryRepository` (already available); join in presentation layer after fetch | Requires mapping `categoryId → localizedCategoryName` before filtering. `CategoryDisplayUtils` already handles this. |
| Filter by ledger (Survival / Soul / All) | Dual-ledger is the app's core differentiator; filtering by ledger is essential | S | `GetTransactionsUseCase` already accepts `ledgerType` param | Toggle chips: All / 生存 / 魂 (ja: 全て / 生存 / 魂). Drives `ledgerType` param in use-case query. |
| Filter by category | おカネレコ premium and MoneyForward ME both do this; standard in any list with 10+ categories | M | `GetTransactionsUseCase` already accepts `categoryId`; need category picker UI | Bottom sheet with L1/L2 category tree. Single-select for v1.4. |
| Combined filters (date + ledger + category + search text) | Filters must compose; applying one must not clear another | M | Single `ListFilterState` Freezed object holding all active filter fields | All filters evaluated in AND logic. Active filter count badge on filter icon. |
| Clear all filters button | Without this, users get stuck in filtered view with no obvious escape | S | `ListFilterState.empty()` reset | Show only when at least one filter is active. |
| Collapsed search bar (reveal on tap) | Permanent search bar consumes vertical space in a content-dense screen | S | AnimatedContainer or simple Visibility toggle | Search icon in toolbar header; expands on tap. Standard iOS/Android pattern. |

### Category E: Row Interactions

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Tap row → TransactionEditScreen | v1.3 ships `TransactionEditScreen` and `TransactionDetailsForm`; must be reachable from the list | S | `TransactionEditScreen` (exists, v1.3); GoRouter or `Navigator.push` | `await Navigator.push(TransactionEditScreen(transaction: tx))`. If result `== true`, invalidate list provider. Same pop-with-result pattern as home screen (D-18). |
| Swipe-to-delete with confirmation dialog | Standard mobile delete gesture in all kakeibo apps (Zaim, MoneyForward, おカネレコ); users expect it | M | Flutter `Dismissible` widget; `DeleteTransactionUseCase` (exists); AlertDialog | Left-swipe reveals red trash background. `confirmDismiss` callback shows AlertDialog. On confirm: `DeleteTransactionUseCase.execute(id)`, show SnackBar, refresh list. Swipe-right disabled or no-op. |
| Delete confirmation dialog | Destructive action must be confirmed; skipping causes user rage | S | AlertDialog (no new deps) | "この記録を削除しますか？" / "确认删除此记录？" / "Delete this entry?" with Cancel + Delete. |
| Undo delete (SnackBar, 5s) | Material Design pattern; reduces anxiety around destructive action | M | New `RestoreTransactionUseCase` (soft-delete reversal) OR optimistic-UI with delayed commit | MEDIUM because undo requires either a restore use case or pending-delete state in the Notifier. Simplest implementation: show SnackBar with action; if tapped before 5s, call restore. Flag as P2 if scope is tight — delete-with-confirm is sufficient for v1.4 launch. |

### Category F: Family-Aware Display

| Feature | Why Expected | Complexity | Dependencies | Notes |
|---------|--------------|------------|--------------|-------|
| Include family members' shadow book transactions in the unified list | v1.4 goal; users in family mode expect to see everyone's entries in one place | L | `shadowBooksProvider` (exists); `GetTransactionsUseCase` called per shadow book; merge + sort results by timestamp | Home screen already does this for today. Extend to month range. Each shadow book queried separately; results merged and sorted by `timestamp DESC, id DESC`. |
| Per-row member attribution (avatar emoji chip + name) | Without attribution, the family list is undifferentiated — you can't tell whose entry is whose | S | `ShadowBookInfo.memberAvatarEmoji` + `memberDisplayName` (already in `ShadowBookInfo`) | Add member chip to tile: avatar emoji + short display name. Own entries: no chip (or "Me" chip if family mode). Same tag style as `HomeTransactionTile.tagText`. |
| Member filter (show one member's entries only) | Family list with 4 members can be very noisy; standard in family kakeibo apps | M | `GroupInfo.members` list; `ShadowBookInfo` already maps book → member | Filter chip per member name in filter panel. Drives which shadow books are included in merge query. |
| "Mine only" shortcut toggle | Quick way to focus on own transactions without navigating filter panel | S | Member filter state | Toggle chip: "自分のみ" / "仅我的" / "Mine only". Deselects other member chips. |
| Auto-refresh after sync completes | Family list goes stale after P2P sync arrives; must auto-refresh | S | `syncStatusStreamProvider` listener (same pattern as `MainShellScreen`) | `ref.listen(syncStatusStreamProvider, ...)` in list screen; invalidate list provider on `syncing → synced` transition. |

---

## Feature Dependencies

```
Month calendar grid
    └──requires──> new getDailyTotals DAO query
    └──requires──> GetMonthlyDailyTotalsUseCase (new in lib/application/accounting/)
    └──enhances──> list day-filter (tap day sets ListFilterState.selectedDay)

List display (full month)
    └──requires──> GetTransactionsUseCase month-range query (exists; already accepts startDate/endDate)
    └──requires──> CategoryRepository for name lookup (exists)
    └──requires──> ListFilterState Freezed model (new)

Text search
    └──requires──> full-month transactions loaded in memory
    └──conflicts──> pagination (do not paginate if search/sort-by-amount are active; load all for single month)

Sort by amount / edit time
    └──requires──> full list loaded in memory
    └──conflicts──> pagination (same conflict as text search)

Family-aware list
    └──requires──> shadowBooksProvider (exists)
    └──requires──> TaggedTransaction Freezed model (new: Transaction + nullable memberTag)
    └──requires──> multi-book merge + sort (new logic in provider or use case)
    └──enhances──> member filter (drives which books are included in query)

Swipe-to-delete
    └──requires──> DeleteTransactionUseCase (exists)
    └──requires──> confirmation dialog (AlertDialog, no new deps)
    └──enhances──> undo SnackBar (optional P2; requires RestoreTransactionUseCase or optimistic-UI)

Tap row → edit
    └──requires──> TransactionEditScreen (exists, v1.3)
    └──requires──> list provider invalidation on pop-with-result==true
```

### Dependency Notes

- **`getDailyTotals` is a new DAO method.** No current DAO query produces `Map<int, int>` (day → totalExpense) for a given book/month. This is a blocking dependency for the calendar grid. Can be a Drift `groupBy` query or a simple Dart aggregate on the full-month load. Drift approach is cleaner for the data layer; Dart aggregate avoids a new DAO surface if the month load is already happening.
- **`ListFilterState` Freezed model is the coordination point.** All active filter values (selectedDay, ledgerType, categoryId, searchText, selectedMemberDeviceIds) must live in a single Freezed object so filter composition is a pure function: `applyFilters(List<TaggedTransaction>, ListFilterState) → List<TaggedTransaction>`. Scattered per-filter Riverpod state leads to dependency ordering bugs.
- **Family list merge is medium-complexity.** `shadowBooksProvider` exists and provides `List<ShadowBookInfo>`. For the list tab, query each shadow book for the same month range, tag each `Transaction` with the member's display name + emoji, merge, sort. A lightweight `TaggedTransaction` Freezed value type (holds `transaction` + nullable `MemberTag`) is the cleanest model.
- **Pagination vs. full-month load.** For a single month, loading all transactions into memory and filtering/sorting in Dart is fast enough (≤500 rows typical; even 4-member family ≤2000). This unblocks text search and amount sort without cursor-pagination complexity. Re-evaluate if family groups with >2000 monthly entries emerge.
- **No new DAO query needed for text search or amount sort.** Both operate on the full-month list already loaded for the calendar and list display.

---

## New Artifacts Required

These do not exist in the codebase and must be created for v1.4:

| Artifact | Layer | Why Needed |
|----------|-------|-----------|
| `getDailyTotals(bookId, year, month)` | `TransactionDao` | Calendar grid per-day expense totals |
| `GetMonthlyDailyTotalsUseCase` | `lib/application/accounting/` | Wraps DAO, exposes `Map<int, int>` |
| `ListFilterState` (Freezed) | `lib/features/list/domain/models/` (new feature) or `lib/features/accounting/domain/models/` | Coordination point for all active filters |
| `TaggedTransaction` (Freezed) | Same as ListFilterState | Transaction + nullable member attribution for family-aware rows |
| `ListScreen` | `lib/features/list/presentation/screens/` | Replaces placeholder `Center(child: Text(S.of(context).listTab))` in `MainShellScreen` |
| `listTransactionsProvider` | `lib/features/list/presentation/providers/` | Async provider: fetch + merge (own + shadow) + apply filters |
| `dailyTotalsProvider` | `lib/features/list/presentation/providers/` | Async provider: per-day totals for calendar grid |
| `listFilterStateProvider` | `lib/features/list/presentation/providers/` | Notifier holding `ListFilterState` |
| `ListCalendarWidget` | `lib/features/list/presentation/widgets/` | Monthly grid calendar component |
| `ListTransactionTile` | `lib/features/list/presentation/widgets/` | Extended `HomeTransactionTile` with member attribution |
| ARB keys (all 3 locales) | `lib/l10n/*.arb` | `listEmptyMonth`, `listEmptyFilter`, `listClearFilters`, `listSortDate`, `listSortAmount`, `listSortAsc`, `listSortDesc`, `listFilterLedgerAll`, `listFilterSurvival`, `listFilterSoul`, `listFilterCategory`, `listFilterMember`, `listFilterMineOnly`, `listDeleteConfirmTitle`, `listDeleteConfirmBody`, `listDeleteConfirm`, `listDeleteCancel`, `listMonthTotal`, `listShowAll`, `listUndoDelete` (if undo added) |
| `RestoreTransactionUseCase` (P2) | `lib/application/accounting/` | Undo delete; only if undo SnackBar is in scope |

---

## Anti-Features (Explicitly NOT for v1.4)

| Anti-Feature | Why Requested | Why Excluded | Alternative |
|---|---|---|---|
| Month settlement / month-lock | Some kakeibo apps let users "close" a month; prevents retroactive edits | Owner-stated out of scope; adds lock state complexity and conflicts with family sync CRDT apply pipeline | Not applicable for v1.4 |
| Income tracking in list | Zaim and MoneyForward ME show income rows alongside expenses | Owner-stated out of scope; expense-only is the product's framing | Income column in AnalyticsScreen (future) |
| "New" badge on recently synced entries | Common in multi-device apps to show recently arrived items | Owner-stated out of scope; adds badge state that must be cleared | Rely on pull-to-refresh and sync-triggered auto-refresh |
| Amount-range filter (e.g. ¥500–¥2,000) | Power-user feature for finding mid-range expenses | Owner-stated out of scope; adds filter UI complexity for low usage | Sort by amount exposes large/small outliers |
| Long-press row: share / copy to clipboard | Power-user gesture seen in some EN finance apps | Anti-feature for v1.4; privacy-sensitive (financial data sharing) | Edit screen handles row-level actions |
| Joy/happiness metrics on list rows | Would mirror AnalyticsScreen soul-satisfaction data | AnalyticsScreen owns this surface; duplicating it on list rows is redundant and dilutes focus | AnalyticsScreen per-category breakdown already exists |
| Pagination / infinite scroll | Common UX pattern for large lists | Single-month load (≤500 rows) is fast; pagination conflicts with in-memory search/sort-by-amount | Load-all per month; add pagination only if perf degrades with large family groups |
| Swipe-right-to-edit | Some apps use right-swipe for edit to complement left-swipe delete | Accidental swipe on "edit" is less costly than accidental swipe on "delete", but adds gesture disambiguation complexity | Tap-to-edit is sufficient; avoids dual-swipe confusion |

---

## MVP Definition

### Launch With (v1.4 core)

All are required for the List tab to be non-placeholder and match the owner's stated target features.

- [ ] Calendar grid with per-day expense totals + month nav — *the visual anchor of the screen; without this it's a plain list*
- [ ] Tap-a-day to filter + clear-day control — *makes the calendar interactive, not decorative*
- [ ] Month expense-only summary line — *single line; reuses existing report use case*
- [ ] Transaction list rows with date-group dividers — *core list display*
- [ ] Sort: date asc/desc toggle — *default (desc) ships free; toggle is low-cost and expected*
- [ ] Text search: merchant + note + category name — *essential for months with >20 entries*
- [ ] Filter by ledger (Survival / Soul / All) — *core dual-ledger differentiator; without this the list has no ledger awareness*
- [ ] Filter by category — *standard in all mature kakeibo apps*
- [ ] Combined filter state + clear all — *filters must compose; clear-all is required escape hatch*
- [ ] Tap row → TransactionEditScreen — *edit path must be reachable from every transaction surface*
- [ ] Swipe-to-delete with confirmation dialog — *standard destructive row action*
- [ ] Empty states: no-entries-in-month and no-filter-match — *blank screen without empty state is broken UX*
- [ ] Family-aware unified list with member attribution — *scoped to family/group mode; own entries always included*
- [ ] Member filter + "Mine only" shortcut — *required when family list is 4× volume*
- [ ] Pull-to-refresh + sync-triggered auto-refresh — *local-first apps must expose manual refresh*

### Add After Validation (post-v1.4)

- [ ] Sort by amount (high→low / low→high) — *low demand signal initially; add sort picker after usage data*
- [ ] Sort by edit time (`updatedAt`) — *niche; defer until sort picker exists*
- [ ] Undo delete SnackBar — *reduces friction but requires `RestoreTransactionUseCase`; defer if scope tight*
- [ ] Loading skeleton / shimmer rows — *polish; only noticeable on first cold load on slow devices*

### Future Consideration (v2+)

- [ ] Pagination / virtual scroll — *only if family groups with >2000 monthly entries cause jank*
- [ ] Cross-month date range filter in list tab — *AnalyticsScreen already owns this; only add if List tab use-cases demand it*
- [ ] Export filtered list to CSV / PDF — *privacy-sensitive; requires explicit user opt-in; out of v1.x scope*

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Calendar grid + per-day totals | HIGH | M | P1 |
| Tap-a-day filter | HIGH | S | P1 |
| Month total summary | HIGH | S | P1 |
| List rows + date dividers | HIGH | S | P1 |
| Date sort asc/desc toggle | HIGH | S | P1 |
| Text search | HIGH | M | P1 |
| Ledger filter | HIGH | S | P1 |
| Category filter | MEDIUM | M | P1 |
| Combined filter state + clear | HIGH | M | P1 |
| Tap → edit | HIGH | S | P1 |
| Swipe-to-delete + confirm | HIGH | M | P1 |
| Empty states (month / filter) | HIGH | S | P1 |
| Family list + member attribution | HIGH | L | P1 |
| Member filter + mine-only | MEDIUM | M | P1 |
| Pull-to-refresh + sync refresh | MEDIUM | S | P1 |
| Sort by amount | LOW | M | P2 |
| Undo delete | MEDIUM | M | P2 |
| Loading skeleton | LOW | S | P2 |
| Sort by edit time | LOW | M | P3 |

---

## Competitor Feature Analysis

| Feature | Zaim | MoneyForward ME | おカネレコ | Money Manager (Okanemochi) | Our Approach |
|---------|------|-----------------|-----------|---------------------------|--------------|
| Calendar with per-day totals | Yes — daily cash-flow dots + amounts | Yes — per-day income/expense | Yes — calendar view toggle | Calendar view available | Expense-only totals per day cell |
| Tap-day to filter | Yes | Yes | Yes | Yes | Toggle: tap selects, tap again deselects; "Show all" chip |
| Month navigation | Yes | Yes | Yes | Yes | Prev/next arrows; no future months |
| Month total summary | Yes | Yes | Yes | Yes | Expense-only; single line above list |
| Ledger filter | N/A (single ledger) | N/A | N/A | Category-based | Survival / Soul / All chips — Home Pocket differentiator |
| Text search | Yes (some on paid) | Yes | Yes (premium) | Yes | In-memory search on full month; free |
| Category filter | Yes | Yes | Yes | Yes | Bottom sheet L1/L2 tree; single-select |
| Swipe-to-delete | Yes | Yes | Yes | Yes | `Dismissible` + AlertDialog confirm |
| Sort options | Date typically | Date + amount | Date typically | Date + amount + category | Date asc/desc v1.4; amount P2 |
| Family member attribution | N/A (single user) | Shared household (paid) | Family version (paid app) | N/A | Emoji avatar chip per row; member filter |
| Empty state | Illustration + text | Illustration + CTA | Text only | Standard empty state | Illustration + localized text + CTA hint |

---

## Implementation Notes for This Codebase

These observations help the roadmap phase the work correctly.

**`getDailyTotals` is a blocking dependency for the calendar.**
The calendar grid needs a `Map<int, int>` (day → totalExpense). Options: (a) Drift `groupBy` query on `timestamp` in `TransactionDao` — cleanest for data layer; (b) load full-month transactions and aggregate in Dart in the provider — avoids a new DAO method. Either approach is valid; the Drift query is ~5 lines and more testable.

**`TransactionEditScreen` pop-with-result is already wired.**
v1.3 D-18 contract: `Navigator.pop(context, true)` on save success. The list screen just needs `await Navigator.push(...)` and `if (result == true) ref.invalidate(listTransactionsProvider(...))`.

**`HomeTransactionTile` is pure UI — reuse or extend.**
It already handles ledger tag color, merchant, category, amount, satisfaction icon. For the list tab, extend with an optional `memberTag` parameter (nullable `MemberTag` with emoji + shortName) rather than forking a separate widget. The member tag renders using the same tag container as the ledger tag but with a different color scheme.

**`shadowBooksProvider` gives `List<ShadowBookInfo>` synchronously (after initial load).**
Each `ShadowBookInfo` has `.book.id` (to query transactions) and `.memberDisplayName` + `.memberAvatarEmoji` (for attribution). The pattern is: for each shadow book, call `GetTransactionsUseCase` with the month range, wrap each result in `TaggedTransaction(transaction: tx, memberTag: MemberTag(emoji: info.memberAvatarEmoji, name: info.memberDisplayName))`, merge all lists, sort by `timestamp DESC`.

**`GetTransactionsUseCase` already accepts `ledgerType` and `categoryId`.**
These can be passed directly for ledger/category pre-filtering (server-side in DAO). Text search and sort-by-amount are post-fetch in-memory operations. This hybrid approach is clean: use the DAO for indexed filters (ledger, category, date range), do non-indexed operations in Dart.

**ARB key count will increase.**
Current count: 506 keys per locale (post-v1.3). Estimated new keys for v1.4: ~20–25 (see "New Artifacts" table above). Run `flutter gen-l10n` after each ARB update. Parity across ja/zh/en is a hard constraint.

**`ListFilterState` should be a `@riverpod` Notifier (not a Freezed-only class).**
The filter state changes frequently (search keystrokes, chip taps). Use `@riverpod` with `keepAlive: false` so it auto-disposes when the List tab is not active. Reset to `ListFilterState.empty()` on month navigation to avoid a stale filter on a new month.

---

## Sources

- Codebase analysis: `TransactionDao`, `GetTransactionsUseCase`, `DeleteTransactionUseCase`, `shadowBooksProvider`, `HomeTransactionTile`, `TransactionListCard`, `MainShellScreen`, `TransactionEditScreen`, `GroupMember`, `ShadowBookInfo`, `GroupInfo`
- [Zaim — Google Play listing](https://play.google.com/store/apps/details?id=net.zaim.android) — calendar, per-day totals, swipe-delete patterns
- [MoneyForward ME — calendar and list UX (IGNITE blog)](https://igni7e.com/blog/budgeting-apps) — calendar filter, month-total display
- [おカネレコ feature page](https://okane-reco.com/function/7206/) — calendar+list duality, family version features
- [Money Manager (Okanemochi) — App Store](https://apps.apple.com/tn/app/okanemochi-money-manager/id6695761026) — swipe-to-delete, sort/filter options
- [Money Manager Android wiki — Account Transactions List](https://github.com/moneymanagerex/android-money-manager-ex/wiki/Account-Transactions-List) — transaction list sort/filter patterns
- [Flutter Dismissible cookbook](https://docs.flutter.dev/cookbook/gestures/dismissible) — swipe-to-delete implementation pattern

---
*Feature research for: v1.4 Transaction List / Calendar Overview (Home Pocket / まもる家計簿)*
*Researched: 2026-05-29*
