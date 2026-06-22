# Quick Task 260622-nhs · 修订 R2 — 语音记录改为「点击·自动填表弹窗·重置恢复」

**日期:** 2026-06-22
**前置:** R1 已实现 hold-to-talk 单页 PTT（commit `4c651bbc..b68f6ccf`）。真机发现底部长条贴 iOS 手势区
难按；经多轮设计 review，最终交互模型改版（见 `mocks/entry-voice-auto-modal.html` —— 终稿，已 review 通过）。
**范围:** 仅数字键盘态（N1）。文字输入态工具条入口本次不做。

---

## 终版交互（LOCKED — 依据 `mocks/entry-voice-auto-modal.html`）

### 1. 底部长条：`HoldToTalkBar` → 点击式「语音记录」
- **位置：移到 SmartKeyboard 上方**（不再在键盘下方贴底）。当前 bug：长条是 keyboard 下方最后一个子节点、
  且无底部 inset → 落在 iOS Home/上滑手势区。修复：长条置于键盘**上方**；并给底部补 `SafeArea`/
  `MediaQuery.viewPadding.bottom` inset，使键盘整体抬离手势区。
- **手势：press-and-hold → 单击 `onTap`。** 不再 hold。
- **文案：「语音记录」**（更新 ARB `holdToTalkBar` 值为「语音记录」/ja/zh/en，或新增 `voiceRecordBar` 键并弃用旧键 —— 二选一，保持单一来源、无孤立键）。
- **图标：线条描边 mic** → 用 `Icons.mic_none`（非填充 `Icons.mic`）。
- 仍随键盘显隐（`_showSmartKeypad` 为 false（文本框聚焦）时隐藏；本次文本态不加入口）。

### 2. 聆听弹窗：`VoiceListeningOverlay` → 自动填表 modal（无完成/无取消）
- 结构（上→下）：抓手 → `● 正在聆听…`（脉冲红点）→ 实时转写 → 16 波形(`VoiceWaveform`) →
  录音红圆角麦克风(`Icons.mic_none` 白、recordingGradient) → **简短提示「轻点空白处退出」（在麦克风正下方）** →
  **唯一按钮「🔄 重置 · 恢复账目」**（线条 restore 图标）。
- **去掉「完成」「取消」按钮。**
- **轻点弹窗任意处（或点遮罩）= 退出**：停止聆听 + 关闭弹窗 + **保留已填内容** + 停留当前页（D-2 不自动保存）。
- **重置按钮**点击**不冒泡到退出**（自身 onTap 拦截）。

### 3. 会话逻辑（mixin）：tap-toggle + 自动填表 + 快照还原
- **startSession（点长条）**：先对当前表单**取快照**
  （amount / category / merchant / date / satisfaction / foreign-triple / currency），再开始**持续**识别、升起 modal。
- **自动填表**：每次 speech final 结果（沿用现有 `parse` + `chunk merger` 2.5s 窗口）即**实时 batch-fill**
  到同一张表单（updateAmount/Category/Merchant/Date/Satisfaction/CurrencyTriple）。**无需点完成**。
  上方金额药丸/外币 triple 同步反映（沿用 R1 的 host-cache 镜像 + `_pushVoiceForeignTriple`）。
- **exitSession（轻点弹窗/遮罩）**：停止识别、flush merger 做最终填充、关闭 modal、保留内容、停留。
- **resetSession（重置键）**：把表单**还原到 startSession 的快照** + 清空转写/merger/parseResult + **继续聆听**（可重说）。
- **无 cancel/discard 语义**（无取消按钮）；放弃整笔仍走 AppBar `×`。
- 关闭时停止录音、释放识别资源；保留 app-lifecycle pause / 锁屏 / 超时 / 文本框聚焦 的取消逻辑。
- `EntrySource.voice` 溯源：自动填表后落库行仍标 voice（沿用 R1 `_lastFillWasVoice`）；重置还原后若快照是纯手工则回 manual。

### 4. 旧独立语音页 `voice_input_screen.dart`（retained, 未路由）
- **保持现有 hold-to-record 行为与全部既有测试零改动通过。** 新的 tap-modal/自动填表/快照是 manual 屏专用的
  附加路径；共享底层识别/解析/填表/外币/满意度原语，不回归旧屏语义。若改动 mixin 公共面，确保旧屏仍编译且测试绿。

---

## 项目 gate（每步遵守）
- 严格 TDD：先改/加测试（RED）再实现（GREEN）。
- `flutter analyze` 0；**全量** `flutter test` 绿（架构测试 hardcoded_cjk_ui_scan / color_literal_scan / arb_key_parity / provider_graph_hygiene 必跑）。
- UI 文案全部走 `S.of(context)`；ja/zh/en 三 ARB 同步 + `flutter gen-l10n`；`lib/generated/` `git add -f`。
- 无裸 hex（color_literal_scan）—— 仅 `context.palette.*`。线条图标用 Material `Icons.mic_none` 等。
- golden：macOS 仅重基线**受影响**项（manual 屏：长条移位 + 新外观「语音记录」；新/改 modal）。不要 blanket。
- 文件 < 800 LOC（`manual_one_step_screen.dart` 现 954，已超；本次尽量不再增，能抽则抽，至少不恶化）。
- Riverpod 3 约定；providers 不抛 UnimplementedError；immutability。

## 必过 must_haves
- 长条在键盘**上方**、点击触发、文案「语音记录」、线条 mic、底部已补 SafeArea（不再压手势区）。
- 点长条 → modal 免持聆听；说一句**自动**填入金额/分类/商家/日期；轻点弹窗/遮罩**退出并保留**、停留不自动保存。
- 「重置·恢复账目」还原到说话前快照 + 清空转写 + 继续聆听；点重置不退出。
- 弹窗**无完成/取消**；提示「轻点空白处退出」在麦克风下方。
- 外币 triple / 悦己满意度 / JPY-native / chunk merger 行为不回归；旧 voice_input_screen 测试零改动绿。
- analyze 0；full test 绿；三 ARB parity；受影响 golden 重基线。

## 提交（原子）
- `refactor(260622-nhs): voice session → tap-toggle + form snapshot/restore`
- `feat(260622-nhs): tap voice-record bar above keypad (line mic) + safe-area`
- `feat(260622-nhs): auto-fill listening modal (tap-exit, reset-restore)`
- `test(260622-nhs): ...` / golden 重基线
