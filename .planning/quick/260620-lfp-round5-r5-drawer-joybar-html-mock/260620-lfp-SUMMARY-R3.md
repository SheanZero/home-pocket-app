# 260620-lfp Round-3 — 悦己 joybar 修复 + 对齐 r5 mock · SUMMARY

**任务类型:** Bug修复 + UI 对齐（fidelity）
**状态:** 已完成
**范围:** 仅悦己抽屉（joybar + 其图例 + 重复总额）。donut hero / 日历 / 趋势 / 直方图零改动。
**分支:** `main`（无 worktree，顺序原子提交）

---

## 根因修复（核心）

`joy_spend_stacked_bar.dart` 每段用 `Flexible(flex: amount, child: <无尺寸 DecoratedBox>)`。
`Flexible` 是 **loose** fit，子 `DecoratedBox` 无固有宽度 → 每段被压成 **0 宽 → 整条不可见**
（设备端只剩约 28px 空白）。golden 是从这个坏渲染重基线的，所以一直没报错。

**修复:** `Flexible` → **`Expanded`**（tight fit），每段按 flex 比例填满。修复后条可见，
故 joy_spend / scroll-smoke golden 必须重基线（已做）。

---

## 改动明细

### 1. `lib/core/theme/joy_warm_palette.dart`（spec §1）
- 新增 `static const Color cream = Color(0xFFFFFAF6);`（mock `--cream`，core/theme 允许裸 hex）。

### 2. `lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart`（spec §2）
- **条本体（§2a）:** `ClipRRect>SizedBox(28)>Row[Flexible]` → 外层 `Container(height:32,
  decoration: cream bg + radius9 + Border.all(barBorder))`，`barBorder = Color.lerp(joy, joyLight, 0.55)`
  （与 drawer 边一致）；内层 `ClipRRect(radius8)>Row`，每段 **`Expanded(flex: amount)`**。保留 tap 选中/dim。
- **`_Segment`（§2b）:** 填充 `dimmed ? color.withValues(alpha:0.45) : color`；段间 2px 奶白右边框
  （除最后段，selected 时改白描边）；`percent >= 12` → 段内 `Center(Text('$percent%'))`，fontSize 9.5 /
  w800 / 白字 / 阴影 `Colors.black.withValues(alpha:0.3)` offset(0,1) blur1。
- **`_LegendRow`（§2c）:** dot 圆形→圆角方块 11×11 radius4；name 12.5/w600/textPrimary/ellipsis；
  amount 12/w700/**joyText**（原 textPrimary）；pct 10.5/w600/textTertiary/width46/右对齐；
  每行底 1px `borderDivider`（最后一行无）；padding 垂直 7。条下间距 16→13（mock `.joybar-legend{margin-top:13px}`）。

### 3. `joy_spend_drawer_body.dart` + `joy_spend_drawer.dart`（spec §3）
- `JoySpendDrawerBody` 加参数 `bool showTotalHeader = true`；`false` 时不渲染「悦己花销」label +
  count-up 总额 + 其后 `SizedBox(16)`。
- 嵌套 `JoySpendDrawer` 调用传 `showTotalHeader: false` → 去掉与 drawer-top 重复的 ¥ 总额。
- 独立 `JoySpendCard` wrapper 继续默认 `true`，其 golden/anti-toxicity 测试不变。

---

## 验收闸（全绿，按序）

1. **`flutter analyze`** → `No issues found!`（全项目）。新增 hex（cream）只在 core/theme ✓。
2. **`flutter test`（全量）** → **3072 个全绿**。含 color_literal_scan、hardcoded_cjk_ui_scan、
   anti_toxicity_phase47、joy_spend / category_donut / analytics scroll-smoke widget 测试。
3. **macOS golden 重基线** → targeted `--update-goldens`，**7 个 master 改动、零删除、零新增**：
   - `joy_spend_card_{light,dark}_{ja,zh,en}.png` ×6
   - `analytics_screen_scroll_smoke_light_ja.png` ×1
   - category_donut goldens **未变**（donut hero 未触）。

---

## Git 提交（原子，2 个，main）

```
b296d3b5 fix(analytics): make 悦己 joybar visible (Flexible→Expanded) + align drawer to r5 mock
53b65787 test(analytics): rebaseline joy_spend + scroll-smoke goldens for visible joybar
```

未提交 `.planning/` docs（orchestrator 处理）。未动 ROADMAP/STATE。

---

## 保守保留点（spec 未给精确值 → 保持现状）

1. **图例 % 文本格式:** mock 图例显示一位小数（如 `25.4%`），但 spec §2c 只改样式值、未要求改百分比
   文本来源。代码继续用 `${segment.percent}%`（整数 round）。**保留整数**（不改数据来源）。
2. **selected 段白描边:** spec §2b 注明「可选，保留现状亦可」→ 保留原 `Border.all(白0.9, width:2)`，
   且 selected 时优先于 2px 奶白分隔。
3. **inpct 文本不透明度:** mock `.inpct{opacity:.95}`，spec 未要求 → 白字直接渲染，未额外加 0.95 透明。
4. **drawer 内 `total` 变量:** `showTotalHeader == false` 时 count-up 块整体不渲染，`total` 仅在条件块内
   引用，analyzer 无 unused 警告。

---

## 结果

- 根因修复已应用（Flexible→Expanded），设备端 joybar 现可见。
- drawer 重复 ¥ 总额已去除，对齐 mock。
- 3 闸全绿，2 个原子 commit。
