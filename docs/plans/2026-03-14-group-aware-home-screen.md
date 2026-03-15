# Group-Aware Home Screen Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make HomeScreen react to local group membership — hide invite banner when in group mode, show correct mode badge, and eliminate unnecessary network checks by reading from local DB.

**Architecture:** Add a Drift `watchSingleOrNull` stream in GroupDao, expose it as a Riverpod `StreamProvider` (`activeGroupProvider`), then wire HomeScreen and SyncStatusNotifier to watch it. All group state changes (pairing success, push notifications, leave/deactivate) already write to the local DB, so the stream auto-propagates without network calls.

**Tech Stack:** Flutter, Riverpod 2.4+ (`@riverpod` codegen), Drift (SQLite streams), Freezed

---

## Task 1: Add `watchActiveGroup()` stream to GroupDao

**Files:**
- Modify: `lib/data/daos/group_dao.dart:18-20` (near existing `findActive()`)

**Step 1: Write the failing test**

Create a test that verifies `watchActiveGroup()` emits group data when an active group exists, and emits `null` when no active group exists.

```dart
// test/data/daos/group_dao_watch_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/tables/groups_table.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;
  late GroupDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = GroupDao(db);
  });

  tearDown(() => db.close());

  test('watchActiveGroup emits null when no active group', () async {
    final stream = dao.watchActiveGroup();
    expect(stream, emits(isNull));
  });

  test('watchActiveGroup emits group when active group inserted', () async {
    final stream = dao.watchActiveGroup();

    // First emission: null (no data yet)
    // Insert active group after a delay
    Future.delayed(const Duration(milliseconds: 50), () async {
      await dao.insert(GroupsCompanion.insert(
        groupId: 'g1',
        status: 'active',
        role: 'owner',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    });

    await expectLater(
      stream,
      emitsInOrder([
        isNull,
        isA<GroupData>().having((g) => g.groupId, 'groupId', 'g1'),
      ]),
    );
  });

  test('watchActiveGroup emits null when group deactivated', () async {
    // Insert active group first
    await dao.insert(GroupsCompanion.insert(
      groupId: 'g2',
      status: 'active',
      role: 'owner',
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));

    final stream = dao.watchActiveGroup();

    // First emission: active group
    // Then deactivate
    Future.delayed(const Duration(milliseconds: 50), () async {
      await dao.updateStatus('g2', 'inactive');
    });

    await expectLater(
      stream,
      emitsInOrder([
        isA<GroupData>().having((g) => g.groupId, 'groupId', 'g2'),
        isNull,
      ]),
    );
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/daos/group_dao_watch_test.dart -v`
Expected: FAIL — `watchActiveGroup` is not defined on GroupDao

**Step 3: Write minimal implementation**

Add the stream method to `group_dao.dart` right after `findActive()`:

```dart
// In GroupDao class, after findActive() method (line ~20):

Stream<GroupData?> watchActiveGroup() => (select(
  groups,
)..where((table) => table.status.equals('active'))).watchSingleOrNull();
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/daos/group_dao_watch_test.dart -v`
Expected: PASS (all 3 tests)

**Step 5: Commit**

```
git add lib/data/daos/group_dao.dart test/data/daos/group_dao_watch_test.dart
git commit -m "feat(data): add watchActiveGroup stream to GroupDao"
```

---

## Task 2: Add `watchActiveGroup()` to GroupRepository interface and impl

**Files:**
- Modify: `lib/features/family_sync/domain/repositories/group_repository.dart:32` (near `getActiveGroup()`)
- Modify: `lib/data/repositories/group_repository_impl.dart:99` (near `getActiveGroup()`)

**Step 1: Write the failing test**

