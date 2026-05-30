---
phase: 29-list-screen-assembly-family
verified: 2026-05-31T09:00:00Z
status: passed
score: 14/14
overrides_applied: 0
human_verification_resolved: "All human items approved at the Plan 04 Task 2 blocking human-verify checkpoint (2026-05-30); recorded in 29-HUMAN-UAT.md (status: resolved, 4/4 passed)."
human_verification:
  - test: "Visual pull-to-refresh — solo mode and family mode"
    expected: "Spinner appears on pull gesture, list reloads. In family mode: member attribution chips visible on shadow-book rows, Mine-only chip visible, member chips appear per family member, AND-composition of ledger + member filter works, Clear-all clears member filter."
    why_human: "Visual gesture behavior, chip rendering, AND-composition, filtered-empty state cannot be verified programmatically from grep/tests alone. Human checkpoint was APPROVED during execution (Plan 04 Task 2) but verifier must surface it for the escalation gate record."
---

# Phase 29: List Screen Assembly + Family — Verification Report

**Phase Goal:** The complete list screen is assembled — all components integrated, pull-to-refresh works, reactive sync updates propagate automatically, and when a family is joined the list merges members' entries with per-row attribution and a "Mine only" shortcut.
**Verified:** 2026-05-31T09:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | User can pull down on the list and it reloads — RefreshIndicator wraps scrollable content (LIST-04) | VERIFIED | `list_screen.dart:64` — `RefreshIndicator(color: AppColors.accentPrimary, onRefresh: ..., child: txsAsync.when(...))`. Widget test `list_screen_refresh_test.dart` confirms `byType(RefreshIndicator)` found and use-case called twice after drag gesture. |
| 2 | onRefresh invalidates both listTransactionsProvider and calendarDailyTotalsProvider; spinner completes after provider re-settles (D-05 / Pitfall F) | VERIFIED | `list_screen.dart:67–76` — both providers invalidated, then `ref.read(listTransactionsProvider.future).catchError(...)` awaited. Test `pull-to-refresh invalidates calendarDailyTotalsProvider` passes. (Note: only list future awaited, not calendar — WR-04 warning, not blocking.) |
| 3 | Loading/error/empty branches wrapped in SingleChildScrollView(AlwaysScrollableScrollPhysics) so pull gesture fires when list is empty (Pitfall E) | VERIFIED | `list_screen.dart:79–122` — loading branch line 79, error branch line 88, empty-data branch line 119 all wrapped. ListView.builder line 127 also has `AlwaysScrollableScrollPhysics`. |
| 4 | anyFilterActive in list_screen.dart includes filter.memberBookId != null (Pitfall B fix) | VERIFIED | `list_screen.dart:111–115` — 5-condition form verified by grep. Matches bar form exactly (IN-03 notes the duplication; not a blocker). |
| 5 | In group mode, listTransactionsProvider bookIds includes own + all shadow book IDs (FAM-01) | VERIFIED | `state_list_transactions.dart:47–52` — `isGroupModeProvider` watched, `shadowBooksProvider.future` awaited in group mode, `bookIds = [bookId, ...shadowBookList.map((s) => s.book.id)]`. Unit tests for FAM-01 pass. |
| 6 | Shadow-book transaction rows have memberTag non-null with emoji + name from ShadowBookInfo (FAM-02) | VERIFIED | `state_list_transactions.dart:123–134` — `bookIdToShadow[tx.bookId]` lookup; non-null shadow → `MemberTag(emoji: ..., name: ...)`. Unit test "FAM-02: shadow rows get memberTag non-null" passes. |
| 7 | Own-book transaction rows always have memberTag == null (D-01 / SC#3) | VERIFIED | Same lookup at line 123 — own bookId not in `bookIdToShadow` (own key never inserted) → `memberTag: null`. Unit test "own rows get memberTag null" passes. |
| 8 | setMemberFilter(shadowBookId) narrows effective bookIds to a single-element list at SQL level (D-02 / FAM-03) | VERIFIED | `state_list_transactions.dart:63–65` — `effectiveBookIds = (memberBookId != null && bookIds.contains(memberBookId)) ? [memberBookId] : bookIds`. Unit test "FAM-03: member filter narrows to shadow book" passes. |
| 9 | Stale/absent memberBookId (CR-01 fix) falls back to full book set, never empty list | VERIFIED | `state_list_transactions.dart:63–65` — same expression: if memberBookId not in bookIds, falls back to full `bookIds`. CR-01 regression test (commit 25403a3c) passes. |
| 10 | setMemberFilter(ownBookId) shows only own rows — Mine-only works (FAM-04) | VERIFIED | `state_list_transactions.dart:63–65` — ownBookId is in `bookIds`, so `effectiveBookIds = [ownBookId]` (solo). Unit test "FAM-04: Mine-only = own bookId narrowing" passes. |
| 11 | calendarDailyTotalsProvider sums per-book getDailyTotals across own + shadow books in group mode and signature stays (bookId, year, month) — never watches listFilterProvider (D-06 / Pitfall 3) | VERIFIED | `state_calendar_totals.dart:34–58` — loops `allBookIds`, sums into `merged`. Only listFilterProvider references are in comments (lines 20, 32). Call signatures in `list_screen.dart` and `list_calendar_header.dart` confirmed `(bookId, year, month)` only. Unit tests "group mode sums" and "calendar isolated from memberBookId filter" pass. |
| 12 | Member attribution chip renders as second trailing element on tiles whose memberTag is non-null; uses AppColors.sharedLight/shared, maxWidth 72, AppTextStyles.micro (FAM-02 / CC-1) | VERIFIED | `list_transaction_tile.dart:196–216` — `if (taggedTx.memberTag case final tag?)` pattern-match; `ConstrainedBox(maxWidth: 72)` + `Container(color: AppColors.sharedLight)` + `AppTextStyles.micro.copyWith(color: AppColors.shared)` + `TextOverflow.ellipsis`. Widget tests for all 3 chip assertions pass. |
| 13 | Family filter segment (Mine-only chip + per-member chips) appears in the bar ONLY when isGroupMode == true (D-04 / FAM-03/FAM-04) | VERIFIED | `list_sort_filter_bar.dart:427–491` — entire family block wrapped in `if (isGroupMode)`. Widget tests "Mine-only visible in group mode" and "absent in solo mode" both pass. |
| 14 | listMineOnly ARB key present in all 3 locale files; arb_key_parity_test passes | VERIFIED | `app_en.arb:2152`, `app_ja.arb:2152`, `app_zh.arb:2152` all contain `"listMineOnly": "Mine only"`. `arb_key_parity_test` passes (confirmed by test run). |

**Score:** 14/14 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `test/widget/features/list/list_screen_refresh_test.dart` | Wave 0 test scaffold for LIST-04 | VERIFIED | Exists, 3 tests all pass, targets RefreshIndicator + dual-provider invalidation |
| `test/widget/features/list/list_sort_filter_bar_member_test.dart` | Wave 0 test scaffold for FAM-03/FAM-04 | VERIFIED | Exists, 7 tests covering Mine-only + member chip visibility, setMemberFilter calls, anyFilterActive |
| `test/unit/.../list_transactions_provider_test.dart` | Provider unit tests with Phase 29 group | VERIFIED | 15 total tests including 7 Phase 29 group tests all passing |
| `test/unit/.../calendar_totals_provider_test.dart` | Calendar totals tests with Phase 29 group | VERIFIED | Phase 29 group (3 tests) + existing — all pass |
| `test/widget/features/list/list_transaction_tile_test.dart` | Tile tests with Phase 29 member chip group | VERIFIED | Phase 29 group (3 tests) all pass |
| `lib/features/list/presentation/providers/state_list_transactions.dart` | Family-aware transaction list provider | VERIFIED | Group-mode fan-out, memberTag fill, member filter narrowing, CR-01 fallback |
| `lib/features/list/presentation/providers/state_calendar_totals.dart` | Family-aware calendar totals provider | VERIFIED | Per-book getDailyTotals loop, signature unchanged, no listFilterProvider reference |
| `lib/features/list/presentation/screens/list_screen.dart` | RefreshIndicator-wrapped list + anyFilterActive fix | VERIFIED | RefreshIndicator present, 4 AlwaysScrollableScrollPhysics sites, 5-condition anyFilterActive |
| `lib/features/list/presentation/widgets/list_transaction_tile.dart` | Member attribution chip as second trailing element | VERIFIED | ConstrainedBox(maxWidth:72) + sharedLight + micro text + ellipsis |
| `lib/features/list/presentation/widgets/list_sort_filter_bar.dart` | Family filter segment + anyFilterActive fix | VERIFIED | isGroupMode guard, Mine-only + member chips, 5-condition anyFilterActive |
| `lib/l10n/app_en.arb` | listMineOnly key | VERIFIED | Line 2152 |
| `lib/l10n/app_ja.arb` | listMineOnly key | VERIFIED | Line 2152 |
| `lib/l10n/app_zh.arb` | listMineOnly key | VERIFIED | Line 2152 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `state_list_transactions.dart` | `state_shadow_books.dart` | `ref.watch(shadowBooksProvider.future)` in group mode | VERIFIED | Line 49: `await ref.watch(shadowBooksProvider.future)` |
| `state_calendar_totals.dart` | `analytics_repository.dart` | per-book `getDailyTotals` loop, NOT listFilterProvider | VERIFIED | Lines 47–57: loop over allBookIds calling `repo.getDailyTotals(bookId: bid, ...)` |
| `list_transaction_tile.dart` | `tagged_transaction.dart` | `taggedTx.memberTag case final tag?` pattern-match | VERIFIED | Line 196: `if (taggedTx.memberTag case final tag?) [...]` |
| `list_sort_filter_bar.dart` | `state_list_filter.dart` | `ref.read(listFilterProvider.notifier).setMemberFilter()` | VERIFIED | Lines 448, 481 |
| `list_sort_filter_bar.dart` | `state_shadow_books.dart` | `ref.watch(shadowBooksProvider)` guarded by isGroupMode | VERIFIED | Lines 130–132 |
| `list_screen.dart` | `state_list_transactions.dart` | `ref.invalidate(listTransactionsProvider(...))` in onRefresh | VERIFIED | Line 67 |
| `list_screen.dart` | `state_calendar_totals.dart` | `ref.invalidate(calendarDailyTotalsProvider(...))` in onRefresh | VERIFIED | Lines 68–72 |

---

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|----------|---------------|--------|--------------------|--------|
| `state_list_transactions.dart` | `shadowBookList` | `shadowBooksProvider.future` (DB query) | Yes — live Riverpod provider backed by DB | FLOWING |
| `state_list_transactions.dart` | `memberTag` | `bookIdToShadow[tx.bookId]` lookup → `ShadowBookInfo.memberAvatarEmoji/memberDisplayName` | Yes — built from shadow book data | FLOWING |
| `state_calendar_totals.dart` | `merged` map | `repo.getDailyTotals(bookId: bid, ...)` per-book loop | Yes — DB aggregate query per book | FLOWING |
| `list_transaction_tile.dart` | `tag.emoji` / `tag.name` | `taggedTx.memberTag` from provider | Yes — flows from shadow book provider through state_list_transactions | FLOWING |
| `list_sort_filter_bar.dart` | `shadowBooksAsync` | `ref.watch(shadowBooksProvider)` | Yes — live Riverpod stream | FLOWING |

---

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| All 97 list feature tests pass | `flutter test test/unit/features/list/ test/widget/features/list/ --no-pub` | 97 passed, 0 failed | PASS |
| Phase 29 test subset (39 tests) | `flutter test [5 Phase 29 files] --no-pub` | 39 passed, 0 failed | PASS |
| flutter analyze on list feature | `flutter analyze lib/features/list/ --no-pub` | No issues found | PASS |
| ARB key parity | `flutter test test/architecture/arb_key_parity_test.dart --no-pub` | All tests passed | PASS |
| Stale suppressions scan | `flutter test test/architecture/stale_suppressions_scan_test.dart --no-pub` | All tests passed | PASS |
| listFilterProvider absent from calendar provider | `grep -n "listFilterProvider" state_calendar_totals.dart` | 0 live references (comments only) | PASS |
| RefreshIndicator present | `grep -n "RefreshIndicator" list_screen.dart` | Line 64 | PASS |
| AlwaysScrollableScrollPhysics (≥2 sites) | `grep -n "AlwaysScrollableScrollPhysics" list_screen.dart` | Lines 80, 89, 120, 127 (4 sites) | PASS |
| anyFilterActive 5-condition form in screen | `grep -n "memberBookId" list_screen.dart` | Line 115: `filter.memberBookId != null` | PASS |
| CR-01 fix — stale memberBookId fallback | Code at `state_list_transactions.dart:63–65`; regression test commit 25403a3c | Falls back to full bookIds; test passes | PASS |
| Full project suite | `flutter test --no-pub` | 2202 passed, 11 failed (all 11 in home_hero_card_golden_test.dart — pre-existing, Phase 30 scope) | PASS (Phase 29 scope) |

---

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| LIST-04 | 29-01, 29-04 | User can pull-to-refresh the list | SATISFIED | RefreshIndicator wired in list_screen.dart; wave-0 tests pass |
| FAM-01 | 29-01, 29-02, 29-04 | When family joined, list includes family members' transactions (shadow books) merged | SATISFIED | state_list_transactions.dart fan-out + state_calendar_totals.dart per-book sum |
| FAM-02 | 29-01, 29-02, 29-03 | Each row attributes its owner (member name/emoji) in family mode | SATISFIED | Member attribution chip in list_transaction_tile.dart; driven by memberTag from provider |
| FAM-03 | 29-01, 29-02, 29-03 | User can filter list by family member | SATISFIED | Per-member ActionChips in list_sort_filter_bar.dart calling setMemberFilter; SQL-level narrowing in provider |
| FAM-04 | 29-01, 29-02, 29-03 | User can quickly switch to "Mine only" view in family mode | SATISFIED | Mine-only ActionChip in list_sort_filter_bar.dart; setMemberFilter(ownBookId) wired |
| LIST-03 | (not Phase 29) | User sees clear empty state when no transactions match | DEFERRED | Assigned to Phase 30 per REQUIREMENTS.md traceability table |

No orphaned requirements detected. All Phase 29 IDs (LIST-04, FAM-01–04) are covered. LIST-03 is correctly in Phase 30.

---

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `list_screen.dart` | 101 | `Text('[data load error]', ...)` — hardcoded UI string | Warning | Violates CLAUDE.md i18n rule "All UI text via S.of(context)"; pre-existing (WR-01 from review); Phase 30 candidate |
| `list_screen.dart` | 39, 187 | `const currencyCode = 'JPY'` / `'JPY'` literal — explicitly marked as Phase 29 out-of-scope seam in RESEARCH.md | Warning | Multi-currency books show wrong symbol; pre-existing; WR-02 from review; Phase 30 candidate |
| `list_screen.dart` | 75 | `onRefresh` awaits only list future, not calendar future — spinner may dismiss before calendar settles | Warning | WR-04 from review; spinner "dishonesty" is cosmetic, not a data loss issue; no test asserts calendar-await behavior |
| `list_sort_filter_bar.dart` | (structural) | Duplicate `anyFilterActive` 5-condition predicate in both `list_screen.dart` and `list_sort_filter_bar.dart` | Info | IN-03 from review; drift risk if a new filter field is added; no immediate breakage |

**Debt marker check:** No `TBD`, `FIXME`, or `XXX` markers found in Phase 29-modified files. The `// Phase 29: resolve currencyCode from bookByIdProvider` comment at `list_screen.dart:38` is a deferred-work note without a formal issue reference — however the RESEARCH.md explicitly documents this seam as out-of-scope for Phase 29, and it does not block current functionality for the default JPY book. This is a WARNING, not a BLOCKER.

No blockers from anti-pattern scan.

---

### Human Verification Required

The human checkpoint (Plan 04 Task 2) was APPROVED during execution. The following items are surfaced here for the escalation gate record per verification protocol.

#### 1. Visual Pull-to-Refresh (Solo Mode)

**Test:** Open the List tab in solo mode. Pull down on the list. Confirm spinner appears and dismisses. Pull on empty month (pull-to-refresh fires even when list is empty).
**Expected:** Spinner fires in all three content states (loading, data, empty); list reloads after dismiss.
**Why human:** Gesture physics, spinner animation timing, and empty-state pull behavior are not fully capturable by widget tests (drag target was simplified for test determinism).

#### 2. Family Mode — Member Attribution Chips

**Test:** With a family group joined, open the List tab. Confirm rows from family members show a small trailing chip (e.g. "🐻 太郎") in a warm-peach/terracotta color. Confirm own rows show no chip.
**Expected:** Shadow-book rows: chip visible with emoji+name. Own-book rows: no chip. Both in the same combined list view.
**Why human:** Visual chip appearance (AppColors.sharedLight color rendering on device) and row-level attribution cannot be verified by automated pixel checks given pending golden re-baseline in Phase 30.

#### 3. Mine-Only and Member Chips — Interaction

**Test:** In family mode, tap "Mine only" chip. Confirm list narrows to own entries only. Calendar totals remain full-family combined. Tap "Mine only" again — list returns to combined. Tap a member chip — list shows only that member's entries. Tap same chip — returns to combined.
**Expected:** Toggle behavior for Mine-only and per-member chips. Calendar totals and month total do NOT narrow with member filter (Pitfall 3 isolation).
**Why human:** Toggle state visual feedback, calendar isolation from member filter, and the combined/individual distinction require visual + interaction verification.

#### 4. AND-Composition (Ledger + Member Filter)

**Test:** In family mode, apply both a ledger filter (生存 or 魂) AND a member filter. Confirm list shows only entries matching BOTH conditions. With member filter active, confirm "Clear all" chip appears and clears member filter on tap.
**Expected:** AND-composition works; Clear chip visible when memberBookId set; tapping Clear removes all filters.
**Why human:** AND-composition requires visual state inspection; Clear chip visibility edge case with combined filters.

---

### Gaps Summary

No blocking gaps. All 14 must-haves are VERIFIED.

The following items are open but non-blocking (code review findings carried forward, scoped to Phase 30 or later):

1. **WR-01** (`list_screen.dart:101`): `'[data load error]'` hardcoded string — Phase 30 i18n cleanup candidate.
2. **WR-02** (`list_screen.dart:39,187`): `const currencyCode = 'JPY'` seam — explicitly out-of-scope per RESEARCH.md; Phase 29 handles JPY-only scenario correctly.
3. **WR-04** (`list_screen.dart:75`): onRefresh awaits only list future; calendar future not co-awaited — cosmetic spinner timing issue, no data loss.
4. **CR-02** (pre-existing from Phase 28): swipe-delete silently discards `Result.error` — acknowledged in review, tagged as pre-existing per commit 234bf9f2. Phase 29 did not introduce or worsen this.
5. **11 golden failures** in `test/golden/home_hero_card_golden_test.dart` — pre-existing from quick task 260522-fj5 (home feature); Phase 30 scope ("golden baselines").

---

_Verified: 2026-05-31T09:00:00Z_
_Verifier: Claude (gsd-verifier)_
