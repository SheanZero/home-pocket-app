# i18n Full Audit & Language Switching Feature

**Date:** 2026-04-05
**Status:** Draft
**Related Module:** MOD-014 i18n

---

## Overview

Full audit of all ~668 ARB translation keys across Japanese, Chinese, and English, plus implementation of a language switching feature in Settings. The app already has comprehensive i18n infrastructure — this work fixes bugs, fills gaps, and wires up the missing UI.

## Goals

1. **Audit all translations** — Systematically review every key in all 3 ARB files for correctness, consistency, and completeness
2. **Fix translation bugs** — Wrong-language entries, untranslated literals, inconsistencies
3. **Add missing keys** — Localize hardcoded strings found in UI code
4. **Language switching UI** — Add a language picker in Settings > Appearance
5. **Wire persistence** — Connect `LocaleNotifier` to `SettingsRepository` so language choice survives app restart

## Non-Goals

- Adding new languages beyond ja/zh/en
- Migrating away from Flutter's built-in `flutter_localizations` + ARB
- RTL support
- Dynamic translation loading or remote translation management

---

## Part 1: Translation Audit

### Process

1. Extract all keys from `app_en.arb`, `app_ja.arb`, `app_zh.arb` into a unified CSV file for tabular review
2. **CSV output:** Save to `docs/i18n/translations.csv` with columns: `key`, `en`, `ja`, `zh`, `notes`
   - One row per translation key
   - `notes` column for flagging issues (wrong language, untranslated, inconsistency, etc.)
   - This CSV serves as the single source of truth for the audit review
3. Review each key for:
   - **Wrong language** — Target file contains text in the wrong language (e.g., Chinese text in Japanese file)
   - **Untranslated** — English literal appearing unchanged in ja/zh files
   - **Inconsistency** — Same concept translated differently across related keys
   - **Missing keys** — Key exists in template but missing from a locale file
4. Fix issues in the CSV, then sync corrections back to the 3 ARB files
5. Produce an audit report (markdown table) documenting all changes made

### Known Bugs (from initial exploration)

| Key | File | Issue |
|-----|------|-------|
| `addTransaction` | `app_ja.arb` | Contains Chinese `"添加账目"` instead of Japanese |
| `next` | `app_ja.arb`, `app_zh.arb` | English literal `"Next"` in both non-English files |

### Missing Keys (hardcoded strings in UI)

| Proposed Key | Source File | Current Hardcoded Value |
|-------------|-------------|------------------------|
| `error` | `lib/main.dart:180` | `'Error'` |
| `initializationError` | `lib/main.dart:181` | Dynamic error string |
| `listTab` | `lib/features/home/presentation/screens/main_shell_screen.dart:74` | `'List'` |
| `todoTab` | `lib/features/home/presentation/screens/main_shell_screen.dart:77` | `'Todo'` |
| `datePickerComingSoon` | `lib/features/home/presentation/screens/home_screen.dart:73` | `'Date picker coming soon'` |

---

## Part 2: Language Switching Architecture

### Existing Infrastructure (already in codebase)

| Component | Location | Status |
|-----------|----------|--------|
| `LocaleSettings` model | `lib/infrastructure/i18n/models/locale_settings.dart` | Working — has `locale`, `isSystemDefault`, `fromSystem()` |
| `LocaleNotifier` provider | `lib/features/settings/presentation/providers/locale_provider.dart` | Exists but broken — hardcodes Japanese, doesn't persist |
| `currentLocaleProvider` | Same file | Working — derives `Locale` from `LocaleNotifier` |
| `AppSettings.language` field | `lib/features/settings/domain/models/app_settings.dart` | Exists, defaults to `'ja'` |
| `SettingsRepository.setLanguage()` | `lib/features/settings/domain/repositories/settings_repository.dart` | Exists, persists to SharedPreferences |
| `MaterialApp.locale` | `lib/main.dart` | Already driven by `currentLocaleProvider` |

### Changes Required

#### 1. `LocaleNotifier.build()` — Read persisted language on startup

**Current:** Always returns `LocaleSettings.defaultSettings()` (Japanese).

**New:** Read `AppSettings.language` from `SettingsRepository`. If value is `'system'`, resolve via `LocaleSettings.fromSystem()`. Otherwise, create `LocaleSettings(locale: Locale(code), isSystemDefault: false)`.

#### 2. `LocaleNotifier.setLocale()` — Persist on change

**Current:** Only updates in-memory state.

**New:** After updating state, call `SettingsRepository.setLanguage()` with the locale code (or `'system'` for system default).

#### 3. `LocaleNotifier` — Add `SettingsRepository` dependency

