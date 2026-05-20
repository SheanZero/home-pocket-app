import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_theme_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../domain/models/ledger_snapshot.dart';
import '../../domain/models/metric_result.dart';
import '../providers/state_ledger_snapshot.dart';
import 'analytics_card_error_state.dart';

/// STATSUI-V2-01 Soul-vs-Survival "Ledger · This window" engagement snapshot.
///
/// The widget reframes the ROADMAP's "satisfaction comparison" idea into a
/// descriptive engagement axis (entry count + total spend). The Soul column
/// additionally renders avg satisfaction (D-03 — single-sided by design;
/// `SurvivalLedgerSnapshot` literally lacks the field per D-04 type-system
/// gate). No "vs" / "compare" / "winner" copy anywhere (D-12, D-14).
///
/// Two layouts:
/// - Solo mode: side-by-side two-column (Soul | Survival), equal-height via
///   IntrinsicHeight.
/// - Group mode: 2×2 grid — rows = You/Family, columns = Soul/Survival. The
///   Family row honors the AsyncValue split (loading/error/Empty/Value) per
///   Plan 16-08 Task 1 step 4c.
class SoulVsSurvivalCard extends ConsumerWidget {
  const SoulVsSurvivalCard({
    super.key,
    required this.bookId,
    required this.startDate,
    required this.endDate,
    required this.currencyCode,
    required this.locale,
    required this.isGroupMode,
  });

  final String bookId;
  final DateTime startDate;
  final DateTime endDate;
  final String currencyCode;
  final Locale locale;
  final bool isGroupMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSnapshot = ref.watch(
      soulVsSurvivalSnapshotProvider(
        bookId: bookId,
        startDate: startDate,
        endDate: endDate,
      ),
    );

    final familyAsyncSnapshot = isGroupMode
        ? ref.watch(
            soulVsSurvivalSnapshotFamilyProvider(
              startDate: startDate,
              endDate: endDate,
            ),
          )
        : const AsyncValue<MetricResult<SoulVsSurvivalSnapshot>>.data(
            Empty<SoulVsSurvivalSnapshot>(),
          );

    final l10n = S.of(context);

