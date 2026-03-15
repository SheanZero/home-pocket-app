# Group Check Before Pairing - Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** When user taps "Family Sync" in settings, check server via `GET /api/v1/group/check` to see if the device is already in a group. If yes, skip pairing and show group management with group info and members. Also, when the WaitingApprovalScreen receives a `memberConfirmed` push notification, verify group membership via the same API before navigating to GroupManagementScreen.

**Architecture:** Add `checkGroup()` to `RelayApiClient`, create `CheckGroupUseCase` that orchestrates the check + local DB sync, modify `FamilySyncSettingsSection._navigate()` to call the use case before navigating, and modify `WaitingApprovalScreen._listenForSyncEvents()` to call `CheckGroupUseCase` on `memberConfirmed` event before navigating. If the device is already in a group on the server but not locally, fetch full group status and persist it before showing `GroupManagementScreen`.

**Tech Stack:** Flutter, Riverpod, Freezed, Drift, RelayApiClient (HTTP + Ed25519 signing)

---

## Task 1: Add `checkGroup()` to RelayApiClient

**Files:**
- Modify: `lib/infrastructure/sync/relay_api_client.dart:114-168` (Groups section)
- Test: `test/infrastructure/sync/relay_api_client_test.dart`

**Step 1: Write the failing test**

```dart
// In test/infrastructure/sync/relay_api_client_test.dart
// Add to the existing test file's group tests section

test('checkGroup returns groupExisted=true with groupId', () async {
  mockHttpClient.stubGet(
    '/group/check',
    response: '{"groupExisted": true, "groupId": "550e8400-e29b-41d4-a716-446655440000"}',
  );

  final result = await apiClient.checkGroup();

  expect(result['groupExisted'], true);
  expect(result['groupId'], '550e8400-e29b-41d4-a716-446655440000');
});

test('checkGroup returns groupExisted=false', () async {
  mockHttpClient.stubGet(
    '/group/check',
    response: '{"groupExisted": false}',
  );

  final result = await apiClient.checkGroup();

  expect(result['groupExisted'], false);
  expect(result['groupId'], isNull);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/infrastructure/sync/relay_api_client_test.dart -v`
Expected: FAIL with "method 'checkGroup' not found"

**Step 3: Write minimal implementation**

Add to `lib/infrastructure/sync/relay_api_client.dart`, in the Groups section (after `createGroup()` around line 119):

```dart
/// Check if this device belongs to a valid group (active with ≥2 members).
///
/// Returns: {groupExisted: bool, groupId?: string}
Future<Map<String, dynamic>> checkGroup() async {
  final response = await _get('/group/check');
  return _parseResponse(response);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/infrastructure/sync/relay_api_client_test.dart -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/infrastructure/sync/relay_api_client.dart test/infrastructure/sync/relay_api_client_test.dart
git commit -m "feat(family_sync): add checkGroup method to RelayApiClient"
```

---

## Task 2: Create `CheckGroupUseCase`

