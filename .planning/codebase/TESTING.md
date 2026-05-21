# Testing Patterns

**Analysis Date:** 2026-05-21

## Test Framework

**Runner:**
- `flutter_test` (built-in SDK package)
- `mocktail: ^1.0.4` — mock library (replaced mockito in v1.0 HIGH-07)

**Assertion Library:**
- `flutter_test` (built-in `expect`, `find`, `matchesGoldenFile`)
- Mocktail `verify`, `verifyNever`, `when`, `any(named: ...)`, `registerFallbackValue`

**Config:** No separate `jest.config` — standard Flutter test runner.

**Run Commands:**
```bash
flutter test                        # Run all tests (must pass before commit)
flutter test --coverage             # Run with LCOV coverage output
flutter test --update-goldens       # Regenerate golden PNG baselines
flutter test test/architecture/     # Arch invariant tests only
flutter test test/unit/             # Unit tests only
flutter test test/widget/           # Widget tests only
```

## Test File Organization

```
test/
├── architecture/            # Arch invariant tests (run against lib/ source)
│   ├── domain_import_rules_test.dart
│   ├── presentation_layer_rules_test.dart
│   ├── provider_graph_hygiene_test.dart
│   ├── production_logging_privacy_test.dart
│   ├── arb_key_parity_test.dart
│   ├── hardcoded_cjk_ui_scan_test.dart
│   └── ...
├── golden/                  # Golden file snapshot tests
│   ├── home_hero_card_golden_test.dart
│   ├── soul_vs_survival_card_golden_test.dart
│   ├── per_category_breakdown_card_golden_test.dart
│   ├── amount_display_golden_test.dart
│   └── goldens/             # PNG baselines (committed, ja-locale default)
│       └── {widget}_{state}_{locale}.png
├── helpers/                 # Shared test utilities
│   ├── test_provider_scope.dart     # createTestProviderScope + waitForFirstValue
│   ├── test_localizations.dart      # createLocalizedWidget helper
│   └── happiness_test_fixtures.dart # Canonical fixture builders
├── unit/                    # Unit tests mirroring lib/ structure
│   ├── application/{domain}/
│   ├── data/{daos,migrations,repositories,tables}/
│   ├── features/{feature}/{domain,presentation}/
│   ├── infrastructure/{category,i18n,ml,speech}/
│   └── shared/{constants,utils}/
├── widget/                  # Widget tests mirroring lib/features structure
│   └── features/{feature}/presentation/{screens,widgets}/
├── integration/sync/        # Integration tests for sync layer
├── infrastructure/          # Infrastructure tests
│   └── crypto/
├── application/             # Application-layer tests (parallel to unit/)
└── scripts/                 # Tooling/script tests
```

**Naming:** Test file names mirror their source counterpart + `_test.dart` suffix (e.g., `get_happiness_report_use_case.dart` → `get_happiness_report_use_case_test.dart`). Special pattern: `{module}_characterization_test.dart` for characterization/golden tests of existing behavior.

## Test Structure

**Standard suite pattern:**

```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  late _MockAnalyticsRepository repository;
  late GetHappinessReportUseCase useCase;

  setUp(() {
    repository = _MockAnalyticsRepository();
    useCase = GetHappinessReportUseCase(analyticsRepository: repository);
  });

  group('GetHappinessReportUseCase', () {
    test('returns Value when repository returns data', () async {
      when(
        () => repository.getSoulSatisfactionOverview(
          bookId: 'book-1',
          startDate: startDate,
          endDate: endDate,
        ),
      ).thenAnswer((_) async => fixtureOverview);

      final result = await useCase.execute(
        bookId: 'book-1',
        startDate: startDate,
        endDate: endDate,
        currencyCode: 'JPY',
      );

      expect(result, isA<Value<HappinessReport>>());
    });
  });
}
```

**Setup pattern:** `late` fields declared at group scope, initialized in `setUp()`. `setUpAll` used only for `registerFallbackValue` calls (required by mocktail before using `any(named: ...)`).

**Teardown:** Use `addTearDown(container.dispose)` or `ProviderContainer.test()` (auto-disposes on test teardown).

## Mocking

**Framework:** Mocktail (`package:mocktail/mocktail.dart`)

**Pattern: private mock classes with `_Mock` prefix:**

```dart
class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}
class _MockMonthlyReportUseCase extends Mock implements GetMonthlyReportUseCase {}
```

**Stubbing:**

```dart
when(
  () => mockRepo.findByBookId(
    any(),
    ledgerType: any(named: 'ledgerType'),
    categoryId: any(named: 'categoryId'),
  ),
).thenAnswer((_) async => transactions);

// For fire-and-forget (must not be called):
when(
  () => perCategoryUseCase.execute(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  ),
).thenAnswer((_) async => const Empty());
```

