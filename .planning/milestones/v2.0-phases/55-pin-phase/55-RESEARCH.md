# Phase 55: 应用锁（生物识别 + PIN）- Research / 专项安全评审

**Researched:** 2026-06-30
**Domain:** Mobile app-lock UI gate · off-isolate KDF · iOS/Android biometric lifecycle · Flutter secure storage
**Confidence:** HIGH (all package facts verified against pub-cache source at resolved lock versions; no training-data version guesses)

> This research **is** the dedicated security review mandated by the ROADMAP for Phase 55 (highest-risk phase). Where CONTEXT defers a parameter to "专项安全评审定参数", the concrete recommended value with rationale is given here. It does **not** re-summarize CONTEXT; it goes deeper on the six high-value targets and surfaces the landmines CONTEXT could only gesture at.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions (D-01 .. D-12 — research honors, never contradicts)
- **D-01:** New `appLockEnabled` master toggle (default **false**) + in-lock `biometricUnlockEnabled` sub-toggle. **「锁生效」= `appLockEnabled && pinHash != null`** (never prompt without a PIN). PIN is always the base credential; biometric is optional overlay.
- **D-02:** Retire legacy `biometricLockEnabled` (default true, read by nobody, no effect) → migrate to off; never let it trigger the new lock. Phase 54 `onboarding_lock_entry_screen.dart`'s `setBiometricLock(false)` "skip=lock off" semantic moves to new `appLockEnabled=false`. New fields stored in SharedPreferences (plaintext, one key/field), **no Drift migration, schemaVersion stays 22**.
- **D-03:** Set-PIN = enter → re-enter to confirm (double-entry). Fixed 4 digits (LOCK-06).
- **D-04:** Settings has a "修改 PIN" entry.
- **D-05:** Disabling the lock **and** changing the PIN both require **re-authentication** first (existing PIN or biometric).
- **D-06 (⚠ explicit LOCK-08 downgrade):** PIN-error handling = **shake + clear + immediate retry only; NO cooldown/backoff/failure counting.** Explicitly descopes LOCK-08. User was told the brute-force implication (4-digit = 10,000 combos, no wipe, no recovery) and **chose this knowingly**. Downstream must: ① security review records this as "known accepted risk" with explicit sign-off (see Security Domain §); ② REQUIREMENTS LOCK-08 rewritten/downgraded into v2; ③ ROADMAP SC-4 "递增冷却" annotated descoped. No "remaining attempts/countdown" UI (nothing to count).
- **D-07:** Privacy mask = theme-following **opaque** brand cover (solid color/logo), **NOT blur**; only when app lock enabled. App-wide, not a tone variant.
- **D-08:** "忘记 PIN?" = low-key tappable text → short explanation (forgot = unrecoverable / must reinstall / lose unsynced local data / no recovery path implied, LOCK-09).
- **D-09:** Auto-trigger Face ID on entering lock screen (cold start + every foreground return); on fail/cancel/unavailable → **stay on Face ID page** with "重试" + ghost button "パスコードを使用" → user taps to switch to PIN page (do not auto-drop to PIN page).
- **D-10:** Phase 54 "现在设置" deep-link → scroll to security section and **immediately start the set-PIN double-entry flow**. Reuse 54-03 `scrollToSecurity`.
- **D-11:** `SecuritySection` refactored to: app-lock master toggle → enabling runs set-PIN flow → after enabled, expand sub-items "生物识别解锁" sub-toggle + "修改 PIN" entry; keep existing `notifications` toggle.
- **D-12:** 4 digits entered → instant verify (no confirm key, standard iOS 9-grid); error = dots **shake + clear + haptic, no text** (tone B minimal).

### Claude's Discretion (technical / security-review territory — values decided in this research)
- **KDF scheme & params**, **lifecycle wiring**, **`local_auth` complete error-classification mapping**, **lock boot-gate placement**, **ARB key naming** (ja/zh/en). See the corresponding sections below for concrete decisions.

### Deferred Ideas (OUT OF SCOPE — do not research/build)
- **LOCK-08 incremental cooldown/backoff** (descoped per D-06 → v2 family; suggest new `LOCK-V2-04`).
- **LOCK-V2-01** configurable relock grace (immediate / 1min / 5min; v2.0 ships fixed-immediate).
- **LOCK-V2-02** forgot-PIN via BIP39 recovery (v2.0 = "no recovery").
- **LOCK-V2-03** optional wipe-after-N-failures (default off).
- **Out of Scope (REQUIREMENTS):** changing secure-storage accessibility; PIN deriving/binding the DB key; account system; go_router.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| LOCK-01 | Toggle app lock in Settings; off = complete no-op | §6 Settings model — `appLockEnabled` gates all lock logic; observer + gate read `lockEffective = appLockEnabled && pinHash != null` |
| LOCK-02 | Cold-start requires unlock before main shell | §4 Boot-gate — new branch in `_buildHome()` ladder before `MainShellScreen` |
| LOCK-03 | Foreground return requires full relock (on `paused`→`resumed`, not `inactive`) | §2 lifecycle guard — `_didPause` flag + root `WidgetsBindingObserver` |
| LOCK-04 | Task-switcher/snapshot privacy mask (`inactive`) | §5 privacy mask — opaque overlay, hand-rolled |
| LOCK-05 | Auto-try biometric first, fall back to PIN | §3 error classification — every `LocalAuthException` code → PIN escape |
| LOCK-06 | 4-digit PIN, mandatory fallback; enabling lock requires setting PIN | §1 KDF + §6 — `lockEffective` predicate enforces PIN presence |
| LOCK-07 | Salted slow-hash (KDF ≥100k iters or Argon2id, off main isolate), existing secure storage, accessibility unchanged, constant-time compare, never plaintext | §1 KDF — Argon2id via `cryptography` 2.9.0 in `Isolate.run`; `constantTimeBytesEquality` |
| LOCK-08 | (DESCOPED per D-06 — known accepted risk) | §Security Domain — explicit sign-off block; do NOT implement backoff |
| LOCK-09 | Forgot-PIN copy: unrecoverable / reinstall / lose unsynced data; no recovery path implied | §6 + ARB keys; D-08 |
| LOCK-10 | Handle complete `local_auth` error classification → always fall back to PIN, never lock user out | §3 — **CRITICAL: existing `PlatformException` handler is dead against local_auth 3.x; must rewrite for `LocalAuthException`** |
</phase_requirements>

---

## Summary

The implementation surface is almost entirely **already present** in the codebase — `BiometricService`, `AuthResult` union, `SecureStorageService.{get,set,delete}PinHash`, `biometricAvailabilityProvider`, the `_buildHome()` gate ladder, and the `SyncLifecycleObserver` pattern. The phase is wiring + one new KDF helper + one lock-screen feature module + a Settings refactor. No new dependencies: `cryptography 2.9.0` (resolved; constraint `^2.7.0`) ships pure-Dart Argon2id + PBKDF2.

Three findings dominate the risk profile and must drive the plan:

1. **`local_auth` 3.0.1 changed its entire error model — the existing error handler is silently dead code.** local_auth 3.x throws `LocalAuthException` (with a `LocalAuthExceptionCode` **enum**), **not** `PlatformException` (with string codes). `BiometricService._handlePlatformException` catches `on PlatformException` and switches on `'LockedOut'`/`'NotEnrolled'`-style strings that **3.x never emits**. In production every biometric error would escape the `catch` and propagate uncaught — directly violating LOCK-10 ("never lock the user out"). This is the single highest-impact fix in the phase. `[VERIFIED: pub-cache local_auth_platform_interface-1.1.0/lib/types/auth_exception.dart + local_auth_darwin-2.0.3]`

