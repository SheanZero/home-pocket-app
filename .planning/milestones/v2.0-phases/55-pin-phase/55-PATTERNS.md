# Phase 55: 应用锁（生物识别 + PIN）- Pattern Map

**Mapped:** 2026-06-30
**Files analyzed:** 16 (new + modified)
**Analogs found:** 14 / 16 (2 net-new UI widgets have structural-only analogs)

> Source of file list: 55-CONTEXT.md §既有安全基础设施 (实现锚点) + 55-RESEARCH.md §"Recommended Project Structure". This map points each new/modified file at the closest in-repo analog and quotes the real excerpt to copy. Honor CLAUDE.md Riverpod-3 conventions (provider names strip `Notifier`, `AsyncValue.value` nullable, side-effects via `ref.listen`), Freezed `copyWith`, `context.palette` theming, `S.of(context)` i18n.

---

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `lib/infrastructure/security/pin_kdf.dart` **(NEW)** | utility (crypto) | transform / batch (off-isolate) | `lib/infrastructure/security/secure_storage_service.dart` (sibling, infra-security conventions) | role-match (no existing KDF) |
| `lib/infrastructure/security/biometric_service.dart` **(MODIFY — rewrite error handling)** | service | request-response | itself (self-rewrite; local_auth 3.x `LocalAuthException`) | exact (in-place) |
| `lib/infrastructure/security/models/auth_result.dart` **(MODIFY — optional)** | model | — | itself (Freezed sealed union) | exact |
| `lib/infrastructure/security/secure_storage_service.dart` **(MODIFY — update pinHash comment)** | service | CRUD (keychain) | itself | exact |
| `lib/infrastructure/security/providers.dart` **(MODIFY — add KDF/lock providers)** | provider | — | itself (`@riverpod` wiring) | exact |
| `lib/application/security/app_lock_service.dart` **(NEW)** | service (use case) | request-response | `lib/infrastructure/security/biometric_service.dart` (plain injectable service) | role-match |
| `lib/infrastructure/.../app_lock_lifecycle_observer.dart` **(NEW)** | service (observer) | event-driven | `lib/infrastructure/sync/sync_lifecycle_observer.dart` | exact |
| `lib/features/applock/presentation/screens/app_lock_screen.dart` **(NEW)** | component (screen) | event-driven | `lib/features/onboarding/.../onboarding_lock_entry_screen.dart` (ConsumerStatefulWidget + palette + S) | role-match (structure) |
| `lib/features/applock/presentation/widgets/pin_keypad.dart` **(NEW)** | component | event-driven | onboarding `_OnboardingGradientButton` (palette/theming idiom) | partial (structure only) |
| `lib/features/applock/presentation/widgets/pin_dots.dart` **(NEW)** | component | — | same | partial (structure only) |
| `lib/features/applock/presentation/widgets/face_id_panel.dart` **(NEW)** | component | event-driven | `onboarding_lock_entry_screen.dart` (centered card + gradient button) | role-match (structure) |
| `lib/features/applock/presentation/widgets/privacy_mask.dart` **(NEW)** | component | — | `onboarding_lock_entry_screen.dart` (opaque `palette.background` Scaffold) | partial (structure only) |
| `lib/features/applock/presentation/providers/app_lock_providers.dart` **(NEW)** | provider | — | `lib/infrastructure/security/providers.dart` | exact |
| `lib/features/settings/.../security_section.dart` **(MODIFY — D-11)** | component | CRUD | itself (SwitchListTile + repo write + invalidate) | exact |
| `lib/features/settings/domain/models/app_settings.dart` **(MODIFY — 2 fields)** | model | — | itself (Freezed `@Default`) | exact |
| `lib/data/repositories/settings_repository_impl.dart` **(MODIFY — 2 keys)** | repository | CRUD (prefs) | itself (`_biometricLockKey` get/set idiom) | exact |
| `lib/features/onboarding/.../onboarding_lock_entry_screen.dart` **(MODIFY — D-02)** | component | CRUD | itself (`setBiometricLock(false)` → `setAppLockEnabled(false)`) | exact |
| ARB: `lib/l10n/app_{ja,zh,en}.arb` **(MODIFY — new lock keys)** | config (i18n) | — | existing `onboardingLock*` keys | exact |

