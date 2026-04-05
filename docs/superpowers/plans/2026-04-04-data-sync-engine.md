# Data Sync Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Unify scattered sync logic into a three-layer `SyncEngine` (Scheduler → Orchestrator → existing Use Cases), replacing `SyncTriggerService` as the single entry point for all sync operations.

**Architecture:** `SyncScheduler` (infrastructure) manages timers/debounce/lifecycle. `SyncOrchestrator` (application) sequences Use Cases into four sync modes. `SyncEngine` (application) is the facade combining both layers + emitting a reactive `SyncStatus` stream. The existing execution-layer Use Cases (`PushSyncUseCase`, `PullSyncUseCase`, `FullSyncUseCase`, `SyncAvatarUseCase`, `ApplySyncOperationsUseCase`) are preserved and extended.

**Tech Stack:** Flutter, Riverpod (codegen), Freezed, Drift (SQLCipher), existing E2EE infrastructure (NaCl box), SHA-256 (package:crypto).

**Package name:** `home_pocket` (all imports use `package:home_pocket/...`).

**Spec:** `docs/superpowers/specs/2026-04-03-data-sync-engine-design.md`

**Out of scope:**
- `UpdateTransactionUseCase` does not exist yet — add sync trigger when that use case is created
- `avatarImageHash` is NOT a field on `UserProfile` (only `avatarImagePath`) — the orchestrator computes hash from `displayName|avatarEmoji` only; avatar image hash is handled separately by `SyncAvatarUseCase`

---

## File Structure

### New Files (Create)

| # | File | Responsibility |
|---|------|---------------|
| 1 | `lib/features/family_sync/domain/models/sync_status_model.dart` | Freezed `SyncStatus` class + `SyncState` enum + `SyncMode` enum (replaces old `sync_status.dart` enum) |
| 2 | `lib/features/family_sync/domain/models/sync_trigger_event.dart` | Extract `SyncTriggerEvent` + `SyncTriggerEventType` from `sync_trigger_service.dart` for UI navigation events |
| 3 | `lib/infrastructure/sync/sync_scheduler.dart` | Debounce timer (1min), polling timer (15min), 24h threshold, anti-reentry queue |
| 4 | `lib/application/family_sync/sync_orchestrator.dart` | Orchestrates InitialSync, IncrementalSync, ProfileSync, FullPull by sequencing existing Use Cases |
| 5 | `lib/application/family_sync/sync_engine.dart` | Facade: wires SyncScheduler → SyncOrchestrator, exposes `Stream<SyncStatus>` and public API methods |
| 6 | `lib/application/family_sync/handle_member_left_use_case.dart` | Group lifecycle: cleanup on member_left push notification |
| 7 | `lib/application/family_sync/handle_group_dissolved_use_case.dart` | Group lifecycle: cleanup on group_dissolved push notification |
| 8 | `test/unit/infrastructure/sync/sync_scheduler_test.dart` | SyncScheduler unit tests |
| 9 | `test/unit/application/family_sync/sync_orchestrator_test.dart` | SyncOrchestrator unit tests |
| 10 | `test/unit/application/family_sync/sync_engine_test.dart` | SyncEngine unit tests |
| 11 | `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart` | Extended test for profile/avatar handling |
| 12 | `test/unit/application/family_sync/handle_member_left_use_case_test.dart` | HandleMemberLeftUseCase tests |
| 13 | `test/unit/application/family_sync/handle_group_dissolved_use_case_test.dart` | HandleGroupDissolvedUseCase tests |

### Modified Files

| # | File | Change |
|---|------|--------|
| M1 | `lib/data/daos/group_member_dao.dart` | Add `watchByGroupId()` Drift stream query |
| M2 | `lib/data/daos/sync_queue_dao.dart` | Add `countPending()` method |
| M3 | `lib/features/family_sync/domain/repositories/sync_repository.dart` | Add `getPendingCount()` |
| M4 | `lib/data/repositories/sync_repository_impl.dart` | Implement `getPendingCount()` |
| M5 | `lib/infrastructure/sync/sync_queue_manager.dart` | Add `getPendingCount()` delegation |
| M6 | `lib/infrastructure/sync/sync_lifecycle_observer.dart` | Add `onPaused` callback for background flush |
| M7 | `lib/application/family_sync/apply_sync_operations_use_case.dart` | Handle `profile` and `avatar` entityType operations |
| M8 | `lib/infrastructure/sync/push_notification_service.dart` | Route sync events to SyncEngine; keep UI events on own stream |
| M9 | `lib/features/family_sync/presentation/providers/sync_providers.dart` | Replace `SyncTriggerService` providers with `SyncEngine` providers; add `groupMembersProvider` |
| M10 | `lib/features/family_sync/presentation/providers/repository_providers.dart` | Add `syncQueueManagerPendingCountProvider` if needed |
| M11 | `lib/application/accounting/create_transaction_use_case.dart` | Replace `SyncTriggerService` with `SyncEngine.onTransactionChanged()` |
| M12 | `lib/application/accounting/delete_transaction_use_case.dart` | Replace `SyncTriggerService` with `SyncEngine.onTransactionChanged()` |
| M13 | `lib/main.dart` | Replace `syncTriggerService.initialize()` with `syncEngine.initialize()` |
| M14 | `lib/features/family_sync/presentation/widgets/sync_status_badge.dart` | Migrate to new `SyncState` enum from `SyncStatus` Freezed model |
| M15 | `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart` | Add manual sync button, use new SyncStatus |
| M16 | `lib/features/family_sync/presentation/screens/group_management_screen.dart` | Add sync status + manual sync button |
| M17 | `lib/l10n/app_ja.arb` | Add 9 new sync i18n keys |
| M18 | `lib/l10n/app_en.arb` | Add 9 new sync i18n keys |
| M19 | `lib/l10n/app_zh.arb` | Add 9 new sync i18n keys |

### Deleted Files

| # | File | Reason |
|---|------|--------|
| D1 | `lib/infrastructure/sync/sync_trigger_service.dart` | Replaced by SyncEngine; SyncTriggerEvent extracted to domain model |

---

## Task 1: SyncState + SyncMode + Freezed SyncStatus Model

**Files:**
- Create: `lib/features/family_sync/domain/models/sync_status_model.dart`
- Test: `test/unit/features/family_sync/domain/models/sync_status_model_test.dart`

**Context:** The existing `sync_status.dart` has a plain enum (`unpaired, pairing, synced, syncing, syncError, offline`). The spec requires a richer Freezed model with `SyncState` enum, `lastSyncAt`, `pendingQueueCount`, and `errorMessage`. We also need a `SyncMode` enum for the scheduler. The old `sync_status.dart` file stays until Task 14 (UI migration) to avoid breaking consumers mid-plan.

- [ ] **Step 1: Write the failing test**

Create `test/unit/features/family_sync/domain/models/sync_status_model_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';

void main() {
  group('SyncState', () {
    test('has all required values', () {
      expect(SyncState.values, containsAll([
        SyncState.noGroup,
        SyncState.idle,
        SyncState.initialSyncing,
        SyncState.syncing,
        SyncState.synced,
        SyncState.error,
        SyncState.queuedOffline,
      ]));
    });
  });

  group('SyncMode', () {
    test('has correct priority ordering', () {
      expect(SyncMode.initialSync.priority, lessThan(SyncMode.fullPull.priority));
      expect(SyncMode.fullPull.priority, lessThan(SyncMode.incrementalPush.priority));
      expect(SyncMode.incrementalPush.priority, equals(SyncMode.incrementalPull.priority));
      expect(SyncMode.incrementalPull.priority, lessThan(SyncMode.profileSync.priority));
    });
  });

  group('SyncStatus', () {
    test('creates with required state', () {
      const status = SyncStatus(state: SyncState.idle);
      expect(status.state, SyncState.idle);
      expect(status.lastSyncAt, isNull);
      expect(status.pendingQueueCount, isNull);
      expect(status.errorMessage, isNull);
    });

    test('copyWith preserves immutability', () {
      const original = SyncStatus(state: SyncState.idle);
      final updated = original.copyWith(state: SyncState.syncing);
      expect(original.state, SyncState.idle);
      expect(updated.state, SyncState.syncing);
    });

    test('creates with all fields', () {
      final now = DateTime.now();
      final status = SyncStatus(
        state: SyncState.queuedOffline,
        lastSyncAt: now,
        pendingQueueCount: 3,
        errorMessage: null,
      );
      expect(status.pendingQueueCount, 3);
      expect(status.lastSyncAt, now);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/features/family_sync/domain/models/sync_status_model_test.dart`
Expected: FAIL — file not found / import errors

- [ ] **Step 3: Write the implementation**

Create `lib/features/family_sync/domain/models/sync_status_model.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status_model.freezed.dart';

/// States of the sync engine.
enum SyncState {
  noGroup,
  idle,
  initialSyncing,
  syncing,
  synced,
  error,
  queuedOffline,
}

/// Sync mode determines what orchestration flow to run.
enum SyncMode {
  initialSync(0),
  fullPull(1),
  incrementalPush(2),
  incrementalPull(2),
  profileSync(3);

  const SyncMode(this.priority);
  final int priority;
}

/// Rich sync status with metadata, replacing the old plain SyncStatus enum.
@freezed
abstract class SyncStatus with _$SyncStatus {
  const factory SyncStatus({
    required SyncState state,
    DateTime? lastSyncAt,
    int? pendingQueueCount,
    String? errorMessage,
  }) = _SyncStatus;
}
```

- [ ] **Step 4: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/features/family_sync/domain/models/sync_status_model_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/features/family_sync/domain/models/sync_status_model.dart \
  lib/features/family_sync/domain/models/sync_status_model.freezed.dart \
  test/unit/features/family_sync/domain/models/sync_status_model_test.dart
git commit -m "feat(sync): add SyncState, SyncMode, and Freezed SyncStatus model"
```

---

## Task 2: Extract SyncTriggerEvent to Domain Model

**Files:**
- Create: `lib/features/family_sync/domain/models/sync_trigger_event.dart`
- Modify: `lib/infrastructure/sync/sync_trigger_service.dart` (re-export from new location)

**Context:** `SyncTriggerEvent` and `SyncTriggerEventType` currently live in `sync_trigger_service.dart`. They're needed for UI navigation (joinRequest popup) even after SyncTriggerService is deleted. Extract them to a domain model so both `PushNotificationService` and UI listeners can import without depending on the old service.

- [ ] **Step 1: Create the extracted file**

Create `lib/features/family_sync/domain/models/sync_trigger_event.dart`:

```dart
/// Event types for UI navigation routing (non-sync concerns).
enum SyncTriggerEventType {
  joinRequest,
  memberConfirmed,
  memberLeft,
  groupDissolved,
  syncAvailable,
}

