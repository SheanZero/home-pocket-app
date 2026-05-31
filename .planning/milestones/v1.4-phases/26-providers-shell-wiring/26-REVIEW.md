---
phase: 26-providers-shell-wiring
reviewed: 2026-05-30T00:00:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - lib/features/home/presentation/screens/main_shell_screen.dart
  - lib/features/list/domain/models/tagged_transaction.dart
  - lib/features/list/presentation/providers/repository_providers.dart
  - lib/features/list/presentation/providers/state_list_filter.dart
  - lib/features/list/presentation/providers/state_list_transactions.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - test/main_characterization_smoke_test.dart
  - test/unit/features/list/domain/models/tagged_transaction_test.dart
  - test/unit/features/list/presentation/providers/list_filter_notifier_test.dart
  - test/unit/features/list/presentation/providers/list_transactions_provider_test.dart
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 26: Code Review Report

**Reviewed:** 2026-05-30
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Phase 26 wired the list feature's three-layer provider stack (`ListFilter`
Notifier → `getListTransactionsUseCaseProvider` → `listTransactionsProvider`),
introduced the `TaggedTransaction` / `MemberTag` value objects, and replaced the
shell's static List-tab placeholder with a loading-only `ListScreen`. The code is
generally well-structured and adheres to the project's layer rules: the use-case
provider correctly reuses the single `transactionRepositoryProvider` via a `show`
clause (no duplicate repo provider), the filter Notifier follows Riverpod 3
naming (`listFilterProvider`, not `listFilterNotifierProvider`), all mutators use
`copyWith`, and the `import_guard.yaml` blocks infrastructure reachability.

No BLOCKER-level correctness, security, or data-loss defects were found. However,
there are three WARNING-level concerns that will surface real defects once Phase 28
renders data on top of this wiring — most notably a locale-loading race that can
make the text-search filter compute against the wrong language on first emission,
and a hidden dependency on `IndexedStack` keeping the provider alive that the
keepAlive annotations do not actually cover. These should be addressed before the
data-rendering phase builds on this foundation.

## Warnings

### WR-01: Text-search filter computes against the wrong locale during `currentLocaleProvider` load

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:41-42`

**Issue:** The provider reads the locale with a synchronous fallback:

```dart
final locale = ref.watch(currentLocaleProvider).value ?? const Locale('ja');
```

`currentLocaleProvider` is an async provider (`Future<Locale>`). On the very first
build — and after any invalidation that re-triggers the locale load — `.value` is
`null` while the future is pending, so the pipeline falls back to `ja`. For a user
whose actual locale is `en` or `zh`, the text-search step (step 6b) resolves
`categoryId → localized name` using the **Japanese** map, producing incorrect
match/no-match results for that emission. When the locale future resolves, the
provider rebuilds and recomputes correctly, so the final state is right — but the
intermediate emission is wrong.

This is invisible in Phase 26 because `ListScreen` is loading-only, but it becomes
a user-visible "wrong search results flash" the moment Phase 28 renders the data
branch. The provider's own doc comment (step 2, D-04) asserts locale-correct
resolution as a contract, so this is a latent correctness gap, not just style.

**Fix:** Await the locale instead of falling back, so the filter never runs against
a placeholder locale. Since the provider is already `async`, gate on the resolved
value:

```dart
// Step 2: read locale for category name resolution (D-04)
// Await so search never runs against a placeholder locale (WR-01).
final locale = await ref.watch(currentLocaleProvider.future);
```

This keeps the provider in `loading` until the locale is known, which the UI
already handles (the screen shows a spinner). If a non-blocking default is truly
desired, document explicitly that the first emission may be locale-mismatched and
add a test asserting the post-resolution recompute.

### WR-02: keepAlive intent is not actually enforced — `listTransactionsProvider` is auto-dispose and only survives by accident of `IndexedStack`

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:32-36` (and `state_list_filter.dart:16`)

**Issue:** `ListFilter` is annotated `@Riverpod(keepAlive: true)` and its doc claims
filter state "persists when the user navigates away from the List tab and returns."
But `listTransactions` is a plain `@riverpod` (auto-dispose) provider. The two are
coupled: `listTransactions` `ref.watch`es `listFilterProvider`. The filter state
does survive, but the *derived list result* does not — `listTransactionsProvider`
will be disposed and fully recomputed (re-querying the repo, re-running the locale
resolution and text search) whenever it has no listeners.

The comment in `state_list_filter.dart` claims this is safe because "Under
IndexedStack widgets are never unmounted, so subscriptions never drop." That is the
**only** thing keeping `listTransactionsProvider` alive — an implementation detail of
`MainShellScreen`'s `IndexedStack`, not anything in the provider layer. The
keepAlive annotation on the filter is described as guarding "against future
refactors," but it does not guard the expensive derived provider at all. A future
refactor swapping `IndexedStack` for lazy tab construction (a common optimization)
would silently change the caching behavior with no compile-time or test signal.

**Fix:** Either make the dependency explicit by also keep-aliving the derived
provider if persistence of results is intended:

```dart
@Riverpod(keepAlive: true)
Future<List<TaggedTransaction>> listTransactions(Ref ref, {
  required String bookId,
}) async { ... }
```

…or, if auto-dispose is intentional (recompute on every tab entry), update the
`state_list_filter.dart` doc comment to stop implying the *list* persists — only
the *filter* does — and add a widget/provider test that pins the IndexedStack
assumption so a future lazy-tab refactor fails loudly.

