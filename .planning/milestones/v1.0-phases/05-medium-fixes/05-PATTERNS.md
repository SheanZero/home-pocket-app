# Phase 5: MEDIUM Fixes - Pattern Map

**Mapped:** 2026-04-27  
**Files analyzed:** 34 new/modified candidates  
**Analogs found:** 31 / 34

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/infrastructure/category/category_locale_service.dart` | service | transform | `lib/infrastructure/category/category_service.dart` | exact |
| `lib/infrastructure/category/category_service.dart` | service | transform | `lib/infrastructure/category/category_service.dart` | exact-rename-source |
| `lib/application/accounting/category_localization_service.dart` | service | transform | `lib/application/i18n/formatter_service.dart` | role-match |
| `lib/application/accounting/category_service.dart` | service | CRUD/lookup | `lib/application/accounting/category_service.dart` | unchanged-reference |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | provider | request-response/DI | same file provider pattern | exact |
| `test/unit/infrastructure/category/category_locale_service_test.dart` | test | transform | `test/unit/features/accounting/presentation/utils/category_display_utils_test.dart` | role-match |
| `test/architecture/service_name_collision_test.dart` | test | batch/scan | `test/architecture/provider_graph_hygiene_test.dart` | exact |
| `lib/l10n/app_en.arb` | config | transform | `lib/l10n/app_en.arb` | exact |
| `lib/l10n/app_ja.arb` | config | transform | `lib/l10n/app_ja.arb` | exact |
| `lib/l10n/app_zh.arb` | config | transform | `lib/l10n/app_zh.arb` | exact |
| `lib/generated/app_localizations.dart` | generated config | transform | `lib/generated/app_localizations.dart` | generated |
| `lib/generated/app_localizations_en.dart` | generated config | transform | `lib/generated/app_localizations_en.dart` | generated |
| `lib/generated/app_localizations_ja.dart` | generated config | transform | `lib/generated/app_localizations_ja.dart` | generated |
| `lib/generated/app_localizations_zh.dart` | generated config | transform | `lib/generated/app_localizations_zh.dart` | generated |
| `test/architecture/arb_key_parity_test.dart` | test | file-I/O/batch | `test/architecture/provider_graph_hygiene_test.dart` | role-match |
| `lib/features/home/presentation/screens/home_screen.dart` | component/screen | request-response | same file + `AnalyticsScreen` localization pattern | exact |
| `lib/features/home/presentation/widgets/soul_fullness_card.dart` | component | transform | `lib/features/home/presentation/widgets/ledger_comparison_section.dart` | role-match |
| `lib/features/accounting/presentation/screens/voice_input_screen.dart` | component/screen | event-driven | same file | exact |
| `test/widget/features/home/presentation/screens/home_screen_test.dart` | test | request-response | same file | exact |
| `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` | test | request-response | `test/helpers/test_localizations.dart` + existing widget tests | role-match |
| `test/widget/features/accounting/presentation/screens/voice_input_screen_test.dart` | test | event-driven | same file | exact |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | component/screen | request-response | same file | exact |
| `lib/features/analytics/presentation/widgets/category_breakdown_list.dart` | component | transform | `lib/features/home/presentation/widgets/home_transaction_tile.dart` | role-match |
| `lib/features/analytics/presentation/widgets/daily_expense_chart.dart` | component/chart | transform | `lib/application/i18n/formatter_service.dart` | partial |
| `lib/features/analytics/presentation/widgets/expense_trend_chart.dart` | component/chart | transform | `lib/application/i18n/formatter_service.dart` | partial |
| `lib/features/analytics/presentation/widgets/ledger_ratio_chart.dart` | component/chart | transform | `lib/features/home/presentation/widgets/ledger_comparison_section.dart` | role-match |
| `lib/features/analytics/presentation/widgets/budget_progress_list.dart` | component | transform | `lib/features/home/presentation/widgets/month_overview_card.dart` | role-match |
| `lib/features/analytics/presentation/widgets/summary_cards.dart` | component | transform | `lib/features/home/presentation/widgets/month_overview_card.dart` | role-match |
| `test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart` | test | request-response | same file | exact |
| `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` | test | request-response | `test/widget/features/home/presentation/widgets/month_overview_card_test.dart` | role-match |
| `lib/infrastructure/ml/merchant_database.dart` | service | lookup/transform | same file | exact |
| `test/architecture/mod009_live_lib_scan_test.dart` | test | file-I/O/batch | `test/architecture/provider_graph_hygiene_test.dart` | exact |
| `test/architecture/hardcoded_cjk_ui_scan_test.dart` | test | file-I/O/batch | `test/architecture/provider_graph_hygiene_test.dart` | exact |
| `.planning/audit/issues.json` | config | batch/status | `scripts/merge_findings.dart` / audit schema | partial |

## Pattern Assignments

### CategoryLocaleService Rename

**Applies to:** `lib/infrastructure/category/category_locale_service.dart`, `lib/application/accounting/category_localization_service.dart`, `lib/features/accounting/presentation/providers/repository_providers.dart`, `test/unit/infrastructure/category/category_locale_service_test.dart`

**Analog:** `lib/infrastructure/category/category_service.dart`

**Static service pattern** (lines 1-35):
```dart
import 'dart:ui';

