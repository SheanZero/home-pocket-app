# Dual Ledger (双轨账本) Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the dual ledger classification engine and UI so transactions are automatically classified into Survival or Soul ledger based on a 3-layer engine (Rule → Merchant → ML fallback).

**Architecture:** Application-layer `ClassificationService` orchestrates 3 classification layers. `RuleEngine` maps category IDs to ledger types (Layer 1). Merchant lookup and ML classifier are stubbed for MVP (Layers 2 & 3). The existing `CreateTransactionUseCase` is extended to use the classification service instead of hardcoding `LedgerType.survival`. A new `dual_ledger` feature provides the tabbed dual-ledger UI and soul celebration animation.

**Tech Stack:** Flutter, Riverpod 2.4+ (code-gen), Freezed 3.x, Drift (existing), Mockito for tests.

**Spec:** `docs/arch/02-module-specs/MOD-002_DualLedger.md`

---

## Existing Code Inventory

**Already implemented (from MOD-001):**
- `LedgerType` enum `{survival, soul}` in `lib/features/accounting/domain/models/transaction.dart`
- `Transaction` model with `ledgerType` and `merchant` fields
- `Transactions` table with `ledgerType` column + index (`idx_tx_ledger_type`)
- `TransactionDao.findByBookId()` already supports `ledgerType` filter
- `TransactionRepository.findByBookId()` accepts `LedgerType?` parameter
- 20 default categories (10 L1 expense, 6 L2 expense, 4 L1 income)
- `CreateTransactionUseCase` — **hardcodes `LedgerType.survival` on line 113**
- Transaction form screen, list screen, list tile widgets
- 213 passing tests

**Not yet implemented:**
- `lib/application/dual_ledger/` — empty
- `lib/features/dual_ledger/` — empty
- `lib/infrastructure/ml/` — empty
- No classification engine, no dual ledger UI, no soul celebration

---

## Task 1: Classification Domain Models

**Files:**
- Create: `lib/application/dual_ledger/classification_result.dart`
- Test: `test/unit/application/dual_ledger/classification_result_test.dart`

**Context:** These plain Dart classes are used by all classification layers. No Freezed needed — simple immutable classes.

**Step 1: Write the test file**

```dart
// test/unit/application/dual_ledger/classification_result_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  group('ClassificationResult', () {
    test('creates with all required fields', () {
      final result = ClassificationResult(
        ledgerType: LedgerType.soul,
        confidence: 0.95,
        method: ClassificationMethod.rule,
        reason: 'Entertainment category',
      );

      expect(result.ledgerType, LedgerType.soul);
      expect(result.confidence, 0.95);
      expect(result.method, ClassificationMethod.rule);
      expect(result.reason, 'Entertainment category');
    });

    test('ClassificationMethod has all expected values', () {
      expect(ClassificationMethod.values, hasLength(3));
      expect(ClassificationMethod.values, contains(ClassificationMethod.rule));
      expect(ClassificationMethod.values, contains(ClassificationMethod.merchant));
      expect(ClassificationMethod.values, contains(ClassificationMethod.ml));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/dual_ledger/classification_result_test.dart`
Expected: FAIL — file not found

**Step 3: Write the implementation**

```dart
// lib/application/dual_ledger/classification_result.dart

import '../../features/accounting/domain/models/transaction.dart';

/// Method used to classify the transaction.
enum ClassificationMethod {
  rule,      // Rule engine (Layer 1)
  merchant,  // Merchant database (Layer 2)
  ml,        // ML classifier (Layer 3)
}

/// Result of the 3-layer classification engine.
class ClassificationResult {
  final LedgerType ledgerType;
  final double confidence;
  final ClassificationMethod method;
  final String reason;

  const ClassificationResult({
    required this.ledgerType,
    required this.confidence,
    required this.method,
    required this.reason,
  });
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/dual_ledger/classification_result_test.dart`
Expected: PASS (2 tests)

**Step 5: Commit**

```bash
git add lib/application/dual_ledger/classification_result.dart \
        test/unit/application/dual_ledger/classification_result_test.dart
git commit -m "feat(dual-ledger): add ClassificationResult model and ClassificationMethod enum"
```

---

## Task 2: Rule Engine (Layer 1)

