# Architecture Research

**Domain:** Pre-launch gating + lock + compliance integration into a shipped local-first Flutter app (Home Pocket v2.0)
**Researched:** 2026-06-28
**Confidence:** HIGH (all integration points read directly from current source — main.dart, app_initializer.dart, secure_storage_service.dart, settings_repository_impl.dart, about_section.dart, security_section.dart, state_locale.dart, state_settings.dart)

> This is an **integration** architecture doc, not a greenfield one. It answers exactly where the onboarding gate, the app-lock gate, and the Settings legal/donation additions attach to THIS app's existing boot + shell, and how each new setting is persisted and wired into the existing providers.

## Standard Architecture

### The single integration seam: `HomePocketApp._buildHome()`

The app already has a **gate stack** in `lib/main.dart`. `AppInitializer` finishes *before* `runApp`, so by the time `HomePocketApp` mounts, the master key + encrypted DB + final `ProviderContainer` are guaranteed ready. The container is handed to `UncontrolledProviderScope`, then `HomePocketApp` runs its own async `_initialize()` (seed + ensure-book + profile probe) and stores the result in **local widget state** (`_bookId`, `_initialized`, `_needsProfileOnboarding`, `_error`). `_buildHome()` then renders a synchronous branch ladder. **This is the exact pattern the two new gates must follow.**

```
main() → ensureNativeLibrary() → AppInitializer.initialize()   [KeyManager → DB → container]
                                          │
                         InitSuccess(container)        InitFailure
                                          │                  │
                  UncontrolledProviderScope(container)   InitFailureApp(onRetry)   ← error-fallback lives HERE, above the gates
                                          │
                                  HomePocketApp (ConsumerStatefulWidget)
                                   _initialize(): seed + ensureBook + read gate config → setState
                                          │
                                  MaterialApp (watches currentLocaleProvider, appSettingsProvider)
                                          │
                                     _buildHome()  ← THE GATE LADDER (extend this, do not relocate it)
   ┌──────────────────────────────────────────────────────────────────────────────────────┐
   │ 1. _error != null            → error Scaffold            (existing)                      │
   │ 2. !_initialized             → CircularProgressIndicator (existing)                      │
   │ 3. !_onboardingComplete      → OnboardingFlow            (NEW — first-run only)          │
   │ 4. _appLockEnabled &&        → AppLockScreen             (NEW — launch + resume)         │
   │      !_unlockedThisSession                                                               │
   │ 5. _needsProfileOnboarding   → ProfileOnboardingScreen   (existing)                      │
   │ 6. else                      → MainShellScreen(bookId)   (existing IndexedStack shell)   │
   └──────────────────────────────────────────────────────────────────────────────────────┘
```

**Why this order.** On first launch nothing is configured: branch 3 (onboarding) runs and *contains* the optional lock setup, so the lock gate (branch 4) is dormant because `_appLockEnabled` is still false. Once onboarding writes `onboarding_complete=true`, every subsequent launch falls through branch 3 and hits branch 4, which blocks all content until unlock. Profile onboarding (branch 5) stays after the lock because the user must be authenticated before reaching any personal data screen.

### Component Responsibilities

| Component | Responsibility | Implementation |
|-----------|----------------|----------------|
| `AppInitializer` (unchanged) | KeyManager → DB → container. Owns the data-loss guard. Completes before `runApp`. | `lib/core/initialization/app_initializer.dart` — **do not add gate logic here** |
| `HomePocketApp._initialize()` (modified) | After seed/ensure-book, read gate config: `onboarding_complete` (SharedPreferences), `app_lock_enabled` (AppSettings), pin-hash presence (secure_storage). Store in local state so branches resolve synchronously. | `lib/main.dart` |
| `OnboardingFlow` (NEW) | First-run app intro + **mandatory** UI-language / currency / voice-language setup; optional lock setup; writes `onboarding_complete` last. | `lib/features/onboarding/presentation/` |
| `AppLockScreen` (NEW) | Biometric (`local_auth`) + PIN unlock UI. Sets `_unlockedThisSession=true` on success. | `lib/features/app_lock/presentation/` |
| `AppLockController` (NEW) | `WidgetsBindingObserver` that re-locks on `resumed` after `paused` when lock enabled. | `lib/features/app_lock/` (lifecycle observer; precedent = `SyncEngine`) |
| `PinService` (NEW) | Salted-hash a PIN, verify, store/clear via the **already-present** `StorageKeys.pinHash`. | `lib/infrastructure/security/` (alongside `biometric_service`) |
| `SecureStorageService` (unchanged) | Already exposes `getPinHash()/setPinHash()/deletePinHash()` + `StorageKeys.pinHash='pin_hash'`. PIN slot is **pre-wired**. | `lib/infrastructure/security/secure_storage_service.dart` |
| `LegalSection` + `DonationSection` (NEW, or extend `AboutSection`) | Privacy Policy / Terms / 特商法 表記 / OSS licenses / donation link. | `lib/features/settings/presentation/widgets/` |

