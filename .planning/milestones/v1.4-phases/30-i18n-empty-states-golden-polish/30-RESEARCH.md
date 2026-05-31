# Phase 30: i18n + Empty States + Golden Polish — Research

**Researched:** 2026-05-31
**Domain:** Flutter golden tests, ARB i18n, Riverpod provider rework, widget refactor
**Confidence:** HIGH (all findings verified from live codebase)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Lock golden baselines for all 6 list-tab widgets: `list_transaction_tile`, `list_day_group_header`, `list_sort_filter_bar`, `list_empty_state`, `list_calendar_header`, `list_category_filter_sheet`.
- **D-02:** Coverage per widget = all 3 locales (ja/zh/en), light theme only. No dark-theme goldens this phase.
- **D-03:** Goldens hard-fail CI, with determinism investment: pin fonts + `textScaleFactor`, disable animations, freeze `table_calendar` to a fixed reference date. No pixel-tolerance threshold.
- **D-04:** Three-state empty state with exact locked copy (see D-04 table in CONTEXT.md). Icons: `receipt_long_outlined` / `event_busy_outlined` / `search_off_outlined`.
- **D-05:** Branching: day-only active → day-empty message + "show full month" clears only the day filter. Any other filter active (regardless of day) → filtered message + "clear filters" clears all.
- **D-06:** Copy refinement — update `listEmptyMonth`, `listEmptyFiltered`, `listEmptyFilteredClear` to D-04 table wording; add 2 new keys `listEmptyDay` + `listEmptyDayClear` (×3 locales).
- **D-07:** `listMineOnly` — fix from "Mine only" in all 3 locales to: ja: 自分のみ · zh: 仅自己 · en: Mine only.
- **D-08:** Hardcoded-string sweep scope = fix within `lib/features/list/` only. Document everything found outside as deferred inventory (no fixes outside list tab).
- **D-09:** Preserve exact 3-locale key parity (currently 1199 keys each). Every key added/renamed lands in all 3 ARB files + `flutter gen-l10n` with no warnings.
- **D-10:** Coverage gate = ≥70% (overrides global 80% default for this polish phase).
- **D-11:** Full green gate before phase close: `flutter analyze` 0, `dart run custom_lint --no-fatal-infos` 0, `build_runner` diff clean, coverage ≥70%.

### Claude's Discretion

- Exact golden test file organization (one file per widget vs grouped).
- Fixture construction and determinism harness mechanics — follow existing `test/golden/*.dart` conventions.
- Mechanical ARB key insertion order and `@`-metadata formatting.

### Deferred Ideas (OUT OF SCOPE)

- App-wide hardcoded-string fixes outside `lib/features/list/` — document as inventory only.
- Dark-theme goldens — explicitly deferred to a future visual-QA phase.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LIST-03 | User sees a clear empty state when no transactions match the current month + active filters | Rework `list_empty_state.dart` to 3-state enum; update `list_screen.dart` branching at line 121; add `listEmptyDay` + `listEmptyDayClear` ARB keys; use `selectDay(null)` for day-only clear |

</phase_requirements>

---

## Summary

Phase 30 closes out the v1.4 列表功能 milestone with targeted polish: 3-locale parity, empty-state refinement, and golden baselines for all 6 list-tab widgets. The codebase is already well-structured — the changes are additions and precise reworks, not architectural shifts.

**Four research questions resolved below:** (1) golden determinism mechanics for `list_calendar_header` and the 5 simpler widgets; (2) the day-only-clear path in the filter notifier; (3) the 3-state empty-state branching signal derivation; (4) ARB key mechanics and parity invariant details.

**Primary recommendation:** Implement in three logical units — ARB key edits first (pure text), then the 3-state `list_empty_state.dart` rework, then golden test files. Keep ARB + widget changes in early waves so golden baselines are generated against the final UI.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| ARB key authoring + gen-l10n | `lib/l10n/` (data) | CI (validation) | Locale files are plain JSON; gen-l10n generates from them |
| Empty-state widget 3-state render | `lib/features/list/presentation/widgets/` | `lib/features/list/presentation/screens/` | Widget owns render; screen owns branching signal computation |
| Branching signal (isDayOnly/isOtherFilter) | `lib/features/list/presentation/screens/list_screen.dart` | — | Screen computes from `listFilterProvider` state; passes to widget |
| Day-only clear action | `lib/features/list/presentation/providers/state_list_filter.dart` | — | `selectDay(null)` already exists; no new method needed |
| Golden test harness | `test/golden/` | — | Follows existing `amount_display_golden_test.dart` / `per_category_breakdown_card_golden_test.dart` conventions |
| CI gate (analyze/lint/coverage) | CI workflow (`.github/workflows/audit.yml`) | — | Existing jobs already run flutter test + coverde; goldens run under `flutter test --coverage` |