**Files:**
- Create: `lib/features/family_sync/use_cases/check_group_use_case.dart`
- Test: `test/features/family_sync/use_cases/check_group_use_case_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/family_sync/use_cases/check_group_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:home_pocket/features/family_sync/use_cases/check_group_use_case.dart';
import 'package:home_pocket/features/family_sync/domain/repositories/group_repository.dart';
import 'package:home_pocket/infrastructure/sync/relay_api_client.dart';
import 'package:home_pocket/infrastructure/crypto/services/key_manager.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_info.dart';
import 'package:home_pocket/features/family_sync/domain/models/group_member.dart';

class MockRelayApiClient extends Mock implements RelayApiClient {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockKeyManager extends Mock implements KeyManager {}

void main() {
  late CheckGroupUseCase useCase;
  late MockRelayApiClient mockApiClient;
  late MockGroupRepository mockGroupRepository;
  late MockKeyManager mockKeyManager;

  setUp(() {
    mockApiClient = MockRelayApiClient();
    mockGroupRepository = MockGroupRepository();
    mockKeyManager = MockKeyManager();
    useCase = CheckGroupUseCase(
      apiClient: mockApiClient,
      groupRepository: mockGroupRepository,
      keyManager: mockKeyManager,
    );
  });

  group('CheckGroupUseCase', () {
    test('returns NotInGroup when server says groupExisted=false', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(() => mockKeyManager.getPublicKeyBase64()).thenAnswer((_) async => 'pubkey');
      when(() => mockKeyManager.getDeviceName()).thenAnswer((_) async => 'iPhone');
      when(() => mockApiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApiClient.checkGroup()).thenAnswer(
        (_) async => {'groupExisted': false},
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupNotInGroup>());
    });

    test('returns InGroup with group info when server says groupExisted=true', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(() => mockKeyManager.getPublicKeyBase64()).thenAnswer((_) async => 'pubkey');
      when(() => mockKeyManager.getDeviceName()).thenAnswer((_) async => 'iPhone');
      when(() => mockApiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApiClient.checkGroup()).thenAnswer(
        (_) async => {
          'groupExisted': true,
          'groupId': 'group-123',
        },
      );
      when(() => mockApiClient.getGroupStatus('group-123')).thenAnswer(
        (_) async => {
          'groupId': 'group-123',
          'status': 'active',
          'inviteCode': '123456',
          'inviteExpiresAt': 1709654400,
          'members': [
            {
              'deviceId': 'device-1',
              'publicKey': 'key1',
              'deviceName': 'iPhone',
              'role': 'owner',
              'status': 'active',
            },
            {
              'deviceId': 'device-2',
              'publicKey': 'key2',
              'deviceName': 'iPad',
              'role': 'member',
              'status': 'active',
            },
          ],
        },
      );
      when(() => mockGroupRepository.getGroupById('group-123'))
          .thenAnswer((_) async => null);
      when(() => mockGroupRepository.savePendingGroup(
        groupId: any(named: 'groupId'),
        inviteCode: any(named: 'inviteCode'),
        inviteExpiresAt: any(named: 'inviteExpiresAt'),
      )).thenAnswer((_) async {});
      when(() => mockGroupRepository.confirmLocalGroup(
        groupId: any(named: 'groupId'),
      )).thenAnswer((_) async {});
      when(() => mockGroupRepository.updateMembers(
        groupId: any(named: 'groupId'),
        members: any(named: 'members'),
      )).thenAnswer((_) async {});

      final result = await useCase.execute();

      expect(result, isA<CheckGroupInGroup>());
      final inGroup = result as CheckGroupInGroup;
      expect(inGroup.groupId, 'group-123');
    });

    test('returns Error on API failure', () async {
      when(() => mockKeyManager.getDeviceId()).thenAnswer((_) async => 'device-1');
      when(() => mockKeyManager.getPublicKeyBase64()).thenAnswer((_) async => 'pubkey');
      when(() => mockKeyManager.getDeviceName()).thenAnswer((_) async => 'iPhone');
      when(() => mockApiClient.registerDevice(
        deviceId: any(named: 'deviceId'),
        publicKey: any(named: 'publicKey'),
        deviceName: any(named: 'deviceName'),
        platform: any(named: 'platform'),
      )).thenAnswer((_) async => {});
      when(() => mockApiClient.checkGroup()).thenThrow(
        const RelayApiException(statusCode: 500, message: 'Server error'),
      );

      final result = await useCase.execute();

      expect(result, isA<CheckGroupError>());
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/use_cases/check_group_use_case_test.dart -v`
Expected: FAIL with "file not found"

**Step 3: Write minimal implementation**

