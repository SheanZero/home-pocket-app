# Phase 58: Flutter, Analyzer & Code Generation Lane - Pattern Map

**Mapped:** 2026-08-06  
**Files analyzed:** 17 explicit inputs plus generated-output families  
**Analogs found:** 17 / 17

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `pubspec.yaml` | config | transform | current `pubspec.yaml` | exact |
| `pubspec.lock` | config | transform | current `pubspec.lock` | exact |
| `.metadata` | config | transform | current `.metadata` | exact |
| `analysis_options.yaml` | config | request-response | current `analysis_options.yaml` | exact |
| `build.yaml` | config | transform | current `build.yaml` | exact |
| `l10n.yaml` | config | transform | current `l10n.yaml` | exact |
| `docs/testing/STABLE_BASELINE.json` | config/manifest | transform | current manifest | exact |
| `docs/testing/DEPENDENCY_COMPATIBILITY.md` | config/documentation | transform | current policy | exact |
| `scripts/dependency_compatibility.dart` | utility/validator | request-response | current validator | exact |
| `test/architecture/dependency_compatibility_contract_test.dart` | test | transform | current contract test | exact |
| `test/architecture/{layer,domain,presentation}_*_rules_test.dart` | test | transform | current architecture tests | exact |
| `.github/workflows/audit.yml` | config/CI | batch | current blocking audit workflow | exact |
| `.github/workflows/flutter-future-compat.yml` | config/CI | batch | current beta probe workflow | exact |
| `lib/**/providers.dart` where a selected Riverpod API requires syntax migration | provider/source | request-response | `lib/infrastructure/security/providers.dart` | role-match |
| `lib/**/models/*.dart` where Freezed/JSON syntax needs migration | model/source | transform | `lib/infrastructure/i18n/models/locale_settings.dart` | role-match |
| `lib/data/app_database.dart` only if the selected Drift cohort requires it | model/database source | CRUD/transform | current `lib/data/app_database.dart` | exact |
| tracked `lib/**/*.g.dart`, `lib/**/*.freezed.dart`, `lib/generated/*.dart` | generated output | transform | existing outputs named at right | exact |

The phase context specifies no preselected individual migration source file. Treat all handwritten generator inputs as conditional: only change a source file when the selected stable cohort fails to compile/generate without its required mechanical migration. Do not hand-edit any output file.

## Pattern Assignments

### `pubspec.yaml` and `pubspec.lock` (config, transform)

**Analog:** `pubspec.yaml` lines 6-25 and 92-124; `pubspec.lock` analyzer/codegen package records.

Keep the language declaration and runtime/annotation/dev-generator cohort together. The current source places runtime annotations with runtime libraries and generators/lints under `dev_dependencies`:

```yaml
environment:
  sdk: ^3.10.8

# State Management
flutter_riverpod: ^3.1.0
riverpod_annotation: ^4.0.0

# Immutable Models
freezed_annotation: ^3.0.0
json_annotation: ^4.9.0

# Code Generation
build_runner: ^2.4.14
freezed: ^3.0.0
json_serializable: ^6.9.4
riverpod_generator: ^4.0.0+1
custom_lint: ^0.8.1
riverpod_lint: ^3.1.0
drift_dev: ^2.25.0

# Audit Tooling
import_guard_custom_lint: ^1.0.0
```

Source: `pubspec.yaml` lines 6-25, 70-75, 102-124.

The lock is the resolved, committed evidence rather than a manually maintained version list. Its current records show the lane’s selected values: analyzer `8.4.0`, build_runner `2.15.1`, Drift/drift_dev `2.31.0`, Freezed `3.2.3`/annotation `3.1.0`, JSON `4.9.0`/`6.11.2`, Riverpod `3.1.0`/`4.0.0`/generator `4.0.0+1`/lint `3.1.0`, custom_lint `0.8.1`, and import_guard `1.0.0` (`pubspec.lock` lines 28-35, 108-115, 284-291, 340-355, 563-570, 637-652, 794-862, 1238-1261).