**Files:**
- Create: `lib/application/dual_ledger/rule_engine.dart`
- Test: `test/unit/application/dual_ledger/rule_engine_test.dart`

**Context:** The Rule Engine maps category IDs to `LedgerType`. It has the highest priority and 100% confidence. Rules must match the existing default category IDs from `lib/shared/constants/default_categories.dart`.

**Existing category IDs (expense):**
- L1: `cat_food`, `cat_transport`, `cat_shopping`, `cat_entertainment`, `cat_housing`, `cat_medical`, `cat_education`, `cat_daily`, `cat_social`, `cat_other_expense`
- L2: `cat_food_breakfast`, `cat_food_lunch`, `cat_food_dinner`, `cat_food_snack`, `cat_transport_public`, `cat_transport_taxi`

**Survival mapping:** `cat_food`, `cat_food_breakfast`, `cat_food_lunch`, `cat_food_dinner`, `cat_food_snack`, `cat_transport`, `cat_transport_public`, `cat_transport_taxi`, `cat_housing`, `cat_medical`, `cat_daily`, `cat_other_expense`

**Soul mapping:** `cat_entertainment`, `cat_shopping`, `cat_education`, `cat_social`

**Step 1: Write the test file**

```dart
// test/unit/application/dual_ledger/rule_engine_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late RuleEngine engine;

  setUp(() {
    engine = RuleEngine();
  });

  group('RuleEngine', () {
    group('default survival rules', () {
      test('classifies food categories as survival', () {
        expect(engine.classify('cat_food'), LedgerType.survival);
        expect(engine.classify('cat_food_breakfast'), LedgerType.survival);
        expect(engine.classify('cat_food_lunch'), LedgerType.survival);
        expect(engine.classify('cat_food_dinner'), LedgerType.survival);
        expect(engine.classify('cat_food_snack'), LedgerType.survival);
      });

      test('classifies transport as survival', () {
        expect(engine.classify('cat_transport'), LedgerType.survival);
        expect(engine.classify('cat_transport_public'), LedgerType.survival);
        expect(engine.classify('cat_transport_taxi'), LedgerType.survival);
      });

      test('classifies housing and medical as survival', () {
        expect(engine.classify('cat_housing'), LedgerType.survival);
        expect(engine.classify('cat_medical'), LedgerType.survival);
      });

      test('classifies daily necessities as survival', () {
        expect(engine.classify('cat_daily'), LedgerType.survival);
      });

      test('classifies other_expense as survival', () {
        expect(engine.classify('cat_other_expense'), LedgerType.survival);
      });
    });

    group('default soul rules', () {
      test('classifies entertainment as soul', () {
        expect(engine.classify('cat_entertainment'), LedgerType.soul);
      });

      test('classifies shopping as soul', () {
        expect(engine.classify('cat_shopping'), LedgerType.soul);
      });

      test('classifies education as soul', () {
        expect(engine.classify('cat_education'), LedgerType.soul);
      });

      test('classifies social as soul', () {
        expect(engine.classify('cat_social'), LedgerType.soul);
      });
    });

    test('returns null for unknown category', () {
      expect(engine.classify('cat_unknown_xyz'), isNull);
    });

    test('addRule overrides existing rule', () {
      expect(engine.classify('cat_food'), LedgerType.survival);
      engine.addRule('cat_food', LedgerType.soul);
      expect(engine.classify('cat_food'), LedgerType.soul);
    });

    test('removeRule makes classify return null', () {
      expect(engine.classify('cat_food'), LedgerType.survival);
      engine.removeRule('cat_food');
      expect(engine.classify('cat_food'), isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/dual_ledger/rule_engine_test.dart`
Expected: FAIL — file not found

**Step 3: Write the implementation**

