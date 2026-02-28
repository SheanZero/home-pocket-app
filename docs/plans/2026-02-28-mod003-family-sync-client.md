# MOD-003 Family Sync - Client Implementation Plan (Flutter)

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the Flutter client side of server-mediated family sync with E2EE, enabling remote device pairing and encrypted transaction synchronization.

**Scope:** Flutter/Dart client only. Server is developed as a separate project (see `2026-02-28-mod003-family-sync-server.md`).

**Prerequisites:**
- Server API available at `https://dev-sync.happypocket.app/api/v1` (or local mock)
- MOD-006 (Security) and MOD-001 (Basic Accounting) implemented

**Tech Stack:** Flutter/Dart, Drift, Riverpod, Freezed, NaCl box (X25519-XSalsa20-Poly1305)

**Design Docs:**
- Client: `docs/arch/02-module-specs/MOD-003_FamilySync.md` (v3.0)
- Server API Contract: `docs/arch/server/SERVER-001_SyncRelay.md`
- Relay Design: `docs/plans/2026-02-28-mod003-family-sync-server-relay-design.md`

---

## Server API Contract (Reference)

The client communicates with the relay server via these endpoints:

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/api/v1/device/register` | None | Register device + public key |
| PUT | `/api/v1/device/push-token` | Ed25519 | Update push token |
| POST | `/api/v1/pair/create` | Ed25519 | Create pairing request |
| POST | `/api/v1/pair/join` | Ed25519 | Join with short code |
| POST | `/api/v1/pair/confirm` | Ed25519 | Confirm pairing |
| GET | `/api/v1/pair/status/{pairId}` | Ed25519 | Poll pairing status |
| DELETE | `/api/v1/pair/{pairId}` | Ed25519 | Unpair devices |
| POST | `/api/v1/sync/push` | Ed25519 | Push encrypted CRDT ops |
| GET | `/api/v1/sync/pull?since={cursor}` | Ed25519 | Pull pending messages |
| POST | `/api/v1/sync/ack` | Ed25519 | ACK received messages |

**Authentication:** `Authorization: Ed25519 <deviceId>:<timestamp>:<signature>`
- Signature = `sign("<method>:<path>:<timestamp>:<SHA256(body)>", privateKey)`

---

## Phase C1: Domain Layer (Models + Repository Interfaces)

### Task 1: Domain models (Freezed)

**Files:**
- Create: `lib/features/family_sync/domain/models/paired_device.dart`
- Create: `lib/features/family_sync/domain/models/sync_message.dart`
- Create: `lib/features/family_sync/domain/models/sync_status.dart`

**Step 1: Write paired_device.dart**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'paired_device.freezed.dart';
part 'paired_device.g.dart';

enum PairStatus { pending, confirming, active, inactive }

@freezed
abstract class PairedDevice with _$PairedDevice {
  const factory PairedDevice({
    required String pairId,
    required String bookId,
    String? partnerDeviceId,     // null during 'pending' state
    String? partnerPublicKey,    // null during 'pending' state
    String? partnerDeviceName,   // null during 'pending' state
    required PairStatus status,
    String? pairCode,
    DateTime? expiresAt,         // pair code expiry
    required DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  }) = _PairedDevice;

  factory PairedDevice.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceFromJson(json);
}
```

**Step 2: Write sync_message.dart and sync_status.dart**

Follow same Freezed pattern. SyncStatus is a plain enum (unpaired, pairing, synced, syncing, syncError, offline).

