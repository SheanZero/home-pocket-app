# Phase 54: 欢迎 / 首启引导（Onboarding flow） - Research

**Researched:** 2026-06-29
**Domain:** Flutter boot-gate orchestration · Riverpod 3 write-through · SharedPreferences-backed settings · re-entrant Navigator flow · i18n/ARB
**Confidence:** HIGH (all findings verified by reading the live codebase; no new external dependencies)

## Summary

Phase 54 reorganizes the existing first-boot experience into a single onboarding flow (intro → settings → lock-entry) inserted at `_buildHome()` branch 3, replacing the current `_needsProfileOnboarding`/`ProfileOnboardingScreen` gate. Every write target already exists — there is **no new data axis** and **no new runtime dependency**. The work is almost entirely UI assembly plus one new persisted boolean.

The single most important finding overturns a locked decision's premise: **`AppSettings` is persisted via `SharedPreferences`, not Drift.** D-04 says store `onboarding_complete` in "Drift 加密 AppSettings"; the ground truth (`lib/data/repositories/settings_repository_impl.dart`) is a `SharedPreferences`-backed repo writing one key per field. Adding `onboarding_complete` therefore requires **no Drift schema migration** — just a new `@Default(false) bool onboardingComplete` on the `@freezed` model, a new prefs key + getter/setter, inclusion in `updateSettings`, and `build_runner`. `schemaVersion` stays at **22** (CONTEXT correct; CLAUDE.md's "21" is stale).

Two integration gaps need the planner's attention. (1) **D-05 (delete-all = re-onboard) is only half-wired:** `ClearAllDataUseCase` resets settings to `const AppSettings()` (→ `onboardingComplete=false`, re-onboard works) but does **not** delete the `UserProfile` — nickname/avatar survive a wipe, contradicting D-05's "身份也被擦". (2) **D-06 (import = skip onboarding)** needs an explicit `copyWith(onboardingComplete: true)` in `ImportBackupUseCase._restoreData`, because old `.hpb` backups lack the field and default it to `false`.

