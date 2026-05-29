# Pitfalls Research — v1.4 列表功能 (Transaction List / 一覧)

**Domain:** Flutter + Riverpod 3 + Drift + SQLCipher calendar/list feature on a local-first family accounting app with hash-chain integrity and dual-ledger system
**Researched:** 2026-05-29
**Confidence:** HIGH (all findings derived from actual codebase inspection + CLAUDE.md rules)

---

## Critical Pitfalls

### Pitfall 1: Swipe-to-Delete Breaks the Hash Chain

**What goes wrong:**
The hash chain in `HashChainService` is a linked list where every transaction's `currentHash = SHA-256(id|amount|timestamp|previousHash)` and the successor's `prevHash` equals the deleted entry's `currentHash`. A soft-delete (setting `isDeleted = true`) leaves the chain topology intact — all subsequent `prevHash` references remain valid. A physical delete or any attempt to re-link the chain after removing an entry causes every downstream transaction to report as tampered when `verifyChain()` is called.

The existing `getLatestHash()` in `TransactionDao` filters `isDeleted.equals(false)` — meaning if a soft-deleted entry was the most recent, the next INSERT picks up the hash of a different row as `prevHash`, silently forking the chain. `DeleteTransactionUseCase` calls `softDelete()` correctly and does NOT re-link hashes. This is safe as long as `verifyChain()` is never called on a gap-containing set. If the list view or backup path re-verifies integrity, the silent gap surfaces.

**Why it happens:**
Developers reach for a direct DAO delete thinking it is "cleaner." The `deleteAllByBook` hard-delete method exists on the DAO and is tempting to reuse.

**How to avoid:**
- Wire swipe-delete exclusively to `DeleteTransactionUseCase.execute(id)`. Never call `_dao.deleteAllByBook` or raw Drift `delete()` on individual rows from user-facing list actions.
- Do NOT add a "re-link chain" step — that is tampering.
- Add a test: after soft-deleting a mid-chain transaction, `HashChainService.verifyChain()` on the remaining non-deleted rows must return `ChainVerificationResult.valid`.
- Always show a delete-confirmation dialog or undo SnackBar before committing the soft-delete, so the user can cancel.

**Warning signs:**
- Any code path touching `_dao.deleteAllByBook` or raw `_db.delete(_db.transactions)` on individual rows from the list screen.
- Any code attempting to update `prevHash` on successor rows after a delete.
- `verifyChain()` returning tampered IDs after a delete that previously passed.

**Phase to address:** Foundation phase (use-case wiring). Must be wired correctly before any list phase ships. A chain-integrity-after-delete test must accompany the swipe-delete implementation.

---

### Pitfall 2: IndexedStack Keeps List Provider State Alive After Tab Switch

**What goes wrong:**
`MainShellScreen` uses `IndexedStack` (confirmed at line 97 of `main_shell_screen.dart`) — all tab widgets remain mounted. Filter state providers declared `autoDispose` (Riverpod 3 default for `@riverpod`) will NOT be disposed on tab switch, because the widget subtree remains subscribed. A developer expecting filter state to reset on tab-leave will be surprised. Conversely, a provider that should survive will silently be recreated if the `@riverpod` annotation defaults to auto-dispose and the subscription count drops.

**Why it happens:**
Riverpod 3 auto-dispose is tied to widget subscription lifetime, not route/tab visibility. With `IndexedStack`, subscriptions are never dropped. CLAUDE.md explicitly notes the `keepAlive` reconciliation as a past audit finding.

**How to avoid:**
- Decide the tab-switch policy up front: filter state persists (most natural under `IndexedStack`) or resets (requires an explicit listener).
- For persistent filter state: use `keepAlive: true` on `selectedDayProvider`, `selectedMonthProvider`, `searchQueryProvider`, `activeSortProvider`, `activeLedgerFilterProvider`.
- For reset-on-tab-switch: add a `ref.listen(selectedTabIndexProvider, ...)` block in the list screen's `ConsumerStatefulWidget` that calls `ref.invalidate` on the relevant filter providers.
- Do NOT rely on auto-dispose to achieve either behavior under `IndexedStack` — it will not work as expected.

**Warning signs:**
- Search query typed on the list tab still shows when returning from another tab (unexpectedly persistent).
- Calendar month selection resets unexpectedly on re-focus (provider was auto-dispose, subscription briefly dropped).
- `ref.invalidate` calls in `MainShellScreen` added to compensate for the wrong disposal strategy.

