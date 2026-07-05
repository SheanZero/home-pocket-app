# Testing Patterns

**Analysis Date:** 2026-07-05

## Test Framework

**Runner:**
- `flutter_test` (Flutter SDK) — **435 `*_test.dart` files** (~3,500+ individual test cases in the full suite)
- `integration_test` (Flutter SDK) — 15 on-device/simulator suites under `test/integration/` (SQLCipher natives only load on real device/sim; host `flutter test` links plain libsqlite3)

**Supporting libraries (`pubspec.yaml` dev_dependencies):**
- `mocktail: ^1.0.4` — mocking (no codegen); used by 151 test files
- `fake_async: ^1.3.3` — deterministic time control
- `plugin_platform_interface: ^2.1.8` + `url_launcher_platform_interface: ^2.3.2` — mock `UrlLauncherPlatform.instance` in the sponsor-launch widget test
- `flutter_lints: ^6.0.0`, `custom_lint: ^0.8.1`, `riverpod_lint: ^3.1.0`, `import_guard_custom_lint: ^1.0.0`, `dart_code_linter: ^3.0.0` (audit tooling)
- `yaml: ^3.1.0` — consumed by architecture meta-tests that parse `import_guard.yaml`

**Run commands:**
```bash
flutter test                                   # Run all tests (run the FULL suite on merge gates)
flutter test --coverage                        # With coverage (coverage/lcov.info)
flutter test test/path/to/file_test.dart       # Single file
flutter test --update-goldens test/golden/...  # Re-baseline goldens (macOS ONLY)
flutter test --tags golden                     # Golden-tagged tests only
```

Never pipe `flutter test` through `tail`/`head` — it masks the exit code; trust the `+N/-N` counter and the process exit status.

## Test File Organization

Tests live under `test/`, mirroring `lib/` layering and feature structure:

```
test/
├── unit/            # Pure functions, providers, use cases (mirrors lib/ layers)
│   ├── core/ features/ shared/ application/ infrastructure/ data/ helpers/
├── widget/          # Widget pump tests (features/, shared/)
├── golden/          # Golden image tests + goldens/ baselines + failures/
├── integration/     # On-device suites (voice/, features/, sync/, data/)
├── architecture/    # 17 invariant/guardrail tests (see below)
├── features/ application/ infrastructure/ data/ core/  # Layer/feature-scoped tests
├── fixtures/        # Static test data
├── helpers/         # Shared test utilities (4 files)
├── scripts/         # Tests for scripts/ tooling (e.g. coverage_gate)
├── flutter_test_config.dart          # Global pre-test hook (golden comparator swap)
├── main_characterization_smoke_test.dart  # App-root boot-path characterization
└── widget_test.dart
```

**Naming:**
- `{subject}_test.dart` — standard
- `{subject}_golden_test.dart` — golden, tagged `@Tags(['golden'])` (28 files)
- `{subject}_characterization_test.dart` — characterization / lock-in existing behavior before refactor (18 files)

**Shared helpers (`test/helpers/`):**
- `test_provider_scope.dart` — Riverpod container factory + async settle helper (see below)
- `ci_golden_comparator.dart` — `BaselineExistenceGoldenComparator` for non-macOS CI
- `test_localizations.dart` — `S.delegate` + Global*Localizations wiring for widget/golden pumps
- `happiness_test_fixtures.dart` — domain fixtures for the satisfaction/happiness-ring surfaces

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

- `group()` per unit-under-test; descriptive `test()` names often encode the spec case (arrow notation `input → output`, or a case ID like `CR-01: ...`).
- Header doc-comments cite the spec ID / decision (`D-NN`, `WR-NN`, phase/plan) and any rounding/edge-case rationale.
- **Corpus-driven tests** use a small local case record + a loop: e.g. `_CurrencyCase(input, amount, currency)` iterated over a table of utterances (`test/infrastructure/voice/currency_detection_test.dart`). Prefer this over copy-pasted near-identical `test()` blocks.
- **RED scaffold pattern:** a test may reference an API that does not exist yet, with a header banner (`WAVE 0 RED SCAFFOLD — ... EXPECTED to fail to compile (RED) until plan NN adds X`) and `Do NOT weaken assertions to make them pass`. RED is the intended state until the implementing plan lands.

## Riverpod 3 Testing (critical)

Shared helpers in `test/helpers/test_provider_scope.dart`:

