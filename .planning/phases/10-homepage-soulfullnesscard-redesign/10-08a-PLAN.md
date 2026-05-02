---
phase: 10-homepage-soulfullnesscard-redesign
plan: 08a
type: execute
wave: 5
depends_on: [07b]
files_modified:
  - lib/features/home/presentation/screens/home_screen.dart
autonomous: true
requirements: [HOMEUI-05, HOMEUI-06, HOMEUI-07, FAMILY-03]
tags: [home-screen, integration, wire-up]

must_haves:
  truths:
    - "`home_screen.dart` imports `HomeHeroCard` and renders exactly one instance"
    - "`MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard` imports are removed; the 3 separate widget call blocks are replaced with one consolidated provider-resolution Builder + HomeHeroCard"
    - "Old helpers `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` may still EXIST as dead code at this stage — Plan 10-08b owns their deletion (intentional split for executor checkpoint per checker B3)"
    - "All providers needed by HomeHeroCard are watched and `.when()`-resolved at the parent: `monthlyReportProvider`, `happinessReportProvider`, `bestJoyMomentProvider`, `bookByIdProvider`, `currentLocaleProvider`, `isGroupModeProvider`; group-mode-only: `familyHappinessProvider`, `shadowBooksProvider`, `shadowAggregateProvider`"
    - "Tap target navigates to `AnalyticsScreen(bookId: bookId)` per Pitfall #9 (no `AnalyticsRegion` enum)"
    - "Currency code resolved from `bookByIdProvider(bookId).valueOrNull?.currency ?? 'JPY'` — JPY fallback only when Book is missing — comment marker `Pitfall #9` or `fallback only when Book is missing` documents the legitimate site (B4 strict guard)"
    - "`flutter analyze lib/features/home/presentation/screens/home_screen.dart` reports 0 issues"
  artifacts:
    - path: "lib/features/home/presentation/screens/home_screen.dart"
      provides: "HomePage renders 1 HomeHeroCard via consolidated provider-resolution Builder; old widget call sites removed; old helper bodies still present pending Plan 10-08b deletion"
      contains: "HomeHeroCard"
  key_links:
    - from: "lib/features/home/presentation/screens/home_screen.dart"
      to: "lib/features/home/presentation/widgets/home_hero_card.dart"
      via: "import + constructor call"
      pattern: "HomeHeroCard\\("
    - from: "lib/features/home/presentation/screens/home_screen.dart"
      to: "lib/features/accounting/presentation/providers/repository_providers.dart"
      via: "ref.watch(bookByIdProvider(bookId: bookId))"
      pattern: "bookByIdProvider"
---

<objective>
Wire `HomeHeroCard` into `home_screen.dart`: replace the 3 separate widget calls (`MonthOverviewCard`, `LedgerComparisonSection`, `SoulFullnessCard`) with a single `HomeHeroCard` call backed by a consolidated provider-resolution Builder.

This plan does NOT delete the obsolete inline helpers (`_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows`). Plan 10-08b owns that deletion + line-count enforcement. The split between wire-up (10-08a) and cleanup (10-08b) provides an executor checkpoint per checker B3 — once 10-08a lands, the new HomeHeroCard renders correctly while the dead helper code coexists temporarily.

This plan owns HOMEUI-05/06/07 wiring (the new card receives the data needed for hero header, split bar, member rows) + FAMILY-03 minimum-gate (parent decides isGroupMode + shadowBooks visibility). HOMEUI-02 (helper deletion) belongs to Plan 10-08b.

Output: `home_screen.dart` renders `HomeHeroCard`; old widget call sites and their direct imports are removed; old helper bodies remain untouched (Plan 10-08b deletes them).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@lib/features/home/presentation/screens/home_screen.dart
@lib/features/home/presentation/widgets/home_hero_card.dart
@lib/features/analytics/presentation/providers/state_happiness.dart
@lib/features/analytics/presentation/providers/state_analytics.dart
@lib/features/home/presentation/providers/state_shadow_books.dart
@lib/features/family_sync/presentation/providers/state_active_group.dart
@lib/features/settings/presentation/providers/state_locale.dart
@lib/features/accounting/presentation/providers/repository_providers.dart
@lib/features/analytics/presentation/screens/analytics_screen.dart
</context>

<tasks>