**Required pattern:** edit declared constraints as the coherent selected lane, resolve with `flutter pub get --enforce-lockfile`, and use the produced lockfile. Never add `dependency_overrides` or `pubspec_overrides.yaml`; the validator rejects both (`scripts/dependency_compatibility.dart` lines 426-431).

### `.metadata`, baseline manifest, and human policy (config/manifest, transform)

**Analogs:** `.metadata` lines 6-23; `docs/testing/STABLE_BASELINE.json` toolchain/dependency entries; `docs/testing/DEPENDENCY_COMPATIBILITY.md` lines 3-13 and 17-28.

Keep one Stable identity across Flutter revision/channel, Dart SDK, manifest, and CI. `.metadata` is Flutter-managed/version-controlled; it records the selected framework revision and `stable` channel:

```yaml
version:
  revision: "058e0af2c2b57e369d905a03ac9748b0ebf543c6"
  channel: "stable"
```

Source: `.metadata` lines 1-23.

The manifest is the canonical source of version decisions; its row schema carries selected/resolved value, production candidate, decision, owner, primary source, date, and—when held—reason and exit condition. The parser requires those fields and accumulates every diagnostic rather than stopping at the first problem (`scripts/dependency_compatibility.dart` lines 79-180 and 183-231). The Markdown policy links to the JSON instead of duplicating it (`docs/testing/DEPENDENCY_COMPATIBILITY.md` lines 3-13), then describes the analyzer/codegen lane and explicit exit condition (`lines 17-28`).

**Required pattern:** after re-querying official sources at execution, update the manifest, `pubspec.yaml`, generated `pubspec.lock`, `.metadata` if Flutter changes, CI pins, prose matrix, and all SHA-256 tracked-input records atomically. A changed tracked input without a new manifest digest is a failure (`scripts/dependency_compatibility.dart` lines 700-722, 935-951).

### `scripts/dependency_compatibility.dart` (utility/validator, request-response)

**Analog:** the file itself, especially the lane assertions and CLI adapter.

The validator accepts checked-in contents as parameters, aggregates issues into an immutable report, and validates both constraints and lock resolution. Preserve that testable, pure core pattern:

```dart
final actualDependencyKeys = allDirectDependencies.keys
    .map((key) => key.toString())
    .toSet();
// Reject manifest inventory drift in either direction, then compare each
// declared constraint and resolved lock version.

expectConstraint('flutter_riverpod', '^3.1.0');
expectLocked('flutter_riverpod', '3.1.0');
// ...same paired assertions for the selected cohort...
if (analyzerVersion == null || !RegExp(r'^8\\.\\d+\\.\\d+$').hasMatch(analyzerVersion)) {
  issues.add('analyzer lock must stay on the verified 8.x line ...');
}
```

Source: `scripts/dependency_compatibility.dart` lines 303-379.

For an analyzer-9-compatible outcome, replace the analyzer-8 assertion with the explicitly selected compatible policy and add/adjust lane completeness checks; for an evidence-backed hold, preserve/enforce the 8.x check. Do not merely weaken the assertion. Keep SDK identity validation tied to manifest, `.metadata`, all Stable CI pins, running `flutter --version --machine`, and Flutter’s resolved `FlutterExtension.kt` (`lines 725-815`). Keep the thin CLI as the only filesystem/process adapter (`lines 935-1043`).

### Dependency compatibility contract test (test, transform)

**Analog:** `test/architecture/dependency_compatibility_contract_test.dart`.

Read real repository inputs once, pass them to the real validator, mutate copies, and assert a specific failure message. That is the established negative-fixture pattern:

