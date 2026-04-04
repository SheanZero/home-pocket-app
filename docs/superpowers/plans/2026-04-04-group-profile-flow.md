# Group Profile Flow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Integrate user profile (name + emoji avatar) into the Group create/join flow, add a two-step join confirmation, Group rename, and avatar E2EE sync — replacing the old `PairingScreen` with a new multi-screen flow.

**Architecture:** New screens in `features/family_sync/presentation/screens/`, three use cases migrated from `features/family_sync/use_cases/` to `application/family_sync/` with profile field integration, three new use cases (ConfirmJoin, Rename, SyncAvatar). Data layer extended with `groupName` on Groups and profile columns on GroupMembers (v13 migration). Existing `AvatarDisplay` widget from profile feature is reused with an added `gradientColors` parameter.

**Tech Stack:** Drift (SQLCipher) for storage, Freezed for domain models, Riverpod (mix of codegen and manual providers), existing E2EE sync infrastructure (NaCl box), SHA-256 for avatar change detection, image_picker (already installed), lucide_icons (new dependency for Pencil design icons).

**Package name:** `home_pocket` (all imports use `package:home_pocket/...`).

**Spec:** `docs/superpowers/specs/2026-04-03-group-profile-flow-design.md`

**UI Design (Pencil `untitled.pen`):**

| Screen | Node ID | Label Node ID |
|--------|---------|---------------|
| GroupChoiceScreen (entry) | `MJ4Qp` | `myIaB` |
| CreateGroupScreen (Owner step 1) | `GStw3` | `s5jkf` |
| MemberApprovalScreen (Owner step 2) | `nD1Kw` | `PHpqv` |
| GroupManagementScreen (Owner step 3) | `zd7Sl` | `qBjLq` |
| JoinGroupScreen (Joiner step 1) | `ehXZ7` | `nv96D` |
| ConfirmJoinScreen (Joiner step 2) | `cl6P6` | `7ItMN` |
| WaitingApprovalScreen (Joiner step 3) | `sjU8l` | `YxpXr` |
| JoinSuccessScreen (Joiner step 4) | `kQpPG` | `B2YzZ` |
| Owner Flow label | — | `WQjKB` |
| Joiner Flow label | — | `xYz65` |

**Design Tokens (from Pencil):**
- Font: Outfit throughout (title 22-26/700, body 14-16/400-600, label 12/600 ls:0.5, code 36/700)
- CTA: gradient `#E85A4F` → `#F08070`, h:52, r:16, shadow `#E85A4F28`
- Card: fill `#FFFFFF`, stroke `#EFEFEF` 1px, r:16-20, shadow `offset(0,2-4) blur 8-16 #0000000A`
- Avatar coral gradient: `#FFD4CC` → `#FEEAE6` → `#FEF5F4` (owner)
- Avatar purple gradient: `#E8D5F5` → `#F3EAF9` → `#FAF5FD` (joiner)
- Bg: `#FCFBF9` (AppColors.background)

---

## File Structure

### New Files (Create)

| # | File | Responsibility |
|---|------|---------------|
| 1 | `lib/application/family_sync/create_group_use_case.dart` | Rewrite: + profile fields + groupName |
| 2 | `lib/application/family_sync/join_group_use_case.dart` | Rewrite: verify-only (returns group info) |
| 3 | `lib/application/family_sync/confirm_join_use_case.dart` | New: Joiner confirms join after preview |
| 4 | `lib/application/family_sync/confirm_member_use_case.dart` | Rewrite: + avatar sync trigger |
| 5 | `lib/application/family_sync/rename_group_use_case.dart` | New: Owner renames group |
| 6 | `lib/application/family_sync/sync_avatar_use_case.dart` | New: SHA-256 check + E2EE avatar transfer |
| 7 | `lib/features/family_sync/presentation/screens/group_choice_screen.dart` | Entry point (create / join choice) |
| 8 | `lib/features/family_sync/presentation/screens/create_group_screen.dart` | Owner step 1 |
| 9 | `lib/features/family_sync/presentation/screens/join_group_screen.dart` | Joiner step 1 |
| 10 | `lib/features/family_sync/presentation/screens/confirm_join_screen.dart` | Joiner step 2 |
| 11 | `lib/features/family_sync/presentation/screens/join_success_screen.dart` | Joiner step 4 |
| 12 | `lib/features/family_sync/presentation/widgets/group_rename_dialog.dart` | Rename dialog |
| 13 | `lib/features/family_sync/presentation/providers/avatar_sync_providers.dart` | Avatar sync state |
| 14 | `test/unit/application/family_sync/create_group_use_case_test.dart` | Use case test |
| 15 | `test/unit/application/family_sync/join_group_use_case_test.dart` | Use case test |
| 16 | `test/unit/application/family_sync/confirm_join_use_case_test.dart` | Use case test |
| 17 | `test/unit/application/family_sync/rename_group_use_case_test.dart` | Use case test |
| 18 | `test/widget/features/family_sync/screens/group_choice_screen_test.dart` | Widget test |
| 19 | `test/widget/features/family_sync/screens/create_group_screen_test.dart` | Widget test |

### Modified Files

| # | File | Change |
|---|------|--------|
| M1 | `lib/data/tables/groups_table.dart` | Add `groupName` column |
| M2 | `lib/data/tables/group_members_table.dart` | Add 4 profile columns |
| M3 | `lib/data/app_database.dart` | Bump to v13, add migration |
| M4 | `lib/data/daos/group_dao.dart` | Add `updateGroupName` |
| M5 | `lib/data/daos/group_member_dao.dart` | Add `updateMemberProfile` |
| M6 | `lib/data/repositories/group_repository_impl.dart` | Map new fields |
| M7 | `lib/features/family_sync/domain/models/group_info.dart` | Add `groupName` |
| M8 | `lib/features/family_sync/domain/models/group_member.dart` | Add 4 profile fields |
| M9 | `lib/features/family_sync/domain/repositories/group_repository.dart` | `updateGroupName`, `updateMemberProfile` |
| M10 | `lib/infrastructure/sync/relay_api_client.dart` | `createGroup(profile)`, `joinGroup(profile)`, `confirmJoin`, `renameGroup` |
| M11 | `lib/features/family_sync/presentation/providers/group_providers.dart` | New use case providers |
| M12 | `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` | Rewrite with profile |
| M13 | `lib/features/family_sync/presentation/screens/member_approval_screen.dart` | Rewrite with profile |
| M14 | `lib/features/family_sync/presentation/screens/group_management_screen.dart` | Rewrite with profile |
| M15 | `lib/features/family_sync/presentation/widgets/member_list_tile.dart` | Use AvatarDisplay |
| M16 | `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart` | GroupChoiceScreen nav |
| M17 | `lib/features/profile/presentation/widgets/avatar_display.dart` | Add `gradientColors` param |
| M18 | `lib/l10n/app_ja.arb` | Add ~37 group i18n keys |
| M19 | `lib/l10n/app_en.arb` | Add ~37 group i18n keys |
| M20 | `lib/l10n/app_zh.arb` | Add ~37 group i18n keys |
| M21 | `lib/features/home/presentation/screens/home_screen.dart` | Replace PairingScreen → GroupChoiceScreen |

### Delete Files

| # | File | Reason |
|---|------|--------|
| D1 | `lib/features/family_sync/presentation/screens/pairing_screen.dart` | Replaced by GroupChoiceScreen + create/join |
| D2 | `lib/features/family_sync/use_cases/create_group_use_case.dart` | Migrated to application/ |
| D3 | `lib/features/family_sync/use_cases/join_group_use_case.dart` | Migrated to application/ |
| D4 | `lib/features/family_sync/use_cases/confirm_member_use_case.dart` | Migrated to application/ |

---

## Task 0: Add `lucide_icons` Dependency

**Files:**
- Modify: `pubspec.yaml`

The Pencil designs use Lucide icons throughout. This package is not yet in the project.

- [ ] **Step 1: Add lucide_icons to pubspec.yaml**

Under `dependencies:`, add:

```yaml
  lucide_icons: ^0.257.0
```

- [ ] **Step 2: Run pub get**

```bash
cd /Users/xinz/Development/home-pocket-app && flutter pub get
```

Expected: Dependencies resolved successfully.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add lucide_icons dependency for group profile flow UI"
```

---

## Task 1: Data Layer — Table Extensions + DB Migration

**Files:**
- Modify: `lib/data/tables/groups_table.dart`
- Modify: `lib/data/tables/group_members_table.dart`
- Modify: `lib/data/app_database.dart`

- [ ] **Step 1: Add `groupName` column to Groups table**

In `lib/data/tables/groups_table.dart`, add after the `role` column:

```dart
TextColumn get groupName => text().withDefault(const Constant(''))();
```

Full file becomes:
```dart
import 'package:drift/drift.dart';

@DataClassName('GroupData')
class Groups extends Table {
  TextColumn get groupId => text()();
  TextColumn get status => text()();
  TextColumn get role => text()();
  TextColumn get groupName => text().withDefault(const Constant(''))();
  TextColumn get inviteCode => text().nullable()();
  IntColumn get inviteExpiresAt => integer().nullable()();
  TextColumn get groupKey => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_groups_status', columns: {#status}),
  ];
}
```

- [ ] **Step 2: Add profile columns to GroupMembers table**

In `lib/data/tables/group_members_table.dart`, add after `status`:

```dart
TextColumn get displayName => text().withDefault(const Constant(''))();
TextColumn get avatarEmoji => text().withDefault(const Constant('🏠'))();
TextColumn get avatarImagePath => text().nullable()();
TextColumn get avatarImageHash => text().nullable()();
```

Full file becomes:
```dart
import 'package:drift/drift.dart';

