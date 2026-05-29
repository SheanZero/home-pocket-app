# Stack Research

**Domain:** Flutter app — v1.4 列表功能 (Transaction List tab)
**Researched:** 2026-05-29
**Confidence:** HIGH — versions verified against pub.dev; pubspec.yaml + pubspec.lock inspected; Drift docs fetched via Context7; table_calendar pub.dev entry confirmed; existing DAO/widget surface read directly from source.

---

## TL;DR (read this first)

**Add exactly one package: `table_calendar: ^3.2.0`.** Everything else the List tab needs — Drift queries, Riverpod providers, swipe-to-delete, text search, sort/filter state, family-aware aggregation, GoRouter navigation — is already covered by the locked stack.

`table_calendar` requires `intl: ^0.20.0`, which is compatible with the pinned `intl: 0.20.2`. It has no win32 dependency and no transitive conflicts with the `file_picker 11` / `package_info_plus 9` / `share_plus 12` trio. iOS build stays green.

The calendar can be wrapped in a `CalendarBuilders`-driven custom cell that injects per-day expense totals using the app's `AppTextStyles`, `AppColors`, and Wa-Modern dual-theme extension — so it fits the design system without fighting the widget internals.

---

## What Is Already Installed (relevant to v1.4)

From `pubspec.yaml` (verified 2026-05-29):

| Locked Dependency | Version | v1.4 Use |
|---|---|---|
| `flutter_riverpod` | `^3.1.0` | `@riverpod` providers for list state (filters, sort, selected day, search query) |
| `riverpod_annotation` | `^4.0.0` | `@riverpod` code-gen on new list/calendar providers |
| `freezed_annotation` | `^3.0.0` | Immutable filter/sort state models (`ListFilterState`, `SortOrder`) |
| `drift` | `^2.25.0` | `findByBookId` (already exists with date range + ledger + category filters); `getDailyTotals` already exists in `AnalyticsDao`; new `findByBookIdForList` needed for dynamic sort + text search |
| `sqlcipher_flutter_libs` | `^0.6.7` | Encrypted DB — unchanged |
| `intl` | `0.20.2` (exact pin) | `DateFormatter` / `NumberFormatter` for calendar day labels and amount display |
| `flutter_localizations` | sdk | ARB keys for list tab labels, empty states, filter chips, confirm-delete dialog |
| `collection` | `^1.19.1` | `groupBy` for per-day transaction bucketing in the calendar cell builder |
| `lucide_icons_flutter` | `^3.1.14` | Sort/filter icon assets already in the icon set |

No new dev-dep additions required: `mocktail`, `build_runner`, `freezed`, `riverpod_generator`, `drift_dev`, `custom_lint`, `riverpod_lint`, `import_guard_custom_lint` are all current and cover v1.4's code-gen and test needs.

---

## Recommended Stack by v1.4 Capability

### Capability 1 — Month calendar grid with per-day expense totals

**Recommendation: `table_calendar: ^3.2.0`.**

Rationale for adding a package (not hand-building a GridView):

- A calendar month grid has non-trivial interaction surface: month navigation (swipe + header chevrons), locale-aware day-of-week headers (ja Sunday-start vs ISO Monday-start), selected-day highlight state, correct date arithmetic across month boundaries, and RTL safety. Replicating this as a `GridView` requires ~300–400 lines of date arithmetic, hit-test handling, and layout edge-case code. The risk-adjusted cost exceeds the package.
- `table_calendar` 3.2.0 exposes `CalendarBuilders.defaultBuilder` and `CalendarBuilders.markerBuilder`, giving complete control over the day cell — the per-day expense total, the selected-day ring, and empty-day styling can all use `AppTextStyles`, `AppColors`, and the `context.wmTextPrimary` / `context.wmCard` theme extension without the package dictating any visual chrome.
- The package is `intl: ^0.20.0` — fully compatible with `0.20.2` pin. Its only other dep, `simple_gesture_detector ^0.2.0`, is a pure Flutter/Dart package with no win32 or native code.
- No iOS CocoaPods changes; no Swift/Kotlin native surface; no capability conflicts with the Podfile `post_install` SQLCipher strip.

