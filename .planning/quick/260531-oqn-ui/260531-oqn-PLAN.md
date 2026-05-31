---
phase: 260531-oqn-ui
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/list/presentation/widgets/list_calendar_header.dart
  - lib/features/list/presentation/screens/list_screen.dart
  - lib/features/settings/domain/models/app_settings.dart
  - lib/features/settings/domain/repositories/settings_repository.dart
  - lib/data/repositories/settings_repository_impl.dart
  - lib/features/settings/presentation/providers/state_settings.dart
  - lib/features/settings/presentation/widgets/appearance_section.dart
  - lib/shared/constants/sort_config.dart
  - lib/features/list/domain/models/list_sort_config.dart
  - lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  - lib/features/list/presentation/widgets/list_transaction_tile.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
autonomous: true
requirements: []

must_haves:
  truths:
    - "ListScreen has a Material AppBar (consistent with analytics) whose title shows the current month and supports prev/next month navigation; the standalone month-nav bar is removed."
    - "Empty-amount calendar cells have a placeholder SizedBox matching the amount text height so numerals align vertically across all cells in a row"
    - "Calendar week-start day is configurable (default Monday) and persisted via SharedPreferences; the setting appears in the Appearance section of Settings"
    - "Calendar header respects the weekStartDay setting for both the day-of-week header row and cell positioning"
    - "Saturday date numerals are blue; Sunday date numerals are black; determination is by weekday (not column position)"
    - "Sort options contain only Date and Amount — updatedAt is removed from SortField, default sort is timestamp-desc"
    - "ListTransactionTile left primary: L1 category icon + L2 category name (+ satisfaction emoji for soul); left secondary: ledger type label optionally followed by merchant name; right: amount only — no time label"
    - "All new UI text uses S.of(context); amounts use NumberFormatter + AppTextStyles.amountSmall; all 3 ARB files updated for any new keys"
    - "flutter analyze reports 0 issues"
    - "All affected golden tests re-baselined after layout changes"
  artifacts:
    - path: lib/features/list/presentation/screens/list_screen.dart
      provides: "Scaffold + AppBar with current-month title and prev/next month navigation"
    - path: lib/features/list/presentation/widgets/list_calendar_header.dart
      provides: "_MonthNavBar removed; empty-cell SizedBox placeholder + weekday color logic + startingDay reads provider"
    - path: lib/features/settings/domain/models/app_settings.dart
      provides: "weekStartDay field (enum WeekStartDay: monday, sunday)"
    - path: lib/data/repositories/settings_repository_impl.dart
      provides: "getWeekStartDay / setWeekStartDay SharedPreferences persistence"
    - path: lib/shared/constants/sort_config.dart
      provides: "SortField enum with only timestamp and amount"
    - path: lib/features/list/presentation/widgets/list_transaction_tile.dart
      provides: "rebuilt tile: L1 icon + L2 name + optional emoji | ledger tag + optional merchant | amount"
  key_links:
    - from: lib/features/list/presentation/screens/list_screen.dart
      to: lib/features/list/presentation/providers/state_list_filter.dart
      via: "AppBar month title reads listFilterProvider; chevrons call listFilterProvider.notifier.selectMonth"
      pattern: "listFilterProvider"
    - from: lib/features/list/presentation/widgets/list_calendar_header.dart
      to: lib/features/settings/presentation/providers/state_settings.dart
      via: "ref.watch(appSettingsProvider) to read weekStartDay"
      pattern: "appSettingsProvider"
    - from: lib/features/list/presentation/screens/list_screen.dart
      to: lib/features/list/presentation/widgets/list_transaction_tile.dart
      via: "passes L1 category and merchant fields after tile contract change"
      pattern: "ListTransactionTile"
    - from: lib/features/list/presentation/widgets/list_sort_filter_bar.dart
      to: lib/shared/constants/sort_config.dart
      via: "SortField.values.map in _showSortMenu"
      pattern: "SortField.values"
---

