# MOD-006 Analytics Implementation Plan

## Overview

Implement the Analytics & Reports module (MOD-007 spec in `docs/arch/02-module-specs/MOD-006_Analytics.md`) following Clean Architecture. The module provides monthly financial reports, category breakdowns, expense trends, budget tracking, and month-over-month comparison — all displayed with demo data to showcase full functionality.

**Goal:** Build a complete, working analytics feature with demo data support so all charts and statistics are visible even without real transactions.

---

## Current State Assessment

### What Exists
- **Transaction data layer**: tables, DAOs, repository (with date range filtering)
- **Category data layer**: tables, DAOs, repository (hierarchical, 3-level)
- **Book data layer**: tables with denormalized balances (survivalBalance, soulBalance)
- **Domain models**: Transaction, Category, Book (all Freezed)
- **Use Cases**: CreateTransaction, GetTransactions, DeleteTransaction
- **Dual Ledger**: Classification service + Rule engine
- **Navigation**: Simple MaterialApp with DualLedgerScreen as home

### What's Missing
- `fl_chart` dependency
- Analytics domain models (MonthlyReport, BudgetProgress, etc.)
- Analytics use cases (GetMonthlyReport, GetBudgetProgress)
- Analytics repository interface + aggregate queries in DAO
- Analytics UI screens and chart widgets
- Navigation to analytics (no routing exists yet)
- Budget amount field on Category model (MOD-007 references `budgetAmount`)
- i18n strings for analytics labels

---

## Architecture Decisions

### File Placement (per "Thin Feature" pattern)

```
lib/
├── application/analytics/                    # Use Cases (global)
│   ├── get_monthly_report_use_case.dart
│   ├── get_budget_progress_use_case.dart
│   └── get_expense_trend_use_case.dart
│
├── features/analytics/                       # Feature module (thin)
│   ├── domain/
│   │   └── models/
│   │       ├── monthly_report.dart           # MonthlyReport + CategoryBreakdown
│   │       ├── daily_expense.dart            # DailyExpense
│   │       ├── month_comparison.dart         # MonthComparison
│   │       ├── budget_progress.dart          # BudgetProgress + BudgetStatus
│   │       └── expense_trend.dart            # MonthlyTrend (multi-month)
│   └── presentation/
│       ├── screens/
│       │   └── analytics_screen.dart         # Main analytics page (tabs/sections)
│       ├── widgets/
│       │   ├── summary_cards.dart            # Income/Expense/Savings/Rate cards
│       │   ├── category_pie_chart.dart       # Pie chart of category breakdown
│       │   ├── daily_expense_chart.dart      # Bar chart of daily spending
│       │   ├── expense_trend_chart.dart      # Line chart multi-month trends
│       │   ├── budget_progress_list.dart     # Budget progress bars
│       │   ├── category_breakdown_list.dart  # Category details list
│       │   ├── month_comparison_card.dart    # Month-over-month comparison
│       │   └── ledger_ratio_chart.dart       # Survival vs Soul pie chart
│       └── providers/
│           ├── repository_providers.dart      # Repository provider (single source)
│           └── analytics_providers.dart       # Use case + data providers
│
├── data/
│   └── daos/
│       └── analytics_dao.dart                # Aggregate SQL queries (SUM, GROUP BY)
```

### Navigation Strategy

Add a **BottomNavigationBar** to main app with 3 tabs:
1. **Home** (DualLedgerScreen) — existing
2. **Analytics** (AnalyticsScreen) — new
3. **Settings** (placeholder) — future

This gives analytics a natural entry point without requiring GoRouter yet.

### Demo Data Strategy

Create a `DemoDataService` that generates realistic sample data covering:
- 3 months of transactions across multiple categories
- Both survival and soul ledger types
- Varying daily amounts to show trends
- Categories with budgets (some exceeded, some safe)

This ensures all charts render with meaningful data for demo purposes.

---

## Implementation Phases

### Phase 1: Dependencies & Data Layer Foundation (Day 1)

**Step 1.1: Add fl_chart dependency**
- Add `fl_chart: ^0.69.0` to pubspec.yaml
- Run `flutter pub get`