Add `ref.watch(settingsRepositoryProvider)` so the notifier can read/write persisted settings.

#### 4. `AppSettings.language` default — Change for new installs

**Current default:** `'ja'`

**New default:** `'system'` — lets device locale drive the choice on first launch, with Japanese as fallback for unsupported locales.

### Data Flow

```
User taps language in Settings
  → AppearanceSection calls LocaleNotifier.setLocale(locale)
  → LocaleNotifier:
      1. Updates in-memory state (LocaleSettings)
      2. Persists via SettingsRepository.setLanguage(code)
  → currentLocaleProvider emits new Locale
  → MaterialApp rebuilds with new locale
  → All S.of(context) calls return new language strings
```

---

## Part 3: Settings UI

### Placement

Language picker is added to the **Appearance section** (`appearance_section.dart`), directly below the existing Theme tile.

### UI Pattern

A `ListTile` with:
- **Leading icon:** `Icons.language` (globe icon)
- **Title:** `S.of(context).language` (already in ARB: "言語" / "语言" / "Language")
- **Subtitle:** Current language name in its own language (e.g., "日本語", "中文", "English") or "System Default" equivalent
- **onTap:** Opens a radio dialog

### Radio Dialog

Matches the existing Theme selection dialog pattern exactly (`AlertDialog` + `RadioListTile`):

**Options (4 total):**

| Value | Display Label (always shown in target language) |
|-------|------------------------------------------------|
| `system` | システム設定に従う / 跟随系统设置 / Follow System |
| `ja` | 日本語 |
| `zh` | 中文 |
| `en` | English |

**Behavior:** Selecting an option immediately:
1. Calls `LocaleNotifier.setLocale()` or `LocaleNotifier.setSystemDefault()`
2. Closes the dialog
3. App rebuilds in the new language (including the Settings screen itself)

### Language Display Labels

Language names are shown **in their own language** (not translated), which is the standard mobile convention:
- Japanese is always "日本語" regardless of current app language
- Chinese is always "中文" regardless of current app language
- English is always "English" regardless of current app language
- "System Default" label is translated per current locale

These display labels are hardcoded constants (not ARB keys), since they should not change with the app locale.

The subtitle on the ListTile shows the current selection's native name. When "System Default" is active, show something like "システム設定に従う (日本語)" — the system label plus the resolved language in parentheses.

---

## Part 4: Error Handling & Edge Cases

| Scenario | Behavior |
|----------|----------|
| Device locale unsupported (e.g., Korean) + System Default selected | Fall back to Japanese (existing `LocaleSettings.fromSystem()` logic) |
| First launch (new install) | Default to `'system'` — device locale drives it, Japanese fallback |
| Existing users upgrading | Keep `'ja'` default — no behavior change for current users |
| SharedPreferences unavailable | Fall back to Japanese (same as current behavior) |
| ARB key missing from a locale file | `flutter gen-l10n` will error at build time — caught during development |

---

## Part 5: Testing Strategy

### Unit Tests

- `LocaleNotifier`: startup reads persisted value, `setLocale()` persists, system default resolution
- `LocaleSettings.fromSystem()`: supported locales resolve correctly, unsupported falls back to Japanese
- ARB parity: all 3 files have identical key sets (can be a build-time check via `flutter gen-l10n`)

### Widget Tests

- `AppearanceSection`: language tile renders, shows current language, tap opens dialog
- Language dialog: all 4 options render, selecting one calls `setLocale()`, dialog closes
- Language switch: after switching, `S.of(context)` returns strings in new language

### Integration Tests

- Full flow: Settings → Appearance → Language → select English → verify UI text changed → kill app → relaunch → verify English persisted

---

## Files to Modify

| File | Change |
|------|--------|
| `lib/l10n/app_en.arb` | Add missing keys, fix any issues found in audit |
| `lib/l10n/app_ja.arb` | Fix wrong-language entries, add missing keys |
| `lib/l10n/app_zh.arb` | Fix untranslated entries, add missing keys |
| `lib/features/settings/presentation/providers/locale_provider.dart` | Wire to SettingsRepository, read on startup, persist on change |
| `lib/features/settings/presentation/widgets/appearance_section.dart` | Add language ListTile + radio dialog |
| `lib/features/settings/domain/models/app_settings.dart` | Change default language to `'system'` |
| `lib/main.dart` | Replace hardcoded `'Error'` with localized string |
| `lib/features/home/presentation/screens/main_shell_screen.dart` | Replace hardcoded `'List'`/`'Todo'` with localized strings |
| `lib/features/home/presentation/screens/home_screen.dart` | Replace hardcoded `'Date picker coming soon'` |

### New Files

None — all changes are to existing files.