<objective>
Six UI changes to the List/Calendar screen: (1) give ListScreen a Material AppBar consistent with the analytics screen, with the current month as the AppBar title and prev/next month navigation in the AppBar; remove the standalone month-nav bar (resolves both the missing month label and the flush-to-status-bar spacing), (2) add placeholder spacer to empty-amount calendar cells for vertical numeral alignment, (3) persisted weekStartDay setting (default Monday) wired into the calendar, (4) Saturday = blue / Sunday = black numeral colors by true weekday, (5) remove updatedAt from sort options leaving only Date and Amount, (6) rebuild ListTransactionTile layout: L1 icon + L2 name + optional satisfaction emoji as primary; ledger type + optional merchant as secondary; amount-only trailing; no time label.

Purpose: Polish the List tab to match product spec. Items 3+4 are coupled (both touch the day-cell render path). Item 5 is a model break (SortField enum change requires build_runner). Item 6 is a tile contract change that propagates to the ListScreen caller.

Output: Updated widgets + settings model + ARB files + re-baselined goldens.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@lib/features/list/presentation/screens/list_screen.dart
@lib/features/list/presentation/widgets/list_calendar_header.dart
@lib/features/list/presentation/widgets/list_sort_filter_bar.dart
@lib/features/list/presentation/widgets/list_transaction_tile.dart
@lib/features/list/domain/models/list_sort_config.dart
@lib/shared/constants/sort_config.dart
@lib/features/settings/domain/models/app_settings.dart
@lib/features/settings/domain/repositories/settings_repository.dart
@lib/data/repositories/settings_repository_impl.dart
@lib/features/settings/presentation/providers/state_settings.dart
@lib/features/settings/presentation/widgets/appearance_section.dart
@lib/features/accounting/domain/models/category.dart
@lib/features/accounting/presentation/utils/category_display_utils.dart
@lib/application/accounting/category_localization_service.dart
@lib/core/theme/app_colors.dart
@lib/features/analytics/presentation/screens/analytics_screen.dart
</context>

<tasks>

<task type="auto">
  <name>Task 1: ListScreen AppBar with month title + empty-cell vertical alignment</name>
  <files>
    lib/features/list/presentation/screens/list_screen.dart
    lib/features/list/presentation/widgets/list_calendar_header.dart
  </files>
  <action>
DECISION (user): "加 AppBar，月份放标题" — give ListScreen a Material AppBar consistent with the analytics screen, with the current month as the AppBar title. Remove the standalone month-nav bar. This resolves both "头部没有月份显示" and "顶的太高了" (the bare Column had no status-bar clearance).

(1a) APPBAR — lib/features/list/presentation/screens/list_screen.dart

ListScreen.build currently returns a bare `Column` (CalendarHeaderWidget + ListSortFilterBar + Expanded(list)). The analytics screen instead returns its OWN `Scaffold` + `AppBar(title: Text(l10n.analyticsTitle), actions: [...])` — that AppBar handles SafeArea/status-bar clearance, which is why analytics looks correctly spaced and ListScreen does not.

Make ListScreen do the same:
- Wrap the existing Column body in a `Scaffold` with an `AppBar`. The Column stays exactly as-is (CalendarHeaderWidget → ListSortFilterBar → Expanded(_buildList)) as the Scaffold `body`.
- `filter` is already read at the top of build via `ref.watch(listFilterProvider)` (current line 40) and `locale` is already resolved (current lines 36-37). Reuse both for the AppBar title.
- AppBar configuration:
  - `centerTitle: true` (match the centered month look the old _MonthNavBar produced).
  - `title`: a tappable month label. Build it as:
      GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final now = DateTime.now();
          ref.read(listFilterProvider.notifier).selectMonth(now.year, now.month);
        },
        child: Text(
          DateFormatter.formatMonthYear(
            DateTime(filter.selectedYear, filter.selectedMonth),
            locale,
          ),
        ),
      )
    This is the SAME formatMonthYear call + the SAME onLabelTap (jump-to-current-month) behavior currently in _MonthNavBar.
  - `leading`: previous-month chevron —
      IconButton(
        icon: const Icon(Icons.chevron_left),
        tooltip: S.of(context).listCalNavPrev,
        onPressed: () {
          final prev = DateTime(filter.selectedYear, filter.selectedMonth - 1);
          ref.read(listFilterProvider.notifier).selectMonth(prev.year, prev.month);
        },
      )
  - `actions`: next-month chevron —
      IconButton(
        icon: const Icon(Icons.chevron_right),
        tooltip: S.of(context).listCalNavNext,
        onPressed: () {
          final next = DateTime(filter.selectedYear, filter.selectedMonth + 1);
          ref.read(listFilterProvider.notifier).selectMonth(next.year, next.month);
        },
      )
    These prev/next computations are identical to the onPrevMonth/onNextMonth callbacks currently passed into _MonthNavBar (list_calendar_header.dart lines 60-72).