/// Resolves system category localization keys to display names.
abstract final class CategoryService {
  static String resolveFromId(String categoryId, Locale locale) {
    if (categoryId.startsWith('cat_')) {
      final nameKey = 'category_${categoryId.substring(4)}';
      return resolve(nameKey, locale);
    }
    return categoryId;
  }

  static String resolve(String nameKey, Locale locale) {
    final map = switch (locale.languageCode) {
      'ja' => _ja,
      'zh' => _zh,
      _ => _en,
    };
    return map[nameKey] ?? nameKey;
  }
}
```

**Application facade pattern** from `lib/application/accounting/category_localization_service.dart` (lines 1-27):
```dart
import 'dart:ui';

import '../../infrastructure/category/category_service.dart' as infra;

abstract final class CategoryLocalizationService {
  static String resolve(String nameKey, Locale locale) =>
      infra.CategoryService.resolve(nameKey, locale);

  static String resolveFromId(String categoryId, Locale locale) =>
      infra.CategoryService.resolveFromId(categoryId, locale);
}
```

Planner action: after `git mv`, update the import path to `../../infrastructure/category/category_locale_service.dart` and calls to `infra.CategoryLocaleService`. Keep `CategoryLocalizationService` as the presentation-facing facade.

**Business service that keeps the name** from `lib/application/accounting/category_service.dart` (lines 5-16, 26-40):
```dart
/// Consolidated service for category-related business logic.
class CategoryService {
  CategoryService({
    required CategoryRepository categoryRepository,
    required CategoryLedgerConfigRepository ledgerConfigRepository,
  }) : _categoryRepo = categoryRepository,
       _configRepo = ledgerConfigRepository;

  Future<LedgerType?> resolveLedgerType(String categoryId) async {
    final category = await _categoryRepo.findById(categoryId);
    if (category == null) return null;
    final directConfig = await _configRepo.findById(categoryId);
    if (directConfig != null) return directConfig.ledgerType;
    if (category.level == 2 && category.parentId != null) {
      final parentConfig = await _configRepo.findById(category.parentId!);
      return parentConfig?.ledgerType;
    }
    return null;
  }
}
```

**Provider wiring pattern** from `lib/features/accounting/presentation/providers/repository_providers.dart` (lines 151-157):
```dart
@riverpod
CategoryService categoryService(Ref ref) {
  return CategoryService(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    ledgerConfigRepository: ref.watch(categoryLedgerConfigRepositoryProvider),
  );
}
```

**Unit test pattern** from `test/unit/features/accounting/presentation/utils/category_display_utils_test.dart` (lines 28-36):
```dart
test('formatCategoryPath builds L1 > L2 label', () {
  final label = formatCategoryPath(
    category: l2Category,
    parentCategory: l1Category,
    locale: const Locale('zh'),
  );

  expect(label, '食费 > 其他食费');
});
```

Use equivalent assertions for `CategoryLocaleService.resolve`, `resolveFromId`, unknown key passthrough, and ja/zh/en key consistency.

---

### Architecture Scan Tests

**Applies to:** `test/architecture/service_name_collision_test.dart`, `test/architecture/hardcoded_cjk_ui_scan_test.dart`, `test/architecture/mod009_live_lib_scan_test.dart`, `test/architecture/arb_key_parity_test.dart`

**Analog:** `test/architecture/provider_graph_hygiene_test.dart`

**Imports and test grouping pattern** (lines 1-13, 41-45):
```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Architecture test: Provider graph hygiene invariants.
///
/// Run: flutter test test/architecture/provider_graph_hygiene_test.dart

