# MOD-009 Voice Input - Implementation Plan v2

**Created:** 2026-02-22
**Reviewed by:** Agent B (Senior Architect)
**Based on:** docs/arch/02-module-specs/MOD-009_VoiceInput.md
**Supersedes:** docs/plans/2026-02-22-voice-input-implementation-plan.md
**Methodology:** TDD (RED → GREEN → REFACTOR)
**Estimated Duration:** 8 days

---

## Architecture Review Summary (Agent B)

### CRITICAL Issues Fixed

**CRITICAL-1: `MerchantMatch` type placement violates domain isolation**
Agent A's plan placed `MerchantMatch` inside `lib/features/accounting/domain/models/voice_parse_result.dart`. This is wrong. `MerchantMatch` is a return type of `MerchantDatabase`, which lives in `lib/infrastructure/ml/`. Domain models must have ZERO dependency on infrastructure. Placing `MerchantMatch` in domain creates a prohibited upward dependency.

Correction: `MerchantMatch` is defined inside `lib/infrastructure/ml/merchant_database.dart` (as a plain Dart class, not Freezed). The voice domain model `VoiceParseResult` stores `String? merchantName` and `String? merchantCategoryId` as plain fields — it does NOT hold a `MerchantMatch` reference. The application layer (`ParseVoiceInputUseCase`) resolves the `MerchantMatch` at execution time and maps it to the domain-safe fields.

**CRITICAL-2: `CategoryService` constructor requires TWO repositories**
Agent A's plan shows `CategoryMatcher` calling `CategoryService.resolveLedgerType()` but does not account for `CategoryService`'s actual constructor signature:
```dart
CategoryService({
  required CategoryRepository categoryRepository,
  required CategoryLedgerConfigRepository ledgerConfigRepository,
})
```
The provider in `voice_providers.dart` must therefore use `categoryServiceProvider` (already defined in `use_case_providers.dart`) rather than constructing a new `CategoryService` — which Agent A's plan fortunately does, but the test mock for `CategoryService` must match the full interface.

**CRITICAL-3: `@freezed` Dart 3+ syntax — existing codebase uses `abstract class`**
The spec (MOD-009) shows `@freezed abstract class VoiceParseResult with _$VoiceParseResult`. The project's existing Freezed models (confirmed by reading `transaction.dart`, `category.dart`, `book.dart`) already use this syntax:
```dart
@freezed
abstract class Transaction with _$Transaction { ... }
```
Agent A's plan is CORRECT on this point. The `@freezed` annotation goes on the line above, and the class is `abstract`. No correction needed here — this is noted as confirmed correct.

**CRITICAL-4: `voice_providers.dart` must NOT redefine `categoryServiceProvider`**
Agent A's plan imports `use_case_providers.dart` and calls `ref.watch(categoryServiceProvider)` — this is correct. However, the plan must NOT define a new `CategoryService` provider inside `voice_providers.dart`. The single source of truth for `categoryServiceProvider` is `use_case_providers.dart`. Confirmed correct in Agent A's plan.

**CRITICAL-5: `MerchantDatabase` does NOT currently exist**
Agent A correctly identifies this: `lib/infrastructure/ml/` directory does not exist. However, Agent A's plan then places `MerchantMatch` in the DOMAIN layer as a workaround — this is the wrong fix. The correct approach is to define both `MerchantDatabase` and `MerchantMatch` in `lib/infrastructure/ml/merchant_database.dart`. The domain model `VoiceParseResult` must not reference `MerchantMatch` directly.

### HIGH Issues Fixed

**HIGH-1: `voice_providers.dart` provider function signatures use deprecated `Ref` type**
Agent A's plan shows:
```dart
@Riverpod(keepAlive: true)
MerchantDatabase merchantDatabase(Ref ref) { ... }

@riverpod
VoiceTextParser voiceTextParser(Ref ref) { ... }
```
Examining the existing codebase (`repository_providers.dart`, `use_case_providers.dart`), the correct signature pattern is `(Ref ref)` with the unparameterized `Ref` from `flutter_riverpod`. This is correct. No change needed.

**HIGH-2: `SpeechRecognitionService` uses `dart:io` Platform check — this breaks unit tests**
The `_normalizeSoundLevel()` method uses `Platform.isAndroid` which calls into `dart:io`. The plan's test-visible `normalizeSoundLevelForTest(double, {required bool isAndroid})` workaround is the correct pattern. No change needed on this point.

**HIGH-3: `categoryServiceProvider` is in `use_case_providers.dart`, NOT `repository_providers.dart`**
Agent A correctly imports from `use_case_providers.dart` for `categoryServiceProvider`. Confirmed correct.

**HIGH-4: `voice_providers.dart` uses relative imports — must be consistent with existing codebase style**
Examining `repository_providers.dart` and `use_case_providers.dart`, the project uses relative imports (e.g., `'../../../../data/daos/book_dao.dart'`). Agent A's plan uses relative imports too. Correct.

**HIGH-5: `TransactionConfirmScreen` does NOT have `initialMerchant` or `initialSatisfaction` parameters**
Confirmed by reading the actual file: the constructor only accepts `bookId`, `amount`, `category`, `parentCategory?`, `date`. Agent A's Phase 5.1 plan to add `String? initialMerchant` and `int? initialSatisfaction` is architecturally sound but requires explicit implementation steps. The corrected plan makes these steps more precise.

### MEDIUM Issues Found (Non-blocking)

**MEDIUM-1: `VoiceParsePreview` hardcodes `¥` currency symbol in test**
The widget test (`voice_parse_preview_test.dart`) checks `find.textContaining('680')`. The widget itself should use `NumberFormatter.formatCurrency(amount, 'JPY', locale)` as specified. The test uses `textContaining('680')` which is locale-agnostic — this is acceptable.

**MEDIUM-2: Test file 1.2 Category model constructor is missing `createdAt`**
The `Category` Freezed model has `required DateTime createdAt`. The test's `fakeCategory` construction is missing it:
```dart
final fakeCategory = Category(
  id: 'cat_food', name: '食事', icon: '🍜',
  color: '#FF0000', level: 1, sortOrder: 0, isArchived: false,
);
```
This will fail compilation. The correction adds `createdAt: DateTime(2026, 1, 1)`.

**MEDIUM-3: `ClassificationService` provider import in `voice_providers.dart`**
Agent A imports from `use_case_providers.dart` for `categoryServiceProvider`. However, `classificationServiceProvider` (from `lib/application/dual_ledger/providers.dart`) is not needed by voice providers directly — the Voice module bypasses auto-classification and sets `ledgerType` explicitly. Confirmed: no import of `classificationServiceProvider` needed.

**MEDIUM-4: No worklog directory verification**
Agent A's plan says "Create worklog at `docs/worklog/YYYYMMDD_HHMM_implement_voice_input_module.md`" but the target directory is `docs/worklog/` (confirmed exists from git status listing). Non-blocking.

### Confirmed Correct in Agent A's Plan

- Clean Architecture layer placement: domain models in `lib/features/accounting/domain/models/`, use cases in `lib/application/voice/`, infrastructure in `lib/infrastructure/speech/` — CORRECT.
- "Thin Feature" rule compliance: voice features/ only contains domain/ and presentation/ — CORRECT.
- Provider single source of truth: all repository providers come from `repository_providers.dart` — CORRECT.
- `@riverpod` annotation with code generation for all providers — CORRECT.
- `build_runner` called after every Freezed model creation — CORRECT.
- Platform permission configuration (iOS Info.plist, Android AndroidManifest.xml) — CORRECT.
- `speech_to_text: ^7.0.0` placement in pubspec.yaml (does not touch sqlcipher_flutter_libs) — CORRECT.
- `SpeechRecognitionService` instantiated directly in `VoiceInputScreen` (not from provider, stateful lifecycle) — CORRECT.
- `MerchantDatabase` as a plain Dart class (no Riverpod, no Freezed) — CORRECT.
- `VoiceSatisfactionEstimator` as a pure Dart class — CORRECT.
- `Result<T>` reuse from `lib/shared/utils/result.dart` — CORRECT.
- `LedgerType` imported from `lib/features/accounting/domain/models/transaction.dart` — CORRECT.
- `categoryServiceProvider` comes from `use_case_providers.dart` — CORRECT.
- `categoryRepositoryProvider` comes from `repository_providers.dart` — CORRECT.

