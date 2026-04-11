# 日本消費カテゴリ 提案書

**文档编号**: DEV-CATEGORIES-JP-001
**版本**: 1.0 (草案)
**创建日期**: 2026-04-10
**状态**: 研究报告 / 未落地
**关联文档**:
- `docs/dev/categories.md` (现状基线)
- `docs/design/research_japanese_kakeibo_apps_analytics_history.md` (UX 研究)
- `lib/shared/constants/default_categories.dart` (seed 数据)
- `lib/data/tables/category_ledger_configs_table.dart` (双账本映射)

---

## 0. TL;DR

**核心结论**: 现有 19 × 103 类目体系在日本语境下 **起点很稳**——本质上是 Money Forward ME 16 大項目的超集——但有三类结构性问题需要修正，并缺少若干日本家庭高频科目。

**五条关键发现**:

1. **现有 `cat_*` L1 中 16 个与 Money Forward ME 16 大項目一一对应**（连顺序都高度近似）。日文名与主流 app 完全一致，并非需要"日本化"的翻译问题，而是结构精修问题。
2. **三个结构性怪味**:
   - `cat_cash_card` (現金・カード) 是 MF ME 对缺乏「口座間振替」原语的 workaround，在拥有 Account/Book 模型的 Home Pocket 中是反模式
   - `cat_asset` (資産形成) 作为支出类目在主流日本 app 里不存在，是 Home Pocket 灵魂账本的独有设计——需要明确声明为 intentional，不要误以为可以对标
   - `cat_special` (特別な支出) 的 L2 与 住宅/車/趣味 有设计性重复（这是日本家計簿传统，但必须给用户清晰指引）
3. **L2 层的 `*_general` 占位符（8 处）是反模式**: Zaim/MF ME 都不用，应删除
4. **缺失的日本高频 L2**: `ふるさと納税`、`学資保険`、`受験料`、`火災・地震保険`、`NHK受信料`、`NISA・iDeCo`、`人間ドック`、`免許教習`——每一个都在 Zaim / MF ME 清单里出现
5. **收入侧 4 个类目太简陋**: 缺 `副業`、`年金`、`児童手当`、`還付金`、`祝い金・お年玉`——日本家庭的真实收入结构至少 7–9 类

**推荐改动规模**:

| 层级 | Add | Rename | Merge | Remove | Keep |
|------|-----|--------|-------|--------|------|
| 支出 L1 | 1 | 0 | 1 | 1 | 17 |
| 支出 L2 | ~15 | ~5 | ~3 | ~12 (主要是 `*_general`) | ~80 |
| 收入 L1 | 5 | 0 | 0 | 0 | 4 |

净结果: 支出 L1 从 19 → 18，支出 L2 从 103 → ~103（数量相当但组合变化），收入 L1 从 4 → 9。

**不推荐改动**:
- 不引入新的 L3 层级（Drift schema 限制 `level ∈ {1,2}`，且 2 级已够用）
- 不替换现有 ARB key 的驼峰命名约定
- 不改动图标/配色主框架（仅对新增类目赋值）

**强烈推荐**引入一个**正交维度** — 把日本家計簿伝統的「固定費 / 変動費 / 特別費」三分法作为 Transaction 的 tag（而非 Category 层级），这是现有体系完全缺失的维度。详见 §8。

---

## 1. 研究背景与方法

### 1.1 为什么要做

Home Pocket 的首发市场定位是日本家庭（「まもる家計簿」，产品名自身即日文）。但当前的 `docs/dev/categories.md` 基线（19 L1 支出 + 103 L2 + 4 L1 收入）虽然 L1 的日文名贴近主流，却存在以下未经对照验证的问题:

- 结构是否真的对齐日本主流 app？还是只是"翻译对齐"而结构还是英美式？
- L2 数量 103 偏多，冗余与缺失分布如何？
- 双账本映射（survival/soul）是否有日本文化依据，还是主观直觉？
- 日本家庭独有科目（ふるさと納税、冠婚葬祭、学資保険…）覆盖如何？

### 1.2 与已有文档的关系

`docs/design/research_japanese_kakeibo_apps_analytics_history.md` 已覆盖 6 款日本主流 app 的分析/历史页 **UX** 设计，但明确未展开**类目分类学**——只提到 Money Forward ME 用 大分類/中分類、Zaim 用 大分類，没有列出实际类目清单。本文档补齐这一空白，并基于公开权威资料给出推荐。

### 1.3 研究方法

- **主要数据来源**: WebSearch + WebFetch 采集公开的 app 官方手册、助けセンター、用户博客
- **权威基线**: 総務省統計局「家計調査」収支項目分類（日本政府唯一的权威家計 taxonomy）
- **覆盖范围**: Zaim, Money Forward ME, Moneytree, おカネレコ (4 款主流 app) + 家計調査 + 日本家計簿文化通用 convention（固定費/変動費/特別費 三分法）
- **对照对象**: 现有 `docs/dev/categories.md` 的 19 × 103 结构

### 1.4 术语约定

本文档中:

- **L1** = 大分類 / 大項目 / 親カテゴリ（parent）
- **L2** = 中分類 / 中項目 / 子カテゴリ（child）
- **日文名** = 指向日本用户显示的字面名称
- **Code** = Home Pocket 内部 ID (`cat_food` 等)
- **生存 / 灵魂** = Home Pocket 双账本术语 (`LedgerType.survival` / `LedgerType.soul`)

---

## 2. 主流日本记账 App 类目体系

### 2.1 Zaim（15 大分類，二级结构）

**来源**: Zaim 官方手册 + 用户博客实测。Zaim 15 个支出大分類是 free tier 默认设置，每个大分類下有 4–9 个中分類。

| # | 大分類 | 中分類 |
|---|--------|--------|
| 1 | **食費** | 食料品、カフェ、朝ごはん、昼ごはん、晩ごはん、その他 |
| 2 | **日用雑貨** | 消耗品、子ども関連、ペット関連、タバコ、その他 |
| 3 | **交通** | 電車、タクシー、バス、飛行機、その他 |
| 4 | **交際費** | 飲み会、プレゼント、ご祝儀・香典、その他 |
| 5 | **エンタメ** | レジャー、イベント、映画・動画、音楽、漫画、書籍、ゲーム、その他 |
| 6 | **教育・教養** | 習い事、新聞、参考書、受験料、学費、**学資保険**、塾、その他 |
| 7 | **水道・光熱** | 水道料金、電気料金、ガス料金、その他 |
| 8 | **美容・衣服** | 洋服、アクセサリー・小物、下着、**ジム・健康**、美容院、コスメ、エステ・ネイル、クリーニング、その他 |
| 9 | **住まい** | 家賃、住宅ローン返済、家具、家電、リフォーム、住宅保険、その他 |
| 10 | **医療・保険** | 病院代、薬代、生命保険、医療保険、その他 |
| 11 | **通信** | 携帯電話料金、固定電話料金、インターネット関連費、放送サービス料金、宅配便、切手・はがき、その他 |
| 12 | **大型支出** | 旅行、住宅、自動車、バイク、結婚、出産、介護、家具、家電、その他 |
| 13 | **クルマ** | ガソリン、駐車場、自動車保険、自動車税、自動車ローン、**免許教習**、高速料金、その他 |
| 14 | **税金** | 年金、所得税、消費税、住民税、**個人事業税**、その他 |
| 15 | **その他** | 仕送り、お小遣い、使途不明金、立替金、未分類、**現金の引出**、**カードの引落**、**電子マネーにチャージ**、その他 |

**独特设计**:

- **`大型支出` 与 `住まい`、`クルマ`、`エンタメ` 有重复 L2**（家具/家電/住宅/自動車/旅行），这是 intentional：低频高额支出单独归档，但日常同名小额支出归到原类
- **`医療・保険` 合并**：Zaim 把生命保険/医療保険放在医療下，与 MF ME（保険独立 L1）形成对比
- **`その他` 里混入转账类**：`現金の引出`、`カードの引落`、`電子マネーにチャージ` 本质是 口座間の移動 而非消费，Zaim 用"伪消费类目"承载
- **`学資保険` 放在 `教育・教養` 下**（而非 `保険` 下），是日本特色归属
- **Zaim Premium** 允许用户自由编辑/添加/删除大分類与中分類，free tier 只能用默认

### 2.2 Money Forward ME（16 大項目 + ~93 中項目）

**来源**: MF ME 官方 サポートサイト + libecity + money-leaf。MF ME 是日本用户量最大的记账 app（15M+ 用户），大項目固定不可编辑（仅可追加中項目），中項目用户可添加最多 100 个。

**16 大項目（支出）完整列表**:

| # | 大項目 | 中項目示例（部分） |
|---|--------|------------------|
| 1 | **食費** | 食料品、カフェ、朝食、昼食、夕食、外食、その他 |
| 2 | **日用品** | 消耗品、子育て用品、ドラッグストア、ペット用品、タバコ |
| 3 | **趣味・娯楽** | アウトドア、スポーツ、映画・音楽・ゲーム、本、旅行、レジャー |
| 4 | **交際費** | 飲み会、プレゼント、**冠婚葬祭**、会費、その他 |
| 5 | **交通費** | 電車、バス、タクシー、新幹線、航空券 |
| 6 | **衣服・美容** | 衣服、アクセサリー、下着、美容院、化粧品、エステ |
| 7 | **健康・医療** | 病院、薬、フィットネス、サプリメント |
| 8 | **教養・教育** | 書籍、新聞、受講料、学費、塾、セミナー |
| 9 | **水道・光熱費** | 電気代、ガス代、水道代、灯油 |
| 10 | **通信費** | 携帯電話、固定電話、インターネット、放送受信料、郵便 |
| 11 | **住宅** | 家賃、住宅ローン、管理費、修繕費、家具、家電 |
| 12 | **自動車** | ガソリン、駐車場、高速料金、車検、自動車税、自動車保険 |
| 13 | **保険** | 生命保険、医療保険、火災保険、地震保険 |
| 14 | **税・社会保障** | 所得税、住民税、年金、健康保険、介護保険 |
| 15 | **現金・カード** | 引き出し、カード払い、電子マネー（"振替"用途的专用类目） |
| 16 | **特別な支出** | 大型家具、大型家電、リフォーム、冠婚葬祭（年度）、旅行 |

**收入 大項目**（2 个）: `給与`, `その他収入`（MF ME 收入侧非常简化）

**独特设计**:

- **`現金・カード` 是 MF ME 特色**: 它存在的唯一理由是捕获"现金 ATM 提取"和"不明カード支払"——因为 MF ME 早期不支持账户间转账原语，用这个伪类目顶替。现代账户模型（Home Pocket 已有）不需要此 workaround。
- **`冠婚葬祭` 放在 `交際費` 下**（L2 而非 L1），这是 MF ME 的决定
- **`特別な支出` 承载"年度性大型支出"**: L2 与 `住宅`、`自動車` 有设计性重复
- **大項目不可编辑**: 用户只能在 中項目 层添加自定义（最多 100 个）
- **93 个默认中項目**（2025 年数据），远超 Zaim 的默认 ~65

### 2.3 Moneytree（20+ 父类，AI 自动分类）

**来源**: Moneytree 官方 + takobutsu blog 的 2020 年实测。Moneytree 是资产管理定位（一生通帳），AI 自动分类为主。

**特点**:

- **20+ 个固定父类**（数量比 Zaim/MF ME 多），但用户**完全不能编辑/删除父类**（比 MF ME 还严格）
- 用户只能在父类下添加子类
- 采用 AI 自动仕訳（自动分类）技术，以减少手动输入
- 类目划分被用户博客批评为 **"有って当然のカテゴリが無い"**（该有的类目没有），缺乏灵活性
- 父类示例（已确认）: `給与`、`収入`、`交際費`、`税金`、`その他の口座`
- **三大顶层类**: Income（收入）/ Expense（支出）/ Other（转账、还款、投资）

**对 Home Pocket 的参考价值**:
- **反面教材**: 不要把父类锁死。Home Pocket 已允许用户自定义类目（`isSystem=false`），优于 Moneytree
- **正面借鉴**: 把"转账、还款、投资"明确归入 **Other** 顶层类而非硬塞进 Expense，这是 Home Pocket 应该学的架构

### 2.4 おカネレコ（15 flat，无 L2）

**来源**: okane-reco 官方 + takobutsu blog。おカネレコ 是轻量级代表（"2秒家計簿"），用户量 500 万+。

**特点**:

- **扁平结构**: 默认 15 个类目，**无子类/层级**——"おカネレコにはサブカテゴリはありません"
- 自由版限制: 最多 18 个类目
- 付费版限制: 最多 90 个类目
- 允许用户任意重命名已有类目
- 特有类目示例: `ママ費`（妈妈专属费用）、`ペット`、`ライブ`、`スマホゲーム` ——面向年轻用户的自定义文化
- 收入侧初始设定不支持（仅可在设置中开启）

**对 Home Pocket 的参考价值**:
- **反面教材**: 扁平结构不适合家庭预算（无法分组统计）
- **正面启示**: 日本部分用户偏好**极简**而非 MF ME/Zaim 的复杂层级——Home Pocket 应在首次引导中提供"最小化模式"选项

### 2.5 総務省「家計調査」10 大費目（日本政府权威基准）

**来源**: 統計局ホームページ/家計調査 収支項目分類及びその内容例示（平成27年1月改定）。这是日本政府唯一的**权威家計支出分类 taxonomy**，用于国家经济统计与生活保护基準の参考。

**10 大費目 完整清单（附子项）**:

| # | 大費目 | 主要費目 |
|---|--------|---------|
| 1 | **食料** | 穀類、魚介類、肉類、乳卵類、野菜・海藻、果物、油脂・調味料、菓子類、調理食品、飲料、酒類、外食、賄い費 |
| 2 | **住居** | 家賃地代、設備修繕・維持 |
| 3 | **光熱・水道** | 電気代、ガス代、他の光熱、上下水道料 |
| 4 | **家具・家事用品** | 家庭用耐久財、室内装備・装飾品、寝具類、家事雑貨、家事用消耗品、家事サービス |
| 5 | **被服及び履物** | 和服、洋服、シャツ・セーター類、下着類、生地・糸類、他の被服、履物類、被服関連サービス |
| 6 | **保健医療** | 医薬品、健康保持用摂取品、保健医療用品・器具、保健医療サービス |
| 7 | **交通・通信** | 交通、自動車等関係費、通信 |
| 8 | **教育** | 授業料等、教科書・学習参考教材、補習教育 |
| 9 | **教養娯楽** | 教養娯楽用耐久財、教養娯楽用品、書籍・他の印刷物、教養娯楽サービス |
| 10 | **その他の消費支出** | 諸雑費、**こづかい**（使途不明）、**交際費**、**仕送り金** |

**关键观察**:

- **交通・通信** 是合并大費目（Zaim/MF ME/Home Pocket 都拆成两个）
- **家具・家事用品** 在消费 app 中通常归入 `日用品` 或 `住宅`，家計調査 独立成 L1
- **被服及び履物** 独立（Zaim/MF ME 合并成 衣服・美容）
- **交際費** 和 **こづかい** 都归入"その他の消費支出"下——这意味着政府统计视角下它们都是非主流
- **税金・社会保险料・貯蓄・投資** 都**不是**消費支出，而是"非消費支出"。Home Pocket 的 `cat_asset` (資産形成) 与这个定义严格冲突——是 intentional divergence

### 2.6 日本家計簿伝統: 固定費 / 変動費 / 特別費 三分法

**来源**: 常陽銀行、エネチェンジ、Looop电力、第一生命等 FP 专栏文章的共识总结。这是日本家計簿 YouTubers 和 FP 圏最通用的记账入门 framework。

**三分法核心**:

| 类型 | 定义 | 典型项 |
|------|------|--------|
| **固定費** | 毎月金额几乎固定的基础支出 | 家賃、住宅ローン、保険料、通信費、サブスク、習い事月謝、**お小遣い** |
| **変動費** | 毎月金额变动的日常支出 | 食費、日用品、交際費、被服、娯楽 |
| **特別費** | 毎月不发生、年度或突发的支出 | **ふるさと納税**、**冠婚葬祭**、旅行、家電買い替え、年払保険料、**初詣・お年玉** |

**关键观察**:

- **お小遣い（个人零花钱）是固定費** —— 日本家計簿文化把给自己/配偶/孩子的每月 spending 视为"固定"预算条目。现有 Home Pocket 把 `cat_other_allowance` 放 L2，降格了
- **ふるさと納税是特別費的标志性项** —— 日本家庭每年 10-12 月集中发生，金额大，**必须在类目里显式存在**（现有 Home Pocket 完全没有）
- **冠婚葬祭** —— 频率低、金额大，日本家計簿伝統归"特別費"。MF ME 把它放 `交際費` L2 是信息损失
- 三分法是**正交于 L1 类目**的维度：同一个 L1（例如 `住宅`）内，家賃 是固定費、リフォーム 是特別費
- 推荐做法: **作为 Transaction 的 tag** 或 **Budget 维度**，而不是 Category 的层级

---

## 3. 横向对比矩阵

### 3.1 L1 语义层面对比

行 = 语义类目，列 = 各 app 的对应 L1。✓ = 存在，✗ = 无，→ = 作为 L2 存在。

