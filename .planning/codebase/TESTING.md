# Testing Patterns

**Analysis Date:** 2026-06-23

This project has ~398 test files across unit, widget, golden, integration, and architecture suites. Tests are first-class code (same standards as production: zero analyzer warnings).

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK)
- `integration_test` (Flutter SDK) — for on-device/simulator tests where SQLCipher natives actually load (`integration_test/`)
- Config: `analysis_options.yaml` (lints apply to tests too); global bootstrap `test/flutter_test_config.dart`

**Assertion Library:**
- Built-in `flutter_test` matchers (`expect`, `isA`, `throwsA`, `having`)

**Supporting libs (`dev_dependencies` in `pubspec.yaml`):**
- `mocktail: ^1.0.4` — mocking (no codegen)
- `fake_async: ^1.3.3` — deterministic time

**Run Commands:**
```bash
flutter test                                          # Run all tests
flutter test --coverage                               # With coverage (lcov)
flutter test test/path/to/file_test.dart              # Single file
flutter test test/golden/foo_golden_test.dart --update-goldens  # Update golden baselines (macOS ONLY)
flutter test --tags golden                            # Run only golden-tagged tests
```

## Test File Organization

**Location:** Separate `test/` tree mirroring `lib/` structure (NOT co-located).

**Naming:** `{subject}_test.dart`. Golden tests: `{subject}_golden_test.dart`.

**Structure:**
```
test/
├── unit/{core,features,shared,application,infrastructure,data}/
├── widget/{features,shared}/
├── golden/            # + golden/goldens/ (baseline PNGs), golden/failures/
├── integration/{features,voice,sync,data,presentation}/
├── architecture/      # arch invariant tests (layer rules, ARB parity, color scan)
├── application/{accounting,family_sync}/
├── infrastructure/{crypto,security}/
├── fixtures/
└── helpers/           # shared test infrastructure
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());  // mocktail fallbacks
  });

  late _MockTransactionRepository mockTransactionRepo;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    useCase = CreateTransactionUseCase(transactionRepository: mockTransactionRepo, ...);
  });

  group('Feature / decision-id', () {
    test('describes expected behavior', () async {
      // arrange / act / assert
    });
  });
}
```

**Patterns:**
- `late` fields re-initialized in `setUp` for isolation
- `group(...)` blocks named by feature + decision ID (e.g. `'Dark-mode theme resolution (D-07 / THEME-V2-02)'`)
- File header comments cite the phase / ADR / VALIDATION row the test enforces (acceptance contract — do NOT weaken assertions to make a RED test pass)
- TDD: scaffolds land RED first, documented in the header

## Mocking

**Framework:** `mocktail` (no code generation).

**Patterns:**
```dart
class _MockTransactionRepository extends Mock implements TransactionRepository {}
class _FakeTransaction extends Fake implements Transaction {}

setUpAll(() => registerFallbackValue(_FakeTransaction()));

when(() => mockCategoryRepo.findById(any())).thenAnswer((_) async => testCategory);
verify(() => mockTransactionRepo.insert(any())).called(1);
```

**What to Mock:** repository interfaces, services (HashChainService, ClassificationService), sync collaborators.

**What NOT to Mock:** the unit under test; pure domain models; for DB tests use a real in-memory `AppDatabase.forTesting()` rather than mocking Drift.

## Fixtures and Factories

**Test Data:** inline `final` instances at top of `main()` (e.g. `final testCategory = Category(...)`). Fixed dates avoid `DateTime.now()` flakiness (`final _date = DateTime(2026, 5, 15)`).

**Shared helpers (`test/helpers/`):**
- `test_provider_scope.dart` — `createTestProviderScope({database, additionalOverrides})` always overrides `appDatabaseProvider` with in-memory DB; `waitForFirstValue<T>(container, provider)` for Riverpod 3 async reads (avoids "disposed during loading")
- `test_localizations.dart` — localization delegates for widget tests
- `happiness_test_fixtures.dart` — domain fixtures
- `ci_golden_comparator.dart` — `BaselineExistenceGoldenComparator`
- Shared `fixtures/` directory

## Coverage

**Requirement:** 70% threshold, BLOCKING in CI (`.github/workflows/audit.yml` `coverage` job via `scripts/coverage_gate.dart --threshold 70`).
- History: 80% (Phase 2 BASE-06) → lowered to 70% (Phase 8 amendment 2026-04-28). Raising back to 80% is on the backlog (`coverage-baseline-review`).
- Gate runs on cleanup-touched files with a deferred-files allowlist.

**View Coverage:**
```bash
flutter test --coverage   # writes coverage/lcov.info
```

## Test Types

**Unit Tests (`test/unit/`, `test/application/`):** use cases, services, utilities. Mock all collaborators with mocktail.

**Widget Tests (`test/widget/`):** `testWidgets` + `tester.pumpWidget`. Wrap in `MaterialApp` (helper `_darkApp`/`_wrap`); assert no-throw + theme/extension resolution. Add localization delegates only when needed.

**Golden Tests (`test/golden/`, `@Tags(['golden'])`):**
- Baselines are macOS-rendered. `test/flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` off-macOS (CI = ubuntu) so goldens still run for crash/coverage but only assert the baseline file exists — pixel match never runs on CI.
- Update baselines ONLY on macOS with `--update-goldens`. Typically 3 locales (ja/zh/en) × theme.

**Integration Tests (`test/integration/`, `integration_test/`):** cross-layer flows; on-device `integration_test/` drives the real SQLCipher encrypted-executor migration ladder (host `flutter test` links plain libsqlite3, so encryption tests must run on device/sim).

**Architecture Tests (`test/architecture/`):** static invariants enforced as tests — `domain_import_rules_test.dart` (layer deps), `arb_key_parity_test.dart` (3 ARB files in sync), `hardcoded_cjk_ui_scan_test.dart` (no hardcoded UI strings), `color_literal_scan_test.dart` (palette tokens only), `provider_graph_hygiene_test.dart` (no dup/UnimplementedError providers). Run the FULL `flutter test` for post-merge gates — scoped runs miss these.

## Common Patterns

**Async Testing:**
```dart
// Use case
final result = await useCase.execute(params);
expect(result.isSuccess, isTrue);

// Riverpod 3 async providers — use the helper, NOT bare read(provider.future)
final value = await waitForFirstValue<T>(container, someAsyncProvider);
// Prefer ProviderContainer.test() (auto-disposes on teardown)
```

**Error Testing:**
```dart
// Result-based use cases
expect(result.isError, isTrue);
expect(result.error, 'amount must be greater than 0');

// Riverpod 3 wraps provider errors in ProviderException
expect(
  () => container.read(p),
  throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>())),
);
```

---

*Testing analysis: 2026-06-23*
