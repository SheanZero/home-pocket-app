---
phase: quick-260607-jrz
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/home/presentation/widgets/month_picker_dialog.dart
  - lib/features/home/presentation/widgets/hero_header.dart
  - lib/features/home/presentation/screens/home_screen.dart
  - test/widget/features/home/presentation/widgets/hero_header_test.dart
  - test/features/home/presentation/widgets/home_header_test.dart
  - test/widget/features/home/presentation/widgets/month_picker_dialog_test.dart
autonomous: true
requirements: [QUICK-260607-JRZ]

must_haves:
  truths:
    - "Tapping the home month label + down-chevron opens a centered month-grid dialog (D: 箭头去留)"
    - "The home header no longer renders left/right month-navigation chevrons (D: 箭头去留)"
    - "Selecting a non-future month in the dialog updates homeSelectedMonthProvider and closes the dialog (D: 未来月份处理)"
    - "Future months are greyed and non-tappable; the year-nav next arrow is disabled at the current year (D: 未来月份处理)"
    - "All dialog/header colors resolve via context.palette and all text via S.of(context) (D: 视觉/主题, i18n)"
  artifacts:
    - path: "lib/features/home/presentation/widgets/month_picker_dialog.dart"
      provides: "Centered rounded-card month-grid picker dialog (year nav + 3x4 grid)"
      min_lines: 80
    - path: "lib/features/home/presentation/widgets/hero_header.dart"
      provides: "Header with tappable month label + down-chevron, no nav chevrons"
  key_links:
    - from: "lib/features/home/presentation/screens/home_screen.dart"
      to: "month_picker_dialog.dart + homeSelectedMonthProvider"
      via: "onMonthTap opens dialog; dialog calls selectMonth"
      pattern: "showMonthPickerDialog|homeSelectedMonthProvider.notifier.selectMonth"
---

<objective>
Replace the home header's left/right month-step chevrons with a tap-to-open month-grid
picker dialog. Tapping the month label (now followed by a downward `⌄` affordance) opens
a centered rounded card containing a year navigator (`‹ YYYY年 ›`) and a 3×4 grid of
months. The current selection is highlighted with a neutral pill; future months and the
future-year nav arrow are disabled. Picking a month calls
`homeSelectedMonthProvider.notifier.selectMonth(year, month)` and closes the dialog.

Purpose: Faster month jumps (especially across many months) than one-tap-per-month chevrons.
Output: New `month_picker_dialog.dart`, modified `hero_header.dart` + `home_screen.dart`,
updated/added widget tests.

Implements user-locked decisions in 260607-jrz-CONTEXT.md (箭头去留 / 未来月份处理 / 视觉主题 / i18n).
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/quick/260607-jrz-month-picker-dialog/260607-jrz-CONTEXT.md
@CLAUDE.md
@lib/features/home/presentation/widgets/hero_header.dart
@lib/features/home/presentation/screens/home_screen.dart
@lib/features/home/presentation/providers/state_home.dart
@lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart

Key facts confirmed during planning (executor: do NOT re-research these):
- ARB key `homeMonthLabel` ALREADY EXISTS in all three ARB files: ja/zh `"{month}月"`, en `"M{month}"`.
  Use `l10n.homeMonthLabel(month)` for grid cell text. NO new ARB keys are required, so NO
  `flutter gen-l10n` run is needed unless you choose to change this label.
- Year label uses existing `homeMonthFormat` only for the header; for the dialog year title use a
  plain `'$year年'`-style string ONLY IF a localized year key exists — otherwise add a small ARB key.
  Prefer reusing an existing localized year form. Check `grep -n '"home.*[Yy]ear\|yearLabel\|analyticsTimeWindowChipLabelYear' lib/l10n/app_ja.arb`
  before inventing a key. `analyticsTimeWindowChipLabelYear` exists (`"{year}年"` ja/zh, `"{year}"` en) — reuse it.
- Palette tokens available (verified in lib/core/theme/app_palette.dart): `backgroundMuted`,
  `backgroundSubtle`, `accentPrimary`, `accentPrimaryLight`, `textPrimary`, `textSecondary`,
  `textTertiary`, `borderDefault`, `background`. Use `backgroundMuted` (or `backgroundSubtle`)
  for the selected-month neutral pill; `accentPrimary` for the year nav title/arrows;
  `textTertiary`/`textSecondary` for disabled future months.
- `homeSelectedMonthProvider` is the provider name (Notifier suffix stripped). Notifier method:
  `selectMonth(int year, int month)`. `nextMonth()` already clamps to the current real-world month.
- hero_header.dart is a PURE StatelessWidget (no providers). KEEP IT PURE: it takes an
  `onMonthTap` callback. Provider reads + dialog launch happen in home_screen.dart.
- There are TWO header test files that reference the OLD API (onPrevMonth/onNextMonth/
  showNextChevron/chevron_left/chevron_right) and WILL break:
  `test/widget/features/home/presentation/widgets/hero_header_test.dart` and
  `test/features/home/presentation/widgets/home_header_test.dart`. Both must be updated.
