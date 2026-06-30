import 'package:flutter/material.dart';

/// Presentational 9-grid numeric keypad (sketch 002 tone B "清爽极简").
///
/// Stub — implemented in the GREEN step.
class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
