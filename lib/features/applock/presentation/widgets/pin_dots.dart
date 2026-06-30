import 'package:flutter/material.dart';

/// Presentational 4-dot PIN indicator with a shake-and-clear error animation
/// (sketch 002 tone B, D-12).
///
/// Stub — implemented in the GREEN step.
class PinDots extends StatefulWidget {
  const PinDots({
    super.key,
    required this.filledCount,
    this.length = 4,
    this.errorTrigger = 0,
  });

  final int filledCount;
  final int length;
  final int errorTrigger;

  @override
  State<PinDots> createState() => _PinDotsState();
}

class _PinDotsState extends State<PinDots> {
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