---

## Pattern Assignments

### `app_lock_lifecycle_observer.dart` (NEW — service, event-driven)

**Analog:** `lib/infrastructure/sync/sync_lifecycle_observer.dart` (the WHOLE file — 50 lines, callback-driven `WidgetsBindingObserver`).

**Registration / dispose pattern to mirror** (`sync_lifecycle_observer.dart:12-48`):
```dart
class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({required SyncResumeCallback onResume, SyncPausedCallback? onPaused})
      : _onResume = onResume, _onPaused = onPaused;
  bool _isActive = false;
  void start() {
    if (_isActive) return;
    WidgetsBinding.instance.addObserver(this);
    _isActive = true;
  }
  void dispose() {
    if (!_isActive) return;
    WidgetsBinding.instance.removeObserver(this);
    _isActive = false;
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { ... }
}
```

**EXTEND, do not reuse verbatim.** The sync observer only handles `resumed`/`paused`. The lock observer needs the RESEARCH §2 two-flag guard (`_authInProgress` + `_didPause`) and a third `inactive` branch for the mask. Take constructor-callback shape (`onRelock`/`onMask`/`onUnmask`) from this analog; take the switch body from RESEARCH §2 (55-RESEARCH.md lines 242-289). Register it in `main.dart._initialize()` exactly where `syncEngine.initialize()` registers its observer (`main.dart:144-146`), `removeObserver` on State dispose.

---

### `pin_kdf.dart` (NEW — utility, transform/off-isolate)

**Analog (conventions only):** `secure_storage_service.dart` (infra-security file style — top-level doc, no class mutation). No existing KDF analog; the concrete API is in RESEARCH §1 (55-RESEARCH.md lines 162-220).

**Copy directly from RESEARCH §1** (verified `cryptography` 2.9.0 API): Argon2id `parallelism:1, memory:19456, iterations:2, hashLength:32`, run the whole derive inside `Isolate.run`, salt = `List<int>.generate(16, (_) => Random.secure().nextInt(256))`, compare with `constantTimeBytesEquality.equals(...)` from `package:cryptography/helpers.dart`, store PHC string `argon2id$v=19$m=19456,t=2,p=1$<b64salt>$<b64hash>` in the existing `pinHash` slot. NEVER `==` on bytes. NEVER derive on main isolate. Plan must add an on-device timing calibration (150–800 ms) verification step.

---

### `biometric_service.dart` (MODIFY — service; ⚠ HIGHEST-PRIORITY FIX)

**Analog:** itself. The current handler is **DEAD against local_auth 3.x** (RESEARCH §3, lines 297-339).

**Current (broken) code to replace** (`biometric_service.dart:111-134`):
```dart
} on PlatformException catch (e) {        // ← 3.x NEVER throws this for auth errors
  return _handlePlatformException(e);
}
...
AuthResult _handlePlatformException(PlatformException e) {
  switch (e.code) {
    case 'LockedOut':
    case 'PermanentlyLockedOut':
      return const AuthResult.lockedOut();   // ← dead-end; violates LOCK-10
    case 'NotAvailable':
    case 'NotEnrolled':
      return const AuthResult.fallbackToPIN();
    default:
      return AuthResult.error(message: e.message ?? 'Unknown biometric error');
  }
}
```

