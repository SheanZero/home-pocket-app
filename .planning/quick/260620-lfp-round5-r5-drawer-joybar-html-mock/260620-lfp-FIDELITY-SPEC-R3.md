# 260620-lfp Round-3 — 悦己抽屉 joybar 修复 + 对齐 mock

**基准 mock:** `.planning/phases/43-html-design-gate-no-production-code/mocks/round5/r5-drawer-joybar.html`（`.joybar` / `.joybar .seg` / `.inpct` / `.joybar-legend .jl`）
**用户反馈:** 设备端「悦己部分没有按 mock 实现」—— 横向堆叠条**不显示**（空白），且多出一个 mock 里没有的「悦己花销 ¥…」大字重复总额。

> 铁律同前：本 spec 给值即全部要求，**不要自己发挥**。范围仅 **悦己抽屉**（joybar + 其图例 + 重复总额）。分类环 hero / 日历卡 / 趋势卡 / 直方图卡**零改动**。

---

## 根因（必须修）：joybar 不可见
`joy_spend_stacked_bar.dart` 里每段用 `Flexible(flex: amount, child: <DecoratedBox 无尺寸>)`。`Flexible` 是 **loose** fit，子 `DecoratedBox` 无固有宽度 → 每段被压成 **0 宽 → 整条不可见**（只剩 28px 空白）。golden 是从这个坏渲染重基线的，所以没报错。

---

## 1. `lib/core/theme/joy_warm_palette.dart`
新增一个奶白常量（core/theme 允许裸 hex）：
```dart
/// 段间 2px 分隔 / 条底色（mock --cream）。
static const Color cream = Color(0xFFFFFAF6);
```

## 2. `lib/features/analytics/presentation/widgets/joy_spend_stacked_bar.dart`

### 2a. 条本体（mock `.joybar` + `.seg`）—— 修不可见 + 对齐 mock
把顶部 `ClipRRect>SizedBox(28)>Row[Flexible...]` 换成：
- 外层 `Container`：`height: 32`，`decoration: BoxDecoration(color: JoyWarmPalette.cream, borderRadius: BorderRadius.circular(9), border: Border.all(color: barBorder))`，其中 `barBorder = Color.lerp(palette.joy, palette.joyLight, 0.55)!`（与 drawer 边一致）。
- 内层 `ClipRRect(borderRadius: BorderRadius.circular(8))` 包一个 `Row`，每段用 **`Expanded(flex: seg.amount, ...)`**（**不是 Flexible** —— 这是修复关键），child = `GestureDetector(onTap → _onSegmentTap(i)) > _Segment(segment, isLast, selected, dimmed)`。
- 保留 tap 选中/dim 行为。

### 2b. `_Segment`（mock `.seg` + `.inpct` + 2px 分隔）
- 填充色：`dimmed ? color.withValues(alpha:0.45) : color`。
- **段间 2px 奶白分隔**：每段（除最后一段）`Border(right: BorderSide(color: JoyWarmPalette.cream, width: 2))`。selected 时可叠加一圈白描边（可选，保留现状亦可）。
- **大段内嵌 % 标**：当 `segment.percent >= 12`（四舍五入百分比）→ 段内 `Center(child: Text('${segment.percent}%'))`，样式 fontSize **9.5**, FontWeight.**w800**, color `Colors.white`, 阴影 `shadows:[Shadow(color: Colors.black.withValues(alpha:0.3), offset: Offset(0,1), blurRadius: 1)]`。`< 12` 不显示标。
  - （单分类 100% → 显示「100%」；mock 7 类数据 → 25/22/19/13 显示、9/7/4 不显示，与 mock 一致。）
- 需把 `percent` 和 `isLast` 传进 `_Segment`。

### 2c. joybar 图例 `_LegendRow`（mock `.joybar-legend .jl`）—— 对齐
- dot：圆形→**圆角方块 11×11, `BorderRadius.circular(4)`**（与已修的环图例一致）。
- name：fontSize **12.5**, w600, `palette.textPrimary`, ellipsis。
- amount：fontSize **12**, w700, **`palette.joyText`**（当前是 textPrimary，改 joyText）。
- pct：fontSize **10.5**, w600, `palette.textTertiary`, 宽 **46**, 右对齐。
- 行间：每行底部 1px `palette.borderDivider` 下边线，最后一行无（mock `.jl{border-bottom}` + `:last-child`）。padding 垂直 7。

## 3. `lib/features/analytics/presentation/widgets/joy_spend_drawer_body.dart` —— 去掉重复总额
`JoySpendDrawerBody` 加参数 `bool showTotalHeader = true`。`showTotalHeader == false` 时**不渲染**「悦己花销」label + count-up 总额（当前第 76–92 行那段）+ 其后的 `SizedBox(16)` → body 直接从 joybar 开始（mock：drawer-sub 之后直接 joybar，无重复总额）。

`joy_spend_drawer.dart`：嵌套调用改为 `JoySpendDrawerBody(amounts: amounts, showTotalHeader: false)`（drawer-top 已显示「悦己 ¥X 花在哪几类开心事」，不再重复）。

> 独立 `JoySpendCard` wrapper（测试保留用）继续默认 `showTotalHeader: true` —— 其 golden/anti-toxicity 测试不变。

## 4. 验收闸（按序全绿）
1. `flutter analyze` → 0 issues。
2. `flutter test`（全量）→ 全绿（color_literal_scan：新增 hex 只在 core/theme ✓；hardcoded_cjk_ui_scan；anti_toxicity_phase47；joy_spend / donut / scroll-smoke widget 测试）。
3. **macOS 重基线**受影响 golden：joy_spend card、category_donut card、analytics scroll-smoke（joybar 现在可见 + 去重复总额，渲染会变）。targeted `--update-goldens`，零删除。
4. 原子提交（1–2 个）。**不提交** .planning/ docs。不动 ROADMAP/STATE。

## 5. 产出
SUMMARY 追加到 `260620-lfp-SUMMARY-R3.md`：根因、改动、commit、analyze/test、重基线 golden 数、保守保留点。