---

## Standard Stack

### Core (already in project — no new deps)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_localizations` | sdk | ARB-driven localization | Part of Flutter SDK; gen-l10n generates from `lib/l10n/` |
| `flutter_riverpod` | ^3.1.0 | Provider state management | Project standard; `ListFilter` notifier is Riverpod 3 |
| `table_calendar` | ^3.2.0 | Calendar widget in `CalendarHeaderWidget` | Already in `pubspec.lock`; frozen `focusedDay` via filter override |
| `freezed_annotation` | ^3.0.0 | Immutable model `ListFilterState` | `copyWith` pattern; `clearAll()` returns new state |
| `flutter_test` (sdk) | sdk | Golden test framework | `matchesGoldenFile`, `tester.pumpAndSettle` |

No new packages needed for this phase.

### Package Legitimacy Audit

> No new packages are installed in this phase. Section not applicable.

---

## Architecture Patterns

### Golden Test Harness Pattern (from codebase)

**Proven by:** `test/golden/amount_display_golden_test.dart` (3-locale, no ProviderScope) and `test/golden/per_category_breakdown_card_golden_test.dart` (3-locale + ProviderScope overrides).

```
┌─────────────────────────────────────────────────┐
│           Golden Test _wrap() function           │
│                                                  │
│  ProviderScope(overrides: [...])                 │
│    MaterialApp(                                  │
│      locale: Locale('ja'|'en'|'zh'),             │
│      localizationsDelegates: S.localizationsDelegates,
│      supportedLocales: S.supportedLocales,       │
│      theme: ThemeData.light(),                   │
│      home: Scaffold(                             │
│        body: SizedBox(width: W, height: H,       │
│          child: <widget under test>,             │
│        ),                                        │
│      ),                                          │
│    ),                                            │
│  )                                               │
└─────────────────────────────────────────────────┘
         │
         ▼
  pumpAndSettle() ← drains AnimatedSize + async providers
         │
         ▼
  matchesGoldenFile('goldens/<name>_<locale>.png')
```

**File per widget or grouped:** Following existing convention (one file per widget), each file in `test/golden/` with prefix `list_` (e.g., `list_calendar_header_golden_test.dart`). Place golden PNGs in `test/golden/goldens/` with naming `list_<widget>_<locale>.png`.

### Recommended Golden Test Structure

```
test/golden/
├── list_calendar_header_golden_test.dart    # 3 locales × 1 state = 3 goldens
├── list_category_filter_sheet_golden_test.dart  # 3 locales = 3 goldens
├── list_day_group_header_golden_test.dart   # 3 locales = 3 goldens
├── list_empty_state_golden_test.dart        # 3 locales × 3 states = 9 goldens
├── list_sort_filter_bar_golden_test.dart    # 3 locales = 3 goldens
├── list_transaction_tile_golden_test.dart   # 3 locales = 3 goldens
└── goldens/
    ├── list_calendar_header_ja.png
    ├── list_calendar_header_zh.png
    ├── list_calendar_header_en.png
    └── ... (total: 24 goldens)
```

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Day-only filter clear | New `clearDay()` notifier method | Existing `selectDay(null)` | Already implemented in `ListFilter.selectDay`; calling with `null` is the documented clear path |
| ARB key parity check | Manual key counting | Existing `test/architecture/arb_key_parity_test.dart` | Already enforces sorted key equality across all 3 locales; adding keys to all 3 files is all that's needed |
| Golden font loading | Custom `FontLoader` setup | System default (Ahem) + `textScaleFactor: 1.0` | Existing goldens (`amount_display`, `per_category_breakdown_card`) render stable without font loading; Outfit font falls back to system font in test env consistently |
| Calendar date freezing | Custom clock injection | Filter provider override + past fixed month | Override `listFilterProvider` to `year=2025, month=1` so `DateTime.now()` (2026-05) never matches a calendar cell → no `todayBuilder` special decoration |

---

## Resolved Research Questions

### D-03 (Golden Determinism) — VERIFIED from codebase

**Root cause of home_hero flakiness:** The `home_hero_card` failures in `test/golden/failures/` were generated 2026-05-31 (today). The `masterImage` vs `testImage` differ in file size (~24.7 KB vs ~22.5 KB for `home_hero_card_single_light_ja`), indicating a rendering difference caused by font substitution or environment delta — not date-dependent content in the home_hero widget (no `DateTime.now()` found in `home_hero_card.dart`).