<task type="auto" tdd="false">
  <name>Task 8a.1: Wire HomeHeroCard into home_screen.dart (no helper deletion)</name>
  <files>lib/features/home/presentation/screens/home_screen.dart</files>
  <read_first>
    - lib/features/home/presentation/screens/home_screen.dart (FULL FILE — 386 lines; locate every reference to MonthOverviewCard / LedgerComparisonSection / SoulFullnessCard but DO NOT delete the helper methods in this plan)
    - lib/features/home/presentation/widgets/home_hero_card.dart (delivered by Plan 10-07b — confirm constructor signature: report, happiness, bestJoy, family, shadowBooks, shadowAggregate, currencyCode, locale, isGroupMode, onTap)
    - lib/features/analytics/presentation/providers/state_happiness.dart (lines 14-65 — confirm provider signatures: `happinessReport(bookId, year, month, currencyCode)`, `bestJoyMoment(bookId, year, month)`, `familyHappiness(year, month)`)
    - lib/features/analytics/presentation/providers/state_analytics.dart (locate `monthlyReportProvider` signature)
    - lib/features/home/presentation/providers/state_shadow_books.dart (lines 13-72 — confirm `shadowBooksProvider` returns List<ShadowBookInfo>; `shadowAggregateProvider` returns ShadowAggregate)
    - lib/features/family_sync/presentation/providers/state_active_group.dart (locate `isGroupModeProvider`)
    - lib/features/settings/presentation/providers/state_locale.dart (locate `currentLocaleProvider`)
    - lib/features/accounting/presentation/providers/repository_providers.dart (Plan 10-05 added `bookByIdProvider(bookId: bookId)` — confirm signature)
    - lib/features/analytics/presentation/screens/analytics_screen.dart (line 25 — `AnalyticsScreen({super.key, required this.bookId})`)
  </read_first>
  <action>
Edit `lib/features/home/presentation/screens/home_screen.dart` per the following plan.

**Step 1: Update imports.**

Remove these imports (the widget call sites are gone — but DO NOT remove `'../models/ledger_row_data.dart'` yet; Plan 10-08b removes it after `_buildLedgerRows` is deleted):
- `'../widgets/ledger_comparison_section.dart'`
- `'../widgets/month_overview_card.dart'`
- `'../widgets/soul_fullness_card.dart'`

Add this import:
- `'../widgets/home_hero_card.dart'`

Keep all other existing imports (transaction list card, hero header, bottom nav, family invite banner, providers, `'../models/ledger_row_data.dart'` until 10-08b, etc.).

**Step 2: Locate the 3 separate widget rendering blocks.**

Currently around lines 88-105 (MonthOverviewCard), 113-128 (LedgerComparisonSection), 132-143 (SoulFullnessCard). The widget tree currently looks like:

```
column children:
  HeroHeader
  ...
  monthlyReportProvider.when(... MonthOverviewCard ...)
  ...
  monthlyReportProvider.when(... LedgerComparisonSection(rows: _buildLedgerRows(...))) 
  ...
  monthlyReportProvider.when(... SoulFullnessCard(satisfactionPercent: _computeSatisfaction(...), happinessROI: _computeHappinessROI(...), recentSoulAmount: ...))
```

**Replace these 3 blocks with a single block** rendering `HomeHeroCard`. The placement should be where `MonthOverviewCard` was (high in the visual stack — first card under the hero header).

**Step 3: Insert the consolidated provider resolution + HomeHeroCard render.**

Insert in the same location as the original `monthlyReportProvider.when(...)` for MonthOverviewCard. The block looks roughly like:

