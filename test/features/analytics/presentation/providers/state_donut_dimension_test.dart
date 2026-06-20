import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/features/analytics/presentation/providers/state_donut_dimension.dart';

void main() {
  group('DonutDimensionState', () {
    test('Test 1: initial = (category, memberFilterDeviceId: null)', () {
      final container = ProviderContainer.test();
      final state = container.read(donutDimensionStateProvider);

      expect(state.dimension, DonutDimension.category);
      expect(state.memberFilterDeviceId, isNull);
    });

    test(
      'Test 2: setDimension(member) → dimension==member, memberFilter unchanged',
      () {
        final container = ProviderContainer.test();
        container
            .read(donutDimensionStateProvider.notifier)
            .setDimension(DonutDimension.member);

        final state = container.read(donutDimensionStateProvider);
        expect(state.dimension, DonutDimension.member);
        expect(state.memberFilterDeviceId, isNull);
      },
    );

    test(
      'Test 3: setMemberFilter(dev-2) → memberFilterDeviceId==dev-2 (global '
      'narrowing)',
      () {
        final container = ProviderContainer.test();
        container
            .read(donutDimensionStateProvider.notifier)
            .setMemberFilter('dev-2');

        final state = container.read(donutDimensionStateProvider);
        expect(state.memberFilterDeviceId, 'dev-2');
        // Dimension untouched.
        expect(state.dimension, DonutDimension.category);
      },
    );

    test('Test 4: setMemberFilter(null) → back to all members', () {
      final container = ProviderContainer.test();
      final notifier = container.read(donutDimensionStateProvider.notifier);
      notifier.setMemberFilter('dev-2');
      notifier.setMemberFilter(null);

      final state = container.read(donutDimensionStateProvider);
      expect(state.memberFilterDeviceId, isNull);
    });

    test(
      'Test 5: switching back to category does NOT clear memberFilter '
      '(filter is a global narrowing kept across dimensions)',
      () {
        final container = ProviderContainer.test();
        final notifier = container.read(donutDimensionStateProvider.notifier);
        notifier.setMemberFilter('dev-3');
        notifier.setDimension(DonutDimension.member);
        notifier.setDimension(DonutDimension.category);

        final state = container.read(donutDimensionStateProvider);
        expect(state.dimension, DonutDimension.category);
        expect(state.memberFilterDeviceId, 'dev-3');
      },
    );
  });
}
