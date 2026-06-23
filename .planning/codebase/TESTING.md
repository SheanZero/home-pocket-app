# Testing Patterns

**Analysis Date:** 2026-06-23

This is a Flutter (Dart) app. ~409 test files live under `test/`, organized by layer and test type. Tests are first-class code held to the same standards as production.

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK) — host-side widget/unit/golden/architecture tests
- `integration_test` (Flutter SDK) — on-device/simulator tests (e.g., SQLCipher encrypted-executor migration ladder; SQLCipher natives only load on a real device/sim, host `flutter test` links plain libsqlite3)

**Mocking:**
- `mocktail: ^1.0.4` (no codegen, `extends Mock implements X`)

**Async helpers:**
- `fake_async: ^1.3.3` for deterministic time-based tests

**Run Commands:**
```bash
flutter test                       # Run all host tests
flutter test --coverage            # With coverage (CI uses this)
flutter test test/golden/          # Golden tests only
flutter test --tags golden         # Tag-filtered (golden tests carry @Tags(['golden']))
flutter test --plain-name "name"   # Single test by name
```
Run `flutter pub run build_runner build --delete-conflicting-outputs` before testing if annotated classes/tables/ARB changed.

## Test File Organization

**Location:** Separate `test/` tree mirroring `lib/` layer structure:
```
test/
├── unit/              # core, features, shared, application, infrastructure, data
├── application/       # use-case tests (accounting, family_sync)
├── data/repositories/ # repository tests
├── infrastructure/    # crypto, security, voice, sync
├── features/          # accounting, home, family_sync, analytics
├── widget/            # widget tests (features, shared)
├── golden/            # *_golden_test.dart + goldens/ (PNG baselines) + failures/
├── integration/       # on-device flows (voice, sync, data, presentation)
├── architecture/      # structural invariant tests (see below)
├── core/              # initialization, theme
├── helpers/           # shared test utilities
├── fixtures/          # test data
└── flutter_test_config.dart  # global bootstrap (golden platform gate)
```

**Naming:** `{source_name}_test.dart`; golden tests `{widget}_golden_test.dart`.

## Test Structure

**Suite Organization** (mocktail + setUp pattern, from `test/application/accounting/create_transaction_currency_test.dart`):
```dart
class _MockTransactionRepository extends Mock implements TransactionRepository {}
class _FakeTransaction extends Fake implements Transaction {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeTransaction());  // mocktail needs fallbacks for any()
  });

  late _MockTransactionRepository mockTransactionRepo;
  late CreateTransactionUseCase useCase;

  setUp(() {
    mockTransactionRepo = _MockTransactionRepository();
    useCase = CreateTransactionUseCase(transactionRepository: mockTransactionRepo, ...);
  });

  group('CreateTransactionUseCase', () {
    test('persists foreign-currency triple', () async { ... });
  });
}
```

**Patterns:**
- `setUpAll` for `registerFallbackValue` (mocktail `any()` matchers on custom types)
- `setUp` to freshly construct mocks + system-under-test per test (isolation)
- `group(...)` to cluster by behavior
- `late` fields for SUT and mocks
- TDD: many tests carry RED-scaffold headers (e.g., `// WAVE 0 RED SCAFFOLD`) and explicitly say "do NOT weaken these assertions to make them pass" — locked acceptance figures

## Mocking

**Framework:** mocktail (`extends Mock implements X`, prefix `_Mock`).

**Patterns:**
```dart
class _MockHashChainService extends Mock implements HashChainService {}
class _FakeTransaction extends Fake implements Transaction {}  // for registerFallbackValue

when(() => mockRepo.save(any())).thenAnswer((_) async => Result.success(null));
verify(() => mockRepo.save(any())).called(1);
```

**What to Mock:** repository interfaces, services (HashChainService, ClassificationService), device identity.

**What NOT to Mock:** the database in integration paths — use real in-memory `AppDatabase.forTesting()` via `createTestProviderScope` instead.

## Riverpod Test Helpers (`test/helpers/`)

