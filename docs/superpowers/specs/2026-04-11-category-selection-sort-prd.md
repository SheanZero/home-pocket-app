# Category Selection Reorder — PRD

**Feature ID**: FEAT-CAT-SORT-001
**Status**: Draft (v2 — simplified scope)
**Created**: 2026-04-11
**Last updated**: 2026-04-11
**Target Branch**: `feature/categories-v2-upgrade`
**Related docs**:
- `docs/plans/2026-04-10-categories-upgrade.md` — categories v2 taxonomy upgrade
- `docs/dev/categories_recommended.md` — seed taxonomy source-of-truth
- `lib/features/accounting/presentation/screens/category_selection_screen.dart` — UI 基线
- `docs/superpowers/specs/2026-04-11-category-selection-sort.pen` — UI 设计稿（Pencil）

> **Scope note (v2)**：本 PRD v1 曾设计"默认 / 自定义"双模式切换 + 重置回路。
> v2 简化为：**seed 顺序仅用于首次初始化；用户任何一次拖拽后的结果始终保留**，不存在模式切换，也不提供重置到默认的回路。
> 实现上直接复用 `Category.sortOrder` 列，无需新增 enum、DAO、Drift 表或 schema 迁移。

---

## 1. 背景 (Context)

### 1.1 问题陈述

当前分类选择页（`CategorySelectionScreen`）对所有用户展示同一套固定顺序：

- L1 按 seed 中手工维护的 `sortOrder`（1–19）排列；
- L2 按父 L1 下的相对 `sortOrder`（1–10）排列；
- 用户没有任何方式影响这套顺序。

对日本家庭记账场景来说，每位用户的高频分类高度个人化：
- 有人每天三餐记"外食" / "便利店"，希望它们第一屏直达；
- 有人以灵魂帐本为主，希望 `cat_hobbies` / `cat_allowance` / `cat_asset` 置顶；
- 随着 categories v2 把 L2 从 103 扩展到 138，发现成本显著上升。

### 1.2 机会

- `Category` 表已经有 `sortOrder: int` 列；所有 DAO 查询已按 `sortOrder ASC`。
- `CategoryRepository.update()` 已支持写 `sortOrder` 字段。
- `ReorderableListView` 是 Flutter SDK 内置组件，无需新依赖。
- 唯一缺失的是一个用户可控的编辑态 UI。

### 1.3 与 categories v2 的关系

Categories v2 upgrade（`feature/categories-v2-upgrade`）正在升级 seed 到 19 × 138。本 PRD 假设 v2 seed 已经作为新基线。Seed 在每次 App 首次安装 / 首次 v14 migration 时写入 `Category.sortOrder` 的初始值；之后用户一旦拖拽重排，就直接覆盖这些列的值，seed 不再回来。

---

## 2. 目标与非目标 (Goals & Non-Goals)

### 2.1 目标

| ID | 目标 |
|----|------|
| G1 | 用户可以通过拖拽手势对 L1、以及同一 parent 下的 L2 进行重排。 |
| G2 | 用户的自定义顺序跨会话持久化（下次打开 App 仍生效）。 |
| G3 | 三语（ja / zh / en）完整本地化，无硬编码字符串。 |
| G4 | 阅读态（不进入编辑态）下，本 feature 对既有用户行为零回归。 |

### 2.2 非目标（本版本不做）

- **无排序模式切换**：不提供"默认顺序 / 自定义顺序"二选一的 picker。
- **无重置到默认的回路**：seed 顺序只在首次安装时使用一次；一旦用户编辑，用户的结果就是唯一真实来源。
- 多维度排序（字母 / 频率 / 最近使用 / 金额）
- 分类的隐藏 / 显示开关（`isArchived` 已存在，范畴不同）
- 跨帐本（生存 vs 灵魂）的重新分组
- 批量选择 / 批量排序 / 批量归档
- 搜索结果内的独立重排
- 服务端同步（App 是本地优先零知识架构）

---

## 3. 用户场景 (User Scenarios)

### S1 日常用户的个性化排序