```dart
Map<String, String> currentInputs() => {
  'pubspec': File('pubspec.yaml').readAsStringSync(),
  'lock': File('pubspec.lock').readAsStringSync(),
  // native, CI and metadata inputs follow
};

test('rejects dependency_overrides in pubspec independently', () {
  final input = currentInputs();
  input['pubspec'] = '${input['pubspec']}\\ndependency_overrides:\\n  intl: 0.20.2\\n';
  expect(validate(input), contains('pubspec dependency_overrides must not be present'));
});
```

Source: `test/architecture/dependency_compatibility_contract_test.dart` lines 28-118 and 291-305.

Extend this same file whenever changing selected versions, lane membership, SDK identity, tracked inputs, or workflow contract. Retain the negative tests proving comment-only workflow validators, override rejection, EOL rejection, partial-lane rejection, and runtime SDK mismatch remain fail-closed (`lines 308-500`). Retain CI ordering/probe tests (`lines 700-742`) and the future-probe severity boundary (`lines 556-698`).

### Analyzer and generator configuration (config, transform)

**Analogs:** `analysis_options.yaml`, `build.yaml`, `l10n.yaml`.

The analyzer keeps `custom_lint` enabled while excluding generated outputs; do not make a generator/analyzer upgrade green by removing this plugin:

```yaml
analyzer:
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"
    - "build/**"
  errors:
    invalid_annotation_target: ignore
  plugins:
    - custom_lint
```

Source: `analysis_options.yaml` lines 1-17.

The generator configuration is minimal and explicit: Freezed formatting and JSON `explicit_to_json` (`build.yaml` lines 1-9); localization’s ARB source and generated output contract stays at `lib/l10n` → `lib/generated` with `S` (`l10n.yaml` lines 1-6). Preserve these behavior/configuration options unless a selected tool mandates a documented replacement.

### CI workflows (config, batch)

**Stable analog:** `.github/workflows/audit.yml`.

Stable CI must use the exact manifest Flutter version, enforced lock resolution, then SDK validation before analysis:

```yaml
- uses: subosito/flutter-action@v2
  with:
    channel: stable
    flutter-version: 3.44.8
- run: flutter pub get --enforce-lockfile
- name: Dependency compatibility contract
  run: dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
- name: flutter analyze
  run: flutter analyze --no-fatal-infos
- name: dart run custom_lint
  run: dart run custom_lint --no-fatal-infos
```

Source: `.github/workflows/audit.yml` lines 23-53. The separate guardrail job regenerates with `--delete-conflicting-outputs` and fails if `git diff --exit-code lib/` shows stale generated output (`lines 71-102`). If localization output must be included in the reproducibility transaction, add `flutter gen-l10n` before the build-runner clean-diff check, matching the phase decision’s locked order.

**Future-probe analog:** `.github/workflows/flutter-future-compat.yml` lines 18-53. It must remain beta, scheduled/advisory, with real Android/iOS builds and `--mode=future-probe`; never repurpose this workflow as the production baseline.

### Architecture enforcement tests (test, transform)

**Analogs:** `test/architecture/layer_import_rules_test.dart`, `domain_import_rules_test.dart`, and `presentation_layer_rules_test.dart`.

The real-import scanner is the defense for relative imports that package-URI import guards cannot see. It intentionally scans handwritten `lib/` files and excludes generated/localization output:

```dart
.where((f) =>
  f.path.endsWith('.dart') &&
  !f.path.endsWith('.g.dart') &&
  !f.path.endsWith('.freezed.dart') &&
  !f.path.startsWith('lib/generated/'),
);
```

Source: `test/architecture/layer_import_rules_test.dart` lines 53-80, 92-152. Retain all four actual dependency-direction rules (`lines 95-127`), then retain import-guard YAML structural checks for domain deny/allow/inherit (`domain_import_rules_test.dart` lines 21-143) and presentation denies (`presentation_layer_rules_test.dart` lines 5-51). These should be extended only if selected lint APIs force compatible configuration edits; never lower their assertions.

