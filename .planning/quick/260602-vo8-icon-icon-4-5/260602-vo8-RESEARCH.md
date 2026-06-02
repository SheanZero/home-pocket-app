---
title: 满意度 icon 候选调研（外部开源库 · 优先猫猫元素）
quick_id: 260602-vo8
date: 2026-06-02
status: awaiting-user-pick
---

# 满意度 icon 候选调研

## 现状

`lib/features/accounting/presentation/widgets/satisfaction_emoji_picker.dart`
当前用 **Flutter 内置 Material Icons**（单色线性，随 palette 染色）：

| 档位 | 当前 icon | 标签 |
|---|---|---|
| 1 平和 | `Icons.sentiment_neutral_outlined` | 平和 |
| 2 | `Icons.sentiment_satisfied_outlined` | — |
| 3 不错 | `Icons.sentiment_satisfied_alt_outlined` | 不错 |
| 4 | `Icons.sentiment_very_satisfied_outlined` | — |
| 5 最爱 | `Icons.favorite_border` | 最爱! |

**关键约束**：当前 icon 是单色线性，被 `palette.joy` / `palette.textSecondary` 染色（选中=丁香 Mauve，未选=灰）。
这决定了两条不同的路线：

- **路线 A（单色线性）** — 直接换 `IconData`，保留"随主题染色"的现有观感，零额外依赖或一个字体包。
- **路线 B（彩色 emoji）** — 换成全彩 SVG emoji，更可爱/有猫，但**放弃染色逻辑**（emoji 自带固定配色），需要 `flutter_svg` + 打包 5~9 个 SVG 资源。

---

## 🐱 核心发现：Unicode 自带「猫脸满意度梯度」

Unicode 有一组**天然按满意度递增**的猫脸 emoji，终点恰好是爱心眼 = 完美对应"最爱"：

```
🐱  →  😺  →  😸  →  😹  →  😻
中性   咧嘴   笑眼   喜极   爱心眼
平和         不错         最爱!
```

| 码点 | emoji | 含义 | 建议档位 |
|---|---|---|---|
| U+1F431 | 🐱 | 猫脸（中性） | 1 平和 |
| U+1F63A | 😺 | 咧嘴笑猫 | 2 |
| U+1F638 | 😸 | 笑眼咧嘴猫 | 3 不错 |
| U+1F639 | 😹 | 喜极而泣猫 | 4 |
| U+1F63B | 😻 | 爱心眼猫 | 5 最爱! |

这组码点在下面 4 个开源 emoji 项目里**全部都有**，只是画风不同 → 直接构成 4 组「猫猫」候选。

---

## 候选清单（5 组，优先猫猫）

### 组 1 — OpenMoji 猫脸 ⭐ 最推荐（猫 + 风格最贴近 App 调性）
- **画风**：黑描线 + 淡彩填色，克制、设计感强，和 App 现在的"柔和单色线性"过渡最自然。
- **License**：CC BY-SA 4.0（需署名，App 内"关于/鸣谢"列一行即可）。
- **集成**：下载 5 个 SVG（`1F431/1F63A/1F638/1F639/1F63B.svg`）→ `assets/` → `flutter_svg` 渲染。
- **来源**：<https://openmoji.org/library/> · GitHub `hfg-gmuend/openmoji`
- **取舍**：彩色，不再随 Mauve/灰染色；但 OpenMoji 描线本身偏单色，违和感最小。

### 组 2 — Fluent Emoji（Flat 变体）猫脸（现代/MIT 最干净）
- **画风**：微软出品，有 3D / Flat / High-Contrast 三套。**Flat 变体**扁平现代，和 teal 设计语言搭。
- **License**：MIT（最宽松，无署名负担）。
- **集成**：取 Flat 子集 SVG → `flutter_svg`。
- **来源**：GitHub `microsoft/fluentui-emoji`
- **取舍**：彩色固定；High-Contrast 变体可作深色模式备选。

### 组 3 — Twemoji / catmoji 猫脸（活泼/圆润卡通）
- **画风**：Twitter 风，饱满圆润、卡通感强，最"可爱讨喜"。
- **特别项**：**catmoji** = "Twemoji 但全是猫" —— 把所有人脸 emoji 都替换成猫版本，主题统一度最高。
- **License**：CC-BY 4.0。
- **来源**：GitHub `jdecked/twemoji`、`catmoji/catmoji`
- **取舍**：彩色卡通，最跳脱当前克制风格——若想要"萌"的方向选它。

