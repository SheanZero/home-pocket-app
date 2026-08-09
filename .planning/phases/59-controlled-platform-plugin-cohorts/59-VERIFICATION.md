---
phase: 59-controlled-platform-plugin-cohorts
verified: 2026-08-09T02:46:00Z
status: passed
score: 7/7 must-haves verified
behavior_unverified: 0
overrides_applied: 0
---

# Phase 59: Controlled Platform Plugin Cohorts Verification Report

**Phase Goal:** Users retain working file, share, speech, notification, biometric, and secure-storage behavior while each plugin cohort is either safely modernized or evidence-held.
**Verified:** 2026-08-09T02:46:00Z
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
| --- | --- | --- | --- |
| 1 | PLUG-01: every direct/significant platform dependency has an exact current/candidate/hold record, official source, query date, owner, reason, and exit condition. | ✓ VERIFIED | `STABLE_BASELINE.json` has 14 Phase-59 direct rows plus the transitive `win32` row, all dated 2026-08-09 and held; the live baseline validator passed with 0 errors/warnings. |
| 2 | PLUG-02: the file/share/package-info/win32 graph is atomic and `.hpb` import plus supported share flows remain wired. | ✓ VERIFIED | Exact declarations/resolutions are `file_picker` 11.0.3, `share_plus` 12.0.2, `package_info_plus` 9.0.1, `win32` 5.15.0; contract mutations are covered. `backup_restore_screen.dart` restricts to `hpb`, returns on cancel/null path, calls `restoreBackupUseCaseProvider`, and shares an `XFile`; both family invite screens retain text `SharePlus` calls. |
| 3 | PLUG-03: speech remains centralized, preserves trilingual/error/cancel/fallback semantics, and 7.3.0 remains exact until candidate native evidence exists. | ✓ VERIFIED | The sole production `_speech.listen` call is in `SpeechRecognitionService`; restart cancels active recognition then replays cached arguments; `allowOnDeviceFallback: false` rethrows before retry. Pub declaration and lock are exactly 7.3.0; all physical-iPhone rows are `UNAVAILABLE — HOLD`, never PASS. |
| 4 | PLUG-04: APNs/FCM split, hidden notification policy, retryable lifecycle, biometric-only/PIN fallback, storage policy, and key-before-database behavior remain intact. | ✓ VERIFIED | iOS injects `ApnsPushMessagingClient`/no Firebase/`apns`; other platforms inject Firebase/`fcm`. `_initializeOnce` fences and cancels subscriptions after failure. `pushNotifications` is false; Android removes POST_NOTIFICATIONS at manifest merge and disables Firebase auto-init; iOS has no remote-notification mode or `aps-environment`. Biometric options and fallback mappings are tested; storage uses `unlocked_this_device`; initializer order tests exercise the fail-closed missing-key path. |
| 5 | No unavailable Android, iPhone, lifecycle, or pre-existing-key condition is presented as accepted native evidence. | ✓ VERIFIED | The acceptance ledger uses `UNAVAILABLE — HOLD` for picker/share, speech, FCM/APNs, biometric, and stored-key observations, with concrete exit conditions; no Phase 60–63 evidence is substituted. |
| 6 | API surface, STRIDE/ASVS controls, six edge-probe resolutions, and Nyquist sampling cover the held graph. | ✓ VERIFIED | Live `api-coverage.verify-pre` passed: 63 capabilities (53 INTEGRATE, 10 reasoned opt-outs). `59-VALIDATION.md` is `validated`, `nyquist_compliant: true`, and maps T-59-01 through T-59-34. |
| 7 | The user-authorized initializing-formal cleanup is behavior-preserving and leaves strict analysis clean. | ✓ VERIFIED | Commit `da459184` is constructor-formal-only across application/data/infrastructure files; no dependency, native, schema, generated-file, or architecture-boundary change was introduced. Fresh `flutter analyze` reported 0 issues and the 319-test focused matrix passed. |

**Score:** 7/7 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
| --- | --- | --- | --- |
| `docs/testing/STABLE_BASELINE.json` | Canonical selected/candidate/hold graph | ✓ VERIFIED | Exact Phase-59 values agree with `pubspec.yaml` and `pubspec.lock`; every selection is an evidence-backed hold. |
| `scripts/dependency_compatibility.dart` | Fail-closed cohort validator | ✓ VERIFIED | `_validatePhase59PluginCohorts` enforces inventory, atomic graph, candidate/hold state, security policy, and exact declaration/lock values. |
| `test/architecture/dependency_compatibility_contract_test.dart` | Contract and mutation coverage | ✓ VERIFIED | 319-test focused matrix passed; mutation groups cover PLUG-01 through PLUG-04. |
| `59-PLUGIN-ACCEPTANCE.md` | Redacted acceptance/hold ledger | ✓ VERIFIED | Current rows match the held graph and contain no sensitive tokens, keys, paths, financial data, or device identifiers. |
| `COVERAGE.md` / `59-VALIDATION.md` | Capability and Nyquist evidence | ✓ VERIFIED | API precheck passed; validation map enumerates the 63-capability surface and all planned cohorts. |

### Key Link Verification