Imports to add in list_screen.dart:
- `DateFormatter` from `lib/infrastructure/i18n/formatters/date_formatter.dart` (used for the title; not currently imported here).
- `S` (app_localizations) is already imported. `listFilterProvider` is already imported. `currentLocaleProvider` (state_locale) is already imported.

Architecture note (1d): no import-guard violation — the list feature already reads `listFilterProvider` (same feature). Use `ref.watch(listFilterProvider)` (already present) and `ref.read(listFilterProvider.notifier).selectMonth(...)`.

(1b) REMOVE _MonthNavBar — lib/features/list/presentation/widgets/list_calendar_header.dart

The month label + prev/next chevrons now live in the AppBar. In CalendarHeaderWidget.build, the Column currently starts with `_MonthNavBar(...)` (lines 58-79) followed by TableCalendar and _SummaryRow.
- Remove the `_MonthNavBar(...)` child (and its callbacks block) from the Column. The Column now starts directly with `TableCalendar`, still reading `filter` for `focusedDay` and the totals providers, and still rendering `_SummaryRow` below.
- Delete the entire `_MonthNavBar` class (lines ~201-269) since it is no longer referenced.
- Leave `_SummaryRow`, `_dayKey`, `_buildDayCell`, `_onDayTapped`, `_startingDay` untouched in THIS task (Task 2 owns _startingDay/_buildDayCell color + weekStart changes).
- After deletion, check for now-unused imports in list_calendar_header.dart: `DateFormatter` was used by _MonthNavBar's title — but it is ALSO used by _SummaryRow (formatShortMonthDay) so the import stays. Do NOT remove the DateFormatter import. Run flutter analyze to catch any genuinely-unused import and remove only those flagged.

(1c) EMPTY-CELL PLACEHOLDER (item 2, unchanged from original spec) — lib/features/list/presentation/widgets/list_calendar_header.dart

In _buildDayCell, the amount Text is currently rendered only when `dayTotal > 0 && !isOutside`. When there is no amount, nothing occupies that vertical slot, so day numerals sit at different heights depending on whether a sibling cell in the same row has an amount label. Fix — replace the conditional amount Text with an always-rendered slot:

Current (approximately):
  if (dayTotal > 0 && !isOutside)
    Text(NumberFormatter.formatCompact(dayTotal, locale), ...)

New:
  if (dayTotal > 0 && !isOutside)
    Text(NumberFormatter.formatCompact(dayTotal, locale),
         style: AppTextStyles.micro.copyWith(color: amountColor))
  else
    const SizedBox(height: 14)  // matches AppTextStyles.micro line height (~14dp)

14dp matches the micro text style height (fontSize ~10, lineHeight ~1.4 → ~14dp), keeping the cell Column height identical regardless of whether an amount is present.
  </action>
  <verify>
    <automated>flutter analyze lib/features/list/presentation/screens/list_screen.dart lib/features/list/presentation/widgets/list_calendar_header.dart && flutter test test/golden/list_calendar_header_golden_test.dart --update-goldens && flutter test test/golden/list_calendar_header_golden_test.dart && flutter test test/widget/features/list/presentation/widgets/list_calendar_header_test.dart test/widget/features/list/list_screen_refresh_test.dart</automated>
  </verify>
  <done>
flutter analyze 0 issues. ListScreen renders a Scaffold + AppBar with the current month centered as title (tappable → jump to current month), chevron_left leading = prev month, chevron_right action = next month. _MonthNavBar removed from CalendarHeaderWidget and its class deleted; the calendar header Column starts at TableCalendar. Empty calendar cells carry a SizedBox(height: 14) placeholder so all numerals in a row align.

