import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_lock_entry_screen.dart';
import 'package:home_pocket/features/settings/domain/models/app_settings.dart';
import 'package:home_pocket/features/settings/domain/repositories/settings_repository.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';

/// Records app-lock master-toggle writes so the skip path's explicit `false`
/// (D-02/D-13) can be asserted. Defaults `getSettings()` to the all-default
/// `AppSettings` (appLockEnabled == false) so the test exercises the real
/// default.
class _FakeSettingsRepository implements SettingsRepository {
  int setAppLockEnabledCalls = 0;
  bool? lastAppLockEnabledValue;
  int setBiometricLockCalls = 0;

  @override
  Future<void> setAppLockEnabled(bool enabled) async {
    setAppLockEnabledCalls++;
    lastAppLockEnabledValue = enabled;
  }

  @override
  Future<void> setBiometricLock(bool enabled) async {
    setBiometricLockCalls++;
  }

  @override
  Future<AppSettings> getSettings() async => const AppSettings();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

class _Capture {
  int calls = 0;
  bool? setupSecurity;

  void onComplete({required bool setupSecurity}) {
    calls++;
    this.setupSecurity = setupSecurity;
  }
}

Widget _host({
  required SettingsRepository repo,
  required void Function({required bool setupSecurity}) onComplete,
}) {
  return ProviderScope(
    overrides: [settingsRepositoryProvider.overrideWith((_) => repo)],
    child: MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: OnboardingLockEntryScreen(onComplete: onComplete),
    ),
  );
}

void main() {
  group('OnboardingLockEntryScreen — D-11 / D-13 / ONBOARD-06', () {
    testWidgets('renders the lock-entry title, description and two actions', (
      tester,
    ) async {
      final repo = _FakeSettingsRepository();
      final capture = _Capture();
      await tester.pumpWidget(
        _host(repo: repo, onComplete: capture.onComplete),
      );
      await tester.pumpAndSettle();

      expect(find.text('アプリロックを設定しますか？'), findsOneWidget);
      expect(find.text('アプリロックで、家計簿をさらに安全に守れます。'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'スキップ'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '今すぐ設定'), findsOneWidget);
    });

    testWidgets(
      'スキップ writes setAppLockEnabled(false) and completes setupSecurity:false '
      '(D-02/D-13 — explicit false on the new master toggle, legacy flag untouched)',
      (tester) async {
        final repo = _FakeSettingsRepository();
        final capture = _Capture();
        await tester.pumpWidget(
          _host(repo: repo, onComplete: capture.onComplete),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'スキップ'));
        await tester.pumpAndSettle();

        // Master lock forced OFF, exactly once; legacy flag never written.
        expect(repo.setAppLockEnabledCalls, 1);
        expect(repo.lastAppLockEnabledValue, false);
        expect(repo.setBiometricLockCalls, 0);
        // Completed with setupSecurity:false, exactly once.
        expect(capture.calls, 1);
        expect(capture.setupSecurity, false);
      },
    );

    testWidgets(
      '今すぐ設定 completes setupSecurity:true with NO biometric write',
      (tester) async {
        final repo = _FakeSettingsRepository();
        final capture = _Capture();
        await tester.pumpWidget(
          _host(repo: repo, onComplete: capture.onComplete),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, '今すぐ設定'));
        await tester.pumpAndSettle();

        // No lock write on the setup-now path (Phase 55 enables it).
        expect(repo.setAppLockEnabledCalls, 0);
        expect(repo.setBiometricLockCalls, 0);
        // Completed with setupSecurity:true, exactly once.
        expect(capture.calls, 1);
        expect(capture.setupSecurity, true);
      },
    );
  });
}
