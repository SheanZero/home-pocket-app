# 暂时关闭悦己(Joy)记账庆祝动画

**日期:** 2026-06-03
**时间:** 18:10
**任务类型:** 重构（功能开关）
**状态:** 已完成
**相关模块:** MOD-001 BasicAccounting / dual_ledger

---

## 任务概述

用户要求「去除 soul 的动画，先不要了，后续再看如何添加」。即暂时关闭悦己（Joy / 灵魂账本）账目保存成功时的 `JoyCelebrationOverlay` 星花庆祝动画，但保留全部脚手架以便后续一行开关恢复。

---

## 完成的工作

### 1. 主要变更
- `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
  - 新增类级常量 `static const bool _kJoyCelebrationEnabled = false;`（含注释说明来由与恢复方式）。
  - 保存成功的 joy 分支触发条件加 `_kJoyCelebrationEnabled &&` 守卫（原 `if (tx.ledgerType == LedgerType.joy && mounted)`）。
- 关闭后行为自洽：`_showCelebration` 永远 false → 覆盖层不渲染；`_celebrationCompleter` 保持 null → `waitForCelebrationDismissed()` 立即返回 `Future.value()`，语音保存流程不再等待、立即 pop（与 daily 保存一致），无死锁。

### 2. 保留（便于后续恢复）
- `joy_celebration_overlay.dart` 组件、completer 机制、`waitForCelebrationDismissed()` 全部保留不动。
- `joy_celebration_overlay_test.dart`（widget 自身单测）不受影响，仍全绿。
- 恢复方式：把 `_kJoyCelebrationEnabled` 翻回 `true`，并把下述 2 个测试断言改回原值。

### 3. 测试同步（Rule 1：行为变更随码更新断言）
- `transaction_details_form_test.dart` 「.new joy save shows overlay」正例 → 改断言 `findsNothing`，标题/注释标注当前禁用 + 恢复指引。
- `voice_input_screen_test.dart` 「D-08 joy save defers pop」正例 → 改为「joy save 立即 pop、无覆盖层」（镜像同组 daily 用例），标题/注释标注禁用 + 恢复指引。

---

## 测试验证

- [x] `flutter test`（transaction_details_form + voice_input_screen + joy_celebration_overlay）→ 44/44 全绿
- [x] `flutter analyze`（3 改动文件）→ No issues found
- [x] 负例（daily 不弹、edit 不弹）原本就成立，保持

---

## 后续工作

- [ ] 后续如需重新加入庆祝动画：评估新的动画形式（用户「后续再看如何添加」），可能替换现有 sparkle 实现；翻 `_kJoyCelebrationEnabled=true` + 恢复 2 个测试正例断言作为起点。

---

**创建时间:** 2026-06-03 18:10
