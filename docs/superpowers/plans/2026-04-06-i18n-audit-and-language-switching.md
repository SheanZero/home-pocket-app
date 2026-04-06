# i18n Full Audit & Language Switching Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Audit all ~668 translation keys across ja/zh/en, fix bugs, export to CSV, and add a working language switching UI in Settings.

**Architecture:** Leverage existing `LocaleNotifier` + `SettingsRepository` + `AppSettings.language` infrastructure. Wire them together with persistence, add a radio dialog in Appearance section matching the existing Theme dialog pattern.

**Tech Stack:** Flutter, Riverpod 2.4+ (`@riverpod` codegen), Freezed, flutter_localizations + ARB, SharedPreferences, Dart `dart:convert` for CSV generation.

**Spec:** `docs/superpowers/specs/2026-04-05-i18n-audit-and-language-switching-design.md`

---

## Task 1: Export ARB Files to Unified CSV

**Files:**
- Create: `scripts/arb_to_csv.dart` (one-time Dart script)
- Create: `docs/i18n/translations.csv`

- [ ] **Step 1: Create the ARB-to-CSV export script**

```dart
// scripts/arb_to_csv.dart
import 'dart:convert';
import 'dart:io';

void main() {
  final enFile = File('lib/l10n/app_en.arb');
  final jaFile = File('lib/l10n/app_ja.arb');
  final zhFile = File('lib/l10n/app_zh.arb');

  final en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  final ja = jsonDecode(jaFile.readAsStringSync()) as Map<String, dynamic>;
  final zh = jsonDecode(zhFile.readAsStringSync()) as Map<String, dynamic>;

  // Collect all translation keys (skip metadata keys starting with @)
  final allKeys = <String>{
    ...en.keys.where((k) => !k.startsWith('@')),
    ...ja.keys.where((k) => !k.startsWith('@')),
    ...zh.keys.where((k) => !k.startsWith('@')),
  };
  final sortedKeys = allKeys.toList()..sort();

  final buffer = StringBuffer();
  buffer.writeln('key,en,ja,zh,notes');
  for (final key in sortedKeys) {
    final enVal = _escapeCsv(en[key]?.toString() ?? '');
    final jaVal = _escapeCsv(ja[key]?.toString() ?? '');
    final zhVal = _escapeCsv(zh[key]?.toString() ?? '');
    buffer.writeln('$key,$enVal,$jaVal,$zhVal,');
  }

  final outDir = Directory('docs/i18n');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);
  File('docs/i18n/translations.csv').writeAsStringSync(buffer.toString());
  print('Exported ${sortedKeys.length} keys to docs/i18n/translations.csv');
}

String _escapeCsv(String value) {
  if (value.contains(',') || value.contains('"') || value.contains('\n')) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
```

- [ ] **Step 2: Run the export script**

Run: `dart run scripts/arb_to_csv.dart`
Expected: `Exported NNN keys to docs/i18n/translations.csv`

- [ ] **Step 3: Verify CSV output**

Run: `head -10 docs/i18n/translations.csv && echo "---" && wc -l docs/i18n/translations.csv`
Expected: CSV with header row `key,en,ja,zh,notes` followed by translation rows. Line count should be ~668+1 (header).

- [ ] **Step 4: Commit**

```bash
git add scripts/arb_to_csv.dart docs/i18n/translations.csv
git commit -m "chore: export ARB translations to unified CSV for audit"
```

---

## Task 2: Audit Translations and Fix ARB Bugs

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `docs/i18n/translations.csv`

**Reference docs:**
- `docs/superpowers/specs/2026-04-05-i18n-audit-and-language-switching-design.md` — Part 1 Known Bugs table

This task requires a human-assisted review. The agentic worker should:

- [ ] **Step 1: Review CSV for wrong-language entries**

