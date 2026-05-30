// Wave 0 stub — bodies implemented in Plan 27-03.
// File must compile and run; placeholder assertions are intentional.

// ignore_for_file: unused_element
// ignore: uri_does_not_exist — widget created in Plan 27-03
// import 'package:home_pocket/features/list/presentation/widgets/list_calendar_header.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/domain/repositories/analytics_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockAnalyticsRepository extends Mock implements AnalyticsRepository {}

void main() {
  group('ListCalendarHeader widget (Wave 0 stubs)', () {
    test('SC#1: month nav — TODO implement in Plan 27-03', () {
      // TODO: implement in Plan 27-03
      expect(true, isTrue);
    });

    test('SC#3: day tap toggle — TODO implement in Plan 27-03', () {
      // TODO: implement in Plan 27-03
      expect(true, isTrue);
    });

    test('SC#4: summary row amount — TODO implement in Plan 27-03', () {
      // TODO: implement in Plan 27-03
      expect(true, isTrue);
    });
  });
}
