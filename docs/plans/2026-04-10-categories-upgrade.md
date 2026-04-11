# Category Taxonomy Upgrade (v2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 `lib/shared/constants/default_categories.dart` 的 seed 数据从基线 **19×103** 升级到 Japan-optimized **19×138**（按 `docs/dev/categories_recommended.md`），同步更新三语 ARB i18n、双账本映射、用户数据迁移（schema v13 → v14）与现有测试/文档，确保 analyzer 与完整测试套件保持 0 问题。

**Architecture:**
- **单一真源**：`default_categories.dart` 是 L1/L2 seed 的唯一来源；测试与 ARB 都从它派生
- **Drift 迁移策略**：新增 `schemaVersion 14`，`onUpgrade` 阶段内：先 remap 用户数据（transactions），再清理 orphan ledger configs，最后替换 categories 表的 system 行
- **TDD 驱动**：先改测试声明新状态（RED），再改 seed（GREEN），每批 L2 一次提交
- **ARB 顺序**：先加新 key（非破坏）→ 改 seed → 删旧 key + 修 analyzer 错误（一次性）

**Tech Stack:** Flutter / Dart / Drift + SQLCipher / Riverpod / Freezed / ARB i18n / flutter_test

**Spec document:** `docs/dev/categories_recommended.md`（由 `docs/dev/categories_japan_proposal.md` §5-6 研究结论落地的成品清单，19 L1 × 138 L2 = 157 条）

---

## 0. Pre-execution Context

### 关键现状事实

- **当前 schema version**: `13`（见 `lib/data/app_database.dart:44`）→ 目标 `14`
- **现有 seed 测试**: `test/unit/shared/constants/default_categories_test.dart`（已存在，会被打破，需要更新而非新建）
- **CategoryService**: `lib/infrastructure/category/category_service.dart`（需要检查是否有硬编码 category ID 引用）
- **Seed 文件**: `lib/shared/constants/default_categories.dart`（main rewrite target）
- **ARB 文件**: `lib/l10n/app_{ja,zh,en}.arb`
- **规范文档**: `docs/dev/categories_recommended.md`（所有 L1/L2 日/中/英名、icon、color、ledger 归属的权威来源）

### 升级摘要

| 层级 | 变化 |
|------|------|
| **L1 删除** | `cat_cash_card`, `cat_uncategorized`（2 条） |
| **L1 新增** | `cat_pet`（#7CB342, soul）, `cat_allowance`（#8D6E63, soul）（2 条） |
| **L1 净变** | 19 → 19（位置调整：cat_pet 插在 daily 之后，cat_allowance 插在 special 之后） |
| **L2 删除** | ~18（`*_general` 占位符 + food 时段细分 + other_expense 的转账类 L2 + cat_daily_pets） |
| **L2 新增** | ~53（日本高频：ふるさと納税/学資保険/人間ドック/NHK受信料/NISA·iDeCo/推し活/カーシェア/新幹線 等 + pet 专项 7 + allowance 4 + asset 8） |
| **L2 净变** | 103 → 138（+35） |
| **Ledger overrides** | 新增 9 条 L2 override（clothing 4 / social 2 / special 3） |

### 用户数据迁移映射（SQL remap 目标）

| 旧 category ID | 新 category ID | 备注 |
|---------------|----------------|------|
| `cat_cash_card` | `cat_other_unclassified` | L1 → L2 降级 |
| `cat_uncategorized` | `cat_other_unclassified` | L1 → L2 合并 |
| `cat_daily_pets` | `cat_pet_other` | L2 提升为 L1 后，旧 L2 transactions 保留在 pet/other |
| `cat_other_allowance` | `cat_allowance_self` | L2 提升为 L1 |
| `cat_other_advances` | `cat_other_misc` | 应为转账，暂入杂费兜底 |
| `cat_other_business` | `cat_other_misc` | 应为独立 Book，暂入杂费兜底 |
| `cat_other_debt` | `cat_other_misc` | 应为负债，暂入杂费兜底 |
| `cat_food_general` | `cat_food_other` | 占位符 → 兜底 |
| `cat_food_breakfast`, `lunch`, `dinner` | `cat_food_dining_out` | 语义最接近 |
| `cat_daily_general` | `cat_daily_other` | 占位符 → 兜底 |
| `cat_transport_general` | `cat_transport_other` | 占位符 → 兜底 |
| `cat_social_general` | `cat_social_other` | 占位符 → 兜底 |
| `cat_utilities_general` | `cat_utilities_other` | 占位符 → 兜底 |
| `cat_communication_info` | `cat_communication_other` | 语义模糊 → 兜底 |
| `cat_insurance_general` | `cat_insurance_other` | 占位符 → 兜底 |
| `cat_special_general` | `cat_special_other` | 占位符 → 兜底 |
| `cat_special_furniture` | `cat_housing_furniture` | 跨类 remap（大型家具） |
| `cat_special_housing` | `cat_housing_renovation` | 跨类 remap |

### File Structure

| 文件 | 操作 | 责任 |
|------|------|------|
| `lib/shared/constants/default_categories.dart` | **rewrite** | Seed data source of truth |
| `lib/data/app_database.dart` | **modify** | bump schemaVersion 13→14, add v14 migration step |
| `lib/data/migrations/category_v14_migration.dart` | **create** (optional — or inline in app_database.dart per existing pattern) | v14 remap logic |
| `lib/l10n/app_ja.arb` | **modify** | +54 keys / -17 keys |
| `lib/l10n/app_zh.arb` | **modify** | 同步 ja |
| `lib/l10n/app_en.arb` | **modify** | 同步 ja |
| `test/unit/shared/constants/default_categories_test.dart` | **update** | 既有断言需要改 |
| `test/unit/data/migrations/category_v14_migration_test.dart` | **create** | 迁移红绿测试 |
| `lib/infrastructure/category/category_service.dart` | **check + maybe modify** | 检查硬编码引用 |
| `lib/features/**/*.dart` | **check + maybe modify** | Grep `cat_cash_card`/`cat_uncategorized` 等 |
| `docs/dev/categories.md` | **rewrite** | 更新到 v2 状态作为当前基线 |
| `docs/worklog/YYYYMMDD_HHMM_categories_v2_upgrade.md` | **create** | 按 `.claude/rules/worklog.md` 规范 |

---

## Task 0: Exploration (Read-only)

**Goal:** 理解当前迁移模式 / 测试结构 / 硬编码引用，让后续任务的代码改动精准。不做任何写入。

**Steps:**

- [ ] **Step 1: 阅读 spec**

```bash
cat docs/dev/categories_recommended.md
```

全文通读，特别注意 §L1 表、每个 L1 的 L2 子表、§L2 Ledger Overrides、Summary counts。

- [ ] **Step 2: 阅读现状 seed**

```bash
cat lib/shared/constants/default_categories.dart
```

注意 `_expenseL1`、`_expenseL2`、`_defaultLedgerConfigs` 列表结构和 `_l1`/`_l2`/`_config` 工厂方法签名。

- [ ] **Step 3: 读现有迁移代码**

```bash
sed -n '40,120p' lib/data/app_database.dart
```

确认 `schemaVersion = 13`，阅读 `onUpgrade` switch-case 模式，识别现有迁移步骤的代码风格（`migrator.addColumn` / `customStatement` / `migrator.createTable`）。记下 v13 的实现风格，v14 要与之一致。

- [ ] **Step 4: 读现有 seed 测试**

```bash
cat test/unit/shared/constants/default_categories_test.dart
```

列出所有既有断言。重要：既有测试硬编码了 `l1s[8].id == 'cat_cash_card'` 和 `l1s[18].id == 'cat_uncategorized'`，这些断言会在 Task 2 被覆盖成新目标状态。

