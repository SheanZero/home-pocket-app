# Phase 22: Voice One-Step Integration + Record Button UX - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 22-voice-one-step-integration-record-button-ux
**Areas discussed:** 单屏统一形态, 录音按钮交互模型, 语音→表单回填时机, 录音中状态视觉 + 100ms 时序

---

## Area 1 — 单屏统一形态

### Q1.1: voice + manual 在单屏上怎么合？

| Option | Description | Selected |
|--------|-------------|----------|
| A: 删 VoiceInputScreen，语音挂进 ManualOneStepScreen | 删除 voice_input_screen.dart；ManualOneStepScreen 变 mode-aware；EntryModeSwitcher 内部切 mode 不再 push 路由 | |
| B: 保留 VoiceInputScreen，重构它内嵌 form | VoiceInputScreen 继续存在但重写，host TransactionDetailsForm + mic 区；EntryModeSwitcher 继续 pushReplacement 三个屏 | ✓ |
| C: 抽出 OneStepEntryScreen 取代两者 | 新建 OneStepEntryScreen.dart 接收 inputMode 参数；删 ManualOneStepScreen + VoiceInputScreen；EntryModeSwitcher 切 mode 走同屏内部 | |

**User's choice:** B
**Notes:** 保留 manual / voice 两个独立 screen，重构最小化、各屏职责清晰。两者共用 TransactionDetailsForm 防止字段行为漂移。

### Q1.2: VoiceInputScreen 底部（原 SmartKeyboard 那一层）怎么布局？

| Option | Description | Selected |
|--------|-------------|----------|
| 不要 SmartKeyboard：mic + waveform 占据底层 | Voice 屏底不放数字键盘；点 AmountDisplay 弹 SmartKeyboard bottom sheet | |
| voice 不录音时保留 SmartKeyboard，录音中换成 waveform | 默认底是 SmartKeyboard；点 mic 开始录音 → SmartKeyboard 滑出、waveform 滑入 | |
| mic 固定屏底，waveform 起在结果区上方（中段） | mic 占据底部；waveform 在中段生长区域 | |
| **Other:** 当用户点击数字的时候，才弹出 keyboard | (自由文本) | ✓ |

**User's choice:** Other —— 默认底部 = mic + waveform + caption；只有点 AmountDisplay 才弹出 SmartKeyboard（沿用 Phase 18/TransactionEditScreen/OcrReviewScreen 的 tap-to-open-sheet 模式）
**Notes:** Voice 屏不常驻 SmartKeyboard。Amount 编辑走 AmountEditBottomSheet 弹出模式，与 TransactionEditScreen 和 OcrReviewScreen 保持一致。

### Q1.3: voice 屏上，用户点 form 里的文字字段（merchant/note）开始输入时，录音态怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 文字输入不影响录音状态（并行） | 录音中点 TextField：soft keyboard 弹起 + KeyboardToolbar 出现；录音继续 | |
| 文字输入自动暂停录音 | TextField onFocus → 自动调 mic 停止、waveform 隐藏；用户处理完点 Done 后需手动重启录音 | ✓ |
| 文字输入期间 mic 被禁用 | 用户聊「应当」样：要么在说（mic on，所有 TextField readOnly），要么在输字（mic 不可点） | |

**User's choice:** 文字输入自动暂停录音
**Notes:** UX 简单可预测，避免用户输入被语音误覆盖。重启需用户主动长按 mic。

### Q1.4: voice 屏上的 Save 入口放哪？

| Option | Description | Selected |
|--------|-------------|----------|
| 底部 mic 上方/下方的独立 Save 按钮（今天 VoiceInputScreen 的 Next 改名成 Save） | 在 mic 按钮上方保留全宽渐变 Save 按钮 | ✓ |
| AppBar 右上角 Save action（文本按钮） | iOS 风格 AppBar action | |
| 复用 KeyboardToolbar，仅在输入/sheet 开启时出现 | Voice 屏不设独立 Save，只在 TextField focus 或 AmountEditBottomSheet 弹出时出现 toolbar | |

**User's choice:** 底部 mic 上方/下方的独立 Save 按钮
**Notes:** 与今天 VoiceInputScreen 的 Next 按钮位置一致；改名 + rewire 即可。Save 状态：disabled until form valid。

---

## Area 2 — 录音按钮交互模型