Per-day expense totals come from the **existing** `AnalyticsDao.getDailyTotals()` — this method already does `DATE(timestamp, 'unixepoch', 'localtime') GROUP BY day SUM(amount)` for a date range. No new DAO query needed for the calendar data source.

Integration point: a `@riverpod` provider `calendarDailyTotals(bookId, year, month)` reads from `AnalyticsRepository.getDailyTotals` and returns `Map<DateTime, int>` (date → total-expense in sub-units). The calendar passes this map to `CalendarBuilders.defaultBuilder` via a closure. When the user switches months, the focused-month `StateProvider` updates, the provider recomputes, and the calendar re-renders.

**Design fit:** The custom day-cell builder injects the per-day amount using `AppTextStyles.micro` (10px bold) with tabular figures, coloured `AppColors.accentPrimary` if the amount is non-zero, muted `AppColors.textTertiary` otherwise. The selected-day ring reuses `AppColors.accentPrimary`. No `CalendarStyle` theming override needed — the builder replaces the entire cell.

### Capability 2 — Sortable, text-searchable, filterable transaction list

**Recommendation: extend `TransactionDao.findByBookId` with dynamic sort + text search.**

The existing `findByBookId` already accepts `ledgerType`, `categoryId`, `startDate`, `endDate`, `limit`, `offset`. For v1.4 we need:

1. **Dynamic sort:** `OrderingTerm` already accepts any `Expression` column and `.asc()` / `.desc()`. Adding a `SortField` enum (date / updatedAt / amount) and `SortDirection` enum (asc / desc) to the query is a pure DAO extension — no new library. The Drift query builder composes `orderBy` terms at runtime without string concatenation.

2. **Text search (category name / merchant / note):** The `merchant` and `note` columns are on the `transactions` table — a `WHERE (merchant LIKE ? OR note LIKE ?)` clause maps to `query.where((t) => t.merchant.like('%$q%') | t.note.like('%$q%'))`. Category-name search requires a JOIN to `categories` table on `categories.name LIKE ?`. This is a Drift `innerJoin` / `leftOuterJoin` with an `OrderingTerm` on the joined table — the existing `AnalyticsDao` already demonstrates the `customSelect` + `readsFrom` pattern; the `TransactionDao` method can use the typed-Dart-query API with a join.

3. **Debounce:** Text search debounce (300ms) is a plain `dart:async Timer` — the same pattern already used in `VoiceInputScreen` (`_parseDebounce`). No new package.

4. **Filter chip state + sort state:** A `@freezed` class `TransactionListFilter` holds `ledgerType?`, `categoryId?`, `searchQuery?`, `sortField`, `sortDirection`, `selectedDay?`. A `@riverpod` `Notifier` holds this state. The provider for the list watches the filter notifier and calls the DAO.

5. **Streaming vs. one-shot:** Drift's `query.watch()` returns a `Stream<List<...>>` that re-emits on any write to the `transactions` table. For the list tab, using `.watch()` means swipe-delete and any new entry from the FAB propagate to the list automatically. The Riverpod `StreamProvider` pattern is already used in the family sync feature; same approach here.

Family-aware extension (Capability 4) adds `bookIds: List<String>` to the DAO query, which extends the `WHERE book_id = ?` to `WHERE book_id IN (?)` — a Drift `isIn` clause. No schema change.

### Capability 3 — Swipe-to-delete rows

**Recommendation: Flutter's built-in `Dismissible` widget.** No package needed.