- [ ] **Step 5: 检查硬编码 category ID 引用**

```bash
rg -n "cat_cash_card|cat_uncategorized|cat_other_allowance|cat_daily_pets|cat_food_general|cat_food_breakfast|cat_food_lunch|cat_food_dinner" lib test
```

记录所有命中的文件与行号。这些地方在 Task 12 需要修复。

- [ ] **Step 6: 检查 ARB 现状**

```bash
rg -l "categoryCashCard|categoryUncategorized|categoryOtherAllowance|categoryDailyPets" lib/l10n/
```

应只命中 3 个 arb 文件。验证 ARB key 命名风格（驼峰 `categoryFoodGroceries`）。

- [ ] **Step 7: 记录发现**

把发现写在本地 scratch（脑中或临时文件），不要 commit。重点产出：
- 现有 v13 迁移代码的结构模式（单文件 inline vs 分文件）
- 硬编码引用的完整文件列表
- 预计 Task 12 需要修改的文件数量

**No commit.** 本任务只读。

---

## Task 1: Pre-flight Baseline

**Goal:** 确保升级从干净基线开始。任何基线失败必须先修复再继续。

**Steps:**

- [ ] **Step 1: 检查 git 状态**

```bash
git status
```

Expected: 工作区仅包含允许的 WIP（例如 docs/dev 的 recommended 文件）。如果有无关修改，stash 或 commit 后再继续。

- [ ] **Step 2: 确保生成代码最新**

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

Expected: 全部成功，`lib/generated/`、`*.g.dart`、`*.freezed.dart` 已更新。

- [ ] **Step 3: Analyzer 基线**

```bash
flutter analyze
```

Expected: `No issues found!`。如果有，**先停下来修掉**——本计划不允许把基线问题与升级问题混在一起。

- [ ] **Step 4: 测试基线**

```bash
flutter test
```

Expected: 所有测试通过。

- [ ] **Step 5: Commit 基线标记（可选）**

如果 Step 1-4 期间有任何 build_runner 触发的生成文件变更：

```bash
git add -A
git commit -m "chore: regenerate code before categories upgrade"
```

否则跳过。

**No functional commit yet.**

---

## Task 2: Write Failing Spec Tests (RED)

**Goal:** 把 `test/unit/shared/constants/default_categories_test.dart` 改写成 v2 目标状态的断言。跑测试应该是 RED（许多失败）。

**Files:**
- Modify: `test/unit/shared/constants/default_categories_test.dart`

这一步的产出是"契约"——后续所有 seed 修改都以让这些测试变绿为目标。

- [ ] **Step 1: 写新的测试骨架**

完全替换既有文件内容为以下结构（完整实现，不要留 TODO）：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';

void main() {
  group('DefaultCategories v2 (Japan-optimized)', () {
    // ─── L1 counts ───
    group('L1 counts', () {
      test('has 19 expense L1 categories', () {
        final l1s = DefaultCategories.expenseL1;
        expect(l1s.length, 19);
        expect(l1s.every((c) => c.level == 1), isTrue);
        expect(l1s.every((c) => c.parentId == null), isTrue);
      });

      test('has 4 income L1 categories', () {
        expect(DefaultCategories.incomeL1.length, 4);
      });
    });

    // ─── L1 presence & absence ───
    group('L1 presence', () {
      test('contains cat_pet and cat_allowance (new L1s)', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        expect(ids, contains('cat_pet'));
        expect(ids, contains('cat_allowance'));
      });

      test('does NOT contain cat_cash_card or cat_uncategorized', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        expect(ids, isNot(contains('cat_cash_card')));
        expect(ids, isNot(contains('cat_uncategorized')));
      });

      test('retains all 17 preserved baseline L1s', () {
        final ids = DefaultCategories.expenseL1.map((c) => c.id).toSet();
        const kept = {
          'cat_food', 'cat_daily', 'cat_transport', 'cat_hobbies',
          'cat_clothing', 'cat_social', 'cat_health', 'cat_education',
          'cat_utilities', 'cat_communication', 'cat_housing', 'cat_car',
          'cat_tax', 'cat_insurance', 'cat_special', 'cat_asset',
          'cat_other_expense',
        };
        for (final id in kept) {
          expect(ids, contains(id), reason: 'L1 $id should be kept');
        }
      });
    });

    // ─── L2 counts per L1 ───
    group('L2 counts per L1', () {
      const expected = <String, int>{
        'cat_food': 6,
        'cat_daily': 6,
        'cat_pet': 7,
        'cat_transport': 7,
        'cat_hobbies': 10,
        'cat_clothing': 10,
        'cat_social': 5,
        'cat_health': 8,
        'cat_education': 10,
        'cat_utilities': 5,
        'cat_communication': 8,
        'cat_housing': 10,
        'cat_car': 10,
        'cat_tax': 7,
        'cat_insurance': 5,
        'cat_special': 8,
        'cat_allowance': 4,
        'cat_asset': 8,
        'cat_other_expense': 4,
      };

      test('total expense L2 count is 138', () {
        final l2s = DefaultCategories.all.where((c) => c.level == 2).toList();
        expect(l2s.length, 138);
      });

      for (final entry in expected.entries) {
        test('${entry.key} has ${entry.value} L2 children', () {
          final l2s = DefaultCategories.all
              .where((c) => c.level == 2 && c.parentId == entry.key)
              .toList();
          expect(l2s.length, entry.value);
        });
      }
    });

    // ─── L2 integrity ───
    group('L2 integrity', () {
      test('every L2 has a parentId pointing to an existing L1', () {
        final l1Ids = DefaultCategories.expenseL1
            .map((c) => c.id)
            .toSet()
            .union(DefaultCategories.incomeL1.map((c) => c.id).toSet());
        final orphans = DefaultCategories.all
            .where((c) => c.level == 2 && !l1Ids.contains(c.parentId))
            .toList();
        expect(orphans, isEmpty, reason: 'Found L2 categories with orphaned parentId');
      });

      test('no duplicate IDs across L1+L2', () {
        final all = DefaultCategories.all.map((c) => c.id).toList();
        expect(all.toSet().length, all.length);
      });

      test('all system categories have isSystem=true', () {
        expect(
          DefaultCategories.all.every((c) => c.isSystem),
          isTrue,
        );
      });
    });

    // ─── Ledger configs ───
    group('Ledger configs', () {
      test('every L1 has a ledger config', () {
        final configuredIds = DefaultCategories.defaultLedgerConfigs
            .map((c) => c.categoryId)
            .toSet();
        for (final l1 in DefaultCategories.expenseL1) {
          expect(configuredIds, contains(l1.id),
              reason: 'L1 ${l1.id} should have a ledger config');
        }
      });

      test('cat_pet and cat_allowance are soul ledger', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        expect(
          configs.firstWhere((c) => c.categoryId == 'cat_pet').ledgerType,
          LedgerType.soul,
        );
        expect(
          configs.firstWhere((c) => c.categoryId == 'cat_allowance').ledgerType,
          LedgerType.soul,
        );
      });

      test('L2 clothing overrides to survival', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        const overrides = {
          'cat_clothing_clothes',
          'cat_clothing_shoes',
          'cat_clothing_underwear',
          'cat_clothing_cleaning',
        };
        for (final id in overrides) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.survival,
              reason: '$id should override to survival');
        }
      });

      test('L2 social drinks/gifts override to soul', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        for (final id in ['cat_social_drinks', 'cat_social_gifts']) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.soul);
        }
      });

      test('L2 special wedding/movement/newyear override to soul', () {
        final configs = DefaultCategories.defaultLedgerConfigs;
        for (final id in [
          'cat_special_wedding',
          'cat_special_movement',
          'cat_special_newyear',
        ]) {
          final c = configs.firstWhere(
            (x) => x.categoryId == id,
            orElse: () => throw StateError('Missing ledger override for $id'),
          );
          expect(c.ledgerType, LedgerType.soul);
        }
      });
    });

    // ─── Key new L2 presence (Japan-specific) ───
    group('Key new L2 presence', () {
      const mustExist = {
        // tax
        'cat_tax_furusato',
        // education
        'cat_education_gakushi_hoken',
        'cat_education_entrance_exam',
        // health
        'cat_health_dock',
        'cat_health_dental',
        // communication
        'cat_communication_nhk',
        // hobbies
        'cat_hobbies_oshikatsu',
        // asset
        'cat_asset_nisa',
        'cat_asset_ideco',
        // pet
        'cat_pet_food',
        'cat_pet_medical',
        'cat_pet_insurance',
        // allowance
        'cat_allowance_self',
        'cat_allowance_spouse',
      };

      test('all Japan-specific L2 categories exist', () {
        final ids = DefaultCategories.all.map((c) => c.id).toSet();
        for (final id in mustExist) {
          expect(ids, contains(id), reason: '$id must exist in v2 seed');
        }
      });
    });

    // ─── Removed L2 absence ───
    group('Removed L2 absence', () {
      const mustNotExist = {
        // food time-slots removed
        'cat_food_general',
        'cat_food_breakfast',
        'cat_food_lunch',
        'cat_food_dinner',
        // general placeholders
        'cat_daily_general',
        'cat_transport_general',
        'cat_social_general',
        'cat_utilities_general',
        'cat_insurance_general',
        'cat_special_general',
        // moved to pet L1
        'cat_daily_pets',
        // communication
        'cat_communication_info',
        // special overlapping with housing
        'cat_special_furniture',
        'cat_special_housing',
        // moved to allowance L1
        'cat_other_allowance',
        // removed (should become transfer primitives)
        'cat_other_advances',
        'cat_other_business',
        'cat_other_debt',
      };

      test('all deprecated L2 categories are absent', () {
        final ids = DefaultCategories.all.map((c) => c.id).toSet();
        for (final id in mustNotExist) {
          expect(ids, isNot(contains(id)), reason: '$id must be removed in v2');
        }
      });
    });
  });
}
```

- [ ] **Step 2: 运行测试确认 RED**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart
```