Open `docs/i18n/translations.csv` and scan for:
- Japanese (ja) column containing Chinese characters where Japanese is expected (known bug: `addTransaction` has `"添加账目"` which is Chinese)
- English literals in ja/zh columns (known bug: `next` is `"Next"` in ja and zh)
- Any other cross-language contamination

Flag issues in the `notes` column.

- [ ] **Step 2: Fix known bugs in ARB files**

Fix `app_ja.arb`:
```json
"addTransaction": "取引を追加",
```
(was `"添加账目"` — Chinese)

Fix `app_ja.arb`:
```json
"next": "次へ",
```
(was `"Next"` — English)

Fix `app_zh.arb`:
```json
"next": "下一步",
```
(was `"Next"` — English)

- [ ] **Step 3: Review all remaining keys systematically**

Go through the CSV row by row. For each key, verify:
1. The ja value is natural Japanese (not Chinese, not English)
2. The zh value is natural Simplified Chinese (not Japanese, not English)
3. The en value is natural English
4. All three convey the same meaning

Document any additional fixes in the `notes` column.

- [ ] **Step 4: Apply all fixes to ARB files**

After completing the CSV review, apply all corrections to the 3 ARB files.

- [ ] **Step 5: Re-export CSV to capture final state**

Run: `dart run scripts/arb_to_csv.dart`

- [ ] **Step 6: Run code generation and verify**

Run: `flutter gen-l10n`
Expected: No errors. If errors appear, it means a key is missing from one locale file — fix it.

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb docs/i18n/translations.csv
git commit -m "fix: audit and correct translation errors across all ARB files"
```

---

## Task 3: Add Missing ARB Keys for Hardcoded Strings

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Add new keys to `app_en.arb`**

Add these entries (place near related existing keys):

```json
"error": "Error",
"@error": { "description": "Generic error title for error screens" },

"initializationError": "Initialization failed: {error}",
"@initializationError": {
  "description": "Error message when app initialization fails",
  "placeholders": {
    "error": { "type": "String" }
  }
},

"listTab": "List",
"@listTab": { "description": "List tab label in bottom navigation" },

"todoTab": "Todo",
"@todoTab": { "description": "Todo tab label in bottom navigation" },

"datePickerComingSoon": "Date picker coming soon",
"@datePickerComingSoon": { "description": "Placeholder message for date picker feature" },

"selectLanguage": "Select Language",
"@selectLanguage": { "description": "Title of language selection dialog" },

"languageSystem": "Follow System",
"@languageSystem": { "description": "Option to follow system language setting" }
```

- [ ] **Step 2: Add corresponding keys to `app_ja.arb`**

```json
"error": "エラー",
"initializationError": "初期化に失敗しました: {error}",
"listTab": "リスト",
"todoTab": "やること",
"datePickerComingSoon": "日付選択は近日公開",
"selectLanguage": "言語を選択",
"languageSystem": "システム設定に従う"
```

- [ ] **Step 3: Add corresponding keys to `app_zh.arb`**

```json
"error": "错误",
"initializationError": "初始化失败: {error}",
"listTab": "列表",
"todoTab": "待办",
"datePickerComingSoon": "日期选择即将推出",
"selectLanguage": "选择语言",
"languageSystem": "跟随系统设置"
```

- [ ] **Step 4: Run code generation**

Run: `flutter gen-l10n`
Expected: No errors, generated files updated with new keys.

- [ ] **Step 5: Run existing tests to verify nothing broken**

Run: `flutter test`
Expected: All existing tests pass.

- [ ] **Step 6: Re-export CSV**

Run: `dart run scripts/arb_to_csv.dart`

- [ ] **Step 7: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb docs/i18n/translations.csv
git commit -m "feat: add missing i18n keys for hardcoded UI strings"
```

---

## Task 4: Replace Hardcoded Strings in UI Code

**Files:**
- Modify: `lib/main.dart:178-182`
- Modify: `lib/features/home/presentation/screens/main_shell_screen.dart:73-77`
- Modify: `lib/features/home/presentation/screens/home_screen.dart:71-76`

