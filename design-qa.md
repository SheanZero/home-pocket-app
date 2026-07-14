# Design QA — 明细页账本筛选与月历金额联动

**Source visual truth**

- Selected明细页视觉：`/Users/xinz/.codex/generated_images/019f4ada-1592-7883-af84-255433d0548e/exec-ed6d5678-1373-4442-8528-68453d5d5483.png`
- 本轮用户覆盖要求：将 `list-filter-ledgers` 放到月历卡片上方，并用同一账本状态过滤月历金额。

**Implementation evidence**

- 全部账本：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/list-ledger-calendar-sync/all-phone.jpg`
- 日常账本：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/list-ledger-calendar-sync/daily-phone.jpg`
- 悦己账本：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/list-ledger-calendar-sync/joy-phone.jpg`
- 全视图对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/list-ledger-calendar-sync/comparison.jpg`
- 三种筛选状态聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/list-ledger-calendar-sync/state-comparison.jpg`

**Viewport and state**

- 390 × 844 手机框架，个人模式，浅色主题，2026年7月，日期降序。
- 分别验证全部、日常、悦己三种账本状态；筛选组件在月历上方，间距 8px。

**Findings**

- 无可执行的 P0/P1/P2 问题。
- 字体与排版：继续使用当前日系纸面字体层级；月历金额保持 9px / 10px 行高，筛选后不会改变日期行高度或造成数字跳动。
- 间距与布局：账本分段控件已从黏性筛选栏移到月历卡片上方；宽度与月历、日期卡片均为 334px，左右对齐一致。390px 框架下 `scrollWidth === clientWidth`，无横向溢出。
- 色彩与视觉令牌：全部、日常、悦己分别复用现有主色、日常色与悦己色的选中态；卡片、边框、阴影和纸面背景没有引入新令牌。
- 图像与图标：页面无新增图像资产；继续使用既有 Material Symbols Rounded，不含占位图、Emoji、手工 SVG 或 CSS 替代图标。
- 文案与内容：月历汇总根据账本切换为「今月の合計 / 日常の合計 / ときめきの合計」，金额分别为 ¥186,420 / ¥132,800 / ¥53,620。
- 状态联动：7月10日金额在全部、日常、悦己状态分别显示 4.3千、3.3千、980；7月2日和12日只在全部/悦己显示，7月9日只在全部/日常显示。
- 明细联动：全部显示4条，日常显示3条，悦己显示1条；与月历金额使用同一个 `listLedger` 状态。
- 无障碍：账本容器使用 `role="group"` 与 `aria-label="帳簿"`；三个选项同步更新 `aria-pressed`。
- 交互与控制台：点击三种账本均会同步刷新月历、月合计和明细；排序、类别、搜索控件仍保持可用；浏览器控制台 0 warnings / 0 errors。

**Open Questions**

- 无阻塞项。原始视觉把账本筛选放在月历下方，本轮位置变化来自用户明确要求，因此不是设计偏差。

**Implementation Checklist**

- [x] 将 `list-filter-ledgers` 移到月历卡片上方。
- [x] 月历每日金额读取当前账本筛选状态。
- [x] 月历月合计和汇总标签同步切换。
- [x] 下方日期卡片沿用同一账本筛选状态。
- [x] 保留排序、类别、搜索、日期选择和明细跳转。
- [x] 验证 390 × 844 三种账本状态与控制台。

**Comparison History**

- 初始实现：移动账本分段控件，拆分日常/悦己月历数据，并让月合计与明细共享 `listLedger`。
- 视觉复核：三态对照确认选中态、每日金额、月合计和明细同时更新，布局无跳动或横向溢出；无需第二轮 P0/P1/P2 修复。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 购物条目标识与筛选器标题精简

**Source visual truth**

- 购物页方案2参考：`/Users/xinz/.codex/generated_images/019f4ada-1592-7883-af84-255433d0548e/exec-9435bdc0-602a-41d0-b0c6-ad1076b19a3c.png`
- 本轮用户覆盖要求：删除 item detail 左侧的日常/悦己竖线标识，并删除两个筛选分组的小标题；其余布局、内容和功能保持现有 mockup 方案。

**Implementation evidence**

- 390 × 844 最终页面：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-final-phone.png`
- 全视图组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-design-comparison.png`
- 筛选器与条目聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-focus-comparison.png`

