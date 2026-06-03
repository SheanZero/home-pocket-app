# 满意度 icon 替换为 line-art 猫 SVG 套组

**日期:** 2026-06-03
**时间:** 10:10
**任务类型:** 功能开发 / UI 资源替换
**状态:** 已完成
**相关模块:** MOD-001 BasicAccounting（添加账目 · 满足度选择器）
**Quick Task:** 260602-vo8

---

## 任务概述

把添加账目页 `满足度` 选择器的 5 档图标，从 Flutter 内置 Material `sentiment_*`/`favorite_border` 换成用户提供的 5 张 line-art 猫 SVG（文件名 01→05，满意度逐渐提升）。

经历了「调研外部开源库(emoji/iconfont) → 自研两版风格稿 → 用户最终给定 5 张正式 SVG → 落地」的过程，本日志记录落地实现部分。

---

## 完成的工作

### 1. 资源
- 新增 `assets/satisfaction/sat_01.svg … sat_05.svg`
  - 来源：用户提供的 `01..05.svg`，800×800 viewBox，单色 `fill="#000000"`，纯 `<path>`（无 gradient/filter/mask/use）
  - 处理：剥离 `<metadata>` RDF 块、压缩空行；其余原样保留
- `pubspec.yaml`
  - 加依赖 `flutter_svg: ^2.3.0`（`flutter pub add`，win32 保持 5.15.0，未触发受 pin 的 file_picker/package_info_plus/share_plus 冲突）
  - `flutter:` 下新增 `assets: - assets/satisfaction/`（此前项目无 assets 段）

### 2. 选择器实现
`lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart`
- `_icons` 由 `List<IconData>` 改为 5 个 SVG 资源路径
- `Icon(_icons[i], size:24, color: ...)` → `SvgPicture.asset(_icons[i], width:30, height:30, colorFilter: ColorFilter.mode(isSelected ? palette.joy : palette.textSecondary, BlendMode.srcIn))`
  - 单色 SVG → `srcIn` 染色，**完全保留原有染色逻辑**（选中 = 悦己 Mauve / 未选 = textSecondary 灰），深浅色自动跟随 palette
  - 尺寸 24→30，line-art 细节在 chip 内更清晰

### 3. 测试
- `satisfaction_emoji_picker_test.dart`：新增断言「渲染 5 个 SvgPicture」
- 新增 `test/golden/satisfaction_emoji_picker_golden_test.dart`（light + dark，选中第 5 档）
  - master 已生成并目视确认：5 只猫梯度渲染正确、选中态 mauve 染色 + 边框 + joyLight 底成立（深色用 `#C0A3CA` + 深 joyLight）
  - 注：golden 内 CJK 文案因测试环境无中日字体显示为 □□，属测试保真，非实现缺陷

---

## 技术决策

- **染色 vs 原黑**：图标为单色，沿用项目既有「选中染 joy / 未选染灰」模式（与 Material 版行为一致），而非固定黑色。深色模式自动适配。
- **范围只限 picker**：满足度脸图标在 4 处有各自独立 mapping（picker / `home_screen` / `home_hero_card` 本月最爱 seal / `list_screen`）。line-art 猫在 seal/tile 的 ~14px 尺寸下会糊，故本次只替换 picker（用户一路迭代的对象），其余 3 处留待用户确认是否同步。

---

## 测试验证

- [x] `flutter analyze` 0 issues（本次新增；遗留 4 条 `onReorder` info 在 `category_selection_screen.dart`，与本次无关）
- [x] picker widget 测试全绿（含新断言）
- [x] picker golden light+dark 生成并目视确认
- [x] 全量 `flutter test` **2297 / 2297** 绿
- [x] `home_hero_card` / `list_transaction_tile` golden 未受影响（独立 mapping）

---

## 后续工作

- [ ] 用户确认是否把同一套猫同步到 `home_hero_card`（本月最爱 seal）/ `home_screen` / `list_screen`——若同步需为各自的小尺寸优化 + golden 重拍
- [ ] 如需，抽出单一 satisfaction→asset 共享 helper，消除 4 处重复 mapping
