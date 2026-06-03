---
phase: 260603-stw
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/home/presentation/widgets/hero_header.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - lib/features/home/presentation/providers/state_home.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - test/features/home/presentation/widgets/home_header_test.dart
  - test/widget/features/home/presentation/widgets/hero_header_test.dart
autonomous: true
requirements: [BUG-STW]
must_haves:
  truths:
    - "When the displayed month equals the current real-world month (year+month), the right chevron is absent from the home HeroHeader — no Icons.chevron_right widget rendered"
    - "When the displayed month equals the current real-world month, the right chevron IconButton is absent from the ListScreen AppBar actions — no Icons.chevron_right widget rendered"
    - "Tapping the right chevron on any past month still advances the month normally on both screens"
    - "The left chevron and month label do not shift position when the right chevron is hidden (layout stable)"
    - "nextMonth() on HomeSelectedMonth.notifier clamps: calling it when already on the current month is a no-op (state unchanged)"
    - "All previously-passing tests pass; the two tests that unconditionally tapped chevron_right are updated to only tap it when on a past month"
  artifacts:
    - path: "lib/features/home/presentation/widgets/hero_header.dart"
      provides: "HeroHeader with showNextChevron bool param"
      contains: "showNextChevron"
    - path: "lib/features/home/presentation/screens/home_screen.dart"
      provides: "isCurrentMonth computation and showNextChevron wiring"
      contains: "isCurrentMonth"
    - path: "lib/features/home/presentation/providers/state_home.dart"
      provides: "nextMonth() clamp guard"
      contains: "clamp"
    - path: "lib/features/list/presentation/screens/list_screen.dart"
      provides: "AppBar right-chevron hidden when on current month"
      contains: "isCurrentMonth"
  key_links:
    - from: "lib/features/home/presentation/screens/home_screen.dart"
      to: "lib/features/home/presentation/widgets/hero_header.dart"
      via: "showNextChevron: !isCurrentMonth"
      pattern: "showNextChevron"
    - from: "lib/features/list/presentation/screens/list_screen.dart"
      to: "listFilterProvider"
      via: "isCurrentMonth guard on actions IconButton"
      pattern: "isCurrentMonth"
---

<objective>
Fix the "endDate must not be in the future" analytics crash by preventing forward month navigation when the displayed month is already the current real-world month. Apply on both the home dashboard (HeroHeader right chevron) and the list-tab AppBar right chevron. Add a belt-and-suspenders clamp in the HomeSelectedMonth notifier. Update the two widget tests that unconditionally tapped chevron_right.

Purpose: Users can currently tap the right arrow on the current month and land on a future month, causing analytics providers to throw because endDate exceeds DateTime.now().

