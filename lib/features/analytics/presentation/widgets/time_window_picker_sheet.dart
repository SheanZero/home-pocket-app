import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bottom-sheet entry point for choosing the AnalyticsScreen time window.
///
/// The full type-row and chooser flow is implemented in the next task; this
/// entry point lets [TimeWindowChip] compile while keeping the public call
/// shape stable.
class TimeWindowPickerSheet {
  const TimeWindowPickerSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    DateTime? earliestData,
  }) async {}
}