**Fallback registration** (required for custom types used with `any()`):

```dart
setUpAll(() {
  registerFallbackValue(DateTime(2000));
  registerFallbackValue(<String>[]);
});
```

**Isolation assertions with `verifyNever`:**

The `verifyNever(...)` + `any(named: ...)` pattern is the canonical way to prove a component does NOT reach a dependency. Used extensively in `home_screen_isolation_test.dart` to assert HomeHero never calls analytics phase 16/17 providers:

```dart
verifyNever(
  () => perCategorySoulBreakdownUseCase.execute(
    bookId: any(named: 'bookId'),
    startDate: any(named: 'startDate'),
    endDate: any(named: 'endDate'),
  ),
);
```

After calling `clearInteractions(mock)`, subsequent `verifyNever` covers only post-clear calls.

**What to mock:** Repository interfaces, use case classes, external services.

**What NOT to mock:** Value objects, Freezed models, pure transformation functions, Drift `AppDatabase.forTesting()` (use real in-memory DB).

## Riverpod 3 Testing Patterns

**Critical: Never use bare `await container.read(provider.future)` on auto-dispose providers.** Riverpod 3 disposes the orphan read before the build settles, causing `Bad state: disposed during loading`. Use `waitForFirstValue<T>` instead:

```dart
import '../helpers/test_provider_scope.dart';

// CORRECT
final result = await waitForFirstValue<List<Transaction>>(
  container,
  todayTransactionsProvider(bookId: 'book_001'),
);
expect(result.hasValue, isTrue);
expect(result.value, hasLength(2));

// WRONG
final list = await container.read(todayTransactionsProvider.future); // may throw disposed
```

**`waitForFirstValue<T>` internals** (`test/helpers/test_provider_scope.dart`): holds an active `container.listen` subscription via a `Completer`, resolving when `hasError || hasValue`. The subscription is closed via `whenComplete`.

**`ProviderContainer.test()` vs manual container:**

```dart
// CORRECT (Riverpod 3 preferred)
final container = ProviderContainer.test(overrides: [...]);
// auto-disposes on test teardown — no addTearDown needed

// ACCEPTABLE (older pattern, still in use)
final container = ProviderContainer(overrides: [...]);
addTearDown(container.dispose);
```

**`createTestProviderScope` helper** (`test/helpers/test_provider_scope.dart`):

```dart
// Always provides appDatabaseProvider override with AppDatabase.forTesting()
final container = createTestProviderScope(
  additionalOverrides: [
    analyticsRepositoryProvider.overrideWithValue(analyticsRepository),
  ],
);
```

**Provider overrides in widget tests** via `createLocalizedWidget`:

```dart
await tester.pumpWidget(
  createLocalizedWidget(
    MyScreen(bookId: _bookId),
    locale: const Locale('ja'),
    overrides: [
      getMonthlyReportUseCaseProvider.overrideWith((_) => mockUseCase),
    ],
  ),
);
```

## Widget Testing Patterns

**`createLocalizedWidget` helper** (`test/helpers/test_localizations.dart`): wraps widget in `ProviderScope + MaterialApp` with all localization delegates. Default locale is `en`; pass `locale:` to override.

```dart
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
})
```

**Standard widget test flow:**

```dart
testWidgets('HomeHeroCard shows amount', (tester) async {
  await tester.pumpWidget(
    createLocalizedWidget(
      HomeHeroCard(...),
      locale: const Locale('ja'),
      overrides: [providerOverride],
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('¥1,235'), findsOneWidget);
  verifyNever(() => forbiddenUseCase.execute(...));
});
```

## Fixtures and Factories

**Canonical fixture builders** live in `test/helpers/happiness_test_fixtures.dart`:

```dart
// Usage pattern throughout test suite
fixtureMonthlyReportRich()              // MonthlyReport with full data
fixtureHappinessReportRich(bookId: id)  // HappinessReport with all fields
fixtureHappinessReportThin()            // HappinessReport with n<5 samples
fixtureBestJoyResultRich()              // MetricResult<BestJoyMomentRow> with data
fixtureBestJoyResultAllNeutral()        // all-neutral best joy moment
fixtureFamilyHappinessRich()            // FamilyHappiness group data
fixtureShadowBooksThree()               // List<ShadowBookInfo> (3 members)
fixtureShadowAggregateThree()           // ShadowAggregate for 3 books
```

**Inline fixture helpers** (within test files) for domain-specific data:

```dart
PerCategorySoulBreakdownItem _item(String id, double avg, int count) =>
    PerCategorySoulBreakdownItem(
      categoryId: id,
      avgSatisfaction: avg,
      totalCount: count,
    );
```