- [ ] **Step 1: Replace hardcoded strings in `lib/main.dart`**

Find the `_buildHome()` method around line 178. Replace:

```dart
// BEFORE
appBar: AppBar(title: const Text('Error')),
body: Center(child: Text(_error!)),
```

With:

```dart
// AFTER
appBar: AppBar(title: Text(S.of(context).error)),
body: Center(child: Text(S.of(context).initializationError(error: _error!))),
```

**Note:** The `_buildHome` method is inside a `Builder` or has access to a `BuildContext` that has `S` in scope because it's below `MaterialApp` with the localization delegates. If `S.of(context)` is not available at this level (because the error screen is the `home:` of `MaterialApp`), wrap it in a `Builder`:

```dart
home: Builder(
  builder: (context) => _buildHome(context),
),
```

And change `_buildHome` to accept `BuildContext context`. Check the actual code structure before editing.

- [ ] **Step 2: Replace hardcoded strings in `main_shell_screen.dart`**

Find the placeholder tabs around line 73-77. Replace:

```dart
// BEFORE
const Center(child: Text('List')),
// ...
const Center(child: Text('Todo')),
```

With:

```dart
// AFTER
Center(child: Text(S.of(context).listTab)),
// ...
Center(child: Text(S.of(context).todoTab)),
```

**Note:** Remove `const` since `S.of(context)` is not a compile-time constant.

- [ ] **Step 3: Replace hardcoded string in `home_screen.dart`**

Find the SnackBar around line 73. Replace:

```dart
// BEFORE
content: Text('Date picker coming soon'),
```

With:

```dart
// AFTER
content: Text(S.of(context).datePickerComingSoon),
```

**Note:** Remove `const` from the `SnackBar` constructor if it was `const`.

- [ ] **Step 4: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 5: Run tests**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 6: Commit**

```bash
git add lib/main.dart lib/features/home/presentation/screens/main_shell_screen.dart lib/features/home/presentation/screens/home_screen.dart
git commit -m "fix: replace hardcoded UI strings with localized equivalents"
```

---

## Task 5: Wire LocaleNotifier to SettingsRepository (TDD)

**Files:**
- Modify: `lib/features/settings/presentation/providers/locale_provider.dart`
- Modify: `test/unit/features/settings/presentation/providers/locale_provider_test.dart`

**Key context:**
- `LocaleNotifier` is a Riverpod `@riverpod` auto-dispose notifier
- `settingsRepositoryProvider` is a SYNC provider that returns `SettingsRepository` directly (not `Future`). It internally uses `ref.watch(sharedPreferencesProvider).requireValue` — SharedPreferences must be resolved first, but the provider itself is sync.
- `SettingsRepository.setLanguage(String)` persists to SharedPreferences (async, returns `Future<void>`)
- `SettingsRepository.getSettings()` returns `Future<AppSettings>` with `.language` field
- The notifier currently has no access to the repository
- In `build()`, use `ref.watch(settingsRepositoryProvider)` directly (no `.future` or `.requireValue` needed on this provider)

- [ ] **Step 1: Write failing tests for persisted locale**

