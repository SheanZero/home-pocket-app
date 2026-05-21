# Phase 13: ADR-016 Backend Foundation - Pattern Map

**Mapped:** 2026-05-19
**Files analyzed:** 14 (8 new/created, 5 modified, 1 settings-impacting Freezed model)
**Analogs found:** 14 / 14 (every file has a direct in-repo analog)

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` (NEW) | use case (application) | request-response, batch fold | `lib/application/analytics/get_happiness_report_use_case.dart` | exact (sibling, same constructor/PTVF shape) |
| `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart` (NEW) | infrastructure formatter | transform | `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` (being deleted) | exact (verbatim PTVF base map transfer) |
| `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` (NEW) | unit test | request-response | `test/unit/application/analytics/get_happiness_report_use_case_test.dart` | exact (mocktail + `valueMetric/emptyMetric` helpers) |
| `test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart` (NEW) | unit test | transform | `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` (being deleted) | exact |
| `lib/features/settings/domain/models/app_settings.dart` (MODIFIED — add `monthlyJoyTarget: int?`) | model (domain) | n/a | itself (extend existing `@freezed` shape) | exact |
| `lib/features/settings/domain/repositories/settings_repository.dart` (MODIFIED — add setter/getter) | repository interface (domain) | CRUD | itself (`setVoiceLanguage` pattern) | exact |
| `lib/data/repositories/settings_repository_impl.dart` (MODIFIED — add key + setter + read) | repository impl (data) | CRUD (SharedPreferences) | itself (`_voiceLanguageKey` / `setVoiceLanguage`) | exact |
| `lib/application/analytics/get_happiness_report_use_case.dart` (MODIFIED — formula + field rename) | use case (application) | request-response | itself | self-modification |
| `lib/features/analytics/domain/models/happiness_report.dart` (MODIFIED — `joyPerYen` → `joyContribution`) | model (domain) | n/a | itself | self-modification (single field rename) |
| `lib/features/analytics/presentation/providers/state_happiness.dart` (MODIFIED — drop `dailyJoyPerYen`, add `monthlyJoyTargetRecommendation`) | Riverpod provider (presentation) | provider-graph | sibling `bestJoyMoment` provider in same file | exact |
| `lib/features/analytics/presentation/providers/repository_providers.dart` (MODIFIED — drop daily, add recommendation use case provider) | Riverpod use case provider | provider-graph | itself (`getBestJoyMomentUseCase` sibling) | exact |
| `lib/features/home/presentation/widgets/home_hero_card.dart` (MODIFIED — 4 touch-points) | widget (presentation) | event-driven (consumer) | itself | self-modification |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` (MODIFIED — delete `_JoyTrendOrFallback`, fix `_SatisfactionHistogramOrFallback`) | screen (presentation) | provider-graph | itself; gate replacement uses `happinessReportProvider` (already present in same file) | partial (self) |
| `lib/data/daos/analytics_dao.dart` (MODIFIED — rename `getSoulRowsForPtvf` → `getSoulRowsForJoyContribution`, delete `getDailySoulRowsForPtvf`) | DAO (data) | CRUD (read) | itself | self-modification |
| `lib/data/repositories/analytics_repository_impl.dart` + `analytics_repository.dart` interface (MODIFIED — mirror DAO rename) | repository delegation | CRUD (read) | itself | self-modification |
| `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` (NEW Markdown) | planning artifact | n/a | no analog needed | n/a |

---

## Pattern Assignments

### `lib/application/analytics/get_monthly_joy_target_recommendation_use_case.dart` (use case, request-response + batch fold)

**Analog:** `lib/application/analytics/get_happiness_report_use_case.dart`

**Imports pattern** (analog lines 1-8) — `import 'dart:math' as math;` + relative imports up two levels to `../../features/.../domain/...` + `../../infrastructure/i18n/formatters/...`:
```dart
import 'dart:math' as math;

import '../../features/analytics/domain/models/analytics_aggregate.dart';
import '../../features/analytics/domain/models/metric_result.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
```
Note: do NOT import `best_joy_moment_row.dart` or `happiness_report.dart` — the recommendation use case is independent.

**Constructor + repo field pattern** (analog lines 16-23):
```dart
class GetHappinessReportUseCase {
  GetHappinessReportUseCase({required AnalyticsRepository analyticsRepository})
    : _repo = analyticsRepository;

  final AnalyticsRepository _repo;

  /// D-04: Kahneman & Tversky 1979 PTVF empirical fit.
  static const double _ptvfAlpha = 0.88;
```
Reproduce verbatim, add `static const int _fallbackBaseline = 50;` (SPIKE-DECIDED — D-06).