玲子每次记账都选"外食"或"便利店"，它们默认分别在食品 L2 第 2 位与日常 L2 第 3 位。
她进入分类选择页 → AppBar 右上"≡"重排按钮 → 直接进入编辑态 → 拖拽把两项拖到所在 L1 组内顶部 → 保存。
下次她打开记账页，这两项已经在最前面。

### S2 灵魂帐本重度用户

健太 80% 的支出都进入灵魂帐本。他希望把 `cat_hobbies`、`cat_allowance`、`cat_asset` 等 L1 置顶。
进入分类选择页 → ≡ → 编辑态 → 拖拽 L1 → 保存。

### S3 App 升级后出现新 seed 分类

下一个版本 seed 新增 `cat_pet_insurance`（系统 L2），带 seed 提供的 sortOrder。
玲子之前已经拖拽过 pet 类别下的其它 L2。
v14 / 后续 migration 在 `INSERT OR IGNORE` 模式下写入新分类：已经被用户动过的行不覆盖，新 ID 以 seed 值首次落盘。
新分类以 seed 默认位置出现在组内（不保证恰好相邻用户已自定义的位置，但会按数值大小穿插进现有序列中，让玲子仍能发现它）。

### S4 清空重装

用户卸载并重装 App（或清除 App 数据）→ 所有数据被清除 → 下次启动按 seed 重新初始化。这是"回到默认"的唯一路径，本 PRD 不再提供应用内的重置按钮。

---

## 4. 功能需求 (Functional Requirements)

### FR-1 编辑态入口

- 分类选择页 AppBar 右上角新增 `Icons.reorder` 图标按钮（位于 "+" 添加按钮左侧）。
- 点击后 **直接进入编辑态**（不经过中间菜单）。
- 不支持 long-press 进入（避免与未来可能的上下文菜单冲突）。

### FR-2 编辑态 UI 与拖拽排序

#### 编辑态 UI 变化

| 元素 | 阅读态 | 编辑态 |
|------|-------|--------|
| AppBar 标题 | "カテゴリ選択" | "順序を編集" |
| AppBar 左按钮 | ✕ (关闭页面) | ✕ (取消编辑) |
| AppBar 右按钮 | ≡ 重排 + ＋ 加号 | **保存** 文字按钮 |
| 搜索框 | 显示 | 隐藏 |
| "添加分类" 底部入口 | 显示 | 隐藏 |
| L1 条目 | Card + chevron | Card + `Icons.drag_indicator` 手柄 |
| L2 区域（展开时） | `Wrap` chip 布局 | 垂直列表 + 每项 drag handle |
| 编辑态顶部 hint | — | "ドラッグして並べ替え" 指引 bar |

#### L1 重排
- L1 列表使用 `ReorderableListView.builder`。
- 用户按手柄或长按条目拖动至目标位置；拖动中条目高亮、浮起、周围条目让位。
- L1 总数约 19 条，一屏基本可见。

#### L2 重排
- 点击某 L1 条目可展开查看其 L2 子项；展开态下 L2 以垂直列表呈现（而非阅读态的 chip Wrap），便于拖拽。
- L2 同样支持 `ReorderableListView` 重排。
- **L2 只能在同一父 L1 内重排**；禁止跨 L1 拖拽。
- 同一时间只允许一个 L1 处于"展开编辑"态。

#### 保存 / 取消
- **保存**：把内存中的顺序一次性 upsert 到 `Category.sortOrder` → 退出编辑态 → 页面按新顺序重新渲染 → 顶部 SnackBar "顺序已更新"。
- **取消**：若有未保存改动，弹出 confirm dialog "未保存の変更を破棄しますか？"；无改动则直接退出。
- **返回键**（Android 物理返回 / iOS 滑动返回）等价于取消按钮。

#### 触觉反馈
- 拖拽开始：`HapticFeedback.selectionClick()`
- 拖拽放下：`HapticFeedback.mediumImpact()`
- 保存成功：`HapticFeedback.lightImpact()`

### FR-3 持久化

- **唯一持久化字段**：`Category.sortOrder`（Drift `categories` 表现有的 `INTEGER` 列）。
- Seed 在首次 v14 migration 时写入初始值；此后 `CategoryRepository.update(id, sortOrder: ...)` 直接覆盖。
- **无新 enum**、**无新 SharedPreferences key**、**无新 DAO**、**无新 Drift 表**、**无新 schema migration**。
- App 启动时 `CategoryDao.findActive()` 已经 `ORDER BY sortOrder ASC`，无需新查询。

