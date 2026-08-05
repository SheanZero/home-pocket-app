---
phase: 55-pin-phase
plan: 11
subsystem: security
tags: [app-lock, lifecycle-observer, privacy-mask, biometric, flutter, riverpod]

# Dependency graph
requires:
  - phase: 55-06
    provides: AppLockLifecycleObserver (two-flag relock + mask guard, beginAuth/endAuth fences)
  - phase: 55-07
    provides: AppLockService.isLockEffective predicate (D-01 single source of truth)
  - phase: 55-08
    provides: opaque PrivacyMask widget
  - phase: 55-09
    provides: AppLockScreen (onUnlocked / onBeginAuth / onEndAuth props)
provides:
  - main.dart app-lock gate branch (cold-start relock, LOCK-02)
  - AppLockLifecycleObserver registration driving relock (LOCK-03) + mask (LOCK-04)
  - opaque PrivacyMask hosted in MaterialApp.builder via synchronous ValueNotifier
  - setState-flag unlock/relock (no pushReplacement) preserving the data-reset refresh path
affects: [app-lock, security, settings, main.dart, future-lifecycle-work]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Boot-gate flag flip for full-screen lock flows (mirror of Phase 54 onboarding gate)"
    - "Synchronous ValueNotifier<bool> mask host in MaterialApp.builder for pre-snapshot paint timing"
    - "Synchronous _lockConfigured cache so the lifecycle predicate avoids an async provider hop"

key-files:
  created: []
  modified:
    - lib/main.dart
    - test/main_characterization_smoke_test.dart

key-decisions:
  - "Unlock/relock use setState flags (never pushReplacement) so _reinitializeAfterDataReset stays attached (boot-gate-completion-must-flip-flag-not-pushreplacement)"
  - "isLockEffective reads a synchronous _lockConfigured cache (not an async provider) so the mask paints in the same frame the app goes inactive"
  - "PrivacyMask hosted via Positioned.fill inside MaterialApp.builder Stack so the opaque cover is full-bleed above the navigator"
  - "_isLocked re-evaluated in _reinitializeAfterDataReset for parity with cold start (a wipe may clear the PIN hash)"

patterns-established:
  - "Pattern 1: lifecycle observer constructed once (??=) next to syncEngine.initialize(), torn down in State.dispose()"
  - "Pattern 2: gate ladder order error -> spinner -> onboarding -> applock -> shell"

requirements-completed: [LOCK-01, LOCK-02, LOCK-03, LOCK-04]

coverage:
  - id: D1
    description: "LOCK-01 no-op: lock disabled renders the shell with no AppLockScreen and no PrivacyMask"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "test/main_characterization_smoke_test.dart#LOCK-01 no-op: lock disabled renders the shell with no lock screen or mask"
        status: pass
    human_judgment: false
  - id: D2
    description: "LOCK-02 cold start: lockEffective shows AppLockScreen before MainShellScreen via the _isLocked gate branch"
    requirement: "LOCK-02"
    verification:
      - kind: unit
        ref: "test/main_characterization_smoke_test.dart#LOCK-02 cold start: lockEffective shows AppLockScreen before the shell"
        status: pass
    human_judgment: false
  - id: D3
    description: "LOCK-03 relock: a true background round-trip (inactive->paused->resumed) re-shows the lock screen via observer onRelock -> setState"
    requirement: "LOCK-03"
    verification:
      - kind: unit
        ref: "test/main_characterization_smoke_test.dart#LOCK-03 relock: a true background round-trip re-shows the lock screen"
        status: pass
    human_judgment: false
  - id: D4
    description: "LOCK-04 privacy mask: opaque PrivacyMask hosted in MaterialApp.builder, flipped synchronously on inactive so it paints before the OS app-switcher snapshot"
    requirement: "LOCK-04"
    verification:
      - kind: manual_procedural
        ref: "55-11-PLAN.md Task 4 step 3 (app-switcher snapshot inspection on a real device)"
        status: unknown
    human_judgment: true
    rationale: "App-switcher snapshot paint timing is OS-driven; widget tests cannot observe the real OS snapshot frame (RESEARCH §5). The mask host wiring is unit-tested, but the pre-snapshot paint guarantee needs a physical device."
  - id: D5
    description: "Face ID lifecycle: auto-trigger on lock entry, no relock-loop after the system sheet dismisses, PIN escape, KDF latency band"
    verification:
      - kind: manual_procedural
        ref: "55-11-PLAN.md Task 4 steps 2,4,5,6,7,8 (on-device QA)"
        status: unknown
    human_judgment: true
    rationale: "Face ID / Touch ID lifecycle churn, Control Center vs background discrimination, Argon2id derivation latency, and keychain-accessibility upgrade-boot are all OS/device-driven and cannot be faithfully unit-tested (RESEARCH §2/§5, VALIDATION Manual-Only table)."

# Metrics
duration: 30min
completed: 2026-06-30
status: complete
---

# Phase 55 Plan 11: App-Lock Integration Summary

**Wired the app lock into main.dart: a cold-start `_isLocked` gate branch, an `AppLockLifecycleObserver` driving relock + an opaque `PrivacyMask` via a synchronous `ValueNotifier`, all unlocking/relocking through setState flags (never pushReplacement).**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-06-30
- **Tasks:** 3 of 4 code tasks complete; Task 4 is a blocking on-device QA checkpoint (human-needed)
- **Files modified:** 2

