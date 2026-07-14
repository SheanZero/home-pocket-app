# Testing Patterns

**Analysis Date:** 2026-07-14

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK) — 454 `*_test.dart` files
- `integration_test` (Flutter SDK) — on-device/simulator migration ladder (`integration_test/`); SQLCipher natives only load on a real device/sim, host `flutter test` links plain libsqlite3
- Global bootstrap: `test/flutter_test_config.dart` (`testExecutable`)

**Key dev dependencies:**
- `mocktail: ^1.0.4` — mocking (no codegen)
- `fake_async: ^1.3.3` — deterministic timer control
- `plugin_platform_interface` / `url_launcher_platform_interface` — platform-channel mocking
- Coverage: `coverde 0.3.0+1` + `VeryGoodOpenSource/very_good_coverage`

**Run Commands:**
```bash
flutter test                       # Run all tests
flutter test path/to/file_test.dart  # Single file
flutter test --coverage            # With coverage (writes coverage/lcov.info)
```
IMPORTANT: never pipe `flutter test` through `tail` — it masks the exit code. Trust the `-N` failure counter as ground truth.

## Test File Organization

**Location:** separate `test/` tree mirroring `lib/` (NOT co-located).

**Directory layout:**
```
test/
├── unit/            # 222 tests — pure logic, providers, use cases (mirrors lib/ path)
├── widget/          # 116 tests — widget build/interaction under pump
├── golden/          #  26 tests — pixel-baselined widget snapshots
├── architecture/    # structural invariant guards (see below)
├── integration/     # cross-component / DB flows
├── application/ core/ data/ features/ infrastructure/  # domain-grouped
├── fixtures/        # static test data
├── helpers/         # shared test scaffolding
├── scripts/         # test tooling
├── flutter_test_config.dart          # global bootstrap
└── main_characterization_smoke_test.dart
```

**Naming:** `{subject}_test.dart`; characterization tests suffixed `_characterization_test.dart`.

## Test Structure

**Suite organization** — `group` + `test`/`testWidgets`, descriptive names citing specs/decisions:
```dart
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

Widget tests wrap subjects in a minimal `MaterialApp` harness (`_darkApp`, or `createLocalizedWidget` for i18n):
```dart
await tester.pumpWidget(_darkApp(child: Builder(builder: (context) { ... })));
```

## Riverpod 3 Test Conventions (CRITICAL)

- Use `ProviderContainer.test()` — auto-disposes on teardown (NOT `ProviderContainer() + addTearDown(dispose)`)
- Shared scope helper: `createTestProviderScope({database, additionalOverrides})` in `test/helpers/test_provider_scope.dart` — ALWAYS overrides `appDatabaseProvider` with in-memory `AppDatabase.forTesting()`
- Do NOT do bare `await container.read(provider.future)` on auto-dispose providers — Riverpod 3 disposes the orphan read before build settles ("Bad state: disposed during loading"). Use `waitForFirstValue<T>(container, provider)` which holds a `container.listen(..., fireImmediately: true)` subscription via a `Completer`.
- Provider-thrown errors are wrapped in `ProviderException`; assert:
  ```dart
  throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))
  ```
- `AsyncValue.valueOrNull` renamed to `.value` (now nullable)

## Mocking

**Framework:** `mocktail` (no build step).

**Patterns:**
```dart
class MockCategoryRepo extends Mock implements CategoryRepository {}

