# Phase 10: HomePage SoulFullnessCard Redesign — Pattern Map

**Mapped:** 2026-05-02
**Files analyzed:** 14 (9 production + 3 ARB + 2 spec docs) + 3 test files
**Analogs found:** 12 / 14 (CustomPainter has no codebase analog — Flutter canonical pattern cited)

---

## Scope Reminder (verbatim from RESEARCH §"Recommended Project Structure")

Production work:
1. **NEW** `lib/features/home/presentation/widgets/home_hero_card.dart` (master StatelessWidget — budget < 400 lines)
2. **NEW** `lib/features/home/presentation/widgets/home_hero_card_rings.dart` (only if master > 400 lines)
3. **NEW** `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` (CustomPainter for 3 concentric gradient rings)
4. **NEW** `lib/features/home/presentation/widgets/home_hero_card_member_rows.dart` (only if master > 400 lines)
5. **MODIFY** `lib/features/home/presentation/screens/home_screen.dart` — delete `_computeHappinessROI` (line 362), `_computeSatisfaction` (line 345), `_buildLedgerRows` (line 258); collapse 3 widget calls into 1 `HomeHeroCard`; net line count must DECREASE
6. **DELETE** `lib/features/home/presentation/widgets/soul_fullness_card.dart`
7. **DELETE** `lib/features/home/presentation/widgets/month_overview_card.dart`
8. **DELETE** `lib/features/home/presentation/widgets/ledger_comparison_section.dart`
9. **MODIFY** `lib/features/accounting/presentation/providers/repository_providers.dart` — add `bookByIdProvider(bookId)` (D-12 currency resolution)
10. **MODIFY** `lib/l10n/app_ja.arb`, `app_zh.arb`, `app_en.arb` — add ~21 new keys (atomically across all 3 files)

Test work:
11. **NEW** `test/widget/features/home/presentation/widgets/home_hero_card_test.dart`
12. **NEW** `test/golden/home_hero_card_golden_test.dart`
13. **NEW** `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart`
14. **MODIFY** `test/widget/features/home/presentation/screens/home_screen_test.dart` — replace 3 widget finders with `HomeHeroCard` finder
15. **DELETE** `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart`
16. **DELETE** `test/widget/features/home/presentation/widgets/month_overview_card_test.dart`
17. **DELETE** `test/golden/soul_fullness_card_golden_test.dart` + `test/golden/goldens/soul_fullness_card_ja.png`

Spec amendments (per CONTEXT D-06/D-07):
18. **MODIFY** `.planning/REQUIREMENTS.md` — add HOMEUI-05/06/07; update v1.1 active REQ count 25 → 28; update traceability table
19. **MODIFY** `.planning/ROADMAP.md` — Phase 10 goal/requirements/complexity/critical-pitfalls amendments

---

## File Classification

| New / Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---------------------|------|-----------|----------------|---------------|
| `lib/features/home/presentation/widgets/home_hero_card.dart` (NEW master) | widget (Stateless presentation, multi-section composition) | request-response (consumes resolved Freezed aggregates) | `lib/features/home/presentation/widgets/soul_fullness_card.dart` (composition pattern) + `lib/features/home/presentation/widgets/month_overview_card.dart` (trend chip pattern) | exact (composition) + exact (trend chip) |
| `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` (NEW) | utility (CustomPainter — pure render) | transform (input ratios → canvas drawArc) | **NO ANALOG IN `lib/`** — Flutter canonical CustomPainter cited from RESEARCH §"Pattern 3" + Flutter docs (api.flutter.dev `Canvas.drawArc` + `SweepGradient`) | none (canonical Flutter pattern) |
| `lib/features/home/presentation/widgets/home_hero_card_rings.dart` (conditional NEW) | widget (sub-section: title row + CustomPaint + legend) | request-response | extracted from `home_hero_card.dart` only if master > 400 lines | follow same composition pattern as `soul_fullness_card.dart` |
| `lib/features/home/presentation/widgets/home_hero_card_member_rows.dart` (conditional NEW) | widget (sub-section: subheader + N rows) | request-response | `lib/features/home/presentation/widgets/ledger_comparison_section.dart` `_LedgerRow` (row composition) | role-match (replaces shadow-book-row branch) |
| `lib/features/home/presentation/screens/home_screen.dart` (MODIFY) | screen (ConsumerWidget, container) | request-response (provider wiring + AsyncValue.when) | itself — keep existing `reportAsync.when(...)` style at lines 88-105 / 113-128 / 132-143 | self-analog (in-place edit) |
| `lib/features/accounting/presentation/providers/repository_providers.dart` (MODIFY — add `bookByIdProvider`) | provider (Riverpod `@riverpod` parametrized) | CRUD-read | existing parametrized providers in `lib/features/analytics/presentation/providers/state_happiness.dart` `happinessReport` (lines 16-30) | exact |
| `lib/l10n/app_{ja,zh,en}.arb` (MODIFY — atomic triple) | config (i18n key/value) | n/a (build-time consumed) | existing `homePreviousMonthAmount` block at `app_en.arb` lines 523-531 (placeholder pattern) | exact |
| `test/widget/features/home/presentation/widgets/home_hero_card_test.dart` (NEW) | test (widget test, mocktail + ProviderScope overrides) | request-response | `test/widget/features/home/presentation/screens/home_screen_test.dart` (ProviderScope+overrides) + `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` (pure widget) | exact (combined) |
| `test/golden/home_hero_card_golden_test.dart` (NEW) | test (golden) | request-response | `test/golden/soul_fullness_card_golden_test.dart` (single-file fixed-size wrap) + `test/golden/summary_cards_golden_test.dart` (locale variants) | exact |
| `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` (NEW) | test (painter unit, mock `Canvas` via mocktail) | transform | **NO ANALOG IN `test/`** — falls back to Flutter docs pattern: instantiate painter, call `paint(mockCanvas, Size(w,h))`, verify `verify(() => canvas.drawArc(...)).called(N)` | none (mocktail-on-Canvas idiom) |
| `test/widget/features/home/presentation/screens/home_screen_test.dart` (MODIFY) | test (widget test) | request-response | itself (already exists with full mocktail+ProviderScope wiring) | self-analog |
| `.planning/REQUIREMENTS.md` (MODIFY) | doc (spec) | n/a | existing requirement entries in same file | self-analog |
| `.planning/ROADMAP.md` (MODIFY) | doc (spec) | n/a | existing Phase entries in same file | self-analog |

