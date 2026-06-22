# 记账录入「按住说话」单页重构（quick 260622-nhs）

**日期:** 2026-06-22
**时间:** 17:49
**任务类型:** 重构 / 功能开发
**状态:** 已完成（代码层全绿；设备端 PTT 视觉/功能 UAT 待用户确认）
**相关模块:** MOD-001 基础记账 / MOD-005 OCR（隐藏态不变）

---

## 任务概述

取消记账录入页的「手工/语音」模式切换 Tab，合并为单页 push-to-talk：手工键盘是唯一常驻
状态；语音改为底部全宽「按住说话」长条 —— 按住录音、升起聆听浮层、松手把解析结果填入
同一张表单并停在手工页等用户确认保存（不自动保存、不连续记账）。复用而非重写现有语音
能力（外币 triple / 悦己满意度 / JPY-native / 2.5s chunk merger / 波形 — 行为不变）。

锁定决策 D-1..D-4（CONTEXT，未改动）。

---

## 完成的工作

### 1. 抽取可复用语音会话单元（Task 1）
- 新建 `voice_ptt_session_mixin.dart`（`VoicePttSessionMixin`）—— 拥有录音/转写/chunk
  merger/解析/满意度/外币 triple 全部会话逻辑，host-agnostic，与现有
  `VoiceRecognitionEventHandlerMixin` / `VoiceLocaleReadinessMixin` 组合。
- `voice_input_screen.dart` 改为 re-host 该 mixin，UI 字节级不变；其全部既有测试零断言
  改动通过（纯无行为变化重构，characterization + mic golden 为契约）。
- 新增 mixin 单测：batch-fill / 误触 discard / 外币 triple（注入 speech mock + fake host）。

### 2. 两个 V2 视觉 widget（Task 2）
- `hold_to_talk_bar.dart`：全宽 48dp 樱粉长条（`joyLight`/`joyText` + joy dot + mic），
  `LongPressGestureRecognizer(duration: zero)` 按住/松手回调。
- `voice_listening_overlay.dart`：scrim + 圆角底板（正在聆听脉冲红点 + 实时转写 +
  16 条波形 + 录音红圆角麦克风 + 松开提示），palette-only，全文经 `S.of(context)`。
- 新增 3 个 ARB key（`holdToTalkBar`/`listeningTitle`/`releaseToFill`）ja/zh/en + gen-l10n。

### 3. 单页 PTT 接线（Task 3）
- `ManualOneStepScreen` host `VoicePttSessionMixin`；`HoldToTalkBar` 渲染在
  SmartKeyboard 下方（随键盘隐藏而隐藏）；按住升起 `VoiceListeningOverlay`，松手 batch-fill
  `_formKey` 并停留（D-2，不自动保存/不 pop）。
- `_lastFillWasVoice` 标志把 `EntrySource.voice` 透传进 live form config（submit 读 config，
  故 provenance 跨单页合并存活，T-nhs-03）；清空金额/连续记账重置时复位为 manual。
- 从该页 build 移除 `EntryModeSwitcher`。
- 偏差（Rule 3）：抽取 `AddScreenForeignCard` + `_RateRequiredRow` 到
  `manual_one_step_foreign_card.dart`，PTT 接线后回收 LOC（975 → 955）。

### 4. 移除模式切换面 + 语音路由入口（Task 4）
- 删除 `entry_mode_switcher.dart` / `input_mode_tabs.dart`（含 `InputMode` enum）/
  `entry_mode_navigation_config.dart`（`navigateToEntryMode` + 路由表）—— 单页合并后零消费者。
- voice/ocr 屏幕 build 去掉 `EntryModeSwitcher`；`voice_input_screen.dart` 保留为未路由文件
  （底层逻辑完整，D-3）。OCR 仍隐藏在 `kOcrEntryEnabled`（未动）。
- 删除孤立 Tab ARB key `manualInput`/`voiceInput`/`ocrScan`（零源消费者）+ gen-l10n；
  `arb_key_parity` 的 OCR-stub 断言相应更新（`ocrScanTitle`/`ocrHint` 保留）。
- voice mic golden 因 Tab 移除布局变化，macOS scoped 重基线 1 张。

---

## 测试验证

- [x] `flutter analyze` = 0 issues
- [x] FULL `flutter test` = **3097/3097 green**（含架构测试 hardcoded_cjk_ui_scan /
      color_literal_scan / arb_key_parity / provider_graph_hygiene）
- [x] voice 行为/characterization 套件零断言改动通过（无行为回归契约）
- [x] golden 仅重基线受影响的 1 张（voice mic idle，macOS）
- [ ] 设备端 PTT 视觉/功能 UAT（locale ja→zh，6 步）—— 待用户确认

---

## Git 提交记录

```
4c651bbc refactor(260622-nhs): extract VoicePttSessionMixin from VoiceInputScreen
180c1325 feat(260622-nhs): hold-to-talk bar + listening overlay widgets
c2921b5b feat(260622-nhs): single-page push-to-talk on ManualOneStepScreen
24898044 refactor(260622-nhs): remove entry mode-switch tab + voice route entry
b68f6ccf test(260622-nhs): clean up test-only lints for the full-suite gate
```

---

## 后续工作

- [ ] 设备端确认 PTT 单页流程（Task 5 `<how-to-verify>` 6 步）。
- 残留 advisory：`manual_one_step_screen.dart` 仍 955 LOC（> 800 指引；任务前已 975，本次净减；
  深拆外币 push 逻辑风险高，留待后续）。

---

**创建时间:** 2026-06-22 17:49
**作者:** Claude Opus 4.8
