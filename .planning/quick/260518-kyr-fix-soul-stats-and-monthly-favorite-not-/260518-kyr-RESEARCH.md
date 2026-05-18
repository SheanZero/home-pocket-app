---
quick_id: 260518-kyr
type: research
created: 2026-05-18
---

# Research: Soul Stats / Monthly Favorite Refresh Bug

## 1. Widget Locations

All three widgets live inside a single `Builder` block in `HomeScreen.build()`, rendered as parts of `HomeHeroCard`. `HomeHeroCard` itself is a pure `StatelessWidget` — it receives unwrapped Dart objects (not `AsyncValue`). The `HomeScreen` resolves all three `AsyncValue.when()` chains before passing data down.

| Widget | UI Region | Data Provider (watched in `home_screen.dart`) | Lines |
|---|---|---|---|
| 总支出 (total expense) | `HomeHeroCard._hero()` — `report.totalExpenses` | `monthlyReportProvider(bookId, year, month)` | `home_screen.dart:80–85` |
| 悦己统计 (Soul Stats ring + legend) | `HomeHeroCard._ringSection()` — `happiness.*` | `happinessReportProvider(bookId, year, month, currencyCode)` | `home_screen.dart:98–105` |
| 本月最爱 (Best Joy strip) | `HomeHeroCard._buildBestJoyStrip()` — `bestJoy` | `bestJoyMomentProvider(bookId, year, month)` | `home_screen.dart:106–112` |

## 2. Provider Chains (working vs broken)

### Working: 总支出

```
monthlyReportProvider(bookId, year, month)   [state_analytics.dart:31]
  @riverpod Future<MonthlyReport>
  └─ ref.watch(getMonthlyReportUseCaseProvider)  [repository_providers.dart:38]
       └─ GetMonthlyReportUseCase.execute()       [get_monthly_report_use_case.dart:23]
            └─ AnalyticsRepository (one-shot Future queries via AnalyticsDao)
```

**Type:** `@riverpod Future<T>` — FutureProvider, one-shot, NOT a reactive stream.

**Why it refreshes:** The FAB callback in `main_shell_screen.dart:101–107` calls:

```dart
ref.invalidate(monthlyReportProvider(bookId: bookId, year: now.year, month: now.month));
ref.invalidate(todayTransactionsProvider(bookId: bookId));
```

`ref.invalidate()` marks the cached future as stale, forcing a rebuild and a fresh DB query on next `ref.watch()`.

### Broken: 悦己统计

```
happinessReportProvider(bookId, year, month, currencyCode)   [state_happiness.dart:17]
  @riverpod Future<HappinessReport>
  └─ ref.watch(getHappinessReportUseCaseProvider)  [repository_providers.dart:61]
       └─ GetHappinessReportUseCase.execute()       [get_happiness_report_use_case.dart:28]
            └─ AnalyticsRepository (soul-only aggregate queries via AnalyticsDao)
```

**Type:** `@riverpod Future<T>` — same pattern as `monthlyReportProvider`. Also one-shot, not reactive.

**Where the chain breaks:** `main_shell_screen.dart:99–108` does NOT include `ref.invalidate(happinessReportProvider(...))`. The provider is never invalidated after the FAB insert flow completes.

### Broken: 本月最爱

```
bestJoyMomentProvider(bookId, year, month)   [state_happiness.dart:35]
  @riverpod Future<MetricResult<BestJoyMomentRow>>
  └─ ref.watch(getBestJoyMomentUseCaseProvider)  [repository_providers.dart:85]
       └─ GetBestJoyMomentUseCase.execute()
            └─ AnalyticsRepository.getBestJoyMoment()  (soul-filtered rank query)
```

**Type:** `@riverpod Future<T>` — same pattern.

**Where the chain breaks:** Same as above. `main_shell_screen.dart:99–108` does NOT include `ref.invalidate(bestJoyMomentProvider(...))`.

## 3. Transaction Insert Path

**Insert call site:** `TransactionConfirmScreen._save()` at `transaction_confirm_screen.dart:289–342`.