**Phase to address:** List-screen state design phase. Decide and document `keepAlive` vs reset policy for every filter provider before implementation.

---

### Pitfall 3: Per-Day Aggregation Rebuilds Entire List on Every Filter Change

**What goes wrong:**
Calendar header shows per-day expense totals (up to 31 day cells). If calendar totals are derived from the same provider as the filterable list, every keystroke in search or sort toggle causes the calendar to re-render all day totals — even though day totals are independent of the text filter. Using a non-streaming `FutureProvider` for the transaction list also causes a loading flash on every filter change.

**Why it happens:**
Developers reach for a single "filtered list" provider and derive both the calendar aggregation and list rows from it. This conflates two different data shapes with different recomputation triggers.

**How to avoid:**
- Calendar day-totals live in a separate provider watching only `(bookId, month)` — not ledger filter, not text search.
- The filterable list rows are a separate provider derived from the full month list with client-side or server-side filter applied.
- Use `StreamProvider` wrapping a Drift `watch()` query for the transaction list so live updates (post-delete, post-sync) propagate without full re-fetch. `TransactionDao` has no watch queries currently — adding one is the correct approach for this feature.
- Use `select()` on providers where possible so calendar cells do not rebuild on unrelated state changes.

**Warning signs:**
- Calendar cells flickering or showing loading indicator while typing in the search bar.
- Full month DAO query executing on every sort direction toggle (visible in Flutter DevTools timeline).

**Phase to address:** Data layer phase (Drift watch query + provider topology). Design the provider graph before writing any widgets.

---

### Pitfall 4: Date-Range Boundary Errors in Month Calendar and Day Filter

**What goes wrong:**
The codebase uses a canonical idiom throughout:
- Month-end: `DateTime(y, m+1, 0, 23, 59, 59)` (confirmed in `time_window.dart`, `home_screen.dart`, `get_expense_trend_use_case.dart`)
- Day-end: `DateTime(y, m, d, 23, 59, 59)` (confirmed in `state_today_transactions.dart`)

Deviating causes boundary transactions to be missed. Specific failure modes:
- Using `DateTime(y, m, d)` (midnight) as the day-end boundary — transactions recorded at 23:45 are excluded.
- Using `DateTime(y, m+1, 1).subtract(const Duration(seconds: 1))` instead of the `(y, m+1, 0, 23, 59, 59)` idiom — functionally equivalent but inconsistent with the codebase standard and fragile at DST boundaries.
- Open-ended date range (`isBiggerOrEqualValue(startDate)` only, missing `isSmallerOrEqualValue(endDate)`) — pulls in future months.
- "Fixing" `DateTime(y, 0, ...)` (December last-year via month=0 underflow) — Dart handles it correctly; do not replace with `DateTime(y-1, 12, 31, 23, 59, 59)`.

**Why it happens:**
Developers unfamiliar with the idiom write alternative boundary calculations. Dart's `DateTime` auto-normalization makes all forms look correct in isolation.

**How to avoid:**
- Extract a shared `DateBoundaries.dayRange(DateTime day)` and `DateBoundaries.monthRange(int year, int month)` utility in `lib/shared/utils/` that encodes the canonical idiom in one place.
- Per-day filter: `start = DateTime(y, m, d)`, `end = DateTime(y, m, d, 23, 59, 59)`.
- Month: `start = DateTime(y, m, 1)`, `end = DateTime(y, m+1, 0, 23, 59, 59)`.
- Unit tests: transaction at 00:00:00 on day D is included; transaction at 23:59:59 on day D is included; transaction at 00:00:00 on day D+1 is excluded.

**Warning signs:**
- Transactions created after 23:00 on a given day not appearing when that day is tapped in the calendar.
- Last day of the month showing 0 totals when transactions exist.

**Phase to address:** Drift query / DAO phase. Boundary utility written and tested before any calendar or filter query is implemented.

---

### Pitfall 5: ProviderException Wrapping Swallows Real Errors in Tests

**What goes wrong:**
Riverpod 3 wraps all provider-thrown errors in `ProviderException`. Tests that assert `throwsA(isA<StateError>())` on a list-provider failure silently pass the wrong type check. CLAUDE.md documents this migration trap explicitly.

**Why it happens:**
Copy-paste from v2-era test code. The wrapping is documented but easy to forget when writing new test surfaces for delete-failure, filter-state-error, and DAO-error cases.

