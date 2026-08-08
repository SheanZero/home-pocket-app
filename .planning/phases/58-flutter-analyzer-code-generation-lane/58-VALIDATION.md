---
phase: 58
slug: flutter-analyzer-code-generation-lane
status: in_progress
nyquist_compliant: false
wave_0_complete: true
created: 2026-08-06
---

# Phase 58 — Validation Strategy

> Per-phase validation contract for the exact Flutter/Dart analyzer/code-generation graph, negative lint enforcement, and deterministic generated output.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test`, repository Dart/Bash verification tools, Flutter analyzer/import_lint/riverpod_lint |
| **Config file** | `pubspec.yaml`, `analysis_options.yaml`, `build.yaml`, `l10n.yaml` |
| **Quick run command** | `flutter test test/architecture/codegen_reproducibility_contract_test.dart` |
| **Full suite command** | `flutter test --coverage --concurrency=1` |
| **Estimated runtime** | targeted contracts ~30 seconds; tooling/codegen/full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run the task’s targeted contract plus `flutter analyze --no-fatal-infos` when Dart/config changed.
- **After Wave 0:** Run source-contract tests only; the independent Wave 0 creators must not race by live-calling each other's output. After each dependent wave, run the authoritative wrapper from a clean committed state plus targeted Phase 58 contracts and `git diff --check`.
- **Before phase verification:** Run the authoritative locked-resolution → two clean generation passes → analyzer/import_lint/riverpod_lint/three architecture tests → negative tooling wrapper, then the full single-concurrency coverage suite, 70% coverage gate, and whitespace check.
- **Max feedback latency:** 30 seconds for pure/source contract tests; subprocess and full-suite gates are phase boundaries, never watch mode.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 58-01-01 | 01 | 0 | GEN-02 | T-58-01, T-58-02 | Package import is rejected by import_lint and the exact fixture is cleaned | negative integration | `flutter test test/architecture/tooling_guard_negative_fixture_test.dart --plain-name 'package import fixture is rejected by import_lint and cleaned'` | ✅ created | ✅ green |
| 58-01-02 / HP-06 | 01 | 0 | GEN-02 | T-58-03, T-58-04 | Package/relative scanner and Riverpod app-root bad/control contracts fail independently; valid analyzer, import_lint, layer scanner, and provider contract pass | negative integration | `dart run scripts/verify_tooling_guards.dart` | ✅ owned contract | ✅ green |
| 58-02-01 | 02 | 1 | GEN-02, GEN-03 | T-58-06, T-58-07 | Exact analyzer 12.1.0, analyzer_plugin 0.14.8, import_lint 2.0.0, active riverpod_lint 3.1.4, and the complete cohort reject every partial mutation | contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'GEN-02/GEN-03 exact analyzer and code-generation graph fails closed'` | ✅ extended | ✅ green (43-test contract suite) |
| 58-02-02 | 02 | 1 | GEN-01, GEN-02, GEN-03 | T-58-05, T-58-08 | Dart ^3.12.2, lock, manifest, policy, and the selected Flutter 3.44.8/Dart 3.12.2 identity agree without native drift; Flutter 3.44.9 remains a documented hold | contract/smoke | `flutter pub get --enforce-lockfile && flutter test test/architecture/dependency_compatibility_contract_test.dart && dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extended | ✅ green (43-test suite + baseline validator) |
| 58-03-01 | 03 | 0 | GEN-04 | T-58-09, T-58-11 | Source contract fixes locked resolution → first clean generation pass → analyzer/lint/three architecture tests | source contract | `flutter test test/architecture/codegen_reproducibility_contract_test.dart --plain-name 'first pass is locked and diff-scoped'` | ✅ created | ✅ green |
| 58-03-02 | 03 | 0 | GEN-04 | T-58-09, T-58-10, T-58-12A | Source contract fixes two clean passes before every lint/architecture/tooling guard | source contract | `flutter test test/architecture/codegen_reproducibility_contract_test.dart --plain-name 'two clean generation passes precede every lint and architecture gate'` | ✅ created | ✅ green |
| 58-04-01 | 04 | 2 | GEN-01, GEN-02 | T-58-13, T-58-14 | Stable CI invokes one wrapper after SDK setup and has no pre-generation analysis duplicate | workflow contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart --plain-name 'Stable CI routes post-generation lint and architecture gates through one wrapper'` | ✅ extended | ✅ green |
| 58-04-02 | 04 | 2 | GEN-03, GEN-04 | T-58-14, T-58-15 | Stable CI has exactly one wrapper call and no inline generator/lint alternate | workflow + wrapper contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/codegen_reproducibility_contract_test.dart && dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ extended | ✅ green |
| 58-05-01 | 05 | 3 | GEN-01, GEN-02, GEN-03, GEN-04 | T-58-17, T-58-18 | The authoritative wrapper executes the complete targeted matrix in D-08 order | integration | `bash scripts/verify_codegen_reproducibility.sh && flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/tooling_guard_negative_fixture_test.dart test/architecture/codegen_reproducibility_contract_test.dart` | pending Waves 0-2 | ⬜ pending |
| 58-05-02 | 05 | 3 | GEN-01, GEN-02, GEN-03, GEN-04 | T-58-19, T-58-20 | Authoritative wrapper, full suite, coverage, and whitespace remain green without later-lane claims | phase gate | `bash scripts/verify_codegen_reproducibility.sh && flutter test --coverage --concurrency=1 && git diff --check` | ✅ infrastructure | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `analysis_options.yaml`, `scripts/verify_tooling_guards.dart`, `scripts/audit/provider_contract.dart`, and their architecture tests — prove package/relative import guards and missing ProviderScope rejection with ProviderScope/alias controls on the selected analyzer 12 + import_lint 2.0.0 + active riverpod_lint 3.1.4 graph.
- [x] `scripts/verify_codegen_reproducibility.sh` and `test/architecture/codegen_reproducibility_contract_test.dart` — source-tested authoritative GEN-04 wrapper for locked resolution, two l10n/build_runner clean passes, then analyzer, lint, layer/domain/presentation architecture tests, and tooling-guard proof.

Plans `58-01` and `58-03` create these gaps in Wave 0. Wave 1 plan `58-02` explicitly depends on both creators before it mutates the selected graph, and Wave 2 plan `58-04` consumes their executable contracts in Stable CI.

---

## Manual-Only Verifications

All Phase 58 behaviors have automated verification. This strategy intentionally makes no platform-plugin, SQLCipher/native, Android-host, simulator, or physical-device acceptance claim.

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Targeted feedback latency is bounded; long subprocess/full-suite gates occur only at plan/phase boundaries
- [ ] `nyquist_compliant: true` set in frontmatter after executed evidence is complete

**Approval:** pending