| 语义 | 家計調査 | Zaim | MF ME | Moneytree | おカネレコ | **Home Pocket** | 备注 |
|------|---------|------|-------|-----------|------------|----------------|------|
| 食品 | 食料 | 食費 | 食費 | 食費* | 食費* | **食費 ✓** | 5/5 全球共识 |
| 日用品 | → (家具家事) | 日用雑貨 | 日用品 | 日用品* | 日用品* | **日用品 ✓** | app 共识，家計調査散入家具 |
| 交通 | → (交通通信) | 交通 | 交通費 | 交通費* | 交通* | **交通費 ✓** | app 都拆，家計調査合并 |
| 娱乐 | 教養娯楽 | エンタメ | 趣味・娯楽 | 娯楽* | 娯楽* | **趣味・娯楽 ✓** | 共识 |
| 衣/美 | 被服及び履物 | 美容・衣服 | 衣服・美容 | 衣服* | 衣服* | **衣服・美容 ✓** | 顺序不同但语义一致 |
| 交際 | → (その他) | 交際費 | 交際費 | 交際費 | 交際費* | **交際費 ✓** | 家計調査归其他 |
| 医療 | 保健医療 | 医療・保険 | 健康・医療 | 医療* | 医療* | **健康・医療 ✓** | Zaim 把保险并入 |
| 教育 | 教育 | 教育・教養 | 教養・教育 | 教育* | 教育* | **教育・教養 ✓** | 5/5 共识 |
| 水电燃气 | 光熱・水道 | 水道・光熱 | 水道・光熱費 | 光熱費* | 光熱* | **水道・光熱費 ✓** | 共识 |
| 通信 | → (交通通信) | 通信 | 通信費 | 通信費* | 通信* | **通信費 ✓** | 共识 |
| 住宅 | 住居 | 住まい | 住宅 | 住宅* | 住居* | **住宅 ✓** | 共识 |
| 车 | → (交通通信>自動車等) | クルマ | 自動車 | 車* | 車* | **車・バイク ✓** | Home Pocket 加"バイク"是额外 |
| 税金・社会保障 | ✗（非消費支出） | 税金 | 税・社会保障 | 税金 | ✗ | **税・社会保障 ✓** | 家計調査明确不视为消费 |
| 保険 | ✗（非消費支出） | → (医療内) | 保険 | - | ✗ | **保険 ✓** | Zaim 合并 |
| 大型/特別支出 | ✗ | 大型支出 | 特別な支出 | - | ✗ | **特別な支出 ✓** | 日本 app 特色 |
| 現金・カード | ✗ | → (その他内) | 現金・カード | - | ✗ | **現金・カード ✓** | 只有 MF ME 和 Home Pocket 明显设 |
| 家具・家事 | 家具・家事用品 | → (大型支出+住まい) | → (住宅+日用品) | - | ✗ | → (住宅+日用品) | 家計調査独立，app 散入 |
| お小遣い | → (その他内) | → (その他内) | → (中項目) | - | ✗ | → (L2 `cat_other_allowance`) | **无人把它当 L1** 但家計簿三分法当固定費 |
| 仕送り | → (その他内) | → (その他内) | - | - | ✗ | → (L2 `cat_other_remittance`) | 家計調査明设 |
| 資産形成/投資 | **非消費支出** | ✗（用 転送扱い）| ✗（用 転送扱い） | 投資系 app | ✗ | **資産形成 ✓** | **Home Pocket 独有** |
| ふるさと納税 | → (税以外) | → (税金 L2?) | → (特別の L2?) | - | ✗ | **✗ 缺失** | 必需追加 |

\* 表示基于公开资料推断，未 100% 确认完整清单

**共识类目（6/6）**: 食費、教育・教養、水道・光熱費、通信費、住宅、趣味・娯楽 — 这些是全球记账共识，现有 Home Pocket 都已覆盖。

**日本特色类目**: `特別な支出`、`現金・カード`、`冠婚葬祭` — 前两者只在 Zaim/MF ME 类日本 app 存在。

**Home Pocket 独有类目**: `資産形成`（双账本哲学的体现）—— 明确为 **intentional divergence**，并非错误。

**现有 Home Pocket 的缺失**: `ふるさと納税`（即使作为 L2 也没有）、`学資保険`（Zaim L2 有）、`NHK受信料`（Zaim L2 有独立的"放送サービス料金"但现有 `cat_communication_broadcast` 语义等同，OK）、`人間ドック`（Zaim 隐含在 医療 L2）、`免許教習`（Zaim 车 L2）

### 3.2 L2 数量横向对比

| App | 支出 L1 | 支出 L2 数量 | L2 自定义上限 | 备注 |
|-----|---------|-------------|--------------|------|
| Zaim (free) | 15 | ~65 | Premium 限定 | L2 可自由编辑 |
| Zaim (Premium) | 15 | ~65 起 | 无上限 | 全部可编辑 |
| MF ME | 16 | ~93 默认 | +100 可追加 | L1 不可编辑 |
| Moneytree | 20+ | 不详 | 有限 | L1 严格锁死 |
| おカネレコ (free) | 15 | 0 (扁平) | 3 (共 18) | 无层级 |
| おカネレコ (paid) | 15 | 0 (扁平) | 最多 90 | 无层级 |
| **Home Pocket** | **19** | **103** | **无上限** | 用户自定义无限制 |

**结论**: Home Pocket 的 19×103 配置**略超 MF ME**，符合"主流日本家計簿"的规模，不需要大幅精简 L2 数量——**精确度需要提高，而不是删减**。

---

## 4. 现有 Home Pocket 类目体系评估

### 4.1 与 Money Forward ME 的同源关系

**关键事实**: 现有 19 个 L1 中，16 个与 MF ME 16 大項目一一对应（顺序甚至接近）。

| Home Pocket L1 | MF ME 对应 | 状态 |
|----------------|-----------|------|
| `cat_food` 食費 | 食費 | 一致 |
| `cat_daily` 日用品 | 日用品 | 一致 |
| `cat_transport` 交通費 | 交通費 | 一致 |
| `cat_hobbies` 趣味・娯楽 | 趣味・娯楽 | 一致 |
| `cat_clothing` 衣服・美容 | 衣服・美容 | 一致 |
| `cat_social` 交際費 | 交際費 | 一致 |
| `cat_health` 健康・医療 | 健康・医療 | 一致 |
| `cat_education` 教育・教養 | 教養・教育 | 语序微差 |
| `cat_cash_card` 現金・カード | 現金・カード | **一致但反模式** |
| `cat_utilities` 水道・光熱費 | 水道・光熱費 | 一致 |
| `cat_communication` 通信費 | 通信費 | 一致 |
| `cat_housing` 住宅 | 住宅 | 一致 |
| `cat_car` 車・バイク | 自動車 | Home Pocket 含"バイク" |
| `cat_tax` 税・社会保障 | 税・社会保障 | 一致 |
| `cat_insurance` 保険 | 保険 | 一致 |
| `cat_special` 特別な支出 | 特別な支出 | 一致 |
| `cat_asset` 資産形成 | **无** | **Home Pocket 独有** |
| `cat_other_expense` その他 | （MF ME 在 中項目 层处理） | Home Pocket 提为 L1 |
| `cat_uncategorized` 未分類 | （技术兜底） | Home Pocket 独有 |

**结论**: **Home Pocket 类目体系 = Money Forward ME + 3 个追加**。MF ME 是日本市占率最高的记账 app（15M+ 用户），以它为基准意味着现有体系**在日本用户的认知负担上很轻**——学习成本几乎为零。

**但是**这也意味着 Home Pocket **继承了 MF ME 的所有结构性缺陷**，尤其是 `現金・カード` 这个反模式。

### 4.2 L1 层面的具体问题

#### 问题 #1: `cat_cash_card`（現金・カード）是反模式

**现状**: L1 类目 `cat_cash_card`，iconography `credit_card`，色 `#546E7A`，ledger `survival`，无 L2。

**为什么是反模式**:
- 从语义上看，"现金"和"卡"不是消费类别，而是**支付方式**或**账户**
- MF ME 用这个类目承载 ATM 提款/不明カード支出——一种**对缺失「账户间转账」原语的 workaround**
- Home Pocket 已有 `AccountsTable` 和 `BooksTable`，原生支持账户概念。只需要一个 `Transfer` 原语（`from_account_id` + `to_account_id`）即可正确处理"从银行提现金"这类操作
- 保留此类目会引导用户把真正的账户转账记为"消费"，污染统计

**推荐**: **删除 `cat_cash_card`**，同步在产品端提供"账户间转账"功能。如果暂时保留，需要在产品内部显著提示：仅在无法用转账替代时使用。

**风险**: 从 MF ME 迁移来的用户可能期待此类目存在。过渡期可保留，但在 settings 中可选隐藏。

#### 问题 #2: `cat_asset`（資産形成）是 Home Pocket 独有设计

**现状**: L1 类目 `cat_asset`，icon `savings`，色 `#1B5E20`，**ledger `soul`**，无 L2。

**为什么特殊**:
- **家計調査** 明确把「貯蓄・投資」列为"非消費支出"——即不是 `消費支出` 的一部分
- **Zaim / MF ME** 都没有此类目，投资/储蓄视为账户间转账
- **Home Pocket** 把它提升为 L1 且归入 **灵魂账本**，体现"自我投资即灵魂支出"的产品哲学——这是**产品差异化的核心**之一

**推荐**: **保留但明确声明为 intentional**，并做三件事:
1. 在 `categories.md` 的头部添加 "Asset Building as Soul Ledger — Home Pocket's Unique Design" 一节说明
2. 追加缺失的 L2: `NISA`、`iDeCo`、`積立投資`、`貯蓄`、`定期預金`、`外貨`、`不動産投資`、`その他`（共 8 个）
3. 在应用首次引导中，解释此类目与"银行转账到储蓄账户"的差别——前者是记在账面上的"soul spending"，后者是纯财务调整

**风险**: 用户可能困惑"为什么存钱算支出"。需要 onboarding 文案支持。

#### 问题 #3: `cat_special`（特別な支出）与 住宅/車/趣味 L2 重复

**现状**: `cat_special` 有 L2: `general`, `furniture`, `housing`, `wedding`, `fertility`, `nursing`, `other`。