## Accomplishments
- `_isLocked` cold-start gate branch in `_buildHome()` (after onboarding, before the shell) — locked boot hard-stops entry to the ledger (LOCK-02 / D-01: `appLockEnabled && pinHash != null`).
- `AppLockLifecycleObserver` registered next to `syncEngine.initialize()`, torn down in a new `dispose()`; `onRelock` flips `_isLocked` via setState, `onMask`/`onUnmask` flip a synchronous `ValueNotifier` (LOCK-03/04).
- Opaque `PrivacyMask` hosted in `MaterialApp.builder` via `Positioned.fill` + `ValueListenableBuilder`, painting above the navigator before the OS snapshot.
- Unlock (`_completeUnlock`) and relock both use setState flags — zero `pushReplacement` calls in the lock wiring — so `_reinitializeAfterDataReset` stays attached; `_isLocked` is re-evaluated post-reset for parity.
- Extended the main smoke test with lock-off no-op, lock-on cold start, and relock-on-resume cases.

## Task Commits

Each task was committed atomically:

1. **Task 1: _isLocked cold-start gate branch + _completeUnlock** - `a333b8f1` (feat)
2. **Task 2: register AppLockLifecycleObserver + host opaque PrivacyMask** - `8c5d3482` (feat)
3. **Task 3: smoke test for lock gate on/off + relock-on-resume** - `8be524a0` (test)

**Task 4 (on-device QA checkpoint):** NOT executed — blocking human verification, returned to the orchestrator.

## Files Created/Modified
- `lib/main.dart` - `_isLocked` + `_lockConfigured` + `_maskVisible` + `_lockObserver` fields; cold-start lock init in `_initialize`; parity re-eval in `_reinitializeAfterDataReset`; gate branch + `_completeUnlock`; observer registration + `dispose()`; PrivacyMask host in `MaterialApp.builder`.
- `test/main_characterization_smoke_test.dart` - `_FakeSecureStorageService`, `_OnceSuccessBiometricService`, `_FallbackBiometricService` fakes; `_pumpApp` now stubs secure storage + biometric and accepts `appLockEnabled`/`pinHash`/`biometric`; new "app-lock gate wiring" group (LOCK-01/02/03).

## Decisions Made
- **setState flags, never pushReplacement** for unlock/relock — keeps the live `'/'` Builder rendering the gate so the data-reset refresh path survives (honors `boot-gate-completion-must-flip-flag-not-pushreplacement`).
- **Synchronous `_lockConfigured` cache** for the observer's `isLockEffective` predicate — an async provider hop would miss the inactive frame and leak the snapshot.
- **`Positioned.fill`** for the mask overlay — a bare non-positioned `Container` under the Stack's loose constraints would shrink to its 96x96 child instead of full-bleed.

## Deviations from Plan
None - plan executed exactly as written. (The PLAN's gate-branch `AppLockScreen` props were added incrementally — Task 1 used the bare `onUnlocked`, Task 2 added `onBeginAuth`/`onEndAuth` — exactly as the plan's task split specified.)

## Issues Encountered
- The fake `BiometricService.authenticate` initially omitted the real `biometricOnly` named parameter; the analyzer flagged the override mismatch and it was corrected to match the production signature. No other issues.

## User Setup Required
None - no external service configuration required.

## On-Device QA Checkpoint (Task 4 — BLOCKING, human-needed)
The OS/device-driven behaviors below cannot be faithfully unit-tested and require a real device before the phase verifies (see coverage D4/D5):
1. Enable アプリロック + set a 4-digit PIN (double-entry); confirm the toggle does NOT enable if set-PIN is cancelled.
2. Fully background then return → lock screen reappears (Face ID auto-prompt); NO flicker, NO relock loop after the sheet dismisses.
3. App-switcher snapshot card shows the opaque brand cover, NOT ledger amounts.
4. Pull down Control Center / Notification Center (no background) → on return NO relock (mask may briefly show, no PIN/Face prompt).
5. Cancel Face ID → 重試 + パスコードを使用 → PIN page; wrong PIN shakes+clears, instantly retryable; correct PIN unlocks.
6. Time set-PIN + unlock → Argon2id ~250-500 ms (band 150-800 ms); file a follow-up if far outside.
7. "PIN をお忘れですか？" copy says unrecoverable / reinstall / lose unsynced data, no recovery hint.
8. Disable the lock → requires re-auth first (D-05).

## Next Phase Readiness
- All code wiring complete; `flutter analyze` 0 issues; smoke test (12 cases) green.
- Phase 55 is fully implemented in code; the ONLY outstanding item is the blocking on-device QA above (Face ID lifecycle, snapshot mask, KDF latency, keychain upgrade-boot).
- WAVE-MERGE / phase verification should run the FULL `flutter analyze && flutter test` (hardcoded-CJK UI scan, ARB parity, import_guard only fire in the full suite).

## Self-Check: PASSED
- Files verified on disk: lib/main.dart, test/main_characterization_smoke_test.dart, 55-11-SUMMARY.md
- Commits verified in git log: a333b8f1, 8c5d3482, 8be524a0

---
*Phase: 55-pin-phase*
*Completed: 2026-06-30*