Replace the entire test file `test/unit/features/settings/presentation/providers/locale_provider_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to create a ProviderContainer with real SharedPreferences.
Future<ProviderContainer> createTestContainer({
  Map<String, Object> initialValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(initialValues);
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
    ],
  );
}

void main() {
  group('LocaleNotifier', () {
    test('initial state reads persisted language from settings', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'en'},
      );
      addTearDown(container.dispose);

      // Wait for async initialization
      await container.read(localeNotifierProvider.future);
      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.locale, const Locale('en'));
      expect(settings.isSystemDefault, isFalse);
    });

    test('initial state defaults to system when no persisted value', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      final settings = await container.read(localeNotifierProvider.future);
      // 'system' is the new default — resolves to device locale (ja fallback in test)
      expect(settings.isSystemDefault, isTrue);
      expect(settings.locale, const Locale('ja'));
    });

    test('initial state handles system value', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'system'},
      );
      addTearDown(container.dispose);

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.isSystemDefault, isTrue);
    });

    test('setLocale persists language and updates state', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await container.read(localeNotifierProvider.future);
      await container
          .read(localeNotifierProvider.notifier)
          .setLocale(const Locale('zh'));

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.locale, const Locale('zh'));
      expect(settings.isSystemDefault, isFalse);

      // Verify persistence
      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString('language'), 'zh');
    });

    test('setSystemDefault persists system and updates state', () async {
      final container = await createTestContainer();
      addTearDown(container.dispose);

      await container.read(localeNotifierProvider.future);
      await container
          .read(localeNotifierProvider.notifier)
          .setSystemDefault();

      final settings = await container.read(localeNotifierProvider.future);
      expect(settings.isSystemDefault, isTrue);

      // Verify persistence
      final prefs = await container.read(sharedPreferencesProvider.future);
      expect(prefs.getString('language'), 'system');
    });
  });

  group('currentLocaleProvider', () {
    test('returns locale from LocaleNotifier', () async {
      final container = await createTestContainer(
        initialValues: {'language': 'en'},
      );
      addTearDown(container.dispose);

      final locale = await container.read(currentLocaleProvider.future);
      expect(locale, const Locale('en'));
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/features/settings/presentation/providers/locale_provider_test.dart`
Expected: FAIL — `localeNotifierProvider` is not async, tests expect `.future`.

- [ ] **Step 3: Implement persisted LocaleNotifier**

Replace `lib/features/settings/presentation/providers/locale_provider.dart`:

```dart
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../infrastructure/i18n/models/locale_settings.dart';
import 'repository_providers.dart';

part 'locale_provider.g.dart';

/// Manages the current locale settings for the app.
///
/// Reads persisted language from [SettingsRepository] on startup.
/// Persists changes via [SettingsRepository.setLanguage()].
@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  @override
  Future<LocaleSettings> build() async {
    final repo = ref.watch(settingsRepositoryProvider);
    final settings = await repo.getSettings();
    final language = settings.language;

    if (language == 'system') {
      final systemLocale = PlatformDispatcher.instance.locale;
      return LocaleSettings.fromSystem(systemLocale);
    }

    return LocaleSettings(
      locale: Locale(language),
      isSystemDefault: false,
    );
  }

  /// Set the locale explicitly (not system default). Persists the choice.
  Future<void> setLocale(Locale locale) async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setLanguage(locale.languageCode);
    state = AsyncData(
      LocaleSettings(locale: locale, isSystemDefault: false),
    );
  }

  /// Use the system locale. Persists 'system' as the language value.
  Future<void> setSystemDefault() async {
    final repo = ref.read(settingsRepositoryProvider);
    await repo.setLanguage('system');
    final systemLocale = PlatformDispatcher.instance.locale;
    state = AsyncData(LocaleSettings.fromSystem(systemLocale));
  }
}

/// Convenience provider that extracts just the [Locale] from [LocaleNotifier].
@riverpod
Future<Locale> currentLocale(Ref ref) async {
  final settings = await ref.watch(localeNotifierProvider.future);
  return settings.locale;
}
```

**IMPORTANT:** This changes the provider from sync to async (`LocaleSettings` → `Future<LocaleSettings>`). The `currentLocaleProvider` also becomes async. This impacts `main.dart` where `ref.watch(currentLocaleProvider)` is used — that will be addressed in Task 6.

- [ ] **Step 4: Run build_runner to regenerate provider code**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates new `.g.dart` files for the async notifier.

- [ ] **Step 5: Run tests to verify they pass**