**Viewport and state**

- 390 × 844，A1个人浅色，购物页；家庭范围为「全部」，账簿为「すべて」，私有和类别筛选未启用。
- 补充验证悦己筛选与日用品类别筛选，并恢复默认交付状态。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：筛选选项、分区标题、条目名称、数量说明和账簿标签延续当前设计系统字阶；去掉小标题后没有产生上下跳动或文字截断。
- 间距与布局：两个分段筛选器在同一行保持平衡；「私有 / カテゴリ」位于第二行；条目继续使用同条件合并卡片，删除左侧竖线后内容区与完成圆环形成统一的水平起始线。
- 色彩与令牌：日常与悦己语义继续通过行内标签区分，不再用额外竖线重复表达；背景、边框、圆角和阴影均复用现有暖日系令牌。
- 图像与图标：没有新增位图或替代图形；完成圆环、拖拽图标和底部导航继续使用既有图标资源。
- 文案与内容：筛选器不再显示「家族範囲 / 帳簿フィルター」小标题；功能选项和购物条目内容未减少。
- 交互与响应式：悦己筛选只显示咖啡豆1项；日用品类别显示卫生纸与已完成洗洁精2项；浏览器控制台0 errors。
- 无障碍：筛选分组继续保留 `role="group"` 和可访问名称「範囲 / 帳簿」，即使视觉小标题被删除，读屏语义仍完整。

**Comparison History**

- 修正前：条目左侧用绿色/粉色竖线重复表达账簿类型，筛选器上方有两个微型标题，信息层级略显繁复。
- 修正后：删除竖线与视觉小标题，保留日常/悦己标签及可访问分组语义；全视图和聚焦对照确认页面更轻、更连续，功能未受影响。

**Implementation Checklist**

- [x] 删除所有购物条目左侧账簿竖线。
- [x] 删除筛选器两个视觉小标题。
- [x] 保留范围、账簿、私有和类别筛选能力。
- [x] 保留日常/悦己行内标签与拖拽顺序入口。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证核心筛选交互和控制台。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 分类 / 成员独立椭圆选中态

**Source visual truth**

- 用户参考图：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/codex-clipboard-d78ca689-4043-4449-bb77-4e654ff46e07.png`
- 本轮补充要求：分类与成员的选中项均为完整椭圆，并使用不同的设计系统语义色。

**Implementation evidence**

- 分类选中：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/24-category-pill-active.png`
- 成员选中：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/25-member-pill-active.png`
- 深色小屏：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/27-member-pill-dark-375.png`
- 聚焦三态对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/26-segmented-pill-comparison.png`

**Viewport and state**

- 主对照为390px手机框架、个人浅色、2026年7月；分别检查分类选中与成员选中。
- 补充验证375px个人深色成员选中，并恢复390px个人浅色分类选中作为交付状态。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：两个标签维持相同11px字阶、750字重和单行居中，选中时没有位移或截断。
- 间距与布局：外层控件保持164 × 40px；选中项高40px并覆盖外框1px，呈现连续完整的999px椭圆；未选中项高38px，切换时整体布局不跳动。
- 色彩与令牌：分类选中映射 `--hp-daily` 鼠尾草绿，成员选中映射 `--hp-shared` 低饱和共享蓝；浅色与深色主题均复用既有令牌。
- 图像与图标：本次不涉及新增位图资产或图标替换，参考图中的控件外观完全由既有交互组件承担。
- 文案与内容：维持「カテゴリ別 / メンバー別」原文案，分类数据、成员数据和筛选行为不变。
- 响应式与无障碍：375px与390px均为0横向溢出；`aria-pressed` 随分类/成员切换同步更新。

**Comparison History**

- 修正前：外框裁切子项并在第二项左侧绘制边框，分类选中时右侧呈现竖直切口，记录为 P2 形状与质感偏差。
- 修正后：移除中间竖线和裁切，每个选项自身使用完整圆角；分类与成员分别使用日常绿和共享蓝。聚焦三态对照确认形状、边框连续性和语义色均达到目标。

**Implementation Checklist**

- [x] 分类选中改为完整椭圆。
- [x] 成员选中改为完整椭圆。
- [x] 删除中间竖向分割线。
- [x] 分类与成员使用不同的设计系统语义色。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、浅色/深色和切换交互。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Design QA — 分类支出截图逐尺寸还原

**Source visual truth**

- 用户重新指定的唯一参考图：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/codex-clipboard-d78ca689-4043-4449-bb77-4e654ff46e07.png`

