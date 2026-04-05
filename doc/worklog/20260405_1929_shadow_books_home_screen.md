# Shadow Books Display on Home Screen

**日期:** 2026-04-05
**時間:** 19:29
**タスクタイプ:** 機能開発
**ステータス:** 完了
**関連モジュール:** [MOD-004] Family Sync / Home Feature

---

## タスク概要

ホーム画面のグループモードで、ハードコードされた「共有帳本 ¥0」行を削除し、シャドーブックごとに「{メンバー名}の帳本」という行を動的に表示するよう変更した。各行には実際の月次支出と先月の比較額を表示し、MonthOverviewCard の今月支出・先月合計にもシャドーブックの金額を加算する。

---

## 完了した作業

### 1. 新規プロバイダーファイル作成
- `lib/features/home/presentation/providers/shadow_books_provider.dart` を新規作成
  - `ShadowBookInfo` クラス（book, memberDisplayName, memberAvatarEmoji）
  - `ShadowAggregate` クラス（totalExpenses, prevTotalExpenses, perBookReports）
  - `shadowBooksProvider`: activeGroupProvider からグループを取得し、findShadowBooksByGroupId でシャドーブック一覧を取得、メンバー情報と結合
  - `shadowAggregateProvider`: shadowBooksProvider の各ブックに対して GetMonthlyReportUseCase を実行し合算

### 2. ホーム画面修正
- `lib/features/home/presentation/screens/home_screen.dart`
  - `shadowAggregateProvider` と `shadowBooksProvider` を watch に追加
  - MonthOverviewCard: シャドーブックの合計金額を report の値に加算
  - `_buildLedgerRows` のシグネチャに `shadowBooks` と `shadowAgg` の名前付き引数を追加
  - グループモード時のハードコード行を削除し、shadowBooks をループして動的に行を生成
  - 各シャドーブック行のタイトルを `${memberDisplayName}の帳本` に変更、subtitle に先月比較額を表示

### 3. 依存パッケージ追加
- `collection` パッケージを直接依存として pubspec.yaml に追加（`firstWhereOrNull` を使用するため）

### 4. テスト更新
- `test/features/home/presentation/screens/home_screen_test.dart`
  - `_shadowBook`、`_shadowBookInfo` のフィクスチャを追加
  - `buildSubject` に `shadowBooks` と `shadowAgg` のオーバーライドパラメータを追加
  - 失敗していたテスト「group mode shows 3 ledger rows including shared」を「group mode shows shadow book ledger row named after member」に刷新
  - 「共有帳本」ではなく「田中の帳本」が表示されることを検証

### 5. コード生成
- `shadow_books_provider.g.dart` が build_runner により自動生成された

---

## 遭遇した問題と解決策

### 問題 1: `collection` パッケージが直接依存でない
**症状:** `dart analyze` で `depend_on_referenced_packages` の info が出た
**原因:** `collection` は推移的依存としてのみ存在していた
**解決策:** `flutter pub add collection` で直接依存に追加

### 問題 2: 既存テストが「共有帳本」テキストを期待していた
**症状:** `home_screen_test.dart` の group mode テストが失敗
**原因:** 新しい実装ではシャドーブックが存在しない場合は行を追加しない
**解決策:** テストに shadowBooksProvider と shadowAggregateProvider のオーバーライドを追加し、フィクスチャのシャドーブックを使って「田中の帳本」が表示されることを検証するよう更新

---

## テスト検証

- [x] 単体テスト通過（home_screen_test.dart: 20/20）
- [x] flutter analyze: 0 issues
- [x] コードレビュー完了
- [x] ドキュメント更新（worklog）

---

## Git コミット記録

```bash
Commit: 8fe1de3
Date: 2026-04-05

feat: display shadow books with real amounts on home screen
```

---

## 後続作業

- [ ] シャドーブックの行をタップしてそのブックの詳細画面に遷移する機能
- [ ] shadowBooksProvider のリアルタイム更新（DB stream への切り替え検討）

---

**作成時間:** 2026-04-05 19:29
**作者:** Claude Sonnet 4.6