Expected: 许多测试失败（大部分 L1/L2 presence、counts、overrides 测试会红）。这正是 TDD 的 RED 阶段。

- [ ] **Step 3: Commit RED**

```bash
git add test/unit/shared/constants/default_categories_test.dart
git commit -m "test: add failing spec for categories v2 (Japan-optimized)"
```

---

## Task 3: ARB — Add New i18n Keys (Additive)

**Goal:** 在删除旧 key 之前先加新 key，保证 gen-l10n 一直可用。

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

ARB key 命名规则：遵循既有 `categoryFoodGroceries` 驼峰风格。所有新 L1/L2 的翻译内容**完整**来源于 `docs/dev/categories_recommended.md` 的 JA/ZH/EN 三列。

**完整新增 key 清单**（按类目组织；每个 key 需在 3 个 ARB 文件中各加一条）:

**新 L1（2 个）**:
- `categoryPet` — JA `ペット` / ZH `宠物` / EN `Pets`
- `categoryAllowance` — JA `お小遣い` / ZH `零花钱` / EN `Allowance`

**食费新 L2**:
- `categoryFoodDelivery` — デリバリー / 外卖 / Delivery
- `categoryFoodDrinks` — 飲料・酒類 / 饮料酒类 / Drinks & Alcohol

**日用品新 L2**:
- `categoryDailyDrugstore` — ドラッグストア / 药妆店 / Drugstore
- `categoryDailySubscription` — サブスク雑貨 / 日用品订阅 / Daily Subscriptions

**交通新 L2**:
- `categoryTransportShinkansen` — 新幹線 / 新干线 / Shinkansen
- `categoryTransportHighwayBus` — 高速バス / 高速巴士 / Highway Bus

**兴趣娱乐新 L2**:
- `categoryHobbiesMusic` — 音楽 / 音乐 / Music
- `categoryHobbiesSubscription` — エンタメサブスク / 娱乐订阅 / Entertainment Subs
- `categoryHobbiesOshikatsu` — 推し活・グッズ / 粉丝活动/周边 / Fan Activities & Goods

（注：`categoryHobbiesGames` 已存在，但 EN 需从 "Music, Games & Manga" 改为 "Games"；`categoryHobbiesBooks` EN 从 "Books" 改为 "Books & Manga"——这 2 个是**修改**而非新增，一并在本任务内做）

**衣服美容新 L2**:
- `categoryClothingShoes` — 靴・履物 / 鞋履 / Shoes & Footwear
- `categoryClothingBags` — カバン / 包袋 / Bags

**交际新 L2**:
- `categorySocialFees` — 会費・組合費 / 会费/组合费 / Membership Fees

（注：`categorySocialCeremonial` 已存在，但 JA 需从「冠婚葬祭」改为「冠婚葬祭・ご祝儀・香典」——修改）

**健康新 L2**:
- `categoryHealthDental` — 歯科 / 牙科 / Dental
- `categoryHealthSupplements` — サプリメント / 保健品 / Supplements
- `categoryHealthDock` — 人間ドック / 体检 / Health Check-up

**教育新 L2**:
- `categoryEducationEntranceExam` — 受験料 / 考试费 / Entrance Exam Fees
- `categoryEducationGakushiHoken` — 学資保険 / 学资保险 / Education Insurance
- `categoryEducationSeminar` — セミナー・講座 / 研讨会讲座 / Seminars & Workshops

**水电新 L2**:
- `categoryUtilitiesKerosene` — 灯油 / 煤油 / Kerosene

**通信新 L2**:
- `categoryCommunicationNhk` — NHK受信料 / NHK 收视费 / NHK Reception Fee
- `categoryCommunicationPostage` — 切手・はがき / 邮票明信片 / Postage & Stamps

**住宅新 L2**:
- `categoryHousingPropertyTax` — 固定資産税 / 固定资产税 / Property Tax
- `categoryHousingUtilitiesSetup` — 引越し・初期設備 / 搬家初期设置 / Moving & Initial Setup

**车新 L2**:
- `categoryCarCarShare` — カーシェア / 共享汽车 / Car Share
- `categoryCarDrivingSchool` — 免許教習 / 驾校 / Driving School

**税新 L2**:
- `categoryTaxFurusato` — ふるさと納税 / 故乡税 / Furusato Nozei
- `categoryTaxConsumption` — 消費税 / 消费税 / Consumption Tax
- `categoryTaxNursingInsurance` — 介護保険 / 介护保险 / Long-term Care Insurance

**保险新 L2**:
- `categoryInsuranceCancer` — がん保険 / 癌症保险 / Cancer Insurance
- `categoryInsuranceIncome` — 所得補償保険 / 所得补偿保险 / Income Protection

**特别支出新 L2**:
- `categorySpecialFuneral` — 葬儀 / 葬礼 / Funeral
- `categorySpecialLifeEvent` — 成人式・七五三・入学式 / 成人礼/七五三/入学式 / Life Events
- `categorySpecialNewyear` — 初詣・お年玉・年末年始 / 新年参拜/压岁钱 / New Year Traditions
- `categorySpecialMovement` — 引越し / 搬家 / Moving

**お小遣い新 L1 + 4 L2**:
- `categoryAllowanceSelf` — 本人お小遣い / 本人零花钱 / Self Allowance
- `categoryAllowanceSpouse` — 配偶者お小遣い / 配偶零花钱 / Spouse Allowance
- `categoryAllowanceKids` — 子どもお小遣い / 儿童零花钱 / Kids Allowance
- `categoryAllowanceOther` — その他お小遣い / 其他零花钱 / Other Allowance