**Rewrite to:** `catch` `LocalAuthException`, switch on `LocalAuthExceptionCode` enum, **every** code (all 14 in RESEARCH §3 table, lines 314-329) → `fallbackToPIN`, with a wildcard `_ => fallbackToPIN` AND a belt-and-suspenders `on PlatformException` + `catch (_)` net also → `fallbackToPIN`. Keep the existing `authenticate()` body (`biometric_service.dart:82-110`) — `persistAcrossBackgrounding: true` is correct (maps to `stickyAuth`). The biometric `_failedAttempts`/`maxFailedAttempts=3` counter (lines 49-52, 92-94) is OS-biometric counting, NOT PIN counting — leave it; it does not conflict with D-06.

---

### `app_lock_service.dart` (NEW — application/security use case)

**Analog:** `biometric_service.dart` (plain constructor-injected service class, no Riverpod inside).

**Responsibilities (RESEARCH §6, lines 439-452):**
- `lockEffective = appLockEnabled && (pinHash != null)` — single source of truth (D-01). Consumed by cold-start gate, observer, Settings UI.
- `setPin` (write Argon2id PHC via `secureStorage.setPinHash`), `verifyPin` (re-derive + `constantTimeBytesEquality`), `reauth` (biometric-if-enabled-else-PIN, D-05), `disableLock` (`setAppLockEnabled(false)` + `deletePinHash()`).

---

### `security_section.dart` (MODIFY — component, D-11)

**Analog:** itself (`security_section.dart:26-47`). Current shape = two `SwitchListTile`s writing repo + `ref.invalidate(appSettingsProvider)`.

**Existing write idiom to reuse** (`security_section.dart:26-35`):
```dart
SwitchListTile(
  secondary: const Icon(Icons.fingerprint),
  title: Text(S.of(context).biometricLock),
  subtitle: Text(S.of(context).biometricLockDescription),
  value: settings.biometricLockEnabled,
  onChanged: (value) async {
    await ref.read(settingsRepositoryProvider).setBiometricLock(value);
    ref.invalidate(appSettingsProvider);
  },
),
```

**Refactor per D-11:** replace the `biometricLock` tile with: (1) app-lock master `SwitchListTile` → ON runs set-PIN double-entry, persist `appLockEnabled=true` ONLY after PIN set (else revert toggle — never enable without PIN, LOCK-06); OFF requires re-auth (D-05) then `setAppLockEnabled(false)` + `deletePinHash()`. (2) When enabled, expand sub-items: 「生物识别解锁」 sub-toggle (`biometricUnlockEnabled`, gated by `biometricAvailabilityProvider`) + 「修改 PIN」 entry → re-auth → set-PIN. (3) Keep the `notifications` tile unchanged (`security_section.dart:36-47`). D-10 deep-link: when arriving with `scrollToSecurity` and lock-not-set, auto-open set-PIN flow.

---

### `app_settings.dart` (MODIFY — model) + `settings_repository_impl.dart` (MODIFY — repository)

**Analog:** both files themselves — exact mirror of `biometricLockEnabled`.

**Model field idiom** (`app_settings.dart:15-24`):
```dart
const factory AppSettings({
  ...
  @Default(true) bool biometricLockEnabled,   // keep (retired, D-02)
  @Default(false) bool appLockEnabled,         // NEW — master, default OFF (D-01)
  @Default(false) bool biometricUnlockEnabled, // NEW — sub-toggle (D-01)
  ...
}) = _AppSettings;
```

**Repo key + getter/setter idiom** (`settings_repository_impl.dart:15`, `27`, `62-64`):
```dart
static const String _biometricLockKey = 'biometric_lock_enabled';
// in getSettings(): biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
@override
Future<void> setBiometricLock(bool enabled) async {
  await _prefs.setBool(_biometricLockKey, enabled);
}
```
Add `_appLockEnabledKey='app_lock_enabled'` (default `false`) + `_biometricUnlockKey='biometric_unlock_enabled'` (default `false`), wire into `getSettings()`/`updateSettings()`, add `setAppLockEnabled`/`setBiometricUnlockEnabled` to the interface + impl. **No Drift migration; `schemaVersion` stays 22** (SharedPreferences, plaintext one-key-per-field). Run `build_runner` after the Freezed edit.