## Recommended Project Structure

```
lib/features/
├── onboarding/                       # NEW feature module (Thin Feature)
│   └── presentation/
│       ├── screens/onboarding_flow_screen.dart   # paged intro + setup steps
│       ├── widgets/                              # language/currency/voice step widgets
│       └── providers/onboarding_state.dart       # onboarding_complete read/write
├── app_lock/                         # NEW feature module
│   ├── app_lock_controller.dart                  # WidgetsBindingObserver (resume re-lock)
│   └── presentation/
│       ├── screens/app_lock_screen.dart          # biometric + PIN entry
│       ├── widgets/pin_pad.dart
│       └── providers/app_lock_state.dart
└── settings/presentation/widgets/
    ├── about_section.dart            # MODIFIED (fill privacyPolicy TODO, add Terms)
    ├── legal_section.dart            # NEW (Privacy / Terms / 特商法 / OSS)
    └── donation_section.dart         # NEW (url_launcher to sponsor page)

lib/infrastructure/security/
└── pin_service.dart                  # NEW (salted PIN hash; reuses crypto KDF + SecureStorageService)
```

### Structure Rationale

- **`onboarding/` and `app_lock/` as new Thin-Feature modules** — they hold only `presentation/` (+ one lifecycle observer). They reuse existing application/infrastructure services; no `data/tables`, no `application/` of their own (import_guard-clean).
- **`pin_service.dart` in `infrastructure/security/`** — CLAUDE.md mandates all crypto/secret handling live under `lib/infrastructure/`. The PIN secret is hashed, not stored raw, so the hashing belongs next to `biometric_service`/`secure_storage_service`, not in a feature.
- **Legal content as bundled assets, not a feature data layer** — privacy/terms/特商法 text ship as localized markdown under `assets/legal/` and render in-app (offline, no network — matches the zero-knowledge ethos).

## Architectural Patterns

### Pattern 1: Local-state gate (mirror `_needsProfileOnboarding`)

**What:** Read gate config once during `_initialize()`, hold it in `setState`, and branch synchronously in `_buildHome()`.
**When:** Both new gates.
**Trade-offs:** + No first-frame flash of the shell before an async gate resolves; + the gate decision can never race `AppInitializer` (init already completed). − Config changed at runtime (e.g. toggling lock in Settings) requires a `ref.listen`/`setState` path, same as the existing `dataResetSignalProvider` re-bootstrap.

```dart
// in _initialize(), after _seedAndEnsureDefaultBook() succeeds:
final prefs = ref.read(settingsRepositoryProvider);
final settings = await prefs.getSettings();
final onboardingDone = await ref.read(onboardingRepositoryProvider).isComplete();
final pinSet = await ref.read(secureStorageServiceProvider).getPinHash() != null;
setState(() {
  _onboardingComplete = onboardingDone;
  _appLockEnabled = settings.biometricLockEnabled || pinSet; // see persistence table
  _unlockedThisSession = false;
  _needsProfileOnboarding = existingProfile == null;
  _initialized = true;
});
```

### Pattern 2: `pushReplacement` to the shell (mirror `ProfileOnboardingScreen`)

**What:** The terminal step of each gate `Navigator.pushReplacement(MaterialPageRoute(... MainShellScreen ...))` — no go_router. `ProfileOnboardingScreen._submit()` already does exactly this.
**When:** End of onboarding; end of unlock can instead flip local state (`_unlockedThisSession=true`) so `_buildHome()` re-renders to the next branch — preferred over an extra route push.
**Trade-offs:** + Zero new routing dependency; consistent with the whole app. − State lives in `HomePocketApp`; the gates either call back up (callback prop) or flip a provider that `HomePocketApp` listens to.