**execute signature pattern** (analog lines 28-35) — named params for `bookId` + currency + date anchor; first-of-month / end-of-month math:
```dart
Future<HappinessReport> execute({
  required String bookId,
  required int year,
  required int month,
  required String currencyCode,
}) async {
  final startDate = DateTime(year, month, 1);
  final endDate = DateTime(year, month + 1, 0, 23, 59, 59);
```
For the new use case, replace `year/month` with `required DateTime asOf` (per CONTEXT D-04: clock injection). Compute the three past months via `DateTime(asOf.year, asOf.month - offset, 1)` — Dart's `DateTime` normalizes negative months across year boundaries (verified by RESEARCH §Sampling Strategy #4).

**Empty fast-path pattern** (analog lines 67-79) — returns `Empty<T>()` const when sample size insufficient:
```dart
if (totalSoulTx == 0) {
  return HappinessReport(
    ...
    joyPerYen: const Empty(),
    ...
  );
}
```
For recommendation: `if (monthSums.length < 3) return const Empty();` returns `MetricResult<int>`.

**PTVF fold pattern (the one that survives — convert to no-denominator form)** (analog lines 99-111):
```dart
double _computePtvfDensity(List<SoulRowSample> rows, double base) {
  if (rows.isEmpty) return 0;
  var numerator = 0.0;
  var denominator = 0;
  for (final r in rows) {
    final scaled = math.pow(r.amount / base, _ptvfAlpha).toDouble();
    numerator += r.soulSatisfaction * scaled;
    denominator += r.amount;
  }
  if (denominator == 0) return 0;
  return numerator / denominator;
}
```
New form for `_computeJoyContribution` (delete denominator, keep numerator) — applies to BOTH the modified `GetHappinessReportUseCase` AND the new recommendation use case's per-month fold:
```dart
double _computeJoyContribution(List<SoulRowSample> rows, double base) {
  if (rows.isEmpty) return 0;
  var sum = 0.0;
  for (final r in rows) {
    sum += r.soulSatisfaction * math.pow(r.amount / base, _ptvfAlpha).toDouble();
  }
  return sum;
}
```
Median of exactly 3 values: `sorted[1]` is always the median (see RESEARCH "Don't Hand-Roll" table).

**Return value pattern** (analog lines 86-96) — wraps `MetricResult<T>` with `Value(data, sampleSize)`:
```dart
return Value(median.ceil(), 3);  // sampleSize = 3 qualified months
```

---

### `lib/infrastructure/i18n/formatters/joy_cumulative_formatter.dart` (formatter, transform)

**Analog:** `lib/infrastructure/i18n/formatters/joy_density_formatter.dart` (being deleted — its `_ptvfBaseByCurrency` map and `ptvfBaseFor()` function MUST be preserved verbatim).

**Preserved verbatim (analog lines 11-15, 25-27):**
```dart
// D-20 names this map _PTVF_BASE_BY_CURRENCY; Dart style requires lower camel.
const Map<String, double> _ptvfBaseByCurrency = {
  'JPY': 500.0,
  'CNY': 25.0,
  'USD': 5.0,
};

/// PTVF base for [currencyCode], defaulting to JPY's 500.0 base.
double ptvfBaseFor(String currencyCode) =>
    _ptvfBaseByCurrency[currencyCode] ?? 500.0;
```

**Deleted from analog (no longer needed in cumulative formatter):**
- `_displayUnitByCurrency` map (lines 18-23) — gone (no per-¥ suffix label in cumulative).
- `formatJoyDensity` (lines 30-36) — replaced.

**New function shape** (replaces `formatJoyDensity`) — integer + locale thousand separator. Use `intl 0.20.2`'s `NumberFormat.decimalPattern('en')` (RESEARCH "Don't Hand-Roll" + Open Question 1):
```dart
import 'package:intl/intl.dart';
...
/// Formats Σ joy_contribution cumulative sum as an integer with
/// locale-appropriate thousand separators (e.g., "1,234").
String formatJoyCumulative(double rawSum, String currencyCode) {
  // currencyCode reserved for future locale-aware variants; cumulative
  // form needs no per-¥ suffix (D-09 / ADR-016 §2).
  final intValue = rawSum.floor();
  return NumberFormat.decimalPattern().format(intValue);
}
```
The `currencyCode` parameter is kept in the signature for callsite parity with `formatJoyDensity` (HomeHero only renames the function name, not the argument list).

---

### `test/unit/application/analytics/get_monthly_joy_target_recommendation_use_case_test.dart` (unit test)

**Analog:** `test/unit/application/analytics/get_happiness_report_use_case_test.dart`

