# Persistent WebSocket in SyncEngine

**日期:** 2026-04-05
**時間:** 18:46
**タスクタイプ:** 機能開発
**状態:** 完了
**関連モジュール:** [MOD-003] Family Sync

---

## タスク概要

SyncEngineにWebSocket永続接続を追加。アプリがフォアグラウンドでアクティブグループが存在する場合、SyncEngineはWebSocket接続を維持し、`sync_available`イベント受信時に即座に`onSyncAvailable()`をトリガーする。また、WaitingApprovalScreenからWebSocket管理を削除し、SyncEngineに一元化した。

---

## 完了した作業

### 1. SyncEngine — WebSocket + KeyManager依存性の追加

- `WebSocketService`と`KeyManager`をコンストラクタの必須パラメータとして追加
- `_wsEventSubscription`フィールドを追加
- 新規インポート: `dart:convert`, `key_manager.dart`, `websocket_service.dart`

### 2. SyncEngine — WebSocketライフサイクルメソッドの追加

- `_connectWebSocket()`: アクティブグループ取得 → deviceId取得 → イベント購読（冪等） → connect → startLifecycleObservation
- `_disconnectWebSocket()`: サブスクリプションキャンセル → stopLifecycleObservation → disconnect
- `_handleWebSocketEvent()`: `syncAvailable` → `onSyncAvailable()`, `memberConfirmed` → `onMemberConfirmed()`

### 3. SyncEngine — initialize() / dispose() の更新

- `initialize()`: アプリレジューム時にWebSocket再接続を追加、初期化時にWebSocket接続を開始
- `dispose()`: `_disconnectWebSocket()`を呼び出してクリーンアップ

### 4. syncEngineProvider の更新

- `webSocketService: ref.watch(webSocketServiceProvider)`を追加
- `keyManager: ref.watch(keyManagerProvider)`を追加

### 5. WaitingApprovalScreen の簡略化

- 削除: `_wsEventSubscription`, `_wsStateSubscription`, `_webSocketService`フィールド
- 削除: `_connectWebSocket()`メソッド（WebSocket接続管理）
- 削除: `_activateAndSync()`メソッド
- 削除: initState内の`_connectWebSocket()`呼び出し
- 削除: dispose内のWebSocketクリーンアップ
- 削除: 不要なインポート（`dart:convert`, `websocket_connection_state.dart`, `websocket_service.dart`, `crypto/providers.dart`）
- 保持: `_listenForSyncStatus()`, `_startAdaptivePolling()`, `_stopPolling()`, `_verifyGroupAndNavigate()`

### 6. テストの更新

3つのテストファイルを更新:
- `sync_engine_dedup_test.dart`: `MockWebSocketService`, `MockKeyManager`を追加、新コンストラクタに対応
- `waiting_approval_screen_test.dart`: SyncEngine構築順序をWebSocketモック後に変更
- `waiting_approval_screen_websocket_test.dart`: SyncEngineに新パラメータ追加、WebSocket接続テストをポーリング常時実行の新動作に合わせて更新

### 7. コード変更統計

- 修正ファイル数: 5ファイル
- 主要変更ファイル:
  - `lib/application/family_sync/sync_engine.dart`
  - `lib/features/family_sync/presentation/providers/sync_providers.dart`
  - `lib/features/family_sync/presentation/screens/waiting_approval_screen.dart`
  - `test/application/family_sync/sync_engine_dedup_test.dart`
  - `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_test.dart`
  - `test/widget/features/family_sync/presentation/screens/waiting_approval_screen_websocket_test.dart`

---

## 重要設計決定

### WebSocketServiceはシングルトン
`webSocketServiceProvider`はシングルトンProviderであり、接続は1つのみ。`WebSocketService.connect()`は既存の接続を切断してから新規接続する。

### アクティブグループが存在しない場合
`_connectWebSocket()`は`getActiveGroup()`がnullを返した場合に早期リターン。WaitingApprovalScreen表示中（グループステータス: confirming）は接続しない設計となっている。

### CreateGroupScreen / MemberApprovalScreen は対象外
これらの画面は独自のWebSocket管理を継続（アクティブグループがまだ存在しない可能性があるため）。

### deduplicationで二重処理を防止
SyncEngineの`_isDuplicate()`がWebSocketとPush通知の両方から届く同一イベントの重複処理を防ぐ。

---

## テスト検証

- [x] 単体テスト通過 (sync_engine_dedup_test: 3件)
- [x] ウィジェットテスト通過 (waiting_approval_screen_test: 5件, websocket_test: 2件)
- [x] dart analyze: 0 issues
- [ ] 統合テスト（手動確認推奨）

---

## 後続作業

- [ ] MemberApprovalScreenへのWebSocketライフサイクル追加（別タスク）
- [ ] WaitingApprovalScreenの最終的なWebSocket表示状態インジケーター（オプション）

---

**作成日時:** 2026-04-05 18:46
**作成者:** Claude Sonnet 4.6
