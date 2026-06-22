# 语音面板中央方块双状态按钮（删底部重置键 + 两态等高）

**日期:** 2026-06-22
**时间:** 23:35
**任务类型:** 重构 / UI 布局微调
**状态:** 已完成（待真机验证）
**相关模块:** MOD-001 基础记账 — 单页语音输入面板（quick 260622-nhs R7）

---

## 任务概述

R6 之后的布局微调：把语音面板的「重置」从底部独立按钮并入中央方块，使方块成为双状态按钮 —— 录音中=灰底麦克风（被动指示，不可点）；停止时=红底重置图标（可点 = 重新录入）。删除底部重置按钮，删去「· 恢复账目」文案，并保证两态面板等高、切换不跳动。功能（onReset 语义）完全不变。

---

## 完成的工作

### 1. 主要变更

- `lib/features/accounting/presentation/widgets/voice_listening_overlay.dart`
  - 删除底部 `voice-panel-reset` 重置按钮整体。
  - 中央方块抽成 `_CentralSquare`，按 `status` 双状态：
    - listening / processing → 灰底（`backgroundMuted`）+ 线条麦克风 `Icons.mic_none`（`textTertiary`），**被动**（无 GestureDetector，点击冒泡到面板 onExit）。
    - stopped → 红底（`recordingGradient*`）+ 重置图标 `Icons.restore`（白），**可点** → `onReset`，且不冒泡到 onExit（key `voice-square-reset`）。
    - 尺寸 74dp / 圆角 22。
  - 「点击重置重新录入」提示行改用 `Visibility(maintainSize/maintainAnimation/maintainState, visible: stopped)` 保留占位 → 两态等高，「轻点空白处退出」在两态同一垂直位置。
- `lib/l10n/app_{ja,zh,en}.arb`：删除 `voiceResetRestore` / `voiceResetRestoreSub`（底部按钮已删，无其他引用），`flutter gen-l10n` 重生成，`git add -f lib/generated/`。

### 2. 技术决策

- **灰底/灰麦克风配色**：复用现有 palette token（`backgroundMuted` + `textTertiary`），不新增 token、不内联裸 hex。设计稿的 `#EAEDEC`/`#9AA8A0` 与现有暖色 token 仅有细微冷暖差异，属外观层面；按 FIX-R7「优先复用现有 token」要求复用，保持 palette-only。
- **等高实现**：用 `Visibility(maintainSize:true)` 而非 `if (stopped)`，后者会塌缩高度导致切换跳动。

### 3. 代码变更统计

- 源码 1 文件、测试 2 文件、ARB 3 文件、生成 4 文件。
- 提交 2 个：
  - `f1e6cb36` refactor — 面板双状态方块 + 删底部按钮 + 测试更新
  - `d4e335d4` chore — 删 ARB + 重生成 l10n

---

## 遇到的问题与解决方案

### 问题 1: 「R2 重置 restores while listening」测试与新设计冲突
**症状:** 旧测试在 listening 态点 `voiceResetRestore` 文案触发重置，但 R7 下 listening 态无重置入口。
**原因:** 重置触发位置从底部按钮（任意态）改为红方块（仅 stopped 态）。
**解决方案:** 测试改为先让识别器自终止（emit `done`）进入 stopped，再点红方块（`voice-square-reset` key）。重置语义（cancel + 重启 fresh listen）零改动，断言不变。

---

## 测试验证

- [x] `flutter analyze` 0 issues
- [x] 面板单测 9/9 绿
- [x] manual_one_step_screen 21/21 绿
- [x] **全量** `flutter test` 3132/3132 绿（含架构测试 / hardcoded CJK scan / golden 平台门）
- [x] golden 无需重基线（面板视觉变更由 widget 断言覆盖，无 golden 触及该面板）
- [ ] 真机验证（PENDING — 见 SUMMARY-R7 human_verify）

---

## Git 提交记录

```bash
f1e6cb36 refactor(260622-nhs): voice panel — central square dual-state button, drop bottom reset
d4e335d4 chore(260622-nhs): remove 「· 恢复账目」 reset sublabel ARB
```

---

## 后续工作

- [ ] 真机复验 2 点：① 灰麦克风/红重置方块按状态切换 + 红方块点击=重新录入；② 两态面板等高不跳动。

---

## 参考资源

- FIX 规格：`.planning/quick/260622-nhs-entry-voice-switch-redesign/260622-nhs-FIX-R7.md`
- 设计稿：`.planning/quick/260622-nhs-entry-voice-switch-redesign/mocks/entry-voice-square-button.html`

---

**创建时间:** 2026-06-22 23:35
**作者:** Claude Opus 4.8