**How to avoid:**
- All test assertions on provider errors: `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<SpecificErrorType>()))`.
- Import `ProviderException` from `package:flutter_riverpod/misc.dart`.
- Use `ProviderContainer.test()` in all new list-feature tests.
- Use `waitForFirstValue<T>(container, provider)` from `test/helpers/test_provider_scope.dart` for async auto-dispose providers. Bare `await container.read(provider.future)` throws "Bad state: disposed during loading" on auto-dispose providers.

**Warning signs:**
- Test asserting `throwsA(isA<SomeError>())` on a provider without importing `ProviderException`.
- `ProviderContainer()` used without `.test()` in new tests.
- `await container.read(provider.future)` on any `@riverpod` provider.

**Phase to address:** Every phase that adds new providers or tests. Add to reviewer checklist.

---

### Pitfall 6: Dual-Ledger Total Contamination in Month Summary and Day Totals

**What goes wrong:**
Month summary and calendar day totals must be **expense-only** (v1.4 spec: "expense-only basis"). Mixing income transactions, or including Soul satisfaction scores in the total, produces wrong figures.

Specific risks:
- `SUM(amount)` without `WHERE type = 'expense'` guard — income transactions inflate the total.
- In family mode, including members' income transactions in shared calendar totals.
- Displaying Soul `soulSatisfaction` or Joy metrics in the list-tab month summary — those belong to AnalyticsScreen only (ADR-016).
- Case-sensitive string comparison for `ledgerType` column ('soul' vs 'Soul') — use the Dart enum's `.name` property consistently.

**Why it happens:**
Analytics use cases in `lib/application/analytics/` already apply these guards correctly for their screens, but a new list-feature DAO method written in isolation may not copy all guards.

**How to avoid:**
- Reuse existing `GetMonthlyReportUseCase` or its underlying DAO logic as the source for the list-tab month summary rather than writing a new aggregate query from scratch.
- Any new DAO method for list aggregation must include: `WHERE type = 'expense' AND is_deleted = 0`.
- Write a specific test: insert one income + one expense transaction; assert list-tab month summary = expense amount only.
- Do not surface Joy or satisfaction data in the list tab.

**Warning signs:**
- List-tab month summary total differs from AnalyticsScreen monthly report when no filters are active.
- Calendar day cells showing totals that include income transactions.

**Phase to address:** Month summary + calendar aggregation phase.

---

### Pitfall 7: Family Member Attribution Races with Stale Member Data

**What goes wrong:**
Transactions carry `deviceId` as author identifier. `GroupMemberDao.watchByGroupId` provides a stream of current members. If member list and transaction list are fetched at different times, attribution labels can be stale (member left group) or missing (new member not yet synced). If the list provider joins transactions against member data eagerly, a sync event updating member data triggers a full list rebuild even when no transactions changed.

**Why it happens:**
The natural implementation combines `transactionListProvider` + `memberListProvider` in a single `ref.watch` chain, causing any member update to rebuild the full list.

**How to avoid:**
- Keep transaction list and member display name resolution as separate providers. Resolve display names lazily per row via a `memberNameProvider(deviceId: id)` family, not by eagerly joining all members in the list provider.
- Use `GroupMemberDao.watchByGroupId` (already returns a `Stream`) as source for a `StreamProvider` so member updates propagate reactively without invalidating the transaction list.
- Handle "member not found" gracefully — show device ID suffix or `S.of(context).unknownMember` (ARB key) rather than throwing.

**Warning signs:**
- Entire transaction list rebuilds every sync heartbeat interval even when no transactions changed.
- Null errors on `memberName` when a member has left the group.
- Member filter chip showing stale names after sync.

**Phase to address:** Family-aware list phase, after single-user list is stable.

---

### Pitfall 8: `ref.watch` Used for Side Effects (Delete Confirmation, Undo SnackBar)

**What goes wrong:**
Showing an undo SnackBar after swipe-delete is a side effect triggered by a state change. Using `ref.watch` to trigger SnackBar display causes it to re-appear on every rebuild that produces the same delete-result state — not just on the initial delete event. CLAUDE.md: "Side-effect listeners belong in `ref.listen`, not `ref.watch`."

**Why it happens:**
Developers pattern-match on the delete result state `ref.watch(deleteStateProvider)` and trigger UI from within `build()`.

**How to avoid:**
- Delete result state (success / failure / undo-pending) must be surfaced via `ref.listen` to a `Notifier` holding the delete outcome.
- The undo action calls a `restoreTransaction` method that flips `isDeleted` back to false via the repository.
- Mirror the existing `FamilySyncNotificationRouteListener` pattern for side-effect routing.