**Primary recommendation:** Add `onboardingComplete` to the existing SharedPreferences settings (no Drift work); build the onboarding flow as a self-contained widget that writes through `localeProvider` / `settingsRepo.setVoiceLanguage` / `bookRepo.update(book.copyWith(currency:))` / `saveUserProfileUseCase`, writes `onboarding_complete=true` only on explicit completion, then `pushReplacement` to `MainShellScreen` (mirroring today's `ProfileOnboardingScreen`); gate reads the flag captured after init, re-captured in `_reinitializeAfterDataReset`.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01 (合并身份步):** 退役独立 `ProfileOnboardingScreen` gate（`_needsProfileOnboarding`），昵称+头像+`saveUserProfileUseCase` 逻辑折进欢迎流设置页。最终首启=单一引导流（介绍 → 设置 → 锁入口），不再有两个串联 gate。
- **D-02 (介绍页保留):** Phase 53 批准的「介绍 app 价值」页保持不动（隐私/本地优先/双账本/语音卖点，可跳过）。合并只发生在设置页。
- **D-03 (有意偏离批准 HTML 稿):** 批准 sketch 001 tone-A 设置步无身份字段；合并后设置步新增「昵称+头像」两行，属对批准稿的有意偏离。planner 视情况补设计稿/QA；非违反 design-gate。
- **D-04 (存 Drift 加密 AppSettings):** `onboarding_complete` 作为 `AppSettings` 新字段（`@Default(false)`），绝不从 `currency≠null` 反推。 ⚠️ **见 Finding #1 — 实际持久化为 SharedPreferences 非 Drift；下游须澄清。**
- **D-05 (删除全部数据=当全新安装):** 「删除全部数据」擦库连同 `onboarding_complete` → 重启重走引导。 ⚠️ **见 Finding #4 — 现 `ClearAllDataUseCase` 不删 UserProfile。**
- **D-06 (导入备份=跳过引导):** 导入成功后显式置 `onboarding_complete=true`，不依赖旧备份是否带该字段。
- **D-07 (UI 语言预选=设备语言):** 设备是 ja/zh/en 之一预选它，其它（如韩语）回退 ja。
- **D-08 (UI 语言写入语义):** 未改动接受预选 → 写 `'system'`（继续跟随设备）；主动选具体语言 → 写 `'ja'/'zh'/'en'` 钉死。确认后 MaterialApp 即时切换（`localeProvider`）。
- **D-09 (币种 + 语音):** 币种写既有 `Book.currency`、复用 v1.7 货币选择器、默认 JPY；语音写既有 `AppSettings.voiceLanguage`、默认=所选 UI 语言。当 UI 语言写 `'system'` 时，语音默认取「解析后的具体设备语言」（zh-CN/ja-JP/en-US，不能是 'system'）。
- **D-10 (统一「行+変更」模式):** 设置页全部字段统一一行「标签: 当前值 [変更]」——昵称/头像/UI语言/币种/语音 各自点开 bottom-sheet/picker 编辑。
- **D-11 (锁入口=末尾单独一屏):** `この設定で始める` 确认后弹收尾屏「要设置应用锁吗？」[跳过]/[现在设置]。主进度=介绍+设置 2 步，锁屏是收尾不占主进度。
- **D-12 (无显式进度条):** 不画步进点/进度条，仅靠返回键/手势导航；但须保证 re-entrant 无法卡死。
- **D-13 (进 app + 深链 Settings 安全区):** 「跳过」=进 app 锁保持关闭；「现在设置」=进 app 并深链 Settings 安全区。Phase 54 不建一次性丢弃锁 UI，复用现有 Settings 承载。
- **D-14 (坚持昵称必填):** 昵称行初始显「未設定」占位，确认键被拦截直到用户实际设过昵称；不给默认占位值，不保留「零输入一键确认」。

### Claude's Discretion
- 新增引导文案的 ARB key 命名与组织（三语 ja/zh/en 齐全，过 ARB parity + 硬编码 CJK 扫描）。
- 介绍页卖点的具体排版/插画/跳过按钮位置（单屏列卖点；轮播 = ONBOARD-V2-01 已 defer）。
- 深链到 Settings 安全区的具体导航机制（进 shell 后 push Settings / 传 intent 滚动到安全区）。
- 「行+変更」各行 bottom-sheet 的具体样式（沿用 ADR-019 桜餅×若葉 + 既有组件）。

### Deferred Ideas (OUT OF SCOPE)
- 更丰富的介绍轮播 / 引导内权限预说明 — **ONBOARD-V2-01**（V2）。
- 真正的应用锁 PIN/生物识别设置 UI + 安全评审 — **Phase 55**（本 phase 仅提供深链入口）。
- Settings 法务/赞助/日本合规 — **Phase 56**。
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| ONBOARD-01 | 仅首次启动展示引导；幂等；`onboarding_complete` 显式完成时落，绝不从 currency≠null 反推 | New `onboardingComplete` bool on `AppSettings` (SharedPreferences, Finding #1); gate reads it (Finding #2); written only at explicit completion |
| ONBOARD-02 | 引导内 app 介绍（隐私/本地优先/双账本卖点），介绍部分可跳过 | Intro screen kept per D-02; sketch 001 tone-A selling points (Finding #9, Code Examples) |
| ONBOARD-03 | 确认 UI 语言（设备语言预选）→ 写 `localeProvider`，MaterialApp 即时生效 | `localeProvider`/`LocaleNotifier.setLocale`/`setSystemDefault` (Finding #5); MaterialApp already `ref.watch(currentLocaleProvider)` (main.dart:204) |
| ONBOARD-04 | 确认记账币种（JPY 默认）→ 写 `Book.currency`（复用 v1.7 货币选择器） | `CurrencySelectorSheet` reusable; **new** write path `bookRepo.update(book.copyWith(currency:))` (Finding #5) |
| ONBOARD-05 | 确认语音输入语言（默认=所选 UI 语言）→ 写既有语音 locale 设置 | `settingsRepo.setVoiceLanguage` + `voiceLocaleIdFromLanguageCode` (Finding #5); 'system' resolution caveat (Finding #6) |
| ONBOARD-06 | 引导末尾「设置应用锁」入口，可明确跳过（skip 后锁保持关闭） | Trailing lock-entry screen (D-11); skip = leave `biometricLockEnabled` off; deep-link to `SecuritySection` (Finding #7) |
| ONBOARD-07 | 支持返回上一步 + 进度提示，无法卡死；gate 在 init settle 之后判定，绝不竞态 | Captured-after-init gate (Finding #2); Navigator back-stack re-entrancy (Finding #8) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Onboarding gate decision | Presentation (`main.dart` `_HomePocketAppState`) | Application (read settings) | Boot-time branch widget, not a route; already where `_needsProfileOnboarding` lives |
| `onboarding_complete` persistence | Data (`SettingsRepositoryImpl` / SharedPreferences) | Domain (`AppSettings` model) | Mirrors every other settings flag — same repo, same model |
| UI-language write-through | Presentation (`localeProvider`) | Data (`SettingsRepository.setLanguage`) | Existing Riverpod notifier owns persist + live MaterialApp switch |
| Currency write-through | Data (`BookRepository.update`) | Presentation (`CurrencySelectorSheet`) | `Book.currency` is a Book field; selector is a reusable widget |
| Voice-language write-through | Data (`SettingsRepository.setVoiceLanguage`) | Presentation | Existing field + helper |
| Identity (nickname/avatar) | Application (`SaveUserProfileUseCase`) | Data (`UserProfileRepository`) | Existing use case + validation contract, folded into settings page |
| Lock-entry landing | Presentation (deep-link to `SecuritySection`) | — | Phase 54 reuses Settings; Phase 55 fills real PIN/biometric |

## Standard Stack

No new packages. Phase 54 is built entirely from in-repo symbols already on `pubspec.yaml`.

### Core (existing symbols — the implementation surface)
| Symbol | File | Purpose |
|--------|------|---------|
| `HomePocketApp._buildHome()` | `lib/main.dart:238` | Gate ladder; insert onboarding branch, retire `_needsProfileOnboarding` |
| `AppSettings` (`@freezed`) | `lib/features/settings/domain/models/app_settings.dart:14` | Add `@Default(false) bool onboardingComplete` |
| `SettingsRepositoryImpl` | `lib/data/repositories/settings_repository_impl.dart` | Add `_onboardingCompleteKey`, getter/setter, include in `updateSettings` |
| `SettingsRepository` (interface) | `lib/features/settings/domain/repositories/settings_repository.dart` | Add `setOnboardingComplete(bool)` |
| `appSettingsProvider` | `lib/features/settings/presentation/providers/state_settings.dart:11` | Async source of `onboardingComplete` for the gate |
| `localeProvider` / `LocaleNotifier` | `lib/features/settings/presentation/providers/state_locale.dart:15` | `setLocale(Locale)` / `setSystemDefault()` — UI-language write-through |
| `currentLocaleProvider` | `state_locale.dart:48` | Already drives `MaterialApp.locale` (main.dart:204) — instant switch is free |
| `CurrencySelectorSheet` | `lib/features/accounting/presentation/widgets/currency_selector_sheet.dart` | Reuse via `showModalBottomSheet`; `onSelect: (code) {}`, `selectedCode:` |
| `BookRepository.update(Book)` | `lib/features/accounting/domain/repositories/book_repository.dart:10` | Currency write: `update(book.copyWith(currency: code))` |
| `voiceLocaleIdFromLanguageCode` | `lib/features/settings/presentation/utils/voice_locale_helpers.dart:3` | zh/ja/en → zh-CN/ja-JP/en-US (default zh-CN) |
| `SaveUserProfileUseCase` | `lib/application/profile/save_user_profile_use_case.dart:25` | Nickname/avatar save + validation (`nameRequired`/`nameTooLong(50)`/`invalidEmoji`) |
| `randomWarmEmoji()` | `lib/shared/constants/warm_emojis.dart:32` | Default avatar |
| `AvatarPickerScreen` / `AvatarPickerResult` | `lib/features/profile/presentation/screens/avatar_picker_screen.dart` | Avatar row editor (push, returns `{emoji, imagePath}`) |
| `AvatarDisplay` | `lib/features/profile/presentation/widgets/avatar_display.dart` | Avatar render |
| `SecuritySection` | `lib/features/settings/presentation/widgets/security_section.dart` | Deep-link target for "现在设置" (D-13) |
| `dataResetSignalProvider` + `invalidateAllDataProviders` | `lib/core/state/data_reset_signal.dart`, `lib/shared/utils/invalidate_all_data_providers.dart` | Re-bootstrap after clear/import (already invalidates `appSettingsProvider`) |

**Installation:** none. `git grep` confirms every symbol above already exists.

**Code generation (mandatory after editing the `@freezed` model):**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n   # after adding ARB keys
```

## Package Legitimacy Audit

Not applicable — Phase 54 installs **no external packages**. The milestone's only new runtime dependency (`url_launcher`) is added in Phase 56 per the 53-04 handoff, not here.

## Architecture Patterns

### System Architecture Diagram

```
                         app boot (main → bootWithInitializer)
                                       │
                          AppInitializer.initialize()  ── KeyManager → DB → services
                                       │ InitSuccess(container)
                                       ▼
                         _HomePocketAppState._initialize()
            (seed → ensureDefaultBook → sync engine → READ onboarding_complete)
                                       │ setState(_initialized=true, _needsOnboarding=!complete)
                                       ▼
                            MaterialApp (locale ← currentLocaleProvider)
                                       │
                              _buildHome() gate ladder
        ┌──────────────┬───────────────┬───────────────────────┬─────────────────┐
     _error?        !_initialized   _needsOnboarding         (else)
   error screen      spinner             │                MainShellScreen
                                         ▼
                              ┌─────────────────────────┐
                              │   OnboardingFlow widget  │  (nested Navigator)
                              │  ① intro (skippable)     │──skip──┐
                              │     ↕ back               │        ▼
                              │  ② settings page         │   ② settings page
                              │   nickname[req]/avatar/  │
                              │   UI-lang/currency/voice │  write-through on each 変更:
                              │   [この設定で始める]      │   • localeProvider.setLocale/setSystemDefault
                              │     ↓ (nickname set?)     │   • bookRepo.update(book.copyWith(currency:))
                              │  ③ lock-entry (trailing)  │   • settingsRepo.setVoiceLanguage
                              │   [跳过] / [现在设置]     │   • saveUserProfileUseCase.execute(...)
                              └─────────────────────────┘
                                  │ on completion: setOnboardingComplete(true)
                                  ▼
                       pushReplacement → MainShellScreen
                            (if 现在设置: also push SettingsScreen + scroll to SecuritySection)

   data-reset path:  Settings clear/import → dataResetSignal.fire()
        → _reinitializeAfterDataReset() → invalidateAllDataProviders(ref)
        → RE-READ onboarding_complete → setState(_needsOnboarding)
```

### Component Responsibilities

| File (new or edited) | Responsibility |
|---|---|
| `lib/features/onboarding/presentation/screens/onboarding_flow_screen.dart` (new) | Hosts intro → settings → lock-entry with a nested `Navigator`; owns transient selection state until confirm |
| `lib/features/onboarding/presentation/screens/onboarding_intro_screen.dart` (new) | D-02 selling points, skip button |
| `lib/features/onboarding/presentation/screens/onboarding_settings_screen.dart` (new) | 「行+変更」rows; `この設定で始める` blocked until nickname set (D-14) |
| `lib/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart` (new) | Trailing "set app lock?" [跳过]/[现在设置] (D-11/D-13) |
| `lib/main.dart` (edit) | Replace branch 3; read `onboarding_complete` after init + on re-bootstrap |
| `app_settings.dart` + `settings_repository*.dart` (edit) | New `onboardingComplete` field/key/getter/setter |
| `import_backup_use_case.dart` (edit) | Force `onboardingComplete: true` on restore (D-06) |
| `clear_all_data_use_case.dart` (edit, see Finding #4) | Optionally also delete `UserProfile` to honor D-05 |
| `settings_screen.dart` + `security_section.dart` (edit) | Accept deep-link/scroll-to-security intent (D-13) |
| `lib/l10n/app_{ja,zh,en}.arb` (edit) | Onboarding strings, three-locale parity |

### Pattern 1: New persisted boolean on SharedPreferences-backed settings
**What:** Add `onboardingComplete` exactly the way `biometricLockEnabled` is done today.
**When to use:** Any non-sensitive settings flag.
**Example:**
```dart
// app_settings.dart — add to the factory
@Default(false) bool onboardingComplete,

// settings_repository_impl.dart
static const String _onboardingCompleteKey = 'onboarding_complete';
// in getSettings():
onboardingComplete: _prefs.getBool(_onboardingCompleteKey) ?? false,
// in updateSettings():
await _prefs.setBool(_onboardingCompleteKey, settings.onboardingComplete);
// new setter (interface + impl):
Future<void> setOnboardingComplete(bool v) async =>
    _prefs.setBool(_onboardingCompleteKey, v);
```

### Pattern 2: Gate read captured after init settle (mirrors `_needsProfileOnboarding`)
**What:** Read the flag once init has settled, not reactively, to honor ONBOARD-07 "绝不与 init 竞态".
**Example:**
```dart
// in _initialize(), after sync engine wiring:
final settings = await ref.read(settingsRepositoryProvider).getSettings();
setState(() {
  _bookId = bookIdResult.data!;
  _needsOnboarding = !settings.onboardingComplete;   // replaces _needsProfileOnboarding
  _initialized = true;
});
// in _reinitializeAfterDataReset(), after invalidateAllDataProviders(ref):
final settings = await ref.read(settingsRepositoryProvider).getSettings();
setState(() { _bookId = bookIdResult.data!; _needsOnboarding = !settings.onboardingComplete; _initialized = true; });
// _buildHome():
if (_needsOnboarding) return OnboardingFlowScreen(bookId: _bookId!);
```
**Why captured, not `ref.watch`:** `appSettingsProvider` is async and independent of `_initialize()`; watching it in `build()` risks a loading-null at branch 3 (race). Capturing after `getSettings()` resolves matches the proven existing pattern and the success-criterion wording. (Reactive alternative documented in Open Questions.)

### Pattern 3: Currency write-through (NEW path — no existing setter)
```dart
final book = await ref.read(bookByIdProvider(bookId: bookId).future);
await ref.read(bookRepositoryProvider).update(book.copyWith(currency: code));
ref.invalidate(bookByIdProvider);
```
`manual_one_step_screen.dart` only writes a *transaction's* currency; there is no prior "set book default currency" callsite, so this small write path is genuinely new.

### Pattern 4: Re-entrant flow with a nested Navigator
**What:** Wrap intro/settings/lock-entry in a child `Navigator` inside `OnboardingFlowScreen`. Back gesture pops within the flow (settings → intro, lock-entry → settings) and never escapes to a dead end. The flow's root route (intro) can `WillPopScope`/`PopScope`-guard to prevent popping out of onboarding entirely on a fresh install.
**Why:** App uses `Navigator` + `MaterialPageRoute` + `IndexedStack` tab shell, **no `go_router`** (CLAUDE.md; REQUIREMENTS Out-of-Scope line 81). A nested Navigator gives self-contained re-entrancy without touching the app's routing.

### Anti-Patterns to Avoid
- **Inferring onboarding state from `currency != null` / profile existence.** Explicitly forbidden (ONBOARD-01, D-04). Use the dedicated flag only.
- **Adding a Drift table/migration for one boolean.** Settings are SharedPreferences; a migration is unnecessary work and contradicts the existing pattern (Finding #1).
- **Adding `onboarding_complete` as a top-level `BackupData` field.** It already rides inside the `settings` map (`settings.toJson()` at export_backup_use_case.dart:73). Add nothing to `BackupData`; just force-true on import (Finding #5).
- **Watching `appSettingsProvider` for the gate in `build()`.** Race risk at branch 3 (Pattern 2).
- **Hardcoding CJK UI strings.** `test/architecture/hardcoded_cjk_ui_scan_test.dart` will fail. All onboarding copy via `S.of(context)` + three ARB files.
- **Building a throwaway lock UI.** D-13: reuse `SecuritySection`; Phase 55 delivers the real PIN/biometric.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Currency picker | New list/search UI | `CurrencySelectorSheet` (`showModalBottomSheet`) | Full ISO list, search, recent-use ordering, JPY-pinned, golden-safe already done |
| Nickname/avatar capture + validation | New save logic | `SaveUserProfileUseCase` + `AvatarPickerScreen` + `randomWarmEmoji()` | Enforces nameRequired/≤50/valid-emoji; old-avatar cleanup |
| UI-language persist + live switch | Manual prefs + MaterialApp rebuild | `localeProvider.notifier.setLocale/setSystemDefault` | `MaterialApp.locale` already watches `currentLocaleProvider` (main.dart:204) |
| Voice locale mapping | New switch | `voiceLocaleIdFromLanguageCode` | Single source of truth for speech_to_text BCP-47 |
| Post-reset refresh | Manual invalidation | `dataResetSignalProvider` + `invalidateAllDataProviders` | Already invalidates `appSettingsProvider`/`currentLocaleProvider`/`bookByIdProvider` |
| Settings persistence | New store | `SettingsRepository` SharedPreferences impl | Every other flag lives here |

**Key insight:** This phase is a *recomposition* of shipped components, not new capability. The only genuinely new code is the flow scaffolding, one boolean, the currency-write helper, and the deep-link plumbing.

## Runtime State Inventory

> Rename/refactor-adjacent (retiring `ProfileOnboardingScreen` gate + adding a persisted flag). Inventory below.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `onboarding_complete` → SharedPreferences key (NEW, `bool`, default false). `language`/`voiceLanguage`/`biometricLockEnabled`/`theme_mode`/`week_start_day`/`monthly_joy_target` already in SharedPreferences. `UserProfile` (nickname/avatar) in Drift via `UserProfileRepository`. `Book.currency` in Drift. | Add prefs key + getter/setter. No Drift migration. |
| Live service config | None — onboarding touches no external service config. | None. |
| OS-registered state | None. | None. |
| Secrets/env vars | None new. `biometricLockEnabled` flag exists but real PIN/secure-storage is Phase 55. | None this phase. |
| Build artifacts | `app_settings.freezed.dart` / `app_settings.g.dart` regenerate after model edit; `lib/generated/app_localizations*.dart` regenerate after ARB edit. | Run build_runner + gen-l10n; **force-add** `lib/generated/` (gitignored-yet-tracked — MEMORY gsd-executor-l10n-generated-uncommitted). |

**Migration vs code-edit:** `onboarding_complete` is a *code edit* (new field) — there is no pre-existing data to migrate because the key simply defaults to `false`. The semantic correctness comes from D-06's import-time force-true and D-05's clear-time reset, not from a backfill.

## Common Pitfalls

### Pitfall 1: D-04 assumes Drift; persistence is SharedPreferences (Finding #1)
**What goes wrong:** Planner writes a Drift migration + schema bump for `onboarding_complete`.
**Why it happens:** D-04 and CONTEXT integration-points say "Drift 加密 AppSettings (@freezed + fromJson)". Only the `@freezed + fromJson` part is true; the store is `SharedPreferences` (`settings_repository_impl.dart:1` imports `shared_preferences`, every field is a prefs key).
**How to avoid:** Treat it as a prefs flag. `schemaVersion` stays 22. Flag the D-04 wording to discuss-phase: the flag will be stored in **plaintext SharedPreferences** (NSUserDefaults / SharedPreferences XML), same as the existing settings — acceptable for a non-sensitive boolean, but it is *not* SQLCipher-encrypted as D-04 implies.
**Warning signs:** Any `onUpgrade` edit, any `schemaVersion => 23`.

### Pitfall 2: D-05 clear-all leaves identity behind (Finding #4)
**What goes wrong:** After "delete all data", re-onboarding shows the old nickname/avatar (or the nickname-required gate behaves oddly), contradicting D-05's "身份/昵称/头像也被擦".
**Why it happens:** `ClearAllDataUseCase.execute()` deletes transactions/categories/books and `updateSettings(const AppSettings())`, but never calls into `UserProfileRepository`. The profile row survives.
**How to avoid:** Planner decides — either (a) add `UserProfileRepository.delete()`/clear to `ClearAllDataUseCase`, or (b) have the merged onboarding settings page pre-fill from a surviving profile so re-onboard "edits" it. (a) matches D-05 intent ("擦库=新开始"). Verify whether `UserProfileRepository` exposes a delete; if not, that is a small addition.
**Warning signs:** Re-onboarding after clear shows a populated nickname.

### Pitfall 3: D-06 old backups re-trigger onboarding (Finding #5)
**What goes wrong:** Import a pre-Phase-54 `.hpb` → `settings` map lacks `onboarding_complete` → `AppSettings.fromJson` defaults it `false` → onboarding reappears for an existing user.
**Why it happens:** `ImportBackupUseCase._restoreData` does `AppSettings.fromJson(backupData.settings)` then `updateSettings(settings)` (import_backup_use_case.dart:163).
**How to avoid:** Change to `.copyWith(onboardingComplete: true)` before `updateSettings`. Do NOT add a `BackupData` field. Then `dataResetSignal.fire()` → `_reinitializeAfterDataReset` re-reads `true` → skip onboarding.
**Warning signs:** Onboarding shown after importing an old backup.

### Pitfall 4: 'system' language → voice default must resolve concrete (Finding #6)
**What goes wrong:** When D-08 writes `language='system'`, naively writing `voiceLanguage='system'` breaks speech (`voiceLocaleIdFromLanguageCode('system')` falls to default `zh-CN`, not the device language).
**Why it happens:** `voice_locale_helpers.dart` only maps `zh`/`ja`/`en`; everything else → `zh-CN`.
**How to avoid:** On confirm, resolve the device language first (`PlatformDispatcher.instance.locale.languageCode`, fallback `ja` per D-07) to a concrete `zh`/`ja`/`en`, and write *that* to `voiceLanguage`. Never store `'system'` in `voiceLanguage`.
**Warning signs:** Voice input listens in Chinese after a Japanese-device user accepts the system default.

### Pitfall 5: Deep-link to security has no scroll target (Finding #7)
**What goes wrong:** "现在设置" pushes Settings but lands at the top; user can't find the security area.
**Why it happens:** `SettingsScreen` is a plain `ListView` (settings_screen.dart:47) with no anchor; it is **pushed** from Home's `onSettingsTap`, it is *not* an `IndexedStack` tab (main_shell_screen.dart:166-176 tabs are Home/List/Analytics/Shopping).
**How to avoid:** Add an optional intent param to `SettingsScreen` (e.g. `scrollToSecurity: true`) + a `GlobalKey` on the `SecuritySection` slot + `WidgetsBinding.instance.addPostFrameCallback` → `Scrollable.ensureVisible(key.currentContext)`. From the lock-entry screen: `pushReplacement(MainShellScreen)` then `push(SettingsScreen(scrollToSecurity: true))`. This is the discretion area in CONTEXT.
**Warning signs:** "现在设置" lands at the profile card.

### Pitfall 6: Generated l10n / freezed left uncommitted (MEMORY)
**What goes wrong:** `flutter analyze` from clean fails because `lib/generated/` is gitignored-yet-tracked and the executor's `git add` skips it.
**How to avoid:** `git add -f lib/generated/` after `gen-l10n`; commit `*.freezed.dart`/`*.g.dart`. Orchestrator re-check (MEMORY gsd-executor-l10n-generated-uncommitted, Phase 46).

## Code Examples

### Import: force onboarding-complete (D-06)
```dart
// import_backup_use_case.dart _restoreData — replace line 163
final settings = AppSettings.fromJson(backupData.settings)
    .copyWith(onboardingComplete: true);   // existing user, skip onboarding
await _settingsRepo.updateSettings(settings);
```

### UI-language write-through with device preselect + 'system' semantics (D-07/D-08)
```dart
// device preselect (used to seed the picker's initial value)
String preselectLang() {
  final dev = PlatformDispatcher.instance.locale.languageCode;
  return const {'ja','zh','en'}.contains(dev) ? dev : 'ja'; // D-07 fallback
}

// on confirm — D-08: untouched preselect → 'system'; explicit pick → concrete
if (userPickedExplicitly) {
  await ref.read(localeProvider.notifier).setLocale(Locale(picked)); // writes 'zh'/'ja'/'en'
} else {
  await ref.read(localeProvider.notifier).setSystemDefault();        // writes 'system'
}
// voice default (D-09 + Finding #6): resolve concrete, never 'system'
final voice = userPickedExplicitly ? picked : preselectLang();
await ref.read(settingsRepositoryProvider).setVoiceLanguage(voice);
```

### Reuse the currency selector (ONBOARD-04 / D-09)
```dart
showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => CurrencySelectorSheet(
    selectedCode: currentCode,           // default 'JPY'
    onSelect: (code) async {
      final book = await ref.read(bookByIdProvider(bookId: bookId).future);
      await ref.read(bookRepositoryProvider).update(book.copyWith(currency: code));
      ref.invalidate(bookByIdProvider);
    },
  ),
);
```

### Nickname-required confirm gate (D-14) — reuse existing contract
```dart
// _canSubmit pattern from ProfileOnboardingScreen (profile_onboarding_screen.dart:45)
bool get _canStart => _nickname.trim().isNotEmpty && !_isSaving;
// この設定で始める button: onPressed: _canStart ? _confirm : null
// _confirm(): saveUserProfileUseCase.execute(displayName:, avatarEmoji:, avatarImagePath:)
//   → on success: setOnboardingComplete(true) → push lock-entry screen
```

### Approved intro selling points (sketch 001 tone-A, three-locale ARB)
From `.planning/sketches/001-onboarding-gate/index.html`: 「すべて端末内・暗号化 / クラウド送信なし」(privacy), local-first, 日常+悦己双账本, 「声でサッと記録」(voice). Confirm button copy locked to **`この設定で始める`**. Each becomes an ARB key in ja/zh/en.

## State of the Art

| Old Approach (current code) | New Approach (Phase 54) | Impact |
|------|------|--------|
| Two-stage gate: `_needsProfileOnboarding` → `ProfileOnboardingScreen`, separate from any settings step | Single onboarding flow (intro → merged settings → lock-entry) at branch 3 | Retire `ProfileOnboardingScreen` as a *gate*; fold its nickname/avatar capture into the flow |
| Onboarding-ness inferred from `getUserProfileUseCase() == null` (main.dart:150) | Explicit `onboarding_complete` flag | Idempotent, decoupled from profile existence (ONBOARD-01) |
| No first-boot language/currency/voice confirmation | Confirmed on first boot, written through existing providers | New UX, zero new data axes |

**Deprecated/retired by this phase:**
- `ProfileOnboardingScreen` **as a boot gate** (main.dart:24, 250-252). The widget's capture logic is reused inside the new settings page; the standalone gate branch is deleted. Its widget test (`test/widget/.../profile_onboarding_screen_test.dart`) must be retargeted or removed.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Non-sensitive `onboarding_complete` is acceptable in plaintext SharedPreferences (D-04 said "Drift 加密") | Finding #1 / Pitfall 1 | If user actually wants it SQLCipher-backed, a Drift-backed settings store would be net-new infra — needs discuss-phase confirmation |
| A2 | D-05 intends identity (nickname/avatar) wiped on clear, so `ClearAllDataUseCase` should gain a `UserProfile` delete | Finding #4 / Pitfall 2 | If identity-survives-clear is acceptable, no code change needed; otherwise a new repo delete is required |
| A3 | `UserProfileRepository` can be made to delete the profile (or already can) | Finding #4 | If no delete exists, slightly larger change in clear path |
| A4 | Captured-after-init gate (not reactive watch) is the intended pattern for "绝不竞态" | Pattern 2 | Reactive watch is a viable alternative (Open Questions) |

## Open Questions (ALL RESOLVED 2026-06-29)

> Resolved into `54-CONTEXT.md` § Research-Resolved Clarifications and implemented across the 7 plans:
> (1) **plaintext SharedPreferences** — user-confirmed 2026-06-29; no Drift migration, schemaVersion stays 22 (54-01).
> (2) **clear-all wipes `UserProfile`** — `UserProfileRepository.delete(String id)` already exists; injected into `ClearAllDataUseCase` (54-04).
> (3) **captured-after-init gate** — adopted (not reactive watch); re-read in `_reinitializeAfterDataReset` (54-07).

1. **D-04 storage medium (plaintext prefs vs Drift-encrypted).** → **RESOLVED: plaintext prefs.**
   - What we know: All settings today are plaintext SharedPreferences; `onboarding_complete` is a non-sensitive boolean.
   - What's unclear: Whether D-04's "Drift 加密" wording is a hard requirement or a misdescription of the existing model.
   - Recommendation: Use SharedPreferences (consistent, no migration); surface A1 to discuss-phase as a one-line confirm.

2. **Does clear-all wipe identity? (D-05)**
   - What we know: `ClearAllDataUseCase` does not touch `UserProfile`.
   - Recommendation: Add `UserProfile` deletion to the clear path to match D-05 intent; verify `UserProfileRepository` delete availability during planning.

3. **Reactive vs captured gate.**
   - Captured (Pattern 2) matches the existing `_needsProfileOnboarding` precedent and the "no race" wording. Reactive (`ref.watch(appSettingsProvider)` in `build`, gate on `AsyncData`) auto-survives re-bootstrap via existing invalidation but must guard the loading state to avoid a flash. Recommendation: captured.

## Environment Availability

Not applicable — Phase 54 is a code/config + ARB change with no new external tools, services, or runtimes. (Build toolchain `flutter`/`build_runner`/`gen-l10n` already in daily use per CLAUDE.md.)

## Validation Architecture

> `workflow.nyquist_validation` not disabled — section included.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (+ `ProviderContainer.test()`, `test/helpers/test_provider_scope.dart` `waitForFirstValue`) |
| Config file | `flutter_test_config.dart` (golden comparator swap off-macOS — MEMORY golden-ci-platform-gate) |
| Quick run command | `flutter test test/unit/features/settings test/widget/features/onboarding` |
| Full suite command | `flutter analyze && flutter test` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ONBOARD-01 | Idempotent gate: `onboarding_complete=true` → straight to shell; `false`/absent → onboarding | widget | `flutter test test/widget/features/onboarding/onboarding_gate_test.dart` | ❌ Wave 0 |
| ONBOARD-01 | `setOnboardingComplete`/getter round-trips via SharedPreferences | unit | `flutter test test/unit/data/repositories/settings_repository_impl_test.dart` | ⚠️ extend existing |
| ONBOARD-02 | Intro skippable → lands on settings | widget | `flutter test test/widget/features/onboarding/onboarding_intro_test.dart` | ❌ Wave 0 |
| ONBOARD-03 | Confirm UI lang → `localeProvider` state + persisted `language`; MaterialApp locale updates | widget | `flutter test test/widget/features/onboarding/onboarding_settings_test.dart` | ❌ Wave 0 |
| ONBOARD-04 | Confirm currency → `Book.currency` updated, default JPY | unit/widget | same settings test | ❌ Wave 0 |
| ONBOARD-05 | Voice default = chosen UI lang; 'system' resolves concrete (not 'system') | unit | `flutter test test/unit/features/settings/voice_default_resolution_test.dart` | ❌ Wave 0 |
| ONBOARD-06 | Lock-entry: skip leaves `biometricLockEnabled` off; "现在设置" deep-links security | widget | `flutter test test/widget/features/onboarding/onboarding_lock_entry_test.dart` | ❌ Wave 0 |
| ONBOARD-07 | Back stack: settings↔intro, lock→settings, cannot dead-lock; nickname-required blocks confirm (D-14) | widget | settings + flow test | ❌ Wave 0 |
| D-05 | Clear-all → `onboarding_complete=false` (and identity wiped, if A2 adopted) | unit | `flutter test test/unit/application/settings/clear_all_data_use_case_test.dart` | ⚠️ extend existing |
| D-06 | Import (old backup w/o field) → `onboarding_complete=true` | unit | `flutter test test/unit/application/settings/import_backup_use_case_test.dart` | ⚠️ extend existing |
| Cross | ARB three-locale parity | arch | `flutter test test/architecture/arb_key_parity_test.dart` | ✅ exists |
| Cross | No hardcoded CJK in onboarding UI | arch | `flutter test test/architecture/hardcoded_cjk_ui_scan_test.dart` | ✅ exists |

### Sampling Rate
- **Per task commit:** `flutter analyze` + the touched test file(s) (`flutter test <file> -x`).
- **Per wave merge:** Full `flutter test` (the two architecture tests are full-suite-only — MEMORY gsd-parallel-executor: scoped tests miss arch scans).
- **Phase gate:** `flutter analyze` (0 issues) + full `flutter test` green before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/widget/features/onboarding/onboarding_gate_test.dart` — idempotency (ONBOARD-01)
- [ ] `test/widget/features/onboarding/onboarding_intro_test.dart` — skippable (ONBOARD-02)
- [ ] `test/widget/features/onboarding/onboarding_settings_test.dart` — write-through + nickname-required (ONBOARD-03/04/07/D-14)
- [ ] `test/widget/features/onboarding/onboarding_lock_entry_test.dart` — skip/deep-link (ONBOARD-06)
- [ ] `test/unit/features/settings/voice_default_resolution_test.dart` — 'system' → concrete (ONBOARD-05)
- [ ] Extend `settings_repository_impl_test.dart` — new key round-trip
- [ ] Extend `import_backup_use_case_test.dart` / `clear_all_data_use_case_test.dart` — D-06 / D-05
- [ ] Retarget/remove `test/widget/features/profile/.../profile_onboarding_screen_test.dart` (gate retired)
- [ ] Shared widget-test scope: `ProviderContainer.test()` + `waitForFirstValue` for async settings providers

## Security Domain

Phase 54 introduces **no new attack surface**: no network, no crypto, no auth, no new secret storage (real PIN/biometric is Phase 55). The single new persisted value is a non-sensitive boolean.

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | App lock is Phase 55 |
| V3 Session Management | no | — |
| V4 Access Control | no | — |
| V5 Input Validation | yes | Nickname via `SaveUserProfileUseCase` (trim, ≤50, valid-emoji); currency restricted to ISO list in selector |
| V6 Cryptography | no | `onboarding_complete` is non-sensitive; do NOT introduce new crypto for it |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| `onboarding_complete` in plaintext prefs read/altered (jailbroken device) | Tampering | Acceptable: worst case is re-showing/skipping onboarding; no data exposure (A1) |
| Malicious imported backup forces state | Tampering | Existing import path validates version + rate rows; settings are device-local config only |
| Identity persists after "delete all" (privacy expectation) | Info disclosure | Pitfall 2 / A2 — wipe `UserProfile` in clear path |

## Sources

### Primary (HIGH confidence — read directly this session)
- `lib/main.dart` — gate ladder (238-255), `_initialize`/`_reinitializeAfterDataReset` (132-188), MaterialApp locale (204-223)
- `lib/features/settings/domain/models/app_settings.dart` — `@freezed` model + `fromJson`
- `lib/data/repositories/settings_repository_impl.dart` — **SharedPreferences** persistence (Finding #1)
- `lib/data/app_database.dart:53` — `schemaVersion => 22`
- `lib/features/settings/presentation/providers/state_locale.dart`, `state_settings.dart` — `localeProvider`/`currentLocaleProvider`/`appSettingsProvider`/`voiceLocaleId`
- `lib/features/settings/presentation/utils/voice_locale_helpers.dart` — voice mapping
- `lib/application/settings/clear_all_data_use_case.dart` (Finding #4), `import_backup_use_case.dart` (Finding #5), `export_backup_use_case.dart`
- `lib/features/settings/domain/models/backup_data.dart` — settings ride in `settings` map
- `lib/shared/utils/invalidate_all_data_providers.dart` — invalidates `appSettingsProvider`/`currentLocaleProvider`/`bookByIdProvider`
- `lib/features/profile/presentation/screens/profile_onboarding_screen.dart`, `lib/application/profile/save_user_profile_use_case.dart`, `get_user_profile_use_case.dart`, `lib/shared/constants/warm_emojis.dart`
- `lib/features/accounting/presentation/widgets/currency_selector_sheet.dart` — reuse API; `book_repository.dart` (update path)
- `lib/features/settings/presentation/screens/settings_screen.dart` (ListView, pushed), `widgets/security_section.dart`, `appearance_section.dart`, `voice_section.dart` (existing 変更 pattern)
- `lib/features/home/presentation/screens/main_shell_screen.dart` — IndexedStack tabs; Settings is pushed
- `test/architecture/arb_key_parity_test.dart`, `test/architecture/hardcoded_cjk_ui_scan_test.dart`
- `.planning/sketches/001-onboarding-gate/index.html` — approved tone-A copy
- CONTEXT.md, REQUIREMENTS.md, 53-04-downstream-handoff.md

### Secondary / Tertiary
- None required — implementation phase verified entirely against the repository.

## Metadata

**Confidence breakdown:**
- Standard stack / integration symbols: HIGH — every symbol read in source this session.
- Persistence model (Finding #1): HIGH — `settings_repository_impl.dart` is unambiguous SharedPreferences.
- D-05/D-06 gaps (Findings #4/#5): HIGH — read the exact use cases.
- Deep-link mechanism (Finding #7): MEDIUM — confirmed Settings is a pushed plain ListView; exact scroll-anchor approach is discretion (multiple valid implementations).
- Pitfalls: HIGH.

**Research date:** 2026-06-29
**Valid until:** 2026-07-29 (stable in-repo surface; re-verify if Phase 55 lands before planning)
