import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../features/accounting/domain/models/transaction.dart';

part 'ledger_providers.g.dart';

/// Current ledger tab selection.
@Riverpod(keepAlive: true)
class LedgerView extends _$LedgerView {
  @override
  LedgerType build() => LedgerType.survival;

  void switchTo(LedgerType type) => state = type;

  void toggle() {
    state = state == LedgerType.survival
        ? LedgerType.soul
        : LedgerType.survival;
  }
}