```dart
// test/data/repositories/group_repository_impl_watch_test.dart
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/data/daos/group_dao.dart';
import 'package:home_pocket/data/daos/group_member_dao.dart';
import 'package:home_pocket/data/repositories/group_repository_impl.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';

void main() {
  late AppDatabase db;
  late GroupRepositoryImpl repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = GroupRepositoryImpl(
      groupDao: GroupDao(db),
      memberDao: GroupMemberDao(db),
    );
  });

  tearDown(() => db.close());

  test('watchActiveGroup emits null then GroupInfo when group activated', () async {
    final stream = repo.watchActiveGroup();

    Future.delayed(const Duration(milliseconds: 50), () async {
      await repo.savePendingGroup(
        groupId: 'g1',
        inviteCode: 'ABC123',
        inviteExpiresAt: DateTime.now().add(const Duration(hours: 1)),
        groupKey: 'key123',
      );
      await repo.confirmLocalGroup('g1');
    });

    await expectLater(
      stream,
      emitsInOrder([
        isNull,
        isA<GroupInfo>()
            .having((g) => g.groupId, 'groupId', 'g1')
            .having((g) => g.status, 'status', GroupStatus.active),
      ]),
    );
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/repositories/group_repository_impl_watch_test.dart -v`
Expected: FAIL — `watchActiveGroup` is not defined

**Step 3: Write minimal implementation**

Add to `group_repository.dart` interface (after `getActiveGroup` declaration):

```dart
Stream<GroupInfo?> watchActiveGroup();
```

Add to `group_repository_impl.dart` (after `getActiveGroup` method):

```dart
@override
Stream<GroupInfo?> watchActiveGroup() {
  return _groupDao.watchActiveGroup().asyncMap((groupData) async {
    if (groupData == null) return null;
    return _toGroupInfo(groupData);
  });
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/repositories/group_repository_impl_watch_test.dart -v`
Expected: PASS

**Step 5: Commit**

```
git add lib/features/family_sync/domain/repositories/group_repository.dart \
  lib/data/repositories/group_repository_impl.dart \
  test/data/repositories/group_repository_impl_watch_test.dart
git commit -m "feat(domain): add watchActiveGroup to GroupRepository"
```

---

## Task 3: Create `activeGroupProvider` Riverpod provider

**Files:**
- Create: `lib/features/family_sync/presentation/providers/active_group_provider.dart`

**Step 1: Write the provider**

```dart
// lib/features/family_sync/presentation/providers/active_group_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/group_info.dart';
import 'repository_providers.dart';

part 'active_group_provider.g.dart';

/// Watches the local database for an active group.
///
/// Emits [GroupInfo] when device is in an active group, null otherwise.
/// Pure local DB stream — zero network calls.
@Riverpod(keepAlive: true)
Stream<GroupInfo?> activeGroup(Ref ref) {
  return ref.watch(groupRepositoryProvider).watchActiveGroup();
}

/// Derived boolean: true when device is in an active group.
///
/// Convenient for conditional UI (banner visibility, mode badge text).
@riverpod
bool isGroupMode(Ref ref) {
  return ref.watch(activeGroupProvider).valueOrNull != null;
}
```

**Step 2: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `active_group_provider.g.dart` without errors

**Step 3: Write unit test**

```dart
// test/features/family_sync/presentation/providers/active_group_provider_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/active_group_provider.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository mockRepo;

  setUp(() {
    mockRepo = MockGroupRepository();
  });

  test('isGroupMode returns false when no active group', () async {
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(null));

    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    // Wait for stream to emit
    await container.read(activeGroupProvider.future);

    final isGroup = container.read(isGroupModeProvider);
    expect(isGroup, isFalse);
  });

  test('isGroupMode returns true when active group exists', () async {
    final group = GroupInfo(
      groupId: 'g1',
      status: GroupStatus.active,
      role: 'owner',
      members: [],
      createdAt: DateTime.now(),
    );
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(group));

    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    await container.read(activeGroupProvider.future);

    final isGroup = container.read(isGroupModeProvider);
    expect(isGroup, isTrue);
  });
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/presentation/providers/active_group_provider_test.dart -v`
Expected: PASS

**Step 5: Commit**

```
git add lib/features/family_sync/presentation/providers/active_group_provider.dart \
  lib/features/family_sync/presentation/providers/active_group_provider.g.dart \
  test/features/family_sync/presentation/providers/active_group_provider_test.dart
git commit -m "feat(providers): add activeGroupProvider for local group state"
```

---

## Task 4: Add `homeFamilyMode` l10n keys

