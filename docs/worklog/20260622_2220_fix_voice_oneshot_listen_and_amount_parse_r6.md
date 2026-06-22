# 修复 R6 — 一次性聆听(停止聆听+点击重置提示) + 金额解析 99999→9

**日期:** 2026-06-22
**时间:** 22:20
**任务类型:** Bug修复
**状态:** 已完成（自动 gate 全绿；真机验证 PENDING）
**相关模块:** MOD-001 基础记账 / 语音录入（continuous tap 路径）

---

## 任务概述

真机暴露 R5 后两个问题：(1) 识别器结束后状态卡在「正在聆听」、麦克风已死、再说话无反应；
(2) 说「99999日元」金额被填成「9」。先做系统性根因调查，再用 TDD 修复，原地改 R5 代码。

---

## 完成的工作

### BUG 1 — 一次性聆听模型（取消不可靠的 iOS 连续 re-arm）

根因：iOS 连续 re-arm 不可靠 —— `onStatus` terminal / `onError` 静音（`error_no_match`/timeout）后
乐观地重新 `startListening` 并设 `_listenStatus=listening`，但 mic 往往没真正重启 → 状态卡「正在聆听」而麦克风已死。

- `voice_ptt_session_mixin.dart`：识别器自然终止（`done`/`notListening` terminal、`error_no_match`
  静音）→ `_isRecording=false`、`_listenStatus=stopped`，**不再 re-arm**。`error_no_match` 仍不弹 toast（保留 R5），但走 stopped。
  删除已死的 `_reArmPttListening` / `_reArmAfterTransientError` / public `restartPttListening`。
- `voice_listening_overlay.dart`（`VoiceRecordPanel`）：stopped 时灰色静态圆点（不脉冲）+ 扁平 muted 麦克风（无录音红渐变/阴影）
  + 新提示「点击重置重新录入」（新 ARB `voiceTapResetToRerecord` ×ja/zh/en + gen-l10n）。
- `manual_one_step_screen.dart`：引入 `_voiceModalOpen` 标志，面板可见性 gate 在它上面（**不再是 `pttIsRecording`**），
  一次性识别器停止后面板保留显示「停止聆听」+提示；轻点空白处退出关面板；重置 = `resetPttSessionAndRestart` 全新录音、面板保留、状态→聆听。

### BUG 2 — 「99999日元」解析填成「9」

根因：句中「一共」的「一」触发 `_numeralHintPattern` → 走 zh 状态机；scanner 对连续裸数字逐位 `digit = value`（覆盖而非累加），
只保留最后一位 9。逗号分组「99,999」则逗号被丢、run 被拆。

- `chinese_numeral_state_machine.dart` / `japanese_numeral_state_machine.dart`：`normalize` 把**相邻**连续阿拉伯数字
  累积成一个多位 `Digit`（非数字字符 flush run）→「99999」读 99999、「2千304」读 2304（顺带修了语料容忍失败项）。
  分隔（如停顿/逗号/文本）会 flush，所以游离的「一」不会并入「99999」。
- `voice_text_parser.dart`：含逗号分组（`\d[,，]\d`）时优先 Arabic 正则（权威），处理「99,999」「1,234,567」。

---

## 代码变更统计

- 修改源文件 5：mixin、panel widget、manual screen、2 个 numeral state machine + parser。
- 修改测试 3：ptt mixin test（一次性语义）、panel widget test（停止提示）、manual screen test（面板解耦）；parser test（99999 repro）。
- ARB ×3 新 key + gen-l10n（`lib/generated` force-add）。

---

## 测试验证

- `flutter analyze` 0 issues。
- **全量** `flutter test`：3132 passed / 0 failed（含架构测试 hardcoded_cjk_ui_scan、golden）。
- zh 语料 53/55 → 54/55（98.2%）。
- 真机复检 PENDING（见 SUMMARY-R6）。

---

## Git 提交记录

- `e5d64133` fix(260622-nhs): final parse authoritatively overrides partial amount (99999 not 9)
- `d2656847` fix(260622-nhs): one-shot listen — stop after recognizer ends, show 停止聆听 + tap-reset hint
- `d2773edf` fix(260622-nhs): decouple voice panel visibility from isRecording

---

## 后续工作

- [ ] 真机验证：说一句后识别器停 → 面板「停止聆听」+「点击重置重新录入」；点重置能重新录；状态不卡「正在聆听」。
- [ ] 真机验证：说「99999日元」→ 金额 99,999（非 9）；其他金额（含外币）不回归。

---

**创建时间:** 2026-06-22 22:20
**作者:** Claude Opus 4.8