**Implementation evidence**

- 最终浏览器截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/21-category-faithful-final.png`
- 全视图组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/23-category-faithful-full-comparison.png`
- 分类区聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/22-category-faithful-final-comparison.png`

**Viewport and state**

- 390 × 844 手机框架，个人模式、浅色主题、2026年7月、分类维度、成员筛选为「全員」。
- 补充验证375px、成员维度、选择「あおい」、恢复「全員」和个人深色模式。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：分类标题为16px/19px、800字重；圆环中心金额18px；控制标签11px；排行标题和金额11.5px。字号层级、截断和数字对齐与参考图一致。
- 间距与布局：圆环为242px，中心孔使用58px内缩；标题到圆环24px，圆环到控制区30px，控制区到排行13px；排行每行52px。
- 表面与形状：分类区已改为连续纸面，删除参考图中不存在的摘要标签、卡片边框、圆角、阴影和底部悦己票据。
- 控制区：左侧分段控件164 × 40px，右侧成员筛选88 × 40px，使用两端对齐；结构和比例与参考图一致。
- 色彩与令牌：圆环使用参考图的鼠尾草绿、蓝、暖粉与薄荷绿；页面表面、文字和边框仍映射现有浅色/深色令牌。
- 图像与图标：分类区不包含需要生成的位图资产；数据圆环由现有可交互图表实现，图标继续使用项目既有 Material Symbols，样式、位置与参考图一致。
- 文案与内容：标题、总额、件数、分类名称、金额、百分比和筛选标签均与参考图一致；未增加解释性文案。
- 响应式与无障碍：375px和390px均为0横向溢出；维度切换继续同步 `aria-pressed`，成员筛选保留完整无障碍名称。
- 交互与控制台：已验证分类/成员切换、成员弹层、选择个人、恢复全员；深色模式背景和文字令牌正确；浏览器0 warnings / 0 errors。

**Open Questions**

- 无阻塞项。参考图外围的方案切换栏和页面目录属于现有 Sketch 预览器，不作为 App 内分类组件重复实现。

**Implementation Checklist**

- [x] 放大并重新定位圆环及四个分类标注。
- [x] 按参考图重设标题、控制区和排行尺寸。
- [x] 改为连续纸面并移除多余卡片表面。
- [x] 移除参考图中不存在的摘要与悦己票据。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、浅色/深色和核心筛选交互。

**Comparison History**

- 初始实现：190px圆环、44px排行、14px卡片内边距，存在明显 P1 尺寸与表面偏差。
- 第一轮修正：圆环调整为242px，排行调整为56px，移除顶部摘要、卡片边框和底部票据；聚焦对照仍显示纵向节奏偏松，记录为 P2。
- 第二轮修正：控制区调整为40px，排行调整为52px，重算圆环到控制区及排行间距，并收敛文字与图标字号。
- 最终修正：分类行水平内缩6px，标题后留白增加9px；全视图与聚焦对照确认构图、比例、字体、颜色、图标与内容达到参考方向。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Design QA — 统计页分类支出方案2

**Source visual truth**

- 用户选定的第二张视觉方案：`/Users/xinz/.codex/generated_images/019f4ada-1592-7883-af84-255433d0548e/exec-7702c39e-ddf3-4e48-8ce6-e800c08ce349.png`

**Implementation evidence**

- 浏览器实现截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/12-category-option2-final.png`
- 全视图组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/14-category-option2-full-comparison.png`
- 控制区与排行聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/13-category-option2-final-comparison.png`

