# Category Reorder Phase 6 (Tasks 6.1–6.4)

**日期:** 2026-04-11
**時間:** 19:51
**任務類型:** 功能開發
**状態:** 已完成
**相関モジュール:** [MOD-001] BasicAccounting / カテゴリ並べ替え機能

---

## 任务概述

CategorySelectionScreen に並べ替え編集モードを追加した (Phase 6, Tasks 6.1-6.4)。
Phases 1-5 で実装済みの CategoryReorderNotifier / CategoryReorderRow / CategoryReorderState を画面に統合し、L1・L2 のドラッグ並べ替え、保存・破棄ダイアログを実装した。

---

## 完成的工作

### 1. 主要変更 (category_selection_screen.dart)

- **Task 6.1:** AppBar に `Icons.reorder` ボタンを追加（読み取りモード）。タップで `CategoryReorderNotifier.enterEditing()` を呼び出し、AppBar をタイトル「Edit category order」＋Save TextButton の編集モードに切り替え。
- **Task 6.1:** `_onLeadingTap` / `_onSave` / `_showDiscardDialog` ヘルパーメソッドを追加。
- **Task 6.2:** `_buildReorderBody` / `_buildHintBanner` / `_buildReadBody` の 3 メソッドで body を分岐。
- **Task 6.2:** `SliverReorderableList` + `ReorderableDelayedDragStartListener` で L1 の並べ替えを実装。
- **Task 6.2:** `_L1ReorderTile` private widget で L1 タイル＋展開時の L2 `ReorderableListView.builder` を実装。
- **Task 6.3b:** ダーク テーマのスモーク テストが通過することを確認（実装自体は AppColors / AppColorsDark で分岐済み）。
- **Task 6.4:** isDirty 判定による破棄ダイアログ (`AlertDialog`) — keepEditing / Discard ボタン。

### 2. 技術決定

- `_parseColor` は State のインスタンスメソッドとして維持し、`_buildReorderBody` で色を事前解析して `_L1ReorderTile` に `Color` 型で渡すことで、StatelessWidget の `_L1ReorderTile` から State メソッドへの依存を排除した。
- `S.of(context).save` が既存のキーとして存在したため使用（ハードコードなし）。
- `AppColors.backgroundMuted` / `AppColorsDark.backgroundMuted` が存在したためヒントバナーに使用。

### 3. コード変更統計

- 変更ファイル数: 2
- 主要ファイル:
  - `lib/features/accounting/presentation/screens/category_selection_screen.dart` (+391 / -99)
  - `test/widget/features/accounting/presentation/screens/category_selection_screen_test.dart` (+100)

---

## テスト検証

- [x] 追加した 6 テストすべて PASS (+ 既存 1 テスト維持)
- [x] 全テスト 939 件 PASS (以前は 933 件)
- [x] flutter analyze: 0 issues
- [x] ダーク テーマ スモークテスト PASS (AC-13)
- [x] 破棄ダイアログのテスト PASS

---

## Git コミット記録

```
Commit: befeb59
Date: 2026-04-11

feat(accounting): add reorder entry button and edit-mode AppBar
```

---

## 後続作業

- Phase 7 があれば実装
- 結合テスト / E2E テストの追加検討

---

**作成時間:** 2026-04-11 19:51
**著者:** Claude Sonnet 4.6