---

## Pattern Assignments

### 1. `home_hero_card.dart` (NEW master) — widget, request-response

**Primary analog:** `lib/features/home/presentation/widgets/soul_fullness_card.dart` (whole-card composition)
**Secondary analog:** `lib/features/home/presentation/widgets/month_overview_card.dart` (trend chip + currency formatting)

**Imports pattern** (from `soul_fullness_card.dart` lines 1-7 — copy verbatim, adjust imports for new dependencies):
```dart
import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
```

Add for Phase 10:
```dart
import '../../../analytics/domain/models/best_joy_moment_row.dart';
import '../../../analytics/domain/models/family_happiness.dart';
import '../../../analytics/domain/models/happiness_report.dart';
import '../../../analytics/domain/models/metric_result.dart';
import '../../../analytics/domain/models/monthly_report.dart';
import '../../../analytics/domain/models/shared_joy_insight.dart';
import '../providers/state_shadow_books.dart';   // ShadowBookInfo + ShadowAggregate types
```

**Outer-card scaffold pattern** (verbatim from `soul_fullness_card.dart` lines 31-53 — `GestureDetector` → `Container` with `BoxDecoration(color: context.wmCard, border: ..., borderRadius: 14)`):
```dart
// soul_fullness_card.dart:31-53
return GestureDetector(
  onTap: onTap,
  child: Container(
    padding: const EdgeInsets.all(16),     // Phase 10: planner picks 16 vs 18 per UI-SPEC OQ #1
    decoration: BoxDecoration(
      color: context.wmCard,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: context.wmBorderDefault),
    ),
    child: Column(
      children: [
        _buildTitleRow(context, l10n),
        const SizedBox(height: 12),
        // ... section / divider / section / divider / ...
        Container(height: 1, color: context.wmBackgroundDivider),
        // ...
      ],
    ),
  ),
);
```