**Viewport and state**

- 390 × 844 手机设计目标；实现运行在 Sketch 005 的390px手机框架内。
- 个人模式、浅色主题、2026年7月、分类维度、成员筛选为「全員」。
- 额外检查375px宽度、成员维度、选择「あおい」以及恢复「全員」状态。

**Findings**

- 无可执行的 P0/P1/P2 问题。
- 字体与排版：沿用现有日系设计系统字体与10px控件字阶；两个维度标签和「全員」均完整显示，没有截断或换行。
- 间距与布局：维度分段控件宽170px，成员筛选宽92px，中间留42px呼吸空间；两组控件均高44px。与选定图的左侧主切换、右侧独立筛选结构一致。
- 色彩与视觉令牌：选中态继续使用既有日常绿色，未引入新主色；背景、边框、圆角和深色令牌均复用当前系统。
- 图像与图标：本次没有新增图片资产；圆环与类别图标保持现有实现，成员筛选使用项目已加载的 Material Symbols `person` 与 `expand_more`。
- 文案与内容：分类金额、占比、月份和总额保持原数据；较长的「対象 · すべてのメンバー」视觉标签收敛为「全員」，完整含义保留在 `aria-label`。
- 响应式：375px与390px均为0横向溢出，控制区 `scrollWidth === clientWidth`。
- 无障碍：维度切换加入 `role="group"`、语义标签与同步更新的 `aria-pressed`；成员筛选仍保留完整目标成员名称。
- 交互与控制台：已验证分类/成员切换、打开成员筛选、选择个人、恢复全员；浏览器0 warnings / 0 errors。

**Open Questions**

- 无阻塞项。选定图将整个分类区铺在连续页面上，当前实现保留既有统计卡片和「ときめき支出」展开入口，这是用户已锁定的整体设计系统与现有功能约束，不属于本次偏差。

**Implementation Checklist**

- [x] 将分类/成员切换合并为一体式分段控件。
- [x] 将成员筛选缩短为右侧独立「全員」控件。
- [x] 保持44px触控高度和完整无障碍名称。
- [x] 保留成员筛选弹层与数据联动。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、关键交互和浏览器控制台。

**Comparison History**

- 第一轮：完成一体式分段控件与92px成员筛选；聚焦对照发现两者间距仅22px，视觉上比选定图更拥挤，记录为 P2。
- 修正：将分段控件从190px收敛到170px，并使用两端对齐；最终间距为42px，文字仍完整，375px/390px均无溢出。
- 第二轮：全视图和聚焦对照确认控制层级、比例、颜色、文字与图标达到选定方向；没有剩余 P0/P1/P2。

**Follow-up Polish**

- P3：若后续希望更贴近生成图，可单独放宽分类排行的行高；本轮保留现有统计页密度，避免影响已经锁定的页面节奏。

final result: passed

---

# Latest QA Status — 分类支出截图逐尺寸还原

