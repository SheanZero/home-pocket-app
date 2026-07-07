# 语音 P1：mixin 拆分 + 宿主瘦身 + 币种交叉验证（quick-260707-bwy）

**日期:** 2026-07-07
**任务类型:** 重构 + 功能
**状态:** 已完成 —— MOD-009 §10 **P0 全部 + P1-7/8 至此全部落地**
**相关模块:** MOD-009 语音记账

## 完成的工作

1. **mixin 巨石拆分（P1-7）**：`VoicePttSessionMixin` 1053 行 → 同库三文件：主声明 591（字段/契约/onError/onStatus）+ `voice_ptt_session_fill_orchestration.dart` part 320 + `voice_ptt_session_foreign_notice.dart` part 196，全部 <800。机械方案：Dart 不允许 mixin 声明跨 part 拆分 → part + `extension on VoicePttSessionMixin<W>` 承载方法体。`dart format` 0 变更证明字节忠实搬移；宿主/harness/公开 API 不变。
2. **宿主瘦身（P1-7 R2）**：`ManualOneStepScreen` 语音接线抽出 122 行 part；宿主残余 946 行（按范围盒不动 keypad/currency，残余已记录）。Rule 3 偏差：`setState` @protected 对 extension 不可达 → 4 处改走既有公开 `onPttSessionChanged`（行为等价）。
3. **alternates 币种矛盾压制（P1-8）**：`_crossValidateCurrency`——primary 检出外币 ISO 且任一 alternate 显式检出不同外币 ISO → 换算压制为 native（高危写操作宁可不做）；alternate 无币种 ≠ 矛盾；日期槽位交叉验证明确不做（决策记录）。TDD 7 测试。

## 验证

- full flutter test **3682 passed + 11 skipped**（基线 3675+11 零修改零失败，+7 additive）；analyze 0；零 generated/ARB/golden；架构测试全绿

## P0+P1 系列总账（saz → tm6 → bwy）

- 测试基线 3601 → **3682**（+81 净增，另 11 known-gap 归档）
- mixin 1075 → 591+320+196；仲裁双写→AmountArbiter 单点；魔法数十项→VoiceTuning
- 离线：设备端识别默认开 + 静默降级（Tier 0 落地）
- 未动：P1-9 sherpa spike（需模型分发决策+真机评测，单独立项）、宿主 keypad/currency 段（946 行残余）

## Git

`70ceadb3`(RED) → `9158a793`(币种 GREEN) → `a5ff6da6`(mixin 拆分) → `380ff04a`(宿主 part) → `8e8b2d41`(merge)

**作者:** Claude (Fable 5)
