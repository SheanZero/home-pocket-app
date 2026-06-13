---
quick_id: 260613-wjx
title: Fix Home recent-items edit — save quantity / delete not reflected
status: complete
date: 2026-06-13
commit: 72d52e15
---

# Quick Task 260613-wjx — Summary

修复 Home 首页"最近项"的 bug：从最近项点击进入编辑后，修改数量和删除都没有生效。

## Root cause

`home_screen.dart` 的最近项 `HomeTransactionTile.onTap` 用 fire-and-forget 方式
`Navigator.push`：既没 `await` 返回的 `bool`，也没在保存/删除后失效 Home 列表所依赖的
provider。所以编辑和删除**确实已写入数据库**，但 `todayTransactionsProvider` 继续返回缓存值，
看起来像"没生效"——直到屏幕被重建才显示。

List 页面早已正确处理这一契约（`list_screen.dart` WR-03）：await push 结果，`result == true`
时调用 `invalidateTransactionDependents(...)`。`TransactionEditScreen` 在 `_save` / `_onDelete`
两处都 `pop(true)`，并把失效职责交给调用方。Home 调用方此前没履行——是近期编辑流重构后的回归。

## Changes

- **`lib/features/home/presentation/screens/home_screen.dart`**
  - import `shared/utils/invalidate_transaction_dependents.dart`
  - 把最近项 `onTap` 改为 async：await `Navigator.push<bool>` 结果，`result == true` 时调用
    `invalidateTransactionDependents(ref, bookId: bookId, year: year, month: month)`；
    try/catch + `FlutterError.reportError` 避免 `onTap: () async` 的 unhandled future
    （对齐 list_screen 的 WR-03 写法）。
- **`test/widget/features/home/presentation/screens/home_screen_test.dart`**
  - 新增回归测试：真实 HomeScreen + 计数版 `todayTransactionsProvider` override，点击最近项 →
    push 编辑屏 → `pop(true)` → 断言 provider 被重新拉取（计数 1→2）。无修复时该测试 RED。
- **`test/widget/features/home/presentation/screens/home_tap_to_edit_test.dart`**
  - 更新过期注释（原称"完整复现 home_screen wiring"，现仅复现导航 seam；失效逻辑由
    home_screen_test.dart 覆盖）。

## Verification

- `flutter analyze`（变更文件）：**0 issues**
- `flutter test test/widget/features/home/ test/features/home/`：**118/118 green**
- TDD RED 确认：临时移除失效调用 → 回归测试在 `todayFetchCount == 2` 断言处失败；恢复后转绿。

## Notes

- 仅改一个 lib 文件 + 测试；与现有 List 页面已验证的 pattern 字节级一致。
- 提交时未触及工作区中无关的预存改动（android/gradle.properties、MOD-004_OCR.md）。
