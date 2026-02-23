# Voice Language Setting Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 在 Settings 中增加独立的语音识别语言设置，支持持久化存储，语音输入实时切换。

**Architecture:** 在现有 `AppSettings` 模型中增加 `voiceLanguage` 字段（独立于 UI 语言），通过 SharedPreferences 持久化；新建 `voiceLanguageProvider` 提供 BCP-47 locale ID；`VoiceInputScreen` 改为读取该 provider；Settings 新增 `VoiceSection` widget。

**Tech Stack:** Flutter · Riverpod (`@riverpod`) · Freezed · SharedPreferences · `speech_to_text`

---

## 背景知识

- `AppSettings` 在 `lib/features/settings/domain/models/app_settings.dart`，是 Freezed 模型，包含 `language`（UI语言）字段
- `SettingsRepositoryImpl` 在 `lib/data/repositories/settings_repository_impl.dart`，用 SharedPreferences 持久化
- `SettingsRepository`（接口）在 `lib/features/settings/domain/repositories/settings_repository.dart`
- `VoiceInputScreen` 目前在 `_startRecording()` 里读 `currentLocaleProvider`（UI 语言）来决定语音语言——这是要改的
- Settings 界面由多个 section widget 组成，新 widget 仿照 `AppearanceSection` 的模式
- ARB 文件在 `lib/l10n/app_{zh,ja,en}.arb`，改后需 `flutter gen-l10n`
- 修改 Freezed 模型后需运行 `flutter pub run build_runner build --delete-conflicting-outputs`

---

## Task 1: 扩展 AppSettings 模型，增加 voiceLanguage 字段

**Files:**
- Modify: `lib/features/settings/domain/models/app_settings.dart`
- Test: `test/unit/features/settings/domain/models/app_settings_test.dart`（新建）

**Step 1: 写失败测试**

新建 `test/unit/features/settings/domain/models/app_settings_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';

void main() {
  group('AppSettings.voiceLanguage', () {
    test('default voiceLanguage is zh', () {
      const settings = AppSettings();
      expect(settings.voiceLanguage, 'zh');
    });

    test('copyWith preserves voiceLanguage', () {
      const settings = AppSettings(voiceLanguage: 'ja');
      final updated = settings.copyWith(themeMode: AppThemeMode.dark);
      expect(updated.voiceLanguage, 'ja');
    });

    test('fromJson/toJson round-trips voiceLanguage', () {
      const settings = AppSettings(voiceLanguage: 'en');
      final json = settings.toJson();
      final restored = AppSettings.fromJson(json);
      expect(restored.voiceLanguage, 'en');
    });
  });
}
```

**Step 2: 运行测试，确认失败**

```bash
flutter test test/unit/features/settings/domain/models/app_settings_test.dart --no-pub
```

Expected: FAIL — `The getter 'voiceLanguage' isn't defined`

**Step 3: 修改 AppSettings**

在 `lib/features/settings/domain/models/app_settings.dart` 的 `const factory AppSettings(...)` 中增加字段：

```dart
@freezed
abstract class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(AppThemeMode.system) AppThemeMode themeMode,
    @Default('ja') String language,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool biometricLockEnabled,
    @Default('zh') String voiceLanguage,   // ← 新增
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
```

**Step 4: 重新生成代码**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: 无错误，`app_settings.freezed.dart` 和 `app_settings.g.dart` 更新

**Step 5: 运行测试，确认通过**

```bash
flutter test test/unit/features/settings/domain/models/app_settings_test.dart --no-pub
```

Expected: PASS (3 tests)

**Step 6: Commit**

```bash
git add lib/features/settings/domain/models/app_settings.dart \
        lib/features/settings/domain/models/app_settings.freezed.dart \
        lib/features/settings/domain/models/app_settings.g.dart \
        test/unit/features/settings/domain/models/app_settings_test.dart
git commit -m "feat(settings): add voiceLanguage field to AppSettings"
```

---

## Task 2: 扩展 Repository 接口和实现，持久化 voiceLanguage

**Files:**
- Modify: `lib/features/settings/domain/repositories/settings_repository.dart`
- Modify: `lib/data/repositories/settings_repository_impl.dart`
- Test: `test/unit/data/repositories/settings_repository_impl_voice_test.dart`（新建）

**Step 1: 写失败测试**

