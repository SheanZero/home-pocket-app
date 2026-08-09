---
phase: 60
plan: "09"
status: compile_pass_runtime_pending
captured: 2026-08-09
source_commit: 570064236eead5e9bdbd8567f8c866bf9d48aa99
---

# Phase 60 Native Safety Evidence

This record distinguishes successful tests, generic iOS compilation, and booted-Simulator runtime. It intentionally does not promote a pre-launch failure to runtime acceptance.

## Exact Source and Toolchain State

| Item | Value |
| --- | --- |
| Source commit | `570064236eead5e9bdbd8567f8c866bf9d48aa99` |
| Compile run start (UTC) | `2026-08-09T13:38:00.022171Z` |
| `pubspec.lock` SHA-256 | `a2a80891ca4596ab5e9eb1fe6b51a6a86088fa029fe1a65bbfbf55a7f1659ecd` |
| `ios/Podfile.lock` SHA-256 | `5623ecf1f98ff2e8fd975aabf80a65bfbf46fc26a12b603c5563cf7593fa1b95` |
| Flutter / Dart / engine | Flutter 3.44.8 stable / Dart 3.12.2 / `0cd610717bde95fd88343c64f81c11ba4e5c0010` |
| Xcode | 26.2 (17C52) |
| CocoaPods | 1.16.2 |
| App schema | 36; unchanged in this plan |
| Native graph | Retained-lock and disposable from-zero inputs both selected Drift `2.34.0`, sqlite3 `3.5.1`, and SQLCipher Native Assets `4.17.x`; their normalized graph digest matched at `a70b12e5a88958f04a6b2afbd249c37c599d3e067f143d63536d16970f908073`. This is compile evidence, not runtime evidence. |

The native commands started with a clean source state (empty-status SHA-256 `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855`) and the runner reported status preservation. The declared evidence and validation edits were made only after the native commands.

## Executed Gates