Run: `flutter test test/unit/features/settings/presentation/providers/locale_provider_test.dart`
Expected: All tests PASS.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/providers/locale_provider.dart lib/features/settings/presentation/providers/locale_provider.g.dart test/unit/features/settings/presentation/providers/locale_provider_test.dart
git commit -m "feat: wire LocaleNotifier to SettingsRepository for persisted language"
```

---

## Task 6: Update main.dart for Async Locale Provider

**Files:**
- Modify: `lib/main.dart`

**Key context:**
- `currentLocaleProvider` is now `Future<Locale>` (was sync `Locale`)
- `main.dart` currently does `final locale = ref.watch(currentLocaleProvider);`
- Need to handle the async state: show the app once locale is resolved, use Japanese as loading fallback

- [ ] **Step 1: Update locale watch in main.dart**

Find where `currentLocaleProvider` is watched (in the `build` method of the app widget). Change from:

```dart
final locale = ref.watch(currentLocaleProvider);
```

To:

```dart
final localeAsync = ref.watch(currentLocaleProvider);
final locale = localeAsync.valueOrNull ?? const Locale('ja');
```

This uses Japanese as a fallback while SharedPreferences is loading (typically <1 frame).

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass. Some existing tests may need updates if they use `currentLocaleProvider` directly — fix any failures.

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart
git commit -m "fix: handle async locale provider in MaterialApp"
```

---

## Task 7: Change AppSettings Default Language (TDD)

**Files:**
- Modify: `lib/features/settings/domain/models/app_settings.dart`
- Modify: `lib/data/repositories/settings_repository_impl.dart:23`
- Modify: `test/unit/features/settings/domain/models/app_settings_test.dart`
- Modify: `test/unit/data/repositories/settings_repository_impl_test.dart`

- [ ] **Step 1: Update tests to expect new default**

In `test/unit/features/settings/domain/models/app_settings_test.dart`, find the test for default language and change expected value from `'ja'` to `'system'`.

In `test/unit/data/repositories/settings_repository_impl_test.dart`, find line 20:
```dart
expect(settings.language, 'ja');
```
Change to:
```dart
expect(settings.language, 'system');
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `flutter test test/unit/features/settings/domain/models/app_settings_test.dart test/unit/data/repositories/settings_repository_impl_test.dart`
Expected: FAIL — defaults still return `'ja'`.

- [ ] **Step 3: Change default in AppSettings model**

In `lib/features/settings/domain/models/app_settings.dart`, change:

```dart
@Default('ja') String language,
```

To:

```dart
@Default('system') String language,
```

- [ ] **Step 4: Change fallback in SettingsRepositoryImpl**

In `lib/data/repositories/settings_repository_impl.dart`, line 23, change:

```dart
language: _prefs.getString(_languageKey) ?? 'ja',
```

To:

```dart
language: _prefs.getString(_languageKey) ?? 'system',
```

- [ ] **Step 5: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run tests to verify they pass**

Run: `flutter test test/unit/features/settings/domain/models/app_settings_test.dart test/unit/data/repositories/settings_repository_impl_test.dart`
Expected: All PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/domain/models/app_settings.dart lib/features/settings/domain/models/app_settings.freezed.dart lib/features/settings/domain/models/app_settings.g.dart lib/data/repositories/settings_repository_impl.dart test/unit/features/settings/domain/models/app_settings_test.dart test/unit/data/repositories/settings_repository_impl_test.dart
git commit -m "feat: change default language to system for new installs"
```

---

## Task 8: Add Language Picker UI to Appearance Section (TDD)

**Files:**
- Modify: `lib/features/settings/presentation/widgets/appearance_section.dart`
- Create: `test/widget/features/settings/presentation/widgets/appearance_section_test.dart`

**Key context:**
- `AppearanceSection` is a `ConsumerWidget` that takes `AppSettings settings`
- Theme dialog uses `AlertDialog` + `RadioListTile` pattern
- Language names are hardcoded constants (not ARB) — shown in their own language
- `LocaleNotifier` is now async, so need `ref.watch(localeNotifierProvider)` which returns `AsyncValue<LocaleSettings>`
- `selectLanguage` and `languageSystem` keys were added in Task 3

