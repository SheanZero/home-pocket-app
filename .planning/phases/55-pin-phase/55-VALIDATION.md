---
phase: 55
slug: pin-phase
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-06-30
---

# Phase 55 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Source: `55-RESEARCH.md` § "Validation Architecture". App Lock = UI gate over an
> already-decrypted DB; the lock NEVER binds the DB encryption key.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Dart) + `mocktail` for service fakes |
| **Config file** | none — `flutter test` auto-discovers `test/**`; goldens via `flutter_test_config.dart` |
| **Quick run command** | `flutter test test/<scoped path for the task under test>` |
| **Full suite command** | `flutter analyze && flutter test` |
| **Estimated runtime** | quick ~10–30s · full suite several minutes (~2300 tests) |

> Goldens are macOS-baselined (see [[golden-ci-platform-gate]]); update baselines only on macOS.
> Never `dart format` the whole `test/` tree (repo is not format-clean).

---

## Sampling Rate

- **After every task commit:** Run the quick `flutter test` for the touched area.
- **After every plan wave:** Run `flutter analyze && flutter test` (full — architecture tests
  like the hardcoded-CJK UI scan + ARB parity only fire in the full suite).
- **Before `/gsd-verify-work`:** Full suite must be green, `flutter analyze` 0 issues.
- **Max feedback latency:** ~30s for the quick loop.

---

## Per-Task Verification Map

> Populated once the planner emits task IDs. Each LOCK-0x criterion maps to the test
> type below (full requirement→test map in `55-RESEARCH.md` § Validation Architecture).

| Requirement | Secure Behavior (must be TRUE) | Test Type | Notes |
|-------------|--------------------------------|-----------|-------|
| LOCK-01/06 | "Lock effective" = `appLockEnabled && pinHash != null`; enabling forces 4-digit PIN set; disabling = no-op | unit | predicate has a single source of truth |
| LOCK-02/03/04 | Cold-start + `paused`→`resumed` relock; mask on `inactive`; mask only when lock enabled | widget | lifecycle guard (`_authInProgress` + `_didPause`) tested with `TestWidgetsFlutterBinding` lifecycle events |
| LOCK-05/10 | Every `LocalAuthExceptionCode` (all 14, incl. lockedOut/permanentlyLockedOut/cancel) → PIN fallback; wildcard `_ → fallbackToPIN` | unit | regression test asserting the *new* `LocalAuthException` model, not legacy `PlatformException` |
| LOCK-07 | Salted Argon2id (m=19456,t=2,p=1,32B) off-isolate; PHC-string in `pinHash`; constant-time compare; never plaintext | unit | KDF determinism (same pin+salt→same hash); wrong pin→reject; `constantTimeBytesEquality` used |
| LOCK-09 | Lock-screen copy states forgotten-PIN is unrecoverable (reinstall + lose unsynced local data); no recovery hint; new ARB keys ja/zh/en parity | arch | ARB parity test + hardcoded-CJK scan (full suite only) |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Test fakes/mocks for `BiometricService`, `SecureStorageService`, `SettingsRepository`
      (mocktail) — enabling unit tests of the unlock controller without platform channels.
- [ ] A lifecycle harness helper to drive `AppLifecycleState` transitions in widget tests.

*Existing `flutter_test` infrastructure otherwise covers all phase requirements (no framework install needed).*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Face ID/Touch ID prompt → `active→inactive→resumed` does NOT spuriously relock or flicker the mask | LOCK-03/04/05 | System biometric UI + real lifecycle cannot be faithfully simulated in `flutter_test` | On device: enable lock, set PIN, foreground app, trigger Face ID; confirm no mask flash, no relock loop; cancel Face ID → lands on PIN page |
| Task-switcher / app-switcher snapshot shows opaque brand cover, no ledger amounts | LOCK-04 | Snapshot timing is OS-driven and device-dependent ([[research A3]]) | On device (iOS + Android): open app-switcher, inspect the app's thumbnail |
| KDF latency in the 250–500ms target band on a real mid-range device | LOCK-07 | Argon2id cost is device-dependent; needs on-device calibration | Time set-PIN + unlock on a real device; adjust params if outside band |
| Keychain accessibility unchanged → existing installs not bricked | LOCK-07 | Requires upgrade-install over a prior build | Install over a previous version; confirm master key still readable (app boots past init) |

---

## Validation Sign-Off

- [ ] All tasks have an automated verify or a Wave 0 dependency
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s for the quick loop
- [ ] `nyquist_compliant: true` set in frontmatter (after planner fills the per-task map)

**Approval:** pending
