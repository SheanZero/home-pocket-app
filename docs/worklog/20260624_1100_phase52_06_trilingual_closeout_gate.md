# Phase 52 Plan 06: 三语收尾闸门（反毒性 sweep + ARB parity + golden）

**日期:** 2026-06-24
**时间:** 11:00
**任务类型:** 测试 / i18n 闸门
**状态:** 已完成
**相关模块:** [RECUX-04 / RECUX-05] Recognition UX 收尾门禁

---

## 任务概述

执行 Phase 52 的合并阻断收尾闸门（D-17）：为新识别 UI 增加完整禁词表的反毒性 sweep（修复 v1.8 WR-02 列表不完整问题），确认三语 ARB parity，并验证全量 analyze + test 通过。门禁内联运行，不延后到里程碑收尾（v1.7/v1.8 教训）。

---

## 完成的工作

### 1. 主要变更
- 新建 `test/widget/features/accounting/presentation/widgets/anti_toxicity_phase52_test.dart`（21 用例）。
  - 覆盖五个新 UI 状态 × {en,ja,zh}：band-strong（× daily/joy）、band-weak+chips、correction-open、manual-no-affordance（D-10 断言不渲染 band/chips）、voice-panel。
  - 禁词表 = phase16/phase47 逐字 + 完整 v1.8 WR-02 词（score/streak/accuracy/正确率/連続/ストリーク/達成）+ UI-SPEC §Copywriting 词（badge/leaderboard/正解率/連勝/达成 等）。
  - 增加 locked-list 完整性 guard：断言 WR-02 词永远不能被悄悄缩减。
  - fixture 使用 `cat_*` id 让 chips 解析出真实三语标签（非原始 key），并加覆盖 guard（exit chip + 本地化 Food 标签）。
- Task 2/3 为纯验证闸门，无工作树改动：gen-l10n 干净、parity 测试已自动覆盖 2 个新 key、无 golden 引用新 surface（无需 rebaseline）、`git add -f lib/generated/` 无 stale 文件。

### 2. 技术决策
- 五个 surface 映射到两个真正新增的有文本 widget（band 无文本，仅 a11y Semantics；chips 渲染类目标签 + exit chip ARB 标签）。04/05 仅数据/解析改动，无新语音面板 widget。
- 用 `cat_*` 而非 `category_*`：`CategoryLocalizationService.resolveFromId` 只翻译 `cat_` 前缀 id，否则三语都渲染相同原始 key，使三语 sweep 失效。

### 3. 代码变更统计
- 1 新建文件；0 修改源文件。

---

## 遇到的问题与解决方案

### 问题 1: stale_suppressions_scan 报未批准的 ignore 指令
**症状:** 全量测试唯一失败 —— 新测试文件含 `// ignore_for_file: lines_longer_than_80_chars`，未在允许列表内。
**原因:** 该 lint 在本仓库未实际配置（参考的 phase16/phase47 测试有 100 字符 import 行也未抑制），指令多余。
**解决方案:** 删除该指令。重跑 analyze（0 issues）、stale-suppressions scan（绿）、sweep（21 绿）。修复 amend 进 Task 1 commit（同一新建文件）。

---

## 测试验证

- [x] `flutter analyze` → 0 issues
- [x] 全量 `flutter test` → 3352/3352 绿
- [x] `flutter gen-l10n` 干净；arb_key_parity 绿；2 个新 key 三语齐全；ARB 无商家名
- [x] golden 全量 202 绿，无需 rebaseline

---

## Git 提交记录

```
35ac551a test: anti-toxicity phase52 sweep — new-UI surfaces × ja/zh/en, COMPLETE banned list (RECUX-04 / D-17)
ba9ff263 docs(52): complete plan 06 — trilingual close-out gate (anti-toxicity sweep + ARB parity + golden, RECUX-04/05)
```

---

## 后续工作

- Phase 52 全部 6 个 plan 完成，状态 `ready_for_verification`。下一步 `/gsd-verify-work`。

---

**创建时间:** 2026-06-24 11:00
**作者:** Claude Opus 4.8