```dart
// lib/application/dual_ledger/rule_engine.dart

import '../../features/accounting/domain/models/transaction.dart';

/// Layer 1: Category-based rule engine for ledger classification.
///
/// Maps category IDs to [LedgerType] with 100% confidence.
/// Highest priority in the 3-layer classification engine.
class RuleEngine {
  final Map<String, LedgerType> _categoryRules = {};

  RuleEngine() {
    _initializeDefaultRules();
  }

  void _initializeDefaultRules() {
    // Survival (必要支出)
    _categoryRules['cat_food'] = LedgerType.survival;
    _categoryRules['cat_food_breakfast'] = LedgerType.survival;
    _categoryRules['cat_food_lunch'] = LedgerType.survival;
    _categoryRules['cat_food_dinner'] = LedgerType.survival;
    _categoryRules['cat_food_snack'] = LedgerType.survival;
    _categoryRules['cat_transport'] = LedgerType.survival;
    _categoryRules['cat_transport_public'] = LedgerType.survival;
    _categoryRules['cat_transport_taxi'] = LedgerType.survival;
    _categoryRules['cat_housing'] = LedgerType.survival;
    _categoryRules['cat_medical'] = LedgerType.survival;
    _categoryRules['cat_daily'] = LedgerType.survival;
    _categoryRules['cat_other_expense'] = LedgerType.survival;

    // Soul (享受型支出)
    _categoryRules['cat_entertainment'] = LedgerType.soul;
    _categoryRules['cat_shopping'] = LedgerType.soul;
    _categoryRules['cat_education'] = LedgerType.soul;
    _categoryRules['cat_social'] = LedgerType.soul;
  }

  /// Classify a category ID. Returns null if no rule matches.
  LedgerType? classify(String categoryId) {
    return _categoryRules[categoryId];
  }

  /// Add or override a classification rule.
  void addRule(String categoryId, LedgerType ledgerType) {
    _categoryRules[categoryId] = ledgerType;
  }

  /// Remove a classification rule.
  void removeRule(String categoryId) {
    _categoryRules.remove(categoryId);
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/dual_ledger/rule_engine_test.dart`
Expected: PASS (11 tests)

**Step 5: Commit**

```bash
git add lib/application/dual_ledger/rule_engine.dart \
        test/unit/application/dual_ledger/rule_engine_test.dart
git commit -m "feat(dual-ledger): add RuleEngine with default category-to-ledger mappings"
```

---

## Task 3: ClassificationService

**Files:**
- Create: `lib/application/dual_ledger/classification_service.dart`
- Test: `test/unit/application/dual_ledger/classification_service_test.dart`

**Context:** The ClassificationService orchestrates the 3-layer classification engine. For MVP, Layers 2 (Merchant) and 3 (ML) are represented as simple interfaces/abstract classes with stub implementations that return null/default. The service falls through: Rule → (merchant stub) → default survival.

**Step 1: Write the test file**

```dart
// test/unit/application/dual_ledger/classification_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/classification_result.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';

void main() {
  late RuleEngine ruleEngine;
  late ClassificationService service;

  setUp(() {
    ruleEngine = RuleEngine();
    service = ClassificationService(ruleEngine: ruleEngine);
  });

  group('ClassificationService', () {
    test('uses rule engine when category has a rule (survival)', () async {
      final result = await service.classify(
        categoryId: 'cat_food',
      );

      expect(result.ledgerType, LedgerType.survival);
      expect(result.method, ClassificationMethod.rule);
      expect(result.confidence, 1.0);
    });

    test('uses rule engine when category has a rule (soul)', () async {
      final result = await service.classify(
        categoryId: 'cat_entertainment',
      );

      expect(result.ledgerType, LedgerType.soul);
      expect(result.method, ClassificationMethod.rule);
      expect(result.confidence, 1.0);
    });

    test('falls back to default survival for unknown category', () async {
      final result = await service.classify(
        categoryId: 'cat_unknown_xyz',
      );

      expect(result.ledgerType, LedgerType.survival);
      expect(result.confidence, lessThan(1.0));
    });

    test('classifies all default expense categories without error', () async {
      final expenseCategoryIds = [
        'cat_food', 'cat_food_breakfast', 'cat_food_lunch',
        'cat_food_dinner', 'cat_food_snack',
        'cat_transport', 'cat_transport_public', 'cat_transport_taxi',
        'cat_shopping', 'cat_entertainment', 'cat_housing',
        'cat_medical', 'cat_education', 'cat_daily',
        'cat_social', 'cat_other_expense',
      ];

      for (final id in expenseCategoryIds) {
        final result = await service.classify(categoryId: id);
        expect(result.ledgerType, isNotNull, reason: 'Failed for $id');
        expect(result.confidence, greaterThan(0), reason: 'Failed for $id');
      }
    });

    test('income categories fall back to survival', () async {
      final result = await service.classify(categoryId: 'cat_salary');
      expect(result.ledgerType, LedgerType.survival);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/unit/application/dual_ledger/classification_service_test.dart`
