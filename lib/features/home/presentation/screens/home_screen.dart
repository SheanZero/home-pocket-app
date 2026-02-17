import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/analytics/presentation/providers/analytics_providers.dart';
import '../../../../generated/app_localizations.dart';
import '../providers/home_providers.dart';
import '../providers/today_transactions_provider.dart';
import '../widgets/family_invite_banner.dart';
import '../widgets/hero_header.dart';
import '../widgets/home_transaction_tile.dart';
import '../widgets/month_overview_card.dart';
import '../widgets/ohtani_converter.dart';
import '../widgets/soul_fullness_card.dart';

/// Home tab content (Tab 0 inside MainShellScreen).
///
/// Scrollable content only -- no Scaffold, no bottom nav.
/// Wires providers to pure UI widgets.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.bookId, this.onSettingsTap});

  final String bookId;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    final reportAsync = ref.watch(
      monthlyReportProvider(bookId: bookId, year: year, month: month),
    );
    final todayTxAsync = ref.watch(todayTransactionsProvider(bookId: bookId));
    final ohtaniVisible = ref.watch(ohtaniConverterVisibleProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero header
          HeroHeader(
            year: year,
            month: month,
            onSettingsTap: onSettingsTap ?? () {},
            onDateTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Date picker coming soon'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Month overview card
          reportAsync.when(
            data: (report) {
              final previousTotal =
                  report.previousMonthComparison?.previousExpenses ?? 0;
              final previousMonth =
                  report.previousMonthComparison?.previousMonth ??
                  (month == 1 ? 12 : month - 1);

              return MonthOverviewCard(
                totalExpense: report.totalExpenses,
                survivalExpense: report.survivalTotal,
                soulExpense: report.soulTotal,
                previousMonthTotal: previousTotal,
                currentMonthNumber: month,
                previousMonthNumber: previousMonth,
                modeBadgeText: l10n.homePersonalMode,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 200,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Error: $error'),
            ),
          ),
          const SizedBox(height: 16),

          // Soul fullness card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: reportAsync.when(
              data: (report) {
                final totalExpense = report.totalExpenses;
                final soulPercent = totalExpense > 0
                    ? (report.soulTotal * 100 ~/ totalExpense)
                    : 0;
                final happinessROI = totalExpense > 0
                    ? report.soulTotal / totalExpense * 10
                    : 0.0;
                final fullness = soulPercent.clamp(0, 100);

                return SoulFullnessCard(
                  soulPercentage: soulPercent,
                  happinessROI: double.parse(happinessROI.toStringAsFixed(1)),
                  fullnessLevel: fullness,
                  recentMerchant: '-',
                  recentAmount: 0,
                  recentQuote: '',
                );
              },
              loading: () => const SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Text('Error: $error'),
            ),
          ),
          const SizedBox(height: 16),

          // Family invite banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FamilyInviteBanner(onTap: () {}),
          ),
          const SizedBox(height: 16),

          // Today's transactions header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: todayTxAsync.when(
              data: (transactions) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.homeTodayTitle,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    l10n.homeTodayCount(transactions.length),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              loading: () => Text(
                l10n.homeTodayTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              error: (_, _) => Text(l10n.homeTodayTitle),
            ),
          ),
          const SizedBox(height: 8),

          // Today's transaction list
          todayTxAsync.when(
            data: (transactions) {
              if (transactions.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Center(
                    child: Text(
                      l10n.noTransactionsYet,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                );
              }
              return Column(
                children: transactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: HomeTransactionTile(
                      merchant: tx.merchant ?? tx.categoryId,
                      categoryLabel: tx.categoryId,
                      formattedAmount: _formatAmount(tx),
                      ledgerType: tx.ledgerType,
                      iconData: _iconForCategory(tx.categoryId),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Error: $error'),
            ),
          ),
          const SizedBox(height: 8),

          // Ohtani converter
          if (ohtaniVisible)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OhtaniConverter(
                emoji: '\u{1F35A}',
                text:
                    todayTxAsync.whenOrNull(
                      data: (txs) {
                        final total = txs.fold<int>(
                          0,
                          (sum, tx) => sum + tx.amount,
                        );
                        final bowls = (total / 500).toStringAsFixed(1);
                        return '$bowls bowls of gyudon';
                      },
                    ) ??
                    '',
                onDismiss: () =>
                    ref.read(ohtaniConverterVisibleProvider.notifier).dismiss(),
              ),
            ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  String _formatAmount(Transaction tx) {
    final formatted = NumberFormat.currency(
      symbol: '\u00a5',
      decimalDigits: 0,
    ).format(tx.amount);
    return tx.type == TransactionType.expense ? '-$formatted' : formatted;
  }

  IconData _iconForCategory(String categoryId) {
    switch (categoryId) {
      case 'cat_food':
        return Icons.restaurant;
      case 'cat_housing':
        return Icons.home_outlined;
      case 'cat_transport':
        return Icons.train;
      case 'cat_utilities':
        return Icons.bolt;
      case 'cat_entertainment':
        return Icons.movie;
      case 'cat_education':
        return Icons.school;
      case 'cat_health':
        return Icons.medical_services;
      case 'cat_shopping':
        return Icons.shopping_bag;
      default:
        return Icons.receipt_long;
    }
  }
}
