---
phase: 59
slug: controlled-platform-plugin-cohorts
status: verified
# threats_open counts OPEN threats at or above workflow.security_block_on (high).
threats_open: 0
threats_total: 35
threats_closed: 35
asvs_level: 1
block_on: high
register_authored_at_plan_time: true
created: 2026-08-09
verified: 2026-08-09
---

# Phase 59 — Security

> Per-phase security contract for the controlled platform-plugin cohorts. The
> register is consolidated from all seven Phase 59 plan-time threat models and
> checked against the summaries, final verification, acceptance ledger, tests,
> and selected dependency graph.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Official evidence to dependency policy | External publisher facts become trusted project policy only after dated, attributable review. | Package identity, version, source, candidate/hold decision |
| Manifest/Pub/lock/ledger to validator | Repository artifacts are untrusted until exact graph and terminal-state checks pass. | Dependency declarations, resolutions, evidence state |
| OS picker/share to Flutter | Platform-owned file and share results enter application code. | Encrypted `.hpb` path and share payload metadata |
| Microphone/recognizer to speech service | Sensitive spoken financial input and native recognition state enter Flutter. | Transcript, locale, permission, error and fallback state |
| APNs/FCM to push service | Remote callbacks enter delivery, identity and navigation policy. | Token/message metadata, identity generation, lifecycle state |
| App lock to OS biometrics | Authentication policy and native outcomes cross the LocalAuthentication boundary. | Biometric options, success/failure/lockout state |
| Secure storage to platform stores | Master and identity keys cross into Keychain/Keystore under fixed options. | Key material and storage operation results |
| Secure storage to AppInitializer/database | Key readiness determines whether encrypted data may be opened. | Key-presence/readability state and database-open decision |
| Native observations to acceptance ledger | Device results become planning evidence without exposing sensitive content. | Redacted platform/build/scenario/result context |
| Generated/test output to phase sign-off | Automated evidence supports terminal acceptance or hold decisions. | Test, analysis, generation, coverage and build results |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|----------|-------------|-----------------------|--------|
| T-59-01 | Spoofing | Official plugin candidate evidence | high | mitigate | `STABLE_BASELINE.json` requires dated official sources, exact selected/candidate values, owner, reason and exit condition; baseline validation passes. | closed |
| T-59-02 | Tampering | Atomic cohort and hold decisions | high | mitigate | Declaration/lock and per-member mutation tests reject missing or partial cohorts; the current graph was independently reconciled. | closed |
| T-59-03 | Information Disclosure | `59-PLUGIN-ACCEPTANCE.md` | high | mitigate | Final evidence is redacted and contains no transcript, token, key, database path, device identity, financial value or production credential. | closed |
| T-59-04 | Denial of Service | Missing native prerequisites | medium | mitigate | Missing Android/iPhone/lifecycle/key prerequisites terminate in exact evidence-backed holds with exit conditions, not graph mutation. | closed |
| T-59-05 | Elevation of Privilege | Cross-cohort security policy | high | mitigate | Tests pin APNs/FCM identity, hidden notifications, biometric-only plus PIN fallback, `unlocked_this_device`, and key-before-database startup. | closed |
| T-59-06 | Tampering | File/share atomic graph | high | mitigate | Exact `file_picker`/`share_plus`/`package_info_plus`/`win32` declaration and lock mutations reject a mixed graph. | closed |
| T-59-07 | Spoofing | Native picker/share acceptance | high | mitigate | Native observations require attributable platform/build/scenario evidence; unavailable observations remain explicit holds. | closed |
| T-59-08 | Information Disclosure | Backup path and share payload | high | mitigate | `.hpb` restriction and encrypted restore/export boundaries remain; evidence stores no path, password, file content or recipient. | closed |
| T-59-09 | Denial of Service | Picker cancellation/missing path | medium | mitigate | Widget characterization proves cancel, null-path and unmounted paths are no-ops and never invoke restore. | closed |
| T-59-10 | Elevation of Privilege | Backup import boundary | high | mitigate | Selected `.hpb` files still flow through `restoreBackupUseCaseProvider`; no raw database importer was added. | closed |
| T-59-11 | Information Disclosure | Speech network fallback | high | mitigate | `allowOnDeviceFallback: false` propagates failure without default-recognition retry; transcript content is excluded from logs/evidence. | closed |
| T-59-12 | Tampering | Speech plugin API adaptation | high | mitigate | Production has one centralized `_speech.listen` call in `SpeechRecognitionService`; adapter and trilingual corpus tests pass. | closed |
| T-59-13 | Spoofing | Physical-iPhone speech acceptance | high | mitigate | Missing physical-iPhone evidence forces the exact `speech_to_text 7.3.0` hold; no simulator or Phase 63 evidence is substituted. | closed |
| T-59-14 | Denial of Service | Speech restart/cancel/error lifecycle | medium | mitigate | Tests prove cancel-before-restart, cached configuration replay, surfaced errors and a one-retry ceiling. | closed |
| T-59-15 | Repudiation | Speech candidate/hold decision | medium | mitigate | Pub, lock, baseline and current ledger agree on the exact 7.3.0 hold; contradiction mutations cover selected-state drift. | closed |
| T-59-16 | Spoofing | APNs/FCM transport identity | high | mitigate | iOS selects `ApnsPushMessagingClient`/`apns` without Firebase initialization; Android selects Firebase/`fcm`. | closed |
| T-59-17 | Tampering | Notification release policy | high | mitigate | Architecture contracts keep push hidden, Android auto-init/analytics disabled, and iOS remote-notification mode/entitlement absent. | closed |
| T-59-18 | Information Disclosure | Push payload/token handling | high | mitigate | Identity-generation fencing remains and evidence/logging excludes payloads, tokens, group/device identity and credentials. | closed |
| T-59-19 | Denial of Service | Push initialization pipeline | medium | mitigate | Regression tests prove failure retry, concurrent idempotency, initialization ordering and single-subscription cleanup. | closed |
| T-59-20 | Elevation of Privilege | Stale push identity navigation | high | mitigate | Generation binding, revoke/clear state and acceptance policy remain before notification display/navigation. | closed |
| T-59-21 | Elevation of Privilege | LocalAuthentication options | high | mitigate | Interaction tests require `biometricOnly`, `sensitiveTransaction` and `persistAcrossBackgrounding`; OS-passcode bypass is not accepted. | closed |
| T-59-22 | Denial of Service | Biometric lockout/native exceptions | high | mitigate | All LocalAuthException, PlatformException and residual failures—including availability probes—reach app-PIN fallback. | closed |
| T-59-23 | Spoofing | Native Face ID acceptance | high | mitigate | Missing attributable Face ID/PIN evidence retains the exact `local_auth 3.0.2` hold and remains non-PASS. | closed |
| T-59-24 | Information Disclosure | Biometric evidence | high | mitigate | Ledger records no PIN, biometric data, device identifier, Keychain item, user data or credential. | closed |
| T-59-25 | Tampering | `local_auth` declaration/lock | medium | mitigate | Exact selected/candidate contract and Pub mutation tests reject unreviewed version drift. | closed |
| T-59-26 | Tampering | Keychain accessibility/options | high | mitigate | Source and tests pin `unlocked_this_device`, established Android options, precise clear scopes and centralized access. | closed |
| T-59-27 | Denial of Service | Existing-key readability | high | mitigate | Secure-storage 11 remains unselected until a reviewed read-then-rewrite migration and prior-build key evidence exist. | closed |
| T-59-28 | Elevation of Privilege | Missing key with existing data | high | mitigate | `AppInitializer` returns `masterKeyMissingWithData` and invokes neither replacement-key creation nor database factory. | closed |
| T-59-29 | Information Disclosure | Key/storage evidence | high | mitigate | Evidence contains only redacted result context—no key, database path/header, credential, device identity or user data. | closed |
| T-59-30 | Repudiation | Secure-storage hold decision | medium | mitigate | Pub, lock, baseline, tests and current ledger agree on `flutter_secure_storage 10.3.1` and its exit condition. | closed |
| T-59-31 | Tampering | Cross-artifact selected graph | high | accept | Current Pub/lock/baseline/document/ledger artifacts were independently inspected and agree. The owner accepted the residual limitation that Markdown terminal `Decision` and native-result rows are not yet fully machine-compared; see AR-59-01. | closed |
| T-59-32 | Spoofing | Native acceptance/final sign-off | high | mitigate | Every unavailable native condition remains `UNAVAILABLE — HOLD`; final sign-off uses recorded command output and never fabricates PASS evidence. | closed |
| T-59-33 | Information Disclosure | Consolidated evidence | high | mitigate | Final redaction review found no transcript, token, key, database path, device identity, credential, payload or financial value. | closed |
| T-59-34 | Denial of Service | Generated/full-suite regression | medium | mitigate | Reproducible generation/architecture wrapper, analyzer, focused matrix, 4,589-test serial suite and 15/15 coverage gate passed. | closed |
| T-59-35 | Elevation of Privilege | Notification/biometric/key policy drift | high | mitigate | Final architecture/unit suites pin hidden notifications, transport split, biometric-only/PIN fallback, Keychain options and fail-closed startup. | closed |

