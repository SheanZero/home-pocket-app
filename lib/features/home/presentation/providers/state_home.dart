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
