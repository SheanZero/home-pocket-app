# Quick Task 260607-jrz: 首页月份选择改为弹窗式月份网格选择 - Context

**Gathered:** 2026-06-07
**Status:** Ready for planning

<domain>
## Task Boundary

将首页（主画面）的月份选择方式，从 header 上的左右翻月箭头（‹ ›，逐月步进），改为：点月份标签弹出一个「月份网格」对话框选择。参考用户截图：弹窗顶部是 `‹ 2026年 ›` 年份导航，下面是 3×4 的 `1月…12月` 网格，当前选中月高亮（灰底胶囊）。

**重要前置事实（来自代码勘查，纠正任务描述里的"去掉滑动"措辞）：**
- 当前首页 **没有任何 swipe/PageView/横向拖动** 切换月份。现状是 `hero_header.dart` 上的左右 chevron 箭头逐月步进 + 月份标签不可点。
- 所以"去掉滑动"在本任务里落实为：**去掉左右 chevron 箭头**，改成点标签弹网格。
- 首页目前 **不存在** 月份网格弹窗（仅 Analytics 的 `time_window_picker_sheet.dart` 有一个 bottom-sheet 月份列表，可作参考，但不直接复用其交互形态）。

## Key Code (勘查结果)
- Header UI（纯 UI 组件）：`lib/features/home/presentation/widgets/hero_header.dart`（月份标签 ~67-73；左 chevron ~52-62；右 chevron ~77-86，`showNextChevron` 控制）
- Header 接线：`lib/features/home/presentation/screens/home_screen.dart`（~74-84，`onPrevMonth`/`onNextMonth`/`showNextChevron`）
- 选中月状态：`lib/features/home/presentation/providers/state_home.dart`（`HomeSelectedMonth`，provider 名 `homeSelectedMonthProvider`，状态 `({int year, int month})`，方法 `selectMonth(year, month)` / `prevMonth()` / `nextMonth()`；`nextMonth()` 已有 clamp 不能翻到未来月）
- 月份标签 l10n：`homeMonthFormat`（ja/zh `{year}年{month}月`，en `{year}/{month}`），三份 ARB：`lib/l10n/app_{ja,zh,en}.arb`
- 参考 picker：`lib/features/analytics/presentation/widgets/time_window_picker_sheet.dart`

</domain>

<decisions>
## Implementation Decisions（用户已锁定，不要再问）

### 箭头去留
- **完全去掉 header 上的左右 chevron 箭头**（弹窗打开前后都没有 ‹ ›）。
- 在月份标签右侧**恢复一个向下箭头 `⌄`**，作为「可点击展开」的视觉提示。
- 点击「月份标签 + ⌄」整体区域 → 打开月份网格弹窗。
- 相应地：`home_screen.dart` 里 `onPrevMonth`/`onNextMonth`/`showNextChevron` 接线移除，改为 `onMonthTap`（或等价回调）打开弹窗。

### 未来月份处理
- 网格中**超过当前真实月份的未来月份置灰、不可点选**（保持现有 `nextMonth()` 的 clamp 限制语义）。
- 弹窗的年份导航**不能翻到未来年**（当年份 == 当前年时，`›` 下一年按钮禁用/置灰；上一年始终可用）。
- 选中当前显示年里某个已过去/当前的月份 → 调 `homeSelectedMonthProvider.notifier.selectMonth(year, month)` 并关闭弹窗。

### 视觉/主题
- 遵循项目 ADR-019 v1.6 配色与 `context.palette`：当前选中月用主题中性高亮（参考截图灰底胶囊即可，不要硬编码 hex）。年份标题用主题强调色。禁止硬编码颜色，统一走 `context.palette`。
- 金额无关，无需 amount text style。

### Claude's Discretion（未明确的交给规划/执行判断，保持项目惯例）
- 弹窗用 `showDialog`（居中卡片，贴合截图形态）还是其它形态由规划决定，但**形态要贴合截图：居中圆角卡片 + 年导航 + 3×4 网格**。
- 网格里月份文案的 l10n：ja/zh 用 `N月`，en 用合适缩写或 `N`（按现有 i18n 惯例，必要时新增 ARB key 并三语补齐 + 跑 `flutter gen-l10n`）。
- 弹窗也可做成可复用 widget，放在 `lib/features/home/presentation/widgets/`。

</decisions>

<specifics>
## Specific Ideas

参考截图（用户 iPhone 实拍叠加目标设计）：居中白色圆角卡片弹窗；顶部一行 `‹  2026年  ›`（年份居中、强调色）；下面 3 列 × 4 行月份网格 `1月 2月 3月 / 4月 5月 6月 / 7月 8月 9月 / 10月 11月 12月`；当前选中月（6月）灰底胶囊高亮。

</specifics>

<canonical_refs>
## Canonical References

- 配色：`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`（v1.6 桜餅×若葉，统一 `context.palette`）
- i18n 规则：CLAUDE.md「i18n Rules」（所有 UI 文案走 `S.of(context)`；改 ARB 后跑 `flutter gen-l10n`；三语同步）
- Riverpod 3 约定：CLAUDE.md「Riverpod 3 conventions」

</canonical_refs>