```dart
// lib/features/family_sync/use_cases/check_group_use_case.dart
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../infrastructure/crypto/services/key_manager.dart';
import '../../../infrastructure/sync/relay_api_client.dart';
import '../domain/models/group_member.dart';
import '../domain/repositories/group_repository.dart';

/// Result of checking if device is already in a group.
sealed class CheckGroupResult {}

class CheckGroupInGroup extends CheckGroupResult {
  CheckGroupInGroup({required this.groupId});
  final String groupId;
}

class CheckGroupNotInGroup extends CheckGroupResult {}

class CheckGroupError extends CheckGroupResult {
  CheckGroupError({required this.message});
  final String message;
}

/// Checks if this device is already in a valid group on the server.
///
/// If yes, fetches group status and syncs to local DB.
/// If no, returns NotInGroup so the UI can show the pairing screen.
class CheckGroupUseCase {
  CheckGroupUseCase({
    required RelayApiClient apiClient,
    required GroupRepository groupRepository,
    required KeyManager keyManager,
  }) : _apiClient = apiClient,
       _groupRepository = groupRepository,
       _keyManager = keyManager;

  final RelayApiClient _apiClient;
  final GroupRepository _groupRepository;
  final KeyManager _keyManager;

  Future<CheckGroupResult> execute() async {
    try {
      // Ensure device is registered before checking
      final deviceId = await _keyManager.getDeviceId();
      if (deviceId == null) {
        return CheckGroupNotInGroup();
      }
      final publicKey = await _keyManager.getPublicKeyBase64();
      final deviceName = await _keyManager.getDeviceName();
      await _apiClient.registerDevice(
        deviceId: deviceId,
        publicKey: publicKey,
        deviceName: deviceName ?? deviceId,
        platform: Platform.isIOS ? 'ios' : 'android',
      );

      // Call GET /api/v1/group/check
      final checkResult = await _apiClient.checkGroup();
      final groupExisted = checkResult['groupExisted'] as bool? ?? false;

      if (!groupExisted) {
        return CheckGroupNotInGroup();
      }

      final groupId = checkResult['groupId'] as String;

      // Fetch full group status from server
      final statusResult = await _apiClient.getGroupStatus(groupId);

      // Parse members from server response
      final membersJson = statusResult['members'] as List<dynamic>? ?? [];
      final members = membersJson
          .map((m) => GroupMember.fromJson(m as Map<String, dynamic>))
          .toList();

      // Sync to local DB if not already there
      final existingGroup = await _groupRepository.getGroupById(groupId);
      if (existingGroup == null) {
        // Save as pending then activate
        final inviteCode = statusResult['inviteCode'] as String?;
        final inviteExpiresAt = statusResult['inviteExpiresAt'] as int?;
        await _groupRepository.savePendingGroup(
          groupId: groupId,
          inviteCode: inviteCode ?? '',
          inviteExpiresAt: inviteExpiresAt != null
              ? DateTime.fromMillisecondsSinceEpoch(inviteExpiresAt * 1000)
              : DateTime.now().add(const Duration(hours: 24)),
        );
        await _groupRepository.confirmLocalGroup(groupId: groupId);
      }

      // Update members list from server
      await _groupRepository.updateMembers(
        groupId: groupId,
        members: members,
      );

      return CheckGroupInGroup(groupId: groupId);
    } on RelayApiException catch (e) {
      if (kDebugMode) {
        debugPrint('[CheckGroupUseCase] API error: $e');
      }
      return CheckGroupError(message: e.message);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CheckGroupUseCase] Unexpected error: $e');
      }
      return CheckGroupError(message: e.toString());
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/features/family_sync/use_cases/check_group_use_case_test.dart -v`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/features/family_sync/use_cases/check_group_use_case.dart test/features/family_sync/use_cases/check_group_use_case_test.dart
git commit -m "feat(family_sync): add CheckGroupUseCase to check server group membership"
```

---

## Task 3: Wire `CheckGroupUseCase` provider

**Files:**
- Modify: `lib/features/family_sync/presentation/providers/group_providers.dart`

**Step 1: Write the failing test**

No separate test needed — provider wiring is verified by Task 4's integration test.

**Step 2: Add the provider**

Add to `lib/features/family_sync/presentation/providers/group_providers.dart`:

```dart
import '../../use_cases/check_group_use_case.dart';

// Add after existing provider definitions:

final checkGroupUseCaseProvider = Provider<CheckGroupUseCase>((ref) {
  return CheckGroupUseCase(
    apiClient: ref.watch(relayApiClientProvider),
    groupRepository: ref.watch(groupRepositoryProvider),
    keyManager: ref.watch(keyManagerProvider),
  );
});
```

**Step 3: Commit**

```bash
git add lib/features/family_sync/presentation/providers/group_providers.dart
git commit -m "feat(family_sync): wire CheckGroupUseCase provider"
```

---

## Task 4: Add l10n strings for group check

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`

**Step 1: Add l10n keys to all 3 ARB files**

Add to `lib/l10n/app_en.arb` (before the closing `}`):

```json
  "familySyncCheckingGroup": "Checking group status...",
  "@familySyncCheckingGroup": {
    "description": "Loading text while checking if device is in a group"
  },
  "familySyncCheckFailed": "Could not check group status: {message}",
  "@familySyncCheckFailed": {
    "description": "Error when group check fails",
    "placeholders": {
      "message": {
        "type": "String"
      }
    }
  }
```

Add to `lib/l10n/app_ja.arb`:

```json
  "familySyncCheckingGroup": "グループ状況を確認中...",
  "familySyncCheckFailed": "グループ状況を確認できません: {message}"
```

Add to `lib/l10n/app_zh.arb`:

```json
  "familySyncCheckingGroup": "正在检查群组状态...",
  "familySyncCheckFailed": "无法检查群组状态: {message}"
```