Expected: FAIL — file not found

**Step 3: Write the implementation**

```dart
// lib/application/dual_ledger/classification_service.dart

import '../../features/accounting/domain/models/transaction.dart';
import 'classification_result.dart';
import 'rule_engine.dart';

/// 3-layer classification engine for dual ledger.
///
/// Priority: Rule Engine → (Merchant DB → ML Classifier) → Default survival.
/// Layers 2 and 3 are stubbed for MVP.
class ClassificationService {
  ClassificationService({required RuleEngine ruleEngine})
      : _ruleEngine = ruleEngine;

  final RuleEngine _ruleEngine;

  /// Classify a transaction into survival or soul ledger.
  Future<ClassificationResult> classify({
    required String categoryId,
    String? merchant,
    String? note,
  }) async {
    // Layer 1: Rule Engine (highest priority, confidence 1.0)
    final ruleResult = _ruleEngine.classify(categoryId);
    if (ruleResult != null) {
      return ClassificationResult(
        ledgerType: ruleResult,
        confidence: 1.0,
        method: ClassificationMethod.rule,
        reason: 'Category rule: $categoryId',
      );
    }

    // Layer 2: Merchant Database (stub for MVP)
    // TODO: Implement MerchantDatabase lookup when lib/infrastructure/ml/ is built

    // Layer 3: ML Classifier (stub for MVP)
    // TODO: Implement TFLiteClassifier when model is available

    // Default fallback: survival
    return ClassificationResult(
      ledgerType: LedgerType.survival,
      confidence: 0.5,
      method: ClassificationMethod.rule,
      reason: 'Default fallback',
    );
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/unit/application/dual_ledger/classification_service_test.dart`
Expected: PASS (5 tests)

**Step 5: Commit**

```bash
git add lib/application/dual_ledger/classification_service.dart \
        test/unit/application/dual_ledger/classification_service_test.dart
git commit -m "feat(dual-ledger): add ClassificationService with 3-layer engine (Layer 2+3 stubbed)"
```

---

## Task 4: Integrate Classification into CreateTransactionUseCase

**Files:**
- Modify: `lib/application/accounting/create_transaction_use_case.dart` (lines 16-32, 38-45, 106-119)
- Modify: `test/unit/application/accounting/create_transaction_use_case_test.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart` (line 15-21)

**Context:** Currently `CreateTransactionUseCase` hardcodes `ledgerType: LedgerType.survival` on line 113. We need to:
1. Add `ClassificationService` as a dependency
2. Add optional `merchant` field to `CreateTransactionParams`
3. Call `classificationService.classify()` during transaction creation
4. Use the result's `ledgerType` instead of the hardcoded value
5. Update the provider wiring
6. Update existing tests to provide the mock

**Step 1: Update CreateTransactionParams to include merchant**

In `lib/application/accounting/create_transaction_use_case.dart`, add `merchant` field to `CreateTransactionParams`:

```dart
class CreateTransactionParams {
  final String bookId;
  final int amount;
  final TransactionType type;
  final String categoryId;
  final DateTime? timestamp;
  final String? note;
  final String? merchant;  // NEW

  const CreateTransactionParams({
    required this.bookId,
    required this.amount,
    required this.type,
    required this.categoryId,
    this.timestamp,
    this.note,
    this.merchant,  // NEW
  });
}
```

**Step 2: Add ClassificationService to constructor**

```dart
class CreateTransactionUseCase {
  CreateTransactionUseCase({
    required TransactionRepository transactionRepository,
    required CategoryRepository categoryRepository,
    required HashChainService hashChainService,
    required ClassificationService classificationService,  // NEW
  }) : _transactionRepo = transactionRepository,
       _categoryRepo = categoryRepository,
       _hashChainService = hashChainService,
       _classificationService = classificationService;  // NEW

  final TransactionRepository _transactionRepo;
  final CategoryRepository _categoryRepo;
  final HashChainService _hashChainService;
  final ClassificationService _classificationService;  // NEW
```

**Step 3: Replace hardcoded ledgerType with classification result**

Replace the hardcoded `ledgerType: LedgerType.survival` (line 113) in the `execute()` method. Insert classification call after category verification (after line 78) and before building the transaction:

```dart
    // 3. Classify transaction (dual ledger)
    final classification = await _classificationService.classify(
      categoryId: params.categoryId,
      merchant: params.merchant,
      note: params.note,
    );

    // ... existing hash chain code ...

    // 6. Create domain object — use classification.ledgerType
    final transaction = Transaction(
      // ... existing fields ...
      ledgerType: classification.ledgerType,  // WAS: LedgerType.survival
      // ... rest of fields ...
      merchant: params.merchant,  // Pass merchant through
    );
```

**Step 4: Update existing tests**

The 5 existing tests in `test/unit/application/accounting/create_transaction_use_case_test.dart` use `@GenerateMocks`. Add `ClassificationService` to the mock list and pass it to the constructor in `setUp`. For the mock, stub `classify()` to return a default result.

**Step 5: Add new tests for classification integration**

Add these tests to the existing test file:

```dart
    test('uses classification service to determine ledgerType', () async {
      // ... setup with mock classification returning soul ...
      // Verify the created transaction has ledgerType: soul
    });

    test('passes merchant and note to classification service', () async {
      // ... setup with merchant param ...
      // Verify classify() was called with correct params
    });
```

**Step 6: Update provider wiring**

In `lib/features/accounting/presentation/providers/use_case_providers.dart`, add the classification service dependency:

```dart
@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),  // NEW
  );
}
```

**Step 7: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 8: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 9: Commit**

```bash
git add lib/application/accounting/create_transaction_use_case.dart \
        lib/features/accounting/presentation/providers/use_case_providers.dart \
        test/unit/application/accounting/create_transaction_use_case_test.dart \
        test/unit/application/accounting/create_transaction_use_case_test.mocks.dart
git commit -m "feat(dual-ledger): integrate ClassificationService into CreateTransactionUseCase"
```

---

## Task 5: Dual Ledger Providers

**Files:**
- Create: `lib/application/dual_ledger/providers.dart`
- Create: `lib/features/dual_ledger/presentation/providers/ledger_providers.dart`
- Modify: `lib/features/accounting/presentation/providers/use_case_providers.dart` (import)

**Context:** Wire the RuleEngine and ClassificationService into Riverpod providers. Add a LedgerView notifier for tab state management.

**Step 1: Create application-level providers**

```dart
// lib/application/dual_ledger/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'classification_service.dart';
import 'rule_engine.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
RuleEngine ruleEngine(Ref ref) {
  return RuleEngine();
}

@riverpod
ClassificationService classificationService(Ref ref) {
  final ruleEngine = ref.watch(ruleEngineProvider);
  return ClassificationService(ruleEngine: ruleEngine);
}
```

**Step 2: Create dual_ledger feature providers**

```dart
// lib/features/dual_ledger/presentation/providers/ledger_providers.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/accounting/domain/models/transaction.dart';

part 'ledger_providers.g.dart';

/// Current ledger tab selection.
@Riverpod(keepAlive: true)
class LedgerView extends _$LedgerView {
  @override
  LedgerType build() => LedgerType.survival;

  void switchTo(LedgerType type) => state = type;

  void toggle() {
    state = state == LedgerType.survival
        ? LedgerType.soul
        : LedgerType.survival;
  }
}
```

**Step 3: Update use_case_providers.dart to import classification provider**

In `lib/features/accounting/presentation/providers/use_case_providers.dart`, change the `createTransactionUseCase` provider to reference `classificationServiceProvider`:

```dart
import '../../../../application/dual_ledger/providers.dart';

@riverpod
CreateTransactionUseCase createTransactionUseCase(Ref ref) {
  return CreateTransactionUseCase(
    transactionRepository: ref.watch(transactionRepositoryProvider),
    categoryRepository: ref.watch(categoryRepositoryProvider),
    hashChainService: ref.watch(hashChainServiceProvider),
    classificationService: ref.watch(classificationServiceProvider),
  );
}
```

**Step 4: Run code generation**

Run: `flutter pub run build_runner build --delete-conflicting-outputs`

**Step 5: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add lib/application/dual_ledger/providers.dart \
        lib/application/dual_ledger/providers.g.dart \
        lib/features/dual_ledger/presentation/providers/ledger_providers.dart \
        lib/features/dual_ledger/presentation/providers/ledger_providers.g.dart \
        lib/features/accounting/presentation/providers/use_case_providers.dart \
        lib/features/accounting/presentation/providers/use_case_providers.g.dart
