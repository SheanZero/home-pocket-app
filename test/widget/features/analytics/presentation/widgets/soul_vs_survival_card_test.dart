import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_ledger_snapshot.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/analytics_card_error_state.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/soul_vs_survival_card.dart';

import '../../../../../helpers/test_localizations.dart';

const _locale = Locale('ja');
const _currencyCode = 'JPY';
final _startDate = DateTime(2026, 5, 1);
final _endDate = DateTime(2026, 6, 1);
const _bookId = 'book-1';

SoulLedgerSnapshot _soul({
  int entryCount = 5,
  int totalSpend = 1500,
  double avgSat = 7.4,
}) => SoulLedgerSnapshot(
  entryCount: entryCount,
  totalSpend: totalSpend,
  avgSatisfaction: avgSat,
);

SurvivalLedgerSnapshot _survival({
  int entryCount = 8,
  int totalSpend = 12000,
}) => SurvivalLedgerSnapshot(entryCount: entryCount, totalSpend: totalSpend);

SoulVsSurvivalSnapshot _snapshot({
  SoulLedgerSnapshot? soul,
  SurvivalLedgerSnapshot? survival,
  SoulLedgerSnapshot? familySoul,
  SurvivalLedgerSnapshot? familySurvival,
}) => SoulVsSurvivalSnapshot(
  soul: soul ?? _soul(),
  survival: survival ?? _survival(),
  familySoul: familySoul,
  familySurvival: familySurvival,
);

Widget _buildSubject({required bool isGroupMode}) {
  return SoulVsSurvivalCard(
    bookId: _bookId,
    startDate: _startDate,
    endDate: _endDate,
    currencyCode: _currencyCode,
    locale: _locale,
    isGroupMode: isGroupMode,
  );
}

