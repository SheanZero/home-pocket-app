---
phase: 55-pin-phase
plan: 01
subsystem: security
tags: [argon2id, kdf, pin, app-lock, cryptography, isolate, phc, constant-time]

requires:
  - phase: 49-52 (v1.9)
    provides: cryptography 2.9.0 already a direct dep; SecureStorageService + StorageKeys.pinHash greenfield slot
provides:
  - "pin_kdf.dart: off-isolate salted Argon2id KDF (derivePinPhc / verifyPin) — the sole brute-force defense for the 4-digit PIN"
  - "Self-describing PHC string format stored in the existing pinHash keychain slot (no new StorageKey, no migration)"
  - "Constant-time PIN verification (no timing oracle)"
affects: [55-05 (set-PIN flow), 55-07 (app_lock_service consumes derive/verify), 55-11 (on-device latency calibration)]

tech-stack:
  added: []  # NO new dependency — reuses pre-existing cryptography 2.9.0
  patterns:
    - "Heavy KDF runs entirely inside Isolate.run with a top-level worker + isolate-sendable args record (no closures over this)"
    - "Secret material encoded as a PHC-style string so params+salt+hash travel together"

key-files:
  created:
    - lib/infrastructure/security/pin_kdf.dart
    - test/infrastructure/security/pin_kdf_test.dart
  modified:
    - lib/infrastructure/security/secure_storage_service.dart

key-decisions:
  - "Argon2id m=19456, t=2, p=1, 32-byte output, 16-byte CSPRNG salt (OWASP-documented minimum; decided in RESEARCH §1)"
  - "parallelism pinned to 1 — DartArgon2id with p>1 spawns its own internal isolates, which would nest inside Isolate.run"
  - "Single PHC string in the existing pinHash slot instead of a separate pinSalt key (two keys can desync); zero StorageKeys change"
  - "Greenfield slot — no legacy SHA-256 hash in the wild, so no migration; first set-PIN writes the new format"
  - "Pure top-level functions, NOT a Riverpod provider — consumed directly by app_lock_service in Plan 07"

patterns-established:
  - "Off-isolate slow-hash: derive whole Argon2id (construct + deriveKey + extractBytes) inside Isolate.run so the UI isolate never blocks"
  - "constantTimeBytesEquality.equals for all secret-byte comparisons — never == on hash bytes"
  - "Best-effort PHC parse returns null (verify => false) on any malformation rather than throwing"

requirements-completed: [LOCK-07]

coverage:
  - id: D1
    description: "PIN stored only as a salted Argon2id PHC hash, never plaintext; derivation runs off the main isolate"
    requirement: "LOCK-07"
    verification:
      - kind: unit
        ref: "test/infrastructure/security/pin_kdf_test.dart (structure, salt-uniqueness, determinism, round-trip)"
        status: pass
      - kind: other
        ref: "grep gates: Isolate.run present, Argon2id m=19456 p=1 present, no plaintext stored"
        status: pass
    human_judgment: false
  - id: D2
    description: "PIN verification uses constant-time byte comparison (no timing oracle)"
    requirement: "LOCK-07"
    verification:
      - kind: unit
        ref: "test/infrastructure/security/pin_kdf_test.dart (reject wrong PIN, garbage PHC => false)"
        status: pass
      - kind: other
        ref: "grep gate: constantTimeBytesEquality used"
        status: pass
    human_judgment: false
  - id: D3
    description: "On-device latency calibration (250–500 ms target, 150–800 ms band) for the pure-Dart Argon2id params"
    verification: []
    human_judgment: true
    rationale: "Pure-Dart timing is device-dependent; deferred to Plan 11's on-device QA checkpoint per the plan. Not assertable in CI."

status: complete
---

# Phase 55 Plan 01: PIN KDF (Off-isolate Salted Argon2id) Summary

Off-isolate salted-slow-hash KDF (`pin_kdf.dart`) that is the sole brute-force defense for the 4-digit app-lock PIN (LOCK-07): Argon2id (m=19456, t=2, p=1, 32B) via the already-present `cryptography` 2.9.0, run inside `Isolate.run`, encoded as a self-describing PHC string in the existing `pinHash` keychain slot, with constant-time verification. No new dependency, no migration.

## Accomplishments

