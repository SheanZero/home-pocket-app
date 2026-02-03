# Home Pocket 商业需求文档 (BRD)
## Business Requirements Document - Complete Feature Specification

**文档版本:** 2.0
**日期:** 2026年2月2日
**状态:** Draft for Review
**产品名称:** Home Pocket (まもる家計簿)


---

## 目录

1. [执行摘要](#1-执行摘要)
2. [产品愿景与定位](#2-产品愿景与定位)
3. [目标用户](#3-目标用户)
4. [完整功能清单](#4-完整功能清单)
5. [功能详细规格](#5-功能详细规格)
6. [UI/UX风格建议](#6-uiux风格建议)
7. [技术架构概要](#7-技术架构概要)
8. [开发路线图](#8-开发路线图)
9. [商业模式与定价](#9-商业模式与定价)
10. [成功指标](#10-成功指标)
11. [风险与缓解](#11-风险与缓解)

---

## 1. 执行摘要

### 1.1 产品定义

Home Pocket 是一款面向日本家庭的**隐私优先、防篡改、趣味化**记账应用。与市场主流的自动化/云端化竞品不同，本产品采用 Local-First 策略，通过哈希链保证数据不可篡改，同时融入日本文化元素，将枯燥的记账变成有趣的家庭互动游戏。

### 1.2 核心价值主张

| 维度 | 竞品现状 | Home Pocket 差异化 |
|------|---------|-------------------|
| **信任** | 云端存储，公司可见数据 | E2EE加密，防篡改哈希链 |
| **体验** | 功能导向，枯燥记账 | 游戏化，社交货币式反馈 |
| **关系** | 监控式共享 | 尊重隐私的家庭协作 |
| **文化** | 通用设计 | 深度融入日本文化（Kakeibo、Omikuji、推し活） |

### 1.3 产品定位升级

**原定位：** "永远不再为钱吵架"
**新定位：** "把为钱吵架变成一起玩游戏"

### 1.4 关键决策确认

| 决策项 | 确认结果 |
|-------|---------|
| 趣味功能核心目标 | 提高日活/留存，增加差异性 |
| LLM 依赖程度 | MVP 本地化，LLM 仅作为 Premium 增强 |
| 双轨账本启用时机 | 无论单人或家庭模式都自动开启（核心功能） |
| Ohtani Converter 更新 | OTA 热更新 |
| 禀议书离线支持 | MVP 使用离线模板库 |
| 趣味元素可关闭性 | 部分可关闭，家庭互动功能不可关闭 |

---

## 2. 产品愿景与定位

### 2.1 愿景声明

> 成为日本家庭财务信任与欢乐的守护者，让每一次记账都成为家庭互动的美好瞬间。

### 2.2 使命

1. **守护信任**：通过防篡改技术，让家庭成员之间建立真正的财务透明
2. **创造欢乐**：将枯燥的记账变成有趣的日常仪式
3. **尊重个体**：在家庭共享中保护个人隐私空间

### 2.3 产品原则

| 原则 | 说明 | 体现 |
|------|------|------|
| **隐私至上** | 用户数据只属于用户 | E2EE、本地优先、无账号 |
| **诚实透明** | 家庭成员间无法隐藏 | 哈希链防篡改 |
| **温暖有趣** | 记账是快乐的事 | 趣味换算、运势占卜、游戏化 |
| **尊重空间** | 个人需要私密领域 | 灵魂账户、互不侵犯条约 |
| **开源开放** | 代码完全透明可审计 | 项目开源，社区共建 |

### 2.4 开源策略

**本项目采用完全开源模式：**

- **代码仓库**：GitHub 公开仓库
- **许可证**：MIT 或 Apache 2.0（待定）
- **核心代码**：客户端完全开源，服务端 Relay 组件开源
- **商业模式**：通过增值服务（云同步、LLM增强）获取收入，而非代码闭源

**开源的好处：**
1. 增强用户对隐私保护的信任（代码可审计）
2. 吸引社区贡献者参与开发
3. 建立技术品牌和口碑
4. 降低用户对数据安全的顾虑

### 2.5 竞争定位

```
                    自动化程度
                        ↑
                        │
        Money Forward   │
        (2,500银行集成)  │
                        │
    ────────────────────┼────────────────────→ 隐私保护
                        │
              Zaim      │      Home Pocket
           (1,300银行)   │   (零银行集成，E2EE)
                        │
                        │   MoneyNote
                        │   (本地存储，无加密)
```

**Home Pocket 的蓝海位置：** 高隐私 + 适度自动化 + 趣味化

---

## 3. 目标用户

### 3.1 主要用户画像

#### 画像 A：夫妻用户"关系守护者" (Primary Target)

| 属性 | 描述 |
|------|------|
| **人口统计** | 25-50岁，已婚或同居伴侣 |
| **收入** | 年收入 ¥400万+，双收入家庭 |
| **痛点** | 经济问题易引发矛盾，缺乏财务透明但又需要个人空间 |
| **动机** | 维持关系稳定，相互理解，在夫妻生活中保持私人空间，不让经济问题成为生活的绊脚石 |
| **付费意愿** | 高（关系稳定 > ¥480/月） |

**典型场景：**
> 田中夫妇（35岁+32岁）：结婚3年，都有全职工作。两人希望共同管理家庭开支，但也想保留各自的"小金库"用于个人爱好。曾因为不了解对方的消费习惯产生过小摩擦，希望找到透明与隐私的平衡。

#### 画像 B：单人用户"爱好经营者"

| 属性 | 描述 |
|------|------|
| **人口统计** | 25-45岁，单身或暂未共同理财 |
| **收入** | 年收入 ¥350-700万 |
| **痛点** | 爱好消费缺乏规划，容易冲动消费导致月底紧张 |
| **动机** | 通过记账让自己的爱好持续健康发展，平衡生活必需与精神追求 |
| **付费意愿** | 中等（趣味功能驱动） |

**典型场景：**
> 佐藤健（31岁）：IT工程师，热爱摄影。每月在器材和外拍上有固定支出，但经常因为冲动购买镜头导致生活费紧张。希望通过双轨账本清晰区分"生存"与"灵魂"消费，让摄影爱好可持续发展。

### 3.2 用户规模估算

| 细分市场 | 家庭/个人数 | 渗透目标 | 目标用户 |
|---------|------------|---------|---------|
| 25-50岁夫妻家庭 | 800万 | 2% | 160,000 |
| 有爱好的单人用户 | 500万 | 1.5% | 75,000 |
| **合计 SAM** | **1,300万** | **1.8%** | **235,000** |

---

## 4. 完整功能清单

### 4.1 功能分类总览

| 分类 | MVP | V1.0 | V2.0 | 总计 |
|------|-----|------|------|------|
| A. 基础记账 | 12 | 3 | 2 | 17 |
| B. 家庭协作 | 6 | 4 | 2 | 12 |
| C. 趣味互动 | 4 | 3 | 2 | 9 |
| D. 数据分析 | 4 | 5 | 3 | 12 |
| E. 系统设置 | 6 | 2 | 1 | 9 |
| **总计** | **32** | **17** | **10** | **59** |

---

### 4.2 完整功能清单表

#### A. 基础记账功能

| ID | 功能名称 | 阶段 | 优先级 | 工时 | 描述 |
|----|---------|------|--------|------|------|
| A01 | 支出记录 | MVP | P0 | 3d | 金额、分类、备注、时间、照片 |
| A02 | 收入记录 | MVP | P0 | 2d | 工资、奖金、副业等收入类型 |
| A03 | 分类管理 | MVP | P0 | 3d | 预设20个分类 + 自定义分类 |
| A04 | 分类图标与颜色 | MVP | P1 | 4d | Material Symbols图标 + 自定义颜色 |
| A05 | 交易列表 | MVP | P0 | 4d | 按日/周/月分组，支持筛选 |
| A06 | 交易搜索 | MVP | P1 | 3d | 按金额、分类、备注关键词搜索 |
| A07 | 交易修正 | MVP | P0 | 4d | 插入修正记录，保留审计轨迹 |
| A08 | 快捷输入模板 | MVP | P1 | 3d | TF Lite 学习常用交易，一键录入 |
| A09 | Widget 快捷入口 | MVP | P1 | 4d | iOS WidgetKit / Android Glance |
| A10 | 隐私 OCR 扫描 | MVP | P1 | 7d | 本地 ML Kit 识别收据 |
| A11 | 商家自动分类 | MVP | P2 | 3d | 500+ 日本商家映射库 |
| A12 | 深色模式 | MVP | P1 | 3d | OLED 优化真黑背景 |
| A13 | 语音输入 | V1.0 | P2 | 5d | 离线语音转文字 |
| A14 | 条码扫描 | V1.0 | P2 | 3d | JAN/EAN 条码识别 |
| A15 | 高级搜索过滤 | V1.0 | P2 | 6d | FTS5 全文搜索 + 多条件组合 |
| A16 | 批量编辑 | V2.0 | P3 | 4d | 批量修改分类/标签 |
| A17 | 导入历史数据 | V1.0 | P2 | 5d | 从 CSV/其他 App 导入 |

#### B. 家庭协作功能

| ID | 功能名称 | 阶段 | 优先级 | 工时 | 描述 |
|----|---------|------|--------|------|------|
| B01 | 家庭配对（面对面） | MVP | P0 | 5d | QR码扫描配对 |
| B02 | 家庭配对（远程） | MVP | P0 | 4d | 6位短码 + Relay 匹配 |
| B03 | 数据同步（定时） | MVP | P0 | 6d | 每日10次免费自动同步 |
| B04 | 个人/家庭视图切换 | MVP | P0 | 4d | Me模式 vs Family模式 |
| B05 | 家庭内部转账 | MVP | P0 | 6d | 两阶段提交保证一致性 |
| B06 | 购物篮同步（家庭） | MVP | P1 | 5d | 家庭协作购物清单 + 记账关联 |
| B06b | 心愿单（私有） | MVP | P1 | 4d | 个人购物心愿单，可选择性公开 |
| B07 | 实时同步推送 | V1.0 | P1 | 12d | WebSocket + FCM/APNs |
| B08 | 多设备同步 (3+) | V1.0 | P2 | 15d | 家庭网络最多5设备 |
| B09 | 照片云同步 | V1.0 | P1 | 10d | S3 加密存储 + 压缩 |
| B10 | 子女零用钱管理 | V1.0 | P3 | 12d | 子账户 + 只读权限 |
| B11 | 账单分摊计算 | V2.0 | P2 | 8d | N人AA制 + 不等额分摊 |
| B12 | 家庭预算池 | V1.0 | P0 | 7d | 虚拟信封共同储蓄 |

#### C. 趣味互动功能 ⭐ NEW

| ID | 功能名称 | 阶段 | 优先级 | 工时 | 描述 | 可关闭 |
|----|---------|------|--------|------|------|--------|
| C01 | 大谷翔平换算器 | MVP | P1 | 3d | 金额→文化符号趣味换算 | ✅ 可关闭 |
| C02a | 小票占卜 | MVP | P1 | 4d | 拍摄购物小票时触发占卜，小票作为签纸 | ✅ 可关闭 |
| C02b | 今日运势预测 | MVP | P1 | 3d | 首页主动点击预测运势，预测页面插入广告 | ✅ 可关闭 |
| C03 | 双轨账本（生存/灵魂） | MVP | P0 | 8d | 生存必需 vs 爱好消费分离，核心功能 | ❌ 强制开启 |
| C04 | 灵魂消费庆祝动画 | MVP | P2 | 3d | 粒子特效 + 正向文案 | ✅ 可关闭 |
| C05 | 互不侵犯条约 | V1.0 | P1 | 6d | 灵魂预算内隐藏明细 | ❌ 家庭模式强制 |
| C06 | 灵魂提案禀议书（离线） | V1.0 | P2 | 7d | 本地模板生成趣味提案 | ❌ 家庭模式强制 |
| C07 | 生存红利分红协议 | V1.0 | P1 | 7d | 省钱自动转入灵魂账户 | ❌ 家庭模式强制 |
| C08 | 今日运势占卜（LLM增强） | V2.0 | P3 | 3d | Gemini 生成创意运势 | ✅ Premium |
| C09 | 灵魂提案禀议书（LLM） | V2.0 | P3 | 3d | Gemini 生成搞笑理由 | ✅ Premium |

#### D. 数据分析与报表

| ID | 功能名称 | 阶段 | 优先级 | 工时 | 描述 |
|----|---------|------|--------|------|------|
| D01 | 月度支出饼图 | MVP | P0 | 3d | 按分类汇总可视化 |
| D02 | 日历热图 | MVP | P1 | 5d | GitHub风格365天热力图 |
| D03 | 审计日志查看器 | MVP | P1 | 4d | 哈希链验证 + PDF导出 |
| D04 | 异常消费检测 | MVP | P2 | 3d | Z-score 标准差预警 |
| D05 | 预算目标设定 | MVP | P0 | 5d | 按分类设定月度上限，与灵魂消费紧密结合（伴侣可见预算但不可见灵魂消费明细） |
| D06 | 预算达成游戏化 | V1.0 | P2 | 3d | 成就徽章 + 连续达成奖励 |
| D07 | 财务健康评分 | V1.0 | P2 | 5d | 0-100分综合评估 |
| D08 | 税务导出模板 | V1.0 | P1 | 6d | 青色申告/确定申告格式 |
| D09 | AI 消费洞察（本地） | V1.0 | P2 | 5d | Gemini Nano 本地分析 |
| D10 | 资产净值追踪 | V2.0 | P2 | 5d | 多账户净值趋势图 |
| D11 | 年度财务报告 | V2.0 | P2 | 6d | 自动生成年度总结 |
| D12 | 会计软件导出 | V2.0 | P3 | 10d | Freee/MF Cloud/Yayoi |

#### E. 系统与设置

| ID | 功能名称 | 阶段 | 优先级 | 工时 | 描述 |
|----|---------|------|--------|------|------|
| E01 | 隐私宣言引导 | MVP | P0 | 2d | 首次启动3页滑动引导 |
| E02 | 密钥生成与备份 | MVP | P0 | 4d | Ed25519 + Recovery Kit |
| E03 | 生物识别锁 | MVP | P0 | 2d | FaceID / 指纹 / PIN |
| E04 | 信任状态指示器 | MVP | P0 | 3d | 绿/黄/红 同步与安全状态 |
| E05 | 大字体模式 | MVP | P1 | 3d | 动态字体缩放 |
| E06 | 色盲友好调色板 | MVP | P2 | 2d | 形状+颜色双重指示 |
| E07 | 趣味功能开关 | V1.0 | P1 | 2d | 部分趣味功能可关闭 |
| E08 | 主题切换 | V1.0 | P2 | 5d | 和风/赛博/极简三种风格 |
| E09 | 百年档案导出 | V2.0 | P3 | 8d | 人类可读PDF + 可恢复JSON |

---

### 4.3 功能依赖关系图

```
MVP Core
├── A01-A07 基础记账
├── B01-B06 家庭协作基础
├── E01-E04 安全基础
│
├── C03 双轨账本 ←── 触发条件：家庭配对完成
│   ├── C01 大谷换算器
│   ├── C02 运势占卜
│   └── C04 灵魂庆祝动画
│
└── D01-D04 基础分析

V1.0 Enhancement
├── B07-B09 高级同步 (依赖服务端)
├── C05 互不侵犯条约 (依赖 C03)
├── C06 禀议书离线版 (依赖 C03)
├── C07 生存红利 (依赖 C03)
└── D05-D09 高级分析

V2.0 Premium
├── C08-C09 LLM增强 (依赖 Gemini API)
└── D10-D12 高级报表
```

---

## 5. 功能详细规格

### 5.1 趣味功能详细规格

#### C01: 大谷翔平换算器 (Ohtani Converter)

**功能概述：**
将消费金额换算成日本国民级文化符号，创造"社交货币"式的记账体验。

**触发机制：**
- 触发时机：交易保存成功后 0.5 秒
- 展示形式：Toast 横幅动画，3 秒后自动消失
- 可关闭：✅ 设置中可关闭

**换算单位库（OTA 热更新）：**

```json
{
  "version": "1.0.0",
  "units": [
    {
      "id": "ohtani_salary",
      "name": "大谷翔平的工资",
      "unit_yen": 2000,
      "format_ja": "この金額は大谷翔平の{value}秒分の給料です",
      "format_zh": "这笔钱相当于大谷翔平 {value} 秒的工资",
      "icon": "⚾",
      "category": "sports"
    },
    {
      "id": "yoshinoya_gyudon",
      "name": "吉野家牛丼",
      "unit_yen": 500,
      "format_ja": "{value}杯の牛丼を食べました",
      "format_zh": "你刚吃掉了 {value} 碗牛丼",
      "icon": "🍚",
      "category": "food"
    },
    {
      "id": "idol_handshake",
      "name": "偶像握手券",
      "unit_yen": 1500,
      "format_ja": "推しと{value}回握手できる金額です",
      "format_zh": "这相当于 {value} 次偶像握手机会",
      "icon": "🤝",
      "category": "entertainment"
    },
    {
      "id": "shiba_food",
      "name": "柴犬高级狗粮",
      "unit_yen": 10000,
      "format_ja": "柴犬が{value}ヶ月分のご飯を食べられます",
      "format_zh": "这足以让一只柴犬吃 {value} 个月",
      "icon": "🐕",
      "category": "pet"
    },
    {
      "id": "gacha_pull",
      "name": "手游十连抽",
      "unit_yen": 3000,
      "format_ja": "{value}回の10連ガチャが回せます",
      "format_zh": "你刚刚抽了 {value} 发十连",
      "icon": "🎰",
      "category": "game"
    },
    {
      "id": "lawson_karaage",
      "name": "罗森炸�的�的鸡块",
      "unit_yen": 220,
      "format_ja": "Lチキ{value}個分です",
      "format_zh": "相当于 {value} 块罗森炸鸡",
      "icon": "🍗",
      "category": "food"
    },
    {
      "id": "train_yamanote",
      "name": "山手线一圈",
      "unit_yen": 210,
      "format_ja": "山手線を{value}周できます",
      "format_zh": "可以坐 {value} 圈山手线",
      "icon": "🚃",
      "category": "transport"
    },
    {
      "id": "onsen_entry",
      "name": "温泉入浴",
      "unit_yen": 800,
      "format_ja": "温泉に{value}回入れます",
      "format_zh": "可以泡 {value} 次温泉",
      "icon": "♨️",
      "category": "leisure"
    }
  ],
  "update_url": "https://api.homepocket.app/v1/converter/units"
}
```

**用户设置：**
- 默认单位宇宙：随机 / 食物系 / 娱乐系 / 运动系 / 自定义
- 显示频率：每次 / 每3次 / 每日首次
- 完全关闭：是/否

**技术实现：**
- 本地 JSON 文件 + OTA 更新检查（每日一次）
- 更新通过 CDN 分发，版本号比对
- 开发工时：3 天

---

#### C02a: 小票占卜 (Receipt Omikuji)

**功能概述：**
将购物小票变成"签纸"，用户拍摄小票时自动触发占卜，融入日本 Omikuji 文化。小票上的金额、商品、日期等信息作为"签纸"的内容，生成独特的运势解读。

**触发机制：**
- 触发时机：用户使用OCR扫描购物小票时
- 展示形式：小票图片变形为签纸，翻转展示运势
- 可关闭：✅ 设置中可关闭

**创意点：**
- 小票 = 签纸，每张小票都是独一无二的"签"
- 根据小票内容生成个性化解读（如购买食材→"今日厨艺大吉"）
- 收集不同商家、金额的"签"形成图鉴

#### C02b: 今日运势预测 (Daily Fortune)

**功能概述：**
首页提供主动式运势预测入口，用户点击后进入预测页面。该功能作为广告变现入口。

**触发机制：**
- 触发时机：用户主动点击首页的"今日运势"入口
- 展示形式：进入专门的运势预测页面
- 广告植入：预测结果页面展示激励广告或插屏广告
- 可关闭：✅ 设置中可隐藏入口

**变现设计：**
- 每日首次预测免费
- 重新抽签需观看激励广告
- 预测结果页底部展示原生广告

**运势等级与概率：**

| 等级 | 日文 | 概率 | 颜色 | 文案风格 |
|------|------|------|------|---------|
| 大吉 | 大吉 | 5% | 金色 | 极度正面，夸张祝福 |
| 中吉 | 中吉 | 15% | 红色 | 正面，温馨鼓励 |
| 小吉 | 小吉 | 25% | 橙色 | 轻度正面 |
| 吉 | 吉 | 30% | 绿色 | 平稳，日常祝福 |
| 末吉 | 末吉 | 15% | 蓝色 | 略带警示的好运 |
| 凶 | 凶 | 8% | 灰色 | 幽默调侃 |
| 大凶 | 大凶 | 2% | 紫色 | 搞笑夸张的"坏运" |

**种子算法（本地版）：**
```dart
int generateSeed(Transaction tx) {
  // 使用交易属性生成确定性种子
  final dateHash = tx.timestamp.day * 31 + tx.timestamp.month;
  final amountHash = tx.amount % 1000;
  final noteHash = tx.note?.hashCode ?? 0;
  return (dateHash ^ amountHash ^ noteHash) & 0x7FFFFFFF;
}

OmikujiResult getOmikuji(int seed) {
  final random = Random(seed);
  final roll = random.nextDouble() * 100;

  if (roll < 5) return OmikujiResult.daikichi;
  if (roll < 20) return OmikujiResult.chukichi;
  if (roll < 45) return OmikujiResult.shokichi;
  if (roll < 75) return OmikujiResult.kichi;
  if (roll < 90) return OmikujiResult.suekichi;
  if (roll < 98) return OmikujiResult.kyo;
  return OmikujiResult.daikyo;
}
```

**本地文案库（示例）：**
```json
{
  "daikichi": [
    {
      "fortune": "今日の出費は、未来への投資！",
      "lucky_item": "レシートの端数",
      "lucky_color": "金色",
      "advice": "衝動買いも時には正解です"
    },
    {
      "fortune": "お金は天下の回りもの、今日使った分は倍になって戻ってくる！",
      "lucky_item": "小銭",
      "lucky_color": "黄色",
      "advice": "自分へのご褒美を忘れずに"
    }
  ],
  "daikyo": [
    {
      "fortune": "財布が泣いています…でも明日があるさ！",
      "lucky_item": "貯金箱",
      "lucky_color": "白",
      "advice": "今日は水だけで過ごすのも一興"
    }
  ]
}
```

**收集图鉴系统：**
```sql
CREATE TABLE omikuji_collection (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,           -- 'daikichi', 'kyo' 等
  transaction_id TEXT NOT NULL,
  fortune_text TEXT,
  lucky_item TEXT,
  lucky_color TEXT,
  collected_at INTEGER NOT NULL,
  is_favorite INTEGER DEFAULT 0,
  FOREIGN KEY (transaction_id) REFERENCES transactions(id)
);

-- 图鉴完成度查询
SELECT level, COUNT(*) as count
FROM omikuji_collection
GROUP BY level;
```

**开发工时：** 5 天（本地版）

---

#### C03: 双轨账本 (Dual Ledger System)

**功能概述：**
将消费分为"生存账户"（必需支出）和"灵魂账户"（爱好支出），赋予爱好消费正向意义。

**启用条件：**
- 作为App核心功能，无论单人模式或家庭模式都自动开启
- 不可关闭
- 这是本产品的核心差异化功能

**数据模型扩展：**
```sql
-- 扩展分类表
ALTER TABLE categories ADD COLUMN ledger_type TEXT DEFAULT 'survival';
-- ledger_type: 'survival' | 'soul' | 'auto'

-- 灵魂账户配置
CREATE TABLE soul_account_config (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  oshi_name TEXT,              -- "高达基金"、"美妆基金"
  icon_emoji TEXT,
  color_hex TEXT,
  monthly_budget INTEGER,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, device_id)
);

-- 预设分类映射
INSERT INTO category_ledger_defaults VALUES
  ('food_groceries', 'survival'),
  ('food_restaurant', 'soul'),
  ('transport_commute', 'survival'),
  ('transport_travel', 'soul'),
  ('housing_rent', 'survival'),
  ('housing_furniture', 'soul'),
  ('entertainment_games', 'soul'),
  ('entertainment_movies', 'soul'),
  ('hobby_figure', 'soul'),
  ('hobby_idol', 'soul'),
  ('medical', 'survival'),
  ('education', 'survival');
```

**LLM 自动分类（本地 Gemini Nano）：**
```dart
Future<LedgerType> classifyTransaction(Transaction tx) async {
  // 优先使用本地规则
  final localResult = _localClassifier.classify(tx);
  if (localResult.confidence > 0.9) {
    return localResult.type;
  }

  // 低置信度时使用 Gemini Nano
  final prompt = '''
判断以下消费属于"生存必需"还是"灵魂享乐"：
- 商家：${tx.merchant}
- 金额：${tx.amount}円
- 备注：${tx.note}
- 分类：${tx.category}

规则：
- 生存：房租、水电、超市食品、医疗、交通通勤、必需衣物
- 灵魂：游戏、手办、演唱会、美妆（非必需）、旅行、收藏品、外食

只回复: "survival" 或 "soul"
''';

  final result = await geminiNano.generate(prompt);
  return result.trim() == 'soul' ? LedgerType.soul : LedgerType.survival;
}
```

**UI 差异化设计：**

| 元素 | 生存账户 | 灵魂账户 |
|------|---------|---------|
| 主色调 | 冷静蓝 #4A90D9 | 活力橙 #FF8C42 |
| 交易卡片标题 | "支出 ¥xxx" | "精神资产 +1 💖" |
| 进度条 | 红绿灯预警式 | 快乐值充能条 |
| 超支提示 | "⚠️ 本月超支" | "灵魂太过充实了呢～" |
| 月报标题 | "生存成本报告" | "灵魂闪耀报告" |

**月报文案模板：**
```json
{
  "monthly_summary": {
    "survival": "本月为生活苟且了 ¥{survival_total}",
    "soul": "为灵魂闪耀投入了 ¥{soul_total}",
    "ratio_healthy": "生存与灵魂比例 {ratio}，平衡得刚刚好！",
    "ratio_soul_high": "灵魂指数超标！但人生苦短，及时行乐～",
    "ratio_survival_high": "太理性了！适当放纵一下自己吧"
  }
}
```

**开发工时：** 8 天

---

#### C05: 互不侵犯条约 (Non-Aggression Pact)

**功能概述：**
在设定的灵魂预算额度内，向伴侣隐藏具体明细，只显示预算使用进度。

**启用条件：**
- 需要先开启双轨账本 (C03)
- 家庭模式下自动可用
- 不可关闭

**可见性规则：**

| 场景 | 自己看到 | 伴侣看到 |
|------|---------|---------|
| 灵魂消费（额度内） | 完整明细 | 进度条（绿/黄/红） |
| 灵魂消费（超额部分） | 完整明细 | 超额部分的明细 |
| 生存消费 | 完整明细 | 完整明细 |

**进度条颜色规则：**
- 🟢 绿色：0-60% 预算使用
- 🟡 黄色：60-90% 预算使用
- 🔴 红色：90-100% 预算使用
- ⚫ 黑色脉冲：超额

**数据模型：**
```sql
CREATE TABLE privacy_pact (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  soul_budget INTEGER NOT NULL,       -- 月度灵魂预算
  visibility_mode TEXT DEFAULT 'pact', -- 'transparent' | 'pact' | 'private'
  effective_month TEXT NOT NULL,       -- '2026-02'
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, device_id, effective_month)
);

-- 同步时的可见性过滤逻辑
CREATE VIEW partner_visible_transactions AS
SELECT
  t.*,
  CASE
    WHEN t.ledger_type = 'survival' THEN 'full'
    WHEN t.ledger_type = 'soul' AND
         (SELECT SUM(amount) FROM transactions
          WHERE device_id = t.device_id
          AND ledger_type = 'soul'
          AND strftime('%Y-%m', timestamp, 'unixepoch') = strftime('%Y-%m', t.timestamp, 'unixepoch')
          AND timestamp <= t.timestamp) >
         (SELECT soul_budget FROM privacy_pact
          WHERE device_id = t.device_id
          AND effective_month = strftime('%Y-%m', t.timestamp, 'unixepoch'))
    THEN 'full'  -- 超额部分可见
    ELSE 'hidden'
  END as visibility
FROM transactions t;
```

**同步协议扩展：**
```protobuf
message TransactionSync {
  string id = 1;
  int64 amount = 2;
  string category_id = 3;
  int64 timestamp = 4;
  string note = 5;
  string ledger_type = 6;

  // 新增：可见性控制
  enum Visibility {
    FULL = 0;      // 完全可见
    SUMMARY = 1;   // 只同步金额，不同步明细
    HIDDEN = 2;    // 不同步（但计入预算统计）
  }
  Visibility partner_visibility = 7;
}
```

**开发工时：** 6 天

---

#### C06: 灵魂提案禀议书 (Soul Pitch - Offline)

**功能概述：**
借鉴日本职场"禀议"制度，用趣味模板生成大额消费提案，把冲突变成协商游戏。

**MVP版本：离线模板库**

**提案模板库：**
```json
{
  "templates": {
    "gaming": {
      "title_format": "【禀议】关于购入{item}的提案",
      "reasons": [
        {
          "title": "技术论证",
          "templates": [
            "高性能{spec}可以提升家庭整体数字素养",
            "{item}的{feature}功能可以促进亲子互动",
            "相比外出娱乐，在家{activity}更经济实惠"
          ]
        },
        {
          "title": "情感价值",
          "templates": [
            "可以在家陪伴您，不再{bad_habit}",
            "这是我们共同的回忆投资",
            "压力释放对家庭和谐至关重要"
          ]
        },
        {
          "title": "美学价值",
          "templates": [
            "{color}色与家居风格高度契合",
            "极简设计不会破坏房间美感",
            "可以成为客厅的谈资亮点"
          ]
        }
      ]
    },
    "fashion": {
      "title_format": "【禀议】关于添置{item}的提案",
      "reasons": [...]
    },
    "hobby": {
      "title_format": "【禀议】关于收藏{item}的提案",
      "reasons": [...]
    }
  },
  "variables": {
    "PS5 Pro": {
      "category": "gaming",
      "spec": "算力",
      "feature": "Share Play",
      "activity": "玩游戏",
      "bad_habit": "出去喝酒",
      "color": "白"
    },
    "高达模型": {
      "category": "hobby",
      "spec": "精密度",
      "feature": "可动关节",
      "activity": "手工制作",
      "bad_habit": "刷手机",
      "color": "红白蓝"
    }
  }
}
```

**生成算法：**
```dart
class SoulPitchGenerator {
  String generate(String itemName, int amount) {
    // 1. 匹配商品类别
    final category = _matchCategory(itemName);
    final template = _templates[category];

    // 2. 随机选择3个理由（每类1个）
    final reasons = template.reasons.map((reasonType) {
      final randomTemplate = reasonType.templates.randomElement();
      return _fillVariables(randomTemplate, itemName);
    }).toList();

    // 3. 生成正式提案文档
    return '''
━━━━━━━━━━━━━━━━━━━━━
${template.titleFormat.replaceAll('{item}', itemName)}
━━━━━━━━━━━━━━━━━━━━━

申请人：{applicant_name}
申请金额：¥${_formatAmount(amount)}
申请日期：${DateTime.now().toIso8601String().substring(0, 10)}

【提案理由】

1️⃣ ${reasons[0]}

2️⃣ ${reasons[1]}

3️⃣ ${reasons[2]}

【投资回报分析】
按预计使用寿命 3 年计算，日均成本仅 ¥${(amount / 1095).toStringAsFixed(0)}

━━━━━━━━━━━━━━━━━━━━━
恳请批准 🙏
━━━━━━━━━━━━━━━━━━━━━
''';
  }
}
```

**审批流程：**
```
发起人                              审批人
   │                                  │
   ├── 生成提案 ──────────────────────►│
   │                                  │
   │◄────────────────── 收到通知 ──────┤
   │                                  │
   │                            ┌─────┴─────┐
   │                            │  审批选项  │
   │                            ├───────────┤
   │                            │ ✅ 承认   │
   │                            │ ❌ 否决   │
   │                            │ ⚡ 条件付 │
   │                            └─────┬─────┘
   │                                  │
   │◄────────────── 审批结果 ──────────┤
   │                                  │
   ├── [承认] 自动记录到灵魂账户        │
   ├── [否决] 归档为"已否决提案"        │
   └── [条件付] 显示条件 + 记录         │
```

**数据模型：**
```sql
CREATE TABLE soul_pitch (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  item_name TEXT NOT NULL,
  amount INTEGER NOT NULL,
  applicant_device_id TEXT NOT NULL,
  generated_pitch TEXT NOT NULL,
  status TEXT DEFAULT 'pending',  -- 'pending'|'approved'|'rejected'|'conditional'
  condition_text TEXT,
  created_at INTEGER NOT NULL,
  resolved_at INTEGER,
  resolved_by_device_id TEXT
);
```

**开发工时：** 7 天（离线版）

---

#### C07: 生存红利分红协议 (Survival Dividend Protocol)

**功能概述：**
将生存账户节省的金额自动"分红"到双方的灵魂账户，激励省钱行为。

**启用条件：**
- 需要先开启双轨账本 (C03)
- 需要设定月度生存预算
- 家庭模式下自动可用

**核心机制：**

```
月初设定
┌────────────────────────────────────┐
│  生存预算：¥150,000                 │
│  分红比例：丈夫 50% / 妻子 50%       │
└────────────────────────────────────┘
           │
           ▼
日常省钱 ──────────────────────────────
┌────────────────────────────────────┐
│ 📝 超市买菜（半价牛肉）              │
│    原价 ¥1,300 → 实付 ¥800          │
│    节省 ¥500                        │
│                                    │
│    ┌──────────────────────────┐    │
│    │ 🎉 叮！                   │    │
│    │ 为老婆的"美妆基金"        │    │
│    │ 贡献了 ¥250              │    │
│    │ 为自己的"高达基金"        │    │
│    │ 贡献了 ¥250              │    │
│    └──────────────────────────┘    │
└────────────────────────────────────┘
           │
           ▼
月末结算 ──────────────────────────────
┌────────────────────────────────────┐
│  实际支出：¥130,000                 │
│  节省金额：¥20,000                  │
│  ───────────────────────          │
│  分红结果：                         │
│    妻子灵魂账户 +¥10,000            │
│    丈夫灵魂账户 +¥10,000            │
└────────────────────────────────────┘
```

**即时省钱检测算法：**
```dart
class SavingsDetector {
  // 检测是否为折扣购买
  Future<SavingsResult?> detectSavings(Transaction tx) async {
    // 方法1：用户手动标记原价
    if (tx.originalPrice != null && tx.originalPrice > tx.amount) {
      return SavingsResult(
        saved: tx.originalPrice - tx.amount,
        method: 'manual',
      );
    }

    // 方法2：与同品类历史平均价比较
    final avgPrice = await _getAveragePrice(tx.category, tx.note);
    if (avgPrice != null && tx.amount < avgPrice * 0.7) {
      return SavingsResult(
        saved: (avgPrice - tx.amount).round(),
        method: 'historical',
        confidence: 0.7,
      );
    }

    // 方法3：关键词检测（限时特价、半额等）
    if (_hasDiscountKeywords(tx.note)) {
      // 估算节省20%
      final estimated = (tx.amount * 0.25).round();
      return SavingsResult(
        saved: estimated,
        method: 'keyword',
        confidence: 0.5,
      );
    }

    return null;
  }

  bool _hasDiscountKeywords(String? note) {
    if (note == null) return false;
    final keywords = ['半額', '特価', 'セール', '割引', 'SALE', '限定', 'お買い得'];
    return keywords.any((k) => note.contains(k));
  }
}
```

**分红动画效果：**
```dart
class DividendAnimation extends StatefulWidget {
  final int savedAmount;
  final String partnerFundName;
  final String selfFundName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 中央金币爆发
        Center(
          child: Lottie.asset('assets/coin_burst.json'),
        ),
        // 金币分流到左右两边
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: CoinFlowPainter(
                progress: _controller.value,
                leftAmount: savedAmount ~/ 2,
                rightAmount: savedAmount - savedAmount ~/ 2,
              ),
            );
          },
        ),
        // 文字提示
        Positioned(
          bottom: 100,
          child: Column(
            children: [
              Text('🎉 节省了 ¥$savedAmount！'),
              SizedBox(height: 8),
              Row(
                children: [
                  _buildFundChip(partnerFundName, savedAmount ~/ 2),
                  SizedBox(width: 16),
                  _buildFundChip(selfFundName, savedAmount - savedAmount ~/ 2),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
```

**数据模型：**
```sql
CREATE TABLE dividend_config (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  survival_budget INTEGER NOT NULL,
  split_ratio_self REAL DEFAULT 0.5,  -- 0.0-1.0
  effective_month TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, effective_month)
);

CREATE TABLE dividend_log (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  transaction_id TEXT,          -- 关联的交易（如即时检测）
  saved_amount INTEGER NOT NULL,
  detection_method TEXT,        -- 'manual'|'historical'|'keyword'|'monthly'
  self_dividend INTEGER NOT NULL,
  partner_dividend INTEGER NOT NULL,
  logged_at INTEGER NOT NULL
);

CREATE TABLE monthly_dividend_settlement (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  month TEXT NOT NULL,          -- '2026-02'
  budget INTEGER NOT NULL,
  actual_spending INTEGER NOT NULL,
  total_saved INTEGER NOT NULL,
  self_total_dividend INTEGER NOT NULL,
  partner_total_dividend INTEGER NOT NULL,
  settled_at INTEGER NOT NULL,
  UNIQUE(book_id, month)
);
```

**开发工时：** 7 天

---

### 5.2 基础记账功能规格

#### A01: 支出记录

**字段定义：**

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| amount | Integer | ✅ | 金额（日元，最小单位） |
| category_id | String | ✅ | 分类 ID |
| timestamp | Integer | ✅ | 发生时间（Unix timestamp） |
| note | String | ❌ | 备注（加密存储） |
| photo_hash | String | ❌ | 照片哈希（防篡改） |
| ledger_type | Enum | ✅ | 'survival' / 'soul' / 'auto' |
| is_private | Boolean | ❌ | 是否为私有记录 |
| location | String | ❌ | 位置信息（可选） |

**交互流程：**
```
┌─────────────────────────────────────────────────┐
│                  新增支出                        │
├─────────────────────────────────────────────────┤
│  ┌─────────────────────────────────────────┐   │
│  │              ¥ 1,280                    │   │
│  │         [数字键盘输入]                   │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  分类：[🍚 食费 ▼]                              │
│                                                 │
│  账户类型：                                     │
│  ┌──────────┐  ┌──────────┐                   │
│  │ 🏠 生存  │  │ 💖 灵魂  │ (自动判断高亮)     │
│  └──────────┘  └──────────┘                   │
│                                                 │
│  备注：午餐 @ 吉野家                            │
│                                                 │
│  [📷 拍照] [📍 位置] [🔒 私密]                   │
│                                                 │
│  ┌─────────────────────────────────────────┐   │
│  │              保存                        │   │
│  └─────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

---

#### A10: 隐私 OCR 扫描

**技术规格：**

| 平台 | 框架 | 模型 |
|------|------|------|
| iOS | Vision Framework | VNRecognizeTextRequest |
| Android | ML Kit | Text Recognition v2 |

**识别字段：**
- 金额：正则 `¥?\s*\d{1,3}(,\d{3})*\s*円?`
- 日期：正则 `\d{4}[年/]\d{1,2}[月/]\d{1,2}日?`
- 商家：OCR 结果第一行（启发式）
- 合计：关键词匹配 `合計|合计|TOTAL|小計`

**识别流程：**
```dart
Future<ReceiptData> scanReceipt(XFile image) async {
  // 1. 图像预处理
  final processed = await _preprocessImage(image);

  // 2. OCR 识别
  final text = await _runOCR(processed);

  // 3. 结构化提取
  final amount = _extractAmount(text);
  final date = _extractDate(text);
  final merchant = _extractMerchant(text);

  // 4. 自动分类
  final category = await _autoClassify(merchant);

  // 5. 加密存储照片
  final encryptedPhoto = await _encryptAndStore(image);

  return ReceiptData(
    amount: amount,
    date: date,
    merchant: merchant,
    category: category,
    photoHash: encryptedPhoto.hash,
  );
}
```

**准确率目标：**
- 金额识别：> 95%
- 日期识别：> 90%
- 商家识别：> 85%

---

### 5.3 家庭协作功能规格

#### 家庭模式命名

**自定义名称支持：**
- 默认名称为"家庭"（家族）
- 用户可自定义名称（如"田中家"、"我们的小窝"、"Dream Team"等）
- 名称在家庭配对时设定，之后可在设置中修改
- 两位成员都可修改名称，修改后即时同步

#### B01-B02: 家庭配对

**方案一：面对面 QR 码**
```
User A (发起方)                    User B (接受方)
     │                                  │
     ├── 生成 QR 码 ─────────────────────►│
     │   (含公钥 + Relay地址)             │ 扫描
     │                                  │
     │◄─────────────── 握手请求 ─────────┤
     │   (B的公钥)                       │
     │                                  │
     ├── 确认配对 ──────────────────────►│
     │                                  │
     │◄─────────────── 配对成功 ─────────┤
     │                                  │
   [开始同步]                         [开始同步]
```

**方案二：远程短码**
```
User A                    Relay                    User B
   │                         │                         │
   ├── 请求连接码 ──────────►│                         │
   │                         │                         │
   │◄── 6位短码 (TTL=5min) ──┤                         │
   │                         │                         │
   │   [通过Line发送给B]      │                         │
   │                         │                         │
   │                         │◄────── 输入短码 ────────┤
   │                         │                         │
   │◄───────────── 匹配成功，交换公钥 ────────────────┤
   │                         │                         │
   ├── 确认指纹 ─────────────────────────────────────►│
   │   (电话核对后4位)        │                         │
   │                         │                         │
 [配对完成]                                         [配对完成]
```

#### B06b: 心愿单 (Wishlist)

**功能概述：**
个人私有的购物心愿清单，可选择性地向伴侣公开部分心愿，作为礼物提示或共同目标。

**核心特性：**
- 默认私有：心愿单默认仅自己可见
- 选择性公开：每个心愿可单独设置"对伴侣可见"
- 礼物暗示：公开的心愿可作为生日/纪念日礼物提示
- 记账关联：购买心愿单物品后自动归类到灵魂账户

**数据模型：**
```sql
CREATE TABLE wishlist (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  book_id TEXT,                    -- 关联的家庭账本（可选）
  item_name TEXT NOT NULL,
  estimated_price INTEGER,
  category TEXT,
  priority INTEGER DEFAULT 0,      -- 优先级 0-5
  is_public_to_partner INTEGER DEFAULT 0,  -- 是否对伴侣可见
  note TEXT,
  image_url TEXT,
  created_at INTEGER NOT NULL,
  purchased_at INTEGER,            -- 购买时间
  linked_transaction_id TEXT       -- 关联的交易记录
);
```

**可见性规则：**
| 设置 | 自己看到 | 伴侣看到 |
|------|---------|---------|
| 私有 | 完整信息 | 不可见 |
| 公开 | 完整信息 | 物品名称、预估价格、优先级 |

**开发工时：** 4 天

---

#### B05: 家庭内部转账

**两阶段提交流程：**
```protobuf
message TransferSignal {
  string request_id = 1;
  string from_device_id = 2;
  string to_device_id = 3;
  int64 amount = 4;

  enum Action {
    REQUEST = 0;   // 发起
    CONFIRM = 1;   // 确认 (ACK)
    REJECT = 2;    // 拒绝
  }
  Action action = 5;
  int64 timestamp = 6;
  string note = 7;
}
```

**状态机：**
```
         ┌──────────────┐
         │   PENDING    │
         └──────┬───────┘
                │
        ┌───────┼───────┐
        ▼       ▼       ▼
   ┌────────┐ ┌────┐ ┌────────┐
   │CONFIRMED│ │EXPIRED│ │REJECTED│
   └────────┘ └────┘ └────────┘
      (24h超时)
```

---

## 6. UI/UX 风格建议

### 6.1 首页信息融合设计要求

**核心原则：个人与家庭信息的自然融合**

首页需要将个人和家庭信息更好地融合展示，避免突兀的模式切换体验。

**设计要求：**
1. **统一视图**：首页默认展示融合视图，同时显示个人状态和家庭状态
2. **层次分明**：通过视觉层次区分个人数据和家庭共享数据，而非完全分离
3. **无缝切换**：查看详情时自然过渡，不需要明显的"切换模式"操作
4. **信息密度平衡**：关键信息一目了然，详细信息下钻可得

**融合展示方式建议：**
- 顶部区域：家庭整体财务概览（如家庭名称可自定义）
- 中部区域：个人今日/本周消费，标注哪些已同步到家庭账本
- 底部区域：家庭近期动态（伴侣的共享消费，不含对方灵魂消费明细）
- 灵魂账户：以卡片形式嵌入，显示个人预算进度，伴侣只能看到进度条不能看到明细

### 6.2 推荐方案：和风治愈 + 赛博活力双模式

基于目标用户画像和日本市场文化，推荐采用**双模式设计**：

- **生存账户**：和风治愈系（温暖、可信赖）
- **灵魂账户**：赛博可爱风（活力、趣味）

这样可以满足"生存账户严肃理性、灵魂账户活泼有趣"的双轨体验需求。

---

### 6.3 风格 A：和风治愈系 (Warm Japanese Healing)

**适用场景：** 生存账户、家庭模式、设置页面

**设计理念：**
融合日式家计簿的手作感与现代数字体验，强调"家"的温暖和"信任"的可靠。

**色彩系统：**
```
Primary Palette (和风暖色)
┌─────────────────────────────────────────────┐
│  Background    │ #F5F0E6 │ 暖米色          │
│  Surface       │ #FFFDF7 │ 和纸白          │
│  Primary       │ #5D4E37 │ 深棕木色        │
│  Secondary     │ #8B7355 │ 浅棕            │
│  Accent        │ #C17767 │ 朱红（警示）     │
│  Success       │ #6B8E6B │ 抹茶绿          │
└─────────────────────────────────────────────┘

Dark Mode (和风夜色)
┌─────────────────────────────────────────────┐
│  Background    │ #1A1614 │ 墨色            │
│  Surface       │ #2D2622 │ 深棕            │
│  Primary       │ #E8DCC8 │ 月白            │
│  Accent        │ #D4A373 │ 暖金            │
└─────────────────────────────────────────────┘
```

**字体系统：**
```
标题字体：Noto Serif JP (衬线，传统感)
正文字体：Noto Sans JP (无衬线，现代感)
数字字体：DIN Alternate (清晰可读)

字号层级：
- 大标题：24sp / 32sp (Large text mode)
- 小标题：18sp / 24sp
- 正文：  14sp / 18sp
- 辅助：  12sp / 16sp
```

**组件风格：**
```
┌─────────────────────────────────────┐
│  交易卡片 (和风风格)                 │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ ╭─────────────────────────────╮ ││
│  │ │ 🍚                          │ ││
│  │ │ 食费 · 超市                  │ ││
│  │ │                    ¥1,280   │ ││
│  │ │ ─────────────────────────── │ ││
│  │ │ 午餐食材                     │ ││
│  │ │ 2/2 14:30                   │ ││
│  │ ╰─────────────────────────────╯ ││
│  └─────────────────────────────────┘│
│                                     │
│  圆角：16px                         │
│  阴影：柔和漫射 (0 4px 12px rgba)    │
│  边框：无                           │
└─────────────────────────────────────┘
```

**动效特性：**
- 页面切换：淡入淡出 (300ms ease-out)
- 列表滚动：弹性回弹
- 保存成功：和纸展开动画
- 季节元素：樱花飘落 (春) / 红叶 (秋) / 雪花 (冬)

**适用人群：**
- 30-50岁家庭用户
- 喜欢传统 Kakeibo 感觉
- 追求温馨感的夫妻
- 再婚信任重建用户

---

### 6.4 风格 B：赛博可爱风 (Cyber Kawaii)

**适用场景：** 灵魂账户、趣味功能、成就系统

**设计理念：**
融合二次元审美与现代 UI，强调"玩"的乐趣和"收集"的满足感。

**色彩系统：**
```
Primary Palette (赛博活力)
┌─────────────────────────────────────────────┐
│  Background    │ #0D0B14 │ 深空紫          │
│  Surface       │ #1A1625 │ 暗紫            │
│  Primary       │ #FF69B4 │ 霓虹粉          │
│  Secondary     │ #00D4FF │ 电子蓝          │
│  Accent        │ #FFD700 │ 金色            │
│  Success       │ #00FF88 │ 霓虹绿          │
│  Gradient      │ #FF69B4 → #00D4FF │ 渐变  │
└─────────────────────────────────────────────┘

Light Mode (柔和版)
┌─────────────────────────────────────────────┐
│  Background    │ #FFF5F8 │ 浅粉            │
│  Surface       │ #FFFFFF │ 纯白            │
│  Primary       │ #FF4D8D │ 亮粉            │
│  Secondary     │ #00B8D4 │ 青色            │
└─────────────────────────────────────────────┘
```

**字体系统：**
```
标题字体：M PLUS Rounded 1c (圆润可爱)
正文字体：M PLUS 1p (现代清晰)
数字字体：像素风等宽字体 (VT323 或自定义)
特殊场景：手写风字体 (Yomogi)
```

**组件风格：**
```
┌─────────────────────────────────────┐
│  灵魂消费卡片 (赛博风格)             │
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │ ╭─────────────────────────────╮ ││
│  │ │ ✨ 精神资产 +1              │ ││
│  │ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━ │ ││
│  │ │ 🎮 高达模型 RX-78-2         │ ││
│  │ │                    ¥12,800  │ ││
│  │ │ ───────────────────────────││
│  │ │ 💖 快乐值 ████████████ MAX  │ ││
│  │ │ ───────────────────────────││
│  │ │ [发光边框 + 粒子效果]       │ ││
│  │ ╰─────────────────────────────╯ ││
│  └─────────────────────────────────┘│
│                                     │
│  圆角：8px (更锐利)                  │
│  阴影：霓虹发光效果                  │
│  边框：1px 渐变                      │
└─────────────────────────────────────┘
```

**动效特性：**
- 灵魂消费：粒子爆发 + 彩虹光晕
- 成就解锁：像素化展开动画
- 运势抽签：抽卡翻转 + 光芒四射
- 提案通过：撒花 + 金币雨

**适用人群：**
- 20-35岁年轻用户
- 推し活/宅文化爱好者
- 喜欢游戏化体验
- 追求社交分享

---

### 6.5 风格 C：极简信任风 (Minimal Trust) - 备选

**适用场景：** 科技工作者用户、极简偏好用户

**设计理念：**
强调透明与信任，专业但不冷漠，适合注重隐私和效率的用户。

**色彩系统：**
```
Primary Palette (极简)
┌─────────────────────────────────────────────┐
│  Background    │ #FFFFFF │ 纯白            │
│  Surface       │ #F8F9FA │ 浅灰            │
│  Primary       │ #1A1A1A │ 墨黑            │
│  Secondary     │ #6C757D │ 中灰            │
│  Success       │ #34C759 │ 信任绿          │
│  Warning       │ #FF9500 │ 警示橙          │
│  Error         │ #FF3B30 │ 错误红          │
└─────────────────────────────────────────────┘
```

---

### 6.6 双模式切换实现

**技术方案：**
```dart
class ThemeManager {
  // 根据当前账户类型自动切换
  ThemeData getTheme(BuildContext context, LedgerType ledgerType) {
    final brightness = MediaQuery.of(context).platformBrightness;

    switch (ledgerType) {
      case LedgerType.survival:
        return brightness == Brightness.dark
            ? WarmJapaneseTheme.dark
            : WarmJapaneseTheme.light;
      case LedgerType.soul:
        return brightness == Brightness.dark
            ? CyberKawaiiTheme.dark
            : CyberKawaiiTheme.light;
      default:
        return WarmJapaneseTheme.light;
    }
  }
}

// 页面切换时的主题过渡
class LedgerSwitcher extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedTheme(
      data: ThemeManager.getTheme(context, currentLedger),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: child,
    );
  }
}
```

---

### 6.7 关键界面 Wireframe

#### 首页 - 融合视图（家庭模式）

**设计理念：** 个人与家庭信息自然融合，无需切换模式即可获得完整财务视图。

```
┌─────────────────────────────────────────────┐
│ ≡  Home Pocket          🟢 [我们的小窝] 👤  │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │  🏠 家庭总览 · 2月                    │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │   │
│  │  家庭支出        家庭收入            │   │
│  │  ¥234,500       ¥450,000            │   │
│  │  预算池剩余：¥65,500                 │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────┐┌──────────────────┐  │
│  │ 👤 我的本月       ││ 💑 TA的本月      │  │
│  │ 生存 ¥95,000     ││ 生存 ¥85,000    │  │
│  │ ┌──────────────┐ ││ ┌──────────────┐│  │
│  │ │💖灵魂 ¥28,000│ ││ │💖灵魂 ██▓░░░ ││  │
│  │ │████████░░ 70%│ ││ │      65%     ││  │
│  │ └──────────────┘ ││ └──────────────┘│  │
│  └──────────────────┘└──────────────────┘  │
│                                             │
│  🔮 今日运势                    [点击预测]  │
│                                             │
│  今日の記録（融合视图）                      │
│  ┌─────────────────────────────────────┐   │
│  │ 👨 食費     ¥1,280    14:30    🏠   │   │
│  │    午餐 @ 吉野家    [已同步家庭账本]  │   │
│  ├─────────────────────────────────────┤   │
│  │ 👩 日用品   ¥2,100    11:20    🏠   │   │
│  │    ドラッグストア                    │   │
│  ├─────────────────────────────────────┤   │
│  │ 👨 交通費   ¥210      09:15    👤   │   │
│  │    JR通勤          [仅个人]         │   │
│  └─────────────────────────────────────┘   │
│                                             │
├─────────────────────────────────────────────┤
│  🏠      📊      ➕      🛒      ⚙️        │
│  首页    报表    记账    购物    设置       │
└─────────────────────────────────────────────┘
```

**图例说明：**
- 🏠 = 已同步到家庭账本
- 👤 = 仅个人可见
- 💖 = 灵魂账户（伴侣只能看到进度条，不能看到明细）
- ██▓░░░ = 模糊化的进度条（保护隐私）

#### 灵魂账户详情页

```
┌─────────────────────────────────────────────┐
│ ←  我的灵魂账户                        ⚙️   │
├─────────────────────────────────────────────┤
│  ┌─────────────────────────────────────┐   │
│  │  ✨ 高达基金 ✨                      │   │
│  │  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━   │   │
│  │                                      │   │
│  │  本月投入        累計資産            │   │
│  │  ¥25,800        ¥156,200           │   │
│  │                                      │   │
│  │  預算 ¥30,000                       │   │
│  │  ████████████████████░░ 86%         │   │
│  │                                      │   │
│  │  [快乐值满格动画 ✦✦✦✦✦]             │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  最近の精神投資                             │
│  ┌─────────────────────────────────────┐   │
│  │ 🎮 RX-78-2 ガンプラ                  │   │
│  │ ¥12,800          精神資産 +1 💖     │   │
│  │ 2/1                                  │   │
│  ├─────────────────────────────────────┤   │
│  │ 🎮 HG ザク II                        │   │
│  │ ¥2,500           精神資産 +1 💖     │   │
│  │ 1/28                                 │   │
│  └─────────────────────────────────────┘   │
│                                             │
│  ┌─────────────────────────────────────┐   │
│  │      🛒 生成禀议书（大額申請）        │   │
│  └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

#### 运势占卜卡片

```
┌─────────────────────────────────────────────┐
│                                             │
│              ╭───────────────╮              │
│              │               │              │
│              │     大吉      │              │
│              │     ✨🎋✨     │              │
│              │               │              │
│              ╰───────────────╯              │
│                                             │
│   「今日の出費は、未来への投資！」           │
│                                             │
│   ───────────────────────────────          │
│                                             │
│   🍀 幸运物：レシートの端数                  │
│   🎨 幸运色：金色                           │
│   💡 建议：衝動買いも時には正解です          │
│                                             │
│   ───────────────────────────────          │
│                                             │
│   ¥777 での買い物は超ラッキー！              │
│   今日は宝くじを買ってみては？               │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │          收藏到图鉴 ⭐               │   │
│   └─────────────────────────────────────┘   │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │             关闭                     │   │
│   └─────────────────────────────────────┘   │
│                                             │
└─────────────────────────────────────────────┘
```

---

## 7. 技术架构概要

### 7.1 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                        Client Layer                          │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐         │
│  │   Flutter    │  │   Flutter    │  │   Flutter    │         │
│  │   iOS App    │  │  Android App │  │   Web App    │         │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘         │
│         │                │                │                  │
│         └────────────────┼────────────────┘                  │
│                          │                                   │
│  ┌───────────────────────┴───────────────────────┐          │
│  │              Shared Business Logic             │          │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐        │          │
│  │  │Riverpod │ │  Drift   │ │Crypto   │        │          │
│  │  │  State  │ │ SQLite   │ │Ed25519  │        │          │
│  │  └─────────┘ └─────────┘ └─────────┘        │          │
│  └───────────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
                              │
                              │ E2EE Encrypted
                              │
┌─────────────────────────────┴─────────────────────────────┐
│                       Relay Layer                          │
├────────────────────────────────────────────────────────────┤
│  ┌────────────────────────────────────────────────────┐   │
│  │                 Relay Server (Go)                   │   │
│  │  • Dumb Pipe (只转发，不解密)                       │   │
│  │  • WebSocket Signaling                             │   │
│  │  • Short Code Matching                             │   │
│  │  • Blob Caching (Redis, TTL=24h)                   │   │
│  └────────────────────────────────────────────────────┘   │
└────────────────────────────────────────────────────────────┘
                              │
                              │ (V1.0+)
                              │
┌─────────────────────────────┴─────────────────────────────┐
│                     Storage Layer                          │
├────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐    │
│  │     S3       │  │    Redis     │  │   CDN        │    │
│  │ Photo Backup │  │   Caching    │  │ OTA Updates  │    │
│  └──────────────┘  └──────────────┘  └──────────────┘    │
└────────────────────────────────────────────────────────────┘
```

### 7.2 客户端技术栈

| 层级 | 技术选型 | 说明 |
|------|---------|------|
| Framework | Flutter 3.x | 跨平台 UI |
| State | Riverpod 2.x | 响应式状态管理 |
| Database | Drift + SQLCipher | 本地加密存储 |
| Crypto | pointycastle | Ed25519, ChaCha20 |
| Network | dio + web_socket | HTTP/2 + WebSocket |
| ML | ML Kit / Vision | OCR, 分类 |
| LLM | Gemini Nano SDK | 本地推理 (Android) |

### 7.3 数据模型扩展

**新增表（趣味功能）：**

```sql
-- 双轨账本配置
CREATE TABLE soul_account_config (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  oshi_name TEXT,
  icon_emoji TEXT,
  color_hex TEXT,
  monthly_budget INTEGER,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, device_id)
);

-- 互不侵犯条约
CREATE TABLE privacy_pact (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  soul_budget INTEGER NOT NULL,
  visibility_mode TEXT DEFAULT 'pact',
  effective_month TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, device_id, effective_month)
);

-- 灵魂提案
CREATE TABLE soul_pitch (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  item_name TEXT NOT NULL,
  amount INTEGER NOT NULL,
  applicant_device_id TEXT NOT NULL,
  generated_pitch TEXT NOT NULL,
  status TEXT DEFAULT 'pending',
  condition_text TEXT,
  created_at INTEGER NOT NULL,
  resolved_at INTEGER,
  resolved_by_device_id TEXT
);

-- 分红配置
CREATE TABLE dividend_config (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  survival_budget INTEGER NOT NULL,
  split_ratio_self REAL DEFAULT 0.5,
  effective_month TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  UNIQUE(book_id, effective_month)
);

-- 分红日志
CREATE TABLE dividend_log (
  id TEXT PRIMARY KEY,
  book_id TEXT NOT NULL,
  transaction_id TEXT,
  saved_amount INTEGER NOT NULL,
  detection_method TEXT,
  self_dividend INTEGER NOT NULL,
  partner_dividend INTEGER NOT NULL,
  logged_at INTEGER NOT NULL
);

-- 运势图�的
CREATE TABLE omikuji_collection (
  id TEXT PRIMARY KEY,
  level TEXT NOT NULL,
  transaction_id TEXT NOT NULL,
  fortune_text TEXT,
  lucky_item TEXT,
  lucky_color TEXT,
  collected_at INTEGER NOT NULL,
  is_favorite INTEGER DEFAULT 0
);

-- 换算单位偏好
CREATE TABLE converter_preferences (
  id TEXT PRIMARY KEY,
  device_id TEXT NOT NULL,
  preferred_universe TEXT DEFAULT 'random',
  display_frequency TEXT DEFAULT 'always',
  is_enabled INTEGER DEFAULT 1,
  UNIQUE(device_id)
);
```

---

## 8. 开发路线图

### 8.1 总体时间线

```
2026 Q1                    2026 Q2                    2026 Q3
│                          │                          │
├── MVP Phase 1 ──────────►│                          │
│   (8 weeks)              │                          │
│   基础记账 + 趣味核心     │                          │
│                          │                          │
│                          ├── MVP Phase 2 ──────────►│
│                          │   (4 weeks)              │
│                          │   Beta 测试 + 迭代       │
│                          │                          │
│                          │                          ├── V1.0 ──►
│                          │                          │   (10 weeks)
│                          │                          │   家庭高级协作
│                          │                          │
W1──W8                     W9──W12                    W13──W22
```

### 8.2 MVP Phase 1 详细计划 (8 周)

#### Week 1-2: 基础架构 + 视觉系统

| 任务 | 工时 | 负责 | 交付物 |
|------|------|------|--------|
| Flutter 项目初始化 | 1d | Dev | 项目骨架 |
| Drift + SQLCipher 配置 | 2d | Dev | 加密数据库 |
| 深色模式主题 (A12) | 2d | Dev | ThemeData |
| 分类图标系统 (A04) | 3d | Dev + Design | 20个图标 |
| 大字体模式 (E05) | 2d | Dev | 动态缩放 |

**里程碑：** 空壳 App，可切换主题

#### Week 3-4: 趣味交互层

| 任务 | 工时 | 负责 | 交付物 |
|------|------|------|--------|
| 大谷换算器 (C01) | 3d | Dev | Toast + JSON库 |
| 运势占卜-本地版 (C02) | 4d | Dev | 算法 + 文案库 |
| 庆祝动画效果 (C04) | 2d | Dev | Lottie + 粒子 |
| OTA 更新检查 | 1d | Dev | CDN 集成 |

**里程碑：** 趣味功能可用

#### Week 5-6: 双轨账本核心

| 任务 | 工时 | 负责 | 交付物 |
|------|------|------|--------|
| 双轨数据模型 (C03) | 3d | Dev | Schema 扩展 |
| 生存/灵魂 UI 差异化 | 4d | Dev + Design | 双主题切换 |
| LLM 自动分类 | 3d | Dev | Gemini Nano 集成 |

**里程碑：** 双轨账本完整可用

#### Week 7-8: 输入优化 + 信任功能

| 任务 | 工时 | 负责 | 交付物 |
|------|------|------|--------|
| 隐私 OCR (A10) | 5d | Dev | ML Kit 集成 |
| 快捷输入模板 (A08) | 2d | Dev | TF Lite 模型 |
| 审计日志查看器 (D03) | 3d | Dev | 哈希链 UI |

**里程碑：** MVP Feature Complete

### 8.3 MVP Phase 2: Beta 测试 (4 周)

| 周次 | 活动 | 目标 |
|------|------|------|
| W9-10 | TestFlight / Play Console 内测 | 100 用户 |
| W11 | 用户访谈 + Bug 修复 | 收集反馈 |
| W12 | 迭代优化 | NPS > 50 |

### 8.4 V1.0 开发计划 (10 周)

| 周次 | 功能 | 说明 |
|------|------|------|
| W13-14 | 互不侵犯条约 (C05) | 隐私协议层 |
| W15-16 | 实时同步推送 (B07) | WebSocket + FCM |
| W17-18 | 照片云同步 (B09) | S3 集成 |
| W19-20 | 禀议书离线版 (C06) | 模板系统 |
| W21-22 | 生存红利 (C07) + 打磨 | 分红机制 |

---

## 9. 商业模式与定价

### 9.1 Freemium 定价策略

| 功能 | 免费版 | Premium (¥480/月) |
|------|--------|-------------------|
| 基础记账 | ✅ 无限 | ✅ 无限 |
| 家庭配对 | ✅ 2设备 | ✅ 5设备 |
| 自动同步 | ⚠️ 10次/日 | ✅ 无限实时 |
| 双轨账本 | ✅ | ✅ |
| 大谷换算器 | ✅ | ✅ |
| 运势占卜 | ✅ 本地版 | ✅ LLM增强版 |
| 互不侵犯条约 | ✅ | ✅ |
| 禀议书 | ✅ 离线模板 | ✅ LLM生成 |
| 生存红利 | ✅ | ✅ |
| 照片同步 | ❌ | ✅ 无限 |
| 税务导出 | ❌ | ✅ |
| 财务健康评分 | ❌ | ✅ |
| 历史数据 | ⚠️ 12个月 | ✅ 永久 |

### 9.2 收入预测

**基于战略分析文档的中性情景：**

| 时间 | 注册用户 | 付费用户 | 月收入 | 年收入 |
|------|---------|---------|--------|--------|
| Year 1 | 18,000 | 720 | ¥35万 | ¥415万 |
| Year 2 | 60,000 | 2,400 | ¥115万 | ¥1,382万 |
| Year 3 | 150,000 | 6,000 | ¥288万 | ¥3,456万 |

### 9.3 单位经济学

| 指标 | 数值 | 说明 |
|------|------|------|
| LTV | ¥19,008 | 3.3年生命周期 |
| CAC (有机) | ¥1,000 | 内容营销+口碑 |
| CAC (合作伙伴) | ¥1,152 | 咨询师推荐 |
| LTV/CAC | 16-19:1 | 健康 |
| 毛利率 | 57% | 扣除平台抽成后 |

---

## 10. 成功指标

### 10.1 MVP 阶段 KPI

| 指标 | 目标 | 测量方式 |
|------|------|---------|
| Beta 用户数 | 100 | TestFlight/Play Console |
| D7 留存率 | > 40% | 本地统计 |
| 伴侣配对率 | > 60% | 配对完成/注册 |
| NPS | > 50 | 用户调研 |
| 趣味功能使用率 | > 70% | 本地统计 |
| 崩溃率 | < 1% | Crashlytics |

### 10.2 V1.0 阶段 KPI

| 指标 | 目标 | 测量方式 |
|------|------|---------|
| 注册用户 | 10,000 | 本地统计 |
| 付费转化率 | > 4% | 付费/注册 |
| 月活跃用户 (MAU) | 5,000 | 本地统计 |
| D30 留存率 | > 20% | 本地统计 |
| App Store 评分 | > 4.5 | 公开数据 |

### 10.3 趣味功能专项指标

| 功能 | 指标 | 目标 |
|------|------|------|
| 大谷换算器 | 保持开启比例 | > 60% |
| 运势占卜 | 图鉴收集活跃度 | > 30% 用户收集3+种 |
| 双轨账本 | 灵魂消费占比 | 15-30% 为健康区间 |
| 禀议书 | 月均发起数 | > 0.5次/家庭 |
| 生存红利 | 节省金额 | > ¥5,000/月/家庭 |

---

## 11. 风险与缓解

### 11.1 产品风险

| 风险 | 概率 | 影响 | 缓解策略 |
|------|------|------|---------|
| 趣味功能影响专业感 | 30% | 中 | 提供关闭选项 + A/B 测试 |
| 双轨账本过于复杂 | 25% | 中 | 简化引导 + 默认智能分类 |
| LLM 本地推理性能差 | 20% | 低 | 降级到规则引擎 |
| 运势功能被认为幼稚 | 20% | 低 | 提供"成人模式"文案 |

### 11.2 技术风险

| 风险 | 概率 | 影响 | 缓解策略 |
|------|------|------|---------|
| SQLCipher 兼容性问题 | 15% | 高 | 提前测试主流机型 |
| Gemini Nano 设备限制 | 30% | 中 | 提供云端 API 降级 |
| OTA 更新失败 | 10% | 低 | 内置默认版本 |

### 11.3 市场风险

| 风险 | 概率 | 影响 | 缓解策略 |
|------|------|------|---------|
| 竞品复制趣味功能 | 40% | 中 | 快速迭代 + 社区护城河 |
| 目标用户规模不足 | 30% | 高 | 拓展到年轻夫妻市场 |
| 付费转化率低于预期 | 35% | 中 | 调整免费版限制策略 |

---

## 附录

### A. 术语表

| 术语 | 日文 | 说明 |
|------|------|------|
| Kakeibo | 家計簿 | 日本传统记账方法 |
| Omikuji | おみくじ | 日本神社抽签占卜 |
| Oshi-katsu | 推し活 | 追星/爱好消费活动 |
| Ringi | 禀议 | 日本职场审批制度 |
| Gyudon | 牛丼 | 牛肉盖饭 |

### B. 参考文档

1. `MVP产品需求文档.pdf` - 原始 PRD
2. `strategic_analysis_feasibility_marketing.md` - 战略分析
3. `brainstorm_feature_improvements.md` - 功能改进建议

### C. 版本历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|---------|
| 1.0 | 2026-02-01 | - | 初始版本 |
| 2.0 | 2026-02-02 | - | 整合趣味功能，完善 BRD |
| 2.1 | 2026-02-02 | - | 重大更新：用户画像聚焦25-50岁夫妻；移除隐私卫士画像，单人用户改为爱好经营者；项目开源；导入历史数据调整为V1 P2；购物篮拆分为家庭购物篮和私有心愿单；家庭预算池升级为V1 P0；预算目标设定升级为MVP P0并与灵魂消费结合；运势占卜拆分为小票占卜和主动预测（含广告）；双轨账本成为核心功能（单人/家庭模式都自动开启）；家庭名称可自定义；首页UI/UX融合设计要求 |

---

**文档状态：** ✅ BRD 完成
**下一步：** 使用 `/sc:design` 进行技术架构详细设计，或 `/sc:workflow` 生成实施任务分解