- No hero_header golden masters exist (only `home_hero_card_*` goldens, which are unaffected).
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Build the month-grid picker dialog widget</name>
  <files>
    lib/features/home/presentation/widgets/month_picker_dialog.dart
    test/widget/features/home/presentation/widgets/month_picker_dialog_test.dart
  </files>
  <behavior>
    - Renders a 3×4 grid of 12 month cells, labelled via `l10n.homeMonthLabel(month)`.
    - Year nav row shows the localized year (`l10n.analyticsTimeWindowChipLabelYear`) with `‹`/`›` arrows in accentPrimary.
    - The selected (year, month) cell shows a neutral pill (palette `backgroundMuted`/`backgroundSubtle`).
    - When the displayed year == current real year, months after the current real month are disabled (greyed via textTertiary, not tappable) and the `›` next-year arrow is disabled.
    - The `‹` previous-year arrow is always enabled.
    - Tapping an enabled month cell pops the dialog returning `(year: int, month: int)`.
  </behavior>
  <action>
    Create `month_picker_dialog.dart` implementing the centered rounded-card month picker per
    CONTEXT.md decisions (D: 视觉/主题, 未来月份处理). Provide a top-level helper
    `Future<({int year, int month})?> showMonthPickerDialog(BuildContext context, {required int selectedYear, required int selectedMonth})`
    that wraps `showDialog<({int year, int month})>` with a `Dialog`/`AlertDialog`-style centered
    rounded card (`shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))`,
    `backgroundColor: context.palette.background`).

    Internals: use a private `StatefulWidget` holding the currently-displayed year (init from
    `selectedYear`). Layout:
    1. Year nav `Row`: `IconButton(Icons.chevron_left)` (always enabled, decrements displayed year),
       centered `Text(l10n.analyticsTimeWindowChipLabelYear(displayYear.toString()))` styled with
       `AppTextStyles.titleSmall`/`titleMedium` + `color: context.palette.accentPrimary`,
       `IconButton(Icons.chevron_right)` enabled ONLY when `displayYear < now.year` (pass
       `onPressed: null` to disable; tint disabled arrow with `context.palette.textTertiary`).
    2. Month grid: `GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: NeverScrollableScrollPhysics())`
       with 12 cells for months 1..12. For each month compute `isFuture = displayYear == now.year && month > now.month`.
       A cell is selected when `displayYear == selectedYear && month == selectedMonth`. Render each cell
       as a tappable rounded container: selected → pill bg `context.palette.backgroundMuted` (or backgroundSubtle)
       with `textPrimary` text; future → `textTertiary` text, no ink, `onTap: null`; normal → transparent bg,
       `textPrimary` text, tappable. On enabled tap: `Navigator.of(context).pop((year: displayYear, month: month))`.

    Colors MUST come from `context.palette` (ADR-019) — NO hardcoded hex (D: 视觉/主题). All text MUST
    go through `S.of(context)` (D: i18n). Import `app_palette.dart` (for the `context.palette` extension),
    `app_text_styles.dart`, and `generated/app_localizations.dart`. Keep the widget a pure UI widget
    (no provider reads inside the dialog — it returns the chosen month to the caller).

    Do NOT inline an arrow glyph string; use `Icons.chevron_left`/`Icons.chevron_right` for year nav
    to match the existing chevron style and ensure findable test handles.
  </action>
  <verify>
    <automated>flutter test test/widget/features/home/presentation/widgets/month_picker_dialog_test.dart</automated>
  </verify>
  <done>
    Dialog test (RED→GREEN) passes: asserts 12 month cells render, the current real month's future
    siblings are disabled in the current year, `‹` always present and `›` disabled at current year,
    and tapping an enabled month pops with the expected `(year, month)` record. Write the test FIRST
    (it should fail before the widget exists), then implement until green.
  </done>
</task>

