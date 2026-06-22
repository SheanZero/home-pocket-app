---
quick_id: 260623-0cj
title: 数字小键盘重设计 — 语音键椭圆化(200dp 居中胶囊) + 底排降高(40dp)
type: refactor
scope: ui-layout-only
status: complete
branch: main
worktree: false
commit: db828168
gate:
  analyze: 0
  test: 3137 passed / 0 failed
  goldens: 10 re-baselined (6 smart_keyboard matrix + 4 dot-gating), macOS
  palette_only: true (no raw hex; joyLight/joyText/daily/FAB tokens + withValues)
  arb: none (reused l10n.voiceRecordBar)
  codegen: none (no @riverpod/@freezed/Drift/ARB change)
human_verify: pending  # 真机确认椭圆/底排观感
design_gate: HTML mock approved (mocks/numpad-voicekey-midpoint.html · 方案 M, width 200dp)
---

# 260623-0cj · 数字小键盘重设计 — 语音键椭圆 + 底排降高

## Design-first

先出 HTML 设计稿，经用户两轮确认后再写代码：

- `mocks/numpad-redesign.html` — 现状 vs 方案 A（居中小胶囊）vs B（内缩宽胶囊），
  两案底排都 −23%。
- `mocks/numpad-voicekey-midpoint.html` — A / **中间值 M** / B 三宽度并排。
  用户定：**M、宽 200dp**；底排 **40dp 没问题**。

## What changed (code = commit db828168)

### ① 语音键椭圆化 — `hold_to_talk_bar.dart`（`VoiceRecordBar`）
- 满宽 38dp `joyLight` 色带（贴左右边 + 下边线）→ **居中 200×40 椭圆胶囊**：
  `Material(color: joyLight, shape: StadiumBorder(side: joyText@18%), elevation: 1)`
  + `InkWell(customBorder: StadiumBorder)`，外层
  `Container(key: voice-record-bar, padding: vertical 8, alignment: center)`。
- 胶囊浮在 cream 屏背景上、白色键盘卡片之上，左右各内缩 ~95dp（390 宽时）→ **不顶边**。
- **胶囊本身是唯一点击区**（原先整条贴边都可点；现在只有胶囊响应 onTap）。
- `Icons.mic_none` + `l10n.voiceRecordBar` 文案/配色不变；新增 `voice-record-pill` key。

### ② 底排降高 — `smart_keyboard.dart`（`SmartKeyboard._buildActionRow`）
- build() 新增 `bottomRowHeight = max(40, keyHeight × 0.77)`，传入 `_buildActionRow`
  （删除/¥货币/保存三键共享，互相等高 D-08 不破）。
- 数字行 + extra 行（00/0/.）仍用原 `keyHeight`（≥48dp 下限不动）。
- 效果：iPhone 14（390×844, padding 34）数字键 ≈51dp、底排 = max(40, 39.4) = **40dp**；
  大屏（keyHeight≥52）按 0.77 比例略增，永不低于 40dp。

## What did NOT change
- 数字键 1–9 / 00 / 0 / . 尺寸·配色·间距·tabular 字形、列间距 6dp、行间距 12dp。
- 键盘卡片 `palette.card` + top border、保存键 FAB 樱粉渐变、货币键绿、48dp 数字下限。
- `VoiceRecordBar` 在 `manual_one_step_screen` 中的位置（仍是 `SmartKeyboard` 上方的兄弟）。
- 语音面板（`VoiceRecordPanel`）、PTT 会话逻辑、`manual_one_step_screen.dart` 全未触及。

## TDD
- RED：`hold_to_talk_bar_test`（无 `voice-record-pill` key）+ `smart_keyboard_test`
  TEST 1b（底排 == 数字键 51.12，非更短）双失败。
- GREEN：实现后两文件全绿（11 tests）。
- TEST 1 48dp 下限收窄到数字/extra 键；TEST 5（三动作键互等高 D-08）保持绿。

## Gate
- `flutter analyze`：**0 issues**（全项目）。
- `flutter test`（全量）：**3137 passed / 0 failed**（含 architecture + golden）。
- Golden：**10 重基线**（macOS）——
  `smart_keyboard_{ja,zh,en}_{light,dark}`（6）+ `smart_keyboard_dot_{enabled_usd,gated_jpy}_{light,dark}`（4）；
  底排变矮所致。`voice_input_screen_mic_button_idle` golden 作用域在 `voice-mic-button`
  子树、不含键盘 → 未变、未重基线。`VoiceRecordBar` 无 golden 覆盖（仅 widget 断言）。
- palette-only：无新裸 hex；胶囊边/影用 `palette.joyText.withValues(alpha:)`。

## On-device verification (human · pending)
1. **语音键椭圆** — 记账录入页键盘顶部出现居中樱粉椭圆胶囊「🎙 语音记录」，
   左右明显留白、不贴边；点胶囊升起语音面板，点胶囊外的留白区不触发。
2. **底排更矮** — 最下一排（删除 / ¥JPY / 保存）明显比数字键矮一截（~40dp），
   保存键樱粉渐变仍清晰可点。
