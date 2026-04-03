# User Profile Onboarding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add first-launch onboarding that collects a user nickname and emoji avatar, stored in an encrypted local database, with editing via Settings.

**Architecture:** New `profile` feature following Thin Feature pattern — domain models + presentation only. Data layer (table, DAO, repo impl) in shared `lib/data/`. Application layer use cases in `lib/application/profile/`. Onboarding check added to app startup flow after existing seed operations. Navigation uses existing `Navigator.push` / `pushReplacement` pattern.

**Tech Stack:** Drift (SQLCipher) for storage, Freezed for domain model, Riverpod codegen for state, image_picker for photo upload, existing AppColors/AppTheme for styling.

**Spec:** `docs/superpowers/specs/2026-04-03-user-profile-onboarding-design.md`

**UI Design (Pencil `untitled.pen`):**

| Screen | Light Node ID | Dark Node ID |
|--------|-------------|-------------|
| ProfileOnboardingScreen | `h5JI2` | `MUen3` |
| AvatarPickerScreen | `NNogy` | `s6UDM` |
| ProfileEditScreen | `wK1hr` | `xLQll` |

**Design Style — "Playful Scattered" (V5):**
- Scattered decorative emoji accents (🌸🌿⭐🍃💫🌷✨) at low opacity (0.08–0.15) with subtle rotation
- Avatar: 110×110 circle (cornerRadius 55) with warm gradient fill (#FFD4CC → #FEEAE6 → #FEF5F4), inner white stroke, outer coral shadow
- Input: cornerRadius 16, height 52, emoji prefix (📝), bg-card fill with border-default stroke
- Button: cornerRadius 16, height 52, gradient fill (#E85A4F → #F08070), coral shadow, white text "はじめる ✨"
- Label style: Outfit 12px 600 weight, text-secondary color, 0.5 letter-spacing
- Font: Outfit throughout, title 26px/700, subtitle 14px/400
- Screen bg: bg-primary (#FCFBF9 light / #141418 dark)
- Dark avatar gradient: #3D2020 → #2D1818 → #251518

---

## File Structure

### New Files (Create)

| # | File | Responsibility |
|---|------|---------------|
| 1 | `lib/data/tables/user_profiles_table.dart` | Drift table definition |
| 2 | `lib/data/daos/user_profile_dao.dart` | CRUD operations |
| 3 | `lib/data/repositories/user_profile_repository_impl.dart` | Domain mapping |
| 4 | `lib/features/profile/domain/models/user_profile.dart` | Freezed model |
| 5 | `lib/features/profile/domain/repositories/user_profile_repository.dart` | Abstract interface |
| 6 | `lib/application/profile/save_user_profile_use_case.dart` | Create/update + validation |
| 7 | `lib/application/profile/get_user_profile_use_case.dart` | Query profile |
| 8 | `lib/shared/constants/warm_emojis.dart` | 24 emoji constants |
| 9 | `lib/features/profile/presentation/providers/user_profile_providers.dart` | Riverpod providers |
| 10 | `lib/features/profile/presentation/widgets/avatar_display.dart` | Emoji/image avatar widget |
| 11 | `lib/features/profile/presentation/widgets/scattered_emoji_background.dart` | Decorative background |
| 12 | `lib/features/profile/presentation/screens/profile_onboarding_screen.dart` | First-launch onboarding |
| 13 | `lib/features/profile/presentation/screens/avatar_picker_screen.dart` | Emoji grid + photo |
| 14 | `lib/features/profile/presentation/screens/profile_edit_screen.dart` | Settings edit page |
| 15 | `lib/features/profile/presentation/widgets/profile_section_card.dart` | Settings entry card |
| 16 | `test/data/daos/user_profile_dao_test.dart` | DAO tests |
| 17 | `test/application/profile/save_user_profile_use_case_test.dart` | Use case tests |
| 18 | `test/features/profile/presentation/screens/profile_onboarding_screen_test.dart` | Widget tests |

### Modified Files

| # | File | Change |
|---|------|--------|
| M1 | `lib/data/app_database.dart` | Add UserProfiles table, bump to v12 |
| M2 | `lib/main.dart` | Add profile check after seed, conditional navigation |
| M3 | `lib/features/settings/presentation/screens/settings_screen.dart` | Add ProfileSectionCard at top |
| M4 | `lib/l10n/app_ja.arb` | Add 21 profile i18n keys |
| M5 | `lib/l10n/app_en.arb` | Add 21 profile i18n keys |
| M6 | `lib/l10n/app_zh.arb` | Add 21 profile i18n keys |
| M7 | `pubspec.yaml` | Add image_picker dependency |

---

## Task 1: Add `image_picker` Dependency

**Files:**
- Modify: `pubspec.yaml`

- [ ] **Step 1: Add image_picker to pubspec.yaml**

Under `dependencies:` section, add:

```yaml
  image_picker: ^1.1.2
```

- [ ] **Step 2: Run pub get**

```bash
cd /Users/xinz/Development/home-pocket-app && flutter pub get
```

Expected: Dependencies resolved successfully.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add image_picker dependency for profile avatar upload"
```

---

## Task 2: Warm Emojis Constant

**Files:**
- Create: `lib/shared/constants/warm_emojis.dart`
- Test: `test/shared/constants/warm_emojis_test.dart`

- [ ] **Step 1: Write the test**

```dart
// test/shared/constants/warm_emojis_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket_app/shared/constants/warm_emojis.dart';

void main() {
  group('warmEmojis', () {
    test('contains exactly 24 emojis', () {
      expect(warmEmojis.length, 24);
    });

    test('has no duplicates', () {
      expect(warmEmojis.toSet().length, warmEmojis.length);
    });

    test('randomWarmEmoji returns an emoji from the list', () {
      for (var i = 0; i < 10; i++) {
        expect(warmEmojis.contains(randomWarmEmoji()), isTrue);
      }
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/shared/constants/warm_emojis_test.dart
```

Expected: FAIL — file not found.

- [ ] **Step 3: Implement**

```dart
// lib/shared/constants/warm_emojis.dart
import 'dart:math';

const List<String> warmEmojis = [
  '🏠', '🌸', '🌿', '🐱', '🐶', '🌈',
  '☀️', '🦊', '🐼', '🍀', '⭐', '🌻',
  '🐰', '🦋', '🌙', '🎀', '🧸', '🎵',
  '🏡', '🌷', '🐣', '🍃', '💫', '🫧',
];

final _random = Random();

String randomWarmEmoji() => warmEmojis[_random.nextInt(warmEmojis.length)];
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/shared/constants/warm_emojis_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/shared/constants/warm_emojis.dart test/shared/constants/warm_emojis_test.dart
git commit -m "feat(profile): add warm emoji constants for avatar selection"
```

---

## Task 3: Domain Model — UserProfile (Freezed)

**Files:**
- Create: `lib/features/profile/domain/models/user_profile.dart`

- [ ] **Step 1: Create the Freezed model**

```dart
// lib/features/profile/domain/models/user_profile.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_profile.freezed.dart';

@freezed
abstract class UserProfile with _$UserProfile {
  const factory UserProfile({
    required String id,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _UserProfile;
}
```

- [ ] **Step 2: Run code generation**

```bash
cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Generated `user_profile.freezed.dart` and `user_profile.g.dart`.

- [ ] **Step 3: Verify no analyzer errors**

```bash
flutter analyze lib/features/profile/domain/models/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/domain/
git commit -m "feat(profile): add UserProfile freezed domain model"
```

---

## Task 4: Domain — Repository Interface

**Files:**
- Create: `lib/features/profile/domain/repositories/user_profile_repository.dart`

- [ ] **Step 1: Create the interface**

```dart
// lib/features/profile/domain/repositories/user_profile_repository.dart
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';

abstract class UserProfileRepository {
  Future<UserProfile?> find();
  Future<void> save(UserProfile profile);
  Future<void> delete(String id);
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/profile/domain/
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/domain/repositories/
git commit -m "feat(profile): add UserProfileRepository interface"
```

---

## Task 5: Data Layer — Drift Table + Migration

**Files:**
- Create: `lib/data/tables/user_profiles_table.dart`
- Modify: `lib/data/app_database.dart`

- [ ] **Step 1: Create the Drift table**

```dart
// lib/data/tables/user_profiles_table.dart
import 'package:drift/drift.dart';

@DataClassName('UserProfileRow')
class UserProfiles extends Table {
  TextColumn get id => text()();
  TextColumn get displayName => text().withLength(min: 1, max: 50)();
  TextColumn get avatarEmoji => text()();
  TextColumn get avatarImagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

- [ ] **Step 2: Add table to AppDatabase and bump version**

In `lib/data/app_database.dart`:

1. Add import: `import 'tables/user_profiles_table.dart';`
2. Add `UserProfiles` to the `@DriftDatabase(tables: [...])` list
3. Change `schemaVersion => 11` to `schemaVersion => 12`
4. Add migration case inside `onUpgrade`:

```dart
if (from < 12) {
  await m.createTable(userProfiles);
}
```

- [ ] **Step 3: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/data/
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/tables/user_profiles_table.dart lib/data/app_database.dart lib/data/app_database.g.dart
git commit -m "feat(profile): add UserProfiles drift table and v12 migration"
```

---

## Task 6: Data Layer — DAO

**Files:**
- Create: `lib/data/daos/user_profile_dao.dart`
- Test: `test/data/daos/user_profile_dao_test.dart`

- [ ] **Step 1: Write the DAO test**

```dart
// test/data/daos/user_profile_dao_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket_app/data/app_database.dart';
import 'package:home_pocket_app/data/daos/user_profile_dao.dart';

void main() {
  late AppDatabase db;
  late UserProfileDao dao;

  setUp(() {
    db = AppDatabase.forTesting();
    dao = UserProfileDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfileDao', () {
    test('insert and find returns the profile', () async {
      final now = DateTime.now();
      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );

      final row = await dao.find();
      expect(row, isNotNull);
      expect(row!.displayName, 'たけし');
      expect(row.avatarEmoji, '🐱');
      expect(row.avatarImagePath, isNull);
    });

    test('find returns null when no profile exists', () async {
      final row = await dao.find();
      expect(row, isNull);
    });

    test('upsert updates existing profile', () async {
      final now = DateTime.now();
      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );
      await dao.upsert(
        id: 'test-id',
        displayName: 'はなこ',
        avatarEmoji: '🌸',
        avatarImagePath: '/path/to/img.jpg',
        createdAt: now,
        updatedAt: DateTime.now(),
      );

      final row = await dao.find();
      expect(row!.displayName, 'はなこ');
      expect(row.avatarEmoji, '🌸');
      expect(row.avatarImagePath, '/path/to/img.jpg');
    });

    test('delete removes the profile', () async {
      final now = DateTime.now();
      await dao.upsert(
        id: 'test-id',
        displayName: 'たけし',
        avatarEmoji: '🐱',
        avatarImagePath: null,
        createdAt: now,
        updatedAt: now,
      );
      await dao.delete('test-id');

      final row = await dao.find();
      expect(row, isNull);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/data/daos/user_profile_dao_test.dart
```

- [ ] **Step 3: Implement the DAO**

```dart
// lib/data/daos/user_profile_dao.dart
import 'package:drift/drift.dart';
import 'package:home_pocket_app/data/app_database.dart';
import 'package:home_pocket_app/data/tables/user_profiles_table.dart';

class UserProfileDao {
  UserProfileDao(this._db);
  final AppDatabase _db;

  Future<UserProfileRow?> find() async {
    final query = _db.select(_db.userProfiles)..limit(1);
    final results = await query.get();
    return results.isEmpty ? null : results.first;
  }

  Future<void> upsert({
    required String id,
    required String displayName,
    required String avatarEmoji,
    required String? avatarImagePath,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) async {
    await _db.into(_db.userProfiles).insertOnConflictUpdate(
          UserProfilesCompanion.insert(
            id: id,
            displayName: displayName,
            avatarEmoji: avatarEmoji,
            avatarImagePath: Value(avatarImagePath),
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
        );
  }

  Future<void> delete(String id) async {
    await (_db.delete(_db.userProfiles)
          ..where((t) => t.id.equals(id)))
        .go();
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/data/daos/user_profile_dao_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/daos/user_profile_dao.dart test/data/daos/user_profile_dao_test.dart
git commit -m "feat(profile): add UserProfileDao with CRUD operations"
```

---

## Task 7: Data Layer — Repository Implementation

**Files:**
- Create: `lib/data/repositories/user_profile_repository_impl.dart`

- [ ] **Step 1: Implement**

```dart
// lib/data/repositories/user_profile_repository_impl.dart
import 'package:home_pocket_app/data/daos/user_profile_dao.dart';
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._dao);
  final UserProfileDao _dao;

  @override
  Future<UserProfile?> find() async {
    final row = await _dao.find();
    if (row == null) return null;
    return UserProfile(
      id: row.id,
      displayName: row.displayName,
      avatarEmoji: row.avatarEmoji,
      avatarImagePath: row.avatarImagePath,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> save(UserProfile profile) async {
    await _dao.upsert(
      id: profile.id,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      avatarImagePath: profile.avatarImagePath,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  @override
  Future<void> delete(String id) async {
    await _dao.delete(id);
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/data/repositories/user_profile_repository_impl.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/data/repositories/user_profile_repository_impl.dart
git commit -m "feat(profile): add UserProfileRepositoryImpl"
```

---

## Task 8: Application Layer — Use Cases

**Files:**
- Create: `lib/application/profile/get_user_profile_use_case.dart`
- Create: `lib/application/profile/save_user_profile_use_case.dart`
- Test: `test/application/profile/save_user_profile_use_case_test.dart`

- [ ] **Step 1: Write the test for SaveUserProfileUseCase**

```dart
// test/application/profile/save_user_profile_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket_app/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/domain/repositories/user_profile_repository.dart';

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

void main() {
  late MockUserProfileRepository mockRepo;
  late SaveUserProfileUseCase useCase;

  setUp(() {
    mockRepo = MockUserProfileRepository();
    useCase = SaveUserProfileUseCase(mockRepo);
    registerFallbackValue(UserProfile(
      id: '',
      displayName: '',
      avatarEmoji: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  group('SaveUserProfileUseCase', () {
    test('saves a valid profile', () async {
      when(() => mockRepo.save(any())).thenAnswer((_) async {});
      when(() => mockRepo.find()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isTrue);
      verify(() => mockRepo.save(any())).called(1);
    });

    test('rejects empty display name', () async {
      final result = await useCase.execute(
        displayName: '   ',
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isFalse);
      expect(result.error, SaveProfileError.nameRequired);
    });

    test('rejects display name over 50 chars', () async {
      final result = await useCase.execute(
        displayName: 'あ' * 51,
        avatarEmoji: '🐱',
      );

      expect(result.isSuccess, isFalse);
    });

    test('rejects emoji not in warmEmojis list', () async {
      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '💀',
      );

      expect(result.isSuccess, isFalse);
    });

    test('updates existing profile when id is provided', () async {
      when(() => mockRepo.save(any())).thenAnswer((_) async {});

      final result = await useCase.execute(
        id: 'existing-id',
        displayName: 'はなこ',
        avatarEmoji: '🌸',
        avatarImagePath: '/path/to/photo.jpg',
      );

      expect(result.isSuccess, isTrue);
      final saved = verify(() => mockRepo.save(captureAny())).captured.single as UserProfile;
      expect(saved.id, 'existing-id');
      expect(saved.displayName, 'はなこ');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/application/profile/save_user_profile_use_case_test.dart
```

- [ ] **Step 3: Implement GetUserProfileUseCase**

```dart
// lib/application/profile/get_user_profile_use_case.dart
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/domain/repositories/user_profile_repository.dart';

class GetUserProfileUseCase {
  GetUserProfileUseCase(this._repository);
  final UserProfileRepository _repository;

  Future<UserProfile?> execute() => _repository.find();
}
```

- [ ] **Step 4: Implement SaveUserProfileUseCase**

```dart
// lib/application/profile/save_user_profile_use_case.dart
import 'dart:io';

import 'package:ulid/ulid.dart';

import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket_app/shared/constants/warm_emojis.dart';

enum SaveProfileError { nameRequired, nameTooLong, invalidEmoji }

class SaveProfileResult {
  const SaveProfileResult.success(this.profile)
      : error = null,
        isSuccess = true;
  const SaveProfileResult.failure(this.error)
      : profile = null,
        isSuccess = false;

  final UserProfile? profile;
  final SaveProfileError? error;
  final bool isSuccess;
}

class SaveUserProfileUseCase {
  SaveUserProfileUseCase(this._repository);
  final UserProfileRepository _repository;

  Future<SaveProfileResult> execute({
    String? id,
    required String displayName,
    required String avatarEmoji,
    String? avatarImagePath,
    String? oldAvatarImagePath,
  }) async {
    // Validate displayName
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      return const SaveProfileResult.failure(SaveProfileError.nameRequired);
    }
    if (trimmed.length > 50) {
      return const SaveProfileResult.failure(SaveProfileError.nameTooLong);
    }

    // Validate emoji
    if (!warmEmojis.contains(avatarEmoji)) {
      return const SaveProfileResult.failure(SaveProfileError.invalidEmoji);
    }

    final now = DateTime.now();
    final profileId = id ?? Ulid().toString();

    // Preserve original createdAt on update
    final existing = id != null ? await _repository.find() : null;

    final profile = UserProfile(
      id: profileId,
      displayName: trimmed,
      avatarEmoji: avatarEmoji,
      avatarImagePath: avatarImagePath,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _repository.save(profile);

    // Delete old avatar image if replaced
    if (oldAvatarImagePath != null &&
        oldAvatarImagePath != avatarImagePath) {
      try {
        final oldFile = File(oldAvatarImagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {
        // Non-critical — log but don't fail
      }
    }

    return SaveProfileResult.success(profile);
  }
}
```

- [ ] **Step 5: Run test — expect PASS**

```bash
flutter test test/application/profile/save_user_profile_use_case_test.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/application/profile/ test/application/profile/
git commit -m "feat(profile): add Get/Save UserProfile use cases with validation"
```

---

## Task 9: i18n — Add Profile Strings

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Add keys to all 3 ARB files**

Add these keys to each ARB file (inside the existing JSON object, before the closing `}`):

**app_ja.arb:**
```json
  "profileSetup": "はじめまして！",
  "profileSetupSubtitle": "まもる家計簿へようこそ",
  "profileNickname": "あなたの呼び名",
  "profileNicknamePlaceholder": "ニックネームを入力",
  "profileStart": "はじめる",
  "profileSelectAvatar": "アバターを選択",
  "profileEmojiTab": "Emoji",
  "profilePhotoTab": "写真",
  "profileEdit": "プロフィールを編集",
  "profileCancel": "キャンセル",
  "profileDone": "完了",
  "profilePreview": "プレビュー",
  "welcomeTo": "まもる家計簿へようこそ",
  "profileNameRequired": "ニックネームを入力してください",
  "profileSave": "保存",
  "profileChangeAvatar": "タップしてアバターを変更",
  "profilePhotoPermissionDenied": "写真へのアクセスが拒否されました",
  "profilePhotoFailed": "写真の読み込みに失敗しました",
  "profileSaveFailed": "保存に失敗しました",
  "profileNameTooLong": "ニックネームは50文字以内で入力してください",
  "profileUploadPhoto": "写真をアップロード"
```

**app_en.arb:**
```json
  "profileSetup": "Nice to meet you!",
  "profileSetupSubtitle": "Welcome to Home Pocket",
  "profileNickname": "Your nickname",
  "profileNicknamePlaceholder": "Enter your nickname",
  "profileStart": "Get Started",
  "profileSelectAvatar": "Select Avatar",
  "profileEmojiTab": "Emoji",
  "profilePhotoTab": "Photo",
  "profileEdit": "Edit Profile",
  "profileCancel": "Cancel",
  "profileDone": "Done",
  "profilePreview": "Preview",
  "welcomeTo": "Welcome to Home Pocket",
  "profileNameRequired": "Please enter a nickname",
  "profileSave": "Save",
  "profileChangeAvatar": "Tap to change avatar",
  "profilePhotoPermissionDenied": "Photo access denied",
  "profilePhotoFailed": "Failed to load photo",
  "profileSaveFailed": "Failed to save",
  "profileNameTooLong": "Nickname must be 50 characters or less",
  "profileUploadPhoto": "Upload Photo"
```

**app_zh.arb:**
```json
  "profileSetup": "初次见面！",
  "profileSetupSubtitle": "欢迎使用守护家计簿",
  "profileNickname": "你的昵称",
  "profileNicknamePlaceholder": "请输入昵称",
  "profileStart": "开始",
  "profileSelectAvatar": "选择头像",
  "profileEmojiTab": "表情",
  "profilePhotoTab": "照片",
  "profileEdit": "编辑个人资料",
  "profileCancel": "取消",
  "profileDone": "完成",
  "profilePreview": "预览",
  "welcomeTo": "欢迎使用守护家计簿",
  "profileNameRequired": "请输入昵称",
  "profileSave": "保存",
  "profileChangeAvatar": "点击更换头像",
  "profilePhotoPermissionDenied": "照片访问被拒绝",
  "profilePhotoFailed": "照片加载失败",
  "profileSaveFailed": "保存失败",
  "profileNameTooLong": "昵称不能超过50个字符",
  "profileUploadPhoto": "上传照片"
```

- [ ] **Step 2: Generate localizations**

```bash
flutter gen-l10n
```

Expected: Generated files in `lib/generated/`.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/l10n/ lib/generated/
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(profile): add i18n strings for profile onboarding (ja/en/zh)"
```

---

## Task 10: Presentation — Providers

**Files:**
- Create: `lib/features/profile/presentation/providers/user_profile_providers.dart`

- [ ] **Step 1: Create providers**

```dart
// lib/features/profile/presentation/providers/user_profile_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:home_pocket_app/data/app_database.dart';
import 'package:home_pocket_app/data/daos/user_profile_dao.dart';
import 'package:home_pocket_app/data/repositories/user_profile_repository_impl.dart';
import 'package:home_pocket_app/application/profile/get_user_profile_use_case.dart';
import 'package:home_pocket_app/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/domain/repositories/user_profile_repository.dart';

part 'user_profile_providers.g.dart';

@riverpod
UserProfileDao userProfileDao(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  return UserProfileDao(db);
}

@riverpod
UserProfileRepository userProfileRepository(Ref ref) {
  final dao = ref.watch(userProfileDaoProvider);
  return UserProfileRepositoryImpl(dao);
}

@riverpod
GetUserProfileUseCase getUserProfileUseCase(Ref ref) {
  return GetUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
}

@riverpod
SaveUserProfileUseCase saveUserProfileUseCase(Ref ref) {
  return SaveUserProfileUseCase(ref.watch(userProfileRepositoryProvider));
}

@riverpod
Future<UserProfile?> userProfile(Ref ref) async {
  final useCase = ref.watch(getUserProfileUseCaseProvider);
  return useCase.execute();
}
```

Note: `appDatabaseProvider` must already exist in the codebase (check `lib/features/accounting/presentation/providers/repository_providers.dart` for the pattern — it likely gets the DB from the ProviderContainer override set in `main.dart`). Adapt the import accordingly.

- [ ] **Step 2: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/profile/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/providers/
git commit -m "feat(profile): add Riverpod providers for profile feature"
```

---

## Task 11: Presentation — AvatarDisplay Widget

**Files:**
- Create: `lib/features/profile/presentation/widgets/avatar_display.dart`

- [ ] **Step 1: Implement the widget**

Ref design: Pencil node `6cHmL` (light), `CScYQ` (dark) — 110×110 circle, gradient fill, emoji centered.

```dart
// lib/features/profile/presentation/widgets/avatar_display.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:home_pocket_app/core/theme/app_colors.dart';

class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    super.key,
    required this.emoji,
    this.imagePath,
    this.size = 110,
    this.onTap,
  });

  final String emoji;
  final String? imagePath;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = size / 2;

    Widget content;
    if (imagePath != null) {
      content = ClipOval(
        child: Image.file(
          File(imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildEmojiAvatar(isDark),
        ),
      );
    } else {
      content = _buildEmojiAvatar(isDark);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF3D2020), const Color(0xFF2D1818), const Color(0xFF251518)]
                : [const Color(0xFFFFD4CC), const Color(0xFFFEEAE6), const Color(0xFFFEF5F4)],
          ),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPrimary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildEmojiAvatar(bool isDark) {
    return Center(
      child: Text(
        emoji,
        style: TextStyle(
          fontSize: size * 0.47,
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/profile/presentation/widgets/avatar_display.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/widgets/avatar_display.dart
git commit -m "feat(profile): add AvatarDisplay widget with emoji/image support"
```

---

## Task 12: Presentation — ScatteredEmojiBackground Widget

**Files:**
- Create: `lib/features/profile/presentation/widgets/scattered_emoji_background.dart`

- [ ] **Step 1: Implement**

Ref design: Pencil node `h5JI2` — scattered emojis at specific positions with low opacity and rotation.

```dart
// lib/features/profile/presentation/widgets/scattered_emoji_background.dart
import 'package:flutter/material.dart';

class ScatteredEmojiBackground extends StatelessWidget {
  const ScatteredEmojiBackground({super.key, required this.child});

  final Widget child;

  // Positions as fractions of screen width/height (0.0–1.0)
  static const _decorations = [
    _EmojiDeco('🌸', 0.10, 0.11, 24, 0.12, 15),
    _EmojiDeco('🌿', 0.80, 0.16, 20, 0.10, -10),
    _EmojiDeco('⭐', 0.07, 0.40, 16, 0.08, 20),
    _EmojiDeco('🍃', 0.87, 0.48, 18, 0.10, -12),
    _EmojiDeco('💫', 0.14, 0.80, 14, 0.08, 8),
    _EmojiDeco('🌷', 0.82, 0.78, 18, 0.10, -5),
    _EmojiDeco('✨', 0.85, 0.90, 14, 0.08, 0),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            child,
            ..._decorations.map((d) => Positioned(
                  left: d.xFrac * w,
                  top: d.yFrac * h,
                  child: Transform.rotate(
                    angle: d.rotation * 3.14159 / 180,
                    child: Opacity(
                      opacity: d.opacity,
                      child: Text(d.emoji, style: TextStyle(fontSize: d.size)),
                    ),
                  ),
                )),
          ],
        );
      },
    );
  }
}

class _EmojiDeco {
  const _EmojiDeco(this.emoji, this.xFrac, this.yFrac, this.size, this.opacity, this.rotation);
  final String emoji;
  final double xFrac, yFrac, size, opacity, rotation;
}
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/profile/presentation/widgets/scattered_emoji_background.dart
git commit -m "feat(profile): add ScatteredEmojiBackground decorative widget"
```

---

## Task 13: Presentation — ProfileOnboardingScreen

**Files:**
- Create: `lib/features/profile/presentation/screens/profile_onboarding_screen.dart`
- Test: `test/features/profile/presentation/screens/profile_onboarding_screen_test.dart`

- [ ] **Step 1: Write widget test**

```dart
// test/features/profile/presentation/screens/profile_onboarding_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_pocket_app/features/profile/presentation/screens/profile_onboarding_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_pocket_app/generated/app_localizations.dart';

Widget buildTestApp(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      locale: const Locale('ja'),
      home: child,
    ),
  );
}

void main() {
  group('ProfileOnboardingScreen', () {
    testWidgets('shows welcome text and disabled button initially', (tester) async {
      await tester.pumpWidget(buildTestApp(const ProfileOnboardingScreen()));
      await tester.pumpAndSettle();

      expect(find.text('はじめまして！'), findsOneWidget);
      // Button should exist but be visually disabled (no tap handler when empty)
      expect(find.text('はじめる'), findsOneWidget);
    });

    testWidgets('enables button when nickname is entered', (tester) async {
      await tester.pumpWidget(buildTestApp(const ProfileOnboardingScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'たけし');
      await tester.pumpAndSettle();

      // Button should now be tappable
      expect(find.text('はじめる'), findsOneWidget);
    });

    testWidgets('shows avatar that can be tapped', (tester) async {
      await tester.pumpWidget(buildTestApp(const ProfileOnboardingScreen()));
      await tester.pumpAndSettle();

      // Should display a default emoji avatar
      expect(find.byType(GestureDetector), findsWidgets);
    });
  });
}
```

- [ ] **Step 2: Implement the screen**

Ref design: Pencil nodes `h5JI2` (light) / `MUen3` (dark).

```dart
// lib/features/profile/presentation/screens/profile_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_pocket_app/core/theme/app_colors.dart';
import 'package:home_pocket_app/generated/app_localizations.dart';
import 'package:home_pocket_app/shared/constants/warm_emojis.dart';
import 'package:home_pocket_app/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/scattered_emoji_background.dart';
import 'package:home_pocket_app/features/profile/presentation/screens/avatar_picker_screen.dart';
import 'package:home_pocket_app/features/home/presentation/screens/main_shell_screen.dart';

class ProfileOnboardingScreen extends ConsumerStatefulWidget {
  const ProfileOnboardingScreen({super.key, required this.bookId});
  final String bookId;

  @override
  ConsumerState<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends ConsumerState<ProfileOnboardingScreen> {
  final _nicknameController = TextEditingController();
  late String _selectedEmoji;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedEmoji = randomWarmEmoji();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSubmit => _nicknameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _onStart() async {
    if (!_canSubmit) return;
    setState(() => _isSaving = true);

    final useCase = ref.read(saveUserProfileUseCaseProvider);
    final result = await useCase.execute(
      displayName: _nicknameController.text,
      avatarEmoji: _selectedEmoji,
      avatarImagePath: _selectedImagePath,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MainShellScreen(bookId: widget.bookId)),
      );
    } else {
      setState(() => _isSaving = false);
      final errorMsg = switch (result.error) {
        SaveProfileError.nameRequired => l10n.profileNameRequired,
        SaveProfileError.nameTooLong => l10n.profileNameTooLong,
        _ => l10n.profileSaveFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  Future<void> _openAvatarPicker() async {
    final result = await Navigator.of(context).push<AvatarPickerResult>(
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          currentEmoji: _selectedEmoji,
          currentImagePath: _selectedImagePath,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedEmoji = result.emoji;
        _selectedImagePath = result.imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
      body: ScatteredEmojiBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Title area
                Text(
                  l10n.profileSetup,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.profileSetupSubtitle,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14,
                    color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Avatar
                AvatarDisplay(
                  emoji: _selectedEmoji,
                  imagePath: _selectedImagePath,
                  size: 110,
                  onTap: _openAvatarPicker,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('✏️ ', style: TextStyle(fontSize: 12, color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary)),
                    Text(
                      l10n.profileChangeAvatar,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profileNickname,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nicknameController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: l10n.profileNicknamePlaceholder,
                          prefixText: '📝 ',
                          filled: true,
                          fillColor: isDark ? AppColorsDark.card : AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE85A4F), Color(0xFFF08070)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPrimary.withValues(alpha: 0.16),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: MaterialButton(
                            onPressed: _canSubmit ? _onStart : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              '${l10n.profileStart} ✨',
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: _canSubmit ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Run test**

```bash
flutter test test/features/profile/presentation/screens/profile_onboarding_screen_test.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/screens/profile_onboarding_screen.dart test/features/profile/presentation/screens/
git commit -m "feat(profile): add ProfileOnboardingScreen with V5 playful scattered design"
```

---

## Task 14: Presentation — AvatarPickerScreen

**Files:**
- Create: `lib/features/profile/presentation/screens/avatar_picker_screen.dart`

- [ ] **Step 1: Implement**

Ref design: Pencil nodes `NNogy` (light) / `s6UDM` (dark).

```dart
// lib/features/profile/presentation/screens/avatar_picker_screen.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:home_pocket_app/core/theme/app_colors.dart';
import 'package:home_pocket_app/generated/app_localizations.dart';
import 'package:home_pocket_app/shared/constants/warm_emojis.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/scattered_emoji_background.dart';

class AvatarPickerResult {
  const AvatarPickerResult({required this.emoji, this.imagePath});
  final String emoji;
  final String? imagePath;
}

class AvatarPickerScreen extends StatefulWidget {
  const AvatarPickerScreen({
    super.key,
    required this.currentEmoji,
    this.currentImagePath,
  });

  final String currentEmoji;
  final String? currentImagePath;

  @override
  State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}

class _AvatarPickerScreenState extends State<AvatarPickerScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedEmoji;
  String? _selectedImagePath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedEmoji = widget.currentEmoji;
    _selectedImagePath = widget.currentImagePath;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDone() {
    Navigator.of(context).pop(
      AvatarPickerResult(emoji: _selectedEmoji, imagePath: _selectedImagePath),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null || !mounted) return;

      final dir = await getApplicationDocumentsDirectory();
      final avatarDir = Directory('${dir.path}/avatars');
      if (!await avatarDir.exists()) {
        await avatarDir.create(recursive: true);
      }

      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final destPath = '${avatarDir.path}/$fileName';
      await File(picked.path).copy(destPath);

      setState(() => _selectedImagePath = destPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).profilePhotoFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
      body: ScatteredEmojiBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(l10n.profileCancel, style: TextStyle(
                        fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500,
                        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                      )),
                    ),
                    Text(l10n.profileSelectAvatar, style: const TextStyle(
                      fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700,
                    )),
                    GestureDetector(
                      onTap: _onDone,
                      child: Text('${l10n.profileDone} ✓', style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700,
                        color: AppColors.accentPrimary,
                      )),
                    ),
                  ],
                ),
              ),

              // Preview
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    AvatarDisplay(emoji: _selectedEmoji, imagePath: _selectedImagePath, size: 110),
                    const SizedBox(height: 10),
                    Text('✏️ ${l10n.profileChangeAvatar}', style: TextStyle(
                      fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w500,
                      color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                    )),
                  ],
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.accentPrimary,
                indicatorWeight: 2,
                labelColor: AppColors.accentPrimary,
                labelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w700),
                unselectedLabelColor: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
                tabs: [Tab(text: l10n.profileEmojiTab), Tab(text: l10n.profilePhotoTab)],
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEmojiGrid(isDark),
                    _buildPhotoTab(l10n, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: GridView.builder(
        itemCount: warmEmojis.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final emoji = warmEmojis[index];
          final isSelected = emoji == _selectedEmoji && _selectedImagePath == null;

          return GestureDetector(
            onTap: () => setState(() {
              _selectedEmoji = emoji;
              _selectedImagePath = null;
            }),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColorsDark.backgroundMuted : AppColors.backgroundMuted,
                borderRadius: BorderRadius.circular(12),
                border: isSelected
                    ? Border.all(color: AppColors.accentPrimary, width: 2)
                    : null,
              ),
              child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28))),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPhotoTab(S l10n, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _pickPhoto,
            icon: Icon(Icons.add_photo_alternate_outlined, size: 48,
              color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(l10n.profilePhotoTab, style: TextStyle(
            fontFamily: 'Outfit', fontSize: 14,
            color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
          )),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/profile/presentation/screens/avatar_picker_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/screens/avatar_picker_screen.dart
git commit -m "feat(profile): add AvatarPickerScreen with emoji grid and photo tab"
```

---

## Task 15: Presentation — ProfileEditScreen

**Files:**
- Create: `lib/features/profile/presentation/screens/profile_edit_screen.dart`

- [ ] **Step 1: Implement**

Ref design: Pencil nodes `wK1hr` (light) / `xLQll` (dark).

```dart
// lib/features/profile/presentation/screens/profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_pocket_app/core/theme/app_colors.dart';
import 'package:home_pocket_app/generated/app_localizations.dart';
import 'package:home_pocket_app/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket_app/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/scattered_emoji_background.dart';
import 'package:home_pocket_app/features/profile/presentation/screens/avatar_picker_screen.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  late final TextEditingController _nicknameController;
  late String _selectedEmoji;
  String? _selectedImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.profile.displayName);
    _selectedEmoji = widget.profile.avatarEmoji;
    _selectedImagePath = widget.profile.avatarImagePath;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  bool get _canSave => _nicknameController.text.trim().isNotEmpty && !_isSaving;

  Future<void> _onSave() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    final useCase = ref.read(saveUserProfileUseCaseProvider);
    final result = await useCase.execute(
      id: widget.profile.id,
      displayName: _nicknameController.text,
      avatarEmoji: _selectedEmoji,
      avatarImagePath: _selectedImagePath,
      oldAvatarImagePath: widget.profile.avatarImagePath,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      ref.invalidate(userProfileProvider);
      Navigator.of(context).pop(true);
    } else {
      setState(() => _isSaving = false);
      final l10n = S.of(context);
      final errorMsg = switch (result.error) {
        SaveProfileError.nameRequired => l10n.profileNameRequired,
        SaveProfileError.nameTooLong => l10n.profileNameTooLong,
        _ => l10n.profileSaveFailed,
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  Future<void> _openAvatarPicker() async {
    final result = await Navigator.of(context).push<AvatarPickerResult>(
      MaterialPageRoute(
        builder: (_) => AvatarPickerScreen(
          currentEmoji: _selectedEmoji,
          currentImagePath: _selectedImagePath,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _selectedEmoji = result.emoji;
        _selectedImagePath = result.imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColorsDark.background : AppColors.background,
      body: ScatteredEmojiBackground(
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(Icons.chevron_left, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Text(l10n.profileEdit, style: const TextStyle(
                      fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700,
                    )),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      AvatarDisplay(
                        emoji: _selectedEmoji,
                        imagePath: _selectedImagePath,
                        size: 110,
                        onTap: _openAvatarPicker,
                      ),
                      const SizedBox(height: 10),
                      Text('✏️ ${l10n.profileChangeAvatar}', style: TextStyle(
                        fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w500,
                        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                      )),
                      const SizedBox(height: 32),

                      // Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(l10n.profileNickname, style: TextStyle(
                          fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                        )),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _nicknameController,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: l10n.profileNicknamePlaceholder,
                          prefixText: '📝 ',
                          filled: true,
                          fillColor: isDark ? AppColorsDark.card : AppColors.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(color: AppColors.accentPrimary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE85A4F), Color(0xFFF08070)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentPrimary.withValues(alpha: 0.16),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: MaterialButton(
                            onPressed: _canSave ? _onSave : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              '${l10n.profileSave} ✨',
                              style: TextStyle(
                                fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700,
                                color: _canSave ? Colors.white : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/profile/presentation/screens/profile_edit_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/profile/presentation/screens/profile_edit_screen.dart
git commit -m "feat(profile): add ProfileEditScreen for settings profile editing"
```

---

## Task 16: Presentation — ProfileSectionCard for Settings

**Files:**
- Create: `lib/features/profile/presentation/widgets/profile_section_card.dart`
- Modify: `lib/features/settings/presentation/screens/settings_screen.dart`

- [ ] **Step 1: Create the card widget**

```dart
// lib/features/profile/presentation/widgets/profile_section_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:home_pocket_app/core/theme/app_colors.dart';
import 'package:home_pocket_app/generated/app_localizations.dart';
import 'package:home_pocket_app/features/profile/presentation/providers/user_profile_providers.dart';
import 'package:home_pocket_app/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket_app/features/profile/presentation/screens/profile_edit_screen.dart';

class ProfileSectionCard extends ConsumerWidget {
  const ProfileSectionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return profileAsync.when(
      data: (profile) {
        if (profile == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => ProfileEditScreen(profile: profile)),
            );
            if (changed == true) ref.invalidate(userProfileProvider);
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColorsDark.card : AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColorsDark.borderDefault : AppColors.borderDefault),
            ),
            child: Row(
              children: [
                AvatarDisplay(emoji: profile.avatarEmoji, imagePath: profile.avatarImagePath, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.displayName, style: const TextStyle(
                        fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600,
                      )),
                      const SizedBox(height: 2),
                      Text(l10n.profileEdit, style: TextStyle(
                        fontFamily: 'Outfit', fontSize: 12,
                        color: isDark ? AppColorsDark.textSecondary : AppColors.textSecondary,
                      )),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 20,
                  color: isDark ? AppColorsDark.textTertiary : AppColors.textTertiary),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
```

- [ ] **Step 2: Add to Settings screen**

In `lib/features/settings/presentation/screens/settings_screen.dart`, add import and insert `const ProfileSectionCard()` as the **first child** in the main content column/list, above the existing settings sections.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/profile/presentation/widgets/profile_section_card.dart lib/features/settings/presentation/screens/settings_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/widgets/profile_section_card.dart lib/features/settings/presentation/screens/settings_screen.dart
git commit -m "feat(profile): add ProfileSectionCard to Settings screen"
```

---

## Task 17: App Startup — Onboarding Navigation

**Files:**
- Modify: `lib/main.dart`

- [ ] **Step 1: Add profile check to startup flow**

In `lib/main.dart`, after the existing seed operations (`seedCategories`, `ensureDefaultBook`), add profile existence check:

```dart
// After existing initialization, determine start screen
import 'package:home_pocket_app/data/daos/user_profile_dao.dart';
import 'package:home_pocket_app/features/profile/presentation/screens/profile_onboarding_screen.dart';

// In the app state initialization (initState or build):
final userProfileDao = UserProfileDao(database);
final existingProfile = await userProfileDao.find();
final needsOnboarding = existingProfile == null;
```

Then, in the `MaterialApp.home:` property, use conditional navigation:

```dart
home: needsOnboarding
    ? const ProfileOnboardingScreen()
    : const MainShellScreen(),
```

The exact integration depends on the current `main.dart` structure (whether state is managed in `initState` or via Riverpod). Follow the existing async initialization pattern used for `seedCategories`.

- [ ] **Step 2: Test manually**

```bash
flutter run
```

Verify: First launch shows `ProfileOnboardingScreen`. After completing onboarding, app shows `MainShellScreen`. Kill and relaunch → goes directly to `MainShellScreen`.

- [ ] **Step 3: Commit**

```bash
git add lib/main.dart
git commit -m "feat(profile): add onboarding check to app startup flow"
```

---

## Task 18: Run Full Test Suite + Analyze

- [ ] **Step 1: Run analyzer**

```bash
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Run code generation (ensure clean)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Final commit if any fixes needed**

```bash
git add -A
git commit -m "chore(profile): fix analyzer warnings and test issues"
```

---

## Dependency Graph

```
Task 1  (pubspec)
Task 2  (warm emojis)
Task 3  (domain model)     → depends on nothing
Task 4  (repo interface)   → depends on Task 3
Task 5  (drift table + DB) → depends on nothing
Task 6  (DAO)              → depends on Task 5
Task 7  (repo impl)        → depends on Task 4, Task 6
Task 8  (use cases)        → depends on Task 2, Task 4, Task 7
Task 9  (i18n)             → depends on nothing
Task 10 (providers)        → depends on Task 7, Task 8
Task 11 (avatar widget)    → depends on nothing (theme only)
Task 12 (scattered bg)     → depends on nothing
Task 13 (onboarding)       → depends on Task 10, Task 11, Task 12
Task 14 (avatar picker)    → depends on Task 2, Task 11, Task 12
Task 15 (profile edit)     → depends on Task 10, Task 11, Task 14
Task 16 (settings card)    → depends on Task 10, Task 11, Task 15
Task 17 (app startup)      → depends on Task 6, Task 13
Task 18 (verify)           → depends on all
```

**Parallelizable groups:**
- Group A: Tasks 1, 2, 3, 5, 9, 11, 12 (all independent)
- Group B: Tasks 4, 6 (after Group A)
- Group C: Tasks 7, 8, 10 (after Group B)
- Group D: Tasks 13, 14 (after Group C)
- Group E: Tasks 15, 16, 17 (after Group D)
- Group F: Task 18 (final)