### Reality Checks Applied

1. **`CategoryService.resolveLedgerType()`** — EXISTS with correct signature `Future<LedgerType?> resolveLedgerType(String categoryId)`. Returns nullable `LedgerType?`. Test mocks must use `thenAnswer((_) async => LedgerType.survival)`.

2. **`MerchantDatabase`** — Does NOT exist. `lib/infrastructure/ml/` directory is entirely absent. The plan to create it from scratch is correct.

3. **`voice_input_screen.dart`** — EXISTS as a `StatefulWidget` stub (not ConsumerStatefulWidget). The plan to replace it with `ConsumerStatefulWidget` is correct.

4. **`TransactionConfirmScreen` constructor** — Confirmed: `{required bookId, required amount, required category, parentCategory?, required date}`. No `initialMerchant` or `initialSatisfaction` yet — must be added in Phase 5.

5. **`Result<T>` in `lib/shared/utils/result.dart`** — EXISTS. Has `Result.success(T? data)` and `Result.error(String message)`. Access via `result.data`, `result.error`, `result.isSuccess`.

6. **`Category` model** — Confirmed requires `createdAt: DateTime` (required field). Tests must include it.

7. **`appDatabaseProvider`** — Defined in `lib/infrastructure/security/providers.dart` (throws `UnimplementedError` by default, overridden at app startup). The `voice_providers.dart` does not need to reference it directly — repository providers handle that.

8. **`categoryServiceProvider`** — Confirmed in `use_case_providers.g.dart` as `AutoDisposeProvider<CategoryService>`.

9. **Freezed syntax** — `@freezed\nabstract class X with _$X { ... }` pattern confirmed in `transaction.dart`, `category.dart`, `book.dart`. This is Freezed 3.x syntax and is already used consistently.

---

## Overview

This plan implements the MOD-009 Voice Input module for the Home Pocket accounting app. The module allows users to create transactions through natural language voice input, extracting amounts, merchants, and categories automatically.

**Key architecture decisions:**

- `VoiceInputScreen` already exists as a static stub at `lib/features/accounting/presentation/screens/voice_input_screen.dart` — replaced with full implementation
- `CategoryService` at `lib/application/accounting/category_service.dart` provides `resolveLedgerType()` — reused by `CategoryMatcher` via the existing `categoryServiceProvider`
- `ClassificationService` at `lib/application/dual_ledger/classification_service.dart` — NOT directly used by voice; `VoiceInputScreen` passes `ledgerType` explicitly
- `TransactionConfirmScreen` at `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` — receives `bookId`, `amount`, `category`, `parentCategory?`, `date`. Optional `initialMerchant` and `initialSatisfaction` will be added in Phase 5.
- `Result<T>` at `lib/shared/utils/result.dart` — reused by use cases
- `LedgerType` enum is defined in `lib/features/accounting/domain/models/transaction.dart`
- `CategoryRepository` interface at `lib/features/accounting/domain/repositories/category_repository.dart`
- `lib/infrastructure/ml/` directory does NOT exist yet — `MerchantDatabase` and `MerchantMatch` must be created there

**CORRECTION vs Agent A's plan:** `MerchantMatch` is defined in `lib/infrastructure/ml/merchant_database.dart` (infrastructure layer), NOT in `lib/features/accounting/domain/models/voice_parse_result.dart`. The domain `VoiceParseResult` stores extracted data as plain primitive fields (`merchantName`, `merchantCategoryId`, `merchantLedgerType`).

---

## Prerequisites & Verification

Before starting, verify these conditions are true:

1. `lib/features/accounting/presentation/screens/voice_input_screen.dart` exists (static stub) — confirmed
2. `lib/application/dual_ledger/classification_service.dart` exists — confirmed
3. `lib/application/accounting/category_service.dart` exists with `resolveLedgerType(String categoryId)` returning `Future<LedgerType?>` — confirmed
4. `lib/features/accounting/domain/repositories/category_repository.dart` exists — confirmed
5. `lib/shared/utils/result.dart` exists with `Result<T>` — confirmed
6. `LedgerType` enum is in `lib/features/accounting/domain/models/transaction.dart` — confirmed
7. `lib/infrastructure/ml/` directory does NOT exist — create it
8. `flutter pub run build_runner build` runs successfully on the current codebase
9. `flutter analyze` shows zero issues on the current codebase

---

## Phase 0: Setup (Day 1 Morning)

### Step 0.1 — Add speech_to_text dependency to pubspec.yaml

Edit `/Users/xinz/Development/home-pocket-app/pubspec.yaml`.

Add `speech_to_text: ^7.0.0` in the `dependencies:` block after the existing Unique ID entry and before the Charts entry, like this:

```yaml
  # Unique ID Generation
  ulid: ^2.0.0

  # Voice Input
  speech_to_text: ^7.0.0

  # Charts
  fl_chart: ^0.69.0
```

Then run:
```bash
flutter pub get
```

### Step 0.2 — iOS platform configuration

Edit `ios/Runner/Info.plist`. Add these two keys inside the root `<dict>`:

```xml
<key>NSSpeechRecognitionUsageDescription</key>
<string>音声で金額や取引内容を入力するために使用します</string>
<key>NSMicrophoneUsageDescription</key>
<string>音声入力のためにマイクへのアクセスが必要です</string>
```

### Step 0.3 — Android platform configuration

Edit `android/app/src/main/AndroidManifest.xml`. Add these entries before the `<application>` tag:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>

<queries>
  <intent>
    <action android:name="android.speech.RecognitionService"/>
  </intent>
</queries>
```

### Step 0.4 — Create directory structure

```bash
mkdir -p lib/infrastructure/ml
mkdir -p lib/infrastructure/speech
mkdir -p lib/application/voice
mkdir -p test/unit/infrastructure/speech
mkdir -p test/unit/application/voice
mkdir -p test/widget/features/accounting/presentation/screens
mkdir -p test/widget/features/accounting/presentation/widgets
mkdir -p test/unit/features/accounting/domain/models
mkdir -p test/unit/features/accounting/presentation/providers
```

---

## Phase 1: RED — Write Tests First (Day 1–2)

All test files are written BEFORE any implementation code. Running `flutter test` at this stage should show compilation errors or test failures for all new tests. That is the expected RED state.

### Test File 1.1 — VoiceTextParser unit tests

**Path:** `test/unit/application/voice/voice_text_parser_test.dart`

**What it tests:**
- `extractAmount()` with Arabic numerals: `680円`, `¥1,280`, `480块`, `550 yen`, standalone `3980`
- `extractAmount()` returns null when no amount is present
- `extractAmount()` with kanji numerals: `六百八十円`, `千二百円`, `三千九百八十`, `一千二百元`
- Amount boundary: value of 0 returns null, value of 10,000,000 or more returns null

This file has NO external dependencies beyond `VoiceTextParser` itself. No mocks needed.

```dart
// test/unit/application/voice/voice_text_parser_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';

