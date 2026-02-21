# BASIC-004: Category 双层分类 PRD

**文档编号:** BASIC-004  
**文档类型:** Product Requirements Document (PRD)  
**文档版本:** 1.3  
**创建日期:** 2026-02-18  
**最后更新:** 2026-02-18  
**状态:** 待评审  
**作者:** Codex (GPT-5)

---

## 1. 背景与目标

现有架构文档中存在“三级分类”历史设计。为满足当前产品目标，Category 统一收敛为**两层结构**，并与双轨账本（成本支出/灵魂支出）和家庭同步能力兼容。

本 PRD 的目标是定义 Category 的业务规则、交互行为、同步策略和验收标准，作为后续模块实现依据。

---

## 2. 设计原则

1. **简单可用:** 分类最多两层，降低选择和维护复杂度。  
2. **记账优先:** 记账流程允许选择任意层级，减少用户操作。  
3. **统计稳定:** 所有分类统计按一级分类聚合，保证报表可比性。  
4. **家庭共享 + 个人偏好分离:** 分类结构可家庭同步，分类类型保持个人设置，不跨成员同步（L1 默认，L2 可覆盖）。  
5. **冲突可控:** 家庭合并时同名自动合并，近似名提示用户确认，避免静默误合并。

---

## 3. 范围

### In Scope

- Category 双层模型（Level 1 / Level 2）
- 记账页分类选择与快速新增
- Setting 页分类管理与类型配置
- 统计聚合口径（按 Level 1）
- 家庭创建后的分类同步与合并规则
- 分类类型个人化配置（L1 默认，L2 可覆盖；不共享）

### Out of Scope

- 三级及以上分类
- 自动语义分类（ML 推荐）细节
- 历史交易自动重算策略的技术实现细节（仅定义业务期望）

---

## 4. 术语定义

- **一级分类 (L1):** 根分类，无 `parentId`。  
- **二级分类 (L2):** 子分类，`parentId` 指向某个 L1。  
- **分类类型 (Category Ledger Type):** 取值为 `cost`（成本支出）或 `soul`（灵魂支出）。L1 必设；L2 可选覆盖。  
- **生效类型 (Effective Ledger Type):** L2 配置了覆盖类型则使用 L2，否则继承父 L1 类型。  
- **统计归属一级分类 (Resolved L1):** 记账选择 L2 时，统计时自动归属其父 L1。  

---

## 5. 功能需求

### FR-001 双层分类结构

1. Category 仅支持两层：L1、L2。  
2. 不允许创建 L3。  
3. L2 必须绑定一个 L1。  

### FR-002 记账时可选任意层

1. 用户在记账时可直接选择 L1 或 L2。  
2. 若选择 L1，交易直接归属该 L1。  
3. 若选择 L2，交易存储所选 L2，同时可解析其父 L1 用于统计与账本类型判断。  
4. 记账页支持“快速新增分类”：  
   - 新增 L1：必须选择类型（`cost`/`soul`）。  
   - 新增 L2：先选一个已有分类作为父级（仅允许选择 L1 作为父级）。

### FR-003 统计口径统一到 L1

1. 所有按 Category 的统计（占比、趋势、排行榜）默认按 L1 统计。  
2. 若交易选中的是 L2，统计金额归并到对应父 L1。  
3. 支持在明细中展示原始 L2，但聚合维度固定为 L1。  

### FR-004 分类类型管理（L1 默认 + L2 覆盖）

1. L1 必须配置“成本支出/灵魂支出”类型。  
2. 用户可在 Setting 修改 L1 类型。  
3. 新增 L1 时必须选择类型，且可后续修改。  
4. L2 默认继承其所属 L1 类型。  
5. L2 可单独设置覆盖类型；设置后以 L2 类型为准。  
6. 用户可在 Setting 清除 L2 覆盖，恢复继承 L1。  

### FR-005 Setting 与记账页均可新增分类

1. Setting 页支持：新增 L1、新增 L2、编辑名称、排序、归档。  
2. 记账页支持：  
   - 新增 L1（需选择类型）  
   - 在已选分类下新增 L2（父级必须是 L1）  
3. 新增后应立即可选，无需重启页面。  

### FR-006 家庭同步与分类合并

家庭创建后，Category 与账户一起参与同步，遵循以下规则：

1. **同名分类自动合并**  
   - 基于规范化名称（大小写、全角半角、首尾空白、常见标点差异归一）进行同名判定。  
   - 同名且层级一致时自动合并为同一分类节点。  

