# 语音 P0 收敛：AmountArbiter + VoiceTuning + 去重（quick-260706-saz）

**日期:** 2026-07-06
**任务类型:** 重构（行为字节不变）
**状态:** 已完成
**相关模块:** MOD-009 语音记账（§10 P0-1/2/3/5）

## 完成的工作

1. **AmountArbiter 提取**（`lib/application/voice/amount_arbiter.dart`）：use-case 1a/1b 采用逻辑与 mixin display 仲裁收敛为 application 层单点；mixin 归零解析器 import（修 S3 层泄漏 + S4 双写）；260703/kzr 语义不变。
2. **VoiceTuning 常量集中**（`lib/shared/constants/voice_tuning.dart`）：十项魔法数收口（30s/3s/300ms×2 分名/2.5s/800ms/100ms/1M/10M/threshold 3）；floor 0.85 domain 自声明 + 一致性锁值测试。
3. **重复合并**：`_stopAndFill({endContinuous})` 合一 stop/exit；`_clearSessionBuffers()` 合一两处 reset 清零；公开 API 不变。
4. **P0-5 组合测试**：use-case×display 双仲裁站点命中向量（53102/5312、35016/3516）+ 1A undo 往返。

## 验证

- flutter analyze 0；full flutter test **3632/3632**（+31 新测试）；既有测试 additive-only（0 修改 0 失败）
- 层规则测试绿；零 generated/ARB/golden 变更
- Rule 3 偏差：lib 注释 MOD-009 字样触发 mod009_live_lib_scan_test，改写为 voice-consolidation P0-N（SUMMARY 详录）

## Git

`5f8bbd1f` VoiceTuning → `67dc9f66` AmountArbiter → `f323f89e` 去重+组合测试 → `a4866576` merge

**作者:** Claude (Fable 5)
