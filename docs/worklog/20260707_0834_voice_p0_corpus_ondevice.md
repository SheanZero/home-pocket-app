# 语音 P0 语料/薄弱测试/onDevice 离线（quick-260706-tm6）

**日期:** 2026-07-07
**任务类型:** 测试补强 + 功能（离线）
**状态:** 已完成
**相关模块:** MOD-009 语音记账（§10 P0-4/5/6 + 离线 Tier 0）

## 完成的工作

1. **黄金语料两档制（P0-4）**：cn2an/Kanjize/NeMo-ja 参照向量移植——17 golden 逐条严格断言 + 11 known-gap `skip:` 归档（缩放类 5 条为同一深坑：与零省略位值直读 anchor 冲突；token 缺失 4 条；小数 2 条等 int→decimal 决策）。新列表新文件，既有 95% 统计闸零污染。顺手 1 行浅修：十万/百万形 万-flush 隐式 1 误触。
2. **薄弱测试补齐（P0-5）**：`manual_one_step_snapshot` 13 字段 capture/restore 直测；`voice_locale_readiness_mixin` 4 态+dispose；宿主 keypad 镜像 4 条非 happy path（既有 fake speech harness，零生产改动）。
3. **onDevice 离线 Tier 0（P0-6）**：`VoiceTuning.preferOnDeviceRecognition` 默认开——识别请求优先设备端；service 单落点降级（listen 失败→静默重试 onDevice:false + session latch），restartListen 自动兼容；TDD 5 条 RED→GREEN；零新 ARB（用户可见隐私开关留给 sherpa 任务）。
4. **插件拼接审读**：pub-cache speech_to_text **7.3.0**（文档 §9.1 的 7.4.0 为调研时最新版，仓库未升级）`SpeechToTextPlugin.swift` 只读审读——pause 重置拼接触发 :827/:894、**空格分隔符** :931-932/:940-941、与 L1 merger 交互双拼风险评估 **LOW**（merger 的 2.5s 窗口+双闸谓词与插件空格 join 不叠加）。结论专节入 SUMMARY。

## 验证

- full flutter test **3675 passed + 11 skipped**（基线 3632 零修改零失败）；analyze 0；零 generated/ARB/golden
- 执行过程跨一次 session-limit 中断，从已提交状态原地恢复（同 worktree 同上下文）

## Git

`13a25ae3`(浅修) → `80c0e17c`(语料) → `0e39c44b`(薄弱测试) → `02fcf907`(RED) → `d2e4169e`(onDevice GREEN) → `0afe9f16`(merge)

**作者:** Claude (Fable 5)
