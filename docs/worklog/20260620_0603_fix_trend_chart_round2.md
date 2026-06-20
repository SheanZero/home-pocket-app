# 支出趋势图表修正 round 2（整月X轴/去起点标注/数据锚定端点标注/进位至今天）

**日期:** 2026-06-20
**时间:** 06:03
**任务类型:** Bug修复
**状态:** 已完成
**相关模块:** [MOD-007] Analytics — 统计页 within-month 累计趋势图（round-5 B card #1）

---

## 任务概述

quick task 260620-kll：对 jx2（round 1）添加的「支出趋势」累计折线图做第二轮修正。
用户真机 review 后给出 5 条锁定修正：①X 轴显示整月而非止于最后消费日 ②去掉起点
标注 ③端点标注数据锚定 + 按本月/上月对比上下放置 ④上月线同规则但对置 ⑤本月线
进位至「今天」、上月线跨整月、起点从 day1 进位。核心是把 carry-forward + 「今天」
注入下沉到 use case（保持 chart 无时钟、golden 确定性）。

---

## 完成的工作

### 1. Task 1 — use case carry-forward + now 注入（commit fc5e6caf）
- `GetWithinMonthCumulativeUseCase.execute(...)` 新增必填 `DateTime now` 参数
  （D-5：use case 是唯一知道「今天」的地方，chart 保持无时钟）。
- `_cumulative(...)` 对每月稀疏序列做整跨度进位：day1(累计0) 前置 + comparisonDay
  后置进位。当前月 comparisonDay = now.day（实时月）/ 月末（过去月，按月长 clamp）；
  上月 comparisonDay = 上月最后一天。无消费的月返回 `const []`（不合成平线）。
- `state_analytics.dart` 传 `now: DateTime.now()`（唯一注入真实时钟的生产调用方）。
- 用例测试 7 → 13（全部传显式 now；+6 进位边界断言）。

### 2. Task 2 — chart 整月 X 轴 + 数据锚定上下端点标注（commit a38938ee）
- `maxX = daysInMonth(anchor)`，minX 1，底部日期刻度跨整月（D-1）。
- 删除起点标注 + 起点圆点；仅保留末点圆点（D-2）。
- `LayoutBuilder` + plot-area 像素映射（leftReserved 44 / bottomReserved 22 /
  topPad 12）锚定标注。本月标注锚于末点；上月标注（仅消费侧）锚于
  day ≤ comparisonDay 的最近上月点（查找，非 `.last`）。`labelAbove = 本月 ≥ 上月`，
  上月取反（对置，D-3/D-4），均 clamp 在卡片内。
- 静态 `labelAbove(...)` helper + 可测 `WithinMonthEndpointAnnotation`
  (`isCurrent`/`above`)，便于断言对比/对置逻辑。chart 测试 9 → 13（+4）。

### 3. Task 3 — golden fixture 重写 + 全量门禁（commit 3ff74f9f）
- 两个 golden 的固定 fixture 改写为 round-2 use-case 输出形状（May-2026 anchor
  = 完整过去月）：当前序列 day1(0)→day31；上月（4 月 30 天）day1(0)→day30；
  comparison day 处本月 98000 > 上月 90000，触发 ABOVE 分支让两标注无碰撞可见。
- macOS 重基线 8 张 master；目视核对 ja light master（整月轴、本月实线、上月虚线
  跨整月、无起点标注、两端点标注上下不重叠）。空态 master 未变（占位路径不变）。

### 代码变更统计
- 修改 14 个文件（3 lib + 4 test/golden test+fixture + 7 PNG master）。
- 提交 3 个原子 commit（每个 task 一个）。

---

## 遇到的问题与解决方案

### 问题 1: clockless grep 误判
**症状:** chart 文档注释里写了字面量 `DateTime.now()`（「reads NO DateTime.now()」），
会让计划的 `grep 'DateTime.now()'` 验证命中。
**原因:** 注释用词包含被检测的 token。
**解决方案:** 改为「reads NO wall clock」，grep 归零；chart 实际不读任何时钟。

---

## 测试验证

- [x] 单元测试通过（use case 13/13）
- [x] Widget 测试通过（chart 13/13）
- [x] 全量 `flutter test` 通过 3071/3071（含 hardcoded-CJK-UI 扫描 + 反毒性扫描）
- [x] `flutter analyze` 0 issues
- [x] grep DateTime.now() / 硬编码 hex 在 chart 内均为 0
- [x] golden master 重基线（macOS）

---

## Git 提交记录

```bash
fc5e6caf feat: carry-forward + now-injection in within-month cumulative use case
a38938ee feat: whole-month X extent + data-anchored above/below endpoint labels in trend chart
3ff74f9f test: re-baseline trend-card + analytics-smoke goldens for whole-month axis + endpoint labels
```

---

## 后续工作

- 无。5 条锁定修正全部实现并可验证；联机真机 UAT 由用户在后续 review 确认。

---

## 参考资源

- 计划: `.planning/quick/260620-kll-trend-chart-fix/260620-kll-PLAN.md`
- 上下文: `.planning/quick/260620-kll-trend-chart-fix/260620-kll-CONTEXT.md`
- round 1: `.planning/quick/260620-jx2-trend-chart-axes/260620-jx2-SUMMARY.md`
- ADR-019（配色，无硬编码 hex）、ADR-012/D-E1（悦己零跨期）

---

**创建时间:** 2026-06-20 06:03
**作者:** Claude Opus 4.8