与下列其他 L1 有重复:
- `cat_housing_furniture`（家具） vs `cat_special_furniture`（家具・家電）
- `cat_housing_renovation`（リフォーム） vs `cat_special_housing`（住宅・リフォーム）
- `cat_hobbies_travel`（旅行） vs `cat_special_*`（大型旅行归入哪里？）

**为什么会有**: 这是 **Zaim 大型支出 + MF ME 特別な支出** 的通用日本家計簿设计，按"频率"而非"类型"切分。优点：用户可以显式看到"今月 / 今年的大额突发支出"；缺点：归类决策发生在每笔交易时，UX 成本高。

**推荐**:

**方案 A（保守）**: 保留现有重复，但在 UI 中明确引导规则 ("一般的な日常家具は `住宅`、年に一度の大型買い替えは `特別な支出`")

**方案 B（推荐）**: 把 `cat_special` 从 L1 **降级为 Transaction tag**（与三分法同维度），不再是 Category。用户在添加交易时可以勾选 "これは特別費ですか？" tag，与 L1 `住宅`/`車`/`趣味` 正交共存。

**方案 B 的优点**:
- 消除 L2 重复
- 释放一个 L1 slot
- 直接对齐日本家計簿"固定費/変動費/特別費"三分法的 `特別費` 概念
- 与双账本 orthogonal 维度一致（双账本也是 transaction-level 概念）

本文档**推荐方案 B**，但方案 A 也可接受（迁移成本更低）。

#### 问题 #4: `cat_other_expense` 混入转账类项目

**现状**: `cat_other_expense` L2 包含:
- `cat_other_advances` (立替金) — 债权，不是消费
- `cat_other_remittance` (仕送り) — 赡养转账，金钱转移
- `cat_other_allowance` (お小遣い) — 预算分配，不是消费
- `cat_other_business` (事業費) — 业务支出，属于单独账簿
- `cat_other_debt` (返済) — 负债偿还，不是消费
- `cat_other_misc` (雑費) — ✓ 真正的杂费
- `cat_other_unclassified` (使途不明金) — ✓ 真正的未分类
- `cat_other_other` — ✓ 兜底

**推荐**:

1. **`立替金` 移出到 Account Transfer 原语** —— 不是支出，是应收
2. **`仕送り` 保留但提升到 L1 或移到"家族への支出"新 L1**（日本家庭高频项）
3. **`お小遣い` 强烈推荐提升为 L1** `cat_allowance`（日本家計簿伝統的固定費核心）
4. **`事業費` 移出**到专门的"事業簿"或单独账簿逻辑——Home Pocket 已有 `Book` 概念，应使用 book 分离而非类目
5. **`返済` 移出到 Liability/Loan 原语**——与 `cat_asset` 的"资产流动"对称
6. **保留 `雑費`、`使途不明金`、`その他`** 作为真正的兜底 L2

### 4.3 L2 层面的具体问题

按 L1 罗列需要改动的 L2。✓ = 保留，➕ = 追加，➖ = 删除，✏️ = 重命名，🔀 = 合并。

#### `cat_food` (食費, 8 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|----- |------|
| ✓ | `cat_food_groceries` | 食料品 | 保留 |
| ✓ | `cat_food_cafe` | カフェ | 保留 |
| ✓ | `cat_food_other` | その他食費 | 保留 |
| ➖ | `cat_food_general` | 食費（一般） | **删除** — L1 已代表通用名 |
| ✏️ | `cat_food_dining_out` → `cat_food_dining_out` | 外食 | 保留（推荐保留而非时段细分） |
| 🔀 | `cat_food_breakfast` + `cat_food_lunch` + `cat_food_dinner` | 朝/昼/晩 | **合并到 `cat_food_meals`** 或删除 — 语义与 `外食` 交叉 |
| ➕ | `cat_food_delivery` | デリバリー | 新增 — Uber Eats/出前館 等日本高频 |
| ➕ | `cat_food_drinks` | 飲料・酒類 | 新增 — 家計調査 独立子项 |

**推荐 L2 结构（食費, 7 个）**: `食料品 / 外食 / カフェ / デリバリー / 飲料・酒類 / お酒・嗜好品 / その他`

#### `cat_daily` (日用品, 6 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_daily_general` | 日用品 | 删除 占位 |
| ✓ | `cat_daily_household` | 生活雑貨 | 保留 |
| ✓ | `cat_daily_children` | 子ども関連 | 保留 |
| ✓ | `cat_daily_pets` | ペット関連 | 保留 |
| ✓ | `cat_daily_tobacco` | タバコ | 保留 |
| ✓ | `cat_daily_other` | その他日用品 | 保留 |
| ➕ | `cat_daily_drugstore` | ドラッグストア | 新增 — MF ME 有，日本家庭高频 |
| ➕ | `cat_daily_subscription` | サブスク雑貨 | 新增 — Amazon 定期便、日用品サブスク 等 |

#### `cat_transport` (交通費, 6 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_transport_general` | 交通費 | 删除占位 |
| ✓ | `cat_transport_train` | 電車 | 保留 |
| ✓ | `cat_transport_bus` | バス | 保留 |
| ✓ | `cat_transport_taxi` | タクシー | 保留 |
| ✓ | `cat_transport_flights` | 飛行機 | 保留 |
| ✓ | `cat_transport_other` | その他交通 | 保留 |
| ➕ | `cat_transport_shinkansen` | 新幹線 | 新增 — 日本出差核心项 |
| ➕ | `cat_transport_highway_bus` | 高速バス | 新增 — 日本中长距离交通 |

#### `cat_hobbies` (趣味・娯楽, 7 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_hobbies_leisure` | レジャー・スポーツ | 保留 |
| ✓ | `cat_hobbies_events` | イベント | 保留 |
| ✓ | `cat_hobbies_movies` | 映画・動画 | 保留 |
| ✓ | `cat_hobbies_travel` | 旅行 | 保留 |
| ✓ | `cat_hobbies_books` | 本 | 保留 (Zaim 有独立 `書籍` 在 教育 L2，双属) |
| ✓ | `cat_hobbies_other` | その他趣味・娯楽 | 保留 |
| 🔀 | `cat_hobbies_games` | 音楽・ゲーム・漫画 | **拆分为 `cat_hobbies_music` / `cat_hobbies_games` / `cat_hobbies_manga`** (Zaim 分开) |
| ➕ | `cat_hobbies_subscription` | エンタメサブスク | 新增 — Netflix/Spotify/Disney+ 等 |
| ➕ | `cat_hobbies_oshikatsu` | **推し活** | 新增 — 日本 Z 世代核心消费 |
| ➕ | `cat_hobbies_fan_goods` | グッズ | 新增 — 与 推し活 配套 |

**注**: `推し活` 和 `グッズ` 是日本年轻家庭（30 代以下）的典型支出，主流 app 默认不覆盖但 おカネレコ 用户常自定义。作为 `soul` ledger 的典型 L2。

#### `cat_clothing` (衣服・美容, 8 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_clothing_clothes` | 衣服 | 保留 |
| ✓ | `cat_clothing_accessories` | アクセサリー・小物 | 保留 |
| ✓ | `cat_clothing_underwear` | 下着 | 保留 |
| ✓ | `cat_clothing_hair` | 美容院、理髪 | 保留 |
| ✓ | `cat_clothing_cosmetics` | 化粧品 | 保留 |
| ✓ | `cat_clothing_esthetic` | エステ・ネイル | 保留 |
| ✓ | `cat_clothing_cleaning` | クリーニング | 保留 |
| ✓ | `cat_clothing_other` | その他衣服・美容 | 保留 |
| ➕ | `cat_clothing_shoes` | 靴・履物 | 新增 — 家計調査 `被服及び履物` 独立子项 |
| ➕ | `cat_clothing_bags` | カバン | 新增 — 日本家庭频繁支出 |

#### `cat_social` (交際費, 5 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_social_general` | 交際費 | 删除占位 |
| ✓ | `cat_social_drinks` | 飲み会 | 保留 |
| ✓ | `cat_social_gifts` | プレゼント | 保留 |
| ✏️ | `cat_social_ceremonial` → `cat_social_goshugi` | ご祝儀・香典 | **重命名+缩窄** — 更精确对齐 Zaim |
| ✓ | `cat_social_other` | その他交際費 | 保留 |
| ➕ | `cat_social_kankon_sosai` | 冠婚葬祭（年度） | 新增 — 与 `特別な支出` 交叉，高频查询术语 |
| ➕ | `cat_social_fees` | 会費 | 新增 — 町内会費、組合費、OB会費 等日本固定费 |

#### `cat_health` (健康・医療, 5 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_health_fitness` | フィットネス | 保留 |
| ✓ | `cat_health_massage` | マッサージ・整体 | 保留 |
| ✓ | `cat_health_hospital` | 病院 | 保留 |
| ✓ | `cat_health_medicine` | 薬代 | 保留 |
| ✓ | `cat_health_other` | その他健康・医療 | 保留 |
| ➕ | `cat_health_dental` | 歯科 | 新增 — 日本家庭独立频繁支出 |
| ➕ | `cat_health_dock` | 人間ドック | 新增 — 日本年度健康检查文化 |
| ➕ | `cat_health_supplements` | サプリメント | 新增 — MF ME 有 |