void main() {
  late VoiceTextParser parser;

  setUp(() {
    parser = VoiceTextParser();
  });

  group('VoiceTextParser - Arabic amount extraction', () {
    test('extracts yen with 円 suffix: 680円', () {
      expect(parser.extractAmount('昼ごはんに680円'), equals(680));
    });

    test('extracts yen with ¥ prefix: ¥1,280', () {
      expect(parser.extractAmount('マクドナルドで¥1,280'), equals(1280));
    });

    test('extracts yuan with 块 suffix: 480块', () {
      expect(parser.extractAmount('午饭480块'), equals(480));
    });

    test('extracts yen with "yen" suffix: 550 yen', () {
      expect(parser.extractAmount('lunch 550 yen'), equals(550));
    });

    test('extracts standalone number >= 3 digits: 3980', () {
      expect(parser.extractAmount('ユニクロで3980'), equals(3980));
    });

    test('returns null when no amount present', () {
      expect(parser.extractAmount('昼ごはん食べた'), isNull);
    });

    test('returns null for amount of zero', () {
      expect(parser.extractAmount('0円'), isNull);
    });

    test('extracts comma-formatted amount: 1,280円', () {
      expect(parser.extractAmount('1,280円'), equals(1280));
    });
  });

  group('VoiceTextParser - Kanji amount extraction', () {
    test('extracts 六百八十円 -> 680', () {
      expect(parser.extractAmount('六百八十円'), equals(680));
    });

    test('extracts 千二百円 -> 1200', () {
      expect(parser.extractAmount('千二百円'), equals(1200));
    });

    test('extracts 三千九百八十 -> 3980', () {
      expect(parser.extractAmount('三千九百八十'), equals(3980));
    });

    test('extracts 一千二百元 -> 1200', () {
      expect(parser.extractAmount('一千二百元'), equals(1200));
    });
  });
}
```

### Test File 1.2 — CategoryMatcher unit tests

**Path:** `test/unit/application/voice/category_matcher_test.dart`

**CORRECTION vs Agent A's plan:** The `Category` model requires `createdAt: DateTime`. The `fakeCategory` construction was missing this required field and would fail compilation. This is fixed below.

**What it tests:**
- Japanese keyword -> food category match with confidence > 0.8: `昼ごはん`
- Chinese keyword -> food category match: `午饭`
- English keyword -> food category match: `lunch`
- Transport keyword match: `電車`, `地铁`, `train`
- No match returns null: `abc123`
- `resolveLedgerType()` delegates correctly to `CategoryService`

Uses `mockito` `@GenerateMocks` for `CategoryRepository` and `CategoryService`.

```dart
// test/unit/application/voice/category_matcher_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/category_matcher.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryRepository, CategoryService])
import 'category_matcher_test.mocks.dart';

void main() {
  late MockCategoryRepository mockCategoryRepo;
  late MockCategoryService mockCategoryService;
  late CategoryMatcher matcher;

  // CORRECTION: Category requires createdAt (DateTime) — it is a required field.
  final fakeCategory = Category(
    id: 'cat_food',
    name: '食事',
    icon: '🍜',
    color: '#FF0000',
    level: 1,
    sortOrder: 0,
    isArchived: false,
    createdAt: DateTime(2026, 1, 1),
  );

  setUp(() {
    mockCategoryRepo = MockCategoryRepository();
    mockCategoryService = MockCategoryService();
    matcher = CategoryMatcher(
      categoryRepository: mockCategoryRepo,
      categoryService: mockCategoryService,
    );
    when(mockCategoryRepo.findById(any))
        .thenAnswer((_) async => fakeCategory);
  });

  group('CategoryMatcher - keyword matching', () {
    test('Japanese 昼ごはん matches cat_food with confidence > 0.8', () async {
      final result = await matcher.matchFromText('昼ごはんに680円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
      expect(result.confidence, greaterThan(0.8));
    });

    test('Chinese 午饭 matches cat_food', () async {
      final result = await matcher.matchFromText('午饭吃了480块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('English lunch matches cat_food', () async {
      final result = await matcher.matchFromText('lunch 550 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_food'));
    });

    test('Japanese 電車 matches cat_transport', () async {
      final result = await matcher.matchFromText('電車代320円');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('Chinese 地铁 matches cat_transport', () async {
      final result = await matcher.matchFromText('坐地铁花了280块');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('English train matches cat_transport', () async {
      final result = await matcher.matchFromText('train pass 320 yen');
      expect(result, isNotNull);
      expect(result!.categoryId, contains('cat_transport'));
    });

    test('No match returns null', () async {
      when(mockCategoryRepo.findById(any)).thenAnswer((_) async => null);
      final result = await matcher.matchFromText('abc123');
      expect(result, isNull);
    });
  });

  group('CategoryMatcher - ledger type resolution', () {
    test('delegates resolveLedgerType to CategoryService', () async {
      when(mockCategoryService.resolveLedgerType('cat_food'))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await matcher.resolveLedgerType('cat_food');
      expect(result, equals(LedgerType.survival));
      verify(mockCategoryService.resolveLedgerType('cat_food')).called(1);
    });
  });
}
```

### Test File 1.3 — VoiceSatisfactionEstimator unit tests

**Path:** `test/unit/application/voice/voice_satisfaction_estimator_test.dart`

**CORRECTION vs Agent A's plan:** This test imports `VoiceAudioFeatures` from `lib/features/accounting/domain/models/voice_parse_result.dart`. That is correct — `VoiceAudioFeatures` is a domain model. No change to this test.

```dart
// test/unit/application/voice/voice_satisfaction_estimator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/voice_satisfaction_estimator.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

List<DateTime> _generateTimestamps(int count, {int intervalMs = 200}) {
  final start = DateTime.now().subtract(Duration(milliseconds: count * intervalMs));
  return List.generate(
    count,
    (i) => start.add(Duration(milliseconds: i * intervalMs)),
  );
}

void main() {
  late VoiceSatisfactionEstimator estimator;

  setUp(() {
    estimator = VoiceSatisfactionEstimator();
  });

  group('VoiceSatisfactionEstimator', () {
    test('excited voice with positive words -> satisfaction 7-10', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.7, 0.8, 0.6, 0.9, 0.7, 0.8, 0.9, 0.7],
        timestamps: _generateTimestamps(8, intervalMs: 200),
        startTime: DateTime.now().subtract(const Duration(seconds: 8)),
        endTime: DateTime.now(),
        partialResultCount: 6,
        wordCount: 15,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: 'ユニクロで服買った、めっちゃ嬉しい！',
      );

      expect(score, greaterThanOrEqualTo(7));
      expect(score, lessThanOrEqualTo(10));
    });

    test('calm voice with neutral text -> satisfaction 4-6', () {
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.35, 0.3, 0.32, 0.3],
        timestamps: _generateTimestamps(5, intervalMs: 400),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '電車代320円',
      );

      expect(score, greaterThanOrEqualTo(4));
      expect(score, lessThanOrEqualTo(6));
    });

    test('empty audio features -> default satisfaction 3-5', () {
      final features = VoiceAudioFeatures(
        soundLevels: [],
        timestamps: [],
        startTime: DateTime.now(),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 0,
      );

      final score = estimator.estimate(
        audioFeatures: features,
        recognizedText: '',
      );

      expect(score, greaterThanOrEqualTo(3));
      expect(score, lessThanOrEqualTo(5));
    });

    test('score is always in range 1-10', () {
      final highFeatures = VoiceAudioFeatures(
        soundLevels: List.filled(50, 1.0),
        timestamps: _generateTimestamps(50, intervalMs: 100),
        startTime: DateTime.now().subtract(const Duration(seconds: 20)),
        endTime: DateTime.now(),
        partialResultCount: 20,
        wordCount: 40,
      );
      final highScore = estimator.estimate(
        audioFeatures: highFeatures,
        recognizedText: 'めっちゃ最高！嬉しい！すごい！',
      );
      expect(highScore, inInclusiveRange(1, 10));

      final lowFeatures = VoiceAudioFeatures(
        soundLevels: [0.01, 0.01],
        timestamps: _generateTimestamps(2, intervalMs: 500),
        startTime: DateTime.now().subtract(const Duration(seconds: 2)),
        endTime: DateTime.now(),
        partialResultCount: 0,
        wordCount: 1,
      );
      final lowScore = estimator.estimate(
        audioFeatures: lowFeatures,
        recognizedText: '高い無駄だった後悔',
      );
      expect(lowScore, inInclusiveRange(1, 10));
    });

    test('negative sentiment words reduce score', () {
      final neutralFeatures = VoiceAudioFeatures(
        soundLevels: [0.4, 0.4, 0.4],
        timestamps: _generateTimestamps(3, intervalMs: 300),
        startTime: DateTime.now().subtract(const Duration(seconds: 3)),
        endTime: DateTime.now(),
        partialResultCount: 2,
        wordCount: 5,
      );

      final neutralScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '昼ごはん680円',
      );

      final negativeScore = estimator.estimate(
        audioFeatures: neutralFeatures,
        recognizedText: '高い、無駄だった、後悔してる',
      );

      expect(negativeScore, lessThan(neutralScore));
    });
  });
}
```

### Test File 1.4 — ParseVoiceInputUseCase unit tests

**Path:** `test/unit/application/voice/parse_voice_input_use_case_test.dart`

**CORRECTION vs Agent A's plan:** The test uses `MerchantMatch` — since `MerchantMatch` is now in `lib/infrastructure/ml/merchant_database.dart`, the import path changes. Also, `result.data!.merchantMatch` no longer exists in `VoiceParseResult` — instead the domain model stores `merchantName` and `merchantCategoryId` as plain strings. The test is rewritten to reflect the corrected domain model.

```dart
// test/unit/application/voice/parse_voice_input_use_case_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/voice/parse_voice_input_use_case.dart';
import 'package:home_pocket/application/voice/category_matcher.dart';
import 'package:home_pocket/application/voice/voice_text_parser.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/infrastructure/ml/merchant_database.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([CategoryMatcher, MerchantDatabase])
import 'parse_voice_input_use_case_test.mocks.dart';

