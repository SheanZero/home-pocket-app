import 'package:flutter/material.dart';

import '../../../../core/theme/app_text_styles.dart';

/// STATSUI-05 — Themed-group H3 header using U+2501 glyphs.
class AnalyticsScreenSectionHeader extends StatelessWidget {
  const AnalyticsScreenSectionHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final header = label.contains('━') ? label : '━ $label ━';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        header,
        style: AppTextStyles.caption.copyWith(
          fontWeight: FontWeight.w700,
          color: const Color(0xFF374151),
        ),
      ),
    );
  }
}