- **`createTestProviderScope({AppDatabase? database, List<Override> additionalOverrides})`** — builds a `ProviderContainer` that ALWAYS overrides `appDatabaseProvider` with an in-memory `AppDatabase.forTesting()`. Use it so DB-backed providers never touch real storage.
- **`waitForFirstValue<T>(container, provider)`** — REQUIRED for async (Future/Stream) providers. Do NOT do bare `await container.read(provider.future)` on auto-dispose providers: Riverpod 3 disposes the orphan read before the build settles, masking values/errors with `Bad state: disposed during loading`. This helper holds a `container.listen(..., fireImmediately: true)` subscription via a `Completer` and resolves on the terminal `AsyncValue`.
- Use `ProviderContainer.test()` (auto-disposes on teardown) instead of `ProviderContainer() + addTearDown(container.dispose)`.
- Inject dependencies via `overrideWithValue` / the `additionalOverrides` list (fakes for use cases, repositories, rate providers, etc.).

**Riverpod 3 gotchas in assertions:**
- `AsyncValue.value` is nullable (the old throwing `.valueOrNull` → `.value`).
- Provider-thrown errors are wrapped: assert `throwsA(isA<ProviderException>().having((e) => e.exception, 'exception', isA<StateError>()))`.
- A new boot-path provider read in `main.dart` breaks app-root characterization tests (`main_characterization_smoke_test.dart` and onboarding/data-reset variants) that don't override it — the scoped executor self-check passes; only the FULL `flutter test` catches it.

## Mocking

**Framework:** `mocktail` (runtime mocks, no codegen). 377 `extends Mock` declarations across the suite; 50 files register fallback values.

```dart
class _MockCategoryRecognizer extends Mock implements CategoryRecognizer {}

when(() => fakeKeyRepo.hasKeyPair()).thenAnswer((_) async => true);
when(() => merchantRecognizer.recognize(any())).thenAnswer((_) async => const <MerchantCandidate>[]);
registerFallbackValue(SomeCustomArg());  // for custom argument-matcher types
```

**Two mocking styles, chosen by need:**
- **`mocktail` mocks** — for pure stubbing of interface methods (`when(...).thenAnswer(...)`).
- **Hand-written fakes** — when a test needs to *capture* what was passed or drive callbacks. Named `_Fake<X>` / `Capturing<X>` / `_Capturing<X>`, they `implement` the interface and store received args (e.g. `CapturingStartSpeechRecognitionUseCase` exposes `onResult`/`startedLocaleId` and an `emitFinal(...)` driver; `_CapturingCreateTransactionUseCase` stores `captured` params to assert the full currency triple). See `test/widget/features/accounting/presentation/screens/voice_input_screen_foreign_save_test.dart`.

**What to mock:** repositories, crypto/key managers, recognizers, platform/plugin services (`UrlLauncherPlatform`), anything I/O- or device-bound.
**What NOT to mock:** pure functions (`lib/shared/utils/`), Freezed models, formatters — test them directly. DB-backed code uses a real in-memory `AppDatabase.forTesting()`, not mocks.

## Golden Tests

- Tagged `@Tags(['golden'])`; baselines in `test/golden/goldens/`, diff failures dumped to `test/golden/failures/`.
- **Baselines are macOS-rendered.** `test/flutter_test_config.dart` swaps in `BaselineExistenceGoldenComparator` (`test/helpers/ci_golden_comparator.dart`) when NOT on macOS — CI (ubuntu) still runs golden tests (keeping widget coverage + crash detection) but only asserts the committed baseline file *exists*, never pixel-matches (font anti-aliasing differs 0.05–5.9%). **Update goldens only on macOS.**
- Pattern: wrap the widget in a `MaterialApp` with fixed `locale`, full `S.delegate` + Global*Localizations delegates (via `test/helpers/test_localizations.dart`), a fixed `SizedBox`, and a fixed `DateTime` (no `DateTime.now()`); typically 3 locales × theme.
- `fl_chart` donut sections with `badgeWidget` throw `RangeError` on section-count change during lerp — set `duration: Duration.zero` on such `PieChart`s (only `DonutHero` uses badges).

## Widget Test Gotchas

- **SnackBar auto-dismiss timers arm outside fake time when a test mixes `tester.binding.runAsync`.** In `voice_input_screen_foreign_save_test.dart`, the commit path uses a real `runAsync` wall-clock delay to settle the pipeline; the conversion-undo SnackBar's dismiss timer is then armed against real time, so `pumpAndSettle`/waiting cannot clear it and it floats over the Save button. Workaround: if a `SnackBar` is present, `tester.drag(find.byType(SnackBar), const Offset(0, 120))` to swipe it away (as a user would) before tapping. Auto-dismiss itself is proven separately in `voice_ptt_session_mixin_test`. Do not "fix" this by removing the SnackBar or shrinking timings.
- Fixed-width button + `Text` can overflow under the flutter_test placeholder font (~1em/glyph) though real fonts fit — wrap the label in a loose `Flexible`; don't shrink the approved width/font.
- Set `tester.view.physicalSize` / `devicePixelRatio` for layout-sensitive widget tests and `addTearDown` the reset.

