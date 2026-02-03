import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'transaction_list_provider.g.dart';

/// Transaction List Provider
/// Manages the list of transactions for display
@riverpod
class TransactionList extends _$TransactionList {
  @override
  Future<List<String>> build({
    required String bookId,
  }) async {
    // TODO: Implement actual transaction loading from repository
    await Future.delayed(const Duration(milliseconds: 500));

    return [
      'Transaction 1',
      'Transaction 2',
      'Transaction 3',
    ];
  }

  /// Refresh the transaction list
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  /// Add a new transaction
  Future<void> addTransaction(String transaction) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      // TODO: Implement actual transaction creation
      await Future.delayed(const Duration(milliseconds: 300));

      return [...?state.value, transaction];
    });
  }
}
