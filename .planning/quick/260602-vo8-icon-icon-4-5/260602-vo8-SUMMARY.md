---
quick_id: 260602-vo8
status: research-delivered
date: 2026-06-02
type: research / discovery (no code changed)
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