void main() {
  group('SoulVsSurvivalCard', () {
    testWidgets('renders solo two-column layout with Soul + Survival metrics',
        (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: false),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => Value(_snapshot(), 13),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Title visible
      expect(find.text('今期の家計簿'), findsOneWidget);
      // Column headers
      expect(find.text('ときめき'), findsOneWidget);
      expect(find.text('日常'), findsOneWidget);
      // Soul entries text + Survival entries text
      expect(find.text('5 件'), findsOneWidget);
      expect(find.text('8 件'), findsOneWidget);
      // Avg satisfaction line — appears ONLY in Soul column (D-04)
      expect(find.text('平均満足 7.4'), findsOneWidget);
      // Solo layout marker
      expect(find.byType(IntrinsicHeight), findsWidgets);
    });

    testWidgets('renders Empty caption (D-05) when provider returns Empty',
        (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: false),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => const Empty<SoulVsSurvivalSnapshot>(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('今期の家計簿'), findsOneWidget);
      expect(find.text('今期はデータがありません'), findsOneWidget);
      // No column header text on Empty
      expect(find.text('ときめき'), findsNothing);
      expect(find.text('生活'), findsNothing);
    });

    testWidgets('renders 2x2 grid in group mode when family is populated',
        (tester) async {
      final familySnapshot = _snapshot(
        soul: _soul(entryCount: 12, totalSpend: 3500, avgSat: 6.8),
        survival: _survival(entryCount: 18, totalSpend: 24000),
      );
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: true),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => Value(_snapshot(), 13),
            ),
            soulVsSurvivalSnapshotFamilyProvider(
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => Value(familySnapshot, 30),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('あなた'), findsOneWidget);
      expect(find.text('家族'), findsOneWidget);
      // You row entries
      expect(find.text('5 件'), findsOneWidget);
      expect(find.text('8 件'), findsOneWidget);
      // Family row entries
      expect(find.text('12 件'), findsOneWidget);
      expect(find.text('18 件'), findsOneWidget);
      // Avg sat appears in both Soul cells (You + Family) — D-04 confined to Soul
      expect(find.text('平均満足 7.4'), findsOneWidget);
      expect(find.text('平均満足 6.8'), findsOneWidget);
      // Family-empty caption should NOT appear
      expect(find.text('今期は家族データがありません'), findsNothing);
    });

    testWidgets('renders D-20 family-empty caption in group mode when family is Empty',
        (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: true),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => Value(_snapshot(), 13),
            ),
            soulVsSurvivalSnapshotFamilyProvider(
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith(
              (ref) async => const Empty<SoulVsSurvivalSnapshot>(),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // You row populated
      expect(find.text('あなた'), findsOneWidget);
      expect(find.text('5 件'), findsOneWidget);
      expect(find.text('8 件'), findsOneWidget);
      // Family row shows D-20 empty caption, no numeric values
      expect(find.text('今期は家族データがありません'), findsOneWidget);
      // No 2nd "12 件" or any family numeric
      expect(find.text('12 件'), findsNothing);
      expect(find.text('18 件'), findsNothing);
    });

    testWidgets(
      'renders whole card Empty (D-05) when single-book provider is Empty in group mode',
      (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _buildSubject(isGroupMode: true),
            locale: _locale,
            overrides: [
              soulVsSurvivalSnapshotProvider(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => const Empty<SoulVsSurvivalSnapshot>(),
              ),
              soulVsSurvivalSnapshotFamilyProvider(
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => Value(_snapshot(), 30),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('今期はデータがありません'), findsOneWidget);
        // No You / Family row labels
        expect(find.text('あなた'), findsNothing);
        expect(find.text('家族'), findsNothing);
      },
    );

    testWidgets('renders Loading placeholder while provider is loading',
        (tester) async {
      final completer = Completer<MetricResult<SoulVsSurvivalSnapshot>>();
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: false),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith((ref) => completer.future),
          ],
        ),
      );
      // Don't pumpAndSettle — provider is intentionally never-completing
      await tester.pump(const Duration(milliseconds: 100));

      // Title visible, but no column headers
      expect(find.text('今期の家計簿'), findsOneWidget);
      expect(find.text('ときめき'), findsNothing);
      expect(find.text('生活'), findsNothing);
      expect(find.text('今期はデータがありません'), findsNothing);

      completer.complete(const Empty<SoulVsSurvivalSnapshot>());
    });

    testWidgets('renders AnalyticsCardErrorState on error',
        (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          _buildSubject(isGroupMode: false),
          locale: _locale,
          overrides: [
            soulVsSurvivalSnapshotProvider(
              bookId: _bookId,
              startDate: _startDate,
              endDate: _endDate,
            ).overrideWith((ref) async => throw StateError('boom')),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsCardErrorState), findsOneWidget);
    });

    testWidgets(
      'D-04 invariant: avg satisfaction text appears exactly once in solo Value mode',
      (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _buildSubject(isGroupMode: false),
            locale: _locale,
            overrides: [
              soulVsSurvivalSnapshotProvider(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => Value(_snapshot(), 13),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // "平均満足" appears exactly ONCE — only on the Soul side (D-04)
        final avgSatFinder = find.textContaining('平均満足');
        expect(avgSatFinder, findsOneWidget);
      },
    );

    testWidgets(
      'group + family LOADING: family row shows skeleton, not Empty caption',
      (tester) async {
        final familyCompleter =
            Completer<MetricResult<SoulVsSurvivalSnapshot>>();
        await tester.pumpWidget(
          createLocalizedWidget(
            _buildSubject(isGroupMode: true),
            locale: _locale,
            overrides: [
              soulVsSurvivalSnapshotProvider(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => Value(_snapshot(), 13),
              ),
              soulVsSurvivalSnapshotFamilyProvider(
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith((ref) => familyCompleter.future),
            ],
          ),
        );
        // intentionally NOT pumpAndSettle — family stays in loading
        await tester.pump(const Duration(milliseconds: 100));

        // You row populated from resolved single-book provider
        expect(find.text('5 件'), findsOneWidget);
        expect(find.text('8 件'), findsOneWidget);

        // Family row shows skeleton — LinearProgressIndicator
        expect(find.byType(LinearProgressIndicator), findsWidgets);
        // Loading is NOT empty
        expect(find.text('今期は家族データがありません'), findsNothing);

        familyCompleter.complete(const Empty<SoulVsSurvivalSnapshot>());
      },
    );

    testWidgets(
      'group + family ERROR: family row shows error caption, not Empty caption or values',
      (tester) async {
        await tester.pumpWidget(
          createLocalizedWidget(
            _buildSubject(isGroupMode: true),
            locale: _locale,
            overrides: [
              soulVsSurvivalSnapshotProvider(
                bookId: _bookId,
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => Value(_snapshot(), 13),
              ),
              soulVsSurvivalSnapshotFamilyProvider(
                startDate: _startDate,
                endDate: _endDate,
              ).overrideWith(
                (ref) async => throw StateError('family fetch failed'),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();

        // You row populated
        expect(find.text('5 件'), findsOneWidget);
        expect(find.text('8 件'), findsOneWidget);
        // Error caption visible
        expect(find.text('家族データを取得できません'), findsOneWidget);
        // Family empty caption is NOT shown
        expect(find.text('今期は家族データがありません'), findsNothing);
      },
    );
  });
}
