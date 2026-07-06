# 语音金额「量级词↔位数」一致性守卫（quick-260706-kzr）

**日期:** 2026-07-06
**时间:** 16:16
**任务类型:** 功能开发
**状态:** 已完成
**相关模块:** 语音记账（voice amount parsing / ITN 防线第五层）

---

## 任务概述

用户需求：「语音输入增加检查，如果用户说了3千5百16，一定要确保最后显示的数字是4位，万是5位，日语和英文也要做相同的处理。」针对 iOS ITN 拼接毒化（五千三百一十二 →"53102"）建立确定性位数校验——当话语含量级词（千/万/thousand）时，最终显示金额的位数必须与量级结构一致；锚定不到时从 alternates 转录找锚。

---

## 完成的工作

### 1. 规格泛化

- 最高量级 千/仟(zh)、千/せん/ぜん(ja)、thousand(en) → 期望位数 = 乘数位数 + 3（「3千5百16」→4 位；ja 裸「千円」乘数缺省 1→4 位）
- 最高量级 万/萬(zh)、万/まん(ja) → 期望位数 = 乘数位数 + 4（「5万」→5 位；「三十五万」→6 位）
- en 无 ten-thousand 词，万规则不适用 en；乘数限 1–999，小数（3.5千）返回 null

### 2. 三层实现

- **L1 纯函数** `expectedDigitCountForAmount(text, {localeId})`（新文件 `lib/application/voice/amount_magnitude_guard.dart`）：金额语境锚 = 量级 token 紧邻前置数词 + 整个数字表达以货币后缀（VoiceCurrencySuffixes）或串尾收尾。precision over recall——千万别/万一/成千上万/1万步/3.5千/日期共存句全部 null（不校验不误改）。
- **L2 use-case 仲裁**（`parse_voice_input_use_case.dart` 1a 块后）：expected 取 primary ?? alternates 首个非 null；resolvedAmount 位数违反时按 ①既有 concat 候选 ②状态机重读 ③alternates extractAmount 顺序采用（候选位数必须==expected，绝不发明数值）。采用时 **candidate swap**：resolvedAmount←修复值、amountRepairCandidate←原毒化值——既有 `voiceAmountRepairSuspect` 通知自动变成「改回原值」撤销入口，零新 ARB key、零 freezed 字段、零 build_runner。260703 精确-alternate 静默采用语义一字不动。
- **L3 mixin 显示仲裁**（`voice_ptt_session_mixin.dart` :388 泛化）：rawText 量级锚已知且 `_mergedAmount` 违反位数而 `data.amount` 满足 → parsed 赢；既有 concat 例外字节不变，追加 OR 分支。

### 3. 代码变更统计

8 文件 +890/-8（6 个 TDD 红绿提交）：新 guard + 测试矩阵 156 行、use-case 测试 121 行、mixin 测试 +143 行、arch 扫描白名单 +4。

---

## 遇到的问题与解决方案

### 问题 1: 计划的 ja 证明向量超解析器上限
**症状:** `100002000円` 超 10M clamp，primary 提取为 null，仲裁前置条件永不成立。
**解决方案:** [Rule 1 偏差] 换同形状在界向量 `5000300円`（零开头 tail 同样击败 concat 探测器，仍只有来源③ alternates 能修）。

### 问题 2: 新 NLP lexicon 文件触发 hardcoded-CJK 架构扫描
**解决方案:** [Rule 2 偏差] 按 voice_text_parser 既有先例加入 `hardcoded_cjk_ui_scan_test.dart` 白名单（NLP 词表非 UI 文案）。

---

## 测试验证

- [x] TDD 先红后绿（6 提交严格 RED→GREEN 序）
- [x] L1 正反例矩阵（zh/ja/en × 千/万 × 乘数 1 位/多位 × 裸千 × 惯用语反例 × 日期共存）
- [x] L2：截图案「53102元」+ alternate「五千三百一十二元」→ 5312；ja `5000300円` + alternate「一万二千円」路线;en concat 修复
- [x] L3：merged 35016 → parsed 3516（真 RED 场景）+ 53102 回归钉
- [x] `flutter analyze` 0 issues（executor + orchestrator 双跑）
- [x] full `flutter test` 3601/3601 exit 0（executor 直连；合并后树 hash 一致，证据转移）
- [x] 0 golden / 0 ARB / 0 generated 变更
- [ ] 真机 UAT：重现截图场景（说「五千三百一十二」）确认显示 5312 + 撤销通知

---

## Git 提交记录

```
d55d1bc0 test(quick-260706-kzr): add failing matrix for expectedDigitCountForAmount
fd6ca815 feat(quick-260706-kzr): implement expectedDigitCountForAmount magnitude guard
7fd6b7b1 test(quick-260706-kzr): add failing use-case magnitude arbitration test
b4d1aab5 feat(quick-260706-kzr): use-case magnitude arbitration with candidate swap
88a055f0 test(quick-260706-kzr): add failing mixin magnitude arbitration scenarios
2b35e5fd feat(quick-260706-kzr): mixin display arbitration honors rawText magnitude anchor
13ad9dfd chore: merge executor worktree
```

---

## 后续工作

- [ ] 真机 UAT：zh「五千三百一十二」、ja「ごせんさんびゃくじゅうに円」、en "three thousand five hundred sixteen dollars" 三语验证
- [ ] 观察 precision-over-recall 的漏网形状（如有新 ITN 变体，加向量即可，架构已就位）

---

## 参考资源

- `.planning/quick/260706-kzr-voice-amount-magnitude-digit-count-guard/`（PLAN/SUMMARY，偏差详录）
- 项目 memory：voice-itn-concat-amount-defenses（260703 四层防线，本任务为第五层）

---

**创建时间:** 2026-07-06 16:16
**作者:** Claude (Fable 5)