旧的「统计页分类支出方案2」报告已被本文件上方的「分类支出截图逐尺寸还原」报告取代。

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/codex-clipboard-d78ca689-4043-4449-bb77-4e654ff46e07.png`
- Implementation screenshot: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/21-category-faithful-final.png`
- Full-view comparison: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/23-category-faithful-full-comparison.png`
- Focused comparison: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/22-category-faithful-final-comparison.png`
- Viewport/state: 390 × 844，个人浅色，2026年7月，分类维度，全員；另验证375px、个人深色和成员筛选状态。
- Primary interactions: 分类/成员切换、成员弹层、选择个人、恢复全員均通过。
- Console: 0 warnings / 0 errors。
- Findings: 字体、间距、颜色、图标、内容和响应式均无剩余 P0/P1/P2；详细对照与修正历史见上方完整报告。

final result: passed

---

# Latest QA Status — 分类 / 成员独立椭圆选中态（最终）

上方「分类 / 成员独立椭圆选中态」完整报告取代旧的分段控件状态。

- Source visual truth: `/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/codex-clipboard-d78ca689-4043-4449-bb77-4e654ff46e07.png`
- Category screenshot: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/24-category-pill-active.png`
- Member screenshot: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/25-member-pill-active.png`
- Focused comparison: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/26-segmented-pill-comparison.png`
- Dark / 375px evidence: `/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/27-member-pill-dark-375.png`
- State: 390px个人浅色分类选中为交付状态；另验证成员选中与375px个人深色。
- Findings: 中间竖线已移除；分类与成员选中均为完整椭圆，分别使用日常绿与共享蓝；375px/390px均无横向溢出，无剩余 P0/P1/P2。

final result: passed

---

# Latest QA Status — 分类卡片统一、悦己分析恢复与成员配色

**Source visual truth**

- 用户本轮三项注释要求，以及统计页上下相邻 `analytics-card` 的既有标题与卡片系统。
- 修改前浏览器证据：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/28-category-card-before.png`
- 历史分类构图参考：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/codex-clipboard-d78ca689-4043-4449-bb77-4e654ff46e07.png`

**Implementation evidence**

- 分类卡片最终浅色状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/33-category-card-title-final.png`
- 悦己分析展开状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/30-category-card-joy-expanded.png`
- 成员暖灰紫选中态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/31-member-warm-mauve.png`
- 375px深色成员状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/34-category-card-dark-member-375.png`
- 卡片表面对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/35-category-card-surface-comparison.png`
- 交互状态对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/36-joy-and-member-states.png`

**Viewport and state**

- 主评审为390px、个人浅色、2026年7月；检查分类卡片折叠与展开、分类/成员切换。
- 补充验证375px个人深色成员选中；所有状态均无横向溢出。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：分类标题已回到与「支出の推移」「ときめきカレンダー」一致的12px、750字重、`.06em`字距及左侧色标结构。
- 间距与布局：分类标题恢复26/10px节奏；分类卡片恢复334px宽、14px内边距、16px圆角，与上下卡片共用相同边框、背景和阴影。
- 色彩与令牌：分类选中保持日常绿；成员选中色由现有共享蓝58%与悦己暖粉42%混合为暖灰紫，浅色约 `#877682`，深色约 `#B3A8B2`，避免冷蓝突兀并保留维度差异。
- 图像与图标：没有新增或替换位图资产；圆环和所有图标继续使用既有可交互图表及 Material Symbols。
- 文案与内容：悦己分析恢复「ときめき支出 / 分类数或成员数 / 总额」摘要，展开后恢复构成条、明细金额和比例；原分类数据不变。
- 交互与无障碍：悦己折叠按钮同步 `aria-expanded`，实测折叠/展开均可用；分类/成员切换继续同步 `aria-pressed`。
- 响应式：375px与390px的分类卡片、椭圆选中态和悦己分析均为0横向溢出；深色文字与选中态保持可读。

**Comparison History**

