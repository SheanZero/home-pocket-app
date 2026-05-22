# Phase 19: Manual One-Step + Keypad Polish - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-22
**Phase:** 19-Manual One-Step + Keypad Polish
**Areas discussed:** Single-screen layout + Save button placement, Keypad polish — touch target + visual hierarchy, Persistent keypad vs system soft keyboard handling, Embedding approach + legacy screen disposition + field affordances

---

## Single-screen layout + Save button placement

### Q: 一屏的顶层拓扑怎么摆？金额显示 + 6 个详情字段 + SmartKeyboard、从上到下怎么排？

| Option | Description | Selected |
|--------|-------------|----------|
| 上下分区、键盘常驻 | 上半部：AmountDisplay + 6 个详情字段一个 SingleChildScrollView。下半部：SmartKeyboard 固定贴底。 | |
| AmountDisplay 常驻，键盘是 sheet | 详情字段满中间，SmartKeyboard 默认隐藏，tap AmountDisplay 才从底弹出 modal bottom sheet。 | |
| 金额与详情同屏，键盘双模式 | AmountDisplay 与详情同屏（详情区可滚），SmartKeyboard 默认贴底；textfield focus 时自动滑出屏。金额 focus 才返回。 | ✓ |

**User's choice:** 金额与详情同屏，键盘双模式

---

### Q: Save 按钮放哪里？

| Option | Description | Selected |
|--------|-------------|----------|
| 替换 SmartKeyboard action row 的 Next | Next 渐变按钮就地改文案成「记账/Save」。身体记忆一致。 | ✓ |
| 全宽底部独立 CTA | SafeArea + Padding + 渐变全宽按钮贴底（TransactionConfirmScreen 风格）。 | |
| 两者都要：keyboard Next + 软键盘 toolbar 上的「完成」按钮 | SmartKeyboard 上保留 Next/save；TextField focus 时软键盘顶部加 toolbar 含 save 入口。 | |

**User's choice:** 替换 SmartKeyboard action row 的 Next

---

### Q: 详情区在一屏如何呈现？6 个字段按什么分组/顺序摆？

| Option | Description | Selected |
|--------|-------------|----------|
| 按账本类型分组：Ledger toggle 顶部 + 两列 chip | LedgerTypeSelector 顶部 + DetailInfoCard 含 date/category chip 两列 grid，merchant/note 为两个 TextField，仅 soul 时加 satisfaction 行。 | ✓ |
| DetailInfoCard 密集列表（6 行紧凑） | 一个 card、6 行 DetailInfoRow，扫读快但 TextField 不适合 chevron-row 布局。 | |
| 分区卡片：金额区 + Meta 卡 + Notes 卡 | 金额+ledger+satisfaction 一卡；date/category/merchant 一卡；note 一卡。 | |

**User's choice:** 按账本类型分组：Ledger toggle 顶部 + 两列 chip

---

### Q: EntryModeSwitcher (Manual/OCR/Voice tabs) 在一屏化后怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 保留不动 | EntryModeSwitcher 仍在 manual 一屏顶部，Phase 22 同步处理 voice 一屏化。 | ✓ |
| 移出顶部，改为 AppBar icon 菜单 | AppBar leading/trailing 加 switch-mode 图标，点击弹底部 sheet 列 voice/ocr。 | |
| 移除换面入口，manual 单属于本屏 | 输入模式跳转走主 shell 的「+」菜单选。 | |

**User's choice:** 保留不动

---

### Q: TextField focus 时 SmartKeyboard 下滑出屏的过渡怎么调？

| Option | Description | Selected |
|--------|-------------|----------|
| 含动画的 AnimatedSlide/AnimatedPositioned | TextField focus listener 切换 _showSmartKeypad 布尔；SmartKeyboard offset Y 从 0 动画到 1。 | ✓ |
| 不动画、直接 Visibility/conditional render | _showSmartKeypad ? SmartKeyboard : SizedBox.shrink()。跳变明显，体验糙。 | |
| SmartKeyboard 始终贴底，软键盘叠加覆盖 | 软键盘自然覆盖 SmartKeyboard；不处理协同。 | |

