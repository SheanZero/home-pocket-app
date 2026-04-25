# TESTING

**Analysis Date:** 2026-04-25

## Test Framework

- **Runner:** `flutter_test` (sdk: flutter) — declared in `dev_dependencies` of `pubspec.yaml`
- **Mocking:**
  - `mockito: ^5.4.6` — codegen-based mocks via `@GenerateMocks([...])`, generates `*.mocks.dart` files
  - `mocktail: ^1.0.4` — runtime mocks via `class MockX extends Mock implements X {}` (no codegen)
  - Both libraries are used; choose based on file convention (mocktail is preferred for newer infrastructure tests)
- **Assertion library:** built-in `expect()` matchers from `package:flutter_test`

**Run commands (from `CLAUDE.md`):**
```bash
flutter test                         # Run all tests
flutter test --coverage              # Generate coverage/lcov.info, ≥80% required
flutter test path/to/specific_test.dart    # Single file
flutter test test/unit/                    # Single directory
```

After modifying mocks (adding `@GenerateMocks`):
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Test File Organization

**Location:** `test/` mirrors `lib/` structure. There are **183 test files** covering **268 source files**.

**Top-level layout:**
```
test/
├── application/        # Cross-feature application services (legacy location)
├── core/               # Theme tests
├── data/               # Repository impl tests (use AppDatabase.forTesting)
├── features/           # Feature-level tests
├── helpers/            # Shared test utilities
│   └── test_localizations.dart    # createLocalizedWidget(...)
├── infrastructure/     # Crypto, security, sync tests
├── integration/        # Multi-component integration tests
│   └── sync/           # E2E sync round-trip tests
├── unit/               # Mirrored lib/ subtree for pure-unit tests
│   ├── application/
│   ├── core/
│   ├── data/
│   ├── features/
│   ├── infrastructure/
│   └── shared/
├── widget/             # Widget tests (testWidgets)
│   └── features/
└── widget_test.dart    # Default Flutter scaffold test
```

**Naming:** every test file ends with `_test.dart`. Mockito-generated mocks live alongside as `<basename>_test.mocks.dart`.

## Test Structure

Standard pattern (`test/unit/application/accounting/delete_transaction_use_case_test.dart`):
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/delete_transaction_use_case.dart';
import 'package:home_pocket/features/accounting/domain/repositories/transaction_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository])
import 'delete_transaction_use_case_test.mocks.dart';

void main() {
  late MockTransactionRepository mockRepo;
  late DeleteTransactionUseCase useCase;

  setUp(() {
    mockRepo = MockTransactionRepository();
    useCase = DeleteTransactionUseCase(transactionRepository: mockRepo);
  });

  group('DeleteTransactionUseCase', () {
    test('soft-deletes an existing transaction', () async {
      when(mockRepo.findById('tx_001')).thenAnswer((_) async => Transaction(...));
      when(mockRepo.softDelete('tx_001')).thenAnswer((_) async {});

      final result = await useCase.execute('tx_001');

      expect(result.isSuccess, isTrue);
      verify(mockRepo.softDelete('tx_001')).called(1);
    });

    test('returns error when transaction not found', () async {
      when(mockRepo.findById('nonexistent')).thenAnswer((_) async => null);
      final result = await useCase.execute('nonexistent');
      expect(result.isError, isTrue);
      expect(result.error, contains('not found'));
      verifyNever(mockRepo.softDelete(any));
    });
  });
}
```

**Patterns:**
- `late` + `setUp(() { ... })` for fresh fixtures per test
- `tearDown(() async { ... })` to dispose AppDatabase, sockets, etc.
- `group(...)` to nest related cases by method or scenario
- Each `test`/`testWidgets` does Arrange → Act → Assert
- `expect(result.isSuccess, isTrue)` style — assert on `Result.isSuccess` / `isError` / `error` for use cases
- Verify mock interactions with `verify(...).called(N)` and `verifyNever(...)`

## Mocking

**Mockito (codegen) — used for: domain repositories, use case dependencies.**

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([TransactionRepository, FieldEncryptionService, GroupRepository])
import 'my_test.mocks.dart';

// Then:
final mock = MockTransactionRepository();
when(mock.findById('id')).thenAnswer((_) async => txn);
when(mock.softDelete('id')).thenAnswer((_) async {});
verify(mock.softDelete('id')).called(1);
verifyNever(mock.findById(any));
```

Multiple mocks in one annotation: `@GenerateMocks([FieldEncryptionService, GroupRepository])` (see `test/integration/sync/bill_sync_round_trip_test.dart`).

**Mocktail (runtime) — used for: infrastructure layer, services with `Fake` types.**

```dart
import 'package:mocktail/mocktail.dart';

class MockKeyRepository extends Mock implements KeyRepository {}
class FakeSignature extends Fake implements Signature {}

void main() {
  late MockKeyRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(FakeSignature());
    registerFallbackValue(<int>[]);
  });

  setUp(() {
    mockRepo = MockKeyRepository();
  });

  test('delegates to repository', () async {
    when(() => mockRepo.hasKeyPair()).thenAnswer((_) async => true);
    expect(await keyManager.hasKeyPair(), true);
    verify(() => mockRepo.hasKeyPair()).called(1);
  });
}
```

Note the parenthesized `() => mock.method()` syntax — this is mocktail's signature, distinct from mockito's bare `mock.method()`.

Pattern source: `test/infrastructure/crypto/services/key_manager_test.dart`.