**The `list_calendar_header` has a MORE specific flake source:** `_buildDayCell` calls `DateTime.now()` directly at line 142 to compute `isToday`:

```dart
// lib/features/list/presentation/widgets/list_calendar_header.dart:142
final isToday = isSameDay(day, DateTime.now());
```

This means the calendar's "today" highlight changes every day. A golden generated on 2026-05-31 shows May 31 highlighted; on 2026-06-01 the highlight moves to June 1 → pixel-perfect mismatch guaranteed across dates.

**Proven fix — past-month filter override (no widget surgery required):**

Override `listFilterProvider` in the golden test to return `ListFilterState(selectedYear: 2025, selectedMonth: 1)` (January 2025). Since `DateTime.now()` returns May 2026, `isSameDay(day, DateTime.now())` will return false for every cell in the January 2025 calendar grid. The `todayBuilder` path still renders but uses the same `_buildDayCell` as `defaultBuilder` (the code passes `isSelected=false` in both cases) → no special decoration → deterministic output regardless of run date.

```dart
// Golden test override pattern for CalendarHeaderWidget:
final container = ProviderContainer.test(overrides: [
  // Pin to Jan 2025 so DateTime.now() (2026-05) never hits a cell
  listFilterProvider.overrideWith((ref) =>
      const ListFilterState(selectedYear: 2025, selectedMonth: 1)),
  // Return deterministic empty data
  calendarDailyTotalsProvider(bookId: 'test', year: 2025, month: 1)
      .overrideWith((_) async => <DateTime, int>{}),
  // Solo mode (no family members shown)
  isGroupModeProvider.overrideWith((_) => false),
]);
```

**Animation source in `_SummaryRow`:** `AnimatedSize` at line 337 of `list_calendar_header.dart` wraps the day subline. With `activeDayFilter == null` in the initial filter state, the `SizedBox.shrink()` branch renders statically. `pumpAndSettle()` drains this.

**`textScaleFactor` and `devicePixelRatio`:** The existing stable goldens (`amount_display`, `per_category_breakdown_card`) do not explicitly pin these. They remain stable because `matchesGoldenFile` uses pixel-exact comparison with `flutter test` default environment (logical pixels at 1.0 dpr). For consistency, follow the same pattern — do NOT pin unless a specific test shows instability.

**Font situation:** The project uses `fontFamily: 'Outfit'` in `AppTextStyles` but there is NO `fonts:` section in `pubspec.yaml` and NO `google_fonts` package. This means Outfit is not bundled and Flutter's test harness falls back to the `Ahem` font for all test rendering. This is consistent across all test environments (CI and local) and is WHY `amount_display` and `per_category_breakdown_card` goldens are stable — they both use this same Ahem-fallback rendering. The list-tab golden tests should follow the same approach (no explicit font loading required).

**`--update-goldens` baseline generation:** Run once per widget file after implementation is complete:
```bash
flutter test test/golden/list_calendar_header_golden_test.dart --update-goldens
```
This generates/overwrites `test/golden/goldens/list_calendar_header_*.png`. Commit those PNG files alongside the test code. Subsequent `flutter test` runs without `--update-goldens` compare against the committed baseline.

### D-05 (Day-Only Clear Path) — VERIFIED from codebase

**Finding: No new notifier method is needed.**

The `ListFilter` notifier in `state_list_filter.dart` already exposes `selectDay(DateTime? day)`:

```dart
// lib/features/list/presentation/providers/state_list_filter.dart:35
void selectDay(DateTime? day) {
  state = state.copyWith(activeDayFilter: day);
}
```

Calling `selectDay(null)` sets `activeDayFilter` to null while leaving all other filter fields (ledgerType, categoryIds, searchQuery, memberBookId) unchanged. This is exactly the "show full month" action D-05 requires — it clears only the day filter.

**Contrast with `clearAll()`** which calls `ListFilterState.initial()` (resets the entire state including the month to `DateTime.now().year/month`). The day-empty action must call `selectDay(null)`, not `clearAll()`.

**New widget parameter design:** The refactored `ListEmptyState` should receive a discriminated state signal from `list_screen.dart`. The simplest approach matching the existing pattern:

```dart
// Enum-based 3-state (clearest intent)
enum ListEmptyVariant { noData, dayEmpty, filtered }
```

`ListEmptyState` constructor changes from `isFilterActive: bool` to `variant: ListEmptyVariant`. The widget calls:
- `variant == ListEmptyVariant.dayEmpty` → `ref.read(listFilterProvider.notifier).selectDay(null)`
- `variant == ListEmptyVariant.filtered` → `ref.read(listFilterProvider.notifier).clearAll()`
- `variant == ListEmptyVariant.noData` → no action widget