**User's choice:** 含动画的 AnimatedSlide/AnimatedPositioned

---

## Keypad polish — touch target + visual hierarchy

### Q: _DigitKey 现高 48dp（Material min）。「键太低易误按」指向 bump 高度。目标高度取多少？

| Option | Description | Selected |
|--------|-------------|----------|
| 响应式：键盘取 ~2/5 屏高、按行平分 | Keypad 总高 = MediaQuery.size.height * 0.40，5 行均分后单键 ≈ 60-72dp。不同设备 thumb 可达区不同、响应式更公平。 | ✓ |
| 固定 64dp、中间路线 | _DigitKey height 48 → 64dp。始终足够高、表现一致；小屏详情区被压。 | |
| 固定 56dp、保守偏动 | _DigitKey 48 → 56dp（iOS 44 + Material 48 都达标、多出 8dp 安全边距）。可能仍不平息主观体验。 | |

**User's choice:** 响应式：键盘取 ~2/5 屏高、按行平分

---

### Q: 「邻键区分度」加强方式？现间距 8dp、背景 backgroundMuted。

| Option | Description | Selected |
|--------|-------------|----------|
| 拉大间距 → 12dp + 保留现 fill | 行间距 8→12dp；列间距 4→6dp（贴近 iOS 系统键盘）。fill 不变。资本代价低。 | ✓ |
| 加轻量 elevation + 增加对比 | _DigitKey 加 BoxShadow 轻亮面；fill 颜色加深与背景差 1 个 tier。粘后呆。 | |
| 加外边框 border | 每个键加 1.5dp border。明确可点击区域，但与 iOS 原生键盘风格不同。 | |

**User's choice:** 拉大间距 → 12dp + 保留现 fill

---

### Q: Action row（现高 50dp）与数字键高度间保持多大差异？

| Option | Description | Selected |
|--------|-------------|----------|
| 与数字键同均、save 渐变按钮路面加强 | Action row 高度跟随响应式，Save 保持现 gradient + shadow 诡异 hierarchy。⌫ 与 ¥JPY 同为 backgroundMuted。 | ✓ |
| Action row 独立高度（保留现 50dp） | 数字键不同高度（响应式 bump），action row 仍 50dp。 | |
| ⌫ 变成二级 size、不与 Save 同等重 | delete 键变小（iOS 计算器风格）；Save 变最大。可能反而误点击 ¥JPY。 | |

**User's choice:** 与数字键同均、save 渐变按钮路面加强

---

### Q: KEYPAD-01 SC-3 谈「golden test 覆盖 ja/zh/en 三语言 + light/dark 两主题」。现仓有哪些 golden？怎么加？

| Option | Description | Selected |
|--------|-------------|----------|
| 新增 SmartKeyboard golden 专项文件 | test/widget/.../smart_keyboard_golden_test.dart × (ja/zh/en) × (light/dark) = 6 个 golden。 | ✓ |
| 在 ManualOneStepScreen golden 里顺便覆盖键盘 | 不独立 golden SmartKeyboard，而是在 manual_one_step_screen_golden_test.dart 覆盖整个屏 × 6 拍。 | |
| 不加 golden，只补 widget test 质查 height = expected | 只加单元测试 size + spacing，调谁的 KEYPAD-01 SC-2 要求。 | |

**User's choice:** 新增 SmartKeyboard golden 专项文件

---

## Persistent keypad vs system soft keyboard handling

### Q: 「金额 focus」状态谁来维护？

| Option | Description | Selected |
|--------|-------------|----------|
| AmountDisplay tap = 金额 focus，tap textfield = textfield focus | _amountFocused 本地状态。AmountDisplay onTap → _amountFocused=true + unfocus 所有 textfield。TextField onTap → _amountFocused=false。默认 _amountFocused=true。 | ✓ |
| FocusNode 主导、AmountDisplay 不要 focus | 为 AmountDisplay 创建 virtual focusNode 注入到 FocusScope。表面上最 Flutter 世俗，但 AmountDisplay 本不是一个输入组件、focus 诡意表达重。 | |
| 三状态机：idle / amount / textfield | 加 idle 状态（进入画面默认不显键盘）。多一步才能输金额。 | |