void main() {
  group('Provider graph hygiene', () {
    test(
      'HIGH-04 structure: each feature has exactly one repository_providers.dart and only state_*.dart siblings',
      () {
```

**Recursive lib scan pattern** (lines 141-203):
```dart
final hits = <String>[];
for (final entity in Directory('lib').listSync(recursive: true)) {
  if (entity is File &&
      entity.path.endsWith('.dart') &&
      !entity.path.endsWith('.g.dart')) {
    final src = entity.readAsStringSync();
    if (RegExp(
          r'@(?:R|r)iverpod[\s\S]{0,500}throw\s+UnimplementedError',
        ).hasMatch(src) ||
        RegExp(
          r'Provider<\w+>\(\([^)]*\)\s*=>\s*throw\s+UnimplementedError',
        ).hasMatch(src)) {
      hits.add(entity.path);
    }
  }
}
expect(
  hits,
  isEmpty,
  reason: 'UnimplementedError providers found in production code: $hits',
);
```

Planner notes:
- Service-name collision guard should scan production Dart class declarations and fail when the same `*Service` class name appears in multiple layers unless explicitly whitelisted.
- CJK scanner should scan `lib/**/*.dart`, skip generated files and approved data/formatter/map paths from `05-CONTEXT.md`, and only fail user-visible string literals.
- MOD-009 scanner should scan `lib/**/*.dart` only and reject `MOD-009`, `mod009`, and deprecated i18n module path strings.
- ARB parity test should read `lib/l10n/app_{en,ja,zh}.arb`, parse JSON, compare normal keys plus metadata keys, and assert OCR placeholders remain.

---

### ARB Normalization and Generated Localization

**Applies to:** `lib/l10n/app_en.arb`, `lib/l10n/app_ja.arb`, `lib/l10n/app_zh.arb`, `lib/generated/app_localizations*.dart`, `test/architecture/arb_key_parity_test.dart`

**Analog:** current ARB files and `flutter gen-l10n` output.

**English metadata pattern** from `lib/l10n/app_en.arb` (lines 378-396, 450-496):
```json
"homeMonthlyExpense": "Monthly Expenses",
"@homeMonthlyExpense": { "description": "Home card title for monthly expense overview" },

"homeSoulFullness": "Soul Fullness",
"@homeSoulFullness": { "description": "Soul fullness section title" },

"ocrScan": "OCR",
"@ocrScan": { "description": "OCR scan mode tab label" },

"ocrScanTitle": "OCR Scan",
"@ocrScanTitle": { "description": "OCR scanner screen title" },

"ocrHint": "Place receipt in frame",
"@ocrHint": { "description": "OCR scanner hint text" }
```

**Localized key parity pattern** from `lib/l10n/app_ja.arb` (lines 141-181):
```json
"homeMonthlyExpense": "今月の出費",
"homeSoulFullness": "魂の充実度",
"homeHappinessROI": "幸せROI",
"homeRecentSoulTransaction": "直近: {merchant} \u00a5{amount}",
"homeSoulChargeStatus": "魂の充実度 {fullness}% \u00b7 幸せROI {roi}x",
"ocrScan": "OCR",
"ocrScanTitle": "OCRスキャン入力",
"ocrHint": "レシートを枠内に収めてください"
```

Planner notes:
- Preserve `ocrScan`, `ocrScanTitle`, and `ocrHint` in all three ARB files. Add/retain `@key` metadata for OCR stubs, especially in `app_en.arb`.
- After ARB edits, run `flutter gen-l10n`. Do not hand-edit `lib/generated/app_localizations*.dart`.
- If normalizing key names, perform a static reference audit before deleting old keys.

---

### UI Localization Pattern

**Applies to:** `lib/features/home/presentation/screens/home_screen.dart`, `lib/features/home/presentation/widgets/soul_fullness_card.dart`, `lib/features/accounting/presentation/screens/voice_input_screen.dart`, analytics widgets, related widget tests.

**Analog:** `lib/features/analytics/presentation/screens/analytics_screen.dart` and localized helper tests.

**Screen localization imports/use** from `lib/features/analytics/presentation/screens/analytics_screen.dart` (lines 6-8, 42-49):
```dart
import '../../../../application/i18n/formatter_service.dart';
import '../../../../generated/app_localizations.dart';

return Scaffold(
  appBar: AppBar(
    title: Text(S.of(context).analytics),
    actions: [
      IconButton(
        icon: const Icon(Icons.auto_fix_high),
        tooltip: S.of(context).generateDemoData,
        onPressed: () => _generateDemoData(context, ref),
      ),
    ],
  ),
);
```

**Existing home hardcoded hotspots** from `lib/features/home/presentation/screens/home_screen.dart` (lines 82-109, 164-198):
```dart
const SectionDivider(label: '今月の支出'),
const SizedBox(height: 16),

const SectionDivider(label: '帳 本'),

Text(
  '最近の取引',
  style: AppTextStyles.titleSmall.copyWith(
    color: context.wmTextPrimary,
  ),
),
Text(
  'すべて見る',
  style: AppTextStyles.bodySmall.copyWith(
    color: AppColors.accentPrimary,
  ),
),
Text(
  '取引がまだありません',
  style: AppTextStyles.bodySmall.copyWith(
    color: context.wmTextSecondary,
  ),
),
```

Replace with `final l10n = S.of(context);` in `build`, pass non-const localized labels into widgets, and update tests to assert localized values from `S`.

**Widget localization test helper** from `test/helpers/test_localizations.dart` (lines 14-31):
```dart
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}
```

**Home test pattern** from `test/widget/features/home/presentation/screens/home_screen_test.dart` (lines 51-68, 89-96):
```dart
Widget buildSubject({Locale locale = const Locale('ja')}) {
  return ProviderScope(
    overrides: [
      monthlyReportProvider(
        bookId: 'book_001',
        year: now.year,
        month: now.month,
      ).overrideWith((ref) async => _mockReport),
      todayTransactionsProvider(
        bookId: 'book_001',
      ).overrideWith((ref) async => []),
      groupRepositoryProvider.overrideWithValue(groupRepository),
    ],
    child: testLocalizedApp(
      locale: locale,
      child: const Scaffold(body: HomeScreen(bookId: 'book_001')),
    ),
  );
}

expect(find.byType(SectionDivider), findsNWidgets(2));
expect(find.text('今月の支出'), findsOneWidget);
expect(find.text('帳 本'), findsOneWidget);
```

Update expected text to use normalized ARB values and include at least one non-Japanese locale assertion when changing key names.

---

### Money Formatting and Amount Style Pattern

**Applies to:** `lib/features/analytics/presentation/widgets/category_breakdown_list.dart`, `daily_expense_chart.dart`, `expense_trend_chart.dart`, `ledger_ratio_chart.dart`, `budget_progress_list.dart`, `summary_cards.dart`, `soul_fullness_card.dart`, widget tests.

**Analog:** `FormatterService`, `AppTextStyles`, and compliant home/accounting widgets.

**FormatterService canonical API** from `lib/application/i18n/formatter_service.dart` (lines 1-9, 53-57, 72-77):
```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../infrastructure/i18n/formatters/date_formatter.dart';
import '../../infrastructure/i18n/formatters/number_formatter.dart';

part 'formatter_service.g.dart';

String formatCurrency(num amount, String currencyCode, Locale locale) =>
    NumberFormatter.formatCurrency(amount, currencyCode, locale);

@riverpod
FormatterService formatterService(Ref ref) => const FormatterService();
```

**Amount style source of truth** from `lib/core/theme/app_text_styles.dart` (lines 143-168):
```dart
// ── Amount styles (tabular figures for numeric alignment) ──

static const amountLarge = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 30,
  fontWeight: FontWeight.w700,
  height: 0.9,
  color: AppColors.textPrimary,
  fontFeatures: _tabularFigures,
);

static const amountMedium = TextStyle(
  fontFamily: _fontFamily,
  fontSize: 18,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  fontFeatures: _tabularFigures,
);
```

**Compliant UI style pattern** from `lib/features/home/presentation/widgets/ledger_comparison_section.dart` (lines 73-78):
```dart
Text(
  data.formattedAmount,
  style: AppTextStyles.amountMedium.copyWith(
    color: data.amountColor,
  ),
),
```

**Compliant screen formatting pattern** from `lib/features/accounting/presentation/screens/voice_input_screen.dart` (lines 394-413, 670-675):
```dart
String _parsedAmountText(Locale locale) {
  final amount = _parseResult?.amount;
  if (amount == null) return '';
  return const FormatterService().formatCurrency(amount, 'JPY', locale);
}

String _parsedDateText(Locale locale, S l10n) {
  final date = _parseResult?.parsedDate;
  if (date == null) return l10n.todayDate;
  return const FormatterService().formatDate(date, locale);
}

_ParsedInfoRow(
  icon: Icons.payments_outlined,
  label: amountLabel,
  value: amountValue,
  valueStyle: AppTextStyles.amountMedium,
  isDark: isDark,
),
```

**Non-compliant analytics examples to replace**:

`lib/features/analytics/presentation/widgets/budget_progress_list.dart` (lines 79-86, 107-116):
```dart
Text(
  '¥${progress.spentAmount} / ¥${progress.budgetAmount}',
  style: TextStyle(
    color: _statusColor,
    fontWeight: FontWeight.bold,
    fontSize: 13,
  ),
),
Text(
  progress.remainingAmount >= 0
      ? 'Remaining: ¥${progress.remainingAmount}'
      : 'Exceeded: ¥${progress.remainingAmount.abs()}',
  style: TextStyle(
    fontSize: 12,
    color: progress.remainingAmount >= 0
        ? Colors.grey
        : Colors.red,
  ),
),
```

`lib/features/analytics/presentation/widgets/summary_cards.dart` (lines 88-95):
```dart
Text(
  '¥${_formatAmount(amount)}',
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: color,
  ),
),
```

Planner action: route all real money strings through `FormatterService.formatCurrency(...)` and style money `Text` with `AppTextStyles.amountLarge/Medium/Small.copyWith(...)`. Percentages and status labels can keep non-amount styles.

**Style test pattern** from `test/unit/core/theme/app_text_styles_test.dart` (lines 26-30):
```dart
test('amountLarge is 30px bold with tabular figures', () {
  expect(AppTextStyles.amountLarge.fontSize, 30);
  expect(AppTextStyles.amountLarge.fontWeight, FontWeight.w700);
  expect(AppTextStyles.amountLarge.fontFeatures, isNotEmpty);
});
```

For widget tests, inspect rendered `Text` widgets for target money strings and assert `text.style?.fontFeatures` contains `FontFeature.tabularFigures()`.

---

### Analytics Widget Test Pattern

**Applies to:** `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart`, updates to `test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart`

**Analog:** `test/unit/features/analytics/presentation/screens/analytics_screen_characterization_test.dart`

**Mock/localized app setup** (lines 20-40, 96-112):
```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
class _MockCategoryRepository extends Mock implements CategoryRepository {}
class _MockSettingsRepository extends Mock implements SettingsRepository {}

Widget _buildApp(Widget child, List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}

testWidgets('renders without crashing', (tester) async {
  await tester.pumpWidget(
    _buildApp(
      const AnalyticsScreen(bookId: 'book-001'),
      [
        analyticsRepositoryProvider.overrideWithValue(mockAnalyticsRepo),
        categoryRepositoryProvider.overrideWithValue(mockCategoryRepo),
        settingsRepositoryProvider.overrideWithValue(mockSettingsRepo),
      ],
    ),
  );
  await tester.pump();
  expect(find.byType(Scaffold), findsWidgets);
});
```

**Simple widget assertion pattern** from `test/widget/features/home/presentation/widgets/month_overview_card_test.dart` (lines 8-21):
```dart
testWidgets('displays formatted total expense', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(
        body: MonthOverviewCard(
          totalExpense: 248500,
          previousMonthTotal: 282300,
        ),
      ),
    ),
  );

  expect(find.textContaining('248,500'), findsOneWidget);
});
```

No exact analytics widget tests exist yet; use these patterns to create focused widget tests for analytics components.

---

### MOD-009 Cleanup Pattern

**Applies to:** `lib/infrastructure/ml/merchant_database.dart`, `test/architecture/mod009_live_lib_scan_test.dart`

**Analog:** same source file and architecture scan tests.

**Current comment to rewrite** from `lib/infrastructure/ml/merchant_database.dart` (lines 38-44):
```dart
/// Merchant lookup database.
///
/// Provides fuzzy merchant matching for voice and OCR modules.
/// This is the shared infrastructure — used by MOD-004 OCR and MOD-009 Voice.
///
/// Current implementation: seed data (~20 well-known Japanese merchants).
```

Rewrite to capability language, for example "shared merchant lookup used by OCR and voice-input classification"; do not remove merchant seed entries or comments containing language data.

## Shared Patterns

### Layer Boundaries
**Source:** `AGENTS.md` and `CLAUDE.md`  
**Apply to:** all Phase 5 changes

- Presentation must not import `lib/infrastructure/**`; use application facades such as `CategoryLocalizationService` and `FormatterService`.
- Features must not contain infrastructure, Drift tables, or DAOs.
- Generated files are regenerated, not hand-edited.

### Localization
**Source:** `lib/generated/app_localizations.dart` via `S.of(context)` and ARB files  
**Apply to:** all user-visible UI copy

Use `S.of(context)` in build methods. For pure widgets that need localization, either pass localized strings from the parent or import `generated/app_localizations.dart` and resolve `S.of(context)` locally. Keep language data whitelisted only for NLP/merchant/formatter/category-map paths.

### Money Display
**Source:** `lib/application/i18n/formatter_service.dart`, `lib/core/theme/app_text_styles.dart`  
**Apply to:** all real monetary values

Both are required:
- format with `FormatterService.formatCurrency(amount, 'JPY', locale)`
- style with `AppTextStyles.amountLarge/Medium/Small.copyWith(...)`

### Test Style
**Source:** `test/architecture/provider_graph_hygiene_test.dart`, `test/helpers/test_localizations.dart`, existing widget tests  
**Apply to:** architecture scan tests and localized widget tests

Use Flutter tests with `dart:io` scans for architecture gates; use `createLocalizedWidget` or local `MaterialApp` with `S.delegate` for localization-dependent widget tests. Prefer Mocktail for mocks.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/generated/app_localizations*.dart` | generated config | transform | Generated by `flutter gen-l10n`; planner should not copy-edit generated code. |
| `test/widget/features/analytics/presentation/widgets/analytics_money_widgets_test.dart` | test | request-response | No existing analytics widget tests; use home widget and analytics screen characterization patterns. |
| `.planning/audit/issues.json` | config | batch/status | Audit status file has schema docs, but no direct edit analog in Phase 5 source; planner should follow `.planning/audit/SCHEMA.md`. |

## Metadata

**Analog search scope:** `lib/`, `test/`, `scripts/`, `lib/l10n/`  
**Files scanned:** `rg --files lib test scripts` plus targeted ARB/code searches  
**Pattern extraction date:** 2026-04-27