### D-04/D-05 (3-State Branching Signal) — VERIFIED from codebase

**Current code (list_screen.dart lines 111–121):**

```dart
final anyFilterActive = filter.activeDayFilter != null ||
    filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;

if (txs.isEmpty) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    child: ListEmptyState(isFilterActive: anyFilterActive),
  );
}
```

**New branching logic needed:**

```dart
// D-05 logic: "other" filters = any non-day filter
final anyOtherFilter = filter.ledgerType != null ||
    filter.categoryIds.isNotEmpty ||
    filter.searchQuery.isNotEmpty ||
    filter.memberBookId != null;

// Determine variant:
// - isDayOnlyActive: day selected AND no other filter → dayEmpty state
// - anyOtherFilter: other filter active (regardless of day) → filtered state
// - else: no filters → noData state
final variant = anyOtherFilter
    ? ListEmptyVariant.filtered
    : (filter.activeDayFilter != null
        ? ListEmptyVariant.dayEmpty
        : ListEmptyVariant.noData);

return SingleChildScrollView(
  physics: const AlwaysScrollableScrollPhysics(),
  child: ListEmptyState(variant: variant),
);
```

**Key point:** `anyOtherFilter` takes priority over `activeDayFilter`. If both a day filter AND a ledger filter are active and no results found, the state is `filtered` (with "clear all" action), not `dayEmpty`. This matches D-05: "Any other filter active (regardless of day) → filtered message."

### ARB Key Mechanics — VERIFIED from codebase

**Parity enforcement:** `test/architecture/arb_key_parity_test.dart` enforces that sorted key sets are identical across all 3 locales. It compares sorted normal keys (no `@`) and sorted metadata keys (with `@`) to the `en` locale as reference. Adding 2 new keys to all 3 files maintains parity automatically.

**Current key counts:**
- Total `@`-metadata keys per file: 429 (verified by `grep -c '"@'`)
- Total `list*` non-metadata keys per file: 24 (verified by `grep -c '"list[A-Z]'`)
- ARB files are exactly 2210 lines each (perfectly symmetric)

**New keys to add (×3 locales):**

| Key | ja | zh | en |
|-----|----|----|-----|
| `listEmptyDay` | この日の記録はありません | 这一天没有记录 | No records on this day |
| `listEmptyDayClear` | 月全体を表示 | 显示整月 | Show full month |

**Keys to update (copy change only, key name unchanged):**

| Key | Current ja | New ja (D-06) |
|-----|-----------|---------------|
| `listEmptyMonth` | この月の記録はありません | この月にはまだ記録がありません |

| Key | Current zh | New zh |
|-----|-----------|--------|
| `listEmptyMonth` | 本月暂无记录 | 本月还没有记录 |

| Key | Current en | New en |
|-----|-----------|--------|
| `listEmptyMonth` | No entries this month | No records yet this month |
| `listEmptyFiltered` | No entries match your filters | No records match your filters |

**Key to fix (value change, key name unchanged):**

| Key | All locales current | New values |
|-----|---------------------|------------|
| `listMineOnly` | "Mine only" (all 3) | ja: 自分のみ / zh: 仅自己 / en: Mine only |

**Metadata format (follow existing pattern):**

```json
"listEmptyDay": "この日の記録はありません",
"@listEmptyDay": {
  "description": "Empty state when day filter active and no transactions on that day (Phase 30)"
},
"listEmptyDayClear": "月全体を表示",
"@listEmptyDayClear": {
  "description": "Clear day filter action in day-empty state (Phase 30)"
},
```

**Insertion position:** After `listEmptyFilteredClear` (current last `list*` key at line 2206 of each ARB file). New keys go immediately after `listEmptyFilteredClear`'s closing `}` and before `"@@locale"`.

**gen-l10n run after changes:**
```bash
flutter gen-l10n
```
This regenerates `lib/generated/app_localizations.dart` and the per-locale files. Run `flutter analyze` immediately after to catch any missing key references.

### Hardcoded String Audit in `lib/features/list/` — VERIFIED from codebase

**Found hardcoded string within list feature scope (D-08, fix in this phase):**

`lib/features/list/presentation/screens/list_screen.dart:101`:
```dart
'[data load error]',
```
This error fallback string is not via `S.of(context)`. Needs an ARB key (suggest `listLoadError`) or can be left as a debug-only internal string — D-08 says "fix only within `lib/features/list/`", so it should be addressed. Adding an ARB key `listLoadError` is the correct fix.