**Mocktail repository + setUp pattern** (analog lines 12-24):
```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetHappinessReportUseCase useCase;

  final startDate = DateTime(2026, 5);
  final endDate = DateTime(2026, 5, 31, 23, 59, 59);

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetHappinessReportUseCase(analyticsRepository: repository);
  });
```
Reuse this exact shape. For the new use case, the test must stub the renamed DAO surface (`getSoulRowsForJoyContribution`) **three times** with different `startDate/endDate` per month.

**Stub helper pattern** (analog lines 26-60) — single-call `when(...).thenAnswer(...)`:
```dart
when(
  () => repository.getSoulRowsForPtvf(
    bookId: 'book-1',
    startDate: startDate,
    endDate: endDate,
  ),
).thenAnswer((_) async => ptvfRows);
```
For the recommendation test, parameterize the stub by month offset; provide a fixture map `{1: [rows for M-1], 2: [...], 3: [...]}`.

**Inline `valueMetric<T>` / `emptyMetric<T>` helpers — duplicate inline per Phase 9 convention** (analog lines 62-70):
```dart
Future<Value<T>> valueMetric<T>(MetricResult<T> result) async {
  expect(result, isA<Value<T>>());
  return result as Value<T>;
}

Future<Empty<T>> emptyMetric<T>(MetricResult<T> result) async {
  expect(result, isA<Empty<T>>());
  return result as Empty<T>;
}
```
Use `valueMetric<int>(...)` for the recommendation test (output is `MetricResult<int>`).

**execute helper** (analog lines 72-79):
```dart
Future<HappinessReport> execute({String currencyCode = 'JPY'}) {
  return useCase.execute(
    bookId: 'book-1',
    year: 2026,
    month: 5,
    currencyCode: currencyCode,
  );
}
```
For new use case, replace year/month with `asOf: DateTime asOf = ...`.

**Group/test naming style** (analog lines 81-118) — single-purpose `test('descriptive sentence', () async { ... });` blocks. Each test re-uses `stubReportInputs` then calls `execute()`.

**Edge case coverage (per RESEARCH Validation §Fixture strategy):**
- ≥3 months all non-zero → `Value(ceil(median), 3)`
- 2 of 3 months populated (one returns empty list) → `Empty()`
- 0 months populated → `Empty()`
- All-zero soul_satisfaction → treated as empty (sum=0)
- CNY currency → base=25 plumbing verified
- asOf month boundary (e.g., `DateTime(2026, 2, 15)` → M-1=Jan, M-2=Dec, M-3=Nov 2025)

---

### `test/unit/infrastructure/i18n/formatters/joy_cumulative_formatter_test.dart` (unit test)

**Analog:** `test/unit/infrastructure/i18n/formatters/joy_density_formatter_test.dart` (being deleted).

**Group structure (analog lines 6-33) — keep `ptvfBaseFor` group verbatim** (all 6 cases stay):
```dart
group('JoyCumulativeFormatter', () {
  group('ptvfBaseFor', () {
    test('returns JPY PTVF base', () {
      expect(ptvfBaseFor('JPY'), 500.0);
    });
    test('returns CNY PTVF base', () => expect(ptvfBaseFor('CNY'), 25.0));
    test('returns USD PTVF base', () => expect(ptvfBaseFor('USD'), 5.0));
    test('falls back to JPY base for EUR', () =>
        expect(ptvfBaseFor('EUR'), 500.0));
    test('matches currency codes case-sensitively', () =>
        expect(ptvfBaseFor('jpy'), 500.0));
  });
```

**Replace `formatJoyDensity` group with `formatJoyCumulative` group:**
- Integer rounding (floor): `formatJoyCumulative(78.4, 'JPY')` → `'78'`.
- Thousand separator: `formatJoyCumulative(12345.67, 'JPY')` → `'12,345'`.
- Zero case: `formatJoyCumulative(0.0, 'JPY')` → `'0'`.
- Large value: `formatJoyCumulative(1234567.0, 'JPY')` → `'1,234,567'`.

---

### `lib/features/settings/domain/models/app_settings.dart` (Freezed model)

**Self-analog (existing fields):**
```dart
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('system') String language,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool biometricLockEnabled,
    @Default('zh') String voiceLanguage,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
```

**Phase 13 addition** — nullable int with no `@Default` (per D-03 absent-key-is-null):
```dart
const factory AppSettings({
  @Default(AppThemeMode.system) AppThemeMode themeMode,
  @Default('system') String language,
  @Default(true) bool notificationsEnabled,
  @Default(true) bool biometricLockEnabled,
  @Default('zh') String voiceLanguage,
  int? monthlyJoyTarget,  // D-03: null = unconfigured; no @Default()
}) = _AppSettings;
```
Regen required (`flutter pub run build_runner build --delete-conflicting-outputs`) — both `app_settings.freezed.dart` and `app_settings.g.dart` must be committed atomically (AUDIT-10).

