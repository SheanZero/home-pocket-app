// Wave 0 stub — bodies implemented in Plan 27-02.
// File must compile and run; placeholder assertions are intentional.

// ignore_for_file: unused_import, unused_element
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/models/analytics_aggregate.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:home_pocket/features/analytics/presentation/providers/repository_providers.dart'
    show analyticsRepositoryProvider;
import 'package:mocktail/mocktail.dart';

import '../../../../../helpers/test_provider_scope.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  group('calendarTotalsProvider (Wave 0 stubs)', () {
    test('SC#2: expense-only basis — TODO implement in Plan 27-02', () {
      // TODO: implement in Plan 27-02
      expect(true, isTrue);
    });

    test('_dayKey normalization — TODO implement in Plan 27-02', () {
      // TODO: implement in Plan 27-02
      expect(true, isTrue);
    });

    test('empty month returns zero totals — TODO implement in Plan 27-02', () {
      // TODO: implement in Plan 27-02
      expect(true, isTrue);
    });

    test('D-11: month total fold — TODO implement in Plan 27-02', () {
      // TODO: implement in Plan 27-02
      expect(true, isTrue);
    });

    test(
      'ProviderException wrapping on repository error — TODO implement in Plan 27-02',
      () {
        // TODO: implement in Plan 27-02
        expect(true, isTrue);
      },
    );
  });
}