**User's choice:** AmountDisplay tap = 金额 focus，tap textfield = textfield focus

---

### Q: TextField focus 时系统软键盘弹起、SmartKeyboard 下滑。此时 Save 按钮不可见。怎么给用户 save 入口？

| Option | Description | Selected |
|--------|-------------|----------|
| 软键盘顶 toolbar 完成/save | TextField 上加 Toolbar 顶部一个 Done/完成 + 一个「记账」按钮 → 同一 save handler。 | ✓ |
| FAB（floating action button）常驻右下角 | Save FAB 定位在软键盘之上 + safeArea。与 SmartKeyboard 上的 save 重复哪里点用户哑口。 | |
| 仅依赖 Done 关闭软键盘、软键盘上不加 save | Toolbar 只加 Done/完成（关 keyboard）。Save 只在 SmartKeyboard 上。 | |

**User's choice:** 软键盘顶 toolbar 完成/save

---

### Q: Toolbar 实现方式？

| Option | Description | Selected |
|--------|-------------|----------|
| 手写 Positioned + MediaQuery.viewInsets | MediaQuery.viewInsets.bottom 探知软键盘高度。Stack 里 Positioned 一个 44dp 高 toolbar，bottom = viewInsets.bottom。零依赖。 | ✓ |
| 引入 keyboard_actions pub package | Pub.dev keyboard_actions 包成熟。多一个 transitive 依赖。 | |
| 使用 Flutter InputDecoration suffix 加 save 图标 | 不加 Toolbar，只在 merchant/note TextField suffixIcon 加 save 图标。 | |

**User's choice:** 手写 Positioned + MediaQuery.viewInsets

---

### Q: Android 上软键盘高度不一、Scaffold.resizeToAvoidBottomInset 会 resize。SmartKeyboard 下滑有几种状态联动策略？

| Option | Description | Selected |
|--------|-------------|----------|
| resizeToAvoidBottomInset=false + 手动 padding | Scaffold(resizeToAvoidBottomInset: false)，详情区 Padding(bottom = max(viewInsets.bottom, smartKeypadHeight))。SmartKeyboard AnimatedSlide 让位。 | ✓ |
| resizeToAvoidBottomInset=true 默认、妥协详情区被压 | Flutter 默认行为：软键盘弹起 Scaffold body 被 resize。SmartKeyboard 仍装在 body 底部，被软键盘 push 上去。 | |
| Scaffold + bottomSheet | 把 SmartKeyboard 装进 persistentBottomSheet。状态与 Scaffold body 不同步、动画难控。 | |

**User's choice:** resizeToAvoidBottomInset=false + 手动 padding

---

## Embedding approach + legacy screen disposition + field affordances

### Q: Phase 18 D-01 承诺「Phase 19/22 都需 inline 嵌入 TransactionDetailsForm」。但那个 form widget 金额走 SmartKeyboard bottom sheet。Phase 19 一屏金额要 inline 常驻键盘、不是 sheet。怎么复用？

| Option | Description | Selected |
|--------|-------------|----------|
| 逆变：form 内部不错金额、amount 走 props in | TransactionDetailsForm 内部不再闭金额 editor。amount = external state；新增公开 method updateAmount(int) push 进去。Refactor form widget 保留原有 save/voice-correction 逻辑、仅去掉 amount editing 部分。 | ✓ |
| Phase 19 不复用 TransactionDetailsForm、手动贴字段 | Phase 19 ManualOneStepScreen 从零写、不复用 form widget。违背 Phase 18 D-01 承诺；业务代码重复。 | |
| TransactionDetailsForm 加个「inlineAmount: true」参数 mode | form 加 flag inlineAmount。若 true，form 不渲染 AmountDisplay。 | |

**User's choice:** 逆变：form 内部不错金额、amount 走 props in

---