Test impact to handle in this task:
- test/widget/features/list/presentation/widgets/list_calendar_header_test.dart "SC#1: right chevron tap advances selectedMonth by 1" taps `find.byIcon(Icons.chevron_right)` INSIDE CalendarHeaderWidget — the chevron has moved to the AppBar, so this widget test (which pumps CalendarHeaderWidget without an AppBar) no longer has a chevron. Update that test: either (preferred) move the SC#1 month-navigation assertion to a ListScreen-level test that pumps the full ListScreen and taps the AppBar chevron, OR delete SC#1 from this widget test and rely on the ListScreen test for month-nav coverage. SC#3 (day select) and SC#4 (summary total) remain valid and untouched.
- list_calendar_header golden baselines re-generated (header no longer contains the nav bar).
- Re-run list_screen_refresh_test.dart to confirm the Scaffold/AppBar wrap did not break the RefreshIndicator pull-to-refresh assertions; adjust the test's expected widget tree only if the AppBar wrap shifts a finder (the RefreshIndicator + list are now under Scaffold.body — finders by type/key should still resolve).
  </done>
</task>

<task type="auto">
  <name>Task 2: Week-start setting + weekend cell colors</name>
  <files>
    lib/features/settings/domain/models/app_settings.dart
    lib/features/settings/domain/models/app_settings.freezed.dart
    lib/features/settings/domain/models/app_settings.g.dart
    lib/features/settings/domain/repositories/settings_repository.dart
    lib/data/repositories/settings_repository_impl.dart
    lib/features/settings/presentation/providers/state_settings.dart
    lib/features/settings/presentation/widgets/appearance_section.dart
    lib/features/list/presentation/widgets/list_calendar_header.dart
    lib/l10n/app_ja.arb
    lib/l10n/app_zh.arb
    lib/l10n/app_en.arb
  </files>
  <action>
STEP A — Domain model: add WeekStartDay enum and field to AppSettings.

In lib/features/settings/domain/models/app_settings.dart:

1. Add before AppSettings class (domain layer, no Flutter import needed):
   enum WeekStartDay { monday, sunday }

2. In the AppSettings freezed factory, add:
   @Default(WeekStartDay.monday) WeekStartDay weekStartDay,

3. In AppSettings.fromJson — no manual change needed; freezed generates this.

Run build_runner after this step to regenerate app_settings.freezed.dart and app_settings.g.dart.

STEP B — Repository interface: add getter + setter.

In lib/features/settings/domain/repositories/settings_repository.dart:
  Future<WeekStartDay> getWeekStartDay();
  Future<void> setWeekStartDay(WeekStartDay day);

(Import app_settings.dart for WeekStartDay.)

STEP C — Repository implementation.

In lib/data/repositories/settings_repository_impl.dart:
  static const String _weekStartDayKey = 'week_start_day';

  @override
  Future<WeekStartDay> getWeekStartDay() async {
    final v = _prefs.getString(_weekStartDayKey);
    return WeekStartDay.values.firstWhere(
      (d) => d.name == v,
      orElse: () => WeekStartDay.monday,
    );
  }

  @override
  Future<void> setWeekStartDay(WeekStartDay day) async {
    await _prefs.setString(_weekStartDayKey, day.name);
  }

Also update getSettings() to read weekStartDay:
  weekStartDay: await getWeekStartDay(),
  // Note: await is needed because getWeekStartDay is async but internally sync
  // via _prefs — simplify by making _getWeekStartDay() a sync private helper
  // identical to _getThemeMode() pattern, and call synchronously from getSettings.

Use the synchronous pattern matching _getThemeMode():
  Add _getWeekStartDay() private sync helper (reads _prefs.getString, returns WeekStartDay).
  Call it in getSettings() without await: weekStartDay: _getWeekStartDay().
  The public async getWeekStartDay() delegates to _getWeekStartDay().

Also update updateSettings() to include:
  await _prefs.setString(_weekStartDayKey, settings.weekStartDay.name);

STEP D — Settings UI: add weekStartDay picker in AppearanceSection.

In lib/features/settings/presentation/widgets/appearance_section.dart:

Add a ListTile below the language tile that shows the current weekStartDay and opens a dialog to toggle between Monday and Sunday. Use S.of(context) strings (see ARB step). Pattern matches the existing _showThemeModeDialog approach:

  ListTile(
    leading: const Icon(Icons.calendar_today),
    title: Text(S.of(context).settingsWeekStart),
    subtitle: Text(_weekStartLabel(settings.weekStartDay, context)),
    onTap: () => _showWeekStartDialog(context, ref, settings.weekStartDay),
  )

_weekStartLabel maps WeekStartDay.monday → S.of(context).settingsWeekStartMonday,
                        WeekStartDay.sunday → S.of(context).settingsWeekStartSunday.

_showWeekStartDialog shows an AlertDialog with two RadioListTile entries. On change:
  await ref.read(settingsRepositoryProvider).setWeekStartDay(value);
  ref.invalidate(appSettingsProvider);
  Navigator.pop(dialogContext);

Import WeekStartDay from app_settings.dart. Import settingsRepositoryProvider from repository_providers.dart and appSettingsProvider from state_settings.dart.

STEP E — ARB files: add 3 new keys to all 3 files.

Keys to add (after existing appearance-section keys):

  "settingsWeekStart": "<label>",
  "@settingsWeekStart": { "description": "Week start day setting label" },
  "settingsWeekStartMonday": "<Monday label>",
  "@settingsWeekStartMonday": { "description": "Monday option for week start" },
  "settingsWeekStartSunday": "<Sunday label>",
  "@settingsWeekStartSunday": { "description": "Sunday option for week start" },

Translations:
- app_ja.arb: settingsWeekStart="週の開始日", settingsWeekStartMonday="月曜日", settingsWeekStartSunday="日曜日"
- app_zh.arb: settingsWeekStart="每周起始日", settingsWeekStartMonday="周一", settingsWeekStartSunday="周日"
- app_en.arb: settingsWeekStart="Week starts on", settingsWeekStartMonday="Monday", settingsWeekStartSunday="Sunday"

Run flutter gen-l10n after updating ARB files.

STEP F — Calendar widget: wire weekStartDay + apply weekend colors.

In lib/features/list/presentation/widgets/list_calendar_header.dart:

1. Make CalendarHeaderWidget a ConsumerWidget (it already is — keep as-is).

2. In build(), watch appSettingsProvider:
   final settingsAsync = ref.watch(appSettingsProvider);
   final weekStartDay = settingsAsync.value?.weekStartDay ?? WeekStartDay.monday;

3. Replace the static _startingDay(locale) call in TableCalendar:
   startingDayOfWeek: weekStartDay == WeekStartDay.monday
       ? StartingDayOfWeek.monday
       : StartingDayOfWeek.sunday,

   Remove the old _startingDay() helper method.

4. Pass weekStartDay into _buildDayCell (add parameter):
   Widget _buildDayCell(DateTime day, Map<DateTime, int> dailyMap,
       DateTime? activeDayFilter, bool isOutside)
   — No need to pass weekStartDay into _buildDayCell; the day.weekday is self-sufficient.

5. WEEKEND COLORS — in _buildDayCell, compute numeralColor based on day.weekday BEFORE applying isSelected override:

   Color baseNumeralColor;
   if (day.weekday == DateTime.saturday) {
     baseNumeralColor = const Color(0xFF1565C0); // Saturday: blue
   } else if (day.weekday == DateTime.sunday) {
     baseNumeralColor = AppColors.textPrimary; // Sunday: black (same as default)
   } else {
     baseNumeralColor = AppColors.textPrimary;
   }
   final numeralColor = isSelected ? AppColors.card : baseNumeralColor;

   Saturday blue: use Color(0xFF1565C0) — Material Blue 800, a standard blue clearly distinct from the survival blue (0xFF5A9CC8). This is an explicitly specified user requirement; document it as a named constant inside the method with a comment: // Saturday calendar numeral — explicitly specified requirement.

   Sunday is black = AppColors.textPrimary (0xFF1E2432) — per requirement "周日字体黑色".

