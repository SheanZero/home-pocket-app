# 语音记录改为「点击·自动填表弹窗·重置恢复」(260622-nhs R2)

**日期:** 2026-06-22
**时间:** 19:59
**任务类型:** 重构 + 功能开发
**状态:** 已完成（代码层）；设备端真机验证待用户确认
**相关模块:** MOD-001 基础记账 / 语音录入

---

## 任务概述

R1 已实现单页 hold-to-talk push-to-talk。真机发现底部长条贴 iOS 上滑手势区难按。
R2 按终稿 `mocks/entry-voice-auto-modal.html` 改版：长条移到键盘上方、改单击、改名
「语音记录」线条 mic；聆听浮层改为自动填表 modal（轻点退出/仅一个重置键）；会话逻辑
改 tap-toggle + 持续识别 + 实时自动填表 + 快照还原。D-2（填入停留、不自动保存）不变。

---

## 完成的工作

### 1. 会话逻辑（mixin）
- `VoicePttSessionMixin` 新增 `startPttTapSession` / `exitPttTapSession` +
  `pttContinuousActive` 持续会话标志。
- 每次 speech-final **实时自动填表**：`_onResult` 解析后调用抽出的
  `_fillFormFromText`（原 `stopPttSessionAndCommit` 主体逐字抽取，单一填表路径，
  解析/合并/外币/满意度零分叉）。hold 路径不变（仍松手才填）。
- 识别器自终止（30s/3s 超时）时 `onStatus` 覆写 **重新启动监听** 保持 modal 不掉。
- `TransactionDetailsForm` 增加只读快照 getter，宿主可取快照/还原而不暴露 controller。

### 2. 底部长条 `VoiceRecordBar`（原 `HoldToTalkBar`）
- 移到键盘**上方**；键盘+长条底部包 `SafeArea` 避让 home indicator。
- 长按 → 单击 `onTap`；文案「语音记录」；线条 `Icons.mic_none`。

### 3. 聆听弹窗 `VoiceListeningModal`（原 `VoiceListeningOverlay`）
- 轻点弹窗/遮罩 = 退出（停止+关闭+保留内容+停留）。
- 唯一「重置·恢复账目」键（线条 `Icons.restore`），点击不冒泡到退出。去掉完成/取消。
- 提示「轻点空白处退出」在录音红线条麦克风正下方。

### 4. manual 屏接线
- tap → 取快照（`ManualEntrySnapshot`）→ 起持续会话+modal；退出→停止+终填+关闭；
  重置→还原快照（表单+金额/币种）+回退 provenance + `resetPttSessionState`（清转写、续听）。

### 5. i18n
- ARB ja/zh/en：`holdToTalkBar`→`voiceRecordBar`，删 `releaseToFill`，
  加 `voiceTapToExit`/`voiceResetRestore`/`voiceResetRestoreSub`；`flutter gen-l10n`。

### 代码变更统计
- 提交 3 个：`440afe73`（refactor）/ `19ee8f62`（feat）/ `d9ad48d9`（test）。
- 新文件 `manual_one_step_snapshot.dart`（110 行）。
- `manual_one_step_screen.dart` 954→1007 行（+53，已抽快照助手减负；超 800 cap 为既存）。

---

## 遇到的问题与解决方案

### 问题 1: modal 测试 pumpAndSettle 超时
**症状:** `_PulsingDot` 永久动画导致 `pumpAndSettle` 不收敛。
**解决:** 点击后改用 `pump()`；点击实体文字区域（标题）而非有间隙的波形条。

### 问题 2: 遮罩点击不触发退出
**症状:** scrim 的 `GestureDetector(child: ColoredBox)` 无尺寸不命中。
**解决:** 用 `Positioned.fill` 包裹 scrim 铺满。

### 问题 3: 提交原子性
**症状:** 长条 feat 与 modal feat 在屏幕集成处强耦合，拆开会产生不可编译的中间提交。
**解决:** 合并为单个可编译 feat（偏差 Rule 3，已记入 SUMMARY）。

---

## 测试验证

- [x] `flutter analyze` 0 issues
- [x] FULL `flutter test` 3104/3104 通过（架构测试含 hardcoded_cjk_ui_scan /
      color_literal_scan / arb_key_parity / provider_graph_hygiene）
- [x] 旧 `voice_input_screen` 全套既有测试零断言改动通过
- [x] golden 0 重基线（无 golden 覆盖这些面；voice mic golden 是未路由 hold 屏，未变）
- [ ] 真机 mic/STT 验证（人工，待用户确认）

---

## Git 提交记录

```
440afe73 refactor(260622-nhs): voice session → tap-toggle + form snapshot/restore
19ee8f62 feat(260622-nhs): tap voice-record modal above keypad + safe-area + auto-fill
d9ad48d9 test(260622-nhs): tap-modal bar/modal/screen + reset-restore coverage
```

---

## 后续工作

- [ ] 设备端 UAT（见 SUMMARY-R2 清单）：手势避让 / 自动填表 / 轻点退出保留 / 重置还原续听。