**Migration test data:** Inserted directly via Drift companion objects using `AppDatabase.forTesting()`.

## Golden Tests

**Location:** `test/golden/`

**PNG baselines committed at:** `test/golden/goldens/{widget}_{state}_{locale}.png`

**Default locale:** Japanese (`ja`) unless test specifically exercises locale variants.

**Standard variant set:** `{light, dark, group_light, group_dark}` (not all widgets need all four).

**Golden file naming:** `{widget_name}_{variant}_{locale}.png` (e.g., `home_hero_card_family_light_ja.png`, `soul_vs_survival_card_group_dark_ja.png`).

**Regeneration command:**
```bash
flutter test test/golden/ --update-goldens
```

**Pattern — pure StatelessWidget goldens (no ProviderScope needed):**

```dart
Widget _wrap({
  required Locale locale,
  required _FixtureSnapshot snapshot,
  ThemeMode themeMode = ThemeMode.light,
  double width = 600,
  double height = 720,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [S.delegate, ...],
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    themeMode: themeMode,
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: SingleChildScrollView(child: MyWidget(data: snapshot.data)),
      ),
    ),
  );
}

testWidgets('single mode light ja', (tester) async {
  await tester.pumpWidget(_wrap(locale: const Locale('ja'), snapshot: _singleRich()));
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MyWidget),
    matchesGoldenFile('goldens/my_widget_single_light_ja.png'),
  );
});
```

## Architecture Invariant Tests

Maintained in `test/architecture/`. These are meta-tests that assert structural properties of the codebase. They run as ordinary `flutter test` tests using `dart:io` to read the filesystem.

| Test file | What it guards |
|-----------|---------------|
| `domain_import_rules_test.dart` | Domain layer import_guard.yaml deny sets not weakened |
| `presentation_layer_rules_test.dart` | Presentation import_guard denies infrastructure/daos/tables |
| `provider_graph_hygiene_test.dart` | ONE `repository_providers.dart` per feature; state_*.dart siblings only; no duplicate provider names; no `UnimplementedError` in providers; keepAlive hard list maintained |
| `production_logging_privacy_test.dart` | No `print()`, no unguarded `debugPrint`/`dev.log`, no sensitive names in logged blocks |
| `arb_key_parity_test.dart` | All 3 ARB files (en/ja/zh) have parity — no missing keys |
| `hardcoded_cjk_ui_scan_test.dart` | No hardcoded CJK strings in UI layer |
| `stale_suppressions_scan_test.dart` | No dangling `// ignore:` comments |
| `service_name_collision_test.dart` | No duplicate service class names across features |

## Anti-Toxicity Sweep Tests

Phase 16 introduced automated trilingual forbidden-substring sweeps to prevent value-judgment / comparison language from leaking into rendered UI copy.

**Phase 16 coverage** (`test/widget/features/analytics/presentation/widgets/anti_toxicity_phase16_test.dart`):
- Cards: `PerCategoryBreakdownCard`, `SoulVsSurvivalCard`
- Locales: `en` (15 forbidden terms), `ja` (10 terms), `zh` (13 terms)
- States: `empty`, `sub_min_n`, `value_solo`, `value_group` — total 24 test cases × 3 locales
- Pattern: pumps whole card, calls `_sweepForbiddenSubstrings()` which iterates `find.textContaining(substring, findRichText: true)` expecting `findsNothing`

**Phase 17 coverage** (`test/widget/features/analytics/presentation/widgets/anti_toxicity_phase17_test.dart`):
- Widget: `JoyMetricVariantChip`
- Locales: `en`, `ja`, `zh` — guards chip copy against accuracy-denigration language
- States: `all`, `manualOnly` variants

## HomeHero Isolation Tests

`test/widget/features/home/presentation/screens/home_screen_isolation_test.dart` is the canonical example of combining source-grep guards, `verifyNever` assertions, and variant-toggle non-effect verification in one file.

**What it tests:**
1. `HomeHeroCard` always uses current-month window regardless of `AnalyticsScreen` `selectedTimeWindowProvider` value (D-12 guard)
2. `HomeHero` never reaches Phase 16 analytics providers (`perCategoryBreakdownUseCase`, `soulVsSurvivalSnapshotUseCase`, etc.) — `verifyNever(... any() ...)` with post-pump assertion
3. Phase 17 SC-4: toggling `selectedJoyMetricVariantProvider` does NOT invalidate or re-render HomeHero (widget data equality check + `clearInteractions` + `verifyNever`)
4. **Source-grep guard** (lines 368–388): reads `home_screen.dart` via `dart:io` and asserts it contains neither `state_time_window` nor `state_ledger_snapshot` import strings — this makes the import constraint explicit and machine-checked

