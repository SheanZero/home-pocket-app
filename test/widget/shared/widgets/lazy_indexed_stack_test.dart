import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/shared/widgets/lazy_indexed_stack.dart';

class _StatefulTab extends StatefulWidget {
  const _StatefulTab({required this.label, super.key});

  final String label;

  @override
  State<_StatefulTab> createState() => _StatefulTabState();
}

class _StatefulTabState extends State<_StatefulTab> {
  @override
  Widget build(BuildContext context) => Text(widget.label);
}

void main() {
  testWidgets('builds tabs on first visit and keeps their state alive', (
    tester,
  ) async {
    var currentIndex = 0;
    late void Function(int index) select;
    final buildCounts = List<int>.filled(4, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            select = (index) => setState(() => currentIndex = index);
            return LazyIndexedStack(
              index: currentIndex,
              itemCount: 4,
              itemBuilder: (context, index) {
                buildCounts[index] += 1;
                return _StatefulTab(
                  key: ValueKey('tab-$index'),
                  label: 'Tab $index',
                );
              },
            );
          },
        ),
      ),
    );

    expect(buildCounts, [1, 0, 0, 0]);
    final initialHomeState = tester.state(find.byKey(const ValueKey('tab-0')));

    select(2);
    await tester.pump();

    expect(buildCounts, [1, 0, 1, 0]);
    expect(find.text('Tab 0', skipOffstage: false), findsOneWidget);
    expect(find.text('Tab 2'), findsOneWidget);

    select(0);
    await tester.pump();

    expect(buildCounts, [1, 0, 1, 0]);
    expect(
      tester.state(find.byKey(const ValueKey('tab-0'))),
      same(initialHomeState),
    );
  });
}
