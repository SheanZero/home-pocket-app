# Phase 52 Plan 03：延迟分类纠正回流（defer-to-save）

**日期:** 2026-06-24
**时间:** 20:14
**任务类型:** 功能开发 / 重构
**状态:** 已完成
**相关模块:** [RECUX-03] 语音识别 UX —— 分类纠正学习回流

---

## 任务概述

将分类纠正写入 `category_keyword_preferences` 学习表的时机，从「分类一变就立即写」改为「在条目确认保存时写一次」（D-05）。芯片轻点（52-02 AlternateCategoryChips 的 onSelect）与完整选择器两条路径都算作一次纠正（D-06）。写入键保持 `resolvedKeyword` 原样（write==read，260526-pg6）；关键词为空写不写任何东西，且永远不碰商家表（D-07/D-16）。重置 / 连续记账 / 返回会丢弃待定纠正且不写表（避免被放弃的草稿污染学习表）。

---

## 完成的工作

### 1. 主要变更

- `lib/features/accounting/presentation/widgets/transaction_details_form.dart`
  - 删除 `_applyCategorySelection` 尾部的即时 `correctionUseCase.execute(...)`。
  - 新增 `_PendingCategoryCorrection` 不可变 stash 类（`keyword` = resolvedKeyword 原样 + `correctedCategoryId`）与状态字段 `_pendingCorrection`。
  - 在 `_applyCategorySelection`：分类变为非「识别原始类目」→ 设 stash；变回原始类目 → 清 stash；关键词 null/空 → 不设 stash（D-07 不留孤儿键）。
  - 在 `submit()` 的 `.new` 成功分支：合并商家学习 hook 之后，待定 stash 存在 + 最终类目 ≠ 识别原始 + 关键词非空时，调用一次 `recordCategoryCorrectionUseCase.execute(...)`，随后清 stash。
  - 新增公开方法 `discardPendingCorrection()`；`updateCategory`（宿主驱动的 voice 批量填充 / 快照还原 / 连续记账重置）清 stash。
- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`
  - `_onVoiceReset`（重置·恢复账目）与 `_resetForContinuousEntry`（连续记账）显式调用 `discardPendingCorrection()`。
- `test/widget/.../transaction_details_form_correction_test.dart`（新建）
  - spy `RecordCategoryCorrectionUseCase` + spy `MerchantCategoryPreferenceRepository`，6 个用例：
    1. D-05 芯片改后放弃（不保存）→ 0 次写
    2. D-06 芯片改后保存 → 1 次写，键 == resolvedKeyword，类目 id 正确
    3. D-06 完整选择器改后保存 → 1 次写（同一共享路径，经退出芯片 → CategorySelectionScreen → 展开父类 → 点子类）
    4. D-07 关键词为 null + 改类目 + 保存 → 0 次写
    5. RECUX-03/D-16 纠正保存永不写商家表
    6. D-05 改走后又改回原始类目 + 保存 → 0 次写

### 2. 技术决策

- D-20：采用显式 stash + 保存时再写一次的模型；保存时再核对「最终类目 ≠ 识别原始」作为纵深防御。
- D-21：宿主命令式 `updateCategory` 视为全新草稿（非交互纠正）→ 清 stash；reset/连续/返回额外显式 `discardPendingCorrection()` 以应对快照无类目的情况。

### 3. 代码变更统计

- 3 个文件（1 新建 + 2 修改）。
- 提交：`c4b44141`（重构）、`77689a6c`（测试）、`92352938`（文档/状态）。

---

## 遇到的问题与解决方案

### 问题 1：「改回原始类目」用例第二次点芯片找不到芯片
**症状:** 第一次点芯片后 D-09 会清掉 band，芯片随之消失，第二次点不到原始类目芯片。
**原因:** D-09 在任何一次用户选类后折叠 band/chips。
**解决方案:** 第一次点击后重新 `updateRecognition(...)` 让芯片重新渲染，再点原始类目芯片——真实走「改回原始→清 stash」路径。仅测试构造问题，无生产代码改动。

---

## 测试验证

- [x] `flutter analyze` 全项目 0 issues
- [x] 新增纠正 widget 测试 6/6 通过
- [x] 既有 `transaction_details_form_test.dart`（23）/ smoke 无回归
- [x] 宿主 `manual_one_step_screen_test.dart` / foreign_triple 测试无回归（71）
- [x] 验证 grep：form 中无 `merchant_category_preferences` / `MerchantCategoryPreference` / `recordMerchantCorrection`

---

## Git 提交记录

```bash
c4b44141 refactor(52): defer category-correction write from change to save (D-05/06/07)
77689a6c test(52): deferred category-correction widget tests (D-05/06/07)
92352938 docs(52): complete plan 03 — deferred category-correction reflux (RECUX-03 / D-05/06/07)
```

---

## 后续工作

- [ ] 52-06：相位收尾波（三语 ARB 一致性 + anti-toxicity 扫描 + macOS golden 重基线）—— 本计划新增的 band/chips/纠正表面是其输入。

---

## 参考资源

- `.planning/phases/52-recognition-ux-english-voice/52-03-PLAN.md`
- `.planning/phases/52-recognition-ux-english-voice/52-03-SUMMARY.md`
- 契约：260526-pg6（write==read 关键词身份）、ADR-012（反游戏化）、D-16（本相位不做商家纠正回流）

---

**创建时间:** 2026-06-24 20:14
**作者:** Claude Opus 4.8