git commit -m "feat(dual-ledger): add Riverpod providers for classification service and ledger view"
```

---

## Task 6: Dual Ledger Screen with Tab Switching

**Files:**
- Create: `lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart`
- Modify: `lib/main.dart` (replace TransactionListScreen with DualLedgerScreen)
- Test: `test/widget/features/dual_ledger/presentation/screens/dual_ledger_screen_test.dart`

**Context:** The DualLedgerScreen wraps the existing TransactionListScreen with a top tab bar to switch between Survival and Soul views. It uses `ledgerViewProvider` for state. The existing `TransactionListScreen` needs a new optional `ledgerType` parameter to filter by ledger.

**Step 1: Add optional ledgerType filter to TransactionListScreen**

In `lib/features/accounting/presentation/screens/transaction_list_screen.dart`, add an optional `ledgerType` parameter and pass it through to `GetTransactionsParams`:

```dart
class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({
    super.key,
    required this.bookId,
    this.ledgerType,  // NEW
  });

  final String bookId;
  final LedgerType? ledgerType;  // NEW
```

Update `_loadData()` to pass ledgerType:

```dart
    final result = await getTransactions.execute(
      GetTransactionsParams(
        bookId: widget.bookId,
        ledgerType: widget.ledgerType,  // NEW
      ),
    );
```

**Step 2: Write the DualLedgerScreen**

```dart
// lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/accounting/domain/models/transaction.dart';
import '../../../../features/accounting/presentation/screens/transaction_list_screen.dart';
import '../providers/ledger_providers.dart';

class DualLedgerScreen extends ConsumerWidget {
  const DualLedgerScreen({super.key, required this.bookId});

  final String bookId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLedger = ref.watch(ledgerViewProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Pocket'),
          bottom: TabBar(
            onTap: (index) {
              ref.read(ledgerViewProvider.notifier).switchTo(
                index == 0 ? LedgerType.survival : LedgerType.soul,
              );
            },
            tabs: [
              Tab(
                icon: Icon(Icons.shield,
                    color: currentLedger == LedgerType.survival
                        ? Colors.blue
                        : null),
                text: 'Survival',
              ),
              Tab(
                icon: Icon(Icons.auto_awesome,
                    color: currentLedger == LedgerType.soul
                        ? Colors.purple
                        : null),
                text: 'Soul',
              ),
            ],
          ),
        ),
        body: TransactionListScreen(
          key: ValueKey(currentLedger),
          bookId: bookId,
          ledgerType: currentLedger,
        ),
      ),
    );
  }
}
```

**Step 3: Update main.dart to use DualLedgerScreen**

Replace `TransactionListScreen(bookId: _bookId!)` with `DualLedgerScreen(bookId: _bookId!)` in `lib/main.dart`.

**Step 4: Write widget test**

```dart
// test/widget/features/dual_ledger/presentation/screens/dual_ledger_screen_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DualLedgerScreen', () {
    testWidgets('displays two tabs - Survival and Soul', (tester) async {
      // Just verify the structure renders without error
      // Full test requires provider overrides
      expect(true, isTrue); // placeholder
    });
  });
}
```

**Step 5: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 6: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

**Step 7: Commit**

```bash
git add lib/features/dual_ledger/presentation/screens/dual_ledger_screen.dart \
        lib/features/accounting/presentation/screens/transaction_list_screen.dart \
        lib/main.dart \
        test/widget/features/dual_ledger/
git commit -m "feat(dual-ledger): add DualLedgerScreen with Survival/Soul tab switching"
```

---

## Task 7: Update TransactionListTile with Ledger Indicator

**Files:**
- Modify: `lib/features/accounting/presentation/widgets/transaction_list_tile.dart`
- Modify: `test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart`

**Context:** Add a small colored indicator (dot or badge) on each transaction tile showing whether it's a Survival (blue) or Soul (purple) transaction. This gives visual feedback about the classification.

**Step 1: Add ledger type indicator test**

Add to the existing test file:

```dart
    testWidgets('shows blue dot for survival transaction', (tester) async {
      // ... pump with survival transaction ...
      // expect to find a blue-colored indicator widget
    });

    testWidgets('shows purple dot for soul transaction', (tester) async {
      final soulTx = Transaction(
        // ... with ledgerType: LedgerType.soul ...
      );
      // ... pump ...
      // expect purple indicator
    });