---

### `onboarding_lock_entry_screen.dart` (MODIFY — D-02 write-through)

**Analog:** itself. Line `onboarding_lock_entry_screen.dart:47`:
```dart
await ref.read(settingsRepositoryProvider).setBiometricLock(false);
```
Repoint to `setAppLockEnabled(false)` (the "skip = lock off" semantic moves to the new master per D-02). Update the doc comment block (lines 14-17) that references `biometricLockEnabled` defaulting true.

---

### `app_lock_screen.dart` + lock widgets (NEW — UI, tone B)

**Analog (structure/theming):** `onboarding_lock_entry_screen.dart` — the canonical `ConsumerStatefulWidget` + `context.palette` + `S.of(context)` + busy-guard idiom for this codebase.

**Theming idiom to copy** (`onboarding_lock_entry_screen.dart:64-68`):
```dart
final palette = context.palette;
return Scaffold(
  backgroundColor: palette.background,
  body: ...
```
Plus the gradient-button palette idiom (`_OnboardingGradientButton`, lines 139-189: `palette.accentPrimary`/`palette.fabGradientStart`, `'Outfit'` font). Build Face ID page + PIN page as **two independent surfaces** (sketch 002 tone B): PIN page = standard 9-grid (1-9 / 0 / ⌫) + 4-dot indicator, instant-verify on 4th digit (D-12), wrong → shake + clear + haptic, NO text, NO cooldown (D-06). Face ID page auto-triggers biometric (D-09); on any failure STAY with 重试 + ghost 「パスコードを使用」 → tap switches to PIN page. `privacy_mask.dart` = opaque `palette.background`/`palette.card` + logo (NOT blur, D-07), driven by a synchronous `ValueNotifier<bool>` flip (RESEARCH §5).

---

### `main.dart` (MODIFY — gate branch + observer)

**Analog:** itself (`_buildHome` ladder + `_completeOnboarding` setState idiom).

**Gate ladder insertion point** (`main.dart:271-278`) — add `_isLocked` branch AFTER onboarding, BEFORE shell:
```dart
if (_needsOnboarding) {
  return OnboardingFlowScreen(bookId: _bookId!, onCompleted: _completeOnboarding);
}
if (_isLocked) {                                  // ← NEW
  return AppLockScreen(onUnlocked: _completeUnlock);
}
return MainShellScreen(bookId: _bookId!);
```

**Completion-flips-flag idiom to mirror** (`main.dart:286-298` `_completeOnboarding`):
```dart
void _completeUnlock() => setState(() => _isLocked = false);   // NEVER pushReplacement
```
(Honors [[boot-gate-completion-must-flip-flag-not-pushreplacement]] — `pushReplacement` would detach `_buildHome` and break `_reinitializeAfterDataReset`.)

**Cold-start init** (`main.dart:156-162`, inside `_initialize()` after reading `settings`):
```dart
final settings = await ref.read(settingsRepositoryProvider).getSettings();
final pinHash = await ref.read(secureStorageServiceProvider).getPinHash();
setState(() {
  _bookId = bookIdResult.data!;
  _needsOnboarding = !settings.onboardingComplete;
  _isLocked = settings.appLockEnabled && pinHash != null;   // LOCK-02
  _initialized = true;
});
```
Register `AppLockLifecycleObserver` next to `syncEngine.initialize()` (`main.dart:144-146`); the observer's `onRelock` does `setState(() => _isLocked = true)`. Keep `_isLocked` a `_HomePocketAppState` field (symmetric with `_needsOnboarding`; avoids the watch-in-build race the onboarding gate deliberately avoided — RESEARCH §4).

---

### ARB keys (MODIFY — `app_ja.arb` / `app_zh.arb` / `app_en.arb`)