2. **The iOS biometric-prompt lifecycle loop is real and must be guarded by an in-flight flag plus a `_didPause` gate.** Presenting Face ID drives the app to `inactive` (and the sheet's own dismissal back to `resumed`); auto-triggering Face ID on the lock screen would, without a guard, fire the privacy mask and a spurious relock — a flicker/re-auth loop. The fix is `_authInProgress` (set around `authenticate()`) **and** relock only when the app actually hit `AppLifecycleState.paused` since the last resume — this elegantly distinguishes Control Center / Notification Center (`inactive` only, never `paused` → no relock) from true backgrounding (`paused` → relock).

3. **The KDF is the only brute-force defense and the PIN slot is greenfield.** `StorageKeys.pinHash` is defined but **written/read by zero production code today** (only its own unit test) — so there is **no legacy SHA-256 hash to migrate**; the planner stores the salted-slow-hash format from day one. Given D-06 (zero rate-limiting) and a 4-digit PIN (10,000 combinations, no wipe, no recovery), the KDF cost is the *entire* offline-attack defense — recommend **Argon2id m=19456 KiB, t=2, p=1, 32-byte output** (OWASP minimum), run inside `Isolate.run`, with a **device-measured calibration check** in plan verification to confirm 250–500 ms on a mid-range target.

**Primary recommendation:** Rewrite `BiometricService` error handling for `local_auth` 3.x `LocalAuthException` so every code maps to a PIN-fallback AuthResult; add a root lifecycle observer with `_authInProgress` + `_didPause` guards; store the PIN as Argon2id(19456,2,1,32) in a PHC-style encoded string in `pinHash` (salt travels with hash); insert the lock as a `setState`-flag boot-gate branch (never `pushReplacement`).

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| PIN KDF derivation/verify | `lib/infrastructure/security/` (crypto-adjacent) | — | Technology capability; pure-Dart, no business rule. Sits beside `BiometricService`/`SecureStorageService`. |
| Biometric auth + error classification | `lib/infrastructure/security/biometric_service.dart` | — | Platform capability wrapper; already there. |
| PIN storage (salted hash) | `lib/infrastructure/security/secure_storage_service.dart` | — | Keychain/Keystore wrapper; `pinHash` slot exists. |
| "Lock effective" predicate / lock state | `lib/application/security/` (use case) or a Riverpod Notifier | presentation provider | Global business rule combining settings + pinHash presence (D-01). |
| Lifecycle relock + privacy mask | `lib/main.dart` root + a root observer | `lib/infrastructure/.../lifecycle` | Boot-time concern; mirrors `SyncLifecycleObserver`; gate is a boot-time widget (CONTEXT). |
| Lock screen UI (Face ID page + PIN page) | `lib/features/applock/presentation/` (new feature, thin) | — | UI only; domain/presentation per Thin Feature rule. |
| Settings toggles + set/change-PIN flow | `lib/features/settings/presentation/` | `lib/data/repositories/settings_repository_impl.dart` | Presentation + plaintext-prefs persistence (D-02/D-11). |
| `appLockEnabled`/`biometricUnlockEnabled` schema | `lib/features/settings/domain/models/app_settings.dart` | repo impl | Freezed model field; SharedPreferences, no Drift. |

---

## Standard Stack

### Core (all already in `pubspec.yaml` — NO new dependency)

| Library | Resolved Version | Purpose | Why Standard |
|---------|------------------|---------|--------------|
| `cryptography` | **2.9.0** (constraint `^2.7.0`) | Argon2id + PBKDF2 KDF, `constantTimeBytesEquality` | Pure-Dart, isolate-safe (see below). Already a direct dep. `[VERIFIED: pubspec.lock + pub-cache 2.9.0/lib/src/cryptography/algorithms.dart]` |
| `local_auth` | **3.0.1** | Face ID / Touch ID / fingerprint | Flutter-team plugin; already used by `BiometricService`. `[VERIFIED: pubspec.lock]` |
| `flutter_secure_storage` | **10.2.0** | iOS Keychain / Android Keystore for `pinHash` | Already used; **accessibility `unlocked_this_device` MUST NOT change** (brick risk 260610-ss7). `[VERIFIED: secure_storage_service.dart + providers.dart]` |
| `shared_preferences` | **2.5.5** | `appLockEnabled` / `biometricUnlockEnabled` (plaintext, no migration) | Existing settings persistence pattern (D-02). `[VERIFIED: pubspec.lock + settings_repository_impl.dart]` |
| `freezed` | (existing) | `AppSettings` new fields + `AuthResult` new variants | Existing immutability pattern; run build_runner after edits. |

### Supporting (already present)

| Symbol | Location | Purpose |
|--------|----------|---------|
| `BiometricService` | `lib/infrastructure/security/biometric_service.dart` | authenticate + availability; **error handler must be rewritten (see §3)** |
| `AuthResult` (sealed) | `lib/infrastructure/security/models/auth_result.dart` | result union; add/repurpose variants for the new classification |
| `SecureStorageService` | `lib/infrastructure/security/secure_storage_service.dart` | `getPinHash`/`setPinHash`/`deletePinHash`; maybe add `pinSalt` key — but PHC encoding avoids it (§1) |
| `biometricServiceProvider` / `biometricAvailabilityProvider` / `secureStorageServiceProvider` | `lib/infrastructure/security/providers.dart` | DI; reuse |
| `SyncLifecycleObserver` | `lib/infrastructure/sync/sync_lifecycle_observer.dart` | observer pattern to mirror for the lock |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Argon2id | PBKDF2-HMAC-SHA256 (`Pbkdf2.hmacSha256`) | PBKDF2 is GPU-cheap (no memory-hardness). Only acceptable fallback if pure-Dart Argon2id measures too slow on min-spec. If used: **≥600,000 iterations** (OWASP 2023), not the LOCK-07 floor of 100k. `[CITED: OWASP Password Storage Cheat Sheet]` |
| `Isolate.run` | `compute()` | Equivalent; `Isolate.run` (Dart 2.19+) is the modern, less-boilerplate form. Either is fine. |
| Hand-rolled overlay mask | `secure_application` pkg | Project's "no unnecessary deps" stance + the pkg adds its own lifecycle observer that would race ours. Hand-roll (§5). |

**Installation:** none — all dependencies present.

**Version verification performed:** `cryptography` resolves to **2.9.0** (not 2.7.0 — the `^2.7.0` constraint floated up); `local_auth` **3.0.1**; both inspected directly in `~/.pub-cache`. `cryptography_flutter` / `flutter_cryptography` are **NOT** in the dependency tree → `Cryptography.instance` defaults to pure-Dart `DartCryptography` → KDF is isolate-safe. `[VERIFIED: grep pubspec.yaml/lock + pub-cache source]`

---

## Package Legitimacy Audit

> All packages are pre-existing direct dependencies already shipping in production. No new package is introduced by this phase. Per-package registry verification was done against the resolved lock versions in `~/.pub-cache`.

| Package | Registry | Status | Source Repo | Verdict | Disposition |
|---------|----------|--------|-------------|---------|-------------|
| `cryptography` 2.9.0 | pub.dev | existing direct dep | github.com/dint-dev/cryptography | OK | Approved (reuse) |
| `local_auth` 3.0.1 | pub.dev | existing direct dep (Flutter team) | github.com/flutter/packages | OK | Approved (reuse) |
| `flutter_secure_storage` 10.2.0 | pub.dev | existing direct dep | github.com/juliansteenbakker/flutter_secure_storage | OK | Approved (reuse; accessibility locked) |
| `shared_preferences` 2.5.5 | pub.dev | existing direct dep (Flutter team) | github.com/flutter/packages | OK | Approved (reuse) |

**Packages removed due to SLOP verdict:** none.
**Packages flagged SUS:** none.

---

## 1. Off-isolate KDF — concrete params, exact API, isolate-safety, storage

### Decision: Argon2id, m=19456 KiB, t=2, p=1, 32-byte output

| Param | Value | Rationale |
|-------|-------|-----------|
| algorithm | **Argon2id** | Memory-hard; resists GPU/ASIC brute force far better than PBKDF2. The *only* defense given D-06 zero rate-limit + 4-digit PIN. `[CITED: OWASP Password Storage Cheat Sheet — Argon2id is first choice]` |
| `memory` | **19456** (KiB = 19 MiB) | OWASP documented minimum `m=19456,t=2,p=1`. Memory cost is what kills parallel attacks. `[CITED: OWASP]` |
| `iterations` | **2** | OWASP minimum at 19 MiB. Bump to 3 if device calibration shows < 250 ms. |
| `parallelism` | **1** | `DartArgon2id` with `parallelism>1` **spawns its own internal isolates** (`maxIsolates`/`minBlocksPerSliceForEachIsolate` fields). Running that *inside* our `Isolate.run` nests isolate spawning needlessly. p=1 keeps it single-threaded and OWASP-acceptable. `[VERIFIED: pub-cache 2.9.0/lib/src/dart/argon2.dart:45 DartArgon2id]` |
| `hashLength` | **32** bytes | 256-bit output; standard. |
| salt | **16 bytes** from `Random.secure()` | CSPRNG, per-PIN unique. |

**Target latency:** 250–500 ms on a 2026 mid-range device. Because this is **pure-Dart** Argon2id (no native `cryptography_flutter`), it is slower than a native impl — the plan **must include an on-device calibration measurement** (a verification step that times one derivation and asserts 150 ms ≤ t ≤ 800 ms; if < 150 ms bump iterations, if > 800 ms drop to m=12288/t=3 or the PBKDF2 fallback). Do not ship un-measured params. `[ASSUMED: pure-Dart timing — verify on device]`

### Isolate-safety: CONFIRMED pure-Dart

`Cryptography.instance` resolves to `DartCryptography` (pure Dart) because neither `cryptography_flutter` nor `flutter_cryptography` is in the dependency tree. `Argon2id(...)` and `Pbkdf2(...)` factories delegate to `Cryptography.instance.argon2id(...)` / `.pbkdf2(...)` → pure-Dart implementations that use **no `MethodChannel`** (only `dart:typed_data` + optional `dart:ffi` for memory). Therefore they are **safe to construct and run inside `Isolate.run` / `compute()`** — a background isolate has a working `DartCryptography` with no `BackgroundIsolateBinaryMessenger` setup required. `[VERIFIED: pub-cache — no cryptography_flutter dep; DartArgon2id is pure Dart]`

### Exact API (cryptography 2.9.0)

```dart
// Source: pub-cache cryptography-2.9.0/lib/src/cryptography/algorithms.dart:502
// Run the WHOLE thing inside Isolate.run so the main isolate never blocks.
import 'dart:isolate';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart'; // constantTimeBytesEquality

// Top-level (isolate-sendable) args + function.
class _PinKdfArgs {
  const _PinKdfArgs(this.pin, this.salt);
  final String pin;
  final List<int> salt;
}

Future<List<int>> _deriveArgon2id(_PinKdfArgs a) async {
  final algorithm = Argon2id(
    parallelism: 1,
    memory: 19456,   // KiB
    iterations: 2,
    hashLength: 32,
  );
  final secret = await algorithm.deriveKey(
    secretKey: SecretKey(utf8.encode(a.pin)),
    nonce: a.salt, // salt
  );
  return secret.extractBytes(); // Future<List<int>>
}

// Caller (main isolate stays responsive):
final salt = List<int>.generate(16, (_) => Random.secure().nextInt(256));
final hash = await Isolate.run(() => _deriveArgon2id(_PinKdfArgs(pin, salt)));
```

`Argon2id.deriveKey` signature (verified): `Future<SecretKey> deriveKey({required SecretKey secretKey, required List<int> nonce, List<int> optionalSecret, List<int> associatedData})`. `SecretKeyData.extractBytes()` → `Future<List<int>>`. `[VERIFIED: pub-cache algorithms.dart:550 + secret_key.dart:71]`

### Constant-time comparison

Use the package-provided constant-time equality — **never `==` on the hash bytes**:

```dart
// Source: pub-cache cryptography-2.9.0/lib/src/helpers/constant_time_equality.dart
// Exported via: package:cryptography/helpers.dart
import 'package:cryptography/helpers.dart';

final ok = constantTimeBytesEquality.equals(candidateHash, storedHash);
```

`constantTimeBytesEquality` is a `const Equality<List<int>>` that XOR-accumulates over the full length (only short-circuits on null/length mismatch — both non-secret). `[VERIFIED: pub-cache helpers.dart export + constant_time_equality.dart]`

### Salt generation & storage — PHC-style encoded string in `pinHash` (recommended)

**Recommendation:** do **not** add a separate `pinSalt` StorageKey (two keys can desync). Instead store a single self-describing PHC-style string in the existing `pinHash` slot so params + salt + hash travel together and future param migration is detectable:

```
argon2id$v=19$m=19456,t=2,p=1$<base64(salt)>$<base64(hash)>
```

Write via existing `SecureStorageService.setPinHash(encoded)`; read via `getPinHash()`; verify by re-deriving with the parsed salt+params and `constantTimeBytesEquality`. Keychain accessibility stays `unlocked_this_device`. If the planner prefers two keys, add `StorageKeys.pinSalt` to `allKeys` — but the single-string approach is preferred and needs **zero** `StorageKeys` change. `[VERIFIED: secure_storage_service.dart get/set/deletePinHash]`

### Migration: NONE needed (greenfield slot)

`StorageKeys.pinHash` is **referenced by zero production code** today — only `secure_storage_service.dart` (definition) and `secure_storage_service_test.dart`. No PIN-set/verify flow exists yet; the slot has never been populated on any install. **There is no legacy SHA-256 hash in the wild to migrate.** On a fresh lock setup `pinHash` is always null; the new salted-slow-hash format is written from the first set-PIN. The "SHA-256" comment on `StorageKeys.pinHash` is purely aspirational/legacy text — update it to reflect Argon2id PHC encoding. `[VERIFIED: grep -rln setPinHash/getPinHash/StorageKeys.pinHash lib/ test/ → only service + its test]`

---

## 2. iOS lifecycle landmine — biometric prompt vs relock loop

### Observed lifecycle sequences (modern iOS; Android noted)

| Event | iOS `AppLifecycleState` sequence | Android | Relock? | Mask? |
|-------|----------------------------------|---------|---------|-------|
| (a) System Face ID / Touch ID prompt shown | active → **inactive** (sheet up) → **resumed** (on dismiss) | biometric prompt → app may go **inactive**/paused briefly | **NO** (it's our own auth) | mask harmlessly behind sheet; ignore for relock |
| (b) Control Center / Notification Center pulled down | active → **inactive** → **resumed** (no `paused`) | n/a (different shade behavior) | **NO** | **YES** while inactive |
| (c) Genuine background + return (home / app-switcher) | active → inactive → **paused** → (return) inactive → **resumed** | onPause → onResume | **YES** | **YES** during inactive snapshot |

The danger D-09 creates: auto-triggering Face ID on entering the lock screen makes the app go `inactive` (case a). Without a guard, the `inactive` handler shows the mask and the subsequent `resumed` re-runs the relock/auto-auth path → flicker or **infinite re-auth loop**.

### Prescribed guard pattern (two flags)

```dart
class AppLockLifecycleObserver with WidgetsBindingObserver {
  bool _authInProgress = false; // true around BiometricService.authenticate()
  bool _didPause = false;       // app actually hit AppLifecycleState.paused

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // Show opaque mask whenever lock is effective. Safe even behind the
        // Face ID sheet. Does NOT cause loops (mask is a paint-only overlay).
        if (_lockEffective) _showMask();
      case AppLifecycleState.paused:
        if (!_authInProgress) _didPause = true; // real backgrounding only
      case AppLifecycleState.resumed:
        _hideMask();
        // Relock ONLY if we truly backgrounded AND this resume isn't the
        // biometric sheet returning. Control Center (case b) never sets
        // _didPause → no relock. The Face ID sheet (case a) is fenced by
        // _authInProgress → no relock.
        if (_didPause && !_authInProgress && _lockEffective) {
          _relock(); // flip isLocked=true → gate shows lock screen
        }
        _didPause = false;
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        break;
    }
  }
}
```

And around the biometric call:

```dart
Future<AuthResult> _runBiometric() async {
  _authInProgress = true;
  try {
    return await biometricService.authenticate(reason: ...);
  } finally {
    _authInProgress = false; // cleared even on throw
  }
}
```

**Why `_didPause` is the elegant discriminator:** LOCK-03 requires relock on `paused`→`resumed` and explicitly NOT on `inactive`. Control Center / Notification Center only ever produce `inactive`→`resumed` (no `paused`), so gating relock on "did we see `paused`?" gives exactly the locked behavior with no heuristics. `[VERIFIED: matches CONTEXT D-09 + LOCK-03/04; existing SyncLifecycleObserver only handles resumed/paused — extend, don't reuse verbatim]`

**`persistAcrossBackgrounding: true`** (already set in `BiometricService.authenticate`) maps to platform `stickyAuth: true` in local_auth 3.x — the plugin auto-retries auth on foregrounding instead of erroring when the app is backgrounded mid-prompt. Keep it; it reduces spurious `systemCanceled` during the auth sheet. `[VERIFIED: pub-cache local_auth-3.0.1/lib/src/local_auth.dart:57-63 — persistAcrossBackgrounding → stickyAuth]`

**Android note:** the BiometricPrompt also drives `inactive`/`paused` transitions; the same `_authInProgress` fence applies. Android additionally may return `systemCanceled` if backgrounded mid-prompt — handled by the §3 classification (→ PIN fallback, not a dead end).

---

## 3. `local_auth` 3.0.1 complete error classification — ⚠ BREAKING: not `PlatformException`

### CRITICAL finding: the existing handler is dead against local_auth 3.x

`local_auth` **3.0.0** replaced the old `PlatformException`(string-code) error model with a typed **`LocalAuthException`** carrying a **`LocalAuthExceptionCode` enum**. The iOS impl (`local_auth_darwin-2.0.3`) throws `LocalAuthException(code: LocalAuthExceptionCode.…)`. `[VERIFIED: pub-cache local_auth_platform_interface-1.1.0/lib/types/auth_exception.dart + local_auth_darwin-2.0.3/lib/local_auth_darwin.dart:52-84]`

The existing code:

```dart
// lib/infrastructure/security/biometric_service.dart:111
} on PlatformException catch (e) {        // ← 3.x NEVER throws this for auth errors
  return _handlePlatformException(e);      // switch on 'LockedOut' / 'NotEnrolled' strings
}
```

Against local_auth 3.0.1 this `catch` **never matches** — the thrown `LocalAuthException` escapes, propagates uncaught, and the user is dropped out of the app instead of falling back to PIN. **This directly violates LOCK-10 and is the highest-priority fix in the phase.** The `error_codes.dart` string constants (`'LockedOut'`, `'NotEnrolled'`, …) shipped in `local_auth` **2.3.0** are gone from the 3.0.1 public surface. `[VERIFIED: local_auth-3.0.1/lib has no error_codes.dart; only 2.3.0 does]`

### Complete `LocalAuthExceptionCode` enum (verified, exhaustive as of 1.1.0)

| `LocalAuthExceptionCode` | Meaning | Map to AuthResult → UI action |
|--------------------------|---------|-------------------------------|
| `authInProgress` | Auth already running | ignore / `fallbackToPIN` (don't double-fire) |
| `uiUnavailable` | No Activity/UI to show prompt | `fallbackToPIN` |
| `userCanceled` | User dismissed prompt | `fallbackToPIN` (stay on Face ID page per D-09; user taps パスコードを使用) |
| `timeout` | Device-specific timeout | `fallbackToPIN` |
| `systemCanceled` | System event (e.g. backgrounded mid-auth) | `fallbackToPIN` (guarded by `_authInProgress`; re-arm or PIN) |
| `noCredentialsSet` | No biometrics **and** no device passcode | `fallbackToPIN` |
| `noBiometricsEnrolled` | Capable but none enrolled | `fallbackToPIN` |
| `noBiometricHardware` | No biometric hardware | `fallbackToPIN` |
| `biometricHardwareTemporarilyUnavailable` | Hardware busy/unpaired | `fallbackToPIN` |
| `temporaryLockout` | Too many fails, retry later (was `LockedOut`) | `fallbackToPIN` (**not** a dead `lockedOut()`) |
| `biometricLockout` | Locked until other auth succeeds (was `PermanentlyLockedOut`) | `fallbackToPIN` — PIN is exactly the "other auth" |
| `userRequestedFallback` | User chose system fallback affordance | `fallbackToPIN` |
| `deviceError` | Device-level error | `fallbackToPIN` |
| `unknownError` | Unknown/unexpected | `fallbackToPIN` |

> The enum doc explicitly says new values are **not** a breaking change and clients **must** include a `default`/fallback. So the handler **must** have a wildcard `_ => fallbackToPIN`. Per LOCK-10, **every** code — including the two lockout codes the current code routes to a dead-end `lockedOut()` — surfaces as "go to PIN page". `[VERIFIED: auth_exception.dart enum + doc comment]`

### Required changes

1. **Catch `LocalAuthException`, not `PlatformException`.** Add `import 'package:local_auth/error_codes.dart';`? No — that file is gone in 3.x. Import the exception type from `local_auth` (re-exported) and switch on `e.code` (the enum).
2. **Repurpose `AuthResult`:** the lockout codes must no longer terminate at `AuthResult.lockedOut()` as a UI dead-end. Simplest: in the lock-screen controller, treat `lockedOut`, `tooManyAttempts`, `error`, **and** `fallbackToPIN` identically → **show PIN page**. The cleanest refactor is to collapse all non-success biometric outcomes to a single "biometric unavailable/failed → offer PIN" path. Keep `AuthResult` variants for telemetry if desired, but the **UI mapping for all of them is PIN fallback**.
3. Keep a defensive `on PlatformException` AND `catch (e)` wildcard too (belt-and-suspenders → `fallbackToPIN`) so an unexpected throw type can never lock the user out.

`AuthResult` variants today: `success`, `failed(failedAttempts)`, `fallbackToPIN`, `tooManyAttempts`, `lockedOut`, `error(message)`. `[VERIFIED: auth_result.dart]` The `_failedAttempts` counter + `maxFailedAttempts=3` + `tooManyAttempts()` in `BiometricService` is **biometric-attempt** counting (OS-level), distinct from PIN-attempt counting — it does **not** conflict with D-06 (which descopes *PIN* cooldown). Leave the biometric counter as-is; it just forces the PIN page sooner, which is the desired behavior.

---

## 4. Boot-gate + relock wiring

### Gate ladder insertion (in `_buildHome()`)

Current ladder (verified `lib/main.dart:259-279`): `error → !_initialized spinner → _needsOnboarding → MainShellScreen`. Insert the lock branch **after onboarding, before the shell**:

```dart
Widget _buildHome(BuildContext context) {
  if (_error != null) return _errorScaffold;
  if (!_initialized) return _spinner;
  if (_needsOnboarding) return OnboardingFlowScreen(...);
  if (_isLocked) {                       // ← NEW branch
    return AppLockScreen(
      onUnlocked: _completeUnlock,        // gate-owned callback, NOT pushReplacement
    );
  }
  return MainShellScreen(bookId: _bookId!);
}
```

### Honor [[boot-gate-completion-must-flip-flag-not-pushreplacement]]

Unlock completes by flipping a `setState` flag — **never** `_rootNavigatorKey.currentState.pushReplacement`. `pushReplacement` would detach `_buildHome` from the live `'/'` Builder and break the `_reinitializeAfterDataReset` path (the same HI-01/D-05 lesson Phase 54 hit with onboarding):

```dart
void _completeUnlock() => setState(() => _isLocked = false);
```

This mirrors `_completeOnboarding({required bool setupSecurity})` exactly (`lib/main.dart:286`). `[VERIFIED: main.dart:286-298 + MEMORY boot-gate-completion-must-flip-flag-not-pushreplacement]`

### Where `_isLocked` lives + how it's initialized

**Recommendation:** keep `_isLocked` as a `main.dart` `_HomePocketAppState` field (sibling of `_needsOnboarding`/`_initialized`), set during `_initialize()`:

```dart
// In _initialize() after reading settings, compute lockEffective:
final pinHash = await secureStorage.getPinHash();
_isLocked = settings.appLockEnabled && pinHash != null; // cold-start relock (LOCK-02)
```

Rationale: the gate ladder is already `setState`-flag driven in this exact widget; adding `_isLocked` is symmetric, keeps the gate attached for `_reinitializeAfterDataReset`, and avoids a provider that would need `ref.watch` in `build()` (the loading-null race the onboarding gate explicitly avoided). The root observer flips `_isLocked = true` on relock (case c above) via a callback into the State (e.g. the observer holds a `void Function() onRelock` that calls `setState(() => _isLocked = true)`), mirroring how `SyncLifecycleObserver` takes callbacks. A Riverpod Notifier is viable but adds the watch-in-build race risk for no benefit here. `[VERIFIED: main.dart gate pattern + CLAUDE.md Riverpod-3 watch/listen rule]`

### Observer lifecycle

Register the `AppLockLifecycleObserver` once (in `initState`/after init, like `syncEngine.initialize()` registers `SyncLifecycleObserver`), `removeObserver` on dispose. It needs read access to `_lockEffective` (settings + pinHash) and the `onRelock`/`onMask`/`onUnmask` callbacks into `_HomePocketAppState`. `[VERIFIED: sync_lifecycle_observer.dart start()/dispose() pattern]`

---

## 5. Privacy mask mechanics

**D-07:** opaque, theme-following brand cover; **NOT blur** (blur can leak账目 in some snapshot timings); only when lock enabled.

### Recommended: hand-rolled `OverlayEntry` / top-level `Stack` overlay

- Place an opaque `Container` (solid `palette.background` / `palette.card` + centered logo) above the entire app. Two viable placements:
  1. A top-level `Stack` in the `MaterialApp.builder` (wraps `child` with a conditional opaque layer driven by a `ValueNotifier<bool> _maskVisible`). This guarantees it paints above all routes including dialogs.
  2. An `OverlayEntry` inserted into the root `Overlay` on `inactive`, removed on `resumed`.
- Drive visibility from the lifecycle observer: show on `inactive` when `_lockEffective`, hide on `resumed`. Use a `ValueListenableBuilder` so toggling does not rebuild the whole app.

**Snapshot-timing caveat (the real risk):** iOS takes the app-switcher snapshot at/around the `inactive`→background transition. Flutter must have **painted** the opaque overlay *before* the snapshot. Setting the flag in the `inactive` handler and using a synchronous `ValueNotifier` flip (not a provider round-trip) maximizes the chance the next frame paints the mask before the OS snapshot. This is **inherently timing-sensitive and cannot be 100% guaranteed from Dart** — it is one of the **manual on-device QA** items (verify the app-switcher card shows the brand cover, not账目). On iOS, the `flutter_secure_storage`/Flutter community pattern of an `inactive`-driven opaque overlay is the standard hand-rolled approach. `[ASSUMED: snapshot paint-ordering — requires device QA]`

**Tradeoff vs `secure_application` package:** that package bundles its own `WidgetsBindingObserver` and `SecureGate`, which would race/duplicate our observer and pull in a dependency contrary to the project stance. Hand-roll. If the device QA shows a paint-timing leak, the fallback is the iOS-native approach (a `UIImageView`/blur added in `SceneDelegate applicationWillResignActive` on the platform side) — but try the Dart overlay first. `[VERIFIED: project "no unnecessary deps" stance in CLAUDE.md + Out of Scope table]`

---

## 6. Settings data model & re-auth

### New `AppSettings` fields (Freezed; SharedPreferences; NO Drift migration; schemaVersion stays 22)

```dart
// lib/features/settings/domain/models/app_settings.dart
const factory AppSettings({
  ...,
  @Default(false) bool appLockEnabled,          // D-01 master, default OFF
  @Default(false) bool biometricUnlockEnabled,  // D-01 sub-toggle
  // biometricLockEnabled retained but RETIRED (D-02) — see below
}) = _AppSettings;
```

Repo impl (`settings_repository_impl.dart`) adds two keys + getters/setters mirroring `_biometricLockKey`:

```dart
static const String _appLockEnabledKey = 'app_lock_enabled';
static const String _biometricUnlockKey = 'biometric_unlock_enabled';
// getSettings(): appLockEnabled: _prefs.getBool(_appLockEnabledKey) ?? false,
//                biometricUnlockEnabled: _prefs.getBool(_biometricUnlockKey) ?? false,
// + setAppLockEnabled(bool) / setBiometricUnlockEnabled(bool)
```

After editing the Freezed model **run `build_runner`** (`app_settings.freezed.dart` + `.g.dart`). `schemaVersion` is **untouched** (SharedPreferences, not Drift). `[VERIFIED: settings_repository_impl.dart pattern + CLAUDE.md/MEMORY settings-persisted-via-sharedprefs-not-drift, schema=22]`

### D-02 retirement of `biometricLockEnabled`

- It has default `true`, is persisted, but is **read by nobody at startup** and has **no lock effect** today (confirmed: only `security_section.dart` writes it and `onboarding_lock_entry_screen.dart` sets it false on skip). `[VERIFIED: grep setBiometricLock/biometricLockEnabled]`
- Planner must repoint Phase 54's `onboarding_lock_entry_screen.dart:47` `setBiometricLock(false)` → `setAppLockEnabled(false)` (the "skip = lock off" semantic moves to the new master). Keep the legacy field/setter to avoid breaking the model + its tests, but ensure the new lock **never** reads `biometricLockEnabled`. Optionally one-time normalize it to false. `[VERIFIED: onboarding_lock_entry_screen.dart:47]`

### "Lock effective" predicate (single source of truth)

`lockEffective = appLockEnabled && (pinHash != null)`. Used by: cold-start gate (`_isLocked` init), the lifecycle observer (mask + relock), and the Settings UI. Centralize it (a small use case or provider) so the three call sites can't diverge. `[VERIFIED: D-01]`

### `SecuritySection` refactor (D-11)

Replace the current `biometricLock` `SwitchListTile` with:
1. **App-lock master `SwitchListTile`** → ON triggers set-PIN double-entry flow (D-03); only persists `appLockEnabled=true` **after** a PIN is successfully set (else revert toggle — never enable lock without a PIN, D-01/LOCK-06). OFF requires **re-auth** first (D-05) → then `setAppLockEnabled(false)` + `deletePinHash()`.
2. When enabled, expand sub-items: **「生物识别解锁」** sub-toggle (`biometricUnlockEnabled`, gated by `biometricAvailabilityProvider`) + **「修改 PIN」** entry → re-auth (D-05) → set-PIN double-entry.
3. Keep the existing `notifications` `SwitchListTile` unchanged. `[VERIFIED: security_section.dart current shape]`

### Re-auth before disable/change (D-05)

A reusable "re-authenticate" step: try biometric (if `biometricUnlockEnabled` && available) → on any failure, require current PIN entry (verified via the same KDF compare). Only on success proceed to disable / change. Prevents someone with an already-unlocked phone from silently turning off the lock or changing the PIN. `[VERIFIED: D-05]`

### Deep-link (D-10)

Phase 54 "现在设置" already deep-links to `SettingsScreen(scrollToSecurity: true)` via `_completeOnboarding(setupSecurity: true)` (`main.dart:286`). Phase 55 hooks the security section so that arriving with `scrollToSecurity` **and** lock-not-yet-set immediately opens the set-PIN double-entry flow (reusing 54-03 `jumpTo(maxScrollExtent)` + post-frame `ensureVisible`). `[VERIFIED: main.dart:286-298 + STATE 54-03 scroll note]`

---

## Architecture Patterns

### System Architecture Diagram

```
COLD START                         FOREGROUND RETURN              TASK SWITCHER
   │                                     │                              │
WidgetsFlutterBinding                AppLockLifecycleObserver       inactive
   │                                  .didChangeAppLifecycleState        │
AppInitializer (KeyMgr→DB→…)              │                          _lockEffective?
   │                              paused? → _didPause=true              │ yes
ProviderScope                             │                         _showMask()
   │                              resumed: _didPause && !_authInProgress  (opaque brand cover,
_buildHome() gate ladder:                 │  && _lockEffective              painted before OS snapshot)
  error → spinner → onboarding →     → setState(_isLocked=true)
  ┌─────────────────────────┐             │
  │  _isLocked ?            │◄────────────┘
  │   AppLockScreen        │
  │   ├─ Face ID page (D-09 auto-trigger)
  │   │    _authInProgress=true → BiometricService.authenticate()
  │   │      success → onUnlocked()           [LocalAuthException → classify]
  │   │      any error/cancel → STAY, show 重试 + 「パスコードを使用」
  │   └─ PIN page (9-grid, 4 dots, instant verify D-12)
  │        4 digits → Isolate.run(Argon2id) → constantTimeBytesEquality
  │          match → onUnlocked() → setState(_isLocked=false)
  │          mismatch → shake + clear + haptic (NO cooldown, D-06)
  └─────────────────────────┘
   │ unlocked
MainShellScreen(bookId)   ◄── DB already decrypted; lock is UI gate only
```

### Recommended Project Structure

```
lib/
├── infrastructure/security/
│   ├── pin_kdf.dart                 # NEW: Argon2id derive/verify (Isolate.run), PHC encode/parse, constant-time
│   ├── biometric_service.dart       # REWRITE error handling for LocalAuthException
│   ├── models/auth_result.dart      # (optional) simplify variants; all non-success → PIN
│   └── secure_storage_service.dart  # reuse pinHash slot; update "SHA-256" comment
├── application/security/
│   └── app_lock_service.dart        # NEW: lockEffective predicate, setPin, verifyPin, reauth, disableLock
├── features/applock/presentation/
│   ├── screens/app_lock_screen.dart # Face ID page + PIN page (two surfaces, tone B)
│   ├── widgets/{pin_keypad,pin_dots,face_id_panel,privacy_mask}.dart
│   └── providers/app_lock_providers.dart
├── features/settings/presentation/widgets/security_section.dart  # D-11 refactor
└── main.dart                        # _isLocked gate branch + AppLockLifecycleObserver registration
```

### Anti-Patterns to Avoid
- **Catching `PlatformException` for local_auth 3.x errors** — never matches; user gets locked out (LOCK-10 violation). Catch `LocalAuthException` + enum.
- **`==` on hash bytes** — timing oracle. Use `constantTimeBytesEquality`.
- **Deriving the KDF on the main isolate** — jank/ANR; violates LOCK-07. Use `Isolate.run`.
- **`pushReplacement` to leave the lock screen** — detaches `_buildHome`, breaks data-reset refresh. Use `setState` flag.
- **Relocking on `inactive`** — would relock on every Control Center pull. Gate on `_didPause`.
- **Enabling lock before a PIN exists** — `lockEffective` requires `pinHash != null`; persist `appLockEnabled=true` only after set-PIN succeeds.
- **Storing salt in a second StorageKey that can desync** — prefer PHC-encoded single string in `pinHash`.
- **`Argon2id(parallelism>1)` inside `Isolate.run`** — nests isolate spawning; keep p=1.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Slow password hash | Custom PBKDF/HMAC loop | `cryptography` `Argon2id` / `Pbkdf2` | Memory-hardness, vetted, pure-Dart isolate-safe |
| Constant-time compare | `a == b` or manual loop | `constantTimeBytesEquality` (`package:cryptography/helpers.dart`) | Avoids timing oracle; correct |
| Off-main work | Manual `Isolate.spawn` + ports | `Isolate.run` / `compute` | Less boilerplate, auto-teardown |
| Biometric error taxonomy | Re-derive codes | `LocalAuthExceptionCode` enum | Plugin owns the mapping; new values expected |
| Privacy mask | `secure_application` pkg | Hand-rolled opaque overlay | Avoids dep + duplicate observer race |
| CSPRNG | `Random()` | `Random.secure()` | Cryptographic salt entropy |

**Key insight:** every primitive this phase needs is already in `cryptography`/`local_auth`; the work is *wiring and lifecycle correctness*, not crypto invention.

---

## Common Pitfalls

### Pitfall 1: Silent dead error handler (local_auth 3.x)
**What goes wrong:** Biometric failure throws `LocalAuthException`; the `on PlatformException` catch misses it; the user is ejected instead of seeing the PIN page.
**Why:** local_auth 3.0 changed the exception model; the existing code predates it.
**Avoid:** Catch `LocalAuthException`, switch on `LocalAuthExceptionCode`, wildcard `→ fallbackToPIN`, plus a final `catch (_)` safety net.
**Warning sign:** any biometric error in device QA closes/loops the app instead of offering PIN.

### Pitfall 2: Face-ID-triggered relock loop
**What goes wrong:** Auto Face ID → `inactive`→`resumed` → relock re-arms Face ID → loop / flicker.
**Avoid:** `_authInProgress` fence + `_didPause`-gated relock (§2).
**Warning sign:** lock screen flashes or Face ID re-prompts immediately after dismiss.

### Pitfall 3: Main-isolate KDF jank
**What goes wrong:** Argon2id at 19 MiB on the UI isolate freezes the lock screen / drops the dots animation.
**Avoid:** `Isolate.run`. Measure on device; tune params to 250–500 ms.
**Warning sign:** visible hitch between 4th digit and unlock/shake.

### Pitfall 4: Keychain accessibility change bricks installs
**What goes wrong:** "improving" `unlocked_this_device` → an `AfterFirstUnlock` variant makes existing master-key reads fail → AppInitializer data-loss guard bricks startup.
**Avoid:** Do not touch accessibility (Out of Scope). PIN hash uses the same `unlocked_this_device` options as everything else.
**Warning sign:** init-failure screen on upgrade. `[VERIFIED: providers.dart rationale + MEMORY 260610-ss7]`

### Pitfall 5: Privacy mask paints too late for the snapshot
**What goes wrong:** OS captures the app-switcher card before the opaque overlay paints →账目 leaks.
**Avoid:** Synchronous `ValueNotifier` flip in the `inactive` handler (no async provider hop). QA on device.
**Warning sign:** app-switcher card shows the ledger, not the brand cover.

---

## Runtime State Inventory

> This is an additive feature, not a rename/migration. The one relevant "state" question is the PIN slot.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `StorageKeys.pinHash` defined but **never written/read** by production code (greenfield) | None — write new Argon2id PHC format from first set-PIN; **no migration** |
| Live service config | None | None — purely local |
| OS-registered state | iOS Keychain item under `pinHash` (created on first set-PIN, accessibility `unlocked_this_device`) | None new; reuse existing options |
| Secrets/env vars | New `pinHash` value (salted Argon2id); SharedPreferences `app_lock_enabled`/`biometric_unlock_enabled` (plaintext, non-secret booleans) | Booleans are not secrets; PIN never stored plaintext |
| Build artifacts | `app_settings.freezed.dart`/`.g.dart`, `providers.g.dart`, ARB `app_localizations.dart` regenerate after model/annotation/ARB edits | Run `build_runner` + `gen-l10n`; force-add `lib/generated/` (gitignored-yet-tracked, MEMORY gsd-executor-l10n-generated-uncommitted) |

**Nothing found requiring data migration** — verified by grep: only `secure_storage_service.dart` + its test reference `pinHash`.

---

## Validation Architecture

> `workflow.nyquist_validation` not disabled → section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ existing `test/helpers/test_provider_scope.dart`, `ProviderContainer.test()`, `waitForFirstValue`) |
| Config file | none beyond `flutter_test_config.dart` (golden comparator swap) |
| Quick run command | `flutter test test/infrastructure/security/ test/features/applock/` |
| Full suite command | `flutter test` (must include architecture tests — hardcoded-CJK scan, import_guard) + `flutter analyze` |

### Phase Requirements → Test Map
| Req | Behavior | Test Type | Command | File exists? |
|-----|----------|-----------|---------|-------------|
| LOCK-07 | Argon2id determinism (same pin+salt → same hash) | unit | `flutter test test/infrastructure/security/pin_kdf_test.dart` | ❌ Wave 0 |
| LOCK-07 | Constant-time compare returns true/false correctly; rejects wrong pin | unit | same | ❌ Wave 0 |
| LOCK-07 | PHC encode/parse round-trip; params recoverable | unit | same | ❌ Wave 0 |
| LOCK-07 | KDF runs off main isolate (no `MethodChannel` in isolate) + **device timing calibration 150–800 ms** | unit + manual | unit deterministic; timing = device QA | ❌ Wave 0 |
| LOCK-10 | Every `LocalAuthExceptionCode` (all 14) → PIN fallback, never throws out | unit | `test/infrastructure/security/biometric_service_test.dart` (rewrite for `LocalAuthException`) | ⚠ exists, must rewrite |
| LOCK-01/06 | `lockEffective` predicate: false unless `appLockEnabled && pinHash!=null` | unit | `test/application/security/app_lock_service_test.dart` | ❌ Wave 0 |
| LOCK-01 | Lock off = no-op (gate renders shell, no mask, no relock) | widget | `test/main_gate_test.dart` (extend) | ⚠ extend |
| LOCK-02 | Cold start with lock effective → `AppLockScreen` before shell | widget | same | ❌ Wave 0 |
| LOCK-03 | `paused`→`resumed` sets `_isLocked`; `inactive`→`resumed` (no pause) does NOT | unit (observer) | `test/.../app_lock_lifecycle_observer_test.dart` | ❌ Wave 0 |
| LOCK-04 | Mask shows on `inactive` when effective, hidden on `resumed` | widget | same / mask widget test | ❌ Wave 0 |
| LOCK-05/D-09 | Face ID page → on fail shows 「パスコードを使用」 → tap → PIN page | widget | `test/features/applock/app_lock_screen_test.dart` | ❌ Wave 0 |
| LOCK-06/D-12 | 9-grid entry fills 4 dots → instant verify; wrong → shake+clear (no cooldown) | widget | same | ❌ Wave 0 |
| LOCK-06/D-03 | Set-PIN double-entry: mismatch re-prompts; match persists + enables lock | widget | `test/features/settings/security_section_test.dart` | ⚠ extend |
| LOCK-05 D-05 | Disable lock / change PIN require re-auth | widget | same | ❌ Wave 0 |
| LOCK-09/D-08 | "忘记 PIN?" → explanation copy (no recovery path); ARB ja/zh/en parity | widget + arch scan | `flutter test` (CJK scan) + arb parity | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test test/infrastructure/security/ test/features/applock/ && flutter analyze`
- **Per wave merge:** full `flutter test` (MUST include architecture/CJK/import_guard tests — per MEMORY, scoped tests miss them).
- **Phase gate:** full suite green + `flutter analyze` 0 before `/gsd-verify-work`.

### Manual device QA (cannot be automated)
- Real Face ID/Touch ID prompt lifecycle: no flicker/loop on auto-trigger (§2).
- Task-switcher snapshot shows opaque brand cover, not账目 (§5 timing).
- KDF latency 250–500 ms on a real mid-range device.
- Control Center / Notification Center pull-down does NOT relock; true background does.

### Wave 0 Gaps
- [ ] `test/infrastructure/security/pin_kdf_test.dart` — LOCK-07
- [ ] Rewrite `test/infrastructure/security/biometric_service_test.dart` for `LocalAuthException` — LOCK-10
- [ ] `test/application/security/app_lock_service_test.dart` — lockEffective/setPin/verify/reauth
- [ ] `test/.../app_lock_lifecycle_observer_test.dart` — relock/mask gating
- [ ] `test/features/applock/app_lock_screen_test.dart` — Face ID↔PIN, dots, shake
- [ ] Extend `security_section_test.dart` + main gate test
- [ ] ARB keys ja/zh/en for lock/PIN/forgot-PIN copy (parity + CJK scan)

---

## Security Domain

> `security_enforcement` enabled (absent = enabled). This section carries the **专项安全评审 sign-off**.

### ⚠ Known Accepted Risk Sign-off (D-06 / LOCK-08 descope)

**Risk:** With zero rate-limiting/backoff (D-06), a 4-digit PIN (10,000 combinations), no wipe-after-failures (LOCK-V2-03 deferred), and no recovery path (LOCK-09), an attacker in physical possession of an unlocked-at-rest device who can read the stored `pinHash`+salt can brute-force all 10,000 PINs **offline**. The KDF cost is the **sole** brute-force defense.
**Mitigation in this phase:** Argon2id (memory-hard) at OWASP-minimum params raises per-guess cost; online guessing is bounded only by human speed (no cooldown). Offline, 10,000 × ~300 ms ≈ ~50 min single-thread on-device; memory-hardness limits GPU parallelism but a 4-digit space remains fundamentally weak.
**Decision:** The user was explicitly informed of this implication and **chose zero rate-limiting for the MVP** (CONTEXT D-06). This research **records it as a KNOWN ACCEPTED RISK and signs off** for v2.0, contingent on the three downstream actions below.
**Downstream actions (planner MUST ensure):**
1. REQUIREMENTS.md LOCK-08 rewritten/downgraded → v2 family (suggest `LOCK-V2-04: PIN 连错递增冷却`).
2. ROADMAP Phase 55 SC-4 "递增冷却" sentence annotated **descoped**.
3. The KDF params are device-calibrated (not shipped un-measured) so the per-guess cost is real.

### Applicable ASVS Categories

| ASVS | Applies | Standard Control |
|------|---------|-----------------|
| V2 Authentication | yes | Biometric (`local_auth`) + PIN knowledge factor; lockout codes → PIN fallback |
| V2.4 Credential Storage | yes | Argon2id salted slow-hash (memory-hard), never plaintext, constant-time verify |
| V3 Session Management | partial | Relock on foreground (LOCK-03); immediate relock (grace deferred to v2) |
| V4 Access Control | yes | Gate before main shell; "lock effective" predicate |
| V5 Input Validation | yes | PIN exactly 4 digits, numeric only |
| V6 Cryptography | yes | `cryptography` Argon2id/`constantTimeBytesEquality` — **never hand-rolled**; `Random.secure()` salt |
| V8 Data Protection | yes | Privacy mask on `inactive` (LOCK-04); no账目 in snapshots |

### Known Threat Patterns

| Pattern | STRIDE | Mitigation |
|---------|--------|-----------|
| Offline PIN brute-force | Spoofing | Argon2id memory-hardness (⚠ residual: 4-digit space + no cooldown — accepted, above) |
| Timing side-channel on verify | Information Disclosure | `constantTimeBytesEquality` |
| Snapshot/task-switcher leak | Information Disclosure | Opaque mask on `inactive` (D-07, not blur) |
| Biometric error → user lockout | Denial of Service | Every `LocalAuthExceptionCode` → PIN fallback (LOCK-10) |
| Shoulder-surfed unlocked phone → disable lock/change PIN | Elevation/Tampering | Re-auth before disable/change (D-05) |
| Keychain accessibility brick | Denial of Service | Do not change `unlocked_this_device` (Out of Scope) |
| Lock-screen relock loop | Denial of Service | `_authInProgress` + `_didPause` guards |

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `local_auth` `PlatformException` + string error codes (`error_codes.dart`) | `LocalAuthException` + `LocalAuthExceptionCode` enum | local_auth **3.0.0** | **Existing handler is dead** — rewrite (§3) |
| `stickyAuth` named param | `persistAcrossBackgrounding` (maps to `stickyAuth`) | local_auth 3.x | already used correctly in `BiometricService` |
| PBKDF2 (GPU-cheap) | Argon2id (memory-hard) preferred | OWASP guidance | Use Argon2id; PBKDF2 only as measured fallback at ≥600k iters |
| `compute()` | `Isolate.run` (Dart 2.19+) | Dart 2.19 | cleaner off-main execution |

**Deprecated/outdated:**
- `local_auth/error_codes.dart` string constants — **gone** from 3.x public API (only present in 2.3.0). Do not import.
- `StorageKeys.pinHash` "SHA-256" comment — legacy/aspirational; update to Argon2id PHC.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Pure-Dart Argon2id(19456,2,1) lands ~250–500 ms on a 2026 mid-range device | §1 | If far slower → janky unlock; mitigated by mandated device calibration step (tune down to m=12288/t=3 or PBKDF2 ≥600k) |
| A2 | iOS Face ID prompt drives `active→inactive→resumed` (not always `paused`) on current iOS | §2 | If it sometimes `paused`s, `_authInProgress` still fences relock (it's set around the whole auth call) — guard is robust either way |
| A3 | Dart `ValueNotifier`-flipped opaque overlay paints before the iOS app-switcher snapshot | §5 | If it leaks → fall back to native `SceneDelegate` cover; flagged as device-QA item |
| A4 | `local_auth_darwin`/`_android` surface all failures as `LocalAuthException` (no stray `PlatformException`) | §3 | Mitigated by belt-and-suspenders `catch (_) → fallbackToPIN` wildcard |

**Cited, not assumed:** package versions/APIs (verified in pub-cache), `pinHash` greenfield (grep), gate/observer patterns (source), OWASP Argon2id/PBKDF2 params (OWASP Password Storage Cheat Sheet).

---

## Open Questions (RESOLVED)

> All three were Claude's-discretion technical items; resolved consistently across the plans during planning (Phase 55 plan-checker Dimension 11).

1. **Which `AuthResult` shape after refactor?**
   - Known: all non-success biometric outcomes must route to the PIN page (LOCK-10).
   - Unclear: keep the 6-variant union (for telemetry) vs collapse to `success`/`needsPin`.
   - Recommendation: keep variants, but the lock controller maps every non-`success` to "show PIN" — minimal churn, preserves existing tests' structure.
   - **RESOLVED: keep the 6-variant `AuthResult` union; lock controller maps every non-`success` → PIN page. Implemented in 55-02.**

2. **PHC single-string vs separate `pinSalt` key?**
   - Recommendation: PHC single string in `pinHash` (no `StorageKeys` change, params travel with hash). Planner may choose two keys if it prefers explicitness — then add `pinSalt` to `allKeys`.
   - **RESOLVED: PHC single string in the existing `pinHash` slot (no new `StorageKeys`, no migration). Implemented in 55-01.**

3. **`_isLocked` as State field vs Riverpod Notifier?**
   - Recommendation: State field (symmetric with `_needsOnboarding`, avoids watch-in-build race). Open to a `keepAlive` Notifier if a non-gate consumer needs lock state.
   - **RESOLVED: `_isLocked` as a `main.dart` State field (symmetric with `_needsOnboarding`, avoids watch-in-build race). Implemented in 55-11.**

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `cryptography` | KDF | ✓ | 2.9.0 | — |
| `local_auth` | biometric | ✓ | 3.0.1 | PIN-only (lock still works) |
| `flutter_secure_storage` | pinHash | ✓ | 10.2.0 | — |
| `shared_preferences` | toggles | ✓ | 2.5.5 | — |
| Real iOS/Android device | Face ID lifecycle + snapshot + KDF timing QA | ✓ (project ships on device) | — | simulator cannot validate snapshot/biometric lifecycle fully |

**Missing with no fallback:** none. **Missing with fallback:** none.

---

## Sources

### Primary (HIGH confidence — verified in pub-cache at resolved lock versions)
- `cryptography-2.9.0/lib/src/cryptography/algorithms.dart` — `Argon2id` (502), `Pbkdf2` (1505) signatures
- `cryptography-2.9.0/lib/src/dart/argon2.dart` — `DartArgon2id` pure-Dart + internal isolate fields
- `cryptography-2.9.0/lib/src/helpers/constant_time_equality.dart` + `lib/helpers.dart` export — `constantTimeBytesEquality`
- `local_auth_platform_interface-1.1.0/lib/types/auth_exception.dart` — `LocalAuthException` + full `LocalAuthExceptionCode` enum
- `local_auth_darwin-2.0.3/lib/local_auth_darwin.dart` — iOS throws `LocalAuthException`
- `local_auth-3.0.1/lib/src/local_auth.dart` — `authenticate` signature + `persistAcrossBackgrounding→stickyAuth`
- `lib/infrastructure/security/{biometric_service,secure_storage_service,providers}.dart`, `models/auth_result.dart` — existing signatures
- `lib/main.dart` — `_buildHome` gate ladder + `_completeOnboarding` setState pattern
- `lib/infrastructure/sync/sync_lifecycle_observer.dart` — observer pattern
- `lib/features/settings/...app_settings.dart` + `settings_repository_impl.dart` + `security_section.dart` — settings model
- `pubspec.lock` / `pubspec.yaml` — resolved versions
- grep audit: `pinHash` referenced only by service + its test (greenfield)

### Secondary (MEDIUM — external guidance)
- OWASP Password Storage Cheat Sheet — Argon2id `m=19456,t=2,p=1`; PBKDF2-SHA256 ≥600k

### Tertiary (LOW — to validate on device)
- iOS lifecycle transition exact sequence for Face ID / Control Center; snapshot paint timing; pure-Dart Argon2id latency

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all versions/APIs read from pub-cache source
- Architecture / gate / lifecycle: HIGH — patterns read from project source; guard logic derived from locked decisions
- `local_auth` 3.x error model: HIGH — exception type + enum verified directly
- KDF params: MEDIUM-HIGH — OWASP-cited; on-device latency requires calibration (A1)
- Privacy-mask snapshot timing: MEDIUM — inherently device-dependent (A3)

**Research date:** 2026-06-30
**Valid until:** ~2026-07-30 (stable deps; re-verify only if `local_auth`/`cryptography` bumped — both move fast on major versions)