**Step 1.2: Add budget support to Category**
- Add `budgetAmount` (nullable int) column to `categories_table.dart`
- Update `CategoryRow` → Category mapping in `category_repository_impl.dart`
- Add `budgetAmount` field to Category domain model
- Update `CategoryDao` with `findWithBudget()` method
- Update `CategoryRepository` interface with `findWithBudget()`
- Run build_runner to regenerate

**Step 1.3: Create AnalyticsDao**
- File: `lib/data/daos/analytics_dao.dart`
- SQL aggregate queries:
  - `getMonthlyTotals(bookId, year, month)` → SUM income/expenses
  - `getCategoryTotals(bookId, startDate, endDate)` → GROUP BY categoryId
  - `getDailyTotals(bookId, year, month)` → GROUP BY day
  - `getLedgerTotals(bookId, startDate, endDate)` → GROUP BY ledgerType
- All use database-level aggregation for performance (<2s target)

**Step 1.4: Update AppDatabase**
- Register AnalyticsDao in `app_database.dart`

### Phase 2: Domain Models (Day 2)

**Step 2.1: Create analytics domain models**
All models use `@freezed` for immutability.

- `monthly_report.dart`:
  ```dart
  @freezed class MonthlyReport — year, month, totalIncome, totalExpenses,
    savings, savingsRate, categoryBreakdowns, dailyExpenses,
    previousMonthComparison, survivalTotal, soulTotal
  ```

- `daily_expense.dart`:
  ```dart
  @freezed class DailyExpense — date, amount
  ```

- `month_comparison.dart`:
  ```dart
  @freezed class MonthComparison — previousMonth, previousYear,
    previousIncome, previousExpenses, incomeChange, expenseChange
  ```

- `budget_progress.dart`:
  ```dart
  enum BudgetStatus { safe, warning, exceeded }
  @freezed class BudgetProgress — categoryId, categoryName, icon, color,
    budgetAmount, spentAmount, percentage, status, remainingAmount
  ```

- `expense_trend.dart`:
  ```dart
  @freezed class MonthlyTrend — year, month, totalExpenses, totalIncome
  @freezed class ExpenseTrendData — months (List<MonthlyTrend>)
  ```

**Step 2.2: Run build_runner**

### Phase 3: Application Layer — Use Cases (Day 3)

**Step 3.1: GetMonthlyReportUseCase**
- File: `lib/application/analytics/get_monthly_report_use_case.dart`
- Inputs: bookId, year, month
- Logic:
  1. Query monthly totals via AnalyticsDao
  2. Calculate category breakdowns (with percentages)
  3. Calculate daily expenses for bar chart
  4. Get previous month data for comparison
  5. Calculate survival vs soul split
- Output: `MonthlyReport`

**Step 3.2: GetBudgetProgressUseCase**
- File: `lib/application/analytics/get_budget_progress_use_case.dart`
- Inputs: bookId, year, month
- Logic:
  1. Get categories with budgets
  2. Get spending per category for the month
  3. Calculate percentage and status
- Output: `List<BudgetProgress>`

**Step 3.3: GetExpenseTrendUseCase**
- File: `lib/application/analytics/get_expense_trend_use_case.dart`
- Inputs: bookId, monthCount (default 6)
- Logic: Query totals for last N months
- Output: `ExpenseTrendData`

### Phase 4: Presentation Layer — Providers (Day 4)

**Step 4.1: Repository providers**
- File: `lib/features/analytics/presentation/providers/repository_providers.dart`
- Provide AnalyticsDao instance

**Step 4.2: Analytics providers**
- File: `lib/features/analytics/presentation/providers/analytics_providers.dart`
- Providers:
  - `selectedMonthProvider` — StateProvider<DateTime> for month picker
  - `monthlyReportProvider` — FutureProvider watching selectedMonth
  - `budgetProgressProvider` — FutureProvider watching selectedMonth
  - `expenseTrendProvider` — FutureProvider for 6-month trend

**Step 4.3: Run build_runner**

### Phase 5: Presentation Layer — Widgets (Day 5-6)

