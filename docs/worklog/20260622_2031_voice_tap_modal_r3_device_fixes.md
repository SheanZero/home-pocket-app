# 语音记账录入 R3 — 真机三 bug 修复

**日期:** 2026-06-22
**时间:** 20:31
**任务类型:** Bug修复
**状态:** 自动 gate 已过；真机验收 PENDING（人工）
**相关模块:** [MOD-005] OCR/语音录入（单页 push-to-talk）

---

## 任务概述

R2（单页点击式语音记录）真机使用后发现 3 个交互问题。本次（R3）就地修改 R2 代码：
长条太高且与键盘脱节、键盘下方留白过大；点「重置」后不再聆听；语音弹窗是带遮罩的浮层
（表单被灰、盖在全屏上）。D-2「填表停留不自动保存」不变。

前置提交：R2 = `440afe73, 19ee8f62, d9ad48d9`。

---

## 完成的工作

### BUG 1 — 长条变矮融入键盘 + 收紧键盘下方留白（`fix: slim voice bar into keypad + trim bottom inset`，`0b6d9101`）
- `VoiceRecordBar`（`hold_to_talk_bar.dart`）：52dp 圆角独立卡片 → 38dp 贴键盘的窄条。
  去掉 `margin(16,0,16,8)` 与圆角边框，改为浅樱粉底 + 单条底部 hairline，读作键盘顶条。
  mic 图标 20→18。
- `manual_one_step_screen.dart`：移除 R2 包在 [长条+键盘] 外的 `SafeArea(top:false)`。
  它把 SmartKeyboard 自带的 24dp 底 padding 又叠了一层（刘海机 ≈ +34dp）。键盘自带 24dp
  已够避开 Home 指示条 —— 恢复 R1 之前的底距。

### BUG 2 — 重置后保证继续聆听（`fix: reset re-arms listening`，`6d098fa0`）
- 根因：`_onVoiceReset` → `resetPttSessionState()` 只清 transcript/merger/parse 缓冲，
  **不重启识别器**；若识别器此时已自终止（pauseFor/done）且未在 re-arm 周期，重置后即死。
- `voice_ptt_session_mixin.dart`：新增幂等 `restartPttListening()` —— 仅当
  `_continuousActive && _isRecording && !pttSpeechService.isListening` 时才 `startListening`。
  正在听 = no-op（不双启）；session 已结束 = no-op。
- `_onVoiceReset` 清缓冲后调用 `restartPttListening()`。

### BUG 3 — 语音面板就地替换键盘，去 scrim、去浮层（`refactor: inline voice panel replaces keypad`，`1c858612`）
- `voice_listening_overlay.dart`：`VoiceListeningModal`（`Positioned.fill` + 0.34 遮罩 +
  圆角阴影 bottom-sheet）→ `VoiceRecordPanel`（内联，无遮罩、无 sheet chrome）。
  内容保留：脉冲「正在聆听」/ 转写 / 波形 / 录音红 `mic_none` / 「轻点空白处退出」/ 重置键。
- `manual_one_step_screen.dart`：从外层 Stack 移除 `if (pttIsRecording) VoiceListeningModal(...)`；
  在 `AnimatedSlide` 内联三元：`pttIsRecording ? VoiceRecordPanel(...) : Column[slim 长条, SmartKeyboard]`。
  面板占键盘 footprint，表单不 reflow、背景不灰、实时可见自动填。
- 退出 = 点面板空白区（onExit）；重置键 onTap 不冒泡（嵌套 GestureDetector，内层赢手势竞技场）。

---

## 代码变更统计

- 修改：`hold_to_talk_bar.dart`、`voice_listening_overlay.dart`、`voice_ptt_session_mixin.dart`、
  `manual_one_step_screen.dart`（1007 → 1012 LOC，面板内容已抽到 `VoiceRecordPanel` 独立 widget）。
- 测试：`hold_to_talk_bar_test.dart`、`voice_listening_overlay_test.dart`、
  `manual_one_step_screen_test.dart`、`voice_ptt_session_mixin_test.dart`。

---

## 测试验证（自动 gate）

- [x] `flutter analyze`：**0 issues**
- [x] `flutter test`（全量，含架构测试）：**3108 passed / 0 failed**
- [x] golden：受影响项无 golden 基线引用（VoiceRecordBar / 面板 / 键盘底区均无 golden），无需 re-baseline。
- [x] 严格 TDD：每个 bug 先红后绿。
- [x] palette-only（无裸 hex），Material `Icons.mic_none` / `Icons.restore` 线性图标。
- [x] 无 ARB 文案改动（面板复用既有 `listeningTitle`/`voiceTapToExit`/`voiceResetRestore` 等）。
- [ ] **真机验收 PENDING**（见下）。

---

## Git 提交记录

```
0b6d9101 fix(260622-nhs): slim voice bar into keypad + trim bottom inset
6d098fa0 fix(260622-nhs): reset re-arms listening
1c858612 refactor(260622-nhs): inline voice panel replaces keypad (no scrim/overlay)
```

---

## 后续工作（真机验收 — 人工 PENDING）

1. 常态：语音记录条变矮、像键盘的一条窄顶条；键盘下方留白正常（不再过大）。
2. 录音中：语音面板**就地替换键盘**、**背景不灰**、无浮层；表单仍清晰可见并实时自动填。
3. 重置：点「重置·恢复账目」→ 账目还原 + **仍在聆听**，可再说一句再次自动填。

---

**创建时间:** 2026-06-22 20:31
**作者:** Claude Opus 4.8
