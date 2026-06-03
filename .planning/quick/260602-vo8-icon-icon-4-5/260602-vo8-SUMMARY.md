---
quick_id: 260602-vo8
status: complete
date: 2026-06-02 → 2026-06-03
type: research → design exploration → implementation → polish → rollout
---

## 收口（2026-06-03）

最终态:**满足度图标 = 用户提供的 5 张 line-art emoji 脸(01→05 满意度递增),全站统一,可随主题染色。**

### 最终图标集
`assets/satisfaction/sat_01..05.svg`(单色 `#000000` SVG,透明底,`sips`+`potrace` 从用户 JPG 描摹而来):

| 档 | 表情 | 语义 |
|---|---|---|
| 01 | 闭眼 + 浅笑 | 平和 |
| 02 | 微笑 | |
| 03 | 咧嘴 | 不错 |
| 04 | 星星眼 + O 嘴 | |
| 05 | 爱心眼 + O 嘴 | 最爱(用户合成图 `05_副本.jpg` 描摹) |

### 技术落地
- **依赖**: `flutter_svg ^2.3.0`(`flutter pub add`;win32 留 5.15.0,未触发 file_picker/share_plus pin 冲突)+ `pubspec.yaml` 注册 `assets/satisfaction/`
- **共享层**: `lib/shared/widgets/satisfaction_face_icon.dart` —— 唯一 `value→asset` 映射 `satisfactionFaceAsset(int)` + `SatisfactionFaceIcon` widget(`ColorFilter srcIn` 染色)。**消除了原先 4 处重复的 `sentiment_*` 映射。**
- **4 处接入**(全部走共享 widget):
  - `satisfaction_emoji_picker.dart`(添加账目页选择器,chip 56 / icon 34,选中=`palette.joy`、未选=`palette.textSecondary`)
  - `home_hero_card.dart`(本月最爱 seal,24px,`satisfactionPillRose`)
  - `home_transaction_tile.dart` + `list_transaction_tile.dart`(14px,`palette.joy`;tile 入参 `satisfactionIcon:IconData?`→`satisfactionValue:int?`)

### 关键修复 / 决策
- **`Container` 紧约束 bug**: 固定 `width/height` 无 `alignment` → 子组件被强制撑满,`SvgPicture` 的 `width` 被忽略,icon 一直顶边、历次尺寸调整无效。修复:`Container` 加 `alignment: Alignment.center` → 松约束,尺寸真正生效。
- **JPG→SVG**: App 是可染色 SVG 管线,位图(白底/不可染色)不能直接用;`sips`(jpg→bmp)+ `potrace`(brew 装)描摹成单色矢量。
- **布局微调**: `用途` 标题缩到 fontSize 13(与满足度一致)、日常/悦己 pill 竖向 padding 8→5、用途↔满足度间距 20→12;满足度底部 `平和/不错/最爱` 标签改 5 列等距,居中于第 1/3/5 个 icon 正下方(不再贴卡片边)。

### 验证
- `flutter analyze` 0(仅遗留 `category_selection_screen.dart` 的 `onReorder` info,与本任务无关)
- 全量 **`flutter test` 2297/2297 绿**
- golden:新增 picker golden(light+dark);重拍 9 个 `home_hero_card` 变体(所有渲染 seal 的:single/family×light/dark + joy_target_0/50/100/over + thin)+ voice screen golden;list_transaction_tile golden 不受影响

### 提交链
`8687c8c0`(picker 接入)→ `0a195d10`/`365f0556`/`854885a9`/`0c448541`(尺寸迭代)→ `dce48139`(alignment 修复)→ `a5ece6d5`(改用 emoji 脸)→ `5538c40d`(05 爱心眼+O 嘴)→ `73ed5e06`(用途/满足度布局)→ `e0279710`(home/list 推广)

> 旁注:为描摹 `brew install` 了 `potrace`(本地工具,可 `brew uninstall` 移除)。
> 下方为最初「调研阶段」记录,保留时间线。

---

# Summary — 满意度 icon 候选调研

**任务**：从外部开源 icon 库找更好的满意度 icon，≥4-5 组，优先猫猫元素。

## 核心发现
Unicode 自带一组**按满意度递增的猫脸** emoji，终点恰为爱心眼 = 完美对应"最爱"：
`🐱(平和) → 😺 → 😸(不错) → 😹 → 😻(最爱)`（码点 1F431/1F63A/1F638/1F639/1F63B）。
该组在 OpenMoji / Twemoji / Noto / Fluent 四个开源 emoji 项目中全部覆盖。

**关键洞察**：OpenMoji 同一套猫脸同时提供**彩色**与**黑色线性**两版 → 单色路线也能要猫，且保留 App 现有的 palette 染色逻辑，化解了"彩色 vs 单色染色"的取舍。

## 5 组候选
| 组 | 有猫 | 画风 | License | 保留染色 | 集成 |
|---|---|---|---|---|---|
| OpenMoji 彩色 ⭐ | 全猫梯度 | 线+淡彩/克制 | CC BY-SA 4.0 | ❌ | flutter_svg+5 SVG |
| Fluent Flat | 全猫梯度 | 扁平现代 | MIT | ❌ | flutter_svg |
| Twemoji/catmoji | 全猫梯度 | 圆润卡通/萌 | CC-BY 4.0 | ❌ | flutter_svg |
| Noto | 全猫梯度 | 写实 | Apache-2.0 | ❌ | flutter_svg |
| OpenMoji 黑线 ⭐⭐ | 全猫梯度 | 单色线性 | CC BY-SA 4.0 | ✅ | SVG+mask/tint |
| Tabler mood+cat | 点缀一档 | 单色线性 | MIT | ✅ | tabler_icons 字体包 |
| (备选)Phosphor | 无 | 单色精致 | MIT | ✅ | phosphor_flutter |

## 交付物
- `260602-vo8-RESEARCH.md` — 完整调研（现状/梯度映射/5 组详述/横向对比/建议/来源）
- `docs/design/satisfaction-icons-showcase.html` — 可视化展示，CDN 实时渲染真实 SVG，含彩色/单色染色/深色三态；27 个图标 URL 全部 200 校验通过
- `docs/design/_satisfaction_icons_showcase.png` — 渲染截图

## 状态
纯调研产出，**未改任何代码**。待用户选定方向（彩色 emoji 路线 / OpenMoji 黑线单色染色路线 / Tabler）后，再开后续 quick 任务做 `satisfaction_emoji_picker.dart` 实际替换 + golden 重拍。