### FR-4 排序作用域

| 维度 | 行为 |
|------|------|
| L1 | 影响全部 19 条 L1 在顶层列表的顺序 |
| L2 | 每个 parent L1 内独立维护，L2 之间不跨父排序 |
| 系统分类 (`isSystem = true`) | 允许重排 |
| 用户自建分类 (`isSystem = false`) | 允许重排，与系统分类一同参与 |
| 归档分类 (`isArchived = true`) | 不参与编辑 UI |
| 不同 ledger type（生存 / 灵魂） | 不受影响；本页面同时展示两种 ledger，排序作用于整体 |

### FR-5 与现有功能的交互

| 功能 | 交互 |
|------|------|
| 搜索 | 阅读态搜索不受影响；编辑态下隐藏搜索框。 |
| 预选中高亮 | `selectedCategoryId` 对应的 L1 仍自动展开。 |
| 添加新分类 | 新分类插入所属 L1 组末尾（`sortOrder = max + 1`）。 |
| Categories v2 schema 迁移 (v13→v14) | v14 migration 按 `INSERT OR IGNORE` / upsert 语义写入 seed：用户已自定义过的行不被覆盖；全新分类以 seed 值落盘。无需单独 remap 用户顺序。 |
| 归档分类 | 归档不改变 sortOrder；取消归档时顺序仍在。 |
| 删除分类 | 直接从表删除，其它行 sortOrder 保持稀疏即可（顺序比较不受影响）。 |

### FR-6 可访问性与反馈

- 所有新按钮提供可读 `semanticsLabel`（屏幕阅读器友好）。
- 拖拽手柄具有 `tooltip`："拖拽重排" / "ドラッグして並べ替え" / "Drag to reorder"。
- 保存成功后显示 SnackBar："顺序已更新" / "順序を更新しました" / "Order updated"。
- 编辑态错误写入显示红色 SnackBar："保存失败，请重试"。

---

## 5. 非功能需求 (Non-Functional)

### NFR-1 性能
- 分类规模约 19 L1 + 138 L2 = 157 条，单次应用排序应 < 16ms 以保持 60 FPS。
- 拖拽过程中不触发数据库写入；保存时一次性在单个事务内批量 update。

### NFR-2 可靠性
- 保存写入必须是原子事务。
- 写入失败时 UI 不回退内存状态，保留用户编辑 + 红色 SnackBar + 允许重试。
- 编辑态下 App 被杀死：未保存改动丢失，重启后回到最后一次保存的顺序（即 `Category.sortOrder` 当前值）。

### NFR-3 i18n
- 所有 UI 文案走 ARB（`S.of(context)`）。
- 三语（ja 默认 / zh / en）全部覆盖；新增 key 见 §7.5。

### NFR-4 安全与隐私
- `Category.sortOrder` 位于 SQLCipher 加密的 categories 表内，与其它字段同级别。
- 不涉及任何网络请求。

### NFR-5 测试
- 单元测试 ≥ 80% 覆盖率：
  - `CategoryRepository.update(sortOrder)` 的批量写入
  - 排序应用逻辑（拖拽后 List<Category> 的顺序等价于 `sortOrder ASC`）
- Widget 测试：
  - 编辑态进入 / 退出 / 保存 / 取消（含 unsaved changes dialog）
  - L1 / L2 拖拽重排（mock drag events）
  - 跨 L1 拖 L2 被拒绝
- 三语快照测试：AppBar 标题、hint banner、discard dialog、SnackBar。

---

## 6. UX 设计 (UX Design)

> 完整高保真设计见 `docs/superpowers/specs/2026-04-11-category-selection-sort.pen`（Pencil 文件，4 屏）。

### 6.1 AppBar（阅读态）

