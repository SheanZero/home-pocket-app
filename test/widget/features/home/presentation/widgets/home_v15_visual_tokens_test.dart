import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:home_pocket/core/theme/home_v15_visual_tokens.dart';

void main() {
  test(
    'light metric and ticket colors match the V15 dedicated composition',
    () {
      const colors = HomeV15VisualTokens.light;

      expect(colors.goalProgress, const Color(0xFFB76376));
      expect(colors.goalTrack, const Color(0xFFF4DDE1));
      expect(colors.goalValue, const Color(0xFF9B455A));
      expect(colors.metricDivider, const Color(0xFFC7C7B7));
      expect(colors.satisfaction, const Color(0xFF4D9058));
      expect(colors.satisfactionText, const Color(0xFF467F4E));
      expect(colors.satisfactionTrack, const Color(0xFFE7ECE1));
      expect(colors.smallWin, const Color(0xFFC1953E));
      expect(colors.ticketSurface, const Color(0xFFF3F7F0));
      expect(colors.ticketBorder, const Color(0xFFDF9FA7));
      expect(colors.ticketAccent, const Color(0xFFA54A63));
      expect(colors.ticketCalendar, const Color(0xFFDE929B));
      expect(colors.ticketText, const Color(0xFF9B455A));
    },
  );
}