### WR-03: Use-case error surfaced via untyped `Exception(result.error)` loses the failure type and risks leaking sensitive detail

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:53-56`

**Issue:**

```dart
if (result.isError) {
  throw Exception(result.error);
}
```

`result.error` is the raw error string from the `Result` returned by the use case /
repository. Two problems:

1. **Type erasure:** It is thrown as a generic `Exception` with the message
   embedded in `toString()`. The `ListScreen` error branch renders it verbatim
   (`error: (e, _) => Center(child: Text(e.toString()))`, `list_screen.dart:23`).
   In Phase 28 this becomes user-facing UI text. A raw repository/SQL error string
   shown directly to the user violates the project's security rule
   *"Error messages don't leak sensitive data"* (`.claude/rules/security.md`) and
   the CLAUDE.md crypto rule about not surfacing internal detail.
2. **Lost structure:** Callers cannot distinguish "empty bookIds" from a DB failure;
   everything collapses into one opaque `Exception`.

This is a WARNING (not BLOCKER) only because `ListScreen` is loading-only this phase
and never actually renders the error text yet — but the wiring that will leak it is
already in place.

**Fix:** Throw a typed, message-sanitized error and have the UI map it to a
localized string rather than echoing `e.toString()`:

```dart
if (result.isError) {
  // Typed so the UI can localize; raw detail stays out of the user-facing string.
  throw ListLoadException(result.error ?? 'unknown');
}
```

and in `list_screen.dart`, render a localized message via `S.of(context)` instead of
`e.toString()`. At minimum, do not pass `result.error` straight to a `Text` widget.

## Info

### IN-01: Day filter is applied twice (SQL date-range + Dart re-filter)

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:60-72`

**Issue:** When `activeDayFilter` is non-null, `GetListTransactionsUseCase._dateRange`
already constrains the SQL query to `DateBoundaries.dayRange(...)` (00:00:00–23:59:59
of that day). The provider then re-filters in Dart by `year && month && day`. The
Dart pass is redundant given the SQL range already isolates the day. It is harmless
(and arguably defensive against any future sort/merge that widens the range), but it
duplicates intent across two layers and is a maintenance trap: a change to the date
boundary in one place won't be caught by the other.

**Fix:** Either drop the Dart-side day filter and rely on the use case's date range,
or add a one-line comment explaining the redundancy is an intentional belt-and-braces
guard for the Phase 29 multi-book merge (where ranges may overlap). Prefer a comment
since removing it slightly increases coupling to the use case's internal behavior.

### IN-02: `Exception` thrown for control flow on a known-error `Result` defeats the typed-Result pattern

**File:** `lib/features/list/presentation/providers/state_list_transactions.dart:54-55`

**Issue:** The use case deliberately returns `Result<T>` (success/error) rather than
throwing, per the project's repository/Result convention. Converting that back into a
thrown generic `Exception` at the provider boundary partially discards the value of
the pattern. (Closely related to WR-03; tracked separately as a design-consistency
note since Riverpod *does* require a throw to populate `AsyncError`.)

**Fix:** Acceptable to throw here (Riverpod needs it for `AsyncValue.hasError`), but
throw a domain-specific exception type so the Result→AsyncError bridge stays typed.

### IN-03: `MemberTag` doc says "always null in Phase 26" but the type permits construction — no guard

**File:** `lib/features/list/domain/models/tagged_transaction.dart:7-19`

**Issue:** The doc comments repeatedly assert `memberTag` is "always null" in Phase 26,
and `listTransactions` hardcodes `memberTag: null` (line 96). This is fine, but nothing
prevents a future caller from constructing a non-null `MemberTag` and the surrounding
code (UI, equality) silently behaving differently. Building the VO fully now (D-07) is
a reasonable forward-investment, but the "always null this phase" invariant lives only
in prose.

**Fix:** No code change required for this phase. When Phase 29 wiring lands, ensure a
test asserts the own-book path still produces `memberTag == null` (the existing
`tagged_transaction_test.dart` already covers the null-equality path, which is good).

### IN-04: Two identical post-action invalidation blocks duplicated in `MainShellScreen`

**File:** `lib/features/home/presentation/screens/main_shell_screen.dart:48-94` and `134-172`

**Issue:** The sync-complete listener (lines 48–94) and the post-FAB-entry callback
(lines 134–172) contain nearly identical invalidation sequences — same month-boundary
computation, same `monthlyReport` / `todayTransactions` / `bestJoyMoment` /
`happinessReport` / `listTransactions` invalidations. The duplication is already a
maintenance hazard (the sync block additionally invalidates `shadowBooks` /
`shadowAggregate`, so they have drifted), and the month-boundary computation
(`DateTime(now.year, now.month + 1, 0, 23, 59, 59)`) is repeated three times across
the file.

**Fix:** Extract a private helper, e.g.
`void _invalidateMonthScopedData(WidgetRef ref, {bool includeShadow = false})`, and a
`({DateTime start, DateTime end}) _currentMonthRange()` (or reuse
`DateBoundaries.monthRange`). This removes the drift risk and the magic
`23, 59, 59` literals. Note this is the correct module per the layer rules — keep it in
presentation; do not push it into the application layer.

---

_Reviewed: 2026-05-30_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
