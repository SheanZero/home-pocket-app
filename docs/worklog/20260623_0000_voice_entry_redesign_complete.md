# 记账录入语音录入重设计 — 整体完成并验收（quick 260622-nhs）

**日期:** 2026-06-23
**任务类型:** 功能开发 / 重构 / UI 设计
**状态:** ✅ 已完成 · 用户真机验收通过（approved）
**相关模块:** MOD-001 基础记账（语音录入）

---

## 任务概述

重新设计记账录入界面，让手工/语音输入切换更顺。经设计 review 与 8 轮真机迭代，最终落地为
**单页、无模式切换、点击「语音记录」进入免持聆听弹窗、自动填表、轻点退出、中央方块双状态（录音/重置）** 的语音录入体验。

---

## 最终交互（落地态）

- 单页录入，取消头部「手工/语音」Tab；自然手工键盘常驻。
- 键盘上方一条「语音记录」长条（线条 mic，点击触发，避开 iOS 底部手势区 + SafeArea）。
- 点击 → 聆听面板**就地替换键盘**（无浮层、不灰背景）：上区状态/转写/波形 — 中央方块（垂直居中）— 下区提示。
- 说一句**自动填表**（金额/分类/商家/日期/满意度 + 外币 triple），亚秒级 partial 实时更新。
- 一次性聆听：识别器结束 → 状态「停止聆听」、中央方块变红 + 重置图标（点击 = 还原快照 + 重新录入）；录音中方块为灰 + 麦克风（被动）。
- 轻点空白处退出（保留已填内容、不自动保存，D-2）。

---

## 8 轮迭代摘要（22 个代码 commit）

| 轮 | 内容 |
|---|---|
| R1 | 抽 `VoicePttSessionMixin` 复用语音逻辑；hold-to-talk 单页 PTT；移除切换 Tab/语音路由 |
| R2 | 改点击式自动填表弹窗（线条 mic、轻点退出、重置还原快照） |
| R3 | 真机修 3 bug：长条融入键盘上方 + SafeArea、重置续听、弹窗就地替换键盘（去 scrim/浮层） |
| R4 | 修生命周期：重置清识别器 buffer + 重启、防假死（串行化）、实时状态、partial 实时填表提速 |
| R5 | 连续会话 `onError`：瞬时 no-match 不锁 bar/不 toast、状态同步 stopped、致命错误恢复 bar |
| R6 | 一次性聆听（停止聆听 + 点击重置提示）；修金额解析 99999→9（解析器多位阿拉伯数字 + 逗号） |
| R7 | 中央方块双状态按钮、删底部重置键、两态等高、删「· 恢复账目」ARB |
| R8 | 中央方块垂直居中 + 面板增高至 356dp（上下区 1:1 等分） |

---

## 验证

- `flutter analyze`：0 issues（每轮独立复核）
- 全量 `flutter test`：最终 **3136/3136 通过**（含架构测试 hardcoded_cjk_ui_scan / color_literal_scan / arb_key_parity / provider_graph_hygiene）
- golden：macOS 仅在受影响处重基线
- 旧 hold 语音屏（voice_input_screen）全程零改动绿
- 用户真机验收通过（approved）

---

## 后续

- [ ] `manual_one_step_screen.dart` 现 1020 LOC，超 CLAUDE.md 800 上限（累积）。建议另开 follow-up 把语音接入/键盘区抽成 widget 压回 800 以下（无自动 size lint，非阻塞）。

---

## 设计稿（保留为历史）

`.planning/quick/260622-nhs-entry-voice-switch-redesign/mocks/`：
`entry-ptt-designs` / `entry-ptt-safezone-designs` / `entry-ptt-textinput-state` / `entry-ptt-tap-modal` /
`entry-voice-auto-modal` / `entry-voice-panel-redesign` / `entry-voice-square-button`（终稿）。
