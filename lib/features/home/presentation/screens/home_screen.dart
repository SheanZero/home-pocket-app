import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../generated/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/analytics/domain/models/monthly_report.dart';
import '../../../../features/analytics/presentation/providers/state_analytics.dart';
import '../../../../features/family_sync/presentation/providers/state_active_group.dart';
import '../../../../features/family_sync/presentation/screens/group_choice_screen.dart';
import '../../../../infrastructure/category/category_service.dart';
import '../../../settings/presentation/providers/state_locale.dart';
import '../models/ledger_row_data.dart';
import '../providers/shadow_books_provider.dart';
import '../providers/today_transactions_provider.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/ledger_comparison_section.dart';
import '../widgets/month_overview_card.dart';
import '../widgets/section_divider.dart';
import '../widgets/soul_fullness_card.dart';
import '../widgets/transaction_list_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Flat vertical scroll layout with section dividers.
/// Wires providers to pure UI widgets. No Scaffold, no bottom nav.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.bookId, this.onSettingsTap});

  final String bookId;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeAsync = ref.watch(currentLocaleProvider);
    final locale = localeAsync.valueOrNull ?? const Locale('ja');
    final isGroupMode = ref.watch(isGroupModeProvider);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final reportAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    final shadowAsync = ref.watch(
      shadowAggregateProvider(year: year, month: month),
    );
    final shadowBookList = ref.watch(shadowBooksProvider);
    final todayTxAsync = ref.watch(todayTransactionsProvider(bookId: bookId));

    return SingleChildScrollView(
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hero header ──
              HeroHeader(
                year: year,
                month: month,
                isGroupMode: isGroupMode,
                onSettingsTap: onSettingsTap ?? () {},
                onDateTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(S.of(context).datePickerComingSoon),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Section: Monthly expenses ──
              const SectionDivider(label: '今月の支出'),
              const SizedBox(height: 16),

              // ── Month overview card ──
              reportAsync.when(
                data: (report) {
                  final shadowData = shadowAsync.valueOrNull;
                  return MonthOverviewCard(
                    totalExpense:
                        report.totalExpenses + (shadowData?.totalExpenses ?? 0),
                    previousMonthTotal:
                        (report.previousMonthComparison?.previousExpenses ??
                            0) +
                        (shadowData?.prevTotalExpenses ?? 0),
                  );
                },
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorText(message: '$error'),
              ),
              const SizedBox(height: 16),

              // ── Section: Ledgers ──
              const SectionDivider(label: '帳 本'),
              const SizedBox(height: 16),

              // ── Ledger comparison rows ──
              reportAsync.when(
                data: (report) => LedgerComparisonSection(
                  rows: _buildLedgerRows(
                    context,
                    report,
                    isGroupMode,
                    shadowBooks: shadowBookList.valueOrNull,
                    shadowAgg: shadowAsync.valueOrNull,
                  ),
                ),
                loading: () => const SizedBox(
                  height: 80,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorText(message: '$error'),
              ),
              const SizedBox(height: 16),

              // ── Soul fullness card ──
              reportAsync.when(
                data: (report) => SoulFullnessCard(
                  satisfactionPercent: _computeSatisfaction(todayTxAsync),
                  happinessROI: _computeHappinessROI(report),
                  recentSoulAmount: report.soulTotal,
                ),
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorText(message: '$error'),
              ),
              const SizedBox(height: 16),

              // ── Group bar or Family invite banner ──
              if (isGroupMode) ...[
                // TODO: Wire GroupBar with actual group data when available
                const SizedBox.shrink(),
                const SizedBox(height: 16),
              ],
              if (!isGroupMode) ...[
                FamilyInviteBanner(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const GroupChoiceScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],

              // ── Transactions header row ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '最近の取引',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.wmTextPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigate to full transaction list
                    },
                    child: Text(
                      'すべて見る',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.accentPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Transaction list card ──
              todayTxAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          '取引がまだありません',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.wmTextSecondary,
                          ),
                        ),
                      ),
                    );
                  }
                  return TransactionListCard(
                    children: transactions.map((tx) {
                      final isSoul = tx.ledgerType == LedgerType.soul;
                      return HomeTransactionTile(
                        tagText: isGroupMode
                            ? _memberInitial(tx)
                            : (isSoul ? '\u9b42' : '\u751f'),
                        tagBgColor: isSoul
                            ? context.wmSoulTagBg
                            : context.wmSurvivalTagBg,
                        tagTextColor: isSoul
                            ? AppColors.soul
                            : AppColors.survival,
                        merchant:
                            tx.merchant ??
                            CategoryService.resolveFromId(
                              tx.categoryId,
                              locale,
                            ),
                        category: CategoryService.resolveFromId(
                          tx.categoryId,
                          locale,
                        ),
                        categoryColor: isSoul
                            ? AppColors.accentPrimary
                            : context.wmTextSecondary,
                        formattedAmount: _formatAmount(tx),
                        amountColor: isSoul
                            ? AppColors.accentPrimary
                            : context.wmTextPrimary,
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => _ErrorText(message: '$error'),
              ),

              // ── Bottom padding for pill nav ──
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Data wiring helpers ──

  List<LedgerRowData> _buildLedgerRows(
    BuildContext context,
    MonthlyReport report,
    bool isGroupMode, {
    List<ShadowBookInfo>? shadowBooks,
    ShadowAggregate? shadowAgg,
  }) {
    final rows = <LedgerRowData>[
      LedgerRowData(
        tagText: '生',
        tagBgColor: context.wmSurvivalTagBg,
        tagTextColor: AppColors.survival,
        title: '生存帳本',
        titleColor: context.wmTextPrimary,
        subtitle:
            '先月 \u00a5${_formatInt(report.previousMonthComparison?.previousExpenses ?? 0)}',
        formattedAmount: '\u00a5${_formatInt(report.survivalTotal)}',
        amountColor: AppColors.survival,
        chevronColor: context.wmTextTertiary,
      ),
      LedgerRowData(
        tagText: '灵',
        tagBgColor: context.wmSoulTagBg,
        tagTextColor: AppColors.soul,
        title: '灵魂帳本',
        titleColor: AppColors.soul,
        subtitle:
            '先月 \u00a5${_formatInt(report.previousMonthComparison?.previousExpenses ?? 0)}',
        formattedAmount: '\u00a5${_formatInt(report.soulTotal)}',
        amountColor: AppColors.soul,
        chevronColor: context.wmTextTertiary,
      ),
    ];

    if (isGroupMode && shadowBooks != null) {
      for (final shadow in shadowBooks) {
        final bookReport = shadowAgg?.perBookReports[shadow.book.id];
        final total = bookReport?.totalExpenses ?? 0;
        final prevTotal =
            bookReport?.previousMonthComparison?.previousExpenses ?? 0;
        rows.add(
          LedgerRowData(
            tagText: '共',
            tagBgColor: context.wmSharedTagBg,
            tagTextColor: AppColors.shared,
            title: '${shadow.memberDisplayName}の帳本',
            titleColor: AppColors.shared,
            subtitle: '先月 \u00a5${_formatInt(prevTotal)}',
            formattedAmount: '\u00a5${_formatInt(total)}',
            amountColor: AppColors.shared,
            chevronColor: AppColors.sharedChevron,
            borderColor: AppColors.sharedBorder,
          ),
        );
      }
    }

    return rows;
  }

  String _formatInt(int value) {
    return NumberFormat('#,##0').format(value);
  }

  String _formatAmount(Transaction tx) {
    final formatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(tx.amount);
    return tx.type == TransactionType.expense ? '-$formatted' : formatted;
  }

  /// Extracts the first character of a member identifier for group mode.
  String _memberInitial(Transaction tx) {
    // Use device ID first character as fallback; real member data TBD
    return tx.deviceId.isNotEmpty ? tx.deviceId[0].toUpperCase() : '?';
  }

  /// Computes average satisfaction from today's soul transactions.
  int _computeSatisfaction(AsyncValue<List<Transaction>> txAsync) {
    final transactions = txAsync.valueOrNull;
    if (transactions == null || transactions.isEmpty) return 0;

    final soulTxs = transactions
        .where((tx) => tx.ledgerType == LedgerType.soul)
        .toList();
    if (soulTxs.isEmpty) return 0;

    final totalSatisfaction = soulTxs.fold<int>(
      0,
      (sum, tx) => sum + tx.soulSatisfaction,
    );
    return (totalSatisfaction / soulTxs.length * 10).round();
  }

  /// Computes happiness ROI: soul total / total expenses ratio.
  double _computeHappinessROI(MonthlyReport report) {
    if (report.totalExpenses == 0) return 0;
    return double.parse(
      (report.soulTotal / report.totalExpenses).toStringAsFixed(1),
    );
  }
}

/// Reusable error text widget for async error states.
class _ErrorText extends StatelessWidget {
  const _ErrorText({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Error: $message',
        style: AppTextStyles.bodySmall.copyWith(color: Colors.red),
      ),
    );
  }
}
