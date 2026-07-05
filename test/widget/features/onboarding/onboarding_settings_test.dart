import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/profile/save_user_profile_use_case.dart';
import 'package:home_pocket/data/repositories/settings_repository_impl.dart';
import 'package:home_pocket/features/accounting/domain/models/book.dart';
import 'package:home_pocket/features/accounting/domain/repositories/book_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/onboarding/presentation/screens/onboarding_settings_screen.dart';
import 'package:home_pocket/features/profile/domain/models/user_profile.dart';
import 'package:home_pocket/features/profile/domain/repositories/user_profile_repository.dart';
import 'package:home_pocket/features/profile/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/settings/presentation/providers/repository_providers.dart';
import 'package:home_pocket/generated/app_localizations.dart';
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

class _Harness {
  _Harness({
    required this.overrides,
    required this.prefs,
    required this.bookRepo,
    required this.profileRepo,
  });

  final List<Override> overrides;
  final SharedPreferences prefs;
  final _FakeBookRepository bookRepo;
  final _FakeUserProfileRepository profileRepo;
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
  return _Harness(
    prefs: prefs,
    bookRepo: bookRepo,
    profileRepo: profileRepo,
    overrides: [
      sharedPreferencesProvider.overrideWith((_) => Future.value(prefs)),
      settingsRepositoryProvider.overrideWith(
        (_) => SettingsRepositoryImpl(prefs: prefs),
      ),
      bookRepositoryProvider.overrideWith((_) => bookRepo),
      saveUserProfileUseCaseProvider.overrideWith(
        (_) => SaveUserProfileUseCase(profileRepo),
      ),
    ],
  );
}

Widget _host({List<Override> overrides = const [], VoidCallback? onConfirmed}) {
  return ProviderScope(
    overrides: overrides,
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
  group('OnboardingSettingsScreen — design 04 re-skin (WELA-02)', () {
    testWidgets(
      'renders eyebrow, title, avatar block, inline name field, 4 language '
      'segments with info note, currency + voice rows and confirm button',
      (tester) async {
        await tester.pumpWidget(_host());
        await tester.pumpAndSettle();

        expect(find.text('最後のステップ'), findsOneWidget); // eyebrow
        expect(find.text('はじめる前に、\nすこしだけ設定を。'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('onboarding-avatar-block')),
          findsOneWidget,
        );
        expect(find.text('お名前'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget); // inline name field
        expect(find.text('表示言語'), findsOneWidget);
        // 4 language segments (the concrete labels can also appear as the
        // voice-row value depending on the host device locale — find by key).
        expect(
          find.byKey(const ValueKey('onboarding-lang-ja')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-lang-zh')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-lang-en')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('onboarding-lang-system')),
          findsOneWidget,
        );
        expect(find.text('自動'), findsOneWidget);
        expect(find.text('「自動」でも対象外の言語のときは、日本語で表示します。'), findsOneWidget);
        expect(find.text('通貨単位'), findsOneWidget);
        expect(find.textContaining('JPY'), findsOneWidget);
        expect(find.text('音声入力の言語'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'この設定ではじめる'), findsOneWidget);
        // The old dialog-based rows are gone.
        expect(find.text('未設定'), findsNothing);
        expect(find.text('変更'), findsNothing);
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

  group('OnboardingSettingsScreen — write-through on confirm', () {
    testWidgets(
      'tapping the English segment persists the concrete code (setLocale)',
      (tester) async {
        final harness = await _buildHarness(
          prefsSeed: const {'language': 'system'},
        );
        await tester.pumpWidget(_host(overrides: harness.overrides));
        await tester.pumpAndSettle();

        // Tap the English language segment directly (no dialog).
        await tester.tap(find.byKey(const ValueKey('onboarding-lang-en')));
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

      await tester.tap(find.byKey(const ValueKey('onboarding-lang-system')));
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
      },
    );
  });
}