/// UI navigation event emitted by push notifications.
///
/// Used by [FamilySyncNotificationRouteListener] to navigate
/// to the appropriate screen when a push event arrives.
class SyncTriggerEvent {
  const SyncTriggerEvent._({required this.type, this.groupId});

  const SyncTriggerEvent.joinRequest({String? groupId})
    : this._(type: SyncTriggerEventType.joinRequest, groupId: groupId);

  const SyncTriggerEvent.memberConfirmed({String? groupId})
    : this._(type: SyncTriggerEventType.memberConfirmed, groupId: groupId);

  const SyncTriggerEvent.memberLeft({String? groupId})
    : this._(type: SyncTriggerEventType.memberLeft, groupId: groupId);

  const SyncTriggerEvent.groupDissolved({String? groupId})
    : this._(type: SyncTriggerEventType.groupDissolved, groupId: groupId);

  const SyncTriggerEvent.syncAvailable({String? groupId})
    : this._(type: SyncTriggerEventType.syncAvailable, groupId: groupId);

  final SyncTriggerEventType type;
  final String? groupId;

  @override
  bool operator ==(Object other) {
    return other is SyncTriggerEvent &&
        other.type == type &&
        other.groupId == groupId;
  }

  @override
  int get hashCode => Object.hash(type, groupId);
}
```

- [ ] **Step 2: Update sync_trigger_service.dart to re-export**

In `lib/infrastructure/sync/sync_trigger_service.dart`, replace the inline `SyncTriggerEventType` enum and `SyncTriggerEvent` class with:

```dart
export '../../features/family_sync/domain/models/sync_trigger_event.dart';
```

Remove the inline definitions (lines 17-55 of the current file). Keep the `import` and the rest of the class unchanged. The re-export ensures all existing consumers (`family_sync_notification_route_listener.dart`, etc.) continue to work without import changes.

- [ ] **Step 3: Run analyzer to verify no breakage**

Run: `flutter analyze`
Expected: 0 issues (all existing imports via sync_trigger_service.dart still resolve)

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/domain/models/sync_trigger_event.dart \
  lib/infrastructure/sync/sync_trigger_service.dart
git commit -m "refactor(sync): extract SyncTriggerEvent to domain model"
```

---

## Task 3: Data Layer Extensions (GroupMemberDao + SyncQueue Count)

**Files:**
- Modify: `lib/data/daos/group_member_dao.dart:17` — add `watchByGroupId()`
- Modify: `lib/data/daos/sync_queue_dao.dart` — add `countPending()`
- Modify: `lib/features/family_sync/domain/repositories/sync_repository.dart` — add `getPendingCount()`
- Modify: `lib/data/repositories/sync_repository_impl.dart` — implement `getPendingCount()`
- Modify: `lib/infrastructure/sync/sync_queue_manager.dart` — add `getPendingCount()`
- Test: `test/unit/data/daos/group_member_dao_watch_test.dart`

**Context:** `SyncStatus.pendingQueueCount` needs a count from the queue. `groupMembersProvider` needs a Drift `watch` stream from `GroupMemberDao`. Neither exists today.

- [ ] **Step 1: Write test for watchByGroupId**

Create `test/unit/data/daos/group_member_dao_watch_test.dart`:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';

