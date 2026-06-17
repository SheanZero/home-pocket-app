import 'package:flutter/material.dart';

/// Shared title/caption/child Card shell for analytics data cards.
///
/// Phase 45: promoted verbatim from the private `_AnalyticsDataCard` inline in
/// `analytics_screen.dart` (D-A1 byte-faithful move — only the class name lost
/// its leading underscore and the constructor gained `super.key`). Consumed by
/// `CategoryDonutCard` and `SatisfactionHistogramCard` (the `TotalSixMonthCard`
/// consumer was removed with the 6-month trend stack in 46-01, D-E2).
///
/// The 14px padding and 12px/4px internal gaps are preserved 8-pt-grid
/// exceptions (UI-SPEC Spacing) — do NOT "normalise" them.
class AnalyticsDataCard extends StatelessWidget {
  const AnalyticsDataCard({
    super.key,
    required this.title,
    required this.caption,
    required this.child,
  });

  final String title;
  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(caption, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
