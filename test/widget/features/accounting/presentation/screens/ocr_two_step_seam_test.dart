/// Widget test: OCR two-step seam behavioral test (D-14, SC-4).
///
/// Verifies that tapping the shutter button in OcrScannerScreen:
/// - pushes OcrReviewScreen onto the navigation stack (D-14 assertion a)
/// - OcrReviewScreen mounts TransactionDetailsForm exactly once (D-14 assertion b)
///
/// This is the behavioral test D-14 mandates. An architecture import test is
/// NOT a substitute — D-14 explicitly requires a widget-level behavioral test.
///
/// Shutter identification (W5 fix):
/// The shutter GestureDetector wraps Container(width: 72, height: 72).
/// The gallery and flash use _CircleButton with Container(width: 48, height: 48).
/// A byWidgetPredicate on the 72x72 container size is the stable selector
/// that survives layout edits that don't change the shutter's semantic role.
/// Index-based selection via .at() is forbidden.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/accounting/category_service.dart';
import 'package:home_pocket/features/accounting/domain/models/category.dart';
import 'package:home_pocket/features/accounting/domain/models/category_ledger_config.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_ledger_config_repository.dart';
import 'package:home_pocket/features/accounting/domain/repositories/category_repository.dart';
import 'package:home_pocket/features/accounting/presentation/providers/repository_providers.dart';
import 'package:home_pocket/features/accounting/presentation/screens/ocr_review_screen.dart';
import 'package:home_pocket/features/accounting/presentation/screens/ocr_scanner_screen.dart';
import 'package:home_pocket/features/accounting/presentation/widgets/transaction_details_form.dart';

import '../../../../../helpers/test_localizations.dart';

// ── Fakes ──────────────────────────────────────────────────────────────────────

/// Always returns null — no database required for OCR seam test.
class _NullCategoryRepository implements CategoryRepository {
  @override
  Future<Category?> findById(String id) async => null;
  @override
  Future<List<Category>> findAll() async => [];
  @override
  Future<List<Category>> findActive() async => [];
  @override
  Future<List<Category>> findByLevel(int level) async => [];
  @override
  Future<List<Category>> findByParent(String parentId) async => [];
  @override
  Future<void> insert(Category category) async {}
  @override
  Future<void> insertBatch(List<Category> categories) async {}
  @override
  Future<void> update({
    required String id,
    String? name,
    String? icon,
    String? color,
    bool? isArchived,
    int? sortOrder,
  }) async {}
  @override
  Future<void> updateSortOrders(Map<String, int> idToSortOrder) async {}
  @override
  Future<void> deleteAll() async {}
}

class _NullLedgerConfigRepository implements CategoryLedgerConfigRepository {
  @override
  Future<CategoryLedgerConfig?> findById(String categoryId) async => null;
  @override
  Future<List<CategoryLedgerConfig>> findAll() async => [];
  @override
  Future<void> upsert(CategoryLedgerConfig config) async {}
  @override
  Future<void> upsertBatch(List<CategoryLedgerConfig> configs) async {}
  @override
  Future<void> delete(String categoryId) async {}
  @override
  Future<void> deleteAll() async {}
}

// ── Test ───────────────────────────────────────────────────────────────────────

void main() {
  testWidgets(
    'shutter tap routes to OcrReviewScreen with single TransactionDetailsForm (D-14, SC-4)',
    (tester) async {
      tester.view.physicalSize = const Size(402, 874);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        createLocalizedWidget(
          const OcrScannerScreen(bookId: 'book-test'),
          locale: const Locale('ja'),
          overrides: [
            // categoryRepositoryProvider: null repo — OcrReviewScreen mounts
            // TransactionDetailsForm in .new mode which doesn't call findById.
            categoryRepositoryProvider.overrideWithValue(
              _NullCategoryRepository(),
            ),
            categoryServiceProvider.overrideWith(
              (_) => CategoryService(
                categoryRepository: _NullCategoryRepository(),
                ledgerConfigRepository: _NullLedgerConfigRepository(),
              ),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // ── Locate the shutter via its 72x72 Container dimension (W5 stable selector) ──
      //
      // The shutter GestureDetector wraps Container(width: 72, height: 72).
      // _CircleButton widgets (gallery + flash) wrap Container(width: 48, height: 48).
      // This predicate does NOT use .at(<int>) — layout edits that reorder the
      // gallery/shutter/flash row must not break this test.
      final shutter = find.byWidgetPredicate((w) {
        if (w is! GestureDetector) return false;
        final child = w.child;
        if (child is! Container) return false;
        final c = child.constraints;
        // Container(width: 72, height: 72) creates BoxConstraints.tightFor(w,h)
        // → maxWidth == 72.0 && maxHeight == 72.0
        return c != null && c.maxWidth == 72.0 && c.maxHeight == 72.0;
      });

      // Fail fast if the selector drifts (e.g., shutter resized in a future phase)
      expect(
        shutter,
        findsOneWidget,
        reason:
            'Shutter GestureDetector with Container(w=72, h=72) must be findable. '
            'If this fails, update the 72x72 size signature in this test to match '
            'the new shutter dimensions in ocr_scanner_screen.dart.',
      );

      // Tap the shutter
      await tester.tap(shutter);
      await tester.pumpAndSettle();

      // D-14 assertion (a): route stack contains OcrReviewScreen
      expect(
        find.byType(OcrReviewScreen),
        findsOneWidget,
        reason: 'Shutter tap must push OcrReviewScreen onto the navigation stack (D-14a)',
      );

      // D-14 assertion (b): TransactionDetailsForm is mounted inside OcrReviewScreen
      // SC-4: step 2 actually mounts the shared widget — behavioral guarantee
      expect(
        find.byType(TransactionDetailsForm),
        findsOneWidget,
        reason:
            'OcrReviewScreen must mount exactly one TransactionDetailsForm (D-14b, SC-4)',
      );

      // Bonus: MaterialBanner is shown because draft.isEmpty is true (Phase 18
      // always passes OcrParseDraft.empty() from the scanner stub — D-11/D-13).
      expect(
        find.byType(MaterialBanner),
        findsOneWidget,
        reason: 'OcrReviewEmptyDraftBanner must be shown when draft is empty',
      );
    },
  );
}
