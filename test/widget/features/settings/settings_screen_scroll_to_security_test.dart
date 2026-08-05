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
import 'package:home_pocket/features/family_sync/presentation/widgets/family_sync_settings_section.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/presentation/providers/state_settings.dart';
import 'package:home_pocket/features/applock/presentation/screens/set_pin_screen.dart';
import 'package:home_pocket/features/settings/presentation/screens/settings_screen.dart';
import 'package:home_pocket/features/settings/presentation/widgets/backup_restore_navigation_section.dart';
import 'package:home_pocket/features/settings/presentation/widgets/delete_all_data_section.dart';
import 'package:home_pocket/features/settings/presentation/widgets/legal_sponsor_navigation_section.dart';
import 'package:home_pocket/features/settings/presentation/widgets/security_section.dart';
import 'package:home_pocket/features/settings/presentation/widgets/joy_target_section.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/shared/widgets/settings_section_card.dart';

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

Widget _pumpScreen({
  required bool scrollToSecurity,
  required AppDatabase db,
  // Phase 55 D-10: arriving via this deep-link with the lock NOT yet set now
  // auto-opens the set-PIN flow. The two original scroll-scope tests pin
  // `appLockEnabled: true` so that new behavior stays out of their assertions;
  // the dedicated D-10 test below exercises the auto-open with the default
  // (lock-not-set) settings.
  AppSettings settings = const AppSettings(appLockEnabled: true),
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      appSettingsProvider.overrideWith((ref) => Future.value(settings)),
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
  testWidgets('settings follows the V16 first-level hierarchy', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final db = AppDatabase.forTesting();
    addTearDown(db.close);

    await tester.pumpWidget(_pumpScreen(scrollToSecurity: false, db: db));
    await _pumpBounded(tester);

    final context = tester.element(find.byType(SettingsScreen));
    final l10n = S.of(context);
    final generalCard = find.byKey(const ValueKey('settings-general-section'));
    final family = find.text(l10n.settingsFamily);

    expect(generalCard, findsOneWidget);
    expect(family, findsOneWidget);
    final generalRows = <String>[
      l10n.appearance,
      l10n.language,
      l10n.voiceLanguage,
      l10n.settingsJoyTargetTitle,
      l10n.settingsWeekStart,
    ];
    for (final label in generalRows) {
      expect(
        find.descendant(of: generalCard, matching: find.text(label)),
        findsOneWidget,
      );
    }
    final generalTiles = find.descendant(
      of: generalCard,
      matching: find.byType(SettingsActionTile),
    );
    expect(generalTiles, findsNWidgets(generalRows.length));
    for (var index = 0; index < generalRows.length; index++) {
      expect(
        tester.getSize(generalTiles.at(index)).height,
        greaterThanOrEqualTo(72.0),
        reason: 'Settings rows must keep a comfortable mobile tap height',
      );
    }
    final rowTops = generalRows
        .map(
          (label) => tester
              .getTopLeft(
                find.descendant(of: generalCard, matching: find.text(label)),
              )
              .dy,
        )
        .toList();
    expect(rowTops, orderedEquals(rowTops.toList()..sort()));
    expect(find.byType(JoyTargetTile), findsOneWidget);

    final listView = tester.widget<ListView>(find.byType(ListView).first);
    final children =
        (listView.childrenDelegate as SliverChildListDelegate).children;
    int indexForKey(Key key) =>
        children.indexWhere((child) => child.key == key);
    int indexForType<T extends Widget>() =>
        children.indexWhere((child) => child is T);

    expect(indexForType<FamilySyncSettingsSection>(), greaterThan(0));
    expect(
      indexForKey(const ValueKey('settings-notifications-section')),
      equals(-1),
      reason: 'push notification settings are hidden in the first release',
    );
    expect(
      indexForType<BackupRestoreNavigationSection>(),
      greaterThan(indexForType<FamilySyncSettingsSection>()),
    );
    expect(
      indexForType<LegalSponsorNavigationSection>(),
      greaterThan(indexForType<BackupRestoreNavigationSection>()),
    );
    expect(
      indexForType<DeleteAllDataSection>(),
      greaterThan(indexForType<LegalSponsorNavigationSection>()),
    );
    expect(
      children.whereType<SettingsSectionCard>().where(
        (section) => section.key == const ValueKey('settings-general-section'),
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'scrollToSecurity: true brings SecuritySection into view after first frame',
    (tester) async {
      // A realistic phone viewport (matching the D-10 cases below) still leaves
      // the 8th SecuritySection well below the fold, so the deep-link scroll is
      // observable — but unlike a pathologically short 300px viewport it gives
      // the lazy ListView room to build the target's element so its GlobalKey
      // context exists for `ensureVisible` (the tile heights above it are not a
      // contract — a taller section like VoiceSection must not break this).
      tester.view.physicalSize = const Size(390, 844);
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
      expect(tileRect.top, lessThan(844));
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

  testWidgets(
    'scrollToSecurity + lock-not-set auto-opens the set-PIN flow (D-10)',
    (tester) async {
      // A tall viewport so the pushed SetPinScreen keypad has room.
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      await tester.pumpWidget(
        _pumpScreen(
          scrollToSecurity: true,
          db: db,
          // Fresh user: lock not yet configured -> D-10 should fire.
          settings: const AppSettings(),
        ),
      );
      await _pumpBounded(tester);

      // The deep-link landed on Security AND launched set-PIN directly.
      expect(find.byType(SetPinScreen), findsOneWidget);
    },
  );

  testWidgets(
    'scrollToSecurity with lock already set does NOT auto-open set-PIN (D-10)',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final db = AppDatabase.forTesting();
      addTearDown(db.close);

      await tester.pumpWidget(
        _pumpScreen(
          scrollToSecurity: true,
          db: db,
          settings: const AppSettings(appLockEnabled: true),
        ),
      );
      await _pumpBounded(tester);

      expect(find.byType(SetPinScreen), findsNothing);
    },
  );
}