新建 `test/unit/data/repositories/settings_repository_impl_voice_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';

void main() {
  group('SettingsRepositoryImpl - voiceLanguage', () {
    late SettingsRepositoryImpl repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      repo = SettingsRepositoryImpl(prefs: prefs);
    });

    test('getSettings returns default voiceLanguage zh', () async {
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'zh');
    });

    test('setVoiceLanguage persists and getSettings reflects change', () async {
      await repo.setVoiceLanguage('ja');
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'ja');
    });

    test('updateSettings persists voiceLanguage', () async {
      await repo.updateSettings(
        const AppSettings(voiceLanguage: 'en'),   // need import
      );
      final settings = await repo.getSettings();
      expect(settings.voiceLanguage, 'en');
    });
  });
}
```

（在文件顶部加 import：`import 'package:home_pocket/features/settings/domain/models/app_settings.dart';`）

**Step 2: 运行测试，确认失败**

```bash
flutter test test/unit/data/repositories/settings_repository_impl_voice_test.dart --no-pub
```

Expected: FAIL — `The method 'setVoiceLanguage' isn't defined`

**Step 3: 更新 SettingsRepository 接口**

在 `lib/features/settings/domain/repositories/settings_repository.dart` 增加方法：

```dart
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
  Future<void> setVoiceLanguage(String languageCode);  // ← 新增
}
```

**Step 4: 更新 SettingsRepositoryImpl**

在 `lib/data/repositories/settings_repository_impl.dart` 中：

1. 增加常量：
```dart
static const String _voiceLanguageKey = 'voice_language';
```

2. `getSettings()` 中增加字段：
```dart
return AppSettings(
  themeMode: _getThemeMode(),
  language: _prefs.getString(_languageKey) ?? 'ja',
  notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
  biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
  voiceLanguage: _prefs.getString(_voiceLanguageKey) ?? 'zh',  // ← 新增
);
```

3. `updateSettings()` 中增加：
```dart
await _prefs.setString(_voiceLanguageKey, settings.voiceLanguage);
```

4. 新增方法：
```dart
@override
Future<void> setVoiceLanguage(String languageCode) async {
  await _prefs.setString(_voiceLanguageKey, languageCode);
}
```

**Step 5: 运行测试，确认通过**

```bash
flutter test test/unit/data/repositories/settings_repository_impl_voice_test.dart --no-pub
```

Expected: PASS (3 tests)

**Step 6: Commit**

```bash
git add lib/features/settings/domain/repositories/settings_repository.dart \
        lib/data/repositories/settings_repository_impl.dart \
        test/unit/data/repositories/settings_repository_impl_voice_test.dart
git commit -m "feat(settings): persist voiceLanguage via SettingsRepository"
```

---

## Task 3: 创建 voiceLanguageProvider

此 provider 读取持久化的 voiceLanguage，转换为 speech_to_text 需要的 BCP-47 字符串（如 `zh-CN`）。

**Files:**
- Modify: `lib/features/settings/presentation/providers/settings_providers.dart`
- Test: `test/unit/features/settings/presentation/providers/voice_language_provider_test.dart`（新建）

**Step 1: 写失败测试**

新建 `test/unit/features/settings/presentation/providers/voice_language_provider_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket/features/settings/presentation/providers/settings_providers.dart';

void main() {
  group('voiceLocaleIdProvider', () {
    test('zh maps to zh-CN', () {
      expect(voiceLocaleIdFromLanguageCode('zh'), 'zh-CN');
    });

    test('ja maps to ja-JP', () {
      expect(voiceLocaleIdFromLanguageCode('ja'), 'ja-JP');
    });

    test('en maps to en-US', () {
      expect(voiceLocaleIdFromLanguageCode('en'), 'en-US');
    });

    test('unknown code defaults to zh-CN', () {
      expect(voiceLocaleIdFromLanguageCode('fr'), 'zh-CN');
    });
  });
}
```

**Step 2: 运行测试，确认失败**

```bash
flutter test test/unit/features/settings/presentation/providers/voice_language_provider_test.dart --no-pub
```

Expected: FAIL — `voiceLocaleIdFromLanguageCode` not found

**Step 3: 实现**

在 `lib/features/settings/presentation/providers/settings_providers.dart` 增加：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/app_settings.dart';
import 'repository_providers.dart';

part 'settings_providers.g.dart';

