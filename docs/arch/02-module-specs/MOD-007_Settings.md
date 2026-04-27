# MOD-008: 设置管理 - 技术设计文档

**模块编号:** MOD-008
**模块名称:** 设置管理
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 6天
**优先级:** P0（MVP核心功能）
**依赖项:** MOD-006 (安全模块), MOD-001 (基础记账)

---

## 📋 目录

1. [模块概述](#模块概述)
2. [业务价值](#业务价值)
3. [核心功能](#核心功能)
4. [功能需求](#功能需求)
5. [技术设计](#技术设计)
6. [数据模型](#数据模型)
7. [核心实现流程](#核心实现流程)
8. [UI组件设计](#ui组件设计)
9. [测试策略](#测试策略)
10. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

设置管理模块提供全面的应用配置和数据管理功能:

- **应用偏好设置:** 主题、语言、货币、通知设置
- **数据备份/导出:** AES-GCM加密备份,密码保护
- **数据导入/恢复:** 从加密备份文件恢复
- **关于界面:** 版本信息、许可证、隐私政策
- **账户管理:** 设备信息、配对设备、退出登录

---

## 数据模型

### 备份数据模型

```dart
// lib/features/settings/domain/models/backup_data.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'backup_data.freezed.dart';
part 'backup_data.g.dart';

@freezed
class BackupData with _$BackupData {
  const factory BackupData({
    required BackupMetadata metadata,
    required List<TransactionBackup> transactions,
    required List<CategoryBackup> categories,
    required Map<String, dynamic> settings,
  }) = _BackupData;

  factory BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);
}

@freezed
class BackupMetadata with _$BackupMetadata {
  const factory BackupMetadata({
    required String version,
    required int createdAt,
    required String deviceId,
    required String appVersion,
  }) = _BackupMetadata;

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default('ja') String language,
    @Default(true) bool notificationsEnabled,
    @Default(true) bool biometricLockEnabled,
  }) = _AppSettings;

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
}
```

---

## 核心实现流程

### 1. 导出备份用例

```dart
// lib/application/settings/export_backup_use_case.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/backup_data.dart';

part 'export_backup_use_case.g.dart';

class ExportBackupUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final SettingsRepository _settingsRepo;

  ExportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required SettingsRepository settingsRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _settingsRepo = settingsRepo;

  Future<File> execute({
    required String bookId,
    required String password,
  }) async {
    // 1. Collect all data
    final transactions = await _transactionRepo.getAllTransactions(bookId);
    final categories = await _categoryRepo.getAllCategories();
    final settings = await _settingsRepo.getSettings();

    // 2. Create backup data structure
    final backupData = BackupData(
      metadata: BackupMetadata(
        version: '1.0',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        deviceId: await _getDeviceId(),
        appVersion: await _getAppVersion(),
      ),
      transactions: transactions.map((tx) => tx.toBackup()).toList(),
      categories: categories.map((cat) => cat.toBackup()).toList(),
      settings: settings.toJson(),
    );

    // 3. Serialize to JSON
    final jsonString = jsonEncode(backupData.toJson());

    // 4. Compress
    final gzipBytes = GZipEncoder().encode(utf8.encode(jsonString))!;

    // 5. Encrypt with AES-GCM
    final encryptedData = await _encryptData(
      Uint8List.fromList(gzipBytes),
      password,
    );

    // 6. Save to file
    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().toIso8601String().substring(0, 10);
    final file = File('${directory.path}/homepocket_backup_$timestamp.hpb');
    await file.writeAsBytes(encryptedData);

    return file;
  }

  Future<Uint8List> _encryptData(Uint8List data, String password) async {
    // Derive key from password using PBKDF2
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final salt = _generateSalt();
    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    // Encrypt with AES-GCM
    final algorithm = AesGcm.with256bits();
    final nonce = _generateNonce();

    final secretBox = await algorithm.encrypt(
      data,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Combine salt + nonce + ciphertext + mac
    final result = <int>[]
      ..addAll(salt)
      ..addAll(nonce)
      ..addAll(secretBox.cipherText)
      ..addAll(secretBox.mac.bytes);

    return Uint8List.fromList(result);
  }

  List<int> _generateSalt() {
    return List.generate(16, (_) => Random.secure().nextInt(256));
  }

  List<int> _generateNonce() {
    return List.generate(12, (_) => Random.secure().nextInt(256));
  }

  Future<String> _getDeviceId() async {
    // Implementation
    return 'device-id';
  }

  Future<String> _getAppVersion() async {
    // Implementation
    return '1.0.0';
  }
}

@riverpod
ExportBackupUseCase exportBackupUseCase(ExportBackupUseCaseRef ref) {
  return ExportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}
```

### 2. 导入备份用例

```dart
// lib/application/settings/import_backup_use_case.dart

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cryptography/cryptography.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/backup_data.dart';

part 'import_backup_use_case.g.dart';

class ImportBackupUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final SettingsRepository _settingsRepo;

  ImportBackupUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
    required SettingsRepository settingsRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo,
        _settingsRepo = settingsRepo;

  Future<void> execute({
    required File backupFile,
    required String password,
  }) async {
    // 1. Read encrypted file
    final encryptedData = await backupFile.readAsBytes();

    // 2. Decrypt
    final decryptedData = await _decryptData(encryptedData, password);

    // 3. Decompress
    final jsonBytes = GZipDecoder().decodeBytes(decryptedData);
    final jsonString = utf8.decode(jsonBytes);

    // 4. Parse JSON
    final backupData = BackupData.fromJson(jsonDecode(jsonString));

    // 5. Validate version
    if (backupData.metadata.version != '1.0') {
      throw UnsupportedBackupVersionException(
        'Backup version ${backupData.metadata.version} not supported',
      );
    }

    // 6. Import to database (atomic transaction)
    await _importToDatabase(backupData);
  }

  Future<Uint8List> _decryptData(Uint8List encryptedData, String password) async {
    // Extract components
    final salt = encryptedData.sublist(0, 16);
    final nonce = encryptedData.sublist(16, 28);
    final cipherText = encryptedData.sublist(28, encryptedData.length - 16);
    final mac = Mac(encryptedData.sublist(encryptedData.length - 16));

    // Derive key from password
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: 100000,
      bits: 256,
    );

    final secretKey = await pbkdf2.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );

    // Decrypt
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);

    try {
      final plaintext = await algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return Uint8List.fromList(plaintext);
    } catch (e) {
      throw IncorrectPasswordException('Password is incorrect');
    }
  }

  Future<void> _importToDatabase(BackupData backupData) async {
    // Use database transaction for atomicity
    await _transactionRepo.transaction(() async {
      // Clear existing data
      await _transactionRepo.deleteAll();
      await _categoryRepo.deleteAll();

      // Import categories first
      for (final cat in backupData.categories) {
        await _categoryRepo.insert(cat.toDomain());
      }

      // Import transactions
      for (final tx in backupData.transactions) {
        await _transactionRepo.insert(tx.toDomain());
      }

      // Import settings
      await _settingsRepo.updateSettings(
        AppSettings.fromJson(backupData.settings),
      );
    });
  }
}

@riverpod
ImportBackupUseCase importBackupUseCase(ImportBackupUseCaseRef ref) {
  return ImportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}

class UnsupportedBackupVersionException implements Exception {
  final String message;
  UnsupportedBackupVersionException(this.message);
}

class IncorrectPasswordException implements Exception {
  final String message;
  IncorrectPasswordException(this.message);
}
```

### 3. 设置仓储实现

```dart
// lib/data/repositories/settings_repository_impl.dart

import 'package:shared_preferences/shared_preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/repositories/settings_repository.dart';

part 'settings_repository_impl.g.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SharedPreferences _prefs;

  SettingsRepositoryImpl({required SharedPreferences prefs}) : _prefs = prefs;

  static const String _themeModeKey = 'theme_mode';
  static const String _languageKey = 'language';
  static const String _notificationsKey = 'notifications_enabled';
  static const String _biometricLockKey = 'biometric_lock_enabled';

  @override
  Future<AppSettings> getSettings() async {
    return AppSettings(
      themeMode: _getThemeMode(),
      language: _prefs.getString(_languageKey) ?? 'ja',
      notificationsEnabled: _prefs.getBool(_notificationsKey) ?? true,
      biometricLockEnabled: _prefs.getBool(_biometricLockKey) ?? true,
    );
  }

  @override
  Future<void> updateSettings(AppSettings settings) async {
    await _prefs.setString(_themeModeKey, settings.themeMode.name);
    await _prefs.setString(_languageKey, settings.language);
    await _prefs.setBool(_notificationsKey, settings.notificationsEnabled);
    await _prefs.setBool(_biometricLockKey, settings.biometricLockEnabled);
  }

  @override
  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _prefs.setString(_themeModeKey, themeMode.name);
  }

  @override
  Future<void> setLanguage(String language) async {
    await _prefs.setString(_languageKey, language);
  }

  @override
  Future<void> setBiometricLock(bool enabled) async {
    await _prefs.setBool(_biometricLockKey, enabled);
  }

  ThemeMode _getThemeMode() {
    final value = _prefs.getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeMode.system,
    );
  }
}

@riverpod
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) async {
  return await SharedPreferences.getInstance();
}

@riverpod
SettingsRepository settingsRepository(SettingsRepositoryRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return SettingsRepositoryImpl(prefs: prefs);
}

@riverpod
Future<AppSettings> appSettings(AppSettingsRef ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
}
```

---

## UI组件设计

### 设置界面

```dart
// lib/features/settings/presentation/screens/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../application/use_cases/export_backup_use_case.dart';
import '../../application/use_cases/import_backup_use_case.dart';
import '../../../../core/i18n/widgets/language_selector.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            _buildAppearanceSection(context, ref, settings),
            const Divider(),
            _buildDataSection(context, ref),
            const Divider(),
            _buildSecuritySection(context, ref, settings),
            const Divider(),
            _buildAboutSection(context),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
      ),
    );
  }

  Widget _buildAppearanceSection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.appearance,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.palette),
          title: Text(l10n.themeMode),
          subtitle: Text(_getThemeModeLabel(settings.themeMode, l10n)),
          onTap: () => _showThemeModeDialog(context, ref),
        ),
        // 使用国际化语言选择器
        const LanguageSelector(),
      ],
    );
  }

  Widget _buildDataSection(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '数据管理',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.backup),
          title: const Text('导出备份'),
          subtitle: const Text('创建加密备份文件'),
          onTap: () => _exportBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.restore),
          title: const Text('导入备份'),
          subtitle: const Text('从备份文件恢复'),
          onTap: () => _importBackup(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever),
          title: const Text('删除所有数据'),
          subtitle: const Text('永久删除所有记账数据'),
          onTap: () => _showDeleteAllDataDialog(context, ref),
        ),
      ],
    );
  }

  Widget _buildSecuritySection(
    BuildContext context,
    WidgetRef ref,
    AppSettings settings,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '安全',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.fingerprint),
          title: const Text('生物识别锁'),
          subtitle: const Text('使用Face ID/指纹认证'),
          value: settings.biometricLockEnabled,
          onChanged: (value) async {
            await ref
                .read(settingsRepositoryProvider)
                .setBiometricLock(value);
            ref.invalidate(appSettingsProvider);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('通知'),
          subtitle: const Text('预算提醒和同步通知'),
          value: settings.notificationsEnabled,
          onChanged: (value) async {
            // TODO: Update notifications setting
          },
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            '关于',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('版本'),
          subtitle: const Text('1.0.0'),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip),
          title: const Text('隐私政策'),
          onTap: () {
            // Navigate to privacy policy
          },
        ),
        ListTile(
          leading: const Icon(Icons.description),
          title: const Text('开源许可证'),
          onTap: () {
            // Navigate to licenses
          },
        ),
      ],
    );
  }

  void _showThemeModeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择主题'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ThemeMode.values.map((mode) {
            return RadioListTile<ThemeMode>(
              title: Text(_getThemeModeLabel(mode)),
              value: mode,
              groupValue: ref.read(appSettingsProvider).value?.themeMode,
              onChanged: (value) async {
                if (value != null) {
                  await ref
                      .read(settingsRepositoryProvider)
                      .setThemeMode(value);
                  ref.invalidate(appSettingsProvider);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择语言'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['ja', 'zh', 'en'].map((lang) {
            return RadioListTile<String>(
              title: Text(_getLanguageLabel(lang)),
              value: lang,
              groupValue: ref.read(appSettingsProvider).value?.language,
              onChanged: (value) async {
                if (value != null) {
                  await ref.read(settingsRepositoryProvider).setLanguage(value);
                  ref.invalidate(appSettingsProvider);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    final password = await _showPasswordDialog(context, '设置备份密码');
    if (password == null) return;

    try {
      final file = await ref.read(exportBackupUseCaseProvider).execute(
            bookId: 'current-book',
            password: password,
          );

      // Share the backup file
      await Share.shareXFiles([XFile(file.path)]);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份导出成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    // Pick backup file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['hpb'],
    );

    if (result == null) return;

    final password = await _showPasswordDialog(context, '输入备份密码');
    if (password == null) return;

    try {
      await ref.read(importBackupUseCaseProvider).execute(
            backupFile: File(result.files.single.path!),
            password: password,
          );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('备份导入成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<String?> _showPasswordDialog(
    BuildContext context,
    String title,
  ) async {
    String? password;
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          obscureText: true,
          onChanged: (value) => password = value,
          decoration: const InputDecoration(hintText: '输入密码'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, password),
            child: const Text('确认'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除所有数据'),
        content: const Text('此操作无法撤销。确定要删除所有数据吗?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Delete all data
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.system:
        return l10n.themeModeSystem;
      case ThemeMode.light:
        return l10n.themeModeLight;
      case ThemeMode.dark:
        return l10n.themeModeDark;
    }
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/unit/application/settings/export_backup_use_case_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockCategoryRepository extends Mock implements CategoryRepository {}
class MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('ExportBackupUseCase', () {
    late ExportBackupUseCase useCase;
    late MockTransactionRepository mockTransactionRepo;
    late MockCategoryRepository mockCategoryRepo;
    late MockSettingsRepository mockSettingsRepo;

    setUp(() {
      mockTransactionRepo = MockTransactionRepository();
      mockCategoryRepo = MockCategoryRepository();
      mockSettingsRepo = MockSettingsRepository();
      useCase = ExportBackupUseCase(
        transactionRepo: mockTransactionRepo,
        categoryRepo: mockCategoryRepo,
        settingsRepo: mockSettingsRepo,
      );
    });

    test('should export backup with correct structure', () async {
      // Given
      when(mockTransactionRepo.getAllTransactions(any))
          .thenAnswer((_) async => []);
      when(mockCategoryRepo.getAllCategories()).thenAnswer((_) async => []);
      when(mockSettingsRepo.getSettings())
          .thenAnswer((_) async => AppSettings());

      // When
      final file = await useCase.execute(
        bookId: 'book-1',
        password: 'test-password',
      );

      // Then
      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.hpb'), isTrue);
    });
  });
}
```

---

## 性能优化

### 优化策略

**1. 备份导出:**
- 流式处理大数据集
- 加密前压缩
- 显示进度指示器

**2. 备份导入:**
- 验证文件完整性
- 使用数据库事务
- 后台处理大导入

---

## 验收标准

### 功能需求

- ✅ 备份导出<10秒(1000条交易)
- ✅ 备份文件AES-256-GCM加密
- ✅ 导入正确验证密码
- ✅ 设置在应用重启后保持

---

## 开发时间线 (6天)

| 天数 | 任务 | 交付物 |
|------|------|--------|
| **第1天** | 设置仓储 | SharedPreferences实现 |
| **第2天** | 导出备份 | 加密、压缩、文件保存 |
| **第3天** | 导入备份 | 解密、解压、验证 |
| **第4天** | 设置界面UI | 完整设置页面 |
| **第5天** | 备份/恢复UI | 对话框、文件选择器 |
| **第6天** | 测试 | 单元测试、集成测试 |

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-03: 创建完整技术实现文档，包含所有代码示例
