---
phase: 06
slug: low-fixes
status: verified
threats_open: 0
asvs_level: 1
block_on: HIGH
created: 2026-04-27
---

# Phase 06 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

**Verdict:** SECURED — 13/13 threats closed.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Scanner output → audit catalogue | Shard JSON becomes stable LOW finding rows | Finding metadata (severity, status, commit) |
| Source files → architecture tests | Tests read repository code and fail on forbidden patterns | Source contents (`// ignore:`, logging calls) |
| Migration SQL → encrypted local database | Static migration statements change existing user databases | Schema DDL |
| Test old schema → current migration | Raw schema fixture validates upgrade behavior | Schema fixture, `PRAGMA index_list` results |
| App runtime → device/system logs | Diagnostic messages can escape the app's encrypted storage boundary | Plaintext logs (was: amounts, IDs, tokens) |
| Family-sync application → logs | Transaction, group, device, and payload metadata can escape to system logs | Sync metadata |
| Sync networking → logs | Request metadata and cryptographic material can be accidentally logged | HTTP body, signatures, tokens |
| Push notification SDK → logs | Tokens and message payloads can escape to system logs | Push tokens, raw payloads |
| Local verification → CI | Local gates become pull-request blocking checks | Test/scanner exit codes |
| Audit catalogue → roadmap completion | LOW finding status controls phase completion | Phase manifest, closed_commit metadata |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation | Status |
|-----------|----------|-----------|-------------|------------|--------|
| T-06-01-01 | R | `.planning/audit/issues.json` | mitigate | Stable DC IDs + `closed_in_phase` / `closed_commit` lifecycle fields; `low_findings_closed_test.dart` gate | closed |
| T-06-01-02 | T | `stale_suppressions_scan_test.dart` | mitigate | Skip generated outputs (`lib/generated/`, `*.g.dart`, `*.freezed.dart`, `*.mocks.dart`); explicit `approvedSuppressions` allow-list with reasons | closed |
| T-06-02-01 | T | `app_database.dart` v15 migration | mitigate | Six literal `customStatement('CREATE INDEX IF NOT EXISTS …')` calls — zero string interpolation | closed |
| T-06-02-02 | D | v15 migration | mitigate | Idempotent `IF NOT EXISTS`; `index_v15_migration_test.dart` asserts every expected index name via `PRAGMA index_list` | closed |
| T-06-03-01 | I | accounting logging | mitigate | All `print/debugPrint/dev.log` calls removed from `main.dart`, `app_initializer.dart`, `create_transaction_use_case.dart`, `merchant_category_learning_service.dart`, `transaction_repository_impl.dart` | closed |
| T-06-03-02 | I | `app_initializer.dart` logging | mitigate | `deviceId` retrieved only as a non-empty validity check; zero logging calls in the file | closed |
| T-06-03-03 | R | logging regression guard | mitigate | `production_logging_privacy_test.dart` blocks `print(`, unguarded `debugPrint/dev.log`, and 12-name sensitive list; `analysis_options.yaml` has `avoid_print: true` | closed |
| T-06-04-01 | I | family-sync logging | mitigate | Transaction/group/device/payload identifiers removed; retained `debugPrint` calls are `kDebugMode`-guarded and emit only counts/modes/lifecycle status | closed |
| T-06-04-02 | R | logging regression guard | mitigate | `production_logging_privacy_test.dart` re-run scoped to family-sync files (06-04 SUMMARY) | closed |
| T-06-05-01 | I | `relay_api_client.dart` logging | mitigate | `_logRequest` logs only `method`; `_logResponse` logs only `method` + status code; no body/path/signature/auth header/`message=` interpolation; both `kDebugMode`-guarded | closed |
| T-06-05-02 | I | `push_notification_service.dart` logging | mitigate | All `debugPrint` calls `kDebugMode`-guarded and emit only generic lifecycle strings; no token values, no raw message dumps | closed |
| T-06-05-03 | R | logging regression guard | mitigate | `production_logging_privacy_test.dart` re-run scoped to sync infrastructure files (06-05 SUMMARY) | closed |
| T-06-06-01 | R | LOW closure evidence | mitigate | `low_findings_closed_test.dart` active; 24 closed LOW rows all carry non-empty `closed_commit`; full local verification pass logged in 06-06 SUMMARY | closed |
| T-06-06-02 | D | CI audit scanner step | mitigate | `.github/workflows/audit.yml` runs `Audit scanners`, `Merge findings`, and per-file coverage gate as blocking (no `continue-on-error`); `phase6-touched-files.txt` enumerates all 19 production files | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

---

## Accepted Risks Log

No accepted risks. All 13 threats had `mitigate` disposition and were verified closed.

---

## Cross-Cutting Privacy Posture (Plans 03–05)

The privacy-safe logging boundary now has three layers of defence:

1. **Static gate** — `test/architecture/production_logging_privacy_test.dart` blocks regression via name-based scan over `print/debugPrint/dev.log` calls and a `kDebugMode` proximity check.
2. **Lint gate** — `analysis_options.yaml: avoid_print: true` blocks bare `print()` at analyzer level.
3. **CI gate** — `.github/workflows/audit.yml` runs `flutter analyze` and the audit scanners as blocking steps; LOW reopen fails `low_findings_closed_test.dart`.

Combined effect: any future attempt to log `body`, `token`, `signature`, `deviceId`, `groupId`, `inviteCode`, `transactionId`, `payload`, `encryptedPayload`, `publicKey`, `privateKey`, `message=`, or to introduce a bare `print()`, fails locally and in CI.

---

## Verification Method

For each `mitigate` threat:

1. Read PLAN file `<threat_model>` block to extract the declared mitigation pattern.
2. Open the cited implementation/test/config artifact.
3. Grep / inspect the mitigation pattern (`rg`, `jq`, or direct line read).
4. Confirm the pattern is present at the location declared by the plan.

Implementation files were NOT modified during this audit. Evidence citations are anchored to file paths and line ranges captured at audit time (commit `2d7900f`).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-04-27 | 13 | 13 | 0 | gsd-security-auditor (Phase 6 close) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-04-27