### Conditional handwritten Riverpod, Freezed/JSON, and Drift sources (provider/model/database source)

**Riverpod analog:** `lib/infrastructure/security/providers.dart` lines 1-10 and 42-70.

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) => BiometricService();

@riverpod
Future<BiometricAvailability> biometricAvailability(Ref ref) async { ... }
```

The paired output, `lib/infrastructure/security/providers.g.dart` lines 1-17 and 71-116, demonstrates the generator-owned provider names/lifecycle types. Change the handwritten source only if required; regenerate the paired `.g.dart` rather than editing it.

**Freezed analog:** `lib/infrastructure/i18n/models/locale_settings.dart` lines 1-27, whose `part 'locale_settings.freezed.dart';`, `@freezed`, and immutable factory contract generate `locale_settings.freezed.dart` (`lines 1-55`). Maintain domain/model behavior and imports; accept generator format changes only as reviewed output.

**Drift analog:** `lib/data/app_database.dart` lines 28-65, which declares `part 'app_database.g.dart';`, tables, and schema version; its generator output begins with `GENERATED CODE - DO NOT MODIFY BY HAND` in `lib/data/app_database.g.dart` lines 1-6. No schema/migration change is in Phase 58, so do not change schema version, table list, migrations, or SQLCipher behavior merely to satisfy the generator cohort.

**Localization output analog:** `lib/generated/app_localizations.dart` lines 1-12 and 65-100 is owned by `l10n.yaml` plus ARBs. Run `flutter gen-l10n`; do not edit the generated class directly.

## Shared Patterns

### Coherent lane and hold evidence

**Sources:** `docs/testing/STABLE_BASELINE.json` entries for Phase 58; `docs/testing/DEPENDENCY_COMPATIBILITY.md` lines 19-23; `scripts/dependency_compatibility.dart` lines 303-379.

Apply to all dependency/config changes: runtime, annotations, generators, analyzer, `custom_lint`, `riverpod_lint`, import guard, and Drift are selected as one graph. A deliberate analyzer-8 hold is acceptable only if its official evidence, reason, and exit condition are recorded and the validator asserts it. No overrides or split runtime/generator contract.

### Clean reproducible generation

**Sources:** `AGENTS.md` generation rules; `.github/workflows/audit.yml` lines 95-102; `docs/testing/DEPENDENCY_COMPATIBILITY.md` lines 52-63.

Apply to all generator inputs: locked resolution → `flutter gen-l10n` → `flutter pub run build_runner build --delete-conflicting-outputs` → inspect tracked generated and localization output. Run the same clean generation a second time; unexplained remaining tracked diffs block the phase. Generated Dart/localization files are never hand-edited.

### Independent architecture/lint protection

**Sources:** `analysis_options.yaml` lines 3-11; `.github/workflows/audit.yml` lines 45-53; architecture tests named above.

Custom lint/import guard remains enabled, but its package-URI limitation is compensated by source-scanning layer tests. Preserve both enforcement paths and add negative regression fixtures to the contract test for any lint/analyzer configuration migration.

### Error handling and reporting

**Source:** `scripts/dependency_compatibility.dart` lines 23-35, 700-722, and 1011-1043.

Validator logic accumulates stable diagnostic messages, returns an immutable report, and the CLI formats error code plus message before nonzero exit. Follow this for new policy assertions so tests can prove rejection precisely.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Exact handwritten source files requiring syntax migration | provider/model/database source | transform | The selected production-stable graph is not known until official execution-date resolution; use the representative Riverpod, Freezed, and Drift input/output pairs above and alter only compiler-required inputs. |

## Metadata

**Analog search scope:** root configuration, `docs/testing/`, `scripts/`, `test/architecture/`, `.github/workflows/`, representative `lib/` handwritten/generator outputs  
**Files scanned:** 23 primary files plus lock/output family listings  
**Pattern extraction date:** 2026-08-06
