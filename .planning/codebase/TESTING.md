# Testing Patterns

**Analysis Date:** 2026-06-27

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK) — 408 `*_test.dart` files
- `integration_test` (Flutter SDK) — on-device/simulator suites under `test/integration/` (SQLCipher natives only load on real device/sim; host `flutter test` links plain libsqlite3)

**Supporting libraries (`pubspec.yaml` dev_dependencies):**
- `mocktail: ^1.0.4` — mocking (no codegen)
- `fake_async: ^1.3.3` — deterministic time control
- `flutter_lints: ^6.0.0`, `custom_lint: ^0.8.1`, `riverpod_lint: ^3.1.0`, `import_guard_custom_lint: ^1.0.0`

**Run commands:**
```bash
flutter test                                   # Run all tests
flutter test --coverage                        # With coverage (lcov.info)
flutter test test/path/to/file_test.dart       # Single file
flutter test --update-goldens test/golden/...  # Re-baseline goldens (macOS only)
flutter test --tags golden                     # Golden-tagged tests only
```

## Test File Organization

Tests live under `test/`, mirroring `lib/` layering and feature structure:

```
test/
├── unit/            # Pure functions, providers, use cases (mirrors lib/ layers)
│   ├── core/ features/ shared/ application/ infrastructure/ data/ helpers/
├── widget/          # Widget pump tests (features/, shared/)
├── golden/          # Golden image tests + goldens/ baselines + failures/
├── integration/     # On-device suites (voice/, sync/, data/, presentation/)
├── architecture/    # Invariant/guardrail tests (see below)
├── features/        # Feature-scoped tests (accounting, home, family_sync, analytics)
├── application/ infrastructure/ data/ core/   # Layer-scoped tests
├── fixtures/        # Static test data
├── helpers/         # Shared test utilities
└── flutter_test_config.dart  # Global pre-test hook (golden comparator swap)
```

**Naming:**
- `{subject}_test.dart` — standard
- `{subject}_golden_test.dart` — golden, tagged `@Tags(['golden'])`
- `{subject}_characterization_test.dart` — characterization (lock-in existing behavior before refactor)

## Test Structure

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

- `group()` per unit-under-test; descriptive `test()` names often encode the spec case (e.g. arrow notation `input → output`).
- Header doc-comments cite the spec ID / decision (`D-NN`) and any rounding/edge-case rationale.

## Riverpod 3 Testing (critical)

Shared helpers in `test/helpers/test_provider_scope.dart`:

- **`createTestProviderScope({AppDatabase? database, additionalOverrides})`** — builds a `ProviderContainer` that ALWAYS overrides `appDatabaseProvider` with an in-memory `AppDatabase.forTesting()`. Use it so DB-backed providers never touch real storage.
- **`waitForFirstValue<T>(container, provider)`** — REQUIRED for async (Future/Stream) providers. Do NOT do bare `await container.read(provider.future)` on auto-dispose providers: Riverpod 3 disposes the orphan read before the build settles, masking values/errors with `Bad state: disposed during loading`. This helper holds a `container.listen(..., fireImmediately: true)` subscription via a `Completer` and resolves on the terminal `AsyncValue`.
- Use `ProviderContainer.test()` (auto-disposes on teardown) instead of `ProviderContainer() + addTearDown(container.dispose)`.

**Riverpod 3 gotchas in assertions:**
- `AsyncValue.value` is nullable (the old throwing `.valueOrNull` → `.value`).
- Provider-thrown errors are wrapped: assert `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.

## Mocking

**Framework:** `mocktail` (runtime mocks, no codegen).

```dart
when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
when(() => fakeKeyRepo.getDeviceId()).thenAnswer((_) async => 'device-1');
```

- Mock at repository / service interface boundaries; inject via Riverpod `overrideWithValue` / `additionalOverrides`.
- `registerFallbackValue(...)` for custom argument-matcher types.
- **What to mock:** repositories, crypto/key managers, platform services, anything I/O- or device-bound.
- **What NOT to mock:** pure functions (`lib/shared/utils/`), Freezed models, formatters — test them directly. DB-backed code uses real in-memory `AppDatabase.forTesting()`, not mocks.

## Golden Tests

- Tagged `@Tags(['golden'])`; baselines in `test/golden/goldens/`, diff failures dumped to `test/golden/failures/`.
- **Baselines are macOS-rendered.** `test/flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` (`test/helpers/ci_golden_comparator.dart`) when NOT on macOS — CI (ubuntu) only checks the baseline file *exists*, never pixel-matches (font anti-aliasing differs 0.05–5.9%). **Update goldens only on macOS.**
- Pattern: wrap widget in a `MaterialApp` with fixed `locale`, full `S.delegate` + Global*Localizations delegates, fixed `SizedBox`, and a fixed `DateTime` (no `DateTime.now()`); typically 3 locales × theme.

## Architecture / Guardrail Tests (`test/architecture/`)

These are invariant tests that fail the build on regressions — run as part of `flutter test`:

| Test | Enforces |
|------|----------|
| `domain_import_rules_test.dart` | Domain layer import boundaries (mirrors import_guard) |
| `provider_graph_hygiene_test.dart` | No duplicate repo providers, no `UnimplementedError` providers, keepAlive hard-list |
| `hardcoded_cjk_ui_scan_test.dart` | No hardcoded CJK UI strings (with `approvedWhitelist` for lexicons/seed data) |
| `arb_key_parity_test.dart` | ja/zh/en ARB key parity |
| `color_literal_scan_test.dart` | No hardcoded color literals in widgets (use `context.palette`) |
| `presentation_layer_rules_test.dart` | Presentation layer boundaries |
| `production_logging_privacy_test.dart` | No sensitive-data logging |
| `service_name_collision_test.dart` | No duplicate service class names across layers |
| `stale_suppressions_scan_test.dart` | No leftover lint suppressions |
| `low/medium_findings_closed_test.dart`, `audit_yml_invariants_test.dart` | Audit findings stay closed; CI config invariants |

Run the FULL suite (`flutter test`) on per-wave merge gates — scoped test runs miss these architecture tests.

## Coverage

- **Target: ≥80%** per project rules; **CI gate currently 70%** (lowered from 80% in the Phase 8 amendment 2026-04-28 post-cleanup; raise revisited after v1 feature work — backlog `coverage-baseline-review`).
- CI (`.github/workflows/audit.yml`, `coverage` job, blocking):
  1. `flutter test --coverage`
  2. `coverde filter` strips `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/` from `lcov.info` → `lcov_clean.info`
  3. `scripts/coverage_gate.dart` — per-file gate (`--threshold 70`) with explicit `--deferred` rationale list
  4. `VeryGoodOpenSource/very_good_coverage@v2` — `min_coverage: 70` on cleaned lcov
- Tests are first-class code: same quality standards as production.

## Test Types

- **Unit** (`test/unit/`): pure functions, use cases, providers (with in-memory DB).
- **Widget** (`test/widget/`): `testWidgets` pumping minimal `MaterialApp`/`Builder` trees, asserting theme resolution / no-throw / structure rather than pixels.
- **Golden** (`test/golden/`): visual regression, macOS-baselined.
- **Integration** (`test/integration/`): device/sim suites for SQLCipher encrypted-executor, sync, voice.
- **Architecture** (`test/architecture/`): build-failing invariant guards.
- **Characterization** (`*_characterization_test.dart`): lock in existing behavior before refactors (mocktail-heavy).

---

*Testing analysis: 2026-06-27*