**Analog:** existing `onboardingLock*` block (`app_ja.arb:3049-3064`):
```json
"onboardingLockTitle": "アプリロックを設定しますか？",
"@onboardingLockTitle": { "description": "Onboarding lock-entry screen: title (D-11)" },
```
Add lock-screen + PIN + forgot-PIN keys (e.g. `appLockFaceIdPrompt`, `appLockUsePasscode`, `appLockPinTitle`, `appLockForgotPin`, `appLockForgotPinExplanation`, plus SecuritySection D-11 strings) to **all three** ARB files (parity), each with an `@`-description block, then run `flutter gen-l10n`. Forgot-PIN copy must state unrecoverable / reinstall / lose unsynced data (LOCK-09, D-08), imply NO recovery path. Must pass the hardcoded-CJK scan + ARB parity check. Force-add `lib/generated/` (gitignored-yet-tracked — MEMORY gsd-executor-l10n-generated-uncommitted).

---

## Shared Patterns

### Riverpod 3 provider wiring
**Source:** `lib/infrastructure/security/providers.dart:42-59`
**Apply to:** `app_lock_providers.dart` + new providers in `providers.dart`
```dart
@Riverpod(keepAlive: true)
BiometricService biometricService(Ref ref) => BiometricService();

@riverpod
SecureStorageService secureStorageService(Ref ref) {
  final storage = ref.watch(flutterSecureStorageProvider);
  return SecureStorageService(storage: storage);
}
```
Provider names strip `Notifier` suffix; side-effects (navigation, unlock) go via `ref.listen`, not `ref.watch`; `AsyncValue.value` is nullable. Run `build_runner` after adding `@riverpod`.

### Secure-storage access (keychain)
**Source:** `secure_storage_service.dart:176-179` (reuse the existing `pinHash` slot)
```dart
Future<String?> getPinHash() => read(key: StorageKeys.pinHash);
Future<void> setPinHash(String value) => write(key: StorageKeys.pinHash, value: value);
Future<void> deletePinHash() => delete(key: StorageKeys.pinHash);
```
**Apply to:** `pin_kdf.dart` consumer + `app_lock_service.dart`. accessibility stays `unlocked_this_device` (`secure_storage_service.dart:77-79`) — NEVER change (brick risk 260610-ss7). Update the stale "PIN SHA-256 hash" comment (`secure_storage_service.dart:17`) to Argon2id PHC. PHC single-string approach needs ZERO `StorageKeys` change.

### Settings persistence (plaintext prefs)
**Source:** `settings_repository_impl.dart` — one-key-per-field, no Drift.
**Apply to:** new `appLockEnabled`/`biometricUnlockEnabled`. `schemaVersion` stays 22.

### UI theming + i18n
**Source:** `onboarding_lock_entry_screen.dart:65` (`final palette = context.palette;`) + `S.of(context).xxx`
**Apply to:** all `features/applock/presentation/` files. ADR-019 palette tokens, `'Outfit'` font, `AppTextStyles.amount*` only for money (n/a here).

---

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/features/applock/presentation/widgets/pin_keypad.dart` | component | event-driven | No 9-grid numeric keypad exists in repo; structure is net-new (theming idiom from onboarding analog, layout from sketch 002 tone B PIN page). |
| `lib/features/applock/presentation/widgets/pin_dots.dart` | component | — | No PIN-dots/shake indicator exists; net-new (animation per D-12). |

> Both have NO behavioral analog — planner builds structure from sketch `002-app-lock/index.html` (tone B) and borrows only `context.palette`/`S.of(context)` conventions from `onboarding_lock_entry_screen.dart`.

---

## Metadata

**Analog search scope:** `lib/infrastructure/security/`, `lib/infrastructure/sync/`, `lib/features/settings/`, `lib/features/onboarding/`, `lib/data/repositories/`, `lib/main.dart`, `lib/l10n/`
**Files scanned:** 11 source + 1 ARB
**Pattern extraction date:** 2026-06-30
</content>
</invoke>