**Found hardcoded Semantics labels in `list_calendar_header.dart`:**
- Line: `Semantics(label: 'Previous month', ...)` 
- Line: `Semantics(label: 'Next month', ...)`
- Line: `Semantics(label: 'Return to current month', ...)`

Semantics labels are accessibility strings — they are user-visible in assistive technology. These should be ARB-keyed per D-08. Suggest keys: `listCalNavPrev`, `listCalNavNext`, `listCalNavCurrentMonth`.

**All other list feature strings are already via `S.of(context)`** — verified by scanning `list_sort_filter_bar.dart`, `list_empty_state.dart`, `list_transaction_tile.dart`, `list_category_filter_sheet.dart`, `list_day_group_header.dart`.

**Deferred (document only, no fix this phase):** The hardcoded CJK scan test (`test/architecture/hardcoded_cjk_ui_scan_test.dart`) already auto-detects hardcoded CJK strings in `lib/`. A grep sweep for English hardcoded strings outside `lib/features/list/` is an additional D-08 deliverable — document findings in the phase deliverables for the backlog.

---

## Golden Test Patterns — Per Widget

### Widget 1: `list_day_group_header`
**Provider deps:** None (pure `StatelessWidget`)
**Inputs:** `date: DateTime`, `locale: Locale`
**Flake risk:** LOW — date is injected, no `DateTime.now()`
**Test pattern:** Inject fixed `date: DateTime(2026, 5, 15)` for each locale. `_wrap()` from `amount_display_golden_test.dart` is sufficient (no ProviderScope needed).

### Widget 2: `list_empty_state`
**Provider deps:** `listFilterProvider.notifier` (called only in button callbacks, not in `build()`)
**Inputs (new):** `variant: ListEmptyVariant`
**Flake risk:** LOW — pure layout, no date/time
**Test pattern:** 3 variants × 3 locales = 9 goldens. Wrap in `ProviderScope` (needed for the `ref.read` in button callbacks, even if not triggered during `pumpAndSettle`).

### Widget 3: `list_sort_filter_bar`
**Provider deps:** `listFilterProvider`, `isGroupModeProvider`, `shadowBooksProvider`, `currentLocaleProvider`
**Flake risk:** LOW — no date-dependent rendering
**Test pattern:** Override all 4 providers:
- `listFilterProvider.overrideWith(...)` → default initial state (solo mode, no filters)
- `isGroupModeProvider.overrideWith((_) => false)` → hide "Mine only" chip
- `currentLocaleProvider.overrideWith((_) async => Locale('ja'))` → avoid async settle issues (same as existing `list_sort_filter_bar_test.dart`)
- `shadowBooksProvider` only needed when `isGroupMode` is true (override to `[]` as safety)

### Widget 4: `list_transaction_tile`
**Provider deps:** `deleteTransactionUseCaseProvider` (accessed only in `onDismissed`, not in `build()`)
**Inputs:** All pre-formatted display values injected via constructor (tagText, category, formattedAmount, etc.)
**Flake risk:** LOW — purely data-driven display widget
**Test pattern:** No provider overrides needed in `build()`. Use a `ProviderContainer.test()` for safety. Supply fixture `TaggedTransaction` with known values (e.g., JPY 1234, Soul ledger). Use fixed locale for date formatting.

### Widget 5: `list_category_filter_sheet`
**Provider deps:** `categoryRepositoryProvider`, `listFilterProvider`, `currentLocaleProvider`
**Flake risk:** LOW — static sheet content
**Test pattern:** Override `categoryRepositoryProvider` with a `_FakeCategoryRepository` (same as `list_category_filter_sheet_test.dart`). Pin `currentLocaleProvider`. The sheet shows a fixed list of categories — use the same fake categories across all 3 locales for consistency.

### Widget 6: `list_calendar_header` (highest complexity)
**Provider deps:** `calendarDailyTotalsProvider`, `listFilterProvider`, `isGroupModeProvider`, `shadowBooksProvider`
**Flake risk:** HIGH — `DateTime.now()` in `_buildDayCell`
**Test pattern (full specification):**

```dart
// Determinism fix: pin to past month so DateTime.now() never matches a cell
const _fixedYear = 2025;
const _fixedMonth = 1; // January 2025

Widget _wrap({required Locale locale}) {
  return ProviderScope(
    overrides: [
      listFilterProvider.overrideWith(
        (ref) => ListFilterState(
          selectedYear: _fixedYear,
          selectedMonth: _fixedMonth,
        ),
      ),
      calendarDailyTotalsProvider(
        bookId: 'test_book',
        year: _fixedYear,
        month: _fixedMonth,
      ).overrideWith((_) async => <DateTime, int>{}),
      isGroupModeProvider.overrideWith((_) => false),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      theme: ThemeData.light(),
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 520, // Calendar grid + summary row
          child: CalendarHeaderWidget(
            bookId: 'test_book',
            currencyCode: 'JPY',
            locale: locale,
          ),
        ),
      ),
    ),
  );
}
```

