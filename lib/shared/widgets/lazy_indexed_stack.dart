import 'package:flutter/widgets.dart';

/// An [IndexedStack] that creates each child only when it is first selected.
///
/// Once created, children stay mounted so tab-local state survives navigation.
/// Changing [cacheKey] clears the cache, which is useful when the shell's
/// underlying account or book changes without replacing this widget's element.
class LazyIndexedStack extends StatefulWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    this.cacheKey,
  }) : assert(itemCount > 0),
       assert(index >= 0 && index < itemCount);

  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Object? cacheKey;

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  late List<Widget?> _children;

  @override
  void initState() {
    super.initState();
    _children = List<Widget?>.filled(widget.itemCount, null);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount ||
        oldWidget.cacheKey != widget.cacheKey) {
      _children = List<Widget?>.filled(widget.itemCount, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    _children[widget.index] ??= widget.itemBuilder(context, widget.index);
    return IndexedStack(
      index: widget.index,
      children: List<Widget>.generate(
        widget.itemCount,
        (index) => _children[index] ?? const SizedBox.shrink(),
        growable: false,
      ),
    );
  }
}
