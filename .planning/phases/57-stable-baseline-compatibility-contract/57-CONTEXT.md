# Phase 57: Stable Baseline & Compatibility Contract - Context

**Gathered:** 2026-08-05
**Status:** Ready for planning
**Mode:** Auto-generated (pure infrastructure phase)

<domain>
## Phase Boundary

Establish one auditable, official-source production-stable SDK, native-tool, and dependency baseline; make the repository compatibility contract reject unsafe, pre-release, EOL, override-forced, and partially upgraded lanes before any version-changing phase begins. This phase records decisions and strengthens executable policy; it does not yet perform the Phase 58–61 SDK/plugin/native migrations.

</domain>

<decisions>
## Implementation Decisions

### the agent's Discretion
- All implementation choices are at the agent's discretion — this is a pure infrastructure phase.
- “Latest” means the latest mutually compatible production-stable window rechecked against official primary sources on the execution date, not the largest version number.
- An evidence-backed hold is successful when its security/compatibility reason, exact version, official evidence, and exit condition are machine-checkable.
- Preserve iOS 15 and Android API 24 support, SQLCipher fail-closed behavior, the analyzer/import-boundary gate, and committed lockfile reproducibility.
- Do not change application behavior, generated source, native build outputs, or dependency versions beyond what is necessary to implement and test the baseline contract; later phases own those upgrades.

</decisions>

<code_context>
## Existing Code Insights

### Reusable Assets
- `docs/testing/DEPENDENCY_COMPATIBILITY.md` already defines coordinated SQLCipher, iOS dependency-manager, file/share, speech, analyzer/codegen, Android, and notification lanes.
- `scripts/dependency_compatibility.dart` and its architecture/contract tests are the existing fail-closed executable policy.
- `.planning/research/STACK.md` and `SUMMARY.md` contain dated official-source candidate and hold decisions for v2.1.
- `pubspec.yaml`, `pubspec.lock`, Gradle wrapper/project files, `ios/Podfile`, `Podfile.lock`, and Xcode SwiftPM state provide the exact resolved baseline inputs.

### Established Patterns
- Compatibility documentation, executable checks, negative tests, and lockfiles co-evolve in the same atomic change.
- Generated files and platform registrants are never hand-edited; native plugin changes begin from `flutter clean` in later phases.
- Security-critical incompatibility fails closed: no `dependency_overrides`, plaintext/system SQLite, `sqlite3_flutter_libs`, or `sqlcipher_flutter_libs 0.7.0+eol` fallback.

### Integration Points
- CI workflows under `.github/workflows/` call the dependency compatibility contract and pin the release/future Flutter lanes.
- Phase 58 consumes the approved Flutter/Dart/analyzer/codegen target; Phases 59–61 consume the plugin, SQLCipher/iOS, and Android lane decisions.
- Phase 62 will reproduce the final selected graph and compare it to the manifest/contract established here.

</code_context>

<specifics>
## Specific Ideas

- Keep a human-readable matrix plus an executable, test-covered manifest/check so reviewers can distinguish “already latest,” “upgraded later,” and “intentional safe hold.”
- Re-query official sources at Phase 57 execution; research candidates are inputs, not immutable claims.

</specifics>

<deferred>
## Deferred Ideas

- Actual Flutter/analyzer/codegen upgrades belong to Phase 58.
- Plugin cohort changes belong to Phase 59; SQLCipher/iOS native proof to Phase 60; Android host migration to Phase 61.

</deferred>