| From | To | Via | Status | Details |
| --- | --- | --- | --- | --- |
| Pubspec/lock | compatibility validator | exact selected graph | ✓ WIRED | Live baseline validation passed. |
| Backup screen | encrypted restore/share seams | FilePicker → use case; SharePlus → XFile | ✓ WIRED | Concrete source calls and focused widget/unit tests passed. |
| Speech callers | `SpeechRecognitionService` | one plugin adapter | ✓ WIRED | Exactly one production `_speech.listen` occurrence; retry/cancel tests passed. |
| Push provider | push service | platform-selective APNs/FCM injection | ✓ WIRED | Source contract and fake-client lifecycle tests passed. |
| Key manager | initializer/database factory | key readiness before DB construction | ✓ WIRED | Call-order/missing-key tests passed; runtime code has the fail-closed branch before `_databaseFactory`. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
| --- | --- | --- | --- | --- |
| Backup restore screen | picked backup path | `FilePicker.pickFiles()` | Passed into encrypted restore use case only after guards | ✓ FLOWING |
| Push service | identity/token/messages | acceptance policy and messaging/local clients | Identity generation fences token registration and message routing | ✓ FLOWING |
| Speech service | cached recognition config | caller arguments | Replayed after active-session cancel; fallback flag preserved | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
| --- | --- | --- | --- |
| Exact held graph and policy | `dart run scripts/dependency_compatibility.dart --mode=baseline --verify-running-flutter-sdk` | 0 errors, 0 warnings | ✓ PASS |
| API coverage | `gsd-tools check api-coverage.verify-pre …/59-controlled-platform-plugin-cohorts` | 63 capabilities; 53 integrate; 10 opt-outs | ✓ PASS |
| Cohort regression matrix | Phase-59 focused `flutter test` command | 319 tests passed | ✓ PASS |
| Analyzer after constructor cleanup | `flutter analyze` | 0 issues | ✓ PASS |
| Reproducible generation/architecture | `bash scripts/verify_codegen_reproducibility.sh` | two passes wrote 0 outputs; analyzer, lint, architecture and negative guards passed | ✓ PASS |
| Coverage gate | `dart run scripts/coverage_gate.dart … --threshold 70` | 15 checked, 0 below threshold, 0 deferred | ✓ PASS |

The recorded final serial run is `4,589` passed with `12` expected skips. I did not claim a Phase-59 Runner/native build: no candidate was accepted and native prerequisites are explicitly held.

### Probe Execution

No standalone `scripts/**/tests/probe-*.sh` probe is declared for Phase 59. The six edge-probe resolutions are exercised by the dependency contract mutation tests and the API-coverage precheck above.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
| --- | --- | --- | --- | --- |
| PLUG-01 | 59-01, 59-07 | Independent official/current/hold decisions | ✓ SATISFIED | Complete dated inventory, official links, exact declarations/locks, and fail-closed baseline validator. |
| PLUG-02 | 59-02, 59-07 | Atomic cohort and `.hpb`/share preservation | ✓ SATISFIED | Exact four-member hold, mutation contract, picker/restore/share source and test coverage. |
| PLUG-03 | 59-03, 59-07 | Safe speech candidate or exact 7.3.0 hold | ✓ SATISFIED | Central adapter, ja/zh/en and fallback tests, exact hold/UNAVAILABLE physical evidence. |
| PLUG-04 | 59-04..07 | Notification, biometrics, and storage policy preservation | ✓ SATISFIED | Transport/hidden-policy contracts, retry regression, biometric fallback, storage and initialization tests. |

### Anti-Patterns and Review Debt

| ID | File | Severity | Finding | Verification disposition |
| --- | --- | --- | --- | --- |
| WR-01 | `scripts/dependency_compatibility.dart:1404-1480` | ⚠️ Warning | `validatePhase59EvidenceArtifacts()` checks fixed Markdown row markers and `UNAVAILABLE — PASS`, but does not parse/compare terminal `Decision:` headings or individual native result rows to the baseline. A future contradictory ledger can therefore evade this secondary artifact gate. | **Non-blocking technical debt.** Current manifest, ledger, Pub graph, and policy source were independently inspected and agree; baseline acceptance itself remains fail-closed. Add typed ledger parsing (or a machine-readable ledger) plus negative decision/result mutations before relying on this gate as the sole convergence control. |
| WR-02 | `test/core/initialization/app_initializer_test.dart:34-35` | ⚠️ Warning | Successful test paths create `AppDatabase.forTesting()` and dispose only their `ProviderContainer`; the focused matrix reproduced Drift's multiple-database/concurrency warning. | **Non-blocking test-isolation debt.** It does not alter production startup or invalidate the explicit call-order assertions, but success-path tests must obtain and `await database.close()` in shared teardown. Similar suite warnings also occur in pre-existing widget test helpers. |

No `TBD`/`FIXME`/`XXX` debt markers were found in phase-modified executable files. The Android `POST_NOTIFICATIONS` string is intentional manifest-merge removal (`tools:node="remove"`), not a restored permission.

### Human Verification Required

None to accept this phase's deliberately unchanged selected graph. Native picker/share, physical-iPhone speech, FCM/APNs lifecycle, Face ID/PIN, and prior-key checks are intentionally `UNAVAILABLE — HOLD` with explicit exit conditions; performing them now would cross the Phase 60–63 ownership boundary rather than close a Phase-59 candidate.

### Gaps Summary

The phase goal is achieved: current behavior remains on exact selected versions and all unavailable native acceptance prerequisites are honestly held. WR-01 and WR-02 are real, scoped technical debt; neither makes a selected plugin unsafe or turns unavailable evidence into an accepted decision in the current codebase. Address them before treating Markdown-ledger validation or initializer-test cleanliness as release-grade evidence on their own.

**Next action:** Proceed to Phase 60 only with the held graph unchanged; schedule the two review-debt fixes as narrow test/tooling work.

---

_Verified: 2026-08-09T02:46:00Z_
_Verifier: the agent (gsd-verifier)_