**Files:**
- Modify: `lib/l10n/app_ja.arb:131` (after `homePersonalMode`)
- Modify: `lib/l10n/app_zh.arb:131` (after `homePersonalMode`)
- Modify: `lib/l10n/app_en.arb:386` (after `@homePersonalMode`)

**Step 1: Add l10n keys**

In `app_ja.arb`, after line 131 (`"homePersonalMode": "個人モード",`):
```json
  "homeFamilyMode": "家族モード",
```

In `app_zh.arb`, after line 131 (`"homePersonalMode": "个人模式",`):
```json
  "homeFamilyMode": "家庭模式",
```

In `app_en.arb`, after line 386 (`"@homePersonalMode": ...`):
```json
  "homeFamilyMode": "Family Mode",
  "@homeFamilyMode": { "description": "Mode badge for family/group mode" },
```

**Step 2: Run l10n generation**

Run: `flutter gen-l10n`
Expected: No errors. `lib/generated/app_localizations_*.dart` updated with `homeFamilyMode` getter.

**Step 3: Verify generated code**

Run: `grep -r 'homeFamilyMode' lib/generated/`
Expected: Appears in all 3 locale files + base class.

**Step 4: Commit**

```
git add lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/generated/
git commit -m "feat(l10n): add homeFamilyMode translations"
```

---

## Task 5: Update HomeScreen — conditional banner + mode badge

**Files:**
- Modify: `lib/features/home/presentation/screens/home_screen.dart`

**Step 1: Write the widget test**

```dart
// test/features/home/presentation/screens/home_screen_group_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/active_group_provider.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/home/presentation/screens/home_screen.dart';
import 'package:home_pocket/features/home/presentation/widgets/family_invite_banner.dart';

import '../../../../helpers/l10n_helpers.dart'; // adjust path to your l10n test helper

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository mockRepo;

  setUp(() {
    mockRepo = MockGroupRepository();
  });

  Widget buildSubject({required List<Override> overrides}) {
    return ProviderScope(
      overrides: overrides,
      child: const MaterialApp(
        localizationsDelegates: S.localizationsDelegates,
        supportedLocales: S.supportedLocales,
        locale: Locale('en'),
        home: Scaffold(
          body: HomeScreen(bookId: 'test-book'),
        ),
      ),
    );
  }

  testWidgets('shows FamilyInviteBanner when not in group', (tester) async {
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(null));

    await tester.pumpWidget(buildSubject(overrides: [
      groupRepositoryProvider.overrideWithValue(mockRepo),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(FamilyInviteBanner), findsOneWidget);
  });

  testWidgets('hides FamilyInviteBanner when in group', (tester) async {
    final group = GroupInfo(
      groupId: 'g1',
      status: GroupStatus.active,
      role: 'owner',
      members: [],
      createdAt: DateTime.now(),
    );
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(group));

    await tester.pumpWidget(buildSubject(overrides: [
      groupRepositoryProvider.overrideWithValue(mockRepo),
    ]));
    await tester.pumpAndSettle();

    expect(find.byType(FamilyInviteBanner), findsNothing);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/home/presentation/screens/home_screen_group_test.dart -v`
Expected: FAIL — banner shows in both cases (always visible currently)

**Step 3: Modify HomeScreen**

In `home_screen.dart`, make these changes:

**3a. Add imports** (top of file):
```dart
import '../../../family_sync/presentation/providers/active_group_provider.dart';
import '../../../family_sync/presentation/screens/pairing_screen.dart';
```

**3b. Watch isGroupMode** (inside `build()`, after line 42):
```dart
final isGroupMode = ref.watch(isGroupModeProvider);
```

**3c. Conditional banner** (replace lines 53-58):
```dart
// Family invite banner (only when not in a group)
if (!isGroupMode) ...[
  Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: FamilyInviteBanner(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PairingScreen(),
          ),
        );
      },
    ),
  ),
  const SizedBox(height: 16),
],
```

**3d. Dynamic mode badge** (replace line 256):
```dart
modeBadgeText: isGroupMode
    ? l10n.homeFamilyMode
    : l10n.homePersonalMode,
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/home/presentation/screens/home_screen_group_test.dart -v`
Expected: PASS

**Step 5: Commit**