```
┌──────────────────────────────────────┐
│  ✕     カテゴリ選択      ≡    ＋  │  ← ≡: 点击直接进入编辑态
├──────────────────────────────────────┤
│  🔍 カテゴリを検索                   │
├──────────────────────────────────────┤
│  🍽️  食費                        ▶   │
│  🛒  日用品                      ▶   │
│  🐾  ペット                      ▶   │
│  🚆  交通                        ▶   │
│  ...                                │
└──────────────────────────────────────┘
```

### 6.2 编辑态（L1 reorder）

```
┌──────────────────────────────────────┐
│  ✕        順序を編集         保存  │
├──────────────────────────────────────┤
│  ≡ ドラッグして並べ替え · L1 / L2 対応 │  ← hint bar
├──────────────────────────────────────┤
│  ≡  🍽️  食費                        │  ← 橘色高亮 = 拖拽中
│  ≡  🛒  日用品                      │
│  ≡  🐾  ペット                      │
│  ≡  🚆  交通                        │
│  ≡  🎨  趣味                        │
│  ≡  👕  衣服                        │
│  ≡  👥  交際                        │
│  ...                                │
└──────────────────────────────────────┘
```

### 6.3 编辑态（L2 expanded）

```
┌──────────────────────────────────────┐
│  ✕        順序を編集         保存  │
├──────────────────────────────────────┤
│  ≡ ドラッグして並べ替え · L1 / L2 対応 │
├──────────────────────────────────────┤
│  ≡  🍽️  食費                    ▼   │  ← 橘色边框 = 展开编辑
│     ┌────────────────────────────┐   │
│     │ ≡  スーパー買い物       #1  │   │
│     │ ≡  外食                 #2  │   │
│     │ ≡  カフェ               #3  │   │
│     │ ≡  お弁当・惣菜         #4  │   │
│     │ ≡  デリバリー           #5  │   │
│     │ ≡  その他               #6  │   │
│     └────────────────────────────┘   │
│  ≡  🛒  日用品                  ▶   │
│  ≡  🐾  ペット                  ▶   │
└──────────────────────────────────────┘
```

### 6.4 未保存确认 Dialog

```
┌──────────────────────────────────────┐
│  ……（scrim 遮罩）                    │
│                                      │
│         ┌──────────────────┐         │
│         │        ⚠         │         │
│         │                  │         │
│         │  未保存の変更を   │         │
│         │   破棄しますか？   │         │
│         │                  │         │
│         │  編集した並び順は  │         │
│         │   失われます。    │         │
│         │                  │         │
│         │ [編集続行][破棄]  │         │
│         └──────────────────┘         │
│                                      │
└──────────────────────────────────────┘
```

### 6.5 组件复用

| 需求 | 复用 |
|------|------|
| Dialog | Material `AlertDialog` |
| 图标 | `Icons.reorder`（入口）· `Icons.drag_indicator`（手柄）· `Icons.warning`（dialog） |
| 文本样式 | `AppTextStyles.titleMedium`（label）、`AppTextStyles.bodyMedium`（次要） |
| 颜色 | `AppColors` / `AppColorsDark`，尊重 dark mode |

---

## 7. 技术方案草案 (Technical Approach)

> 由于 v2 范围裁剪，技术变更极小，可直接在 `CategorySelectionScreen` 内实施，不需要新表 / 新 DAO / 新 enum。

### 7.1 数据模型变更

**无**。直接复用：

- `lib/data/tables/categories_table.dart` 现有的 `sortOrder: int` 列
- `lib/data/daos/category_dao.dart` 现有的 `update()` 方法
- `lib/data/repositories/category_repository_impl.dart` 现有的 `update()` 实现

`Category.sortOrder` 本身是"当前真实顺序"的唯一来源：
- 首次 v14 migration 用 seed 值初始化
- 用户 drag-reorder 保存时直接覆盖

### 7.2 批量保存逻辑

新增 `CategoryRepository.updateSortOrders(Map<String, int> idToOrder)`，在单个 Drift 事务内批量更新：

```dart
// lib/features/accounting/domain/repositories/category_repository.dart
Future<void> updateSortOrders(Map<String, int> idToSortOrder);

// lib/data/repositories/category_repository_impl.dart
@override
Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {
  await _dao.db.transaction(() async {
    for (final entry in idToSortOrder.entries) {
      await _dao.updateSortOrder(entry.key, entry.value);
    }
  });
}

// lib/data/daos/category_dao.dart
Future<void> updateSortOrder(String id, int sortOrder) {
  return (update(categories)..where((c) => c.id.equals(id)))
      .write(CategoriesCompanion(
        sortOrder: Value(sortOrder),
        updatedAt: Value(DateTime.now()),
      ));
}
```