- [ ] **Step 1: Write widget test for language tile**

Create `test/widget/features/settings/presentation/widgets/appearance_section_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/locale_provider.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/widgets/appearance_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/i18n/models/locale_settings.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildTestWidget({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: S.localizationsDelegates,
      supportedLocales: S.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('AppearanceSection', () {
    late List<Override> overrides;

    setUp(() async {
      SharedPreferences.setMockInitialValues({'language': 'ja'});
      final prefs = await SharedPreferences.getInstance();
      overrides = [
        sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
        settingsRepositoryProvider.overrideWith(
          (_) => SettingsRepositoryImpl(prefs: prefs),
        ),
      ];
    });

    testWidgets('shows language tile with current language', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: overrides,
          child: const AppearanceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      // Find the language tile
      expect(find.text('Language'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('tapping language tile opens selection dialog', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          overrides: overrides,
          child: const AppearanceSection(settings: AppSettings()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the language tile
      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // Verify dialog shows all 4 options
      expect(find.text('Select Language'), findsOneWidget);
      expect(find.text('Follow System'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
      expect(find.text('中文'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/widget/features/settings/presentation/widgets/appearance_section_test.dart`
Expected: FAIL — no language tile exists yet.

- [ ] **Step 3: Implement language picker in AppearanceSection**

Replace `lib/features/settings/presentation/widgets/appearance_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/app_settings.dart';
import '../providers/locale_provider.dart';
import '../providers/repository_providers.dart';
import '../providers/settings_providers.dart';

/// Language option with a fixed display name (always in its own language).
class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.nativeName,
    this.isSystem = false,
  });

  final String code;
  final String nativeName;
  final bool isSystem;
}

class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key, required this.settings});

  final AppSettings settings;

  static const _languageOptions = [
    _LanguageOption(code: 'ja', nativeName: '日本語'),
    _LanguageOption(code: 'zh', nativeName: '中文'),
    _LanguageOption(code: 'en', nativeName: 'English'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(localeNotifierProvider);
    final currentLocaleSettings = localeAsync.valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            S.of(context).appearance,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text(S.of(context).theme),
          subtitle: Text(_getThemeModeLabel(settings.themeMode, context)),
          onTap: () => _showThemeModeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.language),
          title: Text(S.of(context).language),
          subtitle: Text(_getLanguageSubtitle(currentLocaleSettings, context)),
          onTap: () => _showLanguageDialog(context, ref, currentLocaleSettings),
        ),
      ],
    );
  }

  String _getLanguageSubtitle(
    LocaleSettings? localeSettings,
    BuildContext context,
  ) {
    if (localeSettings == null) return '';
    if (localeSettings.isSystemDefault) {
      final resolvedName = _nativeNameForCode(
        localeSettings.locale.languageCode,
      );
      return '${S.of(context).languageSystem} ($resolvedName)';
    }
    return _nativeNameForCode(localeSettings.locale.languageCode);
  }

  String _nativeNameForCode(String code) {
    for (final option in _languageOptions) {
      if (option.code == code) return option.nativeName;
    }
    return code;
  }

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    LocaleSettings? currentSettings,
  ) {
    // Determine current selection value
    final currentValue =
        currentSettings?.isSystemDefault == true
            ? 'system'
            : (currentSettings?.locale.languageCode ?? 'ja');

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(S.of(context).selectLanguage),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // System Default option
              RadioListTile<String>(
                title: Text(S.of(context).languageSystem),
                value: 'system',
                groupValue: currentValue,
                onChanged: (value) async {
                  if (value != null) {
                    await ref
                        .read(localeNotifierProvider.notifier)
                        .setSystemDefault();
                    ref.invalidate(appSettingsProvider);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  }
                },
              ),
              // Explicit language options
              ..._languageOptions.map((option) {
                return RadioListTile<String>(
                  title: Text(option.nativeName),
                  value: option.code,
                  groupValue: currentValue,
                  onChanged: (value) async {
                    if (value != null) {
                      await ref
                          .read(localeNotifierProvider.notifier)
                          .setLocale(Locale(value));
                      ref.invalidate(appSettingsProvider);
                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(S.of(context).selectTheme),
        content: RadioGroup<AppThemeMode>(
          groupValue: settings.themeMode,
          onChanged: (value) async {
            if (value != null) {
              await ref.read(settingsRepositoryProvider).setThemeMode(value);
              ref.invalidate(appSettingsProvider);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppThemeMode.values.map((mode) {
              return RadioListTile<AppThemeMode>(
                title: Text(_getThemeModeLabel(mode, context)),
                value: mode,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  String _getThemeModeLabel(AppThemeMode mode, BuildContext context) {
    switch (mode) {
      case AppThemeMode.system:
        return S.of(context).themeSystem;
      case AppThemeMode.light:
        return S.of(context).themeLight;
      case AppThemeMode.dark:
        return S.of(context).themeDark;
    }
  }
}
```