#### `cat_education` (教育・教養, 7 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_education_books` | 書籍 | 保留 |
| ✓ | `cat_education_newspapers` | 新聞・雑誌 | 保留 |
| ✓ | `cat_education_classes` | 習いごと | 保留 |
| ✓ | `cat_education_textbooks` | 教科書・参考書 | 保留 |
| ✓ | `cat_education_tuition` | 学費 | 保留 |
| ✓ | `cat_education_cram_school` | 塾 | 保留 |
| ✓ | `cat_education_other` | その他教育・教養 | 保留 |
| ➕ | `cat_education_entrance_exam` | 受験料 | 新增 — Zaim 有，日本升学核心 |
| ➕ | `cat_education_gakushi_hoken` | 学資保険 | 新增 — **Zaim 把学资保险放教育下**（日本惯例） |
| ➕ | `cat_education_seminar` | セミナー・講座 | 新增 — 大人の学び直し |

#### `cat_utilities` (水道・光熱費, 5 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_utilities_general` | 光熱費 | 删除占位 |
| ✓ | `cat_utilities_electricity` | 電気代 | 保留 |
| ✓ | `cat_utilities_water` | 水道代 | 保留 |
| ✓ | `cat_utilities_gas` | ガス・灯油代 | 保留 |
| ✓ | `cat_utilities_other` | その他水道・光熱費 | 保留 |
| ➕ | `cat_utilities_kerosene` | 灯油 | 新增 — 北日本冬季核心 (可从 `gas` 拆出) |

#### `cat_communication` (通信費, 7 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_communication_mobile` | 携帯電話 | 保留 |
| ✓ | `cat_communication_landline` | 固定電話 | 保留 |
| ✓ | `cat_communication_internet` | インターネット | 保留 |
| ✓ | `cat_communication_broadcast` | 放送視聴料 | 保留 |
| ✓ | `cat_communication_delivery` | 宅配便・運送 | 保留 |
| ✓ | `cat_communication_other` | その他通信費 | 保留 |
| ➖ | `cat_communication_info` | 情報サービス | **删除或并入 `other`** — 语义模糊，主流 app 无 |
| ➕ | `cat_communication_nhk` | NHK受信料 | 新增 — 日本法定收费，应独立（从 `broadcast` 拆出） |
| ➕ | `cat_communication_postage` | 切手・はがき | 新增 — Zaim 有 |

#### `cat_housing` (住宅, 8 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_housing_rent` | 家賃 | 保留 |
| ✓ | `cat_housing_mortgage` | 住宅ローン | 保留 |
| ✓ | `cat_housing_management` | 管理費・積立金 | 保留 |
| ✓ | `cat_housing_furniture` | 家具 | 保留 |
| ✓ | `cat_housing_appliances` | 家電 | 保留 |
| ✓ | `cat_housing_renovation` | リフォーム | 保留 |
| ✓ | `cat_housing_insurance` | 地震・火災保険 | 保留 |
| ✓ | `cat_housing_other` | その他住宅 | 保留 |
| ➕ | `cat_housing_property_tax` | 固定資産税 | 新增 — 日本房产持有核心（也可交叉到 `cat_tax` 下） |
| ➕ | `cat_housing_utilities_setup` | 初期設備工事 | 新增 — 新居入居时一次性 |

#### `cat_car` (車・バイク, 8 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_car_fuel` | ガソリン | 保留 |
| ✓ | `cat_car_parking` | 駐車場 | 保留 |
| ✓ | `cat_car_toll` | 道路料金 | 保留 |
| ✓ | `cat_car_loan` | 自動車ローン | 保留 |
| ✓ | `cat_car_insurance` | 自動車保険 | 保留 |
| ✓ | `cat_car_tax` | 自動車税 | 保留 |
| ✓ | `cat_car_maintenance` | 車検・整備 | 保留 |
| ✓ | `cat_car_other` | その他車・バイク | 保留 |
| ➕ | `cat_car_driving_school` | 免許教習 | 新增 — Zaim 有 |
| ➕ | `cat_car_car_share` | カーシェア | 新增 — 日本都市 mobility 转型 |

#### `cat_tax` (税・社会保障, 4 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ✓ | `cat_tax_income` | 所得税・住民税 | 保留 |
| ✓ | `cat_tax_pension` | 年金 | 保留 |
| ✓ | `cat_tax_health_insurance` | 健康保険 | 保留 |
| ✓ | `cat_tax_other` | その他税・社会保障 | 保留 |
| ➕ | `cat_tax_furusato` | **ふるさと納税** | 新增 — **最高优先级缺失** |
| ➕ | `cat_tax_consumption` | 消費税（自主記録） | 新增（低优先级） |
| ➕ | `cat_tax_property` | 固定資産税 | 新增（或放 `cat_housing`） |
| ➕ | `cat_tax_nursing_insurance` | 介護保険 | 新增 — 40 岁以上家庭核心 |

**特别说明**: `ふるさと納税` 是日本家庭年度税务规划的核心手段，10-12 月集中发生、返礼品触发消费快感，属于日本家計簿 app 的**必备 L2**。现状完全缺失是一个严重遗漏。