### 7.3 排序应用逻辑

**无变化**。`CategoryDao.findActive()` 已经 `ORDER BY sortOrder ASC`，返回的列表直接用于展示。

### 7.4 Riverpod Provider

仅新增一个 editor 状态 provider：

```dart
// lib/features/accounting/presentation/providers/category_reorder_notifier.dart
@riverpod
class CategoryReorderNotifier extends _$CategoryReorderNotifier {
  @override
  CategoryReorderState build() => const CategoryReorderState.idle();

  void enterEditMode(List<Category> l1, Map<String, List<Category>> l2ByParent) {
    state = CategoryReorderState.editing(
      l1: l1,
      l2ByParent: l2ByParent,
      isDirty: false,
    );
  }

  void reorderL1(int oldIdx, int newIdx) { /* in-memory */ }
  void reorderL2(String parentId, int oldIdx, int newIdx) { /* in-memory */ }

  Future<void> save() async {
    final map = <String, int>{};
    // L1 indices
    state.l1.asMap().forEach((i, cat) => map[cat.id] = i);
    // L2 indices (per parent namespace)
    state.l2ByParent.forEach((_, children) {
      children.asMap().forEach((i, cat) => map[cat.id] = i);
    });
    await ref.read(categoryRepositoryProvider).updateSortOrders(map);
    state = const CategoryReorderState.idle();
  }

  void cancel() {
    state = const CategoryReorderState.idle();
  }
}
```

### 7.5 文件变更清单

| 文件 | 操作 |
|------|------|
| `lib/data/daos/category_dao.dart` | **+ `updateSortOrder(id, int)`** 单条 helper |
| `lib/features/accounting/domain/repositories/category_repository.dart` | **+ `updateSortOrders(Map)`** 接口 |
| `lib/data/repositories/category_repository_impl.dart` | 实现 `updateSortOrders` 事务 |
| `lib/features/accounting/presentation/providers/category_reorder_notifier.dart` | **新建** 编辑态 state notifier |
| `lib/features/accounting/presentation/screens/category_selection_screen.dart` | **改造**：AppBar reorder 按钮 + 编辑态分支（`ReorderableListView` 替换 `ListView`）|
| `lib/features/accounting/presentation/widgets/category_reorder_row.dart` | **新建** 编辑态行组件（drag handle + icon + label）|
| `lib/l10n/app_ja.arb` / `app_zh.arb` / `app_en.arb` | **+5 keys**（见 §7.6）|
| `test/unit/data/daos/category_dao_sort_order_test.dart` | **新建** |
| `test/unit/features/accounting/presentation/providers/category_reorder_notifier_test.dart` | **新建** |
| `test/widget/features/accounting/category_selection_screen_reorder_test.dart` | **新建** |
| `docs/arch/02-module-specs/MOD-XXX_CategoryReorder.md` | 可选（功能体量不大，实施 plan 内说明即可）|

**无 schema migration**、**无新 Drift 表**、**无 `SettingsRepository` 改动**、**无新 enum**。

### 7.6 新增 i18n Keys

| Key | ja | zh | en |
|-----|----|----|----|
| `editCategoryOrder` | 順序を編集 | 编辑分类顺序 | Edit category order |
| `dragToReorder` | ドラッグして並べ替え | 拖拽重排 | Drag to reorder |
| `orderUpdated` | 順序を更新しました | 顺序已更新 | Order updated |
| `discardUnsavedChanges` | 未保存の変更を破棄しますか？ | 放弃未保存的修改？ | Discard unsaved changes? |
| `keepEditing` | 編集を続ける | 继续编辑 | Keep editing |
| `discard` | 破棄 | 放弃 | Discard |

（`save`、`cancel`、`sort` 等若已有则复用。）

---

## 8. 边界情况 (Edge Cases)