void main() {
  late MockCategoryMatcher mockCategoryMatcher;
  late MockMerchantDatabase mockMerchantDatabase;
  late VoiceTextParser parser;
  late ParseVoiceInputUseCase useCase;

  setUp(() {
    mockCategoryMatcher = MockCategoryMatcher();
    mockMerchantDatabase = MockMerchantDatabase();
    parser = VoiceTextParser();

    useCase = ParseVoiceInputUseCase(
      textParser: parser,
      categoryMatcher: mockCategoryMatcher,
      merchantDatabase: mockMerchantDatabase,
    );
  });

  group('ParseVoiceInputUseCase', () {
    test('parses amount correctly from text with 円', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any))
          .thenAnswer((_) async => const CategoryMatchResult(
                categoryId: 'cat_food',
                confidence: 0.9,
                source: MatchSource.keyword,
              ));
      when(mockCategoryMatcher.resolveLedgerType(any))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('昼ごはんに680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, equals(680));
      expect(result.data!.rawText, equals('昼ごはんに680円'));
    });

    test('merchant match overrides keyword category', () async {
      // CORRECTION: MerchantMatch is from lib/infrastructure/ml/merchant_database.dart.
      // VoiceParseResult.merchantName is a plain String? (no MerchantMatch reference).
      final merchantMatch = MerchantMatch(
        merchantName: 'マクドナルド',
        categoryId: 'cat_food',
        confidence: 0.95,
        ledgerType: LedgerType.survival,
      );
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(merchantMatch);

      final result = await useCase.execute('マクドナルドで680円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.merchantName, equals('マクドナルド'));
      // CORRECTION: categoryMatch.source should be MatchSource.merchant
      expect(result.data!.categoryMatch!.source, equals(MatchSource.merchant));
      // CategoryMatcher.matchFromText should NOT be called when merchant found
      verifyNever(mockCategoryMatcher.matchFromText(any));
    });

    test('falls back to keyword match when no merchant found', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any))
          .thenAnswer((_) async => const CategoryMatchResult(
                categoryId: 'cat_transport',
                confidence: 0.95,
                source: MatchSource.keyword,
              ));
      when(mockCategoryMatcher.resolveLedgerType(any))
          .thenAnswer((_) async => LedgerType.survival);

      final result = await useCase.execute('電車代320円');

      expect(result.isSuccess, isTrue);
      expect(result.data!.categoryMatch!.source, equals(MatchSource.keyword));
    });

    test('returns success with nulls when text has no recognizable content', () async {
      when(mockMerchantDatabase.findMerchant(any)).thenReturn(null);
      when(mockCategoryMatcher.matchFromText(any)).thenAnswer((_) async => null);

      final result = await useCase.execute('test');

      expect(result.isSuccess, isTrue);
      expect(result.data!.amount, isNull);
      // CORRECTION: no merchantMatch field — check merchantName instead
      expect(result.data!.merchantName, isNull);
      expect(result.data!.categoryMatch, isNull);
    });
  });
}
```

### Test File 1.5 — SpeechRecognitionService unit tests

**Path:** `test/unit/infrastructure/speech/speech_recognition_service_test.dart`

No corrections needed from Agent A's plan. Reproduced as-is.

```dart
// test/unit/infrastructure/speech/speech_recognition_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/infrastructure/speech/speech_recognition_service.dart';

void main() {
  group('SpeechRecognitionService - initial state', () {
    test('isListening is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isListening, isFalse);
    });

    test('isAvailable is false before initialize', () {
      final service = SpeechRecognitionService();
      expect(service.isAvailable, isFalse);
    });

    test('stopListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.stopListening(), completes);
    });

    test('cancelListening does not throw when not initialized', () async {
      final service = SpeechRecognitionService();
      await expectLater(service.cancelListening(), completes);
    });
  });

  group('SpeechRecognitionService - sound level normalization', () {
    test('normalizeSoundLevel clamps within 0.0-1.0 for Android values', () {
      final service = SpeechRecognitionService();
      expect(service.normalizeSoundLevelForTest(15.0, isAndroid: true), equals(1.0));
      expect(service.normalizeSoundLevelForTest(5.0, isAndroid: true), equals(0.5));
      expect(service.normalizeSoundLevelForTest(-1.0, isAndroid: true), equals(0.0));
    });

    test('normalizeSoundLevel clamps within 0.0-1.0 for iOS values', () {
      final service = SpeechRecognitionService();
      expect(service.normalizeSoundLevelForTest(0.0, isAndroid: false), equals(1.0));
      expect(service.normalizeSoundLevelForTest(-25.0, isAndroid: false), equals(0.5));
      expect(service.normalizeSoundLevelForTest(-60.0, isAndroid: false), equals(0.0));
    });
  });
}
```

### Test File 1.6 — VoiceParseResult model tests

**Path:** `test/unit/features/accounting/domain/models/voice_parse_result_test.dart`

**CORRECTION vs Agent A's plan:** `VoiceParseResult` no longer has a `merchantMatch` field (that was a `MerchantMatch` reference to infrastructure). The domain model stores `merchantName?: String?`. The test is corrected accordingly.

```dart
// test/unit/features/accounting/domain/models/voice_parse_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/accounting/domain/models/voice_parse_result.dart';

void main() {
  group('VoiceParseResult', () {
    test('can be instantiated with rawText only', () {
      const result = VoiceParseResult(rawText: 'test text');
      expect(result.rawText, equals('test text'));
      expect(result.amount, isNull);
      expect(result.merchantName, isNull);
      // CORRECTION: no merchantMatch field in domain model
    });

    test('estimatedSatisfaction defaults to 5', () {
      const result = VoiceParseResult(rawText: 'test');
      expect(result.estimatedSatisfaction, equals(5));
    });

    test('copyWith works correctly', () {
      const original = VoiceParseResult(rawText: 'original', amount: 100);
      final copy = original.copyWith(amount: 200);
      expect(copy.rawText, equals('original'));
      expect(copy.amount, equals(200));
    });
  });

  group('VoiceAudioFeatures', () {
    test('can be instantiated with all required fields', () {
      final now = DateTime.now();
      final features = VoiceAudioFeatures(
        soundLevels: [0.3, 0.5, 0.7],
        timestamps: [now, now.add(const Duration(milliseconds: 100))],
        startTime: now,
        endTime: now.add(const Duration(seconds: 3)),
        partialResultCount: 2,
        wordCount: 5,
      );
      expect(features.soundLevels, hasLength(3));
      expect(features.wordCount, equals(5));
    });
  });

  group('CategoryMatchResult', () {
    test('stores categoryId, confidence, and source', () {
      const matchResult = CategoryMatchResult(
        categoryId: 'cat_food',
        confidence: 0.90,
        source: MatchSource.keyword,
      );
      expect(matchResult.categoryId, equals('cat_food'));
      expect(matchResult.confidence, equals(0.90));
      expect(matchResult.source, equals(MatchSource.keyword));
    });
  });

  group('MatchSource', () {
    test('has all three values', () {
      expect(MatchSource.values, containsAll([
        MatchSource.merchant,
        MatchSource.keyword,
        MatchSource.fallback,
      ]));
    });
  });
}
```

### Test Files 1.7, 1.8, 1.9 — Widget tests

No corrections needed from Agent A's plan. Use exactly as specified in the original plan.

- `test/widget/features/accounting/presentation/widgets/voice_waveform_test.dart`
- `test/widget/features/accounting/presentation/widgets/voice_transcript_card_test.dart`
- `test/widget/features/accounting/presentation/widgets/voice_parse_preview_test.dart`

Refer to Agent A's original plan for these test file contents — they are correct as written.

### Test File 1.10 — voice_providers integration test

**Path:** `test/unit/features/accounting/presentation/providers/voice_providers_test.dart`

No corrections needed from Agent A's plan.

---

## Phase 2: GREEN — Domain & Infrastructure (Day 2–3)

Implement in this exact order. After each step, run `flutter analyze` to verify zero issues.

### Step 2.1 — Create VoiceParseResult domain model

**File:** `lib/features/accounting/domain/models/voice_parse_result.dart`

**CRITICAL CORRECTION vs Agent A's plan:** `VoiceParseResult` must NOT hold a `MerchantMatch` field. `MerchantMatch` belongs to `lib/infrastructure/ml/`. Domain models must have zero infrastructure dependencies.

Instead, `VoiceParseResult` stores extracted primitive data:
- `String? merchantName` — the matched merchant name (string only)
- `String? merchantCategoryId` — the category ID from merchant match (string only)
- `LedgerType? merchantLedgerType` — the ledger type from merchant match

The Freezed syntax follows the existing project pattern (`@freezed\nabstract class ... with _$...`).

```dart
// lib/features/accounting/domain/models/voice_parse_result.dart