```
git add lib/features/home/presentation/screens/home_screen.dart \
  test/features/home/presentation/screens/home_screen_group_test.dart
git commit -m "feat(home): hide invite banner in group mode, dynamic mode badge"
```

---

## Task 6: Update SyncStatusNotifier to derive from local DB

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/sync_providers.dart:73-82`

**Step 1: Write test**

```dart
// test/features/family_sync/presentation/providers/sync_status_from_db_test.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/sync_status.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/active_group_provider.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/sync_providers.dart';

class MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  late MockGroupRepository mockRepo;

  setUp(() {
    mockRepo = MockGroupRepository();
  });

  test('SyncStatusNotifier defaults to synced when active group exists', () async {
    final group = GroupInfo(
      groupId: 'g1',
      status: GroupStatus.active,
      role: 'owner',
      members: [],
      createdAt: DateTime.now(),
    );
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(group));

    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    await container.read(activeGroupProvider.future);
    final status = container.read(syncStatusNotifierProvider);
    expect(status, SyncStatus.synced);
  });

  test('SyncStatusNotifier defaults to unpaired when no active group', () async {
    when(() => mockRepo.watchActiveGroup())
        .thenAnswer((_) => Stream.value(null));

    final container = ProviderContainer(
      overrides: [groupRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    await container.read(activeGroupProvider.future);
    final status = container.read(syncStatusNotifierProvider);
    expect(status, SyncStatus.unpaired);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/providers/sync_status_from_db_test.dart -v`
Expected: FAIL — first test fails because SyncStatusNotifier always returns `unpaired`

**Step 3: Modify SyncStatusNotifier**

In `sync_providers.dart`, update the `SyncStatusNotifier` class:

```dart
import '../providers/active_group_provider.dart';

/// Current sync status state notifier.
///
/// Derives initial state from local DB via [activeGroupProvider].
/// Can be manually updated for transient states (syncing, offline, etc.).
@riverpod
class SyncStatusNotifier extends _$SyncStatusNotifier {
  @override
  SyncStatus build() {
    final group = ref.watch(activeGroupProvider).valueOrNull;
    return group != null ? SyncStatus.synced : SyncStatus.unpaired;
  }

  void updateStatus(SyncStatus status) {
    state = status;
  }
}
```

**Step 4: Run code generation + test**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Run: `flutter test test/features/family_sync/presentation/providers/sync_status_from_db_test.dart -v`
Expected: PASS

**Step 5: Commit**

```
git add lib/features/family_sync/presentation/providers/sync_providers.dart \
  test/features/family_sync/presentation/providers/sync_status_from_db_test.dart
git commit -m "feat(sync): derive SyncStatusNotifier initial state from local DB"
```

---

## Task 7: Simplify FamilySyncSettingsSection to use activeGroupProvider

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`

**Step 1: Modify the widget**

Replace the current `FutureBuilder` approach with provider-based approach:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/active_group_provider.dart';
import '../providers/group_providers.dart';
import '../providers/sync_providers.dart';
import '../screens/group_management_screen.dart';
import '../screens/pairing_screen.dart';
import 'sync_status_badge.dart';

/// Settings section for Family Sync.
///
/// Shows current sync status and navigates to pairing or management screens.
class FamilySyncSettingsSection extends ConsumerWidget {
  const FamilySyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusNotifierProvider);
    final l10n = S.of(context);
    final activeGroup = ref.watch(activeGroupProvider).valueOrNull;

    final subtitle = activeGroup != null
        ? l10n.familySyncMemberCount(activeGroup.members.length)
        : _statusDescription(l10n, syncStatus);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            l10n.familySync,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.sync),
          title: Text(l10n.familySync),
          subtitle: Text(subtitle),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SyncStatusBadge(status: syncStatus, compact: true),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
          onTap: () => _navigate(context, ref, syncStatus),
        ),
      ],
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
  ) async {
    final localGroup = ref.read(activeGroupProvider).valueOrNull;
    if (!context.mounted) return;

    // If local DB has active group, go directly to management (no network)
    if (localGroup != null || status != SyncStatus.unpaired) {
      if (localGroup != null) {
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => GroupManagementScreen(groupId: localGroup?.groupId),
        ),
      );
      return;
    }

    // No local group — check server (only network call in this flow)
    final l10n = S.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.familySyncCheckingGroup)),
            ],
          ),
        ),
      ),
    );

    final result = await ref.read(checkGroupUseCaseProvider).execute();
    if (!context.mounted) return;

    Navigator.of(context).pop();

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PairingScreen()),
        );
      case CheckGroupError(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.familySyncCheckFailed(message))),
        );
        await Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PairingScreen()),
        );
    }
  }

  String _statusDescription(S l10n, SyncStatus status) {
    switch (status) {
      case SyncStatus.synced:
        return l10n.familySyncStatusSynced;
      case SyncStatus.syncing:
        return l10n.familySyncStatusSyncing;
      case SyncStatus.offline:
        return l10n.familySyncStatusOffline;
      case SyncStatus.syncError:
        return l10n.familySyncStatusError;
      case SyncStatus.pairing:
        return l10n.familySyncStatusPairing;
      case SyncStatus.unpaired:
        return l10n.familySyncStatusUnpaired;
    }
  }
}
```

Key changes from original:
- Removed `FutureBuilder` + `ref.read(groupRepositoryProvider).getActiveGroup()`
- Now uses `ref.watch(activeGroupProvider).valueOrNull` (cached, reactive)
- `_navigate()` uses `ref.read(activeGroupProvider).valueOrNull` instead of async DB call
- Removed import for `repository_providers.dart` (no longer directly querying repo)

**Step 2: Run existing tests + analyzer**

Run: `flutter analyze lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`
Expected: No issues

**Step 3: Commit**

```
git add lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart
git commit -m "refactor(settings): use activeGroupProvider instead of async DB query"
```

---

## Task 8: Final verification

**Step 1: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: No errors

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Run format**

Run: `dart format .`
Expected: No formatting changes needed

**Step 5: Commit any remaining changes**

If code generation produced updated `.g.dart` files not yet committed:
```
git add -A
git commit -m "chore: regenerate code after group-aware home screen changes"
```

---

## Data Flow Summary

```
配对成功 → UseCase 写入 DB (status: active)
                    ↓
          GroupDao.watchActiveGroup() 推送
                    ↓
          GroupRepositoryImpl.watchActiveGroup() 转换为 GroupInfo
                    ↓
          activeGroupProvider (Stream) 更新
            ↓                    ↓
    isGroupModeProvider     SyncStatusNotifier
    (bool)                  (unpaired → synced)
       ↓                        ↓
  HomeScreen                Settings Section
  - 隐藏 banner             - 显示成员数
  - badge → 家族モード       - 直接进管理页(无联网)

