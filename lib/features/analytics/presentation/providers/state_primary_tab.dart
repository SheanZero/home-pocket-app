import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../widgets/analytics_primary_tabs.dart';

part 'state_primary_tab.g.dart';

/// Session-scoped primary tab for the Statistics surface.
///
/// The shell updates this before selecting the Statistics bottom-nav item so
/// the entry source is explicit: bottom navigation opens Spending, while the
/// two Joy affordances on Home open Joy. Keep this alive because Home may set
/// it before the lazy shell stack has mounted the analytics screen.
@Riverpod(keepAlive: true)
class SelectedAnalyticsPrimaryTab extends _$SelectedAnalyticsPrimaryTab {
  @override
  AnalyticsPrimaryTab build() => AnalyticsPrimaryTab.spending;

  void select(AnalyticsPrimaryTab tab) {
    state = tab;
  }
}
