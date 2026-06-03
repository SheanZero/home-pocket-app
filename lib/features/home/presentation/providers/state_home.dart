import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'state_home.g.dart';

/// Global bottom navigation tab index state.
///
/// Defaults to 0 (Home tab). Kept alive so the tab selection
/// persists across navigation events within the shell.
@Riverpod(keepAlive: true)
class SelectedTabIndex extends _$SelectedTabIndex {
  @override
  int build() => 0;

  void select(int index) {
    state = index;
  }
}

/// Selected month/year for the home dashboard.
///
/// Defaults to the current month. Kept alive so the selected month
/// persists across tab switches. State is a named record
/// `({int year, int month})` so callers use `state.year` / `state.month`.
@Riverpod(keepAlive: true)
class HomeSelectedMonth extends _$HomeSelectedMonth {
  @override
  ({int year, int month}) build() {
    final now = DateTime.now();
    return (year: now.year, month: now.month);
  }

  /// Sets the selected month explicitly.
  void selectMonth(int year, int month) {
    state = (year: year, month: month);
  }

  /// Navigates to the previous month.
  void prevMonth() {
    final d = DateTime(state.year, state.month - 1);
    selectMonth(d.year, d.month);
  }

  /// Navigates to the next month.
  void nextMonth() {
    final d = DateTime(state.year, state.month + 1);
    selectMonth(d.year, d.month);
  }
}
