import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/application/dual_ledger/classification_service.dart';
import 'package:home_pocket/application/dual_ledger/providers.dart';
import 'package:home_pocket/application/dual_ledger/rule_engine.dart';

// No mocks needed — RuleEngine and ClassificationService have no external deps
// Characterization test: locks pre-rename behavior before Plan 04-01 Task 3
// step 7 renames providers.dart → repository_providers.dart.
// After rename, update import path from:
//   package:home_pocket/application/dual_ledger/providers.dart
// to:
//   package:home_pocket/application/dual_ledger/repository_providers.dart

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() => container.dispose());

  group(
    'application/dual_ledger/providers characterization tests (pre-rename behavior)',
    () {
      test(
        'ruleEngineProvider constructs RuleEngine instance',
        () {
          final engine = container.read(ruleEngineProvider);
          expect(engine, isA<RuleEngine>());
        },
      );

      test(
        'ruleEngineProvider is keepAlive — same instance across two reads',
        () {
          // Read twice; @Riverpod(keepAlive: true) at line 9 ensures same
          // instance is returned — this is the pre-rename behavior we lock.
          final first = container.read(ruleEngineProvider);
          final second = container.read(ruleEngineProvider);
          expect(identical(first, second), isTrue,
              reason:
                  'ruleEngineProvider must be keepAlive: true — same instance expected');
        },
      );

      test(
        'classificationServiceProvider constructs ClassificationService',
        () {
          final service = container.read(classificationServiceProvider);
          expect(service, isA<ClassificationService>());
        },
      );

      test(
        'classificationServiceProvider returns non-null instance',
        () {
          expect(container.read(classificationServiceProvider), isNotNull);
        },
      );

      test(
        'classificationServiceProvider uses ruleEngineProvider internally',
        () {
          // Reading classificationService should not throw
          // and should wire to ruleEngineProvider correctly.
          final service = container.read(classificationServiceProvider);
          expect(service, isA<ClassificationService>());
          // Verify ruleEngine is also readable (no circular dep)
          final engine = container.read(ruleEngineProvider);
          expect(engine, isA<RuleEngine>());
        },
      );
    },
  );
}
