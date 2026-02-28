# MOD-003 Family Sync Client Implementation

**日期:** 2026-02-28
**時間:** 16:29
**任務類型:** 功能開発
**状態:** 已完成（部分 TODO 待後續）
**相關模組:** [MOD-003] Family Sync

---

## 任務概述

實現 MOD-003 Family Sync 模組的完整 Flutter 客戶端，包含 19 個任務，涵蓋 7 個階段（C1-C7）。功能包括：設備配對、E2EE 加密通訊、伺服器中繼同步、離線佇列、推播通知處理、生命週期整合、以及完整的 UI 畫面。

---

## 完成的工作

### Phase C1: Domain Layer (Tasks 1-2)
- **Freezed domain models**: `PairedDevice`, `SyncMessage`, `SyncStatus`
- **Repository interfaces**: `PairRepository` (8 methods), `SyncRepository` + `SyncQueueEntry`
- `PairStatus` enum: pending, confirming, active, inactive
- `SyncStatus` enum: unpaired, pairing, synced, syncing, syncError, offline

### Phase C2: Data Layer (Tasks 3-5)
- **Drift tables**: `PairedDevicesTable` (12 columns + indices), `SyncQueueTable` (9 columns + indices)
- **DAOs**: `PairedDeviceDao` (CRUD + status queries), `SyncQueueDao` (queue operations)
- **Repository implementations**: `PairRepositoryImpl`, `SyncRepositoryImpl`
- **Migration**: Schema v6→v7 in `app_database.dart` (createTable for both tables)

### Phase C3: Infrastructure Layer (Tasks 6-9)
- **E2EE Service** (`e2ee_service.dart`):
  - Ed25519→X25519 key conversion via `TweetNaClExt`
  - NaCl box encryption (X25519-XSalsa20-Poly1305) via `pinenacl` `Box` class
  - Format: `base64(nonce_24bytes + ciphertext)`
- **Relay API Client** (`relay_api_client.dart`):
  - `RequestSigner`: Ed25519 auth headers (`Ed25519 <deviceId>:<timestamp>:<signature>`)
  - Signature message: `<method>:<path>:<timestamp>:<SHA256(body)>`
  - 10 server endpoints (register, createPair, joinPair, confirmPair, etc.)
- **Sync Queue Manager** (`sync_queue_manager.dart`): Batch drain with max 5 retries
- **Push Notification Service** (`push_notification_service.dart`): Firebase stub + handler dispatch

### Phase C4: Application Layer (Tasks 10-11)
- **Pairing use cases** (4):
  - `CreatePairUseCase`: Device A creates pair, gets code
  - `JoinPairUseCase`: Device B joins with code
  - `ConfirmPairUseCase`: Device A confirms pair + triggers full sync
  - `UnpairUseCase`: Deactivate pair
- **Sync use cases** (3):
  - `PushSyncUseCase`: Encrypt + push (or queue offline)
  - `PullSyncUseCase`: Pull + decrypt + apply + ACK (server timestamp cursor)
  - `FullSyncUseCase`: Chunk all transactions + push

### Phase C5: Presentation Layer (Tasks 12-14)
- **Riverpod providers**: `repository_providers.dart`, `pair_providers.dart`, `sync_providers.dart`
- **Pairing screen**: TabBarView with "Show My Code" (QR + code) and "Enter Partner Code"
- **Pair management screen**: Device info, pair details, unpair button with confirmation
- **Widgets**: `SyncStatusBadge`, `PartnerDeviceTile`, `PairCodeDisplay`, `PairCodeInput`

### Phase C6: Integration (Tasks 15-16)
- **Sync lifecycle observer**: `SyncLifecycleObserver` triggers pullSync on app resume
- **Sync trigger service**: Coordinates lifecycle, transaction changes, push notifications
- **Push notification handlers**: `pair_confirmed` → confirmLocalPair + pullSync, `sync_available` → pullSync
- **Navigation**: Family Sync section added to Settings screen
- **App init**: `SyncTriggerService.initialize()` called in `main.dart`

### Phase C7: Polish (Tasks 17-19)
- **i18n**: 32 translation keys added to all 3 ARB files (en, ja, zh)
- **flutter analyze**: 0 errors, 0 warnings
- **flutter test**: 569 pass, 1 pre-existing failure (unrelated voice test)

---

## Code Review 發現的問題與修復

### CRITICAL Issues (已修復)

#### 1. `_handlePairConfirmed` 錯誤調用 ConfirmPairUseCase
**問題**: Device B 收到 `pair_confirmed` 推播時，錯誤地調用 `ConfirmPairUseCase`（會再次呼叫伺服器的 confirm endpoint）。正確做法是調用本地的 `confirmLocalPair()` 將狀態從 `confirming` 轉為 `active`。
**修復**: 重寫 `_handlePairConfirmed` 直接調用 `_pairRepo.getPendingPair()` + `_pairRepo.confirmLocalPair(pairId)`，移除 `ConfirmPairUseCase` 依賴。

#### 2. `confirmLocalPair` 三次 DB 查詢
**問題**: 查詢 `_dao.findByPairId(pairId)` 被調用三次取不同欄位。
**修復**: 改為讀取一次，null 檢查後再更新。

### IMPORTANT Issues (已修復)

#### 3. UI 字串硬編碼
**問題**: 所有 UI widget 使用英文硬編碼字串，違反 i18n 規則。
**修復**: 更新 `pairing_screen.dart`、`pair_management_screen.dart`、`family_sync_settings_section.dart` 使用 `S.of(context).familySyncXxx`。