| Gate | Exact command or scope | Result | Attribution |
| --- | --- | --- | --- |
| SEC-06 TDD RED | `flutter test test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart -r expanded` before implementation | Expected failure | Tests referenced the absent native-readiness seam, then failed for that reason. |
| SEC-06 targeted regressions | `flutter test test/core/initialization/app_initializer_test.dart test/infrastructure/crypto/database/encrypted_database_native_assets_test.dart -r expanded` | PASS (28) | Native readiness precedes provider/key/database access; native and missing-key paths stop downstream work; executor/key/schema regressions remain covered. |
| Phase-60 targeted suite | Architecture, initializer, encrypted-database, backup-crypto, import-atomicity, import, and restore tests | PASS (152) | Current-schema/current-v2-only contract and recovery behavior. |
| Static analysis | `flutter analyze` | PASS (0 issues) | Full repository analyzer. |
| Full serial suite | `flutter test --concurrency=1 -r expanded` | PASS (4,592; 12 skipped) | Completed successfully in serial mode. |
| SEC-02 deterministic compile lane | `dart run scripts/verify_ios_native_safety_lane.dart --lane=compile` | PASS | Clean retained-lock and disposable from-zero resolution matched; both supported generations produced iOS 15+; all six unsigned Xcode matrix commands exited 0. Source status was clean and preserved. |
| Current-schema lifecycle lane | `dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_lifecycle_test.dart --prepared-clean --before-status-sha256=<redacted clean digest>` | BLOCKED | Supported Flutter iOS package generation reached an Xcode linker failure for undefined Flutter symbols before any attributable lifecycle runtime test could launch. No compile-only or runtime PASS is claimed. |
| Current HPB-v2 backup lane | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart --prepared-clean --before-status-sha256=<redacted clean digest>` | RUNTIME_PASS | Booted Simulator, Debug, exit 0. The structured runner record redacts the Simulator identifier. Profile/Release remain `NOT_RUN` because Flutter integration tests do not execute in those modes. |
| Whitespace integrity | `git diff --check` | Pending final documentation edits | Run again immediately before the documentation commit. |

## Native Runner Record Classification

| Record | Result | Meaning |
| --- | --- | --- |
| External clean preflight | `COMPILE_ONLY` PASS | Prepared-clean and status-preservation guard only. |
| Supported Flutter package generation | `COMPILE_ONLY` PASS for HPB-v2 lane | Generic unsigned Simulator preparation; not runtime. |
| Generated Swift package floor | `COMPILE_ONLY` iOS 15+ | Source-controlled floor inspection; not runtime. |
| Debug generic Simulator tracer | `COMPILE_ONLY` PASS | Generic destination compilation, unsigned. |
| Booted Simulator HPB-v2 recovery | `RUNTIME_PASS` | Attributable current-v2 integration execution. |
| Current-schema lifecycle | `BLOCKED` | Xcode Flutter-symbol linker failure occurred before launch. |
| Retained-lock graph | `COMPILE_ONLY` PASS | Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher Native Assets 4.17.x. |
| Disposable from-zero graph | `COMPILE_ONLY` PASS | Same selected graph and same normalized graph digest as retained locks. |
| Generated package floors | `COMPILE_ONLY` iOS 15+ | Retained and disposable outputs were generated through Flutter and inspected, never edited. |
| `matrix-simulator-debug` | `COMPILE_ONLY` PASS | Runner Debug, generic Simulator, unsigned. |
| `matrix-simulator-profile` | `COMPILE_ONLY` PASS | Runner Profile, generic Simulator, unsigned; Flutter artifact preparation used supported Debug mode. This is not Profile runtime or AOT proof. |
| `matrix-simulator-release` | `COMPILE_ONLY` PASS | Runner Release, generic Simulator, unsigned; Flutter artifact preparation used supported Debug mode. This is not Release runtime or AOT proof. |
| `matrix-device-debug` | `COMPILE_ONLY` PASS | Runner Debug, generic device, unsigned. |
| `matrix-device-profile` | `COMPILE_ONLY` PASS | Runner Profile, generic device, unsigned. |
| `matrix-device-release` | `COMPILE_ONLY` PASS | Runner Release, generic device, unsigned. |

## Requirement and Mitigation Outcome

| Requirement / mitigation | Outcome |
| --- | --- |
| SEC-01 / T-60-C1 | PASS for source/contract fail-closed graph protection; deterministic probe remains flagged unverified. |
| SEC-02 / T-60-C2 | PASS: exact retained/from-zero graph convergence, iOS 15 generated floors, and all six unsigned compile-only matrix entries passed. T-60-C7/T-60-C8 evidence separation and redaction pass. |
| SEC-03 / T-60-C3 | PENDING plan 60-10: the current-schema production-executor lifecycle still requires an attributable booted-Simulator rerun. |
| SEC-04 | N.A. by owner decision: no released population; no historical lane was run. |
| SEC-05 / T-60-C4 through T-60-C6 | PASS: current HPB-v2 recovery runtime plus targeted atomicity/crypto tests. |
| SEC-06 / T-60-C9 | PASS: native readiness is injected and awaited before container/key/database work; schema remains 36. |

The plan 60-09 command directly resolves the SEC-02 deterministic compile probe. SEC-03 remains separate and unresolved; no result in this compile lane is promoted to runtime acceptance.

## Safety and Redaction Receipt

- No Firebase, APNs, local-notification, external API, or schema-push integration was added or invoked.
- No dependency or application-schema change was introduced; no migration artifact was restored or run.
- No physical device was signed, installed, launched, cleared, or inspected.
- Commands used only source-controlled current-schema/current-HPB-v2 tests and an injected synthetic Simulator sandbox.
- This document omits Simulator IDs, absolute paths, credentials, keys, passwords, financial values, notes, merchants, recovery/sync payloads, and synthetic data.

## Remaining Runtime Gate

Plan 60-08 restored clean native linkage and plan 60-09 closes SEC-02 compile convergence. Phase 60 still requires plan 60-10 to run the current-schema lifecycle on a booted Simulator and record `RUNTIME_PASS`. The compile lane had `runtime_test: null`, emitted no `RUNTIME_PASS`, did not boot or launch an app, and cannot satisfy SEC-03.