Group 被关闭 → Push 通知 → deactivateGroup() → DB status: inactive
                    ↓
          watchActiveGroup() emits null
                    ↓
          activeGroupProvider → null
            ↓                    ↓
    isGroupModeProvider=false  SyncStatusNotifier=unpaired
       ↓                        ↓
  HomeScreen                Settings Section
  - 显示 banner              - 显示"未配对"
  - badge → 個人モード        - 联网检查流程
```

## Files Changed Summary

| File | Action | Purpose |
|------|--------|---------|
| `lib/data/daos/group_dao.dart` | Modify | Add `watchActiveGroup()` stream |
| `lib/features/family_sync/domain/repositories/group_repository.dart` | Modify | Add `watchActiveGroup()` to interface |
| `lib/data/repositories/group_repository_impl.dart` | Modify | Implement `watchActiveGroup()` |
| `lib/features/family_sync/presentation/providers/active_group_provider.dart` | Create | New provider for global group state |
| `lib/l10n/app_ja.arb` | Modify | Add `homeFamilyMode` |
| `lib/l10n/app_zh.arb` | Modify | Add `homeFamilyMode` |
| `lib/l10n/app_en.arb` | Modify | Add `homeFamilyMode` |
| `lib/features/home/presentation/screens/home_screen.dart` | Modify | Conditional banner + mode badge |
| `lib/features/family_sync/presentation/providers/sync_providers.dart` | Modify | Derive initial state from DB |
| `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart` | Modify | Use activeGroupProvider |