final mock = MockCategoryRepo();
when(() => mock.findActive()).thenAnswer((_) async => []);
when(() => mock.findById(any())).thenAnswer((_) async => null);
verify(() => mock.getSettings()).called(greaterThan(0));
```
- `registerFallbackValue(...)` for custom `any()` argument types
- Platform channels mocked via `*_platform_interface` packages (e.g. `UrlLauncherPlatform.instance`)

**What to Mock:** repositories, platform interfaces, key/crypto repos in provider tests.
**What NOT to Mock:** the database — use real in-memory `AppDatabase.forTesting()` via `createTestProviderScope`.

## Localization in Tests

`createLocalizedWidget(child, locale, overrides)` (`test/helpers/test_localizations.dart`) wraps in `ProviderScope` + `MaterialApp` with `S.delegate` and the Global*Localizations delegates. Default locale `en`.

## Golden Tests (platform-gated)

- Baselines are rendered/committed on **macOS**. CI runs ubuntu → cannot pixel-match (font-AA diffs 0.05–5.9%).
- `test/flutter_test_config.dart` swaps `goldenFileComparator` to `BaselineExistenceGoldenComparator` (`test/helpers/ci_golden_comparator.dart`) off-macOS: golden tests still execute (widget coverage + crash detection) but only assert the committed baseline file exists.
- Update baselines ONLY on macOS: `flutter test --update-goldens`.
- Bootstrap also forces `OnboardingFloatDecor.animationsEnabled = false` suite-wide (looping tickers never settle under `pumpAndSettle`).

## Architecture Tests (`test/architecture/`)

Structural invariants that run as normal tests — a green suite is required, and several are the REAL enforcement point where lint yamls are inert:
- `layer_import_rules_test.dart` — real-import layer boundary scan (relative-normalized); the actual enforcer since `import_guard` deny rules are inert for relative imports
- `domain_import_rules_test.dart` — domain never imports data
- `presentation_layer_rules_test.dart`, `service_name_collision_test.dart`
- `provider_graph_hygiene_test.dart` — no duplicate repo providers, no `UnimplementedError` providers
- `arb_key_parity_test.dart` — all 3 ARB files have matching keys
- `hardcoded_cjk_ui_scan_test.dart` — no hardcoded CJK UI strings (must use `S.of`)
- `color_literal_scan_test.dart` — no hardcoded color hex (must use `AppPalette`/`context.palette`)
- `production_logging_privacy_test.dart` — no sensitive-data logging
- `stale_suppressions_scan_test.dart` — no dead `// ignore:` suppressions
- `audit_yml_invariants_test.dart`, `low_findings_closed_test.dart`, `medium_findings_closed_test.dart`, `legal_asset_parity_test.dart`, `mod009_live_lib_scan_test.dart`, `category_other_l2_invariant_test.dart`, `ledger_reachable_l2_invariant_test.dart`

Post-merge/regression gates must run the FULL `flutter test` — scoped test runs miss these architecture invariants.

## Coverage

**Gate:** ≥70% (blocking on every PR + push to main). History: 80% (Phase 2) → 70% (Phase 8 amendment 2026-04-28, post-cleanup; raise to 80% revisited after v1). Project CLAUDE.md still cites the 80% target.

**Two-stage gate in `.github/workflows/audit.yml`:**
1. `flutter test --coverage` → `coverde filter` cleans `coverage/lcov.info` → `coverage/lcov_clean.info`
2. Per-file gate: `dart run scripts/coverage_gate.dart --list .planning/audit/cleanup-touched-files.txt --deferred ... --threshold 70 --lcov coverage/lcov_clean.info`
3. Global gate: `VeryGoodOpenSource/very_good_coverage@v2` with `min_coverage: 70` on `lcov_clean.info`

**View Coverage:**
```bash
flutter test --coverage
coverde filter --input coverage/lcov.info --output coverage/lcov_clean.info ...
```

## Test Types

- **Unit** (`test/unit/`, 222): pure functions, use cases, providers with mocked repos + in-memory DB
- **Widget** (`test/widget/`, 116): build/interaction under `pumpWidget`/`pumpAndSettle`
- **Golden** (`test/golden/`, 26): pixel snapshots, macOS-baselined, existence-only off-macOS
- **Architecture** (`test/architecture/`): structural invariants
- **Characterization**: pin current behavior before refactor (`*_characterization_test.dart`, `main_characterization_smoke_test.dart`)
- **Integration** (`integration_test/`): real SQLCipher on device/sim only

## Common Patterns

**Async provider testing:**
```dart
final container = ProviderContainer.test(overrides: [...]);
final result = await waitForFirstValue(container, someAsyncProvider);
expect(result.hasValue, isTrue);
```

**Fake time (SnackBar/timers):** wrap in `fakeAsync`/`FakeAsync`; NOTE — SnackBar auto-dismiss timers can fall outside a fake zone when mixed with `runAsync`; dismiss via a downward `drag` rather than waiting on the timer (see memory: voice-snackbar-fake-time-test-gotcha).

**Error testing:**
```dart
expect(() => convertToJpy(subunitToUnit: 0, ...), throwsArgumentError);
expect(() => convertToJpy(appliedRate: 'x', ...), throwsFormatException);
```

---

*Testing analysis: 2026-07-14*
