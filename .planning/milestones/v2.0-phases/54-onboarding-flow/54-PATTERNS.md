# Phase 54: 欢迎 / 首启引导（Onboarding flow） - Pattern Map

**Mapped:** 2026-06-29
**Files analyzed:** 14 (8 new, 6 edited)
**Analogs found:** 14 / 14 (every target has an in-repo analog — this phase is a recomposition, not new capability)

> Build on `54-RESEARCH.md` (§ Component Responsibilities, Standard Stack, Code Examples). This file does NOT restate research; it pins each new/edited file to the closest LIVE analog file with line-anchored excerpts the planner copies from. CLAUDE.md conventions are load-bearing: Riverpod 3 import split + name-strips-`Notifier`; `context.palette` (ADR-019); `S.of(context)` + 3 ARB files; `AppTextStyles.amount*` for money.

---

## File Classification

| New/Edited File | Role | Data Flow | Closest Analog | Match Quality |
|-----------------|------|-----------|----------------|---------------|
| `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart` (NEW) | screen (flow host) | event-driven (nested Navigator) | `profile_onboarding_screen.dart` (gate widget + `pushReplacement` to shell) | role-match |
| `lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart` (NEW) | screen | request-response (skip→next) | `profile_onboarding_screen.dart` (single-purpose `Scaffold` + `context.palette` + `ScatteredEmojiBackground`) | role-match |
| `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart` (NEW) | screen | CRUD write-through | `profile_onboarding_screen.dart` (nickname/avatar capture) + `appearance_section.dart` (変更-row + picker dialogs) | exact (two analogs combined) |
| `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart` (NEW) | screen | request-response (2 actions) | `profile_onboarding_screen.dart` `_ProfileGradientButton` + two-button layout | role-match |
| `test/widget/features/onboarding/*` (NEW) | test | — | `test/widget/features/profile/presentation/*` + `test/helpers/test_provider_scope.dart` | role-match |
| `test/unit/features/settings/voice_default_resolution_test.dart` (NEW) | test | — | existing `voice_locale_helpers` unit coverage + `test/unit/application/settings/*` | role-match |
| `lib/main.dart` (EDIT) | bootstrap gate | event-driven | itself (`_buildHome` branch 3 + `_needsProfileOnboarding`) | self |
| `lib/features/settings/domain/models/app_settings.dart` (EDIT) | model | — | `biometricLockEnabled` field (line 19) | exact |
| `lib/data/repositories/settings_repository_impl.dart` (EDIT) | repository | CRUD | `_biometricLockKey` wiring (lines 15/26/38/59) | exact |
| `lib/features/settings/domain/repositories/settings_repository.dart` (EDIT) | interface | — | `setBiometricLock` (line 9) | exact |
| `lib/application/settings/import_backup_use_case.dart` (EDIT) | use-case | transform | itself (`_restoreData` line 163) | self |
| `lib/application/settings/clear_all_data_use_case.dart` (EDIT) | use-case | batch delete | itself (line 41) | self |
| `lib/features/settings/presentation/screens/settings_screen.dart` (EDIT) | screen | — | itself (ListView, line 47) | self |
| `lib/features/settings/presentation/widgets/security_section.dart` (EDIT) | widget | — | itself (line 9) | self |

---

## Shared Patterns (cross-cutting — apply to ALL onboarding files)

### Palette / i18n / no-hardcoded-CJK
**Source:** `profile_onboarding_screen.dart:107` and `appearance_section.dart:24`
**Apply to:** every new onboarding screen + ARB.
```dart
final palette = context.palette;       // ADR-019 tokens — never hardcode hex
final l10n = S.of(context);            // every visible string via S.of(context)
Text(l10n.profileSetup, style: TextStyle(color: palette.textPrimary))
```
`test/architecture/hardcoded_cjk_ui_scan_test.dart` + `arb_key_parity_test.dart` are full-suite-only — run full `flutter test` per wave merge (MEMORY gsd-parallel-executor). All 4 selling points + `この設定で始める` + lock-entry copy become ARB keys in ja/zh/en.

