# Wire Push Notification Handlers to SyncEngine

**日期:** 2026-04-05
**時間:** 18:40
**タスクタイプ:** 機能開発
**ステータス:** 完了
**関連モジュール:** [MOD-003] FamilySync / SyncEngine

---

## タスク概要

`PushNotificationService` の `registerHandlers()` メソッドがプロダクションコードで呼び出されておらず、テストでのみ使用されていた。`SyncEngine` に `connectPushNotifications()` メソッドを追加し、アプリ起動時に `main.dart` でプッシュ通知ハンドラーと SyncEngine を接続するよう修正した。

---

## 完了した作業

### 1. SyncEngine に `connectPushNotifications` メソッドを追加

**ファイル:** `lib/application/family_sync/sync_engine.dart`

- `push_notification_service.dart` のインポートを追加
- `initialize()` の直後に `connectPushNotifications(PushNotificationService)` メソッドを追加
- `onSyncAvailable` と `onMemberConfirmed` の2つのハンドラーのみを登録
  - `onJoinRequest`、`onMemberLeft`、`onGroupDissolved` はUI ナビゲーションイベントのため除外

### 2. `main.dart` でアプリ起動時に接続を確立

**ファイル:** `lib/main.dart`

- `repository_providers.dart` のインポートを追加（`pushNotificationServiceProvider` にアクセスするため）
- `syncEngine.initialize()` の直後に `connectPushNotifications` の呼び出しを追加

### 3. コード変更統計

- 修正ファイル数: 2
- 追加コード: 17行
- 主要ファイル:
  - `lib/application/family_sync/sync_engine.dart`
  - `lib/main.dart`

---

## 技術的決定事項

- **ハンドラーの選択:** `onSyncAvailable` と `onMemberConfirmed` のみ接続。UI ナビゲーション系のハンドラー（`onJoinRequest` 等）は各スクリーンが担当するため SyncEngine への接続は不要
- **クロージャのパラメータ:** `_` で受け取るプッシュ通知データは SyncEngine メソッドが引数不要なため無視
- **重複排除:** SyncEngine の `_isDuplicate()` により、WebSocket と Push Notification 両方から同一イベントが届いた場合も10秒ウィンドウ内で重複処理を防止済み

---

## 遭遇した問題と解決策

特に問題なし。既存の `registerHandlers()` API を呼び出すだけの単純な変更。

---

## テスト検証

- [x] `flutter analyze` — 0 issues
- [x] `flutter test` — 878件全テスト通過
- [ ] 手動テスト検証（デバイス上でのプッシュ通知受信確認は別途必要）

---

## Git コミット記録

```
Commit: 8e73db7
Date: 2026-04-05

feat: wire push notification handlers to SyncEngine
```

---

## 後続タスク

- プッシュ通知が実際に SyncEngine をトリガーすることのデバイス実機テスト
- `PushNotificationService.initialize()` が完了した後に `connectPushNotifications` が呼ばれることの確認（現在は `initialize()` の前に接続しているが、ハンドラー登録自体は `initialize()` より先でも問題ない）

---

**作成時間:** 2026-04-05 18:40
**作成者:** Claude Sonnet 4.6