`Dismissible` covers the full v1.4 swipe-delete requirement:
- Horizontal swipe to reveal a delete background (red with trash icon using `lucide_icons_flutter` which is already installed)
- `confirmDismiss` callback to show an `AlertDialog` confirmation (matching the existing `showDialog` pattern used in Settings data-management)
- `onDismissed` callback to call `softDelete` on the DAO via the existing `DeleteTransactionUseCase` (or call directly through the repository if a use case doesn't yet exist)
- `DismissDirection.endToStart` only (right-to-left) to avoid accidental left-swipe dismissals

`Dismissible` requires a `Key` per row — the transaction ID (a ULID string, already stored in `TransactionRow.id`) is the canonical key.

Alternatives considered and rejected:
- `flutter_slidable` (pub.dev) — adds persistent action trays, animated icon labels, and slidable configs that are heavier than required. The design spec is "swipe-to-delete with confirmation"; there are no secondary actions. `Dismissible` is the correct primitive for one-action swipe-delete.
- Custom `GestureDetector` approach — no benefit over `Dismissible` and substantially more code for identical UX.

### Capability 4 — Family-aware list with per-member attribution

**Recommendation: extend the DAO query to accept `List<String> bookIds` + join `GroupMembers` for attribution. No new package.**

The `transactions` table stores `device_id` per row. The `group_members` table stores `(group_id, device_id, display_name, avatar_emoji)`. The link is: `transactions.device_id = group_members.device_id`. This is the exact same logic used in `ShadowBookInfo` (the home tab's family aggregate), which resolves member attribution by matching `book.ownerDeviceId` to `group.members`.

For the list tab, the family-aware query:
1. Fetches personal book transactions (current bookId) + shadow books' bookIds from `shadowBooksProvider` (already exists)
2. Passes `bookIds` list to the DAO (a Drift `isIn` clause)
3. For each returned row, resolves member display from the in-memory `activeGroupProvider` member list (already loaded) — no JOIN needed at the DAO level since the member map is already in Riverpod state

The member filter chip (show all / show only member X) is a client-side filter over the already-loaded `activeGroupProvider` member list. No new DAO method needed for this filter.

Attribution display per row: small avatar emoji chip + display name label, visible only when a family is active. The `ShadowBookInfo` pattern is the template.

---

## New Package Addition

| Package | Version | Purpose | Why This One |
|---------|---------|---------|-------------|
| `table_calendar` | `^3.2.0` | Month calendar grid with day-selection and custom cell builder | Saves ~350 lines of date arithmetic + layout edge cases; custom builder API fits the design system; intl-compatible; no win32 / no iOS native code |

### Dependency safety check

| Concern | Status |
|---|---|
| `intl` compatibility | `table_calendar` requires `^0.20.0`; project pins `0.20.2` — compatible |
| `simple_gesture_detector` (transitive) | Pure Flutter/Dart, no native code, no win32 |
| `win32` conflict | `table_calendar` has no win32 dep; project's `win32: 5.15.0` (transitive from `file_picker 11`) is unaffected |
| iOS CocoaPods | No new pods; no change to `post_install` strip |
| `flutter build ios --debug --no-codesign` | No new platform code; build outcome unchanged |

### Installation

```bash
# Add to pubspec.yaml dependencies:
#   table_calendar: ^3.2.0

flutter pub get
# No build_runner changes for the package itself.
# Run build_runner after adding @freezed / @riverpod annotated classes:
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Drift Query Patterns for v1.4

### Pattern 1 — Dynamic sort on the transaction list

```dart
// In TransactionDao — add to findByBookId or add a new findByBookIdForList
OrderingTerm _sortTerm(Transactions t, SortField field, bool descending) {
  final expr = switch (field) {
    SortField.date      => t.timestamp,
    SortField.editTime  => t.updatedAt, // nullable; treat null as createdAt
    SortField.amount    => t.amount,
  };
  return descending ? OrderingTerm.desc(expr) : OrderingTerm.asc(expr);
}
```

For `updatedAt` (nullable): use Drift's `coalesce([t.updatedAt, t.createdAt])` expression so rows with no `updatedAt` fall back to `createdAt` — this avoids NULL sort instability.

### Pattern 2 — Text search with merchant + note (same table, no join needed)

```dart
if (searchQuery.isNotEmpty) {
  final q = '%${searchQuery.toLowerCase()}%';
  query.where(
    (t) => t.merchant.lower().like(q) | t.note.lower().like(q),
  );
}
```

For category-name search, use `customSelect` with a `LEFT JOIN categories ON ...` and a `readsFrom: {_db.transactions, _db.categories}` clause so the stream updates when either table changes.

### Pattern 3 — Per-day expense rollup (already exists)

`AnalyticsDao.getDailyTotals` does `DATE(timestamp, 'unixepoch', 'localtime') GROUP BY day` — reuse this for calendar data. The only change needed is to call it from the new list screen's calendar provider instead of only from the analytics screen.

### Pattern 4 — Family multi-book query

```dart
// In TransactionDao — add bookIds parameter
if (bookIds != null && bookIds.isNotEmpty) {
  query.where((t) => t.bookId.isIn(bookIds));
} else {
  query.where((t) => t.bookId.equals(bookId));
}
```

Use `.watch()` (not `.get()`) on the query so new synced entries from family members appear in the list automatically without a manual refresh.

### Pattern 5 — Stream invalidation on swipe-delete

`softDelete` writes `is_deleted = true` + `updated_at = NOW()` to the `transactions` table. Because the list query uses `.watch()`, Drift's table invalidation mechanism fires automatically — no manual `ref.invalidate(...)` needed. The deleted row disappears from the stream in the next emission.

---

## Riverpod Provider Architecture

All new providers belong in `lib/features/list/presentation/providers/` (new feature directory). Use case classes belong in `lib/application/accounting/` (existing domain).

```
lib/features/list/
├── domain/
│   └── models/
│       └── transaction_list_filter.dart   # @freezed: ledgerType?, categoryId?, searchQuery, sortField, sortDirection, selectedDay?
├── presentation/
│   ├── providers/
│   │   ├── repository_providers.dart      # single source of truth: transactionRepositoryProvider ref
│   │   ├── state_list_filter.dart         # @riverpod Notifier<TransactionListFilter>
│   │   ├── state_calendar_totals.dart     # @riverpod family provider: calendarDailyTotals(bookId, year, month)
│   │   └── state_transaction_list.dart    # @riverpod StreamProvider: watches filter + calls DAO
│   ├── screens/
│   │   └── transaction_list_screen.dart
│   └── widgets/
│       ├── list_calendar_header.dart      # table_calendar wrapper
│       ├── transaction_list_row.dart      # Dismissible + row content
│       ├── list_filter_bar.dart           # search field + filter chips
│       └── list_sort_sheet.dart           # bottom sheet for sort options
```

The `state_transaction_list` provider composes: `selectedDayProvider` (from `state_list_filter`) → DAO date-range parameter. When `selectedDay` is set, start/end = that day 00:00–23:59. When null, start/end = the current focused month. Month switching from the calendar updates `focusedMonthProvider` and clears `selectedDay`.

Provider naming follows the Riverpod 3 convention: `class ListFilterNotifier` generates `listFilterProvider` (not `listFilterNotifierProvider`).

---

## What NOT to Add

| Avoid | Why Tempting | Why Wrong for v1.4 | Use Instead |
|---|---|---|---|
| `flutter_slidable` | Polished swipe-action rows with icon labels | One-action delete only; `Dismissible` is the right primitive; `flutter_slidable` adds 300+ lines of config for no UX gain vs. spec | `Dismissible` (Flutter built-in) |
| `infinite_scroll_pagination` | "Transaction lists get long" | Drift's `limit/offset` pattern is already in `findByBookId`; a typical month has <200 transactions; premature abstraction adds a non-trivial package to a list that fits in a `ListView.builder` | `ListView.builder` + Drift limit/offset |
| `flutter_staggered_animations` | Animate list entry/exit | ADR-012 no-gamification constraint applies broadly to celebratory UI motion; simple `AnimatedList` if any animation is needed, but spec doesn't require it | Plain `ListView.builder` |
| Any dedicated search package (`flutter_search_bar`, etc.) | "Native search bar widget" | `TextField` + `TextEditingController` + debounce timer is already the established pattern in `CategorySelectionScreen`; a search package adds API surface with no new capability at this scale | `TextField` + `Timer` debounce (existing pattern) |
| `sticky_headers` / `grouped_list` | Section headers by date | A `SliverList` + `SliverStickyHeader` approach is tempting for "date section dividers" but is not in the v1.4 spec; simple date-label rows in `ListView.builder` suffice | `ListView.builder` with inline date divider rows |
| `intl_utils` / `intl_translation` | "Calendar needs locale-aware day names" | `table_calendar` handles locale via `locale: Locale(...)` parameter; the app's `currentLocaleProvider` supplies this; no separate ARB pipeline needed for calendar | Existing `S.of(context)` + `DateFormatter` |
| `sqflite` (direct) | "Simpler SQL for the per-day rollup" | The project is fully committed to Drift + SQLCipher; accessing the DB via sqflite directly bypasses the encryption layer and violates the layer rules | Drift `customSelect` with `readsFrom:` |
| `rxdart` | "Combine filter stream + query stream" | Drift's `.watch()` already returns a `Stream`; Riverpod 3 handles stream combination via `ref.watch` on multiple providers; rxdart adds a dependency to replace primitives that already exist | Riverpod 3 `StreamProvider` |
| `riverpod: 3.x` upgrade | "Cleaner API" | Already on Riverpod 3.1.0 (`flutter_riverpod: ^3.1.0` in pubspec) — project is already on v3 | Existing `flutter_riverpod: ^3.1.0` |

---

## Version Compatibility (locked stack — do not touch)

| Package | v1.4 Constraint | Notes |
|---|---|---|
| `intl: 0.20.2` | Exact pin — do not touch | `table_calendar ^3.2.0` requires `^0.20.0`; pin satisfies this |
| `sqlcipher_flutter_libs: ^0.6.7` | Do not touch | CI guardrail rejects `sqlite3_flutter_libs`; no v1.4 schema change planned |
| `flutter_riverpod: ^3.1.0` + `riverpod_annotation: ^4.0.0` + `riverpod_generator: ^4.0.0+1` + `riverpod_lint: ^3.1.0` | Move together | Already on Riverpod 3; do not mix 2.x idioms (`AsyncValue.valueOrNull` is gone) |
| `file_picker: ^11.0.2` + `package_info_plus: ^9.0.1` + `share_plus: ^12.0.2` | Do not bump any of these alone | Tied via `win32 ^5.x` transitive constraint; `table_calendar` does not touch this graph |
| `drift: ^2.25.0` + `drift_dev: ^2.25.0` | Keep in sync | DAOs extended in-place; no migration needed for v1.4 unless a new index is added |
| `fl_chart: ^1.2.0` | Unchanged for v1.4 | fl_chart already upgraded to 1.x; not relevant to list tab |

---

## Sources

- `pubspec.yaml` / `pubspec.lock` (read 2026-05-29) — verified all locked dependencies and win32 version (5.15.0).
- `CLAUDE.md` (read 2026-05-29) — architecture constraints, Riverpod 3 conventions, Drift TableIndex syntax, iOS pin rules.
- `.planning/PROJECT.md` (read 2026-05-29) — v1.4 scope, carried constraints, shadow-books family pattern.
- `lib/data/daos/analytics_dao.dart` (read 2026-05-29) — confirmed `getDailyTotals` exists with `DATE(... 'unixepoch', 'localtime') GROUP BY day` pattern; reusable for calendar. HIGH confidence.
- `lib/data/daos/transaction_dao.dart` (read 2026-05-29) — confirmed `findByBookId` signature with ledgerType/categoryId/date range; existing index `idx_tx_book_timestamp` covers the month-range query. HIGH confidence.
- `lib/features/home/presentation/providers/state_shadow_books.dart` (read 2026-05-29) — confirmed family shadow-book + member-attribution pattern; v1.4 family list reuses this. HIGH confidence.
- `lib/features/home/presentation/screens/main_shell_screen.dart` (read 2026-05-29) — confirmed List tab is `Center(child: Text(S.of(context).listTab))` placeholder at index 1 of `IndexedStack`. HIGH confidence.
- Context7 `/aleksanderwozniak/table_calendar` docs — confirmed `CalendarBuilders` API, `onDaySelected` / `focusedDay` pattern, `selectedDayPredicate`. HIGH confidence.
- [pub.dev/packages/table_calendar](https://pub.dev/packages/table_calendar) — confirmed version 3.2.0; deps: `intl ^0.20.0`, `simple_gesture_detector ^0.2.0`; no win32; Dart SDK `>=3.0.0`. HIGH confidence.
- [pub.dev/packages/simple_gesture_detector](https://pub.dev/packages/simple_gesture_detector) — confirmed version 0.2.1; only dep is `flutter`; no native code. HIGH confidence.
- Context7 `/websites/drift_simonbinder_eu` docs — confirmed `OrderingTerm`, `customSelect`/`readsFrom`, `watch()` stream patterns. HIGH confidence.

---

*Stack research for: v1.4 列表功能 (Transaction List tab) — Flutter / Dart / Riverpod 3 / Drift+SQLCipher / table_calendar*
*Researched: 2026-05-29*