### Write-through + invalidate (the universal settings-mutation idiom)
**Source:** `appearance_section.dart:52-56` (theme), `:84-88` (week start), `:174-184` (language), `security_section.dart:31-33` (biometric)
**Apply to:** every 変更 row in `onboarding_settings_screen.dart`.
```dart
await ref.read(settingsRepositoryProvider).setThemeMode(value);
ref.invalidate(appSettingsProvider);
```

---

## Pattern Assignments

### `lib/features/settings/domain/models/app_settings.dart` (model) — THE end-to-end template

**Analog:** `biometricLockEnabled` (this file is its own analog; copy that field's full wiring).

**Model field** (add beside line 19):
```dart
@Default(true) bool biometricLockEnabled,   // ← existing template
@Default(false) bool onboardingComplete,    // ← NEW (default false; absent backup → re-onboard until D-06 forces true)
```
`@freezed` + `fromJson` (lines 13-26) already serialize new fields automatically — `onboarding_complete` rides inside the backup `settings` map for free (RESEARCH: do NOT add a `BackupData` field). Run `build_runner` after.

### `lib/data/repositories/settings_repository_impl.dart` (repository, CRUD)

**Analog:** `_biometricLockKey` — copy all four touch-points (this is SharedPreferences, NOT Drift; no migration, `schemaVersion` stays 22).

**Key** (line 15):
```dart
static const String _biometricLockKey = 'biometric_lock_enabled';
static const String _onboardingCompleteKey = 'onboarding_complete';   // NEW
```
**getSettings()** (line 26):
```dart
biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
onboardingComplete: _prefs.getBool(_onboardingCompleteKey) ?? false,  // NEW
```
**updateSettings()** (line 38):
```dart
await _prefs.setBool(_biometricLockKey, settings.biometricLockEnabled);
await _prefs.setBool(_onboardingCompleteKey, settings.onboardingComplete); // NEW
```
**dedicated setter** (line 59):
```dart
@override
Future<void> setOnboardingComplete(bool enabled) async {
  await _prefs.setBool(_onboardingCompleteKey, enabled);
}
```

### `lib/features/settings/domain/repositories/settings_repository.dart` (interface)

**Analog:** line 9. Add `Future<void> setOnboardingComplete(bool enabled);` beside `setBiometricLock`.

---

### `lib/main.dart` (bootstrap gate) — replace branch 3

**Analog:** itself. The gate read mirrors `_needsProfileOnboarding`. Capture after init settle (NOT `ref.watch`) — branch-3 loading-null race (RESEARCH Pattern 2).

**Field** (line 103): rename `_needsProfileOnboarding` → `_needsOnboarding`.

**`_initialize()` capture** (replace lines 144-152 — drop the `getUserProfileUseCase` existence check, D-01 retires it):
```dart
final settings = await ref.read(settingsRepositoryProvider).getSettings();
setState(() {
  _bookId = bookIdResult.data!;
  _needsOnboarding = !settings.onboardingComplete;   // was: existingProfile == null
  _initialized = true;
});
```

**`_reinitializeAfterDataReset()` re-capture** (the gap — current code at lines 175-180 does NOT re-read; add the same read so clear/import re-evaluates the gate):
```dart
invalidateAllDataProviders(ref);
final settings = await ref.read(settingsRepositoryProvider).getSettings();
setState(() {
  _bookId = bookIdResult.data!;
  _needsOnboarding = !settings.onboardingComplete;   // NEW — D-05/D-06 land here
  _initialized = true;
});
```

**`_buildHome()` branch** (replace lines 250-252):
```dart
if (_needsOnboarding) {
  return OnboardingFlowScreen(bookId: _bookId!);   // was ProfileOnboardingScreen
}
```
Remove the now-unused `profile_onboarding_screen.dart` + `getUserProfileUseCaseProvider` imports (lines 22-24). `dataResetSignalProvider` listen (line 194) + MaterialApp `locale` (line 205, already `currentLocaleProvider`-driven → instant UI-lang switch is free) stay untouched.

---

### `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart` (NEW, flow host)

**Analog:** `profile_onboarding_screen.dart` (`ConsumerStatefulWidget` + `bookId` ctor param + `pushReplacement` to `MainShellScreen`).

**Shape:** `ConsumerStatefulWidget` taking `required this.bookId` (copy lines 16-24). Host a nested `Navigator` whose routes are intro → settings → lock-entry (RESEARCH Pattern 4 — no `go_router`). Own transient selection state until confirm. On completion: `setOnboardingComplete(true)` then `pushReplacement` to `MainShellScreen` exactly as lines 90-94:
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => MainShellScreen(bookId: widget.bookId)),
);
```
Guard the root (intro) route with `PopScope(canPop: false, ...)` so a fresh install can't pop out of onboarding (RESEARCH Pattern 4 / ONBOARD-07).

### `lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart` (NEW)

**Analog:** `profile_onboarding_screen.dart:109-114` (Scaffold + `palette.background` + `ScatteredEmojiBackground` + `SafeArea`/`Center`). Single screen listing the 4 sketch-001 tone-A selling points (privacy/local-first/dual-ledger/voice — all ARB keys), with a skip button that advances the nested Navigator to the settings route (D-02).

### `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart` (NEW) — combines two analogs

**Analog A (identity capture + nickname-required gate):** `profile_onboarding_screen.dart`
- `_canSubmit` (line 45) → `_canStart`: `_nickname.trim().isNotEmpty && !_isSaving` (D-14; nickname row initial placeholder「未設定」, button disabled until set — no default value).
- avatar editor: `_openAvatarPicker()` (lines 48-66) pushes `AvatarPickerScreen` returning `AvatarPickerResult{emoji, imagePath}`; default `randomWarmEmoji()` (line 36).
- confirm: `saveUserProfileUseCase.execute(displayName:, avatarEmoji:, avatarImagePath:)` (lines 76-82); error mapping `_messageForError` (lines 283-293: nameRequired/nameTooLong/invalidEmoji).
- `この設定で始める` button = `_ProfileGradientButton(label:, enabled: _canStart, onPressed: _confirm)` (lines 265-269, 295-354).

**Analog B (「行+変更」rows + pickers):** `appearance_section.dart`
- Row idiom = `ListTile(leading: Icon, title: label, subtitle: currentValue, onTap: openPicker)` (lines 28-33). D-10: each field one row, 変更 opens a dialog/sheet/picker.
- UI-language row → `_LanguageTile` pattern (lines 127-205): `localeProvider` read; on pick `setSystemDefault()` (untouched preselect → `'system'`, D-08) vs `setLocale(Locale(code))` (explicit → concrete), then `ref.invalidate(appSettingsProvider)` (lines 176-184). Device preselect helper (RESEARCH Code Examples): `{'ja','zh','en'}.contains(dev) ? dev : 'ja'` (D-07).
- currency row → reuse `CurrencySelectorSheet` (NOT a new list). Constructor (currency_selector_sheet.dart:175): `CurrencySelectorSheet(onSelect: ValueChanged<String>, selectedCode: String?)`. Currency write is a NEW path (RESEARCH Pattern 3 — no existing book-default setter):
```dart
showModalBottomSheet<void>(context: context, isScrollControlled: true,
  builder: (_) => CurrencySelectorSheet(
    selectedCode: currentCode,             // default 'JPY'
    onSelect: (code) async {
      final book = await ref.read(bookByIdProvider(bookId: bookId).future);
      await ref.read(bookRepositoryProvider).update(book.copyWith(currency: code));
      ref.invalidate(bookByIdProvider);
    }));
