# Phase 58: Flutter, Analyzer & Code Generation Lane - Research

**Researched:** 2026-08-06
**Domain:** Flutter/Dart stable toolchain, analyzer plugins, and generated-source reproducibility
**Confidence:** MEDIUM — current values and constraints were queried from the official Flutter release manifest and official Pub APIs; the Pub solver was not run during research because this task must not mutate the working graph.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

### Stable SDK Identity
- **D-01:** Normalize development, CI metadata and the declared Dart SDK range around the already verified and locally installed Flutter **3.44.8 Stable / Dart 3.12.2** identity. Do not switch to beta, RC, dev, or an unverified newer channel.
- **D-02:** Re-query official primary sources at execution time. If a newer production-stable patch is released during the phase, it may replace 3.44.8 only after the same baseline identity and full gate evidence is updated atomically.

### Analyzer and Architecture Enforcement
- **D-03:** Select the newest mutually compatible production-stable analyzer/custom-lint/import-guard graph without `dependency_overrides` or `pubspec_overrides.yaml`.
- **D-04:** Architecture protection is a release invariant: deliberately invalid imports must still fail `import_guard`, custom lint, Riverpod lint, and the repository's source-scanning architecture tests. Raising a version never justifies weakening a deny rule or suppressing diagnostics.
- **D-05:** If the latest analyzer major cannot coexist with the stable lint/import-guard ecosystem, record and enforce the highest compatible analyzer as an evidence-backed hold with an explicit exit condition. Do not force an internally split graph.

### Generator Compatibility Cohort
- **D-06:** Treat Riverpod runtime/annotations/generator/lint, Freezed runtime/annotations/generator, JSON annotations/serializer, Drift runtime/dev, analyzer-facing support packages, and build_runner as one compatibility cohort. Upgrade in small attributable steps but validate the final graph as one unit.
- **D-07:** Update source syntax only where the selected stable packages require it. Preserve Riverpod 3 conventions, provider names, domain purity, schema behavior, and existing application behavior.

### Reproducible Generation Evidence
- **D-08:** The authoritative generation sequence is locked dependency resolution, `flutter gen-l10n`, and build_runner with `--delete-conflicting-outputs`, followed by analyzer, lint and architecture gates.
- **D-09:** Generated Dart and localization output is never hand-edited. Expected generator changes must be reviewed and committed with their source inputs; an unexplained tracked diff after a second clean generation is blocking.
- **D-10:** No product feature, database migration, platform-plugin migration, or native toolchain change is accepted merely to make the generator lane green. Such work remains in its owning later phase.

### the agent's Discretion
- Choose the exact order of compatible cohort increments, targeted characterization tests, and commit boundaries.
- Apply mechanical source migrations required by stable generator APIs when behavior and architecture contracts remain unchanged.

### Deferred Ideas (OUT OF SCOPE)

- File/share/speech/notification/biometric/secure-storage plugin cohorts belong to Phase 59.
- SQLCipher/sqlite3, CocoaPods/SwiftPM cleanup, encrypted reopen and backup proof belong to Phase 60.
- AGP/Kotlin/Gradle/Android release-host migration belongs to Phase 61.
- Wired-iPhone isolated Bundle ID and physical acceptance belong to Phase 63.
</user_constraints>

## Project Constraints (from AGENTS.md)

- Work on `main`; inspect `git status -sb` before edits; preserve unrelated user changes; do not commit or push unless requested. [VERIFIED: AGENTS.md]
- Keep Clean Architecture import direction: infrastructure has no feature/application/data dependency; data has no presentation/application dependency; domain remains independent of Flutter, Drift, Riverpod, and platform SDKs. [VERIFIED: AGENTS.md:47-59]
- Riverpod remains 3.1+ code-generated; retain the documented Riverpod 3 imports, generated provider naming, nullable `.value`, `ProviderException.exception`, and `ref.listen` side-effect rules. [VERIFIED: AGENTS.md:86-106]
- Regenerate after changing `@riverpod`, Freezed, Drift, or `part '*.g.dart'` inputs; run `flutter gen-l10n` after ARB changes; never hand-edit generated output. [VERIFIED: AGENTS.md:63-82]
- Preserve `sqlcipher_flutter_libs` on `^0.6.x`; never introduce `sqlite3_flutter_libs`; retain local-first/zero-knowledge and never log sensitive financial or crypto data. [VERIFIED: AGENTS.md:110-134,200-205]
- Keep iOS 15+ and Android API 24 support. Do not alter the SQLCipher iOS linker strip or the listed native dependency pins in this lane. [VERIFIED: docs/testing/STABLE_BASELINE.json:5-12]
- Use TDD for behavior changes. Required quality gates are zero-issue `flutter analyze`, relevant targeted tests, full `flutter test` for broad behavior changes, and the 70% coverage gate; if test-process timeouts occur, rerun affected files then confirm the suite with `--concurrency=1`. [VERIFIED: AGENTS.md:173-196]
- Do not mix broad formatter churn or unrelated generated changes into the scoped commit. [VERIFIED: AGENTS.md:188-196]

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| GEN-01 | Flutter 3.44.8 / Dart 3.12.2 and CI/declaration use one stable identity. | Official Flutter release manifest and local machine both identify this pair; update the declared SDK range and preserve CI/.metadata identity. |
| GEN-02 | Resolve or explicitly hold the import-guard analyzer `<9` blocker while keeping invalid-import gates. | The exact hold is analyzer 8.4.0. Add executable negative fixtures for `import_guard`, the independent layer scanner, and Riverpod lint. |
| GEN-03 | Resolve Riverpod, Freezed, JSON, Drift, build_runner, analyzer and lints as one stable graph, without overrides or split lanes. | The current lock is the newest mutually compatible graph; record precise constraints and block all newer incompatible majors through the compatibility contract. |
| GEN-04 | Clean resolve, localization and code generation leave no unexplained tracked diff. | Use a two-pass clean-generation oracle, including `git diff --exit-code` over generated/localization output. |
</phase_requirements>