/// Current app settings (async because SharedPreferences is async).
@riverpod
Future<AppSettings> appSettings(Ref ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
}

/// The BCP-47 locale ID to use for voice recognition.
///
/// Reads from persisted [AppSettings.voiceLanguage] and converts to
/// the format expected by speech_to_text (e.g. 'zh-CN').
@riverpod
Future<String> voiceLocaleId(Ref ref) async {
  final settings = await ref.watch(appSettingsProvider.future);
  return voiceLocaleIdFromLanguageCode(settings.voiceLanguage);
}

/// Converts a language code to a BCP-47 locale ID for speech recognition.
/// Public for testing.
String voiceLocaleIdFromLanguageCode(String code) {
  switch (code) {
    case 'zh':
      return 'zh-CN';
    case 'ja':
      return 'ja-JP';
    case 'en':
      return 'en-US';
    default:
      return 'zh-CN';
  }
}
```

**Step 4: 重新生成代码**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

**Step 5: 运行测试，确认通过**

```bash
flutter test test/unit/features/settings/presentation/providers/voice_language_provider_test.dart --no-pub
```

Expected: PASS (4 tests)

**Step 6: Commit**

```bash
git add lib/features/settings/presentation/providers/settings_providers.dart \
        lib/features/settings/presentation/providers/settings_providers.g.dart \
        test/unit/features/settings/presentation/providers/voice_language_provider_test.dart
git commit -m "feat(settings): add voiceLocaleIdProvider for speech recognition locale"
```

---

## Task 4: 更新 ARB 国际化字符串

**Files:**
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`

**Step 1: 在 app_zh.arb 末尾 `}` 前添加**

```json
  "voiceInputSettings": "语音识别",
  "@voiceInputSettings": {
    "description": "Voice input settings section title"
  },
  "voiceLanguage": "识别语言",
  "@voiceLanguage": {
    "description": "Voice recognition language setting label"
  },
  "voiceLanguageSubtitle": "语音转文字所使用的语言",
  "@voiceLanguageSubtitle": {
    "description": "Subtitle for voice language setting"
  }
```

**Step 2: 在 app_ja.arb 末尾 `}` 前添加**

```json
  "voiceInputSettings": "音声認識",
  "@voiceInputSettings": {
    "description": "Voice input settings section title"
  },
  "voiceLanguage": "認識言語",
  "@voiceLanguage": {
    "description": "Voice recognition language setting label"
  },
  "voiceLanguageSubtitle": "音声入力に使用する言語",
  "@voiceLanguageSubtitle": {
    "description": "Subtitle for voice language setting"
  }
```

**Step 3: 在 app_en.arb 末尾 `}` 前添加**

```json
  "voiceInputSettings": "Voice Recognition",
  "@voiceInputSettings": {
    "description": "Voice input settings section title"
  },
  "voiceLanguage": "Recognition Language",
  "@voiceLanguage": {
    "description": "Voice recognition language setting label"
  },
  "voiceLanguageSubtitle": "Language used for speech-to-text",
  "@voiceLanguageSubtitle": {
    "description": "Subtitle for voice language setting"
  }
```

**Step 4: 生成本地化文件**

```bash
flutter gen-l10n
```

Expected: 无错误，`lib/generated/app_localizations*.dart` 更新

**Step 5: 运行 analyze 确认无报错**

```bash
flutter analyze
```

Expected: `No issues found!`

**Step 6: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(i18n): add voice recognition settings strings (zh/ja/en)"
```

---

## Task 5: 创建 VoiceSection widget 并加入 Settings 页

**Files:**
- Create: `lib/features/settings/presentation/widgets/voice_section.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

**Step 1: 创建 VoiceSection**