**Step 5.1: SummaryCards widget**
- 4 cards in 2x2 grid: Income, Expenses, Savings, Savings Rate
- Use NumberFormatter for currency formatting
- Color-coded: green (income), red (expenses), blue/orange (savings), blue (rate)

**Step 5.2: CategoryPieChart widget**
- fl_chart PieChart showing top 5-7 categories
- Color-coded sections with legends
- Touch interaction to show details
- Empty state when no data

**Step 5.3: DailyExpenseChart widget**
- fl_chart BarChart showing daily spending across the month
- X-axis: days (1-28/30/31)
- Y-axis: amount
- Highlight today's bar

**Step 5.4: ExpenseTrendChart widget**
- fl_chart LineChart showing 6-month expense trend
- Two lines: expenses and income
- X-axis: months, Y-axis: amount

**Step 5.5: BudgetProgressList widget**
- LinearProgressIndicator for each budgeted category
- Color: green (<80%), orange (80-99%), red (>=100%)
- Shows spent/budget amounts and remaining

**Step 5.6: CategoryBreakdownList widget**
- Sortable list of all categories with amounts and percentages
- Icon + name + transaction count + amount + percentage

**Step 5.7: MonthComparisonCard widget**
- Shows income/expense changes vs previous month
- Up/down arrows with percentage changes
- Color-coded positive/negative

**Step 5.8: LedgerRatioChart widget**
- Pie chart showing Survival vs Soul spending ratio
- Green (survival) vs Purple (soul) theme colors

### Phase 6: Main Analytics Screen (Day 6)

**Step 6.1: AnalyticsScreen**
- File: `lib/features/analytics/presentation/screens/analytics_screen.dart`
- Month picker in AppBar (left/right arrows + month selector)
- ScrollView with all widgets in order:
  1. Summary Cards (income/expenses/savings/rate)
  2. Category Pie Chart
  3. Daily Expense Bar Chart
  4. Ledger Ratio (Survival vs Soul)
  5. Budget Progress
  6. 6-Month Expense Trend
  7. Category Breakdown List
  8. Month Comparison
- Pull-to-refresh support
- Loading/error states via AsyncValue

### Phase 7: Navigation Integration (Day 7)

**Step 7.1: Create main navigation shell**
- Add BottomNavigationBar to main app
- Tab 1: Home (DualLedgerScreen) — existing
- Tab 2: Analytics (AnalyticsScreen) — new
- Tab 3: Settings (placeholder Scaffold)
- Pass bookId to analytics screen

**Step 7.2: Update main.dart**
- Replace direct DualLedgerScreen with new navigation shell
- Preserve existing initialization flow

### Phase 8: Demo Data (Day 7)

**Step 8.1: Create DemoDataService**
- File: `lib/application/analytics/demo_data_service.dart`
- Generate 3 months of realistic transactions:
  - 100-200 transactions per month
  - Mix of expense/income types
  - Distributed across categories with realistic patterns
  - Daily variation to create interesting trends
- Set budgets on key categories (food, transport, entertainment)
  - Some budgets safe, some warning, some exceeded
- Can be triggered from a debug button in analytics screen

### Phase 9: i18n Strings (Day 8)

**Step 9.1: Add analytics translations**
- Update all 3 ARB files (ja, en, zh):
  - `analyticsTitle`: 統計 / Analytics / 统计
  - `monthlyReport`: 月次レポート / Monthly Report / 月度报表
  - `income`: 収入 / Income / 收入
  - `expenses`: 支出 / Expenses / 支出
  - `savings`: 貯蓄 / Savings / 结余
  - `savingsRate`: 貯蓄率 / Savings Rate / 储蓄率
  - `categoryBreakdown`: カテゴリ別 / By Category / 分类明细
  - `expenseTrend`: 支出推移 / Expense Trend / 支出趋势
  - `budgetProgress`: 予算進捗 / Budget Progress / 预算进度
  - `monthComparison`: 前月比較 / vs Last Month / 与上月对比
  - `survivalLedger`: 生存 / Survival / 生存
  - `soulLedger`: 魂 / Soul / 灵魂
  - `noBudgetSet`: 予算未設定 / No budgets set / 暂无预算设置
  - `noDataAvailable`: データなし / No data / 暂无数据
  - `exceeded`: 超過 / Exceeded / 超支
  - `remaining`: 残り / Remaining / 剩余
  - `dailyExpenses`: 日別支出 / Daily Expenses / 每日支出
  - `ledgerRatio`: 帳簿比率 / Ledger Ratio / 账本比率
  - `generateDemoData`: デモデータ生成 / Generate Demo Data / 生成演示数据