```dart
// transaction_confirm_screen.dart:298-317
final createUseCase = ref.read(createTransactionUseCaseProvider);
final result = await createUseCase.execute(CreateTransactionParams(...));
```

`CreateTransactionUseCase.execute()` (`create_transaction_use_case.dart:72`) calls `_transactionRepo.insert(transaction)` at line 162. It performs NO `ref.invalidate()` — the use case has no reference to `ref` at all. There is no in-memory cache in the service layer.

**After save, navigation:** On success, the confirm screen calls:

```dart
// transaction_confirm_screen.dart:342
Navigator.of(context).popUntil((route) => route.isFirst);
```

This pops all pushed routes and returns control to `MainShellScreen`. The FAB's `await Navigator.of(context).push<void>(...)` then resolves, and the `onFabTap` callback continues (lines 93–109 in `main_shell_screen.dart`):

```dart
// main_shell_screen.dart:100-108
final now = DateTime.now();
ref.invalidate(
  monthlyReportProvider(bookId: bookId, year: now.year, month: now.month),
);
ref.invalidate(todayTransactionsProvider(bookId: bookId));
// <-- happinessReportProvider: NOT HERE
// <-- bestJoyMomentProvider: NOT HERE
```

No Drift `watchX` reactive streams are involved anywhere in the analytics chain. All three providers use `customSelect(...).get()` (one-shot queries) inside `AnalyticsDao`, not `watch()`.

## 4. Root Cause (the concrete diff)

**Why 总支出 refreshes:**
`monthlyReportProvider` is a `@riverpod Future<MonthlyReport>` (one-shot). It only re-executes when explicitly invalidated. The FAB callback in `main_shell_screen.dart:101–107` includes `ref.invalidate(monthlyReportProvider(...))`, so it re-fetches from DB and the widget rebuilds.

**Why 悦己统计 does NOT refresh:**
`happinessReportProvider` is structurally identical — also a `@riverpod Future<HappinessReport>`. Its cached result persists in the Riverpod container indefinitely. The FAB callback simply omits `ref.invalidate(happinessReportProvider(...))`. The container serves the stale cached value, so `HomeScreen` renders the pre-insert soul stats.

**Why 本月最爱 does NOT refresh:**
`bestJoyMomentProvider` is again identical in pattern — `@riverpod Future<MetricResult<BestJoyMomentRow>>`. Same omission in the FAB callback. Stale cached value is served.

**One-line diff:** The FAB `onFabTap` callback in `main_shell_screen.dart` invalidates 2 of the 4 providers that `HomeScreen` watches, but skips `happinessReportProvider` and `bestJoyMomentProvider`.

Note: `happinessReportProvider` takes a `currencyCode` family parameter that `monthlyReportProvider` does not. `currencyCode` is derived from `bookByIdProvider` (`home_screen.dart:87–96`). The FAB callback in `main_shell_screen.dart` does not have access to `currencyCode` at that point — this must be factored into the fix (see Section 6).

## 5. Service-Layer Consistency Risk

Other entry points that reference `happinessReportProvider` or `bestJoyMomentProvider`:

| File | Lines | Context | Same latent bug? |
|---|---|---|---|
| `analytics_screen.dart:178,184,201,534-546` | `ref.watch(happinessReportProvider(...))` and `ref.watch(bestJoyMomentProvider(...))` | Analytics screen pulls these providers | No — the analytics screen has `RefreshIndicator` → `_refresh()` which correctly calls `ref.invalidate` on both (lines 172-209). Manual pull-to-refresh works. But if user enters transaction from analytics screen FAB, same stale-until-refresh-swipe issue applies. |
| `analytics_screen.dart:75–80` | `_refresh()` method | Only triggered by pull-to-refresh gesture | Not a bug, just manual — always works when triggered |

No in-memory cache exists inside `GetHappinessReportUseCase` or `GetBestJoyMomentUseCase` — they are stateless and re-query the DB on every `execute()` call. The stale data is entirely in Riverpod's `FutureProvider` cached result.