---

### `lib/features/settings/domain/repositories/settings_repository.dart` (domain interface)

**Self-analog — `setVoiceLanguage` shape (line 11):**
```dart
Future<void> setVoiceLanguage(String languageCode);
```

**Phase 13 addition — nullable variant:**
```dart
Future<int?> getMonthlyJoyTarget();
Future<void> setMonthlyJoyTarget(int? value);
```
Both methods recommended (RESEARCH §Group B `settings_repository.dart`): the getter is optional but matches `setVoiceLanguage` symmetry and lets the recommendation use case test harness read without going through full `getSettings()`.

---

### `lib/data/repositories/settings_repository_impl.dart` (SharedPreferences impl)

**Self-analog — `_voiceLanguageKey` + `setVoiceLanguage` pattern** (lines 16, 59-61):
```dart
static const String _voiceLanguageKey = 'voice_language';

@override
Future<void> setVoiceLanguage(String languageCode) async {
  await _prefs.setString(_voiceLanguageKey, languageCode);
}
```

**Phase 13 changes — three insertion points:**

1. Add key constant (after line 16):
```dart
static const String _monthlyJoyTargetKey = 'monthly_joy_target';
```

2. Extend `getSettings()` (analog lines 19-27) — `_prefs.getInt(key)` returns `null` natively when absent (D-03):
```dart
@override
Future<AppSettings> getSettings() async {
  return AppSettings(
    themeMode: _getThemeMode(),
    language: _prefs.getString(_languageKey) ?? 'system',
    notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
    biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
    voiceLanguage: _prefs.getString(_voiceLanguageKey) ?? 'zh',
    monthlyJoyTarget: _prefs.getInt(_monthlyJoyTargetKey),  // NEW (no fallback)
  );
}
```

3. Add setter — null encoding via `remove()` (D-03):
```dart
@override
Future<void> setMonthlyJoyTarget(int? value) async {
  if (value == null) {
    await _prefs.remove(_monthlyJoyTargetKey);
  } else {
    await _prefs.setInt(_monthlyJoyTargetKey, value);
  }
}

@override
Future<int?> getMonthlyJoyTarget() async {
  return _prefs.getInt(_monthlyJoyTargetKey);
}
```

4. Extend `updateSettings` (analog lines 30-36) to match the null semantics:
```dart
@override
Future<void> updateSettings(AppSettings settings) async {
  ...existing 5 lines...
  if (settings.monthlyJoyTarget == null) {
    await _prefs.remove(_monthlyJoyTargetKey);
  } else {
    await _prefs.setInt(_monthlyJoyTargetKey, settings.monthlyJoyTarget!);
  }
}
```

**Round-trip test pattern** — analog `test/unit/data/repositories/settings_repository_impl_voice_test.dart`:
```dart
void main() {
  group('SettingsRepositoryImpl - monthlyJoyTarget', () {
    late SettingsRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepositoryImpl(prefs: prefs);
    });

    test('getSettings returns null monthlyJoyTarget when key absent', () async {
      final settings = await repo.getSettings();
      expect(settings.monthlyJoyTarget, isNull);
    });

    test('setMonthlyJoyTarget persists and getSettings reflects change', () async {
      await repo.setMonthlyJoyTarget(75);
      final settings = await repo.getSettings();
      expect(settings.monthlyJoyTarget, 75);
    });

    test('setMonthlyJoyTarget(null) removes the key', () async {
      await repo.setMonthlyJoyTarget(75);
      await repo.setMonthlyJoyTarget(null);
      final settings = await repo.getSettings();
      expect(settings.monthlyJoyTarget, isNull);
    });
  });
}
```

---

### `lib/features/analytics/domain/models/happiness_report.dart` (Freezed model, single-field rename)

