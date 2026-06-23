import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/application/accounting/ledger_hint_deriver.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/models/transaction.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/shared/constants/default_categories.dart';
import 'package:home_pocket/shared/constants/default_merchants.dart';

/// PARITY GATE (T-49-LED, D-09): the const-list-evaluated `deriveLedgerHint`
/// MUST be byte-equal to the authoritative DB-backed
/// `CategoryService.resolveLedgerType` precedence (L2-override -> L1-parent) for
/// every categoryId the seed list actually uses. This pre-empts the Phase-51
/// ledger desync by proving there is a single source of truth.
///
/// The fakes below are backed by the SAME `DefaultCategories` const data the
/// app seeds, so `resolveLedgerType` here computes the real precedence — it is
/// not a re-implementation of `deriveLedgerHint`.
class _FakeCategoryRepository implements CategoryRepository {
  _FakeCategoryRepository(this._byId);
  final Map<String, Category> _byId;

  @override
  Future<Category?> findById(String id) async => _byId[id];

  @override
  Future<List<Category>> findAll() async => _byId.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

class _FakeLedgerConfigRepository implements CategoryLedgerConfigRepository {
  _FakeLedgerConfigRepository(this._byId);
  final Map<String, CategoryLedgerConfig> _byId;

  @override
  Future<CategoryLedgerConfig?> findById(String id) async => _byId[id];

  @override
  Future<List<CategoryLedgerConfig>> findAll() async => _byId.values.toList();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  final categoryById = {for (final c in DefaultCategories.all) c.id: c};
  final configById = {
    for (final cfg in DefaultCategories.defaultLedgerConfigs)
      cfg.categoryId: cfg,
  };

  final service = CategoryService(
    categoryRepository: _FakeCategoryRepository(categoryById),
    ledgerConfigRepository: _FakeLedgerConfigRepository(configById),
  );

  group('deriveLedgerHint == resolveLedgerType (single source of truth)', () {
    test(
        'parity holds for every distinct categoryId used by DefaultMerchants',
        () async {
      final usedCategoryIds =
          DefaultMerchants.all.map((m) => m.categoryId).toSet();
      expect(usedCategoryIds, isNotEmpty);

      for (final categoryId in usedCategoryIds) {
        final derived = deriveLedgerHint(categoryId);
        final authoritative = await service.resolveLedgerType(categoryId);
        expect(
          authoritative,
          isNotNull,
          reason:
              'resolveLedgerType returned null for $categoryId — categoryId '
              'gate should have caught this',
        );
        expect(
          derived,
          authoritative,
          reason:
              'Ledger desync for $categoryId: deriveLedgerHint=$derived but '
              'resolveLedgerType=$authoritative',
        );
      }
    });

    test('parity holds for EVERY L2 + L1 id in DefaultCategories', () async {
      // Broader than just the seeded ids — proves the deriver is correct across
      // the whole category tree (no override is silently missed).
      for (final cat in DefaultCategories.all) {
        final authoritative = await service.resolveLedgerType(cat.id);
        if (authoritative == null) continue; // no config (e.g. some L2 w/o path)
        expect(
          deriveLedgerHint(cat.id),
          authoritative,
          reason: 'Ledger desync for ${cat.id}',
        );
      }
    });

    test('L2 override wins over L1 parent (cat_clothing_clothes -> daily)', () {
      // cat_clothing parent is joy, but cat_clothing_clothes overrides to daily.
      expect(deriveLedgerHint('cat_clothing_clothes'), LedgerType.daily);
      expect(deriveLedgerHint('cat_clothing'), LedgerType.joy);
    });

    test('L2 without override inherits L1 parent (cat_food_cafe -> daily)', () {
      expect(deriveLedgerHint('cat_food_cafe'), LedgerType.daily);
      expect(deriveLedgerHint('cat_hobbies_subscription'), LedgerType.joy);
    });

    test(
        'parent inheritance is gated on level == 2 (structural parity with '
        'resolveLedgerType, not data-shape coincidence)', () async {
      // A synthetic category that has a parentId WITH a resolvable config but is
      // NOT an L2 (e.g. an L1 mistakenly given a parent, or a future L3). The
      // authority (resolveLedgerType) refuses to inherit because its guard is
      // `level == 2 && parentId != null`. deriveLedgerHint MUST match: it should
      // throw (no resolvable config) rather than silently inherit the parent's
      // ledger. This locks WR-02 — without the level guard, deriveLedgerHint
      // would return the parent's ledger and diverge from the authority.
      final syntheticL1WithParent = Category(
        id: 'cat_synthetic_l1_with_parent',
        name: 'synthetic',
        icon: 'x',
        color: '#000000',
        // parent has a direct config (cat_food -> daily) but this node is L1.
        parentId: 'cat_food',
        level: 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      );

      final byId = {
        for (final c in DefaultCategories.all) c.id: c,
        syntheticL1WithParent.id: syntheticL1WithParent,
      };
      final guardedService = CategoryService(
        categoryRepository: _FakeCategoryRepository(byId),
        ledgerConfigRepository: _FakeLedgerConfigRepository(configById),
      );

      // Authority does not inherit (level != 2) -> null.
      expect(
        await guardedService.resolveLedgerType(syntheticL1WithParent.id),
        isNull,
      );
      // Deriver must agree by refusing to resolve (not inheriting the parent).
      expect(
        () => deriveLedgerHint(syntheticL1WithParent.id),
        throwsStateError,
      );
    });
  });
}