**Step 3: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`
Expected: Generates `.freezed.dart` and `.g.dart` files

**Step 4: Commit**

```bash
git add lib/features/family_sync/domain/
git commit -m "feat(sync): add domain models for family sync"
```

---

### Task 2: Repository interfaces

**Files:**
- Create: `lib/features/family_sync/domain/repositories/pair_repository.dart`
- Create: `lib/features/family_sync/domain/repositories/sync_repository.dart`

**Step 1: Write abstract interfaces**

See MOD-003 v3.0 "客户端 Repository 接口" section for exact method signatures.

**Step 2: Commit**

```bash
git add lib/features/family_sync/domain/repositories/
git commit -m "feat(sync): add repository interfaces for pair and sync"
```

---

## Phase C2: Data Layer (Drift Tables, DAOs, Repository Implementations)

### Task 3: Drift tables

**Files:**
- Create: `lib/data/tables/paired_devices_table.dart`
- Create: `lib/data/tables/sync_queue_table.dart`
- Modify: `lib/data/app_database.dart` (add tables, bump schema version)

**Step 1: Write paired_devices_table.dart**

Follow existing pattern in `transactions_table.dart`. Use `TextColumn`, `IntColumn`, `@DataClassName('PairedDeviceData')`. Primary key: `{pairId}`. Indices: `idx_paired_devices_status`, `idx_paired_devices_book`. Use Symbol syntax `{#status}`. IMPORTANT: `partnerDeviceId`, `partnerPublicKey`, `partnerDeviceName` MUST be `.nullable()` (null during 'pending' state before partner joins). Add `expiresAt` as `integer().nullable()()` for pair code expiry countdown.

**Step 2: Write sync_queue_table.dart**

Primary key: `{id}`. Index: `idx_sync_queue_created` on `{#createdAt}`.

**Step 3: Register tables in app_database.dart**

Add `PairedDevices` and `SyncQueue` to `@DriftDatabase(tables: [...])`. Increment `schemaVersion`. Add migration for new tables.

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Commit**

```bash
git add lib/data/tables/ lib/data/app_database.dart
git commit -m "feat(sync): add Drift tables for paired devices and sync queue"
```

---

### Task 4: DAOs

**Files:**
- Create: `lib/data/daos/paired_device_dao.dart`
- Create: `lib/data/daos/sync_queue_dao.dart`

**Step 1: Write PairedDeviceDao**

Methods: `insert`, `update`, `findActive`, `findByPairId`, `updateStatus`, `updateLastSyncTime`. Follow pattern from `transaction_dao.dart` - constructor takes `AppDatabase`.

**Step 2: Write SyncQueueDao**

Methods: `insert`, `getPending(limit)`, `delete(id)`, `incrementRetry(id)`, `deleteAll`.

**Step 3: Run code generation and verify build**

Run: `flutter pub run build_runner build --delete-conflicting-outputs && flutter analyze`

**Step 4: Commit**

```bash
git add lib/data/daos/
git commit -m "feat(sync): add DAOs for paired devices and sync queue"
```

---

### Task 5: Repository implementations

**Files:**
- Create: `lib/data/repositories/pair_repository_impl.dart`
- Create: `lib/data/repositories/sync_repository_impl.dart`
- Test: `test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 1: Write failing test for PairRepositoryImpl**

Test: savePendingPair (status=pending, partner fields null), saveConfirmingPair (status=confirming, partner fields set), activatePair (status=active), confirmLocalPair (confirming->active), getActivePair returns null when no active pair, getActivePair returns null for confirming/pending pairs, deactivatePair.

**Step 2: Implement PairRepositoryImpl**

Implements `PairRepository` interface. Uses `PairedDeviceDao`. Converts between `PairedDeviceData` (Drift) and `PairedDevice` (domain model). IMPORTANT: `getActivePair()` must filter `WHERE status = 'active'` only -- never return pending or confirming pairs, otherwise sync logic starts before confirmation.

**Step 3: Run test**

Run: `flutter test test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 4: Implement SyncRepositoryImpl**

**Step 5: Commit**

```bash
git add lib/data/repositories/ test/unit/data/repositories/
git commit -m "feat(sync): implement pair and sync repositories"
```

---

## Phase C3: Infrastructure Layer

### Task 6: E2EE Service

**Files:**
- Create: `lib/infrastructure/sync/e2ee_service.dart`
- Test: `test/unit/infrastructure/sync/e2ee_service_test.dart`

**Step 1: Add NaCl dependency**

Check if `cryptography` package (already in pubspec) supports X25519 + XSalsa20-Poly1305. If not, add `pinenacl: ^0.6.0` or `tweetnacl: ^1.0.0`.

**Step 2: Write failing test**

Test: encrypt then decrypt returns original plaintext. Test: decrypt with wrong key fails.

**Step 3: Implement E2EEService**

Key operations:
1. Ed25519 -> X25519 key conversion
2. X25519 Diffie-Hellman shared secret
3. XSalsa20-Poly1305 encrypt/decrypt (NaCl box)
4. Output format: base64(nonce_24bytes + ciphertext)

**Step 4: Run test**

Run: `flutter test test/unit/infrastructure/sync/e2ee_service_test.dart`

**Step 5: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement E2EE service with NaCl box"
```

---

### Task 7: Request Signer and Relay API Client

**Files:**
- Create: `lib/infrastructure/sync/relay_api_client.dart`
- Test: `test/unit/infrastructure/sync/relay_api_client_test.dart`

**Step 1: Add HTTP dependency**

Verify `dio` or `http` is in pubspec. Add if needed.

**Step 2: Write request signer**

`RequestSigner` class: constructs message `"$method:$path:$timestamp:$bodyHash"`, signs with Ed25519 private key from `KeyManager`, returns `"Ed25519 $deviceId:$timestamp:$base64Signature"`.

**Step 3: Write RelayApiClient**

Server URL configuration:
- Production (kReleaseMode): `https://sync.happypocket.app/api/v1`
- Development (!kReleaseMode): `https://dev-sync.happypocket.app/api/v1`
- Override via `--dart-define=SYNC_SERVER_URL=https://...`

Wraps all server API calls. Adds `Authorization` header via `RequestSigner`. Methods: `createPair`, `joinPair`, `confirmPair`, `unpair`, `pushSync`, `pullSync`, `ackSync`, `registerDevice`, `updatePushToken`.

Retry with exponential backoff on network errors.

**Step 4: Write unit test with mock HTTP**

Test: createPair sends correct request body, adds auth header. Test: pushSync handles 201 response. Test: network error throws.

**Step 5: Run tests**

Run: `flutter test test/unit/infrastructure/sync/relay_api_client_test.dart`

**Step 6: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement relay API client with Ed25519 signing"
```

---

### Task 8: Sync Queue Manager

**Files:**
- Create: `lib/infrastructure/sync/sync_queue_manager.dart`
- Test: `test/unit/infrastructure/sync/sync_queue_manager_test.dart`

**Step 1: Write failing test**

Test: enqueue adds entry. Test: drainQueue sends and deletes on success. Test: drainQueue increments retry on failure. Test: clearQueue deletes all.

**Step 2: Implement SyncQueueManager**

Max batch size: 50. Uses `SyncQueueDao` for persistence and `RelayApiClient` for pushing.

**Step 3: Run test**

Run: `flutter test test/unit/infrastructure/sync/sync_queue_manager_test.dart`

**Step 4: Commit**

```bash
git add lib/infrastructure/sync/ test/unit/infrastructure/sync/
git commit -m "feat(sync): implement offline sync queue manager"
```

---

### Task 9: Push Notification Service

**Files:**
- Create: `lib/infrastructure/sync/push_notification_service.dart`

**Step 1: Add firebase_messaging dependency**

```bash
flutter pub add firebase_messaging
```

**Step 2: Implement PushNotificationService**

- Request permission on iOS
- Get and register FCM/APNs token with server
- Message dispatch by `type` field:
  - `pair_confirmed` -> call `_handlePairConfirmed()`: get `getPendingPair()`, if status == confirming call `confirmLocalPair(pairId)` then `pullSync()`. This is the ONLY path that transitions Device B from confirming -> active.
  - `sync_available` -> call `pullSync()`
  - `pair_request` -> handled by system notification (foreground only)
- Handle background message: support both `sync_available` and `pair_confirmed`
- Refresh token on change

**Step 3: Commit**

```bash
git add lib/infrastructure/sync/
git commit -m "feat(sync): implement push notification service"
```

---

## Phase C4: Application Layer (Use Cases)

### Task 10: Pairing use cases

**Files:**
- Create: `lib/application/family_sync/create_pair_use_case.dart`
- Create: `lib/application/family_sync/join_pair_use_case.dart`
- Create: `lib/application/family_sync/confirm_pair_use_case.dart`
- Create: `lib/application/family_sync/unpair_use_case.dart`
- Test: `test/unit/application/family_sync/create_pair_use_case_test.dart`
- Test: `test/unit/application/family_sync/join_pair_use_case_test.dart`

**Step 1: Write failing tests for CreatePairUseCase**

Test: success returns pairId + pairCode. Test: error when keyManager has no keys.

**Step 2: Implement CreatePairUseCase**

See MOD-003 "配对发起" section. IMPORTANT: Must call `_apiClient.registerDevice()` (idempotent, unauthenticated) BEFORE `_apiClient.createPair()`. Without this, the server has no public key to verify the device's Ed25519 signature on the createPair request.

**Step 3: Write failing tests for JoinPairUseCase**

Test: success stores partner public key. Test: initializes E2EE shared secret. Test: calls registerDevice before joinPair.

**Step 4: Implement JoinPairUseCase, ConfirmPairUseCase, UnpairUseCase**

IMPORTANT for JoinPairUseCase: Must call `registerDevice()` before `joinPair()` (same auth bootstrap reason).

IMPORTANT for ConfirmPairUseCase: After confirm succeeds and E2EE is initialized, MUST trigger `fullSync.execute(bookId)` to push all existing local transactions to the newly paired partner. Without this, the partner's device starts empty and only receives future changes.

**Step 5: Run all tests**

Run: `flutter test test/unit/application/family_sync/`

**Step 6: Commit**

```bash
git add lib/application/family_sync/ test/unit/application/family_sync/
git commit -m "feat(sync): implement pairing use cases with tests"
```

---

### Task 11: Sync use cases

**Files:**
- Create: `lib/application/family_sync/push_sync_use_case.dart`
- Create: `lib/application/family_sync/pull_sync_use_case.dart`
- Create: `lib/application/family_sync/full_sync_use_case.dart`
- Test: `test/unit/application/family_sync/push_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`

**Step 1: Write failing tests for PushSyncUseCase**

Test: success encrypts and pushes. Test: network failure queues offline. Test: no pair returns noPair.

**Step 2: Implement PushSyncUseCase**

See MOD-003 "主动推送" section.

**Step 3: Write failing tests for PullSyncUseCase**

Test: pulls and decrypts messages. Test: ACKs after pull. Test: drains queue after pull. Test: stores server-issued `createdAt` of last message as sync cursor (NOT `DateTime.now()`).

IMPORTANT: The sync cursor MUST use the server's `created_at` timestamp from the last pulled message, not the client's wall-clock time. Client clock skew ahead of server time would cause subsequent pulls to skip valid messages.

**Step 4: Implement PullSyncUseCase and FullSyncUseCase**

PullSyncUseCase: After ACK, update `lastSyncAt` with `messages.last.createdAt` (server timestamp), not `DateTime.now()`.

FullSyncUseCase: Chunks all local transactions and pushes via PushSyncUseCase. Triggered by ConfirmPairUseCase after successful pairing.

**Step 5: Run all tests**

Run: `flutter test test/unit/application/family_sync/`

**Step 6: Commit**

```bash
git add lib/application/family_sync/ test/unit/application/family_sync/
git commit -m "feat(sync): implement sync use cases (push, pull, full sync)"
```

---

## Phase C5: Riverpod Providers

### Task 12: Riverpod providers

**Files:**
- Create: `lib/features/family_sync/presentation/providers/repository_providers.dart`
- Create: `lib/features/family_sync/presentation/providers/pair_providers.dart`
- Create: `lib/features/family_sync/presentation/providers/sync_providers.dart`

**Step 1: Write repository_providers.dart**

Single source of truth. Wire up: `pairRepository`, `syncRepository`, `relayApiClient`, `e2eeService`, `syncQueueManager`.

Follow pattern from `lib/features/accounting/presentation/providers/repository_providers.dart`:
```dart
@riverpod
PairRepository pairRepository(Ref ref) {
  final database = ref.watch(appDatabaseProvider);
  final dao = PairedDeviceDao(database);
  return PairRepositoryImpl(dao: dao);
}
```

**Step 2: Write pair_providers.dart**

Wire up: `createPairUseCase`, `joinPairUseCase`, `confirmPairUseCase`, `unpairUseCase`. Reference `repository_providers.dart`.

**Step 3: Write sync_providers.dart**

Wire up: `pushSyncUseCase`, `pullSyncUseCase`, `syncStatusProvider`.

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Verify build**

Run: `flutter analyze`
Expected: No issues found

**Step 6: Commit**

```bash
git add lib/features/family_sync/presentation/providers/
git commit -m "feat(sync): add Riverpod providers for family sync"
```

---

## Phase C6: UI Layer

### Task 13: Pairing screen

**Files:**
- Create: `lib/features/family_sync/presentation/screens/pairing_screen.dart`
- Create: `lib/features/family_sync/presentation/widgets/pair_code_display.dart`
- Create: `lib/features/family_sync/presentation/widgets/pair_code_input.dart`

**Step 1: Add QR code dependency**

```bash
flutter pub add qr_flutter
```

**Step 2: Implement PairCodeDisplay**

Shows QR code (250x250) + 6-digit code (formatted "XXX XXX") + 10-min expiry timer + regenerate button. Uses `ref.watch(createPairProvider(bookId))`.

**Step 3: Implement PairCodeInput**

6-digit input field with large font + submit button. Calls `ref.read(joinPairProvider(code))`.

**Step 4: Implement PairingScreen**

TabBarView with 2 tabs: "Show My Code" and "Enter Partner Code".

**Step 5: Commit**

```bash
git add lib/features/family_sync/presentation/
git commit -m "feat(sync): implement pairing screen with QR and short code"
```

---

### Task 14: Sync status widgets

**Files:**
- Create: `lib/features/family_sync/presentation/widgets/sync_status_badge.dart`
- Create: `lib/features/family_sync/presentation/widgets/partner_device_tile.dart`
- Create: `lib/features/family_sync/presentation/screens/pair_management_screen.dart`

**Step 1: Implement SyncStatusBadge**

Displays icon + label based on `SyncStatus` enum. Colors: green (synced), blue (syncing), orange (pairing/offline), red (error), grey (unpaired).

**Step 2: Implement PartnerDeviceTile**

Shows partner device name, last sync time (using `DateFormatter`), sync status badge.

**Step 3: Implement PairManagementScreen**

Shows current pair info, sync status, unpair button with confirmation dialog.

**Step 4: Commit**

```bash
git add lib/features/family_sync/presentation/
git commit -m "feat(sync): implement sync status widgets and pair management"
```

---

### Task 15: App lifecycle integration

**Files:**
- Modify: `lib/core/initialization/app_initializer.dart`
- Modify: App lifecycle observer (create if needed)

**Step 1: Add lifecycle observer**

On `AppLifecycleState.resumed`: if paired, call `pullSync()` and `drainSyncQueue()`.

**Step 2: Hook transaction changes (create, update, delete)**

After `CreateTransactionUseCase`, `UpdateTransactionUseCase`, and `DeleteTransactionUseCase` succeed: if paired, call `pushSync()` with CRDT operations. FR-002 requires syncing both new AND modified bills. Without hooking update/delete, partner replicas will diverge for edits and removals.

**Step 3: Hook push notifications**

Push messages are dispatched by `type` field (see Task 9 PushNotificationService):
- `pair_confirmed` -> `_handlePairConfirmed()` (confirmLocalPair + pullSync). Without this, Device B stays in `confirming` forever and `getActivePair()` never returns it.
- `sync_available` -> `pullSync()`
- `pair_request` -> system notification (no code action needed)

**Step 4: Commit**

```bash
git add lib/core/ lib/application/
git commit -m "feat(sync): integrate sync triggers with app lifecycle"
```

---

### Task 16: Navigation and routing

**Files:**
- Modify: `lib/core/router/` (add routes for pairing_screen, pair_management_screen)

**Step 1: Add routes**

```dart
GoRoute(
  path: '/pairing',
  builder: (context, state) => PairingScreen(
    bookId: state.extra as String,
  ),
),
GoRoute(
  path: '/pair-management',
  builder: (context, state) => const PairManagementScreen(),
),
```

**Step 2: Add entry point in settings or home screen**

Add "Family Sync" option in settings screen or home screen widget.

**Step 3: Commit**

```bash
git add lib/core/router/ lib/features/
git commit -m "feat(sync): add navigation routes for family sync screens"
```

---

## Phase C7: Testing, i18n & Final Verification

### Task 17: Client unit tests

**Files:**
- Test: `test/unit/infrastructure/sync/e2ee_service_test.dart`
- Test: `test/unit/application/family_sync/push_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/pull_sync_use_case_test.dart`
- Test: `test/unit/application/family_sync/create_pair_use_case_test.dart`
- Test: `test/unit/data/repositories/pair_repository_impl_test.dart`

**Step 1: Verify all client tests pass**

Run: `flutter test`
Expected: All pass

**Step 2: Check coverage**

Run: `flutter test --coverage`
Expected: >=80% coverage for new files

**Step 3: Commit**

```bash
git commit -m "test(sync): verify all client tests pass with 80%+ coverage"
```

---

### Task 18: Add i18n strings

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_zh.arb`

**Step 1: Add translation keys**

Keys needed: `devicePairing`, `showMyCode`, `enterPartnerCode`, `pairCodeExpiresIn`, `regenerate`, `unpaired`, `pairing`, `synced`, `syncing`, `syncError`, `offline`, `unpair`, `unpairConfirmation`, `pairSuccess`, `pairFailed`.

Add to all 3 ARB files with @metadata.

**Step 2: Generate localization files**

Run: `flutter gen-l10n`

**Step 3: Commit**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(sync): add i18n strings for family sync (ja/en/zh)"
```

---

### Task 19: Final verification

**Step 1: Run flutter analyze**

Run: `flutter analyze`
Expected: No issues found

**Step 2: Run all tests**

Run: `flutter test`
Expected: All pass

**Step 3: Build check**

Run: `flutter build ios --no-codesign` (or `flutter build apk --debug`)
Expected: Builds without errors

**Step 4: Commit any fixes**

```bash
git commit -m "chore(sync): final verification pass - all tests and build green"
```

---

## Task Dependency Graph

```
Phase C1: Domain
  T1 (models) -> T2 (repo interfaces)

Phase C2: Data (depends on C1)
  T3 (Drift tables) -> T4 (DAOs) -> T5 (repo impls)

Phase C3: Infrastructure (depends on C2)
  T6 (E2EE) --+
  T7 (API)  --+--> T8 (queue) -> T9 (push)

Phase C4: Use Cases (depends on C3)
  T10 (pair UCs) -> T11 (sync UCs)

Phase C5: Providers (depends on C4)
  T12 (providers)

Phase C6: UI (depends on C5)
  T13 (pairing screen) -> T14 (status widgets) -> T15 (lifecycle) -> T16 (routing)

Phase C7: Testing (depends on all above)
  T17 (client tests) -> T18 (i18n) -> T19 (final verify)
```

---

## Estimated Effort

| Phase | Tasks | Estimated Time |
|-------|-------|---------------|
| Phase C1: Domain Layer | T1-T2 | 0.5 days |
| Phase C2: Data Layer | T3-T5 | 1.5 days |
| Phase C3: Infrastructure | T6-T9 | 2 days |
| Phase C4: Use Cases | T10-T11 | 1.5 days |
| Phase C5: Providers | T12 | 0.5 days |
| Phase C6: UI | T13-T16 | 2 days |
| Phase C7: Testing & i18n | T17-T19 | 2 days |
| **Total** | **19 tasks** | **~10 days** |

---

## Notes

- **Server dependency:** Tasks T7 (API Client) and beyond require the server API to be available. During development, use mock HTTP responses or a local dev server.
- **Can start before server:** Tasks T1-T6 (domain, data, E2EE) are fully independent of the server.
- **Firebase setup required:** Task T9 (Push Notifications) requires Firebase project configuration for both iOS and Android.
