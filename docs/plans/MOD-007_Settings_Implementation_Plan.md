# MOD-007 Settings Module - Implementation Plan

**Module:** MOD-008 Settings Management (file: MOD-007_Settings.md)
**Plan Version:** 1.0
**Created:** 2026-02-07
**Estimated Effort:** 6 days (4 phases)
**Priority:** P0 (MVP Core)
**Dependencies:** MOD-006 Security (done), MOD-001 Basic Accounting (done)

---

## Executive Summary

Implement the Settings module for Home Pocket, providing:
1. App preferences (theme, language, notifications, biometric lock)
2. Encrypted backup export (AES-256-GCM)
3. Encrypted backup import/restore
4. Data deletion with confirmation
5. About section (version, privacy, licenses)

The module follows Clean Architecture ("Thin Feature" pattern) with all code placed according to the 5-layer architecture rules.

---

## Current State Analysis

### What Exists
- **MainShellScreen** (`lib/features/home/presentation/screens/main_shell_screen.dart:54-62`): Contains `_SettingsPlaceholder` stub
- **Crypto infrastructure** (`lib/infrastructure/crypto/`): AES, ChaCha20, PBKDF2, hash chains - all implemented
- **Security infrastructure** (`lib/infrastructure/security/`): Biometric service, secure storage, audit logger
- **Accounting data layer** (`lib/data/`): Tables, DAOs, repository implementations for transactions, categories, books
- **Database** (`lib/data/app_database.dart`): Drift + SQLCipher, schema v3, 4 tables

### What Does NOT Exist
- `lib/features/settings/` - entire feature directory
- `lib/application/settings/` - settings use cases
- `lib/infrastructure/i18n/` - i18n infrastructure (out of scope, follow-up task)
- `shared_preferences` dependency in pubspec.yaml
- `file_picker`, `share_plus`, `package_info_plus` dependencies
- ARB localization files (out of scope, follow-up task)

### Gaps in Existing Repository Interfaces
- `TransactionRepository`: Missing `findAll(bookId)` (unpaginated) and `deleteAllByBook(bookId)`
- `CategoryRepository`: Missing `deleteAll()`
- `BookRepository`: Missing `deleteAll()`

---

## Architecture Compliance

### File Placement Map

```
lib/
├── features/settings/                          # NEW - Thin Feature
│   ├── domain/
│   │   ├── models/
│   │   │   ├── app_settings.dart               # @freezed AppSettings
│   │   │   └── backup_data.dart                # @freezed BackupData, BackupMetadata
│   │   └── repositories/
│   │       └── settings_repository.dart        # Abstract interface
│   └── presentation/
│       ├── providers/
│       │   ├── repository_providers.dart       # SSOT: settingsRepositoryProvider
│       │   ├── settings_providers.dart         # appSettingsProvider, themeModeProvider
│       │   └── backup_providers.dart           # exportBackupUseCaseProvider, etc.
│       ├── screens/
│       │   └── settings_screen.dart            # Main settings page
│       └── widgets/
│           ├── appearance_section.dart         # Theme mode selection
│           ├── data_management_section.dart    # Backup/restore/delete
│           ├── security_section.dart           # Biometric, notifications
│           ├── about_section.dart              # Version, privacy, licenses
│           └── password_dialog.dart            # Backup password input
│
├── application/settings/                       # NEW - Use Cases
│   ├── export_backup_use_case.dart
│   ├── import_backup_use_case.dart
│   └── clear_all_data_use_case.dart
│
├── data/repositories/                          # MODIFY existing
│   ├── settings_repository_impl.dart           # NEW - SharedPreferences impl
│   ├── transaction_repository_impl.dart        # MODIFY - add findAll, deleteAllByBook
│   ├── category_repository_impl.dart           # MODIFY - add deleteAll
│   └── book_repository_impl.dart               # MODIFY - add deleteAll
│
├── data/daos/                                  # MODIFY existing
│   ├── transaction_dao.dart                    # MODIFY - add findAllByBook, deleteAllByBook
│   ├── category_dao.dart                       # MODIFY - add deleteAll
│   └── book_dao.dart                           # MODIFY - add deleteAll
│
└── features/accounting/domain/repositories/    # MODIFY existing interfaces
    ├── transaction_repository.dart              # ADD: findAll, deleteAllByBook
    ├── category_repository.dart                 # ADD: deleteAll
    └── book_repository.dart                     # ADD: deleteAll
```

### Test File Map