**資産形成新 8 L2**:
- `categoryAssetNisa` — NISA / NISA 账户 / NISA
- `categoryAssetIdeco` — iDeCo / iDeCo 年金 / iDeCo
- `categoryAssetTsumitate` — 積立投資 / 定期投资 / Regular Investment
- `categoryAssetSavings` — 貯蓄・定期預金 / 储蓄定期 / Savings & Deposits
- `categoryAssetStock` — 株・投資信託 / 股票信托 / Stocks & Funds
- `categoryAssetFx` — 外貨預金 / 外汇存款 / Foreign Currency
- `categoryAssetRealestate` — 不動産投資 / 不动产投资 / Real Estate Investment
- `categoryAssetOther` — その他資産形成 / 其他资产配置 / Other Asset Building

**ペット新 L1 + 7 L2**:
- `categoryPetFood` — ペットフード / 宠物食品 / Pet Food
- `categoryPetSupplies` — ペット用品・おもちゃ / 宠物用品/玩具 / Supplies & Toys
- `categoryPetMedical` — 病院・医療費 / 宠物医疗 / Vet & Medical
- `categoryPetGrooming` — トリミング / 美容护理 / Grooming & Salon
- `categoryPetInsurance` — ペット保険 / 宠物保险 / Pet Insurance
- `categoryPetHotel` — ペットホテル・預かり / 宠物寄养 / Boarding & Pet Sitter
- `categoryPetOther` — その他ペット / 其他宠物 / Other Pet Expenses

**Steps:**

- [ ] **Step 1: 在 `app_ja.arb` 追加所有新 key**

每条按 ARB 标准格式：

```json
"categoryPet": "ペット",
"@categoryPet": {
  "description": "Pets L1 category"
},
```

按类目顺序（L1 → 食费 L2 → 日用品 L2 → ...）添加，便于 review。

- [ ] **Step 2: 镜像到 `app_zh.arb`（中文值）**

同样的 key 列表，值取 ZH 列。`@` 描述可以共享或省略（跟现有约定走）。

- [ ] **Step 3: 镜像到 `app_en.arb`（英文值）**

同样的 key 列表，值取 EN 列。

- [ ] **Step 4: 处理 2 个需要修改的既有 key**

修改 `categoryHobbiesGames`:
- EN: "Music, Games & Manga" → "Games"
- JA/ZH 保持

修改 `categoryHobbiesBooks`:
- EN: "Books" → "Books & Manga"
- JA: "本" → "本・漫画"
- ZH: "图书" → "书籍漫画"

修改 `categorySocialCeremonial`:
- JA: "冠婚葬祭" → "冠婚葬祭・ご祝儀・香典"
- ZH: "红白喜丧" → "红白喜丧/礼金"
- EN: "Ceremonial Occasions" 保持

- [ ] **Step 5: 生成并验证**

```bash
flutter gen-l10n
flutter analyze
```

Expected: gen-l10n 成功；analyzer 仍然 0 issues（此时只添加了新 key，没删旧的，旧 UI 引用还能工作）。

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_ja.arb lib/l10n/app_zh.arb lib/l10n/app_en.arb lib/generated/
git commit -m "feat(i18n): add Japan-optimized category ARB keys (v2)"
```

---

## Task 4: Seed — L1 List + Ledger Config Reset

**Goal:** 更新 `_expenseL1` 列表和 `_defaultLedgerConfigs` 列表的 L1 部分。这是第一个可以让部分测试变绿的任务。

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**目标 L1 顺序（19 条）**:

```
sortOrder 1  cat_food          survival
sortOrder 2  cat_daily         survival
sortOrder 3  cat_pet           soul     ← NEW
sortOrder 4  cat_transport     survival
sortOrder 5  cat_hobbies       soul
sortOrder 6  cat_clothing      soul
sortOrder 7  cat_social        survival
sortOrder 8  cat_health        survival
sortOrder 9  cat_education     soul
sortOrder 10 cat_utilities     survival
sortOrder 11 cat_communication survival
sortOrder 12 cat_housing       survival
sortOrder 13 cat_car           survival
sortOrder 14 cat_tax           survival
sortOrder 15 cat_insurance     survival
sortOrder 16 cat_special       survival
sortOrder 17 cat_allowance     soul     ← NEW
sortOrder 18 cat_asset         soul
sortOrder 19 cat_other_expense survival
```

（`cat_cash_card` 与 `cat_uncategorized` 完全移除）

**Steps:**

- [ ] **Step 1: 更新 `_expenseL1` 列表**

定位现有列表（约 `default_categories.dart:18-56`），完全按上表重写。保留 `_l1(...)` 工厂调用风格。L1 参数包括 icon 和 color，从 `docs/dev/categories_recommended.md` §L1 表读取：

- `cat_pet`: icon `pets`, color `#7CB342`
- `cat_allowance`: icon `wallet`, color `#8D6E63`

其它 L1 保持原 icon/color（只有 sortOrder 可能微调）。

- [ ] **Step 2: 更新 `_defaultLedgerConfigs` 的 L1 部分**

定位现有列表（约 `default_categories.dart:928-948`）。对 L1 部分：
- 移除 `_config('cat_cash_card', ...)` 和 `_config('cat_uncategorized', ...)`
- 新增 `_config('cat_pet', LedgerType.soul)` 和 `_config('cat_allowance', LedgerType.soul)`
- 其它 L1 的 ledger 值保持不变

**本步骤不要添加 L2 override**——Task 11 专门处理。

- [ ] **Step 3: 运行 L1 相关测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "L1"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "Ledger configs"
```

Expected:
- `L1 counts` / `L1 presence` 全绿
- `Ledger configs > every L1 has a ledger config` 全绿
- `Ledger configs > cat_pet and cat_allowance are soul` 全绿
- 其它 `L2 count` 仍然红

- [ ] **Step 4: Commit**

```bash
git add lib/shared/constants/default_categories.dart
git commit -m "feat(seed): update L1 list (+pet +allowance -cash_card -uncategorized)"
```

---

## Task 5: Seed — L2 Batch A (food / daily / transport / hobbies)

**Goal:** 更新 4 个类目的 L2 条目，对齐 categories_recommended.md。

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**具体变更**（详见 `docs/dev/categories_recommended.md` 对应节）:

**cat_food** (8 → 6)
- Remove: `cat_food_general`, `cat_food_breakfast`, `cat_food_lunch`, `cat_food_dinner`
- Keep: `cat_food_groceries`, `cat_food_dining_out`, `cat_food_cafe`, `cat_food_other`
- Add: `cat_food_delivery` (icon `delivery_dining`), `cat_food_drinks` (icon `local_bar`)

**cat_daily** (6 → 6)
- Remove: `cat_daily_general`, `cat_daily_pets`
- Keep: `cat_daily_household`, `cat_daily_children`, `cat_daily_tobacco`, `cat_daily_other`
- Add: `cat_daily_drugstore` (icon `local_pharmacy`), `cat_daily_subscription` (icon `subscriptions`)

**cat_transport** (6 → 7)
- Remove: `cat_transport_general`
- Keep: `cat_transport_train`, `cat_transport_bus`, `cat_transport_taxi`, `cat_transport_flights`, `cat_transport_other`
- Add: `cat_transport_shinkansen` (icon `directions_railway`), `cat_transport_highway_bus` (icon `airport_shuttle`)

**cat_hobbies** (7 → 10)
- Keep: `cat_hobbies_leisure`, `cat_hobbies_events`, `cat_hobbies_movies`, `cat_hobbies_games`, `cat_hobbies_books`, `cat_hobbies_travel`, `cat_hobbies_other`
- Add: `cat_hobbies_music` (icon `music_note`), `cat_hobbies_subscription` (icon `subscriptions`), `cat_hobbies_oshikatsu` (icon `favorite`)

**Steps:**

- [ ] **Step 1: 定位并修改 `_expenseL2` 列表**

按类目块修改。保留现有 `_l2(id, nameKey, icon, color, parentId, sortOrder)` 工厂调用风格。

新增 L2 的 `nameKey` 使用 Task 3 已加入 ARB 的 camelCase key 对应的下划线版（例如 `cat_food_delivery` 的 name 字段应该是 `'category_food_delivery'`——和现有 `cat_food_groceries` → `'category_food_groceries'` 同风格）。

`sortOrder` 使用 categories_recommended.md 中的相对顺序，每块从 1 开始。

- [ ] **Step 2: 运行相关测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_food has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_daily has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_transport has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_hobbies has"
```