### Q: TransactionEntryScreen（现首屏 manual 输入金额 + 下一步跳 TransactionConfirmScreen）怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 删除、main shell 「+」按钮直接跳新 ManualOneStepScreen | TransactionEntryScreen 不再存在。_initializeDefaultCategory 逻辑 verbatim copy 到新屏。git 删文件。 | ✓ |
| TransactionEntryScreen 重构为「手动一屏」 | 保留 class name、file path，重写内部 body 实现一屏逻辑。class name 表述不准确。 | |
| 保留 TransactionEntryScreen、加一个 one-step path 选项 | TransactionEntryScreen 作为 feature flag 老路径、ManualOneStepScreen 作为新路径。多多余裕 dead code。 | |

**User's choice:** 删除、main shell 「+」按钮直接跳新 ManualOneStepScreen

---

### Q: TransactionConfirmScreen 还被 voice_input_screen.dart:352 push，Phase 22 才还。Phase 19 怎么处理？

| Option | Description | Selected |
|--------|-------------|----------|
| 不动、加 deprecation comment 指向 Phase 22 | TransactionConfirmScreen 文件保留、voice_input_screen 还能 push。 | |
| 重构 voice_input_screen 使其不再 push TransactionConfirmScreen，Phase 19 同时完成 | （初选；后澄清为：voice 仍两步、第二步改为 push ManualOneStepScreen，voice 未并入全一屏） | ✓ |
| 不动、不加任何标记 | TransactionConfirmScreen 不变、零备注。 | |

**User's choice:** 重构 voice_input_screen 使其不再 push TransactionConfirmScreen（澄清为：仅 push 目标改为 ManualOneStepScreen，voice 仍两步；Phase 22 仍负责真正的 voice 一屏化）

**Notes:** Phase 22 INPUT-02/REC-01/REC-02 voice 一屏化需 Phase 20、21 完成。Phase 19 仅做 push target 替换的清理动作。

---

### Q: voice_input_screen 改为 push ManualOneStepScreen 后，TransactionConfirmScreen 不再被任何生产代码引用。Phase 19 要不要一道删除？

| Option | Description | Selected |
|--------|-------------|----------|
| Phase 19 一道删 TransactionConfirmScreen + 测试调整 | Phase 19 一道删除、变动 + Phase 18 刚刚补的 transaction_confirm_screen_test.dart 也调整。Phase 18 D-04 "retire when manual+voice flows collapse" 满足。 | ✓ |
| 保留作 dead code + deprecation 注释 | Phase 19 diff 更小，但 dead code 量增加。 | |
| 删除代码但保留原屏的零零碎碎 file path/route 壳 | 多一个间接层、避免 dead code 不如直接删除。 | |

**User's choice:** Phase 19 一道删 TransactionConfirmScreen + transaction_confirm_screen_test.dart 调整

---

## Claude's Discretion

- D-19: AnimatedSlide curve and duration (220ms / Curves.easeInOut) — Material motion baseline; planner may tune within ±50ms / similar curves.
- D-20: Responsive percentage (~40% of screen) — planner may bump to 42-45% if needed to keep ≥48dp floor on iPhone SE.
- D-21: KeyboardToolbar visual design (44dp height, "Done" left + "Save" right) — planner picks font weight / padding / button size details.
- D-22: `done` ARB key reuse — planner verifies existence, adds `keyboardToolbarDone` if missing.
- D-23: Backspace key (⌫) icon stroke weight at larger key sizes — planner may adjust if 22dp icon feels undersized.
- D-24: Where to extract `_initializeDefaultCategory` — port verbatim default; extract into helper only if it materially simplifies.

## Deferred Ideas

### Beyond Phase 19 (other v1.3 phases)
- Voice one-step integration (INPUT-02) — Phase 22.
- Record button UX (REC-01/REC-02) — Phase 22.
- Voice number parser strengthening (VOICE-01/02/03) — Phase 20.
- Voice category resolver level-2 enforcement (VOICE-04/05/06) — Phase 21.

### Beyond v1.3 (v1.4+)
- MOD-005 OCR writer landing.
- TransactionEditScreen UX redesign (decide whether to also adopt persistent keypad pattern).
- Sound/haptic feedback on key tap.
- Custom key arrangements (calculator-style operators, expression evaluator).
- Long-press behaviors (e.g., long-press 0 → 000).
- Persistent keyboard preference toggle.
- Drag-to-dismiss SmartKeyboard.
