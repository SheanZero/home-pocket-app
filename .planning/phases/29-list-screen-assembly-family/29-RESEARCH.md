# Phase 29: List Screen Assembly + Family — Research

**Researched:** 2026-05-30
**Domain:** Flutter / Riverpod 3 / Drift — family-aware list assembly, pull-to-refresh, multi-book merge, member attribution
**Confidence:** HIGH (all claims verified against live codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01 (FAM-02):** Member attribution = trailing chip (emoji + short name). Same container style as ledger tag but `AppColors.sharedLight`/`shared` colours. Own rows bare — driven by `memberTag == null` data, no UI `isOwn` branch.
- **D-02 (FAM-03/FAM-04):** Per-member chips + Mine-only chip share one single-row scrollable family segment in the bar. Single-select mutex: `setMemberFilter(shadowBookId | ownBookId | null)`. Member filter AND-composes with ledger + category. Mine-only = `setMemberFilter(ownBookId)`.
- **D-03 (FAM-01/FAM-03):** Default group-mode view = All members combined (`memberBookId = null`).
- **D-04 (FAM-01..04):** Solo mode = Phase 28 unchanged. Entire family cluster gated behind `isGroupMode == true`.
- **D-05 (LIST-04):** Pull-to-refresh = local DB reload only. `ref.invalidate` list provider + calendar totals provider. No P2P sync trigger.
- **D-06 (FAM-01/CAL-02):** Calendar per-day totals + month total always reflect full family combined, isolated from member filter. `calendarDailyTotalsProvider` MUST NOT watch `memberBookId`/search/ledger (Pitfall 3).

### Claude's Discretion

- Member chip colour: `AppColors.shared*` (resolved in UI-SPEC CC-1).
- Member chip order in bar: family segment at END (after search, before Clear) (resolved in UI-SPEC CC-2).
- Long name truncation: ellipsis at `maxWidth ≈ 72px`, full `memberDisplayName`, emoji preserves always (resolved in UI-SPEC CC-1).
- Member filter layer (SQL `bookIds` narrowing vs Dart `where`): planner decides (D-02 note, tradeoffs documented below).
- `RefreshIndicator` host widget structure: `_buildList` wrap with `AlwaysScrollableScrollPhysics` (resolved in UI-SPEC CC-3).
- Mine-only prominence: filled/backgroundMuted even when unselected + `Icons.person_outline` leading (resolved in UI-SPEC CC-2).
- ARB key / three-language copy: placeholders this phase, Phase 30 collects final copy.
- Widget/provider test construction: `ProviderContainer.test()` + `waitForFirstValue<T>` + Mocktail.

### Deferred Ideas (OUT OF SCOPE)

- Multi-select member filter.
- ARB three-language copy + member chip / Mine-only / empty-state wording + golden baselines → Phase 30 (LIST-03).
- Pull-to-refresh triggering real P2P sync round.
- Family privacy hardening (FAMILY-V2-01/02/03).
- Per-day per-member calendar colour breakdown.
- Pagination / infinite scroll → v1.5.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIST-04 | User can pull-to-refresh the list | `RefreshIndicator` precedent confirmed in `analytics_screen.dart:80`; wrap `_buildList`'s `ListView.builder` + `AlwaysScrollableScrollPhysics` |
| FAM-01 | When a family is joined, list includes family members' transactions merged with own | `findByBookIds` supports multi-book single SQL; `shadowBooksProvider` + `isGroupModeProvider` exist; seam at `state_list_transactions.dart:45` |
| FAM-02 | Each row attributes its owner (member name / emoji) when in family mode | `TaggedTransaction.memberTag` built, always null now (seam at line 105); `MemberTag{emoji, name}` ready; tile has no member chip yet |
| FAM-03 | User can filter list by family member | `setMemberFilter(String? bookId)` at `state_list_filter.dart:72`; `memberBookId: String?` in `ListFilterState`; member filter not yet in `anyFilterActive` check |
| FAM-04 | User can quickly switch to "Mine only" view in family mode | Same `setMemberFilter(ownBookId)` path; Mine-only chip not yet rendered in bar |

</phase_requirements>

---

## Summary

Phase 29 is a **seam-completion phase**, not a greenfield build. All architectural scaffolding — `TaggedTransaction`/`MemberTag` types, `ListFilterState.memberBookId`, `setMemberFilter`, `findByBookIds` multi-book SQL, `shadowBooksProvider`, `isGroupModeProvider` — was delivered by Phases 24–28. The task is to wire these together and render the family-aware UI.

**Seam verification (all confirmed live):**

| Seam | Location | Actual content | Match? |
|------|----------|---------------|--------|
| `bookIds = [bookId]` | `state_list_transactions.dart:45` | `final bookIds = [bookId]; // Step 3: own-book only (Phase 29: merge shadow books...)` | YES |
| `memberTag: null` | `state_list_transactions.dart:103–106` | `.map((tx) => TaggedTransaction(transaction: tx, memberTag: null))` with `// Phase 29: fill memberTag` comment | YES |
| Calendar seam | `state_calendar_totals.dart:22/30` | `// Phase 29 seam: bookId is a single value (own-book only)` + `// Phase 29: combine shadow books` | YES |
| `setMemberFilter` | `state_list_filter.dart:72` | `void setMemberFilter(String? bookId) { state = state.copyWith(memberBookId: bookId); }` | YES |
| `memberBookId: String?` | `list_filter_state.dart:31` | `String? memberBookId,` (Freezed field) | YES |
| `shadowBooksProvider` | `state_shadow_books.dart` | `Future<List<ShadowBookInfo>> shadowBooks(Ref ref)` | YES |
| `ShadowBookInfo` shape | `state_shadow_books.dart:12–22` | `Book book; String memberDisplayName; String memberAvatarEmoji` | YES |
| `isGroupModeProvider` | `state_active_group.dart:22` | `@Riverpod(keepAlive: true) bool isGroupMode(Ref ref) { ... }` | YES |

**Primary recommendation:** Implement Phase 29 as a series of small, targeted edits to existing files rather than creating new ones. The only new files needed are ARB placeholder keys and the family segment widget logic inside the existing bar + tile files.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Multi-book SQL merge | Data (DAO) | — | `findByBookIds` already handles `WHERE book_id IN (...)` + ORDER BY |
| bookIds expansion (own + shadow) | Presentation Provider | — | `listTransactionsProvider` watches `shadowBooksProvider` + `isGroupModeProvider` |
| `memberTag` fill (bookId → ShadowBookInfo lookup) | Presentation Provider | — | Provider builds lookup map before mapping `TaggedTransaction` |
| Member filter narrowing (SQL vs Dart) | Presentation Provider | Data (DAO) | Tradeoff detailed below; SQL narrowing preferred |
| Family calendar per-day totals | Presentation Provider + Data | — | Per-book `getDailyTotals` calls, summed Dart-side (no multi-book DAO method exists) |
| Member attribution chip rendering | Presentation (Widget) | — | `ListTransactionTile` trailing — second visual element after ledger tag |
| Member filter chips + Mine-only chip | Presentation (Widget) | — | `ListSortFilterBar` family segment |
| Pull-to-refresh trigger | Presentation (Widget + Screen) | — | `RefreshIndicator.onRefresh` in `list_screen.dart` `_buildList` |
| Group-mode gating | Presentation (Widget + Provider) | — | `isGroupModeProvider` gates both provider and widget rendering |

---

## Standard Stack

No new packages needed. Phase 29 is pure widget/provider wiring using the already-installed stack.

### Core (all already installed)

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| `flutter_riverpod` | ^3.x | State management | `isGroupModeProvider`, `shadowBooksProvider`, `listFilterProvider` |
| `riverpod_annotation` | ^4.x | `@riverpod` code gen | `@Riverpod(keepAlive:true)` for existing providers |
| `freezed_annotation` | ^3.x | Immutable models | `TaggedTransaction`, `ListFilterState` already generated |
| `flutter` Material | SDK | `RefreshIndicator`, `ActionChip` | Used per UI-SPEC CC-2/CC-3 |

### No Package Legitimacy Audit Required

This phase installs zero new packages. The `## Package Legitimacy Audit` section is omitted.

---

## Architecture Patterns

### System Architecture Diagram

```
listFilterProvider (keepAlive:true)
    memberBookId: String?    ← setMemberFilter(id|null)
         │
         │ watch
         ▼
isGroupModeProvider ──────────────────────────────────┐
(keepAlive:true, existing)                            │
         │                                            │
         │ if true                                    │
         ▼                                            │
shadowBooksProvider                                   │ gates
  List<ShadowBookInfo>                                │ family
  { book.id, memberDisplayName, memberAvatarEmoji }   │ UI
         │                                            │
         │ expand bookIds                             │
         ▼                                            │
listTransactionsProvider(bookId) ◄────────────────────┘
  1. bookIds = [bookId, ...shadowBookIds]       (FAM-01)
  2. findByBookIds(bookIds, ...)               SQL merge
  3. Dart: member filter narrowing (if memberBookId != null)
  4. Dart: fill TaggedTransaction.memberTag   (FAM-02)
  ↓
  List<TaggedTransaction>
         │
         │ render
         ▼
ListTransactionTile
  ├── ledger tag (existing)
  ├── member chip if memberTag != null  (FAM-02 NEW)
  └── amount

calendarDailyTotalsProvider(bookId, year, month)
  ← DOES NOT watch memberBookId/ledger/search (Pitfall 3)
  ← group mode: per-book getDailyTotals × N books, sum Dart-side (FAM-01 / D-06)
  └── Map<DateTime, int>
           │
           ▼
  CalendarHeaderWidget (unchanged API, new multi-book data)

ListSortFilterBar
  └── if isGroupMode:
       [Mine only] [member₁] [member₂] ... (FAM-03/FAM-04 NEW segment)
       → setMemberFilter(ownBookId | shadowBookId | null)

ListScreen._buildList
  └── RefreshIndicator (LIST-04 NEW)
       └── ListView.builder (physics: AlwaysScrollableScrollPhysics)
```

### Recommended Project Structure (changes only)

```
lib/features/list/presentation/
├── providers/
│   ├── state_list_transactions.dart   ◐ EDIT — seams at lines 44–45, 103–105
│   └── state_calendar_totals.dart     ◐ EDIT — seam at lines 22–30
├── screens/
│   └── list_screen.dart               ◐ EDIT — RefreshIndicator, anyFilterActive+memberBookId, group gating
└── widgets/
    ├── list_transaction_tile.dart     ◐ EDIT — member chip (second trailing element)
    └── list_sort_filter_bar.dart      ◐ EDIT — family segment (Mine-only + member chips)

lib/l10n/
├── app_en.arb   ◐ new placeholder keys: listMineOnly (+ possibly listAllMembers)
├── app_ja.arb   ◐ same keys
└── app_zh.arb   ◐ same keys
```

Zero new Dart files required (no new providers, no new models, no new screens).

---

## Critical Implementation Details

### Detail 1: `state_list_transactions.dart` — Seam Expansion

**Current code (lines 44–45):**
```dart
// Step 3: own-book only (Phase 29: merge shadow books → bookIds + memberTag)
final bookIds = [bookId];
```

**What to replace with:**
```dart
// Step 3: own-book + shadow books in group mode (FAM-01)
final isGroup = ref.watch(isGroupModeProvider);
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future))
    : const <ShadowBookInfo>[];

final bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];
// Build lookup table once: bookId → ShadowBookInfo (for memberTag fill)
final bookIdToShadow = {for (final s in shadowBookList) s.book.id: s};
```

**Current code (lines 103–106):**
```dart
// Step 7: wrap as TaggedTransaction
// Phase 29: fill memberTag from shadowBooks lookup
return txs
    .map((tx) => TaggedTransaction(transaction: tx, memberTag: null))
    .toList();
```

**What to replace with:**
```dart
// Step 7: wrap as TaggedTransaction; own-book rows get null memberTag (D-01)
return txs.map((tx) {
  final shadow = bookIdToShadow[tx.transaction.bookId];
  return TaggedTransaction(
    transaction: tx,
    memberTag: shadow == null
        ? null
        : MemberTag(emoji: shadow.memberAvatarEmoji, name: shadow.memberDisplayName),
  );
}).toList();
```

**Member filter narrowing (D-02 discretion — SQL bookIds narrowing recommended):**

Insert after the shadow-book expansion, before the use-case call:

```dart
// Member filter narrowing: SQL-level (D-02 preference — keeps result set small)
// If memberBookId is set, reduce bookIds to a single-element list.
// This means own-book rows are correctly bare (memberTag=null) when
// ownBookId is selected — shadowBookList is empty for own book, so
// bookIdToShadow[ownBookId] == null → memberTag = null. Correct.
final memberBookId = filter.memberBookId;
final effectiveBookIds = memberBookId != null
    ? (bookIds.contains(memberBookId) ? [memberBookId] : <String>[])
    : bookIds;
```

Pass `effectiveBookIds` to `GetListParams`. Remove the existing Dart-side `memberBookId` filter block (lines 411–413 in the architecture draft; in the live file the filter is not yet present — it simply does not exist, so just skip adding it in favour of SQL narrowing).

**Tradeoff note (for planner's task description):**
- SQL narrowing: `findByBookIds([memberBookId], ...)` — fewer rows from DB, O(N) Dart wrap, own-row memberTag stays null because bookIdToShadow won't contain ownBookId. CORRECT by data.
- Dart `where(tx.bookId == memberBookId)`: fetches all books' rows, filters in memory. More data transfer but simpler to reason about. Own-row attribution also correct (memberTag is set per bookId before the where).
- **SQL narrowing is preferred** (fewer bytes from SQLite, consistent with existing filter approach). Confirmed safe for own-book attribution correctness.

### Detail 2: `state_calendar_totals.dart` — Multi-book Sum

**Current provider** (single book, seam at line 30):
```dart
// Phase 29: combine shadow books for family per-day totals
final repo = ref.watch(analyticsRepositoryProvider);
final range = DateBoundaries.monthRange(year, month);
final totals = await repo.getDailyTotals(bookId: bookId, ...);
return {for (final t in totals) _dayKey(t.date): t.totalAmount};
```

**Confirmed facts:**
- `AnalyticsRepository.getDailyTotals` is **single-book only** (`required String bookId`). [VERIFIED: live `analytics_repository.dart:26`]
- There is **no** `getDailyTotalsAcrossBooks` or multi-book variant in `AnalyticsRepository` or `AnalyticsDao`. [VERIFIED: grepped `analytics_dao.dart`, `analytics_repository_impl.dart`]
- The multi-book pattern for analytics queries is `getSharedJoyCategoryInsight(bookIds: List<String>)` — confirms the codebase already has `bookIds IN (...)` analytics patterns, but NOT for `getDailyTotals`. [VERIFIED: `analytics_repository.dart:75`]

**Therefore:** Phase 29 must implement per-book `getDailyTotals` × N books, then merge the `Map<DateTime, int>` day-maps with integer addition. This is the correct approach (D-06 note: "per-book sum, row count small").

**What to expand to:**
```dart
final isGroup = ref.watch(isGroupModeProvider);
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future))
    : const <ShadowBookInfo>[];

final allBookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];
// CRITICAL: only watch (bookIds, year, month) — NEVER watch memberBookId/ledger/search
// Pitfall 3 / D-06: calendar is always full-family combined

final repo = ref.watch(analyticsRepositoryProvider);
final range = DateBoundaries.monthRange(year, month);

// Per-book calls (N = 1 in solo, 2–5 in family; row count per book ≤ 31)
final merged = <DateTime, int>{};
for (final bid in allBookIds) {
  final totals = await repo.getDailyTotals(bookId: bid, startDate: range.start, endDate: range.end);
  for (final t in totals) {
    final k = _dayKey(t.date);
    merged[k] = (merged[k] ?? 0) + t.totalAmount;
  }
}
return merged;
```

**Pitfall 3 compliance:** The provider signature must NOT add `memberBookId` as a parameter. The `calendarDailyTotalsProvider` key is `(bookId, year, month)` — this remains unchanged. The shadow book list is watched internally but does NOT flow from `listFilterProvider`.

**One concern:** watching `shadowBooksProvider.future` inside `calendarDailyTotalsProvider` means any shadow-book list change (new member joins) will rebuild the calendar. This is acceptable — it is a structural change (new member), not a filter toggle. The constraint is "no filter state coupling", which is satisfied.

### Detail 3: `list_transaction_tile.dart` — Member Chip

The tile currently has this trailing layout:
```
[ledger tag] [8px] [Expanded info col] [8px] [amount]
```

**Target layout (D-01, UI-SPEC CC-1):**
```
[ledger tag] [8px] [Expanded info col] [8px] [member chip?] [8px] [amount]
```

The member chip renders only when `taggedTx.memberTag != null`. It reuses the exact same `Container` + `BoxDecoration` + `Text(AppTextStyles.micro)` pattern as the ledger tag, with `AppColors.sharedLight` bg + `AppColors.shared` text. No new widget needed — inline `if (memberTag != null)` block.

**Truncation:** `maxWidth: 72`, `maxLines: 1`, `overflow: TextOverflow.ellipsis` wrapping the member chip `Text`. Emoji is part of the string (`"${tag.emoji} ${tag.name}"`), so it renders first and clips from the name end.

**No tile parameter changes needed:** `taggedTx.memberTag` is already on `TaggedTransaction`. The tile already receives `taggedTx`. No new constructor parameters.

### Detail 4: `list_sort_filter_bar.dart` — Family Segment

The bar currently ends with: `[Category] [Search] [Clear?]`

**New structure (UI-SPEC CC-2):**
`[Sort] [Direction] [All] [生存] [魂] [Category] [Search] ‖ [Mine only?] [member₁?] [member₂?] ... ‖ [Clear?]`

The entire family segment (`if (isGroupMode)`) is appended after Search and before the existing Clear chip. The Clear chip already uses `anyFilterActive` — this needs `|| memberBookId != null` added (see Detail 5).

**`isGroupMode` watch in the bar:** `ListSortFilterBar` is a `ConsumerStatefulWidget` — add `ref.watch(isGroupModeProvider)`. The bar already watches `listFilterProvider`.

**Mine-only chip (FAM-04):**
- Always visible in group mode (D-04 / SC#5).
- `ActionChip` with `Icons.person_outline` leading (14px, `AppColors.textSecondary`).
- Unselected: `backgroundColor: AppColors.backgroundMuted`, label `AppColors.textPrimary`.
- Selected (`filter.memberBookId == ownBookId`): `backgroundColor: AppColors.backgroundMuted`, `side: AppColors.borderDefault`, label `AppColors.textPrimary` (neutral, not shared/terracotta).
- `onPressed: () => ref.read(listFilterProvider.notifier).setMemberFilter(filter.memberBookId == bookId ? null : bookId)`.
- `bookId` is already available as the bar's constructor parameter.

**Member chips (FAM-03):**
- One `ActionChip` per `shadowBooksProvider` entry.
- Label: `"${info.memberAvatarEmoji} ${info.memberDisplayName}"`.
- Unselected: `backgroundColor: AppColors.card`, `side: AppColors.borderDefault`, label `AppColors.textSecondary`.
- Selected (`filter.memberBookId == info.book.id`): `backgroundColor: AppColors.sharedLight`, `side: AppColors.sharedBorder`, label `AppColors.shared`.
- `onPressed: () => setMemberFilter(selected ? null : info.book.id)` (toggle: tap again deselects).
- `shadowBooksProvider` is async — bar must handle `AsyncValue`. Use `.when(data: ..., loading: () => const SizedBox.shrink(), error: ...)`. This is the same pattern as any other async provider in the bar's feature.

### Detail 5: `list_screen.dart` — `RefreshIndicator` + `anyFilterActive` + Group Gating

**`RefreshIndicator` host:**
The `_buildList` method returns a `Widget` from `txsAsync.when(...)`. Wrap this entire return value in a `RefreshIndicator`. The `ListView.builder` already needs `physics: const AlwaysScrollableScrollPhysics()` added. The `loading` and `error` branches need wrapping in a scrollable widget too (e.g. `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics, child: ...)`) so pull gesture fires when content is short.

**`onRefresh` implementation:**
```dart
Future<void> onRefresh() async {
  ref.invalidate(listTransactionsProvider(bookId: bookId));
  ref.invalidate(calendarDailyTotalsProvider(
    bookId: bookId,
    year: filter.selectedYear,
    month: filter.selectedMonth,
  ));
  // Wait for the list provider to re-settle so the spinner dismisses honestly
  await ref.read(listTransactionsProvider(bookId: bookId).future).catchError((_) => <TaggedTransaction>[]);
}
```

**`anyFilterActive` fix — `memberBookId` missing:**
Current `anyFilterActive` in `list_screen.dart` (line 91) and `list_sort_filter_bar.dart` (line 128):
```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty;
// MISSING: filter.memberBookId != null
```

Phase 29 must add `|| filter.memberBookId != null` so:
1. The Clear chip appears when a member filter is active (bar).
2. `ListEmptyState(isFilterActive: true)` shows the correct filtered-empty copy (screen).
3. `clearAll()` already resets `memberBookId` to null via `ListFilterState.initial()` — no change needed there.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Multi-book transaction merge | Custom Dart merge + sort | `findByBookIds(bookIds, ...)` | Already SQL-merged with tiebreaker `id DESC` |
| Shadow book enumeration | Custom DB query | `shadowBooksProvider` | Already returns `List<ShadowBookInfo>` with all needed fields |
| Group-mode detection | Boolean flag in ListFilter | `isGroupModeProvider` | `keepAlive: true`, reactive to DB change |
| Member single-select state | New `mineOnly: bool` field | `listFilterProvider.memberBookId: String?` | Mine-only = own bookId in same field; no parallel state |
| Calendar multi-book sum | New DAO method | Per-book loop + Dart map merge | `getDailyTotals` is single-book; loop is 2–5 calls × ≤31 rows |
| Pull-to-refresh | Custom gesture | `RefreshIndicator` (Material) | Standard Flutter widget with `AlwaysScrollableScrollPhysics` |

---

## Common Pitfalls

### Pitfall A: Calendar Provider Coupling (Pitfall 3 — CRITICAL)

**What goes wrong:** Adding `memberBookId` or any filter state to `calendarDailyTotalsProvider`'s watch or parameter list causes all 31 day cells to re-render on every filter change.

**How to avoid:** `calendarDailyTotalsProvider` watches only `(bookId, year, month)` plus the internally-watched `shadowBooksProvider` (structural, not filter). `memberBookId` is NEVER a parameter of this provider. D-06 is a hard constraint.

**Warning sign:** Any `ref.watch(listFilterProvider)` inside `state_calendar_totals.dart`.

### Pitfall B: Mine-only `anyFilterActive` Omission

**What goes wrong:** `filter.memberBookId != null` is absent from `anyFilterActive` in both `list_screen.dart` and `list_sort_filter_bar.dart`. This means: (a) Clear chip does not appear when Mine-only/member filter is active, (b) empty-state shows "no entries this month" instead of "no entries match filters" when member filter hides all rows.

**How to avoid:** Add `|| filter.memberBookId != null` to both `anyFilterActive` calculations in the same commit that adds the member filter.

**Verification:** Set `memberBookId = ownBookId`, ensure no transactions exist for that book; confirm `isFilterActive: true` is passed to `ListEmptyState`.

### Pitfall C: `shadowBooksProvider.future` Await in keepAlive Provider

**What goes wrong:** `listTransactionsProvider` is auto-dispose (default `@riverpod`). `shadowBooksProvider` is also auto-dispose. Using `await ref.watch(shadowBooksProvider.future)` is safe for the transaction provider (it is not keepAlive). But `calendarDailyTotalsProvider` is also auto-dispose — the same pattern applies. No keepAlive conflict.

**What IS a concern:** `isGroupModeProvider` is `keepAlive: true`. Watching it from an auto-dispose provider is fine — the auto-dispose provider will rebuild when the keepAlive provider changes. No issue.

**How to avoid:** Use `ref.watch(shadowBooksProvider.future)` (not `ref.read`) so the list provider rebuilds when shadow book list changes (e.g. new member joins). This is correct reactive behaviour.

### Pitfall D: Own-Book Attribution Correctness

**What goes wrong:** If `bookIdToShadow[tx.transaction.bookId]` accidentally returns a non-null value for an own-book transaction, own rows get a spurious member chip — violating D-01 / SC#3.

**Why this cannot happen:** `shadowBooksProvider` returns `List<ShadowBookInfo>` filtered to shadow books (i.e. `isShadow = true`). Own book is `isShadow = false`. `bookIdToShadow` is built from `shadowBookList` only — own `bookId` is never a key in this map. [VERIFIED: `shadow_book_service.dart` creates shadow books with `isShadow = true`; `shadowBooksProvider` queries `findShadowBooksByGroupId`.]

**Verification test:** Create a list with own-book transactions in group mode; assert every `taggedTx.memberTag == null`.

### Pitfall E: `RefreshIndicator` on Non-Scrollable Children

**What goes wrong:** When the list is empty or shows an error, the `loading`/`error` widget returned by `txsAsync.when(...)` is not scrollable. `RefreshIndicator` requires a scrollable child or the pull gesture does not fire.

**How to avoid:** Wrap the `loading` and `error` branches in `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child: ...)`. The `analytics_screen.dart` precedent uses `SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), ...)` for its entire body. [VERIFIED: `analytics_screen.dart:89–90`]

### Pitfall F: `onRefresh` Future Completion

**What goes wrong:** `RefreshIndicator.onRefresh` must return a `Future` that completes when the refresh is done. If it returns immediately after `ref.invalidate`, the spinner dismisses before data reloads — produces a flash. If it never completes (e.g. hangs on a failed provider), the spinner spins forever.

**How to avoid:** After invalidate, await the list provider's future with a catch:
```dart
await ref.read(listTransactionsProvider(bookId: bookId).future)
    .catchError((_) => <TaggedTransaction>[]);
```
This matches the pattern implied by `analytics_screen.dart`'s `_refresh()` helper.

### Pitfall G: Member Chip Overflows Tile Row

**What goes wrong:** A long `memberDisplayName` (e.g. 10-character name) with emoji makes the chip wide, compressing the `Expanded` info column to zero width or pushing the amount off-screen.

**How to avoid:** Constrain chip with `ConstrainedBox(constraints: BoxConstraints(maxWidth: 72), child: ...)` and `Text(..., maxLines: 1, overflow: TextOverflow.ellipsis)`. The `Expanded` column absorbs remaining space; the amount is fixed width at the rightmost end. Test with a 10-char name.

---

## Code Examples

### Multi-book bookIds expansion in provider

```dart
// Source: verified pattern from state_shadow_books.dart + state_list_transactions.dart seam
final isGroup = ref.watch(isGroupModeProvider);          // keepAlive, always fresh
final shadowBookList = isGroup
    ? (await ref.watch(shadowBooksProvider.future))      // auto-dispose, reactive
    : const <ShadowBookInfo>[];
final bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)];
final bookIdToShadow = {for (final s in shadowBookList) s.book.id: s};
```

### SQL member-filter narrowing

```dart
// Source: D-02 note — SQL bookIds narrowing preferred
final memberBookId = filter.memberBookId;
final effectiveBookIds = memberBookId != null
    ? (bookIds.contains(memberBookId) ? [memberBookId] : const <String>[])
    : bookIds;
// Pass effectiveBookIds to GetListParams.bookIds
```

### memberTag fill (replacing seam)

```dart
// Source: state_list_transactions.dart seam replacement
return txs.map((tx) {
  final shadow = bookIdToShadow[tx.transaction.bookId];
  return TaggedTransaction(
    transaction: tx,
    memberTag: shadow == null
        ? null
        : MemberTag(emoji: shadow.memberAvatarEmoji, name: shadow.memberDisplayName),
  );
}).toList();
```

### Calendar per-book sum (replacing seam)

```dart
// Source: per-D-06 pattern; getDailyTotals is single-book (verified analytics_repository.dart:26)
final merged = <DateTime, int>{};
for (final bid in allBookIds) {
  final totals = await repo.getDailyTotals(
    bookId: bid, startDate: range.start, endDate: range.end,
  );
  for (final t in totals) {
    final k = _dayKey(t.date);
    merged[k] = (merged[k] ?? 0) + t.totalAmount;
  }
}
return merged;
```

### Member chip in tile (CC-1)

```dart
// Source: UI-SPEC CC-1; reuses existing ledger-tag Container pattern (list_transaction_tile.dart:134–145)
if (taggedTx.memberTag case final tag?) ...[
  const SizedBox(width: 8),
  ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 72),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.sharedLight,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: Text(
        '${tag.emoji} ${tag.name}',
        style: AppTextStyles.micro.copyWith(color: AppColors.shared),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
],
```

### Mine-only chip (CC-2)

```dart
// Source: UI-SPEC CC-2; ActionChip matching existing bar chip construction
ActionChip(
  avatar: Icon(Icons.person_outline, size: 14,
      color: filter.memberBookId == bookId
          ? AppColors.textPrimary
          : AppColors.textSecondary),
  label: Text(S.of(context).listMineOnly,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.textPrimary,
      )),
  backgroundColor: AppColors.backgroundMuted,
  side: const BorderSide(color: AppColors.borderDefault, width: 1),
  onPressed: () => ref.read(listFilterProvider.notifier)
      .setMemberFilter(filter.memberBookId == bookId ? null : bookId),
  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
),
```

### RefreshIndicator host (CC-3)

```dart
// Source: analytics_screen.dart:80–90 pattern
RefreshIndicator(
  color: AppColors.accentPrimary,
  onRefresh: () async {
    ref.invalidate(listTransactionsProvider(bookId: bookId));
    ref.invalidate(calendarDailyTotalsProvider(
      bookId: bookId, year: filter.selectedYear, month: filter.selectedMonth));
    await ref.read(listTransactionsProvider(bookId: bookId).future)
        .catchError((_) => <TaggedTransaction>[]);
  },
  child: ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    ...
  ),
)
```

---

## State of the Art

| Old Approach (v1.4 research doc) | Current Codebase State | Impact for Phase 29 |
|----------------------------------|------------------------|---------------------|
| "per-shadow-book query + Dart merge" (FEATURES.md line 75) | `findByBookIds` single SQL multi-book already built (Phase 24) | Simpler: no Dart merge needed |
| `memberLabel: String?` field name (ARCHITECTURE.md draft) | `MemberTag { emoji, name }` Freezed VO (Phase 26 D-07) | Use `MemberTag`; not a plain string |
| Calendar `bookId` only | `calendarDailyTotalsProvider(bookId, year, month)` — single book | Phase 29 adds per-book loop internally; signature stays `(bookId, year, month)` |
| `anyFilterActive` = 4 conditions | `anyFilterActive` = 4 conditions (no `memberBookId`) | Phase 29 adds the 5th condition |
| `TaggedTransaction.memberLabel: String?` (ARCHITECTURE.md) | `TaggedTransaction.memberTag: MemberTag?` (live codebase) | Use `memberTag.emoji` + `memberTag.name` separately |

---

## Additional Integration Findings

### `calendarDailyTotalsProvider` Signature Must Stay Stable

The calendar provider is keyed by `(bookId, year, month)`. Other files reference it with exactly these parameters:

- `list_screen.dart:177`: `calendarDailyTotalsProvider(bookId: bookId, year: filter.selectedYear, month: filter.selectedMonth)`
- `list_calendar_header.dart:45`: `calendarDailyTotalsProvider(bookId: bookId, year: filter.selectedYear, month: filter.selectedMonth)`

Phase 29 must NOT add new named parameters to this provider's signature. The multi-book expansion must be internal (shadow books are watched from within the provider body, not passed as parameters).

### `currencyCode` Seam in `list_screen.dart:38–39`

```dart
// Phase 29: resolve currencyCode from bookByIdProvider
const currencyCode = 'JPY';
```

This is a Phase 29 seam. If book-level currency resolution is in scope, this is where it goes. Per CONTEXT.md deferred list, this is NOT in Phase 29 scope. Leave `const currencyCode = 'JPY'` unchanged.

### `clearAll()` and `memberBookId`

`ListFilterState.clearAll()` calls `ListFilterState.initial()` which sets `memberBookId = null` (because `initial()` uses the default `String? memberBookId` = null). No changes needed to `clearAll`. [VERIFIED: `list_filter_state.dart:44`]

### ARB Keys Required (Phase 29 placeholders)

New keys needed (placeholder English values acceptable):

| Key | Suggested English value | Notes |
|-----|------------------------|-------|
| `listMineOnly` | `"Mine only"` | Mine-only chip label (final ja `自分のみ` / zh `仅我的` in Phase 30) |

Possibly needed (if "All members" chip is added for discoverability):
| `listAllMembers` | `"All"` | Reuse `l10n.listLedgerAll` pattern if possible to avoid a new key |

All 3 ARB files (app_ja.arb, app_zh.arb, app_en.arb) must have the key in the same commit, then `flutter gen-l10n` must pass. [VERIFIED: ARB key parity enforced by `test/architecture/arb_key_parity_test.dart`]

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `shadowBooksProvider` only returns shadow books (not own book) because it queries `findShadowBooksByGroupId` which filters `isShadow = true` | Detail 1 / own-book attribution correctness | If own book appeared in shadow list, own rows would get spurious memberTag — visual bug in group mode |
| A2 | `getDailyTotals` per-book loop with 2–5 books × ≤31 rows is fast enough (<50ms) — no new multi-book DAO method needed | Detail 2 | If family has many books (>5) or very active months (>1000 rows/book), per-book loop could become slow; mitigation: add `getDailyTotalsAcrossBooks` DAO method later |
| A3 | `shadowBooksProvider` is auto-dispose but safe to `await ref.watch(...future)` inside `calendarDailyTotalsProvider` (also auto-dispose) | Detail 2 | If both providers are disposed simultaneously during a tab switch, could cause "disposed during loading" — mitigation: `keepAlive: true` on shadow books if needed |

---

## Open Questions (RESOLVED)

1. **`shadowBooksProvider` keepAlive in calendar context**
   - What we know: `shadowBooksProvider` is `@riverpod` (auto-dispose). `calendarDailyTotalsProvider` is also auto-dispose. Both are subscribed from a `keepAlive: true` `listFilterProvider` chain under IndexedStack.
   - What's unclear: Under IndexedStack, the List tab's widgets remain mounted — subscriptions never drop. So auto-dispose providers should stay alive. But the calendar provider is invalidated explicitly on pull-to-refresh; when it rebuilds, it re-awaits `shadowBooksProvider.future`. This should work.
   - RESOLVED: No action needed. If "disposed during loading" appears in tests, add `keepAlive: true` to `shadowBooksProvider`. This is a runtime-only concern, easily fixed.

2. **Mine-only chip ARB key or reuse `listLedgerAll`?**
   - What we know: `listLedgerAll` = `"All"` already exists. A new `listMineOnly` key is needed.
   - What's unclear: Whether a separate "All members" chip is needed (UI-SPEC CC-2 says "do not add a separate All members chip unless needed for discoverability").
   - RESOLVED: Skip "All members" chip in Phase 29. The `null` state is implicit (no chip selected in the member segment). Add `listMineOnly` key only.

---

## Environment Availability

This phase is purely code/config changes (Dart edits + ARB text file edits). No external tool dependencies. Environment availability audit not applicable.

---

## Validation Architecture

`workflow.nyquist_validation = true` in `.planning/config.json`. This section is required.

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Flutter Test (built-in) + Mocktail |
| Config file | none (flutter test runs automatically) |
| Quick run command | `flutter test test/unit/features/list/ test/widget/features/list/ --no-pub` |
| Full suite command | `flutter test --no-pub` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIST-04 | `RefreshIndicator.onRefresh` invalidates list + calendar providers; spinner completes | Widget | `flutter test test/widget/features/list/list_screen_refresh_test.dart` | ❌ Wave 0 |
| FAM-01 | Group mode: `listTransactionsProvider` includes own + shadow book rows; solo mode: own-only | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends existing) |
| FAM-01 | Calendar daily totals = sum over all books when in group mode | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/calendar_totals_provider_test.dart` | ✅ (extends existing) |
| FAM-02 | Shadow-book rows get `memberTag != null`; own-book rows get `memberTag == null` | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends existing) |
| FAM-02 | Member chip renders on tile when `memberTag != null`; absent when null | Widget | `flutter test test/widget/features/list/list_transaction_tile_test.dart` | ✅ (extends existing) |
| FAM-03 | `setMemberFilter(shadowBookId)` narrows list to that book's rows; composable with ledger/category | Unit (provider) | `flutter test test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` | ✅ (extends existing) |
| FAM-03 | Member filter active → `anyFilterActive = true` → Clear chip visible + filtered-empty shown | Widget | `flutter test test/widget/features/list/list_sort_filter_bar_member_test.dart` | ❌ Wave 0 |
| FAM-04 | `setMemberFilter(ownBookId)` shows only own-book rows; re-tap clears to All | Unit (provider) | same as FAM-03 provider test | ✅ (extends existing) |
| FAM-04 | Mine-only chip always visible in group mode regardless of other filters | Widget | `flutter test test/widget/features/list/list_sort_filter_bar_member_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/unit/features/list/ test/widget/features/list/ --no-pub`
- **Per wave merge:** `flutter test --no-pub`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/widget/features/list/list_screen_refresh_test.dart` — covers LIST-04 (RefreshIndicator fires invalidate, spinner completes)
- [ ] `test/widget/features/list/list_sort_filter_bar_member_test.dart` — covers FAM-03 (member chips render per shadowBooksProvider, Mine-only always visible in group mode, anyFilterActive includes memberBookId, Clear chip visible on member filter)
- New test cases to ADD to existing files:
  - `list_transactions_provider_test.dart`: group mode returns merged rows, shadow rows get memberTag, own rows get null memberTag, SQL member-filter narrowing, Mine-only = own-book only
  - `calendar_totals_provider_test.dart`: group mode sums per-book day totals, calendar ignores memberBookId
  - `list_transaction_tile_test.dart`: member chip renders + truncates, absent on own rows

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | — |
| V3 Session Management | no | — |
| V4 Access Control | yes (indirect) | Shadow book data only available after group membership verified by `isGroupModeProvider`; no cross-group data leakage |
| V5 Input Validation | no | No user-typed data paths in this phase (filter taps, not text input) |
| V6 Cryptography | no | No new crypto operations; shadow-book note decrypt behavior inherited from Phase 26 |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Shadow note leakage via search | Information Disclosure | Inherited from Phase 26 D-06: `note ?? ''` on shadow rows; encrypted note not searchable |
| Own-book attribution bypass | Tampering | `bookIdToShadow` built from `shadowBooksProvider` which only contains shadow books; own bookId can never appear |
| Logging family transaction data | Information Disclosure | CLAUDE.md §Security: NEVER log sensitive data; `merchant`/`note` only used for `.contains()` in memory |

---

## Project Constraints (from CLAUDE.md)

- `AppColors.*` tokens — no hardcoded hex. [VERIFIED: `app_colors.dart` has `shared`/`sharedLight`/`sharedBorder`]
- `AppTextStyles.amountSmall` for amounts — tabular figures. [VERIFIED: already used by tile]
- `S.of(context)` — all new strings via ARB. New `listMineOnly` key needed.
- `ONE repository_providers.dart` per feature — do not add a second one. [VERIFIED: `test/architecture/provider_graph_hygiene_test.dart` enforces this]
- `buildRunner` after any Freezed/Riverpod annotation changes — not needed for Phase 29 (no model changes; only provider body edits and widget edits).
- `flutter analyze` must be 0 issues before commit.
- `import_guard` — `lib/features/list/` remains Thin Feature (no application/ or data/daos/ imports added).
- `ProviderContainer.test()` + `waitForFirstValue<T>` in all provider tests. [VERIFIED: existing `list_transactions_provider_test.dart` already uses this pattern]
- `Riverpod 3: AsyncValue.value` nullable (not `.valueOrNull`). [VERIFIED: `list_screen.dart:37` already uses `.value`]

---

## Sources

### Primary (HIGH confidence)

- Live `lib/features/list/presentation/providers/state_list_transactions.dart` — seam at lines 44–45, 103–106 confirmed
- Live `lib/features/list/presentation/providers/state_calendar_totals.dart` — seam at lines 22–30 confirmed
- Live `lib/features/list/presentation/providers/state_list_filter.dart` — `setMemberFilter` at line 72 confirmed
- Live `lib/features/list/domain/models/list_filter_state.dart` — `memberBookId: String?` confirmed
- Live `lib/features/list/domain/models/tagged_transaction.dart` — `MemberTag{emoji, name}` + `TaggedTransaction{memberTag}` confirmed
- Live `lib/features/home/presentation/providers/state_shadow_books.dart` — `ShadowBookInfo{book, memberDisplayName, memberAvatarEmoji}` confirmed
- Live `lib/features/family_sync/presentation/providers/state_active_group.dart` — `isGroupModeProvider` at line 22 confirmed
- Live `lib/data/daos/transaction_dao.dart` — `findByBookIds` at lines 236–273 confirmed; ORDER BY = `_orderByClause + id DESC`
- Live `lib/features/analytics/domain/repositories/analytics_repository.dart` — `getDailyTotals(bookId: String)` single-book confirmed; no multi-book variant
- Live `lib/data/daos/analytics_dao.dart` — `getDailyTotals` single-book SQL confirmed
- Live `lib/core/theme/app_colors.dart` — `AppColors.shared`/`sharedLight`/`sharedBorder` exist at lines 54–56
- Live `lib/features/analytics/presentation/screens/analytics_screen.dart` — `RefreshIndicator` + `AlwaysScrollableScrollPhysics` precedent at lines 80–90
- Live `lib/features/list/presentation/screens/list_screen.dart` — `_buildList` structure, `anyFilterActive` (4 conditions, missing `memberBookId`)
- Live `lib/features/list/presentation/widgets/list_transaction_tile.dart` — tile layout confirmed; no member chip
- Live `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` — bar layout confirmed; no family segment
- Live `lib/l10n/app_en.arb` — no `listMineOnly` or `listMember*` keys exist (confirmed by grep)
- Live `test/unit/features/list/presentation/providers/list_transactions_provider_test.dart` — existing test structure confirmed

### Secondary (MEDIUM confidence)

- `.planning/phases/29-list-screen-assembly-family/29-CONTEXT.md` — locked decisions verified against live codebase; all seam locations match
- `.planning/phases/29-list-screen-assembly-family/29-UI-SPEC.md` — approved design contract; all token names (`AppColors.shared*`, `AppTextStyles.micro`, etc.) verified in live codebase
- `.planning/research/ARCHITECTURE.md` — shadow book sourcing pattern verified live

---

## Metadata

**Confidence breakdown:**
- Seam locations: HIGH — all verified by direct file read against live codebase
- `findByBookIds` signature + ORDER BY: HIGH — verified `transaction_dao.dart:236–273`
- `getDailyTotals` single-book constraint: HIGH — verified `analytics_repository.dart:26`, `analytics_dao.dart:226`
- No multi-book `getDailyTotals` DAO path: HIGH — grepped both files, no match
- `shadowBooksProvider` shape: HIGH — verified `state_shadow_books.dart:12–22`
- `isGroupModeProvider` at line 22: HIGH — verified `state_active_group.dart:22`
- `setMemberFilter` at line 72: HIGH — verified `state_list_filter.dart:72`
- `AppColors.shared*` tokens: HIGH — verified `app_colors.dart:54–56`
- `RefreshIndicator` + `AlwaysScrollableScrollPhysics` precedent: HIGH — verified `analytics_screen.dart:80–90`
- `anyFilterActive` missing `memberBookId`: HIGH — verified in both `list_screen.dart:91` and `list_sort_filter_bar.dart:128`

**Research date:** 2026-05-30
**Valid until:** 2026-06-30 (stable — all findings are from live codebase, not external packages)