2. **近似名分类提示确认**  
   - 名称相似度达到阈值（产品默认 0.82，可配置）时，弹出“是否合并/是否同步”提示。  
   - 用户可选“合并”“保留分开”“稍后处理”。  

3. **层级约束**  
   - L2 合并必须在同一父 L1 语义下进行，避免跨父级误合并。  

### FR-007 分类类型为个人配置，不参与同步

1. L1 类型与 L2 覆盖类型均为**成员个人设置**。  
2. 家庭同步只同步分类结构信息（名称、层级、父子关系、排序等），不覆盖成员本地类型配置。  
3. 同一 L1 或 L2 在不同家庭成员之间可有不同类型结果。  

---

## 6. 数据与所有权模型（业务层）

为支持“结构共享、类型个人化”，业务上拆分两类数据：

### 6.1 共享分类结构（可同步）

- `CategoryNode`
  - `id`
  - `familyId`（个人账本可为空）
  - `name`
  - `level`（1/2）
  - `parentId`（L1 为空，L2 指向 L1）
  - `sortOrder`
  - `isSystem`
  - `isArchived`
  - `createdBy`
  - `createdAt` / `updatedAt`

### 6.2 个人分类类型映射（不同步）

- `CategoryLedgerPreference`（L1 必填）
  - `userId`
  - `categoryId`（仅 L1）
  - `ledgerType`（`cost`/`soul`）
  - `updatedAt`

- `CategoryLedgerOverride`（L2 可选）
  - `userId`
  - `categoryId`（仅 L2）
  - `ledgerType`（`cost`/`soul`）
  - `updatedAt`

---

## 7. 关键业务流程

### 7.1 记账选择流程

1. 打开分类选择器，展示 L1 和其 L2。  
2. 用户可点击 L1 直接完成选择，或进入 L2 选择。  
3. 保存交易时记录用户实际选择的分类；统计时解析 `Resolved L1`。  
4. 账本类型判断使用 `Effective Ledger Type`（L2 覆盖优先，否则继承 L1）。  

### 7.2 快速新增流程（记账页）

1. 用户在选择器点击“新增分类”。  
2. 选择“新增一级”或“新增二级”：  
   - 新增一级：输入名称，必须选择 `cost/soul`。  
   - 新增二级：选择父 L1，输入名称。  
3. 创建成功后自动回填本次记账分类。  

### 7.3 家庭同步冲突流程

1. 拉取对端分类结构。  
2. 执行同名自动合并。  
3. 对近似名生成待确认列表并提示用户。  
4. 用户决策后写入合并映射并继续同步。  
5. 个人 `ledgerType` 与 L2 覆盖映射保持本地，不做上行或下行覆盖。  

---

## 8. 验收标准（Acceptance Criteria）

1. Category 最大深度为 2，无法创建第 3 层。  
2. 记账时能选择 L1 或 L2，且都能成功保存交易。  
3. 分类统计结果全部按 L1 聚合；选择 L2 的交易正确归并到父 L1。  
4. 新增 L1 时必须选择 `cost/soul`，未选择不可提交。  
5. L2 默认继承父 L1 类型；未设置覆盖时生效类型与 L1 一致。  
6. Setting 可修改任意 L1 的 `cost/soul` 类型，并可为 L2 设置/清除覆盖类型。  
7. Setting 与记账页都可新增 L1 和 L2。  
8. 家庭同步时同名分类自动合并。  
9. 家庭同步时近似名分类会提示用户确认，不可静默处理。  
10. 两个家庭成员对同一 L1 或 L2 设置不同类型后，同步完成仍保持各自设置不变。  

---

## 9. 与现有文档关系

1. 本 PRD 在 Category 层级上覆盖历史“三级分类”叙述。  
2. 后续需同步更新以下文档以保持一致：  
   - `docs/arch/02-module-specs/MOD-001_BasicAccounting.md`  
   - `docs/arch/02-module-specs/MOD-002_DualLedger.md`  
   - `docs/arch/01-core-architecture/ARCH-002_Data_Architecture.md`（如涉及数据模型字段变更）  

---

## 10. 默认分类清单（来自参考图片，L2 三语）

说明：
- 以下清单按你提供的图片解析。
- 每张图片对应一个 L1，图片内条目均作为该 L1 的默认 L2。
- 名称提供 `ja`（原文）/`zh`（中文）/`en`（英文）三个版本。

### 10.0 一级分类默认排序（家庭画面）

按“カテゴリーの編集（家族画面）”截图从上到下的默认顺序：