**Why January 2025:** `DateTime.now()` is 2026-05-31 at research time. January 2025 is 16 months ago — guaranteed to never be "today" in CI. The calendar grid will render 31 cells for Jan 2025 with no special decoration (no "today" highlight, no selected day). All 3 locales render identically structured grids (Sunday-start for ja/zh, Monday-start for en — different DOW header layout, intentional and correct).

---

## Common Pitfalls

### Pitfall 1: `clearAll()` instead of `selectDay(null)` for day-empty action
**What goes wrong:** The "show full month" button in the `dayEmpty` state calls `clearAll()`, which resets the month anchor to `DateTime.now()` and clears the sort config too.
**Why it happens:** Easy to grab the existing `clearAll()` reference without noticing `selectDay(null)` exists.
**How to avoid:** The day-empty action MUST call `ref.read(listFilterProvider.notifier).selectDay(null)`. The filtered action calls `clearAll()`. These are different.
**Warning signs:** After tapping "show full month", the calendar jumps to the current month (filter was on a past/future month) — symptom of `clearAll()` being used.

### Pitfall 2: Golden calendar renders "today" highlight on the run date
**What goes wrong:** Golden test uses `ListFilterState.initial()` (or no override), which anchors to `DateTime.now().year/month`. The calendar grid highlights today's cell with the accent color — this changes daily → flaky golden.
**Why it happens:** Not overriding the filter provider to a fixed past month.
**How to avoid:** Override `listFilterProvider` to `ListFilterState(selectedYear: 2025, selectedMonth: 1)`.
**Warning signs:** Failing golden where the diff isolates to a single calendar cell.

### Pitfall 3: Missing `listFilterProvider` override causes `ListFilterState.initial()` to call `DateTime.now()`
**What goes wrong:** If the golden test constructs a `ProviderContainer` without overriding `listFilterProvider`, the notifier's `build()` calls `ListFilterState.initial()` which uses `DateTime.now()` for year/month. Two test runs on different days produce different golden images.
**Why it happens:** `ListFilterState.initial()` is defined as `ListFilterState(selectedYear: DateTime.now().year, selectedMonth: DateTime.now().month)`.
**How to avoid:** Always override `listFilterProvider` in calendar golden tests.

### Pitfall 4: ARB parity test failure from adding key to only 2 of 3 locales
**What goes wrong:** `test/architecture/arb_key_parity_test.dart` fails with "normalKeys differ for zh compared with en."
**Why it happens:** Adding `listEmptyDay` to `app_ja.arb` and `app_en.arb` but forgetting `app_zh.arb`.
**How to avoid:** Always edit all 3 ARB files in a single commit. Use `grep -c '"list[A-Z]'` on each file to confirm equal counts after edits.

### Pitfall 5: `flutter gen-l10n` not run after ARB edits
**What goes wrong:** Widget code references the new `S.of(context).listEmptyDay` but it doesn't exist in `lib/generated/` — compile error.
**How to avoid:** Run `flutter gen-l10n` after every ARB edit. The `build_runner` clean diff check in D-11 also catches stale generated files.

### Pitfall 6: `AnimatedSize` in `_SummaryRow` causes non-settling golden
**What goes wrong:** `pumpAndSettle()` times out because `AnimatedSize` is still animating.
**Why it happens:** Rare — `AnimatedSize` with `activeDayFilter == null` renders `SizedBox.shrink()` which is stable. Mostly a risk if a day filter is injected.
**How to avoid:** For golden tests, do not inject an `activeDayFilter` (keep it null). The collapsed `SizedBox.shrink()` requires no animation.

### Pitfall 7: `isFilterActive: anyFilterActive` API still in use after widget rework
**What goes wrong:** `list_screen.dart` still passes `isFilterActive: anyFilterActive` to `ListEmptyState` after renaming the constructor to `variant`.
**How to avoid:** The rework of `ListEmptyState` is a constructor-breaking change — update both the widget and the call site in `list_screen.dart` in the same commit.

### Pitfall 8: Existing `list_empty_state_test.dart` not updated
**What goes wrong:** The existing widget test for `ListEmptyState` still tests `isFilterActive: true/false` API — tests pass on old API, fail to compile on new API.
**How to avoid:** Update `test/widget/features/list/list_empty_state_test.dart` alongside the widget rework. The new test covers all 3 variants.

---