#### `cat_insurance` (保険, 4 L2)

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_insurance_general` | 保険 | 删除占位 |
| ✓ | `cat_insurance_life` | 生命保険 | 保留 |
| ✓ | `cat_insurance_medical` | 医療保険 | 保留 |
| ✓ | `cat_insurance_other` | その他保険 | 保留 |
| ➕ | `cat_insurance_cancer` | がん保険 | 新增 — 日本独有细分 |
| ➕ | `cat_insurance_fire` | 火災・地震保険 | 新增（或保留在 `cat_housing_insurance` 交叉） |
| ➕ | `cat_insurance_income` | 所得補償保険 | 新增 |

#### `cat_special` (特別な支出, 7 L2)

**推荐**: 根据 §4.2 问题 #3 的方案 B，**此 L1 降级为 Transaction tag**。但如果保留（方案 A），L2 应调整如下:

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➖ | `cat_special_general` | 特別な支出 | 删除占位 |
| ✓ | `cat_special_wedding` | 結婚 | 保留 |
| ✓ | `cat_special_fertility` | 妊活・出産 | 保留 |
| ✓ | `cat_special_nursing` | 介護 | 保留 |
| ✓ | `cat_special_other` | その他特別な出費 | 保留 |
| ➖ | `cat_special_furniture` | 家具・家電 | **删除** — 使用 `cat_housing_*` 交叉 |
| ➖ | `cat_special_housing` | 住宅・リフォーム | **删除** — 使用 `cat_housing_renovation` |
| ➕ | `cat_special_funeral` | 葬儀 | 新增 — 与 wedding 对称 |
| ➕ | `cat_special_annual_ceremony` | 冠婚葬祭（年度） | 新增 |
| ➕ | `cat_special_hatsumode` | 初詣・年末年始 | 新增 — 日本年始固定特別費 |
| ➕ | `cat_special_otoshidama` | お年玉 | 新增 — 日本年始固定特別費 |
| ➕ | `cat_special_movement` | 引越し | 新增 — 日本春秋高频 |
| ➕ | `cat_special_furusato_annual` | ふるさと納税（年度額） | 新增（或归 `cat_tax_furusato`） |

#### `cat_asset` (資産形成, 0 L2 currently)

**现状**: 无 L2。

**推荐**: 追加 8 个 L2:

| 操作 | L2 | 日文 | 理由 |
|------|----|-----|------|
| ➕ | `cat_asset_nisa` | NISA | 日本最普及的投资账户 |
| ➕ | `cat_asset_ideco` | iDeCo | 日本个人年金账户 |
| ➕ | `cat_asset_tsumitate` | 積立投資 | 通用定期定额 |
| ➕ | `cat_asset_savings` | 貯蓄・定期預金 | 传统储蓄 |
| ➕ | `cat_asset_fx` | 外貨預金 | 日元避险 |
| ➕ | `cat_asset_stock` | 個別株・投資信託 | 个人投资 |
| ➕ | `cat_asset_realestate` | 不動産投資 | 资产组合 |
| ➕ | `cat_asset_other` | その他資産形成 | 兜底 |

#### 新增 L1 `cat_allowance` (お小遣い)

**推荐**: 从 `cat_other_expense > cat_other_allowance` 提升为独立 L1。

**L2 建议**:
| L2 | 日文 | 理由 |
|----|-----|------|
| `cat_allowance_self` | 本人 お小遣い | 记账人自己的零花钱 |
| `cat_allowance_spouse` | 配偶者 お小遣い | 日本家計簿伝統主要场景 |
| `cat_allowance_kids` | 子どもお小遣い | 与 `cat_daily_children` 区分（前者是"给"，后者是"为"孩子花） |
| `cat_allowance_other` | その他 | 兜底 |

**Ledger 归属**: **soul** — 零花钱本质是"可自由支配"的灵魂预算。

**理由**: 日本家計簿伝統把 お小遣い 归为"固定費"top-level，与 家賃/保険 同级。现有把它埋在 `cat_other_expense` L2 是降格。提升为 L1 后，用户在双账本视图中可以看到"本月 灵魂支出 = お小遣い + 趣味 + 教育 + 資産 = 合计 XXX 円"的自然语义。

### 4.4 收入侧问题

**现状**: 4 个 L1，没有 L2。

| Code | 日文 | 状态 |
|------|------|------|
| `cat_salary` | 給与 | 保留 |
| `cat_bonus` | 賞与 | 保留 |
| `cat_investment` | 投資収益 | 保留 |
| `cat_other_income` | その他収入 | 保留 |

**缺失的日本家庭收入类目**:

| 推荐追加 | 日文 | 中文 | 理由 |
|---------|------|------|------|
| `cat_side_business` | 副業・事業 | 副业 | 日本"副業解禁"潮流下的第二收入 |
| `cat_pension` | 年金 | 年金 | 60 岁以上家庭核心收入 |
| `cat_child_allowance` | 児童手当 | 育儿补贴 | 15 岁以下子女家庭月收入 |
| `cat_refund` | 還付金 | 退税/退款 | ふるさと納税控除、医療費控除等年度退款 |
| `cat_gift_income` | 祝い金・お年玉 | 红包/礼金 | 年始、冠婚葬祭 收入侧 |

**推荐后的 9 个收入 L1**（`cat_salary` 不变，按重要性排序）:

1. `cat_salary` 給与
2. `cat_bonus` 賞与
3. `cat_side_business` 副業・事業 **(新)**
4. `cat_pension` 年金 **(新)**
5. `cat_investment` 投資収益
6. `cat_child_allowance` 児童手当 **(新)**
7. `cat_refund` 還付金 **(新)**
8. `cat_gift_income` 祝い金・お年玉 **(新)**
9. `cat_other_income` その他収入

### 4.5 双账本映射评估

**现状** (`lib/shared/constants/default_categories.dart:928-948`):

| L1 | 现有 Ledger | 评估 |
|----|-----------|------|
| `cat_food` | survival | ✓ 正确 |
| `cat_daily` | survival | ✓ 正确 |
| `cat_transport` | survival | ✓ 正确 |
| `cat_hobbies` | soul | ✓ 正确（明确的灵魂消费） |
| `cat_clothing` | soul | **⚠️ 讨论**：衣服是必需品（survival），美容是灵魂（soul）——全归 soul 偏激 |
| `cat_social` | survival | **⚠️ 讨论**：飲み会 是 soul，冠婚葬祭 是 survival |
| `cat_health` | survival | ✓ 正确 |
| `cat_education` | soul | ✓ 正确（Home Pocket 核心哲学） |
| `cat_cash_card` | survival | **移除**（按 §4.2 #1） |
| `cat_utilities` | survival | ✓ 正确 |
| `cat_communication` | survival | ✓ 正确 |
| `cat_housing` | survival | ✓ 正确 |
| `cat_car` | survival | ✓ 正确 |
| `cat_tax` | survival | ✓ 正确 |
| `cat_insurance` | survival | ✓ 正确 |
| `cat_special` | survival | **⚠️ 讨论**：旅行/結婚 更像 soul |
| `cat_asset` | soul | ✓ 正确（Home Pocket 核心哲学） |
| `cat_other_expense` | survival | ✓ 默认合理 |
| `cat_uncategorized` | survival | ✓ 默认合理 |

**推荐**: 在 L1 层保持现有映射（大致合理），但**建议在 L2 层允许覆盖**——即 L2 可以声明自己的 ledger 而不继承 L1。例如:

- `cat_clothing` 仍为 **soul**，但 L2 `cat_clothing_clothes`、`cat_clothing_underwear`、`cat_clothing_cleaning` 覆盖为 **survival**，只有美容项保留 **soul**
- `cat_social` 仍为 **survival**，但 L2 `cat_social_drinks`、`cat_social_gifts` 覆盖为 **soul**
- `cat_special` 的 L2 按事件类型分开映射

技术实现: `category_ledger_configs_table` 已允许 per-category 配置（PK 是 `categoryId`，支持 L2 自己的条目），schema 层已支持，只需要在 seed 数据中追加 L2 覆盖记录。

---

## 5. 推荐的日本消費カテゴリ体系（摘要）

### 5.1 支出 L1 推荐（18 个 vs 现有 19 个）

| # | Code | 日文 | 中文 | 英文 | Icon | Color | Ledger | 变动 |
|---|------|------|------|------|------|-------|--------|------|
| 1 | `cat_food` | 食費 | 食费 | Food | restaurant | #FF5722 | survival | 保持 |
| 2 | `cat_daily` | 日用品 | 日用品 | Daily | local_mall | #00BCD4 | survival | 保持 |
| 3 | `cat_transport` | 交通費 | 交通费 | Transport | directions_bus | #2196F3 | survival | 保持 |
| 4 | `cat_hobbies` | 趣味・娯楽 | 兴趣娱乐 | Hobbies | sports_esports | #9C27B0 | soul | 保持 |
| 5 | `cat_clothing` | 衣服・美容 | 衣服美容 | Clothing & Beauty | checkroom | #E91E63 | soul (L2 可覆盖) | 保持 + L2 覆盖 |
| 6 | `cat_social` | 交際費 | 交际费 | Socializing | people | #FF9800 | survival (L2 可覆盖) | 保持 + L2 覆盖 |
| 7 | `cat_health` | 健康・医療 | 健康医疗 | Health & Medical | local_hospital | #F44336 | survival | 保持 |
| 8 | `cat_education` | 教育・教養 | 教育进修 | Education | school | #3F51B5 | soul | 保持 |
| 9 | `cat_utilities` | 水道・光熱費 | 水电燃气 | Utilities | flash_on | #FFC107 | survival | 保持 |
| 10 | `cat_communication` | 通信費 | 通信费 | Communication | phone_iphone | #00ACC1 | survival | 保持 |
| 11 | `cat_housing` | 住宅 | 住宅 | Housing | home | #795548 | survival | 保持 |
| 12 | `cat_car` | 車・バイク | 车与摩托 | Car & Motorcycle | directions_car | #455A64 | survival | 保持 |
| 13 | `cat_tax` | 税・社会保障 | 税与社会保障 | Taxes & Social Security | account_balance | #5D4037 | survival | 保持 |
| 14 | `cat_insurance` | 保険 | 保险 | Insurance | security | #827717 | survival | 保持 |
| 15 | `cat_special` | 特別な支出 | 特别支出 | Special Expenses | star | #AD1457 | survival | 保持 L1，大改 L2（或降级为 tag，方案 B） |
| **16** | **`cat_allowance`** | **お小遣い** | **零花钱** | **Allowance** | **wallet** | **#8D6E63** | **soul** | **新增 L1** |
| 17 | `cat_asset` | 資産形成 | 资产配置 | Asset Building | savings | #1B5E20 | soul | 保持 + 追加 L2 |
| 18 | `cat_other_expense` | その他 | 其他 | Other | more_horiz | #607D8B | survival | 保持 L1，但删掉转账类 L2 |
| — | ~~`cat_cash_card`~~ | ~~現金・カード~~ | — | — | — | — | — | **移除**（使用 Account Transfer 原语） |
| — | ~~`cat_uncategorized`~~ | ~~未分類~~ | — | — | — | — | — | **合并到 `cat_other_expense > cat_other_unclassified`** |

净变化: **-2 +1 = -1**，L1 从 19 → 18。

### 5.2 支出 L2 推荐净变化（汇总）

| 操作 | 数量 | 说明 |
|------|------|------|
| 删除 | ~12 | 主要是 `*_general` 占位符 + 食費时段细分 + 转账类 L2 |
| 新增 | ~40 | 日本高频缺失项（见 §4.3 各类目细节） |
| 重命名 | ~2 | 微调对齐 Zaim/MF ME 用词 |
| 合并 | ~3 | 食費时段项合并到 `外食` 等 |
| 保留 | ~80 | 大部分现状 L2 |

净 L2 总数: **现在 103 → 推荐 ~130**（增加是因为补齐日本特有项与 `cat_asset`/`cat_allowance` 新 L2）

### 5.3 收入 L1 推荐（9 个 vs 现有 4 个）

| # | Code | 日文 | 中文 | 英文 | Icon | Color | 变动 |
|---|------|------|------|------|------|-------|------|
| 1 | `cat_salary` | 給与 | 工资 | Salary | account_balance | #4CAF50 | 保持 |
| 2 | `cat_bonus` | 賞与 | 奖金 | Bonus | stars | #FFC107 | 保持 |
| 3 | **`cat_side_business`** | **副業・事業** | **副业/事业** | **Side Business** | **business_center** | **#00897B** | **新增** |
| 4 | **`cat_pension`** | **年金** | **年金** | **Pension** | **elderly** | **#7CB342** | **新增** |
| 5 | `cat_investment` | 投資収益 | 投资收益 | Investment Returns | trending_up | #009688 | 保持 |
| 6 | **`cat_child_allowance`** | **児童手当** | **育儿补贴** | **Child Allowance** | **child_friendly** | **#AED581** | **新增** |
| 7 | **`cat_refund`** | **還付金** | **退税/退款** | **Tax Refund** | **reply** | **#B0BEC5** | **新增** |
| 8 | **`cat_gift_income`** | **祝い金・お年玉** | **红包/礼金** | **Gift Income** | **redeem** | **#F48FB1** | **新增** |
| 9 | `cat_other_income` | その他収入 | 其他收入 | Other Income | attach_money | #8BC34A | 保持 |

### 5.4 双账本归属推荐

遵循"生存 = 活下去必需，灵魂 = 自我实现与价值投资"的 Home Pocket 哲学:

**Survival L1（13 个）**: 食費、日用品、交通費、健康・医療、水道・光熱費、通信費、住宅、車・バイク、税・社会保障、保険、特別な支出、その他、未分類(合并到 其他)

**Soul L1（5 个）**: 趣味・娯楽、**衣服・美容**(L2 部分 override)、教育・教養、**お小遣い(新)**、資産形成

**需要 L2 覆盖的 L1**:
- `cat_clothing`: 整体 soul，但 `clothes`, `underwear`, `shoes`, `cleaning` 覆盖为 **survival**
- `cat_social`: 整体 survival，但 `drinks`, `gifts` 覆盖为 **soul**
- `cat_special`: 整体 survival，但 `wedding`, `movement`, `hatsumode` 覆盖为 **soul**

---

## 6. 差异表：现有 → 推荐

### 6.1 L1 支出层面（操作汇总）

| 操作 | 现有 | 推荐 | 理由 |
|------|------|------|------|
| **保持** | `cat_food` 食費 | `cat_food` 食費 | MF ME 一致 |
| **保持** | `cat_daily` 日用品 | `cat_daily` 日用品 | MF ME 一致 |
| **保持** | `cat_transport` 交通費 | `cat_transport` 交通費 | MF ME 一致 |
| **保持** | `cat_hobbies` 趣味・娯楽 | `cat_hobbies` 趣味・娯楽 | MF ME 一致 |
| **保持** | `cat_clothing` 衣服・美容 | `cat_clothing` 衣服・美容 | MF ME 一致 |
| **保持** | `cat_social` 交際費 | `cat_social` 交際費 | MF ME 一致 |
| **保持** | `cat_health` 健康・医療 | `cat_health` 健康・医療 | MF ME 一致 |
| **保持** | `cat_education` 教育・教養 | `cat_education` 教育・教養 | MF ME 一致 |
| **保持** | `cat_utilities` 水道・光熱費 | `cat_utilities` 水道・光熱費 | MF ME 一致 |
| **保持** | `cat_communication` 通信費 | `cat_communication` 通信費 | MF ME 一致 |
| **保持** | `cat_housing` 住宅 | `cat_housing` 住宅 | MF ME 一致 |
| **保持** | `cat_car` 車・バイク | `cat_car` 車・バイク | MF ME 一致（"バイク"是延伸） |
| **保持** | `cat_tax` 税・社会保障 | `cat_tax` 税・社会保障 | MF ME 一致 |
| **保持** | `cat_insurance` 保険 | `cat_insurance` 保険 | MF ME 一致 |
| **保持** | `cat_special` 特別な支出 | `cat_special` 特別な支出 | 日本家計簿 特色 (或降级为 tag) |
| **保持** | `cat_asset` 資産形成 | `cat_asset` 資産形成 | Home Pocket 独有 soul 设计 |
| **保持** | `cat_other_expense` その他 | `cat_other_expense` その他 | L2 需大改 |
| **合并** | `cat_uncategorized` 未分類 | → `cat_other_expense > cat_other_unclassified` | 技术兜底不必 L1 |
| **移除** | `cat_cash_card` 現金・カード | — | 使用 Account Transfer 原语替代 |
| **新增** | — | `cat_allowance` お小遣い | 日本家計簿伝統的固定費核心 |

**净变化**: 移除 2 (`cat_cash_card`, `cat_uncategorized`) + 新增 1 (`cat_allowance`) = **-1 L1**（19 → 18）

### 6.2 L2 支出层面（按类目汇总）

| L1 | 删除 | 新增 | 净变化 |
|----|------|------|--------|
| `cat_food` | 4 (`general`, `breakfast`, `lunch`, `dinner`) | 2 (`delivery`, `drinks`) | -2 |
| `cat_daily` | 1 (`general`) | 2 (`drugstore`, `subscription`) | +1 |
| `cat_transport` | 1 (`general`) | 2 (`shinkansen`, `highway_bus`) | +1 |
| `cat_hobbies` | 0 (拆 `games` 不删) | 3 (`music`, `manga`, `subscription`, `oshikatsu`, `fan_goods` — `games` 拆 3) | +4 |
| `cat_clothing` | 0 | 2 (`shoes`, `bags`) | +2 |
| `cat_social` | 1 (`general`) + 1 rename (`ceremonial` → `goshugi`) | 2 (`kankon_sosai`, `fees`) | +1 |
| `cat_health` | 0 | 3 (`dental`, `dock`, `supplements`) | +3 |
| `cat_education` | 0 | 3 (`entrance_exam`, `gakushi_hoken`, `seminar`) | +3 |
| `cat_utilities` | 1 (`general`) | 1 (`kerosene`) | 0 |
| `cat_communication` | 1 (`info`) | 2 (`nhk`, `postage`) | +1 |
| `cat_housing` | 0 | 2 (`property_tax`, `utilities_setup`) | +2 |
| `cat_car` | 0 | 2 (`driving_school`, `car_share`) | +2 |
| `cat_tax` | 0 | 4 (`furusato`, `consumption`, `property`, `nursing_insurance`) | +4 |
| `cat_insurance` | 1 (`general`) | 3 (`cancer`, `fire`, `income`) | +2 |
| `cat_special` | 3 (`general`, `furniture`, `housing`) | 6 (`funeral`, `annual_ceremony`, `hatsumode`, `otoshidama`, `movement`, `furusato_annual`) | +3 |
| `cat_asset` | 0 | 8 (`nisa`, `ideco`, `tsumitate`, `savings`, `fx`, `stock`, `realestate`, `other`) | +8 |
| `cat_allowance` (新增 L1) | — | 4 (`self`, `spouse`, `kids`, `other`) | +4 |
| `cat_other_expense` | 3 (`advances`, `business`, `debt`) | 0 (保留 `remittance`, `misc`, `unclassified`, `other` + 从 `cat_uncategorized` 合并) | -3 |
| **总计** | **~15** | **~49** | **+~34** |

**推荐总 L2 数**: 现在 **103** → 推荐约 **137**

**移到非消费原语的 L2**:
- `cat_other_advances` (立替金) → Account Transfer
- `cat_other_debt` (返済) → Liability/Loan
- `cat_other_business` (事業費) → 独立 Book
- `cat_cash_card` 相关 → Account Transfer
- `cat_other_allowance` (お小遣い) → 提升到 L1 `cat_allowance`

### 6.3 L1 收入层面

| 操作 | 现有 | 推荐 | 理由 |
|------|------|------|------|
| 保持 | `cat_salary` 給与 | `cat_salary` 給与 | — |
| 保持 | `cat_bonus` 賞与 | `cat_bonus` 賞与 | — |
| 保持 | `cat_investment` 投資収益 | `cat_investment` 投資収益 | — |
| 保持 | `cat_other_income` その他収入 | `cat_other_income` その他収入 | — |
| **新增** | — | `cat_side_business` 副業・事業 | 日本副業解禁潮流 |
| **新增** | — | `cat_pension` 年金 | 60 岁以上家庭核心 |
| **新增** | — | `cat_child_allowance` 児童手当 | 日本子育て世代核心 |
| **新增** | — | `cat_refund` 還付金 | ふるさと納税 / 医療費控除 退款 |
| **新增** | — | `cat_gift_income` 祝い金・お年玉 | 年始 / 冠婚葬祭 收入侧 |

**净变化**: +5 L1（4 → 9）

---

## 7. 落地影响评估

**本章仅列出影响，不是本次 scope 的工作项**——落地是独立任务，需要基于本研究报告再单独规划。

### 7.1 需要修改的代码文件

| 文件 | 影响类型 | 大致规模 |
|------|---------|---------|
| `lib/shared/constants/default_categories.dart` | 大改 seed 数据 | L1: -2 +1 = +1 条; L2: 净 +34 条; 收入 L1: +5 条 |
| `lib/data/tables/categories_table.dart` | **schema 无需改** | level ∈ {1,2} 足够，无需追加字段 |
| `lib/data/tables/category_ledger_configs_table.dart` | **schema 无需改**，seed 数据微调 | +L2 override 记录（按 §4.5）约 10 条 |
| `lib/l10n/app_ja.arb` | 大改 | 删除 ~15 key，新增 ~50 key |
| `lib/l10n/app_zh.arb` | 大改 | 与 ja 同步 |
| `lib/l10n/app_en.arb` | 大改 | 与 ja 同步 |
| `lib/features/accounting/**` | 可能微改 | UI 层若有 hardcoded category 列表需同步 |
| `docs/dev/categories.md` | 重写 | 与新 seed 数据同步（或保留为"v1 基线"） |

### 7.2 需要新增的原语（可选，不强制）

如果采纳 "移除 `cat_cash_card`" 和 "移出转账类 L2" 的建议:

- **Account Transfer 原语**: 现有 `Transactions` 表是否已支持 `fromAccountId` + `toAccountId`？如未支持，需要追加迁移
- **Loan/Liability 原语**: 用于替代 `cat_other_debt`。如现有 Book 模型已能承载，则不需要

**本次研究不对这些原语的现状做判断**——需要独立探索任务确认。

### 7.3 用户数据迁移

如果现有用户已经有数据使用 `cat_cash_card` / `cat_other_advances` / `cat_other_debt` / `cat_other_allowance` 等被移除或重分类的类目，需要迁移策略:

| 场景 | 推荐处理 |
|------|---------|
| `cat_cash_card` 记录 | 迁移到 `cat_other_expense > cat_other_unclassified` + 提示用户逐项人工重分类 |
| `cat_other_allowance` 记录 | 自动迁移到新的 `cat_allowance > cat_allowance_self` |
| `cat_other_advances` 记录 | 打标 "需要人工确认"，默认保留在 `cat_other_expense` 下 |
| `cat_uncategorized` 记录 | 迁移到 `cat_other_expense > cat_other_unclassified` |
| 所有被删除的 `*_general` L2 记录 | 迁移到各 L1 的 `other` L2 |

**迁移策略应有 dry-run 模式** 和 **用户确认步骤**。

### 7.4 ARB Key 命名建议

沿用现有 `categoryFoodGroceries` 驼峰风格。新增 key 示例:

```json
{
  "categoryTaxFurusato": "ふるさと納税",
  "categoryEducationGakushiHoken": "学資保険",
  "categoryHealthDock": "人間ドック",
  "categoryAllowance": "お小遣い",
  "categoryAllowanceSelf": "本人お小遣い",
  "categoryAllowanceSpouse": "配偶者お小遣い",
  "categoryAssetNisa": "NISA",
  "categoryAssetIdeco": "iDeCo",
  "categorySideBusiness": "副業・事業",
  "categoryPension": "年金",
  "categoryChildAllowance": "児童手当",
  "categoryRefund": "還付金",
  "categoryGiftIncome": "祝い金・お年玉"
}
```

---

## 8. 开放问题与争议点

本章列出不确定的设计决策，等待产品方向/UX 测试给出答案。

### 8.1 「固定費 / 変動費 / 特別費」三分法的位置

**问题**: 日本家計簿伝統把所有支出划分成这三类，与 L1 类目是**正交维度**。Home Pocket 当前完全缺失这个维度。

**方案 A**: **作为 Transaction tag**。数据库层添加 `expense_type ENUM('fixed', 'variable', 'special') NULL`。用户在记账时选填。

**方案 B**: **作为 Budget 维度**。用户在预算设定里按三类而非类目切预算。

**方案 C**: **不引入**。接受类目层级就是单一维度。

**推荐**: 方案 A（tag）——最轻量、最灵活、对类目无侵入。

### 8.2 `cat_cash_card` 的处置

**方案 A**: 直接删除。需要 Account Transfer 原语支持。
**方案 B**: 保留但改为隐藏类目（仅从 MF ME 迁移用户可见）。
**方案 C**: 保留 + 重命名为 `口座振替` 明确语义。
**方案 D**: 保留原状 + 文档说明。

**推荐**: **方案 B**（过渡期）→ **方案 A**（v2 完全移除）。

### 8.3 `cat_allowance` (お小遣い) 作为 L1 的决定

**赞成**: 日本家計簿伝統是固定費 top-level，Home Pocket 双账本把它作为 soul L1 有强语义。

**反对**: 只有 Home Pocket 会这么做，其他日本 app（Zaim/MF ME）都放 L2——可能造成日本用户困惑。

**折中**: 作为 L1 提供，但在首次 onboarding 中说明 "お小遣いは Home Pocket では独立した大分類です"。

**推荐**: 提升为 L1（坚决），配合 onboarding 文案。

### 8.4 `cat_special` 的去留（方案 A vs 方案 B）

**方案 A**（§4.2 讨论过）: 保留 L1，接受 L2 与 housing/car/hobbies 的设计性重复

**方案 B**（§4.2 讨论过）: 降级为 Transaction tag，与三分法的 `特別費` 统一

**推荐**: 方案 B 更优雅，但迁移成本较高。v1 可先采用方案 A 并为 v2 预留方案 B 的迁移空间。

### 8.5 L2 Ledger 覆盖的 UX 表达

如果 `cat_clothing > cat_clothing_clothes` 是 survival 而 `cat_clothing > cat_clothing_cosmetics` 是 soul——双账本汇总时怎么展示？

- UI 应该在 L2 编辑界面显示 Ledger 标记
- 总览图表在 L1 层应按 L2 加权平均 OR 按多数决
- 推荐展示时"同一 L1 的不同 L2 走向不同账本"

这需要 UX/设计评审，不在本文档范围。

### 8.6 家計調査 "家具・家事用品" 独立 L1 的必要性

日本政府 taxonomy 把它独立成 L1，但主流 app 都散入 `住宅` + `日用品`。Home Pocket 当前随主流做法。

**问题**: 用户在做年度大清仓（换洗衣机/换床垫/购家具）时，希望有独立统计视图吗？

**推荐**: 不独立 L1，但在报表层提供"家具・家電"虚拟分类，跨 `cat_housing_furniture` + `cat_housing_appliances` + `cat_special_*`。

### 8.7 `推し活` 与 `サブスク` 作为 L2 的激进性

Home Pocket 如果面向 Z 世代家庭，`推し活`、`グッズ`、`サブスク` 是强卖点。但如果主要用户是 35+ 家庭主妇，这些会显得 cringe。

**推荐**: 作为**隐藏默认 L2**，在 onboarding 让用户选"ライフステージ"后自动开启对应 L2 集合。

---

## 9. 参考资料

### App 官方与助けセンター

- **Zaim ご利用ガイド・使い方**: https://content.zaim.net/manuals/show/51
- **Zaim 手動編集ブログ (kosodate-info)**: https://kakeibo.kosodate-info.com/archives/20920 —— Zaim 15 大分類完整清单的主要来源
- **Zaim みんなが気になる家計簿カテゴリ**: https://content.zaim.net/ideas/articles30
- **Money Forward ME サポート カテゴリの説明**: https://support.me.moneyforward.com/hc/ja/articles/900004380703
- **Money Forward ME カテゴリ追加・編集**: https://support.me.moneyforward.com/hc/ja/articles/4406222214937
- **Money Forward ME 中項目の表示方法**: https://support.me.moneyforward.com/hc/ja/articles/9435905292697
- **Moneytree Help Centre — Category Types**: https://help.getmoneytree.com/en/articles/407705
- **おカネレコ 公式サイト**: https://okane-reco.com/

### 第三方比较与评测

- **libecity — MF ME のカテゴリ分け徹底解説**: https://library.libecity.com/articles/01JR9NM6NFHPDBNJDST6NG7FXB
- **money-leaf — MF ME カテゴリー編集**: https://www.money-leaf.net/moneyforwardme-category-edit/ —— MF ME 16 大項目的主要确认来源
- **ゼロから家計簿 — 家計簿カテゴリカスタマイズ**: https://zero-kakeibo.com/category-setting/ —— 必要費/ゆとり費 2×2 framework
- **takobutsu 家計簿アプリ研究所 — おカネレコ**: https://takobutsu.blogspot.com/2020/05/okanereco02.html
- **takobutsu 家計簿アプリ研究所 — Moneytree**: https://takobutsu.blogspot.com/2020/06/moneytree002.html

### 政府标准

- **総務省統計局 家計調査**: https://www.stat.go.jp/data/kakei/2.html
- **家計調査 収支項目分類及びその内容例示（平成27年1月改定）**: https://www.stat.go.jp/data/kakei/kou27/reiji27.html —— 10 大費目主要来源
- **L 家計 | 政府統計の総合窓口 (e-Stat)**: https://www.e-stat.go.jp/koumoku/koumoku_teigi/L
- **2019年全国家計構造調査 収支項目分類一覧 (PDF)**: https://www.stat.go.jp/data/zenkokukakei/2019/pdf/syushi.pdf

### 日本家計簿伝統（固定費/変動費/特別費）

- **常陽銀行 — 家計簿の項目を一覧で紹介**: https://www.joyobank.co.jp/column/money/household_budget_categories.html
- **エネチェンジ — 家計簿の項目分類方法**: https://enechange.jp/articles/house-hold-account-book-expense-item
- **ミラシル by 第一生命 — 家計簿の項目はどう決める**: https://mirashiru.dai-ichi-life.co.jp/article/991436
- **CDエナジーダイレクト — 家計簿の項目を一覧化**: https://www.cdedirect.co.jp/media/c7-life/7864/
- **Looop でんき — 家計簿の項目**: https://looop-denki.com/home/denkinavi/savings/review/householdaccountbook/
- **Money Journal — 家計簿の項目はどう分ける**: https://sure-i.co.jp/journal/household/entry-10535/

### 代码基线（仅内部参考）

- `lib/shared/constants/default_categories.dart` — 当前 seed 数据
- `lib/data/tables/categories_table.dart` — schema (level ∈ {1,2})
- `lib/data/tables/category_ledger_configs_table.dart` — 双账本映射 schema
- `docs/dev/categories.md` — 现状清单基线
- `docs/design/research_japanese_kakeibo_apps_analytics_history.md` — UX 背景

---

**文档结束** — 本文档为研究报告，不包含任何代码改动。落地到 seed/ARB 的实施是独立任务，需基于本报告再单独规划（见 §7）。
