# Phase 46: 卡片体系 (Cards) - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-06-17
**Phase:** 46-cards
**Areas discussed:** 卡片阵容对账, 下钻入口与落地, 两张新卡的交互, 暖色动效强度, 趋势卡形态 (found), IA/组模式 (found)

---

## 卡片阵容对账

### Q1 — round-5 B 已批准且只含 5 卡。JOY-01/02/03/04 如何对账？
| Option | Description | Selected |
|--------|-------------|----------|
| round-5 B 为唯一真相 | 严格只建 5 卡；JOY-01/02 视为已由设计重新承载；JOY-03/04 随设计门 drop，零加回 | ✓ |
| B + 保留 kakeibo 静态 | 加回 kakeibo Q4 静态只读提示作 ambient 收尾；记忆故事仍 drop | |
| 加回记忆故事+kakeibo | 两张加回（偏离已批准 round-5 B） | |

### Q2 — 怎么记录被设计门降掉的 JOY-03/04？
| Option | Description | Selected |
|--------|-------------|----------|
| Phase 46 含补正任务 | doc 任务：REQUIREMENTS JOY-03/04 标 Descoped(superseded by GATE-03)；ROADMAP Phase 46 SC #3 重写为 5 卡阵容 | ✓ |
| 只在 CONTEXT 记录 | 不改 REQUIREMENTS/ROADMAP，验收时 SC #3 会误报未达成 | |

### Q3 — round-5 B 不含的旧卡及其 widget/provider/ARB 怎么处理？
| Option | Description | Selected |
|--------|-------------|----------|
| 彻底删除 | find_referencing_symbols 确认无他用后删卡+widget+provider+ARB；golden 重基线入 Phase 47 | ✓ |
| 仅从注册表移除 | 留死代码，违反 dead-code 规则 | |
| planner 定粒度 | 逐个判定删/留 | |

### Q4 — ADR-016 Joy 指标(Σ joy_contribution)是否进 analytics 卡？
| Option | Description | Selected |
|--------|-------------|----------|
| HomeHero 独占 | analytics 零 Σ joy_contribution；JOY-01 以已花悦己金额承载即满足 | ✓ |
| 堆叠条加 ambient 小数字 | 加 Σ joy_contribution 小数字满足 JOY-01 字面，但偏离 round-5 B | |

**User's choice:** 全部按推荐项锁定。
**Notes:** 我核对了选定 HTML（grep 值得/记忆/故事/kakeibo/Q4/反思/下次 = 0 命中），确认 round-5 B 最终阵容确为 5 卡。

---

## 下钻入口与落地

### Q1 — 用户怎么触发分类下钻？
| Option | Description | Selected |
|--------|-------------|----------|
| 图例行 tap | 10 行 level-1 图例整行可点 → push 下钻页；a11y 友好、易点准 | ✓ |
| 圆环扇区 tap | 点饼图扇区；扇区小/悦己弧窄/a11y 弱 | |
| 两者皆可 | 扇区+图例行都触发；命中测试面翻倍 | |

### Q2 — 下钻页顶部小结展示哪些中性统计量？
| Option | Description | Selected |
|--------|-------------|----------|
| 小计+笔数+日均 | 三个中性描述量；日均=总额/天数（非目标/达标率） | ✓ |
| 仅小计+笔数 | 最克制，避免任何速率读感 | |
| planner 定 | 含日均与排序交 planner | |

### Q3 — 下钻列表要不要保留 tile 的写操作？
| Option | Description | Selected |
|--------|-------------|----------|
| 只读列表 | 复用 tile 视觉但禁 swipe-删除/tap-编辑；写操作回列表/录入 tab | ✓ |
| tap-编辑、禁删除 | tap→编辑保留、禁 swipe-删除（折中） | |
| 完整复用 | tap-编辑+swipe-删除全保留；误删+多 provider 失效复杂度 | |

**User's choice:** 全部按推荐项锁定。
**Notes:** 数据层（CategoryDrillDown + GetCategoryDrillDownUseCase）Phase 44 已建；形态（pushed route + l1CategoryId）Phase 45 D-C1 已锁。

---

## 两张新卡的交互

### Q1 — 小确幸日历热力要 ambient 只读还是可交互？
| Option | Description | Selected |
|--------|-------------|----------|
| 纯 ambient 只读 | 色深=当天笔数无 tap 详情；零新数据路径，最 ADR-012-safe | |
| tap 某天→看那天悦己 | 列出当天悦己一刻；需新「按天取悦己」数据路径（scope 风险） | ✓ |

### Q1b — tap 某天后当天悦己一刻怎么呈现？
| Option | Description | Selected |
|--------|-------------|----------|
| 底部 sheet | bottom sheet 列当天悦己；不离页易关 | |
| inline 展开 | 日历下方就地展开当天列表；日历卡变高 | ✓ |
| pushed route | 独立页；单日通常少笔，偏重 | |

### Q2 — 悦己花在哪横向堆叠条 tap 段要有反馈吗？
| Option | Description | Selected |
|--------|-------------|----------|
| 纯展示+图例 | 图例已含 ¥+%，tap-详情冗余；下钻需第二条新路径超 DRILL-01 | |
| tap 段→就地高亮 | 高亮该段+同步高亮图例行；零新数据路径，ADR-012-safe | ✓ |
| tap 段→下钻 L1 全量 | 复用 donut L1 下钻；但点悦己看到日常账，心智错位 | |