### Pattern 3: Lifecycle re-lock observer (mirror `SyncEngine.initialize()`)

**What:** `AppLockController implements WidgetsBindingObserver`; on `didChangeAppLifecycleState(resumed)` after a `paused`, if lock enabled, set unlocked=false so the gate re-renders `AppLockScreen`.
**When:** App-lock on resume from background.
**Trade-offs:** + Reuses the proven observer pattern (`SyncEngine` already registers one at boot). − Must decide the relock policy (immediate vs grace period) — a design decision for the lock phase. Keep it simple: relock on every `resumed` while enabled.

## Data Flow

### Onboarding write-through into existing providers (no new persistence for these three)

```
OnboardingFlow step          write call (EXISTING path)                        downstream reaction
──────────────────────────── ───────────────────────────────────────────────  ─────────────────────────────────
UI language picked        →  ref.read(localeProvider.notifier).setLocale(L)  →  persists `language` via
                             (SettingsRepository.setLanguage)                     SettingsRepository; localeProvider
                                                                                  state updates → currentLocaleProvider
                                                                                  recomputes → MaterialApp.locale
                                                                                  (main.dart already watches it) rebuilds
                                                                                  immediately. No restart.

Currency picked           →  read active Book → bookRepository.update(          →  Book.currency is the home/display
  (reuse v1.7                 book.copyWith(currency: code)); invalidate           currency (default 'JPY' from
   CurrencySelectorSheet)     book provider                                        EnsureDefaultBookUseCase). Lists/
                                                                                  analytics/home read book.currency.

Voice language picked     →  ref.read(settingsRepositoryProvider)             →  appSettings → voiceLocaleIdProvider
                             .setVoiceLanguage(code);                              recomputes BCP-47 (zh-CN/ja-JP/en-US).
                             ref.invalidate(appSettingsProvider)                   Voice flow already reads it.

onboarding_complete=true  →  onboardingRepository.setComplete()  (NEW key)    →  written LAST, after all mandatory
                                                                                  fields succeed (atomic intent).
```

### App-lock unlock flow

```
launch (branch 4 active) → AppLockScreen
   ├─ biometric path: ref.read(biometricServiceProvider).authenticate(...)  → ok → _unlockedThisSession=true
   └─ PIN path: PinService.verify(entered) vs StorageKeys.pinHash           → ok → _unlockedThisSession=true
                                                                            → _buildHome() re-renders → branch 5/6
resume from background → AppLockController(resumed) → _unlockedThisSession=false → AppLockScreen again
```

## Persistence decision — per setting (justified against the encrypted local-first model)

| Setting | Store | Key / field | Why this store |
|---------|-------|-------------|----------------|
| **PIN hash** | **secure_storage (Keychain/Keystore)** | `StorageKeys.pinHash` (**already exists**, currently unused) | The only true secret. Hardware-backed, survives app-data clears but not uninstall, never to iCloud (`unlocked_this_device` — do not change, see provider comment). **Never** SharedPreferences (plaintext). Store a *salted hash*, never the raw PIN — reuse a KDF from `infrastructure/crypto`, mirroring the existing `recoveryKitHash` precedent. |
| **app_lock_enabled / biometric_enabled** | SharedPreferences (via `AppSettings`) | `biometric_lock_enabled` already exists (default true); add `app_lock_enabled` if biometric-vs-PIN must be independent | Non-secret toggles; `SecuritySection` already reads/writes `biometricLockEnabled`. Keep config co-located with all other app config. |
| **onboarding_complete** | SharedPreferences | new `onboarding_complete` bool | Non-secret one-way flag. SharedPreferences is independent of the master key/DB, so it is readable even in degraded boot states — the gate must not depend on the encrypted DB being open. |
| **UI language** | SharedPreferences (via `SettingsRepository.setLanguage`) | `language` | Existing canonical path; `localeProvider` already reads it on build. |
| **Currency (home/display)** | **encrypted Drift — `Book.currency`** (via `BookRepository.update`) | book row | Currency is per-book domain data that already exists (default JPY). Family/multi-book-correct; belongs with the ledger, not in global prefs. |
| **Voice language** | SharedPreferences (via `setVoiceLanguage`) | `voice_language` | Existing canonical path; `voiceLocaleIdProvider` derives BCP-47 from it. |

