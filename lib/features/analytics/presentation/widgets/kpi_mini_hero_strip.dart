import 'package:flutter/material.dart';

import '../../domain/models/happiness_report.dart';
import '../../domain/models/monthly_report.dart';
import 'joy_headline_kpi_tile.dart';
import 'total_spending_kpi_tile.dart';

/// STATSUI-07 — Horizontal KPI mini-hero strip (Joy Index left, 総 right).
class KpiMiniHeroStrip extends StatelessWidget {
  const KpiMiniHeroStrip({
    super.key,
    required this.monthlyReport,
    required this.happinessReport,
    required this.currencyCode,
    required this.locale,
  });

  final MonthlyReport monthlyReport;
  final HappinessReport happinessReport;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: JoyHeadlineKpiTile(
            report: happinessReport,
            currencyCode: currencyCode,
            locale: locale,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TotalSpendingKpiTile(
            report: monthlyReport,
            currencyCode: currencyCode,
            locale: locale,
          ),
        ),
      ],
    );
  }
}
