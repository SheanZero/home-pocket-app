# Quick Task 260714-qit: 实现 v15 mockup 四页面（A1 浅色 / A3 深色）- Context

**Gathered:** 2026-07-14
**Status:** Ready for planning

<domain>
## Task Boundary

实现 `whole-app-warm-japanese-v15.html`（路径：`.superpowers/brainstorm/78061-1783676135/content/whole-app-warm-japanese-v15.html`）中 **A1 个人·浅色** 与 **A3 个人·深色** 两套主题下的四个页面，替换现有对应页面：

| Mockup screen (data-screen) | 中文 | 现有 Flutter 入口文件 |
|---|---|---|
| `home` | 主页 | `lib/features/home/presentation/screens/home_screen.dart` |
| `list` | 明细 | `lib/features/list/presentation/screens/list_screen.dart` |
| `analytics` | 统计 | `lib/features/analytics/presentation/screens/analytics_screen.dart` |
| `shopping` | 购物 | `lib/features/shopping_list/presentation/screens/shopping_list_screen.dart` |

范围 **仅这四个页面**。mockup 中的其他 screen（entry/voice/ocr/settings/family/onboarding 等）不在本轮范围。
</domain>

<decisions>
## Implementation Decisions (LOCKED — 用户已确认，不要重新讨论)

### D-01 执行规模：分屏分批 + 校验
- 按页面拆分为独立任务（主页 / 明细 / 统计 / 购物），**每个页面一个聚焦的 executor**，逐屏实现，避免单个 executor 上下文撑爆导致漏实现。
- 启用 `--validate` 语义：plan-check（≤2 轮）+ 完成后 verification。
- 页面之间若有共享基础改动（主题 token / 共享 widget / ARB），planner 应把它抽成一个**先行的 foundation 任务**，在四个页面任务之前完成。

### D-02 保真口径：视觉高保真移植（NOT 像素级硬对齐）
- 忠实复刻 v15 的**布局、间距、圆角、配色、字号、组件形态、状态（空/加载/错误）**，把 HTML/CSS 结构映射到**等价 Flutter widget**。
- **保留现有数据接线**（providers / repositories / 真实数据流），只改 **presentation 层**（screens / widgets）。不得为了对齐外观而写死数据或破坏 provider 图。
- A1 与 A3 是**同一套布局的浅色/深色两种主题渲染**，不是两套独立布局。深色必须通过 `context.palette`（`AppPalette.light`/`AppPalette.dark`，见 `lib/core/theme/app_palette.dart`）派生 —— **禁止硬编码颜色**。实现每个页面时用 palette token，两套主题应自然成立。

### Claude's Discretion
- 每个页面内部的 widget 文件拆分粒度（遵循 CLAUDE.md「many small files」，200–400 行/文件）。
- 是否新增 ARB 文案键（尽量复用现有；确需新增则同步更新 ja/zh/en 三份并 `flutter gen-l10n`）。
- golden 基线更新策略（浅色+深色都要更新；goldens 仅在 macOS 基线，见项目 golden CI 门）。
</decisions>

<specifics>
## Specific References

- **Mockup 源文件：** `.superpowers/brainstorm/78061-1783676135/content/whole-app-warm-japanese-v15.html`
  - A1 preset：`data-preset="solo-light"`；A3 preset：`data-preset="solo-dark"`（文件顶部 `:root` / `.dark` CSS 变量定义两套主题值）。
  - 四个页面的渲染函数：`home`(≈911 行 `home-faithful`)、`list`(≈976/995 行 `list-transaction`/`tabHeader`)、`analytics`(≈1088 行)、`shopping`。
- **参考截图（可用于逐屏比对）：** `.planning/sketches/audits/home-v15/`、`.planning/sketches/audits/v15-shopping-*`、`.planning/sketches/audits/home-v15-amount-type/`。
- **主题机制：** `lib/core/theme/app_palette.dart`（`AppPalette.light`/`.dark`）、`app_theme.dart`、`context.palette` extension。金额用 `AppTextStyles.amountLarge/Medium/Small`（含 tabularFigures）。
</specifics>

<canonical_refs>
## Canonical References

- **ADR-019 桜餅×若葉 (Sakura Mochi × Wakaba)** — 当前 LIVE 调色板；mockup 的 `--primary: #6FA36F`（若叶绿）与 ADR-019 一致。`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`。
- **CLAUDE.md 强约束：** UI 文案走 `S.of(context)`（禁硬编码字符串）；日期走 `DateFormatter`；货币走 `NumberFormatter`；颜色走 `context.palette`（禁硬编码色值）；金额走 `AppTextStyles.amount*`；`flutter analyze` 必须 0 issue；改注解类后跑 build_runner；改 ARB 后跑 `flutter gen-l10n`。
</canonical_refs>