## Architecture / Guardrail Tests (`test/architecture/`, 17 files)

Invariant tests that fail the build on regressions — part of `flutter test`:

| Test | Enforces |
|------|----------|
| `layer_import_rules_test.dart` | **Real** layer dependency directions — scans hand-written `lib/` files, normalizes relative imports to lib-rooted paths, asserts Presentation→Application→Domain←Data←Infrastructure. This is the actual enforcement point (import_guard deny-mode yamls are inert for relative imports). Exceptions go in its `_allowlist`. |
| `domain_import_rules_test.dart` | Shape of each `domain/import_guard.yaml` (deny set present, no stray `allow:`) — validates config, not real imports |
| `provider_graph_hygiene_test.dart` | No duplicate repo providers, no `UnimplementedError` providers, keepAlive hard-list |
| `presentation_layer_rules_test.dart` | Presentation layer boundaries |
| `hardcoded_cjk_ui_scan_test.dart` | No hardcoded CJK UI strings (with `approvedWhitelist` for lexicons/seed data) |
| `arb_key_parity_test.dart` | ja/zh/en ARB key parity |
| `color_literal_scan_test.dart` | No hardcoded color literals in widgets (use `context.palette`) |
| `production_logging_privacy_test.dart` | No sensitive-data logging |
| `service_name_collision_test.dart` | No duplicate service class names across layers |
| `stale_suppressions_scan_test.dart` | No leftover lint suppressions |
| `low_findings_closed_test.dart`, `medium_findings_closed_test.dart`, `audit_yml_invariants_test.dart` | Audit findings stay closed; CI config invariants |
| `category_other_l2_invariant_test.dart`, `ledger_reachable_l2_invariant_test.dart` | Category/ledger seed-data L2 invariants |
| `legal_asset_parity_test.dart` | `assets/legal/` parity across locales |
| `mod009_live_lib_scan_test.dart` | MOD-009 (deprecated i18n doc) references stay out of live lib |

**Run the FULL suite (`flutter test`) on per-wave merge gates** — scoped test runs miss these architecture tests, and a scoped executor self-check can pass while a full-suite invariant fails.

## Coverage

- **Target: ≥80%** per project rules; **CI gate currently 70%** (lowered from 80% in the Phase 8 amendment 2026-04-28 post-cleanup; raise revisited after v1 feature work — backlog `coverage-baseline-review`, current baseline ~74.6%).
- CI (`.github/workflows/audit.yml`, `coverage` job, blocking on every PR + push to main):
  1. `flutter test --coverage` → `coverage/lcov.info`
  2. `coverde filter` strips `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`, `lib/generated/` → `coverage/lcov_clean.info` (the target is `rm -f`'d first so a partial prior write can't poison the gate)
  3. `scripts/coverage_gate.dart` — **per-file** gate over a curated file list: `--list .planning/audit/cleanup-touched-files.txt --deferred .planning/audit/coverage-gate-deferred.txt --threshold 70 --lcov coverage/lcov_clean.info`. Files on the deferred list are removed from the threshold with an explicit rationale; missing-from-lcov files don't fail (list is generated from PLAN.md). Exit: 0 all pass, 1 a listed file below threshold, 2 invocation error.
  4. `VeryGoodOpenSource/very_good_coverage@v2` — `min_coverage: 70` on the cleaned lcov (whole-suite floor)
  5. `scripts/coverage_baseline.dart` uploads `.planning/audit/coverage-baseline.{txt,json}` artifacts
- Tests are first-class code: same quality standards as production.

## Test Types

- **Unit** (`test/unit/`): pure functions, use cases, providers (with in-memory DB). Dominant category.
- **Widget** (`test/widget/`): `testWidgets` pumping minimal `MaterialApp`/`Builder` trees, asserting theme resolution / no-throw / structure / captured-param outcomes rather than pixels.
- **Golden** (`test/golden/`): visual regression, macOS-baselined (28 files).
- **Integration** (`test/integration/`): device/sim suites for the SQLCipher encrypted-executor migration ladder, sync, and voice corpora (`voice_category_corpus_{ja,zh}`, `voice_corpus_{en,ja,zh}`, `voice_date_corpus`).
- **Architecture** (`test/architecture/`): build-failing invariant guards (17 files).
- **Characterization** (`*_characterization_test.dart`): lock in existing behavior before refactors (18 files, mocktail-heavy; includes the app-root boot smoke test).

---

*Testing analysis: 2026-07-05*