**Warning signs:**
- SnackBar appearing twice after a single swipe.
- SnackBar re-appearing on hot-reload.
- SnackBar appearing when navigating back to the list screen.

**Phase to address:** List row interactions phase (swipe-delete + undo).

---

### Pitfall 9: Amount and Date Formatting Using Hardcoded Strings Instead of Infrastructure Formatters

**What goes wrong:**
List row amounts displayed with raw `toString()` or `Text('¥$amount')` lose tabular figure alignment (columns misalign), incorrect decimal places for non-JPY books, and wrong compact formatting (`1.2M` vs `123万`). Calendar day totals rendered with `DateFormat.MMMd()` directly break the ja/zh/en locale contract.

New ARB keys added for list UI that are missing from any of the three locale files cause `flutter gen-l10n` to fail and block the CI `flutter analyze` step.

**Why it happens:**
Amount display is a subtle rule — developers see amounts elsewhere and copy the style without checking `AppTextStyles`.

**How to avoid:**
- Amounts in list rows and calendar cells: always use `NumberFormatter` from `lib/infrastructure/i18n/formatters/number_formatter.dart` + `AppTextStyles.amountSmall` (which includes `FontFeature.tabularFigures()`). Never use `Text('¥$amount')`.
- Dates: use `DateFormatter` from `lib/infrastructure/i18n/formatters/date_formatter.dart`; always pass locale from `currentLocaleProvider`.
- ARB keys: add to ja/zh/en files in the same commit, then run `flutter gen-l10n`. The CI `flutter analyze` fails if any generated class references a missing key.

**Warning signs:**
- Amount column visually misaligned in a list mixing 3-digit and 6-digit amounts.
- Date showing in wrong format for a non-ja locale.
- `flutter gen-l10n` warning about missing keys.

**Phase to address:** List row widget phase, before any golden baselines are established for this screen.

---

### Pitfall 10: Golden Test Churn from List Screen Layout

**What goes wrong:**
The project has 19 golden PNG baselines in `test/golden/goldens/`. Adding the list tab introduces a screen with a calendar grid and variable-length rows — both highly susceptible to pixel-level layout shifts from: Flutter font metric changes across versions, calendar cell sizing differences between light/dark, and amount column width varying by transaction count. Baselines set too early require constant re-baselining noise.

**Why it happens:**
Goldens are created when a widget "looks right" during development, before layout is stable. Variable row count and calendar totals depending on test fixture data both cause churn.

**How to avoid:**
- Defer list-tab goldens until layout is fully stable (post-feature-complete, not mid-development).
- Scope goldens to isolated, data-fixture-driven widgets: single calendar cell (fixed total), single list row (fixed fields), month summary (fixed total). Do NOT golden the full list screen with many rows.
- For the calendar, golden only one locale (ja) × light/dark — the grid layout is not locale-sensitive.
- Use the existing `test/golden/` directory and `goldens/` subdirectory pattern. Do not create a separate `test/golden/list/` directory.

**Warning signs:**
- Golden files updated in the same commit as a functional change (unstable layout baselined).
- More than 12 new golden PNG files for this feature.
- Golden tests failing in CI on a PR that does not touch list screen layout.

**Phase to address:** Final polish phase, after all list feature widgets are layout-stable. Explicitly do not baseline goldens during list row or calendar implementation phases.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Single combined provider for calendar + filtered list | Fewer providers to wire | Calendar redraws on every search keystroke | Never — separate providers from day 1 |
| `FutureProvider` instead of `StreamProvider` for transaction list | Simpler initial code | Manual `ref.invalidate` after every mutation; post-delete list does not update automatically | Only for static/analytics data; never for mutable list |
| Physical delete instead of soft-delete | Simpler query (no `isDeleted` filter) | Breaks hash chain; breaks sync tombstone propagation | Never |
| Skip delete confirmation dialog | Faster UX prototype | Accidental swipes have no recovery path | Never — always confirm or provide undo |
| Duplicate `repository_providers.dart` for list feature | Fast wiring | Breaks `provider_graph_hygiene_test.dart` CI check | Never |
| Hard-coding `Locale('ja')` in list widget tests | Tests pass quickly | Missing zh/en coverage | Never — use `currentLocaleProvider` |

