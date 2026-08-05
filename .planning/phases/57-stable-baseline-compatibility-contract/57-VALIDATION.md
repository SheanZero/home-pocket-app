---
phase: 57
slug: stable-baseline-compatibility-contract
status: complete
nyquist_compliant: true
wave_0_complete: true
created: 2026-08-05
---

# Phase 57 — Validation Strategy

> Per-phase validation contract for the production-stable baseline manifest and executable compatibility policy.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` plus the repository Dart compatibility CLI |
| **Config file** | `pubspec.yaml`, `analysis_options.yaml` |
| **Quick run command** | `flutter test test/architecture/dependency_compatibility_contract_test.dart` |
| **Full suite command** | `flutter test --concurrency=1` |
| **Estimated runtime** | targeted ~15 seconds; full suite several minutes |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/architecture/dependency_compatibility_contract_test.dart`
- **After every plan wave:** Run the targeted test, `flutter pub get --enforce-lockfile`, `dart run scripts/dependency_compatibility.dart`, and `flutter analyze`
- **Before phase verification:** `flutter test --concurrency=1`, the coverage gate required by project policy, and `git diff --check` must be green
- **Max feedback latency:** 30 seconds for the targeted contract test

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 57-01-01 | 01 | 1 | BASE-01, BASE-02 | T-57-01 | Official-source inventory and selected/held values are complete and reproducible | contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ | ✅ green |
| 57-01-02 | 01 | 1 | BASE-02 | T-57-02 | The committed lockfile resolves without mutation or override | smoke | `flutter pub get --enforce-lockfile` | ✅ | ✅ green |
| 57-02-01 | 02 | 2 | BASE-03, BASE-04 | T-57-03 | Pre-release, EOL, plaintext, override, floor-drift, and partial-lane fixtures fail closed | negative contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ | ✅ green |
| 57-02-02 | 02 | 2 | BASE-03, BASE-04 | T-57-04 | Baseline defaults to blocking; future-probe warns only for ordinary candidate drift | source contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ | ✅ green |
| 57-03-01 | 03 | 3 | BASE-02, BASE-03, BASE-04 | T-57-10, T-57-11 | Stable uses the enforced lock/baseline call; both beta jobs use explicit future-probe mode without losing real builds | integration | `flutter test test/architecture/dependency_compatibility_contract_test.dart test/architecture/audit_yml_invariants_test.dart && dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | ✅ | ✅ green |
| 57-03-02 | 03 | 3 | BASE-03, BASE-04 | T-57-12 | Canonical JSON, human matrix, workflow modes, and validation evidence agree without a native/device claim | contract | `flutter test test/architecture/dependency_compatibility_contract_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] Add the machine-readable baseline manifest selected by the plan.
- [x] Extend `test/architecture/dependency_compatibility_contract_test.dart` with in-memory negative fixtures for missing inventory, prerelease, EOL/plaintext SQLite, overrides, partial lanes, platform floors, and CI semantics.
- [x] Add validator support for manifest completeness and actual-input comparison without adding a new test framework.

---

## Manual-Only Verifications

All Phase 57 behaviors have automated or source-evidence verification. Native encryption, build, emulator, and device validation are intentionally deferred to Phases 60–63 and must not be claimed here.

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 30 seconds for targeted checks
- [x] `nyquist_compliant: true` set in frontmatter after executed evidence is complete

## Executed Phase-Final Evidence

- `flutter pub get --enforce-lockfile` — passed without mutating the committed graph.
- `flutter test test/architecture/dependency_compatibility_contract_test.dart` — passed.
- `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` — passed; verified Flutter 3.44.8 / Dart 3.12.2 Stable identity and effective Android API 24.
- `flutter analyze` — passed with 0 issues.
- `flutter test --coverage --concurrency=1` — passed.
- `coverde filter ...` followed by `dart run scripts/coverage_gate.dart ... --threshold 70` — passed.
- `git diff --check` — passed.

No simulator, device, native-encryption, or production-data proof is claimed;
those remain deferred to their owning phases.

**Approval:** automated evidence complete
