# Phase 58: Flutter, Analyzer & Code Generation Lane - Context

**Gathered:** 2026-08-06
**Status:** Ready for planning
**Mode:** Auto-generated from the user's authorized production-stable upgrade

<domain>
## Phase Boundary

Move Happy Pocket onto one production-stable Flutter/Dart and analyzer/code-generation compatibility graph while preserving all Clean Architecture and lint enforcement. This phase owns the Dart SDK declaration plus Riverpod, Freezed, JSON, Drift, build_runner, analyzer, custom-lint and import-guard compatibility lane. It does not own platform-plugin cohorts, SQLCipher/native iOS changes, Android host-tool migration, or physical-device acceptance.

</domain>

<decisions>
## Implementation Decisions

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Upgrade Policy and Baseline
- `AGENTS.md` — repository architecture, Riverpod 3, generation, SQLCipher and quality-gate rules.
- `docs/testing/STABLE_BASELINE.json` — machine-readable selected/candidate versions, hold evidence and owner phases.
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` — human-readable coordinated-lane policy and exit conditions.
- `.planning/REQUIREMENTS.md` — GEN-01 through GEN-04 acceptance requirements.
- `.planning/phases/57-stable-baseline-compatibility-contract/57-VERIFICATION.md` — independently verified Phase 57 baseline and fail-closed contract evidence.

### Dependency and Generation Inputs
- `pubspec.yaml` — declared Dart SDK, runtime packages, annotations, generators and lint dependencies.
- `pubspec.lock` — exact resolved graph that must remain reproducible.
- `analysis_options.yaml` — analyzer, lint and custom-lint configuration.
- `build.yaml` — generator configuration.
- `l10n.yaml` — localization generation configuration.
- `.metadata` — Flutter project identity aligned by the verified Stable baseline.

### Executable Quality Gates
- `scripts/dependency_compatibility.dart` — fail-closed baseline, hold and coordinated-lane validator.
- `test/architecture/dependency_compatibility_contract_test.dart` — positive and negative compatibility-contract fixtures.
- `test/architecture/layer_import_rules_test.dart` — real-import Clean Architecture enforcement.
- `test/architecture/domain_import_rules_test.dart` — domain purity/import-guard contract.
- `test/architecture/presentation_layer_rules_test.dart` — presentation-layer import contract.
- `.github/workflows/audit.yml` — pinned Stable CI, locked resolution, generation and analysis gates.
- `.github/workflows/flutter-future-compat.yml` — non-release beta future probe; never a production baseline.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `scripts/dependency_compatibility.dart` already validates the selected Flutter/Dart identity, dependency inventory, coordinated lanes, holds, platform floors and tracked input digests.
- `test/architecture/dependency_compatibility_contract_test.dart` provides real-input mutation fixtures for fail-closed dependency policy.
- The three architecture import tests and `custom_lint` invocation form independent protections against a lint plugin silently ceasing to enforce boundaries.
- Existing tracked `*.g.dart`, `*.freezed.dart` and `lib/generated/` outputs provide a clean-before/clean-after reproducibility oracle.

### Established Patterns
- Runtime packages and their annotations/generators advance in lockstep; no generated file is hand-edited.
- Generator or ARB inputs require regeneration immediately, followed by targeted tests and `flutter analyze`.
- Dependency holds are successful outcomes only when their official evidence, reason and exit condition remain machine-enforced.
- Broad formatting churn is excluded from scoped upgrade commits unless required by the selected Dart formatter.

### Integration Points
- `pubspec.yaml` and `pubspec.lock` define the resolved graph consumed by local builds and CI.
- `.github/workflows/audit.yml` runs locked resolution, dependency compatibility, generation cleanliness, analysis, custom lint and coverage gates.
- `.github/workflows/flutter-future-compat.yml` remains advisory for the future Flutter beta lane.
- Phase 59 consumes the final Dart/plugin-compatible graph; Phase 60 consumes the final Drift/sqlite/analyzer boundary without changing the proven SQLCipher hold early.

</code_context>

<specifics>
## Specific Ideas

- “Latest” continues to mean the newest mutually compatible production-stable graph, not an empty `flutter pub outdated` report.
- The upgrade should leave a reviewer able to explain every non-latest selected version and the exact test that permits its future release.

</specifics>

<deferred>
## Deferred Ideas

- File/share/speech/notification/biometric/secure-storage plugin cohorts belong to Phase 59.
- SQLCipher/sqlite3, CocoaPods/SwiftPM cleanup, encrypted reopen and backup proof belong to Phase 60.
- AGP/Kotlin/Gradle/Android release-host migration belongs to Phase 61.
- Wired-iPhone isolated Bundle ID and physical acceptance belong to Phase 63.

</deferred>

---

*Phase: 58-flutter-analyzer-code-generation-lane*
*Context gathered: 2026-08-06*
