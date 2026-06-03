---
phase: quick-260603-nr1
plan: 01
subsystem: home / accounting / list UI
tags: [feedback-toast, confirm-dialog, i18n, icons, reactive-invalidation, edit-delete, golden]
requires: [deleteTransactionUseCaseProvider, AppPalette, S/gen-l10n]
provides:
  - "feedback_toast.dart — unified top success/error overlay helper"
  - "soft_confirm_dialog.dart — shared warm rounded confirm dialog"
  - "invalidate_transaction_dependents.dart — shared mutation invalidation helper"
  - "SoftToast FeedbackTone (success/error) variant"
affects: [manual_one_step_screen, transaction_edit_screen, list_screen, list_transaction_tile, home_hero_card]
tech-stack:
  added: []
  patterns: [overlay-toast, palette-driven-dialog, family-wide ref.invalidate, pop-with-result reactive refresh]
key-files:
  created:
    - lib/features/accounting/presentation/widgets/feedback_toast.dart
    - lib/shared/widgets/soft_confirm_dialog.dart
    - lib/shared/utils/invalidate_transaction_dependents.dart
  modified:
    - lib/features/accounting/presentation/widgets/soft_toast.dart
    - lib/features/accounting/presentation/screens/manual_one_step_screen.dart
    - lib/features/list/presentation/widgets/list_transaction_tile.dart
    - lib/features/list/presentation/screens/list_screen.dart
    - lib/features/accounting/presentation/screens/transaction_edit_screen.dart
    - lib/features/home/presentation/widgets/home_hero_card.dart
    - lib/l10n/app_ja.arb
    - lib/l10n/app_zh.arb
    - lib/l10n/app_en.arb
decisions:
  - "SoftToast success tone derives border/shadow from palette.success via alpha — no new palette tokens"
  - "Continuous-entry reset re-seeds default category AND pushes it into the form (GlobalKey preserves form state)"
  - "Home + Analytics providers invalidated whole-family; list + calendar keyed"
  - "Edit-screen delete relies on caller pop(true) for invalidation (no active year/month in edit screen)"
metrics:
  duration: ~35m
  completed: 2026-06-03
  commits: 3
  tasks: 3
---

# Quick Task 260603-nr1: 首页/记账 UI 优化 + 反应式刷新 bug 修复 Summary

One-liner: 统一顶部成功/错误反馈胶囊 + 共享暖色确认对话框 + 金额校验/连续记账，首页标题图标换 eco/workspace_premium、悦己 bar 去渐变，列表 padding+chevron，删除/编辑后首页+分析页即时刷新（共享 invalidation helper），编辑页新增删除按钮。

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | 记账反馈重设计 + 统一柔和确认对话框 (#1) | `92227367` |
| 2 | 首页标题图标替换 + 悦己 bar 去渐变 (#2 #3) | `bea205f8` |
| 3 | 列表 padding+chevron + 共享失效 helper + 编辑页删除 (#4 #5 #6) | `618ba6cf` |

## What was built

### Task 1 (#1)
- `SoftToast` 新增 `FeedbackTone { success, error }`：success 用 `palette.success`/`palette.successLight`（border/shadow 由 success alpha 派生），error 保持 `error*` tints；tone 决定默认图标（check_circle_outline / error_outline）。默认 error 保持向后兼容。
- 新增 `feedback_toast.dart`：顶部 Overlay 单一入口 `showSuccessFeedback`/`showErrorFeedback`（复用 voice_error_toast 的 OverlayEntry 范式，top = padding.top+16）。
- `manual_one_step_screen`：`_trySave` 新增空/零金额校验（`pleaseEnterAmount`）；成功后不再 `popUntil` —— 改为顶部成功吐司 + 表单复位（金额归零、merchant/note 清空、日期回今天、重置默认类目并推入表单、焦点回金额）保持页面打开连续记账；validation/persist error 走顶部错误吐司；移除内联 `_toastMessage`/`SoftToast` block。
- 新增 `soft_confirm_dialog.dart`：共享暖色圆角确认对话框（圆角 20、palette.card 卡片、确认 = palette.error、取消 = textSecondary），列表滑删 confirmDismiss 接入替换默认 Material AlertDialog。
- i18n：三语新增 `pleaseEnterAmount` + `successKeepGoing` + gen-l10n。

### Task 2 (#2 #3)
- 悦己充盈 header 图标 `auto_awesome → Icons.eco`；本月最爱 header 图标 `auto_awesome → Icons.workspace_premium`（均 16px/palette.joy）。
- `_splitBar` 悦己段去 LinearGradient → 纯色 `palette.joy`（与日常段一致）。
- 10 个 home_hero_card golden 重拍。

### Task 3 (#4 #5 #6)
- `list_transaction_tile`：内层 padding horizontal 10→16；金额后新增 `SizedBox(6)` + `Icon(chevron_right, 18, textSecondary)`，与 Dismissible 共存。
- 新增 `invalidate_transaction_dependents.dart`（普通顶层函数，无 codegen）：keyed 失效 list+calendar，whole-family 失效 today/monthly/happiness/bestJoy。
- `list_screen.invalidateAfterMutation` 委托给共享 helper（滑删 onDeleted + 编辑保存 result==true 自动获益）。
- `transaction_edit_screen`：AppBar 新增 `palette.error` 删除 IconButton → showSoftConfirmDialog → deleteTransactionUseCaseProvider.execute → pop(true)（caller 触发失效）。
- 6 个 list_transaction_tile golden 重拍。

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Test] 更新 manual_one_step_screen_test popUntil 断言**
- **Found during:** Task 1
- **Issue:** `260526-r8y Item 3` 测试断言保存后页面 pop（`Navigator.popUntil(isFirst)`），与锁定决策 #1「成功后不关页连续记账」矛盾。
- **Fix:** 断言改为 `findsOneWidget`（页面保持打开），保留核心断言（保存 use case 调用一次）。
- **Files modified:** test/widget/.../manual_one_step_screen_test.dart
- **Commit:** `92227367`

**2. [Rule 1 - Test] 更新 list_transaction_tile_test 对话框断言**
- **Found during:** Task 1
- **Issue:** `ROW-02` 测试断言 `find.byType(AlertDialog)`，新共享对话框是 `Dialog` 非 `AlertDialog`。
- **Fix:** 改为断言 `find.byType(Dialog)` + 两个 `TextButton`（确认/取消）。初次尝试用 `find.text('削除しますか？')` 因全角字符匹配不稳定，改用更稳健的按钮断言。
- **Files modified:** test/widget/features/list/list_transaction_tile_test.dart
- **Commit:** `92227367`

These are necessary test updates: both tests encoded behavior that decisions #1 explicitly replaced. No production-code deviations.

## Verification

- `flutter analyze` → 4 issues, all pre-existing & out-of-scope (firebase_messaging build artifacts ×2 + category_selection_screen.dart `onReorder` deprecation ×2). 0 issues in touched files.
- `flutter gen-l10n` → 通过（三语 ARB 含 pleaseEnterAmount + successKeepGoing）。
- `flutter test` → **2297/2297 全绿**（含全部 golden master）。
- Task 2/3 golden 已 `--update-goldens` 重拍并复跑确认绿（10 home_hero_card + 6 list_transaction_tile）。

## Known Stubs

None — all wiring is live (delete uses deleteTransactionUseCaseProvider; invalidation helper called from real mutation sites).

## Self-Check

- feedback_toast.dart / soft_confirm_dialog.dart / invalidate_transaction_dependents.dart — created, FOUND.
- Commits 92227367 / bea205f8 / 618ba6cf — FOUND in git log.

## Self-Check: PASSED
