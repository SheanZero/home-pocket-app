import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/models/time_window.dart';

part 'state_time_window.g.dart';

/// Session-scoped AnalyticsScreen time-window selection (D-12: HomeHero is NOT
/// a consumer). Default = current calendar month per ADR-016 §3 ring semantics
/// consistency.
@riverpod
class SelectedTimeWindow extends _$SelectedTimeWindow {
  @override
  TimeWindow build() {
    final now = DateTime.now();
    return TimeWindow.month(year: now.year, month: now.month);
  }

  void setWindow(TimeWindow window) {
    state = window;
  }
}