Output: Modified hero_header.dart, home_screen.dart, state_home.dart, list_screen.dart, and two updated test files. No new files needed.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/Users/xinz/Development/home-pocket-app/CLAUDE.md
@/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/widgets/hero_header.dart
@/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/screens/home_screen.dart
@/Users/xinz/Development/home-pocket-app/lib/features/home/presentation/providers/state_home.dart
@/Users/xinz/Development/home-pocket-app/lib/features/list/presentation/screens/list_screen.dart
@/Users/xinz/Development/home-pocket-app/test/features/home/presentation/widgets/home_header_test.dart
@/Users/xinz/Development/home-pocket-app/test/widget/features/home/presentation/widgets/hero_header_test.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Add showNextChevron to HeroHeader and clamp nextMonth() in notifier</name>
  <files>
    lib/features/home/presentation/widgets/hero_header.dart
    lib/features/home/presentation/screens/home_screen.dart
    lib/features/home/presentation/providers/state_home.dart
    test/features/home/presentation/widgets/home_header_test.dart
    test/widget/features/home/presentation/widgets/hero_header_test.dart
  </files>
  <behavior>
    - HeroHeader with showNextChevron: false renders no Icons.chevron_right widget
    - HeroHeader with showNextChevron: true renders Icons.chevron_right and fires onNextMonth on tap
    - nextMonth() called when state equals current real-world year/month is a no-op (state unchanged)
    - nextMonth() called on a past month advances normally
  </behavior>
  <action>
    1. hero_header.dart — Add `final bool showNextChevron;` as a required named parameter to HeroHeader's constructor (between onPrevMonth and onNextMonth, or after onNextMonth). In the build() Row, replace the right IconButton unconditionally with:

       ```
       if showNextChevron → render IconButton(icon: Icon(Icons.chevron_right, ...), onPressed: onNextMonth)
       else → render SizedBox(width: 28, height: 28)  // same minWidth as the IconButton constraints
       ```

       Use `showNextChevron ? IconButton(...) : const SizedBox(width: 28, height: 28)` inline in the Row children list. The SizedBox dimensions match the existing `BoxConstraints(minWidth: 28, minHeight: 28)` to preserve layout stability. Keep all other code unchanged.

    2. home_screen.dart — In HomeScreen.build(), after reading `selectedMonth`, derive:

       ```dart
       final now = DateTime.now();
       final isCurrentMonth = year == now.year && month == now.month;
       ```

       Pass `showNextChevron: !isCurrentMonth` to the HeroHeader constructor (per D-STW-hide-next). Do NOT hardcode `false` — the bool must reflect live state.

    3. state_home.dart — In HomeSelectedMonth.nextMonth(), add a clamp guard before advancing:

       ```dart
       void nextMonth() {
         final now = DateTime.now();
         if (state.year == now.year && state.month == now.month) return; // clamp
         final d = DateTime(state.year, state.month + 1);
         selectMonth(d.year, d.month);
       }
       ```

       This is belt-and-suspenders: even if UI correctly hides the chevron, programmatic callers cannot advance past the current month.

    4. test/features/home/presentation/widgets/home_header_test.dart and
       test/widget/features/home/presentation/widgets/hero_header_test.dart —
       Both files contain a test that passes `onNextMonth: () => next = true` and then taps `find.byIcon(Icons.chevron_right)` on a past month (year: 2026, month: 2 or 3 — both are past relative to current date 2026-06). These tests pass `showNextChevron` as required. Update all HeroHeader constructor calls to add `showNextChevron: true` (for past-month tests) or `showNextChevron: false` (for any new current-month test). Since all existing test cases use month: 2 or month: 3 (past months), pass `showNextChevron: true` for all existing calls. Add one new test case:

       ```
       testWidgets('right chevron absent when showNextChevron is false', (tester) async {
         await tester.pumpWidget(buildTestWidget(year: <nowYear>, month: <nowMonth>,
           showNextChevron: false, onSettingsTap: () {}));
         expect(find.byIcon(Icons.chevron_right), findsNothing);
       });
       ```

       Use the actual current year/month (2026, 6) as the concrete values or parameterize via DateTime.now() in the test body.

    Note on CLAUDE.md immutability: HeroHeader is a StatelessWidget (no mutation). Notifier state record is replaced via assignment (not mutated), consistent with Riverpod 3 keepAlive notifier pattern.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter test test/features/home/presentation/widgets/home_header_test.dart test/widget/features/home/presentation/widgets/hero_header_test.dart --reporter=compact</automated>
  </verify>
  <done>
    Both hero_header test files pass. HeroHeader renders no chevron_right icon when showNextChevron is false. flutter analyze reports 0 new issues.
  </done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: Hide right chevron in ListScreen AppBar when on current month</name>
  <files>
    lib/features/list/presentation/screens/list_screen.dart
    test/widget/features/list/list_screen_refresh_test.dart
  </files>
  <behavior>
    - ListScreen AppBar renders no Icons.chevron_right action when listFilterProvider's selected month equals the current real-world year/month
    - ListScreen AppBar renders Icons.chevron_right when selected month is a past month
    - Advancing forward from a past month via the right chevron calls listFilterProvider.notifier.selectMonth() normally
  </behavior>
  <action>
    In ListScreen.build(), after `final filter = ref.watch(listFilterProvider);`, derive:

    ```dart
    final now = DateTime.now();
    final isCurrentMonth = filter.selectedYear == now.year && filter.selectedMonth == now.month;
    ```

    In the AppBar `actions:` list, replace the unconditional IconButton with a conditional:

    ```dart
    actions: [
      if (!isCurrentMonth)
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: S.of(context).listCalNavNext,
          onPressed: () {
            final next = DateTime(
              filter.selectedYear,
              filter.selectedMonth + 1,
            );
            ref.read(listFilterProvider.notifier).selectMonth(next.year, next.month);
          },
        ),
    ],
    ```

    The `if (!isCurrentMonth)` collection-if inside the list is idiomatic Flutter/Dart — no ternary with SizedBox needed because AppBar actions omitting the button causes no layout shift (actions is a flex row that shrinks). Keep the leading chevron_left and title GestureDetector completely unchanged.

    In test/widget/features/list/list_screen_refresh_test.dart: search for any `find.byIcon(Icons.chevron_right)` tap that does not guard on the current month. If found, update the test to either (a) use a past month via `listFilterProvider` override, or (b) assert the chevron is absent when on the current month. The test file currently has no chevron_right assertion (confirmed by grep), so no change is needed there unless discovered during implementation.

    No new unit tests are needed for the notifier since ListFilter.selectMonth() is already tested in list_filter_notifier_test.dart — the guard is in the UI layer (conditional render), not in the notifier.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter test test/widget/features/list/ --reporter=compact</automated>
  </verify>
  <done>
    ListScreen compiles. When filter.selectedYear/Month equals DateTime.now() year/month, no Icons.chevron_right icon is present in the AppBar. All list widget tests pass. flutter analyze 0 new issues.
  </done>