Import WeekStartDay from app_settings.dart. Import appSettingsProvider from state_settings.dart provider file.
  </action>
  <verify>
    <automated>flutter pub run build_runner build --delete-conflicting-outputs && flutter gen-l10n && flutter analyze && flutter test test/golden/list_calendar_header_golden_test.dart --update-goldens && flutter test test/golden/list_calendar_header_golden_test.dart</automated>
  </verify>
  <done>build_runner 0 errors; flutter gen-l10n succeeds; flutter analyze 0 issues; calendar header goldens re-baselined; Settings Appearance section shows week-start picker; calendar uses weekStartDay from provider; Saturday numerals are blue, Sunday numerals are textPrimary black.</done>
</task>

<task type="auto">
  <name>Task 3: Remove updatedAt sort option — SortField enum + UI + default</name>
  <files>
    lib/shared/constants/sort_config.dart
    lib/features/list/domain/models/list_sort_config.dart
    lib/features/list/domain/models/list_sort_config.freezed.dart
    lib/features/list/presentation/widgets/list_sort_filter_bar.dart
  </files>
  <action>
STEP A — Remove updatedAt from SortField enum.

In lib/shared/constants/sort_config.dart, remove the updatedAt value. The enum should only contain:
  enum SortField { timestamp, amount }

Update the doc comment to remove the updatedAt line.

CAUTION: SortField is also referenced in:
- lib/features/list/presentation/widgets/list_sort_filter_bar.dart (_sortFieldLabel switch)
- lib/features/list/domain/models/list_sort_config.dart (@Default)
- lib/data/daos/ (ORDER BY column mapping) — read the DAO to verify

Check lib/data/daos/ for the transaction DAO sort column switch and remove the updatedAt case. The DAO switch must remain exhaustive; removing the enum value will surface a compile error pointing to any remaining case.

STEP B — Fix ListSortConfig default.

In lib/features/list/domain/models/list_sort_config.dart:
  Change @Default(SortField.updatedAt) to @Default(SortField.timestamp)
  Update the doc comment: "Default: sort by [SortField.timestamp] descending"
  Update the static const initial = ListSortConfig() doc comment to match.

Run build_runner to regenerate list_sort_config.freezed.dart.

STEP C — Fix list_sort_filter_bar.dart.

In _sortFieldLabel switch, remove the updatedAt case:
  Remove: case SortField.updatedAt: return l10n.listSortEditTime;
  The switch must remain exhaustive over the two remaining values.

No ARB changes needed (listSortEditTime key can stay in ARB files as dead translations — removing it would require verifying no other use, and it causes no harm to leave it).

STEP D — Verify DAO.

Find the ORDER BY mapping in the transaction DAO (likely lib/data/daos/transaction_dao.dart) and remove the updatedAt → updated_at column mapping. The Dart analyzer will surface any remaining references once the enum value is removed.
  </action>
  <verify>
    <automated>flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze && flutter test test/golden/list_sort_filter_bar_golden_test.dart --update-goldens && flutter test test/golden/list_sort_filter_bar_golden_test.dart</automated>
  </verify>
  <done>build_runner 0 errors; flutter analyze 0 issues; SortField has only timestamp and amount; ListSortConfig defaults to timestamp-desc; sort filter bar golden re-baselined showing only Date and Amount chips.</done>
</task>

<task type="auto">
  <name>Task 4: Rebuild ListTransactionTile — L1 icon + L2 name + no time</name>
  <files>
    lib/features/list/presentation/widgets/list_transaction_tile.dart
    lib/features/list/presentation/screens/list_screen.dart
  </files>
  <action>
REDESIGN the tile layout and update the caller in ListScreen.

NEW TILE LAYOUT SPEC:
- LEFT COLUMN (Expanded):
  - PRIMARY row: L1 category Icon (24dp, categoryColor) + SizedBox(width: 8) + L2 category name Text (AppTextStyles.bodyMedium) + [if soul] SizedBox(width: 6) + satisfaction emoji Icon (14dp, AppColors.soul)
  - SECONDARY row: ledger type label Text (tagText, AppTextStyles.micro.copyWith(color: tagTextColor)) + [if merchant != null] ' · ' + merchant Text (AppTextStyles.micro.copyWith(color: AppColors.textSecondary))
