---
phase: 60
plan: "10"
status: pass_ready_for_verification
captured: 2026-08-09
source_commit: ef66b5a07be6769a2e785f979a7488346aa60e36
---

# Phase 60 Native Safety Evidence

This record distinguishes successful tests, generic iOS compilation, and booted-Simulator runtime. It intentionally does not promote a pre-launch failure to runtime acceptance.

## Exact Source and Toolchain State

| Item | Value |
| --- | --- |
| Compile source commit | `570064236eead5e9bdbd8567f8c866bf9d48aa99` |
| Compile run start (UTC) | `2026-08-09T13:38:00.022171Z` |
| Runtime source commit | `ef66b5a07be6769a2e785f979a7488346aa60e36` |
| Runtime run start (UTC) | `2026-08-09T13:49:28.742113Z` |
| Runtime destination | Booted iPhone 17 Pro Simulator, iOS 26.2; identifier redacted |
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
| Historical current-schema lifecycle lane (60-07) | `dart run scripts/verify_ios_native_safety_lane.dart --lane=full --runtime-test=integration_test/sqlcipher_native_assets_lifecycle_test.dart --prepared-clean --before-status-sha256=<redacted clean digest>` | BLOCKED | Historical pre-repair evidence only; undefined Flutter symbols prevented launch at that source state. |
| Current-schema lifecycle lane (60-10) | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_native_assets_lifecycle_test.dart` | `RUNTIME_PASS` | Booted iPhone 17 Pro / iOS 26.2 Simulator, Debug integration runtime, exit 0. Production `AppDatabase` verified SQLCipher 4.17.x, `cipher_status == 1`, readable schema, user version 36, integrity, encrypted header, sentinel persistence, explicit close, and same-key cold reopen. |
| Current HPB-v2 backup lane | `dart run scripts/verify_ios_native_safety_lane.dart --lane=runtime --runtime-test=integration_test/sqlcipher_backup_recovery_test.dart --prepared-clean --before-status-sha256=<redacted clean digest>` | RUNTIME_PASS | Booted Simulator, Debug, exit 0. The structured runner record redacts the Simulator identifier. Profile/Release remain `NOT_RUN` because Flutter integration tests do not execute in those modes. |
| Plan 60-10 focused regressions | Eight architecture, startup, encrypted-database, backup-crypto, import-atomicity, and restore test files named in `60-10-PLAN.md` | PASS (79) | Preserves SEC-01/02/05/06 contracts and rollback/tamper behavior after the direct runtime pass. |
| Whitespace integrity | `git diff --check` | Pending final documentation edits | Run again immediately before the documentation commit. |

## Native Runner Record Classification

| Record | Result | Meaning |
| --- | --- | --- |
| External clean preflight | `COMPILE_ONLY` PASS | Prepared-clean and status-preservation guard only. |
| Supported Flutter package generation | `COMPILE_ONLY` PASS for HPB-v2 lane | Generic unsigned Simulator preparation; not runtime. |
| Generated Swift package floor | `COMPILE_ONLY` iOS 15+ | Source-controlled floor inspection; not runtime. |
| Debug generic Simulator tracer | `COMPILE_ONLY` PASS | Generic destination compilation, unsigned. |
| Booted Simulator HPB-v2 recovery | `RUNTIME_PASS` | Attributable current-v2 integration execution. |
| Historical current-schema lifecycle (60-07) | `BLOCKED` | Superseded evidence from before the clean linkage repair; retained for audit history. |
| Retained-lock graph | `COMPILE_ONLY` PASS | Drift 2.34.0 / sqlite3 3.5.1 / SQLCipher Native Assets 4.17.x. |
| Disposable from-zero graph | `COMPILE_ONLY` PASS | Same selected graph and same normalized graph digest as retained locks. |
| Generated package floors | `COMPILE_ONLY` iOS 15+ | Retained and disposable outputs were generated through Flutter and inspected, never edited. |
| `matrix-simulator-debug` | `COMPILE_ONLY` PASS | Runner Debug, generic Simulator, unsigned. |
| `matrix-simulator-profile` | `COMPILE_ONLY` PASS | Runner Profile, generic Simulator, unsigned; Flutter artifact preparation used supported Debug mode. This is not Profile runtime or AOT proof. |
| `matrix-simulator-release` | `COMPILE_ONLY` PASS | Runner Release, generic Simulator, unsigned; Flutter artifact preparation used supported Debug mode. This is not Release runtime or AOT proof. |
| `matrix-device-debug` | `COMPILE_ONLY` PASS | Runner Debug, generic device, unsigned. |
| `matrix-device-profile` | `COMPILE_ONLY` PASS | Runner Profile, generic device, unsigned. |
| `matrix-device-release` | `COMPILE_ONLY` PASS | Runner Release, generic device, unsigned. |
| Current-schema lifecycle (60-10) | `RUNTIME_PASS` | Allowlisted production-database lifecycle executed on a booted iPhone 17 Pro / iOS 26.2 Simulator; exit 0 and identifier redacted. |
| Current-schema Profile/Release runtime | `NOT_RUN` | Flutter's integration-test runner does not execute these modes; no unsupported runtime claim is made. |

## Requirement and Mitigation Outcome

| Requirement / mitigation | Outcome |
| --- | --- |
| SEC-01 / T-60-C1 | PASS: source/contract fail-closed graph protection and deterministic retained/from-zero probe are verified. |
| SEC-02 / T-60-C2 | PASS: exact retained/from-zero graph convergence, iOS 15 generated floors, and all six unsigned compile-only matrix entries passed. T-60-C7/T-60-C8 evidence separation and redaction pass. |
| SEC-03 / T-60-C3 | PASS: the allowlisted production `AppDatabase` lifecycle emitted `RUNTIME_PASS` after encrypted open, write, close, and same-key cold reopen on a booted supported Simulator. |
| SEC-04 | N.A. by owner decision: no released population; no historical lane was run. |
| SEC-05 / T-60-C4 through T-60-C6 | PASS: current HPB-v2 recovery runtime plus targeted atomicity/crypto tests. |
| SEC-06 / T-60-C9 | PASS: native readiness is injected and awaited before container/key/database work; schema remains 36. |

Plan 60-09 directly resolves the SEC-02 deterministic compile probe. Plan 60-10 independently resolves SEC-03 with a booted-Simulator `RUNTIME_PASS`; no compile or host result is used as its substitute.

## Safety and Redaction Receipt

- No Firebase, APNs, local-notification, external API, or schema-push integration was added or invoked.
- No dependency or application-schema change was introduced; no migration artifact was restored or run.
- No physical device was signed, installed, launched, cleared, or inspected.
- Commands used only source-controlled current-schema/current-HPB-v2 tests and an injected synthetic Simulator sandbox.
- This document omits Simulator IDs, absolute paths, credentials, keys, passwords, financial values, notes, merchants, recovery/sync payloads, and synthetic data.

## Verification Handoff

Plan 60-08 restored clean native linkage, plan 60-09 closed SEC-02 compile convergence, and plan 60-10 recorded the independent SEC-03 runtime pass. The compile lane still has `runtime_test: null` and no runtime record; the runtime lane has one Debug `RUNTIME_PASS` and no compile-matrix claim. Phase 60 now requests a fresh independent verification pass rather than self-declaring phase verification complete.