    return Card(
      color: context.wmCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.analyticsCardTitleLedgerThisWindow,
              style: AppTextStyles.titleLarge.copyWith(
                color: context.wmTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            asyncSnapshot.when(
              loading: () => const SizedBox(height: 200),
              error: (_, _) => AnalyticsCardErrorState(
                onRetry: () => ref.invalidate(
                  soulVsSurvivalSnapshotProvider(
                    bookId: bookId,
                    startDate: startDate,
                    endDate: endDate,
                  ),
                ),
              ),
              data: (result) => switch (result) {
                Empty<SoulVsSurvivalSnapshot>() => _EmptyBody(),
                Value<SoulVsSurvivalSnapshot>(:final data) => isGroupMode
                    ? _GroupGrid(
                        you: data,
                        familyAsync: familyAsyncSnapshot,
                        currencyCode: currencyCode,
                        locale: locale,
                      )
                    : _SoloTwoColumn(
                        data: data,
                        currencyCode: currencyCode,
                        locale: locale,
                      ),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return Text(
      S.of(context).analyticsLedgerEmpty,
      style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
    );
  }
}

class _SoloTwoColumn extends StatelessWidget {
  const _SoloTwoColumn({
    required this.data,
    required this.currencyCode,
    required this.locale,
  });

  final SoulVsSurvivalSnapshot data;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SoulCell(
              soul: data.soul,
              currencyCode: currencyCode,
              locale: locale,
              label: null,
            ),
          ),
          VerticalDivider(width: 1, color: context.wmBorderDivider),
          Expanded(
            child: _SurvivalCell(
              survival: data.survival,
              currencyCode: currencyCode,
              locale: locale,
              label: null,
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupGrid extends StatelessWidget {
  const _GroupGrid({
    required this.you,
    required this.familyAsync,
    required this.currencyCode,
    required this.locale,
  });

  final SoulVsSurvivalSnapshot you;
  final AsyncValue<MetricResult<SoulVsSurvivalSnapshot>> familyAsync;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: You
        _LabeledRow(
          label: l10n.analyticsLedgerRowYou,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _SoulCell(
                    soul: you.soul,
                    currencyCode: currencyCode,
                    locale: locale,
                    label: null,
                  ),
                ),
                VerticalDivider(width: 1, color: context.wmBorderDivider),
                Expanded(
                  child: _SurvivalCell(
                    survival: you.survival,
                    currencyCode: currencyCode,
                    locale: locale,
                    label: null,
                  ),
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: context.wmBorderDivider),
        // Row 2: Family — branches per AsyncValue (Plan 16-08 Task 1 step 4c)
        familyAsync.when(
          loading: () => _LabeledRow(
            label: l10n.analyticsLedgerRowFamily,
            child: const _FamilyLoadingBody(),
          ),
          error: (_, _) => _LabeledRow(
            label: l10n.analyticsLedgerRowFamily,
            child: _FamilyCaptionBody(
              message: l10n.analyticsLedgerFamilyError,
            ),
          ),
          data: (result) => switch (result) {
            Empty<SoulVsSurvivalSnapshot>() => _LabeledRow(
                label: l10n.analyticsLedgerRowFamily,
                child: _FamilyCaptionBody(
                  message: l10n.analyticsLedgerFamilyEmpty,
                ),
              ),
            Value<SoulVsSurvivalSnapshot>(:final data) => _LabeledRow(
                label: l10n.analyticsLedgerRowFamily,
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: _SoulCell(
                          soul: data.soul,
                          currencyCode: currencyCode,
                          locale: locale,
                          label: null,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        color: context.wmBorderDivider,
                      ),
                      Expanded(
                        child: _SurvivalCell(
                          survival: data.survival,
                          currencyCode: currencyCode,
                          locale: locale,
                          label: null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          },
        ),
      ],
    );
  }
}

/// Single label rendered to the left of a row body (You / Family).
class _LabeledRow extends StatelessWidget {
  const _LabeledRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 64,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Text(
                label,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.wmTextSecondary,
                ),
              ),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _SoulCell extends StatelessWidget {
  const _SoulCell({
    required this.soul,
    required this.currencyCode,
    required this.locale,
    required this.label,
  });

  final SoulLedgerSnapshot soul;
  final String currencyCode;
  final Locale locale;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      color: context.wmSoulTagBg,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.wmTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            l10n.analyticsLedgerColumnSoul,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.soul),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.analyticsLedgerCellEntries(soul.entryCount),
            style: AppTextStyles.amountMedium.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormatter.formatCurrency(
              soul.totalSpend,
              currencyCode,
              locale,
            ),
            style: AppTextStyles.amountMedium.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Soul-only avg satisfaction row (D-03). D-04 ensures the symmetric
          // Survival cell has no such field — compile-time invariant.
          Text(
            l10n.analyticsLedgerCellAvgSat(
              soul.avgSatisfaction.toStringAsFixed(1),
            ),
            style: AppTextStyles.amountMedium.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurvivalCell extends StatelessWidget {
  const _SurvivalCell({
    required this.survival,
    required this.currencyCode,
    required this.locale,
    required this.label,
  });

  final SurvivalLedgerSnapshot survival;
  final String currencyCode;
  final Locale locale;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return Container(
      color: context.wmSurvivalTagBg,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.wmTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            l10n.analyticsLedgerColumnSurvival,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.survival),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.analyticsLedgerCellEntries(survival.entryCount),
            style: AppTextStyles.amountMedium.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            NumberFormatter.formatCurrency(
              survival.totalSpend,
              currencyCode,
              locale,
            ),
            style: AppTextStyles.amountMedium.copyWith(
              color: context.wmTextPrimary,
            ),
          ),
          // D-04: SurvivalLedgerSnapshot has no avgSatisfaction. No row here.
        ],
      ),
    );
  }
}

class _FamilyLoadingBody extends StatelessWidget {
  const _FamilyLoadingBody();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(8),
      child: SizedBox(
        height: 24,
        child: Center(child: LinearProgressIndicator()),
      ),
    );
  }
}

class _FamilyCaptionBody extends StatelessWidget {
  const _FamilyCaptionBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        message,
        style: AppTextStyles.caption.copyWith(color: context.wmTextSecondary),
      ),
    );
  }
}