import 'package:freezed_annotation/freezed_annotation.dart';

import 'transaction.dart';

part 'voice_parse_result.freezed.dart';

/// Result of parsing a voice input into structured transaction data.
///
/// Holds all extracted fields as primitives — no infrastructure types.
/// [merchantName], [merchantCategoryId], [merchantLedgerType] store the
/// results of merchant lookup without referencing MerchantMatch directly.
@freezed
abstract class VoiceParseResult with _$VoiceParseResult {
  const factory VoiceParseResult({
    required String rawText,
    int? amount,
    // Merchant fields stored as primitives (no MerchantMatch reference)
    String? merchantName,
    String? merchantCategoryId,
    LedgerType? merchantLedgerType,
    // Category keyword match
    CategoryMatchResult? categoryMatch,
    // Resolved ledger type (from merchant or category)
    LedgerType? ledgerType,
    @Default(5) int estimatedSatisfaction,
  }) = _VoiceParseResult;
}

/// Result of matching a category from voice text keywords.
@freezed
abstract class CategoryMatchResult with _$CategoryMatchResult {
  const factory CategoryMatchResult({
    required String categoryId,
    required double confidence,
    required MatchSource source,
  }) = _CategoryMatchResult;
}

/// How the category match was derived.
enum MatchSource {
  merchant,  // matched via MerchantDatabase
  keyword,   // matched via keyword map
  fallback,  // default fallback
}

/// Audio features collected during voice recording.
///
/// Used by [VoiceSatisfactionEstimator] to estimate satisfaction score.
@freezed
abstract class VoiceAudioFeatures with _$VoiceAudioFeatures {
  const factory VoiceAudioFeatures({
    required List<double> soundLevels,
    required List<DateTime> timestamps,
    required DateTime startTime,
    required DateTime endTime,
    required int partialResultCount,
    required int wordCount,
  }) = _VoiceAudioFeatures;
}
```

After creating this file, run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify `voice_parse_result.freezed.dart` is generated.

Note: Do NOT add `fromJson`/`toJson` unless you need JSON serialization for this model. Existing models like `Transaction` include it; for a pure in-memory voice model it is optional. If you add it, add `part 'voice_parse_result.g.dart';` and `factory VoiceParseResult.fromJson(...)` accordingly.

### Step 2.2 — Create MerchantDatabase and MerchantMatch

**File:** `lib/infrastructure/ml/merchant_database.dart`

**CRITICAL CORRECTION vs Agent A's plan:** `MerchantMatch` is defined HERE in the infrastructure layer, not in domain models. This is the single source of truth.

```dart
// lib/infrastructure/ml/merchant_database.dart

import '../../../features/accounting/domain/models/transaction.dart';

/// A merchant match result from the MerchantDatabase lookup.
///
/// Defined in infrastructure (lib/infrastructure/ml/) because it is the
/// return type of MerchantDatabase — an infrastructure component.
/// Domain models (VoiceParseResult) store merchant data as primitives
/// to avoid upward infrastructure -> domain dependency violations.
class MerchantMatch {
  final String merchantName;
  final String categoryId;
  final double confidence;
  final LedgerType ledgerType;

  const MerchantMatch({
    required this.merchantName,
    required this.categoryId,
    required this.confidence,
    required this.ledgerType,
  });
}

/// A seed entry in the merchant database.
class _MerchantEntry {
  final String name;
  final List<String> aliases;
  final String categoryId;
  final LedgerType ledgerType;

  const _MerchantEntry({
    required this.name,
    required this.aliases,
    required this.categoryId,
    required this.ledgerType,
  });
}