- 修正前 P2：分类区使用通栏纸面，标题字号、色标、边距、卡片边框和圆角均与上下区域不一致。
- 修正前 P1：`analyticsJoyDrawer()` 函数与事件仍存在，但 `analyticsDonutCard()` 未输出该组件，导致用户入口完全丢失。
- 修正前 P2：成员选中直接使用偏冷的共享蓝，与暖日系页面及悦己粉色组合割裂。
- 修正后：删除分类区专属表面覆盖，回归统一 `analytics-card` 与 `analytics-section-head`；重新接入折叠悦己分析；成员色改为设计系统令牌混合的暖灰紫。两组组合对照及深色小屏证据确认问题均已消除。

**Implementation Checklist**

- [x] 分类标题与上下区域统一。
- [x] 分类卡片边框、圆角、背景、阴影与上下区域统一。
- [x] 恢复悦己分析折叠入口及展开内容。
- [x] 重新设计成员选中色。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、浅色/深色及核心交互。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 分类卡片内部留白

**Source visual truth**

- 用户本轮注释：`analytics-card analytics-category-card` 内部内容与卡片边缘距离需要适当增加。
- 修改前浏览器截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/37-category-inset-before.png`

**Implementation evidence**

- 修改后390px浅色截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/40-category-inset-after-aligned.png`
- 同状态前后组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/41-category-inset-comparison.png`

**Viewport and state**

- 主对照：390px、个人浅色、分类维度、悦己分析折叠。
- 补充验证：375px、悦己分析展开，0横向溢出。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：字号、字重、换行和数字对齐未改变。
- 间距与布局：分类卡片专属内边距由14px调整为18px；圆环顶部留白由24px增至28px，控制区和悦己摘要左右留白由15px增至19px，排行左右留白由21px增至25px。卡片宽度、圆环尺寸和外部页面节奏保持不变。
- 色彩与令牌：背景、边框、分类色、成员色及悦己色完全沿用当前设计系统，没有新增颜色。
- 图像与图标：没有新增或替换资产，圆环与 Material Symbols 保持原样。
- 文案与内容：分类、金额、比例和悦己分析内容均未改变。
- 交互与响应式：分类/成员切换与悦己折叠/展开继续可用；375px和390px均为0横向溢出。

**Comparison History**

- 修正前 P2：卡片外观已经统一，但控制区、排行和底部悦己摘要距离边缘仅15–21px，视觉仍略显贴边。
- 修正后：仅增加分类卡片内部留白4px，组合对照确认内容获得更均匀的呼吸空间，同时未压缩圆环、按钮或文字。

**Implementation Checklist**

- [x] 增加分类卡片内部留白。
- [x] 保持卡片外部尺寸与样式不变。
- [x] 保持所有数据和交互不变。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px及悦己展开状态。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 悦己日历左右留白

**Source visual truth**

- 用户截图：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_nY5OTV/截屏2026-07-13 22.26.41.png`
- 本轮要求：日历网格左右与卡片边框之间适当增加空白，保持日期结构与视觉密度。

**Implementation evidence**

- 390px浅色最终截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/42-calendar-side-inset-final.png`
- 截图与实现聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/43-calendar-side-inset-comparison.png`

**Viewport and state**

- 主评审：390px、个人浅色、7月12日选中。
- 补充验证：375px、7月21日选中，以及390px个人深色。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：星期、日期、金额和日历说明的字号、字重、位置均未改变。
- 间距与布局：日历卡片水平内边距由1px调整为8px，网格与卡片可见边缘距离由约2px增加到9px；390px下日期格保持约44.3px，卡片宽度和纵向节奏不变。
- 色彩与令牌：热力颜色、选中描边、卡片背景和边框完全沿用现有悦己色系。
- 图像与图标：本区域不包含新增位图或图标资产。
- 文案与内容：日期、记录数量、明细和图例内容均未改变。
- 交互与响应式：实测7月12日、7月21日切换正常；375px、390px及深色主题均为0横向溢出，左右留白保持对称。

**Comparison History**

- 修正前 P2：日历卡片覆写为1px水平内边距，最外侧日期格几乎贴住卡片边框。
- 修正后：仅增加日历卡片左右内边距到8px；聚焦对照确认边缘获得清晰呼吸空间，同时网格结构、日期比例和选中状态保持稳定。