```dart
Builder(
  builder: (context) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final reportAsync = ref.watch(monthlyReportProvider(
      bookId: bookId,
      year: year,
      month: month,
    ));
    final bookAsync = ref.watch(bookByIdProvider(bookId: bookId));
    final isGroupMode = ref.watch(isGroupModeProvider);
    final locale = ref.watch(currentLocaleProvider);

    // CLAUDE.md Pitfall #9 — fallback only when Book is missing.
    // This is the SOLE legitimate 'JPY' literal in the home feature; future grep audits
    // verify no other site re-introduces it.
    final currencyCode = bookAsync.valueOrNull?.currency ?? 'JPY';

    final happinessAsync = ref.watch(happinessReportProvider(
      bookId: bookId,
      year: year,
      month: month,
      currencyCode: currencyCode,
    ));
    final bestJoyAsync = ref.watch(bestJoyMomentProvider(
      bookId: bookId,
      year: year,
      month: month,
    ));

    // Group-mode-only providers — read AsyncData(null/[]) when not in group mode
    final familyAsync = isGroupMode
        ? ref.watch(familyHappinessProvider(year: year, month: month))
        : const AsyncData<FamilyHappiness?>(null);
    final shadowBooksAsync = isGroupMode
        ? ref.watch(shadowBooksProvider).whenData<List<ShadowBookInfo>?>((value) => value)
        : const AsyncData<List<ShadowBookInfo>?>(null);
    final shadowAggregateAsync = isGroupMode
        ? ref.watch(shadowAggregateProvider).whenData<ShadowAggregate?>((value) => value)
        : const AsyncData<ShadowAggregate?>(null);

    return reportAsync.when(
      data: (report) => happinessAsync.when(
        data: (happiness) => bestJoyAsync.when(
          data: (bestJoy) => familyAsync.when(
            data: (family) => shadowBooksAsync.when(
              data: (shadowBooks) => shadowAggregateAsync.when(
                data: (shadowAggregate) => HomeHeroCard(
                  report: report,
                  happiness: happiness,
                  bestJoy: bestJoy,
                  family: family,
                  shadowBooks: shadowBooks,
                  shadowAggregate: shadowAggregate,
                  currencyCode: currencyCode,
                  locale: locale,
                  isGroupMode: isGroupMode,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AnalyticsScreen(bookId: bookId),
                    ),
                  ),
                ),
                loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
                error: (e, _) => _ErrorText(message: '$e'),
              ),
              loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => _ErrorText(message: '$e'),
            ),
            loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
            error: (e, _) => _ErrorText(message: '$e'),
          ),
          loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => _ErrorText(message: '$e'),
        ),
        loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
        error: (e, _) => _ErrorText(message: '$e'),
      ),
      loading: () => const SizedBox(height: 320, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => _ErrorText(message: '$e'),
    );
  },
),
```

**Adjustment notes:**
- The deeply nested `.when()` chain is hostile but matches the project's existing pattern (verbatim from `home_screen.dart:88-105` style). Refactoring to a `combine()` extension is OUT OF SCOPE for Plan 10-08 — keep the chain as-is for minimal risk.
- The exact provider invocation pattern depends on the actual provider signatures; verify against the read_first files. If `shadowBooksProvider` is a non-async provider, drop the `.when()` for that branch.
- The fallback on missing book (`?? 'JPY'`) is the SOLE legitimate use of `'JPY'` literal in the home feature — it only fires when the Book lookup itself fails, which is a separate failure case from currency resolution. Document this with a comment.
- The locale `currentLocaleProvider` returns `Locale` — it's NOT an AsyncValue based on existing project patterns; if it IS an AsyncValue, adjust the `.when()` accordingly.
- `Navigator.of(context).push(MaterialPageRoute(...))` per Pitfall #9 — DO NOT introduce `AnalyticsRegion` enum (Phase 11 work).

**Step 4: Update imports for AnalyticsScreen if not already present.**

Add: `import '../../../analytics/presentation/screens/analytics_screen.dart';` if missing.

**Step 5: Run analyzer.**

```bash
flutter analyze lib/features/home/presentation/screens/home_screen.dart
```

Expect:
- `flutter analyze` reports 0 issues. **EXCEPT** the analyzer may emit `unused_element` hints for `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` — those are intentional dead code at this stage and Plan 10-08b deletes them. If analyzer treats `unused_element` as warning rather than info, suppress the hint at each helper site with `// ignore: unused_element` (with a TODO marker `// TODO(plan-10-08b): delete this helper`); 10-08b removes both the helper and the ignore.
- The existing `home_screen_test.dart` likely FAILS because it has `find.byType(MonthOverviewCard)` etc. assertions for widgets that no longer exist. This is EXPECTED at this point in Phase 10. Plan 10-09 owns deletion of those obsolete tests + Plan 10-10 owns the new test scaffold population. Note the test failures and proceed; do NOT modify the test file in this plan.