**Why not encrypted Drift for the lock config:** (1) bootstrap ordering / defense-in-depth — the lock should be decidable from SharedPreferences + Keychain without first opening the SQLCipher DB; (2) the single secret (PIN) gets stronger protection in the Keychain than a SQLCipher field; (3) consistency — every other non-secret toggle already lives in SharedPreferences.

## Anti-Patterns

### Anti-Pattern 1: A second `ProviderScope` or gate above the container
**What people do:** Wrap a new gate around `UncontrolledProviderScope` or in `main()`.
**Why it's wrong:** The gate then can't use `ref`/the initialized container, and you'd duplicate scopes.
**Do this instead:** Put both gates *inside* `HomePocketApp._buildHome()`, below the existing error/spinner branches.

### Anti-Pattern 2: Async gate in `build()` that flashes the shell
**What people do:** `ref.watch(someFutureProvider)` for lock/onboarding directly in `build()`; while it's `loading`, the shell paints for one frame.
**Why it's wrong:** Brief flash of protected content before the lock appears.
**Do this instead:** Resolve gate config in `_initialize()` and hold it in local state (Pattern 1), exactly like `_needsProfileOnboarding`.

### Anti-Pattern 3: Storing the PIN (or its plain value) in SharedPreferences / Drift
**Why it's wrong:** SharedPreferences is plaintext; even SQLCipher is weaker than the Keychain for a single credential.
**Do this instead:** Salted hash in `StorageKeys.pinHash` (slot already defined).

### Anti-Pattern 4: Adding go_router for the new flows
**Why it's wrong:** The app has no go_router; the whole codebase uses `Navigator` + `MaterialPageRoute` + `pushReplacement`.
**Do this instead:** Mirror `ProfileOnboardingScreen`'s `pushReplacement` to `MainShellScreen`.

### Anti-Pattern 5: Writing `onboarding_complete` before mandatory fields are committed
**Why it's wrong:** A crash mid-onboarding could leave a half-configured app that never re-prompts.
**Do this instead:** Write the flag last, only after language + currency + voice writes all succeed.

## Integration Points

### New dependency required

| Dependency | Why | Caution |
|------------|-----|---------|
| `url_launcher` | Donation/sponsor link is the one legitimate external-URL launch. **Not currently in pubspec.** | Verify against the `win32`-pinned trio (`file_picker 11` / `package_info_plus 9` / `share_plus 12`) per CLAUDE.md; run `flutter build ios --debug --no-codesign` after adding. `local_auth ^3.0.1` and `flutter_secure_storage ^10.2.0` are already present. |

Legal text (Privacy / Terms / 特商法) ships as bundled localized assets and renders in-app — **no** network/WebView dependency, preserving offline + privacy. OSS licenses already work via Flutter's built-in `showLicensePage` in `AboutSection`.

### Internal boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Gate ladder ↔ `AppInitializer` | none (init fully completes first) | The gates can never race init; container is ready before `HomePocketApp` mounts. |
| OnboardingFlow ↔ existing settings | `localeProvider`, `settingsRepository`, `bookRepository` | Reuses canonical write paths; no new persistence for language/voice/currency. |
| AppLockScreen ↔ security infra | `biometricServiceProvider`, `secureStorageServiceProvider` (+ new `PinService`) | `biometric_service.authenticate(...)` + `StorageKeys.pinHash` already exist. |
| `AppLockController` ↔ Flutter lifecycle | `WidgetsBindingObserver` | Same mechanism `SyncEngine` already uses; register at boot, dispose with app. |
| Settings sections ↔ legal assets / donation | direct widget + `url_launcher` | `AboutSection` already has a `privacyPolicy` TODO stub and a working `showLicensePage`; fill the stub, add Terms/特商法/donation. |

## New vs Modified — explicit inventory

