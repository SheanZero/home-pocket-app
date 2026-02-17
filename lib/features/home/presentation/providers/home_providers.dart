import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'home_providers.g.dart';

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

/// Controls visibility of the Ohtani converter banner on the home page.
///
/// Starts visible (true) and can be dismissed by the user.
@Riverpod(keepAlive: true)
class OhtaniConverterVisible extends _$OhtaniConverterVisible {
  @override
  bool build() => true;

  void dismiss() {
    state = false;
  }
}
