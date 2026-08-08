# Testing Patterns

**Analysis Date:** 2026-08-08

## Test Framework

**Runner:**
- Flutter's `flutter_test`/Dart test runner, with `integration_test` for device and migration journeys (`pubspec.yaml`).
- Global bootstrap: `test/flutter_test_config.dart`.

**Assertion Library:**
- `package:flutter_test/flutter_test.dart` matchers (`equals`, `isNull`, `hasLength`, `throwsA`, `contains`, `matchesGoldenFile`).
- `mocktail` is available for interaction-based mocks; `fake_async` supports deterministic timer tests.

**Run Commands:**
```bash
flutter test                 # all unit/widget/architecture tests
flutter test --coverage     # generate coverage artifacts
flutter test test/path.dart  # targeted file
flutter test integration_test/ # device integration suite
```

## Test File Organization

**Location:** Tests are separate from production code under `test/`, organized by concern: `unit/`, `data/`, `infrastructure/`, `widget/`, `golden/`, `architecture/`, and `scripts/`. Device journeys and fixtures live under `integration_test/`.

**Naming:** Subject-based snake case with `_test.dart`; golden tests are explicitly grouped and tagged (`@Tags(['golden'])` in `test/golden/amount_display_golden_test.dart`).

**Structure:**
```
test/{unit,data,infrastructure,widget,golden,architecture,scripts}/<subject>_test.dart
test/helpers/                 # reusable provider, localization, fixture helpers
integration_test/              # device/database/sync journeys and fixtures
```

## Test Structure

**Suite Organization:**
```dart
void main() {
  late AppDatabase database;
  setUp(() { database = AppDatabase.forTesting(); });
  tearDown(() async { await database.close(); });

  test('describes one behavior', () async {
    final value = await subject.call();
    expect(value, isNotNull);
  });
}
```

**Patterns:**
- Use `group` for a feature/subject and `setUp`/`tearDown` for per-test resources (`test/data/repositories/group_repository_impl_test.dart`).
- Prefer behavior-focused test names and one primary assertion set per behavior. Async tests return `Future` and await all I/O.
- Architecture tests scan source/config contracts (layer imports, ARB parity, release metadata) in `test/architecture/`.

## Mocking

**Framework:** `mocktail` for mocks; provider overrides and in-memory implementations are preferred for Riverpod/database tests.

**Patterns:**
```dart
final container = ProviderContainer(
  overrides: [appDatabaseProvider.overrideWithValue(testDatabase)],
);
addTearDown(container.dispose);
```
`test/helpers/test_provider_scope.dart` centralizes this setup and `ProviderContainer.test()`/`waitForFirstValue` are used for auto-dispose providers.

**What to Mock:** Platform plugins, network clients, secure storage, clocks, and external repositories when testing a single use case. Use `plugin_platform_interface` for platform singleton seams (URL launcher tests).

**What NOT to Mock:** Pure domain models/formatters and Drift behavior when repository tests can use `AppDatabase.forTesting()`; those tests exercise real DAOs and migrations.

## Fixtures and Factories

**Test Data:**
- Shared fixtures live in `test/fixtures/` (voice corpora, merchant false-positive corpus) and `integration_test/fixtures/` (SQLCipher database fixtures).
- Reusable setup helpers live in `test/helpers/`, including localizations, golden comparators, provider scopes, and in-memory repositories.

**Location:** Keep feature-specific builders near the tests unless reused across suites; put cross-suite fixtures/helpers under the directories above.

## Coverage

**Requirements:** Global and configured cleanup-touched files target 70%; deferred exceptions are tracked by project tooling. Coverage baseline/gate behavior is tested in `test/scripts/coverage_baseline_test.dart` and `test/scripts/coverage_gate_test.dart`.

**View Coverage:**
```bash
flutter test --coverage
coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info
```

## Test Types

**Unit Tests:** Domain/application/infrastructure behavior, crypto, repositories, formatters, and scripts under `test/unit/`, `test/infrastructure/`, `test/data/`, and `test/scripts/`.

**Integration Tests:** Real encrypted Drift/SQLCipher migration, backup/restore, sync delivery, and critical user journeys under `integration_test/`; these require a device/simulator.

**E2E Tests:** Device critical journey coverage is implemented by `integration_test/device_critical_journey_test.dart`; no separate web E2E framework is detected.

## Common Patterns

**Async Testing:** Await repository/platform calls; use `testWidgets` with `tester.pumpWidget`, `pump`, and explicit settle controls. Suite-wide onboarding animations are disabled in `test/flutter_test_config.dart` to prevent ticker hangs.

**Error Testing:** Use `expectLater(future, throwsA(isA<StateError>()))` for invariant exceptions and inspect `Result.isError`/`Result.error` for expected use-case failures.

**Golden Testing:** Wrap widgets in fixed-size `SizedBox`, set locale/theme explicitly, load deterministic fonts, and compare via `matchesGoldenFile`. `BaselineExistenceGoldenComparator` makes non-macOS runs verify baseline presence while macOS performs pixel comparison (`test/helpers/ci_golden_comparator.dart`).

---

*Testing analysis: 2026-08-08*