**Implementation Checklist**

- [x] 增加日历网格左右留白。
- [x] 保持日期格比例与行列结构。
- [x] 保持选择交互与明细联动。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、浅色/深色和日期切换。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 支出趋势图右侧留白

**Source visual truth**

- 用户标注截图：`/var/folders/qs/d64k8pm541nbr7hjj9scdxj00000gn/T/TemporaryItems/NSIRD_screencaptureui_gcTlT7/截屏2026-07-13 22.36.45.png`
- 本轮目标：缩小坐标轴与折线终点右侧的空白，同时保持金额标签清晰、不贴边。

**Implementation evidence**

- 调整前390px全页截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/44-trend-right-space-before-full.png`
- 调整后390px浅色截图：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/45-trend-right-space-after.png`
- 聚焦对照（左：用户标注；右：调整后）：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/stats-review-2026-07-13/46-trend-right-space-comparison.png`

**Viewport and state**

- 主评审：390px、个人浅色、总支出趋势。
- 补充验证：375px、个人深色，以及总支出/日常/悦己三种趋势状态。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：坐标文字、当月金额和上月金额的字体、字号、位置保持不变；金额标签仍完整可读。
- 间距与布局：折线终点与 SVG 右边缘距离由约22.4px缩小到9.3px；终点与卡片右边缘仍保留约22.3px安全距离。水平网格线同步延伸，右侧视觉重量更均衡。
- 色彩与令牌：当月实线、上月虚线、面积填充及深色模式亮度均沿用现有设计系统。
- 图像与图标：本轮未新增或替换图像、图标资产。
- 文案与内容：金额、日期、纵横坐标和趋势说明均未改变。
- 交互与响应式：总支出、日常、悦己三种状态终点一致对齐；375px/390px、浅色/深色均为0横向溢出。

**Comparison History**

- 修正前 P2：折线终点与图表右边缘约22.4px，网格线也较早结束，形成明显空白带。
- 修正后：水平网格线终点由306延伸至320，三组趋势曲线与面积填充的末端由302统一延伸至316；聚焦对照确认右侧空白减少，标签未被挤压或裁切。

**Implementation Checklist**

- [x] 缩小坐标轴右侧留白。
- [x] 同步移动实线、虚线、终点圆点和面积填充。
- [x] 保持金额标签完整与安全边距。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证375px/390px、浅色/深色及三种趋势状态。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 购物筛选选中态恢复

**Source visual truth**

- 原购物 mockup：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/01-current-shopping-top.png`
- 本轮用户覆盖要求：保留当前两组筛选器同排的结构，但将选中和未选中状态恢复为原 mockup 的独立胶囊样式。

**Implementation evidence**