</task>

<task type="auto">
  <name>Task 3: Full test suite + analyze verification</name>
  <files/>
  <action>
    Run the full test suite and analyzer to confirm no regressions. Pay attention to any test that was previously finding chevron_right icons — those are the two hero_header test files updated in Task 1.

    Steps:
    1. `flutter analyze` — must report 0 issues
    2. `flutter test --reporter=compact` — all tests must pass

    If any golden test fails (e.g., list_calendar_header_golden_test.dart), re-baseline with:
    `flutter test --update-goldens test/golden/<failing_file>.dart`

    Note: The golden tests for list_calendar_header do NOT include the AppBar (CalendarHeaderWidget is pumped standalone without ListScreen), so no golden re-baseline is expected. The golden tests for home hero card also do not include HeroHeader. No goldens should need re-baselining from this change — confirm by running the full suite first before updating any goldens.
  </action>
  <verify>
    <automated>cd /Users/xinz/Development/home-pocket-app && flutter analyze && flutter test --reporter=compact</automated>
  </verify>
  <done>
    `flutter analyze` exits with 0 issues. `flutter test` exits with all tests passing (0 failures). If any golden needed re-baselining, the updated .png files are committed.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| UI → Riverpod state | Chevron tap triggers state mutation; clamped in notifier |
| DateTime.now() → month guard | System clock is trusted; no sanitization needed |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation Plan |
|-----------|----------|-----------|-------------|-----------------|
| T-STW-01 | Tampering | HomeSelectedMonth.nextMonth() | mitigate | Clamp guard added: returns early if already at current month |
| T-STW-02 | Elevation of Privilege | UI chevron bypass | mitigate | UI hide is belt-and-suspenders layered with notifier clamp; no single point of failure |
| T-STW-03 | Denial of Service | analytics endDate future error | mitigate | Root cause removed: UI cannot advance to future month |
</threat_model>

<verification>
- `flutter analyze` exits 0
- `flutter test` exits 0 failures
- Manual smoke: On device/simulator with current month (2026-06), home screen HeroHeader shows no right chevron. Navigate to list tab — AppBar shows no right chevron. Navigate to May (2026-05) in either screen — right chevron appears and tapping it returns to June; right chevron disappears again.
</verification>

<success_criteria>
- No red error text ("endDate must not be in the future") can appear on the home or list screen by tapping UI affordances
- HeroHeader accepts and honors showNextChevron: bool
- HomeSelectedMonth.nextMonth() is idempotent when on current month
- ListScreen AppBar hides the right chevron when on current month
- All automated tests pass
</success_criteria>

<output>
Create `.planning/quick/260603-stw-analytics-enddate-must-not-be-in-the-fut/260603-stw-SUMMARY.md` when done
</output>