- RIGHT: amount Text (AppTextStyles.amountSmall)
- REMOVE: the time label entirely
- REMOVE: the left tag badge (the pill badge showing ledger type) — ledger info moves to secondary row text
- KEEP: the member attribution chip (taggedTx.memberTag) between left column and amount
- KEEP: the Dismissible swipe-to-delete wrapper

DETAILED TILE CHILD STRUCTURE (inside GestureDetector > Padding):
  Row(
    children: [
      // Left info column
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Primary: L1 icon + L2 category name + optional soul emoji
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(l1Icon, size: 18, color: categoryColor),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(category, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
                ),
                if (satisfactionIcon != null) ...[
                  const SizedBox(width: 6),
                  Icon(satisfactionIcon, size: 14, color: AppColors.soul),
                ],
              ],
            ),
            const SizedBox(height: 2),
            // Secondary: ledger type label (+ merchant if present)
            Text(
              merchant != null ? '$tagText · $merchant' : tagText,
              style: AppTextStyles.micro.copyWith(color: tagTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      // Member attribution chip (unchanged)
      if (taggedTx.memberTag case final tag?) ...[...],
      // Amount
      Text(formattedAmount, style: AppTextStyles.amountSmall.copyWith(color: AppColors.textPrimary)),
    ],
  )

CONTRACT CHANGES to ListTransactionTile constructor:
- ADD parameter: required IconData l1Icon
- ADD parameter: String? merchant  (the raw merchant string from transaction)
- REMOVE parameter: required String formattedTime (no longer needed)
- Keep all other parameters unchanged

The existing formattedTime field is removed from the constructor. Remove the formatTransactionTime() helper function at the bottom of the file.

UPDATE LIST SCREEN (list_screen.dart):

In _buildTile():
1. Resolve L1 category icon:
   - Fetch the Category object for transaction.categoryId. But NOTE: ListScreen currently only has CategoryLocalizationService for resolving names, not full Category objects from the repository.
   - The cleanest approach within the existing architecture: derive the L1 icon using the category_display_utils.dart pattern, BUT the tile receives only a pre-formatted category name string — the Category objects are not in scope in ListScreen.
   - Solution: Import resolveCategoryIcon from category_display_utils.dart. The categoryId follows the pattern 'cat_{l2key}' for L2 items (e.g. 'cat_food_restaurant'). Strip to L1 key and look up icon. Add a helper _resolveL1Icon(String categoryId) in list_screen.dart:
     - L1 ids follow pattern 'cat_food', 'cat_transport' etc. L2 ids follow 'cat_food_restaurant'.
     - If the id has exactly one underscore after 'cat_' → it is already L1.
     - If it has two underscores → it is L2; strip the last segment to get the L1 id.
     - Then look up the icon from the Category static data. Since we cannot call the DB synchronously, look up the ICON STRING from the L1 category's icon field. But we don't have Category objects in scope here.
   - PRAGMATIC SOLUTION: Use a static map in list_screen.dart mapping known L1 categoryId prefixes to their IconData. This mirrors the approach in category_display_utils.dart's resolveCategoryIcon. The map is:
     'cat_food' → Icons.restaurant,
     'cat_daily' → Icons.local_mall,
     'cat_transport' → Icons.directions_bus,
     'cat_hobbies' → Icons.sports_esports,
     'cat_clothing' → Icons.checkroom,
     'cat_social' → Icons.people,
     'cat_health' → Icons.local_hospital,
     'cat_education' → Icons.school,
     'cat_utilities' → Icons.flash_on,
     'cat_communication' → Icons.phone_iphone,
     'cat_housing' → Icons.home,
     'cat_car' → Icons.directions_car,
     'cat_tax' → Icons.account_balance,
     'cat_insurance' → Icons.security,
     'cat_special' → Icons.star,
     'cat_savings' → Icons.savings,
     'cat_other' → Icons.more_horiz,
     (fallback) → Icons.category,
   - Helper _resolveL1IconForCategory(String categoryId):
     - If categoryId starts with 'cat_': strip 'cat_', split on '_', take first segment → prefix 'cat_' back → look up in map.
     - If custom id (no 'cat_' prefix): return Icons.category.
   - Add this private static method or top-level function in list_screen.dart (not in tile — caller resolves, tile is pure display).