- **`derivePinPhc(String pin)`** — generates a fresh 16-byte `Random.secure()` salt, derives Argon2id off the main isolate via `Isolate.run`, and returns `argon2id$v=19$m=19456,t=2,p=1$<b64 salt>$<b64 hash>`. Two calls for the same PIN yield different strings (unique salt).
- **`verifyPin(String pin, String phc)`** — parses salt+params from the stored PHC, re-derives off-isolate with the same salt, and compares with `constantTimeBytesEquality.equals` (never `==` on bytes). Returns `false` (no throw) on empty/garbage PHC.
- **PHC encode/parse helpers** — params recoverable for future migration detection; malformed input parses to `null`.
- **Corrected `StorageKeys.pinHash` doc comment** — was the legacy/aspirational "SHA-256"; now documents the Argon2id PHC format and the greenfield no-migration property. Key name, get/set/deletePinHash signatures, and `unlocked_this_device` accessibility all untouched.
- **6 deterministic unit tests** covering structure, salt-uniqueness, determinism, wrong-PIN reject, PHC round-trip (m/t/p + 16-byte salt + 32-byte hash), and garbage-input. No wall-clock latency assertions (device calibration is Plan 11).

## Task Commits

| Task | Name | Type | Commit |
| ---- | ---- | ---- | ------ |
| 1 | Failing pin_kdf unit tests (RED) | test | a29b4f0d |
| 2 | Implement pin_kdf Argon2id off-isolate + PHC + constant-time (GREEN) | feat | 7a21d3af |
| 3 | Correct stale pinHash SHA-256 comment | docs | 4c0b5d19 |

## Verification

- `flutter test test/infrastructure/security/pin_kdf_test.dart` — 6/6 GREEN.
- `flutter analyze` on both touched lib files (`pin_kdf.dart`, `secure_storage_service.dart`) — 0 issues.
- Acceptance grep gates: `constantTimeBytesEquality` present, `Isolate.run` present, `Argon2id` with `parallelism: 1` (`_kParallelism = 1`) and `memory: 19456` (`_kMemoryKib = 19456`) present, `unlocked_this_device` unchanged (2), `getPinHash` signature unchanged (1), no `PIN SHA-256` text remaining (0).

## TDD Gate Compliance

RED (`test(55-01)` a29b4f0d) → GREEN (`feat(55-01)` 7a21d3af) → docs (4c0b5d19). RED confirmed by compile-fail (`derivePinPhc` not found) before implementation.

## Threat Model Outcomes

- **T-55-01 (PIN at rest, mitigate)** — only the salted Argon2id PHC is stored; plaintext never persisted. ✅
- **T-55-02 (verify timing, mitigate)** — `constantTimeBytesEquality` constant-time compare. ✅
- **T-55-04 (main-isolate jank, mitigate)** — full derivation inside `Isolate.run`. ✅
- **T-55-03 (offline brute-force, accept)** — Argon2id memory-hardness raises per-guess cost; residual 4-digit/no-cooldown is the explicitly accepted risk (D-06). Device-calibrated params handled in Plan 11.
- **T-55-SC (supply chain, accept)** — no new packages; `cryptography` 2.9.0 is a pre-existing audited direct dep.

## Deviations from Plan

**1. [Rule 1 — Bug] Fixed 2 analyzer info issues introduced by the doc comment**
- **Found during:** Task 2
- **Issue:** `unintended_html_in_doc_comment` on the `<base64(salt)>`/`<base64(hash)>` angle brackets in the PHC example doc comment — would fail the "0 issues" acceptance gate.
- **Fix:** Wrapped the PHC example line in backticks (inline code) so the analyzer does not treat `<...>` as HTML.
- **Files modified:** lib/infrastructure/security/pin_kdf.dart
- **Commit:** 7a21d3af (folded into the GREEN commit before staging)

Otherwise the plan executed as written.

## Notes for Downstream Plans

- **KDF params live as named constants** (`_kMemoryKib`, `_kIterations`, `_kParallelism`, `_kHashLength`, `_kSaltLength`) — Plan 11 calibration may bump `_kIterations` to 3 (or drop memory to 12288) based on on-device timing; the PHC format already records the params so older hashes remain verifiable if params change.
- **Consumption contract:** `derivePinPhc()` output → `SecureStorageService.setPinHash()`; `verifyPin()` ← `getPinHash()`. Plan 07 (`app_lock_service`) wires these; no Riverpod provider was added here by design.

## Self-Check: PASSED

- FOUND: lib/infrastructure/security/pin_kdf.dart
- FOUND: test/infrastructure/security/pin_kdf_test.dart
- FOUND: lib/infrastructure/security/secure_storage_service.dart (modified)
- FOUND commit a29b4f0d (test, RED)
- FOUND commit 7a21d3af (feat, GREEN)
- FOUND commit 4c0b5d19 (docs, comment fix)