**NEW components:** `OnboardingFlow` (+ step widgets, onboarding repo/provider with `onboarding_complete`); `AppLockScreen` (+ `pin_pad`); `AppLockController` (lifecycle observer); `PinService` (salted hash); `LegalSection` + `DonationSection` (or expanded `AboutSection`); `onboarding/` and `app_lock/` feature modules; `assets/legal/*` localized markdown; `url_launcher` dependency.

**MODIFIED components:** `lib/main.dart` (`_initialize()` reads gate config; `_buildHome()` adds branches 3 + 4); `AppSettings` (+ `appLockEnabled` if needed; `biometricLockEnabled` already present); `SettingsRepositoryImpl` (persist the new flag(s)); `SecuritySection` (PIN setup/change tile alongside the existing biometric switch); `AboutSection` (fill `privacyPolicy` TODO + add Terms/特商法); ARB ja/zh/en (+ onboarding/lock/legal/donation keys — trilingual parity gate).

**UNCHANGED (reused as-is):** `AppInitializer`, `UncontrolledProviderScope` wiring, `MainShellScreen` IndexedStack, `localeProvider`/`currentLocaleProvider`, `voiceLocaleIdProvider`, `biometric_service`, `SecureStorageService` (`pinHash` slot pre-wired), `BookRepository.update`, `showLicensePage`.

## Suggested build order (design-gate first; respects dependencies)

1. **Phase 53 — HTML design gate (NO production code).** Onboarding flow design draft as HTML, approved before any Dart, per the v1.8 Phase 43 precedent. Also sketch the lock screen + the legal/donation Settings layout here so later phases just implement.
2. **Phase 54 — Onboarding flow.** Gate branch 3 + mandatory language/currency/voice setup writing through existing providers + `onboarding_complete` (written last). Optionally surface the "set up app lock" prompt that branch 4 will later honor. Build before lock because lock setup is *offered during* onboarding.
3. **Phase 55 — App-lock.** `AppLockScreen` (biometric + PIN), `PinService`, `AppLockController` resume re-lock, gate branch 4, and the `SecuritySection` PIN/toggle controls. Depends on the onboarding lock prompt existing.
4. **Phase 56 — Settings legal + donation + Japan compliance.** Fill privacy/terms/特商法/OSS, add `url_launcher` donation link, bundle localized legal assets, trilingual ARB. Independent of the gates — last. (If donations are accepted, confirm whether 特定商取引法に基づく表記 is required — a legal/compliance call to make in this phase.)

## Sources

- `lib/main.dart` — gate ladder, `_initialize()`, `UncontrolledProviderScope`, error fallback, `currentLocaleProvider`/`appSettingsProvider` watch (HIGH)
- `lib/core/initialization/app_initializer.dart` — init completes before `runApp`; ordered KeyManager→DB (HIGH)
- `lib/infrastructure/security/secure_storage_service.dart` — `StorageKeys.pinHash` + `get/set/deletePinHash` already defined (HIGH)
- `lib/infrastructure/security/providers.dart` — `biometricServiceProvider`, `secureStorageServiceProvider`, keychain accessibility constraint (HIGH)
- `lib/data/repositories/settings_repository_impl.dart` — SharedPreferences backing; `biometric_lock_enabled` key (HIGH)
- `lib/features/settings/domain/models/app_settings.dart` — `biometricLockEnabled`, `language`, `voiceLanguage` fields (HIGH)
- `lib/features/settings/presentation/providers/state_locale.dart`, `state_settings.dart` — `localeProvider`/`currentLocaleProvider`/`voiceLocaleIdProvider` write-through (HIGH)
- `lib/features/settings/presentation/widgets/about_section.dart`, `security_section.dart` — privacyPolicy TODO stub, working `showLicensePage`, biometric switch (HIGH)
- `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` — gate + `pushReplacement` precedent (HIGH)
- `lib/features/accounting/domain/repositories/book_repository.dart` — `update(Book)` for currency write; `EnsureDefaultBookUseCase` default `currency: 'JPY'` (HIGH)
- `pubspec.yaml` — `local_auth ^3.0.1`, `flutter_secure_storage ^10.2.0`, `shared_preferences ^2.3.4` present; `url_launcher` absent (HIGH)

---
*Architecture research for: pre-launch gating/lock/compliance integration into Home Pocket v2.0*
*Researched: 2026-06-28*