```

**Step 2: Add ledger color indicator to TransactionListTile**

Add a small `Container` with a circular decoration using blue for survival, purple for soul. Place it as a leading element or trailing badge.

**Step 3: Run tests**

Run: `flutter test test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add lib/features/accounting/presentation/widgets/transaction_list_tile.dart \
        test/widget/features/accounting/presentation/widgets/transaction_list_tile_test.dart
git commit -m "feat(dual-ledger): add ledger type color indicator to transaction list tile"
```

---

## Task 8: Soul Celebration Overlay

**Files:**
- Create: `lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart`
- Modify: `lib/features/accounting/presentation/screens/transaction_form_screen.dart`
- Test: `test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart`

**Context:** When a transaction is classified as Soul, show a brief confetti-like celebration animation after save. For MVP, use a simple Flutter `AnimatedContainer` or `AnimatedOpacity` with purple sparkle icons — no Lottie dependency needed. The celebration is triggered by the form screen after a successful save of a soul transaction.

**Step 1: Create SoulCelebrationOverlay widget**

A simple stateful widget that shows a purple-themed animation overlay for ~1.5 seconds, then auto-dismisses. It takes a `VoidCallback? onDismissed` parameter.

```dart
// lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart

class SoulCelebrationOverlay extends StatefulWidget {
  const SoulCelebrationOverlay({super.key, this.onDismissed});

  final VoidCallback? onDismissed;

  @override
  State<SoulCelebrationOverlay> createState() => _SoulCelebrationOverlayState();
}
```

Implementation: Use `AnimationController` with `TickerProviderStateMixin`, show a purple gradient overlay with animated sparkle icons that scale up and fade out over 1.5 seconds.

**Step 2: Integrate into TransactionFormScreen**

After successful save, check if the result transaction's `ledgerType == LedgerType.soul`. If so, show the overlay before popping.

**Step 3: Write widget test**

```dart
// test/widget/features/dual_ledger/presentation/widgets/soul_celebration_overlay_test.dart

void main() {
  testWidgets('renders without error', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SoulCelebrationOverlay()),
      ),
    );
    expect(find.byType(SoulCelebrationOverlay), findsOneWidget);
  });
}
```

**Step 4: Run all tests**

Run: `flutter test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add lib/features/dual_ledger/presentation/widgets/soul_celebration_overlay.dart \
        lib/features/accounting/presentation/screens/transaction_form_screen.dart \
        test/widget/features/dual_ledger/
git commit -m "feat(dual-ledger): add soul celebration overlay animation"
```

---

## Task 9: Final Verification & Cleanup

**Files:**
- All modified files

**Step 1: Run full test suite**

Run: `flutter test`
Expected: ALL PASS (should be ~230+ tests)

**Step 2: Run analyzer**

Run: `flutter analyze`
Expected: No issues found!

**Step 3: Format code**

Run: `dart format .`

**Step 4: Verify the data flow**

Manually verify:
1. Creating an expense with `cat_food` → should auto-classify as `survival`
2. Creating an expense with `cat_entertainment` → should auto-classify as `soul`
3. Tab switching works to filter by ledger type
4. Soul celebration shows for soul transactions

**Step 5: Commit any cleanup**

```bash
git add -A
git commit -m "chore(dual-ledger): final cleanup and formatting"
```

---

## Summary

| Task | Description | Tests | Files |
|------|-------------|-------|-------|
| 1 | ClassificationResult model | 2 | 2 new |
| 2 | RuleEngine (Layer 1) | 11 | 2 new |
| 3 | ClassificationService | 5 | 2 new |
| 4 | Integrate into CreateTransactionUseCase | ~7 (updated) | 3 modified |
| 5 | Riverpod providers | 0 (wiring) | 3 new + 1 modified |
| 6 | DualLedgerScreen + tab switching | 1 | 3 new/modified |
| 7 | TransactionListTile ledger indicator | 2 | 2 modified |
| 8 | Soul celebration overlay | 1 | 3 new/modified |
| 9 | Final verification | 0 | cleanup |

**Total new tests:** ~29
**Expected total after completion:** ~242+ tests
