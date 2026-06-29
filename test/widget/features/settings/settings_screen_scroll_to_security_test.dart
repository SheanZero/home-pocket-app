// Widget test for the SettingsScreen security deep-link target (D-13 / ONBOARD-06).
//
// Phase 54-03 makes the existing pushed `SettingsScreen` deep-linkable to its
// `SecuritySection` via an OPT-IN `scrollToSecurity` flag. This is the landing
// TARGET only; the onboarding lock-entry screen that triggers it is wired in
// 54-06, and Phase 55 fills the real PIN/biometric inside SecuritySection.
//
// Two cases:
//   - scrollToSecurity: true  → after the first frame the list scrolls so the
//     SecuritySection is brought into view (scroll offset > 0, section visible).
//   - scrollToSecurity: false → default render, no scroll side-effect (offset 0).
//
// Per CLAUDE.md Riverpod-3 rules the heavy screen providers are overridden with
// concrete async values; the real in-memory DB satisfies the lazy sub-section
// repos. Bounded pumping is used instead of `pumpAndSettle` because the family
// sync stream sections never settle (mirrors data_reset_refresh_test.dart).

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/data/app_database.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart'
    show bookByIdProvider;
import 'package:home_pocket/features/analytics/domain/models/metric_result.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_happiness.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_active_group.dart';
import 'package:home_pocket/features/family_sync/presentation/providers/state_sync.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/features/settings/presentation/screens/settings_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/security_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';

const _testBookId = 'book_settings_test';

Future<void> _pumpBounded(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

double _scrollOffset(WidgetTester tester) {
  final scrollable = find.byType(Scrollable).first;
  return tester.state<ScrollableState>(scrollable).position.pixels;
}

Widget _pumpScreen({required bool scrollToSecurity, required AppDatabase db}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      appSettingsProvider.overrideWith((ref) => Future.value(const AppSettings())),
      bookByIdProvider(bookId: _testBookId).overrideWith((ref) async => null),
      monthlyJoyTargetRecommendationProvider(
        bookId: _testBookId,
        currencyCode: 'JPY',
      ).overrideWith((ref) async => const Empty<int>()),
      // Bypass the real SyncEngine (it spawns a periodic status timer that
      // would leak past teardown) and the DB-watch group stream.
      syncStatusStreamProvider.overrideWith((ref) => const Stream.empty()),
      activeGroupProvider.overrideWith((ref) => Stream.value(null)),
    ],
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: SettingsScreen(
        bookId: _testBookId,
        scrollToSecurity: scrollToSecurity,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'scrollToSecurity: true brings SecuritySection into view after first frame',
    (tester) async {
      // A short viewport forces the (8th) SecuritySection off-screen so the
      // deep-link scroll is observable.
      tester.view.physicalSize = const Size(390, 300);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      await tester.pumpWidget(_pumpScreen(scrollToSecurity: true, db: db));
      await _pumpBounded(tester);

      // The deep-link scrolled the list down toward the SecuritySection.
      expect(
        _scrollOffset(tester),
        greaterThan(0),
        reason: 'ensureVisible should have scrolled the list off the top',
      );
      expect(find.byType(SecuritySection), findsOneWidget);

      // The security toggle is genuinely on-screen (within the viewport).
      final tileRect = tester.getRect(find.byType(SecuritySection));
      expect(tileRect.bottom, greaterThan(0));
      expect(tileRect.top, lessThan(300));
    },
  );

  testWidgets(
    'scrollToSecurity: false renders at the top with no scroll side-effect',
    (tester) async {
      tester.view.physicalSize = const Size(390, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      await tester.pumpWidget(_pumpScreen(scrollToSecurity: false, db: db));
      await _pumpBounded(tester);

      expect(
        _scrollOffset(tester),
        equals(0),
        reason: 'default behavior must not scroll',
      );
      expect(tester.takeException(), isNull);
    },
  );
}