### 组 4 — Noto Emoji 猫脸（Google/Apache-2.0）
- **画风**：Google，写实细腻、体积感强。
- **License**：Apache 2.0（宽松，署名友好）。
- **来源**：GitHub `googlefonts/noto-emoji`
- **取舍**：彩色，细节多，小尺寸（24px）下略糊，是 4 组彩色里最不推荐的，但许可证最省心。

### 组 5 — Tabler「mood + cat」单色线性 ⭐ 唯一保留现有染色路线
- **画风**：单色线性，24×24 / 2px stroke，和当前 Material 线性 icon 同一气质，**可继续被 palette 染色**。
- **猫元素**：Tabler 有独立的 `cat` 线性 icon，可放在最高档当"猫彩蛋"；其余档位用 `mood-neutral / mood-smile / mood-happy / mood-crazy-happy / mood-heart`。
- **License**：MIT，5900+ icon。
- **Flutter 包**：`tabler_icons`（pub.dev，字体包，零 SVG 资源）。
- **来源**：<https://tabler.io/icons> · GitHub `tabler/tabler-icons`
- **取舍**：**改动最小、风险最低**（换 `IconData` 即可，golden 重拍量小），但猫只能点缀一档，不是"全猫梯度"。

### 备选（无猫，纯升级线性观感）
- **Phosphor**（`phosphor_flutter`，MIT，6 种字重）：`SmileyMeh → Smiley → SmileyWink → 笑 → Heart`，线性最精致，想保持单色又要比 Material 更好看选它。
- **Lucide**（`lucide_icons`，ISC）：`Meh / Smile / SmilePlus / Laugh / Heart`，干净极简。

---

## 横向对比

| 组 | 有猫 | 画风 | License | 保留染色 | 集成成本 | golden 重拍 |
|---|---|---|---|---|---|---|
| 1 OpenMoji | ✅全猫梯度 | 线+淡彩/克制 | CC BY-SA 4.0 | ❌ | SVG×5 +flutter_svg | 中 |
| 2 Fluent Flat | ✅全猫梯度 | 扁平现代 | **MIT** | ❌ | SVG×5 +flutter_svg | 中 |
| 3 Twemoji/catmoji | ✅全猫梯度 | 圆润卡通/萌 | CC-BY 4.0 | ❌ | SVG×5 +flutter_svg | 中 |
| 4 Noto | ✅全猫梯度 | 写实 | Apache-2.0 | ❌ | SVG×5 +flutter_svg | 中 |
| 5 Tabler mood+cat | ⚠️点缀一档 | 单色线性 | **MIT** | ✅ | 字体包/换 IconData | **小** |
| 备选 Phosphor | ❌ | 单色线性精致 | MIT | ✅ | 字体包 | 小 |

---

## 建议

- **想要「猫猫满意度梯度」（用户原意优先项）** → **组 1 OpenMoji**（风格过渡最稳）或 **组 2 Fluent Flat**（MIT 无署名负担）。
  - 代价：放弃单色染色，引入 `flutter_svg` + 5 个 SVG 资源，深色模式需单独验证对比度。
- **想要最低风险、保留现有观感、猫作彩蛋** → **组 5 Tabler**（换 `IconData`，加 `tabler_icons`，最高档放 `cat`）。
- **不要猫、只想线性升级** → Phosphor。

## 待用户决策

1. 走**彩色 emoji 路线**（真·全猫梯度，组 1/2/3/4 选一）还是**单色线性路线**（组 5 / Phosphor）？
2. 若彩色：选哪一组画风？署名负担（CC vs MIT）是否在意？
3. 决定后再开后续 quick 任务做实际替换 + golden 重拍。

## 来源
- OpenMoji — <https://openmoji.org/library/> · `hfg-gmuend/openmoji`
- Fluent Emoji — `microsoft/fluentui-emoji`
- Twemoji / catmoji — `jdecked/twemoji` · `catmoji/catmoji`
- Noto Emoji — `googlefonts/noto-emoji`
- Tabler Icons — <https://tabler.io/icons> · `tabler/tabler-icons`
- Phosphor — <https://phosphoricons.com/> · `phosphor_flutter`
- Unicode 猫脸字符集 — <https://emojipedia.org/cat-face>