## Summary

The selected production toolchain is still Flutter **3.44.8 Stable** with Dart **3.12.2**, framework revision `058e0af2c2b57e369d905a03ac9748b0ebf543c6`. Flutter’s official release manifest reports this pairing, and the locally installed Flutter reports the same identity. [CITED: https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json] [VERIFIED: `.metadata`:6-23]

The newest mutually compatible, production-stable no-override graph is the graph already resolved in `pubspec.lock`, with one critical clarification: analyzer must be **exactly 8.4.0**. `import_guard_custom_lint` 1.0.0 requires analyzer `>=7.0.0 <9.0.0`; `custom_lint` 0.8.1 permits analyzer 8; but its permitted `analyzer_plugin` 0.13.10 requires analyzer 8.4.0 exactly, while 0.13.11 requires analyzer 9.0.0. Therefore analyzer 8.4.1 is not a viable patch upgrade in this graph. [CITED: https://pub.dev/api/packages/import_guard_custom_lint] [CITED: https://pub.dev/api/packages/custom_lint] [CITED: https://pub.dev/api/packages/analyzer_plugin]

**Primary recommendation:** Keep the current resolved analyzer-8 cohort, change `environment.sdk` to `^3.12.2`, explicitly register `riverpod_lint` as an analysis-server plugin, convert the broad analyzer-8 assertion into an exact graph contract, re-query and record the current candidates/holds, and prove the guardrails with reversible negative fixtures before doing the clean two-pass generation proof.

DATA_N9K4Q2VA_START
> `sdk: ^3.10.8`
>
> `flutter_riverpod: ^3.1.0`
>
> `build_runner: ^2.4.14`
>
> `import_guard_custom_lint: ^1.0.0`
DATA_N9K4Q2VA_END

The quotation records the current declaration that Phase 58 will tighten around the selected graph. [VERIFIED: pubspec.yaml:6-7,20-25,102-121]

DATA_F2W9M6RX_START
> `"selected": "15.0"`
>
> `"selected": 24`
DATA_F2W9M6RX_END

These are the locked minimum iOS and Android support floors; this phase has no authority to lower either floor. [VERIFIED: docs/testing/STABLE_BASELINE.json:5-12]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| Flutter/Dart identity and Pub resolution | Build/CI tooling | Developer workstation | SDK pin, declared SDK range, lockfile, and CI must agree before application code runs. |
| Analyzer/custom lint/import architecture enforcement | Build/CI tooling | Repository source tests | Analyzer plugins examine source; repository scanners independently protect relative imports. |
| Riverpod/Freezed/JSON/Drift generation | Build/CI tooling | Source tree | Generators derive committed output from source annotations/configuration; generated Dart is not authored manually. |
| User accounting data and crypto/native behavior | Later native/data lanes | — | This lane must not alter database schemas, SQLCipher, platform plugins, or host build tooling. |

## Standard Stack

### Core — selected production-stable graph

| Library / tool | Exact selected version | Purpose | Compatibility rationale |
|----------------|------------------------|---------|-------------------------|
| Flutter / Dart | 3.44.8 / 3.12.2 | SDK and compiler | Current Stable manifest pair; local toolchain and `.metadata` match. [CITED: https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json] |
| analyzer | 8.4.0 | Dart analysis API shared by plugins/generators | Exact ceiling forced by analyzer-plugin compatibility; 8.4.1 cannot satisfy `analyzer_plugin` 0.13.10. [CITED: https://pub.dev/api/packages/analyzer_plugin] |
| custom_lint | 0.8.1 | Runs `import_guard_custom_lint` | Latest published custom_lint; accepts analyzer `^8.0.0`. [CITED: https://pub.dev/api/packages/custom_lint] |
| import_guard_custom_lint | 1.0.0 | Package-import boundary diagnostics | Latest published version; accepts analyzer below 9 and custom_lint_builder below 0.9. [CITED: https://pub.dev/api/packages/import_guard_custom_lint] |
| flutter_riverpod / riverpod / riverpod_annotation | 3.1.0 / 3.1.0 / 4.0.0 | Runtime and annotations | `riverpod_annotation` 4.0.0 requires Riverpod 3.1.0; do not split runtime from generated output. [CITED: https://pub.dev/api/packages/riverpod_annotation] |
| riverpod_generator / riverpod_lint | 4.0.0+1 / 3.1.0 | Provider generation and static diagnostics | Last analyzer-8-compatible releases; newer 4.0.8 / 3.1.8 require analyzer `^13.0.0`. [CITED: https://pub.dev/api/packages/riverpod_generator] [CITED: https://pub.dev/api/packages/riverpod_lint] |
| freezed_annotation / freezed | 3.1.0 / 3.2.3 | Immutable model annotations/generator | 3.2.3 accepts analyzer `<9`; newer 3.2.5 requires analyzer `>=9.0.0 <11.0.0`. [CITED: https://pub.dev/api/packages/freezed] |
| json_annotation / json_serializable | 4.9.0 / 6.11.2 | JSON annotations/generator | 6.11.2 accepts analyzer `<9`; newer 6.14.1 requires analyzer `>=10.0.0 <15.0.0`. [CITED: https://pub.dev/api/packages/json_serializable] |
| drift / drift_dev | 2.31.0 / 2.31.0 | Database runtime and generated DAOs | 2.31.0 stays compatible with sqlite3 2.x and analyzer 8.1–10; latest Drift 2.34.3 and drift_dev 2.34.5 require sqlite3 3.x, a Phase 60-owned native migration. [CITED: https://pub.dev/api/packages/drift] [CITED: https://pub.dev/api/packages/drift_dev] |
| build_runner | 2.15.1 | Unified code-generation runner | Supports analyzer 8–13; 2.16.0 requires analyzer `>=13.3.0`. [CITED: https://pub.dev/api/packages/build_runner] |
| dart_code_linter | 3.2.1 | Existing audit tooling | Supports analyzer `^8.2.0`; current 4.1.9 needs analyzer 10–14. [CITED: https://pub.dev/api/packages/dart_code_linter] |

### Supporting locked transitive members

| Library | Exact selected version | Why it is a graph member |
|---------|------------------------|---------------------------|
| analyzer_plugin | 0.13.10 | Its exact `analyzer: 8.4.0` dependency selects the analyzer patch. [CITED: https://pub.dev/api/packages/analyzer_plugin] |
| custom_lint_visitor | 1.0.0+8.4.0 | Analyzer-versioned visitor companion for the custom-lint lane. [VERIFIED: pubspec.lock:308-315] |
| build | 4.0.7 | Shared build API used by the selected runners/generators. [VERIFIED: pubspec.lock:84-91] |
| source_gen | 4.2.4 | Shared generator API; its analyzer range includes 8.4.0. [CITED: https://pub.dev/api/packages/source_gen] |

DATA_G7R5PL1D_START
> `version: "8.4.0"`
>
> `version: "3.1.0"`
>
> `version: "3.2.3"`
>
> `version: "6.11.2"`
>
> `version: "4.0.0+1"`
>
> `version: "2.31.0"`
>
> `version: "2.15.1"`
DATA_G7R5PL1D_END

These are the existing lockfile selections, in the order analyzer, Riverpod runtime, Freezed, JSON serializer, Riverpod generator, Drift/Drift dev, and build_runner. [VERIFIED: pubspec.lock:28-35,108-115,340-355,563-570,637-652,855-862,1222-1261]

### Installation

No package name should be added in Phase 58. After updating the SDK declaration and exact contract metadata, resolve only the committed graph:

```bash
flutter pub get --enforce-lockfile
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
```

Pub resolves declared immediate dependencies and their transitive dependencies; the committed lockfile is the reproducibility mechanism. [CITED: https://dart.dev/tools/pub/dependencies] [CITED: https://dart.dev/tools/pub/cmd/pub-get]

### Alternatives considered

| Instead of selected graph | Could use | Why it is rejected in Phase 58 |
|---------------------------|-----------|--------------------------------|
| analyzer 8.4.0 | analyzer 9–14 and latest generator/lint packages | `import_guard_custom_lint` 1.0.0 has `<9.0.0`; selecting it would remove the architecture guard or require a forbidden override. |
| Riverpod 3.1/4.0.0+1/3.1.0 | Riverpod 3.4.2/4.0.8/3.1.8 | New generators/lint require analyzer `^13.0.0`, incompatible with the guard. |
| Drift 2.31.0 | Drift 2.34.x | New Drift requires sqlite3 3.x, which cannot be separated from SQLCipher/native validation in Phase 60. |

## Package Legitimacy Audit

Phase 58 introduces **no new package names**. The GSD package-legitimacy seam currently accepts only `npm`, `pypi`, and `crates`, not Dart Pub; therefore it cannot produce an `OK` verdict for this ecosystem. Each selected package above was instead checked through its official publisher’s Pub API and is tagged `[CITED]`, not `[VERIFIED: npm registry]`. The implementation must not install a package outside the existing direct dependency inventory.

| Package set | Registry | Verdict | Disposition |
|-------------|----------|---------|-------------|
| Existing Flutter/Dart analyzer and generator cohort | Pub | Official package metadata inspected; automated legitimacy seam unavailable for Pub | Keep only the selected existing names and lockfile graph |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none; no new package recommendation is made.

## Architecture Patterns

### System architecture diagram

```text
Official Flutter release manifest ─┐
Official Pub package metadata ────┼─> reviewed baseline + compatibility contract
                                  │                 │
Developer/CI Flutter 3.44.8 ──────┘                 v
                                           flutter pub get --enforce-lockfile
                                                       │
                      ┌─────────────── generation inputs ────────────────┐
                      v                                                     v
                flutter gen-l10n                              build_runner --delete-conflicting-outputs
                      │                                                     │
                      └──────────────────────> tracked generated output ──┘
                                                            │
                                                            v
                     flutter analyze (Riverpod lint) + custom_lint (import guard)
                                                            │
                                                            v
               independent source-scanning architecture tests + clean-diff gate
```

### Recommended project structure

```text
docs/testing/
├── STABLE_BASELINE.json                 # authoritative reviewed selections and holds
└── DEPENDENCY_COMPATIBILITY.md          # readable explanation, not a duplicate source of truth
scripts/
└── dependency_compatibility.dart        # fail-closed policy/lockfile/identity validator
test/architecture/
├── dependency_compatibility_contract_test.dart
├── layer_import_rules_test.dart
├── domain_import_rules_test.dart
└── presentation_layer_rules_test.dart
```

### Pattern 1: one graph contract, not independent package bumps

**What:** Change the SDK declaration, relevant manifest rows, expected constraints/locked versions, and negative contract tests as one reviewable transaction. Preserve the lockfile-selected graph or reject the transaction.

**When to use:** Every analyzer, generator, lint, or SDK upgrade.

**Implementation pattern:**

```dart
// Keep this enforcement precise, not a broad `8.x` assertion.
expectLocked('custom_lint', '0.8.1');
expectLocked('import_guard_custom_lint', '1.0.0');
expectLocked('analyzer', '8.4.0');
expectLocked('analyzer_plugin', '0.13.10');
```

The first two values are already contract values; Phase 58 should add the exact analyzer and analyzer-plugin checks, then add matching negative mutation tests. [VERIFIED: scripts/dependency_compatibility.dart:357-378]

### Pattern 2: independent enforcement for the two import styles

**What:** Retain both `import_guard` for package imports and source-scanning architecture tests for relative imports. The latter is intentionally the enforcement point for relative imports.

**When to use:** Always; do not consider a passing custom-lint command alone as evidence of Clean Architecture protection.

DATA_Z6VJ4M8S_START
> `- custom_lint`
>
> `prefer_relative_imports: true`
>
> `Layer violations (import_guard deny rules do not catch relative imports — this test is the enforcement point)`
DATA_Z6VJ4M8S_END

The analyzer enables custom_lint, and the architecture test documents why the independent scanner remains mandatory. [VERIFIED: analysis_options.yaml:3-17] [VERIFIED: test/architecture/layer_import_rules_test.dart:5-13,73-80]

### Pattern 3: reversible negative-tool verification

**What:** Add a test-owned verification harness that creates one uniquely named temporary invalid source file under a protected `lib/` directory, runs the relevant tool, asserts the expected diagnostic, and removes the file in `finally`. The harness must also fail early if a prior interrupted run left the fixture behind.

**When to use:** This phase’s explicit proof that the tools still reject invalid code after the analyzer decision.

Before executing a Riverpod negative fixture, add the selected plugin alongside custom_lint and retain its package-specific configuration key:

```yaml
analyzer:
  plugins:
    - custom_lint
    - riverpod_lint

plugins:
  riverpod_lint: 3.1.0
```

Riverpod’s official 3.1.0 package README requires both entries for its analysis-server plugin. The current repository enables only `custom_lint`, so this is a required Phase 58 configuration correction rather than a source-model migration. [CITED: https://pub.dev/api/archives/riverpod_lint-3.1.0.tar.gz] [VERIFIED: analysis_options.yaml:3-17]

**Fixture matrix:**

| Fixture | Command | Required evidence |
|---------|---------|-------------------|
| Domain file importing `package:home_pocket/data/...` | `dart run custom_lint --reporter=json --no-fatal-infos` | nonzero status and an `import_guard` diagnostic |
| Same domain package-import fixture | `flutter test test/architecture/layer_import_rules_test.dart` | nonzero status and the domain-independence failure |
| Domain file using a relative forbidden data import | `flutter test test/architecture/layer_import_rules_test.dart` | nonzero status; proves the scanner is not redundant with import_guard |
| Minimal `runApp(const Placeholder())` fixture without `ProviderScope` | `flutter analyze --format machine` | nonzero status and the Riverpod `missing_provider_scope` warning at the fixture `runApp` invocation |

Riverpod lint 3.1.0 is an analysis-server plugin, so its negative proof belongs to `flutter analyze`, not merely `dart run custom_lint`. Its published source defines `missing_provider_scope` as a WARNING and reports it on a `runApp` whose first widget is neither `ProviderScope` nor `UncontrolledProviderScope`. [CITED: https://pub.dev/api/archives/riverpod_lint-3.1.0.tar.gz] The existing CI already runs analyzer and custom_lint as separate hard gates. [VERIFIED: .github/workflows/audit.yml:38-53]

### Anti-patterns to avoid

- **`dependency_overrides` or `pubspec_overrides.yaml`:** never force analyzer 9+ through a conflicting import-guard graph. The current policy explicitly rejects both. [VERIFIED: .planning/phases/58-flutter-analyzer-code-generation-lane/58-CONTEXT.md:14-16]
- **Broad “analyzer 8.x” acceptance:** analyzer 8.4.1 is not satisfiable with the chosen analyzer-plugin line; enforce 8.4.0 and its paired transitive selection.
- **Treating successful `flutter pub outdated` output as a success criterion:** newest individual packages are intentionally incompatible with the load-bearing lint and SQLCipher lanes.
- **Hand-editing `*.g.dart`, `*.freezed.dart`, or `lib/generated/`:** all output must be regenerated and reviewed from source inputs. [VERIFIED: analysis_options.yaml:3-7] [VERIFIED: l10n.yaml:1-6]
- **Solving native/plugin failures in this phase:** leave SQLCipher/sqlite3, iOS/CocoaPods, platform plugins, and Android host tooling to their owner phases.

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Dependency solving | A custom version resolver or hand-edited lockfile | Pub with `flutter pub get --enforce-lockfile` | Pub resolves the complete transitive graph and enforces the reviewed lockfile. [CITED: https://dart.dev/tools/pub/cmd/pub-get] |
| Generated localization | Hand-maintained localization Dart | `flutter gen-l10n` using `l10n.yaml` | Guarantees generated `S` API matches all ARB inputs. [VERIFIED: l10n.yaml:1-6] |
| Riverpod/Freezed/JSON/Drift output | Manual `.g.dart` / `.freezed.dart` edits | build_runner with selected builders | Generated code is coupled to annotations and runtime contracts. |
| Architecture checks | One lint plugin as the only guard | custom_lint plus source-scanning architecture tests | Package and relative imports have distinct coverage. [VERIFIED: test/architecture/layer_import_rules_test.dart:5-13] |

**Key insight:** a lockfile is a resolved graph, not a guarantee that future individual major upgrades remain compatible. The compatibility script and negative tests are the durable policy layer around it.

## Common Pitfalls

### Pitfall 1: upgrading to analyzer 8.4.1 because it is the newest 8.x patch

**What goes wrong:** Pub cannot retain `analyzer_plugin` 0.13.10, while the next plugin version requires analyzer 9.
**Why it happens:** Version labels suggest a harmless patch, but analyzer plugin APIs are lockstep.
**How to avoid:** Pin/assert analyzer 8.4.0, analyzer_plugin 0.13.10, and custom_lint_visitor 1.0.0+8.4.0 in the contract.
**Warning signs:** `flutter pub get` proposes analyzer 9, or the custom-lint plugin disappears/fails to load. [CITED: https://pub.dev/api/packages/analyzer_plugin]

### Pitfall 2: changing Riverpod runtime without its annotation/generator/lint quartet

**What goes wrong:** `flutter_riverpod` 3.4.2 conflicts with `riverpod_annotation` 4.0.0 and its matching generator/lint generation contract.
**Why it happens:** Riverpod packages pin their matching runtime versions.
**How to avoid:** Preserve 3.1.0 / 4.0.0 / 4.0.0+1 / 3.1.0 as one row in the contract; only advance all four after import_guard supports their analyzer line. [CITED: https://pub.dev/api/packages/flutter_riverpod] [CITED: https://pub.dev/api/packages/riverpod_annotation]

### Pitfall 3: treating `custom_lint` as the Riverpod lint gate

**What goes wrong:** the import boundary check passes while Riverpod lint is not actually exercised.
**Why it happens:** Riverpod lint 3.1.0 is an analysis-server plugin.
**How to avoid:** Require `flutter analyze` evidence for Riverpod diagnostics and keep custom_lint evidence for import_guard. [CITED: https://pub.dev/packages/riverpod_lint]

### Pitfall 4: upgrading Drift to satisfy generator freshness

**What goes wrong:** Drift 2.34.x pulls sqlite3 3.x, violating the encrypted native hold before Phase 60 proves a replacement.
**How to avoid:** hold both Drift packages at 2.31.0; use Phase 60’s encryption/migration/recovery gates as the exit condition. [CITED: https://pub.dev/api/packages/drift] [CITED: https://pub.dev/api/packages/drift_dev]

### Pitfall 5: one clean generation run hides an unstable diff

**What goes wrong:** generator output changes on the first run or from stale assets, but is accepted without proving idempotence.
**How to avoid:** run the generation sequence twice from clean state; the second pass and `git diff --exit-code` must be empty. The existing CI proves the build-runner half but Phase 58 must add/retain the complete sequence. [VERIFIED: .github/workflows/audit.yml:95-102]

## Code Examples

### Required execution order

```bash
flutter --version --machine
flutter pub get --enforce-lockfile
dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk
flutter gen-l10n
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze --no-fatal-infos
dart run custom_lint --no-fatal-infos
flutter test test/architecture/dependency_compatibility_contract_test.dart
flutter test test/architecture/layer_import_rules_test.dart test/architecture/domain_import_rules_test.dart test/architecture/presentation_layer_rules_test.dart
flutter test
git diff --check
```

These commands preserve the project’s existing CI ordering: locked resolution, baseline contract, analyzer/custom lint, architecture guards, then generation cleanliness. [VERIFIED: .github/workflows/audit.yml:38-59,95-102] [VERIFIED: docs/testing/DEPENDENCY_COMPATIBILITY.md:52-63]

### Future migration syntax — only if the exit condition becomes true

No source migration is currently required: every selected generator/runtime version is already locked and current within the analyzer-8 graph. If a later graph changes APIs, preserve the project’s Riverpod 3 syntax rather than applying legacy migration recipes:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

final value = asyncValue.value;
final error = asyncValue.exception;
```

DATA_C3P8X1LM_START
> `AsyncValue.valueOrNull` is gone; use nullable `.value`.
>
> `Provider errors are wrapped in ProviderException; inspect `.exception` in tests.`
>
> `Misc symbols such as Override, ProviderListenable, ProviderException, Family, Refreshable, and ProviderBase live in package:flutter_riverpod/misc.dart.`
DATA_C3P8X1LM_END

This is a project constraint, not an instruction to change sources now. [VERIFIED: AGENTS.md]

## State of the Art

| Old approach | Current approach | Impact |
|--------------|------------------|--------|
| Update each generator to its latest version independently | Select a solver-compatible analyzer/lint/runtime/generator cohort | Prevents a successful resolution from silently losing architecture enforcement. |
| Treat analyzer major updates as isolated tooling | Treat analyzer as a shared API boundary for plugins and generators | Makes import guard the limiting safety dependency until it publishes analyzer-9 support. |
| Validate only positive lint output | Prove valid tree passes and deliberately invalid fixtures fail | Detects a plugin that loads but stops enforcing expected diagnostics. |

**Deprecated/outdated in this project:** analyzer 9+ and latest Riverpod/Freezed/JSON/Drift/build_runner packages are not Phase 58 production candidates until the explicit exit conditions below are met; they are not “failed upgrades.”

## Holds and Exact Exit Conditions

| Hold | Current latest stable observed | Why held | Exit condition |
|------|-------------------------------|----------|----------------|
| analyzer/custom_lint/import_guard | analyzer 14.1.0; import_guard 1.0.0 still `<9` | Architecture guard blocks analyzer 9+. Exact compatible selection is analyzer 8.4.0. | `import_guard_custom_lint` publishes an official production release supporting the analyzer line required by all selected generators; Pub resolves it with no override; positive/negative lint and architecture gates pass. |
| Riverpod cohort | 3.4.2 / 4.0.6 / 4.0.8 / 3.1.8 | New generator/lint require analyzer ^13.0.0. | Advance all runtime/annotation/generator/lint members together after analyzer/import-guard exit condition; regenerate and pass provider/architecture/full-suite gates. |
| Freezed + JSON | Freezed 3.2.5; json_serializable 6.14.1 | New versions require analyzer 9+ / 10+. | Advance only with the new analyzer-compatible lint graph and clean generated-output/serialization tests. |
| build_runner + dart_code_linter | 2.16.0 / 4.1.9 | New versions require analyzer 13.3+ / 10+. | Advance only with the same analyzer migration; keep audit scanner output and CI gates working. |
| Drift + drift_dev | 2.34.3 / 2.34.5 | Require sqlite3 3.x, outside the proven SQLCipher path. | Phase 60 proves a coordinated native replacement: non-empty cipher version, reopen, released-schema migration, backup restore, simulator/device builds, and no system/plain SQLite fallback. |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| — | None. Current-version and constraint claims were checked against official Flutter/Pub sources; implementation-time re-query remains a locked requirement. | — | — |

## Open Questions (RESOLVED)

### 1. Analyzer-9-compatible import guard successor

**Result:** No officially released successor exists as of the 2026-08-06 re-check. Pub’s full release history reports `import_guard_custom_lint` **1.0.0** as latest, published 2026-02-27, with `analyzer: >=7.0.0 <9.0.0`; every prior release also caps analyzer below 9. [CITED: https://pub.dev/api/packages/import_guard_custom_lint]

**Exact decision rule:** Enforce analyzer **8.4.0** unless all four conditions are met in one candidate transaction: (1) Pub officially publishes an import-guard successor whose published constraint accepts the intended analyzer major; (2) `flutter pub get` resolves the entire SDK/Riverpod/Freezed/JSON/Drift/build_runner/custom-lint graph without `dependency_overrides` or `pubspec_overrides.yaml`; (3) D-04 negative fixtures prove import_guard, the relative-import scanner, and Riverpod lint still reject invalid source; and (4) D-08/D-09 complete two clean generation passes with no unexplained tracked diff. **Confidence: MEDIUM** — current publisher metadata is authoritative at query time; a future release requires the locked execution-time re-query.

### 2. Riverpod negative-fixture diagnostic and stable fallback

**Result:** With selected `riverpod_lint` **3.1.0**, assert machine diagnostic code **`missing_provider_scope`** at the fixture `runApp` invocation. The official Pub archive defines that code as a WARNING and emits it when `runApp` is not rooted by `ProviderScope` or `UncontrolledProviderScope`. [CITED: https://pub.dev/api/archives/riverpod_lint-3.1.0.tar.gz]

**Required enablement:** Add `riverpod_lint` to `analyzer.plugins` and add the top-level `plugins: riverpod_lint: 3.1.0` configuration. The existing configuration contains only `custom_lint`, so the plugin is not presently configured for analyzer execution. [CITED: https://pub.dev/api/archives/riverpod_lint-3.1.0.tar.gz] [VERIFIED: analysis_options.yaml:3-17]

**Robust fallback if output text or the selected future lint code changes:** keep the fixture compilable apart from its deliberately missing root scope; compare it to a paired `ProviderScope(child: const Placeholder())` control; require a non-info analyzer diagnostic on the bad fixture’s `runApp` line and no corresponding diagnostic on the control; archive `--format machine` output; then update the asserted code only after inspecting the official Pub archive/source for the exact locked `riverpod_lint` version. This differential evidence protects D-04 without relying on mutable prose. **Confidence: HIGH** for the selected 3.1.0 code path; MEDIUM for any future version.

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter SDK | resolve, generation, analyzer, tests | ✓ | 3.44.8 Stable | none — production identity is locked |
| Dart SDK | Pub, code generation, validators | ✓ | 3.12.2 stable | bundled with selected Flutter |
| Official Flutter release manifest | current stable verification | ✓ | queried 2026-08-06 | use documented prior baseline only if the manifest is temporarily unreachable, then do not change versions |
| Pub.dev package APIs | current constraint verification | ✓ | queried 2026-08-06 | do not approve a changed graph until official source is available |

The Flutter machine output and repository metadata agree on the production identity. [VERIFIED: `.metadata`:6-23] [CITED: https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Flutter test (SDK-pinned) |
| Config file | `analysis_options.yaml`, `build.yaml`, `l10n.yaml` |
| Quick run command | `flutter test test/architecture/dependency_compatibility_contract_test.dart` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test type | Automated command | File exists? |
|--------|----------|-----------|-------------------|-------------|
| GEN-01 | SDK, metadata, CI pin and declared SDK range agree | contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart` and `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extend existing |
| GEN-02 | Exact analyzer hold and all three enforcement mechanisms reject invalid code | integration/negative | new reversible lint-fixture harness plus `flutter analyze`, `dart run custom_lint`, and layer-import test | ❌ Wave 0 |
| GEN-03 | Entire selected graph resolves with no override/split lane | contract + resolution | `flutter pub get --enforce-lockfile`; compatibility contract test | ✅ extend existing |
| GEN-04 | Two clean generation passes leave no tracked generated diff | integration | `flutter gen-l10n && flutter pub run build_runner build --delete-conflicting-outputs` twice, then `git diff --exit-code -- lib/` | ❌ Wave 0 complete-sequence gate |

### Sampling Rate

- **Per task commit:** targeted contract/negative test plus `flutter analyze --no-fatal-infos`.
- **Per wave merge:** `flutter pub get --enforce-lockfile`, both generators, custom lint, architecture tests.
- **Phase gate:** full `flutter test`, coverage when code/test sources change, and a clean second generation before verification.

### Wave 0 Gaps

- [ ] Add a reversible negative-fixture harness that proves package-import `import_guard`, relative-import source scanner, and Riverpod analyzer diagnostics independently fail.
- [ ] Register `riverpod_lint` in `analysis_options.yaml` using its selected `3.1.0` analysis-server-plugin configuration before asserting its fixture diagnostic.
- [ ] Extend `scripts/dependency_compatibility.dart` and its contract test to require exact analyzer 8.4.0 and its analyzer-plugin pair, and to reject analyzer 8.4.1/9+ drift.
- [ ] Add the complete two-pass localization-plus-build-runner clean-diff command to CI or a tested phase-owned verification script; the existing CI covers only build_runner clean output. [VERIFIED: .github/workflows/audit.yml:95-102]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard control |
|---------------|---------|------------------|
| V2 Authentication | no | No authentication behavior is in scope. |
| V3 Session Management | no | No session behavior is in scope. |
| V4 Access Control | yes | Preserve Clean Architecture boundary checks; no policy weakening for a tool upgrade. |
| V5 Input Validation | yes | Parse Pub/lock/manifest configuration fail-closed through the existing dependency compatibility contract. |
| V6 Cryptography | yes, preservation only | Keep SQLCipher package/prohibitions untouched; Phase 60 owns native crypto validation. |

### Known threat patterns for the tooling stack

| Pattern | STRIDE | Standard mitigation |
|---------|--------|---------------------|
| A version override hides an incompatible analyzer graph | Tampering / Elevation | Reject `dependency_overrides` and `pubspec_overrides.yaml`; use one solver-produced lockfile. |
| A lint plugin loads but no longer detects forbidden code | Tampering | Positive production-tree gates plus reversible negative fixtures for import_guard, relative-import scanner, and Riverpod lint. |
| Latest Drift pulls an unproven SQLite/native path | Tampering / Information disclosure | Hold Drift at 2.31.0 until Phase 60 encryption and migration evidence passes. |
| Hand-edited generated output obscures source intent | Repudiation | Regenerate from clean state twice and reject unexpected tracked diff. |

## Sources

### Primary (official publisher sources)

- [Flutter release manifest](https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json) — current Stable 3.44.8/Dart 3.12.2/revision pairing.
- [Flutter SDK archive](https://docs.flutter.dev/install/archive) — Stable is the production-recommended channel and archive semantics.
- [Dart Pub dependency documentation](https://dart.dev/tools/pub/dependencies) and [`pub get`](https://dart.dev/tools/pub/cmd/pub-get) — constraints, transitive resolution, and lockfile behavior.
- [Analyzer](https://pub.dev/api/packages/analyzer), [analyzer_plugin](https://pub.dev/api/packages/analyzer_plugin), [custom_lint](https://pub.dev/api/packages/custom_lint), and [import_guard_custom_lint](https://pub.dev/api/packages/import_guard_custom_lint) — exact analyzer constraint conflict.
- [Riverpod runtime](https://pub.dev/api/packages/flutter_riverpod), [annotations](https://pub.dev/api/packages/riverpod_annotation), [generator](https://pub.dev/api/packages/riverpod_generator), and [lint](https://pub.dev/api/packages/riverpod_lint) — matching runtime and analyzer constraints.
- [Freezed](https://pub.dev/api/packages/freezed), [json_serializable](https://pub.dev/api/packages/json_serializable), [Drift](https://pub.dev/api/packages/drift), [drift_dev](https://pub.dev/api/packages/drift_dev), [build_runner](https://pub.dev/api/packages/build_runner), and [dart_code_linter](https://pub.dev/api/packages/dart_code_linter) — current candidates and incompatibility bounds.

### Repository sources

- `docs/testing/STABLE_BASELINE.json` — baseline identity/platform floors/direct dependency evidence. [VERIFIED: docs/testing/STABLE_BASELINE.json:1-35,93-101]
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — coordinated lane policy and refresh transaction. [VERIFIED: docs/testing/DEPENDENCY_COMPATIBILITY.md:15-28,52-68]
- `analysis_options.yaml`, `build.yaml`, `l10n.yaml`, CI workflow, contract validator, and architecture tests — enforced project patterns. [VERIFIED: analysis_options.yaml:1-17] [VERIFIED: build.yaml:1-9] [VERIFIED: l10n.yaml:1-6] [VERIFIED: .github/workflows/audit.yml:23-102]

## Metadata

**Confidence breakdown:**

- Standard stack: MEDIUM — each current value and constraint is from official publisher data; re-query at execution because package releases are time-sensitive.
- Architecture: HIGH — based on source files opened in this session, including the CI workflow, validator, lint configuration, and architecture tests.
- Pitfalls: MEDIUM — derived from official package constraints and the repository’s documented behavior.

**Research date:** 2026-08-06
**Valid until:** 2026-08-13 — package metadata is fast-moving; re-query immediately before implementation.