## 6. Fix Approach (Recommended)

**Location to change:** `lib/features/home/presentation/screens/main_shell_screen.dart`, `onFabTap` callback, lines 93–109.

**Challenge:** `happinessReportProvider` requires `currencyCode` as a family parameter. The shell does not currently have access to it. Two options:

**Option A (minimal, preferred):** Use `ref.invalidate` with the provider family — invalidate ALL cached instances of `happinessReportProvider` for this bookId by using the provider's `family` override directly. Riverpod's `ref.invalidate` on a family provider with partial parameters is NOT supported — you must pass all family parameters or use `ref.invalidate(provider)` on the base provider (which invalidates ALL family instances).

For `@riverpod`-generated families, calling `ref.invalidate(happinessReportProvider)` (no args) is NOT valid Dart — the generated `happinessReportProvider` is a `FamilyOverride` requiring all params. The clean solution is to read `currencyCode` in the shell at invalidation time.

**Option B (cleanest):** Add `bookByIdProvider` watch to the shell for `currencyCode`, or invalidate `happinessReportProvider` by reading `bookAsync` in a local read:

```dart
// main_shell_screen.dart — in onFabTap callback, after the await:
final now = DateTime.now();
ref.invalidate(monthlyReportProvider(bookId: bookId, year: now.year, month: now.month));
ref.invalidate(todayTransactionsProvider(bookId: bookId));
// --- ADD THESE TWO LINES ---
final book = ref.read(bookByIdProvider(bookId: bookId)).value;
final currencyCode = book?.currency ?? 'JPY';
ref.invalidate(happinessReportProvider(
  bookId: bookId, year: now.year, month: now.month, currencyCode: currencyCode,
));
ref.invalidate(bestJoyMomentProvider(bookId: bookId, year: now.year, month: now.month));
```

Note: `bookByIdProvider` is already imported in `home_screen.dart` via `repository_providers.dart`. The shell must import it too:
```dart
import '../../../accounting/presentation/providers/repository_providers.dart';
```
(Already present at `main_shell_screen.dart` — check the import list; if not present, add it.)

**build_runner:** No `@riverpod` / `@freezed` annotations are touched. This change is pure wiring in a non-annotated callback. `build_runner` is NOT needed.

**flutter analyze** must pass (0 issues) before commit per CLAUDE.md.

Also consider the sync path: `main_shell_screen.dart:33–58` listens to `syncStatusStreamProvider` and invalidates providers on sync completion. Same omission exists there — add the same two invalidations to that `ref.listen` block for consistency.

## 7. Pitfalls

- **currencyCode family param:** `happinessReportProvider` has 4 family args including `currencyCode`. Invalidation must pass the exact same `currencyCode` value that was used when the provider was originally built, or it will create a new (fresh) family instance and silently leave the old cached one alive. Using `ref.read(bookByIdProvider(...)).value?.currency ?? 'JPY'` matches the same fallback logic used in `home_screen.dart:95–96`.

- **Do NOT use `ref.refresh` instead of `ref.invalidate`:** `ref.invalidate` marks stale and rebuilds lazily on next watch. `ref.refresh` triggers an eager rebuild including when no listener exists — fine here but semantically weaker guarantee.

- **Do NOT mutate shared state:** Use `ref.invalidate` + let Riverpod re-execute the provider. No manual state mutation or local cache modification.

- **Riverpod 3 `AsyncValue.valueOrNull` is gone:** If the fix touches any `AsyncValue` consumption, use `.value` (nullable) not `.valueOrNull` (removed in Riverpod 3).

- **No build_runner required** for this fix. If a future refactor adds `@riverpod` annotations to the shell, run `flutter pub run build_runner build --delete-conflicting-outputs` after.

- **Sync path is also affected:** `main_shell_screen.dart:33–58` has the same omission — `happinessReportProvider` and `bestJoyMomentProvider` are not invalidated after sync completes. Fixing only the FAB path leaves the sync path broken. Fix both in one commit.