**Step 2: Regenerate l10n**

Run: `flutter gen-l10n`
Expected: Success, generated files updated

**Step 3: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/generated/
git commit -m "feat(i18n): add group check l10n strings for ja/zh/en"
```

---

## Task 5: Modify `FamilySyncSettingsSection` to check group before navigating

**Files:**
- Modify: `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`
- Test: `test/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart`

**Step 1: Write the failing test**

```dart
// test/features/family_sync/presentation/widgets/family_sync_settings_section_test.dart
// Add test for the new navigation behavior

test('navigates to GroupManagementScreen when server check returns group exists', () async {
  // Mock checkGroupUseCaseProvider to return InGroup
  when(() => mockCheckGroupUseCase.execute()).thenAnswer(
    (_) async => CheckGroupInGroup(groupId: 'group-123'),
  );

  await tester.tap(find.text('Family Sync'));
  await tester.pumpAndSettle();

  // Should show loading indicator first, then navigate to GroupManagementScreen
  expect(find.byType(GroupManagementScreen), findsOneWidget);
});

test('navigates to PairingScreen when server check returns not in group', () async {
  when(() => mockCheckGroupUseCase.execute()).thenAnswer(
    (_) async => CheckGroupNotInGroup(),
  );

  await tester.tap(find.text('Family Sync'));
  await tester.pumpAndSettle();

  expect(find.byType(PairingScreen), findsOneWidget);
});
```

**Step 2: Rewrite `FamilySyncSettingsSection`**

Replace the full content of `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../generated/app_localizations.dart';
import '../../domain/models/sync_status.dart';
import '../../use_cases/check_group_use_case.dart';
import '../providers/group_providers.dart';
import '../providers/repository_providers.dart';
import '../providers/sync_providers.dart';
import '../screens/group_management_screen.dart';
import '../screens/pairing_screen.dart';
import 'sync_status_badge.dart';

/// Settings section for Family Sync.
///
/// Shows current sync status and navigates to pairing or management screens.
/// When status is unpaired, checks the server first to see if the device
/// is already in a group before showing the pairing screen.
class FamilySyncSettingsSection extends ConsumerWidget {
  const FamilySyncSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncStatus = ref.watch(syncStatusNotifierProvider);
    final l10n = S.of(context);
    final groupFuture = ref.read(groupRepositoryProvider).getActiveGroup();

