# Quick Task 260622-nhs: 记账录入「按住说话」单页重构 — Context

**Gathered:** 2026-06-22
**Status:** Ready for planning（设计已 review 通过，方案 V2 锁定）

<domain>
## Task Boundary

重构记账录入界面：**取消「手工/语音」模式切换**，合并为单页。自然手工键盘输入是唯一常驻
状态；语音改为**动量动作（push-to-talk）**：底部全宽「按住说话」长条，按住 → 语音浮层
（实时转写 + 波形 + 录音红麦克风）→ 松手 → 解析结果填入同一张表单 → 回到手工。

设计稿与调研：`260622-nhs-DESIGN.md` + `mocks/entry-ptt-designs.html`（方案 V2）。
</domain>

<decisions>
## Implementation Decisions（LOCKED — 不要重新讨论）

### D-1 交互方案 = V2「底部按住说话长条」
- 键盘下方常驻一条**全宽** PTT 长条（樱粉浅底，`🎤 按住说话`）。
- 长条**按住录音**（hold-to-record），松手结束。命中区 = 整条。

### D-2 松手行为 = 填入表单·停留确认
- 松手后：解析金额/分类/商家/日期 → 填入当前表单 → **停在手工页，不自动保存**。
- 用户可手动微调，再点「保存」。**不做**松手即存 / 连续记账（本次不引入）。

### D-3 架构 = 合并为单页
- 以 `manual_one_step_screen.dart` 为唯一录入页（画布）。
- **移除头部 `EntryModeSwitcher` / `InputModeTabs`** 的手工/语音切换 Tab。
- 抽取现有 `voice_input_screen.dart` 的录音/转写/解析/波形逻辑为可复用单元
  （controller / overlay widget），供 PTT 长条调用 —— **复用，不重写**：
  `start_speech_recognition_use_case` / `parse_voice_input_use_case` /
  `voice_chunk_merger` / `voice_satisfaction_estimator` / `voice_waveform` /
  外币 triple 推送 / 满意度估计，全部保留语义。
- 旧独立语音路由若不再被引用则移除其入口；保留底层逻辑。

### D-4 复用现有语音能力（不回归）
- 外币识别与 triple 推送（goh 任务成果）、悦己满意度估计、JPY-native 路径、
  chunk merger 2.5s 窗口 —— 行为保持不变。

### Claude's Discretion
- PTT 长条与键盘的精确布局/高度、浮层动画、触觉反馈细节。
- OCR 入口（当前 feature-flag 隐藏）不在本次范围，移除 Tab 不应影响其隐藏态。
- 长按阈值、误触保护、最短录音时长沿用现有 voice 逻辑参数。
</decisions>

<specifics>
## Specific Ideas

- 浮层内容：`正在聆听…`（脉冲红点）+ 实时转写文本 + 16 条波形 + 录音红圆角麦克风 +
  `松开 → 自动填入表单` 提示。复用 `voice_waveform.dart`。
- 配色按 `app_palette.dart`：PTT 长条樱粉浅底；录音浮层红 `#E5484D→#C93040`；
  保存键樱粉渐变 `#E09DB4→#D98CA0`。
- i18n：新增/调整字符串（如 `holdToTalkBar`「按住说话」、`listening`「正在聆听」）
  需同时更新 ja/zh/en 三个 ARB 并 `flutter gen-l10n`；移除不再使用的 `manualInput`/
  `voiceInput` Tab 文案前先确认无其他引用。
</specifics>

<canonical_refs>
## Canonical References

- `lib/features/accounting/presentation/screens/manual_one_step_screen.dart`（合并目标主页）
- `lib/features/accounting/presentation/screens/voice_input_screen.dart`（抽取复用来源）
- `lib/features/accounting/presentation/widgets/entry_mode_switcher.dart` +
  `input_mode_tabs.dart`（移除手工/语音 Tab）
- `lib/features/accounting/presentation/widgets/{smart_keyboard,voice_waveform,amount_display,transaction_details_form}.dart`
- `lib/application/voice/*`（解析/识别/合并/满意度 use cases — 复用）
- `lib/core/theme/app_palette.dart`（配色 token）
- `lib/l10n/app_{ja,zh,en}.arb`（三语字符串）
- 测试：`test/...accounting...` widget/golden + `test/infrastructure/voice/`、
  `test/architecture/`（hardcoded_cjk_ui_scan 等必跑）
</canonical_refs>
