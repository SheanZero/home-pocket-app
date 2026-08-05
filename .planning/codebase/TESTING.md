# Testing Patterns

**Analysis Date:** 2026-08-05
**Last mapped commit:** `7b4f1bac44644ea821835e85d09d9571a601e82a`

## Test Framework

Flutter `flutter_test` is primary (564 test files); `integration_test` covers device/simulator flows. Dependencies include `mocktail`, `fake_async`, and platform-interface fakes. Global setup is `test/flutter_test_config.dart`.

Run `flutter test`, `flutter test path/to/file_test.dart`, `flutter test --coverage`, and `flutter test integration_test/`; do not pipe output through `tail` because it can mask exit codes.

## Test File Organization

Tests are separate from production and mirror domains:

```text
test/unit/ (283)       pure logic, use cases, providers
test/widget/ (139)     widget build and interaction
test/golden/ (38)      pixel-baselined widgets
test/architecture/ (23) structural contracts
test/integration/ (18) cross-component/device flows
test/helpers/          shared scaffolding
```

Use `{subject}_test.dart`; use `_characterization_test.dart` for pinned behavior. Place new tests in the closest mirrored `test/unit`, `test/widget`, `test/golden`, `test/architecture`, or `test/integration` subtree.

## Test Structure and Riverpod

Organize with `group` and descriptive `test`/`testWidgets` names. Widget tests use a minimal `MaterialApp`, `_darkApp`, or `createLocalizedWidget` from `test/helpers/test_localizations.dart`, then pump before assertions. Use `ProviderContainer.test()` and `createTestProviderScope` from `test/helpers/test_provider_scope.dart`; override `appDatabaseProvider` with `AppDatabase.forTesting()`. Hold auto-dispose async providers with `waitForFirstValue(...)`, and inspect `ProviderException.exception` for failures.

## Mocking and Fixtures

Use mocktail (`class MockRepo extends Mock implements Repo {}`), `when(...).thenAnswer`, `verify`, and `registerFallbackValue` in `setUpAll`. Mock repositories, platform interfaces, and crypto boundaries; use real in-memory Drift instead of mocking the database. Temporary filesystem tests create and clean `Directory.systemTemp` fixtures (for example `test/unit/application/settings/import_backup_use_case_resource_limits_test.dart`).

## Golden Tests

Baselines live in `test/golden/goldens/` and feature widget golden directories. macOS updates with `flutter test --update-goldens`; non-macOS uses `BaselineExistenceGoldenComparator` from `test/flutter_test_config.dart`, checking files while still exercising widgets. The bootstrap disables looping onboarding animation via `OnboardingFloatDecor.animationsEnabled = false`.

## Architecture and Integration Contracts

Run the full suite after merges: architecture tests enforce layer imports, domain isolation, provider graph hygiene, ARB parity, hardcoded CJK, color literals, logging privacy, stale suppressions, legal assets, and related invariants. SQLCipher integration tests require a real device/simulator; host tests use test paths.

## Coverage

CI enforces 70% global and cleanup-touched-file coverage. `.github/workflows/audit.yml` runs `flutter test --coverage`, filters via `coverde`, then `scripts/coverage_gate.dart` and VeryGoodOpenSource coverage. Deferred files are listed in planning audit configuration.

## Common Patterns

Use `fakeAsync` for deterministic timers; dismiss SnackBars by gesture when `runAsync` would escape the fake zone. Assert typed errors (`throwsArgumentError`, `throwsFormatException`) or structured result errors. Keep tests deterministic, localized through generated delegates, and free of sensitive fixture data.

---

*Testing analysis: 2026-08-05*