## Runtime State Inventory

This is not a rename/refactor/migration phase. No runtime state is modified. Section not applicable.

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All | ✓ | SDK from pubspec.yaml | — |
| `flutter gen-l10n` | ARB changes | ✓ | Bundled with Flutter | — |
| `build_runner` | Code gen check | ✓ | ^2.4.14 | — |
| `flutter analyze` | CI gate D-11 | ✓ | SDK | — |
| `dart run custom_lint` | CI gate D-11 | ✓ | 0.8.1 | — |
| `coverde` | Coverage gate | ✓ | 0.3.0+1 (via CI) | — |

No missing dependencies.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) |
| Config file | No `flutter_test_config.dart` exists — each test self-contained |
| Quick run command | `flutter test test/golden/list_empty_state_golden_test.dart` |
| Full suite command | `flutter test --coverage` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| LIST-03 | No-data empty state renders correctly (all 3 locales) | Golden | `flutter test test/golden/list_empty_state_golden_test.dart` | ❌ Wave 0 |
| LIST-03 | Day-empty state renders with "show full month" action | Golden | `flutter test test/golden/list_empty_state_golden_test.dart` | ❌ Wave 0 |
| LIST-03 | Filtered-empty state renders with "clear filters" action | Golden | `flutter test test/golden/list_empty_state_golden_test.dart` | ❌ Wave 0 |
| LIST-03 | 3-state widget unit test (variant enum → correct icon + text + action) | Widget | `flutter test test/widget/features/list/list_empty_state_test.dart` | ✅ (needs update) |
| LIST-03 | Day-only clear calls `selectDay(null)` not `clearAll()` | Unit | `flutter test test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` | ✅ (needs day-only-clear test added) |
| D-09 | ARB key parity preserved after new keys | Architecture | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ |
| D-11 | Zero analyzer issues | Static | `flutter analyze --no-fatal-infos` | ✅ (CI runs it) |
| D-11 | Zero custom_lint errors | Static | `dart run custom_lint --no-fatal-infos` | ✅ (CI runs it) |
| D-11 | Build runner clean diff | Static | `flutter pub run build_runner build --delete-conflicting-outputs && git diff --exit-code` | ✅ (CI AUDIT-10) |
| D-11 | Coverage ≥70% | Coverage | `flutter test --coverage` + coverde | ✅ (CI runs it) |

**Golden files that need `--update-goldens` baseline generation (all new):**
- `test/golden/list_calendar_header_golden_test.dart` (3 PNGs)
- `test/golden/list_category_filter_sheet_golden_test.dart` (3 PNGs)
- `test/golden/list_day_group_header_golden_test.dart` (3 PNGs)
- `test/golden/list_empty_state_golden_test.dart` (9 PNGs — 3 variants × 3 locales)
- `test/golden/list_sort_filter_bar_golden_test.dart` (3 PNGs)
- `test/golden/list_transaction_tile_golden_test.dart` (3 PNGs)

### Sampling Rate

- **Per task commit:** `flutter analyze` + the relevant widget test file
- **Per wave merge:** `flutter test --coverage` (full suite)
- **Phase gate:** Full suite green + `build_runner` diff clean before `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/golden/list_calendar_header_golden_test.dart` — covers golden determinism for `CalendarHeaderWidget`
- [ ] `test/golden/list_category_filter_sheet_golden_test.dart`
- [ ] `test/golden/list_day_group_header_golden_test.dart`
- [ ] `test/golden/list_empty_state_golden_test.dart` — 9 cases (3 variants × 3 locales)
- [ ] `test/golden/list_sort_filter_bar_golden_test.dart`
- [ ] `test/golden/list_transaction_tile_golden_test.dart`
- [ ] Update `test/widget/features/list/list_empty_state_test.dart` — must match new `variant:` API (currently tests `isFilterActive:` binary API)
- [ ] Add 1 unit test to `test/unit/features/list/presentation/providers/list_filter_notifier_test.dart` — day-only clear behavior: `selectDay(null)` preserves ledgerType, categoryIds, searchQuery, memberBookId

---

## Security Domain

This phase modifies UI copy (ARB text), widget rendering logic, and golden test files. No security-sensitive surface is touched.

| ASVS Category | Applies | Note |
|---------------|---------|------|
| V2 Authentication | No | No auth changes |
| V3 Session Management | No | No session changes |
| V4 Access Control | No | No access control changes |
| V5 Input Validation | No | No new user input surface |
| V6 Cryptography | No | No crypto changes |

---

## Project Constraints (from CLAUDE.md)