---

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Hash chain + swipe-delete | Calling any non-`DeleteTransactionUseCase` delete path | Always use `DeleteTransactionUseCase.execute(id)` — the only safe path, calls `softDelete()` |
| Drift + date filter | Using `DateTime.utc()` for boundary construction | Use local `DateTime(y, m, d)` — codebase stores timestamps as local time (confirmed from `state_today_transactions.dart`) |
| Riverpod + IndexedStack | Expecting auto-dispose to reset filter state on tab switch | State persists under `IndexedStack`; use explicit `ref.invalidate` in tab-switch listener if reset is desired |
| Family sync + list refresh | Forgetting to add list-tab invalidation in `MainShellScreen`'s sync listener | Add `ref.invalidate(listTransactionsProvider(...))` to the `syncStatusStreamProvider` listener at lines 34–91 of `main_shell_screen.dart` |
| Drift watch query + auto-dispose | `StreamProvider` for transaction list being auto-disposed while list tab is visible | Use `keepAlive: true` on the list's `StreamProvider`, or confirm `IndexedStack` keeps it subscribed |
| ARB + `flutter gen-l10n` | Adding new keys to only one locale file | Must update all 3 ARB files (ja/zh/en) atomically; `flutter gen-l10n` fails with partial updates |

---

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| Loading all transactions for a book into memory for client-side filter | Slow scroll init; OOM on 2000+ transactions | Push `ledgerType`, `categoryId`, `startDate`, `endDate` filters to SQL `WHERE` clause | ~500 transactions on mid-range device |
| Per-row member name lookup via individual DAO calls | List scroll jank proportional to row count | Fetch member map once per screen mount; cache in a `memberMapProvider` | ~20 rows in family mode |
| Calendar aggregation as N individual day-queries | Calendar header takes seconds on month load | Single aggregate query: `SELECT DATE(timestamp), SUM(amount) WHERE ... GROUP BY DATE(timestamp)` | ~200 transactions/month |
| Full list rebuild on sort change via `setState` / provider rebuild | Jank on sort toggle | `ListView.builder` with stable keys; sort provider returns new ordered list without item widget rebuild | Always visible; worse at 50+ items |
| Loading all months into memory for month-switch navigation | Memory spike when user navigates many months | Fetch only the displayed month; invalidate and re-fetch on month change | Month switching with 12+ months of data |

---

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Displaying raw `note` field from `TransactionRow` | Shows encrypted ciphertext to user | Always use domain `Transaction` model (decrypted in `TransactionRepositoryImpl._toModel()`); never use raw `TransactionRow` in UI |
| Logging `Transaction` fields during list debug | Leaks financial data to device logs | CLAUDE.md: "NEVER log sensitive data" — use redacted debug strings |
| Passing unencrypted `note` through route params to edit screen | Note exposed in navigation stack | Pass only `transactionId` to `TransactionEditScreen`; let edit screen re-load via repository |
| Persisting search query to SharedPreferences | Search history reveals financial patterns | Keep all filter state in Riverpod memory only; never persist search query |

---

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-----------------|
| No empty state for zero transactions on selected day | Confusing blank area after tapping calendar day | Show ARB key `listEmptyDay` ("この日の記録はありません") when filtered list is empty; add to all 3 locale files |
| Swipe-delete with no undo | Accidental delete of a family member's transaction with no recovery | Show SnackBar with `S.of(context).undoDelete` action; restore via `isDeleted = false` within SnackBar timeout |
| Calendar day cells showing Soul ledger totals | Contradicts spec ("expense-only basis") | Calendar cells: `WHERE type = 'expense'` only |
| Ledger color tag using wrong color | Users misread which ledger a row belongs to | From MEMORY.md: Soul = `#47B88A` (green), Survival = `#5A9CC8` (blue). Note: color names contradict ledger theme names — verify against `app_colors.dart` constants, not the CLAUDE.md description text |
| Sort state not visible | User doesn't know why order changed | Persistent sort indicator (icon + direction) in list header |
| Text search matching only category name | User types merchant name and gets no results | Search must cover category name + merchant + note fields per v1.4 spec |

---

## "Looks Done But Isn't" Checklist

