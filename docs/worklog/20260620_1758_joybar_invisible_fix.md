# 悦己 joybar 不可见根因修复 + 对齐 mock（260620-lfp R3）

**日期:** 2026-06-20
**时间:** 17:58
**任务类型:** Bug修复 / UI 保真
**状态:** 已完成
**相关模块:** MOD-007 Analytics

---

## 任务概述

用户设备端反馈「悦己部分没有按 mock 实现」：悦己抽屉里的横向堆叠条（joybar）**完全不显示**（只剩一段空白），
且多出一个 mock 里没有的「悦己花销 ¥…」大字重复总额。

---

## 根因

`joy_spend_stacked_bar.dart` 把每个分段写成 `Flexible(flex: amount, child: <无固有尺寸的 DecoratedBox>)`。
`Flexible` 默认 **loose** fit —— 子组件可以小到其固有宽度；`DecoratedBox`（无 child、无 size）固有宽度为 **0**，
于是每段被压成 0 宽，**整条 joybar 不可见**。因为 golden 是从这个坏渲染重基线的，测试一直"绿"，从未报错
（典型的 golden 自我锁定坏状态 → 无法校验"对不对得上 mock"，只能靠人眼）。

---

## 完成的工作

### 1. 根因修复（关键）
`Flexible` → **`Expanded`**（tight fit）：每段按 flex 比例填满 → 条可见。

### 2. joybar 对齐 mock（`joy_spend_stacked_bar.dart` + `joy_warm_palette.dart`）
- 条本体：`Container(height:32, 圆角9, 奶白底 cream #FFFAF6, 1px 樱粉边 lerp(joy,joyLight,.55))` 内嵌 `ClipRRect(8) > Row[Expanded 段]`。
- 段间 **2px 奶白分隔**（除最后一段）。
- 大段（四舍五入百分比 **≥12%**）段内居中 **白色 % 标**（9.5/w800/阴影），小段不显示 —— 与 mock 一致（25/22/19/13 显示，9/7/4 不显示；单分类 100% → 显示「100%」）。
- `JoyWarmPalette` 新增 `cream` 常量（core/theme，过 color_literal_scan）。
- joybar 图例：圆形 dot → **圆角方块 11×11**；金额色 textPrimary → **joyText**；行间 1px 分隔线；name 12.5/w600、amount 12/w700、pct 10.5/w600/宽46。

### 3. 去掉嵌套抽屉里的重复总额（`joy_spend_drawer_body.dart` + `joy_spend_drawer.dart`）
`JoySpendDrawerBody` 加 `showTotalHeader`（默认 true）；嵌套 `JoySpendDrawer` 传 `false` → 不再渲染「悦己花销 ¥…」count-up
（drawer-top 已显示「悦己 ¥X 花在哪几类开心事」，mock 是 drawer-sub 之后直接 joybar）。独立 `JoySpendCard` wrapper 仍默认 true，保其测试不变。

---

## 测试验证

- [x] `flutter analyze` → 0 issues（orchestrator 复跑确认）
- [x] `flutter test`（全量）→ 3072/3072
- [x] 7 个 golden master macOS 重基线（joy_spend_card ×6 + analytics_screen_scroll_smoke_light_ja），零删除/零新增
- [x] orchestrator 代码层复核 `joy_spend_stacked_bar.dart`：Expanded/几何/分隔/内嵌标/图例均对齐 spec
- [ ] **设备端视觉待用户确认**

---

## 已知数据说明（非 bug）

用户测试数据只有 **1 个**悦己分类（日用品 ¥236,887 = 100%），故修复后 joybar 是**单段满宽樱粉条**，
不会呈现 mock 的 7 色彩条 —— 那需要多个悦己分类。另：该数据把「日用品」归入悦己账本（分类账本归属问题，
非渲染 bug），导致环上日用品着樱粉、悦己抽屉只此一类。

---

## Git 提交记录

```
b296d3b5 fix(analytics): make 悦己 joybar visible (Flexible→Expanded) + align drawer to r5 mock
53b65787 test(analytics): rebaseline joy_spend + scroll-smoke goldens for visible joybar
```

---

## 保守保留（spec 未给值，按"勿发挥"保留）

- 图例 % 仍为整数 `${percent}%`（mock 显示一位小数，spec 未要求改数据源）
- 选中段白描边保留（spec 标"可选"）
- mock `.inpct{opacity:.95}` 未施（spec 未给值）

---

**创建时间:** 2026-06-20 17:58
**作者:** Claude Opus 4.8