void main() {
  late AppDatabase db;
  late GroupMemberDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = GroupMemberDao(db);
  });

  tearDown(() => db.close());

  test('watchByGroupId emits updated list when members change', () async {
    const groupId = 'test-group';

    // Insert a group first (foreign key)
    await db.into(db.groups).insert(GroupsCompanion.insert(
      groupId: groupId,
      status: 'active',
      role: 'owner',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    final stream = dao.watchByGroupId(groupId);

    // First emission: empty
    expect(await stream.first, isEmpty);

    // Insert a member
    await dao.insertAll([
      GroupMembersCompanion.insert(
        groupId: groupId,
        deviceId: 'device-1',
        publicKey: 'pk-1',
        deviceName: 'Phone',
        role: 'owner',
        status: 'active',
        displayName: 'Test',
        avatarEmoji: '🐱',
      ),
    ]);

    // Next emission should include the member
    final members = await dao.watchByGroupId(groupId).first;
    expect(members, hasLength(1));
    expect(members.first.deviceId, 'device-1');
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/data/daos/group_member_dao_watch_test.dart`
Expected: FAIL — `watchByGroupId` not defined

- [ ] **Step 3: Add watchByGroupId to GroupMemberDao**

In `lib/data/daos/group_member_dao.dart`, add after `findByGroupId`:

```dart
  Stream<List<GroupMemberData>> watchByGroupId(String groupId) => (select(
    groupMembers,
  )..where((table) => table.groupId.equals(groupId))).watch();
```

- [ ] **Step 4: Run build_runner (DAO uses codegen)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Run test to verify it passes**

Run: `flutter test test/unit/data/daos/group_member_dao_watch_test.dart`
Expected: PASS

- [ ] **Step 6: Add countPending to SyncQueueDao**

In `lib/data/daos/sync_queue_dao.dart`, add:

```dart
  Future<int> countPending() async {
    final countExpr = _db.syncQueue.id.count();
    final query = _db.selectOnly(_db.syncQueue)..addColumns([countExpr]);
    final result = await query.getSingle();
    return result.read(countExpr) ?? 0;
  }
```

- [ ] **Step 7: Add getPendingCount to SyncRepository interface**

In `lib/features/family_sync/domain/repositories/sync_repository.dart`, add:

```dart
  /// Get the number of pending queue entries.
  Future<int> getPendingCount();
```

- [ ] **Step 8: Implement getPendingCount in SyncRepositoryImpl**

In `lib/data/repositories/sync_repository_impl.dart`, add:

```dart
  @override
  Future<int> getPendingCount() async {
    return _dao.countPending();
  }
```

- [ ] **Step 9: Add getPendingCount to SyncQueueManager**

In `lib/infrastructure/sync/sync_queue_manager.dart`, add:

```dart
  /// Get number of pending entries in the queue.
  Future<int> getPendingCount() async {
    return _syncRepository.getPendingCount();
  }
```

- [ ] **Step 10: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 11: Commit**

```bash
git add lib/data/daos/group_member_dao.dart \
  lib/data/daos/sync_queue_dao.dart \
  lib/features/family_sync/domain/repositories/sync_repository.dart \
  lib/data/repositories/sync_repository_impl.dart \
  lib/infrastructure/sync/sync_queue_manager.dart \
  test/unit/data/daos/group_member_dao_watch_test.dart
git commit -m "feat(sync): add watchByGroupId stream and pending queue count"
```

---

## Task 4: Extend ApplySyncOperationsUseCase for Profile/Avatar

**Files:**
- Modify: `lib/application/family_sync/apply_sync_operations_use_case.dart`
- Test: `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`

**Context:** Currently only handles `bill` entityType. Need to add `profile` (update GroupMember) and `avatar` (SHA-256 verify + save image + update GroupMember) handling per spec §5.3.

- [ ] **Step 1: Write tests for profile and avatar operations**

Create `test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`:

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/apply_sync_operations_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockShadowBookService extends Mock implements ShadowBookService {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockSyncAvatarUseCase extends Mock implements SyncAvatarUseCase {}

void main() {
  late ApplySyncOperationsUseCase useCase;
  late MockTransactionRepository mockTxRepo;
  late MockShadowBookService mockShadowBookService;
  late MockGroupRepository mockGroupRepo;
  late MockSyncAvatarUseCase mockAvatarUseCase;

  setUp(() {
    mockTxRepo = MockTransactionRepository();
    mockShadowBookService = MockShadowBookService();
    mockGroupRepo = MockGroupRepository();
    mockAvatarUseCase = MockSyncAvatarUseCase();

    useCase = ApplySyncOperationsUseCase(
      transactionRepository: mockTxRepo,
      shadowBookService: mockShadowBookService,
      groupRepository: mockGroupRepo,
      syncAvatarUseCase: mockAvatarUseCase,
      appDirectory: '/tmp/test',
    );
  });

  group('profile operations', () {
    test('updates GroupMember on profile entityType', () async {
      when(() => mockGroupRepo.updateMemberProfile(
        groupId: any(named: 'groupId'),
        deviceId: any(named: 'deviceId'),
        displayName: any(named: 'displayName'),
        avatarEmoji: any(named: 'avatarEmoji'),
      )).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'profile',
          'entityId': 'device-1',
          'data': {
            'displayName': 'たけし',
            'avatarEmoji': '🐱',
            'avatarImageHash': 'sha256_abc',
          },
          'fromDeviceId': 'device-1',
          'timestamp': '2026-04-03T12:00:00Z',
        },
      ], groupId: 'group-1');

      verify(() => mockGroupRepo.updateMemberProfile(
        groupId: 'group-1',
        deviceId: 'device-1',
        displayName: 'たけし',
        avatarEmoji: '🐱',
      )).called(1);
    });
  });

  group('avatar operations', () {
    test('delegates to SyncAvatarUseCase on avatar entityType', () async {
      when(() => mockAvatarUseCase.handleAvatarSync(
        groupId: any(named: 'groupId'),
        senderDeviceId: any(named: 'senderDeviceId'),
        payload: any(named: 'payload'),
        appDirectory: any(named: 'appDirectory'),
      )).thenAnswer((_) async {});

      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'avatar',
          'entityId': 'device-1',
          'data': {
            'avatarImageHash': 'sha256_abc',
            'avatarImageBase64': base64Encode([1, 2, 3]),
          },
          'fromDeviceId': 'device-1',
          'timestamp': '2026-04-03T12:00:00Z',
        },
      ], groupId: 'group-1');

      verify(() => mockAvatarUseCase.handleAvatarSync(
        groupId: 'group-1',
        senderDeviceId: 'device-1',
        payload: any(named: 'payload'),
        appDirectory: '/tmp/test',
      )).called(1);
    });
  });

  group('bill operations', () {
    test('skips unknown entityTypes gracefully', () async {
      // Should not throw
      await useCase.execute([
        {
          'op': 'update',
          'entityType': 'unknown_type',
          'entityId': 'some-id',
          'data': {},
          'fromDeviceId': 'device-1',
        },
      ], groupId: 'group-1');
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
Expected: FAIL — constructor signature mismatch (new params)

- [ ] **Step 3: Extend ApplySyncOperationsUseCase**

Modify `lib/application/family_sync/apply_sync_operations_use_case.dart`:

```dart
import '../../features/accounting/domain/models/transaction_sync_mapper.dart';
import '../../features/accounting/domain/models/book.dart';
import '../../features/accounting/domain/repositories/transaction_repository.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';

/// Applies pulled sync operations into local shadow books and group members.
class ApplySyncOperationsUseCase {
  ApplySyncOperationsUseCase({
    required TransactionRepository transactionRepository,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepository,
    SyncAvatarUseCase? syncAvatarUseCase,
    String? appDirectory,
  }) : _transactionRepository = transactionRepository,
       _shadowBookService = shadowBookService,
       _groupRepository = groupRepository,
       _syncAvatarUseCase = syncAvatarUseCase,
       _appDirectory = appDirectory;

  final TransactionRepository _transactionRepository;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepository;
  final SyncAvatarUseCase? _syncAvatarUseCase;
  final String? _appDirectory;

  Future<void> execute(
    List<Map<String, dynamic>> operations, {
    String? groupId,
  }) async {
    for (final operation in operations) {
      final entityType = operation['entityType'] as String?;

      switch (entityType) {
        case 'bill':
          await _applyBillOperation(operation);
        case 'profile':
          await _applyProfileOperation(operation, groupId: groupId);
        case 'avatar':
          await _applyAvatarOperation(operation, groupId: groupId);
        default:
          continue;
      }
    }
  }

  Future<void> _applyBillOperation(Map<String, dynamic> operation) async {
    final op = operation['op'] as String?;
    final entityId = operation['entityId'] as String?;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (op == null || entityId == null) return;

    switch (op) {
      case 'create':
      case 'insert':
        if (fromDeviceId == null || data == null) return;
        await _handleCreate(entityId, fromDeviceId, data);
      case 'delete':
        await _transactionRepository.softDelete(entityId);
      case 'update':
        if (fromDeviceId == null || data == null) return;
        await _handleUpdate(entityId, fromDeviceId, data);
    }
  }

  Future<void> _applyProfileOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (groupId == null) return;
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || data == null) return;

    await _groupRepository.updateMemberProfile(
      groupId: groupId,
      deviceId: fromDeviceId,
      displayName: data['displayName'] as String? ?? '',
      avatarEmoji: data['avatarEmoji'] as String? ?? '',
    );
  }

  Future<void> _applyAvatarOperation(
    Map<String, dynamic> operation, {
    String? groupId,
  }) async {
    if (groupId == null || _syncAvatarUseCase == null || _appDirectory == null) {
      return;
    }
    final fromDeviceId = operation['fromDeviceId'] as String?;
    final data = operation['data'] as Map<String, dynamic>?;
    if (fromDeviceId == null || data == null) return;

    await _syncAvatarUseCase.handleAvatarSync(
      groupId: groupId,
      senderDeviceId: fromDeviceId,
      payload: data,
      appDirectory: _appDirectory,
    );
  }

  // ... _handleCreate, _handleUpdate, _createShadowBookForSender unchanged ...
}
```

Keep the existing `_handleCreate`, `_handleUpdate`, and `_createShadowBookForSender` methods exactly as they are. Only change the `execute` method signature (add optional `groupId`) and add the two new `_applyProfileOperation` / `_applyAvatarOperation` methods.

- [ ] **Step 4: Update the provider to pass new dependencies**

In `lib/features/family_sync/presentation/providers/sync_providers.dart`, update the `applySyncOperationsUseCase` provider:

```dart
@riverpod
ApplySyncOperationsUseCase applySyncOperationsUseCase(Ref ref) {
  return ApplySyncOperationsUseCase(
    transactionRepository: ref.watch(accounting.transactionRepositoryProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    syncAvatarUseCase: ref.watch(syncAvatarUseCaseProvider),
    appDirectory: null, // Set at runtime via SyncEngine initialization
  );
}
```

Note: `syncAvatarUseCaseProvider` may not exist yet. If the provider already exists from the group-profile-flow branch, use it. Otherwise, create it as part of this step in `sync_providers.dart`:

```dart
@riverpod
SyncAvatarUseCase syncAvatarUseCase(Ref ref) {
  return SyncAvatarUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    userProfileRepository: ref.watch(userProfileRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
}
```

- [ ] **Step 5: Run build_runner (providers use @riverpod codegen)**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 6: Run test to verify it passes**

Run: `flutter test test/unit/application/family_sync/apply_sync_operations_use_case_test.dart`
Expected: PASS

- [ ] **Step 7: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 8: Commit**

```bash
git add lib/application/family_sync/apply_sync_operations_use_case.dart \
  lib/features/family_sync/presentation/providers/sync_providers.dart \
  lib/features/family_sync/presentation/providers/sync_providers.g.dart \
  test/unit/application/family_sync/apply_sync_operations_use_case_test.dart
git commit -m "feat(sync): extend ApplySyncOperationsUseCase for profile/avatar"
```

---

## Task 5: Enhance SyncLifecycleObserver with Paused Callback

**Files:**
- Modify: `lib/infrastructure/sync/sync_lifecycle_observer.dart`
- Test: `test/unit/infrastructure/sync/sync_lifecycle_observer_test.dart`

**Context:** The spec requires flushing the debounce timer when the app goes to background (§3.2 `onAppPaused`). The current observer only handles `resumed`. We need to add an `onPaused` callback.

- [ ] **Step 1: Write test**

Create `test/unit/infrastructure/sync/sync_lifecycle_observer_test.dart`:

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/sync/sync_lifecycle_observer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('calls onPaused when app enters background', () async {
    var pausedCalled = false;
    final observer = SyncLifecycleObserver(
      onResume: () async {},
      onPaused: () { pausedCalled = true; },
    );

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(pausedCalled, isTrue);
  });

  test('onPaused is optional for backward compatibility', () {
    // Should not throw
    final observer = SyncLifecycleObserver(onResume: () async {});
    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/infrastructure/sync/sync_lifecycle_observer_test.dart`
Expected: FAIL — no `onPaused` parameter

- [ ] **Step 3: Add onPaused callback**

Modify `lib/infrastructure/sync/sync_lifecycle_observer.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

typedef SyncResumeCallback = Future<void> Function();
typedef SyncPausedCallback = void Function();

class SyncLifecycleObserver with WidgetsBindingObserver {
  SyncLifecycleObserver({
    required SyncResumeCallback onResume,
    SyncPausedCallback? onPaused,
  }) : _onResume = onResume,
       _onPaused = onPaused;

  final SyncResumeCallback _onResume;
  final SyncPausedCallback? _onPaused;
  bool _isActive = false;

  void start() {
    if (_isActive) return;
    WidgetsBinding.instance.addObserver(this);
    _isActive = true;
  }

  void dispose() {
    if (!_isActive) return;
    WidgetsBinding.instance.removeObserver(this);
    _isActive = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onResume().catchError((Object e) {
        if (kDebugMode) {
          debugPrint('SyncLifecycleObserver: resume sync failed: $e');
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _onPaused?.call();
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/infrastructure/sync/sync_lifecycle_observer_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/infrastructure/sync/sync_lifecycle_observer.dart \
  test/unit/infrastructure/sync/sync_lifecycle_observer_test.dart
git commit -m "feat(sync): add onPaused callback to SyncLifecycleObserver"
```

---

## Task 6: SyncScheduler (Infrastructure Layer)

**Files:**
- Create: `lib/infrastructure/sync/sync_scheduler.dart`
- Test: `test/unit/infrastructure/sync/sync_scheduler_test.dart`

**Context:** The scheduling layer from spec §3. Manages debounce (1min), polling (15min), 24h threshold, and anti-reentry with priority queue. Pure platform mechanism — no business logic. Outputs sync requests via a callback.

- [ ] **Step 1: Write tests**

Create `test/unit/infrastructure/sync/sync_scheduler_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/infrastructure/sync/sync_scheduler.dart';

void main() {
  group('SyncScheduler', () {
    late SyncScheduler scheduler;
    late List<SyncMode> requestedModes;

    setUp(() {
      requestedModes = [];
      scheduler = SyncScheduler(
        onSyncRequested: (mode) async {
          requestedModes.add(mode);
        },
        checkNeedsFullPull: () async => false,
      );
    });

    tearDown(() => scheduler.dispose());

    test('onTransactionChanged debounces to 1 minute', () {
      fakeAsync((async) {
        scheduler.onTransactionChanged();
        scheduler.onTransactionChanged();
        scheduler.onTransactionChanged();

        // Before 1 minute: no sync
        async.elapse(const Duration(seconds: 59));
        expect(requestedModes, isEmpty);

        // At 1 minute: single sync
        async.elapse(const Duration(seconds: 1));
        expect(requestedModes, [SyncMode.incrementalPush]);
      });
    });

    test('onAppResumed triggers immediate pull', () {
      fakeAsync((async) {
        scheduler.onAppResumed();
        async.elapse(Duration.zero);
        expect(requestedModes, contains(SyncMode.incrementalPull));
      });
    });

    test('onAppPaused flushes pending debounce', () {
      fakeAsync((async) {
        scheduler.onTransactionChanged();
        async.elapse(const Duration(seconds: 30));
        expect(requestedModes, isEmpty);

        scheduler.onAppPaused();
        async.elapse(Duration.zero);
        expect(requestedModes, [SyncMode.incrementalPush]);
      });
    });

    test('onAppPaused cancels polling timer', () {
      fakeAsync((async) {
        scheduler.onAppResumed();
        async.elapse(Duration.zero);
        requestedModes.clear();

        scheduler.onAppPaused();

        // 15 minutes pass but no polling since paused
        async.elapse(const Duration(minutes: 15));
        expect(requestedModes, isEmpty);
      });
    });

    test('manual sync skips debounce', () {
      fakeAsync((async) {
        scheduler.onManualSync();
        async.elapse(Duration.zero);
        expect(requestedModes, contains(SyncMode.incrementalPush));
      });
    });

    test('anti-reentry queues pending requests', () {
      fakeAsync((async) {
        var syncCount = 0;
        final slowScheduler = SyncScheduler(
          onSyncRequested: (mode) async {
            syncCount++;
            await Future.delayed(const Duration(seconds: 5));
          },
          checkNeedsFullPull: () async => false,
        );

        slowScheduler.onAppResumed();
        async.elapse(Duration.zero);

        // While first sync is running, trigger another
        slowScheduler.onProfileChanged();
        async.elapse(const Duration(seconds: 2));

        // First sync still running
        expect(syncCount, 1);

        // Complete first sync
        async.elapse(const Duration(seconds: 3));

        // Pending should execute
        async.elapse(const Duration(seconds: 6));
        expect(syncCount, greaterThan(1));

        slowScheduler.dispose();
      });
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/infrastructure/sync/sync_scheduler_test.dart`
Expected: FAIL — class not found

- [ ] **Step 3: Implement SyncScheduler**

Create `lib/infrastructure/sync/sync_scheduler.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';

// NOTE: dart:async is required for Timer and unawaited

/// Callback invoked when the scheduler determines a sync should happen.
typedef SyncRequestCallback = Future<void> Function(SyncMode mode);

/// Callback to check if a full pull is needed (>24h since last sync).
typedef NeedsFullPullCallback = Future<bool> Function();

/// Scheduling layer: manages when to sync via debounce, polling, and thresholds.
///
/// Pure platform mechanism — no business logic. Outputs [SyncMode] requests
/// via the [onSyncRequested] callback.
class SyncScheduler {
  SyncScheduler({
    required SyncRequestCallback onSyncRequested,
    required NeedsFullPullCallback checkNeedsFullPull,
  }) : _onSyncRequested = onSyncRequested,
       _checkNeedsFullPull = checkNeedsFullPull;

  final SyncRequestCallback _onSyncRequested;
  final NeedsFullPullCallback _checkNeedsFullPull;

  Timer? _debounceTimer;
  Timer? _pollingTimer;
  bool _isSyncing = false;
  final Set<SyncMode> _pendingModes = {};

  static const _debounceDuration = Duration(minutes: 1);
  static const _pollingInterval = Duration(minutes: 15);

  /// Transaction changed — reset 1-minute debounce timer.
  void onTransactionChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _enqueueSync(SyncMode.incrementalPush);
    });
  }

  /// App resumed — immediate pull + start 15-min polling.
  void onAppResumed() {
    _enqueueSync(SyncMode.incrementalPull);
    _startPollingTimer();
    _check24HourThreshold();
  }

  /// App paused — flush pending debounce + stop polling.
  void onAppPaused() {
    if (_debounceTimer?.isActive ?? false) {
      _debounceTimer!.cancel();
      _enqueueSync(SyncMode.incrementalPush);
    }
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Push notification: syncAvailable — immediate pull.
  void onSyncAvailable() {
    _enqueueSync(SyncMode.incrementalPull);
  }

  /// Push notification: memberConfirmed — initial sync.
  void onMemberConfirmed() {
    _enqueueSync(SyncMode.initialSync);
  }

  /// User changed profile — immediate profile sync.
  void onProfileChanged() {
    _enqueueSync(SyncMode.profileSync);
  }

  /// Manual sync — skip debounce, immediate push + pull.
  void onManualSync() {
    _debounceTimer?.cancel();
    _enqueueSync(SyncMode.incrementalPush);
    _enqueueSync(SyncMode.incrementalPull);
  }

  void dispose() {
    _debounceTimer?.cancel();
    _pollingTimer?.cancel();
    _debounceTimer = null;
    _pollingTimer = null;
    _pendingModes.clear();
  }

  void _startPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      _enqueueSync(SyncMode.incrementalPull);
      _check24HourThreshold();
    });
  }

  void _check24HourThreshold() {
    unawaited(
      _checkNeedsFullPull().then((needs) {
        if (needs) _enqueueSync(SyncMode.fullPull);
      }).catchError((_) {}),
    );
  }

  Future<void> _enqueueSync(SyncMode mode) async {
    if (_isSyncing) {
      _pendingModes.add(mode);
      return;
    }

    _isSyncing = true;
    try {
      await _onSyncRequested(mode);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncScheduler: sync failed for $mode: $e');
      }
    } finally {
      _isSyncing = false;
      if (_pendingModes.isNotEmpty) {
        final sorted = _pendingModes.toList()
          ..sort((a, b) => a.priority.compareTo(b.priority));
        _pendingModes.clear();
        for (final pending in sorted) {
          await _enqueueSync(pending);
        }
      }
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/infrastructure/sync/sync_scheduler_test.dart`
Expected: PASS

- [ ] **Step 5: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Commit**

```bash
git add lib/infrastructure/sync/sync_scheduler.dart \
  test/unit/infrastructure/sync/sync_scheduler_test.dart
git commit -m "feat(sync): add SyncScheduler with debounce, polling, and anti-reentry"
```

---

## Task 7: SyncOrchestrator (Application Layer)

**Files:**
- Create: `lib/application/family_sync/sync_orchestrator.dart`
- Test: `test/unit/application/family_sync/sync_orchestrator_test.dart`

**Context:** The orchestration layer from spec §4. Coordinates existing Use Cases into four sync modes: InitialSync, IncrementalSync, ProfileSync, FullPull. Contains the `buildOperations` logic for injecting profile into push payloads (spec §5.2). All business logic, no timers.

- [ ] **Step 1: Write tests**

Create `test/unit/application/family_sync/sync_orchestrator_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/application/family_sync/pull_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/push_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/full_sync_use_case.dart';
import 'package:home_pocket/application/family_sync/sync_avatar_use_case.dart';
import 'package:home_pocket/application/family_sync/check_group_validity_use_case.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

class MockPullSync extends Mock implements PullSyncUseCase {}
class MockPushSync extends Mock implements PushSyncUseCase {}
class MockFullSync extends Mock implements FullSyncUseCase {}
class MockAvatarSync extends Mock implements SyncAvatarUseCase {}
class MockCheckValidity extends Mock implements CheckGroupValidityUseCase {}
class MockShadowBook extends Mock implements ShadowBookService {}
class MockGroupRepo extends Mock implements GroupRepository {}
class MockProfileRepo extends Mock implements UserProfileRepository {}
class MockQueueManager extends Mock implements SyncQueueManager {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late SyncOrchestrator orchestrator;
  late MockPullSync mockPull;
  late MockPushSync mockPush;
  late MockFullSync mockFull;
  late MockGroupRepo mockGroupRepo;
  late MockQueueManager mockQueue;

  setUp(() {
    mockPull = MockPullSync();
    mockPush = MockPushSync();
    mockFull = MockFullSync();
    mockGroupRepo = MockGroupRepo();
    mockQueue = MockQueueManager();

    orchestrator = SyncOrchestrator(
      pullSync: mockPull,
      pushSync: mockPush,
      fullSync: mockFull,
      avatarSync: MockAvatarSync(),
      checkValidity: MockCheckValidity(),
      shadowBookService: MockShadowBook(),
      groupRepo: mockGroupRepo,
      profileRepo: MockProfileRepo(),
      queueManager: mockQueue,
      keyManager: MockKeyManager(),
    );
  });

  group('executeIncrementalPull', () {
    test('calls pullSync and updates lastSyncAt', () async {
      when(() => mockGroupRepo.getActiveGroup()).thenAnswer(
        (_) async => _activeGroup(),
      );
      when(() => mockPull.execute())
          .thenAnswer((_) async => PullSyncResult.success(5));
      when(() => mockQueue.drainQueue()).thenAnswer((_) async => 0);
      when(() => mockQueue.getPendingCount()).thenAnswer((_) async => 0);

      final result = await orchestrator.execute(SyncMode.incrementalPull);
      expect(result, isA<SyncOrchestratorSuccess>());
      verify(() => mockPull.execute()).called(1);
    });
  });

  group('executeIncrementalPush', () {
    test('returns noGroup when no active group', () async {
      when(() => mockGroupRepo.getActiveGroup()).thenAnswer((_) async => null);

      final result = await orchestrator.execute(SyncMode.incrementalPush);
      expect(result, isA<SyncOrchestratorNoGroup>());
    });
  });
}

GroupInfo _activeGroup() => GroupInfo(
  groupId: 'g1',
  status: GroupStatus.active,
  groupName: 'Test',
  role: 'owner',
  groupKey: 'key123',
  members: [],
  createdAt: DateTime(2026),
  lastSyncAt: DateTime.now().subtract(const Duration(hours: 1)),
);
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/family_sync/sync_orchestrator_test.dart`
Expected: FAIL — class not found

- [ ] **Step 3: Implement SyncOrchestrator**

Create `lib/application/family_sync/sync_orchestrator.dart`:

```dart
import 'dart:convert';

import 'package:crypto/crypto.dart' as hash_lib;
import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../features/profile/domain/repositories/user_profile_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'check_group_validity_use_case.dart';
import 'full_sync_use_case.dart';
import 'pull_sync_use_case.dart';
import 'push_sync_use_case.dart';
import 'shadow_book_service.dart';
import 'sync_avatar_use_case.dart';

/// Result of an orchestrated sync operation.
sealed class SyncOrchestratorResult {
  const SyncOrchestratorResult();
}

class SyncOrchestratorSuccess extends SyncOrchestratorResult {
  const SyncOrchestratorSuccess({this.appliedCount = 0, this.pushedCount = 0});
  final int appliedCount;
  final int pushedCount;
}

class SyncOrchestratorNoGroup extends SyncOrchestratorResult {
  const SyncOrchestratorNoGroup();
}

class SyncOrchestratorError extends SyncOrchestratorResult {
  const SyncOrchestratorError(this.message);
  final String message;
}

/// Orchestration layer: sequences Use Cases into sync modes.
///
/// No timers or scheduling — pure business logic coordination.
class SyncOrchestrator {
  SyncOrchestrator({
    required PullSyncUseCase pullSync,
    required PushSyncUseCase pushSync,
    required FullSyncUseCase fullSync,
    required SyncAvatarUseCase avatarSync,
    required CheckGroupValidityUseCase checkValidity,
    required ShadowBookService shadowBookService,
    required GroupRepository groupRepo,
    required UserProfileRepository profileRepo,
    required SyncQueueManager queueManager,
    required KeyManager keyManager,
  }) : _pullSync = pullSync,
       _pushSync = pushSync,
       _fullSync = fullSync,
       _avatarSync = avatarSync,
       _checkValidity = checkValidity,
       _shadowBookService = shadowBookService,
       _groupRepo = groupRepo,
       _profileRepo = profileRepo,
       _queueManager = queueManager,
       _keyManager = keyManager;

  final PullSyncUseCase _pullSync;
  final PushSyncUseCase _pushSync;
  final FullSyncUseCase _fullSync;
  final SyncAvatarUseCase _avatarSync;
  final CheckGroupValidityUseCase _checkValidity;
  final ShadowBookService _shadowBookService;
  final GroupRepository _groupRepo;
  final UserProfileRepository _profileRepo;
  final SyncQueueManager _queueManager;
  final KeyManager _keyManager;

  /// Tracks last pushed profile hash to avoid redundant profile operations.
  String? _lastPushedProfileHash;

  /// Execute a sync mode. Returns the result.
  Future<SyncOrchestratorResult> execute(SyncMode mode) async {
    try {
      return switch (mode) {
        SyncMode.initialSync => await _executeInitialSync(),
        SyncMode.incrementalPush => await _executeIncrementalPush(),
        SyncMode.incrementalPull => await _executeIncrementalPull(),
        SyncMode.profileSync => await _executeProfileSync(),
        SyncMode.fullPull => await _executeFullPull(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SyncOrchestrator: $mode failed: $e');
      }
      return SyncOrchestratorError(e.toString());
    }
  }

  /// Check 24h threshold for full pull.
  Future<bool> needsFullPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return false;
    final lastSync = group.lastSyncAt;
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync) > const Duration(hours: 24);
  }

  /// Get pending queue count for SyncStatus.
  Future<int> getPendingQueueCount() => _queueManager.getPendingCount();

  // --- Private orchestration flows ---

  Future<SyncOrchestratorResult> _executeInitialSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final deviceId = await _keyManager.getDeviceId();
    final isOwner = group.role == 'owner';

    if (isOwner) {
      // Owner: push all → push avatar → pull
      final pushed = await _fullSync.execute();
      await _avatarSync.pushAvatarToMembers(groupId: group.groupId);
      final pullResult = await _pullSync.execute();
      final applied = pullResult is PullSyncSuccess
          ? pullResult.appliedCount
          : 0;
      return SyncOrchestratorSuccess(
        pushedCount: pushed,
        appliedCount: applied,
      );
    } else {
      // Joiner: pull → push all → push avatar
      final pullResult = await _pullSync.execute();
      final applied = pullResult is PullSyncSuccess
          ? pullResult.appliedCount
          : 0;
      final pushed = await _fullSync.execute();
      await _avatarSync.pushAvatarToMembers(groupId: group.groupId);
      return SyncOrchestratorSuccess(
        pushedCount: pushed,
        appliedCount: applied,
      );
    }
  }

  Future<SyncOrchestratorResult> _executeIncrementalPush() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    // Check group validity (5-min cache)
    final validity = await _checkValidity.execute();
    if (validity is GroupInvalid) {
      return SyncOrchestratorError('Group invalid: ${validity.reason}');
    }
    if (validity is GroupNoGroup) {
      return const SyncOrchestratorNoGroup();
    }

    // Build profile operation if changed
    final profileOps = await _buildProfileOperationsIfChanged();

    if (profileOps.isNotEmpty) {
      await _pushSync.execute(
        operations: profileOps,
        vectorClock: const {},
      );
    }

    // Drain offline queue
    await _queueManager.drainQueue();

    return const SyncOrchestratorSuccess();
  }

  Future<SyncOrchestratorResult> _executeIncrementalPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final pullResult = await _pullSync.execute();
    final applied = pullResult is PullSyncSuccess
        ? pullResult.appliedCount
        : 0;

    return SyncOrchestratorSuccess(appliedCount: applied);
  }

  Future<SyncOrchestratorResult> _executeProfileSync() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final profile = await _profileRepo.find();
    if (profile == null) return const SyncOrchestratorSuccess();

    final deviceId = await _keyManager.getDeviceId() ?? '';

    // Always push profile on explicit profile sync
    final ops = <Map<String, dynamic>>[
      {
        'op': 'update',
        'entityType': 'profile',
        'entityId': deviceId,
        'data': {
          'displayName': profile.displayName,
          'avatarEmoji': profile.avatarEmoji,
        },
        'fromDeviceId': deviceId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ];

    await _pushSync.execute(operations: ops, vectorClock: const {});

    // Push avatar if available
    await _avatarSync.pushAvatarToMembers(groupId: group.groupId);

    // Update last pushed hash
    _lastPushedProfileHash = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );

    return const SyncOrchestratorSuccess(pushedCount: 1);
  }

  Future<SyncOrchestratorResult> _executeFullPull() async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) return const SyncOrchestratorNoGroup();

    final pullResult = await _pullSync.execute();
    final applied = pullResult is PullSyncSuccess
        ? pullResult.appliedCount
        : 0;

    return SyncOrchestratorSuccess(appliedCount: applied);
  }

  // --- Profile change detection ---

  Future<List<Map<String, dynamic>>> _buildProfileOperationsIfChanged() async {
    final profile = await _profileRepo.find();
    if (profile == null) return const [];

    final deviceId = await _keyManager.getDeviceId() ?? '';
    final currentHash = _computeProfileHash(
      profile.displayName,
      profile.avatarEmoji,
    );

    if (currentHash == _lastPushedProfileHash) return const [];

    _lastPushedProfileHash = currentHash;
    return [
      {
        'op': 'update',
        'entityType': 'profile',
        'entityId': deviceId,
        'data': {
          'displayName': profile.displayName,
          'avatarEmoji': profile.avatarEmoji,
        },
        'fromDeviceId': deviceId,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    ];
  }

  String _computeProfileHash(String displayName, String avatarEmoji) {
    final input = '$displayName|$avatarEmoji';
    return hash_lib.sha256.convert(utf8.encode(input)).toString();
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/family_sync/sync_orchestrator_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/sync_orchestrator.dart \
  test/unit/application/family_sync/sync_orchestrator_test.dart
git commit -m "feat(sync): add SyncOrchestrator with 4 sync mode orchestration"
```

---

## Task 8: SyncEngine Facade

**Files:**
- Create: `lib/application/family_sync/sync_engine.dart`
- Test: `test/unit/application/family_sync/sync_engine_test.dart`

**Context:** The unified entry point from spec §7. Wires SyncScheduler → SyncOrchestrator, manages `SyncStatus` stream, provides public API (`onTransactionChanged`, `onProfileChanged`, `initialize`, `dispose`).

- [ ] **Step 1: Write tests**

Create `test/unit/application/family_sync/sync_engine_test.dart`:

```dart
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/sync_engine.dart';
import 'package:home_pocket/application/family_sync/sync_orchestrator.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status_model.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/sync_scheduler.dart';

class MockOrchestrator extends Mock implements SyncOrchestrator {}
class MockGroupRepo extends Mock implements GroupRepository {}

void main() {
  late SyncEngine engine;
  late MockOrchestrator mockOrchestrator;
  late MockGroupRepo mockGroupRepo;

  setUp(() {
    mockOrchestrator = MockOrchestrator();
    mockGroupRepo = MockGroupRepo();

    when(() => mockOrchestrator.needsFullPull())
        .thenAnswer((_) async => false);
    when(() => mockOrchestrator.getPendingQueueCount())
        .thenAnswer((_) async => 0);
    when(() => mockGroupRepo.getActiveGroup())
        .thenAnswer((_) async => null);

    engine = SyncEngine(
      orchestrator: mockOrchestrator,
      groupRepo: mockGroupRepo,
    );
  });

  tearDown(() => engine.dispose());

  test('initial status is noGroup when no active group', () {
    expect(engine.currentStatus.state, SyncState.noGroup);
  });

  test('statusStream emits updates', () async {
    when(() => mockOrchestrator.execute(any()))
        .thenAnswer((_) async => const SyncOrchestratorNoGroup());

    final states = <SyncState>[];
    final sub = engine.statusStream.listen((s) => states.add(s.state));

    engine.onManualSync();
    await Future.delayed(Duration.zero);

    sub.cancel();
    // Should have emitted at least the noGroup status
    expect(states, isNotEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/family_sync/sync_engine_test.dart`
Expected: FAIL — class not found

- [ ] **Step 3: Implement SyncEngine**

Create `lib/application/family_sync/sync_engine.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/family_sync/domain/models/sync_status_model.dart';
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_lifecycle_observer.dart';
import '../../infrastructure/sync/sync_scheduler.dart';
import 'sync_orchestrator.dart';

/// Unified sync entry point. Combines SyncScheduler + SyncOrchestrator
/// and exposes a reactive SyncStatus stream.
class SyncEngine {
  SyncEngine({
    required SyncOrchestrator orchestrator,
    required GroupRepository groupRepo,
  }) : _orchestrator = orchestrator,
       _groupRepo = groupRepo {
    _scheduler = SyncScheduler(
      onSyncRequested: _handleSyncRequest,
      checkNeedsFullPull: _orchestrator.needsFullPull,
    );
  }

  final SyncOrchestrator _orchestrator;
  final GroupRepository _groupRepo;
  late final SyncScheduler _scheduler;
  SyncLifecycleObserver? _lifecycleObserver;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _currentStatus = const SyncStatus(state: SyncState.noGroup);

  /// Current sync status.
  SyncStatus get currentStatus => _currentStatus;

  /// Stream of sync status changes.
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Initialize the engine: set up lifecycle observer.
  ///
  /// Call once at app startup after provider container is ready.
  void initialize() {
    _lifecycleObserver = SyncLifecycleObserver(
      onResume: () async => _scheduler.onAppResumed(),
      onPaused: () => _scheduler.onAppPaused(),
    );
    _lifecycleObserver!.start();

    // Set initial status based on group presence
    unawaited(_refreshInitialStatus());
  }

  /// Dispose all timers and observers.
  void dispose() {
    _scheduler.dispose();
    _lifecycleObserver?.dispose();
    _lifecycleObserver = null;
    unawaited(_statusController.close());
  }

  // --- Public API (called by transaction use cases, push handlers, etc.) ---

  /// Transaction created/updated/deleted.
  void onTransactionChanged() => _scheduler.onTransactionChanged();

  /// User modified profile (name/avatar).
  void onProfileChanged() => _scheduler.onProfileChanged();

  /// Push notification: syncAvailable.
  void onSyncAvailable() => _scheduler.onSyncAvailable();

  /// Push notification: memberConfirmed (Group activated).
  void onMemberConfirmed() => _scheduler.onMemberConfirmed();

  /// Manual sync button pressed.
  void onManualSync() => _scheduler.onManualSync();

  // --- Internal ---

  Future<void> _refreshInitialStatus() async {
    final group = await _groupRepo.getActiveGroup();
    if (group != null) {
      final pendingCount = await _orchestrator.getPendingQueueCount();
      _updateStatus(SyncStatus(
        state: pendingCount > 0 ? SyncState.queuedOffline : SyncState.idle,
        lastSyncAt: group.lastSyncAt,
        pendingQueueCount: pendingCount,
      ));
    } else {
      _updateStatus(const SyncStatus(state: SyncState.noGroup));
    }
  }

  Future<void> _handleSyncRequest(SyncMode mode) async {
    final group = await _groupRepo.getActiveGroup();
    if (group == null) {
      _updateStatus(const SyncStatus(state: SyncState.noGroup));
      return;
    }

    // Emit syncing state
    final syncingState = mode == SyncMode.initialSync
        ? SyncState.initialSyncing
        : SyncState.syncing;
    _updateStatus(_currentStatus.copyWith(state: syncingState));

    final result = await _orchestrator.execute(mode);

    // Compute final status
    switch (result) {
      case SyncOrchestratorSuccess():
        final pendingCount = await _orchestrator.getPendingQueueCount();
        final refreshedGroup = await _groupRepo.getActiveGroup();
        _updateStatus(SyncStatus(
          state: pendingCount > 0 ? SyncState.queuedOffline : SyncState.synced,
          lastSyncAt: refreshedGroup?.lastSyncAt,
          pendingQueueCount: pendingCount,
        ));
      case SyncOrchestratorNoGroup():
        _updateStatus(const SyncStatus(state: SyncState.noGroup));
      case SyncOrchestratorError(:final message):
        final pendingCount = await _orchestrator.getPendingQueueCount();
        _updateStatus(SyncStatus(
          state: SyncState.error,
          lastSyncAt: _currentStatus.lastSyncAt,
          pendingQueueCount: pendingCount,
          errorMessage: message,
        ));
    }
  }

  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/family_sync/sync_engine_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add lib/application/family_sync/sync_engine.dart \
  test/unit/application/family_sync/sync_engine_test.dart
git commit -m "feat(sync): add SyncEngine facade with status stream"
```

---

## Task 9: Group Lifecycle Use Cases (HandleMemberLeft + HandleGroupDissolved)

**Files:**
- Create: `lib/application/family_sync/handle_member_left_use_case.dart`
- Create: `lib/application/family_sync/handle_group_dissolved_use_case.dart`
- Test: `test/unit/application/family_sync/handle_member_left_use_case_test.dart`
- Test: `test/unit/application/family_sync/handle_group_dissolved_use_case_test.dart`

**Context:** When `SyncTriggerService` is deleted, the `_handleMemberLeft` and `_handleGroupDissolved` logic needs a new home. These are Group lifecycle operations, not sync. Extract to standalone Use Cases.

- [ ] **Step 1: Write test for HandleMemberLeftUseCase**

Create `test/unit/application/family_sync/handle_member_left_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/handle_member_left_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';

class MockGroupRepo extends Mock implements GroupRepository {}
class MockQueueManager extends Mock implements SyncQueueManager {}
class MockShadowBookService extends Mock implements ShadowBookService {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late HandleMemberLeftUseCase useCase;
  late MockGroupRepo mockGroupRepo;
  late MockQueueManager mockQueue;
  late MockShadowBookService mockShadow;
  late MockKeyManager mockKeyManager;

  setUp(() {
    mockGroupRepo = MockGroupRepo();
    mockQueue = MockQueueManager();
    mockShadow = MockShadowBookService();
    mockKeyManager = MockKeyManager();

    useCase = HandleMemberLeftUseCase(
      groupRepo: mockGroupRepo,
      queueManager: mockQueue,
      shadowBookService: mockShadow,
      keyManager: mockKeyManager,
    );
  });

  test('deactivates group when this device was removed', () async {
    when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'my-device');
    when(() => mockQueue.clearQueue()).thenAnswer((_) async {});
    when(() => mockShadow.cleanSyncData(any())).thenAnswer((_) async {});
    when(() => mockGroupRepo.deactivateGroup(any())).thenAnswer((_) async {});

    await useCase.execute(
      groupId: 'g1',
      deviceId: 'my-device',
      reason: 'removed',
    );

    verify(() => mockGroupRepo.deactivateGroup('g1')).called(1);
    verify(() => mockQueue.clearQueue()).called(1);
  });

  test('removes other member from local list', () async {
    when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'my-device');
    when(() => mockGroupRepo.getGroupById('g1')).thenAnswer((_) async => GroupInfo(
      groupId: 'g1',
      status: GroupStatus.active,
      groupName: 'Test',
      role: 'owner',
      members: [
        const GroupMember(deviceId: 'my-device', publicKey: 'pk1', deviceName: 'd1', role: 'owner', status: 'active', displayName: 'Me', avatarEmoji: '🐱'),
        const GroupMember(deviceId: 'other-device', publicKey: 'pk2', deviceName: 'd2', role: 'member', status: 'active', displayName: 'Other', avatarEmoji: '🐶'),
      ],
      createdAt: DateTime(2026),
    ));
    when(() => mockGroupRepo.updateMembers(any(), any())).thenAnswer((_) async {});

    await useCase.execute(
      groupId: 'g1',
      deviceId: 'other-device',
      reason: 'left',
    );

    verify(() => mockGroupRepo.updateMembers('g1', any(that: hasLength(1)))).called(1);
  });
}
```

- [ ] **Step 2: Implement HandleMemberLeftUseCase**

Create `lib/application/family_sync/handle_member_left_use_case.dart`:

```dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/crypto/services/key_manager.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'shadow_book_service.dart';

/// Handles member_left push notification.
///
/// If this device was removed: cleanup + deactivate group.
/// If another member left: update local member list.
class HandleMemberLeftUseCase {
  HandleMemberLeftUseCase({
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
    required ShadowBookService shadowBookService,
    required KeyManager keyManager,
  }) : _groupRepo = groupRepo,
       _queueManager = queueManager,
       _shadowBookService = shadowBookService,
       _keyManager = keyManager;

  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final ShadowBookService _shadowBookService;
  final KeyManager _keyManager;

  Future<void> execute({
    required String groupId,
    required String deviceId,
    String? reason,
  }) async {
    final localDeviceId = await _keyManager.getDeviceId();
    if (localDeviceId != null && deviceId == localDeviceId && reason == 'removed') {
      await _queueManager.clearQueue();
      await _shadowBookService.cleanSyncData(groupId);
      await _groupRepo.deactivateGroup(groupId);
      return;
    }

    final group = await _groupRepo.getGroupById(groupId);
    if (group == null) return;

    final updatedMembers = group.members
        .where((m) => m.deviceId != deviceId)
        .toList();
    await _groupRepo.updateMembers(groupId, updatedMembers);
  }
}
```

- [ ] **Step 3: Write test for HandleGroupDissolvedUseCase**

Create `test/unit/application/family_sync/handle_group_dissolved_use_case_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:home_pocket/application/family_sync/handle_group_dissolved_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/infrastructure/sync/sync_queue_manager.dart';
import 'package:home_pocket/application/family_sync/shadow_book_service.dart';

class MockGroupRepo extends Mock implements GroupRepository {}
class MockQueueManager extends Mock implements SyncQueueManager {}
class MockShadowBookService extends Mock implements ShadowBookService {}

void main() {
  late HandleGroupDissolvedUseCase useCase;
  late MockGroupRepo mockGroupRepo;
  late MockQueueManager mockQueue;
  late MockShadowBookService mockShadow;

  setUp(() {
    mockGroupRepo = MockGroupRepo();
    mockQueue = MockQueueManager();
    mockShadow = MockShadowBookService();

    useCase = HandleGroupDissolvedUseCase(
      groupRepo: mockGroupRepo,
      queueManager: mockQueue,
      shadowBookService: mockShadow,
    );
  });

  test('deactivates active group and cleans data', () async {
    when(() => mockGroupRepo.getActiveGroup()).thenAnswer((_) async => GroupInfo(
      groupId: 'g1',
      status: GroupStatus.active,
      groupName: 'Test',
      role: 'member',
      members: [],
      createdAt: DateTime(2026),
    ));
    when(() => mockQueue.clearQueue()).thenAnswer((_) async {});
    when(() => mockShadow.cleanSyncData(any())).thenAnswer((_) async {});
    when(() => mockGroupRepo.deactivateGroup(any())).thenAnswer((_) async {});

    await useCase.execute(groupId: 'g1');

    verify(() => mockGroupRepo.deactivateGroup('g1')).called(1);
  });
}
```

- [ ] **Step 4: Implement HandleGroupDissolvedUseCase**

Create `lib/application/family_sync/handle_group_dissolved_use_case.dart`:

```dart
import '../../features/family_sync/domain/repositories/group_repository.dart';
import '../../infrastructure/sync/sync_queue_manager.dart';
import 'shadow_book_service.dart';

/// Handles group_dissolved push notification.
///
/// Cleans local sync data and deactivates the group.
class HandleGroupDissolvedUseCase {
  HandleGroupDissolvedUseCase({
    required GroupRepository groupRepo,
    required SyncQueueManager queueManager,
    required ShadowBookService shadowBookService,
  }) : _groupRepo = groupRepo,
       _queueManager = queueManager,
       _shadowBookService = shadowBookService;

  final GroupRepository _groupRepo;
  final SyncQueueManager _queueManager;
  final ShadowBookService _shadowBookService;

  Future<void> execute({required String groupId}) async {
    final activeGroup = await _groupRepo.getActiveGroup();
    if (activeGroup == null || activeGroup.groupId != groupId) return;

    await _queueManager.clearQueue();
    await _shadowBookService.cleanSyncData(groupId);
    await _groupRepo.deactivateGroup(groupId);
  }
}
```

- [ ] **Step 5: Run tests**

Run: `flutter test test/unit/application/family_sync/handle_member_left_use_case_test.dart test/unit/application/family_sync/handle_group_dissolved_use_case_test.dart`
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add lib/application/family_sync/handle_member_left_use_case.dart \
  lib/application/family_sync/handle_group_dissolved_use_case.dart \
  test/unit/application/family_sync/handle_member_left_use_case_test.dart \
  test/unit/application/family_sync/handle_group_dissolved_use_case_test.dart
git commit -m "feat(sync): add HandleMemberLeft and HandleGroupDissolved use cases"
```

---

## Task 10: Provider Wiring

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart`

**Context:** Replace `syncTriggerServiceProvider` and `SyncStatusNotifier` with `syncEngineProvider` and new `syncStatusStreamProvider`. Add `groupMembersProvider` using `watchByGroupId`. Keep old providers temporarily for backward compat (removed in Task 16).

- [ ] **Step 1: Add SyncEngine provider and related providers**

In `lib/features/family_sync/presentation/providers/sync_providers.dart`, add:

```dart
import '../../../../application/family_sync/sync_engine.dart';
import '../../../../application/family_sync/sync_orchestrator.dart';
import '../../../../application/family_sync/sync_avatar_use_case.dart';
import '../../../../features/family_sync/domain/models/sync_status_model.dart'
    as model;
import '../../../../features/profile/presentation/providers/repository_providers.dart'
    as profile;

/// SyncAvatarUseCase provider.
@riverpod
SyncAvatarUseCase syncAvatarUseCase(Ref ref) {
  return SyncAvatarUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    userProfileRepository: ref.watch(profile.userProfileRepositoryProvider),
    e2eeService: ref.watch(e2eeServiceProvider),
  );
}

/// SyncOrchestrator provider.
@riverpod
SyncOrchestrator syncOrchestrator(Ref ref) {
  return SyncOrchestrator(
    pullSync: ref.watch(pullSyncUseCaseProvider),
    pushSync: ref.watch(pushSyncUseCaseProvider),
    fullSync: ref.watch(fullSyncUseCaseProvider),
    avatarSync: ref.watch(syncAvatarUseCaseProvider),
    checkValidity: ref.watch(checkGroupValidityUseCaseProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
    profileRepo: ref.watch(profile.userProfileRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
}

/// SyncEngine provider — keepAlive because it manages timers and lifecycle.
@Riverpod(keepAlive: true)
SyncEngine syncEngine(Ref ref) {
  final engine = SyncEngine(
    orchestrator: ref.watch(syncOrchestratorProvider),
    groupRepo: ref.watch(groupRepositoryProvider),
  );
  ref.onDispose(engine.dispose);
  return engine;
}

/// Reactive sync status stream from SyncEngine.
@riverpod
Stream<model.SyncStatus> syncStatusStream(Ref ref) {
  return ref.watch(syncEngineProvider).statusStream;
}

/// GroupMembers stream via Drift watch query, mapped to domain model.
@riverpod
Stream<List<GroupMember>> groupMembers(Ref ref) {
  final activeGroup = ref.watch(activeGroupProvider).valueOrNull;
  if (activeGroup == null) return Stream.value([]);
  final dao = ref.watch(groupMemberDaoProvider);
  return dao.watchByGroupId(activeGroup.groupId).map(
    (rows) => rows.map((row) => GroupMember(
      deviceId: row.deviceId,
      publicKey: row.publicKey,
      deviceName: row.deviceName,
      role: row.role,
      status: row.status,
      displayName: row.displayName,
      avatarEmoji: row.avatarEmoji,
      avatarImagePath: row.avatarImagePath,
      avatarImageHash: row.avatarImageHash,
    )).toList(),
  );
}
```

Note: `groupMemberDaoProvider` may need to be added to `repository_providers.dart` if not already exposed. Check and add if needed:

```dart
@riverpod
GroupMemberDao groupMemberDao(Ref ref) {
  return ref.watch(appDatabaseProvider).groupMemberDao;
}
```

- [ ] **Step 2: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/providers/sync_providers.dart \
  lib/features/family_sync/presentation/providers/sync_providers.g.dart \
  lib/features/family_sync/presentation/providers/repository_providers.dart \
  lib/features/family_sync/presentation/providers/repository_providers.g.dart
git commit -m "feat(sync): add SyncEngine, SyncOrchestrator, and GroupMembers providers"
```

---

## Task 11: Push Notification Handler Migration

**Files:**
- Modify: `lib/infrastructure/sync/push_notification_service.dart`

**Context:** Currently PushNotificationService registers handlers via `SyncTriggerService`. After migration, sync-related events (`syncAvailable`, `memberConfirmed`) route to `SyncEngine`. UI events (`joinRequest`) stay as direct stream. Lifecycle events (`memberLeft`, `groupDissolved`) route to new Use Cases.

- [ ] **Step 1: Add SyncEngine and Use Case callbacks to PushNotificationService**

Modify `push_notification_service.dart` to accept sync and lifecycle callbacks:

```dart
/// Callbacks for push notification handling.
typedef OnSyncEngineEvent = void Function();
typedef OnMemberLeftEvent = Future<void> Function(Map<String, dynamic> data);
typedef OnGroupDissolvedEvent = Future<void> Function(Map<String, dynamic> data);
typedef OnJoinRequestEvent = Future<void> Function(Map<String, dynamic> data);
```

Replace the current `registerHandlers` method with:

```dart
void registerSyncHandlers({
  required OnSyncEngineEvent onSyncAvailable,
  required OnSyncEngineEvent onMemberConfirmed,
  required OnJoinRequestEvent onJoinRequest,
  required OnMemberLeftEvent onMemberLeft,
  required OnGroupDissolvedEvent onGroupDissolved,
}) {
  _onSyncAvailable = onSyncAvailable;
  _onMemberConfirmed = onMemberConfirmed;
  _onJoinRequest = onJoinRequest;
  _onMemberLeft = onMemberLeft;
  _onGroupDissolved = onGroupDissolved;
}
```

Update the message handlers to use the new callbacks and publish `SyncTriggerEvent` for UI navigation on joinRequest, memberLeft, and groupDissolved.

**Important:** Keep backward compatibility by supporting both old and new handler registration during the transition. The old `registerHandlers` method can be deprecated.

- [ ] **Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 3: Commit**

```bash
git add lib/infrastructure/sync/push_notification_service.dart
git commit -m "refactor(sync): migrate push notification handlers to SyncEngine callbacks"
```

---

## Task 12: Transaction Use Case Migration

**Files:**
- Modify: `lib/application/accounting/create_transaction_use_case.dart`
- Modify: `lib/application/accounting/delete_transaction_use_case.dart`

**Context:** Replace `SyncTriggerService` dependency with `SyncEngine.onTransactionChanged()`. The new API is simpler — just a void call, no operations to build. The SyncEngine handles debounce internally.

- [ ] **Step 1: Update CreateTransactionUseCase**

In `lib/application/accounting/create_transaction_use_case.dart`:

1. Replace `SyncTriggerService? _syncTriggerService` with `SyncEngine? _syncEngine`
2. Replace `CheckGroupValidityUseCase? _checkGroupValidity` — no longer needed here (SyncOrchestrator handles it)
3. Simplify `_triggerIncrementalSync` to just call `_syncEngine?.onTransactionChanged()`

The sync trigger method becomes:

```dart
void _triggerIncrementalSync() {
  _syncEngine?.onTransactionChanged();
}
```

Call it after `_transactionRepo.insert(transaction)` at line 193. Remove the entire old `_triggerIncrementalSync` method with its `unawaited(Future(...))` block — the SyncEngine handles debounce, validity check, and operation building internally.

Update the constructor to accept `SyncEngine?` instead of `SyncTriggerService?` and `CheckGroupValidityUseCase?`.

- [ ] **Step 2: Update DeleteTransactionUseCase**

In `lib/application/accounting/delete_transaction_use_case.dart`:

1. Replace `SyncTriggerService?` with `SyncEngine?`
2. Replace `_syncTriggerService?.onTransactionDeleted(transactionId)` with `_syncEngine?.onTransactionChanged()`

```dart
class DeleteTransactionUseCase {
  DeleteTransactionUseCase({
    required TransactionRepository transactionRepository,
    SyncEngine? syncEngine,
  }) : _transactionRepo = transactionRepository,
       _syncEngine = syncEngine;

  final TransactionRepository _transactionRepo;
  final SyncEngine? _syncEngine;

  Future<Result<void>> execute(String transactionId) async {
    if (transactionId.isEmpty) {
      return Result.error('transactionId must not be empty');
    }

    final existing = await _transactionRepo.findById(transactionId);
    if (existing == null) {
      return Result.error('Transaction not found');
    }

    await _transactionRepo.softDelete(transactionId);
    _syncEngine?.onTransactionChanged();
    return Result.success(null);
  }
}
```

- [ ] **Step 3: Update providers wiring these use cases**

Find and update the providers that create `CreateTransactionUseCase` and `DeleteTransactionUseCase` to pass `syncEngine` instead of `syncTriggerService`.

- [ ] **Step 4: Run existing tests**

Run: `flutter test test/unit/application/accounting/`
Expected: PASS (may need to update mocks)

- [ ] **Step 5: Commit**

```bash
git add lib/application/accounting/create_transaction_use_case.dart \
  lib/application/accounting/delete_transaction_use_case.dart
git commit -m "refactor(sync): migrate transaction use cases to SyncEngine"
```

---

## Task 13: App Initialization Migration

**Files:**
- Modify: `lib/main.dart`

**Context:** Replace `syncTriggerService.initialize()` with `syncEngine.initialize()` + register push notification handlers via SyncEngine.

- [ ] **Step 1: Update initialization**

In `lib/main.dart`, at the sync initialization section (~line 115-116):

Replace:
```dart
final syncTrigger = ref.read(syncTriggerServiceProvider);
await syncTrigger.initialize();
```

With:
```dart
final syncEngine = ref.read(syncEngineProvider);
syncEngine.initialize();

// Register push notification handlers
final pushService = ref.read(pushNotificationServiceProvider);
pushService.registerSyncHandlers(
  onSyncAvailable: syncEngine.onSyncAvailable,
  onMemberConfirmed: syncEngine.onMemberConfirmed,
  onJoinRequest: (data) async {
    // Existing join request handling — refresh members from server
    // then publish UI event
    final groupId = data['groupId'] as String?;
    if (groupId != null) {
      final apiClient = ref.read(relayApiClientProvider);
      final groupRepo = ref.read(groupRepositoryProvider);
      try {
        final status = await apiClient.getGroupStatus(groupId);
        final rawMembers = status['members'] as List<dynamic>? ?? const [];
        final members = rawMembers
            .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
            .toList();
        await groupRepo.updateMembers(groupId, members);
      } catch (_) {}
    }
  },
  onMemberLeft: (data) async {
    final groupId = data['groupId'] as String?;
    final deviceId = data['deviceId'] as String?;
    final reason = data['reason'] as String?;
    if (groupId == null || deviceId == null) return;
    final useCase = ref.read(handleMemberLeftUseCaseProvider);
    await useCase.execute(groupId: groupId, deviceId: deviceId, reason: reason);
  },
  onGroupDissolved: (data) async {
    final groupId = data['groupId'] as String?;
    if (groupId == null) return;
    final useCase = ref.read(handleGroupDissolvedUseCaseProvider);
    await useCase.execute(groupId: groupId);
  },
);
await pushService.initialize();
```

- [ ] **Step 2: Add missing provider imports and definitions**

Ensure `handleMemberLeftUseCaseProvider` and `handleGroupDissolvedUseCaseProvider` exist in sync_providers.dart:

```dart
@riverpod
HandleMemberLeftUseCase handleMemberLeftUseCase(Ref ref) {
  return HandleMemberLeftUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
}

@riverpod
HandleGroupDissolvedUseCase handleGroupDissolvedUseCase(Ref ref) {
  return HandleGroupDissolvedUseCase(
    groupRepo: ref.watch(groupRepositoryProvider),
    queueManager: ref.watch(syncQueueManagerProvider),
    shadowBookService: ref.watch(shadowBookServiceProvider),
  );
}
```

- [ ] **Step 3: Run build_runner + analyzer**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/main.dart \
  lib/features/family_sync/presentation/providers/sync_providers.dart \
  lib/features/family_sync/presentation/providers/sync_providers.g.dart
git commit -m "refactor(sync): migrate app initialization to SyncEngine"
```

---

## Task 14: i18n Additions

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

**Context:** Add the 9 new keys from spec §10. Must be done before UI migration tasks that reference these keys.

- [ ] **Step 1: Add keys to all 3 ARB files**

**English (`app_en.arb`):**
```json
"syncInProgress": "Syncing...",
"@syncInProgress": { "description": "Sync in progress status" },
"syncCompleted": "Sync complete",
"@syncCompleted": { "description": "Sync completed status" },
"syncFailed": "Sync failed",
"@syncFailed": { "description": "Sync failed status" },
"syncRetry": "Retry",
"@syncRetry": { "description": "Retry sync button" },
"syncManual": "Sync Now",
"@syncManual": { "description": "Manual sync button" },
"syncLastTime": "Last sync: {time}",
"@syncLastTime": { "description": "Last sync time", "placeholders": { "time": { "type": "String" } } },
"syncOfflineQueued": "{count} changes pending",
"@syncOfflineQueued": { "description": "Offline queue count", "placeholders": { "count": { "type": "int" } } },
"syncInitialProgress": "Initial sync...",
"@syncInitialProgress": { "description": "Initial sync in progress" },
"syncProfileUpdated": "{name} updated their profile",
"@syncProfileUpdated": { "description": "Profile update notification", "placeholders": { "name": { "type": "String" } } }
```

**Japanese (`app_ja.arb`):**
```json
"syncInProgress": "同期中...",
"syncCompleted": "同期完了",
"syncFailed": "同期に失敗しました",
"syncRetry": "再試行",
"syncManual": "手動で同期",
"syncLastTime": "最終同期: {time}",
"syncOfflineQueued": "{count}件の変更が送信待ち",
"syncInitialProgress": "初回同期中...",
"syncProfileUpdated": "{name}がプロフィールを更新しました"
```

**Chinese (`app_zh.arb`):**
```json
"syncInProgress": "同步中...",
"syncCompleted": "同步完成",
"syncFailed": "同步失败",
"syncRetry": "重试",
"syncManual": "手动同步",
"syncLastTime": "上次同步: {time}",
"syncOfflineQueued": "{count}条变更待发送",
"syncInitialProgress": "首次同步中...",
"syncProfileUpdated": "{name}更新了个人资料"
```

- [ ] **Step 2: Run gen-l10n**

Run: `flutter gen-l10n`
Expected: Generated files updated

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb \
  lib/generated/
git commit -m "feat(sync): add i18n keys for sync engine status"
```

---

## Task 15: SyncStatusBadge Migration

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/sync_status_badge.dart`

**Context:** Migrate from old `SyncStatus` enum to new `SyncState` enum. Add new states: `initialSyncing`, `queuedOffline`. The old `sync_status.dart` can be deleted after all consumers are migrated.

- [ ] **Step 1: Update SyncStatusBadge to use SyncState**

```dart
import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status_model.dart';

class SyncStatusBadge extends StatelessWidget {
  const SyncStatusBadge({
    super.key,
    required this.state,
    this.compact = false,
  });

  final SyncState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = _stateConfig(state, context);
    if (compact) {
      return Icon(config.icon, size: 16, color: config.color);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 14, color: config.color),
          const SizedBox(width: 4),
          Text(
            config.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: config.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _stateConfig(SyncState state, BuildContext context) {
    final l10n = S.of(context);
    return switch (state) {
      SyncState.noGroup => _StatusConfig(
        icon: Icons.link_off,
        color: Colors.grey,
        label: l10n.familySyncBadgeUnpaired,
      ),
      SyncState.idle => _StatusConfig(
        icon: Icons.check_circle_outline,
        color: Colors.grey,
        label: l10n.familySyncBadgeSynced,
      ),
      SyncState.initialSyncing => _StatusConfig(
        icon: Icons.sync,
        color: Colors.blue,
        label: l10n.syncInitialProgress,
      ),
      SyncState.syncing => _StatusConfig(
        icon: Icons.sync,
        color: Colors.blue,
        label: l10n.familySyncBadgeSyncing,
      ),
      SyncState.synced => _StatusConfig(
        icon: Icons.check_circle,
        color: Colors.green,
        label: l10n.familySyncBadgeSynced,
      ),
      SyncState.error => _StatusConfig(
        icon: Icons.error,
        color: Colors.red,
        label: l10n.familySyncBadgeError,
      ),
      SyncState.queuedOffline => _StatusConfig(
        icon: Icons.cloud_off,
        color: Colors.orange,
        label: l10n.familySyncBadgeOffline,
      ),
    };
  }
}

class _StatusConfig {
  const _StatusConfig({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;
}
```

- [ ] **Step 2: Update all consumers of SyncStatusBadge**

Search for `SyncStatusBadge(` usage and update from `status:` to `state:` parameter. Key consumers:
- `family_sync_settings_section.dart` — updated in Task 15
- `group_management_screen.dart` — updated in Task 15

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues (or known issues from not-yet-updated consumers)

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/sync_status_badge.dart
git commit -m "refactor(sync): migrate SyncStatusBadge to new SyncState enum"
```

---

## Task 16: FamilySyncSettingsSection + GroupManagement Update

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`
- Modify: `lib/features/family_sync/presentation/screens/group_management_screen.dart`

**Context:** Update both to use new `syncStatusStreamProvider` and `syncEngineProvider`. Add manual sync button and sync status display per spec §6.3-6.4.

- [ ] **Step 1: Update FamilySyncSettingsSection**

Replace `syncStatusNotifierProvider` with `syncStatusStreamProvider`:

```dart
final syncStatusAsync = ref.watch(syncStatusStreamProvider);
final syncState = syncStatusAsync.valueOrNull?.state ?? SyncState.noGroup;
```

Update `SyncStatusBadge` usage to pass `state: syncState`.

Add manual sync action:

```dart
if (activeGroup != null)
  TextButton.icon(
    icon: const Icon(Icons.refresh, size: 16),
    label: Text(l10n.syncManual),
    onPressed: () => ref.read(syncEngineProvider).onManualSync(),
  ),
```

- [ ] **Step 2: Update GroupManagementScreen**

Add sync status row below the title:

```dart
Consumer(builder: (context, ref, _) {
  final statusAsync = ref.watch(syncStatusStreamProvider);
  final status = statusAsync.valueOrNull;
  if (status == null) return const SizedBox.shrink();

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: Row(
      children: [
        SyncStatusBadge(state: status.state),
        const Spacer(),
        if (status.state != SyncState.syncing &&
            status.state != SyncState.initialSyncing)
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => ref.read(syncEngineProvider).onManualSync(),
            tooltip: S.of(context).syncManual,
          ),
      ],
    ),
  );
}),
```

- [ ] **Step 3: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart \
  lib/features/family_sync/presentation/screens/group_management_screen.dart
git commit -m "feat(sync): add manual sync button and new SyncStatus display"
```

---

## Task 17: Delete SyncTriggerService + Cleanup

**Files:**
- Delete: `lib/infrastructure/sync/sync_trigger_service.dart`
- Modify: any remaining references

**Context:** With all consumers migrated, `SyncTriggerService` can be removed. The `SyncTriggerEvent` type was already extracted to domain in Task 2. The old `SyncStatus` enum in `sync_status.dart` can also be deleted. Additional consumers that need migration: `waiting_approval_screen.dart` and `family_sync_notification_route_listener.dart` (both use `syncStatusNotifierProvider`).

- [ ] **Step 1: Delete SyncTriggerService**

```bash
rm lib/infrastructure/sync/sync_trigger_service.dart
```

- [ ] **Step 2: Delete old SyncStatus enum**

```bash
rm lib/features/family_sync/domain/models/sync_status.dart
```

- [ ] **Step 3: Update remaining imports**

Search for any remaining imports of the deleted files:

```bash
grep -r "sync_trigger_service" lib/ test/
grep -r "domain/models/sync_status.dart" lib/ test/
```

Update each to import from the new locations:
- `sync_trigger_service.dart` → `sync_trigger_event.dart` (for `SyncTriggerEvent`)
- `domain/models/sync_status.dart` → `domain/models/sync_status_model.dart` (for `SyncState`/`SyncStatus`)

Key files that also need migration (not yet updated):
- `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` — uses `syncStatusNotifierProvider`
- `lib/features/family_sync/presentation/widgets/family_sync_notification_route_listener.dart` — uses `syncStatusNotifierProvider`

Update both to use `syncEngineProvider` or `syncStatusStreamProvider` instead.

- [ ] **Step 4: Remove old SyncStatusNotifier from sync_providers.dart**

Delete the `SyncStatusNotifier` class and `syncStatusNotifierProvider` from `sync_providers.dart`. All consumers should now use `syncStatusStreamProvider`.

- [ ] **Step 5: Run build_runner + analyzer**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze`
Expected: 0 issues

- [ ] **Step 6: Run all tests**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "refactor(sync): delete SyncTriggerService and old SyncStatus enum"
```

---

## Task 18: Final Verification

**Files:** None (verification only)

- [ ] **Step 1: Run full analyzer**

Run: `flutter analyze`
Expected: 0 issues

- [ ] **Step 2: Run full test suite**

Run: `flutter test`
Expected: All tests pass

- [ ] **Step 3: Run build_runner clean rebuild**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: No errors

- [ ] **Step 4: Verify test coverage**

Run: `flutter test --coverage`
Expected: ≥80% coverage on new files

- [ ] **Step 5: Smoke test app launch**

Run: `flutter run` and verify:
1. App launches without crash
2. Settings → Family Sync section renders
3. If group exists: sync status badge shows correct state
4. Manual sync button triggers sync (check debug console)

- [ ] **Step 6: Final commit if any fixups needed**

```bash
git add -A
git commit -m "chore(sync): final verification and cleanup"
```