| 场景 | 处理 |
|------|------|
| 编辑态下用户切换 tab / 按 home 键 | 未保存改动保留在 Riverpod 内存 state；回到页面继续。App 被 kill 则丢失。 |
| 保存写入失败 | 保留编辑态、红色 SnackBar "保存失败，请重试"；不清空内存改动。 |
| 编辑态下用户新建 / 归档 / 删除分类 | 编辑态禁用这些入口；避免交叉状态。 |
| v14 migration 期间 | `INSERT OR IGNORE` 写入 seed：已有 ID 的 sortOrder 不被覆盖；新 ID 以 seed 值落盘。 |
| 搜索态下点击编辑按钮 | 先清空 search query 再进入编辑态。 |
| L1 下只有 1 个 L2 | L2 垂直列表仍显示 drag handle，但拖动无效果（单元素列表）。 |
| 拖拽目标超出可视区 | `ReorderableListView` 自带自动滚动。 |
| 跨 L1 拖拽 L2 | 两个 L1 的 L2 列表是独立的 `ReorderableListView`，hit test 不会越界。 |
| 连续快速 tap "保存" | 第一次 tap 后立即 disable 按钮直到写入完成。 |
| 清空重装 App | Drift 数据全量清除；下次启动 seed 重新初始化。这是"回到默认"的唯一路径。 |

---

## 9. 验收标准 (Acceptance Criteria)

- [ ] **AC-1** 分类选择页 AppBar 右上角显示 `Icons.reorder` 按钮；tap **直接进入编辑态**（不弹中间菜单）。
- [ ] **AC-2** 编辑态下 AppBar 标题变为"順序を編集"，右上角显示"保存"按钮，左上角显示 ✕ 取消按钮；搜索框与"添加分类"入口隐藏。
- [ ] **AC-3** 编辑态顶部显示 hint banner "ドラッグして並べ替え"。
- [ ] **AC-4** L1 列表可通过拖拽手柄重排；拖拽时有触觉反馈。
- [ ] **AC-5** L2 可在同一父 L1 内重排；无法跨 L1。
- [ ] **AC-6** tap 保存后 `Category.sortOrder` 在单个事务内批量更新；退出编辑态，SnackBar "顺序已更新"。
- [ ] **AC-7** tap ✕ 或返回键时，若有未保存改动弹确认 dialog；确认后丢弃改动并退出。
- [ ] **AC-8** 关闭并重启 App，用户自定义顺序保持一致（由 `sortOrder` 字段持久化）。
- [ ] **AC-9** 三语（ja / zh / en）下所有 UI 文案正确显示，无英文 fallback、无 hardcoded 字符串。
- [ ] **AC-10** 阅读态下对分类的 long-press 不进入编辑态；与 v2 seed 落地后的当前行为完全一致（零回归）。
- [ ] **AC-11** Categories v2 v14 migration 完成后，seed 的新增 L1/L2 有 sortOrder 初值；用户已动过的分类不被覆盖。
- [ ] **AC-12** `flutter analyze` 零问题；单元 + widget 测试覆盖率 ≥ 80%。
- [ ] **AC-13** Dark mode 下所有新 UI 元素（编辑态、dialog）颜色正确。

---

## 10. 成功指标 (Success Metrics)

本地优先零知识架构，无 telemetry。以下为定性指标：

| ID | 指标 |
|----|------|
| M1 | **可发现性**：内测 5 名用户在无引导情况下，≥ 3 人能自主发现 `≡` 入口并完成一次重排。 |
| M2 | **无回归**：v2 seed + 阅读态下，既有分类选择流程（搜索、展开、选择、新建）的端到端行为不变。 |
| M3 | **稳定性**：内测期间编辑态 → 保存 / 取消 全流程无 crash。 |
| M4 | **性能**：拖拽流畅度 60 FPS 稳定（Flutter DevTools profile mode 验证）。 |

---

## 11. 依赖与约束 (Dependencies & Constraints)

### 11.1 依赖

- Categories v2 upgrade 已完成（`feature/categories-v2-upgrade` 合入 main）。
- Flutter SDK 内置 `ReorderableListView`（无需新 package）。
- Drift / SQLCipher（现状）。

### 11.2 约束（项目规则）