2. Remove formattedTime computation (delete the formatTransactionTime call and import of formatTransactionTime from list_transaction_tile.dart if it was imported separately — it was defined there but called in list_screen.dart via the free function at the file bottom; check if list_screen.dart imports it. Looking at list_screen.dart it imports list_transaction_tile.dart which exports formatTransactionTime at the top level; remove the call but keep the import of ListTransactionTile).

3. Pass the new parameters to ListTransactionTile:
   l1Icon: _resolveL1IconForCategory(transaction.categoryId),
   merchant: transaction.merchant,
   // formattedTime: removed

4. Remove the `formattedTime` variable assignment in _buildTile().

GOLDEN TEST UPDATE:
Update test/golden/list_transaction_tile_golden_test.dart:
- Remove formattedTime parameter from ListTransactionTile construction.
- Add l1Icon: Icons.restaurant (matching the fixture's cat_food categoryId).
- Add merchant: null (the fixture has no merchant set).
- Update the SizedBox height from 80 to 72 or keep 80 and let the widget natural-size itself — keep width: 390, height: 80 but if the tile naturally exceeds 80dp, raise to 96.
- Re-baseline all 3 goldens.
  </action>
  <verify>
    <automated>flutter analyze lib/features/list/presentation/widgets/list_transaction_tile.dart lib/features/list/presentation/screens/list_screen.dart && flutter test test/golden/list_transaction_tile_golden_test.dart --update-goldens && flutter test test/golden/list_transaction_tile_golden_test.dart && flutter analyze</automated>
  </verify>
  <done>flutter analyze 0 issues; ListTransactionTile shows L1 icon + L2 name on primary row, ledger type + merchant on secondary row, amount trailing, no time; golden tests re-baselined for all 3 locales.</done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| SharedPreferences → WeekStartDay | String value from disk parsed into enum; malformed value falls back to monday default |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation |
|-----------|----------|-----------|-------------|------------|
| T-oqn-01 | Tampering | SettingsRepositoryImpl._getWeekStartDay | mitigate | `WeekStartDay.values.firstWhere(..., orElse: () => WeekStartDay.monday)` — malformed persisted value falls back to default, no crash |
| T-oqn-02 | Denial of Service | SortField exhaustive switch in DAO | mitigate | Removing updatedAt causes compiler error at remaining switch sites — fix all before shipping; analyzer gate enforced |
</threat_model>

<verification>
After all 4 tasks:
1. flutter pub run build_runner build --delete-conflicting-outputs  (0 errors)
2. flutter gen-l10n  (0 errors)
3. flutter analyze  (0 issues)
4. flutter test test/golden/  (all goldens pass, baselines updated for: list_calendar_header_{ja,zh,en}, list_sort_filter_bar_{ja,zh,en}, list_transaction_tile_{ja,zh,en})
5. flutter test  (full suite, 0 failures — incl. updated list_calendar_header_test.dart + list_screen_refresh_test.dart after the AppBar refactor)
</verification>

<success_criteria>
- ListScreen: Material AppBar (consistent with analytics) with the current month centered as title (tappable → jump to current month), prev-month chevron leading + next-month chevron action; standalone month-nav bar removed from the calendar header
- Calendar header: empty cells carry a placeholder SizedBox matching the amount text height so numerals align across a row
- Calendar: week-start controlled by AppSettings.weekStartDay (default monday), persisted in SharedPreferences key 'week_start_day'
- Calendar cell colors: Saturday = Color(0xFF1565C0) blue, Sunday = AppColors.textPrimary, determined by day.weekday not column
- Settings > Appearance: new "週の開始日 / 每周起始日 / Week starts on" picker tile with Monday/Sunday options
- Sort options: only Date (timestamp) and Amount; updatedAt removed from SortField enum; default sort is timestamp-desc
- Transaction tile: L1 icon + L2 category name (+ soul emoji if applicable) on primary row; ledger type label + optional merchant on secondary row; amount on right; no time displayed
- flutter analyze 0 issues, all golden tests re-baselined and passing
</success_criteria>

<output>
Create `.planning/quick/260531-oqn-ui/260531-oqn-SUMMARY.md` when done.
</output>