| sortOrder | ja | zh | en |
|---|---|---|---|
| 1 | 食費 | 食费 | Food |
| 2 | 日用品 | 日用品 | Daily Necessities |
| 3 | 交通費 | 交通费 | Transport |
| 4 | 趣味・娯楽 | 兴趣娱乐 | Hobbies & Entertainment |
| 5 | 衣服・美容 | 衣服美容 | Clothing & Beauty |
| 6 | 交際費 | 交际费 | Socializing |
| 7 | 健康・医療 | 健康医疗 | Health & Medical |
| 8 | 教育・教養 | 教育进修 | Education & Self-Improvement |
| 9 | 水道・光熱費 | 水电燃气 | Utilities |
| 10 | 通信費 | 通讯费 | Communication |
| 11 | 住宅 | 住宅 | Housing |
| 12 | 車・バイク | 车与摩托 | Car & Motorcycle |
| 13 | 税・社会保障 | 税费与社会保障 | Taxes & Social Security |
| 14 | 保険 | 保险 | Insurance |
| 15 | 特別な支出 | 特别支出 | Special Expenses |
| 16 | その他 | 其他 | Other |

### 10.1 交通费 / 交通费 / Transport

| ja | zh | en |
|---|---|---|
| 交通費 | 交通费 | Transport |
| 電車 | 电车 | Train |
| バス | 公交 | Bus |
| タクシー | 出租车 | Taxi |
| 飛行機 | 飞机 | Flights |
| その他交通 | 其他交通 | Other Transport |

### 10.2 保険 / 保险 / Insurance

| ja | zh | en |
|---|---|---|
| 保険 | 保险 | Insurance |
| 生命保険 | 人寿保险 | Life Insurance |
| 医療保険 | 医疗保险 | Medical Insurance |
| その他保険 | 其他保险 | Other Insurance |

### 10.3 税・社会保障 / 税费与社会保障 / Taxes & Social Security

| ja | zh | en |
|---|---|---|
| 所得税・住民税 | 所得税与居民税 | Income Tax & Resident Tax |
| 年金 | 年金 | Pension |
| 健康保険 | 健康保险 | Health Insurance |
| その他税・社会保障 | 其他税费与社会保障 | Other Taxes & Social Security |

### 10.4 水道・光熱費 / 水电燃气 / Utilities

| ja | zh | en |
|---|---|---|
| 光熱費 | 水电燃气费 | Utilities |
| 電気代 | 电费 | Electricity |
| 水道代 | 水费 | Water |
| ガス・灯油代 | 燃气/煤油费 | Gas & Kerosene |
| その他水道・光熱費 | 其他水电燃气 | Other Utilities |

### 10.5 健康・医療 / 健康医疗 / Health & Medical

| ja | zh | en |
|---|---|---|
| フィットネス | 健身 | Fitness |
| マッサージ・整体 | 按摩/整骨 | Massage & Chiropractic |
| 病院 | 医院 | Hospital |
| 薬代 | 药费 | Medicine |
| その他健康・医療 | 其他健康医疗 | Other Health & Medical |

### 10.6 教育・教養 / 教育进修 / Education & Self-Improvement

| ja | zh | en |
|---|---|---|
| 書籍 | 书籍 | Books |
| 新聞・雑誌 | 报刊杂志 | Newspapers & Magazines |
| 習いごと | 兴趣课程 | Classes |
| 教科書・参考書 | 教材/参考书 | Textbooks & Reference Books |
| 学費 | 学费 | Tuition |
| 塾 | 补习班 | Cram School |
| その他教育・教養 | 其他教育进修 | Other Education & Self-Improvement |

### 10.7 交際費 / 交际费 / Socializing

| ja | zh | en |
|---|---|---|
| 交際費 | 交际费 | Socializing |
| 飲み会 | 聚会饮酒 | Drinks & Gatherings |
| プレゼント | 礼物 | Gifts |
| 冠婚葬祭 | 红白喜丧 | Ceremonial Occasions |
| その他交際費 | 其他交际费 | Other Socializing |

### 10.8 特別な支出 / 特别支出 / Special Expenses

| ja | zh | en |
|---|---|---|
| 特別な支出 | 特别支出 | Special Expenses |
| 家具・家電 | 家具家电 | Furniture & Appliances |
| 住宅・リフォーム | 住宅/装修 | Housing & Renovation |
| 結婚 | 结婚 | Wedding |
| 妊活・出産 | 备孕与生产 | Fertility & Childbirth |
| 介護 | 护理 | Nursing Care |
| その他特別な出費 | 其他特别支出 | Other Special Expenses |