**Forbidden:**
- DO NOT delete `_computeHappinessROI`, `_computeSatisfaction`, or `_buildLedgerRows` in this plan — Plan 10-08b owns the deletion. The split is the executor checkpoint.
- DO NOT touch ANY other helpers in `home_screen.dart` (e.g., `_ErrorText`, the `todayTransactionsProvider` watch).
- DO NOT change the bookId/year/month resolution logic.
- DO NOT add `AnalyticsRegion` enum or `initialRegion` parameter.
- DO NOT introduce new top-level constants or private helpers beyond the `_ErrorText` already present.
- DO NOT hardcode `'JPY'` anywhere except as the fallback in `currencyCode` resolution (with the `Pitfall #9 — fallback only when Book is missing` comment marker).
  </action>
  <verify>
    <automated>flutter analyze lib/features/home/presentation/screens/home_screen.dart 2>&1 | grep -q "No issues found"</automated>
  </verify>
  <acceptance_criteria>
    - `grep -q "import '../widgets/home_hero_card.dart';" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0
    - `grep -E "import .*month_overview_card|import .*ledger_comparison_section|import .*soul_fullness_card" lib/features/home/presentation/screens/home_screen.dart` returns NO matches (NO imports of the 3 widgets)
    - `grep -E "MonthOverviewCard\(|LedgerComparisonSection\(|SoulFullnessCard\(" lib/features/home/presentation/screens/home_screen.dart` returns NO matches (NO call sites of the 3 widgets — but helper bodies may still reference internal types like `LedgerRowData` until 10-08b)
    - `grep -q "HomeHeroCard(" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0
    - `grep -q "bookByIdProvider" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0
    - `grep -q "Pitfall #9\|fallback only when Book is missing" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (B4 strict guard — comment marker documents the legitimate `'JPY'` fallback)
    - `grep -c "'JPY'" lib/features/home/presentation/screens/home_screen.dart` returns exactly 1 (only the documented fallback)
    - `grep -q "AnalyticsScreen(bookId: bookId)" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0
    - `grep -q "AnalyticsRegion\|initialRegion" lib/features/home/presentation/screens/home_screen.dart` returns exit code 1 (NO match — Phase 11 introduces this enum)
    - `grep -q "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (helpers STILL exist as dead code; 10-08b deletes them — this asserts 10-08a did NOT touch them)
    - `flutter analyze lib/features/home/presentation/screens/home_screen.dart` reports "No issues found" (or only `unused_element` hints, which 10-08b resolves)
  </acceptance_criteria>
  <done>
home_screen.dart imports HomeHeroCard, renders one instance with the consolidated `.when()` chain, removes imports + call sites of the 3 obsolete widgets, navigates to AnalyticsScreen with `bookId` only (no enum), passes `flutter analyze`, AND retains the 3 dead-code helper bodies (deleted by 10-08b). Comment marker `Pitfall #9 — fallback only when Book is missing` documents the legitimate `'JPY'` literal.
  </done>
</task>

</tasks>

<verification>
- Grep guards pass:
  - `grep -E "MonthOverviewCard\(|LedgerComparisonSection\(|SoulFullnessCard\(" lib/features/home/presentation/screens/home_screen.dart` returns NO matches
  - `grep -q "Pitfall #9\|fallback only when Book is missing" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (B4)
  - `grep -q "_computeHappinessROI\|_computeSatisfaction\|_buildLedgerRows" lib/features/home/presentation/screens/home_screen.dart` returns exit code 0 (helpers still exist — 10-08b deletes them)
- `flutter analyze lib/features/home/` 0 issues (excepting `unused_element` hints on the 3 helpers, which 10-08b clears)
- Note: `home_screen_test.dart` will have failing assertions (uses old finders) — that's owned by Plan 10-10
</verification>

<success_criteria>
- HomePage renders 1 HomeHeroCard instead of 3 separate cards
- Currency code resolves from Book.currency, not hardcoded; B4 comment marker present
- Tap navigation works (will manual-verify with placeholder route to AnalyticsScreen)
- Old helper bodies remain (deleted by 10-08b) — splitting at this boundary is intentional per checker B3
- `flutter analyze` clean (modulo `unused_element` hints)
</success_criteria>

<output>
After completion, create `.planning/phases/10-homepage-soulfullnesscard-redesign/10-08a-SUMMARY.md` recording: pre/post line count, the new consolidated block line range, the imports diff, and confirmation that the 3 dead-code helpers are still present pending 10-08b.
</output>