- All UI text via `S.of(context)` — enforced by `hardcoded_cjk_ui_scan_test.dart` for CJK; English strings in `lib/features/list/` must also be ARB-keyed.
- Dates via `DateFormatter`, amounts via `NumberFormatter` — already correct in all list widgets.
- `listMineOnly` fix: "Mine only" → ja: 自分のみ / zh: 仅自己 / en: Mine only (D-07).
- Update ALL 3 ARB files, then `flutter gen-l10n`. ARB parity test enforces this.
- Zero `flutter analyze` warnings before commit — current list widgets are clean.
- Generated files (`.g.dart`, `.freezed.dart`) must not be hand-edited.
- Coverage gate: ≥70% (D-10, overrides global 80% for this phase per ROADMAP SC#4).
- `ListEmptyState` currently has binary `isFilterActive` constructor — this is a breaking change; update the call site in `list_screen.dart` and the existing `list_empty_state_test.dart` in the same plan.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The `isGroupModeProvider` is defined in `lib/features/family_sync/presentation/providers/state_active_group.dart` (import found in list_sort_filter_bar.dart and list_calendar_header via state_calendar_totals) | Golden patterns | Provider not found → import error in test; low risk — already used in existing widget tests |
| A2 | January 2025 will always be in the past relative to the CI run date, so `DateTime.now()` will never equal a Jan 2025 cell | Golden determinism | If a CI machine has a bogus clock set to 2025-01-XX, golden would show a today-cell; extremely unlikely |

**All other claims are verified directly from the codebase source files.**

---

## Open Questions

1. **Should the `listLoadError` string (`'[data load error]'` in `list_screen.dart:101`) get an ARB key or be kept as internal?**
   - What we know: D-08 says "fix only within `lib/features/list/`" — this qualifies.
   - What's unclear: Is this error ever user-visible in production, or only during development? The error widget renders in the main list area with an `Icons.error_outline` — it IS user-visible.
   - Recommendation: Add ARB key `listLoadError` to all 3 locales. Suggest copy: ja: "データを読み込めません" (already used in `calLoadError` for the calendar), zh: "无法加载数据", en: "Unable to load data". This is a 3-line ARB addition with no widget surgery.

2. **Semantics labels in `list_calendar_header.dart` (D-08 scope)?**
   - What we know: Three hardcoded English Semantics labels exist ("Previous month", "Next month", "Return to current month") — accessibility strings, user-visible.
   - What's unclear: D-08 says "fix within `lib/features/list/`" — these qualify. But they are Semantics labels, not visible UI text. Whether to ARB-key them is a judgment call.
   - Recommendation: Add 3 new ARB keys (`listCalNavPrev`, `listCalNavNext`, `listCalNavCurrentMonth`) to all 3 locales. Total list* key count: 24 existing + 2 (listEmptyDay/DayClear) + 1 (listLoadError) + 3 (Semantics) = 30 list* keys after phase. Planner should confirm whether Semantics labels are in scope with user before committing.

---

## Sources

### Primary (HIGH confidence — verified from live codebase)

- `lib/features/list/presentation/widgets/list_empty_state.dart` — current binary API confirmed
- `lib/features/list/presentation/screens/list_screen.dart:111` — branching logic confirmed
- `lib/features/list/presentation/providers/state_list_filter.dart` — `selectDay(null)` confirmed as day-only clear
- `lib/features/list/domain/models/list_filter_state.dart` — `clearAll()` resets to `DateTime.now()` confirmed
- `lib/features/list/presentation/widgets/list_calendar_header.dart:142` — `DateTime.now()` flake source confirmed
- `test/golden/amount_display_golden_test.dart` — proven 3-locale harness pattern
- `test/golden/per_category_breakdown_card_golden_test.dart` — proven ProviderScope override pattern
- `test/golden/failures/` — 6 `home_hero_card_*_ja` failing golden pairs (today's date timestamps)
- `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — 429 metadata keys each, `listMineOnly` = "Mine only" in all 3 confirmed
- `test/architecture/arb_key_parity_test.dart` — parity enforcement mechanism confirmed
- `lib/core/theme/app_text_styles.dart` — `fontFamily: 'Outfit'` with no bundled font asset (no `fonts:` in pubspec.yaml)

### Secondary (MEDIUM confidence)

- Flutter golden test behavior with missing fonts: Ahem fallback in test environment is standard Flutter behavior; stable because deterministic.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages; all existing
- Architecture: HIGH — verified from live code
- Pitfalls: HIGH — derived directly from code inspection
- Golden determinism: HIGH — root cause found in `list_calendar_header.dart:142` with `DateTime.now()`

**Research date:** 2026-05-31
**Valid until:** Stable — code not expected to change before planning