```
test/
├── unit/
│   ├── features/settings/
│   │   └── domain/models/
│   │       ├── app_settings_test.dart
│   │       └── backup_data_test.dart
│   ├── data/repositories/
│   │   └── settings_repository_impl_test.dart
│   └── application/settings/
│       ├── export_backup_use_case_test.dart
│       ├── import_backup_use_case_test.dart
│       └── clear_all_data_use_case_test.dart
└── widget/
    └── features/settings/
        └── presentation/
            ├── settings_screen_test.dart
            └── widgets/
                └── password_dialog_test.dart
```

---

## Implementation Phases

---

### Phase 1: Foundation (Day 1)

**Goal:** Domain models, repository interface, implementation, and providers.

#### Step 1.1: Add Package Dependencies

**File:** `pubspec.yaml`

Add under `dependencies:`:
```yaml
# Settings & Preferences
shared_preferences: ^2.3.4

# File Operations
file_picker: ^8.1.6
share_plus: ^10.1.4
package_info_plus: ^8.1.3
```

**Command:** `flutter pub get`

**Acceptance:** `flutter pub get` succeeds with no errors.

---

#### Step 1.2: Create Domain Models

**File:** `lib/features/settings/domain/models/app_settings.dart`

```dart
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

NOTE: `ThemeMode` is from `package:flutter/material.dart`. Since domain layer should be independent, use a custom enum `AppThemeMode { system, light, dark }` instead to avoid Flutter dependency in domain layer.

**File:** `lib/features/settings/domain/models/backup_data.dart`

```dart
@freezed
class BackupData with _$BackupData {
  const factory BackupData({
    required BackupMetadata metadata,
    required List<Map<String, dynamic>> transactions,
    required List<Map<String, dynamic>> categories,
    required List<Map<String, dynamic>> books,
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
```

NOTE: Use `List<Map<String, dynamic>>` for transactions/categories/books to avoid coupling backup format to current domain models. This provides forward/backward compatibility.

**TDD:** Write tests first for model creation, copyWith, JSON serialization.

---

#### Step 1.3: Create SettingsRepository Interface

**File:** `lib/features/settings/domain/repositories/settings_repository.dart`

```dart
abstract class SettingsRepository {
  Future<AppSettings> getSettings();
  Future<void> updateSettings(AppSettings settings);
  Future<void> setThemeMode(AppThemeMode themeMode);
  Future<void> setLanguage(String language);
  Future<void> setBiometricLock(bool enabled);
  Future<void> setNotificationsEnabled(bool enabled);
}
```

---

#### Step 1.4: Create SettingsRepositoryImpl

**File:** `lib/data/repositories/settings_repository_impl.dart`

Implementation using `SharedPreferences`:
- Keys: `theme_mode`, `language`, `notifications_enabled`, `biometric_lock_enabled`
- Default: system theme, Japanese language, notifications on, biometric on
- No encryption needed (no sensitive data in settings)

**TDD:** Write tests first using mock SharedPreferences.

---

#### Step 1.5: Create Providers (SSOT Pattern)

**File:** `lib/features/settings/presentation/providers/repository_providers.dart`

```dart
@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final prefs = ref.watch(sharedPreferencesProvider).requireValue;
  return SettingsRepositoryImpl(prefs: prefs);
}

@riverpod
Future<SharedPreferences> sharedPreferences(Ref ref) async {
  return await SharedPreferences.getInstance();
}
```

**File:** `lib/features/settings/presentation/providers/settings_providers.dart`

```dart
@riverpod
Future<AppSettings> appSettings(Ref ref) async {
  final repo = ref.watch(settingsRepositoryProvider);
  return await repo.getSettings();
}
```

---

#### Step 1.6: Run Code Generation & Tests

**Commands:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test test/unit/features/settings/
flutter test test/unit/data/repositories/settings_repository_impl_test.dart
flutter analyze
```

**Phase 1 Checkpoint:** Domain models serialize/deserialize correctly. Settings repository reads/writes SharedPreferences. Providers wire correctly. All tests pass.

---

### Phase 2: Backup Infrastructure (Day 2-3)

**Goal:** Export and import backup use cases with encrypted file handling.

#### Step 2.1: Extend Existing Repository Interfaces

**File:** `lib/features/accounting/domain/repositories/transaction_repository.dart`

Add:
```dart
/// Get all transactions for a book (unpaginated, for backup).
Future<List<Transaction>> findAllByBook(String bookId);

/// Delete all transactions for a book (for backup restore).
Future<void> deleteAllByBook(String bookId);
```

**File:** `lib/features/accounting/domain/repositories/category_repository.dart`

Add:
```dart
/// Delete all categories (for backup restore).
Future<void> deleteAll();
```

**File:** `lib/features/accounting/domain/repositories/book_repository.dart`

Add:
```dart
/// Delete all books (for backup restore).
Future<void> deleteAll();
```

---

#### Step 2.2: Update DAOs

**File:** `lib/data/daos/transaction_dao.dart`

Add:
```dart
Future<List<TransactionEntity>> findAllByBook(String bookId);
Future<void> deleteAllByBook(String bookId);
```

**File:** `lib/data/daos/category_dao.dart`

Add:
```dart
Future<void> deleteAll();
```

**File:** `lib/data/daos/book_dao.dart`

Add:
```dart
Future<void> deleteAll();
```

---

#### Step 2.3: Update Repository Implementations

Update `TransactionRepositoryImpl`, `CategoryRepositoryImpl`, `BookRepositoryImpl` to implement new interface methods.

**TDD:** Write tests for new methods first, then implement.

---

#### Step 2.4: Create ExportBackupUseCase

**File:** `lib/application/settings/export_backup_use_case.dart`

Algorithm:
1. Collect all transactions via `transactionRepo.findAllByBook(bookId)`
2. Collect all categories via `categoryRepo.findAll()`
3. Collect all books via `bookRepo.findAll()`
4. Get current settings via `settingsRepo.getSettings()`
5. Get device ID via `keyManager.getDeviceId()`
6. Get app version via `PackageInfo`
7. Build `BackupData` with `BackupMetadata`
8. Serialize to JSON string
9. Compress with GZip (`dart:io` GZipCodec)
10. Derive encryption key from password via PBKDF2 (100k iterations, SHA-256)
11. Encrypt with AES-256-GCM (random 16-byte salt, 12-byte nonce)
12. Write binary: `salt (16) + nonce (12) + ciphertext + mac (16)` to `.hpb` file
13. Return file path

**Dependencies:**
- TransactionRepository
- CategoryRepository
- BookRepository
- SettingsRepository
- KeyManager (device ID)
- `cryptography` package (PBKDF2, AES-GCM)
- `path_provider` (documents directory)
- `package_info_plus` (app version)

**TDD:** Write tests with mocked repositories. Verify encryption format (salt, nonce, ciphertext, mac).

---

#### Step 2.5: Create ImportBackupUseCase

**File:** `lib/application/settings/import_backup_use_case.dart`

Algorithm:
1. Read encrypted `.hpb` file bytes
2. Extract: salt (0..16), nonce (16..28), ciphertext (28..len-16), mac (len-16..len)
3. Derive key from password via PBKDF2 (100k iterations)
4. Decrypt with AES-256-GCM + verify MAC
5. Decompress GZip
6. Parse JSON to `BackupData`
7. Validate backup version (`1.0`)
8. Begin database transaction (atomic)
9. Delete existing data: transactions, categories, books
10. Insert categories from backup
11. Insert books from backup
12. Insert transactions from backup
13. Update settings
14. Commit transaction

**Error handling:**
- `IncorrectPasswordException` if MAC verification fails
- `UnsupportedBackupVersionException` if version != `1.0`
- `BackupCorruptedException` if JSON parse fails
- Database transaction rollback on any failure

**TDD:** Write tests for decryption, version validation, atomic restore.

---

#### Step 2.6: Create ClearAllDataUseCase

**File:** `lib/application/settings/clear_all_data_use_case.dart`

Algorithm:
1. Delete all transactions
2. Delete all categories
3. Delete all books
4. Reset settings to defaults
5. Log audit event

**TDD:** Write tests verifying all repos are called.

---

#### Step 2.7: Create Backup Providers

**File:** `lib/features/settings/presentation/providers/backup_providers.dart`

```dart
@riverpod
ExportBackupUseCase exportBackupUseCase(Ref ref) {
  return ExportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
}

@riverpod
ImportBackupUseCase importBackupUseCase(Ref ref) {
  return ImportBackupUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}

@riverpod
ClearAllDataUseCase clearAllDataUseCase(Ref ref) {
  return ClearAllDataUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
    bookRepo: ref.watch(bookRepositoryProvider),
    settingsRepo: ref.watch(settingsRepositoryProvider),
  );
}
```

NOTE: `transactionRepositoryProvider`, `categoryRepositoryProvider`, `bookRepositoryProvider` are already defined in `lib/features/accounting/presentation/providers/repository_providers.dart`. Import from there.

---

#### Step 2.8: Code Generation & Tests

**Commands:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter test
flutter analyze
```

**Phase 2 Checkpoint:** Export creates correctly formatted encrypted `.hpb` file. Import decrypts and restores data atomically. Wrong password throws IncorrectPasswordException. Unsupported version throws. All existing tests still pass.

---

### Phase 3: Settings UI (Day 4-5)

**Goal:** Complete settings screen with all sections wired to providers.

#### Step 3.1: SettingsScreen

**File:** `lib/features/settings/presentation/screens/settings_screen.dart`

```dart
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key, required this.bookId});
  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(appSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          children: [
            AppearanceSection(settings: settings),
            const Divider(),
            DataManagementSection(bookId: bookId),
            const Divider(),
            SecuritySection(settings: settings),
            const Divider(),
            const AboutSection(),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
```

NOTE: Using hardcoded English strings for now. i18n integration is a follow-up task (MOD-014).

---

#### Step 3.2: AppearanceSection

**File:** `lib/features/settings/presentation/widgets/appearance_section.dart`

- Theme mode selection (System / Light / Dark) via dialog
- On change: `settingsRepo.setThemeMode(mode)` + `ref.invalidate(appSettingsProvider)`

---

#### Step 3.3: DataManagementSection

**File:** `lib/features/settings/presentation/widgets/data_management_section.dart`

- Export Backup: Show password dialog → call ExportBackupUseCase → Share file
- Import Backup: FilePicker → password dialog → ImportBackupUseCase
- Delete All Data: Confirmation dialog → ClearAllDataUseCase

---

#### Step 3.4: SecuritySection

**File:** `lib/features/settings/presentation/widgets/security_section.dart`

- Biometric Lock toggle (SwitchListTile)
- Notifications toggle (SwitchListTile)

---

#### Step 3.5: AboutSection

**File:** `lib/features/settings/presentation/widgets/about_section.dart`

- App version (from package_info_plus)
- Privacy policy (placeholder link)
- Open source licenses (Navigator to LicensePage)

---

#### Step 3.6: PasswordDialog

**File:** `lib/features/settings/presentation/widgets/password_dialog.dart`

- Text field with obscureText
- For export: password + confirm password (must match)
- For import: single password field
- Minimum password length validation (8 chars)

---

#### Step 3.7: Widget Tests

Write widget tests for:
- SettingsScreen renders all sections
- Theme mode dialog opens and selects
- Password dialog validates input
- Delete confirmation dialog shows warning

**Phase 3 Checkpoint:** Settings screen displays all sections. Theme mode changes. Biometric toggle works. About section shows version. All widget tests pass.

---

### Phase 4: Integration & Polish (Day 5-6)

**Goal:** Wire everything together, run full test suite, clean analysis.

#### Step 4.1: Wire SettingsScreen into MainShellScreen

**File:** `lib/features/home/presentation/screens/main_shell_screen.dart`

Replace:
```dart
_SettingsPlaceholder(),
```
With:
```dart
SettingsScreen(bookId: widget.bookId),
```

Remove `_SettingsPlaceholder` class.

---

#### Step 4.2: Connect Theme Mode to MaterialApp

**File:** `lib/main.dart`

Update `HomePocketApp` to watch `appSettingsProvider` and apply `themeMode`:

```dart
@override
Widget build(BuildContext context) {
  final settingsAsync = ref.watch(appSettingsProvider);
  final themeMode = settingsAsync.valueOrNull?.themeMode ?? ThemeMode.system;

  return MaterialApp(
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    darkTheme: ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
    ),
    themeMode: themeMode,
    home: _buildHome(),
  );
}
```

NOTE: Need to convert `AppThemeMode` (domain) to `ThemeMode` (Flutter) in presentation layer.

---

#### Step 4.3: SharedPreferences Initialization

**File:** `lib/main.dart`

Add SharedPreferences async initialization in the app startup:
```dart
// After database init, before runApp:
await SharedPreferences.getInstance(); // Warm the cache
```

Or use Riverpod async provider as designed in Step 1.5.

---

#### Step 4.4: Integration Tests

**File:** `test/integration/settings/backup_integration_test.dart`

Test scenarios:
1. Export → Import round-trip with same password restores identical data
2. Import with wrong password throws IncorrectPasswordException
3. Import unsupported version throws UnsupportedBackupVersionException
4. Clear all data removes everything
5. Settings persist across app restart (SharedPreferences)

---

#### Step 4.5: Quality Checks

```bash
# Format
dart format .

# Analyze (must be 0 issues)
flutter analyze

# Run ALL tests
flutter test

# Coverage check
flutter test --coverage
# Verify >= 80%
```

---

#### Step 4.6: Final Review

- Review all new files follow Clean Architecture
- Verify no hardcoded secrets
- Verify no imports violate dependency rules
- Verify SSOT pattern in repository_providers.dart
- Verify @freezed models use copyWith (no mutation)

**Phase 4 Checkpoint:** Settings tab works in app. Theme switching reflects in UI. Backup export/import works end-to-end. All tests pass. `flutter analyze` clean. 80%+ coverage.

---

## Risk Register

| # | Risk | Impact | Likelihood | Mitigation |
|---|------|--------|------------|------------|
| 1 | Extending existing repository interfaces breaks existing tests | High | Medium | Add new methods only (no changes to existing signatures). Run full test suite after each change. |
| 2 | AES-256-GCM encryption produces non-portable backup files | Medium | Low | Use standard cryptography package. Write round-trip tests. Document binary format. |
| 3 | File picker / share fails on specific iOS/Android versions | Medium | Medium | Add error handling with user-friendly messages. Test on both platforms. |
| 4 | SharedPreferences async init race condition | Low | Low | Use Riverpod FutureProvider with `.requireValue` pattern. Warm cache at startup. |
| 5 | Large backup files (>10k transactions) slow to process | Medium | Low | Use GZip compression. Consider streaming for future optimization. |
| 6 | No i18n means hardcoded English strings | Low | N/A | Noted as follow-up (MOD-014). All strings are isolated in widget layer for easy extraction later. |

---

## New Package Dependencies

| Package | Version | Purpose | Size Impact |
|---------|---------|---------|-------------|
| `shared_preferences` | ^2.3.4 | Settings persistence (key-value) | Minimal |
| `file_picker` | ^8.1.6 | Select .hpb backup file for import | Medium (platform plugins) |
| `share_plus` | ^10.1.4 | Share exported backup file | Medium (platform plugins) |
| `package_info_plus` | ^8.1.3 | Get app version for About section | Minimal |

Existing packages used:
- `cryptography: ^2.7.0` (PBKDF2, AES-GCM)
- `path_provider: ^2.1.5` (documents directory)
- `flutter_secure_storage: ^9.2.4` (key management)

---

## Out of Scope (Follow-up Tasks)

1. **i18n Integration (MOD-014):** Replace hardcoded strings with `S.of(context).key`. Create ARB files. Set up `flutter gen-l10n`.
2. **Language Switching:** Requires i18n infrastructure. Appearance section will show placeholder.
3. **Notification Settings:** Backend not implemented. Toggle saves preference but doesn't configure push notifications.
4. **Cloud Backup:** P2P sync backup is separate from local encrypted backup.
5. **Backup Scheduling:** Automatic backup not in MVP scope.
6. **Settings Migration:** Schema versioning for SharedPreferences values (future).

---

## Acceptance Criteria (Definition of Done)

- [ ] `flutter analyze` returns 0 issues
- [ ] `flutter test` passes all tests
- [ ] Test coverage >= 80% for new code
- [ ] `dart format .` clean (no changes needed)
- [ ] Settings screen accessible via bottom navigation tab
- [ ] Theme mode switching (System/Light/Dark) works and persists
- [ ] Biometric lock toggle saves preference
- [ ] Notifications toggle saves preference
- [ ] About section shows correct app version
- [ ] Export backup creates encrypted `.hpb` file
- [ ] Export backup can be shared via system share sheet
- [ ] Import backup restores data from `.hpb` file with correct password
- [ ] Import backup rejects wrong password with user-friendly error
- [ ] Delete all data clears transactions, categories, books with confirmation dialog
- [ ] No existing tests broken by interface extensions
- [ ] All new code follows Clean Architecture placement rules
- [ ] Repository providers follow SSOT pattern

---

## Timeline Summary

| Day | Phase | Deliverables |
|-----|-------|-------------|
| **Day 1** | Phase 1: Foundation | Dependencies, domain models, repository, providers, unit tests |
| **Day 2** | Phase 2: Backup (Part 1) | Extend repos, ExportBackupUseCase, unit tests |
| **Day 3** | Phase 2: Backup (Part 2) | ImportBackupUseCase, ClearAllDataUseCase, backup providers |
| **Day 4** | Phase 3: UI (Part 1) | SettingsScreen, appearance, security, about sections |
| **Day 5** | Phase 3: UI (Part 2) + Phase 4 start | Data section, password dialog, wire into MainShell |
| **Day 6** | Phase 4: Integration | Theme mode in MaterialApp, integration tests, quality checks |