```
- voice row → `settingsRepo.setVoiceLanguage(code)`; on `'system'` UI-lang resolve concrete device lang FIRST via `voiceLocaleIdFromLanguageCode` source (voice_locale_helpers.dart:3 maps zh/ja/en→zh-CN/ja-JP/en-US, default zh-CN) — never store `'system'` in `voiceLanguage` (D-09 / RESEARCH Pitfall 4).

### `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart` (NEW)

**Analog:** `profile_onboarding_screen.dart:295-354` (`_ProfileGradientButton`). Trailing single screen, two actions (D-11/D-13):
- 跳过 → leave `biometricLockEnabled` off (no write), proceed to shell.
- 现在设置 → `pushReplacement(MainShellScreen)` then `push(SettingsScreen(scrollToSecurity: true))` — deep-link (RESEARCH Pitfall 5).

---

### `lib/application/settings/import_backup_use_case.dart` (EDIT, transform) — D-06

**Analog:** itself, line 163. Force-true so pre-Phase-54 `.hpb` (no field → defaults false) doesn't re-trigger onboarding:
```dart
final settings = AppSettings.fromJson(backupData.settings)
    .copyWith(onboardingComplete: true);   // existing user → skip onboarding
await _settingsRepo.updateSettings(settings);
```

### `lib/application/settings/clear_all_data_use_case.dart` (EDIT, batch) — D-05

**Analog:** itself, line 41. `updateSettings(const AppSettings())` already resets `onboardingComplete→false` (re-onboard works). GAP (RESEARCH Finding #4): it does NOT wipe identity → nickname/avatar survive. `UserProfileRepository.delete(String id)` ALREADY EXISTS (user_profile_repository.dart:6) — no new repo method needed. Inject `UserProfileRepository` into the ctor (mirror the existing repo fields, lines 10-23) and add before/after line 41:
```dart
final profile = await _userProfileRepo.find();   // find() returns UserProfile?
if (profile != null) await _userProfileRepo.delete(profile.id);
await _settingsRepo.updateSettings(const AppSettings());
```

### `lib/features/settings/presentation/screens/settings_screen.dart` + `widgets/security_section.dart` (EDIT) — deep-link target (D-13)

**Analog:** themselves. `SettingsScreen` is a pushed plain `ListView` (settings_screen.dart:47, ctor line 22 takes `bookId`) with no anchor; `SecuritySection` (security_section.dart:9) is one list child rendering the `biometricLockEnabled` `SwitchListTile` (lines 26-34). Add optional `bool scrollToSecurity = false` to `SettingsScreen` ctor + a `GlobalKey` on the `SecuritySection` slot + `addPostFrameCallback → Scrollable.ensureVisible(key.currentContext!)` (RESEARCH Pitfall 5 — discretion area). Phase 55 fills the real PIN/biometric here.

---

## Test Pattern Assignments

**Shared widget-test scope:** `ProviderContainer.test()` + `test/helpers/test_provider_scope.dart` `waitForFirstValue<T>(container, provider)` for async settings/locale providers (CLAUDE.md Riverpod-3 async test rule — never bare `await container.read(provider.future)` on auto-dispose).

- `test/widget/features/onboarding/*` — analog: existing `test/widget/features/profile/presentation/*` widget tests + `profile_onboarding_screen_test.dart` (the latter must be retargeted/removed — gate retired, RESEARCH "Deprecated/retired").
- `test/unit/features/settings/voice_default_resolution_test.dart` — analog: `voice_locale_helpers` coverage; assert `'system'` UI-lang resolves concrete device lang, never stores `'system'` in `voiceLanguage`.
- Extend `test/unit/application/settings/import_backup_use_case_test.dart` (D-06: old backup w/o field → true) and `clear_all_data_use_case_test.dart` (D-05: → false + identity wiped). Both files already exist.

---

## No Analog Found

None. Every target maps to a live in-repo analog. The only genuinely new code is flow scaffolding, the `onboardingComplete` boolean, the currency-write helper (RESEARCH Pattern 3), and deep-link plumbing.

## Metadata

**Analog search scope:** `lib/features/{settings,profile,onboarding,accounting,home}/`, `lib/data/repositories/`, `lib/application/settings/`, `lib/main.dart`, `test/{widget,unit}/`.
**Files read this session:** app_settings.dart, settings_repository_impl.dart, settings_repository.dart, main.dart, profile_onboarding_screen.dart, appearance_section.dart, security_section.dart, settings_screen.dart, import_backup_use_case.dart, clear_all_data_use_case.dart, user_profile_repository.dart, voice_locale_helpers.dart, currency_selector_sheet.dart.
**Pattern extraction date:** 2026-06-29
</content>
</invoke>