/// Merchant lookup database.
///
/// Provides fuzzy merchant matching for voice and OCR modules.
/// This is the shared infrastructure — used by MOD-004 OCR and MOD-009 Voice.
///
/// Current implementation: seed data (~20 well-known Japanese merchants).
/// Full 500+ merchant list is a backlog item.
class MerchantDatabase {
  static const List<_MerchantEntry> _entries = [
    _MerchantEntry(
      name: 'マクドナルド',
      aliases: ['マック', 'Mac', 'McDonald'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'スターバックス',
      aliases: ['スタバ', 'Starbucks'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: '吉野家',
      aliases: ['Yoshinoya'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'セブンイレブン',
      aliases: ['セブン', '7-Eleven', '7-11'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'ファミリーマート',
      aliases: ['ファミマ', 'FamilyMart'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'ローソン',
      aliases: ['Lawson'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'ユニクロ',
      aliases: ['Uniqlo', 'UNIQLO'],
      categoryId: 'cat_shopping',
      ledgerType: LedgerType.soul,
    ),
    _MerchantEntry(
      name: 'ニトリ',
      aliases: ['Nitori'],
      categoryId: 'cat_housing',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'ヤマダ電機',
      aliases: ['ヤマダ', 'Yamada'],
      categoryId: 'cat_shopping',
      ledgerType: LedgerType.soul,
    ),
    _MerchantEntry(
      name: 'すき家',
      aliases: ['Sukiya'],
      categoryId: 'cat_food',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'ドラッグストア',
      aliases: ['薬局', 'pharmacy'],
      categoryId: 'cat_medical',
      ledgerType: LedgerType.survival,
    ),
    _MerchantEntry(
      name: 'Amazon',
      aliases: ['アマゾン', 'amazon'],
      categoryId: 'cat_shopping',
      ledgerType: LedgerType.soul,
    ),
  ];

  /// Find a merchant by name, alias, or substring match.
  ///
  /// Tries exact name match first, then alias match, then substring match.
  /// Returns the first match or null if none found.
  MerchantMatch? findMerchant(String query) {
    if (query.isEmpty) return null;

    final lowerQuery = query.toLowerCase();

    // 1. Exact name match
    for (final entry in _entries) {
      if (entry.name.toLowerCase() == lowerQuery) {
        return _toMatch(entry);
      }
    }

    // 2. Alias match
    for (final entry in _entries) {
      for (final alias in entry.aliases) {
        if (alias.toLowerCase() == lowerQuery) {
          return _toMatch(entry);
        }
      }
    }

    // 3. Substring match (query contains entry name, or entry name contains query)
    for (final entry in _entries) {
      if (lowerQuery.contains(entry.name.toLowerCase()) ||
          entry.name.toLowerCase().contains(lowerQuery)) {
        return _toMatch(entry);
      }
    }

    return null;
  }

  MerchantMatch _toMatch(_MerchantEntry entry) {
    return MerchantMatch(
      merchantName: entry.name,
      categoryId: entry.categoryId,
      confidence: 0.90,
      ledgerType: entry.ledgerType,
    );
  }
}
```

This file does NOT use Riverpod or Freezed — it is a pure Dart class.

### Step 2.3 — Create SpeechRecognitionService infrastructure

**File:** `lib/infrastructure/speech/speech_recognition_service.dart`

Implement exactly as defined in the MOD-009 spec section "1. 语音识别服务封装". Add the test-visible method:

```dart
/// Exposed for unit testing only. Do not call in production code.
@visibleForTesting
double normalizeSoundLevelForTest(double rawLevel, {required bool isAndroid}) {
  if (isAndroid) {
    return (rawLevel / 10.0).clamp(0.0, 1.0);
  } else {
    return ((rawLevel + 50.0) / 50.0).clamp(0.0, 1.0);
  }
}
```

Import: `package:flutter/foundation.dart` for `@visibleForTesting`.

The private `_normalizeSoundLevel()` uses `Platform.isAndroid` for production (import `dart:io`).

After this step, run:
```bash
flutter test test/unit/infrastructure/speech/speech_recognition_service_test.dart
```

---

## Phase 3: GREEN — Application Layer (Day 3–5)

### Step 3.1 — Create VoiceTextParser

**File:** `lib/application/voice/voice_text_parser.dart`

Implement exactly as defined in the MOD-009 spec section "NLP解析引擎 -> 金额提取".

**CORRECTION vs Agent A's plan:** `VoiceTextParser` imports `MerchantMatch` from `lib/infrastructure/ml/merchant_database.dart`, not from `lib/features/accounting/domain/models/voice_parse_result.dart`.

The two public methods remain:
- `int? extractAmount(String text)`
- `MerchantMatch? extractAndMatchMerchant(String text, MerchantDatabase merchantDB)`

Imports:
```dart
import '../../infrastructure/ml/merchant_database.dart';
```

Note: `VoiceTextParser` does NOT import the domain `voice_parse_result.dart` — it only works with `MerchantMatch` from infrastructure.

After this step, run:
```bash
flutter test test/unit/application/voice/voice_text_parser_test.dart
```

### Step 3.2 — Create CategoryMatcher

**File:** `lib/application/voice/category_matcher.dart`

Implement as defined in the MOD-009 spec section "类目匹配服务".

Imports:
```dart
import '../../features/accounting/domain/repositories/category_repository.dart';
import '../../application/accounting/category_service.dart';
import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/models/transaction.dart';
```

Key notes:
- The static `_keywordMap` uses `_KeywordMapping` as a private helper class within the same file
- `resolveLedgerType()` delegates to `CategoryService.resolveLedgerType()` — do NOT re-implement
- `CategoryService` is injected as a constructor parameter (matches existing provider pattern)

After this step, run:
```bash
flutter test test/unit/application/voice/category_matcher_test.dart
```

### Step 3.3 — Create VoiceSatisfactionEstimator

**File:** `lib/application/voice/voice_satisfaction_estimator.dart`

Implement exactly as defined in the MOD-009 spec section "语音满意度估算 -> 估算算法". Pure Dart, no dependencies beyond:
- `dart:math` (for `sqrt`)
- `lib/features/accounting/domain/models/voice_parse_result.dart` (for `VoiceAudioFeatures`)

After this step, run:
```bash
flutter test test/unit/application/voice/voice_satisfaction_estimator_test.dart
```

### Step 3.4 — Create ParseVoiceInputUseCase

**File:** `lib/application/voice/parse_voice_input_use_case.dart`

**CRITICAL CORRECTION vs Agent A's plan:** The use case maps `MerchantMatch` (infrastructure) to primitive fields in `VoiceParseResult` (domain). It does NOT store `MerchantMatch` inside `VoiceParseResult`.

```dart
// lib/application/voice/parse_voice_input_use_case.dart

import '../../features/accounting/domain/models/voice_parse_result.dart';
import '../../features/accounting/domain/models/transaction.dart';
import '../../infrastructure/ml/merchant_database.dart';
import '../../shared/utils/result.dart';
import 'category_matcher.dart';
import 'voice_text_parser.dart';

class ParseVoiceInputUseCase {
  final VoiceTextParser _textParser;
  final CategoryMatcher _categoryMatcher;
  final MerchantDatabase _merchantDatabase;

  ParseVoiceInputUseCase({
    required VoiceTextParser textParser,
    required CategoryMatcher categoryMatcher,
    required MerchantDatabase merchantDatabase,
  })  : _textParser = textParser,
        _categoryMatcher = categoryMatcher,
        _merchantDatabase = merchantDatabase;

  Future<Result<VoiceParseResult>> execute(String recognizedText) async {
    try {
      // 1. Extract amount
      final amount = _textParser.extractAmount(recognizedText);

      // 2. Match merchant (higher priority)
      final merchantMatch = _textParser.extractAndMatchMerchant(
        recognizedText,
        _merchantDatabase,
      );

      // 3. Match category
      CategoryMatchResult? categoryMatch;
      LedgerType? ledgerType;

      if (merchantMatch != null) {
        // Merchant match found: derive category from merchant
        // Map MerchantMatch (infrastructure) to CategoryMatchResult (domain)
        categoryMatch = CategoryMatchResult(
          categoryId: merchantMatch.categoryId,
          confidence: merchantMatch.confidence,
          source: MatchSource.merchant,
        );
        ledgerType = merchantMatch.ledgerType;
      } else {
        // No merchant: fall back to keyword category match
        categoryMatch = await _categoryMatcher.matchFromText(recognizedText);
        if (categoryMatch != null) {
          ledgerType = await _categoryMatcher.resolveLedgerType(
            categoryMatch.categoryId,
          );
        }
      }

      // Build result with primitives only (no MerchantMatch reference in domain)
      return Result.success(VoiceParseResult(
        rawText: recognizedText,
        amount: amount,
        merchantName: merchantMatch?.merchantName,
        merchantCategoryId: merchantMatch?.categoryId,
        merchantLedgerType: merchantMatch?.ledgerType,
        categoryMatch: categoryMatch,
        ledgerType: ledgerType,
      ));
    } catch (e) {
      return Result.error('Voice parse failed: $e');
    }
  }
}
```

After this step, run:
```bash
flutter test test/unit/application/voice/
```

All four application-layer test files should pass.

### Step 3.5 — Run build_runner for all Freezed models

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Then run full unit test suite:
```bash
flutter test test/unit/
```

---

## Phase 4: GREEN — Presentation Layer (Day 5–7)

### Step 4.1 — Create VoiceWaveform widget

**File:** `lib/features/accounting/presentation/widgets/voice_waveform.dart`

Implement as defined in MOD-009 spec section "UI组件设计 -> 波形动画组件". Uses `AnimatedContainer` for each of 16 bars. Pure stateless widget, no Riverpod.

Parameters:
- `double soundLevel` (0.0–1.0, required)
- `bool isActive` (default false)
- `Color color` (default `AppColors.survival`)

After this step, run widget tests from Phase 1 Step 1.7.

### Step 4.2 — Create VoiceTranscriptCard widget

**File:** `lib/features/accounting/presentation/widgets/voice_transcript_card.dart`

A `StatelessWidget`. Parameters:
- `bool isRecording` (required)
- `String partialText` (required, shown in grey)
- `String finalText` (required, shown in dark)

### Step 4.3 — Create VoiceParsePreview widget

**File:** `lib/features/accounting/presentation/widgets/voice_parse_preview.dart`

A `ConsumerWidget` (needs locale access for `NumberFormatter`). Parameters:
- `VoiceParseResult? parseResult` (nullable — renders nothing if null)

When `parseResult` is not null, show a Card with rows for:
- Amount (if present) — use `NumberFormatter.formatCurrency(amount, 'JPY', locale)`
- Merchant name (if present) — from `parseResult.merchantName`
- Category (if present) — show `parseResult.categoryMatch?.categoryId` as placeholder (name lookup in Phase 5)
- Ledger type (if present) — from `parseResult.ledgerType`
- Estimated satisfaction — only if `ledgerType == soul`

Imports:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/voice_parse_result.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
```

After this step, run widget tests from Phase 1 Step 1.9.

### Step 4.4 — Create voice_providers.dart

**File:** `lib/features/accounting/presentation/providers/voice_providers.dart`

Follow the exact same pattern as `use_case_providers.dart`. Use `@riverpod` annotation with code generation.

```dart
// lib/features/accounting/presentation/providers/voice_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../application/voice/category_matcher.dart';
import '../../../../application/voice/parse_voice_input_use_case.dart';
import '../../../../application/voice/voice_satisfaction_estimator.dart';
import '../../../../application/voice/voice_text_parser.dart';
import '../../../../infrastructure/ml/merchant_database.dart';
import 'repository_providers.dart';
import 'use_case_providers.dart';

part 'voice_providers.g.dart';

/// MerchantDatabase — keepAlive because it holds an in-memory seed dataset.
/// Instantiated once and reused across the app session.
@Riverpod(keepAlive: true)
MerchantDatabase merchantDatabase(Ref ref) {
  return MerchantDatabase();
}

@riverpod
VoiceTextParser voiceTextParser(Ref ref) {
  return VoiceTextParser();
}

@riverpod
CategoryMatcher categoryMatcher(Ref ref) {
  return CategoryMatcher(
    categoryRepository: ref.watch(categoryRepositoryProvider),
    // CORRECT: use the existing categoryServiceProvider from use_case_providers.dart
    // Do NOT define a new CategoryService provider here — single source of truth.
    categoryService: ref.watch(categoryServiceProvider),
  );
}

@riverpod
ParseVoiceInputUseCase parseVoiceInputUseCase(Ref ref) {
  return ParseVoiceInputUseCase(
    textParser: ref.watch(voiceTextParserProvider),
    categoryMatcher: ref.watch(categoryMatcherProvider),
    merchantDatabase: ref.watch(merchantDatabaseProvider),
  );
}

@riverpod
VoiceSatisfactionEstimator voiceSatisfactionEstimator(Ref ref) {
  return VoiceSatisfactionEstimator();
}
```

After creating this file, run build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Verify `voice_providers.g.dart` is generated.

### Step 4.5 — Rewrite VoiceInputScreen (replace stub)

**File:** `lib/features/accounting/presentation/screens/voice_input_screen.dart`

**CORRECTION vs Agent A's plan:** When navigating to `TransactionConfirmScreen`, pass `merchantName` from `parseResult.merchantName` (not `parseResult.merchantMatch?.merchantName`).

Replace the existing static stub entirely. The new implementation is a `ConsumerStatefulWidget` that:

1. Manages state: `_isRecording`, `_isInitialized`, `_partialText`, `_finalText`, `_soundLevel`, `_parseResult`, `_soundLevels`, `_timestamps`, `_startTime`, `_partialResultCount`, `_lastWordCount`
2. Creates `SpeechRecognitionService` directly (not from provider — stateful lifecycle)
3. On `initState()`: calls `_initSpeechService()` asynchronously
4. On mic button tap: calls `startListening()` or `stopListening()`
5. On sound level callback: throttles to 100ms, appends to `_soundLevels` list
6. On partial result: updates `_partialText`, debounces (300ms) parse via `ref.read(parseVoiceInputUseCaseProvider).execute(text)`
7. On final result: updates `_finalText`, runs full parse; if `ledgerType == soul`, runs `VoiceSatisfactionEstimator.estimate()`
8. "Next" button: navigates to `TransactionConfirmScreen` with all parameters

**Locale to SpeechToText locale ID mapping:**
```dart
String _localeIdFromLocale(Locale locale) {
  switch (locale.languageCode) {
    case 'ja': return 'ja-JP';
    case 'zh': return 'zh-CN';
    case 'en': return 'en-US';
    default: return 'ja-JP';
  }
}
```

The widgets used are:
- `VoiceWaveform(soundLevel: _soundLevel, isActive: _isRecording)`
- `VoiceTranscriptCard(isRecording: _isRecording, partialText: _partialText, finalText: _finalText)`
- `VoiceParsePreview(parseResult: _parseResult)`

`SpeechRecognitionService` is disposed in `dispose()`.

### Step 4.6 — Run build_runner and full test suite

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Fix any analyzer warnings before proceeding. Zero tolerance for warnings.

---

## Phase 5: REFACTOR — Integration & Polish (Day 7–8)

### Step 5.1 — Add optional parameters to TransactionConfirmScreen

**File:** `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`

Add optional constructor parameters:

```dart
class TransactionConfirmScreen extends ConsumerStatefulWidget {
  const TransactionConfirmScreen({
    super.key,
    required this.bookId,
    required this.amount,
    required this.category,
    this.parentCategory,
    required this.date,
    // New optional parameters for voice pre-fill:
    this.initialMerchant,       // pre-fills _storeController
    this.initialSatisfaction,   // pre-fills _soulSatisfaction
  });

  final String bookId;
  final int amount;
  final Category category;
  final Category? parentCategory;
  final DateTime date;
  final String? initialMerchant;      // new
  final int? initialSatisfaction;     // new
  // ...
}
```

In `initState()`, add:
```dart
if (widget.initialMerchant != null) {
  _storeController.text = widget.initialMerchant!;
}
if (widget.initialSatisfaction != null) {
  _soulSatisfaction = widget.initialSatisfaction!.clamp(1, 10);
}
```

This is backward-compatible — existing callers pass neither parameter.

### Step 5.2 — Integrate navigation from VoiceInputScreen to TransactionConfirmScreen

In `VoiceInputScreen`, implement the "Next" button navigation:

1. Read `categoryRepository` to look up the `Category` object by `parseResult.categoryMatch?.categoryId`
2. If `categoryId` is null (no match), show `SoftToast` and do not navigate
3. If category found, push `TransactionConfirmScreen` with:
   - `bookId: widget.bookId`
   - `amount: parseResult.amount ?? 0`
   - `category: category`
   - `date: DateTime.now()`
   - `initialMerchant: parseResult.merchantName`
   - `initialSatisfaction: parseResult.ledgerType == LedgerType.soul ? parseResult.estimatedSatisfaction : null`

### Step 5.3 — Resolve category name display in VoiceParsePreview

Replace the category ID placeholder with actual name lookup:
- `VoiceParsePreview` accepts optional `Map<String, String>? categoryNames` parameter (categoryId -> display name)
- In `VoiceInputScreen`, after parsing, look up the category name via `categoryRepositoryProvider` and pass it to `VoiceParsePreview`

### Step 5.4 — Debouncing, caching, and throttle implementation

Apply the exact patterns from Agent A's original plan (Steps 5.3, 5.4, 5.5) — these are correct:

- Debounce `_parseDebounce` with 300ms timer, cancelled in `dispose()`
- Merchant match caching: skip re-search if text changed by fewer than 2 characters
- Sound level sampling: 100ms throttle via `_lastSampleTime`

### Step 5.5 — Permission denied error handling

In `_initSpeechService()`, if `initialize()` returns false:
- Show `SoftToast` (exists at `lib/features/accounting/presentation/widgets/soft_toast.dart`) with microphone permission instructions

### Step 5.6 — Final flutter analyze and test run

```bash
flutter analyze
flutter test
```

Expected output:
```
Analyzing home_pocket...
No issues found!

00:XX +NNN: All tests passed!
```

### Step 5.7 — Generate worklog

Create worklog at `docs/worklog/YYYYMMDD_HHMM_implement_voice_input_module.md` per the worklog rules.

---

## Dependency Map

The corrected dependency graph:

```
voice_parse_result.dart (Freezed domain model — NO infrastructure refs)
  └── required by all application/presentation voice files

merchant_database.dart (Infrastructure — defines MerchantMatch)
  └── required by VoiceTextParser, ParseVoiceInputUseCase

speech_recognition_service.dart (Infrastructure)
  └── required by VoiceInputScreen

voice_text_parser.dart (Application)
  └── depends on: MerchantDatabase (infrastructure), NO domain imports

category_matcher.dart (Application)
  └── depends on: CategoryRepository (domain interface), CategoryService (application), VoiceParseResult (domain)

voice_satisfaction_estimator.dart (Application)
  └── depends on: VoiceParseResult.VoiceAudioFeatures (domain)

parse_voice_input_use_case.dart (Application)
  └── depends on: VoiceTextParser, CategoryMatcher, MerchantDatabase, VoiceParseResult
  └── maps MerchantMatch -> VoiceParseResult primitive fields (no cross-layer ref in domain)

voice_providers.dart (Presentation/Providers)
  └── depends on: application layer + repository_providers.dart + use_case_providers.dart
  └── uses categoryServiceProvider from use_case_providers.dart (NOT redefined)

voice_waveform.dart, voice_transcript_card.dart, voice_parse_preview.dart (Widgets)
  └── depend on: VoiceParseResult domain model, NumberFormatter, LocaleProvider

VoiceInputScreen (Screen — replaces stub)
  └── depends on: ALL of the above
  └── maps VoiceParseResult.merchantName (String) to TransactionConfirmScreen.initialMerchant
```

---

## Acceptance Criteria Checklist

Mapped from MOD-009 functional requirements:

**FR-001: Voice to Text**
- [ ] App requests microphone permission before first use (iOS + Android)
- [ ] Speech recognition initializes for Japanese (ja-JP) locale
- [ ] Speech recognition initializes for Chinese (zh-CN) locale
- [ ] Speech recognition initializes for English (en-US) locale
- [ ] Partial results appear in real-time as user speaks
- [ ] 3-second silence automatically stops recording (via `pauseFor: Duration(seconds: 3)`)
- [ ] Maximum 30-second recording limit enforced
- [ ] `VoiceWaveform` animates during recording

**FR-002: Amount Extraction**
- [ ] Extracts `680円` -> 680 (unit test passes)
- [ ] Extracts `¥1,280` -> 1280 (unit test passes)
- [ ] Extracts `480块` -> 480 (unit test passes)
- [ ] Extracts `550 yen` -> 550 (unit test passes)
- [ ] Extracts kanji `六百八十円` -> 680 (unit test passes)
- [ ] Extracts kanji `千二百` -> 1200 (unit test passes)
- [ ] Returns null for text with no amount (unit test passes)

**FR-003: Category Fuzzy Matching**
- [ ] `昼ごはん` -> `cat_food` with confidence > 0.8 (unit test passes)
- [ ] `午饭` -> `cat_food` (unit test passes)
- [ ] `lunch` -> `cat_food` (unit test passes)
- [ ] `電車` -> `cat_transport` with confidence >= 0.9 (unit test passes)
- [ ] Unknown text -> null (unit test passes)
- [ ] `VoiceParsePreview` shows matched category

**FR-004: Merchant Fuzzy Matching**
- [ ] `MerchantDatabase.findMerchant('マクドナルド')` returns match
- [ ] `MerchantDatabase.findMerchant('マック')` returns マクドナルド match (alias)
- [ ] `MerchantDatabase.findMerchant('スタバ')` returns スターバックス match (alias)
- [ ] Merchant match has higher priority than keyword match (unit test passes)
- [ ] `VoiceParsePreview` shows matched merchant name (`parseResult.merchantName`)

**FR-005: Voice Satisfaction Estimation**
- [ ] Estimator returns score in range 1–10 always (unit test passes)
- [ ] Excited voice -> score >= 7 (unit test passes)
- [ ] Calm voice -> score 4–6 (unit test passes)
- [ ] Empty audio -> default score 3–5 (unit test passes)
- [ ] Satisfaction estimation runs only when `ledgerType == soul`
- [ ] Estimated satisfaction is pre-filled in `TransactionConfirmScreen` slider (via `initialSatisfaction`)

**FR-006: Permission Management**
- [ ] iOS `Info.plist` has `NSSpeechRecognitionUsageDescription`
- [ ] iOS `Info.plist` has `NSMicrophoneUsageDescription`
- [ ] Android `AndroidManifest.xml` has `RECORD_AUDIO` permission
- [ ] Permission denial shows friendly error message via `SoftToast`
- [ ] Mic button is disabled when `isAvailable` is false

---

## Files to Create (Complete List)

21 new files + generated files:

**Domain Models (1 file):**
1. `lib/features/accounting/domain/models/voice_parse_result.dart`

**Infrastructure (2 files):**
2. `lib/infrastructure/ml/merchant_database.dart` (defines both `MerchantDatabase` and `MerchantMatch`)
3. `lib/infrastructure/speech/speech_recognition_service.dart`

**Application Layer (4 files):**
4. `lib/application/voice/voice_text_parser.dart`
5. `lib/application/voice/category_matcher.dart`
6. `lib/application/voice/voice_satisfaction_estimator.dart`
7. `lib/application/voice/parse_voice_input_use_case.dart`

**Presentation — Providers (1 file):**
8. `lib/features/accounting/presentation/providers/voice_providers.dart`

**Presentation — Widgets (3 files):**
9. `lib/features/accounting/presentation/widgets/voice_waveform.dart`
10. `lib/features/accounting/presentation/widgets/voice_transcript_card.dart`
11. `lib/features/accounting/presentation/widgets/voice_parse_preview.dart`

**Tests (10 files, all written in Phase 1):**
12. `test/unit/application/voice/voice_text_parser_test.dart`
13. `test/unit/application/voice/category_matcher_test.dart`
14. `test/unit/application/voice/voice_satisfaction_estimator_test.dart`
15. `test/unit/application/voice/parse_voice_input_use_case_test.dart`
16. `test/unit/infrastructure/speech/speech_recognition_service_test.dart`
17. `test/widget/features/accounting/presentation/widgets/voice_waveform_test.dart`
18. `test/widget/features/accounting/presentation/widgets/voice_transcript_card_test.dart`
19. `test/widget/features/accounting/presentation/widgets/voice_parse_preview_test.dart`
20. `test/unit/features/accounting/presentation/providers/voice_providers_test.dart`
21. `test/unit/features/accounting/domain/models/voice_parse_result_test.dart`

**Generated by build_runner (not committed, not listed as "create"):**
- `lib/features/accounting/domain/models/voice_parse_result.freezed.dart`
- `lib/features/accounting/presentation/providers/voice_providers.g.dart`
- `test/unit/application/voice/category_matcher_test.mocks.dart`
- `test/unit/application/voice/parse_voice_input_use_case_test.mocks.dart`

---

## Files to Modify (Complete List)

5 existing files to modify:

1. **`pubspec.yaml`** — Add `speech_to_text: ^7.0.0` dependency
2. **`ios/Runner/Info.plist`** — Add microphone and speech recognition usage descriptions
3. **`android/app/src/main/AndroidManifest.xml`** — Add RECORD_AUDIO permission and speech intent query
4. **`lib/features/accounting/presentation/screens/voice_input_screen.dart`** — Replace stub with full ConsumerStatefulWidget implementation
5. **`lib/features/accounting/presentation/screens/transaction_confirm_screen.dart`** — Add optional `initialMerchant` and `initialSatisfaction` constructor parameters

---

## Notes on Existing Code Reuse

| Existing File | How Reused |
|---|---|
| `lib/application/accounting/category_service.dart` | `CategoryMatcher` delegates `resolveLedgerType()` to it (via `categoryServiceProvider`) |
| `lib/application/dual_ledger/classification_service.dart` | NOT directly used by voice — `VoiceInputScreen` passes `ledgerType` explicitly |
| `lib/shared/utils/result.dart` | `ParseVoiceInputUseCase` returns `Result<VoiceParseResult>` |
| `lib/features/accounting/domain/models/transaction.dart` | `LedgerType` enum imported by voice models and infrastructure |
| `lib/features/accounting/domain/repositories/category_repository.dart` | Used by `CategoryMatcher` |
| `lib/features/accounting/presentation/screens/transaction_confirm_screen.dart` | Voice flow navigates here; new optional params added |
| `lib/features/accounting/presentation/widgets/soft_toast.dart` | Used for error feedback in permission denied case |
| `lib/features/accounting/presentation/providers/repository_providers.dart` | `voice_providers.dart` imports `categoryRepositoryProvider` from here |
| `lib/features/accounting/presentation/providers/use_case_providers.dart` | `voice_providers.dart` imports `categoryServiceProvider` from here |
| `lib/core/theme/app_colors.dart` | Widget colors |
| `lib/core/theme/app_text_styles.dart` | Widget text styles |
| `lib/infrastructure/i18n/formatters/number_formatter.dart` | Currency display in `VoiceParsePreview` |
| `lib/features/settings/presentation/providers/locale_provider.dart` | Locale for speech recognition and number formatting |
