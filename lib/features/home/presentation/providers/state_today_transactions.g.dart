// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'state_today_transactions.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.

@ProviderFor(todayTransactions)
final todayTransactionsProvider = TodayTransactionsFamily._();

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.

final class TodayTransactionsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Transaction>>,
          List<Transaction>,
          FutureOr<List<Transaction>>
        >
    with
        $FutureModifier<List<Transaction>>,
        $FutureProvider<List<Transaction>> {
  /// Fetches today's non-deleted transactions for the given [bookId].
  ///
  /// Uses [GetTransactionsUseCase] with date range for the current day
  /// (00:00:00 to 23:59:59) and filters out soft-deleted records.
  TodayTransactionsProvider._({
    required TodayTransactionsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'todayTransactionsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todayTransactionsHash();

  @override
  String toString() {
    return r'todayTransactionsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Transaction>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Transaction>> create(Ref ref) {
    final argument = this.argument as String;
    return todayTransactions(ref, bookId: argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayTransactionsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todayTransactionsHash() => r'f91eeaaa4ab9c55f0b276f39c499c06f490bb3bd';

/// Fetches today's non-deleted transactions for the given [bookId].
///
/// Uses [GetTransactionsUseCase] with date range for the current day
/// (00:00:00 to 23:59:59) and filters out soft-deleted records.

final class TodayTransactionsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Transaction>>, String> {
  TodayTransactionsFamily._()
    : super(
        retry: null,
        name: r'todayTransactionsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Fetches today's non-deleted transactions for the given [bookId].
  ///
  /// Uses [GetTransactionsUseCase] with date range for the current day
  /// (00:00:00 to 23:59:59) and filters out soft-deleted records.

  TodayTransactionsProvider call({required String bookId}) =>
      TodayTransactionsProvider._(argument: bookId, from: this);

  @override
  String toString() => r'todayTransactionsProvider';
}