参考 `AppearanceSection` 的完整模式，创建 `lib/features/settings/presentation/widgets/voice_section.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_providers.dart';

/// Settings section for voice recognition configuration.
class VoiceSection extends ConsumerWidget {
  const VoiceSection({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).voiceInputSettings,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.mic),
          title: Text(S.of(context).voiceLanguage),
          subtitle: Text(_getLanguageLabel(settings.voiceLanguage, context)),
          onTap: () => _showLanguageDialog(context, ref),
        ),
      ],
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).voiceLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(S.of(context).languageChinese),
              value: 'zh',
              groupValue: settings.voiceLanguage,
              onChanged: (v) => _selectLanguage(v, ref, dialogContext),
            ),
            RadioListTile<String>(
              title: Text(S.of(context).languageJapanese),
              value: 'ja',
              groupValue: settings.voiceLanguage,
              onChanged: (v) => _selectLanguage(v, ref, dialogContext),
            ),
            RadioListTile<String>(
              title: Text(S.of(context).languageEnglish),
              value: 'en',
              groupValue: settings.voiceLanguage,
              onChanged: (v) => _selectLanguage(v, ref, dialogContext),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectLanguage(
    String? value,
    WidgetRef ref,
    BuildContext dialogContext,
  ) async {
    if (value == null) return;
    await ref.read(settingsRepositoryProvider).setVoiceLanguage(value);
    ref.invalidate(appSettingsProvider);
    if (dialogContext.mounted) Navigator.pop(dialogContext);
  }

  String _getLanguageLabel(String code, BuildContext context) {
    switch (code) {
      case 'zh':
        return S.of(context).languageChinese;
      case 'ja':
        return S.of(context).languageJapanese;
      case 'en':
        return S.of(context).languageEnglish;
      default:
        return code;
    }
  }
}
```

**Step 2: 将 VoiceSection 加入 SettingsScreen**

修改 `lib/features/settings/presentation/screens/settings_screen.dart`：

```dart
import '../widgets/voice_section.dart';   // ← 新增 import

// 在 ListView children 中增加（放在 AppearanceSection 和 DataManagementSection 之间）:
AppearanceSection(settings: settings),
const Divider(),
VoiceSection(settings: settings),         // ← 新增
const Divider(),
DataManagementSection(bookId: bookId),
```

**Step 3: 运行 analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

**Step 4: Commit**

```bash
git add lib/features/settings/presentation/widgets/voice_section.dart \
        lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(settings): add VoiceSection widget for voice language selection"
```

---

## Task 6: 将 VoiceInputScreen 改为读取 voiceLocaleIdProvider

**Files:**
- Modify: `lib/features/accounting/presentation/screens/voice_input_screen.dart`

**Step 1: 修改 `_startRecording()`**

当前代码（约第 138-140 行）：
```dart
final locale = ref.read(currentLocaleProvider);
final localeId = _localeIdFromLocale(locale);
```

改为：
```dart
// 读取用户单独设置的语音识别语言（async provider 用 requireValue 取同步值）
final localeId = ref.read(voiceLocaleIdProvider).valueOrNull ?? 'zh-CN';
```

**Step 2: 增加 import**

在文件顶部 import 区域增加：
```dart
import '../../../settings/presentation/providers/settings_providers.dart';
```

**Step 3: 删除不再需要的 `_localeIdFromLocale` 方法**

找到约第 279-290 行的方法并删除：
```dart
// 删除此方法（整个函数体）：
String _localeIdFromLocale(Locale locale) {
  switch (locale.languageCode) {
    ...
  }
}
```

同时检查 `currentLocaleProvider` 的 import 是否还被其他地方使用，如不再使用则删除该 import：
```dart
import '../../../settings/presentation/providers/locale_provider.dart';
```

**Step 4: 运行 analyze**

```bash
flutter analyze
```

Expected: `No issues found!`

**Step 5: 运行所有测试**

```bash
flutter test --no-pub
```

Expected: All tests pass (no regressions)

**Step 6: Commit**

```bash
git add lib/features/accounting/presentation/screens/voice_input_screen.dart
git commit -m "feat(voice): use voiceLocaleIdProvider for speech recognition locale"
```

---

## Task 7: 全量验证

**Step 1: 静态分析**

```bash
flutter analyze
```

Expected: `No issues found!`

**Step 2: 所有测试**

```bash
flutter test --no-pub
```

Expected: All tests pass

**Step 3: 人工验收检查清单**

- [ ] 打开 Settings → 可以看到「语音识别」section
- [ ] 点击「识别语言」→ 弹出对话框，显示三个语言选项，当前选项高亮
- [ ] 选择一种语言 → 对话框关闭，副标题更新为新语言名称
- [ ] 重启 App → Settings 中语言仍然是上次选择的语言（持久化验证）
- [ ] 进入语音输入 → 开始录音 → 语音识别使用 Settings 中设置的语言
- [ ] 更换语言后立即再次进入语音输入 → 使用新语言（实时切换验证）
