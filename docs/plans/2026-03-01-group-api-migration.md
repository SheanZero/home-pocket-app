# Group API Migration — Client Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate the Flutter client from the 2-person pair API to the N-person group API, including group key E2EE.

**Architecture:** The server now uses `groups` + `group_members` tables instead of `pairs`. Sync messages fan out to all group members (N-1 recipients) with the same payload. E2EE switches from per-recipient NaCl Box to a shared group symmetric key (NaCl SecretBox), with NaCl Box used only for key exchange during member confirmation.

**Tech Stack:** Flutter/Dart, Drift (SQLCipher), Riverpod, Freezed, pinenacl (NaCl SecretBox + Box)

**Server API Reference:** See `home-pocket-server/docs/plans/2026-03-01-multi-person-groups.md`

---

## New Server API Contract

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/device/register` | None | Register device (unchanged) |
| PUT | `/api/v1/device/push-token` | Ed25519 | Update push token (unchanged) |
| POST | `/api/v1/group/create` | Ed25519 | Create group, get invite code |
| POST | `/api/v1/group/join` | Ed25519 | Join group with invite code |
| POST | `/api/v1/group/confirm` | Ed25519 | Owner confirms pending member |
| GET | `/api/v1/group/{groupId}/status` | Ed25519 | Get group status + members |
| DELETE | `/api/v1/group/{groupId}` | Ed25519 | Owner deactivates group |
| POST | `/api/v1/group/{groupId}/leave` | Ed25519 | Non-owner leaves group |
| POST | `/api/v1/group/{groupId}/remove` | Ed25519 | Owner removes a member |
| POST | `/api/v1/group/{groupId}/invite` | Ed25519 | Regenerate invite code |
| POST | `/api/v1/sync/push` | Ed25519 | Push encrypted data (`groupId`, no `targetDeviceId`) |
| GET | `/api/v1/sync/pull` | Ed25519 | Pull pending messages (unchanged) |
| POST | `/api/v1/sync/ack` | Ed25519 | ACK messages (unchanged) |

### Key API Differences from Pair System

| Aspect | Old (Pair) | New (Group) |
|--------|-----------|-------------|
| Create request | `{bookId, publicKey, deviceName}` | `{bookId}` |
| Create response | `{pairId, pairCode, qrData, expiresAt}` | `{groupId, inviteCode, expiresAt}` |
| Join request | `{pairCode, publicKey, deviceName}` | `{inviteCode}` |
| Join response | `{pairId, partnerDeviceId, partnerPublicKey, partnerDeviceName, status}` | `{groupId, bookId, members: [{deviceId, publicKey, deviceName, role, status}]}` |
| Confirm request | `{pairId, accept}` | `{groupId, deviceId}` |
| Confirm response | `{status, partnerDeviceId?, partnerPublicKey?, partnerDeviceName?}` | `{status, memberPublicKey, memberDeviceName}` |
| Sync push request | `{pairId, targetDeviceId, payload, ...}` | `{groupId, payload, ...}` |
| Sync push response | `{messageId}` | `{recipientCount}` |
| Push notifications | `pair_request`, `pair_confirmed` | `join_request`, `member_confirmed` |

### E2EE: Group Symmetric Key Protocol

**Problem:** Server fans out the SAME payload to all N-1 recipients. NaCl Box encryption is per-recipient (different shared secret per pair of keys). A payload encrypted with Box for member B cannot be decrypted by member C.

**Solution:** Use a shared group symmetric key with NaCl SecretBox.

1. **CreateGroup:** Owner generates a 32-byte random group key. Stores locally.
2. **ConfirmMember:** Owner encrypts the group key FOR the new member using NaCl Box and includes the intended `toDeviceId` in the v2 key-exchange envelope. The server still fans out the same payload to the whole group. Non-target members ACK immediately without decrypting. The target member ACKs ONLY after successfully decrypting and storing the group key.
3. **Data sync:** All members encrypt/decrypt with NaCl SecretBox using the shared group key.

**Payload format (v2):**
```json
{"v":2,"t":"D","p":"base64(nonce_24 + secretbox_ciphertext)"}                         // data sync
{"v":2,"t":"K","toDeviceId":"device-uuid","p":"base64(nonce_24 + box_ciphertext)"}  // key exchange
```

**Legacy detection (v1):** If payload does NOT start with `{`, treat as raw `base64(nonce_24 + box_ciphertext)` from the old pair system.

---

## Phase 1: Domain Layer

### Task 1: Domain Models — GroupInfo + GroupMember

**Files:**
- Create: `lib/features/family_sync/domain/models/group_info.dart`
- Create: `lib/features/family_sync/domain/models/group_member.dart`
- Keep (unchanged): `lib/features/family_sync/domain/models/sync_message.dart`
- Keep (unchanged): `lib/features/family_sync/domain/models/sync_status.dart`

**Step 1: Create GroupMember model**

```dart
// lib/features/family_sync/domain/models/group_member.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_member.freezed.dart';
part 'group_member.g.dart';

@freezed
class GroupMember with _$GroupMember {
  const factory GroupMember({
    required String deviceId,
    required String publicKey,
    required String deviceName,
    required String role,    // 'owner' | 'member'
    required String status,  // 'active' | 'pending'
  }) = _GroupMember;

  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
}
```

**Step 2: Create GroupInfo model**

```dart
// lib/features/family_sync/domain/models/group_info.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'group_member.dart';

part 'group_info.freezed.dart';
part 'group_info.g.dart';

enum GroupStatus { pending, confirming, active, inactive }

@freezed
class GroupInfo with _$GroupInfo {
  const factory GroupInfo({
    required String groupId,
    required String bookId,
    required GroupStatus status,
    String? inviteCode,
    DateTime? inviteExpiresAt,
    required String role,           // 'owner' | 'member'
    String? groupKey,               // base64-encoded 32-byte symmetric key (local only)
    required List<GroupMember> members,
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _GroupInfo;

  factory GroupInfo.fromJson(Map<String, dynamic> json) =>
      _$GroupInfoFromJson(json);
}
```

**Step 3: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 4: Verify codegen produces `.freezed.dart` and `.g.dart` files**

Run: `ls lib/features/family_sync/domain/models/group_info.freezed.dart lib/features/family_sync/domain/models/group_member.freezed.dart`

**Step 5: Commit**

```bash
git add lib/features/family_sync/domain/models/group_info.dart \
        lib/features/family_sync/domain/models/group_member.dart \
        lib/features/family_sync/domain/models/group_info.freezed.dart \
        lib/features/family_sync/domain/models/group_info.g.dart \
        lib/features/family_sync/domain/models/group_member.freezed.dart \
        lib/features/family_sync/domain/models/group_member.g.dart
git commit -m "feat: add GroupInfo and GroupMember domain models"
```

---

### Task 2: Repository Interface — GroupRepository

**Files:**
- Create: `lib/features/family_sync/domain/repositories/group_repository.dart`
- Modify: `lib/features/family_sync/domain/repositories/sync_repository.dart`

**Step 1: Create GroupRepository interface**

```dart
// lib/features/family_sync/domain/repositories/group_repository.dart
import '../models/group_info.dart';
import '../models/group_member.dart';

/// Repository for local group persistence.
///
/// State transitions:
///   Owner: pending (created, has inviteCode) → active (members confirmed)
///   Joiner: confirming (joined, has members) → active (owner confirmed us)
abstract class GroupRepository {
  /// Owner created group. Status: pending. Has inviteCode.
  Future<void> savePendingGroup({
    required String groupId,
    required String bookId,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,  // base64-encoded 32-byte key
  });

  /// Joiner joined group. Status: confirming. Has member list.
  Future<void> saveConfirmingGroup({
    required String groupId,
    required String bookId,
    required List<GroupMember> members,
  });

  /// Owner confirmed a member. Update member status in local DB.
  Future<void> activateMember(String groupId, String deviceId);

  /// Joiner: confirming → active after receiving member_confirmed push.
  Future<void> confirmLocalGroup(String groupId);

  /// Store the group key (joiner receives via key exchange sync message).
  Future<void> storeGroupKey(String groupId, String groupKeyBase64);

  /// Get the currently active group (status == 'active' ONLY).
  Future<GroupInfo?> getActiveGroup();

  /// Get a group in pending or confirming state.
  Future<GroupInfo?> getPendingGroup();

  /// Get group by ID.
  Future<GroupInfo?> getGroupById(String groupId);

  /// Update last sync time (MUST use server timestamp, not client clock).
  Future<void> updateLastSyncTime(DateTime syncTime);

  /// Update member list (from group status response).
  Future<void> updateMembers(String groupId, List<GroupMember> members);

  /// Update invite code (after regeneration).
  Future<void> updateInviteCode(String groupId, String inviteCode, DateTime expiresAt);

  /// Deactivate group (set status to inactive).
  Future<void> deactivateGroup(String groupId);
}
```

**Step 2: Update SyncRepository — replace `pairId` with `groupId`, remove `targetDeviceId`**

In `lib/features/family_sync/domain/repositories/sync_repository.dart`:

```dart
abstract class SyncRepository {
  Future<void> enqueue({
    required String id,
    required String groupId,          // was: pairId
    required String encryptedPayload,
    required String vectorClock,
    required int operationCount,
  });
  // ... rest unchanged
}

class SyncQueueEntry {
  final String id;
  final String groupId;               // was: pairId
  final String encryptedPayload;
  final String vectorClock;
  final int operationCount;
  final int retryCount;
  final DateTime createdAt;

  const SyncQueueEntry({
    required this.id,
    required this.groupId,
    required this.encryptedPayload,
    required this.vectorClock,
    required this.operationCount,
    required this.retryCount,
    required this.createdAt,
  });
}
```

Note: removed `targetDeviceId` — server does fan-out.

**Step 3: Commit**

```bash
git add lib/features/family_sync/domain/repositories/group_repository.dart \
        lib/features/family_sync/domain/repositories/sync_repository.dart
git commit -m "feat: add GroupRepository interface, update SyncRepository for groups"
```

---

## Phase 2: Data Layer

### Task 3: Drift Database Tables

**Files:**
- Create: `lib/data/tables/groups_table.dart`
- Create: `lib/data/tables/group_members_table.dart`
- Modify: `lib/data/tables/sync_queue_table.dart`
- Modify: `lib/data/app_database.dart` (add tables + migration)

**Step 1: Create groups table**

```dart
// lib/data/tables/groups_table.dart
import 'package:drift/drift.dart';

@DataClassName('GroupData')
class Groups extends Table {
  TextColumn get groupId => text()();
  TextColumn get bookId => text()();
  TextColumn get status => text()();            // 'pending'|'confirming'|'active'|'inactive'
  TextColumn get role => text()();              // 'owner'|'member'
  TextColumn get inviteCode => text().nullable()();
  IntColumn get inviteExpiresAt => integer().nullable()();
  TextColumn get groupKey => text().nullable()(); // base64 symmetric key (local E2EE)
  IntColumn get createdAt => integer()();
  IntColumn get confirmedAt => integer().nullable()();
  IntColumn get lastSyncAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {groupId};
}
```

**Step 2: Create group_members table**

```dart
// lib/data/tables/group_members_table.dart
import 'package:drift/drift.dart';

@DataClassName('GroupMemberData')
class GroupMembers extends Table {
  TextColumn get groupId => text()();
  TextColumn get deviceId => text()();
  TextColumn get publicKey => text()();
  TextColumn get deviceName => text()();
  TextColumn get role => text()();              // 'owner'|'member'
  TextColumn get status => text()();            // 'active'|'pending'

  @override
  Set<Column> get primaryKey => {groupId, deviceId};
}
```

**Step 3: Update sync_queue table — rename `pairId` → `groupId`, remove `targetDeviceId`**

In `lib/data/tables/sync_queue_table.dart`:

Replace `TextColumn get pairId => text()();` with `TextColumn get groupId => text()();`

Remove the `targetDeviceId` column entirely.

**Step 4: Update app_database.dart**

- Add `Groups` and `GroupMembers` to the `@DriftDatabase(tables: [...])` list
- Increment schema version
- Add migration step:
  - Create `groups` and `group_members` tables
  - Recreate `sync_queue` table with `groupId` column (rename from `pairId`, drop `targetDeviceId`)
  - Migrate data from `paired_devices` to `groups` if any active pairs exist

**Step 5: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 6: Verify codegen produces updated `app_database.g.dart`**

Run: `grep -c "GroupData\|GroupMemberData" lib/data/app_database.g.dart`

**Step 7: Commit**

```bash
git add lib/data/tables/groups_table.dart \
        lib/data/tables/group_members_table.dart \
        lib/data/tables/sync_queue_table.dart \
        lib/data/app_database.dart \
        lib/data/app_database.g.dart
git commit -m "feat: add groups and group_members Drift tables, update sync_queue"
```

---

### Task 4: DAOs + Repository Implementations

**Files:**
- Create: `lib/data/daos/group_dao.dart`
- Create: `lib/data/daos/group_member_dao.dart`
- Create: `lib/data/repositories/group_repository_impl.dart`
- Modify: `lib/data/daos/sync_queue_dao.dart`
- Modify: `lib/data/repositories/sync_repository_impl.dart`

**Step 1: Create GroupDao**

```dart
// lib/data/daos/group_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/groups_table.dart';

part 'group_dao.g.dart';

@DriftAccessor(tables: [Groups])
class GroupDao extends DatabaseAccessor<AppDatabase> with _$GroupDaoMixin {
  GroupDao(super.db);

  Future<void> insert(GroupsCompanion entry) => into(groups).insert(entry);

  Future<GroupData?> findByGroupId(String groupId) =>
      (select(groups)..where((t) => t.groupId.equals(groupId)))
          .getSingleOrNull();

  Future<GroupData?> findActive() =>
      (select(groups)..where((t) => t.status.equals('active')))
          .getSingleOrNull();

  Future<GroupData?> findPending() =>
      (select(groups)..where((t) => t.status.isIn(['pending', 'confirming'])))
          .getSingleOrNull();

  Future<void> updateStatus(String groupId, String status) =>
      (update(groups)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsCompanion(status: Value(status)));

  Future<void> updateGroupKey(String groupId, String groupKey) =>
      (update(groups)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsCompanion(groupKey: Value(groupKey)));

  Future<void> updateConfirmedAt(String groupId, int confirmedAt) =>
      (update(groups)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsCompanion(
            status: const Value('active'),
            confirmedAt: Value(confirmedAt),
          ));

  Future<void> updateLastSyncAt(String groupId, int lastSyncAt) =>
      (update(groups)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsCompanion(lastSyncAt: Value(lastSyncAt)));

  Future<void> updateInvite(String groupId, String code, int expiresAt) =>
      (update(groups)..where((t) => t.groupId.equals(groupId)))
          .write(GroupsCompanion(
            inviteCode: Value(code),
            inviteExpiresAt: Value(expiresAt),
          ));
}
```

**Step 2: Create GroupMemberDao**

```dart
// lib/data/daos/group_member_dao.dart
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/group_members_table.dart';

part 'group_member_dao.g.dart';

@DriftAccessor(tables: [GroupMembers])
class GroupMemberDao extends DatabaseAccessor<AppDatabase>
    with _$GroupMemberDaoMixin {
  GroupMemberDao(super.db);

  Future<void> insertAll(List<GroupMembersCompanion> entries) async {
    await batch((b) => b.insertAll(groupMembers, entries));
  }

  Future<List<GroupMemberData>> findByGroupId(String groupId) =>
      (select(groupMembers)..where((t) => t.groupId.equals(groupId))).get();

  Future<void> updateStatus(String groupId, String deviceId, String status) =>
      (update(groupMembers)
            ..where(
                (t) => t.groupId.equals(groupId) & t.deviceId.equals(deviceId)))
          .write(GroupMembersCompanion(status: Value(status)));

  Future<void> deleteByGroupId(String groupId) =>
      (delete(groupMembers)..where((t) => t.groupId.equals(groupId))).go();

  Future<void> replaceAll(
      String groupId, List<GroupMembersCompanion> entries) async {
    await deleteByGroupId(groupId);
    await insertAll(entries);
  }
}
```

**Step 3: Create GroupRepositoryImpl**

```dart
// lib/data/repositories/group_repository_impl.dart
import '../../features/family_sync/domain/models/group_info.dart';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../daos/group_dao.dart';
import '../daos/group_member_dao.dart';
import '../app_database.dart';
import 'package:drift/drift.dart';

class GroupRepositoryImpl implements GroupRepository {
  final GroupDao _groupDao;
  final GroupMemberDao _memberDao;

  GroupRepositoryImpl({
    required GroupDao groupDao,
    required GroupMemberDao memberDao,
  })  : _groupDao = groupDao,
        _memberDao = memberDao;

  @override
  Future<void> savePendingGroup({
    required String groupId,
    required String bookId,
    required String inviteCode,
    required DateTime inviteExpiresAt,
    required String groupKey,
  }) async {
    await _groupDao.insert(GroupsCompanion.insert(
      groupId: groupId,
      bookId: bookId,
      status: 'pending',
      role: 'owner',
      inviteCode: Value(inviteCode),
      inviteExpiresAt: Value(inviteExpiresAt.millisecondsSinceEpoch),
      groupKey: Value(groupKey),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  @override
  Future<void> saveConfirmingGroup({
    required String groupId,
    required String bookId,
    required List<GroupMember> members,
  }) async {
    await _groupDao.insert(GroupsCompanion.insert(
      groupId: groupId,
      bookId: bookId,
      status: 'confirming',
      role: 'member',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await _memberDao.insertAll(members
        .map((m) => GroupMembersCompanion.insert(
              groupId: groupId,
              deviceId: m.deviceId,
              publicKey: m.publicKey,
              deviceName: m.deviceName,
              role: m.role,
              status: m.status,
            ))
        .toList());
  }

  @override
  Future<void> activateMember(String groupId, String deviceId) =>
      _memberDao.updateStatus(groupId, deviceId, 'active');

  @override
  Future<void> confirmLocalGroup(String groupId) =>
      _groupDao.updateConfirmedAt(
          groupId, DateTime.now().millisecondsSinceEpoch);

  @override
  Future<void> storeGroupKey(String groupId, String groupKeyBase64) =>
      _groupDao.updateGroupKey(groupId, groupKeyBase64);

  @override
  Future<GroupInfo?> getActiveGroup() async {
    final group = await _groupDao.findActive();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getPendingGroup() async {
    final group = await _groupDao.findPending();
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<GroupInfo?> getGroupById(String groupId) async {
    final group = await _groupDao.findByGroupId(groupId);
    if (group == null) return null;
    return _toGroupInfo(group);
  }

  @override
  Future<void> updateLastSyncTime(DateTime syncTime) async {
    final group = await _groupDao.findActive();
    if (group == null) return;
    await _groupDao.updateLastSyncAt(
        group.groupId, syncTime.millisecondsSinceEpoch);
  }

  @override
  Future<void> updateMembers(
      String groupId, List<GroupMember> members) async {
    await _memberDao.replaceAll(
      groupId,
      members
          .map((m) => GroupMembersCompanion.insert(
                groupId: groupId,
                deviceId: m.deviceId,
                publicKey: m.publicKey,
                deviceName: m.deviceName,
                role: m.role,
                status: m.status,
              ))
          .toList(),
    );
  }

  @override
  Future<void> updateInviteCode(
      String groupId, String inviteCode, DateTime expiresAt) =>
      _groupDao.updateInvite(
          groupId, inviteCode, expiresAt.millisecondsSinceEpoch);

  @override
  Future<void> deactivateGroup(String groupId) =>
      _groupDao.updateStatus(groupId, 'inactive');

  Future<GroupInfo> _toGroupInfo(GroupData g) async {
    final members = await _memberDao.findByGroupId(g.groupId);
    return GroupInfo(
      groupId: g.groupId,
      bookId: g.bookId,
      status: GroupStatus.values.byName(g.status),
      role: g.role,
      inviteCode: g.inviteCode,
      inviteExpiresAt: g.inviteExpiresAt != null
          ? DateTime.fromMillisecondsSinceEpoch(g.inviteExpiresAt!)
          : null,
      groupKey: g.groupKey,
      members: members
          .map((m) => GroupMember(
                deviceId: m.deviceId,
                publicKey: m.publicKey,
                deviceName: m.deviceName,
                role: m.role,
                status: m.status,
              ))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(g.createdAt),
      confirmedAt: g.confirmedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(g.confirmedAt!)
          : null,
      lastSyncAt: g.lastSyncAt != null
          ? DateTime.fromMillisecondsSinceEpoch(g.lastSyncAt!)
          : null,
    );
  }
}
```

**Step 4: Update SyncQueueDao** — rename `pairId` → `groupId`, remove `targetDeviceId`

**Step 5: Update SyncRepositoryImpl** — rename `pairId` → `groupId`, remove `targetDeviceId`

**Step 6: Run codegen**

Run: `dart run build_runner build --delete-conflicting-outputs`

**Step 7: Commit**

```bash
git add lib/data/daos/group_dao.dart \
        lib/data/daos/group_member_dao.dart \
        lib/data/repositories/group_repository_impl.dart \
        lib/data/daos/sync_queue_dao.dart \
        lib/data/repositories/sync_repository_impl.dart
git commit -m "feat: add group DAOs and repository implementations"
```

---

## Phase 3: Infrastructure

### Task 5: API Client — Update Endpoints

**Files:**
- Modify: `lib/infrastructure/sync/relay_api_client.dart`

**Step 1: Add group methods without removing pair methods yet**

Keep the existing pair methods temporarily so current callers still compile. Add the new group methods alongside them in this task. Old pair methods are removed later in Task 15 after all call sites have migrated.

```dart
// ── Group endpoints ──

Future<Map<String, dynamic>> createGroup({required String bookId}) =>
    _parseResponse(await _post('/group/create', jsonEncode({'bookId': bookId})));

Future<Map<String, dynamic>> joinGroup({required String inviteCode}) =>
    _parseResponse(await _post('/group/join', jsonEncode({'inviteCode': inviteCode})));

Future<Map<String, dynamic>> confirmMember({
  required String groupId,
  required String deviceId,
}) =>
    _parseResponse(await _post('/group/confirm',
        jsonEncode({'groupId': groupId, 'deviceId': deviceId})));

Future<Map<String, dynamic>> getGroupStatus(String groupId) =>
    _parseResponse(await _get('/group/$groupId/status'));

Future<void> deactivateGroup(String groupId) async {
  final resp = await _delete('/group/$groupId');
  if (resp.statusCode >= 400) {
    throw RelayApiException(resp.statusCode, _tryParseError(resp));
  }
}

Future<void> leaveGroup(String groupId) async {
  final resp = await _post('/group/$groupId/leave', '{}');
  if (resp.statusCode >= 400) {
    throw RelayApiException(resp.statusCode, _tryParseError(resp));
  }
}

Future<Map<String, dynamic>> removeMember({
  required String groupId,
  required String deviceId,
}) =>
    _parseResponse(await _post('/group/$groupId/remove',
        jsonEncode({'deviceId': deviceId})));

Future<Map<String, dynamic>> regenerateInvite(String groupId) =>
    _parseResponse(await _post('/group/$groupId/invite', '{}'));
```

**Step 2: Add a new group-specific push method, keep old `pushSync()` temporarily**

```dart
Future<Map<String, dynamic>> pushGroupSync({
  required String groupId,
  required String payload,
  required Map<String, int> vectorClock,
  required int operationCount,
  int chunkIndex = 0,
  int totalChunks = 1,
}) =>
    _parseResponse(await _post('/sync/push', jsonEncode({
      'groupId': groupId,
      'payload': payload,
      'vectorClock': vectorClock,
      'operationCount': operationCount,
      'chunkIndex': chunkIndex,
      'totalChunks': totalChunks,
    })));
```

Note: the legacy `pushSync()` method remains in place in this task so existing pair-based callers still compile. All migrated group callers switch to `pushGroupSync()` in Task 11. The old pair-shaped `pushSync()` is removed in Task 15.

**Step 3: Verify build**

Run: `flutter analyze`

**Step 4: Commit**

```bash
git add lib/infrastructure/sync/relay_api_client.dart
git commit -m "feat: update RelayApiClient from pair to group endpoints"
```

---

### Task 6: E2EE — Add Group Key Support

**Files:**
- Modify: `lib/infrastructure/sync/e2ee_service.dart`

**Step 1: Add SecretBox import and group encryption methods**

Add to E2EEService:

```dart
import 'dart:math';
import 'package:pinenacl/api.dart' show SecretBox;

/// Generate a random 32-byte group key, returned as base64.
String generateGroupKey() {
  final random = Random.secure();
  final key = Uint8List(32);
  for (var i = 0; i < 32; i++) {
    key[i] = random.nextInt(256);
  }
  return base64Encode(key);
}

/// Encrypt plaintext with a shared group key (NaCl SecretBox).
/// Returns v2 payload: {"v":2,"t":"D","p":"base64(nonce+ciphertext)"}
String encryptForGroup({
  required String plaintext,
  required String groupKeyBase64,
}) {
  final groupKey = base64Decode(groupKeyBase64);
  final box = SecretBox(Uint8List.fromList(groupKey));
  final encrypted = box.encrypt(utf8.encode(plaintext));
  final combined = Uint8List(encrypted.nonce.length + encrypted.cipherText.length);
  combined.setAll(0, encrypted.nonce);
  combined.setAll(encrypted.nonce.length, encrypted.cipherText);
  return jsonEncode({'v': 2, 't': 'D', 'p': base64Encode(combined)});
}

/// Decrypt a v2 data payload using the group key (NaCl SecretBox).
String decryptFromGroup({
  required String encryptedPayload,
  required String groupKeyBase64,
}) {
  final json = jsonDecode(encryptedPayload) as Map<String, dynamic>;
  final raw = base64Decode(json['p'] as String);
  final nonce = raw.sublist(0, 24);
  final ciphertext = raw.sublist(24);
  final groupKey = base64Decode(groupKeyBase64);
  final box = SecretBox(Uint8List.fromList(groupKey));
  final decrypted = box.decrypt(ByteList(ciphertext), nonce: Uint8List.fromList(nonce));
  return utf8.decode(decrypted);
}

/// Encrypt the group key FOR a specific member using NaCl Box.
/// Returns v2 payload:
/// {"v":2,"t":"K","toDeviceId":"device-uuid","p":"base64(nonce+ciphertext)"}
Future<String> encryptGroupKeyForMember({
  required String groupKeyBase64,
  required String memberDeviceId,
  required String memberPublicKey,
}) async {
  final encrypted = await encrypt(
    plaintext: groupKeyBase64,
    recipientPublicKey: memberPublicKey,
  );
  return jsonEncode({
    'v': 2,
    't': 'K',
    'toDeviceId': memberDeviceId,
    'p': encrypted,
  });
}

/// Decrypt a v2 key exchange payload using NaCl Box.
/// Returns the group key as base64.
Future<String> decryptGroupKeyFromOwner({
  required String encryptedPayload,
  required String ownerPublicKey,
}) async {
  final json = jsonDecode(encryptedPayload) as Map<String, dynamic>;
  return decrypt(
    ciphertext: json['p'] as String,
    senderPublicKey: ownerPublicKey,
  );
}

/// Detect payload version and type.
/// Returns: 'v1' (legacy pair), 'v2_data', 'v2_key', or 'unknown'.
static String detectPayloadType(String payload) {
  if (payload.startsWith('{')) {
    try {
      final json = jsonDecode(payload) as Map<String, dynamic>;
      if (json['v'] == 2) {
        return json['t'] == 'K' ? 'v2_key' : 'v2_data';
      }
    } catch (_) {}
  }
  return 'v1';
}
```

**Step 2: Add `dart:convert` imports if missing (`jsonEncode`, `jsonDecode`)**

**Step 3: Verify build**

Run: `flutter analyze`

**Step 4: Write test for group key encryption round-trip**

```dart
// test/infrastructure/sync/e2ee_service_test.dart
test('group key encrypt/decrypt round-trip', () {
  final groupKey = e2eeService.generateGroupKey();
  final plaintext = '{"operations": []}';

  final encrypted = e2eeService.encryptForGroup(
    plaintext: plaintext,
    groupKeyBase64: groupKey,
  );

  final decrypted = e2eeService.decryptFromGroup(
    encryptedPayload: encrypted,
    groupKeyBase64: groupKey,
  );

  expect(decrypted, equals(plaintext));
});

test('key exchange encrypt/decrypt round-trip', () async {
  final groupKey = e2eeService.generateGroupKey();

  final encrypted = await e2eeService.encryptGroupKeyForMember(
    groupKeyBase64: groupKey,
    memberDeviceId: memberDeviceId,
    memberPublicKey: memberPublicKeyBase64,
  );

  final decrypted = await memberE2eeService.decryptGroupKeyFromOwner(
    encryptedPayload: encrypted,
    ownerPublicKey: ownerPublicKeyBase64,
  );

  expect(decrypted, equals(groupKey));
});

test('detectPayloadType identifies v2 data', () {
  final payload = '{"v":2,"t":"D","p":"base64data"}';
  expect(E2EEService.detectPayloadType(payload), 'v2_data');
});

test('detectPayloadType identifies v2 key exchange', () {
  final payload = '{"v":2,"t":"K","p":"base64data"}';
  expect(E2EEService.detectPayloadType(payload), 'v2_key');
});

test('detectPayloadType identifies v1 legacy', () {
  final payload = 'aGVsbG8gd29ybGQ=';  // raw base64
  expect(E2EEService.detectPayloadType(payload), 'v1');
});
```

**Step 5: Run tests**

Run: `flutter test test/infrastructure/sync/e2ee_service_test.dart`

**Step 6: Commit**

```bash
git add lib/infrastructure/sync/e2ee_service.dart \
        test/infrastructure/sync/e2ee_service_test.dart
git commit -m "feat: add group key encryption (SecretBox + Box key exchange)"
```

---

## Phase 4: Use Cases

### Task 7: CreateGroup Use Case

**Files:**
- Create: `lib/application/family_sync/create_group_use_case.dart`

**Step 1: Create CreateGroupUseCase**

```dart
// lib/application/family_sync/create_group_use_case.dart
import 'dart:io';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class CreateGroupResult {
  factory CreateGroupResult.success({
    required String groupId,
    required String inviteCode,
    required int expiresAt,
  }) = CreateGroupSuccess;
  factory CreateGroupResult.error(String message) = CreateGroupError;
}

class CreateGroupSuccess implements CreateGroupResult {
  final String groupId;
  final String inviteCode;
  final int expiresAt;
  CreateGroupSuccess({
    required this.groupId,
    required this.inviteCode,
    required this.expiresAt,
  });
}

class CreateGroupError implements CreateGroupResult {
  final String message;
  CreateGroupError(this.message);
}

class CreateGroupUseCase {
  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepo;
  final E2EEService _e2eeService;

  CreateGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepo,
    required E2EEService e2eeService,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _groupRepo = groupRepo,
        _e2eeService = e2eeService;

  Future<CreateGroupResult> execute(String bookId) async {
    try {
      // 1. Register device (idempotent)
      final keyPair = await _keyManager.getOrCreateKeyPair();
      await _apiClient.registerDevice(
        deviceId: keyPair.deviceId,
        publicKey: keyPair.publicKeyBase64,
        deviceName: keyPair.deviceName ?? Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 2. Create group on server
      final resp = await _apiClient.createGroup(bookId: bookId);
      final groupId = resp['groupId'] as String;
      final inviteCode = resp['inviteCode'] as String;
      final expiresAt = resp['expiresAt'] as int;

      // 3. Generate group symmetric key
      final groupKey = _e2eeService.generateGroupKey();

      // 4. Save pending group locally
      await _groupRepo.savePendingGroup(
        groupId: groupId,
        bookId: bookId,
        inviteCode: inviteCode,
        inviteExpiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
        groupKey: groupKey,
      );

      return CreateGroupResult.success(
        groupId: groupId,
        inviteCode: inviteCode,
        expiresAt: expiresAt,
      );
    } on RelayApiException catch (e) {
      return CreateGroupResult.error(e.message);
    } catch (e) {
      return CreateGroupResult.error('Failed to create group: $e');
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/application/family_sync/create_group_use_case.dart
git commit -m "feat: add CreateGroupUseCase"
```

---

### Task 8: JoinGroup Use Case

**Files:**
- Create: `lib/application/family_sync/join_group_use_case.dart`

**Step 1: Create JoinGroupUseCase**

```dart
// lib/application/family_sync/join_group_use_case.dart
import 'dart:io';
import '../../features/family_sync/domain/models/group_member.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/relay_api_client.dart';

sealed class JoinGroupResult {
  factory JoinGroupResult.success({
    required String groupId,
    required List<GroupMember> members,
  }) = JoinGroupSuccess;
  factory JoinGroupResult.error(String message) = JoinGroupError;
}

class JoinGroupSuccess implements JoinGroupResult {
  final String groupId;
  final List<GroupMember> members;
  JoinGroupSuccess({required this.groupId, required this.members});
}

class JoinGroupError implements JoinGroupResult {
  final String message;
  JoinGroupError(this.message);
}

class JoinGroupUseCase {
  final RelayApiClient _apiClient;
  final KeyManager _keyManager;
  final GroupRepository _groupRepo;

  JoinGroupUseCase({
    required RelayApiClient apiClient,
    required KeyManager keyManager,
    required GroupRepository groupRepo,
  })  : _apiClient = apiClient,
        _keyManager = keyManager,
        _groupRepo = groupRepo;

  Future<JoinGroupResult> execute(String inviteCode) async {
    try {
      // 1. Register device (idempotent)
      final keyPair = await _keyManager.getOrCreateKeyPair();
      await _apiClient.registerDevice(
        deviceId: keyPair.deviceId,
        publicKey: keyPair.publicKeyBase64,
        deviceName: keyPair.deviceName ?? Platform.localHostname,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // 2. Join group on server
      final resp = await _apiClient.joinGroup(inviteCode: inviteCode);
      final groupId = resp['groupId'] as String;
      final bookId = resp['bookId'] as String;
      final rawMembers = resp['members'] as List<dynamic>;
      final members = rawMembers
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // 3. Save as confirming group locally (NOT active yet)
      // Joiner waits for owner to confirm via push notification
      await _groupRepo.saveConfirmingGroup(
        groupId: groupId,
        bookId: bookId,
        members: members,
      );

      return JoinGroupResult.success(groupId: groupId, members: members);
    } on RelayApiException catch (e) {
      if (e.isNotFound) {
        return JoinGroupResult.error('Invite code not found or expired');
      }
      if (e.isConflict) {
        return JoinGroupResult.error('Already a member of this group');
      }
      return JoinGroupResult.error(e.message);
    } catch (e) {
      return JoinGroupResult.error('Failed to join group: $e');
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/application/family_sync/join_group_use_case.dart
git commit -m "feat: add JoinGroupUseCase"
```

---

### Task 9: ConfirmMember Use Case

**Files:**
- Create: `lib/application/family_sync/confirm_member_use_case.dart`

This is the most critical use case — it handles group key exchange.

**Step 1: Create ConfirmMemberUseCase**

```dart
// lib/application/family_sync/confirm_member_use_case.dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/e2ee_service.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import 'full_sync_use_case.dart';

sealed class ConfirmMemberResult {
  factory ConfirmMemberResult.success() = ConfirmMemberSuccess;
  factory ConfirmMemberResult.error(String message) = ConfirmMemberError;
}

class ConfirmMemberSuccess implements ConfirmMemberResult {}

class ConfirmMemberError implements ConfirmMemberResult {
  final String message;
  ConfirmMemberError(this.message);
}

class ConfirmMemberUseCase {
  final RelayApiClient _apiClient;
  final GroupRepository _groupRepo;
  final E2EEService _e2eeService;
  final FullSyncUseCase _fullSync;

  ConfirmMemberUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepo,
    required E2EEService e2eeService,
    required FullSyncUseCase fullSync,
  })  : _apiClient = apiClient,
        _groupRepo = groupRepo,
        _e2eeService = e2eeService,
        _fullSync = fullSync;

  Future<ConfirmMemberResult> execute({
    required String groupId,
    required String deviceId,
    required String bookId,
  }) async {
    try {
      // 1. Confirm member on server
      await _apiClient.confirmMember(groupId: groupId, deviceId: deviceId);

      // 2. Activate member locally
      await _groupRepo.activateMember(groupId, deviceId);

      // 3. Send group key to the new member via key exchange sync message
      final group = await _groupRepo.getGroupById(groupId);
      if (group?.groupKey != null) {
        final member = group!.members.firstWhere(
          (m) => m.deviceId == deviceId,
          orElse: () => throw StateError('Member not found locally'),
        );

        final keyExchangePayload =
            await _e2eeService.encryptGroupKeyForMember(
          groupKeyBase64: group.groupKey!,
          memberDeviceId: member.deviceId,
          memberPublicKey: member.publicKey,
        );

        // Push key exchange as a sync message
        await _apiClient.pushGroupSync(
          groupId: groupId,
          payload: keyExchangePayload,
          vectorClock: {},
          operationCount: 0,  // 0 = not a data message
        );
      }

      // 4. Trigger full sync to send existing data to all members
      await _fullSync.execute(bookId);

      return ConfirmMemberResult.success();
    } on RelayApiException catch (e) {
      return ConfirmMemberResult.error(e.message);
    } catch (e) {
      return ConfirmMemberResult.error('Failed to confirm member: $e');
    }
  }
}
```

**Step 2: Commit**

```bash
git add lib/application/family_sync/confirm_member_use_case.dart
git commit -m "feat: add ConfirmMemberUseCase with group key exchange"
```

---

### Task 10: Leave/Deactivate Group Use Cases

**Files:**
- Create: `lib/application/family_sync/leave_group_use_case.dart`
- Create: `lib/application/family_sync/deactivate_group_use_case.dart`

**Step 1: Create LeaveGroupUseCase** (for non-owner members)

```dart
// lib/application/family_sync/leave_group_use_case.dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

sealed class LeaveGroupResult {
  factory LeaveGroupResult.success() = LeaveGroupSuccess;
  factory LeaveGroupResult.error(String message) = LeaveGroupError;
}

class LeaveGroupSuccess implements LeaveGroupResult {}

class LeaveGroupError implements LeaveGroupResult {
  final String message;
  LeaveGroupError(this.message);
}

class LeaveGroupUseCase {
  final RelayApiClient _apiClient;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;

  LeaveGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
  })  : _apiClient = apiClient,
        _groupRepo = groupRepo,
        _queueManager = queueManager;

  Future<LeaveGroupResult> execute(String groupId) async {
    try {
      await _apiClient.leaveGroup(groupId);
      await _queueManager.clearQueue();
      await _groupRepo.deactivateGroup(groupId);
      return LeaveGroupResult.success();
    } on RelayApiException catch (e) {
      return LeaveGroupResult.error(e.message);
    } catch (e) {
      return LeaveGroupResult.error('Failed to leave group: $e');
    }
  }
}
```

**Step 2: Create DeactivateGroupUseCase** (for owner)

```dart
// lib/application/family_sync/deactivate_group_use_case.dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/relay_api_client.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';

sealed class DeactivateGroupResult {
  factory DeactivateGroupResult.success() = DeactivateGroupSuccess;
  factory DeactivateGroupResult.error(String message) = DeactivateGroupError;
}

class DeactivateGroupSuccess implements DeactivateGroupResult {}

class DeactivateGroupError implements DeactivateGroupResult {
  final String message;
  DeactivateGroupError(this.message);
}

class DeactivateGroupUseCase {
  final RelayApiClient _apiClient;
  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;

  DeactivateGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
  })  : _apiClient = apiClient,
        _groupRepo = groupRepo,
        _queueManager = queueManager;

  Future<DeactivateGroupResult> execute(String groupId) async {
    try {
      await _apiClient.deactivateGroup(groupId);
      await _queueManager.clearQueue();
      await _groupRepo.deactivateGroup(groupId);
      return DeactivateGroupResult.success();
    } on RelayApiException catch (e) {
      return DeactivateGroupResult.error(e.message);
    } catch (e) {
      return DeactivateGroupResult.error('Failed to deactivate group: $e');
    }
  }
}
```

**Step 3: Commit**

```bash
git add lib/application/family_sync/leave_group_use_case.dart \
        lib/application/family_sync/deactivate_group_use_case.dart
git commit -m "feat: add LeaveGroup and DeactivateGroup use cases"
```

---

### Task 11: Update Sync Use Cases

**Files:**
- Modify: `lib/application/family_sync/push_sync_use_case.dart`
- Modify: `lib/application/family_sync/pull_sync_use_case.dart`
- Modify: `lib/application/family_sync/full_sync_use_case.dart`

**Step 1: Update PushSyncUseCase**

Key changes:
- Replace `PairRepository` → `GroupRepository`
- Replace `getActivePair()` → `getActiveGroup()`
- Use `encryptForGroup()` instead of `encrypt()` with partner key
- Replace `pairId` → `groupId` in API call and queue
- Remove `targetDeviceId` — server handles fan-out
- Call the additive `pushGroupSync()` method from Task 5

```dart
// Key method change in PushSyncUseCase.execute():
final group = await _groupRepo.getActiveGroup();
if (group == null || group.groupKey == null) {
  return PushSyncResult.noPair();  // rename to noGroup() later
}

final jsonPayload = jsonEncode(operations);
final encrypted = _e2eeService.encryptForGroup(
  plaintext: jsonPayload,
  groupKeyBase64: group.groupKey!,
);

try {
  await _apiClient.pushGroupSync(
    groupId: group.groupId,
    payload: encrypted,
    vectorClock: vectorClock,
    operationCount: operations.length,
  );
  return PushSyncResult.success(operations.length);
} catch (_) {
  // Queue for offline retry
  await _queueManager.enqueue(
    id: const Uuid().v4(),
    groupId: group.groupId,
    encryptedPayload: encrypted,
    vectorClock: vectorClock,
    operationCount: operations.length,
  );
  return PushSyncResult.queued(operations.length);
}
```

**Step 2: Update PullSyncUseCase**

Key changes:
- Replace `PairRepository` → `GroupRepository`
- Handle v2 payload format (key exchange vs data sync)
- Decrypt with group key (SecretBox) instead of partner key (Box)
- Handle key exchange messages safely: only the intended recipient attempts decrypt; ACK only after successful key storage
- Inject `KeyManager` (or equivalent current-device provider) so the use case can compare `toDeviceId` with the local device ID before deciding whether to ACK

```dart
// Key method change in PullSyncUseCase.execute():
final group = await _groupRepo.getActiveGroup()
    ?? await _groupRepo.getPendingGroup();
if (group == null) return PullSyncResult.noPair();

final myDeviceId = await _keyManager.getDeviceId();
if (myDeviceId == null) {
  return PullSyncResult.error('Device ID not initialized');
}

// ... pull messages from server ...

for (final msg in messages) {
  final payload = msg['payload'] as String;
  final fromDeviceId = msg['fromDeviceId'] as String;
  final payloadType = E2EEService.detectPayloadType(payload);

  switch (payloadType) {
    case 'v2_key':
      final envelope = jsonDecode(payload) as Map<String, dynamic>;
      final targetDeviceId = envelope['toDeviceId'] as String?;

      // Invalid envelope: do not ACK; let a later pull retry.
      if (targetDeviceId == null) {
        continue;
      }

      // Non-target members can ACK immediately without decrypting.
      if (targetDeviceId != myDeviceId) {
        messageIds.add(msg['messageId'] as String);
        break;
      }

      final owner = group.members.firstWhere(
        (m) => m.deviceId == fromDeviceId && m.role == 'owner',
        orElse: () => throw StateError('Owner public key not available'),
      );

      try {
        final groupKey = await _e2eeService.decryptGroupKeyFromOwner(
          encryptedPayload: payload,
          ownerPublicKey: owner.publicKey,
        );
        await _groupRepo.storeGroupKey(group.groupId, groupKey);
        messageIds.add(msg['messageId'] as String);
      } catch (_) {
        // Intended recipient failed to store the group key.
        // Do NOT ACK; leave it pending so the next pull can retry.
      }
      break;

    case 'v2_data':
      if (group.groupKey == null) {
        // No group key yet — can't decrypt, skip for now
        continue;
      }
      final plaintext = _e2eeService.decryptFromGroup(
        encryptedPayload: payload,
        groupKeyBase64: group.groupKey!,
      );
      final ops = jsonDecode(plaintext) as List<dynamic>;
      await applyOperations(ops.cast<Map<String, dynamic>>());
      appliedCount += ops.length;
      messageIds.add(msg['messageId'] as String);
      break;

    case 'v1':
      // Legacy pair encryption — try Box decrypt with sender's key
      // Skip if no matching key found
      messageIds.add(msg['messageId'] as String);
      break;
  }
}
```

**Step 3: Update FullSyncUseCase** — no changes needed (delegates to PushSyncUseCase)

**Step 4: Update SyncQueueManager** — replace `pairId` → `groupId`, remove `targetDeviceId`, and call `pushGroupSync()`

**Step 5: Verify build**

Run: `flutter analyze`

**Step 6: Commit**

```bash
git add lib/application/family_sync/push_sync_use_case.dart \
        lib/application/family_sync/pull_sync_use_case.dart \
        lib/infrastructure/sync/sync_queue_manager.dart
git commit -m "feat: update sync use cases for group key encryption"
```

---

## Phase 5: Integration Layer

### Task 12: Push Notifications + Sync Trigger

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart`
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart`

**Step 1: Update PushNotificationService**

- Rename `onPairConfirmed` → `onMemberConfirmed`
- Update `handleMessage` to handle new push types:
  - `member_confirmed` (was `pair_confirmed`)
  - `join_request` (was `pair_request`)
  - `sync_available` (unchanged)

```dart
void registerHandlers({
  PushMessageHandler? onMemberConfirmed,   // was: onPairConfirmed
  PushMessageHandler? onSyncAvailable,
}) { ... }

Future<void> handleMessage(Map<String, dynamic> data) async {
  final type = data['type'] as String?;
  switch (type) {
    case 'member_confirmed':      // was: pair_confirmed
      await _onMemberConfirmed?.call(data);
    case 'sync_available':
      await _onSyncAvailable?.call(data);
    case 'join_request':           // was: pair_request
      // Foreground notification only (no handler needed)
      break;
  }
}
```

**Step 2: Update SyncTriggerService**

- Replace `PairRepository` → `GroupRepository`
- Rename `_handlePairConfirmed` → `_handleMemberConfirmed`
- Update handler registration names
- Replace `confirmLocalPair()` → `confirmLocalGroup()`
- Replace `getActivePair()` → `getActiveGroup()`
- Replace `getPendingPair()` → `getPendingGroup()`

```dart
class SyncTriggerService {
  final GroupRepository _groupRepo;      // was: PairRepository
  // ... rest of constructor ...

  void initialize() {
    // ...
    _pushNotificationService.registerHandlers(
      onMemberConfirmed: _handleMemberConfirmed,
      onSyncAvailable: _handleSyncAvailable,
    );
  }

  Future<void> _handleMemberConfirmed(Map<String, dynamic> data) async {
    final groupId = data['groupId'] as String?;
    if (groupId == null) return;

    final pending = await _groupRepo.getPendingGroup();
    if (pending != null && pending.groupId == groupId) {
      await _groupRepo.confirmLocalGroup(groupId);
    }

    // Pull to receive group key and initial sync data
    await _pullSync.execute();
  }
}
```

**Step 3: Commit**

```bash
git add lib/infrastructure/sync/push_notification_service.dart \
        lib/infrastructure/sync/sync_trigger_service.dart
git commit -m "feat: update push notifications and sync trigger for groups"
```

---

### Task 13: Providers

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/pair_providers.dart` → rename to `group_providers.dart`
- Modify: `lib/features/family_sync/presentation/providers/repository_providers.dart`
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart`

**Step 1: Rename `pair_providers.dart` → `group_providers.dart` and update**

```dart
// lib/features/family_sync/presentation/providers/group_providers.dart
final createGroupUseCase = Provider((ref) => CreateGroupUseCase(
  apiClient: ref.watch(relayApiClient),
  keyManager: ref.watch(keyManagerProvider),
  groupRepo: ref.watch(groupRepository),
  e2eeService: ref.watch(e2eeService),
));

final joinGroupUseCase = Provider((ref) => JoinGroupUseCase(
  apiClient: ref.watch(relayApiClient),
  keyManager: ref.watch(keyManagerProvider),
  groupRepo: ref.watch(groupRepository),
));

final confirmMemberUseCase = Provider((ref) => ConfirmMemberUseCase(
  apiClient: ref.watch(relayApiClient),
  groupRepo: ref.watch(groupRepository),
  e2eeService: ref.watch(e2eeService),
  fullSync: ref.watch(fullSyncUseCase),
));

final leaveGroupUseCase = Provider((ref) => LeaveGroupUseCase(
  apiClient: ref.watch(relayApiClient),
  groupRepo: ref.watch(groupRepository),
  queueManager: ref.watch(syncQueueManager),
));

final deactivateGroupUseCase = Provider((ref) => DeactivateGroupUseCase(
  apiClient: ref.watch(relayApiClient),
  groupRepo: ref.watch(groupRepository),
  queueManager: ref.watch(syncQueueManager),
));
```

**Step 2: Update repository_providers.dart**

- Replace `pairRepository` → `groupRepository` provider
- Wire `GroupRepositoryImpl` with `GroupDao` and `GroupMemberDao`

**Step 3: Update sync_providers.dart**

- Update `pushSyncUseCase` and `pullSyncUseCase` to use `groupRepository`
- Update `syncTriggerService` to use `groupRepository`

**Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/providers/
git commit -m "feat: update Riverpod providers for group system"
```

---

### Task 14: UI — Update Screens and Widgets

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- Modify: `lib/features/family_sync/presentation/screens/pair_management_screen.dart`
- Modify: `lib/features/family_sync/presentation/widgets/pair_code_display.dart`
- Modify: `lib/features/family_sync/presentation/widgets/pair_code_input.dart`
- Modify: `lib/features/family_sync/presentation/widgets/partner_device_tile.dart`
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`

**Step 1: Update PairingScreen**

- Replace `CreatePairUseCase` → `CreateGroupUseCase`
- Replace `JoinPairUseCase` → `JoinGroupUseCase`
- Update UI text: "Pair Code" → "Invite Code", "Pair with partner" → "Create Family Group"
- Update tab labels: "Show Code" → "Create Group", "Enter Code" → "Join Group"
- Update QR code data to use inviteCode instead of pairCode

**Step 2: Update PairManagementScreen → GroupManagementScreen**

- Replace `PairedDevice` model usage → `GroupInfo`
- Replace `partnerDeviceName` → member list display
- Replace "Unpair" button → "Leave Group" / "Deactivate Group" (role-dependent)
- Add member list view showing all group members
- Add "Regenerate Invite" button for owner
- Add "Remove Member" button for owner

**Step 3: Update PairCodeDisplay → InviteCodeDisplay**

- Replace "Pair Code" label → "Invite Code"
- Replace `pairCode` prop → `inviteCode`

**Step 4: Update PairCodeInput → InviteCodeInput**

- Replace "Pair Code" label → "Invite Code"
- Replace `onPairCodeSubmitted` → `onInviteCodeSubmitted`

**Step 5: Update PartnerDeviceTile → MemberDeviceTile**

- Accept `GroupMember` instead of `PairedDevice`
- Show role badge (Owner/Member)
- Show status (Active/Pending)

**Step 6: Update FamilySyncSettingsSection**

- Navigate to updated screens
- Update labels: "Paired with..." → "Family Group" / member count display

**Step 7: Verify build**

Run: `flutter analyze`

**Step 8: Commit**

```bash
git add lib/features/family_sync/presentation/
git commit -m "feat: update UI for group system"
```

---

## Phase 6: Cleanup

### Task 15: Remove Old Pair Code

**Files to delete:**
- `lib/application/family_sync/create_pair_use_case.dart`
- `lib/application/family_sync/join_pair_use_case.dart`
- `lib/application/family_sync/confirm_pair_use_case.dart`
- `lib/application/family_sync/unpair_use_case.dart`
- `lib/features/family_sync/domain/models/paired_device.dart` (+ `.freezed.dart`, `.g.dart`)
- `lib/features/family_sync/domain/repositories/pair_repository.dart`
- `lib/data/repositories/pair_repository_impl.dart`
- `lib/data/daos/paired_device_dao.dart` (+ `.g.dart`)
- `lib/data/tables/paired_devices_table.dart`

**Step 1: Delete all files listed above**

**Step 2: Remove `PairedDevices` table from `app_database.dart` `@DriftDatabase` annotation

**Step 3: Remove `PairedDeviceDao` from app_database.dart

**Step 4: Remove legacy pair methods from `RelayApiClient`**

- Delete `createPair`, `joinPair`, `confirmPair`, `getPairStatus`, `unpair`
- Delete the legacy pair-shaped `pushSync()`
- Rename `pushGroupSync()` back to `pushSync()` only after all call sites are already migrated

**Step 5: Verify build**

Run: `flutter analyze`
Expected: No errors related to pair code

**Step 6: Run all tests**

Run: `flutter test`

**Step 7: Commit**

```bash
git add -A
git commit -m "refactor: remove legacy pair system code"
```

---

### Task 16: Verify Full Application

**Step 1: Clean build**

Run: `flutter clean && flutter pub get && dart run build_runner build --delete-conflicting-outputs`

**Step 2: Analyze**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Run tests**

Run: `flutter test`
Expected: All pass

**Step 4: Final commit if any fixups needed**

```bash
git commit -m "chore: fix any remaining build issues"
```

---

## Summary

| Phase | Tasks | Key Changes |
|-------|-------|-------------|
| 1. Domain | 1-2 | GroupInfo, GroupMember models; GroupRepository interface |
| 2. Data | 3-4 | Drift tables, DAOs, repository implementations |
| 3. Infrastructure | 5-6 | API client endpoints; E2EE group key (SecretBox) |
| 4. Use Cases | 7-11 | Create/Join/Confirm/Leave/Deactivate + sync updates |
| 5. Integration | 12-14 | Push notifications, sync trigger, providers, UI |
| 6. Cleanup | 15-16 | Remove old pair code, verify build |

**Total:** 16 tasks, ~30 files changed, ~10 files created, ~10 files deleted.