Expected: 4 个 L2 counts 测试应该全绿；新 L2 presence 中的 `cat_hobbies_oshikatsu` 也应该变绿。

- [ ] **Step 3: Commit**

```bash
git add lib/shared/constants/default_categories.dart
git commit -m "feat(seed): update food/daily/transport/hobbies L2 categories"
```

---

## Task 6: Seed — L2 Batch B (clothing / social / health / education)

**Goal:** 下一批 4 个类目。

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**具体变更**:

**cat_clothing** (8 → 10)
- Keep all 8 existing
- Add: `cat_clothing_shoes` (icon `directions_walk`), `cat_clothing_bags` (icon `shopping_bag`)

**cat_social** (5 → 5)
- Remove: `cat_social_general`
- Keep: `cat_social_drinks`, `cat_social_gifts`, `cat_social_ceremonial`, `cat_social_other`
- Add: `cat_social_fees` (icon `groups`)

**cat_health** (5 → 8)
- Keep all 5 existing (hospital, medicine, fitness, massage, other)
- Add: `cat_health_dental` (icon `medical_services`), `cat_health_supplements` (icon `health_and_safety`), `cat_health_dock` (icon `fact_check`)

**cat_education** (7 → 10)
- Keep all 7 existing
- Add: `cat_education_entrance_exam` (icon `quiz`), `cat_education_gakushi_hoken` (icon `card_membership`), `cat_education_seminar` (icon `co_present`)

**Steps:**

- [ ] **Step 1: 修改 `_expenseL2` 列表**
- [ ] **Step 2: 测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_clothing has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_social has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_health has"
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_education has"
```

Expected: 4 绿。

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(seed): update clothing/social/health/education L2 categories"
```

---

## Task 7: Seed — L2 Batch C (utilities / communication / housing / car)

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**具体变更**:

**cat_utilities** (5 → 5)
- Remove: `cat_utilities_general`
- Keep: electricity, gas, water, other
- Add: `cat_utilities_kerosene` (icon `propane_tank`)

**cat_communication** (7 → 8)
- Remove: `cat_communication_info`
- Keep: mobile, landline, internet, broadcast, delivery, other
- Add: `cat_communication_nhk` (icon `live_tv`), `cat_communication_postage` (icon `mail`)

**cat_housing** (8 → 10)
- Keep all 8 existing
- Add: `cat_housing_property_tax` (icon `receipt_long`), `cat_housing_utilities_setup` (icon `luggage`)

**cat_car** (8 → 10)
- Keep all 8 existing
- Add: `cat_car_car_share` (icon `car_rental`), `cat_car_driving_school` (icon `drive_eta`)

**Steps:**

- [ ] **Step 1: 修改 `_expenseL2` 列表**
- [ ] **Step 2: 测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_utilities has|cat_communication has|cat_housing has|cat_car has"
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(seed): update utilities/communication/housing/car L2 categories"
```

---

## Task 8: Seed — L2 Batch D (tax / insurance / special + allowance L1)

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**具体变更**:

**cat_tax** (4 → 7)
- Keep all 4 existing
- Add: `cat_tax_furusato` (icon `favorite_border`), `cat_tax_consumption` (icon `money_off`), `cat_tax_nursing_insurance` (icon `accessible`)

**cat_insurance** (4 → 5)
- Remove: `cat_insurance_general`
- Keep: life, medical, other
- Add: `cat_insurance_cancer` (icon `monitor_heart`), `cat_insurance_income` (icon `work`)

**cat_special** (7 → 8)
- Remove: `cat_special_general`, `cat_special_furniture`, `cat_special_housing`
- Keep: `cat_special_wedding`, `cat_special_fertility`, `cat_special_nursing`, `cat_special_other`
- Add: `cat_special_funeral` (icon `church`), `cat_special_life_event` (icon `celebration`), `cat_special_newyear` (icon `celebration`), `cat_special_movement` (icon `luggage`)

**cat_allowance** (NEW L1 → 4 L2)
- Add: `cat_allowance_self` (icon `person`), `cat_allowance_spouse` (icon `people`), `cat_allowance_kids` (icon `child_care`), `cat_allowance_other` (icon `more_horiz`)

**Steps:**

- [ ] **Step 1: 修改 `_expenseL2` 列表**
- [ ] **Step 2: 测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "cat_tax has|cat_insurance has|cat_special has|cat_allowance has"
```

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(seed): update tax/insurance/special + add allowance L2 categories"
```

---

## Task 9: Seed — L2 Batch E (asset + pet L1 + other_expense)

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**具体变更**:

**cat_asset** (0 → 8，首次添加 L2)
- Add: `cat_asset_nisa` (icon `account_balance_wallet`), `cat_asset_ideco` (icon `elderly`), `cat_asset_tsumitate` (icon `trending_up`), `cat_asset_savings` (icon `savings`), `cat_asset_stock` (icon `show_chart`), `cat_asset_fx` (icon `currency_exchange`), `cat_asset_realestate` (icon `apartment`), `cat_asset_other` (icon `more_horiz`)

**cat_pet** (NEW L1 → 7 L2)
- Add: `cat_pet_food` (icon `set_meal`), `cat_pet_supplies` (icon `inventory_2`), `cat_pet_medical` (icon `healing`), `cat_pet_grooming` (icon `shower`), `cat_pet_insurance` (icon `verified_user`), `cat_pet_hotel` (icon `hotel`), `cat_pet_other` (icon `more_horiz`)

**cat_other_expense** (8 → 4)
- Remove: `cat_other_advances`, `cat_other_allowance`, `cat_other_business`, `cat_other_debt`
- Keep: `cat_other_remittance`, `cat_other_misc`, `cat_other_unclassified`, `cat_other_other`
- No additions

**Steps:**

- [ ] **Step 1: 修改 `_expenseL2` 列表**
- [ ] **Step 2: 全量测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart
```

Expected: 所有 L2 counts / presence / absence 测试全绿；ledger override 相关可能仍有部分红（Task 11 修）。

- [ ] **Step 3: Commit**

```bash
git commit -am "feat(seed): add asset/pet L2 and prune other_expense L2"
```

---

## Task 10: Seed — L2 Ledger Overrides

**Goal:** 添加 9 个 L2 ledger override 条目到 `_defaultLedgerConfigs`，让 L2 可以覆盖 L1 的默认 ledger。

**Files:**
- Modify: `lib/shared/constants/default_categories.dart`

**要添加的 overrides**:

```dart
// L2 ledger overrides (per categories_recommended.md §L2 Ledger Overrides)
_config('cat_clothing_clothes', LedgerType.survival),   // 衣服 is basic necessity
_config('cat_clothing_shoes', LedgerType.survival),     // shoes is basic necessity
_config('cat_clothing_underwear', LedgerType.survival), // underwear is basic necessity
_config('cat_clothing_cleaning', LedgerType.survival),  // dry cleaning is maintenance
_config('cat_social_drinks', LedgerType.soul),          // 飲み会 is social enjoyment
_config('cat_social_gifts', LedgerType.soul),           // gifts are emotional expression
_config('cat_special_wedding', LedgerType.soul),        // life milestone
_config('cat_special_movement', LedgerType.soul),       // lifestyle upgrade
_config('cat_special_newyear', LedgerType.soul),        // cultural tradition
```

**Steps:**

- [ ] **Step 1: 追加到 `_defaultLedgerConfigs` 末尾**
- [ ] **Step 2: 运行全部 ledger 测试**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart --plain-name "Ledger configs"
```

Expected: 所有 ledger override 测试全绿。

- [ ] **Step 3: 运行完整测试文件**

```bash
flutter test test/unit/shared/constants/default_categories_test.dart
```

Expected: **全绿** ✅

- [ ] **Step 4: Commit**

```bash
git commit -am "feat(seed): add L2 ledger overrides for clothing/social/special"
```

---

## Task 11: ARB — Remove Deprecated Keys

**Goal:** 删除不再使用的 ARB key。此步骤会让 `flutter analyze` 暴露所有硬编码引用点，Task 12 一次性修复。

**Files:**
- Modify: `lib/l10n/app_ja.arb`
- Modify: `lib/l10n/app_zh.arb`
- Modify: `lib/l10n/app_en.arb`

**要删除的 key 列表**:

**L1 keys（2）**:
- `categoryCashCard`
- `categoryUncategorized`

**L2 keys（15）**:
- `categoryFoodGeneral`
- `categoryFoodBreakfast`
- `categoryFoodLunch`
- `categoryFoodDinner`
- `categoryDailyGeneral`
- `categoryDailyPets`
- `categoryTransportGeneral`
- `categorySocialGeneral`
- `categoryUtilitiesGeneral`
- `categoryCommunicationInfo`
- `categoryInsuranceGeneral`
- `categorySpecialGeneral`
- `categorySpecialFurniture`
- `categorySpecialHousing`
- `categoryOtherAdvances`
- `categoryOtherBusiness`
- `categoryOtherDebt`
- `categoryOtherAllowance`

**Steps:**

- [ ] **Step 1: 删除 ja/zh/en 三个文件中的所有上述 key**

记得删除 `categoryXxx` 和对应的 `@categoryXxx` 元数据双行。

- [ ] **Step 2: 运行 gen-l10n**

```bash
flutter gen-l10n
```

Expected: 成功（ARB 自身没有引用约束）。

- [ ] **Step 3: 运行 analyzer 识别断点**

```bash
flutter analyze 2>&1 | tee /tmp/categories_analyze.log
```

Expected: 会有错误，指向使用已删除 key 的代码位置（例如 `S.of(context).categoryCashCard`）。**不要立即修**，先记录所有错误位置。

- [ ] **Step 4: Commit（带已知 analyzer 错误）**

```bash
git add lib/l10n/ lib/generated/
git commit -m "feat(i18n): remove deprecated category ARB keys (will break analyzer)"
```

Note: 这是**故意**让下一个 commit 前的 analyzer 处于 broken 状态。Task 12 立即恢复。

---

## Task 12: Fix UI/Code References to Removed Categories

**Goal:** 修复所有 Task 11 暴露的 analyzer 错误 + Task 0 Step 5 grep 到的硬编码引用。

**Files:**
- Modify: 取决于 analyzer 错误和 grep 结果
- Possibly: `lib/infrastructure/category/category_service.dart`
- Possibly: `lib/features/accounting/**`（UI 层）

**常见修复模式**:

1. **UI 展开 seed 列表**: 如果 UI 只是遍历 `DefaultCategories.expenseL1` 渲染，不会引用具体 ID——自动适配，无需修
2. **硬编码 ID 过滤**: 如果有 `if (transaction.categoryId == 'cat_cash_card')` 之类判断——根据语义决定 remap 或删除
3. **ARB key 引用**: 如果有 `S.of(context).categoryCashCard`——删除该 UI 分支或改用其它类目
4. **测试 fixture**: 其它测试可能用了旧 category ID 作为 sample——remap 到新 ID

**Steps:**

- [ ] **Step 1: 列出所有 analyzer 错误**

```bash
flutter analyze 2>&1 | grep -E "error|warning" | tee /tmp/cat_errors.log
```

- [ ] **Step 2: 逐个修复**

按文件分组，逐文件处理。对每个文件：
1. 读 Context
2. 判断该引用的用途（是硬编码逻辑 vs 简单展示）
3. 修改为正确的新类目或删除该代码路径
4. 保存

- [ ] **Step 3: 重新跑 analyzer 直到 0 错误**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: 跑完整测试套件**

```bash
flutter test
```

Expected: 所有测试通过，包括 Task 2 的 seed 测试。

- [ ] **Step 5: Commit**

```bash
git add -u
git commit -m "fix: update UI/code references after category ID changes"
```

---

## Task 13: Migration Test (RED)

**Goal:** 写 Drift 迁移的单元测试，确保 v13 → v14 不丢数据。RED 状态——migration 还没实现。

**Files:**
- Create: `test/unit/data/migrations/category_v14_migration_test.dart`

**参考**: Task 0 Step 3 记录的现有 v13 迁移代码风格；Drift 测试文档参考 `https://drift.simonbinder.eu/docs/advanced-features/migrations/`。

**测试应该覆盖**:

1. **数据量守恒**: 迁移前 N 笔 transaction，迁移后仍是 N 笔（只变 categoryId，不变条数）
2. **cat_cash_card → cat_other_unclassified 映射**
3. **cat_uncategorized → cat_other_unclassified 映射**
4. **cat_daily_pets → cat_pet_other 映射**
5. **cat_other_allowance → cat_allowance_self 映射**
6. **cat_other_advances / business / debt → cat_other_misc 映射**
7. **cat_food_breakfast/lunch/dinner → cat_food_dining_out 映射**
8. **所有 `*_general` → `*_other` 映射**
9. **cat_special_furniture → cat_housing_furniture 跨类映射**
10. **cat_special_housing → cat_housing_renovation 跨类映射**
11. **categories 表：v14 后应包含 cat_pet / cat_allowance + 所有新 L2**
12. **categories 表：v14 后应不包含 cat_cash_card / cat_uncategorized / 所有已删 L2**
13. **category_ledger_configs：旧 L1 config 被清理；新 L1 config 被插入；L2 overrides 被插入**

**测试骨架**（engineer 需根据 Task 0 调研补全细节）:

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';

void main() {
  group('Category v14 migration', () {
    late AppDatabase db;

    // 工具：按 v13 schema 初始化一个 in-memory db 并塞入旧 seed + 示例 transactions
    Future<AppDatabase> setupV13WithSamples() async {
      // TODO per Task 0 findings: use schema_v13 snapshot or raw SQL to
      // populate an old-state db, then run migration to v14
      throw UnimplementedError();
    }

    tearDown(() async {
      await db.close();
    });

    test('preserves transaction count through v13 → v14 migration', () async {
      db = await setupV13WithSamples();
      // expected: count of transactions unchanged
    });

    test('remaps cat_cash_card transactions to cat_other_unclassified', () async {
      db = await setupV13WithSamples();
      // seed one transaction with categoryId='cat_cash_card'
      // run migration
      // assert transaction now has categoryId='cat_other_unclassified'
    });

    // ... one test per mapping row in the "用户数据迁移映射" table above

    test('categories table contains cat_pet after migration', () async { ... });
    test('categories table does not contain cat_cash_card after migration', () async { ... });
    test('category_ledger_configs has cat_pet → soul after migration', () async { ... });
    test('category_ledger_configs has L2 overrides after migration', () async { ... });
  });
}
```

**Steps:**

- [ ] **Step 1: 研究 Drift schema migration 测试模式**

阅读 Drift 官方文档的 "Testing migrations" 章节（需要 web 访问）：
```bash
flutter pub run drift_dev schema generate drift_schemas/ --help
```

如果项目已经 snapshot 了 schema 历史版本（常见是 `drift_schemas/` 或 `test/migrations/`），engineer 可以 leverage `verifySelfMigration` 辅助函数。否则要用 `NativeDatabase.memory()` + raw SQL 手动创建 v13 状态。

- [ ] **Step 2: 写完整测试文件**

按上述骨架填充所有测试。至少实现上表 13 个场景的断言。可以用 helper 函数 `seedV13Sample(db, {String categoryId})` 减少重复。

- [ ] **Step 3: 运行测试**

```bash
flutter test test/unit/data/migrations/category_v14_migration_test.dart
```

Expected: **FAIL**（migration 还没实现）。具体错误可能是 schemaVersion 不匹配，或 migration step 不存在。

- [ ] **Step 4: Commit**

```bash
git add test/unit/data/migrations/
git commit -m "test: add failing v14 migration tests for category upgrade"
```

---

## Task 14: Migration Implementation (GREEN)

**Goal:** 实现 v13 → v14 迁移。让 Task 13 的测试变绿。

**Files:**
- Modify: `lib/data/app_database.dart`（至少 bump schemaVersion，可能还要 inline migration step）
- Possibly Create: `lib/data/migrations/category_v14_migration.dart`（如果现有迁移习惯用独立文件）

**迁移步骤**（在 v14 的 `onUpgrade` 中执行，顺序很重要）:

```dart
// Step 1: Remap transactions using old category IDs to new ones
// Use batch UPDATE statements. Do this BEFORE touching categories table
// because FK constraint may prevent deleting categories with referencing
// transactions.
await customStatement('''
  UPDATE transactions SET category_id = 'cat_other_unclassified'
  WHERE category_id IN ('cat_cash_card', 'cat_uncategorized');
''');
await customStatement('''
  UPDATE transactions SET category_id = 'cat_pet_other'
  WHERE category_id = 'cat_daily_pets';
''');
await customStatement('''
  UPDATE transactions SET category_id = 'cat_allowance_self'
  WHERE category_id = 'cat_other_allowance';
''');
await customStatement('''
  UPDATE transactions SET category_id = 'cat_other_misc'
  WHERE category_id IN ('cat_other_advances', 'cat_other_business', 'cat_other_debt');
''');
await customStatement('''
  UPDATE transactions SET category_id = 'cat_food_dining_out'
  WHERE category_id IN ('cat_food_breakfast', 'cat_food_lunch', 'cat_food_dinner');
''');
// ... one statement per general → other mapping (iterate per l1)
// ... cross-category special → housing remaps

// Step 2: Delete orphaned ledger configs for removed category IDs
await customStatement('''
  DELETE FROM category_ledger_configs
  WHERE category_id IN (
    'cat_cash_card', 'cat_uncategorized', 'cat_daily_pets',
    'cat_other_allowance', 'cat_other_advances', 'cat_other_business',
    'cat_other_debt', 'cat_food_general', 'cat_food_breakfast',
    'cat_food_lunch', 'cat_food_dinner', /* ... all removed L2 general placeholders ... */
  );