### Q2.1: 录音按钮选哪个交互模型？（REC-01 要求全应用唯一且明确）

| Option | Description | Selected |
|--------|-------------|----------|
| tap-to-toggle（保留现状） | 点一下开始、再点一下停；idle caption 锁定为「点击开始录音 / タップして録音を開始 / Tap to start recording」 | |
| hold-to-record（按住说话） | 按住 mic 录音、松手停止；idle「按住说话 / 押して話す / Hold to speak」 | ✓ |
| tap-to-toggle + 长按 = 取消本轮录音 | 主交互 tap-to-toggle；长按 mic 表示「取消（丢弃录下的语音→返回 idle）」 | |

**User's choice:** hold-to-record
**Notes:** 走 push-to-talk walkie-talkie 路线，物理一致性更高。code 需重写 GestureDetector 为 onLongPressStart/End/Cancel 组合。

### Q2.2: hold-to-record 的"松手"语义怎么定？

| Option | Description | Selected |
|--------|-------------|----------|
| 松手 = 停录音，但不自动 save（用户点 Save 按钮才提交） | 松开 mic 后只是 cancel listen + commit 最后一批 final result 到 form；Save 需用户主动点底部 Save 按钮 | |
| 松手 = 停录音 + 自动 save（一手完成） | 松开 mic 后 cancel listen，然后几百毫秒 settle 后自动调 submit() 入库 | |
| 松手 = 停录音；跳过误触（< 300ms 丢弃本次录音） | 松开 mic 后 cancel listen。额外加个误触门槛：按住时长 < 300ms → 丢弃本次录音的任何 result（不回写到 form），以免手指拂过意外启动。不含自动 save 逻辑；save 仍要手动点 Save 按钮 | ✓ |

**User's choice:** 松手 = 停录音；< 300ms 误触丢弃；save 仍需手动
**Notes:** 防误点 + 给用户检查 form 的机会。误触阈值 300ms 来自 Material 长按识别器默认。

---

## Area 3 — voice → form 回填时机

### Q3.1: voice 识别出的值什么时候落进 form 字段？

| Option | Description | Selected |
|--------|-------------|----------|
| 实时：每个 final result 到达就马上回写（录音中表单会动） | merger commit amount 后立即 formKey.updateAmount；resolver 出 categoryId 后立即 updateCategory；merchant 同 | |
| 松手后 batch：录音停后一次性回写全部字段 | 录音期间 form 不动；松手 stop listen 后，可能几百毫秒内一次性把最终 amount/category/merchant/note 都回写到 form | ✓ |
| 预览条：识别结果先在表单上方准预览查看；用户点"填入表单"才 commit | 识别结果出现在 form 上方临时预览 row + "使用该结果"按钮；用户点击后 form 才被填充 | |

**User's choice:** 松手后 batch
**Notes:** 与 hold-to-record 的"说-松-看结果"心智模型一致，避免录音中表单跳动。

### Q3.2: batch 回写时碰到"用户已手动输入过的字段"，voice 怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 语音总是覆盖（"最后一次说话赢"） | 所有字段被 voice 识别结果覆盖（只要 voice 识别出了对应字段） | ✓ |
| 语音只填空字段，不动已有内容的字段 | 每个字段检查 form 现存 value：空（或 0/null）才填；金额需要一个"未输入"哨兵 | |
| 语音覆盖 + 保存 undo snapshot（覆盖后弹 SoftToast"已填充 N 字段 / 撤销"） | 表单被 voice 覆盖前先 snapshot 一份；覆盖后弹 SoftToast 给几秒机会点撤销 | |

**User's choice:** 语音总是覆盖
**Notes:** 规则最简单，用户可重新输入修改。不实现 snapshot/undo。

---

## Area 4 — 录音中状态视觉 + 100ms 时序

### Q4.1: 录音中状态 mic 按钮怎么变？

| Option | Description | Selected |
|--------|-------------|----------|
| 颜色变红 + 同 Mic icon + 脉冲光晕（轻量） | idle 绿渐变 + 白 Mic icon；recording 红渐变 + 同 Mic icon + 外圈 BoxShadow blurRadius animated 脉冲 | |
| Mic → Stop icon 变形 + 颜色变红 + 圆形保持 | idle Mic icon；recording Stop icon + 背景渐变换红。形状保持 72dp 圆 | |
| 圆形 → 圆角方形 变形 + 颜色变红 + Mic icon 不变 | idle 72dp 圆；recording 72dp 圆角正方形（borderRadius 16）+ 背景变红，icon 不变 | ✓ |

