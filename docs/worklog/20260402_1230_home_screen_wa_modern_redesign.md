# Home Screen Wa-Modern Redesign

**日期:** 2026-04-02
**時間:** 12:30
**任務類型:** 功能開發
**状態:** 已完成
**相関模組:** Home Screen (Tab 0)

---

## 任務概述

根据 Pencil 设计文件 (nodes: Psivj, 7tgtB, LP8mE, rwQy7) 的 Wa-Modern (和モダン) 设计规范，完整重写 HomeScreen 及其所有子组件。从蓝色 Hero 背景切换到暖象牙色平面滚动布局，更新配色方案和字体系统。

---

## 完成的工作

### 1. 主要变更

**设计系统 (Foundation):**
- `app_colors.dart` — 全面更换为 Wa-Modern 配色: 暖象牙色 `#FCFBF9` 背景 + 珊瑚色 `#E85A4F` 强调色
- `app_text_styles.dart` — 字体从 IBM Plex Sans 切换到 Outfit, 导航用 DM Sans
- `app_theme.dart` — 更新 colorSchemeSeed, scaffoldBg, fontFamily, 卡片边框样式

**新增组件:**
- `SectionDivider` — "标签 ─── 线" 分割线组件
- `MemberAvatar` — 圆形头像 (带首字母和彩色边框)
- `LedgerRowData` (Freezed) — 账本行数据模型
- `LedgerComparisonSection` — 2-3行账本比较 (生存/灵魂/共享)
- `GroupBar` — 家庭组栏 (名称 + 重叠头像)
- `TransactionListCard` — 带圆角边框和分隔线的交易列表容器

**重写组件:**
- `HeroHeader` — 移除蓝色背景, 改为平面 header + 模式徽章
- `MonthOverviewCard` — 移除柱状图, 改为总额 + 趋势徽章 + 上月行
- `SoulFullnessCard` — 移除电池动画, 改为珊瑚/橄榄指标瓦片
- `HomeTransactionTile` — 移除图标容器, 改为彩色标签 + 商户/分类
- `HomeBottomNavBar` — 从平面标签栏改为浮动药丸导航 + 独立 FAB
- `FamilyInviteBanner` — 从水平卡片改为垂直 CTA 卡片

**组装:**
- `HomeScreen` — 完整重写为平面 SingleChildScrollView 布局
- `MainShellScreen` — 导航栏改为 Stack 浮动覆盖

**清理:**
- 删除 `OhtaniConverter` 组件和 provider
- 清理 24 个不再使用的兼容颜色别名

### 2. 技术决策
- 使用兼容别名 (compat aliases) 策略确保非 Home 模块编译不受影响
- LedgerRowData 放在 domain/models/ 遵循 Clean Architecture
- 导航栏使用 Stack 浮动而非 Scaffold.bottomNavigationBar 以支持 pill 设计
- 日文文字暂时硬编码, i18n 作为后续任务

### 3. 代码变更统计
- 15 个 commits
- 19 个文件修改 (lib/)
- +1,750 / -916 行代码
- 6 个新文件创建
- 1 个文件删除 (ohtani_converter.dart)

---

## 测試驗證

- [x] 単元测试通过 (119/119 home 测试)
- [x] flutter analyze 无新 issues
- [x] 代码审查完成 (spec review + quality review)
- [ ] 手动测试验证 (需 flutter run)
- [ ] 文档已更新

---

## Git 提交記録

```
5428852 fix(home): address code review issues in Wa-Modern home screen
ce9dffd test(home): fix stale nav bar test expectations for pill nav redesign
a1cf12f chore(home): remove OhtaniConverter and cleanup unused compat aliases
7dfeb85 refactor(home): update MainShellScreen for floating pill nav
0866715 refactor(home): complete HomeScreen redesign with Wa-Modern layout
e28af53 refactor(home): rewrite HomeBottomNavBar as floating pill with FAB
a9a0859 refactor(home): rewrite transaction tile and add TransactionListCard
ee6654c feat(home): add GroupBar widget with overlapping avatars
63d479a feat(home): add LedgerRowData model and LedgerComparisonSection widget
a0d36c6 refactor(home): rewrite MonthOverviewCard with trend badge + last month row
9fdada9 refactor(home): rewrite HeroHeader as flat header with mode badge
235b7ac feat(home): add MemberAvatar widget
be69bd4 feat(home): add SectionDivider widget for Wa-Modern design
dabc43a refactor(theme): update text styles to Outfit font with Wa-Modern scale
7a05128 refactor(theme): update color tokens to Wa-Modern palette with compat aliases
```

---

## 後続工作

- [ ] i18n: 约20个硬编码日文字符串需迁移到 ARB 文件 + `S.of(context)`
- [ ] NumberFormatter: 切换到 `lib/infrastructure/i18n/formatters/number_formatter.dart`
- [ ] Dark theme: 实现暗色模式 (颜色已在 design-tokens.json 中定义)
- [ ] 视觉验证: `flutter run` 对照 Pencil 截图检查
- [ ] 合并测试目录: `test/features/home/` 和 `test/widget/features/home/` 有重叠

---

## 参考资源

- Pencil 设计文件: `/Users/xinz/Documents/untitled.pen` (nodes: Psivj, 7tgtB, LP8mE, rwQy7)
- 设计系统文档: `docs/design/design-system.md`
- 设计令牌: `docs/design/design-tokens.json`
- 实施计划: `docs/superpowers/plans/2026-04-02-home-screen-redesign.md`

---

**创建时间:** 2026-04-02 12:30
**作者:** Claude Opus 4.6
