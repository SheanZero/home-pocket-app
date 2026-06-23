# Testing Patterns

**Analysis Date:** 2026-06-23

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK)
- Global bootstrap: `test/flutter_test_config.dart`

**Assertion Library:**
- Built-in `expect` / matchers from `flutter_test` (`equals`, `isA`, `throwsA`, `having`)

**Supporting libs:**
- `mocktail: ^1.0.4` — mocking (no codegen; `class MockX extends Mock implements X`)
- `fake_async: ^1.3.3` — deterministic time control
- `import_guard_custom_lint`, `dart_code_linter`, `yaml` — architecture/audit tests

**Run Commands:**
```bash
flutter test                                    # Run all tests
flutter test --coverage                         # With coverage (lcov)
flutter test test/path/to/foo_test.dart         # Single file
flutter test --update-goldens                   # Regenerate golden baselines (macOS only)
flutter test --tags golden                      # Golden-tagged tests only
```

## Test File Organization

**Location:** Separate `test/` tree mirroring `lib/` layer structure (~392 `_test.dart` files):
```
test/
├── unit/{core,features,shared,application,infrastructure,data}/
├── widget/{features,shared}/
├── integration/{features,voice,sync,data,presentation}/
├── golden/{goldens/,failures/}      # baselines + diff output
├── architecture/                    # structural invariant tests
├── application/  data/  infrastructure/  core/  features/
├── helpers/                         # shared test utilities
├── fixtures/                        # test data corpora
└── scripts/
```

**Naming:** `{subject}_test.dart`; legacy-pinning tests use `{subject}_characterization_test.dart`.

## Test Structure

**Suite Organization:**
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/utils/currency_conversion.dart';

void main() {
  group('convertToJpy', () {
    test('USD 50.00 at 149.30 → 7465', () {
      expect(
        convertToJpy(originalMinorUnits: 5000, appliedRate: '149.30', subunitToUnit: 100),
        equals(7465),
      );
    });
  });
}
```

**Patterns:**
- `group()` per unit/behavior; descriptive test names often include the concrete example (`'USD 1 cent ... → 1'`)
- File-header docstrings cite the spec/decision under test
- Fixed dates (`DateTime(2026, 5, 15)`) — never `DateTime.now()` — for determinism

## Mocking

**Framework:** `mocktail` (no build_runner codegen).

**Patterns:**
- Hand-written stubs via `overrideWith()` / `overrideWithValue()` on Riverpod providers — preferred over deep mocks for provider-driven code (see `main_characterization_smoke_test.dart`: each use-case provider replaced with a stub driving init to a terminal state)
- `class MockX extends Mock implements X {}` where a real collaborator is impractical

**What to Mock:**
- Native-dependent services (SQLCipher, `flutter_secure_storage`) — bypass with provider overrides
- External boundaries (sync engine, push notifications)

**What NOT to Mock:**
- Pure functions / pure `StatelessWidget`s (test directly)
- The database in integration tests — use real in-memory `AppDatabase.forTesting()`

## Fixtures and Factories

**Test Data:** `test/fixtures/` holds reusable corpora:
- `voice_corpus_{ja,zh}.dart`, `voice_category_corpus_{ja,zh}.dart`

**Helpers (`test/helpers/`):**
- `test_provider_scope.dart` — `createTestProviderScope()` always overrides `appDatabaseProvider` with in-memory DB; `waitForFirstValue<T>(container, provider)` holds a `container.listen(..., fireImmediately: true)` subscription so Riverpod 3 doesn't dispose orphan async reads mid-build
- `test_localizations.dart` — localization wiring for widget tests
- `happiness_test_fixtures.dart` — domain fixtures
- `ci_golden_comparator.dart` — `BaselineExistenceGoldenComparator`

## Coverage

**Requirements:** Target 80% (per project rules). Current baseline ~74.6% — the CI `coverage` job runs `flutter test --coverage` but is non-blocking until v1 feature work completes (`audit.yml`, backlog `coverage-baseline-review`).

**View Coverage:**
```bash
flutter test --coverage    # → coverage/lcov.info
```

## Test Types

**Unit Tests** (`test/unit/`): Pure functions, services, use cases, providers in isolation.

**Widget Tests** (`test/widget/`): `testWidgets` + `pumpWidget`, wrapped in `UncontrolledProviderScope`/`MaterialApp` with overrides.

**Integration Tests** (`test/integration/`): Cross-layer flows against real in-memory `AppDatabase.forTesting()` (voice, sync, data, presentation).

**Golden Tests** (`test/golden/`): `@Tags(['golden'])`; baselines in `test/golden/goldens/`. Platform-gated — baselines are macOS-rendered; on non-macOS CI (ubuntu) `flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` (asserts baseline file exists, skips pixel match due to 0.05–5.9% font-AA diff). **Update goldens only on macOS.**

**Architecture Tests** (`test/architecture/`): Structural invariants enforced as tests — `domain_import_rules_test.dart` (layer deps), `provider_graph_hygiene_test.dart` (no duplicate/UnimplementedError providers), `hardcoded_cjk_ui_scan_test.dart` (no hardcoded strings), `color_literal_scan_test.dart`, `arb_key_parity_test.dart` (3-language ARB sync), `production_logging_privacy_test.dart`, `service_name_collision_test.dart`.

## Common Patterns

**Async Testing (Riverpod 3 — critical):**
```dart
// Do NOT: await container.read(provider.future)  // disposed-during-loading on auto-dispose
final result = await waitForFirstValue<MyType>(container, myProvider);
// Prefer ProviderContainer.test() over ProviderContainer() + addTearDown(dispose)
```

**Error Testing (Riverpod 3 wraps in ProviderException):**
```dart
expect(
  () => container.read(provider),
  throwsA(isA<ProviderException>()
      .having((e) => e.exception, 'exception', isA<StateError>())),
);
```

**Time control:** use `fake_async` / fixed `DateTime` literals — never wall-clock time.

---

*Testing analysis: 2026-06-23*