- Run `flutter gen-l10n`

### Phase 10: Tests (Day 8)

**Step 10.1: Unit tests for Use Cases**
- `test/unit/application/analytics/get_monthly_report_use_case_test.dart`
  - Correct total calculations (income, expenses, savings, rate)
  - Category breakdown percentages sum to 100%
  - Daily expenses cover all days in month
  - Previous month comparison calculations
  - Empty data handling
- `test/unit/application/analytics/get_budget_progress_use_case_test.dart`
  - Budget status thresholds (safe <80%, warning 80-99%, exceeded >=100%)
  - Remaining amount calculations
  - Empty categories handling
- `test/unit/application/analytics/get_expense_trend_use_case_test.dart`
  - Multi-month data aggregation
  - Missing months handled

**Step 10.2: Unit tests for AnalyticsDao**
- Test aggregate queries return correct sums
- Test GROUP BY produces correct category totals
- Test date range filtering

**Step 10.3: Widget tests**
- `test/widget/features/analytics/summary_cards_test.dart`
- `test/widget/features/analytics/budget_progress_list_test.dart`
- Verify correct rendering with mock data
- Verify empty states

**Step 10.4: Run full test suite**
- `flutter test`
- `flutter analyze` (zero warnings)
- `dart format .`

---

## Dependency Graph

```
Phase 1 (Data Layer)
    → Phase 2 (Domain Models)
        → Phase 3 (Use Cases)
            → Phase 4 (Providers)
                → Phase 5 (Widgets) + Phase 8 (Demo Data)
                    → Phase 6 (Analytics Screen)
                        → Phase 7 (Navigation)
Phase 9 (i18n) — can be done in parallel with Phase 5+
Phase 10 (Tests) — incrementally with each phase, full suite at end
```

---

## Key Design Decisions

1. **AnalyticsDao for SQL aggregation** — Avoids loading all transactions into memory; uses database-level SUM/GROUP BY for performance (<2s target)
2. **BottomNavigationBar** — Simplest navigation without introducing GoRouter; tabs for Home/Analytics/Settings
3. **Demo data service** — Generates realistic data so all charts show meaningful content even without user transactions
4. **Separate chart widgets** — Each chart is an independent widget for testability and reusability
5. **No analytics-specific tables** — Phase 1 aggregates on-the-fly from transactions; caching tables can be added later if performance requires it
6. **Budget on Category** — Add nullable `budgetAmount` field to existing Category model rather than creating a separate budget table

---

## Risk & Mitigation

| Risk | Impact | Mitigation |
|------|--------|-----------|
| fl_chart API changes | Medium | Pin version, check docs |
| Aggregation slow with >1000 txns | Medium | Use SQL-level GROUP BY, add indices |
| Category model change ripple | Low | Nullable field, backward compatible |
| No GoRouter yet | Low | BottomNavigationBar is simpler, GoRouter can be added later |

---

## Acceptance Criteria

- [ ] Monthly report shows income, expenses, savings, savings rate
- [ ] Category pie chart shows top categories with percentages
- [ ] Daily expense bar chart shows spending across the month
- [ ] 6-month expense trend line chart shows historical data
- [ ] Survival vs Soul ledger ratio visualization
- [ ] Budget progress bars with safe/warning/exceeded states
- [ ] Month-over-month comparison with change percentages
- [ ] Month picker navigation (previous/next/select)
- [ ] Demo data generation showcases all features
- [ ] All text localized (ja, en, zh)
- [ ] Currency formatting uses NumberFormatter
- [ ] Date formatting uses DateFormatter
- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — all pass, ≥80% coverage on new code
- [ ] Report generation <2s with 1000 transactions