## Drift Migration Tests

Pattern: `test/unit/data/migrations/migration_v{N}_to_v{N+1}_test.dart`

```dart
// lib version
const _targetSchemaVersion = 17;

setUp(() {
  db = AppDatabase.forTesting();
});
tearDown(() async { await db.close(); });

test('omitted entry_source stores DEFAULT manual', () async {
  await _insertTransaction(db, id: 'tx_default');
  final row = await _findTransaction(db, 'tx_default');
  expect(row.entrySource, equals('manual'));
});

test('rejects invalid entry_source via CHECK constraint', () async {
  expect(
    () => _insertTransaction(db, id: 'tx_invalid', entrySource: const Value('keyboard')),
    throwsA(isA<Object>()),
  );
});
```

**Active migration tests:**
- `category_v14_migration_test.dart`
- `index_v15_migration_test.dart`
- `migration_v15_to_v16_test.dart`
- `migration_v16_to_v17_test.dart` — entry_source column + CHECK constraint
- `entry_source_v17_migration_test.dart`

## Coverage Requirements

**Global:** ≥70% via `VeryGoodOpenSource/very_good_coverage@v2` on `coverage/lcov_clean.info`

**Per-file:** ≥70% via `dart run scripts/coverage_gate.dart` with `--deferred` flag

**Threshold history:** Was 80% pre-v1.0 (Phase 2); lowered to 70% in Phase 8 amendment (2026-04-28) after post-cleanup coverage measured 74.6%. Revisit tracked as FUTURE-TOOL-03.

**Deferred files** (10 explicit exceptions, documented in `.planning/audit/coverage-gate-deferred.txt`):

| File | Coverage | Rationale |
|------|----------|-----------|
| `lib/application/ml/repository_providers.dart` | 40% | Provider plumbing wrapper |
| `lib/application/profile/repository_providers.dart` | 0% | Provider plumbing wrapper |
| `lib/application/voice/repository_providers.dart` | 40% | Provider plumbing wrapper |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | 63% | Needs widget test (FUTURE-TOOL-03) |
| `lib/features/accounting/presentation/screens/transaction_entry_screen.dart` | 46% | Needs widget test (FUTURE-TOOL-03) |
| `lib/features/analytics/presentation/screens/analytics_screen.dart` | 53% | Needs widget test (FUTURE-TOOL-03) |
| `lib/features/family_sync/presentation/screens/create_group_screen.dart` | 18% | Needs widget test (FUTURE-TOOL-03) |
| `lib/features/family_sync/presentation/providers/state_sync.dart` | 62% | Needs notifier test |
| `lib/features/home/presentation/providers/state_shadow_books.dart` | 35% | Needs notifier test |
| `lib/features/settings/presentation/widgets/appearance_section.dart` | 60% | Needs widget test |

**LCOV filtering:** Generated files stripped before coverage gate: `\.g\.dart$`, `\.freezed\.dart$`, `\.mocks\.dart$`, `^lib/generated/`.

## CI / Coverage Pipeline

CI defined in `.github/workflows/audit.yml` (runs on PRs + pushes to `main`).

**Jobs:**
- `static-analysis`: `flutter analyze --no-fatal-infos` → `dart run custom_lint --no-fatal-infos` → audit shell scripts → `dart run scripts/merge_findings.dart`
- `guardrails`: AUDIT-09 (sqlite3_flutter_libs reject) + AUDIT-10 (stale generated files diff)
- `coverage`: `flutter test --coverage` → `coverde filter` (strip generated) → per-file gate (70%) → global gate (70%)

**Pre-commit checklist:**
```bash
flutter analyze          # MUST be 0 issues
dart format .
flutter test
flutter test --coverage  # >= 70% required
```

**After any `@riverpod`, `@freezed`, Drift table, or ARB change:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Known Stale Tests (Deferred at v1.2 close)

| Test file | Failures | Root cause | Deferred resolution |
|-----------|----------|------------|---------------------|
| `test/widget/features/analytics/presentation/widgets/family_insight_card_test.dart` | 6 failures | Phase 15 commit `8d5f136` dropped `今月、` prefix from `analyticsFamilyHighlightsSentence` ARB key; tests still expect old string | Re-baseline test strings in next milestone |
| `test/unit/features/home/presentation/providers/shadow_books_provider_characterization_test.dart` | 2 INFO warnings | riverpod_lint INFO-level (non-blocking) | Accept per Phase 8 amendment |

These are acknowledged and documented in `.planning/STATE.md` Deferred Items §v1.2 and do NOT block any user-observable flow.

---

*Testing analysis: 2026-05-21*