@DataClassName('GroupMemberData')
class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get deviceId => text()();
  TextColumn get publicKey => text()();
  TextColumn get deviceName => text()();
  TextColumn get role => text()();
  TextColumn get status => text()();
  TextColumn get displayName => text().withDefault(const Constant(''))();
  TextColumn get avatarEmoji => text().withDefault(const Constant('🏠'))();
  TextColumn get avatarImagePath => text().nullable()();
  TextColumn get avatarImageHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {groupId, deviceId};

  List<TableIndex> get customIndices => [
    TableIndex(name: 'idx_group_members_group_id', columns: {#groupId}),
    TableIndex(name: 'idx_group_members_status', columns: {#status}),
  ];
}
```

- [ ] **Step 3: Bump schema version and add v13 migration**

In `lib/data/app_database.dart`, change `schemaVersion => 12` to `schemaVersion => 13` and add migration block inside `onUpgrade` after the `from < 12` block:

```dart
if (from < 13) {
  await transaction(() async {
    await migrator.addColumn(groups, groups.groupName);
    await migrator.addColumn(groupMembers, groupMembers.displayName);
    await migrator.addColumn(groupMembers, groupMembers.avatarEmoji);
    await migrator.addColumn(groupMembers, groupMembers.avatarImagePath);
    await migrator.addColumn(groupMembers, groupMembers.avatarImageHash);
    // Backfill: set displayName to deviceName for existing members
    await customStatement(
      "UPDATE group_members SET display_name = device_name WHERE display_name = ''",
    );
  });
}
```

- [ ] **Step 4: Run code generation**

```bash
cd /Users/xinz/Development/home-pocket-app && flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: Regenerated `app_database.g.dart` with new schema.

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/data/
```

Expected: No issues found.

- [ ] **Step 6: Commit**

```bash
git add lib/data/tables/groups_table.dart lib/data/tables/group_members_table.dart lib/data/app_database.dart lib/data/app_database.g.dart
git commit -m "feat(sync): extend Groups/GroupMembers tables with profile fields, v13 migration"
```

---

## Task 2: Data Layer — DAO Updates

**Files:**
- Modify: `lib/data/daos/group_dao.dart`
- Modify: `lib/data/daos/group_member_dao.dart`

- [ ] **Step 1: Add `updateGroupName` to GroupDao**

In `lib/data/daos/group_dao.dart`, add method:

```dart
Future<void> updateGroupName(String groupId, String groupName) =>
    (update(groups)..where((table) => table.groupId.equals(groupId))).write(
      GroupsCompanion(groupName: Value(groupName)),
    );
```

- [ ] **Step 2: Add `updateMemberProfile` to GroupMemberDao**

In `lib/data/daos/group_member_dao.dart`, add method:

```dart
Future<void> updateMemberProfile({
  required String groupId,
  required String deviceId,
  required String displayName,
  required String avatarEmoji,
  String? avatarImagePath,
  String? avatarImageHash,
}) =>
    (update(groupMembers)..where(
          (table) =>
              table.groupId.equals(groupId) & table.deviceId.equals(deviceId),
        ))
        .write(GroupMembersCompanion(
          displayName: Value(displayName),
          avatarEmoji: Value(avatarEmoji),
          avatarImagePath: Value(avatarImagePath),
          avatarImageHash: Value(avatarImageHash),
        ));
```

- [ ] **Step 3: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Verify**

```bash
flutter analyze lib/data/daos/
```

- [ ] **Step 5: Commit**

```bash
git add lib/data/daos/group_dao.dart lib/data/daos/group_dao.g.dart lib/data/daos/group_member_dao.dart lib/data/daos/group_member_dao.g.dart
git commit -m "feat(sync): add updateGroupName and updateMemberProfile DAO methods"
```

---

## Task 3: Domain Layer — Model + Interface Updates

**Files:**
- Modify: `lib/features/family_sync/domain/models/group_info.dart`
- Modify: `lib/features/family_sync/domain/models/group_member.dart`
- Modify: `lib/features/family_sync/domain/repositories/group_repository.dart`

- [ ] **Step 1: Add `groupName` to GroupInfo**

In `lib/features/family_sync/domain/models/group_info.dart`, add field after `status`:

```dart
@freezed
abstract class GroupInfo with _$GroupInfo {
  const factory GroupInfo({
    required String groupId,
    required GroupStatus status,
    required String groupName,          // NEW
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String role,
    String? groupKey,
    required List<GroupMember> members,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _GroupInfo;

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
}
```

- [ ] **Step 2: Add profile fields to GroupMember**

In `lib/features/family_sync/domain/models/group_member.dart`:

```dart
@freezed
abstract class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String role,
    required String status,
    required String displayName,        // NEW
    required String avatarEmoji,        // NEW
    String? avatarImagePath,            // NEW
    String? avatarImageHash,            // NEW
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
```

- [ ] **Step 3: Add methods to GroupRepository interface**

In `lib/features/family_sync/domain/repositories/group_repository.dart`, add:

```dart
Future<void> updateGroupName(String groupId, String groupName);

Future<void> updateMemberProfile({
  required String groupId,
  required String deviceId,
  required String displayName,
  required String avatarEmoji,
  String? avatarImagePath,
  String? avatarImageHash,
});
```

Also update `savePendingGroup` and `saveConfirmingGroup` signatures to include `groupName`:

```dart
Future<void> savePendingGroup({
  required String groupId,
  required String inviteCode,
  required DateTime inviteExpiresAt,
  required String groupKey,
  required String groupName,
});

Future<void> saveConfirmingGroup({
  required String groupId,
  required String groupName,
  required List<GroupMember> members,
});
```

- [ ] **Step 4: Run code generation**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/family_sync/domain/
```

Expected: Errors in `group_repository_impl.dart` (new interface methods not yet implemented). This is expected — will be fixed in the next task.

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/domain/
git commit -m "feat(sync): add groupName to GroupInfo, profile fields to GroupMember"
```

---

## Task 4: Data Layer — Repository Implementation Update

**Files:**
- Modify: `lib/data/repositories/group_repository_impl.dart`

- [ ] **Step 1: Update `_toCompanions` to include profile fields**

Replace the `_toCompanions` method:

```dart
List<GroupMembersCompanion> _toCompanions(
  String groupId,
  List<GroupMember> members,
) {
  return members
      .map(
        (member) => GroupMembersCompanion.insert(
          groupId: groupId,
          deviceId: member.deviceId,
          publicKey: member.publicKey,
          deviceName: member.deviceName,
          role: member.role,
          status: member.status,
          displayName: Value(member.displayName),
          avatarEmoji: Value(member.avatarEmoji),
          avatarImagePath: Value(member.avatarImagePath),
          avatarImageHash: Value(member.avatarImageHash),
        ),
      )
      .toList();
}
```

- [ ] **Step 2: Update `_toGroupInfo` to map new fields**

Replace the `_toGroupInfo` method:

```dart
Future<GroupInfo> _toGroupInfo(GroupData group) async {
  final members = await _memberDao.findByGroupId(group.groupId);
  return GroupInfo(
    groupId: group.groupId,
    status: GroupStatus.values.byName(group.status),
    groupName: group.groupName,
    role: group.role,
    inviteCode: group.inviteCode,
    inviteExpiresAt: group.inviteExpiresAt != null
        ? DateTime.fromMillisecondsSinceEpoch(group.inviteExpiresAt!)
        : null,
    groupKey: group.groupKey,
    members: members
        .map(
          (member) => GroupMember(
            deviceId: member.deviceId,
            publicKey: member.publicKey,
            deviceName: member.deviceName,
            role: member.role,
            status: member.status,
            displayName: member.displayName,
            avatarEmoji: member.avatarEmoji,
            avatarImagePath: member.avatarImagePath,
            avatarImageHash: member.avatarImageHash,
          ),
        )
        .toList(),
    createdAt: DateTime.fromMillisecondsSinceEpoch(group.createdAt),
    confirmedAt: group.confirmedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(group.confirmedAt!)
        : null,
    lastSyncAt: group.lastSyncAt != null
        ? DateTime.fromMillisecondsSinceEpoch(group.lastSyncAt!)
        : null,
  );
}
```

- [ ] **Step 3: Update `savePendingGroup` to include groupName**

```dart
@override
Future<void> savePendingGroup({
  required String groupId,
  required String inviteCode,
  required DateTime inviteExpiresAt,
  required String groupKey,
  required String groupName,
}) async {
  await _groupDao.attachedDatabase.transaction(() async {
    await _groupDao.deletePendingGroups();
    await _groupDao.insert(
      GroupsCompanion.insert(
        groupId: groupId,
        status: 'pending',
        role: 'owner',
        groupName: Value(groupName),
        inviteCode: Value(inviteCode),
        inviteExpiresAt: Value(inviteExpiresAt.millisecondsSinceEpoch),
        groupKey: Value(groupKey),
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  });
}
```

- [ ] **Step 4: Update `saveConfirmingGroup` to include groupName**

```dart
@override
Future<void> saveConfirmingGroup({
  required String groupId,
  required String groupName,
  required List<GroupMember> members,
}) async {
  await _groupDao.insert(
    GroupsCompanion.insert(
      groupId: groupId,
      status: 'confirming',
      role: 'member',
      groupName: Value(groupName),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await _memberDao.insertAll(_toCompanions(groupId, members));
}
```

- [ ] **Step 5: Implement new interface methods**

```dart
@override
Future<void> updateGroupName(String groupId, String groupName) =>
    _groupDao.updateGroupName(groupId, groupName);

@override
Future<void> updateMemberProfile({
  required String groupId,
  required String deviceId,
  required String displayName,
  required String avatarEmoji,
  String? avatarImagePath,
  String? avatarImageHash,
}) =>
    _memberDao.updateMemberProfile(
      groupId: groupId,
      deviceId: deviceId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      avatarImagePath: avatarImagePath,
      avatarImageHash: avatarImageHash,
    );
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/data/repositories/group_repository_impl.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/data/repositories/group_repository_impl.dart
git commit -m "feat(sync): update GroupRepositoryImpl with profile and groupName support"
```

---

## Task 5: Infrastructure — API Client Updates

**Files:**
- Modify: `lib/infrastructure/sync/relay_api_client.dart`

- [ ] **Step 1: Update `createGroup` to accept profile fields**

Replace the existing `createGroup` method:

```dart
Future<Map<String, dynamic>> createGroup({
  String? groupName,
  String? displayName,
  String? avatarEmoji,
  String? avatarImageHash,
}) async {
  final body = jsonEncode({
    if (groupName != null) 'groupName': groupName,
    if (displayName != null) 'displayName': displayName,
    if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
    if (avatarImageHash != null) 'avatarImageHash': avatarImageHash,
  });

  final response = await _post('/group/create', body);
  return _parseResponse(response);
}
```

- [ ] **Step 2: Update `joinGroup` to accept profile fields**

Replace:

```dart
Future<Map<String, dynamic>> joinGroup({
  required String inviteCode,
  String? displayName,
  String? avatarEmoji,
  String? avatarImageHash,
}) async {
  final response = await _post(
    '/group/join',
    jsonEncode({
      'inviteCode': inviteCode,
      if (displayName != null) 'displayName': displayName,
      if (avatarEmoji != null) 'avatarEmoji': avatarEmoji,
      if (avatarImageHash != null) 'avatarImageHash': avatarImageHash,
    }),
  );
  return _parseResponse(response);
}
```

- [ ] **Step 3: Add `confirmJoin` endpoint**

Add after `joinGroup`:

```dart
/// Joiner confirms join after previewing group info.
Future<Map<String, dynamic>> confirmJoin({
  required String groupId,
  required String deviceId,
}) async {
  final response = await _post(
    '/group/$groupId/confirm-join',
    jsonEncode({'deviceId': deviceId, 'confirmed': true}),
  );
  return _parseResponse(response);
}
```

- [ ] **Step 4: Add `renameGroup` endpoint**

Add after `confirmJoin`:

```dart
/// Owner renames group. Only owner-authenticated requests succeed.
Future<Map<String, dynamic>> renameGroup({
  required String groupId,
  required String groupName,
}) async {
  final response = await _put(
    '/group/$groupId/name',
    jsonEncode({'groupName': groupName}),
  );
  return _parseResponse(response);
}
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/infrastructure/sync/relay_api_client.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/infrastructure/sync/relay_api_client.dart
git commit -m "feat(sync): add confirmJoin, renameGroup API endpoints; profile fields on create/join"
```

---

## Task 6: i18n — Add Group Profile Strings

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

- [ ] **Step 1: Add keys to all 3 ARB files**

Add these keys (inside the existing JSON, before the closing `}`):

**app_ja.arb:**
```json
  "groupDefaultName": "{name}の家庭",
  "@groupDefaultName": { "placeholders": { "name": { "type": "String" } } },
  "groupCreate": "グループを作成",
  "groupName": "グループ名",
  "groupOwner": "オーナー",
  "groupMember": "メンバー",
  "groupInviteCode": "招待コード",
  "groupInviteExpiry": "{minutes}分以内に有効",
  "@groupInviteExpiry": { "placeholders": { "minutes": { "type": "int" } } },
  "groupShareCode": "招待コードを共有",
  "groupEnterCode": "招待コードを入力",
  "groupVerify": "検証",
  "groupConfirmJoin": "参加を確認",
  "groupJoinTarget": "参加するグループ",
  "groupWaitingApproval": "オーナーの承認を待っています...",
  "groupWaitingDesc": "{name} があなたのリクエストを確認中",
  "@groupWaitingDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupJoinRequest": "参加リクエストを受信",
  "groupJoinRequestDesc": "{name} が参加を申請しています",
  "@groupJoinRequestDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupApprove": "承認",
  "groupReject": "拒否",
  "groupJoinSuccess": "ようこそ！",
  "groupRename": "グループ名を変更",
  "groupRenameFailed": "名前の変更に失敗しました",
  "groupSyncing": "同期中",
  "groupInvalidCode": "無効な招待コードです",
  "groupCodeExpired": "招待コードの有効期限が切れました",
  "groupMyName": "自分の名前",
  "groupEnterGroup": "グループへ",
  "groupChoiceTitle": "家族とつながろう",
  "groupChoiceSubtitle": "家計簿を一緒に管理しましょう",
  "groupCreateDesc": "新しい家族グループを作って、メンバーを招待しましょう",
  "groupJoinDesc": "招待コードを入力して、既存のグループに参加しましょう",
  "groupE2eeHint": "E2E暗号化でプライバシーを保護",
  "groupInviteMembers": "新しいメンバーを招待",
  "groupDisband": "グループを解散",
  "groupCancel": "キャンセル",
  "groupWaitingHint1": "通知が届くまでお待ちください",
  "groupWaitingHint2": "アプリを閉じても大丈夫です",
  "groupCodeHint": "招待コードはグループのオーナーに聞いてください",
  "groupBack": "戻る"
```

**app_en.arb:**
```json
  "groupDefaultName": "{name}'s Family",
  "@groupDefaultName": { "placeholders": { "name": { "type": "String" } } },
  "groupCreate": "Create Group",
  "groupName": "Group Name",
  "groupOwner": "Owner",
  "groupMember": "Member",
  "groupInviteCode": "Invite Code",
  "groupInviteExpiry": "Valid for {minutes} minutes",
  "@groupInviteExpiry": { "placeholders": { "minutes": { "type": "int" } } },
  "groupShareCode": "Share Invite Code",
  "groupEnterCode": "Enter Invite Code",
  "groupVerify": "Verify",
  "groupConfirmJoin": "Confirm Join",
  "groupJoinTarget": "Group to Join",
  "groupWaitingApproval": "Waiting for Owner approval...",
  "groupWaitingDesc": "{name} is reviewing your request",
  "@groupWaitingDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupJoinRequest": "Join request received",
  "groupJoinRequestDesc": "{name} wants to join",
  "@groupJoinRequestDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupApprove": "Approve",
  "groupReject": "Reject",
  "groupJoinSuccess": "Welcome!",
  "groupRename": "Rename Group",
  "groupRenameFailed": "Failed to rename",
  "groupSyncing": "Syncing",
  "groupInvalidCode": "Invalid invite code",
  "groupCodeExpired": "Invite code expired",
  "groupMyName": "My Name",
  "groupEnterGroup": "Enter Group",
  "groupChoiceTitle": "Connect with family",
  "groupChoiceSubtitle": "Manage your household budget together",
  "groupCreateDesc": "Create a new family group and invite members",
  "groupJoinDesc": "Enter an invite code to join an existing group",
  "groupE2eeHint": "Privacy protected with E2E encryption",
  "groupInviteMembers": "Invite new member",
  "groupDisband": "Disband Group",
  "groupCancel": "Cancel",
  "groupWaitingHint1": "Please wait for the notification",
  "groupWaitingHint2": "It's safe to close the app",
  "groupCodeHint": "Ask the group owner for the invite code",
  "groupBack": "Back"
```

**app_zh.arb:**
```json
  "groupDefaultName": "{name}的家",
  "@groupDefaultName": { "placeholders": { "name": { "type": "String" } } },
  "groupCreate": "创建 Group",
  "groupName": "Group 名",
  "groupOwner": "Owner",
  "groupMember": "成员",
  "groupInviteCode": "邀请码",
  "groupInviteExpiry": "{minutes}分钟内有效",
  "@groupInviteExpiry": { "placeholders": { "minutes": { "type": "int" } } },
  "groupShareCode": "分享邀请码",
  "groupEnterCode": "输入邀请码",
  "groupVerify": "验证",
  "groupConfirmJoin": "确认加入",
  "groupJoinTarget": "你要加入的 Group",
  "groupWaitingApproval": "等待 Owner 审批...",
  "groupWaitingDesc": "{name} 正在确认你的请求",
  "@groupWaitingDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupJoinRequest": "收到加入请求",
  "groupJoinRequestDesc": "{name} 申请加入",
  "@groupJoinRequestDesc": { "placeholders": { "name": { "type": "String" } } },
  "groupApprove": "批准",
  "groupReject": "拒绝",
  "groupJoinSuccess": "欢迎加入！",
  "groupRename": "修改 Group 名",
  "groupRenameFailed": "修改名称失败",
  "groupSyncing": "同步中",
  "groupInvalidCode": "邀请码无效",
  "groupCodeExpired": "邀请码已过期",
  "groupMyName": "我的名称",
  "groupEnterGroup": "进入 Group",
  "groupChoiceTitle": "与家人连接",
  "groupChoiceSubtitle": "一起管理家庭账本",
  "groupCreateDesc": "创建新的家庭群组，邀请家庭成员加入",
  "groupJoinDesc": "输入邀请码，加入已有的家庭群组",
  "groupE2eeHint": "端到端加密保护隐私",
  "groupInviteMembers": "邀请新成员",
  "groupDisband": "解散 Group",
  "groupCancel": "取消",
  "groupWaitingHint1": "请等待通知",
  "groupWaitingHint2": "关闭应用也没有关系",
  "groupCodeHint": "请向群组的 Owner 索取邀请码",
  "groupBack": "返回"
```

- [ ] **Step 2: Generate localizations**

```bash
flutter gen-l10n
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/l10n/ lib/generated/
```

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(sync): add i18n strings for group profile flow (ja/en/zh)"
```

---

## Task 7: Application — CreateGroupUseCase (Migrate + Rewrite)

**Files:**
- Create: `lib/application/family_sync/create_group_use_case.dart`
- Create: `test/unit/application/family_sync/create_group_use_case_test.dart`

- [ ] **Step 1: Write the test**

```dart
// test/unit/application/family_sync/create_group_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/create_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/models/device_key_pair.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/e2ee_service.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockKeyManager extends Mock implements KeyManager {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockE2EEService extends Mock implements E2EEService {}

void main() {
  late MockRelayApiClient mockApi;
  late MockKeyManager mockKeyManager;
  late MockGroupRepository mockRepo;
  late MockE2EEService mockE2ee;
  late CreateGroupUseCase useCase;

  setUp(() {
    mockApi = MockRelayApiClient();
    mockKeyManager = MockKeyManager();
    mockRepo = MockGroupRepository();
    mockE2ee = MockE2EEService();
    useCase = CreateGroupUseCase(
      apiClient: mockApi,
      keyManager: mockKeyManager,
      groupRepository: mockRepo,
      e2eeService: mockE2ee,
    );
  });

  group('CreateGroupUseCase', () {
    test('creates group with profile fields and saves pending group', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'dev-1');
      when(() => mockKeyManager.getPublicKey()).thenAnswer((_) async => 'pk-1');
      when(() => mockApi.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApi.createGroup(
        groupName: any(named: 'groupName'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
        avatarImageHash: any(named: 'avatarImageHash'),
      )).thenAnswer((_) async => {
        'groupId': 'g-1',
        'inviteCode': '385291',
        'expiresAt': 1700000000,
      });
      when(() => mockE2ee.generateGroupKey()).thenReturn('groupkey-base64');
      when(() => mockRepo.savePendingGroup(
        groupId: any(named: 'groupId'),
        inviteCode: any(named: 'inviteCode'),
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
        groupKey: any(named: 'groupKey'),
        groupName: any(named: 'groupName'),
      )).thenAnswer((_) async {});

      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '🐱',
        groupName: 'たけしの家庭',
      );

      expect(result, isA<CreateGroupSuccess>());
      final success = result as CreateGroupSuccess;
      expect(success.groupId, 'g-1');
      expect(success.inviteCode, '385291');
      verify(() => mockRepo.savePendingGroup(
        groupId: 'g-1',
        inviteCode: '385291',
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
        groupKey: 'groupkey-base64',
        groupName: 'たけしの家庭',
      )).called(1);
    });

    test('returns error when device key not initialized', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => null);
      when(() => mockKeyManager.getPublicKey()).thenAnswer((_) async => null);
      when(() => mockKeyManager.hasKeyPair()).thenAnswer((_) async => false);
      when(() => mockKeyManager.generateDeviceKeyPair()).thenAnswer((_) async => null);

      final result = await useCase.execute(
        displayName: 'たけし',
        avatarEmoji: '🐱',
        groupName: 'たけしの家庭',
      );

      expect(result, isA<CreateGroupError>());
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/unit/application/family_sync/create_group_use_case_test.dart
```

Expected: FAIL — `create_group_use_case.dart` not found at new path.

- [ ] **Step 3: Implement**

```dart
// lib/application/family_sync/create_group_use_case.dart
import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

sealed class CreateGroupResult {
  const CreateGroupResult();

  const factory CreateGroupResult.success({
    required String groupId,
    required String inviteCode,
    required int expiresAt,
  }) = CreateGroupSuccess;

  const factory CreateGroupResult.error(String message) = CreateGroupError;
}

class CreateGroupSuccess extends CreateGroupResult {
  const CreateGroupSuccess({
    required this.groupId,
    required this.inviteCode,
    required this.expiresAt,
  });

  final String groupId;
  final String inviteCode;
  final int expiresAt;
}

class CreateGroupError extends CreateGroupResult {
  const CreateGroupError(this.message);
  final String message;
}

class CreateGroupUseCase {
  CreateGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
    required E2EEService e2eeService,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;

  Future<CreateGroupResult> execute({
    required String displayName,
    required String avatarEmoji,
    required String groupName,
    String? avatarImageHash,
  }) async {
    try {
      final identity = await _ensureDeviceIdentity();
      if (identity == null) {
        return const CreateGroupResult.error('Device key not initialized');
      }

      await _apiClient.registerDevice(
        deviceId: identity.deviceId,
        publicKey: identity.publicKey,
        deviceName: Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      final response = await _apiClient.createGroup(
        groupName: groupName,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImageHash: avatarImageHash,
      );

      final groupId = response['groupId'] as String?;
      final inviteCode = response['inviteCode'] as String?;
      final expiresAt = response['expiresAt'] as int?;

      if (groupId == null || inviteCode == null || expiresAt == null) {
        return CreateGroupResult.error(
          'Server returned incomplete response: '
          'groupId=$groupId, inviteCode=$inviteCode, expiresAt=$expiresAt',
        );
      }

      final groupKey = _e2eeService.generateGroupKey();

      await _groupRepository.savePendingGroup(
        groupId: groupId,
        inviteCode: inviteCode,
        inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
        groupKey: groupKey,
        groupName: groupName,
      );

      return CreateGroupResult.success(
        groupId: groupId,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    } on RelayApiException catch (error) {
      return CreateGroupResult.error(error.message);
    } catch (error) {
      return CreateGroupResult.error('Failed to create group: $error');
    }
  }

  Future<DeviceKeyPair?> _ensureDeviceIdentity() async {
    final existingDeviceId = await _keyManager.getDeviceId();
    final existingPublicKey = await _keyManager.getPublicKey();

    if (existingDeviceId != null && existingPublicKey != null) {
      return DeviceKeyPair(
        publicKey: existingPublicKey,
        deviceId: existingDeviceId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    if (!await _keyManager.hasKeyPair()) {
      return _keyManager.generateDeviceKeyPair();
    }

    return null;
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/unit/application/family_sync/create_group_use_case_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/create_group_use_case.dart test/unit/application/family_sync/create_group_use_case_test.dart
git commit -m "feat(sync): migrate CreateGroupUseCase to application/ with profile fields"
```

---

## Task 8: Application — JoinGroupUseCase (Migrate + Rewrite)

**Files:**
- Create: `lib/application/family_sync/join_group_use_case.dart`
- Create: `test/unit/application/family_sync/join_group_use_case_test.dart`

- [ ] **Step 1: Write the test**

```dart
// test/unit/application/family_sync/join_group_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/join_group_use_case.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late MockRelayApiClient mockApi;
  late MockKeyManager mockKeyManager;
  late JoinGroupUseCase useCase;

  setUp(() {
    mockApi = MockRelayApiClient();
    mockKeyManager = MockKeyManager();
    useCase = JoinGroupUseCase(
      apiClient: mockApi,
      keyManager: mockKeyManager,
    );
  });

  group('JoinGroupUseCase (verify-only)', () {
    test('returns group info on valid invite code', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'dev-2');
      when(() => mockKeyManager.getPublicKey()).thenAnswer((_) async => 'pk-2');
      when(() => mockApi.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApi.joinGroup(
        inviteCode: '385291',
        displayName: 'ゆきこ',
        avatarEmoji: '🌸',
      )).thenAnswer((_) async => {
        'groupId': 'g-1',
        'status': 'confirming',
        'groupName': 'たけしの家庭',
        'owner': {
          'deviceId': 'dev-1',
          'displayName': 'たけし',
          'avatarEmoji': '🐱',
          'avatarImageHash': null,
        },
      });

      final result = await useCase.execute(
        inviteCode: '385291',
        displayName: 'ゆきこ',
        avatarEmoji: '🌸',
      );

      expect(result, isA<JoinGroupVerified>());
      final verified = result as JoinGroupVerified;
      expect(verified.groupId, 'g-1');
      expect(verified.groupName, 'たけしの家庭');
      expect(verified.ownerDisplayName, 'たけし');
      expect(verified.ownerAvatarEmoji, '🐱');
    });

    test('returns error on invalid invite code', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'dev-2');
      when(() => mockKeyManager.getPublicKey()).thenAnswer((_) async => 'pk-2');
      when(() => mockApi.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApi.joinGroup(
        inviteCode: '000000',
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
      )).thenThrow(const RelayApiException(statusCode: 404, message: 'Not found'));

      final result = await useCase.execute(
        inviteCode: '000000',
        displayName: 'ゆきこ',
        avatarEmoji: '🌸',
      );

      expect(result, isA<JoinGroupError>());
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/unit/application/family_sync/join_group_use_case_test.dart
```

- [ ] **Step 3: Implement**

The key difference from the old use case: this is **verify-only** — it does NOT save to the local DB. It returns the group info for the user to preview before confirming.

```dart
// lib/application/family_sync/join_group_use_case.dart
import 'dart:io';

import '../../infrastructure/crypto/models/device_key_pair.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class JoinGroupResult {
  const JoinGroupResult();

  const factory JoinGroupResult.verified({
    required String groupId,
    required String groupName,
    required String ownerDeviceId,
    required String ownerDisplayName,
    required String ownerAvatarEmoji,
    String? ownerAvatarImageHash,
  }) = JoinGroupVerified;

  const factory JoinGroupResult.error(String message) = JoinGroupError;
}

class JoinGroupVerified extends JoinGroupResult {
  const JoinGroupVerified({
    required this.groupId,
    required this.groupName,
    required this.ownerDeviceId,
    required this.ownerDisplayName,
    required this.ownerAvatarEmoji,
    this.ownerAvatarImageHash,
  });

  final String groupId;
  final String groupName;
  final String ownerDeviceId;
  final String ownerDisplayName;
  final String ownerAvatarEmoji;
  final String? ownerAvatarImageHash;
}

class JoinGroupError extends JoinGroupResult {
  const JoinGroupError(this.message);
  final String message;
}

class JoinGroupUseCase {
  JoinGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
  }) : _apiClient = apiClient,
       _keyManager = keyManager;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;

  /// Verify invite code and return group info for preview.
  /// Does NOT save to local DB — that happens in ConfirmJoinUseCase.
  Future<JoinGroupResult> execute({
    required String inviteCode,
    required String displayName,
    required String avatarEmoji,
    String? avatarImageHash,
  }) async {
    try {
      final identity = await _ensureDeviceIdentity();
      if (identity == null) {
        return const JoinGroupResult.error('Device key not initialized');
      }

      await _apiClient.registerDevice(
        deviceId: identity.deviceId,
        publicKey: identity.publicKey,
        deviceName: Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      final response = await _apiClient.joinGroup(
        inviteCode: inviteCode,
        displayName: displayName,
        avatarEmoji: avatarEmoji,
        avatarImageHash: avatarImageHash,
      );

      final groupId = response['groupId'] as String;
      final groupName = response['groupName'] as String? ?? '';
      final owner = response['owner'] as Map<String, dynamic>?;

      return JoinGroupResult.verified(
        groupId: groupId,
        groupName: groupName,
        ownerDeviceId: owner?['deviceId'] as String? ?? '',
        ownerDisplayName: owner?['displayName'] as String? ?? '',
        ownerAvatarEmoji: owner?['avatarEmoji'] as String? ?? '🏠',
        ownerAvatarImageHash: owner?['avatarImageHash'] as String?,
      );
    } on RelayApiException catch (error) {
      if (error.isNotFound) {
        return const JoinGroupResult.error('Invite code not found or expired');
      }
      if (error.isConflict) {
        return const JoinGroupResult.error('Already a member of this group');
      }
      return JoinGroupResult.error(error.message);
    } catch (error) {
      return JoinGroupResult.error('Failed to join group: $error');
    }
  }

  Future<DeviceKeyPair?> _ensureDeviceIdentity() async {
    final existingDeviceId = await _keyManager.getDeviceId();
    final existingPublicKey = await _keyManager.getPublicKey();

    if (existingDeviceId != null && existingPublicKey != null) {
      return DeviceKeyPair(
        publicKey: existingPublicKey,
        deviceId: existingDeviceId,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );
    }

    if (!await _keyManager.hasKeyPair()) {
      return _keyManager.generateDeviceKeyPair();
    }

    return null;
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/unit/application/family_sync/join_group_use_case_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/join_group_use_case.dart test/unit/application/family_sync/join_group_use_case_test.dart
git commit -m "feat(sync): migrate JoinGroupUseCase to verify-only with profile fields"
```

---

## Task 9: Application — ConfirmJoinUseCase (New)

**Files:**
- Create: `lib/application/family_sync/confirm_join_use_case.dart`
- Create: `test/unit/application/family_sync/confirm_join_use_case_test.dart`

- [ ] **Step 1: Write the test**

```dart
// test/unit/application/family_sync/confirm_join_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/confirm_join_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockKeyManager extends Mock implements KeyManager {}
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient mockApi;
  late MockKeyManager mockKeyManager;
  late MockGroupRepository mockRepo;
  late ConfirmJoinUseCase useCase;

  setUp(() {
    mockApi = MockRelayApiClient();
    mockKeyManager = MockKeyManager();
    mockRepo = MockGroupRepository();
    useCase = ConfirmJoinUseCase(
      apiClient: mockApi,
      keyManager: mockKeyManager,
      groupRepository: mockRepo,
    );
    registerFallbackValue(<GroupMember>[]);
  });

  group('ConfirmJoinUseCase', () {
    test('confirms join and saves confirming group locally', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'dev-2');
      when(() => mockApi.confirmJoin(
        groupId: 'g-1',
        deviceId: 'dev-2',
      )).thenAnswer((_) async => {
        'groupId': 'g-1',
        'members': [
          {
            'deviceId': 'dev-1',
            'publicKey': 'pk-1',
            'deviceName': 'iPhone',
            'role': 'owner',
            'status': 'active',
            'displayName': 'たけし',
            'avatarEmoji': '🐱',
          },
          {
            'deviceId': 'dev-2',
            'publicKey': 'pk-2',
            'deviceName': 'Pixel',
            'role': 'member',
            'status': 'pending',
            'displayName': 'ゆきこ',
            'avatarEmoji': '🌸',
          },
        ],
      });
      when(() => mockRepo.saveConfirmingGroup(
        groupId: any(named: 'groupId'),
        members: any(named: 'members'),
      )).thenAnswer((_) async {});

      final result = await useCase.execute(groupId: 'g-1', groupName: 'たけしの家庭');

      expect(result, isA<ConfirmJoinSuccess>());
      verify(() => mockRepo.saveConfirmingGroup(
        groupId: 'g-1',
        groupName: 'たけしの家庭',
        members: any(named: 'members'),
      )).called(1);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/unit/application/family_sync/confirm_join_use_case_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/application/family_sync/confirm_join_use_case.dart
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class ConfirmJoinResult {
  const ConfirmJoinResult();
  const factory ConfirmJoinResult.success() = ConfirmJoinSuccess;
  const factory ConfirmJoinResult.error(String message) = ConfirmJoinError;
}

class ConfirmJoinSuccess extends ConfirmJoinResult {
  const ConfirmJoinSuccess();
}

class ConfirmJoinError extends ConfirmJoinResult {
  const ConfirmJoinError(this.message);
  final String message;
}

class ConfirmJoinUseCase {
  ConfirmJoinUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _keyManager = keyManager,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepository;

  /// Joiner confirms join after previewing group info.
  /// Server notifies Owner via push. Saves group locally as "confirming".
  Future<ConfirmJoinResult> execute({
    required String groupId,
    required String groupName,
  }) async {
    try {
      final deviceId = await _keyManager.getDeviceId();
      if (deviceId == null) {
        return const ConfirmJoinResult.error('Device ID not available');
      }

      final response = await _apiClient.confirmJoin(
        groupId: groupId,
        deviceId: deviceId,
      );

      final members = (response['members'] as List<dynamic>)
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();

      await _groupRepository.saveConfirmingGroup(
        groupId: groupId,
        groupName: groupName,
        members: members,
      );

      return const ConfirmJoinResult.success();
    } on RelayApiException catch (error) {
      if (error.isConflict) {
        return const ConfirmJoinResult.error('Another member is already pending');
      }
      return ConfirmJoinResult.error(error.message);
    } catch (error) {
      return ConfirmJoinResult.error('Failed to confirm join: $error');
    }
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/unit/application/family_sync/confirm_join_use_case_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/confirm_join_use_case.dart test/unit/application/family_sync/confirm_join_use_case_test.dart
git commit -m "feat(sync): add ConfirmJoinUseCase for two-step join flow"
```

---

## Task 10: Application — RenameGroupUseCase (New)

**Files:**
- Create: `lib/application/family_sync/rename_group_use_case.dart`
- Create: `test/unit/application/family_sync/rename_group_use_case_test.dart`

- [ ] **Step 1: Write the test**

```dart
// test/unit/application/family_sync/rename_group_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/rename_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockRelayApiClient mockApi;
  late MockGroupRepository mockRepo;
  late RenameGroupUseCase useCase;

  setUp(() {
    mockApi = MockRelayApiClient();
    mockRepo = MockGroupRepository();
    useCase = RenameGroupUseCase(
      apiClient: mockApi,
      groupRepository: mockRepo,
    );
  });

  group('RenameGroupUseCase', () {
    test('renames group on server then updates local DB', () async {
      when(() => mockApi.renameGroup(groupId: 'g-1', groupName: '新しい名前'))
          .thenAnswer((_) async => {'groupId': 'g-1', 'groupName': '新しい名前'});
      when(() => mockRepo.updateGroupName('g-1', '新しい名前'))
          .thenAnswer((_) async {});

      final result = await useCase.execute(groupId: 'g-1', groupName: '新しい名前');

      expect(result, isA<RenameGroupSuccess>());
      verify(() => mockApi.renameGroup(groupId: 'g-1', groupName: '新しい名前')).called(1);
      verify(() => mockRepo.updateGroupName('g-1', '新しい名前')).called(1);
    });

    test('rejects empty name', () async {
      final result = await useCase.execute(groupId: 'g-1', groupName: '   ');

      expect(result, isA<RenameGroupError>());
      verifyNever(() => mockApi.renameGroup(groupId: any(named: 'groupId'), groupName: any(named: 'groupName')));
    });

    test('does not update local DB when server call fails', () async {
      when(() => mockApi.renameGroup(groupId: 'g-1', groupName: '新しい名前'))
          .thenThrow(const RelayApiException(statusCode: 403, message: 'Forbidden'));

      final result = await useCase.execute(groupId: 'g-1', groupName: '新しい名前');

      expect(result, isA<RenameGroupError>());
      verifyNever(() => mockRepo.updateGroupName(any(), any()));
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/unit/application/family_sync/rename_group_use_case_test.dart
```

- [ ] **Step 3: Implement**

```dart
// lib/application/family_sync/rename_group_use_case.dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class RenameGroupResult {
  const RenameGroupResult();
  const factory RenameGroupResult.success(String groupName) = RenameGroupSuccess;
  const factory RenameGroupResult.error(String message) = RenameGroupError;
}

class RenameGroupSuccess extends RenameGroupResult {
  const RenameGroupSuccess(this.groupName);
  final String groupName;
}

class RenameGroupError extends RenameGroupResult {
  const RenameGroupError(this.message);
  final String message;
}

class RenameGroupUseCase {
  RenameGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;

  /// Rename group: server first, then local DB (non-optimistic).
  Future<RenameGroupResult> execute({
    required String groupId,
    required String groupName,
  }) async {
    final trimmed = groupName.trim();
    if (trimmed.isEmpty) {
      return const RenameGroupResult.error('Group name cannot be empty');
    }
    if (trimmed.length > 50) {
      return const RenameGroupResult.error('Group name too long');
    }

    try {
      await _apiClient.renameGroup(groupId: groupId, groupName: trimmed);
      await _groupRepository.updateGroupName(groupId, trimmed);
      return RenameGroupResult.success(trimmed);
    } on RelayApiException catch (error) {
      return RenameGroupResult.error(error.message);
    } catch (error) {
      return RenameGroupResult.error('Failed to rename group: $error');
    }
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/unit/application/family_sync/rename_group_use_case_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/rename_group_use_case.dart test/unit/application/family_sync/rename_group_use_case_test.dart
git commit -m "feat(sync): add RenameGroupUseCase with server-first update"
```

---

## Task 11: Application — ConfirmMemberUseCase (Migrate) + SyncAvatarUseCase (New)

**Files:**
- Create: `lib/application/family_sync/confirm_member_use_case.dart`
- Create: `lib/application/family_sync/sync_avatar_use_case.dart`

- [ ] **Step 1: Migrate ConfirmMemberUseCase to application/**

Copy `lib/features/family_sync/use_cases/confirm_member_use_case.dart` to `lib/application/family_sync/confirm_member_use_case.dart`. Update imports to use relative paths from `application/`:

```dart
// lib/application/family_sync/confirm_member_use_case.dart
import 'full_sync_use_case.dart';
import 'sync_avatar_use_case.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';

sealed class ConfirmMemberResult {
  const ConfirmMemberResult();
  const factory ConfirmMemberResult.success() = ConfirmMemberSuccess;
  const factory ConfirmMemberResult.error(String message) = ConfirmMemberError;
}

class ConfirmMemberSuccess extends ConfirmMemberResult {
  const ConfirmMemberSuccess();
}

class ConfirmMemberError extends ConfirmMemberResult {
  const ConfirmMemberError(this.message);
  final String message;
}

class ConfirmMemberUseCase {
  ConfirmMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required E2EEService e2eeService,
    FullSyncUseCase? fullSync,
    SyncAvatarUseCase? syncAvatar,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _e2eeService = e2eeService,
       _fullSync = fullSync,
       _syncAvatar = syncAvatar;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final E2EEService _e2eeService;
  final FullSyncUseCase? _fullSync;
  final SyncAvatarUseCase? _syncAvatar;

  Future<ConfirmMemberResult> execute({
    required String groupId,
    required String deviceId,
  }) async {
    try {
      await _apiClient.confirmMember(groupId: groupId, deviceId: deviceId);
      await _groupRepository.activateMember(groupId, deviceId);

      final group = await _groupRepository.getGroupById(groupId);
      if (group?.groupKey != null) {
        final member = group!.members.firstWhere(
          (candidate) => candidate.deviceId == deviceId,
          orElse: () => throw StateError('Member not found locally'),
        );
        final keyExchangePayload = await _e2eeService.encryptGroupKeyForMember(
          groupKeyBase64: group.groupKey!,
          memberDeviceId: member.deviceId,
          memberPublicKey: member.publicKey,
        );

        await _apiClient.pushSync(
          groupId: groupId,
          payload: keyExchangePayload,
          vectorClock: const {},
          operationCount: 0,
        );
      }

      await _fullSync?.execute();

      // Trigger avatar sync after group activation (non-blocking)
      _syncAvatar?.pushAvatarToMembers(groupId: groupId).ignore();

      return const ConfirmMemberResult.success();
    } on RelayApiException catch (error) {
      return ConfirmMemberResult.error(error.message);
    } catch (error) {
      return ConfirmMemberResult.error('Failed to confirm member: $error');
    }
  }
}
```

- [ ] **Step 2: Implement SyncAvatarUseCase**

```dart
// lib/application/family_sync/sync_avatar_use_case.dart
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';

class SyncAvatarUseCase {
  SyncAvatarUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required UserProfileRepository profileRepository,
    required E2EEService e2eeService,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _profileRepository = profileRepository,
       _e2eeService = e2eeService;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final UserProfileRepository _profileRepository;
  final E2EEService _e2eeService;

  /// Compute SHA-256 hash of a file.
  static Future<String?> computeImageHash(String? imagePath) async {
    if (imagePath == null) return null;
    final file = File(imagePath);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Push own avatar to all group members via E2EE sync.
  Future<void> pushAvatarToMembers({required String groupId}) async {
    final profile = await _profileRepository.find();
    if (profile == null) return;

    final group = await _groupRepository.getGroupById(groupId);
    if (group == null || group.groupKey == null) return;

    final localHash = await computeImageHash(profile.avatarImagePath);

    String? imageBase64;
    if (profile.avatarImagePath != null) {
      final file = File(profile.avatarImagePath!);
      if (await file.exists()) {
        imageBase64 = base64Encode(await file.readAsBytes());
      }
    }

    final payload = jsonEncode({
      'type': 'avatarSync',
      'displayName': profile.displayName,
      'avatarEmoji': profile.avatarEmoji,
      'avatarImageHash': localHash,
      'avatarImageBase64': imageBase64,
    });

    // encryptForGroup is synchronous — no await needed
    final encrypted = _e2eeService.encryptForGroup(
      plaintext: payload,
      groupKeyBase64: group.groupKey!,
    );

    await _apiClient.pushSync(
      groupId: groupId,
      payload: encrypted,
      vectorClock: const {},
      operationCount: 0,
    );
  }

  /// Handle incoming avatar sync data from a group member.
  Future<void> handleAvatarSync({
    required String groupId,
    required String senderDeviceId,
    required Map<String, dynamic> payload,
  }) async {
    final displayName = payload['displayName'] as String? ?? '';
    final avatarEmoji = payload['avatarEmoji'] as String? ?? '🏠';
    final remoteHash = payload['avatarImageHash'] as String?;
    final imageBase64 = payload['avatarImageBase64'] as String?;

    String? localPath;
    if (imageBase64 != null && remoteHash != null) {
      // Verify hash matches
      final decoded = base64Decode(imageBase64);
      final computedHash = sha256.convert(decoded).toString();
      if (computedHash == remoteHash) {
        // Save to app-private directory using path_provider
        final appDir = await getApplicationDocumentsDirectory();
        final avatarDir = Directory('${appDir.path}/avatars');
        if (!await avatarDir.exists()) await avatarDir.create(recursive: true);
        final file = File('${avatarDir.path}/$senderDeviceId.jpg');
        await file.writeAsBytes(decoded);
        localPath = file.path;
      }
    }

    await _groupRepository.updateMemberProfile(
      groupId: groupId,
      deviceId: senderDeviceId,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      avatarImagePath: localPath,
      avatarImageHash: remoteHash,
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/application/family_sync/confirm_member_use_case.dart lib/application/family_sync/sync_avatar_use_case.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/application/family_sync/confirm_member_use_case.dart lib/application/family_sync/sync_avatar_use_case.dart
git commit -m "feat(sync): migrate ConfirmMemberUseCase with avatar sync trigger; add SyncAvatarUseCase"
```

---

## Task 12: Providers — Update Group Providers + Avatar Sync

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/group_providers.dart`
- Create: `lib/features/family_sync/presentation/providers/avatar_sync_providers.dart`

- [ ] **Step 1: Update group_providers.dart**

Replace the imports for migrated use cases and add new providers:

```dart
// lib/features/family_sync/presentation/providers/group_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/confirm_member_use_case.dart';
import '../../../../application/family_sync/create_group_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../../application/family_sync/rename_group_use_case.dart';
import '../../../../infrastructure/crypto/providers.dart';
import '../../use_cases/check_group_use_case.dart';
import '../../use_cases/deactivate_group_use_case.dart';
import '../../use_cases/leave_group_use_case.dart';
import '../../use_cases/regenerate_invite_use_case.dart';
import '../../use_cases/remove_member_use_case.dart';
import 'avatar_sync_providers.dart';
import 'repository_providers.dart';
import 'sync_providers.dart';

final createGroupUseCaseProvider = Provider<CreateGroupUseCase>((ref) {
  return CreateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
});

final joinGroupUseCaseProvider = Provider<JoinGroupUseCase>((ref) {
  return JoinGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});

final confirmJoinUseCaseProvider = Provider<ConfirmJoinUseCase>((ref) {
  return ConfirmJoinUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final confirmMemberUseCaseProvider = Provider<ConfirmMemberUseCase>((ref) {
  return ConfirmMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
    syncAvatar: ref.watch(syncAvatarUseCaseProvider),
  );
});

final renameGroupUseCaseProvider = Provider<RenameGroupUseCase>((ref) {
  return RenameGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    keyManager: ref.watch(keyManagerProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final leaveGroupUseCaseProvider = Provider<LeaveGroupUseCase>((ref) {
  return LeaveGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
});

final deactivateGroupUseCaseProvider = Provider<DeactivateGroupUseCase>((ref) {
  return DeactivateGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
});

final regenerateInviteUseCaseProvider = Provider<RegenerateInviteUseCase>((ref) {
  return RegenerateInviteUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});

final removeMemberUseCaseProvider = Provider<RemoveMemberUseCase>((ref) {
  return RemoveMemberUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
  );
});
```

- [ ] **Step 2: Create avatar_sync_providers.dart**

```dart
// lib/features/family_sync/presentation/providers/avatar_sync_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../application/family_sync/sync_avatar_use_case.dart';
import '../../../../features/profile/presentation/providers/user_profile_providers.dart';
import 'repository_providers.dart';

final syncAvatarUseCaseProvider = Provider<SyncAvatarUseCase>((ref) {
  return SyncAvatarUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    profileRepository: ref.watch(userProfileRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
});
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/providers/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/providers/group_providers.dart lib/features/family_sync/presentation/providers/avatar_sync_providers.dart
git commit -m "feat(sync): update group providers with migrated use cases and avatar sync"
```

---

## Task 13: Widget — Extend AvatarDisplay with Custom Gradients

**Files:**
- Modify: `lib/features/profile/presentation/widgets/avatar_display.dart`

- [ ] **Step 1: Add `gradientColors` parameter**

Add an optional `gradientColors` parameter to allow callers to override the default coral gradient (used for member avatars in group screens with purple/green variants):

In `avatar_display.dart`, update the constructor and build:

```dart
class AvatarDisplay extends StatelessWidget {
  const AvatarDisplay({
    super.key,
    required this.emoji,
    this.imagePath,
    this.size = 110,
    this.onTap,
    this.gradientColors,
  });

  final String emoji;
  final String? imagePath;
  final double size;
  final VoidCallback? onTap;
  /// Override default coral gradient. Provide 2-3 colors for LinearGradient.
  final List<Color>? gradientColors;

  static const _lightGradient = [
    Color(0xFFFFD4CC),
    Color(0xFFFEEAE6),
    Color(0xFFFEF5F4),
  ];
  static const _darkGradient = [
    Color(0xFF3D2020),
    Color(0xFF2D1818),
    Color(0xFF251518),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark
        ? const Color(0x26FFFFFF)
        : const Color(0x80FFFFFF);
    final colors = gradientColors ?? (isDark ? _darkGradient : _lightGradient);

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
            colors: colors,
          ),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentPrimary.withValues(alpha: 0.16),
              blurRadius: 24,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: imagePath != null
              ? Image.file(
                  File(imagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _EmojiContent(
                    emoji: emoji,
                    size: size,
                  ),
                )
              : _EmojiContent(emoji: emoji, size: size),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify existing profile tests still pass**

```bash
flutter test test/widget/features/profile/
```

- [ ] **Step 3: Verify analyze**

```bash
flutter analyze lib/features/profile/presentation/widgets/avatar_display.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/profile/presentation/widgets/avatar_display.dart
git commit -m "feat(profile): add gradientColors parameter to AvatarDisplay"
```

---

## Task 14: Widget — GroupRenameDialog + MemberListTile Update

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/group_rename_dialog.dart`
- Modify: `lib/features/family_sync/presentation/widgets/member_list_tile.dart`

- [ ] **Step 1: Implement GroupRenameDialog**

```dart
// lib/features/family_sync/presentation/widgets/group_rename_dialog.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';

class GroupRenameDialog extends StatefulWidget {
  const GroupRenameDialog({super.key, required this.currentName});

  final String currentName;

  static Future<String?> show(BuildContext context, String currentName) {
    return showDialog<String>(
      context: context,
      builder: (_) => GroupRenameDialog(currentName: currentName),
    );
  }

  @override
  State<GroupRenameDialog> createState() => _GroupRenameDialogState();
}

class _GroupRenameDialogState extends State<GroupRenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.groupRename),
      content: TextField(
        controller: _controller,
        maxLength: 50,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.groupName,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.groupCancel),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
          },
          child: Text(l10n.profileSave),
        ),
      ],
    );
  }
}
```

- [ ] **Step 2: Update MemberListTile to use AvatarDisplay**

Replace the existing `member_list_tile.dart`:

```dart
// lib/features/family_sync/presentation/widgets/member_list_tile.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';

/// Purple gradient for non-owner members (from Pencil design).
const _purpleGradient = [
  Color(0xFFE8D5F5),
  Color(0xFFF3EAF9),
  Color(0xFFFAF5FD),
];

class MemberListTile extends StatelessWidget {
  const MemberListTile({
    super.key,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    required this.roleLabel,
    this.isOwner = false,
    this.isCurrentUser = false,
    this.youSuffix = '',
    this.onRemove,
  });

  final String displayName;
  final String avatarEmoji;
  final String? avatarImagePath;
  final String roleLabel;
  final bool isOwner;
  final bool isCurrentUser;
  final String youSuffix;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final name = isCurrentUser ? '$displayName$youSuffix' : displayName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          AvatarDisplay(
            emoji: avatarEmoji,
            imagePath: avatarImagePath,
            size: 44,
            gradientColors: isOwner ? null : _purpleGradient,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  roleLabel,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 12,
                    fontWeight: isOwner ? FontWeight.w500 : FontWeight.w400,
                    color: isOwner ? AppColors.accentPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/widgets/
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/group_rename_dialog.dart lib/features/family_sync/presentation/widgets/member_list_tile.dart
git commit -m "feat(sync): add GroupRenameDialog; update MemberListTile with AvatarDisplay"
```

---

## Task 15: Screen — GroupChoiceScreen (Entry Point)

**Files:**
- Create: `lib/features/family_sync/presentation/screens/group_choice_screen.dart`
- Create: `test/widget/features/family_sync/screens/group_choice_screen_test.dart`

**Ref design:** Pencil node `MJ4Qp`

- [ ] **Step 1: Write the widget test**

```dart
// test/widget/features/family_sync/screens/group_choice_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/presentation/screens/group_choice_screen.dart';
import '../../../../helpers/test_app.dart';

void main() {
  group('GroupChoiceScreen', () {
    testWidgets('renders create and join cards', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: GroupChoiceScreen()),
      );
      await tester.pumpAndSettle();

      // Hero section
      expect(find.text('家族とつながろう'), findsOneWidget);

      // Two action cards (check for arrow icons)
      expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    });

    testWidgets('tapping create card navigates to CreateGroupScreen', (tester) async {
      await tester.pumpWidget(
        const TestApp(child: GroupChoiceScreen()),
      );
      await tester.pumpAndSettle();

      // Tap the first card (create group)
      final cards = find.byType(GestureDetector);
      expect(cards, findsWidgets);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/widget/features/family_sync/screens/group_choice_screen_test.dart
```

- [ ] **Step 3: Implement GroupChoiceScreen**

Build UI matching Pencil node `MJ4Qp`: back button + title header, hero area with 3 overlapping emoji avatars, "家族とつながろう" title, two action cards (Create / Join), E2EE hint at bottom.

```dart
// lib/features/family_sync/presentation/screens/group_choice_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'create_group_screen.dart';
import 'join_group_screen.dart';

class GroupChoiceScreen extends StatelessWidget {
  const GroupChoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(
                        children: [
                          const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.textPrimary),
                          const SizedBox(width: 4),
                          Text(l10n.groupBack, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      l10n.familySync,
                      style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    const SizedBox(width: 50, height: 20),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Hero avatars
              _HeroAvatars(),
              const SizedBox(height: 8),
              Text(l10n.groupChoiceTitle, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text(l10n.groupChoiceSubtitle, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 24),

              // Create card
              _ActionCard(
                iconColor: AppColors.accentPrimary,
                iconBgColor: AppColors.accentPrimaryLight,
                icon: LucideIcons.circlePlus,
                title: l10n.groupCreate,
                description: l10n.groupCreateDesc,
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const CreateGroupScreen())),
              ),
              const SizedBox(height: 14),

              // Join card
              _ActionCard(
                iconColor: AppColors.survival,
                iconBgColor: const Color(0xFFF5F9FC),
                icon: LucideIcons.logIn,
                title: l10n.familySyncEnterPartnerCode,
                description: l10n.groupJoinDesc,
                onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const JoinGroupScreen())),
              ),

              const Spacer(),

              // E2EE hint
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.shield, size: 14, color: const Color(0xFF8A8A8A)),
                    const SizedBox(width: 6),
                    Text(l10n.groupE2eeHint, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF8A8A8A))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroAvatars extends StatelessWidget {
  static const _avatars = [
    ('🐱', [Color(0xFFFFD4CC), Color(0xFFFEF5F4)]),
    ('🌸', [Color(0xFFE8D5F5), Color(0xFFFAF5FD)]),
    ('🐻', [Color(0xFFD4E8CC), Color(0xFFF0F8EC)]),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 56.0 * 3 - 8.0 * 2, // 3 avatars with -8 overlap
      height: 56,
      child: Stack(
        children: List.generate(_avatars.length, (i) {
          final (emoji, colors) = _avatars[i];
          return Positioned(
            left: i * 48.0, // 56 - 8 overlap
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
                border: Border.all(color: Colors.white, width: 2.5),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 26)),
            ),
          );
        }),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.iconColor,
    required this.iconBgColor,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final Color iconColor;
  final Color iconBgColor;
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDefault),
          boxShadow: const [
            BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(14)),
              alignment: Alignment.center,
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/widget/features/family_sync/screens/group_choice_screen_test.dart
```

- [ ] **Step 5: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/screens/group_choice_screen.dart
```

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/screens/group_choice_screen.dart test/widget/features/family_sync/screens/group_choice_screen_test.dart
git commit -m "feat(sync): add GroupChoiceScreen entry point with create/join cards"
```

---

## Task 16: Screen — CreateGroupScreen (Owner Step 1)

**Files:**
- Create: `lib/features/family_sync/presentation/screens/create_group_screen.dart`

**Ref design:** Pencil node `GStw3`

- [ ] **Step 1: Implement CreateGroupScreen**

Full screen: header, owner avatar+name, group name input with edit icon, invite code card (split digits, timer), share button. Auto-calls `CreateGroupUseCase` on mount. Listens for `joinRequest` push → navigates to MemberApprovalScreen.

```dart
// lib/features/family_sync/presentation/screens/create_group_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/group_providers.dart';
import '../widgets/group_rename_dialog.dart';
import '../../../../application/family_sync/create_group_use_case.dart';
import 'member_approval_screen.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  String? _groupId;
  String _inviteCode = '';
  int? _expiresAt;
  String _groupName = '';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _createGroup();
  }

  Future<void> _createGroup() async {
    final profile = await ref.read(userProfileProvider.future);
    if (profile == null || !mounted) return;

    final l10n = S.of(context);
    final defaultName = l10n.groupDefaultName(profile.displayName);
    setState(() => _groupName = defaultName);

    final result = await ref.read(createGroupUseCaseProvider).execute(
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
      groupName: defaultName,
      avatarImageHash: null, // TODO: compute hash if image exists
    );

    if (!mounted) return;

    switch (result) {
      case CreateGroupSuccess(:final groupId, :final inviteCode, :final expiresAt):
        setState(() {
          _groupId = groupId;
          _inviteCode = inviteCode;
          _expiresAt = expiresAt;
          _loading = false;
        });
      case CreateGroupError(:final message):
        setState(() {
          _error = message;
          _loading = false;
        });
    }
  }

  Future<void> _rename() async {
    final newName = await GroupRenameDialog.show(context, _groupName);
    if (newName == null || _groupId == null) return;

    final result = await ref.read(renameGroupUseCaseProvider).execute(
      groupId: _groupId!,
      groupName: newName,
    );
    if (mounted && result is RenameGroupSuccess) {
      setState(() => _groupName = result.groupName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : Column(
                      children: [
                        // Header
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Row(children: [
                                  const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.textPrimary),
                                  const SizedBox(width: 4),
                                  Text(l10n.groupBack, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
                                ]),
                              ),
                              Text(l10n.groupCreate, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(width: 50, height: 20),
                            ],
                          ),
                        ),

                        // Avatar section
                        profileAsync.when(
                          data: (profile) => Column(
                            children: [
                              AvatarDisplay(emoji: profile?.avatarEmoji ?? '🏠', imagePath: profile?.avatarImagePath, size: 90),
                              const SizedBox(height: 8),
                              Text(profile?.displayName ?? '', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                              const SizedBox(height: 2),
                              Text(l10n.groupOwner, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                          loading: () => const SizedBox(height: 120),
                          error: (_, __) => const SizedBox(height: 120),
                        ),
                        const SizedBox(height: 16),

                        // Group name
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(l10n.groupName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: _rename,
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderDefault),
                            ),
                            child: Row(
                              children: [
                                const Text('🏠', style: TextStyle(fontSize: 18)),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_groupName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary))),
                                const Icon(LucideIcons.pencil, size: 18, color: AppColors.textSecondary),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Invite code section
                        Text(l10n.groupInviteCode, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderDefault),
                            boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _inviteCode.length >= 3 ? _inviteCode.substring(0, 3) : _inviteCode,
                                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accentPrimary, letterSpacing: 4),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _inviteCode.length >= 6 ? _inviteCode.substring(3, 6) : '',
                                    style: const TextStyle(fontFamily: 'Outfit', fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.accentPrimary, letterSpacing: 4),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(LucideIcons.timer, size: 14, color: Color(0xFF8A8A8A)),
                                  const SizedBox(width: 6),
                                  Text(l10n.groupInviteExpiry(5), style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF8A8A8A))),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Share button
                        _GradientButton(
                          icon: LucideIcons.share2,
                          label: l10n.groupShareCode,
                          onTap: () => Share.share(_inviteCode),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(colors: [Color(0xFFE85A4F), Color(0xFFF08070)]),
          boxShadow: const [BoxShadow(color: Color(0x28E85A4F), blurRadius: 20, offset: Offset(0, 6))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/screens/create_group_screen.dart
```

- [ ] **Step 3: Commit**

```bash
git add lib/features/family_sync/presentation/screens/create_group_screen.dart
git commit -m "feat(sync): add CreateGroupScreen with profile, invite code, and rename"
```

---

## Task 17: Screens — JoinGroupScreen + ConfirmJoinScreen

**Files:**
- Create: `lib/features/family_sync/presentation/screens/join_group_screen.dart`
- Create: `lib/features/family_sync/presentation/screens/confirm_join_screen.dart`

**Ref design:** Pencil nodes `ehXZ7` (JoinGroup) and `cl6P6` (ConfirmJoin)

- [ ] **Step 1: Implement JoinGroupScreen**

Joiner's avatar + name at top, 6-digit PIN input, verify button. On success → navigates to ConfirmJoinScreen with group info.

```dart
// lib/features/family_sync/presentation/screens/join_group_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../profile/presentation/providers/user_profile_providers.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/group_providers.dart';
import 'confirm_join_screen.dart';

/// Purple gradient for joiner avatar (from Pencil design node ehXZ7).
const _purpleGradient = [Color(0xFFE8D5F5), Color(0xFFF3EAF9), Color(0xFFFAF5FD)];

class JoinGroupScreen extends ConsumerStatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  ConsumerState<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends ConsumerState<JoinGroupScreen> {
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes = List.generate(6, (_) => FocusNode());
  bool _verifying = false;

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    for (final f in _focusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_code.length != 6 || _verifying) return;

    final profile = await ref.read(userProfileProvider.future);
    if (profile == null || !mounted) return;

    setState(() => _verifying = true);

    final result = await ref.read(joinGroupUseCaseProvider).execute(
      inviteCode: _code,
      displayName: profile.displayName,
      avatarEmoji: profile.avatarEmoji,
    );

    if (!mounted) return;
    setState(() => _verifying = false);

    switch (result) {
      case JoinGroupVerified():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(builder: (_) => ConfirmJoinScreen(result: result)),
        );
      case JoinGroupError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Row(children: [
                        const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.textPrimary),
                        const SizedBox(width: 4),
                        Text(l10n.groupBack, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
                      ]),
                    ),
                    Text(l10n.familySyncEnterPartnerCode, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                    const SizedBox(width: 50, height: 20),
                  ],
                ),
              ),

              // Avatar
              profileAsync.when(
                data: (profile) => Column(children: [
                  AvatarDisplay(emoji: profile?.avatarEmoji ?? '🏠', imagePath: profile?.avatarImagePath, size: 90, gradientColors: _purpleGradient),
                  const SizedBox(height: 8),
                  Text(profile?.displayName ?? '', style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(l10n.groupMyName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: AppColors.textSecondary)),
                ]),
                loading: () => const SizedBox(height: 120),
                error: (_, __) => const SizedBox(height: 120),
              ),
              const SizedBox(height: 24),

              // Code label
              Align(
                alignment: Alignment.centerLeft,
                child: Text(l10n.groupInviteCode, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
              ),
              const SizedBox(height: 6),

              // 6-digit input
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 6; i++) ...[
                    if (i == 3) ...[
                      const SizedBox(width: 4),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Color(0xFF8A8A8A), shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                    ],
                    SizedBox(
                      width: 44,
                      height: 56,
                      child: TextField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(fontFamily: 'Outfit', fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: _focusNodes[i].hasFocus ? AppColors.accentPrimary : AppColors.borderDefault, width: _focusNodes[i].hasFocus ? 1.5 : 1),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.accentPrimary, width: 1.5),
                          ),
                          filled: true,
                          fillColor: AppColors.card,
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty && i < 5) _focusNodes[i + 1].requestFocus();
                          if (value.isEmpty && i > 0) _focusNodes[i - 1].requestFocus();
                        },
                      ),
                    ),
                    if (i < 5 && i != 2) const SizedBox(width: 8),
                  ],
                ],
              ),

              const Spacer(),

              // Verify button
              GestureDetector(
                onTap: _verify,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFFE85A4F), Color(0xFFF08070)]),
                    boxShadow: const [BoxShadow(color: Color(0x28E85A4F), blurRadius: 20, offset: Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_verifying) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      else const Icon(LucideIcons.search, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l10n.groupVerify, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hint
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.info, size: 14, color: Color(0xFF8A8A8A)),
                  const SizedBox(width: 6),
                  Text(l10n.groupCodeHint, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, color: Color(0xFF8A8A8A))),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement ConfirmJoinScreen**

Displays group name + owner info. Joiner confirms → calls ConfirmJoinUseCase → navigates to WaitingApprovalScreen.

```dart
// lib/features/family_sync/presentation/screens/confirm_join_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../application/family_sync/confirm_join_use_case.dart';
import '../../../../application/family_sync/join_group_use_case.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import '../providers/group_providers.dart';
import 'waiting_approval_screen.dart';

class ConfirmJoinScreen extends ConsumerStatefulWidget {
  const ConfirmJoinScreen({super.key, required this.result});

  final JoinGroupVerified result;

  @override
  ConsumerState<ConfirmJoinScreen> createState() => _ConfirmJoinScreenState();
}

class _ConfirmJoinScreenState extends ConsumerState<ConfirmJoinScreen> {
  bool _confirming = false;

  Future<void> _confirm() async {
    if (_confirming) return;
    setState(() => _confirming = true);

    final result = await ref.read(confirmJoinUseCaseProvider).execute(
      groupId: widget.result.groupId,
      groupName: widget.result.groupName,
    );

    if (!mounted) return;
    setState(() => _confirming = false);

    switch (result) {
      case ConfirmJoinSuccess():
        Navigator.pushReplacement(
          context,
          MaterialPageRoute<void>(
            builder: (_) => WaitingApprovalScreen(
              groupName: widget.result.groupName,
              ownerDisplayName: widget.result.ownerDisplayName,
            ),
          ),
        );
      case ConfirmJoinError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    final r = widget.result;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            children: [
              // Header (back only)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(LucideIcons.chevronLeft, size: 20, color: AppColors.textPrimary),
                      const SizedBox(width: 4),
                      Text(l10n.groupBack, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(l10n.groupJoinTarget, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🏠', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(r.groupName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 24),

              // Owner card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderDefault),
                  boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
                ),
                child: Column(
                  children: [
                    // Owner badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.accentPrimaryLight, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(LucideIcons.crown, size: 14, color: AppColors.accentPrimary),
                        const SizedBox(width: 4),
                        Text(l10n.groupOwner, style: const TextStyle(fontFamily: 'Outfit', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.accentPrimary)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                    AvatarDisplay(emoji: r.ownerAvatarEmoji, size: 80),
                    const SizedBox(height: 12),
                    Text(r.ownerDisplayName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
              ),

              const Spacer(),

              // Confirm button
              GestureDetector(
                onTap: _confirm,
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFFE85A4F), Color(0xFFF08070)]),
                    boxShadow: const [BoxShadow(color: Color(0x28E85A4F), blurRadius: 20, offset: Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_confirming) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      else const Icon(LucideIcons.circleCheck, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l10n.groupConfirmJoin, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.groupCancel, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, color: Color(0xFF8A8A8A))),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/screens/join_group_screen.dart lib/features/family_sync/presentation/screens/confirm_join_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/screens/join_group_screen.dart lib/features/family_sync/presentation/screens/confirm_join_screen.dart
git commit -m "feat(sync): add JoinGroupScreen (PIN input) and ConfirmJoinScreen (owner preview)"
```

---

## Task 18: Screens — WaitingApprovalScreen + JoinSuccessScreen (Rewrite/New)

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Create: `lib/features/family_sync/presentation/screens/join_success_screen.dart`

**Ref design:** Pencil nodes `sjU8l` (Waiting) and `kQpPG` (Success)

- [ ] **Step 1: Rewrite WaitingApprovalScreen**

Replace content with profile-aware waiting screen: group name, spinner, owner name in description, hint text. Listens for `memberConfirmed` event → navigates to JoinSuccessScreen.

```dart
// lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';

class WaitingApprovalScreen extends StatelessWidget {
  const WaitingApprovalScreen({
    super.key,
    required this.groupName,
    required this.ownerDisplayName,
  });

  final String groupName;
  final String ownerDisplayName;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 42),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Group name
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🏠', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(groupName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 32),

                // Spinner
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: AppColors.accentPrimary,
                    backgroundColor: AppColors.borderDefault,
                  ),
                ),
                const SizedBox(height: 24),

                // Wait text
                Text(l10n.groupWaitingApproval, textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                Text(l10n.groupWaitingDesc(ownerDisplayName), textAlign: TextAlign.center, style: const TextStyle(fontFamily: 'Outfit', fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 32),

                // Hints
                Text(l10n.groupWaitingHint1, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF8A8A8A))),
                const SizedBox(height: 4),
                Text(l10n.groupWaitingHint2, style: const TextStyle(fontFamily: 'Outfit', fontSize: 12, color: Color(0xFF8A8A8A))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement JoinSuccessScreen**

```dart
// lib/features/family_sync/presentation/screens/join_success_screen.dart
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';
import 'group_management_screen.dart';

/// Purple gradient for member avatar.
const _purpleGradient = [Color(0xFFE8D5F5), Color(0xFFF3EAF9), Color(0xFFFAF5FD)];

class JoinSuccessScreen extends StatelessWidget {
  const JoinSuccessScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.ownerDisplayName,
    required this.ownerAvatarEmoji,
    required this.myDisplayName,
    required this.myAvatarEmoji,
  });

  final String groupId;
  final String groupName;
  final String ownerDisplayName;
  final String ownerAvatarEmoji;
  final String myDisplayName;
  final String myAvatarEmoji;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 42),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text(l10n.groupJoinSuccess, style: const TextStyle(fontFamily: 'Outfit', fontSize: 26, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              Text(groupName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, color: AppColors.textSecondary)),
              const SizedBox(height: 20),

              // Overlapping avatars
              SizedBox(
                width: 72 * 2 - 16,
                height: 72,
                child: Stack(
                  children: [
                    Positioned(left: 0, child: _avatar(ownerAvatarEmoji, null)),
                    Positioned(left: 56, child: _avatar(myAvatarEmoji, _purpleGradient)),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Names
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(ownerDisplayName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                  const SizedBox(width: 24),
                  Text(myDisplayName, style: const TextStyle(fontFamily: 'Outfit', fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 40),

              // Enter button
              GestureDetector(
                onTap: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute<void>(builder: (_) => GroupManagementScreen(groupId: groupId)),
                  (_) => false,
                ),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(colors: [Color(0xFFE85A4F), Color(0xFFF08070)]),
                    boxShadow: const [BoxShadow(color: Color(0x28E85A4F), blurRadius: 20, offset: Offset(0, 6))],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.arrowRight, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(l10n.groupEnterGroup, style: const TextStyle(fontFamily: 'Outfit', fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
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

  Widget _avatar(String emoji, List<Color>? gradient) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: gradient ?? const [Color(0xFFFFD4CC), Color(0xFFFEF5F4)],
        ),
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [BoxShadow(color: AppColors.accentPrimary.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}
```

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/screens/waiting_approval_screen.dart lib/features/family_sync/presentation/screens/join_success_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart lib/features/family_sync/presentation/screens/join_success_screen.dart
git commit -m "feat(sync): rewrite WaitingApprovalScreen; add JoinSuccessScreen with overlapping avatars"
```

---

## Task 19: Screens — MemberApprovalScreen + GroupManagementScreen (Rewrite)

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/member_approval_screen.dart`
- Modify: `lib/features/family_sync/presentation/screens/group_management_screen.dart`

**Ref design:** Pencil nodes `nD1Kw` (Approval) and `zd7Sl` (Management)

- [ ] **Step 1: Rewrite MemberApprovalScreen**

Replace with profile-aware approval: bell icon, applicant card with avatar + name, approve/reject buttons.

The full screen should match Pencil node `nD1Kw`: centered content, applicant card (80px purple avatar, name, group name tag), approve (gradient) and reject (outline) buttons.

Note: This is a full rewrite. Read the existing `member_approval_screen.dart` first to understand the current Riverpod/event-listening patterns, then rewrite the build method to match the new design while preserving the event handling logic (joinRequest listener, confirmMember call).

- [ ] **Step 2: Rewrite GroupManagementScreen**

Replace with profile-aware management: header with sync badge, group name (editable), member list with AvatarDisplay + role labels, invite new member button, disband button.

Matches Pencil node `zd7Sl`: sync badge (green `#E8F5E9`), member cards using `MemberListTile` (which now has AvatarDisplay), pencil edit icon on group name.

Note: Read the existing `group_management_screen.dart` first. Preserve the data-fetching and state management patterns, but rewrite the UI layout to match the Pencil design. Use `MemberListTile` for each member, `GroupRenameDialog` for rename.

- [ ] **Step 3: Verify**

```bash
flutter analyze lib/features/family_sync/presentation/screens/member_approval_screen.dart lib/features/family_sync/presentation/screens/group_management_screen.dart
```

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/screens/member_approval_screen.dart lib/features/family_sync/presentation/screens/group_management_screen.dart
git commit -m "feat(sync): rewrite MemberApprovalScreen and GroupManagementScreen with profile UI"
```

---

## Task 20: Navigation — Update Settings Section + Cleanup Old PairingScreen

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`
- Delete: `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- Delete: `lib/features/family_sync/use_cases/create_group_use_case.dart`
- Delete: `lib/features/family_sync/use_cases/join_group_use_case.dart`
- Delete: `lib/features/family_sync/use_cases/confirm_member_use_case.dart`
- Modify: `lib/features/home/presentation/screens/home_screen.dart`

- [ ] **Step 1: Update FamilySyncSettingsSection navigation**

In `family_sync_settings_section.dart`, replace the import of `PairingScreen` with `GroupChoiceScreen`:

Change:
```dart
import '../screens/pairing_screen.dart';
```
To:
```dart
import '../screens/group_choice_screen.dart';
```

And replace all `PairingScreen()` references with `GroupChoiceScreen()`:

```dart
// In _navigate method, replace:
// builder: (_) => const PairingScreen()
// with:
// builder: (_) => const GroupChoiceScreen()
```

- [ ] **Step 2: Delete old PairingScreen**

```bash
rm lib/features/family_sync/presentation/screens/pairing_screen.dart
```

- [ ] **Step 3: Delete migrated use case files**

```bash
rm lib/features/family_sync/use_cases/create_group_use_case.dart
rm lib/features/family_sync/use_cases/join_group_use_case.dart
rm lib/features/family_sync/use_cases/confirm_member_use_case.dart
```

- [ ] **Step 4: Update home_screen.dart**

In `lib/features/home/presentation/screens/home_screen.dart`, replace the `PairingScreen` import and navigation with `GroupChoiceScreen`:

```dart
// Replace import:
// import '../../family_sync/presentation/screens/pairing_screen.dart';
import '../../family_sync/presentation/screens/group_choice_screen.dart';

// Replace navigation (line ~138):
// builder: (_) => const PairingScreen(),
// with:
// builder: (_) => const GroupChoiceScreen(),
```

- [ ] **Step 5: Update remaining imports across the codebase**

Search for any remaining references to the deleted files and fix each broken import:

```bash
grep -r "use_cases/create_group_use_case" lib/
grep -r "use_cases/join_group_use_case" lib/
grep -r "use_cases/confirm_member_use_case" lib/
grep -r "pairing_screen" lib/
```

- [ ] **Step 6: Verify**

```bash
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 7: Update existing tests that reference deleted files**

Existing tests in `test/unit/features/family_sync/use_cases/` that test the old use case paths need their imports updated to point to `application/family_sync/`:

- `test/unit/features/family_sync/use_cases/create_group_use_case_test.dart` → update import to `package:home_pocket/application/family_sync/create_group_use_case.dart` and update test expectations for new `execute()` signature (now requires `displayName`, `avatarEmoji`, `groupName` params)
- `test/unit/features/family_sync/use_cases/join_group_use_case_test.dart` → update import and test expectations (result is now `JoinGroupVerified` instead of `JoinGroupSuccess`, no longer saves to DB)
- `test/unit/features/family_sync/use_cases/confirm_member_use_case_test.dart` → update import and add `syncAvatar` parameter

Also update widget tests referencing `PairingScreen`:
- `test/widget/features/family_sync/screens/pairing_screen_test.dart` → delete or update to test `GroupChoiceScreen`

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 8: Commit**

```bash
git add -A
git commit -m "feat(sync): replace PairingScreen with GroupChoiceScreen; cleanup migrated use cases"
```

---

## Task 21: Run Full Test Suite + Analyze

**Files:** None (verification only)

- [ ] **Step 1: Run analyzer**

```bash
flutter analyze
```

Expected: No issues found.

- [ ] **Step 2: Run all tests**

```bash
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Run code generation (ensure nothing stale)**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 4: Run analyzer again after codegen**

```bash
flutter analyze
```

- [ ] **Step 5: Run tests again after codegen**

```bash
flutter test
```

Expected: All tests pass, 0 analyzer issues.

- [ ] **Step 6: Commit any codegen changes**

```bash
git add -A
git commit -m "chore: regenerate code after group profile flow implementation"
```