- [ ] **Swipe-delete:** Calls `DeleteTransactionUseCase`, not a direct DAO method — verify with a unit test that `isDeleted = true` on the row after action.
- [ ] **Hash chain after delete:** `HashChainService.verifyChain()` on remaining non-deleted rows after a mid-chain soft-delete returns `valid`.
- [ ] **Day boundary:** Tap a day cell → list filters to that day → a transaction timestamped at 23:45 on that day appears.
- [ ] **Expense-only total:** Create one income + one expense transaction; list-tab month summary = expense amount only.
- [ ] **Ledger color:** Survival row shows blue tag, Soul row shows green tag (verify against actual constants, not memory).
- [ ] **Amount formatting:** All amounts use `AppTextStyles.amountSmall` + `NumberFormatter`; tabular figures visually align in a column with 1-digit and 5-digit amounts.
- [ ] **ARB parity:** `flutter gen-l10n` produces no warnings; all 3 locale files have identical key count.
- [ ] **Family member fallback:** A transaction with an unknown `deviceId` (member left group) shows graceful fallback label, not a null exception.
- [ ] **IndexedStack filter persistence:** Navigate away from list tab and back; filter/sort state is preserved (or reset, per spec decision).
- [ ] **`ref.listen` for SnackBar:** Delete a transaction; SnackBar appears exactly once; hot-reload does not trigger a second SnackBar.
- [ ] **List refresh on sync:** A sync cycle completing while the list tab is open causes the list to update without requiring a tab switch.

---

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Hard-delete shipped, breaking hash chain | HIGH | Requires backup restore or accepting integrity loss; must be caught in test — never ship |
| Incorrect date boundary (transactions missing from day filter) | LOW | Fix boundary utility; update tests; no data loss |
| Wrong ledger color | LOW | Update color constant reference; re-baseline affected goldens |
| ARB key missing in one locale | LOW | Add missing key; run `flutter gen-l10n`; CI unblocks |
| `ref.watch` side-effect causing SnackBar spam | MEDIUM | Refactor to `ref.listen`; no data loss; requires regression testing |
| Golden baseline set on unstable layout | LOW | Delete golden PNGs; re-baseline after layout stabilizes (`flutter test --update-goldens`) |
| Filter state unexpectedly resetting (wrong keepAlive) | LOW | Correct provider annotation; no data migration |

---

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Swipe-delete → hash chain break | Foundation / use-case wiring | `verifyChain()` passes after soft-delete test; no `deleteAllByBook` call path from list UI |
| IndexedStack + provider state | List state design (first list phase) | Manual tab-switch test; provider keepAlive audit via `riverpod_lint` |
| Per-day aggregation rebuilds on filter | Drift query + provider topology phase | DevTools: search keypress does NOT trigger calendar DAO query |
| Date-range boundary errors | DAO / Drift query phase | Unit tests: transactions at 00:00:00 and 23:59:59 on selected day both appear |
| ProviderException wrapping | Every phase with new providers | Code review checklist item on all provider error tests |
| Dual-ledger total contamination | Month summary aggregation phase | Test: income transaction excluded from summary total |
| Family member stale attribution | Family-aware list phase | Test: unknown deviceId shows fallback label; no null exception |
| `ref.watch` for SnackBar side effects | Row interaction phase | SnackBar appears exactly once; hot-reload clean |
| Amount/date formatting violations | List row widget phase | Visual QA + golden test before baseline |
| Golden test churn | Final polish phase (last) | Goldens only baselined after layout freeze; count < 12 new PNG files |

---

## Sources

- `/Users/xinz/Development/home-pocket-app/lib/infrastructure/crypto/services/hash_chain_service.dart` — hash chain implementation verified: soft-delete safe; hard-delete breaks chain linkage
- `/Users/xinz/Development/home-pocket-app/lib/application/accounting/delete_transaction_use_case.dart` — confirmed `softDelete()` path; no hash re-linking
- `/Users/xinz/Development/home-pocket-app/lib/data/daos/transaction_dao.dart` — confirmed `isDeleted` filter in all read queries; `softDelete` sets flag only; no watch queries exist yet
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/screens/main_shell_screen.dart` — confirmed `IndexedStack` at line 97; sync invalidation pattern at lines 34–91
- `/Users/xinz/Development/home-pocket-app/lib/features/analytics/domain/models/time_window.dart` — canonical `DateTime(y, m+1, 0, 23, 59, 59)` month-end idiom
- `/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/providers/state_today_transactions.dart` — canonical `DateTime(y, m, d, 23, 59, 59)` day-end idiom
- `/Users/xinz/Development/home-pocket-app/lib/core/theme/app_text_styles.dart` — confirmed `amountSmall/Medium/Large` with `FontFeature.tabularFigures()`
- `/Users/xinz/Development/home-pocket-app/CLAUDE.md` — Riverpod 3 conventions (ProviderException, keepAlive, ref.listen, async test pattern), i18n rules, amount display style, common pitfalls list

---
*Pitfalls research for: v1.4 Transaction List feature on Home Pocket (Flutter + Riverpod 3 + Drift + SQLCipher)*
*Researched: 2026-05-29*