**Note:** The `import` for `LocaleSettings` is needed — add:
```dart
import '../../../../infrastructure/i18n/models/locale_settings.dart';
```

**IMPORTANT:** The existing theme dialog uses `RadioGroup<AppThemeMode>` — a custom widget already in the codebase. Do NOT change the theme dialog code. Only ADD the new `_showLanguageDialog` method and the new language `ListTile`. The replacement code above shows the complete file — the theme dialog portion MUST match the existing `appearance_section.dart` exactly. Read the current file first and preserve its theme dialog implementation verbatim.

- [ ] **Step 4: Run tests to verify they pass**

Run: `flutter test test/widget/features/settings/presentation/widgets/appearance_section_test.dart`
Expected: All PASS.

- [ ] **Step 5: Run full analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/presentation/widgets/appearance_section.dart test/widget/features/settings/presentation/widgets/appearance_section_test.dart
git commit -m "feat: add language picker UI in Settings > Appearance"
```

---

## Task 9: Full Integration Verification

**Files:** None (verification only)

- [ ] **Step 1: Run full test suite**

Run: `flutter test`
Expected: All tests pass.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues.

- [ ] **Step 3: Run code generation (ensure everything is in sync)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter gen-l10n`
Expected: No errors.

- [ ] **Step 4: Final CSV export**

Run: `dart run scripts/arb_to_csv.dart`
Expected: Updated CSV with all new keys included.

- [ ] **Step 5: Run test coverage**

Run: `flutter test --coverage && lcov --summary coverage/lcov.info`
Expected: ≥80% coverage.

- [ ] **Step 6: Commit any remaining changes**

Only commit if there are actual changes (e.g., regenerated files). Stage specific files:

```bash
git status
# Stage only relevant changed files
git add docs/i18n/translations.csv
git commit -m "chore: final verification — all tests pass, coverage meets threshold"
```

---

## Task Summary

| Task | Description | Type |
|------|-------------|------|
| 1 | Export ARB files to unified CSV | Tooling |
| 2 | Audit translations and fix ARB bugs | Audit / Fix |
| 3 | Add missing ARB keys for hardcoded strings | i18n |
| 4 | Replace hardcoded strings in UI code | Fix |
| 5 | Wire LocaleNotifier to SettingsRepository (TDD) | Feature |
| 6 | Update main.dart for async locale provider | Fix |
| 7 | Change AppSettings default language (TDD) | Feature |
| 8 | Add language picker UI to Appearance section (TDD) | Feature |
| 9 | Full integration verification | Verification |

**Dependencies:** Tasks 1→2→3→4 (sequential ARB work). Tasks 5→6 (async provider change). Task 7 independent. Task 8 depends on 3+5. Task 9 is final.

**Parallel opportunities:** Tasks 5+7 can run in parallel. Tasks 3+5 can run in parallel if careful about merge.
