import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/application/security/app_lock_service.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/applock/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/applock/presentation/screens/set_pin_screen.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/profile/presentation/widgets/avatar_display.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
import 'package:home_pocket/infrastructure/security/biometric_service.dart';
import 'package:home_pocket/infrastructure/security/providers.dart';
import 'package:home_pocket/shared/constants/avatar_icon_ids.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records the currency written through on currency-row selection.
class _FakeBookRepository implements BookRepository {
  _FakeBookRepository(this._book);

  Book _book;
  String? lastUpdatedCurrency;

  @override
  Future<Book?> findById(String id) async => _book.id == id ? _book : null;

  @override
  Future<void> update(Book book) async {
    _book = book;
    lastUpdatedCurrency = book.currency;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory profile repository that records the saved profile.
class _FakeUserProfileRepository implements UserProfileRepository {
  UserProfile? saved;

  @override
  Future<UserProfile?> find() async => saved;

  @override
  Future<void> save(UserProfile profile) async {
    saved = profile;
  }

  @override
  Future<void> delete(String id) async {}
}

class _MockAppLockService extends Mock implements AppLockService {}

class _Harness {
  _Harness({
    required this.overrides,
    required this.prefs,
    required this.bookRepo,
    required this.profileRepo,
    required this.appLockService,
  });

  final List<Override> overrides;
  final SharedPreferences prefs;
  final _FakeBookRepository bookRepo;
  final _FakeUserProfileRepository profileRepo;
  final _MockAppLockService appLockService;
}

Book _testBook() => Book(
  id: 'book-1',
  name: 'Home',
  currency: 'JPY',
  deviceId: 'device-1',
  createdAt: DateTime(2026, 1, 1),
);

Future<_Harness> _buildHarness({
  Map<String, Object> prefsSeed = const {'language': 'system'},
}) async {
  SharedPreferences.setMockInitialValues(prefsSeed);
  final prefs = await SharedPreferences.getInstance();
  final bookRepo = _FakeBookRepository(_testBook());
  final profileRepo = _FakeUserProfileRepository();
  final appLockService = _MockAppLockService();
  when(() => appLockService.disableLock()).thenAnswer((_) async {});
  when(() => appLockService.setPin(any())).thenAnswer((_) async {});
  return _Harness(
    prefs: prefs,
    bookRepo: bookRepo,
    profileRepo: profileRepo,
    appLockService: appLockService,
    overrides: [
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
      bookRepositoryProvider.overrideWith((_) => bookRepo),
      saveUserProfileUseCaseProvider.overrideWith(
        (_) => SaveUserProfileUseCase(profileRepo),
      ),
      appLockServiceProvider.overrideWithValue(appLockService),
    ],
  );
}

Widget _host({List<Override> overrides = const [], VoidCallback? onConfirmed}) {
  return ProviderScope(
    overrides: [
      biometricAvailabilityProvider.overrideWith(
        (_) async => BiometricAvailability.faceId,
      ),
      ...overrides,
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
      home: OnboardingSettingsScreen(
        bookId: 'book-1',
        onConfirmed: onConfirmed ?? () {},
      ),
    ),
  );
}

/// Enters [name] into the inline nickname TextField (design 04 — the
/// tap-to-dialog editor is gone).
Future<void> _setNickname(WidgetTester tester, String name) async {
  await tester.enterText(find.byType(TextField).first, name);
  await tester.pumpAndSettle();
}

void main() {
  group('OnboardingSettingsScreen — V16 foundation layout', () {
    testWidgets(
      'renders compact profile editor, unified preference card, security card '
      'and confirm dock',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        expect(find.text('初期設定'), findsNothing);
        expect(find.text('最後のステップ'), findsOneWidget); // eyebrow
        expect(find.text('基本設定'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding-avatar-block')),
          findsOneWidget,
        );
        final avatar = tester.widget<AvatarDisplay>(
          find.descendant(
            of: find.byKey(const ValueKey('onboarding-avatar-block')),
            matching: find.byType(AvatarDisplay),
          ),
        );
        expect(avatarIconIds, contains(avatar.emoji));
        expect(find.byKey(ValueKey(avatar.emoji)), findsOneWidget);
        expect(avatar.imagePath, isNull);
        expect(find.text('画像を変更'), findsOneWidget);
        expect(find.text('お名前・必須'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // inline name field
        expect(
          find.byKey(const ValueKey('onboarding-language-row')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-currency-row')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-voice-row')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-security-card')),
          findsOneWidget,
        );
        expect(find.widgetWithText(TextButton, 'この設定ではじめる'), findsOneWidget);
      },
    );
  });

  group('OnboardingSettingsScreen — D-14 nickname gate', () {
    testWidgets('start button is disabled until a nickname is set', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(TextButton, 'この設定ではじめる');
      expect(buttonFinder, findsOneWidget);

      final button = tester.widget<TextButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });

    testWidgets('start button enables once a non-empty nickname is entered', (
      tester,
    ) async {
      await tester.pumpWidget(_host());
      await tester.pumpAndSettle();

      await _setNickname(tester, 'たけし');

      final buttonFinder = find.widgetWithText(TextButton, 'この設定ではじめる');
      final button = tester.widget<TextButton>(buttonFinder);
      expect(button.onPressed, isNotNull);
    });
  });

  group('OnboardingSettingsScreen — V16 security disclosure', () {
    testWidgets(
      'security off hides methods and shows the quiet later-setup message',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        expect(find.text('今は設定せず、あとで決める'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding-security-biometric')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('onboarding-security-pin')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'enabling security hides the defer message and reveals biometric first',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('onboarding-security-toggle')),
        );
        await tester.pumpAndSettle();

        expect(find.text('今は設定せず、あとで決める'), findsNothing);
        expect(
          find.byKey(const ValueKey('onboarding-security-biometric')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-security-pin')),
          findsOneWidget,
        );
        expect(find.text('おすすめ'), findsOneWidget);
      },
    );

    testWidgets(
      'PIN choice expands setup guidance and keeps start disabled until '
      'double-entry completes',
      (tester) async {
        final harness = await _buildHarness();
        await tester.pumpWidget(_host(overrides: harness.overrides));
        await tester.pumpAndSettle();
        await _setNickname(tester, 'たけし');
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('onboarding-security-toggle')),
        );
        await tester.pumpAndSettle();
        final pinMethod = find.byKey(const ValueKey('onboarding-security-pin'));
        await tester.ensureVisible(pinMethod);
        await tester.pumpAndSettle();
        await tester.tap(pinMethod);
        await tester.pumpAndSettle();

        expect(find.text('PINがまだ設定されていません'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'この設定ではじめる'))
              .onPressed,
          isNull,
        );

        final setupPin = find.text('4桁のPINを設定');
        await tester.ensureVisible(setupPin);
        await tester.pumpAndSettle();
        await tester.tap(setupPin);
        await tester.pumpAndSettle();
        expect(find.byType(SetPinScreen), findsOneWidget);

        for (final pin in const ['1234', '1234']) {
          for (final digit in pin.split('')) {
            await tester.tap(find.text(digit));
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        expect(find.byType(SetPinScreen), findsNothing);
        expect(find.text('PINを設定しました'), findsOneWidget);
        expect(
          tester
              .widget<TextButton>(find.widgetWithText(TextButton, 'この設定ではじめる'))
              .onPressed,
          isNotNull,
        );
        verify(() => harness.appLockService.setPin('1234')).called(1);
      },
    );

    testWidgets(
      'biometric choice provisions a PIN fallback before arming the lock',
      (tester) async {
        final harness = await _buildHarness();
        var confirmed = false;
        await tester.pumpWidget(
          _host(
            overrides: harness.overrides,
            onConfirmed: () => confirmed = true,
          ),
        );
        await tester.pumpAndSettle();
        await _setNickname(tester, 'たけし');
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pumpAndSettle();
        await tester.tap(
          find.byKey(const ValueKey('onboarding-security-toggle')),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.widgetWithText(TextButton, 'この設定ではじめる'));
        await tester.pumpAndSettle();
        expect(find.byType(SetPinScreen), findsOneWidget);

        for (final pin in const ['1234', '1234']) {
          for (final digit in pin.split('')) {
            await tester.tap(find.text(digit));
            await tester.pump();
          }
          await tester.pumpAndSettle();
        }

        expect(confirmed, isTrue);
        expect(harness.prefs.getBool('app_lock_enabled'), isTrue);
        expect(harness.prefs.getBool('biometric_unlock_enabled'), isTrue);
        verify(() => harness.appLockService.setPin('1234')).called(1);
      },
    );
  });

  group('OnboardingSettingsScreen — write-through on confirm', () {
    testWidgets(
      'tapping the English segment persists the concrete code (setLocale)',
      (tester) async {
        final harness = await _buildHarness(
          prefsSeed: const {'language': 'system'},
        );
        await tester.pumpWidget(_host(overrides: harness.overrides));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('onboarding-language-row')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('onboarding-language-en')));
        await tester.pumpAndSettle();

        // setLocale persisted 'en' — never the 'system' sentinel.
        expect(harness.prefs.getString('language'), 'en');
      },
    );

    testWidgets('tapping the 自動 segment re-persists the system sentinel', (
      tester,
    ) async {
      final harness = await _buildHarness(prefsSeed: const {'language': 'ja'});
      await tester.pumpWidget(_host(overrides: harness.overrides));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('onboarding-language-row')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('onboarding-language-system')),
      );
      await tester.pumpAndSettle();

      expect(harness.prefs.getString('language'), 'system');
    });

    testWidgets('currency selection writes Book.currency via bookRepo.update', (
      tester,
    ) async {
      final harness = await _buildHarness();
      await tester.pumpWidget(_host(overrides: harness.overrides));
      await tester.pumpAndSettle();

      // Open the currency selector from the currency row and pick USD.
      await tester.tap(find.byKey(const ValueKey('onboarding-currency-row')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('currency-row-USD')));
      await tester.pumpAndSettle();

      expect(harness.bookRepo.lastUpdatedCurrency, 'USD');
      expect(find.textContaining('USD'), findsOneWidget);
    });

    testWidgets(
      'confirm: untouched language → setSystemDefault, concrete voice, '
      'fires onConfirmed',
      (tester) async {
        // Seed a non-system language to prove confirm re-asserts 'system'
        // when the row is left untouched (D-08).
        final harness = await _buildHarness(
          prefsSeed: const {'language': 'ja'},
        );
        var confirmed = false;
        await tester.pumpWidget(
          _host(
            overrides: harness.overrides,
            onConfirmed: () => confirmed = true,
          ),
        );
        await tester.pumpAndSettle();

        await _setNickname(tester, 'たけし');

        await tester.tap(find.widgetWithText(TextButton, 'この設定ではじめる'));
        await tester.pumpAndSettle();

        // onConfirmed fired only on save success.
        expect(confirmed, isTrue);
        // Profile was saved with the entered nickname.
        expect(harness.profileRepo.saved?.displayName, 'たけし');
        // Untouched language row → setSystemDefault persisted 'system' (D-08).
        expect(harness.prefs.getString('language'), 'system');
        // Voice default resolved to a concrete ja/zh/en code, NEVER 'system'
        // (D-09 / ONBOARD-05, Pitfall 4).
        final voice = harness.prefs.getString('voice_language');
        expect(voice, isNotNull);
        expect(voice, isNot('system'));
        expect(const {'ja', 'zh', 'en'}.contains(voice), isTrue);
        verify(() => harness.appLockService.disableLock()).called(1);
      },
    );
  });
}
