# MOD-007: 数据分析与报表 - 技术设计文档

**模块编号:** MOD-007
**模块名称:** 数据分析与报表
**文档版本:** 2.0
**创建日期:** 2026-02-03
**预估工时:** 8天
**优先级:** P0（MVP核心功能）
**依赖项:** MOD-001 (基础记账), MOD-003 (双轨账本)

---

## 📋 目录

1. [模块概述](#模块概述)
2. [业务价值](#业务价值)
3. [核心功能](#核心功能)
4. [功能需求](#功能需求)
5. [技术设计](#技术设计)
6. [数据模型](#数据模型)
7. [核心实现流程](#核心实现流程)
8. [UI组件设计](#ui组件设计)
9. [测试策略](#测试策略)
10. [性能优化](#性能优化)

---

## 模块概述

### 业务价值

数据分析模块通过可视化报表和图表将原始交易数据转化为可操作的洞察:

- **月度报表 (A01):** 全面的月末财务摘要
- **分类明细:** 饼图显示支出分布
- **支出趋势:** 折线图追踪月度模式
- **预算跟踪:** 进度条和预算限制提醒
- **交互式图表:** 点击深入查看详情

### 架构位置

```
┌─────────────────────────────────────────────────┐
│           表现层                                 │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 月度报表     │  │  分类图表组件        │    │
│  │ 界面         │  │                      │    │
│  └──────────────┘  └──────────────────────┘    │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 趋势图表     │  │  预算进度组件        │    │
│  │ 组件         │  │                      │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
                     ↓↑
┌─────────────────────────────────────────────────┐
│           业务逻辑层                             │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 月度报表     │  │  分类统计用例        │    │
│  │ 用例         │  │                      │    │
│  └──────────────┘  └──────────────────────┘    │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 趋势分析     │  │  预算跟踪用例        │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
                     ↓↑
┌─────────────────────────────────────────────────┐
│            数据层                                │
│  ┌──────────────┐  ┌──────────────────────┐    │
│  │ 交易仓储     │  │  统计缓存仓储        │    │
│  └──────────────┘  └──────────────────────┘    │
└─────────────────────────────────────────────────┘
```

---

## 业务价值

### 用户痛点

**目标用户:** 田中(35岁)和美惠(33岁)夫妇管理家庭财务

**痛点:**
1. **缺乏清晰概览:** "这个月的钱都花哪儿了?"
2. **预算盲点:** "我们又在外出就餐上超支了,却没注意到"
3. **趋势无知:** "我们的支出比上个月多还是少?"
4. **分类困惑:** "哪个分类消耗了我们最多的预算?"

**解决方案:**
- 自动生成的月度报表,清晰摘要
- 可视化分类饼图(即时查看比例)
- 月度同比趋势折线图
- 超支前的实时预算提醒

### 成功指标

| 指标 | 目标 | 测量方式 |
|------|------|----------|
| 报表生成时间 | <2s | 1000条交易 |
| 图表渲染时间 | <500ms | 数据到可视化 |
| 用户报表查看率 | >80% | 月活跃用户 |
| 预算提醒有效性 | >70% | 调整支出的用户 |

---

## 核心功能

### 功能矩阵

| 功能ID | 功能名称 | 优先级 | 复杂度 |
|--------|----------|--------|--------|
| A01 | 月度报表生成 | P0 | 中 |
| A01-CAT | 分类明细图表 | P0 | 低 |
| A01-TREND | 支出趋势图表 | P0 | 中 |
| A01-BUDGET | 预算跟踪与提醒 | P0 | 中 |
| A01-EXPORT | 导出PDF报表 | P1 | 低 |
| A02 | 自定义日期范围报表 | P1 | 中 |
| A03 | 对比报表 | P2 | 高 |

---

## 功能需求

### 用户故事

**作为** 月末用户
**我希望** 查看全面的月度报表
**以便** 清楚了解我的财务状况

**验收标准:**
- 月末自动生成报表
- 显示总收入、支出、储蓄
- 按分类分解并显示百分比
- 突出显示前3大支出分类
- 与上月对比

---

## 技术设计

### 月度报表生成架构

```
用户请求报表
    ↓
GetMonthlyReportUseCase.execute(year, month)
    ↓
┌─────────────────────────────────────┐
│ 1. 查询交易                         │
│    - 按年/月过滤                    │
│    - 按账本类型分组                 │
│    - 计算总计                       │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 2. 分类统计                         │
│    - 按分类求和                     │
│    - 计算百分比                     │
│    - 按金额排序(降序)               │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 3. 趋势分析                         │
│    - 与上月对比                     │
│    - 计算变化百分比                 │
│    - 识别异常                       │
└─────────────────────────────────────┘
    ↓
返回MonthlyReport
```

---

## 数据模型

### 领域模型

```dart
// lib/features/analytics/domain/models/monthly_report.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'monthly_report.freezed.dart';

@freezed
class MonthlyReport with _$MonthlyReport {
  const factory MonthlyReport({
    required int year,
    required int month,
    required int totalIncome,
    required int totalExpenses,
    required int savings,
    required double savingsRate,
    required List<CategoryBreakdown> categoryBreakdowns,
    required List<DailyExpense> dailyExpenses,
    MonthComparison? previousMonthComparison,
  }) = _MonthlyReport;
}

@freezed
class CategoryBreakdown with _$CategoryBreakdown {
  const factory CategoryBreakdown({
    required String categoryId,
    required String categoryName,
    required String icon,
    required int amount,
    required double percentage,
    required int transactionCount,
    int? budgetAmount,
    double? budgetProgress,
  }) = _CategoryBreakdown;
}

@freezed
class DailyExpense with _$DailyExpense {
  const factory DailyExpense({
    required DateTime date,
    required int amount,
  }) = _DailyExpense;
}

@freezed
class MonthComparison with _$MonthComparison {
  const factory MonthComparison({
    required int previousMonth,
    required int previousYear,
    required int previousIncome,
    required int previousExpenses,
    required double incomeChange,
    required double expenseChange,
  }) = _MonthComparison;
}
```

```dart
// lib/features/analytics/domain/models/budget_progress.dart

import 'package:freezed_annotation/freezed_annotation.dart';

part 'budget_progress.freezed.dart';

enum BudgetStatus {
  safe,      // < 80%
  warning,   // 80-99%
  exceeded,  // >= 100%
}

@freezed
class BudgetProgress with _$BudgetProgress {
  const factory BudgetProgress({
    required String categoryId,
    required String categoryName,
    required int budgetAmount,
    required int spentAmount,
    required double percentage,
    required BudgetStatus status,
    required int remainingAmount,
  }) = _BudgetProgress;
}
```

---

## 核心实现流程

### 1. 月度报表用例实现

```dart
// lib/features/analytics/application/use_cases/get_monthly_report_use_case.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../../category/domain/repositories/category_repository.dart';
import '../../domain/models/monthly_report.dart';

part 'get_monthly_report_use_case.g.dart';

class GetMonthlyReportUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  GetMonthlyReportUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo;

  Future<MonthlyReport> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    // 1. Get date range
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    // 2. Query transactions
    final transactions = await _transactionRepo.getTransactionsByDateRange(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    // 3. Calculate totals
    int totalIncome = 0;
    int totalExpenses = 0;

    for (final tx in transactions) {
      if (tx.type == TransactionType.income) {
        totalIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        totalExpenses += tx.amount;
      }
    }

    final savings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0
        ? (savings / totalIncome * 100)
        : 0.0;

    // 4. Category breakdown
    final categoryBreakdowns = await _calculateCategoryBreakdowns(
      transactions: transactions,
      totalExpenses: totalExpenses,
    );

    // 5. Daily expenses for trend chart
    final dailyExpenses = _calculateDailyExpenses(
      transactions: transactions,
      year: year,
      month: month,
    );

    // 6. Previous month comparison
    final previousMonthComparison = await _getPreviousMonthComparison(
      bookId: bookId,
      currentYear: year,
      currentMonth: month,
      currentIncome: totalIncome,
      currentExpenses: totalExpenses,
    );

    return MonthlyReport(
      year: year,
      month: month,
      totalIncome: totalIncome,
      totalExpenses: totalExpenses,
      savings: savings,
      savingsRate: savingsRate,
      categoryBreakdowns: categoryBreakdowns,
      dailyExpenses: dailyExpenses,
      previousMonthComparison: previousMonthComparison,
    );
  }

  Future<List<CategoryBreakdown>> _calculateCategoryBreakdowns({
    required List<Transaction> transactions,
    required int totalExpenses,
  }) async {
    // Group by category
    final Map<String, int> categoryTotals = {};
    final Map<String, int> categoryCount = {};

    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        categoryTotals[tx.categoryId] =
            (categoryTotals[tx.categoryId] ?? 0) + tx.amount;
        categoryCount[tx.categoryId] =
            (categoryCount[tx.categoryId] ?? 0) + 1;
      }
    }

    // Build breakdowns
    final List<CategoryBreakdown> breakdowns = [];
    for (final entry in categoryTotals.entries) {
      final category = await _categoryRepo.getCategoryById(entry.key);
      if (category == null) continue;

      final percentage = totalExpenses > 0
          ? (entry.value / totalExpenses * 100)
          : 0.0;

      breakdowns.add(CategoryBreakdown(
        categoryId: entry.key,
        categoryName: category.name,
        icon: category.icon,
        amount: entry.value,
        percentage: percentage,
        transactionCount: categoryCount[entry.key] ?? 0,
        budgetAmount: category.budgetAmount,
        budgetProgress: category.budgetAmount != null
            ? (entry.value / category.budgetAmount! * 100)
            : null,
      ));
    }

    // Sort by amount descending
    breakdowns.sort((a, b) => b.amount.compareTo(a.amount));

    return breakdowns;
  }

  List<DailyExpense> _calculateDailyExpenses({
    required List<Transaction> transactions,
    required int year,
    required int month,
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final Map<int, int> dailyTotals = {};

    // Initialize all days to 0
    for (int day = 1; day <= daysInMonth; day++) {
      dailyTotals[day] = 0;
    }

    // Sum expenses by day
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        final day = tx.timestamp.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0) + tx.amount;
      }
    }

    // Convert to list
    return List.generate(daysInMonth, (index) {
      final day = index + 1;
      return DailyExpense(
        date: DateTime(year, month, day),
        amount: dailyTotals[day] ?? 0,
      );
    });
  }

  Future<MonthComparison?> _getPreviousMonthComparison({
    required String bookId,
    required int currentYear,
    required int currentMonth,
    required int currentIncome,
    required int currentExpenses,
  }) async {
    // Calculate previous month
    int prevYear = currentYear;
    int prevMonth = currentMonth - 1;
    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }

    final startDate = DateTime(prevYear, prevMonth, 1);
    final endDate = DateTime(prevYear, prevMonth + 1, 0, 23, 59, 59);

    final prevTransactions = await _transactionRepo.getTransactionsByDateRange(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    int prevIncome = 0;
    int prevExpenses = 0;

    for (final tx in prevTransactions) {
      if (tx.type == TransactionType.income) {
        prevIncome += tx.amount;
      } else if (tx.type == TransactionType.expense) {
        prevExpenses += tx.amount;
      }
    }

    if (prevIncome == 0 && prevExpenses == 0) {
      return null; // No previous data
    }

    final incomeChange = prevIncome > 0
        ? ((currentIncome - prevIncome) / prevIncome * 100)
        : 0.0;

    final expenseChange = prevExpenses > 0
        ? ((currentExpenses - prevExpenses) / prevExpenses * 100)
        : 0.0;

    return MonthComparison(
      previousMonth: prevMonth,
      previousYear: prevYear,
      previousIncome: prevIncome,
      previousExpenses: prevExpenses,
      incomeChange: incomeChange,
      expenseChange: expenseChange,
    );
  }
}

@riverpod
GetMonthlyReportUseCase getMonthlyReportUseCase(
  GetMonthlyReportUseCaseRef ref,
) {
  return GetMonthlyReportUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
  );
}

@riverpod
Future<MonthlyReport> monthlyReport(
  MonthlyReportRef ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getMonthlyReportUseCaseProvider);
  return await useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
  );
}
```

### 2. 预算跟踪用例实现

```dart
// lib/features/analytics/application/use_cases/get_budget_progress_use_case.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../transaction/domain/repositories/transaction_repository.dart';
import '../../../category/domain/repositories/category_repository.dart';
import '../../domain/models/budget_progress.dart';

part 'get_budget_progress_use_case.g.dart';

class GetBudgetProgressUseCase {
  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;

  GetBudgetProgressUseCase({
    required TransactionRepository transactionRepo,
    required CategoryRepository categoryRepo,
  })  : _transactionRepo = transactionRepo,
        _categoryRepo = categoryRepo;

  Future<List<BudgetProgress>> execute({
    required String bookId,
    required int year,
    required int month,
  }) async {
    // 1. Get categories with budgets
    final categories = await _categoryRepo.getCategoriesWithBudget();

    if (categories.isEmpty) {
      return [];
    }

    // 2. Get current month transactions
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    final transactions = await _transactionRepo.getTransactionsByDateRange(
      bookId: bookId,
      startDate: startDate,
      endDate: endDate,
    );

    // 3. Calculate spending by category
    final Map<String, int> categorySpending = {};
    for (final tx in transactions) {
      if (tx.type == TransactionType.expense) {
        categorySpending[tx.categoryId] =
            (categorySpending[tx.categoryId] ?? 0) + tx.amount;
      }
    }

    // 4. Build budget progress list
    final List<BudgetProgress> progressList = [];

    for (final category in categories) {
      if (category.budgetAmount == null) continue;

      final spentAmount = categorySpending[category.id] ?? 0;
      final percentage = (spentAmount / category.budgetAmount! * 100);
      final remainingAmount = category.budgetAmount! - spentAmount;

      BudgetStatus status;
      if (percentage >= 100) {
        status = BudgetStatus.exceeded;
      } else if (percentage >= 80) {
        status = BudgetStatus.warning;
      } else {
        status = BudgetStatus.safe;
      }

      progressList.add(BudgetProgress(
        categoryId: category.id,
        categoryName: category.name,
        budgetAmount: category.budgetAmount!,
        spentAmount: spentAmount,
        percentage: percentage,
        status: status,
        remainingAmount: remainingAmount,
      ));
    }

    // Sort by percentage descending (most at risk first)
    progressList.sort((a, b) => b.percentage.compareTo(a.percentage));

    return progressList;
  }
}

@riverpod
GetBudgetProgressUseCase getBudgetProgressUseCase(
  GetBudgetProgressUseCaseRef ref,
) {
  return GetBudgetProgressUseCase(
    transactionRepo: ref.watch(transactionRepositoryProvider),
    categoryRepo: ref.watch(categoryRepositoryProvider),
  );
}

@riverpod
Future<List<BudgetProgress>> budgetProgressList(
  BudgetProgressListRef ref, {
  required String bookId,
  required int year,
  required int month,
}) async {
  final useCase = ref.watch(getBudgetProgressUseCaseProvider);
  return await useCase.execute(
    bookId: bookId,
    year: year,
    month: month,
  );
}
```

---

## UI组件设计

### 1. 月度报表界面

```dart
// lib/features/analytics/presentation/screens/monthly_report_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../application/use_cases/get_monthly_report_use_case.dart';
import '../../domain/models/monthly_report.dart';

class MonthlyReportScreen extends ConsumerStatefulWidget {
  final String bookId;

  const MonthlyReportScreen({
    super.key,
    required this.bookId,
  });

  @override
  ConsumerState<MonthlyReportScreen> createState() =>
      _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends ConsumerState<MonthlyReportScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final reportAsync = ref.watch(monthlyReportProvider(
      bookId: widget.bookId,
      year: _selectedDate.year,
      month: _selectedDate.month,
    ));

    return Scaffold(
      appBar: AppBar(
        title: const Text('月度报表'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
          ),
          TextButton(
            onPressed: _selectMonth,
            child: Text(
              '${_selectedDate.year}年${_selectedDate.month}月',
              style: const TextStyle(fontSize: 16),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
          ),
        ],
      ),
      body: reportAsync.when(
        data: (report) => _buildReport(report),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('错误: $error')),
      ),
    );
  }

  Widget _buildReport(MonthlyReport report) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(report),
          const SizedBox(height: 24),
          _buildCategoryPieChart(report),
          const SizedBox(height: 24),
          _buildExpenseTrendChart(report),
          const SizedBox(height: 24),
          _buildCategoryBreakdownList(report),
          const SizedBox(height: 24),
          if (report.previousMonthComparison != null)
            _buildMonthComparison(report.previousMonthComparison!),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(MonthlyReport report) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '收入',
                amount: report.totalIncome,
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _SummaryCard(
                title: '支出',
                amount: report.totalExpenses,
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryCard(
                title: '结余',
                amount: report.savings,
                color: report.savings >= 0 ? Colors.blue : Colors.orange,
                icon: Icons.savings,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _PercentageCard(
                title: '储蓄率',
                percentage: report.savingsRate,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(MonthlyReport report) {
    if (report.categoryBreakdowns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支出分布',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: report.categoryBreakdowns.take(5).map((breakdown) {
                    return PieChartSectionData(
                      value: breakdown.amount.toDouble(),
                      title: '${breakdown.percentage.toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseTrendChart(MonthlyReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '支出趋势',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          return Text('${value.toInt()}日');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: report.dailyExpenses.asMap().entries.map((entry) {
                        return FlSpot(
                          (entry.key + 1).toDouble(),
                          entry.value.amount.toDouble(),
                        );
                      }).toList(),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdownList(MonthlyReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分类明细',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...report.categoryBreakdowns.map((breakdown) {
              return _CategoryBreakdownItem(breakdown: breakdown);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthComparison(MonthComparison comparison) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '与上月对比 (${comparison.previousYear}年${comparison.previousMonth}月)',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _ComparisonRow(
              label: '收入变化',
              change: comparison.incomeChange,
            ),
            const SizedBox(height: 8),
            _ComparisonRow(
              label: '支出变化',
              change: comparison.expenseChange,
            ),
          ],
        ),
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 1);
    });
  }

  void _selectMonth() async {
    // TODO: Show month picker dialog
  }
}

// Helper Widgets

class _SummaryCard extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '¥${_formatAmount(amount)}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmount(int amount) {
    return amount.abs().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}

class _PercentageCard extends StatelessWidget {
  final String title;
  final double percentage;

  const _PercentageCard({
    required this.title,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${percentage.toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdownItem extends StatelessWidget {
  final CategoryBreakdown breakdown;

  const _CategoryBreakdownItem({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(
        breakdown.icon,
        style: const TextStyle(fontSize: 24),
      ),
      title: Text(breakdown.categoryName),
      subtitle: Text('${breakdown.transactionCount}笔交易'),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '¥${breakdown.amount}',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${breakdown.percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final double change;

  const _ComparisonRow({
    required this.label,
    required this.change,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(
              '${change.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
```

### 2. 预算进度组件

```dart
// lib/features/analytics/presentation/widgets/budget_progress_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/use_cases/get_budget_progress_use_case.dart';
import '../../domain/models/budget_progress.dart';

class BudgetProgressWidget extends ConsumerWidget {
  final String bookId;

  const BudgetProgressWidget({
    super.key,
    required this.bookId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final progressListAsync = ref.watch(budgetProgressListProvider(
      bookId: bookId,
      year: now.year,
      month: now.month,
    ));

    return progressListAsync.when(
      data: (progressList) {
        if (progressList.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('暂无预算设置'),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '预算进度',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ...progressList.map((progress) {
                  return _BudgetProgressItem(progress: progress);
                }),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Text('错误: $error'),
    );
  }
}

class _BudgetProgressItem extends StatelessWidget {
  final BudgetProgress progress;

  const _BudgetProgressItem({required this.progress});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(progress.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                progress.categoryName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '¥${progress.spentAmount} / ¥${progress.budgetAmount}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress.percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${progress.percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: color),
              ),
              if (progress.remainingAmount > 0)
                Text(
                  '剩余: ¥${progress.remainingAmount}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                )
              else
                Text(
                  '超支: ¥${progress.remainingAmount.abs()}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.safe:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.exceeded:
        return Colors.red;
    }
  }
}
```

---

## 测试策略

### 单元测试

```dart
// test/features/analytics/application/use_cases/get_monthly_report_use_case_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([TransactionRepository, CategoryRepository])
import 'get_monthly_report_use_case_test.mocks.dart';

void main() {
  group('GetMonthlyReportUseCase', () {
    late GetMonthlyReportUseCase useCase;
    late MockTransactionRepository mockTransactionRepo;
    late MockCategoryRepository mockCategoryRepo;

    setUp(() {
      mockTransactionRepo = MockTransactionRepository();
      mockCategoryRepo = MockCategoryRepository();
      useCase = GetMonthlyReportUseCase(
        transactionRepo: mockTransactionRepo,
        categoryRepo: mockCategoryRepo,
      );
    });

    test('should calculate correct monthly totals', () async {
      // Given
      final transactions = [
        Transaction(
          id: '1',
          type: TransactionType.income,
          amount: 100000,
          // ... other fields
        ),
        Transaction(
          id: '2',
          type: TransactionType.expense,
          amount: 30000,
          // ... other fields
        ),
        Transaction(
          id: '3',
          type: TransactionType.expense,
          amount: 20000,
          // ... other fields
        ),
      ];

      when(mockTransactionRepo.getTransactionsByDateRange(
        bookId: anyNamed('bookId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      )).thenAnswer((_) async => transactions);

      // When
      final report = await useCase.execute(
        bookId: 'book-1',
        year: 2026,
        month: 2,
      );

      // Then
      expect(report.totalIncome, 100000);
      expect(report.totalExpenses, 50000);
      expect(report.savings, 50000);
      expect(report.savingsRate, 50.0);
    });
  });
}
```

---

## 性能优化

### 优化策略

**1. 数据聚合优化:**
- 使用SQL GROUP BY减少计算
- 缓存月度统计结果
- 后台预加载下月数据

**2. 图表渲染优化:**
- 数据采样(大数据集)
- 延迟加载详细数据
- 使用Canvas绘制提升性能

**3. 内存优化:**
- 分页加载交易列表
- 限制图表数据点数量
- 及时释放不用的数据

---

## 验收标准

### 功能需求

- ✅ 月度报表生成时间<2秒(1000条交易)
- ✅ 分类饼图正确显示前5大分类
- ✅ 趋势折线图显示全月每日数据
- ✅ 预算进度实时更新
- ✅ 超支提醒及时推送

### 性能需求

| 指标 | 目标 | 实际 |
|------|------|------|
| 报表生成时间 | <2s | 待定 |
| 图表渲染时间 | <500ms | 待定 |
| 内存占用 | <50MB | 待定 |

---

## 开发时间线 (8天)

| 天数 | 任务 | 交付物 |
|------|------|--------|
| **第1天** | 数据模型设计 | MonthlyReport、BudgetProgress模型 |
| **第2天** | 月度报表用例 | GetMonthlyReportUseCase |
| **第3天** | 预算跟踪用例 | GetBudgetProgressUseCase |
| **第4天** | 月度报表UI | MonthlyReportScreen |
| **第5天** | 图表组件 | 饼图、折线图、柱状图 |
| **第6天** | 预算进度组件 | BudgetProgressWidget |
| **第7天** | 单元测试 | Use Case测试 |
| **第8天** | 集成测试与优化 | 性能优化、文档 |

---

## 参考资料

- [fl_chart](https://pub.dev/packages/fl_chart) - Flutter图表库
- PRD_Module_BasicAccounting.md (需求)
- 01_MVP_Complete_Architecture_Guide.md (架构)

---

**文档状态:** 完成
**审核状态:** 待审核
**变更日志:**
- 2026-02-03: 创建完整技术实现文档，包含所有代码示例