**Self-analog (current shape, lines 8-24):**
```dart
@freezed
abstract class HappinessReport with _$HappinessReport {
  const factory HappinessReport({
    required int year,
    required int month,
    required String bookId,
    required int totalSoulTx,
    required MetricResult<double> avgSatisfaction,
    required MetricResult<double> joyPerYen,   // <-- RENAMED
    required MetricResult<double> medianSatisfaction,
    required MetricResult<int> highlightsCount,
    required MetricResult<BestJoyMomentRow> topJoy,
  }) = _HappinessReport;
}
```
**Change:** rename `joyPerYen` → `joyContribution`. Keep `MetricResult<double>` (per CONTEXT Claude's Discretion: defer rounding to formatter, preserve precision through model).

Regen required: `happiness_report.freezed.dart` (no `.g.dart` — no `fromJson` in this model).

---

### `lib/application/analytics/get_happiness_report_use_case.dart` (self-modification — formula migration)

**Imports change (line 8):**
```dart
// BEFORE
import '../../infrastructure/i18n/formatters/joy_density_formatter.dart';
// AFTER
import '../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
```

**Method rename + fold simplification (analog lines 99-111 — see "PTVF fold pattern" above).** Replace `_computePtvfDensity` with `_computeJoyContribution` (no `denominator`, no division).

**Call-site renames (analog lines 74, 82, 92):**
```dart
// Line 74 — Empty branch:
joyPerYen: const Empty(),   →   joyContribution: const Empty(),

// Line 82 — Value branch (also rename local variable for clarity):
final density = _computePtvfDensity(ptvfRows, base);
→ final joyContrib = _computeJoyContribution(ptvfRows, base);

// Line 92 — HappinessReport constructor:
joyPerYen: Value(density, totalSoulTx),
→ joyContribution: Value(joyContrib, totalSoulTx),
```

**DAO call rename (analog line 48):**
```dart
_repo.getSoulRowsForPtvf(...)   →   _repo.getSoulRowsForJoyContribution(...)
```
(per CONTEXT Claude's Discretion: rename preferred for clarity.)

---

### `lib/features/analytics/presentation/providers/state_happiness.dart` (Riverpod provider file)

**Analog inside the same file — `bestJoyMoment` provider (lines 34-43):**
```dart
@riverpod
Future<MetricResult<BestJoyMomentRow>> bestJoyMoment(
  Ref ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getBestJoyMomentUseCaseProvider);
  return useCase.execute(bookId: bookId, year: year, month: month);
}
```

**Phase 13 deletions:**
- Delete `import '../../domain/models/daily_joy_per_yen_point.dart';` (line 5).
- Delete entire `dailyJoyPerYen` provider block (lines 45-61).

**Phase 13 addition — new provider mirroring the `bestJoyMoment` shape:**
```dart
/// JOYMIG-02 / D-04 — recommended monthlyJoyTarget = ceil(median(past 3 months Σ joy_contribution)).
/// Returns Empty when fewer than 3 past months have soul tx data.
@riverpod
Future<MetricResult<int>> monthlyJoyTargetRecommendation(
  Ref ref, {
  required String bookId,
  required String currencyCode,
}) async {
  final useCase = ref.watch(getMonthlyJoyTargetRecommendationUseCaseProvider);
  return useCase.execute(
    bookId: bookId,
    currencyCode: currencyCode,
    asOf: DateTime.now(),
  );
}
```
Riverpod 3 note (CLAUDE.md table): function name `monthlyJoyTargetRecommendation` → generated provider name `monthlyJoyTargetRecommendationProvider` (no Notifier suffix stripping applies to functional providers — only `class XxxNotifier` is stripped).

Regen required: `state_happiness.g.dart`.

---

### `lib/features/analytics/presentation/providers/repository_providers.dart` (use case provider wiring)

**Analog inside the same file — `getBestJoyMomentUseCase` provider (lines 84-89):**
```dart
@riverpod
GetBestJoyMomentUseCase getBestJoyMomentUseCase(Ref ref) {
  return GetBestJoyMomentUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

**Phase 13 deletions:**
- Delete `import '../../../../application/analytics/get_daily_joy_per_yen_use_case.dart';` (line 6).
- Delete `getDailyJoyPerYenUseCase` provider (lines 67-73).

**Phase 13 addition:**
```dart
import '../../../../application/analytics/get_monthly_joy_target_recommendation_use_case.dart';

/// JOYMIG-02 / D-04: GetMonthlyJoyTargetRecommendationUseCase provider.
@riverpod
GetMonthlyJoyTargetRecommendationUseCase
    getMonthlyJoyTargetRecommendationUseCase(Ref ref) {
  return GetMonthlyJoyTargetRecommendationUseCase(
    analyticsRepository: ref.watch(analyticsRepositoryProvider),
  );
}
```

Regen required: `repository_providers.g.dart`.

---

### `lib/features/home/presentation/widgets/home_hero_card.dart` (HomeHero minimal migration)

**4 touch-points only** (D-09 "HomeHero = field rename + draft only"):

**1. Import (line 11):**
```dart
// BEFORE
import '../../../../infrastructure/i18n/formatters/joy_density_formatter.dart';
// AFTER
import '../../../../infrastructure/i18n/formatters/joy_cumulative_formatter.dart';
```

**2. Ring fill ratio call (line 362):**
```dart
// BEFORE
outerSweepRatio: _outerSingle(happiness.joyPerYen),
// AFTER
outerSweepRatio: _outerSingle(happiness.joyContribution),
```
`_outerSingle` signature unchanged (`MetricResult<double> → double`). Phase-13-baseline ring shim accepted (Risk 4 in RESEARCH).

**3. Legend row data tile (lines 477-482) — field rename + formatter call swap + enum value rename:**
```dart
_legendRow(
  context,
  AppColors.soul,
  l10n.homeJoyPerYenLegend,   // ← ARB key kept (D-09: ARB rename is Phase 14 TOOL-V2-02)
  switch (happiness.joyContribution) {     // ← field renamed
    Empty() => empty,
    Value(:final data) => formatJoyCumulative(data, currencyCode),  // ← formatter swap
  },
  trailing: const _InfoIcon(tooltipKey: _TooltipKey.joyContribution),  // ← enum case renamed
),
```

**4. Tooltip enum + dispatch (lines 818, 850):**
```dart
// Line 818 — enum definition
enum _TooltipKey { joyIndex, joyContribution }   // was: joyPerYen

// Line 850 — dispatch (ARB key stays old per D-09; only the enum case changes)
_TooltipKey.joyContribution => l10n.homeJoyPerYenTooltip,
```
RESEARCH Risk 5: ARB key `homeJoyPerYenTooltip` keeps its old name — only the Dart-side enum case is renamed.

---

### `lib/features/analytics/presentation/screens/analytics_screen.dart` (delete trend section, fix histogram gate)

**Deletions:**
- Import `import '../widgets/joy_trend_line_chart.dart';` (line 21) — remove.
- Body call site `_JoyTrendOrFallback(...)` (lines 105-112) + the surrounding `const SizedBox(height: 8)` spacer (line 104) — remove.
- Class `_JoyTrendOrFallback` (lines 312-374) — remove entirely.
- `ref.invalidate(dailyJoyPerYenProvider(...))` in `_refresh()` (lines 185-192) — remove.
- `_SatisfactionHistogramOrFallback` error retry `dailyJoyPerYenProvider` invalidation (lines 463-471) — remove.

**Histogram gate replacement (the Risk 1 fix — lines 422-473):**

The class currently uses `dailyJoyPerYenProvider`'s sample size as the n<5 gate. Replacement pattern — watch `happinessReportProvider` (already present at screen level for `_KpiHero`):
```dart
class _SatisfactionHistogramOrFallback extends ConsumerWidget {
  // currencyCode parameter no longer needed if we drop daily provider —
  // but happinessReportProvider takes currencyCode too, so keep the field.
  ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final happinessAsync = ref.watch(
      happinessReportProvider(
        bookId: bookId,
        year: year,
        month: month,
        currencyCode: currencyCode,
      ),
    );
    final distributionAsync = ref.watch(
      satisfactionDistributionProvider(
        bookId: bookId,
        year: year,
        month: month,
      ),
    );

    return happinessAsync.when(
      data: (report) {
        if (report.totalSoulTx < 5) {
          return const SizedBox.shrink();
        }
        return distributionAsync.when(
          data: (buckets) => _AnalyticsDataCard(...),
          loading: () => const SizedBox(height: 260),
          error: (_, _) => AnalyticsCardErrorState(
            onRetry: () => ref.invalidate(
              satisfactionDistributionProvider(bookId: bookId, year: year, month: month),
            ),
          ),
        );
      },
      loading: () => const SizedBox(height: 260),
      error: (_, _) => AnalyticsCardErrorState(
        onRetry: () => ref.invalidate(
          happinessReportProvider(
            bookId: bookId, year: year, month: month, currencyCode: currencyCode,
          ),
        ),
      ),
    );
  }
}
```
Riverpod caches the provider value across watches (single `_KpiHero` watch + this watch share the result).

---

### `lib/data/daos/analytics_dao.dart` (DAO rename + delete)

**Self-analog — `getSoulRowsForPtvf` (lines 411-438):**
```dart
Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final results = await _db
      .customSelect(
        'SELECT amount, soul_satisfaction '
        'FROM transactions '
        'WHERE book_id = ? AND $_soulExpenseFilter '
        'AND timestamp >= ? AND timestamp <= ?',
        variables: [
          Variable.withString(bookId),
          Variable.withDateTime(startDate),
          Variable.withDateTime(endDate),
        ],
      )
      .get();
  return results.map((row) => SoulRowSample(...)).toList();
}
```
**Change:** rename method to `getSoulRowsForJoyContribution`. SQL body unchanged.

**Delete entirely:** `getDailySoulRowsForPtvf` (lines 306-337) — no longer consumed after the daily use case is removed.

---

### `lib/data/repositories/analytics_repository_impl.dart` (delegation)

**Self-analog — existing delegation (lines 138-149):**
```dart
@override
Future<List<SoulRowSample>> getSoulRowsForPtvf({
  required String bookId,
  required DateTime startDate,
  required DateTime endDate,
}) {
  return _dao.getSoulRowsForPtvf(
    bookId: bookId,
    startDate: startDate,
    endDate: endDate,
  );
}
```
**Change:** rename method (interface + impl) to `getSoulRowsForJoyContribution`. Delegate to renamed DAO method.

**Delete:** `getDailySoulRowsForPtvf` delegation (lines 151-162).

Interface (`analytics_repository.dart` lines 49-60) — rename `getSoulRowsForPtvf` and delete `getDailySoulRowsForPtvf` declaration.

---

### `test/helpers/happiness_test_fixtures.dart` (fixture update)

**Self-analog — current fixture shape (lines 91-103):**
```dart
HappinessReport fixtureHappinessReportRich({String bookId = 'book_001'}) {
  return HappinessReport(
    year: 2026,
    month: 4,
    bookId: bookId,
    totalSoulTx: 31,
    avgSatisfaction: const Value(7.8, 23),
    medianSatisfaction: const Value(8.0, 23),
    joyPerYen: const Value(1.2, 23),    // ← RENAME
    highlightsCount: const Value(12, 23),
    topJoy: Value(fixtureBestJoyMomentRich(), 23),
  );
}
```
**Change in 3 fixtures (Rich, Thin, Empty — lines 99, 115, 130):**
- `joyPerYen:` → `joyContribution:` in all three factories.
- For `fixtureHappinessReportRich`: change value from `const Value(1.2, 23)` → `const Value(78.4, 23)` (plausible cumulative-sum for 23 soul tx × avg satisfaction ~7).
- For `fixtureHappinessReportThin`: change `const Value(1.2, 3)` → `const Value(12.0, 3)` (plausible for 3 tx).
- For `fixtureHappinessReportEmpty`: `joyContribution: const Empty()` (unchanged semantically).

---

## Shared Patterns

### Pattern: PTVF fold contract (alpha + base)

**Source:** `lib/application/analytics/get_happiness_report_use_case.dart` lines 23, 81-82, 99-111
**Apply to:** Both modified `GetHappinessReportUseCase._computeJoyContribution` and new `GetMonthlyJoyTargetRecommendationUseCase._foldContribution`.

```dart
static const double _ptvfAlpha = 0.88;
...
final base = ptvfBaseFor(currencyCode);
...
sum += r.soulSatisfaction * math.pow(r.amount / base, _ptvfAlpha).toDouble();
```
Both use cases must import `joy_cumulative_formatter.dart` for `ptvfBaseFor`. The alpha constant is duplicated (not shared from formatter) — Phase 9 convention puts it in the use case body.

### Pattern: MetricResult sealed-type return

**Source:** `lib/features/analytics/domain/models/metric_result.dart`
**Apply to:** New recommendation use case output; rewritten `joyContribution` field.

```dart
sealed class MetricResult<T> { const MetricResult(); }
final class Empty<T> extends MetricResult<T> { const Empty(); }
final class Value<T> extends MetricResult<T> {
  const Value(this.data, this.sampleSize);
  final T data;
  final int sampleSize;
}
```
**UI consumption pattern** (kept in HomeHero / AnalyticsScreen):
```dart
switch (result) {
  Empty() => emptyState,
  Value(:final data) => renderData(data),
}
```

### Pattern: SharedPreferences key + setter + null encoding

**Source:** `lib/data/repositories/settings_repository_impl.dart` (`_voiceLanguageKey` / `setVoiceLanguage`)
**Apply to:** new `_monthlyJoyTargetKey` + `setMonthlyJoyTarget` + `getMonthlyJoyTarget`.
**D-03 deviation from analog:** null encoding via `_prefs.remove(key)` because the new field is nullable (analog `voiceLanguage` is non-null string with default `'zh'`). `_prefs.getInt(key)` natively returns `null` when absent — no sentinel needed.

### Pattern: Riverpod 3 functional provider

**Source:** `lib/features/analytics/presentation/providers/state_happiness.dart` (`bestJoyMoment` provider, lines 34-43); use case wiring in `repository_providers.dart` (`getBestJoyMomentUseCase`, lines 84-89).
**Apply to:** `monthlyJoyTargetRecommendation` provider + `getMonthlyJoyTargetRecommendationUseCase` provider.
**Riverpod 3 rules from CLAUDE.md table:**
- `@riverpod` annotation on top-level function → generated `xxxProvider` (no suffix stripping for functions).
- Import `package:flutter_riverpod/flutter_riverpod.dart` only (Riverpod 3 split surface — `Ref` lives there).
- Provider tests use `ProviderContainer.test()` + the `waitForFirstValue<T>` helper in `test/helpers/test_provider_scope.dart` (CLAUDE.md).

### Pattern: Mocktail unit test for use case

**Source:** `test/unit/application/analytics/get_happiness_report_use_case_test.dart` lines 12-79
**Apply to:** New recommendation use case test.
**Components:**
- `class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}`
- `setUp(() { repository = _MockAnalyticsRepository(); useCase = ... })`
- Inline `valueMetric<T>` / `emptyMetric<T>` (8 lines duplicated per Phase 9 convention — RESEARCH §Test Strategy)
- `when(...).thenAnswer((_) async => fixture)` per repository call
- `group('feature', () { test('...', () async { ... }); })` structure

### Pattern: build_runner regeneration ordering

**Source:** CLAUDE.md + RESEARCH §Build/CI Considerations
**Apply to:** every plan that touches `@freezed` / `@riverpod` / Drift.
**Trigger files this phase:**
- `app_settings.dart` (add `monthlyJoyTarget`) → regen `app_settings.freezed.dart` + `.g.dart`
- `happiness_report.dart` (rename field) → regen `happiness_report.freezed.dart`
- `state_happiness.dart` (add/remove providers) → regen `state_happiness.g.dart`
- `repository_providers.dart` (add/remove use case providers) → regen `repository_providers.g.dart`
- `daily_joy_per_yen_point.dart` deleted → delete `daily_joy_per_yen_point.freezed.dart` too (AUDIT-10).

Command: `flutter pub run build_runner build --delete-conflicting-outputs`. Run after each annotated-file change; commit generated files atomically with source change (AUDIT-10 enforces clean-diff).

---

## No Analog Found

| File | Role | Reason |
|------|------|--------|
| `.planning/phases/13-adr-016-backend-foundation/13-SPIKE.md` | planning/spike output | Markdown spike report. CONTEXT.md D-05 + RESEARCH §Implementation Approach Step 1 fully specify the format (scenario table, demo-data simulation rows, decided defaults, rationale). No code analog needed. |
| `.planning/ROADMAP.md` SC-2 wording edit (D-02) | planning artifact | Markdown rewrite of a single bullet. No code analog needed. |
| `.planning/REQUIREMENTS.md` JOYMIG-02 wording review (D-02) | planning artifact | Per CONTEXT D-02 the spike-scope wording is already correct; only ROADMAP SC-2 needs the schema → SharedPreferences rewrite. |

---

## Metadata

**Analog search scope:**
- `lib/application/analytics/` (5 use cases inspected)
- `lib/data/repositories/` (settings + analytics impl)
- `lib/data/daos/` (analytics_dao.dart lines 300-440)
- `lib/features/analytics/{domain,presentation}/`
- `lib/features/settings/domain/`
- `lib/features/home/presentation/widgets/`
- `lib/infrastructure/i18n/formatters/`
- `test/unit/application/analytics/` (use case test template)
- `test/unit/data/repositories/` (settings test template)
- `test/unit/infrastructure/i18n/formatters/` (formatter test template)
- `test/helpers/happiness_test_fixtures.dart` (fixture update sites)

**Files scanned:** 18 (12 read in full, 6 read in targeted ranges via `Read` offset/limit)

**Pattern extraction date:** 2026-05-19

**Tied-into-CLAUDE.md rules verified:**
- Clean Architecture 5-layer placement (use case at `lib/application/analytics/`, formatter at `lib/infrastructure/i18n/formatters/`, model at `lib/features/.../domain/models/`).
- Thin Feature rule (no `application/`, `data/`, or `infrastructure/` inside `features/`) — all new files land correctly.
- Riverpod 3 conventions (function name → `xxxProvider`, no suffix-stripping for functional providers; `.value` not `.valueOrNull`).
- Freezed immutability + `copyWith` (auto-generated for `AppSettings` and `HappinessReport`).
- `intl 0.20.2` pin (use existing dep for `NumberFormat`).
- AUDIT-10 generated-file commit-atomicity (called out in every regen-touching pattern).
- No new Drift table (D-01); `schemaVersion = 16` untouched.
- No new ADR (D-11); ADR-013 append-only segment already ratified.