- 遵守 Clean Architecture 5 层：sort 的 DAO / Repo 实现放 `lib/data/`，feature 层只做 presentation（Thin Feature rule）。
- 所有 UI 文案走 `S.of(context)` + ARB 三语同步，不允许硬编码字符串。
- `flutter analyze` 必须 0 问题。
- 不可修改 `.g.dart` / `.freezed.dart` 生成文件；模型 / DAO 改完后运行 `flutter pub run build_runner build --delete-conflicting-outputs`。
- 必须使用 `sqlcipher_flutter_libs`（禁止 `sqlite3_flutter_libs`）。

---

## 12. 开放问题 (Open Questions) — Design Review 需讨论

| # | 问题 | 暂定方案 |
|---|------|---------|
| Q1 | L2 在编辑态是否一定要切成垂直列表？能否用 `ReorderableWrap` 保留 chip 视觉？ | **暂定 垂直列表**；Material SDK 原生支持更稳定，chip 拖拽交互可读性差。 |
| Q2 | 入口图标 `Icons.reorder` vs `Icons.sort` vs `Icons.swap_vert` vs `Icons.edit`？ | **暂定 `reorder`**（三横线带拖拽暗示），视觉上最贴合"重排"语义。 |
| Q3 | 是否需要对 L1 "批量折叠" 以快速重排？ | **不需要**，L1 共 19 条，一屏可见。 |
| Q4 | 本 feature 是否需要 feature flag 隐藏？ | **不需要**。功能独立、有明确 discard 回路。 |
| Q5 | 是否要在 App 设置页提供"重置分类顺序到出厂默认"？ | **不提供**（按本次用户决策）。清空重装是唯一路径。若未来用户反馈强烈可再加。 |

---

## 13. 分期发布 (Phased Rollout)

体量小，一次 PR 合入。步骤：

1. **P1 数据层**：`CategoryDao.updateSortOrder` + `CategoryRepository.updateSortOrders` + 单测
2. **P2 应用层**：`CategoryReorderNotifier` + 单测
3. **P3 UI**：`category_selection_screen.dart` 改造（AppBar reorder 按钮 + 编辑态 `ReorderableListView` 分支）+ `category_reorder_row.dart`
4. **P4 i18n**：ARB 三语同步 + `flutter gen-l10n`
5. **P5 测试**：Widget 测试 + 三语快照
6. **P6 文档**：worklog

每一步独立可 review，符合项目 TDD 工作流与 `.claude/rules/development-workflow.md`。

---

## 14. 参考 (References)

- `lib/features/accounting/presentation/screens/category_selection_screen.dart:43-86` — 当前 `_loadCategories` + L1/L2 sort
- `lib/features/accounting/domain/models/category.dart` — Category 模型（含 `sortOrder`）
- `lib/data/daos/category_dao.dart:108-128` — DAO 查询已按 sortOrder ASC
- `lib/data/repositories/category_repository_impl.dart` — Repo 实现（`update()` 已存在）
- `lib/features/accounting/presentation/widgets/ledger_type_selector.dart` — chip 选择器风格参考
- `lib/core/theme/app_text_styles.dart` / `app_colors.dart` — 样式 token
- `docs/plans/2026-04-10-categories-upgrade.md` — categories v2 升级
- `docs/dev/categories_recommended.md` — taxonomy 源
- `docs/superpowers/specs/2026-04-11-category-selection-sort.pen` — Pencil 高保真设计（4 屏）
- Material `ReorderableListView` — Flutter SDK 官方文档

---

## 15. Changelog

| 版本 | 日期 | 变更 |
|------|------|------|
| v1 | 2026-04-11 | 初稿：双模式（default / custom）+ 重置回路 + 新 Drift 表 + CategorySortMode enum |
| **v2** | **2026-04-11** | **简化范围**：去掉模式切换、去掉重置回路、去掉新 enum、去掉新 Drift 表。直接复用 `Category.sortOrder`，编辑态一次性批量覆盖。Pencil 设计同步缩至 4 屏。 |

---

**状态**: Draft (v2)
**下一步**: 设计评审 → 实施 plan（`docs/plans/2026-04-11-category-reorder.md`）→ TDD 实施