- 390px默认筛选状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-restored-selected-state-top.png`
- 页面结构组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-selected-state-comparison.png`
- 选中/未选中胶囊聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-selected-state-focus.png`

**Viewport and state**

- 主要对照为390px、个人浅色、购物页；默认选中「全部 / すべて」。
- 补充验证「個人 / 悦己 / 私有」同时选中，筛选结果只显示咖啡豆1项；交付状态已恢复「全部 / すべて」。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：选项继续使用9px、850字重和单行居中，选中前后没有文字位移、换行或截断。
- 间距与布局：筛选器继续保留现在的两组同排结构和第二行辅助筛选；仅移除浅色分段槽，选项间使用6px间距，恢复原 mockup 的独立胶囊节奏。
- 色彩与令牌：选中项恢复松叶绿实色、白色文字和同色边框；未选中项恢复纸白底、暖灰细边框。实测选中背景/边框为 `rgb(69,107,89)`，未选中背景为 `rgb(255,253,248)`。
- 触控与形状：保留当前44px触控高度和999px圆角；相比原 mockup 约32px视觉高度稍大，这是此前触控可用性要求下的明确保留，不构成状态设计偏差。
- 图像与图标：本轮不涉及新增或替换图像资产，购物条目与导航图标保持不变。
- 文案与内容：全部、個人、すべて、日常、悦己、私有与カテゴリ的内容和筛选逻辑均未改变。
- 无障碍与交互：选中项继续同步 `aria-pressed`；「個人 / 悦己 / 私有」组合筛选正确返回1项；浏览器控制台0 errors。

**Comparison History**

- 修正前 P2：范围与账簿选项被放入整块浅色分段槽，未选中项透明无独立边框，与原 mockup 的胶囊选中态不一致。
- 修正后：删除分段槽表面，为每个选项恢复独立纸白底细边框，并用松叶绿实色表示选中；全视图和聚焦对照确认状态语言已回到原 mockup。

**Implementation Checklist**

- [x] 恢复独立胶囊选项。
- [x] 恢复松叶绿实色选中态。
- [x] 恢复白底细边框未选中态。
- [x] 保留44px触控高度、现有筛选结构和功能。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证默认态、组合选中态和控制台。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed

---

# Latest QA Status — 购物筛选右下角对号选中态

**Source visual truth**

- 用户本轮明确纠正的唯一选中态：选项保持纸白表面，不做整颗实色填充；只在选中项右下角显示一个极小对号。
- 被否决的整颗填充版本：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-restored-selected-state-top.png`

**Implementation evidence**

- 390px默认选中状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-corner-check-final-top.png`
- 個人 / 悦己 / 私有组合选中状态：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-corner-check-semantic-top.png`
- 全视图前后组合对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-corner-check-comparison.png`
- 筛选区域聚焦对照：`/Users/xinz/Development/home-pocket-app/.planning/sketches/audits/shopping-ideation-2026-07-13/v15-shopping-corner-check-focus.png`

**Viewport and state**

- 390px、个人浅色、购物页；默认选中「全部 / すべて」。
- 补充验证「個人 / 悦己 / 私有」组合选中，结果仅显示咖啡豆1项；交付状态已恢复默认。

**Findings**

- 无剩余可执行的 P0/P1/P2 问题。
- 字体与排版：选项文字保持原有9px / 850字重，选中时不反白、不位移、不换行；对号使用现有 Material Symbols `check`，字号11px。
- 间距与布局：选项继续保持44px触控高度和独立胶囊结构；对号实测距离右边6px、下边4px，只占据右下角，不挤压居中文字。
- 色彩与令牌：所有选项保持纸白背景；范围与全部账簿使用松叶绿对号，日常使用日常绿、悦己使用樱红、私有使用共享蓝，全部映射现有语义令牌。
- 图像与图标：没有新增位图、手工图形或替代资产；对号来自项目已加载的 Material Symbols，并设置为装饰性图标，不进入按钮可访问名称。
- 文案与内容：全部、個人、すべて、日常、悦己、私有与カテゴリ文案及数据保持不变。
- 交互与无障碍：`aria-pressed` 随筛选切换同步更新；组合筛选返回正确条目；浏览器控制台0 errors。

**Comparison History**

- 修正前 P2：选中项整颗使用松叶绿填充和白色文字，视觉重量过重，与用户要求的右下角小对号版本不一致。
- 修正后：移除实色填充和反白文字，仅加强选中边框，并在右下角放置11px语义色对号；全视图和聚焦对照确认选中态已恢复为轻量版本。

**Implementation Checklist**

- [x] 删除整颗绿色填充选中态。
- [x] 恢复纸白选项表面。
- [x] 在选中项右下角放置小对号。
- [x] 日常、悦己、私有使用各自语义色。
- [x] 保留筛选功能、44px触控区域和无障碍状态。
- [x] 同步 v15 与稳定 Sketch 005。
- [x] 验证默认态、组合选中态和控制台。

**Follow-up Polish**

- 无必须处理的 P3 项。

final result: passed