    return FutureBuilder(
      future: groupFuture,
      builder: (context, snapshot) {
        final group = snapshot.data;
        final subtitle = group != null
            ? l10n.familySyncMemberCount(group.members.length)
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
      },
    );
  }

  Future<void> _navigate(
    BuildContext context,
    WidgetRef ref,
    SyncStatus status,
  ) async {
    // If already paired, go directly to management screen
    if (status != SyncStatus.unpaired) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const GroupManagementScreen()),
      );
      return;
    }

    // Show loading dialog while checking server
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

    // Check server for existing group
    final useCase = ref.read(checkGroupUseCaseProvider);
    final result = await useCase.execute();

    // Dismiss loading dialog
    if (!context.mounted) return;
    Navigator.of(context).pop();

    switch (result) {
      case CheckGroupInGroup(:final groupId):
        // Device is already in a group — update status and go to management
        ref
            .read(syncStatusNotifierProvider.notifier)
            .updateStatus(SyncStatus.synced);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => GroupManagementScreen(groupId: groupId),
          ),
        );
      case CheckGroupNotInGroup():
        // Not in any group — show pairing screen
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const PairingScreen()),
        );
      case CheckGroupError(:final message):
        // Check failed — show error snackbar and still allow pairing
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.familySyncCheckFailed(message))),
        );
        Navigator.of(context).push(
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

**Key changes from original:**
1. `_navigate` is now `async` — calls `CheckGroupUseCase.execute()` when `status == unpaired`
2. Shows a loading dialog while checking the server
3. If `CheckGroupInGroup` → updates sync status to `synced` and navigates to `GroupManagementScreen(groupId: groupId)`
4. If `CheckGroupNotInGroup` → navigates to `PairingScreen` as before
5. If `CheckGroupError` → shows error snackbar but still navigates to `PairingScreen` (graceful degradation)

**Step 3: Run tests**

Run: `flutter test test/features/family_sync/ -v`
Expected: PASS

**Step 4: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart
git commit -m "feat(family_sync): check server group before showing pairing screen"
```

---

## Task 6: Modify `WaitingApprovalScreen` to verify group via API on `memberConfirmed`

**Files:**
- Modify: `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
- Test: `test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`

**Context:** Currently, `WaitingApprovalScreen` listens for the `memberConfirmed` event and navigates directly to `GroupManagementScreen` without verifying with the server. This task adds a server-side check via `CheckGroupUseCase` before navigating, ensuring the group is truly active with members synced to local DB.

**Current code** (`waiting_approval_screen.dart:38-49`):
```dart
void _listenForSyncEvents() {
  final syncTrigger = ref.read(syncTriggerServiceProvider);
  _eventSubscription = syncTrigger.events.listen((event) {
    if (!mounted) return;
    if (event.type != SyncTriggerEventType.memberConfirmed) return;
    if (event.groupId != null && event.groupId != widget.groupId) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => GroupManagementScreen(groupId: widget.groupId),
      ),
    );
  });
}
```

**Step 1: Write the failing test**

```dart
// test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart
// Add test for the new behavior

test('calls CheckGroupUseCase on memberConfirmed and navigates to GroupManagementScreen on success', () async {
  when(() => mockCheckGroupUseCase.execute()).thenAnswer(
    (_) async => CheckGroupInGroup(groupId: 'group-123'),
  );

  // Simulate memberConfirmed event
  syncTriggerEvents.add(
    const SyncTriggerEvent.memberConfirmed(groupId: 'group-123'),
  );
  await tester.pumpAndSettle();

  verify(() => mockCheckGroupUseCase.execute()).called(1);
  expect(find.byType(GroupManagementScreen), findsOneWidget);
});

test('shows error snackbar and stays on screen when CheckGroupUseCase fails', () async {
  when(() => mockCheckGroupUseCase.execute()).thenAnswer(
    (_) async => CheckGroupError(message: 'Network error'),
  );

  syncTriggerEvents.add(
    const SyncTriggerEvent.memberConfirmed(groupId: 'group-123'),
  );
  await tester.pumpAndSettle();

  expect(find.byType(WaitingApprovalScreen), findsOneWidget);
  expect(find.text('Network error'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/family_sync/presentation/screens/waiting_approval_screen_test.dart -v`
Expected: FAIL

**Step 3: Modify `WaitingApprovalScreen`**

In `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`:

1. Add imports:
```dart
import '../../use_cases/check_group_use_case.dart';
import '../../domain/models/sync_status.dart';
import '../providers/group_providers.dart';
import '../providers/sync_providers.dart';
```

2. Replace the `_listenForSyncEvents` method:

```dart
void _listenForSyncEvents() {
  final syncTrigger = ref.read(syncTriggerServiceProvider);
  _eventSubscription = syncTrigger.events.listen((event) {
    if (!mounted) return;
    if (event.type != SyncTriggerEventType.memberConfirmed) return;
    if (event.groupId != null && event.groupId != widget.groupId) return;

    _verifyGroupAndNavigate();
  });
}

Future<void> _verifyGroupAndNavigate() async {
  // Show loading state
  setState(() => _isLoading = true);

  final useCase = ref.read(checkGroupUseCaseProvider);
  final result = await useCase.execute();

  if (!mounted) return;

  switch (result) {
    case CheckGroupInGroup(:final groupId):
      ref
          .read(syncStatusNotifierProvider.notifier)
          .updateStatus(SyncStatus.synced);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => GroupManagementScreen(groupId: groupId),
        ),
      );
    case CheckGroupNotInGroup():
      // Server says not in group — unexpected after memberConfirmed
      // Stay on screen and show message
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(S.of(context).familySyncCheckFailed(
            'Group not found on server',
          )),
        ),
      );
    case CheckGroupError(:final message):
      // API failed — stay on screen and show error, allow manual retry
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).familySyncCheckFailed(message))),
      );
  }
}
```

3. Add a manual "Check Status" button by updating the refresh button in the AppBar to also call `_verifyGroupAndNavigate()`:

```dart
// In build(), update the refresh IconButton's onPressed:
IconButton(
  onPressed: () async {
    await _loadGroup();
    if (mounted) await _verifyGroupAndNavigate();
  },
  icon: const Icon(Icons.refresh),
  tooltip: l10n.refresh,
),
```

**Key changes from original:**
1. `memberConfirmed` event → calls `_verifyGroupAndNavigate()` instead of direct navigation
2. `_verifyGroupAndNavigate()` calls `CheckGroupUseCase.execute()` to verify server state
3. If `CheckGroupInGroup` → updates sync status to `synced` and navigates to `GroupManagementScreen`
4. If `CheckGroupNotInGroup` or `CheckGroupError` → stays on screen with error snackbar (graceful degradation)
5. Refresh button also triggers `_verifyGroupAndNavigate()` for manual retry

**Step 4: Run tests**

Run: `flutter test test/features/family_sync/ -v`
Expected: PASS

**Step 5: Run analyzer**

Run: `flutter analyze`
Expected: 0 issues

**Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/screens/waiting_approval_screen.dart
git commit -m "feat(family_sync): verify group via API on memberConfirmed before navigating"
```

---

## Task 7: Run full verification

**Step 1: Run build_runner**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: SUCCESS

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found

**Step 3: Run all tests**

Run: `flutter test`
Expected: All tests pass

**Step 4: Manual verification checklist**

Flow 1 — Settings entry:
- [ ] Tap "Family Sync" in settings when unpaired → loading dialog → device in group on server → GroupManagementScreen shows with group info + members
- [ ] Tap "Family Sync" in settings when unpaired → loading dialog → NOT in group → PairingScreen shows
- [ ] Tap "Family Sync" in settings when already synced → GroupManagementScreen shows directly (no server check)
- [ ] Server check fails → error snackbar shown → PairingScreen still shown (graceful degradation)

Flow 2 — Waiting approval:
- [ ] On WaitingApprovalScreen, receive `memberConfirmed` push → loading state → API check succeeds → GroupManagementScreen shows with synced members
- [ ] On WaitingApprovalScreen, receive `memberConfirmed` push → loading state → API check fails → stays on screen with error snackbar
- [ ] On WaitingApprovalScreen, tap refresh → calls API check → if in group → GroupManagementScreen

**Step 5: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix(family_sync): address review feedback for group check"
```

---

## Summary of Changes

| File | Action | Description |
|------|--------|-------------|
| `lib/infrastructure/sync/relay_api_client.dart` | Modify | Add `checkGroup()` method |
| `lib/features/family_sync/use_cases/check_group_use_case.dart` | Create | Use case: check server → fetch status → sync local DB |
| `lib/features/family_sync/presentation/providers/group_providers.dart` | Modify | Add `checkGroupUseCaseProvider` |
| `lib/features/family_sync/presentation/widgets/family_sync_settings_section.dart` | Modify | Call `CheckGroupUseCase` before navigation when unpaired |
| `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart` | Modify | Call `CheckGroupUseCase` on `memberConfirmed` before navigating |
| `lib/l10n/app_en.arb` | Modify | Add `familySyncCheckingGroup`, `familySyncCheckFailed` |
| `lib/l10n/app_ja.arb` | Modify | Add Japanese translations |
| `lib/l10n/app_zh.arb` | Modify | Add Chinese translations |
| `test/infrastructure/sync/relay_api_client_test.dart` | Modify | Add tests for `checkGroup()` |
| `test/features/family_sync/use_cases/check_group_use_case_test.dart` | Create | Unit tests for `CheckGroupUseCase` |

## Flow Diagrams

### Flow 1: Settings → Family Sync

```
Settings → tap "Family Sync"
  ├── status != unpaired → GroupManagementScreen (direct)
  └── status == unpaired
      ├── show loading dialog
      ├── call GET /api/v1/group/check
      ├── dismiss loading dialog
      ├── groupExisted == true
      │   ├── GET /api/v1/group/{id}/status (fetch members)
      │   ├── sync to local DB
      │   ├── update syncStatus → synced
      │   └── → GroupManagementScreen(groupId)
      ├── groupExisted == false
      │   └── → PairingScreen
      └── error
          ├── show error snackbar
          └── → PairingScreen (graceful degradation)
```

### Flow 2: WaitingApprovalScreen → memberConfirmed

```
WaitingApprovalScreen (listening for events)
  └── receive memberConfirmed push notification
      ├── show loading state
      ├── call CheckGroupUseCase.execute()
      │   ├── GET /api/v1/group/check
      │   ├── GET /api/v1/group/{id}/status (fetch members)
      │   └── sync to local DB
      ├── CheckGroupInGroup
      │   ├── update syncStatus → synced
      │   └── → GroupManagementScreen(groupId) (pushReplacement)
      ├── CheckGroupNotInGroup
      │   ├── stay on WaitingApprovalScreen
      │   └── show error snackbar
      └── CheckGroupError
          ├── stay on WaitingApprovalScreen
          └── show error snackbar (allow manual retry via refresh)
```