**What to mock:**
- Repository interfaces (`TransactionRepository`, `KeyRepository`, `GroupRepository`)
- Infrastructure services with side effects (`FieldEncryptionService`, `KeyManager`)
- External SDK clients (push messaging, websocket)

**What NOT to mock:**
- The class under test
- Pure data classes (`Result`, Freezed models) — construct them directly
- `AppDatabase` — use `AppDatabase.forTesting()` instead (real in-memory SQLite)

## In-Memory Database

For repository / DAO tests, use the real Drift database against an in-memory SQLite (`lib/data/app_database.dart` line 42):

```dart
AppDatabase.forTesting() : super(NativeDatabase.memory());
```

Pattern (`test/data/repositories/group_repository_impl_test.dart`):
```dart
late AppDatabase database;
late GroupRepositoryImpl repository;

setUp(() {
  database = AppDatabase.forTesting();
  repository = GroupRepositoryImpl(
    groupDao: GroupDao(database),
    memberDao: GroupMemberDao(database),
  );
});

tearDown(() async {
  await database.close();
});
```

This is preferred over mocking DAOs — it exercises real SQL, indices, and constraints.

## Widget Tests

Use `testWidgets`. For widgets requiring localization, wrap in the shared helper at `test/helpers/test_localizations.dart`:

```dart
Widget createLocalizedWidget(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.supportedLocales,
      home: child,
    ),
  );
}
```

Usage:
```dart
await tester.pumpWidget(createLocalizedWidget(
  const MyWidget(),
  overrides: [
    someProvider.overrideWithValue(fakeValue),
  ],
));
```

Simple widget tests not needing localization use plain `MaterialApp`:
```dart
testWidgets('MemberListTile shows display name, role, and emoji avatar', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: MemberListTile(...))),
  );
  expect(find.textContaining('太郎'), findsOneWidget);
});
```

(See `test/widget/features/family_sync/presentation/widgets/member_list_tile_test.dart`.)

For animation testing, advance time with `await tester.pump(const Duration(milliseconds: 1600));` (see `test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart`).

## Provider Overrides

Use `ProviderScope(overrides: [...])` (or `UncontrolledProviderScope`) to inject test doubles. The `createLocalizedWidget` helper accepts an `overrides` list for this exact purpose. Typical pattern:
```dart
ProviderScope(
  overrides: [
    transactionRepositoryProvider.overrideWithValue(mockRepo),
    appDatabaseProvider.overrideWithValue(testDatabase),
  ],
  child: MyWidget(),
)
```

## Coverage

**Requirement:** ≥ 80% (per `CLAUDE.md` and `.claude/rules/testing.md`).

**Generate:**
```bash
flutter test --coverage
```

Output: `coverage/lcov.info`. (The `coverage/` directory exists at project root.)

View locally:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Types

- **Unit tests** — `test/unit/` — pure logic with mocked dependencies. Use mockito or mocktail. Example: `test/unit/shared/utils/result_test.dart`.
- **Repository / DAO tests** — `test/data/`, `test/unit/data/` — use `AppDatabase.forTesting()` for real SQLite. Example: `test/data/repositories/group_repository_impl_test.dart`.
- **Infrastructure tests** — `test/infrastructure/` — crypto, security, sync. Mix mocktail mocks with real services.
- **Widget tests** — `test/widget/` — `testWidgets(...)` with `createLocalizedWidget` helper. Example: `test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart`.
- **Integration tests** — `test/integration/sync/` — multi-component round-trip (sync, websocket). Example: `test/integration/sync/bill_sync_round_trip_test.dart` exercises ApplySyncOperationsUseCase + ShadowBookService + repositories with mocked encryption + mocked group repository.
- **E2E tests** — None observed (no Patrol or `integration_test` package configured at the time of analysis). The `.claude/rules/testing.md` mentions Playwright but that targets the global rule set, not this Flutter project.

## Common Patterns

**Async testing:**
```dart
test('loads transactions', () async {
  when(mock.findAll()).thenAnswer((_) async => [tx1, tx2]);
  final result = await useCase.execute();
  expect(result.length, 2);
});
```

**Result-based assertions:**
```dart
final result = await useCase.execute('');
expect(result.isError, isTrue);
expect(result.error, contains('not found'));
```

**Mockito argument matchers:**
```dart
when(mockEncryption.encryptField(any)).thenAnswer(
  (invocation) async => invocation.positionalArguments.first as String,
);
verifyNever(mockRepo.softDelete(any));
```

**Mocktail fallback registration (required for `any()` of complex types):**
```dart
setUpAll(() {
  registerFallbackValue(FakeSignature());
  registerFallbackValue(<int>[]);
});
```

**TDD workflow** (per `.claude/rules/testing.md`):
1. Write failing test (RED)
2. Run `flutter test` — confirm failure
3. Write minimal implementation (GREEN)
4. Re-run — confirm pass
5. Refactor (IMPROVE) — re-run between each refactor step
6. `flutter test --coverage` — verify 80%+ coverage

## Files Referenced

- `pubspec.yaml`
- `CLAUDE.md`
- `.claude/rules/testing.md`
- `lib/data/app_database.dart`
- `test/helpers/test_localizations.dart`
- `test/unit/application/accounting/delete_transaction_use_case_test.dart`
- `test/unit/shared/utils/result_test.dart`
- `test/infrastructure/crypto/services/key_manager_test.dart`
- `test/data/repositories/group_repository_impl_test.dart`
- `test/integration/sync/bill_sync_round_trip_test.dart`
- `test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart`
- `test/widget/features/family_sync/presentation/widgets/member_list_tile_test.dart`