''');

// Step 3: Delete removed category rows from categories table
// (system categories only — user categories untouched)
await customStatement('''
  DELETE FROM categories
  WHERE is_system = 1 AND id IN (
    'cat_cash_card', 'cat_uncategorized', /* ... all removed IDs ... */
  );
''');

// Step 4: Insert new L1 + L2 system categories
// Safest: iterate DefaultCategories.all and use INSERT OR REPLACE
// so the row layouts match the v14 seed expectation exactly.
for (final cat in DefaultCategories.all) {
  await customStatement('''
    INSERT OR REPLACE INTO categories (
      id, name, icon, color, parent_id, level, is_system, is_archived,
      sort_order, created_at, updated_at
    ) VALUES (?, ?, ?, ?, ?, ?, 1, 0, ?, ?, ?)
  ''', [
    cat.id, cat.name, cat.icon, cat.color, cat.parentId, cat.level,
    cat.sortOrder, cat.createdAt.millisecondsSinceEpoch,
    cat.createdAt.millisecondsSinceEpoch,
  ]);
}

// Step 5: Insert/upsert ledger configs (L1 + L2 overrides)
for (final cfg in DefaultCategories.defaultLedgerConfigs) {
  await customStatement('''
    INSERT OR REPLACE INTO category_ledger_configs (
      category_id, ledger_type, updated_at
    ) VALUES (?, ?, ?)
  ''', [
    cfg.categoryId, cfg.ledgerType.name,
    cfg.updatedAt.millisecondsSinceEpoch,
  ]);
}
```

注意：实际 SQL 语法与列名必须匹配项目 schema（Task 0 已确认）。`ledger_type` 的枚举字符串要和 `CategoryLedgerConfigs` 的 CHECK constraint 一致 (`'survival'` / `'soul'`)。

**Steps:**

- [ ] **Step 1: Bump schemaVersion**

```dart
@override
int get schemaVersion => 14;  // was 13
```

- [ ] **Step 2: 在 `onUpgrade` 中添加 v14 分支**

按现有 v13 的代码风格追加。完整实现上面列出的 5 个 step，使用实际的列名和正确的 schema。

- [ ] **Step 3: 运行迁移测试**

```bash
flutter test test/unit/data/migrations/category_v14_migration_test.dart
```

Expected: **PASS** ✅

- [ ] **Step 4: 跑完整测试**

```bash
flutter test
```

Expected: 全绿。

- [ ] **Step 5: 再跑 analyzer**

```bash
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 6: Commit**

```bash
git add lib/data/
git commit -m "feat(data): add v14 migration for categories upgrade"
```

---

## Task 15: Update `docs/dev/categories.md` to v2 state

**Goal:** 把 `categories.md` 更新成新 seed 的快照（保持格式不变，仅替换表内容），便于开发者 review 当前状态而非过时基线。

**Files:**
- Modify: `docs/dev/categories.md`

**Steps:**

- [ ] **Step 1: 读取新数据源**

```bash
cat docs/dev/categories_recommended.md
```

从中提取 L1 表 + 每个 L1 的 L2 表内容。

- [ ] **Step 2: 重写 categories.md**

保留原 `categories.md` 的 header 风格（`# Default Categories Reference` + Source 说明）；替换 L1 表的 19 行为 v2 的 19 行（包括 cat_pet、cat_allowance，移除 cat_cash_card、cat_uncategorized）。

移除 Income Categories L1 小节（当前 App 重点是支出）。

删除所有 L2 细节子节的 `*_general` 行、food 时段行、被 Task 9 移除的 L2 行；添加所有新增 L2 行（delivery, drugstore, shinkansen, oshikatsu, furusato, gakushi_hoken, dock, nisa, ideco, pet_*, allowance_* 等）。

新增 `### Pets (cat_pet, #7CB342)` 节（插在 Daily 之后）；新增 `### Allowance (cat_allowance, #8D6E63)` 节（插在 Special 之后）。

更新 Summary 表:
```
| Type | Count |
|------|-------|
| Expense L1 | 19 |
| Expense L2 | 138 |
| **Total** | **157** |
```

（注意：删除 Income 行）

在文件头部添加一行注释：
```
> This document reflects v14 seed state (schema version 14, after migration).
> For the research/proposal history, see `categories_recommended.md` and `categories_japan_proposal.md`.
```

- [ ] **Step 3: 快速验证**

```bash
grep -c "^| \`cat_" docs/dev/categories.md
```

Expected: `19 (L1) + 138 (L2) = 157` 个 `| \`cat_` 开头的行。

- [ ] **Step 4: Commit**

```bash
git add docs/dev/categories.md
git commit -m "docs: update categories.md to v14 state (19 L1 / 138 L2)"
```

---

## Task 16: Integration Verification

**Goal:** 全系统验证，确保所有改动协调一致。

**Steps:**

- [ ] **Step 1: 清理 build artifacts**

```bash
flutter clean
flutter pub get
```

- [ ] **Step 2: 重新生成代码**

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

Expected: 两者都成功，无错误输出。

- [ ] **Step 3: Analyzer**

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: 全量测试**

```bash
flutter test
```

Expected: 全绿。

- [ ] **Step 5: 覆盖率检查**

```bash
flutter test --coverage
```

然后查看 `coverage/lcov.info` 中 `default_categories.dart` 与 `category_v14_migration` 的覆盖率（按项目 80% 标准）。

- [ ] **Step 6: 手动 smoke test（可选，如有模拟器）**

运行 App，操作:
1. 打开 Settings → Categories（如果存在）或 记账页面类目 picker
2. 验证 `ペット`、`お小遣い` L1 可见
3. 验证 `現金・カード`、`未分類` 已不可见
4. 点开 `ペット` 验证 7 个 L2 可见
5. 点开 `資産形成` 验证 8 个 L2 可见（NISA / iDeCo 等）
6. 点开 `税・社会保障` 验证 `ふるさと納税` 可见

如果有现成的用户数据，验证 migration 后所有既有 transaction 还在，没有 orphan。

- [ ] **Step 7: 最终 commit（如有生成文件变更）**

```bash
git status
# if any generated files changed:
git add -A
git commit -m "chore: regenerate artifacts after categories v2 upgrade"
```

---

## Task 17: Worklog Entry

**Goal:** 按 `.claude/rules/worklog.md` 规范写一篇工作日志。

**Files:**
- Create: `docs/worklog/YYYYMMDD_HHMM_categories_v2_upgrade.md`（时间取 commit 完成时刻）

**Steps:**

- [ ] **Step 1: 生成文件名**

```bash
DATE=$(date +%Y%m%d_%H%M)
FILENAME="docs/worklog/${DATE}_categories_v2_upgrade.md"
echo "$FILENAME"
```

- [ ] **Step 2: 按 worklog 模板编写**

内容必须包括:

```markdown
# Categories v2 Upgrade (Japan-optimized)

**日期:** YYYY-MM-DD
**时间:** HH:MM
**任务类型:** 功能开发 + 数据迁移
**状态:** 已完成
**相关模块:** MOD-001 Basic Accounting

---

## 任务概述

基于 `docs/dev/categories_recommended.md` 研究结论，把 seed categories 从
19×103 升级到 19×138（删 2 L1 / 新增 2 L1 / 净增 35 L2），加入 Schema v14
migration 保证用户数据无损升级。

---

## 完成的工作

### 1. 主要变更
- L1 新增: cat_pet (soul), cat_allowance (soul)
- L1 删除: cat_cash_card, cat_uncategorized
- L2 净变: +35（详细见 categories_recommended.md §6 差异表）
- 新增 9 条 L2 ledger overrides
- Drift schema v13 → v14 迁移 + remap 所有旧 category ID 的用户数据
- 同步更新 ja/zh/en ARB 文件（+54 key / -17 key）
- 更新 docs/dev/categories.md 到 v14 状态

### 2. 关键文件
- `lib/shared/constants/default_categories.dart`
- `lib/data/app_database.dart`
- `lib/l10n/app_{ja,zh,en}.arb`
- `test/unit/shared/constants/default_categories_test.dart`
- `test/unit/data/migrations/category_v14_migration_test.dart`
- `docs/dev/categories.md`

### 3. 技术决策
（按实施过程中的真实选择填写）

### 4. 代码变更统计
（`git diff --stat main..HEAD` 结果）

---

## 遇到的问题与解决方案

### 问题 1: （按实际情况填写）

---

## 测试验证

- [x] 单元测试：seed 测试全绿 (N 个 test)
- [x] 集成测试：migration 测试全绿 (N 个 test)
- [x] flutter analyze: 0 issues
- [x] 覆盖率: ≥80% on touched files
- [ ] 手动 smoke test: （如执行则勾选）

---

## Git 提交记录

```bash
git log --oneline main..HEAD
```
（把上述输出粘进来）

---

## 后续工作

- [ ] UI onboarding 更新：说明 cat_pet / cat_allowance 新 L1（非本次 scope）
- [ ] 考虑实现 `categories_japan_proposal.md` §8.1 的「固定費/変動費/特別費」tag 维度
- [ ] 考虑实现 Account Transfer 原语以替代 cat_cash_card 的历史 workaround

---

## 参考资源

- Spec: `docs/dev/categories_recommended.md`
- Research: `docs/dev/categories_japan_proposal.md`
- Plan: `docs/plans/2026-04-10-categories-upgrade.md`

---

**创建时间:** YYYY-MM-DD HH:MM
**作者:** Claude Opus 4.6
```

- [ ] **Step 3: Commit worklog**

```bash
git add docs/worklog/
git commit -m "docs: add worklog for categories v2 upgrade"
```

---

## Rollback Plan

如果 production 用户反馈迁移后数据异常:

1. **v14 用户不能直接降级**—旧 category ID 已被 remap，反向丢信息
2. **紧急 fix 路径**:
   - 发布 v15 migration: 给受影响 transactions 加 "unverified" tag
   - 通知用户在 UI 中 audit 标记的 transactions
3. **预防**: Task 13 的 migration tests 必须覆盖所有 remap 场景；production 发布前在 internal build 跑 migration + 真实用户数据快照（如有）

## Risks

| Risk | Mitigation |
|------|-----------|
| 用户数据丢失 | Task 13-14 的测试断言"transaction count 不变"；remap 永远 UPDATE 不 DELETE transactions |
| UI 断点 | Task 11 故意让 analyzer 报错；Task 12 一次性修复 |
| 三语 ARB 不同步 | Task 3/4 的所有编辑都在同一 commit 同时触及 3 个文件 |
| 迁移顺序错误导致 FK 违反 | Task 14 的 5 步顺序严格：先 remap transactions → 清 orphan configs → 删旧 categories → 插新 categories → 插 ledger configs |
| 现有测试覆盖不足 | Task 2 先写 60+ 断言，覆盖 count/presence/absence/integrity/ledger overrides 五个维度 |
| 迁移代码与 v13 风格不一致 | Task 0 Step 3 明确要求 engineer 先阅读 v13 代码做风格对齐 |

## Out of Scope

本计划**不包含**的工作（后续独立规划）:

- 类目 onboarding / release notes 文案更新
- UI/UX 为 cat_pet、cat_allowance 设计专属卡片或引导
- 实现「固定費/変動費/特別費」作为 Transaction tag 正交维度（见 `categories_japan_proposal.md` §8.1）
- 实现 Account Transfer 原语以替代 cat_cash_card 的历史定位（见 §7）
- 实现 Loan/Liability 原语以承载 cat_other_debt 的语义（见 §7）
- 把 business_expense 独立为 Book（见 §7）
- 修改用户自定义 (isSystem=false) 类目（本计划只动 system seeds）
- 修改收入类目（本计划仅支出，收入等 v3）
- 整理 category picker 的搜索/筛选 UX

---

**Plan complete.** Executor is expected to be an engineer新 to this codebase but comfortable with Flutter/Drift/TDD. Each task should take 10–30 minutes for a careful engineer (Task 13-14 migration is the longest).
