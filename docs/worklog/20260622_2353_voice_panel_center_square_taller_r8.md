# 语音面板 R8 — 中央方块垂直居中 + 面板增高

**日期:** 2026-06-22
**时间:** 23:53
**任务类型:** 重构（纯布局）
**状态:** 已完成（真机验收 PENDING）
**相关模块:** [MOD-001] BasicAccounting — 语音录入面板（quick 260622-nhs R8，前置 R7）

---

## 任务概述

R7 在中央方块上做了双状态按钮（录音灰麦克风 / 停止红重置）。R8 是 R7 之后的
纯布局微调：把中央方块（面板核心）**垂直居中**，据此重排上下间距，并把面板
**整体增高**。无任何功能/交互/会话/解析逻辑改动。设计稿：
`mocks/entry-voice-square-button.html`（面板 356px、方块居中、两态等高）。

---

## 完成的工作

### 1. 主要变更

文件：`lib/features/accounting/presentation/widgets/voice_listening_overlay.dart`

- 面板主体改为固定高 `SizedBox(height: 356)`（原为内在高 ~287/296dp）。
- 内部 `Column` 三段：
  1. **上区**（状态行 + 转写 + 波形）放进 `Expanded(flex: 1)`，
     `mainAxisAlignment: center`。
  2. **中央方块** `_CentralSquare`（内容/逻辑不变）—— 作为两区之间的兄弟节点，
     落在面板垂直正中。
  3. **下区**（「点击重置重新录入」`Visibility(maintainSize)` 占位 +
     「轻点空白处退出」）放进 `Expanded(flex: 1)`，`mainAxisAlignment: center`。
  - 上下 1:1 等分 → 方块中心 = 面板中心。
- Container padding 调整为 `fromLTRB(18, 10, 18, 18)` 配合增高布局。

### 2. 不变项

方块双状态、状态行/脉冲点、转写、波形（动/静）、两条提示、就地替换键盘不灰背景、
`onReset`/`onExit` 语义 —— 全部不变。两态等高（固定高 + 下区占位）不跳动。

### 3. TDD

`test/widget/features/accounting/presentation/widgets/voice_listening_overlay_test.dart`
新增 4 个 R8 测试，先 RED 后 GREEN：
- 上下两个 `Expanded` 区存在且方块不在其内；
- 方块垂直中心 ≈ 面板中心（≤6px）；
- 面板高度 ≥340dp（比改前 ~296 高）；
- 两态等高、不跳动。

RED 实测：方块所在面板 296dp、无 Expanded 区、未居中 → GREEN 后通过。原 9 个
面板测试全程绿。

### 4. 代码变更统计

- 修改 2 个文件（widget + test），+349 / -159（含 `dart format` 重排）。
- `manual_one_step_screen.dart` 未触碰（1020 LOC，不在 diff 中）。

---

## 测试验证

- [x] `flutter analyze` 0 issue
- [x] 全量 `flutter test` 3136 passed / 0 failed（含架构测试 + golden tag）
- [x] palette-only（无新增 raw hex）
- [ ] 真机验收（PENDING）

Golden：无需重基线 —— 无 golden 直接渲染 `VoiceRecordPanel`；唯一 `*voice*`
golden（`voice_input_screen_mic_button_idle.png`）拍的是 idle 麦克风按钮，不受影响。

---

## Git 提交记录

```
Commit: 8685f019
refactor(260622-nhs): voice panel — center the square, taller panel, rebalance spacing
```

---

## 后续工作

- [ ] 真机两点复查：① 方块垂直正中；② 面板更高且两态等高、切换不跳动。