#### 4. DateFormatter 未使用
**問題**: `partner_device_tile.dart` 使用自定義 `_formatRelativeTime`，`pair_management_screen.dart` 使用 `toString().substring(0, 10)`。
**修復**: 改用 `DateFormatter.formatRelative()` 和 `DateFormatter.formatDate()`。

#### 5. 重複 Provider 定義
**問題**: `sync_providers.dart` 內聯構造 `ConfirmPairUseCase` 而非使用 provider。
**修復**: 移除重複構造，因為 `SyncTriggerService` 不再需要 `ConfirmPairUseCase`。

#### 6. 缺少 `onTransactionUpdated`
**修復**: 新增 `onTransactionUpdated()` 便利方法到 `SyncTriggerService`。

---

## 已知 TODO / 待後續工作

### 需要後續實現
- [ ] `applyOperations` callback 目前是 no-op（CRDT apply logic 需要 MOD-001 完成後接入）
- [ ] `fetchAllTransactions` callback 返回空列表（需接入 transaction repository）
- [ ] `JoinPairUseCase` 的 `bookId` 設為空字串（需要 server 端 joinPair response 包含 bookId）
- [ ] Push notification 是 Firebase stub（需配置 Firebase）
- [ ] Background message handler 未實現
- [ ] `SyncStatusNotifier` 未在 sync 操作中自動更新
- [ ] Transaction use case 未實際 hook 到 `SyncTriggerService`
- [ ] 無 unit tests（應為 E2EE、RelayApiClient、use cases 添加測試）
- [ ] Relay API client 無重試 / exponential backoff

---

## 代碼變更統計

### 新增文件 (36 files)
| 層級 | 文件數 | 路徑 |
|------|--------|------|
| Domain models | 3 | `lib/features/family_sync/domain/models/` |
| Domain interfaces | 2 | `lib/features/family_sync/domain/repositories/` |
| Drift tables | 2 | `lib/data/tables/` |
| DAOs | 2 | `lib/data/daos/` |
| Repository impls | 2 | `lib/data/repositories/` |
| Infrastructure | 6 | `lib/infrastructure/sync/` |
| Application | 7 | `lib/application/family_sync/` |
| Providers | 3 | `lib/features/family_sync/presentation/providers/` |
| Screens | 2 | `lib/features/family_sync/presentation/screens/` |
| Widgets | 5 | `lib/features/family_sync/presentation/widgets/` |

### 修改文件 (5 files)
- `lib/data/app_database.dart` (table registration + migration)
- `lib/main.dart` (sync trigger initialization)
- `lib/features/settings/presentation/screens/settings_screen.dart` (family sync section)
- `lib/l10n/app_en.arb`, `app_ja.arb`, `app_zh.arb` (32 i18n keys each)
- `pubspec.yaml` (`uuid`, `qr_flutter` dependencies)

---

## 測試驗證

- [x] flutter analyze: 0 errors, 0 warnings (2 info-level pre-existing)
- [x] flutter test: 569 pass, 1 pre-existing failure (unrelated voice test)
- [x] build_runner: 669 outputs generated successfully
- [x] flutter gen-l10n: All 3 locales generated
- [ ] Family sync unit tests: NOT written (TODO)
- [ ] Integration tests: NOT written (TODO)

---

## 架構合規性

| 規則 | 合規 | 備註 |
|------|------|------|
| Thin Feature pattern | ✅ | Domain models + interfaces in feature, everything else outside |
| Repository provider single source | ✅ | `repository_providers.dart` is single source |
| i18n mandatory | ✅ | All UI strings use `S.of(context)` after review fix |
| DateFormatter mandatory | ✅ | Using `DateFormatter.formatDate/formatRelative` after review fix |
| Drift index syntax | ✅ | `TableIndex` with `{#column}` symbol syntax |
| Immutability | ✅ | Freezed models with copyWith |

---

## 技術決策

### 1. E2EE: pinenacl vs cryptography package
**選擇**: pinenacl 的 `Box` class + `TweetNaClExt` key conversion
**理由**: cryptography package 的 X25519 API 不支持從 Ed25519 key 直接轉換。pinenacl 提供底層 TweetNaCl 操作，允許正確的 Ed25519→X25519 birational map 轉換。

### 2. Sync cursor: server timestamp vs client clock
**選擇**: Server-provided `createdAt` timestamp
**理由**: 避免客戶端時鐘偏移導致漏掉同步消息。

### 3. Push notification: Stub implementation
**選擇**: Firebase stub with fallback to pull-on-resume
**理由**: Firebase 需要 platform-specific 配置（GoogleService-Info.plist / google-services.json），在開發階段先用 resume-based sync 替代。

### 4. Navigation: MaterialPageRoute vs GoRouter
**選擇**: 使用現有的 `MaterialPageRoute` + `Navigator.push`
**理由**: 項目尚未使用 GoRouter，保持一致性比引入新的路由模式更重要。

---

## 參考資源

- **客戶端計劃**: `docs/plans/2026-02-28-mod003-family-sync-client.md`
- **完整實現計劃**: `docs/plans/2026-02-28-mod003-family-sync-implementation.md`
- **模組規格**: `docs/arch/02-module-specs/MOD-003_FamilySync.md`
- **伺服器 API**: `docs/arch/server/SERVER-001_SyncRelay.md`

---

**創建時間:** 2026-02-28 16:29
**作者:** Claude Opus 4.6