<task type="auto">
  <name>Task 2: Rewire hero_header (tappable label + ⌄, drop nav chevrons) and home_screen wiring</name>
  <files>
    lib/features/home/presentation/widgets/hero_header.dart
    lib/features/home/presentation/screens/home_screen.dart
  </files>
  <action>
    Edit `hero_header.dart` (D: 箭头去留): REMOVE the `onPrevMonth`, `onNextMonth`, and
    `showNextChevron` constructor params/fields and the two chevron `IconButton`s + the
    `Transform.translate` wrapper + the trailing `SizedBox(width:28)` placeholder. ADD a required
    `VoidCallback onMonthTap` param. Wrap the month-label `Text` and a trailing
    `Icon(Icons.keyboard_arrow_down, size: 20, color: context.palette.textSecondary)` in a single
    `GestureDetector`/`InkWell` `Row(mainAxisSize: MainAxisSize.min, ...)` whose `onTap: onMonthTap`.
    Keep the existing month-label text style (headlineSmall, w500, textPrimary). The header should now
    start with this tappable label group on the left (no leading chevron), then `Spacer`, mode badge,
    settings icon — preserve the rest unchanged. Update the class doc comment to describe the new
    tap-to-open behavior. NOTE the down-arrow uses `Icons.keyboard_arrow_down` — the old tests asserted
    this icon is ABSENT, so Task 3 updates those expectations.

    Edit `home_screen.dart` (D: 箭头去留): in the `HeroHeader(...)` call (~line 74) remove
    `onPrevMonth`/`onNextMonth`/`showNextChevron` args and add
    `onMonthTap: () async { final picked = await showMonthPickerDialog(context, selectedYear: year, selectedMonth: month); if (picked != null) { ref.read(homeSelectedMonthProvider.notifier).selectMonth(picked.year, picked.month); } }`.
    Add the import for `../widgets/month_picker_dialog.dart`. The `isCurrentMonth`/`now` locals that
    were only used for `showNextChevron` may now be unused — remove them if `flutter analyze` flags them
    (do NOT leave unused locals; CLAUDE.md requires 0 analyzer issues). Guard the async gap with
    `if (!context.mounted) return;` after the await before using `ref`/`context` if analyzer/lint requires it.
  </action>
  <verify>
    <automated>flutter analyze lib/features/home/presentation/widgets/hero_header.dart lib/features/home/presentation/screens/home_screen.dart</automated>
  </verify>
  <done>
    hero_header.dart exposes `onMonthTap` and no longer references prev/next/showNextChevron or
    chevron_left/right icons. home_screen.dart opens the dialog on tap and writes the result via
    `selectMonth`. `flutter analyze` reports 0 issues for both files (no unused locals/imports).
  </done>
</task>

<task type="auto">
  <name>Task 3: Update header widget tests for the new API and run full home suite</name>
  <files>
    test/widget/features/home/presentation/widgets/hero_header_test.dart
    test/features/home/presentation/widgets/home_header_test.dart
  </files>
  <action>
    Both header test files use the OLD `HeroHeader` API and WILL fail to compile. Update both:
    - Replace `onPrevMonth`/`onNextMonth`/`showNextChevron` constructor args with `onMonthTap: () {}`
      (or a capturing callback where the test asserts the tap).
    - DELETE the chevron-based tests ("prev/next chevrons switch months", "right chevron absent when
      showNextChevron is false", "HomeHeader prev/next chevrons fire callbacks", "HomeHeader hides
      right chevron ...").
    - UPDATE the "no dropdown arrow" tests: the down-chevron affordance is now PRESENT. Change them to
      assert `find.byIcon(Icons.keyboard_arrow_down)` `findsOneWidget`, and add a test that tapping the
      month-label region (e.g. `tester.tap(find.text('2026年2月'))` or tap the down icon) fires `onMonthTap`.
    - KEEP the year/month display, settings-icon, and family/personal badge tests (adjust constructor
      args only).
    Do NOT change production behavior to satisfy stale assertions — fix the tests to match the new,
    intended API (CLAUDE.md: tests are first-class; fix tests when the contract intentionally changed).
  </action>
  <verify>
    <automated>flutter analyze && flutter test test/widget/features/home/ test/features/home/</automated>
  </verify>
  <done>
    `flutter analyze` = 0 issues. `flutter test` for the home widget + feature test dirs passes
    (including the new month_picker_dialog_test). If any home golden master legitimately changed due to
    the header layout (none expected — no hero_header goldens exist), re-baseline with
    `flutter test --update-goldens <path>` and note the intentional change in the SUMMARY; otherwise do
    NOT touch goldens.
  </done>
</task>

</tasks>

<verification>
- `flutter analyze` reports 0 issues across the whole project.
- `flutter test test/widget/features/home/ test/features/home/` passes.
- Manual/behavioral: tapping the home month label opens the centered grid dialog; future months and
  the future-year `›` are disabled; picking a past/current month updates the dashboard and closes the dialog.
- No hardcoded hex in `month_picker_dialog.dart` or the edited `hero_header.dart`:
  `grep -nE "0xFF|Color\(0x|#[0-9A-Fa-f]{6}" lib/features/home/presentation/widgets/month_picker_dialog.dart lib/features/home/presentation/widgets/hero_header.dart | grep -v '^#' | wc -l` returns 0.
- No hardcoded UI strings: grid/year text all go through `l10n.*` / `S.of(context)`.
</verification>

<success_criteria>
- Home header has NO left/right month chevrons; month label + `⌄` is a single tap target.
- Tapping opens a centered rounded-card dialog: `‹ YYYY年 ›` year nav (accent) + 3×4 month grid,
  selected month as a neutral pill, future months/year disabled.
- Selecting a month calls `homeSelectedMonthProvider.notifier.selectMonth` and closes the dialog.
- All colors via `context.palette`; all text via `S.of(context)`; `flutter analyze` = 0; tests green.
</success_criteria>

<output>
Create `.planning/quick/260607-jrz-month-picker-dialog/260607-jrz-SUMMARY.md` when done.
Per project rules, also write a worklog entry to `docs/worklog/YYYYMMDD_HHMM_home_month_picker_dialog.md`.
</output>
