import 'package:flutter/material.dart';

/// Home-only colors used by the approved V15 hero composition.
///
/// These colors intentionally stay separate from broad semantic colors such as
/// success/warning: the goal ring, satisfaction scale, small-win value and
/// ticket form one authored composition with their own exact palette.
final class HomeV15VisualTokens {
  const HomeV15VisualTokens({
    required this.metricAccent,
    required this.metricDivider,
    required this.satisfaction,
    required this.satisfactionText,
    required this.satisfactionTrack,
    required this.smallWin,
    required this.goalProgress,
    required this.goalTrack,
    required this.goalValue,
    required this.goalShadow,
    required this.ticketSurface,
    required this.ticketBorder,
    required this.ticketAccent,
    required this.ticketCalendar,
    required this.ticketText,
  });

  final Color metricAccent;
  final Color metricDivider;
  final Color satisfaction;
  final Color satisfactionText;
  final Color satisfactionTrack;
  final Color smallWin;
  final Color goalProgress;
  final Color goalTrack;
  final Color goalValue;
  final Color goalShadow;
  final Color ticketSurface;
  final Color ticketBorder;
  final Color ticketAccent;
  final Color ticketCalendar;
  final Color ticketText;

  static const light = HomeV15VisualTokens(
    metricAccent: Color(0xFFA54A63),
    metricDivider: Color(0xFFC7C7B7),
    satisfaction: Color(0xFF4D9058),
    satisfactionText: Color(0xFF467F4E),
    satisfactionTrack: Color(0xFFE7ECE1),
    smallWin: Color(0xFFC1953E),
    goalProgress: Color(0xFFB76376),
    goalTrack: Color(0xFFF4DDE1),
    goalValue: Color(0xFF9B455A),
    goalShadow: Color(0x1A9B455A),
    ticketSurface: Color(0xFFF3F7F0),
    ticketBorder: Color(0xFFDF9FA7),
    ticketAccent: Color(0xFFA54A63),
    ticketCalendar: Color(0xFFDE929B),
    ticketText: Color(0xFF9B455A),
  );

  static const dark = HomeV15VisualTokens(
    metricAccent: Color(0xFFE89BB0),
    metricDivider: Color(0xFF465248),
    satisfaction: Color(0xFF7DC88D),
    satisfactionText: Color(0xFF91D39E),
    satisfactionTrack: Color(0xFF2F3A32),
    smallWin: Color(0xFFD3A571),
    goalProgress: Color(0xFFD57891),
    goalTrack: Color(0xFF4A2D37),
    goalValue: Color(0xFFF0A9BB),
    goalShadow: Color(0x2E000000),
    ticketSurface: Color(0xFF243128),
    ticketBorder: Color(0xFFB36B7E),
    ticketAccent: Color(0xFFE89BB0),
    ticketCalendar: Color(0xFFC9788F),
    ticketText: Color(0xFFE89BB0),
  );

  static HomeV15VisualTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}