**Adaptation notes:**
- Replace inner `_buildTitleRow / _buildMetricRow / _buildRecentSpendingRow` with the 8-region D-02 vertical structure: hero header → split bar → divider → ring section → divider → Best Joy strip → (group-only) divider → members section.
- D-04 Best Joy strip 9/14/9 typography lives **OUTSIDE** `AppTextStyles` (per UI-SPEC line 89-91); use inline `TextStyle` with `fontFeatures: const [FontFeature.tabularFigures()]` on the ¥amount text (Pitfall #10).
- The whole-card single `onTap` (D-11) — sub-widgets MUST NOT install nested `GestureDetector`s that absorb the tap (Pitfall #3 — set inner sub-tap targets to `behavior: HitTestBehavior.translucent` or omit GestureDetector).
- ⓘ icons absorb taps via `behavior: HitTestBehavior.opaque` so card-tap doesn't fire when tooltip is requested.

**Trend chip pattern** (verbatim from `month_overview_card.dart` lines 36-40 + 79-104):
```dart
// month_overview_card.dart:36-40 — arithmetic
final trend = previousMonthTotal > 0
    ? ((totalExpense - previousMonthTotal) / previousMonthTotal * 100).round()
    : 0;
final trendText = trend <= 0 ? '$trend%' : '+$trend%';

// month_overview_card.dart:79-104 — pill + icon
Container(
  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  decoration: BoxDecoration(
    color: AppColors.oliveLight,
    borderRadius: BorderRadius.circular(999),
  ),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        trend <= 0 ? Icons.trending_down : Icons.trending_up,
        size: 14,
        color: AppColors.olive,
      ),
      const SizedBox(width: 4),
      Text(
        trendText,
        style: AppTextStyles.bodySmall.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.olive,
        ),
      ),
    ],
  ),
)
```

**Adaptation notes:**
- D-09 empty state: when `previousMonthTotal == 0` AND `totalExpense == 0`, the trend chip is HIDDEN entirely — do not render the pill at all (UI-SPEC line 223). The existing `0%` fallback at `month_overview_card.dart:39` is replaced by visibility gate.

**Currency formatting pattern** (eliminates Pitfall #1 hardcoded `'JPY'`):
```dart
// CORRECT — uses currencyCode from constructor (sourced via D-12 bookByIdProvider at parent)
const formatter = FormatterService();
final formatted = formatter.formatCurrency(amount, currencyCode, locale);

// WRONG — soul_fullness_card.dart:160-164 (DO NOT copy this part — eliminate the violation):
//   const FormatterService().formatCurrency(recentSoulAmount, 'JPY', locale),
```

**Sealed-class MetricResult pattern matching** (from `lib/features/analytics/domain/models/metric_result.dart` lines 6-14 docstring):
```dart
return switch (joyPerYen) {
  Empty() => Text(
      S.of(context).homeNoSoulDataLegend,
      style: AppTextStyles.bodyMedium.copyWith(color: context.wmTextSecondary),
    ),
  Value(:final data, sampleSize: _) => Text(
      formatJoyDensity(data, currencyCode),
      style: AppTextStyles.amountSmall.copyWith(color: AppColors.soul),
    ),
};
```

**Forbidden in this file (Pitfall guards):**
- ❌ Hardcoded `'JPY'` (Pitfall #1; grep guard at commit time)
- ❌ Any `%` glyph adjacent to "魂"/"生存"/"soul"/"survival" labels (Pitfall #2; reverts D-02)
- ❌ More than 2 `Icons.info_outline` instances (Pitfall #4; HOMEUI-04 hard cap)
- ❌ Generic `TextStyle()` for monetary values without `fontFeatures: tabularFigures` (Pitfall #10; CLAUDE.md Amount Display Style)
- ❌ `(... as Value).data` casts on `MetricResult` (Pitfall #6; use sealed switch)

---

### 2. `painter/happiness_rings_painter.dart` (NEW) — utility, transform

**No analog in codebase.** Codebase grep: `CustomPainter`, `extends CustomPainter`, `Canvas.drawArc`, `SweepGradient`, `RadialGradient` all return zero matches in `lib/`.

**Falls back to canonical Flutter pattern** (verbatim from RESEARCH §"Pattern 3", lines 379-447 of 10-RESEARCH.md):

```dart
import 'dart:math' show pi;
import 'package:flutter/material.dart';

class HappinessRingsPainter extends CustomPainter {
  const HappinessRingsPainter({
    required this.outerSweepRatio,    // 0..1; null = Empty (track only)
    required this.middleSweepRatio,
    required this.innerSweepRatio,
    required this.outerGradient,      // SweepGradient
    required this.middleGradient,
    required this.innerGradient,
    required this.trackColor,
    this.strokeWidth = 8,             // CONTEXT spec
    this.ringGap = 4,                 // CONTEXT spec
  });

  final double? outerSweepRatio;
  final double? middleSweepRatio;
  final double? innerSweepRatio;
  final SweepGradient outerGradient;
  final SweepGradient middleGradient;
  final SweepGradient innerGradient;
  final Color trackColor;
  final double strokeWidth;
  final double ringGap;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radii = [
      size.width / 2 - strokeWidth / 2,
      size.width / 2 - strokeWidth / 2 - (strokeWidth + ringGap),
      size.width / 2 - strokeWidth / 2 - 2 * (strokeWidth + ringGap),
    ];
    final ratios = [outerSweepRatio, middleSweepRatio, innerSweepRatio];
    final gradients = [outerGradient, middleGradient, innerGradient];

    for (var i = 0; i < 3; i++) {
      final r = radii[i];
      final rect = Rect.fromCircle(center: center, radius: r);

      final trackPaint = Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, 2 * pi, false, trackPaint);

      final ratio = ratios[i];
      if (ratio != null && ratio > 0) {
        final fillPaint = Paint()
          ..shader = gradients[i].createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;
        const startAngle = -pi / 2;       // 12 o'clock
        final sweepAngle = ratio.clamp(0.0, 1.0) * 2 * pi;
        canvas.drawArc(rect, startAngle, sweepAngle, false, fillPaint);
      }
    }
  }

  @override
  bool shouldRepaint(HappinessRingsPainter old) =>
      outerSweepRatio != old.outerSweepRatio
      || middleSweepRatio != old.middleSweepRatio
      || innerSweepRatio != old.innerSweepRatio
      || trackColor != old.trackColor;
}
```

**Source citations:**
- Flutter API docs `api.flutter.dev` — `Canvas.drawArc(rect, startAngle, sweepAngle, useCenter, paint)` + `SweepGradient.createShader(rect)`
- Flutter dev `docs.flutter.dev/flutter-for/uikit-devs` — `CustomPainter` signature + `shouldRepaint` semantics
- Both [CITED via Context7 fetch 2026-05-02 — see RESEARCH §Sources line 955-956]

**Performance pattern (RESEARCH lines 451-455):**
- Wrap the `CustomPaint` widget in `RepaintBoundary` to isolate the rings from rebuilds in the rest of the card.
- `shouldRepaint` returns `false` when sweep ratios + track color are equal — Freezed aggregates have value equality; falls through cleanly.
- For `Empty<T>()` rings: pass `null` ratio → painter draws ONLY the track (per D-09 + Claude's Discretion bullet 5).

**Adaptation notes for sweep ratio computation (placed in `home_hero_card.dart` builder, NOT in painter):**
```dart
// RESEARCH Pattern 4 — sweep-ratio normalization (Joy/¥ outer ring, single mode)
double? _outerSweepRatio({
  required MetricResult<double> joyPerYen,
  required MetricResult<double>? lastMonthJoyPerYen,
}) {
  return switch (joyPerYen) {
    Empty() => null,
    Value(:final data) => switch (lastMonthJoyPerYen) {
      Value(data: final prev) when prev > 0 => (data / prev).clamp(0.0, 1.0),
      _ => (data / 2.0).clamp(0.0, 1.0),
    },
  };
}
```

A7-flagged open question: planner picks fallback (`/2.0` normalized) vs. add prev-month query — recommend fallback for Phase 10 minimal scope (RESEARCH line 476).

**Forbidden in this file:**
- ❌ Reading `MetricResult.data` without sealed pattern match (Pitfall #6 — NaN risk)
- ❌ Defaulting to `0.0` for `Empty<double>` (Pitfall #7 — must show empty copy, never "0.0")

---

### 3. `home_screen.dart` (MODIFY) — screen, request-response (self-analog)

**Self-analog:** Existing async-when patterns at lines 88-105, 113-128, 132-143 — keep the **shape** of these blocks; collapse them into a single multi-`when()` chain per RESEARCH Example 4 (lines 656-708).

**Existing `reportAsync.when` block** (verbatim from `home_screen.dart` lines 88-105 — to be REPLACED by single `HomeHeroCard` block):
```dart
reportAsync.when(
  data: (report) {
    final shadowData = shadowAsync.valueOrNull;
    return MonthOverviewCard(
      totalExpense:
          report.totalExpenses + (shadowData?.totalExpenses ?? 0),
      previousMonthTotal:
          (report.previousMonthComparison?.previousExpenses ??
              0) +
          (shadowData?.prevTotalExpenses ?? 0),
    );
  },
  loading: () => const SizedBox(
    height: 120,
    child: Center(child: CircularProgressIndicator()),
  ),
  error: (error, _) => _ErrorText(message: '$error'),
),
```

**Existing `_ErrorText` widget** (verbatim from `home_screen.dart` lines 371-386 — REUSE as-is):
```dart
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Error: $message',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }
}
```

**DELETE excerpts** (verbatim — must be removed and not reappear):
- `home_screen.dart` lines 258-324: `_buildLedgerRows()` method (66 lines).
- `home_screen.dart` lines 345-359: `_computeSatisfaction()` method (14 lines).
- `home_screen.dart` lines 362-367: `_computeHappinessROI()` method (5 lines).
- `home_screen.dart` lines 17, 23-24, 26 imports: `'../models/ledger_row_data.dart'`, `'../widgets/ledger_comparison_section.dart'`, `'../widgets/month_overview_card.dart'`, `'../widgets/soul_fullness_card.dart'` — replace with single `'../widgets/home_hero_card.dart'` import.

**Adaptation notes (Pitfall #11 — net DECREASE):**
- After Phase 10, `wc -l home_screen.dart` MUST return < 386 (current count). Plan unit's PR check enforces.
- Pre-commit grep verifies `_computeHappinessROI`, `_computeSatisfaction`, `_buildLedgerRows` return 0 matches.
- The existing `+X% trend chip arithmetic` math (`((current-prev)/prev*100).round()`) is preserved by `MonthOverviewCard` deletion — re-encoded inside `HomeHeroCard` per Pattern 1 above.
- Group-mode totals: existing aggregation `report.totalExpenses + (shadowData?.totalExpenses ?? 0)` (line 92-93) is preserved per RESEARCH "State of the Art" note line 806; the math moves into the `HomeHeroCard`'s hero-header builder.

**Tap navigation pattern (D-11 minimum viable per A3 + Pitfall #9):**
```dart
onTap: () => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => AnalyticsScreen(bookId: bookId),
  ),
),
```
NOT `AnalyticsScreen(initialRegion: AnalyticsRegion.joyLedger)` — `AnalyticsRegion` enum does not exist (A3 verified `analytics_screen.dart:25` constructor signature is `({super.key, required this.bookId})`); Phase 11 introduces the enum and refactors this call site.

---

### 4. `bookByIdProvider` in `repository_providers.dart` (MODIFY) — provider, CRUD-read

**Analog:** `lib/features/analytics/presentation/providers/state_happiness.dart` lines 16-30 (parametrized `@riverpod` use case provider).

**Pattern excerpt** (verbatim from `state_happiness.dart` lines 14-30):
```dart
/// HAPPY-01..04 personal happiness report.
@riverpod
Future<HappinessReport> happinessReport(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getHappinessReportUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
    currencyCode: currencyCode,
  );
}
```

**Repository-watch pattern** (verbatim from `repository_providers.dart` lines 47-52 — same file the new provider goes into):
```dart
/// BookRepository provider.
@riverpod
BookRepository bookRepository(Ref ref) {
  final database = ref.watch(app_accounting.appAppDatabaseProvider);
  final dao = BookDao(database);
  return BookRepositoryImpl(dao: dao);
}
```

**New provider to add** (synthesis — NOT verbatim, follows the two patterns above):
```dart
/// Resolves a Book by ID for currency-code lookup (D-12).
/// Use case: HomeHeroCard needs `Book.currency` to eliminate hardcoded 'JPY'.
@riverpod
Future<Book?> bookById(Ref ref, {required String bookId}) async {
  final repo = ref.watch(bookRepositoryProvider);
  return repo.findById(bookId);
}
```

**Adaptation notes:**
- A1 (RESEARCH line 812) verified `bookByIdProvider` does not exist; only `bookRepositoryProvider` + `findById(id)` interface.
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding — generates updated `repository_providers.g.dart`.
- `provider_graph_hygiene_test.dart` (test/architecture) validates no `UnimplementedError` providers — this provider passes by definition (it just delegates).

---

### 5. ARB key additions in `app_{ja,zh,en}.arb` (MODIFY) — config, n/a

**Analog:** `app_en.arb` lines 523-531 (existing `homePreviousMonthAmount` block with `{amount}` placeholder).

**Pattern excerpt** (verbatim from `app_en.arb` lines 523-531):
```jsonc
"homePreviousMonthAmount": "Last month {amount}",
"@homePreviousMonthAmount": {
  "description": "Previous month amount subtitle for home ledger rows",
  "placeholders": {
    "amount": {
      "type": "String"
    }
  }
}
```

**Simple-key pattern** (verbatim from `app_en.arb` lines 553-556 — no placeholders):
```jsonc
"homeSoulFullness": "Soul Fullness",
"@homeSoulFullness": {
  "description": "Soul fullness section title"
}
```

**Adaptation notes:**
- Phase 10 adds 21 new keys — full list in UI-SPEC `## Copywriting Contract` section + RESEARCH `## i18n Strategy`.
- ALL 3 ARB files (ja/zh/en) MUST be updated atomically (Pitfall #5 — ARB-parity CI guardrail at `test/architecture/arb_key_parity_test.dart` enforces).
- Run `flutter gen-l10n` after ARB updates (regenerates `lib/generated/app_localizations.dart`).
- Commit ARB triplet + regenerated `app_localizations.dart` together (avoid AUDIT-10 stale-generated-files failure).
- Existing `homeBestJoyAmountSat` template uses placeholders — follow the `homePreviousMonthAmount` placeholder pattern for `{amount}` and `{sat}`.

**Forbidden in this change:**
- ❌ Renaming existing ARB **keys** (Phase 12 RENAME-* scope; Phase 10 only ADDS).
- ❌ Adding a key to one or two ARB files but not all three (Pitfall #5).

---

### 6. `home_hero_card_test.dart` (NEW) — test, request-response

**Primary analog:** `test/widget/features/home/presentation/screens/home_screen_test.dart` (ProviderScope + mocktail + provider overrides).
**Secondary analog:** `test/widget/features/home/presentation/widgets/soul_fullness_card_test.dart` (pure widget, locale variants, `find.text` + tabular figures + `onTap` callback).

**Imports + setUp pattern** (verbatim from `home_screen_test.dart` lines 1-50):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/features/analytics/domain/models/monthly_report.dart';
// ... domain models for HappinessReport, FamilyHappiness, etc.
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_localizations.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

final _mockReport = MonthlyReport(
  year: 2026,
  month: 2,
  totalIncome: 300000,
  totalExpenses: 142800,
  savings: 157200,
  savingsRate: 52.4,
  survivalTotal: 102200,
  soulTotal: 40600,
  categoryBreakdowns: [],
  dailyExpenses: [],
);
```

**ProviderScope+overrides build pattern** (verbatim from `home_screen_test.dart` lines 52-70):
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
```

**Pure-widget direct-instantiation pattern** (verbatim from `soul_fullness_card_test.dart` lines 10-23):
```dart
Widget buildSubject({Locale locale = const Locale('ja')}) {
  return testLocalizedApp(
    locale: locale,
    child: const Scaffold(
      body: SingleChildScrollView(
        child: SoulFullnessCard(
          satisfactionPercent: 60,
          happinessROI: 4.6,
          recentSoulAmount: 12800,
        ),
      ),
    ),
  );
}
```

**Tabular figures assertion pattern** (verbatim from `soul_fullness_card_test.dart` lines 59-70):
```dart
testWidgets('renders recent soul amount with tabular figures', (tester) async {
  await tester.pumpWidget(buildSubject());
  final amountText = tester.widget<Text>(find.textContaining('12,800'));
  expect(
    amountText.style?.fontFeatures,
    contains(const FontFeature.tabularFigures()),
  );
});
```

**onTap assertion pattern** (verbatim from `soul_fullness_card_test.dart` lines 72-94):
```dart
testWidgets('invokes onTap callback', (tester) async {
  var tapped = false;
  await tester.pumpWidget(/* ... with onTap: () => tapped = true */);
  await tester.tap(find.byType(SoulFullnessCard));
  expect(tapped, isTrue);
});
```

**Adaptation notes:**
- `HomeHeroCard` is a **pure StatelessWidget** per UI-SPEC line 277 — testable WITHOUT `ProviderScope` (use the `soul_fullness_card_test.dart` direct-instantiation pattern, NOT the `home_screen_test.dart` provider-override pattern).
- Test groups required (RESEARCH "Phase Requirements → Test Map"):
  - `single mode renders` (HOMEUI-01)
  - `group mode renders with N members` (HOMEUI-03 + HOMEUI-07)
  - 4 empty states: `totalExpenses=0` / `totalSoulTx=0` / thin sample / all-neutral CTA (D-09)
  - `exactly 2 info icons` (HOMEUI-04 hard cap)
  - `tap target invokes onTap once` (D-11 + Pitfall #3)
  - `info icon tap shows tooltip without firing card onTap` (D-10 + Pitfall #3)
  - `coverage caption visible with thin sample` (HAPPY-06 + HOMEUI-04)
- Forbidden-phrase grep can run as a `setUpAll` shell-out OR a separate architecture test (parallel to `test/architecture/hardcoded_cjk_ui_scan_test.dart`).

---

### 7. `home_hero_card_golden_test.dart` (NEW) — test (golden)

**Primary analog:** `test/golden/soul_fullness_card_golden_test.dart` (single-file fixed-size wrap).
**Secondary analog:** `test/golden/summary_cards_golden_test.dart` (locale variants + multi-test group).

**Wrap helper pattern** (verbatim from `summary_cards_golden_test.dart` lines 26-41):
```dart
Widget _wrap({required Locale locale, required Widget child}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: locale,
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: S.supportedLocales,
    home: Scaffold(
      body: SizedBox(width: 600, height: 280, child: child),
    ),
  );
}
```

**matchesGoldenFile pattern** (verbatim from `summary_cards_golden_test.dart` lines 45-57):
```dart
testWidgets('Japanese (ja) — 収入/支出/貯蓄 with JPY formatting', (tester) async {
  await tester.pumpWidget(
    _wrap(
      locale: const Locale('ja'),
      child: const SummaryCards(report: _summaryReport),
    ),
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(SummaryCards),
    matchesGoldenFile('goldens/summary_cards_ja.png'),
  );
});
```

**Adaptation notes:**
- Phase 10 needs 5+ goldens (RESEARCH line 907):
  - `home_hero_card_single_light_ja.png`
  - `home_hero_card_family_light_ja.png`
  - `home_hero_card_family_dark_ja.png`
  - `home_hero_card_thin_sample_ja.png`
  - `home_hero_card_all_neutral_cta_ja.png`
- Increase `SizedBox` to fit the integrated card (recommend `width: 600, height: 720` for single-light; `height: 920` for group with 3 members — planner verifies against rendered output).
- Dark theme: wrap in `Theme(data: ThemeData.dark(), child: ...)` OR set `MaterialApp(theme: ThemeData.light(), darkTheme: ThemeData.dark(), themeMode: ThemeMode.dark)`.
- Member fixtures use synthetic names (`memberDisplayName: 'TestMember1'` etc.) per security checklist (RESEARCH line 938).

---

### 8. `happiness_rings_painter_test.dart` (NEW) — test (painter unit, mocktail-on-Canvas)

**No analog in `test/`.** Codebase grep returns zero matches for `mocktail`-mocked `Canvas`. Falls back to mocktail idiom.

**Pattern (synthesis, follows `mocktail` standard pattern + Flutter `flutter_test` `paint()` invocation):**
```dart
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/home/presentation/widgets/painter/happiness_rings_painter.dart';
import 'package:mocktail/mocktail.dart';

class _MockCanvas extends Mock implements Canvas {}

class _FakeRect extends Fake implements Rect {}
class _FakePaint extends Fake implements Paint {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRect());
    registerFallbackValue(_FakePaint());
  });

  group('HappinessRingsPainter', () {
    test('Empty ring: track only, no fill arc', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(colors: [Colors.green, Colors.greenAccent]);
      final painter = HappinessRingsPainter(
        outerSweepRatio: null,
        middleSweepRatio: null,
        innerSweepRatio: null,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      // Each ring: 1 track arc, 0 fill arc → 3 total drawArc calls.
      verify(() => canvas.drawArc(any(), 0, 2 * pi, false, any())).called(3);
    });

    test('Value ring: track + fill arc with sweep ratio', () {
      final canvas = _MockCanvas();
      const gradient = SweepGradient(colors: [Colors.green, Colors.greenAccent]);
      final painter = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: null,
        innerSweepRatio: null,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      painter.paint(canvas, const Size(120, 120));
      // 3 track arcs + 1 fill arc = 4 drawArc calls.
      verify(() => canvas.drawArc(any(), any(), any(), false, any())).called(4);
    });

    test('shouldRepaint returns false when inputs equal', () {
      const gradient = SweepGradient(colors: [Colors.green, Colors.greenAccent]);
      final p1 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      final p2 = HappinessRingsPainter(
        outerSweepRatio: 0.5,
        middleSweepRatio: 0.5,
        innerSweepRatio: 0.5,
        outerGradient: gradient,
        middleGradient: gradient,
        innerGradient: gradient,
        trackColor: const Color(0xFFEFEFEF),
      );
      expect(p1.shouldRepaint(p2), isFalse);
    });
  });
}
```

**Source:** RESEARCH §"Validation Architecture" line 889; mocktail standard pattern from `pub.dev/packages/mocktail` API. [CITED via existing project use of mocktail at `home_screen_test.dart:20` + `infrastructure/sync/*_test.dart`]

---

## Shared Patterns

### Authentication / Authorization

**Source:** N/A — Phase 10 is read-only UI; no auth surface.
**Apply to:** No files.

### Error Handling

**Source:** `lib/features/home/presentation/screens/home_screen.dart` lines 371-386 (existing `_ErrorText` widget).
**Apply to:** `home_screen.dart` modifications (the existing `_ErrorText` is reused as-is — no changes).
```dart
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Error: $message',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }
}
```

**Note:** RESEARCH §"Security Domain" line 929 flags `'Error: $error'` as raw-exception interpolation that *could* leak detail; existing project precedent accepts this — Phase 10 follows same. No fix needed unless reviewer flags PII concern.

### Validation / Input

**Source:** N/A — Phase 10 has no user input forms. Only ARB string literals; validated by `flutter gen-l10n`.

### Currency Formatting (D-12 — eliminates Pitfall #1)

**Source:** `lib/application/i18n/formatter_service.dart:56` — `FormatterService().formatCurrency(amount, currencyCode, locale)`.
**Apply to:** All ¥ amount renders in `home_hero_card.dart` + sub-widgets.
```dart
const formatter = FormatterService();
final formatted = formatter.formatCurrency(amount, currencyCode, locale);
// ✅ currencyCode comes from bookByIdProvider; never literal 'JPY'
```

### Joy Density Display (Phase 9 D-20)

**Source:** `lib/infrastructure/i18n/formatters/joy_density_formatter.dart:30` — `formatJoyDensity(rawDensity, currencyCode)`.
**Apply to:** Joy/¥ legend value text in `home_hero_card.dart` ring section.
```dart
final displayText = formatJoyDensity(rawDensity, currencyCode);
// JPY: "1.2 / ¥1k"   CNY: "1.2 / ¥100"   USD: "1.2 / $1"
```

### Sealed `MetricResult<T>` Pattern Matching

**Source:** `lib/features/analytics/domain/models/metric_result.dart` lines 6-14 (docstring + sealed class).
**Apply to:** Every `MetricResult<T>` consumption site in `home_hero_card.dart` (rings, legend rows, Best Joy strip).
```dart
return switch (result) {
  case Empty(): renderEmpty();
  case Value(:final data, :final sampleSize): renderValue(data, sampleSize);
};
```

### Container Widget With Async Provider

**Source:** `lib/features/home/presentation/screens/home_screen.dart` lines 88-105 / 113-128 / 132-143.
**Apply to:** `home_screen.dart` modification — the parent screen does ALL `AsyncValue.when()` resolution; `HomeHeroCard` is a pure StatelessWidget receiving resolved Freezed aggregates.
- See RESEARCH §"Pattern 1" + Example 4 (lines 656-708) for the deeply-nested `.when()` chain proposal. Refactor opportunity (planner discretion): extract to `_buildHomeHeroCardSection(...)` private helper.

### Widget Parameter Pattern (CLAUDE.md Pitfall #9)

**Source:** Phase 9 `state_happiness.dart:21` — `currencyCode: String` parameter (not nullable, not defaulted).
**Apply to:** `HomeHeroCard` constructor — every parameter `final` and required (or explicitly nullable for single-mode optionals like `family`, `shadowBooks`).
```dart
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    required this.report,
    required this.happiness,
    required this.bestJoy,
    required this.family,            // null in single mode
    required this.shadowBooks,        // null/empty in single mode
    required this.shadowAggregate,    // null in single mode
    required this.currencyCode,      // ✅ NOT 'JPY' literal
    required this.locale,
    required this.isGroupMode,
    required this.onTap,
    super.key,
  });
}
```

### Theme Tokens (D-13 — color polish deferred to last plan unit)

**Source:** `lib/core/theme/app_colors.dart` (locked accents) + `lib/core/theme/app_theme_colors.dart` extension (`context.wm*`).
**Apply to:** All color references in `home_hero_card.dart` + painter.
- Accents: `AppColors.soul` / `survival` / `accentPrimary` / `olive` / `shared` / `oliveLight` / `sharedBorder` / `sharedChevron`.
- Theme-aware: `context.wmCard` (surface), `wmBorderDefault` (outer stroke), `wmBackgroundDivider` (1px dividers + ring track), `wmTextPrimary/Secondary/Tertiary`, `wmBackgroundSubtle`.

### Tabular Figures Gate (CLAUDE.md "Amount Display Style")

**Source:** `lib/core/theme/app_text_styles.dart` lines 145-168 (`amountLarge/Medium/Small` with `fontFeatures: _tabularFigures`).
**Apply to:** All ¥ amount text in `home_hero_card.dart`.
- Hero total → `AppTextStyles.amountLarge`
- Member spending + ring center text → `AppTextStyles.amountMedium`
- Best Joy small line ¥amount (fontSize 9 outside the standard scale) → inline `TextStyle(fontSize: 9, fontWeight: FontWeight.w500, fontFeatures: const [FontFeature.tabularFigures()])` (Pitfall #10 — manual reviewer's gate).

### Tap-Target Hygiene (D-11 + Pitfall #3)

**Source:** `lib/features/home/presentation/widgets/soul_fullness_card.dart` lines 31-32 (whole-card `GestureDetector`).
**Apply to:** Outer card root in `home_hero_card.dart`.
- Single root `GestureDetector(onTap: onTap, child: Container(...))`.
- Inner sub-widgets MUST NOT install nested `GestureDetector`s with their own `onTap` (would absorb the parent tap).
- ⓘ icon taps absorb propagation: wrap with `GestureDetector(behavior: HitTestBehavior.opaque, onTap: () => showTooltip(...))` so the card-level onTap doesn't fire when tooltip is requested.

### Tooltip Implementation (D-10 — exactly 2)

**Source:** `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart:94` + `lib/features/settings/presentation/widgets/voice_section.dart:38` (existing `showDialog<void>` patterns in the codebase).
**Apply to:** ⓘ icon tap behavior in `home_hero_card.dart` ring section title + Joy/¥ legend.
- Recommendation: `showDialog<void>(...)` with a small explainer dialog (matches existing project convention; UI-SPEC OQ #6 + RESEARCH OQ #4 recommend dialog over `Tooltip` widget for tap-to-explain UX).
- A5 (RESEARCH line 816): no shared `InfoIconButton` exists; introduce a private `_InfoIcon` inside `home_hero_card.dart` (or `_show...Dialog` helper). Deferred to v1.2 for shared component.

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/home/presentation/widgets/painter/happiness_rings_painter.dart` | utility (CustomPainter) | transform | Codebase grep: `CustomPainter`, `extends CustomPainter`, `Canvas.drawArc`, `SweepGradient`, `RadialGradient` all return zero matches in `lib/`. RESEARCH line 193 explicitly notes `fl_chart` exists but lacks SweepGradient stop-control on stroked arcs — `CustomPainter` is the simpler/more-flexible path. **Falls back to canonical Flutter pattern** from `api.flutter.dev` (Canvas.drawArc + SweepGradient) and `docs.flutter.dev/flutter-for/uikit-devs` (CustomPainter signature) — both [CITED via Context7 fetch 2026-05-02 — RESEARCH line 449 + 956]. |
| `test/widget/features/home/presentation/widgets/painter/happiness_rings_painter_test.dart` | test (painter unit) | transform | No `Canvas`-mock test exists in `test/`. Falls back to mocktail standard pattern (`class _MockCanvas extends Mock implements Canvas`) — mocktail is already in `dev_dependencies` per `home_screen_test.dart:20`. Pattern documented above in §6. |

---

## Metadata

**Analog search scope:**
- `lib/features/home/presentation/widgets/` (all existing widgets)
- `lib/features/home/presentation/screens/home_screen.dart`
- `lib/features/analytics/presentation/providers/state_happiness.dart` (Phase 9 contracts consumer-side)
- `lib/features/analytics/presentation/providers/repository_providers.dart`
- `lib/features/accounting/presentation/providers/repository_providers.dart`
- `lib/features/analytics/domain/models/{metric_result,happiness_report,family_happiness}.dart`
- `lib/core/theme/app_colors.dart`, `app_text_styles.dart`, `app_theme_colors.dart`
- `lib/application/i18n/formatter_service.dart`
- `lib/infrastructure/i18n/formatters/{date_formatter,joy_density_formatter}.dart`
- `lib/l10n/app_{ja,zh,en}.arb` (existing key/placeholder patterns)
- `test/widget/features/home/presentation/widgets/{soul_fullness_card,month_overview_card,hero_header}_test.dart`
- `test/widget/features/home/presentation/screens/home_screen_test.dart`
- `test/golden/{soul_fullness_card,summary_cards,amount_display}_golden_test.dart`
- `test/widget/features/home/helpers/test_localizations.dart`

**Files scanned:** ~25 production + 8 test files
**Pattern extraction date:** 2026-05-02
**Dominant pattern themes:**
1. All controllers/widgets use `GestureDetector → Container(decoration: BoxDecoration(...))` outer scaffold (verbatim from `soul_fullness_card.dart:31-39`).
2. All ¥ amounts use `AppTextStyles.amountLarge/Medium/Small` (CLAUDE.md mandatory gate).
3. Provider wiring follows `@riverpod` codegen with `Ref ref` first param + named required params (state_happiness.dart pattern).
4. Tests use `testLocalizedApp` helper for locale-aware widget instantiation (test/widget/features/home/helpers/test_localizations.dart).
5. Golden tests use a `_wrap({locale, child})` helper around `MaterialApp` + `Scaffold` + fixed `SizedBox` (summary_cards_golden_test.dart pattern).
6. Sealed `MetricResult<T>` Dart-3 pattern matching is documented in the model file's docstring; Phase 10 establishes the consumer-side precedent (no existing usage in `lib/`).