*Status: open · closed · open — below high threshold (non-blocking)*  
*Severity: critical > high > medium > low; only open threats at or above `workflow.security_block_on: high` count toward `threats_open`.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-59-01 | T-59-31 | The current exact selected graph and acceptance ledger were independently reconciled and are consistent; the authoritative baseline/declaration/lock gates remain fail-closed. The accepted residual is limited to future contradictory Markdown terminal `Decision` or native-result text potentially evading the secondary artifact validator until typed ledger parsing and negative mutations are added. It does not authorize accepting unavailable native evidence, splitting a cohort, or changing a held dependency. | Project owner via `$gsd-secure-phase 59` option 2 | 2026-08-09 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-08-09 | 35 | 35 | 0 | Codex GSD security orchestrator (ASVS L1) |

### Audit Notes

- Seven plan-time `<threat_model>` registers were present, so retroactive-STRIDE discovery was not required.
- No summary contained a `Threat Flags` section or an implementation threat escalation.
- Phase verification passed 7/7 must-haves. The exact held graph, focused 319-test matrix, strict analyzer, reproducible generation/architecture wrapper, full serial suite, coverage gate, and iOS Runner build/test evidence support the mitigated closures.
- Review finding WR-01 is represented by accepted risk AR-59-01. WR-02 (in-memory Drift test database cleanup) is test-isolation debt, not an open production threat in this register.
- No specialized auditor was required after the owner explicitly accepted the only preliminary open threat under the workflow's accepted-risk path.

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-08-09