### 10.9 車・バイク / 车与摩托 / Car & Motorcycle

| ja | zh | en |
|---|---|---|
| ガソリン | 油费 | Fuel |
| 駐車場 | 停车费 | Parking |
| 道路料金 | 过路费 | Toll Fees |
| 自動車ローン | 车贷 | Auto Loan |
| 自動車保険 | 车险 | Auto Insurance |
| 自動車税 | 车船税 | Vehicle Tax |
| 車検・整備 | 年检/保养 | Inspection & Maintenance |
| その他車・バイク | 其他车与摩托 | Other Car & Motorcycle |

### 10.10 衣服・美容 / 衣服美容 / Clothing & Beauty

| ja | zh | en |
|---|---|---|
| 衣服 | 衣服 | Clothing |
| アクセサリー・小物 | 饰品/小物 | Accessories & Small Items |
| 下着 | 内衣 | Underwear |
| 美容院、理髪 | 美发/理发 | Hair Salon & Barber |
| 化粧品 | 化妆品 | Cosmetics |
| エステ・ネイル | 美容护理/美甲 | Esthetic & Nails |
| クリーニング | 清洗护理 | Dry Cleaning |
| その他衣服・美容 | 其他衣服美容 | Other Clothing & Beauty |

### 10.11 その他 / 其他 / Other

| ja | zh | en |
|---|---|---|
| 立替金 | 垫付款 | Advances |
| 仕送り | 汇款/赡养 | Remittance |
| おこづかい | 零花钱 | Allowance |
| 事業費 | 经营费用 | Business Expenses |
| 返済 | 还款 | Debt Repayment |
| 雑費 | 杂费 | Miscellaneous |
| 使途不明金 | 去向不明款 | Unclassified Spending |
| その他 | 其他 | Other |

### 10.12 趣味・娯楽 / 兴趣娱乐 / Hobbies & Entertainment

| ja | zh | en |
|---|---|---|
| レジャー・スポーツ | 休闲运动 | Leisure & Sports |
| イベント | 活动 | Events |
| 映画・動画 | 电影/视频 | Movies & Videos |
| 音楽・ゲーム・漫画 | 音乐/游戏/漫画 | Music, Games & Manga |
| 本 | 图书 | Books |
| 旅行 | 旅行 | Travel |
| その他趣味・娯楽 | 其他兴趣娱乐 | Other Hobbies & Entertainment |

### 10.13 通信費 / 通讯费 / Communication

| ja | zh | en |
|---|---|---|
| 携帯電話 | 手机通信 | Mobile Phone |
| 固定電話 | 固话 | Landline |
| インターネット | 网络 | Internet |
| 放送視聴料 | 视听费 | Broadcasting Subscription |
| 情報サービス | 信息服务 | Information Services |
| 宅配便・運送 | 快递/运输 | Delivery & Shipping |
| その他通信費 | 其他通讯费 | Other Communication |

### 10.14 住宅 / 住宅 / Housing

| ja | zh | en |
|---|---|---|
| 家賃 | 房租 | Rent |
| 住宅ローン | 房贷 | Mortgage |
| 管理費・積立金 | 物业/公积管理费 | Management Fees & Reserve Fund |
| 家具 | 家具 | Furniture |
| 家電 | 家电 | Home Appliances |
| リフォーム | 装修 | Renovation |
| 地震・火災保険 | 地震/火灾保险 | Earthquake & Fire Insurance |
| その他住宅 | 其他住宅 | Other Housing |

### 10.15 日用品 / 日用品 / Daily Necessities

| ja | zh | en |
|---|---|---|
| 日用品 | 日用品 | Daily Necessities |
| 生活雑貨 | 生活杂货 | Household Goods |
| 子ども関連 | 儿童相关 | Child-related |
| ペット関連 | 宠物相关 | Pet-related |
| タバコ | 烟草 | Tobacco |
| その他日用品 | 其他日用品 | Other Daily Necessities |

### 10.16 食費 / 食费 / Food

| ja | zh | en |
|---|---|---|
| 食費 | 食费 | Food |
| 食料品 | 食材杂货 | Groceries |
| 外食 | 外出就餐 | Dining Out |
| 朝ご飯 | 早餐 | Breakfast |
| 昼ご飯 | 午餐 | Lunch |
| 夜ご飯 | 晚餐 | Dinner |
| カフェ | 咖啡馆 | Cafe |
| その他食費 | 其他食费 | Other Food |