**`test_provider_scope.dart`:**
- `createTestProviderScope({database, additionalOverrides})` — `ProviderContainer` always overriding `appDatabaseProvider` with in-memory `AppDatabase.forTesting()`
- `waitForFirstValue<T>(container, provider)` — REQUIRED for async/auto-dispose providers. Bare `await container.read(provider.future)` errors with `Bad state: disposed during loading` in Riverpod 3; this helper holds a `container.listen(..., fireImmediately: true)` subscription via a `Completer`
- Use `ProviderContainer.test()` in tests (auto-disposes on teardown) instead of manual `addTearDown(container.dispose)`

**`test_localizations.dart`:**
- `createLocalizedWidget(child, {locale, overrides})` — wraps in `ProviderScope` + `MaterialApp` with `S.delegate` + Global delegates for widget tests

## Golden Tests

**Location:** `test/golden/*_golden_test.dart`; PNG baselines in `test/golden/goldens/`; diffs in `test/golden/failures/`.

**Tagged:** every golden file starts with `@Tags(['golden'])` + `library;`.

**Wrapper pattern:** fixed-size `SizedBox` inside `MaterialApp` (localization delegates + `themeMode`) so PNGs are stable across screen sizes. Assert with `matchesGoldenFile('goldens/name.png')`.

**Platform gate (`test/flutter_test_config.dart`):** baselines are macOS-rendered. On non-macOS (CI ubuntu) `BaselineExistenceGoldenComparator` (from `test/helpers/ci_golden_comparator.dart`) only asserts the baseline file exists — keeping crash/widget coverage without pixel mismatch (font-AA diffs 0.05–5.9%). **Update/re-baseline goldens ONLY on macOS** (`flutter test --update-goldens`).

## Architecture Tests (`test/architecture/`)

Structural invariants run as part of the normal suite — they enforce CLAUDE.md rules:
- `domain_import_rules_test.dart` / `presentation_layer_rules_test.dart` — layer dependency direction
- `provider_graph_hygiene_test.dart` — no duplicate repo providers, no `UnimplementedError`
- `arb_key_parity_test.dart` — ja/zh/en ARB key parity
- `hardcoded_cjk_ui_scan_test.dart` — no hardcoded CJK UI strings
- `color_literal_scan_test.dart` — no hardcoded hex colors
- `production_logging_privacy_test.dart` — no sensitive data in logs
- `stale_suppressions_scan_test.dart` — no dead `// ignore:`
- `service_name_collision_test.dart`, `category_other_l2_invariant_test.dart`, `audit_yml_invariants_test.dart`, `low/medium_findings_closed_test.dart`

NOTE: scoped `flutter test path/` runs miss these — per-wave/post-merge gates must run the FULL `flutter test`.

## Coverage

**Target:** 80% project standard (CLAUDE.md / global rules).

**CI gate (`.github/workflows/audit.yml`):** currently enforced at **70%** (Phase 8 amendment 2026-04-28; raise to 80 deferred to backlog `coverage-baseline-review`). Two gates:
- `coverage_gate.dart --threshold 70` on cleanup-touched files (lcov with generated files stripped)
- aggregate `min_coverage: 70`

**Run locally:**
```bash
flutter test --coverage
# generated files are stripped from coverage/lcov.info before the gate
```

## Test Types

**Unit:** use cases (`test/application/`), utilities, repositories, services — mocktail-isolated.
**Widget:** `test/widget/` + `test/features/` via `createLocalizedWidget`.
**Golden:** `test/golden/` — visual regression, macOS-baselined.
**Integration:** `test/integration/` (host) + `integration_test/` (on-device, SQLCipher/migration).
**Architecture:** `test/architecture/` — structural invariants.

## Common Patterns

**Async provider testing:**
```dart
final container = createTestProviderScope();
addTearDown(container.dispose);  // or use ProviderContainer.test()
final result = await waitForFirstValue(container, myAsyncProvider);
expect(result.hasValue, isTrue);
```

**Error testing (Riverpod 3 ProviderException wrapping):**
```dart
expect(
  () => container.read(p),
  throwsA(isA<ProviderException>()
      .having((e) => e.exception, 'exception', isA<StateError>())),
);
```

---

*Testing analysis: 2026-06-23*