**User's choice:** 日历可交互（inline 展开）；悦己段就地高亮。
**Notes:** 用户覆盖了我「纯 ambient 只读」的初始推荐；日历 tap-day 接受新数据路径成本（已记 Research flag #2）。Phase 44 仅允许一条新只读路径且已被 donut 下钻占用——日历 per-day-joy 须 researcher 厘清归属。

---

## 暖色动效强度

### Q1 — 暖色动效整体强度（基调已定 calm-warm）？
| Option | Description | Selected |
|--------|-------------|----------|
| 克制微动 | 仅入场一次性轻动效；无循环/glow 脉冲/庆祝爆发 | ✓ |
| 中等温暖 | count-up + 悦己元素轻 glow（ambient 非循环） | |
| 明显情感化 | count-up+glow+AnimatedSwitcher 较显；逼近成就感读感 | |

### Q2 — 入场 count-up 落在哪些数字？
| Option | Description | Selected |
|--------|-------------|----------|
| donut总额+悦己总额 | 实用 hero + 悦己 hero 各一锚点 count-up，其余静态 | ✓ |
| 仅 donut 总额 | 最克制，只本月支出 count-up | |
| 所有主数字 | donut/悦己/趋势/满足度都 count-up；偏 noisy | |

**User's choice:** 克制微动；count-up 仅 donut 总额 + 悦己总额。
**Notes:** 贴 Phase 43 D-04 calm-warm 基调 + ADR-012 ambient（非 achievement-reward）。

---

## 趋势卡形态 (found during discussion)

> 我在收尾核查时发现已批准设计与 Phase 44 交付数据冲突，遂展开此议项。

### Q1 — 已批准 round-5 B 是「当月日累计 本月vs上月双线」，但 Phase 44 只建了 6 月滚动月总计(BarChart)。怎么办？
| Option | Description | Selected |
|--------|-------------|----------|
| 忠于 round-5 B 日累计双线 | Phase 46 新增 per-day per-ledger 累计数据 + 新 LineChart widget | ✓ |
| 用 6 月滚动(复用 Phase 44) | 趋势改 6 月滚动，「本月vs上月」=framing；低成本但偏离 mock | |
| research 先核实再定 | researcher 核实数据缺口与成本，planning 定形态 | |

**User's choice:** 忠于 round-5 B 日累计双线。
**Notes:** Phase 44 D-08/D-09 建的是 6 月滚动月总计（MonthlyTrend + BarChart），与 round-5 B 的当月日累计 LineChart 形态不符。**Phase 46 须补 per-day-cumulative 数据 + 新 line widget（D-E2，Research flag #1）。**

---

## IA / 组模式 (found during discussion)

### Q1 — round-5 B 未画组模式。现有 family_insight 怎么办？「彻底删除」是否含它？
| Option | Description | Selected |
|--------|-------------|----------|
| 保留为条件卡 | group-mode-only 条件卡（D-B4 isVisible），追在 5 卡后；GUARD-02 要 aggregate-only 存续 | ✓ |
| 也删除 | 组模式也只显 5 卡（聚合家庭数据） | |
| planner 定 | 交 planner 决定去留及位置 | |

### Q2 — Phase 45 保留了分区头；round-5 B 是扁平流。Phase 46 怎么排？
| Option | Description | Selected |
|--------|-------------|----------|
| 扁平 round-5 B 顺序 | 趋势→donut→悦己花在哪→小确幸日历→满足度直方图(+family 条件卡)；删分区头 widget | ✓ |
| 保留分区头 | round-5 B 顺序上仍保留分区标题；偏离 mock | |
| planner 定位置 | 扁平为 round-5 B 序，family_insight 落点交 planner | |

**User's choice:** family_insight 保留为条件卡（不在删除名单）；扁平 round-5 B 顺序，删分区头。
**Notes:** 注册表 list 重排 + isVisible，机制 Phase 45 已立，不再触 shell 机制。

---

## Claude's Discretion

- 下钻列表只读的实现方式（禁回调 vs 只读变体）
- 下钻交易排序（金额降序 vs 时间倒序）
- per-day-cumulative 趋势取数位置（repo thin method vs use case 内 findByBookIds 2-月窗 + Dart cumulative）
- 小确幸日历 inline 展开高度/动画、悦己段高亮视觉手法、count-up 曲线
- 自定义 widget 文件拆分/命名（ADR-017 grep-ban）、注册表条目形态

## Deferred Ideas

- JOY-03 记忆故事 / JOY-04 kakeibo Q4（设计门 drop，标 Descoped；JOY-04 持久化未来需新 ADR + non-Drift）
- 悦己过滤分类下钻（第二条新只读路径，超 DRILL-01）
- Phase 44 的 6 月 MonthlyTrend 扩展若本卡不用 → researcher 核实他用/清理
- i18n / 反毒性扫描扩充 / macOS golden 重基线 / 全量门禁 / UAT → Phase 47
- 收入/结余率、预算、可定制仪表盘、Sankey、中性滚动带、分币种小计、fl_chart 2.x → 里程碑外
