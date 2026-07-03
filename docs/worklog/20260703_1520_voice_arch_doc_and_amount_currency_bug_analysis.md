# 语音识别架构文档输出 + 金额/货币两处 bug 根因分析

**日期:** 2026-07-03
**时间:** 15:20
**任务类型:** 文档 + 问题诊断（只分析，未改代码）
**状态:** 已完成
**相关模块:** 语音记账（infrastructure/speech, infrastructure/voice, application/voice, features/voice, voice_ptt_session_mixin）

---

## 任务概述

1. 将语音识别（语音记账）的实现架构整理为 HTML 文档输出。
2. 对两个用户报告的 bug 定位根因并提出修改意见：
   - 中文说「两千五百四十六元」被识别为 **250046**；
   - 「元」被判为**人民币**，触发了不必要的 CNY→JPY 汇率转换（当前记账货币是日元）。

---

## 完成的工作

### 1. 架构文档（Artifact）

- 产出 HTML 架构文档：<https://claude.ai/code/artifact/5c69940b-31d1-419f-8da3-391c548e518f>
- 覆盖：端到端流水线（STT → SpeechRecognitionService → VoicePttSessionMixin → ParseVoiceInputUseCase → 表单/汇率）、五层文件地图、数字状态机算法（含「两千五百四十六→2546」逐 token 推演表）、VoiceChunkMerger 双门限、会话层两种模式与错误分类、货币检测两级判定与换汇链、双引擎 + Reconciler、两个 bug 的根因卡片与修复优先级总表（P0×2 / P1×4 / P2×3）。

### 2. BUG-1 根因（250046）

- **应用自身的汉字解析是正确的**：写了 7 条临时诊断测试（跑通后已删除）验证 `ChineseNumeralStateMachine.parse('两千五百四十六元') == 2546`。
- **根因在上游**：iOS STT 的数字归一化（ITN）把「两千五百|四十六」切成两段，各自归一化为 `2500`/`46`，中文转写无空格 → 应用收到的转写已是 `250046元`；应用唯一护栏是 `0 < amount < 10,000,000`（voice_text_parser.dart:164），原样放行。
- **同类隐患三个变体**（实测确认）：
  - `2500 46元`（带空格）→ scan() 连续 Digit 覆盖 → **46**；
  - 两个 final `"2500"`+`"46元"` → merger 纯阿拉伯缓冲判「不开放」→ 提交 **2500**、静默丢弃尾段；
  - `2,546元` 直进 merger（裸状态机，绕过 parser 的逗号权威防线）→ **546**（潜在）。

### 3. BUG-2 根因（元→CNY）

- 按规格实现的错误默认值：Phase 42 锁定决策 **D-08**「zh 语境裸『元』→ CNY」，落地在 parse_voice_input_use_case.dart:236 `return isZh ? 'CNY' : null;`。
- 与「块/块钱 → 本币（null，不换算）」自相矛盾；JPY 本位应用中，中文用户说「元」指日元。
- 换算执行点：voice_ptt_session_mixin.dart:385–397 → pushVoiceForeignTriple → convertToJpy。且该块不受 fillCategory 门控，partial 阶段每 300ms 也会触发汇率获取。

### 4. 修改意见（要点，详见 Artifact §8–§10）

- **P0 2A**：裸「元」永远视为本币——:236 改 `return null;`（1 行），supersede D-08 + 更新引用注释与 zh 语料。
- **P0 1A**：拼接签名检测（整百/整千 + 短尾段，250046→候选 2546）→ `amountSuspect` + 确认 chip，绝不静默改写。
- **P1**：1B merger 位值算术合并（并修 2500 截断）；1C scan() 连续 Digit 位值合并（修 46 变体）；2B 换算可见化+撤销；2C 换算仅 final 触发。
- **P2**：1D alternates 交叉验证自动修复；1E 大额确认护栏 + merger 走完整 parser；2D「元」语义设置项。

---

## 遇到的问题与解决方案

### 问题 1: 250046 无法在应用内复现
**症状:** 手动推演与 7 条测试均表明状态机/parser 对汉字与常见变体输出正确。
**原因:** 毒化发生在 speech_to_text 返回之前（iOS ITN 分段拼接），应用只是缺防线。
**解决方案:** 根因定性为「上游 ITN 拼接 + 应用侧无位值一致性防御」，修复建议全部落在应用侧分层防御（无法关闭 SFSpeechRecognizer 的 ITN）。

---

## 测试验证

- [x] 7 条临时诊断测试全部通过（flutter test，验证后已删除，未污染仓库）
- [x] 货币链路静态代码追踪闭环（use case → mixin → rate use case → convertToJpy）
- [ ] 代码修复（本次任务范围为分析，未实施）

---

## Git 提交记录

无代码变更（分析 + 文档任务）。基线：main @ 0b0ac6c5。

---

## 后续工作

- [ ] 实施 P0 2A（1 行 + supersede D-08 决策记录 + 语料断言更新）
- [ ] 实施 P0 1A（amountSuspect + 确认 chip）
- [ ] 排期 P1（1B/1C/2B/2C）与 P2（1D/1E/2D）

---

## 参考资源

- 架构文档 Artifact: <https://claude.ai/code/artifact/5c69940b-31d1-419f-8da3-391c548e518f>
- 关键代码: `lib/application/voice/parse_voice_input_use_case.dart:211-241`、`lib/application/voice/voice_text_parser.dart:66-171`、`lib/application/voice/voice_chunk_merger.dart`、`lib/infrastructure/voice/numeral_state_machine.dart:159-190`、`lib/features/accounting/presentation/screens/voice_ptt_session_mixin.dart:358,385-397,619-653`、`lib/shared/constants/voice_currency_suffixes.dart`

---

**创建时间:** 2026-07-03 15:20
**作者:** Claude (Fable 5)
