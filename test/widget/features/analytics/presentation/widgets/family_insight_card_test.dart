import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/analytics/domain/models/family_happiness.dart';
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/domain/models/shared_joy_insight.dart';
import 'package:home_pocket/features/analytics/presentation/widgets/family_insight_card.dart';

import '../../../../../helpers/test_localizations.dart';

void main() {
  const locale = Locale('ja');

  testWidgets('does not render when group mode is false', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithSharedJoy,
          isGroupMode: false,
          shadowBooks: [_shadowBook],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(_shrinkFinder(), findsOneWidget);
    expect(find.text('家族 · ハイライトサマリー'), findsNothing);
  });

  testWidgets('does not render when shadow books are empty', (tester) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithSharedJoy,
          isGroupMode: true,
          shadowBooks: [],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(_shrinkFinder(), findsOneWidget);
    expect(find.text('家族 · ハイライトサマリー'), findsNothing);
  });

  testWidgets('renders when group mode and shadow books are present', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithSharedJoy,
          isGroupMode: true,
          shadowBooks: [_shadowBook],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('家族 · ハイライトサマリー'), findsOneWidget);
  });

  testWidgets('renders highlights sentence from aggregate value', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithSharedJoy,
          isGroupMode: true,
          shadowBooks: [_shadowBook],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('家族のときめき 23回'), findsOneWidget);
  });

  testWidgets('renders shared joy sentence from aggregate tuple', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithSharedJoy,
          isGroupMode: true,
          shadowBooks: [_shadowBook],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('みんなで「食費」を楽しんでいます（5件、平均 8.2 / 10）'), findsOneWidget);
  });

  testWidgets('renders a custom shared category name instead of its id', (
    tester,
  ) async {
    final custom = Category(
      id: '01CUSTOMFAMILY',
      name: '家族旅行',
      icon: 'flight',
      color: '#8B5CF6',
      parentId: null,
      level: 1,
      createdAt: DateTime(2026),
    );
    const family = FamilyHappiness(
      year: 2026,
      month: 5,
      totalGroupJoyTx: 3,
      familyHighlightsSum: Value<int>(3, 3),
      sharedJoyInsight: Value<SharedJoyInsight>(
        SharedJoyInsight(
          categoryId: '01CUSTOMFAMILY',
          avgSatisfaction: 7,
          totalCount: 3,
        ),
        3,
      ),
      medianSatisfaction: Value<double>(7, 3),
    );

    await tester.pumpWidget(
      createLocalizedWidget(
        FamilyInsightCard(
          family: family,
          isGroupMode: true,
          shadowBooks: const [_shadowBook],
          locale: const Locale('zh'),
          sharedJoyCategory: custom,
        ),
        locale: const Locale('zh'),
      ),
    );

    expect(find.textContaining('家族旅行'), findsOneWidget);
    expect(find.textContaining(custom.id), findsNothing);
  });

  testWidgets('renders empty sentence when shared joy insight is empty', (
    tester,
  ) async {
    await tester.pumpWidget(
      createLocalizedWidget(
        const FamilyInsightCard(
          family: _familyWithoutSharedJoy,
          isGroupMode: true,
          shadowBooks: [_shadowBook],
          locale: locale,
        ),
        locale: locale,
      ),
    );

    expect(find.text('共通のお気に入り品目はまだ集計できません — もう少し記録してみよう'), findsOneWidget);
  });

  testWidgets(
    'renders the empty sentence only once when all insights are empty',
    (tester) async {
      await tester.pumpWidget(
        createLocalizedWidget(
          const FamilyInsightCard(
            family: _emptyFamily,
            isGroupMode: true,
            shadowBooks: [_shadowBook],
            locale: locale,
          ),
          locale: locale,
        ),
      );

      expect(find.text('共通のお気に入り品目はまだ集計できません — もう少し記録してみよう'), findsOneWidget);
    },
  );

  test('does not reference per-member identifiers', () {
    final source = File(
      'lib/features/analytics/presentation/widgets/family_insight_card.dart',
    ).readAsStringSync();

    expect(
      RegExp(
        'byMemberId|memberContribution|perMember',
        caseSensitive: false,
      ).hasMatch(source),
      isFalse,
    );
  });
}

Finder _shrinkFinder() {
  return find.byWidgetPredicate(
    (widget) => widget is SizedBox && widget.width == 0 && widget.height == 0,
  );
}

const _shadowBook = Object();

const _familyWithSharedJoy = FamilyHappiness(
  year: 2026,
  month: 5,
  totalGroupJoyTx: 30,
  familyHighlightsSum: Value<int>(23, 30),
  sharedJoyInsight: Value<SharedJoyInsight>(
    SharedJoyInsight(
      categoryId: 'cat_food',
      avgSatisfaction: 8.2,
      totalCount: 5,
    ),
    5,
  ),
  medianSatisfaction: Value<double>(8, 30),
);

const _familyWithoutSharedJoy = FamilyHappiness(
  year: 2026,
  month: 5,
  totalGroupJoyTx: 30,
  familyHighlightsSum: Value<int>(23, 30),
  sharedJoyInsight: Empty<SharedJoyInsight>(),
  medianSatisfaction: Value<double>(8, 30),
);

const _emptyFamily = FamilyHappiness(
  year: 2026,
  month: 5,
  totalGroupJoyTx: 0,
  familyHighlightsSum: Empty<int>(),
  sharedJoyInsight: Empty<SharedJoyInsight>(),
  medianSatisfaction: Empty<double>(),
);