**User's choice:** 圆形 → 圆角方形 + 颜色变红 + Mic icon 不变
**Notes:** 形状变化 + 颜色变化 同步表达状态切换；icon 不变保持视觉锚点。不加脉冲（hold-to-record 物理接触已经表达"正在录音"）。

### Q4.2: 「录音中…」文案在哪里显示 + ja/en 译文锁什么？

| Option | Description | Selected |
|--------|-------------|----------|
| 换掉现有 mic 下方 caption（今天是 tapToRecord ARB key） | idle = holdToRecord 新 key（按住说话 / 押して話す / Hold to speak）；recording = recording 新 key（录音中… / 録音中… / Recording…）；AnimatedSwitcher fade | ✓ |
| Caption + waveform overlay text | mic 下方 caption 同上，另外在 waveform 动画区上叠一句"录音中…" | |
| Caption + button 内文字（mic icon 下面加老小字"REC"标示） | Caption 同上；button 内部 mic icon 下面加个 9pt 红色"REC"词 | |

**User's choice:** 换掉现有 mic 下方 caption
**Notes:** 单一位置、AnimatedSwitcher fade transition。新增 2 个 ARB keys，删除 tapToRecord（唯一用例就是 voice_input_screen.dart:572）。

### Q4.3: 100ms timing 什么纳入计时？另外 recording-state 要不要单独 golden？

| Option | Description | Selected |
|--------|-------------|----------|
| 从 onTapDown(按住触发) 到 setState 后 build complete；golden 要 idle + recording 两份 | stopwatch 起点 onLongPressStart 回调；终点 setState 后 build complete（pump 后）。Golden idle + recording 两张 | |
| 从 startListen 调用到 first AnimatedContainer rebuild 完成；只要 widget test 不要 golden | stopwatch 起点 _speechService.startListen() 后；只测业务逻辑时间不含物理传感器延迟。无 golden | |
| 两者都要 + 只要 idle 的 golden（recording 状是 animation-frame，不适合 golden） | Timing 同选项 1；golden 只抓 idle 状。Recording 状变化用 Decoration 断言验证 | ✓ |

**User's choice:** 两者都要 + 只要 idle 的 golden
**Notes:** Recording 状是动画 frame 不适合 golden；用 widget test expect Decoration / borderRadius / Color 来断言。Timing 测试用 Stopwatch 包 setState → tester.pump()。

---

## Claude's Discretion

User did not say "you decide" outright; the following are minor implementation choices the planner can finalize without re-asking:

- 录音中按钮渐变红色具体 hex（建议从 AppColors.error 家族选；不合适则新增 AppColors.recordingStart/End）
- AnimatedContainer / AnimatedSwitcher 动画时长（180ms / 150ms 是 Material 基线；±50ms 内可调）
- Save 按钮 enable 判定（`_formKey.currentState?.canSubmit` vs `category != null && amount > 0`）
- `updateNote` 方法在 v1.3 的来源（no-op forward-compat、删除、或从 voiceKeyword 剩余文本提取）
- `_pressStart` 状态字段位置（state field vs closure capture）
- `_navigateToConfirm` + `_extractVoiceKeyword` 方法的删除 vs 重命名 vs 重组

## Deferred Ideas

- MOD-005 OCR writer landing — v1.4+
- English voice input accuracy gates — v1.4+
- 录音中视觉脉冲 / 呼吸动画 — v1.4+ 若用户反馈"不确定是否在录音"
- 触觉反馈（haptic feedback）on long-press start/end — v1.4+，需 ADR
- TextField blur 后自动 resume 录音 — v1.4+ 若用户反馈手动重启太烦
- Voice undo last batch fill — v1.4+ 若 D-8 严格覆盖被反馈为问题
- 第二个 voice surface（如 home recent-tx tile 上的语音 quick-edit）— 若加，必须用 hold-to-record（D-03 绑定）
- WhatsApp-style "slide up to cancel" 手势 — v1.4+
- Per-screen Save 按钮形态统一 — v1.3 接受 manual SmartKeyboard inline Save vs voice 底部 CTA 的分歧
